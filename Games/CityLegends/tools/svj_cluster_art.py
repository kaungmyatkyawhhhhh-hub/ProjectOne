"""The Aventador SVJ screen, drawn after the owner's photo of the real one (2026-11-02), sharp:
the static picture (screens, hex grid, rev band unlit, numbers, labels, wing, car), the rev band's
lit blocks and the readout glyphs. Layout in design pixels 1110 x 400 (the model's screen, side
screens included), drawn 3x and shrunk. No maker's marks.

    python tools/svj_cluster_art.py outdir [--preview] [--assets]

--assets: the pictures for the game (background halves, sprite sheets) into outdir, and
src/client/SVJClusterArt.lua (asset ids from tools/svj_cluster_ids.json once uploaded).

--preview: also the whole screen at a sample state (gear 5, 271 km/h, 8,400 rpm, CORSA), for the
owner to approve before it goes in.
"""

import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1110, 400
S = 3  # drawn at 3x
FONTS = "C:/Users/USER/AppData/Local/Roblox/Versions/version-11f155f3450f4c8e/content/fonts/"
BOLD = FONTS + "Sarpanch-Bold.ttf"
REG = FONTS + "Sarpanch-Regular.ttf"
WIDE = FONTS + "Michroma-Regular.ttf"
WORD = FONTS + "TitilliumWeb-Bold.ttf"

# the dial: an oval round (CX, CY); value v (0-10, x1000 rpm) sits at angle T0 + TV * v
CX, CY, RX, RY = 580.0, 302.0, 348.0, 262.0
T0, TV = -85.0, 17.0
K_OUT = 0.972  # the rev band runs in from the yellow arc to the number line


def k_in(v):
    """the band's inner edge: deeper at the top (as on the car)"""
    return 0.805 + 0.055 * (abs(v - 5) / 5) ** 2


def k_line(v):
    return k_in(v) - 0.022


BLOCKS = 30  # 3 per 1,000 rpm
RED_FROM = 8.33  # blocks from here are the red zone

YELLOW = (238, 214, 40)
WHITE = (238, 243, 250)
SOFT = (170, 190, 215)
RED = (232, 32, 40)
CYAN = (60, 200, 255)


def tv(v):
    return T0 + TV * v


def pt(t, k):
    a = math.radians(t)
    return CX + math.sin(a) * RX * k, CY - math.cos(a) * RY * k


def s(*xy):
    return [c * S for c in xy]


class Canvas:
    def __init__(self, w=W, h=H, bg=(0, 0, 0, 0)):
        self.im = Image.new("RGBA", (w * S, h * S), bg)
        self.d = ImageDraw.Draw(self.im)

    def poly(self, pts, fill=None, outline=None, width=1):
        p = [(x * S, y * S) for x, y in pts]
        if fill:
            self.d.polygon(p, fill=fill)
        if outline:
            self.d.line(p + [p[0]], fill=outline, width=round(width * S), joint="curve")

    def line(self, pts, color, width):
        self.d.line([(x * S, y * S) for x, y in pts], fill=color, width=round(width * S), joint="curve")

    def rect(self, x0, y0, x1, y1, fill=None, outline=None, width=1, r=0):
        self.d.rounded_rectangle(s(x0, y0, x1, y1), radius=r * S, fill=fill, outline=outline, width=round(width * S))

    def paste_layer(self, layer):
        self.im.alpha_composite(layer)

    def text(self, x, y, t, size, color, font=BOLD, anchor="mm", shear=0.18, glow=0, stroke=0):
        """text centred (anchor) at (x, y), slanted like the car's screen"""
        fo = ImageFont.truetype(font, round(size * S))
        l, tp, r, b = fo.getbbox(t, anchor=anchor)
        pad = round(size * S)
        w, h = r - l + 2 * pad, b - tp + 2 * pad
        m = Image.new("L", (w, h))
        ImageDraw.Draw(m).text((pad - l, pad - tp), t, font=fo, fill=255, anchor=anchor, stroke_width=round(stroke * S))
        # slant about the text's middle line
        m = m.transform(m.size, Image.AFFINE, (1, shear, -shear * h / 2, 0, 1, 0), Image.BICUBIC)
        ox, oy = round(x * S + l - pad), round(y * S + tp - pad)
        if glow:
            g = m.filter(ImageFilter.GaussianBlur(glow * S))
            layer = Image.new("RGBA", m.size, color[:3] + (0,))
            layer.putalpha(g.point(lambda a: int(a * 0.55)))
            self.im.alpha_composite(layer, (ox, oy))
        layer = Image.new("RGBA", m.size, color[:3] + (255,))
        layer.putalpha(m)
        self.im.alpha_composite(layer, (ox, oy))

    def done(self, scale=1):
        return self.im.resize((round(W * scale), round(H * scale)), Image.LANCZOS)


def grid():
    ys, xs = np.mgrid[0 : H * S, 0 : W * S].astype(np.float32) / S
    return xs, ys


def kmap():
    xs, ys = grid()
    k = np.hypot((xs - CX) / RX, (CY - ys) / RY)
    t = np.degrees(np.arctan2((xs - CX) / RX, (CY - ys) / RY))
    return k, t


def gradient_fill(c, mask, top, bottom, along):
    """fills mask (bool, canvas size) with a colour going from top (along=0) to bottom (along=1)"""
    a = np.clip(along, 0, 1)[..., None]
    col = np.array(top, np.float32) * (1 - a) + np.array(bottom, np.float32) * a
    rgba = np.zeros((H * S, W * S, 4), np.uint8)
    rgba[..., :3] = col.astype(np.uint8)
    rgba[..., 3] = mask * 255
    c.im.alpha_composite(Image.fromarray(rgba))


def block_poly(i, k1=K_OUT, gap=1.1):
    v0, v1 = 10 * i / BLOCKS, 10 * (i + 1) / BLOCKS
    t0 = tv(v0) + gap / 2
    t1 = tv(v1) - gap / 2
    n = 6
    outer = [pt(t0 + (t1 - t0) * j / n, k1) for j in range(n + 1)]
    inner = [pt(t1 - (t1 - t0) * j / n, k_in(v1 - (v1 - v0) * j / n)) for j in range(n + 1)]
    return outer + inner


def screens(c):
    """the three screens' backgrounds and the black around them"""
    c.rect(0, 0, W, H, fill=(3, 4, 6, 255))
    # middle screen: navy, darker at the top, a blue glow low down
    xs, ys = grid()
    mid = (xs > 212) & (xs < 948) & (ys > 4) & (ys < 396)
    # rounded top corners
    mid &= ~(((xs < 262) | (xs > 898)) & (ys < 54) & (np.hypot(np.minimum(abs(xs - 262), abs(xs - 898)), ys - 54) > 50))
    along = (ys - 4) / 392
    gradient_fill(c, mid, (6, 12, 26), (16, 34, 70), along)
    glow = np.exp(-(((xs - 580) / 330) ** 2 + ((ys - 330) / 80) ** 2))
    rgba = np.zeros((H * S, W * S, 4), np.uint8)
    rgba[..., 0], rgba[..., 1], rgba[..., 2] = 30, 80, 150
    rgba[..., 3] = (glow * 90 * mid).astype(np.uint8)
    c.im.alpha_composite(Image.fromarray(rgba))
    for x0, x1 in ((12, 202), (958, 1098)):
        c.rect(x0, 112, x1, 392, fill=(8, 13, 22, 255), r=10)
        side = (xs > x0) & (xs < x1) & (ys > 112) & (ys < 392)
        gradient_fill(c, side, (8, 13, 24), (14, 26, 48), (ys - 112) / 280)


def hexes(c):
    """the hex grid in the lower half (thin lighter-blue lines, bigger towards the bottom)"""
    layer = Canvas()
    col = (52, 92, 150, 255)
    for row in range(5):
        y = 236 + row * 34
        hw = 38 + row * 3
        for j in range(-8, 9):
            x = 580 + j * hw * 1.5 + (row % 2) * hw * 0.75
            if not (220 < x < 940):
                continue
            hh = 17
            p = [(x - hw / 2, y), (x - hw / 4, y - hh), (x + hw / 4, y - hh), (x + hw / 2, y), (x + hw / 4, y + hh), (x - hw / 4, y + hh)]
            layer.poly(p, outline=col, width=1.4)
    # fade the grid out under the dial and at the sides
    xs, ys = grid()
    k = np.hypot((xs - CX) / RX, (CY - ys) / RY)
    keep = np.clip((ys - 236) / 60, 0, 1) ** 1.5 * np.clip((1.0 - k) / 0.08 + 0.4, 0, 1) * np.clip((360 - abs(xs - 580)) / 40, 0, 1)
    a = np.asarray(layer.im)[..., 3].astype(np.float32) * keep
    arr = np.asarray(layer.im).copy()
    arr[..., 3] = a.astype(np.uint8)
    c.im.alpha_composite(Image.fromarray(arr))


def band(c, lit_upto=None, only=None):
    """the rev band's blocks: unlit (lit_upto None) or lit up to a value; only: one block's index"""
    k, t = kmap()
    for i in range(BLOCKS):
        if only is not None and i != only:
            continue
        v0 = 10 * i / BLOCKS
        lit = lit_upto is not None and v0 < lit_upto
        red = v0 >= RED_FROM - 1e-6
        m = Image.new("L", (W * S, H * S))
        ImageDraw.Draw(m).polygon([(x * S, y * S) for x, y in block_poly(i)], fill=255)
        mask = np.asarray(m) > 127
        along = (K_OUT - k) / (K_OUT - k_in(v0 + 5 / BLOCKS))  # 0 at the outside
        if lit and red:
            top, bot, edge = (255, 70, 70), (170, 14, 24), (255, 150, 150, 255)
        elif red:
            top, bot, edge = (205, 30, 40), (110, 10, 18), (240, 80, 80, 255)
        elif lit:
            top, bot, edge = (215, 228, 245), (40, 62, 100), WHITE + (255,)
        else:
            top, bot, edge = (34, 46, 70), (14, 20, 34), (70, 88, 118, 255)
        gradient_fill(c, mask, top, bot, along)
        c.poly(block_poly(i), outline=edge, width=1.6 if lit else 1.2)


def number_line(c):
    """the yellow line inside the band, stepping out round each number; orange-red from 8.5"""
    pts = []
    n = 700
    for j in range(n + 1):
        v = -0.12 + 10.24 * j / n
        k = k_line(v) - 0.03
        for tick in range(11):
            d = abs(v - tick)
            if d < 0.17:
                k = k_line(v)
            elif d < 0.27:
                k = k_line(v) - 0.03 * (d - 0.17) / 0.1
        pts.append((v, pt(tv(v), k)))
    seg = []
    for v, p in pts:
        seg.append(p)
        if len(seg) > 1:
            col = YELLOW if v < 8.5 else ((255, 120, 30) if v < 9 else (240, 40, 40))
            c.line(seg[-2:], col, 2.4)


def outer_arc(c):
    pts = [pt(tv(-0.2 + 10.4 * j / 300), 0.99) for j in range(301)]
    c.line(pts, YELLOW, 3.2)


def top_strip(c):
    """the cyan fan above the arc"""
    layer = Canvas()
    for i in range(3, 28):
        v0, v1 = 10 * i / BLOCKS, 10 * (i + 1) / BLOCKS
        f = 1 - abs(i - 15) / 13
        k1 = 1.02 + 0.07 * f
        p = [pt(tv(v0) + 0.5, 1.012), pt(tv(v0) + 0.5, k1), pt(tv(v1) - 0.5, k1), pt(tv(v1) - 0.5, 1.012)]
        layer.poly(p, fill=(70, 190, 255, int(110 + 120 * f)))
    k, t = kmap()
    arr = np.asarray(layer.im).copy()
    arr[..., 3] = (arr[..., 3] * np.clip(1.35 - (k - 1.0) / 0.1, 0.25, 1)).astype(np.uint8)
    c.im.alpha_composite(Image.fromarray(arr))


def numbers(c):
    for v in range(11):
        x, y = pt(tv(v), k_line(v) - 0.085)
        c.text(x, y, str(v), 24, RED if v >= 9 else WHITE)


def wing(c):
    """the rear-wing picture (left, below): a wing over stacked flow lines, no badge"""
    x, y = 340, 330
    for i in range(6):
        w = 14 + i * 12
        c.rect(x - w / 2, y + 6 + i * 6, x + w / 2, y + 9 + i * 6, fill=(225, 232, 244, 255))
    # the wing: a wide blade swept up at the tips
    c.poly([(x - 46, y - 10), (x - 10, y - 4), (x + 10, y - 4), (x + 46, y - 10), (x + 44, y - 4), (x + 10, y + 2), (x - 10, y + 2), (x - 44, y - 4)], fill=(240, 244, 250, 255))
    c.rect(x - 4, y, x + 4, y + 6, fill=(240, 244, 250, 255))
    c.text(x, 303, "0.0", 11, WHITE, WIDE, stroke=0.2)
    c.text(268, 322, "0.0", 11, WHITE, WIDE, stroke=0.2)
    c.text(412, 322, "0.0", 11, WHITE, WIDE, stroke=0.2)
    c.text(x, 380, "0.1", 11, WHITE, WIDE, stroke=0.2)


def arrows(c, x, y):
    for i in range(4):
        yy = y + i * 7
        c.poly([(x - 9, yy), (x + 9, yy), (x, yy + 6)], fill=(70, 200, 255, 255))


def car(c):
    """a low wedge supercar from the side, white with blue shading, speed streaks behind"""
    layer = Canvas()
    for i in range(7):
        y = 333 + i * 5
        layer.line([(470 + i * 6, y), (540, y)], (60, 170, 255, 140), 2)
    x, y = 583, 350
    body = [
        (x - 88, y - 2), (x - 86, y - 9), (x - 50, y - 15), (x - 18, y - 30), (x + 22, y - 32), (x + 58, y - 22),
        (x + 84, y - 19), (x + 86, y - 4), (x + 72, y + 2), (x - 80, y + 2),
    ]
    layer.poly(body, fill=(226, 236, 248, 255))
    layer.poly([(x - 36, y - 17), (x - 14, y - 28), (x + 18, y - 29), (x + 40, y - 20)], fill=(60, 90, 140, 255))
    layer.poly([(x + 62, y - 34), (x + 92, y - 34), (x + 92, y - 30), (x + 62, y - 30)], fill=(226, 236, 248, 255))
    layer.poly([(x + 72, y - 30), (x + 76, y - 30), (x + 74, y - 20), (x + 70, y - 20)], fill=(200, 214, 232, 255))
    layer.line([(x - 70, y - 8), (x + 80, y - 10)], (140, 170, 210, 255), 1.6)
    for wx in (x - 50, x + 55):
        layer.d.ellipse(s(wx - 14, y - 12, wx + 14, y + 16), fill=(30, 40, 60, 255))
        layer.d.ellipse(s(wx - 9, y - 7, wx + 9, y + 11), fill=(150, 170, 200, 255))
        layer.d.ellipse(s(wx - 4, y - 2, wx + 4, y + 6), fill=(40, 52, 76, 255))
    glow = layer.im.filter(ImageFilter.GaussianBlur(6 * S))
    g = np.asarray(glow).copy()
    g[..., 0], g[..., 1], g[..., 2] = 80, 180, 255
    g[..., 3] = (g[..., 3] * 0.5).astype(np.uint8)
    c.im.alpha_composite(Image.fromarray(g))
    c.im.alpha_composite(layer.im)


def middle_labels(c):
    # the drive aids: a red pill and the traction-off lamp
    c.rect(458, 150, 496, 172, fill=(225, 30, 40, 255), r=9)
    c.text(477, 156, "ND", 8.5, WHITE, BOLD, shear=0)
    c.text(477, 166, "EBC", 8.5, WHITE, BOLD, shear=0)
    tc = (236, 214, 40)
    c.rect(673, 135, 693, 146, outline=tc + (255,), width=1.8, r=3)
    c.line([(676, 148), (680, 152), (676, 156)], tc + (255,), 1.6)
    c.line([(686, 148), (690, 152), (686, 156)], tc + (255,), 1.6)
    c.text(683, 166, "OFF", 9, tc, BOLD, shear=0)
    # the line under the gear strip and the one over the hex grid
    c.line([(395, 216), (505, 216)], (110, 140, 185, 255), 1)
    c.line([(655, 216), (770, 216)], (110, 140, 185, 255), 1)
    c.line([(350, 242), (820, 242)], (40, 60, 95, 255), 1)
    # aero: front and rear load arrows, the wing mode
    c.text(490, 280, "ANT", 9, WHITE, REG, shear=0)
    arrows(c, 471, 290)
    c.text(472, 324, "CARICO", 8.5, WHITE, REG, shear=0)
    c.text(472, 333, "ALA", 8.5, WHITE, REG, shear=0)
    c.text(674, 280, "POST", 9, WHITE, REG, shear=0)
    arrows(c, 692, 290)
    c.rect(522, 300, 636, 313, fill=(10, 22, 44, 230), r=4)
    c.text(579, 306.5, "MODALITÀ ALA ON", 8.5, WHITE, REG, shear=0)
    c.text(556, 384, "Cx", 9, WHITE, REG, shear=0)
    for i in range(5):
        c.poly([(568 + i * 7, 388), (572 + i * 7, 380), (576 + i * 7, 380), (572 + i * 7, 388)], fill=(70, 160, 240, 255))
    c.text(910, 280, "RPM", 9, WHITE, REG, shear=0)
    c.text(910, 291, "x1000", 9, WHITE, REG, shear=0)
    c.text(849, 370, "km/h", 12, WHITE, REG)


def ladder(c, x, y, h, n, red_top, lean=0.22):
    """a slanted bar gauge: a ladder of short bars, the top ones red"""
    for i in range(n):
        yy = y + h - i * h / n
        xx = x - (h - i * h / n) * lean
        col = RED + (255,) if i >= n - red_top else (220, 228, 240, 255)
        c.rect(xx, yy - h / n * 0.62, xx + 22, yy, fill=col)


def side_screens(c):
    # left: oil temperature, oil pressure, the battery: icons over slanted ladders
    for i, lab in enumerate(("OIL", "°C", "Bar")):
        c.text(44 + i * 52, 214, lab, 9.5, (230, 200, 60), REG, shear=0)
    for i in range(3):
        ladder(c, 52 + i * 52, 228, 150, 14, 3 if i < 2 else 0)
    # right: the fuel pump, coolant
    pump = (230, 236, 246, 255)
    c.rect(978, 137, 990, 155, fill=pump, r=2)
    c.rect(980, 140, 988, 145, fill=(10, 14, 24, 255))
    c.line([(990, 142), (995, 146), (995, 154)], pump, 1.6)
    c.text(990, 214, "°C", 10, WHITE, REG, shear=0)
    c.text(1050, 214, "H", 10, (230, 200, 60), REG, shear=0)
    for i in range(2):
        ladder(c, 1003 + i * 52, 228, 150, 14, 3 if i == 0 else 0)


def static(c):
    screens(c)
    hexes(c)
    top_strip(c)
    outer_arc(c)
    band(c)
    number_line(c)
    numbers(c)
    wing(c)
    middle_labels(c)
    side_screens(c)
    c.text(18, 190, "25.5 °C", 12, WHITE, WORD, anchor="lm")


def live(c, gear="5", kmh="271", rpm=8.4, mode="CORSA", odo="000685 km", clock="17:01", date="20.09.2018", rng="230"):
    """what changes, drawn as the game will draw it (for the preview)"""
    band(c, lit_upto=rpm)
    # the red marker at the current revs
    t = tv(rpm)
    c.line([pt(t, k_in(rpm) - 0.01), pt(t, 1.035)], (255, 40, 40, 255), 2.6)
    # the gear strip either side of the gear, the gear
    order = ["R", "N", "1", "2", "3", "4", "5", "6", "7"]
    i = order.index(gear) if gear in order else 1
    left, right = "".join(order[:i]), "".join(order[i + 1 :])
    c.text(505, 201, left, 15, SOFT, WIDE, anchor="rm", stroke=0.5)
    c.text(655, 201, right, 15, SOFT, WIDE, anchor="lm", stroke=0.5)
    c.text(582, 226, gear, 132, RED, BOLD, glow=4)
    c.text(425, 258, mode, 19, RED, WORD)
    c.text(805, 258, odo, 14, WHITE, WIDE, anchor="rm", stroke=0.6)
    c.text(868, 334, kmh, 50, WHITE, WIDE, anchor="rm", stroke=1.6)
    # side screens
    c.text(18, 150, clock, 20, WHITE, WIDE, anchor="lm", stroke=0.6)
    c.text(18, 172, date, 10, WHITE, WIDE, anchor="lm", stroke=0.2)
    c.text(1000, 146, rng, 19, WHITE, WIDE, anchor="lm", stroke=0.6)
    c.text(849, 370, "km/h", 12, WHITE, REG)


# ---- the pieces for the game -------------------------------------------------------------------
A = 1.5  # sprite pixels per design pixel (the screen's SurfaceGui is drawn 600 high)
BG = 1.8  # background pixels per design pixel (two halves, each under 1024 wide)

# the readouts: (font, design size, stroke, colour, glow, characters)
GLYPHS = {
    "big": (WIDE, 50, 1.6, WHITE, 0, "0123456789"),
    "small": (WIDE, 20, 0.6, WHITE, 0, "0123456789:.kmhpi/RNP "),
    "gear": (BOLD, 132, 0, RED, 4, "RNP123456789"),
}
WORDS = {"CORSA": (WORD, 19, RED), "STRADA": (WORD, 19, RED), "km/h": (REG, 12, WHITE), "mph": (REG, 12, WHITE)}
SHEAR = 0.18


def glyph(ch, font, size, color, stroke, glow):
    """one character (or word) slanted, in a cell centred on its text middle line; returns the
    image (A px per design px), the cell's left pad and its advance, both in design pixels"""
    Q = 4
    fo = ImageFont.truetype(font, round(size * A * Q))
    asc, desc = fo.getmetrics()
    adv = fo.getlength(ch)
    padx = round(size * A * Q * 0.3 + (glow * 3 + stroke) * A * Q)
    pady = round(size * A * Q * 0.08 + (glow * 3 + stroke) * A * Q)
    w, h = round(adv) + 2 * padx, asc + desc + 2 * pady
    m = Image.new("L", (w, h))
    ImageDraw.Draw(m).text((padx, pady), ch, font=fo, fill=255, anchor="la", stroke_width=round(stroke * A * Q))
    m = m.transform(m.size, Image.AFFINE, (1, SHEAR, -SHEAR * h / 2, 0, 1, 0), Image.BICUBIC)
    out = Image.new("RGBA", (w, h), color[:3] + (0,))
    if glow:
        out.putalpha(m.filter(ImageFilter.GaussianBlur(glow * A * Q)).point(lambda a: int(a * 0.55)))
    top = Image.new("RGBA", (w, h), color[:3] + (255,))
    top.putalpha(m)
    out.alpha_composite(top)
    return out.resize((max(1, round(w / Q)), max(1, round(h / Q))), Image.LANCZOS), padx / Q / A, adv / Q / A


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
        at = (len(self.sheets), self.x, self.y)
        self.sheets[-1].alpha_composite(im, (self.x, self.y))
        self.x += w + 2
        self.row = max(self.row, h)
        return at


def lua_num(v):
    return ("%.2f" % v).rstrip("0").rstrip(".")


def build_assets(out, base):
    # the background in two halves
    full = base.resize((round(W * BG), round(H * BG)), Image.LANCZOS)
    half = full.width // 2
    full.crop((0, 0, half, full.height)).save(os.path.join(out, "svj_bg_left.png"))
    full.crop((half, 0, full.width, full.height)).save(os.path.join(out, "svj_bg_right.png"))
    pk = Packer()
    # the lit blocks, each cut out along its own outline
    lit = Canvas()
    band(lit, lit_upto=11)
    litA = lit.im.resize((round(W * A), round(H * A)), Image.LANCZOS)
    blocks = []
    for i in range(BLOCKS):
        poly = block_poly(i)
        xs_, ys_ = [p[0] for p in poly], [p[1] for p in poly]
        box = (math.floor((min(xs_) - 2) * A), math.floor((min(ys_) - 2) * A), math.ceil((max(xs_) + 2) * A), math.ceil((max(ys_) + 2) * A))
        m = Image.new("L", litA.size)
        ImageDraw.Draw(m).polygon([(x * A, y * A) for x, y in poly], fill=255, outline=255, width=3)
        arr = np.asarray(litA.crop(box)).copy()
        arr[..., 3] = np.minimum(arr[..., 3], np.asarray(m.crop(box)))
        sh, ax, ay = pk.put(Image.fromarray(arr))
        blocks.append((sh, ax, ay, box[2] - box[0], box[3] - box[1], box[0] / A, box[1] / A, 10 * i / BLOCKS))
    def tight(ims, keys):
        """crops each picture to its own ink across, and all of them to their shared ink up and
        down; entries: sheet, x, y, w, h (sheet px), left of the pen, top from the middle line,
        advance (design px)"""
        y0 = min(im.getbbox()[1] for im, _, _ in ims if im.getbbox())
        y1 = max(im.getbbox()[3] for im, _, _ in ims if im.getbbox())
        out_ = {}
        for key, (im, padx, adv) in zip(keys, ims):
            bb = im.getbbox()
            if not bb:
                out_[key] = (1, 0, 0, 0, 0, 0, 0, adv)
                continue
            piece = im.crop((bb[0], y0, bb[2], y1))
            sh, ax, ay = pk.put(piece)
            out_[key] = (sh, ax, ay, piece.width, piece.height, bb[0] / A - padx, (y0 - im.height / 2) / A, adv)
        return out_

    fonts = {}
    for name, (font, size, stroke, color, glow, chars) in GLYPHS.items():
        fonts[name] = (size, tight([glyph(ch, font, size, color, stroke, glow) for ch in chars], list(chars)))
    words = {}
    for wname, (font, size, color) in WORDS.items():
        words.update(tight([glyph(wname, font, size, color, 0, 0)], [wname]))
    for n, sheet in enumerate(pk.sheets, 1):
        sheet.save(os.path.join(out, f"svj_sprites_{n}.png"))
    return half / BG, blocks, fonts, words, len(pk.sheets)


def write_lua(path, ids, split, blocks, fonts, words, nsheets):
    T = "\t"
    L = [
        "-- made by tools/svj_cluster_art.py (do not edit by hand): the Aventador SVJ screen's pictures",
        "-- and where everything sits on them. Design pixels 1110 x 400; sprite rects in sheet pixels.",
        "return {",
        f"{T}W = {W}, H = {H}, A = {A},",
        f"{T}split = {lua_num(split)},",
        f'{T}bg = {{ "{ids.get("svj_bg_left", "")}", "{ids.get("svj_bg_right", "")}" }},',
        f"{T}sheets = {{ " + ", ".join(f'"{ids.get(f"svj_sprites_{n}", "")}"' for n in range(1, nsheets + 1)) + " },",
        f"{T}dial = {{ cx = {CX}, cy = {CY}, rx = {RX}, ry = {RY}, t0 = {T0}, tv = {TV} }},",
        f"{T}-- the lit rev blocks: sheet, x, y, w, h (sheet px), left, top (design px), first value",
        f"{T}blocks = {{",
    ]
    for b in blocks:
        L.append(f"{T}{T}{{ " + ", ".join(lua_num(v) for v in b) + " },")
    L += [f"{T}}},", f"{T}-- glyphs: sheet, x, y, w, h (sheet px), left of the pen, top from the middle line, advance (design px at the font size)", f"{T}fonts = {{"]
    for name, (size, gl) in fonts.items():
        L.append(f"{T}{T}{name} = {{ size = {size}, glyphs = {{")
        for ch, g in gl.items():
            L.append(f'{T}{T}{T}["{ch}"] = {{ ' + ", ".join(lua_num(v) for v in g) + " },")
        L.append(f"{T}{T}}} }},")
    L += [f"{T}}},", f"{T}words = {{"]
    for wname, g in words.items():
        L.append(f'{T}{T}["{wname}"] = {{ ' + ", ".join(lua_num(v) for v in g) + " },")
    L += [f"{T}}},", "}"]
    open(path, "w", encoding="utf-8", newline="\r\n").write("\n".join(L) + "\n")


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    c = Canvas()
    static(c)
    base = c.im.copy()
    if "--preview" in sys.argv:
        live(c)
        c.done(2).save(os.path.join(out, "svj_cluster_preview.png"))
    if "--assets" in sys.argv:
        import json

        here = os.path.dirname(os.path.abspath(__file__))
        idfile = os.path.join(here, "svj_cluster_ids.json")
        ids = json.load(open(idfile)) if os.path.exists(idfile) else {}
        split, blocks, fonts, words, n = build_assets(out, base)
        write_lua(os.path.join(here, "..", "src", "client", "SVJClusterArt.lua"), ids, split, blocks, fonts, words, n)
        print("sheets", n)
