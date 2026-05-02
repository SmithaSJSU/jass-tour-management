-- ============================================================
-- JASS Tour Management System
-- Finance Module Queries — Supritha
-- Tables: promoter, contract, expense, payment, settlement
-- ============================================================


-- ============================================================
-- SECTION 1: PROMOTER QUERIES
-- ============================================================

-- 1.1 List all promoters with their payment terms
SELECT promoter_id, company_name, contact_name, primary_market, payment_terms
FROM promoter
ORDER BY company_name;

-- 1.2 Count promoters by primary market
SELECT primary_market, COUNT(*) AS promoter_count
FROM promoter
GROUP BY primary_market
ORDER BY promoter_count DESC;

-- 1.3 Promoters using revenue-sharing payment terms (50/50 or 70/30 split)
SELECT company_name, contact_name, contact_email, payment_terms
FROM promoter
WHERE payment_terms LIKE '%split%'
ORDER BY payment_terms, company_name;

-- 1.4 Promoters in North America or Europe (major markets)
SELECT company_name, contact_name, primary_market, payment_terms
FROM promoter
WHERE primary_market IN ('North America', 'Europe')
ORDER BY primary_market, company_name;


-- ============================================================
-- SECTION 2: CONTRACT QUERIES
-- ============================================================

-- 2.1 Count contracts by type and status
SELECT contract_type, status, COUNT(*) AS count
FROM contract
GROUP BY contract_type, status
ORDER BY contract_type, status;

-- 2.2 Signed contracts with the highest agreed amounts (Top 10)
SELECT c.contract_id, c.contract_type, c.agreed_amount,
       c.percentage_of_net, c.signed_date
FROM contract c
WHERE c.status = 'signed'
ORDER BY c.agreed_amount DESC
LIMIT 10;

-- 2.3 Total contracted value by contract type (signed only)
SELECT contract_type,
       COUNT(*) AS num_contracts,
       SUM(agreed_amount) AS total_agreed,
       ROUND(AVG(agreed_amount), 2) AS avg_agreed
FROM contract
WHERE status = 'signed'
GROUP BY contract_type
ORDER BY total_agreed DESC;

-- 2.4 Disputed or cancelled contracts (need attention)
SELECT c.contract_id, c.contract_type, c.agreed_amount,
       c.status, c.terms
FROM contract c
WHERE c.status IN ('disputed', 'cancelled')
ORDER BY c.agreed_amount DESC;

-- 2.5 Contracts signed in 2026 vs 2025
SELECT EXTRACT(YEAR FROM signed_date) AS year,
       COUNT(*) AS contracts_signed,
       SUM(agreed_amount) AS total_value
FROM contract
WHERE status = 'signed' AND signed_date IS NOT NULL
GROUP BY year
ORDER BY year;

-- 2.6 Hybrid contracts: agreed amount AND percentage breakdown
SELECT contract_id, agreed_amount, percentage_of_net, status, signed_date
FROM contract
WHERE contract_type = 'hybrid' AND status = 'signed'
ORDER BY agreed_amount DESC;

-- 2.7 Unsigned contracts still pending (draft or sent)
SELECT contract_id, contract_type, agreed_amount, status
FROM contract
WHERE status IN ('draft', 'sent')
ORDER BY agreed_amount DESC;


-- ============================================================
-- SECTION 3: EXPENSE QUERIES
-- ============================================================

-- 3.1 Total expenses by category
SELECT category,
       COUNT(*) AS num_expenses,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(AVG(amount), 2) AS avg_amount
FROM expense
GROUP BY category
ORDER BY total_amount DESC;

-- 3.2 Show-level expenses vs. tour-level vs. leg-level
SELECT
    CASE
        WHEN show_id IS NOT NULL THEN 'Show'
        WHEN tour_id IS NOT NULL THEN 'Tour'
        WHEN leg_id IS NOT NULL  THEN 'Leg'
    END AS expense_scope,
    COUNT(*) AS num_expenses,
    ROUND(SUM(amount), 2) AS total_amount
FROM expense
GROUP BY expense_scope
ORDER BY total_amount DESC;

-- 3.3 Top 10 largest individual expenses
SELECT expense_id, category, amount, expense_date,
       vendor_name, approved_by,
       CASE
           WHEN show_id IS NOT NULL THEN 'Show-' || show_id
           WHEN tour_id IS NOT NULL THEN 'Tour-' || tour_id
           WHEN leg_id IS NOT NULL  THEN 'Leg-'  || leg_id
       END AS linked_to
FROM expense
ORDER BY amount DESC
LIMIT 10;

-- 3.4 Expenses with missing receipts (potential compliance issue)
SELECT expense_id, category, amount, expense_date, vendor_name, approved_by
FROM expense
WHERE receipt_no IS NULL
ORDER BY amount DESC;

-- 3.5 Expenses without an approver
SELECT expense_id, category, amount, expense_date, receipt_no
FROM expense
WHERE approved_by IS NULL
ORDER BY amount DESC;

-- 3.6 Monthly expense trend
SELECT TO_CHAR(expense_date, 'YYYY-MM') AS month,
       COUNT(*) AS num_expenses,
       ROUND(SUM(amount), 2) AS total_amount
FROM expense
GROUP BY month
ORDER BY month;

-- 3.7 Insurance and venue_rental expenses over $50,000 (high-value risk items)
SELECT expense_id, category, amount, expense_date, vendor_name, approved_by
FROM expense
WHERE category IN ('insurance', 'venue_rental') AND amount > 50000
ORDER BY amount DESC;


-- ============================================================
-- SECTION 4: PAYMENT QUERIES
-- ============================================================

-- 4.1 Payment summary by status
SELECT status,
       COUNT(*) AS num_payments,
       ROUND(SUM(amount), 2) AS total_amount
FROM payment
GROUP BY status
ORDER BY total_amount DESC;

-- 4.2 Payment summary by type
SELECT payment_type,
       COUNT(*) AS num_payments,
       ROUND(SUM(amount), 2) AS total_amount
FROM payment
GROUP BY payment_type
ORDER BY total_amount DESC;

-- 4.3 Payment method breakdown
SELECT payment_method,
       COUNT(*) AS num_payments,
       ROUND(SUM(amount), 2) AS total_amount
FROM payment
GROUP BY payment_method
ORDER BY total_amount DESC;

-- 4.4 Payments linked to contracts (artist payouts)
SELECT p.payment_id, p.payment_type, p.amount,
       p.payment_date, p.payment_method, p.status,
       c.contract_type, c.agreed_amount
FROM payment p
JOIN contract c ON p.contract_id = c.contract_id
WHERE p.contract_id IS NOT NULL
ORDER BY p.amount DESC
LIMIT 20;

-- 4.5 Payments linked to expenses (vendor disbursements / reimbursements)
SELECT p.payment_id, p.payment_type, p.amount,
       p.payment_date, p.status,
       e.category AS expense_category, e.vendor_name
FROM payment p
JOIN expense e ON p.expense_id = e.expense_id
WHERE p.expense_id IS NOT NULL
ORDER BY p.amount DESC
LIMIT 20;

-- 4.6 Failed or refunded payments (needs follow-up)
SELECT payment_id, payment_type, amount, payment_date,
       payment_method, status,
       contract_id, expense_id
FROM payment
WHERE status IN ('failed', 'refunded')
ORDER BY amount DESC;

-- 4.7 Total payments made per month
SELECT TO_CHAR(payment_date, 'YYYY-MM') AS month,
       COUNT(*) AS num_payments,
       ROUND(SUM(amount), 2) AS total_paid
FROM payment
WHERE status = 'completed'
GROUP BY month
ORDER BY month;

-- 4.8 Pending payments (outstanding cash flow)
SELECT payment_id, payment_type, amount, payment_date, payment_method,
       contract_id, expense_id
FROM payment
WHERE status = 'pending'
ORDER BY payment_date, amount DESC;


-- ============================================================
-- SECTION 5: SETTLEMENT QUERIES
-- ============================================================

-- 5.1 Settlement status summary
SELECT status,
       COUNT(*) AS num_settlements,
       ROUND(SUM(gross_ticket_revenue), 2) AS total_gross_revenue,
       ROUND(SUM(net_revenue), 2) AS total_net_revenue,
       ROUND(SUM(artist_payment), 2) AS total_artist_payments,
       ROUND(SUM(promoter_profit), 2) AS total_promoter_profit
FROM settlement
GROUP BY status
ORDER BY total_gross_revenue DESC;

-- 5.2 Top 10 most profitable shows (by promoter_profit)
SELECT s.settlement_id, s.gross_ticket_revenue,
       s.net_revenue, s.artist_payment, s.promoter_profit,
       s.settlement_date, s.status
FROM settlement s
ORDER BY s.promoter_profit DESC
LIMIT 10;

-- 5.3 Shows where artist payment exceeded promoter profit
SELECT settlement_id, gross_ticket_revenue, net_revenue,
       artist_payment, promoter_profit, settlement_date
FROM settlement
WHERE artist_payment > promoter_profit
ORDER BY artist_payment DESC;

-- 5.4 Average settlement breakdown (revenue vs. cost categories)
SELECT
    ROUND(AVG(gross_ticket_revenue), 2) AS avg_gross_revenue,
    ROUND(AVG(ticket_fees), 2) AS avg_ticket_fees,
    ROUND(AVG(venue_rent), 2) AS avg_venue_rent,
    ROUND(AVG(production_costs), 2) AS avg_production,
    ROUND(AVG(crew_costs), 2) AS avg_crew,
    ROUND(AVG(other_expenses), 2) AS avg_other_expenses,
    ROUND(AVG(net_revenue), 2) AS avg_net_revenue,
    ROUND(AVG(artist_payment), 2) AS avg_artist_payment,
    ROUND(AVG(promoter_profit), 2) AS avg_promoter_profit
FROM settlement;

-- 5.5 Disputed settlements (require resolution)
SELECT settlement_id, gross_ticket_revenue, net_revenue,
       artist_payment, promoter_profit, settlement_date
FROM settlement
WHERE status = 'disputed'
ORDER BY gross_ticket_revenue DESC;

-- 5.6 Settlement cost structure as % of gross revenue
SELECT
    ROUND(AVG(ticket_fees / NULLIF(gross_ticket_revenue, 0) * 100), 2)       AS avg_pct_ticket_fees,
    ROUND(AVG(venue_rent / NULLIF(gross_ticket_revenue, 0) * 100), 2)        AS avg_pct_venue_rent,
    ROUND(AVG(production_costs / NULLIF(gross_ticket_revenue, 0) * 100), 2) AS avg_pct_production,
    ROUND(AVG(crew_costs / NULLIF(gross_ticket_revenue, 0) * 100), 2)        AS avg_pct_crew,
    ROUND(AVG(artist_payment / NULLIF(gross_ticket_revenue, 0) * 100), 2)   AS avg_pct_artist_pay,
    ROUND(AVG(promoter_profit / NULLIF(gross_ticket_revenue, 0) * 100), 2)  AS avg_pct_promoter_profit
FROM settlement;


-- ============================================================
-- SECTION 6: CROSS-TABLE / ANALYTICAL QUERIES
-- ============================================================

-- 6.1 Shows with contract value vs. actual settlement artist payment
SELECT c.contract_id, c.contract_type, c.agreed_amount AS contracted_amount,
       s.artist_payment AS actual_payment,
       (s.artist_payment - c.agreed_amount) AS variance
FROM contract c
JOIN shows sh ON c.show_id = sh.show_id
JOIN settlement s ON sh.show_id = s.show_id
WHERE c.status = 'signed'
ORDER BY ABS(s.artist_payment - c.agreed_amount) DESC
LIMIT 20;

-- 6.2 Promoter payment terms vs. average settlement promoter profit
SELECT p.payment_terms,
       COUNT(s.settlement_id) AS num_shows,
       ROUND(AVG(s.promoter_profit), 2) AS avg_promoter_profit,
       ROUND(SUM(s.gross_ticket_revenue), 2) AS total_gross
FROM promoter p
JOIN shows sh ON sh.promoter_id = p.promoter_id
JOIN settlement s ON s.show_id = sh.show_id
GROUP BY p.payment_terms
ORDER BY avg_promoter_profit DESC;

-- 6.3 Total payments made vs. total contracted amounts (completion rate)
SELECT
    COUNT(DISTINCT c.contract_id) AS total_signed_contracts,
    ROUND(SUM(c.agreed_amount), 2) AS total_contracted,
    ROUND(SUM(p.amount) FILTER (WHERE p.status = 'completed'), 2) AS total_paid_completed,
    ROUND(
        SUM(p.amount) FILTER (WHERE p.status = 'completed')
        / NULLIF(SUM(c.agreed_amount), 0) * 100, 2
    ) AS payment_completion_pct
FROM contract c
LEFT JOIN payment p ON p.contract_id = c.contract_id
WHERE c.status = 'signed';

-- 6.4 Expense categories contributing most to show-level costs
SELECT e.category,
       COUNT(*) AS num_expenses,
       ROUND(SUM(e.amount), 2) AS total,
       ROUND(AVG(e.amount), 2) AS avg_per_expense
FROM expense e
WHERE e.show_id IS NOT NULL
GROUP BY e.category
ORDER BY total DESC;

-- 6.5 Shows with no settlement yet (potential revenue gaps)
SELECT sh.show_id, sh.show_date, sh.status AS show_status
FROM shows sh
LEFT JOIN settlement s ON s.show_id = sh.show_id
WHERE s.settlement_id IS NULL
ORDER BY sh.show_date;

-- 6.6 Contracts linked to shows that have disputed settlements
SELECT c.contract_id, c.contract_type, c.agreed_amount, c.status AS contract_status,
       s.status AS settlement_status, s.gross_ticket_revenue, s.promoter_profit
FROM contract c
JOIN shows sh ON c.show_id = sh.show_id
JOIN settlement s ON sh.show_id = s.show_id
WHERE s.status = 'disputed'
ORDER BY c.agreed_amount DESC;