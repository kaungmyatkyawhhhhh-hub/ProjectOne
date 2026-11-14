"""Whole-Yangon map (14 Nov 2026): STREET LIFE for batch 0.5: parked cars and the people on the pavements.

Owner: "the ingame yangon is too clean compared to real life yangon". Report: build/plan/clutter.md (parked cars, people).

What it makes (client data only; src/client/YangonStreetLife.lua builds and pools them round the camera):
  C  parked-car spots. Mesh streets (streets_05.json) and the game's 1+1 part streets (v5 kind "street"): on the
     carriageway against both kerbs (lanes, half 8: one kerb), in clusters of 2-6 at ~17 studs over ~40-55% of each
     kerb, facing the way traffic goes on that side (Myanmar drives on the right; one in ten the other way round).
     Main roads (v5 kind "route", the NPC traffic roads): only half up on the pavement (centre 1 stud past the kerb) in
     front of shop rows, and only where the car stays LANE_CLEAR studs off every traffic lane's centre line
     (src/shared/YangonLanes*.lua). Kept 8+ studs from gates, bus stops, tea shops, other roads' carriageways
     (junction mouths, corners), the game roads' pavements (street mouths), lots (drive-ins), decks and the roundabout;
     never on a building plot, a placed detail (details_05.json) or another car.
     Kind = Config.Traffic type letter (A hatch / Probox, B people carrier, C small van, D minibus / Hiace, E saloon /
     Mark II, F pickup); colour 1-6 white / silver / grey (70%), 7-10 black / blue / maroon / champagne, 11 = the
     model's own paint. up = 1 or -1: half up on the pavement, which side of the car (its local +X or -X) is up.
  S  spots where people stand: bus stops (under / in front of the shelter), tea shops (round the table), shop fronts.
  K  schools (kids in the green and white uniform near them), W  monasteries / pagodas (monks more often near them).
  P  pavement paths: polylines on the pavements' middles (main roads: half + walk/2 from the v5 samples; mesh streets:
     half + walk/2), broken wherever the point is not on a pavement (junctions, mouths, lots, plots, water). Every path
     runs with its road on its LEFT (the client keeps walkers to the right of the line = away from the kerb).

Output: src/shared/YangonStreetLife.lua (+ YangonStreetLife2.. when it does not fit), each under 190,000 characters,
one string of lines (a big table literal fails to load in Studio). Coordinates are decimetres from (OX, OZ), ints:
  C x z y yaw kind colour up        S x z y yaw kind(b|t|s)        K x z        W x z
  P cls(m|s) n x z y dx dz dy ...      (first point absolute, then deltas; cls m = main road pavement, s = street)
yaw in tenths of a degree: the model's front (-Z) faces (-sin yaw, -cos yaw) (CFrame.Angles(0, yaw, 0)).

Run from Games/CityLegends/tools/yangon/city:  python streetlife.py   (then python streetlife_test.py)
"""
import hashlib, json, math, os, random, re, sys

import numpy as np
import shapely
from shapely.geometry import LineString, MultiPoint, Point, Polygon
from shapely.ops import unary_union
from shapely.strtree import STRtree
from scipy.spatial import cKDTree

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import geo
import streets as streets_mod

YT = os.path.dirname(HERE)
SRC_SHARED = os.path.join(geo.ROOT, 'src', 'shared')
OUT = os.path.join(geo.BUILD, 'city')
NL = chr(10)
TAG = '05'
MAX_CHARS = 185000

OX, OZ = 27900.0, -6500.0
LENGTHS = {'A': 12.0, 'B': 12.6, 'C': 13.2, 'D': 14.7, 'E': 13.8, 'F': 15.9}  # Config.Traffic.ModelLengths
KIND_W = [('E', 0.32), ('A', 0.22), ('D', 0.14), ('C', 0.12), ('B', 0.10), ('F', 0.10)]
CAR_W = 6.0  # footprint width used for every check (the low-poly bodies are ~5-5.8 wide)
KERB_GAP = 0.4  # street cars: body side this far off the kerb
UP_IN = 0.8  # main-road cars: centre this far past the kerb, onto the pavement
LANE_CLEAR = 4.0  # main-road cars: footprint at least this far from a lane's centre line (NPC half width ~3.3)
PITCH = 17.0
CLEAR8 = 8.0
KEEP8 = ('gate', 'busstop', 'teashop')


def H(*k):
    return int(hashlib.md5(repr(k).encode('utf-8')).hexdigest()[:8], 16)


def R(*k):
    return random.Random(H(*k))


def rot_yxz(v, ry, rx, rz):
    """Roblox CFrame.fromEulerAnglesYXZ(rx, ry, rz) * v (as details.py)"""
    x, y, z = v
    c, s = math.cos(rz), math.sin(rz)
    x, y = x * c - y * s, x * s + y * c
    c, s = math.cos(rx), math.sin(rx)
    y, z = y * c - z * s, y * s + z * c
    c, s = math.cos(ry), math.sin(ry)
    x, z = x * c + z * s, -x * s + z * c
    return (x, y, z)


def item_world(it, ox, oz):
    c, s = math.cos(it['yaw']), math.sin(it['yaw'])
    return (it['x'] + ox * c + oz * s, it['z'] - ox * s + oz * c)


def yaw_face(fx, fz):
    """yaw whose local -Z (the front) faces (fx, fz)"""
    return math.atan2(-fx, -fz)


def car_poly(x, z, fx, fz, L, W=CAR_W):
    rx, rz = -fz, fx
    hl, hw = L / 2, W / 2
    return Polygon([(x + fx * a * hl + rx * b * hw, z + fz * a * hl + rz * b * hw) for a, b in ((1, 1), (1, -1), (-1, -1), (-1, 1))])


def parse_lanes():
    out = []
    for name in ('YangonLanes.lua', 'YangonLanes2.lua'):
        t = open(os.path.join(SRC_SHARED, name), encoding='utf-8').read()
        for m in re.finditer(r'pts = \{([^}]*)\}', t):
            v = [float(q) for q in m.group(1).split(',') if q.strip()]
            pts = [(v[i], v[i + 2]) for i in range(0, len(v) - 2, 3)]
            if len(pts) >= 2:
                out.append(LineString(pts))
    return out


# ---------------------------------------------------------------- the world (also used by streetlife_test.py)
def load_world():
    W = {}
    src = open(os.path.join(YT, 'd19_buildings.py'), encoding='utf-8').read()
    ns = {'__file__': os.path.join(YT, 'd19_buildings.py')}
    exec(compile(src[:src.index('# ---------------------------------------------------------------- the OSM buildings')], 'd19', 'exec'), ns)
    W['X0'], W['X1'], W['Z0'], W['Z1'] = ns['X0'], ns['X1'], ns['Z0'], ns['Z1']
    RING = ns['RING']
    rect = ns['rect']
    W['BLK'] = unary_union([Polygon(rect(*s, grow=10)) for s in ns['SITES']] +
                           [Polygon(rect(p['x'], p['z'], p['fx'], p['fz'], p['w'], p['d'], grow=8)) for p in ns['landmarks']])
    game = json.load(open(os.path.join(geo.MAP, 'ygn_roads_v5.json'), encoding='utf-8'))
    W['GAME'] = game
    gpave, gcarr = streets_mod.game_pave(game)
    W['GPAVE'], W['GCARR'] = gpave, gcarr
    st = [s for s in streets_mod.heights(TAG)]
    W['ST'] = st
    P = np.array([p for s in st for p in s['pts']])
    Hh = np.array([y for s in st for y in s['y0']])
    W['_tree'], W['_P'], W['_H'] = cKDTree(P), P, Hh
    # every road record: the game roads' runs between cuts and the mesh streets
    RD = []
    for r in game['roads']:
        cs = set(game.get('cut', {}).get(r['name'], []))
        run = []
        for k, s in enumerate(r['s'] + [None]):
            if s is None or k in cs:
                if len(run) > 3:
                    RD.append({'id': 'g:%s:%d' % (r['name'], len(RD)), 'name': r['name'], 'src': 'game', 'kind': r.get('kind'),
                               'rhalf': r['half'], 'walkL': r.get('walkL') or 10.0, 'walkR': r.get('walkR') or r.get('walkL') or 10.0,
                               'samples': run, 'half': max(max(q[6], q[7]) for q in run), 'pts': [(q[0], q[2]) for q in run]})
                run = []
                continue
            run.append(s)
    for s in st:
        RD.append({'id': 's:%s' % s['id'], 'name': s['name'], 'src': 'street', 'kind': s['cls'], 'half': s['half'],
                   'walk': s['walk'], 'pts': [tuple(p) for p in s['pts']], 'ys': s['y0'], 'st': s})
    for rd in RD:
        rd['line'] = LineString(rd['pts'])
        rd['carr'] = rd['line'].buffer(rd['half'], cap_style=2, join_style=1)
    W['RD'] = RD
    W['RD_CARR_TREE'] = STRtree([rd['carr'] for rd in RD])
    W['DECK_ZONE'] = unary_union([LineString([(q[0], q[2]) for q in d['s']]).buffer(44) for d in game['decks']])
    deck_carr = unary_union([LineString([(q[0], q[2]) for q in d['s']]).buffer(32, cap_style=2) for d in game['decks']])
    W['RING_ZONE'] = Point(RING[0], RING[1]).buffer(RING[2])
    ring_carr = Point(RING[0], RING[1]).buffer(108)
    scarr = unary_union([rd['carr'] for rd in RD if rd['src'] == 'street'])
    souter = unary_union([rd['line'].buffer(rd['half'] + rd['walk'], cap_style=2, join_style=1) for rd in RD if rd['src'] == 'street'])
    W['CARR'] = unary_union([gcarr, scarr, deck_carr, ring_carr])
    W['SPAVE'] = souter.difference(scarr).difference(gpave)
    water = []
    for a in geo.load('areas'):
        t = a['t']
        if t.get('natural') == 'water' or t.get('water') or t.get('landuse') in ('reservoir', 'basin'):
            pp = geo.proj(a['p'])
            if len(pp) >= 3:
                water.append(Polygon(pp).buffer(0))
    W['WATER'] = unary_union(water).buffer(2) if water else Polygon()
    plots = json.load(open(os.path.join(OUT, f'plots_{TAG}.json'), encoding='utf-8'))['plots']
    W['PLOTS'] = plots
    W['PPOLY'] = [Polygon(p['poly']).buffer(0) for p in plots]
    W['PTREE'] = STRtree(W['PPOLY'])
    shop = [i for i, p in enumerate(plots) if p.get('shop') or p.get('style') in ('shophouse',)]
    W['SHOP_IDX'] = shop
    W['SHOPTREE'] = STRtree([W['PPOLY'][i] for i in shop])
    # placed details: ground footprints (parts starting under 6 studs over the item's ground)
    det = json.load(open(os.path.join(OUT, f'details_{TAG}.json'), encoding='utf-8'))
    W['DET'] = det
    protos = det['protos']
    foot, fkind = [], []
    for it in det['items']:
        parts = list(it.get('parts') or [])
        for u in it.get('uses') or []:
            parts += protos.get(u, [])
        pts = []
        for prt in parts:
            shape, sx, sy, sz, ox, oy, oz, ry, rx, rz = prt[:10]
            lo = 1e9
            corners = []
            for a in (-0.5, 0.5):
                for b in (-0.5, 0.5):
                    for c in (-0.5, 0.5):
                        v = rot_yxz((a * sx, b * sy, c * sz), ry, rx, rz)
                        lo = min(lo, v[1] + oy)
                        corners.append(item_world(it, v[0] + ox, v[2] + oz))
            if lo < 6.0:
                pts += corners
        g = MultiPoint(pts).convex_hull.buffer(0.3) if len(pts) >= 3 else Point(it['x'], it['z']).buffer(0.6)
        if it.get('kits'):
            g = g.union(Point(it['x'], it['z']).buffer(1.6))
        foot.append(g)
        fkind.append(it['kind'])
    W['DFOOT'], W['DKIND'] = foot, fkind
    W['DTREE'] = STRtree(foot)
    lanes = parse_lanes()
    W['LANES'] = lanes
    W['LTREE'] = STRtree(lanes)
    for g in (W['CARR'], W['GPAVE'], W['SPAVE'], W['BLK'], W['WATER'], W['DECK_ZONE'], W['RING_ZONE']):
        shapely.prepare(g)
    return W


def street_h(W, x, z):
    """the mesh streets' surface height (streets.py build's h_at)"""
    d, i = W['_tree'].query((x, z), k=4)
    w = 1.0 / np.maximum(d, 0.5) ** 2
    return float((W['_H'][i] * w).sum() / w.sum())


class Line:
    """a polyline with arc-length lookups: position, tangent, interpolated extras"""

    def __init__(self, pts, extras=None):
        self.p = np.array(pts, dtype=float)
        seg = np.hypot(np.diff(self.p[:, 0]), np.diff(self.p[:, 1]))
        self.cum = np.concatenate([[0.0], np.cumsum(seg)])
        self.L = float(self.cum[-1])
        self.extras = {k: np.array(v, dtype=float) for k, v in (extras or {}).items()}

    def at(self, s):
        s = min(max(s, 0.0), self.L)
        i = int(np.searchsorted(self.cum, s, side='right') - 1)
        i = min(max(i, 0), len(self.p) - 2)
        a, b = self.p[i], self.p[i + 1]
        seg = self.cum[i + 1] - self.cum[i]
        t = (s - self.cum[i]) / seg if seg > 1e-6 else 0.0
        x, z = a + (b - a) * t
        dx, dz = (b - a) / (seg if seg > 1e-6 else 1.0)
        ex = {k: float(v[i] + (v[i + 1] - v[i]) * t) for k, v in self.extras.items()}
        ex['_lo'] = {k: float(min(v[i], v[i + 1])) for k, v in self.extras.items()}
        return float(x), float(z), float(dx), float(dz), i, ex


# ---------------------------------------------------------------- the checks every car passes
def car_ok(W, poly, own, placed, main=False):
    """(ok, reason)"""
    x0, z0, x1, z1 = poly.bounds
    if not (W['X0'] + 10 < x0 and x1 < W['X1'] - 10 and W['Z0'] + 10 < z0 and z1 < W['Z1'] - 10):
        return False, 'edge'
    if W['WATER'].intersects(poly) or W['DECK_ZONE'].intersects(poly) or W['RING_ZONE'].intersects(poly):
        return False, 'zone'
    if W['BLK'].distance(poly) < 2.0:
        return False, 'lot'
    if own['src'] == 'street':
        if not poly.within(own['carr'].buffer(0.05)):
            return False, 'off'
        if W['GPAVE'].distance(poly) < CLEAR8:
            return False, 'mouth'
    for j in W['RD_CARR_TREE'].query(poly, predicate='dwithin', distance=CLEAR8):
        rd = W['RD'][int(j)]
        if rd is own or (own['src'] == 'game' and rd['src'] == 'game' and rd['name'] == own['name']):
            continue
        return False, 'junction'
    if len(W['PTREE'].query(poly.buffer(0.2), predicate='intersects')):
        return False, 'plot'
    for j in W['DTREE'].query(poly, predicate='dwithin', distance=CLEAR8):
        j = int(j)
        if W['DKIND'][j] in KEEP8 or W['DFOOT'][j].distance(poly) < 0.3:
            return False, 'detail:' + W['DKIND'][j]
    if len(W['LTREE'].query(poly, predicate='dwithin', distance=LANE_CLEAR)):
        return False, 'lane'
    key = (int(poly.centroid.x // 32), int(poly.centroid.y // 32))
    for gx in (key[0] - 1, key[0], key[0] + 1):
        for gz in (key[1] - 1, key[1], key[1] + 1):
            for q in placed.get((gx, gz), ()):
                if q.distance(poly) < 0.5:
                    return False, 'car'
    return True, ''


def pick_kind(rng):
    r = rng.random()
    for k, w in KIND_W:
        r -= w
        if r <= 0:
            return k
    return 'E'


def pick_colour(rng):
    r = rng.random()
    if r < 0.70:
        return rng.randint(1, 6)
    if r < 0.88:
        return rng.randint(7, 10)
    return 11


def kerb_rows(W, line, off_fn, y_fn, own, side, rng, placed, cars, stats, main=False, want=None):
    """clusters of 2-6 cars along one kerb. off_fn(ex) = lateral offset of the car centre (to the right of the line
    times side); want(x, z, ex) = this stretch may be parked (main roads: shop fronts)"""
    target = rng.uniform(0.40, 0.55)
    mean_cluster = 4 * PITCH
    mean_gap = mean_cluster * (1 - target) / target
    s = rng.uniform(4, mean_gap)
    placed_len = 0.0
    while s < line.L - 8:
        n = rng.randint(2, 6)
        got = 0
        tries = 0
        while got < n and s < line.L - 8:
            x, z, dx, dz, i, ex = line.at(s)
            rx, rz = -dz * side, dx * side
            off = off_fn(ex)
            if off is None or (want is not None and not want(x, z, dx, dz, ex)):
                stats['skip'] += 1
                if got:
                    break
                s += 4
                tries += 1
                if tries > 12:
                    break
                continue
            kind = pick_kind(rng)
            L = LENGTHS[kind]
            cx, cz = x + rx * off, z + rz * off
            # face the way traffic goes on this kerb (right-hand traffic), one in ten the other way
            fx, fz = (dx, dz) if side > 0 else (-dx, -dz)
            flip = rng.random() < 0.1
            if flip:
                fx, fz = -fx, -fz
            # a little skew on the streets (not half up on a kerb); the footprint is checked as it will stand
            yaw = yaw_face(fx, fz) + (0.0 if main else math.radians(rng.uniform(-2.5, 2.5)))
            fx, fz = -math.sin(yaw), -math.cos(yaw)
            poly = car_poly(cx, cz, fx, fz, L)
            ok, why = car_ok(W, poly, own, placed, main)
            if not ok:
                stats[why.split(':')[0]] = stats.get(why.split(':')[0], 0) + 1
                if got:
                    break
                s += 4
                tries += 1
                if tries > 12:
                    break
                continue
            up = 0
            if main:
                # the car's local +X is (cos yaw, -sin yaw); the pavement is on the kerb side (rx, rz)
                up = 1 if (math.cos(yaw) * rx - math.sin(yaw) * rz) > 0 else -1
            cars.append({'x': cx, 'z': cz, 'y': y_fn(cx, cz, ex), 'yaw': yaw, 'kind': kind, 'col': pick_colour(rng), 'up': up,
                         'poly': poly, 'road': own['id'], 'main': main})
            placed.setdefault((int(poly.centroid.x // 32), int(poly.centroid.y // 32)), []).append(poly)
            got += 1
            placed_len += PITCH
            s += PITCH + rng.uniform(0.0, 1.0)
        # the gap after a cluster follows the cluster's real length, so the kerb that can be parked on (not junctions,
        # mouths, gates) ends up about `target` full; a stretch with no car at all gets no gap
        if got:
            s += rng.uniform(0.6, 1.4) * got * PITCH * (1 - target) / target
    return placed_len


def parked_cars(W):
    cars, placed = [], {}
    stats = {'skip': 0}
    side_len = {'street': 0.0, 'main': 0.0}
    got_len = {'street': 0.0, 'main': 0.0}
    for rd in W['RD']:
        if rd['src'] == 'street':
            stt = rd['st']
            if stt.get('bridge') or stt.get('layer'):
                continue
            line = Line(rd['pts'], {'y': rd['ys']})
            half = rd['half']
            sides = (1, -1)
            if rd['kind'] == 'lane':
                sides = (R('laneside', rd['id']).choice((1, -1)),)
            for side in sides:
                rng = R('car', rd['id'], side)
                off = half - KERB_GAP - CAR_W / 2
                side_len['street'] += line.L
                got_len['street'] += kerb_rows(W, line, lambda ex, o=off: o, lambda x, z, ex: street_h(W, x, z), rd, side, rng, placed, cars, stats)
        else:
            smp = rd['samples']
            line = Line(rd['pts'], {'y': [q[1] for q in smp], 'hl': [q[6] for q in smp], 'hr': [q[7] for q in smp]})
            if rd['kind'] == 'street':
                # the game's 1+1 part streets: no NPC lanes, park on the carriageway like the mesh streets
                for side in (1, -1):
                    rng = R('car', rd['id'], side)
                    key = 'hr' if side > 0 else 'hl'

                    def off_fn(ex, key=key, rh=rd['rhalf']):
                        h = ex['_lo'][key]
                        return None if h < rh - 0.5 else h - KERB_GAP - CAR_W / 2

                    side_len['street'] += line.L
                    got_len['street'] += kerb_rows(W, line, off_fn, lambda x, z, ex: ex['y'], rd, side, rng, placed, cars, stats)
            elif rd['kind'] == 'route':
                for side in (1, -1):
                    rng = R('carm', rd['id'], side)
                    key = 'hr' if side > 0 else 'hl'
                    walk = rd['walkR'] if side > 0 else rd['walkL']

                    def off_fn(ex, key=key, rh=rd['rhalf']):
                        h = ex['_lo'][key]
                        return None if h < rh - 0.5 else h + UP_IN

                    def want(x, z, dx, dz, ex, key=key, side=side, walk=walk):
                        h = ex[key]
                        rx, rz = -dz * side, dx * side
                        q = Point(x + rx * (h + walk + 4), z + rz * (h + walk + 4))
                        return len(W['SHOPTREE'].query(q, predicate='dwithin', distance=7.0)) > 0

                    side_len['main'] += line.L
                    got_len['main'] += kerb_rows(W, line, off_fn, lambda x, z, ex: ex['y'], rd, side, rng, placed, cars, stats,
                                                 main=True, want=want)
    return cars, stats, side_len, got_len


# ---------------------------------------------------------------- the people
def douglas(pts, tol=0.5, ytol=0.15):
    """3D Douglas-Peucker: plan distance under tol and height off the chord under ytol"""
    if len(pts) <= 2:
        return pts
    keep = [False] * len(pts)
    keep[0] = keep[-1] = True
    stack = [(0, len(pts) - 1)]
    while stack:
        a, b = stack.pop()
        ax, az, ay = pts[a]
        bx, bz, by = pts[b]
        dx, dz = bx - ax, bz - az
        L2 = dx * dx + dz * dz or 1e-9
        worst, wi = 0.0, -1
        for i in range(a + 1, b):
            px, pz, py = pts[i]
            t = max(0.0, min(1.0, ((px - ax) * dx + (pz - az) * dz) / L2))
            d = math.hypot(px - (ax + dx * t), pz - (az + dz * t))
            dy = abs(py - (ay + (by - ay) * t)) * (tol / ytol)
            e = max(d, dy)
            if e > worst:
                worst, wi = e, i
        if worst > tol and wi > 0:
            keep[wi] = True
            stack.append((a, wi))
            stack.append((wi, b))
    return [p for p, k in zip(pts, keep) if k]


def walk_ok(W, x, z, street):
    p = Point(x, z)
    if not (W['X0'] + 10 < x < W['X1'] - 10 and W['Z0'] + 10 < z < W['Z1'] - 10):
        return False
    if W['CARR'].intersects(p.buffer(0.9)):
        return False
    if street:
        if not W['SPAVE'].contains(p):
            return False
    elif not W['GPAVE'].contains(p):
        return False
    if W['BLK'].contains(p) or W['WATER'].contains(p) or W['DECK_ZONE'].contains(p) or W['RING_ZONE'].contains(p):
        return False
    if len(W['PTREE'].query(p.buffer(0.6), predicate='intersects')):
        return False
    return True


def runs_to_paths(W, seq, cls, out, min_len=24.0):
    """seq: points or None (not walkable); every unbroken run (no jump over 14 studs, no step that touches a
    carriageway) of min_len or more is a path (simplified, unless the simplified line would touch a carriageway)"""
    carr = W['CARR']

    def flush(run):
        if len(run) >= 2:
            L = sum(math.hypot(run[i + 1][0] - run[i][0], run[i + 1][1] - run[i][1]) for i in range(len(run) - 1))
            if L >= min_len:
                simple = douglas(run)
                if LineString([(q[0], q[1]) for q in simple]).buffer(0.4).intersects(carr):
                    simple = run
                out.append((cls, simple))

    run = []
    for q in seq + [None]:
        if q is not None and run and LineString([(run[-1][0], run[-1][1]), (q[0], q[1])]).buffer(0.4).intersects(carr):
            flush(run)
            run = [q]
            continue
        if q is None or (run and math.hypot(q[0] - run[-1][0], q[1] - run[-1][1]) > 14):
            flush(run)
            run = [] if q is None else [q]
            continue
        run.append(q)


def ped_paths(W):
    paths = []
    for rd in W['RD']:
        if rd['src'] == 'street':
            stt = rd['st']
            if stt.get('bridge') or stt.get('layer'):
                continue
            pts = rd['pts']
            n = len(pts)
            off = rd['half'] + rd['walk'] / 2
            for side in (1, -1):
                seq = []
                for i in range(n):
                    a, b = pts[max(0, i - 1)], pts[min(n - 1, i + 1)]
                    dx, dz = b[0] - a[0], b[1] - a[1]
                    L = math.hypot(dx, dz) or 1.0
                    rx, rz = -dz / L * side, dx / L * side
                    x, z = pts[i][0] + rx * off, pts[i][1] + rz * off
                    seq.append((x, z, street_h(W, x, z) + streets_mod.PAVE_UP) if walk_ok(W, x, z, True) else None)
                runs_to_paths(W, seq if side > 0 else seq[::-1], 's', paths)
        else:
            if rd['kind'] not in ('route', 'street', 'side'):
                continue
            smp = rd['samples']
            for side in (1, -1):
                walk = rd['walkR'] if side > 0 else rd['walkL']
                seq = []
                for q in smp:
                    h = q[7] if side > 0 else q[6]
                    if h < rd['rhalf'] - 0.5:
                        seq.append(None)
                        continue
                    rx, rz = -q[4] * side, q[3] * side
                    x, z = q[0] + rx * (h + walk / 2), q[2] + rz * (h + walk / 2)
                    seq.append((x, z, q[1] + 0.5) if walk_ok(W, x, z, False) else None)
                runs_to_paths(W, seq if side > 0 else seq[::-1], 'm', paths)
    return paths


def surface_y(W, x, z):
    """pavement top near a point: a mesh street's pavement, else the nearest game road sample + 0.5"""
    p = Point(x, z)
    if W['SPAVE'].distance(p) < 1.5:
        return street_h(W, x, z) + streets_mod.PAVE_UP
    if '_gtree' not in W:
        g = [(q[0], q[2], q[1]) for r in W['GAME']['roads'] for q in r['s']]
        W['_g'] = np.array(g)
        W['_gtree'] = cKDTree(W['_g'][:, :2])
    d, i = W['_gtree'].query((x, z))
    if d < 80:
        return float(W['_g'][i, 2]) + 0.5
    return street_h(W, x, z) + streets_mod.PAVE_UP


def stand_ok(W, x, z):
    p = Point(x, z)
    if W['CARR'].intersects(p.buffer(0.8)):
        return False
    if not (W['GPAVE'].contains(p) or W['SPAVE'].contains(p)):
        return False
    if W['BLK'].contains(p) or W['WATER'].contains(p):
        return False
    if len(W['PTREE'].query(p.buffer(0.6), predicate='intersects')):
        return False
    for j in W['DTREE'].query(p.buffer(0.7), predicate='intersects'):
        if W['DKIND'][int(j)] not in ('busstop', 'teashop', 'patch'):
            return False
    return True


def ped_spots(W):
    spots = []
    det = W['DET']
    protos = det['protos']
    for it in det['items']:
        if it['kind'] == 'busstop':
            rng = R('bus', it['x'], it['z'])
            for ox, oz in ((-2.6, -0.9), (0.6, -0.9), (2.8, -1.0), (-1.2, -2.6), (1.8, -2.7)):
                if rng.random() < 0.35:
                    continue
                x, z = item_world(it, ox + rng.uniform(-0.3, 0.3), oz + rng.uniform(-0.2, 0.2))
                if stand_ok(W, x, z):
                    spots.append((x, z, surface_y(W, x, z), it['yaw'] + rng.uniform(-0.6, 0.6), 'b'))
        elif it['kind'] == 'teashop':
            rng = R('tea', it['x'], it['z'])
            stools = []
            for u in it.get('uses') or []:
                for prt in protos.get(u, []):
                    if prt[10].startswith('stool'):
                        stools.append((prt[4], prt[6]))
            n = 0
            for a in [rng.uniform(0, 2 * math.pi) for _ in range(8)]:
                ox, oz = math.cos(a) * 2.5, math.sin(a) * 2.5
                if any(math.hypot(ox - sx, oz - sz) < 1.1 for sx, sz in stools):
                    continue
                x, z = item_world(it, ox, oz)
                if stand_ok(W, x, z):
                    spots.append((x, z, surface_y(W, x, z), yaw_face(it['x'] - x, it['z'] - z), 't'))
                    n += 1
                    if n >= 2:
                        break
    for i in W['SHOP_IDX']:
        p = W['PLOTS'][i]
        rng = R('shop', p['id'])
        if rng.random() < 0.5:
            continue
        poly = p['poly']
        f = p.get('front')
        if f is None or not (0 <= f < len(poly)):
            continue
        a, b = poly[f], poly[(f + 1) % len(poly)]
        mx, mz = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
        ex, ez = b[0] - a[0], b[1] - a[1]
        L = math.hypot(ex, ez)
        if L < 4:
            continue
        nx, nz = -ez / L, ex / L
        c = W['PPOLY'][i].centroid
        if (mx - c.x) * nx + (mz - c.y) * nz < 0:
            nx, nz = -nx, -nz
        t = rng.uniform(-0.3, 0.3) * L
        x, z = mx + ex / L * t + nx * 2.2, mz + ez / L * t + nz * 2.2
        if stand_ok(W, x, z):
            spots.append((x, z, surface_y(W, x, z), yaw_face(-nx, -nz) + rng.uniform(-0.5, 0.5), 's'))
    schools = []
    worship = []
    for i, p in enumerate(W['PLOTS']):
        if p.get('kind') == 'school':
            c = W['PPOLY'][i].centroid
            schools.append((c.x, c.y))
        elif p.get('kind') in ('monastery', 'temple'):
            c = W['PPOLY'][i].centroid
            worship.append((c.x, c.y))
    for it in det['items']:
        if it['kind'] == 'worship':
            worship.append((it['x'], it['z']))
    return spots, schools, worship


# ---------------------------------------------------------------- writing
def dm(v, o=0.0):
    return int(round((v - o) * 10))


def lines_of(cars, spots, schools, worship, paths):
    out = []
    for c in cars:
        out.append('C %d %d %d %d %s %d %d' % (dm(c['x'], OX), dm(c['z'], OZ), dm(c['y']), int(round(math.degrees(c['yaw']) * 10)) % 3600,
                                              c['kind'], c['col'], c['up']))
    for x, z, y, yaw, k in spots:
        out.append('S %d %d %d %d %s' % (dm(x, OX), dm(z, OZ), dm(y), int(round(math.degrees(yaw) * 10)) % 3600, k))
    for x, z in schools:
        out.append('K %d %d' % (dm(x, OX), dm(z, OZ)))
    for x, z in worship:
        out.append('W %d %d' % (dm(x, OX), dm(z, OZ)))
    for cls, pts in paths:
        q = [(dm(x, OX), dm(z, OZ), dm(y)) for x, z, y in pts]
        bits = ['P', cls, str(len(q)), str(q[0][0]), str(q[0][1]), str(q[0][2])]
        for k in range(1, len(q)):
            bits += [str(q[k][0] - q[k - 1][0]), str(q[k][1] - q[k - 1][1]), str(q[k][2] - q[k - 1][2])]
        out.append(' '.join(bits))
    return out


def write_modules(lines):
    chunks, cur, n = [], [], 0
    for ln in lines:
        if n + len(ln) + 1 > MAX_CHARS - 1500:
            chunks.append(cur)
            cur, n = [], 0
        cur.append(ln)
        n += len(ln) + 1
    if cur:
        chunks.append(cur)
    names = ['YangonStreetLife'] + ['YangonStreetLife%d' % (k + 1) for k in range(1, len(chunks))]
    # old extra modules from an earlier run
    for f in os.listdir(SRC_SHARED):
        m = re.match(r'^YangonStreetLife(\d+)\.lua$', f)
        if m and int(m.group(1)) > len(chunks):
            os.remove(os.path.join(SRC_SHARED, f))
    res = []
    for k, (name, c) in enumerate(zip(names, chunks)):
        body = NL.join(c)
        assert ']==]' not in body
        head = ('-- generated by tools/yangon/city/streetlife.py (Yangon street life: parked cars, people; OpenStreetMap contributors, '
                'ODbL): part %d of %d, do not edit' % (k + 1, len(chunks)) + NL)
        if k == 0:
            more = ', '.join('"%s"' % n_ for n_ in names[1:])
            txt = (head + 'return {' + NL + '\tmore = { ' + more + ' },' + NL + '\torigin = { %g, %g },' % (OX, OZ) + NL
                   + '\tdata = [==[' + NL + body + NL + ']==],' + NL + '}' + NL)
        else:
            txt = head + 'return [==[' + NL + body + NL + ']==]' + NL
        assert len(txt) < 190000, (name, len(txt))
        path = os.path.join(SRC_SHARED, name + '.lua')
        open(path, 'w', encoding='utf-8', newline=NL).write(txt)
        res.append((path, len(txt)))
    return res


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    print('loading ...')
    W = load_world()
    print('parked cars ...')
    cars, stats, side_len, got_len = parked_cars(W)
    nm = sum(1 for c in cars if c['main'])
    print('cars: %d (streets %d, main roads half up %d)' % (len(cars), len(cars) - nm, nm))
    print('  kerb length looked at: streets %.0f, main roads %.0f; parked share: streets %.0f%%, main %.0f%%' % (
        side_len['street'], side_len['main'], 100 * got_len['street'] / max(side_len['street'], 1), 100 * got_len['main'] / max(side_len['main'], 1)))
    print('  rejected stations:', dict(sorted(stats.items(), key=lambda kv: -kv[1])))
    from collections import Counter
    print('  kinds', dict(Counter(c['kind'] for c in cars)), ' light colours %.0f%%' % (100 * sum(1 for c in cars if c['col'] <= 6) / max(len(cars), 1)))
    print('pedestrian paths ...')
    paths = ped_paths(W)
    npts = sum(len(p) for _, p in paths)
    plen = sum(sum(math.hypot(p[i + 1][0] - p[i][0], p[i + 1][1] - p[i][1]) for i in range(len(p) - 1)) for _, p in paths)
    print('paths: %d (main %d, street %d), %d points, %.0f studs' % (len(paths), sum(1 for c, _ in paths if c == 'm'),
                                                                     sum(1 for c, _ in paths if c == 's'), npts, plen))
    spots, schools, worship = ped_spots(W)
    print('spots: %d (bus %d, tea %d, shop %d), schools %d, worship %d' % (
        len(spots), sum(1 for s in spots if s[4] == 'b'), sum(1 for s in spots if s[4] == 't'), sum(1 for s in spots if s[4] == 's'),
        len(schools), len(worship)))
    res = write_modules(lines_of(cars, spots, schools, worship, paths))
    for p, n in res:
        print('%s %d characters' % (os.path.relpath(p, geo.ROOT), n))


if __name__ == '__main__':
    main()
