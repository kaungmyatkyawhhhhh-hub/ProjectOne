"""p1_refit_layout.py (2026-11-16): the 1:1 site layouts of Myanmar Centre and Sedona in pilot P1 (replaces
landmark_mc_fit.py's game-road clipping: the P1 roads have real widths, so the real outlines are built whole).

    YANGON_SCALE=1to1 python p1_refit_layout.py
      -> build/landmarks/myanmar_centre/layout_fit_1to1.json   (mc3d.py at 1:1)
      -> build/landmarks/refs/sedona/site_1to1.json            (sedona3d.py at 1:1)

Coordinates are the OLD model frame (the site audit's; onetoone.py scales them). Inputs: layout.json (the real fit,
site audit 2026-11-16), the P1 road meshes and terrain (p1_site_ground.py), the buildings agent's empty landmark zones
(buildings_1to1.LANDMARK_SITES, rebuilt here the same way) and its built plots (never overlapped).
"""
import json
import math
import os
import sys

from shapely.geometry import Point, Polygon, LineString, MultiPolygon, box as sbox
from shapely.ops import unary_union

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import geo  # noqa: E402
import onetoone as X1  # noqa: E402
from p1_site_ground import Ground  # noqa: E402

assert geo.ONE_TO_ONE, "run with YANGON_SCALE=1to1"
ROOT = os.path.join(HERE, "..", "..", "..")
MC = os.path.join(ROOT, "build", "landmarks", "myanmar_centre")
SD = os.path.join(ROOT, "build", "landmarks", "refs", "sedona")

# the buildings agent's empty zones (buildings_1to1.py LANDMARK_SITES, lon / lat + OSM outlines, grown in metres)
SITES = {
    "myanmar_centre": dict(osm=["o421632377", "o463189671"], pts=[(96.15439, 16.82723), (96.15476, 16.82866)], grow=22.0),
    "sedona": dict(osm=["o374512164"], pts=[(96.154804, 16.830686), (96.154804, 16.830816), (96.156476, 16.830081),
                                            (96.154886, 16.829420), (96.155045, 16.829389), (96.154687, 16.829663)], grow=18.0),
}


def zones():
    fp = json.load(open(os.path.join(ROOT, "build", "footprints", "ygn_footprints.json"), encoding="utf-8"))["buildings"]
    by = {b["id"]: b for b in fp if b["id"] in {i for s in SITES.values() for i in s["osm"]}}
    out = {}
    for name, s in SITES.items():
        geoms = [Point(geo.world(*p)) for p in s["pts"]] + [Polygon(geo.proj(by[i]["poly"])) for i in s["osm"]]
        z = unary_union(geoms).convex_hull.buffer(geo.m(s["grow"]))
        out[name] = Polygon([X1.old_of_world(x, zz) for x, zz in z.exterior.coords])
    return out


def biggest(shape):
    if shape.geom_type == "Polygon":
        return shape
    return max([g for g in getattr(shape, "geoms", []) if g.geom_type == "Polygon"], key=lambda g: g.area)


def ring(poly):
    return [[round(float(x), 2), round(float(y), 2)] for x, y in list(poly.exterior.coords)[:-1]]


def tiles_of(pave, TW=12.0, TH=18.0):
    tiles = []
    bx0, by0, bx1, by1 = pave.bounds
    gx = math.floor(bx0 / TW)
    while gx * TW < bx1:
        gy = math.floor(by0 / TH)
        while gy * TH < by1:
            cell = sbox(gx * TW, gy * TH, (gx + 1) * TW, (gy + 1) * TH)
            part = pave.intersection(cell)
            for g_ in ([part] if part.geom_type == "Polygon" else [q for q in getattr(part, "geoms", []) if q.geom_type == "Polygon"]):
                if g_.area > 0.5:
                    g_ = g_.simplify(0.05)
                    tiles.append({"outer": ring(g_), "holes": [[[round(x, 2), round(y, 2)] for x, y in list(h.coords)[:-1]]
                                                                for h in g_.interiors]})
            gy += 1
        gx += 1
    return tiles


def main():
    G = Ground((-280, -380, 280, 640))
    Z = zones()
    road = G.road
    road_b = road.buffer(0.6)
    plots = G.plots_u.buffer(0.5)

    # ---------------------------------------------------------------- Myanmar Centre
    lay = json.load(open(os.path.join(MC, "layout.json")))
    zone = Z["myanmar_centre"]
    free = zone.difference(road_b).difference(plots)
    # the mall's block, plus the corner plaza's island (at 1:1 a slip lane of the junction runs between them)
    parts = [g_ for g_ in ([free] if free.geom_type == "Polygon" else list(free.geoms)) if g_.area > 50]
    site = unary_union([biggest(free)] + [g_ for g_ in parts if g_.contains(Point(-84.0, 182.0))])
    pod = biggest(Polygon(lay["podium"]).buffer(0).difference(road.buffer(1.5))).simplify(0.3)
    mel = biggest(unary_union([Polygon(lay["melia_osm"]).buffer(0), Polygon(lay["C"]).buffer(1.0, join_style=2),
                               Polygon(lay["D"]).buffer(1.0, join_style=2)]).difference(road.buffer(1.5))).simplify(0.3)
    face = (-0.392, 0.920)
    PR, PSPAN = 20.0, 180.0
    pc = (-84.0, 182.0)
    fa = math.atan2(face[1], face[0])
    hs = math.radians(PSPAN) / 2
    # the water channel inside the arc wall (r - 1.1 .. r - 3.1): kept out of the paving
    chan = Polygon([(pc[0] + (PR - 1.1) * math.cos(fa + t), pc[1] + (PR - 1.1) * math.sin(fa + t))
                    for t in [-hs + 2 * hs * k / 24 for k in range(25)]] +
                   [(pc[0] + (PR - 3.3) * math.cos(fa + t), pc[1] + (PR - 3.3) * math.sin(fa + t))
                    for t in [hs - 2 * hs * k / 24 for k in range(25)]]).buffer(0)
    wall = Polygon([(pc[0] + (PR + 6.2) * math.cos(fa + t), pc[1] + (PR + 0.6) * math.sin(fa + t))
                    for t in [-hs + 2 * hs * k / 24 for k in range(25)]] +
                   [(pc[0] + (PR - 1.2) * math.cos(fa + t), pc[1] + (PR - 1.2) * math.sin(fa + t))
                    for t in [hs - 2 * hs * k / 24 for k in range(25)]]).buffer(0)
    builds = unary_union([pod, mel, Polygon(lay["whiteroof"]).buffer(0)])
    pave = site.buffer(-0.3).difference(builds.buffer(-0.5)).difference(chan).difference(wall)
    # the drives (site audit fixes 5-8) as model polylines + widths (m), clipped to the site later by mc3d
    drives = {
        "ramp_in": {"pts": [[-146, -71], [-110, -76]], "w": 7.0, "ramp": True},
        "ramp_out": {"pts": [[-110, -55], [-143, -51]], "w": 7.0, "ramp": True},
        "melia_drop": {"pts": [[-150, -200], [-136, -178], [-130, -160], [-128, -140], [-125, -125], [-112, -112], [-99, -108]], "w": 6.5},
        "melia_ramp": {"pts": [[-99, -108], [-72, -116]], "w": 6.5, "ramp": True},
        "service_n": {"pts": [[168, 21], [82, -84], [56, -104]], "w": 7.0},
        "service_s": {"pts": [[-150, -185], [-142, -251], [-131, -266], [-88, -275], [-31, -245], [-2, -229]], "w": 6.0},
        "service_e": {"pts": [[56, -104], [23, -171], [-1, -282], [-11, -313]], "w": 6.0},
    }
    # lamps along the plaza's road edge, palms on the west front, trees by the plaza, bollards before the corner door
    lamps = []
    for comp in ([site] if site.geom_type == "Polygon" else list(site.geoms)):
        edge = comp.buffer(-3.5).exterior
        d = 0.0
        while d < edge.length:
            pt = edge.interpolate(d)
            if Point(pc).distance(pt) < 90 and not Point(pc).buffer(PR + 4).contains(pt) and not builds.buffer(4).contains(pt):
                q = edge.interpolate(min(d + 1.0, edge.length))
                lamps.append([round(pt.x, 2), round(pt.y, 2), round(math.atan2(q.x - pt.x, -(q.y - pt.y)), 3)])
            d += 24.0
    palms = []
    ext = pod.exterior
    dd = 9.0
    while dd < ext.length:
        pt = ext.interpolate(dd)
        q0, q1 = ext.interpolate(max(dd - 1.0, 0)), ext.interpolate(min(dd + 1.0, ext.length))
        tx_, ty_ = q1.x - q0.x, q1.y - q0.y
        ln = math.hypot(tx_, ty_) or 1.0
        nx, ny = ty_ / ln, -tx_ / ln
        if pod.contains(Point(pt.x + nx * 2, pt.y + ny * 2)):
            nx, ny = -nx, -ny
        cand = Point(pt.x + nx * 7, pt.y + ny * 7)
        if nx < -0.6 and site.buffer(-2).contains(cand) and not any(LineString(v["pts"]).buffer(v["w"] * 0.9).contains(cand) for v in drives.values()):
            palms.append([round(cand.x, 2), round(cand.y, 2)])
        dd += 18.0
    trees = []
    for side in (-1, 1):
        t = fa + side * (hs + math.radians(14))
        for rr in (PR + 2, PR + 9):
            pt = (pc[0] + rr * math.cos(t), pc[1] + rr * math.sin(t))
            if site.buffer(-3).contains(Point(pt)) and not builds.buffer(4).contains(Point(pt)):
                trees.append([round(pt[0], 2), round(pt[1], 2)])
    # the corner entrance faces the plaza: bollards in a line in front of it
    best = None
    pc_ = list(pod.exterior.coords)
    for i in range(len(pc_) - 1):
        p, q = pc_[i], pc_[i + 1]
        L = math.dist(p, q)
        if L > 10:
            nx_, ny_ = (q[1] - p[1]) / L, -(q[0] - p[0]) / L
            if Polygon(pc_).buffer(0).contains(Point((p[0] + q[0]) / 2 + nx_ * 2, (p[1] + q[1]) / 2 + ny_ * 2)):
                nx_, ny_ = -nx_, -ny_
            if nx_ * face[0] + ny_ * face[1] > 0.9 and (best is None or L > best[2]):
                best = (p, q, L, (nx_, ny_))
    p, q, L, n = best
    fm = ((p[0] + q[0]) / 2, (p[1] + q[1]) / 2)
    tv = ((q[0] - p[0]) / L, (q[1] - p[1]) / L)
    bollards = []
    for i in range(-4, 5):
        pt = (fm[0] + n[0] * 12.0 + tv[0] * i * 5.0, fm[1] + n[1] * 12.0 + tv[1] * i * 5.0)
        if site.buffer(-1).contains(Point(pt)) and not Point(pc).buffer(PR + 2).contains(Point(pt)):
            bollards.append([round(pt[0], 2), round(pt[1], 2)])
    plane, npts, res = G.plane_near(pod.union(mel), 45.0)
    # floor level: the pavement at the west (Kabar Aye Pagoda Road) entrance, where the mall and the Melia doors are
    def pl(x, y):
        X, Zw = X1.world_of_model(x * X1.S, y * X1.S)
        return plane[0] + plane[1] * (X - X1.OX1) + plane[2] * (Zw - X1.OZ1)
    doors = {"west": pl(-112, 0), "corner": pl(fm[0] + n[0] * 6, fm[1] + n[1] * 6), "melia": pl(-125, -172), "plaza": pl(*pc)}
    tmin = min(G.terrain_old(x, y) for x in range(-110, 150, 8) for y in range(-300, 150, 8) if pod.union(mel).contains(Point(x, y)))
    tmax = max(G.terrain_old(x, y) for x in range(-110, 150, 8) for y in range(-300, 150, 8) if pod.union(mel).contains(Point(x, y)))
    out = dict(lay)
    out.update({
        "podium": ring(pod), "melia_osm": ring(mel) + [ring(mel)[0]], "plinth_c": list(pc), "face": list(face),
        "front_c": [round(fm[0], 2), round(fm[1], 2)], "lot": ring(biggest(site)), "lot0": ring(biggest(site)),
        "site": [ring(g_) for g_ in ([site] if site.geom_type == "Polygon" else list(site.geoms))],
        "paving": tiles_of(pave), "lamps": lamps, "palms": palms, "trees": trees, "bollards": bollards, "drives": drives,
        "fit": {"setback": 0.0, "A_shift": 0.0, "plinth_r": PR, "plinth_span": PSPAN, "plaza": 0.0,
                "podium_area_kept": round(pod.area / Polygon(lay["podium"]).buffer(0).area, 3)},
        "ground": {"plane": plane, "plane_points": npts, "plane_res_max": round(res, 2),
                   "doors_y": {k: round(v, 2) for k, v in doors.items()}, "y0": round((doors["west"] + doors["corner"]) / 2, 2), "terrain_min": tmin, "terrain_max": tmax,
                   "zone_area": round(zone.area), "site_area": round(site.area)},
    })
    json.dump(out, open(os.path.join(MC, "layout_fit_1to1.json"), "w"), indent=1)
    print("MC podium kept", out["fit"]["podium_area_kept"], "site", round(site.area), "of zone", round(zone.area),
          "tiles", len(out["paving"]), "lamps", len(lamps), "palms", len(palms), "trees", len(trees), "bollards", len(bollards))
    print("MC plane", [round(v, 5) for v in plane], npts, "res", round(res, 2), "doors", out["ground"]["doors_y"], "terrain", tmin, tmax)

    # ---------------------------------------------------------------- Sedona
    zone = Z["sedona"]
    # the whole Sedona compound (the buildings agent's zone holds only the Garden Wing): the Inya Wing, pools, courts
    # and the Industrial Road frontage out to the road; its plot for the Inya Wing (o452876267, a generic 25-floor
    # condo) is replaced by the real tower
    sdm = json.load(open(os.path.join(SD, "sedona_model.json")))
    feats = unary_union([Polygon(v["m"]).buffer(0) for v in sdm.values() if len(v["m"]) > 3])
    zone = unary_union([zone, feats.convex_hull.buffer(45.0)])
    # the neighbour's compound beyond the back drive (audit fix 13): y < 430 for x > 50
    zone = zone.difference(sbox(50, 432, 400, 800))
    inya = Polygon(sdm["452876267"]["m"]).buffer(0)
    others = unary_union([P for P in G.plots if P.intersection(inya).area < 0.5 * P.area]).buffer(0.5)
    free = zone.difference(road_b).difference(others)
    site = biggest(free).simplify(0.4)
    # the road edge along the site: points of the site's boundary within 2 studs of the road
    plane, npts, res = G.plane_near(site, 20.0)
    def pls(x, y):
        X, Zw = X1.world_of_model(x * X1.S, y * X1.S)
        return plane[0] + plane[1] * (X - X1.OX1) + plane[2] * (Zw - X1.OZ1)
    # the road's east edge x along Kabar Aye Pagoda Road (for the forecourt), every 5 studs of y
    kedge = []
    for y in range(240, 600, 5):
        L = LineString([(-170, y), (40, y)])
        I = L.intersection(road)
        segs = [g_ for g_ in getattr(I, "geoms", [I]) if not g_.is_empty]
        xs = [g_.bounds[2] for g_ in segs if g_.bounds[2] < -20]
        if xs:
            kedge.append([round(max(xs), 2), y])
    sd_out = {"site": ring(site), "plane": plane, "plane_points": npts, "plane_res_max": round(res, 2),
              "kabar_edge": kedge, "y_gate": round(pls(-60, 540), 2), "y_lobby": round(pls(-30, 310), 2),
              "zone_area": round(zone.area), "site_area": round(site.area)}
    json.dump(sd_out, open(os.path.join(SD, "site_1to1.json"), "w"), indent=1)
    print("SD site", round(site.area), "of zone", round(zone.area), "plane", [round(v, 5) for v in plane], npts,
          "res", round(res, 2), "gate y", sd_out["y_gate"], "lobby y", sd_out["y_lobby"])


if __name__ == "__main__":
    main()
