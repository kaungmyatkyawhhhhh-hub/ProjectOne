"""Road markings for roads05 data, as real Yangon ones (16 Nov 2026; vault "Audit - Yangon roads 1 to 1" items 3, 9-12 and
"Research - Yangon road look"), as paint polygons the preview draws and the Studio build lays (0.08 over the road):

  * lane lines: white, dashed 3 m on / 6 m off (9 / 18 studs), 0.15 m wide (0.45 studs); none on small streets (real
    residential streets are unmarked)
  * centre: one solid white line on an undivided main road (never broken by a smaller road's mouth)
  * divided roads: a yellow solid line along each median kerb
  * no outer edge lines (most photos show none)
  * junction boxes (where two main roads' carriageways overlap): nothing painted inside
  * mouths: a main road's lane lines break across a smaller road's mouth (RoadLines clearMouths); the centre line runs on
  * zebras: yellow, 12 studs long, 1.6-stud bars on a 3.2 pitch, across each arm just outside a main x main box
  * stop lines: white, 1.2 studs, across the approach lanes 3 studs before the zebra, where an OSM traffic signal stands
  * roundabouts: dashed lane lines round the ring, a white dashed give-way line across each entry, yellow hatched
    splitters between an arm's entry and exit where it is divided
  * turn arrows from OSM turn:lanes (roads.json `turn` runs), one per lane, 10 studs before the stop line / box

    YANGON_SCALE=1to1 python roads05_paint.py <tags joined by _>   -> build/city_1to1/roads05_<tags>/paint.json
"""
import json, math, os, sys

import numpy as np
from shapely.geometry import LineString, Point, Polygon, MultiLineString, box as sbox
from shapely.ops import unary_union
from shapely.strtree import STRtree
from shapely import affinity

sys.stdout.reconfigure(encoding='utf-8')
import geo

LINE_W = 0.45
DASH_ON, DASH_OFF = 9.0, 18.0
CENTRE_W = 0.45
YELLOW_W = 0.45
ZEBRA_L, ZEBRA_BAR, ZEBRA_PITCH = 12.0, 1.6, 3.2
STOP_W, STOP_GAP = 1.2, 3.0
GIVE_ON, GIVE_OFF, GIVE_W = 1.8, 1.8, 0.6
HATCH_W, HATCH_PITCH = 0.6, 3.0
BOX_GROW = 1.5


def runs(mask):
    out, i, n = [], 0, len(mask)
    while i < n:
        if not mask[i]:
            i += 1
            continue
        j = i
        while j + 1 < n and mask[j + 1]:
            j += 1
        out.append((i, j))
        i = j + 1
    return out


def offset_line(s, off_f, rng):
    pts = []
    for i in rng:
        q = s[i]
        rx, rz = -q[4], q[3]
        o = off_f(q)
        pts.append((q[0] + rx * o, q[2] + rz * o))
    return LineString(pts) if len(pts) >= 2 else None


def strip(s, lo_f, hi_f, rng):
    A, B = [], []
    for i in rng:
        q = s[i]
        rx, rz = -q[4], q[3]
        A.append((q[0] + rx * lo_f(q), q[2] + rz * lo_f(q)))
        B.append((q[0] + rx * hi_f(q), q[2] + rz * hi_f(q)))
    if len(A) < 2:
        return None
    pg = Polygon(A + B[::-1])
    return pg if pg.is_valid else pg.buffer(0)


def dashes(line, on, off, phase=0.0):
    out = []
    L = line.length
    t = -phase
    while t < L:
        a, b = max(0.0, t), min(L, t + on)
        if b - a > 0.5:
            out.append(substring(line, a, b))
        t += on + off
    return out


def substring(line, a, b):
    from shapely.ops import substring as ss
    return ss(line, a, b)


def lines_of(g):
    if g is None or g.is_empty:
        return []
    if g.geom_type == 'LineString':
        return [g]
    if hasattr(g, 'geoms'):
        out = []
        for x in g.geoms:
            out.extend(lines_of(x))
        return out
    return []


def polys_of(g):
    if g is None or g.is_empty:
        return []
    if g.geom_type == 'Polygon':
        return [g]
    if hasattr(g, 'geoms'):
        out = []
        for x in g.geoms:
            out.extend(polys_of(x))
        return out
    return []


class Clip:
    """a big clip area as an STRtree of its pieces: a line is cut only by the pieces it touches (17 Nov: one city-wide
    union per dash made paint run for hours on 12 districts)"""
    def __init__(self, *gs):
        self.polys = [p for g in gs for p in (g.polys if isinstance(g, Clip) else polys_of(g))]
        self.tree = STRtree(self.polys) if self.polys else None
        self.is_empty = not self.polys

    def local(self, g):
        if self.tree is None:
            return Polygon()
        hit = [self.polys[int(j)] for j in self.tree.query(g)]
        return unary_union(hit) if hit else Polygon()

    def intersects(self, g):
        return self.tree is not None and any(self.polys[int(j)].intersects(g) for j in self.tree.query(g))


class Paint:
    def __init__(self):
        self.items = []

    def poly(self, kind, pg, what, road=None, deck=False):
        for p in polys_of(pg):
            if p.area < 0.05:
                continue
            c = [[round(x, 2), round(z, 2)] for x, z in list(p.exterior.coords)[:-1]]
            it = dict(k=kind, p=c, w=what)
            if road:
                it['r'] = road
            if deck:
                it['deck'] = True
            self.items.append(it)

    def line(self, kind, ln, width, what, road=None, clip=None, deck=False):
        for l in lines_of(ln):
            if clip is not None and not clip.is_empty:
                l2 = l.difference(clip.local(l) if isinstance(clip, Clip) else clip)
            else:
                l2 = l
            for x in lines_of(l2):
                if x.length < 0.6:
                    continue
                self.poly(kind, x.buffer(width / 2, cap_style=2, join_style=2), what, road, deck)


def build(data, signals=None):
    P = Paint()
    roads = data['roads']
    cut = {k: set(v) for k, v in data['cut'].items()}
    rings = data.get('roundabouts', [])
    main = [r for r in roads if r['kind'] in ('route', 'side')]
    # carriageways (built samples)
    cw = {}
    for r in roads:
        s = r['s']
        c = cut.get(r['name'], set())
        parts = []
        for a, b in runs([i not in c for i in range(len(s))]):
            if b > a:
                parts.append(strip(s, lambda q: -q[6], lambda q: q[7], range(a, b + 1)))
        cw[r['name']] = unary_union([p for p in parts if p]) if parts else Polygon()
    names = [r['name'] for r in roads]
    geoms = [cw[n] for n in names]
    tree = STRtree(geoms)
    R = {r['name']: r for r in roads}
    # junction boxes: overlaps of two main roads' carriageways (+ every ring)
    boxes = []
    for r in main:
        g = cw[r['name']]
        if g.is_empty:
            continue
        for j in tree.query(g):
            o = roads[int(j)]
            if o['name'] == r['name'] or o['kind'] not in ('route', 'side') or o['rank'] < r['rank']:
                continue
            # a side lane starting on its road's end is not a junction
            if r.get('name') in (o.get('startsOnEnd'), o.get('endsOnEnd')) or o['name'] in (r.get('startsOnEnd'), r.get('endsOnEnd')):
                continue
            x = g.intersection(cw[o['name']])
            if not x.is_empty and x.area > 20:
                boxes.append(x.convex_hull)
    box_u = unary_union(boxes).buffer(BOX_GROW) if boxes else Polygon()
    main_names = [r['name'] for r in main]
    main_tree = STRtree([cw[n] for n in main_names])
    sxz = {r['name']: np.array([(q[0], q[2]) for q in r['s']]) for r in main}
    ring_disks = unary_union([Point(g['c'][0], g['c'][2]).buffer(g['r_out'] + 0.5, 96) for g in rings]) if rings else Polygon()
    no_paint = box_u.union(ring_disks)
    # zebras / stop lines per main x main box
    zebra_zone = []
    sig = [Point(x, z) for x, z in (signals or [])]
    for bx in polys_of(box_u):
        signalled = any(bx.distance(p) < 60 for p in sig)
        for j in main_tree.query(bx):
            r = main[int(j)]
            g = cw[r['name']]
            if not g.intersects(bx):
                continue
            s = r['s']
            n = len(s)
            c = cut.get(r['name'], set())
            x0, z0, x1, z1 = bx.bounds
            P_ = sxz[r['name']]
            near = (P_[:, 0] > x0 - 1) & (P_[:, 0] < x1 + 1) & (P_[:, 1] > z0 - 1) & (P_[:, 1] < z1 + 1)
            inb = [bool(near[i]) and (bx.contains(Point(q[0], q[2])) or bx.distance(Point(q[0], q[2])) < 0.5) for i, q in enumerate(s)]
            for a, b in runs(inb):
                for side, k0, step in ((-1, a - 1, -1), (1, b + 1, 1)):
                    # walk out of the box along the road; the arm must go on 30 studs
                    k = k0
                    if k < 0 or k >= n or k in c:
                        continue
                    # first sample whose whole cross-section is outside the box
                    while 0 <= k < n and k not in c:
                        q = s[k]
                        rx, rz = -q[4], q[3]
                        L = Point(q[0] - rx * q[6], q[2] - rz * q[6])
                        Rr = Point(q[0] + rx * q[7], q[2] + rz * q[7])
                        if not bx.intersects(LineString([L, Rr])):
                            break
                        k += step
                    if not (0 <= k < n) or k in c:
                        continue
                    # chainage along the road from k outward
                    pts = []
                    kk = k
                    while 0 <= kk < n and kk not in c and len(pts) < 8:
                        pts.append(kk)
                        kk += step
                    if len(pts) < 5:
                        continue
                    line = LineString([(s[i][0], s[i][2]) for i in pts])
                    if line.length < 30:
                        continue
                    z0, z1 = 2.0, 2.0 + ZEBRA_L
                    zline = substring(line, z0, z1)
                    q = s[k]
                    D = np.array([q[3], q[4]])
                    if step < 0:
                        D = -D
                    rgt = np.array([-q[4], q[3]])
                    half_l, half_r, mb = q[6], q[7], q[8]
                    # bars across, each ZEBRA_L long along the road
                    zp = []
                    o = -half_l + 1.0
                    while o + ZEBRA_BAR <= half_r - 1.0 + 1e-6:
                        if not (abs(o) < mb + 0.3 or abs(o + ZEBRA_BAR) < mb + 0.3 or (o < 0 < o + ZEBRA_BAR and mb > 0)):
                            a0 = np.array(zline.coords[0]) + rgt * o
                            a1 = np.array(zline.coords[-1]) + rgt * o
                            b0 = a0 + rgt * ZEBRA_BAR
                            b1 = a1 + rgt * ZEBRA_BAR
                            zp.append(Polygon([a0, a1, b1, b0]))
                        o += ZEBRA_PITCH
                    if r['kind'] == 'route' and (signalled or True):
                        P.poly('LY', unary_union(zp), 'zebra', r['name'])
                        zebra_zone.append(strip(s, lambda q: -q[6] - 1, lambda q: q[7] + 1, sorted(pts[:4])) )
                    # stop line on the approach lanes, signalled junctions only
                    if signalled:
                        sp = np.array(zline.coords[-1]) + D * (STOP_GAP)
                        # approach side: traffic heading into the box. Walking outward along +step, the box is behind:
                        # the forward lanes (right side) head into it when step < 0
                        lo, hi = (max(mb, 0.0), half_r - 0.5) if step < 0 else (-half_l + 0.5, -max(mb, 0.0))
                        if r.get('oneway'):
                            lo, hi = (-half_l + 0.5, half_r - 0.5) if step < 0 else (0, 0)
                        if hi - lo > 2:
                            a0 = sp + rgt * lo
                            a1 = sp + rgt * hi
                            b0 = a0 + D * STOP_W
                            b1 = a1 + D * STOP_W
                            P.poly('LW', Polygon([a0, a1, b1, b0]), 'stop', r['name'])
                            zebra_zone.append(Polygon([a0 - D * 0.5, a1 - D * 0.5, b1 + D * 6, b0 + D * 6]).buffer(0.5))
    zz = unary_union([z for z in zebra_zone if z is not None]) if zebra_zone else Polygon()
    clip_all = Clip(no_paint, zz)
    # mouths of smaller roads on each main road (lane lines break there)
    for r in main:
        s = r['s']
        n = len(s)
        c = cut.get(r['name'], set())
        built = [i not in c for i in range(n)]
        g = cw[r['name']]
        mouths = []
        for j in tree.query(g):
            o = roads[int(j)]
            if o['name'] == r['name'] or o['rank'] < r['rank']:
                continue
            x = g.intersection(cw[o['name']])
            if not x.is_empty and x.area > 4:
                mouths.append(cw[o['name']].buffer(4))
        mouth_u = unary_union(mouths) if mouths else Polygon()
        clip_road = Clip(clip_all, mouth_u) if mouths else clip_all
        deck = False
        for a, b in runs(built):
            if b - a < 2:
                continue
            rng = range(a, b + 1)
            q0 = s[a]
            lm = max(q[11] for q in s[a:b + 1])
            one = r.get('oneway')
            # yellow lines along the built median
            mbm = [s[i][8] > 0.3 for i in rng]
            for m0, m1 in runs(mbm):
                if m1 - m0 < 2:
                    continue
                sub = range(a + m0, a + m1 + 1)
                for sg in (-1, 1):
                    ln = offset_line(s, lambda q, sg=sg: sg * (q[8] + 0.6), sub)
                    P.line('LY', ln, YELLOW_W, 'median', r['name'], clip_all)
            # centre: undivided two-way
            if not one:
                und = [s[i][11] < 1.2 for i in rng]
                for u0, u1 in runs(und):
                    if u1 - u0 < 2:
                        continue
                    ln = offset_line(s, lambda q: 0.0, range(a + u0, a + u1 + 1))
                    P.line('LW', ln, CENTRE_W, 'centre', r['name'], clip_all)
            # lane dividers
            nmax = max(q[9] for q in s[a:b + 1])
            for k in range(1, int(nmax)):
                for sg in ((1,) if one else (-1, 1)):
                    def off(q, k=k, sg=sg):
                        n_ = max(1, q[9])
                        if k >= n_:
                            return None
                        if one:
                            W = (q[6] + q[7]) / n_
                            return -q[6] + W * k
                        half = q[7] if sg > 0 else q[6]
                        W = min(q[10], (half - q[11]) / n_)
                        return sg * (q[11] + W * k)
                    seg = [off(s[i]) is not None for i in rng]
                    for v0, v1 in runs(seg):
                        if v1 - v0 < 2:
                            continue
                        ln = offset_line(s, off, range(a + v0, a + v1 + 1))
                        for d in dashes(ln, DASH_ON, DASH_OFF):
                            P.line('LW', d, LINE_W, 'lane', r['name'], clip_road)
    # roundabouts
    for g in rings:
        C = np.array([g['c'][0], g['c'][2]])
        W = g['laneW']
        circle_clip = Polygon()
        # entries: each arm end in the ring
        arms = [R[a] for a in g['arms'] if a in R]
        entry_zone = []
        for o in arms:
            s = o['s']
            for end in (0, -1):
                q = s[end]
                if np.linalg.norm(np.array([q[0], q[2]]) - C) > g['r_out']:
                    continue
                # the sample where the arm crosses r_out + 1.5
                idx = range(len(s)) if end == 0 else range(len(s) - 1, -1, -1)
                k = None
                for i in idx:
                    if np.linalg.norm(np.array([s[i][0], s[i][2]]) - C) > g['r_out'] + 1.5:
                        k = i
                        break
                if k is None:
                    continue
                q = s[k]
                rgt = np.array([-q[4], q[3]])
                D = np.array([q[3], q[4]]) * (1 if end == -1 else -1)   # towards the ring
                lm = q[11]
                if o.get('oneway'):
                    lo, hi = (-q[6], q[7]) if end == -1 else (0, 0)
                else:
                    lo, hi = (max(lm, 0.3), q[7]) if end == -1 else (-q[6], -max(lm, 0.3))
                if hi - lo > 2:
                    base = np.array([q[0], q[2]])
                    t = lo + 0.4
                    gp = []
                    while t + GIVE_ON <= hi - 0.4:
                        a0 = base + rgt * t
                        a1 = base + rgt * (t + GIVE_ON)
                        gp.append(Polygon([a0, a1, a1 + D * GIVE_W, a0 + D * GIVE_W]))
                        t += GIVE_ON + GIVE_OFF
                    P.poly('LW', unary_union(gp), 'giveway', o['name'])
                # hatched splitter on a divided arm: from the ring to the median's nose
                if lm > 1.2:
                    j = k
                    step = 1 if end == 0 else -1
                    while 0 <= j < len(s) and s[j][8] < 0.3 and abs(j - k) < 40:
                        j += step
                    sub = sorted(range(min(k, j), max(k, j) + 1))
                    sp = strip(s, lambda q: -q[11], lambda q: q[11], sub)
                    # cut it off at the ring
                    if sp is not None:
                        sp = sp.difference(Point(*C).buffer(g['r_out'] + 0.5, 96))
                        hatch(P, sp, o['name'])
        # ring lane lines (dashed circles), broken where arms enter
        mouths = unary_union([cw[a.get('name')].buffer(2) for a in arms]) if arms else Polygon()
        for k in range(1, g['lanes']):
            rr = g['r_in'] + W * k
            ring = Point(*C).buffer(rr, 128).exterior
            ln = LineString(ring.coords)
            for d in dashes(ln, DASH_ON, DASH_OFF):
                P.line('LW', d, LINE_W, 'ring lane', g['name'])
    # decks: 2 + 2, a solid white centre line and dashed lane lines (no zebras, no boxes up there)
    for d in data.get('decks', []):
        s = d['s']
        rng = range(len(s))
        P.line('LW', offset_line(s, lambda q: 0.0, rng), CENTRE_W, 'deck centre', d['name'], None, deck=True)
        for sg in (-1, 1):
            ln = offset_line(s, lambda q, sg=sg: sg * q[10], rng)
            for dd in dashes(ln, DASH_ON, DASH_OFF):
                P.line('LW', dd, LINE_W, 'deck lane', d['name'], None, deck=True)
    # turn arrows
    for r in main:
        for t in r.get('turn', []):
            arrows(P, r, t, clip_all)
    return P


def hatch(P, pg, road):
    for p in polys_of(pg):
        if p.area < 4:
            continue
        ring = list(p.exterior.coords)
        h = len(ring) // 2
        for part in (ring[:h + 1], ring[h:]):
            if len(part) >= 2:
                P.line('LY', LineString(part), YELLOW_W, 'hatch edge', road)
        # a narrow splitter (under 4 studs): its two edges only
        if p.minimum_rotated_rectangle.length < 0 or min_width(p) < 4:
            continue
        minx, miny, maxx, maxy = p.bounds
        d = max(maxx - minx, maxy - miny) * 2
        cx, cy = (minx + maxx) / 2, (miny + maxy) / 2
        t = -d
        while t < d:
            ln = LineString([(cx + t - d, cy - d), (cx + t + d, cy + d)])
            x = ln.intersection(p.buffer(-0.6))
            for l in lines_of(x):
                P.line('LY', l, HATCH_W, 'hatch', road)
            t += HATCH_PITCH * math.sqrt(2)


def min_width(p):
    r = p.minimum_rotated_rectangle
    c = list(r.exterior.coords)
    a = math.dist(c[0], c[1])
    b = math.dist(c[1], c[2])
    return min(a, b)


ARROW = {  # unit arrow shapes (x across, y along, pointing +y), studs
    'through': [(-0.25, 0), (0.25, 0), (0.25, 4.2), (0.75, 4.2), (0, 6), (-0.75, 4.2), (-0.25, 4.2)],
}


def arrows(P, r, t, clip):
    s = r['s']
    i = t['i']
    if i < 0 or i >= len(s):
        return
    q = s[i]
    D = np.array([q[3], q[4]]) * t['dir']
    rgt = np.array([-q[4], q[3]]) * t['dir']
    base = np.array([q[0], q[2]])
    for lane, kinds in enumerate(t['lanes']):
        off = t['offs'][lane]
        c = base + rgt * off
        for kind in kinds.split(';'):
            shape = arrow_shape(kind)
            if shape is None:
                continue
            pts = [c + rgt * x * 1.0 + D * y * 1.0 for x, y in shape]
            pg = Polygon(pts).buffer(0)
            if clip is not None and (clip.intersects(pg) if isinstance(clip, Clip) else pg.intersects(clip)):
                continue
            P.poly('LW', pg, 'arrow', r['name'])


def arrow_shape(kind):
    kind = kind.strip()
    if kind in ('through', ''):
        return [(-0.25, 0), (0.25, 0), (0.25, 4.2), (0.75, 4.2), (0, 6), (-0.75, 4.2), (-0.25, 4.2)]
    if kind in ('left', 'slight_left', 'sharp_left'):
        return [(0.25, 0), (0.75, 0), (0.75, 3.6), (-1.2, 3.6), (-1.2, 4.3), (-2.2, 3.35), (-1.2, 2.4), (-1.2, 3.1), (0.25, 3.1)]
    if kind in ('right', 'slight_right', 'sharp_right'):
        return [(-0.25, 0), (-0.75, 0), (-0.75, 3.6), (1.2, 3.6), (1.2, 4.3), (2.2, 3.35), (1.2, 2.4), (1.2, 3.1), (-0.25, 3.1)]
    if kind in ('reverse',):
        return None
    return None


ORDER = ['stop', 'zebra', 'giveway', 'centre', 'deck centre', 'median', 'lane', 'deck lane', 'ring lane', 'hatch edge',
         'hatch', 'arrow']


def tidy(data, items):
    """final pass (17 Nov, paint QA: paint_off 438, zebra_median 129, stack_paint 89): every polygon clipped to its own
    surface (ground paint to the carriageways and rings, deck paint to the decks), off the medians, and never on a
    polygon laid before it (ORDER: stop lines and zebras first, arrows last): no paint off the asphalt, none on a
    median, no two paint polygons on one spot (they would z-fight)"""
    from roads05_qa import quads
    cut = {k: set(v) for k, v in data['cut'].items()}
    ground, med = [], []
    for r in data['roads']:
        c = cut.get(r['name'], ())
        ground.extend(quads(r['s'], c))
        if any(q[8] > 0 for q in r['s']):
            med.extend(quads(r['s'], c, inner=8))
    for g in data['roundabouts']:
        ground.append(Point(g['c'][0], g['c'][2]).buffer(g['r_out'], 96))
    deck = []
    for d in data['decks']:
        deck.extend(quads(d['s']))
    G, M, D = Clip(*ground), Clip(*med), Clip(*deck)
    rank = {w: i for i, w in enumerate(ORDER)}
    order = sorted(range(len(items)), key=lambda i: rank.get(items[i]['w'], len(ORDER)))
    kept = {}
    CELL = 64.0
    out = []
    st = dict(clipped=0, dropped=0, split=0)

    def cells(b):
        for i in range(int(math.floor(b[0] / CELL)), int(math.floor(b[2] / CELL)) + 1):
            for j in range(int(math.floor(b[1] / CELL)), int(math.floor(b[3] / CELL)) + 1):
                yield (i, j)
    for idx in order:
        it = items[idx]
        P = Polygon(it['p'])
        if not P.is_valid:
            P = P.buffer(0)
        a0 = P.area
        surf = D if it.get('deck') else G
        Q = P.intersection(surf.local(P).buffer(-0.05))
        if not it.get('deck') and not M.is_empty:
            Q = Q.difference(M.local(Q).buffer(0.05)) if not Q.is_empty else Q
        near = []
        for c in cells(P.bounds):
            near.extend(kept.get(c, ()))
        near = [k for k in set(near) if k.intersects(Q)] if not Q.is_empty else []
        if near:
            Q = Q.difference(unary_union(near).buffer(0.05))
        ps = [p for p in polys_of(Q) if p.area >= 0.3 and not p.interiors and p.area / max(p.length, 1e-6) > 0.1]
        if abs(sum(p.area for p in ps) - a0) > 0.05:
            st['clipped'] += 1
        if not ps:
            st['dropped'] += 1
            continue
        if len(ps) > 1:
            st['split'] += 1
        for p in ps:
            p = p.simplify(0.01)
            c = [[round(x, 2), round(z, 2)] for x, z in list(p.exterior.coords)[:-1]]
            n = dict(it, p=c)
            out.append(n)
            for cc in cells(p.bounds):
                kept.setdefault(cc, []).append(p)
    return out, st



def signals_of(region_poly):
    out = []
    for r in geo.load('points'):
        if r.get('v') == 'traffic_signals' and r.get('k') == 'highway':
            x, z = geo.world(r['p'][0], r['p'][1])
            if region_poly.buffer(50).contains(Point(x, z)):
                out.append((x, z))
    return out


if __name__ == '__main__':
    tag = sys.argv[1]
    od = os.path.join(geo.BUILD, 'city_1to1', 'roads05_' + tag)
    data = json.load(open(os.path.join(od, 'roads.json'), encoding='utf-8'))
    region = unary_union([geo.batch_poly(t) for t in data['tags']])
    sig = signals_of(region)
    P = build(data, sig)
    P.items, tst = tidy(data, P.items)
    print('tidy', tst)
    kinds = {}
    for it in P.items:
        kinds[it['w']] = kinds.get(it['w'], 0) + 1
    json.dump(dict(items=P.items, signals=sig), open(os.path.join(od, 'paint.json'), 'w'))
    print(len(P.items), kinds, 'signals', len(sig))
