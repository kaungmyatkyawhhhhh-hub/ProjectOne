"""
Puts the Grand Hairpin into the traffic lanes and the road list (2026-11-04), after hairpin.py:
  * src/shared/RivieraLanes.lua: the four West Switchbacks lanes follow the new bend between the two
    joins. Each lane keeps its number of points, so every link and turn pick stays valid.
  * build/riviera/roads_hw.json: the road's samples ("Grand Hairpin") for Roads.build in Studio.

usage (from Games/CityLegends): python tools/map_plan/hairpin_lanes.py
"""
import json
import math
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "..")
RIV = os.path.join(ROOT, "build", "riviera")
LANES = os.path.join(ROOT, "src", "shared", "RivieraLanes.lua")


def main():
    hp = json.load(open(os.path.join(RIV, "hairpin.json")))
    S = hp["s"]
    arc = [0.0]
    for i in range(1, len(S)):
        arc.append(arc[-1] + math.dist((S[i][0], S[i][2]), (S[i - 1][0], S[i - 1][2])))
    ws = [r for r in json.load(open(os.path.join(RIV, "roads.json")))["roads"] if r["name"] == "West Switchbacks"][0]["s"]
    p0 = (ws[hp["from"]][0], ws[hp["from"]][2])
    p1 = (ws[hp["to"]][0], ws[hp["to"]][2])

    def at_arc(u):
        for i in range(1, len(S)):
            if arc[i] >= u:
                t = (u - arc[i - 1]) / max(arc[i] - arc[i - 1], 1e-6)
                a, b = S[i - 1], S[i]
                return [a[k] + (b[k] - a[k]) * t for k in range(6)]
        return S[-1]

    src = open(LANES, encoding="utf-8", newline="").read()
    done = [0]

    def fix(m):
        lane = int(m.group(2))
        nums = [float(x) for x in m.group(3).split(",") if x.strip()]
        pts = [nums[i:i + 3] for i in range(0, len(nums), 3)]
        k0 = min(range(len(pts)), key=lambda k: math.dist((pts[k][0], pts[k][2]), p0))
        k1 = min(range(len(pts)), key=lambda k: math.dist((pts[k][0], pts[k][2]), p1))
        lo, hi = min(k0, k1), max(k0, k1)
        inner = hi - lo - 1
        back = k0 > k1  # the lane runs against the bend's samples
        for j in range(inner):
            u = arc[-1] * (j + 1) / (inner + 1)
            if back:
                u = arc[-1] - u
            q = at_arc(u)
            dx, dz = (-q[3], -q[4]) if back else (q[3], q[4])
            n = math.hypot(dx, dz) or 1
            rx, rz = -dz / n, dx / n
            half = q[5]
            o = min(24.0, max(4.0, half - 8.0)) if lane == 2 else min(8.0, max(3.0, half / 2.0))
            pts[lo + 1 + j] = [round(q[0] + rx * o, 1), round(q[1] + 0.15, 1), round(q[2] + rz * o, 1)]
        done[0] += 1
        return m.group(0).replace(m.group(3), ",".join(("%g" % v) for q in pts for v in q))

    src = re.sub(r'road = "West Switchbacks", way = (-?\d+), lane = (\d+),[^\n]*?pts = \{ ([^}]*) \}', fix, src)
    assert done[0] == 4, done[0]
    open(LANES, "w", encoding="utf-8", newline="").write(src)

    a = json.load(open(os.path.join(RIV, "roads.json")))
    a["roads"] = a["roads"] + json.load(open(os.path.join(RIV, "highway.json")))["roads"] + json.load(open(os.path.join(RIV, "north.json")))["roads"]
    # (the old stretch out of the list: the road builder leaves out slabs that lie on a bigger road)
    for r in a["roads"]:
        if r["name"] == "West Switchbacks":
            r["s"] = r["s"][:hp["from"] + 1] + r["s"][hp["to"]:]
    step = S[::3]
    if step[-1] is not S[-1]:
        step = step + [S[-1]]
    a["roads"].append({"name": "Grand Hairpin", "kind": "street", "closed": False, "rank": -1, "aligned": True,
                       "s": [[q[0], q[1], q[2], q[3], q[4], 0, q[5], q[5]] for q in step]})
    json.dump(a, open(os.path.join(RIV, "roads_hw.json"), "w"), separators=(",", ":"))
    print("lanes", done[0], "roads", len(a["roads"]))


if __name__ == "__main__":
    main()
