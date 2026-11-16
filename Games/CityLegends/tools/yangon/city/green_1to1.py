"""green_1to1.py <tag> (2026-11-16, P1): real ground cover and greenery of a 1:1 district. Run with YANGON_SCALE=1to1.

    YANGON_SCALE=1to1 python tree_kit.py            (the kit meshes; once for the whole city)
    YANGON_SCALE=1to1 python green_1to1.py P1

Research: vault `City Legends/2026-11-16 Research - Yangon terrain, water and trees.md` (canopy per area, street trees,
crown sizes, grass colours), `... Real Yangon street detail survey.md` (forecourts, dirt shoulders, compounds),
`... Yangon materials and textures library.md` (the Ygn terrain variants).

Inputs (build/city_1to1/): terrain_<tag>_state.npz (heights + water of the terrain skin), roads_<tag>_profile.json (road
corridors), buildings_<tag>/plots.json (footprints + archetype), buildings_<tag>/Inst_*.txt (compound-wall boxes WCOL),
build/osm_ygn/areas.json (parks, pitches, schools, parking ...), tree_kit's build/city_1to1/green/treekit.json.

1. GROUND: one material per 4-stud terrain column (the skin's own grid), painted straight into the terrain (no overlay
   parts, so nothing can flicker):
     L lawn (Grass -> YgnGrassLawn)     D dry grass (LeafyGrass -> YgnGrassDry)   P packed dirt (Ground -> YgnDirtPacked)
     E red earth (Salt -> YgnEarthRed)  G gravel (Pebble -> YgnGravel)            M mud (Mud -> YgnMudEdge)
     C concrete apron (Concrete)        S slab / tiled forecourt (Pavement)       . keep
   by land use: parks / lake banks / roundabout lawns, pitches red earth, schools and campus dry grass and dirt, shop
   and walk-up forecourts concrete (5-10 m deep, street survey 1A), shophouse fronts slabs, compound yards dirt / earth /
   gravel / dry grass with small lawns in villas, dirt and gravel road shoulders with puddle mud, a mud strip at the
   lake edge; under tree crowns in yards, dirt and red earth (leaf litter / bare earth, research section 3).
2. TREES: avenue rain trees (18-25 m on both kerbs), main-road outer kerbs, then fill per 32 m cell to a canopy target
   by land use (parks 58%, lake bank 65 / 56 / 47%, campus 48%, villas 45%, houses 38%, walk-ups 18% ...), species
   by area, crown sizes from the measured spread. A tree never overlaps a building, a road corridor, a deck, a
   landmark site or (for low crowns) a compound wall; trunks keep 1.2 m off walls. Hedges and bougainvillea inside
   compound walls, shrubs in gardens.
Outputs (build/city_1to1/green_<tag>/):
   Ground_<n>.txt   "tx tz y0 y1 <rle>" a 256-stud tile: rle = (material char, run length char) over the 4096 columns,
                    order ix * 64 + iz (terrain.py's order); y0 / y1 the voxel rows to read (multiples of 4)
   Far_<n>.txt      far looks: "pid x y z sx sy sz yaw tile" a line (the big crowns, in the place)
   green_<tag>.rbxmx  holding Folder: Data_<tag>G (kit_pack tile strings: the trees near the camera, client-built),
                    StringValues Ground_* / Far_*, ModuleScript YangonGreen1to1 (tools/yangon/YangonGreen1to1.luau)
   stats.json, preview.png
"""
import json
import math
import os
import random
import sys
import time
from collections import Counter, defaultdict
from xml.sax.saxutils import escape

import numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import distance_transform_edt, zoom, uniform_filter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import geo  # noqa: E402
import kit_pack  # noqa: E402

assert geo.ONE_TO_ONE, "run with YANGON_SCALE=1to1"
TAG = sys.argv[1] if len(sys.argv) > 1 else "P1"
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
B1 = os.path.join(ROOT, "build", "city_1to1")
OUT = os.path.join(B1, "green_%s" % TAG)
M = geo.m
RES = 4.0
TILE = 256
CELL = 8          # canopy cells of 8 x 8 columns (32 studs ~ 10.7 m) summed in windows of WIN cells
WIN = 3
SEED = 1611
B64 = kit_pack.B64
CHARS = 180000
MATS = "LDPEGMCS."

# landmark sites built on their own (their ground and planting are part of the landmark)
LANDMARK_BOXES = {
    "P1": [(34534.2, 27062.2, 35221.7, 28026.5), (34641.0, 26359.2, 35320.9, 27226.1),
           (31113 - 30, 30792 - 30, 31113 + 30, 30792 + 30), (31397 - 50, 33554 - 50, 31397 + 50, 33554 + 50)],
    # (step 5) P2: Kaba Aye court, Diamond Inya Palace, Inya Lake Hotel + Convention Center, Lotte, the two pagodas
    # (buildings_P2/stats.json landmark_sites_empty)
    "P2": [(34450.2, 17611.6, 34809.3, 17968.6), (33404.4, 19819.3, 33813.1, 20312.8), (33367.6, 21652.7, 34232.0, 22307.1),
           (28626.6, 21641.3, 29627.6, 22102.9), (34387.5, 16092.7, 34484.7, 16189.8), (32950.0, 19775.4, 33067.5, 19892.9)],
    # (step 6) P3 downtown: Sule, Botataung, and the lots left empty for their own landmark jobs (City Hall, Bogyoke Market,
    # Strand Hotel, High Court, Secretariat, Central Station, Immanuel Baptist, Holy Trinity, Maha Bandula Park)
    "P3": [(35840, 44973, 36158, 45265), (40017, 46869, 40361, 47547), (36097, 44765, 36483, 45051),
           (34683, 42851, 35286, 43453), (37153, 46507, 37438, 46820), (36499, 45396, 36867, 45733),
           (38008, 44484, 38514, 45055), (36486, 42630, 37118, 42836), (36496, 45191, 36617, 45292),
           (34399, 43175, 34587, 43300), (36008, 45285, 36438, 45950)],
    # ("up to batch 3") P4: Times City, M Tower, Crystal Residences, the four placed pagodas (buildings_P4/stats.json)
    "P4": [(26051.7, 30890.5, 26809.5, 31496.9), (26856.0, 27940.5, 27091.3, 28101.4), (26639.7, 30592.3, 27109.4, 30974.5),
           (25272.6, 24165.4, 25363.6, 24256.4), (23935.8, 29204.6, 24014.4, 29283.2), (25736.5, 19941.8, 25803.1, 20008.4),
           (24503.2, 25515.6, 24649.0, 25661.3)],
    "P5": [],
    # P6: its two placed pagodas (no catalogue landmark in P6)
    "P6": [(28752.9, 36209.0, 28814.4, 36270.5), (27116.2, 36321.5, 27229.4, 36434.6)],
}
AVENUES = {"University Avenue Road", "Inya Road", "U Wisara Road", "New University Avenue Road", "Kan Yeiktha Road",
           "Natmauk Road", "Ahlone Road", "Zoological Garden Road", "Shwe Gone Dine Road", "Bawdi Avenue"}
MAINS = {"Kabar Aye Pagoda Road", "Pyay Road", "Insein Road", "Waizayandar Road", "Bayint Naung Road"}
TOWNSHIP = {"Saya San Road", "No.1 Industrial Road", "Kanbe Road", "Thanlwin Road", "Parami Road", "Dhammazedi Road"}

# canopy targets (share of the ground under crowns, buildings included) by zone (research section 3)
ZONES = ["none", "park", "pitch", "campus", "school", "paved", "build_site", "cemetery", "religious", "lawn_isle",
         "villa", "house", "walkup", "township", "civic", "condo", "shed", "vacant"]
Z = {n: i for i, n in enumerate(ZONES)}
TARGET = dict(none=0.0, park=0.58, pitch=0.0, campus=0.48, school=0.42, paved=0.10, build_site=0.04, cemetery=0.45,
              religious=0.38, lawn_isle=0.0, villa=0.45, house=0.36, walkup=0.16, township=0.08, civic=0.36, condo=0.28,
              shed=0.18, vacant=0.36)
# species shares by zone (pid families; rt rain tree / banyan, bl broadleaf, mg mango, mh mahogany, cp coconut, bn banana)
SPECIES = {
    "park": {"rt": 0.30, "bl": 0.35, "mh": 0.15, "mg": 0.08, "cp": 0.12},
    "cemetery": {"rt": 0.3, "bl": 0.4, "mh": 0.2, "cp": 0.1},
    "campus": {"rt": 0.30, "bl": 0.30, "mh": 0.20, "mg": 0.10, "cp": 0.10},
    "school": {"rt": 0.25, "bl": 0.35, "mh": 0.10, "mg": 0.15, "cp": 0.15},
    "religious": {"rt": 0.35, "bl": 0.25, "cp": 0.20, "mg": 0.20},
    "lake": {"rt": 0.30, "bl": 0.30, "cp": 0.22, "mg": 0.08, "bn": 0.10},
    "villa": {"mg": 0.30, "cp": 0.12, "bl": 0.22, "rt": 0.18, "bn": 0.06, "mh": 0.12},
    "house": {"mg": 0.36, "cp": 0.12, "bl": 0.22, "rt": 0.10, "bn": 0.12, "mh": 0.08},
    "walkup": {"bl": 0.42, "mg": 0.28, "cp": 0.10, "bn": 0.08, "rt": 0.12},
    "default": {"bl": 0.45, "mg": 0.25, "cp": 0.15, "rt": 0.10, "bn": 0.05},
}
# crown diameter range (m) per family, the kit piece's reference diameter / height (tree_kit)
FAM = {
    "rt": dict(pids=("rt1", "rt2"), D=(12.0, 35.0), ref=22.0, base=7.5 / 22, low=False),
    "bl": dict(pids=("bl1", "bl2"), D=(6.0, 18.0), ref=12.0, base=4.5 / 12, low=False),
    "mg": dict(pids=("mg1", "mg2"), D=(6.0, 13.0), ref=11.0, base=2.0 / 11, low=True),
    "mh": dict(pids=("mh1",), D=(7.0, 13.0), ref=10.0, base=7.0 / 10, low=False),
    "cp": dict(pids=("cp1", "cp2"), D=(6.5, 9.0), ref=8.0, base=13.0 / 8, low=False),
    "bn": dict(pids=("bn1",), D=(3.5, 6.0), ref=4.5, base=1.5 / 4.5, low=True),
}
# shifted to bigger crowns than the measured blob spread (its small blobs are crown fragments; research section 4)
# (owner, 16 Nov, after the first look: "the old map vibe was better ... the trees are so ugly ... the first version
# grass looked better") STYLE "clean": the game's own terrain Grass everywhere (no Ygn ground overrides, no dirt /
# earth / gravel patches), clean concrete only on real forecourts and parking, the old map's tree kit (Monaco Tree /
# Palm / PalmA copies, ServerStorage.YangonData.GreenKit) at real sizes, no shrubs / hedges / banana. "patchy" = the
# first pass (Ygn ground variants + tree_kit.py meshes).
STYLE = "clean"
OLD_KIT = {"tree": ("ot1", 18.3), "palm": (("op1", 12.2), ("op2", 16.3))}   # pid, crown width / height (m) at scale 1
SIZE_BINS = [((6, 10), 0.22), ((10, 18), 0.46), ((18, 28), 0.26), ((28, 35), 0.06)]


def log(*a):
    print("%7.1f" % (time.time() - T0), *a, flush=True)


T0 = time.time()


# ---------------------------------------------------------------------------------------------------- inputs
def load():
    st = np.load(os.path.join(B1, "terrain_%s_state.npz" % TAG))
    H, code, org = st["H"], st["code"], st["origin"]
    prof = json.load(open(os.path.join(B1, "roads_%s_profile.json" % TAG)))
    plots = json.load(open(os.path.join(B1, "buildings_%s" % TAG, "plots.json")))
    for q_ in plots:   # (P3) downtown colonial rows take the township shophouses' ground (slab / concrete fronts)
        if q_.get("arch") == "colonial":
            q_["arch"] = "township"
    walls = []
    bdir = os.path.join(B1, "buildings_%s" % TAG)
    for f in sorted(os.listdir(bdir)):
        if f.startswith("Inst_"):
            for ln in open(os.path.join(bdir, f)):
                if ln.startswith("B ") and ln.rstrip().endswith("WCOL"):
                    _, x, y, z, sx, sy, sz, yaw, _c = ln.split()
                    walls.append(tuple(map(float, (x, y, z, sx, sy, sz, yaw))))
    kit = json.load(open(os.path.join(B1, "green", "treekit.json")))
    return H, code, (float(org[0]), float(org[1])), prof, plots, walls, kit


class Grid:
    def __init__(self, org, shape):
        self.X0, self.Z0 = org
        self.nx, self.nz = shape

    def ij(self, x, z):
        return (x - self.X0) / RES, (z - self.Z0) / RES

    def blank(self, mode="1"):
        return Image.new(mode, (self.nx, self.nz), 0)

    def poly(self, draw, pts, fill=1):
        draw.polygon([self.ij(x, z) for x, z in pts], fill=fill)

    @staticmethod
    def arr(img, dtype=bool):
        return np.asarray(img, dtype=dtype).T.copy()

    def xz(self, i, j):
        return self.X0 + RES * i + RES / 2, self.Z0 + RES * j + RES / 2


def box_pts(x, z, sx, sz, yaw):
    c, s = math.cos(yaw), math.sin(yaw)
    out = []
    for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        lx, lz = a * sx / 2, b * sz / 2
        out.append((x + lx * c + lz * s, z - lx * s + lz * c))
    return out


def noise(shape, scale_cols, rng):
    """smooth value noise (0..1, uniform by rank) at a feature size of `scale_cols` columns"""
    g = rng.random((shape[0] // scale_cols + 3, shape[1] // scale_cols + 3))
    n = zoom(g, scale_cols, order=3)[:shape[0], :shape[1]]
    r = np.empty(n.size, np.float32)
    r[np.argsort(n, axis=None)] = np.linspace(0, 1, n.size, dtype=np.float32)
    return r.reshape(shape)


def pick(u, table):
    """u (0..1 array) -> material char per a {char: share} table (cumulative bins)"""
    out = np.full(u.shape, ".", "<U1")
    acc = 0.0
    tot = sum(table.values())
    for ch, w in table.items():
        lo, acc = acc, acc + w / tot
        out[(u >= lo) & (u < acc + (1e-6 if acc >= 0.999 else 0))] = ch
    return out


# ---------------------------------------------------------------------------------------------------- main
def main():
    H, code, org, prof, plots, walls, kit = load()
    G = Grid(org, H.shape)
    nx, nz = H.shape
    rng = np.random.default_rng(SEED)
    log("grid", H.shape, "plots", len(plots), "walls", len(walls), "roads", len(prof))
    land = (code == 1) | (code == 2)
    water = (code == 3) | (code == 4)

    # roads: ground corridors (carriageway + pavement + 0.6 m) and raised decks
    im_r, im_d = G.blank(), G.blank()
    dr_r, dr_d = ImageDraw.Draw(im_r), ImageDraw.Draw(im_d)
    lines = []
    for e in prof:
        P = np.array([[p[0], p[2]] for p in e["pts"]], float)
        if len(P) < 2:
            continue
        lo = -e["half"][0] - e["walk"] - M(0.6)
        hi = e["half"][1] + e["walk"] + M(0.6)
        dr = dr_d if e.get("raised") else dr_r
        for k in range(len(P) - 1):
            a, b = P[k], P[k + 1]
            d = b - a
            L = math.hypot(*d)
            if L < 1e-6:
                continue
            d /= L
            R = np.array([-d[1], d[0]])
            G.poly(dr, [a + R * lo, b + R * lo, b + R * hi, a + R * hi])
            rad = max(abs(lo), abs(hi)) * 0.98 / RES
            ci, cj = G.ij(*b)
            dr.ellipse([ci - rad, cj - rad, ci + rad, cj + rad], fill=1)
        lines.append((P, e))
    road = G.arr(im_r)
    deck = G.arr(im_d)
    log("road corridor cols", road.sum(), "deck", deck.sum())

    # buildings (index image), walls, landmark boxes
    im_b = G.blank("I")
    dr_b = ImageDraw.Draw(im_b)
    for k, q in enumerate(plots):
        G.poly(dr_b, q["poly"], fill=k + 1)
    bid = G.arr(im_b, np.int32)
    bld = bid > 0
    # building tops over the ground (studs): floors x 3.3 m + parapet / pitched roof
    htab = np.array([0.0] + [M(q.get("floors", 2) * 3.3 + (2.5 if q["arch"] in ("house", "villa", "shed") else 1.2))
                             for q in plots], np.float32)
    bh = htab[bid]
    im_w = G.blank()
    dr_w = ImageDraw.Draw(im_w)
    for (x, y, z, sx, sy, sz, yaw) in walls:
        G.poly(dr_w, box_pts(x, z, sx, max(sz, 1.0), yaw))
    wall = G.arr(im_w)
    im_l = G.blank()
    dr_l = ImageDraw.Draw(im_l)
    for (x0, z0, x1, z1) in LANDMARK_BOXES.get(TAG, []):
        G.poly(dr_l, [(x0, z0), (x1, z0), (x1, z1), (x0, z1)])
    # (2026-11-16, real places) fuel forecourts, car parks, courts, playgrounds (places_1to1.py build): no trees, their
    # own slab over the ground
    kp = os.path.join(B1, "places_%s" % TAG, "keepout.json")
    if os.path.exists(kp):
        for pts in json.load(open(kp)):
            G.poly(dr_l, [tuple(q) for q in pts])
    lmk = G.arr(im_l)
    log("buildings cols", bld.sum(), "wall cols", wall.sum(), "landmark cols", lmk.sum())

    # distances (studs)
    d_road = distance_transform_edt(~road) * RES
    d_deck = distance_transform_edt(~deck) * RES
    d_bld, bidx = distance_transform_edt(~bld, return_indices=True)
    d_bld *= RES
    near_b = bid[bidx[0], bidx[1]] - 1         # nearest building per column
    d_wall = distance_transform_edt(~wall) * RES
    d_wat = distance_transform_edt(~water) * RES
    d_lmk = distance_transform_edt(~lmk) * RES
    del bidx
    log("distances done")

    # OSM areas -> zones
    zone = np.zeros((nx, nz), np.int8)
    area_cls = {}
    for a in geo.load("areas"):
        t = a["t"]
        cls = None
        if t.get("leisure") in ("park", "garden") or t.get("landuse") in ("forest", "recreation_ground", "grass", "village_green"):
            cls = "park"
        elif t.get("landuse") == "flowerbed":
            cls = "lawn_isle"
        elif t.get("leisure") in ("pitch", "track"):
            cls = "pitch"
        elif t.get("amenity") == "university":
            cls = "campus"
        elif t.get("amenity") in ("school", "college", "kindergarten"):
            cls = "school"
        elif t.get("amenity") in ("parking", "parking_space") or t.get("landuse") in ("commercial", "retail") or \
                t.get("leisure") == "swimming_pool":
            cls = "paved"
        elif t.get("landuse") == "construction":
            cls = "build_site"
        elif t.get("landuse") == "cemetery":
            cls = "cemetery"
        elif t.get("landuse") == "religious" or t.get("amenity") == "place_of_worship":
            cls = "religious"
        if not cls:
            continue
        P = geo.proj(a["p"])
        xs = [p[0] for p in P]
        zs = [p[1] for p in P]
        if max(xs) < G.X0 or min(xs) > G.X0 + nx * RES or max(zs) < G.Z0 or min(zs) > G.Z0 + nz * RES:
            continue
        area_cls.setdefault(cls, []).append(P)
    # paint big classes first, small specific ones over them
    for cls in ("campus", "school", "religious", "cemetery", "park", "paved", "build_site", "pitch", "lawn_isle"):
        if cls not in area_cls:
            continue
        im = G.blank()
        dr = ImageDraw.Draw(im)
        for P in area_cls[cls]:
            G.poly(dr, P)
        zone[G.arr(im)] = Z[cls]
    log("areas:", {k: len(v) for k, v in area_cls.items()})
    # lots (no area): the nearest building's archetype within 45 m, else vacant
    arch_of = np.array([Z.get(q["arch"], Z["house"]) for q in plots] + [Z["vacant"]], np.int8)
    kind_rel = np.array([q["kind"] == "religious" for q in plots] + [False])
    lot = arch_of[np.where(near_b >= 0, near_b, len(plots))]
    lot = np.where(d_bld > M(45), Z["vacant"], lot)
    rel = kind_rel[np.where(near_b >= 0, near_b, len(plots))] & (d_bld < M(40))
    lot = np.where(rel, Z["religious"], lot)
    zone = np.where(zone == 0, lot, zone).astype(np.int8)

    # ------------------------------------------------------------------------------------ ground materials
    u1 = noise((nx, nz), 3, rng)      # ~4 m patches
    u2 = noise((nx, nz), 6, rng)      # ~8 m patches
    u3 = noise((nx, nz), 14, rng)     # ~19 m patches
    fine = rng.random((nx, nz)).astype(np.float32)
    mat = np.full((nx, nz), ".", "<U1")
    zn = np.array(ZONES)[zone]
    jit = (u1 - 0.5) * M(1.6)          # wobble the band edges

    def put(mask, table, u=None):
        if mask.any():
            mat[mask] = pick((u2 if u is None else u)[mask], table)

    open_ = land & ~bld
    # base by zone
    put(open_ & (zn == "park"), {"L": 0.74, "D": 0.16, "P": 0.10}, u3)
    put(open_ & (zn == "cemetery"), {"L": 0.45, "D": 0.35, "P": 0.20}, u3)
    put(open_ & (zn == "lawn_isle"), {"L": 1.0})
    put(open_ & (zn == "pitch"), {"E": 0.62, "D": 0.22, "L": 0.16}, u3)
    put(open_ & ((zn == "campus") | (zn == "school")), {"D": 0.42, "P": 0.22, "E": 0.12, "L": 0.16, "G": 0.08}, u3)
    put(open_ & (zn == "religious"), {"C": 0.35, "P": 0.30, "D": 0.20, "E": 0.15}, u2)
    put(open_ & (zn == "paved"), {"C": 0.80, "S": 0.12, "P": 0.08}, u3)
    put(open_ & (zn == "build_site"), {"G": 0.45, "P": 0.35, "E": 0.20}, u3)
    put(open_ & (zn == "villa"), {"L": 0.30, "D": 0.24, "P": 0.24, "E": 0.12, "G": 0.10}, u2)
    put(open_ & (zn == "house"), {"P": 0.38, "D": 0.24, "E": 0.14, "L": 0.12, "G": 0.08, "C": 0.04}, u2)
    put(open_ & ((zn == "walkup") | (zn == "township")), {"P": 0.40, "C": 0.22, "G": 0.16, "D": 0.14, "E": 0.08}, u2)
    put(open_ & (zn == "civic"), {"D": 0.34, "P": 0.26, "C": 0.16, "L": 0.14, "E": 0.10}, u2)
    put(open_ & (zn == "condo"), {"C": 0.40, "L": 0.25, "D": 0.20, "P": 0.15}, u2)
    put(open_ & (zn == "shed"), {"P": 0.38, "G": 0.30, "C": 0.20, "D": 0.12}, u2)
    put(open_ & (zn == "vacant"), {"D": 0.48, "P": 0.22, "L": 0.14, "G": 0.08, "E": 0.08}, u3)
    # aprons round buildings: concrete / tiles 1-2.5 m (walk-ups, shops, civic, condo); a packed edge round houses
    arch_near = np.array([q["arch"] for q in plots] + ["none"])[np.where(near_b >= 0, near_b, len(plots))]
    paved_arch = np.isin(arch_near, ["walkup", "township", "civic", "condo", "shed"])
    apron = open_ & (d_bld <= M(1.5) + jit * 0.5) & ~np.isin(zn, ["park", "pitch", "lawn_isle"])
    mat[apron & paved_arch] = np.where(u1[apron & paved_arch] < 0.85, "C", "P")
    mat[apron & (arch_near == "villa")] = np.where(u1[apron & (arch_near == "villa")] < 0.6, "S", "C")
    mat[apron & (arch_near == "house")] = np.where(u1[apron & (arch_near == "house")] < 0.5, "C", "P")
    # forecourts: between a walk-up / shophouse / shop / civic building and the road, up to 10 m deep
    gap_ok = (d_road + d_bld) <= M(14) + jit
    fore = open_ & gap_ok & (d_road <= M(10)) & paved_arch & ~np.isin(zn, ["park", "pitch", "lawn_isle", "campus"])
    mat[fore] = pick(u2[fore], {"C": 0.70, "S": 0.12, "P": 0.12, "G": 0.06})
    mat[fore & (arch_near == "township")] = np.where(u2[fore & (arch_near == "township")] < 0.55, "S", "C")
    # villa / house drives: concrete strip from the street to the building's nearest point (3 m wide)
    drive = open_ & np.isin(arch_near, ["villa", "house"]) & gap_ok & (d_road <= M(14)) & (u3 < 0.25)
    mat[drive] = "C"
    # road shoulders (outside the corridor, 0-2.5 m): dirt and gravel, puddle mud in low spots
    sh = open_ & ~road & (d_road <= M(2.5) + jit * 0.6) & ~fore & ~np.isin(zn, ["park", "lawn_isle"])
    mat[sh] = pick(u1[sh], {"P": 0.48, "G": 0.30, "D": 0.16, "M": 0.06})
    # under the road meshes and their skirts: dirt / gravel (only edges show)
    rd = land & (road | deck) & ~bld
    mat[rd] = np.where(u1[rd] < 0.6, "P", "G")
    # under the flyover decks: packed dirt, gravel and concrete
    under = land & deck & ~road
    mat[under] = pick(u2[under], {"P": 0.45, "G": 0.35, "C": 0.20})
    # lake edge: mud 0-2 m, then mud / dry grass mix to 5 m (natural banks; research section 2)
    lk = land & (d_wat <= M(2.0) + jit * 0.5)
    mat[lk] = "M"
    lk2 = land & ~lk & (d_wat <= M(5.0) + jit)
    mat[lk2] = pick(u1[lk2], {"M": 0.35, "D": 0.35, "L": 0.30})
    # building footprints and landmark sites: keep (hidden / their own ground)
    mat[bld & land] = np.where(paved_arch[bld & land], "C", "P")
    mat[lmk] = "."
    mat[~land] = "."
    if STYLE == "clean":
        mat[:] = "."
        mat[land] = "L"
        cl = open_ & (zn == "paved")
        cl |= fore & (d_road <= M(9)) & ~(zn == "park")
        gx, gz = np.gradient(H.astype(np.float32), RES)
        cl &= np.hypot(gx, gz) < 0.12     # concrete only where the ground is flat (no sloped concrete banks)
        mat[cl] = "C"
        mat[lmk] = "."
        mat[~land] = "."
    # (owner's two pictures, 16 Nov) the lake walk (grass bank down to the water, narrow walk, fan palms ...) and the
    # Kabar Aye green bank (low black railing, embankment, tree row): green_edges.py; the bund wall of v2 is retired
    import green_edges
    ED = green_edges.edges(G, water, prof, H, lmk, ~land & ~water, d_bld, road, d_road,
                           landmark_boxes=LANDMARK_BOXES.get(TAG, []))
    edge_parts, edge_mask, edge_len = ED["parts"], ED["mask"], ED["stats"]["walk_m"] * 3
    log("edges", ED["stats"])
    deck |= edge_mask
    d_deck = distance_transform_edt(~deck) * RES
    mat[edge_mask & land] = np.where(mat[edge_mask & land] == ".", ".", "L")
    log("ground classes", dict(Counter(mat[land].ravel().tolist())), "lake edge parts", len(edge_parts),
        "bund m", round(edge_len / 3))

    # ------------------------------------------------------------------------------------ trees
    R = random.Random(SEED)
    Hh = H

    def ground_y(x, z):
        i = min(max(int((x - G.X0) / RES), 0), nx - 1)
        j = min(max(int((z - G.Z0) / RES), 0), nz - 1)
        return float(Hh[i, j])

    def col(x, z):
        i = int((x - G.X0) / RES)
        j = int((z - G.Z0) / RES)
        if 0 <= i < nx and 0 <= j < nz:
            return i, j
        return None

    trees = []            # dict(fam, pid, x, z, D, s)
    grid = defaultdict(list)
    GH = 60.0

    def clear_of_trees(x, z, r):
        gi, gj = int(x // GH), int(z // GH)
        for a in range(gi - 2, gi + 3):
            for b in range(gj - 2, gj + 3):
                for t in grid[(a, b)]:
                    if math.hypot(t["x"] - x, t["z"] - z) < 0.62 * (t["r"] + r):
                        return False
        return True

    def fits(fam, x, z, D, street=False):
        """largest crown diameter (studs) <= D that fits here, or 0"""
        c = col(x, z)
        if not c:
            return 0
        i, j = c
        if not land[i, j] or bld[i, j] or road[i, j] or deck[i, j] or lmk[i, j]:
            return 0
        if d_wall[i, j] < M(1.2) or d_bld[i, j] < M(1.5) or d_wat[i, j] < M(0.8) or d_road[i, j] < M(0.6):
            return 0
        if zn[i, j] in ("pitch", "lawn_isle"):
            return 0
        f = FAM[fam]
        r = D / 2
        lim = min(d_deck[i, j] - 2.0, d_lmk[i, j] - 2.0)
        if f["low"]:
            lim = min(lim, d_wall[i, j] - M(0.3), d_bld[i, j] - 1.0)
        for k_ in (1.0, 0.85):
            rr = min(r * k_, lim)
            Dm = 2 * rr
            if Dm < M(f["D"][0]) * 0.92:
                return 0
            base = f["base"] * Dm
            if base < M(5.0) and rr > d_road[i, j] + M(0.3):
                continue                               # a low crown must not hang over the road
            if rr <= d_bld[i, j] - 1.0:
                return Dm
            # the crown may hang over roofs that stay at least 1 m under its lowest leaves
            ri = rr / RES
            i0, i1 = max(0, int(i - ri)), min(nx, int(i + ri) + 2)
            j0, j1 = max(0, int(j - ri)), min(nz, int(j + ri) + 2)
            I_, J_ = np.ogrid[i0:i1, j0:j1]
            disk = ((I_ - i) ** 2 + (J_ - j) ** 2) <= ri * ri
            if float((bh[i0:i1, j0:j1] * disk).max()) <= base - M(1.0):
                return Dm
        return 0

    def add_tree(fam, x, z, D, src):
        f = FAM[fam]
        pid = R.choice(f["pids"])
        s = D / M(f["ref"])
        sy = s * R.uniform(0.9, 1.1)
        if fam == "cp":
            s = D / M(f["ref"])
            sy = R.uniform(0.8, 1.3)         # palms: height 13-22 m whatever the crown
        t = dict(fam=fam, pid=pid, x=x, z=z, D=D, r=D / 2, s=s, sy=sy, yaw=R.uniform(0, 2 * math.pi),
                 y=ground_y(x, z) - 0.4, src=src)
        trees.append(t)
        grid[(int(x // GH), int(z // GH))].append(t)
        return t

    def sample_D(fam, rng_):
        lo, hi = FAM[fam]["D"]
        for _ in range(8):
            u = rng_.random()
            acc = 0
            for (a, b), w in SIZE_BINS:
                acc += w
                if u <= acc:
                    d = rng_.uniform(a, b)
                    break
            if lo <= d <= hi:
                return M(d)
        return M(rng_.uniform(lo, hi))

    def species(zname, near_lake, rng_):
        tab = SPECIES["lake"] if near_lake else SPECIES.get(zname, SPECIES["default"])
        ks = list(tab)
        return rng_.choices(ks, [tab[k] for k in ks])[0]

    # 1. street trees
    nst = Counter()
    for P, e in lines:
        nm = e.get("name") or ""
        if e.get("raised"):
            continue
        if nm in AVENUES:
            gap, fams, Dr, both, pres = (18, 25), {"rt": 0.7, "mh": 0.15, "bl": 0.15}, (18, 28), True, 0.92
        elif nm in MAINS:
            gap, fams, Dr, both, pres = (20, 30), {"rt": 0.5, "bl": 0.3, "mh": 0.2}, (12, 24), True, 0.75
        elif nm in TOWNSHIP:
            gap, fams, Dr, both, pres = (14, 24), {"bl": 0.5, "mg": 0.25, "rt": 0.15, "cp": 0.10}, (8, 14), True, 0.55
        else:
            continue
        seg = np.diff(P, axis=0)
        L = np.hypot(seg[:, 0], seg[:, 1])
        cum = np.concatenate([[0], np.cumsum(L)])
        for side in ((-1, 1) if both else (1,)):
            off0 = (e["half"][0] if side < 0 else e["half"][1]) + e["walk"]
            s_at = R.uniform(0, M(gap[0]))
            while s_at < cum[-1]:
                k = min(int(np.searchsorted(cum, s_at) - 1), len(L) - 1)
                k = max(k, 0)
                t = (s_at - cum[k]) / max(L[k], 1e-6)
                p = P[k] + (P[k + 1] - P[k]) * t
                d = (P[k + 1] - P[k]) / max(L[k], 1e-6)
                Rn = np.array([-d[1], d[0]]) * side
                if R.random() < pres:
                    fam = R.choices(list(fams), list(fams.values()))[0]
                    for extra in (1.2, 2.2, 3.4):
                        q = p + Rn * (off0 + M(extra))
                        D = M(R.uniform(*Dr))
                        Dm = fits(fam, q[0], q[1], D, True)
                        if Dm and clear_of_trees(q[0], q[1], Dm / 2):
                            add_tree(fam, q[0], q[1], Dm, "street")
                            nst[nm] += 1
                            break
                s_at += M(R.uniform(*gap))
    log("street trees", sum(nst.values()), dict(nst))

    # 2. fill to the canopy target per cell
    tgt = np.zeros((nx, nz), np.float32)
    for zname, v in TARGET.items():
        tgt[zone == Z[zname]] = v
    lake_band = np.where(d_wat <= M(15), 0.65, np.where(d_wat <= M(50), 0.56, np.where(d_wat <= M(150), 0.47, 0)))
    tgt = np.where(land, np.maximum(tgt, lake_band * (d_wat <= M(150))), 0).astype(np.float32)
    tgt[lmk] = 0
    cov = np.zeros((nx, nz), bool)

    def stamp(t):
        r = t["r"] / RES
        ci, cj = (t["x"] - G.X0) / RES, (t["z"] - G.Z0) / RES
        i0, i1 = max(0, int(ci - r)), min(nx, int(ci + r) + 2)
        j0, j1 = max(0, int(cj - r)), min(nz, int(cj + r) + 2)
        I, J = np.ogrid[i0:i1, j0:j1]
        cov[i0:i1, j0:j1] |= ((I + 0.5 - ci) ** 2 + (J + 0.5 - cj) ** 2) <= r * r
    for t in trees:
        stamp(t)
    ncx, ncz = nx // CELL, nz // CELL
    cell_t = tgt[:ncx * CELL, :ncz * CELL].reshape(ncx, CELL, ncz, CELL).sum((1, 3))
    # window target (WIN x WIN cells) so a narrow lot is judged with its neighbours
    win_t = uniform_filter(cell_t, WIN, mode="constant") * WIN * WIN

    def win_cov(ci, cj):
        a0, a1 = max(0, ci - WIN // 2), min(ncx, ci + WIN // 2 + 1)
        b0, b1 = max(0, cj - WIN // 2), min(ncz, cj + WIN // 2 + 1)
        return cov[a0 * CELL:a1 * CELL, b0 * CELL:b1 * CELL].sum()

    cand_i = rng.integers(0, nx, 900000)
    cand_j = rng.integers(0, nz, 900000)
    ok = land[cand_i, cand_j] & ~bld[cand_i, cand_j] & ~road[cand_i, cand_j] & (tgt[cand_i, cand_j] > 0)
    cand_i, cand_j = cand_i[ok], cand_j[ok]
    nfill = 0
    for i, j in zip(cand_i.tolist(), cand_j.tolist()):
        ci, cj = min(i // CELL, ncx - 1), min(j // CELL, ncz - 1)
        if win_cov(ci, cj) >= win_t[ci, cj] or                 cov[ci * CELL:(ci + 1) * CELL, cj * CELL:(cj + 1) * CELL].sum() >= cell_t[ci, cj] * 1.15:
            continue
        x, z = G.xz(i, j)
        x += R.uniform(-1.8, 1.8)
        z += R.uniform(-1.8, 1.8)
        zname = ZONES[zone[i, j]]
        fam = species(zname, d_wat[i, j] <= M(50), R)
        D = sample_D(fam, R)
        Dm = fits(fam, x, z, D)
        if not Dm and fam not in ("mg", "bn") and R.random() < 0.4:
            fam = "mg"
            Dm = fits(fam, x, z, sample_D(fam, R))
        if not Dm or not clear_of_trees(x, z, Dm / 2):
            continue
        stamp(add_tree(fam, x, z, Dm, "fill"))
        nfill += 1
    log("fill trees", nfill)

    # 3. hedges and bougainvillea inside compound walls, shrubs in gardens
    shrubs = []      # dict(pid, x, y, z, yaw, sx, sy, sz)

    def free(x, z, r, low=True):
        c = col(x, z)
        if not c:
            return False
        i, j = c
        if not land[i, j] or bld[i, j] or road[i, j] or lmk[i, j] or water[i, j]:
            return False
        return d_bld[i, j] >= r + 1.0 and d_road[i, j] >= r + 0.5 and d_lmk[i, j] >= r and \
            (not low or d_wall[i, j] >= r + 0.3)

    nh = nbv = 0
    for (x, y, z, sx, sy, sz, yaw) in (walls if STYLE != "clean" else []):
        c = col(x, z)
        if not c:
            continue
        b = near_b[c]
        arch = plots[b]["arch"] if b >= 0 else "none"
        if arch not in ("villa", "civic", "condo", "house"):
            continue
        # inside = the side toward the nearest building's middle
        bx = np.mean([p[0] for p in plots[b]["poly"]])
        bz = np.mean([p[1] for p in plots[b]["poly"]])
        cy, sn = math.cos(yaw), math.sin(yaw)
        ax_ = (cy, -sn)            # wall direction (local X)
        nrm = (sn, cy)             # local Z
        if (bx - x) * nrm[0] + (bz - z) * nrm[1] < 0:
            nrm = (-nrm[0], -nrm[1])
        r_ = R.random()
        if arch in ("villa", "civic", "condo") and r_ < 0.18 and sx > M(4):
            hl = 10.737
            n = max(1, int(round(sx / hl)))
            stretch = sx / (n * hl)
            off = sz / 2 + 0.6 + 1.66
            for k in range(n):
                t = -sx / 2 + (k + 0.5) * sx / n
                hx = x + ax_[0] * t + nrm[0] * off
                hz = z + ax_[1] * t + nrm[1] * off
                # hedge corners clear of buildings / roads (the hedge itself stands 0.6 off the wall)
                okk = all(free(hx + ax_[0] * e_ * sx / n / 2, hz + ax_[1] * e_ * sx / n / 2, 1.0, False)
                          for e_ in (-0.9, 0, 0.9))
                if not okk:
                    continue
                shrubs.append(dict(pid="hg1", x=hx, z=hz, y=ground_y(hx, hz) - 0.3, yaw=yaw, sx=stretch,
                                   sy=R.uniform(1.35, 1.9), sz=R.uniform(0.9, 1.1)))
                nh += 1
        elif arch in ("villa", "house") and r_ < 0.55 and sx > M(3):
            s = R.uniform(0.8, 1.15)
            rad = 4.44 * s
            t = R.uniform(-0.4, 0.4) * sx
            off = sz / 2 + 0.4 + rad
            hx = x + ax_[0] * t + nrm[0] * off
            hz = z + ax_[1] * t + nrm[1] * off
            if free(hx, hz, rad, False) and clear_of_trees(hx, hz, rad * 0.6):
                shrubs.append(dict(pid="bv1", x=hx, z=hz, y=ground_y(hx, hz) - 0.3, yaw=R.uniform(0, 6.283), sx=s,
                                   sy=s * R.uniform(0.95, 1.15), sz=s))
                nbv += 1
    # garden shrubs next to houses / villas / civic / parks
    nsh = 0
    ci_ = rng.integers(0, nx, 220000)
    cj_ = rng.integers(0, nz, 220000)
    for i, j in zip(ci_.tolist(), cj_.tolist()) if STYLE != "clean" else []:
        zname = ZONES[zone[i, j]]
        if zname not in ("villa", "house", "civic", "park", "condo", "religious"):
            continue
        want = {"villa": 0.5, "house": 0.18, "civic": 0.25, "park": 0.05, "condo": 0.4, "religious": 0.3}[zname]
        if zname != "park" and not (M(1.2) < d_bld[i, j] < M(4.5)):
            continue
        if R.random() > want:
            continue
        x, z = G.xz(i, j)
        s = R.uniform(0.7, 1.3)
        rad = 2.7 * s
        if free(x, z, rad) and clear_of_trees(x, z, rad * 0.5):
            shrubs.append(dict(pid="sh1", x=x, z=z, y=ground_y(x, z) - 0.3, yaw=R.uniform(0, 6.283), sx=s,
                               sy=s * R.uniform(0.8, 1.2), sz=s))
            nsh += 1
    log("hedges", nh, "bougainvillea", nbv, "shrubs", nsh)

    # ground under crowns in yards / campus / vacant: dirt and red earth (leaf litter, bare earth)
    under_c = cov & land & ~bld & ~road & np.isin(zn, ["house", "villa", "walkup", "civic", "campus", "school", "vacant",
                                                       "religious", "shed", "township"])
    soft = under_c & np.isin(mat, ["L", "D"]) & (u1 < 0.62) & (STYLE != "clean")
    mat[soft] = np.where(u2[soft] < 0.55, "P", "E")
    soft_p = cov & land & np.isin(zn, ["park", "cemetery"]) & (mat == "L") & (u1 < 0.28) & (STYLE != "clean")
    mat[soft_p] = np.where(u2[soft_p] < 0.6, "D", "P")
    log("ground under crowns re-painted", int(soft.sum() + soft_p.sum()))

    # ------------------------------------------------------------------------------------ outputs
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        if f.endswith(".txt"):
            os.remove(os.path.join(OUT, f))
    # ground tiles
    glines = []
    ntx, ntz = nx // 64, nz // 64
    cnt = Counter()
    for ti in range(ntx):
        for tj in range(ntz):
            sub = (slice(ti * 64, ti * 64 + 64), slice(tj * 64, tj * 64 + 64))
            m_ = mat[sub]
            if (m_ == ".").all():
                continue
            hh = H[sub][m_ != "."]
            y0 = int(math.floor((hh.min() - 20) / 4) * 4)
            y1 = int(math.ceil((hh.max() + 6) / 4) * 4)
            flat = m_.ravel()
            rle = []
            k = 0
            while k < 4096:
                ch = flat[k]
                n = 1
                while k + n < 4096 and n < 64 and flat[k + n] == ch:
                    n += 1
                rle.append(ch + B64[n - 1])
                k += n
            cnt.update(flat.tolist())
            tx = int(round((G.X0 + ti * 64 * RES) / TILE))
            tz = int(round((G.Z0 + tj * 64 * RES) / TILE))
            glines.append("%d %d %d %d %s" % (tx, tz, y0, y1, "".join(rle)))
    gpages = paginate(glines)
    for n, pg in enumerate(gpages):
        open(os.path.join(OUT, "Ground_%d.txt" % (n + 1)), "w", newline="\n").write("\n".join(pg))
    log("ground tiles", len(glines), "pages", len(gpages), "chars", sum(len(l) + 1 for l in glines))

    # near detail (client): kit_pack Q records per 256-stud tile
    detail = defaultdict(list)
    tri_of = {pid: sum(p["tris"] for p in v["parts"].values()) for pid, v in kit.items()}
    tri_near = 0
    if STYLE == "clean":
        keep = []
        for t in trees:
            if t["fam"] == "bn":
                continue
            if t["fam"] == "cp":
                pid, ref = OLD_KIT["palm"][0] if R.random() < 0.55 else OLD_KIT["palm"][1]
                Hm = R.uniform(10.0, 15.0)
                s = Hm / ref
                t.update(pid=pid, s=s, sy=s)
            else:
                pid, ref = OLD_KIT["tree"]
                Dm = t["D"] / 3.0
                if t["fam"] == "rt":
                    Dm = min(max(Dm, 15.0), 25.0)
                    Dm = min(Dm, max(t["D"] / 3.0, 15.0))
                s = Dm / ref
                t.update(pid=pid, s=s, sy=s * R.uniform(0.92, 1.12))
            keep.append(t)
        trees[:] = keep
    for t in trees:
        key = (int(t["x"] // TILE), int(t["z"] // TILE))
        detail[key].append(("Q", t["pid"], t["x"], t["y"], t["z"], t["yaw"], t["s"], "TRE", t["sy"], t["s"]))
        tri_near += tri_of.get(t["pid"], 0)
    for s in shrubs:
        key = (int(s["x"] // TILE), int(s["z"] // TILE))
        detail[key].append(("Q", s["pid"], s["x"], s["y"], s["z"], s["yaw"], s["sx"], "TRE", s["sy"], s["sz"]))
        tri_near += tri_of.get(s["pid"], 0)
    # far looks (place): crowns 9 m and up, palms 14 m and up
    far = []
    for t in trees:
        if t["fam"] == "cp" and STYLE == "clean":
            Hm = (12.2 if t["pid"] == "op1" else 16.3) * t["s"]
            if Hm < 12:
                continue
            far.append("fp1 %.2f %.2f %.2f %.2f %.2f %.2f %.4f %d_%d" % (t["x"], t["y"], t["z"], M(7.0), M(Hm), M(7.0),
                                                                     t["yaw"], t["x"] // TILE, t["z"] // TILE))
            continue
        if STYLE == "clean":
            if t["D"] >= M(14.0):
                Dm = 18.3 * t["s"]
                far.append("ff1 %.2f %.2f %.2f %.2f %.2f %.2f %.4f %d_%d" % (t["x"], t["y"], t["z"], M(Dm) * 0.92,
                                                                         M(Dm) * 0.62 * t["sy"] / t["s"], M(Dm) * 0.85,
                                                                         t["yaw"], t["x"] // TILE, t["z"] // TILE))
            continue
        if t["fam"] == "cp":
            Hm = 17.0 * t["sy"]
            if Hm < 19:
                continue
            far.append("fp1 %.2f %.2f %.2f %.2f %.2f %.2f %.4f %d_%d" % (t["x"], t["y"], t["z"], t["D"] * 1.0, M(Hm),
                                                                     t["D"] * 1.0, t["yaw"], t["x"] // TILE, t["z"] // TILE))
        elif t["D"] >= M(13.0) and t["fam"] != "bn":
            kp = kit[t["pid"]]["parts"]
            hgt = (kp["TRC"]["centre"][1] + kp["TRC"]["size"][1] / 2) * t["sy"]
            far.append("ff1 %.2f %.2f %.2f %.2f %.2f %.2f %.4f %d_%d" % (t["x"], t["y"], t["z"], t["D"] * 0.96, hgt,
                                                                     t["D"] * 0.96, t["yaw"], t["x"] // TILE, t["z"] // TILE))
    fpages = paginate(far)
    for n, pg in enumerate(fpages):
        open(os.path.join(OUT, "Far_%d.txt" % (n + 1)), "w", newline="\n").write("\n".join(pg))

    # holding rbxmx: Data_<tag>G + ground / far pages + the Studio tool
    ktmp = os.path.join(OUT, "_kit.rbxmx")
    kst = kit_pack.write_rbxmx(ktmp, "Data_%sG" % TAG, detail, TILE)
    kx = open(ktmp, encoding="utf-8").read()
    os.remove(ktmp)
    inner = kx[kx.index('<Item class="Folder"'):kx.rindex("</roblox>")]
    items = [inner]
    ref = 100000
    for n in range(len(gpages)):
        items.append(sv(ref, "Ground_%d" % (n + 1), open(os.path.join(OUT, "Ground_%d.txt" % (n + 1))).read()))
        ref += 1
    for n in range(len(fpages)):
        items.append(sv(ref, "Far_%d" % (n + 1), open(os.path.join(OUT, "Far_%d.txt" % (n + 1))).read()))
        ref += 1
    for nm_, lines_ in (("Cols", ["%.1f %.1f %.2f %d" % (c[0], c[1], c[2], 1 if c[3] else 0) for c in ED["cols"]]),
                        ("Models", ED["models"])):
        for n, pg in enumerate(paginate(lines_)):
            items.append(sv(ref, "%s_%d" % (nm_, n + 1), "\n".join(pg)))
            ref += 1
    epages = paginate(edge_parts)
    for n, pg in enumerate(epages):
        open(os.path.join(OUT, "Edge_%d.txt" % (n + 1)), "w", newline="\n").write("\n".join(pg))
        items.append(sv(ref, "Edge_%d" % (n + 1), "\n".join(pg)))
        ref += 1
    tool = open(os.path.join(ROOT, "tools", "yangon", "YangonGreen1to1.luau"), encoding="utf-8").read().replace("\r\n", "\n")
    assert "]]>" not in tool
    items.append('<Item class="ModuleScript" referent="R%d"><Properties><string name="Name">YangonGreen1to1</string>'
                 '<ProtectedString name="Source"><![CDATA[%s]]></ProtectedString></Properties></Item>' % (ref, tool))
    xmls = ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
           'version="4"><Item class="Folder" referent="RH"><Properties><string name="Name">GreenHolding_%s</string>'
           '</Properties>%s</Item></roblox>' % (TAG, "".join(items)))
    rpath = os.path.join(ROOT, "imports", "sync", "ygn1to1_green", "green_%s.rbxmx" % TAG.lower())
    open(rpath, "w", encoding="utf-8", newline="\n").write(xmls)
    import xml.dom.minidom
    xml.dom.minidom.parseString(xmls.encode("utf-8"))

    # stats
    area_km2 = land.sum() * RES * RES / 9.0 / 1e6
    canopy = cov[land].mean()
    by_zone = {}
    for zname in ZONES:
        mk = land & (zone == Z[zname])
        if mk.sum() > 2000:
            by_zone[zname] = dict(ha=round(mk.sum() * 16 / 9 / 1e4, 1), canopy=round(float(cov[mk].mean()), 3),
                                  target=TARGET[zname])
    lakeb = {}
    for a, b in ((0, 15), (15, 50), (50, 150)):
        mk = land & (d_wat > M(a)) & (d_wat <= M(b))
        lakeb["%d-%d m" % (a, b)] = round(float(cov[mk].mean()), 3)
    fams = Counter(t["fam"] for t in trees)
    st = dict(tag=TAG, style=STYLE, edges=ED["stats"], lake_edge_parts=len(edge_parts), bund_m=round(edge_len / 3), land_km2=round(area_km2, 2), trees=len(trees), street_trees=sum(nst.values()),
              per_road=dict(nst), fill_trees=nfill, by_family=dict(fams), shrubs=dict(Counter(s["pid"] for s in shrubs)),
              canopy_share=round(float(canopy), 3), canopy_by_zone=by_zone, lake_bands=lakeb,
              crown_m=dict(p10=round(np.percentile([t["D"] / 3 for t in trees], 10), 1),
                           median=round(np.median([t["D"] / 3 for t in trees]), 1),
                           p90=round(np.percentile([t["D"] / 3 for t in trees], 90), 1)),
              far_parts=len(far), near_records=sum(len(v) for v in detail.values()), near_tiles=len(detail),
              near_tris_district=tri_near, kit_pack=kst,
              ground=dict((k, round(v / max(1, sum(c for kk, c in cnt.items() if kk != ".")), 3)) for k, v in cnt.items()
                          if k != "."),
              ground_tiles=len(glines), ground_chars=sum(len(l) + 1 for l in glines), rbxmx_bytes=len(xmls.encode("utf-8")),
              seconds=round(time.time() - T0, 1))
    json.dump(st, open(os.path.join(OUT, "stats.json"), "w"), indent=1)
    json.dump([[t["fam"], t["pid"], round(t["x"], 1), round(t["z"], 1), round(t["D"], 1)] for t in trees],
              open(os.path.join(OUT, "trees.json"), "w"))
    preview(mat, cov, trees, shrubs, G, bld, road | deck)
    print(json.dumps({k: v for k, v in st.items() if k not in ("kit_pack",)}, indent=1))


LAKE_LEVEL = 40.5        # Inya Lake at 1:1 (13.5 m x 3)
BUND_ROADS = ("Kabar Aye Pagoda Road", "Pyay Road")   # where the lake runs straight beside these, the edge is a bund
BUND_NEAR = 170.0        # studs from the road's centre line (~57 m: road, pavement, grass strip, walkway)
BUND_MIN = 120.0         # shortest bund run (studs)
WALK_W = 9.0             # walkway 3 m
WALL_T = 1.2             # wall 0.4 m
WALK_UP = 3.6            # walkway top over the water (1.2 m)
LIP = 0.6                # wall top over the walkway
RAIL_H = 3.3             # rail top over the walkway (1.1 m)
POST_GAP = 7.5           # a post every 2.5 m


def lake_edge(G, water, prof, H, lmk, outside):
    """Inya Lake's edge (research section 2 'Bank types'): where the lake runs straight beside Kabar Aye Pagoda Road /
    Pyay Road, a bund: concrete wall straight down into the water + steel railing + a 3 m walkway on the land side
    (the grass strip behind it is the clean terrain lawn). Elsewhere a natural bank (trees and grass to the water: no
    parts). Returns (part lines "CODE x y z sx sy sz yaw", mask of the walkway corridor (no trees), bund length)."""
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from scipy.ndimage import label
    from shapely.geometry import LineString as LS, Point as Pt
    from shapely.ops import unary_union
    lab, n = label(water)
    if n == 0:
        return [], np.zeros(water.shape, bool), 0.0
    big = int(np.argmax(np.bincount(lab.ravel())[1:]) + 1)
    d_out = distance_transform_edt(~outside) * RES
    lake = lab == big
    nx, nz = lake.shape
    xs = G.X0 + np.arange(nx) * RES + RES / 2
    zs = G.Z0 + np.arange(nz) * RES + RES / 2
    fig = plt.figure()
    cs = plt.contour(xs, zs, lake.T.astype(float), [0.5])
    segs = [np.asarray(s_) for s_ in cs.allsegs[0] if len(s_) > 20]
    plt.close(fig)
    roads = [LS([(q[0], q[2]) for q in e["pts"]]) for e in prof if e.get("name") in BUND_ROADS and len(e["pts"]) > 1]
    if not roads:
        return [], np.zeros(water.shape, bool), 0.0
    RD = unary_union(roads)
    boxes = LANDMARK_BOXES.get(TAG, [])
    x_lo, x_hi = G.X0 + 8, G.X0 + nx * RES - 8
    z_lo, z_hi = G.Z0 + 8, G.Z0 + nz * RES - 8

    def is_water(x, z):
        i, j = int((x - G.X0) / RES), int((z - G.Z0) / RES)
        return 0 <= i < nx and 0 <= j < nz and bool(lake[i, j])

    runs = []
    for sg in segs:
        ok = []
        for x, z in sg:
            ii, jj = min(max(int((x - G.X0) / RES), 0), nx - 1), min(max(int((z - G.Z0) / RES), 0), nz - 1)
            inside = x_lo < x < x_hi and z_lo < z < z_hi and d_out[ii, jj] > 16
            near = RD.distance(Pt(x, z)) < BUND_NEAR
            in_l = any(b[0] - 30 < x < b[2] + 30 and b[1] - 30 < z < b[3] + 30 for b in boxes)
            ok.append(inside and near and not in_l)
        cur = []
        for k, flag in enumerate(ok):
            if flag:
                cur.append(sg[k])
            elif cur:
                runs.append(cur)
                cur = []
        if cur:
            runs.append(cur)
    parts = []
    mask_img = G.blank()
    dr = ImageDraw.Draw(mask_img)
    total = 0.0
    for run in runs:
        line = LS(run).simplify(6.0)
        if line.length < BUND_MIN:
            continue
        # smooth: resample every ~24 studs along the simplified line
        nseg = max(1, int(line.length // 24))
        P = np.array([line.interpolate(line.length * k / nseg).coords[0] for k in range(nseg + 1)])
        total += line.length
        top = LAKE_LEVEL + WALK_UP
        rail_cum = 0.0
        for k in range(len(P) - 1):
            a, b = P[k], P[k + 1]
            d = b - a
            L = float(np.hypot(*d))
            if L < 1.0:
                continue
            u = d / L
            nrm = np.array([-u[1], u[0]])
            mid = (a + b) / 2
            # landward = the side that is not lake
            if is_water(*(mid + nrm * 6)) and not is_water(*(mid - nrm * 6)):
                nrm = -nrm
            alt = 0.06 * (k % 2)           # neighbours differ: no shared planes at the joints (flicker rule)
            yaw = math.atan2(-u[1], u[0])  # CFrame.Angles(0, yaw, 0): local X along the segment
            wc = mid + nrm * 1.2           # wall stands just inside the land edge
            wt = WALL_T + 2 * alt
            wall_bot = LAKE_LEVEL - 5.0
            wall_top = top + LIP + alt
            parts.append("WALL %.2f %.2f %.2f %.2f %.2f %.2f %.5f" % (wc[0], (wall_bot + wall_top) / 2, wc[1], L + wt,
                                                                    wall_top - wall_bot, wt, yaw))
            kc = wc + nrm * (wt / 2 - 0.1 + WALK_W / 2)
            parts.append("WALK %.2f %.2f %.2f %.2f %.2f %.2f %.5f" % (kc[0], top - 2.0 + alt, kc[1], L + 0.4, 4.0, WALK_W,
                                                                    yaw))
            # rails (top + middle) on the wall, posts every POST_GAP
            for hh, th in ((RAIL_H, 0.3), (RAIL_H * 0.55, 0.22)):
                parts.append("RAIL %.2f %.2f %.2f %.2f %.2f %.2f %.5f" % (wc[0], top + hh - th / 2 + alt, wc[1], L, th, th,
                                                                        yaw))
            s_ = (POST_GAP - rail_cum) % POST_GAP
            while s_ < L:
                p_ = a + u * s_ + nrm * 1.2
                parts.append("POST %.2f %.2f %.2f %.2f %.2f %.2f %.5f" % (p_[0], top + LIP + (RAIL_H - LIP) / 2 + 0.02, p_[1],
                                                                        0.3, RAIL_H - LIP - 0.04, 0.3, yaw))
                s_ += POST_GAP
            rail_cum = (rail_cum + L) % POST_GAP
            # the walkway corridor (no trees, ground fixed under it in Studio)
            far_ = wc + nrm * (wt / 2 + WALK_W + M(1.0))
            q = [a + nrm * 0.0, b + nrm * 0.0, b + (far_ - wc) + nrm * 1.2, a + (far_ - wc) + nrm * 1.2]
            G.poly(dr, [tuple(v) for v in q])
    mask = G.arr(mask_img)
    return parts, mask, total


def sv(ref, name, value):
    return ('<Item class="StringValue" referent="R%d"><Properties><string name="Name">%s</string>'
            '<string name="Value">%s</string></Properties></Item>' % (ref, name, escape(value)))


def paginate(lines):
    pages, cur, size = [], [], 0
    for ln in lines:
        if cur and size + len(ln) + 1 > CHARS:
            pages.append(cur)
            cur, size = [], 0
        cur.append(ln)
        size += len(ln) + 1
    if cur:
        pages.append(cur)
    return pages


def preview(mat, cov, trees, shrubs, G, bld, road):
    col = {"L": (96, 140, 60), "D": (175, 165, 105), "P": (165, 140, 105), "E": (165, 105, 70), "G": (150, 145, 135),
           "M": (90, 75, 60), "C": (190, 188, 182), "S": (210, 205, 195), ".": (40, 70, 110)}
    img = np.zeros(mat.shape + (3,), np.uint8)
    for k, v in col.items():
        img[mat == k] = v
    img[road] = (60, 60, 64)
    img[bld] = (235, 235, 240)
    im = Image.fromarray(img.transpose(1, 0, 2))
    dr = ImageDraw.Draw(im, "RGBA")
    for t in trees:
        i, j = G.ij(t["x"], t["z"])
        r = t["r"] / RES
        c = {"rt": (20, 70, 20, 150), "bl": (40, 100, 30, 150), "mg": (15, 50, 25, 160), "mh": (25, 60, 35, 150),
             "cp": (120, 160, 40, 170), "bn": (140, 190, 60, 170)}[t["fam"]]
        dr.ellipse([i - r, j - r, i + r, j + r], fill=c)
    for s in shrubs:
        i, j = G.ij(s["x"], s["z"])
        dr.rectangle([i - 1, j - 1, i + 1, j + 1], fill=(220, 40, 150, 255) if s["pid"] == "bv1" else (30, 120, 30, 255))
    im.save(os.path.join(OUT, "preview.png"))
    w = 700
    crop = im.crop((800, 800, 800 + w, 800 + w)).resize((1400, 1400), Image.NEAREST)
    crop.save(os.path.join(OUT, "preview_zoom.png"))


if __name__ == "__main__":
    main()
