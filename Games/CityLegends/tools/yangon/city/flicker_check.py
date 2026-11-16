"""flicker_check.py (2026-11-16, owner rule "no flickering / overlapping parts"): find z-fighting in triangle sets.

A pair of triangles flickers when both face the same way (normals within ~3 degrees), their planes are closer than
GAP studs (0.05: the CLAUDE.md flicker rule), they overlap on that plane by more than MIN_AREA, and they do not look the
same (different look key: group / colour / part). Back-to-back faces (opposite normals) never both show, so they are
not counted. Identical-look overlaps inside one mesh (crossing grille bars) cannot be seen and are not counted either.

    from flicker_check import check
    bad = check([(tri, key), ...])   # tri = ((x, y, z), (x, y, z), (x, y, z)) in studs; key = any hashable look id
    -> list of (i, j, gap, area)
"""
import math
from collections import defaultdict

from shapely.geometry import Polygon

GAP = 0.05
MIN_AREA = 0.004
SLIVER = 0.02
COS = math.cos(math.radians(3.0))


def _n(t):
    a, b, c = t
    u = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
    v = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
    n = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
    L = math.sqrt(n[0] ** 2 + n[1] ** 2 + n[2] ** 2)
    if L < 1e-9:
        return None, 0.0
    return (n[0] / L, n[1] / L, n[2] / L), L / 2


def _basis(n):
    up = (0.0, 1.0, 0.0) if abs(n[1]) < 0.9 else (1.0, 0.0, 0.0)
    e1 = (up[1] * n[2] - up[2] * n[1], up[2] * n[0] - up[0] * n[2], up[0] * n[1] - up[1] * n[0])
    L = math.sqrt(sum(x * x for x in e1))
    e1 = tuple(x / L for x in e1)
    e2 = (n[1] * e1[2] - n[2] * e1[1], n[2] * e1[0] - n[0] * e1[2], n[0] * e1[1] - n[1] * e1[0])
    return e1, e2


def check(items, gap=GAP, min_area=MIN_AREA, limit=200000):
    tris = []
    for t, key in items:
        n, a = _n(t)
        if n is None or a < 1e-4:
            continue
        d = n[0] * t[0][0] + n[1] * t[0][1] + n[2] * t[0][2]
        tris.append((t, key, n, d))
    # buckets: quantised normal, quantised plane offset (cell = gap), and a coarse spatial cell
    B = defaultdict(list)
    for i, (t, key, n, d) in enumerate(tris):
        qn = (round(n[0] * 20), round(n[1] * 20), round(n[2] * 20))
        qd = math.floor(d / gap)
        cx = math.floor(sum(p[0] for p in t) / 3 / 64)
        cy = math.floor(sum(p[1] for p in t) / 3 / 64)
        cz = math.floor(sum(p[2] for p in t) / 3 / 64)
        B[(qn, qd, cx, cy, cz)].append(i)
    bad = []
    seen = set()
    for (qn, qd, cx, cy, cz), idx in B.items():
        cand = []
        for dd in (-1, 0, 1):
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    for dz in (-1, 0, 1):
                        cand += B.get((qn, qd + dd, cx + dx, cy + dy, cz + dz), [])
        if len(cand) < 2:
            continue
        for i in idx:
            ti, ki, ni, di = tris[i]
            e1 = e2 = None
            for j in cand:
                if j <= i or (i, j) in seen:
                    continue
                tj, kj, nj, dj = tris[j]
                if kj == ki:
                    continue
                if ni[0] * nj[0] + ni[1] * nj[1] + ni[2] * nj[2] < COS:
                    continue
                g = abs(di - dj)
                if g >= gap:
                    continue
                # every corner of tj within gap of ti's plane (the offset test alone can pair far planes)
                g = max(abs(ni[0] * p[0] + ni[1] * p[1] + ni[2] * p[2] - di) for p in tj)
                if g >= gap:
                    continue
                seen.add((i, j))
                if e1 is None:
                    e1, e2 = _basis(ni)
                P = lambda t: Polygon([(p[0] * e1[0] + p[1] * e1[1] + p[2] * e1[2], p[0] * e2[0] + p[1] * e2[1] + p[2] * e2[2]) for p in t])
                try:
                    ar = P(ti).intersection(P(tj)).area
                except Exception:
                    continue
                if ar > min_area:
                    # a sliver narrower than SLIVER (seam rounding between pieces that butt) is under a pixel: skipped
                    ov = P(ti).intersection(P(tj))
                    r = ov.minimum_rotated_rectangle
                    c = list(r.exterior.coords) if r.geom_type == "Polygon" else []
                    if len(c) >= 4:
                        w = min(math.dist(c[0], c[1]), math.dist(c[1], c[2]))
                        if w < SLIVER:
                            continue
                    bad.append((i, j, g, ar))
                    if len(bad) >= limit:
                        return bad, tris
    return bad, tris
