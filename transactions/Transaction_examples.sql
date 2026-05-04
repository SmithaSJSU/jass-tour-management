-- ============================================
-- JASS TOUR MANAGEMENT - TRANSACTION EXAMPLES
-- ============================================
-- Purpose: Demonstrate ACID compliance and transaction handling
-- Created: April 29, 2026
-- Team: Jack, Anusha, Supritha, Smitha
--
-- Topics Covered:
-- 1. Basic transactions (BEGIN / COMMIT / ROLLBACK)
-- 2. ACID properties demonstration
-- 3. Isolation levels and locking
-- 4. Concurrent transaction handling
-- 5. Real-world business scenarios
--
-- HOW TO RUN IN pgAdmin:
--   Highlight ONE transaction block at a time and press F5.
--   Do NOT run the entire file at once.
--
-- SCHEMA NOTES (actual column names):
--   ticket_inventory : inventory_id, show_id, ticket_type, section_name,
--                      total_quantity, base_price, service_fees, hold_quantity
--   ticket_sale      : sale_id, inventory_id, quantity_sold, sale_channel,
--                      sale_timestamp, total_amount, buyer_email
--   show_crew_assignment : assignment_id, show_id, crew_id, payment_amount,
--                          payment_status, check_in_time, check_out_time
--   contract         : contract_id, show_id, contract_type, agreed_amount,
--                      percentage_of_net, status, terms, signed_date
--   settlement       : settlement_id, show_id, gross_ticket_revenue,
--                      ticket_fees, venue_rent, production_costs, crew_costs,
--                      other_expenses, net_revenue (generated), artist_payment,
--                      promoter_profit (generated), settlement_date, status
--   payment          : payment_id, contract_id, expense_id, amount,
--                      payment_date, payment_method, status, payment_type
-- ============================================


-- ============================================
-- TRANSACTION 1: Ticket Purchase (Atomicity Demo)
-- ============================================
-- Business Scenario: Customer purchases 4 VIP tickets for a show
-- ACID Property: ATOMICITY — all steps succeed or nothing is saved
-- Tables touched: ticket_inventory, ticket_sale

-- Step 0: Check initial state before the transaction
SELECT 
    inventory_id,
    ticket_type,
    section_name,
    total_quantity,
    hold_quantity,
    total_quantity - hold_quantity AS available_qty
FROM ticket_inventory
WHERE show_id = 1 AND ticket_type = 'VIP'
LIMIT 1;

-- Begin transaction
BEGIN;

DO $$
DECLARE
    v_inventory_id  INTEGER;
    v_available     INTEGER;
    v_base_price    NUMERIC(10,2);
    v_service_fees  NUMERIC(10,2);
    v_total         NUMERIC(10,2);
    v_qty_requested INTEGER := 4;
BEGIN
    SELECT 
        inventory_id,
        total_quantity - hold_quantity,
        base_price,
        service_fees
    INTO v_inventory_id, v_available, v_base_price, v_service_fees
    FROM ticket_inventory
    WHERE show_id = 2 AND ticket_type = 'VIP'
    LIMIT 1
    FOR UPDATE;

    IF v_available < v_qty_requested THEN
        RAISE EXCEPTION 
            'Not enough tickets. Requested: %, Available: %', 
            v_qty_requested, v_available;
    END IF;

    v_total := v_qty_requested * (v_base_price + v_service_fees);

    INSERT INTO ticket_sale (
        inventory_id, quantity_sold, sale_channel,
        sale_timestamp, total_amount, buyer_email
    )
    VALUES (
        v_inventory_id, v_qty_requested, 'online',
        CURRENT_TIMESTAMP, v_total, 'customer@example.com'
    );

    UPDATE ticket_inventory
    SET hold_quantity = hold_quantity + v_qty_requested
    WHERE inventory_id = v_inventory_id;

    RAISE NOTICE 'SUCCESS: % VIP tickets sold for $%', v_qty_requested, v_total;
END $$;

COMMIT;


-- Check the sale was recorded
SELECT * FROM ticket_sale WHERE buyer_email = 'customer@example.com';

-- Check hold_quantity increased by 4
SELECT inventory_id, ticket_type, total_quantity, hold_quantity,
       total_quantity - hold_quantity AS available
FROM ticket_inventory
WHERE inventory_id = 7;

-- ============================================
-- TRANSACTION 2: Atomicity Failure Demo (ROLLBACK)
-- ============================================
-- Business Scenario: Payment fails mid-transaction — nothing should be saved
-- ACID Property: ATOMICITY — partial changes must be rolled back
-- This shows what happens when something goes wrong

BEGIN;

DO $$
DECLARE
    v_inventory_id INTEGER;
BEGIN
    -- Step 1: Record a sale
    INSERT INTO ticket_sale (
        inventory_id, quantity_sold, sale_channel,
        sale_timestamp, total_amount, buyer_email
    )
    VALUES (
        1, 2, 'online',
        CURRENT_TIMESTAMP, 300.00, 'failtest@example.com'
    );

    -- Step 2: Update inventory
    UPDATE ticket_inventory
    SET hold_quantity = hold_quantity + 2
    WHERE inventory_id = 1;

    -- Step 3: Simulate payment processor failure
    RAISE EXCEPTION 'Payment processor error: card declined';

    -- Everything above is rolled back — nothing persists
END $$;

ROLLBACK;

-- Verify: no sale recorded for failtest@example.com
SELECT * FROM ticket_sale WHERE buyer_email = 'failtest@example.com';
-- Should return 0 rows — rollback worked


-- ============================================
-- TRANSACTION 3: Crew Payment Processing (Consistency Demo)
-- ============================================
-- Business Scenario: Mark all crew for a show as paid
-- ACID Property: CONSISTENCY — database rules are always enforced
-- Tables touched: show_crew_assignment

-- Check state before
SELECT 
    sca.assignment_id,
    c.person_name,
    sca.payment_amount,
    sca.payment_status
FROM show_crew_assignment sca
JOIN crew c ON sca.crew_id = c.crew_id
WHERE sca.show_id = 1
ORDER BY sca.assignment_id;

BEGIN;

-- Update all pending crew payments for show 1 to paid
UPDATE show_crew_assignment
SET payment_status = 'paid'
WHERE show_id = 1
  AND payment_status = 'pending';

-- Verify the total we are about to pay
SELECT 
    COUNT(*)              AS crew_members_paid,
    SUM(payment_amount)   AS total_payout
FROM show_crew_assignment
WHERE show_id = 1 AND payment_status = 'paid';

-- If totals look correct, commit
COMMIT;

-- If something looked wrong, you would run ROLLBACK instead of COMMIT


-- ============================================
-- TRANSACTION 4: Show Cancellation (Multi-Table Atomicity)
-- ============================================
-- Business Scenario: A show is cancelled — cancel tickets, cancel crew,
--                    update contract status, all atomically
-- ACID Property: ATOMICITY across 3 tables
-- Tables touched: shows, show_crew_assignment, contract

-- Check show exists and is not already cancelled
SELECT show_id, show_date, status
FROM shows
WHERE show_id = 1;

BEGIN;

DO $$
DECLARE
    v_show_id       INTEGER := 1;
    v_show_count    INTEGER;
    v_crew_updated  INTEGER;
BEGIN
    -- Step 1: Verify the show exists and is not already cancelled
    SELECT COUNT(*) INTO v_show_count
    FROM shows
    WHERE show_id = v_show_id AND status != 'cancelled';

    IF v_show_count = 0 THEN
        RAISE EXCEPTION 'Show % not found or already cancelled', v_show_id;
    END IF;

    -- Step 2: Cancel the show
    UPDATE shows
    SET status = 'cancelled'
    WHERE show_id = v_show_id;

    -- Step 3: Release all crew assignments (set payment to 0 if unpaid)
    UPDATE show_crew_assignment
    SET payment_status = 'cancelled'
    WHERE show_id = v_show_id
      AND payment_status = 'pending';

    GET DIAGNOSTICS v_crew_updated = ROW_COUNT;

    -- Step 4: Update contract status to cancelled
    UPDATE contract
    SET status = 'cancelled'
    WHERE show_id = v_show_id
      AND status IN ('draft', 'sent');

    RAISE NOTICE 'Show % cancelled. % crew assignments released.', 
                 v_show_id, v_crew_updated;
END $$;

COMMIT;

-- Verify all changes applied together
SELECT 
    s.show_id,
    s.status                        AS show_status,
    COUNT(sca.assignment_id)        AS total_crew,
    SUM(CASE WHEN sca.payment_status = 'cancelled' 
             THEN 1 ELSE 0 END)     AS crew_cancelled,
    c.status                        AS contract_status
FROM shows s
LEFT JOIN show_crew_assignment sca ON s.show_id = sca.show_id
LEFT JOIN contract c ON s.show_id = c.show_id
WHERE s.show_id = 1
GROUP BY s.show_id, s.status, c.status;


-- ============================================
-- TRANSACTION 5: Contract Payment Recording (Consistency)
-- ============================================
-- Business Scenario: Record a partial payment against a contract
-- ACID Property: CONSISTENCY — payment cannot exceed contract amount
-- Tables touched: payment, contract

-- Check contract balance first
SELECT 
    c.contract_id,
    c.agreed_amount,
    COALESCE(SUM(p.amount), 0)                       AS paid_so_far,
    c.agreed_amount - COALESCE(SUM(p.amount), 0)     AS balance_remaining
FROM contract c
LEFT JOIN payment p ON c.contract_id = p.contract_id
WHERE c.show_id = 1
GROUP BY c.contract_id, c.agreed_amount;

BEGIN;

DO $$
DECLARE
    v_contract_id   INTEGER;
    v_agreed        NUMERIC(12,2);
    v_already_paid  NUMERIC(12,2);
    v_balance       NUMERIC(12,2);
    v_payment_amt   NUMERIC(12,2) := 5000.00;
BEGIN
    -- Step 1a: Lock the contract row first
    SELECT contract_id, agreed_amount
    INTO v_contract_id, v_agreed
    FROM contract
    WHERE show_id = 3
    LIMIT 1
    FOR UPDATE;

    -- Step 1b: Calculate how much has already been paid
    SELECT COALESCE(SUM(p.amount), 0)
    INTO v_already_paid
    FROM payment p
    WHERE p.contract_id = v_contract_id;

    v_balance := v_agreed - v_already_paid;

    -- Step 2: Ensure payment does not exceed balance
    IF v_payment_amt > v_balance THEN
        RAISE EXCEPTION 
            'Payment of $% exceeds remaining balance of $%',
            v_payment_amt, v_balance;
    END IF;

    -- Step 3: Record the payment
    INSERT INTO payment (
        contract_id, amount, payment_date,
        payment_method, status, payment_type
    )
    VALUES (
        v_contract_id, v_payment_amt, CURRENT_DATE,
        'wire', 'completed', 'artist_guarantee'
    );

    RAISE NOTICE 'Payment of $% recorded. Remaining balance: $%',
                 v_payment_amt, v_balance - v_payment_amt;
END $$;

COMMIT;


-- ============================================
-- TRANSACTION 6: Isolation Demo — Preventing Overselling
-- ============================================
-- Business Scenario: Two customers try to buy the last 2 tickets
-- ACID Property: ISOLATION — concurrent transactions don't interfere
--
-- HOW TO DEMO THIS:
-- Open TWO separate query windows in pgAdmin and run them simultaneously.
--
-- WINDOW 1 (run first, don't commit yet):
BEGIN;
SELECT 
    inventory_id,
    ticket_type,
    total_quantity - hold_quantity AS available
FROM ticket_inventory
WHERE show_id = 1 AND ticket_type = 'GA'
LIMIT 1
FOR UPDATE;  -- Window 1 locks this row

-- WINDOW 2 (run while Window 1 is still open):
-- BEGIN;
-- SELECT inventory_id, ticket_type, total_quantity - hold_quantity AS available
-- FROM ticket_inventory
-- WHERE show_id = 1 AND ticket_type = 'GA'
-- LIMIT 1
-- FOR UPDATE;
-- ^ This will WAIT/BLOCK until Window 1 commits or rolls back
-- This is isolation working correctly — no overselling possible

-- Window 1: now commit
COMMIT;
-- Window 2 will unblock and proceed with updated data


-- ============================================
-- TRANSACTION 7: Savepoints (Selective Rollback)
-- ============================================
-- Business Scenario: Process payments for multiple crew members.
--                    If one payment fails, skip it but save the others.
-- Demonstrates: SAVEPOINT for granular rollback control

BEGIN;

-- Pay crew member 1
SAVEPOINT after_crew_1;
UPDATE show_crew_assignment
SET payment_status = 'paid'
WHERE assignment_id = 1 AND payment_status = 'pending';

-- Pay crew member 2
SAVEPOINT after_crew_2;
UPDATE show_crew_assignment
SET payment_status = 'paid'
WHERE assignment_id = 2 AND payment_status = 'pending';

-- Simulate: crew member 3 payment fails (e.g. bank error)
-- ROLLBACK TO SAVEPOINT after_crew_2;
-- This undoes only crew member 3's payment, keeping 1 and 2

-- Pay crew member 4
SAVEPOINT after_crew_4;
UPDATE show_crew_assignment
SET payment_status = 'paid'
WHERE assignment_id = 4 AND payment_status = 'pending';

-- All good — commit what succeeded
COMMIT;

-- Result: crew members 1, 2, and 4 are paid; crew member 3 is still pending


-- ============================================
-- TRANSACTION 8: Settlement Creation (Durability Demo)
-- ============================================
-- Business Scenario: Create a final settlement record for a completed show
-- ACID Property: DURABILITY — once committed, data survives system restart
-- Tables touched: settlement

-- Verify show is complete and no settlement exists yet
SELECT 
    s.show_id, s.show_date, s.status,
    st.settlement_id
FROM shows s
LEFT JOIN settlement st ON s.show_id = st.show_id
WHERE s.show_id = 1;

BEGIN;

DO $$
DECLARE
    v_show_id           INTEGER := 1;
    v_settlement_exists INTEGER;
    v_gross_revenue     NUMERIC(14,2);
BEGIN
    SELECT COUNT(*) INTO v_settlement_exists
    FROM settlement WHERE show_id = v_show_id;

    IF v_settlement_exists > 0 THEN
        RAISE EXCEPTION 'Settlement already exists for show %', v_show_id;
    END IF;

    SELECT COALESCE(SUM(ts.total_amount), 0) INTO v_gross_revenue
    FROM ticket_inventory ti
    JOIN ticket_sale ts ON ti.inventory_id = ts.inventory_id
    WHERE ti.show_id = v_show_id;

    INSERT INTO settlement (
        show_id, gross_ticket_revenue, ticket_fees, venue_rent,
        production_costs, crew_costs, other_expenses,
        artist_payment, settlement_date, status
    )
    VALUES (
        v_show_id,
        v_gross_revenue,
        v_gross_revenue * 0.05,
        2000.00,
        5000.00,
        COALESCE((
            SELECT SUM(payment_amount)
            FROM show_crew_assignment
            WHERE show_id = v_show_id AND payment_status = 'paid'
        ), 0),
        500.00,
        v_gross_revenue * 0.70,
        CURRENT_DATE,
        'finalized'
    );

    RAISE NOTICE 'Settlement created for show %. Gross revenue: $%',
                 v_show_id, v_gross_revenue;
END $$;

COMMIT;

-- Verify settlement was saved (durability — it will persist)
SELECT 
    settlement_id,
    show_id,
    gross_ticket_revenue,
    net_revenue,       -- generated column
    artist_payment,
    promoter_profit,   -- generated column
    status
FROM settlement
WHERE show_id = 2;


-- ============================================
-- ACID VERIFICATION QUERIES
-- ============================================
-- Run these after the transactions above to confirm ACID properties

-- A: Atomicity — no orphaned sales without inventory updates
SELECT 
    ts.sale_id,
    ts.inventory_id,
    ts.quantity_sold,
    ti.hold_quantity
FROM ticket_sale ts
JOIN ticket_inventory ti ON ts.inventory_id = ti.inventory_id
WHERE ti.hold_quantity < 0;
-- Should return 0 rows (no negative inventory)

-- C: Consistency — settlement math is correct (net_revenue is a generated column)
SELECT 
    show_id,
    gross_ticket_revenue,
    (ticket_fees + venue_rent + production_costs + crew_costs + other_expenses) AS total_costs,
    net_revenue,
    CASE 
        WHEN net_revenue = gross_ticket_revenue 
                          - ticket_fees 
                          - venue_rent 
                          - production_costs 
                          - crew_costs 
                          - other_expenses 
        THEN 'CONSISTENT' 
        ELSE 'ERROR' 
    END AS math_check
FROM settlement;
-- All rows should show CONSISTENT

-- I: Isolation — no double-sold tickets (hold_quantity never exceeds total_quantity)
SELECT 
    inventory_id,
    ticket_type,
    total_quantity,
    hold_quantity
FROM ticket_inventory
WHERE hold_quantity > total_quantity;
-- Should return 0 rows

-- D: Durability — committed sales are permanently recorded
SELECT 
    COUNT(*)            AS total_sales,
    SUM(total_amount)   AS total_revenue,
    MIN(sale_timestamp) AS first_sale,
    MAX(sale_timestamp) AS latest_sale
FROM ticket_sale;
-- Should show all committed sales with timestamps

