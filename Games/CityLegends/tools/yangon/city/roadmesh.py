"""Whole-Yangon map (14 Nov 2026): the road meshes, collision boxes and crossings of a batch, for roads.py.

Per 256-stud cell, triangle meshes in world studs (written to .glb by glb.py):
  R   asphalt: the union of every ground-level carriageway, junction corners rounded (a closing of RC studs), the medians
      and raised parts left out; raised parts (ramps, decks) are their own strips along the road
  P   pavement (+0.5) on main roads (and the faces where it steps down to a flush strip), without the kerb strip
  F   flush concrete edge strips of residential streets and lanes (no traffic): at the asphalt's height, no kerb
      (lead, 14 Nov: Studio memory, one collision box covers the street)
  skirts: every outer edge of the road footprint goes SKIRT down into the ground (same kind as the surface above)
  KR / KW / KG   kerb tops (+0.6, 1 stud wide) and the kerb faces (road -> +0.6): red and white bands 3.2 long on main
      roads and their medians (CLAUDE.md "Yangon look"), plain grey (KG) on streets
  L   white paint (+0.08): main roads' edge lines, dashed lane dividers, a solid centre line on undivided roads (none on
      1 + 1 streets), zebra crossings at signalised junctions and OSM crossings on main roads
  MG  median grass (+0.5 inside the median kerbs)
  B   bridges and ramps: deck sides and underside (DECK deep), retaining walls down to the ground on low ramps,
      parapets (2.5 over the deck, 1 wide), a central barrier on divided decks, piers every ~PIER studs (never on a
      carriageway beneath)
Heights: ground-level surfaces take an inverse-distance blend of the ground-level samples near them; raised strips take
their own samples. Collision: invisible boxes along every edge (roads.py writes them).
"""
import math

import numpy as np
import shapely
import shapely.errors
from scipy.spatial import cKDTree
from shapely.geometry import LineString, Point, Polygon, MultiPolygon, box as sbox
from shapely.ops import unary_union
from shapely.strtree import STRtree
from shapely.prepared import prep

import geo
import roadnet as rn
from heights import DECK, RAISE

CELL = 256.0
MARGIN = 28.0
RC = 8.0            # junction corner radius (closing)
PAVE_UP = 0.5
KERB_UP = 0.6
KERB_W = 1.0
PAINT_UP = 0.08
BAND = 3.2
GRID = 16.0         # asphalt / pavement split into <= 16-stud pieces so their heights follow the ground
PIER = 40.0
PARAPET_H, PARAPET_W = 2.5, 1.0
VIADUCT = 7.0       # raised more than this: a deck on piers; less: solid ramp walls
MAX_TRIS = 17000

COL = dict(R=(46, 47, 50), P=(128, 124, 116), KR=(186, 34, 34), KW=(232, 230, 224), KG=(150, 146, 138),
           L=(232, 232, 226), MG=(84, 116, 58), B=(150, 146, 138), F=(104, 102, 98), LY=(228, 182, 40))
SKIRT = 1.6         # outer edges of the road footprint go this far down into the ground (no see-through gap)


SPILL_RAISE = 4.0   # (2026-11-14) a road the grade cap holds more than this over the ground is built raised (ramp walls,
                    # piers over VIADUCT) like a bridge's ramp, not left on a 12-32 stud earth embankment
MESH_CELL = CELL    # meshes are grouped per MESH_CELL (a multiple of CELL, the geometry's work tile)
SEG = 6.0           # boundary pieces of asphalt / paint / skirts
DASH_ON, DASH_OFF = 6.0, 6.0
LINE_W, DASH_W = 0.5, 0.4
ZEBRA_HALF = 4.0    # a zebra bar runs this far either side of its middle along the road
BARRIER_H = 1.2
ONE_TO_ONE = geo.ONE_TO_ONE
if ONE_TO_ONE:
    # (2026-11-16, rescale step 3, vault "Yangon rescale plan" + "Audit - Yangon roads 1 to 1"): lengths kept in metres
    # (geo.LK), cells about 1 km (budget rules: <= ~3,000 unique meshes for the whole city, packed to MAX_TRIS), junction
    # corners 6 m (item 19), lines 0.15 m wide with 3 m dashes and 6 m gaps (item 9), zebras yellow and 4 m long
    # (item 3), median-side lines yellow, no outer edge line (item 9), red-white kerbs only on trunk / primary roads and
    # roundabouts (item 16), parapets 1.1 m high and 0.5 m thick
    CELL = 512.0
    # (2026-11-16) 1536, not 3072: a MeshPart is at most 2048 studs on any axis; Roblox clamped the 3,072-stud cells to
    # 2048 and shrank the whole mesh (P1's first placement: roads drawn in the wrong place, kerbs alone at the roundabout)
    MESH_CELL = 1536.0
    # (2026-11-16) medians are bare concrete at 1:1 (YgnConcreteBare): the vertex colour tints the variant, so no grass green
    COL = dict(COL, MG=(150, 146, 138))
    MARGIN *= geo.LK
    RC = 18.0
    GRID *= geo.LK
    PIER *= geo.LK
    BAND *= geo.LK
    SEG *= geo.LK
    PARAPET_H, PARAPET_W = 3.3, 1.5
    VIADUCT *= geo.LK
    SPILL_RAISE *= geo.LK
    DASH_ON, DASH_OFF = 9.0, 18.0
    LINE_W = DASH_W = 0.45
    ZEBRA_HALF = 6.0
    BARRIER_H = 2.4
# (2026-11-16, 1:1 junction paint, audit items 11-13) stop lines, turn arrows, hatched splitters / gores / islands
RING_SPLIT = 70.0       # medians this close to where an arm meets a roundabout become painted splitters
STOP_W, STOP_GAP = 1.2, 3.0         # stop line width along the road, its gap before the zebra
ARROW_L, ARROW_BACK = 15.0, 30.0    # turn arrow length (5 m), its middle this far behind the stop line
HATCH_PITCH, HATCH_W = 4.5, 0.75    # yellow hatch stripes
HATCH_MIN, HATCH_MAX = 25.0, 6000.0 # hatched pieces' area (sq studs): splitters, gores, small islands (audit: < ~600 m2)


def raised_samples(net, e):
    """the samples built raised: a bridge family's over RAISE, and any road held over SPILL_RAISE"""
    h = e.y - e.g
    return ((h > RAISE) & (net.fam_of.get(e.id) in net.fam_grade)) | (h > SPILL_RAISE)


def flush(e):
    """residential streets and lanes (no traffic): no raised pavement, a flush concrete edge strip (lead, 14 Nov:
    Studio memory: one collision box covers the whole width)"""
    return e.look in ('street', 'narrow') and not e.traffic


def _polys(g):
    if g is None or g.is_empty:
        return []
    if g.geom_type == 'Polygon':
        return [g]
    return [x for x in getattr(g, 'geoms', []) if x.geom_type == 'Polygon']


class Builder:
    def __init__(self, net, G):
        self.net, self.G = net, G
        edges = net.edges
        self.lohi = {}
        self.raised = {}
        self.walk = {}
        for e in edges:
            lo, hi = rn.offsets(e)
            self.lohi[e.id] = (lo, hi)
            h = e.y - e.g
            # only bridges and their ramps are built raised; a road held above steep ground by the grade cap stays a
            # ground road (the terrain is filled up to it: roads_<tag>_profile.json)
            r = raised_samples(net, e)
            # a raised run includes one ground sample either side (its foot)
            rr = r.copy()
            rr[1:] |= r[:-1]
            rr[:-1] |= r[1:]
            self.raised[e.id] = (r, rr)
        # ground-level pieces of each edge (runs of samples not strictly raised)
        self.gpieces = []   # (edge, i0, i1)
        self.rpieces = []
        for e in edges:
            r, rr = self.raised[e.id]
            n = len(e.P)
            i = 0
            while i < n:
                j = i
                while j + 1 < n and r[j + 1] == r[i]:
                    j += 1
                if r[i]:
                    self.rpieces.append((e, max(0, i - 1), min(n - 1, j + 1)))
                else:
                    a, b = i, j
                    if a > 0:
                        a = a  # the foot sample is shared
                    if b - a >= 1:
                        self.gpieces.append((e, a, b))
                    elif n == 1 or b == a:
                        # a lone ground sample between raised ones: skip
                        pass
                i = j + 1
        # strip polygons
        self.carr, self.outer, self.med, self.meta = [], [], [], []
        self.paved = []     # (2026-11-16) roadnet.PAVED_WAYS: their whole width as pavement, no carriageway
        for e, a, b in self.gpieces:
            lo, hi = self.lohi[e.id]
            sub = _sub(e, a, b)
            if getattr(e, 'paved', False):
                self.paved.append(rn.strip_poly(sub, lo[a:b + 1] - e.walk, hi[a:b + 1] + e.walk))
                continue
            lo_, hi_ = lo[a:b + 1], hi[a:b + 1]
            paired = (e.w[a:b + 1] > 0.5) & bool(e.oneway)
            if not getattr(net, 'standalone', False):
                sub, lo_, hi_, paired = _seam_extend(e, a, b, sub, lo_, hi_, paired)
            wl = np.where(paired, 0.0, e.walk)
            self.carr.append(rn.strip_poly(sub, lo_, hi_))
            self.outer.append(rn.strip_poly(sub, lo_ - wl, hi_ + e.walk))
            if e.oneway and paired.any():
                # (from 1.5 past the midline: the partner's strip overlaps it, so no sliver opens between the two)
                m = rn.strip_poly(sub, np.where(paired, -1.5, lo_), np.where(paired, np.maximum(lo_, 0.0), lo_))
                self.med.append(m)
            else:
                self.med.append(None)
            self.meta.append(e)
        self.ctree = STRtree(self.carr)
        self.otree = STRtree(self.outer)
        mm = [m for m in self.med if m is not None and not m.is_empty]
        self.mtree = STRtree(mm) if mm else None
        self.mlist = mm
        # raised footprints (deck + parapets)
        self.rfoot = []
        for e, a, b in self.rpieces:
            lo, hi = self.lohi[e.id]
            sub = _sub(e, a, b)
            paired = (e.w[a:b + 1] > 0.5) & bool(e.oneway)
            inner = np.where(paired, 0.0, lo[a:b + 1] - PARAPET_W)
            self.rfoot.append(rn.strip_poly(sub, inner, hi[a:b + 1] + PARAPET_W))
        self.rtree = STRtree(self.rfoot) if self.rfoot else None
        # ground height field
        P, H = [], []
        for e in edges:
            r, rr = self.raised[e.id]
            for i in range(len(e.P)):
                if not r[i]:
                    P.append(e.P[i])
                    H.append(e.y[i])
        self.HP = np.array(P)
        self.HH = np.array(H)
        self.htree = cKDTree(self.HP)
        # allowed region: the batch outline, minus batch 0.5 except the seam pieces
        seam_patch = [self.outer[k] for k, e in enumerate(self.meta) if e.seam[0] or e.seam[1]]
        excl = net.exclusion
        if seam_patch:
            excl = excl.difference(unary_union(seam_patch).difference(_game_roads_only(net)))
        self.allowed = net.outline.difference(excl)
        if getattr(net, 'reach_area', None) is not None:
            # (2026-11-14, batch 2) a bridge built on past the outline (roadnet.REACH_OUT): its meshes too
            self.allowed = self.allowed.union(net.reach_area)
        self.allowed_p = prep(self.allowed)
        self.zebras = []
        # (2026-11-16, 1:1, audit items 6 / 12) a roundabout's arms meet the ring on painted splitters, not kerbed
        # medians: medians within RING_SPLIT of a node where an arm joins the ring are left out (asphalt + yellow hatch)
        self.ring_zone = Polygon()
        if ONE_TO_ONE:
            ring_keys = {k for e in edges if e.tags.get('junction') in ('roundabout', 'circular') for k in (e.a, e.b)}
            arm_pts = [e.P[0 if e.a in ring_keys else -1] for e in edges
                       if e.tags.get('junction') not in ('roundabout', 'circular') and (e.a in ring_keys or e.b in ring_keys)]
            if arm_pts:
                self.ring_zone = unary_union([Point(p).buffer(RING_SPLIT) for p in arm_pts])

    # ------------------------------------------------------------ heights
    def h(self, X):
        X = np.atleast_2d(X)
        d, i = self.htree.query(X, k=6)
        w = 1.0 / np.maximum(d, 0.5) ** 2
        return (self.HH[i] * w).sum(1) / w.sum(1)

    # ------------------------------------------------------------ zebra crossings
    def make_zebras(self):
        net = self.net
        pts = []
        for p in geo.load('points'):
            if p['k'] == 'highway' and p['v'] in ('traffic_signals', 'crossing'):
                x, z = geo.world(*p['p'])
                if net.outline.buffer(50).contains(Point(x, z)):
                    pts.append((p['v'], np.array([x, z])))
        # junction nodes
        nodes = {}
        for e in net.edges:
            if getattr(e, 'paved', False):
                continue
            for end, key in ((0, e.a), (-1, e.b)):
                nodes.setdefault(key, []).append((e, end))
        self.nodes_inc = nodes
        self.signal_nodes = []      # (2026-11-16) (node point, radius of its box, [(edge, end, zebra s)])
        npos = {k: v[0][0].P[v[0][1]] for k, v in nodes.items() if len(v) >= 3}
        keys = list(npos)
        if not keys:
            return []
        kt = cKDTree(np.array([npos[k] for k in keys]))
        done = set()
        zeb = []
        for kind, p in pts:
            d, j = kt.query(p)
            if kind == 'traffic_signals' and d < 40 * geo.LK:
                key = keys[j]
                if key in done:
                    continue
                done.add(key)
                inc = nodes[key]
                if not any(e.look == 'main' for e, _ in inc):
                    continue
                rad = max(max(abs(self.lohi[e.id][0][end]), abs(self.lohi[e.id][1][end])) for e, end in inc)
                arms = []
                for e, end in inc:
                    if self.raised[e.id][0][end]:
                        continue
                    zz = self._zebra_on(e, end, rad + 6.0 * geo.LK)
                    zeb.extend(zz)
                    if zz:
                        L_ = rn.chain(e.P)[-1]
                        d_ = rad + 6.0 * geo.LK + 4
                        arms.append((e, end, d_ if end == 0 else L_ - d_))
                self.signal_nodes.append((npos[key], rad, arms))
            elif kind == 'crossing':
                # a crossing on a main road away from junctions
                best = None
                for k in self.ctree.query(Point(p).buffer(6 * geo.LK)):
                    e = self.meta[int(k)]
                    if e.look != 'main':
                        continue
                    dd = LineString(e.P).distance(Point(p))
                    if dd < 6 * geo.LK and (best is None or dd < best[0]):
                        best = (dd, e)
                if best and d > 60 * geo.LK:
                    e = best[1]
                    s_ = LineString(e.P).project(Point(p))
                    zeb.extend(self._zebra_at(e, s_))
        self.zebras = zeb
        self.zebra_union = unary_union(zeb) if zeb else Polygon()
        return zeb

    def _zebra_on(self, e, end, dist):
        L = rn.chain(e.P)[-1]
        if L < dist + 10:
            return []
        s_ = dist + 4 if end == 0 else L - dist - 4
        return self._zebra_at(e, s_)

    def _zebra_at(self, e, s_):
        c = rn.chain(e.P)
        i = int(np.clip(np.searchsorted(c, s_), 1, len(e.P) - 1))
        p = np.array([np.interp(s_, c, e.P[:, 0]), np.interp(s_, c, e.P[:, 1])])
        d = e.D[i]
        r = np.array([-d[1], d[0]])
        lo, hi = self.lohi[e.id]
        out = []
        o = lo[i] + 1.0
        while o + 1.6 <= hi[i] - 0.8:
            q = p + r * (o + 0.8)
            a = q - d * ZEBRA_HALF - r * 0.8
            b = q + d * ZEBRA_HALF - r * 0.8
            c2 = q + d * ZEBRA_HALF + r * 0.8
            d2 = q - d * ZEBRA_HALF + r * 0.8
            out.append(Polygon([a, b, c2, d2]))
            o += 3.2
        return out

    # ------------------------------------------------------------ lines
    def line_polys(self):
        """white paint polygons per edge (ground and raised), already cut at junctions and zebras"""
        out = []   # (polygon, edge)
        for e in self.net.edges:
            if e.look != 'main' or getattr(e, 'paved', False):
                continue
            lo, hi = self.lohi[e.id]
            n = len(e.P)
            if n < 2:
                continue
            specs = []   # (offset array, width, dashed, role)
            if ONE_TO_ONE:
                # no outer edge lines; a yellow line by the median; a solid white centre on undivided roads
                if e.oneway:
                    if getattr(e, 'paired', False):
                        specs.append((lo + 1.2, LINE_W, False, 'median'))
                    for k in range(1, e.nf):
                        specs.append((lo + (hi - lo) * k / e.nf, DASH_W, True, 'lane'))
                else:
                    specs.append((np.zeros(n), LINE_W, False, 'centre'))
                    for k in range(1, e.nf):
                        specs.append((hi * k / e.nf, DASH_W, True, 'lane'))
                    for k in range(1, e.nb):
                        specs.append((lo * k / e.nb, DASH_W, True, 'lane'))
            elif e.oneway:
                nl = e.nf
                specs.append((lo + 1.2, 0.5, False, 'edge'))
                specs.append((hi - 1.2, 0.5, False, 'edge'))
                for k in range(1, nl):
                    specs.append((lo + (hi - lo) * k / nl, 0.4, True, 'lane'))
            else:
                specs.append((lo + 1.2, 0.5, False, 'edge'))
                specs.append((hi - 1.2, 0.5, False, 'edge'))
                specs.append((np.zeros(n), 0.5, False, 'centre'))
                for k in range(1, e.nf):
                    specs.append((hi * k / e.nf, 0.4, True, 'lane'))
                for k in range(1, e.nb):
                    specs.append((lo * k / e.nb, 0.4, True, 'lane'))
            c = rn.chain(e.P)
            for off, wd, dashed, role in specs:
                if role == 'edge' and e.nf + e.nb <= 1 and False:
                    continue
                if not dashed:
                    out.append((rn.strip_poly(e, off - wd / 2, off + wd / 2), e, role, _side(e, off)))
                else:
                    # dashes DASH_ON on, DASH_OFF off (6 / 6; 1:1: 9 / 18)
                    s0 = 0.0
                    while s0 < c[-1] - DASH_ON:
                        a, b = s0, s0 + DASH_ON
                        sub = _sub_s(e, a, b)
                        if sub is not None:
                            oo = np.interp(rn.chain(sub.P) + a, c, off)
                            out.append((rn.strip_poly(sub, oo - wd / 2, oo + wd / 2), e, role, _side(e, oo)))
                        s0 += DASH_ON + DASH_OFF
        # cut: lines stop where another road's carriageway lies (for the centre / lane lines only roads at least as big)
        res = []
        carr_b = {}
        zb = [z.buffer(0.6, join_style=2) for z in self.zebras]
        ztree = STRtree(zb) if zb else None
        # (2026-11-16, 1:1, CLAUDE.md "Yangon look": RoadLines clearMouths) a smaller road (or one of the same rank that
        # does not cross) breaks only the lines on its own side of this road's middle (4 studs out; 1.5 past a divided
        # road's midline), so the far side's lines and the middle line run on; a bigger road breaks every line; and at
        # a signalised junction every line stops at the zebras (the junction box)
        zones = {}
        def zone(e, side):
            key = (e.id, side)
            if key not in zones:
                thr = 1.5 if getattr(e, 'paired', False) else 4.0
                zones[key] = rn.strip_poly(e, thr, 160.0) if side > 0 else rn.strip_poly(e, -160.0, -thr)
            return zones[key]
        boxes = [Point(p).buffer(r + 3.0) for p, r, arms in getattr(self, 'signal_nodes', [])] if ONE_TO_ONE else []
        btree = STRtree(boxes) if boxes else None
        for pg, e, role, side in out:
            if pg.is_empty:
                continue
            cut = []
            for k in self.ctree.query(pg):
                f = self.meta[int(k)]
                if f.id == e.id:
                    continue
                if rn.norm_name(f.name) == rn.norm_name(e.name) and f.name:
                    continue
                if f.oneway and e.oneway and f.layer == e.layer and abs(float(f.D[len(f.D) // 2] @ e.D[len(e.D) // 2])) > 0.95:
                    continue
                k = int(k)
                if not ONE_TO_ONE:
                    if role != 'edge' and f.rank > e.rank:
                        continue
                    if k not in carr_b:
                        carr_b[k] = self.carr[k].buffer(1.0, join_style=2)
                    if carr_b[k].intersects(pg):
                        cut.append(carr_b[k])
                    continue
                if k not in carr_b:
                    carr_b[k] = self.carr[k].buffer(1.0, join_style=2)
                cb_ = carr_b[k]
                if not cb_.intersects(pg):
                    continue
                if f.rank < e.rank or f.layer != e.layer:
                    cut.append(cb_)
                    continue
                if f.rank == e.rank:
                    near = cb_.intersection(pg.buffer(40.0))
                    if near.intersects(zone(e, 1)) and near.intersects(zone(e, -1)):
                        cut.append(cb_)      # a crossing road of the same rank: every line stops
                        continue
                if side == 0:
                    continue                 # the middle line never breaks for a smaller road
                part = cb_.intersection(zone(e, side))
                if not part.is_empty:
                    cut.append(part)
            if btree is not None:
                bb = [boxes[int(k)] for k in btree.query(pg)]
                if bb:
                    cut.append(unary_union(bb))
            g = pg
            if cut:
                g = g.difference(unary_union(cut))
            if ztree is not None:
                zz = [zb[int(k)] for k in ztree.query(pg)]
                if zz:
                    g = g.difference(unary_union(zz))
            for q in _polys(g):
                if q.area > 0.05:
                    res.append((q, e, 'LY' if role == 'median' else 'L'))
        return res

    # ------------------------------------------------------------ junction paint (1:1)
    def extra_paint(self):
        """(2026-11-16, audit items 11-13) -> (white, yellow) polygons: stop lines before the zebras of every signalised
        approach, turn arrows from OSM turn:lanes, yellow hatch on the pieces the junction closing fills between two
        carriageways running the same way or opposite ways (roundabout splitters, slip / ramp gores) and on small
        islands closed in by carriageways"""
        white, yellow = [], []
        stop_at = {}
        for p, rad, arms in getattr(self, 'signal_nodes', []):
            for e, end, sz in arms:
                lo, hi = self.lohi[e.id]
                if end == -1:
                    s_ = sz - ZEBRA_HALF - STOP_GAP - STOP_W / 2
                else:
                    if e.oneway:
                        continue
                    s_ = sz + ZEBRA_HALF + STOP_GAP + STOP_W / 2
                pq = self._at(e, s_)
                if pq is None:
                    continue
                q, d, i = pq
                r = np.array([-d[1], d[0]])
                if end == -1:
                    a_, b_ = (lo[i] if e.oneway else 0.0), hi[i]
                else:
                    a_, b_ = lo[i], 0.0
                a_, b_ = a_ + 0.6, b_ - 0.6
                if b_ - a_ < 3.0:
                    continue
                white.append(Polygon([q - d * STOP_W / 2 + r * a_, q + d * STOP_W / 2 + r * a_,
                                      q + d * STOP_W / 2 + r * b_, q - d * STOP_W / 2 + r * b_]))
                stop_at[(e.id, end)] = s_
        white += self._arrows(stop_at)
        yellow += self._hatches()
        self.paint_stats = dict(stop_lines=len(stop_at), arrows=getattr(self, '_n_arrows', 0), hatches=getattr(self, '_n_hatch', 0))
        return white, yellow

    def _at(self, e, s_):
        c = rn.chain(e.P)
        if s_ < 1.0 or s_ > c[-1] - 1.0:
            return None
        i = int(np.clip(np.searchsorted(c, s_), 1, len(e.P) - 1))
        q = np.array([np.interp(s_, c, e.P[:, 0]), np.interp(s_, c, e.P[:, 1])])
        return q, e.D[i], i

    def _arrows(self, stop_at):
        out = []
        n_ = 0
        inc = getattr(self, 'nodes_inc', {})
        for e in self.net.edges:
            if getattr(e, 'paved', False) or not e.traffic:
                continue
            for end, key in ((-1, e.b), (0, e.a)):
                if len(inc.get(key, [])) < 3 or self.raised[e.id][0][end]:
                    continue
                if e.oneway:
                    if end == 0:
                        continue
                    tag = e.tags.get('turn:lanes') or e.tags.get('turn:lanes:forward')
                    n = e.nf
                else:
                    tag = e.tags.get('turn:lanes:forward' if end == -1 else 'turn:lanes:backward')
                    n = e.nf if end == -1 else e.nb
                if not tag or n < 1:
                    continue
                toks = tag.split('|')
                L = rn.chain(e.P)[-1]
                if (e.id, end) in stop_at:
                    s0 = stop_at[(e.id, end)]
                    s_ = s0 - ARROW_BACK if end == -1 else s0 + ARROW_BACK
                else:
                    reach = max(max(abs(self.lohi[f.id][0][k]), abs(self.lohi[f.id][1][k])) for f, k in inc[key])
                    s_ = L - reach - 12.0 - ARROW_BACK if end == -1 else reach + 12.0 + ARROW_BACK
                pq = self._at(e, s_)
                if pq is None or s_ < ARROW_L or s_ > L - ARROW_L:
                    continue
                q, d, i = pq
                lo, hi = self.lohi[e.id]
                R = np.array([-d[1], d[0]])
                t = d if end == -1 else -d          # the way of travel
                rr = R if end == -1 else -R         # right of the travel
                for k in range(1, n + 1):
                    if e.oneway:
                        off = lo[i] + (hi[i] - lo[i]) * (k - 0.5) / n
                    elif end == -1:
                        off = hi[i] * (k - 0.5) / n
                    else:
                        off = lo[i] * (k - 0.5) / n
                    m = len(toks)
                    j = 0 if n == 1 else int(round((k - 1) * (m - 1) / (n - 1)))
                    kinds = set()
                    for w in toks[min(j, m - 1)].split(';'):
                        w = w.strip()
                        if w == 'through':
                            kinds.add('T')
                        elif w.endswith('left') and not w.startswith('merge'):
                            kinds.add('L')
                        elif w.endswith('right') and not w.startswith('merge'):
                            kinds.add('R')
                    if not kinds:
                        continue
                    pg = _arrow(q + R * off, t, rr, kinds)
                    if pg is None:
                        continue
                    clash = False
                    for kk in self.ctree.query(pg):
                        f = self.meta[int(kk)]
                        if f.id != e.id and rn.norm_name(f.name) != rn.norm_name(e.name) and self.carr[int(kk)].intersects(pg):
                            clash = True
                            break
                    if not clash:
                        out.append(pg)
                        n_ += 1
        self._n_arrows = n_
        return out

    def _hatches(self):
        """yellow hatch on the junction closing's fill between carriageways (see extra_paint)"""
        inc = getattr(self, 'nodes_inc', {})
        mm = self.mlist
        pieces = []
        seen = []
        for key, lst in inc.items():
            if len(lst) < 3:
                continue
            e0, end0 = lst[0]
            if self.raised[e0.id][0][end0]:
                continue
            p = e0.P[end0]
            disk = Point(p).buffer(90.0)
            ks = [int(k) for k in self.ctree.query(disk.buffer(40.0))]
            if len(ks) < 2:
                continue
            U = unary_union([self.carr[k] for k in ks])
            C = U.buffer(RC, join_style=1).buffer(-RC, join_style=1)
            G = C.difference(U)
            if self.mtree is not None:
                med = [mm[int(k)] for k in self.mtree.query(disk.buffer(40.0))]
                if med:
                    Mr = unary_union(med).buffer(1.5)
                    G = G.difference(Mr.difference(self.ring_zone))
            if self.rtree is not None:
                rk = [int(k) for k in self.rtree.query(disk)]
                if rk:
                    G = G.difference(unary_union([self.rfoot[k] for k in rk]).buffer(1.0))
            G = G.intersection(Point(p).buffer(80.0))
            for pc0 in _polys(G):
                for pc in _polys(pc0.buffer(-0.2).buffer(0.2)):
                    if not (HATCH_MIN <= pc.area <= HATCH_MAX):
                        continue
                    if any(pc.centroid.distance(sp) < 0.5 and abs(pc.area - sa) < 1.0 for sp, sa in seen):
                        continue
                    if self._hatch_kind(pc, ks):
                        seen.append((pc.centroid, pc.area))
                        pieces.append(pc)
        # two nodes can find overlapping pieces: one union, so no hatch lies on hatch
        merged = _polys(unary_union(pieces)) if pieces else []
        self._n_hatch = len(merged)
        out = []
        for pc in merged:
            h = _hatch(pc)
            if h is not None:
                out.append(h)
        return out

    def _hatch_kind(self, pc, ks):
        """a splitter / gore: it touches two carriageways (of different edges) that run within 45 degrees of parallel
        beside it; an island: closed in by carriageways (85% of its edge on one)"""
        touch = []
        ring = pc.exterior
        on = 0.0
        for k in ks:
            g = self.carr[k]
            if g.distance(pc) < 0.6:
                e = self.meta[k]
                L = LineString(e.P)
                s_ = L.project(pc.centroid)
                c = rn.chain(e.P)
                i = int(np.clip(np.searchsorted(c, s_), 1, len(e.P) - 1))
                touch.append((e, e.D[i]))
                on += ring.intersection(g.buffer(0.6)).length
        if len(touch) < 2:
            return False
        if on >= 0.85 * ring.length and len(touch) >= 3:
            return True
        for a in range(len(touch)):
            for b in range(a + 1, len(touch)):
                ea, da = touch[a]
                eb, db = touch[b]
                if ea.id == eb.id:
                    continue
                if abs(float(da @ db)) > 0.7:
                    return True
        return False

    # ------------------------------------------------------------ cells
    def cells(self):
        xs, zs = [], []
        for e in self.net.edges:
            xs += [e.P[:, 0].min(), e.P[:, 0].max()]
            zs += [e.P[:, 1].min(), e.P[:, 1].max()]
        cx0, cx1 = math.floor(min(xs) / CELL), math.floor(max(xs) / CELL)
        cz0, cz1 = math.floor(min(zs) / CELL), math.floor(max(zs) / CELL)
        return [(i, j) for i in range(cx0, cx1 + 1) for j in range(cz0, cz1 + 1)]

    def build(self, log=print):
        self.make_zebras()
        lines = self.line_polys()
        ltree = STRtree([x[0] for x in lines]) if lines else None
        xw, xy = self.extra_paint() if ONE_TO_ONE else ([], [])
        xwt = STRtree(xw) if xw else None
        xyt = STRtree(xy) if xy else None
        meshes = {}
        tris_total = {}
        cl = self.cells()
        for n_, (ci, cj) in enumerate(cl):
            if n_ % 200 == 0:
                log('    cell %d / %d' % (n_, len(cl)))
            cb = sbox(ci * CELL, cj * CELL, (ci + 1) * CELL, (cj + 1) * CELL)
            if not self.allowed.intersects(cb):
                continue
            cbm = cb.buffer(MARGIN, join_style=2)
            ks = [int(k) for k in self.ctree.query(cbm)]
            out = {}
            Rg = Polygon()
            if ks:
                try:
                    Rg = self._ground_cell(cb, cbm, ks, out) or Polygon()
                except shapely.errors.GEOSException:
                    # a robustness failure in GEOS's overlay: again on a 0.01-stud grid
                    out = {}
                    self._snap = True
                    try:
                        Rg = self._ground_cell(cb, cbm, ks, out) or Polygon()
                    finally:
                        self._snap = False
                    self.snapped = getattr(self, 'snapped', 0) + 1
            Rg = Rg.buffer(-0.3, join_style=2)   # paint stays clear of the kerb faces
            rz = Polygon()
            if self.rtree is not None:
                rk = [int(k) for k in self.rtree.query(cb)]
                if rk:
                    rz = unary_union([self.rfoot[k] for k in rk])
            paint, yellow = [], []
            if ltree is not None:
                for k in ltree.query(cb):
                    q, e, kd = lines[int(k)]
                    (yellow if kd == 'LY' else paint).append(q)
            if self.zebras:
                for z in self.zebras:
                    if z.intersects(cb):
                        (yellow if ONE_TO_ONE else paint).append(z)
            if xwt is not None:
                paint += [xw[int(k)] for k in xwt.query(cb)]
            if xyt is not None:
                yellow += [xy[int(k)] for k in xyt.query(cb)]
            gy = None
            if yellow:
                gy = unary_union(yellow)
                g = gy.intersection(cb).intersection(Rg).intersection(self.allowed)
                for pg in _polys(g):
                    self._flat(pg, out, 'LY', PAINT_UP)
            if paint:
                # one union: paint pieces never overlap each other (the same height would flicker)
                g = unary_union(paint)
                if gy is not None:
                    g = dif(g, gy.buffer(0.1, join_style=2))
                g = g.intersection(cb).intersection(Rg).intersection(self.allowed)
                for pg in _polys(g):
                    self._flat(pg, out, 'L', PAINT_UP)
            for kind, tris in out.items():
                if tris:
                    meshes[(kind, ci, cj)] = np.asarray(tris, dtype=np.float32)
                    tris_total[kind] = tris_total.get(kind, 0) + len(tris)
        # raised parts: strips, assigned to cells by their triangles' middles
        extra = {}
        for e, a, b in self.rpieces:
            for kind, tri in self._raised_strip(e, a, b):
                m = ((tri[0][0] + tri[1][0] + tri[2][0]) / 3, (tri[0][2] + tri[1][2] + tri[2][2]) / 3)
                if not self.allowed_p.contains(Point(m)):
                    continue
                key = (kind, math.floor(m[0] / CELL), math.floor(m[1] / CELL))
                extra.setdefault(key, []).append(tri)
                tris_total[kind] = tris_total.get(kind, 0) + 1
        for key, tl in extra.items():
            arr = np.asarray(tl, dtype=np.float32)
            meshes[key] = np.concatenate([meshes[key], arr]) if key in meshes else arr
        self.meshes = meshes
        self.tris_total = tris_total
        return meshes

    def _ground_cell(self, cb, cbm, ks, out):
        carr = unary_union([self.carr[k] for k in ks]).intersection(cbm)
        if carr.is_empty:
            return None
        sn = (lambda g: shapely.set_precision(g, 0.01)) if getattr(self, '_snap', False) else (lambda g: g)
        Rc = sn(carr.buffer(RC, join_style=1).buffer(-RC, join_style=1))
        ko = [int(k) for k in self.otree.query(cbm)]
        oo_r = [self.outer[k] for k in ko if not flush(self.meta[k])]
        oo_r += [pv for pv in self.paved if pv.intersects(cbm)]
        oo_f = [self.outer[k] for k in ko if flush(self.meta[k])]
        Po = unary_union(oo_r).intersection(cbm) if oo_r else Polygon()
        Po = Po.buffer(RC * 0.75, join_style=1).buffer(-RC * 0.75, join_style=1)
        Fo = unary_union(oo_f).intersection(cbm) if oo_f else Polygon()
        Fo = sn(Fo.buffer(RC * 0.75, join_style=1).buffer(-RC * 0.75, join_style=1))
        Po = sn(Po)
        M = Polygon()
        if self.mtree is not None:
            mk = [int(k) for k in self.mtree.query(cbm)]
            if mk:
                M = unary_union([self.mlist[k] for k in mk]).intersection(cbm)
                # median openings: where a traffic road crosses (another name), and at zebras
                opens = []
                for k in ks:
                    f = self.meta[k]
                    if f.traffic and not f.oneway or (f.traffic and f.hw in rn.LINKS):
                        opens.append(self.carr[k])
                    elif f.traffic and f.oneway and not (f.w > 0.5).any():
                        opens.append(self.carr[k])
                if opens:
                    M = M.difference(unary_union(opens).buffer(2.0))
                M = sn(M.buffer(1.0, join_style=2).buffer(-1.0, join_style=2).buffer(-0.4).buffer(0.4))
                if not self.ring_zone.is_empty and self.ring_zone.intersects(cbm):
                    M = sn(M.difference(self.ring_zone).buffer(-0.4).buffer(0.4))
        raised = Polygon()
        if self.rtree is not None:
            rk = [int(k) for k in self.rtree.query(cbm)]
            if rk:
                raised = sn(unary_union([self.rfoot[k] for k in rk]))
        R0 = dif(dif(Rc, M), raised)
        R = R0.buffer(-0.6, join_style=2).buffer(0.6, join_style=2).intersection(R0)
        sl = dif(R0, R)                      # asphalt slivers: into the median beside them, else kept
        if not sl.is_empty and not M.is_empty:
            into = sl.intersection(M.buffer(1.5))
            M = M.union(into)
            R = R.union(dif(sl, into))
        else:
            R = R0
        Pv = dif(dif(Po, Rc), raised)
        Fv = dif(dif(dif(Fo, Rc), Pv), raised)
        Mv = dif(M, raised)
        strip = R.buffer(KERB_W, join_style=2, mitre_limit=2.0)
        R_cell = R.intersection(cb).intersection(self.allowed)
        P_cell = dif(Pv, strip).intersection(cb).intersection(self.allowed)
        F_cell = Fv.intersection(cb).intersection(self.allowed)
        M_cell = dif(Mv, strip).intersection(cb).intersection(self.allowed)
        for pg in _polys(R_cell):
            self._flat(pg, out, 'R', 0.0)
        for pg in _polys(P_cell):
            self._flat(pg, out, 'P', PAVE_UP)
        for pg in _polys(F_cell):
            self._flat(pg, out, 'F', 0.0)
        for pg in _polys(M_cell):
            self._flat(pg, out, 'MG', PAVE_UP)
        # vertical faces: a raised pavement's edge over a flush strip (0.5 step), and skirts down into the ground on
        # every outer edge of the footprint (raised pavement, flush strip, asphalt at dead ends)
        foot = R.union(Pv).union(Fv).union(Mv)
        self._edges(Pv, cb, prep(Fv), prep(foot), out)
        self._edges(Fv, cb, None, prep(foot), out, kind='F', up=0.0)
        self._edges(R, cb, None, prep(foot), out, kind='R', up=0.0)
        # kerbs along R's boundary where pavement or median lies outside it
        nextto = prep(Pv.union(Mv))
        medp = prep(Mv) if not Mv.is_empty else None
        R_or = shapely.geometry.polygon.orient
        for pg in _polys(R):
            pg = R_or(pg, 1.0)
            for ring in [pg.exterior] + list(pg.interiors):
                self._kerb_ring(ring, cb, nextto, medp, out)
        return R

    def _edges(self, area, cb, step_to, foot, out, kind='P', up=PAVE_UP):
        """faces along an area's boundary: where the flush strip lies outside (step_to) a 0.5 step face; where nothing of
        the road lies outside, a skirt from the top SKIRT down (never along the batch outline: the next batch joins it)"""
        if area.is_empty:
            return
        o = out.setdefault(kind, [])
        for pg in _polys(area):
            pg = shapely.geometry.polygon.orient(pg, 1.0)
            for ring in [pg.exterior] + list(pg.interiors):
                cs = np.array(shapely.segmentize(LineString(ring.coords), SEG).coords)
                if len(cs) < 3:
                    continue
                mids = (cs[:-1] + cs[1:]) / 2
                seg = cs[1:] - cs[:-1]
                L = np.linalg.norm(seg, axis=1)
                ok = L > 1e-6
                if not ok.any():
                    continue
                nrm = np.zeros_like(seg)
                nrm[ok] = np.stack([seg[ok, 1], -seg[ok, 0]], axis=1) / L[ok, None]
                hs = self.h(cs)
                for k in range(len(mids)):
                    if not ok[k] or not cb.contains(Point(mids[k])):
                        continue
                    probe = Point(mids[k] + nrm[k] * 0.4)
                    if not self.allowed_p.contains(Point(mids[k] - nrm[k] * 0.4)):
                        continue
                    if not self.allowed_p.contains(probe):
                        continue
                    a, b = cs[k], cs[k + 1]
                    top_a, top_b = hs[k] + up, hs[k + 1] + up
                    if step_to is not None and step_to.contains(probe):
                        lo_a, lo_b = hs[k], hs[k + 1]
                    elif foot.contains(probe):
                        continue
                    else:
                        lo_a, lo_b = top_a - SKIRT, top_b - SKIRT
                    _quad(o, (a[0], lo_a, a[1]), (b[0], lo_b, b[1]), (b[0], top_b, b[1]), (a[0], top_a, a[1]),
                          (nrm[k][0], 0, nrm[k][1]))

    def _kerb_ring(self, ring, cb, nextto, medp, out):
        cs = np.array(shapely.segmentize(LineString(ring.coords), BAND).coords)
        if len(cs) < 3:
            return
        if np.allclose(cs[0], cs[-1]):
            cs = cs[:-1]
        n = len(cs)
        seg = np.roll(cs, -1, axis=0) - cs
        L = np.linalg.norm(seg, axis=1)
        L[L < 1e-9] = 1e-9
        d = seg / L[:, None]
        nrm = np.stack([d[:, 1], -d[:, 0]], axis=1)   # away from R (interior on the left)
        vn = nrm + np.roll(nrm, 1, axis=0)
        vl = np.linalg.norm(vn, axis=1)
        vl[vl < 1e-6] = 1
        vn = vn / vl[:, None]
        cosh = np.clip((vn * nrm).sum(1), 0.5, 1.0)
        vn = vn / cosh[:, None]
        s = np.r_[0, np.cumsum(L)][:-1]
        hs = self.h(cs)
        for k in range(n):
            a, b = cs[k], cs[(k + 1) % n]
            mid = (a + b) / 2
            if not cb.contains(Point(mid)):
                continue
            if not self.allowed_p.contains(Point(mid)):
                continue
            probe = mid + nrm[k] * (KERB_W * 0.5)
            if not nextto.contains(Point(probe)):
                continue
            # the road this kerb belongs to
            main = self._kerb_banded(mid) if ONE_TO_ONE else self._is_main(mid)
            band = int((s[k] + L[k] / 2) // BAND) % 2
            kind = ('KR' if band == 0 else 'KW') if main else 'KG'
            ha, hb = hs[k], hs[(k + 1) % n]
            na, nb = vn[k], vn[(k + 1) % n]
            A0 = (a[0], ha, a[1])
            B0 = (b[0], hb, b[1])
            A1 = (a[0], ha + KERB_UP, a[1])
            B1 = (b[0], hb + KERB_UP, b[1])
            A2 = (a[0] + na[0] * KERB_W, ha + KERB_UP, a[1] + na[1] * KERB_W)
            B2 = (b[0] + nb[0] * KERB_W, hb + KERB_UP, b[1] + nb[1] * KERB_W)
            o = out.setdefault(kind, [])
            # top (up), face (towards the road: -nrm)
            _quad(o, A1, B1, B2, A2, (0, 1, 0))
            _quad(o, A0, B0, B1, A1, (-nrm[k][0], 0, -nrm[k][1]))
            # the back face down to the pavement (0.1) is too small to see; the pavement meets it

    def _is_main(self, p):
        best = None
        for k in self.ctree.query(Point(p).buffer(4)):
            dd = self.carr[int(k)].distance(Point(p))
            if best is None or dd < best[0]:
                best = (dd, self.meta[int(k)])
        return best is not None and best[1].look == 'main'

    def _kerb_banded(self, p):
        """(1:1) red-white kerbs only along trunk / primary roads (their links) and roundabouts (audit item 16)"""
        best = None
        for k in self.ctree.query(Point(p).buffer(4)):
            dd = self.carr[int(k)].distance(Point(p))
            if best is None or dd < best[0]:
                best = (dd, self.meta[int(k)])
        if best is None:
            return False
        e = best[1]
        return e.hw in ('trunk', 'primary', 'trunk_link', 'primary_link', 'motorway') or \
            e.tags.get('junction') in ('roundabout', 'circular')

    def _flat(self, pg, out, kind, up, own=None):
        """triangulate a flat-ish polygon, split into grid pieces (GRID under paint, 2 GRID elsewhere), heights from
        the field"""
        o = out.setdefault(kind, [])
        x0, z0, x1, z1 = pg.bounds
        GR = GRID if kind in ('R', 'L', 'LY') else (4 * GRID if kind == 'F' else 2 * GRID)
        if x1 - x0 > GR * 1.5 or z1 - z0 > GR * 1.5:
            parts = []
            gx = np.arange(math.floor(x0 / GR) * GR, x1 + GR, GR)
            gz = np.arange(math.floor(z0 / GR) * GR, z1 + GR, GR)
            grid = [sbox(a, b, a + GR, b + GR) for a in gx[:-1] for b in gz[:-1]]
            gi = shapely.intersection(np.array(grid, dtype=object), pg)
            for g in gi:
                parts += _polys(g)
        else:
            parts = [pg]
        for q in parts:
            if q.area < 0.02:
                continue
            q = shapely.segmentize(q, (6.0 if kind in ('R', 'L', 'LY') else (16.0 if kind == 'F' else 10.0)) * (SEG / 6.0))
            try:
                tr = shapely.constrained_delaunay_triangles(q)
            except Exception:
                continue
            tl = [list(t.exterior.coords)[:3] for t in tr.geoms]
            if not tl:
                continue
            V = np.array([p for t in tl for p in t])
            H = self.h(V) + up
            for k, t in enumerate(tl):
                a = (t[0][0], H[3 * k], t[0][1])
                b = (t[1][0], H[3 * k + 1], t[1][1])
                c = (t[2][0], H[3 * k + 2], t[2][1])
                _tri(o, a, b, c, (0, 1, 0))

    # ------------------------------------------------------------ raised strips
    def _raised_strip(self, e, a, b):
        lo, hi = self.lohi[e.id]
        P, D, Y, Gd = e.P[a:b + 1], e.D[a:b + 1], e.y[a:b + 1], e.g[a:b + 1]
        R = np.stack([-D[:, 1], D[:, 0]], axis=1)
        paired = (e.w[a:b + 1] > 0.5) & bool(e.oneway)
        inner = np.where(paired, 0.0, lo[a:b + 1])
        outer = hi[a:b + 1]
        res = []

        def at(i, off, dy=0.0):
            p = P[i] + R[i] * off
            return (float(p[0]), float(Y[i] + dy), float(p[1]))
        n = len(P)
        hgt = Y - Gd
        for i in range(n - 1):
            # deck top
            _quad_l(res, 'R', at(i, inner[i]), at(i + 1, inner[i + 1]), at(i + 1, outer[i + 1]), at(i, outer[i]), (0, 1, 0))
            deep = max(hgt[i], hgt[i + 1]) > VIADUCT
            for side, off in ((1, outer), (-1, inner)):
                if side == -1 and paired[i]:
                    # central barrier on the midline (half of it on each carriageway)
                    w = 0.8
                    bh = BARRIER_H
                    _quad_l(res, 'B', at(i, 0.0, bh), at(i + 1, 0.0, bh), at(i + 1, w, bh), at(i, w, bh), (0, 1, 0))
                    _quad_l(res, 'B', at(i, w, 0), at(i + 1, w, 0), at(i + 1, w, bh), at(i, w, bh), (R[i][0], 0, R[i][1]))
                    continue
                o0, o1 = off[i], off[i + 1]
                pw = PARAPET_W * side
                # parapet: inner face, top, outer face
                _quad_l(res, 'B', at(i, o0, 0), at(i + 1, o1, 0), at(i + 1, o1, PARAPET_H), at(i, o0, PARAPET_H),
                        (-side * R[i][0], 0, -side * R[i][1]))
                _quad_l(res, 'B', at(i, o0, PARAPET_H), at(i + 1, o1, PARAPET_H), at(i + 1, o1 + pw, PARAPET_H),
                        at(i, o0 + pw, PARAPET_H), (0, 1, 0))
                bot0 = -DECK if hgt[i] > VIADUCT else -(hgt[i] + 1.0)
                bot1 = -DECK if hgt[i + 1] > VIADUCT else -(hgt[i + 1] + 1.0)
                _quad_l(res, 'B', at(i, o0 + pw, bot0), at(i + 1, o1 + pw, bot1), at(i + 1, o1 + pw, PARAPET_H),
                        at(i, o0 + pw, PARAPET_H), (side * R[i][0], 0, side * R[i][1]))
            if deep:
                # underside
                ilo0 = inner[i] - (0 if paired[i] else PARAPET_W)
                ilo1 = inner[i + 1] - (0 if paired[i + 1] else PARAPET_W)
                _quad_l(res, 'B', at(i, ilo0, -DECK), at(i + 1, ilo1, -DECK), at(i + 1, outer[i + 1] + PARAPET_W, -DECK),
                        at(i, outer[i] + PARAPET_W, -DECK), (0, -1, 0))
        # paint on the deck: edge lines, dashed lane lines
        if e.look == 'main':
            c = rn.chain(P)
            los = lo[a:b + 1]
            specs = [(los + 1.2, LINE_W, False), (outer - 1.2, LINE_W, False)]
            if e.oneway:
                for k in range(1, e.nf):
                    specs.append((los + (outer - los) * k / e.nf, DASH_W, True))
            else:
                specs.append((np.zeros(n), LINE_W, False))
                for k in range(1, e.nf):
                    specs.append((outer * k / e.nf, DASH_W, True))
                for k in range(1, e.nb):
                    specs.append((inner * k / e.nb, DASH_W, True))
            for off, wd, dashed in specs:
                for i in range(n - 1):
                    if dashed and ((c[i] + c[i + 1]) / 2) % (DASH_ON + DASH_OFF) >= DASH_ON:
                        continue
                    _quad_l(res, 'L', at(i, off[i] - wd / 2, PAINT_UP), at(i + 1, off[i + 1] - wd / 2, PAINT_UP),
                            at(i + 1, off[i + 1] + wd / 2, PAINT_UP), at(i, off[i] + wd / 2, PAINT_UP), (0, 1, 0))
        # piers
        c = rn.chain(P)
        s_ = PIER / 2
        while s_ < c[-1]:
            i = int(np.clip(np.searchsorted(c, s_), 0, n - 1))
            if hgt[i] > VIADUCT:
                mid_off = (inner[i] + outer[i]) / 2
                pc = P[i] + R[i] * mid_off
                wa = 2.5 * geo.LK
                wc = min(10.0 * geo.LK, (outer[i] - inner[i]) * 0.3)
                foot = Polygon([pc - D[i] * wa - R[i] * wc, pc + D[i] * wa - R[i] * wc, pc + D[i] * wa + R[i] * wc,
                                pc - D[i] * wa + R[i] * wc])
                if not self._on_carriageway(foot, e):
                    top = Y[i] - DECK
                    gy = float(self.G.ys([pc])[0]) - 1.0
                    w_ = self.G.water_at(pc[0], pc[1])
                    if w_:
                        gy = min(gy, w_[0] - 6.0)
                    res.extend(_box_tris('B', pc, D[i], R[i], wa, wc, gy, top))
            s_ += PIER
        return res

    def _on_carriageway(self, foot, e):
        for k in self.ctree.query(foot):
            f = self.meta[int(k)]
            if f.id == e.id:
                continue
            g = self.carr[int(k)]
            if g.intersects(foot):
                return True
        return False


def _arrow(c, t, r, kinds):
    """a painted turn arrow (ARROW_L long) with its middle at c, pointing along t (r = right of t); kinds of T / L / R"""
    t = np.asarray(t, float)
    r = np.asarray(r, float)

    def P(u, v):
        return tuple(c + t * u + r * v)
    h = ARROW_L / 2
    parts = []
    W = 0.35
    if 'T' in kinds:
        parts.append(LineString([P(-h, 0), P(h - 4.0, 0)]).buffer(W, cap_style=2))
        parts.append(Polygon([P(h - 4.0, -1.5), P(h, 0), P(h - 4.0, 1.5)]))
    for side, k in ((-1.0, 'L'), (1.0, 'R')):
        if k not in kinds:
            continue
        base = 0.5 if 'T' in kinds else 2.0
        parts.append(LineString([P(-h, 0), P(base, 0), P(base + 2.6, side * 2.6)]).buffer(W, cap_style=2, join_style=2))
        b0 = np.array([base + 2.6, side * 2.6])
        tip = b0 + np.array([1.0, side]) / math.sqrt(2) * 3.0
        n_ = np.array([1.0, -side]) / math.sqrt(2) * 1.4
        parts.append(Polygon([P(*(b0 + n_)), P(*tip), P(*(b0 - n_))]))
    if not parts:
        return None
    g = unary_union(parts)
    return g if g.is_valid and not g.is_empty else g.buffer(0)


def _hatch(pc):
    """yellow hatch: an outline LINE_W wide inside the piece and stripes HATCH_W wide every HATCH_PITCH at 45 degrees
    to the piece's long side"""
    inner = pc.buffer(-LINE_W)
    outline = pc.difference(inner) if not inner.is_empty else pc
    mr = pc.minimum_rotated_rectangle
    xy = np.array(mr.exterior.coords)[:4]
    e1, e2 = xy[1] - xy[0], xy[2] - xy[1]
    ax = e1 if np.linalg.norm(e1) >= np.linalg.norm(e2) else e2
    ang = math.atan2(ax[1], ax[0]) + math.pi / 4
    d = np.array([math.cos(ang), math.sin(ang)])
    n = np.array([-d[1], d[0]])
    c = np.array(pc.centroid.coords[0])
    R_ = math.hypot(pc.bounds[2] - pc.bounds[0], pc.bounds[3] - pc.bounds[1])
    stripes = []
    k = -int(R_ / HATCH_PITCH) - 1
    while k * HATCH_PITCH <= R_:
        o = c + n * (k * HATCH_PITCH)
        stripes.append(LineString([tuple(o - d * R_), tuple(o + d * R_)]).buffer(HATCH_W / 2, cap_style=2))
        k += 1
    g = outline
    if not inner.is_empty and stripes:
        g = g.union(unary_union(stripes).intersection(inner))
    return g if not g.is_empty else None


def _side(e, off):
    """(1:1 clearMouths) which side of the road's middle a line runs on: +1 right, -1 left, 0 the middle line (within
    4 studs of a two-way road's centre; a divided road's lines all lie right of its midline)"""
    m = float(np.mean(off))
    thr = 1.5 if getattr(e, 'paired', False) else 4.0
    return 1 if m >= thr else (-1 if m <= -thr else 0)


def dif(a, b):
    """a - b, retried on a 0.01 / 0.05-stud grid when GEOS's overlay fails (it did on two cells of batch 2)"""
    try:
        return a.difference(b)
    except shapely.errors.GEOSException:
        try:
            return shapely.difference(a, b, grid_size=0.01)
        except shapely.errors.GEOSException:
            return shapely.difference(a, b, grid_size=0.05)


def _game_roads_only(net):
    game, _ = rn.game_roads()
    return unary_union([LineString([(q[0], q[2]) for q in r['s']]).buffer(max(max(q[6], q[7]) for q in r['s']) + 10.5, cap_style=2)
                        for r in game['roads']])


class _Sub:
    pass


SEAM_EXT = 40.0     # (2026-11-14) a road cut on batch 0.5's box edge: its strips run on this far past the cut, the allowed
                    # area clips them ON the edge (a square cut end met an oblique edge with a gap on one side)


def _on_box_edge(p):
    x0, z0, x1, z1 = geo.BOX_05
    return min(abs(p[0] - x0), abs(p[0] - x1), abs(p[1] - z0), abs(p[1] - z1)) <= 1.0


def _seam_extend(e, a, b, sub, lo_, hi_, paired):
    cut = getattr(e, 'cut', None) or [False, False]
    n = len(e.P)
    pre = a == 0 and cut[0] and _on_box_edge(e.P[0])
    post = b == n - 1 and cut[1] and _on_box_edge(e.P[-1])
    if not (pre or post):
        return sub, lo_, hi_, paired
    s = _Sub()
    P, D = sub.P, sub.D
    lo_, hi_, paired = np.asarray(lo_, float), np.asarray(hi_, float), np.asarray(paired, bool)
    if pre:
        P = np.vstack([P[:1] - D[:1] * SEAM_EXT, P])
        D = np.vstack([D[:1], D])
        lo_, hi_, paired = np.r_[lo_[0], lo_], np.r_[hi_[0], hi_], np.r_[paired[0], paired]
    if post:
        P = np.vstack([P, P[-1:] + D[-1:] * SEAM_EXT])
        D = np.vstack([D, D[-1:]])
        lo_, hi_, paired = np.r_[lo_, lo_[-1]], np.r_[hi_, hi_[-1]], np.r_[paired, paired[-1]]
    s.P, s.D = P, D
    return s, lo_, hi_, paired


def _sub(e, a, b):
    s = _Sub()
    s.P = e.P[a:b + 1]
    s.D = e.D[a:b + 1]
    return s


def _sub_s(e, s0, s1):
    c = rn.chain(e.P)
    if s1 - s0 < 0.5:
        return None
    ss = np.linspace(s0, s1, max(2, int(math.ceil((s1 - s0) / 3)) + 1))
    s = _Sub()
    s.P = np.stack([np.interp(ss, c, e.P[:, 0]), np.interp(ss, c, e.P[:, 1])], axis=1)
    s.D = rn.dirs_of(s.P)
    return s


def _tri(o, a, b, c, want):
    n = np.cross(np.subtract(b, a), np.subtract(c, a))
    if float(np.dot(n, want)) < 0:
        b, c = c, b
    o.append((a, b, c))


def _quad(o, a, b, c, d, want):
    _tri(o, a, b, c, want)
    _tri(o, a, c, d, want)


def _quad_l(res, kind, a, b, c, d, want):
    t = []
    _quad(t, a, b, c, d, want)
    for x in t:
        res.append((kind, x))


def _box_tris(kind, pc, d, r, wa, wc, y0, y1):
    corners = []
    for sa, sc in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        p = pc + d * wa * sa + r * wc * sc
        corners.append(p)
    res = []
    for k in range(4):
        p, q = corners[k], corners[(k + 1) % 4]
        mid = (p + q) / 2 - pc
        want = (float(mid[0]), 0.0, float(mid[1]))
        _quad_l(res, kind, (p[0], y0, p[1]), (q[0], y0, q[1]), (q[0], y1, q[1]), (p[0], y1, p[1]), want)
    return res
