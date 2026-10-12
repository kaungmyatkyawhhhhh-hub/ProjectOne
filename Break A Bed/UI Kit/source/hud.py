import sys, math
from PIL import Image, ImageDraw, ImageFilter, ImageChops
from kit import box, label, sparkle, OUTLINE, S, mix, mask_rr, vgrad, studs
from preview import icon, paste
from products import dumbbell

def gloss(im):
    """3D shine on an icon: white highlight on the upper part, darker lower edge."""
    a = im.getchannel('A')
    w, h = im.size
    hl = Image.new('L', (w, h), 0)
    ImageDraw.Draw(hl).ellipse((w*0.08, h*0.02, w*0.75, h*0.42), fill=110)
    hl = hl.filter(ImageFilter.GaussianBlur(w*0.05))
    hl = ImageChops.multiply(hl, a.point(lambda v: 255 if v > 200 else 0))
    out = im.copy()
    out.alpha_composite(Image.merge('RGBA', [Image.new('L', (w, h), 255)]*3 + [hl]))
    return out

def basket(n):
    W = n * S
    im = Image.new('RGBA', (W, W), (0,0,0,0)); d = ImageDraw.Draw(im); ow = int(W*0.05)
    d.arc((W*0.24, W*0.06, W*0.76, W*0.62), 180, 360, fill=OUTLINE, width=int(ow*2.2))
    d.arc((W*0.24, W*0.06, W*0.76, W*0.62), 180, 360, fill=(255, 120, 130), width=int(ow*1.0))
    d.polygon([(W*0.08,W*0.36),(W*0.92,W*0.36),(W*0.8,W*0.9),(W*0.2,W*0.9)], fill=(235, 50, 70), outline=OUTLINE, width=ow)
    d.rectangle((W*0.05, W*0.32, W*0.95, W*0.44), fill=(255, 90, 105), outline=OUTLINE, width=ow)
    for x in (0.32, 0.5, 0.68):
        d.line((W*x, W*0.5, W*x, W*0.82), fill=(170, 25, 45), width=int(ow*0.9))
    return gloss(im.resize((n, n), Image.LANCZOS))

def hud_button(col, ic, text, n=128, badge=None):
    W = n
    im = Image.new('RGBA', (W, W + 30), (0,0,0,0))
    b = box(W, W, col, radius=0.16, outline=0.05, rim=0.035, lip=0.08, top_mix=0.35, bot_mix=0.05, stud_cell=12)
    im.alpha_composite(b, (0, 0))
    im.alpha_composite(ic, ((W - ic.width)//2, 2))
    label(im, (W/2, W - 14), text, 26)
    if badge:
        bd = box(40, 40, 'red', radius=0.2); label(bd, (20, 18), badge, 24)
        im.alpha_composite(bd, (W - 30, -2 + 0))
    return im

def light_panel(w, h):
    return box(w, h, (246, 247, 252), radius=0.22, outline=0.07, rim=0.06, rim_mix=0.8, lip=0.12, lip_mix=0.22, top_mix=0.0, bot_mix=0.08, stud_light=0, stud_dark=14, stud_cell=12)

def bar(w, h, v, col):
    im = Image.new('RGBA', (w, h), (0,0,0,0))
    im.alpha_composite(box(w, h, (205, 210, 222), pattern=False, radius=0.3, rim=0.0, lip=0.0, top_mix=0, bot_mix=0.1), (0, 0))
    fw = max(h, int(w*v))
    im.alpha_composite(box(fw, h, col, radius=0.3, lip=0.12, top_mix=0.35, stud_cell=8), (0, 0))
    return im

def stat(icon_im, value, col, w=330, h=70, barv=None, bartxt=None):
    im = Image.new('RGBA', (w + 30, h + 20), (0,0,0,0))
    im.alpha_composite(light_panel(w, h), (30, 10))
    if barv is not None:
        b = bar(w - 90, 34, barv, 'green'); label(b, (b.width/2, 15), bartxt, 20)
        im.alpha_composite(b, (100, 10 + 16))
    else:
        label(im, (w + 10, 10 + h/2 - 3), value, 38, fill=col, anchor='rm' if False else 'mm') if False else None
        f = label
        tw = P_font(38).getlength(value)
        f(im, (w + 12 - tw - 20, 10 + h/2 - 3), value, 38, fill=col, anchor='lm')
    im.alpha_composite(icon_im, (0, (h + 20 - icon_im.height)//2))
    return im

def P_font(sz):
    from kit import FONT
    from PIL import ImageFont
    return ImageFont.truetype(FONT, sz)

def lvl_badge():
    b = box(84, 84, 'yellow', radius=0.2, top_mix=0.35)
    label(b, (42, 22), 'LVL', 18); label(b, (42, 52), '1', 36)
    return b

def tutorial_card():
    w, h = 560, 140
    c = light_panel(w, h)
    label(c, (w/2, 40), 'PUNCH 10 TIMES!', 34, fill=(255, 150, 20))
    c.alpha_composite(gloss(icon('bolt', 64)), (22, 62))
    b = bar(w - 130, 44, 0.3, 'green'); label(b, (b.width/2, 19), '3 / 10', 26)
    c.alpha_composite(b, (96, 72))
    return c

def chevrons(w=640, h=110):
    im = Image.new('RGBA', (w, h), (0,0,0,0)); d = ImageDraw.Draw(im)
    for i in range(6):
        x = 30 + i * 100
        a = 255 - i * 25
        pts = [(x, 18), (x + 46, h/2), (x, h - 18), (x + 24, h - 18), (x + 70, h/2), (x + 24, 18)]
        d.polygon(pts, fill=(255, 255, 255, a))
    glow = im.filter(ImageFilter.GaussianBlur(8))
    tint = Image.new('RGBA', (w, h), (70, 220, 255, 0)); tint.putalpha(glow.getchannel('A'))
    out = Image.new('RGBA', (w, h), (0,0,0,0)); out.alpha_composite(tint); out.alpha_composite(tint); out.alpha_composite(im)
    return out

def chevron_tile(n=256):
    im = Image.new('RGBA', (n, n), (0,0,0,0)); d = ImageDraw.Draw(im)
    x = n*0.18
    d.polygon([(x, n*0.12), (x + n*0.42, n/2), (x, n*0.88), (x + n*0.24, n*0.88), (x + n*0.66, n/2), (x + n*0.24, n*0.12)], fill=(255,255,255,255))
    return im

def main(bgpath, out):
    W, H = 1600, 900
    bg = Image.open(bgpath).convert('RGBA').resize((W, H)).filter(ImageFilter.GaussianBlur(8))
    img = Image.blend(bg, Image.new('RGBA', (W, H), (30, 40, 60, 255)), 0.1)
    # left icon buttons
    btns = [('red', basket(96), 'SHOP', None), ('orange', gloss(dumbbell(100)), 'BOOST', None),
            ('purple', gloss(icon('wheel', 92)), 'SPIN', '1'), ('pink', gloss(icon('gift', 92)), 'GIFTS', '!')]
    for i, (col, ic, t, bd) in enumerate(btns):
        b = hud_button(col, ic, t, badge=bd)
        x = 30 + (i % 2) * 150; y = 250 + (i // 2) * 170
        img.alpha_composite(b, (x, y))
    # stats top right
    lv = Image.new('RGBA', (380, 104), (0,0,0,0))
    lv.alpha_composite(stat(Image.new('RGBA', (1, 1)), '', None, barv=0.25, bartxt='1 / 4'), (20, 0))
    lv.alpha_composite(lvl_badge(), (0, 10))
    img.alpha_composite(lv, (W - 410, 20))
    img.alpha_composite(stat(gloss(dumbbell(84)), '1.2K', (190, 120, 255)), (W - 390, 125))
    img.alpha_composite(stat(gloss(icon('cash', 84)), '$5,430', (90, 220, 70)), (W - 390, 215))
    # tutorial card
    paste(img, tutorial_card(), (W/2, 95))
    sk = box(110, 46, 'red', radius=0.25, top_mix=0.3); label(sk, (55, 20), 'SKIP', 22)
    img.alpha_composite(sk, (int(W/2 + 280 - 110), 175))
    # ground arrows
    ch = chevrons()
    persp = ch.transform((900, 220), Image.QUAD, (0, 0, 0, ch.height, ch.width, ch.height, ch.width, 0), Image.BICUBIC)
    img.alpha_composite(persp, (350, 650))
    label(img, (W/2, 590), 'Arrows on the ground point the way', 22)
    img.convert('RGB').save(out, quality=92)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
