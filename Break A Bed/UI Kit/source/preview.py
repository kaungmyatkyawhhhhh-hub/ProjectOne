import math, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from kit import box, window, label, x_mark, OUTLINE, FONT, S, mix, mask_rr

def font(sz): return ImageFont.truetype(FONT, sz)

def paste(img, el, pos, rot=0):
    if rot: el = el.rotate(rot, Image.BICUBIC, expand=True)
    img.alpha_composite(el, (int(pos[0] - el.width/2), int(pos[1] - el.height/2)))

def icon(kind, n):
    W = n * S
    im = Image.new('RGBA', (W, W), (0,0,0,0))
    d = ImageDraw.Draw(im)
    ow = int(W * 0.055)
    def poly(pts, top, bot):
        pts = [(x*W, y*W) for x, y in pts]
        d.line(pts + [pts[0], pts[1]], fill=OUTLINE, width=ow*2, joint='curve')
        m = Image.new('L', (W, W), 0); ImageDraw.Draw(m).polygon(pts, fill=255)
        g = Image.new('RGB', (1, W))
        for y in range(W): g.putpixel((0, y), mix(top, bot, y / W))
        im.paste(g.resize((W, W)), (0, 0), m)
    if kind == 'star':
        pts = [(0.5 + (0.46 if i % 2 == 0 else 0.21)*math.cos(-math.pi/2 + i*math.pi/5), 0.53 + (0.46 if i % 2 == 0 else 0.21)*math.sin(-math.pi/2 + i*math.pi/5)) for i in range(10)]
        poly(pts, (255,236,80), (255,128,0))
    elif kind == 'bolt':
        poly([(0.58,0.04),(0.2,0.56),(0.47,0.56),(0.38,0.96),(0.8,0.40),(0.53,0.40),(0.66,0.04)], (255,250,140), (255,180,0))
    elif kind == 'cash':
        for dx, dy in ((0.04, 0.30), (-0.02, 0.42)):
            b = (W*(0.12+dx), W*dy, W*(0.88+dx), W*(dy+0.36))
            d.rectangle(b, fill=(90,200,80), outline=OUTLINE, width=ow)
            d.rectangle((b[0]+W*0.07, b[1]+W*0.07, b[2]-W*0.07, b[3]-W*0.07), outline=(40,140,45), width=int(ow*0.6))
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
        d.polygon([(W*0.42, 0), (W*0.58, 0), (W*0.5, W*0.16)], fill=(255,255,255), outline=OUTLINE, width=int(ow*0.5))
    elif kind == 'gift':
        d.rectangle((W*0.14, W*0.42, W*0.86, W*0.92), fill=(255,80,120), outline=OUTLINE, width=ow)
        d.rectangle((W*0.08, W*0.28, W*0.92, W*0.46), fill=(255,120,150), outline=OUTLINE, width=ow)
        d.rectangle((W*0.43, W*0.29, W*0.57, W*0.90), fill=(255,220,60))
        d.line((W*0.43, W*0.29, W*0.43, W*0.90), fill=OUTLINE, width=int(ow*0.5)); d.line((W*0.57, W*0.29, W*0.57, W*0.90), fill=OUTLINE, width=int(ow*0.5))
        for sx in (-1, 1):
            d.ellipse((W*(0.5+sx*0.2)-W*0.14, W*0.08, W*(0.5+sx*0.2)+W*0.14, W*0.30), fill=(255,220,60), outline=OUTLINE, width=int(ow*0.8))
    elif kind == 'robux':
        pts = [(W/2+W*0.44*math.cos(math.radians(a)), W/2+W*0.44*math.sin(math.radians(a))) for a in range(-90, 270, 60)]
        d.polygon(pts, fill=OUTLINE)
        d.polygon([(W/2+(x-W/2)*0.8, W/2+(y-W/2)*0.8) for x, y in pts], fill=(255,255,255))
        d.polygon([(W/2+(x-W/2)*0.52, W/2+(y-W/2)*0.52) for x, y in pts], fill=OUTLINE)
        d.polygon([(W/2+(x-W/2)*0.3, W/2+(y-W/2)*0.3) for x, y in pts], fill=(255,255,255))
    return im.resize((n, n), Image.LANCZOS)

def glow(n, col, a=150):
    g = Image.new('RGBA', (n, n), (0,0,0,0))
    ImageDraw.Draw(g).ellipse((n*0.15, n*0.15, n*0.85, n*0.85), fill=col + (a,))
    return g.filter(ImageFilter.GaussianBlur(n*0.12))

def price_btn(w, h, amount):
    b = box(w, h, 'green', stud_cell=10)
    isz = int(h*0.5); fs = int(h*0.42)
    tw = font(fs).getlength(amount); gap = h*0.14
    x0 = w/2 - (isz + gap + tw)/2
    b.alpha_composite(icon('robux', isz), (int(x0), int(h*0.16)))
    label(b, (x0 + isz + gap, h*0.41), amount, fs, anchor='lm')
    return b

def main(bgpath, out):
    W, H = 1600, 900
    bg = Image.open(bgpath).convert('RGBA').resize((W, H)).filter(ImageFilter.GaussianBlur(10))
    img = Image.blend(bg, Image.new('RGBA', (W, H), (10, 15, 35, 255)), 0.2)

    for i, (t, col) in enumerate([('Shop', 'pink'), ('x2 Power', 'orange'), ('Rewards', 'cyan'), ('Rebirth', 'blue')]):
        b = box(250, 64, col); label(b, (125, 29), t, 28)
        paste(img, b, (165, 250 + i*78))
    for i, (t, col, ic) in enumerate([('SPIN', 'purple', 'wheel'), ('GIFT', 'green', 'gift'), ('AUTO', 'blue', 'bolt')]):
        b = box(100, 100, col); b.alpha_composite(icon(ic, 66), (17, 10))
        x = 90 + i*112
        paste(img, b, (x, 625)); label(img, (x, 672), t, 22)

    cx, cy = 935, 505
    for i, (t, col, r) in enumerate([('Passes', 'red', -4), ('Boosts', 'green', -2), ('Cash', 'blue', 2), ('Free', 'pink', 4)]):
        b = box(176, 58, col); label(b, (88, 26), t, 26)
        paste(img, b, (cx - 285 + i*190, 112), rot=r)
    ww, wh = 790, 650
    paste(img, window(ww, wh), (cx, cy))
    top = cy - wh/2
    hdr = box(ww - 90, 92, 'cyan'); label(hdr, (36, 42), 'SHOP!', 46, anchor='lm')
    paste(img, hdr, (cx - 45, top + 46))
    paste(img, x_mark(box(92, 92, 'red')), (cx + ww/2 - 46, top + 46))

    feat = box(ww - 44, 250, 'yellow')
    fw = feat.width
    slot = Image.new('RGBA', (240, 214), (0,0,0,0))
    ImageDraw.Draw(slot).rounded_rectangle((0, 0, 239, 213), 46, fill=(255, 240, 120, 255), outline=(255, 250, 190, 255), width=6)
    feat.alpha_composite(slot, (fw - 262, 12))
    feat.alpha_composite(glow(230, (255, 255, 255)), (fw - 257, 4))
    feat.alpha_composite(icon('star', 165), (fw - 224, 34))
    label(feat, (30, 48), 'VIP PACK', 48, fill=(255, 226, 12), anchor='lm')
    label(feat, (34, 98), '• x2 Cash forever', 20, anchor='lm')
    label(feat, (34, 126), '• VIP lounge + VIP post', 20, anchor='lm')
    feat.alpha_composite(price_btn(250, 68, '199'), (28, 154))
    paste(img, feat, (cx, top + 92 + 14 + 125))

    cw = (ww - 44 - 2*14) // 3
    for i, (t, ic, p) in enumerate([('+3 Spins', 'wheel', '49'), ('x2 Strength', 'bolt', '79'), ('Cash Pack', 'cash', '99')]):
        c = box(cw, 262, 'cyan')
        c.alpha_composite(glow(170, (255, 255, 255)), (cw//2 - 85, 34))
        c.alpha_composite(icon(ic, 130), (cw//2 - 65, 54))
        label(c, (cw/2, 30), t, 24)
        c.alpha_composite(price_btn(cw - 36, 56, p), (18, 190))
        paste(img, c, (cx - ww/2 + 22 + cw/2 + i*(cw + 14), top + 92 + 14 + 250 + 14 + 131))

    img.convert('RGB').save(out, quality=92)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
