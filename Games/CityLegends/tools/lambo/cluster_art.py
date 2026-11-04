"""The Revuelto, Aventador SV and Aventador LP700-4 clusters, redrawn 1:1 from the owner's photos
(imports/refs/*_cluster_owner.png, 2026-11-04: "replicate these clusters to 1:1 and dont miss
anything"). Every coordinate below is a pixel of that car's photo, so the picture can be laid over
the photo to check it. Small drawings no font has (the car seen from above, oil cans, ...) are cut
from the photo with its dark floor taken off.

    python tools/lambo/cluster_art.py outdir [revuelto|sv|lp700]

Writes <name>_art.png (2x the photo's scale for the small SV: 4x) and <name>_compare.jpg (photo over
art). No maker's marks: none of the three screens has one.
"""

import glob
import math
import os
import sys

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
REFS = os.path.join(ROOT, "imports", "refs")
FONTDIR = sorted(glob.glob("C:/Users/USER/AppData/Local/Roblox/Versions/*/content/fonts/"))[-1]
REG = FONTDIR + "Roboto-Regular.ttf"
ROBO_B = FONTDIR + "Roboto-Bold.ttf"
TECH = FONTDIR + "Sarpanch-Bold.ttf"
TECH_R = FONTDIR + "Sarpanch-Regular.ttf"
WIDE = FONTDIR + "Michroma-Regular.ttf"
TITI = FONTDIR + "TitilliumWeb-Bold.ttf"
ARIAL_BI = "C:/Windows/Fonts/arialbi.ttf"
ARIAL_B = "C:/Windows/Fonts/arialbd.ttf"
ARIAL = "C:/Windows/Fonts/arial.ttf"

_fonts = {}


def font(path, size):
    k = (path, int(size))
    if k not in _fonts:
        _fonts[k] = ImageFont.truetype(path, int(size))
    return _fonts[k]


class Art:
    def __init__(self, photo, box, S=4, bg=(9, 10, 13)):
        self.photo = Image.open(os.path.join(REFS, photo)).convert("RGB")
        self.box = box
        self.ox, self.oy = box[0], box[1]
        self.W, self.H = box[2] - box[0], box[3] - box[1]
        self.S = S
        self.im = Image.new("RGB", (self.W * S, self.H * S), bg)
        self.d = ImageDraw.Draw(self.im)
        self.glow = Image.new("RGB", (self.W * S, self.H * S), (0, 0, 0))
        self.gd = ImageDraw.Draw(self.glow)

    def q(self, x, y):
        return ((x - self.ox) * self.S, (y - self.oy) * self.S)

    def line(self, pts, col, w=1.5, glow=None, gw=None):
        p = [self.q(*a) for a in pts]
        self.d.line(p, fill=col, width=max(1, int(round(w * self.S))), joint="curve")
        if glow:
            self.gd.line(p, fill=glow, width=max(1, int(round((gw or w * 2) * self.S))), joint="curve")

    def poly(self, pts, col):
        self.d.polygon([self.q(*a) for a in pts], fill=col)

    def rect(self, x0, y0, x1, y1, col):
        self.d.rectangle([self.q(x0, y0), self.q(x1, y1)], fill=col)

    def round_rect(self, x0, y0, x1, y1, r, col, outline=None, w=1):
        self.d.rounded_rectangle([self.q(x0, y0), self.q(x1, y1)], radius=r * self.S, fill=col, outline=outline, width=int(w * self.S))

    def circle(self, x, y, r, col, outline=None, w=1):
        a, b = self.q(x - r, y - r), self.q(x + r, y + r)
        self.d.ellipse([a, b], fill=col, outline=outline, width=max(1, int(w * self.S)))

    def text(self, x, y, s, path, size, col, anchor="mm", shear=0.0, track=0.0, rot=0.0, stroke=0.0, strokecol=(0, 0, 0), glow=None, scale_x=1.0):
        """(x, y) in photo pixels; size = font size in photo pixels; shear > 0 leans to the right"""
        S = self.S * 3
        f = font(path, size * S)
        # the width, with tracking
        adv = [f.getlength(ch) + track * S for ch in s]
        tw = sum(adv) - track * S
        asc, desc = f.getmetrics()
        pad = int(size * S)
        w, h = int(tw + pad * 2), int(asc + desc + pad * 2)
        fill = Image.new("L", (w, h), 0)
        dr = ImageDraw.Draw(fill)
        strokeim = Image.new("L", (w, h), 0) if stroke else None
        dsk = ImageDraw.Draw(strokeim) if stroke else None
        pen = pad
        for ch, a in zip(s, adv):
            cf = font(ROBO_B, size * S) if ch == ":" and path in (TECH, TECH_R) else f
            yy = pad + (size * S * 0.1 if ch == ":" else 0)
            if dsk:
                dsk.text((pen, yy), ch, font=cf, fill=255, stroke_width=int(stroke * S))
            dr.text((pen, yy), ch, font=cf, fill=255)
            pen += a
        bbox = fill.getbbox() or (0, 0, w, h)
        cy = (bbox[1] + bbox[3]) / 2

        def warp(im):
            if shear:
                im = im.transform((w, h), Image.AFFINE, (1, shear, -shear * cy, 0, 1, 0), Image.BICUBIC)
            if scale_x != 1.0:
                im = im.resize((int(w * scale_x), h), Image.LANCZOS)
            if rot:
                im = im.rotate(-rot, resample=Image.BICUBIC, center=(im.width / 2, cy), expand=False)
            return im.resize((max(1, im.width // 3), max(1, im.height // 3)), Image.LANCZOS)

        m = warp(fill)
        bb = m.getbbox() or (0, 0, m.width, m.height)
        ax = {"l": bb[0], "m": (bb[0] + bb[2]) / 2, "r": bb[2]}[anchor[0]]
        ay = {"t": bb[1], "m": (bb[1] + bb[3]) / 2, "b": bb[3]}[anchor[1]]
        X, Y = self.q(x, y)
        at = (int(round(X - ax)), int(round(Y - ay)))
        if stroke:
            sm = warp(strokeim)
            self.im.paste(Image.new("RGB", sm.size, strokecol), at, sm)
        self.im.paste(Image.new("RGB", m.size, col), at, m)
        if glow:
            self.glow.paste(Image.new("RGB", m.size, glow), at, m)

    def curved(self, cx, cy, r, mid_deg, s, path, size, col, track=0.0):
        """letters along a circle round (cx, cy), reading clockwise, centred on mid_deg (0 = up)"""
        f = font(path, size * 8)
        adv = [f.getlength(ch) / 8 + track for ch in s]
        total = sum(adv) - track
        a = mid_deg - math.degrees(total / r) / 2
        for ch, w in zip(s, adv):
            t = a + math.degrees((w - track) / 2 / r)
            x = cx + r * math.sin(math.radians(t))
            y = cy - r * math.cos(math.radians(t))
            self.text(x, y, ch, path, size, col, rot=t)
            a += math.degrees(w / r)

    def icon(self, box, floor=30, gain=1.3, at=None, tint=None):
        """a piece of the photo, its dark floor taken off, added over the art"""
        c = self.photo.crop(box)
        a = np.asarray(c).astype(float)
        a = np.clip((a - floor) * gain, 0, 255).astype("uint8")
        c = Image.fromarray(a).resize(((box[2] - box[0]) * self.S, (box[3] - box[1]) * self.S), Image.LANCZOS)
        X, Y = self.q(*(at or box[:2]))
        area = (int(X), int(Y), int(X) + c.width, int(Y) + c.height)
        under = self.im.crop(area)
        self.im.paste(ImageChops.lighter(under, c), area[:2])

    def cutout(self, box, t=70, soft=30):
        """a drawing on a coloured screen: only the pixels unlike the screen round it are taken"""
        c = self.photo.crop(box)
        a = np.asarray(c).astype(float)
        edge = np.concatenate([a[0], a[-1], a[:, 0], a[:, -1]])
        bg = np.median(edge, axis=0)
        d = np.sqrt(((a - bg) ** 2).sum(axis=2))
        m = np.clip((d - t) / soft, 0, 1) * 255
        size = ((box[2] - box[0]) * self.S, (box[3] - box[1]) * self.S)
        mask = Image.fromarray(m.astype("uint8")).resize(size, Image.BICUBIC)
        X, Y = self.q(*box[:2])
        self.im.paste(c.resize(size, Image.LANCZOS), (int(X), int(Y)), mask)

    def finish(self, out_scale, blur=5.0, strength=0.9):
        g = self.glow.filter(ImageFilter.GaussianBlur(blur * self.S))
        g2 = self.glow.filter(ImageFilter.GaussianBlur(blur * self.S * 0.4))
        a = np.asarray(self.im).astype(float) + (np.asarray(g).astype(float) + np.asarray(g2).astype(float) * 0.6) * strength
        im = Image.fromarray(np.clip(a, 0, 255).astype("uint8"))
        return im.resize((self.W * out_scale, self.H * out_scale), Image.LANCZOS)


def compare(art, im, out, label_h=0):
    ph = art.photo.crop(art.box)
    W = im.width
    ph2 = ph.resize((W, int(ph.height * W / ph.width)), Image.LANCZOS)
    im2 = im.resize((W, ph2.height), Image.LANCZOS)
    s = Image.new("RGB", (W, ph2.height * 2 + 14), (60, 60, 64))
    s.paste(ph2, (0, 0))
    s.paste(im2, (0, ph2.height + 14))
    s.convert("RGB").save(out, quality=92)


# ---------------------------------------------------------------------------------- Revuelto
def revuelto(outdir):
    A = Art("revuelto_cluster_owner.png", (330, 360, 1690, 860), S=4, bg=(11, 11, 13))
    PINK = (255, 214, 222)
    RED = (238, 34, 52)
    GREY = (108, 112, 120)
    WHITE = (236, 238, 242)
    # faint hex pattern at the right of the screen
    for row in range(0, 22):
        for col in range(0, 8):
            x = 1500 + col * 26 + (row % 2) * 13
            y = 520 + row * 15
            if 1505 < x < 1650:
                pts = [(x + 8 * math.cos(math.radians(a)), y + 8 * math.sin(math.radians(a))) for a in range(30, 391, 60)]
                A.line(pts, (15, 16, 19), 1)

    CX = 1010
    R_TOP, CY_TOP = 1501, 1918
    R_LOW, CY_LOW = 1426, 1907

    def top(th, k=0):
        a = math.radians(th)
        return (CX + (R_TOP - k) * math.sin(a), CY_TOP - (R_TOP - k) * math.cos(a))

    def low(th):
        a = math.radians(th)
        return (CX + R_LOW * math.sin(a), CY_LOW - R_LOW * math.cos(a))

    MARK = {4: -11.5, 5: -8.43, 6: -4.6, 7: 0.0, 8: 5.54, 9: 12.1, 10: 19.9}
    RED_FROM = 8.7  # degrees: the tape turns red here (8,500 rpm)
    START = -18.4

    def rpm_th(v):
        keys = sorted(MARK)
        if v <= 4:
            return MARK[4] + (v - 4) * 2.45
        for a, b in zip(keys, keys[1:]):
            if a <= v <= b:
                return MARK[a] + (MARK[b] - MARK[a]) * (v - a) / (b - a)
        return MARK[10]

    # the tape: two lines and cross bars (a ladder), thinner and closer towards its left end
    th = START
    steps = []
    while th < MARK[10]:
        steps.append(th)
        th += 0.62 if th > -7 else (0.48 if th > -13 else 0.3)
    steps.append(MARK[10])
    for a, b in zip(steps, steps[1:]):
        red = a >= RED_FROM
        col = (246, 44, 62) if red else (226, 230, 236)
        fade = min(1.0, (a - START) / 7.0)
        c2 = tuple(int(v * (0.3 + 0.7 * fade)) for v in col)
        h = 2.5 + 6.5 * min(1.0, (a - START) / 7.0)
        p0, p1 = top(a), top(b)
        q0, q1 = top(a, h), top(b, h)
        A.line([p0, p1], c2, 1.25)
        A.line([q0, q1], c2, 1.25)
        A.line([p0, q0], tuple(int(v * 0.8) for v in c2), 1.0)
    A.line([top(MARK[10]), top(MARK[10], 9)], RED, 1.2)
    # long ticks: at each thousand, thin grey ones between
    for v, th in MARK.items():
        col = RED if v >= 9 else (225, 228, 234)
        steps_ = 12
        for k in range(steps_):
            a = top(th, 7 + k * 2.6)
            b = top(th, 7 + (k + 1) * 2.6)
            f = (1 - k / steps_) ** 0.7
            A.line([a, b], tuple(int(c * f) for c in col), 1.7)
    for v in (4.5, 5.5, 6.5, 7.5, 8.5, 9.5):
        th = rpm_th(v)
        col = RED if v > 8.4 else (150, 155, 162)
        for k in range(14):
            a = top(th, 9 + k * 2.6)
            b = top(th, 9 + (k + 1) * 2.6)
            f = (1 - k / 14) * 0.7
            A.line([a, b], tuple(int(c * f) for c in col), 1.1)
    # the numbers
    for v, (x, y) in {4: (716, 494), 5: (797, 478), 6: (896, 466), 7: (1010, 461), 8: (1150, 466), 9: (1315, 489), 10: (1504, 544)}.items():
        col = (255, 38, 58) if v >= 9 else (240, 244, 248)
        A.text(x, y, str(v), TECH, 32, col, stroke=0.15, strokecol=col, glow=(90, 12, 20) if v >= 9 else None)
    # the grey arc under the numbers, cut at each thousand
    marks = sorted(MARK.values())
    th = -11.2
    while th < 19.6:
        nxt = th + 0.25
        near = any(abs(th - m) < 0.13 for m in marks)
        if not near:
            A.line([low(th), low(nxt)], (104, 108, 116), 2.2)
        th = nxt

    # the two chevrons, glowing pink
    GL = (120, 22, 40)
    A.line([(425, 476), (490, 499), (700, 435), (732, 397)], (150, 92, 104), 1.2)
    A.line([(462, 489), (490, 499), (700, 435), (722, 410)], PINK, 2.0, glow=GL, gw=5)
    A.line([(1287, 391), (1320, 425), (1527, 486), (1595, 461)], (150, 92, 104), 1.2)
    A.line([(1298, 403), (1320, 425), (1527, 486), (1560, 474)], PINK, 2.0, glow=GL, gw=5)

    # coolant, top left
    A.poly([(486, 474), (590, 441), (593, 451), (490, 486)], (226, 232, 240))
    A.line([(592, 448), (652, 430), (697, 418)], (90, 94, 100), 1.3)
    A.line([(652, 416), (654, 431), (695, 421), (690, 408)], (240, 44, 60), 1.8)
    A.text(473, 464, "50", REG, 18, WHITE)
    A.text(690, 398, "130", REG, 18, (244, 52, 66))
    A.icon((545, 412, 600, 442), floor=38, gain=1.5)

    # oil, top right
    A.line([(1322, 418), (1532, 476), (1537, 464)], (92, 96, 102), 1.3)
    A.line([(1325, 402), (1327, 418)], (240, 44, 60), 1.8)
    A.line([(1340, 404), (1337, 420), (1326, 417)], (240, 44, 60), 1.8)
    A.line([(1372, 412), (1369, 427)], (110, 114, 120), 1.3)
    A.poly([(1396, 422), (1422, 429), (1417, 438), (1393, 431)], (214, 224, 236))
    A.line([(1443, 432), (1440, 446), (1454, 449), (1457, 436)], (240, 44, 60), 1.8)
    A.line([(1488, 447), (1484, 460)], (110, 114, 120), 1.3)
    A.text(1326, 391, "170", REG, 18, (244, 52, 66))
    A.icon((1345, 386, 1405, 416), floor=38, gain=1.5)
    A.text(1422, 414, "50", REG, 18, WHITE)
    A.text(1452, 419, "145", REG, 18, (244, 52, 66))
    A.icon((1470, 420, 1502, 440), floor=38, gain=1.5)
    A.text(1515, 440, "psi", ROBO_B, 15, WHITE)
    A.text(1543, 453, "0", REG, 16, WHITE)

    # battery %, left
    A.text(391, 494, "100", REG, 18, (206, 208, 212))
    pts = [(382, 507), (376, 540), (371, 590), (367, 640), (366, 668)]
    A.line(pts, (92, 96, 102), 1.4)
    for y in (507, 557, 607):
        A.line([(354, y), (376 - (y - 507) * 0.1, y)], (70, 74, 80), 1.2)
    A.rect(353, 637, 364, 708, (224, 228, 236))
    A.line([(347, 659), (367, 659), (366, 709), (347, 709)], (240, 44, 60), 1.8)
    A.line([(367, 659), (366, 709)], (240, 44, 60), 1.8)
    A.text(363, 721, "0", REG, 17, (244, 52, 66))
    A.text(385, 720, "%", REG, 15, (160, 164, 170))
    A.icon((366, 688, 402, 712), floor=38, gain=1.5)

    # fuel %, right
    A.text(1626, 481, "100", REG, 18, (206, 208, 212))
    pts = [(1640, 492), (1651, 540), (1661, 600), (1668, 640)]
    A.line(pts, (92, 96, 102), 1.4)
    for y in (492, 544, 596):
        A.line([(1641 + (y - 492) * 0.13, y), (1668, y)], (70, 74, 80), 1.2)
    A.rect(1657, 595, 1669, 693, (224, 228, 236))
    A.line([(1655, 635), (1677, 635)], (240, 44, 60), 1.8)
    A.line([(1656, 635), (1656, 694), (1676, 694)], (240, 44, 60), 1.8)
    A.text(1659, 706, "0", REG, 17, (244, 52, 66))
    A.text(1635, 706, "%", REG, 15, (190, 194, 200))
    A.icon((1620, 668, 1656, 698), floor=38, gain=1.5)
    A.text(1604, 537, "ESC", ROBO_B, 11.5, (240, 40, 56))
    A.text(1604, 550, "CORSA", ROBO_B, 11.5, (240, 40, 56))

    # the top row
    A.text(798, 389, "42.5°C", REG, 21, WHITE)
    A.text(1216, 384, "13:59", REG, 22, WHITE)
    dots = [(847, 398), (883, 395), (919, 391), (955, 389), (991, 388), (1026, 387), (1062, 388), (1098, 390), (1134, 391), (1170, 395)]
    for x, y in dots:
        A.circle(x, y, 9.5, (19, 20, 23), outline=(37, 38, 43), w=1.3)

    # the frame round the car
    thin = (172, 176, 184)
    A.line([(412, 512), (702, 509)], thin, 1.1)
    A.line([(727, 535), (734, 717)], thin, 1.0)
    A.line([(710, 740), (432, 742)], thin, 1.1)
    A.line([(405, 720), (390, 537)], thin, 1.0)
    bright = (250, 232, 236)
    A.line([(390, 537), (390, 525), (400, 514), (414, 512)], bright, 1.9, glow=GL, gw=3)
    A.line([(700, 509), (715, 509), (726, 520), (727, 536)], bright, 1.9, glow=GL, gw=3)
    A.line([(734, 717), (735, 730), (722, 740), (708, 740)], bright, 1.9, glow=GL, gw=3)
    A.line([(434, 742), (420, 744), (406, 732), (405, 719)], bright, 1.9, glow=GL, gw=3)
    A.icon((508, 528, 640, 722), floor=24, gain=1.22)

    # the gear, hollow: a thin dashed line
    def dashed(pts, col, w=1.7, on=4.5, off=1.4):
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            d = math.hypot(x1 - x0, y1 - y0)
            n = max(1, int(d / (on + off)))
            for k in range(n):
                a = k / n
                b = a + on / (on + off) / n
                A.line([(x0 + (x1 - x0) * a, y0 + (y1 - y0) * a), (x0 + (x1 - x0) * b, y0 + (y1 - y0) * b)], col, w, glow=(70, 10, 18), gw=3)

    dashed([(975, 533), (1080, 532), (1093, 545), (1070, 622), (1060, 630), (981, 630), (957, 700), (920, 700), (975, 533)], (242, 40, 58))
    dashed([(1005, 564), (1050, 564), (1040, 597), (991, 597), (1005, 564)], (242, 40, 58))
    A.icon((1140, 680, 1200, 714), floor=34, gain=1.4)  # the car between its lane lines

    # speed
    A.round_rect(996, 752, 1030, 796, 4, None, outline=(246, 248, 250), w=7.5)
    A.text(1013, 810, "km/h", ROBO_B, 13, WHITE)
    A.round_rect(1092, 782, 1102, 795, 1.5, None, outline=(160, 164, 170), w=2.3)
    A.text(1097, 808, "MPH", REG, 12, (130, 134, 140))

    # bottom left and right
    A.line([(455, 755), (690, 754)], (40, 42, 46), 1.1)
    A.icon((508, 758, 540, 788), floor=38, gain=1.5)
    A.text(593, 771, "100.1 MHz", REG, 20, (222, 224, 228))
    A.icon((404, 754, 440, 802), floor=34, gain=1.4)
    A.icon((650, 808, 684, 830), floor=34, gain=1.5)

    def dial(cx, cy, col, word, wordcol, left, right):
        # a toothed ring
        prof = [(-88, 90), (-68, 91), (-66, 95), (-50, 96), (-47, 92), (-30, 93), (-27, 98), (-14, 98), (-11, 94), (11, 94), (14, 98), (27, 98), (30, 93), (47, 92), (50, 96), (66, 95), (68, 91), (88, 90)]
        pts = []
        for (a0, r0), (a1, r1) in zip(prof, prof[1:]):
            n = max(1, int(abs(a1 - a0) / 2))
            for k in range(n + 1):
                f = k / n
                t = math.radians(a0 + (a1 - a0) * f)
                r = r0 + (r1 - r0) * f
                pts.append((cx + r * math.sin(t), cy - r * math.cos(t)))
        A.line(pts, col, 1.8)
        A.curved(cx, cy, 75, 0, word, ROBO_B, 13.5, wordcol, track=0.5)
        A.line([(cx + 64 * math.sin(math.radians(x)), cy - 64 * math.cos(math.radians(x))) for x in range(-17, 18, 3)], (232, 234, 238), 2.0)
        for x in range(-62, 63, 4):
            t = math.radians(x)
            A.circle(cx + 55 * math.sin(t), cy - 55 * math.cos(t), 0.85, (200, 202, 208))
        A.line([(cx + 45 * math.sin(math.radians(x)), cy - 45 * math.cos(math.radians(x))) for x in range(-70, 71, 3)], (240, 228, 232), 3.0, glow=(80, 14, 24), gw=4)
        A.curved(cx, cy, 77, -59 if len(left) > 6 else -49, left, ROBO_B, 11, (88, 90, 96), track=0.2)
        A.curved(cx, cy, 77, 66 if len(right) > 8 else 50, right, ROBO_B, 11, (88, 90, 96), track=0.2)

    dial(782, 868, (232, 40, 56), "CORSA", (244, 48, 64), "SPORT", "ESC OFF")
    dial(1243, 868, (150, 154, 160), "HYBRID", (232, 234, 238), "RECHARGE", "PERFORMANCE")
    A.rect(330, 846, 1690, 860, (11, 11, 13))
    A.icon((1340, 786, 1366, 818), floor=34, gain=1.5)

    # the odometer
    A.line([(1336, 745), (1570, 743)], (120, 124, 130), 1.3)
    A.text(1343, 761, "001074", REG, 21, WHITE, anchor="lm", stroke=0.12, strokecol=WHITE)
    A.text(1417, 763, "km", ROBO_B, 14, WHITE, anchor="lm")
    A.line([(1448, 754), (1448, 770)], (190, 194, 200), 1.3)
    A.text(1461, 761, "174", REG, 21, WHITE, anchor="lm", stroke=0.12, strokecol=WHITE)
    A.text(1496, 763, "km", ROBO_B, 14, WHITE, anchor="lm")
    A.icon((1518, 750, 1560, 770), floor=34, gain=1.5)

    im = A.finish(2, blur=3.0, strength=0.8)
    im.save(os.path.join(outdir, "revuelto_art.png"))
    compare(A, im, os.path.join(outdir, "revuelto_compare.jpg"))


# ---------------------------------------------------------------------------- Aventador SV
def streaks(w, h, seed=3):
    """the yellow screen's light: a warm yellow, soft diagonal sweeps, fine lines"""
    y, x = np.mgrid[0:h, 0:w].astype(float)
    u, v = x / w, y / h
    base = np.zeros((h, w, 3))
    k = 0.52 + 0.28 * np.sin(u * 7.0 - v * 5.0 + 0.8) * np.exp(-((v - 0.65) ** 2) * 5) + 0.12 * np.sin(u * 19 + v * 9)
    k += 0.16 * np.sin((u - v * 0.45) * 26)
    fine = 0.035 * np.sin((u * 0.72 - v) * h / 4.4)
    k = np.clip(k + fine, 0, 1)
    lo = np.array([236, 182, 34.0])
    hi = np.array([255, 226, 96.0])
    for c in range(3):
        base[..., c] = lo[c] + (hi[c] - lo[c]) * k
    return Image.fromarray(base.astype("uint8"))


def sv(outdir):
    A = Art("aventador_sv_cluster_owner.png", (0, 92, 767, 400), S=6, bg=(8, 8, 10))
    W, H = A.W * A.S, A.H * A.S
    CX, CY, RX, RY = 383.0, 272.0, 212.0, 160.0
    black = (11, 11, 13)

    def e(phi, k=1.0):
        a = math.radians(phi)
        return (CX + RX * k * math.sin(a), CY - RY * k * math.cos(a))

    # the yellow screen: the big shape (a thin rim of yellow runs round the rev band), its lower
    # point, the two side panels
    glowY = streaks(W, H)
    mask = Image.new("L", (W, H), 0)
    md = ImageDraw.Draw(mask)
    Y = lambda pts: md.polygon([A.q(*p) for p in pts], fill=255)
    rim = [e(p, 1.03) for p in range(-27, 28, 2)]
    Y([(200, 125)] + rim + [(567, 125), (595, 193), (595, 240), (566, 266), (528, 268), (428, 322.5), (339, 321.5), (238, 266), (202, 266), (174, 240), (174, 193)])
    Y([(53, 218), (131, 221), (133, 268), (22, 267)])
    Y([(630, 225), (708, 226), (738, 275), (630, 275)])
    A.im.paste(glowY, (0, 0), mask)

    # the black under the band's two ends
    A.poly([(170, 230), (180, 232), (200, 238), (213, 233), (200, 246), (208, 254), (202, 266), (170, 266)], (8, 8, 10))
    A.poly([(600, 232), (590, 236), (568, 238), (556, 236), (566, 248), (560, 258), (566, 268), (600, 268)], (8, 8, 10))
    A.poly([(150, 266), (238, 266), (339, 322), (150, 322)], (8, 8, 10))
    A.poly([(528, 268), (620, 268), (620, 322), (428, 323)], (8, 8, 10))

    # the band's inner edge: an arc with a tab of yellow reaching up round each number
    NUM = {n: 20.2 * (n - 6) for n in range(2, 11)}
    edge = []
    for n in range(2, 11):
        ph = NUM[n]
        edge += [(ph - 7.2, 0.782), (ph - 4.4, 0.842), (ph + 4.4, 0.842), (ph + 7.2, 0.782)]

    def kin(ph):
        pts = sorted(edge)
        if ph <= pts[0][0]:
            return pts[0][1]
        for (a, ka), (b, kb) in zip(pts, pts[1:]):
            if a <= ph <= b:
                return ka + (kb - ka) * (ph - a) / max(b - a, 1e-6)
        return pts[-1][1]

    PHI0, PHI1 = -77.0, 77.0
    N = 32
    OUT = 1.0
    # the whole band black, then its bars' lines
    outer = [e(PHI0 + (PHI1 - PHI0) * i / 120, OUT) for i in range(121)]
    inner = [e(PHI1 - (PHI1 - PHI0) * i / 240, kin(PHI1 - (PHI1 - PHI0) * i / 240)) for i in range(241)]
    A.poly(outer + inner, (14, 16, 20))
    A.poly([e(50 + 27 * i / 40, OUT) for i in range(41)] + [e(77 - 27 * i / 40, kin(77 - 27 * i / 40)) for i in range(41)], (40, 6, 9))
    for i in range(N + 1):
        ph = PHI0 + (PHI1 - PHI0) * i / N
        red = ph >= 50.0
        if red:
            A.line([e(ph, OUT), e(ph - 1.0, kin(ph))], (214, 36, 40), 0.7)
        else:
            A.line([e(ph, OUT), e(ph - 0.5, kin(ph))], (236, 240, 244), 1.05)
            A.line([e(ph - 0.85, OUT), e(ph - 1.3, kin(ph))], (120, 124, 130), 0.5)
    # the white line along that edge
    A.line([e(p, kin(p)) for p in [PHI0 - 6 + i * 0.5 for i in range(int((PHI1 - PHI0 + 12) / 0.5) + 1)]], (236, 238, 242), 0.95)

    # the numbers
    for n, (x, y) in {2: (216, 252), 3: (246, 213), 4: (283, 182), 5: (331, 162), 6: (382, 155), 7: (437, 161), 8: (483, 182)}.items():
        A.text(x, y, str(n), TECH, 24, black, shear=0.24)
    A.text(524, 214, "9", TECH, 24, (238, 52, 48), shear=0.24, stroke=0.45, strokecol=(255, 236, 190))
    A.text(549, 253, "10", TECH, 24, (238, 52, 48), shear=0.24, stroke=0.45, strokecol=(255, 236, 190))
    A.line([(177, 230), (219, 253)], (240, 76, 76), 1.3, glow=(120, 20, 24), gw=2.2)

    # the gear: the owner's second photo, traced (2026-11-04, "make the N like this"): a heavy leaning
    # N, its top right and bottom right corners well rounded, two narrow notches, a thin white edge.
    # n5 numbers: pixels of the 8x crop of that photo; photo scale is about the same as the first one
    def n5(x, y):
        return (347.0 + (x - 300) * 0.1152, 178.5 + (y - 80) * 0.1275)

    def arc(cx, cy, r, a0, a1, steps=8):
        return [n5(cx + r * math.cos(math.radians(a0 + (a1 - a0) * k / steps)), cy + r * math.sin(math.radians(a0 + (a1 - a0) * k / steps))) for k in range(steps + 1)]

    N_pts = [n5(300, 745), n5(540, 80), n5(682, 80), n5(738, 540), n5(905, 80), n5(975, 80)]
    N_pts += arc(975, 145, 42, -90, 12)  # top right corner
    N_pts += [n5(835, 660)]
    N_pts += arc(745, 660, 88, 22, 90)  # bottom right corner
    N_pts += [n5(628, 748), n5(585, 360), n5(445, 748)]
    edge = N_pts + N_pts[:1]
    A.line(edge, (252, 244, 214), 1.5)
    A.poly(N_pts, black)
    A.line(edge, black, 0.5)

    # the gear strip
    A.text(335, 256, "R", TECH, 17, black, shear=0.24)
    A.text(419, 257, "1234567", TECH, 17.5, black, shear=0.24, track=1.1, anchor="lm")
    A.text(515, 255, "A", TECH, 24, black, shear=0.24, stroke=0.2, strokecol=black)

    # ESC SPORT
    A.text(306, 187, "ESC", ROBO_B, 7.5, (232, 236, 70), stroke=0.9, strokecol=(16, 16, 12))
    A.text(306, 196, "SPORT", ROBO_B, 7.5, (232, 236, 70), stroke=0.9, strokecol=(16, 16, 12))
    A.cutout((546, 150, 582, 176), t=60)

    # the bands under the dial: SPORT on the left, the odometer on the right
    A.line([(177, 266), (238, 266), (339, 322), (428, 323), (528, 268), (590, 268)], (196, 202, 210), 0.85)
    A.poly([(244, 268), (326, 268), (337, 274), (326, 280), (265, 280)], black)
    A.text(293, 274, "SPORT", ROBO_B, 9.2, (240, 62, 58), track=0.2)
    A.poly([(431, 275), (441, 269), (521, 269), (499, 280), (441, 280)], black)
    A.text(461, 275.5, "001200", ROBO_B, 9.2, (238, 242, 248), shear=0.24, track=0.25)
    A.text(492, 277, "mi", REG, 8, (238, 64, 56))
    A.text(196, 274, "mph", REG, 10, (236, 56, 60))
    A.text(575, 279, "rpm", REG, 10, (236, 56, 60))

    # the speed and the revs
    A.text(238, 293, "0", TECH, 31, (242, 247, 252), shear=0.24, stroke=0.25, strokecol=(242, 247, 252))
    A.text(272, 292, "0", TECH, 10, (112, 200, 240), shear=0.24)
    A.text(265, 301, "km/h", REG, 8.6, (112, 200, 240))
    A.text(546, 297, "1110", TECH, 31, (242, 247, 252), shear=0.24, track=6.8, stroke=0.25, strokecol=(242, 247, 252))

    # the g-force square, traced
    def G(x, y):
        return (320 + x / 10, 262 + y / 10)

    for rows in [[(580, 129), (690, 129), (697, 146), (573, 146)], [(569, 151), (701, 151), (706, 167), (564, 167)], [(557, 175), (713, 175), (718, 190), (552, 190)], [(544, 200), (724, 200), (730, 228), (538, 228)], [(492, 322), (775, 322), (782, 346), (486, 346)], [(475, 361), (795, 361), (803, 382), (466, 382)], [(455, 402), (815, 402), (822, 426), (447, 426)], [(436, 444), (830, 444), (838, 478), (428, 478)]]:
        A.poly([G(*p) for p in rows], black)
    for q in [[(263, 232), (317, 232), (253, 308), (200, 308)], [(335, 232), (385, 232), (325, 308), (277, 308)], [(405, 232), (450, 232), (398, 308), (350, 308)], [(472, 232), (510, 232), (475, 308), (423, 308)], [(760, 235), (795, 235), (845, 315), (792, 315)], [(820, 235), (862, 235), (915, 315), (868, 315)], [(885, 237), (925, 237), (988, 315), (940, 317)], [(950, 240), (990, 240), (1065, 317), (1010, 317)]]:
        A.poly([G(*p) for p in q], black)
    box = [G(565, 250), G(720, 250), G(728, 296), G(549, 296), G(565, 250)]
    A.line(box, black, 0.9)
    A.line([G(588, 262), G(700, 262), G(704, 284), G(580, 284), G(588, 262)], black, 0.7)
    for x, y in [(648, 85), (105, 268), (1185, 280), (625, 530)]:
        A.text(*G(x, y), "0.0", TECH_R, 9.5, black, shear=0.24, stroke=0.1, strokecol=black)

    # the left panel
    A.text(56, 231, "06:04", TECH, 16, black, shear=0.24, track=0.6, anchor="lm", stroke=0.1, strokecol=black)
    A.text(109, 235, "pm", REG, 9, (242, 84, 42), anchor="lm")
    A.text(48, 248, "10.08.2019", TECH, 11, black, shear=0.24, track=0.7, anchor="lm", stroke=0.05, strokecol=black)
    A.text(62, 260, "100.5", TECH, 11, black, shear=0.24, track=0.7, anchor="lm", stroke=0.05, strokecol=black)
    A.text(101, 260, "°F", REG, 10.5, (242, 84, 42), anchor="lm")

    def column(x0, x1, y0, y1, red_top, white_from, cells=12, red_bottom=None):
        A.rect(x0, y0, x1, y1, (12, 12, 14))
        A.rect(x0, y0, x1, red_top, (240, 86, 48))
        A.rect(x0, white_from, x1, y1, (232, 230, 214))
        if red_bottom:
            A.rect(x0, red_bottom, x1, y1, (240, 86, 48))
        for i in range(cells + 1):
            y = y0 + (y1 - y0) * i / cells
            A.line([(x0, y), (x1, y)], (120, 122, 124) if y < white_from else (150, 150, 138), 0.45)
        A.line([(x0, y0), (x0, y1)], (176, 178, 180), 0.55)
        A.line([(x1, y0), (x1, y1)], (176, 178, 180), 0.55)

    column(71.5, 84, 287, 353, 299, 322)
    A.line([(61, 320), (90, 320)], (238, 66, 54), 1.7)
    column(96, 111, 288, 353, 288, 288, red_bottom=337)
    A.line([(90, 285.5), (118, 285.5)], (238, 66, 54), 1.7)
    A.icon((66, 268, 116, 286), floor=26, gain=1.3)
    for x, y, t, c in [(57, 289, "130", (238, 66, 54)), (63, 319, "90", (230, 232, 236)), (65, 350, "50", (230, 232, 236)), (118, 290, "100", (230, 232, 236)), (122, 320, "50", (230, 232, 236)), (126, 351, "0", (238, 66, 54)), (640, 296, "170", (238, 66, 54)), (637, 327, "130", (230, 232, 236)), (638, 357, "50", (230, 232, 236)), (699, 296, "10", (238, 66, 54)), (697, 327, "4", (230, 232, 236)), (696, 357, "0", (230, 232, 236))]:
        A.text(x, y, t, TECH, 8.8, c, shear=0.24)
    A.text(55, 302, "°C", ROBO_B, 8.5, (220, 222, 226))
    A.text(123, 303, "%", ROBO_B, 7.5, (220, 222, 226))
    A.text(637, 310, "°C", ROBO_B, 8.5, (220, 222, 226))
    A.text(703, 310, "Bar", ROBO_B, 7.6, (220, 222, 226))

    # the right panel
    A.cutout((634, 238, 656, 264), t=90)
    A.text(658, 252, "252", TECH, 15.5, black, shear=0.24, track=1.0, anchor="lm", stroke=0.1, strokecol=black)
    A.text(693, 255, "mi", REG, 9.5, (242, 84, 42), anchor="lm")
    column(652, 666, 294, 359, 310, 339)
    A.line([(640, 335.5), (668, 335.5)], (238, 66, 54), 1.7)
    column(678, 691, 294, 359, 306, 350)
    A.line([(666, 348.5), (694, 348.5)], (238, 66, 54), 1.7)
    A.icon((645, 274, 702, 292), floor=26, gain=1.3)
    A.text(586, 361, "PARK", ROBO_B, 6.2, (240, 54, 58))

    im = A.finish(3, blur=1.2, strength=0.7)
    im.save(os.path.join(outdir, "sv_art.png"))
    compare(A, im, os.path.join(outdir, "sv_compare.jpg"))


# --------------------------------------------------------------------------- Aventador LP700
def lp700(outdir, live=False):
    """live: no needle, speed or big gear letter in the picture (the game draws those: CarSkin.DIAL_NEEDLES)"""
    A = Art("aventador_lp700_cluster_owner.png", (110, 150, 1400, 680), S=4, bg=(7, 7, 8))
    WHITE = (240, 244, 248)
    RED = (226, 30, 40)
    REDB = (238, 34, 44)
    GOLD = (226, 168, 44)
    CX, CY = 749.0, 412.0

    def pol(deg, r):
        a = math.radians(deg)
        return (CX + r * math.sin(a), CY - r * math.cos(a))

    def ang(v):
        return -180.0 + v * 30.0  # 0 at the bottom, 6 at the top, 9 at the right

    A.circle(CX, CY, 236, (9, 7, 8))

    # the arc inside: a dark band with a blue edge, wide and all blue at the lower left; the gold line
    TOP, BAND_R0, BAND_R1 = 141.0, 127.0, 143.0
    for x in range(0, 271):
        a0, a1 = 90 - x, 90 - x - 1.4
        A.poly([pol(a0, BAND_R0 - 2), pol(a1, BAND_R0 - 2), pol(a1, BAND_R1), pol(a0, BAND_R1)], (36, 37, 40))
        # how wide the blue is
        t = max(0.0, min(1.0, (x - 95) / 90))
        w = 3.4 + 15.0 * t * t * (3 - 2 * t)
        col = (72, 134, 156)
        A.poly([pol(a0, BAND_R1 - w), pol(a1, BAND_R1 - w), pol(a1, BAND_R1), pol(a0, BAND_R1)], col)
    A.line([pol(90 - x, 113) for x in range(0, 268, 3)], GOLD, 1.5)
    A.line([(778, 412), (862, 412)], GOLD, 1.5)
    A.rect(860, 412.5, 900, 418, (9, 7, 8))

    # the scale: a white line near the rim that dips at each 1,000; a grey band; ticks every 200
    def band_cell(a0, a1, col, r0=214.0, r1=225.0):
        A.poly([pol(a0, r0), pol(a1, r0), pol(a1, r1), pol(a0, r1)], col)

    GREY = (54, 56, 60)
    pts = [pol(ang(0) + 2.6, 215)]
    for v in range(0, 10):
        a = ang(v)
        if v > 0:
            pts += [pol(a - 3.4, 226.5), pol(a - 2.6, 215.5), pol(a + 2.6, 215.5), pol(a + 3.4, 226.5)]
        else:
            pts += [pol(a + 3.4, 226.5)]
    pts = pts[:-2]  # the line stops at 9
    for v in range(0, 9):
        a0, a1 = ang(v) + 3.2, ang(v + 1) - 3.2
        n = 12
        for i in range(n):
            f0, f1 = a0 + (a1 - a0) * i / n, a0 + (a1 - a0) * (i + 1) / n
            hot = (v == 7 and True) or (v == 8) or (v == 7)
            band_cell(f0, f1, REDB if v in (7, 8) else GREY)
    for v in range(1, 10):
        a = ang(v)
        A.poly([pol(a - 2.5, 217), pol(a + 2.5, 217), pol(a + 2.5, 226), pol(a - 2.5, 226)], GREY)
    for k in range(1, 46):
        if k % 5:
            a = ang(k / 5)
            A.line([pol(a, 226), pol(a, 213)], WHITE, 1.5)
        else:
            a = ang(k / 5)
            A.line([pol(a, 212), pol(a, 203)], WHITE, 1.9)
    A.line(pts, WHITE, 2.5)
    A.line([pol(86.4, 226.5), (977, 412), (960, 412)], WHITE, 2.4)

    # the numbers
    for v, (x, y) in {1: (661, 567), 2: (600, 502), 3: (571, 416), 4: (594, 324), 5: (658, 262), 6: (748, 235)}.items():
        A.text(x, y, str(v), TECH, 60, WHITE, shear=0.2)
    for v, (x, y) in {7: (848, 262), 8: (909, 325), 9: (930, 414)}.items():
        A.text(x, y, str(v), TECH, 60, (232, 32, 38), shear=0.2)
    A.text(749, 591, "0", TECH, 60, WHITE, shear=0.2)

    A.text(755, 366, "Giri / min x 1000", ARIAL, 13.5, (236, 238, 242))

    # the speed box
    A.poly([(870, 444), (979, 443), (965, 483), (845, 483)], (236, 240, 244))
    if not live:
        A.text(946, 463, "0", TECH, 40, (14, 14, 16), shear=0.22)
    if not live:
        A.text(945, 492, "km/h", ARIAL, 13, (230, 232, 236))

    # the gear strip
    A.poly([(756, 520), (954, 520), (934, 547), (756, 547)], (58, 112, 130))
    A.poly([(762, 528), (905, 528), (897, 546), (758, 546)], (12, 14, 16))
    A.line([(760, 517), (954, 517)], GOLD, 1.3)
    if not live:
        A.text(770, 540, "R", TECH, 17, WHITE, shear=0.2)
    if not live:
        A.text(795, 532, "N", TECH, 42, (232, 214, 32), shear=0.2, stroke=0.4, strokecol=(232, 214, 32))
    if not live:
        A.text(808, 540, "1234567", TECH, 17.5, WHITE, shear=0.2, track=1.6, anchor="lm")
        A.text(922, 531, "A", TECH, 42, (232, 214, 32), shear=0.2, stroke=0.4, strokecol=(232, 214, 32))
        A.text(819, 568, "STRADA", ARIAL, 18, (230, 196, 40))
        A.text(769, 603, "000700", TECH, 17.5, WHITE, shear=0.2, track=1.0, anchor="lm")
        A.text(857, 603, "km", ARIAL, 12.5, WHITE)

    # the needle, straight down at rest: a pale blade with a red line, the hub with its points
    if not live:
        A.poly([(741, 430), (758, 430), (752, 640), (747, 640)], (204, 226, 236))
        A.poly([(744, 392), (755, 392), (752, 366), (747, 366)], (202, 212, 220))
        A.line([(749, 358), (751, 640)], (234, 28, 38), 2.6)
        A.poly([(746, 636), (760, 636), (765, 645), (750, 645)], WHITE)
    A.circle(CX, CY, 25, (176, 186, 194), outline=(226, 232, 238), w=3)
    A.circle(CX, CY, 14, (58, 64, 72), outline=(26, 28, 32), w=2.5)

    # the gauges: traced outlines, cells inside
    YEL = (232, 186, 24)
    DARK = (46, 46, 50)
    REDC = (224, 28, 36)
    OUTL = (232, 234, 238)

    def along(p0, p1, cells, w):
        dx, dy = p1[0] - p0[0], p1[1] - p0[1]
        d = math.hypot(dx, dy)
        nx, ny = -dy / d * w / 2, dx / d * w / 2
        for c0, c1, col in cells:
            a = (p0[0] + dx * c0, p0[1] + dy * c0)
            b = (p0[0] + dx * c1, p0[1] + dy * c1)
            A.poly([(a[0] + nx, a[1] + ny), (b[0] + nx, b[1] + ny), (b[0] - nx, b[1] - ny), (a[0] - nx, a[1] - ny)], col)

    # fuel
    along((445, 262), (425, 326), [(0.02, 0.32, YEL), (0.35, 0.64, YEL), (0.67, 0.98, YEL)], 13)
    along((418, 335), (417, 396), [(0.02, 0.32, YEL), (0.35, 0.68, YEL), (0.71, 0.98, REDC)], 15)
    A.line([(438, 259), (451, 264), (433, 325), (426, 332), (426, 397), (408, 397), (408, 342), (417, 327), (438, 259)], OUTL, 1.4)
    A.line([(449, 266), (499, 285)], RED, 2.2)
    # water
    along((417, 431), (424, 472), [(0.02, 0.5, REDC), (0.53, 0.98, DARK)], 15)
    along((424, 472), (428, 494), [(0.05, 0.95, DARK)], 13)
    along((427, 500), (454, 561), [(0.02, 0.46, YEL), (0.5, 0.98, YEL)], 14)
    A.line([(408, 430), (425, 431), (427, 469), (428, 496), (460, 558), (447, 564), (425, 502), (414, 474), (408, 430)], OUTL, 1.4)
    A.line([(427, 498), (468, 486)], RED, 2.2)
    # oil pressure
    along((1054, 260), (1076, 332), [(0.02, 0.3, REDC), (0.33, 0.64, DARK), (0.67, 0.98, DARK)], 13)
    along((1086, 345), (1085, 393), [(0.02, 0.48, DARK), (0.52, 0.98, DARK)], 17)
    A.line([(1047, 260), (1061, 257), (1082, 326), (1096, 344), (1094, 394), (1076, 394), (1076, 347), (1065, 330), (1047, 260)], OUTL, 1.4)
    A.line([(1034, 394), (1093, 390)], RED, 2.4)
    # oil temperature
    along((1085, 430), (1079, 472), [(0.02, 0.62, REDC), (0.65, 0.98, DARK)], 15)
    along((1077, 478), (1066, 505), [(0.05, 0.95, DARK)], 13)
    along((1064, 508), (1050, 558), [(0.02, 0.46, DARK), (0.5, 0.86, DARK), (0.88, 1.0, YEL)], 15)
    A.line([(1077, 429), (1093, 429), (1091, 463), (1076, 499), (1058, 563), (1042, 553), (1066, 497), (1072, 474), (1077, 429)], OUTL, 1.4)
    A.line([(1015, 538), (1054, 558)], RED, 2.4)

    for x, y, t in [(470, 276, "100"), (449, 329, "50"), (437, 392, "0"), (444, 438, "130"), (476, 547, "50"), (1032, 276, "10"), (1052, 331, "5"), (1057, 436, "170"), (1046, 490, "130")]:
        A.text(x, y, t, TECH, 17, WHITE, shear=0.2)
    for x, y, t in [(476, 248, "Benzina"), (483, 577, "Temp."), (483, 592, "Acqua"), (1018, 242, "Press."), (1018, 256, "Olio"), (1018, 572, "Temp."), (1017, 587, "Olio"), (1109, 361, "bar")]:
        A.text(x, y, t, ARIAL, 14, (232, 234, 238))
    A.text(394, 362, "%", ARIAL_B, 12, (232, 234, 238))
    A.text(396, 487, "°C", ARIAL_B, 12, (232, 234, 238))
    A.text(1104, 484, "°C", ARIAL_B, 12, (232, 234, 238))
    A.icon((376, 382, 402, 410), floor=46, gain=1.5)
    A.icon((383, 508, 417, 538), floor=46, gain=1.5)
    A.icon((1088, 394, 1136, 416), floor=60, gain=1.5)
    A.icon((1082, 512, 1126, 540), floor=46, gain=1.4)

    # the left screen
    for y, x0 in ((485, 129), (520, 110), (583, 118), (641, 138)):
        A.line([(x0, y), (300, y)], (190, 120, 40), 1.1)
    A.text(159, 495, "FM", ARIAL, 13, (226, 228, 232))
    if not live:
        A.text(225, 541, "00:19", TECH, 40, WHITE, shear=0.2, track=2.2)
        A.text(230, 570, "00.00.0000", TECH, 21, WHITE, shear=0.2, track=1.2)
    A.text(214, 622, "23.0", ARIAL, 21, (232, 234, 238))
    A.text(266, 622, "°C", ARIAL, 15, (232, 234, 238))

    # the right screen
    A.line([(1204, 480), (1378, 480)], (190, 120, 40), 1.1)
    A.icon((1256, 442, 1294, 468), floor=70, gain=1.6)

    im = A.finish(2, blur=1.5, strength=0.5)
    im.save(os.path.join(outdir, "lp700_art.png"))
    compare(A, im, os.path.join(outdir, "lp700_compare.jpg"))


if __name__ == "__main__":
    outdir = sys.argv[1]
    os.makedirs(outdir, exist_ok=True)
    which = sys.argv[2] if len(sys.argv) > 2 else "all"
    if which in ("revuelto", "all"):
        revuelto(outdir)
    if which in ("sv", "all"):
        sv(outdir)
    if which in ("lp700", "all"):
        lp700(outdir, "--live" in sys.argv)
    print("ok")
