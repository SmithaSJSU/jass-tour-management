-- ============================================
-- JASS TOUR MANAGEMENT SYSTEM
-- DATABASE CREATION SCRIPT
-- ============================================
-- Purpose: Initial database setup with PostGIS extension
-- Usage: Run as postgres superuser
-- Command: psql -U postgres -f create_database.sql
-- ============================================

-- Terminate existing connections to the database (if it exists)
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'jass_tour_db'
  AND pid <> pg_backend_pid();

-- Drop database if it exists (clean slate)
DROP DATABASE IF EXISTS jass_tour_db;

-- Create the database
CREATE DATABASE jass_tour_db
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

-- Add comment
COMMENT ON DATABASE jass_tour_db IS 'JASS Tour Management System - Database Systems Project';

-- Connect to the new database
\c jass_tour_db

-- Enable PostGIS extension for geographic data
CREATE EXTENSION IF NOT EXISTS postgis;

-- Verify PostGIS installation
SELECT PostGIS_version();

-- Create schema (optional - using public by default)
-- CREATE SCHEMA IF NOT EXISTS jass;

-- Set search path (if using custom schema)
-- SET search_path TO jass, public;

-- Display success message
\echo '✅ Database jass_tour_db created successfully!'
\echo '✅ PostGIS extension enabled'
\echo ''
\echo 'Next steps:'
\echo '1. Run schema creation: psql -U postgres -d jass_tour_db -f database/schema/01_create_tables.sql'
\echo '2. Add constraints: psql -U postgres -d jass_tour_db -f database/schema/02_constraints.sql'
\echo '3. Create indexes: psql -U postgres -d jass_tour_db -f database/schema/03_indexes.sql'
\echo '4. Load data: psql -U postgres -d jass_tour_db -f database/data/MASTER_DATA_LOAD.sql'
