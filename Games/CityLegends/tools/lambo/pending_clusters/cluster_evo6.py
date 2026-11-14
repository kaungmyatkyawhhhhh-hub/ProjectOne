"""The Ronin CP9A's and Ronin CT9A's cluster (`ronin_cp9a`, `ronin_ct9a`: one drawing for both) as a live Spec for
tools/lambo/cluster_live.py, redrawn from the owner's photo (imports/refs/evo_vi_gsr_evo_ix_cluster_owner.png, 547 x 365,
2026-11-14). To merge: paste the function `evo6` into tools/lambo/cluster_imports.py (it needs only that file's own
imports, the same as the header below) and see MERGE.md, "JDM clusters (2026-11-14)"."""

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from cluster_art import ARIAL, ARIAL_B, ARIAL_BI, REG, ROBO_B, TECH, Art, font  # noqa: F401
from cluster_lfa_maybach import band_mask, blend, field, polar, smooth  # noqa: F401

HERE = os.path.dirname(os.path.abspath(__file__))

PREVIEW_INFO = {
    "game": "Ronin CP9A and CT9A",
    "photo": "evo_vi_gsr_evo_ix_cluster_owner.png",
    "out": "Ronin CP9A and CT9A cluster - photo and redraw.jpg",
    "states": [dict(v=0.85, gear="N", mph=0, manual=True, clock="10:57", odo="048213", distUnit="km", kmh=True, trip="12.4", fuel=0.1),
               dict(v=5.0, gear="3", mph=49.7, manual=True, clock="10:57", odo="048226", distUnit="km", kmh=True, trip="25.6", fuel=0.62)],
}


def evo6(Spec, needle_sprite, add_needle, glyph, solid_gear):
    """the Ronin CP9A and CT9A (`ronin_cp9a`, `ronin_ct9a`: the real cars share this cluster), redrawn 1:1 from the owner's
    photo (imports/refs/evo_vi_gsr_evo_ix_cluster_owner.png, lit, 2026-11-14; the photo is small, so everything is drawn
    fresh at 2-3 picture pixels a photo pixel): a grey carbon-weave plate; left the rev counter 0-9 (a mark every 100, a
    thick red band 7-9, "X1000 r/min"), middle the speedometer 0-180 km/h (a mark every 2 km/h, the face cut straight at
    the bottom) with its LCD window (the odometer, live, dark segment digits as the real window shows them) and the trip
    knob, the grey warning-light window right of it (the belt lamp lit standing), and the two small gauges in their
    figure-eight face: water temperature (C - H, the red block at H; the needle drawn still at running heat: the game has
    no engine heat) above fuel (E - F, the pump; live). Red-lit numbers, marks and needles, dark grey hubs; the dim teal
    turn arrows over the speedometer (the game has no indicator state for a cluster). Live: rev needle, speed needle (km/h
    as printed), fuel needle, odometer (the car's own miles in the player's unit), the belt lamp. No watermark ("ABEL | ART"
    is outside the box) and no maker's mark. Coordinates are pixels of the photo; the box is a guess at the model's hood
    opening (re-measure it on the model)."""
    box = (0, 42, 512, 252)
    REF = "evo_vi_gsr_evo_ix_cluster_owner.png"
    A = Art(REF, box, S=6, bg=(13, 15, 19))
    sp = Spec("evo6", box[2] - box[0], box[3] - box[1], 3.0, 2.4, box[0], box[1])  # bg 1229 x 504
    sp.redline, sp.idle = 7.5, 0.85
    S = A.S
    CT, CS = (99.5, 160.0), (272.0, 152.5)  # rev counter, speedometer hubs
    HW, FW = (487.0, 134.0), (475.0, 205.0)  # water, fuel needle hubs
    RED = (252, 70, 58)
    RGLOW = (120, 22, 14)
    NEEDLE = (246, 46, 34)

    def rev(v):
        return -131.0 + v * 29.4

    # the speedometer's scale: closer from 0 to 20 (as printed), even from 20 on
    SPD = [(0, -123.0), (20, -105.5), (40, -81.0), (60, -55.0), (80, -29.5), (100, 0.0), (120, 29.5), (140, 55.0), (160, 81.0), (180, 105.5), (190, 118.5)]

    def spd(v):
        for (a, x), (b, y) in zip(SPD, SPD[1:]):
            if v <= b:
                return x + (y - x) * (v - a) / (b - a)
        return SPD[-1][1]

    base = np.asarray(A.im).astype(np.float32)
    h, w = base.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    PX = (xx + 0.5) / S + A.ox
    PY = (yy + 0.5) / S + A.oy

    def mask(draw_fn, blur=0.5):
        m = Image.new("L", (w, h), 0)
        draw_fn(ImageDraw.Draw(m))
        if blur:
            m = m.filter(ImageFilter.GaussianBlur(blur * S))
        return np.asarray(m).astype(np.float32) / 255

    def put(rgb, a):
        a = np.clip(a, 0, 1)[..., None]
        base[:] = base * (1 - a) + np.asarray(rgb, np.float32) * a

    def Q(pts):
        return [A.q(x, y) for x, y in pts]

    # ---- the carbon plate: a 2 x 2 twill (tows 2.2 photo px wide), each tow lit along its fibres, darker to the edges
    plate_pts = [(30, 77.5), (60, 62.5), (125, 52.5), (200, 48.5), (272, 47.5), (345, 48.5), (415, 52.5), (480, 67.5), (502, 87.5), (505, 140), (503, 205),
                 (493, 235), (450, 247), (400, 250), (132, 250), (60, 240), (20, 225), (7, 190), (7, 115), (15, 90)]
    plate = mask(lambda d: d.polygon(Q(plate_pts), fill=255), 0.6)
    c = 2.2
    u, v = PX / c, PY / c
    i, j = np.floor(u), np.floor(v)
    fu, fv = u - i, v - j
    over = ((i - j) % 4) < 2  # weft over warp
    sheen = np.where(over, np.sin(np.pi * fv), np.sin(np.pi * fu))  # bright along the tow's middle
    tone = np.where(over, 0.62, 1.0) * (0.45 + 0.55 * sheen)
    light = 0.75 + 0.25 * np.clip(1 - (PY - 50) / 200, 0, 1)
    k = tone * light
    put(np.stack([34 + 58 * k, 38 + 62 * k, 44 + 66 * k], -1), plate)
    # the plate's edge: a dark lip all round
    edge = mask(lambda d: d.polygon(Q(plate_pts), outline=255, width=int(2.2 * S)), 0.8)
    put((10, 11, 14), edge * 0.85)
    # the lower slot (the hood's lip below the speedometer)
    slot = mask(lambda d: d.rounded_rectangle([A.q(132, 226), A.q(400, 245)], radius=8 * S, fill=255), 0.6)
    put((16, 18, 22), slot)
    put((70, 76, 86), mask(lambda d: d.rounded_rectangle([A.q(134, 226), A.q(398, 228.2)], radius=2 * S, fill=255), 0.5) * 0.6)

    # ---- the faces: the rev counter's circle, the speedometer's circle cut straight at the bottom, the small gauges'
    # figure eight, the warning window; each in a thin dark bezel lip
    def face(draw_fn, col_mid, col_edge, centre, r):
        m = mask(draw_fn, 0.4)
        lip = mask(draw_fn, 0.0)
        lip = np.asarray(Image.fromarray((lip * 255).astype("uint8")).filter(ImageFilter.MaxFilter(1 + 2 * int(1.6 * S))).filter(ImageFilter.GaussianBlur(0.5 * S))).astype(np.float32) / 255
        put((12, 13, 16), lip)
        t = np.clip(np.hypot(PX - centre[0], PY - centre[1]) / r, 0, 1)
        col = np.stack([col_mid[i_] + (col_edge[i_] - col_mid[i_]) * t for i_ in range(3)], -1)
        put(col, m)

    FT = (99.5, 160.5)
    put((84, 90, 102), mask(lambda d: d.ellipse([A.q(FT[0] - 74.6, FT[1] - 74.6), A.q(FT[0] + 74.6, FT[1] + 74.6)], outline=255, width=int(1.0 * S)), 0.4) * 0.7)
    face(lambda d: d.ellipse([A.q(FT[0] - 72.0, FT[1] - 72.0), A.q(FT[0] + 72.0, FT[1] + 72.0)], fill=255), (28, 32, 38), (18, 21, 26), FT, 72.0)

    def speedo_shape(d):
        m = Image.new("L", (w, h), 0)
        md = ImageDraw.Draw(m)
        md.ellipse([A.q(CS[0] - 87.5, CS[1] - 87.5), A.q(CS[0] + 87.5, CS[1] + 87.5)], fill=255)
        md.rectangle([A.q(0, 213.0), A.q(512, 260)], fill=0)
        d.bitmap((0, 0), m, fill=255)

    face(speedo_shape, (38, 44, 54), (24, 28, 35), CS, 88.0)
    TW, TF = (463.0, 131.0), (451.0, 204.0)

    def eight(d):
        # two circles joined by smooth waists (the union blurred and cut again: rounded fillets)
        m = Image.new("L", (w, h), 0)
        md = ImageDraw.Draw(m)
        md.ellipse([A.q(TW[0] - 36.0, TW[1] - 36.0), A.q(TW[0] + 36.0, TW[1] + 36.0)], fill=255)
        md.ellipse([A.q(TF[0] - 37.0, TF[1] - 37.0), A.q(TF[0] + 37.0, TF[1] + 37.0)], fill=255)
        x0_, y0_ = [int(v_) for v_ in A.q(405, 85)]
        x1_, y1_ = [int(v_) for v_ in A.q(505, 250)]
        sub = m.crop((x0_, y0_, x1_, y1_)).filter(ImageFilter.GaussianBlur(4.0 * S)).point(lambda a_: 255 if a_ > 100 else 0)
        m.paste(sub, (x0_, y0_))
        d.bitmap((0, 0), m, fill=255)

    face(eight, (30, 34, 41), (20, 23, 28), (458.0, 168.0), 70.0)
    # the warning-light window: smoked grey, its right side a wide arc
    win_pts = [(368, 91.5)] + [polar((307.6, 150.0), 107.4, a) for a in np.linspace(57.3, 122.7, 25)] + [(368, 208.5), (365, 190), (364, 150), (365, 110)]
    face(lambda d: d.polygon(Q(win_pts), fill=255), (112, 116, 124), (92, 96, 104), (384.0, 150.0), 70.0)
    put((60, 64, 72), mask(lambda d: d.polygon(Q(win_pts), fill=255), 0.4) * np.clip((PY - 120) / 90, 0, 1) * 0.55)
    put((150, 154, 162), mask(lambda d: d.line(Q([(370, 95), (396, 95)]), fill=255, width=int(1.2 * S)), 0.8) * 0.4)
    # the LCD window under the speedometer's hub (unlit olive, as the photo)
    lcd = mask(lambda d: d.rectangle([A.q(244.4, 175.6), A.q(298.9, 195.6)], fill=255), 0.3)
    put((134, 134, 112), lcd)
    put((150, 150, 128), mask(lambda d: d.rectangle([A.q(246, 177), A.q(297.3, 184)], fill=255), 1.2) * 0.35)
    A.im.paste(Image.fromarray(np.clip(base, 0, 255).astype("uint8")))

    def tick(C, r0, r1, deg, wd, col=RED):
        A.line([polar(C, r0, deg), polar(C, r1, deg)], col, wd, glow=RGLOW, gw=wd * 2.0)

    def T(x, y, s, size, col=RED, sx=0.86, path=ARIAL_BI, stroke=0.28):
        A.text(x, y, s, path, size, col, scale_x=sx, glow=RGLOW, stroke=stroke, strokecol=col)

    # ---- rev counter: a mark every 100, longer at 500 and 1000; the thick red band 7-9 at the rim
    RO = 67.0
    for n in range(0, 91):
        val = n / 10
        if 7.0 < val < 9.0 and n % 10:
            continue
        if n % 10 == 0:
            tick(CT, RO - 8.5, RO, rev(val), 1.5)
        elif n % 5 == 0:
            tick(CT, RO - 6.0, RO, rev(val), 1.1)
        else:
            tick(CT, RO - 4.8, RO, rev(val), 1.0)
    pts = [polar(CT, RO, rev(7.0) + (rev(9.0) - rev(7.0)) * q / 40) for q in range(41)] + [polar(CT, RO - 5.2, rev(9.0) - (rev(9.0) - rev(7.0)) * q / 40) for q in range(41)]
    A.poly(pts, RED)
    A.gd.polygon([A.q(*p) for p in pts], fill=RGLOW)
    A.line([polar(CT, RO - 5.6, rev(8.0)), polar(CT, RO + 0.4, rev(8.0))], (30, 10, 8), 0.7)
    for n in range(10):
        p = polar((CT[0] + 0.1, CT[1] + 1.4), 53.8, rev(n))
        T(p[0], p[1], str(n), 13.2)
    T(101.5, 184.0, "X1000", 7.6, sx=0.9)
    T(100.5, 191.6, "r/min", 7.6, sx=0.9)

    # ---- speedometer: a mark every 2 km/h, longer at 10, long at 20
    SO = 84.0
    for n in range(0, 91):
        val = n * 2
        if val % 20 == 0:
            tick(CS, SO - 10.5, SO, spd(val), 1.8)
        elif val % 10 == 0:
            tick(CS, SO - 7.4, SO, spd(val), 1.3)
        else:
            tick(CS, SO - 5.4, SO, spd(val), 1.05)
    for val in range(0, 181, 20):
        a = spd(val)
        p = polar(CS, 65.0 - (2.4 if val >= 100 else 2.0) * abs(math.sin(math.radians(a))), a)
        T(p[0] - 0.5, p[1], str(val), 13.2)
    T(331.0, 183.5, "km/h", 7.4, sx=0.9)

    # ---- the small gauges: short marks on an arc round each needle hub
    def small(H, a0, a1, n, r0, r1, red_top):
        for q in range(n + 1):
            a = a0 + (a1 - a0) * q / n
            end = q in (0, n)
            tick(H, r0 - (1.5 if end else 0.0), r1, a, 1.3 if end else 0.95)
        if red_top:
            pts = [polar(H, r1 + 0.5, a1 + 2.0 + 9.0 * q / 8) for q in range(9)] + [polar(H, r0 - 1.0, a1 + 11.0 - 9.0 * q / 8) for q in range(9)]
            A.poly(pts, RED)
            A.gd.polygon([A.q(*p) for p in pts], fill=RGLOW)

    small(HW, -131.0, -58.0, 14, 38.5, 43.5, False)
    sq = [(456.6, 107.4), (461.4, 106.4), (462.4, 112.2), (457.6, 113.2)]  # the red block at H
    A.poly(sq, RED)
    A.gd.polygon([A.q(*p_) for p_ in sq], fill=RGLOW)
    T(447.4, 110.2, "H", 8.4, sx=0.95)
    T(446.8, 161.0, "C", 8.4, sx=0.95)
    # the thermometer icon
    A.line([(436.0, 131.0), (436.0, 138.5)], RED, 1.4, glow=RGLOW)
    A.line([(436.0, 132.5), (438.6, 132.5)], RED, 0.8, glow=RGLOW)
    A.line([(436.0, 135.0), (438.6, 135.0)], RED, 0.8, glow=RGLOW)
    A.line([(431.0, 139.6), (441.0, 139.6)], RED, 1.0, glow=RGLOW)
    A.line([(431.0, 141.8), (441.0, 141.8)], RED, 0.9, glow=RGLOW)
    small(FW, -126.0, -50.0, 12, 37.5, 42.5, False)
    T(436.6, 180.0, "F", 8.4, sx=0.95)
    T(435.6, 232.0, "E", 8.4, sx=0.95)
    # the pump icon
    A.round_rect(419.5, 200.0, 425.0, 210.5, 0.6, RED)
    A.rect(420.6, 201.4, 423.9, 204.4, (26, 26, 30))
    A.rect(418.6, 209.6, 426.0, 211.0, RED)
    A.line([(425.0, 203.0), (427.2, 204.6), (427.2, 208.8), (428.4, 208.8), (428.4, 202.8), (426.4, 200.6)], RED, 0.7, glow=RGLOW)

    # ---- the turn arrows (dim teal) and the screws, the knob
    def arrow(x, y, s):
        pts = [(x - s * 10.0, y), (x - s * 1.0, y - 7.5), (x - s * 1.0, y - 3.3), (x + s * 9.0, y - 3.3), (x + s * 9.0, y + 3.3), (x - s * 1.0, y + 3.3), (x - s * 1.0, y + 7.5)]
        A.poly(pts, (30, 78, 76))
        A.gd.polygon([A.q(*p) for p in pts], fill=(4, 16, 16))

    arrow(191.0, 67.5, 1)
    arrow(354.0, 67.5, -1)
    for C in (CT, CS):
        for s_ in (-1, 1):
            A.circle(C[0] + s_ * 24.5, C[1] + 1.0, 1.6, (40, 44, 50), outline=(10, 10, 12), w=0.4)
    A.circle(465.0, 181.0, 2.4, (44, 48, 54), outline=(12, 12, 14), w=0.4)
    A.circle(340.5, 196.0, 5.4, (30, 32, 36), outline=(8, 8, 10), w=0.5)
    A.circle(339.6, 194.8, 2.6, (70, 74, 80))
    A.circle(350.0, 202.0, 3.0, (36, 38, 42), outline=(8, 8, 10), w=0.4)
    # the still water needle (no engine heat in the game): at running heat
    a_w = -94.0
    A.line([polar(HW, 4.0, a_w), polar(HW, 37.0, a_w)], NEEDLE, 1.7, glow=RGLOW, gw=3.4)
    A.circle(HW[0], HW[1], 8.2, (60, 66, 76), outline=(26, 28, 32), w=0.6)
    A.circle(HW[0] - 1.2, HW[1] - 1.4, 4.5, (72, 78, 88))

    A.final = A.finish(A.S, blur=1.1, strength=0.55)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # ---- the belt lamp in the warning window (lit standing, as on the photo)
    def lamp(draw, bx, when, blur=0.8):
        G = Art(REF, box, S=6, bg=(0, 0, 0))
        draw(G)
        G.final = G.finish(G.S, blur=blur, strength=0.6)
        sp.add_show(sp.box(G, bx, black=True), when)

    def belt(G):
        col = (255, 60, 70)
        G.circle(400.6, 143.4, 1.6, col)
        G.line([(400.4, 145.6), (399.8, 151.0), (404.2, 151.0)], col, 1.4)
        G.line([(398.0, 145.8), (403.2, 150.4)], col, 0.7)
        G.line([(403.6, 151.0), (404.6, 154.0)], col, 1.2)
        G.gd.ellipse([G.q(397.5, 142.0), G.q(405.5, 154.0)], fill=(40, 6, 8))

    lamp(belt, (392, 138, 412, 159), "parked")

    # ---- needles: a thin red blade, a hot core, the dark grey hub cap on top
    def blade(length, tail, w0, w1, cap, cap_col=(60, 66, 76)):
        K = 4
        k = sp.A * K
        L = max(length, tail, cap) + 2
        Wd, Hd = int(2 * (max(cap, w0) + 2) * k), int(2 * L * k)
        im = Image.new("RGBA", (Wd, Hd), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        cx, cy = Wd / 2, Hd / 2
        d.polygon([(cx - w0 / 2 * k, cy + tail * k), (cx + w0 / 2 * k, cy + tail * k), (cx + w1 / 2 * k, cy - length * k), (cx - w1 / 2 * k, cy - length * k)], fill=NEEDLE + (255,))
        d.polygon([(cx - w0 * 0.16 * k, cy), (cx + w0 * 0.16 * k, cy), (cx + w1 * 0.12 * k, cy - length * 0.95 * k), (cx - w1 * 0.12 * k, cy - length * 0.95 * k)], fill=(255, 150, 120, 255))
        if cap:
            d.ellipse([cx - cap * k, cy - cap * k, cx + cap * k, cy + cap * k], fill=cap_col + (255,), outline=(24, 26, 30, 255), width=int(0.6 * k))
            d.ellipse([cx - cap * 0.62 * k - 1.0 * k, cy - cap * 0.62 * k - 1.2 * k, cx + cap * 0.62 * k - 1.0 * k, cy + cap * 0.62 * k - 1.2 * k], fill=tuple(min(255, c_ + 12) for c_ in cap_col) + (255,))
        return im.resize((max(2, Wd // K), max(2, Hd // K)), Image.LANCZOS)

    add_needle(sp, blade(70.0, 9.0, 2.6, 1.5, 11.5), CT[0], CT[1], "rpm", [(0, rev(0)), (9.3, rev(9.3))])
    add_needle(sp, blade(83.0, 10.0, 2.8, 1.6, 11.0), CS[0], CS[1], "kmh", [(0, spd(0)), (190, spd(190))])
    add_needle(sp, blade(37.0, 3.0, 1.9, 1.3, 8.2), FW[0], FW[1], "fuel", [(0, -126.0), (1, -50.0)])

    # ---- the LCD: the odometer in dark segment digits
    def seg_font(name, hh, ww, t, gap, adv, chars, slant=0.0):
        sp.font(name, ARIAL_B, hh, "", shear=0)
        g = sp.fonts[name]["g"]
        K = 4
        k = sp.A * K
        SEG = {"0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd", "6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcdfg"}
        for ch in chars:
            pad = 2
            Wd, Hd = int((ww + 2 * pad) * k), int((hh + 2 * pad) * k)
            m = Image.new("L", (Wd, Hd), 0)
            d = ImageDraw.Draw(m)
            x0, y0 = pad * k, pad * k
            W_, H_, T_, G_ = ww * k, hh * k, t * k, gap * k
            hm = H_ / 2

            def hseg(y):
                return [(x0 + G_ + T_ / 2, y), (x0 + G_ + T_, y - T_ / 2), (x0 + W_ - G_ - T_, y - T_ / 2), (x0 + W_ - G_ - T_ / 2, y), (x0 + W_ - G_ - T_, y + T_ / 2), (x0 + G_ + T_, y + T_ / 2)]

            def vseg(x, ya, yb):
                return [(x, ya + G_ + T_ / 2), (x + T_ / 2, ya + G_ + T_), (x + T_ / 2, yb - G_ - T_), (x, yb - G_ - T_ / 2), (x - T_ / 2, yb - G_ - T_), (x - T_ / 2, ya + G_ + T_)]

            P = {"a": hseg(y0 + T_ / 2), "g": hseg(y0 + hm), "d": hseg(y0 + H_ - T_ / 2),
                 "f": vseg(x0 + T_ / 2, y0 + T_ / 2, y0 + hm), "b": vseg(x0 + W_ - T_ / 2, y0 + T_ / 2, y0 + hm),
                 "e": vseg(x0 + T_ / 2, y0 + hm, y0 + H_ - T_ / 2), "c": vseg(x0 + W_ - T_ / 2, y0 + hm, y0 + H_ - T_ / 2)}
            if ch not in SEG:
                continue
            for s_ in SEG[ch]:
                d.polygon(P[s_], fill=255)
            if slant:
                m = m.transform(m.size, Image.AFFINE, (1, slant, -slant * (y0 + hm), 0, 1, 0), Image.BICUBIC)
            m = m.resize((max(1, Wd // K), max(1, Hd // K)), Image.LANCZOS)
            bb = m.getbbox()
            im = Image.new("RGBA", m.size, (255, 255, 255, 0))
            im.putalpha(m)
            ox, oy = -pad, -(pad + hh / 2)
            if bb:
                im = im.crop(bb)
                ox += bb[0] / sp.A
                oy += bb[1] / sp.A
            g[ch] = (im, ox, oy, adv)

    seg_font("odo", 9.6, 5.4, 1.15, 0.12, 7.0, "0123456789", slant=0.08)
    sp.readout("odo", 293.6, 185.6, "r", 6, "odo", (40, 42, 36))

    sprites = {ch: {"im": Image.new("RGBA", (4, 4), (0, 0, 0, 0))} for ch in "RNP1234567"}
    sp.gear = {"x": 0, "y": 0, "sprites": sprites}
    return sp
