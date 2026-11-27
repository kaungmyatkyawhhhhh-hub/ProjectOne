"""Facade textures for the light 1:1 building shells (2026-11-16, owner: "why are the buildings just blocks").

The place keeps only each building's shell (plain boxes in the wall colour); the real kit facade is built on the client
near the camera (YangonKitStream). So far views and Edit showed blocks. This draws one NEUTRAL facade set per archetype
(light-grey wall, dark window grid at the kit's floor height and bay width, window recesses in the normal map, glass
smooth in the roughness map) for MaterialVariants on the shells. The part's Color tints the grey, so each shell keeps
its own wall colour.

  python tools/yangon/city/shell_facades.py          -> imports/sync/shell_facades/<set>_{color,normal,rough}.png
                                                         + build/shell_facades/preview.png

One tile = TILE studs square (MaterialVariant.StudsPerTile is one number): 6 floors of 10 studs (kit_panels.FH) and
whole bays across (walk-up 6 x 10, shophouse 4 x 15, villa 5 x 12). Floor lines sit on the tile's edges.
"""
import math
import os
import random

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
OUT = os.path.join(ROOT, "imports", "sync", "shell_facades")
PREV = os.path.join(ROOT, "build", "shell_facades")

TILE = 60.0            # studs
PX = 1024
K = PX / TILE          # px a stud
FLOOR = 10.0           # kit_panels.FH (3.33 m)
PHASES = 4
WALL = 228             # neutral light grey (the part Color tints it)

# archetype set -> bays across one tile and the window layout per bay (studs, from kit_panels p_walkup / p_township /
# p_house: windows 1.6 x 1.4 m on a 0.9 m sill, balcony cages on a third of the walk-up bays, two windows a shophouse bay)
SETS = {
    "walkup": dict(bays=6, wins=[(4.8, 4.2)], sill=2.7, cage=0.33, band=0.45, shutter=0.0),
    "shop": dict(bays=4, wins=[(4.8, 3.9), (4.8, 3.9)], sill=2.7, cage=0.0, band=0.35, shutter=0.0),
    "villa": dict(bays=5, wins=[(3.9, 4.8)], sill=2.55, cage=0.0, band=0.45, shutter=0.45),
}


def px(v):
    return int(round(v * K))


def draw(name, p, seed):
    r = random.Random(seed)
    col = np.full((PX, PX), float(WALL))      # grey value
    hgt = np.full((PX, PX), 1.0)              # 1 = wall face, 0 = deepest recess
    rough = np.full((PX, PX), 0.88)
    bay = TILE / p["bays"]
    floors = int(TILE / FLOOR)
    # soft render noise so the wall is not flat plastic from close by
    noise = np.random.default_rng(seed).normal(0, 4.0, (PX // 8, PX // 8))
    noise = np.array(Image.fromarray(noise.astype(np.float32)).resize((PX, PX), Image.BILINEAR))
    col += noise

    def rect(x0, y0, x1, y1, c=None, h=None, ro=None):
        # studs; y up from the floor line at the tile's bottom -> image rows
        a, b = px(x0), px(x1)
        t, u = PX - px(y1), PX - px(y0)
        a, b, t, u = max(a, 0), min(b, PX), max(t, 0), min(u, PX)
        if b <= a or u <= t:
            return
        if c is not None:
            col[t:u, a:b] = c
        if h is not None:
            hgt[t:u, a:b] = h
        if ro is not None:
            rough[t:u, a:b] = ro

    for f in range(floors):
        z = f * FLOOR
        # floor band (slightly darker, proud of the wall), at the floor line
        bh = p["band"]
        rect(0, z, TILE, z + bh, c=WALL - 26, h=1.0)
        rect(0, z + bh, TILE, z + bh + 0.12, c=WALL - 40, h=0.85)   # its drip shadow
        for k in range(p["bays"]):
            x = k * bay
            n = len(p["wins"])
            for wi, (ww, wh) in enumerate(p["wins"]):
                if n == 1:
                    wx = x + bay / 2 - ww / 2
                else:
                    wx = x + 1.5 if wi == 0 else x + bay - 1.5 - ww
                wy = z + p["sill"]
                cage = r.random() < p["cage"]
                if cage:
                    # balcony cage: a dark recess the whole bay wide with a lighter rail and bars
                    rect(x + 0.45, z + 0.6, x + bay - 0.45, z + FLOOR - 0.6, c=78, h=0.25, ro=0.8)
                    rect(wx, wy - 1.8, wx + ww, wy + wh + 0.3, c=46, h=0.1, ro=0.25)
                    rect(x + 0.45, z + 0.6, x + bay - 0.45, z + 3.6, c=WALL - 70, h=0.6, ro=0.7)    # parapet rail
                    for bx in np.arange(x + 0.9, x + bay - 0.6, 0.75):
                        rect(bx, z + 3.6, bx + 0.16, z + FLOOR - 0.6, c=150, h=0.55, ro=0.6)      # grille bars
                    continue
                lit = r.random()
                glass = 40 + int(lit * 34)
                # frame, recess, glass, a mullion and the grille's bars
                rect(wx - 0.35, wy - 0.45, wx + ww + 0.35, wy + wh + 0.35, c=WALL - 12, h=1.0)      # surround
                rect(wx, wy, wx + ww, wy + wh, c=glass, h=0.15, ro=0.12)
                if r.random() < 0.35:   # curtain half drawn
                    side = r.random() < 0.5
                    cx0 = wx if side else wx + ww * 0.55
                    rect(cx0, wy + 0.2, cx0 + ww * 0.45, wy + wh - 0.2, c=150 + r.randint(-20, 30), h=0.15, ro=0.9)
                rect(wx + ww / 2 - 0.1, wy, wx + ww / 2 + 0.1, wy + wh, c=170, h=0.3, ro=0.5)       # mullion
                if name != "villa":
                    for gy in np.arange(wy + 0.7, wy + wh, 0.7):
                        rect(wx, gy, wx + ww, gy + 0.09, c=120, h=0.35, ro=0.6)                   # grille
                rect(wx - 0.3, wy - 0.45, wx + ww + 0.3, wy - 0.15, c=WALL + 10, h=1.0)              # sill
                if p["shutter"] and r.random() < p["shutter"]:
                    for sx in (wx - 0.35 - ww / 2, wx + ww + 0.35):
                        rect(sx, wy, sx + ww / 2, wy + wh, c=WALL - 55, h=0.92, ro=0.7)
                        for ly in np.arange(wy + 0.25, wy + wh, 0.4):
                            rect(sx, ly, sx + ww / 2, ly + 0.1, c=WALL - 80, h=0.85)
                # a rain stain under the sill
                if r.random() < 0.5:
                    sw = r.uniform(0.6, ww)
                    sx = wx + r.uniform(0, ww - sw)
                    a, b = px(sx), px(sx + sw)
                    t0 = PX - px(wy - 0.45)
                    L = px(r.uniform(1.5, 4.5))
                    fade = np.linspace(1, 0, L)[:, None]
                    t1 = min(PX, t0 + L)
                    col[t0:t1, a:b] -= 18 * fade[: t1 - t0]
            # a wall-mounted AC box now and then (walk-up / shophouse)
            if name != "villa" and r.random() < 0.18:
                ax = x + r.uniform(0.6, bay - 2.6)
                ay = z + 1.2
                rect(ax, ay, ax + 2.4, ay + 1.6, c=205, h=1.0, ro=0.6)
                rect(ax + 0.2, ay + 0.2, ax + 2.2, ay + 1.4, c=170, h=1.0, ro=0.6)
    col = weather(col, rough, floors, seed)
    col = np.clip(col, 0, 255)
    # colour map: grey RGB (neutral; a touch of blue in the glass only)
    rgb = np.stack([col, col, col], -1)
    glassmask = (rough < 0.2)
    rgb[glassmask, 2] = np.clip(rgb[glassmask, 2] + 10, 0, 255)
    # normal map (OpenGL, +Y up) from the height field
    hs = np.array(Image.fromarray((hgt * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2))).astype(float) / 255
    depth = 0.35 * K   # recess depth (studs) in px units
    dx = (np.roll(hs, -1, 1) - np.roll(hs, 1, 1)) * depth / 2
    dy = (np.roll(hs, 1, 0) - np.roll(hs, -1, 0)) * depth / 2   # rows go down: +y up is -row
    nz = np.ones_like(hs)
    nx, ny = -dx, -dy
    ln = np.sqrt(nx * nx + ny * ny + nz * nz)
    nrm = np.stack([(nx / ln + 1) * 127.5, (ny / ln + 1) * 127.5, (nz / ln + 1) * 127.5], -1)
    return (rgb.astype(np.uint8), nrm.astype(np.uint8), (np.clip(rough, 0, 1) * 255).astype(np.uint8))


def weather(col, rough, floors, seed):
    """(2026-11-27, owner: "less blocky, more realistic") the far shells get the stains the near kit walls have (stained
    render): soft mildew mottling and dark rain streaks hanging from every floor slab, 20-55% darker (real walk-ups:
    seen 171,190,180 against paint 210,221,220; stain lines 70,69,69). Its own random stream, so the window layout,
    normal and roughness maps stay exactly as uploaded; the glass is left clean."""
    g = np.random.default_rng(seed + 7)
    dark = np.zeros((PX, PX))
    # mottling: low-frequency blotches (tile-periodic: wrap the noise grid)
    for cells, amp in ((8, 0.16), (24, 0.08)):
        n = g.random((cells, cells))
        n = np.tile(n, (3, 3))
        big = np.array(Image.fromarray((n * 255).astype(np.uint8)).resize((PX * 3, PX * 3), Image.BICUBIC)).astype(float) / 255
        big = big[PX:2 * PX, PX:2 * PX]
        dark += amp * np.clip((big - 0.45) / 0.55, 0, 1)
    # streaks under each floor slab: soft wide ones with a darker core, fading down
    for f in range(floors):
        x = g.uniform(0, 3)
        while x < TILE:
            w = g.uniform(0.6, 3.2)
            L = g.uniform(2.0, 8.5)
            s = g.uniform(0.12, 0.38)
            a, b = px(x), min(PX, px(x + w))
            t0 = (PX - px(f * FLOOR)) % PX   # the floor line (the band's underside); rows go down
            n = px(L)
            fade = (np.linspace(1, 0, n) ** 1.4)[:, None]
            rows = (t0 + np.arange(n)) % PX
            prof = np.sin(np.linspace(0, np.pi, max(1, b - a))) ** 0.6   # soft sides
            dark[np.ix_(rows, np.arange(a, b) % PX)] += s * fade * prof[None, :]
            if g.random() < 0.6:   # a dark core line
                c = a + int(g.uniform(0.2, 0.8) * (b - a))
                cw = max(2, px(g.uniform(0.08, 0.25)))
                n2 = px(L * g.uniform(0.7, 1.2))
                f2 = np.linspace(1, 0, n2)[:, None]
                rows2 = (t0 + np.arange(n2)) % PX
                dark[np.ix_(rows2, np.arange(c, c + cw) % PX)] += 0.25 * f2
            x += w + g.uniform(0.5, 4.0)
    dark = np.array(Image.fromarray(np.clip(dark * 255, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.5))).astype(float) / 255
    dark = np.where(rough < 0.2, dark * 0.25, dark)   # glass: a film only
    return col * (1.0 - np.clip(dark, 0, 0.6))


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(PREV, exist_ok=True)
    prev = []
    for i, (name, p) in enumerate(SETS.items()):
        c, n, ro = draw(name, p, 1000 + i)
        # a part's material texture hangs from its TOP edge (tested 16 Nov: V = 0 at the top face), so floor lines fall
        # at top - 10k. PHASES shifts the picture down by 0 / 2.5 / 5 / 7.5 studs; the applier picks the phase that puts
        # a floor line nearest the shell's base + ground floor (error <= 1.25 studs)
        for ph in range(PHASES):
            sh = px(ph * FLOOR / PHASES)
            suf = "" if ph == 0 else "_p%d" % ph
            Image.fromarray(np.roll(c, sh, 0), "RGB").save(os.path.join(OUT, name + suf + "_color.png"))
            Image.fromarray(np.roll(n, sh, 0), "RGB").save(os.path.join(OUT, name + suf + "_normal.png"))
            Image.fromarray(np.roll(ro, sh, 0), "L").save(os.path.join(OUT, name + suf + "_rough.png"))
        prev.append(Image.fromarray(c, "RGB").resize((384, 384)))
    sheet = Image.new("RGB", (384 * len(prev), 384))
    for i, im in enumerate(prev):
        sheet.paste(im, (384 * i, 0))
    sheet.save(os.path.join(PREV, "preview.png"))
    print("written", OUT)


# archetype (buildings_1to1.py) -> facade set; sheds / halls / markets keep their plain wall
SET_OF = {"walkup": "walkup", "condo": "walkup", "civic": "walkup", "township": "shop", "house": "villa", "villa": "villa",
          "colonial": "walkup"}   # (P3) downtown colonial rows: the walk-up window grid


def b36(n):
    d = "0123456789abcdefghijklmnopqrstuvwxyz"
    return d[n // 1296 % 36] + d[n // 36 % 36] + d[n % 36]


def shell_sets(tags):
    """which facade set each shell box takes: the plot (plots.json) its middle lies in. Writes
    build/shell_facades/packed_<set>.txt: 6-character keys run together, key = base-36 (3 chars each) of the box
    middle's x and z rounded to whole studs (what YangonShellFacades.apply matches the Studio parts by: Luau
    math.round). 'villa' is the default and is not listed."""
    from collections import Counter
    from shapely.geometry import Point, Polygon
    from shapely.strtree import STRtree
    import json
    base = os.path.join(ROOT, "build", "city_1to1")
    keys = {"walkup": set(), "shop": set(), "none": set()}
    n = Counter()
    for tag in tags:
        d = os.path.join(base, "buildings_" + tag)
        plots = json.load(open(os.path.join(d, "plots.json")))
        polys = [Polygon(q["poly"]) for q in plots]
        tree = STRtree(polys)
        for f in sorted(os.listdir(d)):
            if not (f.startswith("Shell_") and f.endswith(".txt")):
                continue
            for line in open(os.path.join(d, f)):
                w = line.split()
                if not w or w[0] != "S":
                    continue
                x, z = float(w[2]), float(w[4])
                pt = Point(x, z)
                hit = [i for i in tree.query(pt) if polys[i].buffer(1.0).contains(pt)]
                arch = plots[hit[0]]["arch"] if hit else "house"
                st = SET_OF.get(arch, "none")
                n[st] += 1
                if st != "villa":
                    keys[st].add(b36(math.floor(x + 0.5)) + b36(math.floor(z + 0.5)))
    os.makedirs(PREV, exist_ok=True)
    for st, ks in keys.items():
        open(os.path.join(PREV, "packed_%s.txt" % st), "w").write("".join(sorted(ks)))
    print(dict(n), {k: len(v) for k, v in keys.items()})


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "map":
        shell_sets(sys.argv[2:] or ["P1", "P2"])
    else:
        main()
