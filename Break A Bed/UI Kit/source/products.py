import sys, os
from PIL import Image, ImageDraw, ImageFilter
from kit import box, label, sparkle, soft_glow, rays, OUTLINE, S
from preview import icon
from kit import mix, FONT
from PIL import ImageFont

def dumbbell(n, plate=(220, 40, 55)):
    W = n * S
    im = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    ow = int(W * 0.04)
    d.rounded_rectangle((W*0.08, W*0.44, W*0.92, W*0.56), W*0.03, fill=(255, 205, 60), outline=OUTLINE, width=ow)
    d.rectangle((W*0.16, W*0.465, W*0.84, W*0.49), fill=(255, 240, 160))
    for side in (-1, 1):
        for k, (hh, ww2) in enumerate(((0.66, 0.15), (0.48, 0.11))):
            cxp = 0.5 + side * (0.21 + k * 0.13)
            x0, x1 = W*(cxp - ww2/2), W*(cxp + ww2/2)
            y0, y1 = W*(0.5 - hh/2), W*(0.5 + hh/2)
            d.rounded_rectangle((x0, y0, x1, y1), W*0.025, fill=plate, outline=OUTLINE, width=ow)
            d.rectangle((x0 + ow*1.4, y0 + ow*1.4, x0 + ow*2.6, y1 - ow*1.4), fill=mix(plate, (255, 255, 255), 0.35))
    return im.resize((n, n), Image.LANCZOS)

N = 512
YEL = (255, 226, 12)

def ic(kind, n):
    return dumbbell(n) if kind == 'dumbbell' else icon(kind, n)

def make(bg, kind, big=None, small=None, kind2=None, bigcol=YEL):
    im = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    im.alpha_composite(box(N, N, bg, radius=0.08, outline=0.035, rim=0.025, lip=0.05, stud_cell=22))
    r = rays(N, 12, 110)
    m = Image.new('L', (N, N), 0); ImageDraw.Draw(m).rounded_rectangle((20, 20, N-21, N-40), 30, fill=255)
    r.putalpha(Image.eval(Image.composite(r.getchannel('A'), Image.new('L', (N, N), 0), m), lambda a: a))
    im.alpha_composite(r)
    im.alpha_composite(soft_glow(380, 200), (66, 50))
    isz = 240 if big else 300
    y = 38 if big else 70
    im.alpha_composite(ic(kind, isz), ((N - isz) // 2 - (40 if kind2 else 0), y))
    if kind2:
        im.alpha_composite(ic(kind2, 150), (300, y + 90))
    for sx, sy, sz in ((110, 120, 54), (400, 110, 40), (420, 300, 34), (96, 330, 30)):
        im.alpha_composite(sparkle(sz), (sx - sz // 2, sy - sz // 2))
    if big:
        fs = 112
        while ImageFont.truetype(FONT, fs).getlength(big) > 380: fs -= 4
        label(im, (N / 2, 318), big, fs, fill=bigcol)
    if small:
        rb = box(300, 70, 'red' if small.endswith('MIN') else 'blue', stud_cell=12)
        label(rb, (150, 31), small, 36)
        im.alpha_composite(rb, ((N - 300) // 2, N - 116))
    return im

ITEMS = [
    ('x3-strength-10min', dict(bg='purple', kind='dumbbell', big='x3', small='10 MIN')),
    ('x5-strength-10min', dict(bg='purple', kind='dumbbell', big='x5', small='10 MIN')),
    ('x10-strength-10min', dict(bg='purple', kind='dumbbell', big='x10', small='10 MIN')),
    ('x3-cash-10min', dict(bg='green', kind='cash', big='x3', small='10 MIN')),
    ('x5-cash-10min', dict(bg='green', kind='cash', big='x5', small='10 MIN')),
    ('fast-punch-10min', dict(bg='orange', kind='bolt', big='FAST', small='10 MIN')),
    ('server-x2-strength', dict(bg='red', kind='dumbbell', big='x2', small='SERVER', kind2='star')),
    ('small-cash', dict(bg='green', kind='cash', small='SMALL')),
    ('small-strength', dict(bg='cyan', kind='dumbbell', small='SMALL')),
    ('medium-strength', dict(bg='cyan', kind='dumbbell', small='MEDIUM', kind2='bolt')),
    ('big-strength', dict(bg='cyan', kind='dumbbell', big='BIG', small='STRENGTH', kind2='bolt')),
    ('plus1-spin', dict(bg='pink', kind='wheel', big='+1', small='SPIN')),
    ('instant-break', dict(bg='red', kind='bolt', big='BREAK!', small='INSTANT')),
    ('starter-pack', dict(bg='yellow', kind='gift', big='STARTER', small='ONE TIME', bigcol=(255, 255, 255))),
    ('skip-all-gifts', dict(bg='orange', kind='gift', big='SKIP', small='ALL GIFTS')),
]

if __name__ == '__main__':
    out = sys.argv[1]; os.makedirs(out, exist_ok=True)
    tiles = []
    for name, kw in ITEMS:
        im = make(**kw); im.save(f'{out}/{name}.png'); tiles.append(im)
    sheet = Image.new('RGBA', (5 * 270 + 10, 3 * 270 + 10), (24, 26, 34, 255))
    for i, t in enumerate(tiles):
        sheet.alpha_composite(t.resize((256, 256), Image.LANCZOS), (10 + (i % 5) * 270, 10 + (i // 5) * 270))
    sheet.convert('RGB').save(f'{out}/_all-products.png')
    print('ok')
