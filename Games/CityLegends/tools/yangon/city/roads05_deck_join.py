"""Deck joins: no two road surfaces lying on each other (25 Nov 2026, DECK OVERLAP FIX agent;
vault 'City Legends/2026-11-25 Deck overlaps fix.md').

At a deck foot (the deck's first slab on the ground road's end) and where two decks meet (Lanmadaw x Myoma Kyaung,
Gyophyu / Alan Pya onto the Sule deck, Thamaing Station onto Bayint Naung Bridge 2) the builder lays both roads' slabs
over the same spot, 0 to 1.4 studs apart and tilted against each other: the lower one pokes through the upper one
(z-fighting where they cross). The Studio scan of 25 Nov found it at 13 deck ends.

roads05_bake.bake calls resolve() on the carriageway ('R') triangles near decks: where two up-facing triangles overlap
in plan within GAP studs of each other, each keeps only the part where it is the top surface (the upper envelope).
The remains are re-triangulated on their own plane. Triangles that only share an edge are untouched.

    python roads05_deck_join.py test
"""
import numpy as np
import shapely
from shapely.geometry import Polygon, box as sbox
from shapely.strtree import STRtree
from shapely.ops import unary_union

GAP = 1.6      # two surfaces closer than this over their overlap are one road surface laid twice
MIN_AREA = 0.05


def _plane(t):
    """y = A x + B z + C through a triangle"""
    (x1, y1, z1), (x2, y2, z2), (x3, y3, z3) = t
    M = np.array([[x1, z1, 1.0], [x2, z2, 1.0], [x3, z3, 1.0]])
    return np.linalg.solve(M, np.array([y1, y2, y3]))


def _up(t):
    n = np.cross(t[1] - t[0], t[2] - t[0])
    L = np.linalg.norm(n)
    return L > 1e-9 and n[1] / L > 0.5


def _halfplane(a, b, c, bounds):
    """polygon of {a x + b z + c > 0} within bounds (big enough)"""
    x0, z0, x1, z1 = bounds
    x0 -= 10; z0 -= 10; x1 += 10; z1 += 10
    corners = [(x0, z0), (x1, z0), (x1, z1), (x0, z1)]
    out = []
    n = len(corners)
    for k in range(n):
        p, q = corners[k], corners[(k + 1) % n]
        fp, fq = a * p[0] + b * p[1] + c, a * q[0] + b * q[1] + c
        if fp > 0:
            out.append(p)
        if (fp > 0) != (fq > 0):
            t = fp / (fp - fq)
            out.append((p[0] + t * (q[0] - p[0]), p[1] + t * (q[1] - p[1])))
    return Polygon(out) if len(out) >= 3 else None


def resolve(tris, zone=None):
    """tris: list of (a, b, c) numpy points (the 'R' triangles). zone: shapely geometry (plan) to work in, or None.
    Returns (new list, stats)."""
    idx = []
    for i, t in enumerate(tris):
        if not _up(t):
            continue
        if zone is not None:
            m = (t[0] + t[1] + t[2]) / 3
            if not zone.contains(shapely.points(m[0], m[2])):
                continue
        idx.append(i)
    polys = [Polygon([(p[0], p[2]) for p in tris[i]]) for i in idx]
    planes = [_plane(tris[i]) for i in idx]
    tree = STRtree(polys)
    loss = {}
    pairs = 0
    for a_, P in enumerate(polys):
        for b_ in tree.query(P):
            b_ = int(b_)
            if b_ <= a_:
                continue
            O = P.intersection(polys[b_])
            if O.is_empty or O.area < MIN_AREA:
                continue
            pa, pb = planes[a_], planes[b_]
            d = pb - pa                     # f = y_b - y_a = d0 x + d1 z + d2
            xs = np.array(O.exterior.coords) if O.geom_type == 'Polygon' else np.array([c for g in O.geoms if g.geom_type == 'Polygon' for c in g.exterior.coords])
            if len(xs) == 0:
                continue
            f = d[0] * xs[:, 0] + d[1] * xs[:, 1] + d[2]
            if np.abs(f).max() > GAP:
                continue
            pairs += 1
            if np.abs(f).max() < 0.01:
                lose_a, lose_b = None, O     # coplanar: the later one gives way
            else:
                H = _halfplane(d[0], d[1], d[2], O.bounds)   # where b is above a
                lose_a = O.intersection(H) if H is not None else None
                lose_b = O.difference(H) if H is not None else O
            for k, g in ((a_, lose_a), (b_, lose_b)):
                if g is not None and not g.is_empty and g.area > 1e-6:
                    loss.setdefault(k, []).append(g)
    out = [t for i, t in enumerate(tris)]
    drop = set()
    added = []
    for k, gs in loss.items():
        i = idx[k]
        keep = polys[k].difference(unary_union(gs))
        drop.add(i)
        if keep.is_empty or keep.area < MIN_AREA:
            continue
        A, B, C = planes[k]
        for tri in shapely.constrained_delaunay_triangles(keep).geoms if hasattr(shapely, 'constrained_delaunay_triangles') else shapely.ops.triangulate(keep):
            if tri.area < 1e-4 or not keep.buffer(1e-6).contains(tri):
                continue
            cs = list(tri.exterior.coords)[:3]
            pts = [np.array([x, A * x + B * z + C, z]) for x, z in cs]
            n = np.cross(pts[1] - pts[0], pts[2] - pts[0])
            if n[1] < 0:
                pts[1], pts[2] = pts[2], pts[1]
            added.append(tuple(pts))
    res = [t for i, t in enumerate(out) if i not in drop] + added
    return res, dict(pairs=pairs, cut=len(drop), new=len(added))


def _area_cover(tris, x, z):
    """surface heights at a plan point (up faces)"""
    hs = []
    for t in tris:
        P = Polygon([(p[0], p[2]) for p in t])
        if P.buffer(1e-9).contains(shapely.points(x, z)):
            A, B, C = _plane(t)
            hs.append(A * x + B * z + C)
    return hs


def test():
    def T(a, b, c):
        return tuple(np.array(p, float) for p in (a, b, c))
    # ground slab y 0 (two triangles, 0..20 x 0..20), deck end slab from x 10..30 sloping 0.4 -> -0.4 (crosses the ground)
    g = [T((0, 0, 0), (0, 0, 20), (20, 0, 20)), T((0, 0, 0), (20, 0, 20), (20, 0, 0))]
    def y(x):
        return 0.4 - 0.04 * (x - 10)
    dk = [T((10, y(10), 0), (10, y(10), 20), (30, y(30), 20)), T((10, y(10), 0), (30, y(30), 20), (30, y(30), 0))]
    tris, st = resolve(g + dk)
    assert st['pairs'] > 0, st
    for x in (2, 11, 14, 19, 25):
        for z in (3, 10, 17):
            hs = _area_cover(tris, x, z)
            want = max([0.0] if x <= 20 else []) if x <= 20 else None
            top = max(0.0 if x <= 20 else -9, y(x) if x >= 10 else -9)
            assert len(hs) == 1, (x, z, hs)            # one surface everywhere
            assert abs(hs[0] - top) < 1e-6, (x, z, hs, top)
    # neighbours sharing an edge are left alone
    t2, st2 = resolve(g)
    assert st2 == dict(pairs=0, cut=0, new=0) and len(t2) == 2
    # far apart (a real deck over a road, 15 up): untouched
    hi = [T((0, 15, 0), (0, 15, 20), (20, 15, 20))]
    t3, st3 = resolve(g + hi)
    assert st3['pairs'] == 0
    # coplanar copies: one stays
    t4, st4 = resolve(g + g)
    for x, z in ((5, 2), (15, 18), (10, 9)):
        assert len(_area_cover(t4, x, z)) == 1, _area_cover(t4, x, z)
    print('test ok', st, st4)


if __name__ == '__main__':
    import sys
    if sys.argv[1:] == ['test']:
        test()
