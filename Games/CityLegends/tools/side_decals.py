"""
Side lettering, step 1 (owner, 2026-11-06: ZV, ZVX, ZVX 63, VTZ on the Aventador line and the Huracan STO):
takes the lettering off the design sheets and writes it as see-through PNGs, 1024 wide, for src/client/SideDecals.lua.

The sheets show it on a panel of paint. For each pixel: how far it is from the panel's colour on that row, towards the
nearest ink, is its alpha; the colour is the ink. Sheets: imports/refs/ui/brand_logos/side_decals_zv_zvx.png, side_decal_vtz.png.

run from Games/CityLegends:  python tools/side_decals.py     (writes build/side_decals/*.png and a preview)
Then upload the PNGs (MCP upload_image, serve them on a free port) and put the ids in src/client/SideDecals.lua.
"""
import os

import numpy as np
from PIL import Image

REFS = "imports/refs/ui/brand_logos/"
OUT = "build/side_decals/"
W = 1024

# name: file, panel box, inks (RGB): letters first
DECALS = {
    "zv": ("side_decals_zv_zvx.png", (56, 56, 1856, 396), [(16, 16, 14), (22, 24, 12)]),
    "zvx": ("side_decals_zv_zvx.png", (56, 440, 1856, 780), [(243, 195, 50), (224, 178, 48)]),
    "zvx63": ("side_decals_zv_zvx.png", (56, 824, 1856, 1164), [(200, 16, 46), (31, 58, 120)]),
    "vtz": ("side_decal_vtz.png", (56, 56, 1856, 396), [(16, 16, 14), (40, 26, 14)]),
}


def extract(file, box, inks):
    im = np.asarray(Image.open(REFS + file).convert("RGB").crop(box), dtype=float)
    h, w, _ = im.shape
    # keep clear of the rounded corners when reading the panel's colour
    bg = np.median(im[:, 24:-24, :], axis=1, keepdims=True)
    inks = np.array(inks, dtype=float)
    best_a = np.zeros((h, w))
    best_c = np.zeros((h, w, 3))
    best_r = np.full((h, w), 1e12)
    for ink in inks:
        d = ink.reshape(1, 1, 3) - bg
        a = np.clip(((im - bg) * d).sum(2) / np.maximum((d * d).sum(2), 1), 0, 1)
        r = ((im - (bg + a[..., None] * d)) ** 2).sum(2)
        take = r < best_r
        best_r[take] = r[take]
        best_a[take] = a[take]
        best_c[take] = ink
    a = best_a
    # the panel's own noise and corners
    a[a < 0.06] = 0
    a[:12, :] = 0
    a[-12:, :] = 0
    a[:, :12] = 0
    a[:, -12:] = 0
    return np.dstack([best_c, a])


def shrink(rgba):
    h, w, _ = rgba.shape
    nh = round(h * W / w)
    a = rgba[..., 3]
    pre = (rgba[..., :3] * a[..., None]).astype(np.float32)
    def down(c):
        return np.asarray(Image.fromarray(c, "F").resize((W, nh), Image.LANCZOS), dtype=np.float32)
    pa = np.clip(down(a.astype(np.float32)), 0, 1)
    pc = np.dstack([down(pre[..., i]) for i in range(3)])
    # the colour under see-through pixels is the ink's, or the edges show a dark rim when the image is scaled
    def blur(c):
        for axis in (0, 1, 0, 1):
            c = np.apply_along_axis(lambda m: np.convolve(m, np.ones(21) / 21, "same"), axis, c)
        return c
    ba = blur(pa)
    fill = np.dstack([blur(pc[..., i]) / np.maximum(ba, 1e-4) for i in range(3)])
    col = np.where(pa[..., None] > 0.02, pc / np.maximum(pa[..., None], 1e-3), fill)
    out = np.dstack([np.clip(col, 0, 255), pa * 255]).round().astype(np.uint8)
    return Image.fromarray(out, "RGBA")


os.makedirs(OUT, exist_ok=True)
sheet = Image.new("RGB", (W, 0))
rows = []
for name, (file, box, inks) in DECALS.items():
    im = shrink(extract(file, box, inks))
    im.save(OUT + name + ".png", optimize=True)
    for paint in ((120, 200, 20), (30, 30, 32), (235, 235, 238)):
        row = Image.new("RGB", im.size, paint)
        row.paste(im, (0, 0), im)
        rows.append(row)
    print(name, im.size, os.path.getsize(OUT + name + ".png"))
prev = Image.new("RGB", (W, sum(r.height + 6 for r in rows)), (90, 0, 90))
y = 0
for r in rows:
    prev.paste(r, (0, y))
    y += r.height + 6
prev.save(OUT + "preview.png")

# plain words for the spots where a model had a real name (white: CarSkin tints them), 1024 x 256
from PIL import ImageDraw, ImageFont

FONT = "C:/Windows/Fonts/arialbi.ttf"
for name, text in {"t_name": "VELOCITÉ NOIR", "t_vtz": "VTZ", "t_zv": "ZV", "t_zvx": "ZVX", "t_enf": "ENFURECIDO"}.items():
    W2, H2 = 4096, 1024
    size = 900
    font = ImageFont.truetype(FONT, size)
    l, t, r, b = font.getbbox(text)
    size = int(size * min((W2 - 120) / (r - l), (H2 - 120) / (b - t)))
    font = ImageFont.truetype(FONT, size)
    l, t, r, b = font.getbbox(text)
    mask = Image.new("L", (W2, H2), 0)
    ImageDraw.Draw(mask).text(((W2 - (r - l)) / 2 - l, (H2 - (b - t)) / 2 - t), text, fill=255, font=font)
    im = Image.new("RGBA", (1024, 256), (255, 255, 255, 0))
    im.putalpha(mask.resize((1024, 256), Image.LANCZOS))
    im.save(OUT + name + ".png", optimize=True)
    print(name, os.path.getsize(OUT + name + ".png"))


# a black plate with pointed ends, for where a model's own lettering is cut into the door (it covers it whole)
def plate(name, big, small, w=2040, h=340, tip=150):
    im = Image.new("RGBA", (w, h), (255, 255, 255, 0))
    d = ImageDraw.Draw(im)
    d.polygon([(0, h / 2), (tip, 6), (w - tip, 6), (w - 1, h / 2), (w - tip, h - 6), (tip, h - 6)], fill=(10, 10, 12, 255))
    f1 = ImageFont.truetype(FONT, 200)
    l, t, r, b = f1.getbbox(big)
    x = tip + 40
    d.text((x - l, 26 - t), big, fill=(240, 240, 238, 255), font=f1)
    d.rectangle([x, 250, w - tip - 40, 258], fill=(240, 240, 238, 255))
    f2 = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 44)
    d.text((x, 264), "   ".join(small.upper()), fill=(205, 205, 205, 255), font=f2)
    im.resize((1024, 171), Image.LANCZOS).save(OUT + name + ".png", optimize=True)
    print(name, os.path.getsize(OUT + name + ".png"))


plate("p_vtz", "VTZ", "Veloce Tracciato Zanna")
plate("p_zv", "ZV", "Zanna Vortice")
