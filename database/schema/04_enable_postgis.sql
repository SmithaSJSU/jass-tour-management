CREATE EXTENSION IF NOT EXISTS postgis;
-- SELECT PostGIS_Version();
-- SELECT PostGIS_Version() AS postgis_version;
-- SELECT PostGIS_Full_Version();

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

	
