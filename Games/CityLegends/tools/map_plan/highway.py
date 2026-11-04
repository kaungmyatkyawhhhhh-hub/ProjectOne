"""
The Riviera Highway (2026-11-04, owner-away prompt step 6: "a mountain-highway style area ... long
roads through the mountains with realistic curves ... and also long straight stretches"): a new
2 + 2 road from the West Switchbacks' lower west hairpin (it carries straight on out of the bend)
to the west valley, then a loop round the low hill north of the peak, with a ~900-stud straight
up the valley floor.

Two roads, written as roads.json entries (same sample format as export_roads.py):
  Riviera Highway (open): the link from the West Switchbacks to the loop (a T on its south side)
  Highway Loop (closed)
Heights: the ground along the line (smoothed), then grades capped (HIGHWAY_GRADE) with gentle
vertical curves, pinned to the West Switchbacks at the start and to the loop at the T.

usage (from Games/CityLegends): python tools/map_plan/highway.py [--plot out.png]
  writes build/riviera/highway.json ({"roads": [...]}) and prints lengths, grades, cuts and fills
"""
import json
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "..")
RIV = os.path.join(ROOT, "build", "riviera")

START_Y = 95.5  # the West Switchbacks' height at the hairpin (set from roads.json in build())
STEP = 4.0  # studs between samples (the old roads: ~6.5; finer here so bends look round)
HIGHWAY_GRADE = 0.085
HALF = 32.0

# control points (world studs, x / z); the link starts at the Mountain Road's first sample
LINK = [(10790, 252), (10660, 205), (10450, 150), (10250, 60), (10080, -70), (9960, -260),
        (9880, -520), (9850, -800), (9860, -1080), (9890, -1300)]  # + the loop's T point
LOOP = [(10010, -1530), (9880, -1575), (9805, -1680), (9790, -1900), (9790, -2250), (9800, -2470),
        (9840, -2620), (9960, -2700), (10140, -2690), (10320, -2590), (10460, -2430), (10545, -2220),
        (10565, -1985), (10515, -1770), (10400, -1625), (10220, -1545)]

# The Summit Pass (owner, 2026-11-04: "make the highway roads like this" (photos of the Stelvio pass's
# stacked hairpins and a rock arch over a cliff road), "make the summit roads lead to these roads
# which will make a long loop and then arrive back at the roads of monaco", "tight curves 1+1 lane
# roads"): one lane each way (16 studs a side), from a T on the highway's valley road east up the
# peak's west face in a stack of hairpins, across the south face high up (through a rock arch),
# then down a second stack of hairpins on the south face to a T on the Mountain Road.
PASS_HALF = 16.0
PASS_GRADE = 0.10
PASS_START = (9990, -235)  # on the highway's valley road (the T; set to its nearest sample in build())
PASS_END = (11951, -251)   # on the Mountain Road (the T; set to its nearest sample in build())
HAIRPIN_GAP = 68           # between the centre lines of two legs of a stack


def stack(start, d, n_legs, length, side):
    """n_legs straight legs of `length` from `start` heading `d`, joined by hairpins; the next leg
    lies HAIRPIN_GAP to the `side` (+1: the right of the first leg's way, -1: its left)"""
    d = np.array(d, dtype=float)
    d /= np.linalg.norm(d)
    right = np.array([-d[1], d[0]])
    nrm = right * side
    pts = []
    p = np.array(start, dtype=float)
    r = HAIRPIN_GAP / 2
    for k in range(n_legs):
        e = p + d * length
        for t in np.linspace(0, 1, int(length / 4) + 1)[:-1]:
            pts.append(p + (e - p) * t)
        if k == n_legs - 1:
            pts.append(e)
            break
        c = e + nrm * r
        for th in np.linspace(0, math.pi, 24)[:-1]:
            pts.append(c - nrm * r * math.cos(th) + d * r * math.sin(th))
        p = e + nrm * HAIRPIN_GAP
        d = -d
    return pts, p if n_legs % 2 == 1 else p, d


def pass_line():
    # approach from the T on the valley road, east to the foot of the west face
    # (it comes up to the stack's first leg from the south, already turning onto it: no kink)
    w_start = np.array((10600.0, -440.0))
    w_d = np.array((-0.42, -0.91)) / np.linalg.norm((-0.42, -0.91))
    a = catmull([PASS_START, (10160, -290), (10400, -315), (10560, -360), tuple(w_start), tuple(w_start + w_d * 40)], False, per=16)
    j = int(np.argmin(np.linalg.norm(a - w_start, axis=1)))
    a = a[:j]
    # the west stack: legs NNW / SSE along the face, climbing; each next leg further up (east)
    w_dir = (-0.42, -0.91)
    ws_pts, _, _ = stack((10600, -440), w_dir, 4, 380, +1)
    # across the south face, high up (the rock arch on the way), to the top of the south stack
    last = ws_pts[-1]
    t = catmull([tuple(last), (last[0] + 30, last[1] + 70), (10930, -400), (11120, -420), (11300, -450), (11420, -468)], False, per=16)
    # the south stack: legs east / west, coming down towards the Mountain Road (each next leg lower: south)
    ss_pts, _, d_end = stack((11460, -470), (1, 0.0), 3, 340, +1)
    # to the T on the Mountain Road
    e = ss_pts[-1]
    tail = catmull([tuple(e), (e[0] + 60, e[1] + 8), (PASS_END[0] - 10, PASS_END[1] - 40), PASS_END], False, per=16)
    line = list(a) + [np.array(q) for q in ws_pts] + list(t[1:]) + [np.array(q) for q in ss_pts] + list(tail[1:])
    return np.array(line)



def catmull(pts, closed, per=24):
    """centripetal Catmull-Rom through the points, `per` sub-points a span"""
    P = [np.array(p, dtype=float) for p in pts]
    n = len(P)
    out = []
    spans = n if closed else n - 1
    for i in range(spans):
        p1, p2 = P[i], P[(i + 1) % n]
        p0 = P[(i - 1) % n] if (closed or i > 0) else p1 + (p1 - p2)
        p3 = P[(i + 2) % n] if (closed or i + 2 < n) else p2 + (p2 - p1)
        def tj(ti, a, b):
            return ti + max(np.linalg.norm(b - a), 1e-6) ** 0.5
        t0 = 0.0; t1 = tj(t0, p0, p1); t2 = tj(t1, p1, p2); t3 = tj(t2, p2, p3)
        for k in range(per):
            t = t1 + (t2 - t1) * k / per
            a1 = (t1 - t) / (t1 - t0) * p0 + (t - t0) / (t1 - t0) * p1
            a2 = (t2 - t) / (t2 - t1) * p1 + (t - t1) / (t2 - t1) * p2
            a3 = (t3 - t) / (t3 - t2) * p2 + (t - t2) / (t3 - t2) * p3
            b1 = (t2 - t) / (t2 - t0) * a1 + (t - t0) / (t2 - t0) * a2
            b2 = (t3 - t) / (t3 - t1) * a2 + (t - t1) / (t3 - t1) * a3
            out.append((t2 - t) / (t2 - t1) * b1 + (t - t1) / (t2 - t1) * b2)
    if not closed:
        out.append(P[-1])
    return np.array(out)


def resample(line, closed, step=STEP):
    pts = list(line) + ([line[0]] if closed else [])
    seg = [np.linalg.norm(pts[i + 1] - pts[i]) for i in range(len(pts) - 1)]
    total = sum(seg)
    n = max(2, int(round(total / step)))
    out = []
    acc, j = 0.0, 0
    for k in range(n if closed else n + 1):
        s = total * k / n
        while j < len(seg) - 1 and acc + seg[j] < s:
            acc += seg[j]
            j += 1
        t = (s - acc) / seg[j] if seg[j] > 0 else 0
        out.append(pts[j] + (pts[j + 1] - pts[j]) * min(max(t, 0), 1))
    return np.array(out), total


def ground():
    meta = json.load(open(os.path.join(RIV, "meta.json")))
    nx, nz = meta["nx"], meta["nz"]
    H = np.zeros((nz, nx), dtype=np.float32)
    for name in meta["tiles"]:
        t = json.load(open(os.path.join(RIV, name)))
        i, j, w, d = t["i"], t["j"], t["w"], t["d"]
        H[j:j + d, i:i + w] = np.array(t["h"], dtype=np.float32).reshape(d, w) / 4
    return meta, H


def sample_h(meta, H, x, z):
    fx = (x - meta["x0"]) / meta["cell"] - 0.5
    fz = (z - meta["z0"]) / meta["cell"] - 0.5
    i = np.clip(np.floor(fx).astype(int), 0, H.shape[1] - 2)
    j = np.clip(np.floor(fz).astype(int), 0, H.shape[0] - 2)
    a = np.clip(fx - i, 0, 1); b = np.clip(fz - j, 0, 1)
    return H[j, i] * (1 - a) * (1 - b) + H[j, i + 1] * a * (1 - b) + H[j + 1, i] * (1 - a) * b + H[j + 1, i + 1] * a * b


def smooth(v, r, closed):
    if r <= 0:
        return v.copy()
    k = np.ones(2 * r + 1) / (2 * r + 1)
    if closed:
        ext = np.concatenate([v[-r:], v, v[:r]])
        return np.convolve(ext, k, mode="valid")
    ext = np.concatenate([np.full(r, v[0]), v, np.full(r, v[-1])])
    return np.convolve(ext, k, mode="valid")


def profile(target, step, closed, pins, ease=None):
    """heights close to `target` with |grade| <= HIGHWAY_GRADE and gentle vertical curves; pinned
    values kept exactly (index -> y). `ease` (per sample, 0..1) scales the grade allowed there (gentle
    run-outs next to junctions)"""
    n = len(target)
    g0 = HIGHWAY_GRADE * step
    gv = np.full(n, g0) if ease is None else g0 * np.asarray(ease, dtype=float)
    g = g0
    idx = np.arange(n)
    lo = np.full(n, -1e9)
    hi = np.full(n, 1e9)
    for p, v in pins.items():
        dist = np.abs(idx - p)
        if closed:
            dist = np.minimum(dist, n - dist)
        lo = np.maximum(lo, v - g * dist)
        hi = np.minimum(hi, v + g * dist)
    y = np.clip(target, lo, hi)

    def limit(y):
        for _ in range(3):
            for i in range(1, n):
                if i not in pins:
                    y[i] = min(max(y[i], y[i - 1] - gv[i]), y[i - 1] + gv[i])
            for i in range(n - 2, -1, -1):
                if i not in pins:
                    y[i] = min(max(y[i], y[i + 1] - gv[i]), y[i + 1] + gv[i])
            if closed and 0 not in pins:
                y[0] = min(max(y[0], y[-1] - g), y[-1] + g)
        return y

    for _ in range(80):
        y = np.clip(smooth(y, 5, closed), lo, hi)
        for p, v in pins.items():
            y[p] = v
        y = limit(y)
    return limit(y)


def directions(P, closed):
    n = len(P)
    D = np.zeros_like(P)
    for i in range(n):
        a = P[(i - 1) % n] if (closed or i > 0) else P[i]
        b = P[(i + 1) % n] if (closed or i < n - 1) else P[i]
        d = b - a
        D[i] = d / max(np.linalg.norm(d), 1e-9)
    return D


def min_radius(P, closed):
    best = 1e9
    n = len(P)
    for i in range(1, n - 1) if not closed else range(n):
        a, b, c = P[(i - 1) % n], P[i], P[(i + 1) % n]
        ab, bc, ca = np.linalg.norm(b - a), np.linalg.norm(c - b), np.linalg.norm(a - c)
        cross = abs((b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]))
        if cross > 1e-9:
            best = min(best, ab * bc * ca / (2 * cross))
    return best


def build():
    global START_Y
    meta, H = ground()
    old = json.load(open(os.path.join(RIV, "roads.json")))["roads"]
    ws = [r for r in old if r["name"] == "West Switchbacks"][0]["s"]
    k = min(range(len(ws)), key=lambda i: (ws[i][0] - LINK[0][0]) ** 2 + (ws[i][2] - LINK[0][1]) ** 2)
    START_Y = ws[k][1]
    LINK[0] = (ws[k][0], ws[k][2])
    loop_line = catmull(LOOP, True)
    loop, loop_len = resample(loop_line, True)
    # the T: the loop sample nearest the link's last control point; the link ends on it
    d = np.linalg.norm(loop - np.array(LINK[-1], dtype=float), axis=1)
    t_i = int(np.argmin(d))
    link_line = catmull(LINK + [tuple(loop[t_i])], False)
    link, link_len = resample(link_line, False)
    d = np.linalg.norm(loop - link[-1], axis=1)
    # heights
    g_loop = smooth(sample_h(meta, H, loop[:, 0], loop[:, 1]), 10, True)
    loop_y = profile(g_loop, STEP, True, {})
    g_link = smooth(sample_h(meta, H, link[:, 0], link[:, 1]), 10, False)
    # the start: on the West Switchbacks' lower west hairpin, where it turns back (the highway carries
    # straight on out of the bend); its height there
    start_y = START_Y
    link_y = profile(g_link, STEP, False, {0: start_y, len(link) - 1: float(loop_y[t_i])})
    # the Summit Pass: from a T on the link to a T on the Mountain Road
    global PASS_START, PASS_END
    k = int(np.argmin(np.linalg.norm(link - np.array(PASS_START, dtype=float), axis=1)))
    PASS_START = (float(link[k, 0]), float(link[k, 1]))
    pass_y0 = float(link_y[k])
    mr = [r for r in old if r["name"] == "Mountain Road"][0]["s"]
    m = min(range(len(mr)), key=lambda i: (mr[i][0] - PASS_END[0]) ** 2 + (mr[i][2] - PASS_END[1]) ** 2)
    PASS_END = (mr[m][0], mr[m][2])
    pass_y1 = mr[m][1]
    ps, _ = resample(pass_line(), False)
    # round off the joins between the legs, the hairpins and the free curves (a light average)
    for _ in range(3):
        q = ps.copy()
        q[3:-3] = (ps[1:-5] + ps[2:-4] + ps[3:-3] + ps[4:-2] + ps[5:-1]) / 5
        ps = q
    g_pass = smooth(sample_h(meta, H, ps[:, 0], ps[:, 1]), 6, False)
    global HIGHWAY_GRADE
    keep_grade = HIGHWAY_GRADE
    HIGHWAY_GRADE = PASS_GRADE
    # inside the two roads it joins, the pass lies on their surface (their height at the nearest sample),
    # so there's no step at the joins; it starts to climb or drop only past their edges
    pins = {}

    def height_on(xz, ys, q):
        """the height of a road (centre points xz, heights ys) where q projects onto it"""
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
    mr_xz = np.array([[q[0], q[2]] for q in mr])
    mr_y = np.array([q[1] for q in mr])
    for i in range(len(ps)):
        if np.linalg.norm(ps[i] - np.array(PASS_START)) < HALF + 12:
            pins[i] = height_on(link, link_y, ps[i])
        elif np.linalg.norm(ps[i] - np.array(PASS_END)) < HALF + 12:
            pins[i] = height_on(mr_xz, mr_y, ps[i])
    # past the joins, the grade builds up over ~60 studs (no kink where the pass leaves the other road)
    pinned = sorted(pins)
    ease = np.ones(len(ps))
    for i in range(len(ps)):
        if pinned:
            dd = min(abs(i - p) for p in pinned) * STEP
            ease[i] = min(1.0, 0.15 + dd / 70.0)
    pass_y = profile(g_pass, STEP, False, pins, ease)
    HIGHWAY_GRADE = keep_grade
    out = []
    report = []
    for name, P, Y, closed, rank, glr in (("Riviera Highway", link, link_y, False, 37, g_link), ("Highway Loop", loop, loop_y, True, 36, g_loop), ("Summit Pass", ps, pass_y, False, 38, g_pass)):
        half = PASS_HALF if name == "Summit Pass" else HALF
        kind = "pass" if name == "Summit Pass" else "route"
        D = directions(P, closed)
        s = [[round(float(P[i, 0]), 2), round(float(Y[i]), 2), round(float(P[i, 1]), 2), round(float(D[i, 0]), 4), round(float(D[i, 1]), 4), 0, half, half] for i in range(len(P))]
        if closed:
            s.append(list(s[0]))  # (closed roads repeat their first sample at the end, like export_roads.py's)
        out.append({"name": name, "kind": kind, "closed": closed, "rank": rank, "highway": True, "s": s})
        gr = np.abs(np.diff(Y if not closed else np.append(Y, Y[0]))) / STEP
        cut = glr - Y
        report.append("%s: %d samples, %.0f studs, heights %.0f-%.0f, max grade %.1f%%, min radius %.0f, deepest cut %.0f, highest fill %.0f" % (
            name, len(P), len(P) * STEP, Y.min(), Y.max(), gr.max() * 100, min_radius(P, closed), cut.max(), -cut.min()))
    report.append("T at loop sample %d (%.0f, %.0f), %.1f studs from the link's end" % (t_i, loop[t_i, 0], loop[t_i, 1], d[t_i]))
    return out, report


def write_lua(roads):
    """src/shared/RivieraHighway.lua: the highway's race (the link, then once round the loop and back
    to the T) and its fast travel spot, for ActivityData / TravelSpots"""
    link = [r for r in roads if r["name"] == "Riviera Highway"][0]["s"]
    loop = [r for r in roads if r["name"] == "Highway Loop"][0]["s"][:-1]
    end = link[-1]
    t_i = min(range(len(loop)), key=lambda i: (loop[i][0] - end[0]) ** 2 + (loop[i][2] - end[2]) ** 2)
    # round the loop the way a car turning left at the T goes (the samples backwards)
    ring = [loop[(t_i - k) % len(loop)] for k in range(len(loop) + 1)]
    path = link[12:] + ring[1:]
    cps, acc = [], 0.0
    for i in range(1, len(path)):
        a, b = path[i - 1], path[i]
        acc += math.hypot(b[0] - a[0], b[2] - a[2])
        if acc >= 180 or i == len(path) - 1:
            cps.append(b)
            acc = 0.0
    length = sum(math.hypot(path[i][0] - path[i - 1][0], path[i][2] - path[i - 1][2]) for i in range(1, len(path)))
    st = path[0]

    def v(p):
        return "Vector3.new(%.1f, %.2f, %.1f)" % (p[0], p[1], p[2])
    spot = link[160]
    lines = [
        "-- generated by tools/map_plan/highway.py: do not edit",
        "-- the Riviera Highway's race and fast travel spot (2026-11-04)",
        "return {",
        '\trace = { id = "riv_highway", name = "Riviera Highway", start = %s, dir = Vector3.new(%.3f, 0, %.3f), length = %d, checkpoints = { %s } },' % (
            v(st), st[3], st[4], int(length), ", ".join(v(c) for c in cps)),
        '\tspot = { at = %s, dir = Vector3.new(%.3f, 0, %.3f) },' % (v(spot), spot[3], spot[4]),
        "}",
    ]
    path_lua = os.path.join(ROOT, "src", "shared", "RivieraHighway.lua")
    open(path_lua, "w", encoding="utf-8", newline="").write("\r\n".join(lines) + "\r\n")
    return len(cps), int(length)


if __name__ == "__main__":
    roads, report = build()
    json.dump({"roads": roads}, open(os.path.join(RIV, "highway.json"), "w"), separators=(",", ":"))
    print("\n".join(report))
    print("race: %d checkpoints, %d studs" % write_lua(roads))
    if "--plot" in sys.argv:
        pts = [(s[0], s[2]) for r in roads for s in r["s"][::3]]
        json.dump(pts, open(sys.argv[sys.argv.index("--plot") + 1], "w"))
