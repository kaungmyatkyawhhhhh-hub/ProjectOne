"""Art for the City Legends main menu (owner, 2026-11-02: big-tile menu, our own look): the
patterned background, the tile illustrations, the store icons and the map's venue symbols. Drawn
with shapes at 4x and shrunk (smooth edges); deep navy, warm gold, one mint accent. No logos.

    python tools/menu_art.py outdir

Writes PNGs (upload them, put the ids in tools/menu_art_ids.json) and, with --lua, the module
src/client/MenuArt.lua (ids + the venue icons' places in their sheet).
"""

import json
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

Q = 4
NAVY0 = (9, 13, 28)
NAVY = (18, 28, 58)
BLUE = (40, 74, 150)
GOLD = (255, 192, 72)
GOLD_D = (212, 138, 36)
MINT = (74, 234, 172)
WHITE = (246, 248, 255)
INK = (12, 16, 30)


def canvas(w, h, bg=(0, 0, 0, 0)):
    im = Image.new("RGBA", (w * Q, h * Q), bg)
    return im, ImageDraw.Draw(im)


def S(*v):
    return [x * Q for x in v]


def done(im, w, h):
    return im.resize((w, h), Image.LANCZOS)


def poly(d, pts, fill=None, outline=None, width=0):
    p = [(x * Q, y * Q) for x, y in pts]
    if fill:
        d.polygon(p, fill=fill)
    if outline:
        d.line(p + [p[0]], fill=outline, width=int(width * Q), joint="curve")


def line(d, pts, fill, width):
    d.line([(x * Q, y * Q) for x, y in pts], fill=fill, width=int(width * Q), joint="curve")


def circle(d, cx, cy, r, fill=None, outline=None, width=0):
    d.ellipse(S(cx - r, cy - r, cx + r, cy + r), fill=fill, outline=outline, width=int(width * Q))


def rrect(d, x0, y0, x1, y1, r, fill=None, outline=None, width=0):
    d.rounded_rectangle(S(x0, y0, x1, y1), radius=r * Q, fill=fill, outline=outline, width=int(width * Q))


def shadow(im, offset=6, blur=10, alpha=110):
    """a soft dark shadow under everything drawn so far"""
    a = im.split()[3]
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
    dark = Image.new("RGBA", im.size, (4, 6, 14, 255))
    sh.paste(dark, (0, 0), a.point(lambda v: v * alpha // 255))
    sh = sh.filter(ImageFilter.GaussianBlur(blur * Q / 2))
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.alpha_composite(sh, (offset * Q // 2, offset * Q))
    out.alpha_composite(im)
    return out


# ---- the background pattern: soft triangles, tiles seamlessly -----------------------------------
def pattern():
    W = 256
    im, d = canvas(W, W, NAVY0 + (255,))
    s = 64
    h = s * math.sqrt(3) / 2
    rows = int(W / h) + 2
    k = 0
    for r in range(-1, rows):
        for c in range(-1, W // s + 2):
            x = c * s + (s / 2 if r % 2 else 0)
            y = r * h
            k += 1
            shade = [(14, 20, 42), (16, 24, 48), (12, 18, 38), (18, 26, 52)][(r * 3 + c * 7) % 4]
            poly(d, [(x, y), (x + s, y), (x + s / 2, y + h)], fill=shade + (255,))
            poly(d, [(x + s / 2, y + h), (x + s * 1.5, y + h), (x + s, y)], fill=tuple(v + 3 for v in shade) + (255,))
    out = done(im, W, W)
    # make it seamless: mirror-free, the grid already repeats every 256 across; rows every 2h
    return out


# ---- PLAY: chevrons racing forward over a night road --------------------------------------------
def play_art():
    w, h = 640, 320
    im, d = canvas(w, h)
    # the road in perspective, with lit dashes
    poly(d, [(250, 320), (640, 320), (640, 250), (520, 150)], fill=(10, 14, 30, 150))
    for t in range(6):
        y0 = 316 - t * 30
        y1 = y0 - 14 + t * 2
        x0 = 470 + t * 9
        poly(d, [(x0, y0), (x0 + 22 - t * 2, y0), (x0 + 20 - t * 2, y1), (x0 + 3, y1)], fill=GOLD + (220 - t * 25,))
    # speed lines
    for k, (y, ln, a) in enumerate([(70, 210, 140), (110, 260, 180), (150, 190, 120), (190, 240, 160), (230, 170, 110)]):
        line(d, [(250 - ln * 0.3, y), (250 + ln * 0.55, y)], MINT + (a,), 4)
    # three chevrons, the front one big and gold-edged
    def chevron(x, y, s, fill, edge):
        pts = [(x, y - s), (x + s * 0.55, y - s), (x + s * 1.35, y), (x + s * 0.55, y + s), (x, y + s), (x + s * 0.8, y)]
        poly(d, pts, fill=fill)
        if edge:
            poly(d, pts, outline=edge, width=5)

    chevron(330, 150, 70, MINT + (120,), None)
    chevron(400, 150, 84, MINT + (190,), None)
    chevron(480, 150, 100, WHITE + (255,), GOLD + (255,))
    im = shadow(im, 8, 14, 120)
    return done(im, w, h)


# ---- ACHIEVEMENTS: a trophy, a star and medals ---------------------------------------------------
def trophy_art():
    w = h = 320
    rays, rd = canvas(w, h)
    for k in range(12):
        a = k * math.pi / 6
        poly(rd, [(160, 140), (160 + math.cos(a - 0.12) * 170, 140 + math.sin(a - 0.12) * 170), (160 + math.cos(a + 0.12) * 170, 140 + math.sin(a + 0.12) * 170)], fill=(255, 220, 140, 40))
    im, d = canvas(w, h)
    # cup
    poly(d, [(92, 60), (228, 60), (214, 150), (190, 186), (130, 186), (106, 150)], fill=GOLD + (255,))
    poly(d, [(92, 60), (128, 60), (126, 150), (130, 186), (106, 150)], fill=GOLD_D + (255,))
    rrect(d, 84, 50, 236, 70, 8, fill=(255, 214, 120, 255))
    # handles
    d.arc(S(52, 72, 112, 140), 90, 270, fill=GOLD_D + (255,), width=12 * Q)
    d.arc(S(208, 72, 268, 140), 270, 90, fill=GOLD_D + (255,), width=12 * Q)
    # stem and base
    poly(d, [(146, 186), (174, 186), (180, 226), (140, 226)], fill=GOLD_D + (255,))
    rrect(d, 108, 224, 212, 250, 6, fill=(42, 54, 96, 255))
    rrect(d, 96, 248, 224, 272, 6, fill=(30, 40, 76, 255))
    rrect(d, 132, 230, 188, 244, 4, fill=GOLD + (255,))
    # the star on the cup
    pts = []
    for k in range(10):
        a = -math.pi / 2 + k * math.pi / 5
        r = 30 if k % 2 == 0 else 13
        pts.append((160 + math.cos(a) * r, 112 + math.sin(a) * r))
    poly(d, pts, fill=WHITE + (255,))
    # shine
    poly(d, [(196, 72), (210, 72), (198, 140), (188, 140)], fill=(255, 236, 190, 255))
    # two medals
    for x, col, rib in ((64, (206, 212, 226), MINT), (258, (214, 150, 92), (120, 170, 255))):
        poly(d, [(x - 14, 196), (x - 2, 196), (x + 6, 226), (x - 8, 226)], fill=rib + (255,))
        poly(d, [(x + 2, 196), (x + 14, 196), (x + 8, 226), (x - 6, 226)], fill=rib + (200,))
        circle(d, x, 244, 22, fill=col + (255,), outline=(255, 255, 255, 160), width=3)
        circle(d, x, 244, 11, fill=tuple(int(v * 0.8) for v in col) + (255,))
    im = shadow(im, 8, 14, 120)
    rays.alpha_composite(im)
    return done(rays, w, h)


# ---- SETTINGS: a gear and sliders -----------------------------------------------------------------
def settings_art():
    w = h = 256
    im, d = canvas(w, h)
    cx, cy = 160, 108
    teeth = []
    for k in range(16):
        a = k * math.pi / 8
        r = 70 if k % 2 == 0 else 54
        a0, a1 = a - 0.17, a + 0.17
        teeth += [(cx + math.cos(a0) * r, cy + math.sin(a0) * r), (cx + math.cos(a1) * r, cy + math.sin(a1) * r)]
    poly(d, teeth, fill=WHITE + (255,))
    circle(d, cx, cy, 26, fill=(0, 0, 0, 0))
    # punch the middle out
    hole = Image.new("L", im.size, 0)
    ImageDraw.Draw(hole).ellipse(S(cx - 24, cy - 24, cx + 24, cy + 24), fill=255)
    a = im.split()[3]
    a = Image.composite(Image.new("L", im.size, 0), a, hole)
    im.putalpha(a)
    d = ImageDraw.Draw(im)
    circle(d, cx, cy, 24, outline=GOLD + (255,), width=6)
    # sliders
    for k, (y, knob) in enumerate([(184, 0.7), (212, 0.35), (240, 0.55)]):
        rrect(d, 30, y - 4, 226, y + 4, 4, fill=(255, 255, 255, 90))
        rrect(d, 30, y - 4, 30 + 196 * knob, y + 4, 4, fill=MINT + (255,))
        circle(d, 30 + 196 * knob, y, 11, fill=WHITE + (255,), outline=MINT + (255,), width=3)
    im = shadow(im, 6, 10, 110)
    return done(im, w, h)


# ---- the store's icons ---------------------------------------------------------------------------
def store_icon(kind):
    w = h = 256
    im, d = canvas(w, h)
    if kind == "vip":
        # a crown over a pass card
        rrect(d, 40, 120, 216, 220, 18, fill=(36, 48, 92, 255), outline=GOLD + (255,), width=5)
        rrect(d, 60, 186, 150, 198, 5, fill=(255, 255, 255, 120))
        poly(d, [(60, 120), (76, 52), (106, 92), (128, 36), (150, 92), (180, 52), (196, 120)], fill=GOLD + (255,))
        for x, y in ((76, 52), (128, 36), (180, 52)):
            circle(d, x, y, 10, fill=WHITE + (255,))
        rrect(d, 58, 112, 198, 128, 4, fill=GOLD_D + (255,))
        circle(d, 128, 92, 10, fill=MINT + (255,))
    elif kind == "cash2x":
        for k in range(3):
            rrect(d, 34 + k * 10, 150 - k * 22, 186 + k * 10, 210 - k * 22, 10, fill=(70, 196, 120, 255), outline=(200, 255, 220, 255), width=3)
            circle(d, 110 + k * 10, 180 - k * 22, 16, outline=(220, 255, 230, 255), width=3)
        circle(d, 190, 70, 48, fill=GOLD + (255,), outline=WHITE + (255,), width=5)
        # "2x" drawn with strokes
        line(d, [(166, 56), (174, 48), (188, 50), (188, 62), (166, 90), (192, 90)], INK + (255,), 7)
        line(d, [(198, 66), (218, 90)], INK + (255,), 7)
        line(d, [(218, 66), (198, 90)], INK + (255,), 7)
    elif kind == "starter":
        # a gift box with a car key tag
        rrect(d, 46, 110, 210, 224, 10, fill=(94, 120, 230, 255))
        rrect(d, 38, 88, 218, 120, 8, fill=(120, 146, 250, 255))
        rrect(d, 116, 88, 140, 224, 2, fill=GOLD + (255,))
        d.ellipse(S(84, 50, 126, 92), outline=GOLD + (255,), width=10 * Q)
        d.ellipse(S(130, 50, 172, 92), outline=GOLD + (255,), width=10 * Q)
        circle(d, 196, 196, 34, fill=WHITE + (255,))
        rrect(d, 182, 180, 210, 212, 6, fill=INK + (255,))
        circle(d, 196, 196, 6, fill=WHITE + (255,))
    elif kind == "bundle":
        # stacked coins and a bag
        poly(d, [(88, 96), (168, 96), (204, 200), (52, 200)], fill=(70, 196, 120, 255))
        rrect(d, 46, 190, 210, 222, 14, fill=(52, 160, 96, 255))
        rrect(d, 98, 78, 158, 100, 10, fill=(52, 160, 96, 255))
        line(d, [(116, 128), (116, 186)], (220, 255, 230, 255), 7)
        line(d, [(140, 134), (102, 134), (102, 156), (140, 156), (140, 178), (100, 178)], (220, 255, 230, 255), 7)
        for k in range(4):
            d.ellipse(S(170, 200 - k * 18, 236, 222 - k * 18), fill=GOLD + (255,), outline=GOLD_D + (255,), width=3 * Q)
    elif kind == "garage":
        poly(d, [(28, 110), (128, 42), (228, 110), (228, 226), (28, 226)], fill=(40, 56, 104, 255))
        rrect(d, 58, 120, 198, 226, 4, fill=(196, 206, 228, 255))
        for k in range(5):
            rrect(d, 62, 128 + k * 19, 194, 134 + k * 19, 2, fill=(150, 162, 190, 255))
        circle(d, 198, 70, 34, fill=MINT + (255,), outline=WHITE + (255,), width=4)
        line(d, [(198, 52), (198, 88)], INK + (255,), 8)
        line(d, [(180, 70), (216, 70)], INK + (255,), 8)
    im = shadow(im, 6, 10, 110)
    return done(im, w, h)


# ---- the map's venue symbols: white on clear, 64 px each in one sheet -----------------------------
VENUES = ["dealership", "customs", "bank", "tower", "hotel", "rewards", "gems", "realty", "home", "race", "delivery", "beach", "stadium", "palace", "harbour", "lookout"]


def venue_icon(d, kind, ox):
    """drawn in a 64x64 box at x = ox (sheet 1024 x 64)"""
    c = WHITE + (255,)

    def P(pts):
        return [(ox + x, y) for x, y in pts]

    if kind == "dealership":  # a car from the side
        poly(d, P([(8, 40), (12, 30), (24, 26), (32, 18), (46, 18), (54, 28), (58, 32), (58, 42), (8, 42)]), fill=c)
        circle(d, ox + 20, 44, 7, fill=c)
        circle(d, ox + 46, 44, 7, fill=c)
        circle(d, ox + 20, 44, 3, fill=INK + (255,))
        circle(d, ox + 46, 44, 3, fill=INK + (255,))
        poly(d, P([(28, 26), (34, 21), (44, 21), (49, 26)]), fill=INK + (255,))
    elif kind == "customs":  # a spanner
        line(d, P([(16, 48), (40, 24)]), c, 9)
        circle(d, ox + 44, 20, 12, fill=c)
        poly(d, P([(42, 10), (52, 10), (54, 22), (46, 22)]), fill=(0, 0, 0, 0))
        circle(d, ox + 46, 16, 5, fill=INK + (255,))
        circle(d, ox + 14, 50, 6, fill=c)
    elif kind == "bank":  # columns under a roof
        poly(d, P([(8, 22), (32, 8), (56, 22)]), fill=c)
        for x in (14, 26, 38, 50):
            rrect(d, ox + x - 3, 26, ox + x + 3, 46, 1, fill=c)
        rrect(d, ox + 8, 48, ox + 56, 54, 1, fill=c)
    elif kind == "tower":  # a tall tower and a short one
        rrect(d, ox + 20, 6, ox + 38, 56, 2, fill=c)
        rrect(d, ox + 40, 24, ox + 52, 56, 2, fill=c)
        for y in range(12, 52, 8):
            rrect(d, ox + 24, y, ox + 34, y + 3, 1, fill=INK + (255,))
    elif kind == "hotel":  # a bed
        rrect(d, ox + 8, 30, ox + 56, 44, 3, fill=c)
        rrect(d, ox + 8, 18, ox + 14, 52, 2, fill=c)
        rrect(d, ox + 50, 36, ox + 56, 52, 2, fill=c)
        rrect(d, ox + 16, 22, ox + 30, 30, 4, fill=c)
    elif kind == "rewards":  # a gift box with a bow (Legends Rewards, was the casino's die)
        rrect(d, ox + 10, 28, ox + 54, 54, 3, fill=c)
        rrect(d, ox + 7, 20, ox + 57, 30, 3, fill=c)
        rrect(d, ox + 29, 20, ox + 35, 54, 0, fill=INK + (255,))
        line(d, P([(7, 30), (57, 30)]), INK + (255,), 2)
        poly(d, P([(32, 20), (18, 8), (16, 18)]), fill=c)
        poly(d, P([(32, 20), (46, 8), (48, 18)]), fill=c)
    elif kind == "gems":  # a cut gem
        poly(d, P([(14, 24), (22, 12), (42, 12), (50, 24), (32, 54)]), fill=c)
        line(d, P([(14, 24), (50, 24)]), INK + (255,), 2)
        line(d, P([(26, 24), (32, 54), (38, 24)]), INK + (255,), 2)
    elif kind == "realty":  # a house with a sale tag
        poly(d, P([(6, 30), (26, 12), (46, 30)]), fill=c)
        rrect(d, ox + 12, 30, ox + 40, 52, 1, fill=c)
        rrect(d, ox + 22, 38, ox + 30, 52, 1, fill=INK + (255,))
        rrect(d, ox + 42, 34, ox + 60, 50, 3, fill=c)
        line(d, P([(48, 40), (54, 40)]), INK + (255,), 2)
        line(d, P([(48, 45), (54, 45)]), INK + (255,), 2)
    elif kind == "home":  # a house with a heart
        poly(d, P([(8, 30), (32, 10), (56, 30)]), fill=c)
        rrect(d, ox + 14, 30, ox + 50, 54, 1, fill=c)
        circle(d, ox + 28, 38, 5, fill=INK + (255,))
        circle(d, ox + 36, 38, 5, fill=INK + (255,))
        poly(d, P([(23, 40), (41, 40), (32, 49)]), fill=INK + (255,))
    elif kind == "race":  # a chequered flag
        rrect(d, ox + 12, 8, ox + 16, 58, 1, fill=c)
        for r in range(4):
            for k in range(5):
                if (r + k) % 2 == 0:
                    rrect(d, ox + 16 + k * 8, 10 + r * 7, ox + 24 + k * 8, 17 + r * 7, 0, fill=c)
        rrect(d, ox + 16, 10, ox + 56, 38, 0, outline=c, width=2)
    elif kind == "delivery":  # a parcel
        poly(d, P([(10, 22), (32, 12), (54, 22), (32, 32)]), fill=c)
        poly(d, P([(10, 24), (30, 34), (30, 56), (10, 46)]), fill=c)
        poly(d, P([(34, 34), (54, 24), (54, 46), (34, 56)]), fill=(200, 210, 230, 255))
        line(d, P([(21, 17), (43, 27)]), INK + (255,), 3)
    elif kind == "beach":  # a sunshade
        d.pieslice(S(ox + 6, 10, ox + 58, 54), 180, 360, fill=c)
        rrect(d, ox + 30, 32, ox + 34, 56, 1, fill=c)
        rrect(d, ox + 10, 54, ox + 54, 58, 2, fill=c)
    elif kind == "stadium":  # an oval stand
        d.ellipse(S(ox + 6, 16, ox + 58, 50), fill=c)
        d.ellipse(S(ox + 16, 23, ox + 48, 43), fill=INK + (255,))
        d.ellipse(S(ox + 22, 27, ox + 42, 39), fill=(110, 200, 140, 255))
    elif kind == "palace":  # a castle front
        rrect(d, ox + 10, 24, ox + 54, 54, 1, fill=c)
        for x in (10, 22, 34, 46):
            rrect(d, ox + x, 16, ox + x + 8, 24, 0, fill=c)
        d.pieslice(S(ox + 24, 36, ox + 40, 64), 180, 360, fill=INK + (255,))
        rrect(d, ox + 24, 50, ox + 40, 54, 0, fill=INK + (255,))
    elif kind == "harbour":  # an anchor
        circle(d, ox + 32, 12, 6, outline=c, width=3)
        rrect(d, ox + 30, 18, ox + 34, 52, 1, fill=c)
        rrect(d, ox + 20, 24, ox + 44, 28, 1, fill=c)
        d.arc(S(ox + 12, 28, ox + 52, 56), 0, 180, fill=c, width=4 * Q)
    elif kind == "lookout":  # mountains
        poly(d, P([(4, 54), (24, 20), (36, 38), (44, 28), (60, 54)]), fill=c)
        poly(d, P([(20, 27), (24, 20), (28, 27)]), fill=INK + (255,))


def venue_sheet():
    w, h = 1024, 64
    im, d = canvas(w, h)
    for k, kind in enumerate(VENUES):
        venue_icon(d, kind, k * 64)
    return done(im, w, h)


ART = {
    "menu_pattern": pattern,
    "menu_play": play_art,
    "menu_trophy": trophy_art,
    "menu_settings": settings_art,
    "store_vip": lambda: store_icon("vip"),
    "store_cash2x": lambda: store_icon("cash2x"),
    "store_starter": lambda: store_icon("starter"),
    "store_bundle": lambda: store_icon("bundle"),
    "store_garage": lambda: store_icon("garage"),
    "menu_venues": venue_sheet,
}


def write_lua(path, ids):
    T = "\t"
    L = [
        "-- made by tools/menu_art.py (do not edit by hand): the main menu's pictures",
        "return {",
    ]
    for k in ART:
        L.append(f'{T}{k} = "{ids.get(k, "")}",')
    L.append(f"{T}-- the venue symbols' order in menu_venues (64 px each, left to right)")
    L.append(f"{T}venues = {{ " + ", ".join(f'"{v}"' for v in VENUES) + " },")
    L.append("}")
    open(path, "w", encoding="utf-8", newline="\r\n").write("\n".join(L) + "\n")


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for name, fn in ART.items():
        fn().save(os.path.join(out, name + ".png"))
    here = os.path.dirname(os.path.abspath(__file__))
    idf = os.path.join(here, "menu_art_ids.json")
    ids = json.load(open(idf)) if os.path.exists(idf) else {}
    write_lua(os.path.join(here, "..", "src", "client", "MenuArt.lua"), ids)
    # a contact sheet to look at
    names = list(ART)
    sheet = Image.new("RGBA", (1100, 760), (30, 40, 70, 255))
    x = y = 10
    rowh = 0
    for n in names:
        im = Image.open(os.path.join(out, n + ".png"))
        if im.width > 640:
            im = im.resize((im.width // 1, im.height))
        if x + im.width > 1100:
            x, y = 10, y + rowh + 10
            rowh = 0
        sheet.alpha_composite(im, (x, y))
        x += im.width + 10
        rowh = max(rowh, im.height)
    sheet.save(os.path.join(out, "_sheet.png"))
    print("ok")
