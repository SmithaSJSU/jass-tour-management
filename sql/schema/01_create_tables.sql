-- 1. Create MANAGERS table first
CREATE TABLE MANAGERS (
    manager_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255)
);

-- 2. Create ARTISTS table with a Foreign Key to MANAGERS
CREATE TABLE ARTISTS (
    artist_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    genre VARCHAR(100),
    manager_id INT,
    FOREIGN KEY (manager_id) REFERENCES MANAGERS(manager_id)
);

-- 3. The rest of the tables (TOURS, TOUR_LEGS, SHOWS) follow
CREATE TABLE TOURS (
    tour_id INT PRIMARY KEY,
    artist_id INT NOT NULL,
    tour_name VARCHAR(255) NOT NULL,
    start_date DATE,
    end_date DATE,
    FOREIGN KEY (artist_id) REFERENCES ARTISTS(artist_id)
);

CREATE TABLE TOUR_LEGS (
    leg_id INT PRIMARY KEY,
    tour_id INT NOT NULL,
    leg_name VARCHAR(30),
    region VARCHAR(100),
    start_date DATE,
    end_date DATE,
    FOREIGN KEY (tour_id) REFERENCES TOURS(tour_id)
);

CREATE TABLE SHOWS (
    show_id INT PRIMARY KEY,
    leg_id INT NOT NULL,
    venue_id INT NOT NULL,
    promoter_id INT NOT NULL,
    show_date DATE,
    start_time TIME,
    status VARCHAR(50),
    FOREIGN KEY (leg_id) REFERENCES TOUR_LEGS(leg_id),
    FOREIGN KEY (venue_id) REFERENCES VENUES(venue_id),
    FOREIGN KEY (promoter_id) REFERENCES PROMOTER(promoter_id)
);

create table countries
    (country_id        SMALLINT,
    name            varchar(200) NOT NULL UNIQUE,
    primary key(country_id)
    );

create table cities
    (city_id    Serial,
    name        varchar(200),
    country_id SMALLINT NOT NULL,
    primary key(city_id),
    foreign key (country_id) references countries(country_id)
    );

create table venues
    (venue_id     Serial,
    name        varchar(200),
    city_id     Int NOT NULL,
    capacity    Int NOT NULL CHECK (capacity > 0),
    contact_info    varchar(200),
    coordinates        point NOT NULL,
    indoor_outdoor VARCHAR(10) NOT NULL,
    primary key(venue_id),
    foreign key(city_id) references cities(city_id)
    );

create table routing
    (routing_id                    BIGSERIAL,
    distance                    Int NOT NULL,
    estimated_travel_time        Int NOT NULL,
    from_venue_id                Int NOT NULL,
    to_venue_id                    INT NOT NULL,
    primary key(routing_id),
    foreign key(from_venue_id) references venues(venue_id),
    foreign key(to_venue_id) references venues(venue_id)
    );
    
create table show_sequence
    (sequence_id    SERIAL,
     sequence_number INT UNSIGNED NOT NULL,
     dist_from_previous_show    INT UNSIGNED NOT NULL,
     drive_time                    INT UNSIGNED NOT NULL,
     rest_days                    INT UNSIGNED NOT NULL,
     tour_id                    INT NOT NULL,
     show_id                    INT NOT NULL,
     primary key(sequence_id),
     foreign key(tour_id) references tours(tour_id),
     foreign key(show_id) references shows(show_id)
    );

CREATE TABLE TRANSPORT (
    transport_id SERIAL PRIMARY KEY,
    tour_id INTEGER NOT NULL,
    vehicle_type VARCHAR(100) NOT NULL,
    vehicle_make_model VARCHAR(200),
    capacity_people INTEGER NOT NULL,
    capacity_weight_lbs INTEGER NOT NULL,
    license_plate VARCHAR(20),
    driver_name VARCHAR(200),
    insurance_expiry DATE,
    FOREIN KEY(tour_id) REFERENCES TOURS(tour_id)
);

CREATE TABLE EQUIPMENT (
    equipment_id SERIAL PRIMARY KEY,
    tour_id INTEGER NOT NULL,
    transport_id INTEGER,  -- Nullable: equipment not yet loaded
    equipment_type VARCHAR(100) NOT NULL,
    item_description TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    weight_lbs DECIMAL(10,2),
    value_usd DECIMAL(12,2),
    requires_climate_control BOOLEAN DEFAULT FALSE,
    FOREIN KEY(tour_id) REFERENCES TOURS(tour_id),
    FOREIN KEY(transport_id) REFERENCES TRANSPORT(transport_id)
);

CREATE TABLE TICKET_INVENTORY (
    inventory_id SERIAL PRIMARY KEY,
    show_id INTEGER NOT NULL,
    ticket_type VARCHAR(50) NOT NULL,
    section_name VARCHAR(100) NOT NULL,
    total_quantity INTEGER NOT NULL,
    base_price DECIMAL(10,2) NOT NULL,
    service_fees DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    hold_quantity INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (show_id) REFERENCES SHOWS(show_id)
);

CREATE TABLE TICKET_SALE (
    sale_id SERIAL PRIMARY KEY,
    inventory_id INTEGER NOT NULL,
    quantity_sold INTEGER NOT NULL,
    sale_channel VARCHAR(50) NOT NULL DEFAULT 'online',
    sale_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2) NOT NULL,
    buyer_email VARCHAR(255),
    FOREIGN KEY (inventory_id) REFERENCES TICKET_INVENTORY(inventory_id)
);

CREATE TABLE CREW (
    crew_id SERIAL PRIMARY KEY,
    person_name VARCHAR(200) NOT NULL,
    role VARCHAR(100) NOT NULL,
    daily_rate DECIMAL(10,2) NOT NULL,
    per_diem_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    contact_email VARCHAR(255),
    emergency_contact VARCHAR(255)
);

CREATE TABLE SHOW_CREW_ASSIGNMENT (
    assignment_id SERIAL PRIMARY KEY,
    show_id INTEGER NOT NULL,
    crew_id INTEGER NOT NULL,
    check_in_time TIMESTAMP,
    check_out_time TIMESTAMP,
    payment_amount DECIMAL(10,2),
    payment_status VARCHAR(50) NOT NULL DEFAULT 'pending',
    FOREIGN KEY (show_id) REFERENCES SHOWS(show_id),
    FOREIGN KEY (crew_id) REFERENCES CREW(crew_id)

-- Ensure same crew member not assigned to same show twice
    CONSTRAINT unique_show_crew 
        UNIQUE (show_id, crew_id)
);


-- ============================================================
-- CONTRACTS & FINANCE MODULE 
-- ============================================================

CREATE TABLE IF NOT EXISTS promoter (
    promoter_id     SERIAL          PRIMARY KEY,
    company_name    VARCHAR(200)    NOT NULL,
    contact_name    VARCHAR(150)    NOT NULL,
    contact_email   VARCHAR(254)    NOT NULL,
    phone           VARCHAR(30),
    primary_market  VARCHAR(100),
    payment_terms   VARCHAR(200)
);

COMMENT ON TABLE  promoter IS 'Promotion companies that book and finance shows for artists.';
COMMENT ON COLUMN promoter.primary_market IS 'Geographic region or genre the promoter typically operates in.';
COMMENT ON COLUMN promoter.payment_terms  IS 'Default net-terms or payment arrangement (e.g. Net-30, 50/50 split).';


CREATE TABLE IF NOT EXISTS contract (
    contract_id       SERIAL          PRIMARY KEY,
    show_id           INT             NOT NULL,
    contract_type     VARCHAR(50)     NOT NULL
                          CHECK (contract_type IN ('guarantee', 'percentage', 'hybrid', 'flat_fee')),
    agreed_amount     NUMERIC(12,2)   NOT NULL DEFAULT 0,
    percentage_of_net NUMERIC(5,2)    CHECK (percentage_of_net >= 0 AND percentage_of_net <= 100),
    status            VARCHAR(30)     NOT NULL DEFAULT 'draft'
                          CHECK (status IN ('draft', 'sent', 'signed', 'cancelled', 'disputed')),
    terms             TEXT,
    signed_date       DATE
);

COMMENT ON TABLE  contract IS 'Legal agreements between the artist/manager and a promoter for a specific show.';
COMMENT ON COLUMN contract.contract_type IS 'Payment model: guarantee (fixed), percentage (of net), hybrid (guarantee + % overage), or flat_fee.';
COMMENT ON COLUMN contract.agreed_amount IS 'Guaranteed dollar amount the artist receives regardless of ticket sales.';
COMMENT ON COLUMN contract.percentage_of_net IS 'Artist share of net revenue after expenses, used in percentage/hybrid deals.';


CREATE TABLE IF NOT EXISTS expense (
    expense_id    SERIAL          PRIMARY KEY,
    show_id       INT,
    tour_id       INT,
    leg_id        INT,
    amount        NUMERIC(12,2)   NOT NULL CHECK (amount >= 0),
    expense_date  DATE            NOT NULL,
    category      VARCHAR(60)     NOT NULL
                      CHECK (category IN (
                          'venue_rental', 'production', 'catering', 'travel',
                          'lodging', 'equipment', 'insurance', 'marketing',
                          'crew', 'permits', 'miscellaneous'
                      )),
    description   TEXT,
    vendor_name   VARCHAR(200),
    receipt_no    VARCHAR(100),
    approved_by   VARCHAR(150),

    CONSTRAINT chk_expense_scope CHECK (
        (  (show_id IS NOT NULL)::INT
         + (tour_id IS NOT NULL)::INT
         + (leg_id  IS NOT NULL)::INT
        ) = 1
    )
);

COMMENT ON TABLE  expense IS 'Line-item costs incurred at the show, tour, or leg level.';
COMMENT ON COLUMN expense.show_id IS 'Set when the expense is tied to a single show (e.g. local catering).';
COMMENT ON COLUMN expense.tour_id IS 'Set for tour-wide costs not tied to a single show (e.g. bus lease, insurance).';
COMMENT ON COLUMN expense.leg_id  IS 'Set for leg-level costs (e.g. regional equipment shipping).';


CREATE TABLE IF NOT EXISTS payment (
    payment_id     SERIAL          PRIMARY KEY,
    contract_id    INT,
    expense_id     INT,
    amount         NUMERIC(12,2)   NOT NULL CHECK (amount > 0),
    payment_date   DATE            NOT NULL,
    payment_method VARCHAR(40)     NOT NULL
                       CHECK (payment_method IN ('wire', 'ach', 'check', 'credit_card', 'cash')),
    status         VARCHAR(30)     NOT NULL DEFAULT 'pending'
                       CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    payment_type   VARCHAR(40)     NOT NULL
                       CHECK (payment_type IN (
                           'deposit', 'artist_guarantee', 'artist_percentage',
                           'vendor_payment', 'reimbursement', 'settlement_payout'
                       )),

    CONSTRAINT chk_payment_parent CHECK (
        contract_id IS NOT NULL OR expense_id IS NOT NULL
    )
);

COMMENT ON TABLE  payment IS 'Individual money movements — contract payouts to artists and vendor disbursements for expenses.';
COMMENT ON COLUMN payment.contract_id IS 'Set when this payment fulfills a contractual obligation (artist guarantee, percentage split).';
COMMENT ON COLUMN payment.expense_id  IS 'Set when this payment reimburses or pays a vendor for a recorded expense.';
COMMENT ON COLUMN payment.payment_type IS 'Classifies the business reason for the payment.';


CREATE TABLE IF NOT EXISTS settlement (
    settlement_id        SERIAL          PRIMARY KEY,
    show_id              INT             NOT NULL UNIQUE,
    gross_ticket_revenue NUMERIC(14,2)   NOT NULL DEFAULT 0,
    ticket_fees          NUMERIC(12,2)   NOT NULL DEFAULT 0,
    venue_rent           NUMERIC(12,2)   NOT NULL DEFAULT 0,
    production_costs     NUMERIC(12,2)   NOT NULL DEFAULT 0,
    crew_costs           NUMERIC(12,2)   NOT NULL DEFAULT 0,
    other_expenses       NUMERIC(12,2)   NOT NULL DEFAULT 0,
    net_revenue          NUMERIC(14,2)   NOT NULL GENERATED ALWAYS AS (
                             gross_ticket_revenue
                             - ticket_fees
                             - venue_rent
                             - production_costs
                             - crew_costs
                             - other_expenses
                         ) STORED,
    artist_payment       NUMERIC(12,2)   NOT NULL DEFAULT 0,
    promoter_profit      NUMERIC(14,2)   NOT NULL GENERATED ALWAYS AS (
                             gross_ticket_revenue
                             - ticket_fees
                             - venue_rent
                             - production_costs
                             - crew_costs
                             - other_expenses
                             - artist_payment
                         ) STORED,
    settlement_date      DATE            NOT NULL,
    status               VARCHAR(30)     NOT NULL DEFAULT 'pending'
                             CHECK (status IN ('pending', 'finalized', 'disputed', 'amended'))
);

COMMENT ON TABLE  settlement IS 'Signed financial reconciliation for a completed show — one settlement per show.';
COMMENT ON COLUMN settlement.net_revenue IS 'Auto-computed: gross_ticket_revenue minus all cost line items.';
COMMENT ON COLUMN settlement.promoter_profit IS 'Auto-computed: net_revenue minus artist_payment.';