"""The Apex JZX100 Tourer's cluster (`toyoka_chaser`) as a live Spec for tools/lambo/cluster_live.py, redrawn from the
owner's photo (imports/refs/chaser_jzx100_cluster_owner.webp, 2026-11-14), in the coordinates of its levelled copy
imports/refs/chaser_jzx100_cluster_owner_level.png (the photo's height / 0.94: the camera looks down, the dials come out
round). To merge: paste the function `chaser` into tools/lambo/cluster_imports.py (it needs only that file's own imports,
the same as the header below) and see MERGE.md, "JDM clusters (2026-11-14)"."""

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from cluster_art import ARIAL, ARIAL_B, ARIAL_BI, REG, ROBO_B, TECH, Art, font  # noqa: F401
from cluster_lfa_maybach import band_mask, blend, field, polar, smooth  # noqa: F401

HERE = os.path.dirname(os.path.abspath(__file__))

PREVIEW_INFO = {
    "game": "Apex JZX100 Tourer",
    "photo": "chaser_jzx100_cluster_owner_level.png",
    "states": [dict(v=0.8, gear="N", mph=0, manual=True, clock="10:57", odo="025192", distUnit="km", kmh=True, trip="0.0", fuel=0.0),
               dict(v=5.0, gear="3", mph=49.7, manual=True, clock="10:57", odo="025205", distUnit="km", kmh=True, trip="12.6", fuel=0.62)],
}


def chaser(Spec, needle_sprite, add_needle, glyph, solid_gear):
    """the Apex JZX100 Tourer (`toyoka_chaser`), redrawn 1:1 from the owner's photo (imports/refs/chaser_jzx100_cluster_owner.webp,
    lit, 2026-11-14; coordinates are pixels of its levelled copy chaser_jzx100_cluster_owner_level.png): the white-lit
    speedometer 0-320 km/h (rounded white bars every 10, longer at every 20; big numbers at 40, 80 ... 320, small ones at
    20, 60 ... 300; the start 0-20 squeezed as printed) with "km/h" and the yellow-green ODO window (segment digits, the
    car's own miles in the player's unit, no leading zeros as on the photo); between the dials the P R N D column and
    3 2 L (the photo's lit P: the game's N lights P, R lights R, any forward gear lights D; the others stay dim); the rev
    counter 0-8 (bars every 200 r/min, 0-1 squeezed as printed, red 7-8) with "x1000r/min"; far left the fuel gauge
    (F - E, the pump; its pivot hides at the dial's left edge, the needle shows from under its cover), far right the
    water gauge in its bright ring (C - H, red block at H; pivot at the right edge under a dark cover). Thin grey rims
    round the big dials, the chrome lip under the rev counter, the two trip knobs. Red needles. Live: speed needle (km/h
    as printed), rev needle, fuel needle, the odometer, the lit gear letter. Drawn still: the water needle at running
    heat (as on the photo; the game has no engine temperature). No "TRD" on the speedometer, no "TRD Sportivo" plate.
    The box is a guess at the model's hood opening (re-measure it on the model)."""
    box = (-4, 232, 1284, 612)
    REF = "chaser_jzx100_cluster_owner_level.png"
    A = Art(REF, box, S=3, bg=(7, 7, 7))
    sp = Spec("chaser", box[2] - box[0], box[3] - box[1], 1.3, 1.34, box[0], box[1])  # bg 1726 x 509
    sp.redline, sp.idle = 7.0, 0.8
    S = A.S
    CS = (386.0, 438.0)  # speedometer
    CT = (869.6, 442.0)  # rev counter
    CW, PW = (1168.0, 478.0), (1251.0, 480.0)  # water gauge: ring centre, needle pivot
    CF, PF = (74.0, 482.0), (-8.0, 484.0)  # fuel gauge: rim centre, needle pivot
    WHT = (250, 250, 244)
    GLOW = (96, 96, 90)
    GLOWB = (46, 46, 42)  # (the bars' glow: less than the numbers')
    RED = (246, 64, 50)
    NEEDLE = (226, 30, 30)
    NUMF = "C:/Windows/Fonts/bahnschrift.ttf"

    def spd(v):
        if v <= 20:
            return -128.5 + v * 0.5
        return -118.5 + (v - 20) * 0.8177

    def rev(v):
        if v <= 1:
            return -125.6 + v * 24.1
        return -101.5 + (v - 1) * 32.53

    base = np.asarray(A.im).astype(np.float32)
    h, w = base.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    PX = (xx + 0.5) / S + A.ox
    PY = (yy + 0.5) / S + A.oy

    # ---- the plate: black, a faint carbon weave right of the rev counter and along the bottom
    weave = (np.sin(PX * 0.9) * np.sin(PY * 0.9) > 0).astype(np.float32)
    zone = np.clip((PX - 1060) / 40, 0, 1) + np.clip((PY - 585) / 10, 0, 1)
    tone = 7 + 9 * weave * np.clip(zone, 0, 1)
    base[:] = np.stack([tone, tone, tone * 0.98], -1)

    def put_all(rgb, a):
        a = np.clip(a, 0, 1)[..., None]
        base[:] = base * (1 - a) + np.asarray(rgb, np.float32) * a

    def rr(C):
        return np.hypot(PX - C[0], PY - C[1])

    # the big dials' faces (black) and their thin grey rims, cut by the hood's lip at the bottom
    for C in (CS, CT):
        r = rr(C)
        put_all((4, 4, 4), band_mask(r, -5, 201.0, 0.6) * (PY < 585))
        put_all((74, 74, 76), band_mask(r, 201.0, 203.2, 0.5) * (PY < 585))
    # the water gauge: the bright silver ring round a black face
    r = rr(CW)
    th = np.degrees(np.arctan2(PX - CW[0], -(PY - CW[1]))) % 360
    put_all((3, 3, 3), band_mask(r, -5, 91.0, 0.6))
    ring = 205 + 45 * np.cos(np.radians(th - 300)) ** 2
    put_all(np.stack([ring, ring, ring], -1), band_mask(r, 90.0, 99.0, 0.6))
    put_all((40, 40, 42), band_mask(r, 99.0, 100.6, 0.5))
    # the fuel gauge: only its face shows, a little lighter than the plate (its left half is outside the cluster)
    put_all((13, 13, 13), band_mask(rr(CF), -5, 97.0, 3.0))
    # the rev counter's rim catches the light on its right (a bright bevel from about 1 to 5 o'clock)
    r, th = rr(CT), np.degrees(np.arctan2(PX - CT[0], -(PY - CT[1])))
    k = np.clip((th - 22.0) / 25.0, 0, 1) * np.clip((150.0 - th) / 20.0, 0, 1) * (PY < 585)
    put_all((240, 240, 238), band_mask(r, 199.0, 205.5, 0.8) * k)
    # the chrome lip under the rev counter
    put_all((150, 150, 152), np.clip((PY - 583.0) / 1.0, 0, 1) * np.clip((587.5 - PY) / 1.2, 0, 1) * np.clip((PX - 708) / 20, 0, 1) * np.clip((1036 - PX) / 20, 0, 1))
    put_all((210, 210, 212), np.clip((PY - 584.0) / 0.7, 0, 1) * np.clip((585.6 - PY) / 0.7, 0, 1) * np.clip((PX - 760) / 60, 0, 1) * np.clip((990 - PX) / 60, 0, 1))
    A.im.paste(Image.fromarray(np.clip(base, 0, 255).astype("uint8")))

    def bar(C, r0, r1, deg, wd, col, glow=GLOW):
        """a white bar with rounded ends along a radius"""
        a, b = polar(C, r0 + wd / 2, deg), polar(C, r1 - wd / 2, deg)
        A.line([a, b], col, wd, glow=glow, gw=wd * 1.9)
        for p in (a, b):
            A.circle(p[0], p[1], wd / 2 - 0.05, col)
            A.gd.ellipse([*A.q(p[0] - wd * 0.95, p[1] - wd * 0.95), *A.q(p[0] + wd * 0.95, p[1] + wd * 0.95)], fill=glow)

    def T(x, y, s, size, col=WHT, weight=b"Bold SemiCondensed", sx=1.0, glow=GLOW, path=NUMF):
        if path == NUMF:
            font(NUMF, size * A.S * 3).set_variation_by_name(weight)
        A.text(x, y, s, path, size, col, scale_x=sx, glow=glow)

    # ---- the speedometer: bars every 10 km/h (longer at every 20), big numbers at 40, 80 ..., small at 20, 60 ...
    for v in range(0, 321, 10):
        if v % 20 == 0:
            bar(CS, 163.0, 189.0, spd(v), 5.8, WHT, GLOWB)
        else:
            bar(CS, 171.0, 189.0, spd(v), 4.6, WHT, GLOWB)
    # the numbers where the photo has them (the side ones sit a little below their bars, as printed)
    NUMS = {20: (247.0, 509.0), 40: (247.0, 474.5), 60: (236.0, 438.0), 80: (250.0, 401.0), 100: (266.0, 363.0), 120: (300.0, 332.0),
            140: (333.0, 305.0), 160: (375.0, 296.0), 180: (419.0, 294.0), 200: (458.0, 318.0), 220: (499.0, 345.0), 240: (514.0, 382.0),
            260: (530.0, 420.0), 280: (522.5, 459.5), 300: (526.0, 494.0), 320: (504.0, 530.0)}
    for v, (x, y) in NUMS.items():
        big = v % 40 == 0
        T(x, y, str(v), 32.5 if big else 15.5, weight=b"Bold")
    T(387.2, 508.5, "km/h", 19.0, path=ARIAL_B)
    T(258.0, 548.0, "0", 15.5, weight=b"SemiBold")  # (under the needle at rest)
    # the ODO window: yellow-green backlit glass, "ODO", segment digits (live, below)
    A.round_rect(305.0, 531.0, 469.5, 563.5, 2.2, (200, 182, 120), outline=(120, 108, 70), w=0.8)
    A.round_rect(307.0, 533.0, 467.5, 561.5, 1.6, (210, 192, 132))
    T(322.5, 552.0, "ODO", 12.5, (104, 92, 60), weight=b"SemiBold SemiCondensed", glow=None)

    # ---- between the dials: P R N D, then 3 2 L (dim; the lit one is the gear sprite below)
    DIM = (150, 140, 118)
    PRND = {"P": (610.0, 336.0), "R": (610.0, 378.0), "N": (610.0, 421.0), "D": (610.0, 464.0), "3": (645.0, 464.0), "2": (645.0, 506.0), "L": (645.0, 549.0)}
    for ch, (x, y) in PRND.items():
        T(x, y, ch, 26.0, DIM, weight=b"SemiBold SemiCondensed", glow=(30, 28, 24))

    # ---- the rev counter: bars every 200 r/min, wide ones at every 1000, red 7-8
    for i in range(0, 41):
        v = i / 5
        col = RED if v > 6.95 else WHT
        glow = (100, 26, 20) if v > 6.95 else GLOWB
        if i % 5 == 0:
            bar(CT, 169.0, 193.0, rev(v), 6.0, col, glow)
        else:
            bar(CT, 176.0, 191.0, rev(v), 3.3, col, glow)
    for v, (x, y) in enumerate(((742.0, 535.0), (718.0, 469.0), (729.0, 385.0), (780.0, 322.0), (857.0, 294.0), (937.0, 312.0), (994.0, 369.0), (1019.0, 450.0), (993.0, 537.0))):
        T(x, y, str(v), 34.0, weight=b"Bold")
    T(868.0, 510.0, "x1000r/min", 21.5, path=ARIAL)

    # ---- the water gauge: ticks on an arc round its pivot at the right edge, red block at H, white block at C
    def block(P, r0, r1, deg, wd, col, glow):
        a0, a1 = polar(P, r0, deg), polar(P, r1, deg)
        dx, dy = math.cos(math.radians(deg)) * wd / 2, math.sin(math.radians(deg)) * wd / 2
        pts = [(a0[0] - dx, a0[1] - dy), (a0[0] + dx, a0[1] + dy), (a1[0] + dx, a1[1] + dy), (a1[0] - dx, a1[1] - dy)]
        A.poly(pts, col)
        A.gd.polygon([A.q(*p) for p in pts], fill=glow)

    block(PW, 113.0, 127.0, -121.6, 10.0, WHT, GLOW)
    block(PW, 112.0, 128.0, -64.6, 10.5, RED, (110, 30, 24))
    for deg in (-108.4, -96.3, -84.6, -72.6):
        bar(PW, 114.0, 127.0, deg, 3.8, WHT)
    T(1170.0, 415.0, "H", 22.0, weight=b"Bold")
    T(1172.0, 540.0, "C", 22.0, weight=b"Bold")
    # the thermometer in waves
    TX, TY = 1104.0, 478.0
    A.round_rect(TX - 1.6, TY - 13.0, TX + 1.6, TY + 2.0, 1.2, WHT)
    for k in range(3):
        A.line([(TX + 1.5, TY - 10.0 + k * 3.6), (TX + 6.5, TY - 10.0 + k * 3.6)], WHT, 1.4)
    for dy in (5.5, 10.0):
        A.line([(TX - 12.0 + i * 2.4, TY + dy + (1.0 if i % 2 else -0.8)) for i in range(11)], WHT, 1.6, glow=GLOW, gw=3.0)
    # its needle at running heat, then the dark cover over the pivot
    A.line([polar(PW, 40.0, -96.0), polar(PW, 124.0, -96.0)], NEEDLE, 3.6, glow=(90, 10, 10), gw=7.0)
    m = Image.new("L", A.im.size, 0)
    ImageDraw.Draw(m).ellipse([*A.q(PW[0] - 60.0, PW[1] - 66.0), *A.q(PW[0] + 60.0, PW[1] + 66.0)], fill=255)
    face = Image.new("L", A.im.size, 0)
    ImageDraw.Draw(face).ellipse([*A.q(CW[0] - 90.5, CW[1] - 90.5), *A.q(CW[0] + 90.5, CW[1] + 90.5)], fill=255)
    from PIL import ImageChops

    m = ImageChops.multiply(m.filter(ImageFilter.GaussianBlur(2.0 * S)), face)
    A.im.paste(Image.new("RGB", A.im.size, (20, 20, 22)), (0, 0), m)

    # ---- the fuel gauge: ticks on an arc round its pivot at the left edge, F and E blocks, the pump
    block(PF, 125.0, 139.0, 61.0, 10.0, WHT, GLOW)
    block(PF, 126.0, 140.0, 118.5, 10.0, WHT, GLOW)
    for deg, r0 in ((75.5, 127.0), (104.0, 127.0)):
        bar(PF, r0, 138.0, deg, 3.8, WHT)
    block(PF, 125.0, 133.0, 90.0, 5.0, WHT, GLOW)  # (the half mark: a short wide dash)
    T(80.0, 418.0, "F", 22.0, weight=b"Bold")
    T(82.0, 545.0, "E", 22.0, weight=b"Bold")
    PX0, PY0 = 148.0, 485.0
    A.round_rect(PX0 - 8.0, PY0 - 11.5, PX0 + 3.5, PY0 + 11.5, 1.4, WHT)
    A.rect(PX0 - 5.8, PY0 - 8.8, PX0 + 1.3, PY0 - 3.0, (8, 8, 8))
    A.rect(PX0 - 9.5, PY0 + 10.5, PX0 + 5.0, PY0 + 12.8, WHT)
    A.line([(PX0 + 3.5, PY0 - 4.5), (PX0 + 8.5, PY0 - 1.0), (PX0 + 8.5, PY0 + 7.0), (PX0 + 11.5, PY0 + 7.5), (PX0 + 11.5, PY0 - 7.0), (PX0 + 7.0, PY0 - 11.5)], WHT, 1.7, glow=GLOW, gw=3.4)

    # ---- the trip knobs (chrome stalks in front of the face, pointing in towards the dials)
    for x, y, s in ((152.0, 581.0, 1), (1094.0, 574.0, -1)):
        A.line([(x + s * 4.0, y + 6.0), (x + s * 6.0, y + 30.0)], (70, 72, 76), 3.0)
        A.line([(x, y - 1.0), (x + s * 46.0, y - 13.0)], (60, 62, 66), 8.0)
        A.line([(x, y - 3.0), (x + s * 46.0, y - 15.0)], (176, 180, 186), 2.2)
        A.circle(x, y + 2.0, 9.5, (14, 14, 16))
        A.circle(x, y, 8.5, (120, 124, 130), outline=(210, 214, 220), w=1.2)
        A.circle(x - 2.0, y - 2.0, 3.0, (236, 238, 242))

    A.final = A.finish(A.S, blur=1.8, strength=0.7)
    # (one colour all round the edge: Roblox's small copies blend the top row with the bottom one)
    ImageDraw.Draw(A.final).rectangle([0, 0, A.final.width - 1, A.final.height - 1], outline=(7, 7, 7), width=3 * S)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # ---- needles: a thin red blade from the hub (no cap shows on the photo); the fuel needle only from under its cover
    def blade(r0, length, w0, w1, glow=True):
        K = 4
        k = sp.A * K
        L = length + 4
        Wd, Hd = int(2 * (w0 + 5) * k), int(2 * L * k)
        im = Image.new("RGBA", (Wd, Hd), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        cx, cy = Wd / 2, Hd / 2
        if glow:
            g = Image.new("RGBA", (Wd, Hd), (0, 0, 0, 0))
            ImageDraw.Draw(g).polygon([(cx - w0 * 1.2 * k, cy - r0 * k), (cx + w0 * 1.2 * k, cy - r0 * k), (cx + w1 * 1.4 * k, cy - length * k), (cx - w1 * 1.4 * k, cy - length * k)], fill=(150, 0, 0, 110))
            im.alpha_composite(g.filter(ImageFilter.GaussianBlur(1.6 * k)))
        d = ImageDraw.Draw(im)
        d.polygon([(cx - w0 / 2 * k, cy - r0 * k), (cx + w0 / 2 * k, cy - r0 * k), (cx + w1 / 2 * k, cy - length * k), (cx - w1 / 2 * k, cy - length * k)], fill=NEEDLE + (255,))
        d.polygon([(cx - w0 * 0.12 * k, cy - r0 * k), (cx + w0 * 0.12 * k, cy - r0 * k), (cx + w1 * 0.1 * k, cy - length * 0.97 * k), (cx - w1 * 0.1 * k, cy - length * 0.97 * k)], fill=(255, 96, 80, 255))
        return im.resize((max(2, Wd // K), max(2, Hd // K)), Image.LANCZOS)

    add_needle(sp, blade(-2.0, 186.0, 4.6, 3.4), CS[0], CS[1], "kmh", [(0, spd(0)), (20, spd(20)), (330, spd(330))])
    add_needle(sp, blade(-2.0, 182.0, 4.6, 3.4), CT[0], CT[1], "rpm", [(0, rev(0)), (1, rev(1)), (8.4, rev(8.4))])
    add_needle(sp, blade(72.0, 133.0, 4.2, 3.4), PF[0], PF[1], "fuel", [(0, 118.5), (1, 61.0)])

    # ---- the ODO digits: dark segments on the yellow-green glass, slanted like the photo's
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
            W_, H_, T_, G = w * k, h * k, t * k, gap * k
            hm = H_ / 2

            def hseg(y):
                return [(x0 + G + T_ / 2, y), (x0 + G + T_, y - T_ / 2), (x0 + W_ - G - T_, y - T_ / 2), (x0 + W_ - G - T_ / 2, y), (x0 + W_ - G - T_, y + T_ / 2), (x0 + G + T_, y + T_ / 2)]

            def vseg(x, ya, yb):
                return [(x, ya + G + T_ / 2), (x + T_ / 2, ya + G + T_), (x + T_ / 2, yb - G - T_), (x, yb - G - T_ / 2), (x - T_ / 2, yb - G - T_), (x - T_ / 2, ya + G + T_)]

            P = {"a": hseg(y0 + T_ / 2), "g": hseg(y0 + hm), "d": hseg(y0 + H_ - T_ / 2),
                 "f": vseg(x0 + T_ / 2, y0 + T_ / 2, y0 + hm), "b": vseg(x0 + W_ - T_ / 2, y0 + T_ / 2, y0 + hm),
                 "e": vseg(x0 + T_ / 2, y0 + hm, y0 + H_ - T_ / 2), "c": vseg(x0 + W_ - T_ / 2, y0 + hm, y0 + H_ - T_ / 2)}
            for s in SEG[ch]:
                d.polygon(P[s], fill=255)
            if slant:
                m = m.transform(m.size, Image.AFFINE, (1, slant, -slant * (y0 + hm), 0, 1, 0), Image.BICUBIC)
            m = m.resize((max(1, Wd // K), max(1, Hd // K)), Image.LANCZOS)
            bb = m.getbbox()
            im = Image.new("RGBA", m.size, (255, 255, 255, 0))
            im.putalpha(m)
            ox, oy = -pad, -(pad + h / 2)
            if bb:
                im = im.crop(bb)
                ox += bb[0] / sp.A
                oy += bb[1] / sp.A
            g[ch] = (im, ox, oy, adv)

    seg_font("odo", 21.0, 11.0, 2.4, 0.25, 18.6, "0123456789", slant=0.2)
    sp.readout("odo", 466.0, 547.5, "r", 6, "odoTrim", (64, 56, 34))

    # ---- the lit gear letter: one canvas over the column, the letter at its own place
    def lit(ch):
        K = 4
        k = sp.A * K
        x0, y0, x1, y1 = 592.0, 316.0, 628.0, 484.0
        Wd, Hd = int((x1 - x0) * k), int((y1 - y0) * k)
        m = Image.new("L", (Wd, Hd), 0)
        x, y = PRND[ch]
        fo = font(NUMF, 26.0 / 0.70 * k)
        fo.set_variation_by_name(b"SemiBold SemiCondensed")
        t = Image.new("L", (int(40 * k), int(40 * k)), 0)
        ImageDraw.Draw(t).text((6 * k, 2 * k), ch, font=fo, fill=255)
        t = t.crop(t.getbbox())
        m.paste(t, (int((x - x0) * k - t.width / 2), int((y - y0) * k - t.height / 2)), t)
        glow = m.filter(ImageFilter.GaussianBlur(2.2 * k)).point(lambda a: int(a * 0.55))
        out = Image.new("RGBA", (Wd, Hd), (236, 226, 196, 0))
        out.putalpha(ImageChops.lighter(m, glow))
        return out.resize((Wd // K, Hd // K), Image.LANCZOS)

    sprites = {"N": {"im": lit("P")}, "R": {"im": lit("R")}}
    sprites["P"] = sprites["N"]
    d_im = lit("D")
    for ch in "1234567":
        sprites[ch] = {"im": d_im}
    sp.gear = {"x": (592.0 + 628.0) / 2 - sp.ox, "y": (316.0 + 484.0) / 2 - sp.oy, "sprites": sprites}
    return sp
