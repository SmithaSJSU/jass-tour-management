-- Top 10 most-used venues by show count
SELECT 
    v.name AS venue_name,
    ci.name AS city,
    co.name AS country,
    COUNT(s.show_id) AS show_count
FROM venues v
JOIN cities ci ON v.city_id = ci.city_id
JOIN countries co ON ci.country_id = co.country_id
LEFT JOIN shows s ON v.venue_id = s.venue_id
GROUP BY v.venue_id, v.name, ci.name, co.name
ORDER BY show_count DESC
LIMIT 10;

-- Shows grouped by country with revenue totals
SELECT 
    co.name AS country,
    COUNT(s.show_id) AS total_shows,
    SUM(se.gross_ticket_revenue) AS total_gross_revenue,
    SUM(se.net_revenue) AS total_net_revenue,
    ROUND(AVG(se.gross_ticket_revenue), 2) AS avg_revenue_per_show
FROM countries co
JOIN cities ci ON co.country_id = ci.country_id
JOIN venues v ON ci.city_id = v.city_id
JOIN shows s ON v.venue_id = s.venue_id
LEFT JOIN settlement se ON s.show_id = se.show_id
GROUP BY co.country_id, co.name
ORDER BY total_gross_revenue DESC NULLS LAST;

-- Average distance between consecutive shows on a tour
SELECT 
    t.tour_name,
    COUNT(ss.sequence_id) AS total_legs,
    ROUND(AVG(ss.dist_from_previous_show), 2) AS avg_distance_miles,
    SUM(ss.dist_from_previous_show) AS total_distance_miles,
    ROUND(AVG(ss.drive_time), 2) AS avg_drive_time_mins
FROM tours t
JOIN show_sequence ss ON t.tour_id = ss.tour_id
WHERE ss.sequence_number > 1  -- exclude first show (distance = 0)
GROUP BY t.tour_id, t.tour_name
ORDER BY avg_distance_miles DESC;

-- Venues that haven't hosted any shows yet
SELECT 
    v.name AS venue_name,
    v.capacity,
    v.indoor_outdoor,
    ci.name AS city,
    co.name AS country
FROM venues v
JOIN cities ci ON v.city_id = ci.city_id
JOIN countries co ON ci.country_id = co.country_id
LEFT JOIN shows s ON v.venue_id = s.venue_id
WHERE s.show_id IS NULL
ORDER BY co.name, ci.name, v.name;

-- Function that when you type in a venue it returns the five nearest venues
CREATE OR REPLACE FUNCTION nearest_venues(
    input_name      VARCHAR,
    result_limit    INT DEFAULT 5,
    min_capacity    INT DEFAULT 0,
    max_capacity    INT DEFAULT 2147483647,
    venue_type      VARCHAR DEFAULT 'all'
)
RETURNS TABLE (
    nearest_venue   VARCHAR,
    city            VARCHAR,
    country         VARCHAR,
    capacity        INT,
    indoor_outdoor  VARCHAR,
    distance_miles  NUMERIC
)
LANGUAGE sql AS $$
    SELECT * FROM (
        WITH input_venue AS (
            SELECT venue_id, coordinates[0] AS lat, coordinates[1] AS lon
            FROM venues
            WHERE name ILIKE '%' || input_name || '%'
            LIMIT 1
        )
        SELECT 
            v.name,
            ci.name,
            co.name,
            v.capacity,
            v.indoor_outdoor,
            ROUND(CAST(
                3958.8 * 2 * ASIN(
                    SQRT(
                        POWER(SIN(RADIANS(v.coordinates[0] - iv.lat) / 2), 2) +
                        COS(RADIANS(iv.lat)) * COS(RADIANS(v.coordinates[0])) *
                        POWER(SIN(RADIANS(v.coordinates[1] - iv.lon) / 2), 2)
                    )
                )
            AS NUMERIC), 2) AS distance_miles
        FROM venues v
        JOIN cities ci ON v.city_id = ci.city_id
        JOIN countries co ON ci.country_id = co.country_id
        JOIN input_venue iv ON v.venue_id != iv.venue_id
        WHERE v.capacity >= min_capacity
          AND v.capacity <= max_capacity
          AND (venue_type = 'all' OR LOWER(v.indoor_outdoor) = LOWER(venue_type))
    ) sub
    ORDER BY distance_miles ASC
    LIMIT result_limit;
$$;


-- Returns a function where you type in the name of a city and then it returns the venues and info associated with it
CREATE OR REPLACE FUNCTION venues_in_city(input_city VARCHAR)
RETURNS TABLE (
    venue_name      VARCHAR,
    capacity        INT,
    indoor_outdoor  VARCHAR,
    contact_info    VARCHAR,
    country         VARCHAR,
    total_shows     BIGINT
)
LANGUAGE sql AS $$
    SELECT 
        v.name,
        v.capacity,
        v.indoor_outdoor,
        v.contact_info,
        co.name,
        COUNT(s.show_id) AS total_shows
    FROM venues v
    JOIN cities ci ON v.city_id = ci.city_id
    JOIN countries co ON ci.country_id = co.country_id
    LEFT JOIN shows s ON v.venue_id = s.venue_id
    WHERE ci.name ILIKE '%' || input_city || '%'
    GROUP BY v.venue_id, v.name, v.capacity, v.indoor_outdoor, v.contact_info, co.name
    ORDER BY v.capacity DESC;
$$;

-- SELECT * FROM venues_in_city('Berlin');
