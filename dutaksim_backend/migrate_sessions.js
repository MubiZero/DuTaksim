const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

async function runMigration() {
  console.log('🚀 Starting database migration for collaborative features...\n');

  // Connect to the database using .env credentials
  const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
  });

  try {
    console.log(`📡 Connecting to database "${process.env.DB_NAME}" at ${process.env.DB_HOST}...`);

    // Test connection
    await pool.query('SELECT 1');
    console.log('✅ Connected successfully!\n');

    // Read migration SQL file
    const migrationPath = path.join(__dirname, 'migrations', 'add_sessions.sql');

    if (!fs.existsSync(migrationPath)) {
      console.error('❌ Migration file not found:', migrationPath);
      process.exit(1);
    }

    console.log('📋 Reading migration file...');
    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');

    // Check if tables already exist
    console.log('🔍 Checking if tables already exist...');
    const checkTables = await pool.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
      AND table_name IN ('bill_sessions', 'session_participants', 'session_items', 'contact_invitations')
    `);

    if (checkTables.rows.length > 0) {
      console.log('⚠️  Some tables already exist:');
      checkTables.rows.forEach(row => {
        console.log(`   - ${row.table_name}`);
      });

      const readline = require('readline').createInterface({
        input: process.stdin,
        output: process.stdout
      });

      const answer = await new Promise(resolve => {
        readline.question('\n❓ Do you want to continue? This will use CREATE TABLE IF NOT EXISTS (safe). (y/n): ', resolve);
      });
      readline.close();

      if (answer.toLowerCase() !== 'y' && answer.toLowerCase() !== 'yes') {
        console.log('❌ Migration cancelled by user.');
        process.exit(0);
      }
    }

    console.log('\n📝 Running migration...');

    // Execute migration
    await pool.query(migrationSQL);

    console.log('✅ Migration completed successfully!\n');

    // Verify tables were created
    console.log('🔍 Verifying new tables...');
    const verifyTables = await pool.query(`
      SELECT table_name,
             (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
      FROM information_schema.tables t
      WHERE table_schema = 'public'
      AND table_name IN ('bill_sessions', 'session_participants', 'session_items', 'contact_invitations')
      ORDER BY table_name
    `);

    console.log('\n📊 Created/verified tables:');
    verifyTables.rows.forEach(row => {
      console.log(`   ✓ ${row.table_name} (${row.column_count} columns)`);
    });

    // Verify indexes
    console.log('\n🔍 Verifying indexes...');
    const verifyIndexes = await pool.query(`
      SELECT indexname, tablename
      FROM pg_indexes
      WHERE schemaname = 'public'
      AND tablename IN ('bill_sessions', 'session_participants', 'session_items', 'contact_invitations')
      ORDER BY tablename, indexname
    `);

    console.log('\n📊 Created/verified indexes:');
    verifyIndexes.rows.forEach(row => {
      console.log(`   ✓ ${row.indexname} on ${row.tablename}`);
    });

    await pool.end();

    console.log('\n🎉 Migration completed successfully!\n');
    console.log('✅ Database is ready for collaborative features.');
    console.log('\n📌 Next steps:');
    console.log('   1. Restart your backend server: npm start');
    console.log('   2. Rebuild your Flutter app: flutter run');
    console.log('   3. Test the new features!\n');

  } catch (error) {
    console.error('\n❌ Error running migration:', error.message);
    console.error('\nDetails:', error);

    if (error.code) {
      console.error('Error Code:', error.code);
    }

    process.exit(1);
  }
}

// Run migration with error handling
runMigration().catch(error => {
  console.error('❌ Unexpected error:', error);
  process.exit(1);
});
