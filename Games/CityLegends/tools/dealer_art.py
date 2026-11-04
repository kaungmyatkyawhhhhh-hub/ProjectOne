"""Icons for the City Legends dealer menu (owner-away run 2026-11-04, prompt: "real icons (drawn, not
emoji or letters)"). One sheet of white line icons, 64 px each, 8 across, tinted in the game with
ImageColor3. Drawn at 4x and shrunk (smooth edges).

    python tools/dealer_art.py build/dealer [asset id]

Writes dealer_icons.png; with the uploaded asset id it also writes src/client/DealerArt.lua.
"""

import math
import os
import sys

from PIL import Image, ImageDraw

Q = 4
CELL = 64
COLS = 8
W = (255, 255, 255, 255)
CLEAR = (0, 0, 0, 0)
LW = 5  # line width at 64 px

ICONS = [
    "exit", "back", "next", "up", "down", "lock", "check", "sound",
    "fuel", "bolt", "gearbox", "abs", "drive", "drop", "gauge", "weight",
    "power", "torque", "seat", "paint", "wheel", "tag", "key", "star",
    # (2026-11-04, the main menu)
    "trophy", "gear", "play", "map", "house", "crown", "cash", "gift",
    "garage", "blueprint", "pin", "close",
]


def P(cx, cy, pts):
    return [((cx + x) * Q, (cy + y) * Q) for x, y in pts]


def draw_icon(d, name, ox, oy):
    def line(*pts, w=LW):
        xy = P(ox, oy, pts)
        d.line(xy, fill=W, width=int(w * Q), joint="curve")
        r = w * Q / 2
        for x, y in (xy[0], xy[-1]):
            d.ellipse([x - r, y - r, x + r, y + r], fill=W)

    def poly(*pts, fill=W):
        d.polygon(P(ox, oy, pts), fill=fill)

    def circle(cx, cy, r, w=None, fill=None):
        box = [(ox + cx - r) * Q, (oy + cy - r) * Q, (ox + cx + r) * Q, (oy + cy + r) * Q]
        if fill is not None:
            d.ellipse(box, fill=fill)
        if w:
            d.ellipse(box, outline=W, width=int(w * Q))

    def arc(cx, cy, r, a0, a1, w=LW):
        box = [(ox + cx - r) * Q, (oy + cy - r) * Q, (ox + cx + r) * Q, (oy + cy + r) * Q]
        d.arc(box, a0, a1, fill=W, width=int(w * Q))

    def rrect(x0, y0, x1, y1, r, w=None, fill=None):
        box = [(ox + x0) * Q, (oy + y0) * Q, (ox + x1) * Q, (oy + y1) * Q]
        if fill is not None:
            d.rounded_rectangle(box, radius=r * Q, fill=fill)
        if w:
            d.rounded_rectangle(box, radius=r * Q, outline=W, width=int(w * Q))

    if name == "exit":
        line((34, 12), (14, 12), (14, 52), (34, 52))
        line((26, 32), (54, 32))
        line((44, 22), (54, 32), (44, 42))
    elif name == "back":
        line((38, 14), (22, 32), (38, 50), w=6)
    elif name == "next":
        line((26, 14), (42, 32), (26, 50), w=6)
    elif name == "up":
        line((14, 40), (32, 22), (50, 40), w=6)
    elif name == "down":
        line((14, 24), (32, 42), (50, 24), w=6)
    elif name == "lock":
        arc(32, 24, 11, 180, 360)
        line((21, 24), (21, 30))
        line((43, 24), (43, 30))
        rrect(13, 28, 51, 55, 6, fill=W)
        circle(32, 39, 4, fill=CLEAR)
        poly((30, 40), (34, 40), (35, 48), (29, 48), fill=CLEAR)
    elif name == "check":
        line((13, 34), (27, 47), (51, 19), w=6)
    elif name == "sound":
        poly((9, 24), (19, 24), (31, 13), (31, 51), (19, 40), (9, 40))
        arc(32, 32, 9, -45, 45)
        arc(32, 32, 18, -50, 50)
    elif name == "fuel":
        rrect(11, 11, 36, 55, 4, w=LW)
        rrect(16, 16, 31, 28, 2, fill=W)
        line((36, 22), (46, 28), (46, 44), (51, 44), (51, 18))
        line((7, 55), (40, 55))
    elif name == "bolt":
        poly((37, 5), (13, 36), (29, 36), (25, 59), (51, 26), (34, 26), (41, 5))
    elif name == "gearbox":
        for x in (16, 32, 48):
            line((x, 16), (x, 48))
        line((16, 32), (48, 32))
        for x in (16, 32, 48):
            circle(x, 14, 5, fill=W)
        for x in (16, 32):
            circle(x, 50, 5, fill=W)
    elif name == "abs":
        circle(32, 32, 21, w=LW)
        circle(32, 32, 6, fill=W)
        for k in range(5):
            a = k * 2 * math.pi / 5
            circle(32 + math.cos(a) * 13, 32 + math.sin(a) * 13, 2.2, fill=W)
        arc(32, 32, 27, -70, 10, w=7)
    elif name == "drive":
        rrect(7, 14, 18, 50, 4, fill=W)
        rrect(46, 14, 57, 50, 4, fill=W)
        line((18, 32), (46, 32))
        circle(32, 32, 7, fill=W)
    elif name == "drop":
        circle(32, 40, 16, fill=W)
        poly((32, 5), (17, 34), (47, 34))
        circle(26, 42, 4, fill=CLEAR)
    elif name == "gauge":
        arc(32, 38, 24, 150, 390)
        line((32, 38), (46, 22))
        circle(32, 38, 5, fill=W)
        for k in range(5):
            a = math.radians(150 + k * 60)
            line((32 + math.cos(a) * 17, 38 + math.sin(a) * 17), (32 + math.cos(a) * 20, 38 + math.sin(a) * 20), w=3)
    elif name == "weight":
        circle(32, 15, 8, w=LW)
        poly((15, 24), (49, 24), (57, 56), (7, 56))
    elif name == "power":
        rrect(19, 7, 45, 27, 4, fill=W)
        line((21, 13), (43, 13), w=2)
        line((32, 27), (32, 44), w=7)
        circle(32, 48, 9, w=LW)
        circle(32, 48, 2.5, fill=W)
    elif name == "torque":
        arc(32, 32, 20, 40, 320)
        a = math.radians(320)
        ex, ey = 32 + math.cos(a) * 20, 32 + math.sin(a) * 20
        poly((ex + 9, ey - 1), (ex - 5, ey - 8), (ex - 2, ey + 8))
        circle(32, 32, 5, fill=W)
    elif name == "seat":
        line((22, 9), (27, 40), w=10)
        line((28, 44), (50, 44), w=10)
        line((34, 52), (48, 52), w=4)
    elif name == "paint":
        rrect(8, 9, 46, 25, 5, fill=W)
        line((46, 17), (54, 17), (54, 32), (32, 32), (32, 40))
        rrect(27, 39, 37, 58, 3, fill=W)
    elif name == "wheel":
        circle(32, 32, 22, w=6)
        circle(32, 34, 6, fill=W)
        line((12, 32), (26, 34))
        line((52, 32), (38, 34))
        line((32, 40), (32, 53))
    elif name == "tag":
        poly((8, 32), (30, 10), (55, 10), (55, 34), (33, 56))
        circle(45, 20, 4.5, fill=CLEAR)
    elif name == "key":
        circle(19, 32, 11, w=6)
        line((30, 32), (56, 32), w=6)
        line((48, 32), (48, 42), w=5)
        line((55, 32), (55, 40), w=5)
    elif name == "star":
        pts = []
        for k in range(10):
            a = -math.pi / 2 + k * math.pi / 5
            r = 26 if k % 2 == 0 else 11
            pts.append((32 + math.cos(a) * r, 34 + math.sin(a) * r))
        poly(*pts)
    elif name == "trophy":
        poly((18, 9), (46, 9), (44, 29), (36, 38), (28, 38), (20, 29))
        arc(17, 17, 8, 90, 270, w=4)
        arc(47, 17, 8, -90, 90, w=4)
        line((32, 38), (32, 46), w=6)
        rrect(20, 46, 44, 54, 2, fill=W)
    elif name == "gear":
        for k in range(8):
            a = k * math.pi / 4
            line((32 + math.cos(a) * 18, 32 + math.sin(a) * 18), (32 + math.cos(a) * 26, 32 + math.sin(a) * 26), w=8)
        circle(32, 32, 20, fill=W)
        circle(32, 32, 9, fill=CLEAR)
    elif name == "play":
        poly((19, 10), (19, 54), (54, 32))
    elif name == "map":
        line((9, 15), (24, 9), (40, 15), (55, 9), (55, 49), (40, 55), (24, 49), (9, 55), (9, 15))
        line((24, 9), (24, 49))
        line((40, 15), (40, 55))
    elif name == "house":
        line((7, 31), (32, 9), (57, 31), w=6)
        line((14, 28), (14, 55), (50, 55), (50, 28))
        rrect(26, 36, 38, 55, 2, fill=W)
    elif name == "crown":
        poly((8, 46), (8, 17), (20, 31), (32, 11), (44, 31), (56, 17), (56, 46))
        rrect(8, 49, 56, 55, 2, fill=W)
    elif name == "cash":
        rrect(7, 17, 57, 47, 5, w=LW)
        circle(32, 32, 8, w=4)
        circle(16, 32, 2.5, fill=W)
        circle(48, 32, 2.5, fill=W)
    elif name == "gift":
        rrect(9, 23, 55, 33, 3, fill=W)
        rrect(13, 33, 51, 56, 3, w=LW)
        line((32, 23), (32, 56))
        circle(24, 16, 7, w=4)
        circle(40, 16, 7, w=4)
    elif name == "garage":
        line((7, 27), (32, 10), (57, 27), w=6)
        line((12, 25), (12, 55))
        line((52, 25), (52, 55))
        for y in (33, 41, 49):
            line((20, y), (44, y), w=4)
    elif name == "blueprint":
        rrect(9, 9, 55, 55, 4, w=LW)
        line((9, 31), (30, 31), (30, 9))
        line((30, 43), (55, 43))
        line((30, 43), (30, 55))
    elif name == "pin":
        circle(32, 25, 17, fill=W)
        poly((18, 35), (46, 35), (32, 59))
        circle(32, 25, 7, fill=CLEAR)
    elif name == "close":
        line((15, 15), (49, 49), w=6)
        line((49, 15), (15, 49), w=6)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "build/dealer"
    os.makedirs(out, exist_ok=True)
    rows = (len(ICONS) + COLS - 1) // COLS
    im = Image.new("RGBA", (COLS * CELL * Q, rows * CELL * Q), CLEAR)
    d = ImageDraw.Draw(im)
    for i, name in enumerate(ICONS):
        draw_icon(d, name, (i % COLS) * CELL, (i // COLS) * CELL)
    im = im.resize((COLS * CELL, rows * CELL), Image.LANCZOS)
    path = os.path.join(out, "dealer_icons.png")
    im.save(path)
    print("wrote", path)
    if len(sys.argv) > 2:
        asset = sys.argv[2]
        lua = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "src", "client", "DealerArt.lua")
        names = ", ".join('"%s"' % n for n in ICONS)
        with open(lua, "w", encoding="utf-8", newline="\n") as f:
            f.write("-- made by tools/dealer_art.py (do not edit by hand): the dealer menu's icon sheet\n")
            f.write("return {\n")
            f.write('\tsheet = "%s",\n' % asset)
            f.write("\tcell = %d,\n\tcols = %d,\n" % (CELL, COLS))
            f.write("\t-- the icons' order in the sheet (left to right, then down)\n")
            f.write("\ticons = { %s },\n" % names)
            f.write("}\n")
        print("wrote", lua)


if __name__ == "__main__":
    main()
