const express = require('express');
const cors = require('cors');
require('dotenv').config();
const logger = require('./utils/logger');

const app = express();
const PORT = process.env.PORT || 3000;

// Rate limiting
const { apiLimiter } = require('./middleware/rateLimiter');

// Background jobs
const sessionCleanupJob = require('./jobs/sessionCleanup');

// Middleware
app.use(cors());
app.use(express.json());

// Apply rate limiting to all API routes
app.use('/api/', apiLimiter);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'DuTaksim API is running' });
});

// Manual cleanup trigger (for admin/testing)
app.post('/api/admin/cleanup', async (req, res) => {
  try {
    const results = await sessionCleanupJob.runNow();
    res.json({
      success: true,
      message: 'Cleanup completed',
      results
    });
  } catch (error) {
    logger.error('Manual cleanup failed:', error);
    res.status(500).json({
      success: false,
      error: 'Cleanup failed',
      message: error.message
    });
  }
});

// Routes
app.use('/api/users', require('./routes/users'));
app.use('/api/bills', require('./routes/bills'));
app.use('/api/transactions', require('./routes/transactions'));
app.use('/api/sessions', require('./routes/sessions'));
app.use('/api/contacts', require('./routes/contacts'));

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error('Unhandled error:', { error: err.message, stack: err.stack });
  res.status(500).json({ error: 'Something went wrong!' });
});

app.listen(PORT, () => {
  logger.info(`DuTaksim backend running on port ${PORT}`);

  // Start background cleanup jobs
  sessionCleanupJob.start();
  logger.info('Background jobs initialized');
});
