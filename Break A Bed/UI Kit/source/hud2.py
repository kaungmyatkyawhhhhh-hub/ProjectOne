import sys
from PIL import Image, ImageFilter
import refbtn as R, pixtext as T
from preview import icon
from products import dumbbell
from hud import gloss, chevrons

def txt(img, xy, s, h, fill=(255, 255, 255), anchor='lm'):
    t = T.render(s, fill=fill, height=h)
    x = xy[0] - (t.width / 2 if anchor == 'mm' else t.width if anchor == 'rm' else 0)
    img.alpha_composite(t, (int(x), int(xy[1] - t.height / 2)))

def bar(w, h, v, col):
    im = R.button(w, h, 'light')
    im.alpha_composite(R.button(max(h, int(w * v)), h, col), (0, 0))
    return im

def stat(ic, value, col, w=330, h=74):
    im = Image.new('RGBA', (w + 34, h + 20), (0, 0, 0, 0))
    im.alpha_composite(R.button(w, h, 'light'), (34, 10))
    txt(im, (w + 34 - 16, 10 + h / 2 - 2), value, h * 0.42, fill=col, anchor='rm')
    im.alpha_composite(ic, (0, (h + 20 - ic.height) // 2))
    return im

def main(bgpath, out):
    W, H = 1600, 900
    bg = Image.open(bgpath).convert('RGBA').resize((W, H)).filter(ImageFilter.GaussianBlur(8))
    img = Image.blend(bg, Image.new('RGBA', (W, H), (30, 40, 60, 255)), 0.1)
    rows = [('red', R.basket(70), 'Shop'), ('orange', gloss(dumbbell(72)), 'Boost'),
            ('purple', gloss(icon('wheel', 66)), 'Spin'), ('pink', gloss(icon('gift', 66)), 'Gifts')]
    for i, (c, ic, t) in enumerate(rows):
        img.alpha_composite(R.full(c, ic, t, w=288, h=105), (26, 226 + i * 122))
    tag = R.button(104, 40, 'green'); txt(tag, (52, 19), 'R$19', 18, anchor='mm')
    img.alpha_composite(tag, (196, 226 + 122 + 84))
    lv = Image.new('RGBA', (420, 112), (0, 0, 0, 0))
    lv.alpha_composite(R.button(330, 74, 'light'), (64, 19))
    b = bar(236, 36, 0.25, 'green'); txt(b, (118, 16), '1/4', 18, anchor='mm'); lv.alpha_composite(b, (136, 36))
    badge = R.button(96, 96, 'yellow'); txt(badge, (48, 30), 'LVL', 18, anchor='mm'); txt(badge, (48, 60), '1', 32, anchor='mm')
    lv.alpha_composite(badge, (12, 8))
    img.alpha_composite(lv, (W - 430, 16))
    img.alpha_composite(stat(gloss(dumbbell(82)), '1.2K', (180, 110, 255)), (W - 394, 130))
    img.alpha_composite(stat(gloss(icon('cash', 82)), '$5,430', (80, 210, 60)), (W - 394, 222))
    tc = R.button(580, 140, 'light')
    txt(tc, (290, 42), 'PUNCH 10 TIMES!', 30, fill=(255, 150, 20), anchor='mm')
    tc.alpha_composite(gloss(icon('bolt', 60)), (24, 64))
    tb = bar(450, 44, 0.3, 'green'); txt(tb, (225, 20), '3/10', 22, anchor='mm'); tc.alpha_composite(tb, (100, 74))
    img.alpha_composite(tc, (int(W / 2 - 290), 20))
    sk = R.button(120, 46, 'red'); txt(sk, (60, 21), 'SKIP', 20, anchor='mm')
    img.alpha_composite(sk, (int(W / 2 + 290 - 120), 168))
    ch = chevrons()
    persp = ch.transform((900, 220), Image.QUAD, (0, 0, 0, ch.height, ch.width, ch.height, ch.width, 0), Image.BICUBIC)
    img.alpha_composite(persp, (350, 650))
    img.convert('RGB').save(out, quality=92)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
