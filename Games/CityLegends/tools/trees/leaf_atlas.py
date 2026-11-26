"""Leaf atlas for the City Legends rain tree (2026-11-27, owner: "Trees next").

python tools/trees/leaf_atlas.py   (from Games/CityLegends)

Writes into imports/trees/:
  rain_atlas.png       1024 x 1024 RGBA. Top 768 rows: 2 rows (shape A / B) x 3 columns (light / mid / dark) of
                       leaf-cluster sprites (rain tree: fine bipinnate leaves, cut-out alpha). Bottom 256 rows: bark
                       (opaque, tiles left-right).
  flame_atlas.png      the same layout with red-orange flame-tree blossoms (the old red acacias)
  rain_far.png         256 x 256 opaque: the far tree's crown (top 192 rows, light at the top, dark below) + bark
The layout must match tools/trees/rain_tree.py (SPRITES, BARK_V).
"""
import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "imports", "trees")
W = 1024
SW, SH = 341, 384      # sprite cell
SS = 2                 # supersample

LEAF = [(46, 74, 30), (58, 88, 34), (70, 100, 38), (84, 114, 44), (98, 126, 50)]
TONE = {0: 1.10, 1: 0.86, 2: 0.60}           # light, mid, dark column
BLOSSOM = [(214, 58, 28), (232, 86, 30), (196, 40, 26), (240, 120, 40)]


def pinna(d, x, y, ang, length, col, scale):
    """one compound leaf: a rachis with small paired leaflets (rain tree / flame tree are bipinnate)"""
    ca, sa = math.cos(ang), math.sin(ang)
    n = max(3, int(length / (5 * scale)))
    ex, ey = x + ca * length, y + sa * length
    d.line([(x, y), (ex, ey)], fill=col + (255,), width=max(1, int(scale)))
    for i in range(1, n + 1):
        t = i / (n + 1)
        px, py = x + ca * length * t, y + sa * length * t
        ll = (7 + 3 * math.sin(t * math.pi)) * scale        # leaflet length, longest mid-pinna
        lw = ll * 0.42
        for side in (-1, 1):
            a2 = ang + side * (1.05 + random.uniform(-0.15, 0.15))
            cx, cy = px + math.cos(a2) * ll * 0.55, py + math.sin(a2) * ll * 0.55
            # leaflet = a small rotated ellipse drawn as a polygon
            pts = []
            for k in range(8):
                u = k / 8 * 2 * math.pi
                ex_, ey_ = math.cos(u) * ll * 0.5, math.sin(u) * lw * 0.5
                pts.append((cx + ex_ * math.cos(a2) - ey_ * math.sin(a2), cy + ex_ * math.sin(a2) + ey_ * math.cos(a2)))
            j = random.uniform(0.85, 1.12)
            c = tuple(min(255, int(v * j)) for v in col)
            d.polygon(pts, fill=c + (255,))


def blossom(rng, d, x, y, r, scale):
    for _ in range(int(14 * r / (8 * scale)) + 4):
        a, rr = rng.uniform(0, 2 * math.pi), rng.uniform(0, r)
        px, py = x + math.cos(a) * rr, y + math.sin(a) * rr
        pr = rng.uniform(2.2, 3.8) * scale
        c = rng.choice(BLOSSOM)
        d.ellipse([px - pr, py - pr, px + pr, py + pr], fill=c + (255,))


def sprite(seed, tone, flame=False):
    random.seed(seed)
    rng = random.Random(seed + 1)   # blossoms draw from their own stream: the leaves stay the rain tree's shapes
    w, h = SW * SS, SH * SS
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # an irregular blob (union of circles) the leaves fill; a gap or two shows sky through
    m = min(w, h)
    lobes = [(w * 0.5, h * 0.5, m * 0.2)]
    for _ in range(6):
        a = random.uniform(0, 2 * math.pi)
        rr = random.uniform(0.08, 0.13) * m
        lobes.append((w * 0.5 + math.cos(a) * m * 0.15, h * 0.5 + math.sin(a) * m * 0.14, rr))

    def inside(px, py):
        return any((px - cx) ** 2 + (py - cy) ** 2 < r * r for cx, cy, r in lobes)

    k = TONE[tone]
    layers = 5
    for layer in range(layers):
        depth = layer / (layers - 1)               # 0 back .. 1 front
        for _ in range(260):
            px, py = random.uniform(0, w), random.uniform(0, h)
            if not inside(px, py):
                continue
            # leaves droop and point outward from the cluster middle
            out = math.atan2(py - h * 0.5, px - w * 0.5)
            ang = out + random.uniform(-0.9, 0.9) if random.random() < 0.6 else random.uniform(0, 2 * math.pi)
            length = random.uniform(30, 56) * SS
            # keep every leaf inside its cell (a margin of 6 px), or the atlas neighbour shows a cut edge
            ex, ey = px + math.cos(ang) * length, py + math.sin(ang) * length
            if not (12 * SS < ex < w - 12 * SS and 12 * SS < ey < h - 12 * SS):
                continue
            base = random.choice(LEAF)
            vert = 1.12 - 0.30 * (py / h)          # lighter at the top of the cluster
            f = k * (0.70 + 0.30 * depth) * vert
            col = tuple(max(0, min(255, int(v * f))) for v in base)
            pinna(d, px, py, ang, length, col, SS)
        if flame and layer >= 2:
            n = {0: 70, 1: 40, 2: 14}[tone]
            for _ in range(n):
                px, py = rng.uniform(0, w), rng.uniform(0, h * 0.8)
                if not inside(px, py):
                    continue
                blossom(rng, d, px, py, rng.uniform(12, 24) * SS, SS)
    img = img.resize((SW, SH), Image.LANCZOS)
    # crisp cut-out edge (soft alpha sorts badly), keep a 1-px antialias ramp
    a = np.asarray(img.getchannel("A"), dtype=np.float32)
    a = np.clip((a - 70) * 2.2, 0, 255).astype(np.uint8)
    img.putalpha(Image.fromarray(a))
    return img


def bark(w, h, seed=7):
    rng = np.random.default_rng(seed)
    x = np.arange(w)
    base = np.zeros((h, w), np.float32)
    # vertical furrows that tile left-right (integer frequencies)
    for f, amp in ((6, 0.35), (13, 0.25), (29, 0.18), (61, 0.12)):
        ph = rng.uniform(0, 2 * np.pi)
        base += amp * np.sin(2 * np.pi * f * x / w + ph)[None, :]
    noise = rng.normal(0, 1, (h // 8, w // 4)).astype(np.float32)
    noise = np.asarray(Image.fromarray(noise).resize((w, h), Image.BICUBIC))
    v = 0.5 + 0.35 * base + 0.18 * noise
    v = np.clip(v, 0, 1)
    dark = np.array([46, 40, 35], np.float32)
    light = np.array([112, 100, 86], np.float32)
    rgb = dark[None, None, :] + (light - dark)[None, None, :] * v[..., None]
    return Image.fromarray(rgb.astype(np.uint8), "RGB").convert("RGBA")


def bleed(img):
    """fill transparent pixels' colour from their leafy neighbours (no light halos when mipmapped)"""
    arr = np.asarray(img, dtype=np.float32) / 255
    a = arr[..., 3:4]
    rgb = arr[..., :3]
    out = rgb.copy()
    known = a[..., 0] > 0.02
    pre = rgb * (a > 0.02)
    wgt = (a > 0.02).astype(np.float32)
    for r in (2, 4, 8, 16, 32, 64):
        pi = Image.fromarray((pre * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r))
        wi = Image.fromarray((wgt[..., 0] * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r))
        p = np.asarray(pi, np.float32) / 255
        ww = np.asarray(wi, np.float32)[..., None] / 255
        fill = (~known) & (ww[..., 0] > 0.004)
        out[fill] = (p / np.maximum(ww, 1e-4))[fill]
        known = known | fill
    out = np.clip(out, 0, 1)
    res = np.concatenate([out, a], axis=2)
    return Image.fromarray((res * 255).astype(np.uint8), "RGBA")


def atlas(flame, rects=None):
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    for row in range(2):
        for col in range(3):
            # the same shape (seed) in all three tones of a row, so the tones read as one leaf mass
            s = sprite(100 + row * 17, col, flame)
            if rects is not None and col == 0:
                # the leafy part of the cell (UV rect, 0..1, v up) for rain_tree.py: union of the 3 tones' boxes is
                # the same shape, so the light tone's box is used for all three (+3 px margin)
                x0, y0, x1, y1 = s.getchannel("A").getbbox()
                rects.append([(x0 - 3) / W, (y0 - 3) / W, (x1 + 3) / W, (y1 + 3) / W, row])
            img.alpha_composite(s, (col * SW, row * SH))
    img = bleed(img)
    img.paste(bark(W, 256), (0, 768))
    return img


def far_tex():
    rng = np.random.default_rng(3)
    w, h = 256, 192
    n = rng.normal(0, 1, (h // 4, w // 4)).astype(np.float32)
    n = np.asarray(Image.fromarray(n).resize((w, h), Image.BICUBIC))
    fine = rng.normal(0, 1, (h, w)).astype(np.float32)
    y = np.linspace(1, 0, h)[:, None]                         # 1 at the crown top
    v = 0.45 + 0.50 * y + 0.12 * n + 0.08 * fine
    top = np.array([62, 88, 36], np.float32)
    rgb = top[None, None, :] * np.clip(v, 0.25, 1.15)[..., None]
    crown = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB")
    img = Image.new("RGB", (256, 256))
    img.paste(crown, (0, 0))
    img.paste(bark(256, 64).convert("RGB"), (0, 192))
    return img


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    rects = []
    atlas(False, rects).save(os.path.join(OUT, "rain_atlas.png"))
    import json
    json.dump({"cell": [SW / W, SH / W], "rects": rects, "bark_v": [0, 256 / W]},
              open(os.path.join(OUT, "rain_atlas.json"), "w"), indent=1)
    atlas(True).save(os.path.join(OUT, "flame_atlas.png"))
    far_tex().save(os.path.join(OUT, "rain_far.png"))
    print("written to", os.path.abspath(OUT))
