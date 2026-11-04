"""The Gallardo's two big dials redrawn sharp (owner, 2026-11-04: "numbers is blurry and I cant see the rpm
numbers properly"): the model's picture gives each dial 380 px and thin orange numbers on white. Same layout
as the model, numbers bigger and darker, drawn at 800 px. No needle: the game turns one over them.
Angles are the ones the needle uses (degrees clockwise from 12, CarSkin.DIAL_NEEDLES).

    python tools/lambo/gallardo_art.py outdir
"""

import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cluster_art import ARIAL_B, TECH, font  # noqa: E402

S = 800  # final size
Q = 3
R = S * Q / 2
RPM = [(0, -129.7), (1, -103.2), (2, -76.6), (3, -52.1), (4, -27.5), (5, -3.6), (6, 20.6), (7, 46.0), (8, 73.2), (9, 99.5), (10, 125.4)]
KMH = [(0, -130.0), (40, -99.8), (70, -77.1), (100, -53.8), (130, -30.5), (160, -9.0), (190, 12.5), (220, 33.5), (250, 56.3), (280, 78.9), (310, 102.3), (340, 125.2)]
ORANGE = (214, 92, 0)
EDGE = (92, 44, 6)
RED = (206, 22, 34)
FACE = (240, 238, 232)


def angle(table, v):
    for (v0, a0), (v1, a1) in zip(table, table[1:]):
        if v <= v1:
            return a0 + (a1 - a0) * (v - v0) / (v1 - v0)
    return table[-1][1]


def pol(a, r):
    t = math.radians(a)
    return R + r * R * math.sin(t), R - r * R * math.cos(t)


def stroke(d, a0, a1, r0, r1, col, w):
    d.line([pol(a0, r0), pol(a1, r1)], fill=col, width=round(w * Q))


def num(im, text, at, size, col):
    f = font(TECH, size * Q)
    d = ImageDraw.Draw(im)
    x, y = at
    d.text((x, y), text, font=f, fill=col, anchor="mm", stroke_width=round(1.2 * Q), stroke_fill=EDGE if col == ORANGE else (96, 8, 16))


def lcd(im, box, lines):
    x0, y0, x1, y1 = [v * Q for v in box]
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([x0, y0, x1, y1], radius=12 * Q, fill=(150, 18, 22), outline=(96, 10, 14), width=3 * Q)
    for text, x, y, size in lines:
        d.text((x0 + x * Q, y0 + y * Q), text, font=font(TECH, size * Q), fill=(255, 186, 110), anchor="rm")


def base():
    im = Image.new("RGBA", (S * Q, S * Q), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([2 * Q, 2 * Q, S * Q - 2 * Q, S * Q - 2 * Q], fill=FACE + (255,))
    return im


def scale(im, table, top, majors, minors):
    d = ImageDraw.Draw(im)
    pts = [pol(angle(table, table[-1][0] * i / 240), 0.9) for i in range(0, 241)]
    d.line(pts, fill=ORANGE, width=round(5 * Q), joint="curve")
    for v in minors:
        a = angle(table, v)
        stroke(d, a, a, 0.865, 0.935, ORANGE, 3.4)
    for v in majors:
        a = angle(table, v)
        stroke(d, a, a, 0.83, 0.955, ORANGE, 7)


def rpm():
    im = base()
    d = ImageDraw.Draw(im)
    scale(im, RPM, 10, range(0, 11), [v / 5 for v in range(1, 50) if v % 5])
    for k in range(0, 9):  # the red zone, blocks past 8,500
        v0, v1 = 8.5 + k * 0.17, 8.5 + (k + 0.72) * 0.17
        pts = [pol(angle(RPM, v0), 0.875), pol(angle(RPM, v1), 0.875), pol(angle(RPM, v1), 0.975), pol(angle(RPM, v0), 0.975)]
        d.polygon(pts, fill=RED)
    for v in range(1, 11):
        a = angle(RPM, v)
        num(im, str(v), pol(a, 0.66), 92 if v < 10 else 86, RED if v >= 9 else ORANGE)
    d.text((R, R - 0.42 * R), "giri x1000", font=font(ARIAL_B, 27 * Q), fill=(70, 70, 74), anchor="mm")
    lcd(im, (262, 590, 538, 690), [("5.24.2010", 262, 32, 36), ("9:28", 262, 72, 44)])
    return im


def kmh():
    im = base()
    d = ImageDraw.Draw(im)
    scale(im, KMH, 340, [v for v, _ in KMH] + [20], [v for v in range(10, 340, 10) if v % 30 != 10 or v in (20,)])
    for v in [20, 40, 70, 100, 130, 160, 190, 220, 250, 280, 310, 340]:
        a = angle(KMH, v)
        num(im, str(v), pol(a, 0.69), 50, ORANGE)
    d.text((R, R - 0.42 * R), "km/h", font=font(ARIAL_B, 27 * Q), fill=(70, 70, 74), anchor="mm")
    lcd(im, (262, 590, 538, 690), [("0", 262, 32, 36), ("0.0", 262, 72, 44)])
    return im


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for name, fn in (("gallardo_rpm", rpm), ("gallardo_kmh", kmh)):
        im = fn().resize((S, S), Image.LANCZOS)
        im.save(os.path.join(out, name + ".png"))
    print("ok")
