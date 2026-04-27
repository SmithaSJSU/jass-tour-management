-- ============================================
-- JASS Tour Management System
-- File: 01_create_tables.sql
-- Drops existing tables first, then creates all tables
-- ============================================
 
-- ============================================
-- STEP 1: Drop all existing tables (if they exist)
-- This ensures a clean slate every time
-- ============================================
 
DROP TABLE IF EXISTS payment CASCADE;
DROP TABLE IF EXISTS ticket_sale CASCADE;
DROP TABLE IF EXISTS settlement CASCADE;
DROP TABLE IF EXISTS expense CASCADE;
DROP TABLE IF EXISTS contract CASCADE;
DROP TABLE IF EXISTS show_crew_assignment CASCADE;
DROP TABLE IF EXISTS ticket_inventory CASCADE;
DROP TABLE IF EXISTS show_sequence CASCADE;
DROP TABLE IF EXISTS equipment CASCADE;
DROP TABLE IF EXISTS shows CASCADE;
DROP TABLE IF EXISTS transport CASCADE;
DROP TABLE IF EXISTS routing CASCADE;
DROP TABLE IF EXISTS tour_legs CASCADE;
DROP TABLE IF EXISTS venues CASCADE;
DROP TABLE IF EXISTS tours CASCADE;
DROP TABLE IF EXISTS cities CASCADE;
DROP TABLE IF EXISTS artists CASCADE;
DROP TABLE IF EXISTS promoter CASCADE;
DROP TABLE IF EXISTS crew CASCADE;
DROP TABLE IF EXISTS countries CASCADE;
DROP TABLE IF EXISTS managers CASCADE;
 
-- Verify all tables are dropped
DO $$ 
DECLARE
    table_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
    
    RAISE NOTICE 'Dropped all existing tables. Current count: %', table_count;
END $$;
 
-- ============================================
-- STEP 2: Create all tables in dependency order
-- ============================================
 
-- ============================================
-- PHASE 1: Independent Tables (No dependencies)
-- ============================================
 
CREATE TABLE managers (
    manager_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255)
);
 
create table countries
	(country_ID		SERIAL PRIMARY KEY,
	name			varchar(200) NOT NULL UNIQUE
	);
 
CREATE TABLE crew (
    crew_id SERIAL PRIMARY KEY,
    person_name VARCHAR(200) NOT NULL,
    role VARCHAR(100) NOT NULL,
    daily_rate DECIMAL(10,2) NOT NULL,
    per_diem_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    contact_email VARCHAR(255),
    emergency_contact VARCHAR(255)
);
 
CREATE TABLE promoter (
    promoter_id SERIAL PRIMARY KEY,
    company_name VARCHAR(200) NOT NULL,
    contact_name VARCHAR(150) NOT NULL,
    contact_email VARCHAR(254) NOT NULL,
    phone VARCHAR(30),
    primary_market VARCHAR(100),
    payment_terms VARCHAR(200)
);
 
COMMENT ON TABLE promoter IS 'Promotion companies that book and finance shows for artists.';
 
-- Progress indicator
DO $$ BEGIN RAISE NOTICE 'Phase 1 complete: 4 base tables created'; END $$;
 
-- ============================================
-- PHASE 2: First-Level Dependencies
-- ============================================
 
CREATE TABLE artists (
    artist_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    genre VARCHAR(100),
    manager_id INT,
    FOREIGN KEY (manager_id) REFERENCES managers(manager_id)
);
 
CREATE TABLE cities (
    city_id SERIAL PRIMARY KEY,
    name VARCHAR(200),
    country_id INT NOT NULL,
    FOREIGN KEY (country_id) REFERENCES countries(country_id)
);
 
-- Progress indicator
DO $$ BEGIN RAISE NOTICE 'Phase 2 complete: artists, cities'; END $$;
 
-- ============================================
-- PHASE 3: Second-Level Dependencies
-- ============================================
 
CREATE TABLE tours (
    tour_id SERIAL PRIMARY KEY,
    artist_id INT NOT NULL,
    tour_name VARCHAR(255) NOT NULL,
    start_date DATE,
    end_date DATE,
    FOREIGN KEY (artist_id) REFERENCES artists(artist_id)
);
 
CREATE TABLE venues (
    venue_id SERIAL PRIMARY KEY,
    name VARCHAR(200),
    city_id INT NOT NULL,
    capacity INT NOT NULL CHECK (capacity > 0),
    contact_info VARCHAR(200),
    coordinates POINT NOT NULL,
    indoor_outdoor VARCHAR(10) NOT NULL,
    FOREIGN KEY(city_id) REFERENCES cities(city_id)
);
 
-- Progress indicator
DO $$ BEGIN RAISE NOTICE 'Phase 3 complete: tours, venues'; END $$;
 
-- ============================================
-- PHASE 4: Third-Level Dependencies
-- ============================================
 
CREATE TABLE tour_legs (
    leg_id SERIAL PRIMARY KEY,
    tour_id INT NOT NULL,
    leg_name VARCHAR(30),
    region VARCHAR(100),
    start_date DATE,
    end_date DATE,
    FOREIGN KEY (tour_id) REFERENCES tours(tour_id)
);
 
CREATE TABLE routing (
    routing_id BIGSERIAL PRIMARY KEY,
    distance INT NOT NULL,
    estimated_travel_time INT NOT NULL,
    from_venue_id INT NOT NULL,
    to_venue_id INT NOT NULL,
    FOREIGN KEY(from_venue_id) REFERENCES venues(venue_id),
    FOREIGN KEY(to_venue_id) REFERENCES venues(venue_id)
);
 
CREATE TABLE transport (
    transport_id SERIAL PRIMARY KEY,
    tour_id INTEGER NOT NULL,
    vehicle_type VARCHAR(100) NOT NULL,
    vehicle_make_model VARCHAR(200),
    capacity_people INTEGER NOT NULL,
    capacity_weight_lbs INTEGER NOT NULL,
    license_plate VARCHAR(20),
    driver_name VARCHAR(200),
    insurance_expiry DATE,
    FOREIGN KEY(tour_id) REFERENCES tours(tour_id)
);
 
-- Progress indicator
DO $$ BEGIN RAISE NOTICE 'Phase 4 complete: tour_legs, routing, transport'; END $$;
 
-- ============================================
-- PHASE 5: Fourth-Level Dependencies
-- ============================================
 
CREATE TABLE shows (
    show_id SERIAL PRIMARY KEY,
    leg_id INT NOT NULL,
    venue_id INT NOT NULL,
    promoter_id INT NOT NULL,
    show_date DATE,
    start_time TIME,
    status VARCHAR(50),
    FOREIGN KEY (leg_id) REFERENCES tour_legs(leg_id),
    FOREIGN KEY (venue_id) REFERENCES venues(venue_id),
    FOREIGN KEY (promoter_id) REFERENCES promoter(promoter_id)
);
 
CREATE TABLE equipment (
    equipment_id SERIAL PRIMARY KEY,
    tour_id INTEGER NOT NULL,
    transport_id INTEGER,
    equipment_type VARCHAR(100) NOT NULL,
    item_description TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    weight_lbs DECIMAL(10,2),
    value_usd DECIMAL(12,2),
    requires_climate_control BOOLEAN DEFAULT FALSE,
    FOREIGN KEY(tour_id) REFERENCES tours(tour_id),
    FOREIGN KEY(transport_id) REFERENCES transport(transport_id)
);
 
-- Progress indicator
DO $$ BEGIN RAISE NOTICE 'Phase 5 complete: shows, equipment'; END $$;
 
-- ============================================
-- PHASE 6: Fifth-Level Dependencies
-- ============================================
 
CREATE TABLE show_sequence (
    sequence_id SERIAL PRIMARY KEY,
    sequence_number INT NOT NULL CHECK (sequence_number > 0),
    dist_from_previous_show INT NOT NULL CHECK (dist_from_previous_show >= 0),
    drive_time INT NOT NULL CHECK (drive_time >= 0),
    rest_days INT NOT NULL CHECK (rest_days >= 0),
    tour_id INT NOT NULL,
    show_id INT NOT NULL,
    FOREIGN KEY(tour_id) REFERENCES tours(tour_id),
    FOREIGN KEY(show_id) REFERENCES shows(show_id)
);
 
CREATE TABLE ticket_inventory (
    inventory_id SERIAL PRIMARY KEY,
    show_id INTEGER NOT NULL,
    ticket_type VARCHAR(50) NOT NULL,
    section_name VARCHAR(100) NOT NULL,
    total_quantity INTEGER NOT NULL,
    base_price DECIMAL(10,2) NOT NULL,
    service_fees DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    hold_quantity INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (show_id) REFERENCES shows(show_id)
);
 
CREATE TABLE show_crew_assignment (
    assignment_id SERIAL PRIMARY KEY,
    show_id INTEGER NOT NULL,
    crew_id INTEGER NOT NULL,
    check_in_time TIMESTAMP,
    check_out_time TIMESTAMP,
    payment_amount DECIMAL(10,2),
    payment_status VARCHAR(50) NOT NULL DEFAULT 'pending',
    FOREIGN KEY (show_id) REFERENCES shows(show_id),
    FOREIGN KEY (crew_id) REFERENCES crew(crew_id),
    CONSTRAINT unique_show_crew UNIQUE (show_id, crew_id)
);
 
CREATE TABLE contract (
    contract_id SERIAL PRIMARY KEY,
    show_id INT NOT NULL,
    contract_type VARCHAR(50) NOT NULL
        CHECK (contract_type IN ('guarantee', 'percentage', 'hybrid', 'flat_fee')),
    agreed_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    percentage_of_net NUMERIC(5,2) CHECK (percentage_of_net >= 0 AND percentage_of_net <= 100),
    status VARCHAR(30) NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft', 'sent', 'signed', 'cancelled', 'disputed')),
    terms TEXT,
    signed_date DATE,
    FOREIGN KEY (show_id) REFERENCES shows(show_id)
);
 
COMMENT ON TABLE contract IS 'Legal agreements between the artist/manager and a promoter for a specific show.';
 
CREATE TABLE expense (
    expense_id SERIAL PRIMARY KEY,
    show_id INT,
    tour_id INT,
    leg_id INT,
    amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
    expense_date DATE NOT NULL,
    category VARCHAR(60) NOT NULL
        CHECK (category IN (
            'venue_rental', 'production', 'catering', 'travel',
            'lodging', 'equipment', 'insurance', 'marketing',
            'crew', 'permits', 'miscellaneous'
        )),
    description TEXT,
    vendor_name VARCHAR(200),
    receipt_no VARCHAR(100),
    approved_by VARCHAR(150),
    CONSTRAINT chk_expense_scope CHECK (
        ((show_id IS NOT NULL)::INT
         + (tour_id IS NOT NULL)::INT
         + (leg_id IS NOT NULL)::INT
        ) = 1
    ),
    FOREIGN KEY (show_id) REFERENCES shows(show_id),
    FOREIGN KEY (tour_id) REFERENCES tours(tour_id),
    FOREIGN KEY (leg_id) REFERENCES tour_legs(leg_id)
);
 
COMMENT ON TABLE expense IS 'Line-item costs incurred at the show, tour, or leg level.';
 
CREATE TABLE settlement (
    settlement_id SERIAL PRIMARY KEY,
    show_id INT NOT NULL UNIQUE,
    gross_ticket_revenue NUMERIC(14,2) NOT NULL DEFAULT 0,
    ticket_fees NUMERIC(12,2) NOT NULL DEFAULT 0,
    venue_rent NUMERIC(12,2) NOT NULL DEFAULT 0,
    production_costs NUMERIC(12,2) NOT NULL DEFAULT 0,
    crew_costs NUMERIC(12,2) NOT NULL DEFAULT 0,
    other_expenses NUMERIC(12,2) NOT NULL DEFAULT 0,
    net_revenue NUMERIC(14,2) NOT NULL GENERATED ALWAYS AS (
        gross_ticket_revenue
        - ticket_fees
        - venue_rent
        - production_costs
        - crew_costs
        - other_expenses
    ) STORED,
    artist_payment NUMERIC(12,2) NOT NULL DEFAULT 0,
    promoter_profit NUMERIC(14,2) NOT NULL GENERATED ALWAYS AS (
        gross_ticket_revenue
        - ticket_fees
        - venue_rent
        - production_costs
        - crew_costs
        - other_expenses
        - artist_payment
    ) STORED,
    settlement_date DATE NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'finalized', 'disputed', 'amended')),
    FOREIGN KEY (show_id) REFERENCES shows(show_id)
);
 
COMMENT ON TABLE settlement IS 'Signed financial reconciliation for a completed show — one settlement per show.';
 
-- Progress indicator
DO $$ BEGIN RAISE NOTICE 'Phase 6 complete: show_sequence, ticket_inventory, show_crew_assignment, contract, expense, settlement'; END $$;
 
-- ============================================
-- PHASE 7: Final Dependencies
-- ============================================
 
CREATE TABLE ticket_sale (
    sale_id SERIAL PRIMARY KEY,
    inventory_id INTEGER NOT NULL,
    quantity_sold INTEGER NOT NULL,
    sale_channel VARCHAR(50) NOT NULL DEFAULT 'online',
    sale_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2) NOT NULL,
    buyer_email VARCHAR(255),
    FOREIGN KEY (inventory_id) REFERENCES ticket_inventory(inventory_id)
);
 
CREATE TABLE payment (
    payment_id SERIAL PRIMARY KEY,
    contract_id INT,
    expense_id INT,
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    payment_date DATE NOT NULL,
    payment_method VARCHAR(40) NOT NULL
        CHECK (payment_method IN ('wire', 'ach', 'check', 'credit_card', 'cash')),
    status VARCHAR(30) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    payment_type VARCHAR(40) NOT NULL
        CHECK (payment_type IN (
            'deposit', 'artist_guarantee', 'artist_percentage',
            'vendor_payment', 'reimbursement', 'settlement_payout'
        )),
    CONSTRAINT chk_payment_parent CHECK (
        contract_id IS NOT NULL OR expense_id IS NOT NULL
    ),
    FOREIGN KEY (contract_id) REFERENCES contract(contract_id),
    FOREIGN KEY (expense_id) REFERENCES expense(expense_id)
);
 
COMMENT ON TABLE payment IS 'Individual money movements — contract payouts to artists and vendor disbursements for expenses.';
 
-- Progress indicator
DO $$ BEGIN RAISE NOTICE 'Phase 7 complete: ticket_sale, payment'; END $$;
 
-- ============================================
-- STEP 3: Verify all tables created successfully
-- ============================================
 
DO $$
DECLARE
    table_count INTEGER;
    expected_count INTEGER := 20;
BEGIN
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables
    WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE';
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'TABLE CREATION COMPLETE!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total tables created: %', table_count;
    
    IF table_count = expected_count THEN
        RAISE NOTICE 'SUCCESS! All % tables created!', expected_count;
    ELSE
        RAISE WARNING 'Expected % tables but found %', expected_count, table_count;
        RAISE WARNING 'Please check for errors above.';
    END IF;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Tables by module:';
    RAISE NOTICE '  Anusha (5): managers, artists, tours, tour_legs, shows';
    RAISE NOTICE '  Jack (5): countries, cities, venues, routing, show_sequence';
    RAISE NOTICE '  Supritha (5): promoter, contract, expense, payment, settlement';
    RAISE NOTICE '  Smitha (6): crew, transport, equipment, ticket_inventory, ticket_sale, show_crew_assignment';
    RAISE NOTICE '========================================';
END $$;
 
-- List all created tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;
