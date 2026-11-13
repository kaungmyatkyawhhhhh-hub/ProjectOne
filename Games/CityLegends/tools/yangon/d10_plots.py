"""Yangon map, build step 8 (13 Nov 2026): building plots along the roads.

Reads imports/refs/map/ygn_roads_v3.json (roads, cuts, decks), ygn_road_design.json (landmarks, the
ground grid's extent) and ygn_osm_areas.json / ygn_osm_roads.json (Inya Lake and the ponds) and writes
imports/refs/map/ygn_plots.json: one rectangle per building, facing its road.

Rules
  * A plot's front stands SETBACK studs behind the pavement's outer edge, its rectangle square to the road
    at its middle. Big roads get wider, deeper plots than streets.
  * Nothing of a plot comes nearer any road's centre line than that road's half + pavement + CLEAR (so no
    building stands in a junction's mouth, on a corner or across a side street), nearer a flyover deck's
    centre line than DECK_CLEAR, into the roundabout, into water, or outside the ground grid.
  * Plots don't overlap (GAP between them). VACANT of the frontage is left empty (trees and walls later).
  * The three landmarks (Optima, MM Plaza, Novotel) are placed first, at the design's spots, bigger.

Run from Games/CityLegends:  python tools/yangon/d10_plots.py [--plot out.png]
"""
import json, math, os, random, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
MAP = os.path.join(ROOT, 'imports', 'refs', 'map')
OX, OZ, SPM = 30000.0, 0.0, 1.6
WALK = 10.0
SETBACK = 4.5  # (1.5 more than CLEAR: a front exactly on the clearance line failed by rounding)
CLEAR = 3.0
DECK_CLEAR = 40.0
RING = (29072.0, 1172.8, 108.0 + 10.0 + 6.0)
GAP = 5.0
VACANT = 0.12
random.seed(20261113)

data = json.load(open(os.path.join(MAP, 'ygn_roads_v3.json'), encoding='utf-8'))
design = json.load(open(os.path.join(MAP, 'ygn_road_design.json'), encoding='utf-8'))
G = design['ground']
X0, X1 = OX + G['west_m'] * SPM + 40, OX + G['east_m'] * SPM - 40
Z0, Z1 = OZ - G['north_m'] * SPM + 40, OZ - G['south_m'] * SPM - 40
CUT = {k: set(v) for k, v in data['cut'].items()}
roads = data['roads']
R = {r['name']: r for r in roads}


def W(x, y):
    return (OX + x * SPM, OZ - y * SPM)


# ---------------------------------------------------------------- water polygons (as tools/yangon/mk_rbxmx.py)
LON0, LAT0 = 96.14, 16.82
KX = 111320 * math.cos(math.radians(LAT0))
KY = 110540


def xy(p):
    return ((p[0] - LON0) * KX, (p[1] - LAT0) * KY)


def stitch(parts):
    parts = [list(map(tuple, p)) for p in parts]
    out = []
    while parts:
        cur = parts.pop(0)
        while cur[0] != cur[-1]:
            for i, p in enumerate(parts):
                if p[0] == cur[-1]:
                    cur += p[1:]
                    parts.pop(i)
                    break
                if p[-1] == cur[-1]:
                    cur += p[::-1][1:]
                    parts.pop(i)
                    break
            else:
                break
        out.append(cur)
    return out


water = []  # outer rings in world studs (holes ignored: islands get no buildings anyway)
A = json.load(open(os.path.join(MAP, 'ygn_osm_areas.json'), encoding='utf-8'))
O = json.load(open(os.path.join(MAP, 'ygn_osm_roads.json'), encoding='utf-8'))
for r in A:
    if r['tags'].get('natural') != 'water':
        continue
    for ring in stitch([[xy(p) for p in m['pts']] for m in r['members'] if m['role'] == 'outer']):
        if ring[0] == ring[-1] and len(ring) >= 4:
            water.append([W(*p) for p in ring[:-1]])
for w in O['ways']:
    if w['tags'].get('natural') == 'water':
        p = [xy(q) for q in w['geometry']]
        if p[0] == p[-1] and len(p) >= 4:
            water.append([W(*q) for q in p[:-1]])
water_box = [(min(p[0] for p in poly), min(p[1] for p in poly), max(p[0] for p in poly), max(p[1] for p in poly)) for poly in water]


def in_poly(x, z, poly):
    inside = False
    n = len(poly)
    for i in range(n):
        a, b = poly[i], poly[(i + 1) % n]
        if (a[1] > z) != (b[1] > z):
            xc = a[0] + (z - a[1]) * (b[0] - a[0]) / (b[1] - a[1])
            if x < xc:
                inside = not inside
    return inside


def near_water(x, z, margin):
    for poly, bx in zip(water, water_box):
        if x < bx[0] - margin or x > bx[2] + margin or z < bx[1] - margin or z > bx[3] + margin:
            continue
        if in_poly(x, z, poly):
            return True
        n = len(poly)
        for i in range(n):
            a, b = poly[i], poly[(i + 1) % n]
            vx, vz = b[0] - a[0], b[1] - a[1]
            L = vx * vx + vz * vz
            t = 0 if L == 0 else max(0, min(1, ((x - a[0]) * vx + (z - a[1]) * vz) / L))
            if math.hypot(x - a[0] - t * vx, z - a[1] - t * vz) < margin:
                return True
    return False


# ---------------------------------------------------------------- road clearance grid
CELL = 48.0
grid = {}  # cell -> list of (ax, az, bx, bz, need)
for r in roads:
    s = r['s']
    cs = CUT.get(r['name'], set())
    walk = max(r.get('walkL') or WALK, r.get('walkR') or WALK)
    for k in range(len(s) - 1):
        if k in cs or k + 1 in cs:
            continue
        a, b = s[k], s[k + 1]
        h = max(a[6], a[7], b[6], b[7])
        need = h + walk + CLEAR
        x0, x1 = min(a[0], b[0]) - need, max(a[0], b[0]) + need
        z0, z1 = min(a[2], b[2]) - need, max(a[2], b[2]) + need
        for cx in range(int(math.floor(x0 / CELL)), int(math.floor(x1 / CELL)) + 1):
            for cz in range(int(math.floor(z0 / CELL)), int(math.floor(z1 / CELL)) + 1):
                grid.setdefault((cx, cz), []).append((a[0], a[2], b[0], b[2], need))
for d in data['decks']:
    s = d['s']
    for k in range(len(s) - 1):
        a, b = s[k], s[k + 1]
        need = DECK_CLEAR
        x0, x1 = min(a[0], b[0]) - need, max(a[0], b[0]) + need
        z0, z1 = min(a[2], b[2]) - need, max(a[2], b[2]) + need
        for cx in range(int(math.floor(x0 / CELL)), int(math.floor(x1 / CELL)) + 1):
            for cz in range(int(math.floor(z0 / CELL)), int(math.floor(z1 / CELL)) + 1):
                grid.setdefault((cx, cz), []).append((a[0], a[2], b[0], b[2], need))


def road_clear(x, z):
    for (ax, az, bx, bz, need) in grid.get((int(math.floor(x / CELL)), int(math.floor(z / CELL))), ()):
        vx, vz = bx - ax, bz - az
        L = vx * vx + vz * vz
        t = 0 if L == 0 else max(0, min(1, ((x - ax) * vx + (z - az) * vz) / L))
        if math.hypot(x - ax - t * vx, z - az - t * vz) < need:
            return False
    return True


# ---------------------------------------------------------------- plots
plots = []
pgrid = {}


def corners(cx, cz, fx, fz, w, d):
    """rectangle w (along the road) x d (away from it); (fx, fz) the unit direction from the front to the back"""
    ax, az = -fz, fx  # along the road
    hw, hd = w / 2, d / 2
    return [(cx + ax * sa * hw + fx * sd * hd, cz + az * sa * hw + fz * sd * hd) for sa, sd in ((-1, -1), (1, -1), (1, 1), (-1, 1))]


def sample_pts(cx, cz, fx, fz, w, d):
    ax, az = -fz, fx
    pts = []
    for u in (-0.5, -0.25, 0, 0.25, 0.5):
        for v in (-0.5, 0, 0.5):
            pts.append((cx + ax * u * w + fx * v * d, cz + az * u * w + fz * v * d))
    return pts


def sat_overlap(p, q):
    for poly in (p, q):
        for i in range(4):
            a, b = poly[i], poly[(i + 1) % 4]
            nx, nz = -(b[1] - a[1]), b[0] - a[0]
            pa = [nx * c[0] + nz * c[1] for c in p]
            qa = [nx * c[0] + nz * c[1] for c in q]
            if max(pa) < min(qa) or max(qa) < min(pa):
                return False
    return True


def fits(cx, cz, fx, fz, w, d, ignore_road_clear=False):
    if not (X0 < cx < X1 and Z0 < cz < Z1):
        return False
    for (x, z) in sample_pts(cx, cz, fx, fz, w, d):
        if not (X0 < x < X1 and Z0 < z < Z1):
            return False
        if math.hypot(x - RING[0], z - RING[1]) < RING[2]:
            return False
        if not ignore_road_clear and not road_clear(x, z):
            return False
        if near_water(x, z, 6.0):
            return False
    poly = corners(cx, cz, fx, fz, w + GAP * 2, d + GAP * 2)
    key = (int(cx // 200), int(cz // 200))
    for dx in (-1, 0, 1):
        for dz in (-1, 0, 1):
            for other in pgrid.get((key[0] + dx, key[1] + dz), ()):
                if sat_overlap(poly, other['poly']):
                    return False
    return True


def add(cx, cz, fx, fz, w, d, road, kind, side, tag=None):
    poly = corners(cx, cz, fx, fz, w, d)
    p = {'x': round(cx, 2), 'z': round(cz, 2), 'fx': round(fx, 4), 'fz': round(fz, 4), 'w': w, 'd': d,
         'road': road, 'kind': kind, 'side': side, 'poly': poly}
    if tag:
        p['landmark'] = tag
    plots.append(p)
    pgrid.setdefault((int(cx // 200), int(cz // 200)), []).append(p)


def chain(s):
    c = [0.0]
    for k in range(1, len(s)):
        c.append(c[-1] + math.hypot(s[k][0] - s[k - 1][0], s[k][2] - s[k - 1][2]))
    return c


def at(s, c, dist):
    lo, hi = 0, len(c) - 1
    dist = max(0, min(c[-1], dist))
    while hi - lo > 1:
        m = (lo + hi) // 2
        if c[m] <= dist:
            lo = m
        else:
            hi = m
    t = 0 if c[hi] == c[lo] else (dist - c[lo]) / (c[hi] - c[lo])
    a, b = s[lo], s[hi]
    x, z = a[0] + (b[0] - a[0]) * t, a[2] + (b[2] - a[2]) * t
    dx, dz = b[0] - a[0], b[2] - a[2]
    L = math.hypot(dx, dz) or 1
    h = max(a[6], a[7], b[6], b[7])
    return x, z, dx / L, dz / L, h, lo


# the landmarks first: their frontage is fixed, their plot is forced a little further back if needed
LANDMARKS = {'Optima (START)': ('optima', 110, 90), 'MM Plaza': ('mmplaza', 180, 130), 'Novotel': ('novotel', 100, 90)}
lm_out = []
loop = R['Yangon Loop']['s']
cl = chain(loop)
for lm in design['landmarks']:
    tag, w, d = LANDMARKS[lm['name']]
    dist = lm['at_m'] * SPM
    x, z, tx, tz, h, k = at(loop, cl, dist)
    side = 1 if lm['side'] == 'right' else -1
    rx, rz = -tz * side, tx * side  # away from the road on that side
    placed = False
    for extra in range(0, 80, 4):
        for slide in (0, 16, -16, 32, -32, 48, -48, 64, -64):
            xx, zz, tx2, tz2, h2, _ = at(loop, cl, dist + slide)
            rx, rz = -tz2 * side, tx2 * side
            off = h2 + WALK + SETBACK + extra + d / 2
            cx, cz = xx + rx * off, zz + rz * off
            if fits(cx, cz, rx, rz, w, d):
                add(cx, cz, rx, rz, w, d, 'Yangon Loop', 'route', side, tag)
                lm_out.append('%s at loop %.0f m (+%d along, %d further back)' % (tag, lm['at_m'], slide, extra))
                placed = True
                break
        if placed:
            break
    if not placed:
        lm_out.append('%s: NO ROOM' % tag)

# then every road, both sides: big roads first
SIZES = {'route': ([44, 52, 60, 72], (48, 80)), 'side': ([44, 52, 60], (44, 70)), 'street': ([28, 36, 44, 52], (36, 60))}
order = sorted(roads, key=lambda r: r['rank'])
stats = {}
for r in order:
    s = r['s']
    kind = r.get('kind', 'street')
    widths, (dmin, dmax) = SIZES.get(kind, SIZES['street'])
    c = chain(s)
    cs = CUT.get(r['name'], set())
    for side in (1, -1):
        if kind == 'side' and side == -1:
            continue  # (a side lane's left is the flyover deck)
        walk = (r.get('walkR') if side == 1 else r.get('walkL')) or WALK
        dist = 8.0
        while dist < c[-1] - 8:
            w = random.choice(widths)
            d = random.randint(dmin // 4, dmax // 4) * 4
            mid = dist + w / 2
            if mid > c[-1]:
                break
            x, z, tx, tz, h, k = at(s, c, mid)
            if k in cs:
                dist += 24
                continue
            if random.random() < VACANT:
                dist += w + GAP
                continue
            rx, rz = -tz * side, tx * side
            off = h + walk + SETBACK + d / 2
            cx, cz = x + rx * off, z + rz * off
            if fits(cx, cz, rx, rz, w, d):
                add(cx, cz, rx, rz, w, d, r['name'], kind, side)
                stats[kind] = stats.get(kind, 0) + 1
                dist += w + GAP + random.choice((0, 0, 4, 8))
            else:
                dist += 8

out = [{k: v for k, v in p.items() if k != 'poly'} for p in plots]
json.dump({'plots': out, 'note': 'tools/yangon/d10_plots.py, 13 Nov 2026'}, open(os.path.join(MAP, 'ygn_plots.json'), 'w', encoding='utf-8'), separators=(',', ':'))
print('\n'.join(lm_out))
print('%d plots: %s; %d water polygons' % (len(plots), ', '.join('%s %d' % kv for kv in stats.items()), len(water)))
area = sum(p['w'] * p['d'] for p in plots)
print('footprint area %.0f studs^2, mean frontage %.0f' % (area, sum(p['w'] for p in plots) / len(plots)))

if '--plot' in sys.argv:
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    from matplotlib.patches import Polygon
    out_png = sys.argv[sys.argv.index('--plot') + 1]
    for name, box in (('all', None), ('zoom', (28300, 29300, -1800, -800)), ('ka', (31900, 32900, -1100, -100))):
        fig, ax = plt.subplots(figsize=(14, 14))
        for poly in water:
            ax.add_patch(Polygon(poly, closed=True, fc='#9cf', ec='none'))
        for r in roads:
            s = r['s']
            ax.plot([p[0] for p in s], [p[2] for p in s], color='#555' if r.get('kind') != 'street' else '#999', lw=1.6 if r.get('kind') != 'street' else 0.8)
        for p in plots:
            col = '#c33' if p.get('landmark') else ('#e9a' if p['kind'] == 'route' else '#fc6' if p['kind'] == 'side' else '#ad8')
            ax.add_patch(Polygon(p['poly'], closed=True, fc=col, ec='#333', lw=0.3))
        if box:
            ax.set_xlim(box[0], box[1])
            ax.set_ylim(box[2], box[3])
        else:
            ax.set_xlim(X0, X1)
            ax.set_ylim(Z0, Z1)
        ax.set_aspect('equal')
        ax.invert_yaxis()
        fig.savefig(out_png.replace('.png', '_%s.png' % name), dpi=80)
        plt.close(fig)
    print('plots written')
