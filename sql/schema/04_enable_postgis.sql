-- ============================================
-- JASS Tour Management System
-- File: 04_enable_postgis.sql
-- Module: Venues & Geography (Jack)
-- Purpose: Enable PostGIS for geographic calculations
-- ============================================

-- ============================================
-- WHAT IS POSTGIS?
-- ============================================
-- PostGIS is a PostgreSQL extension that adds support for geographic objects
-- It allows us to:
--   - Store latitude/longitude coordinates
--   - Calculate distances between locations
--   - Find nearby venues
--   - Optimize tour routing
--   - Perform spatial queries
--
-- This file MUST be run AFTER creating all tables
-- Run order: 01_create_tables.sql → 02_add_constraints.sql → 03_create_indexes.sql → 04_enable_postgis.sql


-- ============================================
-- ENABLE POSTGIS EXTENSION
-- ============================================

-- Turn on PostGIS functionality
-- If PostGIS is already enabled, this command will be ignored (IF NOT EXISTS)
CREATE EXTENSION IF NOT EXISTS postgis;

-- Optional: Enable PostGIS topology (advanced features - not required for basic routing)
-- CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Optional: Enable PostGIS raster (satellite/image data - not needed for our project)
-- CREATE EXTENSION IF NOT EXISTS postgis_raster;


-- ============================================
-- VERIFY POSTGIS IS INSTALLED AND WORKING
-- ============================================

-- Check PostGIS version
-- Should return something like: "3.3 USE_GEOS=1 USE_PROJ=1..."
SELECT PostGIS_Version() AS postgis_version;

-- Check full PostGIS installation details
SELECT PostGIS_Full_Version();


-- ============================================
-- TEST GEOGRAPHIC FUNCTIONS
-- ============================================

-- Test 1: Calculate distance between two well-known cities
-- (New York City to Los Angeles)
-- Expected result: approximately 2,451 miles
SELECT 
    ST_Distance(
        ST_SetSRID(ST_MakePoint(-73.9934, 40.7505), 4326)::geography,  -- NYC: Madison Square Garden
        ST_SetSRID(ST_MakePoint(-118.2673, 34.0430), 4326)::geography  -- LA: Staples Center
    ) / 1609.34 AS distance_miles;
-- If this returns ~2,451 miles, PostGIS is working correctly! ✅

-- Test 2: Create a point and display it as text
-- Should return: "POINT(-122.3321 47.6062)"
SELECT ST_AsText(
    ST_SetSRID(ST_MakePoint(-122.3321, 47.6062), 4326)
) AS seattle_point;

-- Test 3: Calculate distance in kilometers
-- Same cities as Test 1, but in kilometers
SELECT 
    ST_Distance(
        ST_SetSRID(ST_MakePoint(-73.9934, 40.7505), 4326)::geography,
        ST_SetSRID(ST_MakePoint(-118.2673, 34.0430), 4326)::geography
    ) / 1000 AS distance_kilometers;
-- Expected result: ~3,944 km


-- ============================================
-- HELPER FUNCTIONS FOR TOUR ROUTING
-- ============================================

-- --------------------------------------------
-- Function 1: Calculate distance between two venues
-- --------------------------------------------
-- Usage: SELECT calculate_venue_distance(1, 2);
-- Returns: Distance in miles between venue 1 and venue 2

CREATE OR REPLACE FUNCTION calculate_venue_distance(
    venue_id_1 INTEGER,
    venue_id_2 INTEGER
)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    distance_miles DECIMAL(10,2);
BEGIN
    SELECT 
        ST_Distance(
            ST_SetSRID(ST_MakePoint(v1.longitude, v1.latitude), 4326)::geography,
            ST_SetSRID(ST_MakePoint(v2.longitude, v2.latitude), 4326)::geography
        ) / 1609.34
    INTO distance_miles
    FROM venues v1, venues v2
    WHERE v1.venue_id = venue_id_1 
      AND v2.venue_id = venue_id_2;
    
    RETURN distance_miles;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_venue_distance(INTEGER, INTEGER) IS 
'Calculate distance in miles between two venues using their venue_ids';


-- --------------------------------------------
-- Function 2: Find venues within X miles of a point
-- --------------------------------------------
-- Usage: SELECT * FROM find_nearby_venues(47.6062, -122.3321, 100);
-- Returns: All venues within 100 miles of Seattle

CREATE OR REPLACE FUNCTION find_nearby_venues(
    lat DECIMAL(10,7),
    lon DECIMAL(10,7),
    radius_miles INTEGER
)
RETURNS TABLE(
    venue_id INTEGER,
    venue_name VARCHAR(200),
    city_name VARCHAR(100),
    distance_miles DECIMAL(10,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        v.venue_id,
        v.name AS venue_name,
        c.name AS city_name,
        (ST_Distance(
            ST_SetSRID(ST_MakePoint(v.longitude, v.latitude), 4326)::geography,
            ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography
        ) / 1609.34)::DECIMAL(10,2) AS distance_miles
    FROM venues v
    JOIN cities c ON v.city_id = c.city_id
    WHERE ST_DWithin(
        ST_SetSRID(ST_MakePoint(v.longitude, v.latitude), 4326)::geography,
        ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography,
        radius_miles * 1609.34  -- Convert miles to meters
    )
    ORDER BY distance_miles;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION find_nearby_venues(DECIMAL, DECIMAL, INTEGER) IS 
'Find all venues within specified miles of a latitude/longitude point';


-- --------------------------------------------
-- Function 3: Calculate total tour mileage
-- --------------------------------------------
-- Usage: SELECT calculate_tour_mileage(1);
-- Returns: Total miles traveled for tour_id 1

CREATE OR REPLACE FUNCTION calculate_tour_mileage(
    tour_id_param INTEGER
)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    total_miles DECIMAL(10,2);
BEGIN
    SELECT 
        COALESCE(SUM(dist_from_prev_show), 0)
    INTO total_miles
    FROM show_sequence
    WHERE tour_id = tour_id_param;
    
    RETURN total_miles;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_tour_mileage(INTEGER) IS 
'Calculate total miles traveled for a tour based on show_sequence distances';


-- --------------------------------------------
-- Function 4: Find next nearest unvisited venue
-- --------------------------------------------
-- Usage: SELECT * FROM find_next_nearest_venue(1, ARRAY[5,7,9]);
-- Returns: Nearest venue to tour 1's current location, excluding venues 5, 7, 9

CREATE OR REPLACE FUNCTION find_next_nearest_venue(
    current_venue_id INTEGER,
    excluded_venue_ids INTEGER[]
)
RETURNS TABLE(
    venue_id INTEGER,
    venue_name VARCHAR(200),
    distance_miles DECIMAL(10,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        v.venue_id,
        v.name AS venue_name,
        (ST_Distance(
            ST_SetSRID(ST_MakePoint(v_current.longitude, v_current.latitude), 4326)::geography,
            ST_SetSRID(ST_MakePoint(v.longitude, v.latitude), 4326)::geography
        ) / 1609.34)::DECIMAL(10,2) AS distance_miles
    FROM venues v
    CROSS JOIN venues v_current
    WHERE v_current.venue_id = current_venue_id
      AND v.venue_id != current_venue_id
      AND NOT (v.venue_id = ANY(excluded_venue_ids))
    ORDER BY distance_miles
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION find_next_nearest_venue(INTEGER, INTEGER[]) IS 
'Find the nearest venue to the current location, excluding already-visited venues';


-- ============================================
-- CREATE SPATIAL INDEXES (Optional but Recommended)
-- ============================================
-- These indexes speed up geographic queries significantly (10-100x faster)
-- They only work if you add a geography column to your tables

-- Note: This section is commented out because we're using separate lat/long columns
-- Uncomment and modify if you decide to add a geography column to venues table

/*
-- Add geography column to venues (if not already present)
ALTER TABLE venues 
ADD COLUMN IF NOT EXISTS location GEOGRAPHY(POINT, 4326);

-- Populate the geography column from lat/long
UPDATE venues 
SET location = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
WHERE longitude IS NOT NULL AND latitude IS NOT NULL;

-- Create spatial index (speeds up proximity searches)
CREATE INDEX idx_venues_location_geography 
ON venues USING GIST(location);

-- Add trigger to auto-update geography column when lat/long changes
CREATE OR REPLACE FUNCTION update_venue_location()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.longitude IS NOT NULL AND NEW.latitude IS NOT NULL THEN
        NEW.location = ST_SetSRID(
            ST_MakePoint(NEW.longitude, NEW.latitude), 
            4326
        )::geography;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_venue_location
BEFORE INSERT OR UPDATE OF latitude, longitude ON venues
FOR EACH ROW
EXECUTE FUNCTION update_venue_location();
*/


-- ============================================
-- USAGE EXAMPLES AND DOCUMENTATION
-- ============================================

-- Example 1: Calculate distance between two specific venues
-- SELECT calculate_venue_distance(1, 2);

-- Example 2: Find all venues within 100 miles of Seattle
-- SELECT * FROM find_nearby_venues(47.6062, -122.3321, 100);

-- Example 3: Get total mileage for a tour
-- SELECT calculate_tour_mileage(1);

-- Example 4: Find nearest venue to Madison Square Garden, excluding venue IDs 5 and 10
-- SELECT * FROM find_next_nearest_venue(1, ARRAY[5, 10]);

-- Example 5: Calculate distance between cities
-- SELECT 
--     c1.name AS from_city,
--     c2.name AS to_city,
--     ST_Distance(
--         ST_SetSRID(ST_MakePoint(c1.longitude, c1.latitude), 4326)::geography,
--         ST_SetSRID(ST_MakePoint(c2.longitude, c2.latitude), 4326)::geography
--     ) / 1609.34 AS miles
-- FROM cities c1, cities c2
-- WHERE c1.city_id = 1 AND c2.city_id = 2;


-- ============================================
-- IMPORTANT NOTES
-- ============================================

-- COORDINATE SYSTEM (SRID 4326):
-- - 4326 = WGS 84 coordinate system (GPS standard)
-- - Used by Google Maps, smartphones, GPS devices
-- - Always use 4326 for latitude/longitude coordinates

-- COORDINATE ORDER:
-- - ST_MakePoint(longitude, latitude)  ← Longitude FIRST!
-- - This is X, Y order (not lat, long)
-- - Common mistake: putting latitude first

-- DISTANCE UNITS:
-- - ST_Distance() returns meters by default
-- - Divide by 1609.34 to convert to miles
-- - Divide by 1000 to convert to kilometers

-- GEOGRAPHY vs GEOMETRY:
-- - ::geography = accurate distances (use for lat/long)
-- - ::geometry = faster but less accurate (use for projected coordinates)
-- - Always cast to ::geography for real-world distances!

-- PERFORMANCE:
-- - PostGIS functions are very fast (microseconds)
-- - Spatial indexes make proximity searches 10-100x faster
-- - Use ST_DWithin() instead of ST_Distance() for "within radius" queries


-- ============================================
-- TROUBLESHOOTING
-- ============================================

-- Problem: "extension postgis does not exist"
-- Solution: PostGIS must be installed on the server first
--           Contact your DBA or run: sudo apt-get install postgresql-postgis

-- Problem: Distance calculations return wrong values
-- Solution: Make sure you're casting to ::geography and using SRID 4326

-- Problem: Queries are slow
-- Solution: Add spatial indexes (see commented section above)

-- Problem: "function st_distance does not exist"
-- Solution: Run this file to enable PostGIS first


