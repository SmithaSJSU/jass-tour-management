"""
Sample Data Generator — Tickets & Logistics Module (Smitha)
Generates SQL INSERT statements for:
  - CREW
  - TRANSPORT
  - EQUIPMENT
  - TICKET_INVENTORY
  - TICKET_SALE
  - SHOW_CREW_ASSIGNMENT

Requires: pip install faker
Usage: python generate_logistics_data.py > logistics_data.sql
"""

# Auto-install faker if not present
try:
    from faker import Faker
except ImportError:
    print("Installing faker library...")
    import subprocess
    import sys
    subprocess.check_call([sys.executable, "-m", "pip", "install", "faker"])
    from faker import Faker
    print("Faker installed successfully!")

import random
from datetime import datetime, timedelta

fake = Faker()
random.seed(42)
Faker.seed(42)

# ── Config ────────────────────────────────────────────────
NUM_CREW = 50
NUM_TRANSPORT_PER_TOUR = 2 # 2 vehicles per tour
NUM_EQUIPMENT_PER_TOUR = 10 # 10 equipment items per tour
NUM_TICKET_TYPES_PER_SHOW = 3 # 3-4 ticket types per show
NUM_SALES_PER_INVENTORY = 25 # ~25 sales per ticket type
NUM_CREW_PER_SHOW = 6 # 4-8 crew members per show
# ─────────────────────────────────────────────────────────

# Data options
CREW_ROLES = [
    'sound_engineer', 'lighting_tech', 'stage_manager', 'rigger',
    'video_tech', 'monitor_engineer', 'foh_engineer', 'backline_tech',
    'production_manager', 'tour_manager', 'merchandise_manager',
    'security', 'driver', 'general_labor'
]

VEHICLE_TYPES = ['tour_bus', 'cargo_truck', 'van', 'trailer', 'sprinter', 'rv']

VEHICLE_MODELS = {
    'tour_bus': ['Prevost H3-45', 'MCI J4500', 'Van Hool CX45', 'Setra TopClass S 417'],
    'cargo_truck': ['Freightliner M2 106', 'International DuraStar', 'Peterbilt 220', 'Kenworth T270'],
    'van': ['Mercedes-Benz Sprinter', 'Ford Transit', 'Ram ProMaster', 'Chevrolet Express'],
    'trailer': ['Utility Reefer Trailer', 'Great Dane Dry Van', 'Wabash National', 'Stoughton Trailers'],
    'sprinter': ['Mercedes-Benz Sprinter 2500', 'Mercedes-Benz Sprinter 3500', 'Dodge Sprinter 3500'],
    'rv': ['Winnebago Horizon', 'Newmar Dutch Star', 'Tiffin Allegro Bus', 'Fleetwood Discovery']
}

EQUIPMENT_TYPES = [
    'instrument', 'guitar', 'bass', 'drums', 'keyboard', 'amplifier',
    'sound_system', 'speakers', 'mixer', 'microphone',
    'lighting', 'led_screen', 'video_equipment',
    'stage_piece', 'backdrop', 'riser', 'barricade',
    'cables', 'cases', 'racks', 'other'
]

EQUIPMENT_CATALOG = {
    'guitar': ['Fender Stratocaster', 'Gibson Les Paul', 'PRS Custom 24', 'Ibanez RG'],
    'bass': ['Fender Precision Bass', 'Music Man StingRay', 'Rickenbacker 4003'],
    'drums': ['Pearl Masters Kit', 'DW Collectors Series', 'Yamaha Recording Custom'],
    'keyboard': ['Nord Stage 3', 'Korg Kronos', 'Yamaha Montage'],
    'amplifier': ['Marshall JCM800', 'Fender Twin Reverb', 'Orange Rockerverb'],
    'sound_system': ['Line Array PA System', 'Meyer Sound System', 'L-Acoustics K2'],
    'speakers': ['JBL SRX Series', 'QSC K Series', 'Yamaha DXR'],
    'mixer': ['Yamaha CL5', 'Midas M32', 'Allen & Heath SQ-7'],
    'microphone': ['Shure SM58', 'Sennheiser e945', 'Audio-Technica AT2020'],
    'lighting': ['Moving Head Fixtures', 'LED Par Cans', 'Wash Lights'],
    'led_screen': ['LED Video Wall Panels', 'LED Curtain Display'],
    'video_equipment': ['HD Camera Package', 'Video Switcher', 'Projector'],
    'stage_piece': ['Stage Platforms', 'Stage Risers', 'Drum Riser'],
    'backdrop': ['Stage Curtain', 'Scenic Backdrop', 'LED Backdrop'],
    'barricade': ['Crowd Control Barriers', 'Stage Barriers'],
    'cables': ['XLR Cable Bundle', 'Power Cable Pack', 'Ethernet Cable Pack'],
    'cases': ['Road Cases', 'Flight Cases', 'Rack Cases'],
    'racks': ['Equipment Rack 19"', 'Power Distribution Rack']
}

TICKET_TYPES = ['General', 'VIP', 'Premium', 'Early Bird', 'Student', 'Senior']
VENUE_SECTIONS = ['Floor', 'Lower Bowl', 'Upper Bowl', 'Balcony', 'Mezzanine', 'Box Seats', 'VIP Section', 'Standing Room']
SALE_CHANNELS = ['online', 'box_office', 'phone', 'mobile_app', 'third_party']
PAYMENT_STATUSES = ['pending', 'paid', 'cancelled']

lines = []

def sql(s):
    lines.append(s)

def quote(v):
    if v is None:
        return "NULL"
    return "'" + str(v).replace("'", "''") + "'"

# ── CREW ─────────────────────────────────────────────────
sql("\n-- ============================================")
sql("-- CREW")
sql("-- ============================================")
for i in range(1, NUM_CREW + 1):
    person_name = fake.name()
    role = random.choice(CREW_ROLES)

    # Daily rates vary by role
    if role in ['production_manager', 'tour_manager']:
        daily_rate = round(random.uniform(500, 1000), 2)
    elif role in ['sound_engineer', 'lighting_tech', 'foh_engineer']:
        daily_rate = round(random.uniform(350, 650), 2)
    elif role in ['stage_manager', 'monitor_engineer', 'video_tech']:
        daily_rate = round(random.uniform(300, 500), 2)
    else:
        daily_rate = round(random.uniform(200, 400), 2)

    per_diem = round(random.uniform(50, 100), 2)
    contact_email = fake.email()
    emergency_contact = f"{fake.name()}, {fake.phone_number()}"

    sql(f"INSERT INTO crew (person_name, role, daily_rate, per_diem_amount, contact_email, emergency_contact) VALUES ({quote(person_name)}, {quote(role)}, {daily_rate}, {per_diem}, {quote(contact_email)}, {quote(emergency_contact)});")

# ── TRANSPORT ────────────────────────────────────────────
sql("\n-- ============================================")
sql("-- TRANSPORT (2 vehicles per tour)")
sql("-- ============================================")
sql("-- NOTE: This assumes ~20 tours exist")
sql("-- Each tour gets: 1 tour_bus + 1 cargo_truck/trailer")

for tour_offset in range(20): # Assuming 20 tours
    # Vehicle 1: Tour bus (for people)
    vehicle_type = 'tour_bus'
    make_model = random.choice(VEHICLE_MODELS[vehicle_type])
    capacity_people = random.randint(12, 20)
    capacity_weight = random.randint(2000, 5000)
    license_plate = fake.license_plate()
    driver_name = fake.name()
    insurance_expiry = (datetime.now() + timedelta(days=random.randint(180, 540))).date()

    sql(f"INSERT INTO transport (tour_id, vehicle_type, vehicle_make_model, capacity_people, capacity_weight_lbs, license_plate, driver_name, insurance_expiry) VALUES ((SELECT tour_id FROM tours ORDER BY tour_id LIMIT 1 OFFSET {tour_offset}), {quote(vehicle_type)}, {quote(make_model)}, {capacity_people}, {capacity_weight}, {quote(license_plate)}, {quote(driver_name)}, {quote(insurance_expiry)});")

    # Vehicle 2: Cargo truck (for equipment)
    vehicle_type = random.choice(['cargo_truck', 'trailer'])
    make_model = random.choice(VEHICLE_MODELS[vehicle_type])
    capacity_people = random.randint(2, 3)
    capacity_weight = random.randint(15000, 40000)
    license_plate = fake.license_plate()
    driver_name = fake.name()
    insurance_expiry = (datetime.now() + timedelta(days=random.randint(180, 540))).date()

    sql(f"INSERT INTO transport (tour_id, vehicle_type, vehicle_make_model, capacity_people, capacity_weight_lbs, license_plate, driver_name, insurance_expiry) VALUES ((SELECT tour_id FROM tours ORDER BY tour_id LIMIT 1 OFFSET {tour_offset}), {quote(vehicle_type)}, {quote(make_model)}, {capacity_people}, {capacity_weight}, {quote(license_plate)}, {quote(driver_name)}, {quote(insurance_expiry)});")

# ── EQUIPMENT ────────────────────────────────────────────
sql("\n-- ============================================")
sql("-- EQUIPMENT (10 items per tour)")
sql("-- ============================================")

for tour_offset in range(20): # Assuming 20 tours
    for item_num in range(NUM_EQUIPMENT_PER_TOUR):
        equipment_type = random.choice(EQUIPMENT_TYPES)

        # Get realistic description
        if equipment_type in EQUIPMENT_CATALOG:
            item_description = random.choice(EQUIPMENT_CATALOG[equipment_type])
        else:
            item_description = f"{equipment_type.replace('_', ' ').title()} Item"

        # Quantity varies by type
        if equipment_type in ['cables', 'cases', 'microphone']:
            quantity = random.randint(5, 20)
        elif equipment_type in ['guitar', 'bass', 'keyboard']:
            quantity = random.randint(2, 5)
        else:
            quantity = random.randint(1, 3)

        # Weight varies by type
        if equipment_type in ['guitar', 'bass', 'microphone', 'cables']:
            weight_lbs = round(random.uniform(5, 30), 2)
        elif equipment_type in ['keyboard', 'amplifier', 'mixer']:
            weight_lbs = round(random.uniform(30, 100), 2)
        elif equipment_type in ['drums', 'sound_system', 'speakers', 'lighting']:
            weight_lbs = round(random.uniform(100, 500), 2)
        else:
            weight_lbs = round(random.uniform(10, 200), 2)

        # Value varies by type
        if equipment_type in ['cables', 'cases', 'microphone']:
            value_usd = round(random.uniform(100, 1000), 2)
        elif equipment_type in ['guitar', 'bass', 'amplifier']:
            value_usd = round(random.uniform(1000, 5000), 2)
        elif equipment_type in ['drums', 'keyboard', 'mixer']:
            value_usd = round(random.uniform(3000, 10000), 2)
        elif equipment_type in ['sound_system', 'led_screen', 'lighting']:
            value_usd = round(random.uniform(10000, 50000), 2)
        else:
            value_usd = round(random.uniform(500, 5000), 2)

        # Climate control for instruments
        climate_control = 'TRUE' if equipment_type in ['guitar', 'bass', 'keyboard', 'drums'] else 'FALSE'

        # 70% assigned to transport, 30% not yet loaded
        if random.random() < 0.7:
            # Assign to one of the 2 transport vehicles for this tour
            transport_offset = tour_offset * 2 + random.randint(0, 1)
            transport_clause = f"(SELECT transport_id FROM transport ORDER BY transport_id LIMIT 1 OFFSET {transport_offset})"
        else:
            transport_clause = "NULL"

        sql(f"INSERT INTO equipment (tour_id, transport_id, equipment_type, item_description, quantity, weight_lbs, value_usd, requires_climate_control) VALUES ((SELECT tour_id FROM tours ORDER BY tour_id LIMIT 1 OFFSET {tour_offset}), {transport_clause}, {quote(equipment_type)}, {quote(item_description)}, {quantity}, {weight_lbs}, {value_usd}, {climate_control});")

# ── TICKET_INVENTORY ─────────────────────────────────────
sql("\n-- ============================================")
sql("-- TICKET_INVENTORY (3-4 types per show)")
sql("-- ============================================")
sql("-- NOTE: Assumes ~500 shows exist")

for show_offset in range(500): # Assuming 500 shows
    num_types = random.randint(3, 4)
    selected_types = random.sample(TICKET_TYPES, num_types)

    # Ensure General is included
    if 'General' not in selected_types:
        selected_types[0] = 'General'

    for ticket_type in selected_types:
        section_name = random.choice(VENUE_SECTIONS)

        # Allocate capacity
        total_quantity = random.randint(100, 2000)

        # Base price depends on type
        if ticket_type == 'VIP':
            base_price = round(random.uniform(150, 300), 2)
        elif ticket_type == 'Premium':
            base_price = round(random.uniform(80, 150), 2)
        elif ticket_type in ['Student', 'Senior']:
            base_price = round(random.uniform(25, 55), 2)
        elif ticket_type == 'Early Bird':
            base_price = round(random.uniform(30, 60), 2)
        else: # General
            base_price = round(random.uniform(40, 80), 2)

        # Service fees: 10-15%
        service_fees = round(base_price * random.uniform(0.10, 0.15), 2)

        # Hold quantity: 5-10%
        hold_quantity = int(total_quantity * random.uniform(0.05, 0.10))

        sql(f"INSERT INTO ticket_inventory (show_id, ticket_type, section_name, total_quantity, base_price, service_fees, hold_quantity) VALUES ((SELECT show_id FROM shows ORDER BY show_id LIMIT 1 OFFSET {show_offset}), {quote(ticket_type)}, {quote(section_name)}, {total_quantity}, {base_price}, {service_fees}, {hold_quantity});")

# ── TICKET_SALE ──────────────────────────────────────────
sql("\n-- ============================================")
sql("-- TICKET_SALE (~25 transactions per inventory)")
sql("-- ============================================")
sql("-- NOTE: This generates sales for ticket inventory")
sql("-- Assumes ticket_inventory has been populated")

sql("-- Using a counter to iterate through inventory IDs")
for inv_offset in range(1500): # Assuming ~1500 inventory records (500 shows × 3 types)
    num_sales = random.randint(15, 40)

    for sale_num in range(num_sales):
        quantity_sold = random.choices([1, 2, 3, 4, 5, 6], weights=[0.35, 0.30, 0.15, 0.10, 0.05, 0.05])[0]
        sale_channel = random.choices(SALE_CHANNELS, weights=[0.60, 0.15, 0.05, 0.15, 0.05])[0]

        # Sale timestamp: random in past 30-90 days
        days_ago = random.randint(30, 90)
        hours_ago = random.randint(0, 23)
        minutes_ago = random.randint(0, 59)
        sale_timestamp = datetime.now() - timedelta(days=days_ago, hours=hours_ago, minutes=minutes_ago)

        # Total amount will be calculated: quantity × (base_price + service_fees)
        # For SQL generation, we'll use a placeholder amount
        total_amount = round(random.uniform(50, 500), 2) # Placeholder

        buyer_email = fake.email()

        sql(f"INSERT INTO ticket_sale (inventory_id, quantity_sold, sale_channel, sale_timestamp, total_amount, buyer_email) VALUES ((SELECT inventory_id FROM ticket_inventory ORDER BY inventory_id LIMIT 1 OFFSET {inv_offset}), {quantity_sold}, {quote(sale_channel)}, {quote(sale_timestamp)}, {total_amount}, {quote(buyer_email)});")

# ── SHOW_CREW_ASSIGNMENT ─────────────────────────────────
sql("\n-- ============================================")
sql("-- SHOW_CREW_ASSIGNMENT (4-8 crew per show)")
sql("-- ============================================")
sql("-- NOTE: Assumes ~500 shows and 50 crew members exist")

for show_offset in range(500): # Assuming 500 shows
    num_crew = random.randint(4, 8)

    for crew_num in range(num_crew):
        # Random crew member
        crew_offset = random.randint(0, NUM_CREW - 1)

        # Check-in time: 4-8 hours before show (assuming 8pm show)
        hours_before = random.randint(4, 8)
        check_in = datetime(2024, 6, 15, 20, 0, 0) - timedelta(hours=hours_before)

        # Check-out time: 2-4 hours after show
        hours_after = random.randint(2, 4)
        check_out = datetime(2024, 6, 15, 23, 0, 0) + timedelta(hours=hours_after)

        # Payment amount: daily_rate + per_diem (random for SQL generation)
        payment_amount = round(random.uniform(250, 1100), 2)

        # Payment status: 70% paid, 25% pending, 5% cancelled
        payment_status = random.choices(PAYMENT_STATUSES, weights=[0.25, 0.70, 0.05])[0]

        sql(f"INSERT INTO show_crew_assignment (show_id, crew_id, check_in_time, check_out_time, payment_amount, payment_status) VALUES ((SELECT show_id FROM shows ORDER BY show_id LIMIT 1 OFFSET {show_offset}), (SELECT crew_id FROM crew ORDER BY crew_id LIMIT 1 OFFSET {crew_offset}), {quote(check_in)}, {quote(check_out)}, {payment_amount}, {quote(payment_status)});")

# ── Output ────────────────────────────────────────────────
print("\n".join(lines))
