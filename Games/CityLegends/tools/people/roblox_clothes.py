"""roblox_clothes.py (2026-11-27): Roblox Shirt / Pants templates (585 x 559) for YangonStreetLife's street people.

Owner (27 Nov): "make it just roblox character, like the tiktok video car game, not some realistic looking people because
thats terrifying". The people are classic Roblox avatars (R6 blocks, Roblox faces and hair); Yangon shows only in the
clothes: longyi checks (men), htamein with a hem band (women), shirts and blouses, the maroon monk robe, the green and
white school uniform, a T-shirt and jeans. Transparent pixels show the body colour (skin): short sleeves, bare feet in
sandals under the longyi.

    python tools/people/roblox_clothes.py      -> imports/people/clothes/<name>.png
"""
import os

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "..", "imports", "people", "clothes"))

# Roblox's clothing template: torso faces, then the right limb (left of the picture) and the left limb (right)
TORSO = {"U": (231, 8, 128, 64), "F": (231, 74, 128, 128), "D": (231, 204, 128, 64), "R": (165, 74, 64, 128),
         "L": (361, 74, 64, 128), "B": (427, 74, 128, 128)}
LIMB_R = {"U": (217, 289, 64, 64), "D": (217, 485, 64, 64), "R": (19, 355, 64, 128), "B": (85, 355, 64, 128),
          "L": (151, 355, 64, 128), "F": (217, 355, 64, 128)}
LIMB_L = {"U": (308, 289, 64, 64), "D": (308, 485, 64, 64), "F": (308, 355, 64, 128), "L": (374, 355, 64, 128),
          "B": (440, 355, 64, 128), "R": (506, 355, 64, 128)}
SIDES = ("F", "L", "B", "R")  # round a limb


def new():
    return Image.new("RGBA", (585, 559), (0, 0, 0, 0))


def shade(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c[:3]) + (255,)


def fill(d, box, c):
    x, y, w, h = box
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=c)


def checks(img, box, a, b, line, cell=16, phase=0):
    """a longyi check: two-tone squares with thin cross lines (the paso / htamein weave)"""
    x0, y0, w, h = box
    px = img.load()
    for y in range(h):
        for x in range(w):
            u, v = (x + phase) // cell, (y + phase) // cell
            c = a if (u + v) % 2 == 0 else b
            if (x + phase) % cell in (cell // 2, cell // 2 + 1) or (y + phase) % cell in (cell // 2, cell // 2 + 1):
                c = line
            px[x0 + x, y0 + y] = c


def stripes(img, box, base, line, every=10):
    x0, y0, w, h = box
    px = img.load()
    for y in range(h):
        for x in range(w):
            px[x0 + x, y0 + y] = line if (x + y // 3) % every < 2 else base


# ------------------------------------------------------------------ shirts
def shirt(name, col, sleeve="short", collar=True, pocket=True, buttons=True, tee=False):
    img = new()
    d = ImageDraw.Draw(img)
    dark = shade(col, 0.82)
    for f, box in TORSO.items():
        fill(d, box, col)
    x, y, w, h = TORSO["F"]
    # side shade and hem line
    d.rectangle([x, y + h - 6, x + w - 1, y + h - 1], fill=dark)
    if tee:
        d.ellipse([x + 44, y - 18, x + 84, y + 14], fill=(0, 0, 0, 0))  # round neck (skin)
        d.arc([x + 44, y - 18, x + 84, y + 14], 0, 180, fill=dark, width=4)
    if collar:
        d.polygon([(x + 40, y), (x + 64, y + 22), (x + 52, y + 30), (x + 34, y + 4)], fill=shade(col, 1.08))
        d.polygon([(x + 88, y), (x + 64, y + 22), (x + 76, y + 30), (x + 94, y + 4)], fill=shade(col, 1.08))
        d.line([(x + 40, y), (x + 64, y + 22), (x + 88, y)], fill=dark, width=2)
        d.polygon([(x + 52, y), (x + 76, y), (x + 64, y + 18)], fill=(0, 0, 0, 0))  # skin in the V
    if buttons:
        d.line([(x + 64, y + 22), (x + 64, y + h - 6)], fill=dark, width=2)
        for by in range(y + 34, y + h - 10, 22):
            d.ellipse([x + 61, by, x + 67, by + 6], fill=(236, 236, 230, 255))
    if pocket:
        d.rectangle([x + 80, y + 36, x + 104, y + 62], outline=dark, width=2)
    bx, by_, bw, bh = TORSO["B"]
    d.rectangle([bx, by_ + bh - 6, bx + bw - 1, by_ + bh - 1], fill=dark)
    if collar:
        d.rectangle([bx + 34, by_, bx + 94, by_ + 8], fill=shade(col, 1.08))
    for limb in (LIMB_R, LIMB_L):
        fill(d, limb["U"], col)
        cut = {"short": 56, "long": 128, "none": 0, "elbow": 72}[sleeve]
        for s in SIDES:
            x, y, w, h = limb[s]
            if cut:
                d.rectangle([x, y, x + w - 1, y + cut - 1], fill=col)
                d.rectangle([x, y + cut - 6, x + w - 1, y + cut - 1], fill=dark)  # cuff
        if sleeve == "long":
            fill(d, limb["D"], (0, 0, 0, 0))
        if sleeve == "none":
            fill(d, limb["U"], (0, 0, 0, 0))
    img.save(os.path.join(OUT, name + ".png"))


def blouse(name, col, trim):
    """eingyi: a short fitted blouse, round neck, buttons down the front, 3/4 sleeves"""
    img = new()
    d = ImageDraw.Draw(img)
    dark = shade(col, 0.84)
    for f, box in TORSO.items():
        fill(d, box, col)
    x, y, w, h = TORSO["F"]
    d.ellipse([x + 46, y - 16, x + 82, y + 14], fill=(0, 0, 0, 0))
    d.arc([x + 46, y - 16, x + 82, y + 14], 0, 180, fill=trim, width=3)
    d.line([(x + 64, y + 14), (x + 64, y + h - 4)], fill=trim, width=2)
    for by in range(y + 24, y + h - 12, 18):
        d.ellipse([x + 60, by, x + 68, by + 8], fill=trim)
    d.rectangle([x, y + h - 8, x + w - 1, y + h - 1], fill=dark)
    for limb in (LIMB_R, LIMB_L):
        fill(d, limb["U"], col)
        for s in SIDES:
            lx, ly, lw, lh = limb[s]
            d.rectangle([lx, ly, lx + lw - 1, ly + 70], fill=col)
            d.rectangle([lx, ly + 64, lx + lw - 1, ly + 70], fill=trim)
    img.save(os.path.join(OUT, name + ".png"))


# ------------------------------------------------------------------ longyi / pants
def strap(d, limb):
    """flip-flops: a dark strap across the foot and a sole line round the bottom of each leg (the rest is the leg's
    skin). (27 Nov: a V strap on the front read as a smiling mouth in Studio.)"""
    for s in SIDES:
        x, y, w, h = limb[s]
        d.rectangle([x, y + h - 9, x + w - 1, y + h - 6], fill=(40, 32, 28, 255))
        d.rectangle([x, y + h - 3, x + w - 1, y + h - 1], fill=(52, 42, 36, 255))
    dx, dy, dw, dh = limb["D"]
    d.rectangle([dx, dy, dx + dw - 1, dy + dh - 1], fill=(52, 42, 36, 255))  # the sole


def longyi(name, a, b, line, band=None, knot=True, plain=False, hem=18):
    img = new()
    d = ImageDraw.Draw(img)
    # the longyi covers the lower torso (waist band) and both legs to the ankle; skin shows at the feet
    for f in ("F", "B", "L", "R"):
        x, y, w, h = TORSO[f]
        lower = (x, y + h - 30, w, 30)
        if plain:
            fill(d, lower, a)
        else:
            checks(img, lower, a, b, line, phase=4)
    fill(d, TORSO["D"], shade(a, 0.8))
    if knot:  # the paso's knot at the front of the waist
        x, y, w, h = TORSO["F"]
        d.ellipse([x + 52, y + h - 34, x + 76, y + h - 14], fill=shade(a, 0.75))
        d.polygon([(x + 58, y + h - 16), (x + 70, y + h - 16), (x + 66, y + h), (x + 62, y + h)], fill=shade(a, 0.7))
    for k, limb in enumerate((LIMB_R, LIMB_L)):
        fill(d, limb["U"], shade(a, 0.8))
        for s in SIDES:
            x, y, w, h = limb[s]
            box = (x, y, w, h - hem)
            if plain:
                fill(d, box, a)
            else:
                checks(img, box, a, b, line, phase=4 + (k * 8 if s in ("L", "R") else 0))
            if band:
                d.rectangle([x, y + h - hem - 16, x + w - 1, y + h - hem - 1], fill=band)
                for bx in range(x + 4, x + w, 12):
                    d.ellipse([bx, y + h - hem - 12, bx + 6, y + h - hem - 6], fill=shade(band, 1.25))
        strap(d, limb)
    img.save(os.path.join(OUT, name + ".png"))


def jeans(name, col):
    img = new()
    d = ImageDraw.Draw(img)
    dark = shade(col, 0.8)
    for f in ("F", "B", "L", "R"):
        x, y, w, h = TORSO[f]
        fill(d, (x, y + h - 26, w, 26), col)
        d.rectangle([x, y + h - 26, x + w - 1, y + h - 20], fill=(60, 44, 34, 255))  # belt
    fill(d, TORSO["D"], col)
    for limb in (LIMB_R, LIMB_L):
        fill(d, limb["U"], col)
        for s in SIDES:
            x, y, w, h = limb[s]
            fill(d, (x, y, w, h - 14), col)
            d.line([(x + w // 2, y), (x + w // 2, y + h - 16)], fill=dark, width=2)
            d.rectangle([x, y + h - 14, x + w - 1, y + h - 1], fill=(236, 236, 232, 255))  # white sneakers
        fill(d, limb["D"], (220, 220, 216, 255))
    img.save(os.path.join(OUT, name + ".png"))


def robe(name, col):
    """the monk's robe: over the left shoulder, the right shoulder and arm bare; shirt and pants of one cloth"""
    img = new()
    d = ImageDraw.Draw(img)
    fold = shade(col, 0.8)
    for f, box in TORSO.items():
        fill(d, box, col)
    x, y, w, h = TORSO["F"]
    d.polygon([(x + 80, y), (x + w, y), (x + w, y + 30)], fill=(0, 0, 0, 0))  # bare right shoulder (viewer's right... )
    for k in range(4):
        d.line([(x + 10 + 30 * k, y + h), (x + 90 + 10 * k, y)], fill=fold, width=3)  # diagonal folds
    for s in SIDES:  # the left arm wrapped, the right bare
        lx, ly, lw, lh = LIMB_L[s]
        fill(d, (lx, ly, lw, 100), col)
        d.line([(lx, ly + 60), (lx + lw, ly + 40)], fill=fold, width=3)
    fill(d, LIMB_L["U"], col)
    img.save(os.path.join(OUT, name + "_shirt.png"))
    img = new()
    d = ImageDraw.Draw(img)
    for f in ("F", "B", "L", "R"):
        x, y, w, h = TORSO[f]
        fill(d, (x, y + h - 30, w, 30), col)
    fill(d, TORSO["D"], fold)
    for limb in (LIMB_R, LIMB_L):
        fill(d, limb["U"], fold)
        for s in SIDES:
            x, y, w, h = limb[s]
            fill(d, (x, y, w, h - 16), col)
            for k in range(3):
                d.line([(x + 12 + 18 * k, y), (x + 8 + 18 * k, y + h - 18)], fill=fold, width=2)
        strap(d, limb)
    img.save(os.path.join(OUT, name + "_pants.png"))


# ------------------------------------------------------------------ atlases (what the game uses)
SHIRTS = ["shirt_white", "shirt_blue", "shirt_cream", "shirt_navy", "tee_red", "tee_black", "blouse_white", "blouse_pink",
          "blouse_yellow", "blouse_lilac", "uniform_shirt", "robe_shirt"]
PANTS = ["longyi_green", "longyi_blue", "longyi_brown", "longyi_grey", "longyi_maroon", "htamein_pink", "htamein_teal",
         "htamein_purple", "htamein_gold", "uniform_longyi", "robe_pants", "jeans_blue"]
CELL_W, CELL_H, G = 341, 256, 4  # 3 x 4 cells in 1024 x 1024; G = gutter round each face (edge pixels repeated)
# face slots in a cell (x, y) for half-size faces: torso F/B 64x64, sides 32x64, top 64x32; limb faces 32x64, tops 32x32
SLOTS = {("T", "F"): (0, 0), ("T", "B"): (72, 0), ("T", "L"): (144, 0), ("T", "R"): (184, 0), ("T", "U"): (224, 0),
         ("R", "F"): (0, 72), ("R", "B"): (40, 72), ("R", "L"): (80, 72), ("R", "R"): (120, 72),
         ("L", "F"): (160, 72), ("L", "B"): (200, 72), ("L", "L"): (240, 72), ("L", "R"): (280, 72),
         ("R", "U"): (0, 144), ("L", "U"): (40, 144)}


def atlas(names, out):
    """the garments' faces cut from their templates at half size into one 1024 x 1024 picture (one texture for every
    person: Roblox's Humanoid clothing made ~1.4 MB of character texture per person, 58 MB for 40 in Studio)"""
    import numpy as np
    big = np.zeros((1024, 1024, 4), np.uint8)
    for i, nm in enumerate(names):
        src = Image.open(os.path.join(OUT, nm + ".png")).convert("RGBA")
        cx, cy = (i % 3) * CELL_W, (i // 3) * CELL_H
        for (part, face), (sx, sy) in SLOTS.items():
            reg = {"T": TORSO, "R": LIMB_R, "L": LIMB_L}[part][face]
            x, y, w, h = reg
            crop = src.crop((x, y, x + w, y + h)).resize((w // 2, h // 2), Image.LANCZOS)
            a = np.pad(np.asarray(crop), ((G, G), (G, G), (0, 0)), mode="edge")
            big[cy + sy:cy + sy + a.shape[0], cx + sx:cx + sx + a.shape[1]] = a
    Image.fromarray(big).save(out)


def main():
    os.makedirs(OUT, exist_ok=True)
    # men: shirts (white is the most common), a T-shirt
    shirt("shirt_white", (240, 240, 236, 255))
    shirt("shirt_blue", (150, 186, 226, 255))
    shirt("shirt_cream", (232, 220, 192, 255), pocket=False)
    shirt("shirt_navy", (46, 58, 96, 255), sleeve="long")
    shirt("tee_red", (196, 52, 52, 255), collar=False, pocket=False, buttons=False, tee=True)
    shirt("tee_black", (40, 40, 44, 255), collar=False, pocket=False, buttons=False, tee=True)
    # women: eingyi blouses
    blouse("blouse_white", (246, 244, 238, 255), (210, 200, 180, 255))
    blouse("blouse_pink", (238, 170, 186, 255), (250, 236, 240, 255))
    blouse("blouse_yellow", (244, 222, 140, 255), (250, 246, 224, 255))
    blouse("blouse_lilac", (196, 176, 222, 255), (244, 240, 250, 255))
    # men's paso: dark checks
    longyi("longyi_green", (46, 84, 60, 255), (34, 62, 46, 255), (120, 150, 120, 255))
    longyi("longyi_blue", (44, 58, 98, 255), (30, 40, 70, 255), (110, 130, 170, 255))
    longyi("longyi_brown", (104, 76, 54, 255), (78, 56, 40, 255), (170, 140, 100, 255))
    longyi("longyi_grey", (90, 96, 104, 255), (60, 64, 72, 255), (150, 156, 164, 255))
    longyi("longyi_maroon", (110, 42, 50, 255), (80, 30, 38, 255), (170, 110, 110, 255))
    # women's htamein: bright, with a hem band
    longyi("htamein_pink", (186, 46, 110, 255), (160, 36, 92, 255), (230, 150, 190, 255), band=(240, 200, 90, 255), knot=False)
    longyi("htamein_teal", (30, 116, 126, 255), (24, 96, 106, 255), (130, 200, 200, 255), band=(240, 220, 150, 255), knot=False)
    longyi("htamein_purple", (104, 56, 132, 255), (84, 44, 110, 255), (190, 150, 210, 255), band=(230, 200, 110, 255), knot=False)
    longyi("htamein_gold", (200, 152, 60, 255), (170, 124, 44, 255), (240, 210, 140, 255), band=(150, 40, 40, 255), knot=False)
    # school uniform, monks, jeans
    shirt("uniform_shirt", (246, 246, 242, 255), pocket=True)
    longyi("uniform_longyi", (34, 112, 62, 255), None, None, knot=True, plain=True)
    robe("robe", (132, 40, 38, 255))
    jeans("jeans_blue", (58, 82, 128, 255))
    atlas(SHIRTS, os.path.join(OUT, "..", "atlas_shirts.png"))
    atlas(PANTS, os.path.join(OUT, "..", "atlas_pants.png"))
    print("wrote", sorted(os.listdir(OUT)), "+ atlas_shirts.png, atlas_pants.png")


if __name__ == "__main__":
    main()
