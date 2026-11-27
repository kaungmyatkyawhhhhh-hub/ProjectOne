"""Straight lane / centre lines where the road flares (27 Nov 2026, owner on Kabar Aye Pagoda Road in front of Myanmar
Plaza: "im pretty sure the big markings are straight irl in frotn of plaza"; vault `City Legends/2026-11-27 Myanmar
Plaza front - current design, off the road.md`).

roads05_paint centres the lanes on the carriageway's width, so where one side flares for a turn lane (Kabar Aye
Pagoda Road's east side widens 32.6 -> 40.5 studs over z 27128..27032) every lane line and the double centre line jog
2-4 studs sideways and back. Real lines run straight; the flare is only a wider outer lane.

STRAIGHT lists stretches: a reference line (a -> b, world x, z), the box of item centroids to fix (z range, |offset|
max) and the straight offsets (studs, + = right of a -> b) the lines keep there. Every 'lane' / 'centre' item in the
box is rebuilt as a straight strip along a -> b at the nearest offset, same length and width.
    roads05_paint.py calls straighten(items) last.
    python paint_straight.py <paint.json>      (rewrites a built paint.json in place, keeps <paint.json>.bak27)
"""
import json, math, shutil, sys

STRAIGHT = [
    # Kabar Aye Pagoda Road, the approach to the No. 1 Industrial Road junction (Myanmar Plaza); a -> b = its centre
    # samples at z 27699 and 26969 (straight). Offsets = the lines' places south of the flare (z 27190-27240).
    dict(road="Kabar Aye Pagoda Road", a=(34569.32, 27699.02), b=(34663.78, 26969.32), z=(27025.0, 27200.0),
         maxlat=34.0, lane=(-21.35, -11.3, 14.45, 24.5), centre=(-0.75, 4.25),
         # the northbound approach's turn arrows go to the straight lanes' middles (centre line 4.25 .. 14.45 .. 24.5
         # .. kerb ~37.5) and its stop line starts at the centre line (it started 1 stud east of the jogged one)
         arrows=(9.35, 19.5, 31.0), stop_from=4.6),
]


def _frame(s):
    a, b = s["a"], s["b"]
    L = math.dist(a, b)
    u = ((b[0] - a[0]) / L, (b[1] - a[1]) / L)
    n = (-u[1], u[0])
    return a, u, n


def _fix(it, s):
    a, u, n = _frame(s)
    P = it["p"]
    lon = [(q[0] - a[0]) * u[0] + (q[1] - a[1]) * u[1] for q in P]
    lat = [(q[0] - a[0]) * n[0] + (q[1] - a[1]) * n[1] for q in P]
    targets = s["centre"] if it["w"] == "centre" else s["lane"]
    c = sum(lat) / len(lat)
    t = min(targets, key=lambda v: abs(v - c))
    w = 0.45
    l0, l1 = min(lon), max(lon)
    pts = []
    for lo, la in ((l0, t - w / 2), (l1, t - w / 2), (l1, t + w / 2), (l0, t + w / 2)):
        pts.append([round(a[0] + u[0] * lo + n[0] * la, 2), round(a[1] + u[1] * lo + n[1] * la, 2)])
    it["p"] = pts
    it["straight"] = s["road"]
    return abs(t - c)


def _shift(it, a, u, n, s):
    """Arrows: moved sideways to the nearest lane middle; the stop line: its centre-side end onto stop_from."""
    P = it["p"]
    lat = [(q[0] - a[0]) * n[0] + (q[1] - a[1]) * n[1] for q in P]
    if it["w"] == "arrow":
        c = (min(lat) + max(lat)) / 2
        d = min(s["arrows"], key=lambda v: abs(v - c)) - c
        it["p"] = [[round(q[0] + n[0] * d, 2), round(q[1] + n[1] * d, 2)] for q in P]
    else:
        lo = min(lat)
        it["p"] = [[round(q[0] + n[0] * (s["stop_from"] - la), 2), round(q[1] + n[1] * (s["stop_from"] - la), 2)]
                   if la - lo < 1.0 else q for q, la in zip(P, lat)]
    it["straight"] = s["road"]


def straighten(items):
    moved = 0
    for s in STRAIGHT:
        a, u, n = _frame(s)
        for it in items:
            if it.get("w") in ("arrow", "stop") and "arrows" in s and it.get("r") == s["road"]:
                xs = [q[0] for q in it["p"]]
                zs = [q[1] for q in it["p"]]
                cx, cz = sum(xs) / len(xs), sum(zs) / len(zs)
                lat = (cx - a[0]) * n[0] + (cz - a[1]) * n[1]
                if s["z"][0] <= cz <= s["z"][0] + 40 and 0 < lat <= s["maxlat"] + 8:
                    _shift(it, a, u, n, s)
                    moved += 1
                continue
            if it.get("w") not in ("lane", "centre") or it.get("r") != s["road"]:
                continue
            xs = [q[0] for q in it["p"]]
            zs = [q[1] for q in it["p"]]
            cx, cz = sum(xs) / len(xs), sum(zs) / len(zs)
            lat = (cx - a[0]) * n[0] + (cz - a[1]) * n[1]
            # a centre line reaching into the box is rebuilt whole (it is one long strip)
            inside = s["z"][0] <= min(zs) <= s["z"][1] or s["z"][0] <= cz <= s["z"][1]
            if inside and abs(lat) <= s["maxlat"]:
                _fix(it, s)
                moved += 1
    return moved


def _selftest():
    s = STRAIGHT[0]
    a, u, n = _frame(s)
    it = {"w": "lane", "r": s["road"], "p": [[a[0] + u[0] * 600 + n[0] * 17.5, a[1] + u[1] * 600 + n[1] * 17.5]]}
    it["p"] += [[it["p"][0][0] + u[0] * 9, it["p"][0][1] + u[1] * 9]]
    _fix(it, s)
    lat = [(q[0] - a[0]) * n[0] + (q[1] - a[1]) * n[1] for q in it["p"]]
    assert abs(sum(lat) / 4 - 14.45) < 0.01 and abs(max(lat) - min(lat) - 0.45) < 0.01


_selftest()

if __name__ == "__main__":
    f = sys.argv[1]
    import os
    if not os.path.exists(f + ".bak27"):   # the bake's own paint, kept once: every run starts from it
        shutil.copy(f, f + ".bak27")
    d = json.load(open(f + ".bak27"))
    print("straightened", straighten(d["items"]))
    json.dump(d, open(f, "w"))
