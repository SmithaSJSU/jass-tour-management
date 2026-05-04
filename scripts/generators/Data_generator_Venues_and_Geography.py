"""
============================================
JASS Tour Management System
Data Generator — Venues & Geography Module (Jack)
============================================
Generates SQL INSERT statements for:
  - COUNTRIES  (20 rows)
  - CITIES     (50 rows)
  - VENUES     (100 rows)
  - ROUTING    (200 rows)
  - SHOW_SEQUENCE (generated after shows exist — see note at bottom)

Schema reference (from 01_create_tables.sql):
  countries   : country_id, name
  cities      : city_id, name, country_id
  venues      : venue_id, name, city_id, capacity, contact_info, coordinates (POINT), indoor_outdoor
  routing     : routing_id, distance, estimated_travel_time, from_venue_id, to_venue_id
  show_sequence: sequence_id, sequence_number, dist_from_previous_show, drive_time,
                 rest_days, tour_id, show_id

Usage:
  pip install faker
  python generate_venues_data.py > venues_data.sql

NOTE: Run this BEFORE Anusha's data (tours/shows depend on venues/cities).
      The show_sequence section must be run AFTER Anusha populates shows.
============================================
"""

# Auto-install faker if needed
try:
    from faker import Faker
except ImportError:
    import subprocess, sys
    subprocess.check_call([sys.executable, "-m", "pip", "install", "faker"])
    from faker import Faker

import random
from datetime import datetime

fake = Faker()
random.seed(42)  # Reproducible data

# ── Config ────────────────────────────────────────────────
NUM_COUNTRIES       = 20
NUM_CITIES          = 50   # spread across countries
NUM_VENUES          = 100  # spread across cities
NUM_ROUTING_PAIRS   = 200  # venue-to-venue routing records
NUM_SHOW_SEQUENCE   = 500  # one per show (run after shows are populated)
# ──────────────────────────────────────────────────────────

# ── Real-world data pools ──────────────────────────────────
COUNTRIES = [
    "United States", "United Kingdom", "Canada", "Australia", "Germany",
    "France", "Japan", "Netherlands", "Sweden", "Brazil",
    "Mexico", "Spain", "Italy", "Argentina", "South Korea",
    "New Zealand", "Belgium", "Denmark", "Norway", "Ireland"
]

# city name, country name, approx lat, approx lng
CITIES_DATA = [
    ("New York",        "United States",  40.7128,  -74.0060),
    ("Los Angeles",     "United States",  34.0522, -118.2437),
    ("Chicago",         "United States",  41.8781,  -87.6298),
    ("Houston",         "United States",  29.7604,  -95.3698),
    ("Nashville",       "United States",  36.1627,  -86.7816),
    ("Austin",          "United States",  30.2672,  -97.7431),
    ("Seattle",         "United States",  47.6062, -122.3321),
    ("Miami",           "United States",  25.7617,  -80.1918),
    ("Denver",          "United States",  39.7392, -104.9903),
    ("Atlanta",         "United States",  33.7490,  -84.3880),
    ("London",          "United Kingdom", 51.5074,   -0.1278),
    ("Manchester",      "United Kingdom", 53.4808,   -2.2426),
    ("Glasgow",         "United Kingdom", 55.8642,   -4.2518),
    ("Birmingham",      "United Kingdom", 52.4862,   -1.8904),
    ("Toronto",         "Canada",         43.6532,  -79.3832),
    ("Vancouver",       "Canada",         49.2827, -123.1207),
    ("Montreal",        "Canada",         45.5017,  -73.5673),
    ("Sydney",          "Australia",     -33.8688,  151.2093),
    ("Melbourne",       "Australia",     -37.8136,  144.9631),
    ("Brisbane",        "Australia",     -27.4698,  153.0251),
    ("Berlin",          "Germany",        52.5200,   13.4050),
    ("Munich",          "Germany",        48.1351,   11.5820),
    ("Hamburg",         "Germany",        53.5511,    9.9937),
    ("Paris",           "France",         48.8566,    2.3522),
    ("Lyon",            "France",         45.7640,    4.8357),
    ("Tokyo",           "Japan",          35.6762,  139.6503),
    ("Osaka",           "Japan",          34.6937,  135.5023),
    ("Amsterdam",       "Netherlands",    52.3676,    4.9041),
    ("Stockholm",       "Sweden",         59.3293,   18.0686),
    ("Gothenburg",      "Sweden",         57.7089,   11.9746),
    ("Sao Paulo",       "Brazil",        -23.5505,  -46.6333),
    ("Rio de Janeiro",  "Brazil",        -22.9068,  -43.1729),
    ("Mexico City",     "Mexico",         19.4326,  -99.1332),
    ("Guadalajara",     "Mexico",         20.6597, -103.3496),
    ("Madrid",          "Spain",          40.4168,   -3.7038),
    ("Barcelona",       "Spain",          41.3851,    2.1734),
    ("Rome",            "Italy",          41.9028,   12.4964),
    ("Milan",           "Italy",          45.4654,    9.1859),
    ("Buenos Aires",    "Argentina",     -34.6037,  -58.3816),
    ("Seoul",           "South Korea",    37.5665,  126.9780),
    ("Auckland",        "New Zealand",   -36.8485,  174.7633),
    ("Brussels",        "Belgium",        50.8503,    4.3517),
    ("Copenhagen",      "Denmark",        55.6761,   12.5683),
    ("Oslo",            "Norway",         59.9139,   10.7522),
    ("Dublin",          "Ireland",        53.3498,   -6.2603),
    ("Phoenix",         "United States",  33.4484, -112.0740),
    ("Portland",        "United States",  45.5051, -122.6750),
    ("Minneapolis",     "United States",  44.9778,  -93.2650),
    ("Boston",          "United States",  42.3601,  -71.0589),
    ("Las Vegas",       "United States",  36.1699, -115.1398),
]

VENUE_NAMES = [
    "Arena", "Amphitheater", "Music Hall", "Civic Center", "Convention Center",
    "Stadium", "Theater", "Pavilion", "Forum", "Coliseum",
    "Auditorium", "Center", "Ballroom", "Garden", "Palace",
    "Club", "Venue", "Hall", "Park", "Bowl"
]

VENUE_PREFIXES = [
    "The", "Grand", "Royal", "City", "National", "Metro",
    "Golden", "Silver", "Blue", "Red", "United", "Central",
    "Northern", "Southern", "Eastern", "Western", "Premier"
]

INDOOR_OUTDOOR = ["indoor", "outdoor"]

# ── Helpers ───────────────────────────────────────────────
def esc(s):
    """Escape single quotes for SQL."""
    return str(s).replace("'", "''")

def haversine_km(lat1, lon1, lat2, lon2):
    """Approximate distance in km between two lat/lon points."""
    import math
    R = 6371
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat/2)**2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2)
    return round(R * 2 * math.asin(math.sqrt(a)))

def header(title):
    print(f"\n-- {'='*50}")
    print(f"-- {title}")
    print(f"-- {'='*50}")

# ── Main generation ───────────────────────────────────────
print("-- ============================================")
print("-- JASS Tour Management — Venues & Geography Data")
print(f"-- Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
print("-- Module Owner: Jack")
print("-- Run ORDER: 1st (no dependencies)")
print("-- ============================================\n")

print("BEGIN;")

# ─────────────────────────────────────────────
# 1. COUNTRIES
# ─────────────────────────────────────────────
header("1. COUNTRIES")
print(f"-- Inserting {NUM_COUNTRIES} countries\n")
print("INSERT INTO countries (name) VALUES")

country_rows = []
for country in COUNTRIES[:NUM_COUNTRIES]:
    country_rows.append(f"    ('{esc(country)}')")

print(",\n".join(country_rows) + ";")

# ─────────────────────────────────────────────
# 2. CITIES
# ─────────────────────────────────────────────
header("2. CITIES")
print(f"-- Inserting {NUM_CITIES} cities\n")
print("INSERT INTO cities (name, country_id) VALUES")

city_rows = []
# Use subquery to look up country_id by name — no hardcoded IDs
for city_name, country_name, lat, lng in CITIES_DATA[:NUM_CITIES]:
    city_rows.append(
        f"    ('{esc(city_name)}', "
        f"(SELECT country_id FROM countries WHERE name = '{esc(country_name)}' LIMIT 1))"
    )

print(",\n".join(city_rows) + ";")

# ─────────────────────────────────────────────
# 3. VENUES
# ─────────────────────────────────────────────
header("3. VENUES")
print(f"-- Inserting {NUM_VENUES} venues")
print("-- coordinates stored as PostgreSQL POINT(lng, lat)\n")

venue_list = []  # track for routing
venue_rows = []

for i in range(NUM_VENUES):
    city_name, country_name, city_lat, city_lng = random.choice(CITIES_DATA[:NUM_CITIES])

    # Venue name
    prefix = random.choice(VENUE_PREFIXES)
    suffix = random.choice(VENUE_NAMES)
    name = f"{prefix} {city_name} {suffix}"

    # Capacity varies by venue type
    if suffix in ["Stadium", "Coliseum", "Bowl"]:
        capacity = random.randint(30000, 80000)
    elif suffix in ["Arena", "Amphitheater", "Forum"]:
        capacity = random.randint(10000, 30000)
    elif suffix in ["Civic Center", "Convention Center", "Pavilion"]:
        capacity = random.randint(5000, 15000)
    else:
        capacity = random.randint(500, 5000)

    # Slight coordinate jitter within city
    lat  = round(city_lat  + random.uniform(-0.05, 0.05), 6)
    lng  = round(city_lng  + random.uniform(-0.05, 0.05), 6)

    contact = fake.phone_number()[:30]
    indoor_outdoor = random.choice(INDOOR_OUTDOOR)

    venue_list.append((name, city_name, lat, lng, capacity))

    venue_rows.append(
        f"    ('{esc(name)}', "
        f"(SELECT city_id FROM cities WHERE name = '{esc(city_name)}' LIMIT 1), "
        f"{capacity}, "
        f"'{esc(contact)}', "
        f"POINT({lng}, {lat}), "
        f"'{indoor_outdoor}')"
    )

print("INSERT INTO venues (name, city_id, capacity, contact_info, coordinates, indoor_outdoor) VALUES")
print(",\n".join(venue_rows) + ";")

# ─────────────────────────────────────────────
# 4. ROUTING
# ─────────────────────────────────────────────
header("4. ROUTING")
print(f"-- Inserting {NUM_ROUTING_PAIRS} venue-to-venue routing records")
print("-- distance in km, estimated_travel_time in hours\n")

# Build a city lat/lng lookup
city_coords = {c[0]: (c[2], c[3]) for c in CITIES_DATA}

routing_rows = []
used_pairs = set()

attempts = 0
while len(routing_rows) < NUM_ROUTING_PAIRS and attempts < 2000:
    attempts += 1
    v1 = random.choice(venue_list)
    v2 = random.choice(venue_list)

    if v1[0] == v2[0]:
        continue

    pair = tuple(sorted([v1[0], v2[0]]))
    if pair in used_pairs:
        continue
    used_pairs.add(pair)

    lat1, lng1 = v1[2], v1[3]
    lat2, lng2 = v2[2], v2[3]

    dist_km = haversine_km(lat1, lng1, lat2, lng2)
    if dist_km == 0:
        dist_km = random.randint(50, 200)

    # Estimate travel time: ~80 km/h average including stops
    travel_hours = round(dist_km / 80 + random.uniform(0.5, 2.0))
    travel_hours = max(1, travel_hours)

    routing_rows.append(
        f"    ({dist_km}, {travel_hours}, "
        f"(SELECT venue_id FROM venues WHERE name = '{esc(v1[0])}' LIMIT 1), "
        f"(SELECT venue_id FROM venues WHERE name = '{esc(v2[0])}' LIMIT 1))"
    )

print("INSERT INTO routing (distance, estimated_travel_time, from_venue_id, to_venue_id) VALUES")
print(",\n".join(routing_rows) + ";")

# ─────────────────────────────────────────────
# 5. SHOW_SEQUENCE
# ─────────────────────────────────────────────
header("5. SHOW_SEQUENCE")
print("-- !! IMPORTANT: Run this section AFTER Anusha has populated the shows table !!")
print("-- Assigns a sequence number to each show within its tour.\n")
print("""
-- This query auto-generates show_sequence rows for every show,
-- ordered by show_date within each tour.
INSERT INTO show_sequence (sequence_number, dist_from_previous_show, drive_time, rest_days, tour_id, show_id)
SELECT
    ROW_NUMBER() OVER (PARTITION BY tl.tour_id ORDER BY s.show_date)  AS sequence_number,
    -- Distance from previous show (0 for first show in tour)
    COALESCE(
        (SELECT r.distance
         FROM routing r
         JOIN shows prev_s ON prev_s.show_id = LAG(s.show_id) OVER (
             PARTITION BY tl.tour_id ORDER BY s.show_date
         )
         WHERE r.from_venue_id = prev_s.venue_id
           AND r.to_venue_id   = s.venue_id
         LIMIT 1),
        0
    )                                                                   AS dist_from_previous_show,
    -- Drive time estimate: distance / 80 km/h, minimum 1 hour
    GREATEST(1, COALESCE(
        (SELECT r.estimated_travel_time
         FROM routing r
         JOIN shows prev_s ON prev_s.show_id = LAG(s.show_id) OVER (
             PARTITION BY tl.tour_id ORDER BY s.show_date
         )
         WHERE r.from_venue_id = prev_s.venue_id
           AND r.to_venue_id   = s.venue_id
         LIMIT 1),
        1
    ))                                                                  AS drive_time,
    -- Rest days between shows
    GREATEST(0,
        COALESCE(
            s.show_date - LAG(s.show_date) OVER (
                PARTITION BY tl.tour_id ORDER BY s.show_date
            ) - 1,
            0
        )
    )                                                                   AS rest_days,
    tl.tour_id,
    s.show_id
FROM shows s
JOIN tour_legs tl ON s.leg_id = tl.leg_id
ORDER BY tl.tour_id, s.show_date;
""")

print("\nCOMMIT;")
print("\n-- ============================================")
print("-- DONE! Venues & Geography data loaded.")
print("-- Row counts to verify:")
print("--   SELECT COUNT(*) FROM countries;      -- expect ~20")
print("--   SELECT COUNT(*) FROM cities;         -- expect ~50")
print("--   SELECT COUNT(*) FROM venues;         -- expect ~100")
print("--   SELECT COUNT(*) FROM routing;        -- expect ~200")
print("--   SELECT COUNT(*) FROM show_sequence;  -- run after shows are loaded")
print("-- ============================================")