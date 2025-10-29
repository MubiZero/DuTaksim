const express = require('express');
const router = express.Router();
const pool = require('../config/database');
const { authenticateToken, generateToken } = require('../middleware/auth');
const { validateUserRegistration, validateUUIDParam } = require('../middleware/validation');
const { authLimiter } = require('../middleware/rateLimiter');

// Register or login user (simple: just name + phone)
router.post('/register', authLimiter, validateUserRegistration, async (req, res) => {
  try {
    const { name, phone } = req.body;

    // Check if user exists
    const existingUser = await pool.query(
      'SELECT * FROM users WHERE phone = $1',
      [phone]
    );

    if (existingUser.rows.length > 0) {
      const user = existingUser.rows[0];
      const token = generateToken(user.id, user.phone);
      return res.json({ user, token });
    }

    // Create new user
    const result = await pool.query(
      'INSERT INTO users (name, phone) VALUES ($1, $2) RETURNING *',
      [name, phone]
    );

    const user = result.rows[0];
    const token = generateToken(user.id, user.phone);
    res.status(201).json({ user, token });
  } catch (error) {
    console.error('Error registering user:', error);
    res.status(500).json({ error: 'Failed to register user' });
  }
});

// Get user by phone
router.get('/phone/:phone', async (req, res) => {
  try {
    const { phone } = req.params;
    const result = await pool.query(
      'SELECT * FROM users WHERE phone = $1',
      [phone]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ user: result.rows[0] });
  } catch (error) {
    console.error('Error fetching user:', error);
    res.status(500).json({ error: 'Failed to fetch user' });
  }
});

// Get user statistics (protected)
router.get('/:userId/stats', authenticateToken, validateUUIDParam('userId'), async (req, res) => {
  try {
    const { userId } = req.params;

    // Total debts owed by user
    const debtsOwed = await pool.query(
      'SELECT SUM(amount) as total FROM debts WHERE debtor_id = $1 AND is_paid = false',
      [userId]
    );

    // Total debts owed to user
    const debtsOwedTo = await pool.query(
      'SELECT SUM(amount) as total FROM debts WHERE creditor_id = $1 AND is_paid = false',
      [userId]
    );

    // Total bills participated
    const billsCount = await pool.query(
      'SELECT COUNT(DISTINCT bill_id) as count FROM bill_participants WHERE user_id = $1',
      [userId]
    );

    res.json({
      debtsOwed: parseFloat(debtsOwed.rows[0].total || 0),
      debtsOwedTo: parseFloat(debtsOwedTo.rows[0].total || 0),
      billsCount: parseInt(billsCount.rows[0].count || 0),
    });
  } catch (error) {
    console.error('Error fetching user stats:', error);
    res.status(500).json({ error: 'Failed to fetch user statistics' });
  }
});

module.exports = router;
