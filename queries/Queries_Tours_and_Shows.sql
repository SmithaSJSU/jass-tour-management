-- ============================================
-- Shows & Tours — SQL Queries
-- All queries used in the Streamlit UI
-- ============================================


-- ============================================
-- PAGE 1: TOURS BY ARTIST
-- ============================================

-- 1. Get all artists
SELECT artist_id, name
FROM artists
ORDER BY name;

-- 2. Get tours by artist with leg and show counts
SELECT
    t.tour_id,
    t.tour_name,
    t.start_date,
    t.end_date,
    COUNT(DISTINCT tl.leg_id)  AS total_legs,
    COUNT(DISTINCT s.show_id)  AS total_shows
FROM tours t
LEFT JOIN tour_legs tl ON t.tour_id = tl.tour_id
LEFT JOIN shows s      ON tl.leg_id = s.leg_id
WHERE t.artist_id = :artist_id
GROUP BY t.tour_id, t.tour_name, t.start_date, t.end_date
ORDER BY t.start_date DESC;

-- 3. Get shows by artist filtered by status
SELECT
    s.show_id,
    t.tour_name,
    tl.leg_name,
    tl.region,
    s.show_date,
    s.start_time,
    s.status
FROM shows s
JOIN tour_legs tl ON s.leg_id    = tl.leg_id
JOIN tours t      ON tl.tour_id  = t.tour_id
JOIN artists a    ON t.artist_id = a.artist_id
WHERE a.artist_id = :artist_id
  AND s.status IN ('scheduled', 'completed', 'cancelled', 'rescheduled')  -- dynamic
ORDER BY s.show_date;


-- ============================================
-- PAGE 2: SHOWS BY TOUR / LEG
-- ============================================

-- 4. Get all tours
SELECT tour_id, tour_name
FROM tours
ORDER BY tour_name;

-- 5. Get legs by tour
SELECT
    leg_id,
    leg_name || ' (' || region || ')' AS leg_label
FROM tour_legs
WHERE tour_id = :tour_id
ORDER BY start_date;

-- 6. Get shows by tour (all legs)
SELECT
    s.show_id,
    tl.region,
    tl.leg_name,
    s.show_date,
    s.start_time,
    s.status
FROM shows s
JOIN tour_legs tl ON s.leg_id = tl.leg_id
WHERE tl.tour_id = :tour_id
ORDER BY s.show_date;

-- 7. Get shows by tour filtered by specific leg
SELECT
    s.show_id,
    tl.region,
    tl.leg_name,
    s.show_date,
    s.start_time,
    s.status
FROM shows s
JOIN tour_legs tl ON s.leg_id = tl.leg_id
WHERE tl.tour_id = :tour_id
  AND tl.leg_id  = :leg_id
ORDER BY s.show_date;


-- ============================================
-- PAGE 3: SEARCH SHOWS
-- ============================================

-- 8. Search shows by date range (no status filter)
SELECT
    s.show_date,
    s.start_time,
    a.name      AS artist,
    t.tour_name,
    tl.region,
    tl.leg_name,
    s.status
FROM shows s
JOIN tour_legs tl ON s.leg_id   = tl.leg_id
JOIN tours t      ON tl.tour_id = t.tour_id
JOIN artists a    ON t.artist_id = a.artist_id
WHERE s.show_date BETWEEN :date_from AND :date_to
ORDER BY s.show_date, s.start_time;

-- 9. Search shows by date range and status filter
SELECT
    s.show_date,
    s.start_time,
    a.name      AS artist,
    t.tour_name,
    tl.region,
    tl.leg_name,
    s.status
FROM shows s
JOIN tour_legs tl ON s.leg_id   = tl.leg_id
JOIN tours t      ON tl.tour_id = t.tour_id
JOIN artists a    ON t.artist_id = a.artist_id
WHERE s.show_date BETWEEN :date_from AND :date_to
  AND s.status IN ('scheduled', 'completed', 'cancelled', 'rescheduled')  -- dynamic
ORDER BY s.show_date, s.start_time;


-- ============================================
-- PAGE 4: RESCHEDULE / CANCEL SHOWS
-- ============================================

-- 10. Get scheduled shows by artist (for reschedule)
SELECT
    s.show_id,
    t.tour_name,
    tl.region,
    s.show_date,
    s.start_time,
    s.status
FROM shows s
JOIN tour_legs tl ON s.leg_id    = tl.leg_id
JOIN tours t      ON tl.tour_id  = t.tour_id
JOIN artists a    ON t.artist_id = a.artist_id
WHERE a.artist_id = :artist_id
  AND s.status = 'scheduled'
ORDER BY s.show_date;

-- 11. Get scheduled and rescheduled shows by artist (for cancel)
SELECT
    s.show_id,
    t.tour_name,
    tl.region,
    s.show_date,
    s.status
FROM shows s
JOIN tour_legs tl ON s.leg_id    = tl.leg_id
JOIN tours t      ON tl.tour_id  = t.tour_id
JOIN artists a    ON t.artist_id = a.artist_id
WHERE a.artist_id = :artist_id
  AND s.status IN ('scheduled', 'rescheduled')
ORDER BY s.show_date;

-- 12. Stored Procedure: Reschedule a show
CALL reschedule_show(:show_id, :new_date, :new_time);

-- 13. Stored Procedure: Cancel a show
CALL cancel_show(:show_id);


-- ============================================
-- PAGE 5: TRIGGERS DEMO
-- ============================================

-- 14. Get scheduled/rescheduled shows by artist (for trigger demo)
SELECT
    s.show_id,
    t.tour_name,
    tl.region,
    s.show_date,
    s.start_time,
    s.status
FROM shows s
JOIN tour_legs tl ON s.leg_id    = tl.leg_id
JOIN tours t      ON tl.tour_id  = t.tour_id
JOIN artists a    ON t.artist_id = a.artist_id
WHERE a.artist_id = :artist_id
  AND s.status IN ('scheduled', 'rescheduled')
ORDER BY s.show_date;

-- 15. Update show date to trigger auto-complete
UPDATE shows
SET show_date = :past_date
WHERE show_id = :show_id;

-- 16. Verify trigger result
SELECT show_id, show_date, status
FROM shows
WHERE show_id = :show_id;


-- ============================================
-- STORED PROCEDURES DEFINITIONS
-- ============================================

-- Procedure 1: Reschedule a show (future date only, sets status to rescheduled)
CREATE OR REPLACE PROCEDURE reschedule_show(
    p_show_id  INT,
    p_new_date DATE,
    p_new_time TIME
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM shows WHERE show_id = p_show_id) THEN
        RAISE EXCEPTION 'Show ID % not found', p_show_id;
    END IF;

    UPDATE shows
    SET
        show_date  = p_new_date,
        start_time = p_new_time,
        status     = 'rescheduled'
    WHERE show_id = p_show_id
      AND status  = 'scheduled';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Show ID % is not in scheduled state and cannot be rescheduled', p_show_id;
    END IF;
END;
$$;

-- Procedure 2: Cancel a show (applies to scheduled and rescheduled)
CREATE OR REPLACE PROCEDURE cancel_show(
    p_show_id INT
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM shows WHERE show_id = p_show_id) THEN
        RAISE EXCEPTION 'Show ID % not found', p_show_id;
    END IF;

    UPDATE shows
    SET status = 'cancelled'
    WHERE show_id = p_show_id
      AND status IN ('scheduled', 'rescheduled');

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Show ID % is not in scheduled or rescheduled state and cannot be cancelled', p_show_id;
    END IF;
END;
$$;


-- ============================================
-- TRIGGER DEFINITION
-- ============================================

-- Trigger function: auto-set status to completed for past scheduled shows
CREATE OR REPLACE FUNCTION trg_auto_complete_show()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.show_date < CURRENT_DATE AND NEW.status = 'scheduled' THEN
        NEW.status := 'completed';
    END IF;
    RETURN NEW;
END;
$$;

-- Attach trigger to shows table
DROP TRIGGER IF EXISTS auto_complete_show ON shows;

CREATE TRIGGER auto_complete_show
BEFORE INSERT OR UPDATE ON shows
FOR EACH ROW
EXECUTE FUNCTION trg_auto_complete_show();