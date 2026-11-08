"""
The loop link's centreline (owner, 2026-11-08: two red lines from the top junction across the East Switchbacks' first
loop to the second leg; then "make the corner less sharp"): a straight from the junction, then one right-hand arc of
radius R that meets the second leg tangentially at sample M of the switchbacks (counted from the junction end).
Height: flat for F studs at the junction, eased (E0) into a steady grade, eased (E1) out into the leg's own -10%.
Writes tools/riviera/looplink.json; then run looplink_data.py (the Studio tool's data lines).

    python tools/riviera/looplink_design.py [R] [M]      (first version R 45 M 93; now R 70 M 99)
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROADS = os.path.join(HERE, "..", "..", "build", "riviera", "roads.json")
R = float(sys.argv[1]) if len(sys.argv) > 1 else 70.0
M = int(sys.argv[2]) if len(sys.argv) > 2 else 99
F, E0, E1, LEG = 28.0, 24.0, 30.0, 0.10
STEP = 4.0

d = json.load(open(ROADS))
S = [r for r in d["roads"] if r["name"] == "East Switchbacks"][0]["s"][::-1]
P = [(p[0], p[1], p[2]) for p in S]
P0 = (17040.0, 183.1, -480.0)


def unit(x, z):
    L = math.hypot(x, z)
    return (x / L, z / L)


Q = P[M]
dq = unit(P[M + 2][0] - P[M - 2][0], P[M + 2][2] - P[M - 2][2])
right = (-dq[1], dq[0])
C = (Q[0] + R * right[0], Q[2] + R * right[1])
dx, dz = C[0] - P0[0], C[1] - P0[2]
L = math.hypot(dx, dz)
a = math.asin(R / L)
base = math.atan2(dz, dx)
tl = math.sqrt(L * L - R * R)
for sgn in (1, -1):
    ang = base + sgn * a
    T = (P0[0] + tl * math.cos(ang), P0[2] + tl * math.sin(ang))
    dd = unit(T[0] - P0[0], T[1] - P0[2])
    rr = (-dd[1], dd[0])
    if (C[0] - T[0]) * rr[0] + (C[1] - T[1]) * rr[1] > 0:
        break
a0 = math.atan2(T[1] - C[1], T[0] - C[0])
a1 = math.atan2(Q[2] - C[1], Q[0] - C[0])
while a1 < a0:
    a1 += 2 * math.pi
arc = R * (a1 - a0)
total = tl + arc
y0, y1 = P0[1], Q[1]
g = (y0 - y1 - LEG * E1 / 2) / (E0 / 2 + (total - F - E0 - E1) + E1 / 2)


def height(s):
    if s <= F:
        return y0
    u = s - F
    if u <= E0:
        return y0 - g * u * u / (2 * E0)
    yE0 = y0 - g * E0 / 2
    if s <= total - E1:
        return yE0 - g * (u - E0)
    v = s - (total - E1)
    yA = yE0 - g * (total - E1 - F - E0)
    return yA - (g * v + (LEG - g) * v * v / (2 * E1))


pts = []
n1 = int(math.ceil(tl / STEP))
for i in range(n1):
    s = tl * i / n1
    pts.append([P0[0] + dd[0] * s, height(s), P0[2] + dd[1] * s, dd[0], dd[1], s])
n2 = int(math.ceil(arc / STEP))
for i in range(n2 + 1):
    t = i / n2
    an = a0 + (a1 - a0) * t
    s = tl + arc * t
    pts.append([C[0] + R * math.cos(an), height(s), C[1] + R * math.sin(an), -math.sin(an), math.cos(an), s])
grades = [abs(pts[i + 1][1] - pts[i][1]) / max(1e-6, pts[i + 1][5] - pts[i][5]) for i in range(len(pts) - 1)]
out = {
    "note": "East Switchbacks loop link (owner 2026-11-08): new centreline from the junction to sample %d of the switchbacks (from the junction end); pts = x, y, z, dirx, dirz, s; made by looplink_design.py" % M,
    "P0": P0, "T": T, "C": C, "R": R, "Q": Q, "m": M, "straight": tl, "arc": arc, "half": 32,
    "grade": round(g, 4), "flat": F,
    "pts": [[round(v, 3) for v in p] for p in pts],
    "old_path": [[round(v, 2) for v in P[i]] for i in range(0, M + 1)],
}
json.dump(out, open(os.path.join(HERE, "looplink.json"), "w"), indent=0)
print("R %g M %d: straight %.0f (heading %.1f deg), arc %.0f (turn %.0f deg), total %.0f, grade %.1f%%, max %.1f%%, join %s" % (
    R, M, tl, math.degrees(math.atan2(dd[1], dd[0])), arc, math.degrees(a1 - a0), total, 100 * g, 100 * max(grades), Q))
