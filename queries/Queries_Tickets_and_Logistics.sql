-- ============================================
-- TICKETS & LOGISTICS MODULE
-- ============================================
-- All queries tested and syntax-verified
-- ============================================

-- ============================================
-- QUERY 1: Crew Utilization & Earnings Analysis
-- ============================================

SELECT 
    c.crew_id,
    c.person_name AS crew_name,
    c.role,
    c.contact_email,
    COUNT(DISTINCT sca.show_id) AS total_shows_worked,
    COUNT(CASE WHEN sca.payment_status = 'paid' THEN 1 END) AS shows_paid,
    COUNT(CASE WHEN sca.payment_status = 'pending' THEN 1 END) AS shows_pending,
    SUM(CASE WHEN sca.payment_status = 'paid' THEN sca.payment_amount ELSE 0 END) AS total_earnings,
    ROUND(AVG(sca.payment_amount), 2) AS avg_payment_per_show,
    MIN(sca.check_in_time) AS earliest_shift,
    MAX(sca.check_out_time) AS latest_shift
FROM crew c
LEFT JOIN show_crew_assignment sca ON c.crew_id = sca.crew_id
GROUP BY c.crew_id, c.person_name, c.role, c.contact_email
HAVING COUNT(sca.show_id) > 0
ORDER BY total_earnings DESC, total_shows_worked DESC
LIMIT 20;


-- ============================================
-- QUERY 2: Ticket Sales Performance by Show
-- ============================================

SELECT 
    s.show_id,
    s.show_date,
    v.name AS venue_name,
    ci.name AS venue_city,
    v.capacity AS venue_capacity,
    COUNT(DISTINCT ti.inventory_id) AS ticket_types_available,
    SUM(ti.total_quantity) AS total_tickets_available,
    COUNT(ts.sale_id) AS total_sales,
    SUM(ts.quantity_sold) AS tickets_sold,
    SUM(ts.total_amount) AS gross_revenue,
    ROUND((SUM(ts.quantity_sold)::NUMERIC / NULLIF(SUM(ti.total_quantity), 0) * 100), 2) AS sell_through_rate,
    ROUND(AVG(ts.total_amount / NULLIF(ts.quantity_sold, 0)), 2) AS avg_ticket_price,
    CASE 
        WHEN SUM(ts.quantity_sold)::NUMERIC / NULLIF(SUM(ti.total_quantity), 0) >= 0.90 THEN 'Sold Out'
        WHEN SUM(ts.quantity_sold)::NUMERIC / NULLIF(SUM(ti.total_quantity), 0) >= 0.70 THEN 'High Demand'
        WHEN SUM(ts.quantity_sold)::NUMERIC / NULLIF(SUM(ti.total_quantity), 0) >= 0.40 THEN 'Moderate Sales'
        ELSE 'Low Sales'
    END AS sales_status
FROM shows s
JOIN venues v ON s.venue_id = v.venue_id
JOIN cities ci ON v.city_id = ci.city_id
LEFT JOIN ticket_inventory ti ON s.show_id = ti.show_id
LEFT JOIN ticket_sale ts ON ti.inventory_id = ts.inventory_id
GROUP BY s.show_id, s.show_date, v.name, ci.name, v.capacity
ORDER BY gross_revenue DESC NULLS LAST;


-- ============================================
-- QUERY 3: Crew Scheduling Conflicts
-- ============================================

SELECT 
    c.crew_id,
    c.person_name AS crew_name,
    c.role,
    s1.show_id AS show1_id,
    s1.show_date AS show1_date,
    v1.name AS show1_venue,
    sca1.check_in_time AS show1_checkin,
    sca1.check_out_time AS show1_checkout,
    s2.show_id AS show2_id,
    s2.show_date AS show2_date,
    v2.name AS show2_venue,
    sca2.check_in_time AS show2_checkin,
    sca2.check_out_time AS show2_checkout,
    CASE 
        WHEN sca1.check_out_time > sca2.check_in_time 
         AND sca1.check_in_time < sca2.check_out_time THEN 'Time Overlap'
        WHEN s1.show_date = s2.show_date THEN 'Same Day - Different Times'
        ELSE 'Back-to-Back Shows'
    END AS conflict_type
FROM crew c
JOIN show_crew_assignment sca1 ON c.crew_id = sca1.crew_id
JOIN show_crew_assignment sca2 ON c.crew_id = sca2.crew_id
JOIN shows s1 ON sca1.show_id = s1.show_id
JOIN shows s2 ON sca2.show_id = s2.show_id
JOIN venues v1 ON s1.venue_id = v1.venue_id
JOIN venues v2 ON s2.venue_id = v2.venue_id
WHERE 
    sca1.show_id < sca2.show_id
    AND s1.show_date = s2.show_date
    AND sca1.check_out_time > sca2.check_in_time 
    AND sca1.check_in_time < sca2.check_out_time
ORDER BY c.person_name, s1.show_date;


-- ============================================
-- QUERY 4: Unsold Ticket Inventory Analysis
-- ============================================

SELECT 
    s.show_id,
    s.show_date,
    v.name AS venue_name,
    ci.name AS city,
    ti.ticket_type AS ticket_tier,
    ti.base_price AS ticket_price,
    ti.total_quantity AS tickets_available,
    COALESCE(
        (SELECT SUM(ts.quantity_sold)
         FROM ticket_sale ts 
         WHERE ts.inventory_id = ti.inventory_id), 
        0
    ) AS tickets_sold,
    ti.total_quantity - COALESCE(
        (SELECT SUM(ts.quantity_sold)
         FROM ticket_sale ts 
         WHERE ts.inventory_id = ti.inventory_id), 
        0
    ) AS tickets_remaining,
    ROUND(
        (COALESCE(
            (SELECT SUM(ts.quantity_sold)
             FROM ticket_sale ts 
             WHERE ts.inventory_id = ti.inventory_id), 
            0
        )::NUMERIC / ti.total_quantity * 100), 
        2
    ) AS percent_sold,
    (ti.total_quantity - COALESCE(
        (SELECT SUM(ts.quantity_sold)
         FROM ticket_sale ts 
         WHERE ts.inventory_id = ti.inventory_id), 
        0
    )) * ti.base_price AS potential_lost_revenue,
    s.show_date - CURRENT_DATE AS days_until_show,
    CASE 
        WHEN s.show_date - CURRENT_DATE <= 7 
         AND ti.total_quantity - COALESCE((SELECT SUM(ts.quantity_sold) FROM ticket_sale ts WHERE ts.inventory_id = ti.inventory_id), 0) > ti.total_quantity * 0.3
        THEN 'URGENT: Week out with 30%+ unsold'
        WHEN s.show_date - CURRENT_DATE <= 14 
         AND ti.total_quantity - COALESCE((SELECT SUM(ts.quantity_sold) FROM ticket_sale ts WHERE ts.inventory_id = ti.inventory_id), 0) > ti.total_quantity * 0.5
        THEN 'WARNING: Two weeks out with 50%+ unsold'
        ELSE 'On Track'
    END AS sales_alert
FROM shows s
JOIN venues v ON s.venue_id = v.venue_id
JOIN cities ci ON v.city_id = ci.city_id
JOIN ticket_inventory ti ON s.show_id = ti.show_id
WHERE 
    s.show_date >= CURRENT_DATE
    AND ti.total_quantity > COALESCE(
        (SELECT SUM(ts.quantity_sold)
         FROM ticket_sale ts 
         WHERE ts.inventory_id = ti.inventory_id), 
        0
    )
ORDER BY 
    days_until_show ASC,
    potential_lost_revenue DESC;


-- ============================================
-- QUERY 5: Crew Payment Status Summary
-- ============================================

SELECT 
    COALESCE(c.role, 'TOTAL') AS crew_role,
    COUNT(DISTINCT c.crew_id) AS crew_members,
    COUNT(sca.assignment_id) AS total_assignments,
    COUNT(CASE WHEN sca.payment_status = 'paid' THEN 1 END) AS paid_count,
    COUNT(CASE WHEN sca.payment_status = 'pending' THEN 1 END) AS pending_count,
    COUNT(CASE WHEN sca.payment_status = 'cancelled' THEN 1 END) AS cancelled_count,
    SUM(CASE WHEN sca.payment_status = 'paid' THEN sca.payment_amount ELSE 0 END) AS total_paid,
    SUM(CASE WHEN sca.payment_status = 'pending' THEN sca.payment_amount ELSE 0 END) AS total_pending,
    SUM(sca.payment_amount) AS total_owed,
    ROUND(
        COUNT(CASE WHEN sca.payment_status = 'paid' THEN 1 END)::NUMERIC / 
        NULLIF(COUNT(sca.assignment_id), 0) * 100, 
        2
    ) AS percent_paid
FROM crew c
LEFT JOIN show_crew_assignment sca ON c.crew_id = sca.crew_id
GROUP BY ROLLUP(c.role)
ORDER BY 
    CASE WHEN c.role IS NULL THEN 1 ELSE 0 END,
    total_pending DESC;


-- ============================================
-- QUERY 6: Daily Rate vs Actual Earnings
-- ============================================

SELECT 
    c.crew_id,
    c.person_name,
    c.role,
    c.daily_rate,
    COUNT(sca.assignment_id) AS shows_worked,
    ROUND(AVG(sca.payment_amount), 2) AS avg_payment_per_show,
    ROUND(c.daily_rate - AVG(sca.payment_amount), 2) AS rate_variance,
    ROUND(((c.daily_rate - AVG(sca.payment_amount)) / NULLIF(c.daily_rate, 0) * 100), 2) AS variance_percent,
    CASE 
        WHEN AVG(sca.payment_amount) > c.daily_rate * 1.1 THEN 'Above Rate (+10%)'
        WHEN AVG(sca.payment_amount) < c.daily_rate * 0.9 THEN 'Below Rate (-10%)'
        ELSE 'On Rate'
    END AS payment_status
FROM crew c
JOIN show_crew_assignment sca ON c.crew_id = sca.crew_id
WHERE sca.payment_status = 'paid'
GROUP BY c.crew_id, c.person_name, c.role, c.daily_rate
HAVING COUNT(sca.assignment_id) >= 3
ORDER BY variance_percent DESC;


-- ============================================
-- QUERY 7 (SIMPLE): Top Revenue Shows
-- ============================================

SELECT 
    s.show_id,
    s.show_date,
    v.name AS venue_name,
    SUM(ts.total_amount) AS total_revenue,
    SUM(ts.quantity_sold) AS tickets_sold
FROM shows s
JOIN venues v ON s.venue_id = v.venue_id
JOIN ticket_inventory ti ON s.show_id = ti.show_id
JOIN ticket_sale ts ON ti.inventory_id = ts.inventory_id
GROUP BY s.show_id, s.show_date, v.name
ORDER BY total_revenue DESC
LIMIT 10;