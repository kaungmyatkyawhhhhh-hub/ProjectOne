"""buildings_1to1.py <tag> (2026-11-16, rescale step 3.7): the ordinary buildings, compound walls and gates of a 1:1 pilot
district, from the real footprints, out of the reusable kit (kit_panels.py). Run with YANGON_SCALE=1to1.

    YANGON_SCALE=1to1 python buildings_1to1.py P1

Inputs
  build/footprints/ygn_footprints.json      OSM + Microsoft outlines (footprints.py), kind and floors
  build/city_1to1/roads_<tag>_profile.json  road centre lines with their carriageway offsets and pavements (roads.py)
  build/city_1to1/terrain_<tag>_state.npz   the terrain heights the skin was written from (terrain.py): base heights
  build/osm_ygn/{areas,lines,points}.json   land use (infill), OSM walls / fences / gates

What it does
  1. footprints inside the district, minus the road corridors (carriageway + pavement + 0.6 m), minus water, minus the
     landmark sites re-fitted on their own (Myanmar Centre / Melia, Sedona: LANDMARK_SITES, marked empty), duplicates out
  2. infill only in blocks with no real building at all where land use says homes / shops (footprint research rule)
  3. an archetype per building from kind, floors, size and the street it faces (street survey 1C / 1E)
  4. every wall cut into kit panels (k bays x full height, stretched <= 15%), party walls and short walls plain
  5. per 1536-stud cell: plain walls, flat roofs, hipped / gable roofs, compound walls, the night window panes
  6. compound walls round villa / house / civic / religious / condo lots (Voronoi lots per block), gates on the street side
  7. collision boxes per building (shells.collision) and per wall run

Outputs (build/city_1to1/buildings_<tag>/; .glb in imports/sync/ygn1to1_<tag>/ for Open Cloud)
  kit_<n>.glb      the panels and props used (one mesh per panel and class, named KWX|KGR|KAR _<pid>_<box>)
  cells_<n>.glb    the cell meshes (named <GROUP>_c<i>x<j>s<k>_<box>)
  Inst_<n>.txt     the detail, readable: "pid sx x y z yaw wall [sy sz]" / "B x y z sx sy sz yaw code" a line, "#i j"
                   starts a 256-stud tile (panel origin = its bottom-left corner on the wall plane)
  stats.json, preview.png

Light version (2026-11-16, "make P1 light enough for the whole city"): the place holds only the SHELL of each building
(its collision boxes, drawn in the wall colour: the far look and the collision in one) plus the pitched roofs and the
compound-wall collision. Everything else (facade panels, piers, party walls, flat roof slabs, roof props, drainpipes,
AC units, compound walls, gates) is DETAIL: packed per 256-stud tile into StringValues (ReplicatedStorage.YgnKit) and
made on each client near the camera by src/client/YangonKitStream.client.lua from the shared kit templates, which also
hides the shells of the tiles it has built (no z-fighting). Walls fit whole bays (stretch <= 15%) plus at most one
half-bay pier (no plain end strips); compound walls use 1 / 2 / 4 / 8-bay pieces and one collision box per straight
segment.
  Shell_<n>.txt    YangonKitPlace.shells lines: S (shell box), R (pitched roof), W (wall collision)
  ygnkit_<tag>.rbxmx  the packed detail (Folder Data_<tag>: StringValue Meta + one StringValue a tile)
"""
import json
import math
import os
import random
import sys
import time
import functools
print = functools.partial(print, flush=True)
import zlib
from collections import Counter, defaultdict

import numpy as np
import shapely
import shapely.prepared
from shapely.geometry import Polygon, Point, LineString, MultiLineString, box as sbox
from shapely.ops import unary_union
from shapely.strtree import STRtree

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import geo  # noqa: E402
from glb import Mesh, write_glb, check_glb, code  # noqa: E402
from landmark_glb3d import GROUPS, box_uv  # noqa: E402
from kit_panels import Kit, ARCH, K_SET, FH, S  # noqa: E402
from shells import collision  # noqa: E402
import kit_pack  # noqa: E402

assert geo.ONE_TO_ONE, "run with YANGON_SCALE=1to1"
TAG = sys.argv[1] if len(sys.argv) > 1 else "P1"
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
B1 = os.path.join(ROOT, "build", "city_1to1")
OUT = os.path.join(B1, "buildings_%s" % TAG)
GLB = os.path.join(ROOT, "imports", "sync", "ygn1to1_%s" % TAG.lower())
CELL = 1792.0   # (a MeshPart is at most 2,048 studs a side: buildings are put in a cell by their middle)
MAX_TRIS = 17000
FILE_MESHES = 90
CHARS = 180000
STRETCH = 0.15
TILE = 256.0    # detail tiles (studs): the client streamer builds whole tiles near the camera
M = geo.m

# landmark sites built on their own (re-fitted later): the lots stay empty. Points in lon / lat round the real site
# (OSM outlines Myanmar Plaza 421632377, Melia 463189671, Sedona 374512164 + the drives and gates of the site audit).
LANDMARK_SITES_BY_TAG = {}
LANDMARK_SITES_BY_TAG["P1"] = {
    "myanmar_centre": dict(osm=["o421632377", "o463189671"], pts=[(96.15439, 16.82723), (96.15476, 16.82866)], grow=22.0),
    # o452876267 = Sedona's Inya Wing tower: built by the Sedona refit (sedona3d.py at 1:1), not as a kit condo
    "sedona": dict(osm=["o374512164", "o452876267"], pts=[(96.154804, 16.830686), (96.154804, 16.830816), (96.156476, 16.830081),
                                            (96.154886, 16.829420), (96.155045, 16.829389), (96.154687, 16.829663)], grow=18.0),
}
# (2026-11-16, step 5) P2's catalogue landmarks (vault "Research - Yangon landmarks catalogue"): their lots stay empty for
# their own models. Kaba Aye: the OSM compound (area 186911800) and the placed model's 315-stud platform round the stupa.
LANDMARK_SITES_BY_TAG["P2"] = {
    "kaba_aye": dict(osm=[], areas=[186911800], pts=[], circles=[(96.15447, 16.85681, 52.5)], grow=6.0),
    "diamond_inya": dict(osm=["o522822395"], pts=[], grow=15.0),
    "inya_lake_hotel": dict(osm=["o1281765358", "o522822402"], pts=[], grow=15.0),
    "lotte_hotel": dict(osm=["o1525507325"], pts=[], grow=15.0),
}
LANDMARK_SITES = LANDMARK_SITES_BY_TAG.get(TAG, {})
# earlier pilots this one meets (geo.PILOT_SEAMS): their buildings by the shared edge are kept, never doubled, and no
# compound wall is drawn along the shared edge twice
SEAM_WITH = getattr(geo, "PILOT_SEAMS", {}).get(TAG, ())

# wall palettes (kit critique, measured: 55-85% neutral)
PAL = {
    "walkup": {"KW4": 0.35, "KWG": 0.25, "KW6": 0.15, "KW1": 0.12, "KW2": 0.08, "KW3": 0.05},
    "township": {"KW4": 0.35, "KWB": 0.20, "KW6": 0.20, "KWG": 0.15, "KW1": 0.10},
    "house": {"KW6": 0.40, "KW4": 0.18, "KWG": 0.18, "KW1": 0.14, "KWB": 0.10},
    "villa": {"KW6": 0.80, "KW1": 0.10, "KWG": 0.10},
    "condo": {"KW6": 0.6, "KWG": 0.4},
    "civic": {"KW6": 0.5, "KW1": 0.3, "KWG": 0.2},
    "shed": {"KW6": 0.35, "KWG": 0.4, "KW1": 0.25},
    "market": {"KW6": 0.4, "KWG": 0.4, "KW1": 0.2},
}
ROOFS = {  # pitched roof sheets (aerial: rust, blue, grey-zinc, red tile)
    "house": {"KRF": 0.45, "KRB": 0.2, "KRG": 0.2, "KRT": 0.15},
    "villa": {"KRT": 0.5, "KRF": 0.3, "KRB": 0.2},
    "shed": {"KRF": 0.6, "KRG": 0.4},
    "market": {"KRF": 0.6, "KRG": 0.4},
}
WALL_ARCH = {"villa": 10.0, "house": 4.0, "civic": 9.0, "condo": 8.0}  # compound lot reach round the building (m)
NIGHT_RGB = [(255, 236, 200), (255, 236, 200), (255, 220, 170), (220, 236, 255)]   # warm rooms, a few cool-white
ROOF_BOOST = 1.45   # the roof mesh is Metal + YgnCorrugatedZinc (a grey map, ~0.65): its vertex colours carry the sheet colour
MAIN = {"motorway", "trunk", "primary", "secondary", "tertiary", "motorway_link", "trunk_link", "primary_link",
        "secondary_link", "tertiary_link"}


def rng_for(*key):
    return random.Random(zlib.crc32(repr(key).encode()))


def wpick(r, table):
    ks = list(table)
    return r.choices(ks, [table[k] for k in ks])[0]


# ---------------------------------------------------------------------------------------------------------- inputs
def load_terrain():
    d = np.load(os.path.join(B1, "terrain_%s_state.npz" % TAG))
    return d["H"], d["code"], d["origin"]


H_, CODE_, ORG_ = load_terrain()


def ground(x, z):
    i = int((x - ORG_[0]) / 4.0)
    j = int((z - ORG_[1]) / 4.0)
    i = min(max(i, 0), H_.shape[0] - 1)
    j = min(max(j, 0), H_.shape[1] - 1)
    return float(H_[i, j]), int(CODE_[i, j])


def corridors():
    """the road corridors (carriageway + pavement + 0.6 m) as one shapely geometry, plus the road lines by class"""
    prof = json.load(open(os.path.join(B1, "roads_%s_profile.json" % TAG)))
    polys, lines = [], []
    for e in prof:
        P = np.array([[p[0], p[2]] for p in e["pts"]], float)
        if len(P) < 2:
            continue
        lo = -e["half"][0] - e["walk"] - M(0.6)
        hi = e["half"][1] + e["walk"] + M(0.6)
        D = np.diff(P, axis=0)
        L = np.hypot(D[:, 0], D[:, 1])
        ok = L > 1e-6
        for k in np.nonzero(ok)[0]:
            d = D[k] / L[k]
            R = np.array([-d[1], d[0]])
            a, b = P[k], P[k + 1]
            polys.append(Polygon([a + R * lo, b + R * lo, b + R * hi, a + R * hi]))
        for k in range(len(P)):
            polys.append(Point(P[k]).buffer(max(abs(lo), abs(hi)) * 0.98, 8))
        lines.append((LineString(P), e["hw"], (lo, hi), e))
    return unary_union(polys).buffer(0), lines


def landmark_zones(fp_by_id):
    zones = {}
    areas = None
    for name, s in LANDMARK_SITES.items():
        geoms = [Point(geo.world(*p)) for p in s["pts"]]
        for oid in s["osm"]:
            b = fp_by_id.get(oid)
            if b:
                geoms.append(Polygon(geo.proj(b["poly"])))
        if s.get("areas"):
            if areas is None:
                areas = {a["id"]: a for a in json.load(open(os.path.join(geo.OSM, "areas.json"), encoding="utf-8"))["areas"]}
            for aid in s["areas"]:
                a = areas.get(aid)
                if a:
                    geoms.append(Polygon(geo.proj(a["p"])).buffer(0))
        for lo, la, r_m in s.get("circles", ()):
            geoms.append(Point(geo.world(lo, la)).buffer(M(r_m), 32))
        zones[name] = unary_union(geoms).convex_hull.buffer(M(s["grow"]))
    # (step 5) the ordinary pagodas of build/pagodas/pagodas.json in this district (PagodaPlace puts them there): the stupa
    # and a clear ring round it
    pj = os.path.join(ROOT, "build", "pagodas", "pagodas.json")
    if TAG != "P1" and os.path.exists(pj):
        lo0, la0, lo1, la1 = geo.PILOT_LL[TAG]
        for pg in json.load(open(pj, encoding="utf-8"))["pagodas"]:
            if lo0 <= pg["lon"] <= lo1 and la0 <= pg["lat"] <= la1:
                zones["pagoda_" + pg["id"]] = Point(geo.world(pg["lon"], pg["lat"])).buffer(M(pg["w"] * 0.71 + 6.0), 24)
    return zones


# --------------------------------------------------------------------------------------------------- archetypes
def archetype(b, near_main):
    kind, f, area = b["kind"], int(b["floors"] or 2), b["area_m2"]
    if kind in ("mass",) or f >= 9:
        return ("condo", max(9, f)) if f >= 8 else ("civic", min(max(f, 3), 7))
    if kind == "walkup":
        return "walkup", min(max(f, 3), 8)
    if kind == "shophouse":
        return ("township", min(max(f, 2), 4)) if f <= 4 else ("walkup", min(f, 8))
    if kind == "villa":
        return "villa", min(max(f, 1), 3)
    if kind in ("school", "hospital", "civic"):
        return "civic", min(max(f, 2), 5)
    if kind == "religious":
        return "villa", 1
    if kind in ("shed",) or area < 30:
        return "shed", 1
    if kind == "hall":
        return "market", 1
    # houses: on a main road the township shops (street survey 1C: runs of shophouses along the township roads)
    if near_main and area < 260 and f >= 2:
        return "township", min(max(f, 2), 4)
    return "house", min(max(f, 1), 3)


def decompose(n):
    out = []
    for k in sorted(K_SET, reverse=True):
        while n >= k:
            out.append(k)
            n -= k
    return out


def fit_wall(L, bay):
    """(n full bays, stretch s, pier stretch ps or 0) for a wall of length L: whole bays stretched <= 15%, else whole
    bays plus one half-bay pier at the wall's end (pier stretch 0.3-1.6: it has no openings); None = too short"""
    best = None
    n0 = int(L / bay)
    for n in range(max(1, n0 - 1), n0 + 3):
        s = L / (n * bay)
        if abs(s - 1) <= STRETCH:
            c = abs(s - 1)
            if best is None or c < best[0]:
                best = (c, n, s, 0.0)
        s = min(max((L - 0.5 * bay) / (n * bay), 1 - STRETCH), 1 + STRETCH)
        pw = L - n * bay * s
        ps = pw / (0.5 * bay)
        if 0.3 <= ps <= 1.6:
            c = abs(s - 1) + 0.3 * abs(ps - 1) + 0.05
            if best is None or c < best[0]:
                best = (c, n, s, ps)
    return best[1:] if best else None


def tile_of(x, z):
    return (math.floor(x / TILE), math.floor(z / TILE))


# ------------------------------------------------------------------------------------------------------ geometry
class Cells:
    """per-cell meshes by group (world studs)"""

    def __init__(self):
        self.m = defaultdict(Mesh)   # (cell, group) -> Mesh

    def cell(self, x, z):
        return (math.floor(x / CELL), math.floor(z / CELL))

    def tri(self, cell, grp, a, b, c, rgb):
        self.m[(cell, grp)].tri(a, b, c, *box_uv([a, b, c]), rgb)

    def quad(self, cell, grp, a, b, c, d, rgb):
        self.tri(cell, grp, a, b, c, rgb)
        self.tri(cell, grp, a, c, d, rgb)

    def wall(self, cell, grp, p, q, y0, y1, rgb):
        """a vertical quad over the segment p -> q (x, z) that shows to the right of p -> q seen from above in (x, z)
        math orientation (outward of a CCW ring)"""
        a, b = (p[0], y0, p[1]), (q[0], y0, q[1])
        c, d = (q[0], y1, q[1]), (p[0], y1, p[1])
        # glb winding: counter-clockwise seen from the side that shows. With x right and z down-the-page, a CCW ring in
        # (x, z) has its outside to the right of each edge: a, b, c, d is then clockwise from outside -> flip
        self.quad(cell, grp, a, d, c, b, rgb)

    def cap(self, cell, grp, poly, y, rgb, down=False):
        P = poly.buffer(0)
        geoms = [P] if P.geom_type == "Polygon" else list(getattr(P, "geoms", []))
        for G in geoms:
            if G.is_empty or G.area < 0.01:
                continue
            for t in shapely.constrained_delaunay_triangles(G).geoms:
                c = list(t.exterior.coords)[:3]
                A = [(c[k][0], y, c[k][1]) for k in range(3)]
                # facing up: normal (b - a) x (c - a) must have +y
                n = (A[1][2] - A[0][2]) * (A[2][0] - A[0][0]) - (A[1][0] - A[0][0]) * (A[2][2] - A[0][2])
                if (n > 0) == down:
                    A = [A[0], A[2], A[1]]
                self.tri(cell, grp, A[0], A[1], A[2], rgb)


def face_up(a, b, c):
    n = ((b[1] - a[1]) * (c[2] - a[2]) - (b[2] - a[2]) * (c[1] - a[1]),
         (b[2] - a[2]) * (c[0] - a[0]) - (b[0] - a[0]) * (c[2] - a[2]),
         (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]))
    return n


def oriented(cells, cell, grp, pts, want, rgb):
    """a convex polygon (3D) facing roughly `want`"""
    n = face_up(pts[0], pts[1], pts[2])
    if n[0] * want[0] + n[1] * want[1] + n[2] * want[2] < 0:
        pts = pts[::-1]
    for i in range(1, len(pts) - 1):
        cells.tri(cell, grp, pts[0], pts[i], pts[i + 1], rgb)


def hip_roof(cells, cell, grp, poly, y, eave, slope, rgb, gable=False):
    rect = poly.minimum_rotated_rectangle
    c4 = list(rect.exterior.coords)[:4]
    s1 = (c4[1][0] - c4[0][0], c4[1][1] - c4[0][1])
    s2 = (c4[2][0] - c4[1][0], c4[2][1] - c4[1][1])
    l1, l2 = math.hypot(*s1), math.hypot(*s2)
    e1 = (s1[0] / l1, s1[1] / l1) if l1 >= l2 else (s2[0] / l2, s2[1] / l2)
    hl, hw = max(l1, l2) / 2 + eave, min(l1, l2) / 2 + eave
    e2 = (-e1[1], e1[0])
    cx = sum(p[0] for p in c4) / 4
    cz = sum(p[1] for p in c4) / 4
    rise = hw * slope
    P = lambda s, t, yy: (cx + e1[0] * s + e2[0] * t, yy, cz + e1[1] * s + e2[1] * t)
    r = 0.0 if gable else max(0.0, hl - hw)
    if not gable:
        r = hl - hw
    A, Bq, C, D = P(-hl, -hw, y), P(hl, -hw, y), P(hl, hw, y), P(-hl, hw, y)
    top = y + rise
    R0, R1 = (P(-r, 0, top), P(r, 0, top)) if not gable else (P(-hl, 0, top), P(hl, 0, top))
    up = lambda t: (e2[0] * t, 1.0, e2[1] * t)
    oriented(cells, cell, grp, [A, Bq, R1, R0], (-e2[0], 1.0, -e2[1]), rgb)
    oriented(cells, cell, grp, [C, D, R0, R1], (e2[0], 1.0, e2[1]), rgb)
    if not gable:
        oriented(cells, cell, grp, [Bq, C, R1], (e1[0], 1.0, e1[1]), rgb)
        oriented(cells, cell, grp, [D, A, R0], (-e1[0], 1.0, -e1[1]), rgb)
    # the soffit (seen from the street under the eaves)
    oriented(cells, cell, grp, [A, Bq, C, D], (0, -1, 0), tuple(v * 0.6 for v in rgb))
    return rise, (cx, cz, e1, hl - eave, hw - eave)


def gable_ends(cells, cell, info, y, rise, rgb):
    cx, cz, e1, hl, hw = info
    e2 = (-e1[1], e1[0])
    for sgn in (-1, 1):
        p = lambda t, yy: (cx + e1[0] * hl * sgn + e2[0] * t, yy, cz + e1[1] * hl * sgn + e2[1] * t)
        tri = [p(-hw, y), p(hw, y), p(0, y + rise * hw / (hw + M(0.6)))]
        oriented(cells, cell, "KW6", tri, (e1[0] * sgn, 0, e1[1] * sgn), rgb)


def wall_box(p, q, y0, y1, code, k=0):
    """a plain wall (party walls, short walls, the ends a panel run leaves) as a Part line: the outer face on p -> q
    (outward on the right of p -> q in (x, z))"""
    L = math.hypot(q[0] - p[0], q[1] - p[1])
    ux, uz = (q[0] - p[0]) / L, (q[1] - p[1]) / L
    nx, nz = uz, -ux
    # a thin sheet (0.02 studs): a thick Part's end face lay in the next wall's plane at every corner (flicker)
    cx, cz = (p[0] + q[0]) / 2 - nx * 0.01, (p[1] + q[1]) / 2 - nz * 0.01
    y1 -= 0.06 * k
    return ("B", cx, (y0 + y1) / 2, cz, L, y1 - y0, 0.02, math.atan2(-uz, ux), code)


def parity(i, n):
    """0 / 1 / 2 for edge i of n: neighbours always differ (an odd ring's last edge gets 2)"""
    return 2 if (n % 2 == 1 and i == n - 1) else i % 2


def rect_of(g):
    rect = g.minimum_rotated_rectangle
    c4 = list(rect.exterior.coords)[:4]
    s1 = (c4[1][0] - c4[0][0], c4[1][1] - c4[0][1])
    s2 = (c4[2][0] - c4[1][0], c4[2][1] - c4[1][1])
    l1, l2 = math.hypot(*s1), math.hypot(*s2)
    e1 = (s1[0] / l1, s1[1] / l1) if l1 >= l2 else (s2[0] / l2, s2[1] / l2)
    cx = sum(p[0] for p in c4) / 4
    cz = sum(p[1] for p in c4) / 4
    return cx, cz, e1, max(l1, l2) / 2, min(l1, l2) / 2


def roof_rects(g, cellm=M(1.0)):
    """a flat roof as Part rectangles inside the outline: a 1 m raster in the outline's rectangle frame, rows cut into
    runs, equal runs of neighbouring rows merged (cells whose middle is inside; the parapet hides the steps)"""
    cx, cz, e1, hl, hw = rect_of(g)
    e2 = (-e1[1], e1[0])
    yw = math.atan2(-e1[1], e1[0])
    if g.area > 0.97 * g.minimum_rotated_rectangle.area:
        return [(cx, cz, 2 * hl, 2 * hw, yw)]
    nu, nv = max(1, int(math.ceil(2 * hl / cellm))), max(1, int(math.ceil(2 * hw / cellm)))
    du, dv = 2 * hl / nu, 2 * hw / nv
    gp = shapely.prepared.prep(g)
    rows = []
    for j in range(nv):
        v = -hw + (j + 0.5) * dv
        runs, start = [], None
        for i in range(nu + 1):
            inside = False
            if i < nu:
                uu = -hl + (i + 0.5) * du
                inside = gp.contains(Point(cx + e1[0] * uu + e2[0] * v, cz + e1[1] * uu + e2[1] * v))
            if inside and start is None:
                start = i
            elif not inside and start is not None:
                runs.append((start, i))
                start = None
        rows.append(runs)
    out, open_ = [], {}
    for j, runs in enumerate(rows + [[]]):
        nxt = {}
        for rr in runs:
            nxt[rr] = open_.pop(rr) if rr in open_ else j
        for rr, j0 in open_.items():
            out.append((rr, j0, j))
        open_ = nxt
    res = []
    for (i0, i1), j0, j1 in out:
        uu = -hl + (i0 + i1) / 2 * du
        v = -hw + (j0 + j1) / 2 * dv
        res.append((cx + e1[0] * uu + e2[0] * v, cz + e1[1] * uu + e2[1] * v, (i1 - i0) * du, (j1 - j0) * dv, yw))
    return res


# ---------------------------------------------------------------------------------------------------------- main
def main():
    t0 = time.time()
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(GLB, exist_ok=True)
    for f in os.listdir(GLB):
        if f.endswith(".glb"):
            os.remove(os.path.join(GLB, f))
    district = geo.batch_poly(TAG)
    dist_ll = geo.PILOT_LL[TAG]
    fp = json.load(open(os.path.join(ROOT, "build", "footprints", "ygn_footprints.json"), encoding="utf-8"))["buildings"]
    lo0, la0, lo1, la1 = dist_ll
    cand = [b for b in fp if lo0 - 0.001 <= b["poly"][0][0] <= lo1 + 0.001 and la0 - 0.001 <= b["poly"][0][1] <= la1 + 0.001]
    by_id = {b["id"]: b for b in cand}
    corr, road_lines = corridors()
    print("corridors ready %.1f s" % (time.time() - t0))
    zones = landmark_zones(by_id)
    stats = Counter()
    edge_in = district.buffer(-M(3))
    blds = []
    for b in cand:
        g = Polygon(geo.proj(b["poly"])).buffer(0)
        if g.is_empty or not edge_in.contains(g.centroid):
            continue
        stats["footprints"] += 1
        if any(z.intersects(g.centroid) or z.intersection(g).area > 0.3 * g.area for z in zones.values()):
            stats["dropped_landmark_site"] += 1
            continue
        a0 = g.area
        g2 = g.difference(corr)
        if g2.geom_type == "MultiPolygon":
            g2 = max(g2.geoms, key=lambda q: q.area)
        if g2.is_empty or g2.area < 0.45 * a0 or g2.area < M(4) * M(4):
            stats["dropped_road"] += 1
            continue
        if g2.area < 0.97 * a0:
            stats["clipped_road"] += 1
        g2 = g2.simplify(M(0.4), preserve_topology=True).buffer(0)
        if g2.geom_type != "Polygon" or g2.area < M(3) * M(3):
            stats["dropped_small"] += 1
            continue
        gy, gc = ground(g2.centroid.x, g2.centroid.y)
        if gc == 4:
            stats["dropped_water"] += 1
            continue
        blds.append(dict(id=b["id"], src=b["src"], kind=b["kind"], floors=b["floors"], area_m2=g2.area / (S * S),
                         g=g2, name=b.get("name")))
    # duplicates (OSM keeps old and new ways; MS and OSM overlaps that the merge left)
    blds.sort(key=lambda q: -q["g"].area)
    kept, kp = [], []
    for q in blds:
        hit = False
        if kp:
            tree = STRtree(kp)
            for j in tree.query(q["g"], predicate="intersects"):
                if q["g"].intersection(kp[j]).area > 0.3 * q["g"].area:
                    hit = True
                    break
        if hit:
            stats["dropped_overlap"] += 1
            continue
        # a smaller building nicked by a kept one: cut it out
        kept.append(q)
        kp.append(q["g"])
    blds = kept
    # (step 5) the earlier pilots' buildings standing over the shared edge (their centroid on their side): never built twice,
    # a building of ours they overlap is dropped (> 30 %) or cut clear of them
    seam_polys = []
    for u in SEAM_WITH:
        pp = os.path.join(B1, "buildings_%s" % u, "plots.json")
        if not os.path.exists(pp):
            continue
        near_edge = geo.batch_poly(u).boundary.intersection(district.boundary).buffer(M(60))
        seen = set()
        for r_ in json.load(open(pp)):
            seen.add(r_["id"])
            g_ = Polygon(r_["poly"]).buffer(0)
            if g_.intersects(near_edge):
                seam_polys.append(g_.buffer(M(1.0)))
        n0 = len(blds)
        blds = [q for q in blds if q["id"] not in seen]
        stats["dropped_built_in_" + u] += n0 - len(blds)
    if seam_polys:
        stree = STRtree(seam_polys)
        out_ = []
        for q in blds:
            g = q["g"]
            for j in stree.query(g, predicate="intersects"):
                if g.intersection(seam_polys[j]).area > 0.3 * q["g"].area:
                    g = None
                    break
                g = g.difference(seam_polys[j])
                if g.geom_type == "MultiPolygon":
                    g = max(g.geoms, key=lambda x: x.area)
            if g is None or g.is_empty or g.geom_type != "Polygon" or g.area < M(3) * M(3):
                stats["dropped_seam_overlap"] += 1
                continue
            q["g"] = g.buffer(0)
            out_.append(q)
        blds = out_
    # remove the small overlaps that remain (they would z-fight)
    tree = STRtree([q["g"] for q in blds])
    for i, q in enumerate(blds):
        for j in tree.query(q["g"], predicate="intersects"):
            if j < i:
                d = q["g"].difference(blds[j]["g"].buffer(M(0.05)))
                if d.geom_type == "MultiPolygon":
                    d = max(d.geoms, key=lambda x: x.area)
                if d.geom_type == "Polygon" and d.area > 0.6 * q["g"].area:
                    q["g"] = d.simplify(0.2).buffer(0)
                else:
                    q["drop"] = True
    stats["dropped_overlap"] += sum(1 for q in blds if q.get("drop"))
    blds = [q for q in blds if not q.get("drop")]
    print("buildings %d  %s  %.1f s" % (len(blds), dict(stats), time.time() - t0))

    # ----------------------------------------------------------------------------------- infill (real data missing)
    areas = json.load(open(os.path.join(geo.OSM, "areas.json"), encoding="utf-8"))["areas"]
    built_lu, open_lu = [], []
    for a in areas:
        t = a["t"]
        lu = t.get("landuse") or t.get("leisure") or t.get("natural") or t.get("amenity")
        if not lu or len(a["p"]) < 4:
            continue
        try:
            ap = Polygon(geo.proj(a["p"])).buffer(0)
        except Exception:
            continue
        if not ap.intersects(district):
            continue
        if lu in ("residential", "commercial", "retail"):
            built_lu.append(ap)
        elif lu in ("park", "grass", "pitch", "water", "wetland", "forest", "wood", "cemetery", "recreation_ground",
                    "garden", "golf_course", "construction", "parking", "swimming_pool", "track", "playground"):
            open_lu.append(ap)
    built_u = unary_union(built_lu) if built_lu else Polygon()
    open_u = unary_union(open_lu) if open_lu else Polygon()
    blocks = district.difference(corr.buffer(M(0.5)))
    blocks = [p for p in (blocks.geoms if blocks.geom_type == "MultiPolygon" else [blocks]) if p.area > M(10) * M(10)]
    btree = STRtree([q["g"] for q in blds])
    infill_block = unary_union(list(zones.values()) + seam_polys) if (zones or seam_polys) else Polygon()
    infill = 0
    for bl in blocks:
        if bl.area < M(40) * M(40):
            continue
        cx, cz = bl.representative_point().x, bl.representative_point().y
        if ground(cx, cz)[1] == 4 or not built_u.intersects(bl) or built_u.intersection(bl).area < 0.5 * bl.area:
            continue
        if len(btree.query(bl, predicate="intersects")):
            continue
        # no real building at all in a home / shop block: houses 10 x 12 m on a grid, 4 m apart, off the open land
        r = rng_for("infill", round(cx), round(cz))
        x0, z0, x1, z1 = bl.bounds
        for gx in np.arange(x0 + M(4), x1 - M(10), M(14)):
            for gz in np.arange(z0 + M(4), z1 - M(12), M(16)):
                hb = sbox(gx, gz, gx + M(10), gz + M(12))
                if bl.buffer(-M(2)).contains(hb) and not open_u.intersects(hb) and not infill_block.intersects(hb):
                    blds.append(dict(id="i%d" % infill, src="infill", kind="house", floors=r.choice([1, 2, 2, 3]),
                                     area_m2=120.0, g=hb, name=None))
                    infill += 1
    stats["infill"] = infill
    print("infill %d" % infill)

    # ------------------------------------------------------------------------------- per building: kit + cell meshes
    kit = Kit()
    cells = Cells()
    detail = defaultdict(list)  # tile -> detail records (client-made near the camera)
    shell = []                  # server records: S shell boxes, R pitched roofs, W wall collision
    allg = [q["g"] for q in blds]
    gtree = STRtree(allg)
    main_lines = [l[0] for l in road_lines if l[1] in MAIN]
    main_u = unary_union(main_lines) if main_lines else LineString()
    arch_n, floor_n = Counter(), Counter()
    panes_lit = 0
    # shell inset levels: touching neighbours never share one, so two shells' faces never lie in one plane
    # (neighbours = buildings whose collision boxes overlap or nearly touch: the boxes' rectangles can stand past the
    # outline by several studs)
    def box_poly(bb):
        x, _, z, sxb, _, szb, yw = bb
        c, s_ = math.cos(yw), math.sin(yw)
        return Polygon([(x + c * u + s_ * v, z - s_ * u + c * v) for u, v in
                        ((-sxb / 2, -szb / 2), (sxb / 2, -szb / 2), (sxb / 2, szb / 2), (-sxb / 2, szb / 2))])
    bpolys = [unary_union([box_poly(bb) for bb in collision(q["g"], 0.0, 1.0)]).buffer(0.5) for q in blds]
    btree2 = STRtree(bpolys)
    level = {}
    for bi in range(len(blds)):
        used = {level[j] for j in btree2.query(bpolys[bi], predicate="intersects") if j in level and j != bi}
        level[bi] = next(k for k in range(64) if k not in used)
    stats["shell_levels"] = max(level.values()) + 1

    def stack_of(arch, role, floors, kk, var, shop, stripe, base):
        if arch == "condo":
            vv, st = (0, False) if kk == 0 else (var, stripe)
            out = [(kit.panel("condo", role, 2, kk, vv, stripe=st), base)]
            y = base + (ARCH["condo"]["gf"] + FH) * S
            left = floors - 2
            for nf in (8, 4, 2, 1):
                while left >= nf:
                    out.append((kit.panel("condo_band", role, nf, kk, vv, stripe=st), y))
                    y += nf * FH * S
                    left -= nf
            out.append((kit.panel("condo_top", role, 0, kk, vv, stripe=st), y))
            return out
        if kk == 0:
            return [(kit.panel(arch, role, floors, 0, 0), base)]
        return [(kit.panel(arch, role, floors, kk, var, shop=shop, stripe=stripe), base)]

    roof_polys = []   # (index in shell, the roof's plan rectangle with its eaves)
    for bi, q in enumerate(blds):
        g = q["g"]
        r = rng_for(q["id"])
        near_main = g.distance(main_u) < M(28) + M(12)
        arch, floors = archetype(q, near_main)
        q["arch"], q["floors_b"] = arch, floors
        arch_n[arch] += 1
        floor_n[floors] += 1
        base_arch = "shed" if arch == "market" else arch
        bay = ARCH[base_arch]["bay"] * S
        Hs = (ARCH[base_arch]["gf"] + FH * (floors - 1)) * S
        par = ARCH[base_arch]["par"] * S
        wallc = wpick(r, PAL[arch])
        q["wall"] = wallc
        # base: the lowest ground under the outline
        ring = list(g.exterior.coords)[:-1]
        ys = [ground(x, z)[0] for x, z in ring] + [ground(g.centroid.x, g.centroid.y)[0]]
        base = min(ys)
        q["base"] = base
        cell = cells.cell(g.centroid.x, g.centroid.y)
        tile = tile_of(g.centroid.x, g.centroid.y)
        q["tile"] = tile
        D = detail[tile]
        ccw_ring = ring if Polygon(ring).exterior.is_ccw else ring[::-1]
        # NB shapely's is_ccw is in (x, z) math orientation; outward of edge (dx, dz) is (dz, -dx)
        lit_share = 0.22
        n_edges = len(ccw_ring)
        fronts = []
        top = base + Hs + (par if par > 0 else 0)
        for ei in range(n_edges):
            A = ccw_ring[ei]
            Bp = ccw_ring[(ei + 1) % n_edges]
            dx, dz = Bp[0] - A[0], Bp[1] - A[1]
            L = math.hypot(dx, dz)
            if L < 0.3:
                continue
            nx, nz = dz / L, -dx / L
            mid = ((A[0] + Bp[0]) / 2, (A[1] + Bp[1]) / 2)
            probe = Point(mid[0] + nx * M(1.2), mid[1] + nz * M(1.2))
            party = False
            for j in gtree.query(probe, predicate="intersects"):
                if j != bi:
                    party = True
                    break
            fit = None if (party or L < 0.85 * bay) else fit_wall(L, bay)
            if fit is None:
                D.append(wall_box(A, Bp, base - 1.0, top, wallc, parity(ei, n_edges)))
                stats["plain_walls"] += 1
                continue
            n, s, ps = fit
            # street side? a ray out of the wall meets a road corridor within 30 m
            ray = LineString([(mid[0] + nx * 0.5, mid[1] + nz * 0.5), (mid[0] + nx * M(30), mid[1] + nz * M(30))])
            front = ray.intersects(corr)
            role = "front" if front else "side"
            shop = front and arch in ("walkup", "township") and (arch == "township" or LineString(
                [(mid[0] + nx * 0.5, mid[1] + nz * 0.5), (mid[0] + nx * M(12), mid[1] + nz * M(12))]).intersects(corr))
            ax, az = nz, -nx  # along = up x outward: runs from B to A
            yaw = math.atan2(nx, nz)
            if front:
                fronts.append(dict(L=L, B=Bp, ax=ax, az=az, nx=nx, nz=nz, yaw=yaw, s=s, n=n, ps=ps))
            u = 0.0
            var = (zlib.crc32(("%s%d" % (q["id"], ei)).encode()) % 2) if (role == "front" and arch in ("walkup", "township")) else 0
            stripe_done = False
            pieces = decompose(n) + ([0] if ps > 0 else [])
            for kk in pieces:
                stripe = False
                if arch == "condo" and role == "front" and not stripe_done and kk == 1:
                    stripe, stripe_done = True, True
                sx = ps if kk == 0 else s
                ox, oz = Bp[0] + ax * u, Bp[1] + az * u
                for pid, py in stack_of(arch, role, floors, kk, var, shop, stripe, base):
                    D.append(("P", pid, ox, py, oz, yaw, sx, wallc))
                    stats["piers" if kk == 0 else "panels"] += 1
                    # night panes: about 22% of the windows lit
                    for pane in kit.data[pid]["panes"]:
                        if r.random() < lit_share:
                            wp = []
                            for (X, Y, Z) in pane:
                                X *= sx
                                wp.append((ox + ax * X + nx * (Z + 0.1), py + Y, oz + az * X + nz * (Z + 0.1)))
                            oriented(cells, cell, "NWH", wp, (nx, 0, nz), r.choice(NIGHT_RGB))
                            panes_lit += 1
                u += (0.5 * bay * ps) if kk == 0 else kk * bay * s
        # one drainpipe and one or two AC units a building, on its longest street face (brief 16 Nov: not one a panel)
        if fronts and arch in ("walkup", "township", "house", "villa") and floors >= 2:
            e = max(fronts, key=lambda f: f["L"])
            gf = ARCH[base_arch]["gf"]
            if arch in ("walkup", "township"):
                u = e["L"] - M(0.07)
                y0, y1 = base + M(gf - 0.3), top - M(0.1)
                D.append(("Q", kit.prop("pipe"), e["B"][0] + e["ax"] * u, y0, e["B"][1] + e["az"] * u, e["yaw"], 1.0,
                          wallc, (y1 - y0) / M(3.0), 1.0))
                stats["pipes"] += 1
            n_ac = 2 if (arch == "walkup" and floors >= 4) else 1
            spots = [(b, f) for b in range(e["n"]) for f in range(1, floors)
                     if (b * bay + M(0.16)) * e["s"] + M(0.8) < e["L"] - M(0.15)]
            r.shuffle(spots)
            for b, f in spots[:n_ac]:
                u = (b * bay + M(0.16)) * e["s"]
                yy = base + M(gf + FH * (f - 1) + 0.17)
                D.append(("P", kit.prop("ac"), e["B"][0] + e["ax"] * u, yy, e["B"][1] + e["az"] * u, e["yaw"], 1.0, wallc))
                stats["ac_units"] += 1
        # roofs
        top_y = base + Hs
        fill = g.area / g.minimum_rotated_rectangle.area
        # (light pass) pitched only on near-rectangular outlines: on notched outlines the roof's rectangle stood far
        # past the walls (the "huge eaves" on wide villas); eaves and rise capped on wide buildings
        pitched = arch in ("house", "villa", "shed", "market") and fill > 0.88 and g.area < M(45) * M(45)
        lv = level[bi]
        if pitched:
            rg = wpick(r, ROOFS[arch])
            gable = arch in ("shed", "market")
            slope = 0.5 if arch == "villa" else (0.38 if gable else 0.45)
            eave = M(0.75) if arch == "villa" else M(0.6)
            cx, cz, e1, hl, hw = rect_of(g)
            rise = min((hw + eave) * slope, M(3.2) if arch == "villa" else M(2.8))
            pid = kit.prop("gable" if gable else "hip")
            # the reference roof: 10 x 6 m on plan (eaves included), 3 m rise, centred, base at 0
            sx, sz, sy = 2 * (hl + eave) / M(10), 2 * (hw + eave) / M(6), rise / M(3)
            e2_ = (-e1[1], e1[0])
            roof_polys.append((len(shell), Polygon([(cx + e1[0] * a_ * (hl + eave) + e2_[0] * b_ * (hw + eave),
                                                     cz + e1[1] * a_ * (hl + eave) + e2_[1] * b_ * (hw + eave))
                                                    for a_, b_ in ((-1, -1), (1, -1), (1, 1), (-1, 1))])))
            shell.append(("R", pid, sx, cx, top_y, cz, math.atan2(-e1[1], e1[0]), wallc, sy, sz, rg))
            stats["roof_" + rg] += 1
            shell_top = top_y - 0.1 - 0.25 * lv
        else:
            gi = g.buffer(-0.75, join_style=2)
            if gi.geom_type == "MultiPolygon":
                gi = max(gi.geoms, key=lambda x: x.area)
            for (cx, cz, sx, sz, yw) in (roof_rects(gi) if gi.geom_type == "Polygon" and not gi.is_empty else []):
                D.append(("B", cx, top_y + 0.15 - 0.4, cz, sx, 0.8, sz, yw, "KCO"))
                stats["roof_parts"] += 1
            stats["roof_flat"] += 1
            shell_top = top_y + par - 0.1 - 0.25 * lv
            # roof props on flat roofs: tanks, dishes, a stair room
            if arch in ("walkup", "township", "civic", "condo") and g.area > M(5) * M(5):
                inner = g.buffer(-M(2.5))
                if not inner.is_empty:
                    rp = inner.representative_point()
                    e = list(g.minimum_rotated_rectangle.exterior.coords)
                    ya = math.atan2(e[1][1] - e[0][1], e[1][0] - e[0][0])
                    for name, off in (("tanks", (0, 0)), ("dish", (M(4), M(1))), ("stair", (-M(4), M(2)))):
                        if name == "dish" and (arch not in ("walkup", "condo") or r.random() < 0.4):
                            continue
                        if name == "stair" and arch not in ("walkup", "condo", "civic"):
                            continue
                        px = rp.x + off[0] * math.cos(ya) - off[1] * math.sin(ya)
                        pz = rp.y + off[0] * math.sin(ya) + off[1] * math.cos(ya)
                        if not inner.contains(Point(px, pz)):
                            continue
                        D.append(("P", kit.prop(name), px, top_y + 0.15, pz, -ya, 1.0, wallc))
                        stats["props"] += 1
        # the shell: the collision boxes drawn in the wall colour, a little inside the walls (inset and top by level:
        # touching shells never share a plane)
        # (each box of one building steps 0.05 down and in too: the boxes of an L / U building overlap a little and their
        # tops and sides must not share a plane either)
        boxes = collision(g, base - 1.0, shell_top)
        for k, bb in enumerate(boxes):
            x, y, z, sxb, syb, szb, yw = bb
            ins = 0.2 + 0.25 * lv + 0.08 * k
            syk = syb - 0.08 * k
            shell.append(("S", "%d_%d" % tile, x, y - 0.04 * k, z, max(1.0, sxb - 2 * ins), syk, max(1.0, szb - 2 * ins), yw,
                          wallc, 0 if pitched else 1))
        stats["shell_boxes"] += len(boxes)
    # roofs whose eaves overlap a neighbour's: each a little lower (0.08 studs a step, at least 0.06 from every
    # overlapping neighbour's final height), so two soffits / eave sheets
    # never lie in one plane (the walls' tops end inside the roof)
    rtree = STRtree([pg for _, pg in roof_polys])
    rlev = {}
    for k, (si, pg) in enumerate(roof_polys):
        ys = [shell[roof_polys[j][0]][4] for j in rtree.query(pg.buffer(0.3), predicate="intersects") if j in rlev and j != k]
        y0 = shell[si][4]
        v = next(v for v in range(64) if all(abs(y0 - 0.08 * v - yy) >= 0.06 for yy in ys))
        rlev[k] = v
        if v:
            rec = list(shell[si])
            rec[4] = y0 - 0.08 * v
            shell[si] = tuple(rec)
    stats["roof_levels"] = (max(rlev.values()) + 1) if rlev else 0
    print("kit panels %d, piers %d (%d unique)  %.1f s" % (stats["panels"], stats["piers"], len(kit.data), time.time() - t0))

    # ------------------------------------------------------------------------------------ compound walls and gates
    walled = [q for q in blds if q["arch"] in WALL_ARCH or q["kind"] in ("religious", "school", "hospital")]
    pts = shapely.MultiPoint([q["g"].representative_point() for q in blds])
    vor = shapely.voronoi_polygons(pts, extend_to=district.buffer(M(50)))
    vcells = list(vor.geoms)
    vtree = STRtree(vcells)
    blocks_u = unary_union(blocks)
    lots = []
    for q in walled:
        rp = q["g"].representative_point()
        cand_v = [vcells[j] for j in vtree.query(rp, predicate="intersects")]
        if not cand_v:
            continue
        reach = WALL_ARCH.get(q["arch"], 9.0)
        lot = cand_v[0].intersection(q["g"].buffer(M(reach), join_style=2)).intersection(blocks_u)
        if lot.geom_type == "MultiPolygon":
            lot = max(lot.geoms, key=lambda x: x.area)
        if lot.geom_type != "Polygon" or lot.area < q["g"].area * 1.3:
            continue
        lots.append((q, lot))
    # the wall lines: the union of the lot outlines (shared sides once), minus the buildings, minus water
    bunion = unary_union([q["g"].buffer(M(0.3)) for q in blds])
    gates = []
    wall_pieces = []
    gate_cut = []
    for q, lot in lots:
        # the gate: on the lot's side that faces a road, at the point nearest the building's middle
        ring = LineString(lot.exterior.coords)
        near = [seg for seg in zip(lot.exterior.coords[:-1], lot.exterior.coords[1:])]
        best = None
        for a, b in near:
            s = LineString([a, b])
            if s.length < M(5.5):
                continue
            mid = s.interpolate(0.5, normalized=True)
            if mid.distance(corr) < M(4.5):
                d = mid.distance(q["g"].centroid)
                if best is None or d < best[0]:
                    best = (d, a, b)
        if best:
            _, a, b = best
            L = math.hypot(b[0] - a[0], b[1] - a[1])
            ux, uz = (b[0] - a[0]) / L, (b[1] - a[1]) / L
            t = max(M(0.8), min(L - M(5.8), L / 2 - M(2.25)))
            gx, gz = a[0] + ux * t, a[1] + uz * t
            gate_cut.append(LineString([(gx - ux * M(0.7), gz - uz * M(0.7)), (gx + ux * M(5.2), gz + uz * M(5.2))]).buffer(M(0.6)))
            # outward = away from the lot: the side the corridor is on
            nx, nz = uz, -ux
            if Point(gx + nx * M(2), gz + nz * M(2)).distance(corr) > Point(gx - nx * M(2), gz - nz * M(2)).distance(corr):
                nx, nz = -nx, -nz
            # panel frame: X along = up x outward = (nz, -nx); start where X runs from
            ax, az = nz, -nx
            # the gate's X runs 0 .. 4.5 m from its origin: put the origin so the leaf covers t .. t + 4.5
            if ax * ux + az * uz > 0:
                ox, oz = gx, gz
            else:
                ox, oz = gx + ux * M(4.5), gz + uz * M(4.5)
            gy = ground(gx, gz)[0]
            r = rng_for("gate", q["id"])
            pid = kit.prop("gate_green" if r.random() < 0.7 else "gate_rust")
            gates.append((tile_of(gx, gz), ("P", pid, ox, gy, oz, math.atan2(nx, nz), 1.0, "KWC")))
    full, street = [], []
    corr35 = corr.buffer(M(3.5))
    for q, l in lots:
        ring = LineString(l.exterior.coords)
        if q["arch"] == "house":
            street.append(ring.intersection(corr35))
        else:
            full.append(ring)
    lines = unary_union(full + street)
    # OSM walls and fences in the district
    osm_lines = json.load(open(os.path.join(geo.OSM, "lines.json"), encoding="utf-8"))["lines"]
    extra = []
    for l in osm_lines:
        if l["t"].get("barrier") in ("wall", "fence") and len(l["p"]) >= 2:
            ls = LineString(geo.proj(l["p"]))
            if ls.intersects(district):
                extra.append(ls)
    if extra:
        extra = [e.difference(lines.buffer(M(1.0))) for e in extra]
        lines = unary_union([lines] + [e for e in extra if not e.is_empty])
        stats["osm_walls"] = len(extra)
    seam_cut = [geo.batch_poly(u).boundary.intersection(district.boundary).buffer(M(1.0)) for u in SEAM_WITH]
    cut = unary_union([bunion, corr.buffer(M(0.3))] + gate_cut + list(zones.values()) + seam_polys + seam_cut)
    lines = lines.difference(cut)
    # straight runs: consecutive segments of a line that turn less than 3 degrees are one run (one collision box)
    runs = []
    # (light pass) the union cut the lot outlines at every node: join the pieces end to end, drop the tiny kinks
    from shapely.ops import linemerge
    if lines.geom_type == "MultiLineString":
        lines = linemerge(lines)
    lines = lines.simplify(M(0.25))
    for ls in (lines.geoms if hasattr(lines, "geoms") else [lines]):
        if ls.geom_type != "LineString" or ls.length < M(0.8):
            continue
        cs = list(ls.coords)
        cur = [cs[0], cs[1]]
        for c in cs[2:]:
            d0 = (cur[-1][0] - cur[0][0], cur[-1][1] - cur[0][1])
            d1 = (c[0] - cur[-1][0], c[1] - cur[-1][1])
            l0, l1 = math.hypot(*d0), math.hypot(*d1)
            if l0 > 1e-6 and l1 > 1e-6 and (d0[0] * d1[0] + d0[1] * d1[1]) / (l0 * l1) > math.cos(math.radians(4.0)):
                cur.append(c)
            else:
                runs.append((cur[0], cur[-1]))
                cur = [cur[-1], c]
        runs.append((cur[0], cur[-1]))
    # compound walls from the kit: each straight run cut into 8 / 4 / 2 / 1-bay pieces (28 / 14 / 7 / 3.5 m), stretched to
    # its exact length, each piece stood on the lower ground of its two ends (0.3 m of it goes into the ground)
    BAYW = M(3.5)
    wall_cols = {"KWC": 0.55, "KW6": 0.25, "KW1": 0.1, "KWG": 0.1}
    wall_len = 0.0
    wall_boxes = []
    n_pieces = 0
    # every piece stands a pillar at its start: two runs must never start within a pillar of each other (doubled pillars)
    class _Near:
        def __init__(self):
            self.g = defaultdict(list)

        def __contains__(self, p):
            i, j = int(p[0] // 4), int(p[1] // 4)
            return any(math.hypot(q[0] - p[0], q[1] - p[1]) < M(0.5) for di in (-1, 0, 1) for dj in (-1, 0, 1)
                       for q in self.g[(i + di, j + dj)])

        def add(self, p):
            self.g[(int(p[0] // 4), int(p[1] // 4))].append(p)
    pillars = _Near()
    for (a, b) in runs:
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        if L < M(0.8) or ground((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)[1] == 4:
            continue
        if a in pillars and b not in pillars:
            a, b = b, a
        elif a in pillars:
            # both ends taken: start just past the other pillar (0.45 m on)
            t = M(0.45) / L
            a = (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
            L = math.hypot(b[0] - a[0], b[1] - a[1])
            if L < M(0.8):
                continue
        pillars.add(a)
        ux, uz = (b[0] - a[0]) / L, (b[1] - a[1]) / L
        n = max(1, int(round(L / BAYW)))
        sw = L / (n * BAYW)
        col = wpick(rng_for("wc", round(a[0] / 60), round(a[1] / 60)), wall_cols)
        # the piece's X runs along the run (X = up x Z, so Z = (-uz, ux)); the wall is two-sided
        nx, nz = -uz, ux
        yaw = math.atan2(nx, nz)
        u = 0.0
        ks = [8] * (n // 8) + [4] * ((n % 8) // 4) + [2] * ((n % 4) // 2) + [1] * (n % 2)
        gys = []
        for kk in ks:
            ln = kk * BAYW * sw
            p = (a[0] + ux * u, a[1] + uz * u)
            p2 = (a[0] + ux * (u + ln), a[1] + uz * (u + ln))
            # long pieces on sloping ground: the lowest of five points along it
            gy = min(ground(a[0] + ux * (u + ln * t), a[1] + uz * (u + ln * t))[0] for t in (0, 0.25, 0.5, 0.75, 1.0))
            gys.append(gy)
            detail[tile_of(*p)].append(("P", kit.prop("cwall%d" % kk), p[0], gy, p[1], yaw, sw, col))
            stats["wall_pieces_%d" % kk] += 1
            n_pieces += 1
            u += ln
        wall_len += L
    # collision: one box per chain of the wall line whose points all lie within 1 stud of the chain's chord (gentle
    # kinks of the lot outlines share a box, thickened to cover them); stubs under 1.5 m get none
    for ls in (lines.geoms if hasattr(lines, "geoms") else [lines]):
        if ls.geom_type != "LineString" or ls.length < M(1.5):
            continue
        cs = list(ls.coords)
        i0 = 0
        while i0 < len(cs) - 1:
            i1 = i0 + 1
            dev = 0.0
            while i1 + 1 < len(cs):
                a, b = cs[i0], cs[i1 + 1]
                Lc = math.hypot(b[0] - a[0], b[1] - a[1])
                if Lc < 1e-6 or Lc > 600.0:
                    break
                dd = max(abs((c[0] - a[0]) * (b[1] - a[1]) - (c[1] - a[1]) * (b[0] - a[0])) / Lc for c in cs[i0 + 1:i1 + 1])
                if dd > 1.0:
                    break
                i1 += 1
                dev = dd
            a, b = cs[i0], cs[i1]
            L = math.hypot(b[0] - a[0], b[1] - a[1])
            if L >= M(1.5) and ground((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)[1] != 4:
                hs = [ground(a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)[0] for t in (0, 0.25, 0.5, 0.75, 1.0)]
                wall_boxes.append((a, b, min(hs), max(hs), dev))
            i0 = i1
    WH, WT = M(2.1), M(0.22)
    stats["wall_km"] = round(wall_len / S / 1000, 2)
    stats["wall_runs"] = len(runs)
    stats["wall_pieces"] = n_pieces
    stats["lots_walled"] = len(lots)
    stats["gates"] = len(gates)
    for t, rec in gates:
        detail[t].append(rec)
    for (p, p2, lo, hi, dev) in wall_boxes:
        L = math.hypot(p2[0] - p[0], p2[1] - p[1])
        yaw = math.atan2(-(p2[1] - p[1]), p2[0] - p[0])
        y0, y1 = lo - 0.9, hi + WH
        # client-side like the walls themselves (the local character and car are simulated on the client): an invisible
        # colliding Part in the detail of its tile (code WCOL)
        mx, mz = (p[0] + p2[0]) / 2, (p[1] + p2[1]) / 2
        detail[tile_of(mx, mz)].append(("B", mx, (y0 + y1) / 2, mz, L, y1 - y0, WT + 2 * dev, yaw, "WCOL"))
    stats["collide_wall_boxes"] = len(wall_boxes)
    print("walls %.2f km, %d lots, %d gates  %.1f s" % (stats["wall_km"], len(lots), len(gates), time.time() - t0))

    # -------------------------------------------------------------------------------------------------- write
    named_kit = []
    cls_name = {"W": "KWX", "M": "KGR", "C": "KAR", "R": "KRO"}
    kit_meta = {}
    for pid, d in kit.data.items():
        kit_meta[pid] = dict(key=list(d["key"]), w=d["w"], h=d["h"], parts={})
        for c in "WMCR":
            m = d[c]
            if not m.T:
                continue
            lo, hi = m.box()
            cen = [(lo[i] + hi[i]) / 2 for i in range(3)]
            siz = [max(0.05, hi[i] - lo[i]) for i in range(3)]
            nm = code(cls_name[c], pid, cen, siz)
            named_kit.append((nm, m))
            kit_meta[pid]["parts"][c] = dict(name=nm, tris=m.tris)
    kit_files = []
    for i in range(0, len(named_kit), FILE_MESHES):
        path = os.path.join(GLB, "kit_%d.glb" % (i // FILE_MESHES + 1))
        info = write_glb(path, named_kit[i:i + FILE_MESHES], generator="buildings_1to1.py kit")
        nmesh, bad = check_glb(path, info)
        assert not bad, bad
        kit_files.append(os.path.basename(path))
    named_cells = []
    cell_tris = Counter()
    for (cell, grp), m in sorted(cells.m.items()):
        if not m.T:
            continue
        # split past MAX_TRIS
        T = m.T
        for k0 in range(0, len(T), MAX_TRIS * 3):
            sub = Mesh()
            idx = T[k0:k0 + MAX_TRIS * 3]
            for t in range(0, len(idx), 3):
                i0, i1, i2 = idx[t], idx[t + 1], idx[t + 2]
                sub.P += [m.P[i0], m.P[i1], m.P[i2]]
                sub.N += [m.N[i0], m.N[i1], m.N[i2]]
                sub.U += [m.U[i0], m.U[i1], m.U[i2]]
                sub.C += [m.C[i0], m.C[i1], m.C[i2]]
                n0 = len(sub.T)
                sub.T += [n0, n0 + 1, n0 + 2]
            lo, hi = sub.box()
            cen = [(lo[i] + hi[i]) / 2 for i in range(3)]
            siz = [max(0.05, hi[i] - lo[i]) for i in range(3)]
            assert max(siz) <= 2048, (grp, cell, siz)
            cid = "c%sx%ss%d" % (("n%d" % -cell[0]) if cell[0] < 0 else cell[0], ("n%d" % -cell[1]) if cell[1] < 0 else cell[1], k0 // (MAX_TRIS * 3))
            named_cells.append((code(grp, cid, cen, siz), sub))
            cell_tris[grp] += sub.tris
    cell_files = []
    for i in range(0, len(named_cells), FILE_MESHES):
        path = os.path.join(GLB, "cells_%d.glb" % (i // FILE_MESHES + 1))
        info = write_glb(path, named_cells[i:i + FILE_MESHES], generator="buildings_1to1.py cells")
        nmesh, bad = check_glb(path, info)
        assert not bad, bad
        cell_files.append(os.path.basename(path))
    # detail (readable Inst pages for the checks + the packed per-tile data the client streamer reads), shell pages
    for f in os.listdir(OUT):
        if f.startswith(("Inst_", "Collide_", "Shell_")):
            os.remove(os.path.join(OUT, f))
    pages, cur = [], ""
    for tile in sorted(detail):
        head = "#%d %d\n" % tile
        cur += head
        for rec in detail[tile]:
            line = kit_pack.line(rec)
            if len(cur) + len(line) + 1 > CHARS:
                pages.append(cur)
                cur = head
            cur += line + "\n"
    if cur:
        pages.append(cur)
    for k, s_ in enumerate(pages):
        open(os.path.join(OUT, "Inst_%d.txt" % (k + 1)), "w", newline="\n").write(s_)
    cp, cur = [], ""
    for rec in shell:
        line = kit_pack.line(rec)
        if len(cur) + len(line) + 1 > CHARS:
            cp.append(cur)
            cur = ""
        cur += line + "\n"
    if cur:
        cp.append(cur)
    for k, s_ in enumerate(cp):
        open(os.path.join(OUT, "Shell_%d.txt" % (k + 1)), "w", newline="\n").write(s_)
    packed = kit_pack.write_rbxmx(os.path.join(GLB, "ygnkit_%s.rbxmx" % TAG.lower()), "Data_%s" % TAG, detail, TILE)
    # parts and triangles: in the place (shell) and made near the camera (detail)
    def rec_cost(rec):
        if rec[0] == "B":
            return 1, (0 if rec[8] == "WCOL" else 12)
        if rec[0] in ("S",):
            return 1, 12
        if rec[0] == "W":
            return 1, 0
        pid = rec[1]
        ps = kit_meta[pid]["parts"]
        return len(ps), sum(v["tris"] for v in ps.values())
    det_parts = det_tris = 0
    for t, recs in detail.items():
        for rec in recs:
            a_, b_ = rec_cost(rec)
            det_parts += a_
            det_tris += b_
    sh_parts = sh_tris = 0
    for rec in shell:
        a_, b_ = rec_cost(rec)
        sh_parts += a_
        sh_tris += b_
    inst_parts, inst_tris = det_parts, det_tris
    stats.update(detail_records=sum(len(v) for v in detail.values()), detail_parts=det_parts, detail_tris=det_tris,
                 detail_tiles=len(detail), detail_chars=packed["chars"], shell_parts=sh_parts, shell_tris=sh_tris,
                 place_parts=sh_parts + len(named_cells), collide_boxes=sum(1 for r_ in shell if r_[0] == "S"),
                 shell_pages=len(cp))
    kit_tris = sum(m.tris for _, m in named_kit)
    st = dict(stats, buildings=len(blds), archetypes=dict(arch_n), floors=dict(sorted(floor_n.items())),
              src=dict(Counter(q["src"] for q in blds)), unique_kit_meshes=len(named_kit), kit_panels_unique=len(kit.data),
              kit_files=kit_files, kit_tris_unique=kit_tris, cell_meshes=len(named_cells), cell_files=cell_files,
              cell_tris=dict(cell_tris), instance_parts=inst_parts, instance_tris=inst_tris,
              tris_total=inst_tris + sh_tris + sum(cell_tris.values()), panes_lit=panes_lit, inst_pages=len(pages),
              shell_pages_n=len(cp), unique_meshes=len(named_kit) + len(named_cells),
              landmark_sites_empty={k: [round(v, 1) for v in z.bounds] for k, z in zones.items()},
              seconds=round(time.time() - t0, 1))
    json.dump(st, open(os.path.join(OUT, "stats.json"), "w"), indent=1)
    json.dump(kit_meta, open(os.path.join(OUT, "kit_meta.json"), "w"))
    json.dump([dict(id=q["id"], src=q["src"], kind=q["kind"], arch=q["arch"], floors=q["floors_b"], wall=q["wall"],
                    base=round(q["base"], 2), poly=[[round(x, 1), round(z, 1)] for x, z in list(q["g"].exterior.coords)[:-1]])
               for q in blds], open(os.path.join(OUT, "plots.json"), "w"))
    preview(blds, lots, corr, zones, district)
    print(json.dumps({k: v for k, v in st.items() if k not in ("landmark_sites_empty",)}, indent=1))


def preview(blds, lots, corr, zones, district):
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        return
    x0, z0, x1, z1 = district.bounds
    sc = 2048 / max(x1 - x0, z1 - z0)
    im = Image.new("RGB", (int((x1 - x0) * sc) + 1, int((z1 - z0) * sc) + 1), (40, 52, 40))
    d = ImageDraw.Draw(im)
    P = lambda c: [((x - x0) * sc, (z - z0) * sc) for x, z in c]
    for g in (corr.geoms if hasattr(corr, "geoms") else [corr]):
        d.polygon(P(g.exterior.coords), fill=(90, 90, 92))
    for _, l in lots:
        d.line(P(l.exterior.coords), fill=(190, 190, 180), width=1)
    col = {"walkup": (120, 170, 220), "township": (230, 120, 80), "house": (220, 220, 210), "villa": (250, 250, 250),
           "condo": (80, 120, 240), "civic": (230, 210, 120), "shed": (150, 100, 80), "market": (180, 80, 60)}
    for q in blds:
        d.polygon(P(q["g"].exterior.coords), fill=col[q["arch"]])
    for z in zones.values():
        d.line(P(z.exterior.coords), fill=(255, 0, 255), width=3)
    im.save(os.path.join(OUT, "preview.png"))


if __name__ == "__main__":
    main()
