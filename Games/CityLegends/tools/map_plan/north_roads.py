"""
The north roads (2026-11-04, owner's map with red strokes: "I want to add roads. The big road on top
will be a highway. and near the circle road there will be more curves roads and also connect roads
that has no where, because I see some roads which lead to no where").

Written as roads.json entries (same sample format) to build/riviera/north.json:
  Corniche Highway (route, 2 + 2): from the top of the Highway Loop east along the mountains, back
      west, and east again down to the Mountain Road's east end (the thick red stroke)
  Serpent Road (pass, 1 + 1): from the highway's first bend up a stack of hairpins, over the top and
      down a second stack to the Summit Pass (the thin red stroke)
  the links (streets, 1 + 1, pavements): the short red strokes and the one dead end not marked

usage (from Games/CityLegends):
  python tools/map_plan/north_roads.py            builds and writes north.json, prints the report
  python tools/map_plan/north_roads.py --fit      searches the shapes first (prints what to paste)
"""
import json
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import highway as hw  # noqa: E402
import highway_terrain as ht  # noqa: E402

RIV = hw.RIV
CACHE = os.path.join(RIV, "ground_after_highway.npz")

HW_STEP = 10.0  # studs between samples: the bends are wide, and fewer pieces (20,000 studs of road)
HW_GRADE = 0.095
HW_MIN_R = 110.0
HALF = 32.0
PASS_STEP = 6.0
PASS_HALF = 16.0
PASS_GRADE = 0.10
STREET_STEP = 6.0
STREET_GRADE = 0.14


def to_world(px):
    """the owner's marked map, 3x enlarged: pixel -> world (fitted to the roads on it)"""
    return (9636 + px[0] * 5.6, -2964 + px[1] * 5.6)


# the thick stroke, traced (world studs, x / z). The top keeps ~180 studs from the terrain's north edge.
HW_STROKE = [(10150, -2715), (10588, -2745), (10880, -2700), (11050, -2480), (11085, -2236), (10990, -2020),
             (10945, -1850), (11045, -1735), (11225, -1765), (11470, -2010), (11792, -2300), (12268, -2510),
             (12772, -2640), (13332, -2700), (13780, -2640), (14396, -2561), (15124, -2544), (15684, -2415),
             (16356, -2432), (16916, -2488), (17336, -2505), (17476, -2264), (17280, -2124), (16860, -1967),
             (15964, -1967), (15236, -2068), (14452, -2236), (13668, -2337), (12996, -2432), (12548, -2208),
             (12230, -1990), (12060, -1790), (12240, -1640), (12996, -1648), (13724, -1704), (14396, -1799),
             (15012, -1816), (15684, -1676), (16328, -1463), (16636, -1172), (16748, -892), (16930, -660)]
# (the last point joins the Mountain Road, set in build())
# (the stroke moved across the line by --fit: at most 130 studs, for less digging and wider bends)
HW_FIT = [(10144, -2689), (10590, -2625), (10858, -2608), (11083, -2482), (11172, -2211), (10952, -2044), (10838, -1825), (11010, -1618), (11287, -1683), (11376, -2084), (11741, -2408), (12298, -2394), (12748, -2742), (13328, -2580), (13784, -2730), (14414, -2680), (15110, -2460), (15680, -2295), (16370, -2313), (16930, -2394), (17322, -2457), (17523, -2264), (17335, -2017), (16864, -1907), (15968, -1997), (15246, -2117), (14471, -2354), (13677, -2457), (12996, -2447), (12557, -2219), (12174, -2076), (12000, -1783), (12227, -1551), (12987, -1738), (13721, -1824), (14400, -1739), (15006, -1696), (15659, -1559), (16279, -1353), (16551, -1088), (16756, -898), (16888, -638), (16986, -503)]


def ground_after_highway():
    """the ground in the place now: the master grid plus the Riviera Highway's and pass's cuts"""
    if os.path.exists(CACHE):
        z = np.load(CACHE)
        meta = json.load(open(os.path.join(RIV, "meta.json")))
        return meta, z["H"], z["M"]
    meta, H, M = ht.load()
    road = json.load(open(os.path.join(RIV, "highway.json")))["roads"]
    old = json.load(open(os.path.join(RIV, "roads.json")))["roads"]
    H1, M1, _ = ht.compute(meta, H, M, road, old)
    np.savez_compressed(CACHE, H=H1, M=M1)
    return meta, H1, M1


def lipschitz(y, g):
    """y moved as little as possible so neighbours differ by at most g (the middle of the two envelopes)"""
    i = np.arange(len(y)) * g
    up = np.maximum(np.maximum.accumulate(y + i) - i, (np.maximum.accumulate((y - i)[::-1])[::-1]) + i)
    dn = np.minimum(np.minimum.accumulate(y - i) + i, (np.minimum.accumulate((y + i)[::-1])[::-1]) - i)
    return (up + dn) / 2


def fast_profile(target, step, grade, y0, y1):
    """(for the searches) heights near `target`, grade limited, pinned at both ends"""
    n = len(target)
    g = grade * step
    idx = np.arange(n)
    lo = np.maximum(y0 - g * idx, y1 - g * (n - 1 - idx))
    hi = np.minimum(y0 + g * idx, y1 + g * (n - 1 - idx))
    y = np.clip(lipschitz(np.clip(target, lo, hi), g), lo, hi)
    return y


def radii(P):
    a, b, c = P[:-2], P[1:-1], P[2:]
    ab = np.linalg.norm(b - a, axis=1)
    bc = np.linalg.norm(c - b, axis=1)
    ca = np.linalg.norm(a - c, axis=1)
    cr = np.abs((b[:, 0] - a[:, 0]) * (c[:, 1] - a[:, 1]) - (b[:, 1] - a[:, 1]) * (c[:, 0] - a[:, 0]))
    return np.where(cr > 1e-9, ab * bc * ca / (2 * np.maximum(cr, 1e-9)), 1e9)


def smooth_line(P, passes=4, r=4):
    """a light average: rounds what the control points left a bit tight; the ends stay"""
    n = len(P)
    k = np.ones(2 * r + 1) / (2 * r + 1)
    for _ in range(passes):
        Q = P.copy()
        for c in (0, 1):
            Q[r:n - r, c] = np.convolve(P[:, c], k, mode="valid")
        P = Q
    return P


def hw_line(ctrl):
    line = hw.catmull(ctrl, False, per=24)
    P, _ = hw.resample(line, False, HW_STEP)
    P = smooth_line(P, 6, 5)
    return P


def mountain_end(mr):
    """the highway's T on the Mountain Road: near its east end, the road's north side"""
    k = min(range(len(mr)), key=lambda i: (mr[i][0] - 16990) ** 2 + (mr[i][2] - -510) ** 2)
    return (mr[k][0], mr[k][2])


def fit_highway(meta, H1, ctrl0, loop_y, end_y):
    """moves the control points across the line (at most 130 studs from the owner's stroke) for the road
    that digs and fills least and keeps its bends wide"""
    ctrl = [np.array(p, dtype=float) for p in ctrl0]
    home = [p.copy() for p in ctrl]

    def score(c):
        P = hw_line([tuple(q) for q in c])
        g = hw.smooth(hw.sample_h(meta, H1, P[:, 0], P[:, 1]), 6, False)
        y = fast_profile(g, HW_STEP, HW_GRADE, loop_y, end_y)
        cut = np.maximum(g - y, 0)
        fill = np.maximum(y - g, 0)
        s = float(np.mean(cut ** 2) + 0.35 * np.mean(fill ** 2))
        r = radii(P)
        s += float(np.sum(np.maximum(HW_MIN_R + 30 - r, 0) ** 2)) * 0.4
        s += float(np.sum(np.maximum(-2735 - P[:, 1], 0) ** 2)) * 0.5  # the terrain's north edge
        s += sum(float(np.sum((a - b) ** 2)) for a, b in zip(c, home)) * 0.003
        return s

    best = score(ctrl)
    print("start score %.0f" % best)
    n = len(ctrl)
    for rnd, step in enumerate((90, 60, 35)):
        for i in range(1, n - 1):
            d = ctrl[min(i + 1, n - 1)] - ctrl[max(i - 1, 0)]
            d = d / max(np.linalg.norm(d), 1e-6)
            nrm = np.array((-d[1], d[0]))
            base = ctrl[i].copy()
            for s_ in (-step, step, -step / 2, step / 2):
                q = base + nrm * s_
                if np.linalg.norm(q - home[i]) > 130:
                    continue
                c = list(ctrl)
                c[i] = q
                v = score(c)
                if v < best:
                    best = v
                    ctrl[i] = q
        print("round %d score %.0f" % (rnd, best))
    return [(round(float(p[0])), round(float(p[1]))) for p in ctrl]


# ---- the Serpent Road: same plan as the Summit Pass: an approach, a stack of hairpins, the top, a
# second stack, a run into the T
SERPENT = {
    "n_x": 11030.0, "n_z": -1510.0, "n_ang": -8.0, "n_len": 550.0, "n_gap": 82.0, "n_legs": 5,
    "t1": -280.0, "t2": -320.0,
    "s_x": 12330.0, "s_z": -1050.0, "s_ang": 200.0, "s_len": 320.0, "s_gap": 100.0, "s_legs": 7,
}
SERPENT_START = (11045, -1735)  # (the highway's bend; set to its nearest sample in build())
SERPENT_END = (11760, -470)     # on the Summit Pass's first leg (set to its nearest sample in build())


def serpent_line(start, end, P=None):
    P = dict(SERPENT, **(P or {}))
    ang = math.radians(P["n_ang"])
    n_d = np.array((math.cos(ang), math.sin(ang)))
    n_start = np.array((P["n_x"], P["n_z"]))
    ns_pts, _, n_end_d = hw.stack(tuple(n_start), tuple(n_d), int(P["n_legs"]), P["n_len"], +1, P["n_gap"])
    a = hw.catmull([tuple(start), tuple(np.array(start) + (n_start - np.array(start)) * 0.5 + np.array((-30, 0))), tuple(n_start - n_d * 30), tuple(n_start), tuple(n_start + n_d * 40)], False, per=16)
    j = int(np.argmin(np.linalg.norm(a - n_start, axis=1)))
    a = a[:j]
    sang = math.radians(P["s_ang"])
    s_d = np.array((math.cos(sang), math.sin(sang)))
    s_start = np.array((P["s_x"], P["s_z"]))
    ss_pts, _, d_end = hw.stack(tuple(s_start), tuple(s_d), int(P["s_legs"]), P["s_len"], -1, P["s_gap"])
    last = np.array(ns_pts[-1])
    out_d = np.array(n_end_d) / np.linalg.norm(n_end_d)
    a0 = last + out_d * 50
    b0 = s_start - s_d * 50
    line_d = (b0 - a0) / max(np.linalg.norm(b0 - a0), 1e-6)
    nrm = np.array((-line_d[1], line_d[0]))
    m1 = a0 + (b0 - a0) / 3 + nrm * P["t1"]
    m2 = a0 + (b0 - a0) * 2 / 3 + nrm * P["t2"]
    t = hw.catmull([tuple(last), tuple(a0), tuple(m1), tuple(m2), tuple(b0), tuple(s_start)], False, per=16)
    e = np.array(ss_pts[-1])
    # the last leg bends round into the T
    e_d = np.array(d_end) / np.linalg.norm(d_end)
    tgt = np.array(end, dtype=float)
    tail = hw.catmull([tuple(e), tuple(e + e_d * 40), tuple(tgt + (e + e_d * 40 - tgt) * 0.35), tuple(tgt)], False, per=16)
    line = list(a) + [np.array(q) for q in ns_pts] + list(t[1:-1]) + [np.array(q) for q in ss_pts] + list(tail[1:])
    return np.array(line)


def open_bends(P, rmin, rounds=400):
    """widens only the spots tighter than rmin: those samples (and a few each side) move towards their
    neighbours' average until no bend is tighter"""
    P = P.copy()
    for _ in range(rounds):
        r = radii(P)
        bad = np.where(r < rmin)[0] + 1
        if len(bad) == 0:
            break
        mask = np.zeros(len(P), dtype=bool)
        for b in bad:
            mask[max(2, b - 4):min(len(P) - 2, b + 5)] = True
        Q = P.copy()
        avg = (P[:-4] + P[1:-3] * 2 + P[3:-1] * 2 + P[4:]) / 6
        Q[2:-2][mask[2:-2]] = avg[mask[2:-2]]
        P = Q
    return P


def serpent_samples(start, end, P=None):
    ps, _ = hw.resample(serpent_line(start, end, P), False, PASS_STEP)
    for _ in range(3):
        q = ps.copy()
        q[3:-3] = (ps[1:-5] + ps[2:-4] + ps[3:-3] + ps[4:-2] + ps[5:-1]) / 5
        ps = q
    # (evenly spaced again: bends bunch the samples up, and the grade limit counts samples)
    ps, _ = hw.resample(open_bends(ps, 34.0), False, PASS_STEP)
    return ps


def fit_serpent(meta, H1, start, end, y0, y1, others):
    params = dict(SERPENT)

    def score(p):
        try:
            ps = serpent_samples(start, end, p)
        except Exception:
            return 1e18
        g = hw.smooth(hw.sample_h(meta, H1, ps[:, 0], ps[:, 1]), 5, False)
        y = fast_profile(g, PASS_STEP, PASS_GRADE, y0, y1)
        cut = np.maximum(g - y, 0)
        fill = np.maximum(y - g, 0)
        s = float(np.mean(cut ** 2) + 0.5 * np.mean(fill ** 2))
        n = len(ps)
        body = ps[12: n - 14]
        dm = np.min(np.linalg.norm(body[:, None, :] - others[None, ::2, :], axis=2), axis=1)
        s += float(np.sum(np.maximum(95 - dm, 0) ** 2)) * 4
        # the road's own legs apart
        sub = ps[::4]
        d = np.linalg.norm(sub[:, None, :] - sub[None, :, :], axis=2)
        far = np.abs(np.arange(len(sub))[:, None] - np.arange(len(sub))[None, :]) > 22
        s += float(np.sum(np.maximum(70 - d[far], 0) ** 2)) * 0.5
        # the end off the T: the last ~40 studs nearly straight at the road
        return s + abs(n * PASS_STEP - 5200) * 0.01

    steps = {"n_x": 50, "n_z": 50, "n_ang": 8, "n_len": 50, "n_gap": 8, "t1": 40, "t2": 40, "s_x": 50, "s_z": 50, "s_ang": 8, "s_len": 40, "s_gap": 8}
    best = score(params)
    print("serpent start score %.0f" % best)
    for rnd in range(5):
        for k, st in steps.items():
            base = params[k]
            for mul in (-2, -1, 1, 2):
                q = dict(params)
                q[k] = base + st * mul
                if k.endswith("_gap") and not 76 <= q[k] <= 120:
                    continue
                if k.endswith("_len") and not 220 <= q[k] <= 560:
                    continue
                v = score(q)
                if v < best:
                    best = v
                    params = q
        for k, opts in (("n_legs", (3, 4, 5, 6)), ("s_legs", (3, 4, 5, 6, 7))):
            for o in opts:
                q = dict(params)
                q[k] = o
                v = score(q)
                if v < best:
                    best = v
                    params = q
        print("round %d score %.0f" % (rnd, best), params)
    return params


# ---- the links: control points, then a T at both ends (a junction's point or a road's nearest sample)
LINKS = [
    # the short red strokes
    # (round the house lot beside it)
    {"name": "Hairpin W2", "pts": [(12960, -480), (12942, -405), (12972, -315), (13040, -235), (13095, -180), (13104, -128)]},
    {"name": "Terrace Cross E", "pts": [("Mountain Road", 15236, -696), (15245, -600), (15262, -490), (15280, -368)]},
    # (from Hairpin E3 a little up the hill: at the corner itself it would run side by side with E3, and
    # a house lot stands right below the corner)
    {"name": "Hairpin E4", "pts": [("Hairpin E3", 16700, -482), (16745, -410), (16810, -320), (16845, -220), (16835, -120), (16805, -50), (16800, -16)]},
    # (a wide curve south of the switchback's tip: straight at it, the 20-stud drop came in 100 studs)
    {"name": "Terrace E1 Link", "pts": [(16800, -16), (16865, 18), (16935, 48), (17000, 42), ("East Switchbacks", 17045, 12)]},
    {"name": "Harbour Link", "pts": [(14240, 392), (14212, 445), (14125, 522), (14050, 592), ("Coast Road", 14002, 645)]},
    # the dead end nobody marked: the west end of Terrace W1, on along the hill to the West Switchbacks
    {"name": "Terrace W1 Link", "pts": [(11680, 99), (11600, 100), (11510, 108), ("West Switchbacks", 11395, 122)]},
]


def road_y(all_roads, name, x, z):
    r = [q for q in all_roads if q["name"] == name][0]["s"]
    k = min(range(len(r)), key=lambda i: (r[i][0] - x) ** 2 + (r[i][2] - z) ** 2)
    return r[k]


def junction_y(all_roads, x, z):
    """the height of the road point at (x, z): every road sample within a stud"""
    best = None
    for r in all_roads:
        for s in r["s"]:
            d = math.hypot(s[0] - x, s[2] - z)
            if best is None or d < best[0]:
                best = (d, s[1])
    return best[1]


def big_surface(all_roads, x, z, radius=38.0):
    """the height Roads.alignJunctions gives a street's sample near a bigger road: that road's nearest
    segment, or None when no road is within radius"""
    best = None
    for r in all_roads:
        s = r["s"]
        for i in range(0, len(s) - 1):
            a, b = s[i], s[i + 1]
            if abs(a[0] - x) > radius + 12 or abs(a[2] - z) > radius + 12:
                continue
            dx, dz = b[0] - a[0], b[2] - a[2]
            L = dx * dx + dz * dz
            t = max(0.0, min(1.0, ((x - a[0]) * dx + (z - a[2]) * dz) / L)) if L > 0 else 0.0
            d = math.hypot(a[0] + dx * t - x, a[2] + dz * t - z)
            if d < radius and (best is None or d < best[0]):
                best = (d, a[1] + (b[1] - a[1]) * t)
    return None if best is None else best[1]


def link_road(spec, all_roads, meta, H1):
    ctrl = []
    for p in spec["pts"]:
        if isinstance(p[0], str):
            s = road_y(all_roads, p[0], p[1], p[2])
            ctrl.append((s[0], s[2]))
        else:
            ctrl.append(p)
    line = hw.catmull(ctrl, False, per=16)
    P, total = hw.resample(line, False, STREET_STEP)
    y0 = junction_y(all_roads, P[0, 0], P[0, 1])
    y1 = junction_y(all_roads, P[-1, 0], P[-1, 1])
    n = len(P)
    # inside the reach of the roads it joins it lies on their surface (the road builder would put it
    # there anyway, and fade the difference far along the link); an even climb between the two mouths
    pins = {0: y0, n - 1: y1}
    for i in range(n):
        y = big_surface(all_roads, float(P[i, 0]), float(P[i, 1]))
        if y is not None:
            pins[i] = y
    first = max(k for k in pins if k < n / 2)
    last = min(k for k in pins if k > n / 2)
    keep = hw.HIGHWAY_GRADE
    run = (last - first) * STREET_STEP
    hw.HIGHWAY_GRADE = max(STREET_GRADE, abs(pins[last] - pins[first]) / max(run, 1) * 1.1)
    ease = np.ones(n)
    for i in range(n):
        ease[i] = min(1.0, 0.3 + min(abs(i - p) for p in pins) * STREET_STEP / 40.0)
    t = np.clip((np.arange(n) - first) / max(last - first, 1), 0, 1)
    Y = hw.profile(pins[first] + (pins[last] - pins[first]) * t, STREET_STEP, False, pins, ease)
    hw.HIGHWAY_GRADE = keep
    return P, Y, total


def write_entry(name, kind, P, Y, half, rank, highway, closed=False, extra=None):
    D = hw.directions(P, closed)
    s = [[round(float(P[i, 0]), 2), round(float(Y[i]), 2), round(float(P[i, 1]), 2), round(float(D[i, 0]), 4), round(float(D[i, 1]), 4), 0, half, half] for i in range(len(P))]
    e = {"name": name, "kind": kind, "closed": closed, "rank": rank, "highway": highway, "s": s}
    if extra:
        e.update(extra)
    return e


def report(name, P, Y, g):
    gr = np.abs(np.diff(Y)) / np.maximum(np.linalg.norm(np.diff(P, axis=0), axis=1), 1e-6)
    c = g - Y
    print("%s: %d samples, %.0f studs, heights %.0f-%.0f, max grade %.1f%%, min radius %.0f, deepest cut %.0f, highest fill %.0f" % (
        name, len(P), float(np.sum(np.linalg.norm(np.diff(P, axis=0), axis=1))), Y.min(), Y.max(), float(gr.max()) * 100, hw.min_radius(P, False), c.max(), -c.min()))


def viaducts(Y, g, step, limit=60.0, min_run=160.0):
    """runs of samples where the road stands more than `limit` above the ground: bridges, not banks"""
    high = (Y - g) > limit
    runs = []
    i, n = 0, len(Y)
    while i < n:
        if high[i]:
            j = i
            while j + 1 < n and high[j + 1]:
                j += 1
            runs.append([i, j])
            i = j + 1
        else:
            i += 1
    # join close runs, widen to where the road is ~20 over the ground, drop short ones
    merged = []
    for r in runs:
        if merged and (r[0] - merged[-1][1]) * step < 160:
            merged[-1][1] = r[1]
        else:
            merged.append(r)
    out = []
    for a, b in merged:
        while a > 0 and Y[a - 1] - g[a - 1] > 34:
            a -= 1
        while b < n - 1 and Y[b + 1] - g[b + 1] > 34:
            b += 1
        if out and a <= out[-1][1] + 1:
            out[-1][1] = max(out[-1][1], b)  # (widening made two runs one)
        elif (b - a) * step >= min_run:
            out.append([a, b])
    return out


def build(fit=False):
    meta, H1 = None, None
    meta, H1, _ = ground_after_highway()
    old = json.load(open(os.path.join(RIV, "roads.json")))["roads"]
    road_hw = json.load(open(os.path.join(RIV, "highway.json")))["roads"]
    allr = old + road_hw
    loop = [r for r in road_hw if r["name"] == "Highway Loop"][0]["s"]
    mr = [r for r in old if r["name"] == "Mountain Road"][0]["s"]
    # the highway
    ctrl = list(HW_FIT or HW_STROKE)
    k0 = min(range(len(loop)), key=lambda i: (loop[i][0] - ctrl[0][0]) ** 2 + (loop[i][2] - ctrl[0][1]) ** 2)
    ctrl[0] = (loop[k0][0], loop[k0][2])
    end = mountain_end(mr)
    ctrl = ctrl[:-1] + [ctrl[-1], end]
    y_end = road_y(allr, "Mountain Road", end[0], end[1])[1]
    if fit:
        ctrl2 = fit_highway(meta, H1, ctrl, loop[k0][1], y_end)
        print("HW_FIT =", ctrl2)
        ctrl = ctrl2
        ctrl[0] = (loop[k0][0], loop[k0][2])
        ctrl[-1] = end
    P = hw_line(ctrl)
    g = hw.smooth(hw.sample_h(meta, H1, P[:, 0], P[:, 1]), 6, False)
    keep = hw.HIGHWAY_GRADE
    hw.HIGHWAY_GRADE = HW_GRADE
    pins = {}
    lp_xz = np.array([[q[0], q[2]] for q in loop])
    lp_y = np.array([q[1] for q in loop])
    mr_xz = np.array([[q[0], q[2]] for q in mr])
    mr_y = np.array([q[1] for q in mr])

    def height_on(xz, ys, q):
        j = int(np.argmin(np.linalg.norm(xz - q, axis=1)))
        best = (1e18, float(ys[j]))
        for a_ in (j - 1, j):
            if 0 <= a_ < len(xz) - 1:
                p0, p1 = xz[a_], xz[a_ + 1]
                d = p1 - p0
                t = float(np.clip(np.dot(q - p0, d) / max(np.dot(d, d), 1e-9), 0, 1))
                dist = float(np.linalg.norm(p0 + d * t - q))
                if dist < best[0]:
                    best = (dist, float(ys[a_] + (ys[a_ + 1] - ys[a_]) * t))
        return best[1]

    for i in range(len(P)):
        if np.min(np.linalg.norm(lp_xz - P[i], axis=1)) < HALF + 8:
            pins[i] = height_on(lp_xz, lp_y, P[i])
        elif np.min(np.linalg.norm(mr_xz - P[i], axis=1)) < HALF + 8:
            pins[i] = height_on(mr_xz, mr_y, P[i])
    pinned = sorted(pins)
    ease = np.ones(len(P))
    for i in range(len(P)):
        dd = min(abs(i - p) for p in pinned) * HW_STEP
        ease[i] = min(1.0, 0.15 + dd / 90.0)
    Y = hw.profile(g, HW_STEP, False, pins, ease)
    hw.HIGHWAY_GRADE = keep
    report("Corniche Highway", P, Y, g)
    via = viaducts(Y, g, HW_STEP)
    print("viaducts:", [(a, b, round((b - a) * HW_STEP), round(float((Y - g)[a:b + 1].max()))) for a, b in via])
    entries = [write_entry("Corniche Highway", "route", P, Y, HALF, 39, True, extra={"viaducts": via})]
    # the Serpent Road
    h_nearest = int(np.argmin(np.linalg.norm(P - np.array(SERPENT_START, dtype=float), axis=1)))
    s0 = (float(P[h_nearest, 0]), float(P[h_nearest, 1]))
    pas = [r for r in road_hw if r["name"] == "Summit Pass"][0]["s"]
    k = min(range(len(pas)), key=lambda i: (pas[i][0] - SERPENT_END[0]) ** 2 + (pas[i][2] - SERPENT_END[1]) ** 2)
    s1 = (pas[k][0], pas[k][2])
    y0, y1 = float(Y[h_nearest]), pas[k][1]
    others = np.array([[q[0], q[2]] for q in entries[0]["s"]] + [[q[0], q[2]] for q in pas] + [[q[0], q[2]] for q in mr])
    params = None
    if fit:
        params = fit_serpent(meta, H1, s0, s1, y0, y1, others)
        print("SERPENT =", params)
    ps = serpent_samples(s0, s1, params)
    g2 = hw.smooth(hw.sample_h(meta, H1, ps[:, 0], ps[:, 1]), 5, False)
    hw.HIGHWAY_GRADE = PASS_GRADE
    hxz = P
    pins = {}
    for i in range(len(ps)):
        if np.linalg.norm(ps[i] - np.array(s0)) < HALF + 10:
            pins[i] = height_on(hxz, Y, ps[i])
        elif np.linalg.norm(ps[i] - np.array(s1)) < PASS_HALF + 10:
            pins[i] = height_on(np.array([[q[0], q[2]] for q in pas]), np.array([q[1] for q in pas]), ps[i])
    pinned = sorted(pins)
    ease = np.ones(len(ps))
    for i in range(len(ps)):
        dd = min(abs(i - p) for p in pinned) * PASS_STEP
        ease[i] = min(1.0, 0.15 + dd / 60.0)
    Y2 = hw.profile(g2, PASS_STEP, False, pins, ease)
    hw.HIGHWAY_GRADE = keep
    report("Serpent Road", ps, Y2, g2)
    print("serpent viaducts:", viaducts(Y2, g2, PASS_STEP))
    entries.append(write_entry("Serpent Road", "pass", ps, Y2, PASS_HALF, 40, True))
    # the links
    for n, spec in enumerate(LINKS):
        Pl, Yl, total = link_road(spec, allr + entries, meta, H1)
        g3 = hw.sample_h(meta, H1, Pl[:, 0], Pl[:, 1])
        report(spec["name"], Pl, Yl, g3)
        entries.append(write_entry(spec["name"], "street", Pl, Yl, HALF, 41 + n, False, extra={"aligned": True}))
    return entries


if __name__ == "__main__":
    entries = build("--fit" in sys.argv)
    json.dump({"roads": entries}, open(os.path.join(RIV, "north.json"), "w"), separators=(",", ":"))
    print("written", [e["name"] for e in entries])
