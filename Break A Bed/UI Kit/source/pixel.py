import sys, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops
from kit import OUTLINE, S, mix, mask_rr, vgrad, label as mlabel
from preview import icon
from products import dumbbell
from hud import basket, gloss, chevrons

PFONT = os.path.join(os.path.dirname(__file__), '..', 'fonts', 'PressStart2P.ttf')
# (top, bottom) like the reference: strong colour on top, lighter at the bottom
PCOL = {
    'red':    ((236, 30, 52), (255, 120, 132)),
    'orange': ((250, 120, 10), (255, 190, 90)),
    'purple': ((140, 50, 225), (205, 140, 255)),
    'pink':   ((225, 30, 175), (255, 130, 220)),
    'green':  ((40, 175, 40), (130, 235, 100)),
    'blue':   ((25, 110, 225), (110, 185, 255)),
    'cyan':   ((10, 170, 230), (110, 225, 255)),
    'yellow': ((250, 185, 0), (255, 235, 110)),
    'light':  ((235, 238, 246), (255, 255, 255)),
}

def diamonds(size, cell, alpha):
    lay = Image.new('RGBA', size, (0, 0, 0, 0)); d = ImageDraw.Draw(lay)
    w, h = size; r = cell / 2
    for gy in range(-1, int(h / cell) + 2):
        for gx in range(-1, int(w / cell) + 2):
            if (gx + gy) % 2: continue
            cx, cy = gx * cell, gy * cell
            d.polygon([(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)], fill=(255, 255, 255, alpha))
    return lay

def pbtn(w, h, col, radius=0.12, pat=True, dark_pat=False):
    top, bot = PCOL[col]
    W, H = w * S, h * S
    m = min(w, h)
    rad = max(3, m * radius) * S
    ow = max(3, round(m * 0.06)) * S
    inner = max(2, round(m * 0.045)) * S
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    img.paste(OUTLINE + (255,), (0, 0, W, H), mask_rr((W, H), (0, 0, W - 1, H - 1), rad))
    b1 = (ow, ow, W - 1 - ow, H - 1 - ow)
    img.paste(mix(top, (255, 255, 255), 0.55) + (255,), (0, 0, W, H), mask_rr((W, H), b1, rad - ow))
    face = (b1[0] + inner, b1[1] + inner, b1[2] - inner, b1[3] - inner)
    fm = mask_rr((W, H), face, max(1, rad - ow - inner))
    img.paste(vgrad((W, H), top, bot, face[1], face[3]), (0, 0), fm)
    if pat:
        p = diamonds((W, H), 16 * S, 34 if not dark_pat else 0)
        if dark_pat:
            p = diamonds((W, H), 16 * S, 0); dp = Image.new('RGBA', (W, H), (0, 0, 0, 0))
            dd = diamonds((W, H), 16 * S, 22); dp = Image.merge('RGBA', [Image.new('L', (W, H), 120)] * 3 + [dd.getchannel('A')]); p = dp
        p.putalpha(ImageChops.multiply(p.getchannel('A'), fm)); img.alpha_composite(p)
    # glossy top band
    gl = Image.new('L', (W, H), 0)
    ImageDraw.Draw(gl).rounded_rectangle((face[0] + inner, face[1] + inner * 0.6, face[2] - inner, face[1] + (face[3] - face[1]) * 0.4), rad, fill=55)
    gl = ImageChops.multiply(gl.filter(ImageFilter.GaussianBlur(inner)), fm)
    img.alpha_composite(Image.merge('RGBA', [Image.new('L', (W, H), 255)] * 3 + [gl]))
    return img.resize((w, h), Image.LANCZOS)

import pixtext
def ptext(img, xy, s, size, fill=(255, 255, 255), anchor='lm'):
    pixtext.put(img, (xy[0], xy[1]), s, size * 1.7, fill=fill, anchor=anchor)

def wide(col, ic, text, w=320, h=92, tsize=26):
    b = pbtn(w, h, col)
    b.alpha_composite(ic, (8, (h - ic.height) // 2 - 3))
    while pixtext.render(text, max(1, round(tsize * 1.7 / 20))).width > w - ic.width - 34 and tsize > 8: tsize -= 2
    ptext(b, (ic.width + 20, h / 2 - 3), text, tsize)
    return b

def bar(w, h, v, col):
    im = pbtn(w, h, 'light', radius=0.25, pat=False)
    fw = max(h, int(w * v))
    im.alpha_composite(pbtn(fw, h, col, radius=0.25), (0, 0))
    return im

def stat(ic, value, col, w=330, h=72):
    im = Image.new('RGBA', (w + 30, h + 20), (0, 0, 0, 0))
    im.alpha_composite(pbtn(w, h, 'light', dark_pat=True), (30, 10))
    ptext(im, (w + 14, 10 + h / 2 - 2), value, 26, fill=col, anchor='rm')
    im.alpha_composite(ic, (0, (h + 20 - ic.height) // 2))
    return im

def main(bgpath, out):
    W, H = 1600, 900
    bg = Image.open(bgpath).convert('RGBA').resize((W, H)).filter(ImageFilter.GaussianBlur(8))
    img = Image.blend(bg, Image.new('RGBA', (W, H), (30, 40, 60, 255)), 0.1)
    rows = [('red', basket(78), 'Shop'), ('orange', gloss(dumbbell(78)), 'Boost'),
            ('purple', gloss(icon('wheel', 72)), 'Spin'), ('pink', gloss(icon('gift', 72)), 'Gifts')]
    for i, (c, ic, t) in enumerate(rows):
        img.alpha_composite(wide(c, ic, t), (28, 240 + i * 106))
    tag = pbtn(110, 40, 'green', radius=0.25); ptext(tag, (55, 19), 'R$19', 14, anchor='mm')
    img.alpha_composite(tag, (228, 240 + 106 + 66))
    # stats (light)
    lv = Image.new('RGBA', (400, 110), (0, 0, 0, 0))
    lp = pbtn(330, 72, 'light', dark_pat=True); lv.alpha_composite(lp, (50, 18))
    b = bar(230, 34, 0.25, 'green'); ptext(b, (115, 16), '1/4', 15, anchor='mm'); lv.alpha_composite(b, (130, 37))
    badge = pbtn(92, 92, 'yellow'); ptext(badge, (46, 30), 'LVL', 14, anchor='mm'); ptext(badge, (46, 60), '1', 26, anchor='mm')
    lv.alpha_composite(badge, (8, 8))
    img.alpha_composite(lv, (W - 420, 18))
    img.alpha_composite(stat(gloss(dumbbell(80)), '1.2K', (180, 110, 255)), (W - 390, 130))
    img.alpha_composite(stat(gloss(icon('cash', 80)), '$5,430', (80, 210, 60)), (W - 390, 222))
    # tutorial (light)
    tc = pbtn(560, 136, 'light', dark_pat=True)
    ptext(tc, (280, 40), 'PUNCH 10 TIMES!', 22, fill=(255, 150, 20), anchor='mm')
    tc.alpha_composite(gloss(icon('bolt', 60)), (22, 62))
    tb = bar(430, 42, 0.3, 'green'); ptext(tb, (215, 20), '3/10', 17, anchor='mm'); tc.alpha_composite(tb, (100, 72))
    img.alpha_composite(tc, (int(W / 2 - 280), 24))
    sk = pbtn(120, 46, 'red', radius=0.25); ptext(sk, (60, 22), 'SKIP', 14, anchor='mm')
    img.alpha_composite(sk, (int(W / 2 + 280 - 120), 168))
    # ground arrows
    ch = chevrons()
    persp = ch.transform((900, 220), Image.QUAD, (0, 0, 0, ch.height, ch.width, ch.height, ch.width, 0), Image.BICUBIC)
    img.alpha_composite(persp, (350, 650))
    img.convert('RGB').save(out, quality=92)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
