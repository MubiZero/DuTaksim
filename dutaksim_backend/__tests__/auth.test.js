/**
 * Tests for authentication middleware
 */

const { generateToken } = require('../middleware/auth');
const jwt = require('jsonwebtoken');

// Set up test environment
process.env.JWT_SECRET = 'test_secret_key_for_testing';
process.env.JWT_EXPIRES_IN = '1h';

describe('Authentication', () => {
  describe('generateToken', () => {
    test('should generate a valid JWT token', () => {
      const userId = '123e4567-e89b-12d3-a456-426614174000';
      const phone = '+992123456789';

      const token = generateToken(userId, phone);

      expect(token).toBeDefined();
      expect(typeof token).toBe('string');
      expect(token.split('.')).toHaveLength(3); // JWT has 3 parts
    });

    test('token should contain correct payload', () => {
      const userId = '123e4567-e89b-12d3-a456-426614174000';
      const phone = '+992123456789';

      const token = generateToken(userId, phone);
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      expect(decoded.userId).toBe(userId);
      expect(decoded.phone).toBe(phone);
      expect(decoded.iat).toBeDefined(); // issued at
      expect(decoded.exp).toBeDefined(); // expiration
    });

    test('token should expire after specified time', () => {
      const userId = '123e4567-e89b-12d3-a456-426614174000';
      const phone = '+992123456789';

      const token = generateToken(userId, phone);
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      const expiresIn = decoded.exp - decoded.iat;
      expect(expiresIn).toBe(3600); // 1 hour = 3600 seconds
    });

    test('should fail to verify with wrong secret', () => {
      const userId = '123e4567-e89b-12d3-a456-426614174000';
      const phone = '+992123456789';

      const token = generateToken(userId, phone);

      expect(() => {
        jwt.verify(token, 'wrong_secret');
      }).toThrow();
    });
  });
});
