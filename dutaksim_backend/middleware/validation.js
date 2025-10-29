/**
 * Validation middleware for request data
 */

// Phone number validation (international format)
const validatePhone = (phone) => {
  if (!phone || typeof phone !== 'string') {
    return false;
  }
  // Allow formats: +992123456789, 992123456789, or simple digits
  const phoneRegex = /^\+?[0-9]{9,15}$/;
  return phoneRegex.test(phone.replace(/[\s-]/g, ''));
};

// Name validation
const validateName = (name) => {
  if (!name || typeof name !== 'string') {
    return false;
  }
  return name.trim().length >= 2 && name.trim().length <= 100;
};

// Price validation
const validatePrice = (price) => {
  const numPrice = parseFloat(price);
  return !isNaN(numPrice) && numPrice > 0 && numPrice < 1000000;
};

// UUID validation
const validateUUID = (uuid) => {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  return uuidRegex.test(uuid);
};

// GPS coordinates validation
const validateCoordinates = (lat, lon) => {
  const latitude = parseFloat(lat);
  const longitude = parseFloat(lon);
  return !isNaN(latitude) && !isNaN(longitude) &&
         latitude >= -90 && latitude <= 90 &&
         longitude >= -180 && longitude <= 180;
};

// Session code validation (6 alphanumeric characters)
const validateSessionCode = (code) => {
  if (!code || typeof code !== 'string') {
    return false;
  }
  return /^[A-Z0-9]{6}$/.test(code);
};

// Middleware: Validate user registration
const validateUserRegistration = (req, res, next) => {
  const { name, phone } = req.body;

  if (!validateName(name)) {
    return res.status(400).json({
      error: 'Invalid name. Name must be 2-100 characters long'
    });
  }

  if (!validatePhone(phone)) {
    return res.status(400).json({
      error: 'Invalid phone number. Use international format (e.g., +992123456789)'
    });
  }

  // Sanitize phone number
  req.body.phone = phone.replace(/[\s-]/g, '');
  req.body.name = name.trim();

  next();
};

// Middleware: Validate bill creation
const validateBillCreation = (req, res, next) => {
  const { title, items, participants, paidBy, totalAmount, tips } = req.body;

  if (!title || title.trim().length < 1 || title.trim().length > 200) {
    return res.status(400).json({
      error: 'Invalid title. Title must be 1-200 characters long'
    });
  }

  if (!Array.isArray(items) || items.length === 0) {
    return res.status(400).json({
      error: 'At least one item is required'
    });
  }

  // Validate each item
  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    if (!item.name || item.name.trim().length < 1 || item.name.trim().length > 200) {
      return res.status(400).json({
        error: `Invalid item name at index ${i}`
      });
    }
    if (!validatePrice(item.price)) {
      return res.status(400).json({
        error: `Invalid price for item "${item.name}". Price must be positive and less than 1,000,000`
      });
    }
    if (item.quantity && (item.quantity < 1 || item.quantity > 1000)) {
      return res.status(400).json({
        error: `Invalid quantity for item "${item.name}". Quantity must be 1-1000`
      });
    }
  }

  if (!Array.isArray(participants) || participants.length === 0) {
    return res.status(400).json({
      error: 'At least one participant is required'
    });
  }

  // Validate participants are UUIDs
  for (const participantId of participants) {
    if (!validateUUID(participantId)) {
      return res.status(400).json({
        error: `Invalid participant ID: ${participantId}`
      });
    }
  }

  if (!validateUUID(paidBy)) {
    return res.status(400).json({
      error: 'Invalid paidBy user ID'
    });
  }

  if (!validatePrice(totalAmount)) {
    return res.status(400).json({
      error: 'Invalid total amount. Must be positive and less than 1,000,000'
    });
  }

  if (tips !== undefined && tips !== null && !validatePrice(tips)) {
    return res.status(400).json({
      error: 'Invalid tips amount. Must be positive and less than 1,000,000'
    });
  }

  next();
};

// Middleware: Validate session creation
const validateSessionCreation = (req, res, next) => {
  const { name, location } = req.body;

  if (!name || name.trim().length < 1 || name.trim().length > 200) {
    return res.status(400).json({
      error: 'Invalid session name. Name must be 1-200 characters long'
    });
  }

  if (location) {
    if (!location.latitude || !location.longitude) {
      return res.status(400).json({
        error: 'Location must include latitude and longitude'
      });
    }

    if (!validateCoordinates(location.latitude, location.longitude)) {
      return res.status(400).json({
        error: 'Invalid GPS coordinates'
      });
    }
  }

  req.body.name = name.trim();
  next();
};

// Middleware: Validate session item
const validateSessionItem = (req, res, next) => {
  const { name, price, quantity } = req.body;

  if (!name || name.trim().length < 1 || name.trim().length > 200) {
    return res.status(400).json({
      error: 'Invalid item name. Name must be 1-200 characters long'
    });
  }

  if (!validatePrice(price)) {
    return res.status(400).json({
      error: 'Invalid price. Price must be positive and less than 1,000,000'
    });
  }

  if (quantity && (quantity < 1 || quantity > 1000)) {
    return res.status(400).json({
      error: 'Invalid quantity. Quantity must be 1-1000'
    });
  }

  req.body.name = name.trim();
  next();
};

// Middleware: Validate UUID parameter
const validateUUIDParam = (paramName) => {
  return (req, res, next) => {
    const value = req.params[paramName];
    if (!validateUUID(value)) {
      return res.status(400).json({
        error: `Invalid ${paramName}. Must be a valid UUID`
      });
    }
    next();
  };
};

module.exports = {
  validatePhone,
  validateName,
  validatePrice,
  validateUUID,
  validateCoordinates,
  validateSessionCode,
  validateUserRegistration,
  validateBillCreation,
  validateSessionCreation,
  validateSessionItem,
  validateUUIDParam
};
