"""
The Grand Hairpin (2026-11-04, `City Legends/Prompts/Realistic hairpin`, owner chose real curved
meshes: made here, one Import 3D by hand): the West Switchbacks' upper west bend rebuilt like Monaco's
famous one: 1+1, a tight 180 round a small teardrop island, the road climbing through the bend. The
shape was traced from the owner's reference photos (imports/refs/map/hairpin/), not from a map service.

Writes build/riviera/hairpin.json: the road's samples, the island's outline and the pieces' strips.
tools/hairpin_fbx.py (run with Blender) turns that into imports/new_map/Grand Hairpin.fbx.

usage (from Games/CityLegends): python tools/map_plan/hairpin.py
"""
import json
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import highway as hw  # noqa: E402
import north_roads  # noqa: E402

RIV = hw.RIV
FROM_I, TO_I = 399, 465   # West Switchbacks samples replaced between (their ends stay)
C = (10850.0, -100.0)     # the bend's middle
R = 46.0                  # the centre line's radius in the bend
HALF = 22.0               # half the road in the bend (1 + 1)
HALF_END = 32.0           # the streets' half width at both ends
TAPER = 70.0              # studs over which it narrows
STEP = 1.5                # between samples: smooth meshes
WALK = 10.0               # pavement width
KERB = 1.4                # red-and-white kerb width
ISLAND_R = HALF and (R - HALF - KERB - 0.6)  # the round end of the teardrop
ISLAND_TIP = (10925.0, -92.0)


def centre_line(ws):
    a0, a1 = ws[FROM_I - 12], ws[FROM_I]
    b0, b1 = ws[TO_I], ws[TO_I + 12]
    pts = [(a0[0], a0[2]), (a1[0], a1[2]), (10925, -30), (10885, -44)]
    for deg in range(90, 271, 15):
        th = math.radians(deg)
        pts.append((C[0] + R * math.cos(th), C[1] + R * math.sin(th)))
    pts += [(10890, -154), (10935, -160), (b0[0], b0[2]), (b1[0], b1[2])]
    line = hw.catmull(pts, False, per=24)
    P, _ = hw.resample(line, False, STEP)
    P, _ = hw.resample(north_roads.open_bends(P, R - 2.0, 1500), False, STEP)
    # only the part between the two joins
    i0 = int(np.argmin(np.linalg.norm(P - np.array((a1[0], a1[2])), axis=1)))
    i1 = int(np.argmin(np.linalg.norm(P - np.array((b0[0], b0[2])), axis=1)))
    return P[i0:i1 + 1]


def island_outline():
    """the teardrop: round round the bend's middle, a long point towards the legs"""
    pts = []
    tip = np.array(ISLAND_TIP)
    c = np.array(C)
    d = tip - c
    L = float(np.linalg.norm(d))
    base = math.atan2(d[1], d[0])
    # the tangent points from the tip to the circle
    off = math.acos(ISLAND_R / L)
    n = 48
    for k in range(n + 1):
        a = base + off + (2 * math.pi - 2 * off) * k / n
        pts.append((c[0] + ISLAND_R * math.cos(a), c[1] + ISLAND_R * math.sin(a)))
    pts.append((tip[0], tip[1]))
    return pts


def main():
    road = json.load(open(os.path.join(RIV, "roads.json")))["roads"]
    ws = [r for r in road if r["name"] == "West Switchbacks"][0]["s"]
    P = centre_line(ws)
    n = len(P)
    seg = np.linalg.norm(np.diff(P, axis=0), axis=1)
    s = np.concatenate([[0], np.cumsum(seg)])
    L = float(s[-1])
    y0, y1 = ws[FROM_I][1], ws[TO_I][1]
    # an even climb, eased into the old road's grade at both ends
    t = s / L
    Y = y0 + (y1 - y0) * t
    half = HALF + np.maximum((HALF_END - HALF) * np.clip(1 - s / TAPER, 0, 1), (HALF_END - HALF) * np.clip(1 - (L - s) / TAPER, 0, 1))
    D = hw.directions(P, False)
    grade = float(np.max(np.abs(np.diff(Y)) / np.maximum(seg, 1e-6)))
    out = {
        "name": "Grand Hairpin", "from": FROM_I, "to": TO_I, "centre": list(C), "R": R, "half": HALF, "walk": WALK, "kerb": KERB,
        "s": [[round(float(P[i, 0]), 3), round(float(Y[i]), 3), round(float(P[i, 1]), 3), round(float(D[i, 0]), 5), round(float(D[i, 1]), 5), round(float(half[i]), 3)] for i in range(n)],
        "island": [[round(a, 3), round(b, 3)] for a, b in island_outline()],
    }
    json.dump(out, open(os.path.join(RIV, "hairpin.json"), "w"), separators=(",", ":"))
    print("%d samples, %.0f studs, heights %.1f-%.1f, grade %.1f%%, min radius %.0f, island round end %.1f" % (n, L, Y.min(), Y.max(), grade * 100, hw.min_radius(P, False), ISLAND_R))


if __name__ == "__main__":
    main()
