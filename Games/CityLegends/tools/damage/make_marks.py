"""The pictures of visible damage (owner, 2026-11-07: "add car scrapes and etc"), drawn here, no logos, no real source.
    python tools/damage/make_marks.py <out dir>
Each picture is a clear 1024 square with its mark in the middle. client/DamageFx.lua puts one Texture on every body piece
under the mark, all with the same scale (24 x 8 studs a tile on a side, 12 x 8 on an end), so a mark runs across panels at
one size and never repeats on the car. That is 43 x 128 pixels a stud on a side: strokes are drawn thick across and long
along, or they fade out at normal view distance (the first set, in 1 px lines, could not be seen on a car at all)."""
import math
import os
import random
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
S = 1024
C = S // 2


def clear():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))


def fade(im, rx, ry):
    """soften the ends of a mark so it has no cut edge"""
    y, x = np.mgrid[0:S, 0:S]
    d = np.sqrt(((x - C) / rx) ** 2 + ((y - C) / ry) ** 2)
    k = np.clip((1.0 - d) / 0.35, 0, 1)
    a = np.asarray(im, dtype=np.float32).copy()
    a[..., 3] *= k
    return Image.fromarray(a.astype(np.uint8), "RGBA")


def scrape(seed, lines=26):
    random.seed(seed)
    rub = clear()
    d = ImageDraw.Draw(rub)
    for _ in range(22):
        x0 = C - random.randint(30, 104)
        x1 = C + random.randint(30, 104)
        y = int(random.gauss(C, 20))
        d.line((x0, y, x1, y + random.randint(-5, 5)), fill=(150, 152, 158, random.randint(36, 70)), width=random.randint(10, 24))
    rub = rub.filter(ImageFilter.GaussianBlur(6))
    d = ImageDraw.Draw(rub)
    for _ in range(lines):
        x0 = C - random.randint(10, 104)
        x1 = x0 + random.randint(30, 130)
        y = random.gauss(C, 26)
        d.line((x0, y, x1, y + random.randint(-4, 4)), fill=(206, 208, 212, random.randint(110, 200)), width=random.choice((2, 3, 4)))
    for _ in range(lines // 3):
        x0 = C - random.randint(10, 104)
        x1 = x0 + random.randint(30, 100)
        y = random.gauss(C, 30)
        d.line((x0, y, x1, y + random.randint(-4, 4)), fill=(30, 30, 34, random.randint(90, 150)), width=random.choice((2, 3)))
    return fade(rub, 122, 78)


def scratch(seed):
    random.seed(seed)
    im = clear()
    d = ImageDraw.Draw(im)
    for _ in range(7):
        x0 = C - random.randint(10, 46)
        x1 = x0 + random.randint(24, 70)
        y = random.gauss(C, 14)
        d.line((x0, y, x1, y + random.randint(-10, 10)), fill=(216, 218, 222, random.randint(130, 210)), width=random.choice((2, 3)))
    for _ in range(3):
        x0 = C - random.randint(10, 46)
        x1 = x0 + random.randint(24, 60)
        y = random.gauss(C, 16)
        d.line((x0, y, x1, y + random.randint(-8, 8)), fill=(30, 30, 34, 130), width=2)
    return im


def dent(seed):
    """a pushed-in panel: a soft dark hollow, a light rim on the top edge, a crease or two, a little bare metal"""
    rng = np.random.default_rng(seed)
    random.seed(seed)
    rx, ry = 54, 104
    y, x = np.mgrid[0:S, 0:S]
    nx, ny = (x - C) / rx, (y - C) / ry
    ang = np.arctan2(ny, nx)
    wob = 1 + sum(rng.uniform(0.03, 0.09) * np.sin(ang * k + rng.uniform(0, 6.3)) for k in (2, 3, 5, 7))
    r = np.sqrt(nx**2 + ny**2) / wob
    hollow = np.clip(1.0 - r, 0, 1) ** 0.9
    a = hollow * 0.46
    rim = np.exp(-(((r - 1.0) / 0.16) ** 2)) * np.clip(-ny / wob, 0, 1)
    rgb = np.zeros((S, S, 4), dtype=np.float32)
    rgb[..., 0:3] = 14
    rgb[..., 3] = a * 255
    keep = rim > 0.02
    rgb[keep, 0:3] = 225
    rgb[keep, 3] = np.maximum(rgb[keep, 3], rim[keep] * 62)
    im = Image.fromarray(rgb.astype(np.uint8), "RGBA").filter(ImageFilter.GaussianBlur(2))
    d = ImageDraw.Draw(im)
    for _ in range(3):
        x0 = C + random.randint(-40, 14)
        y0 = C + random.randint(-70, 60)
        d.line((x0, y0, x0 + random.randint(14, 34), y0 + random.randint(-30, 30)), fill=(214, 214, 218, 170), width=3)
    for _ in range(2):
        x0 = C + random.randint(-40, 14)
        y0 = C + random.randint(-70, 60)
        d.line((x0, y0, x0 + random.randint(14, 34), y0 + random.randint(-30, 30)), fill=(8, 8, 10, 170), width=3)
    for _ in range(14):
        px = C + random.gauss(0, 24)
        py = C + random.gauss(0, 46)
        d.ellipse((px, py, px + 3, py + 6), fill=(196, 198, 202, 190))
    return im


def crack(seed, reach, arms, width):
    random.seed(seed)
    im = clear()
    d = ImageDraw.Draw(im)
    ends = []
    for i in range(arms):
        a = i / arms * math.tau + random.uniform(-0.2, 0.2)
        x, y = C, C
        steps = random.randint(4, 8)
        pts = [(x, y)]
        for _ in range(steps):
            a += random.uniform(-0.26, 0.26)
            r = reach / steps * random.uniform(0.7, 1.2)
            x += math.cos(a) * r
            y += math.sin(a) * r
            pts.append((x, y))
        d.line(pts, fill=(226, 234, 240, 215), width=width + (1 if i % 3 == 0 else 0))
        ends.append(pts[len(pts) // 2])
    for i in range(arms):
        d.line((ends[i], ends[(i + 1) % arms]), fill=(226, 234, 240, 140), width=width)
    d.ellipse((C - 12, C - 12, C + 12, C + 12), fill=(244, 248, 250, 225))
    return im


def rash():
    """the rim lip, ground away: a broken ring, seen square on. Stretched over the rim's whole face by a Decal"""
    random.seed(4)
    im = clear()
    d = ImageDraw.Draw(im)
    for _ in range(620):
        a = random.uniform(0, math.tau)
        if 2.2 < a < 3.1:
            continue
        r = random.uniform(428, 492)
        x, y = C + math.cos(a) * r, C + math.sin(a) * r
        d.line((x, y, x + math.sin(a) * random.uniform(10, 36), y - math.cos(a) * random.uniform(10, 36)), fill=(232, 232, 236, random.randint(150, 250)), width=random.choice((3, 4, 6)))
    return im


def dirt():
    """road film: thick at the sill, gone by the waist. One tile is the height of the car"""
    rng = np.random.default_rng(9)
    n = rng.random((S // 4, S // 4))
    n = np.asarray(Image.fromarray((n * 255).astype(np.uint8)).resize((S, S), Image.BICUBIC), dtype=np.float32) / 255
    fine = rng.random((S, S))
    y = np.arange(S)[:, None] / S
    k = np.clip((y - 0.42) / 0.58, 0, 1) ** 1.3
    a = np.clip(k * (0.45 + 0.75 * n) * (0.75 + 0.35 * fine), 0, 1) * 255
    out = np.zeros((S, S, 4), dtype=np.uint8)
    out[..., 0] = 96
    out[..., 1] = 82
    out[..., 2] = 62
    out[..., 3] = a.astype(np.uint8)
    return Image.fromarray(out, "RGBA").filter(ImageFilter.GaussianBlur(1.5))


for name, im in {
    "scrape1": scrape(1), "scrape2": scrape(2, 40), "scrape3": scrape(3, 22),
    "scratch1": scratch(4), "scratch2": scratch(5),
    "dent1": dent(6), "dent2": dent(7), "dent3": dent(8),
    "crackglass": crack(9, 450, 12, 9), "cracklamp": crack(10, 84, 8, 3), "rash": rash(), "dirt": dirt(),
}.items():
    im.save(os.path.join(OUT, name + ".png"))
print("ok")
