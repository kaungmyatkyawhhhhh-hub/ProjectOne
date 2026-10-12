import sys
from PIL import Image, ImageDraw, ImageFilter
from kit import box, window, label, x_mark, sparkle, rays, OUTLINE, S, mix
from preview import icon, glow, paste, price_btn

def check(n):
    W = n * S
    im = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    pts = [(W*0.12, W*0.52), (W*0.40, W*0.80), (W*0.90, W*0.22)]
    d.line(pts, fill=OUTLINE, width=int(W*0.26), joint='curve')
    for p in (pts[0], pts[2]):
        r = W*0.13; d.ellipse((p[0]-r, p[1]-r, p[0]+r, p[1]+r), fill=OUTLINE)
    d.line(pts, fill=(120, 240, 90), width=int(W*0.14), joint='curve')
    for p in (pts[0], pts[2]):
        r = W*0.07; d.ellipse((p[0]-r, p[1]-r, p[0]+r, p[1]+r), fill=(120, 240, 90))
    return im.resize((n, n), Image.LANCZOS)

def dumbbell(n):
    W = n * S
    im = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    ow = int(W*0.05)
    d.rectangle((W*0.2, W*0.44, W*0.8, W*0.56), fill=(200, 205, 215), outline=OUTLINE, width=ow)
    for x0 in (0.08, 0.72):
        d.rectangle((W*x0, W*0.24, W*(x0+0.2), W*0.76), fill=(70, 80, 100), outline=OUTLINE, width=ow)
        d.rectangle((W*(x0+0.04), W*0.30, W*(x0+0.08), W*0.70), fill=(120, 130, 150))
    return im.resize((n, n), Image.LANCZOS)

REWARDS = [  # name, icon, card colour, time
    ('Small Cash', 'cash', 'slate', '00:00', 'claimed'),
    ('+1 Spin', 'wheel', 'green', '00:00', 'claimed'),
    ('x2 Strength 5m', 'bolt', 'purple', 'CLAIM!', 'ready'),
    ('Strength Pack', 'dumbbell', 'cyan', '04:27', 'wait'),
    ('Medium Cash', 'cash', 'yellow', '06:27', 'wait'),
    ('+3 Spins', 'wheel', 'slate', '11:27', 'wait'),
    ('+1 Level', 'star', 'green', '16:27', 'wait'),
    ('x2 Cash 10m', 'bolt', 'cyan', '21:27', 'wait'),
    ('Big Cash', 'cash', 'pink', '26:27', 'wait'),
    ('Big Strength', 'dumbbell', 'purple', '41:27', 'wait'),
    ('+5 Spins', 'wheel', 'cyan', '56:27', 'wait'),
    ('MEGA Gift', 'gift', 'orange', '1:26:27', 'wait'),
]

def main(bgpath, out):
    Wd, Hd = 1600, 900
    bg = Image.open(bgpath).convert('RGBA').resize((Wd, Hd)).filter(ImageFilter.GaussianBlur(10))
    img = Image.blend(bg, Image.new('RGBA', (Wd, Hd), (10, 15, 35, 255)), 0.2)
    cx, cy = 800, 462
    ww, wh = 900, 800
    paste(img, rays(1700, 14, 170), (cx, cy))
    paste(img, window(ww, wh), (cx, cy))
    top = cy - wh/2
    hdr = box(ww - 96, 96, 'cyan')
    label(hdr, (126, 44), 'FREE GIFTS', 46, anchor='lm')
    paste(img, hdr, (cx - 48, top + 48))
    img.alpha_composite(icon('gift', 110), (int(cx - ww/2 + 10), int(top - 14)))
    paste(img, x_mark(box(96, 96, 'red')), (cx + ww/2 - 48, top + 48))

    gap, pad = 14, 22
    cw = (ww - 2*pad - 3*gap) // 4
    ch = 140
    y0 = top + 96 + 16
    for i, (name, ic, col, t, state) in enumerate(REWARDS):
        r, c = divmod(i, 4)
        card = box(cw, ch, col)
        card.alpha_composite(glow(120, (255, 255, 255), 120), (cw//2 - 60, -10))
        icn = dumbbell(72) if ic == 'dumbbell' else icon(ic, 72)
        card.alpha_composite(icn, (cw//2 - 36, 12))
        if state == 'ready':
            for sx, sy, sz in ((cw//2 - 50, 20, 24), (cw//2 + 48, 72, 18), (cw//2 + 42, 14, 14)):
                card.alpha_composite(sparkle(sz), (sx - sz//2, sy - sz//2))
        label(card, (cw/2, 102), name, 19)
        if state == 'claimed':
            dim = Image.new('RGBA', card.size, (20, 22, 30, 140))
            m = card.getchannel('A'); dim.putalpha(Image.eval(m, lambda a: a * 140 // 255))
            card.alpha_composite(dim)
            card.alpha_composite(check(66), (cw//2 - 33, 16))
        x = cx - ww/2 + pad + c*(cw + gap)
        y = y0 + r*(ch + 42 + gap)
        img.alpha_composite(card, (int(x), int(y)))
        if state == 'ready':
            bar = box(cw, 46, 'green')
        else:
            bar = box(cw, 46, (40, 130, 48), stud_cell=10)
        label(bar, (cw/2, 20), 'CLAIMED' if state == 'claimed' else t, 22)
        img.alpha_composite(bar, (int(x), int(y + ch - 4)))

    by = top + wh - 44
    label(img, (cx - ww/2 + 30, by), 'Leaving resets gifts!', 26, fill=(255, 80, 80), anchor='lm')
    sk = box(270, 64, 'green', stud_cell=10)
    from preview import font
    from kit import label as L
    sk.alpha_composite(icon('robux', 32), (24, 13))
    L(sk, (66, 29), 'SKIP ALL 99', 24, anchor='lm')
    paste(img, sk, (cx + ww/2 - 22 - 135, by))

    # HUD gift button with timer (right side of screen)
    hb = box(110, 110, 'green'); hb.alpha_composite(icon('gift', 74), (18, 10))
    paste(img, hb, (1480, 640))
    label(img, (1480, 712), '04:27', 26)
    bd = box(44, 44, 'red'); label(bd, (22, 20), '1', 24)
    paste(img, bd, (1530, 590))
    img.convert('RGB').save(out, quality=92)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
