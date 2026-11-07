"""The Revuelto, Aventador SV and Huracan screens in layers, to run live in the game (owner's driving
photos, 2026-11-04: imports/refs/*_driving_owner*.png). Each car is a Spec: a background picture and
pieces laid over it, the same list the game's DashGauges `liveCluster` style works from, so a preview
drawn here is what the game shows. Coordinates are pixels of that car's photo.

    python tools/lambo/cluster_live.py outdir preview      the driving look next to the owner's photos
    python tools/lambo/cluster_live.py outdir assets       pictures for upload
    python tools/lambo/cluster_live.py outdir lua          src/client/LamboClusterArt.lua (ids from cluster_ids.json)

No maker's marks: words on the real screens that name the maker are left out.
"""

import json
import math
import os
import sys
import tempfile

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cluster_art import ARIAL, ARIAL_B, REFS, REG, ROBO_B, TECH, TECH_R, WIDE, Art, font, streaks  # noqa: E402
from cluster_art import lp700 as lp700_art  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "..")
BG_MAX = 1000  # a background half at most this wide


def rgba_from_black(im):
    """a picture on black -> its colours with alpha (light adds, glow fades out)"""
    a = np.asarray(im.convert("RGB")).astype(float)
    alpha = a.max(axis=2)
    safe = np.maximum(alpha, 1)[..., None]
    rgb = np.clip(a * 255 / safe, 0, 255)
    return Image.fromarray(np.dstack([rgb, alpha]).astype("uint8"), "RGBA")


class Spec:
    def __init__(self, name, W, H, A, bg_scale, ox, oy):
        self.name, self.W, self.H, self.A, self.bg_scale = name, W, H, A, bg_scale
        self.ox, self.oy = ox, oy  # design (0, 0) in photo pixels
        self.bg = None
        self.blocks, self.fills, self.shows, self.readouts, self.labels = [], [], [], [], []
        self.fuels = []  # bars that follow the fuel tank
        self.needles = []
        self.marker = None
        self.gear = None
        self.fonts = {}
        self.redline, self.idle = 8.5, 0.9
        self.bg_tint = None

    def font(self, name, path, size, chars, stroke=0.0, shear=0.2, track=0.0):
        self.fonts[name] = {"path": path, "size": size, "chars": chars, "stroke": stroke, "shear": shear, "track": track, "g": {}}

    def box(self, art, box, mask_pts=None, black=False):
        """a piece of an Art, box in photo pixels -> (RGBA at A px per design px, left, top)"""
        x0, y0, x1, y1 = box
        S = art.S
        im = art.final.crop((int((x0 - art.ox) * S), int((y0 - art.oy) * S), int((x1 - art.ox) * S), int((y1 - art.oy) * S)))
        size = (max(1, round((x1 - x0) * self.A)), max(1, round((y1 - y0) * self.A)))
        if black:
            out = rgba_from_black(im.resize(size, Image.LANCZOS))
        else:
            out = im.resize(size, Image.LANCZOS).convert("RGBA")
        if mask_pts:
            K = 4
            m = Image.new("L", (size[0] * K, size[1] * K), 0)
            k = self.A * K
            ImageDraw.Draw(m).polygon([((p[0] - x0) * k, (p[1] - y0) * k) for p in mask_pts], fill=255)
            out.putalpha(ImageChops.multiply(out.getchannel("A"), m.resize(size, Image.LANCZOS)))
        return out, x0 - self.ox, y0 - self.oy

    def add_block(self, art, box, pts, v):
        im, left, top = self.box(art, box, pts)
        self.blocks.append({"im": im, "left": left, "top": top, "v": v})

    def add_show(self, im_left_top, when, name=""):
        im, left, top = im_left_top
        self.shows.append({"im": im, "left": left, "top": top, "when": when})

    def readout(self, fnt, x, y, align, length, bind, tint=(255, 255, 255), when=None):
        self.readouts.append({"font": fnt, "x": x - self.ox, "y": y - self.oy, "align": align, "len": length, "bind": bind, "tint": tint, "when": when})

    def build_fonts(self):
        for f in self.fonts.values():
            for ch in f["chars"]:
                im, ox, oy, adv = glyph(ch, f, self.A)
                bb = im.getbbox()
                if bb:
                    im = im.crop(bb)
                    ox += bb[0] / self.A
                    oy += bb[1] / self.A
                f["g"][ch] = (im, ox, oy, adv)
        for e in self.gear["sprites"].values():
            im = e["im"]
            bb = im.getbbox()
            if bb:
                cx, cy = im.width / 2, im.height / 2
                dx, dy = math.ceil(max(cx - bb[0], bb[2] - cx)), math.ceil(max(cy - bb[1], bb[3] - cy))
                e["im"] = im.crop((int(cx - dx), int(cy - dy), int(cx + dx), int(cy + dy)))


def glyph(ch, f, A):
    """one slanted character on a line through (0, 0) at the digits' middle: (image, ox, oy, adv), the
    last three in design pixels"""
    Q = 4
    size = f["size"]
    fo = font(ROBO_B if ch == ":" and f["path"] in (TECH, TECH_R) else f["path"], size * A * Q)
    ref = font(f["path"], size * A * Q)
    adv = fo.getlength(ch)
    pad = round(size * A * Q * 0.35 + f["stroke"] * A * Q)
    asc, desc = ref.getmetrics()
    w, h = round(adv) + pad * 2, asc + desc + pad * 2
    m = Image.new("L", (w, h))
    ImageDraw.Draw(m).text((pad, pad), ch, font=fo, fill=255, stroke_width=round(f["stroke"] * A * Q))
    bb = ref.getbbox("0")
    mid = pad + (bb[1] + bb[3]) / 2
    sh = f["shear"]
    m = m.transform(m.size, Image.AFFINE, (1, sh, -sh * mid, 0, 1, 0), Image.BICUBIC)
    img = Image.new("RGBA", (w, h), (255, 255, 255, 0))
    img.putalpha(m)
    img = img.resize((max(1, round(w / Q)), max(1, round(h / Q))), Image.LANCZOS)
    return img, -pad / Q / A, -mid / Q / A, (adv / Q / A) + f["track"]


def hollow(shape, size, A, shear, line, col, glow):
    """a gear shown as a thin glowing outline. shape: a mask of the letter at A*4 px"""
    Q = 4
    m = shape.filter(ImageFilter.MaxFilter(1 + 2 * max(1, round(line * A * Q))))
    edge = ImageChops.subtract(m, shape)
    out = Image.new("RGBA", shape.size, col + (0,))
    out.putalpha(edge)
    if glow:
        halo = edge.filter(ImageFilter.GaussianBlur(glow * A * Q)).point(lambda a: min(255, int(a * 1.6)))
        h = Image.new("RGBA", shape.size, col + (0,))
        h.putalpha(halo)
        h.alpha_composite(out)
        out = h
    return out.resize((shape.width // Q, shape.height // Q), Image.LANCZOS)


def letter_mask(ch, path, size, A, shear, stroke=0.0, rounded=0.0):
    Q = 4
    fo = font(path, size * A * Q)
    pad = round(size * A * Q * 0.3)
    bb = fo.getbbox(ch)
    w, h = bb[2] - bb[0] + pad * 2, bb[3] - bb[1] + pad * 2
    m = Image.new("L", (w, h))
    ImageDraw.Draw(m).text((pad - bb[0], pad - bb[1]), ch, font=fo, fill=255, stroke_width=round(stroke * A * Q))
    if rounded:
        m = m.filter(ImageFilter.GaussianBlur(rounded * A * Q)).point(lambda a: 255 if a > 127 else 0)
    return m.transform(m.size, Image.AFFINE, (1, shear, -shear * h / 2, 0, 1, 0), Image.BICUBIC)


# ---------------------------------------------------------------------------------- previews
def values(st):
    kmh = st.get("kmh", True)
    mph = st["mph"]
    speed = mph * 1.609 if kmh else mph
    alt = mph if kmh else mph * 1.609
    v = st["v"]
    order = ["R", "N", "1", "2", "3", "4", "5", "6", "7"]
    g = st["gear"]
    i = order.index(g)
    manual = st.get("manual", False)
    return {
        "speed": str(int(speed + 0.5)),
        "alt": str(int(alt + 0.5)),
        "rpm": str(int(v * 100) * 10),
        "odo": st.get("odo", "000350"),
        "odo5": st.get("odo", "000350"),
        "odoTrim": st.get("odo", "000350").lstrip("0") or "0",
        "range": st.get("range", "200"),
        "clock": st.get("clock", "10:45"),
        "date": st.get("date", "10.08.2019"),
        "unit": "km/h" if kmh else "mph",
        "altUnit": "mph" if kmh else "km/h",
        "distUnit": "km" if kmh else "mi",
        "driveMode": "SPORT" if manual else "NORMAL",
        "trip": st.get("trip", "0.0"),
        "mode": "CORSA" if manual else "SPORT",
        "gearLeft": "".join(order[:i]),
        "gearRight": "".join(order[i + 1 :]) + ("" if manual else "A"),
        "gearLeft4": "".join(order[max(i - 4, 0) : i]),
        "gearRight4": "".join(order[i + 1 : i + 5]),
        "gearPrev": order[i - 1] if i >= 3 else "",
        "gearNext": order[i + 1] if i + 1 < len(order) and i >= 2 else "",
        "temp": "100.5",
        "tempUnit": "°F",
        "gBrake": st.get("gBrake", "0.0"),
        "gAccel": st.get("gAccel", "0.0"),
    }


def active(when, st):
    if when is None:
        return True
    manual = st.get("manual", False)
    table = {
        "parked": st["mph"] < 1,
        "moving": st["mph"] >= 1,
        "corsa": manual,
        "sport": not manual,
        "lights": st.get("lights", False),
        "tcoff": st.get("tcoff", False),
        "accel": float(st.get("gAccel", "0.0")) > 0.1,
        "sv": st.get("sv", False),
        "kmh": st.get("kmh", True),
        "mph": not st.get("kmh", True),
        "gearN": st["gear"] == "N",
        "gearR": st["gear"] == "R",
        "gearD": st["gear"] not in ("N", "R"),
    }
    return table[when]


def compose(spec, st, scale=2):
    W, H = round(spec.W * scale), round(spec.H * scale)
    out = spec.bg.resize((W, H), Image.LANCZOS).convert("RGBA")
    if spec.bg_tint and active(spec.bg_tint["when"], st):
        t = np.asarray(out.convert("RGB")).astype(float) * (np.array(spec.bg_tint["color"]) / 255)
        out = Image.fromarray(t.astype("uint8")).convert("RGBA")

    def paste(im, left, top, tint=None):
        im2 = im.resize((max(1, round(im.width * scale / spec.A)), max(1, round(im.height * scale / spec.A))), Image.LANCZOS)
        if tint:
            r = Image.new("RGBA", im2.size, tuple(tint) + (0,))
            r.putalpha(im2.getchannel("A"))
            im2 = r
        out.alpha_composite(im2, (max(0, round(left * scale)), max(0, round(top * scale))))

    v = st["v"]
    for b in spec.blocks:
        if b["v"] < (st["mph"] if b.get("bind") == "mph" else v):
            paste(b["im"], b["left"], b["top"])
    for f in spec.fills:
        frac = interp(f["pts"], v + f.get("lead", 0))
        w = max(1, round(f["im"].width * frac))
        paste(f["im"].crop((0, 0, w, f["im"].height)), f["left"], f["top"])
    for f in spec.fuels:
        w = max(1, round(f["im"].width * 0.62))
        paste(f["im"].crop((0, 0, w, f["im"].height)), f["left"], f["top"])
    for s in spec.shows:
        if active(s["when"], st):
            paste(s["im"], s["left"], s["top"])
    for n in spec.needles:
        val = {"rpm": v, "fuel": st.get("fuel", 0.75), "kmh": st["mph"] * 1.609, "mph": st["mph"], "dial": st["mph"] * 1.609 if st.get("kmh", True) else st["mph"]}[n["bind"]]
        pts = n["alt"] if n["bind"] == "dial" and not st.get("kmh", True) else n["pts"]
        im = n["im"].rotate(-interp(pts, val), resample=Image.BICUBIC, expand=True)
        paste(im, n["x"] - im.width / spec.A / 2, n["y"] - im.height / spec.A / 2)
    if spec.marker:
        pts = spec.marker["pts"]
        x0, y0, x1, y1 = [interp([(p[0], p[1 + i]) for p in pts], v) for i in range(4)]
        g = spec.marker.get("glow", 0)
        if g:
            halo = Image.new("L", out.size, 0)
            ImageDraw.Draw(halo).line([(x0 * scale, y0 * scale), (x1 * scale, y1 * scale)], fill=255, width=max(1, round(spec.marker["w"] * g * scale)))
            lay = Image.new("RGBA", out.size, tuple(spec.marker["color"]) + (0,))
            lay.putalpha(halo.point(lambda a: int(a * 0.4)))
            out.alpha_composite(lay)
        d = ImageDraw.Draw(out)
        d.line([(x0 * scale, y0 * scale), (x1 * scale, y1 * scale)], fill=tuple(spec.marker["color"]) + (255,), width=max(1, round(spec.marker["w"] * scale)))
    for l in spec.labels:
        if active(l.get("when"), st):
            ImageDraw.Draw(out).text((l["x"] * scale, (l["y"] - l["h"] / 2) * scale), st.get(l["bind"], {"bandFM": "FM"}.get(l["bind"], "Radio")), font=font(REG, l["h"] * scale * 0.82), fill=tuple(l["color"]) + (255,))
    if spec.gear:
        e = spec.gear["sprites"].get(st["gear"])
        if e:
            paste(e["im"], spec.gear["x"] - e["im"].width / spec.A / 2, spec.gear["y"] - e["im"].height / spec.A / 2)
    vals = values(st)
    for r in spec.readouts:
        if not active(r["when"], st):
            continue
        s = vals[r["bind"]]
        f = spec.fonts[r["font"]]
        s = s[: r["len"]]
        width = sum(f["g"][c][3] if c in f["g"] else 0 for c in s)
        pen = r["x"] - width if r["align"] == "r" else (r["x"] - width / 2 if r["align"] == "m" else r["x"])
        for c in s:
            if c in f["g"]:
                im, ox, oy, adv = f["g"][c]
                paste(im, pen + ox, r["y"] + oy, r["tint"])
                pen += adv
    return out.convert("RGB")


def interp(pts, v):
    if v <= pts[0][0]:
        return pts[0][1]
    for (a, x), (b, y) in zip(pts, pts[1:]):
        if a <= v <= b:
            return x + (y - x) * (v - a) / (b - a) if b > a else y
    return pts[-1][1]


def side_by_side(photo_box, name, im, out):
    p = Image.open(os.path.join(REFS, name)).convert("RGB")
    p = p.crop(photo_box)
    W = im.width
    h = round(p.height * W / p.width)
    s = Image.new("RGB", (W, h + im.height + 14), (60, 60, 64))
    s.paste(p.resize((W, h), Image.LANCZOS), (0, 0))
    s.paste(im, (0, h + 14))
    s.save(out, quality=92)


# ---------------------------------------------------------------------------------- Revuelto
def revuelto():
    box = (330, 360, 1690, 860)
    A = Art("revuelto_cluster_owner.png", box, S=3, bg=(7, 7, 9))
    sp = Spec("revuelto", box[2] - box[0], box[3] - box[1], 1.2, 1.35, box[0], box[1])
    sp.redline, sp.idle = 9.5, 0.9
    PINK = (255, 214, 222)
    RED = (238, 34, 52)
    WHITE = (236, 238, 242)
    GL = (120, 22, 40)
    DIM = (92, 96, 102)
    dr11 = Image.open(os.path.join(REFS, "revuelto_cluster_driving_owner_2.png")).convert("RGB")

    # the faint hexagons at both sides
    for row in range(0, 24):
        for col in range(0, 12):
            x = 1490 + col * 26 + (row % 2) * 13
            y = 500 + row * 15
            if 1505 < x < 1650:
                A.line([(x + 8 * math.cos(math.radians(a)), y + 8 * math.sin(math.radians(a))) for a in range(30, 391, 60)], (21, 22, 26), 1)
            x2 = 368 + col * 26 + (row % 2) * 13
            if 395 < x2 < 520 and y > 560:
                A.line([(x2 + 8 * math.cos(math.radians(a)), y + 8 * math.sin(math.radians(a))) for a in range(30, 391, 60)], (21, 22, 26), 1)

    CX = 1010
    R_TOP, CY_TOP = 1501, 1918
    R_LOW, CY_LOW = 1426, 1907

    def top(th, k=0):
        a = math.radians(th)
        return (CX + (R_TOP - k) * math.sin(a), CY_TOP - (R_TOP - k) * math.cos(a))

    def low(th):
        a = math.radians(th)
        return (CX + R_LOW * math.sin(a), CY_LOW - R_LOW * math.cos(a))

    MARK = {0: -19.8, 1: -18.1, 2: -16.3, 3: -14.2, 4: -11.5, 5: -8.43, 6: -4.6, 7: 0.0, 8: 5.54, 9: 12.1, 10: 19.9}
    RED_FROM = 15.2  # (from the driving photo: the red steps start past 9)

    def rpm_th(v):
        return interp(sorted(MARK.items()), v)

    # the tape: two lines and cross bars
    th = MARK[0]
    steps = []
    while th < MARK[10]:
        steps.append(th)
        th += 0.62 if th > -6 else 0.34
    steps.append(MARK[10])
    for a, b in zip(steps, steps[1:]):
        red = a >= RED_FROM
        col = (246, 44, 62) if red else (214, 218, 224)
        p0, p1 = top(a), top(b)
        q0, q1 = top(a, 8.5), top(b, 8.5)
        A.line([p0, p1], col, 1.2)
        A.line([q0, q1], col, 1.2)
        A.line([p0, q0], tuple(int(v * 0.75) for v in col), 0.9)
    A.line([top(MARK[10]), top(MARK[10], 9)], RED, 1.2)
    for v, th in MARK.items():
        col = RED if v >= 10 else (225, 228, 234)
        for k in range(12):
            a, b = top(th, 7 + k * 2.6), top(th, 7 + (k + 1) * 2.6)
            f = (1 - k / 12) ** 0.7
            A.line([a, b], tuple(int(c * f) for c in col), 1.7)
    for v in [x + 0.5 for x in range(0, 10)]:
        th = rpm_th(v)
        col = RED if th > RED_FROM else (150, 155, 162)
        for k in range(14):
            a, b = top(th, 9 + k * 2.6), top(th, 9 + (k + 1) * 2.6)
            f = (1 - k / 14) * 0.7
            A.line([a, b], tuple(int(c * f) for c in col), 1.1)
    # the red steps at the end
    for th in (15.2, 16.3, 17.4, 18.5):
        for k in range(16):
            a, b = top(th, 6 + k * 2.4), top(th, 6 + (k + 1) * 2.4)
            A.line([a, b], tuple(int(c * (1 - k / 16)) for c in (226, 36, 50)), 1.5)

    NUM = {0: (524, 548), 1: (558, 536), 2: (604, 520), 3: (655, 504), 4: (716, 494), 5: (797, 478), 6: (896, 466), 7: (1010, 461), 8: (1150, 466), 9: (1315, 489), 10: (1504, 544)}
    for v, (x, y) in NUM.items():
        col = (255, 38, 58) if v >= 10 else (240, 244, 248)
        A.text(x, y, str(v), TECH, 32, col, stroke=0.15, strokecol=col, glow=(90, 12, 20) if v >= 10 else None)
    marks = sorted(MARK.values())
    th = -19.0
    while th < 19.6:
        nxt = th + 0.25
        if not any(abs(th - m) < 0.13 for m in marks):
            c = (60, 62, 68) if th < -12 else (92, 96, 104)
            A.line([low(th), low(nxt)], c, 2.2)
        th = nxt
    A.text(443, 539, "%E-POTENZA x10", ROBO_B, 12.5, (52, 158, 180), rot=-18)
    A.text(474, 562, "RPM x1000", ROBO_B, 12.5, (226, 228, 232), rot=-18)
    A.text(476, 601, "% RICARICA x10", ROBO_B, 11.5, (44, 46, 50), rot=-20)

    # the two chevrons
    A.line([(425, 476), (490, 499), (700, 435), (732, 397)], (150, 92, 104), 1.2)
    A.line([(462, 489), (490, 499), (700, 435), (722, 410)], PINK, 2.0, glow=GL, gw=5)
    A.line([(1287, 391), (1320, 425), (1527, 486), (1595, 461)], (150, 92, 104), 1.2)
    A.line([(1298, 403), (1320, 425), (1527, 486), (1560, 474)], PINK, 2.0, glow=GL, gw=5)

    # coolant
    A.poly([(486, 474), (590, 441), (593, 451), (490, 486)], (226, 232, 240))
    A.line([(592, 448), (652, 430), (697, 418)], (90, 94, 100), 1.3)
    A.line([(652, 416), (654, 431), (695, 421), (690, 408)], (240, 44, 60), 1.8)
    A.text(473, 464, "50", REG, 18, WHITE)
    A.text(690, 398, "130", REG, 18, (244, 52, 66))
    A.icon((545, 412, 600, 442), floor=38, gain=1.5)
    # oil: temperature, pressure
    A.line([(1322, 418), (1532, 476), (1537, 464)], (92, 96, 102), 1.3)
    A.line([(1325, 402), (1327, 418)], (240, 44, 60), 1.8)
    A.line([(1340, 404), (1337, 420), (1326, 417)], (240, 44, 60), 1.8)
    A.line([(1372, 412), (1369, 427)], (110, 114, 120), 1.3)
    A.poly([(1373, 416), (1418, 429), (1415, 442), (1370, 429)], (214, 224, 236))
    A.line([(1443, 432), (1440, 446), (1454, 449), (1457, 436)], (240, 44, 60), 1.8)
    A.poly([(1490, 455), (1534, 467), (1531, 479), (1487, 467)], (214, 224, 236))
    A.text(1326, 391, "170", REG, 18, (244, 52, 66))
    A.icon((1345, 386, 1405, 416), floor=38, gain=1.5)
    A.text(1422, 414, "50", REG, 18, WHITE)
    A.text(1451, 419, "10", REG, 18, (244, 52, 66))
    A.icon((1470, 420, 1502, 440), floor=38, gain=1.5)
    A.text(1515, 442, "bar", ROBO_B, 15, WHITE)
    A.text(1545, 455, "0", REG, 16, WHITE)
    # battery, fuel
    A.text(391, 494, "100", REG, 18, (206, 208, 212))
    A.line([(382, 507), (376, 540), (371, 590), (367, 640), (366, 668)], (92, 96, 102), 1.4)
    for y in (507, 557):
        A.line([(354, y), (376 - (y - 507) * 0.1, y)], (70, 74, 80), 1.2)
    A.rect(353, 580, 364, 708, (224, 228, 236))
    A.line([(347, 709), (367, 709)], (240, 44, 60), 1.8)
    A.line([(347, 659), (367, 659)], (150, 44, 60), 1.2)
    A.text(363, 721, "0", REG, 17, (244, 52, 66))
    A.text(385, 720, "%", REG, 15, (160, 164, 170))
    A.icon((366, 688, 402, 712), floor=38, gain=1.5)
    A.text(1626, 481, "100", REG, 18, (206, 208, 212))
    A.line([(1640, 492), (1651, 540), (1661, 600), (1668, 640)], (92, 96, 102), 1.4)
    for y in (492, 544):
        A.line([(1641 + (y - 492) * 0.13, y), (1668, y)], (70, 74, 80), 1.2)
    A.rect(1657, 595, 1669, 693, (224, 228, 236))
    A.line([(1655, 635), (1677, 635)], (240, 44, 60), 1.8)
    A.text(1659, 706, "0", REG, 17, (244, 52, 66))
    A.text(1635, 706, "%", REG, 15, (190, 194, 200))
    A.icon((1620, 668, 1656, 698), floor=38, gain=1.5)
    A.text(1604, 537, "ESC", ROBO_B, 11.5, (240, 40, 56))
    A.text(1604, 550, "CORSA", ROBO_B, 11.5, (240, 40, 56))
    # top row
    A.text(798, 389, "20.5°C", REG, 21, WHITE)

    def ring(cx, cy, col):
        prof = [(-88, 90), (-68, 91), (-66, 95), (-50, 96), (-47, 92), (-30, 93), (-27, 98), (-14, 98), (-11, 94), (11, 94), (14, 98), (27, 98), (30, 93), (47, 92), (50, 96), (66, 95), (68, 91), (88, 90)]
        pts = []
        for (a0, r0), (a1, r1) in zip(prof, prof[1:]):
            n = max(1, int(abs(a1 - a0) / 2))
            for k in range(n + 1):
                f = k / n
                t = math.radians(a0 + (a1 - a0) * f)
                r = r0 + (r1 - r0) * f
                pts.append((cx + r * math.sin(t), cy - r * math.cos(t)))
        A.line(pts, col, 1.8)
        A.line([(cx + 64 * math.sin(math.radians(x)), cy - 64 * math.cos(math.radians(x))) for x in range(-17, 18, 3)], (232, 234, 238), 2.0)
        for x in range(-62, 63, 4):
            t = math.radians(x)
            A.circle(cx + 55 * math.sin(t), cy - 55 * math.cos(t), 0.85, (200, 202, 208))
        A.line([(cx + 45 * math.sin(math.radians(x)), cy - 45 * math.cos(math.radians(x))) for x in range(-70, 71, 3)], (240, 228, 232), 3.0, glow=(80, 14, 24), gw=4)

    ring(782, 868, (232, 40, 56))
    A.curved(782, 868, 75, 0, "CORSA", ROBO_B, 13.5, (244, 48, 64), track=0.5)
    A.curved(782, 868, 77, -49, "SPORT", ROBO_B, 11, (88, 90, 96), track=0.2)
    A.curved(782, 868, 77, 50, "ESC OFF", ROBO_B, 11, (88, 90, 96), track=0.2)
    ring(1243, 868, (150, 40, 52))
    A.curved(1243, 868, 75, 2, "PERFORMANCE", ROBO_B, 12, (236, 44, 60), track=0.2)
    A.curved(1243, 868, 77, -62, "HYBRID", ROBO_B, 11, (88, 90, 96), track=0.2)
    A.rect(330, 846, 1690, 860, (7, 7, 9))
    A.line([(1336, 745), (1570, 743)], (120, 124, 130), 1.3)
    A.line([(1448, 754), (1448, 770)], (190, 194, 200), 1.3)
    A.icon((1518, 750, 1560, 770), floor=34, gain=1.5)
    A.line([(455, 755), (690, 754)], (40, 42, 46), 1.1)
    # (the music note, from the driving photo)
    c = dr11.crop((332, 563, 354, 590))
    c = c.resize((c.width * 1 * A.S * 11 // 10, c.height * A.S * 11 // 10), Image.LANCZOS)
    A.im.paste(ImageChops.lighter(A.im.crop((int((512 - A.ox) * A.S), int((756 - A.oy) * A.S), int((512 - A.ox) * A.S) + c.width, int((756 - A.oy) * A.S) + c.height)), c), (int((512 - A.ox) * A.S), int((756 - A.oy) * A.S)))
    A.d = ImageDraw.Draw(A.im)
    A.final = A.finish(A.S, blur=3.0, strength=0.8)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # the fills
    F = Art("revuelto_cluster_owner.png", box, S=3, bg=(0, 0, 0))
    for a, b in zip([MARK[0] + i * 0.2 for i in range(199)], [MARK[0] + (i + 1) * 0.2 for i in range(199)]):
        if b > MARK[10]:
            break
        F.poly([top(a, 9), top(b, 9), top(b, 20), top(a, 20)], (232, 234, 238))
    F.final = F.finish(F.S, blur=1, strength=0)
    fbox = (496, 400, 1520, 560)
    im, left, top_ = sp.box(F, fbox, black=True)
    xs = [(v / 2, (top(rpm_th(v / 2), 14)[0] - fbox[0]) / (fbox[2] - fbox[0])) for v in range(0, 21)]
    sp.fills.append({"im": im, "left": left, "top": top_, "pts": xs, "lead": 0})
    C = Art("revuelto_cluster_owner.png", box, S=3, bg=(0, 0, 0))
    a = MARK[0]
    while a < MARK[10]:
        b = a + 0.2
        col = (54, 172, 192) if (a * 5) % 8 > 0.6 else (24, 92, 104)
        C.poly([top(a, -7.5), top(b, -7.5), top(b, -1.2), top(a, -1.2)], col)
        a = b
    C.final = C.finish(C.S, blur=1, strength=0)
    im, left, top_ = sp.box(C, fbox, black=True)
    xs = [(v / 2, (top(rpm_th(v / 2), -4)[0] - fbox[0]) / (fbox[2] - fbox[0])) for v in range(0, 21)]
    sp.fills.append({"im": im, "left": left, "top": top_, "pts": xs, "lead": 0.55})
    sp.marker = {"color": (232, 26, 44), "w": 4.4, "glow": 2.4, "pts": [(v / 2, *[c - o for c, o in zip(top(rpm_th(v / 2), -2), (sp.ox, sp.oy))], *[c - o for c, o in zip(top(rpm_th(v / 2), 46), (sp.ox, sp.oy))]) for v in range(0, 21)]}

    L = Art("revuelto_cluster_owner.png", box, S=3, bg=(0, 0, 0))
    L.icon((650, 808, 684, 830), floor=34, gain=1.5)
    L.final = L.finish(L.S, blur=1, strength=0)
    sp.add_show(sp.box(L, (650, 808, 684, 830), black=True), "lights")

    # the gear: thin hollow letters, the next ones small and grey
    K = sp.A
    sprites = {}
    for ch in "RNP1234567":
        m = letter_mask(ch, TECH, 200, K, 0.3, rounded=2.0)
        sprites[ch] = {"im": hollow(m, 200, K, 0.26, 1.6, (236, 34, 52), 2.2)}
    sprites["N"], sprites["P"] = sprites["P"], sprites["N"]  # (a car in neutral shows P here)
    sp.gear = {"x": 1006 - sp.ox, "y": 612 - sp.oy, "sprites": sprites}
    sp.font("next", TECH, 32, "1234567", shear=0.26)
    sp.readout("next", 1104, 612, "m", 1, "gearNext", (120, 122, 126), "moving")
    sp.readout("next", 908, 612, "m", 1, "gearPrev", (120, 122, 126), "moving")
    sp.font("speed", TECH, 54, "0123456789", stroke=0.5, shear=0, track=1.0)
    sp.readout("speed", 1013, 774, "m", 3, "speed")
    sp.font("clock", REG, 22, "0123456789:", shear=0)
    sp.readout("clock", 1216, 384, "m", 5, "clock")
    sp.font("odo", REG, 21, "0123456789", stroke=0.2, shear=0)
    sp.readout("odo", 1343, 761, "l", 6, "odo")
    sp.readout("odo", 1461, 761, "l", 3, "range")
    sp.font("unit", ROBO_B, 13.5, "kmhpi/", shear=0)
    sp.readout("unit", 1013, 810, "m", 4, "unit")
    sp.readout("unit", 1417, 763, "l", 2, "distUnit")
    sp.readout("unit", 1496, 763, "l", 2, "distUnit")
    sp.labels.append({"x": 541 - sp.ox, "y": 771 - sp.oy, "w": 150, "h": 21, "bind": "station", "color": (222, 224, 228)})
    return sp


# ---------------------------------------------------------------------------- Aventador SV
def sv():
    box = (0, 92, 767, 400)
    A = Art("aventador_sv_cluster_owner.png", box, S=6, bg=(8, 8, 10))
    sp = Spec("sv", box[2] - box[0], box[3] - box[1], 2.0, 2.4, box[0], box[1])
    sp.redline, sp.idle = 8.5, 0.9
    W, H = A.W * A.S, A.H * A.S
    CX, CY, RX, RY = 383.0, 272.0, 212.0, 160.0
    black = (11, 11, 13)

    def e(phi, k=1.0):
        a = math.radians(phi)
        return (CX + RX * k * math.sin(a), CY - RY * k * math.cos(a))

    glowY = streaks(W, H)
    mask = Image.new("L", (W, H), 0)
    md = ImageDraw.Draw(mask)
    Y = lambda pts: md.polygon([A.q(*p) for p in pts], fill=255)
    rim = [e(p, 1.03) for p in range(-22, 23, 2)]
    TOP = [(203, 128), (284, 116)] + rim + [(482, 116), (562, 127)]
    Y(TOP + [(595, 193), (595, 240), (566, 266), (528, 268), (428, 322.5), (339, 321.5), (238, 266), (202, 266), (174, 240), (177, 188)])
    Y([(53, 218), (131, 221), (133, 268), (22, 267)])
    Y([(630, 225), (708, 226), (738, 275), (630, 275)])
    A.im.paste(glowY, (0, 0), mask)
    A.poly([(170, 233), (181, 236), (196, 246), (193, 258), (202, 266), (170, 266)], (8, 8, 10))
    A.poly([(600, 236), (590, 238), (574, 246), (577, 258), (566, 268), (600, 268)], (8, 8, 10))
    A.poly([(150, 266), (238, 266), (339, 322), (150, 322)], (8, 8, 10))
    A.poly([(528, 268), (620, 268), (620, 322), (428, 323)], (8, 8, 10))

    NUM = {n: 20.2 * (n - 6) for n in range(2, 11)}
    edge = []
    for n in range(2, 11):
        ph = NUM[n]
        edge += [(ph - 5.4, 0.79), (ph - 3.4, 0.822), (ph + 3.4, 0.822), (ph + 5.4, 0.79)]

    def kin(ph):
        pts = sorted(edge)
        if ph <= pts[0][0]:
            return pts[0][1]
        for (a, ka), (b, kb) in zip(pts, pts[1:]):
            if a <= ph <= b:
                return ka + (kb - ka) * (ph - a) / max(b - a, 1e-6)
        return pts[-1][1]

    PHI0, PHI1 = -77.0, 77.0
    N = 32
    OUT = 1.0
    outer = [e(PHI0 + (PHI1 - PHI0) * i / 120, OUT) for i in range(121)]
    inner = [e(PHI1 - (PHI1 - PHI0) * i / 240, kin(PHI1 - (PHI1 - PHI0) * i / 240)) for i in range(241)]
    A.poly(outer + inner, (14, 16, 20))
    A.poly([e(50 + 27 * i / 40, OUT) for i in range(41)] + [e(77 - 27 * i / 40, kin(77 - 27 * i / 40)) for i in range(41)], (40, 6, 9))
    for i in range(N + 1):
        ph = PHI0 + (PHI1 - PHI0) * i / N
        if ph >= 50.0:
            A.line([e(ph, OUT), e(ph - 1.0, kin(ph))], (214, 36, 40), 0.7)
        else:
            A.line([e(ph, OUT), e(ph - 0.5, kin(ph))], (236, 240, 244), 1.05)
            A.line([e(ph - 0.85, OUT), e(ph - 1.3, kin(ph))], (120, 124, 130), 0.5)
    A.line([e(p, kin(p)) for p in [PHI0 - 6 + i * 0.5 for i in range(int((PHI1 - PHI0 + 12) / 0.5) + 1)]], (236, 238, 242), 0.95)

    for n, (x, y) in {2: (216, 252), 3: (246, 213), 4: (283, 182), 5: (331, 162), 6: (382, 155), 7: (437, 161), 8: (483, 182)}.items():
        A.text(x, y, str(n), TECH, 24, black, shear=0.24)
    A.text(524, 214, "9", TECH, 24, (238, 52, 48), shear=0.24, stroke=0.45, strokecol=(255, 236, 190))
    A.text(549, 253, "10", TECH, 24, (238, 52, 48), shear=0.24, stroke=0.45, strokecol=(255, 236, 190))

    # under the dial
    A.line([(177, 266), (238, 266), (339, 322), (428, 323), (528, 268), (590, 268)], (196, 202, 210), 0.85)
    A.poly([(244, 268), (326, 268), (337, 274), (326, 280), (265, 280)], black)
    A.poly([(431, 275), (441, 269), (521, 269), (499, 280), (441, 280)], black)

    # the g-force square
    def G(x, y):
        return (320 + x / 10, 262 + y / 10)

    for rows in [[(580, 129), (690, 129), (697, 146), (573, 146)], [(569, 151), (701, 151), (706, 167), (564, 167)], [(557, 175), (713, 175), (718, 190), (552, 190)], [(544, 200), (724, 200), (730, 228), (538, 228)], [(492, 322), (775, 322), (782, 346), (486, 346)], [(475, 361), (795, 361), (803, 382), (466, 382)], [(455, 402), (815, 402), (822, 426), (447, 426)], [(436, 444), (830, 444), (838, 478), (428, 478)]]:
        A.poly([G(*p) for p in rows], black)
    for q in [[(263, 232), (317, 232), (253, 308), (200, 308)], [(335, 232), (385, 232), (325, 308), (277, 308)], [(405, 232), (450, 232), (398, 308), (350, 308)], [(472, 232), (510, 232), (475, 308), (423, 308)], [(760, 235), (795, 235), (845, 315), (792, 315)], [(820, 235), (862, 235), (915, 315), (868, 315)], [(885, 237), (925, 237), (988, 315), (940, 317)], [(950, 240), (990, 240), (1065, 317), (1010, 317)]]:
        A.poly([G(*p) for p in q], black)
    bx = [G(565, 250), G(720, 250), G(728, 296), G(549, 296), G(565, 250)]
    A.line(bx, black, 0.9)
    A.line([G(588, 262), G(700, 262), G(704, 284), G(580, 284), G(588, 262)], black, 0.7)
    for x, y in [(105, 268), (1185, 280)]:
        A.text(*G(x, y), "0.0", TECH_R, 9.5, black, shear=0.24, stroke=0.1, strokecol=black)

    def column(x0, x1, y0, y1, red_top, white_from, cells=12, red_bottom=None):
        A.rect(x0, y0, x1, y1, (12, 12, 14))
        A.rect(x0, y0, x1, red_top, (240, 86, 48))
        A.rect(x0, white_from, x1, y1, (232, 230, 214))
        if red_bottom:
            A.rect(x0, red_bottom, x1, y1, (240, 86, 48))
        for i in range(cells + 1):
            y = y0 + (y1 - y0) * i / cells
            A.line([(x0, y), (x1, y)], (120, 122, 124) if y < white_from else (150, 150, 138), 0.45)
        A.line([(x0, y0), (x0, y1)], (176, 178, 180), 0.55)
        A.line([(x1, y0), (x1, y1)], (176, 178, 180), 0.55)

    column(71.5, 84, 287, 353, 299, 322)
    A.line([(61, 320), (90, 320)], (238, 66, 54), 1.7)
    column(96, 111, 288, 353, 288, 288, red_bottom=337)
    A.line([(90, 285.5), (118, 285.5)], (238, 66, 54), 1.7)
    A.icon((66, 268, 116, 286), floor=26, gain=1.3)
    for x, y, t, c in [(57, 289, "130", (238, 66, 54)), (63, 319, "90", (230, 232, 236)), (65, 350, "50", (230, 232, 236)), (118, 290, "100", (230, 232, 236)), (122, 320, "50", (230, 232, 236)), (126, 351, "0", (238, 66, 54)), (640, 296, "170", (238, 66, 54)), (637, 327, "130", (230, 232, 236)), (638, 357, "50", (230, 232, 236)), (699, 296, "10", (238, 66, 54)), (697, 327, "4", (230, 232, 236)), (696, 357, "0", (230, 232, 236))]:
        A.text(x, y, t, TECH, 8.8, c, shear=0.24)
    A.text(55, 302, "°C", ROBO_B, 8.5, (220, 222, 226))
    A.text(123, 303, "%", ROBO_B, 7.5, (220, 222, 226))
    A.text(637, 310, "°C", ROBO_B, 8.5, (220, 222, 226))
    A.text(703, 310, "Bar", ROBO_B, 7.6, (220, 222, 226))
    A.cutout((634, 238, 656, 264), t=90)
    column(652, 666, 294, 359, 310, 339)
    A.line([(640, 335.5), (668, 335.5)], (238, 66, 54), 1.7)
    column(678, 691, 294, 359, 306, 350)
    A.line([(666, 348.5), (694, 348.5)], (238, 66, 54), 1.7)
    A.icon((645, 274, 702, 292), floor=26, gain=1.3)
    A.text(586, 361, "PARK", ROBO_B, 6.2, (240, 54, 58))
    A.final = A.finish(A.S, blur=1.2, strength=0.7)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # the lit cells: white, fading to blue and dark at the inner edge; red in the red zone
    L = Art("aventador_sv_cluster_owner.png", box, S=6, bg=(0, 0, 0))

    def lit_cell(p0, p1, red):
        steps = 48
        for s in range(steps):
            f0, f1 = s / steps, (s + 1.2) / steps

            def at(ph, f):
                return e(ph, OUT + (kin(ph) - OUT) * f)

            if red:
                c = (255, 40, 44) if f0 < 0.6 else tuple(int(v * (1.4 - f0)) for v in (255, 40, 44))
            elif f0 < 0.55:
                c = (246, 250, 254)
            else:
                t = (f0 - 0.55) / 0.45
                c = (int(246 - 190 * t), int(250 - 150 * t), int(254 - 70 * t))
            L.poly([at(p0, f0), at(p1, f0), at(p1, f1), at(p0, f1)], c)

    cells = []
    for i in range(N):
        p0 = PHI0 + (PHI1 - PHI0) * i / N
        p1 = PHI0 + (PHI1 - PHI0) * (i + 1) / N
        lit_cell(p0 + 0.14, p1 - 0.14, p0 >= 49.9)
        cells.append((p0, p1))
    L.final = L.finish(L.S, blur=1, strength=0)

    def v_of(ph):
        return 6 + ph / 20.2

    for i, (p0, p1) in enumerate(cells):
        pts = [e(p0 + 0.14, OUT), e(p1 - 0.14, OUT)]
        steps = 6
        for s in range(steps + 1):
            ph = p1 - 0.14 - (p1 - p0 - 0.28) * s / steps
            pts.append(e(ph, kin(ph)))
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        bx2 = (math.floor(min(xs)) - 1, math.floor(min(ys)) - 1, math.ceil(max(xs)) + 1, math.ceil(max(ys)) + 1)
        sp.add_block(L, bx2, pts, v_of(p0))
    sp.marker = {"color": (240, 80, 92), "w": 1.5, "pts": [(v / 4, e((v / 4 - 6) * 20.2, 0.80)[0] - sp.ox, e((v / 4 - 6) * 20.2, 0.80)[1] - sp.oy, e((v / 4 - 6) * 20.2, 1.03)[0] - sp.ox, e((v / 4 - 6) * 20.2, 1.03)[1] - sp.oy) for v in range(4, 41)]}

    # CORSA: the blue over the top, the corners go orange, the rest warms a little
    sp.bg_tint = {"when": "corsa", "color": (255, 240, 216)}
    B = Art("aventador_sv_cluster_owner.png", box, S=6, bg=(0, 0, 0))
    def top_y(x):
        return interp([(p[0], p[1]) for p in TOP], x)

    xs = [196 + i * 4 for i in range(95)]
    B.poly([(x, top_y(x) - 2 - 9 * (1 - ((x - 383) / 190) ** 2)) for x in xs] + [(x, top_y(x) - 0.6) for x in reversed(xs)], (28, 84, 232))
    for x in range(204, 566, 26):
        B.line([(x, top_y(x) - 0.6), (x + 7, top_y(x + 7) - 2 - 9 * (1 - ((x + 7 - 383) / 190) ** 2))], (8, 22, 70), 0.9)
    B.final = B.finish(B.S, blur=1, strength=0)
    sp.add_show(sp.box(B, (190, 84, 580, 132), black=True), "corsa")
    T = Art("aventador_sv_cluster_owner.png", box, S=6, bg=(0, 0, 0))
    for side in (-1, 1):
        steps = 30
        for k in range(steps):
            f0, f1 = k / steps, (k + 1.3) / steps

            def yy(f):
                return 112 + 125 * f

            def xo(f):
                # the panel's outer side
                return 383 + side * (183 + 28 * min(f / 0.6, 1))

            def xi(f):
                # up against the band's yellow rim
                y = yy(f)
                t = max(min((272 - y) / (160 * 1.045), 1), -1)
                return 383 + side * 212 * 1.045 * math.sqrt(max(1 - t * t, 0))

            if f0 > 0.62:
                continue
            c = (int(226 + 16 * f0), int(136 + 44 * f0), int(58 + 6 * f0))
            T.poly([(xo(f0), yy(f0)), (xi(f0), yy(f0)), (xi(f1), yy(f1)), (xo(f1), yy(f1))], c)
    T.final = T.finish(T.S, blur=1, strength=0)
    sp.add_show(sp.box(T, (172, 110, 600, 200), TOP + [(595, 193), (595, 240), (174, 240), (177, 188)], black=True), "corsa")

    # the small signs
    E = Art("aventador_sv_cluster_owner.png", box, S=6, bg=(0, 0, 0))
    E.text(306, 187, "ESC", ROBO_B, 7.5, (232, 236, 70), stroke=0.9, strokecol=(30, 30, 20))
    E.text(306, 196, "SPORT", ROBO_B, 7.5, (232, 236, 70), stroke=0.9, strokecol=(30, 30, 20))
    E.final = E.finish(E.S, blur=1, strength=0)
    im, left, top = sp.box(E, (284, 178, 330, 204), black=True)
    sp.add_show((im, left, top), "sport")
    Pill = Art("aventador_sv_cluster_owner.png", box, S=6, bg=(0, 0, 0))
    Pill.poly([(293, 208), (313, 208), (319, 214), (316, 223), (293, 223), (288, 217)], (214, 18, 48))
    Pill.text(303, 212, "NO", ROBO_B, 6.2, (250, 240, 240))
    Pill.text(303, 219, "ESC", ROBO_B, 6.2, (250, 240, 240))
    Pill.final = Pill.finish(Pill.S, blur=1, strength=0)
    sp.add_show(sp.box(Pill, (284, 204, 324, 228), black=True), "tcoff")
    Off = Art("aventador_sv_cluster_driving_owner.png", (0, 0, 1280, 720), S=2, bg=(0, 0, 0))
    ref = Image.open(os.path.join(REFS, "aventador_sv_cluster_driving_owner.png")).convert("RGB")
    c = ref.crop((524, 262, 572, 304))
    a = np.asarray(c).astype(float)
    d = np.sqrt(((a - np.median(np.concatenate([a[0], a[-1]]), axis=0)) ** 2).sum(axis=2))
    m = Image.fromarray((np.clip((d - 40) / 40, 0, 1) * 255).astype("uint8"))
    size = (round(26.7 * sp.A), round(22.3 * sp.A))
    off = c.resize(size, Image.LANCZOS).convert("RGBA")
    off.putalpha(m.resize(size, Image.LANCZOS))
    sp.shows.append({"im": off, "left": 292 - sp.ox, "top": 182 - sp.oy, "when": "tcoff"})
    c = ref.crop((976, 226, 1026, 256))
    a = np.asarray(c).astype(float)
    d = np.sqrt(((a - np.median(np.concatenate([a[0], a[-1]]), axis=0)) ** 2).sum(axis=2))
    m = Image.fromarray((np.clip((d - 50) / 40, 0, 1) * 255).astype("uint8"))
    size = (round(27.8 * sp.A), round(15.9 * sp.A))
    lamp = c.resize(size, Image.LANCZOS).convert("RGBA")
    lamp.putalpha(m.resize(size, Image.LANCZOS))
    sp.shows.append({"im": lamp, "left": 548 - sp.ox, "top": 161 - sp.oy, "when": "lights"})
    # a red bar in the g-force stack under power
    Rb = Art("aventador_sv_cluster_owner.png", box, S=6, bg=(0, 0, 0))
    Rb.poly([G(492, 322), G(775, 322), G(782, 346), G(486, 346)], (226, 30, 34))
    Rb.final = Rb.finish(Rb.S, blur=1, strength=0)
    sp.add_show(sp.box(Rb, (366, 292, 402, 298), black=True), "accel")

    # the gear
    K = sp.A
    Q = 4

    def red_digit(ch):
        m = letter_mask(ch, TECH, 142, K, 0.2, stroke=1.0, rounded=1.2)
        out = Image.new("RGBA", m.size, (0, 0, 0, 0))
        edge = m.filter(ImageFilter.MaxFilter(1 + 2 * round(1.1 * K * Q)))
        e2 = Image.new("RGBA", m.size, (250, 246, 240, 0))
        e2.putalpha(edge)
        out.alpha_composite(e2)
        fill = Image.new("RGBA", m.size, (204, 18, 44, 0))
        fill.putalpha(m)
        out.alpha_composite(fill)
        return out.resize((m.width // Q, m.height // Q), Image.LANCZOS)

    def n5(x, y):
        return (347.0 + (x - 300) * 0.1152, 178.5 + (y - 80) * 0.1275)

    def arc(cx, cy, r, a0, a1, steps=8):
        return [n5(cx + r * math.cos(math.radians(a0 + (a1 - a0) * k / steps)), cy + r * math.sin(math.radians(a0 + (a1 - a0) * k / steps))) for k in range(steps + 1)]

    Nn = Art("aventador_sv_cluster_owner.png", box, S=6, bg=(0, 0, 0))
    N_pts = [n5(300, 745), n5(540, 80), n5(682, 80), n5(738, 540), n5(905, 80), n5(975, 80)]
    N_pts += arc(975, 145, 42, -90, 12) + [n5(835, 660)] + arc(745, 660, 88, 22, 90)
    N_pts += [n5(628, 748), n5(585, 360), n5(445, 748)]
    Nn.line(N_pts + N_pts[:1], (252, 244, 214), 1.5)
    Nn.poly(N_pts, (1, 1, 2))
    Nn.line(N_pts + N_pts[:1], (1, 1, 2), 0.5)
    Nn.final = Nn.finish(Nn.S, blur=1, strength=0)
    nbx = (336, 170, 448, 272)
    im = Nn.final.crop((int((nbx[0] - Nn.ox) * Nn.S), int((nbx[1] - Nn.oy) * Nn.S), int((nbx[2] - Nn.ox) * Nn.S), int((nbx[3] - Nn.oy) * Nn.S)))
    a = np.asarray(im).astype(float)
    alpha = np.where(a.max(axis=2) > 0, 255, 0).astype("uint8")
    # (the N's black is kept solid: the polygon's own pixels)
    mk = Image.new("L", im.size, 0)
    ImageDraw.Draw(mk).polygon([((p[0] - nbx[0]) * Nn.S, (p[1] - nbx[1]) * Nn.S) for p in N_pts], fill=255)
    al = np.maximum(alpha, np.asarray(mk))
    rgba = Image.fromarray(np.dstack([a, al]).astype("uint8"), "RGBA").resize((round(112 * K), round(102 * K)), Image.LANCZOS)
    sprites = {ch: {"im": red_digit(ch)} for ch in "1234567"}
    sprites["N"] = {"im": rgba}
    sprites["R"] = {"im": red_digit("R")}
    sp.gear = {"x": 392 - sp.ox, "y": 219 - sp.oy, "sprites": sprites}

    sp.font("strip", TECH, 17, "RN1234567A", shear=0.24, track=1.1)
    sp.font("stripA", TECH, 24, "A", stroke=0.2, shear=0.24)
    sp.readout("strip", 338, 256, "r", 7, "gearLeft", (11, 11, 13))
    sp.readout("strip", 423, 257, "l", 8, "gearRight", (11, 11, 13))
    sp.font("big", TECH, 31, "0123456789", stroke=0.25, shear=0.24, track=0.8)
    sp.readout("big", 250, 293, "r", 3, "speed", (242, 247, 252))
    sp.font("rpm", TECH, 31, "0123456789", stroke=0.25, shear=0.24, track=2.5)
    sp.readout("rpm", 581, 297, "r", 4, "rpm", (242, 247, 252))
    sp.font("alt", TECH, 10, "0123456789", shear=0.24, track=0.3)
    sp.readout("alt", 266, 292, "m", 3, "alt", (112, 200, 240))
    sp.font("unit", REG, 8.6, "kmhpi/", shear=0)
    sp.readout("unit", 265, 301, "m", 4, "altUnit", (112, 200, 240))
    sp.font("redunit", REG, 10, "kmhpi/", shear=0)
    sp.readout("redunit", 196, 274, "m", 4, "unit", (236, 56, 60))
    sp.font("mode", ROBO_B, 9.2, "SPORTCAD", shear=0, track=0.2)
    sp.readout("mode", 293, 274, "m", 5, "mode", (240, 62, 58))
    sp.font("odo", ROBO_B, 9.2, "0123456789", shear=0.24, track=0.25)
    sp.readout("odo", 461, 275.5, "m", 6, "odo", (238, 242, 248))
    sp.font("redu2", REG, 8, "kmhpi/", shear=0)
    sp.readout("redu2", 492, 277, "m", 2, "distUnit", (238, 64, 56))
    sp.font("clock", TECH, 16, "0123456789:", stroke=0.1, shear=0.24, track=0.6)
    sp.readout("clock", 56, 231, "l", 5, "clock", (11, 11, 13), "parked")
    sp.font("date", TECH, 11, "0123456789.", stroke=0.05, shear=0.24, track=0.7)
    sp.readout("date", 48, 248, "l", 10, "date", (11, 11, 13), "parked")
    sp.font("range", TECH_R, 14.5, "0123456789", stroke=0.12, shear=0.24, track=0.8)
    sp.readout("range", 659, 252, "l", 3, "range", (11, 11, 13))
    sp.readout("redu2", 684, 255, "m", 2, "distUnit", (242, 84, 42))
    sp.font("g", TECH_R, 9.5, "0123456789.", stroke=0.1, shear=0.24)
    sp.readout("g", 384.8, 270.5, "m", 3, "gBrake", (11, 11, 13))
    sp.readout("g", 382.5, 315, "m", 3, "gAccel", (11, 11, 13))

    sp.font("temp", TECH, 11, "0123456789.", stroke=0.05, shear=0.24, track=0.7)
    sp.readout("temp", 62, 260, "l", 5, "temp", (11, 11, 13), "parked")
    sp.font("tempU", REG, 10.5, "°F", shear=0)
    sp.readout("tempU", 101, 260, "l", 2, "tempUnit", (242, 84, 42), "parked")
    # (the clock panel's temperature, and the radio line while moving, are text on the yellow)
    sp.labels.append({"x": 58, "y": 240 - sp.oy, "w": 74, "h": 10, "bind": "bandFM", "color": (58, 44, 6), "when": "moving", "left": True})
    sp.labels.append({"x": 58, "y": 250 - sp.oy, "w": 74, "h": 10, "bind": "stationShort", "color": (58, 44, 6), "when": "moving", "left": True})
    return sp


# ------------------------------------------------------------------------------------ LP700
def lp700():
    """one sharp picture behind the model's frame, like the SV and the SVJ (owner, 2026-11-04: "numbers
    blurry"; it was a 1024 atlas). The real car's screen is one picture, so the photo maps onto the
    frame at one scale. No needle in the picture: the marker is the needle."""
    box = (110, 150, 1400, 680)
    sp = Spec("lp700", box[2] - box[0], box[3] - box[1], 2.0, 1.55, box[0], box[1])
    sp.redline, sp.idle = 8.5, 0.9
    tmp = tempfile.mkdtemp()
    lp700_art(tmp, True)
    im = Image.open(os.path.join(tmp, "lp700_art.png")).convert("RGB")
    sp.bg = im.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)
    CX, CY = 749.0, 412.0

    def pol(v, r):
        a = math.radians(-180.0 + v * 30.0)
        return CX + r * math.sin(a) - sp.ox, CY - r * math.cos(a) - sp.oy

    sp.marker = {"color": (238, 30, 40), "w": 3.4, "glow": 0, "pts": [(v / 4, *pol(v / 4, 27), *pol(v / 4, 224)) for v in range(0, 39)]}
    K = sp.A
    Q = 4
    YEL = (232, 214, 32)

    def yellow(ch):
        m = letter_mask(ch, TECH, 42, K, 0.2, stroke=0.4)
        out = Image.new("RGBA", m.size, YEL + (0,))
        out.putalpha(m)
        return out.resize((m.width // Q, m.height // Q), Image.LANCZOS)

    sp.gear = {"x": 838 - sp.ox, "y": 532 - sp.oy, "sprites": {ch: {"im": yellow(ch)} for ch in "RN1234567"}}
    WHITE = (240, 244, 248)
    sp.font("speed", TECH, 40, "0123456789", stroke=0.25, shear=0.22, track=0.6)
    sp.readout("speed", 963, 463, "r", 3, "speed", (14, 14, 16))
    sp.font("unit", ARIAL, 13, "kmhpi/", shear=0)
    sp.readout("unit", 945, 492, "m", 4, "unit", (230, 232, 236))
    sp.font("strip", TECH, 17.5, "RN1234567", shear=0.2, track=1.6)
    sp.readout("strip", 822, 540, "r", 4, "gearLeft4", WHITE)
    sp.readout("strip", 856, 540, "l", 4, "gearRight4", WHITE)
    sp.font("mode", ARIAL, 18, "SPORTCA", shear=0)
    sp.readout("mode", 819, 568, "m", 5, "mode", (230, 196, 40))
    sp.font("odo", TECH, 17.5, "0123456789", shear=0.2, track=1.0)
    sp.readout("odo", 769, 603, "l", 6, "odo", WHITE)
    sp.font("dist", ARIAL, 12.5, "kmi", shear=0)
    sp.readout("dist", 857, 603, "m", 2, "distUnit", WHITE)
    sp.font("clock", TECH, 40, "0123456789:", shear=0.2, track=2.2)
    sp.readout("clock", 225, 541, "m", 5, "clock", WHITE)
    sp.font("date", TECH, 21, "0123456789.", shear=0.2, track=1.2)
    sp.readout("date", 230, 570, "m", 10, "date", WHITE)
    return sp


# ------------------------------------------------------------------------------------ Huracan
def huracan():
    box = (100, 305, 940, 595)
    A = Art("huracan_cluster_driving_owner.png", box, S=5, bg=(9, 8, 11))
    sp = Spec("huracan", box[2] - box[0], box[3] - box[1], 2.0, 2.2, box[0], box[1])
    sp.redline, sp.idle = 8.5, 0.9
    CX, CY, R = 518.0, 671.0, 357.0
    WHITE = (240, 240, 244)
    GREY = (205, 202, 206)
    REDO = (250, 62, 34)
    INK = (22, 26, 44)

    def e(th, r):
        a = math.radians(th)
        r = r + (r - 300) / 55 * 8 * math.cos(a) ** 6  # (the arc is a little more pointed at the top)
        x = CX + r * math.sin(a)
        return (x, CY - r * 0.983 * math.cos(a) - 0.03 * (x - CX))

    # the background: dark, a blue panel on the right, a darker one on the left
    A.poly([e(t, 362) for t in range(38, 69, 2)] + [(936, 519), (933, 408), (902, 400), (762, 399)], (17, 30, 66))
    A.poly([(112, 420), (190, 420), (262, 410), (195, 530), (112, 530)], (10, 10, 20))

    # hexagons over the band
    def hex_at(x, y, r, col):
        A.line([(x + r * 1.5 * math.cos(math.radians(a)), y + r * 0.62 * math.sin(math.radians(a))) for a in range(0, 361, 60)], col, 1.0)

    for row in range(0, 3):
        for col in range(0, 7):
            x = 268 + col * 44 + (row % 2) * 22
            y = 330 + row * 16
            if e(math.degrees(math.atan2(x - CX, CY - y)), 356)[1] > y:
                hex_at(x, y, 14, (30, 29, 34))
            x2 = 640 + col * 44 + (row % 2) * 22
            if e(math.degrees(math.atan2(x2 - CX, CY - y)), 356)[1] > y:
                hex_at(x2, y, 14, (30, 29, 34))
    A.line([(260, 372), (285, 400), (281, 410)], (150, 150, 156), 1.1)
    A.line([(775, 363), (755, 388), (760, 398)], (150, 150, 156), 1.1)

    # the band's cells, unlit: grey at the outer edge, dark at the inner
    TH0, CELL = -56.7, 5.605
    RO, RI = 347.0, 307.0

    def cell_poly(i, f0=0.0, f1=1.0):
        a0, a1 = TH0 + i * CELL + 0.5, TH0 + (i + 1) * CELL - 0.5
        return [e(a0, RO + (RI - RO) * f0), e(a1, RO + (RI - RO) * f0), e(a1, RO + (RI - RO) * f1), e(a0, RO + (RI - RO) * f1)]

    def shade(art, i, top, bot, side=0.0):
        steps = 20
        for s in range(steps):
            f = s / steps
            c = tuple(int(top[j] + (bot[j] - top[j]) * f) for j in range(3))
            art.poly(cell_poly(i, f, f + 1 / steps + 0.01), c)

    for i in range(17):
        shade(A, i, (150, 148, 152), (34, 32, 36))
    # the rim: two lines
    A.line([e(t / 2, 355) for t in range(-124, 125)], (205, 203, 208), 1.5)
    A.line([e(t / 2, 350) for t in range(-124, 125)], (108, 106, 112), 1.0)

    # the stepped line round the numbers: a tab over each
    NUM = {0: (283, 520), 1: (314, 473), 2: (359, 433), 3: (405, 405), 4: (461, 387), 5: (518, 378), 6: (573, 383), 7: (629, 399), 8: (679, 427), 9: (726, 464), 10: (757, 510)}
    STEP = 11.3

    def th_of(v):
        return (v - 5) * STEP

    pts = []
    for v in range(0, 11):
        t = th_of(v)
        pts += [e(t - 3.3, 296), e(t - 2.2, 304), e(t + 2.2, 304), e(t + 3.3, 296)]
    A.line(pts[:30], (226, 226, 230), 1.5)
    A.line(pts[30:], (226, 226, 230), 1.5)
    A.line([e(th_of(8) + 3.6, 297), e(th_of(9) - 3.4, 297)], (250, 90, 40), 2.0)
    A.line([e(th_of(9) + 3.6, 297), e(th_of(10) - 3.4, 297)], (250, 90, 40), 2.0)

    for v, (x, y) in NUM.items():
        col = REDO if v >= 9 else WHITE
        A.text(x, y, str(v), TECH, 21 if v else 25, col, shear=0.2, stroke=0.1, strokecol=col)
    A.text(232, 529, "RPM x 1000", ARIAL, 8.6, (222, 222, 226))

    # the gear band, fading at both ends
    band = Image.new("L", (A.W * A.S, A.H * A.S), 0)
    bd = ImageDraw.Draw(band)
    bd.polygon([A.q(*p) for p in [(318, 439), (717, 436), (690, 458), (560, 470), (318, 473)]], fill=255)
    arr = np.asarray(band).astype(float)
    xs = (np.arange(band.width) / A.S) + A.ox
    fade = np.clip((xs - 318) / 70, 0, 1) * np.clip((722 - xs) / 60, 0, 1)
    arr = arr * fade[None, :] * 0.9
    A.im.paste(Image.new("RGB", band.size, (136, 130, 134)), (0, 0), Image.fromarray(arr.astype("uint8")))
    A.d = ImageDraw.Draw(A.im)

    # lower middle: thin lines, lens shapes, lap data
    lens = (90, 88, 94)
    A.poly([(300, 526), (416, 518), (420, 522), (306, 531)], (58, 56, 62))
    A.poly([(624, 518), (742, 516), (738, 521), (628, 524)], (58, 56, 62))
    for a, b in [((440, 494), (482, 546)), ((452, 478), (500, 516)), ((600, 478), (560, 520)), ((610, 494), (568, 544))]:
        A.line([a, b], lens, 0.9)
    A.text(349, 513, "1) 00.00.01.10", TECH_R, 12, WHITE, shear=0.2)
    A.text(390, 503, "GIRO 2", ROBO_B, 7.8, GREY)
    A.text(352, 528, "GIRO 1", ROBO_B, 7.8, GREY)
    A.text(647, 498, "GIRO 3", ROBO_B, 7.8, GREY)
    A.text(657, 508, "95", TECH_R, 13, WHITE, shear=0.2)
    A.text(678, 509, "km/h", ARIAL, 7.6, WHITE)
    A.text(661, 521, "V MAX", ROBO_B, 7.8, GREY)
    A.text(714, 507, "32", TECH_R, 13, WHITE, shear=0.2)
    A.text(734, 508, "km/h", ARIAL, 7.6, WHITE)
    A.text(718, 520, "V MED", ROBO_B, 7.8, GREY)
    A.text(809, 515, "CORSA", ROBO_B, 12.5, REDO)
    A.text(594, 417, "ESC", ROBO_B, 9.2, REDO)
    A.text(594, 427, "CORSA", ROBO_B, 9.2, REDO)

    # the two bright panels
    def panel(pts, x0, x1):
        m = Image.new("L", (A.W * A.S, A.H * A.S), 0)
        ImageDraw.Draw(m).polygon([A.q(*p) for p in pts], fill=255)
        w, h = m.size
        y, x = np.mgrid[0:h, 0:w].astype(float)
        t = np.clip(((x / A.S + A.ox) - x0) / (x1 - x0), 0, 1)
        base = np.dstack([176 + 40 * t, 166 + 40 * t, 172 + 40 * t])
        tex = 2 * np.sin((x + y * 0.4) / (A.S * 0.9))
        im = Image.fromarray(np.clip(base + tex[..., None], 0, 255).astype("uint8"))
        A.im.paste(im, (0, 0), m)
        A.d = ImageDraw.Draw(A.im)

    panel([(180, 540), (408, 532), (478, 585), (305, 592)], 180, 470)
    panel([(580, 581), (633, 528), (866, 525), (742, 581)], 860, 590)
    A.line([(178, 539), (408, 531), (478, 584)], (240, 238, 242), 1.2)
    A.line([(580, 581), (633, 527), (866, 524)], (240, 238, 242), 1.2)
    A.line([(305, 592), (478, 586)], (120, 118, 122), 1.0)
    A.line([(580, 582), (742, 582)], (120, 118, 122), 1.0)
    A.text(377, 569, "PM", ARIAL, 6.5, INK)
    A.text(408, 575, "23.5", TECH_R, 14.5, INK, shear=0.2)
    A.text(434, 575, "°C", ARIAL, 9, INK)
    A.cutout((331, 542, 346, 562), t=70)

    # the g-force mark
    GR = (214, 212, 216)
    for k, (xa, xb, y) in enumerate([(512, 534, 530), (510, 536, 534)]):
        A.poly([(xa, y), (xb, y), (xb + 1.5, y + 3), (xa - 1.5, y + 3)], GR)
    for k, (xa, xb, y) in enumerate([(505, 541, 549), (502, 544, 553), (499, 548, 557), (496, 551, 561)]):
        A.poly([(xa, y), (xb, y), (xb + 2, y + 3), (xa - 2, y + 3)], GR)
    for i in range(7):
        A.poly([(479 + i * 5, 547), (483 + i * 5, 547), (489 + i * 5, 540), (485 + i * 5, 540)], GR)
        A.poly([(569 - i * 5, 546), (565 - i * 5, 546), (559 - i * 5, 539), (563 - i * 5, 539)], GR)
    A.line([(513, 539), (535, 539), (536, 546), (512, 546), (513, 539)], GR, 1.0)
    for x, y in [(465, 542), (583, 539), (523, 524), (523, 573)]:
        A.text(x, y, "0.0", TECH_R, 9.5, WHITE, shear=0.2, stroke=0.1, strokecol=WHITE)

    # left gauges
    def hatch(x0, x1, y0, y1, col, step=2.6, slant=3.0):
        x = x0
        while x < x1:
            A.line([(x, y1), (x + slant, y0)], col, 1.3)
            x += step

    A.text(207, 408, "Temp.", ARIAL, 8.4, GREY)
    A.text(207, 417, "Olio", ARIAL, 8.4, GREY)
    A.icon((230, 402, 262, 422), floor=70, gain=1.4)
    for x, y, t, c in [(161, 427, "50", GREY), (194, 427, "130", GREY), (245, 426, "170", REDO), (128, 467, "0", GREY), (174, 467, "5", GREY), (219, 466, "10", REDO)]:
        A.text(x, y, t, TECH_R, 9.5, c, shear=0.2)
    A.line([(153, 434), (248, 432)], (220, 218, 222), 1.1)
    for x in (153, 186, 216, 248):
        A.line([(x, 434), (x, 430)], (220, 218, 222), 1.0)
    A.line([(150, 444), (236, 454)], (120, 118, 122), 1.0)
    hatch(148, 168, 438, 445, GREY)
    hatch(215, 240, 438, 453, (232, 30, 34), 2.4, 3)
    A.line([(167, 455), (187, 428)], (236, 40, 34), 2.0)
    A.line([(123, 473), (218, 472)], (220, 218, 222), 1.1)
    for x in (123, 150, 174, 197, 218):
        A.line([(x, 473), (x, 469)], (220, 218, 222), 1.0)
    A.line([(118, 484), (206, 493)], (120, 118, 122), 1.0)
    hatch(117, 168, 478, 487, GREY)
    hatch(183, 212, 478, 492, (232, 30, 34), 2.4, 3)
    A.line([(160, 495), (180, 467)], (236, 40, 34), 2.0)
    A.text(131, 509, "Press.", ARIAL, 8.4, GREY)
    A.text(131, 519, "Olio", ARIAL, 8.4, GREY)
    A.icon((145, 505, 176, 524), floor=70, gain=1.4)

    # right gauges
    A.icon((786, 390, 802, 412), floor=70, gain=1.4)
    A.text(820, 401, "Benzina", ARIAL, 8.4, GREY)
    for x, y, t, c in [(791, 415, "0", REDO), (835, 413, "50", GREY), (882, 413, "100", GREY), (827, 453, "130", REDO), (867, 453, "90", GREY), (912, 451, "50", GREY)]:
        A.text(x, y, t, TECH_R, 9.5, c, shear=0.2)
    A.line([(788, 423), (885, 421)], (220, 218, 222), 1.1)
    for x in (788, 835, 860, 885):
        A.line([(x, 423), (x, 419)], (220, 218, 222), 1.0)
    A.line([(803, 442), (892, 429)], (120, 118, 122), 1.0)
    hatch(797, 825, 427, 441, (232, 30, 34), 2.4, -3)
    hatch(826, 886, 425, 439, GREY, 2.8, -3)
    A.line([(865, 415), (887, 441)], (236, 40, 34), 2.0)
    A.line([(820, 460), (917, 458)], (220, 218, 222), 1.1)
    for x in (820, 867, 917):
        A.line([(x, 460), (x, 456)], (220, 218, 222), 1.0)
    A.line([(840, 480), (922, 468)], (120, 118, 122), 1.0)
    hatch(827, 857, 464, 480, (232, 30, 34), 2.4, -3)
    hatch(876, 922, 463, 475, GREY, 2.8, -3)
    A.line([(863, 455), (885, 480)], (236, 40, 34), 2.0)
    A.icon((870, 485, 892, 508), floor=70, gain=1.4)
    A.text(908, 492, "Temp.", ARIAL, 8.4, GREY)
    A.text(910, 502, "Acqua", ARIAL, 8.4, GREY)
    A.final = A.finish(A.S, blur=1.5, strength=0.6)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # lit cells; the last three are lit all the time
    L = Art("huracan_cluster_driving_owner.png", box, S=5, bg=(0, 0, 0))
    for i in range(17):
        steps = 20
        for s in range(steps):
            f = s / steps
            c = tuple(int(a + (b - a) * f) for a, b in zip((238, 232, 236), (150, 142, 148)))
            L.poly(cell_poly(i, f, f + 1 / steps + 0.01), c)
    L.final = L.finish(L.S, blur=1, strength=0)
    for i in range(17):
        p = cell_poly(i)
        xs = [q[0] for q in p]
        ys = [q[1] for q in p]
        sp.add_block(L, (math.floor(min(xs)) - 1, math.floor(min(ys)) - 1, math.ceil(max(xs)) + 1, math.ceil(max(ys)) + 1), p, i * 0.5)
    Rd = Art("huracan_cluster_driving_owner.png", box, S=5, bg=(0, 0, 0))
    for i in (17, 18, 19):
        steps = 20
        for s in range(steps):
            f = s / steps
            c = (255, int(70 - 40 * f), int(40 - 10 * f)) if f < 0.7 else (int(255 - 220 * (f - 0.7) / 0.3), 24, 22)
            Rd.poly(cell_poly(i, f, f + 1 / steps + 0.01), c)
    Rd.final = Rd.finish(Rd.S, blur=1, strength=0)
    sp.add_show(sp.box(Rd, (680, 380, 830, 510), black=True), None)
    sp.marker = {"color": (244, 44, 30), "w": 2.0, "pts": [(v / 2, e(th_of(v / 2), 356)[0] - sp.ox, e(th_of(v / 2), 356)[1] - sp.oy, e(th_of(v / 2), 304)[0] - sp.ox, e(th_of(v / 2), 304)[1] - sp.oy) for v in range(0, 21)]}
    Li = Art("huracan_cluster_driving_owner.png", box, S=5, bg=(0, 0, 0))
    Li.icon((696, 322, 730, 338), floor=40, gain=1.3)
    Li.final = Li.finish(Li.S, blur=1, strength=0)
    sp.add_show(sp.box(Li, (696, 322, 730, 338), black=True), "lights")

    # the gear
    K = sp.A
    sprites = {}
    for ch in "RNP1234567":
        m = letter_mask(ch, TECH, 166, K, 0.2, rounded=2.2)
        sprites[ch] = {"im": hollow(m, 166, K, 0.2, 1.7, (254, 62, 30), 1.6)}
    sp.gear = {"x": 525 - sp.ox, "y": 458 - sp.oy, "sprites": sprites}
    sp.font("strip", TECH_R, 14, "RN1234567", stroke=0.15, shear=0.2, track=3.2)
    sp.readout("strip", 488, 454, "r", 4, "gearLeft4", (22, 22, 26))
    sp.readout("strip", 566, 454, "l", 4, "gearRight4", (22, 22, 26))
    sp.font("speed", TECH_R, 46, "0123456789", stroke=0.25, shear=0.26, track=3.5)
    sp.readout("speed", 760, 546, "r", 3, "speed", INK)
    sp.font("odo", TECH_R, 15, "0123456789", stroke=0.12, shear=0.2, track=0.8)
    sp.readout("odo", 300, 552, "r", 6, "odo", INK)
    sp.font("range", TECH_R, 25, "0123456789", stroke=0.2, shear=0.2, track=1.2)
    sp.readout("range", 402, 548, "r", 3, "range", INK)
    sp.font("clock", TECH_R, 25, "0123456789:", stroke=0.2, shear=0.2, track=1.6)
    sp.readout("clock", 333, 574, "m", 5, "clock", INK)
    sp.font("unit", ARIAL, 12.5, "kmhpi/", shear=0)
    sp.readout("unit", 763, 536, "l", 4, "unit", INK)
    sp.readout("unit", 313, 552, "m", 2, "distUnit", INK)
    sp.readout("unit", 412, 552, "m", 2, "distUnit", INK)
    return sp


# -------------------------------------------------------------------------------------- main
# ------------------------------------------------------------------------------- Urus Performante
def urus():
    """From the owner's photo (imports/refs/urus_performante_cluster_owner.png). The photo leans 1.15
    degrees, so the coordinates are those of the levelled copy (..._owner_level.png), centre x 370."""
    box = (92, 236, 652, 392)
    REF = "urus_performante_cluster_owner_level.png"
    A = Art(REF, box, S=6, bg=(7, 7, 9))
    sp = Spec("urus", box[2] - box[0], box[3] - box[1], 3, 3, box[0], box[1])
    sp.redline, sp.idle = 6.8, 0.8
    WHITE = (238, 240, 244)
    RED = (240, 34, 50)
    REDL = (232, 62, 78)
    GREY = (150, 153, 160)
    DIM = (92, 94, 100)
    DARK = (58, 60, 66)
    CX = 370
    RT, CT = 460.0, 708.0  # the top line of the rev band: a circle
    RL, CL = 426.6, 695.0  # its bottom line

    def ty(x, k=0.0):
        return CT - math.sqrt((RT - k) ** 2 - (x - CX) ** 2)

    def ly(x):
        return CL - math.sqrt(RL**2 - (x - CX) ** 2)

    TOP = {0: 209.0, 1: 233.75, 2: 259.5, 3: 291.75, 4: 328.0, 5: 370.5, 6: 418.0, 7: 472.0, 8: 530.5}

    def tx(v):
        return interp(sorted(TOP.items()), v)

    def lx(v):
        return 217.5 + (tx(v) - 209.0) * 0.9564

    def arc(x0, x1, k, col, w):
        pts = [(x, ty(x, k)) for x in np.arange(x0, x1 + 0.01, 3.0)]
        A.line(pts, col, w)

    arc(207, 533, 0, (176, 179, 186), 1.1)
    arc(207, 328, 3, (120, 122, 128), 1.0)
    arc(328, 533, 3, RED, 1.5)
    A.line([(x, ly(x)) for x in np.arange(217, 526, 3.0)], (108, 110, 116), 1.1)
    # the dotted row
    x = 214.0
    while x < 526:
        y = ty(x, 11)
        A.circle(x, y, 0.62, (235, 44, 60) if x >= 328 else (84, 86, 92))
        x += 7.0 + (x - 214) * 0.003
    # ticks at the top and the half marks
    for v in range(0, 9):
        x = tx(v)
        col = RED if v >= 4 else (214, 216, 222)
        A.line([(x, ty(x, 0)), (x + (CX - x) * 0.004, ty(x, 8))], col, 1.3)
        if v < 8:
            xh = tx(v + 0.5)
            A.line([(xh, ty(xh, 3)), (xh, ty(xh, 6))], (RED if v >= 4 else DIM), 0.8)
    A.line([(tx(8), ty(tx(8), 0)), (lx(8) + 2, ly(lx(8)) - 1)], RED, 1.2)
    NUM = {0: (213.75, 291.3), 1: (235.5, 282.8), 2: (261.75, 275.3), 3: (293, 269.0), 4: (328.75, 263.7), 5: (370.5, 262.5), 6: (417.5, 264.0), 7: (469.5, 273.0), 8: (526.75, 291.9)}
    for v, (x, y) in NUM.items():
        col = RED if v >= 4 else WHITE
        A.text(x, y, str(v), TECH, 15.5, col, stroke=0.12, strokecol=col, glow=(90, 12, 20) if v >= 4 else None)
    for s, x, y in (("0", 218.75, 301.5), ("25", 266.25, 286.8), ("50", 330.75, 275.6), ("75", 416.0, 276.6), ("100", 522.0, 301.6)):
        A.text(x, y, s, REG, 6.4, (190, 192, 198))
        A.line([(x, ly(x) + 0.2), (x, ly(x) + 2.2)], GREY, 0.7)
    A.text(187.5, 287.6, "% E-POTENZA", ROBO_B, 4.9, DARK, rot=-19)
    A.text(195, 296.6, "RPM x 1000", ROBO_B, 4.9, (84, 86, 92), rot=-19)
    A.text(199.5, 305.8, "% RICARICA", ROBO_B, 4.9, DARK, rot=-19)

    # the top line
    def bt(x, y, k=1.0):
        A.line([(x - 2.4 * k, y - 2 * k), (x + 2.4 * k, y + 2 * k), (x, y + 4.4 * k), (x, y - 4.4 * k), (x + 2.4 * k, y - 2 * k), (x - 2.4 * k, y + 2 * k)], (220, 222, 228), 0.75)

    bt(207, 245.5)
    A.text(212.5, 245.5, "Not connected", ROBO_B, 7.3, WHITE, anchor="lm")
    A.line([(265.5, 242), (265.5, 249)], DIM, 0.8)
    A.round_rect(270.6, 241.2, 275.8, 250.2, 0.9, None, outline=(190, 192, 198), w=0.7)
    A.line([(270.2, 250.8), (276.2, 240.8)], (190, 192, 198), 0.7)
    A.text(295, 248.4, "+ 31.5", ROBO_B, 7.3, WHITE, anchor="lm")  # (a little lower than the photo: the model's hood reaches further down)
    A.text(315.5, 248.6, "°C", ROBO_B, 5.2, (210, 212, 218), anchor="lm")
    A.line([(495.8, 241.5), (495.8, 249.5)], DIM, 0.8)
    # two fuel pumps: range
    for x0 in (499.0, 510.5):
        A.round_rect(x0, 241.0, x0 + 6.4, 250.0, 0.7, None, outline=(216, 218, 224), w=0.7)
        A.rect(x0 + 1.2, 242.2, x0 + 5.2, 244.8, (216, 218, 224))
    A.text(507.9, 245.6, "+", ROBO_B, 6, (216, 218, 224))

    # coolant, left
    A.text(206, 342.8, "50 °C", ROBO_B, 6.4, (226, 228, 232))
    A.line([(242, 338.5), (242, 345)], (150, 153, 160), 1.0)
    A.circle(242, 345.6, 1.3, (150, 153, 160))
    A.line([(245, 341), (247, 340), (249, 341), (251, 340)], (120, 122, 128), 0.7)
    A.line([(233, 343.5), (235, 342.5), (237, 343.5), (239, 342.5)], (120, 122, 128), 0.7)
    A.text(280.8, 342.8, "130", ROBO_B, 6.8, RED)
    A.round_rect(202.5, 348.6, 244, 351.0, 1.0, (232, 234, 238))
    A.line([(242.6, 348.6), (244.2, 351)], RED, 1.2)
    A.line([(244, 349.7), (276, 349.8)], (112, 114, 120), 0.9)
    A.line([(277, 349.8), (286, 349.8), (286.6, 346.6)], RED, 1.1)
    A.line([(192.5, 355.5), (285, 356.3), (306, 345.7)], REDL, 0.9, glow=(70, 14, 22), gw=2.6)
    # oil, right: temperature, pressure
    A.text(461, 342.4, "50 °C", ROBO_B, 6.4, (226, 228, 232))
    A.line([(475, 340), (480, 340), (482, 337.6)], (190, 192, 198), 0.8)
    A.line([(473.2, 341.4), (474.6, 337.6), (476.8, 337.6)], (190, 192, 198), 0.8)
    A.text(492.2, 342.4, "170", ROBO_B, 6.8, RED)
    A.line([(459.4, 349.6), (488, 349.6)], (112, 114, 120), 0.9)
    A.line([(458, 350), (461, 347.2)], RED, 1.2)
    A.line([(488, 349.6), (496.4, 349.6), (497.4, 346.6)], RED, 1.1)
    A.text(509.4, 342.4, "0 bar", ROBO_B, 6.4, (226, 228, 232))
    A.line([(517, 340), (522, 340), (524, 337.6)], (190, 192, 198), 0.8)
    A.line([(515.4, 341.4), (516.8, 337.6), (519, 337.6)], (190, 192, 198), 0.8)
    A.text(537.8, 342.4, "10", ROBO_B, 6.8, RED)
    A.line([(502, 349.6), (529, 349.6)], (112, 114, 120), 0.9)
    A.line([(500.5, 350), (503.5, 347.2)], RED, 1.2)
    A.line([(529, 349.6), (540, 349.6), (541, 346.6)], RED, 1.1)
    A.line([(434.5, 345.9), (455, 356.2), (548, 356.2)], REDL, 0.9, glow=(70, 14, 22), gw=2.6)

    # the mode frames
    def frame(cx, cy, hw):
        c = (84, 86, 92)
        for sg in (-1, 1):
            A.line([(cx + sg * (hw + 2), cy), (cx + sg * (hw + 8), cy)], (214, 216, 222), 1.0)
            A.line([(cx + sg * (hw - 2), cy - 3.4), (cx + sg * (hw + 2), cy), (cx + sg * (hw - 2), cy + 3.4)], (214, 216, 222), 1.0)
            A.line([(cx + sg * (hw - 2), cy - 3.4), (cx + sg * (hw - 8), cy - 8.8), (cx + sg * 8, cy - 8.8)], c, 0.6)
            A.line([(cx + sg * (hw - 2), cy + 3.4), (cx + sg * (hw - 8), cy + 8.8), (cx + sg * 8, cy + 8.8)], c, 0.6)

    frame(239.5, 370.2, 21)
    frame(503.75, 370.2, 26)
    A.text(503.75, 370.2, "PERFORMANCE", ROBO_B, 5.3, WHITE, track=0.3)
    A.text(503.75, 363.4, "TACHIMETRO", ROBO_B, 3.8, DIM, track=0.2)
    A.text(503.75, 376.9, "ROAD", ROBO_B, 3.8, DIM, track=0.2)

    # the side pods
    def pod(side):
        x = (lambda v: v) if side < 0 else (lambda v: 744 - v)
        A.text(x(121.5), 287.5, "1/1", ROBO_B, 6.8, (226, 228, 232))
        A.text(x(121.5), 318.5, "1/2", ROBO_B, 6.8, (226, 228, 232))
        A.text(x(137), 349.4, "R", ROBO_B, 7.6, RED)
        n = 9 if side < 0 else 25
        pts = [(133.5 + (k / 8) ** 1.8 * 10.5, 324.5 + k * 2.9) for k in range(0, 9)] if side < 0 else [(131.2 + ((k + 8) / 32 * 2) ** 2.2 * 2.75, 285 + k * 2.42) for k in range(0, 25)]
        for i in range(n - 1):
            if i % 2 == 0:
                A.line([(x(pts[i][0]), pts[i][1]), (x(pts[i + 1][0]), pts[i + 1][1])], WHITE, 1.5)
        A.line([(x(124.5), 336.4), (x(127.8), 335.0)], (226, 228, 232), 1.0)
        A.line([(x(127.5), 344.0), (x(130.8), 342.2)], RED, 1.1)

    pod(-1)
    pod(1)
    # left pod: the battery; right pod: fuel
    A.round_rect(106.5, 299.0, 116.5, 307.5, 1.4, None, outline=(216, 218, 224), w=0.9)
    A.rect(108, 300.5, 115, 306, (120, 122, 128))
    A.poly([(105.5, 301.0), (102.5, 303.2), (105.5, 305.4)], (216, 218, 224))
    A.line([(118.5, 303.2), (121.5, 303.2)], (216, 218, 224), 1.0)
    A.round_rect(627.5, 299.0, 634.5, 308.5, 0.8, None, outline=(216, 218, 224), w=0.8)
    A.rect(628.8, 300.4, 633.2, 303.2, (216, 218, 224))
    A.poly([(637.2, 301.0), (640.2, 303.6), (637.2, 306.2)], (216, 218, 224))
    A.line([(621.5, 303.8), (624.5, 303.8)], (216, 218, 224), 1.0)

    # the ring dial, right of the gear
    RX, RY = 445.75, 309.0
    for i in range(16):
        a0, a1 = 22.5 * i + 0.8, 22.5 * (i + 1) - 0.8
        col = (66, 68, 74) if i == 0 else (236, 238, 242)
        pts = []
        for t in np.linspace(a0, a1, 8):
            pts.append((RX + 21.2 * math.sin(math.radians(t)), RY - 21.2 * math.cos(math.radians(t))))
        for t in np.linspace(a1, a0, 8):
            pts.append((RX + 16.2 * math.sin(math.radians(t)), RY - 16.2 * math.cos(math.radians(t))))
        A.poly(pts, col)
    A.circle(RX, RY, 14.6, (17, 17, 20))
    A.text(RX, RY, "19", TECH, 16.5, WHITE, stroke=0.14, strokecol=WHITE)
    A.final = A.finish(A.S, blur=2.2, strength=0.7)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # the rev band that fills, and the red marker
    F = Art(REF, box, S=6, bg=(0, 0, 0))
    a = 209.0
    while a < 530.5:
        b = a + 1.0
        F.poly([(a, ty(a, 3.8)), (b, ty(b, 3.8)), (b, ty(b, 7.6)), (a, ty(a, 7.6))], RED if a >= 328 else (232, 234, 238))
        a = b
    F.final = F.finish(F.S, blur=1, strength=0)
    fbox = (205, 244, 535, 286)
    im, left, top_ = sp.box(F, fbox, black=True)
    xs = [(v / 4, (tx(v / 4) - fbox[0]) / (fbox[2] - fbox[0])) for v in range(0, 33)]
    sp.fills.append({"im": im, "left": left, "top": top_, "pts": xs, "lead": 0})
    sp.marker = {"color": (240, 34, 50), "w": 1.7, "glow": 2.4, "pts": [(v / 4, tx(v / 4) - sp.ox, ty(tx(v / 4), 0.5) - sp.oy, lx(v / 4) - 1.5 - sp.ox, ly(lx(v / 4)) - 5 - sp.oy) for v in range(0, 33)]}

    # the mode word: the middle row is the mode the car is in
    for when, rows in (("corsa", ("SPORT", "CORSA", "STRADA")), ("sport", ("STRADA", "SPORT", "CORSA"))):
        L = Art(REF, box, S=6, bg=(0, 0, 0))
        L.text(239.5, 363.4, rows[0], ROBO_B, 3.8, DIM, track=0.2)
        L.text(239.5, 370.2, rows[1], ROBO_B, 6.0, RED, track=0.3, glow=(90, 12, 20))
        L.text(239.5, 376.9, rows[2], ROBO_B, 3.8, DIM, track=0.2)
        L.final = L.finish(L.S, blur=1, strength=0.5)
        sp.add_show(sp.box(L, (216, 359, 263, 381), black=True), when)

    # parked: seat belt, the car's warnings
    W2 = Art(REF, box, S=6, bg=(0, 0, 0))
    W2.circle(288.6, 361.0, 1.9, RED)
    W2.poly([(284.8, 372.6), (285.8, 364.2), (291.6, 364.2), (292.6, 372.6)], RED)
    W2.line([(285.4, 365), (292.2, 371.6)], (60, 8, 14), 0.8)
    W2.line([(286, 378.6), (291, 375.6), (298, 375.6), (301.6, 378.2), (301.6, 380), (286, 380), (286, 378.6)], (214, 216, 222), 0.9)
    W2.line([(270, 380.2), (281, 376.4), (278.4, 380)], (150, 153, 160), 0.7)
    W2.text(407.6, 342.6, "ESC", ROBO_B, 4.1, RED, track=0.2)
    W2.text(407.6, 347.6, "SPORT", ROBO_B, 4.1, RED, track=0.2)
    W2.circle(423.8, 341.2, 2.4, None, outline=(232, 200, 40), w=0.9)
    W2.round_rect(420, 342.8, 427.6, 351, 1.8, None, outline=(232, 200, 40), w=1.0)
    W2.line([(421, 347), (426.6, 347)], (232, 200, 40), 0.9)
    W2.final = W2.finish(W2.S, blur=1, strength=0)
    sp.add_show(sp.box(W2, (266, 356, 306, 384), black=True), "parked")
    sp.add_show(sp.box(W2, (396, 335, 432, 354), black=True), "parked")

    # the gear: a thin hollow letter
    K = sp.A
    sprites = {}
    for ch in "RNP1234567":
        m = letter_mask(ch, TECH, 79, K, 0.28, rounded=1.0)
        sprites[ch] = {"im": hollow(m, 79, K, 0.26, 0.9, (240, 34, 50), 0.5)}
    sprites["N"], sprites["P"] = sprites["P"], sprites["N"]  # (a car in neutral shows P here)
    sp.gear = {"x": 369 - sp.ox, "y": 312 - sp.oy, "sprites": sprites}
    sp.font("speed", TECH, 21, "0123456789", stroke=0.25, shear=0, track=0.3)
    sp.readout("speed", 372, 359, "m", 3, "speed")
    sp.font("unit", ROBO_B, 5.6, "kmhpi/", shear=0)
    sp.readout("unit", 372, 371, "m", 4, "unit")
    sp.readout("unit", 485.4, 246.6, "l", 2, "distUnit")
    sp.readout("unit", 534, 246.6, "l", 2, "distUnit")
    sp.font("clock", ROBO_B, 7.3, "0123456789:", shear=0)
    sp.readout("clock", 430.5, 248.3, "m", 5, "clock")
    sp.font("odo", ROBO_B, 7.3, "0123456789", shear=0)
    sp.readout("odo", 484.2, 245.5, "r", 6, "odoTrim")
    sp.readout("odo", 532.8, 245.5, "r", 3, "range")
    return sp


# ------------------------------------------------------------------------- Rosso Rampante dials
def gradient(A, box, top, bottom, radius=0.0):
    """a rounded box filled from one colour at the top to another at the bottom"""
    x0, y0, x1, y1 = box
    S = A.S
    w, h = int((x1 - x0) * S), int((y1 - y0) * S)
    t = np.linspace(0, 1, h)[:, None, None]
    g = np.array(top, float)[None, None, :] * (1 - t) + np.array(bottom, float)[None, None, :] * t
    im = Image.fromarray(np.repeat(g, w, axis=1).astype("uint8"))
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, w - 1, h - 1], radius=radius * S, fill=255)
    A.im.paste(im, (int((x0 - A.ox) * S), int((y0 - A.oy) * S)), m)


def radial(A, cx, cy, r, inner, outer):
    S = A.S
    d = int(2 * r * S)
    yy, xx = np.mgrid[0:d, 0:d]
    t = np.clip(np.hypot(xx - d / 2, yy - d / 2) / (d / 2), 0, 1)[..., None]
    g = np.array(inner, float)[None, None, :] * (1 - t) + np.array(outer, float)[None, None, :] * t
    m = Image.new("L", (d, d), 0)
    ImageDraw.Draw(m).ellipse([0, 0, d - 1, d - 1], fill=255)
    A.im.paste(Image.fromarray(g.astype("uint8")), (int((cx - r - A.ox) * S), int((cy - r - A.oy) * S)), m)


def polar(c, r, deg):
    a = math.radians(deg)
    return (c[0] + r * math.sin(a), c[1] - r * math.cos(a))


def ring_band(A, c, r0, r1, a0, a1, col):
    """a band round c between two angles (degrees clockwise from up)"""
    n = max(2, int(abs(a1 - a0) / 1.5))
    angs = [a0 + (a1 - a0) * i / n for i in range(n + 1)]
    A.poly([polar(c, r1, t) for t in angs] + [polar(c, r0, t) for t in reversed(angs)], col)


def needle_sprite(sp, length, tail, parts, hub=0.0, hub_col=(0, 0, 0), hub_line=None):
    """a needle drawn pointing up, the pivot in the middle of the picture: it turns about its own
    middle in the game. parts: (r0, r1, half width at r0, half width at r1, colour), r up from the pivot"""
    K = 4
    L = max(length, tail) + 2
    k = sp.A * K
    W = int(2 * (max(p[2] for p in parts) + hub + 3) * k)
    H = int(2 * L * k)
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = W / 2, H / 2
    for r0, r1, w0, w1, col in parts:
        d.polygon([(cx - w0 * k, cy - r0 * k), (cx + w0 * k, cy - r0 * k), (cx + w1 * k, cy - r1 * k), (cx - w1 * k, cy - r1 * k)], fill=tuple(col) + (255,))
    if hub:
        d.ellipse([cx - hub * k, cy - hub * k, cx + hub * k, cy + hub * k], fill=tuple(hub_col) + (255,), outline=tuple(hub_line) + (255,) if hub_line else None, width=int(1.5 * k))
    return im.resize((max(2, W // K), max(2, H // K)), Image.LANCZOS)


def add_needle(sp, im, x, y, bind, pts):
    sp.needles.append({"im": im, "x": x - sp.ox, "y": y - sp.oy, "bind": bind, "pts": pts})


def solid_gear(sp, path, size, col, x, y, stroke=0.5):
    sprites = {}
    f = {"path": path, "size": size, "chars": "", "stroke": stroke, "shear": 0, "track": 0}
    for ch in "RNP1234567":
        im, ox, oy, adv = glyph(ch, f, sp.A)
        c = Image.new("RGBA", im.size, tuple(col) + (0,))
        c.putalpha(im.getchannel("A"))
        sprites[ch] = {"im": c}
    sprites["N"], sprites["P"] = sprites["P"], sprites["N"]  # (a car in neutral shows P here)
    sp.gear = {"x": x - sp.ox, "y": y - sp.oy, "sprites": sprites}


def f458():
    """the 458's three screens, from the owner's photo (imports/refs/f458_cluster_owner.png). Coordinates are
    photo pixels. No maker's horse on the dial. The 458 Spider and Speciale share it."""
    box = (56, 300, 1876, 990)
    REF = "f458_cluster_owner.png"
    A = Art(REF, box, S=2, bg=(10, 10, 12))
    sp = Spec("f458", box[2] - box[0], box[3] - box[1], 0.9, 1, box[0], box[1])
    sp.redline, sp.idle = 9.0, 0.7
    C = (966, 617)
    NUMG = (112, 106, 88)
    RED = (206, 34, 30)
    LINE = (196, 236, 234)
    WHT = (236, 240, 238)

    def rev(v):
        return 180 + 27 * v

    # the side panels above the screens
    for sg in (1, -1):
        mx = (lambda x: x) if sg > 0 else (lambda x: 1932 - x)
        A.poly([(mx(196), 545), (mx(240), 478), (mx(330), 442), (mx(565), 408), (mx(565), 545)], (15, 15, 17))
        A.line([(mx(196), 545), (mx(240), 478), (mx(330), 442), (mx(565), 408)], (46, 46, 50), 2)

    # the rev counter
    A.circle(C[0], C[1], 303, (226, 228, 226))
    A.circle(C[0], C[1], 299, (24, 24, 24))
    radial(A, C[0], C[1], 263, (232, 188, 42), (214, 168, 28))
    ring_band(A, C, 254, 268, rev(8.98), rev(9.82), RED)
    for i in range(0, 56):
        v = i / 5
        t = rev(v)
        if i % 5 == 0:
            A.line([polar(C, 266, t), polar(C, 307, t)], (238, 238, 236), 3.6)
        else:
            A.line([polar(C, 268, t), polar(C, 286, t)], (214, 214, 212), 2.0)
    NUM = {0: (967, 842), 1: (873, 820), 2: (800, 762), 3: (750, 662), 4: (750, 562), 5: (795, 473), 6: (880, 408), 7: (985, 395), 8: (1087, 430), 9: (1160, 505), 10: (1190, 618)}
    for v, (x, y) in NUM.items():
        col = RED if v >= 9 else NUMG
        A.text(x, y, str(v), WIDE, 50, col, stroke=1.4, strokecol=col)
    A.text(1056, 388, "7500", REG, 15, NUMG, rot=26)
    A.text(1147, 452, "8500", REG, 15, NUMG, rot=52)
    A.text(1203, 551, "9500", REG, 15, RED, rot=80)
    # the inner ribbon
    for r in (165, 171, 177):
        ring_band(A, C, r - 0.9, r + 0.9, 183, 448, (176, 136, 24))
    for v in range(1, 11):
        t = rev(v)
        A.line([polar(C, 163, t), polar(C, 179, t)], (176, 136, 24), 1.6)
    A.text(1068, 606, "RPM", WIDE, 20, NUMG, stroke=0.3, strokecol=NUMG)
    A.text(1068, 628, "x 1000", REG, 16, NUMG)
    # the gear window
    gw = [(1006, 662), (1020, 646), (1180, 646), (1195, 660), (1170, 730), (1145, 770), (1095, 811), (1050, 785), (1015, 730)]
    A.poly(gw, (130, 112, 94))
    A.line(gw + [gw[0]], (222, 220, 212), 3)

    # the left screen
    gradient(A, (66, 586, 574, 974), (38, 38, 42), (38, 38, 42), 20)
    gradient(A, (72, 592, 568, 968), (13, 22, 42), (20, 30, 50), 16)
    gradient(A, (76, 908, 566, 964), (34, 50, 62), (28, 42, 54), 10)
    A.rect(78, 598, 562, 642, (238, 240, 230))
    A.text(504, 623, "38°", REG, 33, (40, 74, 84))
    A.round_rect(84, 650, 562, 692, 10, (44, 62, 76), outline=(176, 196, 204), w=1.6)
    A.text(100, 671, "VDA available in RACE - CT - CST", WIDE, 20.5, (222, 232, 232), anchor="lm", scale_x=0.98)
    A.line([(418, 681), (456, 663)], (222, 232, 232), 1.6)
    A.line([(476, 681), (538, 663)], (222, 232, 232), 1.6)

    def Z(x, y):
        return (60 + x / 2.5, 585 + y / 2.5)

    def car(pts, w=2.3):
        A.line([Z(*p) for p in pts], LINE, w)

    car([(222, 345), (300, 328), (560, 330), (830, 330), (960, 328), (1040, 345), (1095, 400), (1125, 470), (1134, 530), (1125, 595), (1095, 665), (1040, 715), (970, 737), (830, 735), (560, 735), (300, 735), (222, 720), (205, 660), (196, 530), (205, 410), (222, 345)])
    car([(245, 365), (300, 345), (560, 346), (830, 345), (1035, 362), (1088, 430), (1114, 530), (1088, 632), (1035, 702), (830, 720), (560, 720), (300, 720), (245, 703), (226, 620), (216, 530), (226, 430), (245, 365)])
    A.round_rect(*Z(322, 472), *Z(515, 595), 12, None, outline=LINE, w=2.3)
    A.round_rect(*Z(332, 481), *Z(505, 587), 9, None, outline=LINE, w=2.3)
    car([(255, 470), (300, 442), (520, 420), (530, 470), (530, 600), (520, 645), (300, 622), (255, 592), (248, 530), (255, 470)])
    car([(705, 415), (725, 530), (705, 645)])
    car([(520, 420), (640, 417), (705, 415), (810, 365)])
    car([(520, 645), (640, 650), (705, 645), (810, 700)])
    car([(880, 425), (920, 530), (885, 635)])
    car([(880, 395), (1010, 415), (1085, 455), (1115, 530), (1085, 610), (1010, 650), (880, 675)])
    car([(550, 335), (570, 375), (560, 410)])
    car([(550, 722), (570, 662), (555, 648)])
    for b in ((288, 330, 438, 400), (832, 338, 972, 392), (298, 660, 442, 730), (835, 675, 975, 735)):
        A.round_rect(*Z(b[0], b[1]), *Z(b[2], b[3]), 6, (12, 18, 34), outline=LINE, w=2.4)
    for b in ((298, 415, 432, 438), (835, 408, 975, 432), (300, 620, 435, 642), (835, 635, 975, 660)):
        A.round_rect(*Z(b[0], b[1]), *Z(b[2], b[3]), 4, (12, 18, 34), outline=LINE, w=2.0)
    # fuel, speed, odometer
    A.round_rect(*Z(70, 825), *Z(112, 890), 2, (226, 234, 232))
    A.rect(*Z(80, 833), *Z(102, 852), (34, 50, 62))
    A.line([Z(112, 840), Z(126, 858), Z(124, 882), Z(116, 884)], (226, 234, 232), 1.5)
    for i in range(9):
        x0 = 131 + i * 39
        if i < 5:
            A.rect(*Z(x0, 822), *Z(x0 + 36, 887), (232, 138, 44))
        else:
            A.rect(*Z(x0, 824), *Z(x0 + 33, 885), (24, 36, 46))
            A.line([Z(x0, 824), Z(x0 + 33, 824), Z(x0 + 33, 885), Z(x0, 885), Z(x0, 824)], (206, 216, 214), 1.2)
    for s, x in (("0", 148), ("1/2", 308), ("1", 468)):
        A.text(*Z(x, 913), s, ROBO_B, 19, (226, 234, 232))
    A.text(*Z(922, 833), "km/h", ROBO_B, 15, (226, 234, 232))

    # the right screen
    gradient(A, (1356, 588, 1868, 978), (38, 38, 42), (38, 38, 42), 20)
    gradient(A, (1362, 594, 1862, 972), (16, 20, 48), (40, 32, 78), 14)
    H = (1609, 820)
    SP = {0: -130.3, 30: -110, 60: -86.9, 90: -64.6, 120: -43, 150: -21.1, 180: 0, 210: 23.9, 240: 44.6, 270: 65.7, 300: 86.2, 330: 108.7, 360: 132.5}

    def sang(k):
        return interp(sorted(SP.items()), k)

    ring_band(A, H, 202, 216, sang(0), sang(360), (112, 132, 146))
    for k in range(0, 361, 10):
        t = sang(k)
        if k % 30 == 0:
            A.line([polar(H, 190, t), polar(H, 219, t)], (240, 244, 242), 3.6)
        else:
            A.line([polar(H, 189, t), polar(H, 201, t)], (232, 236, 236), 2.2)

    def R_(x, y):
        return (1350 + x / 2.5, 585 + y / 2.5)

    BIG = ((180, 653, 165), (120, 398, 316), (240, 888, 316), (60, 282, 566), (300, 968, 566), (360, 847, 855), (0, 342, 856))
    SMALL = ((150, 493, 227), (210, 808, 227), (90, 308, 432), (270, 948, 432), (30, 292, 716), (330, 952, 716))
    for k, x, y in BIG:
        A.text(*R_(x, y), str(k), WIDE, 27, WHT, stroke=1.0, strokecol=WHT)
    for k, x, y in SMALL:
        A.text(*R_(x, y), str(k), WIDE, 20, WHT, stroke=0.8, strokecol=WHT)
    A.text(*R_(637, 437), "km/h", ROBO_B, 20, WHT)
    A.round_rect(1752, 601, 1855, 645, 5, (62, 82, 94))
    A.final = A.finish(A.S, blur=2.0, strength=0.3)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    # the needles
    im = needle_sprite(sp, 262, 80, [(-82, 0, 4, 6, (14, 14, 14)), (0, 96, 5, 4, (14, 14, 14)), (96, 262, 8, 2, (244, 244, 242)), (112, 240, 2.4, 1, (212, 40, 34))], hub=31, hub_col=(14, 14, 14))
    add_needle(sp, im, C[0], C[1], "rpm", [(v, rev(v)) for v in (0, 10)])
    im = needle_sprite(sp, 150, 56, [(-56, 0, 2.2, 2.6, (66, 84, 104)), (0, 62, 2.2, 2.2, (66, 84, 104)), (62, 150, 4.5, 1.5, (244, 244, 242)), (70, 136, 1.2, 0.8, (212, 40, 34))], hub=18, hub_col=(30, 38, 62), hub_line=(150, 178, 192))
    add_needle(sp, im, H[0], H[1], "kmh", sorted(SP.items()))

    # the mode bar, the gear's "auto", warning lights while parked
    for when, word in (("sport", "SPORT"), ("corsa", "RACE")):
        L = Art(REF, box, S=2, bg=(0, 0, 0))
        L.text(80, 622, word, WIDE, 22, (255, 255, 255), anchor="lm")
        L.final = L.finish(L.S, blur=1, strength=0)
        im, left, top_ = sp.box(L, (76, 604, 260, 640), black=True)
        c = Image.new("RGBA", im.size, (40, 74, 84, 0))
        c.putalpha(im.getchannel("A"))
        sp.add_show((c, left, top_), when)
    L = Art(REF, box, S=2, bg=(0, 0, 0))
    L.text(1078, 766, "auto", ROBO_B, 20, (240, 110, 44))
    L.final = L.finish(L.S, blur=1, strength=0)
    sp.add_show(sp.box(L, (1050, 754, 1106, 778), black=True), "sport")
    W2 = Art(REF, box, S=2, bg=(0, 0, 0))
    W2.icon((496, 446, 536, 490), floor=46, gain=1.5)
    W2.icon((1450, 500, 1498, 542), floor=46, gain=1.5)
    W2.final = W2.finish(W2.S, blur=1.5, strength=0.4)
    sp.add_show(sp.box(W2, (490, 442, 542, 494), black=True), "parked")
    sp.add_show(sp.box(W2, (1444, 496, 1504, 546), black=True), "parked")

    solid_gear(sp, WIDE, 62, (238, 110, 44), 1102, 722)
    sp.font("speed", WIDE, 36, "0123456789", stroke=0.5, shear=0, track=0.5)
    sp.readout("speed", 434, 944, "m", 3, "speed", (226, 234, 232))
    sp.font("odo", ROBO_B, 27, "0123456789", shear=0)
    sp.readout("odo", 563, 949, "r", 6, "odoTrim", (226, 234, 232))
    sp.font("unit", ROBO_B, 15, "kmhpi/", shear=0)
    sp.readout("unit", 547, 919, "m", 2, "distUnit", (226, 234, 232))
    sp.font("clock", ROBO_B, 27, "0123456789:", shear=0, track=0.6)
    sp.readout("clock", 1803, 624, "m", 5, "clock", (238, 242, 240))
    return sp


def california():
    """the California's three dials, from the owner's photo (imports/refs/california_cluster_owner.png).
    Coordinates are photo pixels, or the zoomed views' (m, L, R). No maker's horse. The word on the photo's corner
    is the seller's, not the car's: it is outside the box."""
    box = (120, 270, 1460, 800)
    REF = "california_cluster_owner.png"
    A = Art(REF, box, S=2, bg=(9, 9, 12))
    sp = Spec("california", box[2] - box[0], box[3] - box[1], 1, 1, box[0], box[1])
    sp.redline, sp.idle = 7.5, 0.7

    def m(x, y):
        return (540 + x / 2.222, 270 + y / 2.222)

    def L_(x, y):
        return (130 + x / 2.5, 350 + y / 2.5)

    def R_(x, y):
        return (1020 + x / 2.3256, 370 + y / 2.3256)

    C = m(488, 515)
    BLUE = (116, 178, 206)
    RED = (250, 44, 30)
    BL2 = (92, 204, 224)
    WHT = (240, 242, 244)

    def rev(v):
        return 180 + 27 * v

    # the rev counter
    A.circle(C[0], C[1], 210, (92, 90, 90))
    A.circle(C[0], C[1], 205, (16, 16, 18))
    radial(A, C[0], C[1], 177, (84, 72, 16), (148, 128, 30))
    ring_band(A, C, 166, 177, rev(7.95), rev(9.95), RED)
    for i in range(0, 56):
        v = i / 5
        t = rev(v)
        col = (236, 236, 234)
        if i % 5 == 0:
            A.line([polar(C, 177, t), polar(C, 205, t)], (150, 150, 150), 2.6)
        else:
            A.line([polar(C, 180, t), polar(C, 192, t)], col, 1.4)
    NUM = {0: (488, 855), 1: (348, 818), 2: (238, 730), 3: (165, 580), 4: (165, 432), 5: (235, 295), 6: (362, 198), 7: (522, 178), 8: (675, 235), 9: (785, 350), 10: (828, 518)}
    for v, (x, y) in NUM.items():
        col = RED if v >= 8 else BLUE
        A.text(*m(x, y), str(v), WIDE, 34, col, stroke=1.0, strokecol=col)
    A.text(*m(628, 168), "7500", REG, 9.5, (206, 206, 186), rot=14)
    A.text(*m(762, 265), "8500", REG, 9.5, RED, rot=44)
    A.text(*m(845, 415), "9500", REG, 9.5, RED, rot=76)
    for r in (106, 111, 116, 121):
        ring_band(A, C, r - 0.5, r + 0.5, 181, 448, (104, 168, 176))
    for v in range(1, 11):
        t = rev(v)
        A.line([polar(C, 105, t), polar(C, 122, t)], (104, 168, 176), 1.1)
    A.text(*m(640, 505), "RPM", WIDE, 11.5, BLUE, stroke=0.15, strokecol=BLUE)
    A.text(*m(640, 535), "x 1000", REG, 9.5, BLUE)
    gw = [(545, 585), (565, 565), (815, 565), (830, 585), (805, 655), (770, 730), (680, 806), (590, 760), (550, 700)]
    A.poly([m(*p) for p in gw], (232, 112, 10))
    A.line([m(*p) for p in gw + gw[:1]], (120, 116, 110), 2)
    A.line([m(*p) for p in ((575, 688), (632, 688), (603, 716), (575, 688))], (252, 226, 30), 1.8)

    # the left screen
    gradient(A, (146, 475, 492, 734), (30, 30, 34), (30, 30, 34), 12)
    gradient(A, (149, 478, 489, 731), (82, 82, 88), (70, 72, 92), 10)
    A.rect(149, 478, 458, 507, (248, 248, 246))
    A.rect(*L_(44, 396), *L_(436, 772), (214, 214, 206))
    A.rect(*L_(52, 404), *L_(428, 764), (56, 62, 132))
    for a, b in ((52, 186), (196, 330), (340, 896)):
        A.rect(*L_(a, 780), *L_(b, 850), (156, 170, 214))
        A.rect(*L_(a + 3, 783), *L_(b - 3, 847), (42, 42, 62))
    gradient(A, (150, 692, 489, 730), (42, 46, 98), (40, 44, 92), 8)
    # coolant, oil
    A.line([L_(544, 458), L_(544, 512)], WHT, 1.8)
    A.line([L_(544, 462), L_(558, 462)], WHT, 1.2)
    A.line([L_(544, 478), L_(558, 478)], WHT, 1.2)
    A.line([L_(506, 516), L_(524, 508), L_(544, 516), L_(562, 508), L_(582, 516)], WHT, 1.6)
    A.line([L_(506, 526), L_(524, 518), L_(544, 526), L_(562, 518), L_(582, 526)], WHT, 1.6)
    A.line([L_(498, 682), L_(530, 690), L_(554, 690), L_(584, 680), L_(552, 708), L_(516, 708), L_(498, 682)], WHT, 1.7)
    A.line([L_(536, 646), L_(536, 690)], WHT, 1.8)
    A.line([L_(536, 652), L_(552, 652)], WHT, 1.2)
    A.line([L_(536, 668), L_(552, 668)], WHT, 1.2)
    for cy, nums in ((495, (("210", 725, 428), ("230", 775, 480), ("140", 690, 565), ("260", 760, 565), ("°F", 660, 492))), (680, (("240", 725, 614), ("300", 785, 700), ("140", 690, 750), ("360", 760, 750), ("°F", 660, 678)))):
        c = L_(725, cy)
        ring_band(A, c, 37.5, 40.5, -140, 104, WHT)
        ring_band(A, c, 37.5, 40.5, 104, 140, (240, 196, 50))
        for t in range(-140, 141, 35):
            A.line([polar(c, 33, t), polar(c, 38, t)], WHT, 1.2)
        for s, x, y in nums:
            A.text(*L_(x, y), s, ROBO_B, 7.8, WHT)
    A.line([L_(725, 680), L_(672, 752)], WHT, 1.8)
    A.line([L_(725, 680), L_(745, 668)], (150, 170, 210), 1.8)
    # fuel, odometer
    A.round_rect(*L_(66, 858), *L_(106, 932), 2, WHT)
    A.rect(*L_(76, 866), *L_(96, 884), (42, 46, 98))
    A.line([L_(106, 868), L_(128, 900), L_(122, 924), L_(112, 926)], WHT, 1.4)
    for i in range(10):
        x0 = 136 + i * 24.6
        if i < 5:
            A.rect(*L_(x0, 860), *L_(x0 + 22, 903), (246, 232, 190))
        else:
            A.line([L_(x0, 860), L_(x0 + 20, 860), L_(x0 + 20, 903), L_(x0, 903), L_(x0, 860)], (214, 214, 220), 1.0)
    for s, x in (("0", 150), ("1/2", 257), ("1", 373)):
        A.text(*L_(x, 930), s, ROBO_B, 14, WHT)

    # the speedometer
    H = R_(382, 575)
    radial(A, H[0], H[1], 186, (10, 10, 30), (12, 12, 22))
    A.line([polar(H, 186, t) for t in range(0, 365, 5)], (38, 38, 50), 1.4)

    def sp_ang(mph):
        return 180 + 1.4 * mph

    for r in (103, 106.5, 110, 113):
        ring_band(A, H, r - 0.65, r + 0.65, 0, 359.5, BL2)
    for k in range(0, 221, 10):
        t = sp_ang(k)
        if k % 20 == 0:
            A.line([polar(H, 104, t), polar(H, 124, t)], BL2, 1.5)
        else:
            A.line([polar(H, 113, t), polar(H, 119, t)], BL2, 1.1)
    NM = ((20, 235, 845, 26), (40, 118, 742, 19), (60, 72, 605, 26), (80, 95, 452, 19), (100, 190, 330, 26), (120, 325, 265, 19), (140, 478, 280, 26), (160, 607, 355, 19), (180, 680, 483, 26), (200, 688, 632, 19), (220, 615, 770, 26))
    for k, x, y, s in NM:
        A.text(*R_(x, y), str(k), WIDE, s * 0.92, BL2, rot=sp_ang(k), stroke=0.25, strokecol=BL2)
    A.text(*R_(378, 885), "0", WIDE, 12, BL2, rot=180)
    A.text(*R_(523, 578), "MPH", WIDE, 13, (160, 190, 226))
    A.final = A.finish(A.S, blur=2.0, strength=0.3)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    im = needle_sprite(sp, 180, 58, [(-58, 0, 3.2, 4, (10, 10, 10)), (0, 60, 4, 3.6, (10, 10, 10)), (60, 118, 6, 6, (116, 116, 112)), (118, 180, 6, 1.2, (116, 116, 112)), (82, 160, 2, 1.2, (238, 30, 60))], hub=20, hub_col=(10, 10, 10))
    add_needle(sp, im, C[0], C[1], "rpm", [(0, rev(0)), (10, rev(10))])
    im = needle_sprite(sp, 148, 8, [(0, 88, 2.6, 2.6, (20, 20, 30)), (88, 112, 6, 6, (118, 118, 116)), (112, 148, 6, 1.2, (118, 118, 116)), (94, 138, 2, 1, (238, 30, 60))])
    add_needle(sp, im, H[0], H[1], "mph", [(0, sp_ang(0)), (220, sp_ang(220))])

    L = Art(REF, box, S=2, bg=(0, 0, 0))
    L.text(*m(652, 745), "auto", ROBO_B, 12, (252, 226, 30))
    L.final = L.finish(L.S, blur=1, strength=0)
    sp.add_show(sp.box(L, (806, 596, 846, 616), black=True), "sport")
    # parked: the warning lights, as in the photo (owner, 2026-11-06: no fault note on the left screen)
    W2 = Art(REF, box, S=2, bg=(0, 0, 0))
    W2.icon((352, 372, 456, 412), floor=46, gain=1.4)
    W2.icon((280, 408, 358, 436), floor=46, gain=1.4)
    W2.icon((1054, 386, 1112, 416), floor=46, gain=1.4)
    W2.icon((1130, 386, 1205, 416), floor=46, gain=1.4)
    W2.icon((1088, 428, 1128, 444), floor=46, gain=1.4)
    W2.icon((520, 696, 562, 728), floor=46, gain=1.4)
    W2.icon((952, 696, 990, 728), floor=46, gain=1.4)
    W2.final = W2.finish(W2.S, blur=1.5, strength=0.4)
    for b in ((348, 368, 458, 416), (276, 404, 362, 440), (1050, 382, 1116, 420), (1126, 382, 1209, 420), (1084, 424, 1132, 448), (516, 692, 566, 732), (948, 692, 994, 732)):
        sp.add_show(sp.box(W2, b, black=True), "parked")

    solid_gear(sp, WIDE, 40, (252, 226, 30), *m(692, 682))
    sp.font("odo", ROBO_B, 22, "0123456789", shear=0)
    sp.readout("odo", 468, 713, "r", 6, "odoTrim", WHT)
    sp.font("unit", ROBO_B, 13, "kmhpi/", shear=0)
    sp.readout("unit", 317, 714, "m", 2, "distUnit", WHT)
    return sp


def murcielago():
    """the Murcielago's dials, drawn sharp from the SV model's own cluster seen straight on
    (imports/refs/murcielago_model_dials.png, 2963 px a metre; no photo: owner, 2026-11-06). Coordinates are that
    render's pixels. LP670-4 SV and the LP650-4 Roadster share it; only the SV shows the SV mark ("sv")."""
    box = (190, 170, 1250, 620)
    REF = "murcielago_model_dials.png"
    A = Art(REF, box, S=2, bg=(12, 12, 14))
    sp = Spec("murcielago", box[2] - box[0], box[3] - box[1], 1, 1, box[0], box[1])
    sp.redline, sp.idle = 8.0, 0.9
    WHT = (232, 234, 238)
    GOLD = (222, 168, 44)
    RED = (236, 44, 44)
    BAND = (118, 130, 150)
    SOFT = (168, 172, 180)

    # the face
    face = [(245, 400), (330, 325), (430, 225), (560, 188), (700, 178), (840, 188), (1000, 222), (1110, 325), (1225, 400), (1190, 480), (1060, 600), (950, 610), (835, 556), (565, 556), (450, 606), (340, 600), (215, 480)]
    A.poly(face, (46, 46, 48))
    radial(A, 700, 410, 230, (66, 66, 68), (46, 46, 48))

    def dial(C, red=None):
        A.circle(C[0], C[1], 123, (222, 224, 228))
        A.circle(C[0], C[1], 120, BAND)
        A.circle(C[0], C[1], 107, (42, 42, 44))
        if red:
            ring_band(A, C, 107, 120, red[0], red[1], RED)

    REV, SPD = (549, 407), (852, 407)

    def rev(v):
        return 180 + 30 * v

    def kph(k):
        return 180 + 0.75 * k

    dial(REV, (rev(8.5), rev(9.02)))
    dial(SPD)
    for i in range(0, 19):
        t = rev(i / 2)
        col = RED if i >= 17 else WHT
        if i % 2 == 0:
            A.line([polar(REV, 98, t), polar(REV, 126, t)], col, 3.4)
        else:
            A.line([polar(REV, 106, t), polar(REV, 118, t)], col, 2.0)
    for k, x, y in ((1, 507, 480), (2, 479, 450), (3, 466, 407), (4, 478, 366), (5, 509, 336), (6, 550, 325), (7, 593, 337), (8, 621, 367), (9, 632, 407)):
        col = RED if k == 9 else WHT
        A.text(x, y, str(k), TECH, 22, col, shear=0.14, stroke=0.2, strokecol=col)
    A.text(551, 364, "giri x 1000", REG, 8, SOFT)
    for k in range(0, 361, 10):
        t = kph(k)
        if k % 30 == 0:
            A.line([polar(SPD, 98, t), polar(SPD, 126, t)], WHT, 3.0)
        else:
            A.line([polar(SPD, 106, t), polar(SPD, 118, t)], WHT, 1.6)
    for k in range(30, 361, 30):
        x, y = polar(SPD, 84, kph(k))
        A.text(x, y, str(k), TECH, 12.5, WHT, stroke=0.1, strokecol=WHT)
    A.text(852, 355, "km/h", REG, 8.5, SOFT)
    # the two windows, the gear row
    for pts, inner in (([(875, 442), (998, 442), (982, 498), (875, 498)], (884, 448, 976, 492)), ([(598, 208), (802, 208), (784, 272), (616, 272)], (626, 216, 776, 264))):
        A.poly(pts, (84, 86, 100))
        A.rect(*inner, (34, 50, 54))
    A.rect(684, 284, 716, 334, (34, 38, 44))
    A.text(700, 198, "N123456", TECH, 16, WHT, track=2.0)

    # the small gauges
    def small(c, red_right):
        pts = [polar(c, 49, t) for t in range(-72, 73, 4)]
        A.line(pts, (196, 198, 204), 5)
        for t in (-72, -36, 0, 36, 72):
            A.line([polar(c, 40, t), polar(c, 53, t)], WHT, 1.6)
        a = 58 if red_right else -58
        tip = polar(c, 40, a)
        A.poly([tip, polar(c, 53, a - 8), polar(c, 53, a + 8)], RED)
        A.circle(c[0], c[1], 15, (6, 6, 8))

    for c, rr, nt in (((360, 411), False, 0), ((283, 483), True, 0), ((1041, 411), True, -14), ((1116, 480), True, -24)):
        small(c, rr)
        A.line([polar(c, -22, nt), polar(c, 44, nt)], GOLD, 3.6)
    for s, x, y in (("benzina", 295, 378), ("100 %", 395, 398), ("temperatura motore", 362, 450), ("130 °C", 318, 462), ("pressione olio", 1120, 379), ("10 bar", 1078, 426), ("temperatura olio", 1040, 448), ("150 °C", 1150, 462)):
        A.text(x, y, s, REG, 7.4, SOFT)
    A.final = A.finish(A.S, blur=2.0, strength=0.3)
    sp.bg = A.final.resize((round(sp.W * sp.bg_scale), round(sp.H * sp.bg_scale)), Image.LANCZOS)

    parts = [(-38, 0, 3.0, 3.4, GOLD), (0, 128, 3.4, 1.4, GOLD)]
    add_needle(sp, needle_sprite(sp, 128, 38, parts, hub=24, hub_col=(6, 6, 8)), REV[0], REV[1], "rpm", [(0, rev(0)), (9, rev(9))])
    add_needle(sp, needle_sprite(sp, 128, 38, parts, hub=24, hub_col=(6, 6, 8)), SPD[0], SPD[1], "kmh", [(0, kph(0)), (360, kph(360))])

    # the SV mark, only on the SV
    L = Art(REF, box, S=2, bg=(0, 0, 0))
    L.line([(566, 471), (600, 467), (578, 456), (612, 451)], WHT, 2.6)
    L.line([(604, 450), (620, 471), (642, 449)], WHT, 2.6)
    L.final = L.finish(L.S, blur=1, strength=0)
    sp.add_show(sp.box(L, (558, 442, 650, 478), black=True), "sv")

    solid_gear(sp, TECH, 46, (232, 210, 120), 700, 240, stroke=0.4)
    sp.font("odo", ROBO_B, 22, "0123456789", shear=0)
    sp.readout("odo", 972, 470, "r", 6, "odoTrim", (214, 196, 120))
    return sp


def lfa():
    import cluster_lfa_maybach as m

    return m.lfa(Spec, needle_sprite, add_needle)


def maybach():
    import cluster_lfa_maybach as m

    return m.maybach(Spec, needle_sprite, add_needle, glyph)


def mc12c():
    import cluster_imports as m

    return m.mc12c(Spec, needle_sprite, add_needle, glyph)


def sls():
    import cluster_imports as m

    return m.sls(Spec, needle_sprite, add_needle)


def sl65():
    import cluster_imports as m

    return m.sls(Spec, needle_sprite, add_needle, twin=True)


def f599():
    import cluster_imports as m

    return m.f599(Spec, needle_sprite, add_needle, glyph)


def dbx():
    import cluster_imports as m

    return m.dbx(Spec, needle_sprite, add_needle, glyph)


def sovereign():
    import cluster_imports as m

    return m.sovereign(Spec, needle_sprite, add_needle, glyph)


def z33():
    import cluster_imports as m

    return m.z33(Spec, needle_sprite, add_needle, glyph)


def g20():
    import cluster_imports as m

    return m.g20(Spec, needle_sprite, add_needle, glyph)


BUILDERS = {"mc12c": mc12c, "sls": sls, "sl65": sl65, "f599": f599, "dbx": dbx, "sovereign": sovereign, "z33": z33, "g20": g20, "revuelto": revuelto, "sv": sv, "huracan": huracan, "lp700": lp700, "urus": urus, "f458": f458, "california": california, "murcielago": murcielago, "lfa": lfa, "maybach": maybach}
PREVIEW = {
    "g20": ("g20_model_cluster.png", (0, 0, 834, 310), None, dict(v=3.4, gear="3", mph=58, manual=True, clock="2:40", odo="003274", distUnit="mi", kmh=False, fuel=0.6)),
    "sovereign": ("sls_sl65_cluster_owner.png", (0, 0, 740, 280), None, dict(v=3.0, gear="3", mph=70, manual=False, clock="2:40", odo="003274", distUnit="mi", kmh=False)),
    "z33": ("sls_sl65_cluster_owner.png", (0, 0, 750, 280), None, dict(v=3.0, gear="3", mph=70, manual=False, clock="2:40", odo="003274", distUnit="mi", kmh=False)),
    "dbx": ("dbx_cluster_owner.png", (60, 128, 748, 390), None, dict(v=0.8, gear="N", mph=0, manual=False, clock="10:57", odo="002434", date="08.08.2024", distUnit="mi", kmh=False, trip="69.1")),
    "f599": ("ferrari_599_cluster_owner.webp", (0, 208, 1600, 812), None, dict(v=0.9, gear="N", mph=0, manual=False, clock="23:36", odo="011972", distUnit="km", kmh=False, fuel=0.5)),
    "sl65": ("sls_sl65_cluster_owner.png", (71, 60, 677, 317), None, dict(v=0.8, gear="N", mph=0, manual=False, clock="2:40", odo="003274", distUnit="mi", kmh=False)),
    "sls": ("sls_sl65_cluster_owner.png", (71, 60, 677, 317), None, dict(v=0.8, gear="N", mph=0, manual=False, clock="2:40", odo="003274", distUnit="mi", kmh=False)),
    "mc12c": ("mclaren_12c_cluster_owner.webp", (14, 131, 974, 494), (14, 131, 974, 494), dict(v=1.0, gear="N", mph=0, manual=False, clock="10:47", odo="003274", distUnit="mi", kmh=False)),
    "lfa": ("lfa_cluster_owner.png", (14, 26, 466, 322), None, dict(v=7.0, gear="4", mph=99.4, manual=False, clock="12:56", odo="000364", range="36")),
    "maybach": ("maybach_gls_s680_cluster_owner.png", (2, 34, 594, 270), None, dict(v=0.9, gear="N", mph=0, manual=False, clock="12:06", odo="009857", range="190")),
    "murcielago": ("murcielago_model_dials.png", (190, 170, 1250, 620), None, dict(v=0.9, gear="N", mph=0, manual=False, clock="20:26", odo="009857", sv=True)),
    "f458": ("f458_cluster_owner.png", (56, 300, 1876, 990), None, dict(v=0.7, gear="N", mph=0, manual=False, clock="20:26", odo="009857", range="432")),
    "california": ("california_cluster_owner.png", (120, 270, 1460, 800), None, dict(v=0.0, gear="N", mph=0, manual=False, clock="20:26", odo="029822", range="432")),
    "urus": ("urus_performante_cluster_owner_level.png", (92, 236, 652, 392), None, dict(v=0.0, gear="N", mph=0, manual=True, clock="9:57", odo="2938", range="432")),
    "lp700": ("aventador_lp700_cluster_owner.png", (110, 150, 1400, 680), None, dict(v=3.0, gear="2", mph=31, manual=False, clock="10:45", date="10.08.2019")),
    # ref, the view in the ref, the same view in the design's pixels, a state
    "revuelto": ("revuelto_cluster_driving_owner_2.png", (235, 215, 1405, 645), None, dict(v=6.0, gear="1", mph=23, manual=True, clock="10:45", odo="000350", range="200", station="Radio Riviera")),
    "sv": ("aventador_sv_cluster_driving_owner.png", (40, 95, 1270, 610), (28, 92, 712, 365), dict(v=8.0, gear="5", mph=162.2, manual=True, lights=True, tcoff=True, odo="004600", range="130", gAccel="0.2", clock="06:04", stationShort="Radio Riviera")),
    "huracan": ("huracan_cluster_driving_owner.png", (100, 305, 940, 595), None, dict(v=3.0, gear="7", mph=69.6, manual=True, lights=True, odo="005558", range="530", clock="04:27")),
}


class Packer:
    """shelf packing into 1024 x 512 sheets (a 1024 x 1024 sheet never loaded in Studio)"""

    def __init__(self):
        self.sheets = [Image.new("RGBA", (1024, 512), (0, 0, 0, 0))]
        self.x = self.y = self.row = 0

    def put(self, im):
        w, h = im.size
        if self.x + w + 2 > 1024:
            self.x, self.y, self.row = 0, self.y + self.row + 2, 0
        if self.y + h > 512:
            self.sheets.append(Image.new("RGBA", (1024, 512), (0, 0, 0, 0)))
            self.x = self.y = self.row = 0
        at = (len(self.sheets), self.x, self.y, w, h)
        self.sheets[-1].alpha_composite(im, (self.x, self.y))
        self.x += w + 2
        self.row = max(self.row, h)
        return at


def num(v):
    return ("%.3f" % v).rstrip("0").rstrip(".")


def lua_list(vals):
    return "{ " + ", ".join(v if isinstance(v, str) and v.startswith(("{", '"')) else (num(v) if not isinstance(v, str) else '"%s"' % v) for v in vals) + " }"


def spec_lua(sp, ids):
    """the Spec as a Luau table; rects: { sheet, x, y, w, h }"""
    pk = Packer()
    out = []
    w = out.append

    def rect(im):
        return list(pk.put(im))

    blocks = [rect(b["im"]) + [b["left"], b["top"], b["v"]] + (['"%s"' % b["bind"]] if b.get("bind") else []) for b in sp.blocks]
    fills = []
    for f in sp.fills:
        pts = []
        for v, x in f["pts"]:
            pts += [v, x]
        fills.append(rect(f["im"]) + [f["left"], f["top"], f.get("lead", 0), lua_list(pts)])
    fuels = [rect(x["im"]) + [x["left"], x["top"]] for x in sp.fuels]
    shows = [rect(x["im"]) + [x["left"], x["top"], x["when"] or "always"] for x in sp.shows]
    needles = []
    for n in sp.needles:
        pts = []
        for a, b in n["pts"]:
            pts += [a, b]
        row = rect(n["im"]) + [n["x"], n["y"], '"%s"' % n["bind"], lua_list(pts)]
        if n.get("alt"):
            alt = []
            for a, b in n["alt"]:
                alt += [a, b]
            row.append(lua_list(alt))
        needles.append(row)
    gear = {ch: rect(e["im"]) for ch, e in sp.gear["sprites"].items()}
    fonts = {}
    for name, f in sp.fonts.items():
        g = {}
        for ch, (im, ox, oy, adv) in f["g"].items():
            g[ch] = rect(im) + [ox, oy, adv]
        fonts[name] = g
    pk_sheets = pk.sheets
    w("\t%s = {" % sp.name)
    w("\t\tW = %s, H = %s, A = %s, split = %s, idle = %s, redline = %s," % (num(sp.W), num(sp.H), num(sp.A), num(sp.W / 2), num(sp.idle), num(sp.redline)))
    w('\t\tbg = { "%s", "%s" },' % (ids.get(sp.name + "_bg_1", ""), ids.get(sp.name + "_bg_2", "")))
    w("\t\tsheets = { " + ", ".join('"%s"' % ids.get("%s_sheet_%d" % (sp.name, i + 1), "") for i in range(len(pk_sheets))) + " },")
    if os.path.exists(os.path.join(HERE, "window_%s.png" % sp.name)):
        w("\t\tclear = true,")
    if sp.bg_tint:
        w('\t\ttint = { "%s", %d, %d, %d },' % (sp.bg_tint["when"], *sp.bg_tint["color"]))
    w("\t\tblocks = {")
    for b in blocks:
        w("\t\t\t" + lua_list(b) + ",")
    w("\t\t},")
    w("\t\tfills = {")
    for b in fills:
        w("\t\t\t" + lua_list(b) + ",")
    w("\t\t},")
    if sp.marker:
        pts = []
        for q in sp.marker["pts"]:
            pts += list(q)
        c = sp.marker["color"]
        w("\t\tmarker = { color = { %d, %d, %d }, w = %s, glow = %s, pts = %s }," % (c[0], c[1], c[2], num(sp.marker["w"]), num(sp.marker.get("glow", 0)), lua_list(pts)))
    w("\t\tfuels = {")
    for b in fuels:
        w("\t\t\t" + lua_list(b) + ",")
    w("\t\t},")
    w("\t\tshows = {")
    for b in shows:
        w("\t\t\t" + lua_list(b) + ",")
    w("\t\t},")
    if needles:
        w("\t\tneedles = {")
        for b in needles:
            w("\t\t\t" + lua_list(b) + ",")
        w("\t\t},")
    w("\t\tgear = { x = %s, y = %s, sprites = {" % (num(sp.gear["x"]), num(sp.gear["y"])))
    for ch, r in gear.items():
        w('\t\t\t["%s"] = %s,' % (ch, lua_list(r)))
    w("\t\t} },")
    w("\t\tfonts = {")
    for name, g in fonts.items():
        w("\t\t\t%s = {" % name)
        for ch, r in g.items():
            key = ch if ch != '"' else '\\"'
            w('\t\t\t\t["%s"] = %s,' % (key, lua_list(r)))
        w("\t\t\t},")
    w("\t\t},")
    w("\t\treadouts = {")
    for r in sp.readouts:
        c = r["tint"]
        w('\t\t\t{ font = "%s", x = %s, y = %s, align = "%s", len = %d, bind = "%s", color = { %d, %d, %d }, when = %s },' % (r["font"], num(r["x"]), num(r["y"]), r["align"], r["len"], r["bind"], c[0], c[1], c[2], '"%s"' % r["when"] if r["when"] else "nil"))
    w("\t\t},")
    w("\t\tlabels = {")
    for l in sp.labels:
        c = l["color"]
        w('\t\t\t{ x = %s, y = %s, w = %s, h = %s, bind = "%s", color = { %d, %d, %d }, when = %s },' % (num(l["x"]), num(l["y"]), num(l["w"]), num(l["h"]), l["bind"], c[0], c[1], c[2], '"%s"' % l["when"] if l.get("when") else "nil"))
    w("\t\t},")
    w("\t},")
    return out, pk_sheets


def masked(sp):
    """a car whose screen sits behind its frame: the picture cut to the frame's openings
    (tools/lambo/window_mask.py), so no corner shows past the hood"""
    p = os.path.join(HERE, "window_%s.png" % sp.name)
    if not os.path.exists(p):
        return False
    m = Image.open(p).convert("L").resize(sp.bg.size, Image.LANCZOS)
    sp.bg = sp.bg.convert("RGBA")
    sp.bg.putalpha(m)
    return True


def write_assets(sp, out):
    masked(sp)
    W, H = sp.bg.size
    half = W // 2
    sp.bg.crop((0, 0, half, H)).save(os.path.join(out, sp.name + "_bg_1.png"))
    sp.bg.crop((half, 0, W, H)).save(os.path.join(out, sp.name + "_bg_2.png"))
    _, sheets = spec_lua(sp, {})
    for i, im in enumerate(sheets):
        im.save(os.path.join(out, "%s_sheet_%d.png" % (sp.name, i + 1)))
    print(sp.name, "bg", W, H, "half", half, "sheets", len(sheets))


def main():
    out = sys.argv[1]
    what = sys.argv[2] if len(sys.argv) > 2 else "preview"
    only = sys.argv[3] if len(sys.argv) > 3 else None
    os.makedirs(out, exist_ok=True)
    lua = []
    ids = {}
    idp = os.path.join(HERE, "cluster_ids.json")
    if os.path.exists(idp):
        ids = json.load(open(idp))
    for name, fn in BUILDERS.items():
        if only and only != name:
            continue
        sp = fn()
        sp.build_fonts()
        if what == "preview":
            ref, bx, view, st = PREVIEW[name]
            if view:
                k = 1600 / (view[2] - view[0])
                im = compose(sp, st, scale=k).crop((round((view[0] - sp.ox) * k), round((view[1] - sp.oy) * k), round((view[2] - sp.ox) * k), round((view[3] - sp.oy) * k)))
            else:
                im = compose(sp, st, scale=1600 / sp.W)
            side_by_side(bx, ref, im, os.path.join(out, name + "_drive.jpg"))
            print(name, "pieces", len(sp.blocks), len(sp.shows), len(sp.readouts))
        elif what == "assets":
            write_assets(sp, out)
        elif what == "lua":
            t, _ = spec_lua(sp, ids)
            lua += t
    if what == "lua":
        path = os.path.join(ROOT, "src", "client", "LamboClusterArt.lua")
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write("-- made by tools/lambo/cluster_live.py (do not edit by hand): the live Revuelto, Aventador SV, LP700 and\n")
            f.write("-- Huracan screens: pictures, pieces and where they sit. Design pixels; rects in sheet pixels.\n")
            f.write("return {\n" + "\n".join(lua) + "\n}\n")
        print("wrote", path, os.path.getsize(path))


if __name__ == "__main__":
    main()
