# Maha Wizaya Pagoda: the three interior pictures, painted in code (PIL). Nothing is copied from a photo: the colours and
# the layout (a pale sky-blue tiled dome with a ring of star-sign figures and dotted constellations round a centre lamp;
# a teal forest wall; leafy canopies) follow the Commons photos 2016_Rangun_Pagoda_Maha_Wizaya_17/20/21 (Marcin Konsek,
# CC BY-SA 4.0) by eye, the figures are our own simple shapes.
#   python tools/yangon/landmarks3d/maha_wizaya_textures.py   ->  build/landmarks/maha_wizaya/tex/{dome,mural,leaves}.png
import math, os, random
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
OUT = os.path.join(ROOT, "build", "landmarks", "maha_wizaya", "tex")

SKY = (152, 186, 200)        # dome tiles (photo 20: pale blue, lit 160,190,205; shaded 120,150,165)
JOINT = (128, 160, 176)
WHITE = (236, 230, 214)
CREAM = (226, 206, 150)
GREEN = (92, 128, 104)
DARKG = (70, 86, 62)
BROWN = (120, 92, 60)
PINK = (222, 160, 150)
RED = (196, 82, 62)
GOLD = (206, 172, 92)


def dome(size=2048):
    """Top-down 'azimuthal equidistant' view of the dome: radius = polar angle. Returns the canvas."""
    R = size // 2 - 8
    c = size // 2
    im = Image.new("RGB", (size, size), SKY)
    d = ImageDraw.Draw(im)
    rnd = random.Random(7)
    # tile courses: concentric rings + staggered joints (the photo's small square mosaic tiles)
    ring = 22
    k = 0
    for r in range(40, R, ring):
        d.ellipse([c - r, c - r, c + r, c + r], outline=JOINT, width=2)
        n = max(8, int(2 * math.pi * r / ring))
        off = 0.5 * (k % 2)
        for i in range(n):
            a = 2 * math.pi * (i + off) / n
            d.line([c + r * math.cos(a), c + r * math.sin(a), c + (r + ring) * math.cos(a), c + (r + ring) * math.sin(a)],
                   fill=JOINT, width=2)
        k += 1
    # gentle shading blotches (old plaster)
    sh = Image.new("L", (size, size), 0)
    sd = ImageDraw.Draw(sh)
    for _ in range(40):
        x, y, rr = rnd.randint(0, size), rnd.randint(0, size), rnd.randint(60, 220)
        sd.ellipse([x - rr, y - rr, x + rr, y + rr], fill=rnd.randint(8, 22))
    sh = sh.filter(ImageFilter.GaussianBlur(60))
    im = Image.composite(Image.new("RGB", (size, size), (118, 150, 166)), im, sh)
    d = ImageDraw.Draw(im)
    # the centre lamp fixture
    d.ellipse([c - 60, c - 60, c + 60, c + 60], fill=(96, 110, 116), outline=(70, 80, 86), width=6)

    def P(r, a):  # polar (fraction of R, degrees) -> canvas
        a = math.radians(a)
        return (c + r * R * math.cos(a), c + r * R * math.sin(a))

    def rot(pts, r, a, s, turn):
        """pts in a unit box (-1..1), placed at polar (r, a), scaled s px, turned `turn` deg."""
        x0, y0 = P(r, a)
        t = math.radians(turn)
        return [(x0 + s * (x * math.cos(t) - y * math.sin(t)), y0 + s * (x * math.sin(t) + y * math.cos(t))) for x, y in pts]

    def blob(r, a, s, turn, pts, fill, outline=(60, 60, 60)):
        d.polygon(rot(pts, r, a, s, turn), fill=fill, outline=outline)

    # constellation lines with star dots (white)
    def stars(r, a, s, turn, pts, closed=False):
        q = rot(pts, r, a, s, turn)
        seq = q + ([q[0]] if closed else [])
        d.line(seq, fill=(240, 240, 236), width=5)
        for x, y in q:
            d.ellipse([x - 9, y - 9, x + 9, y + 9], fill=(250, 250, 248), outline=(120, 120, 120), width=2)

    # stylised star-sign figures in a ring (our own shapes)
    elephant = [(-1, -.2), (-.8, -.6), (-.2, -.7), (.5, -.6), (.8, -.3), (1, .1), (.95, .6), (.85, .62), (.8, .2), (.6, .1),
                (.55, .7), (.4, .7), (.35, .3), (-.3, .3), (-.35, .7), (-.5, .7), (-.55, .3), (-.8, .25), (-.95, .1)]
    croc = [(-1, 0), (-.7, -.12), (-.3, -.18), (.2, -.2), (.6, -.12), (1, -.05), (.6, .05), (.2, .15), (-.3, .16), (-.7, .1)]
    horse = [(-.8, -.2), (-.5, -.4), (.3, -.35), (.55, -.8), (.8, -.75), (.7, -.4), (.6, .0), (.55, .7), (.45, .7), (.4, .1),
             (-.4, .1), (-.5, .7), (-.6, .7), (-.65, .05), (-.9, .3), (-.95, .2)]
    conch = [(-1, 0), (-.4, -.5), (.3, -.6), (.8, -.35), (1, 0), (.8, .3), (.3, .5), (-.4, .4)]
    fish = [(-1, 0), (-.6, -.35), (.2, -.35), (.6, -.05), (1, -.4), (.9, 0), (1, .4), (.6, .05), (.2, .35), (-.6, .35)]
    bird = [(-1, .2), (-.6, -.1), (-.2, -.15), (.1, -.6), (.3, -.65), (.25, -.2), (.7, -.1), (1, .1), (.6, .2), (-.2, .3)]
    rooster = [(-.6, .6), (-.7, 0), (-.4, -.5), (0, -.7), (.3, -.9), (.5, -.6), (.3, -.3), (.6, .2), (.2, .7)]
    house = [(-1, .5), (-1, -.1), (0, -.8), (1, -.1), (1, .5)]
    hat = [(-1, .4), (-.6, -.5), (0, -.9), (.6, -.5), (1, .4)]
    leaf = [(-1, 0), (-.4, -.6), (.4, -.7), (1, 0), (.4, .7), (-.4, .6)]
    flag = [(-1, -.1), (.2, -.1), (.9, -.6), (.6, .9), (.2, .1), (-1, .1)]
    figs = [  # (r, angle, size px, turn, shape, colour)
        (0.62, 200, 190, 10, elephant, WHITE), (0.80, 270, 300, 0, croc, DARKG), (0.70, 330, 150, 30, conch, WHITE),
        (0.55, 150, 120, -20, horse, CREAM), (0.62, 115, 150, 40, bird, WHITE), (0.80, 100, 140, 70, fish, (110, 118, 120)),
        (0.78, 70, 150, 20, hat, CREAM), (0.68, 45, 180, -30, flag, PINK), (0.72, 20, 90, 0, hat, (226, 214, 120)),
        (0.80, 140, 130, 10, house, CREAM), (0.62, 250, 110, 0, leaf, GREEN), (0.82, 35, 110, 0, rooster, BROWN),
        (0.30, 270, 90, 0, house, BROWN), (0.50, 10, 80, 0, leaf, (120, 140, 150)), (0.40, 300, 70, 0, fish, GOLD),
    ]
    for r, a, s, t, shp, col in figs:
        blob(r, a, s, t, shp, col)
    # an arrow and a trident (lines)
    x0, y0 = P(0.28, 300); x1, y1 = P(0.48, 285)
    d.line([x0, y0, x1, y1], fill=GOLD, width=14); d.polygon([(x1 - 22, y1 - 10), (x1 + 22, y1 - 10), (x1, y1 + 30)], fill=RED)
    x0, y0 = P(0.10, 90); x1, y1 = P(0.32, 90)
    d.line([x0, y0, x1, y1], fill=(90, 120, 110), width=12)
    d.line([x1 - 50, y1 - 30, x1, y1, x1 + 50, y1 - 30], fill=(90, 120, 110), width=12)
    # dotted constellations
    stars(0.45, 230, 110, 0, [(-1, -.3), (-.2, -.8), (.9, -.5), (.6, .6), (-.6, .4)], closed=True)
    stars(0.42, 330, 70, 0, [(math.cos(i * math.pi / 4), math.sin(i * math.pi / 4)) for i in range(8)], closed=True)
    stars(0.70, 180, 90, 0, [(-1, -1), (0, 0), (1, -1), (0, 0), (0, 1)])
    stars(0.58, 60, 100, 0, [(-1, .8), (-.6, -.6), (.4, -.9), (1, .2), (.3, .8)], closed=True)
    stars(0.50, 100, 60, 0, [(-1, 0), (-.4, -.6), (.3, -.7), (1, -.2)])
    stars(0.88, 220, 70, 0, [(-1, -1), (1, 1), (0, 0), (1, -1), (-1, 1)])
    # small star dots everywhere
    for _ in range(140):
        r, a = math.sqrt(rnd.random()) * 0.95, rnd.random() * 360
        x, y = P(r, a)
        d.ellipse([x - 6, y - 6, x + 6, y + 6], fill=(236, 236, 230), outline=(110, 110, 110), width=2)
    return im, c, R


def dome_uv_image(w=1024, h=512):
    """Resample the top-down canvas into the mesh's (u = angle / 360, v = polar fraction) layout."""
    can, c, R = dome()
    src = can.load()
    out = Image.new("RGB", (w, h))
    px = out.load()
    for y in range(h):
        rho = (y + 0.5) / h * R
        for x in range(w):
            a = 2 * math.pi * (x + 0.5) / w
            sx, sy = c + rho * math.cos(a), c + rho * math.sin(a)
            px[x, y] = src[int(sx), int(sy)]
    return out.filter(ImageFilter.SMOOTH)


def mural(w=1024, h=512):
    """One quarter of the chamber wall (repeated 4 times round, between the doorways): a painted forest, blue-teal haze
    above, far tree crowns, a green floor band. The big trunks are relief meshes in front of it."""
    W, H = 1824, 512
    im = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(im)
    for y in range(H):  # sky haze: deep teal at the top -> pale blue-green near the horizon
        t = y / H
        top, hz = (38, 80, 96), (110, 160, 160)
        col = tuple(int(top[i] + (hz[i] - top[i]) * min(1, t / 0.62)) for i in range(3))
        if t > 0.72:  # ground
            g0, g1 = (70, 112, 84), (52, 84, 66)
            u = (t - 0.72) / 0.28
            col = tuple(int(g0[i] + (g1[i] - g0[i]) * u) for i in range(3))
        d.line([0, y, W, y], fill=col)
    rnd = random.Random(3)
    # far tree crowns (soft dark teal blobs along the horizon)
    for layer, (col, y0, rr) in enumerate([((60, 104, 108), 300, 70), ((44, 86, 84), 330, 55)]):
        for _ in range(60):
            x = rnd.randint(-50, W + 50)
            r = rnd.randint(int(rr * 0.6), rr)
            d.ellipse([x - r, y0 - r * 1.2, x + r, y0 + r * 0.6], fill=col)
    # thin painted trunks in the distance
    for _ in range(26):
        x = rnd.randint(0, W)
        d.line([x, 380, x + rnd.randint(-10, 10), 250], fill=(96, 120, 116), width=rnd.randint(5, 10))
    # bushes along the ground
    for _ in range(50):
        x = rnd.randint(0, W)
        r = rnd.randint(14, 34)
        d.ellipse([x - r, 372 - r, x + r, 372 + r * 0.5], fill=(58, 98, 72))
    im = im.filter(ImageFilter.GaussianBlur(2))
    # tile seam: blend the two ends so the repeat does not show
    a = im.crop((0, 0, 60, H)); b = im.crop((W - 60, 0, W, H))
    m = Image.linear_gradient("L").rotate(90).resize((60, H))
    im.paste(Image.composite(a, b, m), (W - 60, 0))
    return im.resize((w, h), Image.LANCZOS)


def leaves(n=512):
    """Tiling leaf picture for the canopies (teal-green, lit tips and dark gaps)."""
    im = Image.new("RGB", (n, n), (22, 48, 42))
    d = ImageDraw.Draw(im)
    rnd = random.Random(11)
    cols = [(46, 98, 82), (62, 122, 100), (78, 142, 116), (96, 160, 128), (40, 84, 72), (120, 170, 130)]
    for _ in range(1500):
        x, y = rnd.random() * n, rnd.random() * n
        L, Wd = rnd.uniform(10, 18), rnd.uniform(5, 8)
        a = rnd.random() * math.pi
        col = cols[min(len(cols) - 1, int(rnd.random() ** 0.8 * len(cols)))]
        pts = []
        for k in range(10):
            t = 2 * math.pi * k / 10
            px, py = L * math.cos(t), Wd * math.sin(t) * (1 - 0.3 * math.cos(t))
            pts.append((px * math.cos(a) - py * math.sin(a), px * math.sin(a) + py * math.cos(a)))
        for ox in (-n, 0, n):
            for oy in (-n, 0, n):
                d.polygon([(x + ox + p, y + oy + q) for p, q in pts], fill=col, outline=(30, 60, 52))
    return im


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    dome_uv_image().save(os.path.join(OUT, "dome.png"))
    dome()[0].resize((1024, 1024), Image.LANCZOS).save(os.path.join(OUT, "dome_topdown_preview.png"))
    mural().save(os.path.join(OUT, "mural.png"))
    leaves().save(os.path.join(OUT, "leaves.png"))
    print("wrote", OUT)
