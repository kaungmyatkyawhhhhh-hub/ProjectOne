"""Yangon map, build step 7 (13 Nov 2026): NPC traffic lanes for the main roads.

Reads imports/refs/map/ygn_roads_v5.json and writes src/shared/YangonLanes.lua (and YangonLanes2.lua when one
module would pass MAX_CHARS) in the format of src/shared/RivieraLanes.lua / RivieraLanesHighway.lua (see
RivieraTraffic.lua): lane records { road, way, lane, kind, closed, pts = { x,y,z, ... } } with points every ~24 studs
in the direction of travel, y = surface + 0.15, and links { fromLane, fromK, toLane, toK } in the GLOBAL lane
numbering (this module's lanes are numbered on from RivieraLanes + RivieraLanesHighway: `first`).

Owner's rule: traffic only on the main roads (the loop, New Road, University Avenue, the v4 routes), their flyover
decks and side lanes, and the Hanthawaddy Roundabout. Streets get no lanes.

  * Right-hand traffic (Myanmar). v5 (14 Nov 2026, d23_lanes_v5.py): each road sample carries its lanes a side n,
    the lane width w and the lanes' median half m (s[9..11]); lane k (1 = inner, next to the median or the centre
    line) runs at m + we * (k - 0.5) right of the centre line, we = min(w, (half - m) / n). Samples without them
    (decks, side lanes) are 2+2 at 16: lanes 8 and 24, as before.
  * Lanes 1 and 2 run the whole of a road; lane 3 is a piece wherever the road has 3 lanes a side (several pieces
    on the loop). A piece that starts mid-road is fed by a lane change from lane 2 (`to_start`), one that ends
    mid-road merges into lane 2 (`end_to`), except at a gore: there it runs on into the side lane (Pyay, Kabar Aye),
    or a side lane runs into it.
  * A road end with 3 lanes at a T: right turns from lane 3 (the outer), left turns from lane 1; lane 2 (the middle
    one) stops TRIM studs short and changes into lane 1 or 3 (leaving a T: it starts TRIM in, fed from lanes 1 and
    3). Into the big road: the right turn lands on its outer lane there, the left on its lane 1.
  * A side lane is one-way, in the order of its samples: lane 1 is its left lane (the deck side), lane 2 its right,
    each half its half width from its centre (the Kabar Aye lanes are 16 wide at their split, so their lanes start
    exactly on the loop's own lanes).
  * The loop is two runs: A (the roundabout to where it splits into the Kabar Aye side lanes, samples 0..K0) and
    B (where it resumes, KRES = the Kabar Aye deck's `land`, round over the Pyay deck back to the roundabout).
  * New Road runs on over its deck and lands on the loop at KRES; its forward lanes go straight on into run B, run
    B's backward lanes go straight on onto it.
  * The roundabout: two closed lanes, inner radius 76 and outer 96, anticlockwise (traffic keeps right). Its arms
    are 2+2 (d23 RING_2LANE); a lane 3 reaching it would join ring lane 2.
  * A lane that meets another road's lane at a junction stops BEFORE_JUNCTION clear of that road's centre line;
    the turn links land at least CLEAR studs along the other lane (RivieraTraffic draws the turn curves between
    them). A lane that runs straight on into another stops one point short, so the join is a short straight lane
    change and never a zero-length piece.
  * Lane records also carry `outer` (point ranges where the lane is its road's outermost: the start spots) and
    `median` (ranges where a raised median runs beside lane 1: no lane splitting onto it); RivieraTraffic reads them.

Run from Games/CityLegends:  python tools/yangon/d9_lanes.py [--plot outdir]
"""
import json, math, os, re, sys

sys.stdout.reconfigure(encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
MAP = os.path.join(ROOT, 'imports', 'refs', 'map')
OUT = os.path.join(ROOT, 'src', 'shared', 'YangonLanes.lua')
OUT2 = os.path.join(ROOT, 'src', 'shared', 'YangonLanes2.lua')
MAX_CHARS = 190000
STEP = 24.0
LIFT = 0.15
CLEAR = 18.0
TRIM = 48.0  # studs: a middle lane stops (or starts) this far from a T
MIN_PIECE = 72.0  # studs: shorter lane-3 pieces are left out
C = (29072.0, 47.27, 1172.8)  # the roundabout's centre at the ring's road height (YangonRoads.M.C)
R_OUT, FLAT, EASE = 108.0, 12.0, 128.0  # (YangonRoads: the arms are eased onto the ring's height)
RING_EXIT = 114.0  # loop lanes stop / start this far from the roundabout's centre
RING_LANES = {1: 76.0, 2: 96.0}

# (14 Nov 2026: v5 = real lane counts and medians, tools/yangon/d23_lanes_v5.py)
data = json.load(open(os.path.join(MAP, 'ygn_roads_v5.json'), encoding='utf-8'))
R = {r['name']: r for r in data['roads']}
CUT = {k: set(v) for k, v in data['cut'].items()}


def smooth(u):
    u = max(0.0, min(1.0, u))
    return u * u * (3 - 2 * u)


def rad(s):
    return math.hypot(s[0] - C[0], s[2] - C[2])


# ---------------------------------------------------------------- heights as Studio has them
def ease_arms(s):
    """YangonRoads.load: a road ending in the roundabout is flat at the ring's height out to
    R_OUT + FLAT, then eased back to its own heights over EASE studs"""
    s = [list(p) for p in s]
    n = len(s)
    for i0, step in ((0, 1), (n - 1, -1)):
        if rad(s[i0]) >= R_OUT:
            continue
        R0 = R_OUT + FLAT
        i = i0
        while rad(s[i]) < R0:
            i += step
        a, b = s[i - step], s[i]
        ra, rb = rad(a), rad(b)
        y_ring = a[1] + (b[1] - a[1]) * (R0 - ra) / (rb - ra)
        shift = C[1] - y_ring
        j = i0
        while 0 <= j < n:
            rr = rad(s[j])
            if rr < R0:
                s[j][1] = C[1]
            elif rr - R0 < EASE:
                s[j][1] += shift * (1 - smooth((rr - R0) / EASE))
            else:
                break
            j += step
    return s


loop = ease_arms(R['Yangon Loop']['s'])
nr = R['New Road']['s']
decks = {d['name']: d for d in data['decks']}
ka_deck = decks['Kabar Aye Flyover']['s']
LOOP_CUT = CUT['Yangon Loop']
PYAY_FROM = decks['Pyay Road Flyover']['from']
K0 = min(i for i in LOOP_CUT if i > 0 and (i - 1) not in LOOP_CUT and i < PYAY_FROM) - 1  # the loop ends here (run A)
KRES = decks['Kabar Aye Flyover']['land']  # ... and resumes here (run B)
NR_DECK = decks['Kabar Aye Flyover']['from']

centres = {
    'Yangon Loop A': loop[0:K0 + 1],
    'Yangon Loop B': loop[KRES:],  # (over the Pyay deck: the loop's own samples carry the deck's heights)
    'New Road': [list(p) for p in nr[0:NR_DECK]] + [list(p) for p in ka_deck],
    'University Avenue': R['University Avenue']['s'],
}
SIDES = ['Pyay Flyover West Lane', 'Pyay Flyover East Lane 1', 'Pyay Flyover East Lane 2', 'Kabar Aye East Lane', 'Kabar Aye West Lane']
for n_ in SIDES:
    centres[n_] = R[n_]['s']
# the widened roads (v4): every route that isn't one of the three originals
EXTRA = [r['name'] for r in data['roads'] if r.get('kind') == 'route' and r['name'] not in ('Yangon Loop', 'New Road', 'University Avenue')]
for n_ in EXTRA:
    centres[n_] = ease_arms(R[n_]['s'])


# ---------------------------------------------------------------- geometry helpers
def chain(s):
    c = [0.0]
    for k in range(1, len(s)):
        c.append(c[-1] + math.hypot(s[k][0] - s[k - 1][0], s[k][2] - s[k - 1][2]))
    return c


def geo(p):
    """(lanes a side, lane width, the lanes' median half, built median half) of a sample; 2+2 at 16 without v5 fields"""
    if len(p) >= 12:
        return p[9], p[10], p[11], p[8]
    return 2, 16.0, 0.0, 0.0


def at(s, c, d):
    """centre point, unit direction, half widths, lane width, lanes' median half and built median half at chain d"""
    d = max(0.0, min(c[-1], d))
    lo, hi = 0, len(c) - 1
    while hi - lo > 1:
        m = (lo + hi) // 2
        if c[m] <= d:
            lo = m
        else:
            hi = m
    a, b = s[lo], s[hi]
    t = 0.0 if c[hi] == c[lo] else (d - c[lo]) / (c[hi] - c[lo])
    x, y, z = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t
    dx, dz = a[3] + (b[3] - a[3]) * t, a[4] + (b[4] - a[4]) * t
    L = math.hypot(dx, dz)
    hl, hr = a[6] + (b[6] - a[6]) * t, a[7] + (b[7] - a[7]) * t
    ga, gb = geo(a), geo(b)
    w = ga[1] + (gb[1] - ga[1]) * t
    mL = ga[2] + (gb[2] - ga[2]) * t
    mP = ga[3] + (gb[3] - ga[3]) * t
    return x, y, z, dx / L, dz / L, hl, hr, w, mL, mP


def three_runs(s, c):
    """chain intervals [a, b] where the road has 3 lanes a side"""
    out = []
    k = 0
    n = len(s)
    while k < n:
        if geo(s[k])[0] < 3:
            k += 1
            continue
        j = k
        while j + 1 < n and geo(s[j + 1])[0] >= 3:
            j += 1
        out.append((c[k], c[j]))
        k = j + 1
    return out


def seg_dist(px, pz, s, cutset=None):
    best = 1e18
    for k in range(len(s) - 1):
        if cutset and (k in cutset or k + 1 in cutset):
            continue
        a, b = s[k], s[k + 1]
        vx, vz = b[0] - a[0], b[2] - a[2]
        L = vx * vx + vz * vz
        t = 0 if L == 0 else max(0, min(1, ((px - a[0]) * vx + (pz - a[2]) * vz) / L))
        best = min(best, math.hypot(px - a[0] - t * vx, pz - a[2] - t * vz))
    return best


def half_near(name, x, z):
    """the half width (the wider side) of a centre line at its sample nearest a point"""
    s = centres[name]
    k = min(range(len(s)), key=lambda q: (s[q][0] - x) ** 2 + (s[q][2] - z) ** 2)
    return max(s[k][6], s[k][7])


lanes = []  # dicts: road, way, lane, kind, closed, pts [(x,y,z)], outer / median ranges
index = {}  # (road, way, lane) -> position in lanes (lane 3 pieces: (road, way, 3, j))
pieces3 = {}  # (road, way) -> [{li, at_start, at_end}] lane-3 pieces in travel order


def add_lane(road, way, lane_no, pts, kind='route', closed=False, key=None, outer=None, median=None):
    index[key or (road, way, lane_no)] = len(lanes)
    lanes.append({'road': road, 'way': way, 'lane': lane_no, 'kind': kind, 'closed': closed, 'pts': pts, 'outer': outer, 'median': median})
    return len(lanes) - 1


def ranges(flags):
    """[k0, k1, ...] (1-based point ranges, piece k = point k to k + 1) where flags[k - 1] is true; True for all"""
    if flags and all(flags):
        return True
    out = []
    k = 0
    while k < len(flags):
        if not flags[k]:
            k += 1
            continue
        j = k
        while j + 1 < len(flags) and flags[j + 1]:
            j += 1
        out += [k + 1, j + 2]
        k = j + 1
    return out or None


def make_lanes(road, s, d0, d1, side_lane=False):
    """the lanes of one centre line between chain distances d0 and d1"""
    c = chain(s)
    L = d1 - d0
    n = max(2, int(round(L / STEP))) + 1
    ds = [d0 + L * k / (n - 1) for k in range(n)]
    threes = []
    if not side_lane:
        for a, b in three_runs(s, c):
            a, b = max(a, d0), min(b, d1)
            if b - a >= MIN_PIECE:
                threes.append((a, b))

    def n_eff(d):
        return 3 if any(a - 1e-6 <= d <= b + 1e-6 for a, b in threes) else 2

    def point(d, way, lane_no):
        x, y, z, dx, dz, hl, hr, w, mL, mP = at(s, c, d)
        rx, rz = -dz, dx  # right of the samples' own direction
        if side_lane:
            off = (-hl / 2) if lane_no == 1 else (hr / 2)
        else:
            ne = n_eff(d)
            h = hr if way == 1 else hl
            we = min(w, (h - mL) / ne)
            off = way * (mL + we * (lane_no - 0.5))
        return (round(x + rx * off, 2), round(y + LIFT, 2), round(z + rz * off, 2)), mP

    ways = (1,) if side_lane else (1, -1)
    for way in ways:
        for lane_no in (1, 2):
            pts, meds = [], []
            for d in ds:
                p, mP = point(d, way, lane_no)
                pts.append(p)
                meds.append(mP)
            mids = [(ds[k] + ds[k + 1]) / 2 for k in range(n - 1)]
            if way == -1:
                pts.reverse()
                meds.reverse()
                mids.reverse()
            if side_lane:
                outer = True if lane_no == 2 else None
                median = None
            else:
                outer = ranges([lane_no == 2 and n_eff(m) == 2 for m in mids]) if lane_no == 2 else None
                median = ranges([(meds[k] > 0.5 or meds[k + 1] > 0.5) for k in range(n - 1)]) if lane_no == 1 else None
            add_lane(road, way, lane_no, pts, outer=outer, median=median)
        # lane 3: a piece wherever the road has 3 lanes a side
        order = threes if way == 1 else list(reversed(threes))
        plist = []
        for j, (a, b) in enumerate(order):
            m = max(2, int(round((b - a) / STEP))) + 1
            dd = [a + (b - a) * k / (m - 1) for k in range(m)]
            pts = [point(d, way, 3)[0] for d in dd]
            if way == -1:
                pts.reverse()
            li = add_lane(road, way, 3, pts, key=(road, way, 3, j), outer=True)
            # (travel sense: way 1 runs along the chain, way -1 against it)
            st, en = (a, b) if way == 1 else (b, a)
            plist.append({'li': li, 'at_start': abs(st - (d0 if way == 1 else d1)) < 1e-6, 'at_end': abs(en - (d1 if way == 1 else d0)) < 1e-6})
        pieces3[(road, way)] = plist


def first_clear(s, other_s, other_cut, need, from_end=False):
    """chain distance along s from its start (or, from_end, its end) to the first sample at least
    `need` studs from the other road's centre line"""
    c = chain(s)
    idx = range(len(s) - 1, -1, -1) if from_end else range(len(s))
    for i in idx:
        if seg_dist(s[i][0], s[i][2], other_s, other_cut) >= need:
            return c[i]
    raise SystemExit('never clear')


def ring_clear(s, from_end=False):
    c = chain(s)
    idx = range(len(s) - 1, -1, -1) if from_end else range(len(s))
    for i in idx:
        if rad(s[i]) >= RING_EXIT:
            return c[i]
    raise SystemExit('ring never clear')


loopA, loopB = centres['Yangon Loop A'], centres['Yangon Loop B']
ua, nrc = centres['University Avenue'], centres['New Road']
west, e1, e2 = centres['Pyay Flyover West Lane'], centres['Pyay Flyover East Lane 1'], centres['Pyay Flyover East Lane 2']
kae, kaw = centres['Kabar Aye East Lane'], centres['Kabar Aye West Lane']
full_loop_cut = CUT['Yangon Loop']


# which run of the loop a junction lies on
def loop_run(x, z):
    da = seg_dist(x, z, loopA)
    db = seg_dist(x, z, loopB)
    return ('Yangon Loop A', loopA) if da < db else ('Yangon Loop B', loopB)


ua_end_run = loop_run(ua[-1][0], ua[-1][2])
nr_start_run = loop_run(nrc[0][0], nrc[0][2])

# ---------------------------------------------------------------- the lanes
cA, cB = chain(loopA), chain(loopB)
make_lanes('Yangon Loop A', loopA, ring_clear(loopA), cA[-1])
make_lanes('Yangon Loop B', loopB, 0.0, ring_clear(loopB, from_end=True))
cN = chain(nrc)
make_lanes('New Road', nrc, first_clear(nrc, nr_start_run[1], None, half_near(nr_start_run[0], nrc[0][0], nrc[0][2]) + 12), cN[-1])
cU = chain(ua)
make_lanes('University Avenue', ua, first_clear(ua, west, None, 12 + 12), first_clear(ua, ua_end_run[1], None, half_near(ua_end_run[0], ua[-1][0], ua[-1][2]) + 12, from_end=True))
make_lanes('Pyay Flyover West Lane', west, 0.0, chain(west)[-1], side_lane=True)
make_lanes('Pyay Flyover East Lane 1', e1, 0.0, first_clear(e1, ua, None, 32 + 12, from_end=True), side_lane=True)
make_lanes('Pyay Flyover East Lane 2', e2, first_clear(e2, ua, None, 32 + 12), chain(e2)[-1], side_lane=True)
make_lanes('Kabar Aye East Lane', kae, 0.0, chain(kae)[-1], side_lane=True)
make_lanes('Kabar Aye West Lane', kaw, 0.0, chain(kaw)[-1], side_lane=True)
# the widened roads (v4): each end either in the roundabout, on a road that has lanes, or at the map edge
LANE_ROADS = ['Yangon Loop A', 'Yangon Loop B', 'New Road', 'University Avenue']
extra_ends = {}  # name -> {start: (kind, big), end: (kind, big)}


def end_kind(name, p, other_names):
    if rad(p) < R_OUT + FLAT:
        return ('ring', None)
    best = None
    for o in other_names:
        if o == name:
            continue
        dd = seg_dist(p[0], p[2], centres[o])
        if dd < half_near(o, p[0], p[2]) + 24 and (best is None or dd < best[0]):
            best = (dd, o)
    return ('road', best[1]) if best else ('edge', None)


for n_ in EXTRA:
    s_ = centres[n_]
    others = LANE_ROADS + EXTRA
    ks, ke = end_kind(n_, s_[0], others), end_kind(n_, s_[-1], others)
    c_ = chain(s_)

    def clear_from(kind, big, from_end):
        if kind == 'ring':
            return ring_clear(s_, from_end=from_end)
        if kind == 'road':
            p = s_[-1] if from_end else s_[0]
            return first_clear(s_, centres[big], None, half_near(big, p[0], p[2]) + 12, from_end=from_end)
        return (c_[-1] - 30) if from_end else 30.0
    d0 = clear_from(ks[0], ks[1], False)
    d1 = clear_from(ke[0], ke[1], True)
    if d1 - d0 < 60:
        print('skipped (too short between its ends):', n_, round(d0), round(d1))
        continue
    make_lanes(n_, s_, d0, d1)
    extra_ends[n_] = {'start': ks, 'end': ke}

# the roundabout: anticlockwise = the angle atan2(z - Cz, x - Cx) falling
for lane_no, rho in RING_LANES.items():
    n = max(12, int(round(2 * math.pi * rho / STEP)))
    pts = []
    for k in range(n + 1):
        a = -2 * math.pi * k / n
        pts.append((round(C[0] + rho * math.cos(a), 2), round(C[1] + LIFT, 2), round(C[2] + rho * math.sin(a), 2)))
    pts[-1] = pts[0]
    add_lane('Hanthawaddy Roundabout', 1, lane_no, pts, closed=True, outer=True if lane_no == 2 else None)

# ---------------------------------------------------------------- links (local numbering, made global at the end)
links = []
handled = set()  # ('end' | 'start', lane index): a lane-3 piece's end that a junction rule has taken care of


def L(road, way, lane_no):
    return index[(road, way, lane_no)]


def npts(li):
    return len(lanes[li]['pts'])


def nearest(li, x, z):
    p = lanes[li]['pts']
    return min(range(len(p)), key=lambda k: math.hypot(p[k][0] - x, p[k][2] - z))


def along(li, k0, studs):
    """the point index `studs` along lane li from point k0 (negative: back)"""
    p = lanes[li]['pts']
    k, acc = k0, 0.0
    step = 1 if studs >= 0 else -1
    while 0 <= k + step < len(p) and acc < abs(studs):
        acc += math.hypot(p[k + step][0] - p[k][0], p[k + step][2] - p[k][2])
        k += step
    return k


def link(a, fromK, b, toK, why=''):
    """fromK, toK 1-based"""
    na, nb = npts(a), npts(b)
    fromK = max(2, min(na, fromK))
    toK = max(1, min(nb - 1, toK))
    links.append((a, fromK, b, toK, why))


def end_to(a, b, why=''):
    """from lane a's last point onto lane b, landing CLEAR studs past the point nearest a's end"""
    p = lanes[a]['pts'][-1]
    k = nearest(b, p[0], p[2])
    link(a, npts(a), b, along(b, k, CLEAR) + 1, why)


def to_start(a, b, why=''):
    """from lane a, CLEAR studs before the point nearest b's start, onto b's start"""
    p = lanes[b]['pts'][0]
    k = nearest(a, p[0], p[2])
    link(a, along(a, k, -CLEAR) + 1, b, 1, why)


def straight(a, b, why=''):
    """lane a runs straight on into lane b (b's first point is on a's line): a's last point onto b's
    second, so the join is a short straight piece"""
    link(a, npts(a), b, 2, why)


def change(a, studs_before_end, b, toK, why=''):
    """a lane change: from lane a at studs_before_end before its end onto lane b's point toK"""
    link(a, along(a, npts(a) - 1, -studs_before_end) + 1, b, toK, why)


def piece_at(road, way, where):
    """the lane-3 piece of (road, way) that reaches the road's travel 'start' or 'end', or None"""
    for p in pieces3.get((road, way), []):
        if p['at_' + where]:
            return p['li']
    return None


def outer_at(road, way, where):
    """the outermost lane at a road's travel start / end: its lane 3 piece there, else lane 2"""
    li = piece_at(road, way, where)
    return li if li is not None else L(road, way, 2)


def outer_near(road, way, x, z):
    """the outermost lane of (road, way) beside a point: a lane-3 piece running past it, else lane 2"""
    for p in pieces3.get((road, way), []):
        li = p['li']
        k = nearest(li, x, z)
        q = lanes[li]['pts'][k]
        if 2 <= k <= npts(li) - 3 and math.hypot(q[0] - x, q[2] - z) < 60:
            return li
    return L(road, way, 2)


# ---------------------------------------------------------------- T junctions: the middle lanes stop short (first: it moves point indices)
T_JOBS = [('University Avenue', ua, ua_end_run, True), ('New Road', nrc, nr_start_run, False)]
for n_, ends in extra_ends.items():
    for which, (kind, big) in ends.items():
        at_end = which == 'end'
        # (a junction only where both roads are at one height: New University Avenue Road meets the loop where it
        # climbs to the Kabar Aye deck, 15 studs up; there it turns round instead)
        if kind == 'road' and (big, 1, 1) in index:
            mine = lanes[L(n_, 1, 1)]['pts'][-1 if at_end else 0]
            theirs = lanes[L(big, 1, 1)]['pts']
            q = theirs[nearest(L(big, 1, 1), mine[0], mine[2])]
            if abs(q[1] - mine[1]) < 4:
                T_JOBS.append((n_, centres[n_], (big, centres[big]), at_end))
trimmed = []
for minor, minor_s, big_run, at_end in T_JOBS:
    inn = 1 if at_end else -1
    out = -inn
    if piece_at(minor, inn, 'end') is not None:  # arriving with 3 lanes: lane 2 stops TRIM short
        li = L(minor, inn, 2)
        k = along(li, npts(li) - 1, -TRIM)
        lanes[li]['pts'] = lanes[li]['pts'][:k + 1]
        trimmed.append((li, 'end'))
    if piece_at(minor, out, 'start') is not None:  # leaving with 3 lanes: lane 2 starts TRIM in
        li = L(minor, out, 2)
        k = along(li, 0, TRIM)
        lanes[li]['pts'] = lanes[li]['pts'][k:]
        trimmed.append((li, 'start'))
        # (its outer ranges move with its points)
        o = lanes[li]['outer']
        if isinstance(o, list):
            o = [max(1, x - k) for x in o]
            lanes[li]['outer'] = [x for x in o] if any(o[q + 1] > o[q] for q in range(0, len(o), 2)) else None

# ---------------------------------------------------------------- gores and lane-3 piece ends
side_l = {n_: (L(n_, 1, 1), L(n_, 1, 2)) for n_ in SIDES}
gore_done = set()  # (side lane, 'start' | 'end') handled by a lane-3 piece
for (road, way), plist in pieces3.items():
    for p in plist:
        li = p['li']
        a, b = lanes[li]['pts'][0], lanes[li]['pts'][-1]
        # runs on into a side lane that starts at its end (a gore: Pyay, the Kabar Aye west lane)
        for sn, (s1, s2) in side_l.items():
            q = lanes[s1]['pts'][0]
            if math.hypot(q[0] - b[0], q[2] - b[2]) < 12 and abs(q[1] - b[1]) < 3:
                straight(li, s1, '%s lane 3 runs on into the %s' % (road, sn))
                handled.add(('end', li))
                gore_done.add((sn, 'start'))
            # a side lane that ends at its start runs into it (both its lanes)
            q1, q2 = lanes[s1]['pts'][-1], lanes[s2]['pts'][-1]
            if math.hypot(q1[0] - a[0], q1[2] - a[2]) < 12 and abs(q1[1] - a[1]) < 3:
                link(s1, npts(s1), li, 2, 'the %s runs into %s lane 3' % (sn, road))
                link(s2, npts(s2), li, 3, 'the %s (outer) merges into %s lane 3' % (sn, road))
                handled.add(('start', li))
                gore_done.add((sn, 'end'))
        # mid-road: fed from lane 2, merging into lane 2
        if ('start', li) not in handled and not p['at_start']:
            to_start(L(road, way, 2), li, '%s lane 3 begins (from lane 2)' % road)
            handled.add(('start', li))
        if ('end', li) not in handled and not p['at_end']:
            end_to(li, L(road, way, 2), '%s lane 3 ends (into lane 2)' % road)
            handled.add(('end', li))

# straight-on joins at the loop's split and where it resumes
for ln in (1, 2):
    straight(L('Yangon Loop A', 1, ln), L('Kabar Aye East Lane', 1, ln), 'loop A into the Kabar Aye east lane')
    straight(L('Kabar Aye West Lane', 1, ln), L('Yangon Loop A', -1, ln), 'Kabar Aye west lane into loop A')
    straight(L('New Road', 1, ln), L('Yangon Loop B', 1, ln), 'New Road deck lands on loop B')
    straight(L('Yangon Loop B', -1, ln), L('New Road', -1, ln), 'loop B onto the New Road deck')
# the Kabar Aye side lanes merge into / leave run B's outer lanes over its widened start (v5: its lane 3, above,
# where run B has 3 lanes there)
lb_f2 = L('Yangon Loop B', 1, 2)
if ('Kabar Aye East Lane', 'end') not in gore_done:
    for ln in (1, 2):
        a = L('Kabar Aye East Lane', 1, ln)
        p = lanes[a]['pts'][-1]
        k = nearest(lb_f2, p[0], p[2])
        link(a, npts(a), lb_f2, along(lb_f2, k, 96 + 24 * (ln - 1)) + 1, 'Kabar Aye east lane merges into loop B')
if ('Kabar Aye West Lane', 'start') not in gore_done:
    change(L('Yangon Loop B', -1, 2), 96, L('Kabar Aye West Lane', 1, 1), 1, 'loop B leaves onto the Kabar Aye west lane')
link(L('Kabar Aye West Lane', 1, 1), 2, L('Kabar Aye West Lane', 1, 2), 4, 'split')
# Pyay: the side lanes leave and rejoin the loop's outer lanes over its widened ends
lb_b2 = L('Yangon Loop B', -1, 2)
wl1, wl2 = L('Pyay Flyover West Lane', 1, 1), L('Pyay Flyover West Lane', 1, 2)
if ('Pyay Flyover West Lane', 'start') not in gore_done:
    p = lanes[wl1]['pts'][0]
    k = nearest(lb_f2, p[0], p[2])
    link(lb_f2, along(lb_f2, k, -72) + 1, wl1, 1, 'loop B leaves onto the Pyay west lane')
link(wl1, 3, wl2, 5, 'split')
if ('Pyay Flyover West Lane', 'end') not in gore_done:
    for ln in (1, 2):
        a = L('Pyay Flyover West Lane', 1, ln)
        p = lanes[a]['pts'][-1]
        k = nearest(lb_f2, p[0], p[2])
        link(a, npts(a), lb_f2, along(lb_f2, k, 96 + 24 * (ln - 1)) + 1, 'Pyay west lane rejoins loop B')
e1l1, e1l2 = L('Pyay Flyover East Lane 1', 1, 1), L('Pyay Flyover East Lane 1', 1, 2)
if ('Pyay Flyover East Lane 1', 'start') not in gore_done:
    p = lanes[e1l1]['pts'][0]
    k = nearest(lb_b2, p[0], p[2])
    link(lb_b2, along(lb_b2, k, -72) + 1, e1l1, 1, 'loop B leaves onto the Pyay east lane')
link(e1l1, 3, e1l2, 5, 'split')
if ('Pyay Flyover East Lane 2', 'end') not in gore_done:
    for ln in (1, 2):
        a = L('Pyay Flyover East Lane 2', 1, ln)
        p = lanes[a]['pts'][-1]
        k = nearest(lb_b2, p[0], p[2])
        link(a, npts(a), lb_b2, along(lb_b2, k, 96 + 24 * (ln - 1)) + 1, 'Pyay east lane rejoins loop B')
# University Avenue across the east lanes (a crossroads under the deck)
uaf = {ln: L('University Avenue', 1, ln) for ln in (1, 2)}
uab = {ln: L('University Avenue', -1, ln) for ln in (1, 2)}
e2l = {ln: L('Pyay Flyover East Lane 2', 1, ln) for ln in (1, 2)}
for ln in (1, 2):
    a = L('Pyay Flyover East Lane 1', 1, ln)
    link(a, npts(a), e2l[ln], 1, 'east lane straight across University Avenue')
end_to(e1l2, uaf[2], 'east lane turns right onto University Avenue')
end_to(e1l1, uab[1], 'east lane turns left onto University Avenue')
to_start(uaf[1], e2l[1], 'University Avenue turns left onto the east lane')
to_start(uab[2], e2l[2], 'University Avenue turns right onto the east lane')
# University Avenue's start on the west lane (the lane is one-way south: left turns only)
to_start(wl1, uaf[1], 'west lane turns left onto University Avenue')
end_to(uab[1], wl1, 'University Avenue turns left onto the west lane')
end_to(uab[2], wl2, 'University Avenue turns left onto the west lane (outer)')


def t_junction(minor, minor_s, big_run, at_end):
    """a road meeting a bigger one at a T: its lanes away from it start / end clear of it.
    at_end: the minor road's forward lanes END at the big road (turns onto both its ways), its backward
    lanes START there (fed from both). Otherwise the reverse. Right turns from and into the outer lanes,
    left turns from and into lane 1; a middle lane 2 (3 lanes) changes lanes instead."""
    run_name, run_s = big_run
    jx, jz = (minor_s[-1][0], minor_s[-1][2]) if at_end else (minor_s[0][0], minor_s[0][2])
    # the big road's direction at the junction, and which way is a right turn for the arriving road
    kk = min(range(len(run_s)), key=lambda i: math.hypot(run_s[i][0] - jx, run_s[i][2] - jz))
    ldx, ldz = run_s[kk][3], run_s[kk][4]
    inn = 1 if at_end else -1  # the minor road's way that arrives at the big road
    out = -inn
    arr = lanes[L(minor, inn, 1)]['pts']
    ax, az = arr[-1][0] - arr[-2][0], arr[-1][2] - arr[-2][2]  # arriving direction
    cross = ax * ldz - az * ldx  # > 0: the big road's forward way is to the arriving road's right
    right_way = 1 if cross > 0 else -1
    in_outer = outer_at(minor, inn, 'end')
    out_outer = outer_at(minor, out, 'start')
    for way in (1, -1):
        big_outer = outer_near(run_name, way, jx, jz)
        if way == right_way:
            end_to(in_outer, big_outer, minor + ' turns right onto ' + run_name)
        else:
            end_to(L(minor, inn, 1), L(run_name, way, 1), minor + ' turns left onto ' + run_name)
        # from the big road into the minor: the way that runs to the arriving road's right turns RIGHT into it
        # (an eastbound road meeting a north-south road: the southbound way turns right, west, into it) from its
        # outer lane into the minor's outer lane; the other way turns left from lane 1 into lane 1
        if way == right_way:
            to_start(big_outer, out_outer, run_name + ' turns right into ' + minor)
        else:
            to_start(L(run_name, way, 1), L(minor, out, 1), run_name + ' turns left into ' + minor)
    if in_outer != L(minor, inn, 2):
        # the middle lane (trimmed above) changes into lane 1 or lane 3 before the end
        l2 = L(minor, inn, 2)
        end_to(l2, L(minor, inn, 1), minor + ' middle lane changes to lane 1')
        end_to(l2, in_outer, minor + ' middle lane changes to lane 3')
        handled.add(('end', in_outer))
    if out_outer != L(minor, out, 2):
        l2 = L(minor, out, 2)
        to_start(L(minor, out, 1), l2, minor + ' lane 1 changes into the middle lane')
        to_start(out_outer, l2, minor + ' lane 3 changes into the middle lane')
        handled.add(('start', out_outer))


for job in T_JOBS:
    t_junction(*job)
t_set = {(j[0], j[3]) for j in T_JOBS}

# the widened roads' ends: turn-rounds at the map edge or where a road isn't level with the one it meets (the
# roundabout below)
for n_, ends in extra_ends.items():
    for which, (kind, big) in ends.items():
        at_end = which == 'end'
        if (n_, at_end) in t_set or kind not in ('edge', 'road'):
            continue
        # turn round: the way arriving at this end onto the way leaving it (outer to outer, inner to inner)
        arrive, leave = (1, -1) if at_end else (-1, 1)
        for ln in (1, 2):
            link(L(n_, arrive, ln), npts(L(n_, arrive, ln)), L(n_, leave, ln), 1, n_ + ' turns round at the map edge')
        a3, l3 = piece_at(n_, arrive, 'end'), piece_at(n_, leave, 'start')
        if a3 is not None:
            link(a3, npts(a3), l3 if l3 is not None else L(n_, leave, 2), 1, n_ + ' turns round at the map edge (lane 3)')
            handled.add(('end', a3))
        if l3 is not None:
            if a3 is None:
                link(L(n_, arrive, 2), npts(L(n_, arrive, 2)), l3, 1, n_ + ' turns round at the map edge (into lane 3)')
            handled.add(('start', l3))

# the roundabout
ring = {ln: L('Hanthawaddy Roundabout', 1, ln) for ln in (1, 2)}
for ln in (1, 2):
    link(ring[ln], npts(ring[ln]), ring[ln], 1, 'round')


def ring_angle(p):
    return math.atan2(p[2] - C[2], p[0] - C[0])


def ring_k(ln, ang, studs):
    """the ring lane's point `studs` along (positive: later in travel) from angle ang"""
    p = lanes[ring[ln]]['pts']
    n = len(p) - 1
    rho = RING_LANES[ln]
    # travel = falling angle: a point's progress from ang
    best = None
    for k in range(n):
        prog = ((ang - ring_angle(p[k])) % (2 * math.pi)) * rho
        if studs >= 0 and prog >= studs and (best is None or prog < best[0]):
            best = (prog, k)
        if studs < 0:
            back = ((ring_angle(p[k]) - ang) % (2 * math.pi)) * rho
            if back >= -studs and (best is None or back < best[0]):
                best = (back, k)
    return best[1] + 1


ring_arms = [('Yangon Loop A', -1, 1), ('Yangon Loop B', 1, -1)]
for n_, ends in extra_ends.items():
    if ends['start'][0] == 'ring':
        ring_arms.append((n_, -1, 1))  # (starts in the ring: its backward way arrives, its forward way leaves)
    if ends['end'][0] == 'ring':
        ring_arms.append((n_, 1, -1))
for run, way_in, way_out in ring_arms:
    arms_in = [(ln, L(run, way_in, ln)) for ln in (1, 2)]
    arms_out = [(ln, L(run, way_out, ln)) for ln in (1, 2)]
    # (a lane 3 reaching the ring joins its lane 2, a little further on; one leaving it is fed from ring lane 2)
    a3, b3 = piece_at(run, way_in, 'end'), piece_at(run, way_out, 'start')
    if a3 is not None:
        arms_in.append((3, a3))
        handled.add(('end', a3))
    if b3 is not None:
        arms_out.append((3, b3))
        handled.add(('start', b3))
    for ln, a in arms_in:
        rl = min(ln, 2)
        pa = lanes[a]['pts'][-1]
        link(a, npts(a), ring[rl], ring_k(rl, ring_angle(pa), CLEAR + 6 + (24 if ln == 3 else 0)), 'into the roundabout')
    for ln, b in arms_out:
        rl = min(ln, 2)
        pb = lanes[b]['pts'][0]
        k = ring_k(rl, ring_angle(pb), -(CLEAR + 6 + (24 if ln == 3 else 0)))
        link(ring[rl], max(2, k), b, 1, 'out of the roundabout')

# T junctions also took their lane-3 ends (t_junction marks them); anything left over merges into / is fed by lane 2
for (road, way), plist in pieces3.items():
    for p in plist:
        li = p['li']
        if p['at_end'] and ('end', li) not in handled:
            # (its end was not met by a rule: it ends where lane 2 does, so it turns where lane 2 turns)
            for a, fk, b, tk, why in list(links):
                if a == L(road, way, 2) and fk == npts(a):
                    link(li, npts(li), b, tk, why + ' (lane 3)')
            handled.add(('end', li))
        if p['at_start'] and ('start', li) not in handled:
            for a, fk, b, tk, why in list(links):
                if b == L(road, way, 2) and tk == 1:
                    link(a, fk, li, 1, why + ' (lane 3)')
            handled.add(('start', li))

# ---------------------------------------------------------------- checks
errors = []
starts_fed = {i: 0 for i in range(len(lanes))}
ends_out = {i: 0 for i in range(len(lanes))}
for a, fk, b, tk, why in links:
    if not (2 <= fk <= npts(a)) or not (1 <= tk <= npts(b) - 1):
        errors.append('bad index %s' % str((a, fk, b, tk, why)))
    if fk == npts(a):
        ends_out[a] += 1
    if tk <= 2:  # (a straight join lands on point 2)
        starts_fed[b] += 1
for i, l in enumerate(lanes):
    if not l['closed'] and ends_out[i] == 0:
        errors.append('dead end: %s way %d lane %d' % (l['road'], l['way'], l['lane']))
    if len(l['pts']) < 2:
        errors.append('too short: ' + l['road'])
unfed = ['%s way %d lane %d' % (l['road'], l['way'], l['lane']) for i, l in enumerate(lanes) if not l['closed'] and starts_fed[i] == 0]
# every lane point on its own carriageway and clear of the median (v5): at least 3 studs from the built median's
# kerb and 3 from the carriageway's edge (a car is ~6 wide)
on_median, off_edge = [], []
for l in lanes:
    if l['road'] not in centres or l['road'] in SIDES or l['closed']:
        continue
    s = centres[l['road']]
    c = chain(s)
    for p in l['pts'][1:-1]:
        k = min(range(len(s)), key=lambda q: (s[q][0] - p[0]) ** 2 + (s[q][2] - p[2]) ** 2)
        q = s[k]
        Lh = math.hypot(q[3], q[4])
        lat = (p[0] - q[0]) * (-q[4] / Lh) + (p[2] - q[2]) * (q[3] / Lh)
        mP = geo(q)[3]
        h = q[7] if lat > 0 else q[6]
        if abs(lat) < mP + 3:
            on_median.append('%s way %d lane %d at %.0f, %.0f (%.1f out, median %.1f)' % (l['road'], l['way'], l['lane'], p[0], p[2], lat, mP))
        if abs(lat) > h - 3:
            off_edge.append('%s way %d lane %d at %.0f, %.0f (%.1f out, half %.1f)' % (l['road'], l['way'], l['lane'], p[0], p[2], lat, h))
# link lengths and turn angles (a sanity check, the curves are RivieraTraffic's)
long_links = []
for a, fk, b, tk, why in links:
    p, q = lanes[a]['pts'][fk - 1], lanes[b]['pts'][tk - 1]
    dist = math.hypot(q[0] - p[0], q[2] - p[2])
    if dist > 140 or abs(q[1] - p[1]) > 4:
        long_links.append('%s: %.0f studs, dy %.1f' % (why, dist, q[1] - p[1]))

# ---------------------------------------------------------------- write
riv = open(os.path.join(ROOT, 'src', 'shared', 'RivieraLanes.lua'), encoding='utf-8').read()
hw = open(os.path.join(ROOT, 'src', 'shared', 'RivieraLanesHighway.lua'), encoding='utf-8').read()
n_riv = len(re.findall(r'\{ road = ', riv))
n_hw = len(re.findall(r'\{ road = ', hw))
first = n_riv + n_hw + 1


def fmt(v):
    s = ('%.2f' % v).rstrip('0').rstrip('.')
    return s if s not in ('-0', '') else '0'


def lua_ranges(v):
    if v is True:
        return 'true'
    return '{ ' + ', '.join(str(x) for x in v) + ' }'


def lane_line(l):
    pts = ','.join('%s,%s,%s' % (fmt(p[0]), fmt(p[1]), fmt(p[2])) for p in l['pts'])
    extra = ''
    if l['outer']:
        extra += ', outer = ' + lua_ranges(l['outer'])
    if l['median']:
        extra += ', median = ' + lua_ranges(l['median'])
    return '\t\t{ road = "%s", way = %d, lane = %d, kind = "%s", closed = %s, yangon = true%s, pts = { %s } },' % (
        l['road'], l['way'], l['lane'], l['kind'], 'true' if l['closed'] else 'false', extra, pts)


HEAD = ['-- generated by tools/yangon/d9_lanes.py from imports/refs/map/ygn_roads_v5.json: do not edit',
        "-- the Yangon map's traffic lanes (main roads, flyover decks and side lanes, the roundabout), numbered on",
        '-- from RivieraLanes + RivieraLanesHighway; links in that global numbering (RivieraTraffic.build)']
link_lines = ['\t\t{ %d, %d, %d, %d }, -- %s' % (a + first, fk, b + first, tk, why) for a, fk, b, tk, why in links]
lane_lines = [lane_line(l) for l in lanes]
NLC = chr(10)


def module(first_no, lane_rows, link_rows, more, head):
    out = head + ['return {', '\tfirst = %d,' % first_no]
    if more:
        out.append('\tmore = true, -- (the rest of the lanes and links: YangonLanes2)')
    out += ['\tlanes = {'] + lane_rows + ['\t},', '\tlinks = {'] + link_rows + ['\t},', '}']
    return NLC.join(out) + NLC


one = module(first, lane_lines, link_lines, False, HEAD)
if len(one) < MAX_CHARS:
    srcs = [(OUT, one)]
else:
    # the first module takes lanes while it stays under the limit; the second the rest and every link
    used = len(module(first, [], [], True, HEAD))
    cut_at = 0
    while cut_at < len(lane_lines) and used + len(lane_lines[cut_at]) + 1 < MAX_CHARS - 2000:
        used += len(lane_lines[cut_at]) + 1
        cut_at += 1
    m1 = module(first, lane_lines[:cut_at], [], True, HEAD)
    m2 = module(first + cut_at, lane_lines[cut_at:], link_lines, False,
                ['-- generated by tools/yangon/d9_lanes.py: the second half of YangonLanes (lanes numbered on from its own), do not edit'])
    assert len(m2) < MAX_CHARS, len(m2)
    srcs = [(OUT, m1), (OUT2, m2)]
for path, src in srcs:
    assert len(src) < MAX_CHARS, (path, len(src))
    open(path, 'w', encoding='utf-8', newline=NLC).write(src)
if len(srcs) == 1 and os.path.exists(OUT2):
    os.remove(OUT2)

n3 = sum(1 for l in lanes if l['lane'] == 3)
print('%d lanes (numbered %d..%d; %d lane-3 pieces), %d links, %d points; %s' % (
    len(lanes), first, first + len(lanes) - 1, n3, len(links), sum(len(l['pts']) for l in lanes),
    ', '.join('%s %d characters' % (os.path.basename(p), len(s)) for p, s in srcs)))
print('loop runs: A 0..%d, B %d..%d (Kabar Aye deck lands at %d); %d T junctions, %d middle lanes trimmed' % (K0, KRES, len(loop) - 1, KRES, len(T_JOBS), len(trimmed)))
print('University Avenue ends on %s, New Road starts on %s' % (ua_end_run[0], nr_start_run[0]))
print('errors: %s' % ('none' if not errors else '\n  '.join(errors)))
print('lane points within 3 studs of a median kerb: %s' % ('none' if not on_median else '%d, e.g. %s' % (len(on_median), '; '.join(on_median[:5]))))
print('lane points within 3 studs of the carriageway edge: %s' % ('none' if not off_edge else '%d, e.g. %s' % (len(off_edge), '; '.join(off_edge[:5]))))
print('lane starts no link feeds: %s' % ('none' if not unfed else '%d: %s' % (len(unfed), ', '.join(unfed))))
if '--links' in sys.argv:
    for a, fk, b, tk, why in links:
        if lanes[a]['lane'] == 3 or lanes[b]['lane'] == 3 or 'middle' in why:
            print('  %s w%d l%d k%d/%d -> %s w%d l%d k%d: %s' % (lanes[a]['road'], lanes[a]['way'], lanes[a]['lane'], fk, npts(a), lanes[b]['road'], lanes[b]['way'], lanes[b]['lane'], tk, why))
print('links longer than 140 studs or over 4 studs up / down: %s' % ('none' if not long_links else '\n  '.join(long_links)))

if '--plot' in sys.argv:
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    outdir = sys.argv[sys.argv.index('--plot') + 1]
    os.makedirs(outdir, exist_ok=True)
    views = {'all': None, 'pyay': (28300, 28900, -2100, 0), 'kabaraye': (32150, 32650, -1300, -500),
             'ring': (28850, 29300, 950, 1400), 'ua_end': None, 'nr_start': None}
    jx = {'ua_end': (ua[-1][0], ua[-1][2]), 'nr_start': (nrc[0][0], nrc[0][2])}
    for name, box in views.items():
        fig, ax = plt.subplots(figsize=(12, 12))
        for o in data['roads']:
            s = o['s']
            ax.plot([p[0] for p in s], [p[2] for p in s], color='#ddd', lw=0.6)
        for i, l in enumerate(lanes):
            col = '#c33' if l['way'] == 1 else '#33c'
            if l['road'] in SIDES:
                col = '#3a3'
            if l['closed']:
                col = '#a3a'
            if l['lane'] == 3:
                col = '#0aa'
            xs = [p[0] for p in l['pts']]
            zs = [p[2] for p in l['pts']]
            ax.plot(xs, zs, color=col, lw=1)
            ax.annotate('', xy=(xs[-1], zs[-1]), xytext=(xs[-2], zs[-2]), arrowprops=dict(arrowstyle='->', color=col))
        for a, fk, b, tk, why in links:
            p, q = lanes[a]['pts'][fk - 1], lanes[b]['pts'][tk - 1]
            ax.plot([p[0], q[0]], [p[2], q[2]], color='#f90', lw=0.8)
        if box is None and name in jx:
            x, z = jx[name]
            box = (x - 160, x + 160, z - 160, z + 160)
        if box:
            ax.set_xlim(box[0], box[1])
            ax.set_ylim(box[2], box[3])
        ax.set_aspect('equal')
        ax.invert_yaxis()
        ax.set_title('Yangon lanes: %s (red forward, blue back, cyan lane 3, green side lanes, purple ring, orange links)' % name)
        fig.savefig(os.path.join(outdir, 'd9_%s.png' % name), dpi=90)
        plt.close(fig)
    print('plots in', outdir)
