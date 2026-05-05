-- ============================================================
-- JASS Tour Management System
-- Index Performance Analysis
-- ============================================================
-- HOW TO USE:
--   BEFORE (no indexes):
    SET enable_seqscan = ON;
    SET enable_indexscan = OFF;
    SET enable_bitmapscan = OFF;
    SET enable_indexonlyscan = OFF;
--
--   AFTER (with indexes):
    SET enable_seqscan = ON;
    SET enable_indexscan = ON;
    SET enable_bitmapscan = ON;
    SET enable_indexonlyscan = ON;
-- ============================================================

-- ============================================================
-- QUERY 1: Tour Profitability Report
-- Shows revenue, costs, net profit and profit margin per show
-- Joins: shows → ticket_sale → ticket_inventory → contract →
--        settlement → show_crew_assignment → venues → cities →
--        countries → tour_legs → tours → artists → managers
-- ============================================================
-- RESULTS:
--   No Indexes:  58.499 ms
--   With Index:  35.627 ms
--   Improvement: 22.872 ms faster (39.1% reduction)
-- ============================================================

EXPLAIN ANALYZE
WITH show_revenue AS (
    SELECT 
        ti.show_id,
        SUM(ts.total_amount) AS ticket_revenue,
        COUNT(ts.sale_id)    AS tickets_sold
    FROM ticket_inventory ti
    LEFT JOIN ticket_sale ts ON ti.inventory_id = ts.inventory_id
    GROUP BY ti.show_id
),
show_costs AS (
    SELECT 
        s.show_id,
        tl.tour_id,
        COALESCE(SUM(sca.payment_amount), 0)          AS crew_costs,
        COALESCE((
            SELECT agreed_amount FROM contract c
            WHERE c.show_id = s.show_id LIMIT 1
        ), 0)                                          AS contract_costs,
        COALESCE((
            SELECT SUM(amount) FROM expense ex
            WHERE ex.show_id = s.show_id
        ), 0)                                          AS other_expenses
    FROM shows s
    JOIN tour_legs tl ON s.leg_id = tl.leg_id
    LEFT JOIN show_crew_assignment sca ON s.show_id = sca.show_id
    GROUP BY s.show_id, tl.tour_id
),
show_geography AS (
    SELECT 
        s.show_id,
        v.name     AS venue_name,
        v.capacity AS venue_capacity,
        c.name     AS city_name,
        co.name    AS country_name
    FROM shows s
    JOIN venues v    ON s.venue_id = v.venue_id
    JOIN cities c    ON v.city_id = c.city_id
    JOIN countries co ON c.country_id = co.country_id
),
tour_info AS (
    SELECT 
        s.show_id,
        t.tour_name,
        a.name AS artist_name,
        m.name AS manager_name,
        tl.leg_name
    FROM shows s
    JOIN tour_legs tl  ON s.leg_id = tl.leg_id
    JOIN tours t       ON tl.tour_id = t.tour_id
    LEFT JOIN artists a   ON t.artist_id = a.artist_id
    LEFT JOIN managers m  ON a.manager_id = m.manager_id
)
SELECT 
    s.show_id,
    s.show_date,
    ti.tour_name,
    ti.artist_name,
    ti.manager_name,
    ti.leg_name,
    sg.venue_name,
    sg.city_name,
    sg.country_name,
    COALESCE(sr.ticket_revenue, 0)                                                        AS ticket_revenue,
    sr.tickets_sold,
    sc.crew_costs,
    sc.contract_costs,
    sc.other_expenses,
    (sc.crew_costs + sc.contract_costs + sc.other_expenses)                               AS total_costs,
    COALESCE(sr.ticket_revenue, 0) - (sc.crew_costs + sc.contract_costs + sc.other_expenses) AS net_profit,
    ROUND(
        ((COALESCE(sr.ticket_revenue, 0) -
          (sc.crew_costs + sc.contract_costs + sc.other_expenses)) /
         NULLIF(COALESCE(sr.ticket_revenue, 0), 0) * 100),
        2
    )                                                                                      AS profit_margin_percent,
    ROUND((sr.tickets_sold::NUMERIC / NULLIF(sg.venue_capacity, 0) * 100), 2)             AS capacity_utilization,
    RANK() OVER (
        ORDER BY COALESCE(sr.ticket_revenue, 0) -
                 (sc.crew_costs + sc.contract_costs + sc.other_expenses) DESC
    )                                                                                      AS profitability_rank,
    CASE 
        WHEN COALESCE(sr.ticket_revenue, 0) - (sc.crew_costs + sc.contract_costs + sc.other_expenses) > 50000 THEN 'Highly Profitable'
        WHEN COALESCE(sr.ticket_revenue, 0) - (sc.crew_costs + sc.contract_costs + sc.other_expenses) > 10000 THEN 'Profitable'
        WHEN COALESCE(sr.ticket_revenue, 0) - (sc.crew_costs + sc.contract_costs + sc.other_expenses) > 0     THEN 'Break Even'
        ELSE 'Loss Making'
    END AS profit_category
FROM shows s
LEFT JOIN show_revenue   sr ON s.show_id = sr.show_id
LEFT JOIN show_costs     sc ON s.show_id = sc.show_id
LEFT JOIN show_geography sg ON s.show_id = sg.show_id
LEFT JOIN tour_info      ti ON s.show_id = ti.show_id
ORDER BY net_profit DESC;


-- ============================================================
-- QUERY 2: Tour Routing & Logistics Analysis
-- Pairs consecutive shows on the same tour and flags
-- tight schedules, long breaks, and international travel
-- Joins: show_sequence (self-join) → shows → venues →
--        cities → countries → routing
-- ============================================================
-- RESULTS:
--   No Indexes:  38.320 ms
--   With Index:   9.648 ms
--   Improvement: 28.672 ms faster (74.8% reduction)
-- ============================================================

EXPLAIN ANALYZE
WITH ordered_shows AS (
    SELECT 
        ss.tour_id,
        ss.show_id,
        ss.sequence_number,
        ss.dist_from_previous_show,
        ss.drive_time,
        ss.rest_days,
        s.show_date,
        s.venue_id,
        v.name  AS venue_name,
        c.name  AS city_name,
        co.name AS country_name
    FROM show_sequence ss
    JOIN shows s     ON ss.show_id = s.show_id
    JOIN venues v    ON s.venue_id = v.venue_id
    JOIN cities c    ON v.city_id = c.city_id
    JOIN countries co ON c.country_id = co.country_id
),
consecutive_shows AS (
    SELECT 
        cur.tour_id,
        cur.show_id        AS current_show_id,
        cur.show_date      AS current_show_date,
        cur.venue_id       AS current_venue_id,
        cur.venue_name     AS current_venue,
        cur.city_name      AS current_city,
        cur.country_name   AS current_country,
        nxt.show_id        AS next_show_id,
        nxt.show_date      AS next_show_date,
        nxt.venue_name     AS next_venue,
        nxt.city_name      AS next_city,
        nxt.country_name   AS next_country,
        nxt.sequence_number - cur.sequence_number AS sequence_gap,
        nxt.show_date - cur.show_date             AS days_between_shows,
        nxt.dist_from_previous_show               AS distance_from_prev,
        nxt.drive_time                            AS drive_time_hours,
        nxt.rest_days
    FROM ordered_shows cur
    JOIN ordered_shows nxt
      ON cur.tour_id = nxt.tour_id
     AND nxt.sequence_number = cur.sequence_number + 1
),
routing_info AS (
    SELECT 
        cs.*,
        r.distance              AS routing_distance,
        r.estimated_travel_time AS routing_travel_time
    FROM consecutive_shows cs
    LEFT JOIN routing r
      ON r.from_venue_id = cs.current_venue_id
     AND r.to_venue_id = (
             SELECT venue_id FROM shows
             WHERE show_id = cs.next_show_id
         )
)
SELECT 
    ri.current_show_id,
    ri.current_show_date,
    ri.current_venue,
    ri.current_city,
    ri.current_country,
    ri.next_show_id,
    ri.next_show_date,
    ri.next_venue,
    ri.next_city,
    ri.next_country,
    ri.days_between_shows,
    ri.distance_from_prev    AS distance_km,
    ri.drive_time_hours,
    ri.rest_days,
    CASE 
        WHEN ri.days_between_shows < 2 AND ri.distance_from_prev > 500 THEN 'TIGHT: Long distance, short time'
        WHEN ri.days_between_shows >= 5                                 THEN 'OPPORTUNITY: Long break, consider adding show'
        WHEN ri.distance_from_prev < 100                                THEN 'EFFICIENT: Short distance'
        ELSE 'NORMAL'
    END AS routing_flag,
    CASE 
        WHEN ri.current_country != ri.next_country THEN 'International'
        ELSE 'Domestic'
    END AS travel_type
FROM routing_info ri
ORDER BY ri.tour_id, ri.current_show_date;


-- ============================================================
-- QUERY 3: Artist Revenue Aggregation
-- Aggregates ticket revenue, contract value, settlements,
-- capacity utilization and geographic reach per artist
-- Joins: artists → managers → tours → tour_legs → shows →
--        venues → cities → countries → contract → settlement →
--        ticket_inventory → ticket_sale (via subqueries)
-- ============================================================
-- RESULTS:
--   No Indexes:  6982.264 ms
--   With Index:    56.106 ms
--   Improvement: 6926.158 ms faster (99.2% reduction)
-- ============================================================

EXPLAIN ANALYZE
SELECT 
    a.artist_id,
    a.name  AS artist_name,
    a.genre,
    m.name  AS manager_name,
    COUNT(DISTINCT t.tour_id)  AS total_tours,
    COUNT(DISTINCT s.show_id)  AS total_shows,
    SUM(
        COALESCE((
            SELECT SUM(ts.total_amount)
            FROM ticket_inventory ti
            JOIN ticket_sale ts ON ti.inventory_id = ts.inventory_id
            WHERE ti.show_id = s.show_id
        ), 0)
    )                          AS total_ticket_revenue,
    AVG(
        COALESCE((
            SELECT SUM(ts.total_amount)
            FROM ticket_inventory ti
            JOIN ticket_sale ts ON ti.inventory_id = ts.inventory_id
            WHERE ti.show_id = s.show_id
        ), 0)
    )                          AS avg_revenue_per_show,
    SUM(COALESCE(c.agreed_amount, 0))    AS total_contract_value,
    SUM(COALESCE(st.artist_payment, 0))  AS total_artist_payments,
    SUM(
        COALESCE((
            SELECT COUNT(*)
            FROM ticket_inventory ti
            JOIN ticket_sale ts ON ti.inventory_id = ts.inventory_id
            WHERE ti.show_id = s.show_id
        ), 0)
    )                          AS total_tickets_sold,
    AVG(
        COALESCE((
            SELECT COUNT(*)
            FROM ticket_inventory ti
            JOIN ticket_sale ts ON ti.inventory_id = ts.inventory_id
            WHERE ti.show_id = s.show_id
        ), 0)
    )                          AS avg_tickets_per_show,
    ROUND(
        AVG(
            COALESCE((
                SELECT COUNT(*)::NUMERIC / NULLIF(v.capacity, 0) * 100
                FROM ticket_inventory ti
                JOIN ticket_sale ts ON ti.inventory_id = ts.inventory_id
                WHERE ti.show_id = s.show_id
            ), 0)
        ),
        2
    )                          AS avg_capacity_utilization,
    COUNT(DISTINCT co.country_id) AS countries_performed,
    COUNT(DISTINCT ci.city_id)    AS cities_performed,
    CASE 
        WHEN COUNT(DISTINCT s.show_id) >= 50 THEN 'Touring Powerhouse'
        WHEN COUNT(DISTINCT s.show_id) >= 20 THEN 'Established Act'
        WHEN COUNT(DISTINCT s.show_id) >= 10 THEN 'Rising Star'
        ELSE 'Emerging Artist'
    END AS artist_tier
FROM artists a
LEFT JOIN managers m    ON a.manager_id = m.manager_id
LEFT JOIN tours t       ON a.artist_id = t.artist_id
LEFT JOIN tour_legs tl  ON t.tour_id = tl.tour_id
LEFT JOIN shows s       ON tl.leg_id = s.leg_id
LEFT JOIN venues v      ON s.venue_id = v.venue_id
LEFT JOIN cities ci     ON v.city_id = ci.city_id
LEFT JOIN countries co  ON ci.country_id = co.country_id
LEFT JOIN contract c    ON s.show_id = c.show_id
LEFT JOIN settlement st ON s.show_id = st.show_id
GROUP BY a.artist_id, a.name, a.genre, m.name
HAVING COUNT(DISTINCT s.show_id) > 0
ORDER BY total_ticket_revenue DESC;


-- ============================================================
-- QUERY 4: Venue Performance Analysis
-- Ranks venues by revenue, capacity utilization and expenses
-- within each country and overall
-- Joins: venues → cities → countries → shows →
--        ticket_inventory → ticket_sale → expense (via subqueries)
-- ============================================================
-- RESULTS:
--   No Indexes:  2878.870 ms
--   With Index:    35.078 ms
--   Improvement: 2843.792 ms faster (98.8% reduction)
-- ============================================================

EXPLAIN ANALYZE
WITH venue_metrics AS (
    SELECT 
        v.venue_id,
        v.name     AS venue_name,
        v.capacity,
        c.name     AS city_name,
        co.name    AS country_name,
        COUNT(s.show_id) AS shows_hosted,
        SUM(
            COALESCE((
                SELECT SUM(ts.total_amount)
                FROM ticket_inventory ti
                JOIN ticket_sale ts ON ti.inventory_id = ts.inventory_id
                WHERE ti.show_id = s.show_id
            ), 0)
        ) AS total_revenue,
        AVG(
            COALESCE((
                SELECT COUNT(*)::NUMERIC / NULLIF(v.capacity, 0) * 100
                FROM ticket_inventory ti
                JOIN ticket_sale ts ON ti.inventory_id = ts.inventory_id
                WHERE ti.show_id = s.show_id
            ), 0)
        ) AS avg_capacity_utilization,
        AVG(
            COALESCE((
                SELECT SUM(amount)
                FROM expense ex
                WHERE ex.show_id = s.show_id
            ), 0)
        ) AS avg_expenses_per_show
    FROM venues v
    JOIN cities c     ON v.city_id = c.city_id
    JOIN countries co ON c.country_id = co.country_id
    LEFT JOIN shows s ON v.venue_id = s.venue_id
    GROUP BY v.venue_id, v.name, v.capacity, c.name, co.name
)
SELECT 
    vm.country_name,
    vm.city_name,
    vm.venue_name,
    vm.capacity,
    vm.shows_hosted,
    vm.total_revenue,
    vm.avg_capacity_utilization,
    vm.avg_expenses_per_show,
    ROUND(vm.total_revenue / NULLIF(vm.shows_hosted, 0), 2)              AS avg_revenue_per_show,
    RANK() OVER (PARTITION BY vm.country_name ORDER BY vm.total_revenue DESC) AS rank_in_country,
    RANK() OVER (ORDER BY vm.total_revenue DESC)                          AS rank_overall,
    ROUND(AVG(vm.total_revenue) OVER (PARTITION BY vm.country_name), 2)  AS country_avg_revenue,
    ROUND(AVG(vm.avg_capacity_utilization) OVER (PARTITION BY vm.country_name), 2) AS country_avg_utilization,
    CASE 
        WHEN vm.avg_capacity_utilization >= 80 THEN 'High Demand'
        WHEN vm.avg_capacity_utilization >= 60 THEN 'Good Performance'
        WHEN vm.avg_capacity_utilization >= 40 THEN 'Moderate Performance'
        ELSE 'Poor Performance'
    END AS venue_rating
FROM venue_metrics vm
WHERE vm.shows_hosted > 0
ORDER BY vm.total_revenue DESC;


-- ============================================================
-- QUERY 5: Financial Reconciliation & Payment Status
-- Tracks outstanding contract balances, pending crew payments
-- and settlement mismatches per show
-- Joins: shows → venues → tour_legs → tours → artists →
--        contract → payment → show_crew_assignment → settlement
-- ============================================================
-- RESULTS:
--   No Indexes:  7.461 ms
--   With Index:  7.744 ms
--   Improvement: 0.283 ms slower (3.8% — no meaningful difference)
--   Note: Tables too small for index benefit at current dataset size
-- ============================================================

EXPLAIN ANALYZE
WITH contract_payments AS (
    SELECT 
        c.show_id,
        c.contract_id,
        c.agreed_amount                               AS contract_value,
        COALESCE(SUM(p.amount), 0)                    AS total_payments_made,
        c.agreed_amount - COALESCE(SUM(p.amount), 0)  AS contract_balance,
        COUNT(p.payment_id)                           AS payment_count,
        MAX(p.payment_date)                           AS last_payment_date
    FROM contract c
    LEFT JOIN payment p ON c.contract_id = p.contract_id
    GROUP BY c.show_id, c.contract_id, c.agreed_amount
),
crew_payments AS (
    SELECT 
        show_id,
        SUM(CASE WHEN payment_status = 'paid'    THEN payment_amount ELSE 0 END) AS crew_paid,
        SUM(CASE WHEN payment_status = 'pending' THEN payment_amount ELSE 0 END) AS crew_pending,
        COUNT(CASE WHEN payment_status = 'pending' THEN 1 END)                   AS pending_crew_count
    FROM show_crew_assignment
    GROUP BY show_id
),
show_settlements AS (
    SELECT 
        show_id,
        net_revenue    AS settlement_amount,
        artist_payment,
        status         AS settlement_status,
        settlement_date
    FROM settlement
)
SELECT 
    s.show_id,
    s.show_date,
    v.name     AS venue_name,
    t.tour_name,
    a.name     AS artist_name,
    cp.contract_value,
    cp.total_payments_made   AS contract_paid,
    cp.contract_balance      AS contract_outstanding,
    cp.payment_count         AS contract_payment_count,
    cp.last_payment_date,
    crp.crew_paid,
    crp.crew_pending         AS crew_outstanding,
    crp.pending_crew_count,
    ss.settlement_amount,
    ss.artist_payment,
    ss.settlement_status,
    ss.settlement_date,
    COALESCE(cp.contract_balance, 0) + COALESCE(crp.crew_pending, 0) AS total_outstanding,
    CURRENT_DATE - s.show_date AS days_since_show,
    CASE 
        WHEN CURRENT_DATE - s.show_date > 60
         AND (COALESCE(cp.contract_balance, 0) + COALESCE(crp.crew_pending, 0)) > 1000 THEN 'CRITICAL: 60+ days overdue'
        WHEN CURRENT_DATE - s.show_date > 30
         AND (COALESCE(cp.contract_balance, 0) + COALESCE(crp.crew_pending, 0)) > 500  THEN 'WARNING: 30+ days overdue'
        WHEN (COALESCE(cp.contract_balance, 0) + COALESCE(crp.crew_pending, 0)) > 0    THEN 'Active: Payment pending'
        ELSE 'Settled'
    END AS payment_status_flag,
    CASE 
        WHEN ss.settlement_status = 'finalized'
         AND (COALESCE(cp.contract_balance, 0) + COALESCE(crp.crew_pending, 0)) > 100 THEN 'MISMATCH: Finalized but has outstanding'
        WHEN ss.settlement_status IS NULL
         AND CURRENT_DATE - s.show_date > 45                                           THEN 'WARNING: No settlement record'
        ELSE 'OK'
    END AS reconciliation_flag
FROM shows s
JOIN venues v      ON s.venue_id = v.venue_id
JOIN tour_legs tl  ON s.leg_id = tl.leg_id
JOIN tours t       ON tl.tour_id = t.tour_id
LEFT JOIN artists a            ON t.artist_id = a.artist_id
LEFT JOIN contract_payments cp ON s.show_id = cp.show_id
LEFT JOIN crew_payments crp    ON s.show_id = crp.show_id
LEFT JOIN show_settlements ss  ON s.show_id = ss.show_id
WHERE s.show_date <= CURRENT_DATE
  AND (
      COALESCE(cp.contract_balance, 0) + COALESCE(crp.crew_pending, 0) > 0
      OR ss.settlement_status != 'finalized'
      OR ss.settlement_status IS NULL
  )
ORDER BY 
    CASE 
        WHEN CURRENT_DATE - s.show_date > 60 THEN 1
        WHEN CURRENT_DATE - s.show_date > 30 THEN 2
        ELSE 3
    END,
    total_outstanding DESC;


-- ============================================================
-- PERFORMANCE SUMMARY
-- ============================================================
--
--  Query | Description                  | Before    | After    | Saved     | Reduction
--  ------+------------------------------+-----------+----------+-----------+----------
--  Q1    | Tour Profitability Report    | 58.499 ms | 35.627 ms| 22.872 ms |  39.1%
--  Q2    | Tour Routing & Logistics     | 38.320 ms |  9.648 ms| 28.672 ms |  74.8%
--  Q3    | Artist Revenue Aggregation   |6982.264 ms| 56.106 ms|6926.158 ms|  99.2%
--  Q4    | Venue Performance Analysis   |2878.870 ms| 35.078 ms|2843.792 ms|  98.8%
--  Q5    | Financial Reconciliation     |  7.461 ms |  7.744 ms| -0.283 ms |  -3.8% *
-- Total  | 							 |9965.414 ms|144.201 ms|9821.211 ms| 98.6%
--
--  * Q5 showed no improvement — dataset too small for index benefit
--    on low-row tables (contract, payment, settlement < 1,000 rows)
--
-- ============================================================