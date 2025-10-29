# Logger Migration Guide

## What Has Been Done

1. ✅ Installed winston logger package
2. ✅ Created logger utility at `utils/logger.js`
3. ✅ Created `logs/` directory and added to `.gitignore`
4. ✅ Updated `server.js` to use logger

## What Needs to Be Done

Replace `console.log`, `console.error`, and `console.warn` with logger calls in the following files:

### Files to Update

1. **routes/users.js**
   - Add: `const logger = require('../utils/logger');`
   - Replace `console.error` with `logger.error`

2. **routes/bills.js**
   - Add: `const logger = require('../utils/logger');`
   - Replace `console.error` with `logger.error`

3. **routes/sessions.js**
   - Add: `const logger = require('../utils/logger');`
   - Replace `console.log` with `logger.info`
   - Replace `console.error` with `logger.error`

4. **routes/transactions.js**
   - Add: `const logger = require('../utils/logger');`
   - Replace `console.error` with `logger.error`

5. **routes/contacts.js**
   - Add: `const logger = require('../utils/logger');`
   - Replace `console.log` with `logger.info`
   - Replace `console.error` with `logger.error`

6. **services/emailService.js**
   - Add: `const logger = require('../utils/logger');`
   - Replace `console.log` with `logger.info`
   - Replace `console.error` with `logger.error`
   - Replace `console.warn` with `logger.warn`

7. **jobs/sessionCleanup.js**
   - Add: `const logger = require('../utils/logger');`
   - Replace `console.log` with `logger.info`
   - Replace `console.error` with `logger.error`

### Quick Find & Replace

You can use your editor's find & replace functionality:

1. **Add logger import** at the top of each file after other requires:
   ```javascript
   const logger = require('../utils/logger'); // for files in subdirectories
   const logger = require('./utils/logger');  // for files in root
   ```

2. **Replace console.log**:
   - Find: `console.log(`
   - Replace: `logger.info(`

3. **Replace console.error**:
   - Find: `console.error(`
   - Replace: `logger.error(`

4. **Replace console.warn**:
   - Find: `console.warn(`
   - Replace: `logger.warn(`

### Verification

After making changes:

1. Start the server: `npm start`
2. Check that logs are being written to `logs/` directory
3. Verify no `console.log` statements remain (except in test files):
   ```bash
   grep -r "console\.log" --exclude-dir=node_modules --exclude-dir=logs --exclude="*.test.js" .
   ```

## Logger API

The logger provides the following levels:

- `logger.error(message, metadata)` - Error messages
- `logger.warn(message, metadata)` - Warning messages
- `logger.info(message, metadata)` - Informational messages
- `logger.http(message, metadata)` - HTTP request logs
- `logger.debug(message, metadata)` - Debug messages

## Helper Methods

- `logger.logRequest(req, message)` - Log HTTP request with context
- `logger.logError(error, context)` - Log error with stack trace
- `logger.logDatabase(operation, details)` - Log database operations

## Example Usage

Before:
```javascript
console.log('User registered:', userId);
console.error('Error registering user:', error);
```

After:
```javascript
logger.info('User registered', { userId });
logger.error('Error registering user', { error: error.message, stack: error.stack });
```

## Log Files

Logs are written to:
- `logs/combined.log` - All logs
- `logs/error.log` - Error logs only
- `logs/exceptions.log` - Uncaught exceptions
- `logs/rejections.log` - Unhandled promise rejections

All log files are automatically rotated (max 5 files, 5MB each).
