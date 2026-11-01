# GYM ARC - Run Cards art (2 Nov 2026, Claude Code). Run: python make_runcards_art.py
# Makes, next to this file:
#   face_<Rarity>.png  384x576  the card face (dark aged parchment, ornate frame in the rarity colour, art window, name banner, gem)
#   back.png           384x576  the card back (dealt face down, then flipped)
#   art_<Type>.png     512x512  the picture in the art window (an engraved emblem over a glowing seal)
# Drawn at 3x and scaled down (smooth edges). No outside images: everything is drawn here.
import math, os, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops

OUT = os.path.dirname(os.path.abspath(__file__))
SS = 3
RARITY = {
    "Common": (170, 170, 178),
    "Rare": (70, 140, 255),
    "Epic": (170, 80, 255),
    "Legendary": (245, 190, 40),
}
# the art's own colour (the glow behind the emblem)
THEME = {
    "Chest": (226, 70, 70), "Shoulders": (240, 140, 50), "Back": (150, 95, 235), "Arms": (235, 60, 90),
    "Legs": (70, 150, 245), "Core": (240, 185, 60), "All": (250, 215, 110), "Trainers": (60, 200, 210),
    "Coins": (250, 200, 60), "Stamina": (90, 220, 130),
}
rng = np.random.default_rng(7)


def clamp(a):
    return np.clip(a, 0, 255).astype(np.uint8)


def noise(w, h, scale=1.0, blur=1.2):
    n = rng.normal(0, 1, (h, w)).astype(np.float32)
    img = Image.fromarray(clamp(128 + n * 40 * scale)).filter(ImageFilter.GaussianBlur(blur))
    return (np.asarray(img).astype(np.float32) - 128) / 40


def radial(w, h, cx, cy, r):
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    d = np.sqrt((x - cx) ** 2 + (y - cy) ** 2) / r
    return np.clip(1 - d, 0, 1)


def lerp(a, b, t):
    return a + (b - a) * t


def rgba(arr):
    return Image.fromarray(clamp(arr), "RGBA")


def mask_to_layer(mask, color, alpha=1.0):
    w, h = mask.size
    layer = Image.new("RGBA", (w, h), color + (0,))
    layer.putalpha(mask.point(lambda v: int(v * alpha)))
    return layer


def grad_fill(mask, top, bottom):
    """fill a mask with a vertical gradient"""
    w, h = mask.size
    t = np.linspace(0, 1, h, dtype=np.float32)[:, None, None]
    c = lerp(np.array(top, np.float32)[None, None, :], np.array(bottom, np.float32)[None, None, :], t)
    c = np.repeat(c, w, axis=1)
    a = np.asarray(mask).astype(np.float32)[:, :, None]
    return rgba(np.concatenate([c, a], axis=2))


def dilate(mask, px):
    # (a blur pushed back up: much faster than a big MaxFilter, soft enough for outlines and glows)
    if px <= 0:
        return mask
    return mask.filter(ImageFilter.GaussianBlur(px * 0.6)).point(lambda v: min(255, v * 3))


def erode(mask, px):
    return mask.filter(ImageFilter.MinFilter(px * 2 + 1)) if px > 0 else mask


# ---------------------------------------------------------------- the emblems (drawn on a mask, unit coords 0..1)
class Pen:
    def __init__(self, size):
        self.S = size
        self.m = Image.new("L", (size, size), 0)
        self.d = ImageDraw.Draw(self.m)
        self.lines = Image.new("L", (size, size), 0)  # engraved lines (cut into the emblem)
        self.ld = ImageDraw.Draw(self.lines)

    def p(self, x, y):
        return (x * self.S, y * self.S)

    def poly(self, pts, fill=255):
        self.d.polygon([self.p(*q) for q in pts], fill=fill)

    def ellipse(self, cx, cy, rx, ry, fill=255):
        self.d.ellipse([self.p(cx - rx, cy - ry), self.p(cx + rx, cy + ry)], fill=fill)

    def capsule(self, a, b, r, fill=255):
        ax, ay = self.p(*a)
        bx, by = self.p(*b)
        w = r * self.S
        self.d.line([(ax, ay), (bx, by)], fill=fill, width=int(w * 2))
        self.d.ellipse([ax - w, ay - w, ax + w, ay + w], fill=fill)
        self.d.ellipse([bx - w, by - w, bx + w, by + w], fill=fill)

    def cut(self, pts, width=0.012, closed=False):
        q = [self.p(*v) for v in pts]
        if closed:
            q.append(q[0])
        self.ld.line(q, fill=255, width=max(1, int(width * self.S)), joint="curve")

    def arc(self, cx, cy, rx, ry, a0, a1, width=0.012, steps=40):
        pts = [(cx + rx * math.cos(math.radians(a)), cy + ry * math.sin(math.radians(a))) for a in np.linspace(a0, a1, steps)]
        self.cut(pts, width)


def torso(pen, top_l, top_r, waist_l, waist_r, y0, y1, neck=0.07):
    pen.poly([(top_l, y0 + 0.03), (0.5 - neck, y0), (0.5 + neck, y0), (top_r, y0 + 0.03), (top_r + 0.01, y0 + 0.12),
              (waist_r, y1), (waist_l, y1), (top_l - 0.01, y0 + 0.12)])


def em_chest(pen):
    torso(pen, 0.17, 0.83, 0.32, 0.68, 0.24, 0.84)
    pen.ellipse(0.17, 0.3, 0.08, 0.08)
    pen.ellipse(0.83, 0.3, 0.08, 0.08)
    # the pecs: two plates and the line between them, the collarbones
    pen.cut([(0.5, 0.27), (0.5, 0.58)], 0.014)
    pen.arc(0.36, 0.42, 0.15, 0.13, 20, 175, 0.016)
    pen.arc(0.64, 0.42, 0.15, 0.13, 5, 160, 0.016)
    pen.cut([(0.24, 0.29), (0.44, 0.27)], 0.01)
    pen.cut([(0.56, 0.27), (0.76, 0.29)], 0.01)
    # the serratus under each pec
    for s in (-1, 1):
        for k in range(3):
            y = 0.6 + k * 0.05
            pen.cut([(0.5 + s * 0.24, y), (0.5 + s * 0.17, y + 0.025)], 0.009)


def em_shoulders(pen):
    # front view of the yoke: traps sloping up to the neck, two big round delts, the upper chest under them
    pen.poly([(0.22, 0.4), (0.4, 0.27), (0.44, 0.18), (0.56, 0.18), (0.6, 0.27), (0.78, 0.4), (0.74, 0.74), (0.26, 0.74)])
    pen.ellipse(0.22, 0.47, 0.17, 0.19)
    pen.ellipse(0.78, 0.47, 0.17, 0.19)
    for s in (-1, 1):
        cx = 0.5 + s * 0.28
        pen.arc(cx, 0.47, 0.17, 0.19, 0, 360, 0.0, 2)
        pen.cut([(cx - s * 0.02, 0.3), (cx + s * 0.02, 0.62)], 0.012)  # front / side delt split
        pen.arc(cx, 0.5, 0.12, 0.14, 40 if s > 0 else 100, 80 if s > 0 else 140, 0.012)
        pen.cut([(0.5 + s * 0.06, 0.24), (0.5 + s * 0.17, 0.33)], 0.012)  # the trap's edge
    pen.cut([(0.4, 0.42), (0.5, 0.46), (0.6, 0.42)], 0.012)  # the collarbones
    pen.cut([(0.5, 0.46), (0.5, 0.72)], 0.012)


def em_back(pen):
    pen.poly([(0.1, 0.3), (0.4, 0.22), (0.6, 0.22), (0.9, 0.3), (0.86, 0.42), (0.66, 0.86), (0.34, 0.86), (0.14, 0.42)])
    pen.ellipse(0.5, 0.15, 0.07, 0.08)
    pen.cut([(0.5, 0.24), (0.5, 0.86)], 0.014)
    pen.cut([(0.4, 0.23), (0.5, 0.42), (0.6, 0.23)], 0.012)  # the traps diamond
    pen.cut([(0.2, 0.4), (0.38, 0.58), (0.44, 0.78)], 0.014)  # the lats
    pen.cut([(0.8, 0.4), (0.62, 0.58), (0.56, 0.78)], 0.014)
    pen.arc(0.3, 0.33, 0.1, 0.06, 200, 340, 0.01)
    pen.arc(0.7, 0.33, 0.1, 0.06, 200, 340, 0.01)


def em_arms(pen):
    # a flexed arm: upper arm, the biceps peak, the forearm up, the fist
    pen.capsule((0.2, 0.68), (0.55, 0.66), 0.11)
    pen.ellipse(0.4, 0.55, 0.17, 0.14)
    pen.capsule((0.58, 0.66), (0.66, 0.32), 0.09)
    pen.ellipse(0.66, 0.24, 0.1, 0.1)
    pen.ellipse(0.17, 0.7, 0.1, 0.13)
    pen.arc(0.4, 0.57, 0.12, 0.08, 190, 340, 0.016)  # the peak's line
    pen.arc(0.66, 0.24, 0.06, 0.05, 200, 330, 0.01)
    pen.cut([(0.6, 0.6), (0.64, 0.42)], 0.01)
    pen.cut([(0.26, 0.74), (0.5, 0.76)], 0.01)


def em_legs(pen):
    # front view, hips to feet: each thigh sweeps out and has its teardrop over the knee, diamond calves, a clear gap
    pen.poly([(0.27, 0.1), (0.73, 0.1), (0.74, 0.2), (0.26, 0.2)])  # the hips
    for s in (-1, 1):
        def X(dx):
            return 0.5 + s * dx
        pen.poly([(X(0.02), 0.18), (X(0.23), 0.16), (X(0.26), 0.3), (X(0.24), 0.42), (X(0.17), 0.57), (X(0.07), 0.6), (X(0.035), 0.5), (X(0.02), 0.3)])
        pen.ellipse(X(0.065), 0.5, 0.045, 0.07)  # the teardrop
        pen.ellipse(X(0.12), 0.6, 0.065, 0.045)  # the knee
        pen.poly([(X(0.06), 0.6), (X(0.18), 0.62), (X(0.2), 0.7), (X(0.13), 0.88), (X(0.085), 0.88), (X(0.055), 0.72)])
        pen.ellipse(X(0.12), 0.92, 0.065, 0.03)  # the foot
        pen.cut([(X(0.12), 0.2), (X(0.17), 0.34), (X(0.15), 0.5)], 0.012)  # the quad lines
        pen.cut([(X(0.22), 0.3), (X(0.2), 0.44)], 0.01)
        pen.arc(X(0.065), 0.5, 0.03, 0.05, 0, 360, 0.0, 2)
        pen.cut([(X(0.045), 0.44), (X(0.09), 0.56)], 0.012)  # the teardrop's edge
        pen.cut([(X(0.13), 0.64), (X(0.12), 0.8)], 0.012)  # the calf split


def em_core(pen):
    torso(pen, 0.25, 0.75, 0.33, 0.67, 0.18, 0.88, neck=0.06)
    pen.cut([(0.5, 0.3), (0.5, 0.84)], 0.014)
    for y in (0.38, 0.52, 0.66):
        pen.cut([(0.37, y), (0.63, y + 0.01)], 0.012)
    pen.cut([(0.33, 0.32), (0.35, 0.8), (0.5, 0.86)], 0.012)
    pen.cut([(0.67, 0.32), (0.65, 0.8), (0.5, 0.86)], 0.012)
    pen.cut([(0.27, 0.42), (0.33, 0.48)], 0.008)
    pen.cut([(0.27, 0.52), (0.33, 0.58)], 0.008)
    pen.cut([(0.73, 0.42), (0.67, 0.48)], 0.008)
    pen.cut([(0.73, 0.52), (0.67, 0.58)], 0.008)


def star(cx, cy, r0, r1, n, rot=-90):
    pts = []
    for i in range(n * 2):
        r = r0 if i % 2 == 0 else r1
        a = math.radians(rot + i * 180 / n)
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def em_all(pen):
    pen.poly(star(0.5, 0.5, 0.42, 0.18, 8))
    pen.ellipse(0.5, 0.5, 0.2, 0.2)
    pen.cut([(x, y) for x, y in star(0.5, 0.5, 0.42, 0.18, 8)], 0.01, closed=True)
    pen.arc(0.5, 0.5, 0.15, 0.15, 0, 360, 0.012, 60)
    # a dumbbell in the middle
    pen.cut([(0.4, 0.5), (0.6, 0.5)], 0.02)
    pen.cut([(0.4, 0.44), (0.4, 0.56)], 0.03)
    pen.cut([(0.6, 0.44), (0.6, 0.56)], 0.03)


def em_trainers(pen):
    # a coach's whistle on its cord, and a clipboard behind it
    pen.poly([(0.2, 0.18), (0.6, 0.18), (0.6, 0.78), (0.2, 0.78)])
    pen.poly([(0.32, 0.13), (0.48, 0.13), (0.48, 0.21), (0.32, 0.21)])
    for y in (0.32, 0.42, 0.52):
        pen.cut([(0.27, y), (0.53, y)], 0.014)
    pen.ellipse(0.58, 0.64, 0.18, 0.18)
    pen.poly([(0.6, 0.47), (0.88, 0.42), (0.9, 0.55), (0.66, 0.58)])
    pen.arc(0.58, 0.64, 0.07, 0.07, 0, 360, 0.016, 50)
    pen.cut([(0.88, 0.48), (0.93, 0.3), (0.8, 0.12)], 0.012)


def em_coins(pen):
    for i in range(5):
        y = 0.8 - i * 0.07
        pen.ellipse(0.33, y, 0.2, 0.07)
        pen.d.rectangle([pen.p(0.13, y - 0.035), pen.p(0.53, y)], fill=255)
    for i in range(5):
        pen.arc(0.33, 0.8 - i * 0.07, 0.2, 0.07, 0, 180, 0.008)
    pen.ellipse(0.63, 0.46, 0.25, 0.25)
    pen.arc(0.63, 0.46, 0.19, 0.19, 0, 360, 0.014, 60)
    pen.cut(star(0.63, 0.46, 0.12, 0.05, 5), 0.012, closed=True)


def em_stamina(pen):
    pen.poly([(0.6, 0.08), (0.24, 0.55), (0.46, 0.55), (0.36, 0.92), (0.78, 0.4), (0.55, 0.4), (0.68, 0.08)])
    pen.cut([(0.55, 0.16), (0.36, 0.48)], 0.01)


EMBLEMS = {"Chest": em_chest, "Shoulders": em_shoulders, "Back": em_back, "Arms": em_arms, "Legs": em_legs, "Core": em_core,
           "All": em_all, "Trainers": em_trainers, "Coins": em_coins, "Stamina": em_stamina}


def seal(size, color):
    """the glowing seal behind an emblem: rings, ticks and a soft star"""
    S = size
    img = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(img)
    c = S / 2
    for r, w in ((0.46, 0.006), (0.43, 0.003), (0.3, 0.003)):
        d.ellipse([c - r * S, c - r * S, c + r * S, c + r * S], outline=255, width=max(1, int(w * S)))
    for i in range(72):
        a = math.radians(i * 5)
        r0, r1 = (0.43, 0.46) if i % 6 else (0.4, 0.49)
        d.line([(c + r0 * S * math.cos(a), c + r0 * S * math.sin(a)), (c + r1 * S * math.cos(a), c + r1 * S * math.sin(a))], fill=255,
               width=max(1, int(0.003 * S)))
    d.polygon([(c + x * S - 0.5 * S, c + y * S - 0.5 * S) for x, y in star(0.5, 0.5, 0.42, 0.3, 4, -90)], outline=255)
    return img


def make_art(name):
    W = 512 * SS
    col = np.array(THEME[name], np.float32)
    # background: near-black ink, the theme colour glowing from the middle, grain, a dark edge
    base = np.zeros((W, W, 3), np.float32) + np.array([16, 13, 14], np.float32)
    glow = radial(W, W, W / 2, W * 0.5, W * 0.62)[:, :, None]
    base += col[None, None, :] * (glow ** 1.6) * 0.55
    base += noise(W, W, 1.0, 1.5)[:, :, None] * 7
    edge = radial(W, W, W / 2, W / 2, W * 0.78)[:, :, None]
    base *= 0.35 + 0.65 * np.clip(edge * 1.4, 0, 1)
    img = rgba(np.concatenate([base, np.full((W, W, 1), 255, np.float32)], axis=2))
    # light rays
    rays = Image.new("L", (W, W), 0)
    rd = ImageDraw.Draw(rays)
    for i in range(16):
        a = math.radians(i * 22.5 + 6)
        w2 = math.radians(4)
        pts = [(W / 2, W / 2), (W / 2 + W * math.cos(a - w2), W / 2 + W * math.sin(a - w2)), (W / 2 + W * math.cos(a + w2), W / 2 + W * math.sin(a + w2))]
        rd.polygon(pts, fill=40)
    rays = rays.filter(ImageFilter.GaussianBlur(W * 0.01))
    rays = ImageChops.multiply(rays, Image.fromarray(clamp(radial(W, W, W / 2, W / 2, W * 0.55) * 255)))
    img.alpha_composite(mask_to_layer(rays, tuple(int(v) for v in np.minimum(col * 1.2, 255)), 1.0))
    # the seal
    s = seal(W, col)
    img.alpha_composite(mask_to_layer(s.filter(ImageFilter.GaussianBlur(W * 0.004)), tuple(int(v) for v in col), 0.55))
    img.alpha_composite(mask_to_layer(s, (255, 236, 200), 0.25))
    # the emblem, a little inset
    pen = Pen(W)
    EMBLEMS[name](pen)
    m = pen.m.resize((int(W * 0.78), int(W * 0.78)), Image.LANCZOS)
    lines = pen.lines.resize(m.size, Image.LANCZOS)
    full = Image.new("L", (W, W), 0)
    full.paste(m, (int(W * 0.11), int(W * 0.12)))
    cuts = Image.new("L", (W, W), 0)
    cuts.paste(lines, (int(W * 0.11), int(W * 0.12)))
    cuts = ImageChops.multiply(cuts, full)
    # glow behind it, a dark outline, the bone-and-gold body, the engraved lines, a top light
    img.alpha_composite(mask_to_layer(dilate(full, int(W * 0.02)).filter(ImageFilter.GaussianBlur(W * 0.03)), tuple(int(v) for v in col), 0.9))
    img.alpha_composite(mask_to_layer(dilate(full, int(W * 0.008)), (20, 14, 10), 1.0))
    body = grad_fill(full, (255, 244, 214), (196, 150, 82))
    img.alpha_composite(body)
    shade = ImageChops.subtract(full, ImageChops.offset(full, -int(W * 0.012), -int(W * 0.016))).filter(ImageFilter.GaussianBlur(W * 0.006))
    img.alpha_composite(mask_to_layer(shade, (90, 50, 20), 0.55))
    hi = ImageChops.subtract(full, ImageChops.offset(full, int(W * 0.008), int(W * 0.01))).filter(ImageFilter.GaussianBlur(W * 0.004))
    img.alpha_composite(mask_to_layer(hi, (255, 255, 240), 0.6))
    img.alpha_composite(mask_to_layer(cuts.filter(ImageFilter.GaussianBlur(1.5)), (60, 34, 14), 0.95))
    cut_hi = ImageChops.multiply(ImageChops.offset(cuts, 0, int(W * 0.004)), ImageChops.invert(cuts))
    img.alpha_composite(mask_to_layer(ImageChops.multiply(cut_hi, full), (255, 248, 225), 0.5))
    # sparkles
    sp = Image.new("L", (W, W), 0)
    sd = ImageDraw.Draw(sp)
    random.seed(hash(name) % 1000)
    for _ in range(26):
        x, y = random.uniform(0.08, 0.92) * W, random.uniform(0.08, 0.92) * W
        r = random.uniform(0.002, 0.006) * W
        sd.ellipse([x - r, y - r, x + r, y + r], fill=random.randint(120, 255))
    img.alpha_composite(mask_to_layer(sp.filter(ImageFilter.GaussianBlur(2)), (255, 240, 210), 0.9))
    img = img.resize((512, 512), Image.LANCZOS)
    img.save(os.path.join(OUT, f"art_{name}.png"))


# ---------------------------------------------------------------- card faces and the back
CW, CH = 384, 576
ART = (34, 66, 350, 318)  # the art window (x0, y0, x1, y1) at 1x
BANNER = (22, 330, 362, 382)


def metal(color, t):
    """a metallic tint of a colour, t 0..1 (dark .. light)"""
    c = np.array(color, np.float32)
    dark, light = c * 0.45, np.minimum(c * 0.6 + 140, 255)
    return tuple(int(v) for v in lerp(dark, light, t))


def ornate_frame(d, w, h, color, s):
    # outer rim (3 bands, light in the middle), inner thin line, corner pieces, top and bottom points
    def rr(inset, width, col, radius):
        d.rounded_rectangle([inset * s, inset * s, (w - inset) * s, (h - inset) * s], radius=radius * s, outline=col, width=max(1, int(width * s)))
    rr(3, 3, metal(color, 0.15), 18)
    rr(5.5, 2.5, metal(color, 0.85), 16)
    rr(8, 2, metal(color, 0.35), 14)
    rr(15, 1.2, metal(color, 0.6), 10)
    for cx, cy, sx, sy in ((0, 0, 1, 1), (w, 0, -1, 1), (0, h, 1, -1), (w, h, -1, -1)):
        x, y = cx + sx * 15, cy + sy * 15
        d.polygon([((x) * s, (y) * s), ((x + sx * 28) * s, (y) * s), ((x) * s, (y + sy * 28) * s)], fill=metal(color, 0.55))
        d.polygon([((x + sx * 4) * s, (y + sy * 4) * s), ((x + sx * 18) * s, (y + sy * 4) * s), ((x + sx * 4) * s, (y + sy * 18) * s)], fill=metal(color, 0.9))
        d.ellipse([(x + sx * 7 - 3) * s, (y + sy * 7 - 3) * s, (x + sx * 7 + 3) * s, (y + sy * 7 + 3) * s], fill=(25, 20, 18))
    for cx, cy, sy in ((w / 2, 8, 1), (w / 2, h - 8, -1)):
        d.polygon([((cx - 22) * s, cy * s), (cx * s, (cy + sy * 12) * s), ((cx + 22) * s, cy * s), (cx * s, (cy - sy * 7) * s)], fill=metal(color, 0.75))


def make_face(rarity):
    color = RARITY[rarity]
    W, H = CW * SS, CH * SS
    # aged dark parchment: warm charcoal, blotches, grain, darker edges
    base = np.zeros((H, W, 3), np.float32) + np.array([38, 32, 29], np.float32)
    blot = noise(W // 8, H // 8, 1.0, 3)
    blot = np.asarray(Image.fromarray(clamp(128 + blot * 40)).resize((W, H), Image.BICUBIC)).astype(np.float32) - 128
    base += blot[:, :, None] * 0.18
    base += noise(W, H, 1.0, 1.0)[:, :, None] * 5
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    ex = np.minimum(x, W - x) / (W * 0.18)
    ey = np.minimum(y, H - y) / (H * 0.12)
    edge = np.clip(np.minimum(ex, ey), 0, 1)[:, :, None]
    base *= 0.55 + 0.45 * edge
    base += np.array(color, np.float32)[None, None, :] * 0.06 * (1 - edge)
    img = rgba(np.concatenate([base, np.full((H, W, 1), 255, np.float32)], axis=2))
    # rounded card shape
    shape = Image.new("L", (W, H), 0)
    ImageDraw.Draw(shape).rounded_rectangle([0, 0, W - 1, H - 1], radius=20 * SS, fill=255)
    img.putalpha(shape)
    d = ImageDraw.Draw(img)
    # the art window: a dark well with a rarity rim (the art image sits on it in the game)
    x0, y0, x1, y1 = ART
    d.rectangle([(x0 - 6) * SS, (y0 - 6) * SS, (x1 + 6) * SS, (y1 + 6) * SS], fill=(14, 11, 10))
    d.rectangle([(x0 - 6) * SS, (y0 - 6) * SS, (x1 + 6) * SS, (y1 + 6) * SS], outline=metal(color, 0.25), width=2 * SS)
    d.rectangle([(x0 - 3) * SS, (y0 - 3) * SS, (x1 + 3) * SS, (y1 + 3) * SS], outline=metal(color, 0.8), width=2 * SS)
    # the name banner: a ribbon with notched ends
    bx0, by0, bx1, by1 = BANNER
    mid = (by0 + by1) / 2
    ribbon = [(bx0 * SS, by0 * SS), (bx1 * SS, by0 * SS), ((bx1 - 12) * SS, mid * SS), (bx1 * SS, by1 * SS), (bx0 * SS, by1 * SS), ((bx0 + 12) * SS, mid * SS)]
    d.polygon(ribbon, fill=(24, 19, 17))
    d.line(ribbon + [ribbon[0]], fill=metal(color, 0.75), width=2 * SS)
    d.line([((bx0 + 20) * SS, (by0 + 5) * SS), ((bx1 - 20) * SS, (by0 + 5) * SS)], fill=metal(color, 0.35), width=SS)
    d.line([((bx0 + 20) * SS, (by1 - 5) * SS), ((bx1 - 20) * SS, (by1 - 5) * SS)], fill=metal(color, 0.35), width=SS)
    # a divider with a small diamond under the description area
    dy = 500
    d.line([(70 * SS, dy * SS), (170 * SS, dy * SS)], fill=metal(color, 0.5), width=SS)
    d.line([(214 * SS, dy * SS), (314 * SS, dy * SS)], fill=metal(color, 0.5), width=SS)
    d.polygon([(192 * SS, (dy - 6) * SS), (198 * SS, dy * SS), (192 * SS, (dy + 6) * SS), (186 * SS, dy * SS)], fill=metal(color, 0.85))
    ornate_frame(d, CW, CH, color, SS)
    # the rarity gem at the bottom, glowing
    gem = Image.new("L", (W, H), 0)
    gd = ImageDraw.Draw(gem)
    gx, gy = CW / 2, 540
    gd.polygon([(gx * SS, (gy - 15) * SS), ((gx + 13) * SS, gy * SS), (gx * SS, (gy + 15) * SS), ((gx - 13) * SS, gy * SS)], fill=255)
    img.alpha_composite(mask_to_layer(dilate(gem, 6 * SS).filter(ImageFilter.GaussianBlur(8 * SS)), color, 0.8))
    img.alpha_composite(mask_to_layer(dilate(gem, 2 * SS), (20, 16, 14), 1))
    img.alpha_composite(grad_fill(gem, metal(color, 0.95), metal(color, 0.3)))
    shine = Image.new("L", (W, H), 0)
    ImageDraw.Draw(shine).polygon([(gx * SS, (gy - 11) * SS), ((gx + 5) * SS, (gy - 3) * SS), (gx * SS, (gy - 1) * SS), ((gx - 5) * SS, (gy - 3) * SS)], fill=200)
    img.alpha_composite(mask_to_layer(shine, (255, 255, 255), 0.8))
    img = img.resize((CW, CH), Image.LANCZOS)
    img.save(os.path.join(OUT, f"face_{rarity}.png"))


def make_back():
    W, H = CW * SS, CH * SS
    color = (214, 168, 70)
    base = np.zeros((H, W, 3), np.float32) + np.array([30, 22, 24], np.float32)
    base += noise(W, H, 1.0, 1.0)[:, :, None] * 5
    glow = radial(W, H, W / 2, H / 2, H * 0.55)[:, :, None]
    base += np.array([120, 30, 40], np.float32)[None, None, :] * glow * 0.35
    img = rgba(np.concatenate([base, np.full((H, W, 1), 255, np.float32)], axis=2))
    shape = Image.new("L", (W, H), 0)
    ImageDraw.Draw(shape).rounded_rectangle([0, 0, W - 1, H - 1], radius=20 * SS, fill=255)
    img.putalpha(shape)
    # a diamond lattice
    lat = Image.new("L", (W, H), 0)
    ld = ImageDraw.Draw(lat)
    step = 32 * SS
    for k in range(-H // step - 2, W // step + H // step + 2):
        ld.line([(k * step, 0), (k * step + H, H)], fill=60, width=SS)
        ld.line([(k * step, 0), (k * step - H, H)], fill=60, width=SS)
    inner = Image.new("L", (W, H), 0)
    ImageDraw.Draw(inner).rounded_rectangle([26 * SS, 26 * SS, W - 26 * SS, H - 26 * SS], radius=10 * SS, fill=255)
    img.alpha_composite(mask_to_layer(ImageChops.multiply(lat, inner), color, 0.5))
    d = ImageDraw.Draw(img)
    ornate_frame(d, CW, CH, color, SS)
    # the seal in the middle with a dumbbell
    S = int(260 * SS)
    s = seal(S, color)
    layer = Image.new("L", (W, H), 0)
    layer.paste(s, ((W - S) // 2, (H - S) // 2))
    img.alpha_composite(mask_to_layer(layer.filter(ImageFilter.GaussianBlur(4 * SS)), (230, 60, 80), 0.5))
    img.alpha_composite(mask_to_layer(layer, metal(color, 0.85), 0.9))
    pen = Pen(S)
    pen.capsule((0.28, 0.5), (0.72, 0.5), 0.03)
    for x in (0.28, 0.72):
        pen.d.rounded_rectangle([pen.p(x - 0.05, 0.36), pen.p(x + 0.05, 0.64)], radius=0.02 * S, fill=255)
    for x in (0.2, 0.8):
        pen.d.rounded_rectangle([pen.p(x - 0.035, 0.41), pen.p(x + 0.035, 0.59)], radius=0.015 * S, fill=255)
    db = Image.new("L", (W, H), 0)
    db.paste(pen.m, ((W - S) // 2, (H - S) // 2))
    img.alpha_composite(mask_to_layer(dilate(db, 3 * SS), (20, 14, 10), 1))
    img.alpha_composite(grad_fill(db, (255, 236, 190), (190, 140, 60)))
    img = img.resize((CW, CH), Image.LANCZOS)
    img.save(os.path.join(OUT, "back.png"))


if __name__ == "__main__":
    import sys
    only = sys.argv[1:]  # e.g. "Legs Shoulders": only those pictures
    if not only:
        for r in RARITY:
            make_face(r)
        make_back()
    for n in EMBLEMS:
        if not only or n in only:
            make_art(n)
    print("done:", sorted(f for f in os.listdir(OUT) if f.endswith(".png")))
