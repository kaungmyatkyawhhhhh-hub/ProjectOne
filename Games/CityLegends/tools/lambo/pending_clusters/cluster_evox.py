"""The Ronin CZ4A Final's cluster (`ronin_cz4a`) as a live Spec for tools/lambo/cluster_live.py, redrawn from the owner's
photo (imports/refs/evo_x_cluster_owner.webp, 1920 x 1080, 2026-11-14). To merge: paste the function `evox` into
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
    "game": "Ronin CZ4A Final",
    "photo": "evo_x_cluster_owner.webp",
    "states": [dict(v=0.75, gear="N", mph=0, manual=False, clock="10:57", odo="031106", distUnit="km", kmh=True, trip="111.5", fuel=0.59),
               dict(v=5.0, gear="3", mph=49.7, manual=False, clock="10:57", odo="031119", distUnit="km", kmh=True, trip="124.7", fuel=0.55)],
}


def evox(Spec, needle_sprite, add_needle, glyph, solid_gear):
    """the Ronin CZ4A Final (`ronin_cz4a`), redrawn 1:1 from the owner's photo (imports/refs/evo_x_cluster_owner.webp, lit,
    2026-11-14) as seen straight on (the photo's close camera spreads each deep chrome ring away from the middle; here ring
    and face share a centre): two deep round dials in wide chrome rings, the rev counter 0-9 (0 at the bottom, 9 at three
    o'clock; a mark every 250 to 3,000, every 200 to 6,600, every 100 beyond, red from 7,000, the red dot field over the
    grey mesh centre, "x1000r/min") and the speedometer 0-300 km/h (0 at the bottom, 80 at nine o'clock, 180 at the top;
    a mark every 5 km/h to 120, every 10 beyond), white italic numbers, thin grey rings with their small red dots, white
    needles with the dark hub and counterweight. The colour screen between them: the drive-mode tag "TARMAC" (drawn), the
    outside temperature (drawn, "28°C" in km/h or "82°F" in mph: the game has no outside temperature), "TRIP A" with the
    trip (live, the player's unit), the water-temperature and fuel bars in their brackets (drawn at the photo's levels: a
    vertical bar can't follow a value in the game's live pictures), the gear (live, big: P standing as the game's N, R, the
    gear's number), the shift mode under it (live: NORMAL with the automatic gearbox, SPORT with the manual one, as the
    real twin-clutch box shows), "ODO" with the odometer (live, the car's own miles in the player's unit). The amber
    brake lamp above the screen (lit standing, as on the photo) and the dark red lamp over it; the trip / dimmer knob on the
    speedometer's ring. No maker's mark. Coordinates are pixels of the photo; the box is a guess at the model's hood
    opening (re-measure it on the model)."""
    box = (60, 240, 1880, 1060)
    REF = "evo_x_cluster_owner.webp"
    A = Art(REF, box, S=2, bg=(2, 3, 9))
    sp = Spec("evox", box[2] - box[0], box[3] - box[1], 0.7, 0.62, box[0], box[1])  # bg 1128 x 508
    sp.redline, sp.idle = 7.0, 0.75
    S = A.S
    CT, CS = (476.0, 679.0), (1447.0, 686.0)  # rev counter, speedometer
    WHT = (240, 242, 246)
    RED = (214, 44, 30)
    SCR = (238, 242, 250)  # the screen's white

    def rev(v):
        return -180.0 + v * 30.0

    def spd(v):
        return -180.0 + v * 1.125 if v <= 120 else -45.0 + (v - 120) * 0.75

    base = np.asarray(A.im).astype(np.float32)
    h, w = base.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    PX = (xx + 0.5) / S + A.ox
    PY = (yy + 0.5) / S + A.oy

    def put(rgb, a, sl=None):
        a = np.clip(a, 0, 1)[..., None]
        if sl is None:
            base[:] = base * (1 - a) + np.asarray(rgb, np.float32) * a
        else:
            base[sl] = base[sl] * (1 - a) + np.asarray(rgb, np.float32) * a

    def region(C, R):
        x0, x1 = max(0, int((C[0] - R - A.ox) * S)), min(w, int((C[0] + R - A.ox) * S) + 2)
        y0, y1 = max(0, int((C[1] - R - A.oy) * S)), min(h, int((C[1] + R - A.oy) * S) + 2)
        sl = (slice(y0, y1), slice(x0, x1))
        px, py = PX[sl] - C[0], PY[sl] - C[1]
        return sl, np.hypot(px, py), np.degrees(np.arctan2(px, -py)) % 360, px, py

    def mask(draw_fn, blur=0.5):
        m = Image.new("L", (w, h), 0)
        draw_fn(ImageDraw.Draw(m))
        if blur:
            m = m.filter(ImageFilter.GaussianBlur(blur * S))
        return np.asarray(m).astype(np.float32) / 255

    # ---- the housing: black, the grey chin under the screen
    chin = [(700, 1060), (705, 935), (740, 912), (800, 906), (1120, 906), (1180, 912), (1215, 935), (1220, 1060)]
    m = mask(lambda d: d.polygon([A.q(*p) for p in chin], fill=255), 1.0)
    t = np.clip((PY - 906) / 150, 0, 1)
    tone = 96 - 30 * t
    put(np.stack([tone * 0.98, tone * 1.04, tone * 1.02], -1), m)
    lip = mask(lambda d: d.line([A.q(*p) for p in [(712, 975), (760, 952), (900, 945), (1020, 945), (1160, 952), (1208, 975)]], fill=255, width=int(3 * S)), 1.5)
    put((40, 44, 44), lip * 0.8)
    put((120, 126, 126), mask(lambda d: d.line([A.q(*p) for p in [(740, 912), (800, 907), (1120, 907), (1180, 912)]], fill=255, width=int(2 * S)), 1.0) * 0.7)

    def dial(C, red_sector):
        sl, r, th, px, py = region(C, 372)
        # the chrome cone: dark at the top, grey at the sides, bright at the bottom; a dark rim outside
        put((4, 5, 8), np.clip((372 - r) / 10, 0, 1) * band_mask(r, 340, 380, 2.0), sl)
        lit = 34 + 120 * (0.5 - 0.5 * np.cos(np.radians(th))) ** 1.8 + 95 * np.clip(-np.cos(np.radians(th)), 0, 1) ** 5
        tt = np.clip((r - 292) / 66, 0, 1)
        prof = lit * (0.55 + 0.45 * np.sin(np.pi * np.clip(tt * 0.9 + 0.1, 0, 1)))
        put(np.stack([prof, prof * 1.01, prof * 1.03], -1), band_mask(r, 292, 358, 1.2), sl)
        put((210, 214, 218), band_mask(r, 352, 355.5, 1.0) * np.clip(-np.cos(np.radians(th)), 0, 1) ** 2 * 0.8, sl)
        put((10, 11, 14), band_mask(r, 289, 293, 1.0), sl)
        # the face: black, the darker cone ring, the grey dotted mesh in the middle
        put((3, 4, 8), band_mask(r, -5, 290, 1.0), sl)
        put((12, 14, 16), band_mask(r, 150, 196, 6.0) * 0.8, sl)
        mesh = band_mask(r, -5, 152, 1.5)
        put(np.stack([40 + 16 * np.clip(py / 150, -1, 1), 46 + 17 * np.clip(py / 150, -1, 1), 46 + 18 * np.clip(py / 150, -1, 1)], -1), mesh, sl)
        dots = (np.cos(px * np.pi / 10.0) * np.cos(py * np.pi / 10.0)) ** 2  # (holes 10 photo px apart)
        dot = np.clip((dots - 0.5) / 0.2, 0, 1)
        put((6, 8, 10), mesh * dot * 0.95, sl)
        put((26, 30, 30), band_mask(r, 146, 154, 2.0), sl)
        if red_sector:
            ang = np.where(th > 180, th - 360, th)
            sec = np.clip((ang - 20) / 3, 0, 1) * np.clip((90 - ang) / 3, 0, 1) * band_mask(r, 94, 150, 3.0)
            lit_ = 0.55 + 0.45 * np.clip((r - 94) / 56, 0, 1)
            put((30, 8, 8), sec * (1 - dot) * 0.85, sl)  # (the mesh's holes lit red from behind)
            put((164, 30, 24), sec * dot * lit_, sl)
        # the thin grey scale ring
        put((84, 88, 92), band_mask(r, 273, 276.5, 0.8), sl)
        # the hub's dark well
        put((8, 9, 11), band_mask(r, -5, 54, 1.5), sl)
        put((40, 42, 46), band_mask(r, 52, 55, 1.0) * 0.8, sl)

    dial(CT, True)
    dial(CS, False)

    # ---- the screen: dark navy with a faint fan of lines behind the trip; its bezel
    SX0, SY0, SX1, SY1 = 812.0, 503.0, 1113.0, 903.0
    put((22, 24, 28), mask(lambda d: d.rounded_rectangle([A.q(SX0 - 9, SY0 - 9), A.q(SX1 + 9, SY1 + 9)], radius=10 * S, fill=255), 0.8))
    scr = mask(lambda d: d.rectangle([A.q(SX0, SY0), A.q(SX1, SY1)], fill=255), 0.4)
    g = np.clip(1 - np.hypot((PX - 962) / 260, (PY - 700) / 300), 0, 1)
    put(np.stack([3 + 6 * g, 6 + 10 * g, 16 + 20 * g], -1), scr)
    fan = Image.new("L", (w, h), 0)
    fd = ImageDraw.Draw(fan)
    for k in range(-9, 10):
        fd.line([A.q(962 + k * 9, 676), A.q(962 + k * 40, 728)], fill=255, width=max(1, int(0.8 * S)))
    for yv in (684, 694, 707, 724):
        fd.line([A.q(830, yv), A.q(1095, yv)], fill=255, width=max(1, int(0.8 * S)))
    fan = np.asarray(fan.filter(ImageFilter.GaussianBlur(0.6 * S))).astype(np.float32) / 255
    fade = np.clip(1 - np.abs(PX - 962) / 140, 0, 1) * np.clip((PY - 672) / 20, 0, 1) * np.clip((732 - PY) / 10, 0, 1)
    put((30, 40, 70), fan * fade * scr * 0.8)
    A.im.paste(Image.fromarray(np.clip(base, 0, 255).astype("uint8")))

    def tick(C, r0, r1, deg, wd, col=WHT, glow=(40, 40, 44)):
        A.line([polar(C, r0, deg), polar(C, r1, deg)], col, wd, glow=glow, gw=wd * 1.8)

    def T(x, y, s, size, col=WHT, sx=0.92, path=ARIAL_BI, rot=0.0, anchor="mm", track=0.0):
        A.text(x, y, s, path, size, col, scale_x=sx, glow=(30, 30, 34), rot=rot, anchor=anchor, track=track)

    def rtext(x, y, s, path, size, col, rot):
        # text turned by rot degrees (negative: counter-clockwise), centred on (x, y), nothing cut off
        K = S * 3
        fo = font(path, size * K)
        bb = fo.getbbox(s)
        m = Image.new("L", (bb[2] - bb[0] + 8, bb[3] - bb[1] + 8), 0)
        ImageDraw.Draw(m).text((4 - bb[0], 4 - bb[1]), s, font=fo, fill=255)
        m = m.rotate(-rot, resample=Image.BICUBIC, expand=True)
        m = m.resize((max(1, m.width // 3), max(1, m.height // 3)), Image.LANCZOS)
        X, Y = A.q(x, y)
        at = (int(X - m.width / 2), int(Y - m.height / 2))
        A.im.paste(Image.new("RGB", m.size, col), at, m)
        A.glow.paste(Image.new("RGB", m.size, (30, 30, 34)), at, m)

    # ---- the rev counter: marks every 250 to 3,000, every 200 to 6,600, every 100 to 9,000 (red from 7,000)
    RO = 268.0
    vals = [k * 0.25 for k in range(0, 12)] + [3.0 + k * 0.2 for k in range(0, 18)] + [6.6 + k * 0.1 for k in range(0, 25)]
    for v in vals:
        v = round(v, 2)
        red = v >= 6.99
        col = RED if red else WHT
        if abs(v - round(v)) < 0.01:
            tick(CT, RO - 29.0, RO, rev(v), 6.6, col)
        elif red:
            tick(CT, RO - 13.0, RO, rev(v), 3.4, col, (60, 10, 6))
        elif v < 3 and abs(v * 2 - round(v * 2)) < 0.01:
            tick(CT, RO - 17.0, RO, rev(v), 4.4, col)
        else:
            tick(CT, RO - 12.0, RO, rev(v), 3.8, col)
    # (the numbers at the photo's own places, measured: the close camera spreads them a little from a true circle)
    NUMT = {0: (470.0, 888.0), 1: (359.6, 857.6), 2: (294.6, 773.9), 3: (261.2, 671.1), 4: (288.2, 563.9), 5: (371.8, 492.1), 6: (476.7, 463.7), 7: (582.9, 494.3), 8: (657.6, 570.1), 9: (688.9, 673.0)}
    for n, (x, y) in NUMT.items():
        T(x, y, str(n), 44.0)
    rtext(694.0, 792.0, "x1000r/min", ARIAL_BI, 22.0, WHT, -62.0)
    # ---- the speedometer: marks every 5 km/h to 120, every 10 beyond; numbers every 20, then every 30
    SO = 266.0
    marks = [k * 5 for k in range(0, 24)] + [120 + k * 10 for k in range(0, 19)]
    majors = {0, 20, 40, 60, 80, 100, 120, 150, 180, 210, 240, 270, 300}
    for v in marks:
        if v in majors:
            tick(CS, SO - 28.0, SO, spd(v), 6.4)
        elif (v < 120 and v % 10 == 0) or (v > 120 and v % 30 in (10, 20) and False):
            tick(CS, SO - 16.0, SO, spd(v), 4.4)
        else:
            tick(CS, SO - 12.0, SO, spd(v), 3.8)
    NUMS = {0: (1445.0, 905.8), 20: (1378.9, 877.3), 40: (1308.1, 833.1), 60: (1263.4, 764.9), 80: (1243.6, 684.1), 100: (1266.3, 605.0), 120: (1307.5, 542.8),
            150: (1368.9, 491.7), 180: (1452.0, 473.3), 210: (1528.1, 494.2), 240: (1590.9, 545.2), 270: (1631.8, 613.5), 300: (1646.0, 688.9)}
    for v, (x, y) in NUMS.items():
        T(x, y, str(v), 39.0)
    rtext(1684.0, 789.0, "km/h", ARIAL_BI, 22.0, WHT, -62.0)
    # the small red dots on the thin rings (as photographed)
    for C, angs in ((CT, (rev(0), rev(1.0), rev(7.0))), (CS, (spd(0), spd(20), spd(60), spd(120), spd(210), spd(240)))):
        for a in angs:
            p = polar(C, 274.8, a)
            A.circle(p[0], p[1], 2.4, (200, 40, 30))

    # ---- the screen's still parts
    A.round_rect(827.0, 515.5, 914.5, 537.5, 2.5, (232, 236, 242))
    T(870.8, 526.6, "TARMAC", 17.6, (22, 26, 34), sx=0.95, path=ARIAL)
    T(851.0, 618.4, "TRIP", 20.0, SCR, sx=0.94, path=ARIAL_B)
    A.round_rect(887.5, 607.5, 905.0, 629.0, 1.5, SCR)
    T(896.3, 618.6, "A", 20.0, (16, 20, 30), sx=0.94, path=ARIAL_B)
    T(857.0, 880.5, "ODO", 23.0, SCR, sx=1.0, path=ARIAL, track=1.0)
    # the water temperature bracket (left) and the fuel bracket (right), their bars at the photo's levels
    for xb, s_ in ((826.5, 1), (1097.5, -1)):
        A.line([(xb + s_ * 7.0, 727.0), (xb, 727.0), (xb, 841.0), (xb + s_ * 7.0, 841.0)], SCR, 3.2)
        A.line([(xb, 784.0), (xb + s_ * 6.0, 784.0)], SCR, 3.0)
    A.line([(826.5, 727.0), (826.5, 738.0)], (230, 60, 50), 3.4)
    A.line([(826.5, 727.0), (833.0, 727.0)], (230, 60, 50), 3.2)

    def bar(x0, x1, y_top):
        K = Image.new("RGB", (int((x1 - x0) * S), int((841.0 - y_top) * S)))
        a = np.linspace(0, 1, K.width)[None, :, None]
        col = np.array([176, 206, 238], float) * (1 - a) + np.array([104, 134, 198], float) * a
        K = Image.fromarray(np.repeat(col, K.height, axis=0).astype("uint8"))
        A.im.paste(K, (int((x0 - A.ox) * S), int((y_top - A.oy) * S)))

    bar(836.5, 865.5, 793.0)
    bar(1060.0, 1088.5, 773.0)
    for x, y, s in ((875.5, 734.5, "H"), (874.6, 831.2, "C"), (1047.0, 734.6, "F"), (1047.6, 831.0, "E")):
        T(x, y, s, 21.0, SCR, sx=0.95, path=ARIAL_B)
    # the thermometer and the pump (with the filler-side arrow)
    A.line([(887.0, 772.0), (887.0, 790.0)], SCR, 3.0)
    for k in range(3):
        A.line([(887.0, 775.0 + k * 4.0), (892.0, 775.0 + k * 4.0)], SCR, 1.6)
    for dy in (793.0, 798.0):
        A.line([(878.0 + i * 2.0, dy + (1.2 if i % 2 else -0.6)) for i in range(10)], SCR, 1.6)
    A.round_rect(1035.0, 768.0, 1048.0, 792.0, 2.0, SCR)
    A.rect(1037.5, 771.0, 1045.5, 778.0, (8, 12, 24))
    A.line([(1048.0, 773.0), (1052.0, 777.0), (1052.0, 787.0)], SCR, 2.0)
    A.poly([(1027.0, 780.0), (1033.0, 775.5), (1033.0, 784.5)], SCR)

    # ---- the knob on the speedometer's ring, the dark red lamp above the screen
    kp = polar(CS, 352.0, 116.0)
    A.circle(kp[0], kp[1], 21.0, (150, 154, 156), outline=(40, 42, 44), w=2.0)
    A.circle(kp[0], kp[1], 15.0, (70, 72, 74), outline=(190, 194, 196), w=1.6)
    for k in range(8):
        A.line([polar(kp, 5.0, k * 45.0), polar(kp, 9.5, k * 45.0)], (220, 222, 224), 2.0)
    A.round_rect(961.0, 256.0, 1017.0, 300.0, 4.0, (34, 6, 6))
    for C in (CT, CS):
        A.circle(C[0], C[1], 9.0, (20, 20, 22))

    A.final = A.finish(A.S, blur=2.0, strength=0.45)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # ---- shows: the amber brake lamp (standing), the outside temperature in the player's unit
    def show(draw, bx, when, blur=1.5, strength=0.6):
        G = Art(REF, box, S=2, bg=(0, 0, 0))
        draw(G)
        G.final = G.finish(G.S, blur=blur, strength=strength)
        sp.add_show(sp.box(G, bx, black=True), when)

    def brake(G):
        col = (255, 150, 52)
        G.circle(988.0, 350.0, 14.0, None, outline=col, w=4.0)
        for a0, a1 in ((140, 220), (-40, 40)):  # the brackets each side
            G.d.arc([*G.q(988.0 - 22.0, 350.0 - 22.0), *G.q(988.0 + 22.0, 350.0 + 22.0)], a0, a1, fill=col, width=int(4.0 * S))
        G.line([(988.0, 340.0), (988.0, 352.0)], (255, 230, 170), 4.0)
        G.circle(988.0, 358.0, 2.3, (255, 230, 170))
        G.gd.ellipse([G.q(962.0, 324.0), G.q(1014.0, 376.0)], fill=(150, 60, 10))

    show(brake, (956, 318, 1020, 382), "parked", blur=3.0, strength=0.7)

    def temp_text(s, unit):
        def draw(G):
            G.text(1083.0, 550.5, s, ARIAL_B, 41.0, SCR, anchor="rm", scale_x=0.92)
            G.text(1087.0, 554.0, unit, ARIAL_B, 22.0, SCR, anchor="lm", scale_x=0.9)
        return draw

    show(temp_text("28", "°C"), (1026, 526, 1112, 574), "kmh", blur=0.8, strength=0.2)
    show(temp_text("82", "°F"), (1026, 526, 1112, 574), "mph", blur=0.8, strength=0.2)

    # ---- needles: a white blade, the dark counterweight, the small dark cap
    def blade(length, tail, w0, w1, tw, cap):
        K = 4
        k = sp.A * K
        L = max(length, tail) + 4
        Wd, Hd = int(2 * (max(cap, w0, tw) + 3) * k), int(2 * L * k)
        im = Image.new("RGBA", (Wd, Hd), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        cx, cy = Wd / 2, Hd / 2
        d.rounded_rectangle([cx - tw / 2 * k, cy - 2 * k, cx + tw / 2 * k, cy + tail * k], radius=tw / 2 * k, fill=(46, 48, 52, 255))
        d.rounded_rectangle([cx - tw * 0.32 * k, cy + 4 * k, cx + tw * 0.32 * k, cy + (tail - 6) * k], radius=tw * 0.3 * k, fill=(62, 64, 68, 255))
        d.polygon([(cx - w0 / 2 * k, cy + 4 * k), (cx + w0 / 2 * k, cy + 4 * k), (cx + w1 / 2 * k, cy - length * k), (cx - w1 / 2 * k, cy - length * k)], fill=(196, 198, 204, 255))
        d.polygon([(cx - w0 * 0.36 * k, cy + 4 * k), (cx + w0 * 0.36 * k, cy + 4 * k), (cx + w1 * 0.34 * k, cy - (length - 1) * k), (cx - w1 * 0.34 * k, cy - (length - 1) * k)], fill=(250, 251, 255, 255))
        d.ellipse([cx - cap * k, cy - cap * k, cx + cap * k, cy + cap * k], fill=(30, 31, 34, 255), outline=(70, 72, 76, 255), width=int(1.5 * k))
        return im.resize((max(2, Wd // K), max(2, Hd // K)), Image.LANCZOS)

    add_needle(sp, blade(258.0, 84.0, 17.0, 12.0, 26.0, 16.0), CT[0], CT[1], "rpm", [(0, rev(0)), (9.4, rev(9.4))])
    pts = [(v, spd(v)) for v in (0, 120, 300)] + [(315, spd(315))]
    add_needle(sp, blade(258.0, 84.0, 17.0, 12.0, 26.0, 16.0), CS[0], CS[1], "kmh", pts)

    # ---- live readouts on the screen
    sp.font("trip", ARIAL, 36.0, "0123456789.", shear=0, track=3.5)
    sp.readout("trip", 1021.0, 660.8, "r", 6, "trip", SCR)
    sp.font("du", ARIAL, 21.5, "kmi", shear=0, track=0.6)
    sp.readout("du", 1026.5, 664.8, "l", 2, "distUnit", SCR)
    sp.font("odo", ARIAL, 40.0, "0123456789", shear=0, track=1.2)
    sp.readout("odo", 1032.5, 876.7, "r", 6, "odo", SCR)
    sp.readout("du", 1040.7, 880.5, "l", 2, "distUnit", SCR)
    sp.font("mode", ARIAL, 23.5, "NORMALSPT", shear=0, track=0.3)
    sp.readout("mode", 965.0, 815.0, "m", 6, "driveMode", SCR)

    def char_im(ch, cap_h):
        K = 4
        k = sp.A * K
        fo = font(ARIAL_B, cap_h / 0.716 * k)
        t = Image.new("L", (int(cap_h * 2 * k), int(cap_h * 2 * k)), 0)
        ImageDraw.Draw(t).text((cap_h * 0.4 * k, cap_h * 0.2 * k), ch, font=fo, fill=255)
        t = t.crop(t.getbbox())
        m = t.resize((max(1, t.width // K), max(1, t.height // K)), Image.LANCZOS)
        out = Image.new("RGBA", m.size, SCR + (0,))
        out.putalpha(m)
        return out

    sprites = {"N": {"im": char_im("P", 52.0)}, "R": {"im": char_im("R", 52.0)}}
    sprites["P"] = sprites["N"]
    for ch in "1234567":
        sprites[ch] = {"im": char_im(ch, 52.0)}
    sp.gear = {"x": 968.8 - sp.ox, "y": 767.2 - sp.oy, "sprites": sprites}
    return sp
