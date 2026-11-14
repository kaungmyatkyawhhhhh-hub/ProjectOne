"""landmark_mc_fit.py: fits the Myanmar Centre layout (build/landmarks/myanmar_centre/layout.json, real positions) into the
game's free lot between Kabar Aye Pagoda Road and No.1 Industrial Road -> layout_fit.json (read by landmark_mc_blend.py).

Why: the map's roads are car-scale wide (lanes at 3 studs a metre) while plans are 1.6 studs a metre, so each road eats
~13-23 studs into the real building outlines. lot_rays.json holds Studio raycasts (distance from three centres to the first
road / pavement surface in 72 directions). Here:
  * lot = union of the three star polygons, inset by SETBACK;
  * podium and Melia podium = their outline clipped to the lot;
  * tower A slides along the Industrial Road normal until its north-east face is FLUSH studs inside the clipped podium edge;
  * the plinth goes in the lot's north tip (largest circle up to PLINTH_R that fits, as far toward the junction as it can),
    and the podium's tip is cut back square to the plinth's facing so a PLAZA-deep forecourt stays in front of the screen.
"""
import json
import math
import os
import sys

from shapely.geometry import Point, Polygon, LineString
from shapely.ops import unary_union
from shapely import affinity

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "..", "..", "build", "landmarks", "myanmar_centre")
OX, OZ = 32600.0, -1350.0
SETBACK = 3.0
FLUSH = 1.5
PLINTH_R = 20.0
PLAZA = 12.0
DOME_GAP = 8.0
CHORD_MAX = 64.0


def model(X, Z):
    return (X - OX, -(Z - OZ))


def main():
    lay = json.load(open(os.path.join(ROOT, "layout.json")))
    rays = json.load(open(os.path.join(ROOT, "lot_rays.json")))
    stars = []
    for r in rays["rays"]:
        cx, cz = r["c"]
        pts = []
        for k, d in enumerate(r["d"]):
            a = math.radians(k * 5)
            pts.append(model(cx + math.cos(a) * d, cz + math.sin(a) * d))
        stars.append(Polygon(pts).buffer(0))
    lot0 = unary_union(stars)
    if lot0.geom_type != "Polygon":
        lot0 = max(lot0.geoms, key=lambda g: g.area)
    lot = lot0.buffer(-SETBACK)
    if lot.geom_type != "Polygon":
        lot = max(lot.geoms, key=lambda g: g.area)

    pod = Polygon(lay["podium"]).buffer(0)
    pod_fit = pod.intersection(lot)
    # the Industrial Road normal (outward, model coords): the podium's long north-east edge
    p, q = lay["podium"][10], lay["podium"][11]  # (149.7, 5.5) -> (58.9, 82.6)
    ex, ey = q[0] - p[0], q[1] - p[1]
    L = math.hypot(ex, ey)
    n = (ey / L, -ex / L)  # right of p -> q
    if n[0] < 0:  # must point north-east (+x, +y)
        n = (-n[0], -n[1])
    # where the clipped podium's NE edge is, along n
    def along(poly):
        return max(x * n[0] + y * n[1] for x, y in poly.exterior.coords)
    edge = along(pod_fit)
    A = Polygon(lay["A"])
    shift = edge - FLUSH - along(A)
    A_fit = affinity.translate(A, shift * n[0], shift * n[1]) if shift < 0 else A

    # the plinth: a long shallow arc wall (critique 2026-11-14: "a long sign wall, not a drum"). Search the lot's north tip
    # for the apex (front middle of the wall), radius and span whose hedge ring (r + 4.5) and chord fit inside the lot;
    # score = chord length (up to CHORD_MAX) + how far toward the junction the apex sits (keeps more podium).
    import numpy as np
    import shapely
    from shapely.prepared import prep
    face = (-0.392, 0.920)  # from the real podium front's middle to the real plinth, unit
    lotp = prep(lot)
    best = None
    minx, miny, maxx, maxy = lot.bounds
    fa = math.atan2(face[1], face[0])
    for r in range(28, 66, 4):
        for sd in range(56, 116, 6):
            hs = math.radians(sd) / 2
            sag = r * (1 - math.cos(hs))
            chord = 2 * r * math.sin(hs)
            th = np.linspace(fa - hs, fa + hs, 17)
            ox, oy = (r + 4.5) * np.cos(th), (r + 4.5) * np.sin(th)
            # the chord (garden back edge) sampled too
            cx_, cy_ = r * np.cos(th[[0, -1]]), r * np.sin(th[[0, -1]])
            chx = np.linspace(cx_[0], cx_[1], 9)
            chy = np.linspace(cy_[0], cy_[1], 9)
            relx = np.concatenate([ox, chx])
            rely = np.concatenate([oy, chy])
            for ay in np.arange(maxy, 60, -2.0):
                for ax in np.arange(minx, maxx, 2.0):
                    # centre = apex - face * r
                    ccx, ccy = ax - face[0] * r, ay - face[1] * r
                    if not shapely.contains_xy(lot, ccx + relx, ccy + rely).all():
                        continue
                    score = min(chord, CHORD_MAX) + 0.6 * (ax * face[0] + ay * face[1])
                    if best is None or score > best[0]:
                        best = (score, ax, ay, r, sd, sag, chord)
    if best is None:
        print("no room for the plinth")
        sys.exit(1)
    _, ax, ay, PR, PSPAN, sag, chord = best
    px, py = ax - face[0] * PR, ay - face[1] * PR  # the arc's centre
    # cut the podium back: PLAZA studs behind the wall's chord
    back = sag + 3.0 + PLAZA
    cut_c = (ax - face[0] * back, ay - face[1] * back)
    big = 2000.0
    t = (face[1], -face[0])
    half = Polygon([(cut_c[0] + t[0] * big, cut_c[1] + t[1] * big),
                    (cut_c[0] - t[0] * big, cut_c[1] - t[1] * big),
                    (cut_c[0] - t[0] * big - face[0] * big, cut_c[1] - t[1] * big - face[1] * big),
                    (cut_c[0] + t[0] * big - face[0] * big, cut_c[1] + t[1] * big - face[1] * big)])
    pod_fit = pod_fit.intersection(half)
    if pod_fit.geom_type != "Polygon":
        pod_fit = max(pod_fit.geoms, key=lambda g: g.area)
    pod_fit = pod_fit.simplify(0.5)

    # the dome skylight keeps DOME_GAP studs behind the new front (it sat 26 studs deep in the real podium)
    dx, dy = lay["dome_c"]
    lim = -(26.0 + DOME_GAP)
    k = (dx - cut_c[0]) * face[0] + (dy - cut_c[1]) * face[1]
    if k > lim:
        dx, dy = dx + face[0] * (lim - k), dy + face[1] * (lim - k)
    dome = [round(dx, 2), round(dy, 2)]

    mel = unary_union([Polygon(lay["melia_osm"]).buffer(0), Polygon(lay["C"]).buffer(1.0, join_style=2),
                       Polygon(lay["D"]).buffer(1.0, join_style=2)]).intersection(lot)
    if mel.geom_type != "Polygon":
        mel = max(mel.geoms, key=lambda g: g.area)
    mel = mel.simplify(0.5)

    def ring(poly):
        c = list(poly.exterior.coords)[:-1]
        return [[round(float(x), 2), round(float(y), 2)] for x, y in c]

    # ---- the ground round the buildings: pavers from the road pavement's back edge (0.3 in) to the buildings ----
    fa = math.atan2(face[1], face[0])
    hs = math.radians(PSPAN) / 2
    arc = [(px + PR * math.cos(fa + t), py + PR * math.sin(fa + t)) for t in np.linspace(-hs, hs, 25)]
    garden = Polygon(arc).buffer(0)  # the arc and its chord: the lawn behind the wall
    E = Polygon(lay["E"]).buffer(6.0, join_style=2)
    builds = unary_union([pod_fit, mel, E] + [Polygon(lay[k]).buffer(0) for k in ("whiteroof",)])
    site = unary_union([builds, Point(px, py).buffer(PR + 12)]).buffer(30, join_style=2)
    # the paving reaches the real pavement edge: a 2-stud raycast grid of the road surfaces (lot_fine.json) when there is one
    fine_p = os.path.join(ROOT, "lot_fine.json")
    lot_pave = Polygon(json.load(open(fine_p))).buffer(0) if os.path.exists(fine_p) else lot0
    pave = lot_pave.buffer(-0.3).intersection(site).difference(builds.buffer(-0.5)).difference(garden.buffer(-0.5))
    tiles = []
    TW, TH = 12.0, 18.0
    bx0, by0, bx1, by1 = pave.bounds
    gx = math.floor(bx0 / TW)
    while gx * TW < bx1:
        gy = math.floor(by0 / TH)
        while gy * TH < by1:
            cell = Polygon([(gx * TW, gy * TH), ((gx + 1) * TW, gy * TH), ((gx + 1) * TW, (gy + 1) * TH), (gx * TW, (gy + 1) * TH)])
            part = pave.intersection(cell)
            geoms = [part] if part.geom_type == "Polygon" else [g for g in getattr(part, "geoms", []) if g.geom_type == "Polygon"]
            for g in geoms:
                if g.area > 0.5:
                    g = g.simplify(0.05)
                    tiles.append({"cell": [gx * TW, (gx + 1) * TW, gy * TH, (gy + 1) * TH], "outer": ring(g),
                                  "holes": [[[round(float(x), 2), round(float(y), 2)] for x, y in list(h.coords)[:-1]] for h in g.interiors]})
            gy += 1
        gx += 1

    # ---- props: lamp posts along the plaza's road edge near the corner, palms along the west front, trees, bollards ----
    edge = lot0.buffer(-3.5).exterior
    apex = Point(ax, ay)
    lamps = []
    L = edge.length
    d = 0.0
    while d < L:
        pt = edge.interpolate(d)
        if pt.distance(apex) < 110 and not garden.buffer(6).contains(pt) and not builds.buffer(3).contains(pt):
            q = edge.interpolate(min(d + 1.0, L))
            ex, ey = q.x - pt.x, q.y - pt.y
            lamps.append([round(pt.x, 2), round(pt.y, 2), round(math.atan2(ex, -ey), 3)])
        d += 22.0
    # palms: along the podium's street fronts facing west (Kabar Aye Pagoda Road), 7 studs out, every 18 of outline
    palms = []
    ext = pod_fit.exterior
    dd = 9.0
    while dd < ext.length:
        pt = ext.interpolate(dd)
        q0, q1 = ext.interpolate(max(dd - 1.0, 0)), ext.interpolate(min(dd + 1.0, ext.length))
        tx_, ty_ = q1.x - q0.x, q1.y - q0.y
        ln = math.hypot(tx_, ty_) or 1.0
        nx, ny = ty_ / ln, -tx_ / ln
        if pod_fit.contains(Point(pt.x + nx * 2, pt.y + ny * 2)):
            nx, ny = -nx, -ny
        cand = Point(pt.x + nx * 7, pt.y + ny * 7)
        if nx < -0.6 and lot0.buffer(-1).contains(cand) and not garden.buffer(4).contains(cand):
            palms.append([round(cand.x, 2), round(cand.y, 2)])
        dd += 18.0
    trees = []
    for side in (-1, 1):
        t = fa + side * (hs + math.radians(9))
        for rr in (PR - 6, PR + 4):
            pt = (px + rr * math.cos(t), py + rr * math.sin(t))
            if lot0.buffer(-2).contains(Point(pt)) and not builds.buffer(4).contains(Point(pt)):
                trees.append([round(pt[0], 2), round(pt[1], 2)])
    tvec = (face[1], -face[0])
    bollards = []
    for i in range(-5, 6):
        pt = (cut_c[0] + face[0] * 5 + tvec[0] * i * 5.0, cut_c[1] + face[1] * 5 + tvec[1] * i * 5.0)
        if lot0.buffer(-1).contains(Point(pt)) and not garden.buffer(2).contains(Point(pt)):
            bollards.append([round(pt[0], 2), round(pt[1], 2)])
    out = dict(lay)
    out.update({
        "podium": ring(pod_fit),
        "melia_osm": ring(mel) + [ring(mel)[0]],
        "A": [[round(x, 2), round(y, 2)] for x, y in list(A_fit.exterior.coords)[:-1]],
        "plinth_c": [round(float(px), 2), round(float(py), 2)],
        "dome_c": dome,
        "front_c": [round(float(cut_c[0]), 2), round(float(cut_c[1]), 2)],
        "face": list(face),
        "lot": ring(lot),
        "lot0": ring(lot0),
        "apex": [round(float(ax), 2), round(float(ay), 2)],
        "paving": tiles,
        "lamps": lamps,
        "palms": palms,
        "trees": trees,
        "bollards": bollards,
        "fit": {"setback": SETBACK, "A_shift": round(shift, 2), "plinth_r": PR, "plinth_span": PSPAN,
                "plinth_chord": round(chord, 1), "plaza": PLAZA,
                "podium_area_kept": round(pod_fit.area / pod.area, 3)},
    })
    json.dump(out, open(os.path.join(ROOT, "layout_fit.json"), "w"), indent=1)
    print(json.dumps(out["fit"]), "plinth", out["plinth_c"], "front", out["front_c"], "tiles", len(tiles),
          "lamps", len(lamps), "palms", len(palms), "trees", len(trees), "bollards", len(bollards))
    print("podium", out["podium"])


if __name__ == "__main__":
    main()
