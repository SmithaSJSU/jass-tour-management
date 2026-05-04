# JASS Tour Management System
> A relational database for managing touring artists, venues, logistics, and finances.
> **Database Systems — CMPE 180B | Spring 2026**

---

## Team JASS

| Name | Module | Tables |
|------|--------|--------|
| **Jack** | Venues & Geography | `countries`, `cities`, `venues`, `routing`, `show_sequence` |
| **Anusha** | Tours & Shows | `managers`, `artists`, `tours`, `tour_legs`, `shows` |
| **Supritha** | Contracts & Finance | `promoter`, `contract`, `expense`, `payment`, `settlement` |
| **Smitha** *(Team Lead)* | Tickets & Logistics | `crew`, `transport`, `equipment`, `ticket_inventory`, `ticket_sale`, `show_crew_assignment` |

---

## Project Overview

The JASS Tour Management System is a logistics platform for touring artists to plan routes, book venues, and manage finances. It models the full lifecycle of a concert tour — from signing contracts and booking venues to selling tickets, assigning crew, and reconciling show finances.

**Key features:**
- 20 normalized tables across 4 modules
- PostgreSQL with PostGIS for geographic data
- ~48,000+ rows of realistic sample data
- Cross-module complex queries with CTEs and window functions
- ACID-compliant transaction handling
- Strategic indexing with measurable performance improvements

---

## Repository Structure

```
jass-tour-management/
│
├── README.md
├── .gitignore
│
├── docs/
│   ├── ER_Diagram.pdf               ← Finalized ERD
│   └── erd_versions/                ← Previous ERD drafts
│
├── database/
│   ├── schema/
│   │   ├── 01_create_tables.sql     ← All 20 tables (run this first)
│   │   ├── 02_constraints.sql       ← Additional constraints
│   │   └── 03_indexes.sql           ← Index creation
│   │
│   ├── data/
│   │   └── MASTER_DATA_LOAD.sql     ← Complete dataset (~48,000 rows)
│   │
│   └── setup/
│       └── reset_database.sql       ← Drop and recreate everything
│
├── queries/
│   ├── module_queries/
│   │   ├── jack_queries.sql
│   │   ├── anusha_queries.sql
│   │   ├── supritha_queries.sql
│   │   └── smitha_queries.sql
│   │
│   └── complex_queries.sql          ← 5 cross-module queries
│
├── optimization/
│   └── indexing_strategy.sql        ← Before/after EXPLAIN ANALYZE
│
├── transactions/
│   └── transaction_examples.sql     ← 8 ACID transaction demos
│
├── testing/
│   └── test_suite.sql               ← 30 tests across 5 categories
│
├── scripts/
│   └── generate_venues_data.py      ← Jack's data generator (Faker)
│
└── presentation/
    └── JASS_Presentation.pptx
```

---

## Setup Instructions

### Prerequisites
- PostgreSQL 14+
- pgAdmin 4
- PostGIS extension
- Python 3.8+ with Faker library (`pip install faker`)

### Step 1 — Create the database
```sql
CREATE DATABASE jass_tour_management;
```

### Step 2 — Enable PostGIS
```sql
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

### Step 3 — Create all tables
Open `database/schema/01_create_tables.sql` in pgAdmin and run it.
This creates all 20 tables in dependency order.

### Step 4 — Load sample data
Open `database/data/MASTER_DATA_LOAD.sql` in pgAdmin and run it.

### Step 5 — Verify
```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
-- Should return 20 tables
```

---

## Database Schema

### Entity Relationship Diagram
See [`docs/ER_Diagram.pdf`](docs/ER_Diagram.pdf)

### Table Summary

| Module | Table | Description |
|--------|-------|-------------|
| Geography | `countries` | Country reference data |
| Geography | `cities` | Cities with country FK |
| Geography | `venues` | Concert venues with PostGIS coordinates |
| Geography | `routing` | Venue-to-venue distance and travel time |
| Geography | `show_sequence` | Ordered sequence of shows within a tour |
| Tours | `managers` | Artist managers |
| Tours | `artists` | Performing artists |
| Tours | `tours` | Tour campaigns per artist |
| Tours | `tour_legs` | Regional segments of a tour |
| Tours | `shows` | Individual performances |
| Finance | `promoter` | Promotion companies |
| Finance | `contract` | Show contracts with agreed amounts |
| Finance | `expense` | Line-item costs at show/tour/leg level |
| Finance | `payment` | Money movements against contracts/expenses |
| Finance | `settlement` | Final financial reconciliation per show |
| Logistics | `crew` | Technical and production crew members |
| Logistics | `transport` | Vehicles assigned to tours |
| Logistics | `equipment` | Gear and equipment per tour |
| Logistics | `ticket_inventory` | Ticket types and quantities per show |
| Logistics | `ticket_sale` | Individual ticket purchase records |
| Logistics | `show_crew_assignment` | Crew assigned to specific shows |

---

## Data Volume

| Module | Tables | Approximate Rows |
|--------|--------|-----------------|
| Jack — Venues & Geography | 5 | ~870 |
| Anusha — Tours & Shows | 5 | ~610 |
| Supritha — Contracts & Finance | 5 | ~4,030 |
| Smitha — Tickets & Logistics | 6 | ~46,730 |
| **Total** | **20** | **~48,240** |

---

## Queries

### Module Queries
Each team member wrote queries demonstrating their module:
- `queries/module_queries/jack_queries.sql` — Geographic analysis, venue routing
- `queries/module_queries/anusha_queries.sql` — Tour analytics, artist performance
- `queries/module_queries/supritha_queries.sql` — Financial reporting, settlement tracking
- `queries/module_queries/smitha_queries.sql` — Ticket sales, crew utilization, logistics

### Cross-Module Complex Queries (`queries/complex_queries.sql`)
| # | Query | Techniques Used |
|---|-------|-----------------|
| 1 | Complete Show Profitability Analysis | Multiple CTEs, window functions, RANK() |
| 2 | Tour Route Optimization | Self-joins, sequential analysis |
| 3 | Artist Performance Dashboard | Complex aggregations, correlated subqueries |
| 4 | Venue Performance & Country Analysis | Window functions, PARTITION BY |
| 5 | Payment Settlement Status Report | Financial reconciliation, CASE logic |

---

## Performance Optimization

See `optimization/indexing_strategy.sql` for full details.

**Strategy:** 32 strategic indexes across 4 categories:
- **Foreign key indexes** — support JOIN operations on all heavily-used FK columns
- **Composite indexes** — multi-column indexes for common filter patterns
- **Covering indexes** — include SELECT columns to avoid table lookups
- **Partial indexes** — index only relevant subsets (e.g. pending payments, future shows)

Run `EXPLAIN ANALYZE` before and after creating indexes to measure improvement.

---

## Transactions & ACID Compliance

See `transactions/transaction_examples.sql` for 8 complete demos.

| Transaction | ACID Property | Scenario |
|-------------|--------------|----------|
| 1 | Atomicity | Ticket purchase — all steps or none |
| 2 | Atomicity | Payment failure rollback |
| 3 | Consistency | Bulk crew payment update |
| 4 | Atomicity | Show cancellation across 3 tables |
| 5 | Consistency | Contract payment with balance check |
| 6 | Isolation | Concurrent ticket sales with FOR UPDATE |
| 7 | Atomicity | Savepoints for partial crew payment batch |
| 8 | Durability | Settlement creation and commit |

---

## Test Suite

See `testing/test_suite.sql` for 30 tests across 5 categories.

| Category | Tests | What It Checks |
|----------|-------|---------------|
| Row Count Checks | 2 | All 20 tables have data |
| Data Integrity | 13 | FK orphans, duplicates, invalid status values |
| Business Logic | 7 | Tour structure, venue capacity, expense scope |
| Query Correctness | 5 | Revenue math, settlement accuracy, overselling |
| Edge Cases | 3 | NULL handling, LEFT JOIN completeness |

---

## Tech Stack

| Tool | Purpose |
|------|---------|
| PostgreSQL 14+ | Primary database |
| PostGIS | Geographic coordinate storage and queries |
| pgAdmin 4 | Query execution and database management |
| Python + Faker | Realistic sample data generation |
| GitHub | Version control and collaboration |

---

## Key Files Quick Reference

| File | Purpose | Run Order |
|------|---------|-----------|
| `database/schema/01_create_tables.sql` | Create all 20 tables | 1st |
| `database/data/MASTER_DATA_LOAD.sql` | Load ~48K rows of data | 2nd |
| `optimization/indexing_strategy.sql` | Create 32 performance indexes | 3rd |
| `queries/complex_queries.sql` | 5 cross-module business queries | After data load |
| `transactions/transaction_examples.sql` | ACID demos | After data load |
| `testing/test_suite.sql` | 30 validation tests | After data load |

---

## Running the Project

```sql
-- Quick health check after setup
SELECT
    'countries'             AS tbl, COUNT(*) FROM countries UNION ALL
    SELECT 'cities',                COUNT(*) FROM cities UNION ALL
    SELECT 'venues',                COUNT(*) FROM venues UNION ALL
    SELECT 'shows',                 COUNT(*) FROM shows UNION ALL
    SELECT 'ticket_inventory',      COUNT(*) FROM ticket_inventory UNION ALL
    SELECT 'ticket_sale',           COUNT(*) FROM ticket_sale UNION ALL
    SELECT 'crew',                  COUNT(*) FROM crew UNION ALL
    SELECT 'contract',              COUNT(*) FROM contract UNION ALL
    SELECT 'settlement',            COUNT(*) FROM settlement
ORDER BY tbl;
```


