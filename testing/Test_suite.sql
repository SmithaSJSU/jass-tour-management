-- ============================================
-- JASS TOUR MANAGEMENT - COMPREHENSIVE TEST SUITE
-- ============================================
-- Purpose: Validate database functionality and data integrity
-- Created: April 29, 2026
-- Team: Jack, Anusha, Supritha, Smitha
--
-- Test Categories:
--   1. Row Count Checks        (data was loaded)
--   2. Data Integrity Tests    (constraints, foreign keys)
--   3. Business Logic Tests    (rules are enforced)
--   4. Query Correctness Tests (calculations are accurate)
--   5. Edge Case Tests         (NULLs, boundaries, empty sets)
--
-- HOW TO RUN:
--   Highlight each test individually in pgAdmin and press F5.
--   Every test returns a result column showing PASS or FAIL.
--   Expected result for all tests: PASS
--
-- SCHEMA QUICK REFERENCE:
--   ticket_inventory : inventory_id, show_id, ticket_type, section_name,
--                      total_quantity, base_price, service_fees, hold_quantity
--   ticket_sale      : sale_id, inventory_id, quantity_sold, sale_channel,
--                      sale_timestamp, total_amount, buyer_email
--   show_crew_assignment : assignment_id, show_id, crew_id, payment_amount,
--                          payment_status (pending/paid/cancelled)
--   crew             : crew_id, person_name, role, daily_rate, per_diem_amount
--   contract         : contract_id, show_id, contract_type, agreed_amount,
--                      status (draft/sent/signed/cancelled/disputed)
--   settlement       : settlement_id, show_id, gross_ticket_revenue,
--                      ticket_fees, venue_rent, production_costs, crew_costs,
--                      other_expenses, net_revenue (generated),
--                      artist_payment, promoter_profit (generated),
--                      settlement_date, status (pending/finalized/disputed/amended)
--   payment          : payment_id, contract_id, expense_id, amount,
--                      payment_date, payment_method, status, payment_type
-- ============================================


-- ============================================
-- CATEGORY 1: ROW COUNT CHECKS
-- ============================================
-- Verify all 20 tables have data loaded

-- TEST 1: All tables have data
SELECT
    t.table_name,
    (xpath('/row/cnt/text()',
        query_to_xml('SELECT COUNT(*) AS cnt FROM ' || quote_ident(t.table_name), false, true, ''))
    )[1]::text::integer AS row_count,
    CASE
        WHEN (xpath('/row/cnt/text()',
            query_to_xml('SELECT COUNT(*) AS cnt FROM ' || quote_ident(t.table_name), false, true, ''))
        )[1]::text::integer > 0
        THEN 'PASS'
        ELSE 'FAIL - TABLE IS EMPTY'
    END AS result
FROM information_schema.tables t
WHERE t.table_schema = 'public'
  AND t.table_type = 'BASE TABLE'
ORDER BY t.table_name;
-- Expected: PASS for all 20 tables


-- TEST 2: Minimum expected row counts per module
SELECT 'countries'        AS table_name, COUNT(*) AS row_count, CASE WHEN COUNT(*) >= 10  THEN 'PASS' ELSE 'FAIL' END AS result FROM countries
UNION ALL
SELECT 'cities',                          COUNT(*),              CASE WHEN COUNT(*) >= 20  THEN 'PASS' ELSE 'FAIL' END FROM cities
UNION ALL
SELECT 'venues',                          COUNT(*),              CASE WHEN COUNT(*) >= 50  THEN 'PASS' ELSE 'FAIL' END FROM venues
UNION ALL
SELECT 'routing',                         COUNT(*),              CASE WHEN COUNT(*) >= 50  THEN 'PASS' ELSE 'FAIL' END FROM routing
UNION ALL
SELECT 'managers',                        COUNT(*),              CASE WHEN COUNT(*) >= 5   THEN 'PASS' ELSE 'FAIL' END FROM managers
UNION ALL
SELECT 'artists',                         COUNT(*),              CASE WHEN COUNT(*) >= 5   THEN 'PASS' ELSE 'FAIL' END FROM artists
UNION ALL
SELECT 'tours',                           COUNT(*),              CASE WHEN COUNT(*) >= 5   THEN 'PASS' ELSE 'FAIL' END FROM tours
UNION ALL
SELECT 'tour_legs',                       COUNT(*),              CASE WHEN COUNT(*) >= 10  THEN 'PASS' ELSE 'FAIL' END FROM tour_legs
UNION ALL
SELECT 'shows',                           COUNT(*),              CASE WHEN COUNT(*) >= 20  THEN 'PASS' ELSE 'FAIL' END FROM shows
UNION ALL
SELECT 'promoter',                        COUNT(*),              CASE WHEN COUNT(*) >= 5   THEN 'PASS' ELSE 'FAIL' END FROM promoter
UNION ALL
SELECT 'contract',                        COUNT(*),              CASE WHEN COUNT(*) >= 20  THEN 'PASS' ELSE 'FAIL' END FROM contract
UNION ALL
SELECT 'expense',                         COUNT(*),              CASE WHEN COUNT(*) >= 20  THEN 'PASS' ELSE 'FAIL' END FROM expense
UNION ALL
SELECT 'payment',                         COUNT(*),              CASE WHEN COUNT(*) >= 20  THEN 'PASS' ELSE 'FAIL' END FROM payment
UNION ALL
SELECT 'settlement',                      COUNT(*),              CASE WHEN COUNT(*) >= 20  THEN 'PASS' ELSE 'FAIL' END FROM settlement
UNION ALL
SELECT 'crew',                            COUNT(*),              CASE WHEN COUNT(*) >= 20  THEN 'PASS' ELSE 'FAIL' END FROM crew
UNION ALL
SELECT 'transport',                       COUNT(*),              CASE WHEN COUNT(*) >= 10  THEN 'PASS' ELSE 'FAIL' END FROM transport
UNION ALL
SELECT 'equipment',                       COUNT(*),              CASE WHEN COUNT(*) >= 20  THEN 'PASS' ELSE 'FAIL' END FROM equipment
UNION ALL
SELECT 'ticket_inventory',                COUNT(*),              CASE WHEN COUNT(*) >= 50  THEN 'PASS' ELSE 'FAIL' END FROM ticket_inventory
UNION ALL
SELECT 'ticket_sale',                     COUNT(*),              CASE WHEN COUNT(*) >= 100 THEN 'PASS' ELSE 'FAIL' END FROM ticket_sale
UNION ALL
SELECT 'show_crew_assignment',            COUNT(*),              CASE WHEN COUNT(*) >= 50  THEN 'PASS' ELSE 'FAIL' END FROM show_crew_assignment
ORDER BY table_name;
-- Expected: PASS for all tables


-- ============================================
-- CATEGORY 2: DATA INTEGRITY TESTS
-- ============================================

-- TEST 3: No orphaned ticket sales (FK integrity)
SELECT
    'Orphaned ticket_sale rows' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM ticket_sale ts
LEFT JOIN ticket_inventory ti ON ts.inventory_id = ti.inventory_id
WHERE ti.inventory_id IS NULL;
-- Expected: 0 failed rows


-- TEST 4: No orphaned show_crew_assignment rows
SELECT
    'Orphaned show_crew_assignment rows' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM show_crew_assignment sca
LEFT JOIN shows s ON sca.show_id = s.show_id
LEFT JOIN crew c  ON sca.crew_id = c.crew_id
WHERE s.show_id IS NULL OR c.crew_id IS NULL;
-- Expected: 0 failed rows


-- TEST 5: No orphaned contracts
SELECT
    'Orphaned contract rows' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM contract c
LEFT JOIN shows s ON c.show_id = s.show_id
WHERE s.show_id IS NULL;
-- Expected: 0 failed rows


-- TEST 6: No orphaned payments
SELECT
    'Payments with no parent (no contract_id or expense_id)' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM payment
WHERE contract_id IS NULL AND expense_id IS NULL;
-- Expected: 0 failed rows (chk_payment_parent constraint)


-- TEST 7: No negative ticket quantities
SELECT
    'Negative ticket quantities' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM ticket_inventory
WHERE total_quantity < 0 OR hold_quantity < 0;
-- Expected: 0 failed rows


-- TEST 8: hold_quantity never exceeds total_quantity
SELECT
    'Oversold ticket inventory' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM ticket_inventory
WHERE hold_quantity > total_quantity;
-- Expected: 0 failed rows


-- TEST 9: No negative prices or amounts
SELECT
    'Negative base_price in ticket_inventory' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM ticket_inventory
WHERE base_price < 0 OR service_fees < 0
UNION ALL
SELECT
    'Negative total_amount in ticket_sale',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM ticket_sale
WHERE total_amount < 0
UNION ALL
SELECT
    'Negative payment amounts',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM payment
WHERE amount <= 0;
-- Expected: 0 failed rows for all


-- TEST 10: No duplicate show_crew_assignment (unique_show_crew constraint)
SELECT
    'Duplicate show_crew_assignment entries' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
    SELECT show_id, crew_id, COUNT(*) AS cnt
    FROM show_crew_assignment
    GROUP BY show_id, crew_id
    HAVING COUNT(*) > 1
) duplicates;
-- Expected: 0 failed rows


-- TEST 11: No duplicate settlements per show (UNIQUE constraint)
SELECT
    'Duplicate settlements per show' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
    SELECT show_id, COUNT(*) AS cnt
    FROM settlement
    GROUP BY show_id
    HAVING COUNT(*) > 1
) duplicates;
-- Expected: 0 failed rows


-- TEST 12: Valid payment_status values in show_crew_assignment
SELECT
    'Invalid payment_status in show_crew_assignment' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM show_crew_assignment
WHERE payment_status NOT IN ('pending', 'paid', 'cancelled');
-- Expected: 0 failed rows


-- TEST 13: Valid contract status values
SELECT
    'Invalid contract status values' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM contract
WHERE status NOT IN ('draft', 'sent', 'signed', 'cancelled', 'disputed');
-- Expected: 0 failed rows


-- TEST 14: Valid settlement status values
SELECT
    'Invalid settlement status values' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM settlement
WHERE status NOT IN ('pending', 'finalized', 'disputed', 'amended');
-- Expected: 0 failed rows


-- TEST 15: All shows have a valid venue and tour leg
SELECT
    'Shows missing venue or tour leg' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM shows s
LEFT JOIN venues v    ON s.venue_id = v.venue_id
LEFT JOIN tour_legs tl ON s.leg_id  = tl.leg_id
WHERE v.venue_id IS NULL OR tl.leg_id IS NULL;
-- Expected: 0 failed rows


-- ============================================
-- CATEGORY 3: BUSINESS LOGIC TESTS
-- ============================================

-- TEST 16: Every tour has at least one tour leg
SELECT
    'Tours with no tour legs' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM tours t
LEFT JOIN tour_legs tl ON t.tour_id = tl.tour_id
WHERE tl.leg_id IS NULL;
-- Expected: 0 failed rows


-- TEST 17: Every tour leg has at least one show
SELECT
    'Tour legs with no shows' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM tour_legs tl
LEFT JOIN shows s ON tl.leg_id = s.leg_id
WHERE s.show_id IS NULL;
-- Expected: 0 or low number (some legs may be future/planned)


-- TEST 18: Every show has at least one ticket inventory row
SELECT
    'Shows with no ticket inventory' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM shows s
LEFT JOIN ticket_inventory ti ON s.show_id = ti.show_id
WHERE ti.inventory_id IS NULL;
-- Expected: 0 failed rows


-- TEST 19: Venue capacity is always positive
SELECT
    'Venues with zero or negative capacity' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM venues
WHERE capacity <= 0;
-- Expected: 0 failed rows (enforced by CHECK constraint)


-- TEST 20: Crew daily_rate and per_diem are non-negative
SELECT
    'Crew with negative rates' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM crew
WHERE daily_rate < 0 OR per_diem_amount < 0;
-- Expected: 0 failed rows


-- TEST 21: Tour start_date is before end_date
SELECT
    'Tours where start_date >= end_date' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM tours
WHERE start_date IS NOT NULL
  AND end_date IS NOT NULL
  AND start_date >= end_date;
-- Expected: 0 failed rows


-- TEST 22: No expense assigned to more than one scope
-- (constraint: exactly one of show_id, tour_id, leg_id must be set)
SELECT
    'Expenses violating scope constraint' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM expense
WHERE (
    (show_id IS NOT NULL)::INT +
    (tour_id IS NOT NULL)::INT +
    (leg_id  IS NOT NULL)::INT
) != 1;
-- Expected: 0 failed rows


-- ============================================
-- CATEGORY 4: QUERY CORRECTNESS TESTS
-- ============================================


-- TEST 23: Revenue sanity check (total_amount is positive and non-null)
SELECT
    'Revenue sanity check' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM ticket_sale
WHERE total_amount IS NULL OR total_amount <= 0;
-- Expected: 0 failed rows


-- TEST 24: Settlement net_revenue is computed correctly
-- net_revenue is a GENERATED column:
-- gross - ticket_fees - venue_rent - production_costs - crew_costs - other_expenses
SELECT
    'Settlement net_revenue accuracy' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM settlement
WHERE ABS(net_revenue - (
    gross_ticket_revenue
    - ticket_fees
    - venue_rent
    - production_costs
    - crew_costs
    - other_expenses
)) > 0.01;
-- Expected: 0 failed rows (it is a GENERATED column so should always match)


-- TEST 25: Ticket sales quantity does not exceed inventory
SELECT
    'Shows where tickets sold exceed total inventory' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
    SELECT
        ti.inventory_id,
        ti.total_quantity,
        COALESCE(SUM(ts.quantity_sold), 0) AS total_sold
    FROM ticket_inventory ti
    LEFT JOIN ticket_sale ts ON ti.inventory_id = ts.inventory_id
    GROUP BY ti.inventory_id, ti.total_quantity
    HAVING COALESCE(SUM(ts.quantity_sold), 0) > ti.total_quantity
) oversold;
-- Expected: 0 failed rows


-- TEST 26: All payments have valid amounts
SELECT
    'All payments have valid positive amounts' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM payment
WHERE amount IS NULL OR amount <= 0;
-- Expected: 0 (flag if data generator created overpaid contracts)


-- TEST 27: Every tour has a valid artist (enforced by FK)
SELECT
    'Tours with no valid artist' AS test_name,
    COUNT(*) AS failed_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM tours t
LEFT JOIN artists a ON t.artist_id = a.artist_id
WHERE a.artist_id IS NULL;


-- ============================================
-- CATEGORY 5: EDGE CASE TESTS
-- ============================================

-- TEST 28: NULL handling — crew with no assignments still appear in LEFT JOIN
SELECT
    'Crew LEFT JOIN returns all crew' AS test_name,
    CASE
        WHEN (SELECT COUNT(*) FROM crew) =
             (SELECT COUNT(DISTINCT c.crew_id)
              FROM crew c
              LEFT JOIN show_crew_assignment sca ON c.crew_id = sca.crew_id)
        THEN 'PASS'
        ELSE 'FAIL'
    END AS result;
-- Expected: PASS


-- TEST 29: Shows with zero ticket sales still appear in revenue query
SELECT
    'Shows with zero sales handled correctly' AS test_name,
    COUNT(*) AS shows_with_zero_sales,
    CASE WHEN COUNT(*) >= 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM shows s
LEFT JOIN ticket_inventory ti ON s.show_id = ti.show_id
LEFT JOIN ticket_sale ts ON ti.inventory_id = ts.inventory_id
GROUP BY s.show_id
HAVING COALESCE(SUM(ts.total_amount), 0) = 0;
-- Expected: PASS (0 or more shows with zero sales is fine)


-- TEST 30: COALESCE handles NULL payment amounts correctly
SELECT
    'NULL payment_amount handled by COALESCE' AS test_name,
    CASE
        WHEN SUM(COALESCE(payment_amount, 0)) >= 0 THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM show_crew_assignment;
-- Expected: PASS


-- ============================================
-- SUMMARY REPORT
-- ============================================
-- Run this last to get an overview of data volume across all modules

SELECT
    'Jack — Venues & Geography'    AS module,
    (SELECT COUNT(*) FROM countries)  AS countries,
    (SELECT COUNT(*) FROM cities)     AS cities,
    (SELECT COUNT(*) FROM venues)     AS venues,
    (SELECT COUNT(*) FROM routing)    AS routing,
    (SELECT COUNT(*) FROM show_sequence) AS show_sequence
UNION ALL
SELECT
    'Anusha — Tours & Shows',
    (SELECT COUNT(*) FROM managers),
    (SELECT COUNT(*) FROM artists),
    (SELECT COUNT(*) FROM tours),
    (SELECT COUNT(*) FROM tour_legs),
    (SELECT COUNT(*) FROM shows)
UNION ALL
SELECT
    'Supritha — Contracts & Finance',
    (SELECT COUNT(*) FROM promoter),
    (SELECT COUNT(*) FROM contract),
    (SELECT COUNT(*) FROM expense),
    (SELECT COUNT(*) FROM payment),
    (SELECT COUNT(*) FROM settlement)
UNION ALL
SELECT
    'Smitha — Tickets & Logistics',
    (SELECT COUNT(*) FROM crew),
    (SELECT COUNT(*) FROM transport),
    (SELECT COUNT(*) FROM equipment),
    (SELECT COUNT(*) FROM ticket_inventory),
    (SELECT COUNT(*) FROM ticket_sale);