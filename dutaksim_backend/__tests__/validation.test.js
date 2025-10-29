/**
 * Tests for validation middleware
 */

const {
  validatePhone,
  validateName,
  validatePrice,
  validateUUID,
  validateCoordinates,
  validateSessionCode
} = require('../middleware/validation');

describe('Validation Functions', () => {
  describe('validatePhone', () => {
    test('should accept valid phone numbers', () => {
      expect(validatePhone('+992123456789')).toBe(true);
      expect(validatePhone('992123456789')).toBe(true);
      expect(validatePhone('1234567890')).toBe(true);
    });

    test('should accept phone numbers with spaces and dashes', () => {
      expect(validatePhone('+992 123 456 789')).toBe(true);
      expect(validatePhone('992-123-456-789')).toBe(true);
    });

    test('should reject invalid phone numbers', () => {
      expect(validatePhone('')).toBe(false);
      expect(validatePhone('12345')).toBe(false); // too short
      expect(validatePhone('12345678901234567')).toBe(false); // too long
      expect(validatePhone(null)).toBe(false);
      expect(validatePhone(undefined)).toBe(false);
      expect(validatePhone(123456789)).toBe(false); // number instead of string
    });
  });

  describe('validateName', () => {
    test('should accept valid names', () => {
      expect(validateName('John')).toBe(true);
      expect(validateName('Иван Иванов')).toBe(true);
      expect(validateName('محمد')).toBe(true);
      expect(validateName('A'.repeat(100))).toBe(true);
    });

    test('should reject invalid names', () => {
      expect(validateName('')).toBe(false);
      expect(validateName('A')).toBe(false); // too short
      expect(validateName('A'.repeat(101))).toBe(false); // too long
      expect(validateName('  ')).toBe(false); // only spaces
      expect(validateName(null)).toBe(false);
      expect(validateName(undefined)).toBe(false);
    });
  });

  describe('validatePrice', () => {
    test('should accept valid prices', () => {
      expect(validatePrice(10)).toBe(true);
      expect(validatePrice(100.50)).toBe(true);
      expect(validatePrice('50.99')).toBe(true);
      expect(validatePrice(999999)).toBe(true);
    });

    test('should reject invalid prices', () => {
      expect(validatePrice(0)).toBe(false);
      expect(validatePrice(-10)).toBe(false);
      expect(validatePrice(1000000)).toBe(false); // too large
      expect(validatePrice('abc')).toBe(false);
      expect(validatePrice(null)).toBe(false);
      expect(validatePrice(undefined)).toBe(false);
    });
  });

  describe('validateUUID', () => {
    test('should accept valid UUIDs', () => {
      expect(validateUUID('123e4567-e89b-12d3-a456-426614174000')).toBe(true);
      expect(validateUUID('550e8400-e29b-41d4-a716-446655440000')).toBe(true);
    });

    test('should reject invalid UUIDs', () => {
      expect(validateUUID('not-a-uuid')).toBe(false);
      expect(validateUUID('123e4567-e89b-12d3-a456')).toBe(false); // too short
      expect(validateUUID('123e4567-e89b-12d3-a456-42661417400g')).toBe(false); // invalid char
      expect(validateUUID('')).toBe(false);
      expect(validateUUID(null)).toBe(false);
    });
  });

  describe('validateCoordinates', () => {
    test('should accept valid coordinates', () => {
      expect(validateCoordinates(38.5736, 68.7738)).toBe(true); // Dushanbe
      expect(validateCoordinates(40.7128, -74.0060)).toBe(true); // New York
      expect(validateCoordinates(0, 0)).toBe(true); // Null Island
      expect(validateCoordinates(-90, -180)).toBe(true); // Edge cases
      expect(validateCoordinates(90, 180)).toBe(true);
    });

    test('should reject invalid coordinates', () => {
      expect(validateCoordinates(91, 0)).toBe(false); // lat too high
      expect(validateCoordinates(-91, 0)).toBe(false); // lat too low
      expect(validateCoordinates(0, 181)).toBe(false); // lon too high
      expect(validateCoordinates(0, -181)).toBe(false); // lon too low
      expect(validateCoordinates('abc', 0)).toBe(false);
      expect(validateCoordinates(0, 'abc')).toBe(false);
      expect(validateCoordinates(null, null)).toBe(false);
    });
  });

  describe('validateSessionCode', () => {
    test('should accept valid session codes', () => {
      expect(validateSessionCode('ABC123')).toBe(true);
      expect(validateSessionCode('XYZ999')).toBe(true);
      expect(validateSessionCode('A23B4C')).toBe(true);
    });

    test('should reject invalid session codes', () => {
      expect(validateSessionCode('abc123')).toBe(false); // lowercase
      expect(validateSessionCode('ABC12')).toBe(false); // too short
      expect(validateSessionCode('ABC1234')).toBe(false); // too long
      expect(validateSessionCode('ABC-123')).toBe(false); // special char
      expect(validateSessionCode('')).toBe(false);
      expect(validateSessionCode(null)).toBe(false);
    });
  });
});
