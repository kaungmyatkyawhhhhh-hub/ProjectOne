"""
City Legends minimap art (owner, 2026-11-03: "make the mini map look way better and smoother").

Renders the Monaco map (the Riviera) as picture tiles for the minimap and the full map, instead of
~3,000 plain frames: the sea with a lighter shore, the land shaded by its height (hills read as
hills), green and sand where the terrain is grass or beach, every building's footprint, and the
roads with pavements, dark edges and rounded joins (the three long routes in gold). Also the
round rim and the player arrow.

Inputs (all in build/, from the map tools):
  build/riviera/meta.json + tile_*.json   the terrain grid (4 studs a cell: height + material)
  build/riviera/roads.json                road centre lines and half widths
  build/minimap/buildings.txt             footprints from the open place (written by the MCP)
  build/minimap/extra.json                car parks (the marina deck as cell runs + bay lines)
Output: build/minimap/tile_<col>_<row>.png (1024 x 512 each: bigger pictures didn't load in
Studio), rim.png, arrow.png, and with --lua <ids.json> the module src/client/MinimapArt.lua.

Run from Games/CityLegends:  python tools/minimap_art.py   then upload the PNGs and
python tools/minimap_art.py --lua build/minimap/ids.json
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
RIV = os.path.join(ROOT, "build", "riviera")
OUT = os.path.join(ROOT, "build", "minimap")

# the area drawn (world studs) and its scale: 2 studs a pixel = the minimap's close zoom, 1:1
# (x0 moved west 560 studs on 2026-11-04 so the Riviera Highway's valley is on the map)
X0, Z0 = 9640, -3000
SPP = 2.0
TILE_W, TILE_H = 1024, 512
COLS, ROWS = 4, 5
W, H = TILE_W * COLS, TILE_H * ROWS  # 4096 x 2560 px = 8192 x 5120 studs
SS = 2  # drawn at twice the size, then shrunk (smooth edges)

# a night map, like the HUD
SEA = (14, 36, 64)
SEA_SHORE = (30, 70, 108)
LAND = (34, 40, 48)
GRASS = (34, 46, 42)
SAND = (82, 76, 60)
ROCK = (38, 42, 48) # (close to the land: the slope bands drew diagonal streaks)
QUAY = (50, 54, 62)
BUILDING = (60, 68, 84)
BUILDING_EDGE = (92, 102, 122)
SHADOW = (18, 22, 28)
PAVEMENT = (64, 68, 80)
EDGE = (12, 14, 18)
STREET = (156, 164, 180)
ROUTE = (222, 184, 98)


def to_px(x, z, ss=SS):
    return ((x - X0) / SPP * ss, (z - Z0) / SPP * ss)


def terrain():
    meta = json.load(open(os.path.join(RIV, "meta.json")))
    nx, nz, cell = meta["nx"], meta["nz"], meta["cell"]
    tx0, tz0 = meta["x0"], meta["z0"]
    hgt = np.zeros((nz, nx), np.float32)
    mat = np.full((nz, nx), ord("W"), np.uint8)
    for name in meta["tiles"]:
        t = json.load(open(os.path.join(RIV, name)))
        i0, j0, w, d = t["i"], t["j"], t["w"], t["d"]
        hh = np.array(t["h"], np.float32).reshape(d, w)
        mm = np.frombuffer(t["m"].encode(), np.uint8).reshape(d, w)
        hgt[j0:j0 + d, i0:i0 + w] = hh
        mat[j0:j0 + d, i0:i0 + w] = mm
    return hgt, mat, tx0, tz0, cell


def box_blur(a, r):
    # separable box blur of radius r (cumulative sums), edges held
    pad = np.pad(a, r, mode="edge")
    c = np.cumsum(pad, axis=0)
    c = np.vstack([np.zeros((1, c.shape[1])), c])
    a1 = (c[2 * r + 1:] - c[:-2 * r - 1]) / (2 * r + 1)
    c = np.cumsum(a1, axis=1)
    c = np.hstack([np.zeros((c.shape[0], 1)), c])
    return ((c[:, 2 * r + 1:] - c[:, :-2 * r - 1]) / (2 * r + 1)).astype(np.float32)


def base_layer():
    """The ground picture at the final size (W x H): sea, land colours, hill shading, shore."""
    hgt, mat, tx0, tz0, cell = terrain()
    # sample the 4-stud grid at each final pixel (2 studs)
    xs = X0 + (np.arange(W) + 0.5) * SPP
    zs = Z0 + (np.arange(H) + 0.5) * SPP
    fi = (xs - tx0) / cell - 0.5
    fj = (zs - tz0) / cell - 0.5
    i0 = np.clip(np.floor(fi).astype(int), 0, hgt.shape[1] - 2)
    j0 = np.clip(np.floor(fj).astype(int), 0, hgt.shape[0] - 2)
    ti = np.clip(fi - i0, 0, 1)[None, :]
    tj = np.clip(fj - j0, 0, 1)[:, None]
    inside = ((xs >= tx0) & (xs < tx0 + hgt.shape[1] * cell))[None, :] & ((zs >= tz0) & (zs < tz0 + hgt.shape[0] * cell))[:, None]

    def bilerp(a):
        a00 = a[j0][:, i0]
        a01 = a[j0][:, i0 + 1]
        a10 = a[j0 + 1][:, i0]
        a11 = a[j0 + 1][:, i0 + 1]
        return (a00 * (1 - ti) + a01 * ti) * (1 - tj) + (a10 * (1 - ti) + a11 * ti) * tj

    # (heights are stored x4; the sea is below 0: its bed is sand, not a water material)
    water = (hgt < 0).astype(np.float32)
    wet = bilerp(water)
    wet[~inside] = 1.0
    wet[(zs < tz0)[:, None].repeat(W, axis=1)] = 0.0  # north of the terrain grid: the hills go on
    wet = box_blur(box_blur(wet, 2), 2)  # (the 4-stud cells would show as steps along the coast)
    h = np.maximum(bilerp(hgt) / 4.0, 0)
    # land colour by material (smoothed so patches blend)
    cols = {"G": GRASS, "F": GRASS, "S": SAND, "R": ROCK, "L": ROCK, "C": QUAY}
    img = np.zeros((H, W, 3), np.float32)
    img[:] = LAND
    for ch, col in cols.items():
        m = bilerp((mat == ord(ch)).astype(np.float32))
        if ch in "GFRL":
            m = box_blur(m, 10) * 0.8  # soft patches, never hard bands
        m = np.clip(m, 0, 1)[..., None]
        img = img * (1 - m) + np.array(col, np.float32) * m
    # hill shading: light from the north-west, on smoothed heights (the 25 m height data shows
    # its grid as streaks otherwise)
    hs = box_blur(box_blur(h, 10), 10)
    gy, gx = np.gradient(hs)
    shade = (-gx * 0.7 - gy * 0.7) * 0.25
    shade = np.clip(shade, -0.25, 0.25)
    img *= (1 + shade)[..., None]
    # higher ground a touch lighter
    img *= (1 + np.clip(h / max(h.max(), 1), 0, 1) * 0.12)[..., None]
    # the sea, lighter near the shore
    land = (wet < 0.5).astype(np.float32)
    landImg = Image.fromarray((land * 255).astype(np.uint8))
    near = np.asarray(landImg.filter(ImageFilter.GaussianBlur(14)), np.float32) / 255
    sea = np.array(SEA, np.float32) * (1 - near[..., None] * 1.6).clip(0, 1) + np.array(SEA_SHORE, np.float32) * (near[..., None] * 1.6).clip(0, 1)
    edge = np.clip((0.5 - np.abs(wet - 0.5)) * 2, 0, 1)  # a soft coast line
    sw = np.clip((wet - 0.42) / 0.16, 0, 1)[..., None]
    img = img * (1 - sw) + sea * sw
    img += (edge[..., None] * 18)
    return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))


def buildings_layer(draw_shadow, draw_body):
    path = os.path.join(OUT, "buildings.txt")
    if not os.path.exists(path):
        print("no buildings.txt: buildings left out")
        return
    for ln in open(path).read().split("\n"):
        f = ln.split(",")
        if len(f) < 7:
            continue
        tag = f[0]
        cx, cz, sx, sz, yaw = map(float, f[1:6])
        if tag in ("o", "s") and (sx > 300 or sz > 300):
            continue
        # footprint corners: LookVector = (sin yaw, cos yaw) is the box's -Z axis
        lx, lz = math.sin(yaw), math.cos(yaw)
        rx, rz = lz, -lx
        hx, hz = sx / 2, sz / 2
        pts = []
        for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
            wx = cx + rx * hx * a + lx * hz * b
            wz = cz + rz * hx * a + lz * hz * b
            pts.append(to_px(wx, wz))
        off = 3 * SS
        draw_shadow.polygon([(p[0] + off, p[1] + off) for p in pts], fill=SHADOW)
        draw_body.polygon(pts, fill=BUILDING, outline=BUILDING_EDGE, width=SS)


def roads_layer(draw):
    data = json.load(open(os.path.join(RIV, "roads.json")))
    hw = os.path.join(RIV, "highway.json")  # the Riviera Highway (tools/map_plan/highway.py)
    if os.path.exists(hw):
        data["roads"] = data["roads"] + json.load(open(hw))["roads"]
    north = os.path.join(RIV, "north.json")  # the north roads (tools/map_plan/north_roads.py)
    if os.path.exists(north):
        data["roads"] = data["roads"] + json.load(open(north))["roads"]
    hairpin = os.path.join(RIV, "hairpin.json")  # the Grand Hairpin replaces a stretch of the West Switchbacks
    if os.path.exists(hairpin):
        hp = json.load(open(hairpin))
        for r in data["roads"]:
            if r["name"] == "West Switchbacks":
                mid = [[q[0], q[1], q[2], q[3], q[4], 0, q[5], q[5]] for q in hp["s"]]
                r["s"] = r["s"][:hp["from"]] + mid + r["s"][hp["to"] + 1:]
    # the straight link (owner, 2026-11-06; tools/riviera/StraightLink.luau): the top of the West Switchbacks
    # carries straight on into the Mountain Road, no bend back
    for r in data["roads"]:
        if r["name"] == "West Switchbacks":
            s = r["s"]
            k = max(i for i, q in enumerate(s) if 10900 < q[0] < 10925 and q[2] < -170)
            q = s[k]
            r["s"] = s[:k + 1] + [[x, q[1], -176 + 1.9 * (x - 10905) / 245] + q[3:] for x in range(int(q[0]) + 8, 11130, 8)]
    # the loop link (owner, 2026-11-08; tools/riviera/LoopLink.luau): from the top junction the East Switchbacks
    # cut straight across their first loop to the second leg (tools/riviera/looplink.json)
    link = json.load(open(os.path.join(HERE, "riviera", "looplink.json")))
    lq = link["old_path"][-1]
    for r in data["roads"]:
        if r["name"] == "East Switchbacks":
            s = r["s"]
            k = min(range(len(s)), key=lambda i: math.hypot(s[i][0] - lq[0], s[i][2] - lq[2]))
            r["s"] = s[:k] + [[p[0], p[1], p[2], -p[3], -p[4], 0, 32.0, 32.0] for p in reversed(link["pts"])]
    roads = sorted(data["roads"], key=lambda r: 0 if r["kind"] != "route" else 1)

    def stroke(pts, width, color):
        w = max(1, int(round(width / SPP * SS)))
        draw.line(pts, fill=color, width=w)
        r = w / 2
        for (x, y) in pts:
            draw.ellipse((x - r, y - r, x + r, y + r), fill=color)

    polys = []
    for r in roads:
        pts = [to_px(s[0], s[2]) for s in r["s"]]
        wl = [s[6] if len(s) > 6 else 32 for s in r["s"]]
        wr = [s[7] if len(s) > 7 else 32 for s in r["s"]]
        width = sum(a + b for a, b in zip(wl, wr)) / len(wl)
        if r.get("closed"):
            pts = pts + [pts[0]]
        polys.append((r, pts, width))
    # pavements, then dark edges, then the roads (streets first, routes on top)
    for r, pts, width in polys:
        stroke(pts, width + 20, PAVEMENT)
    for r, pts, width in polys:
        stroke(pts, width + 5, EDGE)
    for r, pts, width in polys:
        stroke(pts, width, ROUTE if r["kind"] == "route" else STREET)


PARKING = (74, 80, 94)
BAY_LINE = (150, 158, 172)


def parking_layer(draw):
    """car parks drawn from build/minimap/extra.json (2026-11-04: the marina parking): the deck as
    runs of cells read from the open place, and the painted bay lines"""
    path = os.path.join(OUT, "extra.json")
    if not os.path.exists(path):
        return
    data = json.load(open(path))
    for park in data.get("parking", []):
        step = park.get("step", 2)
        for z, xa, xb in park["runs"]:
            a = to_px(xa - step / 2, z - step / 2)
            b = to_px(xb + step / 2, z + step / 2)
            draw.rectangle((a[0], a[1], b[0], b[1]), fill=PARKING)
        for x1, z1, x2, z2 in park.get("lines", []):
            draw.line((to_px(x1, z1), to_px(x2, z2)), fill=BAY_LINE, width=max(1, SS))


def render():
    os.makedirs(OUT, exist_ok=True)
    print("ground...")
    base = base_layer().resize((W * SS, H * SS), Image.BILINEAR)
    print("buildings...")
    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    body = Image.new("RGBA", base.size, (0, 0, 0, 0))
    buildings_layer(ImageDraw.Draw(shadow), ImageDraw.Draw(body))
    shadow = shadow.filter(ImageFilter.GaussianBlur(3 * SS))
    a = np.asarray(shadow).copy()
    a[..., 3] = (a[..., 3] * 0.7).astype(np.uint8)
    base.paste(Image.fromarray(a), (0, 0), Image.fromarray(a))
    print("roads...")
    roads = Image.new("RGBA", base.size, (0, 0, 0, 0))
    roads_layer(ImageDraw.Draw(roads))
    base.paste(roads, (0, 0), roads)
    park = Image.new("RGBA", base.size, (0, 0, 0, 0))
    parking_layer(ImageDraw.Draw(park))
    base.paste(park, (0, 0), park)
    base.paste(body, (0, 0), body)  # buildings over the pavement edges
    final = base.resize((W, H), Image.LANCZOS)
    final.save(os.path.join(OUT, "whole.png"))
    for c in range(COLS):
        for r in range(ROWS):
            final.crop((c * TILE_W, r * TILE_H, (c + 1) * TILE_W, (r + 1) * TILE_H)).save(os.path.join(OUT, f"tile_{c}_{r}.png"))
    rim_and_arrow()
    print("done:", OUT)


def rim_and_arrow():
    # the rim: a dark ring with a thin light inner line, a soft inner shadow over the map's edge
    S = 512
    big = S * 4
    im = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = big / 2
    # inner shadow (drawn as rings fading inward)
    for k in range(60):
        t = k / 60
        r = c - 40 - k * 3
        alpha = int(150 * (1 - t) ** 2)
        d.ellipse((c - r, c - r, c + r, c + r), outline=(0, 0, 0, alpha), width=4)
    ring = 44
    d.ellipse((4, 4, big - 4, big - 4), outline=(16, 18, 24, 255), width=ring)
    d.ellipse((4 + ring - 6, 4 + ring - 6, big - 4 - ring + 6, big - 4 - ring + 6), outline=(120, 132, 156, 255), width=6)
    d.ellipse((4, 4, big - 4, big - 4), outline=(70, 78, 96, 255), width=6)
    im.resize((S, S), Image.LANCZOS).save(os.path.join(OUT, "rim.png"))
    # the arrow: white-edged, accent filled, pointing up
    A = 256
    big = A * 4
    im = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    tip, left, notch, right = (big / 2, 90), (big * 0.2, big - 110), (big / 2, big * 0.68), (big * 0.8, big - 110)
    sh = [(x + 18, y + 26) for x, y in (tip, left, notch, right)]
    shadow = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).polygon(sh, fill=(0, 0, 0, 150))
    im = Image.alpha_composite(im, shadow.filter(ImageFilter.GaussianBlur(20)))
    d = ImageDraw.Draw(im)
    d.polygon([tip, left, notch, right], fill=(255, 255, 255, 255))
    k = 0.78
    cx, cy = big / 2, big * 0.6
    inner = [(cx + (x - cx) * k, cy + (y - cy) * k) for x, y in (tip, left, notch, right)]
    d.polygon(inner, fill=(255, 196, 64, 255))
    im.resize((A, A), Image.LANCZOS).save(os.path.join(OUT, "arrow.png"))


def write_lua(ids_path):
    ids = json.load(open(ids_path))
    lines = [
        "-- generated by tools/minimap_art.py: do not edit",
        "-- the Monaco map as picture tiles (world studs), the rim and the arrow",
        "return {",
        f"\tx0 = {X0}, z0 = {Z0}, tileStuds = Vector2.new({TILE_W * SPP:g}, {TILE_H * SPP:g}), cols = {COLS}, rows = {ROWS},",
        "\ttiles = {",
    ]
    for c in range(COLS):
        for r in range(ROWS):
            lines.append(f'\t\t{{ col = {c}, row = {r}, image = "{ids[f"tile_{c}_{r}"]}" }},')
    lines.append("\t},")
    lines.append(f'\trim = "{ids["rim"]}",')
    lines.append(f'\tarrow = "{ids["arrow"]}",')
    lines.append("}")
    path = os.path.join(ROOT, "src", "client", "MinimapArt.lua")
    open(path, "w", newline="\n").write("\n".join(lines) + "\n")
    print("wrote", path)


if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "--lua":
        write_lua(sys.argv[2])
    else:
        render()
