"""Road markings for roads05 data, as real Yangon ones (16 Nov 2026; vault "Audit - Yangon roads 1 to 1" items 3, 9-12 and
"Research - Yangon road look"), as paint polygons the preview draws and the Studio build lays (0.08 over the road):

  * lane lines: white, dashed 3 m on / 6 m off (9 / 18 studs), 0.15 m wide (0.45 studs); none on small streets (real
    residential streets are unmarked). (J15) One smooth offset per boundary: the lane count is a 9-sample median, each
    line moves at most LANE_RATE sideways per stud, so a new lane tapers out of the kerb (no jogs, no side-by-side
    dashes); all lines are Chaikin-smoothed (no sample corners); clipped pieces under 3 studs are dropped
  * centre: one solid white line on an undivided main road (never broken by a smaller road's mouth)
  * yellow kerb lines (J15, owner ref 'Sule Square road'): along every kerb of a main road, outer and median, 0.9 in
  * junction boxes (where two main roads' carriageways overlap): nothing painted inside; (J15) two parallel roads under
    40 studs apart crossing one road make ONE box (owner ref 'double junction zebras and stop lines'), and each road's
    stretch from the box to its arm's zebra is box too (ref 'junction box grass hole')
  * mouths: a main road's lane lines break across a smaller road's mouth (RoadLines clearMouths); the centre line runs on
  * zebras: faded ochre LZ (230, 190, 110), 12 studs long, 1.6-stud bars on a 3.2 pitch, across each arm of a route just
    outside its box; (J15) whole bars only (none cut by a kerb, a box, a median nose or another arm's zebra)
  * stop lines (J15: every approach): white, 1.2 studs, across the incoming lanes only (centre line / median .. kerb),
    3 studs before the zebra on the approach side, stepped back where another arm's zebra lies
  * roundabouts: dashed lane lines round the ring, a white dashed give-way line across each entry, yellow hatched
    splitters between an arm's entry and exit where it is divided
  * turn arrows (J15): one per incoming lane at every stop line, 8 studs behind it, for the turns the box offers
    (leftmost lane left, rightmost right, all through where it goes on); OSM turn:lanes where the lane count fits
  * paint stops short of median noses and islands (nose caps in tidy)
  QA: roads05_paint_qa.py (J15 rules) besides roads05_qa.py --paint-only.

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
DOUBLE_GAP = 40.0     # (J15) two parallel roads closer than this crossing one road: ONE box
CLOSE_GAP = 60.0      # (J15) two junctions closer than this along one road: ONE box
LANE_RATE = 0.08      # (J15) a lane line moves at most this many studs sideways per stud along (a taper, never a jog)
EDGE_IN = 0.9         # (J15) yellow kerb lines: middle this far in from the kerb
ARROW_S = 2.0         # (J15) arrows 12 studs long (real ones ~5 m)
ARROW_L = 6.0 * ARROW_S
ARROW_BACK = 8.0      # (J15) arrow tip this far behind the stop line
MIN_PIECE = 3.0       # (J15) a clipped lane / edge piece shorter than this is dropped (clean line ends)


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
    return smooth(pts)


def smooth(pts, it=2):
    """(J15, paint_snake) Chaikin corner cutting, ends kept: lines follow a smooth curve, not the 8-stud sample polygon"""
    pts = [tuple(p) for p in pts]
    if len(pts) < 2:
        return None
    for _ in range(it):
        if len(pts) < 3:
            break
        out = [pts[0]]
        for (x0, z0), (x1, z1) in zip(pts[:-1], pts[1:]):
            out.append((0.75 * x0 + 0.25 * x1, 0.75 * z0 + 0.25 * z1))
            out.append((0.25 * x0 + 0.75 * x1, 0.25 * z0 + 0.75 * z1))
        out.append(pts[-1])
        pts = out
    return LineString(pts)


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


class Grid:
    """polygons laid so far, by 64-stud cell"""
    def __init__(self):
        self.cells = {}

    def _cells(self, b):
        for i in range(int(math.floor(b[0] / 64)), int(math.floor(b[2] / 64)) + 1):
            for j in range(int(math.floor(b[1] / 64)), int(math.floor(b[3] / 64)) + 1):
                yield (i, j)

    def add(self, g):
        for c in self._cells(g.bounds):
            self.cells.setdefault(c, []).append(g)

    def hits(self, g, d):
        return any(x.distance(g) < d for c in self._cells(g.buffer(d).bounds) for x in self.cells.get(c, ()))


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

    def line(self, kind, ln, width, what, road=None, clip=None, deck=False, min_len=0.6):
        for l in lines_of(ln):
            if clip is not None and not clip.is_empty:
                l2 = l.difference(clip.local(l) if isinstance(clip, Clip) else clip)
            else:
                l2 = l
            for x in lines_of(l2):
                if x.length < min_len:
                    continue
                self.poly(kind, x.buffer(width / 2, cap_style=2, join_style=2), what, road, deck)


def neff(q, one):
    """(J14, owner: no bare asphalt strip wider than one lane without a line) the lanes painted at sample q: the data's
    lanes a side, more where a direction's asphalt holds more 12-stud lanes (a parking shoulder gets its own line)"""
    span = (q[6] + q[7]) if one else ((q[6] if q[8] > 0.3 else (q[6] + q[7]) / 2) - q[11])
    return max(1, int(q[9]), int(round(span / 12.0)))


def raw_boxes(roads, main, cw, tree):
    """overlaps of two main roads' carriageways: [(hull, bigger road, smaller road)]"""
    out = []
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
                out.append((x.convex_hull, r['name'], o['name']))
    return out


def heading_at(r, pt):
    s = r['s']
    S = np.array([(q[0], q[2]) for q in s])
    i = int(np.argmin(((S - np.asarray(pt)) ** 2).sum(1)))
    return np.array([s[i][3], s[i][4]])


def double_pairs(raw, R, parallel=True, gap=DOUBLE_GAP):
    """(J15, owner ref 'double junction zebras and stop lines') pairs of boxes (i, j) where two parallel roads under
    DOUBLE_GAP apart cross one road (a dual carriageway as two one-ways, two streets side by side)"""
    out = []
    tr = STRtree([b[0] for b in raw]) if raw else None
    for i, (h, a, b) in enumerate(raw):
        for j in tr.query(h.buffer(gap)):
            j = int(j)
            if j <= i:
                continue
            h2, c, d = raw[j]
            sh = {a, b} & {c, d}
            if len(sh) != 1 or h.distance(h2) > gap:
                continue
            x, y = ({a, b} - sh).pop(), ({c, d} - sh).pop()
            if x == y:
                continue
            if parallel and abs(heading_at(R[x], h.centroid.coords[0]) @ heading_at(R[y], h2.centroid.coords[0])) < 0.9:
                continue
            out.append((i, j))
    return out


def merged_boxes(raw, R):
    """the junction boxes: each double pair joined into ONE box (the hull of both: nothing painted between them)"""
    par = list(range(len(raw)))

    def f(i):
        while par[i] != i:
            par[i] = par[par[i]]
            i = par[i]
        return i
    # double junctions, and (J15) any two junctions under CLOSE_GAP apart along one road (a short link between them
    # has no room for two zebras, stop lines and arrows: real ones are one box)
    pairs = double_pairs(raw, R) + double_pairs(raw, R, parallel=False, gap=CLOSE_GAP)
    for i, j in pairs:
        par[f(i)] = f(j)
    groups = {}
    for i in range(len(raw)):
        groups.setdefault(f(i), []).append(raw[i][0])
    return [unary_union(g).convex_hull if len(g) > 1 else g[0] for g in groups.values()], len(pairs)


def limit_rate(t, ds, rate):
    for i in range(1, len(t)):
        t[i] = min(max(t[i], t[i - 1] - rate * ds[i]), t[i - 1] + rate * ds[i])
    for i in range(len(t) - 2, -1, -1):
        t[i] = min(max(t[i], t[i + 1] - rate * ds[i + 1]), t[i + 1] + rate * ds[i + 1])
    return t


def lane_lines(s, a, b, one):
    """(J15, owner ref 'road markings messed up 5': dashes jogging sideways and side by side where a lane starts) the
    lane structure of built samples a..b, per side sg: (inner, outer, n, [line k offsets (nan = no line)]). Each line is
    spread evenly over its direction's half (J14) but moves at most LANE_RATE studs sideways per stud along: where a
    lane is added it tapers out of the kerb, where one ends it tapers into it (one offset per boundary, never a jump)"""
    idx = list(range(a, b + 1))
    Q = [s[i] for i in idx]
    ds = [0.0] + [math.hypot(Q[i][0] - Q[i - 1][0], Q[i][2] - Q[i - 1][2]) for i in range(1, len(Q))]
    out = {}
    for sg in ((1,) if one else (-1, 1)):
        inner, outer, nn = [], [], []
        for q in Q:
            if one:
                lo, hi = -q[6], q[7]
            elif q[8] > 0.3:
                lo, hi = (q[11], q[7]) if sg > 0 else (-q[11], -q[6])
            else:
                c0 = (q[7] - q[6]) / 2
                lo, hi = c0 + sg * q[11], (q[7] if sg > 0 else -q[6])
            inner.append(lo)
            outer.append(hi)
            nn.append(neff(q, one))
        inner, outer, nn = np.array(inner), np.array(outer), np.array(nn)
        # lane count: the median over 9 samples (a width near x.5 lanes flipped it every sample: snaking lines)
        nn = np.array([int(np.median(nn[max(0, j - 4):j + 5])) for j in range(len(nn))])
        lines = []
        for k in range(1, int(nn.max())):
            t = np.where(k < nn, inner + (outer - inner) * k / nn, outer)
            t = np.convolve(np.pad(t.astype(float), 4, mode='edge'), np.ones(9) / 9, mode='valid')
            t = limit_rate(t, ds, LANE_RATE)
            # never off the asphalt where the kerb pulls in faster than the line may move
            t = np.where(outer > inner, np.minimum(np.maximum(t, inner + 1.5), outer), np.maximum(np.minimum(t, inner - 1.5), outer))
            lines.append(np.where(np.abs(t - outer) > 1.5, t, np.nan))
        # (J15, dash_side_by_side) where a lane ends its line tapers out while the next one spreads: a line closer
        # than 4 studs to the one inside it gives way (never two dashes side by side)
        for k in range(len(lines) - 1, -1, -1):
            prev = lines[k - 1] if k > 0 else inner
            close = np.abs(lines[k] - np.where(np.isnan(prev), inner, prev)) < 4.0
            lines[k] = np.where(close, np.nan, lines[k])
        out[sg] = (inner, outer, nn, lines)
    return idx, out


def bounds_at(LL, name, i, sg):
    """lane boundaries (inner .. outer: left to right for the driver) at sample i on side sg, or None"""
    for idx, out in LL.get(name, ()):
        if idx[0] <= i <= idx[-1] and sg in out:
            j = i - idx[0]
            inner, outer, nn, lines = out[sg]
            return [inner[j]] + [ln[j] for k, ln in enumerate(lines) if k + 1 < nn[j] and not np.isnan(ln[j])] + [outer[j]]
    return None


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
    # lane structure of every main road (lane lines, stop lines and arrows share it)
    LL = {}
    for r in main:
        s = r['s']
        c = cut.get(r['name'], set())
        for a, b in runs([i not in c for i in range(len(s))]):
            if b - a >= 2:
                LL.setdefault(r['name'], []).append(lane_lines(s, a, b, bool(r.get('oneway'))))
    # junction boxes: overlaps of two main roads' carriageways (double junctions joined), + every ring
    raw = raw_boxes(roads, main, cw, tree)
    boxes, ndouble = merged_boxes(raw, R)
    box_u = unary_union(boxes).buffer(BOX_GROW) if boxes else Polygon()
    main_names = [r['name'] for r in main]
    main_tree = STRtree([cw[n] for n in main_names])
    sxz = {r['name']: np.array([(q[0], q[2]) for q in r['s']]) for r in main}
    ring_disks = unary_union([Point(g['c'][0], g['c'][2]).buffer(g['r_out'] + 0.5, 96) for g in rings]) if rings else Polygon()
    no_paint = box_u.union(ring_disks)
    # arms: every main road leaving every box (first sample whose whole cross-section is outside it)
    arms = []
    arm_fill = []
    box_roads = {}
    for bi, bx in enumerate(polys_of(box_u)):
        for j in main_tree.query(bx.buffer(30)):
            r = main[int(j)]
            touches = cw[r['name']].intersects(bx)
            if touches:
                box_roads.setdefault(bi, []).append((r, bx))
            s = r['s']
            n = len(s)
            c = cut.get(r['name'], set())
            x0, z0, x1, z1 = bx.bounds
            P_ = sxz[r['name']]
            near = (P_[:, 0] > x0 - 1) & (P_[:, 0] < x1 + 1) & (P_[:, 1] > z0 - 1) & (P_[:, 1] < z1 + 1)
            inb = [bool(near[i]) and (bx.contains(Point(q[0], q[2])) or bx.distance(Point(q[0], q[2])) < 0.5) for i, q in enumerate(s)]
            ex = [(a, b, ((a - 1, -1), (b + 1, 1))) for a, b in runs(inb)] if touches else []
            if not ex:
                # (J16 Studio test, Pazundaung Y) a road ENDING at the box (a continuation meeting it, its centre line
                # never inside): its arm leaves from its end
                e = min((0, n - 1), key=lambda i: bx.distance(Point(s[i][0], s[i][2])))
                if bx.distance(Point(s[e][0], s[e][2])) < max(s[e][6], s[e][7]) + 30 and e not in c:
                    ex = [(e, e, ((e + 1, 1),) if e == 0 else ((e - 1, -1),))]
            for a, b, sides in ex:
                for k0, step in sides:
                    k = k0
                    if k < 0 or k >= n or k in c:
                        continue
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
                    # (J15, owner ref 'junction box grass hole') the road from the box to its arm's zebra is box too
                    k_in = k0 - step
                    if abs(k - k_in) >= 1:
                        arm_fill.append(strip(s, lambda q: -q[6], lambda q: q[7], range(min(k, k_in), max(k, k_in) + 1)))
                    pts = []
                    kk = k
                    while 0 <= kk < n and kk not in c and len(pts) < 10:
                        pts.append(kk)
                        kk += step
                    if len(pts) < 5:
                        continue
                    line = LineString([(s[i][0], s[i][2]) for i in pts])
                    if line.length < 30:
                        continue
                    D = np.array([s[k][3], s[k][4]]) * (-1 if step < 0 else 1)   # outward
                    arms.append(dict(box=bi, r=r, k=k, step=step, pts=pts, line=line, D=D))
    no_paint = unary_union([no_paint] + [p for p in arm_fill if p is not None])
    by_box = {}
    for am in arms:
        by_box.setdefault(am['box'], []).append(am)
    # zebras, stop lines per arm
    zebra_zone = []
    arrow_jobs = []
    laid = Grid()           # (J15, zebra_torn) bars and stop lines laid so far: nothing is laid over another
    boxc = Clip(no_paint)
    medc = Clip(*medians(data))
    # (J16 Studio test, Pyay x University) the ground under a deck can be an open gap (cut corridor): no zebra or stop
    # line under a deck's footprint
    from roads05_qa import quads as _quads
    deckc = Clip(*[g.buffer(1.0) for d in data.get('decks', []) for g in _quads(d['s'])])
    for am in arms:
        r, k, pts, line = am['r'], am['k'], am['pts'], am['line']
        if r['kind'] != 'route':
            continue
        s = r['s']
        q = s[k]
        rgt = np.array([-q[4], q[3]])
        half_l, half_r, mb = q[6], q[7], q[8]
        zline = substring(line, 2.0, 2.0 + ZEBRA_L)
        o = -half_l + 1.0
        while o + ZEBRA_BAR <= half_r - 1.0 + 1e-6:
            # (J15) bars keep 1.3 off a median (its nose cap): no bar is cut
            if not (mb > 0.3 and (o + ZEBRA_BAR > -mb - 1.3 and o < mb + 1.3)):
                a0 = np.array(zline.coords[0]) + rgt * o
                a1 = np.array(zline.coords[-1]) + rgt * o
                bar = Polygon([a0, a1, a1 + rgt * ZEBRA_BAR, a0 + rgt * ZEBRA_BAR])
                # (J15) a whole bar or none: one the kerb would cut, inside a junction box or on another arm's zebra
                # is left out
                if (unary_union([geoms[int(j)] for j in tree.query(bar)]).buffer(-0.1).contains(bar)
                        and boxc.local(bar).intersection(bar).area < 0.1 and not laid.hits(bar, 0.3)
                        and not medc.intersects(bar.buffer(0.1)) and not deckc.intersects(bar)):
                    P.poly('LZ', bar, 'zebra', r['name'])
                    laid.add(bar)
            o += ZEBRA_PITCH
        zebra_zone.append(strip(s, lambda q: -q[6] - 1, lambda q: q[7] + 1, sorted(pts[:4])))
    for am in arms:
        r, k, step, pts, line, D = am['r'], am['k'], am['step'], am['pts'], am['line'], am['D']
        s = r['s']
        # incoming side: traffic heading into the box (right-hand traffic: the driver's right side)
        if r.get('oneway'):
            if step > 0:
                continue
            sg = 1
        else:
            sg = 1 if step < 0 else -1
        # (J15) stop line: across the incoming lanes only (centre line / median .. kerb), just before the zebra, on the
        # lane structure of the sample at the stop line itself (a flaring mouth moves the centre); moved back up to 6
        # studs where another arm's zebra lies on that spot
        for c_stop in [2.0 + ZEBRA_L + STOP_GAP + e for e in (0.0, 2.0, 4.0, 6.0)]:
            if line.length < c_stop + STOP_W + 2:
                break
            sp = np.array(line.interpolate(c_stop).coords[0])
            ks = min(pts, key=lambda i: (s[i][0] - sp[0]) ** 2 + (s[i][2] - sp[1]) ** 2)
            bd = bounds_at(LL, r['name'], ks, sg)
            if bd is None:
                break
            lo, hi = sorted((bd[0] + sg * 0.45, bd[-1] - sg * 0.5))
            if hi - lo < 2:
                break
            qs = s[ks]
            rgt = np.array([-qs[4], qs[3]])
            lat = (sp[0] - qs[0]) * rgt[0] + (sp[1] - qs[2]) * rgt[1]
            sp = sp - rgt * lat
            a0, a1 = sp + rgt * lo, sp + rgt * hi
            b0, b1 = a0 + D * STOP_W, a1 + D * STOP_W
            st = Polygon([a0, a1, b1, b0])
            if deckc.intersects(st):
                # stop at the deck's edge (cut back, one clean piece) or none
                cutd = st.difference(deckc.local(st))
                if cutd.geom_type != 'Polygon' or cutd.area < 0.5 * st.area:
                    continue
                st = cutd
            if laid.hits(st, 0.5) or boxc.local(st).intersection(st).area > 0.1:
                continue
            P.poly('LW', st, 'stop', r['name'])
            laid.add(st)
            zebra_zone.append(Polygon([a0 - D * 0.5, a1 - D * 0.5, b1 + D * 6, b0 + D * 6]).buffer(0.5))
            arrow_jobs.append(dict(am, sg=sg, c=c_stop + STOP_W + ARROW_BACK))
            break
    zz = unary_union([z for z in zebra_zone if z is not None]) if zebra_zone else Polygon()
    clip_all = Clip(no_paint, zz)
    fills = unary_union([Polygon([(p[0], p[2]) for p in f]).buffer(0) for f in data.get('fills', []) if len(f) >= 3])
    # mouths of smaller roads on each main road (lane and edge lines break there)
    for r in main:
        s = r['s']
        g = cw[r['name']]
        mouths = []
        for j in tree.query(g):
            o = roads[int(j)]
            if o['name'] == r['name']:
                continue
            x = g.intersection(cw[o['name']])
            # (J15) a smaller road lying inside this one (a doubled carriageway) is no mouth: the kerb lines run on
            if not x.is_empty and x.area > 4 and (o['rank'] < r['rank'] or cw[o['name']].difference(g.buffer(0.5)).area > 4):
                # a smaller road's mouth: lines break 4 short of it; (J15) a bigger road: none of this road's lines on it
                mouths.append(cw[o['name']].buffer(4 if o['rank'] > r['rank'] else 1))
        mouth_u = unary_union(mouths) if mouths else Polygon()
        clip_road = Clip(clip_all, mouth_u) if mouths else clip_all
        clip_edge = Clip(clip_road, fills.buffer(2)) if not fills.is_empty else clip_road
        one = bool(r.get('oneway'))
        for idx, out in LL.get(r['name'], ()):
            a, b = idx[0], idx[-1]
            rng = range(a, b + 1)
            # yellow lines along the built median, EDGE_IN from its kerb
            mbm = [s[i][8] > 0.3 for i in rng]
            for m0, m1 in runs(mbm):
                if m1 - m0 < 2:
                    continue
                sub = range(a + m0, a + m1 + 1)
                for sg in (-1, 1):
                    ln = offset_line(s, lambda q, sg=sg: sg * (q[8] + EDGE_IN), sub)
                    P.line('LY', ln, YELLOW_W, 'median', r['name'], clip_all, min_len=MIN_PIECE)
            # (J15, owner ref 'Sule Square road') a yellow edge line along each outer kerb of a main road
            edges = [(outer, -sg) for sg, (inner, outer, nn, lines) in out.items()]
            if one:
                edges.append((out[1][0], 1))
            for off, sgn in edges:
                ln = smooth([(s[i][0] - s[i][4] * (off[j] + sgn * EDGE_IN), s[i][2] + s[i][3] * (off[j] + sgn * EDGE_IN))
                             for j, i in enumerate(idx)])
                P.line('LY', ln, YELLOW_W, 'edge', r['name'], clip_edge, min_len=MIN_PIECE)
            # centre: undivided two-way, on the carriageway's middle (J14), rate-limited like the lane lines
            if not one:
                und = [s[i][11] < 1.2 and s[i][8] <= 0.3 for i in rng]
                ds = [0.0] + [math.hypot(s[i][0] - s[i - 1][0], s[i][2] - s[i - 1][2]) for i in range(a + 1, b + 1)]
                c0 = limit_rate(np.array([(s[i][7] - s[i][6]) / 2 for i in rng], float), ds, LANE_RATE)
                for u0, u1 in runs(und):
                    if u1 - u0 < 2:
                        continue
                    ln = smooth([(s[a + j][0] - s[a + j][4] * c0[j], s[a + j][2] + s[a + j][3] * c0[j]) for j in range(u0, u1 + 1)])
                    P.line('LW', ln, CENTRE_W, 'centre', r['name'], clip_all)
                # (J15) a painted median (lanes held apart, no kerbed median built): a solid line on each side of it
                flush = [s[i][11] >= 1.2 and s[i][8] <= 0.3 for i in rng]
                for u0, u1 in runs(flush):
                    if u1 - u0 < 2:
                        continue
                    for sg in (-1, 1):
                        ln = smooth([(s[a + j][0] - s[a + j][4] * (c0[j] + sg * (s[a + j][11] - 0.3)),
                                      s[a + j][2] + s[a + j][3] * (c0[j] + sg * (s[a + j][11] - 0.3))) for j in range(u0, u1 + 1)])
                        P.line('LW', ln, CENTRE_W, 'centre', r['name'], clip_all)
            # lane dividers: one smooth offset per boundary
            for sg, (inner, outer, nn, lines) in out.items():
                for t in lines:
                    for v0, v1 in runs([not np.isnan(x) for x in t]):
                        if v1 - v0 < 1:
                            continue
                        ln = smooth([(s[idx[j]][0] - s[idx[j]][4] * t[j], s[idx[j]][2] + s[idx[j]][3] * t[j]) for j in range(v0, v1 + 1)])
                        for d in dashes(ln, DASH_ON, DASH_OFF):
                            P.line('LW', d, LINE_W, 'lane', r['name'], clip_road, min_len=MIN_PIECE)
    # roundabouts
    for g in rings:
        C = np.array([g['c'][0], g['c'][2]])
        W = g['laneW']
        for o in [R[a] for a in g['arms'] if a in R]:
            s = o['s']
            for end in (0, -1):
                q = s[end]
                if np.linalg.norm(np.array([q[0], q[2]]) - C) > g['r_out']:
                    continue
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
                    if sp is not None:
                        sp = sp.difference(Point(*C).buffer(g['r_out'] + 0.5, 96))
                        hatch(P, sp, o['name'])
        # ring lane lines (dashed circles)
        for k in range(1, g['lanes']):
            rr = g['r_in'] + W * k
            ln = LineString(Point(*C).buffer(rr, 128).exterior.coords)
            for d in dashes(ln, DASH_ON, DASH_OFF):
                P.line('LW', d, LINE_W, 'ring lane', g['name'], box_u)   # (J15) none in an arm's junction box
    # decks: 2 + 2, a solid white centre line and dashed lane lines (no zebras, no boxes up there)
    for d in data.get('decks', []):
        s = d['s']
        rng = range(len(s))
        P.line('LW', offset_line(s, lambda q: 0.0, rng), CENTRE_W, 'deck centre', d['name'], None, deck=True)
        for sg in (-1, 1):
            ln = offset_line(s, lambda q, sg=sg: sg * q[10], rng)
            for dd in dashes(ln, DASH_ON, DASH_OFF):
                P.line('LW', dd, LINE_W, 'deck lane', d['name'], None, deck=True)
    # (J15) turn arrows: one per incoming lane at every approach, ARROW_BACK behind the stop line, for the turns the box
    # really offers (OSM turn:lanes where they fit)
    for job in arrow_jobs:
        approach_arrows(P, job, (by_box, box_roads), LL, clip_all)
    P.stats = dict(joined=ndouble, boxes=len(boxes), approaches=len(arrow_jobs))
    return P


def turns_of(job, boxes):
    """left / through / right the box offers an approach heading into it: its other arms, or (a T whose through road
    has no arm in the box: its carriageway only touches it) the directions of the other roads through the box"""
    by_box, box_roads = boxes
    h = -job['D']
    rgt = np.array([-h[1], h[0]])
    have = set()
    armed = {o['r']['name'] for o in by_box.get(job['box'], ())}
    for r, bx in box_roads.get(job['box'], ()):
        if r['name'] in armed or r['name'] == job['r']['name']:
            continue
        c = np.array(bx.centroid.coords[0])
        q = min(r['s'], key=lambda q: (q[0] - c[0]) ** 2 + (q[2] - c[1]) ** 2)
        for d in ([np.array([q[3], q[4]])] if r.get('oneway') else [np.array([q[3], q[4]]), -np.array([q[3], q[4]])]):
            if d @ h < -0.7:
                continue
            have.add('through' if d @ h > 0.7 else ('right' if d @ rgt > 0 else 'left'))
    for o in by_box.get(job['box'], ()):
        if o['r']['name'] == job['r']['name'] and o['k'] == job['k']:
            continue
        if o['r'].get('oneway') and o['step'] < 0:      # a one-way running into the box: no way out there
            continue
        d = o['D']
        if d @ h > 0.7:
            have.add('through')
        elif d @ rgt > 0:
            have.add('right')
        else:
            have.add('left')
    return have


def lane_kinds(n, have):
    """per lane, left to right: the leftmost lane turns left, the rightmost right, all go through where it can"""
    ks = [set() for _ in range(n)]
    if 'through' in have:
        for x in ks:
            x.add('through')
    if 'left' in have:
        ks[0].add('left')
    if 'right' in have:
        ks[-1].add('right')
    for j, x in enumerate(ks):
        if not x:
            x.add(('left' if 'left' in have else 'right') if j < n / 2 else ('right' if 'right' in have else 'left'))
    return ks


def approach_arrows(P, job, by_box, LL, clip):
    r, line, sg, step = job['r'], job['line'], job['sg'], job['step']
    s = r['s']
    for back in (0.0, 6.0, 12.0):
        if line.length < job['c'] + back + ARROW_L + 1:
            return
        if approach_arrows_at(P, job, by_box, LL, clip, job['c'] + back):
            return


def approach_arrows_at(P, job, by_box, LL, clip, c_tip):
    """one arrow per lane with its tip at chainage c_tip; False (nothing laid) when one would touch a zebra / box"""
    r, line, sg, step = job['r'], job['line'], job['sg'], job['step']
    s = r['s']
    tail = np.array(line.interpolate(c_tip + ARROW_L).coords[0])
    i = min(job['pts'], key=lambda i: (s[i][0] - tail[0]) ** 2 + (s[i][2] - tail[1]) ** 2)
    bd = bounds_at(LL, r['name'], i, sg)
    have = turns_of(job, by_box)
    if bd is None or not have:
        return True
    n = len(bd) - 1
    kinds = lane_kinds(n, have)
    hs = 1 if step < 0 else -1          # heading along (+1) or against (-1) the data direction
    for t in r.get('turn', []):
        if t['dir'] == hs and abs(t['i'] - i) < 10 and len(t['lanes']) == n:
            kinds = [set(x for x in (k.strip().replace('slight_', '').replace('sharp_', '') for k in ln.split(';'))
                         if x in ('left', 'through', 'right')) or {'through'} for ln in t['lanes']]
            break
    q = s[i]
    h = np.array([q[3], q[4]]) * hs
    rgt = np.array([-h[1], h[0]])
    rq = np.array([-q[4], q[3]])
    lat = (tail[0] - q[0]) * rq[0] + (tail[1] - q[2]) * rq[1]
    pgs = []
    for j in range(n):
        c = tail + rq * ((bd[j] + bd[j + 1]) / 2 - lat)
        pg = unary_union([Polygon([c + rgt * x * ARROW_S + h * y * ARROW_S for x, y in arrow_shape(k)]).buffer(0)
                          for k in sorted(kinds[j])])
        if clip.intersects(pg):
            return False
        pgs.append(pg)
    for pg in pgs:
        P.poly('LW', pg, 'arrow', r['name'])
    return True


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


def arrow_shape(kind):
    kind = kind.strip()
    # one stem (x -0.25 .. 0.25) for every kind, so a combined arrow is their union
    if kind in ('through', ''):
        return [(-0.25, 0), (0.25, 0), (0.25, 4.2), (0.75, 4.2), (0, 6), (-0.75, 4.2), (-0.25, 4.2)]
    if kind in ('left', 'slight_left', 'sharp_left'):
        return [(-0.25, 0), (0.25, 0), (0.25, 3.6), (-1.2, 3.6), (-1.2, 4.3), (-2.2, 3.35), (-1.2, 2.4), (-1.2, 3.1), (-0.25, 3.1)]
    if kind in ('right', 'slight_right', 'sharp_right'):
        return [(0.25, 0), (-0.25, 0), (-0.25, 3.6), (1.2, 3.6), (1.2, 4.3), (2.2, 3.35), (1.2, 2.4), (1.2, 3.1), (0.25, 3.1)]
    if kind in ('reverse',):
        return None
    return None


ORDER = ['stop', 'zebra', 'giveway', 'centre', 'deck centre', 'median', 'edge', 'lane', 'deck lane', 'ring lane', 'hatch edge',
         'hatch', 'arrow']


def nose_caps(data):
    """a box round each median end: 1.5 back along the median, 1.0 past its nose, the median half + 1.2 to each side"""
    cut = {k: set(v) for k, v in data['cut'].items()}
    out = []
    for r in data['roads']:
        s = r['s']
        c = cut.get(r['name'], set())
        for a, b in runs([s[i][8] > 0.3 and i not in c for i in range(len(s))]):
            for e, sgn in ((a, -1), (b, 1)):
                q = s[e]
                u = np.array([q[3], q[4]]) * sgn
                rg = np.array([-q[4], q[3]])
                p = np.array([q[0], q[2]])
                w = q[8] + EDGE_IN + 0.3
                out.append(Polygon([p - u * 1.5 - rg * w, p + u * 1.0 - rg * w, p + u * 1.0 + rg * w, p - u * 1.5 + rg * w]))
    return out


def medians(data):
    """no paint here: the medians, (J15) a cap past each median nose (paint stops short of it) and the islands"""
    from roads05_qa import quads
    cut = {k: set(v) for k, v in data['cut'].items()}
    med = []
    for r in data['roads']:
        if any(q[8] > 0 for q in r['s']):
            med.extend(quads(r['s'], cut.get(r['name'], ()), inner=8))
    med.extend(nose_caps(data))
    for isl in data.get('islands', []):
        if len(isl) >= 3:
            med.append(Polygon([(p[0], p[2]) for p in isl]).buffer(0).buffer(0.8))
    return med


def tidy(data, items):
    """final pass (17 Nov, paint QA: paint_off 438, zebra_median 129, stack_paint 89): every polygon clipped to its own
    surface (ground paint to the carriageways and rings, deck paint to the decks), off the medians, and never on a
    polygon laid before it (ORDER: stop lines and zebras first, arrows last): no paint off the asphalt, none on a
    median, no two paint polygons on one spot (they would z-fight)"""
    from roads05_qa import quads
    cut = {k: set(v) for k, v in data['cut'].items()}
    ground = []
    for r in data['roads']:
        ground.extend(quads(r['s'], cut.get(r['name'], ())))
    for g in data['roundabouts']:
        ground.append(Point(g['c'][0], g['c'][2]).buffer(g['r_out'], 96))
    med = medians(data)
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
        Q = P.intersection(surf.local(P).buffer(0.15).buffer(-0.2))   # (J15) seams between two roads' quads closed first
        if not it.get('deck') and not M.is_empty:
            Q = Q.difference(M.local(Q).buffer(0.05)) if not Q.is_empty else Q
        near = []
        for c in cells(P.bounds):
            near.extend(kept.get((c, bool(it.get("deck"))), ()))
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
                kept.setdefault((cc, bool(it.get("deck"))), []).append(p)
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
    print(len(P.items), kinds, 'signals', len(sig), P.stats)
