"""The painted needles taken out of the Superleggera's dash picture, so the game's
live needles (CarSkin.DIAL_NEEDLES) stand alone. The scale under a needle's tip is copied from the same
scale a step further round.

    python tools/lambo/gallardo_dials.py dash_in.png dash_out.png
"""

import math
import sys

import numpy as np
from PIL import Image, ImageDraw

dash_in, dash_out = sys.argv[1:3]
# hub, tip of the painted needle, tail past the hub, half width, radius where the scale starts, one step of it (deg)
DIALS = [
    {"hub": (198.0, 821.5), "tip": (20, 768), "tail": (264, 840), "r": 158, "step": -27.4, "R": 34, "keep": (44, 793, 74, 812), "wide": 1.15},
    {"hub": (605.0, 822.5), "tip": (455, 712), "tail": (670, 861), "r": 158, "step": -27.6, "R": 34, "wide": 1.3},
]


def needle_mask(d, size):
    """the needle and its soft shadow: wide at the hub, narrow at the tip"""
    m = Image.new("L", size, 0)
    (cx, cy), (tx, ty), (bx, by) = d["hub"], d["tip"], d["tail"]
    ax, ay = tx - bx, ty - by
    n = math.hypot(ax, ay)
    ux, uy = ax / n, ay / n
    nx, ny = -uy, ux
    k = d.get("wide", 1.0)
    stations = [(0.0, 15), (0.45, 17), (0.75, 13), (1.0, 9)]
    left = [(bx + ax * f + nx * w * k, by + ay * f + ny * w * k) for f, w in stations]
    right = [(bx + ax * f - nx * w * k, by + ay * f - ny * w * k) for f, w in stations]
    ImageDraw.Draw(m).polygon(left + right[::-1], fill=255)
    return np.asarray(m) > 0


dash = np.asarray(Image.open(dash_in).convert("RGB")).astype(float)
H, W = dash.shape[:2]
yy, xx = np.mgrid[0:H, 0:W]
for d in DIALS:
    mask = needle_mask(d, (W, H))
    cx, cy = d["hub"]
    rr = np.hypot(xx - cx, yy - cy)
    if "keep" in d:
        x0, y0, x1, y1 = d["keep"]
        mask = mask & ~((xx >= x0) & (xx < x1) & (yy >= y0) & (yy < y1))
    # the face's own light, ring by ring (the numbers and the needle fall out of the middle value)
    inner = mask & (rr < d["r"])
    bins = rr.astype(int)
    prof = {}
    for b in np.unique(bins[inner]):
        ring = (np.abs(bins - b) <= 2) & ~mask & (yy > cy - 190) & (yy < cy + 190)
        prof[b] = np.median(dash[ring], axis=0) if ring.any() else np.array([200.0, 200.0, 200.0])
    dash[inner] = np.array([prof[b] for b in bins[inner]])
    outer = mask & (rr >= d["r"])
    a = np.arctan2(yy[outer] - cy, xx[outer] - cx) + math.radians(d["step"])
    sx = np.clip((cx + rr[outer] * np.cos(a)).astype(int), 0, W - 1)
    sy = np.clip((cy + rr[outer] * np.sin(a)).astype(int), 0, H - 1)
    dash[outer] = dash[sy, sx]
out = Image.fromarray(dash.astype("uint8"))
dr = ImageDraw.Draw(out)
for d in DIALS:
    cx, cy = d["hub"]
    R = d["R"]
    dr.ellipse([cx - R, cy - R, cx + R, cy + R], fill=(58, 62, 68), outline=(30, 32, 36), width=2)
out.save(dash_out)

print("ok")
