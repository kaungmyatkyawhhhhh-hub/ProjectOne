"""The Riviera road network in game units, from layout.py.

Every road becomes a list of samples {x, z, y, dir} in world studs (x along the coast, z inland
negative: world Z = OZ - plan_y * SPM), with heights solved together so roads meet at the same
height: the 3 routes first, then each street with its ends (and any crossing) held at the height
of the road it meets, grades capped (routes 8%, streets 10% or their own cap).

    import network; roads = network.build(map_plan_dir)
"""
import os, sys, math, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from geo import Elev
from routes import catmull

SPM = 1.6          # studs per metre across
VS = 0.75          # studs per metre up (hills a bit gentler than real, so streets stay drivable)
OX, OZ = 14000, 0  # where the plan's (0, 0) sits in the place (east of the old city)
STEP = 4.0         # metres between samples


class Dem:
    """the dense 25 m grid (data/dem25.json), falling back to the coarse one at sea"""
    def __init__(self, d):
        j = json.load(open(os.path.join(d, "data", "dem25.json")))
        self.x0, self.y0, self.s, self.nx, self.ny, self.h = j["x0"], j["y0"], j["step"], j["nx"], j["ny"], j["h"]
        self.coarse = Elev(os.path.join(d, "data", "elev.json"))

    def raw(self, i, j):
        i = min(max(i, 0), self.nx - 1); j = min(max(j, 0), self.ny - 1)
        return self.h[j][i]

    def at(self, x, y):
        fi = (x - self.x0) / self.s; fj = (y - self.y0) / self.s
        i, j = int(math.floor(fi)), int(math.floor(fj)); a, b = fi - i, fj - j
        vals = [self.raw(i, j), self.raw(i + 1, j), self.raw(i, j + 1), self.raw(i + 1, j + 1)]
        if any(v is None for v in vals):
            vals = [v if v is not None else 0.0 for v in vals]
        return vals[0] * (1 - a) * (1 - b) + vals[1] * a * (1 - b) + vals[2] * (1 - a) * b + vals[3] * a * b


def world(x, y):
    return OX + x * SPM, OZ - y * SPM


def solve(line, ground, maxg, fixed):
    """heights (studs) along line: ground smoothed over ~150 studs, fixed points held, grade capped"""
    n = len(line)
    s = [0.0]
    for i in range(1, n):
        s.append(s[-1] + math.hypot(line[i][0] - line[i - 1][0], line[i][1] - line[i - 1][1]) * SPM)
    raw = [max(ground(*p), 1.5) * VS for p in line]
    sm = []
    lo = hi = 0
    acc = 0.0
    # sliding window mean over +-75 studs
    pref = [0.0]
    for v in raw:
        pref.append(pref[-1] + v)
    for i in range(n):
        while s[i] - s[lo] > 75:
            lo += 1
        while hi < n - 1 and s[hi + 1] - s[i] <= 75:
            hi += 1
        sm.append((pref[hi + 1] - pref[lo]) / (hi - lo + 1))
    h = sm[:]
    for i, v in fixed.items():
        h[i] = v
    fx = set(fixed)
    for _ in range(60):
        for i in range(1, n):
            if i in fx:
                continue
            d = s[i] - s[i - 1]
            h[i] = min(max(h[i], h[i - 1] - maxg * d), h[i - 1] + maxg * d)
        for i in range(n - 2, -1, -1):
            if i in fx:
                continue
            d = s[i + 1] - s[i]
            h[i] = min(max(h[i], h[i + 1] - maxg * d), h[i + 1] + maxg * d)
    return s, raw, h


def build(d, iters=300):
    """all roads' heights solved together: junction points (samples within 6 m of another road)
    share one height; each pass caps every road's grade, then evens out each junction"""
    ns = {"el": Elev(os.path.join(d, "data", "elev.json"))}
    exec(open(os.path.join(d, "layout.py"), encoding="utf-8").read(), ns)
    dem = Dem(d)
    R = []
    from square import square
    sq_streets, depends = square(ns["ROUTES"], ns["STREETS"], True)
    for kind, group in (("route", ns["ROUTES"]), ("street", sq_streets)):
        for name, pts, col, opts in group:
            line = catmull(pts, STEP, opts.get("closed", False))
            s = [0.0]
            for i in range(1, len(line)):
                s.append(s[-1] + math.hypot(line[i][0] - line[i - 1][0], line[i][1] - line[i - 1][1]) * SPM)
            raw = [max(dem.at(*p), 1.5) * VS for p in line]
            pref = [0.0]
            for v in raw:
                pref.append(pref[-1] + v)
            sm, lo, hi = [], 0, 0
            for i in range(len(line)):
                while s[i] - s[lo] > 75:
                    lo += 1
                while hi < len(line) - 1 and s[hi + 1] - s[i] <= 75:
                    hi += 1
                sm.append((pref[hi + 1] - pref[lo]) / (hi - lo + 1))
            hi_cap = [1e9] * len(line)
            for x0, x1, ymax in opts.get("low", []):
                for i, p in enumerate(line):
                    if x0 <= p[0] <= x1:
                        hi_cap[i] = ymax
                        sm[i] = min(sm[i], ymax)
            R.append({"name": name, "kind": kind, "opts": opts, "line": line, "s": s, "raw": raw, "target": sm, "h": sm[:], "cap": hi_cap,
                      "g": opts.get("grade", 0.08 if kind == "route" else 0.10),
                      # junction weight: the loop (routes and the switchbacks) wins, then the rest
                      "w": 50 if kind == "route" else (20 if "Switchbacks" in name else 1)})
    # junction groups: a cell hash of every sample
    cells = {}
    for ri, r in enumerate(R):
        for k, p in enumerate(r["line"]):
            cells.setdefault((int(p[0] // 6), int(p[1] // 6)), []).append((ri, k))
    groups = []
    seen = set()
    for ri, r in enumerate(R):
        for k in range(0, len(r["line"])):
            p = r["line"][k]
            cx, cy = int(p[0] // 6), int(p[1] // 6)
            members = {}
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    for (rj, kj) in cells.get((cx + dx, cy + dy), []):
                        if rj == ri:
                            continue
                        q = R[rj]["line"][kj]
                        dd = (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2
                        if dd < 36 and (rj not in members or dd < members[rj][0]):
                            members[rj] = (dd, kj)
            if members:
                key = tuple(sorted([(ri, k)] + [(rj, v[1]) for rj, v in members.items()]))
                if not (set(key) & seen):
                    groups.append(key)
                    seen |= set(key)
    for _ in range(iters):
        for r in R:
            h, s, g, t = r["h"], r["s"], r["g"], r["target"]
            n = len(h)
            for i in range(n):  # pull gently back toward the ground
                h[i] += (t[i] - h[i]) * 0.05
            for i in range(1, n):
                dd = s[i] - s[i - 1]
                h[i] = min(max(h[i], h[i - 1] - g * dd), h[i - 1] + g * dd)
            for i in range(n - 2, -1, -1):
                dd = s[i + 1] - s[i]
                h[i] = min(max(h[i], h[i + 1] - g * dd), h[i + 1] + g * dd)
            cap = r["cap"]
            for i in range(n):
                if h[i] > cap[i]:
                    h[i] = cap[i]
        for grp in groups:
            # the main routes win at their junctions (weight 50)
            wsum = sum(R[ri]["w"] for ri, k in grp)
            avg = sum(R[ri]["h"][k] * R[ri]["w"] for ri, k in grp) / wsum
            for ri, k in grp:
                R[ri]["h"][k] = avg
    # last: junctions held where they are, every road's grade capped up to them
    fixed = [set() for _ in R]
    for grp in groups:
        for ri, k in grp:
            fixed[ri].add(k)
    for _ in range(40):
        for ri, r in enumerate(R):
            h, s, g, fx = r["h"], r["s"], r["g"], fixed[ri]
            for i in range(1, len(h)):
                if i not in fx:
                    dd = s[i] - s[i - 1]
                    h[i] = min(max(h[i], h[i - 1] - g * dd), h[i - 1] + g * dd)
            for i in range(len(h) - 2, -1, -1):
                if i not in fx:
                    dd = s[i + 1] - s[i]
                    h[i] = min(max(h[i], h[i + 1] - g * dd), h[i + 1] + g * dd)
    # where a road joins a bigger one it runs level across that road: every sample of the smaller
    # road on the bigger road's carriageway takes the bigger road's (final) height there, the bigger
    # road being flat side to side, so the two surfaces meet with no step or bump. Roads are
    # finished one by one, biggest first, so a road only ever copies heights that won't change.
    # the switchbacks run straight through their junctions (the routes end on them), then the
    # routes, then the streets in layout order
    order = sorted(range(len(R)), key=lambda i: (0 if R[i]["w"] == 20 else 1 if R[i]["w"] == 50 else 2, i))
    # a street that ends on another street comes after it (it gives way there)
    names = {r["name"]: i for i, r in enumerate(R)}
    streets = [i for i in order if R[i]["w"] == 1]
    placed, done = [i for i in order if R[i]["w"] != 1], set(i for i in order if R[i]["w"] != 1)
    while streets:
        for i in streets:
            if all(names[d] in done or names[d] == i for d in depends.get(R[i]["name"], ())):
                break
        else:
            i = streets[0]  # a loop of dependencies: take the first
        streets.remove(i); placed.append(i); done.add(i)
    order = placed
    rank = {ri: n for n, ri in enumerate(order)}
    grid = {}
    for ri, r in enumerate(R):
        for k, p in enumerate(r["line"]):
            grid.setdefault((int(p[0] // 30), int(p[1] // 30)), []).append((ri, k))

    def clamp(h, s, g, fx, passes, cap=None):
        n = len(h)
        for _ in range(passes):
            if cap:
                for i in range(n):
                    if h[i] > cap[i] and i not in fx:
                        h[i] = cap[i]
            for i in range(1, n):
                if i not in fx:
                    dd = s[i] - s[i - 1]
                    h[i] = min(max(h[i], h[i - 1] - g * dd), h[i - 1] + g * dd)
            for i in range(n - 2, -1, -1):
                if i not in fx:
                    dd = s[i + 1] - s[i]
                    h[i] = min(max(h[i], h[i + 1] - g * dd), h[i + 1] + g * dd)

    # every junction is flat: where a smaller road meets this one, this road is held level for FLAT
    # studs either side of the meeting point, so both surfaces are one flat plane at the junction
    # (no step at the corners). Junctions should be near right angles (layout.py) for this to hold.
    FLAT = 40   # studs, at least
    def tangent(line, k):
        a = line[max(k - 2, 0)]; b = line[min(k + 2, len(line) - 1)]
        L = math.hypot(b[0] - a[0], b[1] - a[1]) or 1
        return ((b[0] - a[0]) / L, (b[1] - a[1]) / L)
    zones = {ri: {} for ri in range(len(R))}   # centre sample -> half length (studs)
    for grp in groups:
        for (ra, ka) in grp:
            for (rb, kb) in grp:
                if rank[ra] < rank[rb]:
                    # long enough that the smaller road's whole width crosses flat road even when
                    # it meets at an angle
                    ta, tb = tangent(R[ra]["line"], ka), tangent(R[rb]["line"], kb)
                    sn = max(abs(ta[0] * tb[1] - ta[1] * tb[0]), 0.5)
                    cs = math.sqrt(max(0.0, 1 - sn * sn))
                    half = min(96.0, max(FLAT, 34 * cs / sn + 34 / sn))
                    zones[ra][ka] = max(zones[ra].get(ka, 0), half)
    FLAT = 40   # studs, at least
    REACH = 46 / SPM  # metres: smaller-road samples this close copy the bigger road's height
    HALF_W = 34       # studs: and these (on its carriageway) are held there
    for ri in order:
        r = R[ri]
        # only what this pass decides is held: its flat junction spots and where it meets bigger roads
        fixed[ri] = set()
        h, s, g, fx = r["h"], r["s"], r["g"], fixed[ri]
        n = len(h)
        def near_bigger(k):
            p = r["line"][k]
            cx, cy = int(p[0] // 30), int(p[1] // 30)
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    for rj, kj in grid.get((cx + dx, cy + dy), []):
                        if rank[rj] < rank[ri]:
                            q = R[rj]["line"][kj]
                            if math.hypot(p[0] - q[0], p[1] - q[1]) < REACH:
                                return True
            return False
        for kc in sorted(zones[ri]):
            if kc in fx or near_bigger(kc):
                continue  # already flat, or the junction sits on a bigger road (that one is flat there)
            hc, half = h[kc], zones[ri][kc]
            i = kc
            while i >= 0 and s[kc] - s[i] <= half:
                h[i] = hc; fx.add(i); i -= 1
            i = kc + 1
            while i < n and s[i] - s[kc] <= half:
                h[i] = hc; fx.add(i); i += 1
        for k, p in enumerate(r["line"]):
            best = None
            cx, cy = int(p[0] // 30), int(p[1] // 30)
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    for rj, kj in grid.get((cx + dx, cy + dy), []):
                        if rank[rj] >= rank[ri]:
                            continue
                        q = R[rj]["line"][kj]
                        dd = math.hypot(p[0] - q[0], p[1] - q[1])
                        if dd < REACH and (best is None or (rank[rj], dd) < (best[0], best[1])):
                            best = (rank[rj], dd, rj, kj)
            if best:
                # the bigger road's height where this point meets it square-on (between its samples)
                rj, kj = best[2], best[3]
                L, H = R[rj]["line"], R[rj]["h"]
                y = H[kj]
                for a2, b2 in ((kj - 1, kj), (kj, kj + 1)):
                    if 0 <= a2 and b2 < len(L):
                        ax, ay = L[a2]; bx, by = L[b2]
                        vx, vy = bx - ax, by - ay
                        t = ((p[0] - ax) * vx + (p[1] - ay) * vy) / max(vx * vx + vy * vy, 1e-9)
                        if 0 <= t <= 1:
                            y = H[a2] + (H[b2] - H[a2]) * t
                            break
                h[k] = y
                if best[1] < (HALF_W / SPM):
                    fx.add(k)  # on the bigger road's carriageway: held; on its pavement: free
        clamp(h, s, g, fx, 40, r["cap"])
        # spread any small step left at a junction over the next few samples
        nearj = [i for i in range(1, n - 1) if i not in fx and any(abs(i - f) <= 10 for f in fx)]
        for _ in range(12):
            for i in nearj:
                h[i] = (h[i - 1] + h[i] + h[i + 1]) / 3
        # round every crest and dip (held samples kept), so the grade never changes sharply from one
        # sample to the next: sharp changes are felt as bumps
        for _ in range(6):
            src = h[:]
            for i in range(1, n - 1):
                if i in fx:
                    continue
                lo, hi = max(0, i - 4), min(n - 1, i + 4)
                h[i] = sum(src[lo:hi + 1]) / (hi - lo + 1)
            clamp(h, s, g, fx, 8, r["cap"])
    roads = []
    for r in R:
        line, h, s, raw = r["line"], r["h"], r["s"], r["raw"]
        tunnel = r["opts"].get("tunnel")
        samples = []
        for i, p in enumerate(line):
            a = line[max(i - 1, 0)]; b = line[min(i + 1, len(line) - 1)]
            dx, dy = b[0] - a[0], b[1] - a[1]
            L = math.hypot(dx, dy) or 1
            X, Z = world(*p)
            samples.append({"x": X, "z": Z, "y": h[i], "ground": raw[i], "dx": dx / L, "dz": -dy / L,
                            "tunnel": bool(tunnel and tunnel[0] <= p[0] <= tunnel[1])})
        grades = [abs(h[i] - h[i - 1]) / max(s[i] - s[i - 1], 1e-6) for i in range(1, len(h))]
        roads.append({"name": r["name"], "kind": r["kind"], "closed": r["opts"].get("closed", False), "samples": samples, "rank": rank[R.index(r)],
                      "length": s[-1], "maxGrade": max(grades) if grades else 0,
                      "maxCut": max(raw[i] - h[i] for i in range(len(h))), "maxFill": max(h[i] - raw[i] for i in range(len(h)))})
    return roads


if __name__ == "__main__":
    rs = build(sys.argv[1])
    for r in rs:
        flag = "  <-- steep" if r["maxGrade"] > 0.145 else ""
        print("%-18s %6.0f studs  y %5.0f..%5.0f  max %4.1f%%  cut %4.0f fill %4.0f%s" % (r["name"], r["length"], min(s["y"] for s in r["samples"]), max(s["y"] for s in r["samples"]), r["maxGrade"] * 100, r["maxCut"], r["maxFill"], flag))
