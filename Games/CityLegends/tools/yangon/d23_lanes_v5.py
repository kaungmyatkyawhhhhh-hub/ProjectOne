"""Yangon main roads v5 (14 Nov 2026, owner: "some are 4 lane and 6 lane and 2 lane but ingame theyre different"):
every main road gets its REAL lane count and, where the real road is divided, a raised median.

Reads imports/refs/map/ygn_roads_v4.json (d18_widen.py) and the OpenStreetMap roads in build/osm_ygn/roads.json
({id, t: tags, p: [[lon, lat], ...]}), writes imports/refs/map/ygn_roads_v5.json and the Studio modules
build/yangon_v5/Roads3_1..N.luau (YangonData.Roads3_*, each under 190,000 characters).

Lanes and medians (the design of build/plan/roads.md: one road record, the median inside it):
  * For every sample of every `route` road the real road under it is found: the nearest OSM highway centre lines of
    class tertiary or bigger within 60 studs that run the same way. A two-way way nearest = undivided (lanes each
    way = lanes:forward, else lanes / 2); two one-way ways (one each way) = divided (lanes each way = their `lanes`);
    the game's centre line lies between them. Lanes each way are clamped to 2..3 (4+ becomes 3; a main road is
    never 1 + 1, that is a street), unknown = 2.
  * Smoothed into sections (no section shorter than MIN_SEC studs: the shortest is merged into its longer
    neighbour), then a few decided overrides (OVERRIDES: satellite checks, the decks and their approaches).
  * Widths: 2-lane sides 16-stud lanes, 3-lane sides 13-stud lanes, median half MEDIAN (3, kerbs included) on
    divided sections: half = median + lanes * laneW (undivided 2+2: 32, divided 2+2: 35, divided 3+3: 42).
    Widths ease over EASE (128) studs at a section change (half of the shorter section at most); a section change
    inside a cut run (a deck, the Kabar Aye split) is a plain step, nothing of it is built.
  * The loop's gores (d7_flyovers.py widened it to 60 where the side lanes leave and join it): there the lane
    geometry eases onto the deck's 2+2 (median 0, 16-stud lanes) with the third lane running out towards the side
    lane, so the deck and both side lanes still start square on the loop's unchanged wide end (60).
  * Per-sample fields (0-based, after the 8 old ones): s[8] = the BUILT median half (0 where it is open), s[9] =
    lanes per side, s[10] = lane width, s[11] = the lane geometry's median half (lanes sit at s[11] + w*(k-0.5),
    w = min(s[10], (half - s[11]) / s[9])). s[6] / s[7] = the outer carriageway edges, as before.
  * The built median is open (s[8] = 0, eased over NOSE studs to a nose) where: the sample or its neighbour is cut;
    within OPEN_RING of the roundabout's centre; another route or side lane's centre line (where traffic links
    cross) is within its half + OPEN_R; the loop is widened at a gore. Streets (1+1, no traffic lanes) keep the
    median closed (OPEN_AT_STREETS): left-in / left-out only, as in real Yangon. Median runs under MIN_MEDIAN studs
    are left out.
  * Road-level fields: lanes (most lanes per side), median (median half where divided, else 0), laneW (the lane
    width of the longest section).

Run from Games/CityLegends:  python tools/yangon/d23_lanes_v5.py
Then: d9_lanes.py (reads v5), and in Studio the YangonData.Roads3_* modules + step 5 (see the CLAUDE.md note).
"""
import collections, json, math, os, re, sys

sys.stdout.reconfigure(encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
MAP = os.path.join(ROOT, 'imports', 'refs', 'map')
OUT_DIR = os.path.join(ROOT, 'build', 'yangon_v5')
NL = chr(10)

KX = 111320 * math.cos(math.radians(16.82))
KY = 110540
SEARCH = 60.0          # studs: OSM centre lines this near a sample count
BIG = {'trunk', 'primary', 'secondary', 'tertiary'}
MIN_SEC = 200.0        # studs: no section shorter
EASE = 128.0           # studs: widths eased over this at a section change
MEDIAN = 3.0           # median half (kerbs included) on a divided section
LANE_W = {2: 16.0, 3: 13.0}
GORE_W = 16.0          # the deck's lane width (the gores ease onto it)
OPEN_R = 14.0          # a median opens where another route's centre line is within its half + this
C = (29072.0, 1172.8)  # the roundabout's centre (YangonRoads.M.C)
OPEN_RING = 108.0 + 12.0 + 30.0   # R_OUT + FLAT + 30
NOSE = 19.2            # studs: a median eases to 0 over this into an opening
MIN_MEDIAN = 40.0      # studs: shorter median runs are left out
OPEN_AT_STREETS = False
RING_2LANE = 230.0     # studs from the roundabout's centre: the arms are 2+2 (the arms sit close together)
CHUNK = 185000         # characters of JSON per Studio module (+ the wrapper: under 190,000)

# decided overrides: (from sample, to sample (inclusive, None = the end), lanes, divided, why); 0-based samples
OVERRIDES = {
    'No.1 Industrial Road': [(0, None, 2, True, 'satellite check: divided, 2 each way, tree-lined median (OSM says 2-3)')],
    # (OSM has a one-way pair tagged lanes=4 for its first 500 studs: the Hledan junction approach, 9 m apart, so the
    # 4 is the road's total. That stretch is also d7's carry-on under the Pyay deck and across the Pyay side lanes)
    'University Avenue': [(0, None, 2, False, 'undivided 2+2 (its Hledan-end one-way pair is the junction approach)')],
}

# ---------------------------------------------------------------------------------------------------- data
d = json.load(open(os.path.join(MAP, 'ygn_roads_v4.json'), encoding='utf-8'))
R = {r['name']: r for r in d['roads']}
CUT = {k: set(v) for k, v in d['cut'].items()}
DECKS = {dk['name']: dk for dk in d['decks']}


def chain(s):
    c = [0.0]
    for k in range(1, len(s)):
        c.append(c[-1] + math.hypot(s[k][0] - s[k - 1][0], s[k][2] - s[k - 1][2]))
    return c


def smooth(u):
    u = min(max(u, 0.0), 1.0)
    return u * u * (3 - 2 * u)


# ---------------------------------------------------------------------------------------------------- the decks
# (owner, 14 Nov: "i think the overhead bridges are too low") a real Yangon flyover clears about 5.5-6 m: 17 studs at
# the cars' 3 studs a metre, from the LOWEST part of the deck (the girder's underside: surface - SLAB 2 - GIRDER 3,
# YangonRoads.buildDecks) to the road under it. Every point of every road's carriageway under a deck's footprint
# (32 either side of its centre line) must have the deck surface at least DECK_NEED over it.
# * Pyay Road Flyover: only University Avenue passes under. Its old profile stays; a hump of DECK_GRADE eases it up
#   over University Avenue (the rest of the deck is unchanged).
# * Kabar Aye Flyover: the Kabar Aye east lane and New University Avenue Road pass under it 190 studs before its
#   landing on the loop, which would need a 12.7% ramp. Its landing moves further along the loop (onto the loop's own
#   line, before No.1 Industrial Road's junction), so the ramp down stays at DECK_GRADE: the loop is cut further, the
#   two Kabar Aye side lanes run on to the new landing (d7_flyovers.py's lane geometry, re-made here) and the loop's
#   widened join moves with it. New profile: up from New Road at DECK_GRADE, level over the side lane, down at
#   DECK_GRADE, parabolic vertical curves (VCURVE studs) at both feet.
DECK_NEED = 17.0 + 2.0 + 3.0 + 0.3   # clearance + slab + girder + a margin
DECK_GRADE = 0.075
VCURVE = 48.0
SLAB_GIRDER = 5.0
OX, OZ, SPM, STEP = 30000.0, 0.0, 1.6, 6.4
SIDE_OFF, SIDE_HALF, SPLIT, JOIN = 48.0, 12.0, 160.0, 140.0   # (d7_flyovers.py)
WIDE = SIDE_OFF + SIDE_HALF
design = json.load(open(os.path.join(MAP, 'ygn_road_design.json'), encoding='utf-8'))
GR = design['ground']


def ground(X, Z):
    """d7_flyovers.ground: the smoothed ground grid's road height"""
    x, y = (X - OX) / SPM, (OZ - Z) / SPM
    nx, ny = GR['nx'], GR['ny']
    dx = (GR['east_m'] - GR['west_m']) / (nx - 1)
    dy = (GR['north_m'] - GR['south_m']) / (ny - 1)
    fi = min(max((x - GR['west_m']) / dx, 0), nx - 1.001)
    fj = min(max((y - GR['south_m']) / dy, 0), ny - 1.001)
    i, j = int(fi), int(fj)
    a, b = fi - i, fj - j
    h = GR['height_m']
    v = h[j][i] * (1 - a) * (1 - b) + h[j][i + 1] * a * (1 - b) + h[j + 1][i] * (1 - a) * b + h[j + 1][i + 1] * a * b
    return v * SPM


class Line:
    """d7_flyovers.Line"""

    def __init__(self, s):
        self.s = s
        self.c = chain(s)

    def at(self, dd):
        c, s = self.c, self.s
        dd = min(max(dd, 0), c[-1])
        lo, hi = 0, len(c) - 1
        while hi - lo > 1:
            m = (lo + hi) // 2
            if c[m] <= dd:
                lo = m
            else:
                hi = m
        t = (dd - c[lo]) / max(c[hi] - c[lo], 1e-9)
        a, b = s[lo], s[hi]
        x, y, z = (a[k] + (b[k] - a[k]) * t for k in range(3))
        dx, dz = b[0] - a[0], b[2] - a[2]
        L = math.hypot(dx, dz)
        return x, y, z, dx / L, dz / L


def side_lane(line, d0, d1, offset, half_fn, height_fn, side):
    """d7_flyovers.lane, unchanged"""
    n = max(2, int(round((d1 - d0) / STEP)) + 1)
    pts = []
    for k in range(n):
        dd = d0 + (d1 - d0) * k / (n - 1)
        x, y, z, tx, tz = line.at(dd)
        j = min(range(len(line.c)), key=lambda q: abs(line.c[q] - dd))
        if abs(line.c[j] - dd) < 1e-6:
            Ls = math.hypot(line.s[j][3], line.s[j][4])
            tx, tz = line.s[j][3] / Ls, line.s[j][4] / Ls
        rx, rz = -tz, tx
        o = offset(dd) * side
        pts.append([x + rx * o, z + rz * o, dd])
    out = []
    for k, p in enumerate(pts):
        a, b = pts[max(k - 1, 0)], pts[min(k + 1, n - 1)]
        dx, dz = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dz)
        dx, dz = dx / L, dz / L
        if side < 0:
            dx, dz = -dx, -dz
        h = half_fn(p[2])
        out.append([round(p[0], 2), round(height_fn(p[0], p[1], p[2]), 2), round(p[1], 2), round(dx, 4), round(dz, 4), 0, h, h])
    for k, dd in ((0, d0), (n - 1, d1)):
        _, _, _, tx, tz = line.at(dd)
        j = min(range(len(line.c)), key=lambda q: abs(line.c[q] - dd))
        if abs(line.c[j] - dd) < 1e-6:
            tx, tz = line.s[j][3], line.s[j][4]
        Lt = math.hypot(tx, tz)
        sgn = -1 if side < 0 else 1
        out[k][3], out[k][4] = round(sgn * tx / Lt, 4), round(sgn * tz / Lt, 4)
    if side < 0:
        out.reverse()
    return out


def deck_needs(dk, extra_cut=None):
    """[(deck chain, surface height needed, road)] for every point of every road's carriageway under the deck
    (extra_cut: {road: samples} not built either)"""
    s = dk['s']
    c = chain(s)
    out = []
    for r in d['roads']:
        if r['name'] == dk['of']:
            continue
        cs = CUT.get(r['name'], set()) | (extra_cut or {}).get(r['name'], set())
        for i, p in enumerate(r['s']):
            if i in cs:
                continue
            h = max(p[6], p[7])
            Lh = math.hypot(p[3], p[4])
            rx, rz = -p[4] / Lh, p[3] / Lh
            if min(math.hypot(p[0] - q[0], p[2] - q[2]) for q in s[::4]) > 32 + h + 30:
                continue
            for lat in (-h + 0.5, -h / 2, 0, h / 2, h - 0.5):
                x, z = p[0] + rx * lat, p[2] + rz * lat
                best = None
                for k in range(len(s) - 1):
                    a, b = s[k], s[k + 1]
                    vx, vz = b[0] - a[0], b[2] - a[2]
                    LL = vx * vx + vz * vz
                    t = max(0, min(1, ((x - a[0]) * vx + (z - a[2]) * vz) / LL))
                    dd = math.hypot(x - a[0] - t * vx, z - a[2] - t * vz)
                    if best is None or dd < best[0]:
                        best = (dd, k, t)
                dd, k, t = best
                if dd < 32 and 0 < k < len(s) - 2:
                    out.append((c[k] + t * (c[k + 1] - c[k]), p[1] + DECK_NEED, r['name']))
    return out


def clearances(dk):
    """{road: the least clearance from the girder's underside to it}"""
    s = dk['s']
    c = chain(s)
    worst = {}
    for dc, need, name in deck_needs(dk):
        k = max(0, min(len(s) - 2, max(q for q in range(len(s)) if c[q] <= dc)))
        t = (dc - c[k]) / max(c[k + 1] - c[k], 1e-9)
        y = s[k][1] + (s[k + 1][1] - s[k][1]) * t
        cl = y - SLAB_GIRDER - (need - DECK_NEED)
        worst[name] = min(worst.get(name, 1e9), cl)
    return worst


def grades(s):
    c = chain(s)
    g = [(s[k + 1][1] - s[k][1]) / max(c[k + 1] - c[k], 1e-9) for k in range(len(s) - 1)]
    return max(g), min(g)


def ramp(x):
    """height gained x studs from a foot: a parabolic vertical curve over VCURVE, then DECK_GRADE"""
    if x <= 0:
        return 0.0
    if x < VCURVE:
        return DECK_GRADE * x * x / (2 * VCURVE)
    return DECK_GRADE * (x - VCURVE / 2)


def smin(vals, k=1.2):
    m = min(vals)
    return m - k * math.log(sum(math.exp(-(v - m) / k) for v in vals))


def smax(vals, k=1.0):
    return -smin([-v for v in vals], k)


deck_report = []
before = {dk['name']: (clearances(dk), grades(dk['s'])) for dk in d['decks']}

# Pyay: the old profile, eased up over what passes under it
pyay = DECKS['Pyay Road Flyover']
ps = pyay['s']
pc = chain(ps)
needs = deck_needs(pyay)
if needs:
    env = []
    for k in range(len(ps)):
        env.append(max(nd - DECK_GRADE * 0.66 * abs(pc[k] - dc) for dc, nd, _ in needs))
    # (a moving average over 96 studs rounds the hump's corners; grades stay under the envelope's)
    sm = []
    for k in range(len(ps)):
        acc = [env[q] for q in range(len(ps)) if abs(pc[q] - pc[k]) <= 48]
        sm.append(sum(acc) / len(acc))
    deficit = max(0.0, max(nd - (sm[min(range(len(ps)), key=lambda q: abs(pc[q] - dc))]) for dc, nd, _ in needs))
    for k in range(1, len(ps) - 1):
        ps[k][1] = round(smax([ps[k][1], sm[k] + deficit]), 2)
    loop = R['Yangon Loop']['s']
    for k in range(1, len(ps) - 1):
        loop[pyay['from'] + k][1] = ps[k][1]  # (the loop's own cut samples carry the deck: d9's loop B drives them)

# Kabar Aye: a later landing along the loop, then a new profile
ka = DECKS['Kabar Aye Flyover']
loop = R['Yangon Loop']['s']
nr = R['New Road']['s']
K0 = min(i for i in CUT['Yangon Loop'] if i > 0 and (i - 1) not in CUT['Yangon Loop'] and i < pyay['from']) - 1  # (789)
KRES_OLD = ka['land']
LC = chain(loop)
next_junction = None
for r in d['roads']:
    if r['name'] == 'Yangon Loop':
        continue
    for ei in (0, len(r['s']) - 1):
        if ei in CUT.get(r['name'], set()):
            continue  # (New Road's cut end lies on the loop's line under its deck)
        e = r['s'][ei]
        k = min(range(len(loop)), key=lambda q: (loop[q][0] - e[0]) ** 2 + (loop[q][2] - e[2]) ** 2)
        if k > KRES_OLD and math.hypot(loop[k][0] - e[0], loop[k][2] - e[2]) < 40 and (next_junction is None or k < next_junction):
            if r['kind'] != 'side':
                next_junction = k
ka_base = [list(p) for p in ka['s'][:-1]]  # New Road's samples from the deck's start to its old foot


def ka_profile(kres):
    s = ka_base + [list(p) for p in loop[KRES_OLD:kres + 1]]
    for p in s[len(ka_base):]:
        p[6] = p[7] = 32  # (the deck is 2+2, half 32: the loop's samples there were widened for the old join)
    c = chain(s)
    L = c[-1]
    y0, y1 = s[0][1], s[-1][1]
    tmp = {'s': s, 'of': 'New Road'}
    nd = deck_needs(tmp, {'Yangon Loop': set(range(KRES_OLD, kres))})
    top = max(v for _, v, _ in nd) + 1.0
    for k in range(1, len(s) - 1):
        s[k][1] = round(smin([y0 + ramp(c[k]), top, y1 + ramp(L - c[k])]), 2)
    ok = True
    for dc, need, _ in nd:
        k = max(q for q in range(len(s)) if c[q] <= dc)
        if s[k][1] < need or s[min(k + 1, len(s) - 1)][1] < need:
            ok = False
    return s, ok


new_land = None
for kres in range(KRES_OLD, (next_junction or KRES_OLD + 60) - int(JOIN / STEP) - 4):
    s_try, ok = ka_profile(kres)
    if os.environ.get('D23_DEBUG'):
        print('landing', kres, ok, grades(s_try), next_junction)
    if ok and max(abs(g) for g in grades(s_try)) <= 0.08:
        new_land = kres
        break
if new_land is None:
    raise SystemExit('the Kabar Aye deck cannot clear what is under it before the next junction on the loop')
ka_s, _ = ka_profile(new_land)
if new_land != KRES_OLD:
    # the loop: cut on to the new landing, the widened join moved there (60 at the landing, 32 after JOIN)
    for i in range(KRES_OLD, new_land):
        CUT['Yangon Loop'].add(i)
    d['cut']['Yangon Loop'] = sorted(CUT['Yangon Loop'])
    dK0, dK1 = LC[K0], LC[new_land]
    for i in range(KRES_OLD, len(loop)):
        if LC[i] > LC[KRES_OLD] + JOIN + 10:
            break
        loop[i][6] = loop[i][7] = 32.0
    for i in range(new_land, len(loop)):
        dd = LC[i] - dK1
        if dd > JOIN:
            break
        w = round(32 + (WIDE - 32) * smooth((JOIN - dd) / JOIN), 2)
        loop[i][6] = loop[i][7] = max(32.0, w)
    # the two side lanes, d7's geometry on to the new landing
    Lloop = Line(loop)

    def ka_off(dd):
        if dd < dK0 + SPLIT:
            return 16 + (SIDE_OFF - 16) * smooth((dd - dK0) / SPLIT)
        return SIDE_OFF

    def ka_half(dd):
        return 16 - 4 * smooth((dd - dK0) / SPLIT)

    def ka_h(x, z, dd):
        if dd <= dK0:
            return Lloop.at(dK0)[1]
        if dd >= dK1:
            return Lloop.at(dK1)[1]
        g = ground(x, z)
        if dd - dK0 < 64:
            w = smooth((dd - dK0) / 64)
            return Lloop.at(dK0)[1] * (1 - w) + g * w
        if dK1 - dd < 64:
            w = smooth((dK1 - dd) / 64)
            return Lloop.at(dK1)[1] * (1 - w) + g * w
        return g

    # (check first: d7's lanes to the old landing must come out as the v4 ones)
    old_e = side_lane(Lloop, dK0, LC[KRES_OLD], ka_off, ka_half, lambda x, z, dd: 0, +1)
    v4e = R['Kabar Aye East Lane']['s']
    dev = max(math.hypot(a[0] - b[0], a[2] - b[2]) for a, b in zip(old_e, v4e)) if len(old_e) == len(v4e) else 1e9
    assert dev < 0.05, 'the side lane re-make differs from v4 (%.2f studs)' % dev
    R['Kabar Aye East Lane']['s'] = side_lane(Lloop, dK0, dK1, ka_off, ka_half, ka_h, +1)
    R['Kabar Aye West Lane']['s'] = side_lane(Lloop, dK0, dK1, ka_off, ka_half, ka_h, -1)
    # (the west lane's end on the loop's split was half 16; side_lane gives the same)
ka['s'] = ka_s
ka['land'] = new_land
# heights of the side lanes changed only near the landing; the needs are checked again below
after = {dk['name']: (clearances(dk), grades(dk['s'])) for dk in d['decks']}
for dk in d['decks']:
    cb, gb = before[dk['name']]
    ca, ga = after[dk['name']]
    rows = ', '.join('%s %.1f -> %.1f' % (n_, cb.get(n_, float('nan')), ca[n_]) for n_ in sorted(ca))
    deck_report.append('%s: length %.0f studs, top %.1f; clearance under the girder (studs): %s; grades up %.1f%% / down %.1f%% (were %.1f%% / %.1f%%)' % (
        dk['name'], chain(dk['s'])[-1], max(p[1] for p in dk['s']), rows, ga[0] * 100, -ga[1] * 100, gb[0] * 100, -gb[1] * 100))
    assert all(v >= 17.0 for v in ca.values()), dk['name'] + ' still too low'
deck_report.append('Kabar Aye Flyover lands on the loop at sample %d (was %d; the loop is cut %d..%d, its next junction is at %s)' % (
    new_land, KRES_OLD, K0 + 1, new_land - 1, next_junction))
# the decks: their ground samples are cut and the deck is 2+2 (no median); a deck's approach eases to 2+2 first
pyay = DECKS['Pyay Road Flyover']
OVERRIDES.setdefault('Yangon Loop', []).append((pyay['from'] + 1, pyay['to'] - 1, 2, False, 'the Pyay Road Flyover deck (2+2)'))
ka = DECKS['Kabar Aye Flyover']
OVERRIDES.setdefault('New Road', []).append((ka['from'] - 20, None, 2, False, 'the Kabar Aye Flyover deck (2+2) and its approach'))


def W(lon, lat):
    return 30000 + (lon - 96.14) * KX * 1.6, -(lat - 16.82) * KY * 1.6


osm = json.load(open(os.path.join(ROOT, 'build', 'osm_ygn', 'roads.json'), encoding='utf-8'))['roads']
segs = []
for w in osm:
    if w['t'].get('highway') not in BIG:
        continue
    pts = [W(*p) for p in w['p']]
    for k in range(len(pts) - 1):
        segs.append((pts[k], pts[k + 1], w))
CELL = 64
GRID = collections.defaultdict(list)
for i, (a, b, w) in enumerate(segs):
    x0, x1 = sorted((a[0], b[0]))
    z0, z1 = sorted((a[1], b[1]))
    for cx in range(int(x0 // CELL) - 1, int(x1 // CELL) + 2):
        for cz in range(int(z0 // CELL) - 1, int(z1 // CELL) + 2):
            GRID[(cx, cz)].append(i)


def num(v):
    try:
        return float(str(v).split(';')[0])
    except (TypeError, ValueError):
        return None


def oneway(t):
    return t.get('oneway') in ('yes', '1', 'true', '-1')


def lanes_each(t):
    if oneway(t):
        return num(t.get('lanes'))
    f = num(t.get('lanes:forward'))
    if f:
        return f
    n = num(t.get('lanes'))
    return n / 2 if n else None


def wname(w):
    return w['t'].get('name:en') or w['t'].get('name') or '?'


def query(x, z, dx, dz):
    """the OSM ways near a point that run along dx, dz: [(distance, along (+1 / -1), way)] nearest first, one per way"""
    L = math.hypot(dx, dz)
    dx, dz = dx / L, dz / L
    best = {}
    seen = set()
    for cx in range(int(x // CELL) - 1, int(x // CELL) + 2):
        for cz in range(int(z // CELL) - 1, int(z // CELL) + 2):
            for i in GRID.get((cx, cz), ()):
                if i in seen:
                    continue
                seen.add(i)
                a, b, w = segs[i]
                vx, vz = b[0] - a[0], b[1] - a[1]
                LL = vx * vx + vz * vz
                if LL == 0:
                    continue
                t = max(0, min(1, ((x - a[0]) * vx + (z - a[1]) * vz) / LL))
                dist = math.hypot(a[0] + t * vx - x, a[1] + t * vz - z)
                if dist > SEARCH:
                    continue
                cos = (vx * dx + vz * dz) / math.sqrt(LL)
                if abs(cos) < 0.85:
                    continue
                along = 1 if cos > 0 else -1
                if w['t'].get('oneway') == '-1':
                    along = -along
                if w['id'] not in best or dist < best[w['id']][0]:
                    best[w['id']] = (dist, along, w)
    return sorted(best.values(), key=lambda o: o[0])


def classify(x, z, dx, dz):
    """(divided, lanes each way or None, name) of the real road under a sample, or None"""
    c = query(x, z, dx, dz)
    if not c:
        return None
    tw = [o for o in c if not oneway(o[2]['t'])]
    ow = [o for o in c if oneway(o[2]['t'])]
    if tw and tw[0][0] <= 30 and (not ow or tw[0][0] < 0.6 * ow[0][0] + 2):
        return (False, lanes_each(tw[0][2]['t']), wname(tw[0][2]))
    if not ow:
        return None
    fwd = [o for o in ow if o[1] > 0]
    back = [o for o in ow if o[1] < 0]
    pick = [o for o in (fwd[:1] + back[:1])]
    ln = [lanes_each(o[2]['t']) for o in pick]
    ln = [v for v in ln if v]
    return (True, max(ln) if ln else None, wname(pick[0][2]))


def chain(s):
    c = [0.0]
    for k in range(1, len(s)):
        c.append(c[-1] + math.hypot(s[k][0] - s[k - 1][0], s[k][2] - s[k - 1][2]))
    return c


def smooth(u):
    u = min(max(u, 0.0), 1.0)
    return u * u * (3 - 2 * u)


def clamp_lanes(v):
    if v is None:
        return 2
    return min(3, max(2, int(round(v))))


def seg_dist(px, pz, s, cut=None):
    best = 1e18
    for k in range(len(s) - 1):
        if cut and (k in cut or (k + 1) in cut):
            continue
        a, b = s[k], s[k + 1]
        vx, vz = b[0] - a[0], b[2] - a[2]
        L = vx * vx + vz * vz
        t = 0 if L == 0 else max(0, min(1, ((px - a[0]) * vx + (pz - a[2]) * vz) / L))
        best = min(best, math.hypot(px - a[0] - t * vx, pz - a[2] - t * vz))
    return best


# a 32-stud grid of every road's kept segments (for the median openings)
SG = collections.defaultdict(list)
for r in d['roads']:
    s, cs = r['s'], CUT.get(r['name'], set())
    for k in range(len(s) - 1):
        if k in cs or (k + 1) in cs:
            continue
        a, b = s[k], s[k + 1]
        for cx in range(int(min(a[0], b[0]) // 32) - 1, int(max(a[0], b[0]) // 32) + 2):
            for cz in range(int(min(a[2], b[2]) // 32) - 1, int(max(a[2], b[2]) // 32) + 2):
                SG[(cx, cz)].append((r['name'], k))


def others_near(name, x, z, reach):
    """{other road: (distance to its centre line, its half there)} for kept segments within reach"""
    out = {}
    n = int(math.ceil(reach / 32))
    for cx in range(int(x // 32) - n, int(x // 32) + n + 1):
        for cz in range(int(z // 32) - n, int(z // 32) + n + 1):
            for on, k in SG.get((cx, cz), ()):
                if on == name:
                    continue
                s = R[on]['s']
                a, b = s[k], s[k + 1]
                vx, vz = b[0] - a[0], b[2] - a[2]
                L = vx * vx + vz * vz
                t = 0 if L == 0 else max(0, min(1, ((x - a[0]) * vx + (z - a[2]) * vz) / L))
                dd = math.hypot(x - a[0] - t * vx, z - a[2] - t * vz)
                h = max(a[6], a[7], b[6], b[7])
                if on not in out or dd < out[on][0]:
                    out[on] = (dd, h)
    return out


# ---------------------------------------------------------------------------------------------------- per road
ROUTES = [r for r in d['roads'] if r['kind'] == 'route']
old_half = {r['name']: [max(p[6], p[7]) for p in r['s']] for r in d['roads']}
summary = []
for r in ROUTES:
    name, s = r['name'], r['s']
    n = len(s)
    c = chain(s)
    cut = CUT.get(name, set())
    raw = [classify(p[0], p[2], p[3], p[4]) for p in s]
    vals = [None if v is None else (clamp_lanes(v[1]), v[0]) for v in raw]
    # decided values first (OVERRIDES, and RING_2LANE: the roundabout's arms are 2+2), locked
    lock = [False] * n
    why = {}
    for a, b, ln, dv, txt in OVERRIDES.get(name, []):
        b = n - 1 if b is None else b
        for q in range(max(0, a), min(n - 1, b) + 1):
            vals[q] = (ln, dv)
            lock[q] = True
        why[(a, b)] = txt
    ring = [q for q in range(n) if math.hypot(s[q][0] - C[0], s[q][2] - C[1]) < RING_2LANE]
    for q in ring:
        vals[q] = (2, False)
        lock[q] = True
    if ring:
        why[(ring[0], ring[-1])] = 'a roundabout arm (2+2 within %d studs of its centre)' % RING_2LANE
    # unknown runs: short ones take a neighbour's value, long ones (a drawn road, a residential street) and those
    # at a road's end (a junction the real road reaches differently) stay 2+2
    i = 0
    while i < n:
        if vals[i] is not None:
            i += 1
            continue
        j = i
        while j + 1 < n and vals[j + 1] is None:
            j += 1
        length = c[j] - c[i] + 6.4
        fill = (2, False)
        if length < MIN_SEC and i > 0 and j + 1 < n:
            fill = vals[i - 1]
        for k in range(i, j + 1):
            vals[k] = fill
        i = j + 1

    def runs_of(v):
        out = []
        for k, x in enumerate(v):
            if out and out[-1][0] == x:
                out[-1][2] = k
            else:
                out.append([x, k, k])
        return out

    # sections: the shortest run under MIN_SEC goes into a neighbour (one that isn't locked first, then the
    # longer), until none is left; locked samples never change
    while True:
        runs = runs_of(vals)
        lens = [c[b] - c[a] + 6.4 for _, a, b in runs]
        cand = [q for q in range(len(runs)) if lens[q] < MIN_SEC and not any(lock[x] for x in range(runs[q][1], runs[q][2] + 1))]
        if not cand or len(runs) < 2:
            break
        k = min(cand, key=lambda q: lens[q])
        nbs = [q for q in (k - 1, k + 1) if 0 <= q < len(runs)]
        nbs.sort(key=lambda q: (any(lock[x] for x in range(runs[q][1], runs[q][2] + 1)), -lens[q]))
        nb = nbs[0]
        for q in range(runs[k][1], runs[k][2] + 1):
            vals[q] = runs[nb][0]
    runs = runs_of(vals)

    # targets per sample, then the eases at each section change
    def target(v):
        ln, dv = v
        mL = MEDIAN if dv else 0.0
        w = LANE_W[ln]
        return [mL, w, mL + ln * w, ln]

    T = [target(v) for v in vals]
    G = [list(t[:3]) for t in T]  # eased mL, laneW, base half
    NL_ = [t[3] for t in T]
    for q in range(len(runs) - 1):
        A, B = runs[q], runs[q + 1]
        b = B[1]
        if (b - 1) in cut or b in cut:
            continue  # (a step inside a cut run: nothing of it is built)
        lenA, lenB = c[A[2]] - c[A[1]] + 6.4, c[B[2]] - c[B[1]] + 6.4
        E = min(EASE / 2, lenA / 2, lenB / 2)
        cb = (c[b - 1] + c[b]) / 2
        ta, tb = target(A[0]), target(B[0])
        for k in range(A[1], B[2] + 1):
            if abs(c[k] - cb) >= E:
                continue
            u = smooth((c[k] - (cb - E)) / (2 * E))
            mL = ta[0] + (tb[0] - ta[0]) * u
            w = ta[1] + (tb[1] - ta[1]) * u
            hb = ta[2] + (tb[2] - ta[2]) * u
            G[k] = [mL, w, hb]
            lo, hi = min(ta[3], tb[3]), max(ta[3], tb[3])
            NL_[k] = min(hi, max(lo, int(math.floor((hb - mL) / w + 0.2))))
    # the gores: the loop widened by d7 (old half over 32): ease onto the deck's lanes, the outer edge kept
    gore = [False] * n
    halves = []
    for k in range(n):
        mL, w, hb = G[k]
        ln = NL_[k]
        wo = old_half[name][k]
        h = hb
        if wo > 32.01:
            gore[k] = True
            u = min(1.0, (wo - 32.0) / 28.0)
            mL = mL * (1 - u)
            w = w + (GORE_W - w) * u
            hb = mL + ln * w
            h = max(hb, wo)  # (the old gore edge, d7's: the side lanes still start square on it)
            G[k] = [mL, w, hb]
        halves.append(h)

    # the built median: open where traffic crosses, at the ring, the cuts and the gores
    openm = [False] * n
    for k in range(n):
        mL = G[k][0]
        p = s[k]
        if mL < 0.05 or k in cut or (k - 1) in cut or (k + 1) in cut or gore[k]:
            openm[k] = True
            continue
        if math.hypot(p[0] - C[0], p[2] - C[1]) < OPEN_RING:
            openm[k] = True
            continue
        for on, (dd, oh) in others_near(name, p[0], p[2], 32 + OPEN_R + 32).items():
            ok = R[on]['kind']
            if ok == 'street' and not OPEN_AT_STREETS:
                continue
            if dd < oh + OPEN_R:
                openm[k] = True
                break
    # short median runs are left out; the rest ease to a nose into each opening
    k = 0
    while k < n:
        if openm[k]:
            k += 1
            continue
        j = k
        while j + 1 < n and not openm[j + 1]:
            j += 1
        if c[j] - c[k] < MIN_MEDIAN:
            for q in range(k, j + 1):
                openm[q] = True
        k = j + 1
    opens = [c[k] for k in range(n) if openm[k]]
    mP = [0.0] * n
    oi = 0
    for k in range(n):
        if openm[k]:
            continue
        while oi + 1 < len(opens) and opens[oi + 1] <= c[k]:
            oi += 1
        dist = 1e9
        for q in (oi, oi + 1):
            if 0 <= q < len(opens):
                dist = min(dist, abs(opens[q] - c[k]))
        mP[k] = G[k][0] * smooth(dist / NOSE)

    def rnd(v):
        v = round(v, 2)
        return int(v) if v == int(v) else v

    for k in range(n):
        p = s[k]
        h = rnd(halves[k])
        p[6] = p[7] = h
        del p[8:]
        p += [rnd(mP[k]), NL_[k], rnd(G[k][1]), rnd(G[k][0])]
    # (the road's own half = its NARROWEST section's: Roads.luau leaves out the kerb and pavement wherever a sample is
    # narrower than the road's half (`narrow`), and alignJunctions skips such samples. A wider section is to it what
    # the gores were in v4: wider samples; the kerbs and pavements follow every sample's own edge)
    kept = [G[k][2] for k in range(n) if not gore[k] and k not in cut]
    r['half'] = rnd(min(kept)) if kept else r['half']
    secs = []
    for v, a, b in runs:
        names = collections.Counter(raw[q][2] for q in range(a, b + 1) if raw[q])
        secs.append((v, a, b, c[b] - c[a] + 6.4, names.most_common(1)[0][0] if names else '-'))
    longest = max(secs, key=lambda x: x[3])
    r['lanes'] = max(NL_)
    r['median'] = MEDIAN if any(v[1] for v, *_ in secs) else 0
    r['laneW'] = LANE_W[longest[0][0]]
    built = sum(1 for k in range(n) if mP[k] > 0.05)
    summary.append((name, secs, built, min(halves), max(halves), why))

d['note'] = (d.get('note', '') + ' | v5 (14 Nov 2026): real lane counts and medians from OSM (d23_lanes_v5.py): per-sample s[8] built median half, s[9] lanes per side, s[10] lane width, s[11] lane median half.').strip(' |')

# ---------------------------------------------------------------------------------------------------- report
print('%-28s %4s  %-44s %6s %s' % ('road', 'secs', 'sections (samples: lanes each way, D = divided)', 'median', 'half'))
for name, secs, built, h0, h1, why in summary:
    txt = ', '.join('%d-%d %d%s' % (a, b, v[0], 'D' if v[1] else '') for v, a, b, L, nm in secs)
    print('%-28s %4d  %-44s %6d %.0f-%.0f' % (name, len(secs), txt, built, h0, h1))
print()
print('sections with the OSM road under them:')
for name, secs, built, h0, h1, why in summary:
    for v, a, b, L, nm in secs:
        print('  %-28s %4d-%-4d %5.0f studs  %d each way %-9s (%s)' % (name, a, b, L, v[0], 'divided' if v[1] else 'undivided', nm))
    for (a, b), txt in why.items():
        print('  %-28s override %d-%d: %s' % (name, a, b, txt))

# the side-by-side check (d18's, with the new halves): a road's carriageway + pavement must not overlap another
# road it doesn't meet
problems_new = []
for r in ROUTES:
    n_, s = r['name'], r['s']
    for o in d['roads']:
        if o['name'] == n_:
            continue
        oc = CUT.get(o['name'], set())
        ohalf = max(max(q[6], q[7]) for q in o['s'])
        dists = [seg_dist(p[0], p[2], o['s'], oc) for p in s]
        if min(dists) < ohalf + 1:
            continue  # a junction
        worst = None
        for k, p in enumerate(s):
            if k in CUT.get(n_, set()):
                continue
            need_new = max(p[6], p[7]) + 10 + ohalf + 10 - 2
            need_old = old_half[n_][k] + 10 + ohalf + 10 - 2
            if dists[k] < need_new and dists[k] >= need_old:
                if worst is None or dists[k] - need_new < worst[0]:
                    worst = (dists[k] - need_new, k)
        if worst:
            problems_new.append('%s sample %d now %.0f studs too close to %s' % (n_, worst[1], -worst[0], o['name']))
# (the decks again, with the roads at their v5 widths: a wider road under a deck has more of it under the girder)
for dk in d['decks']:
    ca = clearances(dk)
    deck_report.append('%s with the v5 widths: least clearance %s' % (dk['name'], ', '.join('%s %.1f' % kv for kv in sorted(ca.items()))))
    assert all(v >= 17.0 for v in ca.values()), dk['name'] + ' too low over a widened road'
print()
print('decks:')
for line in deck_report:
    print('  ' + line)
print()
print('side-by-side problems the wider roads make (pavements overlapping a road they do not meet): %d' % len(problems_new))
for p in problems_new:
    print('  ' + p)

# what now stands on the wider roads: buildings (ygn_plots_real), lots (YangonWorld), lamps, trees
def on_road_count(points_of, items, margin):
    """items whose points lie within new half + margin of a route but were clear of old half + margin"""
    hit = 0
    for it in items:
        newly = False
        for (x, z) in points_of(it):
            for r in ROUTES:
                s = r['s']
                cs = CUT.get(r['name'], set())
                if abs(s[0][0] - x) > 9000:
                    pass
                # (quick reject on the grid of kept segments)
                for cx in (int(x // 32) - 2, int(x // 32) - 1, int(x // 32), int(x // 32) + 1, int(x // 32) + 2):
                    pass
            near = others_near('', x, z, 64)
            for on, (dd, oh) in near.items():
                if R[on]['kind'] != 'route':
                    continue
                k = min(range(len(R[on]['s'])), key=lambda q: (R[on]['s'][q][0] - x) ** 2 + (R[on]['s'][q][2] - z) ** 2)
                hn = max(R[on]['s'][k][6], R[on]['s'][k][7])
                ho = old_half[on][k]
                if hn + margin > dd >= ho + margin:
                    newly = True
            if newly:
                break
        if newly:
            hit += 1
    return hit


plots = json.load(open(os.path.join(MAP, 'ygn_plots_real.json'), encoding='utf-8'))['plots']


def plot_pts(p):
    # the front edge (fx, fz point front -> back) and the two front corners
    x, z, fx, fz, w, dd = p['x'], p['z'], p['fx'], p['fz'], p['w'], p['d']
    ax, az = -fz, fx
    fxp, fzp = x - fx * dd / 2, z - fz * dd / 2
    return [(fxp + ax * w * u, fzp + az * w * u) for u in (-0.5, -0.25, 0, 0.25, 0.5)]


n_plots = on_road_count(plot_pts, plots, 10.0)
world = open(os.path.join(ROOT, 'src', 'shared', 'YangonWorld.lua'), encoding='utf-8').read()
lots = [tuple(float(v) for v in m.group(1, 2, 3, 4, 5, 6)) for m in re.finditer(r'\{ id = "[^"]+", zone = "[^"]+", tier = \d+, number = \d+, x = ([-\d.]+), y = [-\d.]+, z = ([-\d.]+), fx = ([-\d.]+), fz = ([-\d.]+), w = (\d+), d = (\d+) \},', world)]


def lot_pts(l):
    x, z, fx, fz, w, dd = l
    return plot_pts({'x': x, 'z': z, 'fx': fx, 'fz': fz, 'w': w, 'd': dd})


n_lots = on_road_count(lot_pts, lots, 13.0)
lamp_src = open(os.path.join(ROOT, 'build', 'yangon_lamps', 'YangonLampSpots.luau'), encoding='utf-8').read()
lamps = [tuple(float(v) for v in ln.split()[:2]) for ln in lamp_src.split(NL) if re.match(r'^[-\d.]+ [-\d.]+ [-\d.]+ [-\d.]+ [-\d.]+ P$', ln)]
n_lamps = on_road_count(lambda p: [p], lamps, 1.5)
green_src = open(os.path.join(ROOT, 'build', 'yangon_green', 'YangonGreenData.luau'), encoding='utf-8').read()
trees = [tuple(float(v) for v in ln.split()[1:3]) for ln in green_src.split(NL) if ln.startswith('T ')]
n_trees = on_road_count(lambda p: [p], trees, 10.0)
print()
print('now on the wider roads (carriageway + pavement): %d of %d buildings (ygn_plots_real), %d of %d lots (YangonWorld), '
      '%d of %d pavement lamps, %d of %d trees' % (n_plots, len(plots), n_lots, len(lots), n_lamps, len(lamps), n_trees, len(trees)))

# ---------------------------------------------------------------------------------------------------- write
path = os.path.join(MAP, 'ygn_roads_v5.json')
json.dump(d, open(path, 'w', encoding='utf-8'), separators=(',', ':'))
txt = open(path, encoding='utf-8').read()
os.makedirs(OUT_DIR, exist_ok=True)
for f in os.listdir(OUT_DIR):
    if re.match(r'^Roads3_\d+\.luau$', f):
        os.remove(os.path.join(OUT_DIR, f))
parts = int(math.ceil(len(txt) / CHUNK))
size = (len(txt) + parts - 1) // parts
for k in range(parts):
    body = 'return [==[' + txt[k * size:(k + 1) * size] + ']==]' + NL
    assert len(body) < 190000, len(body)
    assert ']==]' not in txt[k * size:(k + 1) * size]
    open(os.path.join(OUT_DIR, 'Roads3_%d.luau' % (k + 1)), 'w', encoding='utf-8', newline=NL).write(body)
print()
print('wrote %s (%d characters) and %d modules in %s (Roads3_1..%d, each under 190,000)' % (path, len(txt), parts, OUT_DIR, parts))
