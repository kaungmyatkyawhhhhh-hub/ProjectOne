"""Yangon batch 0.5 accuracy pass (14 Nov 2026, owner: "the buildings rn are not accurate ... some are tall circle
buildings in real life and in game its a square short building", "do everything"): plots from the REAL building
outlines (OpenStreetMap, imports/refs/map/osm_b05/tile_*.osm, (c) OpenStreetMap contributors, ODbL).

Writes imports/refs/map/ygn_plots_real.json and build/yangon_real/Plots2.luau (YangonData.Plots2, read by
tools/yangon/YangonBuildings.luau B.build when present). Each plot is the outline's smallest enclosing rectangle
(x, z middle, fx, fz = towards its nearest road, w along the road, d away from it) with:
  * floors: OSM building:levels, else an estimate from its type and size (Yangon: mostly 4-8 floor flats);
  * style: "round" (a near-circular outline: a round tower), "tower" (10+ floors), "villa" (a house), "walkup" /
    "shophouse" (facing a road: the detailed Yangon kit), "mass" (inside a block: a light block with window bands);
  * name: OSM's English name when it has one (shown on towers).
Rules: a building whose outline reaches into a road's carriageway or pavement (the game's roads are wider than the
real ones) is moved back from that road (up to 20 studs), else dropped; nothing in the lake, under a flyover deck,
in the roundabout, on a venue / hub / service / fuel / house lot, or on the three landmarks (kept from step 8).

Run from Games/CityLegends:  python tools/yangon/d19_buildings.py
"""
import glob, json, math, os, re, xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
MAP = os.path.join(ROOT, 'imports', 'refs', 'map')
OUT = os.path.join(ROOT, 'build', 'yangon_real')
LON0, LAT0, SPM = 96.14, 16.82, 1.6
KX = 111320 * math.cos(math.radians(LAT0))
KY = 110540
WALK, GAP = 10.0, 1.0


def world(lon, lat):
    return (30000 + (lon - LON0) * KX * SPM, -(lat - LAT0) * KY * SPM)


# ---------------------------------------------------------------- the map's own data
roads = json.load(open(os.path.join(MAP, 'ygn_roads_v5.json'), encoding='utf-8'))
CUT = {k: set(v) for k, v in roads['cut'].items()}
design = json.load(open(os.path.join(MAP, 'ygn_road_design.json'), encoding='utf-8'))
G = design['ground']
X0, X1 = 30000 + G['west_m'] * SPM + 40, 30000 + G['east_m'] * SPM - 40
Z0, Z1 = -G['north_m'] * SPM + 40, -G['south_m'] * SPM - 40
RING = (29072.0, 1172.8, 108.0 + 10.0 + 6.0)
old = json.load(open(os.path.join(MAP, 'ygn_plots.json'), encoding='utf-8'))['plots']
landmarks = [p for p in old if p.get('landmark')]

# water (the lake and ponds), as d10
src = open(os.path.join(HERE, 'd10_plots.py'), encoding='utf-8').read()
ns = {'__file__': os.path.join(HERE, 'd10_plots.py')}
exec(compile(src[:src.index('# ---------------------------------------------------------------- road clearance grid')], 'd10', 'exec'), ns)
near_water, in_poly = ns['near_water'], ns['in_poly']

# lots that must stay clear (as d16_lamps: venues, fuel, service, hub, house lots)
SITES = [
    (30836.8, 957.4, -0.560, -0.829, 216, 216), (31025.7, 646.7, -0.990, -0.144, 216, 216), (31125.7, 960.7, 0.326, 0.945, 216, 216),
    (31074.1, 394.2, -0.991, -0.136, 216, 216), (32358.8, -1833.6, 0.992, 0.127, 216, 216), (30742.3, 223.9, 0.969, -0.249, 216, 216),
    (30730.5, 552.9, 0.987, 0.159, 304, 216), (29745.3, 1089.0, 0, 1, 216, 216), (30655.1, 1303.2, 0, -1, 216, 216),
    (30911.0, 1306.4, 0, -1, 216, 216), (29867.2, 1398.6, 0, -1, 216, 216), (30465.2, 921.7, 0.560, 0.829, 80, 80),
    (31424.3, 1181.3, -0.327, -0.945, 216, 216),
]
wsrc = open(os.path.join(ROOT, 'src', 'shared', 'YangonWorld.lua'), encoding='utf-8').read()
for m in re.finditer(r'x = ([-\d.]+), y = [-\d.]+, z = ([-\d.]+), fx = ([-\d.]+), fz = ([-\d.]+), w = (\d+), d = (\d+)', wsrc):
    SITES.append(tuple(float(v) for v in m.groups()))
m = re.search(r'site = \{ x = ([-\d.]+), z = ([-\d.]+), fx = ([-\d.]+), fz = ([-\d.]+)', wsrc)
SITES.append((float(m.group(1)), float(m.group(2)), float(m.group(3)), float(m.group(4)), 216, 216))


def rect(x, z, fx, fz, w, d, grow=0.0):
    ax, az = -fz, fx
    hw, hd = w / 2 + grow, d / 2 + grow
    return [(x + ax * u * hw + fx * v * hd, z + az * u * hw + fz * v * hd) for u, v in ((-1, -1), (1, -1), (1, 1), (-1, 1))]


def overlap(p, q):
    for poly in (p, q):
        for i in range(len(poly)):
            a, b = poly[i], poly[(i + 1) % len(poly)]
            nx, nz = -(b[1] - a[1]), b[0] - a[0]
            pa = [nx * x + nz * z for x, z in p]
            pb = [nx * x + nz * z for x, z in q]
            if max(pa) < min(pb) or max(pb) < min(pa):
                return False
    return True


BLOCKED = [rect(*s, grow=10) for s in SITES] + [rect(p['x'], p['z'], p['fx'], p['fz'], p['w'], p['d'], grow=8) for p in landmarks]

# road segments (carriageway half + pavement) in a grid, and the decks
CELL = 64.0
grid = {}
for r in roads['roads']:
    s = r['s']
    cs = CUT.get(r['name'], set())
    walk = max(r.get('walkL') or WALK, r.get('walkR') or WALK)
    for k in range(len(s) - 1):
        if k in cs or (k + 1) in cs:
            continue
        a, b = s[k], s[k + 1]
        need = max(a[6], a[7], b[6], b[7]) + walk + GAP
        for cx in range(int((min(a[0], b[0]) - need) // CELL) - 1, int((max(a[0], b[0]) + need) // CELL) + 2):
            for cz in range(int((min(a[2], b[2]) - need) // CELL) - 1, int((max(a[2], b[2]) + need) // CELL) + 2):
                grid.setdefault((cx, cz), []).append((a[0], a[2], b[0], b[2], need, r['name'], r.get('kind')))
for d in roads['decks']:
    s = d['s']
    for k in range(len(s) - 1):
        a, b = s[k], s[k + 1]
        need = 40.0
        for cx in range(int((min(a[0], b[0]) - need) // CELL) - 1, int((max(a[0], b[0]) + need) // CELL) + 2):
            for cz in range(int((min(a[2], b[2]) - need) // CELL) - 1, int((max(a[2], b[2]) + need) // CELL) + 2):
                grid.setdefault((cx, cz), []).append((a[0], a[2], b[0], b[2], need, 'deck', 'deck'))


def seg(px, pz, ax, az, bx, bz):
    vx, vz = bx - ax, bz - az
    L = vx * vx + vz * vz
    t = 0 if L == 0 else max(0, min(1, ((px - ax) * vx + (pz - az) * vz) / L))
    qx, qz = ax + t * vx, az + t * vz
    return math.hypot(px - qx, pz - qz), qx, qz


def worst_intrusion(pts):
    """the deepest a point goes into any road's zone: (depth, push direction x, z, road name, kind)"""
    best = (0.0, 0, 0, None, None)
    for (x, z) in pts:
        for e in grid.get((int(x // CELL), int(z // CELL)), ()):
            dd, qx, qz = seg(x, z, *e[:4])
            depth = e[4] - dd
            if depth > best[0]:
                L = math.hypot(x - qx, z - qz) or 1
                best = (depth, (x - qx) / L, (z - qz) / L, e[5], e[6])
    return best


def nearest_road(x, z, reach=160):
    best = (1e9, None, 0, 0, None)
    for cx in range(int((x - reach) // CELL), int((x + reach) // CELL) + 1):
        for cz in range(int((z - reach) // CELL), int((z + reach) // CELL) + 1):
            for e in grid.get((cx, cz), ()):
                if e[6] == 'deck':
                    continue
                dd, qx, qz = seg(x, z, *e[:4])
                edge = dd - e[4]  # distance past the pavement's outer edge
                if edge < best[0]:
                    best = (edge, e[5], qx, qz, e[6])
    return best


# ---------------------------------------------------------------- the OSM buildings
nodes, ways, rels = {}, {}, []
for f in sorted(glob.glob(os.path.join(MAP, 'osm_b05', 'tile_*.osm'))):
    r = ET.parse(f).getroot()
    for n in r.iter('node'):
        nodes[n.get('id')] = (float(n.get('lon')), float(n.get('lat')))
    for w in r.iter('way'):
        ways[w.get('id')] = {'nd': [x.get('ref') for x in w.iter('nd')], 'tags': {t.get('k'): t.get('v') for t in w.iter('tag')}}
    for rl in r.iter('relation'):
        tags = {t.get('k'): t.get('v') for t in rl.iter('tag')}
        if 'building' in tags:
            rels.append((rl.get('id'), tags, [m.get('ref') for m in rl.iter('member') if m.get('type') == 'way' and m.get('role') == 'outer']))

outlines = []  # (id, tags, [world points])
used_ways = set()
for rid, tags, outer in rels:
    for wid in outer:
        w = ways.get(wid)
        if w:
            used_ways.add(wid)
            outlines.append(('r' + rid + '_' + wid, {**w['tags'], **tags}, w['nd']))
for wid, w in ways.items():
    if 'building' in w['tags'] and wid not in used_ways and w['tags'].get('building') not in ('roof', 'no', 'construction'):
        outlines.append(('w' + wid, w['tags'], w['nd']))


def hull_rect(pts):
    """the smallest-area enclosing rectangle (rotating calipers over the convex hull): (cx, cz, ux, uz, a, b)
    with u the direction of side a, the other side b"""
    P = sorted(set(pts))
    if len(P) < 3:
        return None

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lower, upper = [], []
    for p in P:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(P):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    H = lower[:-1] + upper[:-1]
    best = None
    for i in range(len(H)):
        a, b = H[i], H[(i + 1) % len(H)]
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        if L < 1e-6:
            continue
        ux, uz = (b[0] - a[0]) / L, (b[1] - a[1]) / L
        us = [p[0] * ux + p[1] * uz for p in H]
        vs = [-p[0] * uz + p[1] * ux for p in H]
        area = (max(us) - min(us)) * (max(vs) - min(vs))
        if best is None or area < best[0]:
            cu, cv = (max(us) + min(us)) / 2, (max(vs) + min(vs)) / 2
            best = (area, cu * ux - cv * uz, cu * uz + cv * ux, ux, uz, max(us) - min(us), max(vs) - min(vs))
    return best[1:]


def poly_area_perim(pts):
    A = P = 0.0
    for i in range(len(pts)):
        (x1, z1), (x2, z2) = pts[i], pts[(i + 1) % len(pts)]
        A += x1 * z2 - x2 * z1
        P += math.hypot(x2 - x1, z2 - z1)
    return abs(A) / 2, P


def hsh(s, k=0):
    h = 2166136261
    for ch in (s + str(k)).encode():
        h = ((h ^ ch) * 16777619) & 0xffffffff
    return h / 0xffffffff


def floors_of(oid, tags, area_m2):
    lv = tags.get('building:levels')
    try:
        if lv:
            return max(1, int(round(float(re.split(r'[;,]', lv)[0]))))
    except ValueError:
        pass
    h = tags.get('height')
    try:
        if h:
            return max(1, int(round(float(h.split()[0]) / 3.2)))
    except ValueError:
        pass
    t = tags.get('building')
    r = hsh(oid)
    if t in ('house', 'detached', 'bungalow', 'hut', 'shed', 'garage', 'garages'):
        return 1 if t in ('hut', 'shed', 'garage', 'garages') else (2 if r < 0.7 else 3)
    if t in ('apartments', 'residential', 'dormitory'):
        return 5 + int(r * 4)
    if t in ('university', 'school', 'college', 'hospital', 'public', 'civic', 'government'):
        return 2 + int(r * 3)
    if t in ('retail', 'commercial', 'office', 'hotel'):
        return 4 + int(r * 5)
    if t in ('industrial', 'warehouse', 'grandstand', 'church', 'temple', 'religious', 'kiosk', 'service'):
        return 1 + int(r * 2)
    # "yes": by size (Yangon: small houses, 4-8 floor flats, big low halls)
    if area_m2 < 90:
        return 1 + int(r * 2)
    if area_m2 < 250:
        return 2 + int(r * 3)
    if area_m2 < 900:
        return 4 + int(r * 5)
    if area_m2 < 2500:
        return 3 + int(r * 5)
    return 2 + int(r * 3)


FRONT = float(os.environ.get('FRONT', '25'))
gaps = []
plots, dropped = [], {'outside': 0, 'water': 0, 'lot': 0, 'road': 0, 'small': 0, 'overlap': 0, 'ring': 0}
placed_rects = []
pgrid = {}
outlines.sort(key=lambda o: -poly_area_perim([world(*nodes[n]) for n in o[2] if n in nodes])[0] if len([n for n in o[2] if n in nodes]) >= 3 else 0)
for oid, tags, nd in outlines:
    ll = [nodes[n] for n in nd if n in nodes]
    if len(ll) < 4:
        continue
    pts = [world(*p) for p in ll]
    if pts[0] == pts[-1]:
        pts = pts[:-1]
    A, P = poly_area_perim(pts)
    area_m2 = A / (SPM * SPM)
    if area_m2 < 25:
        dropped['small'] += 1
        continue
    hr = hull_rect(pts)
    if not hr:
        continue
    cx, cz, ux, uz, a, b = hr
    if not (X0 < cx < X1 and Z0 < cz < Z1):
        dropped['outside'] += 1
        continue
    if math.hypot(cx - RING[0], cz - RING[1]) < RING[2] + max(a, b) / 2:
        dropped['ring'] += 1
        continue
    circ = 4 * math.pi * A / (P * P) if P else 0
    round_ = circ > 0.85 and len(ll) >= 10
    # keep the outline's area when its rectangle is much bigger (an L or a courtyard block)
    fill = A / (a * b) if a * b else 1
    if fill < 0.8 and not round_:
        k = math.sqrt(max(fill, 0.45) / 0.8)
        a, b = a * k, b * k
    # facing: towards the nearest road (the rectangle side whose normal points nearest to it)
    nr = nearest_road(cx, cz)
    if nr[1] is not None:
        tx, tz = nr[2] - cx, nr[3] - cz
        L = math.hypot(tx, tz) or 1
        tx, tz = tx / L, tz / L
    else:
        tx, tz = ux, uz
    # the two candidate facings: along u (side b faces it) or along v
    vx, vz = -uz, ux
    if abs(tx * ux + tz * uz) > abs(tx * vx + tz * vz):
        fx, fz = (ux, uz) if tx * ux + tz * uz > 0 else (-ux, -uz)
        d, w = a, b  # depth along u
    else:
        fx, fz = (vx, vz) if tx * vx + tz * vz > 0 else (-vx, -vz)
        d, w = b, a
    # (fx, fz) points FROM the building TO its road: the kit's frame looks out of the front
    pts_r = rect(cx, cz, fx, fz, w, d)
    # push out of roads (up to 20 studs), then the checks
    moved = 0.0
    ok = True
    for _ in range(6):
        depth, px, pz, rn, rk = worst_intrusion(pts_r + [(cx, cz)])
        if depth <= 0:
            break
        if rk == 'deck' or moved + depth > 20:
            ok = False
            break
        step = depth + 0.5
        cx, cz = cx + px * step, cz + pz * step
        moved += step
        pts_r = rect(cx, cz, fx, fz, w, d)
    if not ok:
        dropped['road'] += 1
        continue
    if any(near_water(x, z, 4) for x, z in pts_r) or any(in_poly(cx, cz, wp) for wp in ns['water']):
        dropped['water'] += 1
        continue
    if any(overlap(pts_r, bz) for bz in BLOCKED):
        dropped['lot'] += 1
        continue
    key = (int(cx // 150), int(cz // 150))
    clash = False
    for dx in (-1, 0, 1):
        for dz in (-1, 0, 1):
            for q in pgrid.get((key[0] + dx, key[1] + dz), ()):
                if overlap(rect(cx, cz, fx, fz, w - 1.5, d - 1.5), q):
                    clash = True
                    break
    if clash:
        dropped['overlap'] += 1
        continue
    pgrid.setdefault(key, []).append(pts_r)
    floors = floors_of(oid, tags, area_m2)
    # (from the front face, after any push back: the road's own pavement edge to the wall)
    nr2 = nearest_road(cx, cz)
    front_gap = (nr2[0] - d / 2) if nr2[1] is not None else 999
    frontage = front_gap < FRONT and w >= 14
    gaps.append(front_gap)
    t = tags.get('building')
    if round_:
        style = 'round'
    elif floors >= 10:
        style = 'tower'
    elif t in ('house', 'detached', 'bungalow') and floors <= 3 and frontage:
        style = 'villa'
    elif frontage:
        style = 'shophouse' if (nr[4] == 'route' and floors <= 5 and w <= 48 and hsh(oid, 3) < 0.5) else 'walkup'
    else:
        style = 'mass'
    name = tags.get('name:en') or tags.get('name') or ''
    if not re.match(r'^[ -~]*$', name):
        name = ''
    # (stored as d10's plots: (fx, fz) from the front to the back, i.e. AWAY from the road)
    plots.append({'x': round(cx, 2), 'z': round(cz, 2), 'fx': round(-fx, 4), 'fz': round(-fz, 4), 'w': round(max(w, 8), 1), 'd': round(max(d, 8), 1),
                  'road': nr[1] or '', 'kind': nr[4] or 'street', 'floors': floors, 'style': style, 'name': name[:40], 'osm': oid, 'moved': round(moved, 1),
                  'type': t})

# the three landmarks from step 8 stay
for p in landmarks:
    q = dict(p)
    q.pop('poly', None)
    plots.append(q)
os.makedirs(OUT, exist_ok=True)
styles = {}
for p in plots:
    styles[p.get('style', p.get('landmark'))] = styles.get(p.get('style', p.get('landmark')), 0) + 1
print('outlines', len(outlines), '-> plots', len(plots), styles)
print('dropped', dropped)
print('moved back from a road:', sum(1 for p in plots if p.get('moved', 0) > 0))
import statistics
print('frontage gap percentiles (studs past the pavement):', [round(sorted(gaps)[int(len(gaps) * q)]) for q in (0.1, 0.25, 0.5, 0.75)])
print('floors: max', max(p.get('floors', 0) for p in plots), ' 10+:', sum(1 for p in plots if p.get('floors', 0) >= 10))
doc = {'plots': plots, 'note': 'real building outlines (OSM, ODbL) as plots, tools/yangon/d19_buildings.py, 14 Nov 2026'}
txt = json.dumps(doc, separators=(',', ':'))
json.dump(doc, open(os.path.join(MAP, 'ygn_plots_real.json'), 'w'), separators=(',', ':'))
NL = chr(10)
for f in glob.glob(os.path.join(OUT, 'Plots2_*.luau')):
    os.remove(f)
pieces = (len(txt) + 189999) // 190000
n = (len(txt) + pieces - 1) // pieces
for k in range(pieces):
    open(os.path.join(OUT, 'Plots2_%d.luau' % (k + 1)), 'w', encoding='utf-8', newline=NL).write('return [==[' + txt[k * n:(k + 1) * n] + ']==]' + NL)
print('Plots2_1..%d.luau' % pieces, len(txt), 'chars')
