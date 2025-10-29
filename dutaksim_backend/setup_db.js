const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

async function setupDatabase() {
  console.log('🚀 Starting database setup...\n');

  // Connect to postgres database first
  const adminPool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: 'postgres', // Connect to default postgres database
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
  });

  try {
    // Check if database exists
    const dbCheck = await adminPool.query(
      `SELECT 1 FROM pg_database WHERE datname = $1`,
      [process.env.DB_NAME]
    );

    if (dbCheck.rows.length === 0) {
      // Create database if it doesn't exist
      console.log(`📦 Creating database "${process.env.DB_NAME}"...`);
      await adminPool.query(`CREATE DATABASE ${process.env.DB_NAME}`);
      console.log('✅ Database created successfully!\n');
    } else {
      console.log(`✅ Database "${process.env.DB_NAME}" already exists.\n`);
    }

    await adminPool.end();

    // Now connect to the actual database and create tables
    const pool = new Pool({
      host: process.env.DB_HOST,
      port: process.env.DB_PORT,
      database: process.env.DB_NAME,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
    });

    console.log('📋 Creating tables...');

    // Read and execute SQL file
    const sqlFilePath = path.join(__dirname, 'database.sql');
    const sql = fs.readFileSync(sqlFilePath, 'utf8');

    await pool.query(sql);

    console.log('✅ Tables created successfully!\n');

    // Insert test data
    console.log('📝 Inserting test data...');

    const testUser1 = await pool.query(
      `INSERT INTO users (name, phone) VALUES ($1, $2)
       ON CONFLICT (phone) DO UPDATE SET name = EXCLUDED.name
       RETURNING *`,
      ['Test User 1', '929059030']
    );

    const testUser2 = await pool.query(
      `INSERT INTO users (name, phone) VALUES ($1, $2)
       ON CONFLICT (phone) DO UPDATE SET name = EXCLUDED.name
       RETURNING *`,
      ['Test User 2', '929059031']
    );

    console.log('✅ Test users created:');
    console.log(`   - ${testUser1.rows[0].name} (${testUser1.rows[0].phone})`);
    console.log(`   - ${testUser2.rows[0].name} (${testUser2.rows[0].phone})\n`);

    await pool.end();

    console.log('🎉 Database setup completed successfully!\n');
    console.log('You can now start the server with: npm start');

  } catch (error) {
    console.error('❌ Error setting up database:', error.message);
    process.exit(1);
  }
}

setupDatabase();
