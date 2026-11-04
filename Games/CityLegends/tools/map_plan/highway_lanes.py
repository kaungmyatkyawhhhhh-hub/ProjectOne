"""
Adds the Riviera Highway's traffic lanes to src/shared/RivieraLanes.lua (2026-11-04), keeping every
existing lane and link as it is (the file has hand fixes a full export_lanes.py run would lose).

The two roads of build/riviera/highway.json get 2 lanes each way like the others (export_lanes.py's
rule: lane centres 8 and 24 studs right of the centre line, a point every ~24 studs), marked
`highway = true` (RivieraTraffic / Traffic keep at most Config.Traffic.HighwayMax cars on them).
Links: the loop wraps round; the link's end meets the loop (a T: turns both ways onto it, and off it
into the link); the link's start meets the West Switchbacks (turns both ways onto it, off it into
the link). Running it again replaces the highway lanes it added before.

usage (from Games/CityLegends): python tools/map_plan/highway_lanes.py
"""
import json
import math
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import export_lanes  # noqa: E402  (resample, STEP, CLEAR)

ROOT = os.path.join(HERE, "..", "..")
LANES = os.path.join(ROOT, "src", "shared", "RivieraLanes.lua")
HW = os.path.join(ROOT, "build", "riviera", "highway.json")
CLEAR = export_lanes.CLEAR


def parse(src):
    lanes = []
    for m in re.finditer(r'\t\t\{ road = "([^"]*)", way = (-?\d+), lane = (\d+), kind = "(\w+)", closed = (\w+)(, highway = true)?, pts = \{ ([^}]*) \} \},', src):
        nums = [float(x) for x in m.group(7).split(",") if x.strip()]
        lanes.append({"road": m.group(1), "way": int(m.group(2)), "lane": int(m.group(3)), "kind": m.group(4),
                      "closed": m.group(5) == "true", "highway": bool(m.group(6)), "pts": nums, "line": m.group(0)})
    links = [tuple(int(x) for x in m.groups()) for m in re.finditer(r"\t\t\{ (\d+), (\d+), (\d+), (\d+) \},", src.split("links = {")[1])]
    return lanes, links


def lane_points(road):
    s = export_lanes.resample(road["s"], road.get("closed"))
    out = []
    for way in (1, -1):
        seq = s if way == 1 else list(reversed(s))
        for lane, off in ((1, 8.0), (2, 24.0)):
            pts = []
            for p in seq:
                dx, dz = p[3] * way, p[4] * way
                n = math.hypot(dx, dz) or 1.0
                dx, dz = dx / n, dz / n
                rx, rz = -dz, dx
                half = (p[7] if way == 1 else p[6]) if len(p) > 7 else 32.0
                o = min(off, max(4.0, half - 8.0)) if lane == 2 else min(off, max(3.0, half / 2.0))
                pts += [round(p[0] + rx * o, 1), round(p[1] + 0.15, 1), round(p[2] + rz * o, 1)]
            out.append({"road": road["name"], "way": way, "lane": lane, "kind": road["kind"], "closed": bool(road.get("closed")), "highway": True, "pts": pts})
    return out


def main():
    src = open(LANES, encoding="utf-8", newline="").read()
    nl = "\r\n" if "\r\n" in src else "\n"
    src = src.replace("\r\n", "\n")
    lanes, links = parse(src)
    # drop a previous run's highway lanes (they come last) and their links
    keep = [l for l in lanes if not l["highway"]]
    n_old = len(keep)
    links = [k for k in links if k[0] <= n_old and k[2] <= n_old]
    hw = json.load(open(HW))["roads"]
    new = []
    index = {}
    for r in hw:
        for l in lane_points(r):
            new.append(l)
            index[(r["name"], l["way"], l["lane"])] = n_old + len(new)
    all_lanes = keep + new

    def npts(ln):
        return len(all_lanes[ln - 1]["pts"]) // 3

    def pt(ln, k):
        p = all_lanes[ln - 1]["pts"]
        return p[3 * (k - 1)], p[3 * (k - 1) + 1], p[3 * (k - 1) + 2]

    def nearest_on(ln, pos, after=True, min_d=CLEAR):
        best, bk = 1e18, 1
        for k in range(1, npts(ln) + 1):
            q = pt(ln, k)
            d = math.hypot(q[0] - pos[0], q[2] - pos[2])
            if d < best:
                best, bk = d, k
        k = bk
        if after:
            while k < npts(ln) and math.hypot(pt(ln, k)[0] - pos[0], pt(ln, k)[2] - pos[2]) < min_d:
                k += 1
        else:
            while k > 1 and math.hypot(pt(ln, k)[0] - pos[0], pt(ln, k)[2] - pos[2]) < min_d:
                k -= 1
        return k

    added = set()
    loop = [r for r in hw if r["name"] == "Highway Loop"][0]
    link = [r for r in hw if r["name"] == "Riviera Highway"][0]
    pas = [r for r in hw if r["name"] == "Summit Pass"]
    # the loop wraps round
    for way in (1, -1):
        for lane in (1, 2):
            ln = index[(loop["name"], way, lane)]
            added.add((ln, npts(ln), ln, 1))

    def junction(end_way_in, other_lanes, jpos, road=None):
        """the end of `road` (the link by default) that `end_way_in` drives into meets roads whose
        lanes are other_lanes [(lane number, lane 1 or 2)]: turn onto them both ways, and come off
        them into this road"""
        road = road or link
        way_out = -end_way_in
        for lane in (1, 2):
            into = index[(road["name"], end_way_in, lane)]
            outof = index[(road["name"], way_out, lane)]
            for other, olane in other_lanes:
                if olane != lane and any(o[1] == lane for o in other_lanes):
                    continue  # (lane 1 to lane 1, lane 2 to lane 2 where the other road has both)
                k_to = nearest_on(other, jpos, after=True)
                if k_to < npts(other):
                    added.add((into, npts(into), other, k_to))
                k_from = nearest_on(other, jpos, after=False)
                if k_from > 1:
                    added.add((other, k_from, outof, 1))

    # the T on the loop (the link's last sample is on the loop's centre line)
    e = link["s"][-1]
    junction(1, [(index[(loop["name"], w, l)], l) for w in (1, -1) for l in (1, 2)], (e[0], e[1], e[2]))
    # the start on the West Switchbacks (one lane each way in traffic: its lane 1s; links into its
    # lane 2s are moved onto lane 1 by RivieraTraffic anyway)
    s0 = link["s"][0]
    ws = [(i + 1, l["lane"]) for i, l in enumerate(keep) if l["road"] == "West Switchbacks"]
    junction(-1, ws, (s0[0], s0[1], s0[2]))
    # the Summit Pass: a T on the link at its start, a T on the Mountain Road at its end
    for pr in pas:
        p0, p1 = pr["s"][0], pr["s"][-1]
        junction(-1, [(index[(link["name"], w, l)], l) for w in (1, -1) for l in (1, 2)], (p0[0], p0[1], p0[2]), pr)
        mr = [(i + 1, l["lane"]) for i, l in enumerate(keep) if l["road"] == "Mountain Road"]
        junction(1, mr, (p1[0], p1[1], p1[2]), pr)
    # Studio refuses a script over 200,000 characters, so the highway's lanes and links go in their own
    # module (src/shared/RivieraLanesHighway.lua; RivieraTraffic adds them to RivieraLanes' lists:
    # lane numbers carry on from the base file's, links use the joined numbering)
    base_links = sorted(set(links))
    out = [src.split("	lanes = {")[0] + "	lanes = {"]
    for l in keep:
        out.append(l["line"])
    out.append("	},")
    out.append("	links = {")
    for a in base_links:
        out.append("		{ %d, %d, %d, %d }," % a)
    out.append("	},")
    out.append("}")
    text = "\n".join(out) + "\n"
    text = text.replace("then tools/map_plan/apply_lane_nudges.py, plus the highway (tools/map_plan/highway_lanes.py): do not edit", "then tools/map_plan/apply_lane_nudges.py: do not edit")
    open(LANES, "w", encoding="utf-8", newline="").write(text.replace("\n", nl))
    hw_out = ["-- generated by tools/map_plan/highway_lanes.py from build/riviera/highway.json: do not edit",
              "-- the Riviera Highway's and the Summit Pass's lanes (numbered on from RivieraLanes' %d) and their links" % n_old,
              "return {", "	first = %d," % (n_old + 1), "	lanes = {"]
    for l in new:
        hw_out.append('		{ road = "%s", way = %d, lane = %d, kind = "%s", closed = %s, highway = true, pts = { %s } },' % (
            l["road"], l["way"], l["lane"], l["kind"], "true" if l["closed"] else "false", ",".join(("%g" % v) for v in l["pts"])))
    hw_out.append("	},")
    hw_out.append("	links = {")
    for a in sorted(added):
        hw_out.append("		{ %d, %d, %d, %d }," % a)
    hw_out.append("	},")
    hw_out.append("}")
    open(os.path.join(ROOT, "src", "shared", "RivieraLanesHighway.lua"), "w", encoding="utf-8", newline="").write("\r\n".join(hw_out) + "\r\n")
    links = base_links + sorted(added)
    all_lanes = keep + new
    print("%d lanes (%d highway), %d links (%d highway)" % (len(all_lanes), len(new), len(links), len(added)))


if __name__ == "__main__":
    main()
