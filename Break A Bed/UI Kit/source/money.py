import math, random, sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops, ImageFont
from kit import FONT, mix
import art

S = 4
OL = (16, 20, 14)
G1, G2, G3 = (120, 220, 70), (70, 175, 45), (35, 110, 30)   # light, mid, dark green
Y1, Y2 = (255, 225, 70), (235, 165, 20)

def outline(im, px):
    a = im.getchannel('A').point(lambda v: 255 if v > 60 else 0)
    big = a.filter(ImageFilter.GaussianBlur(px * 0.6)).point(lambda v: 255 if v > 8 else 0).filter(ImageFilter.GaussianBlur(1.5))
    o = Image.new('RGBA', im.size, OL + (0,)); o.putalpha(big); o.alpha_composite(im); return o

def bundle(w=600, h=300, thick=110, seed=0):
    """front-facing bundle: bill face on top, stacked edges below, yellow band."""
    rnd = random.Random(seed)
    W, H = w * S, (h + thick) * S
    im = Image.new('RGBA', (W, H + 40 * S), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    r = 16 * S; T = thick * S; fh = h * S
    # stacked edges (front face)
    d.rounded_rectangle((0, fh - r * 2, W, fh + T), r, fill=G3)
    n = 9
    for i in range(n):
        y = fh + T * i / n
        off = rnd.randint(-6, 6) * S
        d.rounded_rectangle((off + 4 * S, y - 2 * S, W + off - 4 * S, y + T / n - 3 * S), 6 * S, fill=mix(G2, G1, 0.3 if i % 2 else 0))
    # top bill face
    face = Image.new('RGBA', (W, fh), (0, 0, 0, 0)); fd = ImageDraw.Draw(face)
    fd.rounded_rectangle((0, 0, W - 1, fh - 1), r, fill=G1)
    g = Image.new('RGB', (W, fh)); gd = ImageDraw.Draw(g)
    for y in range(fh): gd.line((0, y, W, y), fill=mix((140, 230, 90), (90, 195, 60), y / fh))
    face.paste(g, (0, 0), face.getchannel('A'))
    fd.rounded_rectangle((W * .06, fh * .1, W * .94, fh * .9), r * .7, outline=G3, width=5 * S)
    cx, cy = W * .5, fh * .5; rr = fh * .26
    fd.ellipse((cx - rr * 1.25, cy - rr, cx + rr * 1.25, cy + rr), fill=(185, 245, 150), outline=G3, width=5 * S)
    f = ImageFont.truetype(FONT, int(fh * .42))
    fd.text((cx, cy + fh * .02), '$', font=f, anchor='mm', fill=G3)
    for x in (.16, .84):
        fd.ellipse((W * x - fh * .07, cy - fh * .07, W * x + fh * .07, cy + fh * .07), fill=(100, 200, 70), outline=G3, width=3 * S)
    im.alpha_composite(face, (0, 0))
    # band
    bx0, bx1 = W * .56, W * .72
    band = Image.new('RGBA', im.size, (0, 0, 0, 0)); bd = ImageDraw.Draw(band)
    bd.rectangle((bx0, 0, bx1, fh), fill=Y1); bd.rectangle((bx0, fh, bx1, fh + T), fill=Y2)
    bd.line((bx0 + 6 * S, 0, bx0 + 6 * S, fh), fill=(255, 245, 170), width=5 * S)
    m = Image.new('L', im.size, 0); ImageDraw.Draw(m).rounded_rectangle((0, 0, W, fh + T), r, fill=255)
    band.putalpha(ImageChops.multiply(band.getchannel('A'), m)); im.alpha_composite(band)
    # shine
    sh = Image.new('L', im.size, 0); ImageDraw.Draw(sh).polygon([(W * .08, fh * .08), (W * .28, fh * .08), (W * .14, fh * .85), (W * .04, fh * .85)], fill=70)
    im.alpha_composite(Image.merge('RGBA', [Image.new('L', im.size, 255)] * 3 + [ImageChops.multiply(sh.filter(ImageFilter.GaussianBlur(6 * S)), m)]))
    im = outline(im, 7 * S)
    im = im.resize((w, h + thick + 40), Image.LANCZOS)
    return im

def place(canvas, b, x, y, ang, scale=1.0):
    b = b.resize((int(b.width * scale), int(b.height * scale)), Image.LANCZOS).rotate(ang, expand=True, resample=Image.BICUBIC)
    canvas.alpha_composite(b, (int(x - b.width / 2), int(y - b.height / 2)))

def finish(c, n):
    c = outline(c, 16)
    bb = c.getbbox(); c = c.crop(bb)
    s = n / max(c.size); c = c.resize((int(c.width * s), int(c.height * s)), Image.LANCZOS)
    out = Image.new('RGBA', (n, n), (0, 0, 0, 0)); out.alpha_composite(c, ((n - c.width) // 2, (n - c.height) // 2)); return out

def cash1(n=512):
    c = Image.new('RGBA', (1200, 1200), (0, 0, 0, 0))
    place(c, bundle(seed=1), 600, 620, 14)
    return finish(c, n)

def cash2(n=512):
    c = Image.new('RGBA', (1300, 1300), (0, 0, 0, 0))
    place(c, bundle(seed=2), 640, 760, 10)
    place(c, bundle(seed=3), 660, 560, -6, 0.95)
    place(c, bundle(560, 260, 40, seed=4), 830, 760, 62, 0.75)
    return finish(c, n)

def cash3(n=512):
    c = Image.new('RGBA', (1500, 1500), (0, 0, 0, 0))
    for (x, y, a, s, sd) in ((560, 960, 8, 0.9, 1), (960, 980, -10, 0.9, 2), (760, 820, 4, 0.9, 3), (600, 640, -12, 0.85, 4), (920, 640, 12, 0.85, 5), (760, 470, -4, 0.85, 6)):
        place(c, bundle(seed=sd), x, y, a, s)
    return finish(c, n)

def bag(n=512):
    W = 1200; c = Image.new('RGBA', (W, W), (0, 0, 0, 0)); d = ImageDraw.Draw(c)
    # bills sticking out behind
    for k, (x, a) in enumerate(((450, 25), (560, -8), (680, 18), (770, -22))):
        place(c, bundle(420, 200, 30, seed=10 + k), x, 300, a, 0.75)
    body = Image.new('RGBA', (W, W), (0, 0, 0, 0)); bd = ImageDraw.Draw(body)
    bd.polygon([(400, 360), (800, 360), (760, 470), (950, 640), (980, 880), (860, 1060), (340, 1060), (220, 880), (250, 640), (440, 470)], fill=(240, 240, 228))
    body = body.filter(ImageFilter.GaussianBlur(14)); body.putalpha(body.getchannel('A').point(lambda v: 255 if v > 120 else 0))
    g = Image.new('RGB', (W, W)); gd = ImageDraw.Draw(g)
    for x in range(W): gd.line((x, 0, x, W), fill=mix((255, 255, 248), (195, 200, 185), abs(x - 520) / 520))
    c.alpha_composite(outline(Image.composite(g.convert('RGBA'), Image.new('RGBA', (W, W), (0,0,0,0)), body.getchannel('A')), 14))
    d = ImageDraw.Draw(c)
    d.line([(420, 460), (600, 500), (780, 460)], fill=(235, 185, 40), width=34)
    d.line([(600, 500), (560, 580)], fill=(235, 185, 40), width=26); d.line([(600, 500), (650, 585)], fill=(235, 185, 40), width=26)
    f = ImageFont.truetype(FONT, 330)
    d.text((610, 790), '$', font=f, anchor='mm', fill=(70, 160, 60))
    place(c, bundle(seed=20), 820, 950, -14, 0.55)
    return finish(c, n)

def safe(n=512):
    W = 1200; c = Image.new('RGBA', (W, W), (0, 0, 0, 0)); d = ImageDraw.Draw(c)
    d.rounded_rectangle((246, 206, 954, 1014), 56, fill=OL)
    d.rounded_rectangle((260, 220, 940, 1000), 50, fill=(60, 64, 74))
    d.rounded_rectangle((300, 260, 900, 960), 30, fill=(30, 32, 38))
    for k in range(5):
        place(c, bundle(420, 200, 40, seed=30 + k), 470 + (k % 2) * 220, 380 + (k // 2) * 200, (-1) ** k * 6, 0.6)
    door = Image.new('RGBA', (W, W), (0, 0, 0, 0)); dd = ImageDraw.Draw(door)
    dd.polygon([(900, 230), (1090, 300), (1090, 940), (900, 990)], fill=(90, 95, 108))
    dd.polygon([(900, 230), (930, 240), (930, 980), (900, 990)], fill=(50, 52, 60))
    dd.ellipse((960, 540, 1060, 700), fill=(240, 190, 40)); dd.ellipse((990, 585, 1030, 655), fill=(150, 100, 20))
    c.alpha_composite(door)
    for k in range(3):
        place(c, bundle(seed=40 + k), 420 + k * 200, 980, (-1) ** k * 12, 0.5)
    sh = Image.new('L', (W, W), 0); ImageDraw.Draw(sh).polygon([(280, 240), (420, 240), (300, 600)], fill=60)
    c.alpha_composite(Image.merge('RGBA', [Image.new('L', (W, W), 255)] * 3 + [sh.filter(ImageFilter.GaussianBlur(12))]))
    return finish(c, n)

if __name__ == '__main__':
    items = [cash1(), cash2(), cash3(), bag(), safe()]
    sheet = Image.new('RGBA', (len(items) * 330 + 10, 340), (60, 190, 60, 255))
    for i, im in enumerate(items): sheet.alpha_composite(im.resize((320, 320), Image.LANCZOS), (10 + i * 330, 10))
    sheet.convert('RGB').save('money_sheet.png')
