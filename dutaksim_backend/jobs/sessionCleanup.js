const cron = require('node-cron');
const pool = require('../config/database');

/**
 * Session Cleanup Job
 * Runs every hour to clean up expired sessions
 */

class SessionCleanupJob {
  constructor() {
    this.isRunning = false;
  }

  /**
   * Clean up expired sessions
   * - Delete session items
   * - Delete session participants
   * - Mark sessions as expired or delete them
   */
  async cleanupExpiredSessions() {
    if (this.isRunning) {
      console.log('Session cleanup already running, skipping...');
      return;
    }

    this.isRunning = true;
    const startTime = Date.now();

    try {
      console.log('Starting session cleanup job...');

      const client = await pool.connect();
      try {
        await client.query('BEGIN');

        // Find expired sessions
        const expiredSessionsResult = await client.query(
          `SELECT id, session_code, name, status
           FROM bill_sessions
           WHERE expires_at < NOW()
           AND status IN ('active', 'pending')`,
          []
        );

        const expiredSessions = expiredSessionsResult.rows;
        console.log(`Found ${expiredSessions.length} expired sessions to clean up`);

        if (expiredSessions.length === 0) {
          await client.query('COMMIT');
          console.log('No expired sessions to clean up');
          return { cleaned: 0 };
        }

        const sessionIds = expiredSessions.map(s => s.id);

        // Delete session items
        const deletedItemsResult = await client.query(
          'DELETE FROM session_items WHERE session_id = ANY($1)',
          [sessionIds]
        );
        console.log(`Deleted ${deletedItemsResult.rowCount} session items`);

        // Delete session participants
        const deletedParticipantsResult = await client.query(
          'DELETE FROM session_participants WHERE session_id = ANY($1)',
          [sessionIds]
        );
        console.log(`Deleted ${deletedParticipantsResult.rowCount} session participants`);

        // Mark sessions as expired (don't delete to keep history)
        const updatedSessionsResult = await client.query(
          `UPDATE bill_sessions
           SET status = 'expired'
           WHERE id = ANY($1)`,
          [sessionIds]
        );
        console.log(`Marked ${updatedSessionsResult.rowCount} sessions as expired`);

        await client.query('COMMIT');

        const duration = Date.now() - startTime;
        console.log(`Session cleanup completed in ${duration}ms`);

        return {
          cleaned: expiredSessions.length,
          itemsDeleted: deletedItemsResult.rowCount,
          participantsDeleted: deletedParticipantsResult.rowCount,
          duration
        };
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      } finally {
        client.release();
      }
    } catch (error) {
      console.error('Error in session cleanup job:', error);
      throw error;
    } finally {
      this.isRunning = false;
    }
  }

  /**
   * Clean up very old sessions (older than 30 days)
   * Completely delete them from database to save space
   */
  async cleanupOldSessions() {
    try {
      console.log('Starting old session cleanup (30+ days)...');

      const result = await pool.query(
        `DELETE FROM bill_sessions
         WHERE created_at < NOW() - INTERVAL '30 days'
         AND status IN ('expired', 'closed', 'cancelled')
         AND bill_id IS NULL`, // Don't delete sessions that created bills
        []
      );

      console.log(`Deleted ${result.rowCount} old sessions (30+ days)`);
      return { deleted: result.rowCount };
    } catch (error) {
      console.error('Error cleaning up old sessions:', error);
      throw error;
    }
  }

  /**
   * Clean up expired invitations (older than 7 days)
   */
  async cleanupExpiredInvitations() {
    try {
      console.log('Starting expired invitation cleanup...');

      const result = await pool.query(
        `DELETE FROM contact_invitations
         WHERE expires_at < NOW() - INTERVAL '7 days'
         AND status = 'pending'`,
        []
      );

      console.log(`Deleted ${result.rowCount} expired invitations`);
      return { deleted: result.rowCount };
    } catch (error) {
      console.error('Error cleaning up expired invitations:', error);
      throw error;
    }
  }

  /**
   * Start the scheduled cleanup jobs
   */
  start() {
    // Run expired session cleanup every hour at minute 0
    cron.schedule('0 * * * *', async () => {
      console.log('Running scheduled session cleanup...');
      try {
        await this.cleanupExpiredSessions();
      } catch (error) {
        console.error('Scheduled session cleanup failed:', error);
      }
    });

    // Run old session cleanup once a day at 3 AM
    cron.schedule('0 3 * * *', async () => {
      console.log('Running scheduled old session cleanup...');
      try {
        await this.cleanupOldSessions();
        await this.cleanupExpiredInvitations();
      } catch (error) {
        console.error('Scheduled old session cleanup failed:', error);
      }
    });

    console.log('Session cleanup jobs scheduled:');
    console.log('  - Expired sessions: every hour at minute 0');
    console.log('  - Old sessions (30+ days): daily at 3:00 AM');
    console.log('  - Expired invitations: daily at 3:00 AM');
  }

  /**
   * Run cleanup immediately (for testing or manual trigger)
   */
  async runNow() {
    console.log('Running session cleanup manually...');
    const results = await Promise.all([
      this.cleanupExpiredSessions(),
      this.cleanupOldSessions(),
      this.cleanupExpiredInvitations()
    ]);

    return {
      expiredSessions: results[0],
      oldSessions: results[1],
      expiredInvitations: results[2]
    };
  }
}

// Export singleton instance
module.exports = new SessionCleanupJob();
