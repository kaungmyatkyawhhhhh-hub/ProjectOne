"""SPEED ARC UI art kit (prompt 12).

Draws every UI sprite as a PNG (9-slice where it stretches) into Games/SpeedArc/ui_kit/,
writes ui_kit/kit.json (SliceCenter + SliceScale per sprite) and builds the 667x375 mockups
(HUD, Store, the kit sheet) into SPEED ARC/Screenshots/ui_kit/ from those same sprites.

Run: python tools/make_ui_kit.py
Style: thick navy outline, 3D bottom lip, inner top highlight, soft shadow, rounded corners,
Montserrat Black Italic with a navy stroke. Sporty palette only (no pink / purple / pastels).
"""
import json
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.dirname(HERE)
VAULT = os.path.dirname(os.path.dirname(GAME))
OUT_SPR = os.path.join(GAME, "ui_kit")
OUT_MOCK = os.path.join(VAULT, "SPEED ARC", "Screenshots", "ui_kit")
SHOTS = os.path.join(VAULT, "SPEED ARC", "Screenshots")
FONT_I = os.path.join(HERE, "fonts", "Montserrat-Italic.ttf")
FONT_U = os.path.join(HERE, "fonts", "Montserrat.ttf")
SS = 4  # supersampling while drawing

OUTLINE = "#0A1433"
NAVY = "#0F1E4A"

# name: (face base, face light, lip / edge, text colour)
BUTTONS = {
    "green": ("#3FCB2B", "#8BF26A", "#22861A", "#FFFFFF"),  # buy / go / equip
    "blue": ("#1E90FF", "#6CC0FF", "#1659C7", "#FFFFFF"),  # normal
    "yellow": ("#FFD21F", "#FFF07A", "#E09600", NAVY),  # claim / reward
    "red": ("#FF3B3B", "#FF8A7A", "#B81F1F", "#FFFFFF"),  # close / stop
    "grey": ("#8C97AD", "#C3CBDA", "#5B6478", "#FFFFFF"),  # locked
    "navy": ("#2C4499", "#4A68CF", "#17296B", "#FFFFFF"),  # tab off / small HUD buttons
}
TILES = {"blue": "#1E90FF", "lime": "#6BE33B", "orange": "#FF7A1A", "gold": "#FFB300", "red": "#FF3B3B", "cyan": "#1EC8FF", "grey": "#8C97AD"}


def rgba(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def mix(a, b, t):
    a, b = rgba(a) if isinstance(a, str) else a, rgba(b) if isinstance(b, str) else b
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(4))


def S(*v):
    return [x * SS for x in v]


def mask(size, draw_fn):
    m = Image.new("L", size, 0)
    draw_fn(ImageDraw.Draw(m))
    return m


def rr(size, box, r):
    return mask(size, lambda d: d.rounded_rectangle(S(*box), r * SS, fill=255))


def grad(size, box, top, bottom):
    """A full-size RGBA layer with a vertical gradient inside box (1x coords)."""
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    x0, y0, x1, y1 = S(*box)
    h = max(1, int(y1 - y0))
    col = Image.new("RGBA", (1, h))
    top, bottom = rgba(top) if isinstance(top, str) else top, rgba(bottom) if isinstance(bottom, str) else bottom
    for y in range(h):
        col.putpixel((0, y), mix(top, bottom, y / max(1, h - 1)))
    layer.paste(col.resize((max(1, int(x1 - x0)), h)), (int(x0), int(y0)))
    return layer


def paint(img, m, fill):
    layer = Image.new("RGBA", img.size, rgba(fill) if isinstance(fill, str) else fill) if not isinstance(fill, Image.Image) else fill.copy()
    layer.putalpha(ImageChops.multiply(layer.getchannel("A"), m))
    img.alpha_composite(layer)


def dilate(m, r):
    return m.filter(ImageFilter.GaussianBlur(r * SS * 0.55)).point(lambda v: 255 if v > 24 else 0).filter(ImageFilter.GaussianBlur(SS * 0.6))


def shrink(img, size):
    return img.resize(size, Image.LANCZOS)


# ---------------------------------------------------------------- sprites
def button(style, pressed=False):
    base, light, edge, _ = BUTTONS[style]
    if pressed:
        base, light = mix(base, edge, 0.18), mix(light, edge, 0.2)
    W, H = 160, 112
    size = (W * SS, H * SS)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    paint(img, rr(size, (6, 14, W - 6, H - 2), 30).filter(ImageFilter.GaussianBlur(4 * SS)), rgba(OUTLINE, 120))  # soft shadow
    top = 10 if pressed else 2
    lip = 4 if pressed else 12
    paint(img, rr(size, (4, top, W - 4, H - 8), 30), OUTLINE)  # thick navy outline
    paint(img, rr(size, (10, top + 6, W - 10, H - 14), 24), edge)  # the 3D lip
    face = (10, top + 6, W - 10, H - 14 - lip)
    fm = rr(size, face, 24)
    paint(img, fm, grad(size, face, light, base))
    # bottom of the face a touch darker, then the glossy top highlight
    fy = face[3] - face[1]
    paint(img, ImageChops.multiply(fm, rr(size, (face[0], face[1] + fy * 0.62, face[2], face[3]), 24)), grad(size, (face[0], face[1] + fy * 0.62, face[2], face[3]), mix(edge, edge, 0)[:3] + (0,), mix(edge, edge, 0)[:3] + (70,)))
    hl = (face[0] + 8, face[1] + 4, face[2] - 8, face[1] + fy * 0.42)
    paint(img, ImageChops.multiply(fm, rr(size, hl, 16)), grad(size, hl, (255, 255, 255, 150), (255, 255, 255, 25)))
    return shrink(img, (W, H))


def panel():
    W = H = 192
    size = (W * SS, H * SS)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    paint(img, rr(size, (6, 12, W - 6, H - 2), 40).filter(ImageFilter.GaussianBlur(5 * SS)), rgba(OUTLINE, 140))
    paint(img, rr(size, (4, 4, W - 4, H - 8), 40), OUTLINE)
    paint(img, rr(size, (10, 10, W - 10, H - 14), 34), grad(size, (10, 10, W - 10, H - 14), "#4A6BD6", "#1F358A"))  # bright rim
    inner = (16, 16, W - 16, H - 20)
    im = rr(size, inner, 28)
    paint(img, im, grad(size, inner, "#213A8C", "#0F1F57"))
    hl = (inner[0] + 6, inner[1] + 3, inner[2] - 6, inner[1] + 26)
    paint(img, ImageChops.multiply(im, rr(size, hl, 22)), grad(size, hl, (255, 255, 255, 40), (255, 255, 255, 0)))
    return shrink(img, (W, H))


def tile(colour):
    W, H = 160, 200
    size = (W * SS, H * SS)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    paint(img, rr(size, (5, 10, W - 5, H - 1), 26).filter(ImageFilter.GaussianBlur(4 * SS)), rgba(OUTLINE, 120))
    paint(img, rr(size, (3, 3, W - 3, H - 6), 26), OUTLINE)
    paint(img, rr(size, (8, 8, W - 8, H - 11), 21), grad(size, (8, 8, W - 8, H - 11), mix(colour, "#FFFFFF", 0.35), mix(colour, OUTLINE, 0.25)))  # colour rim
    inner = (13, 13, W - 13, H - 16)
    im = rr(size, inner, 16)
    paint(img, im, grad(size, inner, "#1D3378", "#0E1C4C"))
    # the colour glow rising from the bottom (like the coach tiles)
    glow = mask(size, lambda d: d.ellipse(S(-10, 80, W + 10, H + 70), fill=255)).filter(ImageFilter.GaussianBlur(22 * SS))
    paint(img, ImageChops.multiply(im, glow), rgba(colour, 200))
    hl = (inner[0] + 5, inner[1] + 3, inner[2] - 5, inner[1] + 30)
    paint(img, ImageChops.multiply(im, rr(size, hl, 14)), grad(size, hl, (255, 255, 255, 45), (255, 255, 255, 0)))
    return shrink(img, (W, H))


def pill(fill_top, fill_bottom, rim):
    W, H = 96, 48
    size = (W * SS, H * SS)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    paint(img, rr(size, (1, 1, W - 1, H - 1), 23), OUTLINE)
    paint(img, rr(size, (4, 4, W - 4, H - 4), 20), rim)
    inner = (6, 6, W - 6, H - 6)
    im = rr(size, inner, 18)
    paint(img, im, grad(size, inner, fill_top, fill_bottom))
    hl = (inner[0] + 6, inner[1] + 2, inner[2] - 6, inner[1] + 14)
    paint(img, ImageChops.multiply(im, rr(size, hl, 8)), grad(size, hl, (255, 255, 255, 70), (255, 255, 255, 0)))
    return shrink(img, (W, H))


def bar(fill=None):
    W, H = 96, 32
    size = (W * SS, H * SS)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    if fill is None:
        paint(img, rr(size, (0, 0, W, H), 16), OUTLINE)
        paint(img, rr(size, (4, 4, W - 4, H - 4), 12), grad(size, (4, 4, W - 4, H - 4), "#070F2B", "#16296A"))
    else:
        m = rr(size, (4, 4, W - 4, H - 4), 12)
        paint(img, m, grad(size, (4, 4, W - 4, H - 4), mix(fill, "#FFFFFF", 0.45), fill))
        paint(img, ImageChops.multiply(m, rr(size, (10, 6, W - 10, 13), 4)), (255, 255, 255, 110))
    return shrink(img, (W, H))


def badge(colour):
    W = H = 64
    size = (W * SS, H * SS)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    paint(img, mask(size, lambda d: d.ellipse(S(2, 2, 62, 62), fill=255)), OUTLINE)
    paint(img, mask(size, lambda d: d.ellipse(S(7, 7, 57, 57), fill=255)), "#FFFFFF")
    m = mask(size, lambda d: d.ellipse(S(12, 12, 52, 52), fill=255))
    paint(img, m, grad(size, (12, 12, 52, 52), mix(colour, "#FFFFFF", 0.35), colour))
    paint(img, ImageChops.multiply(m, mask(size, lambda d: d.ellipse(S(18, 14, 46, 30), fill=255))), (255, 255, 255, 90))
    return shrink(img, (W, H))


# ---------------------------------------------------------------- icons (128 x 128, navy outline)
def icon(parts, details=None, outline=7):
    """parts: list of (draw_fn(d) in 1x coords via S, colour). details: fn(d) drawn on top."""
    size = (128 * SS, 128 * SS)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    masks = [(mask(size, fn), c) for fn, c in parts]
    union = Image.new("L", size, 0)
    for m, _ in masks:
        union = ImageChops.lighter(union, m)
    out = dilate(union, outline)
    paint(img, ImageChops.offset(out, 0, 5 * SS).filter(ImageFilter.GaussianBlur(3 * SS)), rgba(OUTLINE, 130))
    paint(img, out, OUTLINE)
    for m, c in masks:
        bb = m.getbbox() or (0, 0, 1, 1)
        box = (bb[0] / SS, bb[1] / SS, bb[2] / SS, bb[3] / SS)
        paint(img, m, grad(size, box, mix(c, "#FFFFFF", 0.38), mix(c, OUTLINE, 0.12)))
    if details:
        details(ImageDraw.Draw(img))
    gloss = mask(size, lambda d: d.ellipse(S(-20, -40, 110, 58), fill=255)).filter(ImageFilter.GaussianBlur(6 * SS))
    paint(img, ImageChops.multiply(union, gloss), (255, 255, 255, 60))
    return shrink(img, (128, 128))


def poly(pts):
    return lambda d: d.polygon([tuple(S(x, y)) for x, y in pts], fill=255)


def ell(x0, y0, x1, y1):
    return lambda d: d.ellipse(S(x0, y0, x1, y1), fill=255)


def rect(x0, y0, x1, y1, r=0):
    return lambda d: d.rounded_rectangle(S(x0, y0, x1, y1), r * SS, fill=255)


def line(pts, w):
    def fn(d):
        d.line([tuple(S(x, y)) for x, y in pts], fill=255, width=w * SS, joint="curve")
        for x, y in (pts[0], pts[-1]):
            d.ellipse(S(x - w / 2, y - w / 2, x + w / 2, y + w / 2), fill=255)
    return fn


def ring(x0, y0, x1, y1, w):
    return lambda d: d.ellipse(S(x0, y0, x1, y1), outline=255, width=w * SS)


N = rgba(NAVY)


def ICONS():
    W, GOLD, LIME, BLUE, RED, ORANGE, ROYAL = "#FFFFFF", "#FFD21F", "#6BE33B", "#1E90FF", "#FF3B3B", "#FF7A1A", "#2152D9"

    def d_store(d):
        for x in (54, 72, 90):
            d.line([tuple(S(x, 50)), tuple(S(x - 3, 76))], fill=rgba("#E09600"), width=5 * SS)

    def d_shoe(d):
        d.line([tuple(S(*p)) for p in ((34, 78), (60, 70), (98, 78))], fill=rgba(ROYAL), width=8 * SS, joint="curve")
        for x in (40, 50, 60):
            d.ellipse(S(x - 3, 56 - (x - 40) * 0.2 - 3, x + 3, 56 - (x - 40) * 0.2 + 3), fill=N)

    def d_whistle(d):
        d.ellipse(S(44, 62, 64, 82), fill=N)

    def d_ticket(d):
        for cx in (12, 116):  # the bites out of the sides
            d.ellipse(S(cx - 10, 55, cx + 10, 75), fill=rgba(OUTLINE))
        for y in range(44, 88, 10):
            d.rounded_rectangle(S(40, y, 45, y + 6), 2 * SS, fill=rgba("#2A8A18"))
        d.polygon([tuple(S(x, y)) for x, y in ((80, 48), (84, 60), (96, 60), (86, 67), (90, 80), (80, 72), (70, 80), (74, 67), (64, 60), (76, 60))], fill=rgba("#FFFFFF"))

    def d_cal(d):
        for i in range(3):
            for j in range(2):
                d.rounded_rectangle(S(32 + i * 24, 66 + j * 18, 48 + i * 24, 78 + j * 18), 3 * SS, fill=rgba("#9FB3D6"))
        d.rounded_rectangle(S(80, 84, 96, 96), 3 * SS, fill=rgba(RED))

    def d_quest(d):
        d.line([tuple(S(*p)) for p in ((44, 72), (58, 86), (86, 54))], fill=rgba("#2FB51E"), width=12 * SS, joint="curve")

    def d_trophy(d):
        d.polygon([tuple(S(x, y)) for x, y in ((64, 28), (69, 40), (82, 40), (72, 48), (76, 60), (64, 53), (52, 60), (56, 48), (46, 40), (59, 40))], fill=rgba("#FFF4B8"))

    def d_gear(d):
        d.ellipse(S(50, 50, 78, 78), fill=N)

    def d_coin(d):
        d.ellipse(S(28, 28, 100, 100), outline=rgba("#E09600"), width=6 * SS)
        for x in (52, 70):
            d.line([tuple(S(x + 6, 46)), tuple(S(x - 6, 82))], fill=rgba("#FFFFFF"), width=8 * SS)

    def d_crown(d):
        for x, c in ((42, RED), (64, BLUE), (86, LIME)):
            d.ellipse(S(x - 6, 91, x + 6, 103), fill=rgba(c))

    def d_flag(d):
        for i in range(5):
            for j in range(3):
                if (i + j) % 2 == 0:
                    d.rectangle(S(34 + i * 15, 22 + j * 15, 49 + i * 15, 37 + j * 15), fill=N)

    gear_teeth = []
    import math
    for k in range(8):
        a = k * math.pi / 4
        cx, cy = 64 + math.cos(a) * 44, 64 + math.sin(a) * 44
        gear_teeth.append(line([(64 + math.cos(a) * 30, 64 + math.sin(a) * 30), (cx, cy)], 18))

    return {
        "store": icon([(poly([(28, 40), (114, 40), (102, 84), (40, 84)]), GOLD), (line([(8, 24), (24, 24), (40, 94), (102, 94)], 10), W), (ell(34, 96, 56, 118), W), (ell(84, 96, 106, 118), W)], d_store),
        "locker": icon([(poly([(14, 86), (18, 48), (44, 40), (60, 58), (88, 64), (110, 72), (116, 88)]), W), (rect(10, 82, 120, 102, 9), BLUE)], d_shoe),
        "coaches": icon([(ell(26, 44, 82, 100), GOLD), (rect(50, 44, 116, 66, 8), GOLD), (ring(12, 14, 44, 46, 8), W)], d_whistle),
        "codes": icon([(rect(12, 38, 116, 92, 12), LIME)], d_ticket),
        "invite": icon([(ell(30, 18, 72, 60), W), (rect(16, 62, 86, 112, 26), W), (rect(88, 46, 106, 96, 5), LIME), (rect(72, 62, 122, 80, 5), LIME)]),
        "daily": icon([(rect(16, 28, 112, 110, 14), W), (rect(16, 28, 112, 58, 14), RED), (rect(36, 14, 48, 40, 6), W), (rect(80, 14, 92, 40, 6), W)], d_cal),
        "quests": icon([(rect(22, 20, 106, 116, 12), BLUE), (rect(32, 34, 96, 106, 6), W), (rect(46, 12, 82, 32, 8), GOLD)], d_quest),
        "top": icon([(lambda d: d.pieslice(S(30, -12, 98, 80), 0, 180, fill=255), GOLD), (rect(30, 16, 98, 34), GOLD), (ring(12, 20, 46, 58, 8), GOLD), (ring(82, 20, 116, 58, 8), GOLD), (rect(56, 76, 72, 96), GOLD), (rect(34, 94, 94, 114, 6), "#FFB300")], d_trophy),
        "settings": icon([(ell(28, 28, 100, 100), "#DDE6F5")] + [(t, "#DDE6F5") for t in gear_teeth], d_gear),
        "close": icon([(line([(34, 34), (94, 94)], 24), W), (line([(94, 34), (34, 94)], 24), W)]),
        "coin": icon([(ell(16, 16, 112, 112), GOLD)], d_coin, outline=6),
        "speed": icon([(poly([(72, 8), (26, 72), (58, 72), (46, 120), (102, 50), (68, 50), (84, 8)]), GOLD)]),
        "crown": icon([(poly([(16, 94), (12, 36), (40, 60), (64, 22), (88, 60), (116, 36), (112, 94)]), GOLD), (rect(16, 86, 112, 108, 6), "#FFB300")], d_crown),
        "race": icon([(rect(18, 12, 30, 118, 5), W), (rect(30, 18, 112, 70, 4), W)], d_flag),
        "shoe2x": icon([(poly([(14, 86), (18, 48), (44, 40), (60, 58), (88, 64), (110, 72), (116, 88)]), W), (rect(10, 82, 120, 102, 9), LIME)], d_shoe),
    }


# ---------------------------------------------------------------- build sprites + kit.json
def build():
    os.makedirs(OUT_SPR, exist_ok=True)
    kit = {}

    def save(name, img, rect=None, scale=None, note=""):
        img.save(os.path.join(OUT_SPR, name + ".png"))
        kit[name] = {"size": list(img.size), "slice": rect, "sliceScale": scale, "use": note}
        return img

    spr = {}
    for st in BUTTONS:
        spr["btn_" + st] = save("btn_" + st, button(st), [40, 40, 120, 72], 0.33, "button " + st)
        spr["btn_" + st + "_down"] = save("btn_" + st + "_down", button(st, True), [40, 40, 120, 72], 0.33, "button " + st + " pressed")
    spr["panel"] = save("panel", panel(), [56, 56, 136, 136], 0.33, "every window")
    for c, h in TILES.items():
        spr["tile_" + c] = save("tile_" + c, tile(h), [40, 40, 120, 160], 0.33, "store / locker / quest / coach tile")
    spr["pill_navy"] = save("pill_navy", pill("#24409A", "#14276A", "#3B5CC8"), [24, 20, 72, 28], "auto", "counters, HUD plates (SliceScale = height / 48)")
    spr["pill_red"] = save("pill_red", pill("#FF7A7A", "#E02828", "#FFB0A8"), [24, 20, 72, 28], "auto", "LIVE, warnings")
    spr["pill_lime"] = save("pill_lime", pill("#9BF27A", "#3FB52B", "#C8FFB0"), [24, 20, 72, 28], "auto", "status: equipped, new")
    spr["bar_track"] = save("bar_track", bar(), [16, 15, 80, 17], "auto", "progress track")
    spr["bar_blue"] = save("bar_blue", bar("#1E90FF"), [16, 15, 80, 17], "auto", "progress fill")
    spr["bar_gold"] = save("bar_gold", bar("#FFB300"), [16, 15, 80, 17], "auto", "progress fill (rewards)")
    spr["badge_red"] = save("badge_red", badge("#FF3B3B"), None, None, "notification dot")
    spr["badge_bronze"] = save("badge_bronze", badge("#D9822B"), None, None, "rank badge")
    for k, v in ICONS().items():
        spr["icon_" + k] = save("icon_" + k, v, None, None, "icon")
    with open(os.path.join(OUT_SPR, "kit.json"), "w") as f:
        json.dump(kit, f, indent=1)
    return spr


# ---------------------------------------------------------------- mockups
K = 2  # mockups are drawn at 2x (1334 x 750) then saved at 667 x 375 too


def font(size, italic=True, weight=900):
    f = ImageFont.truetype(FONT_I if italic else FONT_U, int(size * K))
    f.set_variation_by_axes([weight])
    return f


def nine(img, rect, w, h, scale):
    W, H = img.size
    if rect is None:
        return img.resize((w, h), Image.LANCZOS)
    l, t, r, b = rect
    L2, T2, R2, B2 = [max(1, int(round(v * scale))) for v in (l, t, W - r, H - b)]
    if L2 + R2 > w:
        f = w / (L2 + R2)
        L2 = int(L2 * f)
        R2 = w - L2
    if T2 + B2 > h:
        f = h / (T2 + B2)
        T2 = int(T2 * f)
        B2 = h - T2
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for sx0, sx1, dx0, dx1 in ((0, l, 0, L2), (l, r, L2, w - R2), (r, W, w - R2, w)):
        for sy0, sy1, dy0, dy1 in ((0, t, 0, T2), (t, b, T2, h - B2), (b, H, h - B2, h)):
            if dx1 > dx0 and dy1 > dy0:
                out.paste(img.crop((sx0, sy0, sx1, sy1)).resize((dx1 - dx0, dy1 - dy0), Image.LANCZOS), (dx0, dy0))
    return out


class Canvas:
    def __init__(self, bg):
        self.img = bg.convert("RGBA")
        self.kit = json.load(open(os.path.join(OUT_SPR, "kit.json")))
        self.spr = {k: Image.open(os.path.join(OUT_SPR, k + ".png")).convert("RGBA") for k in self.kit}

    def put(self, name, x, y, w, h):
        k = self.kit[name]
        sc = (h * K / k["size"][1]) if k["sliceScale"] == "auto" else (k["sliceScale"] or 1) * K
        self.img.alpha_composite(nine(self.spr[name], k["slice"], int(w * K), int(h * K), sc), (int(x * K), int(y * K)))

    def text(self, x, y, s, size, fill="#FFFFFF", stroke=NAVY, sw=None, anchor="mm", italic=True, weight=900, shadow=True):
        d = ImageDraw.Draw(self.img)
        f = font(size, italic, weight)
        sw = int((sw if sw is not None else max(1.2, size * 0.12)) * K) if stroke else 0
        if shadow and stroke:
            d.text((x * K, y * K + size * 0.12 * K), s, font=f, fill=rgba(stroke), stroke_width=sw, stroke_fill=rgba(stroke), anchor=anchor)
        d.text((x * K, y * K), s, font=f, fill=rgba(fill) if isinstance(fill, str) else fill, stroke_width=sw, stroke_fill=rgba(stroke) if stroke else None, anchor=anchor)

    def wrap(self, x, y, w, s, size, fill, lh=1.25):
        f = font(size, False, 700)
        words, lines, cur = s.split(), [], ""
        for wd in words:
            t = (cur + " " + wd).strip()
            if f.getlength(t) / K > w and cur:
                lines.append(cur)
                cur = wd
            else:
                cur = t
        lines.append(cur)
        for i, ln in enumerate(lines):
            self.text(x, y + i * size * lh, ln, size, fill, stroke=None, italic=False, weight=700, anchor="ma")

    def button(self, style, x, y, w, h, label=None, icon=None, size=None, down=False):
        self.put("btn_" + style + ("_down" if down else ""), x, y, w, h)
        oy = 1.6 if down else 0
        cy = y + h * 0.44 + oy
        size = size or h * 0.38
        tc = BUTTONS[style][3]
        if icon and label:
            isz = h * 0.82
            self.put("icon_" + icon, x + 2, y + (h - isz) / 2 - 1 + oy, isz, isz)
            self.text(x + isz + (w - isz) / 2 - 2, cy, label, size, tc, NAVY if tc != NAVY else "#FFFFFF", shadow=tc != NAVY)
        elif icon:
            isz = min(w, h) * 0.62
            self.put("icon_" + icon, x + (w - isz) / 2, y + (h - isz) / 2 - 2 + oy, isz, isz)
        elif label:
            self.text(x + w / 2, cy, label, size, tc, NAVY if tc != NAVY else "#FFFFFF", shadow=tc != NAVY)

    def save(self, name):
        os.makedirs(OUT_MOCK, exist_ok=True)
        self.img.convert("RGB").save(os.path.join(OUT_MOCK, name + "@2x.png"))
        self.img.convert("RGB").resize((667, 375), Image.LANCZOS).save(os.path.join(OUT_MOCK, name + ".png"))


def world_bg():
    p = os.path.join(SHOTS, "2026-10-28 sporty hub course.jpg")
    im = Image.open(p).convert("RGBA")
    w, h = im.size
    ch = int(w * 9 / 16)
    return im.crop((0, (h - ch) // 2, w, (h - ch) // 2 + ch)).resize((667 * K, 375 * K), Image.LANCZOS)


def hud(c):
    # coins + rank (top left)
    c.put("pill_navy", 10, 10, 150, 38)
    c.put("icon_coin", 4, 5, 46, 46)
    c.text(92, 29, "50.0K", 19)
    c.button("green", 124, 9, 38, 38, "+", size=20)
    c.put("pill_navy", 10, 52, 132, 32)
    c.put("badge_bronze", 12, 52, 32, 32)
    c.text(28, 68, "B", 12)
    c.text(50, 62, "BRONZE", 11, "#FFB15C", anchor="lm")
    c.text(50, 75, "LEAGUE 1", 8, "#B9D3FF", stroke=None, anchor="lm", italic=False, weight=800)
    # speed (top centre)
    c.put("panel", 213, 8, 241, 70)
    c.put("icon_speed", 252, 13, 34, 34)
    c.text(316, 31, "0", 27, anchor="mm")
    c.text(372, 33, "SPEED", 17, "#5AB4FF")
    c.put("bar_track", 236, 48, 195, 12)
    c.put("bar_blue", 236, 48, 40, 12)
    c.text(333, 68, "Reach 310 SPEED to smash wall 1", 8.5, "#FFFFFF", stroke=None, italic=False, weight=700)
    # next race + small buttons (top right)
    c.put("pill_navy", 500, 10, 157, 38)
    c.put("icon_race", 504, 12, 32, 32)
    c.text(538, 29, "NEXT RACE", 11, anchor="lm")
    c.text(627, 29, "1:15", 15, "#FFD21F")
    c.button("yellow", 500, 52, 52, 44, icon="daily")
    c.put("badge_red", 540, 48, 16, 16)
    c.button("blue", 553, 52, 52, 44, icon="quests")
    c.button("blue", 606, 52, 52, 44, icon="top")
    c.text(526, 101, "DAILY", 8.5)
    c.text(579, 101, "QUESTS", 8.5)
    c.text(632, 101, "TOP", 8.5)
    # left column
    c.button("blue", 10, 120, 132, 42, "LOCKER", "locker", 15)
    c.button("yellow", 10, 166, 132, 42, "COACHES", "coaches", 14)
    c.button("green", 10, 212, 132, 42, "STORE", "store", 15)
    c.button("navy", 10, 258, 64, 34, "CODES", "codes", 9)
    c.button("navy", 78, 258, 64, 34, "INVITE", "invite", 9)
    # bottom
    c.button("green", 263, 318, 142, 46, "TO START", None, 17)
    c.button("navy", 616, 326, 40, 38, icon="settings")


def store(c):
    dim = Image.new("RGBA", c.img.size, (6, 12, 34, 150))
    c.img.alpha_composite(dim)
    x, y, w, h = 92, 62, 484, 272
    c.put("panel", x, y, w, h)
    c.text(x + 18, y - 2, "STORE", 27, anchor="lm", sw=3)
    c.put("bar_gold", x + 18, y + 14, 46, 7)
    c.button("red", x + w - 36, y - 16, 46, 44, icon="close")
    c.button("blue", x + 18, y + 28, 104, 36, "PASSES", None, 14)
    c.button("navy", x + 126, y + 28, 104, 36, "COINS", None, 14)
    c.button("navy", x + 234, y + 28, 104, 36, "BOOSTS", None, 14)
    c.text(x + 350, y + 44, "Passes are forever.", 8.5, "#B9D3FF", stroke=None, anchor="lm", italic=False, weight=700)
    c.text(x + 350, y + 55, "They never win a race.", 8.5, "#B9D3FF", stroke=None, anchor="lm", italic=False, weight=700)
    tiles = [
        ("blue", "speed", "AUTO RUN", "Treadmills step for you 3x faster.", "R$ 249"),
        ("lime", "shoe2x", "2x SPEED", "Double SPEED from every step, forever.", "R$ 249"),
        ("gold", "coin", "2x COINS", "Double coins from walls, races and rewards.", "R$ 149"),
        ("orange", "crown", "VIP", "+10% coins, VIP tag, kit, trail and gold name.", "R$ 299"),
    ]
    tw, gap = 108, 8
    for i, (col, ic, name, desc, price) in enumerate(tiles):
        tx, ty = x + 18 + i * (tw + gap), y + 74
        c.put("tile_" + col, tx, ty, tw, 184)
        c.put("icon_" + ic, tx + tw / 2 - 30, ty + 10, 60, 60)
        if ic == "shoe2x" or ic == "coin":
            c.text(tx + tw / 2 + 24, ty + 60, "2x", 14, "#FFD21F")
        c.text(tx + tw / 2, ty + 84, name, 13.5)
        c.wrap(tx + tw / 2, ty + 98, tw - 18, desc, 8, "#C9DCFF")
        c.button("green", tx + 10, ty + 136, tw - 20, 38, price, None, 13)


def sheet(c):
    c.text(20, 18, "SPEED ARC UI KIT", 17, anchor="lm")
    c.text(208, 19, "9-slice PNG sprites, navy outline, 3D lip, top highlight", 8.5, "#B9D3FF", stroke=None, anchor="lm", italic=False, weight=700)
    labels = {"green": "BUY / GO", "blue": "NORMAL", "yellow": "CLAIM", "red": "CLOSE", "grey": "LOCKED", "navy": "TAB OFF"}
    for i, st in enumerate(BUTTONS):
        bx = 20 + i * 106
        c.button(st, bx, 34, 98, 38, labels[st], None, 12)
        c.button(st, bx, 78, 98, 38, "PRESSED", None, 11, down=True)
    c.text(20, 130, "TILES (colour glow)", 9, "#FFD21F", anchor="lm")
    tcols = [("blue", "speed"), ("lime", "shoe2x"), ("orange", "crown"), ("gold", "coin"), ("red", "close"), ("cyan", "race"), ("grey", "settings")]
    for i, (col, ic) in enumerate(tcols):
        tx = 20 + i * 62
        c.put("tile_" + col, tx, 140, 56, 76)
        c.put("icon_" + ic, tx + 8, 150, 40, 40)
    c.text(462, 130, "PANEL + PILLS", 9, "#FFD21F", anchor="lm")
    c.put("panel", 462, 146, 186, 72)
    c.text(476, 147, "WINDOW", 13, anchor="lm")
    c.put("pill_navy", 474, 164, 74, 26)
    c.put("icon_coin", 470, 161, 30, 30)
    c.text(524, 177, "720", 11)
    c.put("pill_red", 554, 164, 52, 26)
    c.text(580, 177, "LIVE", 10)
    c.put("badge_red", 612, 166, 22, 22)
    c.put("bar_track", 474, 196, 160, 12)
    c.put("bar_gold", 474, 196, 96, 12)
    c.text(20, 232, "ICONS (one on every main button)", 9, "#FFD21F", anchor="lm")
    names = ["store", "locker", "coaches", "codes", "invite", "daily", "quests", "top", "settings", "close", "coin", "speed", "crown", "race"]
    for i, n in enumerate(names):
        ix = 20 + i * 45.5
        c.put("icon_" + n, ix, 244, 42, 42)
        c.text(ix + 21, 296, n.upper(), 6.5, "#FFFFFF", stroke=None, italic=False, weight=800)
    c.text(20, 322, "BUTTON + ICON", 9, "#FFD21F", anchor="lm")
    c.button("blue", 20, 332, 124, 38, "LOCKER", "locker", 14)
    c.button("yellow", 150, 332, 124, 38, "COACHES", "coaches", 13)
    c.button("green", 280, 332, 124, 38, "STORE", "store", 14)
    c.button("yellow", 410, 332, 120, 38, "CLAIM", "coin", 14)
    c.button("grey", 536, 332, 112, 38, "LOCKED", None, 13)


# ---------------------------------------------------------------- 3 atlas sheets + the game's sprite table
SHEETS = {"Buttons": "ui_buttons.png", "Tiles": "ui_tiles.png", "Icons": "ui_icons.png"}
GUTTER = 4


def sheet_of(name):
    return "Tiles" if name.startswith("tile_") else "Icons" if name.startswith("icon_") else "Buttons"


def pack():
    kit = json.load(open(os.path.join(OUT_SPR, "kit.json")))
    out_dir = os.path.join(OUT_SPR, "sheets")
    os.makedirs(out_dir, exist_ok=True)
    table = {}
    for sheet, fname in SHEETS.items():
        names = [n for n in kit if sheet_of(n) == sheet]
        names.sort(key=lambda n: -kit[n]["size"][1])  # tallest first: simple shelf packing
        atlas = Image.new("RGBA", (1024, 512), (0, 0, 0, 0))
        x = y = shelf = 0
        for n in names:
            w, h = kit[n]["size"]
            if x + w > 1024:
                x, y, shelf = 0, y + shelf + GUTTER, 0
            assert y + h <= 512, (sheet, n)
            atlas.alpha_composite(Image.open(os.path.join(OUT_SPR, n + ".png")).convert("RGBA"), (x, y))
            table[n] = (sheet, x, y, w, h, kit[n]["slice"], kit[n]["sliceScale"])
            x += w + GUTTER
            shelf = max(shelf, h)
        atlas.save(os.path.join(out_dir, fname))
    lua = ["-- GENERATED by tools/make_ui_kit.py (prompt 12). Don't edit by hand: change the script and run it again.",
           "-- name = { Sheet, X, Y, W, H, Slice = {l, t, r, b} (inside the sprite), SliceScale (\"auto\" = height / sprite height) }",
           "return {"]
    for n in sorted(table):
        sheet, x, y, w, h, sl, sc = table[n]
        extra = ""
        if sl:
            extra = ", Slice = { %d, %d, %d, %d }, SliceScale = %s" % (*sl, '"auto"' if sc == "auto" else sc)
        lua.append('\t%s = { "%s", %d, %d, %d, %d%s },' % (n, sheet, x, y, w, h, extra))
    lua.append("}")
    p = os.path.join(GAME, "src", "ReplicatedStorage", "Shared", "Config", "UIArtSprites.lua")
    open(p, "w", newline="\n").write("\n".join(lua) + "\n")
    return out_dir


if __name__ == "__main__":
    build()
    sheets_dir = pack()
    # Studio test copy: Studio loads rbxasset://textures/SpeedArcKit/* until the sheets are uploaded
    import glob, shutil
    for v in glob.glob(os.path.join(os.environ.get("LOCALAPPDATA", ""), "Roblox", "Versions", "*", "content", "textures")):
        if os.path.exists(os.path.join(os.path.dirname(os.path.dirname(v)), "RobloxStudioBeta.exe")):
            dst = os.path.join(v, "SpeedArcKit")
            os.makedirs(dst, exist_ok=True)
            for f in SHEETS.values():
                shutil.copy(os.path.join(sheets_dir, f), dst)
            print("studio copy:", dst)
    c = Canvas(world_bg())
    hud(c)
    c.save("mockup_hud")
    store(c)
    c.save("mockup_store")
    bg = Image.new("RGBA", (667 * K, 375 * K))
    bg.paste(grad((667 * K // SS + 1, 375 * K // SS + 1), (0, 0, 667 * K / SS, 375 * K / SS), "#1A2E6E", "#0B1638").resize((667 * K, 375 * K)), (0, 0))
    s = Canvas(bg)
    sheet(s)
    s.save("mockup_kit")
    print("ok", len(s.kit), "sprites")
