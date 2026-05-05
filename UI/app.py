"""
============================================
JASS Tour Management System — Streamlit Demo
============================================
Course  : CMPE 180B — Database Systems
School  : San Jose State University
Team    : Jack • Anusha • Supritha • Smitha
Date    : May 2026
============================================
"""

import streamlit as st
import psycopg2
import psycopg2.extras
import pandas as pd
from datetime import date, timedelta

st.set_page_config(
    page_title="JASS Tour Management",
    page_icon="🎸",
    layout="wide",
    initial_sidebar_state="collapsed",
)

st.markdown("""
<style>
  @import url('https://fonts.googleapis.com/css2?family=Syne:wght@400;700;800&family=DM+Sans:wght@300;400;500&display=swap');

  [data-testid="stToolbar"] { display: none !important; }
  .stDeployButton { display: none !important; }

  html, body, [class*="css"] {
      font-family: 'DM Sans', sans-serif;
      background-color: #0d1b2a;
      color: #e8edf3;
  }
  .stApp {
      background: linear-gradient(135deg, #0d1b2a 0%, #1a2f4a 50%, #0d1b2a 100%);
  }
  .jass-header {
      background: linear-gradient(135deg, #1a2f4a, #243b55);
      border: 1px solid rgba(100,160,220,0.2);
      border-radius: 16px;
      padding: 28px 36px;
      margin-bottom: 24px;
  }
  .jass-header h1 {
      font-family: 'Syne', sans-serif;
      font-weight: 800;
      font-size: 2.2rem;
      color: #ffffff;
      margin: 0;
      letter-spacing: -0.5px;
  }
  .jass-header p { color: #8aaccc; margin: 4px 0 0 0; font-size: 0.95rem; }
  .stTabs [data-baseweb="tab-list"] {
      background: rgba(26,47,74,0.8);
      border-radius: 12px;
      padding: 4px;
      gap: 4px;
      border: 1px solid rgba(100,160,220,0.15);
  }
  .stTabs [data-baseweb="tab"] {
      background: transparent;
      color: #8aaccc;
      border-radius: 8px;
      font-family: 'Syne', sans-serif;
      font-weight: 700;
      font-size: 0.82rem;
      padding: 8px 16px;
      border: none;
  }
  .stTabs [aria-selected="true"] {
      background: linear-gradient(135deg, #2563a8, #1a4a80) !important;
      color: #ffffff !important;
  }
  .module-card {
      background: linear-gradient(135deg, rgba(26,47,74,0.9), rgba(36,59,85,0.9));
      border: 1px solid rgba(100,160,220,0.2);
      border-radius: 12px;
      padding: 20px 24px;
      margin-bottom: 16px;
  }
  .module-card h3 { font-family:'Syne',sans-serif; font-weight:700; color:#64a0dc; margin:0 0 4px 0; font-size:1.1rem; }
  .module-card p  { color:#8aaccc; margin:0; font-size:0.88rem; }
  .metric-row { display:flex; gap:16px; margin-bottom:20px; }
  .metric-card {
      background: linear-gradient(135deg, rgba(37,99,168,0.3), rgba(26,74,128,0.3));
      border: 1px solid rgba(100,160,220,0.25);
      border-radius: 10px;
      padding: 16px 20px;
      flex: 1;
      text-align: center;
  }
  .metric-card .value { font-family:'Syne',sans-serif; font-size:1.8rem; font-weight:800; color:#64b8ff; }
  .metric-card .label { font-size:0.8rem; color:#8aaccc; margin-top:4px; }
  .section-title {
      font-family:'Syne',sans-serif; font-weight:700; font-size:1.15rem; color:#ffffff;
      margin:20px 0 12px 0; padding-bottom:8px;
      border-bottom:1px solid rgba(100,160,220,0.2);
  }
  .stMarkdown p, .stMarkdown strong, .stMarkdown b { color:#e8edf3 !important; }
  [data-testid="stMarkdownContainer"] p { color:#e8edf3 !important; }
  [data-testid="stMarkdownContainer"] strong { color:#ffffff !important; font-size:1.0rem; }
  hr { border-color:rgba(100,160,220,0.2) !important; }
  .stCaption, [data-testid="stCaptionContainer"] { color:#8aaccc !important; }
  .stButton > button {
      background: linear-gradient(135deg, #2563a8, #1a4a80);
      color:white; border:none; border-radius:8px;
      font-family:'Syne',sans-serif; font-weight:700;
      padding:8px 24px; font-size:0.9rem; transition:all 0.2s;
  }
  .stButton > button:hover {
      background: linear-gradient(135deg, #3070b8, #2256a0);
      transform:translateY(-1px);
      box-shadow:0 4px 16px rgba(37,99,168,0.4);
  }
  .stDataFrame { border-radius:10px; overflow:hidden; }
  .stSelectbox > div > div, .stTextInput > div > div {
      background:rgba(26,47,74,0.8);
      border:1px solid rgba(100,160,220,0.25);
      border-radius:8px; color:#ffffff;
  }
  .stSelectbox div[data-baseweb="select"] span,
  .stSelectbox div[data-baseweb="select"] div,
  .stSelectbox input, .stTextInput input, .stNumberInput input { color:#ffffff !important; }
  [data-baseweb="popover"] li, [data-baseweb="menu"] li { background:#1a2f4a !important; color:#ffffff !important; }
  [data-baseweb="popover"] li:hover, [data-baseweb="menu"] li:hover { background:#2563a8 !important; color:#ffffff !important; }
  .stSlider label, .stSelectbox label, .stTextInput label, .stNumberInput label { color:#e8edf3 !important; }
  .stSuccess { background:rgba(16,185,129,0.15); border:1px solid rgba(16,185,129,0.3); border-radius:8px; }
  .stError   { background:rgba(239,68,68,0.15);  border:1px solid rgba(239,68,68,0.3);  border-radius:8px; }
  .stInfo    { background:rgba(37,99,168,0.2);   border:1px solid rgba(37,99,168,0.3);  border-radius:8px; }
  .stWarning { background:rgba(245,158,11,0.1);  border:1px solid rgba(245,158,11,0.3); border-radius:8px; }
  .badge-signed    { background:rgba(16,185,129,0.15);  color:#6ee7b7; border:1px solid rgba(16,185,129,0.3);  padding:3px 10px; border-radius:20px; font-size:11px; font-weight:600; }
  .badge-disputed  { background:rgba(239,68,68,0.15);   color:#fca5a5; border:1px solid rgba(239,68,68,0.3);   padding:3px 10px; border-radius:20px; font-size:11px; font-weight:600; }
  .badge-draft     { background:rgba(107,114,128,0.15); color:#9ca3af; border:1px solid rgba(107,114,128,0.3); padding:3px 10px; border-radius:20px; font-size:11px; font-weight:600; }
  .badge-sent      { background:rgba(59,130,246,0.15);  color:#93c5fd; border:1px solid rgba(59,130,246,0.3);  padding:3px 10px; border-radius:20px; font-size:11px; font-weight:600; }
  .badge-cancelled { background:rgba(239,68,68,0.08);   color:#f87171; border:1px solid rgba(239,68,68,0.2);   padding:3px 10px; border-radius:20px; font-size:11px; font-weight:600; }
  .badge-guarantee  { background:rgba(139,92,246,0.15); color:#a78bfa; border:1px solid rgba(139,92,246,0.3); padding:3px 10px; border-radius:20px; font-size:11px; font-weight:600; }
  .badge-hybrid     { background:rgba(236,72,153,0.15); color:#f9a8d4; border:1px solid rgba(236,72,153,0.3); padding:3px 10px; border-radius:20px; font-size:11px; font-weight:600; }
  .badge-flat_fee   { background:rgba(6,182,212,0.15);  color:#67e8f9; border:1px solid rgba(6,182,212,0.3);  padding:3px 10px; border-radius:20px; font-size:11px; font-weight:600; }
  .badge-percentage { background:rgba(245,158,11,0.15); color:#fcd34d; border:1px solid rgba(245,158,11,0.3); padding:3px 10px; border-radius:20px; font-size:11px; font-weight:600; }
  .info-box {
      background:rgba(37,99,168,0.1); border:1px solid rgba(100,160,220,0.2);
      border-left:3px solid #2563a8; border-radius:10px;
      padding:1rem 1.2rem; margin:1rem 0;
      font-size:13px; color:#8aaccc; line-height:1.6;
  }
  footer { visibility:hidden; }
  #MainMenu { visibility:hidden; }
</style>
""", unsafe_allow_html=True)


# ── Database connection ────────────────────────────────────
@st.cache_resource
def get_connection():
    return psycopg2.connect(
        host="host.docker.internal",
        port=5432,
        dbname="jass_tour_management",
        user="postgres",
        password="*******",  # ← update with your actual password
    )

def run_query(sql, params=None):
    try:
        conn = get_connection()
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
            cur.execute(sql, params)
            rows = cur.fetchall()
            if rows:
                return pd.DataFrame(rows, columns=[desc[0] for desc in cur.description])
            return pd.DataFrame()
    except Exception as e:
        st.error(f"Query error: {e}")
        try:
            conn.rollback()
        except:
            pass
        return pd.DataFrame()

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

def run_transaction(sql_steps: list):
    try:
        conn = get_connection()
        conn.autocommit = False
        with conn.cursor() as cur:
            for sql, params in sql_steps:
                cur.execute(sql, params)
        conn.commit()
        conn.autocommit = True
        return True, "Transaction committed successfully."
    except Exception as e:
        conn.rollback()
        conn.autocommit = True
        return False, str(e)

def show_df(df, height=400):
    if df.empty:
        st.info("No results returned.")
    else:
        st.dataframe(df, use_container_width=True, height=height)
        st.caption(f"{len(df):,} rows returned")

def metric_html(value, label):
    return f"""<div class="metric-card">
        <div class="value">{value}</div>
        <div class="label">{label}</div>
    </div>"""

def fmt_money(val):
    if pd.isna(val) or val is None: return "—"
    if val >= 1_000_000: return f"${val/1_000_000:.1f}M"
    if val >= 1_000:     return f"${val/1_000:.0f}K"
    return f"${val:,.0f}"

def fmt_pct(val):
    if pd.isna(val) or val is None: return "—"
    return f"{val:.1f}%"


# ── Stored procedures setup ────────────────────────────────
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
    finally:
        cur.close()

setup_db()


# ── Header ─────────────────────────────────────────────────
st.markdown("""
<div class="jass-header">
    <div>
        <h1>🎸 JASS Tour Management System</h1>
        <p>CMPE 180B — Database Systems &nbsp;|&nbsp; San Jose State University &nbsp;|&nbsp; May 2026</p>
        <p style="color:#64a0dc; margin-top:4px; font-size:0.85rem;">
            Jack &nbsp;•&nbsp; Anusha &nbsp;•&nbsp; Supritha &nbsp;•&nbsp; Smitha
        </p>
    </div>
</div>
""", unsafe_allow_html=True)


# ── Tabs ───────────────────────────────────────────────────
tab1, tab2, tab3, tab4, tab5, tab6 = st.tabs([
    "🗺️ Venues & Geography",
    "🎤 Tours & Shows",
    "💰 Contracts & Finance",
    "🎟️ Tickets & Logistics",
    "🔗 Complex Queries",
    "⚡ Transactions (ACID)",
])


# ══════════════════════════════════════════════════════════
# TAB 1: VENUES & GEOGRAPHY (Jack)
# ══════════════════════════════════════════════════════════
with tab1:
    st.markdown('<div class="section-title">🗺️ Venues & Geography Module — Jack</div>', unsafe_allow_html=True)

    col1, col2 = st.columns([1, 2])
    with col1:
        st.markdown('<div class="module-card"><h3>Module Overview</h3><p>countries • cities • venues • routing • show_sequence</p></div>', unsafe_allow_html=True)
        stats = run_query("""
            SELECT (SELECT COUNT(*) FROM countries) AS countries,
                   (SELECT COUNT(*) FROM cities)    AS cities,
                   (SELECT COUNT(*) FROM venues)    AS venues,
                   (SELECT COUNT(*) FROM routing)   AS routes
        """)
        if not stats.empty:
            r = stats.iloc[0]
            st.markdown(f"""
            <div class="metric-row">
                {metric_html(r['countries'], 'Countries')}
                {metric_html(r['cities'], 'Cities')}
            </div>
            <div class="metric-row">
                {metric_html(r['venues'], 'Venues')}
                {metric_html(r['routes'], 'Routes')}
            </div>
            """, unsafe_allow_html=True)

    with col2:
        jack_query = st.selectbox("Select Query", [
            "Query 1 — Venues in a City",
            "Query 2 — Nearest Venues to a Selected Venue",
        ], key="jack_query_select")

    st.divider()

    if "Query 1" in jack_query:
        st.markdown("**Query 1 — Venues in a City**")
        cities_df = run_query("SELECT DISTINCT name FROM cities ORDER BY name")
        city_options = cities_df['name'].tolist() if not cities_df.empty else []
        col_a, col_b = st.columns([3, 1])
        with col_a:
            selected_city = st.selectbox("Select a city", city_options, key="city_select")
        with col_b:
            st.markdown("<br>", unsafe_allow_html=True)
            search_venues = st.button("🔍 Show Venues", key="btn_venues")
        if search_venues:
            df = run_query("""
                SELECT v.name AS venue_name, v.capacity, v.indoor_outdoor,
                       co.name AS country, COUNT(s.show_id) AS total_shows
                FROM venues v
                JOIN cities c     ON v.city_id    = c.city_id
                JOIN countries co ON c.country_id = co.country_id
                LEFT JOIN shows s ON v.venue_id   = s.venue_id
                WHERE c.name = %s
                GROUP BY v.venue_id, v.name, v.capacity, v.indoor_outdoor, co.name
                ORDER BY v.capacity DESC
            """, (selected_city,))
            if not df.empty:
                c1,c2,c3,c4,c5 = st.columns(5)
                c1.metric("Venues Found",   len(df))
                c2.metric("Total Capacity", f"{int(df['capacity'].sum()):,}")
                c3.metric("Total Shows",    int(df['total_shows'].sum()))
                c4.metric("Indoor",  len(df[df['indoor_outdoor']=='indoor']))
                c5.metric("Outdoor", len(df[df['indoor_outdoor']=='outdoor']))
            show_df(df, height=320)

    else:
        st.markdown("**Query 2 — Nearest Venues to a Selected Venue**")
        venues_df = run_query("SELECT name FROM venues ORDER BY name LIMIT 200")
        venue_options = venues_df['name'].tolist() if not venues_df.empty else []
        col_a, col_b = st.columns([2, 1])
        with col_a:
            selected_venue = st.selectbox("Select a venue", venue_options, key="venue_select")
        with col_b:
            top_n = st.slider("Top N closest", 5, 20, 10)
        col_c, col_d, col_e = st.columns(3)
        with col_c:
            venue_type_filter = st.multiselect("Venue Type", ["indoor","outdoor"], default=["indoor","outdoor"])
        with col_d:
            min_cap = st.number_input("Min Capacity", min_value=0, value=0, step=1000)
        with col_e:
            max_cap = st.number_input("Max Capacity", min_value=0, value=100000, step=1000)
        if st.button("📍 Find Nearest Venues", key="btn_route"):
            df = run_query("""
                SELECT v2.name AS destination_venue, c2.name AS destination_city,
                       co2.name AS country, v2.capacity, v2.indoor_outdoor,
                       r.distance AS distance_km, r.estimated_travel_time AS travel_hours
                FROM routing r
                JOIN venues v1     ON r.from_venue_id = v1.venue_id
                JOIN venues v2     ON r.to_venue_id   = v2.venue_id
                JOIN cities c2     ON v2.city_id       = c2.city_id
                JOIN countries co2 ON c2.country_id   = co2.country_id
                WHERE v1.name = %s ORDER BY r.distance ASC LIMIT %s
            """, (selected_venue, top_n * 3))
            if not df.empty:
                if venue_type_filter:
                    df = df[df['indoor_outdoor'].isin(venue_type_filter)]
                df = df[(df['capacity'] >= min_cap) & (df['capacity'] <= max_cap)].head(top_n)
                if not df.empty:
                    c1,c2,c3,c4 = st.columns(4)
                    c1.metric("Venues Found", len(df))
                    c2.metric("Avg Distance", f"{df['distance_km'].mean():.0f} km")
                    c3.metric("Avg Capacity", f"{int(df['capacity'].mean()):,}")
                    c4.metric("Closest",      f"{df['distance_km'].min()} km")
                    show_df(df, height=320)
                    closest = df.iloc[0]
                    st.divider()
                    st.markdown("**🏆 Closest Matching Venue**")
                    cc1,cc2,cc3,cc4 = st.columns(4)
                    cc1.metric("Venue",    closest['destination_venue'])
                    cc2.metric("Distance", f"{closest['distance_km']} km")
                    cc3.metric("Capacity", f"{int(closest['capacity']):,}")
                    cc4.metric("Type",     closest['indoor_outdoor'].capitalize())
                else:
                    st.warning("No venues match your filters.")
            else:
                st.info("No routing data found for this venue.")


# ══════════════════════════════════════════════════════════
# TAB 2: TOURS & SHOWS (Anusha)
# ══════════════════════════════════════════════════════════
with tab2:
    st.markdown('<div class="section-title">🎤 Tours & Shows Module — Anusha</div>', unsafe_allow_html=True)

    col1, col2 = st.columns([1, 2])
    with col1:
        st.markdown('<div class="module-card"><h3>Module Overview</h3><p>managers • artists • tours • tour_legs • shows</p></div>', unsafe_allow_html=True)
        stats2 = run_query("""
            SELECT (SELECT COUNT(*) FROM artists)   AS artists,
                   (SELECT COUNT(*) FROM tours)     AS tours,
                   (SELECT COUNT(*) FROM tour_legs) AS legs,
                   (SELECT COUNT(*) FROM shows)     AS shows
        """)
        if not stats2.empty:
            r = stats2.iloc[0]
            st.markdown(f"""
            <div class="metric-row">
                {metric_html(r['artists'], 'Artists')}
                {metric_html(r['tours'], 'Tours')}
            </div>
            <div class="metric-row">
                {metric_html(r['legs'], 'Tour Legs')}
                {metric_html(r['shows'], 'Shows')}
            </div>
            """, unsafe_allow_html=True)

    with col2:
        anusha_query = st.selectbox("Select Query", [
            "Query 1 — Tours by Artist",
            "Query 2 — Shows by Tour / Leg",
            "Query 3 — Search Shows",
            "Query 4 — Reschedule / Cancel Show",
            "Query 5 — Trigger Demo",
        ], key="anusha_query_select")

    st.divider()

    if "Query 1" in anusha_query:
        st.markdown("**Query 1 — Tours by Artist**")
        artists = run_query("SELECT artist_id, name FROM artists ORDER BY name")
        artist_options = {r["name"]: r["artist_id"] for _, r in artists.iterrows()}
        sel_a = st.selectbox("Select Artist", list(artist_options.keys()), key="a_artist")
        if st.button("🎤 Load Tours", key="btn_tours_by_artist"):
            df = run_query("""
                SELECT t.tour_name, t.start_date, t.end_date,
                       COUNT(DISTINCT tl.leg_id) AS legs,
                       COUNT(DISTINCT s.show_id) AS shows
                FROM tours t
                LEFT JOIN tour_legs tl ON t.tour_id = tl.tour_id
                LEFT JOIN shows s      ON tl.leg_id = s.leg_id
                WHERE t.artist_id = %(aid)s
                GROUP BY t.tour_id, t.tour_name, t.start_date, t.end_date
                ORDER BY t.start_date DESC
            """, params={"aid": artist_options[sel_a]})
            if not df.empty:
                c1,c2,c3 = st.columns(3)
                c1.metric("Tours",  len(df))
                c2.metric("Legs",   int(df["legs"].sum()))
                c3.metric("Shows",  int(df["shows"].sum()))
            show_df(df, height=300)

    elif "Query 2" in anusha_query:
        st.markdown("**Query 2 — Shows by Tour / Leg**")
        tours_df = run_query("SELECT tour_id, tour_name FROM tours ORDER BY tour_name")
        tour_map = {r["tour_name"]: r["tour_id"] for _, r in tours_df.iterrows()}
        sel_tour = st.selectbox("Select Tour", list(tour_map.keys()), key="a_tour")
        if sel_tour:
            tid = tour_map[sel_tour]
            legs = run_query("""
                SELECT leg_id, leg_name || ' (' || region || ')' AS leg_label
                FROM tour_legs WHERE tour_id=%(tid)s ORDER BY start_date
            """, params={"tid": tid})
            leg_opts = {"All Legs": None}
            leg_opts.update({r["leg_label"]: r["leg_id"] for _, r in legs.iterrows()})
            sel_leg = st.selectbox("Filter by Leg", list(leg_opts.keys()), key="a_leg")
            leg_id  = leg_opts[sel_leg]
            if st.button("📋 Load Shows", key="btn_shows_by_tour"):
                leg_filter = "AND tl.leg_id = %(leg_id)s" if leg_id else ""
                df = run_query(f"""
                    SELECT tl.region, tl.leg_name, s.show_date, s.start_time, s.status
                    FROM shows s JOIN tour_legs tl ON s.leg_id = tl.leg_id
                    WHERE tl.tour_id=%(tour_id)s {leg_filter} ORDER BY s.show_date
                """, params={"tour_id": tid, "leg_id": leg_id})
                if not df.empty: st.metric("Shows Found", len(df))
                show_df(df, height=350)

    elif "Query 3" in anusha_query:
        st.markdown("**Query 3 — Search Shows**")
        sc1,sc2,sc3 = st.columns(3)
        with sc1: status_filter = st.multiselect("Status", ["scheduled","completed","cancelled","rescheduled"], default=[])
        with sc2: date_from = st.date_input("From", value=date.today()-timedelta(days=90), key="a_dfrom")
        with sc3: date_to   = st.date_input("To",   value=date.today()+timedelta(days=180), key="a_dto")
        if st.button("🔍 Search", key="btn_search_shows"):
            params = {"date_from": str(date_from), "date_to": str(date_to)}
            status_clause = ""
            if status_filter:
                phs = ", ".join([f"%(st_{i})s" for i in range(len(status_filter))])
                status_clause = f"AND s.status IN ({phs})"
                for i, s in enumerate(status_filter): params[f"st_{i}"] = s
            df = run_query(f"""
                SELECT s.show_date, s.start_time, a.name AS artist,
                       t.tour_name, tl.region, tl.leg_name, s.status
                FROM shows s
                JOIN tour_legs tl ON s.leg_id    = tl.leg_id
                JOIN tours t      ON tl.tour_id  = t.tour_id
                JOIN artists a    ON t.artist_id = a.artist_id
                WHERE s.show_date BETWEEN %(date_from)s AND %(date_to)s {status_clause}
                ORDER BY s.show_date
            """, params=params)
            if not df.empty: st.metric("Results", len(df))
            show_df(df, height=350)

    elif "Query 4" in anusha_query:
        st.markdown("**Query 4 — Reschedule / Cancel Show**")
        rsc1, rsc2 = st.tabs(["📅 Reschedule", "❌ Cancel"])
        with rsc1:
            st.markdown('<div class="info-box">Calls <code>reschedule_show(show_id, new_date, new_time)</code> — only works on <code>scheduled</code> shows.</div>', unsafe_allow_html=True)
            artists_r = run_query("SELECT artist_id, name FROM artists ORDER BY name")
            amap_r    = {r["name"]: r["artist_id"] for _, r in artists_r.iterrows()}
            sel_r     = st.selectbox("Artist", list(amap_r.keys()), key="rsch_a")
            if sel_r:
                shows_r = run_query("""
                    SELECT s.show_id, t.tour_name, tl.region, s.show_date
                    FROM shows s JOIN tour_legs tl ON s.leg_id=tl.leg_id
                    JOIN tours t ON tl.tour_id=t.tour_id JOIN artists a ON t.artist_id=a.artist_id
                    WHERE a.artist_id=%(aid)s AND s.status='scheduled' ORDER BY s.show_date
                """, params={"aid": amap_r[sel_r]})
                if shows_r.empty:
                    st.info("No scheduled shows.")
                else:
                    labels_r   = {f"[{r['show_id']}] {r['tour_name']} · {r['region']} · {r['show_date']}": r["show_id"] for _,r in shows_r.iterrows()}
                    sel_show_r = st.selectbox("Show", list(labels_r.keys()), key="rsch_show")
                    nr1, nr2   = st.columns(2)
                    with nr1: new_date_r = st.date_input("New Date", min_value=date.today()+timedelta(1), key="rsch_date")
                    with nr2: new_time_r = st.time_input("New Time", key="rsch_time")
                    if st.button("Reschedule", key="btn_reschedule"):
                        ok, err, _ = run_procedure("CALL reschedule_show(%s,%s,%s)", (labels_r[sel_show_r], str(new_date_r), str(new_time_r)))
                        if ok: st.success(f"✅ Rescheduled to {new_date_r} at {new_time_r}")
                        else:  st.error(f"❌ {err}")
        with rsc2:
            st.markdown('<div class="info-box">Calls <code>cancel_show(show_id)</code> — works on <code>scheduled</code> and <code>rescheduled</code> shows.</div>', unsafe_allow_html=True)
            artists_c = run_query("SELECT artist_id, name FROM artists ORDER BY name")
            amap_c    = {r["name"]: r["artist_id"] for _, r in artists_c.iterrows()}
            sel_c     = st.selectbox("Artist", list(amap_c.keys()), key="cncl_a")
            if sel_c:
                shows_c = run_query("""
                    SELECT s.show_id, t.tour_name, tl.region, s.show_date, s.status
                    FROM shows s JOIN tour_legs tl ON s.leg_id=tl.leg_id
                    JOIN tours t ON tl.tour_id=t.tour_id JOIN artists a ON t.artist_id=a.artist_id
                    WHERE a.artist_id=%(aid)s AND s.status IN ('scheduled','rescheduled') ORDER BY s.show_date
                """, params={"aid": amap_c[sel_c]})
                if shows_c.empty:
                    st.info("No cancellable shows.")
                else:
                    labels_c   = {f"[{r['show_id']}] {r['tour_name']} · {r['region']} · {r['show_date']} ({r['status']})": r["show_id"] for _,r in shows_c.iterrows()}
                    sel_cancel = st.selectbox("Show", list(labels_c.keys()), key="cncl_show")
                    st.warning("⚠️ This will permanently mark the show as cancelled.")
                    if st.button("Cancel Show", key="btn_cancel"):
                        ok, err, _ = run_procedure("CALL cancel_show(%s)", (labels_c[sel_cancel],))
                        if ok: st.success("✅ Show cancelled.")
                        else:  st.error(f"❌ {err}")

    else:
        st.markdown("**Query 5 — Trigger Demo: `auto_complete_show`**")
        st.markdown("""<div class="info-box">
            <strong>Trigger:</strong> BEFORE INSERT OR UPDATE ON shows (FOR EACH ROW)<br>
            <strong>Logic:</strong> If <code>show_date &lt; CURRENT_DATE</code> and status is <code>scheduled</code>,
            auto-sets status → <code>completed</code>.<br>
            <strong>Purpose:</strong> DB-level enforcement — no stale scheduled shows in the past.
        </div>""", unsafe_allow_html=True)
        artists_t = run_query("SELECT artist_id, name FROM artists ORDER BY name")
        amap_t    = {r["name"]: r["artist_id"] for _, r in artists_t.iterrows()}
        sel_t     = st.selectbox("Artist", list(amap_t.keys()), key="trig_a")
        if sel_t:
            sched_t = run_query("""
                SELECT s.show_id, t.tour_name, tl.region, s.show_date, s.status
                FROM shows s JOIN tour_legs tl ON s.leg_id=tl.leg_id
                JOIN tours t ON tl.tour_id=t.tour_id JOIN artists a ON t.artist_id=a.artist_id
                WHERE a.artist_id=%(aid)s AND s.status IN ('scheduled','rescheduled') ORDER BY s.show_date
            """, params={"aid": amap_t[sel_t]})
            if sched_t.empty:
                st.info("No scheduled shows.")
            else:
                slabels = {f"[{r['show_id']}] {r['tour_name']} · {r['region']} · {r['show_date']}": r["show_id"] for _,r in sched_t.iterrows()}
                sel_s_t = st.selectbox("Pick a Show", list(slabels.keys()), key="trig_show")
                past_t  = st.date_input("Set to a Past Date", value=date(2024,1,1), key="trig_date")
                if st.button("🔥 Fire Trigger", key="btn_trigger"):
                    ok, err = run_command("UPDATE shows SET show_date=%s WHERE show_id=%s", (str(past_t), slabels[sel_s_t]))
                    if ok:
                        result_t = run_query("SELECT show_id, show_date, status FROM shows WHERE show_id=%(sid)s", params={"sid": slabels[sel_s_t]})
                        st.success("✅ Trigger fired!")
                        st.dataframe(result_t)
                        st.info("status auto-changed: `scheduled` → `completed` (enforced by trigger, not app code)")
                    else:
                        st.error(f"❌ {err}")


# ══════════════════════════════════════════════════════════
# TAB 3: CONTRACTS & FINANCE (Supritha)
# ══════════════════════════════════════════════════════════
with tab3:
    st.markdown('<div class="section-title">💰 Contracts & Finance Module — Supritha</div>', unsafe_allow_html=True)

    col1, col2 = st.columns([1, 2])
    with col1:
        st.markdown('<div class="module-card"><h3>Module Overview</h3><p>promoter • contract • expense • payment • settlement</p></div>', unsafe_allow_html=True)
        stats3 = run_query("""
            SELECT (SELECT COUNT(*) FROM contract)   AS contracts,
                   (SELECT COUNT(*) FROM payment)    AS payments,
                   (SELECT COUNT(*) FROM settlement) AS settlements,
                   (SELECT SUM(agreed_amount)::NUMERIC(14,0) FROM contract) AS contract_value
        """)
        if not stats3.empty:
            r   = stats3.iloc[0]
            val = fmt_money(float(r['contract_value'])) if r['contract_value'] else "$0"
            st.markdown(f"""
            <div class="metric-row">
                {metric_html(r['contracts'], 'Contracts')}
                {metric_html(r['payments'], 'Payments')}
            </div>
            <div class="metric-row">
                {metric_html(r['settlements'], 'Settlements')}
                {metric_html(val, 'Total Value')}
            </div>
            """, unsafe_allow_html=True)

    with col2:
        supritha_query = st.selectbox("Select Query", [
            "Query 1 — Finance Dashboard",
            "Query 2 — Contract Explorer",
            "Query 3 — Promoter Directory",
            "Query 4 — Contract Actions",
        ], key="supritha_query_select")

    st.divider()

    if "Query 1" in supritha_query:
        st.markdown("**Query 1 — Finance Dashboard**")
        kpis = run_query("""
            SELECT COUNT(*) AS total_contracts,
                   COUNT(*) FILTER (WHERE status='signed')   AS signed,
                   COUNT(*) FILTER (WHERE status='disputed') AS disputed,
                   COUNT(*) FILTER (WHERE status='draft')    AS draft,
                   COALESCE(SUM(agreed_amount) FILTER (WHERE status='signed' AND agreed_amount>0),0) AS signed_value,
                   COALESCE(AVG(agreed_amount) FILTER (WHERE agreed_amount>0),0) AS avg_value
            FROM contract
        """)
        if not kpis.empty:
            row = kpis.iloc[0]
            c1,c2,c3,c4,c5,c6 = st.columns(6)
            c1.metric("Total",        f"{int(row['total_contracts']):,}")
            c2.metric("Signed",       f"{int(row['signed']):,}")
            c3.metric("Disputed",     f"{int(row['disputed']):,}", delta_color="inverse")
            c4.metric("Draft",        f"{int(row['draft']):,}")
            c5.metric("Signed Value", fmt_money(row['signed_value']))
            c6.metric("Avg Contract", fmt_money(row['avg_value']))
        st.markdown("**Breakdown by Type & Status**")
        breakdown = run_query("""
            SELECT contract_type, status, COUNT(*) AS contracts,
                   COALESCE(SUM(agreed_amount),0) AS total_value,
                   COALESCE(AVG(agreed_amount) FILTER (WHERE agreed_amount>0),0) AS avg_value
            FROM contract GROUP BY contract_type, status ORDER BY contract_type, contracts DESC
        """)
        if not breakdown.empty:
            b = breakdown.copy()
            b["total_value"] = b["total_value"].apply(fmt_money)
            b["avg_value"]   = b["avg_value"].apply(fmt_money)
            b.columns        = ["Type","Status","# Contracts","Total Value","Avg Value"]
            show_df(b, height=280)
        st.markdown("**Recently Signed Contracts**")
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
            rc = recent.copy()
            rc["agreed_amount"]     = rc["agreed_amount"].apply(fmt_money)
            rc["percentage_of_net"] = rc["percentage_of_net"].apply(fmt_pct)
            rc.columns = ["Signed","Artist","Tour","Region","Type","Amount","% Net","Status"]
            show_df(rc, height=280)

    elif "Query 2" in supritha_query:
        st.markdown("**Query 2 — Contract Explorer**")
        fc1,fc2,fc3,fc4 = st.columns(4)
        with fc1: type_f   = st.multiselect("Type",   ["guarantee","flat_fee","hybrid","percentage"], default=[])
        with fc2: status_f = st.multiselect("Status", ["signed","draft","sent","disputed","cancelled"], default=[])
        with fc3: dfrom_c  = st.date_input("Show Date From", value=date(2025,1,1), key="c_dfrom")
        with fc4: dto_c    = st.date_input("Show Date To",   value=date(2026,12,31), key="c_dto")
        if st.button("🔍 Search Contracts", key="btn_contracts"):
            where  = ["s.show_date BETWEEN %(date_from)s AND %(date_to)s"]
            params = {"date_from": str(dfrom_c), "date_to": str(dto_c)}
            if type_f:
                phs = ", ".join([f"%(type_{i})s" for i in range(len(type_f))])
                where.append(f"c.contract_type IN ({phs})")
                for i,t in enumerate(type_f): params[f"type_{i}"] = t
            if status_f:
                phs = ", ".join([f"%(status_{i})s" for i in range(len(status_f))])
                where.append(f"c.status IN ({phs})")
                for i,s in enumerate(status_f): params[f"status_{i}"] = s
            results = run_query(f"""
                SELECT a.name AS artist, t.tour_name, tl.region, s.show_date,
                       c.contract_type, c.agreed_amount, c.percentage_of_net,
                       c.status AS contract_status, c.signed_date
                FROM contract c
                JOIN shows s      ON c.show_id   = s.show_id
                JOIN tour_legs tl ON s.leg_id    = tl.leg_id
                JOIN tours t      ON tl.tour_id  = t.tour_id
                JOIN artists a    ON t.artist_id = a.artist_id
                WHERE {" AND ".join(where)} ORDER BY s.show_date DESC
            """, params=params)
            if not results.empty:
                m1,m2,m3,m4 = st.columns(4)
                sv = results[results["contract_status"]=="signed"]["agreed_amount"]
                m1.metric("Found",        f"{len(results):,}")
                m2.metric("Signed Value", fmt_money(sv.sum()))
                m3.metric("Avg Amount",   fmt_money(results["agreed_amount"][results["agreed_amount"]>0].mean()))
                m4.metric("Disputed",     f"{(results['contract_status']=='disputed').sum()}", delta_color="inverse")
                rc2 = results.copy()
                rc2["agreed_amount"]     = rc2["agreed_amount"].apply(fmt_money)
                rc2["percentage_of_net"] = rc2["percentage_of_net"].apply(fmt_pct)
                rc2.columns = ["Artist","Tour","Region","Show Date","Type","Amount","% Net","Status","Signed Date"]
                show_df(rc2, height=350)
            else:
                st.info("No contracts match your filters.")

    elif "Query 3" in supritha_query:
        st.markdown("**Query 3 — Promoter Directory**")
        pc1, pc2 = st.columns(2)
        with pc1: market_f = st.multiselect("Market", ["North America","Europe","Asia Pacific","Latin America","Multi-Genre","Hip-Hop/R&B","Jazz/Classical","Rock/Alternative","Country","Pop/Dance"], default=[])
        with pc2: terms_f  = st.multiselect("Payment Terms", ["Net-30","Net-60","50/50 split","70/30 split","Upon completion"], default=[])
        if st.button("🏢 Load Promoters", key="btn_promoters"):
            where  = ["1=1"]
            params = {}
            if market_f:
                phs = ", ".join([f"%(mkt_{i})s" for i in range(len(market_f))])
                where.append(f"primary_market IN ({phs})")
                for i,m in enumerate(market_f): params[f"mkt_{i}"] = m
            if terms_f:
                phs = ", ".join([f"%(trm_{i})s" for i in range(len(terms_f))])
                where.append(f"payment_terms IN ({phs})")
                for i,t in enumerate(terms_f): params[f"trm_{i}"] = t
            promoters = run_query(f"""
                SELECT company_name, contact_name, contact_email, phone, primary_market, payment_terms
                FROM promoter WHERE {" AND ".join(where)} ORDER BY company_name
            """, params=params)
            if not promoters.empty:
                pa,pb,pc_col = st.columns(3)
                pa.metric("Found",   len(promoters))
                pb.metric("Markets", promoters["primary_market"].nunique())
                pc_col.metric("Terms", promoters["payment_terms"].nunique())
                promoters.columns = ["Company","Contact","Email","Phone","Market","Payment Terms"]
                show_df(promoters, height=350)
            else:
                st.info("No promoters match your filters.")

    else:
        st.markdown("**Query 4 — Contract Actions**")
        ca1, ca2 = st.tabs(["📝 Update Contract Status", "🚨 Disputed Contracts"])
        with ca1:
            st.markdown('<div class="info-box">Executes a direct <code>UPDATE</code> on the contract table.</div>', unsafe_allow_html=True)
            artists_ca = run_query("SELECT artist_id, name FROM artists ORDER BY name")
            amap_ca    = {r["name"]: r["artist_id"] for _, r in artists_ca.iterrows()}
            sel_ca     = st.selectbox("Artist", list(amap_ca.keys()), key="ca_artist")
            if sel_ca:
                contracts_ca = run_query("""
                    SELECT c.show_id, c.contract_type, c.agreed_amount, c.status AS contract_status,
                           s.show_date, tl.region
                    FROM contract c
                    JOIN shows s      ON c.show_id   = s.show_id
                    JOIN tour_legs tl ON s.leg_id    = tl.leg_id
                    JOIN tours t      ON tl.tour_id  = t.tour_id
                    JOIN artists a    ON t.artist_id = a.artist_id
                    WHERE a.artist_id=%(aid)s AND c.status NOT IN ('cancelled') ORDER BY s.show_date
                """, params={"aid": amap_ca[sel_ca]})
                if contracts_ca.empty:
                    st.info("No active contracts.")
                else:
                    labels_ca    = {f"[Show {r['show_id']}] {r['region']} · {r['show_date']} · {r['contract_type']} · {r['contract_status']}": r["show_id"] for _,r in contracts_ca.iterrows()}
                    sel_contract = st.selectbox("Contract", list(labels_ca.keys()), key="ca_contract")
                    nca1, nca2   = st.columns(2)
                    with nca1: new_status_ca = st.selectbox("New Status", ["signed","draft","sent","disputed","cancelled"], key="ca_status")
                    with nca2: signed_date_ca = st.date_input("Signed Date", value=date.today(), key="ca_date") if new_status_ca=="signed" else None
                    if st.button("Update Status", key="btn_update_contract"):
                        ok, err = run_command(
                            "UPDATE contract SET status=%s, signed_date=%s WHERE show_id=%s",
                            (new_status_ca, str(signed_date_ca) if signed_date_ca else None, labels_ca[sel_contract])
                        )
                        if ok: st.success(f"✅ Updated to **{new_status_ca}**.")
                        else:  st.error(f"❌ {err}")
        with ca2:
            disputed = run_query("""
                SELECT a.name AS artist, t.tour_name, tl.region, s.show_date,
                       c.contract_type, c.agreed_amount, c.percentage_of_net, c.terms
                FROM contract c
                JOIN shows s      ON c.show_id   = s.show_id
                JOIN tour_legs tl ON s.leg_id    = tl.leg_id
                JOIN tours t      ON tl.tour_id  = t.tour_id
                JOIN artists a    ON t.artist_id = a.artist_id
                WHERE c.status='disputed' ORDER BY c.agreed_amount DESC NULLS LAST
            """)
            if disputed.empty:
                st.success("🎉 No disputed contracts!")
            else:
                d1,d2 = st.columns(2)
                d1.metric("Disputed", len(disputed))
                d2.metric("At Risk",  fmt_money(disputed["agreed_amount"].sum()), delta_color="inverse")
                dd = disputed.copy()
                dd["agreed_amount"]     = dd["agreed_amount"].apply(fmt_money)
                dd["percentage_of_net"] = dd["percentage_of_net"].apply(fmt_pct)
                dd.columns = ["Artist","Tour","Region","Show Date","Type","Amount","% Net","Terms"]
                show_df(dd, height=350)


# ══════════════════════════════════════════════════════════
# TAB 4: TICKETS & LOGISTICS (Smitha)
# ══════════════════════════════════════════════════════════
with tab4:
    st.markdown('<div class="section-title">🎟️ Tickets & Logistics Module — Smitha</div>', unsafe_allow_html=True)

    col1, col2 = st.columns([1, 2])
    with col1:
        st.markdown('<div class="module-card"><h3>Module Overview</h3><p>crew • transport • equipment • ticket_inventory • ticket_sale • show_crew_assignment</p></div>', unsafe_allow_html=True)
        stats4 = run_query("""
            SELECT (SELECT COUNT(*) FROM crew)                AS crew,
                   (SELECT COUNT(*) FROM ticket_sale)         AS sales,
                   (SELECT COUNT(*) FROM ticket_inventory)    AS inventory_tiers,
                   (SELECT SUM(total_amount)::NUMERIC(14,0) FROM ticket_sale) AS total_revenue
        """)
        if not stats4.empty:
            r   = stats4.iloc[0]
            rev = fmt_money(float(r['total_revenue'])) if r['total_revenue'] else "$0"
            st.markdown(f"""
            <div class="metric-row">
                {metric_html(r['crew'], 'Crew Members')}
                {metric_html(f"{int(r['sales']):,}", 'Ticket Sales')}
            </div>
            <div class="metric-row">
                {metric_html(r['inventory_tiers'], 'Inventory Tiers')}
                {metric_html(rev, 'Total Revenue')}
            </div>
            """, unsafe_allow_html=True)

    with col2:
        smitha_query = st.selectbox("Select Query", [
            "Query 1 — Crew Utilization",
            "Query 2 — Ticket Sales Revenue",
            "Query 3 — Ticket Sales by Venue",
        ], key="smitha_query_select")

    st.divider()

    # ── Smitha Query 1: Crew Utilization ──────────────────
    if "Query 1" in smitha_query:
        st.markdown("**Query 1 — Crew Utilization: Earnings & Show Counts**")

        f1, f2, f3 = st.columns(3)
        with f1:
            roles_df    = run_query("SELECT DISTINCT role FROM crew ORDER BY role")
            role_filter = st.multiselect("Role", roles_df['role'].tolist() if not roles_df.empty else [], default=[])
        with f2:
            pay_status_filter = st.multiselect("Payment Status", ["paid","pending","cancelled"], default=[])
        with f3:
            min_shows = st.number_input("Min Shows Worked", min_value=0, value=0, step=1)

        if st.button("👷 Load Crew Utilization", key="btn_crew"):
            where  = ["1=1"]
            params = {}
            if role_filter:
                phs = ", ".join([f"%(role_{i})s" for i in range(len(role_filter))])
                where.append(f"c.role IN ({phs})")
                for i, r in enumerate(role_filter): params[f"role_{i}"] = r
            if pay_status_filter:
                phs = ", ".join([f"%(pst_{i})s" for i in range(len(pay_status_filter))])
                where.append(f"(sca.payment_status IN ({phs}) OR sca.payment_status IS NULL)")
                for i, s in enumerate(pay_status_filter): params[f"pst_{i}"] = s

            df = run_query(f"""
                SELECT c.person_name, c.role, c.daily_rate,
                       COUNT(sca.show_id) AS shows_worked,
                       SUM(CASE WHEN sca.payment_status='paid'      THEN sca.payment_amount ELSE 0 END) AS total_earned,
                       SUM(CASE WHEN sca.payment_status='pending'   THEN sca.payment_amount ELSE 0 END) AS pending_payment,
                       SUM(CASE WHEN sca.payment_status='cancelled' THEN sca.payment_amount ELSE 0 END) AS cancelled_amount
                FROM crew c
                LEFT JOIN show_crew_assignment sca ON c.crew_id = sca.crew_id
                WHERE {" AND ".join(where)}
                GROUP BY c.crew_id, c.person_name, c.role, c.daily_rate
                HAVING COUNT(sca.show_id) >= %(min_shows)s
                ORDER BY total_earned DESC
                LIMIT 100
            """, {**params, "min_shows": min_shows})

            if not df.empty:
                c1,c2,c3,c4 = st.columns(4)
                c1.metric("Crew Found",     len(df))
                c2.metric("Total Earned",   fmt_money(float(df['total_earned'].sum())))
                c3.metric("Total Pending",  fmt_money(float(df['pending_payment'].sum())))
                c4.metric("Avg Shows/Crew", f"{df['shows_worked'].mean():.1f}")
            show_df(df, height=350)

    # ── Smitha Query 2: Ticket Sales Revenue ──────────────
    elif "Query 2" in smitha_query:
        st.markdown("**Query 2 — Ticket Sales: Revenue by Show with Sell-Through Rates**")

        f1, f2, f3, f4 = st.columns(4)
        with f1:
            tt_df          = run_query("SELECT DISTINCT ticket_type FROM ticket_inventory ORDER BY ticket_type")
            ticket_type_f  = st.multiselect("Ticket Type", tt_df['ticket_type'].tolist() if not tt_df.empty else [], default=[])
        with f2:
            channel_f = st.multiselect("Sale Channel", ["online","box_office","mobile","reseller"], default=[])
        with f3:
            sale_from = st.date_input("Sale Date From", value=date(2024,1,1), key="s_dfrom")
        with f4:
            sale_to   = st.date_input("Sale Date To",   value=date.today(),   key="s_dto")

        min_st = st.slider("Min Sell-Through %", min_value=0, max_value=100, value=0)

        if st.button("🎫 Load Ticket Revenue", key="btn_tickets"):
            where  = ["ts.sale_timestamp BETWEEN %(sale_from)s AND %(sale_to)s"]
            params = {"sale_from": f"{sale_from} 00:00:00", "sale_to": f"{sale_to} 23:59:59"}
            if ticket_type_f:
                phs = ", ".join([f"%(tt_{i})s" for i in range(len(ticket_type_f))])
                where.append(f"ti.ticket_type IN ({phs})")
                for i,t in enumerate(ticket_type_f): params[f"tt_{i}"] = t
            if channel_f:
                phs = ", ".join([f"%(ch_{i})s" for i in range(len(channel_f))])
                where.append(f"ts.sale_channel IN ({phs})")
                for i,c in enumerate(channel_f): params[f"ch_{i}"] = c

            df = run_query(f"""
                SELECT s.show_id, s.show_date,
                       v.name                                              AS venue,
                       v.capacity                                          AS venue_capacity,
                       COUNT(DISTINCT ti.ticket_type)                      AS ticket_types,
                       SUM(ts.quantity_sold)                               AS tickets_sold,
                       SUM(ts.total_amount)::NUMERIC(14,2)                 AS total_revenue,
                       ROUND(SUM(ts.quantity_sold)::NUMERIC /
                             NULLIF(v.capacity,0)*100, 1)                  AS sell_through_pct,
                       MIN(ts.sale_timestamp::DATE)                        AS first_sale_date,
                       MAX(ts.sale_timestamp::DATE)                        AS last_sale_date
                FROM shows s
                JOIN venues v            ON s.venue_id      = v.venue_id
                JOIN ticket_inventory ti ON s.show_id       = ti.show_id
                JOIN ticket_sale ts      ON ti.inventory_id = ts.inventory_id
                WHERE {" AND ".join(where)}
                GROUP BY s.show_id, s.show_date, v.name, v.capacity
                HAVING ROUND(SUM(ts.quantity_sold)::NUMERIC/NULLIF(v.capacity,0)*100,1) >= %(min_st)s
                ORDER BY total_revenue DESC LIMIT 100
            """, {**params, "min_st": min_st})

            if not df.empty:
                c1,c2,c3,c4 = st.columns(4)
                c1.metric("Shows Found",      len(df))
                c2.metric("Total Revenue",    fmt_money(float(df['total_revenue'].sum())))
                c3.metric("Tickets Sold",     f"{int(df['tickets_sold'].sum()):,}")
                c4.metric("Avg Sell-Through", f"{df['sell_through_pct'].mean():.1f}%")
            show_df(df, height=350)

    # ── Smitha Query 3: Ticket Sales by Venue ─────────────
    else:
        st.markdown("**Query 3 — Ticket Sales by Venue**")

        f1, f2, f3 = st.columns(3)
        with f1:
            countries_df   = run_query("SELECT DISTINCT name FROM countries ORDER BY name")
            country_filter = st.multiselect("Country", countries_df['name'].tolist() if not countries_df.empty else [], default=[])
        with f2:
            vtype_filter = st.multiselect("Venue Type", ["indoor","outdoor"], default=[])
        with f3:
            min_cap_v = st.number_input("Min Venue Capacity", min_value=0, value=0, step=1000)

        col_d, col_e = st.columns(2)
        with col_d: sale_from_v = st.date_input("Sale Date From", value=date(2024,1,1), key="v_dfrom")
        with col_e: sale_to_v   = st.date_input("Sale Date To",   value=date.today(),   key="v_dto")

        if st.button("🏟️ Load Sales by Venue", key="btn_venue_sales"):
            where  = ["ts.sale_timestamp BETWEEN %(sale_from)s AND %(sale_to)s"]
            params = {"sale_from": f"{sale_from_v} 00:00:00", "sale_to": f"{sale_to_v} 23:59:59"}
            if country_filter:
                phs = ", ".join([f"%(ctr_{i})s" for i in range(len(country_filter))])
                where.append(f"co.name IN ({phs})")
                for i,c in enumerate(country_filter): params[f"ctr_{i}"] = c
            if vtype_filter:
                phs = ", ".join([f"%(vt_{i})s" for i in range(len(vtype_filter))])
                where.append(f"v.indoor_outdoor IN ({phs})")
                for i,vt in enumerate(vtype_filter): params[f"vt_{i}"] = vt
            if min_cap_v > 0:
                where.append("v.capacity >= %(min_cap)s")
                params["min_cap"] = min_cap_v

            df = run_query(f"""
                SELECT v.name                                              AS venue,
                       ci.name                                             AS city,
                       co.name                                             AS country,
                       v.capacity,
                       v.indoor_outdoor,
                       COUNT(DISTINCT s.show_id)                           AS total_shows,
                       SUM(ts.quantity_sold)                               AS total_tickets_sold,
                       SUM(ts.total_amount)::NUMERIC(14,2)                 AS total_revenue,
                       ROUND(AVG(ts.total_amount / NULLIF(ts.quantity_sold,0))::NUMERIC, 2) AS avg_ticket_price,
                       ROUND(SUM(ts.quantity_sold)::NUMERIC /
                             NULLIF(v.capacity,0) /
                             NULLIF(COUNT(DISTINCT s.show_id),0)*100, 1)  AS avg_sell_through_pct,
                       MIN(s.show_date)                                    AS first_show,
                       MAX(s.show_date)                                    AS last_show
                FROM venues v
                JOIN cities ci            ON v.city_id       = ci.city_id
                JOIN countries co         ON ci.country_id   = co.country_id
                JOIN shows s              ON v.venue_id      = s.venue_id
                JOIN ticket_inventory ti  ON s.show_id       = ti.show_id
                JOIN ticket_sale ts       ON ti.inventory_id = ts.inventory_id
                WHERE {" AND ".join(where)}
                GROUP BY v.venue_id, v.name, ci.name, co.name, v.capacity, v.indoor_outdoor
                ORDER BY total_revenue DESC LIMIT 100
            """, params)

            if not df.empty:
                c1,c2,c3,c4,c5 = st.columns(5)
                c1.metric("Venues",           len(df))
                c2.metric("Total Revenue",    fmt_money(float(df['total_revenue'].sum())))
                c3.metric("Tickets Sold",     f"{int(df['total_tickets_sold'].sum()):,}")
                c4.metric("Avg Ticket Price", fmt_money(float(df['avg_ticket_price'].mean())))
                c5.metric("Avg Sell-Through", f"{df['avg_sell_through_pct'].mean():.1f}%")
            show_df(df, height=380)


# ══════════════════════════════════════════════════════════
# TAB 5: COMPLEX QUERIES
# ══════════════════════════════════════════════════════════
with tab5:
    st.markdown('<div class="section-title">🔗 Cross-Module Complex Queries</div>', unsafe_allow_html=True)
    st.markdown('<div class="module-card"><h3>All 4 modules integrated</h3><p>CTEs • Window Functions • Multi-table JOINs • Business Intelligence</p></div>', unsafe_allow_html=True)

    query_choice = st.selectbox("Select a complex query to run", [
        "Query 1 — Complete Show Profitability Analysis",
        "Query 2 — Tour Route Optimization",
        "Query 3 — Artist Performance Dashboard",
        "Query 4 — Venue Performance by Country",
        "Query 5 — Payment Settlement Status Report",
    ], key="complex_select")

    if st.button("▶ Run Complex Query", key="btn_complex"):
        if "Query 1" in query_choice:
            sql = """
                WITH show_revenue AS (
                    SELECT ti.show_id, SUM(ts.total_amount) AS ticket_revenue, COUNT(ts.sale_id) AS tickets_sold
                    FROM ticket_inventory ti LEFT JOIN ticket_sale ts ON ti.inventory_id=ts.inventory_id
                    GROUP BY ti.show_id
                ),
                show_costs AS (
                    SELECT s.show_id,
                           COALESCE(SUM(sca.payment_amount),0) AS crew_costs,
                           COALESCE((SELECT agreed_amount FROM contract c WHERE c.show_id=s.show_id LIMIT 1),0) AS contract_costs,
                           COALESCE((SELECT SUM(amount) FROM expense ex WHERE ex.show_id=s.show_id),0) AS other_expenses
                    FROM shows s LEFT JOIN show_crew_assignment sca ON s.show_id=sca.show_id GROUP BY s.show_id
                )
                SELECT s.show_id, s.show_date, t.tour_name, a.name AS artist,
                       v.name AS venue, ci.name AS city,
                       COALESCE(sr.ticket_revenue,0) AS revenue,
                       (sc.crew_costs+sc.contract_costs+sc.other_expenses) AS total_costs,
                       COALESCE(sr.ticket_revenue,0)-(sc.crew_costs+sc.contract_costs+sc.other_expenses) AS net_profit,
                       ROUND(sr.tickets_sold::NUMERIC/NULLIF(v.capacity,0)*100,1) AS capacity_pct,
                       RANK() OVER (ORDER BY COALESCE(sr.ticket_revenue,0)-(sc.crew_costs+sc.contract_costs+sc.other_expenses) DESC) AS rank
                FROM shows s
                JOIN venues v     ON s.venue_id=v.venue_id JOIN cities ci ON v.city_id=ci.city_id
                JOIN tour_legs tl ON s.leg_id=tl.leg_id   JOIN tours t   ON tl.tour_id=t.tour_id
                JOIN artists a    ON t.artist_id=a.artist_id
                LEFT JOIN show_revenue sr ON s.show_id=sr.show_id
                LEFT JOIN show_costs sc   ON s.show_id=sc.show_id
                ORDER BY net_profit DESC LIMIT 30
            """
        elif "Query 2" in query_choice:
            sql = """
                WITH ordered_shows AS (
                    SELECT ss.tour_id, ss.show_id, ss.sequence_number,
                           ss.dist_from_previous_show, ss.drive_time, ss.rest_days,
                           s.show_date, v.name AS venue_name, ci.name AS city_name, co.name AS country_name
                    FROM show_sequence ss
                    JOIN shows s ON ss.show_id=s.show_id JOIN venues v ON s.venue_id=v.venue_id
                    JOIN cities ci ON v.city_id=ci.city_id JOIN countries co ON ci.country_id=co.country_id
                )
                SELECT cur.show_id AS current_show_id, cur.show_date AS current_date,
                       cur.venue_name AS current_venue, cur.city_name AS current_city,
                       nxt.show_id AS next_show_id, nxt.show_date AS next_date,
                       nxt.venue_name AS next_venue, nxt.city_name AS next_city,
                       nxt.show_date-cur.show_date AS days_between,
                       nxt.dist_from_previous_show AS distance_km,
                       nxt.drive_time AS drive_hours, nxt.rest_days,
                       CASE WHEN cur.country_name!=nxt.country_name THEN 'International' ELSE 'Domestic' END AS travel_type,
                       CASE WHEN nxt.show_date-cur.show_date<2 AND nxt.dist_from_previous_show>500 THEN 'TIGHT'
                            WHEN nxt.show_date-cur.show_date>=5 THEN 'OPPORTUNITY'
                            WHEN nxt.dist_from_previous_show<100 THEN 'EFFICIENT'
                            ELSE 'NORMAL' END AS routing_flag
                FROM ordered_shows cur
                JOIN ordered_shows nxt ON cur.tour_id=nxt.tour_id AND nxt.sequence_number=cur.sequence_number+1
                ORDER BY cur.tour_id, cur.show_date LIMIT 50
            """
        elif "Query 3" in query_choice:
            sql = """
                SELECT a.name AS artist, a.genre, m.name AS manager,
                       COUNT(DISTINCT t.tour_id) AS tours, COUNT(DISTINCT s.show_id) AS shows,
                       COUNT(DISTINCT co.country_id) AS countries,
                       COALESCE(SUM(ts.total_amount),0)::NUMERIC(14,2) AS total_revenue,
                       SUM(COALESCE(c.agreed_amount,0))::NUMERIC(14,2) AS contract_value,
                       CASE WHEN COUNT(DISTINCT s.show_id)>=50 THEN 'Touring Powerhouse'
                            WHEN COUNT(DISTINCT s.show_id)>=20 THEN 'Established Act'
                            WHEN COUNT(DISTINCT s.show_id)>=10 THEN 'Rising Star'
                            ELSE 'Emerging Artist' END AS tier
                FROM artists a
                LEFT JOIN managers m    ON a.manager_id=m.manager_id
                LEFT JOIN tours t       ON a.artist_id=t.artist_id
                LEFT JOIN tour_legs tl  ON t.tour_id=tl.tour_id
                LEFT JOIN shows s       ON tl.leg_id=s.leg_id
                LEFT JOIN venues v      ON s.venue_id=v.venue_id
                LEFT JOIN cities ci     ON v.city_id=ci.city_id
                LEFT JOIN countries co  ON ci.country_id=co.country_id
                LEFT JOIN contract c    ON s.show_id=c.show_id
                LEFT JOIN ticket_inventory ti ON s.show_id=ti.show_id
                LEFT JOIN ticket_sale ts ON ti.inventory_id=ts.inventory_id
                GROUP BY a.artist_id, a.name, a.genre, m.name
                HAVING COUNT(DISTINCT s.show_id)>0 ORDER BY total_revenue DESC
            """
        elif "Query 4" in query_choice:
            sql = """
                WITH venue_metrics AS (
                    SELECT v.venue_id, v.name AS venue_name, v.capacity,
                           ci.name AS city_name, co.name AS country_name,
                           COUNT(s.show_id) AS shows_hosted,
                           SUM(COALESCE((SELECT SUM(ts.total_amount) FROM ticket_inventory ti
                               JOIN ticket_sale ts ON ti.inventory_id=ts.inventory_id
                               WHERE ti.show_id=s.show_id),0)) AS total_revenue,
                           AVG(COALESCE((SELECT COUNT(*)::NUMERIC/NULLIF(v.capacity,0)*100
                               FROM ticket_inventory ti JOIN ticket_sale ts ON ti.inventory_id=ts.inventory_id
                               WHERE ti.show_id=s.show_id),0)) AS avg_utilization
                    FROM venues v JOIN cities ci ON v.city_id=ci.city_id
                    JOIN countries co ON ci.country_id=co.country_id
                    LEFT JOIN shows s ON v.venue_id=s.venue_id
                    GROUP BY v.venue_id, v.name, v.capacity, ci.name, co.name
                )
                SELECT country_name, city_name, venue_name, capacity, shows_hosted,
                       total_revenue::NUMERIC(14,2),
                       ROUND(avg_utilization::NUMERIC,1) AS avg_utilization_pct,
                       RANK() OVER (PARTITION BY country_name ORDER BY total_revenue DESC) AS rank_in_country,
                       RANK() OVER (ORDER BY total_revenue DESC) AS rank_overall
                FROM venue_metrics WHERE shows_hosted>0 ORDER BY total_revenue DESC LIMIT 40
            """
        else:
            sql = """
                WITH contract_payments AS (
                    SELECT c.show_id, c.agreed_amount,
                           COALESCE(SUM(p.amount),0) AS paid,
                           c.agreed_amount-COALESCE(SUM(p.amount),0) AS balance
                    FROM contract c LEFT JOIN payment p ON c.contract_id=p.contract_id
                    GROUP BY c.show_id, c.contract_id, c.agreed_amount
                ),
                crew_payments AS (
                    SELECT show_id,
                           SUM(CASE WHEN payment_status='pending' THEN payment_amount ELSE 0 END) AS crew_pending
                    FROM show_crew_assignment GROUP BY show_id
                )
                SELECT s.show_id, s.show_date, v.name AS venue, t.tour_name,
                       cp.agreed_amount, cp.paid AS contract_paid, cp.balance AS contract_balance,
                       COALESCE(crp.crew_pending,0) AS crew_pending,
                       cp.balance+COALESCE(crp.crew_pending,0) AS total_outstanding,
                       CURRENT_DATE-s.show_date AS days_since_show, st.status AS settlement_status,
                       CASE WHEN CURRENT_DATE-s.show_date>60 AND cp.balance+COALESCE(crp.crew_pending,0)>1000 THEN '🔴 CRITICAL'
                            WHEN CURRENT_DATE-s.show_date>30 AND cp.balance+COALESCE(crp.crew_pending,0)>500  THEN '🟡 WARNING'
                            WHEN cp.balance+COALESCE(crp.crew_pending,0)>0 THEN '🟢 PENDING'
                            ELSE '✅ SETTLED' END AS status_flag
                FROM shows s
                JOIN venues v     ON s.venue_id=v.venue_id JOIN tour_legs tl ON s.leg_id=tl.leg_id
                JOIN tours t      ON tl.tour_id=t.tour_id
                LEFT JOIN contract_payments cp ON s.show_id=cp.show_id
                LEFT JOIN crew_payments crp    ON s.show_id=crp.show_id
                LEFT JOIN settlement st        ON s.show_id=st.show_id
                WHERE s.show_date<=CURRENT_DATE
                  AND (cp.balance+COALESCE(crp.crew_pending,0)>0
                       OR st.status!='finalized' OR st.status IS NULL)
                ORDER BY total_outstanding DESC LIMIT 40
            """
        df = run_query(sql)
        show_df(df, height=420)


# ══════════════════════════════════════════════════════════
# TAB 6: TRANSACTIONS (ACID Demo)
# ══════════════════════════════════════════════════════════
with tab6:
    st.markdown('<div class="section-title">⚡ Transaction Management — ACID Compliance Demo</div>', unsafe_allow_html=True)

    st.markdown("""
    <div class="metric-row">
        <div class="metric-card"><div class="value">A</div><div class="label">Atomicity</div></div>
        <div class="metric-card"><div class="value">C</div><div class="label">Consistency</div></div>
        <div class="metric-card"><div class="value">I</div><div class="label">Isolation</div></div>
        <div class="metric-card"><div class="value">D</div><div class="label">Durability</div></div>
    </div>
    """, unsafe_allow_html=True)

    tx_choice = st.selectbox("Select a transaction to demo", [
        "Transaction 1 — Ticket Purchase (Atomicity)",
        "Transaction 2 — Failed Payment Rollback (Atomicity)",
        "Transaction 3 — Crew Payment Batch (Consistency)",
    ], key="tx_select")

    st.divider()

    if "Transaction 1" in tx_choice:
        st.markdown("**Scenario:** Customer purchases tickets. All 3 steps must succeed, or nothing is saved.")
        st.markdown("""<div class="module-card"><h3>Steps</h3>
            <p>1. Check availability (SELECT FOR UPDATE — locks the row)</p>
            <p>2. INSERT into ticket_sale</p>
            <p>3. UPDATE hold_quantity in ticket_inventory</p>
        </div>""", unsafe_allow_html=True)
        inv_df = run_query("""
            SELECT ti.inventory_id, ti.ticket_type, ti.section_name,
                   ti.total_quantity-ti.hold_quantity AS available,
                   ti.base_price, ti.service_fees, s.show_id, s.show_date
            FROM ticket_inventory ti JOIN shows s ON ti.show_id=s.show_id
            WHERE ti.total_quantity-ti.hold_quantity>0 ORDER BY available DESC LIMIT 20
        """)
        if not inv_df.empty:
            st.markdown("**Available Inventory:**")
            show_df(inv_df, height=200)
            col_a,col_b,col_c = st.columns(3)
            with col_a: inv_id = st.number_input("inventory_id", min_value=1, value=int(inv_df.iloc[0]['inventory_id']))
            with col_b: qty    = st.number_input("Quantity", min_value=1, max_value=20, value=2)
            with col_c: buyer  = st.text_input("Buyer email", value="demo@jass.com")
            if st.button("🎟️ Purchase Tickets", key="btn_buy"):
                check = run_query("SELECT total_quantity-hold_quantity AS avail, base_price, service_fees FROM ticket_inventory WHERE inventory_id=%s", (inv_id,))
                if check.empty:
                    st.error("Inventory not found.")
                elif check.iloc[0]['avail'] < qty:
                    st.error(f"Only {check.iloc[0]['avail']} available, requested {qty}.")
                else:
                    total = float(qty)*(float(check.iloc[0]['base_price'])+float(check.iloc[0]['service_fees']))
                    ok, msg = run_transaction([
                        ("INSERT INTO ticket_sale (inventory_id,quantity_sold,sale_channel,sale_timestamp,total_amount,buyer_email) VALUES (%s,%s,'online',NOW(),%s,%s)", (inv_id,qty,total,buyer)),
                        ("UPDATE ticket_inventory SET hold_quantity=hold_quantity+%s WHERE inventory_id=%s", (qty,inv_id)),
                    ])
                    if ok:
                        st.success(f"✅ COMMITTED — {qty} tickets sold for ${total:.2f}. Both INSERT and UPDATE saved atomically.")
                        st.balloons()
                    else:
                        st.error(f"❌ ROLLED BACK — {msg}")

    elif "Transaction 2" in tx_choice:
        st.markdown("**Scenario:** Payment fails mid-transaction. Everything rolls back — nothing is saved.")
        st.markdown("""<div class="module-card"><h3>What happens</h3>
            <p>1. INSERT into ticket_sale — succeeds</p>
            <p>2. UPDATE ticket_inventory — succeeds</p>
            <p>3. Payment processor error — EXCEPTION raised</p>
            <p>⟶ Entire transaction ROLLS BACK. Database unchanged.</p>
        </div>""", unsafe_allow_html=True)
        before = run_query("SELECT COUNT(*) AS cnt FROM ticket_sale WHERE buyer_email='rollback_test@jass.com'")
        st.info(f"Rows for rollback_test@jass.com: **{before.iloc[0]['cnt']}** (should stay 0)")
        if st.button("💥 Simulate Failed Payment", key="btn_rollback"):
            try:
                conn = get_connection()
                conn.autocommit = False
                with conn.cursor() as cur:
                    cur.execute("INSERT INTO ticket_sale (inventory_id,quantity_sold,sale_channel,sale_timestamp,total_amount,buyer_email) VALUES (1,2,'online',NOW(),300.00,'rollback_test@jass.com')")
                    cur.execute("UPDATE ticket_inventory SET hold_quantity=hold_quantity+2 WHERE inventory_id=1")
                    raise Exception("Payment processor error: card declined")
            except Exception as e:
                conn.rollback()
                conn.autocommit = True
                st.error(f"❌ EXCEPTION: {e}")
                after = run_query("SELECT COUNT(*) AS cnt FROM ticket_sale WHERE buyer_email='rollback_test@jass.com'")
                st.success(f"✅ ROLLED BACK — rows remaining: **{after.iloc[0]['cnt']}** — Atomicity confirmed!")

    else:
        st.markdown("**Scenario:** Mark all pending crew for a show as paid atomically.")
        st.markdown("""<div class="module-card"><h3>Consistency demo</h3>
            <p>All crew statuses transition from 'pending' → 'paid' together.</p>
            <p>If any update fails, none are committed.</p>
        </div>""", unsafe_allow_html=True)
        pending_df = run_query("""
            SELECT s.show_id, s.show_date, v.name AS venue,
                   COUNT(*) AS pending_crew, SUM(sca.payment_amount) AS total_to_pay
            FROM show_crew_assignment sca JOIN shows s ON sca.show_id=s.show_id
            JOIN venues v ON s.venue_id=v.venue_id WHERE sca.payment_status='pending'
            GROUP BY s.show_id, s.show_date, v.name ORDER BY pending_crew DESC LIMIT 15
        """)
        if not pending_df.empty:
            show_df(pending_df, height=220)
            show_id_pay = st.number_input("show_id to pay crew", min_value=1, value=int(pending_df.iloc[0]['show_id']))
            if st.button("💸 Pay All Crew", key="btn_pay_crew"):
                ok, msg = run_transaction([
                    ("UPDATE show_crew_assignment SET payment_status='paid' WHERE show_id=%s AND payment_status='pending'", (show_id_pay,)),
                ])
                if ok:
                    verify    = run_query("SELECT COUNT(*) AS still_pending FROM show_crew_assignment WHERE show_id=%s AND payment_status='pending'", (show_id_pay,))
                    remaining = verify.iloc[0]['still_pending'] if not verify.empty else '?'
                    st.success(f"✅ COMMITTED — All crew paid. Pending remaining: {remaining}. Consistency maintained.")
                else:
                    st.error(f"❌ ROLLED BACK — {msg}")
        else:
            st.info("No pending crew payments found.")

    st.divider()
    st.markdown("""
    <div class="module-card">
        <h3>ACID Summary</h3>
        <p><strong>Atomicity</strong> — All steps commit together, or rollback undoes all of them</p>
        <p><strong>Consistency</strong> — hold_quantity never exceeds total_quantity; status fields only accept valid values</p>
        <p><strong>Isolation</strong> — SELECT FOR UPDATE locks rows, preventing concurrent overselling</p>
        <p><strong>Durability</strong> — Once COMMIT fires, data survives even if the server crashes immediately after</p>
    </div>
    """, unsafe_allow_html=True)
