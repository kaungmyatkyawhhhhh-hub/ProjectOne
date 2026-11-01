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
    for kind, group in (("route", ns["ROUTES"]), ("street", ns["STREETS"])):
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
            R.append({"name": name, "kind": kind, "opts": opts, "line": line, "s": s, "raw": raw, "target": sm, "h": sm[:],
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
    # spread any small step left at a junction over the next few samples
    for ri, r in enumerate(R):
        h, fx = r["h"], fixed[ri]
        nearj = [i for i in range(1, len(h) - 1) if i not in fx and any(abs(i - f) <= 10 for f in fx)]
        for _ in range(12):
            for i in nearj:
                h[i] = (h[i - 1] + h[i] + h[i + 1]) / 3
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
        roads.append({"name": r["name"], "kind": r["kind"], "closed": r["opts"].get("closed", False), "samples": samples,
                      "length": s[-1], "maxGrade": max(grades) if grades else 0,
                      "maxCut": max(raw[i] - h[i] for i in range(len(h))), "maxFill": max(h[i] - raw[i] for i in range(len(h)))})
    return roads


if __name__ == "__main__":
    rs = build(sys.argv[1])
    for r in rs:
        flag = "  <-- steep" if r["maxGrade"] > 0.145 else ""
        print("%-18s %6.0f studs  y %5.0f..%5.0f  max %4.1f%%  cut %4.0f fill %4.0f%s" % (r["name"], r["length"], min(s["y"] for s in r["samples"]), max(s["y"] for s in r["samples"]), r["maxGrade"] * 100, r["maxCut"], r["maxFill"], flag))
