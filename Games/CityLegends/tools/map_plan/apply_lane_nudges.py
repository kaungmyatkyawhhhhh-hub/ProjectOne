"""
Moves Riviera lane points off kerbs, pavements and walls (2026-11-04, smooth roads).

tools/riviera/LaneCheck.luau (Studio) walks every lane and finds the spots where a car's width (3 studs
each side of the lane) runs onto a kerb, a pavement or into a wall; the fixes were small sideways
moves of single lane points, kept in lane_nudges.json. export_lanes.py writes RivieraLanes.lua from
scratch, so run this after it:

    python tools/map_plan/export_lanes.py
    python tools/map_plan/apply_lane_nudges.py [src/shared/RivieraLanes.lua]

Each move is [lane number, point number, dx, dz] (studs; lanes and points counted from 1 in file order).
"""

import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def fmt(v: float) -> str:
    t = "%.1f" % v
    if t.endswith(".0"):
        t = t[:-2]
    return "0" if t == "-0" else t


def apply(path: str, moves: list) -> int:
    with open(path, encoding="utf-8", newline="") as f:
        lines = f.read().split("\n")
    by: dict = {}
    for m in moves:
        by.setdefault(m[0], []).append(m)
    lane, done = 0, 0
    for n, line in enumerate(lines):
        mm = re.search(r"pts = \{ ([^}]*) \}", line)
        if not mm:
            continue
        lane += 1
        if lane not in by:
            continue
        nums = [x.strip() for x in mm.group(1).split(",")]
        trail = bool(nums) and nums[-1] == ""
        if trail:
            nums = nums[:-1]
        vals = [float(x) for x in nums]
        for _, pt, dx, dz in by[lane]:
            i = (pt - 1) * 3
            vals[i] = round(vals[i] + dx, 1)
            vals[i + 2] = round(vals[i + 2] + dz, 1)
            done += 1
        new = ",".join(fmt(v) for v in vals) + ("," if trail else "")
        lines[n] = line[: mm.start(1)] + new + line[mm.end(1) :]
    with open(path, "w", encoding="utf-8", newline="") as f:
        f.write("\n".join(lines))
    return done


if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "src", "shared", "RivieraLanes.lua")
    with open(os.path.join(HERE, "lane_nudges.json"), encoding="utf-8") as f:
        moves = json.load(f)["moves"]
    print("moved", apply(target, moves), "lane points")
