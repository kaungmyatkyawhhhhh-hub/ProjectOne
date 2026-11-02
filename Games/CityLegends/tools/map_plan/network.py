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
BEND_IN = 32.0     # studs: the carriageway's half width (the inside edge of a bend)
BEND_MAX = 0.30    # the steepest a bend's inside edge may climb


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


def sample_dirs(line, closed):
    """each sample's direction in world studs (dx, dz), as written to roads.json"""
    out = []
    for i in range(len(line)):
        a = line[max(i - 1, 0)]; b = line[min(i + 1, len(line) - 1)]
        if closed and i == 0:
            a = line[-2]
        if closed and i == len(line) - 1:
            b = line[1]
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dy) or 1
        out.append((dx / L, -dy / L))
    return out


HALF = 32.0  # studs: half the carriageway


def half_widths(line, closed, others=None):
    """each sample's left and right half widths (studs). Where the road comes back past itself
    (the two legs of a hairpin running side by side, closer than a carriageway apart), or runs
    alongside another road that close without meeting it, each stops at the line halfway between
    them, so they never overlap at different heights; the builder puts a wall on that line.
    others: (positions, directions, road ids) of every other road's samples (world studs)."""
    import numpy as np
    dirs = np.array(sample_dirs(line, closed))
    pos = np.array([world(*p) for p in line])
    n = len(line)
    w = np.full((n, 2), HALF)
    idx = np.arange(n)
    for i in range(n):
        v = pos - pos[i]
        dist = np.hypot(v[:, 0], v[:, 1])
        d = dirs[i]
        right = np.array([-d[1], d[0]])
        along = v @ d
        perp = v @ right
        opp = dirs @ d
        m = (np.abs(idx - i) >= 6) & (dist < 2 * HALF + 2) & (opp < -0.5) & (np.abs(along) < np.abs(perp))
        if closed:
            m &= np.minimum(np.abs(idx - i), n - 1 - np.abs(idx - i)) >= 6
        cand = [perp[m]]
        if others is not None:
            opos, odir, oid = others
            ov = opos - pos[i]
            odist = np.hypot(ov[:, 0], ov[:, 1])
            near = odist < 2 * HALF + 2
            if near.any():
                oalong = ov[near] @ d
                operp = ov[near] @ right
                ok = (np.abs(odir[near] @ d) > 0.5) & (np.abs(oalong) < np.abs(operp))
                # not where the two meet (a junction mouth: centre lines within REACH)
                for rid in set(oid[near][ok].tolist()):
                    if odist[oid == rid].min() < 46:
                        ok &= oid[near] != rid
                cand.append(operp[ok])
        allp = np.concatenate(cand)
        for col, sgn in ((0, -1), (1, 1)):
            sel = allp * sgn > 0
            if sel.any():
                w[i, col] = min(HALF, float(np.abs(allp[sel]).min()) / 2 - 0.25)
    return [tuple(x) for x in w]


def pivots(line, closed, widths=None):
    """samples whose left or right carriageway edge waits at an earlier point in the builder
    (Roads.luau: the edge would not move forward), plus the sample it waits at"""
    dirs = sample_dirs(line, closed)
    pos = [world(*p) for p in line]
    widths = widths or half_widths(line, closed)
    out = set()
    for side in (-1, 1):
        last = None
        for i, (p, d) in enumerate(zip(pos, dirs)):
            hw = widths[i][0 if side < 0 else 1]
            e = (p[0] + side * -d[1] * hw, p[1] + side * d[0] * hw)
            if i > 0:
                mx, mz = p[0] - pos[i - 1][0], p[1] - pos[i - 1][1]
                if (e[0] - last[0]) * mx + (e[1] - last[1]) * mz <= 0.05 * math.hypot(mx, mz):
                    out.add(i); out.add(i - 1)
                    continue
            last = e
    return out


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
            if opts.get("closed"):
                line.append(line[0])  # a loop ends where it starts (same point, same height)
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
    # per-segment grade caps: a bend's inside edge climbs R / (R - BEND_IN) times as steeply as the
    # centre line, so in tight bends the centre's grade is capped to keep the inside edge under
    # BEND_MAX; hairpins tighter than the half width (the inside edge stands still) run level
    # (owner, 2026-11-02: no bumps; steep inside corners and folds were felt as bumps)
    import numpy as np
    allpos = np.array([world(*p) for r in R for p in r["line"]])
    alldir = np.array([d for r in R for d in sample_dirs(r["line"], r["opts"].get("closed", False))])
    allid = np.array([ri for ri, r in enumerate(R) for _ in r["line"]])
    for ri, r in enumerate(R):
        line, s, g = r["line"], r["s"], r["g"]
        n = len(line)
        rad = [1e9] * n
        for k in range(n):
            a, b = max(k - 2, 0), min(k + 2, n - 1)
            if b - a < 2:
                continue
            t1 = (line[a + 1][0] - line[a][0], line[a + 1][1] - line[a][1])
            t2 = (line[b][0] - line[b - 1][0], line[b][1] - line[b - 1][1])
            ang = abs(math.atan2(t1[0] * t2[1] - t1[1] * t2[0], t1[0] * t2[0] + t1[1] * t2[1]))
            if ang > 1e-6:
                rad[k] = (s[b] - s[a]) / ang
        gk = [g] * n
        for i in range(1, n):
            rr = min(rad[i - 1], rad[i])
            gk[i] = min(g, max(0.0, BEND_MAX * (rr - BEND_IN) / rr))
        # where the builder (tools/riviera/Roads.luau) makes a bend's inside edge wait at one point
        # (it would run backwards), every sample sharing that point must have one height: level
        keep = allid != ri
        r["widths"] = half_widths(line, r["opts"].get("closed", False), (allpos[keep], alldir[keep], allid[keep]))
        for i in pivots(line, r["opts"].get("closed", False), r["widths"]):
            gk[i] = 0.0
            if i + 1 < n:
                gk[i + 1] = 0.0
        r["gk"] = gk
        r["rad"] = rad
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
            h, s, gk, t = r["h"], r["s"], r["gk"], r["target"]
            n = len(h)
            for i in range(n):  # pull gently back toward the ground
                h[i] += (t[i] - h[i]) * 0.05
            for i in range(1, n):
                dd = s[i] - s[i - 1]
                h[i] = min(max(h[i], h[i - 1] - gk[i] * dd), h[i - 1] + gk[i] * dd)
            for i in range(n - 2, -1, -1):
                dd = s[i + 1] - s[i]
                h[i] = min(max(h[i], h[i + 1] - gk[i + 1] * dd), h[i + 1] + gk[i + 1] * dd)
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
            h, s, gk, fx = r["h"], r["s"], r["gk"], fixed[ri]
            for i in range(1, len(h)):
                if i not in fx:
                    dd = s[i] - s[i - 1]
                    h[i] = min(max(h[i], h[i - 1] - gk[i] * dd), h[i - 1] + gk[i] * dd)
            for i in range(len(h) - 2, -1, -1):
                if i not in fx:
                    dd = s[i + 1] - s[i]
                    h[i] = min(max(h[i], h[i + 1] - gk[i + 1] * dd), h[i + 1] + gk[i + 1] * dd)
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

    def clamp(h, s, gk, fx, passes, cap=None):
        n = len(h)
        for _ in range(passes):
            if cap:
                for i in range(n):
                    if h[i] > cap[i] and i not in fx:
                        h[i] = cap[i]
            for i in range(1, n):
                if i not in fx:
                    dd = s[i] - s[i - 1]
                    h[i] = min(max(h[i], h[i - 1] - gk[i] * dd), h[i - 1] + gk[i] * dd)
            for i in range(n - 2, -1, -1):
                if i not in fx:
                    dd = s[i + 1] - s[i]
                    h[i] = min(max(h[i], h[i + 1] - gk[i + 1] * dd), h[i + 1] + gk[i + 1] * dd)

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
                    # and at least as long as the smaller road's carriageway reaches along this one
                    # near the junction (its edges, where it bends away), so every bit of the smaller
                    # road lying on this one lies on its level part (2026-11-02)
                    La, Lb, sa = R[ra]["line"], R[rb]["line"], R[ra]["s"]
                    foot = 0.0
                    for kk in range(max(0, kb - 15), min(len(Lb), kb + 16)):
                        p = Lb[kk]
                        if math.hypot(p[0] - La[ka][0], p[1] - La[ka][1]) > 70 / SPM:
                            continue
                        t = tangent(Lb, kk)
                        nx, ny = -t[1], t[0]
                        for e in ((p[0] + nx * HALF / SPM, p[1] + ny * HALF / SPM), p, (p[0] - nx * HALF / SPM, p[1] - ny * HALF / SPM)):
                            lo, hi = max(0, ka - 40), min(len(La), ka + 41)
                            j = min(range(lo, hi), key=lambda q: (La[q][0] - e[0]) ** 2 + (La[q][1] - e[1]) ** 2)
                            if math.hypot(La[j][0] - e[0], La[j][1] - e[1]) < (HALF + 2) / SPM:
                                foot = max(foot, abs(sa[j] - sa[ka]))
                    half = min(140.0, max(half, foot + 8))
                    zones[ra][ka] = max(zones[ra].get(ka, 0), half)
    FLAT = 40   # studs, at least
    REACH = 46 / SPM  # metres: smaller-road samples this close copy the bigger road's height
    HALF_W = 34       # studs: and these (on its carriageway) are held there
    for ri in order:
        r = R[ri]
        # only what this pass decides is held: its flat junction spots and where it meets bigger roads
        fixed[ri] = set()
        r["fx"] = fixed[ri]
        h, s, gk, fx = r["h"], r["s"], r["gk"], fixed[ri]
        n = len(h)
        # how far the grade caps let the height change from the start to each sample
        A = [0.0]
        for i in range(1, n):
            A.append(A[-1] + gk[i] * (s[i] - s[i - 1]))
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
        # first: where this road runs onto a bigger road it must take that road's height (hard)
        copies = []
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
                copies.append((k, y, best[1] < (HALF_W / SPM)))
        hard = [(k, y) for k, y, held in copies if held]
        # then this road's own flat junction zones. A zone's height must be reachable at this road's
        # grade from every hard point and every earlier zone (otherwise the solve leaves a cliff at
        # the zone's end, as at Mountain Road's east end, 2026-11-02)
        def zone_try(kc, half):
            lo_i, hi_i = kc, kc
            while lo_i > 0 and s[kc] - s[lo_i - 1] <= half:
                lo_i -= 1
            while hi_i < n - 1 and s[hi_i + 1] - s[kc] <= half:
                hi_i += 1
            # never over a point held at a bigger road's height (that one wins)
            for j, _ in hard:
                if lo_i <= j < kc:
                    lo_i = j + 1
                elif kc < j <= hi_i:
                    hi_i = j - 1
            lo_y, hi_y = -1e9, 1e9
            for j, y in hard + [(j, h[j]) for j in fx]:
                if lo_i <= j <= hi_i:
                    continue
                room = (A[lo_i] - A[j] if j < lo_i else A[j] - A[hi_i]) * 0.95
                lo_y = max(lo_y, y - room)
                hi_y = min(hi_y, y + room)
            joined = [j for j in range(lo_i, hi_i + 1) if j in fx]
            return lo_i, hi_i, lo_y, hi_y, joined
        for kc in sorted(zones[ri]):
            if kc in fx or near_bigger(kc):
                continue  # already flat, or the junction sits on a bigger road (that one is flat there)
            # the longest level stretch (from the zone's length down) that the grades can still reach
            # from everything held; if none can, the shortest one at the best height
            half = zones[ri][kc]
            tries = [half] + [x for x in (96, 72, 56, 40, 28) if x < half]
            for k, hl in enumerate(tries):
                lo_i, hi_i, lo_y, hi_y, joined = zone_try(kc, hl)
                hc = h[joined[0]] if joined else min(max(h[kc], lo_y), hi_y)
                if lo_y <= hc <= hi_y or k == len(tries) - 1:
                    break
            if lo_i > hi_i:
                continue
            if not (lo_y <= hc <= hi_y) and not joined:
                hc = (lo_y + hi_y) / 2
            for i in range(lo_i, hi_i + 1):
                h[i] = hc; fx.add(i)
        # the bigger road's height where this point meets it square-on (between its samples); on the
        # bigger road's carriageway: held; on its pavement: free
        for k, y, held in copies:
            h[k] = y
            if held:
                fx.add(k)
        if r["opts"].get("closed"):
            # a loop's two ends are the same point: one height, held
            y = h[0] if 0 in fx else h[n - 1] if (n - 1) in fx else (h[0] + h[n - 1]) / 2
            h[0] = h[n - 1] = y
            fx.add(0); fx.add(n - 1)
        clamp(h, s, gk, fx, 40, r["cap"])
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
            clamp(h, s, gk, fx, 8, r["cap"])
    roads = []
    for r in R:
        line, h, s, raw = r["line"], r["h"], r["s"], r["raw"]
        tunnel = r["opts"].get("tunnel")
        samples = []
        closed = r["opts"].get("closed")
        for i, p in enumerate(line):
            a = line[max(i - 1, 0)]; b = line[min(i + 1, len(line) - 1)]
            if closed and i == 0:
                a = line[-2]
            if closed and i == len(line) - 1:
                b = line[1]
            dx, dy = b[0] - a[0], b[1] - a[1]
            L = math.hypot(dx, dy) or 1
            X, Z = world(*p)
            samples.append({"x": X, "z": Z, "y": h[i], "ground": raw[i], "dx": dx / L, "dz": -dy / L,
                            "wl": r["widths"][i][0], "wr": r["widths"][i][1],
                            "tunnel": bool(tunnel and tunnel[0] <= p[0] <= tunnel[1])})
        grades = [abs(h[i] - h[i - 1]) / max(s[i] - s[i - 1], 1e-6) for i in range(1, len(h))]
        over = [i for i in range(1, len(h)) if abs(h[i] - h[i - 1]) > r["gk"][i] * (s[i] - s[i - 1]) + 0.05]
        roads.append({"name": r["name"], "kind": r["kind"], "closed": r["opts"].get("closed", False), "samples": samples, "rank": rank[R.index(r)],
                      "length": s[-1], "maxGrade": max(grades) if grades else 0,
                      "over": over, "fx": sorted(r.get("fx", ())), "gk": r["gk"], "maxCut": max(raw[i] - h[i] for i in range(len(h))), "maxFill": max(h[i] - raw[i] for i in range(len(h)))})
    # where one road ends exactly where another ends or starts, both get the same cross-section
    # there (the mean direction), or the joint would leave a wedge-shaped hole or overlap
    ends = []
    for r in roads:
        sm = r["samples"]
        if not r["closed"]:
            ends.append((sm[0], -1))
            ends.append((sm[-1], 1))
    for i in range(len(ends)):
        for j in range(i + 1, len(ends)):
            (pa, sa), (pb, sb) = ends[i], ends[j]
            if math.hypot(pa["x"] - pb["x"], pa["z"] - pb["z"]) < 0.5:
                # outward directions; a straight joint has them opposite
                oa = (pa["dx"] * sa, pa["dz"] * sa); ob = (pb["dx"] * sb, pb["dz"] * sb)
                vx, vz = oa[0] - ob[0], oa[1] - ob[1]
                L = math.hypot(vx, vz) or 1
                vx, vz = vx / L, vz / L
                pa["dx"], pa["dz"] = vx * sa, vz * sa
                pb["dx"], pb["dz"] = -vx * sb, -vz * sb
    return roads


if __name__ == "__main__":
    rs = build(sys.argv[1])
    for r in rs:
        flag = "  <-- steep" if r["maxGrade"] > 0.145 else ""
        if r["over"]:
            flag += "  OVER CAP at %d samples: %s" % (len(r["over"]), r["over"][:12])
        print("%-18s %6.0f studs  y %5.0f..%5.0f  max %4.1f%%  cut %4.0f fill %4.0f%s" % (r["name"], r["length"], min(s["y"] for s in r["samples"]), max(s["y"] for s in r["samples"]), r["maxGrade"] * 100, r["maxCut"], r["maxFill"], flag))
