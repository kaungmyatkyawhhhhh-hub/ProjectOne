"""Exact clip of baked road triangles to a subset's districts (25 Nov 2026, road bug sweep).

The bake used to keep a PART when its centre lay in the subset's districts. A road quad is two wedges, and where a district
edge crosses a road one wedge of each pair has its centre on the other side: the cell kept every other triangle (the
sawtooth teeth / slivers sticking into the grass, owner shot 2), and the far build never filled the gaps when it was
built from other data or not at all (map edge). Now the bake keeps the parts near the edge too and cuts every triangle
exactly on the district edge: both sides meet on one straight line.

    clip_tris(T, poly) -> T'    T: (N, 3, 3) world triangles; poly: shapely (Multi)Polygon in x / z
    python roads05_clip.py test
"""
import sys
import numpy as np
import shapely
from shapely.geometry import Polygon, Point, box as sbox

PAD = 60.0   # parts this far outside the districts are kept for the exact cut (> the longest road wedge's half)


def _lift(t, xz):
    """y on triangle t's plane at points xz (k, 2)."""
    n = np.cross(t[1] - t[0], t[2] - t[0])
    if abs(n[1]) < 1e-12:
        return np.full(len(xz), t[:, 1].mean())
    return t[0, 1] - (n[0] * (xz[:, 0] - t[0, 0]) + n[2] * (xz[:, 1] - t[0, 2])) / n[1]


def _tris_of(g):
    out = []
    for p in getattr(g, 'geoms', [g]):
        if p.geom_type != 'Polygon' or p.area < 1e-6:
            continue
        p = shapely.set_precision(p, 0)
        for t in shapely.constrained_delaunay_triangles(p).geoms:
            if t.area > 1e-7:
                out.append(np.array(t.exterior.coords)[:3])
    return out


def clip_tris(T, poly):
    if len(T) == 0:
        return T
    shapely.prepare(poly)
    xs, zs = T[:, :, 0], T[:, :, 2]
    pts = shapely.points(xs.ravel(), zs.ravel())
    inside = shapely.contains_xy(poly, xs.ravel(), zs.ravel()).reshape(-1, 3)
    keep = inside.all(1)
    out = [T[keep]]
    rest = np.where(~keep)[0]
    n = np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0])
    L = np.linalg.norm(n, axis=1) + 1e-12
    flat = np.abs(n[:, 1]) / L > 0.05
    extra = []
    for i in rest:
        t = T[i]
        if not flat[i]:
            c = t.mean(0)
            if poly.contains(Point(c[0], c[2])):
                extra.append(t)   # a wall face (kerb side): whole, by its middle
            continue
        tp = Polygon(t[:, [0, 2]])
        if not tp.is_valid or tp.area < 1e-9:
            continue
        g = tp.intersection(poly)
        if g.is_empty:
            continue
        up = n[i, 1] > 0
        for xz in _tris_of(g):
            y = _lift(t, xz)
            q = np.stack([xz[:, 0], y, xz[:, 1]], 1)
            m = np.cross(q[1] - q[0], q[2] - q[0])
            if (m[1] > 0) != up:   # keep the original winding (which side shows)
                q = q[[0, 2, 1]]
            extra.append(q)
    if extra:
        out.append(np.array(extra))
    return np.concatenate(out)


def _test():
    # a road strip 0..100 x 0..20 made of wedge pairs every 10, cut by a district edge at x = 47 (slanted)
    T = []
    for x in range(0, 100, 10):
        a, b, c, d = (x, 1, 0), (x + 10, 1, 0), (x + 10, 1, 20), (x, 1, 20)
        T += [(a, c, b), (a, d, c)]
    T = np.array(T, float)
    poly = Polygon([(-10, -10), (47, -10), (40, 30), (-10, 30)])
    C = clip_tris(T, poly)
    area = sum(Polygon(t[:, [0, 2]]).area for t in C)
    want = Polygon([(0, 0), (47 - 7 * 10 / 40, 0), (47 - 7 * 30 / 40, 20), (0, 20)]).area
    assert abs(area - want) < 1e-6, (area, want)
    assert np.allclose(C[:, :, 1], 1)
    for t in C:   # winding kept (the input's normals point up)
        assert np.cross(t[1] - t[0], t[2] - t[0])[1] > 0
    # the outline is one straight cut: no tooth
    U = shapely.union_all([Polygon(t[:, [0, 2]]).buffer(1e-6) for t in C]).simplify(1e-4)
    assert len(U.exterior.coords) == 5, list(U.exterior.coords)
    # the far side's own clip fills the rest exactly
    far = sbox(-100, -100, 200, 200).difference(poly)
    C2 = clip_tris(T, far)
    tot = area + sum(Polygon(t[:, [0, 2]]).area for t in C2)
    assert abs(tot - 2000) < 1e-6, tot
    print('roads05_clip test ok', len(C), len(C2))


if __name__ == '__main__':
    if sys.argv[1:] == ['test']:
        _test()
