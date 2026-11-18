"""roads05_kerb_cross.py (19 Nov 2026, map bug fixes): kerb pieces lying across each other (crumpled islands, twisted kerbs).

    python roads05_kerb_cross.py <tag> [cells...]
Reads build/city_1to1/roads05_<tag>/parts.pkl (the built parts the bake meshes), takes the kerb bands (kinds r / w) and
finds pairs that overlap by >= 30% of the smaller footprint with their long axes > 25 degrees apart and tops within 1.5.
Clusters them (16 studs) and prints the clusters, biggest first; writes kerb_cross_<tag>.json.
"""
import json, math, pickle, sys

import numpy as np
import shapely
from shapely.strtree import STRtree

BUILD = 'D:/ObsidianOne/Claude+Obsidian/Games/CityLegends/build/city_1to1/'
CELL = 1536.0


def main(tag, cells):
    parts = pickle.load(open(BUILD + 'roads05_%s/parts.pkl' % tag, 'rb'))
    ks = [p for p in parts if p[0] in ('r', 'w')]
    if cells:
        ks = [p for p in ks if '%dx%d' % (math.floor(p[2][0] / CELL), math.floor(p[2][2] / CELL)) in cells]
    polys, tops, axes = [], [], []
    for k, cls, pos, R, U, S in ks:
        R, U = np.array(R), np.array(U)
        B = np.cross(R, U)
        hx, hy, hz = S[0] / 2, S[1] / 2, S[2] / 2
        if cls == 'W':
            loc = [(sx * hx, -hy, sz * hz) for sx in (-1, 1) for sz in (-1, 1)] + [(sx * hx, hy, hz) for sx in (-1, 1)]
        else:
            loc = [(sx * hx, sy * hy, sz * hz) for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)]
        pts = np.array([np.array(pos) + R * a + U * b + B * c for a, b, c in loc])
        poly = shapely.convex_hull(shapely.multipoints(pts[:, [0, 2]]))
        polys.append(poly)
        tops.append(pts[:, 1].max())
        # long axis of the footprint: the hull's minimum rotated rectangle's longer side
        mrr = shapely.minimum_rotated_rectangle(poly)
        c = np.array(mrr.exterior.coords)[:4] if mrr.geom_type == 'Polygon' else np.zeros((4, 2))
        e1, e2 = c[1] - c[0], c[2] - c[1]
        ax = e1 if np.linalg.norm(e1) >= np.linalg.norm(e2) else e2
        n = np.linalg.norm(ax)
        axes.append(ax / n if n > 1e-9 else np.array([1.0, 0.0]))
    polys = np.array(polys, dtype=object)
    tree = STRtree(polys)
    a_idx, b_idx = tree.query(polys, predicate='intersects')
    hits = []
    for a, b in zip(a_idx, b_idx):
        if a >= b:
            continue
        if abs(tops[a] - tops[b]) > 1.5:
            continue
        ang = math.degrees(math.acos(min(1.0, abs(float(axes[a] @ axes[b])))))
        if ang < 25:
            continue
        inter = polys[a].intersection(polys[b]).area
        if inter < 0.3 * min(polys[a].area, polys[b].area) or inter < 0.4:
            continue
        c = polys[a].intersection(polys[b]).centroid
        hits.append((c.x, tops[a], c.y, ang, inter))
    # clusters
    cl = []
    for h in hits:
        for c in cl:
            if math.hypot(c['x'] - h[0], c['z'] - h[2]) < 16:
                c['n'] += 1
                break
        else:
            cl.append(dict(x=round(h[0], 1), y=round(h[1], 1), z=round(h[2], 1), n=1, ang=round(h[3])))
    cl.sort(key=lambda c: -c['n'])
    print(tag, 'kerb pieces', len(ks), 'crossing pairs', len(hits), 'clusters', len(cl))
    for c in cl[:40]:
        print(c)
    json.dump(dict(pairs=len(hits), clusters=cl), open(BUILD + 'kerb_cross_%s.json' % tag, 'w'))


if __name__ == '__main__':
    main(sys.argv[1], set(sys.argv[2:]))
