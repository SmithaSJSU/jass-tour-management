-- ============================================
-- JASS Tour Management System
-- File: 02_add_constraints.sql
-- Purpose: Add business rule constraints
-- Based on: Final ERD diagram
-- ============================================
 
-- ============================================
-- CHECK CONSTRAINTS - TRANSPORT
-- ============================================
 
-- People capacity must be positive
ALTER TABLE TRANSPORT
ADD CONSTRAINT chk_transport_capacity_people_positive 
CHECK (capacity_people > 0);
 
-- Weight capacity must be positive
ALTER TABLE TRANSPORT
ADD CONSTRAINT chk_transport_capacity_weight_positive 
CHECK (capacity_weight_lbs > 0);
 
-- Vehicle type must be valid
ALTER TABLE TRANSPORT
ADD CONSTRAINT chk_transport_vehicle_type_valid 
CHECK (vehicle_type IN ('tour_bus', 'cargo_truck', 'van', 'trailer', 'sprinter', 'rv'));
 
 
-- ============================================
-- CHECK CONSTRAINTS - EQUIPMENT
-- ============================================
 
-- Quantity must be positive
ALTER TABLE EQUIPMENT
ADD CONSTRAINT chk_equipment_quantity_positive 
CHECK (quantity > 0);
 
-- Weight must be non-negative (if provided)
ALTER TABLE EQUIPMENT
ADD CONSTRAINT chk_equipment_weight_non_negative 
CHECK (weight_lbs IS NULL OR weight_lbs >= 0);
 
-- Value must be non-negative (if provided)
ALTER TABLE EQUIPMENT
ADD CONSTRAINT chk_equipment_value_non_negative 
CHECK (value_usd IS NULL OR value_usd >= 0);
 
-- Equipment type must be valid
ALTER TABLE EQUIPMENT
ADD CONSTRAINT chk_equipment_type_valid 
CHECK (equipment_type IN (
    'instrument', 'guitar', 'bass', 'drums', 'keyboard', 'amplifier',
    'sound_system', 'speakers', 'mixer', 'microphone',
    'lighting', 'led_screen', 'video_equipment',
    'stage_piece', 'backdrop', 'riser', 'barricade',
    'cables', 'cases', 'racks', 'other'
));
 
 
-- ============================================
-- CHECK CONSTRAINTS - TICKET_INVENTORY
-- ============================================
 
-- Total quantity must be positive
ALTER TABLE TICKET_INVENTORY 
ADD CONSTRAINT chk_ticket_total_quantity_positive 
CHECK (total_quantity > 0);
 
-- Hold quantity must be non-negative and within total
ALTER TABLE TICKET_INVENTORY 
ADD CONSTRAINT chk_ticket_hold_within_total 
CHECK (hold_quantity >= 0 AND hold_quantity <= total_quantity);
 
-- Base price must be non-negative
ALTER TABLE TICKET_INVENTORY 
ADD CONSTRAINT chk_ticket_base_price_non_negative 
CHECK (base_price >= 0);
 
-- Service fees must be non-negative
ALTER TABLE TICKET_INVENTORY 
ADD CONSTRAINT chk_ticket_service_fees_non_negative 
CHECK (service_fees >= 0);
 
-- Ticket type must be valid
ALTER TABLE TICKET_INVENTORY
ADD CONSTRAINT chk_ticket_type_valid
CHECK (ticket_type IN ('General', 'VIP', 'Premium', 'Early Bird', 'Student', 'Senior'));
 
 
-- ============================================
-- CHECK CONSTRAINTS - TICKET_SALE
-- ============================================
 
-- Quantity sold must be positive
ALTER TABLE TICKET_SALE 
ADD CONSTRAINT chk_ticket_sale_quantity_positive 
CHECK (quantity_sold > 0);
 
-- Total amount must be non-negative
ALTER TABLE TICKET_SALE 
ADD CONSTRAINT chk_ticket_sale_amount_non_negative 
CHECK (total_amount >= 0);
 
-- Sale channel must be valid
ALTER TABLE TICKET_SALE 
ADD CONSTRAINT chk_ticket_sale_channel_valid 
CHECK (sale_channel IN ('online', 'box_office', 'phone', 'mobile_app', 'third_party'));
 
 
-- ============================================
-- CHECK CONSTRAINTS - CREW
-- ============================================
 
-- Daily rate must be non-negative
ALTER TABLE CREW
ADD CONSTRAINT chk_crew_daily_rate_non_negative 
CHECK (daily_rate >= 0);
 
-- Per diem amount must be non-negative
ALTER TABLE CREW
ADD CONSTRAINT chk_crew_per_diem_non_negative 
CHECK (per_diem_amount >= 0);
 
-- Role must be valid
ALTER TABLE CREW
ADD CONSTRAINT chk_crew_role_valid 
CHECK (role IN (
    'sound_engineer', 'lighting_tech', 'stage_manager', 'rigger',
    'video_tech', 'monitor_engineer', 'foh_engineer', 'backline_tech',
    'production_manager', 'tour_manager', 'merchandise_manager',
    'security', 'driver', 'general_labor'
));
 
 
-- ============================================
-- CHECK CONSTRAINTS - SHOW_CREW_ASSIGNMENT
-- ============================================
 
-- Payment amount must be non-negative (if provided)
ALTER TABLE SHOW_CREW_ASSIGNMENT
ADD CONSTRAINT chk_show_crew_payment_non_negative 
CHECK (payment_amount IS NULL OR payment_amount >= 0);
 
-- Payment status must be valid
ALTER TABLE SHOW_CREW_ASSIGNMENT
ADD CONSTRAINT chk_show_crew_payment_status_valid 
CHECK (payment_status IN ('pending', 'paid', 'cancelled'));
 
-- Check-out time must be after check-in time (if both provided)
ALTER TABLE SHOW_CREW_ASSIGNMENT
ADD CONSTRAINT chk_show_crew_times_logical
CHECK (
    check_out_time IS NULL OR 
    check_in_time IS NULL OR 
    check_out_time >= check_in_time
);

-- ============================================
-- CHECK CONSTRAINTS - venues
-- ============================================

-- Capacity is greater than 0
ALTER TABLE venues
ADD CONSTRAINT chk_cap_non_negative
CHECK (capacity > 0);

-- Indoor/outdoor type must be valid
ALTER TABLE venues
ADD CONSTRAINT chk_indoor_outdoor
CHECK (UPPER(indoor_outdoor) IN ('INDOOR', 'OUTDOOR', 'BOTH'));

-- ============================================
-- CHECK CONSTRAINTS - routing
-- ============================================

-- Distance is non-negative
ALTER TABLE routing
ADD CONSTRAINT chk_distance
CHECK (distance >= 0);

-- Travel time is non-negative
ALTER TABLE routing
ADD CONSTRAINT chk_travel_time
CHECK (estimated_travel_time >= 0);
 
-- ============================================
-- UNIQUE CONSTRAINTS
-- ============================================
 
-- Ticket inventory: unique per show + section + type
-- (Ensures no duplicate inventory entries for same show/section/type combination)
ALTER TABLE TICKET_INVENTORY
ADD CONSTRAINT unique_ticket_show_section_type 
UNIQUE (show_id, section_name, ticket_type);
 
-- Show crew assignment: unique per show + crew
-- (Already defined in CREATE TABLE, but documented here for clarity)
-- UNIQUE (show_id, crew_id) prevents same crew member assigned to same show twice
 
 
-- ============================================
-- DEFAULT VALUES
-- ============================================
 
-- Ticket sale defaults
ALTER TABLE TICKET_SALE
ALTER COLUMN sale_channel SET DEFAULT 'online',
ALTER COLUMN sale_timestamp SET DEFAULT CURRENT_TIMESTAMP;
 
-- Crew defaults
ALTER TABLE CREW
ALTER COLUMN per_diem_amount SET DEFAULT 0.00;
 
-- Show crew assignment defaults
ALTER TABLE SHOW_CREW_ASSIGNMENT
ALTER COLUMN payment_status SET DEFAULT 'pending';
 
-- Equipment defaults
ALTER TABLE EQUIPMENT
ALTER COLUMN quantity SET DEFAULT 1,
ALTER COLUMN requires_climate_control SET DEFAULT FALSE;
 
-- Ticket inventory defaults
ALTER TABLE TICKET_INVENTORY
ALTER COLUMN service_fees SET DEFAULT 0.00,
ALTER COLUMN hold_quantity SET DEFAULT 0;
 
 
