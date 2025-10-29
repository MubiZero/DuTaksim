const express = require('express');
const router = express.Router();
const pool = require('../config/database');
const { authenticateToken } = require('../middleware/auth');
const { validateUUIDParam } = require('../middleware/validation');
const { contactLookupLimiter } = require('../middleware/rateLimiter');
const emailService = require('../services/emailService');

// Search users by phone numbers (batch lookup) - protected
router.post('/lookup', contactLookupLimiter, authenticateToken, async (req, res) => {
  const { phones } = req.body;

  if (!phones || !Array.isArray(phones) || phones.length === 0) {
    return res.status(400).json({ error: 'Phone numbers array is required' });
  }

  try {
    // Clean phone numbers (remove spaces, dashes, etc.)
    const cleanedPhones = phones.map(phone =>
      phone.replace(/[\s\-\(\)]/g, '')
    );

    const result = await pool.query(
      'SELECT id, name, phone FROM users WHERE phone = ANY($1)',
      [cleanedPhones]
    );

    // Create a map of phone -> user for easy lookup
    const userMap = {};
    result.rows.forEach(user => {
      userMap[user.phone] = user;
    });

    // Return in same order as requested
    const users = cleanedPhones.map(phone => userMap[phone] || null);

    res.json({
      users,
      registeredCount: result.rows.length,
      totalCount: phones.length
    });
  } catch (error) {
    console.error('Error looking up contacts:', error);
    res.status(500).json({ error: 'Failed to lookup contacts' });
  }
});

// Send invitation to email (protected)
router.post('/invite', authenticateToken, async (req, res) => {
  const { inviterId, email, sessionId } = req.body;

  if (!inviterId || !email) {
    return res.status(400).json({ error: 'Inviter ID and email are required' });
  }

  // Basic email validation
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({ error: 'Invalid email address' });
  }

  try {
    // Get inviter details
    const inviterResult = await pool.query(
      'SELECT name, phone FROM users WHERE id = $1',
      [inviterId]
    );

    if (inviterResult.rows.length === 0) {
      return res.status(404).json({ error: 'Inviter not found' });
    }

    const inviter = inviterResult.rows[0];

    // Get session details if sessionId is provided
    let sessionName = 'a bill session';
    let sessionCode = null;

    if (sessionId) {
      const sessionResult = await pool.query(
        'SELECT name, session_code FROM bill_sessions WHERE id = $1',
        [sessionId]
      );

      if (sessionResult.rows.length > 0) {
        sessionName = sessionResult.rows[0].name;
        sessionCode = sessionResult.rows[0].session_code;
      }
    }

    // Create invitation record
    const inviteResult = await pool.query(
      `INSERT INTO contact_invitations (inviter_id, phone, session_id)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [inviterId, email, sessionId] // Store email in phone field for now
    );

    // Send email invitation
    const emailResult = await emailService.sendSessionInvitation(
      email,
      inviter.name,
      sessionName,
      sessionCode
    );

    res.json({
      success: true,
      message: emailResult.success ? 'Invitation sent via email' : 'Invitation created (email delivery failed)',
      invitation: inviteResult.rows[0],
      emailSent: emailResult.success,
      emailError: emailResult.error || emailResult.reason
    });
  } catch (error) {
    console.error('Error creating invitation:', error);
    res.status(500).json({ error: 'Failed to create invitation' });
  }
});

// Get pending invitations for a phone number (protected)
router.get('/invitations/:phone', authenticateToken, async (req, res) => {
  const { phone } = req.params;

  try {
    const result = await pool.query(
      `SELECT ci.*, u.name as inviter_name, bs.name as session_name
       FROM contact_invitations ci
       JOIN users u ON ci.inviter_id = u.id
       LEFT JOIN bill_sessions bs ON ci.session_id = bs.id
       WHERE ci.phone = $1
       AND ci.status = 'pending'
       AND ci.expires_at > NOW()
       ORDER BY ci.created_at DESC`,
      [phone]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Error getting invitations:', error);
    res.status(500).json({ error: 'Failed to get invitations' });
  }
});

// Accept invitation (called after user registers) - protected
router.post('/invitations/:invitationId/accept', authenticateToken, validateUUIDParam('invitationId'), async (req, res) => {
  const { invitationId } = req.params;
  const { userId } = req.body;

  if (!userId) {
    return res.status(400).json({ error: 'User ID is required' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Get invitation
    const inviteResult = await client.query(
      `SELECT * FROM contact_invitations
       WHERE id = $1 AND status = 'pending' AND expires_at > NOW()`,
      [invitationId]
    );

    if (inviteResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Invitation not found or expired' });
    }

    const invitation = inviteResult.rows[0];

    // Mark invitation as accepted
    await client.query(
      'UPDATE contact_invitations SET status = $1 WHERE id = $2',
      ['accepted', invitationId]
    );

    // If invitation has a session, add user to it
    if (invitation.session_id) {
      // Check if session is still active
      const sessionResult = await client.query(
        'SELECT * FROM bill_sessions WHERE id = $1 AND status = $2',
        [invitation.session_id, 'active']
      );

      if (sessionResult.rows.length > 0) {
        // Add user to session
        await client.query(
          `INSERT INTO session_participants (session_id, user_id, role)
           VALUES ($1, $2, 'participant')
           ON CONFLICT (session_id, user_id) DO NOTHING`,
          [invitation.session_id, userId]
        );
      }
    }

    await client.query('COMMIT');

    res.json({
      success: true,
      message: 'Invitation accepted',
      sessionId: invitation.session_id
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error accepting invitation:', error);
    res.status(500).json({ error: 'Failed to accept invitation' });
  } finally {
    client.release();
  }
});

// Add participants to session from contacts (protected)
router.post('/sessions/:sessionId/add-participants', authenticateToken, validateUUIDParam('sessionId'), async (req, res) => {
  const { sessionId } = req.params;
  const { userIds, sendInvites } = req.body;

  if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
    return res.status(400).json({ error: 'User IDs array is required' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Verify session exists and is active
    const sessionResult = await client.query(
      'SELECT * FROM bill_sessions WHERE id = $1 AND status = $2',
      [sessionId, 'active']
    );

    if (sessionResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Session not found or not active' });
    }

    const added = [];
    const alreadyInSession = [];

    for (const userId of userIds) {
      // Check if already in session
      const existingResult = await client.query(
        'SELECT * FROM session_participants WHERE session_id = $1 AND user_id = $2',
        [sessionId, userId]
      );

      if (existingResult.rows.length > 0) {
        alreadyInSession.push(userId);
        continue;
      }

      // Add to session
      await client.query(
        'INSERT INTO session_participants (session_id, user_id, role) VALUES ($1, $2, $3)',
        [sessionId, userId, 'participant']
      );

      added.push(userId);

      // If sendInvites is true, create invitation record (for notifications)
      if (sendInvites) {
        const userResult = await client.query(
          'SELECT phone FROM users WHERE id = $1',
          [userId]
        );

        if (userResult.rows.length > 0) {
          const session = sessionResult.rows[0];
          await client.query(
            `INSERT INTO contact_invitations (inviter_id, phone, session_id, status)
             VALUES ($1, $2, $3, 'accepted')`,
            [session.creator_id, userResult.rows[0].phone, sessionId]
          );
        }
      }
    }

    await client.query('COMMIT');

    res.json({
      success: true,
      addedCount: added.length,
      alreadyInSessionCount: alreadyInSession.length,
      added,
      alreadyInSession
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error adding participants:', error);
    res.status(500).json({ error: 'Failed to add participants' });
  } finally {
    client.release();
  }
});

module.exports = router;
