import math, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from kit import box, x_mark, OUTLINE, FONT, S, mix

def font(sz): return ImageFont.truetype(FONT, sz)

def text(img, c, s, size, fill=(255,255,255), anchor='mm', rot=0, stroke=None):
    f = font(size * S)
    sw = stroke or max(2, round(size * 0.16))
    tmp = Image.new('RGBA', (len(s) * size * S + 40 * S, size * 2 * S), (0,0,0,0))
    d = ImageDraw.Draw(tmp)
    cx, cy = tmp.width / 2, tmp.height / 2
    d.text((cx, cy + size * 0.10 * S), s, font=f, anchor='mm', fill=OUTLINE, stroke_width=sw * S, stroke_fill=OUTLINE)
    d.text((cx, cy), s, font=f, anchor='mm', fill=fill, stroke_width=sw * S, stroke_fill=OUTLINE)
    t = tmp.resize((tmp.width // S, tmp.height // S), Image.LANCZOS)
    if rot: t = t.rotate(rot, Image.BICUBIC, expand=True)
    if anchor == 'lm':
        bb = d.textbbox((cx, cy), s, font=f, anchor='mm', stroke_width=sw*S)
        w = (bb[2]-bb[0]) / S
        pos = (int(c[0] - t.width/2 + w/2), int(c[1] - t.height/2))
    else:
        pos = (int(c[0] - t.width/2), int(c[1] - t.height/2))
    img.alpha_composite(t, pos)

def paste(img, el, pos, rot=0):
    if rot: el = el.rotate(rot, Image.BICUBIC, expand=True)
    img.alpha_composite(el, (int(pos[0] - el.width/2), int(pos[1] - el.height/2)))

def icon(kind, n):
    W = n * S
    im = Image.new('RGBA', (W, W), (0,0,0,0))
    d = ImageDraw.Draw(im)
    ow = int(W * 0.06)
    def poly(pts, top, bot):
        pts = [(x*W, y*W) for x, y in pts]
        d.line(pts + [pts[0], pts[1]], fill=OUTLINE, width=ow*2, joint='curve')
        m = Image.new('L', (W, W), 0); ImageDraw.Draw(m).polygon(pts, fill=255)
        g = Image.new('RGB', (1, W))
        for y in range(W): g.putpixel((0, y), mix(top, bot, y / W))
        im.paste(g.resize((W, W)), (0, 0), m)
    if kind == 'star':
        pts = []
        for i in range(10):
            a = -math.pi/2 + i * math.pi/5
            r = 0.46 if i % 2 == 0 else 0.21
            pts.append((0.5 + r*math.cos(a), 0.53 + r*math.sin(a)))
        poly(pts, (255,236,80), (255,128,0))
    elif kind == 'bolt':
        poly([(0.58,0.04),(0.2,0.56),(0.47,0.56),(0.38,0.96),(0.8,0.40),(0.53,0.40),(0.66,0.04)], (255,250,140), (255,180,0))
    elif kind == 'cash':
        for dx, dy in ((0.04, 0.30), (-0.02, 0.42)):
            b = (W*(0.12+dx), W*(dy), W*(0.88+dx), W*(dy+0.36))
            d.rounded_rectangle(b, W*0.06, fill=(90,200,80), outline=OUTLINE, width=ow)
            d.rounded_rectangle((b[0]+W*0.07, b[1]+W*0.07, b[2]-W*0.07, b[3]-W*0.07), W*0.04, outline=(40,140,45), width=int(ow*0.6))
        c = (W*0.47, W*0.60); r = W*0.13
        d.ellipse((c[0]-r, c[1]-r, c[0]+r, c[1]+r), fill=(200,255,170), outline=OUTLINE, width=int(ow*0.8))
        d.text(c, '$', font=font(int(W*0.2)), anchor='mm', fill=(30,120,40))
    elif kind == 'wheel':
        b = (W*0.08, W*0.08, W*0.92, W*0.92)
        cols = [(255,80,90),(255,200,40),(80,210,90),(60,170,255),(190,110,255),(255,140,40)]
        d.ellipse(b, fill=OUTLINE)
        ib = (b[0]+ow, b[1]+ow, b[2]-ow, b[3]-ow)
        for i, c in enumerate(cols): d.pieslice(ib, i*60-90, i*60-30, fill=c)
        for i in range(6):
            a = math.radians(i*60-90)
            d.line((W/2, W/2, W/2 + W*0.4*math.cos(a), W/2 + W*0.4*math.sin(a)), fill=OUTLINE, width=int(ow*0.5))
        r = W*0.1; d.ellipse((W/2-r, W/2-r, W/2+r, W/2+r), fill=(255,255,255), outline=OUTLINE, width=int(ow*0.7))
        d.polygon([(W*0.42, W*0.0), (W*0.58, W*0.0), (W*0.5, W*0.16)], fill=(255,255,255), outline=OUTLINE, width=int(ow*0.5))
    elif kind == 'gift':
        d.rounded_rectangle((W*0.14, W*0.42, W*0.86, W*0.92), W*0.05, fill=(255,80,120), outline=OUTLINE, width=ow)
        d.rounded_rectangle((W*0.08, W*0.28, W*0.92, W*0.46), W*0.05, fill=(255,120,150), outline=OUTLINE, width=ow)
        d.rectangle((W*0.43, W*0.29, W*0.57, W*0.90), fill=(255,220,60))
        d.line((W*0.43, W*0.29, W*0.43, W*0.90), fill=OUTLINE, width=int(ow*0.5)); d.line((W*0.57, W*0.29, W*0.57, W*0.90), fill=OUTLINE, width=int(ow*0.5))
        for sx in (-1, 1):
            d.ellipse((W*(0.5+sx*0.2)-W*0.14, W*0.08, W*(0.5+sx*0.2)+W*0.14, W*0.30), fill=(255,220,60), outline=OUTLINE, width=int(ow*0.8))
    elif kind == 'robux':
        pts = [(0.5+0.44*math.cos(math.radians(a)), 0.5+0.44*math.sin(math.radians(a))) for a in range(-90, 270, 60)]
        pts = [(x*W, y*W) for x, y in pts]
        d.polygon(pts, fill=OUTLINE)
        inner = [(W/2+(x-W/2)*0.78, W/2+(y-W/2)*0.78) for x, y in pts]
        d.polygon(inner, fill=(255,255,255))
        hole = [(W/2+(x-W/2)*0.5, W/2+(y-W/2)*0.5) for x, y in pts]
        d.polygon(hole, fill=OUTLINE)
        s = W*0.1; d.rectangle((W/2-s, W/2-s, W/2+s, W/2+s), fill=(255,255,255))
    return im.resize((n, n), Image.LANCZOS)

def glow(n, col):
    g = Image.new('RGBA', (n, n), (0,0,0,0))
    ImageDraw.Draw(g).ellipse((n*0.15, n*0.15, n*0.85, n*0.85), fill=col + (170,))
    return g.filter(ImageFilter.GaussianBlur(n*0.12))

def price_btn(w, h, amount):
    b = box(w, h, 'green', cell=12)
    isz = int(h*0.5); fs = int(h*0.44)
    tw = font(fs).getlength(amount); gap = h*0.12
    x0 = w/2 - (isz + gap + tw)/2
    b.alpha_composite(icon('robux', isz), (int(x0), int(h*0.17)))
    text(b, (x0 + isz + gap, h*0.42), amount, fs, anchor='lm')
    return b

def main(bgpath, out):
    W, H = 1600, 900
    bg = Image.open(bgpath).convert('RGBA').resize((W, H)).filter(ImageFilter.GaussianBlur(14))
    img = Image.blend(bg, Image.new('RGBA', (W, H), (10, 15, 35, 255)), 0.35)

    # left side menu
    for i, (label, col) in enumerate([('Shop', 'pink'), ('x2 Power', 'orange'), ('Rewards', 'cyan'), ('Rebirth', 'blue')]):
        b = box(250, 66, col)
        text(b, (125, 30), label, 30)
        paste(img, b, (165, 250 + i*80))
    for i, (label, col, ic) in enumerate([('SPIN', 'purple', 'wheel'), ('GIFT', 'green', 'gift'), ('AUTO', 'blue', 'bolt')]):
        b = box(100, 100, col)
        b.alpha_composite(icon(ic, 66), (17, 10))
        x = 90 + i*112
        paste(img, b, (x, 630))
        text(img, (x, 676), label, 24)

    cx, wy = 935, 495
    tabs = [('Passes', 'red', -4), ('Boosts', 'green', -2), ('Cash', 'blue', 2), ('Free', 'pink', 4)]
    for i, (t, col, r) in enumerate(tabs):
        b = box(176, 60, col); text(b, (88, 27), t, 28)
        paste(img, b, (cx - 285 + i*190, 112), rot=r)
    win = box(780, 640, 'slate', radius=10, outline=7, lip=8, cell=16)
    paste(img, win, (cx, wy))
    hdr = box(780, 96, 'cyan', radius=8, outline=7, lip=7, cell=14)
    text(hdr, (40, 44), 'SHOP!', 48, anchor='lm')
    paste(img, hdr, (cx, wy - 320 + 48))
    paste(img, x_mark(box(86, 86, 'red')), (cx + 345, wy - 272))

    feat = box(730, 250, 'yellow', radius=8, outline=6, lip=7, cell=14)
    slot = box(250, 210, ((255, 236, 120), (255, 205, 40)), radius=8, outline=0, lip=0, cell=14)
    feat.alpha_composite(slot, (462, 14))
    feat.alpha_composite(glow(240, (255, 255, 255)), (465, -2))
    feat.alpha_composite(icon('star', 170), (502, 30))
    text(feat, (36, 50), 'VIP PACK', 50, fill=(255, 226, 40), anchor='lm')
    text(feat, (40, 100), '• x2 Cash forever', 22, anchor='lm')
    text(feat, (40, 130), '• VIP lounge + VIP post', 22, anchor='lm')
    feat.alpha_composite(price_btn(240, 66, '199'), (34, 160))
    paste(img, feat, (cx, wy - 104))

    cards = [('+3 Spins', 'wheel', '49'), ('x2 Strength', 'bolt', '79'), ('Cash Pack', 'cash', '99')]
    for i, (t, ic, p) in enumerate(cards):
        c = box(234, 262, 'cyan', radius=8, outline=6, lip=7, cell=14)
        c.alpha_composite(glow(170, (255, 255, 255)), (32, 34))
        c.alpha_composite(icon(ic, 130), (52, 54))
        text(c, (117, 30), t, 26)
        c.alpha_composite(price_btn(194, 54, p), (20, 194))
        paste(img, c, (cx - 248 + i*248, wy + 168))

    img.convert('RGB').save(out, quality=92)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
