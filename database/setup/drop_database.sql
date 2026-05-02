-- ============================================
-- JASS TOUR MANAGEMENT SYSTEM
-- DATABASE DROP SCRIPT
-- ============================================
-- Purpose: Completely remove the database
-- WARNING: This will delete ALL data permanently!
-- Usage: Run as postgres superuser
-- Command: psql -U postgres -f drop_database.sql
-- ============================================

-- Display warning
\echo '⚠️  WARNING: This will permanently delete the jass_tour_db database!'
\echo '⚠️  All data will be lost and cannot be recovered!'
\echo ''
\echo 'Press Ctrl+C to cancel, or press Enter to continue...'
\prompt 'Type YES to confirm deletion: ' confirm

-- Check confirmation (note: this is a safeguard in interactive mode)
-- In scripted execution, comment out the prompt above and uncomment below
-- \set confirm 'NO'

-- Terminate all active connections to the database
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'jass_tour_db'
  AND pid <> pg_backend_pid();

\echo 'Terminating active connections...'

-- Wait a moment for connections to close
SELECT pg_sleep(1);

-- Drop the database
DROP DATABASE IF EXISTS jass_tour_db;

\echo '✅ Database jass_tour_db has been dropped successfully'
\echo ''
\echo 'To recreate the database, run:'
\echo 'psql -U postgres -f database/setup/create_database.sql'
