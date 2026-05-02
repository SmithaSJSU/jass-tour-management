"""
JASS Tour Management — Contracts & Finance Dashboard
Run: streamlit run app.py
"""

import streamlit as st
import psycopg2
import psycopg2.extras
import pandas as pd
from datetime import date, timedelta

st.set_page_config(
    page_title="JASS · Tour Finance",
    page_icon="🎵",
    layout="wide",
    initial_sidebar_state="expanded",
)

# ── MEGA CSS ───────────────────────────────────────────────────────────────────
st.markdown("""
<style>
@import url('https://fonts.googleapis.com/css2?family=Syne:wght@400;500;600;700;800&family=Inter:wght@300;400;500;600&display=swap');

html, body, [class*="css"] { font-family: 'Inter', sans-serif; }

#MainMenu, footer, header { visibility: hidden; }
.block-container { padding: 0 2rem 2rem 2rem !important; max-width: 1400px; }

/* ── SIDEBAR ── */
[data-testid="stSidebar"] {
    background: linear-gradient(180deg, #0a0a12 0%, #0f0f1e 100%);
    border-right: 1px solid rgba(139,92,246,0.2);
}
[data-testid="stSidebar"] * { color: #a0a0c0 !important; }
[data-testid="stSidebar"] .stRadio > div { gap: 2px !important; }
[data-testid="stSidebar"] .stRadio label {
    font-size: 13px !important;
    padding: 8px 12px !important;
    border-radius: 8px !important;
    transition: all 0.2s !important;
    border: 1px solid transparent !important;
}
[data-testid="stSidebar"] .stRadio label:hover {
    background: rgba(139,92,246,0.1) !important;
    color: #c4b5fd !important;
    border-color: rgba(139,92,246,0.2) !important;
}
[data-testid="stSidebar"] .stRadio [aria-checked="true"] + div label,
[data-testid="stSidebar"] .stRadio label[data-checked="true"] {
    background: rgba(139,92,246,0.15) !important;
    color: #a78bfa !important;
}

/* ── METRICS ── */
[data-testid="stMetric"] {
    background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
    border: 1px solid rgba(139,92,246,0.25);
    border-radius: 16px;
    padding: 1.4rem 1.6rem !important;
    position: relative;
    overflow: hidden;
}
[data-testid="stMetric"]::before {
    content: '';
    position: absolute;
    top: 0; left: 0; right: 0;
    height: 2px;
    background: linear-gradient(90deg, #7c3aed, #a78bfa, #7c3aed);
}
[data-testid="stMetricLabel"] {
    font-size: 10px !important;
    font-weight: 600 !important;
    text-transform: uppercase !important;
    letter-spacing: 1.5px !important;
    color: #6b6b9a !important;
}
[data-testid="stMetricValue"] {
    font-family: 'Syne', sans-serif !important;
    font-size: 28px !important;
    font-weight: 700 !important;
    color: #e2e2f0 !important;
    background: linear-gradient(135deg, #a78bfa, #c4b5fd);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
}
[data-testid="stMetricDelta"] { font-size: 11px !important; }

/* ── DATAFRAME ── */
[data-testid="stDataFrame"] {
    border-radius: 14px !important;
    overflow: hidden !important;
    border: 1px solid rgba(139,92,246,0.2) !important;
}

/* ── BUTTONS ── */
.stButton > button {
    background: linear-gradient(135deg, #7c3aed, #6d28d9) !important;
    color: white !important;
    border: none !important;
    border-radius: 10px !important;
    padding: 0.55rem 1.6rem !important;
    font-weight: 600 !important;
    font-size: 13px !important;
    letter-spacing: 0.5px !important;
    transition: all 0.2s !important;
    font-family: 'Inter', sans-serif !important;
    box-shadow: 0 4px 15px rgba(124,58,237,0.3) !important;
}
.stButton > button:hover {
    background: linear-gradient(135deg, #6d28d9, #5b21b6) !important;
    transform: translateY(-2px) !important;
    box-shadow: 0 8px 25px rgba(124,58,237,0.4) !important;
}
.stButton > button:active { transform: translateY(0) !important; }

/* ── TABS ── */
.stTabs [data-baseweb="tab-list"] {
    gap: 0;
    background: rgba(139,92,246,0.08);
    padding: 4px;
    border-radius: 12px;
    border: 1px solid rgba(139,92,246,0.15);
}
.stTabs [data-baseweb="tab"] {
    border-radius: 9px;
    font-size: 13px;
    font-weight: 500;
    color: #6b6b9a;
    padding: 7px 20px;
    border: none !important;
}
.stTabs [aria-selected="true"] {
    background: linear-gradient(135deg, #7c3aed, #6d28d9) !important;
    color: white !important;
    box-shadow: 0 2px 8px rgba(124,58,237,0.3) !important;
}

/* ── INPUTS ── */
.stSelectbox > div > div, .stMultiSelect > div > div {
    border-radius: 10px !important;
    border-color: rgba(139,92,246,0.3) !important;
    background: rgba(15,15,30,0.6) !important;
    color: #e2e2f0 !important;
}
input, textarea {
    border-radius: 10px !important;
    border-color: rgba(139,92,246,0.3) !important;
    background: rgba(15,15,30,0.6) !important;
}

/* ── HEADINGS ── */
h1 {
    font-family: 'Syne', sans-serif !important;
    font-weight: 800 !important;
    font-size: 32px !important;
    background: linear-gradient(135deg, #a78bfa 0%, #c4b5fd 50%, #e2e2f0 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    letter-spacing: -1px !important;
    margin-bottom: 0 !important;
}
h2 {
    font-family: 'Syne', sans-serif !important;
    font-size: 20px !important;
    font-weight: 700 !important;
    color: #c4b5fd !important;
}
h3 {
    font-size: 15px !important;
    font-weight: 600 !important;
    color: #a0a0c0 !important;
}

/* ── ALERTS ── */
.stAlert { border-radius: 12px !important; }
.stSuccess {
    background: rgba(16,185,129,0.1) !important;
    border: 1px solid rgba(16,185,129,0.3) !important;
    color: #6ee7b7 !important;
}
.stError {
    background: rgba(239,68,68,0.1) !important;
    border: 1px solid rgba(239,68,68,0.3) !important;
    color: #fca5a5 !important;
}
.stWarning {
    background: rgba(245,158,11,0.1) !important;
    border: 1px solid rgba(245,158,11,0.3) !important;
    color: #fcd34d !important;
}
.stInfo {
    background: rgba(139,92,246,0.1) !important;
    border: 1px solid rgba(139,92,246,0.3) !important;
    color: #c4b5fd !important;
}

/* ── CUSTOM COMPONENTS ── */
.hero-banner {
    background: linear-gradient(135deg, #0f0f1e 0%, #1a0533 50%, #0f0f1e 100%);
    border: 1px solid rgba(139,92,246,0.3);
    border-radius: 20px;
    padding: 2rem 2.5rem;
    margin-bottom: 2rem;
    position: relative;
    overflow: hidden;
}
.hero-banner::before {
    content: '';
    position: absolute;
    top: -50%; left: -50%;
    width: 200%; height: 200%;
    background: radial-gradient(circle at 30% 50%, rgba(124,58,237,0.08) 0%, transparent 60%),
                radial-gradient(circle at 70% 50%, rgba(167,139,250,0.05) 0%, transparent 60%);
    pointer-events: none;
}
.hero-title {
    font-family: 'Syne', sans-serif;
    font-size: 42px;
    font-weight: 800;
    background: linear-gradient(135deg, #a78bfa 0%, #c4b5fd 40%, #ffffff 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    line-height: 1.1;
    margin: 0;
}
.hero-sub {
    font-size: 14px;
    color: #6b6b9a;
    margin-top: 8px;
    letter-spacing: 0.5px;
}
.hero-badge {
    display: inline-block;
    background: rgba(139,92,246,0.15);
    border: 1px solid rgba(139,92,246,0.3);
    color: #a78bfa;
    font-size: 11px;
    font-weight: 600;
    padding: 4px 12px;
    border-radius: 20px;
    letter-spacing: 1px;
    text-transform: uppercase;
    margin-bottom: 12px;
}
.section-label {
    font-size: 10px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 2px;
    color: rgba(139,92,246,0.6);
    margin: 2rem 0 1rem 0;
    padding-bottom: 8px;
    border-bottom: 1px solid rgba(139,92,246,0.15);
}
.stat-card {
    background: linear-gradient(135deg, #1a1a2e, #16213e);
    border: 1px solid rgba(139,92,246,0.2);
    border-radius: 14px;
    padding: 1.2rem 1.4rem;
    text-align: center;
}
.stat-num {
    font-family: 'Syne', sans-serif;
    font-size: 32px;
    font-weight: 800;
    background: linear-gradient(135deg, #a78bfa, #c4b5fd);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    line-height: 1;
}
.stat-label {
    font-size: 11px;
    color: #6b6b9a;
    text-transform: uppercase;
    letter-spacing: 1px;
    margin-top: 4px;
}
.badge-signed    { background:rgba(16,185,129,0.15); color:#6ee7b7; border:1px solid rgba(16,185,129,0.3); padding:3px 10px; border-radius:20px; font-size:11px; font-weight:600; }
.badge-disputed  { background:rgba(239,68,68,0.15);  color:#fca5a5; border:1px solid rgba(239,68,68,0.3);  padding:3px 10px; border-radius:20px; font-size:11px; font-weight:600; }
.badge-draft     { background:rgba(107,114,128,0.15);color:#9ca3af; border:1px solid rgba(107,114,128,0.3);padding:3px 10px; border-radius:20px; font-size:11px; font-weight:600; }
.badge-sent      { background:rgba(59,130,246,0.15); color:#93c5fd; border:1px solid rgba(59,130,246,0.3); padding:3px 10px; border-radius:20px; font-size:11px; font-weight:600; }
.badge-cancelled { background:rgba(239,68,68,0.08);  color:#f87171; border:1px solid rgba(239,68,68,0.2);  padding:3px 10px; border-radius:20px; font-size:11px; font-weight:600; }
.badge-guarantee  { background:rgba(139,92,246,0.15); color:#a78bfa; border:1px solid rgba(139,92,246,0.3); padding:3px 10px; border-radius:20px; font-size:11px; font-weight:600; }
.badge-hybrid     { background:rgba(236,72,153,0.15); color:#f9a8d4; border:1px solid rgba(236,72,153,0.3); padding:3px 10px; border-radius:20px; font-size:11px; font-weight:600; }
.badge-flat_fee   { background:rgba(6,182,212,0.15);  color:#67e8f9; border:1px solid rgba(6,182,212,0.3);  padding:3px 10px; border-radius:20px; font-size:11px; font-weight:600; }
.badge-percentage { background:rgba(245,158,11,0.15); color:#fcd34d; border:1px solid rgba(245,158,11,0.3); padding:3px 10px; border-radius:20px; font-size:11px; font-weight:600; }

.info-box {
    background: rgba(139,92,246,0.08);
    border: 1px solid rgba(139,92,246,0.2);
    border-left: 3px solid #7c3aed;
    border-radius: 10px;
    padding: 1rem 1.2rem;
    margin: 1rem 0;
    font-size: 13px;
    color: #a0a0c0;
    line-height: 1.6;
}
.code-block {
    background: #0a0a12;
    border: 1px solid rgba(139,92,246,0.2);
    border-radius: 10px;
    padding: 1rem 1.2rem;
    font-family: 'Courier New', monospace;
    font-size: 12px;
    color: #a78bfa;
    line-height: 1.7;
}
.divider {
    border: none;
    border-top: 1px solid rgba(139,92,246,0.15);
    margin: 1.5rem 0;
}
.page-caption {
    font-size: 13px;
    color: #6b6b9a;
    margin-top: -8px;
    margin-bottom: 1.5rem;
}
</style>
""", unsafe_allow_html=True)

# ── DB Connection ──────────────────────────────────────────────────────────────
@st.experimental_singleton
def get_connection():
    return psycopg2.connect(
        host     = st.secrets["DB_HOST"],
        port     = st.secrets["DB_PORT"],
        dbname   = st.secrets["DB_NAME"],
        user     = st.secrets["DB_USER"],
        password = st.secrets["DB_PASSWORD"],
    )

@st.experimental_memo(ttl=60)
def run_query(sql, params=None):
    conn = get_connection()
    return pd.read_sql(sql, conn, params=params)

def run_command(sql, params=None):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(sql, params)
        conn.commit()
        return True, None
    except Exception as e:
        conn.rollback()
        return False, str(e)
    finally:
        cur.close()

def run_procedure(sql, params=None):
    conn = get_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    try:
        cur.execute(sql, params)
        conn.commit()
        try:
            rows = cur.fetchall()
            return True, None, rows
        except:
            return True, None, []
    except Exception as e:
        conn.rollback()
        return False, str(e), []
    finally:
        cur.close()

# ── Helpers ────────────────────────────────────────────────────────────────────
def fmt_money(val):
    if pd.isna(val) or val is None: return "—"
    if val >= 1_000_000: return f"${val/1_000_000:.1f}M"
    if val >= 1_000:     return f"${val/1_000:.0f}K"
    return f"${val:,.0f}"

def fmt_pct(val):
    if pd.isna(val) or val is None: return "—"
    return f"{val:.1f}%"

def badge(val, kind="status"):
    css = f"badge-{str(val).lower().replace(' ','_')}"
    return f'<span class="{css}">{val}</span>'

# ── Stored Procedures Setup ────────────────────────────────────────────────────
def setup_db():
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute("""
            CREATE OR REPLACE PROCEDURE reschedule_show(p_show_id INT, p_new_date DATE, p_new_time TIME)
            LANGUAGE plpgsql AS $$
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM shows WHERE show_id = p_show_id) THEN
                    RAISE EXCEPTION 'Show ID % not found', p_show_id;
                END IF;
                UPDATE shows SET show_date=p_new_date, start_time=p_new_time, status='rescheduled'
                WHERE show_id=p_show_id AND status='scheduled';
                IF NOT FOUND THEN
                    RAISE EXCEPTION 'Show ID % is not scheduled', p_show_id;
                END IF;
            END; $$;
        """)
        cur.execute("""
            CREATE OR REPLACE PROCEDURE cancel_show(p_show_id INT)
            LANGUAGE plpgsql AS $$
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM shows WHERE show_id = p_show_id) THEN
                    RAISE EXCEPTION 'Show ID % not found', p_show_id;
                END IF;
                UPDATE shows SET status='cancelled'
                WHERE show_id=p_show_id AND status IN ('scheduled','rescheduled');
                IF NOT FOUND THEN
                    RAISE EXCEPTION 'Show ID % cannot be cancelled', p_show_id;
                END IF;
            END; $$;
        """)
        cur.execute("""
            CREATE OR REPLACE FUNCTION trg_auto_complete_show()
            RETURNS TRIGGER LANGUAGE plpgsql AS $$
            BEGIN
                IF NEW.show_date < CURRENT_DATE AND NEW.status = 'scheduled' THEN
                    NEW.status := 'completed';
                END IF;
                RETURN NEW;
            END; $$;
        """)
        cur.execute("DROP TRIGGER IF EXISTS auto_complete_show ON shows;")
        cur.execute("""
            CREATE TRIGGER auto_complete_show
            BEFORE INSERT OR UPDATE ON shows
            FOR EACH ROW EXECUTE FUNCTION trg_auto_complete_show();
        """)
        conn.commit()
    except Exception as e:
        conn.rollback()
        st.error(f"DB Setup Error: {e}")
    finally:
        cur.close()

setup_db()

# ── SIDEBAR ────────────────────────────────────────────────────────────────────
with st.sidebar:
    st.markdown("""
    <div style="padding: 1.2rem 0.5rem 1rem;">
        <div style="font-family:'Syne',sans-serif; font-size:22px; font-weight:800;
                    background:linear-gradient(135deg,#a78bfa,#c4b5fd);
                    -webkit-background-clip:text; -webkit-text-fill-color:transparent;">
            🎵 JASS
        </div>
        <div style="font-size:11px; color:#555580; letter-spacing:1px; text-transform:uppercase; margin-top:2px;">
            Tour Management System
        </div>
    </div>
    <hr style="border:none; border-top:1px solid rgba(139,92,246,0.2); margin:0 0 1rem 0;">
    """, unsafe_allow_html=True)

    st.markdown('<div style="font-size:9px;font-weight:700;text-transform:uppercase;letter-spacing:2px;color:rgba(139,92,246,0.5);padding:0 0.5rem;margin-bottom:4px;">Finance Module</div>', unsafe_allow_html=True)
    finance_pages = [
        "📊  Finance Dashboard",
        "📋  Contract Explorer",
        "🏢  Promoter Directory",
        "⚙️  Contract Actions",
    ]

    st.markdown('<div style="font-size:9px;font-weight:700;text-transform:uppercase;letter-spacing:2px;color:rgba(139,92,246,0.5);padding:0.8rem 0.5rem 4px;">Shows Module</div>', unsafe_allow_html=True)
    shows_pages = [
        "🎸  Tours by Artist",
        "🗺️  Shows by Tour / Leg",
        "🔍  Search Shows",
        "📅  Reschedule / Cancel",
        "🔔  Trigger Demo",
    ]

    all_pages = finance_pages + shows_pages
    page = st.radio("", all_pages)

    st.markdown("""
    <hr style="border:none;border-top:1px solid rgba(139,92,246,0.15);margin:1.5rem 0 1rem;">
    <div style="font-size:11px;color:#444466;text-align:center;padding-bottom:0.5rem;">
        DB Project · Spring 2026<br>
        <span style="color:rgba(139,92,246,0.4);">●</span> Live PostgreSQL
    </div>
    """, unsafe_allow_html=True)


# ═══════════════════════════════════════════════════════════════════════════════
# PAGE: Finance Dashboard
# ═══════════════════════════════════════════════════════════════════════════════
if page == "📊  Finance Dashboard":

    st.markdown("""
    <div class="hero-banner">
        <div class="hero-badge">Finance Module</div>
        <div class="hero-title">Finance Dashboard</div>
        <div class="hero-sub">Live contract & payment analytics — queried directly from PostgreSQL</div>
    </div>
    """, unsafe_allow_html=True)

    kpis = run_query("""
        SELECT
            COUNT(*)                                               AS total_contracts,
            COUNT(*) FILTER (WHERE status = 'signed')             AS signed,
            COUNT(*) FILTER (WHERE status = 'disputed')           AS disputed,
            COUNT(*) FILTER (WHERE status = 'draft')              AS draft,
            COALESCE(SUM(agreed_amount) FILTER (WHERE status='signed' AND agreed_amount>0),0) AS signed_value,
            COALESCE(AVG(agreed_amount) FILTER (WHERE agreed_amount>0),0)                     AS avg_value,
            COALESCE(SUM(agreed_amount) FILTER (WHERE status='disputed'),0)                   AS disputed_value
        FROM contract
    """)

    if not kpis.empty:
        row = kpis.iloc[0]
        c1,c2,c3,c4,c5,c6 = st.columns(6)
        c1.metric("Total Contracts",  f"{int(row['total_contracts']):,}")
        c2.metric("Signed",           f"{int(row['signed']):,}",      delta=f"{int(row['signed'])/max(int(row['total_contracts']),1)*100:.0f}% of total")
        c3.metric("Disputed",         f"{int(row['disputed']):,}",    delta=f"⚠ ${row['disputed_value']/1000:.0f}K at risk", delta_color="inverse")
        c4.metric("Draft",            f"{int(row['draft']):,}")
        c5.metric("Signed Value",     fmt_money(row['signed_value']))
        c6.metric("Avg Contract",     fmt_money(row['avg_value']))

    st.markdown('<div class="section-label">Contract Breakdown by Type & Status</div>', unsafe_allow_html=True)
    col_l, col_r = st.columns([1.3, 1])

    with col_l:
        breakdown = run_query("""
            SELECT contract_type, status,
                   COUNT(*) AS contracts,
                   COALESCE(SUM(agreed_amount),0) AS total_value,
                   COALESCE(AVG(agreed_amount) FILTER (WHERE agreed_amount>0),0) AS avg_value
            FROM contract
            GROUP BY contract_type, status
            ORDER BY contract_type, contracts DESC
        """)
        if not breakdown.empty:
            breakdown["total_value"] = breakdown["total_value"].apply(fmt_money)
            breakdown["avg_value"]   = breakdown["avg_value"].apply(fmt_money)
            breakdown.columns        = ["Type","Status","# Contracts","Total Value","Avg Value"]
            st.dataframe(breakdown)

    with col_r:
        st.markdown('<div style="font-size:13px;color:#6b6b9a;margin-bottom:0.8rem;">Signed contracts by payment structure</div>', unsafe_allow_html=True)
        top_c = run_query("""
            SELECT contract_type,
                   COUNT(*) AS num_signed,
                   SUM(agreed_amount) AS total,
                   AVG(percentage_of_net) AS avg_pct
            FROM contract WHERE status='signed'
            GROUP BY contract_type ORDER BY total DESC NULLS LAST
        """)
        if not top_c.empty:
            for _, r in top_c.iterrows():
                pct_str = f"  ·  avg {r['avg_pct']:.1f}% of net" if not pd.isna(r['avg_pct']) else ""
                st.markdown(f"""
                <div style="background:rgba(139,92,246,0.06);border:1px solid rgba(139,92,246,0.15);
                            border-radius:12px;padding:14px 16px;margin-bottom:8px;display:flex;
                            align-items:center;justify-content:space-between;">
                    <div>
                        <span class="badge-{r['contract_type']}">{r['contract_type']}</span>
                        <span style="font-size:11px;color:#555580;margin-left:8px;">{int(r['num_signed'])} contracts{pct_str}</span>
                    </div>
                    <div style="font-family:'Syne',sans-serif;font-size:18px;font-weight:700;
                                background:linear-gradient(135deg,#a78bfa,#c4b5fd);
                                -webkit-background-clip:text;-webkit-text-fill-color:transparent;">
                        {fmt_money(r['total'])}
                    </div>
                </div>
                """, unsafe_allow_html=True)

    st.markdown('<div class="section-label">Recently Signed Contracts</div>', unsafe_allow_html=True)
    recent = run_query("""
        SELECT c.signed_date, a.name AS artist, t.tour_name, tl.region,
               c.contract_type, c.agreed_amount, c.percentage_of_net, c.status
        FROM contract c
        JOIN shows s      ON c.show_id   = s.show_id
        JOIN tour_legs tl ON s.leg_id    = tl.leg_id
        JOIN tours t      ON tl.tour_id  = t.tour_id
        JOIN artists a    ON t.artist_id = a.artist_id
        WHERE c.status='signed' AND c.signed_date IS NOT NULL
        ORDER BY c.signed_date DESC LIMIT 10
    """)
    if not recent.empty:
        recent["agreed_amount"]     = recent["agreed_amount"].apply(fmt_money)
        recent["percentage_of_net"] = recent["percentage_of_net"].apply(fmt_pct)
        recent.columns = ["Signed","Artist","Tour","Region","Type","Amount","% Net","Status"]
        st.dataframe(recent)


# ═══════════════════════════════════════════════════════════════════════════════
# PAGE: Contract Explorer
# ═══════════════════════════════════════════════════════════════════════════════
elif page == "📋  Contract Explorer":
    st.markdown("""
    <div style="margin-bottom:1.5rem;">
        <h1>Contract Explorer</h1>
        <div class="page-caption">Filter and drill into every contract across all shows and tours</div>
    </div>
    """, unsafe_allow_html=True)

    st.markdown("""
    <div style="background:rgba(139,92,246,0.06);border:1px solid rgba(139,92,246,0.2);
                border-radius:14px;padding:1.2rem 1.5rem;margin-bottom:1.5rem;">
    """, unsafe_allow_html=True)
    fc1,fc2,fc3,fc4 = st.columns(4)
    with fc1: type_filter   = st.multiselect("Contract Type", ["guarantee","flat_fee","hybrid","percentage"], default=[])
    with fc2: status_filter = st.multiselect("Status", ["signed","draft","sent","disputed","cancelled"], default=[])
    with fc3: date_from     = st.date_input("Show Date From", value=date(2025,1,1))
    with fc4: date_to       = st.date_input("Show Date To",   value=date(2026,12,31))
    st.markdown("</div>", unsafe_allow_html=True)

    where = ["s.show_date BETWEEN %(date_from)s AND %(date_to)s"]
    params = {"date_from": str(date_from), "date_to": str(date_to)}
    if type_filter:
        phs = ", ".join([f"%(type_{i})s" for i in range(len(type_filter))])
        where.append(f"c.contract_type IN ({phs})")
        for i,t in enumerate(type_filter): params[f"type_{i}"] = t
    if status_filter:
        phs = ", ".join([f"%(status_{i})s" for i in range(len(status_filter))])
        where.append(f"c.status IN ({phs})")
        for i,s in enumerate(status_filter): params[f"status_{i}"] = s

    results = run_query(f"""
        SELECT a.name AS artist, t.tour_name, tl.region, s.show_date,
               c.contract_type, c.agreed_amount, c.percentage_of_net,
               c.status AS contract_status, c.signed_date, s.status AS show_status
        FROM contract c
        JOIN shows s      ON c.show_id   = s.show_id
        JOIN tour_legs tl ON s.leg_id    = tl.leg_id
        JOIN tours t      ON tl.tour_id  = t.tour_id
        JOIN artists a    ON t.artist_id = a.artist_id
        WHERE {" AND ".join(where)}
        ORDER BY s.show_date DESC
    """, params=params)

    if results.empty:
        st.info("No contracts match your filters.")
    else:
        m1,m2,m3,m4 = st.columns(4)
        signed_vals = results[results["contract_status"]=="signed"]["agreed_amount"]
        m1.metric("Contracts Found",  f"{len(results):,}")
        m2.metric("Signed Value",     fmt_money(signed_vals.sum()))
        m3.metric("Avg Amount",       fmt_money(results["agreed_amount"][results["agreed_amount"]>0].mean()))
        m4.metric("Disputed",         f"{(results['contract_status']=='disputed').sum()}", delta_color="inverse")
        st.markdown('<hr class="divider">', unsafe_allow_html=True)
        display = results.copy()
        display["agreed_amount"]     = display["agreed_amount"].apply(fmt_money)
        display["percentage_of_net"] = display["percentage_of_net"].apply(fmt_pct)
        display.columns = ["Artist","Tour","Region","Show Date","Contract Type","Agreed Amount","% Net","Contract Status","Signed Date","Show Status"]
        st.dataframe(display)


# ═══════════════════════════════════════════════════════════════════════════════
# PAGE: Promoter Directory
# ═══════════════════════════════════════════════════════════════════════════════
elif page == "🏢  Promoter Directory":
    st.markdown("""
    <div style="margin-bottom:1.5rem;">
        <h1>Promoter Directory</h1>
        <div class="page-caption">All promoter companies, their markets, and payment terms</div>
    </div>
    """, unsafe_allow_html=True)

    st.markdown('<div style="background:rgba(139,92,246,0.06);border:1px solid rgba(139,92,246,0.2);border-radius:14px;padding:1.2rem 1.5rem;margin-bottom:1.5rem;">', unsafe_allow_html=True)
    sc1,sc2 = st.columns(2)
    with sc1:
        market_filter = st.multiselect("Market", ["North America","Europe","Asia Pacific","Latin America",
                                                   "Multi-Genre","Hip-Hop/R&B","Jazz/Classical",
                                                   "Rock/Alternative","Country","Pop/Dance"], default=[])
    with sc2:
        terms_filter = st.multiselect("Payment Terms", ["Net-30","Net-60","50/50 split","70/30 split","Upon completion"], default=[])
    st.markdown("</div>", unsafe_allow_html=True)

    where = ["1=1"]
    params = {}
    if market_filter:
        phs = ", ".join([f"%(mkt_{i})s" for i in range(len(market_filter))])
        where.append(f"primary_market IN ({phs})")
        for i,m in enumerate(market_filter): params[f"mkt_{i}"] = m
    if terms_filter:
        phs = ", ".join([f"%(trm_{i})s" for i in range(len(terms_filter))])
        where.append(f"payment_terms IN ({phs})")
        for i,t in enumerate(terms_filter): params[f"trm_{i}"] = t

    promoters = run_query(f"""
        SELECT company_name, contact_name, contact_email, phone, primary_market, payment_terms
        FROM promoter WHERE {" AND ".join(where)} ORDER BY company_name
    """, params=params)

    if promoters.empty:
        st.info("No promoters match your filters.")
    else:
        pa,pb,pc = st.columns(3)
        pa.metric("Promoters Found", len(promoters))
        pb.metric("Unique Markets",  promoters["primary_market"].nunique())
        pc.metric("Payment Structures", promoters["payment_terms"].nunique())
        st.markdown('<hr class="divider">', unsafe_allow_html=True)
        promoters.columns = ["Company","Contact","Email","Phone","Market","Payment Terms"]
        st.dataframe(promoters)


# ═══════════════════════════════════════════════════════════════════════════════
# PAGE: Contract Actions
# ═══════════════════════════════════════════════════════════════════════════════
elif page == "⚙️  Contract Actions":
    st.markdown("""
    <div style="margin-bottom:1.5rem;">
        <h1>Contract Actions</h1>
        <div class="page-caption">Execute stored procedures, review disputes, and demo the trigger</div>
    </div>
    """, unsafe_allow_html=True)

    tab1,tab2,tab3 = st.tabs(["📝  Update Contract Status","🚨  Disputed Contracts","🔔  Trigger Demo"])

    with tab1:
        st.markdown("### Update Contract Status")
        st.markdown('<div class="info-box">Executes a direct <code>UPDATE</code> on the contract table. Select an artist, pick a show, choose the new status.</div>', unsafe_allow_html=True)

        artists_df = run_query("SELECT artist_id, name FROM artists ORDER BY name")
        artist_map = {r["name"]: r["artist_id"] for _,r in artists_df.iterrows()}
        sel = st.selectbox("Select Artist", list(artist_map.keys()))

        if sel:
            aid = artist_map[sel]
            contracts_df = run_query("""
                SELECT c.show_id, c.contract_type, c.agreed_amount, c.status AS contract_status, s.show_date, tl.region
                FROM contract c
                JOIN shows s      ON c.show_id   = s.show_id
                JOIN tour_legs tl ON s.leg_id    = tl.leg_id
                JOIN tours t      ON tl.tour_id  = t.tour_id
                JOIN artists a    ON t.artist_id = a.artist_id
                WHERE a.artist_id=%(aid)s AND c.status NOT IN ('cancelled')
                ORDER BY s.show_date
            """, params={"aid": aid})

            if contracts_df.empty:
                st.info("No active contracts for this artist.")
            else:
                labels = {f"[Show {r['show_id']}] {r['region']} · {r['show_date']} · {r['contract_type']} · {r['contract_status']}": r["show_id"]
                          for _,r in contracts_df.iterrows()}
                sel_c   = st.selectbox("Select Contract", list(labels.keys()))
                show_id = labels[sel_c]
                nc1,nc2 = st.columns(2)
                with nc1: new_status = st.selectbox("New Status", ["signed","draft","sent","disputed","cancelled"])
                with nc2: signed_date_val = st.date_input("Signed Date", value=date.today()) if new_status=="signed" else None
                if st.button("Update Contract Status"):
                    ok, err = run_command("UPDATE contract SET status=%s, signed_date=%s WHERE show_id=%s",
                                         (new_status, str(signed_date_val) if signed_date_val else None, show_id))
                    if ok:
                        st.success(f"✅ Contract for Show {show_id} updated to **{new_status}**.")
                        st.experimental_memo.clear()
                    else:
                        st.error(f"❌ {err}")

    with tab2:
        st.markdown("### Disputed Contracts")
        st.markdown('<div class="info-box">All contracts currently in dispute — showing artist, tour, value at risk, and contract terms.</div>', unsafe_allow_html=True)

        disputed = run_query("""
            SELECT a.name AS artist, t.tour_name, tl.region, s.show_date,
                   c.contract_type, c.agreed_amount, c.percentage_of_net, c.terms
            FROM contract c
            JOIN shows s      ON c.show_id   = s.show_id
            JOIN tour_legs tl ON s.leg_id    = tl.leg_id
            JOIN tours t      ON tl.tour_id  = t.tour_id
            JOIN artists a    ON t.artist_id = a.artist_id
            WHERE c.status='disputed'
            ORDER BY c.agreed_amount DESC NULLS LAST
        """)

        if disputed.empty:
            st.success("🎉 No disputed contracts right now!")
        else:
            d1,d2 = st.columns(2)
            d1.metric("Disputed Contracts", len(disputed))
            d2.metric("Total $ at Risk",    fmt_money(disputed["agreed_amount"].sum()), delta_color="inverse")
            st.markdown('<hr class="divider">', unsafe_allow_html=True)
            disputed["agreed_amount"]     = disputed["agreed_amount"].apply(fmt_money)
            disputed["percentage_of_net"] = disputed["percentage_of_net"].apply(fmt_pct)
            disputed.columns = ["Artist","Tour","Region","Show Date","Type","Amount","% Net","Terms"]
            st.dataframe(disputed)

    with tab3:
        st.markdown("### `auto_complete_show` Trigger Demo")
        st.markdown("""
        <div class="info-box">
            <strong style="color:#a78bfa;">How the trigger works:</strong><br>
            When a show's date is updated to a past date and its status is <code>scheduled</code>,
            the PostgreSQL trigger fires automatically and changes status → <code>completed</code>.
            No application code needed — the database enforces it.<br><br>
            <strong style="color:#a78bfa;">Trigger definition:</strong><br>
            <code>BEFORE INSERT OR UPDATE ON shows FOR EACH ROW</code>
        </div>
        """, unsafe_allow_html=True)

        artists_df3 = run_query("SELECT artist_id, name FROM artists ORDER BY name")
        artist_map3 = {r["name"]: r["artist_id"] for _,r in artists_df3.iterrows()}
        sel3 = st.selectbox("Select Artist", list(artist_map3.keys()), key="trig_a")

        if sel3:
            aid3 = artist_map3[sel3]
            sched = run_query("""
                SELECT s.show_id, t.tour_name, tl.region, s.show_date, s.status
                FROM shows s
                JOIN tour_legs tl ON s.leg_id   = tl.leg_id
                JOIN tours t      ON tl.tour_id = t.tour_id
                JOIN artists a    ON t.artist_id = a.artist_id
                WHERE a.artist_id=%(aid)s AND s.status IN ('scheduled','rescheduled')
                ORDER BY s.show_date
            """, params={"aid": aid3})

            if sched.empty:
                st.info("No scheduled shows for this artist.")
            else:
                slabels = {f"[{r['show_id']}] {r['tour_name']} · {r['region']} · {r['show_date']}": r["show_id"]
                           for _,r in sched.iterrows()}
                sel_s   = st.selectbox("Pick a Scheduled Show", list(slabels.keys()))
                show_id = slabels[sel_s]
                past_d  = st.date_input("Set to a Past Date", value=date(2024,6,1))

                tc1,tc2 = st.columns([1,3])
                with tc1:
                    if st.button("🔥 Fire Trigger"):
                        ok,err = run_command("UPDATE shows SET show_date=%s WHERE show_id=%s", (str(past_d), show_id))
                        if ok:
                            result = run_query("SELECT show_id, show_date, status FROM shows WHERE show_id=%(sid)s", params={"sid": show_id})
                            st.success("✅ Trigger fired!")
                            st.markdown('<div style="font-size:12px;color:#6b6b9a;margin-bottom:6px;">Resulting row in database:</div>', unsafe_allow_html=True)
                            st.dataframe(result)
                            st.info("Notice: status auto-changed `scheduled` → `completed` by the trigger — zero application code.")
                            st.experimental_memo.clear()
                        else:
                            st.error(f"❌ {err}")


# ═══════════════════════════════════════════════════════════════════════════════
# PAGE: Tours by Artist
# ═══════════════════════════════════════════════════════════════════════════════
elif page == "🎸  Tours by Artist":
    st.markdown("""
    <div style="margin-bottom:1.5rem;">
        <h1>Tours by Artist</h1>
        <div class="page-caption">All tours, legs, and shows for any artist</div>
    </div>
    """, unsafe_allow_html=True)

    artists = run_query("SELECT artist_id, name FROM artists ORDER BY name")
    artist_options = {r["name"]: r["artist_id"] for _,r in artists.iterrows()}
    selected = st.selectbox("Select Artist", list(artist_options.keys()))

    if selected:
        artist_id = artist_options[selected]
        tours = run_query("""
            SELECT t.tour_name, t.start_date, t.end_date,
                   COUNT(DISTINCT tl.leg_id) AS legs,
                   COUNT(DISTINCT s.show_id) AS shows
            FROM tours t
            LEFT JOIN tour_legs tl ON t.tour_id = tl.tour_id
            LEFT JOIN shows s      ON tl.leg_id = s.leg_id
            WHERE t.artist_id=%(aid)s
            GROUP BY t.tour_id, t.tour_name, t.start_date, t.end_date
            ORDER BY t.start_date DESC
        """, params={"aid": artist_id})

        if tours.empty:
            st.info("No tours found.")
        else:
            c1,c2,c3 = st.columns(3)
            c1.metric("Total Tours",  len(tours))
            c2.metric("Total Legs",   int(tours["legs"].sum()))
            c3.metric("Total Shows",  int(tours["shows"].sum()))
            st.markdown('<hr class="divider">', unsafe_allow_html=True)
            st.dataframe(tours)


# ═══════════════════════════════════════════════════════════════════════════════
# PAGE: Shows by Tour / Leg
# ═══════════════════════════════════════════════════════════════════════════════
elif page == "🗺️  Shows by Tour / Leg":
    st.markdown("""
    <div style="margin-bottom:1.5rem;">
        <h1>Shows by Tour / Leg</h1>
        <div class="page-caption">Drill into shows for any tour and leg</div>
    </div>
    """, unsafe_allow_html=True)

    tours = run_query("SELECT tour_id, tour_name FROM tours ORDER BY tour_name")
    tour_options = {r["tour_name"]: r["tour_id"] for _,r in tours.iterrows()}
    selected_tour = st.selectbox("Select Tour", list(tour_options.keys()))

    if selected_tour:
        tour_id = tour_options[selected_tour]
        legs = run_query("""
            SELECT leg_id, leg_name || ' (' || region || ')' AS leg_label
            FROM tour_legs WHERE tour_id=%(tid)s ORDER BY start_date
        """, params={"tid": tour_id})
        leg_options = {"All Legs": None}
        leg_options.update({r["leg_label"]: r["leg_id"] for _,r in legs.iterrows()})
        selected_leg = st.selectbox("Filter by Leg", list(leg_options.keys()))
        leg_id = leg_options[selected_leg]
        leg_filter = "AND tl.leg_id = %(leg_id)s" if leg_id else ""
        params = {"tour_id": tour_id, "leg_id": leg_id}

        shows = run_query(f"""
            SELECT tl.region, tl.leg_name, s.show_date, s.start_time, s.status
            FROM shows s
            JOIN tour_legs tl ON s.leg_id = tl.leg_id
            WHERE tl.tour_id=%(tour_id)s {leg_filter}
            ORDER BY s.show_date
        """, params=params)

        if shows.empty:
            st.info("No shows found.")
        else:
            st.metric("Shows Found", len(shows))
            st.markdown('<hr class="divider">', unsafe_allow_html=True)
            st.dataframe(shows)


# ═══════════════════════════════════════════════════════════════════════════════
# PAGE: Search Shows
# ═══════════════════════════════════════════════════════════════════════════════
elif page == "🔍  Search Shows":
    st.markdown("""
    <div style="margin-bottom:1.5rem;">
        <h1>Search Shows</h1>
        <div class="page-caption">Filter shows by status and date range across all tours</div>
    </div>
    """, unsafe_allow_html=True)

    st.markdown('<div style="background:rgba(139,92,246,0.06);border:1px solid rgba(139,92,246,0.2);border-radius:14px;padding:1.2rem 1.5rem;margin-bottom:1.5rem;">', unsafe_allow_html=True)
    col1,col2,col3 = st.columns(3)
    with col1: status_filter = st.multiselect("Status", ["scheduled","completed","cancelled","rescheduled"], default=[])
    with col2: date_from     = st.date_input("From Date", value=date.today()-timedelta(days=90))
    with col3: date_to       = st.date_input("To Date",   value=date.today()+timedelta(days=180))
    st.markdown("</div>", unsafe_allow_html=True)

    if st.button("Search Shows"):
        params = {"date_from": str(date_from), "date_to": str(date_to)}
        status_clause = ""
        if status_filter:
            phs = ", ".join([f"%(st_{i})s" for i in range(len(status_filter))])
            status_clause = f"AND s.status IN ({phs})"
            for i,s in enumerate(status_filter): params[f"st_{i}"] = s

        results = run_query(f"""
            SELECT s.show_date, s.start_time, a.name AS artist,
                   t.tour_name, tl.region, tl.leg_name, s.status
            FROM shows s
            JOIN tour_legs tl ON s.leg_id   = tl.leg_id
            JOIN tours t      ON tl.tour_id = t.tour_id
            JOIN artists a    ON t.artist_id = a.artist_id
            WHERE s.show_date BETWEEN %(date_from)s AND %(date_to)s {status_clause}
            ORDER BY s.show_date, s.start_time
        """, params=params)

        if results.empty:
            st.info("No shows found.")
        else:
            st.metric("Results Found", len(results))
            st.markdown('<hr class="divider">', unsafe_allow_html=True)
            st.dataframe(results)


# ═══════════════════════════════════════════════════════════════════════════════
# PAGE: Reschedule / Cancel
# ═══════════════════════════════════════════════════════════════════════════════
elif page == "📅  Reschedule / Cancel":
    st.markdown("""
    <div style="margin-bottom:1.5rem;">
        <h1>Reschedule / Cancel Shows</h1>
        <div class="page-caption">Calls stored procedures directly on the PostgreSQL database</div>
    </div>
    """, unsafe_allow_html=True)

    tab1,tab2 = st.tabs(["📅  Reschedule Show","❌  Cancel Show"])

    with tab1:
        st.markdown('<div class="info-box">Calls stored procedure: <code>reschedule_show(show_id, new_date, new_time)</code><br>Only works on shows with status = <code>scheduled</code>. Raises an exception otherwise.</div>', unsafe_allow_html=True)
        artists_df = run_query("SELECT artist_id, name FROM artists ORDER BY name")
        artist_map = {r["name"]: r["artist_id"] for _,r in artists_df.iterrows()}
        sel = st.selectbox("Artist", list(artist_map.keys()), key="rsch_a")
        if sel:
            aid = artist_map[sel]
            shows_df = run_query("""
                SELECT s.show_id, t.tour_name, tl.region, s.show_date, s.start_time
                FROM shows s
                JOIN tour_legs tl ON s.leg_id   = tl.leg_id
                JOIN tours t      ON tl.tour_id = t.tour_id
                JOIN artists a    ON t.artist_id = a.artist_id
                WHERE a.artist_id=%(aid)s AND s.status='scheduled' ORDER BY s.show_date
            """, params={"aid": aid})
            if shows_df.empty:
                st.info("No scheduled shows for this artist.")
            else:
                labels = {f"[{r['show_id']}] {r['tour_name']} · {r['region']} · {r['show_date']}": r["show_id"]
                          for _,r in shows_df.iterrows()}
                sel_show = st.selectbox("Show to Reschedule", list(labels.keys()))
                show_id  = labels[sel_show]
                nc1,nc2  = st.columns(2)
                with nc1: new_date = st.date_input("New Date", min_value=date.today()+timedelta(1))
                with nc2: new_time = st.time_input("New Start Time")
                if st.button("Reschedule Show"):
                    ok,err,_ = run_procedure("CALL reschedule_show(%s,%s,%s)", (show_id, str(new_date), str(new_time)))
                    if ok: st.success(f"✅ Show rescheduled to {new_date} at {new_time}"); st.experimental_memo.clear()
                    else:  st.error(f"❌ {err}")

    with tab2:
        st.markdown('<div class="info-box">Calls stored procedure: <code>cancel_show(show_id)</code><br>Works on <code>scheduled</code> and <code>rescheduled</code> shows. Raises exception if already completed or cancelled.</div>', unsafe_allow_html=True)
        artists_df2 = run_query("SELECT artist_id, name FROM artists ORDER BY name")
        artist_map2 = {r["name"]: r["artist_id"] for _,r in artists_df2.iterrows()}
        sel2 = st.selectbox("Artist", list(artist_map2.keys()), key="cncl_a")
        if sel2:
            aid2 = artist_map2[sel2]
            active = run_query("""
                SELECT s.show_id, t.tour_name, tl.region, s.show_date, s.status
                FROM shows s
                JOIN tour_legs tl ON s.leg_id   = tl.leg_id
                JOIN tours t      ON tl.tour_id = t.tour_id
                JOIN artists a    ON t.artist_id = a.artist_id
                WHERE a.artist_id=%(aid)s AND s.status IN ('scheduled','rescheduled') ORDER BY s.show_date
            """, params={"aid": aid2})
            if active.empty:
                st.info("No cancellable shows for this artist.")
            else:
                labels2 = {f"[{r['show_id']}] {r['tour_name']} · {r['region']} · {r['show_date']} ({r['status']})": r["show_id"]
                           for _,r in active.iterrows()}
                sel_cancel = st.selectbox("Show to Cancel", list(labels2.keys()))
                cid = labels2[sel_cancel]
                st.warning("⚠️ This will permanently mark the show as cancelled.")
                if st.button("Cancel Show"):
                    ok,err,_ = run_procedure("CALL cancel_show(%s)", (cid,))
                    if ok: st.success(f"✅ Show {cid} cancelled successfully."); st.experimental_memo.clear()
                    else:  st.error(f"❌ {err}")


# ═══════════════════════════════════════════════════════════════════════════════
# PAGE: Trigger Demo
# ═══════════════════════════════════════════════════════════════════════════════
elif page == "🔔  Trigger Demo":
    st.markdown("""
    <div style="margin-bottom:1.5rem;">
        <h1>Trigger Demo</h1>
        <div class="page-caption">Live demonstration of the auto_complete_show PostgreSQL trigger</div>
    </div>
    """, unsafe_allow_html=True)

    st.markdown("""
    <div class="info-box">
        <strong style="color:#a78bfa;">Trigger:</strong> <code>auto_complete_show</code><br>
        <strong style="color:#a78bfa;">Event:</strong> BEFORE INSERT OR UPDATE ON shows (FOR EACH ROW)<br>
        <strong style="color:#a78bfa;">Logic:</strong> If <code>show_date &lt; CURRENT_DATE</code> and <code>status = 'scheduled'</code>,
        automatically set <code>status = 'completed'</code>.<br>
        <strong style="color:#a78bfa;">Purpose:</strong> Enforce data integrity at the DB level — no stale "scheduled" shows in the past.
    </div>
    """, unsafe_allow_html=True)

    artists_df4 = run_query("SELECT artist_id, name FROM artists ORDER BY name")
    artist_map4 = {r["name"]: r["artist_id"] for _,r in artists_df4.iterrows()}
    sel4 = st.selectbox("Select Artist", list(artist_map4.keys()))

    if sel4:
        aid4 = artist_map4[sel4]
        sched4 = run_query("""
            SELECT s.show_id, t.tour_name, tl.region, s.show_date, s.status
            FROM shows s
            JOIN tour_legs tl ON s.leg_id   = tl.leg_id
            JOIN tours t      ON tl.tour_id = t.tour_id
            JOIN artists a    ON t.artist_id = a.artist_id
            WHERE a.artist_id=%(aid)s AND s.status IN ('scheduled','rescheduled')
            ORDER BY s.show_date
        """, params={"aid": aid4})

        if sched4.empty:
            st.info("No scheduled shows for this artist.")
        else:
            slabels4 = {f"[{r['show_id']}] {r['tour_name']} · {r['region']} · {r['show_date']}": r["show_id"]
                        for _,r in sched4.iterrows()}
            sel_s4  = st.selectbox("Pick a Scheduled Show", list(slabels4.keys()))
            sid4    = slabels4[sel_s4]
            past4   = st.date_input("Set to a Past Date", value=date(2024,1,1))

            col_btn, col_note = st.columns([1,3])
            with col_btn:
                if st.button("🔥 Fire Trigger"):
                    ok,err = run_command("UPDATE shows SET show_date=%s WHERE show_id=%s", (str(past4), sid4))
                    if ok:
                        result4 = run_query("SELECT show_id, show_date, status FROM shows WHERE show_id=%(sid)s", params={"sid": sid4})
                        st.success("✅ Trigger fired!")
                        st.dataframe(result4)
                        st.info("status auto-changed: `scheduled` → `completed` (enforced by trigger, not app code)")
                        st.experimental_memo.clear()
                    else:
                        st.error(f"❌ {err}")
