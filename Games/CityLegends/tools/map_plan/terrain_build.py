"""Riviera terrain: a 4-stud height and material grid for the whole map, cut into 64 x 64 tiles
(build/riviera/tile_<i>_<j>.json) plus build/riviera/meta.json, for tools/riviera_terrain.luau to
write into Studio with Terrain:WriteVoxels.

Ground = real heights (data/dem25.json, EU-DEM 25 m) at 1.6 studs a metre across and 1 stud a
metre up; sea outside the OpenStreetMap coastline (deeper further out); long piers and
breakwaters as concrete quays; the roads (network.py) flattened into the ground as asphalt with
pavements, with cut banks (rock) and fills; tunnels left in the hill (carved later in Studio).

usage (from Games/CityLegends): python -I tools/map_plan/terrain_build.py tools/map_plan build/riviera
"""
import os, sys, json, math
import numpy as np
D, OUT = sys.argv[1], sys.argv[2]
sys.path.insert(0, D)
import network
from network import SPM, VS, OX, OZ
from geo import load
from base import coast_chains

os.makedirs(OUT, exist_ok=True)
CELL = 4
TILE = 64
# world frame (studs), multiples of the tile size
# the plan area plus about 1 km of hills round it (coarse heights) and 2 km of open sea
X0 = OX - 5184; X1 = OX + 5312
Z0 = OZ - 2880; Z1 = OZ + 4352
NX = (X1 - X0) // CELL; NZ = (Z1 - Z0) // CELL
print("grid", NX, "x", NZ, "cells")
xs = X0 + CELL * (np.arange(NX) + 0.5)
zs = Z0 + CELL * (np.arange(NZ) + 0.5)
PX = (xs - OX) / SPM                      # plan metres along the coast
PY = -(zs - OZ) / SPM                     # plan metres inland
GX, GY = np.meshgrid(PX, PY)              # [z, x]

# ---- natural ground from the dense DEM (bilinear)
dem = network.Dem(D)
H = np.array([[v if v is not None else np.nan for v in row] for row in dem.h], dtype=float)
fi = (GX - dem.x0) / dem.s; fj = (GY - dem.y0) / dem.s
i0 = np.clip(np.floor(fi).astype(int), 0, dem.nx - 2); j0 = np.clip(np.floor(fj).astype(int), 0, dem.ny - 2)
a = np.clip(fi - i0, 0, 1); b = np.clip(fj - j0, 0, 1)
def g(jj, ii):
    v = H[jj, ii]
    return np.where(np.isnan(v), 0.0, v)
nat = (g(j0, i0) * (1 - a) * (1 - b) + g(j0, i0 + 1) * a * (1 - b) + g(j0 + 1, i0) * (1 - a) * b + g(j0 + 1, i0 + 1) * a * b) * VS
# outside the dense grid: the coarse 30 x 30 grid
from geo import Elev
coarse = Elev(os.path.join(D, "data", "elev.json"))
cg = np.vectorize(lambda x, y: coarse.at(x, y))(GX, GY) * VS
# how far inside the dense grid (metres; negative outside); the coarse heights fade in over the last 400 m
din = np.minimum(np.minimum(GX - dem.x0, dem.x0 + dem.s * (dem.nx - 1) - GX), np.minimum(GY - dem.y0, dem.y0 + dem.s * (dem.ny - 1) - GY))
w_out = np.clip(1 - din / 400.0, 0, 1)
w_out = w_out * w_out * (3 - 2 * w_out)
nat = nat * (1 - w_out) + cg * w_out
# the mountains behind the city at their true steepness (the town keeps the gentler 0.75 a metre so
# its streets stay drivable): every stud above 170 counts 2.3 times
nat = nat + np.maximum(nat - 170.0, 0) * 1.3

# ---- land and sea (scanline fill of the coastline polygon, in plan metres)
ways = load(os.path.join(D, "data", "monaco.json"))
chain = max(coast_chains(ways), key=len)
poly = chain + [(9000, 9000), (-9000, 9000)]
land = np.zeros((NZ, NX), dtype=bool)
P = np.array(poly)
x1, y1 = P[:, 0], P[:, 1]; x2, y2 = np.roll(x1, -1), np.roll(y1, -1)
for r, y in enumerate(PY):
    m = (y1 > y) != (y2 > y)
    xc = np.sort(x1[m] + (y - y1[m]) * (x2[m] - x1[m]) / (y2[m] - y1[m]))
    cnt = np.searchsorted(xc, PX)
    land[r] = (cnt % 2) == 1

# distance (cells) from the shore, both ways, by growing the mask (8-neighbour steps, capped)
def grow_dist(mask, cap):
    dd = np.where(mask, 0, cap).astype(np.int32)
    cur = mask.copy()
    for k in range(1, cap):
        nxt = cur.copy()
        nxt[1:] |= cur[:-1]; nxt[:-1] |= cur[1:]; nxt[:, 1:] |= cur[:, :-1]; nxt[:, :-1] |= cur[:, 1:]
        new = nxt & ~cur
        if not new.any():
            break
        dd[new] = k
        cur = nxt
    return dd
print("distances...")
d_sea = grow_dist(~land, 40)    # cells from the nearest sea (on land)
d_land = grow_dist(land, 120)   # cells from the nearest land (at sea)

ground = np.where(land, np.maximum(nat, 2.0), 0.0)
# the shore: land rises from 2 studs at the water over the first 12 studs
shore = land & (d_sea <= 3)
ground = np.where(shore, np.minimum(ground, 2.0 + d_sea * 3.0), ground)
seabed = -(4.0 + np.minimum(d_land * CELL * 0.08, 36.0))
height = np.where(land, ground, seabed)

MAT = {"Water": "W", "Sand": "S", "Rock": "R", "Limestone": "L", "Grass": "G", "LeafyGrass": "F", "Ground": "D",
       "Asphalt": "A", "Pavement": "P", "Concrete": "C", "Mud": "M"}
mat = np.full((NZ, NX), "G", dtype="<U1")
mat[~land] = "S"

# ---- quays: long piers and breakwaters
def stamp_line(pts, half, h, m):
    for (ax, ay), (bx, by) in zip(pts, pts[1:]):
        L = math.hypot(bx - ax, by - ay)
        n = max(1, int(L / 3))
        for k in range(n + 1):
            px, py = ax + (bx - ax) * k / n, ay + (by - ay) * k / n
            X, Z = network.world(px, py)
            ci, cj = int((X - X0) / CELL), int((Z - Z0) / CELL)
            rr = int(half * SPM / CELL) + 1
            for dj in range(-rr, rr + 1):
                for di in range(-rr, rr + 1):
                    ii, jj = ci + di, cj + dj
                    if 0 <= ii < NX and 0 <= jj < NZ and math.hypot(di, dj) * CELL <= half * SPM:
                        height[jj, ii] = max(height[jj, ii], h); mat[jj, ii] = m
for w in ways:
    t = w["tags"]
    L = sum(math.hypot(w["pts"][k][0] - w["pts"][k - 1][0], w["pts"][k][1] - w["pts"][k - 1][1]) for k in range(1, len(w["pts"])))
    if t.get("man_made") == "breakwater" or (t.get("man_made") == "pier" and L > 140):
        stamp_line(w["pts"], 9 if t.get("man_made") == "breakwater" else 6, 3.0, "C")

# ---- beaches (OSM natural=beach areas)
for w in ways:
    if w["tags"].get("natural") == "beach" and len(w["pts"]) > 3:
        Q = np.array(w["pts"]); qx1, qy1 = Q[:, 0], Q[:, 1]; qx2, qy2 = np.roll(qx1, -1), np.roll(qy1, -1)
        rows = np.where((PY >= Q[:, 1].min() - 5) & (PY <= Q[:, 1].max() + 5))[0]
        for r in rows:
            y = PY[r]; m = (qy1 > y) != (qy2 > y)
            if not m.any():
                continue
            xc = np.sort(qx1[m] + (y - qy1[m]) * (qx2[m] - qx1[m]) / (qy2[m] - qy1[m]))
            inside = (np.searchsorted(xc, PX) % 2) == 1
            sel = inside & land[r]
            mat[r][sel] = "S"
            height[r][sel] = np.minimum(height[r][sel], 1.5 + d_sea[r][sel] * 0.8)

# ---- districts (town ground is paved)
from geo import Elev
ns = {"el": Elev(os.path.join(D, "data", "elev.json"))}
exec(open(os.path.join(D, "layout.py"), encoding="utf-8").read(), ns)
urban = np.zeros((NZ, NX), dtype=bool)
for name, pts, col in ns["DISTRICTS"]:
    if "Terraces" in name:
        continue
    Q = np.array(pts); qx1, qy1 = Q[:, 0], Q[:, 1]; qx2, qy2 = np.roll(qx1, -1), np.roll(qy1, -1)
    for r, y in enumerate(PY):
        m = (qy1 > y) != (qy2 > y)
        if not m.any():
            continue
        xc = np.sort(qx1[m] + (y - qy1[m]) * (qx2[m] - qx1[m]) / (qy2[m] - qy1[m]))
        urban[r] |= (np.searchsorted(xc, PX) % 2) == 1
urban &= land

# ---- roads: flatten the ground to each road, pavements, banks
print("roads...")
roads = network.build(D)
best = np.full((NZ, NX), np.inf)      # distance to the nearest road centre (studs)
road_y = np.zeros((NZ, NX))
road_kind = np.zeros((NZ, NX), dtype=np.int8)
tunnels = []
for rd in roads:
    sm = rd["samples"]
    for k, s in enumerate(sm):
        # automatic tunnels: the road far below the hill on the long routes (less deep: an open cutting)
        if s["tunnel"] or (rd["kind"] == "route" and s["ground"] - s["y"] > 45):
            tunnels.append([s["x"], s["y"], s["z"], s["dx"], s["dz"]])
            continue
        R = 42 + 130
        ci0 = max(int((s["x"] - R - X0) / CELL), 0); ci1 = min(int((s["x"] + R - X0) / CELL) + 1, NX)
        cj0 = max(int((s["z"] - R - Z0) / CELL), 0); cj1 = min(int((s["z"] + R - Z0) / CELL) + 1, NZ)
        if ci0 >= ci1 or cj0 >= cj1:
            continue
        sx = xs[ci0:ci1][None, :]; sz = zs[cj0:cj1][:, None]
        dist = np.hypot(sx - s["x"], sz - s["z"])
        sub = best[cj0:cj1, ci0:ci1]
        closer = dist < sub
        sub[closer] = dist[closer]
        road_y[cj0:cj1, ci0:ci1][closer] = s["y"]
        road_kind[cj0:cj1, ci0:ci1][closer] = 1 if rd["kind"] == "route" else 2
ROAD, WALK = 32.0, 42.0
near = best < WALK + 130
diff = road_y - height
bank = np.minimum(np.abs(diff) * 1.3 + 6, 130)       # how far the bank reaches past the pavement
t = np.clip((best - WALK) / bank, 0, 1)
t = t * t * (3 - 2 * t)                                 # smoothstep
blend = np.where(best <= WALK, 1.0, 1.0 - t)
newh = road_y * blend + height * (1 - blend)
apply = near & (blend > 0)
height = np.where(apply, newh, height)
# town ground is paved only along its streets (buildings stand there); further off it stays natural
urban &= best < 150
on_road = best <= ROAD
on_walk = (best > ROAD) & (best <= WALK)
cut = apply & ~on_road & ~on_walk & (diff < -8)
mat[on_road] = "A"
mat[on_walk & (urban | (road_kind == 2))] = "P"
mat[on_walk & ~(urban | (road_kind == 2))] = "D"

# ---- surface materials off the roads
gz, gx = np.gradient(height, CELL)
slope = np.hypot(gx, gz)
free = land & ~on_road & ~on_walk & (mat != "C") & (mat != "S")
rng = np.random.default_rng(7)
noise = rng.random((NZ, NX))
mat[free & (slope < 0.6) & urban] = "P"
mat[free & (slope < 0.6) & ~urban & (noise < 0.45)] = "F"
mat[free & (slope < 0.6) & ~urban & (height > 230) & (noise > 0.7)] = "D"
mat[free & (slope >= 0.6) & (slope < 1.0)] = "R"
mat[free & (slope >= 1.0)] = "L"
mat[cut & (slope >= 0.6)] = "L"

# ---- write tiles
meta = {"x0": int(X0), "z0": int(Z0), "cell": CELL, "tile": TILE, "nx": int(NX), "nz": int(NZ), "tiles": [],
        "mats": {v: k for k, v in MAT.items()}, "tunnels": tunnels, "ox": OX, "oz": OZ}
for tj in range(0, NZ, TILE):
    for ti in range(0, NX, TILE):
        hh = height[tj:tj + TILE, ti:ti + TILE]
        mm = mat[tj:tj + TILE, ti:ti + TILE]
        name = "tile_%d_%d.json" % (ti // TILE, tj // TILE)
        json.dump({"i": ti, "j": tj, "w": int(hh.shape[1]), "d": int(hh.shape[0]),
                   "h": [int(round(v * 4)) for v in hh.flatten()], "m": "".join(mm.flatten())},
                  open(os.path.join(OUT, name), "w"), separators=(",", ":"))
        meta["tiles"].append(name)
json.dump(meta, open(os.path.join(OUT, "meta.json"), "w"), separators=(",", ":"))
# a small preview: heights and materials
try:
    import zlib, struct
    col = {"W": (40, 90, 140), "S": (214, 196, 150), "R": (110, 104, 96), "L": (190, 184, 168), "G": (120, 150, 80),
           "F": (95, 135, 70), "D": (140, 120, 90), "A": (45, 45, 48), "P": (170, 165, 158), "C": (200, 198, 192), "M": (90, 80, 70)}
    img = np.zeros((NZ, NX, 3), dtype=np.uint8)
    for k, c in col.items():
        img[mat == k] = c
    sea = height < 0
    img[sea] = (np.array([30, 80, 130]) * (1 + height[sea, None] / 80)).clip(0, 255).astype(np.uint8)
    shade = np.clip(1 - gx * 0.6 + gz * 0.3, 0.55, 1.25)[..., None]
    img = (img * shade).clip(0, 255).astype(np.uint8)
    raw = b"".join(b"\x00" + img[r].tobytes() for r in range(NZ))
    def chunk(t, data):
        return struct.pack(">I", len(data)) + t + data + struct.pack(">I", zlib.crc32(t + data) & 0xffffffff)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", NX, NZ, 8, 2, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw, 6)) + chunk(b"IEND", b"")
    open(os.path.join(OUT, "preview.png"), "wb").write(png)
except Exception as e:
    print("preview failed", e)
print("tiles", len(meta["tiles"]), "tunnel samples", len(tunnels), "height range", float(height.min()), float(height.max()))
