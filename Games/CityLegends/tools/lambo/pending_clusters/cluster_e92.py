"""The E92 V8's cluster (`bnw_m3_e92`) as a live Spec for tools/lambo/cluster_live.py, redrawn from the OWNER's photo
(imports/refs/e92_m3_cluster_owner.png, 2026-11-10). To merge: paste the function `e92` into
tools/lambo/cluster_imports.py (it needs only that file's own imports, the same as the header below) and see MERGE.md."""

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from cluster_art import ARIAL, ARIAL_B, ARIAL_BI, REG, ROBO_B, TECH, Art, font  # noqa: F401
from cluster_lfa_maybach import band_mask, blend, field, polar, smooth  # noqa: F401

HERE = os.path.dirname(os.path.abspath(__file__))


def e92(Spec, needle_sprite, add_needle, glyph, solid_gear):
    """the Bavarica Werkz E92 V8 (`bnw_m3_e92`), redrawn 1:1 from the owner's photo (imports/refs/e92_m3_cluster_owner.png,
    2026-11-10; it replaces the 2026-11-09 redraw from a Wikimedia photo): two black dials in satin rings (a bright inner
    bevel, a flat ring, lit from below as on the photo), the speedometer 0-330 km/h (labels every 20 to 120, then every
    30; bars on the labels, dots every 10; the needle follows km/h, as printed), its fuel scale 0 - 1/2 - 1 low in it with
    its own needle (live), the rev counter 0-9 "1/min x 1000" (bars on the thousands, dots on the halves) with the nine
    dark slots in its ring over the top and the photo's lit warm-up band in its bevel (yellow 6,650-7,150, red 7,200-9,000:
    the cold engine of the photo, drawn as it is), the oil scale 50-100-150 C low in it (the needle drawn where the photo
    has it, cold), red needles over big dark slotted caps; between the dials the dark lamp field (lamps unlit, the DSC-off
    lamp lights with traction control off and the belt lamp while standing) over the orange display: the upper screen
    (blank, as on the photo), the lower one with the gear (P standing,
    R, D1-D7), "km" (live unit), the odometer and the trip (live). The M logo on the rev counter is left out (blank).
    Coordinates are pixels of the photo. The box is the model's hood opening (274 x 114 mm, tools/lambo/window_e92.png)
    laid on the photo so the photo's dial centres sit on the model's (137.7 mm apart): 1 px = 0.17 mm."""
    from cluster_lfa_maybach import angular

    box = (138, 316, 1754, 988)
    REF = "e92_m3_cluster_owner.png"
    A = Art(REF, box, S=2, bg=(7, 8, 6))
    sp = Spec("e92", box[2] - box[0], box[3] - box[1], 1.0, 0.76, box[0], box[1])  # bg 1228 x 511 (halves 614 x 511)
    sp.redline, sp.idle = 8.3, 0.9
    C1, C2 = (546.4, 657.9), (1358.6, 657.9)  # speedometer, rev counter (the dots' circles on the photo)
    INK = (220, 222, 207)  # the dials' print: warm white
    RED = (216, 36, 18)  # the needles
    LCD = (254, 160, 30)  # the display's characters
    LCD_BG = (100, 8, 2)
    S = A.S

    # ---- the housing (under the rings): the lamp field (dark glass), the display's frame
    A.round_rect(705, 338, 1068, 598, 10, (10, 10, 9))
    A.round_rect(850, 600, 1072, 932, 8, (12, 12, 10))

    # ---- shading in numpy: the faces and the rings
    base = np.asarray(A.im).astype(np.float32)

    def region(C, R):
        x0, x1 = max(0, int((C[0] - R - A.ox) * S)), min(A.W * S, int((C[0] + R - A.ox) * S) + 2)
        y0, y1 = max(0, int((C[1] - R - A.oy) * S)), min(A.H * S, int((C[1] + R - A.oy) * S) + 2)
        yy, xx = np.mgrid[y0:y1, x0:x1]
        px = (xx + 0.5) / S + A.ox - C[0]
        py = (yy + 0.5) / S + A.oy - C[1]
        return (slice(y0, y1), slice(x0, x1)), np.hypot(px, py), np.degrees(np.arctan2(px, -py)) % 360, py

    def put(sl, rgb, a):
        a = a[..., None]
        base[sl] = base[sl] * (1 - a) + rgb * a

    ANG = list(range(0, 360, 15))
    # the rings' light by angle (median brightness on the photo, 15 degree steps from the top, clockwise), each band
    # at its middle radius: the inner bevel (253-271), the flat ring (271-300), its outer edge (300-306)
    RINGS = {
        C1: [(255.5, [202, 212, 227, 233, 235, 237, 237, 235, 235, 30, 30, 30, 30, 30, 30, 30, 131, 132, 138, 154, 156, 161, 177, 196]),
             (261.0, [152, 160, 184, 210, 213, 213, 213, 203, 193, 24, 24, 24, 24, 24, 24, 24, 140, 145, 152, 157, 155, 157, 161, 160]),
             (267.5, [117, 109, 131, 149, 157, 157, 156, 155, 153, 22, 22, 22, 24, 25, 30, 31, 186, 182, 172, 171, 165, 161, 148, 133]),
             (277.0, [142, 111, 60, 50, 52, 62, 85, 124, 70, 50, 62, 92, 131, 177, 222, 233, 167, 159, 161, 174, 171, 165, 163, 158]),
             (290.0, [70, 60, 46, 40, 42, 52, 72, 118, 73, 52, 66, 104, 142, 183, 217, 230, 230, 243, 225, 153, 110, 90, 80, 74]),
             (300.0, [40, 36, 36, 40, 73, 105, 113, 112, 89, 60, 65, 50, 52, 127, 199, 217, 222, 240, 224, 169, 106, 66, 46, 40]),
             (304.5, [18, 18, 14, 12, 17, 21, 40, 46, 44, 12, 8, 6, 6, 6, 8, 14, 37, 120, 110, 90, 60, 40, 28, 22])],
        C2: [(255.5, [198, 187, 160, 158, 141, 111, 74, 80, 68, 30, 30, 30, 30, 31, 32, 32, 218, 208, 213, 224, 217, 216, 212, 217]),
             (261.0, [198, 187, 160, 158, 141, 111, 74, 80, 68, 24, 24, 24, 25, 31, 32, 32, 218, 208, 213, 224, 217, 216, 212, 217]),
             (267.5, [170, 141, 115, 111, 95, 86, 52, 59, 62, 22, 22, 22, 31, 36, 35, 34, 228, 219, 208, 209, 215, 217, 208, 197]),
             (277.0, [162, 171, 158, 172, 134, 88, 75, 85, 48, 45, 77, 148, 209, 242, 248, 239, 248, 236, 226, 214, 166, 133, 112, 150]),
             (290.0, [140, 140, 126, 134, 94, 54, 43, 47, 40, 43, 92, 163, 215, 244, 248, 240, 249, 250, 238, 201, 150, 123, 110, 128]),
             (300.0, [40, 36, 40, 40, 36, 32, 40, 46, 39, 51, 100, 138, 60, 60, 80, 223, 246, 249, 238, 205, 156, 127, 97, 50]),
             (304.5, [20, 16, 12, 14, 14, 14, 16, 18, 16, 10, 9, 8, 7, 7, 7, 9, 56, 57, 55, 41, 17, 13, 16, 30])],
    }
    for C in (C1, C2):
        sl, r, th, py = region(C, 309)
        v = 12.0 + 4.0 * np.clip((py + 150) / 400, 0, 1)
        put(sl, np.stack([v * 0.95, v * 1.05, v * 0.86], axis=-1), band_mask(r, -5, 253.5, 0.7))
        bands = RINGS[C]
        val = np.zeros(r.shape, np.float32)
        for i, (rc, vals) in enumerate(bands):
            prof = angular(th, list(zip(ANG, vals)))
            lo = bands[i - 1][0] if i > 0 else rc - 2.5
            hi = bands[i + 1][0] if i + 1 < len(bands) else rc + 1.5
            w = np.where(r < rc, np.clip((r - lo) / max(rc - lo, 1e-3), 0, 1), np.clip((hi - r) / max(hi - rc, 1e-3), 0, 1))
            if i == 0:
                w = np.where(r < rc, 1.0, w)
            if i == len(bands) - 1:
                w = np.where(r > rc, 1.0, w)
            val += prof * w
        put(sl, np.stack([val, val * 0.995, val * 0.955], axis=-1), band_mask(r, 253.5, 306.5, 0.7))
        # the sharp bright lip where the bevel meets the face (top and sides), a dark seam where it meets the flat ring
        lip = 0.55 * np.clip(np.cos(np.radians((th - 40) * 0.75)), 0, 1)
        put(sl, np.full(r.shape + (3,), 246.0), band_mask(r, 253.6, 255.4, 0.5) * lip)
        put(sl, np.full(r.shape + (3,), 30.0), band_mask(r, 270.4, 271.8, 0.5) * 0.45)
    A.im.paste(Image.fromarray(np.clip(base, 0, 255).astype("uint8")))

    def bar(p0, p1, w, col):
        A.line([p0, p1], col, w)
        for p in (p0, p1):
            A.circle(p[0], p[1], w / 2, col)

    def tick(C, r0, r1, deg, w, col):
        bar(polar(C, r0, deg), polar(C, r1, deg), w, col)

    # ---- speedometer: 0-120 every 20 (9.92 degrees per 10 km/h), then every 30 (6.635 per 10)
    SPD = [(0, -129.36), (120, -10.33), (330, 128.99)]

    def kph(v):
        return -129.36 + 0.992 * v if v <= 120 else -10.33 + 0.6635 * (v - 120)

    LAB = (0, 20, 40, 60, 80, 100, 120, 150, 180, 210, 240, 270, 300, 330)
    for v in range(0, 331, 10):
        if v in LAB:
            tick(C1, 226.5, 247.0, kph(v), 8.4, INK)
        else:
            p = polar(C1, 245.6, kph(v))
            A.circle(p[0], p[1], 4.2, INK)
    NUM1 = {0: (391.5, 782.0), 20: (365.5, 721.0), 40: (352.0, 654.0), 60: (363.0, 589.0), 80: (396.0, 531.0), 100: (442.5, 486.0),
            120: (508.0, 459.0), 150: (583.5, 460.0), 180: (646.5, 488.0), 210: (693.0, 531.0), 240: (722.5, 588.0),
            270: (734.5, 652.0), 300: (722.5, 719.5), 330: (688.0, 779.0)}
    for v, (x, y) in NUM1.items():
        A.text(x, y + 1, str(v), ARIAL_B, 39.0, INK, scale_x=0.85, track=-1.6 if v >= 100 else 0.0)
    A.text(546, 558.5, "km/h", ARIAL_B, 23.0, (236, 238, 230), scale_x=0.89)

    # the fuel scale low in the speedometer: its marks sit on the dial's own circle and point at the fuel needle's hub
    HF = (C1[0] + 1.0, C1[1] + 106.0)

    def sub_bar(c, hub, length, w, col):
        d = (hub[0] - c[0], hub[1] - c[1])
        L = math.hypot(*d)
        u = (d[0] / L, d[1] / L)
        bar((c[0] - u[0] * length / 2, c[1] - u[1] * length / 2), (c[0] + u[0] * length / 2, c[1] + u[1] * length / 2), w, col)

    def sub_scale(C, hub, side, mid, dots):
        for s in (-1, 1):
            sub_bar((C[0] + s * side[0], C[1] + side[1]), hub, 26.0, 8.2, INK)
            A.circle(C[0] + s * dots[0], C[1] + dots[1], 4.2, INK)
        sub_bar((C[0], C[1] + mid), hub, 22.0, 7.6, INK)

    sub_scale(C1, HF, (120.4, 201.9), 240.8, (64.0, 238.1))
    A.text(452.5, 839.0, "0", ARIAL_B, 28.5, INK, scale_x=0.85)
    A.text(548.0, 870.5, "1/2", ARIAL_B, 26.5, INK, scale_x=0.86)
    A.text(644.0, 840.0, "1", ARIAL_B, 28.5, INK, scale_x=0.85)
    # the pump
    A.round_rect(540.0, 810.5, 555.0, 836.5, 2.0, INK)
    A.round_rect(542.6, 813.2, 552.4, 822.0, 1.0, (14, 15, 12))
    A.rect(537.6, 834.0, 557.4, 837.2, INK)
    A.line([(555.0, 815.5), (559.5, 818.5), (560.5, 830.5), (558.0, 833.5), (556.0, 831.5)], INK, 1.8)

    # ---- rev counter 0-9: 28.66 degrees a thousand, 4,500 at the top
    def rev(v):
        return (v - 4.5) * 28.66

    for i in range(0, 19):
        v = i / 2
        if i % 2 == 0:
            tick(C2, 226.5, 248.5, rev(v), 8.8, INK)
        else:
            p = polar(C2, 245.7, rev(v))
            A.circle(p[0], p[1], 4.2, INK)
    NUM2 = {0: (1203.0, 778.5), 1: (1152.0, 693.0), 2: (1168.0, 592.5), 3: (1225.0, 511.5), 4: (1307.5, 465.0), 5: (1409.0, 465.0),
            6: (1493.5, 513.0), 7: (1549.5, 595.0), 8: (1557.5, 694.5), 9: (1517.5, 779.0)}
    for v, (x, y) in NUM2.items():
        A.text(x, y + 0.5, str(v), ARIAL_B, 48.4, INK, scale_x=0.86)
    A.text(1359.0, 520.5, "1/min x 1000", ARIAL_B, 23.5, (230, 232, 224), scale_x=0.84)
    # (the M logo's spot under it stays blank)

    # the nine dark slots in the ring over the top
    for k in range(9):
        a0 = -34.2 + 8.96 * k
        pts = [polar(C2, 297.5, a0 - 3.2 + 6.4 * t / 8) for t in range(9)] + [polar(C2, 284.5, a0 + 3.2 - 6.4 * t / 8) for t in range(9)]
        A.poly(pts, (16, 16, 15))
        A.line(pts + [pts[0]], (96, 96, 94), 1.0)

    # the warm-up band in the bevel, lit as on the photo: three yellow segments, then red to 9
    def bevel_band(a0, a1, col, r0=253.8, r1=270.0, glow=None):
        n = max(2, int((a1 - a0) / 1.0))
        pts = [polar(C2, r1, a0 + (a1 - a0) * t / n) for t in range(n + 1)] + [polar(C2, r0, a1 - (a1 - a0) * t / n) for t in range(n + 1)]
        A.poly(pts, col)
        if glow:
            A.gd.polygon([A.q(*p) for p in pts], fill=glow)

    for a0, a1, col in ((62.0, 66.2, (226, 150, 34)), (66.8, 71.0, (238, 178, 58)), (71.6, 76.4, (232, 140, 28))):
        bevel_band(a0, a1, col, glow=(90, 50, 8))
    n = 40
    a0, a1 = 78.0, 129.2
    pts = [polar(C2, 270.0, a0 + (a1 - a0) * t / n) for t in range(n + 1)]
    pts += [polar(C2, 253.8 - 2.6 * smooth(100.0, 128.0, a1 - (a1 - a0) * t / n), a1 - (a1 - a0) * t / n) for t in range(n + 1)]
    A.poly(pts, (222, 58, 16))
    A.gd.polygon([A.q(*p) for p in pts], fill=(110, 20, 4))

    # the oil scale low in the rev counter, its needle where the photo has it (cold, at 50)
    HO = (C2[0] - 1.6, C2[1] + 106.0)
    sub_scale(C2, HO, (122.3, 204.6), 243.1, (64.4, 239.6))
    A.text(1268.0, 840.5, "50", ARIAL_B, 28.8, INK, scale_x=0.82)
    A.text(1358.0, 872.5, "100", ARIAL_B, 28.8, INK, scale_x=0.82)
    A.text(1443.5, 840.5, "150", ARIAL_B, 28.8, INK, scale_x=0.82)
    A.text(1387.0, 821.5, "°C", ARIAL_B, 23.0, INK, scale_x=0.8)
    # the oil can: body, lid, the spout and a drop
    A.line([(1323.0, 815.5), (1331.5, 819.5), (1336.0, 828.5), (1356.0, 828.5), (1366.5, 816.5)], INK, 2.2)
    A.line([(1336.0, 828.5), (1335.0, 819.5), (1352.5, 819.5), (1356.0, 828.5)], INK, 2.2)
    A.line([(1341.0, 819.5), (1341.0, 816.5), (1347.0, 816.5), (1347.0, 819.5)], INK, 1.8)
    A.circle(1370.0, 823.5, 1.9, INK)

    # ---- the display between the dials: the upper screen (blank) and the lower one
    A.poly([(880.8, 644.0), (1028.0, 644.0), (1040.0, 752.7), (867.3, 752.7)], (50, 13, 2))
    A.poly([(842.0, 766.0), (1044.0, 766.0), (1067.0, 805.0), (1067.0, 914.0), (835.0, 914.0), (835.0, 812.0)], LCD_BG)
    sl, r, th, py = region((954.0, 780.0), 160)
    t = np.clip((py + 136) / 108, 0, 1)
    shade = np.stack([44 + 18 * t, 11 + 4 * t, 2 + 0 * t], axis=-1)
    mim = Image.new("L", (sl[1].stop - sl[1].start, sl[0].stop - sl[0].start), 0)
    ImageDraw.Draw(mim).polygon([((x - A.ox) * S - sl[1].start, (y - A.oy) * S - sl[0].start) for x, y in
                                 [(881.3, 644.5), (1027.5, 644.5), (1039.5, 752.2), (867.8, 752.2)]], fill=255)
    m = np.asarray(mim).astype(np.float32) / 255
    cur = np.asarray(A.im).astype(np.float32)
    cur[sl] = cur[sl] * (1 - m[..., None]) + shade * m[..., None]
    A.im.paste(Image.fromarray(np.clip(cur, 0, 255).astype("uint8")))
    # the line under the odometer, broken where the unit stands
    A.line([(839.5, 878.8), (847.0, 878.8)], LCD, 1.6)
    A.line([(876.5, 878.8), (1066.0, 878.8)], LCD, 1.6)
    # the display's soft light on the frame and the rings near it
    A.gd.polygon([A.q(x, y) for x, y in [(842.0, 766.0), (1044.0, 766.0), (1067.0, 805.0), (1067.0, 914.0), (835.0, 914.0), (835.0, 812.0)]], fill=(60, 8, 2))
    A.gd.polygon([A.q(x, y) for x, y in [(880.8, 644.0), (1028.0, 644.0), (1040.0, 752.7), (867.3, 752.7)]], fill=(30, 7, 1))

    # ---- the lamp field: unlit lamps, as faint as on the photo
    dim = (17, 17, 15)
    A.circle(874.0, 425.0, 13.0, None, outline=dim, w=1.6)
    A.text(874.0, 425.5, "ABS", ARIAL_B, 9.0, dim)
    A.circle(955.0, 433.0, 12.0, None, outline=dim, w=1.8)
    for k in range(4):
        A.line([(926.0, 425.0 + k * 5.5), (940.0, 425.0 + k * 5.5)], dim, 1.6)
    A.round_rect(931.0, 486.0, 966.0, 503.0, 3.0, None, outline=dim, w=1.6)
    A.line([(936.0, 494.5), (961.0, 494.5)], dim, 1.4)

    def belt(G, col):  # the seat-belt lamp: a figure in a seat, the belt across
        G.circle(1020.0, 420.0, 4.2, col)
        G.line([(1018.0, 426.0), (1016.0, 441.0), (1028.0, 441.0)], col, 3.2)
        G.line([(1012.0, 426.0), (1025.0, 438.0)], col, 1.8)
        G.line([(1026.0, 441.0), (1029.0, 450.0)], col, 3.0)

    def dsc(G, col):  # traction control off: the car on wavy tracks, "OFF" under it
        G.round_rect(866.0, 482.0, 892.0, 496.0, 3.0, None, outline=col, w=2.0)
        G.line([(870.0, 496.0), (870.0, 500.0)], col, 2.2)
        G.line([(888.0, 496.0), (888.0, 500.0)], col, 2.2)
        for x0 in (865.0, 883.0):
            G.line([(x0, 512.0), (x0 + 4, 505.0), (x0 + 8, 512.0), (x0 + 12, 505.0)], col, 1.6)
        G.text(879.0, 522.0, "OFF", ARIAL_B, 11.0, col)

    belt(A, dim)
    dsc(A, dim)
    # the trip button low at the left of the speedometer
    A.circle(343.0, 910.0, 10.5, (28, 28, 27), outline=(70, 70, 68), w=1.4)
    A.circle(343.0, 910.0, 6.0, (88, 88, 86))

    # ---- the oil needle (still) and cap
    def needle_im(length, w0, w1, col, core, cap_r, cap_col, tail=0.0):
        """a needle drawn pointing up over its own slotted cap, the pivot in the middle of the picture"""
        K = 4
        k = sp.A * K
        Lh = max(length, tail, cap_r) + 3
        Wd = int(2 * (cap_r + 3) * k)
        Hd = int(2 * Lh * k)
        im = Image.new("RGBA", (Wd, Hd), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        cx, cy = Wd / 2, Hd / 2
        d.polygon([(cx - w0 / 2 * k, cy + tail * k), (cx + w0 / 2 * k, cy + tail * k), (cx + w1 / 2 * k, cy - length * k), (cx - w1 / 2 * k, cy - length * k)], fill=col + (255,))
        d.ellipse([cx - w1 / 2 * k, cy - (length + w1 / 2) * k, cx + w1 / 2 * k, cy - (length - w1 / 2) * k], fill=col + (255,))
        d.polygon([(cx - w0 * 0.12 * k, cy), (cx + w0 * 0.12 * k, cy), (cx + w1 * 0.1 * k, cy - length * 0.96 * k), (cx - w1 * 0.1 * k, cy - length * 0.96 * k)], fill=core + (255,))
        d.ellipse([cx - cap_r * k, cy - cap_r * k, cx + cap_r * k, cy + cap_r * k], fill=cap_col + (255,))
        d.ellipse([cx - (cap_r - 1.2) * k, cy - (cap_r - 1.2) * k, cx + (cap_r - 1.2) * k, cy + (cap_r - 1.2) * k], outline=tuple(min(255, c + 16) for c in cap_col) + (255,), width=int(1.0 * k))
        g = cap_r * 0.86
        d.rectangle([cx - 1.6 * k, cy - g * k, cx + 1.6 * k, cy + g * k], fill=tuple(max(0, c - 22) for c in cap_col) + (255,))
        d.rectangle([cx + 1.6 * k, cy - g * k, cx + 2.6 * k, cy + g * k], fill=tuple(min(255, c + 22) for c in cap_col) + (255,))
        return im.resize((max(2, Wd // K), max(2, Hd // K)), Image.LANCZOS)

    oil = needle_im(152, 6.6, 4.6, RED, (240, 74, 40), 34.0, (36, 36, 36))
    rot = oil.rotate(-229.5, resample=Image.BICUBIC, expand=True)
    big = rot.resize((rot.width * S, rot.height * S), Image.LANCZOS)
    A.im.paste(big, (int(round((HO[0] - A.ox) * S - big.width / 2)), int(round((HO[1] - A.oy) * S - big.height / 2))), big)

    A.final = A.finish(A.S, blur=2.0, strength=0.35)
    # the outer rows and columns all the housing's colour (Roblox blends a picture's edges in its small copies)
    fin = A.final
    ImageDraw.Draw(fin).rectangle([0, 0, fin.width - 1, fin.height - 1], outline=(7, 8, 6), width=3 * S)
    sp.bg = fin.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # ---- lamps that light: traction control off (amber), the belt lamp while standing (red)
    T = Art(REF, box, S=2, bg=(0, 0, 0))
    dsc(T, (250, 156, 24))
    T.final = T.finish(T.S, blur=1.5, strength=0.4)
    sp.add_show(sp.box(T, (856, 474, 902, 532), black=True), "tcoff")
    B = Art(REF, box, S=2, bg=(0, 0, 0))
    belt(B, (236, 40, 32))
    B.final = B.finish(B.S, blur=1.5, strength=0.4)
    sp.add_show(sp.box(B, (1004, 410, 1038, 458), black=True), "parked")

    # ---- needles: speed (km/h, as printed), revs, fuel
    main = needle_im(232, 8.0, 5.2, RED, (240, 74, 40), 43.0, (38, 38, 38))
    add_needle(sp, main, C1[0], C1[1], "kmh", SPD)
    add_needle(sp, main, C2[0], C2[1], "rpm", [(0, rev(0)), (9.3, rev(9.3))])
    fuel = needle_im(152, 6.6, 4.6, RED, (240, 74, 40), 34.0, (36, 36, 36))
    add_needle(sp, fuel, HF[0], HF[1], "fuel", [(0, 229.5), (0.5, 180.0), (1, 130.5)])

    # ---- the display: the gear (P standing: the game's N), R, D1-D7; the unit; odometer and trip; the speed moving
    def lcd_text(s, cap_h, sx, track=0.0):
        K = 4
        fo = font(ARIAL_B, cap_h / 0.716 * sp.A * K)
        adv = [fo.getlength(ch) + track * sp.A * K for ch in s]
        w = int(sum(adv) + cap_h * 2 * K)
        h = int(cap_h * 3 * K)
        m = Image.new("L", (w, h), 0)
        pen = cap_h * K
        for ch, a in zip(s, adv):
            ImageDraw.Draw(m).text((pen, cap_h * K * 0.6), ch, font=fo, fill=255)
            pen += a
        bb = m.getbbox()
        m = m.crop(bb)
        m = m.resize((max(1, round(m.width * sx / K)), max(1, round(m.height / K))), Image.LANCZOS)
        pad = 4
        out = Image.new("RGBA", (m.width + 2 * pad, m.height + 2 * pad), LCD + (0,))
        a = Image.new("L", out.size, 0)
        a.paste(m, (pad, pad))
        out.putalpha(a)
        return out

    sprites = {"N": {"im": lcd_text("P", 75, 0.75)}, "R": {"im": lcd_text("R", 75, 0.75)}, "P": {"im": lcd_text("P", 75, 0.75)}}
    for ch in "1234567":
        sprites[ch] = {"im": lcd_text("D" + ch, 66, 0.75, track=6)}
    sp.gear = {"x": 951.0 - sp.ox, "y": 817.5 - sp.oy, "sprites": sprites}
    sp.font("lcd", ARIAL_B, 32.8, "0123456789.", shear=0, track=0.0)
    sp.readout("lcd", 956.5, 896.8, "r", 6, "odo", LCD)
    sp.readout("lcd", 1058.0, 896.8, "r", 6, "trip", LCD)
    sp.font("lcds", ARIAL_B, 18.6, "kmi", shear=0)
    sp.readout("lcds", 848.5, 870.8, "l", 2, "distUnit", LCD)
    # (2026-11-10) no digital speed in the upper screen: it isn't on the owner's photo (blank, as photographed)
    return sp
