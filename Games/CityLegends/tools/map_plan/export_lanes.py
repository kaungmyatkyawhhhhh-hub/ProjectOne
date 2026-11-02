"""
Riviera traffic lanes (owner 2026-11-02: "traffic on the new map (reduce traffic)").

From build/riviera/roads.json: every road gets 2 lanes each way (lane centres 8 and 24 studs right of
the centre line, as painted by tools/riviera/Roads.luau: 2 + 2 lanes of 16), points every ~24 studs,
squeezed in where the road is narrowed (hairpin legs). Junctions are found where a road's end
meets another road; there cars can turn both ways onto the other road and come off it into this one.
Dead ends get a U-turn. Closed loops wrap round.

Output: src/shared/RivieraLanes.lua (a Luau data module, read by src/shared/RivieraTraffic.lua)
  lanes = { { road, way, lane, kind, closed, pts = { x, y, z, x, y, z, ... } }, ... }
  links = { { fromLane, fromIndex, toLane, toIndex }, ... }  (1-based point indices)
"""
import json
import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "..")
STEP = 24.0
JOIN = 44.0  # a road end this close to another road is a junction
CLEAR = 18.0  # turns join the other road at least this far from the junction point


def resample(s, closed):
    out = [s[0]]
    acc = 0.0
    for k in range(1, len(s)):
        a, b = s[k - 1], s[k]
        acc += math.hypot(b[0] - a[0], b[2] - a[2])
        if acc >= STEP or k == len(s) - 1:
            out.append(b)
            acc = 0.0
    return out


def main():
    data = json.load(open(os.path.join(ROOT, "build", "riviera", "roads.json")))
    roads = data["roads"]
    lanes = []
    index = {}  # (road, way, lane) -> lane number (1-based)
    centre = []  # per road: resampled centre points
    for ri, r in enumerate(roads):
        s = resample(r["s"], r.get("closed"))
        centre.append(s)
        for way in (1, -1):
            seq = s if way == 1 else list(reversed(s))
            for lane, off in ((1, 8.0), (2, 24.0)):
                pts = []
                for p in seq:
                    dx, dz = p[3] * way, p[4] * way
                    n = math.hypot(dx, dz) or 1.0
                    dx, dz = dx / n, dz / n
                    # right of travel (Roblox: look x up): (-dz, 0, dx); traffic keeps right
                    rx, rz = -dz, dx
                    half = (p[7] if way == 1 else p[6]) if len(p) > 7 else 32.0
                    o = min(off, max(4.0, half - 8.0)) if lane == 2 else min(off, max(3.0, half / 2.0))
                    pts += [round(p[0] + rx * o, 1), round(p[1] + 0.15, 1), round(p[2] + rz * o, 1)]
                lanes.append({"road": r["name"], "way": way, "lane": lane, "kind": r["kind"], "closed": bool(r.get("closed")), "pts": pts})
                index[(ri, way, lane)] = len(lanes)

    def lane_pt(ln, k):
        p = lanes[ln - 1]["pts"]
        return (p[3 * (k - 1)], p[3 * (k - 1) + 1], p[3 * (k - 1) + 2])

    def npts(ln):
        return len(lanes[ln - 1]["pts"]) // 3

    def nearest_on(ln, pos, after=True, min_d=CLEAR):
        """the point index on lane ln nearest pos, moved along the lane to be min_d away"""
        best, bk = 1e18, 1
        for k in range(1, npts(ln) + 1):
            q = lane_pt(ln, k)
            d = math.hypot(q[0] - pos[0], q[2] - pos[2])
            if d < best:
                best, bk = d, k
        k = bk
        if after:
            while k < npts(ln) and math.hypot(lane_pt(ln, k)[0] - pos[0], lane_pt(ln, k)[2] - pos[2]) < min_d:
                k += 1
        else:
            while k > 1 and math.hypot(lane_pt(ln, k)[0] - pos[0], lane_pt(ln, k)[2] - pos[2]) < min_d:
                k -= 1
        return k

    links = set()
    for ri, r in enumerate(roads):
        if r.get("closed"):
            for way in (1, -1):
                for lane in (1, 2):
                    ln = index[(ri, way, lane)]
                    links.add((ln, npts(ln), ln, 1))
            continue
        s = centre[ri]
        for end in (0, -1):
            e = s[end]
            # the nearest other road
            best, bj, bk = 1e18, None, None
            for rj, cs in enumerate(centre):
                if rj == ri:
                    continue
                for k, q in enumerate(roads[rj]["s"]):
                    d = math.hypot(q[0] - e[0], q[2] - e[2])
                    if d < best:
                        best, bj, bk = d, rj, k
            # the way that drives INTO this end, and the way that drives OUT of it
            way_in = 1 if end == -1 else -1
            way_out = -way_in
            if best > JOIN:
                # dead end: turn round
                for lane in (1, 2):
                    a = index[(ri, way_in, lane)]
                    b = index[(ri, way_out, lane)]
                    links.add((a, npts(a), b, 1))
                continue
            jp = roads[bj]["s"][bk]
            jpos = (jp[0], jp[1], jp[2])
            for lane in (1, 2):
                into = index[(ri, way_in, lane)]
                outof = index[(ri, way_out, lane)]
                for way in (1, -1):
                    other = index[(bj, way, lane)]
                    # off this road onto the other one, either way
                    k_to = nearest_on(other, jpos, after=True)
                    if k_to < npts(other):
                        links.add((into, npts(into), other, k_to))
                    # off the other road into this one
                    k_from = nearest_on(other, jpos, after=False)
                    if k_from > 1:
                        links.add((other, k_from, outof, 1))

    out = ["-- generated by tools/map_plan/export_lanes.py from build/riviera/roads.json: do not edit", "return {", "\tlanes = {"]
    for l in lanes:
        out.append('\t\t{ road = "%s", way = %d, lane = %d, kind = "%s", closed = %s, pts = { %s } },' % (
            l["road"], l["way"], l["lane"], l["kind"], "true" if l["closed"] else "false", ",".join(("%g" % v) for v in l["pts"])))
    out.append("\t},")
    out.append("\tlinks = {")
    for a in sorted(links):
        out.append("\t\t{ %d, %d, %d, %d }," % a)
    out.append("\t},")
    out.append("}")
    path = os.path.join(ROOT, "src", "shared", "RivieraLanes.lua")
    open(path, "w", encoding="utf-8").write("\n".join(out) + "\n")
    print(f"{len(lanes)} lanes, {sum(npts(i + 1) for i in range(len(lanes)))} points, {len(links)} links -> {path} ({os.path.getsize(path)} bytes)")


if __name__ == "__main__":
    main()
