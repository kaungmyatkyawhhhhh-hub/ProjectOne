"""Whole-Yangon map (14 Nov 2026): the road meshes, collision boxes and crossings of a batch, for roads.py.

Per 256-stud cell, triangle meshes in world studs (written to .glb by glb.py):
  R   asphalt: the union of every ground-level carriageway, junction corners rounded (a closing of RC studs), the medians
      and raised parts left out; raised parts (ramps, decks) are their own strips along the road
  P   pavement (+0.5) and the median's concrete tops, without the kerb strip
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
           L=(232, 232, 226), MG=(84, 116, 58), B=(150, 146, 138))


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
            r = (h > RAISE) & (net.fam_of.get(e.id) in net.fam_grade)
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
        for e, a, b in self.gpieces:
            lo, hi = self.lohi[e.id]
            sub = _sub(e, a, b)
            lo_, hi_ = lo[a:b + 1], hi[a:b + 1]
            paired = (e.w[a:b + 1] > 0.5) & bool(e.oneway)
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
        self.allowed_p = prep(self.allowed)
        self.zebras = []

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
            for end, key in ((0, e.a), (-1, e.b)):
                nodes.setdefault(key, []).append((e, end))
        npos = {k: v[0][0].P[v[0][1]] for k, v in nodes.items() if len(v) >= 3}
        keys = list(npos)
        if not keys:
            return []
        kt = cKDTree(np.array([npos[k] for k in keys]))
        done = set()
        zeb = []
        for kind, p in pts:
            d, j = kt.query(p)
            if kind == 'traffic_signals' and d < 40:
                key = keys[j]
                if key in done:
                    continue
                done.add(key)
                inc = nodes[key]
                if not any(e.look == 'main' for e, _ in inc):
                    continue
                rad = max(max(abs(self.lohi[e.id][0][end]), abs(self.lohi[e.id][1][end])) for e, end in inc)
                for e, end in inc:
                    if self.raised[e.id][0][end]:
                        continue
                    zeb.extend(self._zebra_on(e, end, rad + 6.0))
            elif kind == 'crossing':
                # a crossing on a main road away from junctions
                best = None
                for k in self.ctree.query(Point(p).buffer(6)):
                    e = self.meta[int(k)]
                    if e.look != 'main':
                        continue
                    dd = LineString(e.P).distance(Point(p))
                    if dd < 6 and (best is None or dd < best[0]):
                        best = (dd, e)
                if best and d > 60:
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
            a = q - d * 4 - r * 0.8
            b = q + d * 4 - r * 0.8
            c2 = q + d * 4 + r * 0.8
            d2 = q - d * 4 + r * 0.8
            out.append(Polygon([a, b, c2, d2]))
            o += 3.2
        return out

    # ------------------------------------------------------------ lines
    def line_polys(self):
        """white paint polygons per edge (ground and raised), already cut at junctions and zebras"""
        out = []   # (polygon, edge)
        for e in self.net.edges:
            if e.look != 'main':
                continue
            lo, hi = self.lohi[e.id]
            n = len(e.P)
            if n < 2:
                continue
            specs = []   # (offset array, width, dashed, role)
            if e.oneway:
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
                    out.append((rn.strip_poly(e, off - wd / 2, off + wd / 2), e, role))
                else:
                    # dashes 6 on, 6 off
                    s0 = 0.0
                    while s0 < c[-1] - 6:
                        a, b = s0, s0 + 6
                        sub = _sub_s(e, a, b)
                        if sub is not None:
                            oo = np.interp(rn.chain(sub.P) + a, c, off)
                            out.append((rn.strip_poly(sub, oo - wd / 2, oo + wd / 2), e, role))
                        s0 += 12
        # cut: lines stop where another road's carriageway lies (for the centre / lane lines only roads at least as big)
        res = []
        carr_b = {}
        zb = [z.buffer(0.6, join_style=2) for z in self.zebras]
        ztree = STRtree(zb) if zb else None
        for pg, e, role in out:
            if pg.is_empty:
                continue
            cut = []
            for k in self.ctree.query(pg):
                f = self.meta[int(k)]
                if f.id == e.id:
                    continue
                if rn.norm_name(f.name) == rn.norm_name(e.name) and f.name:
                    continue
                if role != 'edge' and f.rank > e.rank:
                    continue
                if f.oneway and e.oneway and f.layer == e.layer and abs(float(f.D[len(f.D) // 2] @ e.D[len(e.D) // 2])) > 0.95:
                    continue
                k = int(k)
                if k not in carr_b:
                    carr_b[k] = self.carr[k].buffer(1.0, join_style=2)
                if carr_b[k].intersects(pg):
                    cut.append(carr_b[k])
            g = pg
            if cut:
                g = g.difference(unary_union(cut))
            if ztree is not None:
                zz = [zb[int(k)] for k in ztree.query(pg)]
                if zz:
                    g = g.difference(unary_union(zz))
            for q in _polys(g):
                if q.area > 0.05:
                    res.append((q, e))
        return res

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
        ltree = STRtree([q for q, _ in lines]) if lines else None
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
                Rg = self._ground_cell(cb, cbm, ks, out) or Polygon()
            Rg = Rg.buffer(-0.3, join_style=2)   # paint stays clear of the kerb faces
            rz = Polygon()
            if self.rtree is not None:
                rk = [int(k) for k in self.rtree.query(cb)]
                if rk:
                    rz = unary_union([self.rfoot[k] for k in rk])
            paint = []
            if ltree is not None:
                for k in ltree.query(cb):
                    q, e = lines[int(k)]
                    paint.append(q)
            if self.zebras:
                for z in self.zebras:
                    if z.intersects(cb):
                        paint.append(z)
            if paint:
                # one union: paint pieces never overlap each other (the same height would flicker)
                g = unary_union(paint).intersection(cb).intersection(Rg).intersection(self.allowed)
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
        Rc = carr.buffer(RC, join_style=1).buffer(-RC, join_style=1)
        ko = [int(k) for k in self.otree.query(cbm)]
        outer = unary_union([self.outer[k] for k in ko]).intersection(cbm)
        Po = outer.buffer(RC * 0.75, join_style=1).buffer(-RC * 0.75, join_style=1).union(Rc)
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
                M = M.buffer(1.0, join_style=2).buffer(-1.0, join_style=2).buffer(-0.4).buffer(0.4)
        raised = Polygon()
        if self.rtree is not None:
            rk = [int(k) for k in self.rtree.query(cbm)]
            if rk:
                raised = unary_union([self.rfoot[k] for k in rk])
        R0 = Rc.difference(M).difference(raised)
        R = R0.buffer(-0.6, join_style=2).buffer(0.6, join_style=2).intersection(R0)
        sl = R0.difference(R)                      # asphalt slivers: into the median beside them, else kept
        if not sl.is_empty and not M.is_empty:
            into = sl.intersection(M.buffer(1.5))
            M = M.union(into)
            R = R.union(sl.difference(into))
        else:
            R = R0
        Pv = Po.difference(Rc).difference(raised)
        Mv = M.difference(raised)
        strip = R.buffer(KERB_W, join_style=2, mitre_limit=2.0)
        R_cell = R.intersection(cb).intersection(self.allowed)
        P_cell = Pv.difference(strip).intersection(cb).intersection(self.allowed)
        M_cell = Mv.difference(strip).intersection(cb).intersection(self.allowed)
        for pg in _polys(R_cell):
            self._flat(pg, out, 'R', 0.0)
        for pg in _polys(P_cell):
            self._flat(pg, out, 'P', PAVE_UP)
        for pg in _polys(M_cell):
            self._flat(pg, out, 'MG', PAVE_UP)
        # kerbs along R's boundary where pavement or median lies outside it
        nextto = prep(Pv.union(Mv))
        medp = prep(Mv) if not Mv.is_empty else None
        R_or = shapely.geometry.polygon.orient
        for pg in _polys(R):
            pg = R_or(pg, 1.0)
            for ring in [pg.exterior] + list(pg.interiors):
                self._kerb_ring(ring, cb, nextto, medp, out)
        return R

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
            main = self._is_main(mid)
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

    def _flat(self, pg, out, kind, up, own=None):
        """triangulate a flat-ish polygon, split into grid pieces (GRID under paint, 2 GRID elsewhere), heights from
        the field"""
        o = out.setdefault(kind, [])
        x0, z0, x1, z1 = pg.bounds
        GR = GRID if kind in ('R', 'L') else 2 * GRID
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
            q = shapely.segmentize(q, 6.0 if kind in ('R', 'L') else 10.0)
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
                    a0, b0 = at(i, 0.0), at(i + 1, 0.0)
                    a1, b1 = at(i, w), at(i + 1, w)
                    _quad_l(res, 'B', at(i, 0.0, 1.2), at(i + 1, 0.0, 1.2), at(i + 1, w, 1.2), at(i, w, 1.2), (0, 1, 0))
                    _quad_l(res, 'B', at(i, w, 0), at(i + 1, w, 0), at(i + 1, w, 1.2), at(i, w, 1.2), (R[i][0], 0, R[i][1]))
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
            specs = [(los + 1.2, 0.5, False), (outer - 1.2, 0.5, False)]
            if e.oneway:
                for k in range(1, e.nf):
                    specs.append((los + (outer - los) * k / e.nf, 0.4, True))
            else:
                specs.append((np.zeros(n), 0.5, False))
                for k in range(1, e.nf):
                    specs.append((outer * k / e.nf, 0.4, True))
                for k in range(1, e.nb):
                    specs.append((inner * k / e.nb, 0.4, True))
            for off, wd, dashed in specs:
                for i in range(n - 1):
                    if dashed and int(((c[i] + c[i + 1]) / 2) // 6) % 2 == 1:
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
                wa = 2.5
                wc = min(10.0, (outer[i] - inner[i]) * 0.3)
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


def _game_roads_only(net):
    game, _ = rn.game_roads()
    return unary_union([LineString([(q[0], q[2]) for q in r['s']]).buffer(max(max(q[6], q[7]) for q in r['s']) + 10.5, cap_style=2)
                        for r in game['roads']])


class _Sub:
    pass


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
