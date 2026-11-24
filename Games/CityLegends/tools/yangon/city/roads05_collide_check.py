"""(24 Nov 2026, ROAD STEPS FIX agent) offline check of the bake's collision boxes against the visual road surface.

    python roads05_collide_check.py <tag> x0 z0 x1 z1 [step]

Runs roads05_bake.collision on roads05_<tag> (parts.pkl + roads.json, as the bake does) and walks a grid over the
box (every `step` studs, default 2) where the visual carriageway (R top triangles) is. At each point the driving
surface is the highest R / D box top within 3 studs of the visual surface (what a car's ray meets). It prints:
  off  : how far that box top is from the visual surface (worst + count over 0.3); 'none' = no box there (a crack)
  step : a jump in the box surface between two grid neighbours beyond the visual surface's own change there
"""
import json, math, os, pickle, sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import roads05_bake as RB


def boxes_of(rows):
    out = []
    for r in rows:
        f = r.split()
        if f[0] not in ('R', 'D'):
            continue
        v = list(map(float, f[1:]))
        c, R, U, S = np.array(v[0:3]), np.array(v[3:6]), np.array(v[6:9]), np.array(v[9:12])
        F = np.cross(R, U)
        out.append((c, R, U, F, S))
    return out


def top_at(b, x, z):
    c, R, U, F, S = b
    if abs(U[1]) < 0.5:
        return None
    y = c[1] + (S[1] / 2 - U[0] * (x - c[0]) - U[2] * (z - c[2])) / U[1]
    p = np.array([x, y, z]) - c
    if abs(p @ R) <= S[0] / 2 + 1e-6 and abs(p @ F) <= S[2] / 2 + 1e-6:
        return y
    return None


def run(tag, x0, z0, x1, z1, step=2.0, rows=None, quiet=False):
    D = RB.od(tag)
    parts = pickle.load(open(os.path.join(D, 'parts.pkl'), 'rb'))
    data = json.load(open(os.path.join(D, 'roads.json'), encoding='utf-8'))
    tris = [t for p in parts if p[0] == 'R' for t in RB.faces_of(p)]
    near = [t for t in tris if x0 - 4 <= t[0][0] <= x1 + 4 and z0 - 4 <= t[0][2] <= z1 + 4]
    surf = RB.Surface(tris)
    if rows is None:
        rows = RB.collision(data, surf, parts)
    B = [b for b in boxes_of(rows) if x0 - 200 < b[0][0] < x1 + 200 and z0 - 200 < b[0][2] < z1 + 200]
    local = RB.Surface(near)
    xs = np.arange(x0, x1, step)
    zs = np.arange(z0, z1, step)
    vis = {}
    col = {}
    worst, nbad, holes = (0.0, None), 0, []
    for x in xs:
        for z in zs:
            hs = local.heights(x, z)
            if not hs:
                continue
            h = max(hs)
            vis[(x, z)] = h
            tops = [y for y in (top_at(b, x, z) for b in B) if y is not None and abs(y - h) < 3]
            if not tops:
                holes.append((round(x), round(z)))
                continue
            y = max(tops)
            col[(x, z)] = y
            if abs(y - h) > 0.3:
                nbad += 1
            if abs(y - h) > abs(worst[0]):
                worst = (y - h, (round(x), round(z)))
    sw, swat, nstep = 0.0, None, 0
    for (x, z), y in col.items():
        for dx, dz in ((step, 0), (0, step)):
            q = (x + dx, z + dz)
            if q in col:
                d = (col[q] - y) - (vis[q] - vis[(x, z)])
                if abs(d) > 0.3:
                    nstep += 1
                if abs(d) > abs(sw):
                    sw, swat = d, (round(x), round(z))
    res = dict(points=len(vis), off_worst=round(worst[0], 2), off_at=worst[1], off_over_03=nbad, holes=len(holes),
               hole_at=holes[:3], step_worst=round(sw, 2), step_at=swat, steps_over_03=nstep)
    if not quiet:
        print(tag, (x0, z0, x1, z1), json.dumps(res))
    return res


if __name__ == '__main__':
    a = sys.argv
    run(a[1], *map(float, a[2:6]), step=float(a[6]) if len(a) > 6 else 2.0)
