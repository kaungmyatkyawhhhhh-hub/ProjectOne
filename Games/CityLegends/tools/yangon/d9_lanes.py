"""Yangon map, build step 7 (13 Nov 2026): NPC traffic lanes for the main roads.

Reads imports/refs/map/ygn_roads_v3.json and writes src/shared/YangonLanes.lua in the format of
src/shared/RivieraLanes.lua / RivieraLanesHighway.lua (see RivieraTraffic.lua): lane records
{ road, way, lane, kind, closed, pts = { x,y,z, ... } } with points every ~24 studs in the direction of
travel, y = surface + 0.15, and links { fromLane, fromK, toLane, toK } in the GLOBAL lane numbering
(this module's lanes are numbered on from RivieraLanes + RivieraLanesHighway: `first`).

Owner's rule: traffic only on the main roads (the loop, New Road, University Avenue), their flyover
decks and side lanes, and the Hanthawaddy Roundabout. Streets get no lanes.

  * Right-hand traffic (Myanmar). A 2+2 road: lane 1 (inner) 8 studs right of the centre line, lane 2
    (outer) 24 right, each way.
  * A side lane is one-way, in the order of its samples: lane 1 is its left lane (the deck side), lane 2
    its right, each half its half width from its centre (the Kabar Aye lanes are 16 wide at their split,
    so their lanes start exactly on the loop's own lanes).
  * The loop is two runs: A (the roundabout to where it splits into the Kabar Aye side lanes, samples
    0..789) and B (where it resumes, 838, round over the Pyay deck back to the roundabout).
  * New Road runs on over its deck and lands on the loop at 838; its forward lanes go straight on into
    run B, run B's backward lanes go straight on onto it.
  * The roundabout: two closed lanes, inner radius 76 and outer 96, anticlockwise (traffic keeps right).
  * A lane that meets another road's lane at a junction stops BEFORE_JUNCTION clear of that road's
    centre line; the turn links land at least CLEAR studs along the other lane (RivieraTraffic draws the
    turn curves between them). A lane that runs straight on into another stops one point short, so the
    join is a short straight lane change and never a zero-length piece.

Run from Games/CityLegends:  python tools/yangon/d9_lanes.py [--plot outdir]
"""
import json, math, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
MAP = os.path.join(ROOT, 'imports', 'refs', 'map')
OUT = os.path.join(ROOT, 'src', 'shared', 'YangonLanes.lua')
STEP = 24.0
LIFT = 0.15
CLEAR = 18.0
C = (29072.0, 47.27, 1172.8)  # the roundabout's centre at the ring's road height (YangonRoads.M.C)
R_OUT, FLAT, EASE = 108.0, 12.0, 128.0  # (YangonRoads: the arms are eased onto the ring's height)
RING_EXIT = 114.0  # loop lanes stop / start this far from the roundabout's centre
RING_LANES = {1: 76.0, 2: 96.0}

# (14 Nov 2026: v4 = the real 4+ lane roads widened to 2+2 routes, tools/yangon/d18_widen.py; they get traffic too)
data = json.load(open(os.path.join(MAP, 'ygn_roads_v4.json'), encoding='utf-8'))
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
K0, KRES = 789, 838  # the loop ends here (run A) and resumes here (run B)

centres = {
    'Yangon Loop A': loop[0:K0 + 1],
    'Yangon Loop B': loop[KRES:],  # (over the Pyay deck: the loop's own samples carry the deck's heights)
    'New Road': [list(p) for p in nr[0:572]] + [list(p) for p in ka_deck],
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


def at(s, c, d):
    """centre point, unit direction and half widths at chain distance d"""
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
    return x, y, z, dx / L, dz / L, hl, hr


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


lanes = []  # dicts: road, way, lane, kind, closed, pts [(x,y,z)], plus our own: name key
index = {}  # (road, way, lane) -> position in lanes


def add_lane(road, way, lane_no, pts, kind='route', closed=False):
    index[(road, way, lane_no)] = len(lanes)
    lanes.append({'road': road, 'way': way, 'lane': lane_no, 'kind': kind, 'closed': closed, 'pts': pts})


def make_lanes(road, s, d0, d1, side_lane=False):
    """the lanes of one centre line between chain distances d0 and d1"""
    c = chain(s)
    L = d1 - d0
    n = max(2, int(round(L / STEP))) + 1
    ds = [d0 + L * k / (n - 1) for k in range(n)]
    ways = (1,) if side_lane else (1, -1)
    for way in ways:
        for lane_no in (1, 2):
            pts = []
            for d in ds:
                x, y, z, dx, dz, hl, hr = at(s, c, d)
                rx, rz = -dz, dx  # right of the samples' own direction
                if side_lane:
                    off = (-hl / 2) if lane_no == 1 else (hr / 2)
                else:
                    off = way * (8.0 if lane_no == 1 else 24.0)
                pts.append((round(x + rx * off, 2), round(y + LIFT, 2), round(z + rz * off, 2)))
            if way == -1:
                pts.reverse()
            add_lane(road, way, lane_no, pts)


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


H = {n_: (R[n_]['half'] if n_ in R else 32) for n_ in centres}
H['Yangon Loop A'] = H['Yangon Loop B'] = 32
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
make_lanes('New Road', nrc, first_clear(nrc, nr_start_run[1], None, 32 + 12), cN[-1])
cU = chain(ua)
make_lanes('University Avenue', ua, first_clear(ua, west, None, 12 + 12), first_clear(ua, ua_end_run[1], None, 32 + 12, from_end=True))
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
        if dd < H.get(o, 32) + 24 and (best is None or dd < best[0]):
            best = (dd, o)
    return ('road', best[1]) if best else ('edge', None)


for n_ in EXTRA:
    H[n_] = 32
for n_ in EXTRA:
    s_ = centres[n_]
    others = LANE_ROADS + EXTRA
    ks, ke = end_kind(n_, s_[0], others), end_kind(n_, s_[-1], others)
    c_ = chain(s_)
    def clear_from(kind, big, from_end):
        if kind == 'ring':
            return ring_clear(s_, from_end=from_end)
        if kind == 'road':
            return first_clear(s_, centres[big], None, H[big] + 12, from_end=from_end)
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
    add_lane('Hanthawaddy Roundabout', 1, lane_no, pts, closed=True)

# ---------------------------------------------------------------- links (local numbering, made global at the end)
links = []


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


# straight-on joins at the loop's split and where it resumes
for ln in (1, 2):
    straight(L('Yangon Loop A', 1, ln), L('Kabar Aye East Lane', 1, ln), 'loop A into the Kabar Aye east lane')
    straight(L('Kabar Aye West Lane', 1, ln), L('Yangon Loop A', -1, ln), 'Kabar Aye west lane into loop A')
    straight(L('New Road', 1, ln), L('Yangon Loop B', 1, ln), 'New Road deck lands on loop B')
    straight(L('Yangon Loop B', -1, ln), L('New Road', -1, ln), 'loop B onto the New Road deck')
# the Kabar Aye side lanes merge into / leave run B's outer lanes over its widened start
lb_f2 = L('Yangon Loop B', 1, 2)
for ln in (1, 2):
    a = L('Kabar Aye East Lane', 1, ln)
    p = lanes[a]['pts'][-1]
    k = nearest(lb_f2, p[0], p[2])
    link(a, npts(a), lb_f2, along(lb_f2, k, 96 + 24 * (ln - 1)) + 1, 'Kabar Aye east lane merges into loop B')
change(L('Yangon Loop B', -1, 2), 96, L('Kabar Aye West Lane', 1, 1), 1, 'loop B leaves onto the Kabar Aye west lane')
link(L('Kabar Aye West Lane', 1, 1), 2, L('Kabar Aye West Lane', 1, 2), 4, 'split')
# Pyay: the side lanes leave and rejoin the loop's outer lanes over its widened ends
lb_b2 = L('Yangon Loop B', -1, 2)
wl1, wl2 = L('Pyay Flyover West Lane', 1, 1), L('Pyay Flyover West Lane', 1, 2)
p = lanes[wl1]['pts'][0]
k = nearest(lb_f2, p[0], p[2])
link(lb_f2, along(lb_f2, k, -72) + 1, wl1, 1, 'loop B leaves onto the Pyay west lane')
link(wl1, 3, wl2, 5, 'split')
for ln in (1, 2):
    a = L('Pyay Flyover West Lane', 1, ln)
    p = lanes[a]['pts'][-1]
    k = nearest(lb_f2, p[0], p[2])
    link(a, npts(a), lb_f2, along(lb_f2, k, 96 + 24 * (ln - 1)) + 1, 'Pyay west lane rejoins loop B')
e1l1, e1l2 = L('Pyay Flyover East Lane 1', 1, 1), L('Pyay Flyover East Lane 1', 1, 2)
p = lanes[e1l1]['pts'][0]
k = nearest(lb_b2, p[0], p[2])
link(lb_b2, along(lb_b2, k, -72) + 1, e1l1, 1, 'loop B leaves onto the Pyay east lane')
link(e1l1, 3, e1l2, 5, 'split')
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
    """a 2+2 road meeting the loop at a T: its lanes away from the loop start / end clear of it.
    at_end: the minor road's forward lanes END at the loop (turns onto both loop ways), its backward
    lanes START there (fed from both). Otherwise the reverse."""
    run_name, run_s = big_run
    jx, jz = (minor_s[-1][0], minor_s[-1][2]) if at_end else (minor_s[0][0], minor_s[0][2])
    # the loop's direction at the junction, and which way is a right turn for the arriving road
    rc = chain(run_s)
    kk = min(range(len(run_s)), key=lambda i: math.hypot(run_s[i][0] - jx, run_s[i][2] - jz))
    ldx, ldz = run_s[kk][3], run_s[kk][4]
    arr = lanes[L(minor, 1 if at_end else -1, 1)]['pts']
    ax, az = arr[-1][0] - arr[-2][0], arr[-1][2] - arr[-2][2]  # arriving direction
    cross = ax * ldz - az * ldx  # > 0: the loop's forward way is to the arriving road's right
    right_way = 1 if cross > 0 else -1
    inn = 1 if at_end else -1  # the minor road's way that arrives at the loop
    out = -inn
    for way in (1, -1):
        turn = 2 if way == right_way else 1  # right turns use the outer lanes, left turns the inner
        end_to(L(minor, inn, turn), L(run_name, way, turn), minor + ' turns onto the loop')
        # from the loop into the minor road: the loop way that runs to the arriving road's right turns RIGHT
        # into it (an eastbound road meeting a north-south road: the southbound way turns right, west, into
        # it) and uses its outer lane; the other way turns left from its inner lane
        way_right_into = (way == right_way)
        lane_from = 2 if way_right_into else 1
        to_start(L(run_name, way, lane_from), L(minor, out, lane_from), 'loop turns into ' + minor)


t_junction('University Avenue', ua, ua_end_run, at_end=True)
t_junction('New Road', nrc, nr_start_run, at_end=False)

# the widened roads' ends: T junctions with a lane road, turn-rounds at the map edge (the roundabout below)
for n_, ends in extra_ends.items():
    for which, (kind, big) in ends.items():
        at_end = which == 'end'
        # (a junction only where both roads are at one height: New University Avenue Road meets the loop where it
        # climbs to the Kabar Aye deck, 15 studs up; there it turns round instead)
        level = False
        if kind == 'road' and (big, 1, 1) in index:
            mine = lanes[L(n_, 1, 1)]['pts'][-1 if at_end else 0]
            theirs = lanes[L(big, 1, 1)]['pts']
            q = theirs[nearest(L(big, 1, 1), mine[0], mine[2])]
            level = abs(q[1] - mine[1]) < 4
        if level:
            t_junction(n_, centres[n_], (big, centres[big]), at_end)
        elif kind in ('edge', 'road'):
            # turn round: the way arriving at this end onto the way leaving it (outer to outer, inner to inner)
            arrive, leave = (1, -1) if at_end else (-1, 1)
            for ln in (1, 2):
                link(L(n_, arrive, ln), npts(L(n_, arrive, ln)), L(n_, leave, ln), 1, n_ + ' turns round at the map edge')

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
    for ln in (1, 2):
        a = L(run, way_in, ln)  # arrives at the ring
        pa = lanes[a]['pts'][-1]
        link(a, npts(a), ring[ln], ring_k(ln, ring_angle(pa), CLEAR + 6), 'into the roundabout')
        b = L(run, way_out, ln)  # leaves it
        pb = lanes[b]['pts'][0]
        k = ring_k(ln, ring_angle(pb), -(CLEAR + 6))
        link(ring[ln], max(2, k), b, 1, 'out of the roundabout')

# ---------------------------------------------------------------- checks
errors = []
starts_fed = {i: 0 for i in range(len(lanes))}
ends_out = {i: 0 for i in range(len(lanes))}
for a, fk, b, tk, why in links:
    if not (2 <= fk <= npts(a)) or not (1 <= tk <= npts(b) - 1):
        errors.append('bad index %s' % str((a, fk, b, tk, why)))
    if fk == npts(a):
        ends_out[a] += 1
    if tk == 1:
        starts_fed[b] += 1
for i, l in enumerate(lanes):
    if not l['closed'] and ends_out[i] == 0:
        errors.append('dead end: %s way %d lane %d' % (l['road'], l['way'], l['lane']))
    if len(l['pts']) < 2:
        errors.append('too short: ' + l['road'])
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


lines = ['-- generated by tools/yangon/d9_lanes.py from imports/refs/map/ygn_roads_v3.json: do not edit',
         "-- the Yangon map's traffic lanes (main roads, flyover decks and side lanes, the roundabout), numbered on",
         '-- from RivieraLanes + RivieraLanesHighway; links in that global numbering (RivieraTraffic.build)',
         'return {', '\tfirst = %d,' % first, '\tlanes = {']
for l in lanes:
    pts = ','.join('%s,%s,%s' % (fmt(p[0]), fmt(p[1]), fmt(p[2])) for p in l['pts'])
    lines.append('\t\t{ road = "%s", way = %d, lane = %d, kind = "%s", closed = %s, yangon = true, pts = { %s } },' % (
        l['road'], l['way'], l['lane'], l['kind'], 'true' if l['closed'] else 'false', pts))
lines.append('\t},')
lines.append('\tlinks = {')
for a, fk, b, tk, why in links:
    lines.append('\t\t{ %d, %d, %d, %d }, -- %s' % (a + first, fk, b + first, tk, why))
lines.append('\t},')
lines.append('}')
src = '\n'.join(lines) + '\n'
assert len(src) < 199000, len(src)
open(OUT, 'w', encoding='utf-8', newline='\n').write(src)

print('%d lanes (numbered %d..%d), %d links, %d points, %d characters' % (len(lanes), first, first + len(lanes) - 1, len(links), sum(len(l['pts']) for l in lanes), len(src)))
print('University Avenue ends on %s, New Road starts on %s' % (ua_end_run[0], nr_start_run[0]))
print('errors: %s' % ('none' if not errors else '\n  '.join(errors)))
print('links longer than 140 studs or over 4 studs up / down: %s' % ('none' if not long_links else '\n  '.join(long_links)))

if '--plot' in sys.argv:
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    outdir = sys.argv[sys.argv.index('--plot') + 1]
    os.makedirs(outdir, exist_ok=True)
    views = {'all': None, 'pyay': (28300, 28900, -2100, 0), 'kabaraye': (32150, 32650, -1100, -500),
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
        ax.set_title('Yangon lanes: %s (red forward, blue back, green side lanes, purple ring, orange links)' % name)
        fig.savefig(os.path.join(outdir, 'd9_%s.png' % name), dpi=90)
        plt.close(fig)
    print('plots in', outdir)
