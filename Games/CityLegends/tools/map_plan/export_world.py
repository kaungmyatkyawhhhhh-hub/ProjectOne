"""
Monaco's gameplay places (owner 2026-11-02: "bring the main stuffs from city legends to Monaco city and
remove the city legends map"), worked out from build/riviera/roads.json and far.json:

  * house lots on the hillside lanes kept free of buildings (Terraces and Hairpins): Low lots on the
    lower lanes, Mid on the middle ones, High on the top ones; each faces its lane, behind the
    pavement, clear of every road and of each other, on land
  * time-trial races: a checkpoint every ~180 studs along a run of road
  * delivery dispatch points and drop points, and the Legends chips: on pavements, away from junctions

Output: src/shared/RivieraWorld.lua (read by IsleLayout.lots and ActivityData when the Riviera is in
the place).
"""
import json
import math
import os

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "..")
HALF, WALK = 32, 10

TIERS = {
    # name: (tier, zone, width, depth, cap)
    0: ("low", 60, 72, 22),
    1: ("mid", 104, 100, 13),
    2: ("high", 120, 130, 12),
}
ROAD_TIER = {
    "Terrace W1": 0, "Terrace E1": 0, "Hairpin W1": 0, "Hairpin E1": 0,
    "Terrace E2": 1, "Hairpin E2": 1, "Hairpin W3": 1,
    "Terrace W2": 2, "Hairpin E3": 2, "Mountain Road": 2,
}


def main():
    d = json.load(open(os.path.join(ROOT, "build", "riviera", "roads.json")))
    roads = d["roads"]
    allpts = np.array([(s[0], s[2]) for r in roads for s in r["s"]])
    far = json.load(open(os.path.join(ROOT, "build", "riviera", "far.json")))
    gx, gz, step, x0, z0 = far["gx"], far["gz"], far["step"], far["x0"], far["z0"]
    V = np.array(far["verts"]).reshape(gz, gx)

    def ground(x, z):
        i, j = int(round((x - x0) / step)), int(round((z - z0) / step))
        return V[j, i] if 0 <= i < gx and 0 <= j < gz else -20

    def road_dist(x, z):
        return float(np.hypot(allpts[:, 0] - x, allpts[:, 1] - z).min())

    ends = []
    for r in roads:
        if not r.get("closed"):
            ends += [r["s"][0], r["s"][-1]]

    def near_junction(x, z, r=90):
        return any(math.hypot(e[0] - x, e[2] - z) < r for e in ends)

    # ---------------------------------------------------------------- lots
    lots = []  # dicts
    count = {0: 0, 1: 0, 2: 0}

    def overlaps(c, f, w, dpt):
        for l in lots:
            if math.hypot(l["x"] - c[0], l["z"] - c[1]) < (math.hypot(w, dpt) + math.hypot(l["w"], l["d"])) / 2 * 0.95:
                return True
        return False

    for tier in (2, 1, 0):
        zone, w, dpt, cap = TIERS[tier]
        for r in roads:
            if ROAD_TIER.get(r["name"]) != tier:
                continue
            s = r["s"]
            for side in (1, -1):
                last = -1e9
                acc = 0.0
                for i in range(1, len(s)):
                    acc += math.hypot(s[i][0] - s[i - 1][0], s[i][2] - s[i - 1][2])
                    if count[tier] >= cap:
                        break
                    if acc - last < w + 14:
                        continue
                    p = s[i]
                    if p[5] == 1:
                        continue
                    dx, dz = p[3], p[4]
                    n = math.hypot(dx, dz) or 1
                    dx, dz = dx / n, dz / n
                    rx, rz = -dz * side, dx * side  # out from the road on this side
                    off = HALF + WALK + 6 + dpt / 2
                    cx, cz = p[0] + rx * off, p[2] + rz * off
                    # the lot's outline: clear of every road (behind the pavement), on land
                    ok = True
                    for a in np.linspace(-w / 2, w / 2, 7):
                        for b in np.linspace(-dpt / 2, dpt / 2, 7):
                            # (a along the road, b out from it)
                            qx = cx + dx * a + rx * b
                            qz = cz + dz * a + rz * b
                            if road_dist(qx, qz) < HALF + WALK + 3 or ground(qx, qz) < 2:
                                ok = False
                                break
                        if not ok:
                            break
                    if not ok or overlaps((cx, cz), None, w, dpt):
                        continue
                    last = acc
                    count[tier] += 1
                    lots.append({
                        "id": f"riv_{zone}_{count[tier]}", "zone": zone, "tier": tier, "number": count[tier],
                        "x": round(cx, 1), "y": round(p[1] + 0.6, 2), "z": round(cz, 1),
                        "fx": round(-rx, 3), "fz": round(-rz, 3), "w": w, "d": dpt, "road": r["name"],
                    })
    # ---------------------------------------------------------------- races
    by = {r["name"]: r for r in roads}

    def race(rid, name, rname, a=0.0, b=1.0, every=180):
        s = by[rname]["s"]
        i0, i1 = int(len(s) * a), int(len(s) * b) - 1
        cps, acc, length = [], 0.0, 0.0
        for i in range(i0 + 1, i1 + 1):
            stepd = math.hypot(s[i][0] - s[i - 1][0], s[i][2] - s[i - 1][2])
            acc += stepd
            length += stepd
            if acc >= every or i == i1:
                cps.append((round(s[i][0], 1), round(s[i][1], 2), round(s[i][2], 1)))
                acc = 0
        p = s[i0]
        dx, dz = p[3], p[4]
        right = (-dz, dx)
        start = (round(p[0] + right[0] * 8, 1), round(p[1], 2), round(p[2] + right[1] * 8, 1))
        return {"id": rid, "name": name, "start": start, "dir": (round(dx, 3), round(dz, 3)), "cps": cps, "length": round(length)}

    races = [
        race("riv_coast", "Coast Road Run", "Coast Road", 0.05, 0.95),
        race("riv_mountain", "Mountain Road", "Mountain Road", 0.05, 0.95),
        race("riv_town", "Town Road Sprint", "Town Road", 0.1, 0.9),
        race("riv_casino", "Casino Avenue", "Casino Avenue", 0.0, 1.0, 150),
    ]

    # ---------------------------------------------------------------- pavement points
    def pavement_point(rname, frac, side=1):
        s = by[rname]["s"]
        i = max(1, min(len(s) - 2, int(len(s) * frac)))
        # move along to a sample away from junctions
        for k in range(0, len(s)):
            for j in (i + k, i - k):
                if 1 <= j < len(s) - 1 and not near_junction(s[j][0], s[j][2]):
                    p = s[j]
                    dx, dz = p[3], p[4]
                    rx, rz = -dz * side, dx * side
                    return (round(p[0] + rx * (HALF + WALK / 2), 1), round(p[1] + 0.5, 2), round(p[2] + rz * (HALF + WALK / 2), 1))
        return None

    dispatch = [
        {"name": "Harbour Dispatch", "pos": pavement_point("Harbour Street", 0.4)},
        {"name": "Casino Dispatch", "pos": pavement_point("Casino Avenue", 0.6)},
    ]
    drop_names = ["Marina Lofts", "Old Rock Steps", "Bay Apartments", "Rock Climb Deli", "Upper Street Florist", "Ravine Studios",
                  "Beach Club", "Larvotto Flats", "Town Road Bakery", "Hilltop Villa", "Casino Valet", "Port Office"]
    drop_spots = [("Coast Road", 0.3), ("Old Rock", 0.5), ("Riviera Bay", 0.3), ("Rock Climb", 0.5), ("Upper Street", 0.6), ("Ravine Street", 0.5),
                  ("Beach Avenue", 0.5), ("Coast Road", 0.8), ("Town Road", 0.4), ("Terrace W1", 0.5), ("Casino Avenue", 0.3), ("Harbour Street", 0.7)]
    drops = [{"name": n, "pos": pavement_point(r, f, -1)} for n, (r, f) in zip(drop_names, drop_spots)]
    chips = []
    rng = np.random.default_rng(7)
    street_names = [r["name"] for r in roads if r["kind"] == "street" or r["name"] in ("Town Road", "Coast Road")]
    tries = 0
    while len(chips) < 25 and tries < 500:
        tries += 1
        rn = street_names[int(rng.integers(len(street_names)))]
        p = pavement_point(rn, float(rng.uniform(0.1, 0.9)), 1 if rng.random() < 0.5 else -1)
        if p and all(math.hypot(p[0] - c[0], p[2] - c[2]) > 150 for c in chips):
            chips.append((p[0], round(p[1] + 2.6, 2), p[2]))
    realty = pavement_point("Harbour Street", 0.55, -1)

    def v3(t):
        return "Vector3.new(%s, %s, %s)" % t

    out = ["-- generated by tools/map_plan/export_world.py: do not edit", "return {", "\tlots = {"]
    for l in lots:
        out.append('\t\t{ id = "%s", zone = "%s", tier = %d, number = %d, x = %s, y = %s, z = %s, fx = %s, fz = %s, w = %d, d = %d },'
                   % (l["id"], l["zone"], l["tier"], l["number"], l["x"], l["y"], l["z"], l["fx"], l["fz"], l["w"], l["d"]))
    out.append("\t},")
    out.append("\traces = {")
    for r in races:
        out.append('\t\t{ id = "%s", name = "%s", start = %s, dir = Vector3.new(%s, 0, %s), length = %d, checkpoints = { %s } },'
                   % (r["id"], r["name"], v3(r["start"]), r["dir"][0], r["dir"][1], r["length"], ", ".join(v3(c) for c in r["cps"])))
    out.append("\t},")
    out.append("\tdispatch = {")
    for dpt in dispatch:
        out.append('\t\t{ name = "%s", pos = %s },' % (dpt["name"], v3(dpt["pos"])))
    out.append("\t},")
    out.append("\tdropPoints = {")
    for dpt in drops:
        out.append('\t\t{ name = "%s", pos = %s },' % (dpt["name"], v3(dpt["pos"])))
    out.append("\t},")
    out.append("\tchips = { %s }," % ", ".join(v3(c) for c in chips))
    out.append("\trealty = %s," % v3(realty))
    out.append("}")
    path = os.path.join(ROOT, "src", "shared", "RivieraWorld.lua")
    open(path, "w", encoding="utf-8").write("\n".join(out) + "\n")
    print(f"lots {count} ({len(lots)}), races {[len(r['cps']) for r in races]}, drops {len(drops)}, chips {len(chips)} -> {os.path.getsize(path)} bytes")
    for l in lots:
        print(l["id"], l["road"], l["x"], l["y"], l["z"])


if __name__ == "__main__":
    main()
