"""The clusters of the 2026-11-08 imports as live Specs for cluster_live.py, drawn fresh from the owner's photos
(imports/refs/*_cluster_owner.*). Coordinates are photo pixels; the design only follows the photo, nothing is cut from it.
No makers' marks: the dial's name goes, and a blank stays."""

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from cluster_art import ARIAL, ARIAL_B, ARIAL_BI, REG, ROBO_B, TECH, Art, font
from cluster_lfa_maybach import band_mask, blend, field, polar, smooth

HERE = os.path.dirname(os.path.abspath(__file__))


def window(name, box, polys, circles=(), cuts=(), S=2):
    """window_<name>.png: white where the panel shows"""
    W, H = (box[2] - box[0]) * S, (box[3] - box[1]) * S
    m = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(m)
    for poly in polys:
        d.polygon([((x - box[0]) * S, (y - box[1]) * S) for x, y in poly], fill=255)
    for c, r in circles:
        x, y = (c[0] - box[0]) * S, (c[1] - box[1]) * S
        d.ellipse([x - r * S, y - r * S, x + r * S, y + r * S], fill=255)
    for poly in cuts:
        d.polygon([((x - box[0]) * S, (y - box[1]) * S) for x, y in poly], fill=0)
    m.filter(ImageFilter.GaussianBlur(0.6)).save(os.path.join(HERE, "window_%s.png" % name))


def bar_fuel(sp, art_box, x0, y0, x1, y1, col, A):
    """a bar that follows the fuel: filled left to right by the game"""
    A.rect(x0, y0, x1, y1, col)


def add_fuel(sp, REF, box, x0, y0, x1, y1, col, S=4):
    F = Art(REF, box, S=S, bg=(0, 0, 0))
    F.rect(x0, y0, x1, y1, col)
    F.final = F.finish(F.S, blur=1, strength=0)
    im, left, top = sp.box(F, (x0, y0, x1, y1), black=False)
    im = im.convert("RGBA")
    sp.fuels.append({"im": im, "left": left, "top": top})


def mc12c(Spec, needle_sprite, add_needle, glyph):
    """the 12C: a big round rev counter with two wings, each a screen. No name on the dial."""
    # the panel lies in the model's own hood, under its ring and frame (frame_probe + window_mask): 1 px = 0.33 mm, so
    # the model's opening sets the box, and the photo's frame and silver ring stay the model's
    box = (-26, 131, 1002, 494)
    REF = "mclaren_12c_cluster_owner.webp"
    A = Art(REF, box, S=4, bg=(4, 4, 5))
    sp = Spec("mc12c", box[2] - box[0], box[3] - box[1], 2.0, 2.0, box[0], box[1])
    sp.redline, sp.idle = 8.5, 1.0
    C = (490.0, 347.0)  # the needle's hub, the numbers' middle
    R = (488.0, 335.0)  # the silver ring's middle
    TAN = (218, 200, 166)
    ORG = (246, 134, 30)
    OR2 = (238, 150, 60)
    WHT = (232, 232, 234)
    RED = (232, 44, 28)

    def rev(v):
        return (v - 6) * 30

    # the wings: black glass with a soft light behind the warning lamps
    r, th = field(A, R)
    h, w = r.shape
    yy, xx = np.mgrid[0:h, 0:w]
    px = (xx + 0.5) / A.S + A.ox
    py = (yy + 0.5) / A.S + A.oy
    # the dial: black face, a bezel, the ring
    blend(A, np.full((h, w, 3), (7.0, 7.0, 8.0)), band_mask(r, -10, 186, 0.5))
    r2, th2 = field(A, C)
    # the scale's track, dark up top, lighter low on the right
    tone = np.where(th2 < 180, 40 + 34 * smooth(70, 150, th2), 34 - 10 * smooth(180, 260, th2))
    blend(A, np.stack([tone, tone, tone * 1.02], axis=-1), band_mask(r2, 132, 153, 0.6) * smooth(0.0, 1.0, (py - 180) / 60))
    # the red block on it before 9, and the glow by the 1
    zone = band_mask(r2, 132, 153, 0.6) * np.clip((th2 - rev(8.62)) / 0.6, 0, 1) * np.clip((rev(9.02) - th2) / 0.6, 0, 1)
    blend(A, np.full((h, w, 3), (206.0, 26.0, 14.0)), zone)
    tt = (th2 - 180) % 360
    low = band_mask(r2, 132, 153, 0.6) * np.clip((tt - 10) / 8, 0, 1) * np.clip((40 - tt) / 8, 0, 1)
    blend(A, np.full((h, w, 3), (120.0, 14.0, 12.0)), low * 0.8)

    # long dim marks on the half thousands, tan wedges on the thousands
    for v in (1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5):
        col = RED if v == 8.5 else (86, 86, 90)
        a, b = polar(C, 116, rev(v)), polar(C, 150, rev(v))
        A.line([a, b], col, 1.6 if v == 8.5 else 1.1)
    for v in range(1, 10):
        col = RED if v == 9 else TAN
        d = rev(v)
        A.poly([polar(C, 92, d - 1.4), polar(C, 92, d + 1.4), polar(C, 104, d)], col)
    for v in range(1, 10):
        p = polar(C, 125, rev(v))
        col = (232, 62, 34) if v == 9 else TAN
        A.text(p[0], p[1], str(v), ARIAL_B, 30, col, stroke=0.3, strokecol=col)
    A.text(491, 321, "x1000 r/min", ARIAL, 6.6, (204, 200, 190))

    # the speed box
    A.rect(509, 389, 596, 431, (34, 10, 8))
    # the unit is live

    # the left wing: the screen's lines
    A.text(172, 379, "HOME", ARIAL_B, 7.6, ORG)
    A.line([(158, 385), (328, 385)], (120, 76, 30), 0.8)
    A.text(186, 392, "ODOMETER", ARIAL_B, 7.6, ORG)
    A.text(290, 392, "TEMPERATURE", ARIAL_B, 7.6, ORG)
    A.text(173, 429, "TRIP", ARIAL_B, 7.6, ORG)
    A.text(302, 426, "RANGE", ARIAL_B, 7.6, ORG)
    A.text(304, 410, "75 °F", ARIAL_B, 10, WHT)
    A.text(226, 413, "Miles", ARIAL, 8.2, WHT)
    A.text(226, 449, "Miles", ARIAL, 8.2, WHT)
    A.text(320, 447, "Miles", ARIAL, 8.2, WHT)

    # the right wing: modes and bars
    A.text(692, 408, "HANDLING", ARIAL_B, 7.6, ORG)
    A.text(692, 436, "POWERTRAIN", ARIAL_B, 7.6, ORG)
    A.line([(664, 426), (720, 426)], (70, 70, 74), 0.8)
    for y, word in ((402, "OIL"), (424, "WATER"), (448, "FUEL")):
        A.text(745 if word == "OIL" else 756 if word == "WATER" else 750, y - 3, word, ARIAL_B, 7.6, ORG)
        A.rect(738, y + 3, 826, y + 13, (6, 6, 7))
        A.line([(737, y + 3), (827, y + 3), (827, y + 13), (737, y + 13), (737, y + 3)], (168, 170, 176), 0.9)
    A.rect(738.6, 428, 744, 436, (150, 150, 186))  # water, warm
    A.final = A.finish(A.S, blur=1.2, strength=0.25)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    add_fuel(sp, REF, box, 738.6, 452, 826, 460, (150, 150, 186))

    # oil and water follow the engine a little
    O = Art(REF, box, S=4, bg=(0, 0, 0))
    O.rect(738.6, 406, 826, 414, (150, 150, 186))
    O.final = O.finish(O.S, blur=1, strength=0)
    im, left, top = sp.box(O, (738.6, 406, 826, 414), black=True)
    sp.fills.append({"im": im, "left": left, "top": top, "pts": [(0, 0.2), (2, 0.34), (5, 0.62), (8.5, 0.86)]})

    # warning lamps: lit parked, as in the photo; the beams when the lights are on
    L = Art(REF, box, S=4, bg=(0, 0, 0))
    L.text(887, 421, "(P)", ARIAL_B, 11, (246, 86, 30))
    L.text(897, 468, "BRAKE", ARIAL_B, 8.2, (246, 86, 30))
    L.poly([(108, 382), (116, 382), (120, 396), (104, 396)], (232, 62, 30))
    L.circle(112, 379, 3, (232, 62, 30))
    for x, y, rad in ((96, 365, 16), (904, 372, 18), (908, 462, 15), (900, 492, 12)):
        L.gd.ellipse([*L.q(x - rad, y - rad * 1.6), *L.q(x + rad, y + rad * 1.6)], fill=(120, 18, 10))
    L.final = L.finish(L.S, blur=9, strength=0.9)
    sp.add_show(sp.box(L, (60, 330, 136, 410), black=True), "parked")
    sp.add_show(sp.box(L, (860, 340, 950, 510), black=True), "parked")
    B = Art(REF, box, S=4, bg=(0, 0, 0))
    GRN = (60, 216, 96)
    B.line([(224, 345), (224, 359)], GRN, 1.6)
    B.d.arc([*B.q(216, 345), *B.q(232, 359)], -90, 90, fill=GRN, width=7)
    for y in (346, 350, 354, 358):
        B.line([(213, y + 1), (221, y)], GRN, 1.3)
    B.final = B.finish(B.S, blur=1, strength=0)
    sp.add_show(sp.box(B, (208, 340, 238, 364), black=True), "lights")

    # the needle
    parts = [(0, 96, 2.0, 1.3, RED), (96, 124, 1.3, 0.5, (246, 80, 40))]
    add_needle(sp, needle_sprite(sp, 126, 2, parts, hub=12.5, hub_col=(26, 26, 30), hub_line=(60, 60, 64)), C[0], C[1], "rpm", [(0, rev(0)), (10, rev(10))])

    # gear on the right edge
    sprites = {}
    f = {"path": ARIAL_B, "size": 34, "chars": "", "stroke": 0.1, "shear": 0, "track": 0}
    for ch in "RN1234567":
        g, ox, oy, adv = glyph(ch, f, sp.A)
        c = Image.new("RGBA", g.size, ORG + (0,))
        c.putalpha(g.getchannel("A"))
        sprites[ch] = {"im": c}
    sp.gear = {"x": 690 - sp.ox, "y": 322 - sp.oy, "sprites": sprites}

    sp.font("speed", TECH, 44, "0123456789", stroke=0.1, shear=0, track=0.4)
    sp.readout("speed", 596, 403, "r", 3, "speed", ORG)
    sp.font("unit", ARIAL, 8, "kmhp/", shear=0)
    sp.readout("unit", 571, 423, "m", 4, "unit", ORG)
    sp.font("odo", ARIAL_B, 13.6, "0123456789", shear=0, track=0.2)
    sp.readout("odo", 208, 412, "r", 7, "odoTrim", WHT)
    sp.readout("odo", 208, 448, "r", 7, "odoTrim", WHT)
    sp.readout("odo", 310, 447, "r", 3, "range", WHT)
    sp.font("clock", ARIAL_B, 11.6, "0123456789:", shear=0, track=0.3)
    sp.readout("clock", 285, 379, "m", 5, "clock", WHT)
    sp.font("mode", ARIAL_B, 9.4, "NORMALSPT", shear=0, track=0.3)
    sp.readout("mode", 692, 417, "m", 6, "driveMode", WHT)
    sp.readout("mode", 692, 446, "m", 6, "driveMode", WHT)
    return sp


def sls(Spec, needle_sprite, add_needle, twin=False):
    """the SLS and SL65: two deep dials, a brushed plate between them with the screen. No maker's lettering on the plate.
    twin: the SL65's hood has two bowls side by side and no room for the plate, so the same dials sit close together, and
    the screen's speed and P R N D go in small windows in the dials."""
    box = (74, 80, 595, 316) if twin else (71, 60, 677, 317)
    REF = "sls_sl65_cluster_owner.png"
    A = Art(REF, box, S=5, bg=(5, 5, 6))
    sp = Spec("sl65" if twin else "sls", box[2] - box[0], box[3] - box[1], 3.0, 3.0, box[0], box[1])
    sp.redline, sp.idle = 9.0, 0.8
    C1, C2 = (192.0, 198.0), (477.0 if twin else 556.0, 198.0)
    dx = C2[0] - 556.0
    if twin:
        window("sl65", box, [], [(C1, 113), (C2, 113)])
    NUM = (232, 224, 206)
    DIM = (150, 146, 134)
    RED = (226, 30, 34)

    def mph(m):
        return -111.6 + (m - 60) * 1.103

    def rpm(v):
        return -176 + 29.4 * v

    r1, th1 = field(A, C1)
    r2, th2 = field(A, C2)
    h, w = r1.shape
    yy, xx = np.mgrid[0:h, 0:w]
    px = (xx + 0.5) / A.S + A.ox
    py = (yy + 0.5) / A.S + A.oy

    # the brushed plate between the dials, lit from above
    plate = (px > 248) & (px < 500) & (not twin)
    noise = np.random.default_rng(3).normal(0, 1, (h, 1)).repeat(w, axis=1)
    noise = np.asarray(Image.fromarray(((noise + 3) * 40).clip(0, 255).astype("uint8")).filter(ImageFilter.GaussianBlur(1.2))).astype(float) / 40 - 3
    tone = 100 - 56 * smooth(52, 150, py) - 16 * smooth(150, 290, py) + noise * 2.4
    blend(A, np.stack([tone, tone * 0.985, tone * 0.95], axis=-1), plate * 1.0)
    top = np.clip((py - 104) / 1, 0, 1) * np.clip((110 - py) / 1, 0, 1) * plate
    blend(A, np.full((h, w, 3), (196.0, 192.0, 182.0)), top * 0.5)

    if not twin:
        # the arrows and the shift bar in the plate
        for s, x in ((-1, 284), (1, 465)):
            A.poly([(x + s * 11, 79), (x + s * 1, 69), (x + s * 1, 75), (x - s * 10, 75), (x - s * 10, 83), (x + s * 1, 83), (x + s * 1, 89)], (14, 14, 16))
        A.rect(327, 72, 421, 88, (10, 10, 12))
        for i in range(7):
            x0 = 330 + i * 12.9
            A.rect(x0, 74, x0 + 10.4, 86, (54, 52, 50))

        # the screen
        A.rect(304, 140, 446, 267, (150, 150, 150))
        A.rect(306, 142, 444, 265, (29, 31, 38))
        A.line([(308, 161), (442, 161)], (222, 224, 226), 1.2)
        A.line([(308, 239), (442, 239)], (222, 224, 226), 1.2)
        for ch, x in (("P", 342), ("R", 356), ("N", 369), ("D", 383)):
            A.text(x, 152, ch, ARIAL_B, 12, (232, 234, 236))
        A.rect(400, 145, 414, 159, (232, 234, 236))
        A.rect(401.2, 146.2, 412.8, 157.8, (29, 31, 38))
        A.text(406.6, 152, "S", ARIAL_B, 10.5, (232, 234, 236))
        A.circle(313, 246, 4.4, None, outline=(226, 228, 230), w=0.9)
        A.line([(313, 243), (313, 246), (315.5, 247)], (226, 228, 230), 0.9)

    # the dials
    for r, th, C, t2 in ((r1, th1, C1, mph), (r2, th2, C2, rpm)):
        blend(A, np.full((h, w, 3), (9.0, 9.0, 10.0)), band_mask(r, -10, 108, 0.5))
        # the deep black wall round the face
        d = 16 + 26 * smooth(96, 108, r)
        blend(A, np.stack([d, d, d * 1.03], axis=-1), band_mask(r, 96, 116, 0.5))
        # the brushed silver middle
        s = 128 + 26 * np.cos(np.radians(th * 2 - 70)) + 8 * np.cos(np.radians(th * 6))
        blend(A, np.stack([s, s * 0.975, s * 0.91], axis=-1), band_mask(r, -10, 49, 0.5))
        blend(A, np.full((h, w, 3), (54.0, 52.0, 48.0)), band_mask(r, 49, 51, 0.5))

    def tick(C, r0, r1_, deg, w_, col):
        a, b = polar(C, r0, deg), polar(C, r1_, deg)
        A.line([a, b], col, w_)

    for m in range(0, 251, 5):
        big = m % 20 == 0
        mid = m % 10 == 0
        if m == 0:
            continue
        tick(C1, 88 if big else (90 if mid else 92), 95, mph(m), 2.0 if big else (1.2 if mid else 0.8), NUM if big or mid else DIM)
    for m in range(20, 241, 20):
        p = polar(C1, 73 if m not in (240,) else 71, mph(m))
        A.text(p[0], p[1], str(m), ARIAL_B, 11.5, NUM)
    A.text(263, 205, "mph", ARIAL_B, 6.4, NUM)
    A.text(189, 232, "SPORT", ARIAL_B, 6.6, (232, 132, 36))

    # the fuel scale in the left dial
    FA = lambda f: 158 - 53 * f
    for f in (0, 0.25, 0.5, 0.75, 1):
        tick(C1, 80, 88, FA(f), 1.3, NUM)
    A.text(221, 257, "0", ARIAL_B, 9, NUM)
    A.text(243, 241, "1/2", ARIAL_B, 8, NUM)
    A.text(262, 224, "1", ARIAL_B, 9, NUM)

    # the rev scale, red from 8
    tt = th2.copy()
    zone = band_mask(r2, 86, 96, 0.5) * np.clip((((tt - rpm(8)) % 360)) / 0.6, 0, 1) * np.clip((rpm(9) - rpm(8) - ((tt - rpm(8)) % 360)) / 0.6, 0, 1)
    blend(A, np.full((h, w, 3), (206.0, 22.0, 26.0)), zone)
    for i in range(0, 37):
        v = i / 4
        big = i % 4 == 0
        mid = i % 2 == 0
        if v >= 8:
            continue
        tick(C2, 86 if big else (89 if mid else 91), 95, rpm(v), 2.0 if big else (1.2 if mid else 0.8), NUM if big or mid else DIM)
    for v in range(0, 10):
        p = polar(C2, 73, rpm(v))
        A.text(p[0], p[1], str(v), ARIAL_B, 14, NUM)
    A.text(619 + dx, 206, "x1000", ARIAL_B, 5.6, NUM)
    A.text(619 + dx, 212, "/min", ARIAL_B, 5.6, NUM)

    # the oil temperature in the right dial
    for t, deg in ((50, 156), (100, 134), (140, 112)):
        tick(C2, 80, 88, deg, 1.3, NUM)
    A.text(570 + dx, 258, "50", ARIAL_B, 8, NUM)
    A.text(598 + dx, 243, "100", ARIAL_B, 8, NUM)
    A.text(607 + dx, 226, "140", ARIAL_B, 8, NUM)
    A.line([polar(C2, 54, 140), polar(C2, 78, 140)], RED, 1.8)
    px_x = (C2[0] - 21, C2[0] - 7, C2[0] + 7, C2[0] + 21)
    if twin:
        # the small windows, low in the silver middles
        for c in (C1, C2):
            A.round_rect(c[0] - 33, 216, c[0] + 33, 240, 2.0, (22, 24, 30), outline=(70, 70, 72), w=0.8)
        for ch, x in zip("PRND", px_x):
            A.text(x, 228, ch, ARIAL_B, 11, (232, 234, 236))

    A.final = A.finish(A.S, blur=1.2, strength=0.25)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # the shift lights light up to the limit
    for i in range(0 if twin else 7):
        L = Art(REF, box, S=4, bg=(0, 0, 0))
        x0 = 330 + i * 12.9
        L.rect(x0, 74, x0 + 10.4, 86, (246, 210, 90) if i < 4 else (246, 120, 30) if i < 6 else (240, 40, 30))
        L.final = L.finish(L.S, blur=1, strength=0)
        im, left, top_ = sp.box(L, (x0, 74, x0 + 10.4, 86), black=True)
        sp.blocks.append({"im": im, "left": left, "top": top_, "v": 6.2 + i * 0.36})

    # which of P R N D
    for when, ch, x in (("gearN", "P", px_x[0] if twin else 342), ("gearR", "R", px_x[1] if twin else 356), ("gearD", "D", px_x[3] if twin else 383)):
        L = Art(REF, box, S=4, bg=(0, 0, 0))
        y0 = 221 if twin else 145
        L.rect(x - 6.4, y0, x + 6.4, y0 + 14, (232, 234, 236))
        L.final = L.finish(L.S, blur=1, strength=0)
        im, left, top_ = sp.box(L, (x - 6.4, y0, x + 6.4, y0 + 14), black=False)
        # the letter stays in the box: dark
        d = ImageDraw.Draw(im)
        f = font(ARIAL_B, round(12 * sp.A))
        b = d.textbbox((0, 0), ch, font=f)
        d.text(((im.width - (b[2] - b[0])) / 2 - b[0], (im.height - (b[3] - b[1])) / 2 - b[1]), ch, font=f, fill=(29, 31, 38, 255))
        sp.add_show((im, left, top_), when)

    B = Art(REF, box, S=4, bg=(0, 0, 0))
    GRN = (60, 216, 96)
    B.d.arc([*B.q(224, 176), *B.q(236, 188)], -90, 90, fill=GRN, width=5)
    B.line([(230, 176), (230, 188)], GRN, 1.1)
    for y in (177, 180.5, 184, 187):
        B.line([(220, y + 0.5), (227, y)], GRN, 1)
    B.final = B.finish(B.S, blur=1, strength=0)
    sp.add_show(sp.box(B, (216, 172, 240, 192), black=True), "lights")

    parts = [(-20, 0, 1.4, 1.8, RED), (0, 88, 1.8, 0.9, RED)]
    add_needle(sp, needle_sprite(sp, 90, 22, parts, hub=11.5, hub_col=(190, 186, 174), hub_line=(24, 24, 26)), C1[0], C1[1], "mph", [(0, mph(0) if False else -178), (60, mph(60)), (240, mph(240)), (250, mph(250))])
    add_needle(sp, needle_sprite(sp, 90, 22, parts, hub=11.5, hub_col=(190, 186, 174), hub_line=(24, 24, 26)), C2[0], C2[1], "rpm", [(0, rpm(0)), (9.5, rpm(9.5))])
    fuel = [(54, 80, 1.1, 0.7, RED)]
    add_needle(sp, needle_sprite(sp, 82, 2, fuel), C1[0], C1[1], "fuel", [(0, FA(0)), (1, FA(1))])

    sprites = {ch: {"im": Image.new("RGBA", (4, 4), (0, 0, 0, 0))} for ch in "RNP1234567"}
    sp.gear = {"x": 0, "y": 0, "sprites": sprites}

    sp.font("speed", ARIAL_B, 14, "0123456789", shear=0, track=0.4)
    sp.font("unit", ARIAL_B, 10.5, "kmhp/", shear=0)
    if twin:
        sp.readout("speed", C1[0] + 8, 221, "r", 3, "speed", (232, 234, 236))
        sp.readout("unit", C1[0] + 12, 222, "l", 4, "unit", (232, 234, 236))
        return sp
    sp.readout("speed", 372, 203, "r", 3, "speed", (232, 234, 236))
    sp.readout("unit", 378, 204, "l", 4, "unit", (232, 234, 236))
    sp.font("small", ARIAL_B, 9.6, "0123456789:", shear=0, track=0.2)
    sp.font("smallu", ARIAL_B, 7.6, "kmhp/", shear=0)
    sp.readout("small", 322, 246.5, "l", 5, "clock", (226, 228, 230))
    sp.readout("small", 412, 246.5, "r", 3, "alt", (226, 228, 230))
    sp.readout("smallu", 415, 247, "l", 4, "altUnit", (226, 228, 230))
    return sp


def f599(Spec, needle_sprite, add_needle, glyph):
    """the F141: the white screen on the left, the big yellow rev dial, a black speedometer on the right. No horse.
    Coordinates below are the photo at 1400 wide; K puts them on the 1600 px photo."""
    K = 8 / 7
    box = (0, 208, 1600, 812)
    REF = "ferrari_599_cluster_owner.webp"
    A = Art(REF, box, S=2, bg=(12, 12, 14))
    sp = Spec("f599", box[2] - box[0], box[3] - box[1], 1.2, 1.2, box[0], box[1])
    sp.redline, sp.idle = 9.5, 0.9

    def P(x, y):
        return (x * K, y * K)

    def T(x, y, s, f, size, col, **kw):
        A.text(x * K, y * K, s, f, size * K, col, **kw)

    def L(pts, col, w):
        A.line([P(*p) for p in pts], col, w * K)

    C1 = P(703, 432)
    C2 = P(1097, 474)
    INK = (20, 34, 18)
    YEL = (238, 208, 40)
    PALE = (206, 224, 214)
    ORG = (246, 150, 40)
    RED = (232, 34, 26)

    def rev(v):
        return 180 + 25.7 * v

    def kph(v):
        return 180 + 0.8 * v

    r1, th1 = field(A, C1)
    r2, th2 = field(A, C2)
    h, w = r1.shape

    # the speedometer, under the yellow dial's edge
    blend(A, np.full((h, w, 3), (5.0, 5.0, 6.0)), band_mask(r2, -10, 190 * K, 0.6))
    s = 26 + 20 * smooth(180 * K, 190 * K, r2)
    blend(A, np.stack([s, s, s], axis=-1), band_mask(r2, 182 * K, 196 * K, 0.6))
    for v in range(0, 361, 10):
        big = v % 30 == 0 or v in (20, 50, 80, 110, 140, 170, 200, 230, 260, 290, 320, 360)
        a, b = polar(C2, (150 if big else 158) * K, kph(v)), polar(C2, 170 * K, kph(v))
        A.line([a, b], (226, 234, 228), (4 if big else 2) * K * 0.7)
    for v, f in ((20, 17), (50, 25), (80, 19), (110, 27), (140, 19), (170, 27), (200, 19), (230, 27), (260, 17), (290, 27), (320, 17), (360, 27)):
        p = polar(C2, 122 * K, kph(v))
        A.text(p[0], p[1], str(v), ARIAL_B, f * K, PALE)
    T(1026, 518, "km/h", ARIAL_B, 15, PALE)

    # the yellow dial
    blend(A, np.full((h, w, 3), (6.0, 6.0, 8.0)), band_mask(r1, 222 * K, 248 * K, 0.6))
    blend(A, np.full((h, w, 3), (196.0, 198.0, 200.0)), band_mask(r1, 222 * K, 229 * K, 0.6))
    t = smooth(0, 222 * K, r1)
    face = np.stack([242 - 8 * t, 214 - 8 * t, 44 + 0 * t], axis=-1)
    blend(A, face, band_mask(r1, -10, 222 * K, 0.6))
    for i in range(0, 101):
        v = i / 10
        d = rev(v)
        big = i % 10 == 0
        mid = i % 5 == 0
        col = (170, 30, 24) if v >= 9 else INK
        if big:
            A.line([polar(C1, 188 * K, d), polar(C1, 222 * K, d)], col, 7 * K * 0.8)
        else:
            A.line([polar(C1, (203 if mid else 208) * K, d), polar(C1, 214 * K, d)], col, 1.6 * K)
    A.line([polar(C1, 212 * K, rev(0) + 0.1 * i) for i in range(0, 2571, 30)], INK, 1.2 * K)
    for v in range(0, 11):
        p = polar(C1, 158 * K, rev(v))
        A.text(p[0], p[1], str(v), ARIAL_BI, 45 * K, INK)
    T(622, 470, "rpm x 1000", ARIAL_BI, 16, INK)
    A.round_rect(780 * K, 475 * K, 838 * K, 549 * K, 7 * K, (58, 36, 12))
    T(808, 542, "auto", ARIAL_B, 11, ORG)

    # the white screen
    W = [(66, 340), (440, 340), (440, 520), (490, 585), (490, 652), (50, 652)]
    A.poly([P(x - 6, y - 6) for x, y in W[:1]] + [P(446, 334), P(446, 518), P(496, 583), P(496, 658), P(44, 658), P(60, 334)], (34, 34, 38))
    A.poly([P(*p) for p in W], (232, 232, 228))
    L([(66, 377), (440, 377)], (24, 24, 26), 2)
    L([(66, 583), (486, 583)], (120, 120, 120), 1.6)
    T(275, 358, "26 °C", ARIAL_B, 27, (20, 20, 22))
    T(388, 364, "SPORT", ARIAL, 20, (20, 20, 22))

    def gauge(c, low, top, high):
        for a in range(-135, 92, 3):
            A.line([polar(c, 66 * K, a), polar(c, 66 * K, a + 3)], (16, 16, 18), 8 * K)
        for a in range(92, 136, 3):
            A.line([polar(c, 66 * K, a), polar(c, 66 * K, a + 3)], (206, 30, 24), 8 * K)
        for a in (-90, -45, 0, 45, 90):
            A.line([polar(c, 58 * K, a), polar(c, 70 * K, a)], (232, 232, 228), 1.6 * K)
        T(c[0] / K, c[1] / K - 50, top, ARIAL, 18, (24, 24, 26))
        T(c[0] / K - 38, c[1] / K + 36, low, ARIAL, 18, (24, 24, 26))
        T(c[0] / K + 30, c[1] / K + 34, high, ARIAL, 18, (24, 24, 26))
        T(c[0] / K - 5, c[1] / K - 26, "°C", ARIAL, 14, (24, 24, 26))
        A.circle(c[0], c[1], 12 * K, None, outline=(150, 150, 154), w=3 * K)
        A.line([polar(c, 12 * K, -98), polar(c, 60 * K, -98)], (226, 40, 30), 2.2 * K)

    gauge(P(165, 456), "60", "100", "140")
    gauge(P(335, 456), "50", "110", "170")
    A.round_rect(70 * K, 535 * K, 116 * K, 581 * K, 3 * K, (30, 30, 30))
    A.round_rect(82 * K, 543 * K, 98 * K, 573 * K, 2 * K, ORG)
    for x in range(105, 236, 26):
        L([(x, 594), (x, 612)], (150, 150, 150), 1.4)
    L([(105, 594), (235, 594), (235, 612), (105, 612), (105, 594)], (120, 120, 120), 1.6)
    T(106, 642, "0", ARIAL, 17, (24, 24, 26))
    T(172, 640, "1/2", ARIAL, 17, (24, 24, 26))
    T(230, 642, "1", ARIAL, 17, (24, 24, 26))
    A.round_rect(62 * K, 603 * K, 82 * K, 638 * K, 2 * K, (30, 30, 34))
    A.round_rect(242 * K, 590 * K, 302 * K, 613 * K, 3 * K, (240, 170, 80))
    T(272, 601, "auto", ARIAL_B, 22, (24, 24, 26))

    A.final = A.finish(A.S, blur=1.2, strength=0.15)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    add_fuel(sp, REF, box, 106 * K, 595 * K, 234 * K, 611 * K, (244, 168, 70), S=2)

    # warning lamps, parked as in the photo
    B = Art(REF, box, S=2, bg=(0, 0, 0))
    for x, y, col in ((850, 250, (240, 130, 30)), (900, 303, (226, 44, 30)), (955, 317, (226, 44, 30)), (905, 560, (240, 170, 40)), (875, 598, (226, 44, 30))):
        B.round_rect((x - 13) * K, (y - 9) * K, (x + 13) * K, (y + 9) * K, 3 * K, None, outline=col, w=2.4 * K)
    B.final = B.finish(B.S, blur=1, strength=0)
    sp.add_show(sp.box(B, (820 * K, 232 * K, 990 * K, 620 * K), black=True), "parked")

    # needles
    parts = [(-46, 0, 4.4, 4.4, RED), (0, 190, 5.0, 1.4, RED)]
    add_needle(sp, needle_sprite(sp, 190, 46, parts, hub=34, hub_col=(204, 206, 210), hub_line=(120, 122, 126)), C1[0], C1[1], "rpm", [(0, rev(0)), (10.5, rev(10.5))])
    parts2 = [(-40, 0, 3.6, 3.6, RED), (0, 155, 5.0, 1.2, (236, 40, 90))]
    add_needle(sp, needle_sprite(sp, 158, 40, parts2, hub=32, hub_col=(240, 240, 240), hub_line=(120, 122, 126)), C2[0], C2[1], "kmh", [(0, kph(0)), (360, kph(360))])

    # gear box: orange, the way the photo has it
    sprites = {}
    f = {"path": ARIAL_B, "size": 52, "chars": "", "stroke": 0.1, "shear": 0, "track": 0}
    for ch in "RN1234567":
        g, ox, oy, adv = glyph(ch, f, sp.A)
        c = Image.new("RGBA", g.size, ORG + (0,))
        c.putalpha(g.getchannel("A"))
        sprites[ch] = {"im": c}
    sp.gear = {"x": 808 * K - sp.ox, "y": 505 * K - sp.oy, "sprites": sprites}

    dark = (20, 20, 22)
    sp.font("clock", ARIAL_B, 36, "0123456789:", shear=0, track=1.5)
    sp.readout("clock", 118 * K, 359 * K, "m", 5, "clock", dark)
    sp.font("odo", ARIAL, 32, "0123456789", shear=0, track=0.8)
    sp.readout("odo", 368 * K, 634 * K, "r", 7, "odoTrim", dark)
    sp.font("spd", ARIAL, 44, "0123456789", shear=0, track=0.5)
    sp.readout("spd", 466 * K, 630 * K, "r", 3, "speed", dark)
    sp.font("unit", ARIAL, 21, "kmhpi/", shear=0)
    sp.readout("unit", 440 * K, 598 * K, "m", 4, "unit", dark)
    sp.readout("unit", 349 * K, 598 * K, "m", 2, "distUnit", dark)
    return sp


def dbx(Spec, needle_sprite, add_needle, glyph):
    """the Highland's wide screen: two round dials with red faces and white rings, the mileage panel between them. No wings
    on the dial. Coordinates below are the photo at 1400 wide; K puts them on the 800 px photo."""
    K = 4 / 7
    box = (60, 128, 748, 390)
    REF = "dbx_cluster_owner.png"
    A = Art(REF, box, S=6, bg=(7, 7, 9))
    sp = Spec("dbx", box[2] - box[0], box[3] - box[1], 2.6, 2.6, box[0], box[1])
    sp.redline, sp.idle = 7.0, 0.8

    def P(x, y):
        return (x * K, y * K)

    def T(x, y, s, f, size, col, **kw):
        A.text(x * K, y * K, s, f, size * K, col, **kw)

    C1 = P(350, 435)
    C2 = P(1040, 455)
    WHT = (238, 238, 240)
    DIM = (168, 170, 176)
    RED = (214, 36, 26)
    ORG = (246, 96, 30)
    MPH = [(0, 180), (20, 211), (60, 272), (120, 364), (180, 420), (220, 451)]

    def mph(v):
        for (a, x), (b, y) in zip(MPH, MPH[1:]):
            if v <= b:
                return x + (y - x) * (v - a) / (b - a)
        return MPH[-1][1]

    def rev(v):
        return 180 + 34 * v

    h, w = A.H * A.S, A.W * A.S
    yy, xx = np.mgrid[0:h, 0:w]
    px = (xx + 0.5) / A.S + A.ox
    py = (yy + 0.5) / A.S + A.oy
    # the red glow along the top, and the strip of dots along the bottom
    glow = np.exp(-(((py / K - 275) / 42) ** 2)) * np.exp(-(((px / K - 700) / 330) ** 2))
    blend(A, np.full((h, w, 3), (150.0, 12.0, 8.0)), glow * 0.8)
    for row in range(0, 6):
        for col in range(0, 40):
            x = 470 + col * 19 + (row % 2) * 9
            y = 590 + row * 15
            A.round_rect((x - 6) * K, (y - 3) * K, (x + 6) * K, (y + 3) * K, 1.2, (24, 24, 26))

    def dial(C, scale, nums, step_small):
        r, th = field(A, C)
        for s in (172, 176):
            A.circle(C[0], C[1], s * K, None, outline=(150, 152, 156), w=1.0)
        # the red face and rays
        rays = 0.9 + 0.1 * np.cos(np.radians(th * 90))
        t = smooth(58 * K, 118 * K, r)
        face = np.stack([(30 + 120 * (1 - t) + 70 * t) * rays, 6 + 8 * t, 6 + 8 * t], axis=-1)
        blend(A, face, band_mask(r, 58 * K, 120 * K, 0.5))
        blend(A, np.full((h, w, 3), (238.0, 238.0, 240.0)), band_mask(r, 120 * K, 150 * K, 0.5))
        blend(A, np.full((h, w, 3), (14.0, 14.0, 16.0)), band_mask(r, 150 * K, 172 * K, 0.5))
        for v, s in nums:
            p = polar(C, 135 * K, scale(v))
            A.text(p[0], p[1], s, ARIAL, 19 * K, (20, 20, 24))
            A.line([polar(C, 152 * K, scale(v)), polar(C, 172 * K, scale(v))], WHT, 1.3)
        for v in step_small:
            A.line([polar(C, 160 * K, scale(v)), polar(C, 172 * K, scale(v))], DIM, 0.7)
        return r, th

    dial(C1, mph, [(v, str(v)) for v in (0, 20, 40, 60, 80, 100, 120, 150, 180, 220)], [v for v in range(5, 220, 10)])
    r2, th2 = dial(C2, rev, [(v, str(v)) for v in range(0, 9)], [v / 2 for v in range(1, 16, 2)])
    # the red line on the rev scale
    for v in (7, 7.5, 8):
        A.line([polar(C2, 150 * K, rev(v)), polar(C2, 172 * K, rev(v))], ORG, 1.6)
    # the middle discs
    for C in (C1, C2):
        r, th = field(A, C)
        s = 34 + 60 * smooth(-1, 1, np.cos(np.radians(th - 20)))
        blend(A, np.stack([s, s, s * 1.03], axis=-1), band_mask(r, -5, 58 * K, 0.5))
        A.circle(C[0], C[1], 60 * K, None, outline=(226, 226, 230), w=1.2)
    r1, th1 = field(A, C1)
    blend(A, np.full((h, w, 3), (20.0, 20.0, 24.0)), band_mask(r1, -5, 58 * K, 0.5))
    A.circle(C1[0], C1[1], 60 * K, None, outline=(226, 226, 230), w=1.2)
    T(1042, 575, "x1000 RPM", ARIAL, 12, DIM)

    # the panel between the dials
    panel = [P(500, 300), P(520, 288), P(880, 288), P(905, 305), P(880, 330), P(855, 565), P(545, 565), P(525, 330)]
    A.poly(panel, (17, 18, 22))
    A.line([P(500, 300), P(520, 288), P(880, 288), P(905, 305)], (214, 60, 50), 1.4)
    T(700, 357, "Mileage", ARIAL_B, 19, WHT)
    A.line([P(618, 476), P(668, 476)], DIM, 0.8)
    A.line([P(730, 476), P(780, 476)], DIM, 0.8)
    T(699, 478, "miles", ARIAL, 15, WHT)

    # far sides: the temperature bar, the fuel pump
    for k in range(0, 8):
        y = 395 + k * 15
        col = (64, 150, 230) if k > 4 else (214, 214, 218)
        A.rect(1238 * K, y * K, 1245 * K, (y + 12) * K, col)
    A.round_rect(132 * K, 484 * K, 143 * K, 500 * K, 1, WHT)
    # the top line
    T(928, 250, "P", ARIAL_B, 20, WHT)
    T(974, 250, "S+", ARIAL_B, 20, WHT)
    T(1025, 253, "64°F", ARIAL_B, 13, WHT)
    A.final = A.finish(A.S, blur=1.0, strength=0.2)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    B = Art(REF, box, S=4, bg=(0, 0, 0))
    B.text(815 * K, 645 * K, "(!)", ARIAL_B, 15 * K, (246, 96, 30))
    B.text(925 * K, 647 * K, "PARK", ARIAL_B, 11 * K, (226, 44, 30))
    B.final = B.finish(B.S, blur=1, strength=0)
    sp.add_show(sp.box(B, (795 * K, 630 * K, 955 * K, 660 * K), black=True), "parked")

    parts = [(60, 118, 2.0, 1.2, (250, 240, 240)), (118, 170, 1.2, 0.6, (250, 90, 60))]
    add_needle(sp, needle_sprite(sp, 172 * K + 4, 2, [(a * K, b * K, c, d, e) for a, b, c, d, e in parts]), C1[0], C1[1], "mph", MPH)
    add_needle(sp, needle_sprite(sp, 172 * K + 4, 2, [(a * K, b * K, c, d, e) for a, b, c, d, e in parts]), C2[0], C2[1], "rpm", [(0, rev(0)), (8.5, rev(8.5))])
    # the fuel mark on an arc left of the speedometer
    add_needle(sp, needle_sprite(sp, 208 * K, 2, [(190 * K, 206 * K, 1.0, 1.0, WHT)]), C1[0], C1[1], "fuel", [(0, 245), (1, 295)])

    sprites = {ch: {"im": Image.new("RGBA", (4, 4), (0, 0, 0, 0))} for ch in "RNP1234567"}
    sp.gear = {"x": 0, "y": 0, "sprites": sprites}
    sp.font("speed", ARIAL, 27, "0123456789", shear=0, track=0.2)
    sp.readout("speed", 355 * K, 434 * K, "m", 3, "speed", WHT)
    sp.font("unit", ARIAL_B, 7, "kmhpi/", shear=0)
    sp.readout("unit", 355 * K, 471 * K, "m", 4, "unit", WHT)
    sp.font("trip", ARIAL_B, 19, "0123456789.", shear=0, track=0.2)
    sp.readout("trip", 698 * K, 433 * K, "m", 7, "trip", WHT)
    sp.font("odo", ARIAL_B, 11, "0123456789", shear=0, track=0.2)
    sp.readout("odo", 696 * K, 513 * K, "m", 7, "odoTrim", WHT)
    sp.font("top", ARIAL_B, 7.6, "0123456789:./", shear=0, track=0.1)
    sp.readout("top", 360 * K, 236 * K, "m", 10, "date", WHT)
    sp.readout("top", 452 * K, 238 * K, "m", 5, "clock", WHT)
    return sp
