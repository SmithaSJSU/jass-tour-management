-- ============================================
-- JASS TOUR MANAGEMENT - INDEXING STRATEGY
-- ============================================
-- Purpose: Optimize query performance through strategic indexing
-- Created: April 29, 2026
-- Team: Jack, Anusha, Supritha, Smitha
--
-- INSTRUCTIONS:
-- 1. Run PART 1 queries WITHOUT indexes first (note timing in pgAdmin status bar)
-- 2. Run PART 2 to create all indexes
-- 3. Re-run PART 4 queries and compare timing
-- 4. Document performance improvements
--
-- NOTE: Run each query individually in pgAdmin by highlighting it.
--       Timing is shown automatically at the bottom of the results panel.
-- ============================================


-- ============================================
-- PART 1: BASELINE PERFORMANCE TESTING
-- ============================================
-- Run these queries BEFORE creating indexes
-- Note execution time shown in pgAdmin results panel

-- TEST 1: Show revenue analysis (uses ticket_sale, ticket_inventory, shows)
EXPLAIN ANALYZE
SELECT 
    s.show_id,
    s.show_date,
    COUNT(ts.sale_id) AS total_sales,
    SUM(ts.total_amount) AS revenue
FROM shows s
JOIN ticket_inventory ti ON s.show_id = ti.show_id
JOIN ticket_sale ts ON ti.inventory_id = ts.inventory_id
GROUP BY s.show_id, s.show_date
ORDER BY revenue DESC
LIMIT 20;

-- Record execution time: _____________ ms
-- Expected: 200-500ms without indexes


-- TEST 2: Crew utilization (uses crew, show_crew_assignment)
-- FIX: crew column is person_name, not name
EXPLAIN ANALYZE
SELECT 
    c.crew_id,
    c.person_name,
    COUNT(sca.show_id) AS shows_worked,
    SUM(sca.payment_amount) AS total_earnings
FROM crew c
LEFT JOIN show_crew_assignment sca ON c.crew_id = sca.crew_id
WHERE sca.payment_status = 'paid'
GROUP BY c.crew_id, c.person_name
ORDER BY total_earnings DESC;

-- Record execution time: _____________ ms


-- TEST 3: Tour profitability (multi-table join)
-- FIX: ts.total_price -> ts.total_amount
EXPLAIN ANALYZE
SELECT 
    t.tour_name,
    COUNT(s.show_id) AS total_shows,
    SUM(ts.total_amount) AS total_revenue
FROM tours t
JOIN tour_legs tl ON t.tour_id = tl.tour_id
JOIN shows s ON tl.leg_id = s.leg_id
JOIN ticket_inventory ti ON s.show_id = ti.show_id
JOIN ticket_sale ts ON ti.inventory_id = ts.inventory_id
GROUP BY t.tour_id, t.tour_name
ORDER BY total_revenue DESC;

-- Record execution time: _____________ ms


-- TEST 4: Venue performance by city
-- FIX: ts.total_price -> ts.total_amount
EXPLAIN ANALYZE
SELECT 
    v.name AS venue_name,
    c.name AS city_name,
    COUNT(s.show_id) AS shows_hosted,
    AVG(ts.total_amount) AS avg_ticket_amount
FROM venues v
JOIN cities c ON v.city_id = c.city_id
JOIN shows s ON v.venue_id = s.venue_id
JOIN ticket_inventory ti ON s.show_id = ti.show_id
JOIN ticket_sale ts ON ti.inventory_id = ts.inventory_id
GROUP BY v.venue_id, v.name, c.name
ORDER BY shows_hosted DESC;

-- Record execution time: _____________ ms


-- TEST 5: Payment settlement status
-- FIX: contract column is agreed_amount, not contract_value
EXPLAIN ANALYZE
SELECT 
    s.show_id,
    s.show_date,
    c.agreed_amount,
    SUM(p.amount) AS payments_made
FROM shows s
JOIN contract c ON s.show_id = c.show_id
LEFT JOIN payment p ON c.contract_id = p.contract_id
WHERE s.show_date < CURRENT_DATE
GROUP BY s.show_id, s.show_date, c.agreed_amount
HAVING c.agreed_amount > SUM(COALESCE(p.amount, 0));

-- Record execution time: _____________ ms


-- ============================================
-- PART 2: INDEX CREATION SCRIPTS
-- ============================================
-- Create indexes strategically based on query patterns
-- Focus on: JOIN columns, WHERE clauses, ORDER BY columns

-- --------------------------------------------
-- CATEGORY 1: Primary Foreign Key Indexes
-- --------------------------------------------

-- Shows table (heavily joined)
CREATE INDEX IF NOT EXISTS idx_shows_venue_id   ON shows(venue_id);
CREATE INDEX IF NOT EXISTS idx_shows_leg_id     ON shows(leg_id);
CREATE INDEX IF NOT EXISTS idx_shows_show_date  ON shows(show_date);
CREATE INDEX IF NOT EXISTS idx_shows_promoter_id ON shows(promoter_id);

-- Ticket tables (high volume)
CREATE INDEX IF NOT EXISTS idx_ticket_inventory_show_id    ON ticket_inventory(show_id);
CREATE INDEX IF NOT EXISTS idx_ticket_sale_inventory_id    ON ticket_sale(inventory_id);
CREATE INDEX IF NOT EXISTS idx_ticket_sale_sale_timestamp  ON ticket_sale(sale_timestamp);

-- Crew assignments
CREATE INDEX IF NOT EXISTS idx_show_crew_assignment_show_id        ON show_crew_assignment(show_id);
CREATE INDEX IF NOT EXISTS idx_show_crew_assignment_crew_id        ON show_crew_assignment(crew_id);
CREATE INDEX IF NOT EXISTS idx_show_crew_assignment_payment_status ON show_crew_assignment(payment_status);

-- Tour hierarchy
CREATE INDEX IF NOT EXISTS idx_tour_legs_tour_id  ON tour_legs(tour_id);
CREATE INDEX IF NOT EXISTS idx_tours_artist_id    ON tours(artist_id);
CREATE INDEX IF NOT EXISTS idx_artists_manager_id ON artists(manager_id);

-- Geography
CREATE INDEX IF NOT EXISTS idx_venues_city_id    ON venues(city_id);
CREATE INDEX IF NOT EXISTS idx_cities_country_id ON cities(country_id);

-- Finance
CREATE INDEX IF NOT EXISTS idx_contract_show_id   ON contract(show_id);
CREATE INDEX IF NOT EXISTS idx_payment_contract_id ON payment(contract_id);
CREATE INDEX IF NOT EXISTS idx_payment_expense_id  ON payment(expense_id);
CREATE INDEX IF NOT EXISTS idx_expense_show_id     ON expense(show_id);
CREATE INDEX IF NOT EXISTS idx_expense_tour_id     ON expense(tour_id);
CREATE INDEX IF NOT EXISTS idx_expense_leg_id      ON expense(leg_id);
CREATE INDEX IF NOT EXISTS idx_settlement_show_id  ON settlement(show_id);

-- Logistics
-- FIX: transport and equipment link to tour_id, not show_id
CREATE INDEX IF NOT EXISTS idx_transport_tour_id  ON transport(tour_id);
CREATE INDEX IF NOT EXISTS idx_equipment_tour_id  ON equipment(tour_id);
CREATE INDEX IF NOT EXISTS idx_equipment_transport_id ON equipment(transport_id);

-- Routing
-- FIX: columns are from_venue_id / to_venue_id, not origin/destination city
CREATE INDEX IF NOT EXISTS idx_routing_from_venue ON routing(from_venue_id);
CREATE INDEX IF NOT EXISTS idx_routing_to_venue   ON routing(to_venue_id);

-- Show sequence
-- FIX: show_sequence has show_id and tour_id, not current_show_id/next_show_id
CREATE INDEX IF NOT EXISTS idx_show_sequence_show_id  ON show_sequence(show_id);
CREATE INDEX IF NOT EXISTS idx_show_sequence_tour_id  ON show_sequence(tour_id);
CREATE INDEX IF NOT EXISTS idx_show_sequence_number   ON show_sequence(sequence_number);


-- --------------------------------------------
-- CATEGORY 2: Composite Indexes
-- --------------------------------------------

-- Ticket sales by timestamp and channel
CREATE INDEX IF NOT EXISTS idx_ticket_sale_timestamp_channel 
    ON ticket_sale(sale_timestamp, sale_channel);

-- Crew assignments by show and payment status
CREATE INDEX IF NOT EXISTS idx_crew_show_payment 
    ON show_crew_assignment(show_id, payment_status);

-- Shows by date and status
CREATE INDEX IF NOT EXISTS idx_shows_date_status 
    ON shows(show_date, status) WHERE status IS NOT NULL;

-- Expenses by show and category
CREATE INDEX IF NOT EXISTS idx_expense_show_category 
    ON expense(show_id, category) WHERE show_id IS NOT NULL;

-- Contract by show and status
CREATE INDEX IF NOT EXISTS idx_contract_show_status 
    ON contract(show_id, status);


-- --------------------------------------------
-- CATEGORY 3: Covering Indexes
-- --------------------------------------------

-- Crew assignment covering (avoids table lookup for common query columns)
CREATE INDEX IF NOT EXISTS idx_crew_assignment_covering 
    ON show_crew_assignment(show_id, crew_id, payment_status, payment_amount);

-- Ticket inventory covering (show + price + quantity)
-- FIX: actual columns are show_id, ticket_type, base_price, total_quantity
CREATE INDEX IF NOT EXISTS idx_ticket_inventory_covering 
    ON ticket_inventory(show_id, ticket_type, base_price, total_quantity);

-- Ticket sale covering
CREATE INDEX IF NOT EXISTS idx_ticket_sale_covering 
    ON ticket_sale(inventory_id, total_amount, quantity_sold, sale_channel);


-- --------------------------------------------
-- CATEGORY 4: Partial Indexes
-- --------------------------------------------

-- Only pending crew payments
CREATE INDEX IF NOT EXISTS idx_crew_pending_payments 
    ON show_crew_assignment(show_id, payment_amount) 
    WHERE payment_status = 'pending';

-- Only future shows
CREATE INDEX IF NOT EXISTS idx_future_shows 
    ON shows(show_date, venue_id) 
    WHERE show_date >= CURRENT_DATE;

-- Only unsettled contracts
-- FIX: settlement_status is on settlement table, not contract
--      contract has its own status column
CREATE INDEX IF NOT EXISTS idx_unsigned_contracts 
    ON contract(show_id, agreed_amount)
    WHERE status IN ('draft', 'sent');

-- Settlements not yet finalized
CREATE INDEX IF NOT EXISTS idx_pending_settlements
    ON settlement(show_id, status)
    WHERE status IN ('pending', 'disputed');


-- --------------------------------------------
-- CATEGORY 5: Text Search Indexes
-- --------------------------------------------
-- Requires pg_trgm extension for fuzzy name searching

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS idx_venues_name_trgm  ON venues  USING gin(name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_artists_name_trgm ON artists USING gin(name gin_trgm_ops);
-- FIX: crew name column is person_name, not name
CREATE INDEX IF NOT EXISTS idx_crew_name_trgm    ON crew    USING gin(person_name gin_trgm_ops);


-- ============================================
-- PART 3: VERIFY INDEXES CREATED
-- ============================================

-- List all indexes in the public schema
SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- Check index sizes
SELECT 
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
ORDER BY pg_relation_size(indexrelid) DESC;


-- ============================================
-- PART 4: POST-OPTIMIZATION TESTING
-- ============================================
-- Re-run the SAME queries from Part 1 and compare timing

-- TEST 1 (AFTER INDEXES): Show revenue analysis
EXPLAIN ANALYZE
SELECT 
    s.show_id,
    s.show_date,
    COUNT(ts.sale_id) AS total_sales,
    SUM(ts.total_amount) AS revenue
FROM shows s
JOIN ticket_inventory ti ON s.show_id = ti.show_id
JOIN ticket_sale ts ON ti.inventory_id = ts.inventory_id
GROUP BY s.show_id, s.show_date
ORDER BY revenue DESC
LIMIT 20;

-- Record NEW execution time: _____________ ms
-- Improvement: (old - new) / old * 100 = _____% faster


-- TEST 2 (AFTER INDEXES): Crew utilization
EXPLAIN ANALYZE
SELECT 
    c.crew_id,
    c.person_name,
    COUNT(sca.show_id) AS shows_worked,
    SUM(sca.payment_amount) AS total_earnings
FROM crew c
LEFT JOIN show_crew_assignment sca ON c.crew_id = sca.crew_id
WHERE sca.payment_status = 'paid'
GROUP BY c.crew_id, c.person_name
ORDER BY total_earnings DESC;

-- Record NEW execution time: _____________ ms
-- Improvement: _____% faster


-- TEST 3 (AFTER INDEXES): Tour profitability
EXPLAIN ANALYZE
SELECT 
    t.tour_name,
    COUNT(s.show_id) AS total_shows,
    SUM(ts.total_amount) AS total_revenue
FROM tours t
JOIN tour_legs tl ON t.tour_id = tl.tour_id
JOIN shows s ON tl.leg_id = s.leg_id
JOIN ticket_inventory ti ON s.show_id = ti.show_id
JOIN ticket_sale ts ON ti.inventory_id = ts.inventory_id
GROUP BY t.tour_id, t.tour_name
ORDER BY total_revenue DESC;

-- Record NEW execution time: _____________ ms
-- Improvement: _____% faster


-- TEST 4 (AFTER INDEXES): Venue performance
EXPLAIN ANALYZE
SELECT 
    v.name AS venue_name,
    c.name AS city_name,
    COUNT(s.show_id) AS shows_hosted,
    AVG(ts.total_amount) AS avg_ticket_amount
FROM venues v
JOIN cities c ON v.city_id = c.city_id
JOIN shows s ON v.venue_id = s.venue_id
JOIN ticket_inventory ti ON s.show_id = ti.show_id
JOIN ticket_sale ts ON ti.inventory_id = ts.inventory_id
GROUP BY v.venue_id, v.name, c.name
ORDER BY shows_hosted DESC;

-- Record NEW execution time: _____________ ms
-- Improvement: _____% faster


-- TEST 5 (AFTER INDEXES): Payment settlement
EXPLAIN ANALYZE
SELECT 
    s.show_id,
    s.show_date,
    c.agreed_amount,
    SUM(p.amount) AS payments_made
FROM shows s
JOIN contract c ON s.show_id = c.show_id
LEFT JOIN payment p ON c.contract_id = p.contract_id
WHERE s.show_date < CURRENT_DATE
GROUP BY s.show_id, s.show_date, c.agreed_amount
HAVING c.agreed_amount > SUM(COALESCE(p.amount, 0));

-- Record NEW execution time: _____________ ms
-- Improvement: _____% faster


-- ============================================
-- PART 5: READING THE EXPLAIN ANALYZE OUTPUT
-- ============================================
--
-- Look for these changes in the output:
--
-- BEFORE indexes:
--   Seq Scan on ticket_sale  <- reads entire table row by row
--   cost=0.00..1523.45 rows=41470
--
-- AFTER indexes:
--   Index Scan using idx_ticket_sale_inventory_id  <- uses index
--   cost=0.29..8.31 rows=1
--
-- Key terms:
--   Seq Scan       = slow, no index used
--   Index Scan     = fast, index used
--   Bitmap Scan    = efficient for multiple matches
--   Nested Loop    = join strategy (good with indexes)
--   Hash Join      = join strategy (used when no index)
--
-- Actual rows vs Estimated rows: if very different, run ANALYZE to
-- update statistics:
--   ANALYZE shows;
--   ANALYZE ticket_sale;
--   ANALYZE ticket_inventory;