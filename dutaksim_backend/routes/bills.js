const express = require('express');
const router = express.Router();
const pool = require('../config/database');
const { calculateDebts } = require('../utils/debtCalculator');
const { authenticateToken } = require('../middleware/auth');
const { validateBillCreation, validateUUIDParam } = require('../middleware/validation');

// Create a new bill (protected)
router.post('/', authenticateToken, validateBillCreation, async (req, res) => {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const { title, description, totalAmount, paidBy, tips, participants, items } = req.body;

    // Create bill
    const billResult = await client.query(
      'INSERT INTO bills (title, description, total_amount, paid_by, tips) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [title, description || '', totalAmount, paidBy, tips || 0]
    );

    const bill = billResult.rows[0];

    // Add participants
    for (const participantId of participants) {
      await client.query(
        'INSERT INTO bill_participants (bill_id, user_id) VALUES ($1, $2)',
        [bill.id, participantId]
      );
    }

    // Add items
    for (const item of items) {
      const itemResult = await client.query(
        'INSERT INTO bill_items (bill_id, name, price, is_shared) VALUES ($1, $2, $3, $4) RETURNING *',
        [bill.id, item.name, item.price, item.isShared || false]
      );

      const billItem = itemResult.rows[0];

      // Add item participants
      if (item.participants && item.participants.length > 0) {
        for (const participantId of item.participants) {
          await client.query(
            'INSERT INTO item_participants (item_id, user_id) VALUES ($1, $2)',
            [billItem.id, participantId]
          );
        }
      }
    }

    // Calculate debts
    const debts = await calculateDebts(client, bill.id, paidBy, tips || 0);

    // Save debts
    for (const debt of debts) {
      await client.query(
        'INSERT INTO debts (bill_id, debtor_id, creditor_id, amount) VALUES ($1, $2, $3, $4)',
        [bill.id, debt.debtorId, debt.creditorId, debt.amount]
      );
    }

    await client.query('COMMIT');

    // Fetch complete bill data
    const completeBill = await getBillById(bill.id);
    res.status(201).json({ bill: completeBill });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error creating bill:', error);
    res.status(500).json({ error: 'Failed to create bill' });
  } finally {
    client.release();
  }
});

// Get all bills for a user (protected, with pagination)
router.get('/user/:userId', authenticateToken, validateUUIDParam('userId'), async (req, res) => {
  try {
    const { userId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 20, 100); // Max 100 per page
    const offset = (page - 1) * limit;

    // Get total count
    const countResult = await pool.query(
      `SELECT COUNT(DISTINCT b.id) as total
       FROM bills b
       LEFT JOIN bill_participants bp ON b.id = bp.bill_id
       WHERE b.paid_by = $1 OR bp.user_id = $1`,
      [userId]
    );

    const totalCount = parseInt(countResult.rows[0].total);
    const totalPages = Math.ceil(totalCount / limit);

    // Get paginated bills
    const result = await pool.query(
      `SELECT DISTINCT b.*, u.name as paid_by_name, u.phone as paid_by_phone
       FROM bills b
       JOIN users u ON b.paid_by = u.id
       LEFT JOIN bill_participants bp ON b.id = bp.bill_id
       WHERE b.paid_by = $1 OR bp.user_id = $1
       ORDER BY b.created_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );

    res.json({
      bills: result.rows,
      pagination: {
        page,
        limit,
        totalCount,
        totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1
      }
    });
  } catch (error) {
    console.error('Error fetching bills:', error);
    res.status(500).json({ error: 'Failed to fetch bills' });
  }
});

// Get bill by ID with all details (protected)
router.get('/:billId', authenticateToken, validateUUIDParam('billId'), async (req, res) => {
  try {
    const { billId } = req.params;
    const bill = await getBillById(billId);

    if (!bill) {
      return res.status(404).json({ error: 'Bill not found' });
    }

    res.json({ bill });
  } catch (error) {
    console.error('Error fetching bill:', error);
    res.status(500).json({ error: 'Failed to fetch bill' });
  }
});

// Mark debt as paid (protected)
router.patch('/debts/:debtId/pay', authenticateToken, validateUUIDParam('debtId'), async (req, res) => {
  try {
    const { debtId } = req.params;

    const result = await pool.query(
      'UPDATE debts SET is_paid = true, paid_at = CURRENT_TIMESTAMP WHERE id = $1 RETURNING *',
      [debtId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Debt not found' });
    }

    res.json({ debt: result.rows[0] });
  } catch (error) {
    console.error('Error marking debt as paid:', error);
    res.status(500).json({ error: 'Failed to mark debt as paid' });
  }
});

// Helper function to get complete bill data
async function getBillById(billId) {
  const billResult = await pool.query(
    `SELECT b.*, u.name as paid_by_name, u.phone as paid_by_phone
     FROM bills b
     JOIN users u ON b.paid_by = u.id
     WHERE b.id = $1`,
    [billId]
  );

  if (billResult.rows.length === 0) {
    return null;
  }

  const bill = billResult.rows[0];

  // Get participants
  const participantsResult = await pool.query(
    `SELECT u.* FROM users u
     JOIN bill_participants bp ON u.id = bp.user_id
     WHERE bp.bill_id = $1`,
    [billId]
  );
  bill.participants = participantsResult.rows;

  // Get items
  const itemsResult = await pool.query(
    'SELECT * FROM bill_items WHERE bill_id = $1',
    [billId]
  );

  // Get all item participants in one query (fix N+1 problem)
  const itemIds = itemsResult.rows.map(item => item.id);
  let itemParticipantsMap = {};

  if (itemIds.length > 0) {
    const allItemParticipantsResult = await pool.query(
      `SELECT ip.item_id, u.*
       FROM item_participants ip
       JOIN users u ON ip.user_id = u.id
       WHERE ip.item_id = ANY($1)`,
      [itemIds]
    );

    // Group participants by item_id
    allItemParticipantsResult.rows.forEach(row => {
      const itemId = row.item_id;
      if (!itemParticipantsMap[itemId]) {
        itemParticipantsMap[itemId] = [];
      }
      // Remove item_id from user object
      const { item_id, ...user } = row;
      itemParticipantsMap[itemId].push(user);
    });
  }

  // Attach participants to each item
  itemsResult.rows.forEach(item => {
    item.participants = itemParticipantsMap[item.id] || [];
  });

  bill.items = itemsResult.rows;

  // Get debts
  const debtsResult = await pool.query(
    `SELECT d.*,
            u1.name as debtor_name, u1.phone as debtor_phone,
            u2.name as creditor_name, u2.phone as creditor_phone
     FROM debts d
     JOIN users u1 ON d.debtor_id = u1.id
     JOIN users u2 ON d.creditor_id = u2.id
     WHERE d.bill_id = $1`,
    [billId]
  );
  bill.debts = debtsResult.rows;

  return bill;
}

module.exports = router;
