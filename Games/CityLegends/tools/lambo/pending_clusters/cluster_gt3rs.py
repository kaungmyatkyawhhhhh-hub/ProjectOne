"""The Stuttgart 991.2 Track's cluster (`porsha_gt3`) as a live Spec for tools/lambo/cluster_live.py, redrawn from the
owner's photo (imports/refs/gt3rs_9912_cluster_owner.png, 2026-11-10). To merge: paste the function `gt3rs` into
tools/lambo/cluster_imports.py (it needs only that file's own imports, the same as the header below) and see MERGE.md."""

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from cluster_art import ARIAL, ARIAL_B, ARIAL_BI, REG, ROBO_B, TECH, Art, font  # noqa: F401
from cluster_lfa_maybach import band_mask, blend, field, polar, smooth  # noqa: F401

HERE = os.path.dirname(os.path.abspath(__file__))


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
    photo; the box is a guess at the model's hood opening (re-measure it on the model)."""
    box = (228, 362, 1732, 918)
    REF = "gt3rs_9912_cluster_owner.png"
    A = Art(REF, box, S=2, bg=(5, 5, 6))
    sp = Spec("gt3rs", box[2] - box[0], box[3] - box[1], 1.3, 0.92, box[0], box[1])  # bg 1384 x 512 (halves 692 x 512)
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
