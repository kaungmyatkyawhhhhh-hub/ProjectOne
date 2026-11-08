"""
The East Switchbacks' traffic lanes onto the loop link (owner, 2026-11-08): in src/shared/RivieraLanes.lua each of the
road's lanes keeps its number of points (junction links use point numbers). The junction end stays where it is (the
Mountain Road's lanes end on the same point); the points from there to the first point past the join
(tools/riviera/looplink.json) are laid along the new road, easing from the junction end's offset to the lane's own.

    python tools/riviera/looplink_lanes.py
"""
import json
import math
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
LANES = os.path.join(HERE, "..", "..", "src", "shared", "RivieraLanes.lua")
link = json.load(open(os.path.join(HERE, "looplink.json")))
PATH = link["pts"]
OLD = link["old_path"]
Q = OLD[-1]
TOTAL = PATH[-1][5]
P0 = PATH[0]
D0 = (P0[3], P0[4])
DQ = (PATH[-1][3], PATH[-1][4])


def at(s, off):
    if s < 0:  # behind the start: straight back along its direction
        a = PATH[0]
        return (a[0] + a[3] * s - a[4] * off, a[1], a[2] + a[4] * s + a[3] * off)
    k = 0
    while k < len(PATH) - 2 and PATH[k + 1][5] < s:
        k += 1
    a, b = PATH[k], PATH[k + 1]
    t = max(0.0, min(1.0, (s - a[5]) / max(b[5] - a[5], 1e-6)))
    x = a[0] + (b[0] - a[0]) * t
    y = a[1] + (b[1] - a[1]) * t
    z = a[2] + (b[2] - a[2]) * t
    dx, dz = a[3] + (b[3] - a[3]) * t, a[4] + (b[4] - a[4]) * t
    L = math.hypot(dx, dz)
    dx, dz = dx / L, dz / L
    return (x - dz * off, y, z + dx * off)


def frame(p, o, d):
    """(along, to the right) of p in the frame of o heading d"""
    rx, rz = p[0] - o[0], p[2] - o[2]
    return rx * d[0] + rz * d[1], rx * (-d[1]) + rz * d[0]


def smooth(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def fix(m):
    way, lane = int(m.group(2)), int(m.group(3))
    v = [float(x) for x in m.group(4).split(",") if x.strip()]
    P = [[v[i], v[i + 1], v[i + 2]] for i in range(0, len(v) - 2, 3)]
    # junction end first
    rev = math.hypot(P[-1][0] - P0[0], P[-1][2] - P0[2]) < math.hypot(P[0][0] - P0[0], P[0][2] - P0[2])
    seq = P[::-1] if rev else P
    # the first point past the join (Q's cross line), near it
    j = next(i for i in range(1, len(seq)) if math.hypot(seq[i][0] - Q[0], seq[i][2] - Q[2]) < 45 and frame(seq[i], Q, DQ)[0] > 0)
    along_j, off = frame(seq[j], Q, DQ)
    along0, off0 = frame(seq[0], P0, D0)
    s_end = TOTAL + along_j
    for i in range(1, j):
        s = along0 + (s_end - along0) * i / j
        o = off0 + (off - off0) * smooth((s - along0) / 45.0)
        x, y, z = at(min(s, TOTAL), o)  # (s < 0 goes straight back)
        if s > TOTAL:  # past the join: straight on along the end direction
            x, z = x + DQ[0] * (s - TOTAL), z + DQ[1] * (s - TOTAL)
        seq[i] = [x, y + 0.1, z]
    P = seq[::-1] if rev else seq
    print("lane", way, lane, "points", len(P), "moved 1 ..", j - 1,
          "junction end off %.1f at %.1f, lane off %.1f, first kept point %.1f past the join" % (off0, along0, off, along_j))
    flat = ",".join("%s,%s,%s" % (round(p[0], 1), round(p[1], 1), round(p[2], 1)) for p in P)
    return m.group(1) + flat + m.group(5)


src = open(LANES, encoding="utf-8").read()
pat = re.compile(r'(\{ road = "East Switchbacks", way = (-?\d), lane = (\d),[^}]*?pts = \{ )([^}]*)( \})')
new, count = pat.subn(fix, src)
print("lanes", count)
open(LANES, "w", encoding="utf-8", newline="\n").write(new)
