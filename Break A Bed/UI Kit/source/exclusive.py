import sys, math, random
from PIL import Image, ImageDraw, ImageFilter
import art, aura2 as A, fx, kit, money
from kit import mix
random.seed(5)

def chest(n=600):
    W = n * 4; im = Image.new('RGBA', (W, W), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    P = lambda *pts: [(x * W, y * W) for x, y in pts]
    purple1, purple2 = (150, 60, 230), (70, 20, 140)
    gold1, gold2 = (255, 235, 120), (225, 140, 20)
    art.grad_poly(im, P((.12, .52), (.88, .52), (.84, .9), (.16, .9)), purple1, purple2)
    art.grad_poly(im, P((.12, .52), (.14, .34), (.26, .22), (.74, .22), (.86, .34), (.88, .52)), (175, 90, 250), (110, 40, 190))
    for poly in (P((.1, .5), (.9, .5), (.9, .56), (.1, .56)), P((.14, .86), (.86, .86), (.86, .92), (.14, .92)),
                 P((.1, .34), (.18, .26), (.2, .92), (.12, .92)), P((.82, .26), (.9, .34), (.88, .92), (.8, .92)),
                 P((.45, .22), (.55, .22), (.55, .92), (.45, .92))):
        art.grad_poly(im, poly, gold1, gold2)
    # gem lock + side gems
    d.polygon(P((.5, .48), (.58, .58), (.5, .7), (.42, .58)), fill=(255, 80, 200), outline=(120, 10, 80), width=int(W * .008))
    d.polygon(P((.5, .5), (.55, .58), (.5, .6), (.45, .58)), fill=(255, 190, 240))
    for x in (.3, .7):
        d.polygon(P((x, .64), (x + .04, .7), (x, .76), (x - .04, .7)), fill=(70, 220, 255), outline=(10, 80, 120), width=int(W * .006))
    # crown on top
    art.grad_poly(im, P((.36, .22), (.36, .1), (.43, .16), (.5, .05), (.57, .16), (.64, .1), (.64, .22)), gold1, gold2)
    for x, y in ((.36, .09), (.5, .04), (.64, .09)):
        r = W * .022; d.ellipse((W * x - r, W * y - r, W * x + r, W * y + r), fill=(255, 80, 200))
    # glowing runes
    for x, y in ((.28, .38), (.72, .38), (.3, .8), (.7, .8)):
        r = W * .025; d.ellipse((W * x - r, W * y - r, W * x + r, W * y + r), outline=(120, 255, 255), width=int(W * .006))
    sh = Image.new('L', (W, W), 0); ImageDraw.Draw(sh).polygon(P((.2, .3), (.3, .24), (.24, .86), (.18, .86)), fill=80)
    im.alpha_composite(Image.merge('RGBA', [Image.new('L', (W, W), 255)] * 3 + [sh.filter(ImageFilter.GaussianBlur(W * .01))]))
    im = art.outline(im, int(W * .016))
    return A.bloom(im.resize((n, n), Image.LANCZOS), n * .02, .35, 200)

def scene(bgpath, out):
    Wd, Hd = 1200, 1000
    bg = Image.open(bgpath).convert('RGBA').resize((Wd, Hd)).filter(ImageFilter.GaussianBlur(12))
    img = Image.blend(bg, Image.new('RGBA', (Wd, Hd), (40, 20, 70, 255)), 0.45)
    cx, cy = 600, 640
    # light pillar
    pil = Image.new('RGBA', (Wd, Hd), (0, 0, 0, 0)); ImageDraw.Draw(pil).polygon([(cx - 120, 0), (cx + 120, 0), (cx + 200, cy + 120), (cx - 200, cy + 120)], fill=(200, 120, 255, 70))
    img.alpha_composite(pil.filter(ImageFilter.GaussianBlur(30)))
    # rotating rays + rune circle on the ground
    img.alpha_composite(A.tint(kit.rays(900, 18, 140), (220, 150, 255), .7), (cx - 450, cy - 470))
    ring = Image.new('RGBA', (820, 300), (0, 0, 0, 0)); d = ImageDraw.Draw(ring)
    for k, (a, col) in enumerate(((0, (190, 90, 255)), (40, (255, 210, 80)), (90, (120, 240, 255)))):
        d.ellipse((a, a * .37, 820 - a, 300 - a * .37), outline=col + (230,), width=10 - k * 2)
    for i in range(12):
        t = i / 12 * 2 * math.pi; x, y = 410 + 360 * math.cos(t), 150 + 132 * math.sin(t)
        d.polygon([(x, y - 14), (x + 9, y), (x, y + 14), (x - 9, y)], fill=(255, 220, 120, 255))
    img.alpha_composite(ring.filter(ImageFilter.GaussianBlur(1)), (cx - 410, cy + 140))
    img.alpha_composite(A.tint(ring.filter(ImageFilter.GaussianBlur(14)), (200, 120, 255), .9), (cx - 410, cy + 140))
    # floating chest
    c = chest(440); img.alpha_composite(c, (cx - 220, cy - 260))
    # orbiting gems & sparkles
    for i in range(10):
        t = i / 10 * 2 * math.pi; x, y = cx + 300 * math.cos(t), cy - 30 + 90 * math.sin(t)
        s = random.randint(26, 52); img.alpha_composite(fx.star4().resize((s, s)), (int(x - s / 2), int(y - s / 2)))
    for i in range(30):
        x, y, s = random.uniform(cx - 260, cx + 260), random.uniform(80, cy + 200), random.randint(6, 16)
        img.alpha_composite(A.tint(fx.glow().resize((s * 3, s * 3)), random.choice([(220, 150, 255), (255, 220, 120), (120, 240, 255)]), .9), (int(x), int(y)))
    # title
    A.stroke_text(img, (cx, 120), 'EXCLUSIVE CHEST', 86, (255, 240, 140), (255, 150, 20), anchor='mm')
    A.stroke_text(img, (cx, 205), 'Like  •  Favorite  •  Join', 40, (225, 180, 255), (170, 100, 255), anchor='mm')
    A.stroke_text(img, (cx, 930), 'Next chest in 14:59', 38, (255, 255, 255), (230, 230, 240), anchor='mm')
    img = A.bloom(img, 10, .3, 210)
    img.convert('RGB').save(out, quality=92)

if __name__ == '__main__':
    scene(sys.argv[1], 'exclusive.png')
