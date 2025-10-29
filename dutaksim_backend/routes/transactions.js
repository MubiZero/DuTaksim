const express = require('express');
const router = express.Router();
const pool = require('../config/database');
const { authenticateToken } = require('../middleware/auth');
const { validateUUIDParam } = require('../middleware/validation');

// Get all debts for a user (what they owe and what's owed to them) - protected
router.get('/user/:userId', authenticateToken, validateUUIDParam('userId'), async (req, res) => {
  try {
    const { userId } = req.params;

    // Debts user owes
    const debtsOwed = await pool.query(
      `SELECT d.*, b.title as bill_title, b.created_at as bill_date,
              u.name as creditor_name, u.phone as creditor_phone
       FROM debts d
       JOIN bills b ON d.bill_id = b.id
       JOIN users u ON d.creditor_id = u.id
       WHERE d.debtor_id = $1
       ORDER BY d.created_at DESC`,
      [userId]
    );

    // Debts owed to user
    const debtsOwedTo = await pool.query(
      `SELECT d.*, b.title as bill_title, b.created_at as bill_date,
              u.name as debtor_name, u.phone as debtor_phone
       FROM debts d
       JOIN bills b ON d.bill_id = b.id
       JOIN users u ON d.debtor_id = u.id
       WHERE d.creditor_id = $1
       ORDER BY d.created_at DESC`,
      [userId]
    );

    res.json({
      debtsOwed: debtsOwed.rows,
      debtsOwedTo: debtsOwedTo.rows,
    });
  } catch (error) {
    console.error('Error fetching transactions:', error);
    res.status(500).json({ error: 'Failed to fetch transactions' });
  }
});

module.exports = router;
