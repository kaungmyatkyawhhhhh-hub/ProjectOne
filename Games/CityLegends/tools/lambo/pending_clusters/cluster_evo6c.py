"""The Ronin CP9A Champion's cluster (`ronin_cp9a_champ`) as a live Spec for tools/lambo/cluster_live.py, redrawn sharp
from the model's own cluster picture (imports/refs/ronin_cp9a_champ_model_cluster.png: the .glb's 1024 px interior
picture laid on the cluster plate's mesh, upright, as the driver sees it; see its .txt). To merge: paste the function
`evo6c` into tools/lambo/cluster_imports.py (it needs only that file's own imports, the same as the header below) and see
MERGE.md, "JDM clusters (2026-11-14)"."""

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from cluster_art import ARIAL, ARIAL_B, ARIAL_BI, REG, ROBO_B, TECH, Art, font  # noqa: F401
from cluster_lfa_maybach import band_mask, blend, field, polar, smooth  # noqa: F401

HERE = os.path.dirname(os.path.abspath(__file__))

PREVIEW_INFO = {
    "game": "Ronin CP9A Champion",
    "photo": "ronin_cp9a_champ_model_cluster.png",
    "states": [dict(v=0.85, gear="N", mph=0, manual=True, clock="10:57", odo="012480", distUnit="km", kmh=True, trip="0.0", fuel=0.8),
               dict(v=5.0, gear="3", mph=49.7, manual=True, clock="10:57", odo="012493", distUnit="km", kmh=True, trip="13.2", fuel=0.62)],
}


def evo6c(Spec, needle_sprite, add_needle, glyph, solid_gear):
    """the Ronin CP9A Champion (`ronin_cp9a_champ`), redrawn sharp from the model's own cluster picture
    (imports/refs/ronin_cp9a_champ_model_cluster.png, the .glb's 1024 px interior picture laid on the cluster plate,
    2026-11-14; the model's design kept). The plate, its bevels, the screws, the empty warning-light window, the LCD and
    the dial faces are the model picture's own with every printed marking taken off (painted over from the face round
    it); every marking is drawn fresh at three times the picture's resolution: the rev counter 0-9 (x1000 r/min, a mark
    every 100, the salmon red band from 7 to 9 with white marks at 8 and 9), the speedometer 0-260 km/h (a mark every 5)
    with the inner mph ring (dots and numbers 20-140, placed true to the km/h scale), "km/h", "MPH" and the small "km/h";
    the water temperature (C - H) and fuel (E - F) gauges, whose scales turn round pivots at the right of their faces, with
    the red end blocks, the thermometer and the pump; the two teal turn arrows (the game has no indicator state for a
    cluster). Salmon italic numbers; red needles with black caps. Live: the rev needle, the speed needle (km/h as
    printed), the fuel needle, the odometer in the LCD (the car's own miles in the player's unit). Drawn still: the water
    needle at running heat (no data in the game). The model's own needle parts are not drawn (ours turn on the plate). No
    maker's mark (the picture has none on the cluster). Coordinates are pixels of the model picture; the box is the whole
    picture, a guess at the model's hood opening (re-measure it on the model)."""
    box = (0, 0, 1278, 557)
    REF = "ronin_cp9a_champ_model_cluster.png"
    A = Art(REF, box, S=3, bg=(0, 0, 0))
    sp = Spec("evo6c", box[2] - box[0], box[3] - box[1], 1.0, 0.919, box[0], box[1])  # bg 1174 x 512
    sp.redline, sp.idle = 7.5, 0.85
    S = A.S
    CT, CS = (196.4, 303.1), (635.7, 290.6)  # rev counter, speedometer
    CW, CF = (1187.0, 251.6), (1159.0, 436.5)  # water, fuel pivots (right of their faces)
    SAL = (252, 116, 102)
    SALD = (232, 96, 84)
    WHT = (240, 236, 232)
    REV = [(0, -133.0), (1, -106.0), (2, -75.4), (3, -46.4), (4, -15.4), (5, 13.5), (6, 44.6), (7, 75.4), (8, 104.6), (9, 133.5)]
    SPD = [(0, -137.5), (20, -115.0), (40, -98.7), (60, -83.6), (80, -66.5), (100, -48.6), (120, -26.6), (140, 0.0), (160, 20.9),
           (180, 40.3), (200, 58.6), (220, 76.5), (240, 93.8), (260, 113.2)]

    def lerp(tab, v):
        if v <= tab[0][0]:
            return tab[0][1] + (v - tab[0][0]) * (tab[1][1] - tab[0][1]) / (tab[1][0] - tab[0][0])
        for (a, x), (b, y) in zip(tab, tab[1:]):
            if a <= v <= b:
                return x + (y - x) * (v - a) / (b - a)
        return tab[-1][1] + (v - tab[-1][0]) * (tab[-1][1] - tab[-2][1]) / (tab[-1][0] - tab[-2][0])

    def rev(v):
        return lerp(REV, v)

    def spd(v):
        return lerp(SPD, v)

    # ---- the plate: the model picture with its printed markings painted out (from the face round them)
    ph = np.asarray(A.photo.crop(box).convert("RGB")).astype(np.float32)
    red = (ph[..., 0] - np.maximum(ph[..., 1], ph[..., 2])) > 34
    lcd = np.zeros(red.shape, bool)
    lcd[349:402, 561:704] = True
    m = Image.fromarray((red & ~lcd).astype("uint8") * 255).filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.MaxFilter(3))  # (with their dark rims)
    m = np.asarray(m).astype(np.float32) / 255
    keep = 1 - m

    def gblur(arr, r):
        return np.stack([np.asarray(Image.fromarray(np.clip(arr[..., c], 0, 255).astype("uint8")).filter(ImageFilter.GaussianBlur(r))).astype(np.float32) for c in range(arr.shape[2])], -1)

    # start from the mean of the unmarked picture round each spot (wide), then let it settle (narrow)
    den = gblur((keep * 255)[..., None], 9)[..., 0] / 255
    start = gblur(ph * keep[..., None], 9) / np.maximum(den, 1e-3)[..., None]
    img = np.where(m[..., None] > 0, start, ph)
    for k in range(30):
        img = np.where(m[..., None] > 0, gblur(img, 2), ph)
    # the faces a touch darker and even (the picture's face has a faint teal cast and pale bevels)
    base = Image.fromarray(np.clip(img, 0, 255).astype("uint8")).filter(ImageFilter.MedianFilter(3))
    A.im.paste(base.resize(A.im.size, Image.BICUBIC))
    A.d = ImageDraw.Draw(A.im)

    # the dark gap between each scale and its bezel (its shadow side, top right, the darkest), lost under the painted-out
    # marks: laid back as a soft dark ring
    arr = np.asarray(A.im).astype(np.float32)
    hh, ww = arr.shape[:2]
    yy, xx = np.mgrid[0:hh, 0:ww]
    for C, r0, r1 in ((CT, 176.5, 182.5), (CS, 216.5, 226.5)):
        px = (xx + 0.5) / S - C[0]
        py = (yy + 0.5) / S - C[1]
        r = np.hypot(px, py)
        th = np.degrees(np.arctan2(px, -py))
        k = band_mask(r, r0, r1, 1.2) * (0.55 + 0.45 * np.clip(np.cos(np.radians(th - 45)), 0, 1))
        if C == CS:
            k *= np.clip((462.0 - (py + C[1])) / 6.0, 0, 1)  # (the D face's straight bottom)
        arr = arr * (1 - k[..., None]) + np.array([8, 8, 9], np.float32) * k[..., None]
    A.im.paste(Image.fromarray(np.clip(arr, 0, 255).astype("uint8")))
    A.d = ImageDraw.Draw(A.im)

    GLOW = (70, 22, 16)

    def tick(C, r0, r1, deg, w, col=SAL):
        A.line([polar(C, r0, deg), polar(C, r1, deg)], col, w, glow=GLOW, gw=w * 1.8)

    def T(x, y, s, size, col=SAL, sx=1.0, path=ARIAL_BI):
        A.text(x, y, s, path, size, col, scale_x=sx, glow=GLOW)

    # ---- the rev counter
    for i in range(0, 91):
        v = i / 10
        if v > 7.0:
            continue
        if i % 10 == 0:
            tick(CT, 148.0, 170.0, rev(v), 4.2)
        elif i % 5 == 0:
            tick(CT, 155.0, 170.0, rev(v), 2.8)
        else:
            tick(CT, 160.0, 170.0, rev(v), 2.0)
    # the red band 7-9 and its white marks
    n = 40
    a0, a1 = rev(7.0) - 0.8, rev(9.0) + 0.6
    pts = [polar(CT, 177.0, a0 + (a1 - a0) * k / n) for k in range(n + 1)] + [polar(CT, 159.5, a1 - (a1 - a0) * k / n) for k in range(n + 1)]
    A.poly(pts, (255, 112, 102))
    A.gd.polygon([A.q(*p) for p in pts], fill=(90, 24, 18))
    tick(CT, 150.0, 177.0, rev(7.0), 3.2)
    for v, r0, r1 in ((8.0, 150.0, 178.0), (9.0, 148.0, 180.0)):
        A.line([polar(CT, r0, rev(v)), polar(CT, r1, rev(v))], WHT, 3.0)
    NUMT = {0: (95.0, 394.0), 1: (62.5, 340.0), 2: (67.5, 270.0), 3: (100.0, 215.0), 4: (156.5, 177.5), 5: (226.0, 178.5), 6: (289.0, 214.0),
            7: (327.5, 270.0), 8: (330.0, 342.5), 9: (299.0, 400.0)}
    for v, (x, y) in NUMT.items():
        T(x, y, str(v), 35.0)
    T(195.0, 369.0, "X1000", 18.5)
    T(194.0, 389.0, "r/min", 18.5)

    # ---- the speedometer: long marks every 20 and 10, short ones every 5; numbers at their own places
    for i in range(0, 53):
        v = i * 5
        if v % 20 == 0:
            tick(CS, 197.0, 216.0, spd(v), 5.0)
        elif v % 10 == 0:
            tick(CS, 199.0, 216.0, spd(v), 4.2)
        else:
            tick(CS, 206.0, 216.0, spd(v), 2.2)
    NUMS = {20: (483.0, 362.0), 40: (470.5, 316.0), 60: (471.0, 272.0), 80: (480.6, 223.3), 100: (513.9, 183.3), 120: (561.0, 141.7),
            140: (633.0, 124.4), 160: (694.4, 137.2), 180: (745.6, 161.0), 200: (775.0, 205.6), 220: (788.9, 253.9), 240: (791.7, 301.1),
            260: (783.3, 353.9)}
    for v, (x, y) in NUMS.items():
        T(x, y, str(v), 31.0)
    # the inner mph ring: a dot at each 20 mph where it falls on the km/h scale, its number inside
    for mph in range(20, 141, 20):
        a = spd(mph * 1.609)
        p = polar(CS, 134.0, a)
        A.circle(p[0], p[1], 4.4, SAL)
        q = polar(CS, 112.0, a)
        T(q[0], q[1], str(mph), 17.5)
    T(719.0, 329.0, "MPH", 13.0)
    T(514.0, 429.0, "km/h", 22.0)
    T(730.6, 383.0, "km/h", 16.0)

    # ---- the water and fuel gauges: dashes round their pivots, the red end blocks, letters and icons
    def side_scale(C, r_mid, a_lo, a_hi, n):
        for k in range(1, n):
            a = a_lo + (a_hi - a_lo) * k / n
            tick(C, r_mid - 8.0, r_mid + 8.0, a, 3.4)
        for a in (a_lo, a_hi):
            p0, p1 = polar(C, r_mid - 10.0, a), polar(C, r_mid + 10.0, a)
            A.line([p0, p1], (255, 112, 102), 9.5, glow=GLOW, gw=14.0)

    side_scale(CW, 90.0, -137.5, -41.8, 16)
    side_scale(CF, 99.0, -133.8, -45.8, 17)
    T(1097.5, 186.0, "H", 18.0, sx=1.0, path=ARIAL_B)
    T(1095.0, 318.0, "C", 18.0, path=ARIAL_B)
    T(1061.0, 368.5, "F", 18.0, path=ARIAL_B)
    T(1055.0, 503.0, "E", 18.0, path=ARIAL_B)
    # the thermometer in the waves
    x, y = 1065.0, 251.0
    A.line([(x, y - 13.0), (x, y + 4.0)], SAL, 4.6, glow=GLOW)
    for k in range(3):
        A.line([(x + 2.0, y - 10.0 + k * 4.0), (x + 7.0, y - 10.0 + k * 4.0)], SAL, 1.8)
    for dy in (7.5, 12.0):
        A.line([(x - 13.5 + i * 2.7, y + dy + (1.2 if i % 2 else -0.8)) for i in range(11)], SAL, 2.4, glow=GLOW)
    # the pump
    x, y = 1028.0, 436.5
    A.round_rect(x - 10.0, y - 12.0, x + 4.0, y + 12.0, 1.5, SAL)
    A.rect(x - 7.0, y - 9.0, x + 1.0, y - 2.0, (75, 75, 75))
    A.line([(x + 4.0, y - 5.0), (x + 9.0, y - 1.0), (x + 9.0, y + 8.0), (x + 11.5, y + 8.5), (x + 11.5, y - 6.0), (x + 7.0, y - 11.0)], SAL, 2.0)

    # ---- the turn arrows (teal, as on the model)
    def arrow(x, y, s):
        A.poly([(x - s * 22.0, y), (x - s * 3.0, y - 19.0), (x - s * 3.0, y - 8.5), (x + s * 21.0, y - 8.5), (x + s * 21.0, y + 8.5), (x - s * 3.0, y + 8.5), (x - s * 3.0, y + 19.0)], (60, 150, 140))

    arrow(422.0, 78.5, 1)
    arrow(852.0, 78.5, -1)

    # ---- the still water needle (running heat)
    A.line([polar(CW, 18.0, -90.0), polar(CW, 104.0, -90.0)], (255, 92, 64), 3.6, glow=(110, 30, 14), gw=8.0)

    A.final = A.finish(A.S, blur=1.5, strength=0.5)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # ---- needles: a red blade with a hot core, a short tail, the black cap
    def blade(length, tail, w0, w1, cap):
        K = 4
        k = sp.A * K
        L = max(length, tail, cap) + 2
        Wd, Hd = int(2 * (max(cap, w0) + 3) * k), int(2 * L * k)
        im = Image.new("RGBA", (Wd, Hd), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        cx, cy = Wd / 2, Hd / 2
        d.polygon([(cx - w0 / 2 * k, cy + tail * k), (cx + w0 / 2 * k, cy + tail * k), (cx + w1 / 2 * k, cy - length * k), (cx - w1 / 2 * k, cy - length * k)], fill=(232, 52, 34, 255))
        d.polygon([(cx - w0 * 0.16 * k, cy), (cx + w0 * 0.16 * k, cy), (cx + w1 * 0.14 * k, cy - length * 0.95 * k), (cx - w1 * 0.14 * k, cy - length * 0.95 * k)], fill=(255, 170, 130, 255))
        if cap:
            d.ellipse([cx - cap * k, cy - cap * k, cx + cap * k, cy + cap * k], fill=(14, 14, 15, 255), outline=(48, 48, 50, 255), width=int(1.0 * k))
        return im.resize((max(2, Wd // K), max(2, Hd // K)), Image.LANCZOS)

    add_needle(sp, blade(166.0, 34.0, 7.0, 4.0, 16.0), CT[0], CT[1], "rpm", [(v, rev(v)) for v, _ in REV] + [(9.3, rev(9.3))])
    add_needle(sp, blade(206.0, 40.0, 7.4, 4.2, 18.0), CS[0], CS[1], "kmh", [(v, spd(v)) for v, _ in SPD] + [(270, spd(270))])
    add_needle(sp, blade(104.0, 0.0, 4.4, 3.0, 0.0), CF[0], CF[1], "fuel", [(0, -133.8), (1, -45.8)])

    # ---- the odometer in the LCD: dark segment digits (the car's own miles in the player's unit)
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

    seg_font("odo", 26.0, 13.0, 3.4, 0.3, 17.6, "0123456789", slant=0.12)
    sp.readout("odo", 690.0, 375.5, "r", 6, "odo", (44, 46, 38))

    sprites = {ch: {"im": Image.new("RGBA", (4, 4), (0, 0, 0, 0))} for ch in "RNP1234567"}
    sp.gear = {"x": 0, "y": 0, "sprites": sprites}
    return sp
