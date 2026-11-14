"""The Pleiad ZC6's cluster (`pleiad_zc6`) as a live Spec for tools/lambo/cluster_live.py, redrawn from the owner's photo
(imports/refs/brz_cluster_owner.png, 600 x 300, 2026-11-14). To merge: paste the function `brz` into
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
    "game": "Pleiad ZC6",
    "photo": "brz_cluster_owner.png",
    "states": [dict(v=0.0, gear="N", mph=0, manual=True, clock="10:57", odo="012345", distUnit="mi", kmh=False, trip="12.4", fuel=0.0),
               dict(v=5.0, gear="3", mph=49.7, manual=True, clock="10:57", odo="012358", distUnit="mi", kmh=False, trip="25.6", fuel=0.62)],
}


def brz(Spec, needle_sprite, add_needle, glyph, solid_gear):
    """the Pleiad ZC6 (`pleiad_zc6`), redrawn 1:1 from the owner's photo (imports/refs/brz_cluster_owner.png, the FA20
    coupe's cluster, 2026-11-14; a small photo, so everything is drawn fresh at about 2 picture pixels a photo pixel): the
    big rev counter in the middle (0-9 x1000 "rpm", a broken white arc with a gap at every 1000, red 7.5-9 as printed, the
    numbers inside the arc, the silver bezel with a tab at every 1000, the grey hub dome) with its two dark screens (right:
    the digital speed and its unit in the player's unit, as the real car's; low: the odometer and its unit); the
    speedometer on the left as printed (0-160 mph, a broken arc, a dot every 10, "mph"); fuel (F - E, red last quarter, the
    pump) and water temperature (H - C, red first quarter, the thermometer) on the right, two needles on their own hubs
    sweeping one outer arc; the dark (unlit) warning lights in the two columns between the dials and in the rev counter.
    Red needles. Live: the rev needle, the speed needle (mph as printed), the fuel needle, the digital speed + unit, the
    odometer + unit. Drawn still: the water needle at running heat (the photo's engine is off; the game has no engine
    temperature). No "REV LIMITER" watermark and no maker's mark. Coordinates are pixels of the photo; the box is a guess at
    the model's hood opening (re-measure it on the model)."""
    box = (2, 20, 598, 282)
    REF = "brz_cluster_owner.png"
    A = Art(REF, box, S=6, bg=(7, 7, 8))
    sp = Spec("brz", box[2] - box[0], box[3] - box[1], 2.5, 1.95, box[0], box[1])  # bg 1162 x 511
    sp.redline, sp.idle = 7.4, 0.8
    S = A.S
    C1, R1 = (118.0, 186.0), 85.3  # speedometer: centre, its arc
    C2, R2 = (300.0, 150.0), 97.5  # rev counter: centre, its arc
    HF, HW = (493.0, 151.0), (496.0, 211.0)  # fuel, water needle hubs
    WHT = (240, 240, 238)
    RED = (232, 30, 36)
    DIM = (46, 46, 48)

    def spd(v):
        return 139.6 + v * 1.486

    def rev(v):
        return -137.5 + v * 22.85

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

    # ---- the housing: the hood's dark grey lip at the top, the lighter shroud under the rev counter
    h, w = base.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    py_all = (yy + 0.5) / S + A.oy
    px_all = (xx + 0.5) / S + A.ox
    lip = np.clip((44 - py_all - 0.0006 * (px_all - 300) ** 2) / 10, 0, 1)
    base += (np.array([22, 22, 24], np.float32) * lip[..., None])
    low = Image.new("L", (w, h), 0)
    ImageDraw.Draw(low).polygon([A.q(x, y) for x, y in [(196, 282), (214, 248), (386, 248), (404, 282)]], fill=255)
    low = np.asarray(low.filter(ImageFilter.GaussianBlur(1.5 * S))).astype(np.float32) / 255
    base = base * (1 - low[..., None]) + np.array([40, 40, 42], np.float32) * low[..., None]
    # the two side lenses: dark discs with a faint grey edge
    for C, R in ((C1, 107.0), ((482.0, 185.0), 106.0)):  # (the right lens round both small gauges)
        sl, r, th, px, py = region(C, R + 3)
        put(sl, (10, 10, 11), band_mask(r, -5, R, 0.6))
        put(sl, (46, 46, 49), band_mask(r, R - 1.6, R, 0.5) * (0.5 + 0.5 * np.cos(np.radians(th - 300)) ** 2))
        put(sl, (24, 24, 26), band_mask(r, R - 13.0, R - 11.8, 0.5))
        k = np.clip(1 - r / (R - 12), 0, 1)
        put(sl, np.stack([8 + 10 * k, 8 + 10 * k, 9 + 11 * k], -1), band_mask(r, -5, R - 12.5, 0.8))
    # the rev counter: its face, a little lighter in the middle, the wide silver bezel
    sl, r, th, px, py = region(C2, 130)
    k = np.clip(1 - r / 110, 0, 1)
    put(sl, np.stack([12 + 16 * k, 12 + 16 * k, 13 + 17 * k], -1), band_mask(r, -5, 110.0, 0.6))
    lit = 60 + 70 * np.cos(np.radians(th - 270)) ** 6 + 40 * np.cos(np.radians(th - 90)) ** 6
    put(sl, np.stack([lit * 0.55, lit * 0.55, lit * 0.57], -1), band_mask(r, 110.0, 125.5, 0.5))
    for r0, r1, a in ((111.0, 113.2, 1.0), (116.6, 118.2, 0.8), (122.6, 124.4, 1.0)):
        put(sl, np.stack([lit * 1.5, lit * 1.5, lit * 1.52], -1), band_mask(r, r0, r1, 0.5) * a)
    put(sl, (6, 6, 7), band_mask(r, 125.4, 128.0, 0.6))
    # the screens: dark glass, a light edge on each side
    for x0, y0, x1, y1, cut in ((328.0, 144.0, 393.0, 184.0, None), (267.0, 205.0, 372.5, 248.0, (372.5, 226.0, 336.0, 248.0))):
        m = Image.new("L", (w, h), 0)
        pts = [(x0, y0), (x1, y0), (x1, y1), (x0, y1)] if cut is None else [(x0, y0), (x1, y0), (cut[0], cut[1]), (cut[2], cut[3]), (x0, y1)]
        ImageDraw.Draw(m).polygon([A.q(*p) for p in pts], fill=255)
        m = np.asarray(m.filter(ImageFilter.GaussianBlur(0.4 * S))).astype(np.float32) / 255
        base = base * (1 - m[..., None]) + np.array([4, 4, 5], np.float32) * m[..., None]
    A.im.paste(Image.fromarray(np.clip(base, 0, 255).astype("uint8")))
    for x0, y0, x1, y1 in ((328.0, 144.0, 393.0, 184.0), (267.0, 205.0, 372.5, 248.0)):
        A.line([(x0, y0 + 1), (x0, y1 - 1)], (120, 120, 124), 0.7)
        A.line([(x1, y0 + 1), (x1, y1 - 1 if y1 < 200 else 226.0)], (120, 120, 124), 0.7)
    # the bezel's tabs: a small silver block at every 1000
    for v in range(10):
        a = rev(v)
        c = polar(C2, 120.0, a)
        dx, dy = math.cos(math.radians(a)), math.sin(math.radians(a))
        ux, uy = math.sin(math.radians(a)), -math.cos(math.radians(a))
        pts = [(c[0] + dx * 3.0 + ux * 3.2, c[1] + dy * 3.0 + uy * 3.2), (c[0] - dx * 3.0 + ux * 3.2, c[1] - dy * 3.0 + uy * 3.2),
               (c[0] - dx * 3.0 - ux * 2.8, c[1] - dy * 3.0 - uy * 2.8), (c[0] + dx * 3.0 - ux * 2.8, c[1] + dy * 3.0 - uy * 2.8)]
        t = int(110 + 100 * math.cos(math.radians(a - 270)) ** 2) if math.cos(math.radians(a - 270)) > 0 else 110
        A.poly(pts, (t, t, t + 2))

    def arc(C, r, a0, a1, col, wd, glow=(70, 70, 70)):
        n = max(2, int(abs(a1 - a0) / 1.2))
        A.line([polar(C, r, a0 + (a1 - a0) * k / n) for k in range(n + 1)], col, wd, glow=glow, gw=wd * 2.2)

    GAP = 1.1  # degrees left open at each mark

    # ---- the rev counter's broken arc (white to 7.5, red 7.5-9), its numbers and "rpm"
    marks = [0, 1, 2, 3, 4, 5, 6, 7, 7.5, 8, 9]
    for a, b in zip(marks, marks[1:]):
        arc(C2, R2, rev(a) + GAP, rev(b) - GAP, RED if a >= 7.5 else WHT, 2.4, glow=(90, 20, 20) if a >= 7.5 else (70, 70, 70))
    A.line([polar(C2, R2, rev(0)), polar(C2, R2 - 6.0, rev(0) + 2.0)], WHT, 1.4)
    NUM = {0: (245.0, 213.0), 1: (221.0, 186.0), 2: (213.0, 155.0), 3: (218.0, 119.5), 4: (235.0, 92.0), 5: (264.0, 72.0), 6: (299.5, 65.0), 7: (333.0, 70.0), 8: (360.0, 90.5), 9: (378.0, 119.0)}
    for v, (x, y) in NUM.items():
        A.text(x, y, str(v), ARIAL_B, 17.0, WHT, glow=(70, 70, 70), scale_x=0.92)
    A.text(300.0, 82.5, "rpm", ARIAL, 9.0, (214, 214, 212), glow=(50, 50, 50))

    # ---- the speedometer's broken arc, a dot every 10 mph, the numbers every 20, "mph"
    for v in range(0, 160, 20):
        arc(C1, R1, spd(v) + GAP, spd(v + 20) - GAP, WHT if v < 140 else (176, 176, 178), 2.0)
    for v in range(10, 160, 20):
        p = polar(C1, 77.6, spd(v))
        A.circle(p[0], p[1], 0.9, (224, 224, 222))
    NUM1 = {20: (132.0, 260.0), 40: (92.0, 257.0), 60: (62.0, 234.0), 80: (46.0, 202.0), 100: (50.0, 162.0), 120: (69.0, 133.0), 140: (103.0, 112.0), 160: (141.0, 112.0)}
    for v, (x, y) in NUM1.items():
        A.text(x, y, str(v), ARIAL_B, 10.4, WHT if v < 160 else (176, 176, 178), glow=(60, 60, 60), scale_x=0.92)
    A.text(118.0, 137.5, "mph", ARIAL, 8.6, (214, 214, 212), glow=(50, 50, 50))

    # ---- the right gauge: fuel (F at the top, E, the red last quarter) and water (H, the red first quarter, C), each arc
    # round its own needle's hub (the photo's arcs drift a little off their hubs at the ends: lens / angle)
    FA0, FA1, FR = 11.0, 90.0, 57.0  # F, E (angles round HF), radius
    WA0, WA1, WR = 89.0, 168.0, 59.0  # H, C (round HW)
    for k in range(4):
        a0, a1 = FA0 + (FA1 - FA0) * k / 4, FA0 + (FA1 - FA0) * (k + 1) / 4
        arc(HF, FR, a0 + GAP * 1.6, a1 - GAP * 1.6, RED if k == 3 else WHT, 2.2, glow=(90, 20, 20) if k == 3 else (70, 70, 70))
        a0, a1 = WA0 + (WA1 - WA0) * k / 4, WA0 + (WA1 - WA0) * (k + 1) / 4
        arc(HW, WR, a0 + GAP * 1.6, a1 - GAP * 1.6, RED if k == 0 else WHT, 2.2, glow=(90, 20, 20) if k == 0 else (70, 70, 70))
    for st, x, y in (("F", 499.0, 109.0), ("E", 542.0, 158.0), ("H", 543.0, 207.0), ("C", 503.0, 255.0)):
        A.text(x, y, st, ARIAL_B, 9.6, WHT, glow=(60, 60, 60), scale_x=0.95)
    # the pump (with the filler-side arrow) and the thermometer in the waves
    col = (222, 222, 220)
    x, y = 529.0, 125.0
    A.round_rect(x - 4.6, y - 5.4, x + 1.6, y + 5.0, 0.8, None, outline=col, w=0.9)
    A.rect(x - 3.2, y - 4.0, x + 0.2, y - 1.0, col)
    A.rect(x - 5.6, y + 4.4, x + 2.6, y + 5.6, col)
    A.line([(x + 1.6, y - 2.0), (x + 3.8, y - 0.6), (x + 3.8, y + 3.4), (x + 5.0, y + 3.6), (x + 5.0, y - 3.2), (x + 3.0, y - 5.4)], col, 0.8)
    A.poly([(x + 6.6, y - 2.2), (x + 9.0, y), (x + 6.6, y + 2.2)], col)
    x, y = 535.0, 234.0
    A.line([(x, y - 6.0), (x, y + 1.6)], col, 1.2)
    for k in range(3):
        A.line([(x, y - 4.6 + k * 2.0), (x + 2.8, y - 4.6 + k * 2.0)], col, 0.7)
    A.circle(x, y + 2.0, 1.6, col)
    for dy in (4.6, 6.8):
        A.line([(x - 6.0 + i * 1.2, y + dy + (0.5 if i % 2 else -0.4)) for i in range(11)], col, 0.7)

    # ---- the dark warning lights (unlit): traced from the photo's dim prints, sharp, in a dim grey
    photo = np.asarray(A.photo.convert("L")).astype(np.float32)
    TELL = [(158, 122, 174, 133), (150, 143, 172, 152), (154, 161, 168, 175), (161, 184, 174, 196), (165, 202, 184, 217), (179, 223, 198, 233),
            (252, 130, 266, 141), (270, 111, 282, 121), (316, 105, 331, 123), (292, 99, 307, 108),
            (434, 107, 444, 120), (436, 129, 451, 140), (434, 149, 455, 159), (435, 168, 455, 186), (464, 168, 481, 182),
            (432, 199, 457, 210), (465, 191, 478, 213), (405, 221, 425, 233), (434, 222, 456, 233), (464, 221, 486, 238),
            (432, 243, 455, 259), (466, 256, 482, 270)]
    for x0, y0, x1, y1 in TELL:
        c = photo[y0:y1, x0:x1]
        bgv = np.percentile(c, 30)
        m = Image.fromarray(np.clip((c - bgv - 6) * 9, 0, 255).astype("uint8")).resize(((x1 - x0) * S, (y1 - y0) * S), Image.BICUBIC)
        m = m.filter(ImageFilter.GaussianBlur(0.6 * S)).point(lambda v: 255 if v > 110 else 0).filter(ImageFilter.GaussianBlur(0.25 * S))
        A.im.paste(Image.new("RGB", m.size, DIM), (int((x0 - A.ox) * S), int((y0 - A.oy) * S)), m)

    A.text(290.0, 238.0, "ODO", ARIAL_B, 6.6, (214, 214, 212))  # (the low screen's word; the number and unit are live)

    A.final = A.finish(A.S, blur=1.2, strength=0.5)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # ---- needles: a thin red blade with a light core, the translucent grey dome on top
    def blade(length, tail, w0, w1, dome):
        K = 4
        k = sp.A * K
        L = max(length, tail, dome) + 2
        Wd, Hd = int(2 * (max(dome, w0) + 3) * k), int(2 * L * k)
        im = Image.new("RGBA", (Wd, Hd), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        cx, cy = Wd / 2, Hd / 2
        d.polygon([(cx - w0 / 2 * k, cy + tail * k), (cx + w0 / 2 * k, cy + tail * k), (cx + w1 / 2 * k, cy - length * k), (cx - w1 / 2 * k, cy - length * k)], fill=RED + (255,))
        d.polygon([(cx - w0 * 0.14 * k, cy), (cx + w0 * 0.14 * k, cy), (cx + w1 * 0.12 * k, cy - length * 0.95 * k), (cx - w1 * 0.12 * k, cy - length * 0.95 * k)], fill=(255, 120, 110, 255))
        if dome:
            dm = Image.new("RGBA", (Wd, Hd), (0, 0, 0, 0))
            yy2, xx2 = np.mgrid[0:Hd, 0:Wd]
            rr = np.hypot(xx2 - cx, yy2 - cy) / (dome * k)
            shade = np.clip(110 - 60 * rr - 30 * ((yy2 - cy) / (dome * k)), 30, 140)
            a = np.clip((1 - rr) * dome * k / 2.0, 0, 1) * 225
            dm = Image.fromarray(np.dstack([shade, shade, shade * 1.02, a]).astype("uint8"), "RGBA")
            im.alpha_composite(dm)
        return im.resize((max(2, Wd // K), max(2, Hd // K)), Image.LANCZOS)

    add_needle(sp, blade(95.0, 15.0, 2.6, 1.6, 15.0), C2[0], C2[1], "rpm", [(0, rev(0)), (9.3, rev(9.3))])
    add_needle(sp, blade(82.0, 18.0, 2.4, 1.5, 11.0), C1[0], C1[1], "mph", [(0, spd(0)), (165, spd(165))])
    add_needle(sp, blade(FR - 1.0, 6.0, 2.4, 1.4, 8.5), HF[0], HF[1], "fuel", [(0, FA1), (1, FA0)])
    # the water needle (still, at running heat: the middle of its arc) as a piece that is always shown
    wim = blade(WR - 1.0, 6.0, 2.4, 1.4, 8.5).rotate(-(WA0 + WA1) / 2, resample=Image.BICUBIC, expand=True)
    sp.shows.append({"im": wim, "left": HW[0] - wim.width / sp.A / 2 - sp.ox, "top": HW[1] - wim.height / sp.A / 2 - sp.oy, "when": None})

    # ---- the screens: the digital speed + unit (right), the odometer + unit (low)
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
            W_, H_, T, G_ = w * k, h * k, t * k, gap * k
            hm = H_ / 2

            def hseg(y):
                return [(x0 + G_ + T / 2, y), (x0 + G_ + T, y - T / 2), (x0 + W_ - G_ - T, y - T / 2), (x0 + W_ - G_ - T / 2, y), (x0 + W_ - G_ - T, y + T / 2), (x0 + G_ + T, y + T / 2)]

            def vseg(x, ya, yb):
                return [(x, ya + G_ + T / 2), (x + T / 2, ya + G_ + T), (x + T / 2, yb - G_ - T), (x, yb - G_ - T / 2), (x - T / 2, yb - G_ - T), (x - T / 2, ya + G_ + T)]

            P = {"a": hseg(y0 + T / 2), "g": hseg(y0 + hm), "d": hseg(y0 + H_ - T / 2),
                 "f": vseg(x0 + T / 2, y0 + T / 2, y0 + hm), "b": vseg(x0 + W_ - T / 2, y0 + T / 2, y0 + hm),
                 "e": vseg(x0 + T / 2, y0 + hm, y0 + H_ - T / 2), "c": vseg(x0 + W_ - T / 2, y0 + hm, y0 + H_ - T / 2)}
            if ch in SEG:
                for s_ in SEG[ch]:
                    d.polygon(P[s_], fill=255)
                a = adv
            else:
                continue
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
            g[ch] = (im, ox, oy, a)

    seg_font("spd", 19.0, 10.6, 2.4, 0.2, 13.4, "0123456789", slant=0.08)
    sp.readout("spd", 384.0, 160.0, "r", 3, "speed", WHT)
    sp.font("unit", ARIAL_B, 6.4, "kmhp/", shear=0, track=0.1)
    sp.readout("unit", 385.0, 177.5, "r", 4, "unit", (214, 214, 212))
    sp.font("odo", ARIAL_B, 8.4, "0123456789", shear=0, track=0.35)
    sp.readout("odo", 350.0, 238.0, "r", 6, "odo", WHT)
    sp.font("du", ARIAL_B, 6.4, "kmi", shear=0)
    sp.readout("du", 353.0, 239.5, "l", 2, "distUnit", (214, 214, 212))

    sprites = {ch: {"im": Image.new("RGBA", (4, 4), (0, 0, 0, 0))} for ch in "RNP1234567"}
    sp.gear = {"x": 0, "y": 0, "sprites": sprites}
    return sp
