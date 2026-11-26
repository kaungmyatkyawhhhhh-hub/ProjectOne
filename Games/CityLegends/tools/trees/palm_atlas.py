"""Palm atlas for City Legends' coconut and toddy (fan) palms (2026-11-27, palms looked like flat dark star cards).

python tools/trees/palm_atlas.py   (from Games/CityLegends)

imports/trees/palm_atlas.png, 1024 x 1024 RGBA (layout = LAYOUT below, read by tools/trees/palm_tree.py):
  x 0-767,  rows 0-767     3 coconut frond sprites 256 x 768 (green, deep green, dry): rachis up the middle, base at
                           the bottom, cut-out pinnate leaflets
  x 768-1023, rows 0-767   2 fan-leaf sprites 256 x 384 (toddy palm: green, dry): petiole from the bottom middle,
                           a fan of split segments
  x 0-767,  rows 768-1023  bark strips, u along the trunk: coconut (ringed, grey-brown) and toddy (dark grey)
  x 768-1023, rows 768-1023  coconut husk (green-yellow) and crown fibre (brown)
Colour is bled into the clear pixels (no light halos when mipmapped).
"""
import json
import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw

from leaf_atlas import bleed

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "imports", "trees")
W = 1024
SS = 2

GREEN = [(58, 92, 34), (70, 106, 38), (84, 118, 44), (96, 128, 48), (76, 110, 52)]
DEEP = [(40, 70, 30), (48, 80, 32), (56, 88, 36), (44, 76, 34)]
DRY = [(150, 128, 70), (170, 146, 82), (128, 104, 58), (186, 160, 92)]


def frond(seed, pal, dry=False):
    """one coconut frond, 256 x 768: base at the bottom. Leaflet reach follows ENV (the mesh tapers the card the same)"""
    r = random.Random(seed)
    w, h = 256 * SS, 768 * SS
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = w / 2
    n = 92
    for i in range(n):
        t = 0.06 + 0.93 * i / (n - 1)               # 0 base .. 1 tip
        y = h * (1 - t)
        reach = env(t) * (w / 2 - 6 * SS)
        for side in (-1, 1):
            if r.random() < (0.10 if not dry else 0.22):   # a torn / missing leaflet shows sky through
                continue
            L = reach * r.uniform(0.86, 1.0)
            ang = math.radians(r.uniform(52, 64))       # leaflets sweep toward the tip
            bend = r.uniform(0.0, 0.18)
            col = r.choice(pal)
            j = r.uniform(0.85, 1.12)
            col = tuple(min(255, int(v * j)) for v in col)
            # a tapered blade drawn as a polygon along a slightly bent line
            pts_l, pts_r = [], []
            steps = 6
            lw = r.uniform(4.5, 6.5) * SS
            for k in range(steps + 1):
                u = k / steps
                a = ang + bend * u
                px = cx + side * math.sin(a) * L * u
                py = y - math.cos(a) * L * u
                half = lw * (0.35 + 0.65 * math.sin(math.pi * min(1, u * 1.15 + 0.05))) * (1 - 0.8 * u)
                # normal to the blade
                nx, ny = math.cos(a) * side, math.sin(a)
                pts_l.append((px + nx * half, py + ny * half))
                pts_r.append((px - nx * half, py - ny * half))
            d.polygon(pts_l + pts_r[::-1], fill=col + (255,))
            # pale midrib
            mid = tuple(min(255, int(v * 1.18)) for v in col)
            d.line([(cx, y), (cx + side * math.sin(ang) * L * 0.8, y - math.cos(ang) * L * 0.8)], fill=mid + (255,), width=1)
    # rachis: thick at the base, thin at the tip, a light top line
    rc = (150, 140, 80) if not dry else (176, 150, 96)
    for k in range(40):
        t0, t1 = k / 40, (k + 1) / 40
        wd = (9 - 7 * t0) * SS
        d.line([(cx, h * (1 - t0)), (cx, h * (1 - t1))], fill=rc + (255,), width=int(wd))
    img = img.resize((256, 768), Image.LANCZOS)
    a = np.asarray(img.getchannel("A"), dtype=np.float32)
    img.putalpha(Image.fromarray(np.clip((a - 70) * 2.2, 0, 255).astype(np.uint8)))
    return img


def env(t):
    """leaflet reach (0..1 of the half width) along the frond: short at the base, longest at ~0.35, short at the tip"""
    return max(0.12, min(1.0, 0.25 + 2.6 * t)) * (1 - 0.82 * max(0, (t - 0.35) / 0.65) ** 1.3)


def fan(seed, pal):
    """a toddy palm leaf, 256 x 384: petiole from the bottom middle, a fan of ~44 split segments"""
    r = random.Random(seed)
    w, h = 256 * SS, 384 * SS
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    hub = (w / 2, h * 0.62)
    # petiole (bottom 38 %)
    d.polygon([(w / 2 - 5 * SS, h), (w / 2 + 5 * SS, h), (w / 2 + 3 * SS, hub[1]), (w / 2 - 3 * SS, hub[1])],
              fill=(96, 98, 52, 255))
    n = 44
    R = min(w / 2, hub[1]) - 6 * SS
    for i in range(n):
        a = math.radians(-118 + 236 * i / (n - 1)) + r.uniform(-0.02, 0.02)
        L = R * r.uniform(0.78, 1.0) * (0.82 + 0.18 * math.cos(a * 0.7))
        col = r.choice(pal)
        col = tuple(min(255, int(v * r.uniform(0.85, 1.12))) for v in col)
        half = math.radians(2.6)
        tip_split = r.random() < 0.6
        # a segment: narrow wedge, split tip
        p_l = (hub[0] + math.sin(a - half) * L * 0.92, hub[1] - math.cos(a - half) * L * 0.92)
        p_r = (hub[0] + math.sin(a + half) * L * 0.92, hub[1] - math.cos(a + half) * L * 0.92)
        if tip_split:
            t_l = (hub[0] + math.sin(a - half * 0.6) * L, hub[1] - math.cos(a - half * 0.6) * L)
            notch = (hub[0] + math.sin(a) * L * 0.9, hub[1] - math.cos(a) * L * 0.9)
            t_r = (hub[0] + math.sin(a + half * 0.6) * L, hub[1] - math.cos(a + half * 0.6) * L)
            poly = [hub, p_l, t_l, notch, t_r, p_r]
        else:
            tip = (hub[0] + math.sin(a) * L, hub[1] - math.cos(a) * L)
            poly = [hub, p_l, tip, p_r]
        d.polygon(poly, fill=col + (255,))
        # fold line (light ridge)
        ridge = tuple(min(255, int(v * 1.25)) for v in col)
        d.line([hub, (hub[0] + math.sin(a) * L * 0.85, hub[1] - math.cos(a) * L * 0.85)], fill=ridge + (255,), width=1)
    img = img.resize((256, 384), Image.LANCZOS)
    a = np.asarray(img.getchannel("A"), dtype=np.float32)
    img.putalpha(Image.fromarray(np.clip((a - 70) * 2.2, 0, 255).astype(np.uint8)))
    return img


def bark(w, h, seed, dark, light, rings):
    """u (x) along the trunk: ring scars across it every 1/rings of the width"""
    rng = np.random.default_rng(seed)
    x = np.arange(w)[None, :]
    y = np.arange(h)[:, None]
    ph = (x / w * rings) % 1.0
    ring = np.exp(-((ph - 0.5) / 0.07) ** 2)             # a dark scar line in each ring
    noise = rng.normal(0, 1, (h // 4, w // 8)).astype(np.float32)
    noise = np.asarray(Image.fromarray(noise).resize((w, h), Image.BICUBIC))
    fine = rng.normal(0, 1, (h, w)).astype(np.float32)
    v = 0.62 + 0.12 * noise + 0.06 * fine - 0.45 * ring + 0.08 * np.sin(2 * np.pi * y / h * 3)
    v = np.clip(v, 0, 1)
    dark, light = np.array(dark, np.float32), np.array(light, np.float32)
    rgb = dark + (light - dark) * v[..., None]
    return Image.fromarray(rgb.astype(np.uint8), "RGB").convert("RGBA")


def flat(w, h, seed, a, b):
    rng = np.random.default_rng(seed)
    n = np.asarray(Image.fromarray(rng.normal(0, 1, (h // 8, w // 8)).astype(np.float32)).resize((w, h), Image.BICUBIC))
    v = np.clip(0.5 + 0.25 * n + 0.1 * rng.normal(0, 1, (h, w)), 0, 1)
    rgb = np.array(a, np.float32) + (np.array(b, np.float32) - np.array(a, np.float32)) * v[..., None]
    return Image.fromarray(rgb.astype(np.uint8), "RGB").convert("RGBA")


LAYOUT = {
    # UV rects (u0, v0, u1, v1), v up
    "frond": [[i * 0.25, 0.25, (i + 1) * 0.25, 1.0] for i in range(3)],    # green, deep, dry
    "fan": [[0.75, 0.625, 1.0, 1.0], [0.75, 0.25, 1.0, 0.625]],            # green, dry
    "fan_hub_v": 0.38,      # where the petiole meets the blade, 0..1 up the fan cell
    "bark_coco": [0.0, 0.125, 0.75, 0.25],
    "bark_toddy": [0.0, 0.0, 0.75, 0.125],
    "husk": [0.76, 0.135, 0.99, 0.24],
    "fibre": [0.76, 0.01, 0.99, 0.115],
}

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    for i, (pal, dry) in enumerate(((GREEN, False), (DEEP, False), (DRY, True))):
        img.alpha_composite(frond(40 + i * 7, pal, dry), (i * 256, 0))
    img.alpha_composite(fan(91, GREEN + DEEP[:2]), (768, 0))
    img.alpha_composite(fan(92, DRY), (768, 384))
    img = bleed(img)
    img.paste(bark(768, 128, 5, (78, 70, 60), (150, 140, 124), 40), (0, 768))
    img.paste(bark(768, 128, 6, (40, 38, 36), (96, 92, 86), 28), (0, 896))
    img.paste(flat(256, 128, 7, (96, 112, 40), (150, 150, 60)), (768, 768))
    img.paste(flat(256, 128, 8, (70, 52, 34), (126, 98, 62)), (768, 896))
    img.save(os.path.join(OUT, "palm_atlas.png"))
    json.dump(LAYOUT, open(os.path.join(OUT, "palm_atlas.json"), "w"), indent=1)
    print("written", os.path.abspath(os.path.join(OUT, "palm_atlas.png")))
