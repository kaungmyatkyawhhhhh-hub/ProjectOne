import sys
from PIL import Image, ImageDraw, ImageFilter
import sim, shop3, kit, money, aura2 as A
from kit import label
from preview import icon
from hud import gloss
from products import dumbbell
from gifts import check

def combo(items, n):
    """1 or 2 icons overlapped."""
    im = Image.new('RGBA', (n, n), (0, 0, 0, 0))
    if len(items) == 1:
        im.alpha_composite(items[0].resize((n, n), Image.LANCZOS))
    else:
        a = items[0].resize((int(n * .78),) * 2, Image.LANCZOS); b = items[1].resize((int(n * .62),) * 2, Image.LANCZOS)
        im.alpha_composite(a, (0, 0)); im.alpha_composite(b, (n - b.width, n - b.height))
    return im

def boost_icon(n, mult='x2'):
    im = gloss(dumbbell(n)).copy()
    A.stroke_text(im, (n * .5, n * .78), mult, int(n * .36), (255, 240, 60), (255, 160, 10), anchor='mm')
    return im

def dcard(w, h, day, art, amount, state, gold=False):
    col = (110, 220, 20) if state == 'claimed' else ((255, 200, 30) if gold else ((40, 200, 245) if state == 'today' else (70, 74, 86)))
    c = sim.sbox(w, h, col, radius=0.05, cell=14, stud=(26, 26))
    if state == 'today' or gold:
        c.alpha_composite(A.tint(kit.rays(w * 2, 14, 70).crop((w // 2, h // 3, w // 2 + w, h // 3 + h)), (255, 255, 255), .6))
    A.stroke_text(c, (w / 2, 30), f'DAY {day}', 26, (255, 255, 255), (230, 230, 235), anchor='mm')
    s = int(w * .74)
    c.alpha_composite(A.tint(kit.soft_glow(s, 160), (255, 255, 255), .5), ((w - s) // 2, 82))
    c.alpha_composite(art.resize((s, s), Image.LANCZOS), ((w - s) // 2, 82))
    A.stroke_text(c, (w / 2, h - 30), amount, 24, (140, 255, 90) if '$' in amount else (255, 255, 255), (40, 190, 30) if '$' in amount else (225, 225, 235), anchor='mm')
    if state == 'claimed':
        dim = Image.new('RGBA', (w, h), (0, 0, 0, 0)); dim.putalpha(c.getchannel('A').point(lambda v: v * 70 // 255)); c.alpha_composite(dim)
        ck = check(int(w * .55)); c.alpha_composite(ck, ((w - ck.width) // 2, 100))
    return c

def main(bgpath, out):
    Wd, Hd = 1600, 620
    bg = Image.open(bgpath).convert('RGBA').resize((Wd, Hd)).filter(ImageFilter.GaussianBlur(10))
    img = Image.blend(bg, Image.new('RGBA', (Wd, Hd), (30, 40, 30, 255)), 0.2)
    x0, y0, ww, wh = 70, 30, 1460, 560
    img.alpha_composite(shop3.window(ww, wh), (x0, y0))
    hd = sim.header(ww - 110, 100, 'green', ''); hd.alpha_composite(gloss(icon('gift', 80)), (16, 8))
    A.stroke_text(hd, (110, 48), 'DAILY REWARD', 50, (255, 255, 255), (230, 230, 235))
    img.alpha_composite(hd, (x0 + 6, y0 + 6))
    img.alpha_composite(kit.x_mark(sim.sbox(96, 96, 'red', radius=0.04, cell=40, stud=(0, 0))), (x0 + ww - 102, y0 + 8))
    cash = money.cash1(256); pile = money.cash2(256); spin = gloss(icon('wheel', 256)); star = gloss(icon('star', 256))
    days = [(1, combo([cash], 200), '$28T', 'claimed'), (2, combo([pile], 200), '$56T', 'claimed'),
            (3, combo([pile, spin], 200), '$56T +1', 'today'), (4, boost_icon(256), '10 MIN', 'locked'),
            (5, combo([money.cash3(256)], 200), '$140T', 'locked'), (6, combo([spin], 200), '+2 SPINS', 'locked')]
    cw, ch = 176, 330
    for i, (d, art, amt, st) in enumerate(days):
        img.alpha_composite(dcard(cw, ch, d, art, amt, st), (x0 + 24 + i * (cw + 14), y0 + 130))
    # day 7: big gold OP card
    g = dcard(cw + 140, ch + 40, 7, combo([money.safe(256), star], 260), '+2 LVL +3 SPINS', 'locked', gold=True)
    A.stroke_text(g, (g.width / 2, 64), "MEGA!", 28, (255, 80, 80), (200, 20, 20), anchor='mm')
    img.alpha_composite(g, (x0 + 24 + 6 * (cw + 14), y0 + 112))
    A.stroke_text(img, (x0 + ww / 2, y0 + wh - 36), 'Come back tomorrow for Day 4!', 30, (255, 230, 80), (255, 170, 20), anchor='mm')
    img.convert('RGB').save(out, quality=92)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
