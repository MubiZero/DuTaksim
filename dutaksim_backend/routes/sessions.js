const express = require('express');
const router = express.Router();
const pool = require('../config/database');
const { authenticateToken } = require('../middleware/auth');
const { validateSessionCreation, validateSessionItem, validateUUIDParam } = require('../middleware/validation');
const { sessionCreationLimiter } = require('../middleware/rateLimiter');

// Generate random session code
function generateSessionCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

// Calculate distance between two coordinates (Haversine formula)
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // Earth's radius in meters
  const φ1 = lat1 * Math.PI / 180;
  const φ2 = lat2 * Math.PI / 180;
  const Δφ = (lat2 - lat1) * Math.PI / 180;
  const Δλ = (lon2 - lon1) * Math.PI / 180;

  const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
    Math.cos(φ1) * Math.cos(φ2) *
    Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // Distance in meters
}

// Create a new session (protected)
router.post('/create', sessionCreationLimiter, authenticateToken, validateSessionCreation, async (req, res) => {
  const { name, creatorId, latitude, longitude, radius } = req.body;

  console.log('Create session request:', {
    name,
    creatorId,
    latitude,
    longitude,
    radius,
    body: req.body
  });

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Generate unique session code
    let sessionCode;
    let isUnique = false;
    while (!isUnique) {
      sessionCode = generateSessionCode();
      const checkResult = await client.query(
        'SELECT id FROM bill_sessions WHERE session_code = $1',
        [sessionCode]
      );
      isUnique = checkResult.rows.length === 0;
    }

    // Create session
    const sessionResult = await client.query(
      `INSERT INTO bill_sessions (session_code, name, creator_id, latitude, longitude, radius)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [sessionCode, name, creatorId, latitude, longitude, radius || 50]
    );

    const session = sessionResult.rows[0];

    // Add creator as participant
    await client.query(
      `INSERT INTO session_participants (session_id, user_id, role)
       VALUES ($1, $2, 'creator')`,
      [session.id, creatorId]
    );

    await client.query('COMMIT');

    // Get creator info
    const creatorResult = await client.query(
      'SELECT id, name, phone FROM users WHERE id = $1',
      [creatorId]
    );

    const creator = creatorResult.rows[0];

    res.json({
      ...session,
      creator_name: creator.name,
      participants: [{
        ...creator,
        role: 'creator',
        joined_at: new Date().toISOString()
      }],
      items: []
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error creating session:', error);
    res.status(500).json({ error: 'Failed to create session' });
  } finally {
    client.release();
  }
});

// Get nearby active sessions (protected)
router.get('/nearby', authenticateToken, async (req, res) => {
  const { latitude, longitude, radius } = req.query;

  if (!latitude || !longitude) {
    return res.status(400).json({ error: 'Latitude and longitude are required' });
  }

  const searchRadius = parseInt(radius) || 100; // Default 100m

  try {
    const result = await pool.query(
      `SELECT s.*, u.name as creator_name,
              (SELECT COUNT(*) FROM session_participants WHERE session_id = s.id) as participant_count
       FROM bill_sessions s
       JOIN users u ON s.creator_id = u.id
       WHERE s.status = 'active'
       AND s.expires_at > NOW()
       AND s.latitude IS NOT NULL
       AND s.longitude IS NOT NULL`,
      []
    );

    // Filter by distance
    const userLat = parseFloat(latitude);
    const userLon = parseFloat(longitude);

    const nearbySessions = result.rows.filter(session => {
      const distance = calculateDistance(
        userLat,
        userLon,
        parseFloat(session.latitude),
        parseFloat(session.longitude)
      );
      return distance <= searchRadius;
    }).map(session => ({
      ...session,
      distance: Math.round(calculateDistance(
        userLat,
        userLon,
        parseFloat(session.latitude),
        parseFloat(session.longitude)
      ))
    }));

    res.json(nearbySessions);
  } catch (error) {
    console.error('Error getting nearby sessions:', error);
    res.status(500).json({ error: 'Failed to get nearby sessions' });
  }
});

// Join session by code or ID (protected)
router.post('/join', authenticateToken, async (req, res) => {
  const { sessionCode, sessionId, userId } = req.body;

  console.log('Join session request:', {
    sessionCode,
    sessionId,
    userId,
    body: req.body
  });

  if (!userId || (!sessionCode && !sessionId)) {
    console.log('Join session - Missing required fields');
    return res.status(400).json({ error: 'User ID and session code or ID are required' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Get session
    let sessionResult;
    if (sessionCode) {
      sessionResult = await client.query(
        'SELECT * FROM bill_sessions WHERE session_code = $1 AND status = $2 AND expires_at > NOW()',
        [sessionCode, 'active']
      );
    } else {
      sessionResult = await client.query(
        'SELECT * FROM bill_sessions WHERE id = $1 AND status = $2 AND expires_at > NOW()',
        [sessionId, 'active']
      );
    }

    if (sessionResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Session not found or expired' });
    }

    const session = sessionResult.rows[0];

    // Check if already joined
    const existingResult = await client.query(
      'SELECT * FROM session_participants WHERE session_id = $1 AND user_id = $2',
      [session.id, userId]
    );

    if (existingResult.rows.length > 0) {
      await client.query('COMMIT');
      return res.json({ message: 'Already in session', session });
    }

    // Add participant
    await client.query(
      'INSERT INTO session_participants (session_id, user_id, role) VALUES ($1, $2, $3)',
      [session.id, userId, 'participant']
    );

    await client.query('COMMIT');

    // Get full session details
    const fullSession = await getSessionDetails(session.id);
    res.json(fullSession);
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error joining session:', error);
    res.status(500).json({ error: 'Failed to join session' });
  } finally {
    client.release();
  }
});

// Get session details (protected)
router.get('/:sessionId', authenticateToken, validateUUIDParam('sessionId'), async (req, res) => {
  const { sessionId } = req.params;

  try {
    const session = await getSessionDetails(sessionId);
    if (!session) {
      return res.status(404).json({ error: 'Session not found' });
    }
    res.json(session);
  } catch (error) {
    console.error('Error getting session:', error);
    res.status(500).json({ error: 'Failed to get session' });
  }
});

// Add item to session (protected)
router.post('/:sessionId/items', authenticateToken, validateUUIDParam('sessionId'), validateSessionItem, async (req, res) => {
  const { sessionId } = req.params;
  const { name, price, addedBy, forUserId, isShared } = req.body;

  try {
    const result = await pool.query(
      `INSERT INTO session_items (session_id, added_by, name, price, for_user_id, is_shared)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [sessionId, addedBy, name, price, forUserId, isShared || false]
    );

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error adding item:', error);
    res.status(500).json({ error: 'Failed to add item' });
  }
});

// Get session items (protected)
router.get('/:sessionId/items', authenticateToken, validateUUIDParam('sessionId'), async (req, res) => {
  const { sessionId } = req.params;

  try {
    const result = await pool.query(
      `SELECT si.*, u.name as added_by_name, fu.name as for_user_name
       FROM session_items si
       JOIN users u ON si.added_by = u.id
       LEFT JOIN users fu ON si.for_user_id = fu.id
       WHERE si.session_id = $1
       ORDER BY si.created_at DESC`,
      [sessionId]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Error getting items:', error);
    res.status(500).json({ error: 'Failed to get items' });
  }
});

// Delete item from session (protected)
router.delete('/:sessionId/items/:itemId', authenticateToken, validateUUIDParam('sessionId'), validateUUIDParam('itemId'), async (req, res) => {
  const { itemId } = req.params;

  try {
    await pool.query('DELETE FROM session_items WHERE id = $1', [itemId]);
    res.json({ message: 'Item deleted' });
  } catch (error) {
    console.error('Error deleting item:', error);
    res.status(500).json({ error: 'Failed to delete item' });
  }
});

// Finalize session and create bill (protected)
router.post('/:sessionId/finalize', authenticateToken, validateUUIDParam('sessionId'), async (req, res) => {
  const { sessionId } = req.params;
  const { title, description, paidBy, tips } = req.body;

  if (!paidBy) {
    return res.status(400).json({ error: 'Paid by user ID is required' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Get session
    const sessionResult = await client.query(
      'SELECT * FROM bill_sessions WHERE id = $1',
      [sessionId]
    );

    if (sessionResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Session not found' });
    }

    // Get all items
    const itemsResult = await client.query(
      'SELECT * FROM session_items WHERE session_id = $1',
      [sessionId]
    );

    const items = itemsResult.rows;
    const totalAmount = items.reduce((sum, item) => sum + parseFloat(item.price), 0);

    // Create bill
    const billResult = await client.query(
      `INSERT INTO bills (title, description, total_amount, paid_by, tips)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [title || 'Session Bill', description, totalAmount, paidBy, tips || 0]
    );

    const bill = billResult.rows[0];

    // Get participants
    const participantsResult = await client.query(
      'SELECT user_id FROM session_participants WHERE session_id = $1',
      [sessionId]
    );

    // Add bill participants
    for (const participant of participantsResult.rows) {
      await client.query(
        'INSERT INTO bill_participants (bill_id, user_id) VALUES ($1, $2)',
        [bill.id, participant.user_id]
      );
    }

    // Add bill items
    for (const item of items) {
      const billItemResult = await client.query(
        `INSERT INTO bill_items (bill_id, name, price, is_shared)
         VALUES ($1, $2, $3, $4)
         RETURNING *`,
        [bill.id, item.name, item.price, item.is_shared]
      );

      const billItem = billItemResult.rows[0];

      // If item is for specific user, add to item_participants
      if (item.for_user_id && !item.is_shared) {
        await client.query(
          'INSERT INTO item_participants (item_id, user_id) VALUES ($1, $2)',
          [billItem.id, item.for_user_id]
        );
      }
    }

    // Calculate debts (reuse existing debtCalculator)
    const debtCalculator = require('../utils/debtCalculator');
    await debtCalculator.calculateDebts(client, bill.id, paidBy, tips || 0);

    // Update session status
    await client.query(
      'UPDATE bill_sessions SET status = $1, bill_id = $2 WHERE id = $3',
      ['finalized', bill.id, sessionId]
    );

    await client.query('COMMIT');

    res.json({ message: 'Session finalized', billId: bill.id });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error finalizing session:', error);
    res.status(500).json({ error: 'Failed to finalize session' });
  } finally {
    client.release();
  }
});

// Close/cancel session (protected)
router.post('/:sessionId/close', authenticateToken, validateUUIDParam('sessionId'), async (req, res) => {
  const { sessionId } = req.params;

  try {
    await pool.query(
      'UPDATE bill_sessions SET status = $1 WHERE id = $2',
      ['closed', sessionId]
    );
    res.json({ message: 'Session closed' });
  } catch (error) {
    console.error('Error closing session:', error);
    res.status(500).json({ error: 'Failed to close session' });
  }
});

// Helper function to get full session details
async function getSessionDetails(sessionId) {
  const sessionResult = await pool.query(
    `SELECT s.*, u.name as creator_name
     FROM bill_sessions s
     JOIN users u ON s.creator_id = u.id
     WHERE s.id = $1`,
    [sessionId]
  );

  if (sessionResult.rows.length === 0) {
    return null;
  }

  const session = sessionResult.rows[0];

  // Get participants
  const participantsResult = await pool.query(
    `SELECT u.id, u.name, u.phone, sp.role, sp.joined_at
     FROM session_participants sp
     JOIN users u ON sp.user_id = u.id
     WHERE sp.session_id = $1
     ORDER BY sp.joined_at`,
    [sessionId]
  );

  // Get items
  const itemsResult = await pool.query(
    `SELECT si.*, u.name as added_by_name, fu.name as for_user_name
     FROM session_items si
     JOIN users u ON si.added_by = u.id
     LEFT JOIN users fu ON si.for_user_id = fu.id
     WHERE si.session_id = $1
     ORDER BY si.created_at`,
    [sessionId]
  );

  return {
    ...session,
    participants: participantsResult.rows,
    items: itemsResult.rows
  };
}

module.exports = router;
