"""
Sample Data Generator — Shows & Tours Schema
Requires: pip install faker
Usage:    python generate_sample_data.py > sample_data.sql
"""

from faker import Faker
import random
from datetime import timedelta, date

fake = Faker()
random.seed(42)
Faker.seed(42)

# ── Config ────────────────────────────────────────────────
NUM_MANAGERS   = 20
NUM_ARTISTS    = 50
NUM_TOURS      = 20
NUM_LEGS       = 40   # spread across tours
NUM_SHOWS      = 500  # spread across legs
# ─────────────────────────────────────────────────────────

GENRES   = ["Pop", "Rock", "Hip-Hop", "Jazz", "Electronic", "R&B", "Country", "Classical", "Indie", "Metal"]
REGIONS  = ["North America", "Europe", "Asia Pacific", "Latin America", "Middle East", "Africa"]

lines = []
today      = date.today()
one_yr_ago = today - timedelta(days=365)  # same start for all tables
one_yr_fwd = today + timedelta(days=365)  # same end for all tables

def sql(s):
    lines.append(s)

def quote(v):
    if v is None:
        return "NULL"
    return "'" + str(v).replace("'", "''") + "'"

# ── MANAGERS ─────────────────────────────────────────────
sql("\n-- ============================================")
sql("-- MANAGERS")
sql("-- ============================================")
for i in range(1, NUM_MANAGERS + 1):
    name  = fake.name()
    email = fake.unique.email()
    sql(f"INSERT INTO managers (name, contact_email) VALUES ({quote(name)}, {quote(email)});")

# ── ARTISTS ──────────────────────────────────────────────
sql("\n-- ============================================")
sql("-- ARTISTS")
sql("-- ============================================")
for i in range(1, NUM_ARTISTS + 1):
    artist_name = fake.last_name() + " " + random.choice([
        "Band", "& The Artists", "Project", "Collective",
        "& Co", "Ensemble", "Group", ""
    ])
    artist_name = artist_name.strip()
    genre = random.choice(GENRES)
    sql(f"INSERT INTO artists (name, genre, manager_id) VALUES ({quote(artist_name)}, {quote(genre)}, (SELECT manager_id FROM managers ORDER BY RANDOM() LIMIT 1));")

# ── TOURS ────────────────────────────────────────────────
sql("\n-- ============================================")
sql("-- TOURS")
sql("-- ============================================")
for i in range(1, NUM_TOURS + 1):
    tour_name  = fake.city() + " " + random.choice(["World Tour", "Live Tour", "Arena Tour", "Festival Run", "Summer Tour", "Reunion Tour"])
    start_date = fake.date_between(start_date=one_yr_ago, end_date=one_yr_fwd)
    end_date   = fake.date_between(start_date=start_date + timedelta(days=1), end_date=one_yr_fwd)
    sql(f"INSERT INTO tours (artist_id, tour_name, start_date, end_date) VALUES ((SELECT artist_id FROM artists ORDER BY RANDOM() LIMIT 1), {quote(tour_name)}, {quote(start_date)}, {quote(end_date)});")

# ── TOUR_LEGS ────────────────────────────────────────────
sql("\n-- ============================================")
sql("-- TOUR_LEGS")
sql("-- ============================================")
sql("CREATE TEMPORARY SEQUENCE IF NOT EXISTS temp_tour_seq START 1;")

tour_regions = {}
for i in range(1, NUM_LEGS + 1):
    tour_num = ((i - 1) // 2) % NUM_TOURS + 1  # 2 legs per tour

    used = tour_regions.get(tour_num, set())
    available = [r for r in REGIONS if r not in used]
    if not available:
        available = REGIONS
    region = random.choice(available)
    tour_regions.setdefault(tour_num, set()).add(region)

    leg_name   = region.split()[0] + " Leg"
    start_date = fake.date_between(start_date=one_yr_ago, end_date=one_yr_fwd)
    end_date   = fake.date_between(start_date=start_date + timedelta(days=1), end_date=one_yr_fwd)
    sql(f"INSERT INTO tour_legs (tour_id, leg_name, region, start_date, end_date) VALUES ((SELECT tour_id FROM tours ORDER BY tour_id LIMIT 1 OFFSET {tour_num - 1}), {quote(leg_name)}, {quote(region)}, {quote(start_date)}, {quote(end_date)});")

# ── SHOWS ────────────────────────────────────────────────
sql("\n-- ============================================")
sql("-- SHOWS")
sql("-- ============================================")
used_venue_slots = set()

for i in range(1, NUM_SHOWS + 1):
    leg_num = ((i - 1) // 12) % NUM_LEGS + 1  # ~12 shows per leg

    for _ in range(50):
        show_date  = fake.date_between(start_date=one_yr_ago, end_date=one_yr_fwd)
        start_time = random.choice(["18:00:00", "19:00:00", "19:30:00", "20:00:00", "20:30:00", "21:00:00"])
        venue_id   = random.randint(1, 100)
        slot = (venue_id, str(show_date), start_time)
        if slot not in used_venue_slots:
            used_venue_slots.add(slot)
            break

    # STATUS: past shows can be completed/cancelled/postponed (not scheduled)
    #         future shows can be scheduled/cancelled/postponed (not completed)
    past_statuses   = ["completed", "cancelled"]
    future_statuses = ["scheduled", "cancelled"]
    status = random.choice(past_statuses) if show_date < today else random.choice(future_statuses)

    sql(f"INSERT INTO shows (leg_id, venue_id, promoter_id, show_date, start_time, status) VALUES ((SELECT leg_id FROM tour_legs ORDER BY leg_id LIMIT 1 OFFSET {leg_num - 1}), (SELECT venue_id FROM venues ORDER BY RANDOM() LIMIT 1), (SELECT promoter_id FROM promoter ORDER BY RANDOM() LIMIT 1), {quote(show_date)}, {quote(start_time)}, {quote(status)});")

# ── Output ────────────────────────────────────────────────
print("\n".join(lines))
