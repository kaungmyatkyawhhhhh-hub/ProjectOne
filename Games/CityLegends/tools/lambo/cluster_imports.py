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


def pods(Spec, needle_sprite, add_needle, glyph, name, W, H, items, windows, boxes=()):
    """round dials redrawn sharp from a model's own dial picture, for a car with no photo: live needles, plus the digital bits
    in the boxes. Coordinates are design pixels (0.5 mm each); the panel is cut to the model's bowls (window_<name>.png)."""
    box = (0, 0, W, H)
    REF = "sls_sl65_cluster_owner.png"
    A = Art(REF, box, S=4, bg=(6, 6, 8))
    sp = Spec(name, W, H, 2.0, 2.0, 0, 0)
    sp.redline, sp.idle = 7.5, 0.8
    window(name, box, windows[0], windows[1], S=2)
    h, w = A.H * A.S, A.W * A.S
    for it in items:
        C, R, kind = it["c"], it["r"], it["kind"]
        a0, a1, vmax = it["a0"], it["a1"], it["vmax"]

        def ang(v, a0=a0, a1=a1, vmax=vmax):
            return a0 + (a1 - a0) * v / vmax

        r, th = field(A, C)
        blend(A, np.full((h, w, 3), it.get("face", (8.0, 8.0, 10.0))), band_mask(r, -5, R * 0.96, 0.5))
        s = 150 + 50 * np.cos(np.radians(th - 320))
        ring = it.get("ring", 1.0)
        blend(A, np.stack([s * ring, s * ring, s * ring * 0.98], axis=-1), band_mask(r, R * 0.96, R, 0.5))
        num, tick = it["num"], it["tick"]
        minor = it.get("minor", 5)
        n = round(vmax / it["step"]) * minor
        for i in range(0, n + 1):
            v = vmax * i / n
            big = i % minor == 0
            col = (214, 40, 30) if it.get("red") is not None and v >= it["red"] else tick
            A.line([polar(C, R * (0.78 if big else 0.84), ang(v)), polar(C, R * 0.92, ang(v))], col, 2.4 if big else 1.0)
        for i in range(0, round(vmax / it["step"]) + 1):
            v = it["step"] * i
            if v == 0 and it.get("skip0"):
                continue
            p = polar(C, R * 0.62, ang(v))
            lab = str(int(v / it.get("div", 1)))
            A.text(p[0], p[1], it.get("labels", {}).get(i, lab), ARIAL_B, R * it.get("fs", 0.2), num)
        if it.get("word"):
            A.text(C[0], C[1] + R * 0.42, it["word"], ARIAL_B, R * 0.11, num)
    for b in boxes:
        A.round_rect(b["x0"], b["y0"], b["x1"], b["y1"], 6, b.get("col", (16, 18, 22)), outline=(70, 70, 74), w=1.2)
    A.final = A.finish(A.S, blur=1.0, strength=0.2)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    for it in items:
        C, R, kind = it["c"], it["r"], it["kind"]
        a0, a1, vmax = it["a0"], it["a1"], it["vmax"]
        red = it.get("needle", (232, 44, 28))
        parts = [(-R * 0.16, 0, 1.6, 2.0, red), (0, R * 0.88, 2.6, 0.9, red)]
        im = needle_sprite(sp, R * 0.9, R * 0.17, parts, hub=R * 0.09, hub_col=(30, 30, 34), hub_line=(120, 120, 124))
        add_needle(sp, im, C[0], C[1], kind, [(0, a0), (vmax, a1)])

    sprites = {}
    g = next((b for b in boxes if b.get("gear")), None)
    f = {"path": ARIAL_B, "size": (g or {}).get("gear", 30), "chars": "", "stroke": 0.1, "shear": 0, "track": 0}
    for ch in "RN1234567":
        im, ox, oy, adv = glyph(ch, f, sp.A)
        c = Image.new("RGBA", im.size, (246, 200, 120, 0))
        c.putalpha(im.getchannel("A"))
        sprites[ch] = {"im": c}
    sp.gear = {"x": g["gx"] if g else -100, "y": g["gy"] if g else -100, "sprites": sprites}
    sp.font("speed", ARIAL_B, 30, "0123456789", shear=0, track=0.2)
    sp.font("unit", ARIAL_B, 12, "kmhpi/", shear=0)
    sp.font("odo", ARIAL_B, 14, "0123456789:", shear=0, track=0.2)
    for b in boxes:
        col = (240, 236, 226)
        if b.get("sx") is not None:
            sp.readout("speed", b["sx"], b["sy"], "m", 3, "speed", col)
            sp.readout("unit", b["sx"], b["sy"] + 24, "m", 4, "unit", col)
        if b.get("ox") is not None:
            sp.readout("odo", b["ox"], b["oy"], "m", 7, "odoTrim", col)
    return sp


def sovereign(Spec, needle_sprite, add_needle, glyph):
    GOLD = (222, 184, 104)
    items = [
        {"c": (160, 138), "r": 104, "kind": "rpm", "a0": -130, "a1": 130, "vmax": 8, "step": 1, "red": 6.5, "num": GOLD, "tick": GOLD, "word": "x1000 rpm", "skip0": True},
        {"c": (584, 150), "r": 104, "kind": "mph", "a0": -130, "a1": 130, "vmax": 200, "step": 20, "num": GOLD, "tick": GOLD, "word": "mph", "fs": 0.17, "skip0": True},
        {"c": (312, 206), "r": 38, "kind": "fuel", "a0": -110, "a1": 110, "vmax": 1, "step": 0.5, "minor": 2, "num": GOLD, "tick": GOLD, "fs": 0.26, "labels": {0: "E", 1: "", 2: "F"}, "needle": (232, 232, 236)},
    ]
    return pods(Spec, needle_sprite, add_needle, glyph, "sovereign", 740, 280, items,
                ([[(290, 14), (450, 14), (450, 150), (290, 150)]], [((160, 138), 104), ((584, 150), 104), ((312, 206), 38)]),
                [{"x0": 292, "y0": 16, "x1": 448, "y1": 148, "sx": 370, "sy": 64, "ox": 370, "oy": 132, "gear": 24, "gx": 424, "gy": 40}])


def z33(Spec, needle_sprite, add_needle, glyph):
    ORG = (248, 150, 40)
    items = [
        {"c": (136, 136), "r": 110, "kind": "fuel", "a0": -100, "a1": 100, "vmax": 1, "step": 0.5, "minor": 2, "num": ORG, "tick": ORG, "fs": 0.18, "labels": {0: "E", 1: "", 2: "F"}, "word": "FUEL", "needle": (240, 240, 244)},
        {"c": (384, 88), "r": 112, "kind": "rpm", "a0": -150, "a1": 120, "vmax": 8, "step": 1, "red": 6.5, "num": ORG, "tick": ORG, "word": "x1000 rpm"},
        {"c": (632, 136), "r": 110, "kind": "mph", "a0": -130, "a1": 130, "vmax": 160, "step": 20, "num": ORG, "tick": ORG, "word": "mph", "fs": 0.17, "skip0": True},
    ]
    return pods(Spec, needle_sprite, add_needle, glyph, "z33", 760, 280, items,
                ([], [((136, 136), 110), ((384, 88), 112), ((632, 136), 110)]),
                [{"x0": 340, "y0": 132, "x1": 428, "y1": 176, "col": (10, 10, 12), "ox": 384, "oy": 166, "gear": 22, "gx": 384, "gy": 146}])


def g20(Spec, needle_sprite, add_needle, glyph):
    """the G20 Sport's own screen (the model's picture, imports/refs/g20_model_cluster.png, 0.4 mm a pixel): two
    six-sided arcs that light up as the speed and the revs climb, the big speed in the left one, the gear in the
    right one's rings, fuel and temperature arcs outside, mileage and drive mode along the bottom. No names."""
    W, H = 834, 310
    box = (0, 0, W, H)
    REF = "g20_model_cluster.png"
    A = Art(REF, box, S=4, bg=(3, 3, 5))
    sp = Spec("g20", W, H, 2.0, 2.0, 0, 0)
    sp.redline, sp.idle = 7.0, 0.8
    WHT = (240, 240, 242)
    DIM = (150, 152, 158)
    MID = 848  # the screen's middle line, doubled: the right arc is the left one mirrored

    O = [(230, 258), (150, 258), (132, 246), (98, 190), (80, 142), (86, 126), (114, 84), (160, 48), (232, 25), (338, 14)]
    CEN = (235, 150)

    def offset(poly, d):
        out = []
        for i, p in enumerate(poly):
            ns = []
            for a, b in ((poly[i - 1], p) if i > 0 else (None, None), (p, poly[i + 1]) if i + 1 < len(poly) else (None, None)):
                if a is None:
                    continue
                dx, dy = b[0] - a[0], b[1] - a[1]
                L = math.hypot(dx, dy)
                n = (-dy / L, dx / L)
                m = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
                if (CEN[0] - m[0]) * n[0] + (CEN[1] - m[1]) * n[1] < 0:
                    n = (-n[0], -n[1])
                ns.append(n)
            nx, ny = sum(n[0] for n in ns), sum(n[1] for n in ns)
            L = math.hypot(nx, ny)
            nx, ny = nx / L, ny / L
            k = 1 / max(0.5, nx * ns[0][0] + ny * ns[0][1])
            out.append((p[0] + nx * d * k, p[1] + ny * d * k))
        return out

    I = offset(O, 24)
    seg = [math.hypot(O[i + 1][0] - O[i][0], O[i + 1][1] - O[i][1]) for i in range(len(O) - 1)]
    total = sum(seg)

    def at(poly, s):
        # the point a length s along (the outer line's lengths)
        for i, L in enumerate(seg):
            if s <= L or i == len(seg) - 1:
                f = min(1.0, s / L)
                a, b = poly[i], poly[i + 1]
                return (a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f)
            s -= L

    def s_of(pt):
        # length along the outer line of the point nearest pt
        best, bs, run = 1e9, 0.0, 0.0
        for i, L in enumerate(seg):
            a, b = O[i], O[i + 1]
            dx, dy = b[0] - a[0], b[1] - a[1]
            f = max(0.0, min(1.0, ((pt[0] - a[0]) * dx + (pt[1] - a[1]) * dy) / (L * L)))
            q = (a[0] + dx * f, a[1] + dy * f)
            d = math.hypot(pt[0] - q[0], pt[1] - q[1])
            if d < best:
                best, bs = d, run + L * f
            run += L
        return bs

    NUMS = [(196, 234), (152, 221), (130, 187), (117, 138), (143, 99), (190, 67), (257, 50), (326, 44)]
    stops = [s_of(p) for p in NUMS]
    stops[0] = 0.0  # the band starts at nought
    MPH = [0, 10, 20, 40, 60, 80, 120, 160]
    REV = [0, 1, 2, 3, 4, 5, 6, 7]

    def val(s, scale):
        if s <= stops[0]:
            return scale[0]
        for (s0, v0), (s1, v1) in zip(zip(stops, scale), zip(stops[1:], scale[1:])):
            if s <= s1:
                return v0 + (v1 - v0) * (s - s0) / (s1 - s0)
        return scale[-1] + (scale[-1] - scale[-2]) * (s - stops[-1]) / (stops[-1] - stops[-2])

    def flip(pts, right):
        return [(MID / 2 * 2 - x, y) for x, y in pts] if right else pts

    def band(s0, s1, n=6):
        outer = [at(O, s0 + (s1 - s0) * k / n) for k in range(n + 1)]
        inner = [at(I, s0 + (s1 - s0) * k / n) for k in range(n + 1)]
        return outer + inner[::-1]

    s_end = total
    s_red = None
    for k in range(400):
        s = stops[0] + (s_end - stops[0]) * k / 400
        if val(s, REV) >= 6.5:
            s_red = s
            break

    # the unlit bands, the red end of the rev scale
    for right in (False, True):
        A.poly(flip(band(0, s_end, 40), right), (52, 11, 8))
        A.poly(flip(band(0, s_end, 40), right), (52, 11, 8))
        if right and s_red:
            A.poly(flip(band(s_red, s_end, 10), right), (116, 16, 12))
        # a soft dark edge along the inner side
        A.line(flip([at(I, stops[0] + (s_end - stops[0]) * k / 40) for k in range(41)], right), (96, 26, 18), 1.0)
        # the white frame: the bottom line, the notch, the six sides, the end
        bottom = [(376, 245), (238, 245), (230, 258)]
        A.line(flip(bottom + O[1:] + [(338, 28)], right), WHT, 2.4)
        # white teeth on the frame at each number
        for s in stops:
            p = at(O, s)
            q = at(I, s)
            dx, dy = q[0] - p[0], q[1] - p[1]
            L = math.hypot(dx, dy)
            ux, uy = dx / L, dy / L
            tri = [(p[0] - uy * 4.5, p[1] + ux * 4.5), (p[0] + uy * 4.5, p[1] - ux * 4.5), (p[0] + ux * 7, p[1] + uy * 7)]
            A.poly(flip(tri, right), WHT)
        scale = REV if right else MPH
        for p, v in zip(NUMS, scale):
            x, y = flip([p], right)[0]
            A.text(x, y, str(v), ARIAL_B, 17, WHT)

    A.text(238, 235, "mph", ARIAL, 10, WHT, anchor="lm")
    A.text(612, 226, "1/min", ARIAL, 8, WHT, anchor="rm")
    A.text(612, 236, "x1000", ARIAL, 8, WHT, anchor="rm")
    # under the big speed
    A.line([(193, 166), (318, 166)], (120, 122, 128), 1.2)
    A.line([(193, 166), (232, 166)], (222, 224, 230), 1.4)

    # the right arc's rings (the model's g-meter) round the gear
    G = (608, 143)
    for r, col, w_ in ((66, (70, 72, 78), 3.0), (46, (96, 98, 104), 2.2), (26, (60, 62, 68), 1.6)):
        A.circle(G[0], G[1], r, None, outline=col, w=w_)
    A.line([(G[0] - 70, G[1]), (G[0] - 30, G[1])], (54, 56, 60), 0.8)
    A.line([(G[0] + 30, G[1]), (G[0] + 70, G[1])], (54, 56, 60), 0.8)
    for x0 in range(540, 678, 8):
        A.line([(x0, 75), (x0 + 4, 75)], (110, 112, 118), 0.8)
        A.line([(x0, 213), (x0 + 4, 213)], (110, 112, 118), 0.8)
    for y0 in range(75, 213, 8):
        A.line([(540, y0), (540, y0 + 4)], (110, 112, 118), 0.8)
        A.line([(678, y0), (678, y0 + 4)], (110, 112, 118), 0.8)

    # fuel (left) and temperature (right) arcs outside the big ones
    C = (110, 196)
    for right in (False, True):
        c = (MID - C[0], C[1]) if right else C
        sgn = -1 if right else 1
        r, th = field(A, c)
        a0, a1 = (190, 285) if not right else (75, 170)
        thn = np.mod(th, 360)
        inarc = ((thn >= a0) & (thn <= a1)).astype(float)
        shade = 44 + 46 * np.clip((r - 58) / 10, 0, 1)
        blend(A, np.stack([shade, shade, shade * 1.04], axis=-1), band_mask(r, 58, 68, 0.5) * inarc)
        arc_o = [polar(c, 69, a0 + (a1 - a0) * k / 24) for k in range(25)]
        A.line(arc_o, WHT, 1.4)
        for k in range(0, 5):
            a = a0 + (a1 - a0) * k / 4
            A.line([polar(c, 58, a), polar(c, 68, a)], (200, 200, 204), 1.0)
        if right:
            A.line([polar(c, 58, 162), polar(c, 68, 162)], (60, 130, 240), 3.0)
            A.line([polar(c, 52, 120), polar(c, 70, 120)], WHT, 1.6)  # the engine is warm
        else:
            A.line([polar(c, 58, 197), polar(c, 68, 197)], (230, 40, 30), 3.0)
            for a, s in ((198, "0"), (238, "1/2"), (279, "1")):
                p = polar(c, 47, a)
                A.text(p[0], p[1], s, ARIAL_B, 10, WHT)
    # the fuel pump
    A.round_rect(12, 232, 22, 248, 1.5, (210, 210, 214))
    A.rect(14, 235, 20, 239, (20, 20, 22))
    A.line([(22, 236), (26, 238), (26, 246)], (210, 210, 214), 1.2)

    A.final = A.finish(A.S, blur=1.0, strength=0.2)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # the lit cells: each a piece of the band, on when the speed (left) or the revs (right) pass its start
    B = Art(REF, box, S=4, bg=(0, 0, 0))
    for right in (False, True):
        B.poly(flip(band(0, s_end, 40), right), (240, 88, 24))
        B.line(flip([at(O, s_end * k / 40) for k in range(41)], right), (255, 150, 72), 3.0)
        if right and s_red:
            B.poly(flip(band(s_red, s_end, 10), right), (238, 34, 24))
        # the numbers stay on top of the lit band
        for p, v in zip(NUMS, REV if right else MPH):
            x, y = flip([p], right)[0]
            B.text(x, y, str(v), ARIAL_B, 17, WHT)
    B.final = B.finish(B.S, blur=1, strength=0)
    N = 44
    for right in (False, True):
        for k in range(N):
            s0 = stops[0] + (s_end - stops[0]) * k / N
            s1 = stops[0] + (s_end - stops[0]) * (k + 1) / N + 0.4
            pts = flip(band(s0, s1, 2), right)
            xs, ys = [p[0] for p in pts], [p[1] for p in pts]
            bx = (math.floor(min(xs)) - 1, math.floor(min(ys)) - 1, math.ceil(max(xs)) + 1, math.ceil(max(ys)) + 1)
            v = val(s0, REV if right else MPH)
            sp.add_block(B, bx, pts, v)
            if not right:
                sp.blocks[-1]["bind"] = "mph"

    # the fuel mark
    add_needle(sp, needle_sprite(sp, 72, 2, [(55, 71, 1.4, 1.4, (250, 130, 50))]), C[0], C[1], "fuel", [(0, 196), (1, 281)])

    sprites = {}
    f = {"path": ARIAL_B, "size": 40, "chars": "", "stroke": 0.1, "shear": 0, "track": 0}
    for ch in "RN1234567":
        im, ox, oy, adv = glyph(ch, f, sp.A)
        c2 = Image.new("RGBA", im.size, (244, 244, 246, 0))
        c2.putalpha(im.getchannel("A"))
        sprites[ch] = {"im": c2}
    sp.gear = {"x": G[0], "y": G[1], "sprites": sprites}
    sp.font("speed", ARIAL_B, 40, "0123456789", shear=0, track=0.1)
    sp.readout("speed", 272, 137, "r", 3, "speed", WHT)
    sp.font("unit", ARIAL_B, 11, "kmhpi/", shear=0)
    sp.readout("unit", 279, 151, "l", 4, "unit", WHT)
    sp.font("odo", ARIAL_B, 13, "0123456789:kmiSPORTNMAL", shear=0, track=0.15)
    sp.readout("odo", 350, 266, "r", 7, "odoTrim", WHT)
    sp.readout("odo", 356, 266, "l", 2, "distUnit", DIM)
    sp.readout("odo", 478, 266, "l", 6, "driveMode", WHT)
    sp.readout("odo", 424, 22, "m", 5, "clock", WHT)
    return sp



def r8g1(Spec, needle_sprite, add_needle, glyph, solid_gear, gt=False):
    """the first Precision Type 42 (owner's photo imports/refs/audi_r8_gen1_cluster_owner.png): two deep round dials with
    silver rings and a red inner ring, revs 0-10 on the left (red from 9), 0-350 km/h on the right, a dark screen low in
    each dial, water and fuel gauges in their little hood at the top, the screen in the middle, oil and volts at the far
    ends of the pods. The dial's names are left out. Coordinates are photo pixels (0.46 mm each on the model); the box
    reaches past the photo to the ends of the model's pods.
    gt: the Lightweight (2011 R8 GT, 2026-11-09): the same cluster with the real GT's white dial faces (all five round
    gauges, the red outline kept), dark numbers and red needles; its unlit warning lamps don't show on the white."""
    from cluster_art import FONTDIR

    DIG = FONTDIR + "BuilderExtended-SemiBold.otf"
    box = (-85, 60, 763, 375)
    REF = "audi_r8_gen1_cluster_owner.png"
    A = Art(REF, box, S=4, bg=(7, 7, 8))
    sp = Spec("r8gt" if gt else "r8g1", box[2] - box[0], box[3] - box[1], 2.35, 2.35, box[0], box[1])
    sp.redline, sp.idle = 8.7, 0.9
    C1, C2 = (153.0, 233.0), (525.0, 233.0)
    NUM = (236, 236, 238)
    DIM = (176, 178, 182)
    RED = (214, 30, 34)
    # the dials' own print: light on the photo's black faces, dark on the GT's white ones
    FACE = (229.0, 229.0, 231.0)
    INK = (22, 22, 24) if gt else NUM
    INK_DIM = (98, 100, 104) if gt else DIM
    NEEDLE = (206, 28, 30) if gt else (238, 238, 240)
    SPD = [(0, -131), (20, -114), (40, -97), (60, -79), (80, -61), (100, -43), (120, -25), (140, -7), (170, 13), (200, 33),
           (230, 52.5), (260, 72), (290, 92), (320, 111.5), (350, 131)]

    def kph(v):
        for (a, x), (b, y) in zip(SPD, SPD[1:]):
            if v <= b:
                return x + (y - x) * (v - a) / (b - a)
        return SPD[-1][1]

    def rev(v):
        return -131 + 26.2 * v

    h, w = A.H * A.S, A.W * A.S
    yy, xx = np.mgrid[0:h, 0:w]
    px = (xx + 0.5) / A.S + A.ox
    py = (yy + 0.5) / A.S + A.oy

    # the pods round the dials: dark grey, lighter low down
    for C, side in ((C1, -1), (C2, 1)):
        far = (C[0] + side * 150, C[1] + 34)
        pod = np.zeros((h, w))
        for c, rad in ((C, 128.0), (far, 46.0)):
            pod = np.maximum(pod, np.clip((rad - np.hypot(px - c[0], py - c[1])) / 1.0, 0, 1))
        t = np.clip((px - C[0]) * side / 150.0, 0, 1)
        half = 128 + (46 - 128) * t
        inside = ((px - C[0]) * side > 0) & ((px - C[0]) * side < 160)
        pod = np.maximum(pod, np.clip((half - np.abs(py - (C[1] + 34 * t))) / 1.0, 0, 1) * inside)
        tone = 18 + 16 * smooth(180, 340, py)
        blend(A, np.stack([tone, tone, tone * 1.04], axis=-1), pod)

    # the two dials
    for C in (C1, C2):
        r, th = field(A, C)
        if gt:
            blend(A, np.full((h, w, 3), FACE), band_mask(r, -5, 101, 0.6))
        else:
            face = 9 + 7 * (1 - smooth(10, 100, r))
            blend(A, np.stack([face, face, face * 1.08], axis=-1), band_mask(r, -5, 101, 0.6))
        blend(A, np.full((h, w, 3), (196.0, 20.0, 28.0)), band_mask(r, 101.8, 104.6, 0.6))
        blend(A, np.full((h, w, 3), (8.0, 8.0, 9.0)), band_mask(r, 104.4, 108, 0.6))
        # the silver ring: bright where the light catches it, grey elsewhere
        s = 150 + 70 * np.cos(np.radians(th - 315)) ** 2 + 30 * np.cos(np.radians(th * 3))
        s = s * (0.78 + 0.22 * smooth(108, 113, r)) * (1 - 0.25 * smooth(113, 118, r))
        blend(A, np.stack([s, s, s * 1.02], axis=-1), band_mask(r, 108, 118, 0.7))

    def tick(C, r0, r1, deg, wd, col):
        A.line([polar(C, r0, deg), polar(C, r1, deg)], col, wd)

    # revs: 0-10, a tick every 250, red from 9
    for i in range(0, 41):
        v = i / 4
        big = i % 4 == 0
        col = (206, 34, 34) if v >= 9 else (INK if big else INK_DIM)
        tick(C1, 87 if big else 91, 100, rev(v), 2.4 if big else 1.6, col)
    for v in range(0, 11):
        p = polar(C1, 77 if v < 10 else 74, rev(v))
        A.text(p[0], p[1], str(v), DIG, 15.5, (222, 36, 36) if v >= 9 else INK)
    A.text(C1[0], 173.5, "1/min x 1000", ARIAL_B, 7.6, INK)

    # km/h: a tick every 10, the numbers as on the photo (two sizes)
    LABELS = (0, 20, 40, 60, 80, 100, 120, 140, 170, 200, 230, 260, 290, 320, 350)
    for v in range(0, 351, 10):
        big = v in LABELS
        tick(C2, 89 if big else 93, 100, kph(v), 2.4 if big else 1.4, INK if big else INK_DIM)
    for v in (30, 50):
        tick(C2, 84, 88, kph(v), 1.6, RED)
    for v in LABELS:
        small = v in (0, 40, 80, 120, 170, 230, 290, 350)
        size = 10.5 if small else 14
        hw, hh = len(str(v)) * size * 0.36, size * 0.36  # (half the label's width and height)
        th = math.radians(kph(v))
        p = polar(C2, 85 - hw * abs(math.sin(th)) - hh * abs(math.cos(th)), kph(v))
        A.text(p[0], p[1], str(v), DIG, size, INK)
    A.text(C2[0] - 6, 174.5, "km/h", ARIAL_B, 8.4, INK)

    # the dark screens low in each dial
    for C in (C1, C2):
        A.round_rect(C[0] - 34, 289, C[0] + 34, 323, 4, (13, 14, 16), outline=(46, 46, 50), w=0.8)
        top = np.clip((py - 289) / 3, 0, 1) * np.clip((293 - py) / 3, 0, 1) * (np.abs(px - C[0]) < 33)
        blend(A, np.full((h, w, 3), (30.0, 32.0, 36.0)), top)

    # the warning lamps, dark until they light (the owner's photo is the bulb check); on the GT's white faces an
    # unlit lamp doesn't show at all
    k = 0.13
    if not gt:
        amber = tuple(int(c * k) for c in (246, 140, 20))
        red = tuple(int(c * k) for c in (230, 30, 30))
        A.text(122, 207, "EPC", ARIAL_B, 8.2, amber)
        A.round_rect(186, 200, 199, 210, 1.5, None, outline=amber, w=1.2)
        A.line([(183, 205), (186, 205)], amber, 1.2)
        A.circle(133, 253, 3.4, None, outline=amber, w=1.1)
        A.line([(133, 245), (133, 249.6)], amber, 1.2)
        A.round_rect(173, 249, 184, 255, 2, None, outline=amber, w=1.1)
        A.line([(170, 259), (175, 257), (180, 259), (185, 257)], amber, 1.0)
        A.circle(479, 205, 2.4, red)
        A.line([(479, 208), (477, 214)], red, 2.0)
        A.line([(483, 208), (488, 212)], red, 1.6)
        A.round_rect(498, 190, 515, 199, 1.0, None, outline=red, w=1.1)
        A.circle(533, 186, 2.6, red)
        A.line([(533, 189), (533, 197)], red, 2.6)
        A.line([(529, 191), (538, 196)], red, 1.0)
        A.circle(565, 230, 6.2, None, outline=amber, w=1.2)
        A.text(565, 230.5, "ABS", ARIAL_B, 3.9, amber)
        A.circle(553, 206, 6.0, None, outline=red, w=1.2)
        A.round_rect(165, 186, 178, 193, 2, None, outline=amber, w=1.1)

    # the little hood at the top: water and fuel
    A.round_rect(250, 90, 430, 157, 14, (22, 22, 24), outline=(130, 132, 136), w=1.4)
    A.line([(262, 91.5), (418, 91.5)], (200, 202, 206), 1.0)
    T1, T2 = (291.3, 143.8), (390.0, 144.5)
    SMALL = (229, 229, 231) if gt else (12, 12, 13)  # the small gauges' faces
    for C in (T1, T2):
        A.circle(C[0], C[1], 30, SMALL)
    for i, deg in enumerate((-55, -28, 0, 28, 57)):
        tick(T1, 22, 30, deg, 1.6 if i % 2 == 0 else 1.0, (214, 30, 30) if i == 4 else INK)
        tick(T2, 22, 30, deg, 1.6 if i % 2 == 0 else 1.0, (214, 30, 30) if i == 0 else INK)
    A.text(272, 132, "50", ARIAL_B, 6.4, INK)
    A.text(291.5, 119.5, "90", ARIAL_B, 7.2, INK)
    A.text(310.5, 131.5, "130", ARIAL_B, 6.4, (220, 40, 40))
    A.text(270, 145, "°C", ARIAL_B, 6.0, INK)
    A.text(390, 119.5, "1/2", ARIAL_B, 7.0, INK)
    A.text(408.5, 132, "1/1", ARIAL_B, 6.4, INK)
    A.round_rect(364, 138, 370, 147, 0.8, None, outline=INK, w=0.9)
    A.line([(313, 139), (313, 146)], INK, 1.0)
    A.line([(309, 147), (317, 147)], INK, 1.0)
    # the water needle stays at 90 (the engine is always warm here)
    A.line([T1, polar(T1, 27, 2)], NEEDLE, 1.6)
    A.circle(T1[0], T1[1], 9.0, (34, 34, 36), outline=(196, 198, 202), w=1.4)

    # the screen in the middle
    A.round_rect(294.5, 185, 388, 315, 7, (34, 34, 36), outline=(70, 70, 74), w=1.0)
    A.round_rect(301, 195, 382.5, 310, 4, (14, 13, 12))
    glare = np.clip((py - 195) / 2, 0, 1) * np.clip((205 - py) / 10, 0, 1) * (px > 302) * (px < 381)
    blend(A, np.full((h, w, 3), (40.0, 36.0, 32.0)), glare)
    A.line([(306, 246), (377, 246)], (60, 58, 56), 0.8)
    A.line([(306, 285), (377, 285)], (60, 58, 56), 0.8)
    A.round_rect(232, 315, 450, 330, 4, (54, 54, 56))

    # oil (far left) and volts (far right), small round gauges at the ends of the pods
    O1, O2 = (6.0, 268.0), (672.0, 268.0)
    for C, s, word in ((O1, 1, "°C"), (O2, -1, "Volt")):
        A.circle(C[0], C[1], 27, SMALL)
        for j, deg in enumerate((40, 70, 100, 130)):
            tick(C, 19, 26, deg * s, 1.4 if j % 3 == 0 else 1.0, INK)
        A.text(C[0] - 4 * s, C[1] - 21, word, ARIAL_B, 6.2, INK)
        A.line([C, polar(C, 23, 85 * s)], NEEDLE, 1.6)
        A.circle(C[0], C[1], 7.5, (34, 34, 36), outline=(196, 198, 202), w=1.2)
    A.text(O1[0] + 18, O1[1] - 13, "150", ARIAL_B, 5.4, INK)
    A.text(O1[0] + 18, O1[1] + 14, "50", ARIAL_B, 5.4, INK)
    A.text(O2[0] - 18, O2[1] - 13, "16", ARIAL_B, 5.4, INK)
    A.text(O2[0] - 18, O2[1] + 14, "8", ARIAL_B, 5.4, INK)
    A.round_rect(O2[0] - 12, O2[1] + 20, O2[0] + 0, O2[1] + 27, 0.8, None, outline=INK, w=0.8)

    A.final = A.finish(A.S, blur=1.0, strength=0.25)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # the lamps that light: traction control off (the skid car), the brake lamp when standing
    AMB = (246, 140, 20)
    LBG = (229, 229, 231) if gt else (0, 0, 0)  # (on a white face the lit lamp is a piece of that face)
    L = Art(REF, box, S=4, bg=LBG)
    L.round_rect(165, 186, 178, 193, 2, None, outline=AMB, w=1.1)
    L.line([(163, 197), (168, 195), (173, 197), (178, 195)], AMB, 1.0)
    L.text(171.5, 201, "OFF", ARIAL_B, 4.2, AMB)
    L.final = L.finish(L.S, blur=1, strength=0.3)
    sp.add_show(sp.box(L, (158, 180, 186, 206), black=not gt), "tcoff")
    RD = (230, 30, 30)
    B = Art(REF, box, S=4, bg=LBG)
    B.circle(553, 206, 6.0, None, outline=RD, w=1.2)
    B.text(553, 206.5, "!", ARIAL_B, 8, RD)
    B.line([(545, 199), (543, 206), (545, 213)], RD, 1.0)
    B.line([(561, 199), (563, 206), (561, 213)], RD, 1.0)
    B.final = B.finish(B.S, blur=1, strength=0.3)
    sp.add_show(sp.box(B, (538, 195, 568, 217), black=not gt), "parked")

    # needles: long and white-silver, a dark hub with a bright rim
    WN = NEEDLE
    parts = [(-14, 0, 1.6, 1.9, WN), (0, 95, 1.9, 0.8, WN)]
    add_needle(sp, needle_sprite(sp, 96, 15, parts, hub=16.5, hub_col=(38, 38, 40), hub_line=(206, 208, 212)), C1[0], C1[1], "rpm", [(0, rev(0)), (10.5, rev(10.5))])
    add_needle(sp, needle_sprite(sp, 96, 15, parts, hub=16.5, hub_col=(38, 38, 40), hub_line=(206, 208, 212)), C2[0], C2[1], "kmh", SPD)
    fp = [(-4, 0, 1.0, 1.2, WN), (0, 27, 1.3, 0.6, WN)]
    add_needle(sp, needle_sprite(sp, 28, 5, fp, hub=9.0, hub_col=(34, 34, 36), hub_line=(196, 198, 202)), T2[0], T2[1], "fuel", [(0, -55), (1, 57)])

    # the middle screen: the gear, the speed, the mileage; the dial screens: the clock and the trip
    solid_gear(sp, DIG, 24, (236, 236, 238), 341.5, 224)
    sp.font("speed", DIG, 15, "0123456789", shear=0, track=0.4)
    sp.readout("speed", 341.5, 263, "m", 3, "speed", NUM)
    sp.font("unit", ARIAL_B, 7, "kmhpi/", shear=0)
    sp.readout("unit", 341.5, 277, "m", 4, "unit", DIM)
    sp.font("odo", DIG, 8.2, "0123456789.:", shear=0, track=0.3)
    sp.readout("odo", 336, 298, "m", 7, "odoTrim", NUM)
    sp.font("du", ARIAL_B, 6.2, "kmi", shear=0)
    sp.readout("du", 366, 298.5, "m", 2, "distUnit", DIM)
    sp.readout("odo", C1[0], 306, "m", 5, "clock", NUM)
    sp.readout("odo", C2[0] - 4, 306, "m", 6, "trip", NUM)
    sp.readout("du", C2[0] + 24, 306.5, "m", 2, "distUnit", DIM)
    return sp


def r8gt(Spec, needle_sprite, add_needle, glyph, solid_gear):
    """the Precision Type 42 V10 Lightweight (2011 R8 GT): the r8g1 cluster with the GT's white dials"""
    return r8g1(Spec, needle_sprite, add_needle, glyph, solid_gear, gt=True)


def r8g2(Spec, needle_sprite, add_needle, glyph, solid_gear):
    """the second Precision 4S (owner's photo imports/refs/audi_r8_gen2_cluster_owner.png); both 4S cars share it"""
    import math

    import numpy as np
    from PIL import Image

    from cluster_art import ARIAL_B, FONTDIR, Art
    from cluster_lfa_maybach import band_mask, blend, field, polar, smooth

    EXT = FONTDIR + "BuilderExtended-Bold.otf"  # the dial's numbers (wide, like the real screen's)
    EXT_R = FONTDIR + "BuilderExtended-Regular.otf"  # the big speed
    SANS_B = FONTDIR + "BuilderSans-Bold.otf"
    SANS = FONTDIR + "BuilderSans-Medium.otf"
    TXT = FONTDIR + "Arimo-Regular.ttf"
    TXT_B = FONTDIR + "Arimo-Bold.ttf"
    box = (35, 103, 631, 319)
    REF = "audi_r8_gen2_cluster_owner.png"
    A = Art(REF, box, S=4, bg=(5, 5, 7))
    sp = Spec("r8g2", box[2] - box[0], box[3] - box[1], 3.0, 3.3, box[0], box[1])
    sp.redline, sp.idle = 8.7, 0.9
    C = (333.0, 211.0)
    WHT = (238, 238, 240)
    GRY = (150, 152, 156)
    DIM = (88, 90, 94)
    RED = (226, 30, 38)
    ORANGE = (236, 150, 44)

    def rev(v):
        return -112.5 + 22.5 * v  # 1 at the left, 5 at the top, 9 at the right

    h, w = A.H * A.S, A.W * A.S
    yy, xx = np.mgrid[0:h, 0:w]
    px = (xx + 0.5) / A.S + A.ox
    py = (yy + 0.5) / A.S + A.oy

    # the screen: black, a faint lift towards the middle
    lift = 7 * np.exp(-(((px - C[0]) / 260) ** 2 + ((py - C[1]) / 120) ** 2))
    blend(A, np.stack([5 + lift, 5 + lift, 7 + lift], axis=-1), np.ones((h, w)))

    # thin frame lines: under the top line of each side panel, over the bottom line
    for x0, x1 in ((148, 262), (404, 520)):
        A.line([(x0, 147.5), (x1, 147.5)], (52, 52, 56), 0.9)

    # the rev counter: a dark grey ring band, a thin light outer ring, the black middle with its thin ring
    r, th = field(A, C)
    shade = 22 + 14 * (1 - smooth(130, 300, py)) + 8 * np.cos(np.radians(th)) ** 2
    blend(A, np.stack([shade, shade, shade * 1.05], axis=-1), band_mask(r, 41.5, 76.0, 0.6))
    ring = 150 + 50 * np.cos(np.radians(th - 330)) ** 2
    blend(A, np.stack([ring, ring, ring * 1.02], axis=-1), band_mask(r, 76.3, 77.7, 0.5))
    blend(A, np.full((h, w, 3), (3.0, 3.0, 5.0)), band_mask(r, -5, 40.6, 0.6))
    blend(A, np.full((h, w, 3), (96.0, 96.0, 100.0)), band_mask(r, 40.6, 41.6, 0.5))
    # the red zone: a red block behind 9 and 10, a bright red line round its outside
    a0, a1 = rev(8.6), rev(10.35)
    inz = ((th - a0) % 360 <= (a1 - a0)).astype(float)
    tone = 120 + 40 * smooth(52, 66, r)
    blend(A, np.stack([tone, tone * 0.1, tone * 0.14], axis=-1), band_mask(r, 50.5, 67.5, 0.6) * inz)
    a0b, a1b = rev(8.5), rev(10.7)
    inz2 = ((th - a0b) % 360 <= (a1b - a0b)).astype(float)
    blend(A, np.full((h, w, 3), (232.0, 34.0, 42.0)), band_mask(r, 68.6, 71.0, 0.5) * inz2)

    # ticks: every 250 a short grey one, every 1000 a longer white one
    for i in range(0, 43):
        v = i / 4
        big = i % 4 == 0
        col = (238, 60, 64) if v >= 9 else (WHT if big else (120, 122, 126))
        A.line([polar(C, 66.0 if big else 69.5, rev(v)), polar(C, 74.0, rev(v))], col, 1.5 if big else 0.9)
    for v in range(1, 11):
        p = polar(C, 57.0 if v < 10 else 55.5, rev(v))
        A.text(p[0] + (1.5 if v == 10 else 0), p[1], str(v), EXT, 18.5 if v < 10 else 16.5, WHT)
    A.text(C[0], 169.5, "1/min x 1000", TXT, 4.4, (110, 112, 116))
    # the dial is cut off at the bottom line: the info row runs under it on black
    A.rect(box[0], 262.6, box[2], box[3], (5, 5, 7))
    A.line([(118, 263), (548, 263)], (46, 46, 50), 0.9)

    # inside the middle: READY low on the left of the ring, the drive mode in red under the gear
    A.text(271, 240, "READY", TXT_B, 5.0, (190, 192, 196))
    A.text(C[0], 242.5, "DYNAMIC", TXT_B, 5.6, RED, track=0.4)

    # ---- the media panel (left): our own text
    def antenna(x, y, col):
        A.circle(x, y - 2.6, 1.6, None, outline=col, w=0.7)
        A.line([(x, y - 1.0), (x, y + 3.6)], col, 0.8)
        A.line([(x - 1.8, y + 3.6), (x + 1.8, y + 3.6)], col, 0.7)

    antenna(157, 138, GRY)
    A.text(163, 138, "001: Midnight", TXT, 7.0, (196, 198, 202), anchor="lm")
    A.circle(214, 138, 3.0, None, outline=GRY, w=0.7)  # the compass
    A.poly([(214, 135.0), (215.4, 138.6), (214, 138.0), (212.6, 138.6)], GRY)
    A.text(220, 138, "NE", TXT, 6.4, (196, 198, 202), anchor="lm")
    A.text(146, 153, "Radio", TXT_B, 8.6, ORANGE, anchor="lm")
    A.text(110, 177, "001", TXT_B, 9.0, WHT, anchor="lm")
    A.text(130, 177, "MIDNIGHT FM", TXT_B, 8.4, WHT, anchor="lm")
    A.text(110, 191, "Synthwave", TXT, 7.0, (176, 178, 182), anchor="lm")
    # mic and note icons, then the made-up artist and song
    A.round_rect(114.6, 200.5, 117.4, 205.5, 1.3, (150, 152, 156))
    A.line([(113.3, 204.5), (113.6, 206.4), (116, 207.4), (118.4, 206.4), (118.7, 204.5)], (150, 152, 156), 0.6)
    A.line([(116, 207.4), (116, 209.0)], (150, 152, 156), 0.6)
    A.text(126, 204.5, "The Hairpin Club", TXT, 7.0, (150, 152, 156), anchor="lm")
    A.circle(114.3, 218.2, 1.5, (190, 192, 196))
    A.circle(118.7, 217.2, 1.5, (190, 192, 196))
    A.line([(115.6, 218.0), (115.6, 211.6), (120.0, 210.6), (120.0, 217.0)], (190, 192, 196), 0.8)
    A.text(126, 215, "Midnight on the Corniche", TXT, 7.0, (190, 192, 196), anchor="lm")
    for x in (199, 211):  # the two small icons at the panel's right
        A.round_rect(x, 186, x + 8, 195, 1.2, None, outline=(110, 112, 116), w=0.7)
    A.line([(202, 189.5), (204.5, 189.5)], (110, 112, 116), 0.6)
    A.line([(214, 189.0), (216, 189.0), (216, 192.5)], (110, 112, 116), 0.6)

    # ---- the g-force circle (right)
    G = (485.0, 202.0)
    rg, _ = field(A, G)
    blend(A, np.full((h, w, 3), (12.0, 12.0, 14.0)), band_mask(rg, -5, 31.5, 0.6))
    for rad, col, wd in ((32.0, (206, 206, 210), 1.3), (21.5, (44, 44, 48), 0.8), (11.0, (40, 40, 44), 0.7)):
        A.circle(G[0], G[1], rad, None, outline=col, w=wd)
    A.line([(G[0] - 31, G[1]), (G[0] + 31, G[1])], (34, 34, 38), 0.6)
    A.line([(G[0], G[1] - 31), (G[0], G[1] + 31)], (34, 34, 38), 0.6)
    A.circle(G[0], G[1], 3.0, (232, 232, 236))
    for x, y in ((487, 161), (440, 203), (530, 203), (484.5, 244)):
        A.text(x, y, "0.0", TXT, 7.6, (204, 34, 42))

    # ---- the range (top right): fuel pump, the number (live), the unit (live), the small range icon
    def pump(x, y, col):
        A.round_rect(x - 2.4, y - 4.0, x + 1.6, y + 4.0, 0.6, None, outline=col, w=0.7)
        A.rect(x - 1.6, y - 3.0, x + 0.8, y - 0.8, col)
        A.line([(x + 1.6, y - 1.5), (x + 3.2, y - 0.5), (x + 3.2, y + 3.0)], col, 0.6)

    pump(434, 138, GRY)
    A.line([(474, 134), (478, 134), (473, 142), (477, 142)], (130, 132, 136), 0.8)

    # ---- far left: the water temperature bar (always warm here), far right: the fuel bar
    def bar(xs, ys, lit, col_on, col_off):
        n = len(ys) - 1
        for k in range(n):
            x0, x1 = xs[k], xs[k + 1]
            y0, y1 = ys[k] + 0.9, ys[k + 1] - 0.9
            A.line([(x0, y0), (x1, y1)], col_on if k >= n - lit else col_off, 2.0)

    ys = [200 + 4.8 * k for k in range(12)]
    bar([70.5 - 0.11 * (y - 200) for y in ys], ys, 6, (226, 226, 230), (44, 44, 48))
    A.line([(63.5, 200.5), (66.5, 200.5)], (200, 36, 40), 1.2)
    A.text(52, 214, "°C", TXT, 6.2, (196, 198, 202))
    A.text(58.5, 229, "90", TXT, 6.2, (196, 198, 202))
    A.text(56, 254.5, "50", TXT, 6.2, (196, 198, 202))
    A.line([(47, 238.5), (47, 245)], (170, 172, 176), 0.8)  # the thermometer
    A.circle(47, 246.2, 1.4, (170, 172, 176))
    A.line([(44, 247.5), (50, 247.5)], (170, 172, 176), 0.6)
    bar([586.0 + 0.11 * (y - 200) for y in ys], ys, 7, (226, 226, 230), (44, 44, 48))
    A.line([(591.5, 254.5), (595.0, 254.5)], (200, 36, 40), 1.2)
    A.text(589, 200.5, "1/1", TXT, 6.0, (196, 198, 202))
    A.text(595.5, 227.5, "1/2", TXT, 6.0, (196, 198, 202))
    pump(604, 243, (170, 172, 176))

    # ---- the bottom line: oil temperature, a small key, (the clock, live), the outside temperature, a ---
    A.line([(116, 265.5), (124, 265.5)], (220, 220, 224), 1.0)
    A.text(171, 273.5, "62°C", TXT_B, 7.4, (214, 216, 220), anchor="rm")
    A.line([(189.5, 272.5), (196, 276), (189.5, 278.5)], (150, 152, 156), 0.7)  # oil can (simple)
    A.round_rect(186, 274, 193, 279, 0.8, None, outline=(150, 152, 156), w=0.7)
    A.round_rect(269.5, 268.5, 274.5, 277.5, 1.2, None, outline=(170, 172, 176), w=0.7)  # the key
    A.line([(272, 271), (272, 274)], (170, 172, 176), 0.6)
    A.text(355, 273.5, "+16.5", TXT_B, 7.6, (214, 216, 220), anchor="lm")
    A.text(376, 273.5, "°C", TXT, 6.0, (190, 192, 196), anchor="lm")
    A.circle(472.5, 276, 3.6, None, outline=(196, 198, 202), w=0.8)
    A.line([(472.5, 273.6), (472.5, 276.6)], (196, 198, 202), 0.8)
    A.circle(472.5, 278.1, 0.45, (196, 198, 202))
    A.text(488, 274.5, "---", TXT_B, 7.0, (196, 198, 202), anchor="lm")
    A.text(500.5, 273.5, "°C", TXT, 6.0, (190, 192, 196), anchor="lm")

    A.final = A.finish(A.S, blur=1.0, strength=0.25)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # lamps: traction control off (amber, bottom left of the dial), the seat-belt lamp when standing (red)
    AMB = (246, 150, 30)
    L = Art(REF, box, S=4, bg=(0, 0, 0))
    L.round_rect(243, 268.5, 254, 274.5, 1.8, None, outline=AMB, w=0.9)
    L.line([(242, 277.6), (246, 276.4), (250, 277.6), (254, 276.4)], AMB, 0.8)
    L.text(248.5, 281.5, "OFF", ARIAL_B, 3.6, AMB)
    L.final = L.finish(L.S, blur=1, strength=0.3)
    sp.add_show(sp.box(L, (238, 264, 259, 285), black=True), "tcoff")
    B = Art(REF, box, S=4, bg=(0, 0, 0))
    B.circle(315.5, 266.8, 1.5, RED)
    B.line([(315.5, 268.6), (315.0, 273.5)], RED, 1.6)
    B.line([(313.2, 269.0), (317.6, 274.0)], RED, 0.9)
    B.line([(313.0, 274.6), (318.5, 274.6)], RED, 1.0)
    B.final = B.finish(B.S, blur=1, strength=0.3)
    sp.add_show(sp.box(B, (309, 262, 322, 278), black=True), "parked")

    # the rev needle: a red line across the ring band, the pivot in the middle of the dial
    parts = [(40.5, 75.5, 1.25, 1.0, (236, 40, 46))]
    add_needle(sp, needle_sprite(sp, 76, 2, parts), C[0], C[1], "rpm", [(0, rev(0)), (10.7, rev(10.7))])

    # the middle: km/h (live unit), the big speed (live), the gear (P standing, live)
    sp.font("unit", TXT, 6.2, "kmhpi/", shear=0)
    sp.readout("unit", C[0], 197.5, "m", 4, "unit", (200, 202, 206))
    sp.font("speed", EXT_R, 33, "0123456789", shear=0, track=0.8)
    sp.readout("speed", C[0], 212.5, "m", 3, "speed", WHT)
    solid_gear(sp, SANS, 15.0, (236, 236, 238), C[0], 232.5, stroke=0.1)
    # the range (live, with its unit) and the clock (live)
    sp.font("small", TXT_B, 7.6, "0123456789:", shear=0, track=0.15)
    sp.readout("small", 458, 138.5, "r", 3, "range", (200, 202, 206))
    sp.font("du", TXT, 5.6, "kmi", shear=0)
    sp.readout("du", 460, 139.5, "l", 2, "distUnit", (170, 172, 176))
    sp.font("clock", TXT_B, 8.6, "0123456789:", shear=0, track=0.2)
    sp.readout("clock", 295.5, 273.5, "m", 5, "clock", (220, 222, 226))
    return sp


def e60(Spec, needle_sprite, add_needle, glyph, solid_gear):
    """the Bavarica Werkz E60 V10 (the 2009 M5 model, 2026-11-09): KEEP, the model's own dial faces
    (tools/logo_paint/bnw_m5_e60_dials.png = its picture turned upright, the M logo painted out) made live, with what the
    model lacks drawn from the real photos (imports/refs/1_e60_m5_cluster_real.jpg, 6_e64_m6_cluster_real.jpg and the E64
    model's own photo): the two red segment screens between the dials (range above; the gear, odometer and trip below), the
    warm-up lights in the rev counter, the warning lamps and the turn arrows. Speedometer as modelled (US/UK print: mph
    outside, km/h inside, so it is right in either unit setting; the needle follows mph), rev counter 0-9 (red from 8,250),
    fuel (live) and oil in F (US print, drawn warm at 215 F). No maker's marks.
    Design pixels are 0.2 mm on the panel (1430 x 610 = the hood's opening, 286 x 122 mm, tools/lambo/window_e60.png)."""
    from cluster_art import FONTDIR

    DIG = FONTDIR + "zekton_rg.ttf"
    box = (0, 0, 1430, 610)
    REF = "model_clusters/1_e60_m5_img15_Gauges1_diff.png"
    A = Art(REF, box, S=3, bg=(18, 18, 20))
    sp = Spec("e60", 1430, 610, 1.0, 1.0, 0, 0)
    sp.redline, sp.idle = 8.25, 0.9
    # the dial centres measured on the model (UV-to-3D fit of its dial faces), and its picture's own centres and scales
    C1, C2 = (364.5, 333.5), (1066.0, 325.5)  # speedometer (driver's left), rev counter
    P1, P2 = (294.5, 291.4), (718.7, 713.8)
    K1, K2 = 0.796, 0.7795  # design px per picture px (0.1592 / 0.1559 mm a picture px)
    FUEL = (C1[0] + 0.5 * K1, C1[1] + 118.9 * K1)
    OIL = (C2[0] - 2.7 * K2, C2[1] + 139.6 * K2)
    RED = (226, 30, 24)
    LCD = (255, 70, 28)
    pic = Image.open(os.path.join(HERE, "..", "logo_paint", "bnw_m5_e60_dials.png")).convert("RGB")

    S = A.S
    h, w = A.H * S, A.W * S
    yy, xx = np.mgrid[0:h, 0:w]
    px = (xx + 0.5) / S
    py = (yy + 0.5) / S

    # the panel round the dials: near black, a touch lighter at the top
    tone = 22 - 8 * smooth(0, 610, py)
    blend(A, np.stack([tone, tone, tone * 1.06], axis=-1), np.ones((h, w)))

    def silver(th):
        return 150 + 60 * np.cos(np.radians(th - 320)) ** 2 + 25 * np.cos(np.radians(th * 3))

    # the dials: dark faces, the model's own print over them, its outer stripe as the ring's satin lip
    for C, P, k in ((C1, P1, K1), (C2, P2, K2)):
        r, th = field(A, C)
        face = 38 - 11 * smooth(40, 215, r)
        blend(A, np.stack([face, face, face * 1.05], axis=-1), band_mask(r, -5, 214, 0.8))
        # the chrome ring under the model's own (it stands proud in front of the panel): drawn too, in case an edge shows
        s = silver(th) * (1 - 0.3 * smooth(238, 252, r))
        blend(A, np.stack([s, s, s * 1.02], axis=-1), band_mask(r, 229, 252, 0.8))
        blend(A, np.full((h, w, 3), 10.0), band_mask(r, 252, 258, 0.8))
        # the picture, scaled onto the art
        half = 300
        crop = pic.crop((int(P[0] - half), int(P[1] - half), int(P[0] + half), int(P[1] + half)))
        size = round(2 * half * k * S)
        lay = np.asarray(crop.resize((size, size), Image.LANCZOS)).astype(float)
        x0 = round((C[0] - half * k) * S)
        y0 = round((C[1] - half * k) * S)
        ys, xs = slice(max(0, y0), min(h, y0 + size)), slice(max(0, x0), min(w, x0 + size))
        lay = lay[ys.start - y0: ys.stop - y0, xs.start - x0: xs.stop - x0]
        base = np.asarray(A.im).astype(float)
        reg = base[ys, xs]
        rr = r[ys, xs] / k  # radius in picture px
        tt = th[ys, xs]
        lum = lay.max(axis=2)
        sat = lay.max(axis=2) - lay.min(axis=2)
        inner = rr < 262
        printed = np.clip((lum - 30) / 200, 0, 1)[..., None] * inner[..., None]
        ink = np.where(sat[..., None] > 60, lay, np.array([238.0, 238.0, 240.0]))
        reg = reg * (1 - printed) + ink * printed
        band = (rr >= 262) & (rr < 294)
        col = sat > 60
        a = np.clip((lum - 40) / 160, 0, 1) * band
        sv = silver(tt) * 0.92
        lip = np.where(col[..., None], lay * 0.92, np.stack([sv, sv, sv * 1.02], axis=-1))
        reg = reg * (1 - a[..., None]) + lip * a[..., None]
        base[ys, xs] = reg
        A.im.paste(Image.fromarray(np.clip(base, 0, 255).astype("uint8")))

    def rev(v):
        return -132.35 + 29.31 * v

    # warm-up lights in the rev counter's scale (6,500-8,000, dark; they light while the car stands, a cold engine's limit)
    for i in range(6):
        a0, a1 = rev(6.5 + i * 0.25) + 0.9, rev(6.75 + i * 0.25) - 0.9
        pts = [polar(C2, 207, a0 + (a1 - a0) * t / 8) for t in range(9)] + [polar(C2, 213, a1 - (a1 - a0) * t / 8) for t in range(9)]
        A.poly(pts, (40, 26, 18))

    # the oil gauge's needle (drawn: the engine is always warm here) and the small caps
    A.line([OIL, polar(OIL, 104, 176.7)], RED, 3.4)
    A.line([OIL, polar(OIL, -14, 176.7)], RED, 3.4)
    A.circle(OIL[0], OIL[1], 21, (16, 16, 17), outline=(62, 62, 66), w=1.5)

    # the two segment screens between the dials (dark red glass)
    def lcd(x0, y0, x1, y1, rad):
        A.round_rect(x0 - 3, y0 - 3, x1 + 3, y1 + 3, rad + 2, (8, 8, 9))
        A.round_rect(x0, y0, x1, y1, rad, (40, 7, 5), outline=(70, 16, 10), w=1.4)
        m = np.clip((py - y0) / 3, 0, 1) * np.clip((y0 + 12 - py) / 9, 0, 1) * (px > x0 + 4) * (px < x1 - 4)
        blend(A, np.full((h, w, 3), (70.0, 22.0, 16.0)), m * 0.6)

    lcd(653, 352, 777, 437, 8)
    lcd(623, 452, 807, 582, 10)
    # the range screen's arrow and pump (lit, as on the photos)
    A.line([(668, 371), (690, 371)], LCD, 2.4)
    A.poly([(690, 364), (700, 371), (690, 378)], LCD)
    A.round_rect(708, 361, 721, 382, 1.5, None, outline=LCD, w=2.0)
    A.rect(710, 363, 719, 369, LCD)
    A.line([(721, 366), (727, 370), (727, 380), (724, 382)], LCD, 1.6)

    # warning lamps up the middle, dark until they light; the turn arrows at the ends, dark
    dim = lambda c, k=0.14: tuple(int(v * k) for v in c)  # noqa: E731
    AMB, RD = (246, 150, 20), (230, 36, 30)
    A.circle(715, 150, 15, None, outline=dim(RD), w=2.2)
    A.text(715, 151, "!", ARIAL_B, 20, dim(RD))
    A.line([(694, 136), (690, 150), (694, 164)], dim(RD), 2.0)
    A.line([(736, 136), (740, 150), (736, 164)], dim(RD), 2.0)
    A.round_rect(700, 196, 730, 214, 2, None, outline=dim(RD), w=2.0)
    A.text(708, 205, "-", ARIAL_B, 14, dim(RD))
    A.text(722, 205, "+", ARIAL_B, 14, dim(RD))
    A.circle(690, 252, 13, None, outline=dim(AMB), w=2.0)
    A.text(690, 252.5, "ABS", ARIAL_B, 9, dim(AMB))
    A.circle(740, 252, 13, None, outline=dim(AMB), w=2.0)
    A.text(740, 252.5, "!", ARIAL_B, 15, dim(AMB))
    A.round_rect(700, 290, 730, 310, 4, None, outline=dim(AMB), w=2.0)
    for x, s in ((42, 1), (1388, -1)):
        A.poly([(x - 16 * s, 330), (x - 2 * s, 316), (x - 2 * s, 324), (x + 16 * s, 324), (x + 16 * s, 336), (x - 2 * s, 336), (x - 2 * s, 344)], (52, 52, 55))

    A.final = A.finish(A.S, blur=1.2, strength=0.3)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # the lamps that light: the parking brake while standing; the warm-up lights while standing (the cold start look)
    L = Art(REF, box, S=3, bg=(0, 0, 0))
    L.circle(715, 150, 15, None, outline=RD, w=2.2)
    L.text(715, 151, "!", ARIAL_B, 20, RD)
    L.line([(694, 136), (690, 150), (694, 164)], RD, 2.0)
    L.line([(736, 136), (740, 150), (736, 164)], RD, 2.0)
    L.final = L.finish(L.S, blur=1.2, strength=0.5)
    sp.add_show(sp.box(L, (680, 128, 750, 172), black=True), "parked")
    W2 = Art(REF, box, S=3, bg=(0, 0, 0))
    for i in range(6):
        a0, a1 = rev(6.5 + i * 0.25) + 0.9, rev(6.75 + i * 0.25) - 0.9
        pts = [polar(C2, 207, a0 + (a1 - a0) * t / 8) for t in range(9)] + [polar(C2, 213, a1 - (a1 - a0) * t / 8) for t in range(9)]
        W2.gd.polygon([W2.q(*p) for p in pts], fill=(255, 120, 10))
        W2.poly(pts, (255, 150, 30))
    W2.final = W2.finish(W2.S, blur=1.5, strength=0.6)
    xs_ = [polar(C2, r_, rev(v))[0] for r_ in (200, 220) for v in (6.4, 8.1)]
    ys_ = [polar(C2, r_, rev(v))[1] for r_ in (200, 220) for v in (6.4, 8.1)]
    sp.add_show(sp.box(W2, (int(min(xs_)) - 6, int(min(ys_)) - 6, int(max(xs_)) + 6, int(max(ys_)) + 6), black=True), "parked")

    # needles: red, long, with the big black caps (the photos)
    big = [(-40, 0, 3.4, 3.8, RED), (0, 192, 3.8, 1.5, RED), (0, 150, 1.0, 0.5, (255, 120, 110))]
    SPD = [(0, -128.9), (10, -112.9), (20, -96.9), (30, -80.8), (40, -64.65), (50, -48.65), (60, -32.35), (70, -16.35), (80, 0.1),
           (90, 11.1), (100, 22.1), (110, 33.1), (120, 44.1), (130, 55.1), (140, 66.1), (150, 77.1), (160, 88.1), (170, 98.9),
           (180, 109.9), (190, 120.9), (200, 131.65), (215, 148.0)]
    add_needle(sp, needle_sprite(sp, 192, 40, big, hub=42, hub_col=(16, 16, 17), hub_line=(62, 62, 66)), C1[0], C1[1], "mph", SPD)
    add_needle(sp, needle_sprite(sp, 192, 40, big, hub=42, hub_col=(16, 16, 17), hub_line=(62, 62, 66)), C2[0], C2[1], "rpm", [(0, rev(0)), (9.3, rev(9.3))])
    small = [(-14, 0, 2.0, 2.2, RED), (0, 104, 2.2, 1.0, RED)]
    add_needle(sp, needle_sprite(sp, 104, 14, small, hub=21, hub_col=(16, 16, 17), hub_line=(62, 62, 66)), FUEL[0], FUEL[1], "fuel", [(0, 231), (0.5, 180), (1, 129)])

    # the screens' live text: range + unit above; the gear (N / R, or the gear with D as on the SMG), the odometer, the trip
    sp.font("lcd", DIG, 34, "0123456789", shear=0, track=1.0)
    sp.readout("lcd", 752, 404, "r", 3, "range", LCD)
    sp.font("lcds", DIG, 15, "0123456789.kmi", shear=0, track=0.6)
    sp.readout("lcds", 715, 426, "m", 2, "distUnit", LCD)
    sp.readout("lcds", 637, 566, "l", 6, "odo", LCD)
    sp.readout("lcds", 795, 566, "r", 5, "trip", LCD)
    sprites = {}
    fb = {"path": ARIAL_B, "size": 74, "chars": "", "stroke": 0.4, "shear": 0, "track": 0}
    fs = {"path": ARIAL_B, "size": 34, "chars": "", "stroke": 0.3, "shear": 0, "track": 0}

    def tint(im):
        c = Image.new("RGBA", im.size, LCD + (0,))
        c.putalpha(im.getchannel("A"))
        return c

    for ch in "RNP":
        sprites[ch] = {"im": tint(glyph(ch, fb, sp.A)[0])}
    D = tint(glyph("D", fb, sp.A)[0])
    for ch in "1234567":
        g = tint(glyph(ch, fs, sp.A)[0])
        Wc = 2 * (D.width + g.width)
        comp = Image.new("RGBA", (Wc, D.height), (0, 0, 0, 0))
        comp.alpha_composite(D, (Wc // 2 - D.width // 4, 0))
        comp.alpha_composite(g, (Wc // 2 - D.width // 4 - g.width - 2, D.height - g.height - round(D.height * 0.12)))
        sprites[ch] = {"im": comp}
    sp.gear = {"x": 715 - sp.ox, "y": 512 - sp.oy, "sprites": sprites}
    return sp


def bentayga(Spec, needle_sprite, add_needle, glyph, solid_gear):
    """the Sovereign Highlands (owner's photo imports/refs/bentayga_cluster_owner.webp)"""
    import math

    import numpy as np
    from PIL import Image

    from cluster_art import FONTDIR, Art
    from cluster_lfa_maybach import band_mask, blend, field, polar, smooth

    NUMF = FONTDIR + "Montserrat-Medium.ttf"  # the dials' numbers and the big speed (round, like the real screen's)
    NUMB = FONTDIR + "Montserrat-Bold.ttf"
    TXT = FONTDIR + "SourceSansPro-Regular.ttf"
    TXT_S = FONTDIR + "SourceSansPro-Semibold.ttf"
    TXT_B = FONTDIR + "SourceSansPro-Bold.ttf"
    box = (196, 292, 1796, 962)
    REF = "bentayga_cluster_owner.webp"
    A = Art(REF, box, S=2, bg=(7, 7, 9))
    sp = Spec("bentayga", box[2] - box[0], box[3] - box[1], 1.0, 1.25, box[0], box[1])
    sp.redline, sp.idle = 6.5, 0.75
    C1, C2 = (489.0, 668.0), (1501.0, 669.0)  # rev counter, speedometer
    T1, F1 = (480.0, 836.0), (1502.0, 822.0)  # coolant, fuel
    WHT = (240, 240, 242)
    GRY = (176, 178, 182)
    DIM = (120, 122, 126)
    ORG = (240, 112, 34)
    RED = (224, 36, 40)

    def rev(v):
        return -135 + 33.75 * v  # 0 at the lower left, 4 at the top, 8 at the lower right

    def kph(v):
        return -136 + 0.853 * v  # 0 at the lower left, 300 at the lower right

    def coolant(t):
        return (t - 90) * 2.33

    def fuel(f):
        return -137 + 274 * f

    h, w = A.H * A.S, A.W * A.S
    yy, xx = np.mgrid[0:h, 0:w]
    px = (xx + 0.5) / A.S + A.ox
    py = (yy + 0.5) / A.S + A.oy

    # ---- the black glass, the middle screen a shade lighter, its info band lighter still
    lift = 5 * np.exp(-(((px - 996) / 380) ** 2 + ((py - 560) / 200) ** 2))
    blend(A, np.stack([7 + lift, 8 + lift, 11 + lift * 1.3], axis=-1), np.ones((h, w)))
    A.round_rect(668, 352, 1324, 800, 26, (13, 15, 19))
    A.round_rect(760, 706, 1232, 796, 6, (22, 24, 28))
    A.line([(764, 705), (1228, 705)], (40, 42, 47), 1.0)

    def tick(C, r0, r1, deg, wd, col):
        A.line([polar(C, r0, deg), polar(C, r1, deg)], col, wd)

    def arc(C, r, a0, a1, col, wd, gaps=()):
        n = max(8, int(abs(a1 - a0) / 1.0))
        pts = []
        for i in range(n + 1):
            t = a0 + (a1 - a0) * i / n
            if any(g0 <= t <= g1 for g0, g1 in gaps):
                if len(pts) > 1:
                    A.line(pts, col, wd)
                pts = []
                continue
            pts.append(polar(C, r, t))
        if len(pts) > 1:
            A.line(pts, col, wd)

    # ---- the two dials: black faces, the chrome rings (bright where the light catches them)
    for C in (C1, C2):
        r, th = field(A, C)
        blend(A, np.full((h, w, 3), (5.0, 5.0, 6.0)), band_mask(r, -5, 266, 0.7))
        s = 150 + 80 * np.cos(np.radians(th - 320)) ** 2 + 25 * np.cos(np.radians(th * 2 + 40))
        s = s * (0.8 + 0.2 * smooth(268, 274, r)) * (1 - 0.3 * smooth(278, 285, r))
        blend(A, np.stack([s, s, s * 1.02], axis=-1), band_mask(r, 267.5, 285, 0.7))
        blend(A, np.full((h, w, 3), (20.0, 20.0, 22.0)), band_mask(r, 264, 267.5, 0.6))

    # ---- the rev counter: two scale lines, ticks, numbers 0-70, the orange top end, the inner arc
    rmaj = [rev(v) for v in range(0, 9)]
    arc(C1, 251, rev(0), rev(8), WHT, 2.2)
    arc(C1, 240, rev(0), rev(6.8), WHT, 1.6, gaps=[(t - 4.0, t + 4.0) for t in rmaj])
    arc(C1, 228, rev(6.8), rev(8.0), ORG, 2.6)
    A.line([polar(C1, 228, rev(6.8)), polar(C1, 240, rev(6.8))], ORG, 2.4)
    for i in range(0, 41):
        v = i / 5
        if i % 5 == 0:
            tick(C1, 231, 251, rev(v), 3.0, WHT)
        else:
            tick(C1, 230, 236, rev(v), 1.8, ORG if v > 6.8 else WHT)
    tick(C1, 226, 251, rev(8), 2.4, WHT)  # the end cap
    for v in range(0, 8):
        p = polar(C1, 212 if v not in (0, 7) else 206, rev(v))
        A.text(p[0], p[1], str(v * 10) if v else "0", NUMF, 41, WHT)
    arc(C1, 160, -129, 133, WHT, 2.0)
    A.text(639, 815, "rpm", TXT_S, 19, WHT)
    A.text(637, 833, "x100", TXT_S, 19, WHT)

    # ---- the speedometer: the same lines, numbers every 30 km/h, km/h, the inner arc
    arc(C2, 251, kph(0), kph(300) + 1.5, WHT, 2.2)
    smaj = [kph(v) for v in range(0, 301, 30)]
    arc(C2, 240, kph(0), kph(300) + 1.5, WHT, 1.6, gaps=[(t - 4.0, t + 4.0) for t in smaj])
    for v in range(0, 301, 10):
        if v % 30 == 0:
            tick(C2, 231, 251, kph(v), 3.0, WHT)
        else:
            tick(C2, 230, 236, kph(v), 1.8, WHT)
    tick(C2, 226, 251, kph(300) + 1.5, 2.4, WHT)
    for v in range(30, 301, 30):
        p = polar(C2, 208 if v < 270 else 204, kph(v))
        A.text(p[0], p[1], str(v), NUMF, 38, WHT)
    arc(C2, 160, -129, 133, WHT, 2.0)
    A.text(1656, 838, "km/h", TXT_S, 21, WHT)

    # ---- the coolant gauge (inside the rev counter, low): 30-150 C, the orange top, the needle at 90
    arc(T1, 80, coolant(30), coolant(150), WHT, 2.0)
    arc(T1, 73, coolant(132), coolant(150), ORG, 2.8)
    for t in range(30, 151, 10):
        big = t % 30 == 0
        tick(T1, 70 if big else 74, 80, coolant(t), 2.4 if big else 1.4, WHT)
    for t, s_ in ((60, "60"), (120, "120")):
        p = polar(T1, 55, coolant(t))
        A.text(p[0], p[1], s_, NUMF, 17, WHT)
    p = polar(T1, 92, coolant(90) + 9)
    A.text(p[0] + 4, p[1] + 14, "90", NUMF, 17, WHT)
    A.text(T1[0] - 35, T1[1] + 43, "30°C", NUMF, 16, WHT)
    A.text(T1[0] + 44, T1[1] + 40, "150", NUMF, 16, WHT)
    tx, ty = T1[0], T1[1] + 68  # the thermometer
    A.line([(tx, ty - 14), (tx, ty + 2)], WHT, 2.2)
    A.line([(tx - 9, ty + 6), (tx + 9, ty + 6)], WHT, 1.6)
    A.line([(tx - 7, ty + 10), (tx - 3, ty + 8), (tx + 1, ty + 10), (tx + 5, ty + 8), (tx + 8, ty + 10)], WHT, 1.2)
    A.line([(tx + 1, ty - 11), (tx + 6, ty - 11)], WHT, 1.2)
    A.line([(tx + 1, ty - 6), (tx + 6, ty - 6)], WHT, 1.2)
    # its needle (the engine is always warm here): orange with a white edge, the hub over it
    A.line([polar(T1, -12, coolant(88)), polar(T1, 76, coolant(88))], (250, 236, 226), 4.0)
    A.line([polar(T1, -10, coolant(88)), polar(T1, 74, coolant(88))], ORG, 2.2)
    A.circle(T1[0], T1[1], 14, (36, 36, 38), outline=(120, 122, 126), w=1.6)

    # ---- the fuel gauge (inside the speedometer, low): 0, 1/4, 1/2, 3/4, 1, the orange low end, the pump
    arc(F1, 80, fuel(0), fuel(1), WHT, 2.0)
    arc(F1, 73, fuel(0), fuel(0.1), ORG, 2.8)
    for i in range(0, 9):
        f = i / 8
        big = i % 2 == 0
        tick(F1, 70 if big else 74, 80, fuel(f), 2.4 if big else 1.4, WHT)
    for f, s_ in ((0.25, "1/4"), (0.75, "3/4")):
        p = polar(F1, 54, fuel(f))
        A.text(p[0], p[1], s_, NUMF, 16, WHT)
    p = polar(F1, 58, 0)
    A.text(p[0], p[1] + 2, "1/2", NUMF, 16, WHT)
    A.text(F1[0] - 40, F1[1] + 53, "0", NUMF, 16, WHT)
    A.text(F1[0] + 47, F1[1] + 53, "1", NUMF, 16, WHT)
    fx, fy = F1[0] - 4, F1[1] + 70  # the pump and its arrow
    A.round_rect(fx - 8, fy - 11, fx + 5, fy + 11, 2, None, outline=WHT, w=1.6)
    A.rect(fx - 5, fy - 8, fx + 2, fy - 2, WHT)
    A.line([(fx + 5, fy - 4), (fx + 9, fy - 1), (fx + 9, fy + 7)], WHT, 1.4)
    A.poly([(fx + 14, fy - 4), (fx + 20, fy), (fx + 14, fy + 4)], WHT)

    # ---- the middle screen's top row: the car (with its orange arc), the selected car tab, media, phone, globe, drive
    def car_side(x, y, s, col, wd=1.6):
        A.line([(x - 22 * s, y + 6 * s), (x - 21 * s, y - 1 * s), (x - 12 * s, y - 3 * s), (x - 6 * s, y - 9 * s), (x + 8 * s, y - 9 * s),
                (x + 16 * s, y - 3 * s), (x + 22 * s, y - 1 * s), (x + 22 * s, y + 6 * s), (x - 22 * s, y + 6 * s)], col, wd)
        for dx in (-12, 12):
            A.circle(x + dx * s, y + 6 * s, 3.6 * s, (13, 15, 19), outline=col, w=wd)

    arc((693, 426), 20, -160, -20, ORG, 2.4)
    car_side(707, 427, 1.0, WHT)
    A.round_rect(865, 403, 902, 440, 11, (226, 112, 32))
    A.round_rect(873, 417, 895, 430, 3, None, outline=(20, 14, 10), w=2.2)  # the front of a car, dark on orange
    A.line([(876, 417), (880, 410), (888, 410), (892, 417)], (20, 14, 10), 2.0)
    A.circle(878, 426, 1.8, (20, 14, 10))
    A.circle(890, 426, 1.8, (20, 14, 10))
    for x in (938, 993, 1048, 1103):
        A.circle(x, 422, 18, (30, 32, 36))
    A.circle(938, 422, 13, None, outline=WHT, w=2.0)
    A.poly([(933, 415), (945, 422), (933, 429)], WHT)
    A.line([(985, 428), (988, 431), (992, 430), (999, 423), (999, 419), (996, 416), (993, 418), (991, 422), (988, 422)], WHT, 2.0)  # the phone
    A.line([(998, 427), (1004, 433)], WHT, 1.6)
    A.line([(1004, 427), (998, 433)], WHT, 1.6)
    A.circle(1048, 422, 12, None, outline=WHT, w=1.6)  # the globe
    A.line([(1036, 422), (1060, 422)], WHT, 1.2)
    A.line([(1048, 410), (1048, 434)], WHT, 1.2)
    A.circle(1048, 422, 6, None, outline=WHT, w=1.2)
    for x0, x1 in ((1094, 1112),):  # the drive diagram: two axles and a shaft
        A.line([(x0, 410), (x1, 410)], WHT, 2.0)
        A.line([(x0, 434), (x1, 434)], WHT, 2.0)
        A.line([((x0 + x1) / 2, 410), ((x0 + x1) / 2, 434)], WHT, 2.0)
        for x in (x0, x1):
            A.rect(x - 3, 405, x + 3, 415, WHT)
            A.rect(x - 3, 429, x + 3, 439, WHT)
    A.text(990, 467, "Current speed", TXT, 27, WHT)
    A.rect(1178, 508, 1182, 692, (52, 54, 58))  # the list's scroll bar: a dim track, the bright thumb at its top
    A.round_rect(1177, 508, 1183, 548, 2, (246, 246, 248))

    # ---- the bottom lines: the pump (range), the start-stop-off mark, the outside temperature
    def pump(x, y, col):
        A.round_rect(x - 9, y - 12, x + 6, y + 12, 2, None, outline=col, w=1.8)
        A.rect(x - 6, y - 9, x + 3, y - 3, col)
        A.line([(x + 6, y - 6), (x + 11, y - 2), (x + 11, y + 8), (x + 8, y + 10)], col, 1.6)

    pump(811, 762, WHT)
    A.circle(1013, 762, 12, None, outline=GRY, w=2.0)  # start-stop off: an A in a ring, struck through
    A.text(1013, 763, "A", TXT_B, 18, GRY)
    A.line([(1001, 777), (1027, 747)], GRY, 2.0)
    A.text(1160, 763, "+31.5", NUMF, 30, WHT, anchor="rm")
    A.text(1177, 755, "°C", TXT_S, 18, WHT, anchor="mm")

    A.final = A.finish(A.S, blur=1.0, strength=0.2)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # the seat-belt lamp (red) while standing
    B = Art(REF, box, S=2, bg=(0, 0, 0))
    bx, by = 940, 762
    B.circle(bx, by - 13, 4.5, RED)
    B.poly([(bx - 7, by - 6), (bx + 7, by - 6), (bx + 9, by + 10), (bx + 3, by + 10), (bx, by + 4), (bx - 3, by + 10), (bx - 9, by + 10)], RED)
    B.line([(bx - 8, by - 6), (bx + 6, by + 9)], (90, 10, 12), 2.0)
    B.line([(bx - 12, by + 13), (bx + 12, by + 13)], RED, 2.0)
    B.final = B.finish(B.S, blur=1, strength=0.3)
    sp.add_show(sp.box(B, (924, 742, 956, 780), black=True), "parked")

    # needles: long, orange with a bright white edge, over a dark hub with a silver rim
    WN, ON = (252, 240, 230), (232, 96, 36)
    parts = [(-34, 0, 4.0, 4.4, WN), (0, 250, 4.4, 1.6, WN), (-32, 0, 2.4, 2.8, ON), (0, 246, 2.8, 0.8, ON)]
    hub = dict(hub=24, hub_col=(30, 30, 32), hub_line=(150, 152, 156))
    add_needle(sp, needle_sprite(sp, 252, 36, parts, **hub), C1[0], C1[1], "rpm", [(0, rev(0)), (8.0, rev(8.0))])
    add_needle(sp, needle_sprite(sp, 252, 36, parts, **hub), C2[0], C2[1], "kmh", [(0, kph(0)), (300, kph(300)), (310, kph(300) + 6)])
    fparts = [(-14, 0, 2.6, 3.0, WN), (0, 76, 3.0, 1.2, WN), (-12, 0, 1.5, 1.8, ON), (0, 73, 1.8, 0.6, ON)]
    add_needle(sp, needle_sprite(sp, 78, 16, fparts, hub=13, hub_col=(36, 36, 38), hub_line=(120, 122, 126)), F1[0], F1[1], "fuel", [(0, fuel(0)), (1, fuel(1))])

    # the middle: the big speed and its unit (live), the odometer, trip and range with their units, the gear
    sp.font("speed", NUMF, 86, "0123456789", shear=0, track=1.0)
    sp.readout("speed", 1037, 573, "r", 3, "speed", WHT)
    sp.font("unit", TXT, 25, "kmhpi/", shear=0)
    sp.readout("unit", 1043, 593, "l", 4, "unit", WHT)
    sp.font("small", NUMF, 27, "0123456789.", shear=0, track=0.3)
    sp.font("du", TXT_S, 18, "kmi", shear=0)
    sp.readout("small", 906, 727, "r", 7, "odoTrim", WHT)
    sp.readout("du", 910, 731, "l", 2, "distUnit", WHT)
    sp.readout("small", 1163, 727, "r", 7, "trip", WHT)
    sp.readout("du", 1167, 731, "l", 2, "distUnit", WHT)
    sp.readout("small", 884, 762, "r", 4, "range", WHT)
    sp.readout("du", 888, 766, "l", 2, "distUnit", WHT)
    solid_gear(sp, NUMB, 30, WHT, 982, 762, stroke=0.1)
    return sp


def gtr(Spec, needle_sprite, add_needle, glyph, solid_gear, nismo=False, ref=None, box=(0, 0, 694, 321)):
    """the Horizon R35 (2013 model's own cluster); nismo: the Track Edition (red rev counter band, grey rings).
    box: the panel in the reference picture's pixels (the 2017 model's cluster quad is a little taller and sits 5 px
    higher: (2, -5, 696, 308), registered on the five dials' middles, 0.6 px rms); outside the picture is its background"""
    import math
    import os

    import numpy as np
    from PIL import Image, ImageDraw, ImageFilter

    from cluster_art import FONTDIR, REFS

    TIT = FONTDIR + "TitilliumWeb-Regular.ttf"
    TIT_B = FONTDIR + "TitilliumWeb-Bold.ttf"
    REF = ref or os.path.join(REFS, "gtr_model_cluster.png")
    BX0, BY0, BX1, BY1 = box
    W, H, K = BX1 - BX0, BY1 - BY0, 4
    A, BG = 2.0, 2.6  # px a design px: the sprites (a needle sprite is twice its length tall and must fit a 1024 x 512
    # sheet: the rev needle is 2 x 126 x 2.0 = 504 px) and the background (1804 x 835, two halves of 902)
    sp = Spec("gtrte" if nismo else "gtr", W, H, A, BG, BX0, BY0)
    sp.redline, sp.idle = 7.1, 0.9

    FACE = np.array([25.0, 26.0, 25.0])
    HUB = np.array([18.0, 18.0, 18.0])
    WHITE = (247, 243, 247)
    KRED = (156, 24, 25)  # the km/h scale
    RED = (230, 40, 41)  # the needles
    AMBER = (255, 176, 64)  # the displays

    # the model's dials (measured on the picture: ring circles, needle hubs, printed needles)
    SC, TC, FC, WC = (118.1, 159.4), (341.36, 152.21), (551.46, 218.75), (656.18, 157.65)  # hubs
    TACH_C, TACH_R = (341.51, 151.33), 126.35  # the rev counter's face (inside its ring)
    TOP_C, TOP_R = (531.49, 97.54), 45.38  # the empty display top right
    SPD = [(0, 133.92), (20, 154.2), (40, 178.65), (60, 203.36), (80, 228.36), (100, 253.32), (120, 278.08), (140, 303.94),
           (160, 328.26), (180, 352.76), (200, 377.41), (220, 402.37)]  # mph -> degrees from up, as seen from the hub

    def rev(v):
        return 226.28 + 25.92 * v

    src0 = Image.open(REF).convert("RGB")
    assert src0.size == (694, 321), src0.size
    s0 = np.asarray(src0).astype(float)  # (glyphs are cut from it in its own pixels)
    src = Image.new("RGB", (W, H), tuple(int(v) for v in FACE))
    src.paste(src0, (-BX0, -BY0))
    # 1. the printed needles out, on the picture's own pixels (a strip a little wider than each needle, face colour)
    #    before it is enlarged, so no edge of them is left by the sharpening
    clean = np.asarray(src).astype(float).copy()
    ny, nx = np.mgrid[0:H, 0:W]
    nx, ny = nx + BX0, ny + BY0
    for c, deg, r0, r1, hw in ((SC, 324.27, -22, 103, 6.0), (TC, 22.53, -22, 126, 6.0), (FC, 277.98, -20, 60, 5.6)):
        t = math.radians(deg)
        ux, uy = math.sin(t), -math.cos(t)
        al = (nx + 0.5 - c[0]) * ux + (ny + 0.5 - c[1]) * uy
        ac = np.abs(-(nx + 0.5 - c[0]) * uy + (ny + 0.5 - c[1]) * ux)
        clean[(al >= r0) & (al <= r1) & (ac <= hw)] = FACE
    src = Image.fromarray(clean.astype("uint8"))
    big = src.resize((W * K, H * K), Image.LANCZOS).filter(ImageFilter.UnsharpMask(radius=2, percent=70, threshold=2))
    a = np.asarray(big).astype(float)
    yy, xx = np.mgrid[0 : H * K, 0 : W * K]
    px = (xx + 0.5) / K + BX0
    py = (yy + 0.5) / K + BY0

    def cover(mask, col, soft=None):
        nonlocal a
        m = mask.astype(float)[..., None] if soft is None else soft[..., None]
        a = a * (1 - m) + np.array(col, float) * m

    def disc(c, r):
        return np.clip(r - np.hypot(px - c[0], py - c[1]), 0, 1)  # (anti-aliased by a pixel of the 4x canvas / 4)

    def strip(c, deg, r0, r1, hw):
        t = math.radians(deg)
        ux, uy = math.sin(t), -math.cos(t)
        along = (px - c[0]) * ux + (py - c[1]) * uy
        across = np.abs(-(px - c[0]) * uy + (py - c[1]) * ux)
        return (along >= r0) & (along <= r1) & (across <= hw)

    # (the hubs back on top)
    for c in (SC, TC, FC):
        cover(None, HUB, soft=np.clip((16.2 - np.hypot(px - c[0], py - c[1])) * K / 2, 0, 1))

    # 2. what they covered, put back: copies of the model's own glyphs (upright, same print) and plain bars / dots
    def paste_glyph(box, at, scale=1.0, red=False):
        """a glyph cut from the source picture (box, design px) laid with its top-left at `at` (design px), as white
        (or, red: the km/h scale's red) coverage over what is there"""
        nonlocal a
        x0, y0, x1, y1 = box
        g = s0[y0:y1, x0:x1]
        if red:
            cov = np.clip((g[..., 0] - g[..., 1]) / (KRED[0] - KRED[1]), 0, 1)
        else:
            cov = np.clip((g.mean(axis=2) - FACE.mean()) / (np.mean(WHITE) - FACE.mean()), 0, 1)
        gi = Image.fromarray((cov * 255).astype("uint8")).resize((round((x1 - x0) * scale * K), round((y1 - y0) * scale * K)), Image.LANCZOS)
        gm = np.asarray(gi).astype(float) / 255
        X, Y = round((at[0] - BX0) * K), round((at[1] - BY0) * K)
        h, w = gm.shape
        sub = a[Y : Y + h, X : X + w]
        a[Y : Y + h, X : X + w] = sub * (1 - gm[..., None]) + np.array(KRED if red else WHITE, float) * gm[..., None]

    def bar(c, deg, r0, r1, w, col):
        cover(None, col, soft=strip(c, deg, r0, r1, w / 2).astype(float))

    # speedometer: the "160" (a "1" and a "0" from "100", a "6" from "60"), its tick, the "0" of the km/h "250" (from
    # "310"), the km/h dots
    cover((px > 61.5) & (px < 90.5) & (py > 92.5) & (py < 105.5), FACE)
    paste_glyph((34, 176, 40, 188), (64.0, 93.0))
    paste_glyph((78, 222, 88, 234), (70.0, 93.0))
    paste_glyph((41, 176, 50, 188), (80.0, 93.0))
    cover((px > 85.0) & (px < 91.0) & (py > 118.5) & (py < 127.0), FACE)
    paste_glyph((125, 108, 132, 116), (85.0, 119.0), red=True)
    bar(SC, 328.26, 89.5, 103.2, 4.0, WHITE)
    RC = (116.83, 159.67)  # (the dotted km/h ring: a dot every 8 degrees round the ring's middle)
    for deg in (315.6, 323.7, 331.8):
        cover(None, KRED, soft=disc((RC[0] + 37.25 * math.sin(math.radians(deg)), RC[1] - 37.25 * math.cos(math.radians(deg))), 1.05))
    # rev counter: the "6" (the speedometer's "6", 1.45x: the same print, bigger) and the 6000 tick
    paste_glyph((78, 222, 88, 234), (367.0, 61.0), 1.45)
    bar(TACH_C, rev(6), 108.0, 125.0, 4.1, WHITE)
    # fuel: the half tick and the pump sign by the hub
    bar(FC, 270.7, 52.5, 66.5, 3.2, WHITE)
    d = Image.new("L", (W * K, H * K), 0)
    dr = ImageDraw.Draw(d)
    q = lambda x, y: (x * K, y * K)  # noqa: E731
    dr.rectangle([q(508.6, 214.6), q(514.0, 222.6)], fill=255)
    dr.rectangle([q(509.6, 215.6), q(513.0, 218.0)], fill=0)
    dr.line([q(514.0, 216.4), q(516.6, 217.6), q(516.6, 221.4), q(517.8, 221.4)], fill=255, width=K)
    cover(None, WHITE, soft=np.asarray(d.filter(ImageFilter.GaussianBlur(K * 0.3))).astype(float) / 255)

    # 3. the Track Edition: grey rings (its model's own), the red band on the rev counter round its display corner
    if nismo:
        lum = a.mean(axis=2)
        pale = (a[..., 2] - a[..., 0] > 6) & (lum > 60)
        k = np.clip((lum - FACE.mean()) / (205 - FACE.mean()), 0, 1)[..., None]
        grey = FACE + (np.array([103.0, 103.0, 103.0]) - FACE) * k
        a = np.where(pale[..., None], grey, a)
        r = np.hypot(px - TACH_C[0], py - TACH_C[1])
        th = np.degrees(np.arctan2(px - TACH_C[0], -(py - TACH_C[1]))) % 360
        band = (np.clip(r - 74.2, 0, 1) * np.clip(118.4 - r, 0, 1)) > 0
        corner = (py > TACH_C[1] + 16.5) & (th > 90) & (th < 206.0)  # the display corner stays dark
        band &= ~corner
        soft = np.asarray(Image.fromarray((band * 255).astype("uint8")).filter(ImageFilter.GaussianBlur(K * 0.35))).astype(float) / 255
        # the print over the face (white ticks and numbers) stays on top of the band: a = face + white * cov
        cov = np.clip((a.mean(axis=2) - FACE.mean()) / (np.mean(WHITE) - FACE.mean()), 0, 1)
        whiteish = (np.abs(a[..., 0] - a[..., 1]) < 30)  # (the red 7-8 ticks lie outside the band)
        cov = np.where(whiteish, cov, 0.0)[..., None]
        BAND = np.array([190.0, 22.0, 22.0])
        on = BAND * (1 - cov) + np.array(WHITE, float) * cov
        a = a * (1 - soft[..., None]) + on * soft[..., None]

    img = Image.fromarray(np.clip(a, 0, 255).astype("uint8"))
    sp.bg = img.resize((round(W * BG), round(H * BG)), Image.LANCZOS)

    # 4. live: needles (thin red bars through the hub, as printed), the gear, the speed, the mileage
    def needle(length, tail, w0, w1):
        return needle_sprite(sp, length, tail, [(-tail, 0, w0, w0, RED), (0, length, w0, w1, RED)])

    add_needle(sp, needle(99.5, 17.0, 2.3, 1.6), SC[0], SC[1], "mph", SPD)
    add_needle(sp, needle(124.0, 17.0, 2.4, 1.6), TC[0], TC[1], "rpm", [(0, rev(0)), (8.6, rev(8.6))])
    add_needle(sp, needle(56.0, 15.0, 2.3, 1.7), FC[0], FC[1], "fuel", [(0, 238.5), (0.5, 270.7), (1, 306.8)])
    solid_gear(sp, TIT_B, 34, AMBER, 409.0, 207.0, stroke=0.2)
    sp.font("speed", TIT_B, 27, "0123456789", shear=0, track=0.3)
    sp.readout("speed", TOP_C[0], TOP_C[1] - 5.0, "m", 3, "speed", AMBER)
    sp.font("unit", TIT_B, 9.5, "kmhpi/", shear=0)
    sp.readout("unit", TOP_C[0], TOP_C[1] + 18.5, "m", 4, "unit", AMBER)
    sp.font("odo", TIT_B, 10, "0123456789", shear=0, track=0.4)
    sp.readout("odo", 404.0, 244.0, "m", 7, "odoTrim", AMBER)
    sp.font("du", TIT_B, 9, "kmi", shear=0)
    sp.readout("du", 435.0, 244.5, "m", 2, "distUnit", AMBER)
    return sp


def gtrte(Spec, needle_sprite, add_needle, glyph, solid_gear, ref=None):
    """the Horizon R35 Track Edition (2017 track model): the same cluster, its red rev counter band and grey rings, on
    its own model's quad (a little taller)"""
    return gtr(Spec, needle_sprite, add_needle, glyph, solid_gear, nismo=True, ref=ref, box=(2, -5, 696, 308))


def f82(Spec, needle_sprite, add_needle, glyph, solid_gear):
    """the F82 (`bnw_m4_f82`), redrawn 1:1 from the owner's photo (imports/refs/f82_m4_cluster_owner.png, lit, 2026-11-10;
    the photo is small, so everything is drawn fresh at 2-3 picture pixels a photo pixel): the speedometer 0-330 km/h and
    the rev counter 0-8 (READY and OFF under the 1), each a dark grey scale band under a white arc with its marks hanging
    from it, a lighter middle with a glow round the black hub, the bottom cut away in black; the photo's lit warm-up
    segments 7-8.5 by the rev counter's arc (yellow, orange, red: drawn as on the photo); the small fuel gauge far left
    (0 - 1/2 - 1, live) and the oil gauge far right (70-120-170 C, its needle drawn where the photo has it); the two amber
    marks between the dials; red needles (live: km/h as printed, revs). The screen between: the speed and unit (live, the
    player's unit), the gear (P standing: the game's N; R; "1 D" ... "7 D" as the photo's "1 D"), the shift-program bars
    and the drive-mode circle, the consumption arc with its blue bar (its maker's word replaced by a plain "Efficiency"),
    the date, km (live unit), the odometer and the trip (live). Lamps: the parking lights (green, with the lights), the
    amber warning triangle (standing, as on the photo), traction control off (amber) and the belt lamp (red, standing)
    in the blank under the speedometer. No M logo (its spot stays blank) and no M in the drive-mode circle.
    Coordinates are pixels of the photo; the box is the 2018 model's own cluster face laid on the photo so the photo's
    dial hubs sit on the model's (2026-11-12; wider than the photo: the 38 / 32 px beyond its sides are drawn housing)."""
    box = (-38, 7, 659, 271)  # the 2018 model's own cluster face, 354.6 x 134.3 mm, 0.5089 mm a photo px (measured 2026-11-12)
    REF = "f82_m4_cluster_owner.png"
    A = Art(REF, box, S=6, bg=(6, 6, 7))
    sp = Spec("f82", box[2] - box[0], box[3] - box[1], 3.0, 1.93, box[0], box[1])  # bg 1345 x 510
    sp.redline, sp.idle = 7.6, 0.9
    C1, C2 = (186.8, 131.0), (436.5, 131.5)  # speedometer, rev counter hubs
    HF, RF = (49.2, 203.3), (47.0, 189.5)  # fuel: needle hub, ring centre
    HO, RO = (570.0, 199.2), (572.6, 186.8)  # oil: needle hub, ring centre
    WHT = (246, 243, 241)
    GRY = (150, 150, 154)
    RED = (238, 38, 28)
    AMB = (246, 182, 40)
    BLUE = (90, 170, 235)
    S = A.S

    def spd(v):
        return (v - 165.0) * 0.7383

    def rev(v):
        return (v - 4.0) * 26.65 + 0.5

    base = np.asarray(A.im).astype(np.float32)

    def region(C, R):
        x0, x1 = max(0, int((C[0] - R - A.ox) * S)), min(A.W * S, int((C[0] + R - A.ox) * S) + 2)
        y0, y1 = max(0, int((C[1] - R - A.oy) * S)), min(A.H * S, int((C[1] + R - A.oy) * S) + 2)
        yy, xx = np.mgrid[y0:y1, x0:x1]
        px = (xx + 0.5) / S + A.ox - C[0]
        py = (yy + 0.5) / S + A.oy - C[1]
        return (slice(y0, y1), slice(x0, x1)), np.hypot(px, py), np.degrees(np.arctan2(px, -py)) % 360, px, py

    def put(sl, rgb, a):
        a = np.clip(a, 0, 1)[..., None]
        base[sl] = base[sl] * (1 - a) + np.asarray(rgb, np.float32) * a

    def poly_mask(sl, pts):
        m = Image.new("L", (sl[1].stop - sl[1].start, sl[0].stop - sl[0].start), 0)
        ImageDraw.Draw(m).polygon([((x - A.ox) * S - sl[1].start, (y - A.oy) * S - sl[0].start) for x, y in pts], fill=255)
        return np.asarray(m.filter(ImageFilter.GaussianBlur(0.6))).astype(np.float32) / 255

    # ---- the two big dials: bezel, scale band, the lighter middle with its glow, the black cut-away at the bottom
    for C, band_col, mid_top, mid_low, ycut, cut in (
            (C1, (20, 20, 24), 15.0, 34.0, 196.0, [(165.0, 163.3), (213.8, 163.3), (256.0, 195.0), (276.0, 240.0), (106.0, 240.0), (126.0, 195.0)]),
            (C2, (30, 27, 30), 34.0, 46.0, 201.0, [(398.8, 162.0), (457.5, 162.0), (499.0, 196.0), (520.0, 240.0), (372.0, 240.0), (386.0, 195.0)])):
        sl, r, th, px, py = region(C, 108)
        # the bezel: a grey ring, lighter at the top left
        tone = 44 + 22 * np.cos(np.radians(th - 320)) ** 2
        lower = np.clip((py - 50) / 8, 0, 1)
        put(sl, np.stack([tone, tone, tone * 1.05], -1), band_mask(r, 97.0, 103.0, 0.4) * (1 - lower))
        put(sl, (14, 14, 16), band_mask(r, -5, 97.0, 0.4) * (1 - lower))
        # the scale band and the middle (under the arc; the bottom part is cut away below, nothing under ycut)
        yl = np.clip((ycut - (py + C[1])) / 0.6 + 0.5, 0, 1)
        put(sl, band_col, band_mask(r, -5, 88.6, 0.4) * yl)
        t = np.clip((py + 52) / 104, 0, 1)
        mid = mid_top + (mid_low - mid_top) * t
        put(sl, np.stack([mid, mid * 0.97, mid * 1.04], -1), band_mask(r, -5, 52.0, 0.4))
        glow = np.exp(-np.clip(r - 15.5, 0, None) / 7.0) * 120
        put(sl, (210, 206, 212), np.clip(glow / 255, 0, 1) * band_mask(r, 15.0, 60.0, 0.3))
        put(sl, (2, 2, 2), poly_mask(sl, cut))
        # the bezel's straight ends down to the housing at both sides of the cut-away
        for s in (-1, 1):
            p0 = polar(C, 100.0, s * 126.0)
            pts = [p0, (p0[0] + s * 3.0, p0[1]), (C[0] + s * 74.0 + s * 3.0, C[1] + 66.0), (C[0] + s * 74.0, C[1] + 66.0)]
            put(sl, (52, 52, 56), poly_mask(sl, pts))
    # the small gauges: a silver ring, a dark face with the glow round the hub
    for H, Rc in ((HF, RF), (HO, RO)):
        sl, r, th, px, py = region(Rc, 46)
        put(sl, (4, 4, 5), band_mask(r, -5, 44.5, 0.4))
        tone = 120 + 70 * np.cos(np.radians(th - 300)) ** 2
        put(sl, np.stack([tone, tone, tone * 1.04], -1), band_mask(r, 38.2, 41.6, 0.4))
        put(sl, (24, 22, 25), band_mask(r, -5, 38.0, 0.4))
        slh, rh, _, _, _ = region(H, 40)
        g = np.exp(-np.clip(rh - 10.0, 0, None) / 6.0) * 150
        put(slh, (220, 216, 222), np.clip(g / 255, 0, 1) * band_mask(rh, 9.5, 38, 0.3))
    A.im.paste(Image.fromarray(np.clip(base, 0, 255).astype("uint8")))

    def arc(C, r, a0, a1, col, w):
        n = max(2, int(abs(a1 - a0) / 1.5))
        A.line([polar(C, r, a0 + (a1 - a0) * k / n) for k in range(n + 1)], col, w)

    def tick(C, r0, r1, deg, w, col):
        A.line([polar(C, r0, deg), polar(C, r1, deg)], col, w)

    # ---- speedometer: the white arc, marks every 10, the numbers every 30
    arc(C1, 88.0, spd(0), spd(330), WHT, 1.1)
    for v in range(0, 331, 10):
        if v % 30 == 0:
            tick(C1, 79.5, 88.0, spd(v), 1.7, WHT)
        else:
            tick(C1, 84.0, 88.0, spd(v), 1.0, (210, 208, 206))
    NUM1 = {0: (126.0, 165.5), 30: (121.5, 143.0), 60: (121.5, 118.0), 90: (131.5, 95.5), 120: (150.0, 78.0), 150: (173.5, 66.0),
            180: (200.5, 66.0), 210: (223.0, 77.0), 240: (239.5, 94.0), 270: (250.0, 116.0), 300: (251.0, 142.0), 330: (243.0, 165.0)}
    for v, (x, y) in NUM1.items():
        A.text(x, y, str(v), ARIAL_B, 13.6, WHT, scale_x=0.95)
    A.text(187.0, 104.5, "km/h", ARIAL_B, 7.6, (226, 224, 222), scale_x=0.95)

    # ---- rev counter: the arc to 7, the warm-up segments beyond, marks every 500, READY / OFF under the 1
    arc(C2, 88.0, rev(-0.85), rev(7.0) - 1.2, WHT, 1.1)
    for i in range(0, 15):
        v = i / 2
        tick(C2, 79.5 if i % 2 == 0 else 84.0, 88.0, rev(v), 1.7 if i % 2 == 0 else 1.0, WHT if i % 2 == 0 else (210, 208, 206))
    tick(C2, 80.5, 88.0, rev(7.0), 1.7, WHT)
    tick(C2, 80.5, 87.0, rev(8.0), 1.7, WHT)
    tick(C2, 83.5, 87.0, rev(7.5), 1.0, (210, 208, 206))
    for deg in (rev(-0.85), rev(-0.4)):  # the bracket ends by READY and OFF
        tick(C2, 82.0, 88.0, deg, 1.4, WHT)
    NUM2 = {1: (366.0, 118.0), 2: (380.5, 89.0), 3: (406.5, 70.5), 4: (437.0, 64.5), 5: (468.5, 74.0), 6: (490.5, 92.0), 7: (502.5, 121.0), 8: (501.0, 150.5)}
    for v, (x, y) in NUM2.items():
        A.text(x, y, str(v), ARIAL_B, 17.4, WHT, scale_x=0.95)
    A.text(437.0, 104.0, "1/min x 1000", ARIAL_B, 7.4, (226, 224, 222), scale_x=0.95)
    A.text(371.5, 146.0, "READY", ARIAL_B, 8.2, (222, 220, 218), scale_x=0.95)
    A.text(378.0, 167.0, "OFF", ARIAL_B, 8.2, (222, 220, 218), scale_x=0.95)
    for a0, a1, col, glow in ((80.5, 85.4, (250, 226, 34), (110, 90, 10)), (86.0, 91.0, (250, 226, 34), (110, 90, 10)),
                              (92.4, 98.4, (250, 120, 38), (110, 40, 8)), (99.0, 105.0, (250, 110, 34), (110, 36, 8)),
                              (106.6, 111.2, (240, 42, 30), (100, 14, 8)), (111.8, 116.2, (240, 42, 30), (100, 14, 8)),
                              (116.8, 120.8, (240, 42, 30), (100, 14, 8))):
        n = 6
        pts = [polar(C2, 92.0, a0 + (a1 - a0) * k / n) for k in range(n + 1)] + [polar(C2, 86.2, a1 - (a1 - a0) * k / n) for k in range(n + 1)]
        A.poly(pts, col)
        A.gd.polygon([A.q(*p) for p in pts], fill=glow)

    # ---- the hubs (drawn; the needles turn over them in the game, their caps are part of the needle pictures)
    for C in (C1, C2):
        A.circle(C[0], C[1], 15.2, (2, 2, 3), outline=(70, 70, 76), w=0.6)

    # ---- the small fuel gauge: marks on the ring's arc pointing at the low hub, 0 - 1/2 - 1, the pump
    def sub_mark(H, Rc, Rr, alpha, length, w, col):
        # the point where the hub's ray at angle alpha meets the circle (Rc, Rr), and a mark from there towards the hub
        ux, uy = math.sin(math.radians(alpha)), -math.cos(math.radians(alpha))
        dx, dy = H[0] - Rc[0], H[1] - Rc[1]
        b = dx * ux + dy * uy
        t = -b + math.sqrt(max(0.0, b * b - (dx * dx + dy * dy - Rr * Rr)))
        p = (H[0] + ux * t, H[1] + uy * t)
        A.line([p, (p[0] - ux * length, p[1] - uy * length)], col, w)
        return p

    FU = [(0, -45.5), (0.5, 0.0), (1, 46.0)]

    def fang(f):
        return -45.5 + 91.5 * f if f <= 0.5 else 0.0 + 92.0 * (f - 0.5)

    pts = [sub_mark(HF, RF, 35.6, fang(k / 32), 0, 1, WHT) for k in range(33)]
    A.line(pts, WHT, 0.9)
    for k in range(9):
        f = k / 8
        major = k % 4 == 0
        sub_mark(HF, RF, 35.6, fang(f), 4.6 if major else (3.4 if k % 2 == 0 else 2.2), 1.5 if major else 1.0, WHT)
    A.text(25.8, 181.7, "0", ARIAL_B, 11.2, WHT, scale_x=0.95)
    A.text(50.0, 166.7, "1/2", ARIAL_B, 11.2, WHT, scale_x=0.92)
    A.text(72.5, 181.7, "1", ARIAL_B, 11.2, WHT, scale_x=0.95)
    A.round_rect(24.0, 194.0, 31.0, 204.5, 0.8, (226, 224, 222))
    A.rect(25.2, 195.4, 29.8, 198.6, (30, 28, 30))
    A.rect(23.0, 203.6, 32.0, 205.0, (226, 224, 222))
    A.line([(31.0, 196.0), (33.0, 197.5), (33.0, 202.5)], (226, 224, 222), 0.8)
    A.circle(HF[0], HF[1], 10.2, (2, 2, 3), outline=(80, 80, 86), w=0.5)

    # ---- the small oil gauge: 70 - 120 - 170 C, the oil can; its needle where the photo has it (about 105 C)
    def oang(c):
        return -45.0 + 45.0 * (c - 70) / 50

    pts = [sub_mark(HO, RO, 35.4, oang(70 + 100 * k / 32), 0, 1, WHT) for k in range(33)]
    A.line(pts, WHT, 0.9)
    for k in range(9):
        c = 70 + 12.5 * k
        major = k % 4 == 0
        sub_mark(HO, RO, 35.4, oang(c), 4.6 if major else (3.4 if k % 2 == 0 else 2.2), 1.5 if major else 1.0, WHT)
    A.text(553.3, 180.3, "70", ARIAL_B, 11.2, WHT, scale_x=0.95)
    A.text(573.3, 165.0, "120", ARIAL_B, 11.2, WHT, scale_x=0.92)
    A.text(590.5, 180.3, "170", ARIAL_B, 11.2, WHT, scale_x=0.92)
    A.text(571.5, 180.0, "°C", ARIAL_B, 8.6, WHT, scale_x=0.9)
    A.line([(586.0, 197.5), (589.0, 199.5), (591.0, 203.5), (599.0, 203.5), (603.0, 199.0)], (226, 224, 222), 1.0)
    A.line([(591.0, 203.5), (590.5, 199.5), (598.0, 199.5), (599.0, 203.5)], (226, 224, 222), 1.0)
    A.line([(594.0, 199.5), (594.0, 193.0)], (226, 224, 222), 1.0)
    A.line([(592.0, 193.0), (596.0, 193.0)], (226, 224, 222), 0.8)
    for k, y in enumerate((195.0, 197.0)):
        A.line([(594.0, y), (596.5, y)], (226, 224, 222), 0.6)
    a_oil = oang(105.0)
    A.circle(HO[0], HO[1], 10.2, (2, 2, 3), outline=(80, 80, 86), w=0.5)
    A.line([polar(HO, -13.0, a_oil), polar(HO, 36.0, a_oil)], RED, 2.0)
    A.line([polar(HO, -10.0, a_oil), polar(HO, 33.0, a_oil)], (252, 150, 80), 0.6)

    # ---- the two amber marks between the dials (lit on the photo)
    for s in (-1, 1):
        x0 = 310.0 + s * 29.0
        for (ya, yb) in ((84.5, 77.5), (76.0, 68.0), (66.5, 59.5)):
            p = (x0 + s * (84.5 - ya) * -0.68, ya)
            q = (x0 + s * (84.5 - yb) * -0.68, yb)
            A.line([p, q], AMB, 2.0, glow=(120, 80, 10), gw=4.0)

    # ---- the screen between the dials
    # the consumption arc: a large arc under the rev counter, its blue bar on the left, 0 - 10 - 20 l/100km
    EC, ER = (433.0, 85.5), 139.0

    def ec(x):
        return math.degrees(math.asin((x - EC[0]) / ER)) + 180.0

    A.line([polar(EC, ER, 180 - (ec(x) - 180)) for x in np.linspace(394, 496, 30)], (200, 204, 186), 1.0)
    A.line([polar(EC, ER + 0.6, 180 - (ec(x) - 180)) for x in np.linspace(349, 395, 16)], BLUE, 2.4)
    A.round_rect(366.6, 198.6, 374.6, 206.6, 1.0, (6, 6, 7), outline=BLUE, w=0.8)  # (the bar's own icon)
    A.line([(368.6, 202.6), (372.6, 202.6)], BLUE, 0.8)
    for x, lab in ((395.0, "0"), (433.0, "10"), (472.0, "20")):
        d = 180 - (ec(x) - 180)
        A.line([polar(EC, ER - 3.5, d), polar(EC, ER + 1.0, d)], (210, 210, 206), 1.0)
        p = polar(EC, ER + 8.0, d)
        A.text(p[0], p[1], lab, ARIAL_B, 7.6, (210, 210, 206))
    A.text(488.0, 207.0, "l/100km", ARIAL_B, 6.0, (210, 210, 206), rot=-62)
    fo = font(ARIAL_B, 70)
    x = 354.5
    for ch in "Efficiency":
        w = fo.getlength(ch) / 10 + 0.35
        d = 180 - (ec(x + w / 2) - 180)
        p = polar(EC, ER + 5.8, d)
        A.text(p[0], p[1], ch, ARIAL_B, 7.0, BLUE, rot=d - 180, anchor="mm")
        x += w * math.cos(math.radians(d - 180))
    # the shift-program bars and the drive-mode circle (no maker's M)
    for k in range(3):
        A.poly([(447.0 + k * 3.6, 207.0), (449.4 + k * 3.6, 207.0), (453.0 + k * 3.6, 194.0), (450.6 + k * 3.6, 194.0)], (214, 226, 200))
    A.line([(446.0, 209.0), (458.0, 209.0)], (214, 226, 200), 0.9)
    A.circle(470.0, 198.8, 5.6, None, outline=(180, 180, 176), w=0.8)
    A.text(470.0, 199.0, "1", ARIAL_B, 7.0, (200, 200, 196))
    # the line over the odometer, broken where the unit stands
    A.line([(278.3, 241.2), (355.3, 241.2)], (200, 200, 198), 0.8)
    # the date's calendar box
    A.round_rect(284.2, 219.8, 291.6, 229.0, 1.0, None, outline=(226, 224, 222), w=0.8)
    A.text(287.9, 224.6, "1", ARIAL_B, 6.4, (226, 224, 222))

    A.final = A.finish(A.S, blur=1.4, strength=0.45)
    fin = A.final
    ImageDraw.Draw(fin).rectangle([0, 0, fin.width - 1, fin.height - 1], outline=(6, 6, 7), width=3 * S)
    sp.bg = fin.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # ---- lamps that light
    def lamp(draw, bx, when, blur=1.0):
        G = Art(REF, box, S=6, bg=(0, 0, 0))
        draw(G)
        G.final = G.finish(G.S, blur=blur, strength=0.5)
        sp.add_show(sp.box(G, bx, black=True), when)

    def sidelights(G):  # green, with the lights
        col = (70, 220, 110)
        for s in (-1, 1):
            G.d.arc([*G.q(112.0 + s * 3.2 - 3.0, 189.0), *G.q(112.0 + s * 3.2 + 3.0, 195.0)], 90 if s < 0 else 270, 270 if s < 0 else 90, fill=col, width=int(0.9 * S))
            for dy in (-2.2, 0.0, 2.2):
                G.line([(112.0 + s * 7.0, 192.0 + dy), (112.0 + s * 9.5, 192.0 + dy)], col, 0.8)

    def triangle(G):  # the amber warning triangle (lit on the photo, standing)
        G.poly([(512.5, 193.5), (518.5, 204.0), (506.5, 204.0)], (240, 178, 40))
        G.text(512.5, 200.6, "!", ARIAL_B, 6.4, (30, 20, 0))

    def dsc(G):  # traction control off
        col = (246, 160, 30)
        G.round_rect(141.0, 199.0, 152.0, 205.0, 1.5, None, outline=col, w=0.9)
        for x0 in (140.5, 147.5):
            G.line([(x0, 210.0), (x0 + 1.6, 207.0), (x0 + 3.2, 210.0), (x0 + 4.8, 207.0)], col, 0.7)
        G.text(146.5, 214.5, "OFF", ARIAL_B, 4.6, col)

    def belt(G):  # the seat belt lamp, standing
        col = (236, 40, 32)
        G.circle(236.0, 199.0, 1.7, col)
        G.line([(235.4, 201.3), (234.6, 207.4), (239.6, 207.4)], col, 1.4)
        G.line([(232.6, 201.4), (238.2, 206.4)], col, 0.8)
        G.line([(239.0, 207.4), (240.2, 211.0)], col, 1.3)

    lamp(sidelights, (100, 184, 124, 200), "lights")
    lamp(triangle, (503, 190, 522, 208), "parked")
    lamp(dsc, (136, 194, 158, 219), "tcoff")
    lamp(belt, (229, 194, 244, 214), "parked")

    # ---- needles: a red blade with a hot core and a short dark counterweight, the hub cap on top
    def blade(length, tail, w0, w1, cap):
        K = 4
        k = sp.A * K
        L = max(length, tail, cap) + 2
        Wd, Hd = int(2 * (cap + 2) * k), int(2 * L * k)
        im = Image.new("RGBA", (Wd, Hd), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        cx, cy = Wd / 2, Hd / 2
        d.polygon([(cx - w0 / 2 * k, cy + tail * k), (cx + w0 / 2 * k, cy + tail * k), (cx + w0 / 2 * k, cy), (cx + w1 / 2 * k, cy - length * k), (cx - w1 / 2 * k, cy - length * k), (cx - w0 / 2 * k, cy)], fill=RED + (255,))
        d.polygon([(cx - w0 * 0.18 * k, cy), (cx + w0 * 0.18 * k, cy), (cx + w1 * 0.12 * k, cy - length * 0.94 * k), (cx - w1 * 0.12 * k, cy - length * 0.94 * k)], fill=(252, 150, 80, 255))
        d.rectangle([cx - w0 / 2 * k, cy + (tail - 5) * k, cx + w0 / 2 * k, cy + tail * k], fill=(20, 20, 22, 255))
        if cap:
            d.ellipse([cx - cap * k, cy - cap * k, cx + cap * k, cy + cap * k], fill=(4, 4, 5, 255), outline=(70, 70, 76, 255), width=int(0.5 * k))
        return im.resize((max(2, Wd // K), max(2, Hd // K)), Image.LANCZOS)

    big = blade(80.0, 21.0, 3.4, 1.9, 0.0)
    add_needle(sp, big, C1[0], C1[1], "kmh", [(0, spd(0)), (330, spd(330))])
    add_needle(sp, big, C2[0], C2[1], "rpm", [(0, rev(0)), (8.6, rev(8.6))])
    add_needle(sp, blade(37.5, 11.0, 2.4, 1.5, 0.0), HF[0], HF[1], "fuel", FU)

    # ---- the screen: speed and unit, the gear, date, unit, odometer, trip
    def char_im(parts, cap_h):
        """letters on one canvas centred on the big letter's middle: parts = (text, cap height, x offset of the ink
        middle from the canvas middle)"""
        K = 4
        k = sp.A * K
        Wd, Hd = int(60 * k), int(cap_h * 2.2 * k)
        m = Image.new("L", (Wd, Hd), 0)
        for s, ch, dx in parts:
            fo = font(ARIAL_B, ch / 0.716 * k)
            t = Image.new("L", (int(ch * 3 * k), int(ch * 3 * k)), 0)
            ImageDraw.Draw(t).text((ch * k * 0.5, ch * k * 0.5), s, font=fo, fill=255)
            bb = t.getbbox()
            t = t.crop(bb)
            # baseline shared: bottoms aligned at the big letter's bottom
            m.paste(t, (int(Wd / 2 + dx * k - t.width / 2), int(Hd / 2 + cap_h / 2 * k - t.height)), t)
        m = m.resize((Wd // K, Hd // K), Image.LANCZOS)
        out = Image.new("RGBA", m.size, WHT + (0,))
        out.putalpha(m)
        return out

    sprites = {"N": {"im": char_im([("P", 17.5, 0.0)], 17.5)}, "R": {"im": char_im([("R", 17.5, 0.0)], 17.5)}}
    sprites["P"] = sprites["N"]
    for ch in "1234567":
        sprites[ch] = {"im": char_im([("D", 17.5, 0.0), (ch, 8.8, -15.8)], 17.5)}
    sp.gear = {"x": 431.2 - sp.ox, "y": 200.8 - sp.oy, "sprites": sprites}
    sp.font("spd", ARIAL_B, 18.6, "0123456789", shear=0, track=0.3)
    sp.readout("spd", 323.2, 198.3, "r", 3, "speed", WHT)
    sp.font("unit", ARIAL_B, 8.0, "kmhpi/", shear=0, track=0.1)
    sp.readout("unit", 327.6, 202.9, "l", 4, "unit", (226, 224, 222))
    sp.font("num", ARIAL_B, 13.0, "0123456789.", shear=0, track=0.15)
    sp.readout("num", 293.8, 224.5, "l", 10, "date", WHT)
    sp.readout("num", 266.8, 249.6, "l", 6, "odo", WHT)
    sp.readout("num", 355.4, 249.6, "r", 6, "trip", WHT)
    sp.font("du", ARIAL_B, 7.2, "kmi", shear=0)
    sp.readout("du", 266.8, 239.2, "l", 2, "distUnit", (226, 224, 222))
    return sp


def gt3rs(Spec, needle_sprite, add_needle, glyph, solid_gear):
    """the Stuttgart 991.2 Track (`porsha_gt3`), redrawn 1:1 from the owner's photo (imports/refs/gt3rs_9912_cluster_owner.png,
    lit, 2026-11-10; the steering wheel hides bits of the outer dials on the photo, the model's own atlas
    (imports/refs/model_clusters/5_gt3rs_9912_img20_InteriorA_emissive.png) fills them in): five round dials in one hood,
    each tucked under its neighbour as on the car, in black rims with dark bevels that catch the lit marks: the oil gauge
    (temperature 60-150 on its upper hub, pressure 0-5 on its lower one, both drawn where the photo has them: cold, no
    pressure), the speedometer 0-350 km/h (marks every 10, numbers every 50; the needle follows km/h, as printed) with the
    odometer and trip (live, segment digits as on the photo), the big grey rev counter 0-10 (yellow marks every 200 to
    8,000, every 100 to 9,000, the lit pale band 9-10 with its red-orange glow), white numbers in a square font, the
    warning lamps unlit (the belt lamp lights standing, the stability-off car with traction control off), the P R N D / M
    strip (the lit square follows the gear; in a gear the box shows its number), the digital speed and unit (live, the
    player's unit) and "Lift"; the round screen (a plain car outline of our own, "991.2 TRACK" where the photo names the
    car, the clock live); water 60-120 (drawn cold, as on the photo) over fuel 0 - 2/4 - 4/4 (live) on the far right.
    Orange-yellow needles. No logo: the rev counter's model script is left out (blank). Coordinates are pixels of the
    photo; the box is laid on the photo so the photo's five dial centres sit on the 2019 model's five tubes (2026-11-13;
    the panel is cut to the tubes by tools/lambo/window_gt3rs.png)."""
    box = (287, 397, 1732, 940)  # the 2019 model's five dial tubes as the driver's eye sees them on the panel, 400.8 x 150.6 mm, 0.2773 mm a photo px (measured 2026-11-13)
    REF = "gt3rs_9912_cluster_owner.png"
    A = Art(REF, box, S=2, bg=(5, 5, 6))
    sp = Spec("gt3rs", box[2] - box[0], box[3] - box[1], 1.3, 0.94, box[0], box[1])  # bg 1358 x 510 (halves 679 x 510)
    sp.redline, sp.idle = 9.0, 0.9
    from cluster_art import FONTDIR
    from cluster_lfa_maybach import angular

    SQ = FONTDIR + "Michroma-Regular.ttf"  # the square numbers (Porsche's are close to it, made bolder with a stroke)
    S = A.S
    CR, RR = (1010.0, 608.0), 188.0  # rev counter: centre, face radius
    CS, RS = (693.3, 681.8), 146.0  # speedometer
    CT, RT = (1387.0, 672.0), 158.0  # the round screen
    CO = (450.5, 760.0)  # oil dial
    CW = (1569.5, 770.0)  # water / fuel dial
    HT, HP = (430.8, 738.3), (452.3, 807.5)  # oil: temperature hub, pressure hub
    HW, HF = (1597.3, 742.2), (1569.3, 816.1)  # water hub, fuel hub
    WHT = (246, 246, 246)
    YEL = (246, 196, 40)
    YEL_B = (255, 214, 60)
    NEEDLE = (250, 180, 22)
    ICON = (98, 98, 100)

    def rev(v):
        return (v - 5.0) * 26.84 + 0.7

    def kph(v):
        return -132.9 + 0.485 * v

    base = np.asarray(A.im).astype(np.float32)

    def region(C, R):
        x0, x1 = max(0, int((C[0] - R - A.ox) * S)), min(A.W * S, int((C[0] + R - A.ox) * S) + 2)
        y0, y1 = max(0, int((C[1] - R - A.oy) * S)), min(A.H * S, int((C[1] + R - A.oy) * S) + 2)
        yy, xx = np.mgrid[y0:y1, x0:x1]
        px = (xx + 0.5) / S + A.ox - C[0]
        py = (yy + 0.5) / S + A.oy - C[1]
        return (slice(y0, y1), slice(x0, x1)), np.hypot(px, py), np.degrees(np.arctan2(px, -py)) % 360, px, py

    def put(sl, rgb, a):
        a = np.clip(a, 0, 1)[..., None]
        base[sl] = base[sl] * (1 - a) + np.asarray(rgb, np.float32) * a

    def push():
        A.im.paste(Image.fromarray(np.clip(base, 0, 255).astype("uint8")))

    def pull():
        base[...] = np.asarray(A.im).astype(np.float32)

    def streaks(th, angs, width):
        s = np.zeros(th.shape, np.float32)
        for a in angs:
            d = (th - a % 360 + 180) % 360 - 180
            s += np.exp(-(d / width) ** 2)
        return np.clip(s, 0, 1)

    def housing(Cf, rf, Cr, Rr, face_fn, glints, tr=16.0, glint_col=(255, 140, 40), glint_k=0.42, wall=(22.0, 34.0)):
        """a round dial seen as on the photo: the black rim (circle Cr, Rr, tr thick; its centre off the face's, as the
        camera saw the tube), the tube's inner wall between it and the face (wider on the far side, lit softly by the
        marks), the face (circle Cf, rf)"""
        sl, r, th, px, py = region(Cf, Rr + abs(Cr[0] - Cf[0]) + abs(Cr[1] - Cf[1]) + 2)
        dx, dy = Cf[0] - Cr[0], Cf[1] - Cr[1]
        rr = np.hypot(px + dx, py + dy)  # distance from the rim's centre
        put(sl, (3, 3, 4), band_mask(rr, -5, Rr, 0.6))
        put(sl, (24, 24, 26), band_mask(rr, Rr - 1.2, Rr, 0.5) * 0.8)
        Rin = Rr - tr
        ux, uy = px / np.maximum(r, 1e-3), py / np.maximum(r, 1e-3)
        b = dx * ux + dy * uy
        rw = -b + np.sqrt(np.maximum(b * b - (dx * dx + dy * dy - Rin * Rin), 0))
        t = np.clip((r - rf) / np.maximum(rw - rf, 1.0), 0, 1)
        v = (wall[0] + wall[1] * t) * (1.0 + 0.3 * np.cos(np.radians(th)))
        rgb = np.stack([v, v * 0.93, v * 0.88], -1)
        g = (streaks(th, glints, 2.6) * (1 - t) ** 0.6 * np.clip(t * 6, 0, 1) * glint_k * (0.35 + 0.65 * np.clip(np.cos(np.radians(th)), 0, 1)))[..., None]
        rgb = rgb * (1 - g) + np.asarray(glint_col, np.float32) * g
        inwall = band_mask(rr, -5, Rin, 0.6) * np.clip((r - rf) / 0.6 + 0.5, 0, 1)
        put(sl, rgb, inwall)
        put(sl, (10, 10, 11), band_mask(r, rf - 0.4, rf + 1.6, 0.4))
        frgb, a = face_fn(r, th, px, py)
        put(sl, frgb, band_mask(r, -5, rf - 0.4, 0.5) * a)

    def black_face(level):
        def fn(r, th, px, py):
            v = level + 4 * np.exp(-(r / 120) ** 2)
            return np.stack([v, v, v * 1.05], -1), 1.0
        return fn

    # ---- the hood behind the dials: black, the lower shroud a little lighter
    sl, r, th, px, py = region((980.0, 640.0), 800)
    yy = py + 640.0
    v = 4 + 26 * smooth(800, 900, yy)
    put(sl, np.stack([v, v, v * 1.05], -1), np.ones(r.shape))

    # ---- the outer dials first (each tucked under its neighbour)
    housing(CO, 150.0, (428.0, 765.0), 192.0, black_face(20.0), [-89.5 + 11.2 * k for k in range(-3, 10)])
    housing(CW, 150.0, (1592.0, 772.0), 192.0, black_face(14.0), [-4.0 + 16.2 * k for k in range(-2, 8)])
    push()

    def ray_hit(H, Oc, Rc, alpha):
        ux, uy = math.sin(math.radians(alpha)), -math.cos(math.radians(alpha))
        dx, dy = H[0] - Oc[0], H[1] - Oc[1]
        b = dx * ux + dy * uy
        t = -b + math.sqrt(max(0.0, b * b - (dx * dx + dy * dy - Rc * Rc)))
        return (H[0] + ux * t, H[1] + uy * t), (ux, uy)

    def sub_scale(H, Oc, Rc, angs, majors, col=YEL):
        for i, a in enumerate(angs):
            p, (ux, uy) = ray_hit(H, Oc, Rc, a)
            major = i in majors
            L = 14.0 if major else 7.0
            A.line([p, (p[0] - ux * L, p[1] - uy * L)], col if not isinstance(col, dict) else col.get(i, YEL), 4.2 if major else 2.2)

    # oil: temperature (60-150, every 10) on the upper hub, pressure (0-5, every 0.5) on the lower hub
    tang = [-89.5 + 1.12 * (c - 60) for c in range(60, 151, 10)]
    sub_scale(HT, (449.3, 766.5), 119.6, tang, (0, 3, 6, 9))
    pang = [-113.2 - 25.1 * p / 2 for p in range(0, 11)]
    sub_scale(HP, (451.0, 755.4), 125.0, pang, (0, 2, 4, 6, 8, 10))

    def sq(x, y, s, h, col=WHT, sx=0.92, stroke=0.7, anchor="mm", shear=0.0, G=None):
        G = G or A
        size = h / 0.715
        G.text(x, y, s, SQ, size, col, anchor=anchor, scale_x=sx, stroke=stroke, strokecol=col, shear=shear)

    for s, (x, y) in (("60", (377.0, 739.0)), ("90", (379.5, 708.5)), ("120", (404.5, 684.0)), ("150", (437.0, 668.5))):
        sq(x, y, s, 10.0, sx=0.86)
    for i, (x, y) in enumerate(((388.5, 835.0), (409.0, 849.5), (435.5, 857.5), (461.0, 857.5), (485.0, 851.5), (509.5, 840.5))):
        sq(x, y, str(i), 10.5, sx=0.86)

    def oil_can(x, y, k, col, thermo=False):
        A.line([(x - 17 * k, y - 3 * k), (x - 10 * k, y), (x - 6 * k, y + 5 * k), (x + 8 * k, y + 5 * k), (x + 16 * k, y - 4 * k)], col, 1.6 * k)
        A.line([(x - 6 * k, y + 5 * k), (x - 7 * k, y - 1 * k), (x + 5 * k, y - 1 * k), (x + 8 * k, y + 5 * k)], col, 1.6 * k)
        A.line([(x - 3 * k, y - 1 * k), (x - 3 * k, y - 4 * k), (x + 1 * k, y - 4 * k), (x + 1 * k, y - 1 * k)], col, 1.3 * k)
        A.circle(x + 17.5 * k, y + 1.5 * k, 1.2 * k, col)
        if thermo:
            A.line([(x + 22 * k, y - 7 * k), (x + 22 * k, y + 4 * k)], col, 1.6 * k)
            for dy in (-5, -2, 1):
                A.line([(x + 23 * k, y + dy * k), (x + 26 * k, y + dy * k)], col, 1.0 * k)

    oil_can(352.0, 754.0, 0.85, WHT, thermo=True)
    oil_can(363.0, 827.0, 0.85, WHT)
    # the oil needles, still: temperature at 60, pressure at 0 (the photo's cold engine)
    for H, a, L in ((HT, -89.5, 96.0), (HP, -113.2, 98.0)):
        A.circle(H[0], H[1], 11.0, (12, 12, 13))
        A.line([polar(H, 26.0, a), polar(H, L, a)], NEEDLE, 4.6)
        A.line([polar(H, 28.0, a), polar(H, L - 4, a)], (252, 226, 150), 1.2)

    # water (60-120) on the upper hub, fuel (0 - 4/4, eighths) on the lower hub
    wang = [93.3 - 1.62 * (c - 60) for c in range(60, 121, 10)]
    sub_scale(HW, (1569.0, 778.1), 123.9, wang, (0, 3, 6), col={6: (222, 40, 30)})
    for a0, a1 in ((-24.0, -14.0),):
        pts = [ray_hit(HW, (1569.0, 778.1), 123.9, a0 + (a1 - a0) * k / 6)[0] for k in range(7)]
        pts += [ray_hit(HW, (1569.0, 778.1), 112.0, a1 - (a1 - a0) * k / 6)[0] for k in range(7)]
        A.poly(pts, (214, 34, 26))
    fang = [-120.4 - 124.7 * k / 8 for k in range(9)]
    sub_scale(HF, (1569.8, 762.2), 128.6, fang, (0, 4, 8))
    pts = [ray_hit(HF, (1569.8, 762.2), 128.6, -125.0 - 12.0 * k / 6)[0] for k in range(7)]
    pts += [ray_hit(HF, (1569.8, 762.2), 116.0, -137.0 + 12.0 * k / 6)[0] for k in range(7)]
    A.poly(pts, (214, 34, 26))
    for s, (x, y) in (("120", (1591.5, 685.5)), ("90", (1634.0, 708.5)), ("60", (1656.0, 746.0)), ("0", (1507.0, 849.0)),
                      ("2/4", (1575.0, 870.0)), ("4/4", (1625.5, 842.0))):
        sq(x, y, s, 10.5, sx=0.86)
    # the water and fuel signs
    A.line([(1678.0, 755.0), (1678.0, 768.0)], WHT, 1.6)
    for dy in (757.0, 761.0, 765.0):
        A.line([(1678.0, dy), (1683.0, dy)], WHT, 1.0)
    for dy in (771.0, 775.0):
        A.line([(1668.0, dy), (1671.0, dy - 1.5), (1674.0, dy), (1677.0, dy - 1.5), (1680.0, dy), (1683.0, dy - 1.5), (1686.0, dy), (1689.0, dy - 1.5)], WHT, 1.1)
    A.round_rect(1651.0, 827.0, 1662.0, 845.0, 1.5, None, outline=WHT, w=1.6)
    A.rect(1653.0, 829.5, 1660.0, 835.0, WHT)
    A.line([(1662.0, 831.0), (1666.0, 834.0), (1666.0, 842.0)], WHT, 1.2)
    A.poly([(1668.0, 832.0), (1674.0, 835.5), (1668.0, 839.0)], WHT)
    # the water needle, still at 60 (cold, as on the photo); its hub; the fuel hub (its needle is live)
    for H in (HW, HF):
        A.circle(H[0], H[1], 11.0, (12, 12, 13))
    A.line([polar(HW, 24.0, 93.3), polar(HW, 88.0, 93.3)], NEEDLE, 4.6)
    A.line([polar(HW, 26.0, 93.3), polar(HW, 84.0, 93.3)], (252, 226, 150), 1.2)
    pull()

    # ---- the speedometer and the round screen over them
    housing(CS, RS, (650.2, 680.5), 209.0, black_face(18.0), [kph(v) for v in range(0, 351, 25)], tr=18.0)

    def screen(r, th, px, py):
        yv = np.clip((py + RT) / (2 * RT), 0, 1)
        lift = np.exp(-((px / 120) ** 2 + ((py + 40) / 90) ** 2))
        return np.stack([10 + 20 * (1 - yv) + 22 * lift, 12 + 22 * (1 - yv) + 24 * lift, 20 + 28 * (1 - yv) + 30 * lift], -1), 1.0

    housing(CT, RT + 12.0, (1390.0, 676.0), 183.0, lambda r, th, px, py: (np.stack([8 + 0 * r, 8 + 0 * r, 10 + 0 * r], -1), 1.0), [], wall=(30.0, 22.0))
    sl, r, th, px, py = region(CT, RT + 2)
    frgb, _ = screen(r, th, px, py)
    put(sl, frgb, band_mask(r, -5, RT, 0.6))
    push()

    # the odometer's window: the bottom of the speedometer's face under a straight edge with a round corner
    sl, r, th, px, py = region(CS, RS)
    m = Image.new("L", (sl[1].stop - sl[1].start, sl[0].stop - sl[0].start), 0)
    ImageDraw.Draw(m).rounded_rectangle([((556.0 - A.ox) * S - sl[1].start), ((773.0 - A.oy) * S - sl[0].start),
                                         ((860.0 - A.ox) * S - sl[1].start), ((850.0 - A.oy) * S - sl[0].start)], radius=12 * S, fill=255)
    put(sl, (6, 6, 8), np.asarray(m).astype(np.float32) / 255 * band_mask(r, -5, RS - 0.5, 0.5))
    push()

    # speedometer marks and numbers
    for v in range(0, 351, 10):
        major = v % 50 == 0
        A.line([polar(CS, 129.5 if major else 136.5, kph(v)), polar(CS, 143.6, kph(v))], YEL_B if major else YEL, 4.4 if major else 2.2)
    for s, (x, y) in (("0", (607.5, 763.5)), ("50", (580.5, 720.5)), ("100", (583.5, 673.0)), ("150", (598.5, 625.5)), ("200", (630.5, 589.5)),
                      ("250", (668.0, 566.0)), ("300", (723.5, 566.5)), ("350", (757.0, 590.5))):
        sq(x, y, s, 13.0, sx=0.84)
    A.text(693.5, 584.5, "km/h", ARIAL_B, 12.6, (226, 226, 226), scale_x=0.95)
    A.text(744.5, 795.0, "km", ARIAL_B, 13.0, WHT, scale_x=0.95)

    # the round screen: a plain car outline of our own, the name, the line, (the clock is live)
    car = [(1251.0, 682.0), (1262.0, 677.0), (1290.0, 672.0), (1312.0, 668.0), (1330.0, 659.5), (1348.0, 655.5), (1366.0, 656.0),
           (1384.0, 660.5), (1398.0, 667.0), (1412.0, 670.0), (1424.0, 671.0)]
    A.line(car, WHT, 1.6)
    A.line([(1251.0, 682.0), (1251.0, 686.0), (1272.0, 686.5)], WHT, 1.4)
    A.d.arc([*A.q(1272.0, 675.0), *A.q(1296.0, 699.0)], 180, 360, fill=WHT, width=int(1.4 * S))
    A.line([(1296.0, 686.5), (1384.0, 686.5)], WHT, 1.4)
    A.d.arc([*A.q(1384.0, 675.0), *A.q(1408.0, 699.0)], 180, 360, fill=WHT, width=int(1.4 * S))
    A.line([(1408.0, 686.5), (1426.0, 686.0), (1430.0, 680.0), (1426.0, 671.0)], WHT, 1.4)
    A.line([(1322.0, 671.0), (1336.0, 662.0), (1350.0, 660.0), (1362.0, 661.0), (1378.0, 666.0), (1372.0, 670.0), (1322.0, 671.0)], (190, 196, 214), 1.0)
    A.line([(1420.0, 670.0), (1424.0, 660.0), (1446.0, 657.5), (1444.0, 662.0), (1426.0, 664.0)], WHT, 1.4)  # the wing
    A.line([(1430.0, 663.0), (1430.0, 671.0)], WHT, 1.2)
    sq(1349.0, 702.0, "991.2 TRACK", 15.0, sx=0.80, stroke=0.45, shear=0.22)
    A.line([(1205.0, 773.8), (1445.0, 773.8)], (200, 204, 214), 1.0)
    pull()

    # ---- the rev counter on top
    def rev_face(r, th, px, py):
        v = 72 - 22 * smooth(70, RR, r) + 10 * np.clip(py / RR, -1, 1)
        return np.stack([v, v * 0.985, v * 0.985], -1), 1.0

    housing(CR, RR, (1012.0, 610.0), 240.0, rev_face, [rev(v / 2) for v in range(0, 18)], tr=24.0, wall=(28.0, 38.0))
    sl, r, th, px, py = region(CR, 240)
    zone = ((th - rev(9.0)) % 360 <= rev(10.05) - rev(9.0)).astype(np.float32)
    put(sl, np.stack([236 - 30 * np.clip((r - 190) / 16, 0, 1), 84 - 30 * np.clip((r - 190) / 16, 0, 1), 30 + 0 * r], -1), band_mask(r, 189.0, 206.0, 2.0) * zone * 0.7)
    A.im.paste(Image.fromarray(np.clip(base, 0, 255).astype("uint8")))
    A.gd.polygon([A.q(*polar(CR, 197.0, rev(9.0) + (rev(10.05) - rev(9.0)) * k / 20)) for k in range(21)] +
                 [A.q(*polar(CR, 186.0, rev(10.05) - (rev(10.05) - rev(9.0)) * k / 20)) for k in range(21)], fill=(120, 40, 10))
    pull()
    # the digital speed's window: the bottom of the face, under a straight edge with round corners
    sl, r, th, px, py = region(CR, RR)
    m = Image.new("L", (sl[1].stop - sl[1].start, sl[0].stop - sl[0].start), 0)
    ImageDraw.Draw(m).rounded_rectangle([((898.0 - A.ox) * S - sl[1].start), ((738.0 - A.oy) * S - sl[0].start),
                                         ((1122.0 - A.ox) * S - sl[1].start), ((830.0 - A.oy) * S - sl[0].start)], radius=12 * S, fill=255)
    mm = np.asarray(m).astype(np.float32) / 255 * band_mask(r, -5, RR - 0.5, 0.5)
    put(sl, (12, 12, 15), mm)
    push()

    # rev marks: every 200 to 8,000, every 100 to 9,000, the pale band 9-10
    for i in range(0, 41):
        v = i / 5
        major = i % 5 == 0
        A.line([polar(CR, 167.5 if major else 175.0, rev(v)), polar(CR, 185.0, rev(v))], YEL_B if major else YEL, 4.4 if major else 2.2)
    for i in range(1, 10):
        v = 8.0 + i / 10
        A.line([polar(CR, 175.0, rev(v)), polar(CR, 185.0, rev(v))], YEL, 2.0)
    n = 30
    pts = [polar(CR, 182.5, rev(9.0) + (rev(10.0) - rev(9.0)) * k / n) for k in range(n + 1)] + [polar(CR, 172.0, rev(10.0) - (rev(10.0) - rev(9.0)) * k / n) for k in range(n + 1)]
    A.poly(pts, (255, 224, 152))
    A.gd.polygon([A.q(*p) for p in pts], fill=(90, 50, 10))
    for v in (9.0, 10.0):
        A.line([polar(CR, 167.5, rev(v)), polar(CR, 185.0, rev(v))], (255, 214, 120), 4.4)
    NUM = {0: (901.0, 710.5), 1: (858.0, 650.5), 2: (859.0, 582.5), 3: (887.0, 522.5), 4: (940.5, 474.5), 5: (1012.5, 458.5),
           6: (1084.0, 475.5), 7: (1134.0, 525.5), 8: (1160.5, 584.5), 9: (1156.5, 654.5), 10: (1120.0, 712.5)}
    for v, (x, y) in NUM.items():
        sq(x, y, str(v), 21.0, sx=0.88, stroke=1.1)
    # (the model's script under the 5 is left out: blank)

    # the unlit warning lamps round the face
    def arrow(x, y, s, col):
        A.poly([(x - 11 * s, y), (x - 2 * s, y - 9), (x - 2 * s, y - 4), (x + 10 * s, y - 4), (x + 10 * s, y + 4), (x - 2 * s, y + 4), (x - 2 * s, y + 9)], col)

    arrow(966.0, 513.0, 1, ICON)
    arrow(1054.0, 513.0, -1, ICON)
    A.d.chord([*A.q(1000.0, 491.0), *A.q(1024.0, 509.0)], 270, 90, fill=None, outline=ICON, width=int(2.0 * S))
    A.line([(1012.0, 491.5), (1012.0, 508.5)], ICON, 2.0)
    for k in range(4):
        A.line([(996.0, 493.0 + k * 4.6), (1008.0, 493.0 + k * 4.6)], ICON, 1.6)

    def ring_lamp(x, y, s, col, txt):
        A.circle(x, y, 9.0, None, outline=col, w=1.8)
        A.d.arc([*A.q(x - 14, y - 12), *A.q(x + 14, y + 12)], 120, 240, fill=col, width=int(1.6 * S))
        A.d.arc([*A.q(x - 14, y - 12), *A.q(x + 14, y + 12)], -60, 60, fill=col, width=int(1.6 * S))
        A.text(x, y + 0.5, txt, ARIAL_B, s, col)

    ring_lamp(931.0, 541.0, 13.0, ICON, "!")
    ring_lamp(931.0, 668.0, 12.0, ICON, "P")
    ring_lamp(1090.0, 541.0, 6.4, ICON, "ABS")

    def belt(G, col):
        G.circle(904.0, 575.0, 3.2, col)
        G.line([(903.0, 580.0), (901.0, 592.0), (911.0, 592.0)], col, 2.6)
        G.line([(897.0, 580.0), (909.0, 590.0)], col, 1.5)
        G.line([(910.0, 592.0), (912.5, 599.0)], col, 2.4)

    def psm(G, col):  # stability control off: the car on wavy tracks, OFF
        G.round_rect(1100.0, 600.0, 1122.0, 612.0, 3.0, None, outline=col, w=1.8)
        G.line([(1103.0, 612.0), (1103.0, 616.0)], col, 2.0)
        G.line([(1119.0, 612.0), (1119.0, 616.0)], col, 2.0)
        for x0 in (1099.0, 1113.0):
            G.line([(x0, 625.0), (x0 + 3, 619.5), (x0 + 6, 625.0), (x0 + 9, 619.5)], col, 1.3)
        G.text(1111.0, 632.0, "OFF", ARIAL_B, 8.0, col)

    belt(A, ICON)
    psm(A, ICON)
    A.circle(943.0, 600.0, 3.0, ICON)  # the airbag lamp: a seated figure and the bag
    A.line([(942.0, 605.0), (940.0, 616.0), (950.0, 616.0)], ICON, 2.4)
    A.circle(953.0, 607.0, 5.0, None, outline=ICON, w=1.4)
    A.line([(896.0, 622.0), (914.0, 622.0), (918.0, 627.0), (918.0, 634.0), (898.0, 634.0), (894.0, 628.0), (896.0, 622.0)], ICON, 1.6)  # engine
    A.line([(902.0, 622.0), (902.0, 618.0), (908.0, 618.0)], ICON, 1.4)
    A.round_rect(1102.0, 572.0, 1122.0, 584.0, 3.0, None, outline=ICON, w=1.6)  # the car with its lamp lines
    for k in range(3):
        A.line([(1124.0 + k * 3, 571.0), (1126.0 + k * 3, 585.0)], ICON, 1.2)

    # the gear strip: P R N D, M with + / -, the unlit squares, the box for the gear
    A.round_rect(994.0, 648.0, 1026.0, 688.0, 5.0, (12, 12, 14), outline=(34, 34, 38), w=1.2)
    for s, y in (("P", 653.8), ("R", 672.5), ("N", 692.5), ("D", 711.3)):
        A.text(1058.0, y, s, ARIAL_B, 14.2, WHT, scale_x=0.95)
        A.circle(1047.5, y, 2.2, WHT)
        A.rect(1073.0, y - 2.4, 1079.0, y + 2.4, (60, 60, 62))
    A.line([(1047.5, 653.8), (1047.5, 711.3)], WHT, 1.2)
    A.line([(1036.0, 711.3), (1047.5, 711.3)], WHT, 1.2)
    A.text(1028.0, 711.3, "M", ARIAL_B, 13.6, WHT, scale_x=0.95)
    A.line([(1035.0, 697.0), (1042.5, 697.0)], WHT, 1.4)
    A.line([(1035.0, 724.0), (1042.5, 724.0)], WHT, 1.4)
    A.line([(1038.75, 720.25), (1038.75, 727.75)], WHT, 1.4)
    A.text(1009.0, 786.0, "Lift", ARIAL_B, 10.6, (226, 226, 226), scale_x=0.95)

    A.final = A.finish(A.S, blur=2.0, strength=0.4)
    fin = A.final
    ImageDraw.Draw(fin).rectangle([0, 0, fin.width - 1, fin.height - 1], outline=(5, 5, 6), width=3 * S)
    sp.bg = fin.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # ---- lamps that light: the belt lamp standing (red), stability control off (amber)
    Lb = Art(REF, box, S=2, bg=(0, 0, 0))
    belt(Lb, (236, 40, 32))
    Lb.final = Lb.finish(Lb.S, blur=1.5, strength=0.4)
    sp.add_show(sp.box(Lb, (892, 568, 918, 604), black=True), "parked")
    Lp = Art(REF, box, S=2, bg=(0, 0, 0))
    psm(Lp, (250, 160, 30))
    Lp.final = Lp.finish(Lp.S, blur=1.5, strength=0.4)
    sp.add_show(sp.box(Lp, (1094, 594, 1128, 640), black=True), "tcoff")

    # ---- needles: orange-yellow blades with a hot core over dark caps
    def blade(length, w0, w1, cap, tail=0.0):
        K = 4
        k = sp.A * K
        L = max(length, tail, cap) + 2
        Wd, Hd = int(2 * (max(cap, w0) + 2) * k), int(2 * L * k)
        im = Image.new("RGBA", (Wd, Hd), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        cx, cy = Wd / 2, Hd / 2
        if cap:
            d.ellipse([cx - cap * k, cy - cap * k, cx + cap * k, cy + cap * k], fill=(18, 18, 20, 255), outline=(44, 44, 46, 255), width=int(1.0 * k))
        d.polygon([(cx - w0 / 2 * k, cy + tail * k), (cx + w0 / 2 * k, cy + tail * k), (cx + w1 / 2 * k, cy - length * k), (cx - w1 / 2 * k, cy - length * k)], fill=NEEDLE + (255,))
        d.polygon([(cx - w0 * 0.13 * k, cy), (cx + w0 * 0.13 * k, cy), (cx + w1 * 0.12 * k, cy - length * 0.95 * k), (cx - w1 * 0.12 * k, cy - length * 0.95 * k)], fill=(252, 232, 168, 255))
        if cap:
            d.ellipse([cx - cap * 0.3 * k, cy - cap * 0.3 * k, cx + cap * 0.3 * k, cy + cap * 0.3 * k], fill=(30, 30, 32, 255))
        return im.resize((max(2, Wd // K), max(2, Hd // K)), Image.LANCZOS)

    add_needle(sp, blade(186.0, 9.0, 5.6, 32.0), CR[0], CR[1], "rpm", [(0, rev(0)), (10.3, rev(10.3))])
    add_needle(sp, blade(145.0, 7.6, 4.8, 24.0), CS[0], CS[1], "kmh", [(0, kph(0)), (360, kph(360))])
    add_needle(sp, blade(92.0, 4.8, 3.6, 0.0, tail=0.0), HF[0], HF[1], "fuel", [(0, -120.4), (1, -245.1)])

    # ---- segment digits (odometer, trip, the digital speed, the clock), drawn as the photo's
    def seg_font(name, h, w, t, gap, adv, chars, slant=0.0):
        sp.font(name, ARIAL_B, h, "", shear=0)
        g = sp.fonts[name]["g"]
        K = 4
        k = sp.A * K
        SEG = {"0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd", "6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcdfg"}
        for ch in chars:
            pad = 2
            Wd, Hd = int((w + 2 * pad) * k), int((h + 2 * pad) * k)
            m = Image.new("L", (Wd, Hd), 0)
            d = ImageDraw.Draw(m)
            x0, y0 = pad * k, pad * k
            W_, H_, T, G = w * k, h * k, t * k, gap * k
            hm = H_ / 2

            def hseg(y):
                return [(x0 + G + T / 2, y), (x0 + G + T, y - T / 2), (x0 + W_ - G - T, y - T / 2), (x0 + W_ - G - T / 2, y), (x0 + W_ - G - T, y + T / 2), (x0 + G + T, y + T / 2)]

            def vseg(x, ya, yb):
                return [(x, ya + G + T / 2), (x + T / 2, ya + G + T), (x + T / 2, yb - G - T), (x, yb - G - T / 2), (x - T / 2, yb - G - T), (x - T / 2, ya + G + T)]

            P = {"a": hseg(y0 + T / 2), "g": hseg(y0 + hm), "d": hseg(y0 + H_ - T / 2),
                 "f": vseg(x0 + T / 2, y0 + T / 2, y0 + hm), "b": vseg(x0 + W_ - T / 2, y0 + T / 2, y0 + hm),
                 "e": vseg(x0 + T / 2, y0 + hm, y0 + H_ - T / 2), "c": vseg(x0 + W_ - T / 2, y0 + hm, y0 + H_ - T / 2)}
            if ch in SEG:
                for s in SEG[ch]:
                    d.polygon(P[s], fill=255)
                a = adv
            elif ch == ".":
                d.rectangle([x0, y0 + H_ - T, x0 + T, y0 + H_], fill=255)
                a = t * 1.9
            elif ch == ":":
                for yy in (y0 + H_ * 0.3, y0 + H_ * 0.7):
                    d.rectangle([x0, yy - T / 2, x0 + T, yy + T / 2], fill=255)
                a = t * 2.2
            else:
                continue
            if slant:
                m = m.transform(m.size, Image.AFFINE, (1, slant, -slant * (y0 + hm), 0, 1, 0), Image.BICUBIC)
            m = m.resize((max(1, Wd // K), max(1, Hd // K)), Image.LANCZOS)
            bb = m.getbbox()
            im = Image.new("RGBA", m.size, (255, 255, 255, 0))
            im.putalpha(m)
            ox, oy = -pad, -(pad + h / 2)  # (pen at the digit's left edge, on its middle line)
            if bb:
                im = im.crop(bb)
                ox += bb[0] / sp.A
                oy += bb[1] / sp.A
            g[ch] = (im, ox, oy, a)

    seg_font("odo", 18.5, 10.4, 2.9, 0.22, 13.4, "0123456789.")
    sp.readout("odo", 736.0, 790.0, "r", 6, "odoTrim", WHT)
    sp.readout("odo", 732.5, 812.0, "r", 6, "trip", WHT)
    seg_font("spd", 39.5, 24.0, 6.4, 0.4, 30.0, "0123456789")
    sp.readout("spd", 1041.0, 759.5, "r", 3, "speed", WHT)
    sp.font("unit", ARIAL_B, 12.4, "kmhpi/", shear=0)
    sp.readout("unit", 1046.5, 769.6, "l", 4, "unit", WHT)
    seg_font("clock", 21.0, 11.6, 3.0, 0.25, 14.6, "0123456789:")
    sp.readout("clock", 1325.0, 793.0, "m", 5, "clock", WHT)

    # ---- the gear: the lit square by P (standing: the game's N), R or D; in a gear the box shows its number
    def gear_im(row_y, digit=None):
        K = 4
        k = sp.A * K
        x0, y0, x1, y1 = 988.0, 640.0, 1086.0, 735.0  # canvas, centred on the gear's x, y below
        Wd, Hd = int((x1 - x0) * k), int((y1 - y0) * k)
        im = Image.new("RGBA", (Wd, Hd), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.rectangle([(1073.0 - x0) * k, (row_y - 2.6 - y0) * k, (1079.0 - x0) * k, (row_y + 2.6 - y0) * k], fill=(255, 92, 70, 255))
        if digit:
            fo = font(ARIAL_B, 27.0 / 0.716 * k)
            t = Image.new("L", (int(40 * k), int(40 * k)), 0)
            ImageDraw.Draw(t).text((5 * k, 2 * k), digit, font=fo, fill=255)
            t = t.crop(t.getbbox())
            im.paste((246, 246, 246, 255), (int((1010.0 - x0) * k - t.width / 2), int((668.0 - y0) * k - t.height / 2)), t)
        return im.resize((Wd // K, Hd // K), Image.LANCZOS)

    sprites = {"N": {"im": gear_im(653.8)}, "R": {"im": gear_im(672.5)}}
    sprites["P"] = sprites["N"]
    for ch in "1234567":
        sprites[ch] = {"im": gear_im(711.3, ch)}
    sp.gear = {"x": (988.0 + 1086.0) / 2 - sp.ox, "y": (640.0 + 735.0) / 2 - sp.oy, "sprites": sprites}
    return sp
