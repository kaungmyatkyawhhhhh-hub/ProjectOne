"""The LFA's and the Maybachs' clusters as live Specs for cluster_live.py (owner's photos, 2026-11-06:
imports/refs/lfa_cluster_owner.png, maybach_gls_s680_cluster_owner.png). Coordinates are photo pixels; the
photos are small (480 and 596 px wide), so everything is drawn fresh and only placed by them. No logos."""

import math

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from cluster_art import ARIAL, ARIAL_B, ARIAL_BI, REG, ROBO_B, Art

SERIF = "C:/Windows/Fonts/timesbd.ttf"


def polar(c, r, deg):
    a = math.radians(deg)
    return (c[0] + r * math.sin(a), c[1] - r * math.cos(a))


def field(A, c):
    """radius and angle (degrees clockwise from up) of every pixel of the Art, in photo pixels"""
    S = A.S
    h, w = A.H * S, A.W * S
    yy, xx = np.mgrid[0:h, 0:w]
    x = (xx + 0.5) / S + A.ox - c[0]
    y = (yy + 0.5) / S + A.oy - c[1]
    r = np.hypot(x, y)
    th = (np.degrees(np.arctan2(x, -y))) % 360
    return r, th


def blend(A, rgb, alpha):
    """rgb (h, w, 3 floats) over the picture with alpha (h, w, 0-1)"""
    base = np.asarray(A.im).astype(float)
    a = alpha[..., None]
    out = base * (1 - a) + rgb * a
    A.im.paste(Image.fromarray(np.clip(out, 0, 255).astype("uint8")))


def band_mask(r, r0, r1, soft):
    return np.clip((r - r0) / soft + 0.5, 0, 1) * np.clip((r1 - r) / soft + 0.5, 0, 1)


def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def angular(th, keys):
    """a value round the circle from (angle, value) keys, smooth between them"""
    ks = sorted(keys)
    xs = np.array([k[0] for k in ks] + [ks[0][0] + 360])
    ys = np.array([k[1] for k in ks] + [ks[0][1]])
    t = np.where(th < ks[0][0], th + 360, th)
    return np.interp(t, xs, ys)


def tick(A, c, r0, r1, deg, w0, w1, col):
    """a tapered mark on a radius, w half widths at r0 and r1"""
    a, b = polar(c, r0, deg), polar(c, r1, deg)
    dx, dy = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    A.poly([(a[0] - dx * w0, a[1] - dy * w0), (a[0] + dx * w0, a[1] + dy * w0), (b[0] + dx * w1, b[1] + dy * w1), (b[0] - dx * w1, b[1] - dy * w1)], col)


def arc_pts(c, r, a0, a1, n=40):
    return [polar(c, r, a0 + (a1 - a0) * i / n) for i in range(n + 1)]


def lfa_thermo(A, x, y, col):
    A.round_rect(x - 1.1, y - 11, x + 1.1, y + 3, 1, col)
    for i in range(4):
        A.line([(x + 1.5, y - 9.5 + i * 3), (x + 5, y - 9.5 + i * 3)], col, 0.8)
    for dy in (3.5, 6.5):
        pts = [(x - 10 + i * 2, y + dy + (1.0 if i % 2 else -0.4)) for i in range(11)]
        A.line(pts, col, 0.9)


def lfa_fuel(A, x, y, col):
    A.round_rect(x - 5, y - 6.5, x + 2.5, y + 6.5, 1, col)
    A.rect(x - 3.6, y - 5, x + 1, y - 1, (4, 5, 9))
    A.line([(x + 2.5, y + 2), (x + 5, y + 3.5), (x + 5.4, y - 3), (x + 3, y - 6)], col, 0.9)
    A.poly([(x - 8, y), (x - 11.5, y - 2.8), (x - 11.5, y + 2.8)], col)


def lfa_oil(A, x, y, col):
    A.poly([(x - 8, y + 2), (x + 5, y + 2), (x + 11, y - 4), (x + 12, y - 3), (x + 6, y + 5), (x - 8, y + 5)], col)
    A.poly([(x - 7.5, y - 2), (x + 1, y - 2), (x + 2, y + 2), (x - 7.5, y + 2)], col)
    A.line([(x - 8, y - 2), (x - 13, y - 5), (x - 15, y - 2), (x - 11, y - 1)], col, 1.0)
    A.circle(x + 13, y + 1.5, 1.0, col)
    A.rect(x - 4.5, y - 5, x - 1.5, y - 2, col)


def lfa(Spec, needle_sprite, add_needle):
    """the LFA's dial. Rev needle, speed, gear, oil pressure bar, trip lines and clock live."""
    box = (14, 26, 466, 322)
    REF = "lfa_cluster_owner.png"
    A = Art(REF, box, S=6, bg=(1, 1, 3))
    sp = Spec("lfa", box[2] - box[0], box[3] - box[1], 3.0, 3.4, box[0], box[1])
    sp.redline, sp.idle = 9.0, 0.9
    C = (240.5, 188.0)
    WHT = (232, 236, 242)
    BLU = (178, 198, 224)
    DIM = (120, 138, 164)
    FILL = (176, 204, 240)

    def rev(v):
        return 180 + 30 * v

    r, th = field(A, C)
    # the face: black in the middle, deep blue out to the ticks
    t = smooth(60, 104, r)
    face = np.stack([6 + 54 * t, 8 + 76 * t, 14 + 112 * t], axis=-1)
    blend(A, face, band_mask(r, -10, 117, 0.3))
    # the black track with the fine marks
    blend(A, np.full(face.shape, (5.0, 7.0, 11.0)), band_mask(r, 117, 127, 0.3))
    # the inner steel ring
    s = angular(th, [(0, 74), (60, 86), (110, 150), (140, 176), (180, 128), (225, 96), (270, 84), (320, 72)])
    s = s + 34 * band_mask(r, 129, 131, 1.0)
    blend(A, np.stack([s, s, s * 1.02], axis=-1), band_mask(r, 127, 135, 0.4))
    blend(A, np.full(face.shape, (8.0, 8.0, 10.0)), band_mask(r, 135, 138, 0.4))
    # the wide bezel: bright on the left, dark up top, a long highlight low on the right
    s = angular(th, [(0, 58), (45, 54), (90, 66), (112, 92), (135, 118), (165, 116), (200, 104), (232, 138), (258, 236), (280, 244), (298, 196), (312, 58), (340, 44)])
    glint = angular(th, [(0, 0), (100, 0), (125, 150), (150, 110), (175, 10), (360, 0)]) * band_mask(r, 140, 144, 2.0)
    s2 = (s + glint) * (0.82 + 0.28 * smooth(139, 154, r))
    blend(A, np.stack([s2, s2, s2 * 1.03], axis=-1), band_mask(r, 138, 155, 0.5))

    # marks on the bezel at every number, the last one red
    for v in range(0, 11):
        col = (214, 40, 44) if v == 10 else (240, 240, 236)
        tick(A, C, 141, 155, rev(v), 1.5, 2.1, col)
    # the rev scale: dots, and the red zone over them from 9
    z = band_mask(r, 119, 127, 0.5)
    a0, a1 = rev(8.98), rev(10.02)
    tt = np.where(th < 180, th + 360, th)
    zone = np.clip((tt - a0) / 0.6, 0, 1) * np.clip((a1 - tt) / 0.6, 0, 1) * z
    blend(A, np.full(face.shape, (186.0, 26.0, 26.0)), zone)
    for i in range(0, 51):
        v = i / 5
        big = i % 5 == 0
        p = polar(C, 120.5, rev(v))
        A.circle(p[0], p[1], 1.25 if big else 0.75, (206, 220, 236) if big else (112, 132, 156))
    for v in range(0, 11):
        col = WHT
        p = polar(C, 102.5, rev(v))
        A.text(p[0], p[1], str(v), ROBO_B, 16.5, col, stroke=0.15, strokecol=col)

    # the middle: unit line, dim gear marks, trip
    A.line([(200, 165), (283, 165)], (208, 214, 222), 0.9)
    A.text(241.5, 158.5, "km/h" if False else "", ROBO_B, 9, WHT)
    A.round_rect(211, 182, 221, 192, 1.0, None, outline=(38, 42, 48), w=0.7)
    A.text(216, 187, "S", ROBO_B, 7, (44, 48, 56))
    A.text(266, 187, "N", ROBO_B, 13, (46, 52, 60))
    A.text(199, 247, "TRIP A", ROBO_B, 11, WHT, stroke=0.1, strokecol=WHT)
    A.text(241, 285, "0", ROBO_B, 16.5, WHT) if False else None
    A.text(267, 281.5, "×1000", REG, 8.2, BLU)
    A.text(267, 290, "r/min", REG, 7.6, BLU)

    # left: water temperature, outside temperature, fuel
    W_ = [(101, 66), (84, 66), (62, 90), (46, 112), (34, 127)]
    A.line([(84, 66)] + arc_pts((236, 188), 207, 303, 283, 18)[0:] + [(30, 130)], (58, 66, 80), 0.9)
    A.poly([(33.5, 128), (43, 128), (36, 160), (26, 160)], FILL)
    A.line([(33.5, 128), (26, 160), (36, 160)], (222, 232, 244), 0.7)
    A.text(102, 66.5, "130℃".replace("℃", ""), ROBO_B, 11, BLU, anchor="mm")
    A.text(118, 66.5, "℃".replace("℃", "°C"), REG, 9, BLU)
    A.line([(82, 66.5), (88, 66.5)], BLU, 0.8)
    A.text(65, 102.5, "100", ROBO_B, 7.8, DIM)
    A.line([(54, 102.5), (58, 102.5)], DIM, 0.7)
    A.text(47.5, 144.5, "70", ROBO_B, 8.2, DIM)
    A.line([(40, 144.5), (43.5, 144.5)], DIM, 0.7)
    A.text(47, 158, "40", ROBO_B, 10, BLU)
    lfa_thermo(A, 75, 125, BLU)
    A.text(44, 185, "22", ROBO_B, 13, BLU)
    A.text(69, 185.5, "°C", REG, 10, BLU)
    A.line([(34, 216)] + arc_pts((236, 188), 207, 262, 233, 22) + [(78, 300)], (58, 66, 80), 0.9)
    A.poly([(62, 283), (71, 278), (86, 298), (75, 301)], FILL)
    A.line([(46, 212), (51, 212)], DIM, 0.7) if False else None
    A.text(50, 212, "1/1", ROBO_B, 9.5, BLU)
    lfa_fuel(A, 80, 245, BLU)
    A.text(97, 299, "E", ROBO_B, 10.5, BLU)

    # right: oil temperature, clock (live), oil pressure
    A.line([(397, 66)] + arc_pts((245, 188), 207, 57, 77, 18) + [(450, 130)], (58, 66, 80), 0.9)
    A.poly([(437, 128), (447, 128), (454, 160), (444, 160)], FILL)
    A.line([(447, 128), (454, 160), (444, 160)], (222, 232, 244), 0.7)
    A.text(373, 66.5, "160", ROBO_B, 11, BLU)
    A.text(391, 66.5, "°C", REG, 9, BLU)
    A.line([(397, 66.5), (402, 66.5)], BLU, 0.8)
    A.text(413, 105, "100", ROBO_B, 7.8, DIM)
    A.line([(423, 105), (428, 105)], DIM, 0.7)
    A.text(433, 157.5, "40", ROBO_B, 10, BLU)
    lfa_oil(A, 408, 125, BLU)
    A.line([(449, 206), (459, 206)] + arc_pts((245, 188), 207, 95, 121, 24) + [(412, 299)], (58, 66, 80), 0.9)
    A.text(439, 208, "8", ROBO_B, 10, BLU)
    A.line([(437, 232), (441, 232)], DIM, 0.7)
    A.text(421, 256, "4", ROBO_B, 9.5, DIM)
    A.line([(426, 256), (430, 256)], DIM, 0.7)
    A.line([(412, 278), (416, 278)], DIM, 0.7)
    A.text(389, 298, "0", ROBO_B, 10.5, BLU)
    A.line([(394, 298), (399, 298)], DIM, 0.7)
    lfa_oil(A, 406, 242, BLU)
    A.text(366, 305, "×100kPa", ROBO_B, 8.6, BLU)

    A.final = A.finish(A.S, blur=1.2, strength=0.25)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # the oil pressure bar rises with the revs; it fills left to right, as it climbs that way
    O = Art(REF, box, S=6, bg=(0, 0, 0))
    O.poly([(400, 300), (410, 300), (433, 266), (424, 263)], FILL)
    O.final = O.finish(O.S, blur=1, strength=0)
    im, left, top_ = sp.box(O, (398, 260, 436, 302), black=True)
    sp.fills.append({"im": im, "left": left, "top": top_, "pts": [(0, 0.12), (1, 0.34), (5, 0.8), (9, 1.0)]})
    # the water bar creeps up a little when worked hard
    for v, k in ((6.5, 0), (8.0, 1)):
        W = Art(REF, box, S=6, bg=(0, 0, 0))
        y0, y1 = 121 - 6 * k, 127 - 6 * k
        W.poly([(35 + 1.4 * k + 1.4, y0), (45 + 1.4 * k, y0), (43.6, y1), (33.8, y1)], FILL)
        W.final = W.finish(W.S, blur=1, strength=0)
        im, left, top_ = sp.box(W, (28, 108, 50, 128), black=True)
        sp.blocks.append({"im": im, "left": left, "top": top_, "v": v})

    # the needle, over the marks, under the digits
    RED = (232, 40, 26)
    im = needle_sprite(sp, 124, 2, [(16, 70, 0.5, 1.5, RED), (70, 106, 1.5, 2.4, RED), (106, 123, 2.4, 0.6, (246, 120, 70))])
    add_needle(sp, im, C[0], C[1], "rpm", [(0, rev(0)), (10, rev(10))])

    # the gear: big digit in the middle; in neutral the digit goes and the small N lights
    sprites = {}
    f = {"path": ARIAL_B, "size": 34, "chars": "", "stroke": 0.2, "shear": 0, "track": 0}
    from cluster_live import glyph

    for ch in "R1234567":
        g, ox, oy, adv = glyph(ch, f, sp.A)
        c = Image.new("RGBA", g.size, (240, 244, 248, 0))
        c.putalpha(g.getchannel("A"))
        sprites[ch] = {"im": c}
    sprites["N"] = {"im": Image.new("RGBA", (4, 4), (0, 0, 0, 0))}
    sp.gear = {"x": 241 - sp.ox, "y": 186 - sp.oy, "sprites": sprites}
    L = Art(REF, box, S=6, bg=(0, 0, 0))
    L.text(266, 187, "N", ROBO_B, 13, (240, 244, 248))
    L.final = L.finish(L.S, blur=1, strength=0)
    sp.add_show(sp.box(L, (258, 178, 275, 196), black=True), "gearN")

    # (values and their places)
    sp.font("speed", ARIAL_B, 38, "0123456789", stroke=0.25, shear=0, track=0.2)
    sp.readout("speed", 241, 135, "m", 3, "speed", (244, 246, 250))
    sp.font("unit", ROBO_B, 9.5, "kmhpi/", shear=0)
    sp.readout("unit", 241.5, 158.5, "m", 4, "unit", (232, 236, 242))
    sp.font("trip", ROBO_B, 12.5, "0123456789", shear=0, track=0.3)
    sp.readout("trip", 278, 248, "r", 4, "range", (232, 236, 242))
    sp.readout("trip", 272, 263, "r", 6, "odoTrim", (232, 236, 242))
    sp.font("tripu", ROBO_B, 9, "kmi", shear=0)
    sp.readout("tripu", 283, 248.5, "l", 2, "distUnit", (232, 236, 242))
    sp.readout("tripu", 277, 263.5, "l", 2, "distUnit", (232, 236, 242))
    sp.font("clock", ROBO_B, 15.5, "0123456789:", shear=0, track=0.6)
    sp.readout("clock", 435, 182.5, "m", 5, "clock", BLU)
    sp.font("zero", ROBO_B, 16.5, "0", shear=0)
    return sp


def my_tab(A, c, r0, r1, deg):
    """the small white wedge at a number, wide at the rim"""
    tick(A, c, r0, r1, deg, 0.5, 2.0, (238, 236, 240))


def my_dial(A, c, R):
    r, th = field(A, c)
    tt = th
    shape = (A.H * A.S, A.W * A.S, 3)
    # deep blue, darkest under the mark's place at the top, brightest low and in a wide ring
    k = smooth(0.92, 0.5, r / R) * (0.35 + 0.65 * smooth(14, 40, r))
    top = angular(th, [(0, 0.62), (40, 0.86), (90, 1.0), (180, 1.0), (270, 1.0), (320, 0.86)])
    dark = np.exp(-(((r * np.cos(np.radians(th)) - 32) / 20) ** 2 + (r * np.sin(np.radians(th)) / 28) ** 2))
    k2 = k * top * (1 - 0.82 * dark)
    col = np.stack([6 + 8 * k2, 10 + 44 * k2, 26 + 196 * k2], axis=-1)
    blend(A, col, band_mask(r, -10, R, 0.4))
    # fine radial lines
    lines = 76
    ph = (th * lines / 360) % 1
    w = np.abs(ph - 0.5) * 2
    li = np.clip(1 - w / (0.26 * (28 / np.maximum(r, 12))), 0, 1)
    fade = smooth(10, 26, r) * smooth(0.92, 0.74, r / R)
    blend(A, np.full(shape, (176.0, 186.0, 250.0)), li * fade * (0.42 + 0.44 * top * (1 - 0.5 * dark)))
    # the silver ring
    lit = angular(th, [(0, 240), (90, 222), (135, 206), (180, 232), (225, 208), (270, 236), (320, 228)])
    blend(A, np.stack([lit, lit * 0.93, lit * 0.97], axis=-1), band_mask(r, R, R + 2.5, 0.5))


def my_note(A, x, y, s, col):
    A.line([(x - 5 * s, y + 8 * s), (x - 5 * s, y - 9 * s), (x + 8 * s, y - 13 * s), (x + 8 * s, y + 4 * s)], col, 2.0 * s)
    A.circle(x - 9 * s, y + 8 * s, 4.2 * s, None, outline=col, w=1.8 * s)
    A.circle(x + 4 * s, y + 4 * s, 4.2 * s, None, outline=col, w=1.8 * s)


def maybach(Spec, needle_sprite, add_needle, glyph):
    """the Maybachs' wide screen. Both needles, digital speed, gear letters, range, clock live. No logo."""
    box = (2, 34, 594, 270)
    REF = "maybach_gls_s680_cluster_owner.png"
    A = Art(REF, box, S=5, bg=(1, 1, 5))
    sp = Spec("maybach", box[2] - box[0], box[3] - box[1], 3.0, 3.2, box[0], box[1])
    sp.redline, sp.idle = 6.0, 0.7
    L = (105.7, 152.0)
    Rc = (491.0, 151.5)
    R = 95.0
    WHT = (240, 240, 246)
    SP = [(0, 231.7), (20, 259.4), (40, 287.4), (60, 315.0), (80, 344.4), (100, 375.0), (140, 404.5), (180, 432.8), (220, 460.5), (260, 488.7)]
    MPH = [(0, 231.7), (20, 259.4), (40, 287.4), (60, 315.0), (80, 344.4), (100, 375.0), (120, 404.5), (140, 432.8), (160, 460.5), (180, 488.7)]
    RP = [(0, 231.0), (1, 272.3), (2, 314.0), (3, 360.0), (4, 405.0), (5, 448.0), (6, 490.0)]

    # the blue horizon behind everything, between the dials
    S = A.S
    h, w = A.H * S, A.W * S
    yy, xx = np.mgrid[0:h, 0:w]
    y = (yy + 0.5) / S + A.oy
    x = (xx + 0.5) / S + A.ox
    top = 141 + 3.2 * np.sin((x - 298) / 40) * np.exp(-(((x - 298) / 170) ** 2))
    above = np.exp(-np.maximum(top - y, 0) / 9) * 0.30
    below = np.exp(-(np.maximum(y - top, 0) / 42) ** 2)
    k = np.where(y < top, above, below) * np.exp(-(((x - 298) / 165) ** 4))
    k = k * (0.86 + 0.14 * np.sin(x / 5.0 + y / 2.0) * np.sin(y / 1.7))
    lift = np.exp(-np.maximum(y - top, 0) / 11) * (y >= top) * np.exp(-(((x - 298) / 140) ** 4))
    col = np.stack([2 + 26 * k + 120 * lift, 3 + 56 * k + 110 * lift, 8 + 226 * k + 30 * lift], axis=-1)
    blend(A, col, np.ones((h, w)))
    # a few stars over the band
    for p in ((246, 116), (262, 129), (271, 122), (322, 128), (348, 121), (353, 134), (281, 118)):
        A.circle(p[0], p[1], 0.5, (190, 210, 255))

    my_dial(A, L, R)
    my_dial(A, Rc, R)
    # the numbers and wedges, speedometer: the numbers live, they follow km/h or mph
    TABR = (78, 88)
    for v, a in SP:
        my_tab(A, L, TABR[0], TABR[1], a)
    for v, a in RP:
        my_tab(A, Rc, TABR[0], TABR[1], a)
    RN = {0: (433, 196), 1: (418, 148.5), 2: (443, 103), 3: (490, 86), 4: (539, 103), 5: (562, 148.5), 6: (546, 196)}
    for v, p in RN.items():
        col = (232, 118, 152) if v >= 5 else WHT
        A.text(p[0], p[1], str(v), SERIF, 17, col, scale_x=0.8)
    # the hubs: chrome over the upper half
    for c in (L, Rc):
        A.circle(c[0], c[1], 11.5, (232, 228, 236))
        A.circle(c[0], c[1], 9.0, (205, 200, 216))
        A.poly([(c[0] - 9, c[1] + 0.6), (c[0] - 4, c[1] - 0.5), (c[0] + 4, c[1] + 0.8), (c[0] + 9, c[1] - 0.5), (c[0] + 8, c[1] + 4.5), (c[0] + 4, c[1] + 8), (c[0], c[1] + 9), (c[0] - 4, c[1] + 8), (c[0] - 8, c[1] + 4.5)], (20, 40, 150))

    # rev dial's small print, fuel and coolant under the dials
    A.text(490.5, 176, "x1000/min", ARIAL_BI, 7.2, (200, 208, 244))
    A.text(69, 224, "0", ARIAL_BI, 7, WHT)
    A.text(143, 224, "1", ARIAL_BI, 7, WHT)
    A.text(105, 233, "1/2", ARIAL_BI, 6.2, WHT)
    A.round_rect(86, 217, 95, 227, 1.0, WHT)
    A.rect(88, 219, 93, 222, (12, 18, 60))
    A.poly([(96, 220), (100, 222), (96, 224)], WHT)
    for i, (a0, a1, c0) in enumerate(((201, 190, (150, 190, 236)), (189, 179, (240, 240, 246)), (178, 168, (106, 116, 170)), (167, 156, (106, 116, 170)))):
        pts = arc_pts(L, 88, a0, a1, 8)
        A.line(pts, c0, 1.9)
    A.text(453, 224, "50", ARIAL_BI, 7, WHT)
    A.text(490, 233, "90", ARIAL_BI, 6.6, WHT)
    A.text(524, 224, "130", ARIAL_BI, 7, WHT)
    A.line([(491, 213), (491, 222)], (46, 110, 236), 2.2)
    A.line([(484, 224), (498, 224)], (46, 110, 236), 1.6)
    for i, (a0, a1, c0) in enumerate(((201, 190, (106, 116, 170)), (189, 179, (106, 116, 170)), (178, 168, (106, 116, 170)), (167, 156, (232, 90, 130)))):
        A.line(arc_pts(Rc, 88, a0, a1, 8), c0, 1.9)

    # the middle: lines, assist icons, the media tile
    A.line([(207, 99), (282, 99)], (222, 226, 240), 1.0)
    A.line([(313, 99), (388, 99)], (222, 226, 240), 1.0)
    # car + wheel
    A.round_rect(240, 80, 254, 87, 2, None, outline=WHT, w=1.2)
    A.line([(243, 80), (246, 76), (252, 76), (255, 80)], WHT, 1.1)
    A.circle(258, 89, 5.2, None, outline=WHT, w=1.2)
    A.line([(258, 84), (258, 94)], WHT, 0.8)
    A.line([(253, 89), (263, 89)], WHT, 0.8)
    # steering assist, lanes
    A.circle(345.5, 86, 5.5, None, outline=WHT, w=1.2)
    A.circle(345.5, 86, 1.4, WHT)
    A.line([(335, 92), (338, 80), (345, 76), (353, 80), (356, 92)], WHT, 1.4)
    for sx in (-1, 1):
        A.line([(382 + sx * 11, 82), (382 + sx * 4, 92)], WHT, 2.0)
    A.rect(381, 81, 382.6, 85, WHT)
    A.rect(381, 88, 382.6, 92, WHT)
    A.text(298, 126, "Media", ROBO_B, 8.2, (232, 236, 246))
    gr = Image.new("RGB", (68 * S, 66 * S))
    gg = np.zeros((66 * S, 68 * S, 3), float)
    yy2, xx2 = np.mgrid[0:66 * S, 0:68 * S]
    t = yy2 / (66 * S)
    gg[..., 0] = 10 + 30 * (1 - t)
    gg[..., 1] = 40 + 60 * (1 - t) + 10 * np.sin(xx2 / 17.0) * np.sin(yy2 / 11.0)
    gg[..., 2] = 150 + 90 * (1 - t)
    gr = Image.fromarray(np.clip(gg, 0, 255).astype("uint8"))
    A.im.paste(gr, (int((264.5 - A.ox) * S), int((137 - A.oy) * S)))
    A.round_rect(264.5, 137, 331, 201, 1.2, None, outline=(130, 170, 244), w=0.9)
    my_note(A, 298, 170, 1.15, (196, 244, 255))
    A.poly([(254, 165), (254, 177), (244.5, 171)], (196, 208, 240))
    A.rect(243.3, 165, 244.5, 177, (196, 208, 240))
    A.poly([(342, 165), (342, 177), (351.5, 171)], (196, 208, 240))
    A.rect(351.5, 165, 352.7, 177, (196, 208, 240))
    # the bottom row
    A.text(414, 247, "24.5 °C", ROBO_B, 9, (236, 236, 242))
    A.round_rect(533, 241, 556, 253, 1.5, (24, 112, 200), outline=(90, 170, 240), w=0.5)
    A.text(544.5, 247, "C", ROBO_B, 8.5, (214, 234, 250))
    for ch, yy3 in (("R", 228.5), ("N", 239.5), ("D", 250)):
        A.text(562, yy3, ch, ROBO_B, 8.2, (86, 90, 110))

    A.final = A.finish(A.S, blur=1.5, strength=0.3)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    def small(draw, bx, when):
        B = Art(REF, box, S=5, bg=(0, 0, 0))
        draw(B)
        B.final = B.finish(B.S, blur=1, strength=0)
        sp.add_show(sp.box(B, bx, black=True), when)

    # the speedometer's numbers, one set per unit
    KP = {0: (50, 196.5), 20: (38, 167.5), 40: (38.7, 133), 60: (56, 106), 80: (87, 88), 100: (123, 88), 140: (152, 105.5), 180: (170, 134), 220: (172, 167.5), 260: (156, 196.5)}
    for (v, p), (m, _) in zip(KP.items(), MPH):
        small(lambda B, s=str(v), q=p: B.text(q[0], q[1], s, SERIF, 14.5, WHT, scale_x=0.8), (p[0] - 18, p[1] - 10, p[0] + 18, p[1] + 10), "kmh")
        small(lambda B, s=str(m), q=p: B.text(q[0], q[1], s, SERIF, 14.5, WHT, scale_x=0.8), (p[0] - 18, p[1] - 10, p[0] + 18, p[1] + 10), "mph")
    # the parking brake's blue P; the lit gear letter
    small(lambda B: (B.round_rect(343, 241, 355, 252, 1, (30, 120, 216)), B.text(349, 246.5, "P", ROBO_B, 8.5, (214, 236, 252))), (341, 239, 357, 254), "parked")
    small(lambda B: B.text(562, 228.5, "R", ROBO_B, 8.2, (250, 250, 255)), (556, 222, 568, 235), "gearR")
    small(lambda B: B.text(562, 239.5, "N", ROBO_B, 8.2, (250, 250, 255)), (556, 233, 568, 246), "gearN")
    small(lambda B: B.text(562, 250, "D", ROBO_B, 8.2, (250, 250, 255)), (556, 244, 568, 257), "gearD")

    # the needles: thin, white, a chrome hub
    NC = (244, 242, 248)
    parts = [(-17, -11, 1.8, 1.8, NC), (11, 70, 1.0, 1.4, NC), (70, 84, 1.4, 2.4, NC), (84, 90, 2.4, 0.4, NC)]
    im = needle_sprite(sp, 90, 18, parts)
    sp.needles.append({"im": im, "x": L[0] - sp.ox, "y": L[1] - sp.oy, "bind": "dial", "pts": SP, "alt": MPH})
    im = needle_sprite(sp, 90, 18, parts)
    add_needle(sp, im, Rc[0], Rc[1], "rpm", RP)

    # the big gear letter: P parked or in neutral, R, D
    sprites = {}
    f = {"path": ROBO_B, "size": 15, "chars": "", "stroke": 0.1, "shear": 0, "track": 0}

    def letter(ch):
        g, ox, oy, adv = glyph(ch, f, sp.A)
        c = Image.new("RGBA", g.size, (246, 246, 250, 0))
        c.putalpha(g.getchannel("A"))
        return {"im": c}

    sprites["N"] = letter("P")
    sprites["R"] = letter("R")
    for ch in "1234567":
        sprites[ch] = letter("D")
    sp.gear = {"x": 574 - sp.ox, "y": 240 - sp.oy, "sprites": sprites}

    # values
    sp.font("speed", ARIAL_BI, 25, "0123456789", stroke=0.1, shear=0, track=0.2)
    sp.readout("speed", 298, 82.5, "m", 3, "speed", (246, 246, 250))
    sp.font("unit", ARIAL_BI, 6.2, "kmhpi/", shear=0)
    sp.readout("unit", 298, 95, "m", 4, "unit", (214, 222, 244))
    sp.readout("unit", 105.5, 175, "m", 4, "unit", (200, 208, 244))
    sp.font("range", ARIAL_BI, 8.8, "0123456789", shear=0, track=0.2)
    sp.readout("range", 124, 224, "r", 3, "range", WHT)
    sp.font("rangeu", ARIAL_BI, 5.8, "kmi", shear=0)
    sp.readout("rangeu", 126, 225, "l", 2, "distUnit", WHT)
    sp.font("clock", ROBO_B, 10, "0123456789:", shear=0, track=0.1)
    sp.readout("clock", 173, 247, "m", 5, "clock", (240, 240, 246))
    return sp
