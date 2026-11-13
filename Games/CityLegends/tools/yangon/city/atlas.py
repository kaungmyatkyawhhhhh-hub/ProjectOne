"""atlas.py [outdir]: the Yangon facade + roof atlas for the mesh buildings (pure Python: Pillow + numpy).

Writes into outdir (default build/ygn_bmesh/):
  atlas.png        1024 x 1024 colour map. Walls are drawn near white / light grey: each building's wall and roof colour
                   comes from its vertex colours (Roblox multiplies them with the texture), so one atlas serves the city.
  atlas_glow.png   1024 x 1024 emissive mask (white = lit at night: some windows, open shops, signs, stair wells).
  atlas.json       the rows: {name: {v0, v1 (glTF v, 0 = top of the image), kind, studs_u (studs per full U repeat),
                   studs_v (studs one row height covers), bays, regions {name: [u0, u1]}}}.
  atlas_preview.png  day / night elevations of a walk-up, a shophouse, a condo, a house and a shed made of the rows.

Every row fills the whole width and tiles in U (one repeat = studs_u studs, 8 bays of studs_u / 8). V stays inside the
row; each row has GUTTER pixels above and below copied from its own edge lines, so mipmaps don't bleed between rows.
Drawn at 2x and filtered down. Wall rows: a floor is 9 studs (ground floor 12), so a bay is 12 studs wide.
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "..", "build", "ygn_bmesh")
W = 1024
S = 2  # drawn at 2x
GUTTER = 4

# name, content height (px at 1x), kind, studs per U repeat, studs per row height
ROWS = [
    ("walkup", 88, "wall", 96, 9),
    ("shopup", 88, "wall", 96, 9),
    ("condo", 88, "wall", 96, 9),
    ("house", 88, "wall", 96, 9),
    ("party", 88, "wall", 96, 9),
    ("cage", 88, "wall", 96, 9),
    ("gshop", 112, "ground", 96, 12),
    ("gres", 112, "ground", 96, 12),
    ("cornice", 24, "band", 96, 2.4),
    ("roofc", 48, "roof", 64, None),
    ("rooff", 64, "flat", 256, 16),
    ("props", 40, "props", None, None),
]
PROPS = {"tank": [0.0, 0.25], "ac": [0.25, 0.375], "tarp": [0.375, 0.625], "signA": [0.625, 0.8125], "signB": [0.8125, 1.0]}


# ------------------------------------------------------------------ noise
def vnoise(w, h, cell, rng, wrapy=False):
    """value noise, periodic in x (w % cell == 0), optionally in y."""
    gw = max(1, w // cell)
    gh = max(1, h // cell) if wrapy else h // cell + 2
    g = rng.random((gh, gw))
    xs = np.arange(w) / cell
    ys = np.arange(h) / cell
    x0 = np.floor(xs).astype(int)
    fx = xs - x0
    x1 = (x0 + 1) % gw
    x0 = x0 % gw
    y0 = np.floor(ys).astype(int)
    fy = ys - y0
    if wrapy:
        y1 = (y0 + 1) % gh
        y0 = y0 % gh
    else:
        y1 = np.minimum(y0 + 1, gh - 1)
    sx = fx * fx * (3 - 2 * fx)
    sy = (fy * fy * (3 - 2 * fy))[:, None]
    a = g[y0][:, x0]
    b = g[y0][:, x1]
    c = g[y1][:, x0]
    d = g[y1][:, x1]
    top = a + (b - a) * sx
    bot = c + (d - c) * sx
    return top + (bot - top) * sy


def fbm(w, h, rng, cells=(128, 64, 32, 16, 8), wrapy=False):
    out = np.zeros((h, w))
    amp, tot = 1.0, 0.0
    for c in cells:
        out += amp * vnoise(w, h, c, rng, wrapy)
        tot += amp
        amp *= 0.55
    return out / tot


def C(rgb):
    return tuple(int(max(0, min(255, round(c)))) for c in rgb)


def shade(rgb, k):
    return C(tuple(c * k for c in rgb))


def mix(a, b, t):
    return C(tuple(a[i] + (b[i] - a[i]) * t for i in range(3)))


# ------------------------------------------------------------------ a row canvas
class Row:
    def __init__(self, name, h1, seed):
        self.name = name
        self.w = W * S
        self.h = h1 * S
        self.rng = np.random.default_rng(seed)
        self.r = __import__("random").Random(seed)
        self.img = Image.new("RGB", (self.w, self.h), (236, 234, 228))
        self.mask = Image.new("L", (self.w, self.h), 0)
        self.d = ImageDraw.Draw(self.img)
        self.m = ImageDraw.Draw(self.mask)
        self.sills = []  # (x0, x1, y, strength): rain streaks run down from these
        self.clean = np.zeros((self.h, self.w))  # 1 = less grime (glass, signs)

    # plaster: near white, mottled, with repaired patches
    def slab_streaks(self, y=0, density=0.5, s=0.7):
        """black streaks running down from the slab / ledge above (every Yangon wall has them)."""
        x = 0
        while x < self.w:
            sw = self.r.randrange(4, 26)
            if self.r.random() < density:
                self.sills.append((x, x + sw, y, s * self.r.uniform(0.4, 1.2)))
            x += sw + self.r.randrange(2, 30)

    def plaster(self, base=(228, 225, 218), mottle=0.05, patches=10):
        n = fbm(self.w, self.h, self.rng)
        fine = vnoise(self.w, self.h, 4, self.rng)
        a = np.array(base, float)[None, None, :] * (1 - mottle * (n - 0.5) * 2)[:, :, None]
        a *= (1 - 0.035 * (fine - 0.5) * 2)[:, :, None]
        img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))
        d = ImageDraw.Draw(img)
        for _ in range(patches):
            x = self.r.randrange(0, self.w)
            y = self.r.randrange(0, self.h)
            pw, ph = self.r.randrange(20, 90), self.r.randrange(14, 60)
            k = self.r.choice([0.93, 0.96, 1.02, 0.9])
            col = shade(base, k)
            for dx in (0, -self.w):
                d.rectangle([x + dx, y, x + dx + pw, y + ph], fill=col)
        self.img = img.filter(ImageFilter.GaussianBlur(0.8))
        self.d = ImageDraw.Draw(self.img)

    def rect(self, box, fill, glow=0):
        """anything drawn covers the lit window behind it in the mask too (glow=None leaves the mask alone)."""
        x0, y0, x1, y1 = box
        self.d.rectangle([x0, y0, x1, y1], fill=fill)
        if glow is not None:
            self.m.rectangle([x0, y0, x1, y1], fill=glow)

    def line(self, pts, fill, width, glow=None):
        self.d.line(pts, fill=fill, width=width)
        if glow is not None:
            self.m.line(pts, fill=glow, width=width)

    def shadow_below(self, x0, x1, y, depth, k=0.55):
        """a soft shadow under a ledge."""
        for i in range(depth):
            t = 1 - i / depth
            a = np.array(self.img.crop((x0, y + i, x1, y + i + 1)), float) * (1 - (1 - k) * t * t)
            self.img.paste(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)), (x0, y + i))
        self.d = ImageDraw.Draw(self.img)

    def finish(self, grime=0.18, mould_top=0.0, mould_bottom=0.0, streak=1.0):
        a = np.array(self.img, float) / 255
        h, w = self.h, self.w
        grime *= 1.35  # (pilot 2026-11-14: in Studio's light the walls read too clean and white)
        dirt = np.zeros((h, w))
        # rain streaks under sills / ledges
        for x0, x1, y, s in self.sills:
            for x in range(max(0, x0), min(w, x1)):
                if self.r.random() < 0.55:
                    L = int(self.r.uniform(0.25, 1.0) * (h - y) * s)
                    if L <= 2:
                        continue
                    amt = self.r.uniform(0.06, 0.26) * streak
                    ys = np.arange(L)
                    fade = (1 - ys / L) ** 1.6
                    y1 = min(h, y + L)
                    dirt[y:y1, x] += amt * fade[: y1 - y]
        dirt = np.array(Image.fromarray((np.clip(dirt, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.6)), float) / 255
        n = fbm(w, h, self.rng, (64, 32, 16, 8))
        # grime: soft, and stretched downwards (rain), not round clouds
        v = np.array(Image.fromarray((fbm(w, h, self.rng, (32, 16, 8)) * 255).astype(np.uint8)).resize((w, max(1, h // 6))).resize((w, h), Image.BICUBIC), float) / 255
        g = grime * (0.55 * np.clip((n - 0.4) * 1.6, 0, 1) + 0.6 * np.clip((v - 0.45) * 2.0, 0, 1)) * (1 - 0.7 * self.clean)
        ys = np.linspace(0, 1, h)[:, None]
        mould = np.zeros((h, w))
        if mould_top:
            mould += mould_top * np.clip(1 - ys / 0.22, 0, 1) ** 1.5 * (0.5 + n)
        if mould_bottom:
            mould += mould_bottom * np.clip((ys - 0.72) / 0.28, 0, 1) ** 1.5 * (0.5 + n)
        mould = np.clip(mould, 0, 0.75) * (1 - 0.6 * self.clean)
        mc = np.array([0.30, 0.33, 0.28])
        a = a * (1 - dirt[:, :, None] * 0.9) * (1 - g[:, :, None])
        a = a * (1 - mould[:, :, None]) + mc[None, None, :] * mould[:, :, None] * a.mean(axis=2, keepdims=True) * 0.9
        self.img = Image.fromarray(np.clip(a * 255, 0, 255).astype(np.uint8))
        self.d = ImageDraw.Draw(self.img)


# ------------------------------------------------------------------ pieces
CURTAINS = [(232, 196, 150), (214, 120, 120), (120, 160, 210), (230, 220, 190), (190, 120, 170), (240, 200, 90),
            (150, 190, 150), (250, 236, 210), (200, 90, 70), (110, 120, 170)]
GRILL = [(46, 48, 52), (46, 48, 52), (58, 60, 64), (226, 226, 220), (60, 110, 80), (52, 84, 130), (120, 70, 50)]
CLOTH = [(200, 40, 50), (40, 90, 170), (240, 220, 80), (250, 250, 245), (40, 140, 90), (120, 60, 140), (230, 120, 40),
         (90, 60, 40), (220, 160, 180), (30, 30, 34), (90, 170, 200)]


def curtains(R, x0, y0, x1, y1, lit):
    r = R.r
    if r.random() < 0.22:
        R.rect((x0, y0, x1, y1), (34, 30, 28), 0)  # dark room, no curtain
        if lit:
            R.m.rectangle([x0, y0, x1, y1], fill=150)
        return
    c = r.choice(CURTAINS)
    R.rect((x0, y0, x1, y1), shade(c, 0.85), 255 if lit else 0)
    # folds
    step = r.choice([6, 8, 10])
    for x in range(x0, x1, step):
        R.d.line([(x, y0), (x, y1)], fill=shade(c, 0.68), width=2)
    if r.random() < 0.35:  # pattern (flowers / checks)
        for _ in range(int((x1 - x0) * (y1 - y0) / 90)):
            px, py = r.randrange(x0, max(x0 + 1, x1)), r.randrange(y0, max(y0 + 1, y1))
            R.d.ellipse([px - 2, py - 2, px + 2, py + 2], fill=shade(c, 1.15))
    if r.random() < 0.4:  # one side drawn open
        ox = r.choice([x0, (x0 + x1) // 2])
        R.rect((ox, y0, ox + (x1 - x0) // 2 - 2, y1), (40, 34, 30), 230 if lit else 0)
        if lit:
            R.m.rectangle([ox, y0, ox + (x1 - x0) // 2 - 2, y1], fill=230)


def grill(R, x0, y0, x1, y1, col=None, style=None):
    """steel window grills, drawn on their own layer and clipped to the box."""
    r = R.r
    col = col or r.choice(GRILL)
    style = style or r.choice(["bars", "bars", "grid", "diamond", "arch", "sun"])
    w, h = int(x1 - x0) + 1, int(y1 - y0) + 1
    lay = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(lay)
    if style in ("bars", "grid", "arch"):
        step = r.choice([9, 11, 13])
        for x in range(step, w, step):
            d.line([(x, 0), (x, h)], fill=255, width=2)
        hs = [h // 3, 2 * h // 3] if style != "grid" else list(range(step, h, step))
        for y in hs:
            d.line([(0, y), (w, y)], fill=255, width=2)
        if style == "arch":
            d.arc([0, -h // 3, w, h // 3], 0, 180, fill=255, width=2)
            d.arc([w // 4, -h // 6, 3 * w // 4, h // 6], 0, 180, fill=255, width=2)
    elif style == "sun":  # rays from the bottom middle, a common gate / window pattern
        for k in range(0, 13):
            a = math.pi * k / 12
            d.line([(w / 2, h), (w / 2 + math.cos(a) * w, h - math.sin(a) * w)], fill=255, width=2)
        d.arc([w / 2 - h * 0.45, h * 0.55, w / 2 + h * 0.45, h * 1.45], 180, 360, fill=255, width=2)
        d.line([(0, h // 2), (w, h // 2)], fill=255, width=2)
    else:
        step = r.choice([14, 18])
        for k in range(-h, w, step):
            d.line([(k, 0), (k + h, h)], fill=255, width=2)
            d.line([(k + h, 0), (k, h)], fill=255, width=2)
    d.rectangle([0, 0, w - 1, h - 1], outline=255, width=3)
    R.img.paste(Image.new("RGB", (w, h), col), (int(x0), int(y0)), lay)
    R.mask.paste(Image.new("L", (w, h), 0), (int(x0), int(y0)), lay)
    R.d = ImageDraw.Draw(R.img)
    R.m = ImageDraw.Draw(R.mask)
    R.sills.append((int(x0), int(x1), int(y1) + 2, 0.35))


def louvres(R, x0, y0, x1, y1, lit):
    frame = (196, 198, 196)
    R.rect((x0, y0, x1, y1), frame, 0)
    mid = (x0 + x1) // 2
    for (a, b) in ((x0 + 3, mid - 2), (mid + 2, x1 - 3)):
        R.rect((a, y0 + 3, b, y1 - 3), (40, 46, 52), 200 if lit else 0)
        for y in range(y0 + 5, y1 - 4, 7):
            R.d.line([(a, y), (b, y)], fill=(150, 172, 186), width=3)
            R.d.line([(a, y + 3), (b, y + 3)], fill=(70, 84, 96), width=1)
            if lit:
                R.m.line([(a, y + 3), (b, y + 3)], fill=90, width=1)


def hood(R, x0, x1, y, depth=9):
    """a concrete sun hood over a window, with its shadow."""
    R.rect((x0, y - depth, x1, y), (244, 242, 236))
    R.d.line([(x0, y - depth), (x1, y - depth)], fill=(214, 210, 202), width=2)
    R.shadow_below(max(0, x0), min(R.w, x1), y, 10, 0.5)
    R.sills.append((x0, x1, y, 0.5))


def sill(R, x0, x1, y):
    R.rect((x0 - 4, y, x1 + 4, y + 6), (242, 240, 234))
    R.d.line([(x0 - 4, y + 6), (x1 + 4, y + 6)], fill=(150, 146, 140), width=2)
    R.sills.append((x0, x1, y + 7, 1.0))


def ac_unit(R, x, y, w=54, h=36):
    R.rect((x, y, x + w, y + h), (226, 226, 222))
    R.d.rectangle([x, y, x + w, y + h], outline=(150, 150, 148), width=2)
    cx, cy, rr = x + w * 0.62, y + h / 2, h * 0.36
    R.d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=(70, 72, 74))
    for k in range(3):
        q = rr * (0.85 - 0.25 * k)
        R.d.ellipse([cx - q, cy - q, cx + q, cy + q], outline=(150, 152, 152), width=1)
    for yy in range(y + 6, y + h - 4, 5):
        R.d.line([(x + 5, yy), (x + w * 0.35, yy)], fill=(176, 176, 172), width=1)
    R.d.line([(x + 4, y + h), (x + 4, y + h + 6)], fill=(70, 70, 70), width=2)
    R.d.line([(x + w - 4, y + h), (x + w - 4, y + h + 6)], fill=(70, 70, 70), width=2)
    R.sills.append((x + 8, x + 20, y + h + 2, 1.0))  # the drip stain


def laundry(R, x0, x1, y, maxh):
    r = R.r
    R.d.line([(x0, y), (x1, y)], fill=(60, 60, 60), width=1)
    x = x0 + r.randrange(2, 12)
    while x < x1 - 10:
        cw = r.randrange(10, 30)
        ch = r.randrange(int(maxh * 0.4), maxh)
        c = r.choice(CLOTH)
        if x + cw > x1:
            break
        R.rect((x, y, x + cw, y + ch), c)
        k = r.random()
        if k < 0.3:  # longyi checks
            for yy in range(y, y + ch, 6):
                R.d.line([(x, yy), (x + cw, yy)], fill=shade(c, 0.7), width=2)
            for xx in range(x, x + cw, 6):
                R.d.line([(xx, y), (xx, y + ch)], fill=shade(c, 0.75), width=2)
        elif k < 0.5:
            R.rect((x, y + ch * 0.6, x + cw, y + ch * 0.75), shade(c, 0.6))
        R.d.line([(x + cw - 2, y), (x + cw - 2, y + ch)], fill=shade(c, 0.75), width=2)
        x += cw + r.randrange(2, 10)


def plants(R, x0, x1, y):
    r = R.r
    x = x0 + r.randrange(0, 20)
    while x < x1 - 16:
        pw = r.randrange(12, 22)
        R.rect((x + 2, y - 10, x + pw - 2, y), r.choice([(160, 80, 50), (60, 60, 64), (200, 120, 60)]))
        for _ in range(10):
            px = x + r.randrange(0, pw)
            py = y - 10 - r.randrange(0, 20)
            rr = r.randrange(3, 7)
            R.d.ellipse([px - rr, py - rr, px + rr, py + rr], fill=r.choice([(60, 120, 50), (80, 140, 60), (40, 96, 44)]))
        x += pw + r.randrange(6, 40)


def slab_line(R, y, h=10):
    """the floor slab edge at the bottom of a floor row."""
    R.rect((0, y, R.w, y + h), (240, 238, 232))
    R.d.line([(0, y), (R.w, y)], fill=(200, 196, 188), width=2)
    R.d.line([(0, y + h), (R.w, y + h)], fill=(168, 164, 156), width=2)


def pier(R, x, y0, y1, w=14):
    R.rect((x, y0, x + w, y1), (242, 240, 234))
    R.d.line([(x + w, y0), (x + w, y1)], fill=(196, 192, 184), width=2)


def brick_patch(R, x0, y0, x1, y1):
    R.rect((x0, y0, x1, y1), (150, 92, 70))
    for i, y in enumerate(range(y0, y1, 6)):
        R.d.line([(x0, y), (x1, y)], fill=(196, 180, 160), width=1)
        off = 6 if i % 2 else 0
        for x in range(x0 + off, x1, 12):
            R.d.line([(x, y), (x, y + 6)], fill=(196, 180, 160), width=1)


def pipe(R, x, y0, y1):
    R.rect((x, y0, x + 5, y1), (74, 76, 78))
    R.d.line([(x + 1, y0), (x + 1, y1)], fill=(120, 122, 124), width=1)
    for y in range(y0 + 20, y1, 60):
        R.rect((x - 2, y, x + 7, y + 3), (60, 60, 60))


# ------------------------------------------------------------------ rows
BW = 128 * S  # a bay


def row_walkup(R):
    R.plaster()
    h = R.h
    slab = h - 12
    for b in range(8):
        x = b * BW
        kind = ["win", "bal", "stair", "louvre"][b % 4]
        lit = R.r.random() < 0.42
        if kind == "win":
            wx0, wx1, wy0, wy1 = x + 34, x + 222, 34, 132
            hood(R, wx0 - 14, wx1 + 14, wy0 - 2)
            R.rect((wx0 - 4, wy0 - 4, wx1 + 4, wy1 + 4), (200, 196, 188))
            if R.r.random() < 0.5:
                curtains(R, wx0, wy0, wx1, wy1, lit)
            else:
                mid = (wx0 + wx1) // 2
                curtains(R, wx0, wy0, mid - 2, wy1, lit)
                louvres(R, mid + 2, wy0, wx1, wy1, lit and R.r.random() < 0.5)
            grill(R, wx0 - 2, wy0 - 2, wx1 + 2, wy1 + 2)
            sill(R, wx0, wx1, wy1 + 4)
            if R.r.random() < 0.6:
                ac_unit(R, x + R.r.choice([20, 180]), wy1 + 10, 54, 30)
        elif kind == "louvre":
            wx0, wx1, wy0, wy1 = x + 30, x + 226, 36, 130
            hood(R, wx0 - 10, wx1 + 10, wy0 - 2)
            louvres(R, wx0, wy0, wx1, wy1, lit)
            if R.r.random() < 0.7:
                grill(R, wx0, wy0, wx1, wy1)
            sill(R, wx0, wx1, wy1)
            if R.r.random() < 0.6:
                ac_unit(R, x + 98, wy1 + 10, 58, 30)
        elif kind == "bal":
            bx0, bx1 = x + 14, x + BW - 14
            # recess: ceiling shadow, back wall, door
            R.rect((bx0, 6, bx1, slab), (150, 146, 138))
            R.rect((bx0 + 30, 26, bx0 + 96, slab), (52, 44, 40), 0)
            curtains(R, bx0 + 34, 30, bx0 + 92, slab - 4, lit)
            R.rect((bx0 + 120, 40, bx1 - 20, 110), (60, 56, 52))
            curtains(R, bx0 + 124, 44, bx1 - 24, 106, lit and R.r.random() < 0.5)
            R.shadow_below(bx0, bx1, 6, 30, 0.35)
            laundry(R, bx0 + 6, bx1 - 6, 30, 60)
            # front parapet + grill
            par = 104
            R.rect((bx0 - 4, par, bx1 + 4, slab), (238, 236, 230))
            R.d.line([(bx0 - 4, par), (bx1 + 4, par)], fill=(250, 250, 246), width=3)
            plants(R, bx0 + 4, bx1 - 4, par)
            grill(R, bx0, 8, bx1, par, style=R.r.choice(["bars", "diamond", "grid"]))
            R.sills.append((bx0, bx1, slab + 1, 0.6))
            pier(R, x, 0, slab)
            pier(R, x + BW - 14, 0, slab)
        else:  # stair well: breeze-block screen
            sx0, sx1 = x + 74, x + 182
            R.rect((sx0 - 6, 4, sx1 + 6, slab), (226, 224, 218))
            cell = 18
            for yy in range(10, slab - 12, cell):
                for xx in range(sx0, sx1 - cell + 2, cell):
                    R.rect((xx + 2, yy + 2, xx + cell - 3, yy + cell - 3), (36, 34, 32), 210 if lit else 0)
                    R.d.line([(xx + cell // 2, yy + 2), (xx + cell // 2, yy + cell - 3)], fill=(214, 212, 206), width=2)
                    R.d.line([(xx + 2, yy + cell // 2), (xx + cell - 3, yy + cell // 2)], fill=(214, 212, 206), width=2)
            R.sills.append((sx0, sx1, slab, 0.5))
            if R.r.random() < 0.5:
                pipe(R, x + 30, 0, slab)
    R.slab_streaks(0, 0.6, 0.8)
    slab_line(R, slab, 12)
    R.finish(grime=0.16, mould_top=0.35, mould_bottom=0.25)


def row_shopup(R):
    R.plaster(base=(230, 227, 220))
    h = R.h
    slab = h - 12
    for b in range(8):
        x = b * BW
        lit = R.r.random() < 0.45
        pier(R, x, 0, slab, 22)
        R.d.line([(x + 4, 0), (x + 4, slab)], fill=(220, 216, 208), width=2)
        # two tall shuttered openings, arched heads
        for k, ox in enumerate((44, 140)):
            wx0, wx1, wy0, wy1 = x + ox, x + ox + 74, 26, 128
            R.rect((wx0 - 6, wy0 - 10, wx1 + 6, wy0 - 2), (246, 244, 238))
            R.d.arc([wx0 - 6, wy0 - 22, wx1 + 6, wy0 + 6], 180, 360, fill=(210, 206, 198), width=3)
            R.shadow_below(wx0 - 6, wx1 + 6, wy0 - 2, 8, 0.6)
            col = R.r.choice([(70, 120, 90), (60, 90, 140), (120, 80, 50), (150, 150, 146), (90, 130, 140)])
            state = R.r.random()
            if state < 0.45:  # closed wooden shutters with louvres
                R.rect((wx0, wy0, wx1, wy1), col)
                mid = (wx0 + wx1) // 2
                R.d.line([(mid, wy0), (mid, wy1)], fill=shade(col, 0.6), width=2)
                for y in range(wy0 + 6, wy1 - 4, 6):
                    R.d.line([(wx0 + 4, y), (wx1 - 4, y)], fill=shade(col, 0.72), width=2)
                if lit:
                    R.m.rectangle([wx0, wy0, wx1, wy1], fill=40)
            else:
                curtains(R, wx0, wy0, wx1, wy1, lit)
                R.rect((wx0 - 10, wy0, wx0, wy1), col)
                R.rect((wx1, wy0, wx1 + 10, wy1), col)
                if R.r.random() < 0.6:
                    grill(R, wx0, wy0, wx1, wy1, style="bars")
            # iron balcony railing in front
            ry = 98
            rc = R.r.choice([(40, 42, 46), (40, 42, 46), (60, 100, 70)])
            R.line([(wx0 - 12, ry), (wx1 + 12, ry)], rc, 3)
            for xx in range(wx0 - 10, wx1 + 12, 7):
                R.line([(xx, ry), (xx, wy1 + 4)], rc, 2)
            R.rect((wx0 - 14, wy1 + 4, wx1 + 14, wy1 + 10), (232, 230, 224))
            R.sills.append((wx0 - 14, wx1 + 14, wy1 + 11, 1.0))
        if R.r.random() < 0.3:
            ac_unit(R, x + 100, 140, 50, 30)
        if R.r.random() < 0.25:  # a vertical sign board
            sc = R.r.choice([(200, 40, 40), (30, 80, 170), (240, 200, 40), (30, 140, 80)])
            R.rect((x + 116, 30, x + 136, 150), sc, 200)
            for yy in range(40, 140, 18):
                R.d.ellipse([x + 120, yy, x + 132, yy + 12], outline=(250, 250, 240), width=2)
    R.slab_streaks(0, 0.6, 0.8)
    slab_line(R, slab, 12)
    R.finish(grime=0.18, mould_top=0.45, mould_bottom=0.2)


def row_condo(R):
    R.plaster(base=(242, 242, 240), mottle=0.04, patches=3)
    h = R.h
    slab = h - 22
    for b in range(8):
        x = b * BW
        lit = R.r.random() < 0.4
        wx0, wx1, wy0, wy1 = x + 22, x + BW - 22, 34, slab - 14
        frame = (176, 180, 184)
        R.rect((wx0 - 4, wy0 - 4, wx1 + 4, wy1 + 4), frame)
        # glass: tinted, a sky reflection gradient
        tint = R.r.choice([(70, 110, 120), (60, 90, 110), (80, 100, 96), (90, 110, 130)])
        for yy in range(wy0, wy1):
            t = (yy - wy0) / max(1, wy1 - wy0)
            R.d.line([(wx0, yy), (wx1, yy)], fill=mix(shade(tint, 1.5), shade(tint, 0.7), t))
        R.clean[wy0:wy1, wx0:wx1] = 1
        if lit:
            R.m.rectangle([wx0, wy0, wx1, wy1], fill=170)
            cc = R.r.choice(CURTAINS)
            R.rect((wx0 + 4, wy0 + 4, wx0 + (wx1 - wx0) // 2, wy1 - 4), mix(cc, tint, 0.4), 255)
        elif R.r.random() < 0.5:
            cc = R.r.choice(CURTAINS)
            R.rect((wx0 + 4, wy0 + 4, wx1 - 4, wy1 - 4), mix(cc, tint, 0.55), 0)
        for k in (1, 2, 3):
            xx = wx0 + (wx1 - wx0) * k // 4
            R.d.line([(xx, wy0), (xx, wy1)], fill=frame, width=4)
        R.d.line([(wx0, wy0 + 18), (wx1, wy0 + 18)], fill=frame, width=3)
        if R.r.random() < 0.55:
            ac_unit(R, x + R.r.choice([30, 150]), slab - 40, 50, 30)
        if b % 4 == 1:  # glass balcony rail
            R.rect((x + 10, slab - 40, x + BW - 10, slab), (150, 176, 180))
            R.d.line([(x + 10, slab - 40), (x + BW - 10, slab - 40)], fill=(220, 222, 224), width=4)
            R.clean[slab - 40:slab, x + 10:x + BW - 10] = 1
    # spandrel tiles
    R.rect((0, slab, R.w, h), (226, 222, 214))
    for xx in range(0, R.w, 16):
        R.d.line([(xx, slab), (xx, h)], fill=(206, 202, 194), width=1)
    R.d.line([(0, slab), (R.w, slab)], fill=(190, 186, 178), width=2)
    R.d.line([(0, slab + 11), (R.w, slab + 11)], fill=(206, 202, 194), width=1)
    R.rect((0, 0, R.w, 10), (226, 222, 214))
    R.finish(grime=0.12, mould_top=0.12, mould_bottom=0.1, streak=0.5)


def row_house(R):
    R.plaster(base=(240, 236, 226))
    h = R.h
    for b in range(8):
        x = b * BW
        lit = R.r.random() < 0.38
        kind = ["win", "pair", "plain", "win", "pair", "win", "plain", "pair"][b]
        col = R.r.choice([(250, 250, 246), (70, 120, 90), (120, 80, 50), (60, 90, 140), (230, 230, 226)])
        if kind == "plain":
            if R.r.random() < 0.5:
                R.rect((x + 110, 60, x + 140, 84), col)  # a small vent
                for yy in range(62, 84, 5):
                    R.d.line([(x + 112, yy), (x + 138, yy)], fill=shade(col, 0.6), width=2)
            continue
        ws = [(x + 70, x + 186)] if kind == "win" else [(x + 30, x + 112), (x + 144, x + 226)]
        for wx0, wx1 in ws:
            wy0, wy1 = 44, 136
            R.rect((wx0 - 8, wy0 - 8, wx1 + 8, wy1 + 4), shade(col, 0.95) if col[0] > 200 else (236, 232, 222))
            curtains(R, wx0, wy0, wx1, wy1, lit)
            # jalousie louvre leaves, often one open
            mid = (wx0 + wx1) // 2
            for (a, bb, open_) in ((wx0, mid, R.r.random() < 0.4), (mid, wx1, R.r.random() < 0.4)):
                if open_:
                    continue
                R.rect((a, wy0, bb, wy1), col)
                for yy in range(wy0 + 4, wy1 - 2, 6):
                    R.d.line([(a + 3, yy), (bb - 3, yy)], fill=shade(col, 0.7), width=2)
                R.d.rectangle([a, wy0, bb, wy1], outline=shade(col, 0.6), width=2)
                if lit:
                    R.m.rectangle([a, wy0, bb, wy1], fill=50)
            sill(R, wx0, wx1, wy1 + 4)
    R.rect((0, 0, R.w, 12), (210, 206, 198))  # eaves shadow line
    R.shadow_below(0, R.w, 12, 16, 0.6)
    R.slab_streaks(28, 0.5, 0.6)
    R.finish(grime=0.16, mould_top=0.25, mould_bottom=0.45)


def row_party(R):
    R.plaster(base=(234, 232, 226), mottle=0.1, patches=26)
    h = R.h
    for b in range(8):
        x = b * BW
        r = R.r.random()
        if r < 0.3:
            brick_patch(R, x + R.r.randrange(10, 120), R.r.randrange(10, 100), x + R.r.randrange(140, 240), R.r.randrange(110, 170))
        elif r < 0.45:
            vx = x + R.r.randrange(40, 180)
            R.rect((vx, 50, vx + 26, 76), (60, 58, 56), 120 if R.r.random() < 0.3 else 0)
            for yy in range(52, 76, 5):
                R.d.line([(vx, yy), (vx + 26, yy)], fill=(200, 196, 190), width=2)
            R.sills.append((vx, vx + 26, 78, 1.0))
        if b in (2, 6):
            pipe(R, x + 60, 0, h)
        if R.r.random() < 0.5:  # cracks
            px, py = x + R.r.randrange(0, BW), R.r.randrange(0, h)
            for _ in range(14):
                nx, ny = px + R.r.randrange(-8, 9), py + R.r.randrange(2, 10)
                R.d.line([(px, py), (nx, ny)], fill=(150, 146, 140), width=1)
                px, py = nx, ny
        # mould runs down from the top
        for _ in range(4):
            sx = x + R.r.randrange(0, BW)
            R.sills.append((sx, sx + R.r.randrange(20, 70), 0, 1.4))
    R.d.line([(0, h - 2), (R.w, h - 2)], fill=(200, 196, 188), width=2)
    R.slab_streaks(0, 0.7, 1.0)
    R.finish(grime=0.22, mould_top=0.5, mould_bottom=0.35, streak=1.3)


def row_cage(R):
    """the front of a projecting grilled balcony cage (the most Yangon thing there is)."""
    R.plaster(base=(236, 234, 228))
    h = R.h
    par = 104
    slab = h - 12
    for b in range(8):
        x = b * BW
        lit = R.r.random() < 0.45
        # behind the grill: the dark balcony, a door, things
        R.rect((x, 4, x + BW, par), (64, 60, 56))
        R.rect((x + 30, 12, x + 110, par), (46, 40, 36))
        curtains(R, x + 34, 16, x + 106, par, lit)
        R.rect((x + 140, 26, x + 226, 90), (50, 46, 44))
        curtains(R, x + 144, 30, x + 222, 86, lit and R.r.random() < 0.6)
        R.shadow_below(x, x + BW, 4, 22, 0.4)
        laundry(R, x + 4, x + BW - 4, 18, 62)
        if R.r.random() < 0.4:
            R.rect((x + 160, par - 46, x + 210, par), R.r.choice([(40, 90, 160), (200, 60, 50), (60, 60, 64)]))  # a water drum
        # parapet panel
        R.rect((x, par, x + BW, slab), (240, 238, 232))
        R.d.line([(x, par), (x + BW, par)], fill=(252, 252, 248), width=4)
        if R.r.random() < 0.5:
            plants(R, x + 6, x + BW - 6, par)
        R.sills.append((x, x + BW, par + 3, 0.5))
        # grill
        col = R.r.choice(GRILL)
        grill(R, x + 2, 2, x + BW - 2, par, col=col, style=R.r.choice(["bars", "grid", "diamond", "bars"]))
        R.rect((x, 0, x + 6, slab), col)
        if R.r.random() < 0.35:
            ac_unit(R, x + 70, par + 14, 52, 32)
    slab_line(R, slab, 12)
    R.finish(grime=0.16, mould_top=0.2, mould_bottom=0.3)


SIGN = [(200, 30, 40), (24, 70, 160), (246, 206, 40), (30, 130, 70), (250, 250, 246), (230, 110, 30), (120, 40, 120),
        (20, 20, 24)]


def glyphs(R, x0, y0, x1, y1, col, glow):
    """round abstract shapes in the rhythm of Burmese lettering (not real text): open circles, c-shapes, double bowls,
    small marks above and below, word gaps."""
    r = R.r
    hgt = y1 - y0
    rr = hgt * 0.3
    cy = (y0 + y1) / 2
    x = x0 + r.randrange(2, 8)

    def ell(box, a=None, b=None, fill=None):
        if a is None:
            if fill is None:
                R.d.ellipse(box, outline=col, width=3)
                if glow:
                    R.m.ellipse(box, outline=255, width=3)
            else:
                R.d.ellipse(box, fill=col)
                if glow:
                    R.m.ellipse(box, fill=255)
        else:
            R.d.arc(box, a, b, fill=col, width=3)
            if glow:
                R.m.arc(box, a, b, fill=255, width=3)

    while x < x1 - 2 * rr:
        k = r.random()
        box = [x, cy - rr, x + 2 * rr, cy + rr]
        if k < 0.3:
            ell(box, 300, 240 + 360)  # open circle (gap at the top right)
        elif k < 0.5:
            ell(box, 90, 360)  # c / u shape
        elif k < 0.65:  # double bowl
            ell([x, cy - rr, x + 2 * rr, cy + rr], 0, 180)
            ell([x + 2 * rr - 3, cy - rr, x + 4 * rr - 3, cy + rr], 0, 180)
            R.d.line([(x + 1, cy), (x + 1, cy - rr)], fill=col, width=3)
            x += 2 * rr
        elif k < 0.8:
            ell(box)
            ell([x + rr * 0.7, cy - rr * 0.3, x + rr * 1.3, cy + rr * 0.3], fill=True)
        else:
            ell(box, 180, 450)
            R.d.line([(x + 2 * rr, cy), (x + 2 * rr, cy + rr * 1.6)], fill=col, width=3)  # a tail
        if r.random() < 0.25:  # a mark above or below
            mx = x + rr
            my = cy - rr * 1.7 if r.random() < 0.6 else cy + rr * 1.5
            ell([mx - rr * 0.35, my - rr * 0.35, mx + rr * 0.35, my + rr * 0.35], fill=True if r.random() < 0.5 else None)
        x += int(2 * rr + r.randrange(1, 4))
        if r.random() < 0.18:
            x += int(rr * 1.6)


def blocks(R, x0, y0, x1, y1, col, glow, bg):
    """a line of latin-like capitals as plain hollow blocks (not readable)."""
    x = int(x0)
    y0, y1 = int(y0), int(y1)
    while x < x1 - 8:
        cw = R.r.randrange(6, 13)
        R.rect((x, y0, x + cw, y1), col, 255 if glow else None)
        k = R.r.random()
        if k < 0.4:
            R.rect((x + 3, y0 + 3, x + cw - 3, y1 - 3), bg, 0)
        elif k < 0.7:
            R.rect((x + 3, y0 + (y1 - y0) // 2 - 1, x + cw, y0 + (y1 - y0) // 2 + 1), bg, 0)
        x += cw + R.r.randrange(2, 5)
        if R.r.random() < 0.18:
            x += 10


def sign_board(R, x0, y0, x1, y1, lit):
    r = R.r
    bg = r.choice(SIGN)
    fg = (250, 250, 246) if sum(bg) < 400 else r.choice([(200, 30, 40), (24, 40, 120), (20, 20, 24)])
    R.rect((x0, y0, x1, y1), bg, 235 if lit else 0)
    R.clean[y0:y1, x0:x1] = 0.8
    if r.random() < 0.5:  # a colour block / logo-ish circle
        cx = x0 + r.randrange(6, 30)
        R.d.ellipse([cx, y0 + 4, cx + (y1 - y0) - 8, y1 - 4], fill=r.choice(SIGN))
        x0 += (y1 - y0) + 2
    if r.random() < 0.4:
        R.rect((x0, y1 - (y1 - y0) // 3, x1, y1), shade(bg, 0.75), 235 if lit else 0)
    if r.random() < 0.55:
        glyphs(R, x0 + 6, y0 + 4, x1 - 6, y0 + (y1 - y0) * 0.66, fg, lit)
        if (y1 - y0) > 40 and r.random() < 0.7:
            blocks(R, x0 + 10, y0 + (y1 - y0) * 0.74, x0 + (x1 - x0) * r.uniform(0.4, 0.8), y1 - 5, fg, lit, bg)
    else:
        blocks(R, x0 + 8, y0 + (y1 - y0) * 0.16, x0 + (x1 - x0) * r.uniform(0.5, 0.9), y0 + (y1 - y0) * 0.5, fg, lit, bg)
        glyphs(R, x0 + 8, y0 + (y1 - y0) * 0.56, x1 - 8, y1 - 2, fg, lit)
    R.d.rectangle([x0, y0, x1, y1], outline=shade(bg, 0.6), width=2)


DUSTY = [(150, 60, 50), (60, 90, 140), (200, 170, 60), (210, 206, 196), (70, 120, 80), (160, 100, 60), (120, 80, 120),
         (190, 120, 110), (90, 90, 96), (230, 220, 200)]


def goods(R, x0, y0, x1, y1, kind=None):
    """inside an open shop: grocery shelves, a tea shop, a hardware / plastics shop or a phone shop."""
    r = R.r
    kind = kind or r.choice(["grocery", "grocery", "tea", "hardware", "phone"])
    R.rect((x0, y0, x1, y1), (40, 36, 33))
    R.rect((x0, y0, x1, y0 + 30), (30, 27, 25))
    if kind == "grocery":
        y = y0 + 22
        while y < y1 - 50:
            R.d.line([(x0 + 30, y + 14), (x1 - 4, y + 14)], fill=(96, 86, 74), width=2)
            x = x0 + 32
            while x < x1 - 6:
                gw = r.randrange(5, 14)
                if r.random() < 0.85:
                    R.rect((x, y + r.randrange(0, 7), x + gw, y + 13), shade(r.choice(DUSTY), r.uniform(0.6, 0.95)))
                x += gw + r.randrange(0, 4)
            y += 20
        for _ in range(r.randrange(3, 7)):  # snack strips hanging at the front
            hx = r.randrange(x0 + 4, x1 - 10)
            hc = r.choice(CLOTH)
            for k in range(r.randrange(3, 7)):
                R.rect((hx, y0 + 4 + k * 9, hx + 9, y0 + 11 + k * 9), shade(hc, 0.95 - 0.04 * k))
        for _ in range(r.randrange(2, 4)):  # rice sacks
            sx = r.randrange(x0 + 4, x1 - 34)
            R.d.ellipse([sx, y1 - 34, sx + 30, y1 - 2], fill=(214, 206, 186))
            R.d.line([(sx + 4, y1 - 18), (sx + 26, y1 - 18)], fill=(170, 60, 50), width=2)
    elif kind == "tea":
        R.rect((x0 + 10, y0 + 30, x1 - 10, y0 + 56), (230, 226, 210))  # menu board
        for k in range(3):
            R.d.line([(x0 + 16, y0 + 38 + k * 6), (x0 + 16 + r.randrange(30, (x1 - x0) - 40), y0 + 38 + k * 6)], fill=(60, 60, 60), width=2)
        for _ in range(r.randrange(3, 6)):  # low tables and plastic stools
            tx = r.randrange(x0 + 4, x1 - 40)
            R.rect((tx, y1 - 28, tx + 36, y1 - 22), r.choice([(230, 230, 226), (90, 140, 200), (220, 70, 60)]))
            R.rect((tx + 3, y1 - 22, tx + 6, y1 - 4), (180, 180, 176))
            R.rect((tx + 30, y1 - 22, tx + 33, y1 - 4), (180, 180, 176))
            sc = r.choice([(220, 60, 50), (40, 110, 200), (60, 160, 90)])
            sx = tx + r.choice([-14, 40])
            R.rect((sx, y1 - 16, sx + 12, y1 - 2), sc)
        R.rect((x1 - 50, y0 + 64, x1 - 8, y1 - 30), (150, 150, 150))  # the urn counter
    elif kind == "hardware":
        y = y0 + 34
        while y < y1 - 10:  # stacked buckets / basins
            x = x0 + 4
            while x < x1 - 20:
                bw = r.randrange(16, 30)
                c = r.choice([(60, 120, 200), (220, 60, 50), (240, 200, 50), (60, 160, 90), (230, 230, 226), (240, 120, 40)])
                R.d.polygon([(x, y), (x + bw, y), (x + bw - 3, y + 18), (x + 3, y + 18)], fill=shade(c, 0.85))
                R.d.line([(x, y + 2), (x + bw, y + 2)], fill=c, width=2)
                x += bw + r.randrange(1, 5)
            y += 22
        for k in range(r.randrange(4, 9)):  # pipes leaning
            px = x1 - 8 - k * 5
            R.d.line([(px, y0 + 34), (px - 10, y1)], fill=r.choice([(200, 200, 196), (90, 90, 96), (230, 200, 120)]), width=3)
    else:  # phone shop: a lit glass counter and posters
        for _ in range(r.randrange(2, 4)):
            px = r.randrange(x0 + 4, x1 - 40)
            R.rect((px, y0 + 36, px + 34, y0 + 84), r.choice(SIGN))
            R.rect((px + 6, y0 + 44, px + 28, y0 + 74), r.choice([(30, 30, 34), (200, 200, 210)]))
        R.rect((x0 + 8, y1 - 46, x1 - 8, y1 - 2), (140, 170, 180))
        R.rect((x0 + 12, y1 - 42, x1 - 12, y1 - 22), (220, 236, 240))
        for k in range(8):
            gx = x0 + 16 + k * ((x1 - x0 - 32) // 8)
            R.rect((gx, y1 - 38, gx + 8, y1 - 26), (40, 40, 44))


def row_gshop(R):
    R.plaster(base=(238, 236, 230))
    h = R.h
    floor = h - 16
    for b in range(8):
        x = b * BW
        lit = R.r.random() < 0.7
        pier(R, x, 0, floor, 18)
        sign_board(R, x + 22, 10, x + BW - 8, 58, lit or R.r.random() < 0.5)
        R.shadow_below(x + 22, x + BW - 8, 58, 6, 0.6)
        ox0, ox1, oy0, oy1 = x + 22, x + BW - 6, 66, floor
        state = [0.7, 0.1, 0.9, 0.5, 0.8, 0.2, 0.95, 0.75][b]  # open, shut, open, half, open, shut, open, open
        kind = ["grocery", None, "tea", "grocery", "hardware", None, "phone", "grocery"][b]
        if state < 0.42:  # roller shutter, closed
            col = R.r.choice([(110, 140, 170), (150, 160, 166), (90, 120, 150), (170, 172, 170), (70, 110, 140)])
            R.rect((ox0, oy0, ox1, oy1), col)
            for yy in range(oy0 + 4, oy1, 6):
                R.d.line([(ox0, yy), (ox1, yy)], fill=shade(col, 0.72), width=2)
                R.d.line([(ox0, yy + 2), (ox1, yy + 2)], fill=shade(col, 1.12), width=1)
            R.rect((ox0, oy0, ox1, oy0 + 10), shade(col, 0.8))
            R.rect(((ox0 + ox1) // 2 - 8, oy1 - 12, (ox0 + ox1) // 2 + 8, oy1 - 8), (40, 40, 40))
            R.sills.append((ox0, ox1, oy0 + 10, 0.4))
        elif state < 0.62:  # half open
            goods(R, ox0, oy0, ox1, oy1, kind)
            if lit:
                R.m.rectangle([ox0, oy0, ox1, oy1], fill=200)
            col = R.r.choice([(110, 140, 170), (150, 160, 166), (90, 120, 150)])
            sh = oy0 + int((oy1 - oy0) * R.r.uniform(0.3, 0.55))
            R.rect((ox0, oy0, ox1, sh), col, 0)
            for yy in range(oy0 + 4, sh, 6):
                R.d.line([(ox0, yy), (ox1, yy)], fill=shade(col, 0.72), width=2)
            R.d.line([(ox0, sh), (ox1, sh)], fill=(50, 50, 50), width=3)
        else:  # open shop with goods and a tube light
            goods(R, ox0, oy0, ox1, oy1, kind)
            if lit:
                R.m.rectangle([ox0, oy0, ox1, oy1], fill=220)
            R.rect((ox0 + 20, oy0 + 3, ox1 - 20, oy0 + 7), (250, 252, 250), 255)
            R.rect((ox0, oy0, ox1, oy0 + 6), (120, 140, 160), 0)  # the rolled-up shutter box
        # tiled step
    R.rect((0, floor, R.w, h), (170, 166, 160))
    for xx in range(0, R.w, 24):
        R.d.line([(xx, floor), (xx, h)], fill=(140, 136, 130), width=1)
    R.d.line([(0, floor), (R.w, floor)], fill=(120, 116, 110), width=2)
    R.finish(grime=0.24, mould_top=0.1, mould_bottom=0.3)


def row_gres(R):
    R.plaster(base=(236, 234, 228))
    h = R.h
    plinth = h - 22
    for b in range(8):
        x = b * BW
        lit = R.r.random() < 0.4
        kind = ["gate", "win", "door", "win", "gate", "meter", "win", "door"][b]
        if kind == "gate":  # folding steel gate in front of a dark entry
            gx0, gx1, gy0 = x + 30, x + 226, 50
            R.rect((gx0 - 8, gy0 - 10, gx1 + 8, gy0 - 2), (244, 242, 236))
            R.shadow_below(gx0 - 8, gx1 + 8, gy0 - 2, 8)
            R.rect((gx0, gy0, gx1, plinth), (74, 68, 62), 120 if lit else 0)
            R.rect((gx0 + 20, gy0 + 20, gx0 + 90, plinth), (52, 48, 44))  # a motorbike-free passage, a bicycle shape
            R.d.ellipse([gx0 + 110, plinth - 34, gx0 + 140, plinth - 4], outline=(30, 30, 30), width=3)
            R.d.ellipse([gx0 + 150, plinth - 34, gx0 + 180, plinth - 4], outline=(30, 30, 30), width=3)
            R.d.line([(gx0 + 125, plinth - 19), (gx0 + 145, plinth - 40), (gx0 + 165, plinth - 19)], fill=(30, 30, 30), width=3)
            if lit:
                R.rect((gx0 + 70, gy0 + 6, gx1 - 70, gy0 + 10), (250, 250, 246), 255)
            col = R.r.choice([(200, 200, 196), (70, 130, 90), (60, 100, 150), (150, 150, 150), (60, 60, 64)])
            for xx in range(gx0, gx1, 10):
                R.line([(xx, gy0), (xx + 5, (gy0 + plinth) // 2), (xx, plinth)], col, 2, 0)
            R.line([(gx0, gy0 + 4), (gx1, gy0 + 4)], col, 3, 0)
            R.line([(gx0, plinth - 4), (gx1, plinth - 4)], col, 3, 0)
        elif kind == "win":
            wx0, wx1, wy0, wy1 = x + 62, x + 194, 64, 150
            hood(R, wx0 - 12, wx1 + 12, wy0 - 2)
            if R.r.random() < 0.5:
                louvres(R, wx0, wy0, wx1, wy1, lit)
            else:
                curtains(R, wx0, wy0, wx1, wy1, lit)
            grill(R, wx0, wy0, wx1, wy1, style=R.r.choice(["bars", "grid", "diamond"]))
            sill(R, wx0, wx1, wy1)
        elif kind == "door":
            dx0, dx1, dy0 = x + 80, x + 176, 46
            R.rect((dx0 - 10, dy0 - 10, dx1 + 10, plinth), (226, 222, 214))
            col = R.r.choice([(120, 80, 50), (70, 110, 80), (60, 90, 140), (150, 150, 150)])
            R.rect((dx0, dy0, dx1, plinth), col)
            R.d.line([((dx0 + dx1) // 2, dy0), ((dx0 + dx1) // 2, plinth)], fill=shade(col, 0.6), width=2)
            for yy in (dy0 + 20, dy0 + 70, dy0 + 120):
                R.d.rectangle([dx0 + 8, yy, (dx0 + dx1) // 2 - 8, yy + 36], outline=shade(col, 0.7), width=2)
                R.d.rectangle([(dx0 + dx1) // 2 + 8, yy, dx1 - 8, yy + 36], outline=shade(col, 0.7), width=2)
            R.rect((dx0 + 30, dy0 - 30, dx1 - 30, dy0 - 14), (250, 250, 240), 255 if lit else 0)  # a door lamp
        else:  # meter boxes, wires, a pipe
            for k in range(3):
                R.rect((x + 40 + k * 34, 70, x + 66 + k * 34, 104), (210, 210, 206))
                R.d.rectangle([x + 40 + k * 34, 70, x + 66 + k * 34, 104], outline=(120, 120, 120), width=2)
                R.d.ellipse([x + 46 + k * 34, 78, x + 60 + k * 34, 92], fill=(60, 60, 60))
            for k in range(4):
                R.d.line([(x + 50 + k * 22, 70), (x + 40 + k * 30, 0)], fill=(30, 30, 30), width=2)
            pipe(R, x + 190, 0, plinth)
    R.rect((0, plinth, R.w, h), (150, 148, 144))
    R.d.line([(0, plinth), (R.w, plinth)], fill=(110, 108, 104), width=3)
    R.slab_streaks(0, 0.5, 0.6)
    R.finish(grime=0.18, mould_top=0.1, mould_bottom=0.6)


def row_cornice(R):
    R.plaster(base=(240, 238, 232), patches=6)
    h = R.h
    R.rect((0, 0, R.w, 8), (248, 246, 242))
    R.d.line([(0, 8), (R.w, 8)], fill=(170, 166, 158), width=2)
    R.shadow_below(0, R.w, 9, 6, 0.65)
    R.rect((0, h - 14, R.w, h - 8), (246, 244, 238))
    R.d.line([(0, h - 8), (R.w, h - 8)], fill=(176, 172, 164), width=2)
    for x in range(0, R.w, 3):
        if R.r.random() < 0.5:
            R.sills.append((x, x + 2, 9, 2.0))
    R.finish(grime=0.3, mould_top=0.6, mould_bottom=0.2, streak=1.5)


def row_roofc(R):
    """corrugated metal sheets: ridges run down the slope (V); rust; lapped sheets. Near white-grey so the roof colour tints it."""
    h, w = R.h, R.w
    n = fbm(w, h, R.rng, (128, 64, 32))
    xs = np.arange(w)
    pitch = 16  # 0.5 stud at 32 px a stud
    corr = 0.82 + 0.18 * np.sin(xs / pitch * 2 * np.pi)
    a = np.ones((h, w, 3)) * np.array([0.86, 0.86, 0.85])[None, None, :]
    sheet = 64  # sheets 2 studs wide
    tone = np.ones(w)
    rust = np.zeros((h, w))
    for s in range(w // sheet):
        k = R.r.random()
        tone[s * sheet:(s + 1) * sheet] = R.r.choice([1.0, 0.96, 0.92, 1.04, 0.88])
        if k < 0.35:
            amt = R.r.uniform(0.3, 0.85)
            col = vnoise(sheet, h, 16, R.rng)
            rust[:, s * sheet:(s + 1) * sheet] += amt * np.clip(col - 0.3, 0, 1)
    ys = np.linspace(0, 1, h)[:, None]
    rust += 0.5 * np.clip((ys - 0.55) / 0.45, 0, 1) * n  # eaves rust
    rust += 0.35 * np.clip(n - 0.55, 0, 1) * 3
    rust = np.clip(rust, 0, 1)
    # streaks along V (down the corrugations)
    streak = vnoise(w, h, 4, R.rng) * 0.0
    for x in range(0, w, pitch):
        if R.r.random() < 0.3:
            y0 = R.r.randrange(0, h)
            rust[y0:, x:x + 6] = np.clip(rust[y0:, x:x + 6] + R.r.uniform(0.2, 0.5), 0, 1)
    rc = np.array([0.58, 0.34, 0.20])
    a = a * (corr * tone)[None, :, None]
    a = a * (1 - rust[:, :, None]) + rc[None, None, :] * rust[:, :, None] * (corr * tone)[None, :, None]
    # lap lines between sheets
    for s in range(0, w, sheet):
        a[:, s:s + 2] *= 0.6
    a[:6] = a[:6] * 0.7 + 0.25  # ridge cap
    a = a * (1 - 0.15 * (n - 0.5))[:, :, None] + streak[:, :, None]
    R.img = Image.fromarray(np.clip(a * 255, 0, 255).astype(np.uint8))
    R.d = ImageDraw.Draw(R.img)


def row_rooff(R):
    """flat concrete roof: tiles in U AND V (strips of 16 studs meet without a seam)."""
    h, w = R.h, R.w
    n = fbm(w, h, R.rng, (64, 32, 16, 8), wrapy=True)
    fine = vnoise(w, h, 4, R.rng, wrapy=True)
    a = np.ones((h, w, 3)) * np.array([0.84, 0.83, 0.81])[None, None, :]
    a *= (1 - 0.18 * (n - 0.5) * 2)[:, :, None]
    a *= (1 - 0.05 * (fine - 0.5) * 2)[:, :, None]
    stain = np.clip((vnoise(w, h, 32, R.rng, True) - 0.55) * 3, 0, 1)
    moss = np.clip((vnoise(w, h, 16, R.rng, True) - 0.7) * 4, 0, 1)
    a = a * (1 - 0.35 * stain[:, :, None])
    mc = np.array([0.32, 0.36, 0.28])
    a = a * (1 - moss[:, :, None] * 0.6) + mc[None, None, :] * moss[:, :, None] * 0.6
    img = Image.fromarray(np.clip(a * 255, 0, 255).astype(np.uint8))
    d = ImageDraw.Draw(img)
    # cracks and tar patches, wrapped
    for _ in range(30):
        px, py = R.r.randrange(0, w), R.r.randrange(0, h)
        for _ in range(R.r.randrange(10, 40)):
            nx, ny = px + R.r.randrange(-6, 7), py + R.r.randrange(-6, 7)
            for ox in (0, -w, w):
                for oy in (0, -h, h):
                    d.line([(px + ox, py + oy), (nx + ox, ny + oy)], fill=(120, 118, 114), width=1)
            px, py = nx, ny
    for _ in range(6):
        px, py = R.r.randrange(0, w), R.r.randrange(0, h)
        for _ in range(R.r.randrange(3, 8)):
            qx, qy, q = px + R.r.randrange(-20, 20), py + R.r.randrange(-12, 12), R.r.randrange(5, 14)
            for ox in (0, -w, w):
                for oy in (0, -h, h):
                    d.ellipse([qx + ox - q, qy + oy - q * 0.7, qx + ox + q, qy + oy + q * 0.7], fill=(78, 78, 80))
    R.img = img.filter(ImageFilter.GaussianBlur(0.7))
    R.d = ImageDraw.Draw(R.img)


def row_props(R):
    h, w = R.h, R.w
    R.img = Image.new("RGB", (w, h), (230, 230, 228))
    R.d = ImageDraw.Draw(R.img)
    u = lambda f: int(f * w)
    # tank: ribbed plastic (horizontal ribs), near white so vertex colour tints it
    t0, t1 = u(PROPS["tank"][0]), u(PROPS["tank"][1])
    for y in range(h):
        k = 0.78 + 0.22 * math.sin(y / h * 2 * math.pi * 5)
        R.d.line([(t0, y), (t1, y)], fill=C((236 * k, 236 * k, 234 * k)))
    for x in range(t0, t1, 6):
        R.d.line([(x, 0), (x, h)], fill=(220, 220, 218), width=1)
    # AC unit face
    a0, a1 = u(PROPS["ac"][0]), u(PROPS["ac"][1])
    R.rect((a0, 0, a1, h), (232, 232, 228))
    cx, cy, rr = (a0 + a1) * 0.5 + 30, h / 2, h * 0.36
    R.d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=(70, 72, 74))
    for k in range(3):
        q = rr * (0.85 - 0.25 * k)
        R.d.ellipse([cx - q, cy - q, cx + q, cy + q], outline=(160, 160, 160), width=2)
    for yy in range(8, h - 6, 6):
        R.d.line([(a0 + 8, yy), (a0 + 70, yy)], fill=(180, 180, 176), width=2)
    # tarp: folds and dirt, near white so the vertex colour makes it blue / green / orange
    p0, p1 = u(PROPS["tarp"][0]), u(PROPS["tarp"][1])
    n = vnoise(p1 - p0, h, 16, R.rng)
    for x in range(p0, p1):
        k = 0.85 + 0.15 * math.sin((x - p0) / 23.0) * math.sin((x - p0) / 7.0)
        for y in range(0, h, 1):
            kk = k * (0.92 + 0.08 * n[y, x - p0])
            R.img.putpixel((x, y), C((240 * kk, 240 * kk, 238 * kk)))
    R.d = ImageDraw.Draw(R.img)
    for x in range(p0, p1, 40):
        R.d.line([(x, 0), (x, h)], fill=(200, 200, 198), width=2)
    # two sign boards
    for key in ("signA", "signB"):
        s0, s1 = u(PROPS[key][0]), u(PROPS[key][1])
        sign_board(R, s0 + 2, 2, s1 - 2, h - 3, True)
    R.clean[:] = 1


DRAW = {"walkup": row_walkup, "shopup": row_shopup, "condo": row_condo, "house": row_house, "party": row_party,
        "cage": row_cage, "gshop": row_gshop, "gres": row_gres, "cornice": row_cornice, "roofc": row_roofc,
        "rooff": row_rooff, "props": row_props}


def build(out):
    os.makedirs(out, exist_ok=True)
    atlas = Image.new("RGB", (W, W), (128, 128, 128))
    glow = Image.new("L", (W, W), 0)
    meta = {}
    y = 0
    for i, (name, h1, kind, su, sv) in enumerate(ROWS):
        R = Row(name, h1, 1400 + i * 37)
        DRAW[name](R)
        img = R.img.resize((W, h1), Image.LANCZOS)
        msk = R.mask.filter(ImageFilter.GaussianBlur(0.6)).resize((W, h1), Image.LANCZOS)
        top = y + GUTTER
        atlas.paste(img, (0, top))
        glow.paste(msk, (0, top))
        for g in range(GUTTER):  # gutters: copies of the edge lines
            atlas.paste(img.crop((0, 0, W, 1)), (0, top - 1 - g))
            atlas.paste(img.crop((0, h1 - 1, W, h1)), (0, top + h1 + g))
            glow.paste(msk.crop((0, 0, W, 1)), (0, top - 1 - g))
            glow.paste(msk.crop((0, h1 - 1, W, h1)), (0, top + h1 + g))
        meta[name] = dict(v0=(top + 0.5) / W, v1=(top + h1 - 0.5) / W, kind=kind, studs_u=su, studs_v=sv, bays=8,
                          px=[top, top + h1])
        if name == "props":
            meta[name]["regions"] = PROPS
        y = top + h1 + GUTTER
    assert y <= W, y
    atlas.save(os.path.join(out, "atlas.png"))
    glow.save(os.path.join(out, "atlas_glow.png"))
    # the night overlay's colour map: lit texels warmed up, alpha = the mask (the G layer is a see-through copy of the walls)
    a = np.array(atlas, float)
    g = np.array(glow, float)[:, :, None] / 255
    warm = np.array([255, 214, 150], float)[None, None, :]
    lit = np.clip(a * 0.55 + warm * 0.55, 0, 255)
    rgba = np.concatenate([lit, np.clip(g * 255 * 1.2, 0, 255)], axis=2).astype(np.uint8)
    Image.fromarray(rgba, "RGBA").save(os.path.join(out, "atlas_night.png"))
    json.dump(dict(size=W, gutter=GUTTER, rows=meta), open(os.path.join(out, "atlas.json"), "w"), indent=1)
    preview(atlas, glow, meta, os.path.join(out, "atlas_preview.png"))
    print("atlas", y, "px used;", ", ".join("%s %d-%d" % (k, v["px"][0], v["px"][1]) for k, v in meta.items()))


# ------------------------------------------------------------------ preview: elevations made of the rows
def strip(atlas, meta, name, u0, nb, tint, px_per_stud=10.67):
    m = meta[name]
    y0, y1 = m["px"]
    bay = W // 8
    out = Image.new("RGB", (nb * bay, y1 - y0))
    for k in range(nb):
        b = (u0 + k) % 8
        out.paste(atlas.crop((b * bay, y0, (b + 1) * bay, y1)), (k * bay, 0))
    a = np.array(out, float) * np.array(tint)[None, None, :] / 255
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def preview(atlas, glow, meta, path):
    P = 10.67  # px a stud
    sheet = Image.new("RGB", (2400, 1300), (150, 170, 190))
    night = Image.new("RGB", (2400, 1300), (14, 16, 26))
    sky = atlas.copy()
    gl = Image.merge("RGB", [glow, glow, glow])
    dark = Image.blend(atlas, Image.new("RGB", atlas.size, (0, 0, 0)), 0.85)
    lit = Image.composite(atlas, dark, glow)
    builds = [("walkup", 6, 4, (232, 218, 170), "gshop"), ("walkup", 5, 3, (200, 222, 202), "gres"),
              ("shopup", 4, 2, (240, 200, 170), "gshop"), ("condo", 12, 3, (236, 236, 232), "gshop"),
              ("house", 2, 2, (250, 240, 220), "gres"), ("party", 4, 2, (222, 210, 196), "gres"),
              ("cage", 6, 3, (214, 226, 236), "gshop")]
    for which, (img, dst) in enumerate(((atlas, sheet), (lit, night))):
        x = 20
        for name, floors, nb, tint, ground in builds:
            hgt = int((12 + 9 * floors) * P) + 30
            ybase = 1280
            g = strip(img, meta, ground, 0, nb, (tint[0] * 0.5 + 127, tint[1] * 0.5 + 127, tint[2] * 0.5 + 127))
            g = g.resize((g.width, int(12 * P)))
            dst.paste(g, (x, ybase - g.height))
            yy = ybase - g.height
            for f in range(floors):
                s = strip(img, meta, name, (f % 2) * 4, nb, tint)
                yy -= s.height
                dst.paste(s, (x, yy))
            if name != "house":
                c = strip(img, meta, "cornice", 0, nb, tint)
                dst.paste(c, (x, yy - c.height))
            x += nb * 128 + 30
            if x > 2200:
                break
    full = Image.new("RGB", (2400, 2600))
    full.paste(sheet, (0, 0))
    full.paste(night, (0, 1300))
    full.save(path)
    # the roofs / props rows at a glance
    r = Image.new("RGB", (1024, 300), (0, 0, 0))
    yy = 0
    for name in ("roofc", "rooff", "props", "cornice"):
        y0, y1 = meta[name]["px"]
        r.paste(atlas.crop((0, y0, 1024, y1)), (0, yy))
        yy += y1 - y0 + 6
    r.save(path.replace(".png", "_roofs.png"))


if __name__ == "__main__":
    build(OUT)
