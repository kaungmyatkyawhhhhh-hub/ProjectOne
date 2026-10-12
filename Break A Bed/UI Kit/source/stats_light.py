import sys
from PIL import Image, ImageDraw, ImageFilter
import sim, money, aura2 as A
from kit import mix, label
from products import dumbbell
from hud import gloss

LIGHT = (232, 236, 244)

def panel(w, h):
    return sim.sbox(w, h, LIGHT, radius=0.06, cell=14, stud=(70, 22))

def track(w, h, v, col=(90, 220, 60)):
    t = sim.sbox(w, h, (205, 211, 224), radius=0.18, cell=10, stud=(30, 18))
    if v > 0:
        f = sim.sbox(max(h, int(w * v)), h, col, radius=0.18, cell=10, stud=(40, 20))
        t.alpha_composite(f)
    return t

def block():
    W = 520
    im = Image.new('RGBA', (W, 330), (0, 0, 0, 0))
    # level row
    lp = panel(420, 84); im.alpha_composite(lp, (96, 14))
    tr = track(370, 50, 0.74); A.stroke_text(tr, (185, 23), '7.22Qa / 9.74Qa', 28, (255, 255, 255), (235, 235, 240), anchor='mm')
    im.alpha_composite(tr, (126, 31))
    badge = sim.sbox(108, 108, 'yellow', radius=0.08, cell=12)
    A.stroke_text(badge, (54, 28), 'LVL', 26, (255, 255, 255), (240, 240, 240), anchor='mm')
    A.stroke_text(badge, (54, 68), '115', 44, (255, 255, 255), (240, 240, 240), anchor='mm')
    im.alpha_composite(badge, (6, 2))
    # strength row
    sp = panel(420, 92); im.alpha_composite(sp, (96, 124))
    A.stroke_text(im, (500, 170), '7.22Qa', 52, (255, 235, 40), (255, 190, 20), anchor='rm')
    im.alpha_composite(gloss(dumbbell(110)), (16, 115))
    # cash row
    cp = panel(420, 92); im.alpha_composite(cp, (96, 230))
    A.stroke_text(im, (500, 276), '$5.62Qa', 52, (130, 245, 90), (50, 190, 40), anchor='rm')
    im.alpha_composite(money.cash1(118), (8, 216))
    return im

if __name__ == '__main__':
    bg = Image.open(sys.argv[1]).convert('RGBA').resize((1000, 520)).filter(ImageFilter.GaussianBlur(10))
    bg.alpha_composite(block(), (440, 40))
    bg.convert('RGB').save('stats_light.png', quality=92)
    block().save('stats_light_block.png')
