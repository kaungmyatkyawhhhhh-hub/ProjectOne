"""pilot_plots.py [x0 x1 z0 z1] [--probe probe.json] [--out plots.json]: plot records (d24_bmesh.py's schema) from the real OSM
building outlines in a box, for trying the mesh kit (default: the Hledan pilot, X 28200..28712, Z -1400..-888).

  * outlines: build/osm_ygn/buildings.json (e0_extract.py), world X = 30000 + (lon - 96.14) * KX * 1.6,
    Z = -(lat - 16.82) * KY * 1.6, KX = 111320 cos(16.82 deg), KY = 110540. A building is in when its centroid is in the box.
  * floors: building:levels, else the batch 0.5 plot's floors (same OSM way in ygn_plots_real.json), else by area.
  * style from the tags and size; roof flat for walk-ups / blocks, hip or gable for houses, shed / gable for sheds.
  * front: the edge facing the nearest road (ygn_roads_v4.json samples) within 70 studs of the road's edge.
  * y: from a Studio probe (--probe: {"id": y}); without it the field is left out.
Writes build/ygn_bmesh/pilot_plots.json and pilot_probe.txt (the probe's input: "id x z;x z;..." one line a building).
"""
import json
import math
import os
import random
import sys

from shapely.geometry import Polygon

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
args = [a for i, a in enumerate(sys.argv) if i > 0 and not a.startswith("--") and not sys.argv[i - 1].startswith("--")]
opts = {sys.argv[i]: sys.argv[i + 1] for i in range(1, len(sys.argv) - 1) if sys.argv[i].startswith("--")}
X0, X1, Z0, Z1 = [float(a) for a in args[:4]] if len(args) >= 4 else (28200.0, 28712.0, -1400.0, -888.0)
OUT = opts.get("--out", os.path.join(ROOT, "build", "ygn_bmesh", "pilot_plots.json"))
PROBE = opts.get("--probe")

KX = 111320 * math.cos(math.radians(16.82))
KY = 110540


def world(lon, lat):
    return (30000 + (lon - 96.14) * KX * 1.6, -(lat - 16.82) * KY * 1.6)


osm = json.load(open(os.path.join(ROOT, "build", "osm_ygn", "buildings.json"), encoding="utf-8"))["buildings"]
old = {p.get("osm"): p for p in json.load(open(os.path.join(ROOT, "imports", "refs", "map", "ygn_plots_real.json"), encoding="utf-8"))["plots"]}
roads = json.load(open(os.path.join(ROOT, "imports", "refs", "map", "ygn_roads_v4.json"), encoding="utf-8"))["roads"]
samples = []
for r in roads:
    for s in r["s"]:
        if X0 - 200 < s[0] < X1 + 200 and Z0 - 200 < s[2] < Z1 + 200:
            samples.append((s[0], s[2], max(s[6], s[7])))
probe = json.load(open(PROBE)) if PROBE else {}
# the game's carriageways + pavements (wider than real: 1.6 studs a metre, half 32 on main roads): an outline that reaches
# onto one is cut back to the pavement's edge (that edge becomes its street front); under 40% left -> dropped. (The batch
# 0.5 builder pushed such plots back instead; the full plots job must do one or the other.)
from shapely.geometry import LineString
from shapely.ops import unary_union
_lanes = []
for r in roads:
    pts = [(q[0], q[2]) for q in r["s"] if X0 - 300 < q[0] < X1 + 300 and Z0 - 300 < q[2] < Z1 + 300]
    if len(pts) >= 2:
        _lanes.append(LineString(pts).buffer(max(r["s"][0][6], r["s"][0][7]) + 10, cap_style="flat"))
CARRIAGEWAY = unary_union(_lanes) if _lanes else None
dropped_road = []

# Yangon wall paint (multiplied with the near-white atlas): strong pastels, ochre, and plenty of dirty white / grey
PASTEL = [(236, 214, 150), (232, 168, 150), (170, 210, 170), (160, 196, 226), (196, 176, 214), (240, 190, 140),
          (190, 188, 182), (230, 228, 220), (220, 180, 110), (140, 200, 196), (200, 220, 150), (214, 206, 190),
          (176, 176, 172), (236, 200, 200)]
ROOF_TIN = [(150, 70, 50), (128, 60, 46), (140, 140, 138), (110, 112, 114), (70, 110, 84), (60, 90, 130), (170, 90, 60)]
CONCRETE = [(160, 158, 152), (146, 144, 138), (172, 168, 160), (132, 130, 126)]


def num(v):
    try:
        return float(str(v).split(";")[0].replace(",", "."))
    except Exception:
        return None


plots = []
probe_lines = []
for b in osm:
    pts = [world(lo, la) for lo, la in b["p"]]
    if len(pts) > 1 and pts[0] == pts[-1]:
        pts = pts[:-1]
    if len(pts) < 3:
        continue
    poly = Polygon(pts)
    if not poly.is_valid:
        poly = poly.buffer(0)
    c = poly.centroid
    if not (X0 <= c.x < X1 and Z0 <= c.y < Z1):
        continue
    if CARRIAGEWAY is not None and poly.intersects(CARRIAGEWAY):
        cut = poly.difference(CARRIAGEWAY)
        if cut.geom_type == "MultiPolygon":
            cut = max(cut.geoms, key=lambda g: g.area)
        if cut.is_empty or cut.geom_type != "Polygon" or cut.area < 0.4 * poly.area or cut.area < 60:
            dropped_road.append(b["id"])
            continue
        poly = cut.simplify(0.3)
        pts = list(poly.exterior.coords)[:-1]
        c = poly.centroid
    t = b.get("t", {})
    kind = t.get("building", "yes")
    if kind in ("roof", "no", "construction", "ruins"):
        continue
    rng = random.Random(b["id"])
    m2 = poly.area / 2.56
    lv = num(t.get("building:levels"))
    oid = ("w" if b.get("way", True) else "r") + str(b["id"])
    if lv:
        floors = int(round(lv))
    elif oid in old:
        floors = int(old[oid]["floors"])
    elif num(t.get("height")):
        floors = max(1, int(num(t["height"]) / 3.2))
    else:
        floors = 1 if m2 < 40 else rng.choice([2, 3]) if m2 < 150 else rng.choice([3, 4, 5]) if m2 < 600 else rng.choice([4, 5, 6])
    floors = max(1, min(floors, 30))
    if kind in ("warehouse", "industrial", "shed", "garage", "garages", "hut", "kiosk", "carport", "service"):
        style = "shed"
    elif kind in ("house", "detached", "bungalow", "semidetached_house"):
        style = "villa" if m2 > 220 else "house"
    elif kind in ("apartments", "dormitory", "residential"):
        style = "walkup" if floors <= 8 else "tower"
    elif kind in ("commercial", "retail", "office", "hotel"):
        style = "tower" if floors >= 9 else ("shophouse" if m2 < 220 else "mass")
    elif kind in ("university", "school", "college", "hospital", "public", "civic", "temple", "religious", "monastery", "church", "government"):
        style = "hall"
    else:
        if floors >= 9:
            style = "tower"
        elif m2 < 45 and floors <= 1:
            style = "shed"
        elif m2 < 160 and floors <= 3:
            style = rng.choice(["house", "shophouse", "walkup"])
        else:
            style = "walkup" if rng.random() < 0.55 else "mass"
    if style in ("house", "villa"):
        roof = rng.choice(["hip", "hip", "gable"])
    elif style == "shed":
        roof = rng.choice(["shed", "gable"])
    elif style == "hall":
        roof = rng.choice(["flat", "hip"])
    else:
        roof = "flat"
    rc = t.get("roof:colour")
    roof_colour = rng.choice(ROOF_TIN) if roof != "flat" else rng.choice(CONCRETE)
    if rc and rc.startswith("#") and len(rc) == 7:
        roof_colour = tuple(int(rc[i:i + 2], 16) for i in (1, 3, 5))
    wall = rng.choice(PASTEL)
    if style == "tower":
        wall = rng.choice([(236, 236, 230), (226, 230, 232), (240, 236, 226)])
    # front: the edge whose outward normal looks at the nearest road edge
    ring = list(Polygon(pts).buffer(0).exterior.coords)[:-1] if not Polygon(pts).is_valid else pts
    sa = sum(ring[i][0] * ring[(i + 1) % len(ring)][1] - ring[(i + 1) % len(ring)][0] * ring[i][1] for i in range(len(ring)))
    if sa > 0:  # counter-clockwise in (x, z) = clockwise from above: turn it round
        ring = ring[::-1]
    best, front, dist = 1e9, None, 1e9
    for i in range(len(ring)):
        a, bb = ring[i], ring[(i + 1) % len(ring)]
        L = math.hypot(bb[0] - a[0], bb[1] - a[1])
        if L < 4:
            continue
        mx, mz = (a[0] + bb[0]) / 2, (a[1] + bb[1]) / 2
        nx, nz = -(bb[1] - a[1]) / L, (bb[0] - a[0]) / L
        for sx, sz, half in samples:
            dx, dz = sx - mx, sz - mz
            d = math.hypot(dx, dz)
            if d < 1e-6:
                continue
            facing = (dx * nx + dz * nz) / d
            if facing < 0.55:
                continue
            gap = d - half - 10
            score = gap - 8 * facing - 0.05 * L
            if gap < 70 and score < best:
                best, front, dist = score, i, gap
    shop = False
    if front is not None and style in ("shophouse", "walkup", "mass") and floors <= 7:
        shop = style == "shophouse" or (dist < 30 and rng.random() < 0.7)
    rec = {"id": oid, "poly": [[round(x, 2), round(z, 2)] for x, z in ring], "floors": floors, "style": style, "roof": roof,
           "roof_colour": list(roof_colour), "wall_colour": list(wall), "front": front, "shop": shop, "name": t.get("name")}
    if oid in probe:
        rec["y"] = probe[oid]
    plots.append(rec)
    step = max(1, len(ring) // 12)
    probe_lines.append(oid + " " + ";".join("%.1f %.1f" % (x, z) for x, z in ring[::step] + [(c.x, c.y)]))

os.makedirs(os.path.dirname(OUT), exist_ok=True)
json.dump(plots, open(OUT, "w", encoding="utf-8"), indent=0)
open(os.path.join(os.path.dirname(OUT), "pilot_probe.txt"), "w").write("\n".join(probe_lines))
from collections import Counter
print("dropped on a carriageway:", len(dropped_road), dropped_road)
print(len(plots), "plots;", Counter(p["style"] for p in plots), "shops", sum(p["shop"] for p in plots), "with y", sum("y" in p for p in plots))
