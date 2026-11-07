"""The pictures of visible damage (owner, 2026-11-07: "add car scrapes and etc"), drawn here, no logos, no real source.
    python tools/damage/make_marks.py <out dir>
Each mark fills the middle quarter of a clear square: a Texture as wide as a body side shows one, and its offset moves it
anywhere on that side, following the real surface of the mesh."""
import math
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFilter

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
S = 512


def clear():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))


def scrape(seed, lines=46, color=(214, 216, 220)):
    random.seed(seed)
    im = clear()
    d = ImageDraw.Draw(im)
    # grey primer rub underneath
    for _ in range(26):
        x0 = random.randint(90, 240)
        x1 = random.randint(270, 420)
        y = random.randint(226, 286)
        d.line((x0, y, x1, y + random.randint(-3, 3)), fill=(120, 122, 128, 70), width=random.randint(3, 7))
    im = im.filter(ImageFilter.GaussianBlur(2.2))
    d = ImageDraw.Draw(im)
    for _ in range(lines):
        x0 = random.randint(70, 300)
        x1 = x0 + random.randint(60, 240)
        y = random.gauss(256, 17)
        d.line((x0, y, x1, y + random.randint(-2, 2)), fill=color + (random.randint(120, 245),), width=random.choice((1, 1, 2)))
    for _ in range(90):
        x = random.randint(90, 420)
        y = random.gauss(256, 26)
        d.point((x, y), fill=(32, 32, 34, 200))
    return im


def scratch(seed):
    random.seed(seed)
    im = clear()
    d = ImageDraw.Draw(im)
    for _ in range(10):
        x0 = random.randint(190, 280)
        x1 = x0 + random.randint(20, 70)
        y = random.gauss(256, 9)
        d.line((x0, y, x1, y + random.randint(-4, 4)), fill=(218, 220, 224, random.randint(150, 240)), width=1)
    return im


def dent(seed):
    random.seed(seed)
    im = clear()
    # the dark shape of a pushed-in panel, lit on one edge
    shade = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(shade)
    pts = []
    for i in range(14):
        a = i / 14 * math.tau
        r = random.uniform(62, 104)
        pts.append((256 + math.cos(a) * r * 1.35, 256 + math.sin(a) * r * 0.8))
    d.polygon(pts, fill=150)
    for _ in range(9):
        x, y = random.choice(pts)
        d.line((x, y, 256 + random.randint(-30, 30), 256 + random.randint(-20, 20)), fill=205, width=random.randint(3, 8))
    shade = shade.filter(ImageFilter.GaussianBlur(9))
    im = Image.merge("RGBA", (Image.new("L", (S, S), 8), Image.new("L", (S, S), 8), Image.new("L", (S, S), 10), shade))
    # a bright crease and paint chips
    d2 = ImageDraw.Draw(im)
    for _ in range(5):
        x0 = 256 + random.randint(-90, 40)
        y0 = 256 + random.randint(-40, 40)
        d2.line((x0, y0, x0 + random.randint(30, 70), y0 + random.randint(-14, 14)), fill=(226, 226, 230, 190), width=2)
    for _ in range(40):
        x = 256 + random.gauss(0, 48)
        y = 256 + random.gauss(0, 26)
        d2.ellipse((x, y, x + 2, y + 2), fill=(196, 198, 202, 200))
    return im


def crack(seed, big=True):
    random.seed(seed)
    im = clear()
    d = ImageDraw.Draw(im)
    cx, cy = random.randint(220, 290), random.randint(220, 290)
    arms = 11 if big else 8
    reach = 230 if big else 150
    ends = []
    for i in range(arms):
        a = i / arms * math.tau + random.uniform(-0.2, 0.2)
        x, y = cx, cy
        steps = random.randint(4, 8)
        pts = [(x, y)]
        for s in range(steps):
            a += random.uniform(-0.26, 0.26)
            r = reach / steps * random.uniform(0.7, 1.2)
            x += math.cos(a) * r
            y += math.sin(a) * r
            pts.append((x, y))
        d.line(pts, fill=(232, 240, 246, 225), width=2 if i % 3 == 0 else 1)
        ends.append(pts[len(pts) // 2])
    for i in range(arms):
        d.line((ends[i], ends[(i + 1) % arms]), fill=(232, 240, 246, 150), width=1)
    d.ellipse((cx - 7, cy - 7, cx + 7, cy + 7), fill=(240, 244, 248, 200))
    return im


def rash():
    """the rim's lip, ground away: a broken ring, seen square on"""
    random.seed(4)
    im = clear()
    d = ImageDraw.Draw(im)
    for _ in range(420):
        a = random.uniform(0, math.tau)
        if 2.2 < a < 3.1:
            continue
        r = random.uniform(214, 244)
        x, y = 256 + math.cos(a) * r, 256 + math.sin(a) * r
        d.line((x, y, x + math.sin(a) * random.uniform(4, 16), y - math.cos(a) * random.uniform(4, 16)), fill=(232, 232, 236, random.randint(120, 240)), width=random.choice((1, 2)))
    return im


def dirt():
    """road film: thick at the sill, gone by the waist. Wide, for the whole side"""
    random.seed(9)
    W, H = 1024, 512
    a = Image.new("L", (W, H), 0)
    px = a.load()
    for y in range(H):
        k = max(0.0, (y / H - 0.34) / 0.66) ** 1.5
        for x in range(0, W, 2):
            n = random.random()
            v = int(255 * k * (0.5 + 0.5 * n))
            px[x, y] = v
            px[min(x + 1, W - 1), y] = v
    a = a.filter(ImageFilter.GaussianBlur(3))
    return Image.merge("RGBA", (Image.new("L", (W, H), 92), Image.new("L", (W, H), 78), Image.new("L", (W, H), 58), a))


def shrink(im):
    """the mark into the middle quarter of a 1024 square"""
    out = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    box = im.crop((56, 156, 456, 356)) if im.size == (S, S) else im
    box = box.resize((384, 192), Image.LANCZOS)
    out.paste(box, (320, 416))
    return out


for name, im in {
    "scrape1": scrape(1), "scrape2": scrape(2, 60), "scrape3": scrape(3, 34),
    "scratch1": scratch(4), "scratch2": scratch(5),
    "dent1": dent(6), "dent2": dent(7), "dent3": dent(8),
    "crackglass": crack(9), "cracklamp": crack(10, False), "rash": rash(), "dirt": dirt(),
}.items():
    if name[:5] in ("scrap", "dent1", "dent2", "dent3"):
        im = shrink(im)
    elif name == "cracklamp":
        out = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
        out.paste(im.resize((230, 230), Image.LANCZOS), (397, 397))
        im = out
    im.save(os.path.join(OUT, name + ".png"))
print("ok")
