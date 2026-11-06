"""
Real names in the new imports' pictures (owner, 2026-11-06: "remove every new imports car model if they have their
actual car brands name"). Paints them out of the colour pictures already in the game; our fake names go where the
real one was. The jobs: tools/logo_paint/retex.json.

    python tools/retex.py [sources folder]     writes build/retex/<name>.png

Then serve build/retex on a free port, upload_image them, and in Studio's edit side swap each job's old asset ids for
the new id in ReplicatedStorage.CarModels (MeshPart.TextureID and SurfaceAppearance.ColorMap; the old ids stay in
retex.json, so it can be put back). Pictures that came from a session's scratch folder are looked for in the
sources folder by name.

ops:  {"rect": [x0, y0, x1, y1]}                 each row blended from the pixel left of it to the pixel right of it
      {"solid": [x0, y0, x1, y1, r, g, b]}
      {"from": [x0, y0, x1, y1, sx, sy]}         one colour, read at (sx, sy)
      {"text": [x0, y0, x1, y1, "TEXT", r, g, b], "flip": "v" | "h" | "vh"}   text fitted to the box (bold italic)
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageOps

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
OUT = os.path.join(ROOT, "build", "retex")
FONT = "C:/Windows/Fonts/arialbi.ttf"


def do_rect(a, x0, y0, x1, y1):
    h, w = a.shape[:2]
    x0, x1 = max(x0, 0), min(x1, w)
    for y in range(max(y0, 0), min(y1, h)):
        left = a[y, x0 - 1] if x0 > 0 else a[y, min(x1, w - 1)]
        right = a[y, x1] if x1 < w else left
        t = np.linspace(0, 1, x1 - x0)[:, None]
        a[y, x0:x1] = left * (1 - t) + right * t


def do_text(im, box, text, color, flip):
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    size = 200
    font = ImageFont.truetype(FONT, size)
    l, t, r, b = font.getbbox(text)
    size = int(size * min(w / (r - l), h / (b - t)))
    font = ImageFont.truetype(FONT, size)
    l, t, r, b = font.getbbox(text)
    mask = Image.new("L", (w * 4, h * 4), 0)
    f4 = ImageFont.truetype(FONT, size * 4)
    l, t, r, b = f4.getbbox(text)
    ImageDraw.Draw(mask).text(((w * 4 - (r - l)) / 2 - l, (h * 4 - (b - t)) / 2 - t), text, fill=255, font=f4)
    mask = mask.resize((w, h), Image.LANCZOS)
    if "v" in flip:
        mask = ImageOps.flip(mask)
    if "h" in flip:
        mask = ImageOps.mirror(mask)
    im.paste(Image.new("RGBA", (w, h), (*color, 255)), (x0, y0), mask)


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else None
    jobs = json.load(open(os.path.join(HERE, "logo_paint", "retex.json"), encoding="utf-8"))
    os.makedirs(OUT, exist_ok=True)
    for job in jobs:
        path = os.path.join(ROOT, job["file"])
        if not os.path.exists(path) and src:
            path = os.path.join(src, os.path.basename(job["file"]))
        im = Image.open(path).convert("RGBA")
        a = np.asarray(im, dtype=float).copy()
        for op in job["ops"]:
            if "rect" in op:
                do_rect(a, *op["rect"])
            elif "solid" in op:
                x0, y0, x1, y1, r, g, b = op["solid"]
                a[y0:y1, x0:x1, :3] = (r, g, b)
                a[y0:y1, x0:x1, 3] = 255
            elif "from" in op:
                x0, y0, x1, y1, sx, sy = op["from"]
                a[y0:y1, x0:x1] = a[sy, sx]
            elif "text" in op:
                im2 = Image.fromarray(a.round().astype(np.uint8), "RGBA")
                x0, y0, x1, y1, text, r, g, b = op["text"]
                do_text(im2, (x0, y0, x1, y1), text, (r, g, b), op.get("flip", ""))
                a = np.asarray(im2, dtype=float).copy()
        name = job["name"]
        Image.fromarray(a.round().astype(np.uint8), "RGBA").save(os.path.join(OUT, name + ".png"), optimize=True)
        print(name, im.size, job["assets"])


if __name__ == "__main__":
    main()
