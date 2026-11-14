"""The Apex AE86's cluster (`toyoka_ae86`) as a live Spec for tools/lambo/cluster_live.py, redrawn sharp from the model's
own cluster picture (imports/refs/toyoka_ae86_model_cluster.png: the .glb's dashboard picture laid on the cluster's mesh
plane, upright, as the driver sees it; see its .txt). To merge: paste the function `ae86` into
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
    "game": "Apex AE86",
    "photo": "toyoka_ae86_model_cluster.png",
    "states": [dict(v=0.8, gear="N", mph=0, manual=True, clock="10:57", odo="000000", distUnit="km", kmh=True, trip="0.0", fuel=1.0),
               dict(v=5.0, gear="3", mph=49.7, manual=True, clock="10:57", odo="086412", distUnit="km", kmh=True, trip="317.6", fuel=0.62)],
}


def ae86(Spec, needle_sprite, add_needle, glyph, solid_gear):
    """the Apex AE86 (`toyoka_ae86`), redrawn sharp from the model's own cluster picture (imports/refs/toyoka_ae86_model_cluster.png:
    the .glb's 512 px dashboard picture laid on the cluster's plane; the model's design kept, 2026-11-14): black faces,
    white squared numbers, cream needles with dark hub caps; the lower part of both dials hidden by the hood as on the
    model. Left: the fuel bar gauge (E FUEL F, an orange needle swinging from below the window) and the pump; the
    speedometer 0-180 km/h (its own scale: 0-20 short, then 23.3 degrees every 20; amber marks from 100 up, the numbers
    stay white) with the odometer (five drums and the last, grey) and the trip (three drums and the grey tenths);
    "km/h"; the two teal turn arrows (as the model: the game has no indicator state for a cluster); right: the rev counter
    0-8 (x1000/min, a mark every 100, amber from 7,500, red from 7,800 to the red block at 8), the headlamp plate, the OIL
    (L - H) and TEMP (C - H, red at H) bar gauges with their oil-can and thermometer icons. Live: the rev needle, the speed
    needle (km/h as printed), the fuel needle, the odometer (the car's own miles in the player's unit) and the trip.
    Drawn still: the oil pressure and water temperature needles where the model has them (the game has neither). The
    model's printed needles are not in the drawing (ours turn over it). No maker's mark. Coordinates are pixels of the
    model picture; the box is the whole picture, a guess at the model's hood opening (re-measure it on the model)."""
    box = (0, 0, 1029, 364)
    REF = "toyoka_ae86_model_cluster.png"
    A = Art(REF, box, S=4, bg=(3, 3, 4))
    sp = Spec("ae86", box[2] - box[0], box[3] - box[1], 1.4, 1.4, box[0], box[1])  # bg 1441 x 510
    sp.redline, sp.idle = 7.6, 0.8
    S = A.S
    C1, C2 = (366.0, 258.0), (741.0, 249.0)  # speedometer, rev counter hubs
    WHT = (244, 244, 238)
    AMB = (250, 188, 44)
    PINK = (242, 70, 98)
    CREAM = (238, 234, 202)
    ORG = (226, 104, 30)
    NUMF = TECH
    SPD = [(0, -104.0), (20, -88.6), (40, -66.0), (60, -43.8), (80, -22.5), (100, 0.0), (120, 24.0), (140, 47.5), (160, 71.0), (180, 97.3)]

    def spd(v):
        for (a, x), (b, y) in zip(SPD, SPD[1:]):
            if a <= v <= b:
                return x + (y - x) * (v - a) / (b - a)
        return SPD[-1][1] + (v - 180) * 1.165

    def rev(v):
        return -116.0 + v * 25.9

    GLOW = (40, 40, 38)

    def tick(C, r0, r1, deg, w, col, glow=GLOW):
        A.line([polar(C, r0, deg), polar(C, r1, deg)], col, w, glow=glow, gw=w * 1.8)

    # ---- the speedometer: blocks every 20, a mark at every 10 and 5; amber from 100
    RO = 175.0
    for i in range(0, 37):
        v = i * 5
        col = AMB if v >= 100 else WHT
        if v % 20 == 0:
            tick(C1, RO - 26.0, RO, spd(v), 8.0, col)
        elif v % 10 == 0:
            tick(C1, RO - 15.0, RO, spd(v), 2.8, col)
        else:
            tick(C1, RO - 11.0, RO, spd(v), 2.2, col)
    NUM1 = {0: (232.3, 287.3), 20: (233.6, 251.0), 40: (245.0, 198.6), 60: (268.6, 157.7), 80: (314.0, 128.2), 100: (364.0, 114.5),
            120: (419.5, 135.0), 140: (459.5, 169.0), 160: (481.0, 218.2), 180: (481.0, 272.7)}
    for v, (x, y) in NUM1.items():
        A.text(x, y, str(v), NUMF, 22.5, WHT, scale_x=1.0, glow=GLOW)
    A.text(493.6, 307.7, "km/h", NUMF, 18.0, WHT, glow=GLOW)

    # ---- the rev counter: a mark every 100, longer every 500, long and wide every 1000; amber 7.5-7.7, red 7.8-8
    RO2 = 156.0
    for i in range(0, 81):
        v = i / 10
        col = PINK if v > 7.75 else (AMB if v > 7.45 else WHT)
        if i == 80:
            tick(C2, RO2 - 17.0, RO2, rev(v), 6.4, PINK)
        elif i % 10 == 0:
            tick(C2, RO2 - 22.0, RO2, rev(v), 5.4, col)
        elif i % 5 == 0:
            tick(C2, RO2 - 17.0, RO2, rev(v), 3.0, col)
        else:
            tick(C2, RO2 - 15.5, RO2, rev(v), 2.4, col)
    NUM2 = {0: (632.5, 302.5), 1: (619.0, 246.0), 2: (630.0, 194.0), 3: (665.0, 151.5), 4: (716.5, 125.0), 5: (769.0, 126.5), 6: (817.5, 150.0), 7: (851.0, 196.0), 8: (865.0, 251.0)}
    for v, (x, y) in NUM2.items():
        A.text(x, y, str(v), NUMF, 20.5, WHT, scale_x=1.02, glow=GLOW)
    A.text(742.0, 306.0, "x1000/min", ARIAL, 16.0, WHT, glow=GLOW)

    # ---- the stop pins either side of each hub
    for x, y in ((323.0, 256.0), (403.0, 257.5), (704.0, 251.0), (776.0, 251.0)):
        A.circle(x, y, 4.2, (58, 60, 64))

    # ---- the drums: the odometer (five drums and a grey last one) and the trip (three and the grey tenths)
    ODO = (329.0, 199.0, 399.4, 217.5)
    TRIP = (330.6, 289.5, 399.4, 307.7)
    for (x0, y0, x1, y1), n in ((ODO, 6), (TRIP, 4)):
        A.round_rect(x0 - 1.5, y0 - 1.2, x1 + 1.5, y1 + 1.2, 1.2, (10, 10, 11))
        pitch = (x1 - x0) / n
        for k in range(n):
            last = k == n - 1
            A.rect(x0 + k * pitch + 0.5, y0, x0 + (k + 1) * pitch - 0.5, y1, (70, 70, 72) if last else (14, 14, 15))
            if last:
                for yy in np.arange(y0 + 1.5, y1, 3.0):
                    A.line([(x0 + k * pitch + 1.0, yy), (x0 + (k + 1) * pitch - 1.0, yy)], (52, 52, 54), 0.8)

    # ---- the fuel bar gauge (left) and the pump
    def bar_box(x0, y0, x1, y1):
        A.round_rect(x0, y0, x1, y1, 2.0, (24, 24, 26))

    bar_box(45.0, 286.6, 157.0, 322.6)
    for a, b in ((52.0, 75.0), (77.0, 97.0), (99.0, 121.0), (125.0, 148.0)):
        A.line([(a, 292.0), (b, 292.0)], WHT, 1.8)
    A.line([(56.0, 296.4), (141.0, 296.4)], WHT, 1.8)
    A.text(57.5, 305.5, "E", ARIAL, 11.0, WHT)
    A.text(102.5, 305.5, "FUEL", ARIAL, 11.0, WHT)
    A.text(144.5, 305.5, "F", ARIAL, 11.0, WHT)
    # the pump
    A.round_rect(143.5, 328.5, 153.0, 346.0, 1.0, WHT)
    A.rect(145.2, 330.5, 151.4, 336.0, (3, 3, 4))
    A.rect(142.0, 344.6, 154.4, 347.6, WHT)
    A.line([(153.0, 333.0), (157.5, 335.5), (157.5, 343.0), (160.0, 343.4), (160.0, 333.0), (156.0, 329.0)], WHT, 1.4)

    # ---- the OIL and TEMP bar gauges (right), their icons, the still needles
    for x0, x1, labels, red in ((808.6, 902.9, (("L", 817.5), ("OIL", 854.0), ("H", 897.0)), False),
                                (917.0, 1011.0, (("C", 923.5), ("TEMP", 964.0), ("H", 999.0)), True)):
        bar_box(x0, 286.4, x1, 313.0)
        A.line([(x0 + 4.0, 289.4), (x1 - 9.0 if red else x1 - 4.0, 289.4)], WHT, 1.6)
        if not red:
            for xs in (855.0, 875.5):
                A.line([(xs, 288.2), (xs, 290.6)], (24, 24, 26), 1.2)
        A.line([(x0 + 7.0, 292.6), (x1 - 4.0, 292.6)], WHT, 1.6)
        if red:
            A.line([(x1 - 9.0, 289.0), (x1 - 2.5, 289.0)], (236, 56, 64), 2.0)
        for s, x in labels:
            A.text(x, 300.5, s, ARIAL_B, 10.5, WHT)
    for (xb, yb), (xt, yt) in (((865.0, 311.5), (871.5, 293.5)), ((961.5, 313.0), (959.5, 294.0))):
        A.line([(xb, yb), (xt, yt)], ORG, 2.6)
    # the oil can
    A.poly([(816.0, 332.0), (821.0, 332.0), (823.0, 334.5), (832.0, 334.5), (838.0, 331.0), (838.6, 332.0), (833.0, 339.5), (821.0, 339.5), (821.0, 336.0), (816.0, 334.0)], WHT)
    A.poly([(818.0, 333.0), (820.5, 333.0), (821.5, 335.0), (831.0, 335.0), (831.0, 338.6), (822.0, 338.6), (822.0, 336.0), (818.0, 334.4)], (3, 3, 4))
    A.line([(825.0, 334.5), (825.0, 331.0)], WHT, 1.2)
    A.line([(822.5, 330.6), (827.5, 330.6)], WHT, 1.2)
    A.circle(841.0, 337.5, 0.9, WHT)
    # the thermometer in the waves
    A.line([(923.5, 337.0), (923.5, 326.0)], WHT, 2.2)
    A.circle(923.5, 337.5, 2.6, WHT)
    for k in range(3):
        A.line([(924.5, 328.0 + k * 2.6), (928.0, 328.0 + k * 2.6)], WHT, 1.0)
    for dy in (340.5, 343.6):
        A.line([(913.0 + i * 2.2, dy + (0.9 if i % 2 else -0.5)) for i in range(11)], WHT, 1.1)
    # the headlamp plate
    A.rect(720.0, 325.0, 765.5, 338.5, (226, 226, 222))
    A.round_rect(735.0, 327.4, 745.5, 336.0, 1.0, (10, 10, 11))
    A.d.chord([*A.q(741.0, 327.4), *A.q(752.0, 336.0)], -90, 90, fill=(10, 10, 11))
    A.d.chord([*A.q(742.6, 329.0), *A.q(749.6, 334.4)], -90, 90, fill=(226, 226, 222))
    for k in range(3):
        A.line([(728.0, 328.8 + k * 2.8), (733.6, 328.8 + k * 2.8)], (10, 10, 11), 1.0)

    # ---- the turn arrows (teal, as on the model)
    def arrow(x, y, s):
        A.poly([(x - s * 12.5, y), (x - s * 2.0, y - 10.0), (x - s * 2.0, y - 4.6), (x + s * 12.5, y - 4.6), (x + s * 12.5, y + 4.6), (x - s * 2.0, y + 4.6), (x - s * 2.0, y + 10.0)], (38, 116, 108))

    arrow(512.5, 92.5, 1)
    arrow(610.0, 92.5, -1)

    A.final = A.finish(A.S, blur=1.4, strength=0.45)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # ---- needles: the model's cream blades, a short tail, the dark grey hub cap on top
    def blade(length, tail, w0, w1, cap, col=CREAM, r0=0.0):
        K = 4
        k = sp.A * K
        L = max(length, tail, cap) + 2
        Wd, Hd = int(2 * (max(cap, w0) + 3) * k), int(2 * L * k)
        im = Image.new("RGBA", (Wd, Hd), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        cx, cy = Wd / 2, Hd / 2
        top = cy - length * k
        bot = cy + tail * k if not r0 else cy - r0 * k
        d.polygon([(cx - w0 / 2 * k, bot), (cx + w0 / 2 * k, bot), (cx + w1 / 2 * k, top), (cx - w1 / 2 * k, top)], fill=col + (255,))
        if cap:
            g = Image.new("L", (Wd, Hd), 0)
            ImageDraw.Draw(g).ellipse([cx - cap * k, cy - cap * k, cx + cap * k, cy + cap * k], fill=255)
            sh = Image.new("RGBA", (Wd, Hd), (52, 55, 60, 255))
            im.paste(sh, (0, 0), g)
            ImageDraw.Draw(im).ellipse([cx - cap * 0.75 * k, cy - cap * 0.85 * k, cx + cap * 0.55 * k, cy + cap * 0.35 * k], fill=(62, 65, 70, 255))
        return im.resize((max(2, Wd // K), max(2, Hd // K)), Image.LANCZOS)

    add_needle(sp, blade(172.0, 42.0, 6.4, 4.6, 20.5), C1[0], C1[1], "kmh", [(v, spd(v)) for v, _ in SPD] + [(190, spd(190))])
    add_needle(sp, blade(152.0, 42.0, 6.0, 4.4, 18.5), C2[0], C2[1], "rpm", [(0, rev(0)), (8.4, rev(8.4))])
    # the fuel needle swings from a pivot under its window: only the part inside the window is drawn
    add_needle(sp, blade(55.0, 0.0, 2.8, 2.6, 0.0, ORG, r0=24.0), 100.0, 341.7, "fuel", [(0, -42.6), (1, 42.6)])

    # ---- the drums: odometer (the car's own miles) and trip
    def drum_font(name, h, pitch, chars):
        sp.font(name, ARIAL, h, "", shear=0)
        g = sp.fonts[name]["g"]
        K = 4
        k = sp.A * K
        for ch in chars:
            fo = font(ARIAL, h / 0.716 * k)
            t = Image.new("L", (int(h * 3 * k), int(h * 3 * k)), 0)
            ImageDraw.Draw(t).text((h * k * 0.5, h * k * 0.5), ch, font=fo, fill=255)
            t = t.crop(t.getbbox())
            t = t.resize((max(1, int(t.width * 0.86)), t.height), Image.LANCZOS)
            m = t.resize((max(1, round(t.width / K)), max(1, round(t.height / K))), Image.LANCZOS)
            im = Image.new("RGBA", m.size, (255, 255, 255, 0))
            im.putalpha(m)
            g[ch] = (im, (pitch - m.width / sp.A) / 2, -m.height / sp.A / 2, pitch)  # (pen at the drum's left edge)

    drum_font("odo", 14.0, (ODO[2] - ODO[0]) / 6, "0123456789")
    sp.readout("odo", ODO[2], (ODO[1] + ODO[3]) / 2, "r", 6, "odo", WHT)
    drum_font("trip", 14.0, (TRIP[2] - TRIP[0]) / 4, "0123456789")
    sp.readout("trip", TRIP[2], (TRIP[1] + TRIP[3]) / 2, "r", 5, "trip", WHT)

    sprites = {ch: {"im": Image.new("RGBA", (4, 4), (0, 0, 0, 0))} for ch in "RNP1234567"}
    sp.gear = {"x": 0, "y": 0, "sprites": sprites}
    return sp
