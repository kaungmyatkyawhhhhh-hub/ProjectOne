"""Close small bare patches inside the baked road surfaces (25 Nov 2026, road bug sweep; owner shot 3 "grass triangle on
the asphalt").

At some mouth corners the builder leaves a triangle of nothing between the carriageway, the corner kerb and the pavement
(a grass hole on the road, 76 sq studs on Shin Saw Pu Road x Lane #3155), and seams leave cracks of 1-10 sq studs. Any
hole of the union of every surface (asphalt, pavement, kerbs, median grass, bridge) smaller than MAX_AREA is closed with
the surface most of its rim touches (asphalt or pavement), on a plane fitted to that surface's corners round it.
Holes that are meant to be open are kept: roundabout middles, the data's islands / fills, anything under a deck.

    fill(by, cells, keep) -> {'filled': n, 'area': a}   by: bake's {(kind, cell): [tri]}; keep: shapely geometry to leave
    python roads05_gapfill.py test
"""
import collections, sys
import numpy as np
import shapely
from shapely.geometry import Polygon, Point, box as sbox
from shapely.strtree import STRtree

MAX_AREA = 600.0
MIN_AREA = 0.3
CELL = 1536.0
KINDS = ('R', 'P', 'KR', 'KW', 'MG', 'B')


def _flat(T):
    n = np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0])
    L = np.linalg.norm(n, axis=1) + 1e-12
    return T[(n[:, 1] / L > 0.5) & (L > 1e-6)]


def _polys(T):
    return [Polygon(t[:, [0, 2]]) for t in T]


def fill(by, cells, keep=None):
    stats = collections.Counter()
    cells = sorted(cells)
    for cell in cells:
        cx, cz = (int(v) for v in cell.split('x'))
        x0, z0 = cx * CELL, cz * CELL
        win = sbox(x0 - 60, z0 - 60, x0 + CELL + 60, z0 + CELL + 60)
        flat = {}
        for k in KINDS:
            Ts = []
            for dx in (-1, 0, 1):
                for dz in (-1, 0, 1):
                    L = by.get((k, '%dx%d' % (cx + dx, cz + dz)))
                    if L:
                        T = _flat(np.array(L, dtype=float).reshape(-1, 3, 3))
                        c = T.mean(1)
                        T = T[(c[:, 0] > x0 - 60) & (c[:, 0] < x0 + CELL + 60) & (c[:, 2] > z0 - 60) & (c[:, 2] < z0 + CELL + 60)]
                        Ts.append(T)
            flat[k] = np.concatenate(Ts) if Ts else np.zeros((0, 3, 3))
        if not len(flat['R']):
            continue
        allp = [p for k in KINDS for p in _polys(flat[k])]
        U = shapely.union_all([p.buffer(0.02, join_style=2) for p in allp if p.is_valid])
        cellbox = sbox(x0, z0, x0 + CELL, z0 + CELL)
        trees = {k: (STRtree(_polys(flat[k])), flat[k]) for k in ('R', 'P') if len(flat[k])}
        for g in getattr(U, 'geoms', [U]):
            for ring in g.interiors:
                h = Polygon(ring)
                if not (MIN_AREA < h.area < MAX_AREA) or not cellbox.contains(h.representative_point()):
                    continue
                if keep is not None and keep.intersects(h):
                    continue
                # which surface rims it, and the corners of that surface round it
                rim = h.buffer(1.0).difference(h.buffer(-0.01) if h.area > 1 else h)
                best, pts = None, None
                for k, (tr, T) in trees.items():
                    idx = tr.query(rim, predicate='intersects')
                    if len(idx) and (best is None or len(idx) > len(pts)):
                        best, pts = k, idx
                if best is None:
                    continue
                T = trees[best][1][pts]
                V = T.reshape(-1, 3)
                d = shapely.distance(shapely.points(V[:, 0], V[:, 2]), h.exterior)
                V = V[d < 3.0]
                if len(V) < 3:
                    V = T.reshape(-1, 3)
                A = np.c_[V[:, 0], V[:, 2], np.ones(len(V))]
                coef, *_ = np.linalg.lstsq(A, V[:, 1], rcond=None)
                hp = shapely.set_precision(h.buffer(0.02, join_style=2), 0)   # back out to the real rim
                for t in shapely.constrained_delaunay_triangles(hp).geoms:
                    xz = np.array(t.exterior.coords)[:3]
                    if Polygon(xz).area < 1e-6:
                        continue
                    y = xz[:, 0] * coef[0] + xz[:, 1] * coef[1] + coef[2] + 0.0
                    q = np.stack([xz[:, 0], y, xz[:, 1]], 1)
                    if np.cross(q[1] - q[0], q[2] - q[0])[1] < 0:
                        q = q[[0, 2, 1]]
                    by[(best, cell)].append(q)
                stats['filled'] += 1
                stats['area'] += round(h.area, 1)
                stats[best] += 1
    return dict(stats)


def _test():
    # a 100 x 40 asphalt slab (two 50-wide halves of wedge pairs) with a 6 x 6 hole, a pavement strip beside it,
    # and a 30 x 30 hole that is a roundabout middle (keep)
    def quad(x0, z0, x1, z1, y):
        a, b, c, d = (x0, y, z0), (x1, y, z0), (x1, y, z1), (x0, y, z1)
        return [np.array((a, c, b)), np.array((a, d, c))]
    R = []
    for (x0, z0, x1, z1) in [(0, 0, 100, 10), (0, 16, 100, 40), (0, 10, 40, 16), (46, 10, 100, 16)]:
        R += quad(x0, z0, x1, z1, 5.0)
    by = collections.defaultdict(list)
    by[('R', '0x0')] = list(R)
    by[('P', '0x0')] = quad(0, 40, 100, 48, 5.5)
    st = fill(by, ['0x0'])
    assert st.get('filled') == 1 and abs(st['area'] - 36) < 1.0, st
    new = np.array(by[('R', '0x0')][len(R):])
    assert np.allclose(new[:, :, 1], 5.0, atol=1e-6), new[:, :, 1]
    assert all(np.cross(t[1] - t[0], t[2] - t[0])[1] > 0 for t in new)
    by2 = collections.defaultdict(list)
    by2[('R', '0x0')] = list(R)
    st2 = fill(by2, ['0x0'], keep=Point(43, 13).buffer(1))
    assert not st2.get('filled'), st2
    print('roads05_gapfill test ok', st)


if __name__ == '__main__':
    if sys.argv[1:] == ['test']:
        _test()
