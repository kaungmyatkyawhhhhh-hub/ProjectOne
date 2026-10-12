import sys
from PIL import Image, ImageDraw, ImageFilter
from kit import box, label, sparkle, OUTLINE, S, soft_glow
from preview import paste, icon
from gifts import dumbbell

def bar(w, h, v, col):
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    im.alpha_composite(box(w, h, (42, 47, 61), pattern=False, rim=0.0, lip=0.0, top_mix=0, bot_mix=0.15), (0, 0))
    fw = max(h, int(w * v))
    im.alpha_composite(box(fw, h, col, stud_cell=10), (0, 0))
    return im

def step_card(title, v, txt):
    w, h = 620, 150
    c = box(w, h, 'slate', stud_cell=14)
    label(c, (w/2, 42), title, 34, fill=(255, 226, 12))
    b = bar(w - 150, 48, v, 'green')
    label(b, (b.width/2, 21), txt, 26)
    c.alpha_composite(icon('bolt', 66), (26, 72))
    c.alpha_composite(b, (106, 80))
    return c

def goal_bar(text, v, txt):
    w, h = 620, 96
    c = box(w, h, 'slate', stud_cell=14)
    c.alpha_composite(icon('bolt', 66), (16, 12))
    label(c, (96, 26), text, 22, anchor='lm')
    b = bar(w - 116, 32, v, 'cyan')
    label(b, (b.width/2, 14), txt, 18)
    c.alpha_composite(b, (94, 48))
    return c

def main(shot, out):
    bg = Image.open(shot).convert('RGBA')
    W, H = 1600, int(1600 * bg.height / bg.width)
    img = bg.resize((W, H), Image.LANCZOS).filter(ImageFilter.GaussianBlur(9))
    img = Image.blend(img, Image.new('RGBA', (W, H), (10, 15, 35, 255)), 0.15)
    cx = W / 2
    card = step_card('PUNCH 10 TIMES!', 0.3, '3 / 10')
    paste(img, card, (cx, 120))
    sk = box(118, 46, 'red', stud_cell=10); label(sk, (59, 20), 'SKIP', 22)
    paste(img, sk, (cx + 310 - 59, 120 + 75 + 30))
    # in-world arrow hint
    ar = Image.new('RGBA', (200, 200), (0, 0, 0, 0))
    d = ImageDraw.Draw(ar)
    d.polygon([(100, 190), (20, 100), (65, 100), (65, 10), (135, 10), (135, 100), (180, 100)], fill=OUTLINE)
    d.polygon([(100, 172), (40, 108), (75, 108), (75, 20), (125, 20), (125, 108), (160, 108)], fill=(255, 226, 12))
    paste(img, ar, (cx, 560))
    for sx, sy, sz in ((cx - 90, 500, 34), (cx + 95, 580, 26)):
        img.alpha_composite(sparkle(sz), (int(sx - sz/2), int(sy - sz/2)))
    # after the guide
    label(img, (cx - 310, H - 170), 'After the guide:', 22, anchor='lm')
    paste(img, goal_bar('Next bed: Air Mattress', 0.55, '4 / 7 Strength'), (cx, H - 95))
    img.convert('RGB').save(out, quality=92)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
