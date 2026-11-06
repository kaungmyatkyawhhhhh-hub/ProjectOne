"""The Countach's two big dials redrawn sharp (owner, 2026-11-06: "make the RPM and speed numbers much more
visible and sharper"): the model's picture gives each dial about 110 px. Same layout as the model: speed 0-320
km/h round the outside, the mph ring inside it, the odometer and trip windows; revs 0-90 x 100 with the yellow and
red blocks. Clear white numbers and marks on black, drawn at 800 px. No needle: the game turns one over them. No
logos: the shield at the bottom of each dial is gone.
Angles are the ones the needle uses (degrees clockwise from 12, CarSkin.DIAL_NEEDLES).

    python tools/lambo/countach_art.py outdir
"""

import math
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cluster_art import ARIAL, ARIAL_B, font  # noqa: E402

S = 800
Q = 3
R = S * Q / 2
WHITE = (246, 246, 244)
FACE = (10, 10, 11)
YEL = (242, 196, 24)
RED = (206, 34, 36)
KMH = [(0, -135), (320, 135)]
RPM = [(0, -114), (10, -90), (20, -61), (30, -35.5), (40, -14), (50, 10.4), (60, 34), (70, 58), (80, 90), (90, 118)]


def angle(table, v):
    for (v0, a0), (v1, a1) in zip(table, table[1:]):
        if v <= v1:
            return a0 + (a1 - a0) * (v - v0) / (v1 - v0)
    return table[-1][1]


def pol(a, r):
    t = math.radians(a)
    return R + r * R * math.sin(t), R - r * R * math.cos(t)


def stroke(d, a, r0, r1, w, col=WHITE):
    d.line([pol(a, r0), pol(a, r1)], fill=col, width=round(w * Q))


def base():
    im = Image.new("RGBA", (S * Q, S * Q), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([2 * Q, 2 * Q, S * Q - 2 * Q, S * Q - 2 * Q], fill=FACE + (255,))
    d.ellipse([6 * Q, 6 * Q, S * Q - 6 * Q, S * Q - 6 * Q], outline=(58, 58, 60, 255), width=3 * Q)
    return im, d


def text(d, x, y, s, size, col=WHITE, path=ARIAL_B, stroke_w=0.0):
    d.text((x, y), s, font=font(path, size * Q), fill=col, anchor="mm", stroke_width=round(stroke_w * Q), stroke_fill=col)


def speed():
    im, d = base()
    for v in range(0, 321, 5):
        a = angle(KMH, v)
        if v % 20 == 0:
            stroke(d, a, 0.88, 0.98, 7)
        elif v % 10 == 0:
            stroke(d, a, 0.91, 0.98, 4)
        else:
            stroke(d, a, 0.94, 0.98, 2.6)
    for v in range(0, 321, 20):
        x, y = pol(angle(KMH, v), 0.775)
        text(d, x, y, str(v), 50, stroke_w=0.4)
    # the mph ring: two arcs and its marks
    a0, a1 = -135, 135
    for r in (0.635, 0.54):
        d.arc([R - r * R, R - r * R, R + r * R, R + r * R], a0 - 90, a1 - 90, fill=WHITE, width=round(5 * Q))
    for m in range(0, 201, 20):
        a = a0 + (a1 - a0) * m / 200
        stroke(d, a, 0.54, 0.635, 6)
        x, y = pol(a, 0.455)
        text(d, x, y, str(m), 26)
    # odometer and trip windows
    for box, digits, last in (((R - 125 * Q, R - 132 * Q, R + 125 * Q, R - 84 * Q), "024888", None), ((R - 82 * Q, R + 92 * Q, R + 82 * Q, R + 136 * Q), "2736", 3)):
        d.rounded_rectangle(box, radius=6 * Q, fill=(24, 24, 26, 255), outline=(70, 70, 72, 255), width=2 * Q)
        n = len(digits)
        w = (box[2] - box[0]) / n
        for i, c in enumerate(digits):
            x = box[0] + w * (i + 0.5)
            hot = last is not None and i == last
            if i:
                d.line([(box[0] + w * i, box[1] + 3 * Q), (box[0] + w * i, box[3] - 3 * Q)], fill=(60, 60, 62, 255), width=2 * Q)
            text(d, x, (box[1] + box[3]) / 2, c, 32, YEL if hot else WHITE)
    text(d, R + 170 * Q, R + 268 * Q, "mph", 24, (214, 214, 212), ARIAL)
    text(d, R + 170 * Q, R + 296 * Q, "km/h", 24, (214, 214, 212), ARIAL)
    return im


def rpm():
    im, d = base()
    # the yellow and red blocks
    for v0, v1, col in ((67.5, 74.5, YEL), (74.5, 91, RED)):
        pts = []
        for k in range(0, 21):
            pts.append(pol(angle(RPM, v0 + (v1 - v0) * k / 20), 0.97))
        for k in range(20, -1, -1):
            pts.append(pol(angle(RPM, v0 + (v1 - v0) * k / 20), 0.79))
        d.polygon(pts, fill=col + (255,))
    stroke(d, angle(RPM, 80), 0.79, 0.97, 7, (236, 236, 232))
    # the old rev limit's stripes, just under the yellow
    for k in range(0, 5):
        v = 61.5 + k * 1.2
        stroke(d, angle(RPM, v), 0.8, 0.95, 3.5)
    for v in range(0, 91, 5):
        a = angle(RPM, v)
        if v % 10 == 0:
            if v < 70:
                stroke(d, a, 0.79, 0.97, 9)
        elif v < 60:
            stroke(d, a, 0.86, 0.97, 4.5)
    for v in range(0, 91, 10):
        x, y = pol(angle(RPM, v), 0.60)
        text(d, x, y, str(v), 74, stroke_w=0.6)
    text(d, R, R - 0.17 * R, "ELETTRONICO", 40, (232, 232, 230), ARIAL_B)
    text(d, R, R + 0.64 * R, "Giri x 100", 38, (222, 222, 220), ARIAL)
    return im


def main():
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for name, fn in (("countach_speed", speed), ("countach_rpm", rpm)):
        fn().resize((S, S), Image.LANCZOS).save(os.path.join(out, name + ".png"))
        print(name)


if __name__ == "__main__":
    main()
