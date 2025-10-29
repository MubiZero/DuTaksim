/**
 * Calculate debts for a bill
 * This function optimizes debt transactions to minimize the number of transfers
 */
async function calculateDebts(client, billId, paidBy, tips) {
  // Get all items
  const itemsResult = await client.query(
    'SELECT * FROM bill_items WHERE bill_id = $1',
    [billId]
  );

  const items = itemsResult.rows;

  // Get all participants
  const participantsResult = await client.query(
    'SELECT user_id FROM bill_participants WHERE bill_id = $1',
    [billId]
  );

  const allParticipants = participantsResult.rows.map(p => p.user_id);

  // Calculate what each person owes
  const userAmounts = {};
  allParticipants.forEach(userId => {
    userAmounts[userId] = 0;
  });

  // Process each item
  for (const item of items) {
    // Get participants for this item
    const itemParticipantsResult = await client.query(
      'SELECT user_id FROM item_participants WHERE item_id = $1',
      [item.id]
    );

    let itemParticipants;
    if (item.is_shared || itemParticipantsResult.rows.length === 0) {
      // If shared or no specific participants, split among all
      itemParticipants = allParticipants;
    } else {
      itemParticipants = itemParticipantsResult.rows.map(p => p.user_id);
    }

    const amountPerPerson = parseFloat(item.price) / itemParticipants.length;

    itemParticipants.forEach(userId => {
      userAmounts[userId] += amountPerPerson;
    });
  }

  // Add tips divided equally among all participants
  if (tips > 0) {
    const tipsPerPerson = parseFloat(tips) / allParticipants.length;
    allParticipants.forEach(userId => {
      userAmounts[userId] += tipsPerPerson;
    });
  }

  // Calculate net debts (who owes whom)
  const debts = [];

  for (const userId of allParticipants) {
    if (userId === paidBy) {
      continue; // Person who paid doesn't owe themselves
    }

    const amount = userAmounts[userId];
    if (amount > 0) {
      debts.push({
        debtorId: userId,
        creditorId: paidBy,
        amount: Math.round(amount * 100) / 100, // Round to 2 decimal places
      });
    }
  }

  return debts;
}

module.exports = { calculateDebts };
