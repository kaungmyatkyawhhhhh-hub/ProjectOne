"""Whole-Yangon map (14 Nov 2026), master plan step A6: the DETAIL LAYER (the lived-in layer) for batch 0.5.

Owner: "the ingame yangon is too clean compared to real life yangon because in real life its compact", "wheres the fusan
basketball court, u need to add EVERY single detail". Lessons (14 Nov): "In-game Yangon is too clean and empty" and "Yangon's
overhead bridges are too low": every feature type in the data is built (courts, pitches, pools, walls, gates, pagodas, bus
stops, footbridges), and a city is never clean (walls, signs, wires, tea shops, trishaws). Report: build/plan/clutter.md.
No motorbike clusters (petrol motorbikes are banned in central Yangon): trishaws instead.

Data (OpenStreetMap contributors, ODbL): build/osm_ygn/*.json (e0_extract.py), build/city/plots_05.json (plots.py),
build/city/streets_05.json (+ its probe heights, streets.py), imports/refs/map/ygn_roads_v5.json (the game's part roads).

What it makes (each item: kind, anchor x z, a height hint, yaw, and its parts in the item's own frame):
  1 sport       every leisure=pitch / sports_centre / track: surface by sport, white lines 0.06 over the paint / 0.12 over
                the surface (flicker rule), tennis nets, basketball hoops, goals, a baseball diamond;
    sportfence  high chain fences (posts, 3 rails, diagonals) round tennis and futsal courts, a gate gap, a name sign
  2 pool        water (bright blue SmoothPlastic, Transparency 0), white coping, the darker floor at the edge, ladders
    parking     asphalt strips with white bay lines (surface lots only, clipped off roads and buildings)
  3 worship     stupas (zedi: square terraces, bell, lotus, banana bud, golden hti, corner shrines; named ones bigger),
                monastery halls (teak tiered roof), churches (gable, tower, cross), mosques (dome, minaret), Hindu temples
                (a colourful gopuram). Points inside a building plot are that building (the mesh kit's job): skipped.
  4 busstop     YBS-style shelters (posts, roof, back panel, bench, sign pole) at OSM bus stops, on the pavement
    signal      traffic signals at OSM traffic_signals junctions on the game roads: pole, arm over the road, head with
                three lamps (Neon only, one lit, no lights), on the right-hand kerb (Myanmar drives on the right)
    tree        the OSM natural=tree trees (GreenKit "Tree")
    gate        steel sliding gates between two pillars at OSM gates (snapped onto a compound wall when one is there)
  5 wall/fence/hedge  OSM barrier lines; compound   the classic compound wall on the street side of school / hospital /
                hall / monastery / villa / house plots with a yard and nothing else between them and the street
  6 footbridge  the pedestrian overpasses on their real lines, spanning the game road with 18 studs under the girders
  7 shopsign    a sign board on the nearest plot's front face for every OSM shop / restaurant / cafe / bank point (the
                OSM name as plain text, never a logo); teashop: low tables and plastic stools on the pavement
  8 pole        concrete power poles every ~56 studs on one side of each street (wires = Beams, 0 parts), kerbtree
                (painted white trunk bands) on main-road pavements, trishaw at lane mouths, patch (road patches)

Output: build/city/details_05.json (every item and part), build/city/Details_05_<n>.luau (one string each, < 185,000
bytes) for tools/yangon/YangonDetails.luau. Data line format (see the placer's header):
  Q idx r g b Material          palette
  D name / E                    prototype begin / end (parts in between)
  I kind x z yh yaw ex ez mode chain    an item ("-" = no height hint; mode G ground, M highest of 5 rays, R all 5 rays on
                                        "Road" parts; a trailing S = on a mesh street's pavement)
  U name                        the prototype's parts, in this item's frame
  B|C|H|S|W sx sy sz ox oy oz ry rx rz pal     a part (B block, C upright cylinder, H cylinder along local X, S ball,
                                        W wedge); angles in degrees, Roblox YXZ order
  T w|k text                    a SurfaceGui text on the last part's front (-Z) face (white or black letters)
  K kit wide band               a GreenKit tree at the item (band 1 = white trunk band, 2 = red and white)

Run from Games/CityLegends/tools/yangon/city:  python details.py   (then python details_test.py)
"""
import hashlib, json, math, os, random, re, sys

import numpy as np
import shapely
from shapely.geometry import LineString, MultiPoint, Point, Polygon, box as sbox
from shapely.ops import unary_union, nearest_points
from shapely.strtree import STRtree
from scipy.spatial import cKDTree

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import geo
import streets as streets_mod

YT = os.path.dirname(HERE)
OUT = os.path.join(geo.BUILD, 'city')
NL = chr(10)
TAG = '05'
MAX_BYTES = 185000
PART_BUDGET = 25000

# ---------------------------------------------------------------- the lots, landmarks, ring (d19's top, read only)
_src = open(os.path.join(YT, 'd19_buildings.py'), encoding='utf-8').read()
_ns = {'__file__': os.path.join(YT, 'd19_buildings.py')}
exec(compile(_src[:_src.index('# ---------------------------------------------------------------- the OSM buildings')], 'd19', 'exec'), _ns)
SITES, RING, LANDMARKS, rect = _ns['SITES'], _ns['RING'], _ns['landmarks'], _ns['rect']
X0, X1, Z0, Z1 = _ns['X0'], _ns['X1'], _ns['Z0'], _ns['Z1']


def H(*k):
    return int(hashlib.md5(repr(k).encode('utf-8')).hexdigest()[:8], 16)


def R(*k):
    return random.Random(H(*k))


def inside_box(x, z, m=10.0):
    return X0 + m < x < X1 - m and Z0 + m < z < Z1 - m


# ---------------------------------------------------------------- palette
PAL = {}
PAL_ORDER = []


def pal(name, rgb=None, mat='SmoothPlastic'):
    if name not in PAL:
        assert rgb is not None, name
        PAL[name] = (len(PAL_ORDER) + 1, rgb, mat)
        PAL_ORDER.append(name)
    return PAL[name][0]


for _n, _c, _m in [
    ('white', (240, 240, 236), 'SmoothPlastic'), ('line', (246, 246, 242), 'SmoothPlastic'), ('black', (30, 30, 32), 'SmoothPlastic'),
    ('concrete', (168, 166, 158), 'Concrete'), ('poleconc', (150, 148, 140), 'Concrete'), ('steel', (118, 122, 128), 'Metal'),
    ('darksteel', (52, 56, 60), 'Metal'), ('asphalt', (64, 64, 68), 'Asphalt'), ('patchdark', (40, 40, 43), 'Asphalt'),
    ('patchgrey', (98, 96, 92), 'Concrete'), ('court_green', (58, 118, 82), 'SmoothPlastic'), ('court_blue', (44, 92, 150), 'SmoothPlastic'),
    ('clay', (176, 92, 58), 'Sand'), ('court_conc', (150, 150, 146), 'Concrete'), ('key_orange', (214, 112, 44), 'SmoothPlastic'),
    ('grass', (74, 124, 58), 'Grass'), ('turf', (52, 132, 72), 'SmoothPlastic'), ('dirt', (150, 104, 66), 'Ground'),
    ('track_red', (168, 72, 54), 'SmoothPlastic'), ('net', (34, 38, 36), 'SmoothPlastic'), ('fence_green', (42, 74, 54), 'Metal'),
    ('hoop_orange', (226, 98, 30), 'SmoothPlastic'), ('board', (236, 236, 236), 'SmoothPlastic'),
    ('pool_water', (52, 172, 226), 'SmoothPlastic'), ('pool_floor', (26, 96, 156), 'SmoothPlastic'), ('coping', (236, 236, 228), 'Concrete'),
    ('ladder', (200, 204, 208), 'Metal'), ('whitewash', (242, 240, 232), 'Plaster'), ('gold', (214, 170, 58), 'SmoothPlastic'),
    ('teak', (112, 64, 34), 'WoodPlanks'), ('teak_dark', (82, 46, 26), 'Wood'), ('plinth', (204, 194, 172), 'Concrete'),
    ('cream', (237, 230, 214), 'Plaster'), ('roof_red', (150, 62, 46), 'SmoothPlastic'), ('door', (60, 44, 34), 'Wood'),
    ('mosque_green', (44, 124, 84), 'SmoothPlastic'), ('lamp_red', (255, 40, 30), 'Neon'), ('lamp_green', (40, 255, 110), 'Neon'),
    ('lamp_off_r', (70, 24, 22), 'SmoothPlastic'), ('lamp_off_a', (74, 58, 20), 'SmoothPlastic'), ('lamp_off_g', (20, 60, 34), 'SmoothPlastic'),
    ('hedge', (62, 108, 50), 'Grass'), ('gateplate', (122, 126, 130), 'DiamondPlate'), ('bench', (120, 84, 56), 'Wood'),
    ('ybs_blue', (32, 84, 164), 'SmoothPlastic'), ('ybs_panel', (232, 236, 240), 'SmoothPlastic'), ('table', (226, 222, 210), 'SmoothPlastic'),
    ('stool_red', (210, 40, 40), 'SmoothPlastic'), ('stool_blue', (36, 96, 200), 'SmoothPlastic'), ('stool_green', (44, 160, 72), 'SmoothPlastic'),
    ('trishaw_frame', (40, 40, 44), 'Metal'), ('tyre', (24, 24, 26), 'SmoothPlastic'), ('seat', (120, 40, 36), 'Fabric'),
    ('band_white', (238, 236, 228), 'SmoothPlastic'), ('band_red', (196, 40, 36), 'SmoothPlastic'), ('cable', (22, 22, 24), 'SmoothPlastic'),
    ('transformer', (128, 134, 132), 'Metal'),
]:
    pal(_n, _c, _m)

WALL_COLS = [(237, 230, 214), (196, 222, 204), (238, 224, 168), (184, 184, 178), (240, 238, 230), (228, 196, 172), (206, 216, 226)]
for _i, _c in enumerate(WALL_COLS):
    pal('wall%d' % _i, _c, 'Plaster')
SIGN_COLS = {
    'restaurant': ((178, 36, 36), 'w'), 'cafe': ((112, 72, 40), 'w'), 'tea': ((40, 110, 60), 'w'), 'coffee': ((112, 72, 40), 'w'),
    'bank': ((24, 70, 140), 'w'), 'convenience': ((232, 122, 22), 'w'), 'supermarket': ((22, 128, 70), 'w'),
    'mobile_phone': ((30, 140, 200), 'w'), 'electronics': ((30, 110, 170), 'w'), 'computer': ((30, 110, 170), 'w'),
    'clothes': ((120, 40, 120), 'w'), 'fashion': ((120, 40, 120), 'w'), 'shoes': ((120, 40, 120), 'w'), 'bag': ((120, 40, 120), 'w'),
    'jewelry': ((206, 166, 46), 'k'), 'gift': ((220, 90, 140), 'w'), 'cosmetics': ((220, 90, 140), 'w'), 'beauty': ((220, 90, 140), 'w'),
    'car': ((70, 72, 80), 'w'), 'car_parts': ((70, 72, 80), 'w'), 'car_repair': ((70, 72, 80), 'w'), 'bakery': ((236, 186, 120), 'k'),
    'dry_cleaning': ((70, 160, 200), 'w'), 'hairdresser': ((160, 60, 160), 'w'), 'books': ((150, 40, 40), 'w'),
    'travel_agency': ((20, 120, 160), 'w'), 'hardware': ((200, 120, 30), 'w'), 'pharmacy': ((30, 150, 90), 'w'),
}
for _k, (_c, _t) in SIGN_COLS.items():
    pal('sign_' + _k, _c)
pal('sign_default', (240, 240, 236))
GOPURAM = [(220, 80, 60), (240, 190, 60), (70, 140, 200), (120, 190, 90), (230, 120, 180)]
for _i, _c in enumerate(GOPURAM):
    pal('gop%d' % _i, _c)
TRISHAW_COLS = [(40, 96, 170), (40, 140, 80), (180, 50, 40), (60, 60, 64)]
for _i, _c in enumerate(TRISHAW_COLS):
    pal('tri%d' % _i, _c)


# ---------------------------------------------------------------- items
def rot_yxz(v, ry, rx, rz):
    """Roblox CFrame.fromEulerAnglesYXZ(rx, ry, rz) * v (= Ry * Rx * Rz), angles in radians"""
    x, y, z = v
    c, s = math.cos(rz), math.sin(rz)
    x, y = x * c - y * s, x * s + y * c
    c, s = math.cos(rx), math.sin(rx)
    y, z = y * c - z * s, y * s + z * c
    c, s = math.cos(ry), math.sin(ry)
    x, z = x * c + z * s, -x * s + z * c
    return (x, y, z)


class Item:
    def __init__(self, kind, x, z, yaw=0.0, mode='G', ex=0.0, ez=0.0, chain=0, name=None):
        self.kind, self.x, self.z, self.yaw, self.mode, self.ex, self.ez, self.chain = kind, x, z, yaw, mode, ex, ez, chain
        self.parts = []  # [shape, sx, sy, sz, ox, oy, oz, ry, rx, rz, palname, text, overhead]
        self.uses = []
        self.kits = []
        self.name = name
        self.yh = None
        self.street = False

    def add(self, shape, size, off, p, ry=0.0, rx=0.0, rz=0.0, text=None):
        self.parts.append([shape, size[0], size[1], size[2], off[0], off[1], off[2], ry, rx, rz, p, text])
        return self

    def box(self, size, off, p, ry=0.0, rx=0.0, rz=0.0, text=None):
        return self.add('B', size, off, p, ry, rx, rz, text)

    def span(self, lo, hi, size_xz, off_xz, p, shape='B', ry=0.0):
        """a part from height lo to hi"""
        return self.add(shape, (size_xz[0], hi - lo, size_xz[1]), (off_xz[0], (lo + hi) / 2, off_xz[1]), p, ry)

    def rod(self, a, b, t, p, shape='B'):
        """a bar from local point a to b (its long side = local Z)"""
        dx, dy, dz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
        L = math.sqrt(dx * dx + dy * dy + dz * dz)
        if L < 0.05:
            return self
        ry = math.atan2(dx, dz)
        rx = -math.asin(max(-1.0, min(1.0, dy / L)))
        return self.add(shape, (t, t, L), ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, (a[2] + b[2]) / 2), p, ry, rx, 0.0)

    def world(self, ox, oz):
        c, s = math.cos(self.yaw), math.sin(self.yaw)
        return (self.x + ox * c + oz * s, self.z - ox * s + oz * c)

    def part_geo(self, prt):
        """(plan polygon, lowest y, highest y) of one part, relative to the item's ground"""
        shape, sx, sy, sz, ox, oy, oz, ry, rx, rz = prt[:10]
        pts = []
        lo, hi = 1e9, -1e9
        for a in (-0.5, 0.5):
            for b in (-0.5, 0.5):
                for c in (-0.5, 0.5):
                    v = rot_yxz((a * sx, b * sy, c * sz), ry, rx, rz)
                    v = (v[0] + ox, v[1] + oy, v[2] + oz)
                    wx, wz = self.world(v[0], v[2])
                    pts.append((wx, wz))
                    lo, hi = min(lo, v[1]), max(hi, v[1])
        return MultiPoint(pts).convex_hull, lo, hi

    def all_parts(self):
        out = list(self.parts)
        for u in self.uses:
            out += PROTOS[u]
        return out

    def n_parts(self):
        return len(self.parts) + sum(len(PROTOS[u]) for u in self.uses) + sum(3 + (1 if k[2] else 0) for k in self.kits)


ITEMS = []
PROTOS = {}


def proto(name, parts_item):
    PROTOS[name] = parts_item.parts


def keep(it):
    ITEMS.append(it)
    return it


def yaw_x(ax, az):
    """yaw whose local +X points along (ax, az)"""
    return math.atan2(-az, ax)


def yaw_face(fx, fz):
    """yaw whose local -Z (the front) faces (fx, fz)"""
    return math.atan2(-fx, -fz)


def unit(dx, dz):
    L = math.hypot(dx, dz) or 1.0
    return dx / L, dz / L


# ---------------------------------------------------------------- the map's geometry
print('loading ...')
GAME = json.load(open(os.path.join(geo.MAP, 'ygn_roads_v5.json'), encoding='utf-8'))
GPAVE, GCARR = streets_mod.game_pave(GAME)
ST = streets_mod.heights(TAG)
PLOTS = json.load(open(os.path.join(OUT, f'plots_{TAG}.json'), encoding='utf-8'))['plots']
PPOLY = [Polygon(p['poly']).buffer(0) for p in PLOTS]
PTREE = STRtree(PPOLY)

# every road as one record: the game's part roads (each run of samples between cuts) and the new mesh streets
RD = []
for r in GAME['roads']:
    cs = set(GAME.get('cut', {}).get(r['name'], []))
    walk = r.get('walkL') or 10.0
    run = []
    for k, s in enumerate(r['s'] + [None]):
        if s is None or k in cs:
            if len(run) > 3:
                RD.append({'id': 'g:%s:%d' % (r['name'], len(RD)), 'name': r['name'], 'src': 'game', 'kind': r.get('kind'),
                           'half': max(max(q[6], q[7]) for q in run), 'walk': walk, 'pts': [(q[0], q[2]) for q in run],
                           'ys': [q[1] for q in run], 'mouth': (False, False)})
            run = []
            continue
        run.append(s)
for s in ST:
    RD.append({'id': 's:%s' % s['id'], 'name': s['name'], 'src': 'street', 'kind': s['cls'], 'half': s['half'], 'walk': s['walk'],
               'pts': [tuple(p) for p in s['pts']], 'ys': s['y0'], 'mouth': tuple(s['mouth'])})
for rd in RD:
    rd['line'] = LineString(rd['pts'])
    rd['carr'] = rd['line'].buffer(rd['half'], cap_style=2, join_style=1)
    rd['outer'] = rd['line'].buffer(rd['half'] + rd['walk'], cap_style=2, join_style=1)
RD_LINES = [rd['line'] for rd in RD]
RD_TREE = STRtree(RD_LINES)
RD_CARR_TREE = STRtree([rd['carr'] for rd in RD])

DECK_CARR = unary_union([LineString([(q[0], q[2]) for q in d['s']]).buffer(32, cap_style=2) for d in GAME['decks']])
DECK_ZONE = unary_union([LineString([(q[0], q[2]) for q in d['s']]).buffer(44) for d in GAME['decks']])
RING_CARR = Point(RING[0], RING[1]).buffer(108)
RING_ZONE = Point(RING[0], RING[1]).buffer(RING[2])
SCARR = unary_union([rd['carr'] for rd in RD if rd['src'] == 'street'])
SOUTER = unary_union([rd['outer'] for rd in RD if rd['src'] == 'street'])
CARR = unary_union([GCARR, SCARR, DECK_CARR, RING_CARR])
PAVE = unary_union([GPAVE, SOUTER, RING_ZONE])
SPAVE_ONLY = SOUTER.difference(SCARR).difference(GPAVE)

water = []
for a in geo.load('areas'):
    t = a['t']
    if t.get('natural') == 'water' or t.get('water') or t.get('landuse') in ('reservoir', 'basin'):
        pp = geo.proj(a['p'])
        if len(pp) >= 3 and any(X0 - 300 < x < X1 + 300 and Z0 - 300 < z < Z1 + 300 for x, z in pp):
            water.append(Polygon(pp).buffer(0))
WATER = unary_union(water).buffer(2) if water else Polygon()
BLK = unary_union([Polygon(rect(*s, grow=10)) for s in SITES] +
                  [Polygon(rect(p['x'], p['z'], p['fx'], p['fz'], p['w'], p['d'], grow=8)) for p in LANDMARKS])
NOGO = unary_union([CARR, WATER, BLK, DECK_ZONE, RING_ZONE])
for g in (CARR, PAVE, NOGO, WATER, SPAVE_ONLY, DECK_ZONE, BLK):
    shapely.prepare(g)

# height hints: the game road samples and the streets' heights
_hp = [(q[0], q[2], q[1]) for r in GAME['roads'] for q in r['s']] + [(p[0], p[1], y) for s in ST for p, y in zip(s['pts'], s['y0'])]
HP = np.array(_hp)
HTREE = cKDTree(HP[:, :2])


def yhint(x, z):
    d, i = HTREE.query((x, z))
    return float(HP[i, 2]) if d < 160 else None


def plots_hit(g):
    return [int(i) for i in PTREE.query(g, predicate='intersects')]


def clear(g, pave=False, plots=True, nogo=True):
    if nogo and NOGO.intersects(g):
        return False
    if not nogo and CARR.intersects(g):
        return False
    if pave and PAVE.intersects(g):
        return False
    if plots and len(PTREE.query(g, predicate='intersects')):
        return False
    return True


# occupancy of point-like things (lamps, the green layer's trees, and everything placed here)
OCC = {}


def occ_free(x, z, r):
    k = (int(x // 16), int(z // 16))
    for dx in (-1, 0, 1):
        for dz in (-1, 0, 1):
            for (qx, qz, qr) in OCC.get((k[0] + dx, k[1] + dz), ()):
                if math.hypot(qx - x, qz - z) < r + qr:
                    return False
    return True


def occ_add(x, z, r):
    OCC.setdefault((int(x // 16), int(z // 16)), []).append((x, z, r))


LAMPS = []
for line in open(os.path.join(geo.BUILD, 'yangon_lamps', 'YangonLampSpots.luau'), encoding='utf-8'):
    m = re.match(r'^([-\d.]+) ([-\d.]+) ([-\d.]+) ', line)
    if m:
        LAMPS.append((float(m.group(1)), float(m.group(2))))
        occ_add(float(m.group(1)), float(m.group(2)), 3.0)
LTREE = cKDTree(np.array(LAMPS))
for line in open(os.path.join(geo.BUILD, 'yangon_green', 'YangonGreenData.luau'), encoding='utf-8'):
    m = re.match(r'^[TP] ([-\d.]+) ([-\d.]+)', line)
    if m:
        occ_add(float(m.group(1)), float(m.group(2)), 1.2)


def frame(poly):
    """the polygon's minimum rectangle: centre, long axis (ax, az), long side L, short side W, area / rectangle area"""
    mrr = poly.minimum_rotated_rectangle
    cs = list(mrr.exterior.coords)[:4]
    e1 = (cs[1][0] - cs[0][0], cs[1][1] - cs[0][1])
    e2 = (cs[2][0] - cs[1][0], cs[2][1] - cs[1][1])
    L1, L2 = math.hypot(*e1), math.hypot(*e2)
    if L1 >= L2:
        ax, az, L, W = e1[0] / L1, e1[1] / L1, L1, L2
    else:
        ax, az, L, W = e2[0] / L2, e2[1] / L2, L2, L1
    c = mrr.centroid
    return c.x, c.y, ax, az, L, W, (poly.area / mrr.area if mrr.area > 0 else 0)


def to_local(poly, cx, cz, ax, az):
    def tr(pts):
        return [((x - cx) * ax + (z - cz) * az, (x - cx) * (-az) + (z - cz) * ax) for x, z in pts]
    return Polygon(tr(poly.exterior.coords), [tr(h.coords) for h in poly.interiors]).buffer(0)


def intervals(poly, v):
    """the u intervals where the line v = const lies inside poly (local frame)"""
    b = poly.bounds
    g = poly.intersection(LineString([(b[0] - 1, v), (b[2] + 1, v)]))
    out = []
    for s in getattr(g, 'geoms', [g]):
        if s.geom_type == 'LineString' and s.length > 0.2:
            xs = [c[0] for c in s.coords]
            out.append((min(xs), max(xs)))
    return sorted(out)


def inter_iv(a, b):
    out = []
    for (a0, a1) in a:
        for (b0, b1) in b:
            lo, hi = max(a0, b0), min(a1, b1)
            if hi - lo > 0.3:
                out.append((lo, hi))
    return out


def strips(poly_local, width):
    """inner strips (u0, u1, v0, v1) filling a local polygon"""
    b = poly_local.bounds
    out = []
    v = b[1]
    while v < b[3] - 0.3:
        v1 = min(v + width, b[3])
        iv = inter_iv(inter_iv(intervals(poly_local, v + 0.05), intervals(poly_local, (v + v1) / 2)), intervals(poly_local, v1 - 0.05))
        for (u0, u1) in iv:
            out.append((u0, u1, v, v1))
        v = v1
    return out


def ascii_name(n, fallback):
    if not n:
        return fallback
    words = [w for w in re.split(r'\s+', n) if w and all(32 <= ord(ch) < 127 for ch in w)]
    s = ' '.join(words).strip(' -,()')
    s = s.replace(']', ')').replace('[', '(')
    return s[:40] if len(s) >= 2 else fallback


# ---------------------------------------------------------------- 1. sports
SURF_TOP, PAINT_TOP, LINE_TOP = 0.20, 0.26, 0.32


def court_lines(it, segs, w=0.25, top=LINE_TOP):
    for (u0, v0, u1, v1) in segs:
        L = math.hypot(u1 - u0, v1 - v0)
        if L < 0.1:
            continue
        it.add('B', (L + w, 0.1, w), ((u0 + u1) / 2, top - 0.05, (v0 + v1) / 2), 'line', math.atan2(-(v1 - v0), u1 - u0))


def arc(cu, cv, r, a0, a1, n):
    pts = [(cu + r * math.cos(a0 + (a1 - a0) * i / n), cv + r * math.sin(a0 + (a1 - a0) * i / n)) for i in range(n + 1)]
    return [(pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1]) for i in range(n)]


def rect_lines(u0, v0, u1, v1):
    return [(u0, v0, u1, v0), (u1, v0, u1, v1), (u1, v1, u0, v1), (u0, v1, u0, v0)]


def surface(it, L, W, p):
    it.box((L, 1.4, W), (0, SURF_TOP - 0.7, 0), p)


def tennis(it, L, W, r):
    CL, CW, SW, SV = 23.77 * 1.6, 10.97 * 1.6, 8.23 * 1.6, 6.40 * 1.6
    s = max(0.5, min(1.0, (L - 3) / CL, (W - 2) / CW))
    cl, cw, sw, sv = CL * s, CW * s, SW * s, SV * s
    style = r.choice(['blue', 'blue', 'green', 'clay'])
    surface(it, L, W, 'clay' if style == 'clay' else 'court_green')
    if style == 'blue':
        it.box((cl + 4 * s, 0.1, cw + 3 * s), (0, PAINT_TOP - 0.05, 0), 'court_blue')
    segs = rect_lines(-cl / 2, -cw / 2, cl / 2, cw / 2)
    segs += [(-cl / 2, -sw / 2, cl / 2, -sw / 2), (-cl / 2, sw / 2, cl / 2, sw / 2), (-sv, -sw / 2, -sv, sw / 2), (sv, -sw / 2, sv, sw / 2),
             (-sv, 0, sv, 0)]
    court_lines(it, segs)
    nv = cw / 2 + 1.4 * s
    for v in (-nv, nv):
        it.add('C', (0.3, 2.1, 0.3), (0, SURF_TOP + 1.0, v), 'darksteel')
    it.box((0.12, 1.55, 2 * nv), (0, SURF_TOP + 0.97, 0), 'net')
    it.box((0.24, 0.16, 2 * nv), (0, SURF_TOP + 1.75, 0), 'white')


def basketball(it, L, W, r):
    BL, BW = 28 * 1.6, 15 * 1.6
    s = max(0.5, min(1.0, (L - 2.6) / BL, (W - 2) / BW))
    bl, bw = BL * s, BW * s
    surface(it, L, W, r.choice(['court_conc', 'court_conc', 'court_green', 'court_blue']))
    kd, kw = 5.8 * 1.6 * s, 4.9 * 1.6 * s
    for sg in (-1, 1):
        it.box((kd, 0.1, kw), (sg * (bl / 2 - kd / 2), PAINT_TOP - 0.05, 0), 'key_orange')
    segs = rect_lines(-bl / 2, -bw / 2, bl / 2, bw / 2) + [(0, -bw / 2, 0, bw / 2)]
    segs += arc(0, 0, 1.8 * 1.6 * s, 0, 2 * math.pi, 6)
    R3, bu = 6.75 * 1.6 * s, bl / 2 - 1.575 * 1.6 * s
    cv = bw / 2 - 0.9 * 1.6 * s
    phi = math.asin(min(0.99, cv / R3))
    for sg in (-1, 1):
        segs += [(sg * bl / 2, -kw / 2, sg * (bl / 2 - kd), -kw / 2), (sg * bl / 2, kw / 2, sg * (bl / 2 - kd), kw / 2),
                 (sg * (bl / 2 - kd), -kw / 2, sg * (bl / 2 - kd), kw / 2)]
        cu = sg * bu
        a0, a1 = (math.pi - phi, math.pi + phi) if sg > 0 else (-phi, phi)
        segs += arc(cu, 0, R3, a0, a1, 5)
        ue = cu - sg * R3 * math.cos(phi)
        segs += [(sg * bl / 2, -cv, ue, -cv), (sg * bl / 2, cv, ue, cv)]
        pu = sg * (bl / 2 + min(1.2, (L - bl) / 2 - 0.3))
        it.add('C', (0.5, 9.8, 0.5), (pu, 4.4, 0), 'darksteel')
        bdu = sg * (bl / 2 - 1.2 * 1.6 * s)
        it.box((abs(pu - bdu) + 0.3, 0.3, 0.3), ((pu + bdu) / 2, 9.0, 0), 'darksteel')
        it.box((0.2, 2.8, 4.4), (bdu, 9.6, 0), 'board')
        ru = sg * bu
        for (du, dv, lu, lv) in ((0, -0.7, 1.4, 0.12), (0, 0.7, 1.4, 0.12), (-0.7, 0, 0.12, 1.4), (0.7, 0, 0.12, 1.4)):
            it.box((lu, 0.12, lv), (ru + du, 8.6, dv), 'hoop_orange')
    court_lines(it, segs, w=0.22)


def soccer(it, L, W, r, grass=None):
    big = L >= 110
    pl, pw = L - 3.2, min(W - 3.2, (L - 3.2) * 0.75)
    if grass is None:
        grass = 'grass' if big else r.choice(['turf', 'turf', 'grass'])
    surface(it, L, W, grass)
    segs = rect_lines(-pl / 2, -pw / 2, pl / 2, pw / 2) + [(0, -pw / 2, 0, pw / 2)]
    if big:
        cr, pd, pwid, gw, gh = 9.15 / 105 * pl, 16.5 / 105 * pl, 40.3 / 68 * pw, 7.32 / 68 * pw, 6.0
    else:
        cr, pd, pwid, gw, gh = 3.0 / 40 * pl, 6.0 / 40 * pl, 0.5 * pw, 3.0 / 20 * pw, 4.5
    segs += arc(0, 0, cr, 0, 2 * math.pi, 8)
    for sg in (-1, 1):
        u0, u1 = sg * pl / 2, sg * (pl / 2 - pd)
        segs += [(u0, -pwid / 2, u1, -pwid / 2), (u1, -pwid / 2, u1, pwid / 2), (u1, pwid / 2, u0, pwid / 2)]
        gu = sg * pl / 2
        for v in (-gw / 2, gw / 2):
            it.add('C', (0.4, gh, 0.4), (gu, SURF_TOP + gh / 2 - 0.1, v), 'white')
        it.add('H', (gw + 0.4, 0.4, 0.4), (gu, SURF_TOP + gh - 0.1, 0), 'white', math.pi / 2)
        it.box((0.25, 0.25, gw), (gu + sg * 1.3, SURF_TOP + 0.08, 0), 'white')
    court_lines(it, segs)


def baseball(it, L, W, r, poly_local):
    if poly_local.area < 0.8 * L * W:
        for (u0, u1, v0, v1) in strips(poly_local.buffer(-0.5), 4.0):
            it.box((u1 - u0, 1.4, v1 - v0), ((u0 + u1) / 2, SURF_TOP - 0.7, (v0 + v1) / 2), 'grass')
    else:
        surface(it, L, W, 'grass')
    # home plate: the local polygon's sharpest corner (a fan) or a rectangle corner
    hull = list(poly_local.convex_hull.exterior.coords)[:-1]
    best = None
    for i, p in enumerate(hull):
        a, b = hull[i - 1], hull[(i + 1) % len(hull)]
        v1, v2 = (a[0] - p[0], a[1] - p[1]), (b[0] - p[0], b[1] - p[1])
        ang = math.acos(max(-1, min(1, (v1[0] * v2[0] + v1[1] * v2[1]) / ((math.hypot(*v1) * math.hypot(*v2)) or 1))))
        if best is None or ang < best[0]:
            best = (ang, p)
    hu, hv = best[1]
    c = poly_local.centroid
    du, dv = unit(c.x - hu, c.y - hv)
    hu, hv = hu + du * 3, hv + dv * 3
    reach = math.hypot(c.x - hu, c.y - hv) * 1.6
    side = max(14.0, min(27.43 * 1.6, reach * 0.55))
    d45 = side / math.sqrt(2)
    cu, cv = hu + du * d45, hv + dv * d45
    ry = math.atan2(-dv, du) + math.pi / 4
    it.add('B', (side * 1.22, 0.1, side * 1.22), (cu, PAINT_TOP - 0.05, cv), 'dirt', ry)
    it.add('B', (side * 0.78, 0.1, side * 0.78), (cu, LINE_TOP - 0.05, cv), 'grass', ry)
    for k in range(4):
        a = math.atan2(dv, du) + math.pi / 4 * (-1 if k == 1 else (1 if k == 3 else 0))
        if k == 0:
            bu, bv = hu, hv
        elif k == 2:
            bu, bv = hu + du * side * math.sqrt(2), hv + dv * side * math.sqrt(2)
        else:
            bu, bv = hu + math.cos(a) * side, hv + math.sin(a) * side
        it.add('B', (1.1, 0.1, 1.1), (bu, LINE_TOP + 0.01, bv), 'white', ry)
    it.add('C', (3.2, 0.1, 3.2), (cu, LINE_TOP + 0.01, cv), 'dirt')
    for sgn in (-1, 1):
        a = math.atan2(dv, du) + sgn * math.pi / 4
        ex_, ez_ = hu + math.cos(a) * 400, hv + math.sin(a) * 400
        g = poly_local.buffer(-1).intersection(LineString([(hu, hv), (ex_, ez_)]))
        if not g.is_empty and g.length > 3:
            far = max((Point(q) for q in (getattr(g, 'coords', None) or g.geoms[0].coords)), key=lambda q: q.distance(Point(hu, hv)))
            court_lines(it, [(hu, hv, far.x, far.y)], w=0.25, top=LINE_TOP + 0.06)


FENCE_H = 7.2


def fence_edge(a, b, include_end, colour='fence_green'):
    """an item: a chain fence from world a to b"""
    dx, dz = b[0] - a[0], b[1] - a[1]
    E = math.hypot(dx, dz)
    if E < 1.5:
        return None
    it = Item('sportfence', (a[0] + b[0]) / 2, (a[1] + b[1]) / 2, yaw_x(dx / E, dz / E), 'M', E / 2, 0)
    n = max(1, int(math.ceil(E / 10.0)))
    us = [-E / 2 + E * i / n for i in range(n + 1)]
    for i, u in enumerate(us):
        if i == n and not include_end:
            continue
        it.add('C', (0.35, FENCE_H + 0.8, 0.35), (u, (FENCE_H - 0.8) / 2, 0), colour)
    for y in (0.35, FENCE_H * 0.5, FENCE_H - 0.15):
        it.box((E, 0.18, 0.18), (0, y, 0), colour)
    for i in range(0, n, 2):
        sg = 1 if (i // 2) % 2 == 0 else -1
        u0, u1 = us[i], us[i + 1]
        it.rod((u0 if sg > 0 else u1, 0.35, 0.06), (u1 if sg > 0 else u0, FENCE_H - 0.15, 0.06), 0.12, colour)
    return it


def name_sign(x, z, fx, fz, text):
    it = Item('sportfence', x, z, yaw_face(fx, fz), 'G')
    it.add('C', (0.25, 6.5, 0.25), (-2.2, 2.25, 0.2), 'darksteel')
    it.add('C', (0.25, 6.5, 0.25), (2.2, 2.25, 0.2), 'darksteel')
    it.box((5.2, 1.6, 0.2), (0, 4.6, 0), 'ybs_blue', text=('w', text))
    return it


def sports():
    n0 = len(ITEMS)
    fenced = []  # (world polygon, name)
    cnt = {}
    for a in geo.load('areas'):
        t = a['t']
        lei = t.get('leisure')
        if lei not in ('pitch', 'sports_centre', 'track'):
            continue
        pp = geo.proj(a['p'])
        if len(pp) < 3:
            continue
        holes = [geo.proj(h) for h in (a.get('h') or []) if len(h) >= 3]
        poly = Polygon(pp, holes).buffer(0)
        c = poly.centroid
        if not inside_box(c.x, c.y, 20) or poly.area < 60:
            continue
        cover = sum(PPOLY[i].intersection(poly).area for i in plots_hit(poly))
        if cover > 0.4 * poly.area:
            cnt['indoor (a building on it)'] = cnt.get('indoor (a building on it)', 0) + 1
            continue
        loc_carr = CARR.intersection(poly.buffer(4))
        free = poly.difference(loc_carr.buffer(0.6)).difference(unary_union([PPOLY[i] for i in plots_hit(poly)] or [Polygon()]).buffer(0.6))
        free = free.difference(WATER).difference(BLK)
        if free.is_empty or free.area < 0.6 * poly.area:
            cnt['mostly under a road / lot'] = cnt.get('mostly under a road / lot', 0) + 1
            continue
        if free.geom_type != 'Polygon':
            free = max(free.geoms, key=lambda g: g.area)
        cx, cz, ax, az, L, W, rectness = frame(free)
        sport = (t.get('sport') or '').split(';')[0]
        name = ascii_name(t.get('name:en') or t.get('name'), None)
        r = R('sport', a['id'])
        if lei == 'track' or sport in ('running', 'athletics'):
            loc = to_local(free, cx, cz, ax, az)
            it = Item('sport', cx, cz, yaw_x(ax, az), 'M', L / 2 - 1, W / 2 - 1, name=name)
            ring = loc.buffer(-0.4)
            for (u0, u1, v0, v1) in strips(ring, 3.0):
                it.box((u1 - u0, 1.4, v1 - v0), ((u0 + u1) / 2, SURF_TOP - 0.7, (v0 + v1) / 2), 'track_red')
            keep(it)
            cnt['track'] = cnt.get('track', 0) + 1
            for h in free.interiors:
                hp = Polygon(h.coords)
                if hp.area > 400:
                    hx, hz, hax, haz, hL, hW, _ = frame(hp)
                    it2 = Item('sport', hx, hz, yaw_x(hax, haz), 'M', hL / 2 - 1, hW / 2 - 1)
                    soccer(it2, hL - 1.0, hW - 1.0, r, grass='grass')
                    keep(it2)
                    cnt['soccer'] = cnt.get('soccer', 0) + 1
            continue
        if sport == 'tennis':
            kind = 'tennis'
        elif sport in ('basketball', 'volleyball', 'badminton', 'multi', 'table_tennis'):
            kind = 'basketball'
        elif sport in ('soccer', 'football', 'futsal'):
            kind = 'soccer'
        elif sport == 'baseball':
            kind = 'baseball'
        else:
            kind = 'soccer' if L >= 70 else ('futsal' if L >= 40 else 'basketball')
        if rectness >= 0.8 or kind != 'baseball':
            mrr = free.minimum_rotated_rectangle
            if rectness < 0.8:
                # a ragged outline: the largest rectangle-ish core (the rectangle shrunk until it is inside)
                for k in range(1, 12):
                    sh = 1 - 0.04 * k
                    test = Polygon([(cx + ((x - cx) * sh), cz + ((z - cz) * sh)) for x, z in mrr.exterior.coords])
                    if free.buffer(0.3).contains(test):
                        L, W = L * sh, W * sh
                        break
                else:
                    L, W = L * 0.55, W * 0.55
            L, W = L - 0.8, W - 0.8
            blockers = unary_union([loc_carr.buffer(0.3)] + [PPOLY[i].buffer(0.3) for i in plots_hit(poly)])
            for k in range(14):
                rc = Polygon([(cx + u * ax - v * az, cz + u * az + v * ax) for u, v in ((-L / 2, -W / 2), (L / 2, -W / 2), (L / 2, W / 2), (-L / 2, W / 2))])
                if not rc.intersects(blockers):
                    break
                L, W = L * 0.95, W * 0.95
            else:
                cnt['no clear rectangle'] = cnt.get('no clear rectangle', 0) + 1
                continue
            if L < 12 or W < 8:
                cnt['too small once clear'] = cnt.get('too small once clear', 0) + 1
                continue
        it = Item('sport', cx, cz, yaw_x(ax, az), 'M', L / 2, W / 2, name=name)
        if kind == 'tennis':
            tennis(it, L, W, r)
        elif kind == 'basketball':
            basketball(it, L, W, r)
        elif kind == 'baseball':
            baseball(it, L, W, r, to_local(free, cx, cz, ax, az))
        else:
            soccer(it, L, W, r)
        keep(it)
        cnt[kind] = cnt.get(kind, 0) + 1
        if kind in ('tennis', 'futsal') or (kind == 'soccer' and L < 110):
            fenced.append((Polygon([it.world(u, v) for u, v in ((-L / 2, -W / 2), (L / 2, -W / 2), (L / 2, W / 2), (-L / 2, W / 2))]), name))
    # fences: one round each group of touching courts
    if fenced:
        groups = unary_union([p.buffer(1.6, join_style=2) for p, _ in fenced])
        for g in getattr(groups, 'geoms', [groups]):
            g = g.buffer(-1.6, join_style=2).simplify(0.8)
            if g.is_empty or g.geom_type != 'Polygon':
                continue
            ring = g.buffer(-0.5, join_style=2)
            if ring.is_empty or ring.geom_type != 'Polygon':
                continue
            cs = list(ring.exterior.coords)
            # the gate: the middle of the edge nearest a road
            best, gi = 1e9, None
            for i in range(len(cs) - 1):
                if math.dist(cs[i], cs[i + 1]) < 8:
                    continue
                m = Point((cs[i][0] + cs[i + 1][0]) / 2, (cs[i][1] + cs[i + 1][1]) / 2)
                d = m.distance(PAVE)
                if d < best:
                    best, gi = d, i
            names = [n for p, n in fenced if n and p.intersects(g)]
            for i in range(len(cs) - 1):
                a, b = cs[i], cs[i + 1]
                if i == gi:
                    E = math.dist(a, b)
                    ux, uz = (b[0] - a[0]) / E, (b[1] - a[1]) / E
                    m = (E / 2 - 2.2, E / 2 + 2.2)
                    for it in (fence_edge(a, (a[0] + ux * m[0], a[1] + uz * m[0]), True),
                               fence_edge((a[0] + ux * m[1], a[1] + uz * m[1]), b, False)):
                        if it:
                            keep(it)
                    if names:
                        # the sign stands outside, beside the gate, facing out
                        nx, nz = uz, -ux
                        mid = (a[0] + ux * E / 2, a[1] + uz * E / 2)
                        if ring.contains(Point(mid[0] + nx, mid[1] + nz)):
                            nx, nz = -nx, -nz
                        sx_, sz_ = mid[0] + ux * 5.5 + nx * 1.2, mid[1] + uz * 5.5 + nz * 1.2
                        if clear(Point(sx_, sz_).buffer(2.8)):
                            keep(name_sign(sx_, sz_, nx, nz, names[0]))
                else:
                    it = fence_edge(a, b, False)
                    if it:
                        keep(it)
    print('sports', cnt, len(ITEMS) - n0, 'items')


# ---------------------------------------------------------------- 2. pools and parking
def pools():
    n0, skipped = len(ITEMS), 0
    for a in geo.load('areas'):
        t = a['t']
        if t.get('leisure') != 'swimming_pool':
            continue
        pp = geo.proj(a['p'])
        if len(pp) < 3:
            continue
        poly = Polygon(pp).buffer(0)
        c = poly.centroid
        if not inside_box(c.x, c.y, 20) or poly.area < 12:
            continue
        hit = plots_hit(poly)
        cover = sum(PPOLY[i].intersection(poly).area for i in hit)
        if cover > 0.3 * poly.area or NOGO.intersects(poly):
            skipped += 1
            continue
        if hit:
            poly = poly.difference(unary_union([PPOLY[i] for i in hit]).buffer(0.6))
            if poly.geom_type != 'Polygon':
                poly = max(poly.geoms, key=lambda g: g.area)
        cx, cz, ax, az, L, W, rectness = frame(poly)
        it = Item('pool', cx, cz, yaw_x(ax, az), 'M', L / 2, W / 2, name=ascii_name(t.get('name:en') or t.get('name'), None))
        if rectness >= 0.85:
            L, W = L - 0.4, W - 0.4
            cw = 1.0
            for sg in (-1, 1):
                it.box((L, 0.9, cw), (0, -0.05, sg * (W / 2 - cw / 2)), 'coping')
                it.box((cw, 0.9, W - 2 * cw), (sg * (L / 2 - cw / 2), -0.05, 0), 'coping')
            it.box((L - 2 * cw, 0.9, W - 2 * cw), (0, 0.12 - 0.45, 0), 'pool_floor')
            it.box((L - 2 * cw - 1.4, 0.9, W - 2 * cw - 1.4), (0, 0.24 - 0.45, 0), 'pool_water')
            ladders = [(-L / 2 + cw + 2.5, -(W / 2 - cw)), (L / 2 - cw - 2.5, W / 2 - cw)] if L > 10 else [(0, -(W / 2 - cw))]
        else:
            loc = to_local(poly, cx, cz, ax, az).simplify(0.5)
            if loc.geom_type != 'Polygon':
                continue
            cs = list(loc.exterior.coords)
            for i in range(len(cs) - 1):
                (u0, v0), (u1, v1) = cs[i], cs[i + 1]
                E = math.hypot(u1 - u0, v1 - v0)
                if E < 0.3:
                    continue
                # the coping sits on the edge, 1 wide, inward
                nu, nv = -(v1 - v0) / E, (u1 - u0) / E
                if not loc.contains(Point((u0 + u1) / 2 + nu * 0.5, (v0 + v1) / 2 + nv * 0.5)):
                    nu, nv = -nu, -nv
                it.add('B', (E + 0.6, 0.9, 1.0), ((u0 + u1) / 2 + nu * 0.5, -0.05, (v0 + v1) / 2 + nv * 0.5), 'coping',
                       math.atan2(-(v1 - v0), u1 - u0))
            for poly2, p, top in ((loc.buffer(-0.9), 'pool_floor', 0.12), (loc.buffer(-1.6), 'pool_water', 0.24)):
                if poly2.is_empty:
                    continue
                for g in getattr(poly2, 'geoms', [poly2]):
                    for (u0, u1, v0, v1) in strips(g, 2.0):
                        it.box((u1 - u0, 0.9, v1 - v0), ((u0 + u1) / 2, top - 0.45, (v0 + v1) / 2), p)
            ladders = []
            L, W = L - 0.4, W - 0.4
        for (lu, lv) in ladders:
            sg = 1 if lv < 0 else -1
            for du in (-0.6, 0.6):
                it.add('C', (0.16, 2.4, 0.16), (lu + du, 0.9, lv + sg * 0.25), 'ladder')
                it.add('H', (0.9, 0.16, 0.16), (lu + du, 2.0, lv - sg * 0.05), 'ladder', math.pi / 2)
            it.add('H', (1.2, 0.12, 0.12), (lu, 0.5, lv + sg * 0.25), 'ladder')
        keep(it)
        if it.name:
            # a name board beside the pool, on the side towards the nearest road, facing it
            q = nearest_points(PAVE, Point(cx, cz))[0]
            fx, fz = unit(q.x - cx, q.y - cz)
            for dist in range(4, 140, 2):
                px, pz = cx + fx * dist, cz + fz * dist
                g = Point(px, pz).buffer(2.9)
                if not poly.buffer(1.5).intersects(g) and clear(g) and occ_free(px, pz, 2.9):
                    keep(name_sign(px, pz, fx, fz, it.name))
                    occ_add(px, pz, 2.9)
                    break
    print('pools', len(ITEMS) - n0, 'skipped (on a building / a road)', skipped)


def parking():
    n0, nl = len(ITEMS), 0
    for a in geo.load('areas'):
        t = a['t']
        if t.get('amenity') != 'parking' or t.get('parking') in ('underground', 'multi-storey', 'rooftop'):
            continue
        pp = geo.proj(a['p'])
        if len(pp) < 3:
            continue
        poly = Polygon(pp).buffer(0)
        c = poly.centroid
        if not inside_box(c.x, c.y, 20):
            continue
        hit = plots_hit(poly)
        near = poly.buffer(4)
        cut = unary_union([PAVE.intersection(near).buffer(0.5), NOGO.intersection(near).buffer(0.5)] + [PPOLY[i].buffer(0.8) for i in hit])
        free = poly.difference(cut)
        if free.is_empty:
            continue
        for g in getattr(free, 'geoms', [free]):
            if g.geom_type != 'Polygon' or g.area < 200:
                continue
            cx, cz, ax, az, L, W, _ = frame(g)
            loc = to_local(g, cx, cz, ax, az)
            lines_left = 60
            for k, (u0, u1, v0, v1) in enumerate(strips(loc, 8.0)):
                if u1 - u0 < 6:
                    continue
                mu, mv = (u0 + u1) / 2, (v0 + v1) / 2
                wx, wz = cx + mu * ax + mv * (-az), cz + mu * az + mv * ax
                it = Item('parking', wx, wz, yaw_x(ax, az), 'M', (u1 - u0) / 2 - 0.5, (v1 - v0) / 2 - 0.5)
                it.box((u1 - u0, 1.2, v1 - v0), (0, 0.15 - 0.6, 0), 'asphalt')
                # bays: rows 0 and 2 of every 3 strips, white lines across the strip every 4.2
                row = int(round((v0 - loc.bounds[1]) / 8.0)) % 3
                if row != 1 and v1 - v0 > 7.5 and lines_left > 0:
                    u = u0 + 1.0
                    while u < u1 - 1.0 and lines_left > 0:
                        it.box((0.22, 0.1, 6.8), (u - mu, 0.15 + 0.08 - 0.05, 0), 'line')
                        u += 4.2
                        lines_left -= 1
                        nl += 1
                keep(it)
    print('parking strips', len(ITEMS) - n0, 'bay lines', nl)


# ---------------------------------------------------------------- 3. places of worship
BIG_PAGODAS = ('shwedagon', 'kaba aye', 'kabar aye', 'kaba-aye', 'gabar aye', 'sule', 'botahtaung', 'chauk htat', 'chaukhtatgyi',
               'maha wizaya', 'mahawizaya', 'nga htat', 'ngahtatgyi', 'maha pasana', 'kyauk htat')
NOT_WORSHIP = ('co,', 'co.', 'ltd', 'company', 'mict')


def religion_of(name, tag):
    n = (name or '').lower()
    if any(k in n for k in ('church', 'baptist', 'cathedral', 'chapel', 'methodist', 'catholic', 'christ', 'holy cross', 'iglesia',
                            'cristo', 'judson', 'kingdom hall', 'jehovah', 'assembly of god', 'seminary', 'anglican', 'lutheran')):
        return 'christian'
    if any(k in n for k in ('mosque', 'moosqe', 'masjid', 'jamae', 'jami ', 'jama ')):
        return 'muslim'
    if any(k in n for k in ('hindu', 'sri ', 'kali', 'murugan', 'mariamman', 'shiva', 'vishnu', 'ganesh', 'krishna', 'devi ', 'amman')):
        return 'hindu'
    if 'chabad' in n or 'synagogue' in n:
        return 'jewish'
    if tag in ('christian', 'muslim', 'hindu', 'jewish'):
        return tag
    return 'buddhist'


def stupa(it, b, Hh, gilded, shrines, cx=0.0, cz=0.0):
    body = 'gold' if gilded else 'whitewash'

    def cyl(lo, hi, d, p):
        it.add('C', (d, hi - lo, d), (cx, (lo + hi) / 2, cz), p)
    it.span(-1.0, 0.08 * Hh, (b, b), (cx, cz), 'whitewash')
    it.span(0.08 * Hh, 0.14 * Hh, (0.78 * b, 0.78 * b), (cx, cz), 'whitewash')
    cyl(0.14 * Hh, 0.19 * Hh, 0.62 * b, 'whitewash')
    cyl(0.19 * Hh, 0.23 * Hh, 0.54 * b, body)
    cyl(0.23 * Hh, 0.26 * Hh, 0.48 * b, body)
    cyl(0.26 * Hh, 0.40 * Hh, 0.44 * b, body)
    it.add('S', (0.44 * b, 0.44 * b, 0.44 * b), (cx, 0.40 * Hh, cz), body)
    cyl(0.45 * Hh, 0.51 * Hh, 0.26 * b, body)
    cyl(0.51 * Hh, 0.56 * Hh, 0.22 * b, body)
    cyl(0.56 * Hh, 0.61 * Hh, 0.17 * b, 'gold')
    cyl(0.61 * Hh, 0.77 * Hh, 0.12 * b, 'gold')
    it.add('S', (0.12 * b, 0.12 * b, 0.12 * b), (cx, 0.77 * Hh, cz), 'gold')
    cyl(0.79 * Hh, 0.82 * Hh, 0.10 * b, 'gold')
    cyl(0.82 * Hh, 0.85 * Hh, 0.075 * b, 'gold')
    cyl(0.85 * Hh, 0.89 * Hh, 0.05 * b, 'gold')
    cyl(0.89 * Hh, 0.95 * Hh, 0.03 * b, 'gold')
    it.box((0.04 * b, 0.03 * Hh, 0.1 * b), (cx, 0.955 * Hh, cz), 'gold')
    it.add('S', (0.045 * b, 0.045 * b, 0.045 * b), (cx, 0.985 * Hh, cz), 'gold')
    if shrines:
        for su in (-1, 1):
            for sv in (-1, 1):
                x_, z_ = cx + su * 0.39 * b, cz + sv * 0.39 * b
                y0 = 0.08 * Hh
                it.add('C', (0.13 * b, 0.10 * Hh, 0.13 * b), (x_, y0 + 0.05 * Hh, z_), 'whitewash')
                it.add('S', (0.13 * b, 0.13 * b, 0.13 * b), (x_, y0 + 0.10 * Hh, z_), body)
                it.add('C', (0.03 * b, 0.07 * Hh, 0.03 * b), (x_, y0 + 0.15 * Hh, z_), 'gold')


def monastery(it):
    it.span(-1.0, 1.2, (22, 16), (0, 0), 'plinth')
    it.span(1.2, 7.6, (19, 13), (0, 0), 'cream')
    it.span(7.6, 8.6, (23.5, 17.5), (0, 0), 'teak')
    it.span(8.6, 9.8, (14, 9), (0, 0), 'teak_dark')
    it.span(9.8, 10.7, (16.5, 11.5), (0, 0), 'teak')
    it.span(10.7, 11.8, (9, 6), (0, 0), 'teak_dark')
    it.span(11.8, 12.6, (10.5, 7.5), (0, 0), 'teak')
    it.add('C', (0.7, 3.4, 0.7), (0, 14.3, 0), 'gold')
    it.box((3.2, 4.6, 0.2), (0, 3.5, -6.6), 'door')


def church(it):
    it.span(-1.0, 9.0, (12, 20), (0, 0), 'whitewash')
    for sg in (-1, 1):
        it.add('W', (21.0, 4.2, 6.5), (sg * 3.25, 11.1, 0), 'roof_red', -sg * math.pi / 2)
    it.span(-1.0, 15.0, (5, 5), (0, -11.2), 'whitewash')
    it.span(15.0, 15.6, (5.8, 5.8), (0, -11.2), 'roof_red')
    it.span(15.6, 19.0, (0.5, 0.5), (0, -11.2), 'gold')
    it.box((2.2, 0.5, 0.5), (0, 18.0, -11.2), 'gold')
    it.box((2.4, 4.4, 0.2), (0, 2.2, -13.8), 'door')


def mosque(it, r):
    wall = r.choice(['whitewash', 'cream'])
    dome = r.choice(['mosque_green', 'gold', 'whitewash'])
    it.span(-1.0, 8.0, (14, 16), (0, 0), wall)
    it.add('C', (8.8, 1.2, 8.8), (0, 8.6, 0), wall)
    it.add('S', (8.4, 8.4, 8.4), (0, 9.2, 0), dome)
    it.add('C', (0.3, 2.2, 0.3), (0, 14.4, 0), 'gold')
    it.add('C', (2.2, 21.0, 2.2), (7.4, 9.5, -8.4), wall)
    it.add('C', (3.2, 0.6, 3.2), (7.4, 15.2, -8.4), dome)
    it.add('S', (2.2, 2.2, 2.2), (7.4, 20.0, -8.4), dome)
    it.add('C', (0.25, 2.4, 0.25), (7.4, 22.2, -8.4), 'gold')
    it.box((3.0, 5.0, 0.2), (0, 2.5, -8.1), 'door')


def hindu(it, r):
    it.span(-1.0, 6.0, (10, 12), (0, 2), 'cream')
    sizes = [(9.0, 4.6), (7.8, 4.0), (6.6, 3.5), (5.4, 3.0), (4.2, 2.5)]
    y = -1.0
    for k, (w, d) in enumerate(sizes):
        h = 3.6 if k == 0 else 2.2
        it.span(y, y + h, (w, d), (0, -5.2), 'gop%d' % ((k + H('h', k)) % 5))
        y += h
    it.add('H', (4.6, 1.6, 1.6), (0, y + 0.6, -5.2), 'gop%d' % r.randrange(5))
    for du in (-1.4, 0, 1.4):
        it.add('C', (0.5, 1.4, 0.5), (du, y + 2.0, -5.2), 'gold')
    it.span(6.0, 9.0, (5, 5), (0, 3), 'gop1')
    it.add('C', (3.0, 3.0, 3.0), (0, 10.5, 3), 'gop0')
    it.box((2.2, 3.4, 0.2), (0, 1.7, -7.6), 'door')


FOOT = {'stupa_big': (14 + 2, 14 + 2), 'stupa': (9, 9), 'monastery': (24, 18), 'christian': (13, 28), 'muslim': (18, 20), 'hindu': (11, 15)}


def find_spot(x, z, w, d, yaw0=None, reach=50, inside=None):
    for rad in range(0, reach + 1, 3):
        n = 1 if rad == 0 else max(6, int(rad * 0.7))
        for k in range(n):
            a = 2 * math.pi * k / n
            px, pz = x + rad * math.cos(a), z + rad * math.sin(a)
            if not inside_box(px, pz, 20):
                continue
            if inside is not None and not inside.contains(Point(px, pz)):
                continue
            yaw = yaw0 if yaw0 is not None else 0.0
            c, s = math.cos(yaw), math.sin(yaw)
            fp = Polygon([(px + u * c + v * s, pz - u * s + v * c) for u, v in ((-w / 2, -d / 2), (w / 2, -d / 2), (w / 2, d / 2), (-w / 2, d / 2))])
            if clear(fp, pave=True) and occ_free(px, pz, max(w, d) / 2):
                return px, pz, yaw
    return None


def worship():
    n0 = len(ITEMS)
    places = []
    bl = [b for b in geo.load('buildings') if b['t'].get('amenity') == 'place_of_worship' or b['t'].get('religion')]
    bpolys = []
    for b in bl:
        pp = geo.proj(b['p'])
        if len(pp) >= 3:
            bpolys.append((Polygon(pp).buffer(0), b['t']))
    for a in geo.load('areas'):
        t = a['t']
        if t.get('amenity') in ('place_of_worship', 'monastery') or (t.get('landuse') == 'religious' and t.get('name')):
            pp = geo.proj(a['p'])
            if len(pp) >= 3:
                poly = Polygon(pp).buffer(0)
                c = poly.centroid
                if inside_box(c.x, c.y):
                    places.append({'x': c.x, 'z': c.y, 'name': t.get('name:en') or t.get('name'), 'rel': t.get('religion'),
                                   'area': poly, 'mon': t.get('amenity') == 'monastery', 'id': a['id']})
    for p in geo.load('points'):
        if p['v'] != 'place_of_worship':
            continue
        x, z = geo.world(*p['p'])
        if not inside_box(x, z):
            continue
        if any(q.get('area') is not None and q['area'].buffer(5).contains(Point(x, z)) for q in places):
            continue
        rel = None
        for bp, bt in bpolys:
            if bp.buffer(3).contains(Point(x, z)):
                rel = bt.get('religion')
                break
        places.append({'x': x, 'z': z, 'name': p['name'], 'rel': rel, 'area': None, 'mon': False, 'id': p['id']})
    cnt = {}

    def note(k):
        cnt[k] = cnt.get(k, 0) + 1
    for pl in places:
        name = pl['name'] or ''
        low = name.lower()
        if any(k in low for k in BIG_PAGODAS):
            note('landmark pagoda (not ours)')
            continue
        if BLK.contains(Point(pl['x'], pl['z'])):
            note('in a landmark / venue lot')
            continue
        if any(k in low for k in NOT_WORSHIP):
            note('not a place of worship (a company / office)')
            continue
        pt = Point(pl['x'], pl['z'])
        in_plot = len(PTREE.query(pt.buffer(1.5), predicate='intersects')) > 0
        zedi = any(k in low for k in ('pagoda', 'zedi', 'stupa', 'paya', 'ceti', 'cetiya')) or 'စေတီ' in name
        if in_plot and pl['area'] is None and not zedi:
            note('the building itself (a plot)')
            continue
        rel = religion_of(name, pl['rel'])
        if rel == 'jewish':
            note('jewish (no symbol made)')
            continue
        r = R('worship', pl['id'])
        named = bool(ascii_name(name, None)) or bool(name)
        if rel == 'buddhist':
            mon = pl['mon'] or any(k in low for k in ('monast', 'kyaung', 'temple', 'meditation', 'sasana', 'dhamma', 'vihara',
                                                      'yeiktha', 'yeik thar', 'nunnery', 'monestry')) or 'ကျောင်း' in name
            kind = 'monastery' if mon and not zedi else ('stupa_big' if named or (pl['area'] is not None and pl['area'].area > 1500) else 'stupa')
        else:
            kind = rel
        w, d = FOOT[kind]
        inside = pl['area'].buffer(4) if pl['area'] is not None else None
        # face the nearest road (the front, local -Z)
        q = nearest_points(PAVE, pt)[0]
        yaw = yaw_face(*unit(q.x - pt.x, q.y - pt.y))
        spot = find_spot(pl['x'], pl['z'], w + 1, d + 1, yaw0=yaw, inside=inside) or (
            find_spot(pl['x'], pl['z'], w + 1, d + 1, yaw0=yaw) if inside is not None else None)
        if not spot:
            note('no free ground near it')
            continue
        x, z, yaw = spot
        it = Item('worship', x, z, yaw, 'M', w / 2 - 1, d / 2 - 1, name=ascii_name(name, None))
        if kind == 'stupa_big':
            stupa(it, 14.0, 34.0, r.random() < 0.55, True)
        elif kind == 'stupa':
            stupa(it, 8.0, 19.0, r.random() < 0.35, False)
        elif kind == 'monastery':
            monastery(it)
        elif kind == 'christian':
            church(it)
        elif kind == 'muslim':
            mosque(it, r)
        else:
            hindu(it, r)
        keep(it)
        occ_add(x, z, max(w, d) / 2)
        note(kind)
        if kind == 'monastery':
            c, s = math.cos(yaw), math.sin(yaw)
            for side in (1, -1):
                sx_, sz_ = x + side * 18 * c, z - side * 18 * s
                sp = find_spot(sx_, sz_, 9, 9, yaw0=yaw, reach=6)
                if sp:
                    it2 = Item('worship', sp[0], sp[1], yaw, 'M', 3.5, 3.5)
                    stupa(it2, 8.0, 19.0, True, False)
                    keep(it2)
                    occ_add(sp[0], sp[1], 4.5)
                    note('stupa (by a monastery)')
                    break
    print('worship', cnt, len(ITEMS) - n0, 'items')


# ---------------------------------------------------------------- road frames
def rd_at(rd, x, z):
    """station s, the point on the centreline, unit tangent, signed side (+1 = left of the line's direction)"""
    ln = rd['line']
    s = ln.project(Point(x, z))
    p = ln.interpolate(s)
    q = ln.interpolate(min(ln.length, s + 1.0))
    o = ln.interpolate(max(0.0, s - 1.0))
    tx, tz = unit(q.x - o.x, q.y - o.y)
    side = 1 if (tx * (z - p.y) - tz * (x - p.x)) > 0 else -1
    return s, (p.x, p.y), (tx, tz), side


def rd_point(rd, s):
    ln = rd['line']
    s = max(0.0, min(ln.length, s))
    p = ln.interpolate(s)
    q = ln.interpolate(min(ln.length, s + 1.0))
    o = ln.interpolate(max(0.0, s - 1.0))
    return (p.x, p.y), unit(q.x - o.x, q.y - o.y)


def nearest_rd(x, z, reach=60, pred=None):
    best = None
    for i in RD_TREE.query(Point(x, z).buffer(reach)):
        rd = RD[int(i)]
        if pred and not pred(rd):
            continue
        d = rd['line'].distance(Point(x, z))
        if best is None or d < best[0]:
            best = (d, rd)
    return best


def lateral(c, t, side, off):
    """the point `off` from the centreline point c on `side` (+1 = left normal (-tz, tx))"""
    return (c[0] - t[1] * off * side, c[1] + t[0] * off * side)


# ---------------------------------------------------------------- 6. footbridges (first: they pick their spot)
def footbridges():
    """the pedestrian overpasses on their real OSM lines. The game's roads are wider than the real ones (and a divided road
    is two carriageways), so the deck runs along the real line until both landings stand clear of every carriageway;
    the stairs go down along the pavement either way or straight on, whichever is clear of roads and buildings."""
    n0 = len(ITEMS)
    bad_ends = 0
    CLEAR = 18.0
    DT = CLEAR + 1.2
    for r in geo.load('roads'):
        t = r['t']
        if not (t.get('bridge') and t.get('highway') in ('footway', 'path', 'pedestrian', 'steps', 'cycleway')):
            continue
        pp = geo.proj(r['p'])
        if not any(inside_box(x, z) for x, z in pp):
            continue
        ls = LineString(pp)
        (ax, az), (bx, bz) = pp[0], pp[-1]
        ux, uz = unit(bx - ax, bz - az)
        mid = ls.interpolate(0.5, normalized=True)
        ts = np.arange(-110.0, 110.01, 0.5)
        inside = shapely.contains_xy(CARR, mid.x + ux * ts, mid.y + uz * ts)
        # carriageway intervals along the line, then the cluster round the middle (gaps under 26: medians, pavements)
        ivs = []
        k = 0
        while k < len(ts):
            if inside[k]:
                j = k
                while j + 1 < len(ts) and inside[j + 1]:
                    j += 1
                ivs.append([ts[k], ts[j]])
                k = j + 1
            else:
                k += 1
        if not ivs or min(min(abs(a), abs(b)) if a * b > 0 else 0 for a, b in ivs) > 30:
            L = ls.length
            it = Item('footbridge', mid.x, mid.y, yaw_x(ux, uz), 'M', L / 2, 1.5, name='footbridge (no road)')
            it.box((L + 2, 0.8, 4.0), (0, 1.0, 0), 'concrete')
            for sg in (-1, 1):
                it.box((L + 2, 0.25, 0.25), (0, 4.2, sg * 1.9), 'steel')
                for k in range(int(L // 5) + 2):
                    it.add('C', (0.2, 2.8, 0.2), (-L / 2 - 1 + k * (L + 2) / (int(L // 5) + 1), 2.8, sg * 1.9), 'steel')
            keep(it)
            continue
        main = min(range(len(ivs)), key=lambda i: 0 if ivs[i][0] <= 0 <= ivs[i][1] else min(abs(ivs[i][0]), abs(ivs[i][1])))
        lo_i = hi_i = main
        while lo_i > 0 and ivs[lo_i][0] - ivs[lo_i - 1][1] < 26:
            lo_i -= 1
        while hi_i < len(ivs) - 1 and ivs[hi_i + 1][0] - ivs[hi_i][1] < 26:
            hi_i += 1
        tmin, tmax = ivs[lo_i][0], ivs[hi_i][1]
        t0 = (ivs[main][0] + ivs[main][1]) / 2
        cx0, cz0 = mid.x + ux * t0, mid.y + uz * t0
        nb = nearest_rd(cx0, cz0, 80)
        walk = nb[1]['walk'] if nb else 4.0
        wst = min(4.5, max(2.6, walk - 1.0))
        wl = wst + 0.8
        run = (DT + 1.4) / 0.74
        it = Item('footbridge', cx0, cz0, yaw_x(ux, uz), 'G', 0, 0, name=ascii_name(t.get('name:en') or t.get('name'), 'footbridge'))
        it.yh = yhint(cx0, cz0)
        ends = []
        for end in (-1, 1):
            edge = (tmin if end < 0 else tmax) - t0
            found = None
            for push in np.arange(wl / 2 + 0.6, wl / 2 + 16, 1.0):
                xl = edge + end * push
                land = Polygon([it.world(xl + du, dv) for du, dv in ((-wl / 2, -wl / 2), (wl / 2, -wl / 2), (wl / 2, wl / 2), (-wl / 2, wl / 2))])
                if CARR.intersects(land) or plots_hit(land) or WATER.intersects(land):
                    continue
                for opt in ('z+', 'z-', 'x'):
                    if opt == 'x':
                        x0, x1 = xl + end * wl / 2, xl + end * (wl / 2 + run)
                        corners = ((x0, -wst / 2), (x1, -wst / 2), (x1, wst / 2), (x0, wst / 2))
                    else:
                        dz_ = 1 if opt == 'z+' else -1
                        z0, z1 = dz_ * wl / 2, dz_ * (wl / 2 + run)
                        corners = ((xl - wst / 2, z0), (xl + wst / 2, z0), (xl + wst / 2, z1), (xl - wst / 2, z1))
                    fp = Polygon([it.world(u, v) for u, v in corners])
                    if not CARR.intersects(fp) and not plots_hit(fp) and not WATER.intersects(fp):
                        found = (xl, opt)
                        break
                if found:
                    break
            if not found:
                bad_ends += 1
            ends.append(found)
        if not all(ends):
            print('  footbridge %s: no clear landing for its stairs, left out' % r['id'])
            continue
        xa, xb = ends[0][0] + wl / 2, ends[1][0] - wl / 2
        span = xb - xa
        xm = (xa + xb) / 2
        wd = 5.0
        it.box((span, 1.2, wd), (xm, CLEAR + 0.6, 0), 'concrete')
        for sg in (-1, 1):
            it.box((span, 2.4, 0.3), (xm, CLEAR + 1.2, sg * (wd / 2 + 0.15)), 'ybs_blue')
            it.box((span + 2 * wl, 0.3, 0.3), (xm, DT + 3.2, sg * (wd / 2 + 0.1)), 'steel')
            n = int(span // 6) + 1
            for k in range(n + 1):
                it.add('C', (0.22, 3.0, 0.22), (xa + span * k / n, DT + 1.6, sg * (wd / 2 + 0.1)), 'steel')
        frac = (DT - 0.5) / (DT + 1.4)
        for end, (xl, opt) in zip((-1, 1), ends):
            it.box((wl, 1.2, wl), (xl, CLEAR + 0.6, 0), 'concrete')
            if opt == 'x':
                xc = xl + end * (wl / 2 + run / 2)
                it.add('W', (wst, DT + 1.4, run), (xc, (DT - 1.4) / 2, 0), 'concrete', -end * math.pi / 2)
                for sg in (-1, 1):
                    it.rod((xl + end * wl / 2, DT + 3.2, sg * (wst / 2 - 0.1)), (xl + end * (wl / 2 + run * frac), 3.7, sg * (wst / 2 - 0.1)), 0.25, 'steel')
                foot = (xc, 0)
            else:
                dz_ = 1 if opt == 'z+' else -1
                zc = dz_ * (wl / 2 + run / 2)
                # wedge: high side at its +Z; for stairs running to +Z the high end must be at -Z: turn it round
                it.add('W', (wst, DT + 1.4, run), (xl, (DT - 1.4) / 2, zc), 'concrete', 0.0 if dz_ < 0 else math.pi)
                for sg in (-1, 1):
                    it.rod((xl + sg * (wst / 2 - 0.1), DT + 3.2, dz_ * wl / 2), (xl + sg * (wst / 2 - 0.1), 3.7, dz_ * (wl / 2 + run * frac)), 0.25, 'steel')
                foot = (xl, zc)
            for cz_ in (-wl / 2 + 0.6, wl / 2 - 0.6):
                it.span(-1.5, CLEAR, (0.9, 0.9), (xl, cz_), 'concrete')
            occ_add(*it.world(xl, 0), 3.5)
            occ_add(*it.world(*foot), 4.0)
        it.clearance = CLEAR
        keep(it)
    print('footbridges', len(ITEMS) - n0, 'stair ends with no clear way', bad_ends)


# ---------------------------------------------------------------- 4. signals, bus stops, trees, gates
def signals():
    n0 = len(ITEMS)
    nodes = [geo.world(*p['p']) for p in geo.load('points') if p['k'] == 'highway' and p['v'] == 'traffic_signals']
    nodes = [(x, z) for x, z in nodes if inside_box(x, z)]
    clusters = []
    for x, z in nodes:
        for c in clusters:
            if math.hypot(c[0] - x, c[1] - z) < 40:
                c[2].append((x, z))
                c[0] = sum(q[0] for q in c[2]) / len(c[2])
                c[1] = sum(q[1] for q in c[2]) / len(c[2])
                break
        else:
            clusters.append([x, z, [(x, z)]])
    used = 0
    for ci, (x, z, _) in enumerate(clusters):
        if DECK_ZONE.contains(Point(x, z)) or RING_ZONE.contains(Point(x, z)):
            continue
        near = []
        for i in RD_TREE.query(Point(x, z).buffer(60)):
            rd = RD[int(i)]
            if rd['src'] != 'game':
                continue
            if rd['line'].distance(Point(x, z)) <= rd['half'] + 14:
                near.append(rd)
        if not near:
            continue
        used += 1
        for k, rd in enumerate(near):
            others = [o['half'] for o in near if o is not rd]
            gap = (max(others) if others else 0) + 9
            s0, c0, t0, _ = rd_at(rd, x, z)
            lit = 'G' if k % 2 == 0 else 'R'
            for dirn in (1, -1):
                placed = False
                for extra in (0, 4, 8, 12, 16):
                    sa = s0 - dirn * (gap + extra)
                    if sa < 2 or sa > rd['line'].length - 2:
                        break
                    c, t = rd_point(rd, sa)
                    vx, vz = t[0] * dirn, t[1] * dirn
                    rx_, rz_ = -vz, vx  # right of travel (Myanmar drives on the right)
                    px, pz = c[0] + rx_ * (rd['half'] + 1.6), c[1] + rz_ * (rd['half'] + 1.6)
                    if CARR.intersects(Point(px, pz).buffer(0.6)) or plots_hit(Point(px, pz).buffer(0.6)) or not occ_free(px, pz, 1.2):
                        continue
                    it = Item('signal', px, pz, yaw_face(-vx, -vz), 'G')
                    arm = min(rd['half'] - 4, 18.0)
                    it.add('C', (0.6, 22.5, 0.6), (0, 10.25, 0), 'darksteel')
                    it.box((arm + 0.6, 0.45, 0.45), (arm / 2, 20.6, 0), 'darksteel')
                    it.box((1.4, 3.6, 1.0), (arm, 18.6, 0), 'black')
                    for j, (yy, on, off) in enumerate(((19.75, 'lamp_red', 'lamp_off_r'), (18.6, None, 'lamp_off_a'), (17.45, 'lamp_green', 'lamp_off_g'))):
                        p = on if (on and ((lit == 'R' and j == 0) or (lit == 'G' and j == 2))) else off
                        it.add('S', (0.9, 0.9, 0.9), (arm, yy, -0.55), p)
                    it.yh = yhint(px, pz)
                    keep(it)
                    occ_add(px, pz, 3.0)
                    placed = True
                    break
    print('signals', len(ITEMS) - n0, 'at', used, 'junctions of', len(clusters))


def bus_stops():
    n0, poles = len(ITEMS), 0
    for p in geo.load('points'):
        if p['v'] != 'bus_stop':
            continue
        x, z = geo.world(*p['p'])
        if not inside_box(x, z):
            continue
        nb = nearest_rd(x, z, 40)
        if not nb:
            continue
        d, rd = nb
        if d > rd['half'] + rd['walk'] + 25:
            continue
        s0, c0, t0, side = rd_at(rd, x, z)
        half, walk = rd['half'], rd['walk']
        name = ascii_name(p['name'], 'Bus Stop')
        done = False
        for ds in (0, 8, -8, 16, -16, 24, -24, 32, -32):
            c, t = rd_point(rd, s0 + ds)
            if walk >= 6:
                D, Ls = 3.6, 11.0
                off = half + 1.2 + D / 2 + 0.8
            else:
                D, Ls = min(3.0, walk + 1.6), 9.0
                off = half + 0.6 + D / 2
            px, pz = lateral(c, t, side, off)
            fx, fz = unit(c[0] - px, c[1] - pz)
            it = Item('busstop', px, pz, yaw_face(fx, fz), 'G', name=name)
            fp = Polygon([it.world(u, v) for u, v in ((-Ls / 2 - 1.6, -D / 2), (Ls / 2 + 1.6, -D / 2), (Ls / 2 + 1.6, D / 2), (-Ls / 2 - 1.6, D / 2))])
            if CARR.intersects(fp) or plots_hit(fp) or WATER.intersects(fp) or not occ_free(px, pz, 4.0):
                continue
            # posts, roof, back panel, bench, sign pole (YBS-style: blue frame, white panel)
            for u in (-Ls / 2 + 0.4, Ls / 2 - 0.4):
                for v in (-D / 2 + 0.3, D / 2 - 0.3):
                    it.add('C', (0.3, 8.6, 0.3), (u, 3.3, v), 'ybs_blue')
            it.box((Ls + 0.6, 0.35, D + 0.6), (0, 7.75, -0.15), 'ybs_blue')
            it.box((Ls - 0.8, 4.2, 0.15), (0, 4.9, D / 2 - 0.3), 'ybs_panel')
            it.box((Ls * 0.6, 0.25, 1.1), (0, 1.7, D / 2 - 1.0), 'bench')
            it.box((Ls * 0.6 - 0.6, 1.6, 0.3), (0, 0.8, D / 2 - 0.9), 'darksteel')
            it.add('C', (0.2, 10.0, 0.2), (Ls / 2 + 1.2, 4.0, -D / 2 + 1.6), 'darksteel')
            it.add('B', (2.6, 1.7, 0.12), (Ls / 2 + 1.2, 8.0, -D / 2 + 1.6), 'ybs_panel', math.pi / 2, text=('k', 'YBS  ' + name))
            it.street = rd['src'] == 'street'
            it.yh = yhint(px, pz)
            keep(it)
            occ_add(px, pz, 7.0)
            done = True
            break
        if not done:
            c, t = rd_point(rd, s0)
            px, pz = lateral(c, t, side, half + min(walk - 0.6, 1.4))
            if not CARR.intersects(Point(px, pz).buffer(0.5)) and occ_free(px, pz, 1.0):
                fx, fz = unit(c[0] - px, c[1] - pz)
                it = Item('busstop', px, pz, yaw_face(fx, fz), 'G', name=name)
                it.add('C', (0.2, 10.0, 0.2), (0, 4.0, 0), 'darksteel')
                it.add('B', (2.8, 1.7, 0.12), (0, 8.0, 0), 'ybs_panel', math.pi / 2, text=('k', 'YBS  ' + name))
                it.street = rd['src'] == 'street'
                it.yh = yhint(px, pz)
                keep(it)
                occ_add(px, pz, 2.0)
                poles += 1
    print('bus stops', len(ITEMS) - n0, '(of them sign poles only:', poles, ')')


def osm_trees():
    n0 = len(ITEMS)
    for p in geo.load('points'):
        if p['v'] != 'tree':
            continue
        x, z = geo.world(*p['p'])
        if not inside_box(x, z):
            continue
        for dx, dz in ((0, 0), (3, 0), (-3, 0), (0, 3), (0, -3), (5, 5), (-5, -5), (5, -5), (-5, 5)):
            g = Point(x + dx, z + dz).buffer(1.4)
            if clear(g, nogo=True) and occ_free(x + dx, z + dz, 1.4):
                it = Item('tree', x + dx, z + dz, R('tree', p['id']).uniform(0, 2 * math.pi), 'G')
                it.kits.append(('Tree', round(R('treew', p['id']).uniform(22, 30), 1), 0))
                it.yh = yhint(x, z)
                keep(it)
                occ_add(x + dx, z + dz, 2.0)
                break
    print('trees', len(ITEMS) - n0)


# OSM ways (every highway) for the gates' direction and the driveways that cut a compound wall
OSMW = []
for _r in geo.load('roads'):
    _pp = geo.proj(_r['p'])
    if len(_pp) >= 2 and any(X0 - 50 < x < X1 + 50 and Z0 - 50 < z < Z1 + 50 for x, z in _pp):
        OSMW.append((LineString(_pp), _r['t'].get('highway')))
OSMW_TREE = STRtree([w[0] for w in OSMW])
GATES = []  # [x, z, ax, az (panel direction), width, id, snapped]


def gate_specs():
    for p in geo.load('points'):
        if p['v'] != 'gate':
            continue
        x, z = geo.world(*p['p'])
        if not inside_box(x, z):
            continue
        best = None
        for i in OSMW_TREE.query(Point(x, z).buffer(4)):
            ln, hw = OSMW[int(i)]
            d = ln.distance(Point(x, z))
            if best is None or d < best[0]:
                best = (d, ln, hw)
        if best and best[0] < 4:
            ln, hw = best[1], best[2]
            s = ln.project(Point(x, z))
            a, b = ln.interpolate(max(0, s - 1)), ln.interpolate(min(ln.length, s + 1))
            tx, tz = unit(b.x - a.x, b.y - a.y)
            ax, az = -tz, tx  # the panel spans across the way
            w = 5.0 if hw in ('footway', 'path', 'steps', 'pedestrian', 'cycleway') else 10.0
        else:
            nb = nearest_rd(x, z, 80)
            if nb:
                _, c, t, _ = rd_at(nb[1], x, z)
                ax, az = t
            else:
                ax, az = 1.0, 0.0
            w = 8.0
        GATES.append([x, z, ax, az, w, p['id'], False])


def gate_item(x, z, ax, az, w, seed):
    r = R('gate', seed)
    it = Item('gate', x, z, yaw_x(ax, az), 'M', w / 2 + 1.4, 0.6)
    col = r.choice(['gateplate', 'gateplate', 'darksteel', 'ybs_blue', 'fence_green'])
    wall = 'wall%d' % r.randrange(len(WALL_COLS))
    for sg in (-1, 1):
        it.span(-1.0, 6.4, (1.4, 1.4), (sg * (w / 2 + 0.7), 0), wall)
    it.span(0.3, 2.9, (w, 0.2), (0, 0), col)
    it.box((w, 0.25, 0.25), (0, 2.9, 0), 'darksteel')
    it.box((w, 0.25, 0.25), (0, 5.0, 0), 'darksteel')
    n = max(2, int(round(w / 2.5)))
    for k in range(n):
        it.box((0.15, 2.1, 0.15), (-w / 2 + w * (k + 0.5) / n, 3.95, 0), 'darksteel')
    return it


def gates_out():
    n0 = len(ITEMS)
    for x, z, ax, az, w, gid, snapped in GATES:
        it = gate_item(x, z, ax, az, w, gid)
        ok = None
        for k in range(0, 21, 2):
            for sg in ((1, -1) if k else (1,)):
                # slide along the way (perpendicular to the panel) until clear of carriageways and buildings
                px, pz = x + (-az) * k * sg, z + ax * k * sg
                it.x, it.z = px, pz
                fp = unary_union([it.part_geo(q)[0] for q in it.parts])
                if not CARR.intersects(fp) and not plots_hit(fp) and not WATER.intersects(fp):
                    ok = (px, pz)
                    break
            if ok:
                break
        if not ok:
            continue
        it.yh = yhint(*ok)
        keep(it)
        occ_add(ok[0], ok[1], w / 2 + 1.5)
    print('gates', len(ITEMS) - n0, 'of', len(GATES))


# ---------------------------------------------------------------- 5. walls
def wall_piece(kind, a, b, colour, pillar_us, height=5.0, low=False):
    """an item: a straight wall from a to b; pillars at the given distances from a"""
    dx, dz = b[0] - a[0], b[1] - a[1]
    E = math.hypot(dx, dz)
    if E < 0.8:
        return None
    it = Item(kind, (a[0] + b[0]) / 2, (a[1] + b[1]) / 2, yaw_x(dx / E, dz / E), 'G', E / 2, 0)
    if kind == 'hedge':
        it.span(-0.8, 3.4, (E, 2.0), (0, 0), 'hedge')
        return it
    if kind == 'fence':
        it.span(-1.4, 2.0, (E, 0.8), (0, 0), colour)
        it.span(2.0, 2.25, (E + 0.1, 1.0), (0, 0), 'coping')
        it.box((E, 0.18, 0.18), (0, 5.4, 0), 'darksteel')
        n = max(1, int(E / 2.0))
        for k in range(n):
            it.box((0.14, 3.2, 0.14), (-E / 2 + E * (k + 0.5) / n, 3.8, 0), 'darksteel')
        for u in pillar_us:
            it.span(-1.4, 5.8, (1.2, 1.2), (u - E / 2, 0), colour)
        return it
    it.span(-1.4, height, (E, 0.8), (0, 0), colour)
    it.span(height, height + 0.3, (E + 0.05, 1.0), (0, 0), 'coping')
    for u in pillar_us:
        it.span(-1.4, height + 0.6, (1.3, 1.3), (u - E / 2, 0), colour)
    return it


def run_pieces(kind, pts, colour, max_len=32.0, pillar_every=16.0):
    """walls along a polyline: pieces <= max_len, pillars every pillar_every and at both ends"""
    out = []
    total = 0.0
    next_p = 0.0
    segs = []
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        E = math.dist(a, b)
        n = max(1, int(math.ceil(E / max_len)))
        for k in range(n):
            segs.append(((a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n),
                         (a[0] + (b[0] - a[0]) * (k + 1) / n, a[1] + (b[1] - a[1]) * (k + 1) / n)))
    for j, (a, b) in enumerate(segs):
        E = math.dist(a, b)
        us = []
        while next_p <= total + E + 1e-6:
            us.append(next_p - total)
            next_p += pillar_every
        if j == len(segs) - 1 and (not us or E - us[-1] > 3):
            us.append(E)
        it = wall_piece(kind, a, b, colour, us)
        if it:
            out.append(it)
        total += E
    return out


OSM_WALL_LINES = []


def osm_walls():
    n0 = len(ITEMS)
    nogo = unary_union([PAVE, NOGO])
    shapely.prepare(nogo)
    for l in geo.load('lines'):
        bt = l['t'].get('barrier')
        if bt not in ('wall', 'fence', 'hedge', 'retaining_wall', 'city_wall'):
            continue
        pp = geo.proj(l['p'])
        if len(pp) < 2 or not any(inside_box(x, z) for x, z in pp):
            continue
        ls = LineString(pp)
        OSM_WALL_LINES.append(ls)
        hit = plots_hit(ls.buffer(2))
        cut = unary_union([nogo.intersection(ls.buffer(3))] + [PPOLY[i].buffer(0.9) for i in hit])
        rest = ls.difference(cut)
        kind = {'fence': 'fence', 'hedge': 'hedge'}.get(bt, 'wall')
        colour = 'wall%d' % (H('w', l['id']) % len(WALL_COLS))
        for g in getattr(rest, 'geoms', [rest]):
            if g.geom_type != 'LineString' or g.length < 3:
                continue
            for it in run_pieces(kind, list(g.coords), colour):
                keep(it)
    print('OSM walls / fences / hedges', len(ITEMS) - n0, 'pieces')


QUAL_KIND = {'school', 'hospital', 'hall', 'monastery', 'church', 'temple'}
QUAL_STYLE = {'villa', 'house'}
YARD = 5.5     # studs of yard between the wall line and the building
MIN_RUN = 8    # stations (2 studs each): runs shorter than 16 studs are left open
GAP_BRIDGE = 12  # stations: open yard gaps up to 24 studs between walled houses are walled too


def compound_walls():
    t0 = __import__('time').time()
    n0 = len(ITEMS)
    STEP = 2.0
    E, P2, META = [], [], []
    for ri, rd in enumerate(RD):
        ln = rd['line']
        L = ln.length
        if L < 8:
            continue
        n = int(L // STEP)
        ss = np.linspace(1.0, L - 1.0, max(2, n))
        pts = shapely.line_interpolate_point(ln, ss)
        pa = shapely.line_interpolate_point(ln, np.maximum(ss - 1, 0))
        pb = shapely.line_interpolate_point(ln, np.minimum(ss + 1, L))
        cx, cz = shapely.get_x(pts), shapely.get_y(pts)
        tx, tz = shapely.get_x(pb) - shapely.get_x(pa), shapely.get_y(pb) - shapely.get_y(pa)
        tl = np.hypot(tx, tz) + 1e-9
        tx, tz = tx / tl, tz / tl
        off = rd['half'] + rd['walk'] + 0.6
        for side in (1, -1):
            ex, ez = cx - tz * off * side, cz + tx * off * side
            E.append(np.stack([ex, ez], 1))
            P2.append(np.stack([ex - tz * 40 * side, ez + tx * 40 * side], 1))
            META += [(ri, side, k, tx[k], tz[k]) for k in range(len(ss))]
    E = np.concatenate(E)
    P2 = np.concatenate(P2)
    N = len(E)
    ok = ~shapely.contains_xy(PAVE, E[:, 0], E[:, 1])
    ok &= ~shapely.contains_xy(NOGO, E[:, 0], E[:, 1])
    ok &= (E[:, 0] > X0 + 10) & (E[:, 0] < X1 - 10) & (E[:, 1] > Z0 + 10) & (E[:, 1] < Z1 - 10)
    epts = shapely.points(E)
    if OSM_WALL_LINES:
        wt = STRtree(OSM_WALL_LINES)
        near = wt.query(epts, predicate='dwithin', distance=3.0)
        ok[np.unique(near[0])] = False
    probes = shapely.linestrings(np.stack([E, P2], 1))
    pairs = PTREE.query(probes, predicate='intersects')
    dist = shapely.distance(epts[pairs[0]], np.array(PPOLY, dtype=object)[pairs[1]])
    owner = np.full(N, -1)
    od = np.full(N, 1e9)
    for pi, qi, d in zip(pairs[0], pairs[1], dist):
        if d < od[pi]:
            od[pi], owner[pi] = d, qi
    qual = np.array([(p.get('kind') in QUAL_KIND or p.get('style') in QUAL_STYLE) for p in PLOTS])
    acc = ok & (owner >= 0) & (od >= YARD)
    acc &= np.where(owner >= 0, qual[np.maximum(owner, 0)], False)
    # a compound wall runs on across the open yard between two walled houses (no building behind, nothing in the way):
    # gaps of up to GAP_BRIDGE stations of one street side are closed
    bridged = 0
    i = 0
    while i < N - 1:
        if acc[i] and not acc[i + 1]:
            key = META[i][:2]
            j = i + 1
            while j < N and j - i - 1 <= GAP_BRIDGE and META[j][:2] == key and not acc[j] and ok[j] and owner[j] < 0:
                j += 1
            if j < N and j - i - 1 <= GAP_BRIDGE and META[j][:2] == key and acc[j] and META[j][2] - META[i][2] == j - i:
                for q in range(i + 1, j):
                    acc[q], owner[q] = True, owner[i]
                    bridged += 1
                i = j
                continue
        i += 1
    print('compound walls: %d open stations bridged' % bridged)
    # driveways: OSM ways that cross the wall line (not the street itself)
    print('compound walls: %d stations, %d accepted (%.1f s)' % (N, int(acc.sum()), __import__('time').time() - t0))
    # runs per (road, side)
    runs = []
    cur = []
    last = None
    for i in range(N):
        ri, side, k, tx_, tz_ = META[i]
        key = (ri, side)
        if acc[i] and last is not None and last[0] == key and last[1] == k - 1 and math.dist(E[i], E[last[2]]) < 3.2:
            cur.append(i)
        else:
            if len(cur) >= MIN_RUN:
                runs.append(cur)
            cur = [i] if acc[i] else []
        last = (key, k, i) if acc[i] else None
    if len(cur) >= MIN_RUN:
        runs.append(cur)
    gates_made = 0
    pieces = 0
    gate_pts = [(g[0], g[1]) for g in GATES]
    gtree = cKDTree(np.array(gate_pts)) if gate_pts else None
    for run in runs:
        drop = set()
        owners = {}
        for i in run:
            owners.setdefault(int(owner[i]), []).append(i)
        # OSM gates on this run: snap them onto the wall
        if gtree is not None:
            for i in run:
                for gi in gtree.query_ball_point(E[i], 7.0):
                    g = GATES[gi]
                    if g[6]:
                        continue
                    ri, side, k, tx_, tz_ = META[i]
                    g[0], g[1], g[2], g[3], g[4], g[6] = float(E[i][0]), float(E[i][1]), tx_, tz_, 10.0, True
                    for j in run:
                        if math.dist(E[j], E[i]) < 10.0 / 2 + 1.4:
                            drop.add(j)
        # driveways crossing the run: a gate there
        line = LineString([tuple(E[i]) for i in run])
        for wi in OSMW_TREE.query(line, predicate='intersects'):
            wl, hw = OSMW[int(wi)]
            if hw in ('footway', 'path', 'steps', 'cycleway', 'pedestrian', None):
                continue
            x_ = wl.intersection(line)
            for q in getattr(x_, 'geoms', [x_]):
                if q.geom_type != 'Point':
                    continue
                j0 = min(run, key=lambda j: math.dist(E[j], (q.x, q.y)))
                if j0 in drop:
                    continue
                ri, side, k, tx_, tz_ = META[j0]
                for j in run:
                    if math.dist(E[j], E[j0]) < 5 + 1.4:
                        drop.add(j)
                GATES.append([float(E[j0][0]), float(E[j0][1]), tx_, tz_, 10.0, 'drive%d' % j0, True])
                owners.pop(int(owner[j0]), None)
                gates_made += 1
        # one gate per owner: at the station nearest the plot's front middle
        for oi, idx in owners.items():
            if len(idx) * STEP < 16 or any(j in drop for j in idx):
                continue
            p = PLOTS[oi]
            poly = p['poly']
            if p.get('front') is not None:
                a, b = poly[p['front']], poly[(p['front'] + 1) % len(poly)]
                tgt = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
            else:
                c = PPOLY[oi].centroid
                tgt = (c.x, c.y)
            j0 = min(idx, key=lambda j: math.dist(E[j], tgt))
            w = 10.0 if len(idx) * STEP >= 30 else 5.0
            if sum(1 for j in idx if math.dist(E[j], E[j0]) < w / 2 + 2) * STEP < w:
                continue
            ri, side, k, tx_, tz_ = META[j0]
            for j in run:
                if math.dist(E[j], E[j0]) < w / 2 + 1.4:
                    drop.add(j)
            GATES.append([float(E[j0][0]), float(E[j0][1]), tx_, tz_, w, 'cmp%d' % j0, True])
            gates_made += 1
        # the wall pieces: contiguous stations, chunks of <= 14 stations as straight chords
        seg = []
        segs_ = []
        for i in run:
            if i in drop:
                if len(seg) >= 2:
                    segs_.append(seg)
                seg = []
            else:
                seg.append(i)
        if len(seg) >= 2:
            segs_.append(seg)
        colour = 'wall%d' % (H('cw', run[0]) % len(WALL_COLS))
        for sg_ in segs_:
            # extend the ends half a step
            pts = [tuple(E[i]) for i in sg_]
            (ax_, az_), (bx_, bz_) = pts[0], pts[1]
            u = unit(ax_ - bx_, az_ - bz_)
            pts[0] = (ax_ + u[0] * 1.0, az_ + u[1] * 1.0)
            (ax_, az_), (bx_, bz_) = pts[-1], pts[-2]
            u = unit(ax_ - bx_, az_ - bz_)
            pts[-1] = (ax_ + u[0] * 1.0, az_ + u[1] * 1.0)
            k = 0
            total = 0.0
            next_p = 0.0
            while k < len(pts) - 1:
                k2 = min(len(pts) - 1, k + 14)
                while k2 > k + 1:
                    a, b = pts[k], pts[k2]
                    fp = LineString([a, b]).buffer(0.75, cap_style=3)
                    if not CARR.intersects(fp) and not plots_hit(fp):
                        # the chord must stay near the stations (curves)
                        if max(LineString([a, b]).distance(Point(q)) for q in pts[k:k2 + 1]) < 0.8:
                            break
                    k2 -= 1
                a, b = pts[k], pts[k2]
                fp = LineString([a, b]).buffer(0.75, cap_style=3)
                Ls = math.dist(a, b)
                if not CARR.intersects(fp) and not plots_hit(fp):
                    us = []
                    if next_p < total - 1e-6:
                        next_p = total
                    while next_p <= total + Ls + 1e-6:
                        us.append(next_p - total)
                        next_p += 16.0
                    if k2 == len(pts) - 1 and (not us or Ls - us[-1] > 3):
                        us.append(Ls)
                    it = wall_piece('compound', a, b, colour, us)
                    if it:
                        keep(it)
                        pieces += 1
                total += Ls
                k = k2
    print('compound walls: %d runs, %d pieces, %d gates (%.1f s)' % (len(runs), pieces, gates_made, __import__('time').time() - t0))


# ---------------------------------------------------------------- 7. shops and tea shops
SHOP_VALUES = None


def shops():
    n0 = len(ITEMS)
    used = {}  # (plot, edge) -> [(u0, u1)]
    cnt = {'sign': 0, 'teashop': 0, 'no plot front near': 0, 'front full': 0}
    tea_sets = 0
    for p in geo.load('points'):
        if not (p['k'] == 'shop' or p['v'] in ('restaurant', 'cafe', 'bank')):
            continue
        x, z = geo.world(*p['p'])
        if not inside_box(x, z) or BLK.contains(Point(x, z)):
            continue
        kind = p['v'] if p['k'] == 'amenity' else p['v']
        best = None
        for i in PTREE.query(Point(x, z).buffer(42)):
            i = int(i)
            pl = PLOTS[i]
            if pl.get('front') is None:
                continue
            poly = pl['poly']
            a, b = poly[pl['front']], poly[(pl['front'] + 1) % len(poly)]
            d = LineString([a, b]).distance(Point(x, z))
            if best is None or d < best[0]:
                best = (d, i, a, b)
        if not best or best[0] > 42:
            cnt['no plot front near'] += 1
            continue
        _, pi, a, b = best
        pl = PLOTS[pi]
        name = ascii_name(p['name'], {'restaurant': 'Restaurant', 'cafe': 'Cafe', 'bank': 'Bank'}.get(kind, 'Shop'))
        if pl.get('sign') and pl.get('name') and ascii_name(pl['name'], '') == name:
            continue
        E = math.dist(a, b)
        if E < 4:
            cnt['front full'] += 1
            continue
        ux, uz = (b[0] - a[0]) / E, (b[1] - a[1]) / E
        nx, nz = uz, -ux
        mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
        if PPOLY[pi].contains(Point(mid[0] + nx * 0.5, mid[1] + nz * 0.5)):
            nx, nz = -nx, -nz
        w = max(4.0, min(E - 1.0, 5.0 + 0.32 * len(name), 14.0))
        u_pt = (x - a[0]) * ux + (z - a[1]) * uz
        slots = used.setdefault((pi, pl['front']), [])
        placed = None
        for du in (0, 3, -3, 6, -6, 9, -9, 12, -12, 16, -16):
            uc = max(w / 2 + 0.4, min(E - w / 2 - 0.4, u_pt + du))
            if all(uc + w / 2 + 0.4 < s0 or uc - w / 2 - 0.4 > s1 for s0, s1 in slots):
                placed = uc
                break
        if placed is None:
            cnt['front full'] += 1
            continue
        slots.append((placed - w / 2, placed + w / 2))
        sx, sz = a[0] + ux * placed + nx * 0.27, a[1] + uz * placed + nz * 0.27
        board = Polygon([(sx + ux * du + nx * dv, sz + uz * du + nz * dv) for du, dv in ((-w / 2, -0.17), (w / 2, -0.17), (w / 2, 0.17), (-w / 2, 0.17))])
        if any(PPOLY[j].intersection(board).area > 0.01 for j in plots_hit(board)) or CARR.intersects(board):
            slots.pop()
            cnt['front full'] += 1
            continue
        colour, ink = SIGN_COLS.get(kind, ((240, 240, 236), 'k'))
        pname = 'sign_' + kind if kind in SIGN_COLS else 'sign_default'
        it = Item('shopsign', sx, sz, yaw_face(nx, nz), 'G', name=name)
        it.box((w, 2.6, 0.3), (0, 9.3, 0), pname, text=(ink, name))
        it.street = SPAVE_ONLY.contains(Point(sx + nx, sz + nz))
        it.yh = yhint(sx, sz)
        keep(it)
        cnt['sign'] += 1
        if kind in ('restaurant', 'cafe') or (p['k'] == 'shop' and kind in ('tea', 'coffee')):
            # tea-shop spill: low tables and plastic stools on the pavement in front (never on a carriageway)
            nb = nearest_rd(sx, sz, 40)
            if nb and nb[1]['src'] == 'game' and nb[1]['walk'] < 6:
                continue
            made = 0
            for du in (-2.8, 2.8, 0, -5.6, 5.6):
                if made >= 2:
                    break
                for dv in (2.6, 4.2):
                    tx_, tz_ = a[0] + ux * (placed + du) + nx * dv, a[1] + uz * (placed + du) + nz * dv
                    g = Point(tx_, tz_).buffer(1.9)
                    if CARR.intersects(Point(tx_, tz_).buffer(2.7)):
                        continue
                    if plots_hit(g) or NOGO.intersects(g) or not occ_free(tx_, tz_, 1.9):
                        continue
                    r = R('tea', p['id'], du)
                    ti = Item('teashop', tx_, tz_, yaw_face(nx, nz) + r.uniform(-0.3, 0.3), 'G')
                    ti.uses.append('tea%d' % r.randrange(3))
                    ti.street = SPAVE_ONLY.contains(Point(tx_, tz_))
                    ti.yh = yhint(tx_, tz_)
                    keep(ti)
                    occ_add(tx_, tz_, 1.9)
                    made += 1
                    tea_sets += 1
                    break
            if made:
                cnt['teashop'] += 1
    print('shops', cnt, 'tea sets', tea_sets, len(ITEMS) - n0, 'items')


def make_protos():
    stools = [('stool_red', 'stool_blue', 'stool_green'), ('stool_blue', 'stool_blue', 'stool_red'), ('stool_green', 'stool_red', 'stool_red')]
    for k, cols in enumerate(stools):
        it = Item('proto', 0, 0)
        it.span(0, 1.3, (1.6, 1.6), (0, 0), 'table')
        for j, (du, dv) in enumerate(((-1.55, 0.2), (1.55, -0.1), (0.1, 1.55))):
            it.add('C', (0.95, 0.85, 0.95), (du, 0.425, dv), cols[j])
        proto('tea%d' % k, it)
    for k, col in enumerate(('tri0', 'tri1', 'tri2', 'tri3')):
        it = Item('proto', 0, 0)
        # local X = forward; the sidecar on +Z (Yangon's saiq-ka: a bicycle with a two-seat sidecar)
        it.box((3.4, 0.25, 0.25), (0.2, 1.7, -0.6), 'trishaw_frame')
        it.add('H', (0.2, 2.0, 2.0), (-1.3, 1.0, -0.6), 'tyre', math.pi / 2)
        it.add('H', (0.2, 2.0, 2.0), (1.7, 1.0, -0.6), 'tyre', math.pi / 2)
        it.box((0.25, 1.4, 0.25), (1.7, 2.3, -0.6), 'trishaw_frame')
        it.box((0.2, 0.15, 1.4), (1.7, 3.0, -0.6), 'trishaw_frame')
        it.add('H', (0.2, 1.8, 1.8), (-0.6, 0.9, 1.9), 'tyre', math.pi / 2)
        it.box((2.4, 1.0, 1.8), (-0.4, 1.4, 1.0), col)
        it.box((0.3, 1.5, 1.8), (-1.5, 2.6, 1.0), 'seat')
        proto('trishaw%d' % k, it)
    for name, extra in (('pole', None), ('pole_b', 'bundle'), ('pole_t', 'transformer')):
        it = Item('proto', 0, 0)
        it.add('C', (0.9, 25.4, 0.9), (0, 11.2, 0), 'poleconc')
        it.box((0.3, 0.3, 4.2), (0, 22.4, 0), 'poleconc')
        if extra == 'bundle':
            it.box((0.8, 1.8, 0.8), (0.55, 18.2, 0.2), 'cable')
        elif extra == 'transformer':
            it.box((1.4, 2.2, 1.2), (0, 15.6, 0.95), 'transformer')
        proto(name, it)


# ---------------------------------------------------------------- 8. clutter along the streets
def kerb_trees():
    n0 = len(ITEMS)
    for rd in RD:
        if rd['src'] != 'game' or rd['kind'] != 'route':
            continue
        L = rd['line'].length
        for side in (1, -1):
            w = 0
            while w < L:
                if R('kt', rd['id'], side, w).random() < 0.3:
                    s = w + 12
                    while s < min(L - 8, w + 200):
                        c, t = rd_point(rd, s)
                        px, pz = lateral(c, t, side, rd['half'] + rd['walk'] - 2.5)
                        g = Point(px, pz).buffer(1.5)
                        if not NOGO.intersects(g) and not plots_hit(g) and occ_free(px, pz, 1.5) and not LTREE.query_ball_point((px, pz), 9.0):
                            # only where this road's own pavement is (not a junction mouth)
                            if rd['outer'].contains(Point(px, pz)) and not any(
                                    o is not rd and o['carr'].intersects(g) for o in (RD[int(i)] for i in RD_CARR_TREE.query(g))):
                                r = R('ktree', rd['id'], side, s)
                                it = Item('kerbtree', px, pz, r.uniform(0, 2 * math.pi), 'G')
                                it.kits.append(('Tree', round(r.uniform(15, 19), 1), 2 if r.random() < 0.2 else 1))
                                it.yh = yhint(px, pz)
                                keep(it)
                                occ_add(px, pz, 2.2)
                        s += 44
                w += 200
    print('kerb trees', len(ITEMS) - n0)


def poles():
    n0 = len(ITEMS)
    chain = 0
    for rd in RD:
        L = rd['line'].length
        if L < 60 or rd['kind'] in ('side', 'lane'):
            continue
        every = 80.0 if rd['kind'] == 'street' else 64.0
        side = 1 if H('pside', rd['id']) % 2 else -1
        s = 10 + H('pstart', rd['id']) % 24
        chain += 1
        last_t = None
        made = 0
        while s < L - 6:
            placed = False
            for ds in (0, 6, -6, 12, -12):
                c, t = rd_point(rd, s + ds)
                px, pz = lateral(c, t, side, rd['half'] + rd['walk'] - 0.7)
                g = Point(px, pz).buffer(0.8)
                if NOGO.intersects(g) or plots_hit(g) or not occ_free(px, pz, 1.0) or LTREE.query_ball_point((px, pz), 6.0):
                    continue
                if last_t is not None and (t[0] * last_t[0] + t[1] * last_t[1]) < math.cos(math.radians(22)):
                    chain += 1
                r = R('pole', rd['id'], s)
                it = Item('pole', px, pz, yaw_x(*t), 'G', chain=chain)
                k = r.random()
                it.uses.append('pole_t' if k < 0.07 else ('pole_b' if k < 0.24 else 'pole'))
                it.street = SPAVE_ONLY.contains(Point(px, pz))
                it.yh = yhint(px, pz)
                keep(it)
                occ_add(px, pz, 1.2)
                last_t = t
                placed = True
                made += 1
                s += ds
                break
            if not placed:
                chain += 1
                last_t = None
            s += every
    print('poles', len(ITEMS) - n0)


def trishaws():
    n0 = len(ITEMS)
    sites = 0
    for rd in RD:
        if rd['src'] != 'street':
            continue
        for end in (0, 1):
            if not rd['mouth'][end] or sites >= 40:
                continue
            if R('trim', rd['id'], end).random() > 0.45:
                continue
            L = rd['line'].length
            if L < 30:
                continue
            side = 1 if H('tside', rd['id'], end) % 2 else -1
            made = 0
            for k in range(2):
                s = (12 + 6.8 * k) if end == 0 else (L - 12 - 6.8 * k)
                c, t = rd_point(rd, s)
                px, pz = lateral(c, t, side, rd['half'] + rd['walk'] * 0.5 + 0.9)
                fx, fz = (t if end == 0 else (-t[0], -t[1]))  # facing the main road
                r = R('trishaw', rd['id'], end, k)
                it = Item('trishaw', px, pz, yaw_x(-fx, -fz), 'G')
                it.uses.append('trishaw%d' % r.randrange(4))
                fp = unary_union([it.part_geo(q)[0] for q in PROTOS[it.uses[0]]])
                if CARR.intersects(fp) or plots_hit(fp) or NOGO.intersects(fp) or not occ_free(px, pz, 2.8):
                    continue
                it.street = SPAVE_ONLY.contains(Point(px, pz))
                it.yh = yhint(px, pz)
                keep(it)
                occ_add(px, pz, 2.8)
                made += 1
            if made:
                sites += 1
    print('trishaws', len(ITEMS) - n0, 'at', sites, 'lane mouths')


def patches():
    n0 = len(ITEMS)
    for rd in RD:
        if rd['src'] != 'game' or rd['kind'] == 'side':
            continue
        L = rd['line'].length
        every = 160 if rd['kind'] == 'route' else 90
        lanes = [-24, -8, 8, 24] if rd['half'] >= 30 else [-8, 8]
        s = 30 + H('patch', rd['id']) % 60
        while s < L - 30:
            r = R('patch', rd['id'], s)
            c, t = rd_point(rd, s)
            off = r.choice(lanes)
            px, pz = lateral(c, t, 1, off)
            pl, pw = r.uniform(3.5, 7.5), r.uniform(2.4, 3.6)
            it = Item('patch', px, pz, yaw_x(*t) + r.uniform(-0.15, 0.15), 'R', pl / 2 - 0.3, pw / 2 - 0.3)
            it.box((pl, 0.1, pw), (0, 0.06 - 0.05, 0), 'patchdark' if r.random() < 0.6 else 'patchgrey')
            fp = it.part_geo(it.parts[0])[0]
            if rd['carr'].buffer(-1.0).contains(fp) and not DECK_ZONE.intersects(fp) and not RING_ZONE.intersects(fp) and \
                    sum(1 for i in RD_CARR_TREE.query(fp, predicate='intersects')) == 1:
                it.yh = yhint(px, pz)
                keep(it)
            s += every
    print('patches', len(ITEMS) - n0)


# ---------------------------------------------------------------- output
def fmt(v):
    s = '%.2f' % v
    s = s.rstrip('0').rstrip('.')
    return '0' if s in ('-0', '', '-') else s


def part_line(prt):
    shape, sx, sy, sz, ox, oy, oz, ry, rx, rz, p, text = prt[:12]
    ln = '%s %s %s %s %s %s %s %s %s %s %d' % (shape, fmt(sx), fmt(sy), fmt(sz), fmt(ox), fmt(oy), fmt(oz),
                                               fmt(math.degrees(ry)), fmt(math.degrees(rx)), fmt(math.degrees(rz)), PAL[p][0])
    if text:
        ink, tx = text
        tx = re.sub(r'[^ -~]', '', tx).replace(']', ')').strip()
        ln += NL + 'T %s %s' % (ink, tx)
    return ln


def write():
    head = []
    for name in PAL_ORDER:
        idx, (r, g, b), mat = PAL[name]
        head.append('Q %d %d %d %d %s' % (idx, r, g, b, mat))
    for name, parts in PROTOS.items():
        head.append('D ' + name)
        head += [part_line(q) for q in parts]
        head.append('E')
    body = []
    for it in ITEMS:
        if it.yh is None:
            it.yh = yhint(it.x, it.z)
        mode = it.mode + ('S' if it.street else '')
        ln = ['I %s %s %s %s %s %s %s %s %d' % (it.kind, fmt(it.x), fmt(it.z), fmt(it.yh) if it.yh is not None else '-', fmt(math.degrees(it.yaw)),
                                               fmt(it.ex), fmt(it.ez), mode, it.chain)]
        for u in it.uses:
            ln.append('U ' + u)
        for k in it.kits:
            ln.append('K %s %s %d' % (k[0], fmt(k[1]), k[2]))
        ln += [part_line(q) for q in it.parts]
        body.append(NL.join(ln))
    chunks, cur, size = [], [NL.join(head)], len(NL.join(head)) + 1
    for b in body:
        if size + len(b) + 1 > MAX_BYTES - 200:
            chunks.append(cur)
            cur, size = [], 0
        cur.append(b)
        size += len(b) + 1
    chunks.append(cur)
    for f in os.listdir(OUT):
        if re.match(r'Details_%s_\d+\.luau$' % TAG, f):
            os.remove(os.path.join(OUT, f))
    paths = []
    for k, c in enumerate(chunks, 1):
        txt = ('-- generated by tools/yangon/city/details.py (Yangon detail layer, batch 0.5; OpenStreetMap contributors, ODbL): part %d of %d' % (k, len(chunks))
               + NL + 'return [==[' + NL + NL.join(c) + NL + ']==]' + NL)
        assert ']==]' not in NL.join(c)
        path = os.path.join(OUT, 'Details_%s_%d.luau' % (TAG, k))
        open(path, 'w', encoding='utf-8', newline=NL).write(txt)
        assert len(txt.encode('utf-8')) < MAX_BYTES, (path, len(txt.encode('utf-8')))
        paths.append((path, len(txt.encode('utf-8'))))
    # the JSON: every item and its parts
    js = {'note': 'tools/yangon/city/details.py, 14 Nov 2026 (OpenStreetMap contributors, ODbL)', 'box': [X0, Z0, X1, Z1],
          'palette': {n: {'i': PAL[n][0], 'rgb': PAL[n][1], 'mat': PAL[n][2]} for n in PAL_ORDER},
          'protos': {n: [q[:11] for q in v] for n, v in PROTOS.items()}, 'items': []}
    for it in ITEMS:
        d = {'kind': it.kind, 'x': round(it.x, 2), 'z': round(it.z, 2), 'yh': None if it.yh is None else round(it.yh, 2),
             'yaw': round(it.yaw, 4), 'mode': it.mode + ('S' if it.street else ''), 'ex': round(it.ex, 2), 'ez': round(it.ez, 2),
             'chain': it.chain, 'uses': it.uses, 'kits': it.kits, 'name': it.name,
             'parts': [[q[0]] + [round(v, 3) for v in q[1:10]] + [q[10]] + ([q[11][1]] if q[11] else []) for q in it.parts]}
        if hasattr(it, 'clearance'):
            d['clearance'] = it.clearance
        js['items'].append(d)
    json.dump(js, open(os.path.join(OUT, 'details_%s.json' % TAG), 'w', encoding='utf-8'))
    return paths


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    make_protos()
    footbridges()
    signals()
    bus_stops()
    gate_specs()
    worship()
    sports()
    pools()
    parking()
    osm_walls()
    compound_walls()
    gates_out()
    osm_trees()
    shops()
    kerb_trees()
    poles()
    trishaws()
    patches()
    per = {}
    for it in ITEMS:
        k = per.setdefault(it.kind, [0, 0])
        k[0] += 1
        k[1] += it.n_parts()
    total = sum(v[1] for v in per.values())
    print()
    print('%-12s %7s %8s' % ('kind', 'items', 'parts'))
    for k, (n, p) in sorted(per.items(), key=lambda kv: -kv[1][1]):
        print('%-12s %7d %8d' % (k, n, p))
    print('%-12s %7d %8d   (budget %d)' % ('TOTAL', len(ITEMS), total, PART_BUDGET))
    paths = write()
    for p, n in paths:
        print('%s %d bytes' % (os.path.relpath(p, geo.ROOT), n))


if __name__ == '__main__':
    main()
