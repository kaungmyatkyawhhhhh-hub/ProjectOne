"""Median joints (26 Nov 2026, road bug sweep round 3; detector "median_stub" 169).

YangonRoads.buildMedians lays a median of constant width as blocks along the chord and shortens each block at both ends
by what the bend to the next one would overlap, plus 0.02 (so neighbours never overlap and flicker). That leaves a slit
at every joint: 0.04 studs on a straight, a V up to 0.4 on a bend, and the same between a block and the exact (triangle)
piece where the median widens. The asphalt shows through as a dark line across the red / white kerbs and the grass, and
every stretch between two slits counts as a separate small median.

The bake now closes them: inside the data's median zone, the top faces of the median parts (fill m; kerbs r + w) are
unioned, closed by CLOSE studs, and only the uncovered slivers (narrower than MAX_W) are filled with triangles at the
height of the top face next to them, plus their outer side faces down to the road. Nothing overlaps an existing face.

Also (short runs): a median run shorter than SHORT studs (two samples inside a junction box) is dropped whole.

    fill(parts, data, faces, surf) -> [(kind letter, triangle)], stats     faces: roads05_bake.faces_of
    short_zones(data) -> polygon of the short runs (used by roads05_nose.drop)
    python roads05_median_join.py test
"""
import collections, math, sys
import numpy as np
import shapely
from shapely.geometry import Polygon, Point, box as sbox
from shapely.strtree import STRtree

MIN_M = 0.15     # YangonRoads: a sample with s[9] (here s[8]) under this lays no median
PAD = 0.6
CLOSE = 0.3      # closes gaps up to 2 x CLOSE wide
MAX_W = 0.6      # a sliver wider than this is not a joint slit
SHORT = 24.0     # a median run shorter than this (studs) is a stray piece in a junction
CELL = 1536.0


def _med(q):
    return q[8] if len(q) > 8 else 0


def _seg_poly(a, b, ha, hb):
    pa, pb = (a[0], a[2]), (b[0], b[2])
    na, nb = (a[4], -a[3]), (b[4], -b[3])
    q = Polygon([(pa[0] + na[0] * ha, pa[1] + na[1] * ha), (pb[0] + nb[0] * hb, pb[1] + nb[1] * hb),
                 (pb[0] - nb[0] * hb, pb[1] - nb[1] * hb), (pa[0] - na[0] * ha, pa[1] - na[1] * ha)])
    return q if q.is_valid and q.area > 0 else None


def zones(data):
    out = []
    for r in data['roads']:
        s = r['s']
        for i in range(len(s) - 1):
            ma, mb = _med(s[i]), _med(s[i + 1])
            if ma < MIN_M and mb < MIN_M:
                continue
            q = _seg_poly(s[i], s[i + 1], max(ma, mb) + PAD, max(ma, mb) + PAD)
            if q is not None:
                out.append(q)
    return shapely.union_all(out) if out else Polygon()


def short_zones(data):
    out = []
    for r in data['roads']:
        s = r['s']
        i = 0
        while i < len(s):
            if _med(s[i]) < MIN_M:
                i += 1
                continue
            j = i
            while j + 1 < len(s) and _med(s[j + 1]) >= MIN_M:
                j += 1
            L = sum(math.hypot(s[k + 1][0] - s[k][0], s[k + 1][2] - s[k][2]) for k in range(i, j))
            if L < SHORT:
                for k in range(max(0, i - 1), min(len(s) - 1, j + 1)):
                    h = max(_med(s[k]), _med(s[k + 1])) + PAD
                    q = _seg_poly(s[k], s[k + 1], h, h)
                    if q is not None:
                        out.append(q)
            i = j + 1
    return shapely.union_all(out) if out else Polygon()


def _tops(tris):
    out = []
    for t in tris:
        t = np.asarray(t, float)
        n = np.cross(t[1] - t[0], t[2] - t[0])
        L = np.linalg.norm(n)
        if L > 1e-9 and n[1] / L > 0.5:
            out.append(t)
    return out


def _plane_y(t, x, z):
    n = np.cross(t[1] - t[0], t[2] - t[0])
    if abs(n[1]) < 1e-9:
        return float(t[:, 1].mean())
    return float(t[0][1] - (n[0] * (x - t[0][0]) + n[2] * (z - t[0][2])) / n[1])


def _up(t):
    a, b, c = t
    n = np.cross(b - a, c - a)
    return (a, c, b) if n[1] < 0 else (a, b, c)


def _out(t, inside):
    a, b, c = t
    n = np.cross(b - a, c - a)
    return (a, c, b) if n @ ((a + b + c) / 3 - inside) < 0 else (a, b, c)


def _road_y(surf, x, z, top):
    if surf is None:
        return top - 0.6
    hs = [h for h in surf.heights(x, z) if h < top - 0.05]
    return max(hs) if hs else top - 0.6


def fill(parts, data, faces, surf=None, only=None):
    """only: set of 1536 cells (slits whose middle lies in them); None = all"""
    Z = zones(data)
    stats = collections.Counter()
    if Z.is_empty:
        return [], dict(stats)
    shapely.prepare(Z)
    med = [p for p in parts if p[0] in ('r', 'w', 'm') and Z.contains(Point(p[2][0], p[2][2]))]
    bycell = collections.defaultdict(list)
    for p in med:
        bycell[(math.floor(p[2][0] / CELL), math.floor(p[2][2] / CELL))].append(p)
    extra = []
    for (cx, cz) in sorted(bycell):
        cell = '%dx%d' % (cx, cz)
        if only and cell not in only:
            continue
        ps = [p for dx in (-1, 0, 1) for dz in (-1, 0, 1) for p in bycell.get((cx + dx, cz + dz), [])
              if cx * CELL - 30 < p[2][0] < (cx + 1) * CELL + 30 and cz * CELL - 30 < p[2][2] < (cz + 1) * CELL + 30]
        for group in (('m',), ('r', 'w')):
            tops, kinds = [], []
            for p in ps:
                if p[0] in group:
                    for t in _tops(faces(p)):
                        tops.append(t)
                        kinds.append(p[0])
            if not tops:
                continue
            polys = [Polygon(t[:, [0, 2]]) for t in tops]
            good = [i for i, g in enumerate(polys) if g.is_valid and g.area > 1e-6]
            polys = [polys[i] for i in good]
            tops = [tops[i] for i in good]
            kinds = [kinds[i] for i in good]
            U0 = shapely.union_all(polys)
            C = U0.buffer(CLOSE, join_style=2).buffer(-CLOSE, join_style=2)
            # (candidates against the outline grown 0.003: the float hairlines along the long edges vanish; each one is
            # then grown back and clipped to the closed outline minus the exact tops: the fill never overlaps a top)
            cand = C.difference(U0.buffer(0.003, join_style=2))
            tree = STRtree(polys)
            for g0 in getattr(cand, 'geoms', [cand]):
                if g0.is_empty or g0.geom_type != 'Polygon' or g0.area < 1e-4:
                    continue
                w = 2 * g0.area / max(g0.length, 1e-9) + 0.006
                rp = g0.representative_point()
                # (each slit belongs to exactly one cell: the floor of its point, so a slit on a cell edge is filled once)
                if w > MAX_W or g0.area > 30 or (math.floor(rp.x / CELL), math.floor(rp.y / CELL)) != (cx, cz):
                    continue
                # a slit touches tops on two sides; a dent in one outline does not
                near = tree.query(g0.buffer(0.01))
                if len(set(int(i) for i in near)) < 2:
                    continue
                gg = g0.buffer(0.004, join_style=2).intersection(C).difference(U0)
                gl = [x for x in getattr(gg, 'geoms', [gg]) if x.geom_type == 'Polygon' and x.area > 1e-6]
                if not gl:
                    continue
                g = max(gl, key=lambda x: x.area)
                stats['slits'] += 1
                stats['area'] += g.area
                def yk(x, z):
                    i = int(tree.query_nearest(Point(x, z))[0])
                    return _plane_y(tops[i], x, z), kinds[i]
                tri = shapely.constrained_delaunay_triangles(g)
                for tg in getattr(tri, 'geoms', [tri]):
                    if tg.area < 1e-7 or not g.buffer(1e-6).contains(tg.representative_point()):
                        continue
                    xy = list(tg.exterior.coords)[:3]
                    pts = []
                    for x, z in xy:
                        y, k = yk(x, z)
                        pts.append(np.array([x, y, z]))
                    k = yk(*tg.representative_point().coords[0])[1]
                    extra.append((k, _up(tuple(pts))))
                # the slit's outer sides (on the closed outline): down to the road
                cxz = g.representative_point()
                cy, k0 = yk(cxz.x, cxz.y)
                inside = np.array([cxz.x, cy - 0.05, cxz.y])
                bound = C.boundary
                co = list(g.exterior.coords)
                for (x0, z0), (x1, z1) in zip(co[:-1], co[1:]):
                    if math.hypot(x1 - x0, z1 - z0) < 1e-4:
                        continue
                    mid = Point((x0 + x1) / 2, (z0 + z1) / 2)
                    if bound.distance(mid) > 0.01:
                        continue
                    y0, k = yk(x0, z0)
                    y1, _ = yk(x1, z1)
                    b0 = _road_y(surf, x0, z0, y0)
                    b1 = _road_y(surf, x1, z1, y1)
                    A, B = np.array([x0, y0, z0]), np.array([x1, y1, z1])
                    A2, B2 = np.array([x0, b0, z0]), np.array([x1, b1, z1])
                    extra.append((k, _out((A, B, B2), inside)))
                    extra.append((k, _out((A, B2, A2), inside)))
                    stats['sides'] += 1
    stats['area'] = round(stats['area'], 2)
    return extra, dict(stats)


def _test():
    import roads05_bake as B
    # a straight median along +z, 3 wide (kerbs 0.9 + fill), blocks of 6.4 with the builder's 0.02 trims, then a 10 deg bend
    data = dict(roads=[dict(name='a', s=[[0, 0, z, 0, 1, 0, 10, 10, 1.5] for z in (0, 6.4, 12.8, 19.2)])])
    parts = []
    for z0 in (0.0, 6.4, 12.8):
        a, b = z0 + 0.02, z0 + 6.4 - 0.02
        parts.append(('m', 'B', (0.0, 0.2, (a + b) / 2), (1, 0, 0), (0, 1, 0), (1.4, 0.4, b - a)))
        for side in (-1, 1):
            parts.append(('r', 'B', (side * 1.05, 0.25, (a + b) / 2), (1, 0, 0), (0, 1, 0), (0.9, 0.5, b - a)))
    extra, st = fill(parts, data, lambda p: B.faces_of(p))
    assert st['slits'] == 6, st         # 2 joints x (fill + 2 kerbs)
    # the filled tops + the parts' tops = one piece per group, and nothing overlaps
    for grp in (('m',), ('r',)):
        tops = [Polygon(np.asarray(t)[:, [0, 2]]) for p in parts if p[0] in grp for t in _tops(B.faces_of(p))]
        add = [Polygon(np.asarray(t)[:, [0, 2]]) for k, t in extra if k in grp and np.cross(t[1] - t[0], t[2] - t[0])[1] > 0]
        U = shapely.union_all(tops + add)
        assert abs(sum(g.area for g in tops + add) - U.area) < 1e-3, 'overlap'
        U = shapely.union_all([g.buffer(1e-6) for g in tops + add])
        n = len(getattr(U, 'geoms', [U]))
        assert n == (1 if grp == ('m',) else 2), (grp, n)
    # every added top triangle faces up and sits at its neighbours' height
    for k, t in extra:
        n = np.cross(t[1] - t[0], t[2] - t[0])
        if n[1] > 1e-9:
            assert abs(np.mean([p[1] for p in t]) - (0.4 if k == 'm' else 0.5)) < 1e-6, (k, t)
    # short runs: an 8-stud median between two clears is a stray piece
    d2 = dict(roads=[dict(name='b', s=[[0, 0, 0, 0, 1, 0, 10, 10, 0], [0, 0, 4, 0, 1, 0, 10, 10, 1.5],
                                       [0, 0, 12, 0, 1, 0, 10, 10, 1.5], [0, 0, 16, 0, 1, 0, 10, 10, 0],
                                       [0, 0, 100, 0, 1, 0, 10, 10, 1.5], [0, 0, 200, 0, 1, 0, 10, 10, 1.5]])])
    S = short_zones(d2)
    assert S.contains(Point(0, 8)) and not S.contains(Point(0, 150)), S
    print('roads05_median_join test ok', st)


if __name__ == '__main__':
    if sys.argv[1:] == ['test']:
        _test()
