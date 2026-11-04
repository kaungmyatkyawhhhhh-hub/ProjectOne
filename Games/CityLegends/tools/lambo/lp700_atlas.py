"""The LP700's redrawn cluster laid into the model's own cluster picture (a 512 px atlas, stored
upside down): the dial, the two gauge strips and the two side screens each go where the model's
own ones are, so they land on the right flats of its dash. Written at 1024.

    python tools/lambo/lp700_atlas.py lp700_art.png model_atlas.png out.png
"""

import sys

import numpy as np
from PIL import Image, ImageDraw

art_path, atlas_path, out = sys.argv[1], sys.argv[2], sys.argv[3]
SCALE = 2  # art pixels per photo pixel
OX, OY = 110, 150  # the art's first pixel in the photo
art = Image.open(art_path).convert("RGB")
base = Image.open(atlas_path).convert("RGB").resize((1024, 1024), Image.LANCZOS)


def piece(box, centre, k, mask_circle=None):
    """box in photo pixels -> placed in the atlas (512 space) with its middle at centre, k atlas
    pixels per photo pixel, flipped top to bottom as the atlas stores it"""
    x0, y0, x1, y1 = box
    c = art.crop(((x0 - OX) * SCALE, (y0 - OY) * SCALE, (x1 - OX) * SCALE, (y1 - OY) * SCALE))
    w, h = int((x1 - x0) * k * 2), int((y1 - y0) * k * 2)
    c = c.resize((w, h), Image.LANCZOS).transpose(Image.FLIP_TOP_BOTTOM)
    at = (int(centre[0] * 2 - w / 2), int(centre[1] * 2 - h / 2))
    if mask_circle:
        m = Image.new("L", (w, h), 0)
        ImageDraw.Draw(m).ellipse([1, 1, w - 2, h - 2], fill=255)
        base.paste(c, at, m)
    else:
        base.paste(c, at)


# wipe the old cluster
d = ImageDraw.Draw(base)
d.rectangle([0, 0, 1023, 382], fill=(7, 7, 8))
R = 238
piece((749 - R, 412 - R, 749 + R, 412 + R), (257.4, 107.5), 62.8 / 226.0, mask_circle=True)
piece((372, 235, 505, 600), (152, 100), 0.305)
piece((1000, 235, 1140, 600), (361, 103), 0.305)
piece((110, 478, 305, 650), (85, 60), 0.31)
piece((1200, 430, 1388, 492), (418, 90), 0.31)
base.save(out)
print("ok")
