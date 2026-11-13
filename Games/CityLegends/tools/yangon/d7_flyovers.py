"""Yangon map, build step 4 (13 Nov 2026): the two flyovers' ground roads, as road data.

Reads imports/refs/map/ygn_roads.json (steps 2 and 3) and ygn_road_design.json (flyovers, ground grid) and
writes imports/refs/map/ygn_roads_v2.json: the same roads plus

  * the decks, as their own roads ("deck": built apart, surface only, with parapets, girders and piers):
      - "Pyay Road Flyover": the loop's samples 2686..2985 (its ends are the loop's square cut ends)
      - "Kabar Aye Flyover": New Road's samples 572..679, ending on the loop's line where its ramp lands
  * the side lanes at ground (kind "side", one-way, 24 wide, centre 48 from the deck's centre line,
    a 3.5-stud strip on the deck side, the usual pavement outside):
      - Pyay: one each side of the loop's deck, leaving the loop's outer lanes before the ramp and joining
        them after it. The east one is cut in two where University Avenue crosses under the deck.
      - Kabar Aye: the loop itself, split in two at its end south of the flyover, one lane each side of New
        Road's ramp, joining the loop again north of where the ramp lands.
  * University Avenue carried on under the Pyay deck to the west side lane (along Hledan Road's line);
    Hledan Road, Nar Nat Taw Road and New University Avenue Road shortened to end on a side lane.
  * "cut": every sample that is not built by the ground roads (the decks' own, the loop where the Kabar
    Aye side lanes take over, New Road under its own deck).

The heights of the side lanes come from the smoothed ground grid (the same grid the terrain and the
roads were made from). Ranks: lower = bigger road (Roads.luau). Plain JSON, no design chain needed.
Run from Games/CityLegends:  python tools/yangon/d7_flyovers.py [--plot outdir]
"""
import json, math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
MAP = os.path.join(ROOT, 'imports', 'refs', 'map')
OX, OZ, SPM = 30000.0, 0.0, 1.6
STEP = 6.4
SIDE_OFF, SIDE_HALF, SIDE_START = 48.0, 12.0, 20.0  # side lane centre from the deck line; half width; where a fork starts
SIDE_INNER_WALK = 3.5  # the strip between a side lane and the deck's wall / piers

roads = json.load(open(os.path.join(MAP, 'ygn_roads.json'), encoding='utf-8'))
design = json.load(open(os.path.join(MAP, 'ygn_road_design.json'), encoding='utf-8'))
G = design['ground']
R = {r['name']: r for r in roads['roads']}


def ground(X, Z):
    """road height (studs) of the smoothed ground at a world point (YangonTerrain.height)"""
    x, y = (X - OX) / SPM, (OZ - Z) / SPM
    nx, ny = G['nx'], G['ny']
    dx = (G['east_m'] - G['west_m']) / (nx - 1)
    dy = (G['north_m'] - G['south_m']) / (ny - 1)
    fi = min(max((x - G['west_m']) / dx, 0), nx - 1.001)
    fj = min(max((y - G['south_m']) / dy, 0), ny - 1.001)
    i, j = int(fi), int(fj)
    a, b = fi - i, fj - j
    h = G['height_m']
    v = h[j][i] * (1 - a) * (1 - b) + h[j][i + 1] * a * (1 - b) + h[j + 1][i] * (1 - a) * b + h[j + 1][i + 1] * a * b
    return v * SPM


def chain(s):
    c = [0.0]
    for k in range(1, len(s)):
        c.append(c[-1] + math.hypot(s[k][0] - s[k - 1][0], s[k][2] - s[k - 1][2]))
    return c


class Line:
    """a road's centre line as a function of distance along it"""

    def __init__(self, s):
        self.s = s
        self.c = chain(s)

    def at(self, d):
        c, s = self.c, self.s
        d = min(max(d, 0), c[-1])
        lo, hi = 0, len(c) - 1
        while hi - lo > 1:
            m = (lo + hi) // 2
            if c[m] <= d:
                lo = m
            else:
                hi = m
        t = (d - c[lo]) / max(c[hi] - c[lo], 1e-9)
        a, b = s[lo], s[hi]
        x, y, z = (a[k] + (b[k] - a[k]) * t for k in range(3))
        dx, dz = b[0] - a[0], b[2] - a[2]
        L = math.hypot(dx, dz)
        return x, y, z, dx / L, dz / L


def smooth(u):
    u = min(max(u, 0.0), 1.0)
    return u * u * (3 - 2 * u)


def lane(line, d0, d1, offset, half_fn, height_fn, name, side):
    """samples of a lane that runs beside `line` from d0 to d1 at lateral offset(d) (right of the line's
    direction for side +1), every STEP studs"""
    n = max(2, int(round((d1 - d0) / STEP)) + 1)
    pts = []
    for k in range(n):
        d = d0 + (d1 - d0) * k / (n - 1)
        x, y, z, tx, tz = line.at(d)
        # (on a sample of the line: offset along that sample's own stored direction, as Roads.build lays
        # its cross-section; the chord's differs by up to 2 degrees, half a stud at 16 out: LaneCheck found
        # the gap it left at the Kabar Aye split)
        j = min(range(len(line.c)), key=lambda q: abs(line.c[q] - d))
        if abs(line.c[j] - d) < 1e-6:
            Ls = math.hypot(line.s[j][3], line.s[j][4])
            tx, tz = line.s[j][3] / Ls, line.s[j][4] / Ls
        rx, rz = -tz, tx
        o = offset(d) * side
        pts.append([x + rx * o, z + rz * o, d])
    out = []
    for k, p in enumerate(pts):
        a, b = pts[max(k - 1, 0)], pts[min(k + 1, n - 1)]
        dx, dz = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dz)
        dx, dz = dx / L, dz / L
        if side < 0:  # (the west / left lane runs the other way: traffic keeps right)
            dx, dz = -dx, -dz
        h = half_fn(p[2])
        out.append([round(p[0], 2), round(height_fn(p[0], p[1], p[2]), 2), round(p[1], 2), round(dx, 4), round(dz, 4), 0, h, h])
    # (step 7, LaneCheck: a lane's end cross-section must lie exactly on the loop's own cross-section where
    # it leaves or joins the loop's end. The chord to the next point turned it a few degrees on the
    # Kabar Aye split, leaving a gap up to a stud wide on one side. Both ends take the line's direction.)
    for k, d in ((0, d0), (n - 1, d1)):
        _, _, _, tx, tz = line.at(d)
        # (on a sample of the line: that sample's own stored direction, which Roads.build lays its
        # cross-section by; Line.at's tangent differs from it by up to 2 degrees)
        j = min(range(len(line.c)), key=lambda q: abs(line.c[q] - d))
        if abs(line.c[j] - d) < 1e-6:
            tx, tz = line.s[j][3], line.s[j][4]
        Lt = math.hypot(tx, tz)
        sgn = -1 if side < 0 else 1
        out[k][3], out[k][4] = round(sgn * tx / Lt, 4), round(sgn * tz / Lt, 4)
    if side < 0:
        out.reverse()
    return out


def cross_split(lane_s, other, other_half):
    """cut a lane in two where it crosses another road: (before, after), each ending inside the other road"""
    def dist(p):
        best = 1e9
        for k in range(len(other) - 1):
            a, b = other[k], other[k + 1]
            vx, vz = b[0] - a[0], b[2] - a[2]
            L = vx * vx + vz * vz
            t = 0 if L == 0 else max(0, min(1, ((p[0] - a[0]) * vx + (p[2] - a[2]) * vz) / L))
            best = min(best, math.hypot(p[0] - a[0] - t * vx, p[2] - a[2] - t * vz))
        return best
    ds = [dist(p) for p in lane_s]
    k = min(range(len(ds)), key=lambda i: ds[i])
    if ds[k] > other_half:
        raise SystemExit('cross_split: the lane never crosses')
    # the first sample of each half lies on the other road's centre line side of its edge
    i0 = k
    while i0 > 0 and ds[i0 - 1] < other_half - 2:
        i0 -= 1
    i1 = k
    while i1 < len(ds) - 1 and ds[i1 + 1] < other_half - 2:
        i1 += 1
    return lane_s[:i0 + 1], lane_s[i1:]


def nearest(s, x, z):
    return min(range(len(s)), key=lambda i: math.hypot(s[i][0] - x, s[i][2] - z))


new_roads = []
cut = {}
decks = []

# ---------------------------------------------------------------- Pyay Road Flyover (the loop)
loop = R['Yangon Loop']['s']
L = Line(loop)
D0, D1 = 2686, 2985
dA, dB = L.c[D0], L.c[D1]
FORK = 128.0  # studs over which a side lane leaves (or joins) the loop

# (13 Nov, second design) the loop widens to the lanes' outer edges over FORK before the deck (and narrows
# after it): the deck and both side lanes then all start square on the loop's last cross-section, like a
# real gore. No lane runs inside another road's carriageway (no clipped slabs, no kerb rules for a fork).
WIDE = SIDE_OFF + SIDE_HALF  # the loop's half width where the lanes leave it
def widen(road_s, chainv, d_from, d_to):
    """half widths of the samples between chain d_from and d_to eased from 32 to WIDE (d_to the wide end)"""
    for i, p in enumerate(road_s):
        d = chainv[i]
        lo, hi = min(d_from, d_to), max(d_from, d_to)
        if lo - 1e-6 <= d <= hi + 1e-6:
            u = (d - d_from) / (d_to - d_from)
            w = round(32 + (WIDE - 32) * smooth(u), 2)
            p[6] = max(p[6], w)
            p[7] = max(p[7], w)

def pyay_off(d):
    return SIDE_OFF

EASE_H = 64.0  # studs over which a side lane goes from the loop end's height to the ground's

def eased(x, z, d, d0, d1):
    """the ground's height, eased onto the loop's own height at both ends (d0, d1): no step where a
    lane starts square on a loop end"""
    if d <= d0:
        return L.at(d0)[1]
    if d >= d1:
        return L.at(d1)[1]
    g = ground(x, z)
    if d - d0 < EASE_H:
        w = smooth((d - d0) / EASE_H)
        return L.at(d0)[1] * (1 - w) + g * w
    if d1 - d < EASE_H:
        w = smooth((d1 - d) / EASE_H)
        return L.at(d1)[1] * (1 - w) + g * w
    return g

def pyay_h(x, z, d):
    return eased(x, z, d, dA, dB)

decks.append({'name': 'Pyay Road Flyover', 'of': 'Yangon Loop', 'from': D0, 'to': D1, 's': loop[D0:D1 + 1]})
cut['Yangon Loop'] = list(range(D0 + 1, D1))
loop[:] = [list(p) for p in loop]
R['Yangon Loop']['s'] = loop
widen(loop, L.c, dA - FORK, dA)
widen(loop, L.c, dB + FORK, dB)
# loop heading south here: its right (+1) is west
pw = lane(L, dA, dB, pyay_off, lambda d: SIDE_HALF, pyay_h, 'Pyay W', +1)
pe = lane(L, dA, dB, pyay_off, lambda d: SIDE_HALF, pyay_h, 'Pyay E', -1)

# University Avenue carried on under the deck to the west side lane, along Hledan Road
ua, hl = R['University Avenue']['s'], R['Hledan Road']['s']
# the west lane's centre crosses Hledan Road at sample kh
def lateral_from_loop(p):
    k = nearest(loop, p[0], p[2])
    a = loop[k]
    rx, rz = -a[4], a[3]
    return (p[0] - a[0]) * rx + (p[2] - a[2]) * rz
kh = max(i for i in range(len(hl)) if lateral_from_loop(hl[i]) > SIDE_OFF)  # last Hledan sample west of the lane's centre
ua_new = [list(p) for p in hl[kh + 1:len(hl) - 1]] + [list(p) for p in ua]
for p in ua_new:
    p[6] = p[7] = 32
R['University Avenue']['s'] = ua_new
R['Hledan Road']['s'] = [list(p) for p in hl[:kh + 2]]  # (its last sample lies inside the west lane)
# the east lane is cut in two by University Avenue
pe1, pe2 = cross_split(pe, ua_new, 32)
# Nar Nat Taw Road starts on the west lane
nn = R['Nar Nat Taw Road']['s']
kn = min(i for i in range(len(nn)) if lateral_from_loop(nn[i]) > SIDE_OFF)
R['Nar Nat Taw Road']['s'] = [list(p) for p in nn[kn - 1:]]

new_roads += [
    {'name': 'Pyay Flyover West Lane', 'kind': 'side', 'closed': False, 'rank': 1.5, 'half': SIDE_HALF, 'walkL': SIDE_INNER_WALK, 'startsOnEnd': 'Yangon Loop', 'endsOnEnd': 'Yangon Loop', 's': pw},
    {'name': 'Pyay Flyover East Lane 1', 'kind': 'side', 'closed': False, 'rank': 2.5, 'half': SIDE_HALF, 'walkL': SIDE_INNER_WALK, 'startsOnEnd': 'Yangon Loop', 's': pe1},
    {'name': 'Pyay Flyover East Lane 2', 'kind': 'side', 'closed': False, 'rank': 2.6, 'half': SIDE_HALF, 'walkL': SIDE_INNER_WALK, 'endsOnEnd': 'Yangon Loop', 's': pe2},
]

# ---------------------------------------------------------------- Kabar Aye Flyover (New Road)
nr = R['New Road']['s']
foot = 680  # New Road's ramp foot: on the loop's line from here
kres = nearest(loop, nr[foot][0], nr[foot][2])  # the loop is built again from here
deck_s = [list(p) for p in nr[572:foot]] + [list(loop[kres])]
deck_s[-1][3], deck_s[-1][4] = loop[kres][3], loop[kres][4]
decks.append({'name': 'Kabar Aye Flyover', 'of': 'New Road', 'from': 572, 'to': foot, 'land': kres, 's': deck_s})
cut['New Road'] = list(range(573, len(nr)))
K0 = 789  # the loop's end south of the flyover: it splits into the two side lanes here
cut['Yangon Loop'] += list(range(K0 + 1, kres))
dK0, dK1 = L.c[K0], L.c[kres]
SPLIT = 160.0  # from a half of the loop (centre 16, half 16) out to a side lane (centre 48, half 12)
JOIN_AFTER, JOIN = 40.0, 140.0

def ka_off(d):
    if d < dK0 + SPLIT:
        return 16 + (SIDE_OFF - 16) * smooth((d - dK0) / SPLIT)
    return SIDE_OFF

def ka_half(d):
    return 16 - 4 * smooth((d - dK0) / SPLIT)

def ka_h(x, z, d):
    return eased(x, z, d, dK0, dK1)

# loop heading north here: its right (+1) is east
widen(loop, L.c, dK1 + JOIN, dK1)
ke = lane(L, dK0, dK1, ka_off, ka_half, ka_h, 'Kabar Aye E', +1)
kw = lane(L, dK0, dK1, ka_off, ka_half, ka_h, 'Kabar Aye W', -1)
new_roads += [
    {'name': 'Kabar Aye East Lane', 'kind': 'side', 'closed': False, 'rank': 0.6, 'half': SIDE_HALF, 'walkL': SIDE_INNER_WALK, 'startsOnEnd': 'Yangon Loop', 'endsOnEnd': 'Yangon Loop', 's': ke},
    {'name': 'Kabar Aye West Lane', 'kind': 'side', 'closed': False, 'rank': 0.7, 'half': SIDE_HALF, 'walkL': SIDE_INNER_WALK, 'startsOnEnd': 'Yangon Loop', 'endsOnEnd': 'Yangon Loop', 's': kw},
]
# New University Avenue Road ends on the east lane
nu = R['New University Avenue Road']['s']
def dist_to(s_list, p):
    return min(math.hypot(q[0] - p[0], q[2] - p[2]) for q in s_list)
# (it ends under New Road's deck, heading west, about 50 studs north of the east lane: a bend carries it
# on until it meets the east lane square on, at ground height. The bend is a cubic Hermite from its end
# to an east-lane sample, entering along that sample's normal; the sample whose bend is gentlest wins.)
def hermite(A, ta, B, tb, n):
    D = math.hypot(B[0] - A[0], B[1] - A[1])
    out = []
    for i in range(n + 1):
        u = i / n
        h00, h10, h01, h11 = 2*u**3 - 3*u**2 + 1, u**3 - 2*u**2 + u, -2*u**3 + 3*u**2, u**3 - u**2
        out.append((h00 * A[0] + h10 * D * ta[0] + h01 * B[0] + h11 * D * tb[0],
                    h00 * A[1] + h10 * D * ta[1] + h01 * B[1] + h11 * D * tb[1]))
    return out
def bend_cost(pts):  # 1 / the tightest radius
    worst = 0.0
    for i in range(1, len(pts) - 1):
        ax, az = pts[i][0] - pts[i-1][0], pts[i][1] - pts[i-1][1]
        bx, bz = pts[i+1][0] - pts[i][0], pts[i+1][1] - pts[i][1]
        la, lb = math.hypot(ax, az), math.hypot(bx, bz)
        ang = math.acos(max(-1, min(1, (ax*bx + az*bz) / (la * lb))))
        worst = max(worst, ang / ((la + lb) / 2))
    return worst
nu0 = [list(p) for p in nu]
best = None
for m in range(0, 30):  # (samples taken off its end first, so the bend can meet the lane past the fork)
    P0 = nu0[len(nu0) - 1 - m]
    L0 = math.hypot(P0[3], P0[4])
    t0 = (P0[3] / L0, P0[4] / L0)
    for k in range(14, len(ke) - 1):  # (from 14 on the two lanes stand apart: no T at the fork's nose)
        q = ke[k]
        tx, tz = ke[k+1][0] - ke[k-1][0], ke[k+1][2] - ke[k-1][2]
        Lt = math.hypot(tx, tz); tx, tz = tx / Lt, tz / Lt
        nx, nz = -tz, tx  # a normal; point it from P0's side into the lane
        if (P0[0] - q[0]) * nx + (P0[2] - q[2]) * nz > 0:
            nx, nz = -nx, -nz
        D = math.hypot(q[0] - P0[0], q[2] - P0[2])
        if D < 30 or D > 160:
            continue
        pts = hermite((P0[0], P0[2]), t0, (q[0], q[2]), (nx, nz), 40)
        c = bend_cost(pts) + 0.0004 * m
        if best is None or c < best[0]:
            best = (c, k, pts, m)
c, kq, pts, mcut = best
nu = nu0[:len(nu0) - mcut]
P0 = nu[-1]
print('New University Avenue Road: %d samples off its end, then a bend' % mcut)
print('New University Avenue Road bends onto east-lane sample %d: tightest radius %.0f studs' % (kq, 1 / bend_cost(pts)))
# resample the bend every STEP, stop at the first sample well inside the east lane
dense = []
for i in range(1, len(pts)):
    a2, b2 = pts[i-1], pts[i]
    for j in range(1, 21):
        u = j / 20
        dense.append((a2[0] + (b2[0] - a2[0]) * u, a2[1] + (b2[1] - a2[1]) * u))
prev = (P0[0], P0[2])
run = 0.0
for i, (x, z) in enumerate(dense):
    run += math.hypot(x - prev[0], z - prev[1]); prev = (x, z)
    if run >= STEP or i == len(dense) - 1:
        nx_, nz_ = dense[min(i + 1, len(dense) - 1)][0] - dense[max(i - 1, 0)][0], dense[min(i + 1, len(dense) - 1)][1] - dense[max(i - 1, 0)][1]
        Ln = math.hypot(nx_, nz_)
        nu.append([round(x, 2), round(ground(x, z), 2), round(z, 2), round(nx_ / Ln, 4), round(nz_ / Ln, 4), 0, P0[6], P0[7]])
        run = 0.0
        if dist_to(ke, nu[-1]) <= SIDE_HALF - 3:
            break
R['New University Avenue Road']['s'] = nu
ku = len(nu) - 1
print('New University Avenue Road carried on to the east lane: %d samples' % len(nu))

# ---------------------------------------------------------------- write
out_roads = list(roads['roads']) + new_roads
json.dump({'roads': out_roads, 'ox': OX, 'oz': OZ, 'spm': SPM, 'cut': cut, 'decks': decks,
           'note': 'ygn_roads.json + the flyovers (tools/yangon/d7_flyovers.py, 13 Nov 2026)'},
          open(os.path.join(MAP, 'ygn_roads_v2.json'), 'w', encoding='utf-8'), separators=(',', ':'))
print('kres %d (loop resumes), kh %d (Hledan kept to), kn %d (Nar Nat Taw from), ku %d (New University Avenue Road to)' % (kres, kh + 1, kn - 1, ku))
for r in new_roads:
    s = r['s']
    print('%-28s %3d samples, %.0f studs, rank %.1f, ends %s .. %s' % (r['name'], len(s), chain(s)[-1], r['rank'], s[0][:3], s[-1][:3]))
print('University Avenue now %d samples (was %d), starts %s' % (len(ua_new), len(ua), ua_new[0][:3]))
for d in decks:
    print('deck %s: %d samples, heights %.1f .. %.1f' % (d['name'], len(d['s']), min(p[1] for p in d['s']), max(p[1] for p in d['s'])))
print('cut: ' + ', '.join('%s %d' % (k, len(v)) for k, v in cut.items()))

if '--plot' in sys.argv:
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    outdir = sys.argv[sys.argv.index('--plot') + 1]
    for title, box in (('pyay', (28250, 28950, -2250, 100)), ('kabaraye', (32100, 32800, -1350, -150))):
        fig, ax = plt.subplots(figsize=(11, 14))
        x0, x1, z0, z1 = box
        cutset = {k: set(v) for k, v in cut.items()}
        for r in out_roads:
            s = r['s']
            if not any(x0 - 100 < p[0] < x1 + 100 and z0 - 100 < p[2] < z1 + 100 for p in s):
                continue
            col = {'route': 'k', 'side': 'r', 'street': 'gray'}[r['kind']]
            cs = cutset.get(r['name'], set())
            for side in (-1, 1):
                seg = []
                for i, p in enumerate(s):
                    if i in cs:
                        if len(seg) > 1:
                            ax.plot([q[0] for q in seg], [q[1] for q in seg], '-', color=col, lw=0.7)
                        seg = []
                        continue
                    Lh = math.hypot(p[3], p[4])
                    rx, rz = -p[4] / Lh, p[3] / Lh
                    h = p[6] if side < 0 else p[7]
                    seg.append((p[0] + rx * h * side, p[2] + rz * h * side))
                if len(seg) > 1:
                    ax.plot([q[0] for q in seg], [q[1] for q in seg], '-', color=col, lw=0.7)
        for dk in decks:
            s = dk['s']
            for side in (-1, 1):
                ex = []
                for p in s:
                    Lh = math.hypot(p[3], p[4])
                    rx, rz = -p[4] / Lh, p[3] / Lh
                    ex.append((p[0] + rx * 32 * side, p[2] + rz * 32 * side))
                ax.plot([q[0] for q in ex], [q[1] for q in ex], '-', color='b', lw=1.2)
            for i in range(0, len(s), 8):
                ax.text(s[i][0], s[i][2], '%.0f' % s[i][1], fontsize=5, color='b')
        for r in new_roads:
            s = r['s']
            for i in range(0, len(s), 10):
                ax.text(s[i][0], s[i][2], '%.0f' % s[i][1], fontsize=5, color='r')
        ax.set_xlim(x0, x1)
        ax.set_ylim(z1, z0)
        ax.set_aspect('equal')
        ax.grid(lw=0.2)
        ax.set_title(title + ': deck blue, side lanes red, main roads black, streets grey')
        fig.savefig(os.path.join(outdir, 'd7_' + title + '.png'), dpi=110)
    print('plots in', outdir)
