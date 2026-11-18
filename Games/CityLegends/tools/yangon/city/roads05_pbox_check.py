"""roads05_pbox_check.py (19 Nov 2026, map bug fixes): invisible pavement collision.

roads05_bake.collision lays pavement boxes (RoadBox "P", top = road + 0.5) along every road's whole length from the road
data, whether or not the builder laid a pavement there. Where the builder cut the pavement (junction mouths, driveways,
gores, islands dropped) the box stands 0.5 over visible asphalt: a car hits a kerb nobody can see.

    python roads05_pbox_check.py <tag> <collide dir> [<tag> <collide dir> ...]
For each P box of the collide files: points on its top (every 1.5 along, 3 across) that no visible pavement / kerb /
median part covers while a road part does = "bad". Prints per-file counts; writes pbox_check.json (bad boxes).
"""
import glob, json, math, os, pickle, sys

import numpy as np
import shapely
from shapely.strtree import STRtree

BUILD = 'D:/ObsidianOne/Claude+Obsidian/Games/CityLegends/build/city_1to1/'
VIS = ('P', 'r', 'w', 'm')


def footprints(parts, kinds):
    """convex hulls (XZ) and top heights of the parts of the given kinds"""
    sel = [p for p in parts if p[0] in kinds]
    polys, tops = [], []
    for k, cls, pos, R, U, S in sel:
        R = np.array(R)
        U = np.array(U)
        B = np.cross(R, U)
        hx, hy, hz = S[0] / 2, S[1] / 2, S[2] / 2
        if cls == 'W':
            loc = [(sx * hx, -hy, sz * hz) for sx in (-1, 1) for sz in (-1, 1)] + [(sx * hx, hy, hz) for sx in (-1, 1)]
        else:
            loc = [(sx * hx, sy * hy, sz * hz) for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)]
        pts = np.array([np.array(pos) + R * a + U * b + B * c for a, b, c in loc])
        polys.append(shapely.convex_hull(shapely.multipoints(pts[:, [0, 2]])))
        tops.append(pts[:, 1].max())
    return np.array(polys, dtype=object), np.array(tops)


def boxes(cdir):
    out = []
    for f in sorted(glob.glob(os.path.join(cdir, '*.txt'))):
        for line in open(f):
            v = line.split()
            if len(v) == 13:
                out.append((v[0], np.array(list(map(float, v[1:4]))), np.array(list(map(float, v[4:7]))),
                            np.array(list(map(float, v[7:10]))), np.array(list(map(float, v[10:13])))))
    return out


def samples(c, R, U, S):
    """points on the top face: 3 across (at -0.35, 0, 0.35 of the width), every 1.5 along"""
    Bk = np.cross(R, U)
    top = c + U * S[1] / 2
    n = max(1, int(S[2] / 1.5))
    pts = []
    for i in range(n + 1):
        t = (i / n - 0.5) * (S[2] - 0.6)
        for a in (-0.35, 0, 0.35):
            pts.append(top + R * a * S[0] + Bk * t)
    return np.array(pts)


def check(tag, cdir):
    parts = pickle.load(open(BUILD + 'roads05_%s/parts.pkl' % tag, 'rb'))
    vp, vt = footprints(parts, VIS)
    rp, rt = footprints(parts, ('R',))
    vtree, rtree = STRtree(vp), STRtree(rp)
    res = []
    bxs = [b for b in boxes(cdir) if b[0] == 'P']
    for k, c, R, U, S in bxs:
        pts = samples(c, R, U, S)
        g = shapely.points(pts[:, [0, 2]])
        top = pts[:, 1]
        cov = np.zeros(len(pts), bool)
        road = np.zeros(len(pts), bool)
        pi, ti = vtree.query(g, predicate='intersects')
        for a, b in zip(pi, ti):
            if top[a] - 2.5 < vt[b] < top[a] + 1.5:
                cov[a] = True
        pi, ti = rtree.query(g, predicate='intersects')
        for a, b in zip(pi, ti):
            if top[a] - 2.0 < rt[b] < top[a] + 0.2:
                road[a] = True
        bad = (~cov) & road
        if bad.sum():
            res.append(dict(c=c.round(2).tolist(), R=R.tolist(), U=U.tolist(), S=S.tolist(), bad=int(bad.sum()), n=len(pts),
                            pts=pts[bad][:, [0, 1, 2]].round(1).tolist()))
    print(tag, cdir, 'P boxes', len(bxs), 'with bad points', len(res), 'bad points', sum(r['bad'] for r in res))
    return res


if __name__ == '__main__':
    a = sys.argv[1:]
    allres = {}
    for i in range(0, len(a), 2):
        allres[a[i] + ':' + a[i + 1]] = check(a[i], a[i + 1])
    json.dump(allres, open(BUILD + 'pbox_check.json', 'w'))
