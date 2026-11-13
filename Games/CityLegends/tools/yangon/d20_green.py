"""Yangon batch 0.5 accuracy pass (14 Nov 2026, owner: "the inya lake have borders and stuff in real life and theres like
a park", "do everything"): the lake's embankments (Inya Kan Baung), the parks and the city's trees.

Reference study: City Legends/2026-11-14 Yangon batch 0.5 - reference study and accuracy plan.md (Google Earth: the
Pyay Road and Kabar Aye embankments: a sloped concrete edge, a walkway, a row of big trees, a green strip, the road;
Yangon is very green: big trees in every compound and along the roads). Data: OpenStreetMap (osm_b05, ODbL).

Writes build/yangon_green/YangonGreenData.luau (one string, for tools/yangon/YangonGreen.luau):
  S x1 z1 x2 z2 nx nz        a shore segment of an embankment (n = inland, away from the water)
  P x z                      a park tree spot (denser)
  T x z s k                  a city tree (s = size 0.8..1.5, k = kind: R rain tree, P palm, M mango)
  B x z fx fz                a bench on the walkway, facing (fx, fz) = the water
  L x z                      a walkway lamp
Embankments: where the lake's shore runs within 130 studs of a main road (the loop's Pyay Road and Kabar Aye sides).
Trees: never on a road (+ its pavement + 3), a building (+ 4), water (+ 6), a venue / house / hub lot, a deck corridor or
the roundabout; at least SPACING apart (parks: PARK_SPACING).

Run from Games/CityLegends:  python tools/yangon/d20_green.py
"""
import glob, json, math, os, random, re, xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
MAP = os.path.join(ROOT, 'imports', 'refs', 'map')
OUT = os.path.join(ROOT, 'build', 'yangon_green')
LON0, LAT0, SPM = 96.14, 16.82, 1.6
KX = 111320 * math.cos(math.radians(LAT0))
KY = 110540
SPACING, PARK_SPACING = 46.0, 24.0
rng = random.Random(20261114)


def world(lon, lat):
    return (30000 + (lon - LON0) * KX * SPM, -(lat - LAT0) * KY * SPM)


src = open(os.path.join(HERE, 'd19_buildings.py'), encoding='utf-8').read()
ns = {'__file__': os.path.join(HERE, 'd19_buildings.py')}
exec(compile(src[:src.index('# ---------------------------------------------------------------- the OSM buildings')], 'd19', 'exec'), ns)
roads, near_water, in_poly, grid, seg, BLOCKED, overlap, rect, CELL = (ns[k] for k in ('roads', 'near_water', 'in_poly', 'grid', 'seg', 'BLOCKED', 'overlap', 'rect', 'CELL'))
water = ns['ns']['water']
X0, X1, Z0, Z1, RING = ns['X0'], ns['X1'], ns['Z0'], ns['Z1'], ns['RING']

# the buildings as built: the mesh city's plots (tools/yangon/city/plots.py, real density; 14 Nov 2026), else d19's
bgrid = {}
_city = os.path.join(ROOT, 'build', 'city', 'plots_05.json')
if os.path.exists(_city):
    from shapely.geometry import Polygon as _Poly
    for p in json.load(open(_city, encoding='utf-8'))['plots']:
        try:
            g = _Poly(p['poly']).buffer(4, join_style=2)
        except Exception:
            continue
        if g.geom_type != 'Polygon':
            continue
        r = list(g.exterior.coords)[:-1]
        for cx in range(int(min(q[0] for q in r) // 100), int(max(q[0] for q in r) // 100) + 1):
            for cz in range(int(min(q[1] for q in r) // 100), int(max(q[1] for q in r) // 100) + 1):
                bgrid.setdefault((cx, cz), []).append(r)
    # the new mesh streets keep their trees off too (carriageway + pavement + 1)
    for st in json.load(open(os.path.join(ROOT, 'build', 'city', 'streets_05.json'), encoding='utf-8'))['streets']:
        pts = st['pts']
        need = st['half'] + st['walk'] + 1
        for a, b in zip(pts, pts[1:]):
            for cx in range(int((min(a[0], b[0]) - need) // CELL) - 1, int((max(a[0], b[0]) + need) // CELL) + 2):
                for cz in range(int((min(a[1], b[1]) - need) // CELL) - 1, int((max(a[1], b[1]) + need) // CELL) + 2):
                    grid.setdefault((cx, cz), []).append((a[0], a[1], b[0], b[1], need, st['name'], 'street'))
else:
    plots = json.load(open(os.path.join(MAP, 'ygn_plots_real.json'), encoding='utf-8'))['plots']
    for p in plots:
        r = rect(p['x'], p['z'], p['fx'], p['fz'], p['w'], p['d'], grow=4)
        for cx in range(int(min(q[0] for q in r) // 100), int(max(q[0] for q in r) // 100) + 1):
            for cz in range(int(min(q[1] for q in r) // 100), int(max(q[1] for q in r) // 100) + 1):
                bgrid.setdefault((cx, cz), []).append(r)


def in_building(x, z):
    for r in bgrid.get((int(x // 100), int(z // 100)), ()):
        if in_poly(x, z, r):
            return True
    return False


def road_dist(x, z):
    """how far past the nearest road's pavement (negative: on it); decks count with their 40 corridor"""
    best = 1e9
    for e in grid.get((int(x // CELL), int(z // CELL)), ()):
        dd = seg(x, z, *e[:4])[0]
        best = min(best, dd - e[4])
    return best


def blocked_lot(x, z):
    return any(in_poly(x, z, b) for b in BLOCKED)


# ---------------------------------------------------------------- the embankments: lake shore near a main road
lake = max(water, key=lambda w: abs(sum(w[i][0] * w[(i + 1) % len(w)][1] - w[(i + 1) % len(w)][0] * w[i][1] for i in range(len(w)))))
main = [r for r in roads['roads'] if r.get('kind') == 'route']


def main_dist(x, z):
    best = 1e9
    for r in main:
        s = r['s']
        for k in range(0, len(s) - 1, 2):
            a, b = s[k], s[min(k + 2, len(s) - 1)]
            best = min(best, seg(x, z, a[0], a[2], b[0], b[2])[0])
    return best


segs = []
n = len(lake)
for i in range(n):
    a, b = lake[i], lake[(i + 1) % n]
    L = math.hypot(b[0] - a[0], b[1] - a[1])
    if L < 2:
        continue
    mx, mz = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
    if main_dist(mx, mz) > 130:
        continue
    # inland: the side of the edge that is not water
    nx, nz = -(b[1] - a[1]) / L, (b[0] - a[0]) / L
    if in_poly(mx + nx * 6, mz + nz * 6, lake):
        nx, nz = -nx, -nz
    # the walkway (inland 2..10) must not be on a road
    if road_dist(mx + nx * 6, mz + nz * 6) < 0:
        continue
    # split long edges so the pieces follow the shore
    k = max(1, int(L // 24))
    for j in range(k):
        t0, t1 = j / k, (j + 1) / k
        segs.append((a[0] + (b[0] - a[0]) * t0, a[1] + (b[1] - a[1]) * t0, a[0] + (b[0] - a[0]) * t1, a[1] + (b[1] - a[1]) * t1, nx, nz))

# benches, lamps and the tree row along the embankments
bench, lamps, row_trees = [], [], []
walked = 0.0
for (x1, z1, x2, z2, nx, nz) in segs:
    L = math.hypot(x2 - x1, z2 - z1)
    t = 0.0
    while t < L:
        if walked % 44 < 1e-6 or (walked % 44) + (L - t) < 0 and False:
            pass
        x, z = x1 + (x2 - x1) * t / L, z1 + (z2 - z1) * t / L
        phase = walked % 44
        if phase < 1:
            bench.append((x + nx * 4, z + nz * 4, -nx, -nz))
        if abs(phase - 22) < 1:
            lamps.append((x + nx * 11, z + nz * 11))
        if phase < 1 or abs(phase - 22) < 1:
            tx, tz = x + nx * 17, z + nz * 17
            if road_dist(tx, tz) > 3 and not in_building(tx, tz):
                row_trees.append((tx, tz))
        step = 1.0
        t += step
        walked += step

# ---------------------------------------------------------------- parks and city trees
parks = []
nodes, ways = {}, {}
for f in sorted(glob.glob(os.path.join(MAP, 'osm_b05', 'tile_*.osm'))):
    r = ET.parse(f).getroot()
    for nd in r.iter('node'):
        nodes[nd.get('id')] = (float(nd.get('lon')), float(nd.get('lat')))
    for w in r.iter('way'):
        ways[w.get('id')] = {'nd': [x.get('ref') for x in w.iter('nd')], 'tags': {t.get('k'): t.get('v') for t in w.iter('tag')}}
for w in ways.values():
    t = w['tags']
    if t.get('leisure') in ('park', 'garden') or t.get('landuse') in ('grass', 'forest', 'recreation_ground') or t.get('natural') in ('wood', 'scrub'):
        pts = [world(*nodes[q]) for q in w['nd'] if q in nodes]
        if len(pts) >= 3:
            parks.append(pts)


def in_park(x, z):
    return any(in_poly(x, z, p) for p in parks)


placed = []
pgrid = {}


def free_spot(x, z, spacing):
    key = (int(x // 50), int(z // 50))
    for dx in (-1, 0, 1):
        for dz in (-1, 0, 1):
            for (qx, qz) in pgrid.get((key[0] + dx, key[1] + dz), ()):
                if math.hypot(qx - x, qz - z) < spacing:
                    return False
    return True


def put(x, z):
    placed.append((x, z))
    pgrid.setdefault((int(x // 50), int(z // 50)), []).append((x, z))


for (x, z) in row_trees:
    put(x, z)


def ok_ground(x, z):
    if not (X0 < x < X1 and Z0 < z < Z1):
        return False
    if math.hypot(x - RING[0], z - RING[1]) < RING[2]:
        return False
    if road_dist(x, z) < 3 or in_building(x, z) or near_water(x, z, 6) or in_poly(x, z, lake) or blocked_lot(x, z):
        return False
    return True


park_trees, city_trees = [], []
# parks first (denser), then the city
for poly in parks:
    xs = [p[0] for p in poly]
    zs = [p[1] for p in poly]
    area = abs(sum(poly[i][0] * poly[(i + 1) % len(poly)][1] - poly[(i + 1) % len(poly)][0] * poly[i][1] for i in range(len(poly)))) / 2
    for _ in range(int(area / (PARK_SPACING * PARK_SPACING) * 1.6) + 4):
        x, z = rng.uniform(min(xs), max(xs)), rng.uniform(min(zs), max(zs))
        if in_poly(x, z, poly) and ok_ground(x, z) and free_spot(x, z, PARK_SPACING):
            put(x, z)
            park_trees.append((x, z))
tries = int((X1 - X0) * (Z1 - Z0) / (SPACING * SPACING) * 2.2)
for _ in range(tries):
    x, z = rng.uniform(X0, X1), rng.uniform(Z0, Z1)
    if ok_ground(x, z) and free_spot(x, z, SPACING):
        put(x, z)
        city_trees.append((x, z))

os.makedirs(OUT, exist_ok=True)
lines = []
for s_ in segs:
    lines.append('S %.1f %.1f %.1f %.1f %.3f %.3f' % s_)
for (x, z) in row_trees + park_trees:
    lines.append('P %.1f %.1f' % (x, z))
for (x, z) in city_trees:
    k = rng.random()
    kind = 'R' if k < 0.55 else ('M' if k < 0.85 else 'P')
    lines.append('T %.1f %.1f %.2f %s' % (x, z, rng.uniform(0.8, 1.5), kind))
for b in bench:
    lines.append('B %.1f %.1f %.3f %.3f' % b)
for (x, z) in lamps:
    lines.append('L %.1f %.1f' % (x, z))
txt = '\n'.join(lines)
NL = chr(10)
mod = '-- generated by tools/yangon/d20_green.py: the lake embankments, parks and trees (see its header)' + NL + 'return [==[' + NL + txt + NL + ']==]' + NL
open(os.path.join(OUT, 'YangonGreenData.luau'), 'w', encoding='utf-8', newline=NL).write(mod)
print('shore segments', len(segs), 'benches', len(bench), 'lamps', len(lamps), 'row trees', len(row_trees), 'park trees', len(park_trees), 'city trees', len(city_trees), 'chars', len(mod))
