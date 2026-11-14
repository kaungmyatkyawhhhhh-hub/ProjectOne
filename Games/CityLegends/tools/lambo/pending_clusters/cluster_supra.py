"""The Apex JZA80's cluster (`toyoka_supra_mk4`) as a live Spec for tools/lambo/cluster_live.py, redrawn from the owner's
photo (imports/refs/supra_mk4_cluster_owner_photo5.webp, 1152 x 864, 2026-11-14). To merge: paste the function `supra`
into tools/lambo/cluster_imports.py (it needs only that file's own imports, the same as the header below) and see
MERGE.md, "JDM clusters (2026-11-14)"."""

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from cluster_art import ARIAL, ARIAL_B, ARIAL_BI, REG, ROBO_B, TECH, Art, font  # noqa: F401
from cluster_lfa_maybach import band_mask, blend, field, polar, smooth  # noqa: F401

HERE = os.path.dirname(os.path.abspath(__file__))

PREVIEW_INFO = {
    "game": "Apex JZA80",
    "photo": "supra_mk4_cluster_owner_photo5.webp",
    "states": [dict(v=0.8, gear="N", mph=0, manual=True, clock="10:57", odo="129355", distUnit="km", kmh=True, trip="304.9", fuel=0.12),
               dict(v=5.0, gear="3", mph=49.7, manual=True, clock="10:57", odo="129368", distUnit="km", kmh=True, trip="317.6", fuel=0.62)],
}


def supra(Spec, needle_sprite, add_needle, glyph, solid_gear):
    """the Apex JZA80 (`toyoka_supra_mk4`), redrawn 1:1 from the owner's photo (imports/refs/supra_mk4_cluster_owner_photo5.webp,
    the 2JZ car's cluster by day, 2026-11-14) as seen straight on (the photo looks down on deep dials, so each face sits a
    little low and right in its ring there; here face and ring share a centre): five deep round dials in chrome rings on
    the dark grey plate. Middle: the rev counter 0-8 (x1000 r/min, a mark every 100, red marks 7-8); left: the
    speedometer 0-180 km/h (a mark every 5) with the two drum windows (the odometer, six drums, and the trip, three drums
    and the tenths), "km/h" and the trip knob; right: the three small gauges, each with its scale on the left of the dial:
    boost (0 and +, the turbo icon), water temperature (C - H, red marks at H) and fuel (E, the pump at the full end). The turn arrows
    (dark teal as on the photo: the game has no indicator state for a cluster) between the dials. Orange needles; white
    numbers lit a little. Live: the rev needle, the speed needle (km/h as printed), the fuel needle, the odometer (the
    car's own miles in the player's unit) and the trip. Drawn still: the boost needle at idle (the game has no boost) and
    the water needle at running heat (the photo's engine is cold). No "DIDO TUNING" watermark and no maker's mark.
    Coordinates are pixels of the photo; the box is a guess at the model's hood opening (re-measure it on the model)."""
    box = (6, 318, 1150, 772)
    REF = "supra_mk4_cluster_owner_photo5.webp"
    A = Art(REF, box, S=3, bg=(40, 37, 36))
    sp = Spec("supra", box[2] - box[0], box[3] - box[1], 1.1, 1.12, box[0], box[1])  # bg 1281 x 508
    sp.redline, sp.idle = 6.8, 0.8
    S = A.S
    CS, RS = (234.0, 590.0), 181.0  # speedometer: centre, the chrome ring's outer radius
    CT, RT = (589.0, 492.0), 156.0  # rev counter
    SMALL = {"boost": ((961.0, 457.0), 80.0), "water": ((866.0, 608.0), 80.0), "fuel": ((1057.0, 614.0), 81.0)}
    WHT = (238, 238, 232)
    RED = (228, 54, 42)
    NEEDLE = (248, 116, 70)
    NUMF = "C:/Windows/Fonts/bahnschrift.ttf"

    def spd(v):
        return -128.0 + v * 1.29

    def rev(v):
        return -120.0 + v * 30.0

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

    # ---- the plate: dark warm grey, a little lighter at the top, the deep slot under the rev counter
    h, w = base.shape[:2]
    yy = np.mgrid[0:h, 0:w][0]
    py_all = (yy + 0.5) / S + A.oy
    tone = 58 - 12 * np.clip((py_all - 330) / 420, 0, 1)
    base[:] = np.stack([tone * 1.05, tone, tone * 0.95], -1)
    slot = Image.new("L", (w, h), 0)
    ImageDraw.Draw(slot).polygon([A.q(x, y) for x, y in [(352, 772), (380, 706), (420, 690), (760, 690), (800, 706), (830, 772)]], fill=255)
    slot = np.asarray(slot.filter(ImageFilter.GaussianBlur(2.0 * S))).astype(np.float32) / 255
    base = base * (1 - slot[..., None]) + np.array([12, 13, 15], np.float32) * slot[..., None]

    def dial(C, R, ring_w, face_r):
        """a chrome ring (outer radius R) round a deep dark face: a dark wall from the ring down to the face (face_r)"""
        sl, r, th, px, py = region(C, R + 7)
        put(sl, (14, 13, 13), np.clip((R + 6.0 - r) / 6.0, 0, 1) * 0.6)  # its shadow on the plate
        lit = 150 + 95 * np.cos(np.radians(th - 315)) ** 8 + 75 * np.cos(np.radians(th - 135)) ** 6
        dark = 66 + 40 * np.cos(np.radians(th - 225)) ** 2
        t = np.clip((r - (R - ring_w)) / ring_w, 0, 1)
        up = np.clip(t / 0.35, 0, 1)
        down = np.clip((t - 0.35) / 0.65, 0, 1) ** 1.5
        prof = np.where(t < 0.35, dark + (lit - dark) * up, lit - (lit - 120) * down)
        put(sl, np.stack([prof, prof, prof * 1.03], -1), band_mask(r, R - ring_w, R, 0.5))
        put(sl, (214, 216, 220), band_mask(r, R - 3.8, R - 2.6, 0.5) * (0.5 + 0.5 * np.cos(np.radians(th - 315)) ** 2))
        put(sl, (16, 16, 18), band_mask(r, R - ring_w - 1.2, R - ring_w + 0.2, 0.5))
        # the wall: dark, lighter at the bottom where the light falls in
        wall = 14 + 10 * np.clip(np.cos(np.radians(th - 180)), 0, 1)
        put(sl, np.stack([wall, wall, wall * 1.05], -1), band_mask(r, face_r - 1.0, R - ring_w - 1.0, 0.8))
        k = np.clip(1 - r / face_r, 0, 1)
        put(sl, np.stack([20 + 7 * k, 19 + 7 * k, 21 + 8 * k], -1), band_mask(r, -5, face_r, 1.2))

    dial(CS, RS, 12.0, 150.0)
    dial(CT, RT, 12.0, 138.0)
    for C, R in SMALL.values():
        dial(C, R, 9.0, R - 12.0)
    A.im.paste(Image.fromarray(np.clip(base, 0, 255).astype("uint8")))

    GLOW = (54, 54, 50)

    def tick(C, r0, r1, deg, w, col, glow=GLOW):
        A.line([polar(C, r0, deg), polar(C, r1, deg)], col, w, glow=glow, gw=w * 2.0)

    def T(x, y, s, size, col=WHT, weight=b"SemiBold", sx=1.0, path=NUMF):
        if path == NUMF:
            font(NUMF, size * A.S * 3).set_variation_by_name(weight)
        A.text(x, y, s, path, size, col, scale_x=sx, glow=GLOW)

    # ---- the rev counter: a mark every 100, longer at 500, long and wide at every 1000; red 7-8
    RO = 131.0
    for i in range(0, 81):
        v = i / 10
        col = RED if v > 6.95 else WHT
        if i % 10 == 0:
            tick(CT, RO - 23.0, RO, rev(v), 3.8, col)
        elif i % 5 == 0:
            tick(CT, RO - 15.0, RO, rev(v), 2.2, col)
        else:
            tick(CT, RO - 10.0, RO, rev(v), 1.5, col)
    for v in range(9):
        p = polar(CT, 99.0, rev(v))
        T(p[0], p[1], str(v), 30.0, sx=1.08)
    A.text(593.0, 534.0, "x1000r/min", ARIAL, 10.2, (214, 214, 208), glow=GLOW)

    # ---- the speedometer: a mark every 5 km/h, the numbers every 20
    SO = 140.0
    for i in range(0, 37):
        v = i * 5
        if v % 20 == 0:
            tick(CS, SO - 24.0, SO, spd(v), 4.0, WHT)
        elif v % 10 == 0:
            tick(CS, SO - 17.0, SO, spd(v), 2.6, WHT)
        else:
            tick(CS, SO - 11.0, SO, spd(v), 1.8, WHT)
    for v in range(0, 181, 20):
        p = polar(CS, 100.0 - (6.0 if v >= 100 else 1.0) * abs(math.sin(math.radians(spd(v)))), spd(v))
        T(p[0], p[1], str(v), 24.5, sx=1.08)
    T(CS[0] + 80.0, CS[1] + 61.0, "km/h", 14.0, (220, 220, 214), weight=b"Regular")
    # the drum windows: the odometer (six drums) above the hub, the trip (three drums and the tenths) below it
    ODO = (CS[0] - 52.0, CS[1] - 48.0, CS[0] + 52.0, CS[1] - 28.0)
    TRIP = (CS[0] - 38.0, CS[1] + 30.0, CS[0] + 38.0, CS[1] + 50.0)
    for (x0, y0, x1, y1), n in ((ODO, 6), (TRIP, 4)):
        A.round_rect(x0, y0, x1, y1, 1.5, (6, 6, 7), outline=(34, 34, 36), w=0.8)
        pitch = (x1 - x0 - 4) / n
        for k in range(n):
            cx0 = x0 + 2 + k * pitch
            # (the trip's tenths drum is white on the photo: a readout can't colour one digit apart, so it is a lighter
            # grey here, after a printed point)
            A.rect(cx0 + 0.8, y0 + 2.0, cx0 + pitch - 0.8, y1 - 2.0, (64, 61, 58) if (n == 4 and k == 3) else (17, 16, 17))
        if n == 4:
            A.circle(x0 + 2 + 3 * pitch, y1 - 3.6, 0.9, (226, 226, 220))
    # the trip knob low in the face
    A.circle(CS[0] - 31.0, CS[1] + 99.0, 10.0, (10, 10, 11), outline=(40, 40, 42), w=0.8)
    A.circle(CS[0] - 31.0, CS[1] + 99.0, 5.6, (150, 140, 120), outline=(70, 66, 60), w=0.6)

    # ---- the small gauges: the scale on the left of each dial, the needle pivot in the middle
    def small_scale(C, a0, a1, n, r0, r1, red_from=None):
        for k in range(n + 1):
            a = a0 + (a1 - a0) * k / n
            col = RED if red_from is not None and k >= red_from else WHT
            tick(C, r0, r1, a, 2.6 if k in (0, n) else 2.0, col)

    def thermo(x, y, col):
        A.line([(x, y - 9.0), (x, y + 2.0)], col, 1.8)
        for k in range(3):
            A.line([(x, y - 7.0 + k * 3.0), (x + 4.0, y - 7.0 + k * 3.0)], col, 1.0)
        for dy in (4.5, 7.5):
            A.line([(x - 9.0 + i * 1.8, y + dy + (0.8 if i % 2 else -0.6)) for i in range(11)], col, 1.0)

    def pump(x, y, col):
        A.round_rect(x - 5.0, y - 8.0, x + 3.0, y + 8.0, 1.0, col)
        A.rect(x - 3.4, y - 6.2, x + 1.4, y - 1.8, (14, 14, 15))
        A.rect(x - 6.5, y + 7.0, x + 4.5, y + 8.6, col)
        A.line([(x + 3.0, y - 3.0), (x + 6.5, y - 0.5), (x + 6.5, y + 5.0), (x + 8.2, y + 5.5), (x + 8.2, y - 5.0), (x + 5.0, y - 8.5)], col, 1.2)

    def turbo(x, y, col):
        A.circle(x, y, 8.0, None, outline=col, w=1.4)
        for k in range(8):
            a = k * 45.0
            A.line([polar((x, y), 2.0, a), polar((x, y), 7.0, a + 30.0)], col, 1.2)
        A.line([(x - 9.0, y + 9.5), (x + 9.0, y + 9.5)], col, 1.4)

    CB, CW, CF = SMALL["boost"][0], SMALL["water"][0], SMALL["fuel"][0]
    SR0, SR1 = 52.0, 63.0
    ICON = (206, 206, 200)
    # boost: from the vacuum side (below 0) up past +; 0 and + printed
    small_scale(CB, -122.0, -56.0, 7, SR0, SR1)
    p = polar(CB, 44.0, -103.0)
    T(p[0], p[1], "0", 14.0)
    p = polar(CB, 47.0, -66.0)
    A.line([(p[0] - 5.0, p[1]), (p[0] + 5.0, p[1])], WHT, 1.8, glow=GLOW)
    A.line([(p[0], p[1] - 5.0), (p[0], p[1] + 5.0)], WHT, 1.8, glow=GLOW)
    turbo(CB[0] - 23.0, CB[1] - 28.0, ICON)
    # water: C at the bottom, H at the top, red marks at H
    small_scale(CW, -116.0, -50.0, 8, SR0, SR1, red_from=7)
    p = polar(CW, 60.0, -131.0)
    T(p[0], p[1], "C", 13.5)
    p = polar(CW, 61.0, -45.0)
    T(p[0], p[1], "H", 13.5)
    thermo(CW[0] - 14.0, CW[1] - 40.0, ICON)
    # fuel: E at the bottom, the pump at the top (the photo's shadow hides this scale: drawn like the water gauge's)
    small_scale(CF, -116.0, -50.0, 4, SR0, SR1)
    for k in (1, 3):
        tick(CF, SR0 + 4.0, SR1, -116.0 + 66.0 * (k - 0.5) / 4, 1.6, WHT)
    p = polar(CF, 60.0, -131.0)
    T(p[0], p[1], "E", 13.5)
    pump(CF[0] - 42.0, CF[1] - 37.0, ICON)

    # ---- the turn arrows between the dials (dark teal, as on the photo)
    def arrow(x, y, s):
        pts = [(x - s * 17.0, y), (x - s * 1.5, y - 14.0), (x - s * 1.5, y - 6.5), (x + s * 16.0, y - 6.5), (x + s * 16.0, y + 6.5), (x - s * 1.5, y + 6.5), (x - s * 1.5, y + 14.0)]
        A.poly(pts, (30, 62, 64))

    arrow(373.0, 418.0, 1)
    arrow(800.0, 408.0, -1)

    # ---- still needles (no data in the game): boost at idle, water at running heat
    def still_needle(C, deg, length, tail, w):
        A.line([polar(C, -tail, deg), polar(C, length, deg)], (150, 54, 34), w + 1.2)
        A.line([polar(C, -tail, deg), polar(C, length, deg)], NEEDLE, w, glow=(90, 36, 14), gw=w * 2.4)
        A.circle(C[0], C[1], 6.0, (12, 12, 13), outline=(36, 36, 38), w=0.8)

    still_needle(CB, -116.0, 64.0, 24.0, 3.0)
    still_needle(CW, -84.0, 64.0, 24.0, 3.0)

    A.final = A.finish(A.S, blur=1.6, strength=0.5)
    # (one colour all round the edge: Roblox's small copies blend the top row with the bottom one)
    ImageDraw.Draw(A.final).rectangle([0, 0, A.final.width - 1, A.final.height - 1], outline=(34, 32, 31), width=3 * S)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # ---- needles: an orange blade with a light core and a darker edge, the black cap on top
    def blade(length, tail, w0, w1, cap):
        K = 4
        k = sp.A * K
        L = max(length, tail, cap) + 2
        Wd, Hd = int(2 * (max(cap, w0) + 3) * k), int(2 * L * k)
        im = Image.new("RGBA", (Wd, Hd), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        cx, cy = Wd / 2, Hd / 2
        d.polygon([(cx - w0 / 2 * k, cy + tail * k), (cx + w0 / 2 * k, cy + tail * k), (cx + w1 / 2 * k, cy - length * k), (cx - w1 / 2 * k, cy - length * k)], fill=(176, 64, 36, 255))
        d.polygon([(cx - w0 * 0.36 * k, cy + tail * k), (cx + w0 * 0.36 * k, cy + tail * k), (cx + w1 * 0.36 * k, cy - length * k), (cx - w1 * 0.36 * k, cy - length * k)], fill=NEEDLE + (255,))
        d.polygon([(cx - w0 * 0.12 * k, cy), (cx + w0 * 0.12 * k, cy), (cx + w1 * 0.1 * k, cy - length * 0.96 * k), (cx - w1 * 0.1 * k, cy - length * 0.96 * k)], fill=(255, 182, 132, 255))
        if cap:
            d.ellipse([cx - cap * k, cy - cap * k, cx + cap * k, cy + cap * k], fill=(12, 12, 13, 255), outline=(40, 40, 42, 255), width=int(0.8 * k))
        return im.resize((max(2, Wd // K), max(2, Hd // K)), Image.LANCZOS)

    add_needle(sp, blade(133.0, 29.0, 5.0, 4.2, 8.0), CT[0], CT[1], "rpm", [(0, rev(0)), (8.4, rev(8.4))])
    add_needle(sp, blade(138.0, 34.0, 5.6, 4.6, 8.0), CS[0], CS[1], "kmh", [(0, spd(0)), (190, spd(190))])
    add_needle(sp, blade(64.0, 24.0, 3.4, 2.8, 6.0), CF[0], CF[1], "fuel", [(0, -116.0), (1, -50.0)])

    # ---- the drums: the odometer (the car's own miles, six drums) and the trip (all white on black: a readout can't
    # colour its last digit apart, so the photo's white tenths drum is a lighter grey drum with a printed point before it)
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
            m = t.resize((max(1, round(t.width / K)), max(1, round(t.height / K))), Image.LANCZOS)
            im = Image.new("RGBA", m.size, (255, 255, 255, 0))
            im.putalpha(m)
            g[ch] = (im, (pitch - m.width / sp.A) / 2, -m.height / sp.A / 2, pitch)  # (pen at the drum's left edge)

    drum_font("odo", 11.0, (ODO[2] - ODO[0] - 4) / 6, "0123456789")
    sp.readout("odo", ODO[2] - 2.0, (ODO[1] + ODO[3]) / 2, "r", 6, "odo", WHT)
    drum_font("trip", 11.0, (TRIP[2] - TRIP[0] - 4) / 4, "0123456789")
    sp.readout("trip", TRIP[2] - 2.0, (TRIP[1] + TRIP[3]) / 2, "r", 5, "trip", WHT)

    sprites = {ch: {"im": Image.new("RGBA", (4, 4), (0, 0, 0, 0))} for ch in "RNP1234567"}
    sp.gear = {"x": 0, "y": 0, "sprites": sprites}
    return sp
