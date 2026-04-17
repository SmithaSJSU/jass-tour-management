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
    indoor_outdoor VARCHAR(10) NOT NULL
        CHECK (UPPER(indoor_outdoor) IN ('INDOOR', 'OUTDOOR', 'BOTH')),
    primary key(venue_id),
    foreign key(city_id) references cities(city_id)
    );

create table routing
    (routing_id                    BIGSERIAL,
    distance                    Int NOT NULL CHECK (distance > 0),
    estimated_travel_time        Int NOT NULL CHECK (estimated_travel_time > 0),
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