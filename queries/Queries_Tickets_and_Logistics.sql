-- ============================================
-- TICKETS & LOGISTICS MODULE
-- ============================================
-- Module covers: crew, show_crew_assignment, transport, equipment,
--                ticket_inventory, ticket_sale
-- Total: 5+ queries demonstrating various SQL concepts

-- ============================================
-- QUERY 1: Crew Utilization & Earnings Analysis
-- ============================================
-- Business Purpose: Identify top-performing crew members by workload and earnings
-- Demonstrates: Multi-table JOIN, GROUP BY, ORDER BY, aggregate functions
-- Complexity: Medium

SELECT 
    c.crew_id,
    c.name AS crew_name,
    c.role,
    c.phone,
    COUNT(DISTINCT sca.show_id) AS total_shows_worked,
    COUNT(CASE WHEN sca.payment_status = 'paid' THEN 1 END) AS shows_paid,
    COUNT(CASE WHEN sca.payment_status = 'pending' THEN 1 END) AS shows_pending,
    SUM(CASE WHEN sca.payment_status = 'paid' THEN sca.payment_amount ELSE 0 END) AS total_earnings,
    AVG(sca.payment_amount) AS avg_payment_per_show,
    MIN(sca.check_in_time) AS earliest_shift,
    MAX(sca.check_out_time) AS latest_shift
FROM crew c
LEFT JOIN show_crew_assignment sca ON c.crew_id = sca.crew_id
GROUP BY c.crew_id, c.name, c.role, c.phone
HAVING COUNT(sca.show_id) > 0
ORDER BY total_earnings DESC, total_shows_worked DESC
LIMIT 20;

-- Expected Output: Top 20 crew members ranked by earnings
-- Use Case: Payroll analysis, crew scheduling, performance reviews


-- ============================================
-- QUERY 2: Ticket Sales Performance by Show
-- ============================================
-- Business Purpose: Analyze ticket revenue and inventory status per show
-- Demonstrates: Multiple JOINs, subqueries, aggregate functions, CASE statements
-- Complexity: High

SELECT 
    s.show_id,
    s.show_date,
    v.name AS venue_name,
    v.city AS venue_city,
    v.capacity AS venue_capacity,
    
    -- Inventory metrics
    COUNT(DISTINCT ti.inventory_id) AS ticket_types_available,
    SUM(ti.quantity) AS total_tickets_available,
    
    -- Sales metrics
    COUNT(ts.sale_id) AS total_sales,
    SUM(ts.quantity) AS tickets_sold,
    SUM(ts.total_price) AS gross_revenue,
    
    -- Calculated metrics
    ROUND((SUM(ts.quantity)::NUMERIC / NULLIF(SUM(ti.quantity), 0) * 100), 2) AS sell_through_rate,
    ROUND(AVG(ts.total_price / ts.quantity), 2) AS avg_ticket_price,
    
    -- Status classification
    CASE 
        WHEN SUM(ts.quantity)::NUMERIC / NULLIF(SUM(ti.quantity), 0) >= 0.90 THEN 'Sold Out'
        WHEN SUM(ts.quantity)::NUMERIC / NULLIF(SUM(ti.quantity), 0) >= 0.70 THEN 'High Demand'
        WHEN SUM(ts.quantity)::NUMERIC / NULLIF(SUM(ti.quantity), 0) >= 0.40 THEN 'Moderate Sales'
        ELSE 'Low Sales'
    END AS sales_status
    
FROM shows s
JOIN venues v ON s.venue_id = v.venue_id
LEFT JOIN ticket_inventory ti ON s.show_id = ti.show_id
LEFT JOIN ticket_sale ts ON ti.inventory_id = ts.inventory_id
GROUP BY s.show_id, s.show_date, v.name, v.city, v.capacity
ORDER BY gross_revenue DESC NULLS LAST;

-- Expected Output: Shows ranked by revenue with detailed sales metrics
-- Use Case: Revenue forecasting, pricing strategy, venue selection


-- ============================================
-- QUERY 3: Transport & Equipment Logistics Cost Analysis
-- ============================================
-- Business Purpose: Calculate total logistics costs per show and identify cost outliers
-- Demonstrates: CTEs (Common Table Expressions), window functions, UNION
-- Complexity: High

WITH transport_costs AS (
    SELECT 
        show_id,
        'Transport' AS cost_type,
        SUM(cost) AS total_cost,
        COUNT(*) AS item_count,
        AVG(cost) AS avg_cost
    FROM transport
    GROUP BY show_id
),
equipment_costs AS (
    SELECT 
        show_id,
        'Equipment' AS cost_type,
        SUM(rental_cost) AS total_cost,
        COUNT(*) AS item_count,
        AVG(rental_cost) AS avg_cost
    FROM equipment
    GROUP BY show_id
),
combined_costs AS (
    SELECT * FROM transport_costs
    UNION ALL
    SELECT * FROM equipment_costs
)
SELECT 
    s.show_id,
    s.show_date,
    v.name AS venue_name,
    v.city,
    
    -- Cost breakdown
    SUM(CASE WHEN cc.cost_type = 'Transport' THEN cc.total_cost ELSE 0 END) AS transport_cost,
    SUM(CASE WHEN cc.cost_type = 'Equipment' THEN cc.total_cost ELSE 0 END) AS equipment_cost,
    SUM(cc.total_cost) AS total_logistics_cost,
    
    -- Item counts
    SUM(CASE WHEN cc.cost_type = 'Transport' THEN cc.item_count ELSE 0 END) AS transport_items,
    SUM(CASE WHEN cc.cost_type = 'Equipment' THEN cc.item_count ELSE 0 END) AS equipment_items,
    
    -- Rankings and comparisons
    RANK() OVER (ORDER BY SUM(cc.total_cost) DESC) AS cost_rank,
    ROUND(AVG(SUM(cc.total_cost)) OVER (), 2) AS avg_show_logistics_cost,
    
    -- Cost classification
    CASE 
        WHEN SUM(cc.total_cost) > AVG(SUM(cc.total_cost)) OVER () * 1.5 THEN 'High Cost'
        WHEN SUM(cc.total_cost) < AVG(SUM(cc.total_cost)) OVER () * 0.5 THEN 'Low Cost'
        ELSE 'Average Cost'
    END AS cost_category
    
FROM shows s
JOIN venues v ON s.venue_id = v.venue_id
LEFT JOIN combined_costs cc ON s.show_id = cc.show_id
GROUP BY s.show_id, s.show_date, v.name, v.city
HAVING SUM(cc.total_cost) IS NOT NULL
ORDER BY total_logistics_cost DESC;

-- Expected Output: Shows ranked by logistics costs with categorization
-- Use Case: Budget planning, cost reduction opportunities, vendor negotiations


-- ============================================
-- QUERY 4: Crew Scheduling Conflicts & Overlaps
-- ============================================
-- Business Purpose: Identify crew members assigned to overlapping shows
-- Demonstrates: Self-join, date/time operations, complex WHERE conditions
-- Complexity: High

SELECT 
    c.crew_id,
    c.name AS crew_name,
    c.role,
    
    -- First show details
    s1.show_id AS show1_id,
    s1.show_date AS show1_date,
    v1.name AS show1_venue,
    sca1.check_in_time AS show1_checkin,
    sca1.check_out_time AS show1_checkout,
    
    -- Second show details
    s2.show_id AS show2_id,
    s2.show_date AS show2_date,
    v2.name AS show2_venue,
    sca2.check_in_time AS show2_checkin,
    sca2.check_out_time AS show2_checkout,
    
    -- Overlap calculation
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
    sca1.show_id < sca2.show_id  -- Avoid duplicate pairs
    AND s1.show_date = s2.show_date  -- Same day
    AND (
        -- Check for time overlaps
        sca1.check_out_time > sca2.check_in_time 
        AND sca1.check_in_time < sca2.check_out_time
    )
ORDER BY c.name, s1.show_date;

-- Expected Output: Crew members with scheduling conflicts
-- Use Case: Crew scheduling, conflict resolution, workload balancing


-- ============================================
-- QUERY 5: Unsold Ticket Inventory Analysis
-- ============================================
-- Business Purpose: Identify shows with poor ticket sales and unsold inventory
-- Demonstrates: Subquery in SELECT, COALESCE, percentage calculations
-- Complexity: Medium

SELECT 
    s.show_id,
    s.show_date,
    v.name AS venue_name,
    v.city,
    ti.tier AS ticket_tier,
    ti.price AS ticket_price,
    ti.quantity AS tickets_available,
    
    -- Calculate sold tickets
    COALESCE(
        (SELECT SUM(ts.quantity) 
         FROM ticket_sale ts 
         WHERE ts.inventory_id = ti.inventory_id), 
        0
    ) AS tickets_sold,
    
    -- Calculate remaining inventory
    ti.quantity - COALESCE(
        (SELECT SUM(ts.quantity) 
         FROM ticket_sale ts 
         WHERE ts.inventory_id = ti.inventory_id), 
        0
    ) AS tickets_remaining,
    
    -- Calculate percentages
    ROUND(
        (COALESCE(
            (SELECT SUM(ts.quantity) 
             FROM ticket_sale ts 
             WHERE ts.inventory_id = ti.inventory_id), 
            0
        )::NUMERIC / ti.quantity * 100), 
        2
    ) AS percent_sold,
    
    -- Calculate revenue loss
    (ti.quantity - COALESCE(
        (SELECT SUM(ts.quantity) 
         FROM ticket_sale ts 
         WHERE ts.inventory_id = ti.inventory_id), 
        0
    )) * ti.price AS potential_lost_revenue,
    
    -- Days until show
    s.show_date - CURRENT_DATE AS days_until_show,
    
    -- Sales urgency
    CASE 
        WHEN s.show_date - CURRENT_DATE <= 7 
         AND ti.quantity - COALESCE((SELECT SUM(ts.quantity) FROM ticket_sale ts WHERE ts.inventory_id = ti.inventory_id), 0) > ti.quantity * 0.3
        THEN 'URGENT: Week out with 30%+ unsold'
        WHEN s.show_date - CURRENT_DATE <= 14 
         AND ti.quantity - COALESCE((SELECT SUM(ts.quantity) FROM ticket_sale ts WHERE ts.inventory_id = ti.inventory_id), 0) > ti.quantity * 0.5
        THEN 'WARNING: Two weeks out with 50%+ unsold'
        ELSE 'On Track'
    END AS sales_alert
    
FROM shows s
JOIN venues v ON s.venue_id = v.venue_id
JOIN ticket_inventory ti ON s.show_id = ti.show_id
WHERE 
    s.show_date >= CURRENT_DATE  -- Future shows only
    AND ti.quantity > COALESCE(
        (SELECT SUM(ts.quantity) 
         FROM ticket_sale ts 
         WHERE ts.inventory_id = ti.inventory_id), 
        0
    )  -- Has unsold tickets
ORDER BY 
    days_until_show ASC,
    potential_lost_revenue DESC;

-- Expected Output: Upcoming shows with unsold inventory ranked by urgency
-- Use Case: Marketing campaigns, dynamic pricing, promotional planning


-- ============================================
-- BONUS QUERY 6: Crew Payment Status Summary
-- ============================================
-- Business Purpose: Track outstanding crew payments for accounting
-- Demonstrates: Aggregate functions, GROUP BY ROLLUP, HAVING clause
-- Complexity: Medium

SELECT 
    COALESCE(c.role, 'TOTAL') AS crew_role,
    COUNT(DISTINCT c.crew_id) AS crew_members,
    COUNT(sca.assignment_id) AS total_assignments,
    
    -- Payment breakdown
    COUNT(CASE WHEN sca.payment_status = 'paid' THEN 1 END) AS paid_count,
    COUNT(CASE WHEN sca.payment_status = 'pending' THEN 1 END) AS pending_count,
    COUNT(CASE WHEN sca.payment_status = 'cancelled' THEN 1 END) AS cancelled_count,
    
    -- Financial summary
    SUM(CASE WHEN sca.payment_status = 'paid' THEN sca.payment_amount ELSE 0 END) AS total_paid,
    SUM(CASE WHEN sca.payment_status = 'pending' THEN sca.payment_amount ELSE 0 END) AS total_pending,
    SUM(sca.payment_amount) AS total_owed,
    
    -- Percentages
    ROUND(
        COUNT(CASE WHEN sca.payment_status = 'paid' THEN 1 END)::NUMERIC / 
        NULLIF(COUNT(sca.assignment_id), 0) * 100, 
        2
    ) AS percent_paid
    
FROM crew c
LEFT JOIN show_crew_assignment sca ON c.crew_id = sca.crew_id
GROUP BY ROLLUP(c.role)
ORDER BY 
    CASE WHEN crew_role = 'TOTAL' THEN 1 ELSE 0 END,
    total_pending DESC;

-- Expected Output: Payment status by crew role with grand total
-- Use Case: Accounts payable, cash flow planning, crew relations


-- ============================================
-- QUERY EXECUTION INSTRUCTIONS
-- ============================================
-- 1. Run each query individually in pgAdmin
-- 2. Note execution time (for optimization comparison later)
-- 3. Export results to CSV for documentation
-- 4. Take screenshots for presentation
-- 5. Prepare to explain business value of each query

-- For EXPLAIN ANALYZE (performance testing):
-- EXPLAIN ANALYZE [paste query here];