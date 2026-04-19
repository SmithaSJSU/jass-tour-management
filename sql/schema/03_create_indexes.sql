-- ============================================
-- JASS Tour Management System
-- File: 03_create_indexes.sql
-- Purpose: Create indexes for query performance
-- Based on: Final ERD diagram
-- ============================================

-- ============================================
-- FOREIGN KEY INDEXES 
-- ============================================
-- PostgreSQL does NOT automatically create indexes on foreign keys
-- These are essential for join performance
 
-- TRANSPORT foreign key
CREATE INDEX idx_transport_tour 
ON TRANSPORT(tour_id);
 
-- EQUIPMENT foreign keys
CREATE INDEX idx_equipment_tour 
ON EQUIPMENT(tour_id);
 
CREATE INDEX idx_equipment_transport 
ON EQUIPMENT(transport_id);
 
-- TICKET_INVENTORY foreign key
CREATE INDEX idx_ticket_inventory_show 
ON TICKET_INVENTORY(show_id);
 
-- TICKET_SALE foreign key
CREATE INDEX idx_ticket_sale_inventory 
ON TICKET_SALE(inventory_id);
 
-- SHOW_CREW_ASSIGNMENT foreign keys
CREATE INDEX idx_show_crew_assignment_show 
ON SHOW_CREW_ASSIGNMENT(show_id);
 
CREATE INDEX idx_show_crew_assignment_crew 
ON SHOW_CREW_ASSIGNMENT(crew_id);

-- ARTISTS
CREATE INDEX idx_artists_manager_id ON ARTISTS(manager_id);

-- TOURS
CREATE INDEX idx_tours_artist_id ON TOURS(artist_id);

-- TOUR_LEGS
CREATE INDEX idx_tour_legs_tour_id ON TOUR_LEGS(tour_id);

-- SHOWS
CREATE INDEX idx_shows_leg_id ON SHOWS(leg_id);
CREATE INDEX idx_shows_venue_id ON SHOWS(venue_id);
CREATE INDEX idx_shows_promoter_id ON SHOWS(promoter_id);
 
 
-- ============================================
-- SEARCH COLUMN INDEXES
-- ============================================
-- Indexes on columns frequently used in WHERE clauses
 
-- Transport filtered by vehicle type
CREATE INDEX idx_transport_vehicle_type 
ON TRANSPORT(vehicle_type);
 
-- Equipment filtered by type
CREATE INDEX idx_equipment_type 
ON EQUIPMENT(equipment_type);
 
-- Ticket inventory filtered by ticket type
CREATE INDEX idx_ticket_inventory_type 
ON TICKET_INVENTORY(ticket_type);
 
-- Ticket inventory filtered by section
CREATE INDEX idx_ticket_inventory_section 
ON TICKET_INVENTORY(section_name);
 
-- Ticket sales analyzed by timestamp (for reports)
CREATE INDEX idx_ticket_sale_timestamp 
ON TICKET_SALE(sale_timestamp);
 
-- Ticket sales filtered by channel
CREATE INDEX idx_ticket_sale_channel 
ON TICKET_SALE(sale_channel);
 
-- Crew filtered by role (common query)
CREATE INDEX idx_crew_role 
ON CREW(role);
 
-- Show crew assignments filtered by payment status
CREATE INDEX idx_show_crew_payment_status 
ON SHOW_CREW_ASSIGNMENT(payment_status);

-- SHOWS
CREATE INDEX idx_shows_show_date ON SHOWS(show_date);
CREATE INDEX idx_shows_status ON SHOWS(status);
 
 
-- ============================================
-- COMPOSITE INDEXES (Multi-Column)
-- ============================================
-- Indexes for queries that filter by multiple columns together
 
-- Ticket inventory searched by show and section together
-- (Common query: "Get all VIP tickets for show X")
CREATE INDEX idx_ticket_inventory_show_section 
ON TICKET_INVENTORY(show_id, section_name);
 
-- Ticket inventory searched by show and type together
-- (Common query: "Get all General tickets for show X")
CREATE INDEX idx_ticket_inventory_show_type 
ON TICKET_INVENTORY(show_id, ticket_type);
 
-- Ticket sales by inventory and timestamp (for sales reports)
-- (Common query: "Show sales over time for this ticket type")
CREATE INDEX idx_ticket_sale_inventory_timestamp 
ON TICKET_SALE(inventory_id, sale_timestamp);
 
-- Show crew assignments by show and payment status (for payroll)
-- (Common query: "Which crew members are unpaid for show X?")
CREATE INDEX idx_show_crew_show_payment 
ON SHOW_CREW_ASSIGNMENT(show_id, payment_status);
 
-- Equipment by tour and transport (for loading management)
-- (Common query: "What equipment is on truck #5 for tour X?")
CREATE INDEX idx_equipment_tour_transport 
ON EQUIPMENT(tour_id, transport_id);

-- Shows often queried by tour AND date together
CREATE INDEX idx_shows_tour_date ON shows(tour_id, show_date);
 
 
-- ============================================
-- PARTIAL INDEXES (Advanced - Optional)
-- ============================================
-- Indexes that only cover certain rows (saves space and improves speed)
 
-- Index only unpaid crew assignments (very common query)
CREATE INDEX idx_show_crew_unpaid 
ON SHOW_CREW_ASSIGNMENT(show_id, crew_id) 
WHERE payment_status = 'pending';
 
-- Index only equipment requiring climate control (common query)
CREATE INDEX idx_equipment_climate_control 
ON EQUIPMENT(tour_id, transport_id) 
WHERE requires_climate_control = TRUE;
 
-- Index only available tickets (total > hold)
-- (Common query: tickets available for purchase)
CREATE INDEX idx_ticket_inventory_available 
ON TICKET_INVENTORY(show_id, section_name) 
WHERE total_quantity > hold_quantity;

-- Index only active shows (not completed/cancelled)
CREATE INDEX idx_shows_active 
ON shows(show_date) 
WHERE status IN ('scheduled', 'postponed');

 
-- ============================================
-- TEXT SEARCH INDEXES (Optional)
-- ============================================
-- For case-insensitive name searches
 
-- Search crew by name (case-insensitive)
CREATE INDEX idx_crew_name_lower 
ON CREW(LOWER(person_name));
 
-- Search equipment by description (case-insensitive)
CREATE INDEX idx_equipment_description_lower 
ON EQUIPMENT(LOWER(item_description));

-- Search artists by name (case-insensitive)
CREATE INDEX idx_artists_name_lower 
ON artists(LOWER(name));

-- ============================================
-- Range INDEXES (support date range queries)
-- ============================================

-- TOURS
CREATE INDEX idx_tours_dates ON TOURS(start_date, end_date);
-- TOUR_LEGS
CREATE INDEX idx_tour_legs_dates ON TOUR_LEGS(start_date, end_date);
 
 
-- ============================================
-- ANALYZE TABLES
-- ============================================
-- Update statistics for query planner
-- This helps PostgreSQL choose the best execution plan
 
ANALYZE TRANSPORT;
ANALYZE EQUIPMENT;
ANALYZE TICKET_INVENTORY;
ANALYZE TICKET_SALE;
ANALYZE CREW;
ANALYZE SHOW_CREW_ASSIGNMENT;
ANALYZE MANAGERS;
ANALYZE ARTISTS;
ANALYZE TOURS;
ANALYZE TOUR_LEGS;
ANALYZE SHOWS;
 
