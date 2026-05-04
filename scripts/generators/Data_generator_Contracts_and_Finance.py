"""
Sample Data Generator — Contracts & Finance Module (Supritha)
Generates SQL INSERT statements for:
  - PROMOTER
  - CONTRACT
  - EXPENSE
  - PAYMENT
  - SETTLEMENT

Requires: pip install faker
Usage: python generate_finance_data.py > finance_data.sql
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
NUM_PROMOTERS = 30
NUM_CONTRACTS_PER_SHOW = 1 # 1 contract per show
NUM_EXPENSES = 800 # Spread across shows, tours, legs
NUM_PAYMENTS = 1000 # Payments for contracts and expenses
# SETTLEMENT: 1 per show (calculated)
# ─────────────────────────────────────────────────────────

# Data options
CONTRACT_TYPES = ['guarantee', 'percentage', 'hybrid', 'flat_fee']
CONTRACT_STATUSES = ['draft', 'sent', 'signed', 'cancelled', 'disputed']

EXPENSE_CATEGORIES = [
    'venue_rental', 'production', 'catering', 'travel',
    'lodging', 'equipment', 'insurance', 'marketing',
    'crew', 'permits', 'miscellaneous'
]

PAYMENT_METHODS = ['wire', 'ach', 'check', 'credit_card', 'cash']
PAYMENT_STATUSES = ['pending', 'completed', 'failed', 'refunded']
PAYMENT_TYPES = [
    'deposit', 'artist_guarantee', 'artist_percentage',
    'vendor_payment', 'reimbursement', 'settlement_payout'
]

SETTLEMENT_STATUSES = ['pending', 'finalized', 'disputed', 'amended']

# Markets for promoters
MARKETS = [
    'North America', 'Europe', 'Asia Pacific', 'Latin America',
    'Rock/Alternative', 'Pop/Dance', 'Hip-Hop/R&B', 'Country',
    'Electronic/EDM', 'Jazz/Classical', 'Multi-Genre'
]

lines = []

def sql(s):
    lines.append(s)

def quote(v):
    if v is None:
        return "NULL"
    return "'" + str(v).replace("'", "''") + "'"

# ── PROMOTER ─────────────────────────────────────────────
sql("\n-- ============================================")
sql("-- PROMOTER")
sql("-- ============================================")

for i in range(1, NUM_PROMOTERS + 1):
    company_name = fake.company() + " " + random.choice(['Entertainment', 'Presents', 'Productions', 'Events', 'Live'])
    contact_name = fake.name()
    contact_email = fake.email()
    phone = fake.phone_number()
    primary_market = random.choice(MARKETS)
    payment_terms = random.choice(['Net-30', 'Net-60', '50/50 split', '70/30 split', 'Upon completion'])

    sql(f"INSERT INTO promoter (company_name, contact_name, contact_email, phone, primary_market, payment_terms) VALUES ({quote(company_name)}, {quote(contact_name)}, {quote(contact_email)}, {quote(phone)}, {quote(primary_market)}, {quote(payment_terms)});")

# ── CONTRACT ─────────────────────────────────────────────
sql("\n-- ============================================")
sql("-- CONTRACT (1 per show)")
sql("-- ============================================")
sql("-- NOTE: Assumes ~500 shows exist")

for show_idx in range(500):
    contract_type = random.choice(CONTRACT_TYPES)

    # Agreed amount varies by contract type
    if contract_type == 'guarantee':
        agreed_amount = round(random.uniform(50000, 500000), 2)
        percentage_of_net = 'NULL'
    elif contract_type == 'percentage':
        agreed_amount = 0
        percentage_of_net = round(random.uniform(60, 90), 2)
    elif contract_type == 'hybrid':
        agreed_amount = round(random.uniform(25000, 200000), 2)
        percentage_of_net = round(random.uniform(70, 85), 2)
    else: # flat_fee
        agreed_amount = round(random.uniform(10000, 100000), 2)
        percentage_of_net = 'NULL'

    # Status distribution: most are signed
    status = random.choices(CONTRACT_STATUSES, weights=[0.05, 0.10, 0.75, 0.05, 0.05])[0]

    # Terms (optional)
    terms = quote(f"Standard performance agreement with {contract_type} payment structure") if random.random() < 0.6 else 'NULL'

    # Signed date (if signed)
    if status == 'signed':
        signed_date = quote((datetime.now() - timedelta(days=random.randint(30, 180))).date())
    else:
        signed_date = 'NULL'

    sql(f"INSERT INTO contract (show_id, contract_type, agreed_amount, percentage_of_net, status, terms, signed_date) VALUES ((SELECT show_id FROM shows ORDER BY show_id LIMIT 1 OFFSET {show_idx}), {quote(contract_type)}, {agreed_amount}, {percentage_of_net}, {quote(status)}, {terms}, {signed_date});")

# ── EXPENSE ──────────────────────────────────────────────
sql("\n-- ============================================")
sql("-- EXPENSE (distributed across shows/tours/legs)")
sql("-- ============================================")
sql("-- NOTE: Each expense belongs to either a show, tour, or leg (not multiple)")

for i in range(NUM_EXPENSES):
    # Randomly assign to show, tour, or leg
    expense_scope = random.choices(['show', 'tour', 'leg'], weights=[0.60, 0.25, 0.15])[0]

    if expense_scope == 'show':
        show_id_clause = f"(SELECT show_id FROM shows ORDER BY show_id LIMIT 1 OFFSET {random.randint(0, 499)})"
        tour_id_clause = 'NULL'
        leg_id_clause = 'NULL'
    elif expense_scope == 'tour':
        show_id_clause = 'NULL'
        tour_id_clause = f"(SELECT tour_id FROM tours ORDER BY tour_id LIMIT 1 OFFSET {random.randint(0, 19)})"
        leg_id_clause = 'NULL'
    else: # leg
        show_id_clause = 'NULL'
        tour_id_clause = 'NULL'
        leg_id_clause = f"(SELECT leg_id FROM tour_legs ORDER BY leg_id LIMIT 1 OFFSET {random.randint(0, 39)})"

    # Amount varies by category
    category = random.choice(EXPENSE_CATEGORIES)

    if category in ['venue_rental', 'production', 'insurance']:
        amount = round(random.uniform(10000, 100000), 2)
    elif category in ['equipment', 'marketing', 'crew']:
        amount = round(random.uniform(5000, 50000), 2)
    elif category in ['catering', 'travel', 'lodging']:
        amount = round(random.uniform(1000, 15000), 2)
    else:
        amount = round(random.uniform(500, 10000), 2)

    # Expense date (past 90 days)
    expense_date = (datetime.now() - timedelta(days=random.randint(0, 90))).date()

    # Description (optional)
    description = quote(f"{category.replace('_', ' ').title()} expense for event") if random.random() < 0.5 else 'NULL'

    # Vendor name (optional)
    vendor_name = quote(fake.company()) if random.random() < 0.7 else 'NULL'

    # Receipt number (optional)
    receipt_no = quote(f"RCP-{random.randint(10000, 99999)}") if random.random() < 0.6 else 'NULL'

    # Approved by (optional)
    approved_by = quote(fake.name()) if random.random() < 0.8 else 'NULL'

    sql(f"INSERT INTO expense (show_id, tour_id, leg_id, amount, expense_date, category, description, vendor_name, receipt_no, approved_by) VALUES ({show_id_clause}, {tour_id_clause}, {leg_id_clause}, {amount}, {quote(expense_date)}, {quote(category)}, {description}, {vendor_name}, {receipt_no}, {approved_by});")

# ── PAYMENT ──────────────────────────────────────────────
sql("\n-- ============================================")
sql("-- PAYMENT (for contracts and expenses)")
sql("-- ============================================")
sql("-- NOTE: Each payment links to either a contract or expense")

for i in range(NUM_PAYMENTS):
    # Randomly link to contract or expense
    payment_for = random.choices(['contract', 'expense'], weights=[0.55, 0.45])[0]

    if payment_for == 'contract':
        contract_id_clause = f"(SELECT contract_id FROM contract ORDER BY contract_id LIMIT 1 OFFSET {random.randint(0, 499)})"
        expense_id_clause = 'NULL'
        payment_type = random.choice(['deposit', 'artist_guarantee', 'artist_percentage', 'settlement_payout'])
        amount = round(random.uniform(10000, 250000), 2)
    else: # expense
        contract_id_clause = 'NULL'
        expense_id_clause = f"(SELECT expense_id FROM expense ORDER BY expense_id LIMIT 1 OFFSET {random.randint(0, NUM_EXPENSES - 1)})"
        payment_type = random.choice(['vendor_payment', 'reimbursement'])
        amount = round(random.uniform(500, 50000), 2)

    # Payment date (past 60 days)
    payment_date = (datetime.now() - timedelta(days=random.randint(0, 60))).date()

    # Payment method
    payment_method = random.choice(PAYMENT_METHODS)

    # Status (most are completed)
    status = random.choices(PAYMENT_STATUSES, weights=[0.15, 0.75, 0.05, 0.05])[0]

    sql(f"INSERT INTO payment (contract_id, expense_id, amount, payment_date, payment_method, status, payment_type) VALUES ({contract_id_clause}, {expense_id_clause}, {amount}, {quote(payment_date)}, {quote(payment_method)}, {quote(status)}, {quote(payment_type)});")

# ── SETTLEMENT ───────────────────────────────────────────
sql("\n-- ============================================")
sql("-- SETTLEMENT (1 per show)")
sql("-- ============================================")
sql("-- NOTE: Assumes ~500 shows exist")
sql("-- Settlement reconciles revenue and expenses for each show")

for show_idx in range(500):
    # Gross ticket revenue (varies widely)
    gross_ticket_revenue = round(random.uniform(100000, 2000000), 2)

    # Ticket fees (10-15% of gross)
    ticket_fees = round(gross_ticket_revenue * random.uniform(0.10, 0.15), 2)

    # Venue rent (5-20% of gross)
    venue_rent = round(gross_ticket_revenue * random.uniform(0.05, 0.20), 2)

    # Production costs (10-30% of gross)
    production_costs = round(gross_ticket_revenue * random.uniform(0.10, 0.30), 2)

    # Crew costs (5-15% of gross)
    crew_costs = round(gross_ticket_revenue * random.uniform(0.05, 0.15), 2)

    # Other expenses (2-10% of gross)
    other_expenses = round(gross_ticket_revenue * random.uniform(0.02, 0.10), 2)

    # Artist payment (typically 40-70% of net revenue)
    net_revenue = gross_ticket_revenue - ticket_fees - venue_rent - production_costs - crew_costs - other_expenses
    artist_payment = round(net_revenue * random.uniform(0.40, 0.70), 2)

    # Settlement date (recent)
    settlement_date = (datetime.now() - timedelta(days=random.randint(0, 30))).date()

    # Status (most are finalized)
    status = random.choices(SETTLEMENT_STATUSES, weights=[0.10, 0.80, 0.05, 0.05])[0]

    sql(f"INSERT INTO settlement (show_id, gross_ticket_revenue, ticket_fees, venue_rent, production_costs, crew_costs, other_expenses, artist_payment, settlement_date, status) VALUES ((SELECT show_id FROM shows ORDER BY show_id LIMIT 1 OFFSET {show_idx}), {gross_ticket_revenue}, {ticket_fees}, {venue_rent}, {production_costs}, {crew_costs}, {other_expenses}, {artist_payment}, {quote(settlement_date)}, {quote(status)});")

# ── Output ────────────────────────────────────────────────
output = "\n".join(lines)
print(output)

with open("finance_data.sql", "w") as f:
    f.write(output)
print("✅ finance_data.sql saved!")