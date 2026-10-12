import sys, os
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import sim, money, aura2 as A, art
from products import dumbbell
from hud import gloss
from preview import icon

def bar(w, h, v):
    t = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    t.alpha_composite(sim.sbox(w, h, (40, 44, 56), radius=0.3, cell=10, stud=(18, 30)))
    if v > 0:
        t.alpha_composite(sim.sbox(max(h, int(w * v)), h, (110, 225, 40), radius=0.3, cell=10, stud=(40, 20)))
    return t

def star_badge(n, num):
    st = gloss(icon('star', n))
    A.stroke_text(st, (n / 2, n * 0.56), str(num), int(n * 0.34), (255, 255, 255), (235, 235, 240), anchor='mm')
    return st

def block(level=1, cur='0', nxt='4', v=0.0, strength='0', cash='$0'):
    im = Image.new('RGBA', (620, 330), (0, 0, 0, 0))
    im.alpha_composite(star_badge(104, level), (0, 0))
    b = bar(360, 46, v); A.stroke_text(b, (180, 22), f'{cur} / {nxt}', 26, (255, 255, 255), (230, 230, 235), anchor='mm')
    im.alpha_composite(b, (112, 30))
    A.stroke_text(im, (114, 96), 'LEVEL', 22, (255, 230, 80), (255, 180, 30))
    im.alpha_composite(gloss(dumbbell(104)), (0, 112))
    A.stroke_text(im, (116, 166), strength, 64, (255, 240, 60), (255, 170, 10), ital=True)
    im.alpha_composite(money.cash1(104), (0, 212))
    A.stroke_text(im, (116, 266), cash, 64, (140, 255, 90), (40, 190, 30), ital=True)
    return im

if __name__ == '__main__':
    bg = Image.open(sys.argv[1]).convert('RGBA').resize((1000, 620)).filter(ImageFilter.GaussianBlur(10))
    bg.alpha_composite(block(), (30, 40))
    bg.alpha_composite(block(42, '1.2M', '3.4M', 0.35, '7.22Qa', '$5.62Qa').resize((400, 213), Image.LANCZOS), (560, 360))
    A.stroke_text(bg, (34, 390), 'Join group: +10% Strength!', 30, (255, 240, 90), (255, 190, 20), ital=True)
    bg.convert('RGB').save('stats2.png', quality=92)
