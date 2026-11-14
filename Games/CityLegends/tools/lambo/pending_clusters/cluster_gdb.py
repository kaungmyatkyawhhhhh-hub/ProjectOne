"""The Pleiad GDB's cluster (`pleiad_gdb`) as a live Spec for tools/lambo/cluster_live.py, redrawn from the owner's photo of
a 2006 GD cluster (imports/refs/impreza_gdb_sti_cluster_owner.png, 2000 x 1500, taken at an angle in sunlight), worked in
its level copy imports/refs/impreza_gdb_sti_cluster_owner_level.png (the dials as seen straight on, 2100 x 1500; see its
.txt). To merge: paste the function `gdb` into tools/lambo/cluster_imports.py (it needs only that file's own imports, the
same as the header below) and see MERGE.md, "JDM clusters (2026-11-14)"."""

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from cluster_art import ARIAL, ARIAL_B, ARIAL_BI, REG, ROBO_B, TECH, Art, font  # noqa: F401
from cluster_lfa_maybach import band_mask, blend, field, polar, smooth  # noqa: F401

HERE = os.path.dirname(os.path.abspath(__file__))

PREVIEW_INFO = {
    "game": "Pleiad GDB",
    "photo": "impreza_gdb_sti_cluster_owner_level.png",
    "states": [dict(v=0.8, gear="N", mph=0, manual=True, clock="10:57", odo="217892", distUnit="mi", kmh=False, trip="241.1", fuel=0.5),
               dict(v=5.0, gear="3", mph=49.7, manual=True, clock="10:57", odo="217905", distUnit="mi", kmh=False, trip="254.3", fuel=0.45)],
}


def gdb(Spec, needle_sprite, add_needle, glyph, solid_gear):
    """the Pleiad GDB (`pleiad_gdb`), redrawn 1:1 from the owner's photo of the 2006 GD cluster
    (imports/refs/impreza_gdb_sti_cluster_owner.png), drawn as seen straight on, lit, at night and clean (the photo is taken
    at an angle in sunlight, with glare and dust; coordinates are pixels of its level copy
    impreza_gdb_sti_cluster_owner_level.png): three round dials lit in red on black in wide silver rings. Middle (the
    biggest): the rev counter 0-9 (x1000 r/min, a mark every 250, the red dotted band 7-9 as printed), a long red needle,
    a dark hub, the small dark sensor dot over the hub. Left: fuel (E - F, the pump) and water temperature (C - H, the dotted
    block at H) sharing one dial, each needle on its own hub, the DCCD panel between them ("DCCD", "AUTO" lit, the LOCK box
    and the column of triangle boxes, unlit) and the OUT TEMP red window low (46 °F / 8 °C by the player's unit). Right:
    the speedometer 0-160 MPH as printed (a mark every 5) with the small inner km/h ring (20-260), the red window low with
    the trip (A) and the odometer. Over the rev counter, right: the seat-belt light (standing). Under the dials: the REV.
    and TRIP stalks and the dark warning-light row. Live: the rev needle, the speed needle (mph as printed), the fuel
    needle, the trip and the odometer (the car's own miles in the player's unit, segment digits as on the photo), the
    belt light, the OUT TEMP unit. Drawn still: the water needle at running heat (no engine temperature in the game), the
    outside temperature's value (no weather temperature in the game: 46 °F as on the photo, 8 °C in km/h), the DCCD AUTO
    state. No "STI" under the hub (its spot stays plain) and no maker's mark. The box is a guess at the model's hood
    opening (re-measure it on the model)."""
    box = (120, 480, 2050, 1330)
    REF = "impreza_gdb_sti_cluster_owner_level.png"
    A = Art(REF, box, S=2, bg=(6, 6, 7))
    sp = Spec("gdb", box[2] - box[0], box[3] - box[1], 0.8, 0.6, box[0], box[1])  # bg 1158 x 510 (A: the long needles fit a sheet)
    sp.redline, sp.idle = 7.0, 0.8
    S = A.S
    CT, RT, WT = (1097.0, 838.0), 342.0, 44.0  # rev counter: centre, ring's outer radius, ring width
    CL, RL, WL = (453.0, 992.0), 308.0, 46.0  # left dial
    CR, RR, WR = (1720.0, 976.0), 306.0, 28.0  # speedometer
    HF, HW = (302.0, 992.0), (604.0, 992.0)  # fuel, water needle hubs
    RED = (255, 38, 32)
    GLOW = (150, 12, 8)
    DIMR = (62, 12, 11)
    GREY = (176, 176, 178)

    def rev(v):
        return -126.0 + v * 28.0

    def mph(v):
        return -122.0 + v * 1.525

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

    # ---- the housing: black above the dials, the dark grey plate below them (the photo's sunlit grey, at night)
    h, w = base.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    py_all = (yy + 0.5) / S + A.oy
    px_all = (xx + 0.5) / S + A.ox
    plate = np.clip((py_all - 1010) / 60, 0, 1)
    tone = 8 + 22 * plate
    base[:] = np.stack([tone, tone, tone * 1.04], -1)

    def dial(C, R, wd, face_r):
        sl, r, th, px, py = region(C, R + 8)
        put(sl, (3, 3, 4), np.clip((R + 7.0 - r) / 7.0, 0, 1) * 0.8)  # the shadow round the ring
        # the silver ring at night: a soft grey, a bright line on its outer lip, darker towards the face
        t = np.clip((r - (R - wd)) / wd, 0, 1)
        lit = 1.0 + 0.45 * np.cos(np.radians(th - 320)) ** 8 + 0.25 * np.cos(np.radians(th - 140)) ** 6
        prof = (62 + 58 * np.sin(np.pi * np.clip(t * 1.1, 0, 1)) ** 0.8) * lit
        put(sl, np.stack([prof, prof, prof * 1.03], -1), band_mask(r, R - wd, R, 0.6))
        put(sl, (200, 200, 204), band_mask(r, R - 3.6, R - 1.8, 0.6) * (0.45 + 0.55 * np.cos(np.radians(th - 320)) ** 2))
        put(sl, (150, 150, 154), band_mask(r, R - wd + 1.0, R - wd + 2.6, 0.6) * 0.6)
        put(sl, (2, 2, 3), band_mask(r, R - wd - 2.0, R - wd + 0.8, 0.6))
        k = np.clip(1 - r / face_r, 0, 1)
        put(sl, np.stack([4 + 8 * k, 4 + 8 * k, 5 + 9 * k], -1), band_mask(r, -5, face_r, 1.0))

    dial(CL, RL, WL, RL - WL - 2)
    dial(CR, RR, WR, RR - WR - 2)
    dial(CT, RT, WT, RT - WT - 2)  # (the rev counter's ring over the side dials' rings where they meet)
    # the warning-light row under the rev counter: a dark window in a grey frame
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle([A.q(797, 1180), A.q(1398, 1260)], radius=14 * S, fill=255)
    m = np.asarray(m.filter(ImageFilter.GaussianBlur(1.0 * S))).astype(np.float32) / 255
    base = base * (1 - m[..., None]) + np.array([5, 5, 6], np.float32) * m[..., None]
    A.im.paste(Image.fromarray(np.clip(base, 0, 255).astype("uint8")))
    A.round_rect(797, 1180, 1398, 1260, 14, None, outline=(64, 64, 68), w=3.0)

    def tick(C, r0, r1, deg, wd, col=RED, glow=GLOW):
        A.line([polar(C, r0, deg), polar(C, r1, deg)], col, wd, glow=glow, gw=wd * 1.8)

    def red_text(x, y, s, path, size, sx=1.0, col=RED, glow=GLOW, rot=0.0):
        A.text(x, y, s, path, size, col, scale_x=sx, glow=glow, rot=rot)

    # ---- the rev counter: a mark every 250 (long at 1000, medium at 500), numbers 0-9, the red dotted band 7-9
    TO = 296.0
    for i in range(0, 37):
        v = i / 4
        if v > 7.0 and v < 9.0 and i % 4 != 0 and i % 2 != 0:
            continue  # (the band: only the 500 marks cross it)
        if i % 4 == 0:
            tick(CT, TO - 42.0, TO, rev(v), 8.5)
        elif i % 2 == 0:
            tick(CT, TO - 26.0, TO, rev(v), 6.5)
        else:
            tick(CT, TO - 16.0, TO, rev(v), 5.0)
    # the dotted band: rows of dots between the 7 and the 9 marks, five across (the 500 marks cross it)
    NR = 40
    for k in range(NR):
        a = rev(7.0) + (rev(9.0) - rev(7.0)) * (k + 0.5) / NR
        for j in range(5):
            p = polar(CT, 259.0 + j * 6.8, a + (0.6 if j % 2 else 0.0))
            A.circle(p[0], p[1], 2.3, RED)
            A.gd.ellipse([A.q(p[0] - 2.6, p[1] - 2.6), A.q(p[0] + 2.6, p[1] + 2.6)], fill=(80, 8, 6))
    for v in range(10):
        p = polar(CT, 228.0, rev(v))
        red_text(p[0], p[1], str(v), ARIAL_B, 76.0, sx=0.9)
    red_text(1097.0, 657.0, "x1000r/min", ARIAL_BI, 31.0, sx=0.95)
    A.circle(1084.0, 724.0, 17.0, (3, 3, 4), outline=(34, 34, 38), w=2.0)  # the small sensor dot

    # ---- the speedometer: a mark every 5 mph, numbers every 20, MPH; the inner km/h ring 20-260
    SO = 276.0
    for i in range(0, 33):
        v = i * 5
        if v % 20 == 0:
            tick(CR, SO - 44.0, SO, mph(v), 8.0)
        elif v % 10 == 0:
            tick(CR, SO - 30.0, SO, mph(v), 6.0)
        else:
            tick(CR, SO - 18.0, SO, mph(v), 4.6)
    for v in range(0, 161, 20):
        p = polar(CR, 207.0 - 6.0 * abs(math.sin(math.radians(mph(v)))) * (1 if v >= 100 else 0.3), mph(v))
        red_text(p[0], p[1], str(v), ARIAL_B, 48.0, sx=0.92)
    red_text(1902.0, 1154.0, "MPH", ARIAL_B, 26.0, sx=0.95)
    for k in range(20, 261, 10):
        a = mph(k / 1.609)
        tick(CR, 140.0, 150.0 if k % 20 else 154.0, a, 3.0 if k % 20 else 3.6)
        if k % 20 == 0:
            p = polar(CR, 124.0, a)
            red_text(p[0], p[1], str(k), ARIAL, 22.0, sx=0.9)
    red_text(1712.0, 890.0, "km/h", ARIAL, 22.0, sx=0.9)
    # the red window low: dark red glass with the trip (A) over the odometer
    A.round_rect(1622, 1140, 1824, 1230, 4, (30, 4, 4), outline=(58, 8, 8), w=2.0)
    A.round_rect(1631, 1150, 1650, 1167, 2, None, outline=RED, w=2.2)
    red_text(1640.5, 1159.0, "A", ARIAL_B, 13.0)

    # ---- the left dial: fuel (left) and water temperature (right), each arc round its own needle's hub, ticks outward
    AR = 101.0
    for H, sgn in ((HF, -1), (HW, 1)):
        a0, a1 = sgn * 34.0, sgn * 146.0
        n = 40
        A.line([polar(H, AR, a0 + (a1 - a0) * k / n) for k in range(n + 1)], RED, 4.4, glow=GLOW, gw=8.0)
        for k, f in enumerate((0.0, 0.25, 0.5, 0.75, 1.0)):
            a = a0 + (a1 - a0) * f
            tick(H, AR, AR + (41.0 if k in (0, 4) else (24.0 if k == 2 else 17.0)), a, 9.0 if k in (0, 4) else 5.4)
    # the dotted block at H
    for k in range(4):
        for j in range(5):
            a = 23.0 + k * 3.4
            p = polar(HW, AR + 8.0 + j * 6.8, a)
            A.circle(p[0], p[1], 2.3, RED)
            A.gd.ellipse([A.q(p[0] - 2.6, p[1] - 2.6), A.q(p[0] + 2.6, p[1] + 2.6)], fill=(80, 8, 6))
    for s, H, dx, dy in (("F", HF, -6.0, -88.0), ("E", HF, -10.0, 80.0), ("H", HW, 6.0, -88.0), ("C", HW, 10.0, 80.0)):
        red_text(H[0] + dx, H[1] + dy, s, ARIAL_B, 44.0, sx=0.95)
    # the pump and the thermometer in the waves
    x, y = HF[0] - 50.0, HF[1] - 2.0
    A.round_rect(x - 12, y - 16, x + 4, y + 16, 2, RED)
    A.rect(x - 8.5, y - 12, x + 0.5, y - 3, (12, 2, 2))
    A.rect(x - 15, y + 14, x + 7, y + 18, RED)
    A.line([(x + 4, y - 6), (x + 10, y - 2), (x + 10, y + 9), (x + 14, y + 9), (x + 14, y - 10), (x + 8, y - 16)], RED, 2.6)
    x, y = HW[0] + 54.0, HW[1] - 10.0
    A.line([(x, y - 18), (x, y + 4)], RED, 4.0)
    for k in range(3):
        A.line([(x, y - 14 + k * 5.5), (x + 8, y - 14 + k * 5.5)], RED, 2.2)
    A.circle(x, y + 5, 4.5, RED)
    for dy in (13.0, 19.0):
        A.line([(x - 15 + i * 3.0, y + dy + (1.4 if i % 2 else -1.0)) for i in range(11)], RED, 2.2)
    # the DCCD panel: "DCCD", "AUTO" lit; LOCK and the triangle boxes unlit
    red_text(389.0, 782.0, "DCCD", ARIAL_B, 30.0, sx=0.88)
    A.round_rect(452, 769, 494, 795, 4, (60, 6, 6), outline=RED, w=2.6)
    red_text(473.0, 782.0, "AUTO", ARIAL_B, 19.0, sx=0.85)
    for k, sym in enumerate(("LOCK", "v", "v", "v", "^", "^")):
        y = 833.0 + k * 53.0
        A.round_rect(456, y - 16, 486, y + 16, 5, None, outline=DIMR, w=2.4)
        if sym == "LOCK":
            A.text(471.0, y, "LOCK", ARIAL_B, 10.5, DIMR, scale_x=0.8)
        elif sym == "v":
            A.poly([(463.0, y - 5.0), (479.0, y - 5.0), (471.0, y + 6.0)], DIMR)
        else:
            A.poly([(463.0, y + 5.0), (479.0, y + 5.0), (471.0, y - 6.0)], DIMR)
    # the OUT TEMP window: dark red glass ("OUT TEMP" printed; the value is a lit piece by unit, below)
    A.round_rect(380, 1160, 546, 1236, 4, (30, 4, 4), outline=(58, 8, 8), w=2.0)
    red_text(463.0, 1180.0, "OUT TEMP", ARIAL_B, 19.0, sx=0.8)

    # ---- under the dials: REV. and TRIP printed, the two stalks (a silver collar, the black rod coming out at the viewer)
    for x, y, lab, ly in ((755.0, 1214.0, "REV.", 1177.0), (1440.0, 1219.0, "TRIP", 1180.0)):
        A.text(x, ly, lab, ARIAL_B, 22.0, (150, 150, 154), scale_x=0.9)
        A.circle(x, y, 17.0, (90, 90, 94), outline=(150, 150, 154), w=2.0)
        A.circle(x, y, 11.0, (8, 8, 9))
        A.line([(x, y), (x, y + 30.0)], (14, 14, 15), 18.0)
        A.circle(x, y + 30.0, 9.5, (20, 20, 22), outline=(52, 52, 56), w=1.6)
    # the dark warning lights in the row (unlit: dim prints)
    DIMG = (40, 40, 44)
    A.text(928.0, 1220.0, "ABS", ARIAL_B, 26.0, DIMG)
    A.circle(1010.0, 1220.0, 15.0, None, outline=DIMG, w=2.4)
    A.text(1010.0, 1220.0, "!", ARIAL_B, 22.0, DIMG)
    A.round_rect(1062, 1208, 1098, 1232, 3, None, outline=DIMG, w=2.4)
    A.text(1080.0, 1220.0, "+ -", ARIAL_B, 15.0, DIMG)
    A.text(1160.0, 1220.0, "TCS", ARIAL_B, 22.0, DIMG)
    A.text(1250.0, 1226.0, "SPEAK", ARIAL_B, 18.0, DIMG)
    A.text(1335.0, 1220.0, "CHECK", ARIAL_B, 18.0, DIMG)

    A.final = A.finish(A.S, blur=2.4, strength=0.6)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # ---- lit pieces: the seat-belt light (standing) and the OUT TEMP value by the player's unit
    def piece(draw, bx, when, blur=2.0):
        G = Art(REF, box, S=2, bg=(0, 0, 0))
        draw(G)
        G.final = G.finish(G.S, blur=blur, strength=0.6)
        sp.add_show(sp.box(G, bx, black=True), when)

    def belt(G):  # the seated figure with the belt across it
        x, y = 1385.0, 572.0
        G.circle(x + 1.0, y - 15.0, 5.6, RED)
        G.poly([(x - 7.0, y - 7.0), (x + 7.0, y - 7.0), (x + 9.0, y + 6.0), (x + 18.0, y + 6.0), (x + 21.0, y + 18.0), (x + 15.0, y + 18.0), (x + 13.0, y + 12.0), (x - 6.0, y + 12.0), (x - 9.0, y + 2.0)], RED)
        G.line([(x - 14.0, y - 9.0), (x - 11.0, y + 14.0)], RED, 3.0)
        G.line([(x + 6.0, y - 8.0), (x - 6.0, y + 8.0)], (14, 2, 2), 2.6)
        G.line([(x - 18.0, y + 19.0), (x + 22.0, y + 19.0)], RED, 2.4)

    piece(belt, (1360, 545, 1410, 595), "parked")

    SEGS = {"0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd", "6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcdfg"}

    def seg_char(G, x0, ym, ch, h, wd, t, gap=0.3, col=RED):
        """one segment digit drawn into an Art: left edge x0, middle line ym (the OUT TEMP value)"""
        y0, hm = ym - h / 2, h / 2

        def hseg(y):
            return [(x0 + gap + t / 2, y), (x0 + gap + t, y - t / 2), (x0 + wd - gap - t, y - t / 2), (x0 + wd - gap - t / 2, y), (x0 + wd - gap - t, y + t / 2), (x0 + gap + t, y + t / 2)]

        def vseg(x, ya, yb):
            return [(x, ya + gap + t / 2), (x + t / 2, ya + gap + t), (x + t / 2, yb - gap - t), (x, yb - gap - t / 2), (x - t / 2, yb - gap - t), (x - t / 2, ya + gap + t)]

        P = {"a": hseg(y0 + t / 2), "g": hseg(y0 + hm), "d": hseg(y0 + h - t / 2), "f": vseg(x0 + t / 2, y0 + t / 2, y0 + hm), "b": vseg(x0 + wd - t / 2, y0 + t / 2, y0 + hm),
             "e": vseg(x0 + t / 2, y0 + hm, y0 + h - t / 2), "c": vseg(x0 + wd - t / 2, y0 + hm, y0 + h - t / 2)}
        for sg in SEGS.get(ch, ""):
            G.poly(P[sg], col)
            G.gd.polygon([G.q(*q) for q in P[sg]], fill=GLOW)

    def temp_f(G):
        seg_char(G, 412.0, 1214.0, "4", 36.0, 21.0, 5.6)
        seg_char(G, 442.0, 1214.0, "6", 36.0, 21.0, 5.6)
        G.circle(474.0, 1200.0, 4.0, None, outline=RED, w=2.2)
        G.text(494.0, 1214.0, "F", ARIAL_B, 40.0, RED, scale_x=0.85, glow=GLOW)

    def temp_c(G):
        seg_char(G, 442.0, 1214.0, "8", 36.0, 21.0, 5.6)
        G.circle(474.0, 1200.0, 4.0, None, outline=RED, w=2.2)
        G.text(494.0, 1214.0, "C", ARIAL_B, 40.0, RED, scale_x=0.85, glow=GLOW)

    piece(temp_f, (404, 1190, 516, 1238), "mph")
    piece(temp_c, (404, 1190, 516, 1238), "kmh")

    # ---- needles: a long red blade with a hot core; the dark hub on top
    def blade(length, tail, w0, w1, cap, cap_col=(16, 16, 18)):
        K = 3
        k = sp.A * K
        L = max(length, tail, cap) + 2
        Wd, Hd = int(2 * (max(cap, w0) + 3) * k), int(2 * L * k)
        im = Image.new("RGBA", (Wd, Hd), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        cx, cy = Wd / 2, Hd / 2
        d.polygon([(cx - w0 / 2 * k, cy + tail * k), (cx + w0 / 2 * k, cy + tail * k), (cx + w1 / 2 * k, cy - length * k), (cx - w1 / 2 * k, cy - length * k)], fill=RED + (255,))
        d.polygon([(cx - w0 * 0.16 * k, cy), (cx + w0 * 0.16 * k, cy), (cx + w1 * 0.14 * k, cy - length * 0.96 * k), (cx - w1 * 0.14 * k, cy - length * 0.96 * k)], fill=(255, 150, 130, 255))
        if cap:
            yy2, xx2 = np.mgrid[0:Hd, 0:Wd]
            rr = np.hypot(xx2 - cx, yy2 - cy) / (cap * k)
            sh = np.clip(cap_col[0] + 26 * (1 - rr) - 14 * ((yy2 - cy) / (cap * k)), 0, 255)
            a = np.clip((1 - rr) * cap * k / 2.0, 0, 1) * 255
            rim = np.exp(-((rr - 0.93) / 0.05) ** 2) * 50
            dm = Image.fromarray(np.dstack([sh + rim, sh + rim, sh * 1.04 + rim, a]).astype("uint8"), "RGBA")
            im.alpha_composite(dm)
        return im.resize((max(2, Wd // K), max(2, Hd // K)), Image.LANCZOS)

    add_needle(sp, blade(292.0, 40.0, 13.0, 7.0, 46.0), CT[0], CT[1], "rpm", [(0, rev(0)), (9.3, rev(9.3))])
    add_needle(sp, blade(272.0, 40.0, 12.0, 6.5, 62.0), CR[0], CR[1], "mph", [(0, mph(0)), (165, mph(165))])
    add_needle(sp, blade(108.0, 30.0, 9.0, 5.5, 27.0), HF[0], HF[1], "fuel", [(0, -146.0), (1, -34.0)])
    wim = blade(108.0, 30.0, 9.0, 5.5, 27.0).rotate(-90.0, resample=Image.BICUBIC, expand=True)  # water: still, at running heat
    sp.shows.append({"im": wim, "left": HW[0] - wim.width / sp.A / 2 - sp.ox, "top": HW[1] - wim.height / sp.A / 2 - sp.oy, "when": None})

    # ---- the red window: the trip (A, tenths) over the odometer, segment digits as on the photo
    def seg_font(name, h, w, t, gap, adv, chars, slant=0.0, dot=(0.0, 0.0)):
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
            elif ch == ".":
                d.rectangle([x0, y0 + H_ - T, x0 + T, y0 + H_], fill=255)
                a = dot[1]
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
            g[ch] = (im, ox + (dot[0] if ch == "." else 0.0), oy, a)

    # (the digit sits at the left of its cell, so a "1" lights the cell's middle: as the photo's "241.1"; the point sits
    # right after the digit before it and takes little room)
    seg_font("trip", 41.0, 21.0, 5.8, 0.3, 39.0, "0123456789.", slant=0.05, dot=(-16.0, 6.0))
    sp.readout("trip", 1825.0, 1167.5, "r", 6, "trip", RED)
    seg_font("odo", 36.0, 19.0, 5.4, 0.3, 30.0, "0123456789", slant=0.05)
    sp.readout("odo", 1815.0, 1214.0, "r", 6, "odo", RED)

    sprites = {ch: {"im": Image.new("RGBA", (4, 4), (0, 0, 0, 0))} for ch in "RNP1234567"}
    sp.gear = {"x": 0, "y": 0, "sprites": sprites}
    return sp
