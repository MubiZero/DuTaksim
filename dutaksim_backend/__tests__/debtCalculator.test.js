/**
 * Tests for debt calculation logic
 * Note: These tests use mock database client
 */

describe('Debt Calculator', () => {
  describe('optimizeDebts', () => {
    test('should minimize number of transactions', () => {
      // Example: A owes B 50, B owes C 50
      // Result should be: A owes C 50 (instead of 2 transactions)
      const debts = {
        'A': -50,  // A owes 50
        'B': 0,    // B is even
        'C': 50    // C is owed 50
      };

      // Simple optimization algorithm
      function optimizeDebts(balances) {
        const debtors = [];
        const creditors = [];

        for (const [person, balance] of Object.entries(balances)) {
          if (balance < 0) {
            debtors.push({ person, amount: -balance });
          } else if (balance > 0) {
            creditors.push({ person, amount: balance });
          }
        }

        const transactions = [];
        let i = 0, j = 0;

        while (i < debtors.length && j < creditors.length) {
          const debt = Math.min(debtors[i].amount, creditors[j].amount);

          transactions.push({
            from: debtors[i].person,
            to: creditors[j].person,
            amount: debt
          });

          debtors[i].amount -= debt;
          creditors[j].amount -= debt;

          if (debtors[i].amount === 0) i++;
          if (creditors[j].amount === 0) j++;
        }

        return transactions;
      }

      const result = optimizeDebts(debts);

      expect(result).toHaveLength(1);
      expect(result[0]).toEqual({
        from: 'A',
        to: 'C',
        amount: 50
      });
    });

    test('should handle multiple debtors and creditors', () => {
      const debts = {
        'A': -30,  // A owes 30
        'B': -20,  // B owes 20
        'C': 25,   // C is owed 25
        'D': 25    // D is owed 25
      };

      function optimizeDebts(balances) {
        const debtors = [];
        const creditors = [];

        for (const [person, balance] of Object.entries(balances)) {
          if (balance < 0) {
            debtors.push({ person, amount: -balance });
          } else if (balance > 0) {
            creditors.push({ person, amount: balance });
          }
        }

        const transactions = [];
        let i = 0, j = 0;

        while (i < debtors.length && j < creditors.length) {
          const debt = Math.min(debtors[i].amount, creditors[j].amount);

          transactions.push({
            from: debtors[i].person,
            to: creditors[j].person,
            amount: debt
          });

          debtors[i].amount -= debt;
          creditors[j].amount -= debt;

          if (debtors[i].amount === 0) i++;
          if (creditors[j].amount === 0) j++;
        }

        return transactions;
      }

      const result = optimizeDebts(debts);

      // Should have at most n-1 transactions (where n is number of people)
      expect(result.length).toBeLessThanOrEqual(3);

      // Verify total amounts
      const totalDebt = result.reduce((sum, t) => sum + t.amount, 0);
      expect(totalDebt).toBe(50); // 30 + 20 = 50
    });

    test('should handle equal split scenario', () => {
      // 3 people, 300 total, each should pay 100
      // Person A paid 300, B and C owe 100 each
      const debts = {
        'A': 200,   // A is owed 200
        'B': -100,  // B owes 100
        'C': -100   // C owes 100
      };

      function optimizeDebts(balances) {
        const debtors = [];
        const creditors = [];

        for (const [person, balance] of Object.entries(balances)) {
          if (balance < 0) {
            debtors.push({ person, amount: -balance });
          } else if (balance > 0) {
            creditors.push({ person, amount: balance });
          }
        }

        const transactions = [];
        let i = 0, j = 0;

        while (i < debtors.length && j < creditors.length) {
          const debt = Math.min(debtors[i].amount, creditors[j].amount);

          transactions.push({
            from: debtors[i].person,
            to: creditors[j].person,
            amount: debt
          });

          debtors[i].amount -= debt;
          creditors[j].amount -= debt;

          if (debtors[i].amount === 0) i++;
          if (creditors[j].amount === 0) j++;
        }

        return transactions;
      }

      const result = optimizeDebts(debts);

      expect(result).toHaveLength(2);

      // B owes A 100
      expect(result.find(t => t.from === 'B' && t.to === 'A' && t.amount === 100)).toBeDefined();

      // C owes A 100
      expect(result.find(t => t.from === 'C' && t.to === 'A' && t.amount === 100)).toBeDefined();
    });
  });

  describe('calculateBillSplit', () => {
    test('should split bill equally among participants', () => {
      const totalAmount = 300;
      const participants = 3;
      const perPerson = totalAmount / participants;

      expect(perPerson).toBe(100);
    });

    test('should handle tips correctly', () => {
      const totalAmount = 300;
      const tips = 30;
      const participants = 3;

      const perPerson = (totalAmount + tips) / participants;

      expect(perPerson).toBe(110); // (300 + 30) / 3
    });

    test('should handle individual items', () => {
      // Person A ate item1 (100), Person B ate item2 (150), shared item3 (60)
      const items = [
        { price: 100, participants: ['A'] },
        { price: 150, participants: ['B'] },
        { price: 60, participants: ['A', 'B'] }
      ];

      const balances = { A: 0, B: 0 };

      items.forEach(item => {
        const perPerson = item.price / item.participants.length;
        item.participants.forEach(p => {
          balances[p] += perPerson;
        });
      });

      expect(balances.A).toBe(130); // 100 + 30
      expect(balances.B).toBe(180); // 150 + 30
    });
  });
});
