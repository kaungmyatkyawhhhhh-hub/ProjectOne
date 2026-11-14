"""The Pleiad GC8 Wide's cluster (`pleiad_gc8`) as a live Spec for tools/lambo/cluster_live.py, redrawn sharp from the
model's own cluster picture (imports/refs/pleiad_gc8_model_cluster.png: the lit half of the .glb's 1024 px dial picture
laid on the dial faces' mesh, upright, as the driver sees it; see its .txt). To merge: paste the function `gc8` into
tools/lambo/cluster_imports.py (it needs only that file's own imports, the same as the header below) and see MERGE.md,
"JDM clusters (2026-11-14)"."""

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from cluster_art import ARIAL, ARIAL_B, ARIAL_BI, REG, ROBO_B, TECH, Art, font  # noqa: F401
from cluster_lfa_maybach import band_mask, blend, field, polar, smooth  # noqa: F401

HERE = os.path.dirname(os.path.abspath(__file__))

PREVIEW_INFO = {
    "game": "Pleiad GC8 Wide",
    "photo": "pleiad_gc8_model_cluster.png",
    "states": [dict(v=0.8, gear="N", mph=0, manual=True, clock="10:57", odo="087065", distUnit="km", kmh=True, trip="0.0", fuel=0.75),
               dict(v=5.0, gear="3", mph=49.7, manual=True, clock="10:57", odo="087078", distUnit="km", kmh=True, trip="13.2", fuel=0.62)],
}


def gc8(Spec, needle_sprite, add_needle, glyph, solid_gear):
    """the Pleiad GC8 Wide (`pleiad_gc8`), redrawn sharp from the model's own cluster picture (imports/refs/pleiad_gc8_model_cluster.png:
    the lit half of the .glb's 1024 px dial picture, the one the model's dial faces wear, 2026-11-14; the model's design
    kept): four round grey faces with pale green lit numbers and marks. Left: the fuel (E - F, the pump) and water
    temperature (C - H, the thermometer) gauges, each a thick arc on the left of the face; middle: the big rev counter
    0-9 (x1000 r/min in its dark lit capsule, a mark every 100, longer at 500, long at every 1000; pink-red marks, numbers
    and an inner dashed arc from 7,900 to 9,000) with the dark warning-light panel low in the face (door, BRAKE, ABS, oil,
    belt, battery: dark, as on the model); right: the speedometer 0-180 km/h (a mark every 5, slanted numbers, km/h in
    its capsule) with the odometer window. Pink-red needles with grey caps (the model's needle parts' colours). Live:
    the rev needle, the speed needle (km/h as printed), the fuel needle, the odometer (the car's own miles in the
    player's unit). Drawn still: the water needle at running heat (no data in the game). Left out: the maker's logo in
    the rev counter (its spot stays blank). The model's needle parts are not drawn (ours turn on the faces). Coordinates
    are pixels of the model picture; the box is the whole picture, a guess at the model's hood opening (re-measure it on
    the model; the faces' lower edges are cut where the model's mesh ends)."""
    box = (0, 0, 1414, 484)
    REF = "pleiad_gc8_model_cluster.png"
    A = Art(REF, box, S=3, bg=(0, 0, 0))
    sp = Spec("gc8", box[2] - box[0], box[3] - box[1], 1.05, 1.05, box[0], box[1])  # bg 1485 x 508
    sp.redline, sp.idle = 7.9, 0.8
    S = A.S
    CT, RT = (736.8, 238.2), 241.0  # rev counter: hub, face radius
    CS, RS = (1206.3, 266.0), 201.0  # speedometer
    CF, CW, RSM = (94.2, 232.4), (298.3, 232.6), 92.8  # fuel, water faces (the needles turn about their middles)
    GRN = (210, 244, 192)  # (the picture's 224, 251, 209 under its dark green rims: a touch greener so the glow keeps it)
    PINK = (248, 120, 128)
    FACE = (109, 109, 109)

    def rev(v):
        return -142.4 + v * 30.25

    def spd(v):
        return -141.7 + v * 1.4919

    # ---- the faces: flat grey discs (cut at the picture's foot, where the model's mesh ends)
    for C, R in ((CT, RT), (CS, RS), (CF, RSM), (CW, RSM)):
        A.circle(C[0], C[1], R, FACE)

    GLOW = (44, 58, 38)

    def tick(C, r0, r1, deg, w, col=GRN, glow=GLOW):
        A.line([polar(C, r0, deg), polar(C, r1, deg)], col, w, glow=glow, gw=w * 1.8)

    # ---- the rev counter
    for i in range(0, 91):
        v = i / 10
        col = PINK if v > 7.85 else GRN
        if i % 10 == 0:
            tick(CT, 202.0, 238.0, rev(v), 7.0, col)
        elif i % 5 == 0:
            tick(CT, 213.0, 238.0, rev(v), 4.8, col)
        else:
            tick(CT, 220.0, 238.0, rev(v), 4.0, col)
    for i in range(79, 91):  # the inner dashed red arc
        tick(CT, 141.0, 158.0, rev(i / 10), 3.4, PINK, (70, 30, 30))
    NUMT = {0: (587.5, 397.0), 1: (572.5, 303.0), 2: (563.0, 214.0), 3: (600.0, 131.0), 4: (675.0, 77.0), 5: (764.0, 69.0), 6: (849.0, 107.5),
            7: (900.0, 178.0), 8: (911.0, 269.0), 9: (875.0, 350.0)}
    for v, (x, y) in NUMT.items():
        col = PINK if v >= 8 else GRN
        A.text(x, y, str(v), ARIAL_B, 46.0, col, glow=GLOW if v < 8 else (70, 30, 30), stroke=0.9, strokecol=col)
    # the x1000r/min capsule
    A.round_rect(667.5, 145.6, 805.0, 167.5, 10.5, (8, 30, 10), outline=(150, 170, 150), w=1.2)
    A.text(736.0, 156.6, "x1000r/min", ARIAL_B, 19.0, (150, 250, 120), glow=(30, 70, 24))
    # the warning-light panel (dark, as on the model)
    PAN = [(602.0, 484.0), (602.0, 437.0), (640.0, 362.0), (662.0, 346.0), (700.0, 338.0), (737.0, 336.0), (774.0, 338.0), (812.0, 346.0), (834.0, 362.0), (874.0, 437.0), (874.0, 484.0)]
    pm = Image.new("L", A.im.size, 0)
    ImageDraw.Draw(pm).polygon([A.q(x, y) for x, y in PAN], fill=255)
    cm = Image.new("L", A.im.size, 0)
    ImageDraw.Draw(cm).ellipse([*A.q(CT[0] - RT + 8, CT[1] - RT + 8), *A.q(CT[0] + RT - 8, CT[1] + RT - 8)], fill=255)
    pm = Image.fromarray(np.minimum(np.asarray(pm), np.asarray(cm))).filter(ImageFilter.GaussianBlur(1.2))
    A.im.paste(Image.new("RGB", A.im.size, (50, 50, 51)), (0, 0), pm)
    DIM = (74, 74, 76)
    # the door-open car, BRAKE, ABS ring; the oil can, the belted driver, the battery
    A.round_rect(655.0, 362.0, 683.0, 392.0, 6.0, None, outline=DIM, w=2.6)
    A.round_rect(660.0, 368.0, 678.0, 380.0, 3.0, None, outline=DIM, w=2.0)
    A.text(737.0, 365.0, "BRAKE", ARIAL_B, 16.5, DIM)
    A.circle(793.0, 378.0, 14.0, None, outline=DIM, w=3.0)
    A.d.arc([*A.q(774.0, 359.0), *A.q(812.0, 397.0)], 120, 240, fill=DIM, width=int(2.4 * S))
    A.d.arc([*A.q(774.0, 359.0), *A.q(812.0, 397.0)], -60, 60, fill=DIM, width=int(2.4 * S))
    A.poly([(652.0, 414.0), (664.0, 414.0), (668.0, 418.0), (682.0, 418.0), (692.0, 412.0), (693.0, 414.0), (685.0, 426.0), (666.0, 426.0), (666.0, 420.0), (652.0, 417.0)], DIM)
    A.circle(737.0, 403.0, 4.0, DIM)
    A.line([(734.0, 409.0), (731.0, 422.0), (744.0, 426.0)], DIM, 4.0)
    A.line([(728.0, 410.0), (746.0, 424.0)], DIM, 2.0)
    A.round_rect(782.0, 410.0, 812.0, 430.0, 2.0, None, outline=DIM, w=2.4)
    A.rect(786.0, 406.0, 792.0, 410.0, DIM)
    A.rect(802.0, 406.0, 808.0, 410.0, DIM)

    # ---- the speedometer: a mark every 5, longer every 10, long every 20; slanted numbers
    for i in range(0, 37):
        v = i * 5
        if v % 20 == 0:
            tick(CS, 171.0, 196.0, spd(v), 6.4)
        elif v % 10 == 0:
            tick(CS, 180.0, 196.0, spd(v), 5.0)
        else:
            tick(CS, 186.0, 196.0, spd(v), 4.2)
    NUMS = {0: (1084.0, 392.6), 20: (1079.0, 325.8), 40: (1068.4, 239.0), 60: (1102.6, 168.0), 80: (1155.0, 125.8), 100: (1231.6, 112.6),
            120: (1300.0, 152.0), 140: (1336.8, 215.0), 160: (1351.6, 290.0), 180: (1336.8, 354.7)}
    for v, (x, y) in NUMS.items():
        A.text(x, y, str(v), ARIAL_BI, 33.5, GRN, glow=GLOW, stroke=0.8, strokecol=GRN)
    A.round_rect(1170.0, 183.0, 1247.0, 203.0, 10.0, (8, 30, 10), outline=(150, 170, 150), w=1.2)
    A.text(1208.5, 193.0, "km/h", ARIAL_B, 18.5, (150, 250, 120), glow=(30, 70, 24))
    # the odometer window
    ODO = (1142.0, 357.0, 1279.0, 410.0)
    A.round_rect(*ODO, 6.0, (122, 122, 122), outline=(96, 96, 98), w=1.4)
    A.text(1262.0, 366.0, "ODO", ARIAL_B, 10.0, (78, 80, 78))

    # ---- the fuel and water gauges: a thick arc on the left of the face, end and middle marks, letters, icons
    def side(C, a0, a1, labels, icon):
        n = 40
        pts = [polar(C, 80.0, a0 + (a1 - a0) * k / n) for k in range(n + 1)]
        A.line(pts, GRN, 7.0, glow=GLOW, gw=10.0)
        for f in (0.0, 0.25, 0.5, 0.75, 1.0):
            L = 17.0 if f in (0.0, 1.0) else 10.0
            tick(C, 80.0 - L, 83.0, a0 + (a1 - a0) * f, 5.6 if f in (0.0, 1.0) else 4.4)
        for s, (x, y) in labels:
            A.text(x, y, s, ARIAL_BI, 33.0, GRN, glow=GLOW, stroke=0.8, strokecol=GRN)
        icon()

    def pump():
        x, y = 91.0, 221.0
        A.round_rect(x - 14.0, y - 19.0, x + 9.0, y + 19.0, 3.0, GRN)
        A.rect(x - 9.5, y - 14.0, x + 4.5, y - 3.0, FACE)
        A.line([(x + 9.0, y - 7.0), (x + 16.0, y - 1.0), (x + 16.0, y + 13.0)], GRN, 3.8)

    def thermo():
        x, y = 294.0, 216.0
        A.line([(x, y - 18.0), (x, y + 6.0)], GRN, 6.4)
        for k in range(3):
            A.line([(x + 3.0, y - 14.0 + k * 6.0), (x + 11.0, y - 14.0 + k * 6.0)], GRN, 2.8)
        for dy in (11.0, 18.0):
            A.line([(x - 21.0 + i * 4.2, y + dy + (1.8 if i % 2 else -1.2)) for i in range(11)], GRN, 3.6, glow=GLOW)

    side(CF, -113.2, 10.0, (("E", (56.7, 276.7)), ("F", (130.0, 176.7))), pump)
    side(CW, -113.0, 16.0, (("C", (261.7, 263.3)), ("H", (335.0, 173.3))), thermo)

    # ---- the still water needle (running heat)
    A.line([polar(CW, -12.0, -48.5), polar(CW, 74.0, -48.5)], PINK, 4.0, glow=(70, 30, 30), gw=8.0)
    A.circle(CW[0], CW[1], 7.0, (99, 99, 99), outline=(80, 80, 82), w=1.0)

    A.final = A.finish(A.S, blur=1.5, strength=0.5)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # ---- needles: pink-red blades, a short tail, the grey cap (the model's needle parts' colours)
    def blade(length, tail, w0, w1, cap):
        K = 4
        k = sp.A * K
        L = max(length, tail, cap) + 2
        Wd, Hd = int(2 * (max(cap, w0) + 3) * k), int(2 * L * k)
        im = Image.new("RGBA", (Wd, Hd), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        cx, cy = Wd / 2, Hd / 2
        d.polygon([(cx - w0 / 2 * k, cy + tail * k), (cx + w0 / 2 * k, cy + tail * k), (cx + w1 / 2 * k, cy - length * k), (cx - w1 / 2 * k, cy - length * k)], fill=PINK + (255,))
        d.polygon([(cx - w0 * 0.16 * k, cy), (cx + w0 * 0.16 * k, cy), (cx + w1 * 0.14 * k, cy - length * 0.95 * k), (cx - w1 * 0.14 * k, cy - length * 0.95 * k)], fill=(255, 196, 196, 255))
        if cap:
            d.ellipse([cx - cap * k, cy - cap * k, cx + cap * k, cy + cap * k], fill=(99, 99, 99, 255), outline=(78, 78, 80, 255), width=int(1.5 * k))
            d.ellipse([cx - cap * 0.55 * k, cy - cap * 0.55 * k, cx + cap * 0.55 * k, cy + cap * 0.55 * k], fill=(90, 90, 92, 255))
        return im.resize((max(2, Wd // K), max(2, Hd // K)), Image.LANCZOS)

    add_needle(sp, blade(212.0, 43.0, 9.0, 5.0, 33.0), CT[0], CT[1], "rpm", [(0, rev(0)), (9.3, rev(9.3))])
    add_needle(sp, blade(183.0, 44.0, 8.4, 4.6, 31.0), CS[0], CS[1], "kmh", [(0, spd(0)), (190, spd(190))])
    add_needle(sp, blade(74.0, 12.0, 4.6, 3.2, 7.0), CF[0], CF[1], "fuel", [(0, -113.2), (1, 10.0)])

    # ---- the odometer: dark segment digits in the window (the car's own miles in the player's unit)
    def seg_font(name, h, w, t, gap, adv, chars, slant=0.0):
        sp.font(name, ARIAL_B, h, "", shear=0)
        g = sp.fonts[name]["g"]
        K = 4
        k = sp.A * K
        SEG = {"0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd", "6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcdfg"}
        for ch in chars:
            pad = 2
            Wd, Hd = int((w + 2 * pad) * k), int((h + 2 * pad) * k)
            mm = Image.new("L", (Wd, Hd), 0)
            d = ImageDraw.Draw(mm)
            x0, y0 = pad * k, pad * k
            W_, H_, Tt, G = w * k, h * k, t * k, gap * k
            hm = H_ / 2

            def hseg(y):
                return [(x0 + G + Tt / 2, y), (x0 + G + Tt, y - Tt / 2), (x0 + W_ - G - Tt, y - Tt / 2), (x0 + W_ - G - Tt / 2, y), (x0 + W_ - G - Tt, y + Tt / 2), (x0 + G + Tt, y + Tt / 2)]

            def vseg(x, ya, yb):
                return [(x, ya + G + Tt / 2), (x + Tt / 2, ya + G + Tt), (x + Tt / 2, yb - G - Tt), (x, yb - G - Tt / 2), (x - Tt / 2, yb - G - Tt), (x - Tt / 2, ya + G + Tt)]

            P = {"a": hseg(y0 + Tt / 2), "g": hseg(y0 + hm), "d": hseg(y0 + H_ - Tt / 2),
                 "f": vseg(x0 + Tt / 2, y0 + Tt / 2, y0 + hm), "b": vseg(x0 + W_ - Tt / 2, y0 + Tt / 2, y0 + hm),
                 "e": vseg(x0 + Tt / 2, y0 + hm, y0 + H_ - Tt / 2), "c": vseg(x0 + W_ - Tt / 2, y0 + hm, y0 + H_ - Tt / 2)}
            for s in SEG[ch]:
                d.polygon(P[s], fill=255)
            if slant:
                mm = mm.transform(mm.size, Image.AFFINE, (1, slant, -slant * (y0 + hm), 0, 1, 0), Image.BICUBIC)
            mm = mm.resize((max(1, Wd // K), max(1, Hd // K)), Image.LANCZOS)
            bb = mm.getbbox()
            im = Image.new("RGBA", mm.size, (255, 255, 255, 0))
            im.putalpha(mm)
            ox, oy = -pad, -(pad + h / 2)
            if bb:
                im = im.crop(bb)
                ox += bb[0] / sp.A
                oy += bb[1] / sp.A
            g[ch] = (im, ox, oy, adv)

    seg_font("odo", 26.0, 14.0, 3.6, 0.3, 19.6, "0123456789", slant=0.1)
    sp.readout("odo", 1268.0, 387.5, "r", 6, "odo", (62, 64, 62))

    sprites = {ch: {"im": Image.new("RGBA", (4, 4), (0, 0, 0, 0))} for ch in "RNP1234567"}
    sp.gear = {"x": 0, "y": 0, "sprites": sprites}
    return sp
