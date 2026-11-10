"""The F82's cluster (`bnw_m4_f82`) as a live Spec for tools/lambo/cluster_live.py, redrawn from the owner's photo
(imports/refs/f82_m4_cluster_owner.png, 627 x 279, 2026-11-10). To merge: paste the function `f82` into
tools/lambo/cluster_imports.py (it needs only that file's own imports, the same as the header below) and see MERGE.md."""

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from cluster_art import ARIAL, ARIAL_B, ARIAL_BI, REG, ROBO_B, TECH, Art, font  # noqa: F401
from cluster_lfa_maybach import band_mask, blend, field, polar, smooth  # noqa: F401

HERE = os.path.dirname(os.path.abspath(__file__))


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
    Coordinates are pixels of the photo; the box is a guess at the model's hood opening (re-measure it on the model)."""
    box = (-4, 18, 631, 266)
    REF = "f82_m4_cluster_owner.png"
    A = Art(REF, box, S=6, bg=(6, 6, 7))
    sp = Spec("f82", box[2] - box[0], box[3] - box[1], 3.0, 2.06, box[0], box[1])  # bg 1308 x 511
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
