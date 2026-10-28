"""SPEED ARC Locker kits as classic clothing templates (585 x 559, the Roblox Shirt / Pants layout).
Transparent pixels show the avatar's skin, so a singlet leaves the arms bare and shorts leave the
lower legs bare. In game the Locker puts these on as the character's Shirt / Pants (they wrap and move
with the body). The owner uploads each PNG as an IMAGE (in the group) and sends the ids.
    python tools/make_clothing.py [out folder]
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.expanduser("~"), "Downloads", "speed_arc_models", "clothing")
os.makedirs(OUT, exist_ok=True)
W, H = 585, 559
FONT = "C:/Windows/Fonts/ariblk.ttf"

BLACK, CARBON, GRAPHITE = (11, 13, 18), (23, 26, 34), (42, 47, 58)
BLUE, BRIGHT, DEEP = (30, 123, 255), (79, 195, 255), (14, 58, 138)
GOLD, DEEPGOLD, WHITE = (255, 200, 61), (224, 154, 18), (244, 246, 250)

# template regions (x0, y0, x1, y1)
TORSO = {"U": (231, 8, 359, 72), "F": (231, 74, 359, 202), "R": (165, 74, 229, 202), "L": (361, 74, 425, 202), "B": (427, 74, 555, 202), "D": (231, 204, 359, 268)}
RLIMB = {"U": (217, 289, 281, 353), "L": (19, 355, 83, 483), "B": (85, 355, 149, 483), "R": (151, 355, 215, 483), "F": (217, 355, 281, 483), "D": (217, 485, 281, 549)}
LLIMB = {"U": (308, 289, 372, 353), "F": (308, 355, 372, 483), "L": (374, 355, 438, 483), "B": (440, 355, 504, 483), "R": (506, 355, 570, 483), "D": (308, 485, 372, 549)}
SIDES = ("F", "L", "B", "R")


def new():
    return Image.new("RGBA", (W, H), (0, 0, 0, 0))


def shade(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c)


def fill(d, box, color, top=0.0, bottom=1.0):
    """Fill the part of a face between top and bottom (0..1 of its height), with a soft vertical shade."""
    x0, y0, x1, y1 = box
    ya, yb = int(y0 + (y1 - y0) * top), int(y0 + (y1 - y0) * bottom)
    for y in range(ya, yb):
        t = (y - y0) / max(1, (y1 - y0))
        d.line([(x0, y), (x1 - 1, y)], fill=shade(color, 1.06 - 0.14 * t) + (255,))


def band(d, box, color, at, h=0.05):
    x0, y0, x1, y1 = box
    y = int(y0 + (y1 - y0) * at)
    d.rectangle([x0, y, x1 - 1, y + max(2, int((y1 - y0) * h))], fill=color + (255,))


def vstripe(d, box, color, w=6, side="center", top=0.0, bottom=1.0):
    x0, y0, x1, y1 = box
    ya, yb = int(y0 + (y1 - y0) * top), int(y0 + (y1 - y0) * bottom)
    cx = (x0 + x1) // 2 if side == "center" else (x0 + 4 if side == "left" else x1 - 4 - w)
    if side == "center":
        cx -= w // 2
    d.rectangle([cx, ya, cx + w - 1, yb - 1], fill=color + (255,))


def logo(d, box, text, color):
    x0, y0, x1, y1 = box
    f = ImageFont.truetype(FONT, 14)
    d.text((x0 + (x1 - x0) * 0.72, y0 + 26), text, font=f, fill=color + (255,), anchor="mm")


def neck_scoop(img, box, depth):
    """Cut a U-shaped neckline (transparent = skin) into the top of a torso face."""
    x0, y0, x1, y1 = box
    m = Image.new("L", (W, H), 0)
    md = ImageDraw.Draw(m)
    cx, r = (x0 + x1) / 2, (x1 - x0) * 0.22
    md.ellipse([cx - r, y0 - depth, cx + r, y0 + depth], fill=255)
    img.paste((0, 0, 0, 0), (0, 0), m)


def shirt(name, body, trim, accent, arms, scoop=True, zip_=False, label=None):
    """arms: 0 = singlet (bare arms), 0.4 = tee sleeves, 0.88 = long sleeves (hands bare)."""
    img = new()
    d = ImageDraw.Draw(img)
    for k, box in TORSO.items():
        fill(d, box, body)
    for k in SIDES:
        band(d, TORSO[k], trim, 0.93, 0.07)  # hem
    for k in ("L", "R"):
        vstripe(d, TORSO[k], accent, w=8)  # side panel stripe
    if zip_:
        vstripe(d, TORSO["F"], accent, w=5)
        d.rectangle([TORSO["F"][0] + 60, TORSO["F"][1] + 8, TORSO["F"][0] + 68, TORSO["F"][1] + 22], fill=WHITE + (255,))
        d.rectangle([TORSO["U"][0], TORSO["U"][3] - 10, TORSO["U"][2] - 1, TORSO["U"][3] - 1], fill=trim + (255,))  # collar
    else:
        # a chest stripe like a race top
        band(d, TORSO["F"], accent, 0.36, 0.06)
        band(d, TORSO["B"], accent, 0.36, 0.06)
    if label:
        logo(d, TORSO["F"], label, trim)
    if arms > 0:
        for limb in (RLIMB, LLIMB):
            fill(d, limb["U"], body)
            for k in SIDES:
                fill(d, limb[k], body, 0, arms)
                band(d, limb[k], trim, arms - 0.07, 0.07)  # cuff
            for k in ("L", "R"):
                vstripe(d, limb[k], accent, w=6, bottom=arms - 0.07)
    if scoop and not zip_:
        neck_scoop(img, TORSO["F"], 22)
        neck_scoop(img, TORSO["B"], 12)
    img.save(os.path.join(OUT, name + ".png"))
    print("[shirt]", name)


def pants(name, body, trim, accent, legs, label=None):
    """legs: how far down the leg it goes (0.45 shorts, 0.36 split shorts, 0.86 tights)."""
    img = new()
    d = ImageDraw.Draw(img)
    # the torso part: only the hips (the bottom of the torso faces)
    for k in SIDES:
        fill(d, TORSO[k], body, 0.62, 1.0)
        band(d, TORSO[k], trim, 0.62, 0.08)  # waistband
    fill(d, TORSO["D"], body)
    for limb in (RLIMB, LLIMB):
        fill(d, limb["U"], body)
        for k in SIDES:
            fill(d, limb[k], body, 0, legs)
            band(d, limb[k], trim, legs - 0.06, 0.06)  # hem
        for k in ("L", "R"):
            vstripe(d, limb[k], accent, w=7, bottom=legs - 0.06)
    if label:
        x0, y0, x1, y1 = RLIMB["F"]
        f = ImageFont.truetype(FONT, 12)
        d.text(((x0 + x1) / 2, y0 + 16), label, font=f, fill=trim + (255,), anchor="mm")
    img.save(os.path.join(OUT, name + ".png"))
    print("[pants]", name)


if __name__ == "__main__":
    shirt("Shirt_SingletBlue", BLUE, WHITE, GOLD, arms=0)
    shirt("Shirt_TeeGold", GOLD, WHITE, BLUE, arms=0.42, scoop=False)
    shirt("Shirt_ZipBlack", CARBON, GRAPHITE, BRIGHT, arms=0.88, zip_=True)
    shirt("Shirt_VipTop", BLACK, GOLD, GOLD, arms=0, label="VIP")
    pants("Pants_ShortsBlue", DEEP, WHITE, BRIGHT, legs=0.46)
    pants("Pants_SplitBlack", CARBON, GOLD, GOLD, legs=0.36)
    pants("Pants_TightsGold", GOLD, BLACK, BLUE, legs=0.88)
    pants("Pants_VipShorts", BLACK, GOLD, GOLD, legs=0.46, label="VIP")
