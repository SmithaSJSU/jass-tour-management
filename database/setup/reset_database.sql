-- ============================================
-- JASS TOUR MANAGEMENT SYSTEM
-- DATABASE RESET SCRIPT
-- ============================================
-- Purpose: Drop and recreate database with fresh data
-- WARNING: This will delete ALL existing data!
-- Usage: Run as postgres superuser
-- Command: psql -U postgres -f reset_database.sql
-- ============================================

\echo '╔════════════════════════════════════════╗'
\echo '║   JASS DATABASE RESET UTILITY          ║'
\echo '║   This will:                           ║'
\echo '║   1. Drop existing database            ║'
\echo '║   2. Create fresh database             ║'
\echo '║   3. Enable PostGIS                    ║'
\echo '║   4. Create all tables                 ║'
\echo '║   5. Load sample data (optional)       ║'
\echo '╚════════════════════════════════════════╝'
\echo ''

-- ============================================
-- STEP 1: TERMINATE CONNECTIONS & DROP DATABASE
-- ============================================

\echo '▶ Step 1: Terminating connections and dropping database...'

-- Terminate existing connections
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'jass_tour_db'
  AND pid <> pg_backend_pid();

-- Wait for connections to close
SELECT pg_sleep(1);

-- Drop database
DROP DATABASE IF EXISTS jass_tour_db;

\echo '  ✓ Database dropped'

-- ============================================
-- STEP 2: CREATE DATABASE
-- ============================================

\echo '▶ Step 2: Creating new database...'

CREATE DATABASE jass_tour_db
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

COMMENT ON DATABASE jass_tour_db IS 'JASS Tour Management System - Fresh Reset';

\echo '  ✓ Database created'

-- ============================================
-- STEP 3: ENABLE POSTGIS
-- ============================================

\echo '▶ Step 3: Enabling PostGIS extension...'

\c jass_tour_db

CREATE EXTENSION IF NOT EXISTS postgis;

\echo '  ✓ PostGIS enabled'

-- ============================================
-- STEP 4: CREATE SCHEMA (Tables)
-- ============================================

\echo '▶ Step 4: Creating database schema...'
\echo '  Note: You need to run the schema scripts separately'
\echo ''
\echo 'Run these commands in order:'
\echo '  1. psql -U postgres -d jass_tour_db -f database/schema/01_create_tables.sql'
\echo '  2. psql -U postgres -d jass_tour_db -f database/schema/02_constraints.sql'
\echo '  3. psql -U postgres -d jass_tour_db -f database/schema/03_indexes.sql'
\echo ''

-- Alternative: Uncomment below to run schema scripts automatically
-- (Requires scripts to be in expected locations)

-- \echo '  → Creating tables...'
-- \i database/schema/01_create_tables.sql
-- 
-- \echo '  → Adding constraints...'
-- \i database/schema/02_constraints.sql
-- 
-- \echo '  → Creating indexes...'
-- \i database/schema/03_indexes.sql

-- ============================================
-- STEP 5: LOAD DATA (OPTIONAL)
-- ============================================

\echo '▶ Step 5: Data loading options'
\echo ''
\echo 'To load data, run ONE of the following:'
\echo ''
\echo '  Option A - Load complete dataset (48,000+ records):'
\echo '    psql -U postgres -d jass_tour_db -f database/data/MASTER_DATA_LOAD.sql'
\echo ''
\echo '  Option B - Load sample data (small subset for testing):'
\echo '    psql -U postgres -d jass_tour_db -f database/data/sample_data.sql'
\echo ''
\echo '  Option C - Generate fresh data with Python:'
\echo '    cd scripts && python generate_data.py'
\echo ''

-- ============================================
-- VERIFICATION
-- ============================================

\echo '▶ Verifying database setup...'

-- Check PostGIS version
SELECT 'PostGIS Version: ' || PostGIS_version() AS verification;

-- List extensions
SELECT extname AS "Installed Extensions" FROM pg_extension WHERE extname != 'plpgsql';

\echo ''
\echo '╔════════════════════════════════════════╗'
\echo '║          RESET COMPLETE!               ║'
\echo '║                                        ║'
\echo '║  Database: jass_tour_db                ║'
\echo '║  Status: Ready for schema & data       ║'
\echo '╚════════════════════════════════════════╝'
\echo ''
