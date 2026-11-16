"""places_1to1.py <tag> plan|build (2026-11-16): the real PLACES of a 1:1 pilot district (owner: "most of the stuff like
the gas station near myanmar plaza ... is missing"; "also the yangon condominiums arent there?"). Run with YANGON_SCALE=1to1.

    python places_extract.py P1          every OSM object of the district with ALL its tags (osm_all.json)
    python places_1to1.py P1 plan        -> places_P1/places.json (read by buildings_1to1.py) + plan.json
    python buildings_1to1.py P1          the kit buildings again: place lots cleared, compounds walled on their real
                                         outlines (gate at the OSM gate), condos at their real levels, crowns
    python places_1to1.py P1 build       -> places_P1/ygnplaces_p1.rbxmx (Folder Data_P1P, client-streamed, LOAD 900)
                                            + driveways.json (fuel entries / exits for the roads builder) + stats, preview

What it makes (all from OSM outlines / points; no invented text, no logos, brand colours as plain colours only):
  fuel stations   forecourt (concrete), canopy on columns (white soffit, Neon light panels, fascia band in a plain
                  colour), pump islands with pumps and yellow bollards, kiosk at the back, entry / exit arrows painted
                  on the forecourt; collision for columns, islands, pumps, kiosk and the forecourt
  car parks       asphalt slab on the lot with white bay lines (2.5 x 5 m bays, 6 m aisles), cut round every building
  pitches         courts (basketball / tennis / volleyball / badminton / futsal or a paved surface): concrete slab, white
                  lines, hoops or net posts; grass / earth pitches: goals at the two ends
  playgrounds     sand pad with a kerb, swing frame with seats, a climbing frame
  compounds       (in buildings_1to1) schools, hospitals, clinics, monasteries, churches, mosques, embassies, hotels,
                  government and university grounds: compound wall on the real outline, the gate where OSM has it
  buildings       (in buildings_1to1) condos = building=apartments / residential with 6+ levels at their real levels;
                  civic archetype for school / hospital / hotel / embassy buildings; low villas for monastery halls
Every slab keeps 1 m off the road corridors (carriageway + pavement), 0.6 m off buildings and compound walls; slabs stand
0.25 studs over the highest terrain under them (no flicker with the ground), line paint 0.08 over the slab.

Record format (kit_pack B): ("B", x, y_centre, z, sx, sy, sz, yaw, code); yaw: local X -> (cos yaw, -sin yaw) in (x, z).
"""
import json
import math
import os
import re
import sys
import time
import zlib
import random
import functools
print = functools.partial(print, flush=True)
from collections import Counter, defaultdict

import numpy as np
import shapely
from shapely.geometry import Polygon, Point, LineString, MultiPolygon, box as sbox
from shapely.ops import unary_union, nearest_points
from shapely.strtree import STRtree
from shapely import affinity

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import geo  # noqa: E402
import kit_pack  # noqa: E402

assert geo.ONE_TO_ONE, "run with YANGON_SCALE=1to1"
TAG = sys.argv[1] if len(sys.argv) > 1 else "P1"
MODE = sys.argv[2] if len(sys.argv) > 2 else "plan"
import buildings_1to1 as BK  # noqa: E402  (corridors, ground, roof_rects, rect_of, MAIN)

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
B1 = os.path.join(ROOT, "build", "city_1to1")
OUT = os.path.join(B1, "places_%s" % TAG)
M = geo.m
TILE = 256.0
LOAD = 900.0
MAIN = BK.MAIN

COMPOUND_AMENITY = {"school", "college", "kindergarten", "university", "hospital", "clinic", "place_of_worship",
                    "monastery", "embassy", "marketplace", "bus_station", "police", "fire_station", "townhall",
                    "community_centre", "courthouse", "prison", "library", "social_facility", "doctors"}
CIVIC_KINDS = {"school", "college", "kindergarten", "university", "hospital", "clinic", "embassy", "police",
               "fire_station", "townhall", "community_centre", "courthouse", "library", "government", "hotel",
               "diplomatic", "office", "doctors", "social_facility", "bus_station", "marketplace"}
RELIGIOUS = {"place_of_worship", "monastery", "religious"}
COURT_SPORTS = {"basketball", "tennis", "volleyball", "badminton", "futsal", "table_tennis", "netball", "multi",
                "sepak_takraw", "chinlone"}
CONDO_WORDS = re.compile(r"condo|residen|tower|housing|apartment|mansion|garden", re.I)
# named condos with a tiled hip crown (Esri satellite z19, 16 Nov 2026: terracotta pyramid roofs on the Pearl Condo towers)
CROWNS = {"o374511963": "KRT", "o374511964": "KRT", "o374511984": "KRT", "o374512116": "KRT"}
# real heights where a source beats OSM (levels): id -> (levels, source)
HEIGHTS = {}
# fuel stations measured on the Esri z19 satellite (16 Nov 2026, build/city_1to1/places_P1/sat/): the canopy's middle,
# its length along the road and depth (m), the roof colour seen from above
SAT = {
    "n3838315913": dict(canopy=(96.14866, 16.82578), size=(24.0, 18.6), roof=(160, 175, 148)),   # Myawaddy, University Ave
}


def W(lon, lat):
    return geo.world(lon, lat)


def poly_w(pts):
    try:
        g = Polygon([W(*p) for p in pts]).buffer(0)
    except Exception:
        return None
    if g.geom_type == "MultiPolygon":
        g = max(g.geoms, key=lambda x: x.area)
    return g if g.geom_type == "Polygon" and not g.is_empty else None


def levels_of(t):
    try:
        if "building:levels" in t:
            return int(round(float(str(t["building:levels"]).split(";")[0])))
        if "height" in t:
            return int(round(float(re.sub(r"[^0-9.]", "", str(t["height"]))) / 3.3))
    except Exception:
        return None
    return None


def load_osm():
    d = json.load(open(os.path.join(OUT, "osm_all.json"), encoding="utf-8"))
    nodes = d["nodes"]
    areas = []
    for w in d["ways"]:
        if w["closed"] and len(w["p"]) >= 4:
            g = poly_w(w["p"])
            if g is not None:
                areas.append(dict(id="w%d" % w["id"], bid="o%d" % w["id"], t=w["t"], g=g, ll=w["p"]))
    for r in d["areas"]:
        g = poly_w(r["p"])
        if g is not None:
            areas.append(dict(id="r%d" % r["id"], bid="o%d" % r["id"], t=r["t"], g=g, ll=r["p"]))
    return nodes, areas, d["ways"]


# ---------------------------------------------------------------------------------------------------------------- plan
def plan():
    t0 = time.time()
    district = geo.batch_poly(TAG)
    inner = district.buffer(-M(3))
    nodes, areas, ways = load_osm()
    corr, road_lines = BK.corridors()
    main_lines = [l[0] for l in road_lines if l[1] in MAIN]
    all_lines = [l[0] for l in road_lines]
    lo0, la0, lo1, la1 = geo.PILOT_LL[TAG]
    fp = json.load(open(os.path.join(ROOT, "build", "footprints", "ygn_footprints.json"), encoding="utf-8"))["buildings"]
    fps = []
    for b in fp:
        if lo0 - 0.001 <= b["poly"][0][0] <= lo1 + 0.001 and la0 - 0.001 <= b["poly"][0][1] <= la1 + 0.001:
            g = poly_w(b["poly"])
            if g is not None and inner.contains(g.centroid):
                fps.append(dict(b, g=g))
    ftree = STRtree([b["g"] for b in fps])
    stats = Counter()
    places = dict(clear=[], drop=[], bld={}, compounds=[])
    items = dict(fuel=[], parking=[], pitch=[], playground=[], condos=[], compounds=[])

    def inside(g):
        return inner.contains(g.centroid if hasattr(g, "centroid") else g)

    # ---- fuel stations
    seen_fuel = []
    fuel_src = [(a["g"], a["t"], a["id"]) for a in areas if a["t"].get("amenity") == "fuel" and "building" not in a["t"]]
    fuel_src += [(Point(W(*n["p"])), n["t"], "n%d" % n["id"]) for n in nodes if n["t"].get("amenity") == "fuel"]
    roofs = [a for a in areas if a["t"].get("building") == "roof"]
    for g, t, oid in fuel_src:
        c = g.centroid
        if not inner.contains(c) or any(c.distance(s) < M(40) for s in seen_fuel):
            continue
        seen_fuel.append(c)
        # the road it opens onto: the nearest road line (main roads preferred within 45 m)
        cand = sorted(all_lines, key=lambda ls: ls.distance(c))
        mains = [ls for ls in main_lines if ls.distance(c) < M(45)]
        road = min(mains, key=lambda ls: ls.distance(c)) if mains else cand[0]
        s = road.project(c)
        pa, pb = road.interpolate(max(0, s - 2)), road.interpolate(min(road.length, s + 2))
        ux, uz = pb.x - pa.x, pb.y - pa.y
        L = math.hypot(ux, uz) or 1.0
        ux, uz = ux / L, uz / L
        foot = road.interpolate(s)
        vx, vz = c.x - foot.x, c.y - foot.y
        side = 1.0 if (-uz * vx + ux * vz) >= 0 else -1.0
        nx, nz = -uz * side, ux * side          # away from the road, towards the station
        # the corridor's edge on that side, then the lot inward from it
        ray = LineString([(foot.x, foot.y), (foot.x + nx * M(80), foot.y + nz * M(80))])
        hit = ray.difference(corr.buffer(M(1.0)))
        if hit.is_empty:
            stats["fuel_no_room"] += 1
            continue
        hs = list(hit.geoms) if hasattr(hit, "geoms") else [hit]
        e0 = min(hs, key=lambda h: Point(h.coords[0]).distance(Point(foot.x, foot.y)))
        ex, ez = e0.coords[0]
        if g.geom_type == "Polygon" and g.area > M(12) * M(12):
            lot = g.difference(corr.buffer(M(1.0)))
            src = "osm outline"
        else:
            # no outline: a 34 x 26 m lot (the median of the 9 Yangon stations measured on the satellite) centred on the
            # point along the road, from the pavement's back edge inward
            Wd, Dp = M(34), M(26)
            cx = foot.x + ux * 0  # along the road: centred on the point's foot
            cz = foot.y
            sat = SAT.get(oid)
            cref = Point(W(*sat["canopy"])) if sat else c
            along = (cref.x - ex) * ux + (cref.y - ez) * uz
            ox, oz = ex + ux * along, ez + uz * along
            lot = Polygon([(ox - ux * Wd / 2, oz - uz * Wd / 2), (ox + ux * Wd / 2, oz + uz * Wd / 2),
                           (ox + ux * Wd / 2 + nx * Dp, oz + uz * Wd / 2 + nz * Dp),
                           (ox - ux * Wd / 2 + nx * Dp, oz - uz * Wd / 2 + nz * Dp)]).difference(corr.buffer(M(1.0)))
            src = "osm point + standard lot"
        if lot.geom_type == "MultiPolygon":
            lot = max(lot.geoms, key=lambda x: x.area)
        if lot.is_empty or lot.area < M(15) * M(12):
            stats["fuel_too_small"] += 1
            continue
        canopy = None
        for a in roofs:
            if a["g"].intersects(lot) and a["g"].intersection(lot).area > 0.6 * a["g"].area:
                canopy = list(a["g"].minimum_rotated_rectangle.exterior.coords)[:-1]
        big = [fps[j] for j in ftree.query(lot, predicate="intersects")
               if fps[j]["g"].intersection(lot).area > 0.3 * fps[j]["g"].area]
        places["clear"].append([list(p) for p in lot.exterior.coords])
        items["fuel"].append(dict(id=oid, name=t.get("name:en") or t.get("name"), brand=t.get("brand") or t.get("operator"),
                                  tags=t, lot=[list(p) for p in lot.exterior.coords], u=[ux, uz], n=[nx, nz],
                                  front=[ex, ez], canopy=canopy, src=src, cleared=[b["id"] for b in big],
                                  sat=SAT.get(oid),
                                  lonlat=list(geo.lonlat(c.x, c.y))))
        stats["fuel"] += 1

    # ---- car parks, pitches, playgrounds (outlines)
    def small_inside(g, amax):
        out = []
        for j in ftree.query(g, predicate="intersects"):
            b = fps[j]
            if b["g"].area < M(1) * M(1) * amax and g.contains(b["g"].centroid):
                out.append(b["id"])
        return out
    for a in areas:
        t, g = a["t"], a["g"]
        if not inside(g) or "building" in t:
            continue
        if t.get("amenity") == "parking" and t.get("parking", "surface") in ("surface", "lane", "street_side") \
                and g.area >= M(1) * M(1) * 150:
            d = small_inside(g, 40)
            places["drop"] += d
            items["parking"].append(dict(id=a["id"], tags=t, poly=[list(p) for p in g.exterior.coords], dropped=d))
            stats["parking"] += 1
        elif t.get("leisure") == "pitch" and g.area >= M(1) * M(1) * 80:
            d = small_inside(g, 60)
            places["drop"] += d
            items["pitch"].append(dict(id=a["id"], tags=t, poly=[list(p) for p in g.exterior.coords], dropped=d))
            stats["pitch"] += 1
        elif t.get("leisure") == "playground" and g.area >= M(1) * M(1) * 40:
            d = small_inside(g, 40)
            places["drop"] += d
            items["playground"].append(dict(id=a["id"], tags=t, poly=[list(p) for p in g.exterior.coords], dropped=d))
            stats["playground"] += 1
    for n in nodes:
        if n["t"].get("leisure") == "playground":
            p = Point(W(*n["p"]))
            if inside(p) and not any(Polygon(q["poly"]).buffer(M(10)).contains(p) for q in items["playground"]):
                g = p.buffer(M(7), 4)  # a 14 m pad round a mapped point
                if g.intersects(corr.buffer(M(1))) or len(ftree.query(g, predicate="intersects")):
                    stats["playground_point_no_room"] += 1
                    continue
                items["playground"].append(dict(id="n%d" % n["id"], tags=n["t"], poly=[list(q) for q in g.exterior.coords],
                                                dropped=[]))
                stats["playground"] += 1

    # ---- compounds (non-building grounds) and their gates
    gates = [Point(W(*n["p"])) for n in nodes if n["t"].get("barrier") in ("gate", "lift_gate", "sliding_gate", "swing_gate")]
    gtree = STRtree(gates) if gates else None
    for a in areas:
        t, g = a["t"], a["g"]
        if "building" in t or not inside(g):
            continue
        am = t.get("amenity")
        kind = None
        if am in COMPOUND_AMENITY:
            kind = am
        elif t.get("office") in ("diplomatic", "government") or t.get("diplomatic") in ("embassy", "consulate"):
            kind = "embassy" if t.get("office") == "diplomatic" or t.get("diplomatic") else "government"
        elif t.get("tourism") == "hotel":
            kind = "hotel"
        elif t.get("landuse") == "religious":
            kind = "religious"
        elif t.get("healthcare") in ("hospital", "clinic", "centre"):
            kind = "hospital"
        if not kind:
            continue
        if g.area < M(1) * M(1) * 400 or g.area > M(1) * M(1) * 700000:
            continue
        gp = []
        if gtree is not None:
            for j in gtree.query(g.buffer(M(6))):
                if g.exterior.distance(gates[j]) < M(6):
                    gp.append([gates[j].x, gates[j].y])
        places["compounds"].append(dict(id=a["id"], kind=kind, name=t.get("name:en") or t.get("name"),
                                        poly=[list(p) for p in g.exterior.coords], gates=gp))
        items["compounds"].append(dict(id=a["id"], kind=kind, name=t.get("name:en") or t.get("name"),
                                       area_m2=round(g.area / 9.0), gates=len(gp)))
        stats["compound_" + kind] += 1
    # the buildings in compounds: civic / religious looks (only low ones: towers keep their own archetype)
    comp_polys = [(Polygon(c["poly"]).buffer(0), c["kind"]) for c in places["compounds"]]
    for b in fps:
        for cp, kind in comp_polys:
            if cp.contains(b["g"].representative_point()):
                f = int(b["floors"] or 2)
                if kind in RELIGIOUS:
                    if f <= 3 and b["kind"] not in ("shed",):
                        places["bld"][b["id"]] = dict(arch="villa", floors=max(1, min(f, 3)), place=kind)
                        stats["bld_religious"] += 1
                elif kind in CIVIC_KINDS and f <= 5 and b["kind"] in ("house", "villa", "shophouse", "walkup", "mass"):
                    places["bld"][b["id"]] = dict(kind="civic", place=kind)
                    stats["bld_civic"] += 1
                break
    # ---- OSM-tagged buildings: condos (real levels), civic buildings
    by_id = {b["id"]: b for b in fps}
    for a in areas:
        t = a["t"]
        if "building" not in t:
            continue
        b = by_id.get(a["bid"])
        if b is None:
            continue
        lv = levels_of(t)
        name = t.get("name:en") or t.get("name") or ""
        bt = t.get("building")
        is_res = bt in ("apartments", "residential", "condominium") or t.get("residential") in ("apartments", "condominium") \
            or (bool(CONDO_WORDS.search(name)) and bt not in ("office", "commercial", "retail", "hotel", "industrial")) \
            or a["bid"] in CROWNS
        if a["bid"] in CROWNS and not lv:
            lv = int(b["floors"] or 0)
        if a["bid"] in HEIGHTS:
            lv = HEIGHTS[a["bid"]][0]
        if is_res and lv and lv >= 6:
            ov = dict(arch="condo", floors=int(lv), place="condo")
            if a["bid"] in CROWNS:
                ov["crown"] = CROWNS[a["bid"]]
            places["bld"][a["bid"]] = ov
            ht = t.get("height")
            items["condos"].append(dict(id=a["bid"], name=name or None, levels=int(lv),
                                        height_m=round(4.5 + 3.33 * (int(lv) - 1) + 1.2, 1),
                                        osm_height=ht, src=HEIGHTS.get(a["bid"], (0, "OSM building:levels" if
                                                                                  "building:levels" in t else "OSM height"))[1],
                                        building=bt, crown=a["bid"] in CROWNS,
                                        lonlat=[round(v, 6) for v in geo.lonlat(b["g"].centroid.x, b["g"].centroid.y)]))
            stats["condo"] += 1
        elif (t.get("amenity") in CIVIC_KINDS or t.get("tourism") == "hotel" or bt in ("school", "hospital", "hotel",
                                                                                       "university", "college",
                                                                                       "government", "office")) \
                and (lv or b["floors"] or 2) <= 5 and a["bid"] not in places["bld"]:
            places["bld"][a["bid"]] = dict(kind="civic", place=t.get("amenity") or t.get("tourism") or bt)
            stats["bld_civic_tag"] += 1
    places["drop"] = sorted(set(places["drop"]))
    os.makedirs(OUT, exist_ok=True)
    json.dump(places, open(os.path.join(OUT, "places.json"), "w", encoding="utf-8"), ensure_ascii=False)
    json.dump(items, open(os.path.join(OUT, "plan.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("plan %s  %.1f s" % (dict(stats), time.time() - t0))


# --------------------------------------------------------------------------------------------------------------- build
class Out:
    def __init__(self):
        self.detail = defaultdict(list)
        self.stats = Counter()
        self.boxes = []      # (shapely footprint, y0, y1, code) of everything placed: the overlap check
        self.keep = []       # ground the places cover (slabs, pads): no trees, no street props there

    def box(self, x, y0, z, sx, sy, sz, ux, uz, code, coll=False, check=True):
        """a box from y0 up sy, centred (x, z), its X along (ux, uz)"""
        yaw = math.atan2(-uz, ux)
        rec = ("B", x, y0 + sy / 2, z, sx, sy, sz, yaw, code)
        self.detail[BK.tile_of(x, z)].append(rec)
        self.stats["parts"] += 1
        if coll:
            self.detail[BK.tile_of(x, z)].append(("B", x, y0 + sy / 2, z, sx, sy, sz, yaw, "WCOL"))
            self.stats["collide"] += 1
        if check:
            fx, fz = -uz, ux
            hx, hz = sx / 2, sz / 2
            self.boxes.append((Polygon([(x - ux * hx - fx * hz, z - uz * hx - fz * hz), (x + ux * hx - fx * hz, z + uz * hx - fz * hz),
                                        (x + ux * hx + fx * hz, z + uz * hx + fz * hz), (x - ux * hx + fx * hz, z - uz * hx + fz * hz)]),
                               y0, y0 + sy, code))


def gmax(poly, step=4.0):
    """highest / lowest terrain under a polygon (4-stud grid)"""
    x0, z0, x1, z1 = poly.bounds
    hs = []
    for x in np.arange(x0, x1 + step, step):
        for z in np.arange(z0, z1 + step, step):
            if poly.buffer(2.0).contains(Point(x, z)):
                hs.append(BK.ground(x, z)[0])
    if not hs:
        hs = [BK.ground(poly.centroid.x, poly.centroid.y)[0]]
    return max(hs), min(hs)


def slab(o, poly, code, coll=True, lift=0.25):
    """a ground slab on a polygon (rectangles), its top `lift` over the highest terrain under it; returns the top y"""
    hi, lo = gmax(poly)
    top = hi + lift
    o.keep.append(poly)
    for (cx, cz, sx, sz, yw) in BK.roof_rects(poly, M(1.0)):
        ux, uz = math.cos(yw), -math.sin(yw)
        y0 = lo - 1.0
        o.box(cx, y0, cz, sx, top - y0, sz, ux, uz, code, coll=coll, check=False)
    o.stats["slab_m2"] += poly.area / 9.0
    return top


def frame_of(poly, prefer=None):
    """the polygon's long axis (unit), its middle, half length / half width of the min rotated rectangle"""
    r = poly.minimum_rotated_rectangle
    cs = list(r.exterior.coords)[:4]
    e1 = (cs[1][0] - cs[0][0], cs[1][1] - cs[0][1])
    e2 = (cs[2][0] - cs[1][0], cs[2][1] - cs[1][1])
    l1, l2 = math.hypot(*e1), math.hypot(*e2)
    if prefer is not None:
        # the axis most parallel to `prefer`
        d1 = abs(e1[0] * prefer[0] + e1[1] * prefer[1]) / max(l1, 1e-6)
        d2 = abs(e2[0] * prefer[0] + e2[1] * prefer[1]) / max(l2, 1e-6)
        if d2 > d1:
            e1, e2, l1, l2 = e2, e1, l2, l1
    elif l2 > l1:
        e1, e2, l1, l2 = e2, e1, l2, l1
    c = r.centroid
    return (c.x, c.y), (e1[0] / l1, e1[1] / l1), l1 / 2, l2 / 2


def lines_rect(o, cx, cz, ux, uz, L, Wd, y, w=0.1 * 3, code="PLN"):
    """the four edge lines of a rectangle (2L along u, 2Wd across) at height y (bottom of the paint)"""
    fx, fz = -uz, ux
    o.box(cx + fx * (Wd - w / 2), y, cz + fz * (Wd - w / 2), 2 * L, 0.08, w, ux, uz, code)
    o.box(cx - fx * (Wd - w / 2), y, cz - fz * (Wd - w / 2), 2 * L, 0.08, w, ux, uz, code)
    o.box(cx + ux * (L - w / 2), y, cz + uz * (L - w / 2), w, 0.08, 2 * Wd - 2 * w, ux, uz, code)
    o.box(cx - ux * (L - w / 2), y, cz - uz * (L - w / 2), w, 0.08, 2 * Wd - 2 * w, ux, uz, code)


def fuel_station(o, st, keep_off, rng):
    lot = Polygon(st["lot"]).buffer(0)
    lot = lot.difference(keep_off)
    if lot.geom_type == "MultiPolygon":
        lot = max(lot.geoms, key=lambda x: x.area)
    ux, uz = st["u"]
    nx, nz = st["n"]
    if ux * nz - uz * nx < 0:   # keep (u, n) a right-handed pair: n = left of u
        ux, uz = -ux, -uz
    top = slab(o, lot, "PCN")
    # frame: along the road u, inward n; the lot's extent in that frame
    pts = list(lot.exterior.coords)
    us = [p[0] * ux + p[1] * uz for p in pts]
    ns = [p[0] * nx + p[1] * nz for p in pts]
    u0, u1, n0, n1 = min(us), max(us), min(ns), max(ns)
    Lu, Ln = u1 - u0, n1 - n0

    def P(a, b):  # frame -> world
        return (ux * a + nx * b, uz * a + nz * b)
    um = (u0 + u1) / 2
    # canopy: the OSM roof outline if mapped, else 60% of the lot's length x 13 m, its front 5 m behind the lot's front
    cl = min(Lu * 0.62, M(24))
    cd = min(M(13), Ln * 0.5)
    cn0 = n0 + min(M(5), Ln * 0.18)
    cpoly = Polygon([P(um - cl / 2, cn0), P(um + cl / 2, cn0), P(um + cl / 2, cn0 + cd), P(um - cl / 2, cn0 + cd)])
    if st.get("sat"):
        sx_, sz_ = W(*st["sat"]["canopy"])
        a_c = sx_ * ux + sz_ * uz
        b_c = sx_ * nx + sz_ * nz
        cl, cd = M(st["sat"]["size"][0]), M(st["sat"]["size"][1])
        b_c = max(b_c, n0 + cd / 2 + M(3.0))     # keep a 3 m drive between the pavement and the canopy
        cpoly = Polygon([P(a_c - cl / 2, b_c - cd / 2), P(a_c + cl / 2, b_c - cd / 2), P(a_c + cl / 2, b_c + cd / 2),
                         P(a_c - cl / 2, b_c + cd / 2)])
        um = a_c
    if st.get("canopy"):
        cpoly = Polygon(st["canopy"])
        (ccx, ccz), (cux, cuz), chl, chw = frame_of(cpoly, prefer=(ux, uz))
    else:
        cc = cpoly.centroid
        ccx, ccz, cux, cuz, chl, chw = cc.x, cc.y, ux, uz, cl / 2, cd / 2
    roof_code = "PCR" if st.get("sat") else "PCW"
    cfx, cfz = -cuz, cux
    clear_h = M(5.4)
    y_roof = top + clear_h
    brand = st.get("colour", "PFG")
    # columns: 2 x n down the middle line pairs, 0.5 m square
    ncol = max(2, int(round(2 * chl / M(9))) + 1)
    for i in range(ncol):
        a = -chl + M(1.6) + i * (2 * chl - M(3.2)) / (ncol - 1)
        for b in (-chw * 0.42, chw * 0.42):
            x, z = ccx + cux * a + cfx * b, ccz + cuz * a + cfz * b
            o.box(x, top, z, M(0.5), clear_h + 0.02, M(0.5), cux, cuz, "PCS", coll=True)
    # roof deck (soffit white), fascia band in the brand colour all round, a thin white top stripe
    o.box(ccx, y_roof, ccz, 2 * chl - 0.4, M(0.5), 2 * chw - 0.4, cux, cuz, "PCW")
    fb = M(1.1)
    for sgn in (1, -1):
        x, z = ccx + cfx * sgn * (chw - 0.15), ccz + cfz * sgn * (chw - 0.15)
        o.box(x, y_roof - M(0.25), z, 2 * chl, fb, 0.3, cux, cuz, brand)
        x, z = ccx + cux * sgn * (chl - 0.15), ccz + cuz * sgn * (chl - 0.15)
        o.box(x, y_roof - M(0.25), z, 0.3, fb, 2 * chw - 0.6, cux, cuz, brand)
    o.box(ccx, y_roof - M(0.25) + fb, ccz, 2 * chl, M(0.12), 2 * chw, cux, cuz, roof_code, check=False)
    # light panels under the soffit (Neon), a grid of 1.2 x 0.6 m
    for i in range(ncol - 1):
        a = -chl + M(1.6) + (i + 0.5) * (2 * chl - M(3.2)) / (ncol - 1)
        for b in (-chw * 0.42, 0.0, chw * 0.42):
            x, z = ccx + cux * a + cfx * b, ccz + cuz * a + cfz * b
            o.box(x, y_roof - 0.12, z, M(1.2), 0.12, M(0.6), cux, cuz, "PLT")
    o.stats["canopies"] += 1
    # pump islands: one between each pair of columns on the two lines, along u
    pumps = []
    for i in range(ncol - 1):
        a = -chl + M(1.6) + (i + 0.5) * (2 * chl - M(3.2)) / (ncol - 1)
        for b in (-chw * 0.42, chw * 0.42):
            x, z = ccx + cux * a + cfx * b, ccz + cuz * a + cfz * b
            o.box(x, top, z, M(5.0), M(0.2), M(1.2), cux, cuz, "PCN", coll=True)
            o.box(x, top + M(0.2), z, M(5.0) - 0.6, 0.06, M(1.2) - 0.6, cux, cuz, "PLY", check=False)
            for s in (-1, 1):
                px, pz = x + cux * s * M(1.3), z + cuz * s * M(1.3)
                yb = top + M(0.2)
                o.box(px, yb, pz, M(0.9), M(1.6), M(0.5), cux, cuz, "PCW", coll=True)
                o.box(px, yb + M(1.6), pz, M(0.9), M(0.35), M(0.5), cux, cuz, brand)
                for f in (1, -1):  # the dark price / litre display on both faces
                    o.box(px + cfx * f * M(0.255), yb + M(1.05), pz + cfz * f * M(0.255), M(0.6), M(0.35), 0.06, cux, cuz,
                          "PPD", check=False)
                pumps.append((px, yb, pz))
            for s in (-1, 1):  # bollards at the island ends
                bx, bz = x + cux * s * M(2.75), z + cuz * s * M(2.75)
                o.box(bx, top, bz, M(0.18), M(0.9), M(0.18), cux, cuz, "PLY", coll=True)
            o.stats["pump_islands"] += 1
    o.stats["pumps"] += len(pumps)
    # kiosk: a 9 x 6 m shop at the back of the lot, behind the canopy, if there is room
    kd, kl, kh = M(6), M(9), M(3.4)
    kn = n1 - kd / 2 - M(1.0)
    kpoly = None
    for ku in (u1 - kl / 2 - M(1.0), u0 + kl / 2 + M(1.0), um):
        cand = Polygon([P(ku - kl / 2, kn - kd / 2), P(ku + kl / 2, kn - kd / 2), P(ku + kl / 2, kn + kd / 2),
                        P(ku - kl / 2, kn + kd / 2)])
        if lot.buffer(-M(0.5)).contains(cand) and not cand.intersects(Polygon(cpoly.exterior.coords).buffer(M(2))):
            kpoly = cand
            break
    if kpoly is not None:
        kc = kpoly.centroid
        o.box(kc.x, top, kc.y, kl, kh, kd, ux, uz, "KW0", coll=True)
        # glass front towards the forecourt (the -n face), a slab roof with a fascia in the brand colour
        gx, gz = kc.x - nx * (kd / 2 + 0.05), kc.y - nz * (kd / 2 + 0.05)
        o.box(gx, top + M(0.3), gz, kl - M(1.6), M(2.3), 0.1, ux, uz, "PGL", check=False)
        o.box(kc.x, top + kh, kc.y, kl + M(0.6), M(0.3), kd + M(0.6), ux, uz, "PCW")
        fx_, fz_ = kc.x - nx * (kd / 2 + M(0.3) + 0.06), kc.y - nz * (kd / 2 + M(0.3) + 0.06)
        o.box(fx_, top + kh - M(0.4), fz_, kl + M(0.6), M(0.7), 0.12, ux, uz, brand, check=False)
        o.stats["kiosks"] += 1
    # entry / exit arrows on the forecourt (painted), 4 m in from the front edge near the two ends
    drive = []
    for s, (au, dirn) in enumerate(((u0 + M(4.5), 1), (u1 - M(4.5), -1))):
        a_n = n0 + M(3.0)
        x, z = P(au, a_n)
        if not lot.buffer(-M(1.0)).contains(Point(x, z)):
            continue
        y = top + 0.08
        # shaft (along n: into the lot for the entry, out for the exit), head two strokes
        inward = 1 if s == 0 else -1
        dx0, dz0 = nx * inward, nz * inward
        # shaft from 1.2 m behind the middle to 0.35 m short of the tip (no paint on paint), head strokes 0.06 apart
        o.box(x - dx0 * M(0.175), y, z - dz0 * M(0.175), M(0.25), 0.06, M(2.05), ux, uz, "PLN", check=False)
        hx, hz = x + dx0 * M(1.2), z + dz0 * M(1.2)
        for k in (-1, 1):
            ang = math.atan2(dz0, dx0) + k * math.radians(145)
            dx, dz = math.cos(ang), math.sin(ang)
            o.box(hx + dx * M(0.45), y + (0.0 if k < 0 else 0.07), hz + dz * M(0.45), M(0.9), 0.06, M(0.25), dx, dz, "PLN",
                  check=False)
        fx0, fz0 = P(au, n0)
        drive.append(dict(kind="entry" if s == 0 else "exit", at=[round(fx0, 2), round(fz0, 2)],
                          lonlat=[round(v, 6) for v in geo.lonlat(fx0, fz0)], width_m=6.0))
    o.stats["arrows"] += len(drive)
    return dict(id=st["id"], name=st.get("name"), top=top, pumps=[[round(v, 2) for v in p] for p in pumps],
                canopy=[round(ccx, 1), round(ccz, 1)], drive=drive)


def parking(o, pk, keep_off):
    g = Polygon(pk["poly"]).buffer(0).difference(keep_off)
    parts = [p for p in (g.geoms if g.geom_type == "MultiPolygon" else [g]) if p.area > M(6) * M(6)]
    n_bays = 0
    drawn = set()
    for poly in parts:
        poly = poly.simplify(0.5).buffer(0)
        if poly.geom_type != "Polygon":
            continue
        top = slab(o, poly, "PAS")
        (cx, cz), (ux, uz), hl, hw = frame_of(poly)
        fx, fz = -uz, ux
        bw, bd, aisle = M(2.5), M(5.0), M(6.0)
        inner = poly.buffer(-M(0.4))
        # rows of bays across the short axis: bay row, aisle, bay row ... (double rows back to back)
        v = -hw
        row = 0
        while v + bd <= hw + 1e-6:
            for a in np.arange(-hl, hl - bw + 1e-6, bw):
                q = Polygon([(cx + ux * a + fx * v, cz + uz * a + fz * v), (cx + ux * (a + bw) + fx * v, cz + uz * (a + bw) + fz * v),
                             (cx + ux * (a + bw) + fx * (v + bd), cz + uz * (a + bw) + fz * (v + bd)),
                             (cx + ux * a + fx * (v + bd), cz + uz * a + fz * (v + bd))])
                if not inner.contains(q):
                    continue
                # a bay = its two side lines (shared with the next bay: drawn once)
                for aa in (a, a + bw):
                    key = (round(aa, 2), round(v, 2), id(poly))
                    if key in drawn:
                        continue
                    drawn.add(key)
                    lx, lz = cx + ux * aa + fx * (v + bd / 2), cz + uz * aa + fz * (v + bd / 2)
                    o.box(lx, top + 0.08, lz, M(0.1), 0.06, bd, ux, uz, "PLN", check=False)
                n_bays += 1
            v += bd + (aisle if row % 2 == 0 else 0.0)
            row += 1
    o.stats["parking_bays"] += n_bays
    o.stats["parking_lots"] += 1
    return n_bays


def pitch(o, pt, keep_off):
    t = pt["tags"]
    g = Polygon(pt["poly"]).buffer(0)
    g2 = g.difference(keep_off)
    if g2.geom_type == "MultiPolygon":
        g2 = max(g2.geoms, key=lambda x: x.area)
    if g2.is_empty or g2.area < 0.6 * g.area:
        o.stats["pitch_blocked"] += 1
        return None
    sport = (t.get("sport") or "").split(";")[0]
    paved = t.get("surface") in ("concrete", "asphalt", "paved", "paving_stones", "tartan", "acrylic", "artificial_turf")
    (cx, cz), (ux, uz), hl, hw = frame_of(g2)
    fx, fz = -uz, ux
    court = sport in COURT_SPORTS or (paved and g2.area < M(40) * M(25))
    if court:
        # the court on the largest rectangle of the outline (inset 0.3 m)
        rect = Polygon([(cx + ux * a * (hl - M(0.3)) + fx * b * (hw - M(0.3)), cz + uz * a * (hl - M(0.3)) + fz * b * (hw - M(0.3)))
                        for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1))])
        if not g2.buffer(M(0.5)).contains(rect):
            rect = g2
        top = slab(o, rect, "PCG" if sport in ("tennis", "badminton") else "PCN")
        L, Wd = hl - M(1.0), hw - M(1.0)
        if L < M(4) or Wd < M(3):
            return dict(id=pt["id"], kind="court", sport=sport)
        lines_rect(o, cx, cz, ux, uz, L, Wd, top + 0.08)
        o.box(cx, top + 0.08, cz, M(0.1), 0.06, 2 * Wd - M(0.2), ux, uz, "PLN", check=False)  # half-way line
        if sport in ("basketball", "futsal", "multi", "") or sport not in ("tennis", "badminton", "volleyball",
                                                                              "sepak_takraw", "chinlone"):
            for s in (-1, 1):  # hoops: post 1.2 m behind the end line, board 3.05 m rim
                px, pz = cx + ux * s * (L + M(1.0)), cz + uz * s * (L + M(1.0))
                if not g2.buffer(M(1.5)).contains(Point(px, pz)):
                    px, pz = cx + ux * s * (L - M(0.3)), cz + uz * s * (L - M(0.3))
                o.box(px, top, pz, M(0.2), M(3.6), M(0.2), ux, uz, "PST", coll=True)
                bx, bz = px - ux * s * M(0.9), pz - uz * s * M(0.9)
                o.box(px - ux * s * M(0.45), top + M(3.2), pz - uz * s * M(0.45), M(0.9), M(0.12), M(0.12), ux, uz, "PST")
                o.box(bx, top + M(2.9), bz, M(0.06), M(1.05), M(1.8), ux, uz, "PCW")
                o.box(bx - ux * s * M(0.3), top + M(3.05), bz - uz * s * M(0.3), M(0.45), M(0.04), M(0.45), ux, uz, "PFR")
            o.stats["hoops"] += 2
        else:
            for s in (-1, 1):  # net posts at the half-way line, the net a thin dark sheet
                px, pz = cx + fx * s * (Wd + M(0.5)), cz + fz * s * (Wd + M(0.5))
                o.box(px, top, pz, M(0.12), M(2.4 if sport == "volleyball" else 1.1), M(0.12), ux, uz, "PST", coll=True)
            nh = M(1.0) if sport == "volleyball" else M(0.9)
            ny0 = top + (M(1.43) if sport == "volleyball" else M(0.07))
            o.box(cx, ny0, cz, 0.06, nh, 2 * Wd + M(0.8), ux, uz, "PPD")
            o.stats["nets"] += 1
        o.stats["courts"] += 1
        return dict(id=pt["id"], kind="court", sport=sport)
    # a grass / earth field: goals at the two ends (7.32 x 2.44 m full size, 5 x 2 m on small fields)
    big = hl > M(40)
    gw, gh = (M(7.32), M(2.44)) if big else (M(5.0), M(2.0))
    if hw < gw / 2 + M(1):
        return dict(id=pt["id"], kind="field", sport=sport)
    for s in (-1, 1):
        gx, gz = cx + ux * s * (hl - M(1.0)), cz + uz * s * (hl - M(1.0))
        gy = min(BK.ground(gx + fx * gw / 2, gz + fz * gw / 2)[0], BK.ground(gx - fx * gw / 2, gz - fz * gw / 2)[0]) - 0.3
        for k in (-1, 1):
            px, pz = gx + fx * k * gw / 2, gz + fz * k * gw / 2
            o.box(px, gy, pz, M(0.12), gh + 0.3, M(0.12), ux, uz, "PCW", coll=True)
        o.box(gx, gy + gh + 0.3, gz, M(0.12), M(0.12), gw + M(0.12), ux, uz, "PCW")
        o.stats["goals"] += 1
    o.stats["fields"] += 1
    return dict(id=pt["id"], kind="field", sport=sport)


def playground(o, pg, keep_off):
    g = Polygon(pg["poly"]).buffer(0).difference(keep_off)
    if g.geom_type == "MultiPolygon":
        g = max(g.geoms, key=lambda x: x.area)
    if g.is_empty or g.area < M(5) * M(5):
        o.stats["playground_blocked"] += 1
        return None
    (cx, cz), (ux, uz), hl, hw = frame_of(g)
    fx, fz = -uz, ux
    # sand pad on the largest rectangle that fits (at most 16 x 10 m)
    L, Wd = min(hl - M(0.5), M(8)), min(hw - M(0.5), M(5))
    if L < M(2.5) or Wd < M(2):
        return None
    rect = Polygon([(cx + ux * a * L + fx * b * Wd, cz + uz * a * L + fz * b * Wd) for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1))])
    top = slab(o, rect, "PSD", lift=0.15)
    # kerb round the pad
    k = M(0.2)
    for s in (-1, 1):
        o.box(cx + fx * s * (Wd + k / 2), top - 0.15, cz + fz * s * (Wd + k / 2), 2 * L + 2 * k, M(0.25), k, ux, uz, "PCN", coll=True)
        o.box(cx + ux * s * (L + k / 2), top - 0.15, cz + uz * s * (L + k / 2), k, M(0.25), 2 * Wd, ux, uz, "PCN", coll=True)
    # swing frame (2 seats) on one half: two A legs as posts, a top bar, seats on chains
    sx_ = cx - ux * L * 0.45
    sz_ = cz - uz * L * 0.45
    sw = min(M(3.4), 2 * Wd - M(1.0))
    for s in (-1, 1):
        o.box(sx_ + fx * s * sw / 2, top, sz_ + fz * s * sw / 2, M(0.1), M(2.4), M(0.1), ux, uz, "PFB", coll=True)
    o.box(sx_, top + M(2.4), sz_, M(0.1), M(0.1), sw + M(0.1), ux, uz, "PFB")
    for s in (-0.25, 0.25):
        px, pz = sx_ + fx * s * sw, sz_ + fz * s * sw
        for c in (-1, 1):
            o.box(px + fx * c * M(0.2), top + M(0.45), pz + fz * c * M(0.2), M(0.03), M(1.95), M(0.03), ux, uz, "PST", check=False)
        o.box(px, top + M(0.4), pz, M(0.25), M(0.05), M(0.5), ux, uz, "PFY")
    # climbing frame on the other half: a 1.8 m cube of bars
    cxk, czk = cx + ux * L * 0.45, cz + uz * L * 0.45
    h = M(1.8)
    for a in (-1, 1):
        for b in (-1, 1):
            o.box(cxk + ux * a * h / 2 + fx * b * h / 2, top, czk + uz * a * h / 2 + fz * b * h / 2, M(0.08), h, M(0.08), ux, uz,
                  "PFR", coll=True)
    for y in (M(0.6), M(1.2), h):
        for b in (-1, 1):
            o.box(cxk + fx * b * h / 2, top + y, czk + fz * b * h / 2, h - M(0.08), M(0.05), M(0.05), ux, uz, "PFY", check=False)
            o.box(cxk + ux * b * h / 2, top + y, czk + uz * b * h / 2, M(0.05), M(0.05), h - M(0.08), ux, uz, "PFY", check=False)
    o.stats["playgrounds"] += 1
    return dict(id=pg["id"])


def build():
    t0 = time.time()
    items = json.load(open(os.path.join(OUT, "plan.json"), encoding="utf-8"))
    plots = json.load(open(os.path.join(B1, "buildings_%s" % TAG, "plots.json")))
    bpolys = [Polygon(p["poly"]).buffer(0) for p in plots]
    corr, _ = BK.corridors()
    places = json.load(open(os.path.join(OUT, "places.json"), encoding="utf-8"))
    comp_rings = [LineString(c["poly"]) for c in places["compounds"]]
    keep_off = unary_union([corr.buffer(M(1.0))] + [b.buffer(M(0.6)) for b in bpolys] +
                           [r.buffer(M(0.6)) for r in comp_rings])
    # the landmark sites (Myanmar Centre, Sedona ...) and water stay clear
    zones = BK.landmark_zones({})
    if zones:
        keep_off = unary_union([keep_off] + list(zones.values()))
    o = Out()
    rng = random.Random(7)
    res = dict(fuel=[], parking=[], pitch=[], playground=[])
    for st in items["fuel"]:
        # plain colours only: the canopy fascia from the satellite roof / brand where known (Myawaddy: green, measured)
        st["colour"] = "PFG"
        lot_keep = unary_union([corr.buffer(M(1.0)), zones and unary_union(list(zones.values())) or Polygon()])
        res["fuel"].append(fuel_station(o, st, lot_keep, rng))
    for pk in items["parking"]:
        res["parking"].append(dict(id=pk["id"], bays=parking(o, pk, keep_off)))
    for pt in items["pitch"]:
        r = pitch(o, pt, keep_off)
        if r:
            res["pitch"].append(r)
    for pg in items["playground"]:
        r = playground(o, pg, keep_off)
        if r:
            res["playground"].append(r)
    # checks: nothing placed on a carriageway / pavement or in a building (footprints of every checked box)
    ctree = corr
    bad_road = sum(1 for (fpoly, _, _, _) in o.boxes if fpoly.intersects(corr))
    btree = STRtree(bpolys)
    bad_bld = sum(1 for (fpoly, _, _, _) in o.boxes if any(bpolys[j].intersection(fpoly).area > 0.05
                                                            for j in btree.query(fpoly, predicate="intersects")))
    o.stats["check_on_road"] = bad_road
    keep = unary_union(o.keep + [b[0] for b in o.boxes]).buffer(M(0.5))
    kl = [list(map(list, g.exterior.coords)) for g in (keep.geoms if keep.geom_type == "MultiPolygon" else [keep])]
    json.dump(kl, open(os.path.join(OUT, "keepout.json"), "w"))
    # what the current green / street layers have standing there (they are re-run with keepout.json)
    try:
        trees = json.load(open(os.path.join(B1, "green_%s" % TAG, "trees.json")))
        o.stats["trees_in_places_before"] = sum(1 for t in trees if keep.contains(Point(t[2], t[3])))
        its = json.load(open(os.path.join(B1, "street_%s" % TAG, "items.json")))["items"]
        o.stats["street_items_in_places_before"] = sum(1 for t in its if keep.contains(Point(t["x"], t["z"])))
    except Exception as e:
        print("layer check skipped", e)
    o.stats["check_in_building"] = bad_bld
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, "ygnplaces_%s.rbxmx" % TAG.lower())
    st = kit_pack.write_rbxmx(path, "Data_%sP" % TAG, o.detail, TILE)
    x = open(path, encoding="utf-8").read()
    x = x.replace("TILE=256\n", "TILE=256\nLOAD=%d\n" % LOAD, 1)
    open(path, "w", encoding="utf-8", newline="\n").write(x)
    o.stats.update({"pack_" + k: v for k, v in st.items()})
    json.dump(res, open(os.path.join(OUT, "built.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    json.dump([d for f in res["fuel"] for d in f["drive"]], open(os.path.join(OUT, "driveways.json"), "w"), indent=1)
    stats = dict(o.stats)
    stats["seconds"] = round(time.time() - t0, 1)
    json.dump(stats, open(os.path.join(OUT, "stats.json"), "w"), indent=1)
    flicker(o)
    preview(o, items)
    print(json.dumps(stats, indent=1))


def flicker(o):
    """same-facing faces of two placed boxes closer than 0.05 studs that overlap (tops / bottoms and sides)"""
    recs = [r for recs in o.detail.values() for r in recs if r[8] != "WCOL"]
    n = 0
    tops = defaultdict(list)
    for r in recs:
        _, x, y, z, sx, sy, sz, yaw, code = r
        c, s = math.cos(yaw), -math.sin(yaw)
        fx, fz = -s, c
        fp = Polygon([(x + c * a * sx / 2 + fx * b * sz / 2, z + s * a * sx / 2 + fz * b * sz / 2)
                      for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1))])
        tops[round((y + sy / 2) * 20)].append(fp)
        tops[round((y - sy / 2) * 20) + 100000].append(fp)
    for k, fps in tops.items():
        if len(fps) < 2:
            continue
        tr = STRtree(fps)
        for i, f in enumerate(fps):
            for j in tr.query(f, predicate="intersects"):
                if j > i and fps[j].intersection(f).area > 0.01:
                    n += 1
                    if n <= 8:
                        print("  flicker pair at", round(f.centroid.x, 1), round(f.centroid.y, 1), "plane", k)
    print("flicker: coplanar overlapping top / bottom face pairs: %d" % n)
    o.stats["flicker_pairs"] = n


def preview(o, items):
    from PIL import Image, ImageDraw
    allp = [b[0] for b in o.boxes]
    if not allp:
        return
    for name, fl in (("fuel", items["fuel"]),):
        pass
    x0, z0, x1, z1 = unary_union(allp).bounds
    sc = 2000.0 / max(x1 - x0, z1 - z0)
    im = Image.new("RGB", (int((x1 - x0) * sc) + 20, int((z1 - z0) * sc) + 20), (24, 24, 28))
    dr = ImageDraw.Draw(im)
    col = {"PCN": (190, 190, 180), "PAS": (90, 90, 95), "PLN": (255, 255, 255), "PFG": (40, 160, 80), "PCW": (240, 240, 240)}
    for fp, y0, y1, code in o.boxes:
        dr.polygon([((x - x0) * sc + 10, (z - z0) * sc + 10) for x, z in fp.exterior.coords], fill=col.get(code, (200, 120, 60)))
    im.save(os.path.join(OUT, "preview.png"))


if __name__ == "__main__":
    if MODE == "plan":
        plan()
    else:
        build()
