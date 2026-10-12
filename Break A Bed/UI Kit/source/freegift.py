import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import kit, sim, shop3, art, aura2 as A
from kit import label, FONT
from preview import icon
from hud import gloss
from products import dumbbell

def popup(bgpath, out):
    Wd, Hd = 1600, 900
    bg = Image.open(bgpath).convert('RGBA').resize((Wd, Hd)).filter(ImageFilter.GaussianBlur(10))
    img = Image.blend(bg, Image.new('RGBA', (Wd, Hd), (40, 90, 30, 255)), 0.15)
    x0, y0, ww, wh = 260, 90, 1080, 730
    img.alpha_composite(shop3.window(ww, wh), (x0, y0))
    img.alpha_composite(sim.header(ww - 12, 100, 'cyan', 'Free Gift!'), (x0 + 6, y0 + 6))
    img.alpha_composite(kit.x_mark(sim.sbox(84, 84, 'red', radius=0.04, cell=40, stud=(0, 0))), (x0 + ww - 100, y0 + 14))
    hero = Image.new('RGBA', (360, 360), (0, 0, 0, 0))
    hero.alpha_composite(A.burst(360, (255, 230, 120), 14, 70))
    hero.alpha_composite(art.cash_pile(320, 5), (20, 10))
    img.alpha_composite(hero, (x0 + 40, y0 + 110))  # step cards are drawn after this, so they sit on top of the pile
    A.stroke_text(img, (x0 + 730, y0 + 228), '~ LIMITED TIME! ~', 60, (255, 120, 120), (230, 40, 40), anchor='mm')
    A.stroke_text(img, (x0 + 730, y0 + 325), '+$50K CASH!', 86, (120, 255, 90), (40, 190, 40), anchor='mm')
    steps = [('1. Like the game!', 'thumb'), ('2. Favorite it!', 'star'), ('3. Join the group!', 'group')]
    cw = (ww - 4 * 22) // 3
    for i, (t, k) in enumerate(steps):
        c = shop3.card(cw, 190, (50, 52, 64), (34, 35, 44), rays=False)
        label(c, (cw / 2, 30), t, 26, anchor='mm')
        sc = Image.new('RGBA', (cw - 30, 120), (30, 31, 40, 255)); d = ImageDraw.Draw(sc)
        d.rectangle((0, 0, sc.width - 1, sc.height - 1), outline=(80, 82, 96), width=3)
        if k == 'star':
            ic = gloss(icon('star', 70))
        elif k == 'thumb':
            ic = Image.new('RGBA', (70, 70), (0, 0, 0, 0)); dd = ImageDraw.Draw(ic)
            dd.rounded_rectangle((8, 30, 24, 64), 3, fill=(255, 255, 255)); dd.rounded_rectangle((28, 28, 62, 64), 8, fill=(255, 255, 255))
            dd.polygon([(30, 30), (42, 6), (52, 10), (48, 30)], fill=(255, 255, 255))
        else:
            ic = Image.new('RGBA', (180, 60), (0, 0, 0, 0)); dd = ImageDraw.Draw(ic)
            dd.rounded_rectangle((0, 6, 178, 54), 8, fill=(50, 110, 255)); label(ic, (89, 28), 'Join', 26, anchor='mm')
        sc.alpha_composite(ic, ((sc.width - ic.width) // 2, (sc.height - ic.height) // 2))
        ar = Image.new('RGBA', (90, 60), (0, 0, 0, 0)); ImageDraw.Draw(ar).line([(80, 8), (40, 26), (12, 48)], fill=(230, 30, 30), width=9)
        ImageDraw.Draw(ar).polygon([(4, 56), (8, 34), (26, 50)], fill=(230, 30, 30))
        sc.alpha_composite(ar, (sc.width // 2 + 30, 50))
        c.alpha_composite(sc, (15, 55))
        if k == 'group':
            ok = sim.sbox(44, 44, 'green', radius=0.1, cell=40, stud=(0, 0)); label(ok, (22, 20), '✓' if False else 'OK', 18, anchor='mm')
        img.alpha_composite(c, (x0 + 22 + i * (cw + 22), y0 + 420))
    cb = shop3.lime(400, 96); label(cb, (200, 46), 'Claim!', 56, anchor='mm')
    img.alpha_composite(cb, (x0 + ww // 2 - 200, y0 + wh - 120))
    img.convert('RGB').save(out, quality=92)

def chest(n=420):
    W = n * 4
    im = Image.new('RGBA', (W, W), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    def P(*pts): return [(x * W, y * W) for x, y in pts]
    A.grad_poly = art.grad_poly
    art.grad_poly(im, P((.12, .48), (.88, .48), (.88, .88), (.12, .88)), (220, 45, 40), (150, 20, 20))
    art.grad_poly(im, P((.12, .48), (.15, .3), (.3, .2), (.7, .2), (.85, .3), (.88, .48)), (240, 70, 60), (190, 30, 30))
    gold = (255, 205, 50)
    for x in (.12, .44, .56, .84):
        pass
    for poly in (P((.1, .46), (.9, .46), (.9, .52), (.1, .52)), P((.1, .84), (.9, .84), (.9, .9), (.1, .9)),
                 P((.1, .3), (.17, .28), (.17, .9), (.1, .9)), P((.83, .28), (.9, .3), (.9, .9), (.83, .9)),
                 P((.44, .2), (.56, .2), (.56, .9), (.44, .9))):
        art.grad_poly(im, poly, (255, 235, 110), (230, 150, 20))
    d.rounded_rectangle((W*.43, W*.5, W*.57, W*.66), W*.02, fill=(255, 220, 80), outline=(140, 80, 10), width=int(W*.008))
    d.ellipse((W*.47, W*.54, W*.53, W*.6), fill=(40, 30, 20)); d.polygon(P((.49, .58), (.51, .58), (.52, .64), (.48, .64)), fill=(40, 30, 20))
    d.ellipse((W*.45, W*.27, W*.55, W*.37), fill=(60, 220, 110), outline=(20, 90, 40), width=int(W*.008))
    im = art.outline(im, int(W * .018))
    return im.resize((n, n), Image.LANCZOS)

def billboard(bgpath, out):
    Wd, Hd = 1200, 1000
    bg = Image.open(bgpath).convert('RGBA').resize((Wd, Hd)).filter(ImageFilter.GaussianBlur(12))
    img = Image.blend(bg, Image.new('RGBA', (Wd, Hd), (60, 150, 40, 255)), 0.35)
    bw, bh = 820, 400
    board = Image.new('RGBA', (bw, bh), (0, 0, 0, 0))
    frame = sim.sbox(bw, bh, (90, 180, 50), radius=0.03, cell=24)
    board.alpha_composite(frame)
    inner = shop3.card(bw - 60, bh - 70, (20, 120, 30), (60, 190, 50))
    board.alpha_composite(inner, (30, 40))
    A.stroke_text(board, (80, 120), 'Watch Ad To Collect:', 34, (255, 255, 255), (230, 230, 235))
    A.stroke_text(board, (80, 210), '$694.4K', 76, (130, 255, 90), (50, 200, 40), ital=True)
    pl = Image.new('RGBA', (60, 60), (0, 0, 0, 0)); ImageDraw.Draw(pl).polygon([(10, 6), (54, 30), (10, 54)], fill=(255, 255, 255))
    board.alpha_composite(pl, (90, 280))
    cp = Image.new('RGBA', (340, 300), (0, 0, 0, 0)); cp.alpha_composite(A.burst(300, (200, 255, 150), 14, 60), (20, 0)); cp.alpha_composite(art.cash_pile(300, 3), (20, 0))
    board.alpha_composite(cp, (bw - 380, 60))
    tag = Image.new('RGBA', (bw, 90), (0, 0, 0, 0)); A.stroke_text(tag, (bw / 2, 45), 'CLICK TO CLAIM', 46, (190, 255, 120), (90, 210, 40), ital=True, anchor='mm')
    tag = tag.rotate(3, expand=False, resample=Image.BICUBIC)
    img.alpha_composite(board, (190, 60)); img.alpha_composite(tag, (190, 20))
    # ground pad + chest + FREE!
    pad = Image.new('RGBA', (760, 260), (0, 0, 0, 0)); d = ImageDraw.Draw(pad)
    d.ellipse((0, 0, 759, 259), fill=(80, 255, 80, 150)); d.ellipse((20, 14, 739, 245), fill=(120, 255, 100, 110))
    img.alpha_composite(pad.filter(ImageFilter.GaussianBlur(3)), (220, 720))
    img.alpha_composite(chest(380), (410, 540))
    A.stroke_text(img, (600, 540), 'FREE!', 110, (120, 255, 90), (30, 190, 30), anchor='mm')
    A.stroke_text(img, (600, 950), 'Next chest in 14:59', 34, (255, 255, 255), (230, 230, 235), anchor='mm')
    img.convert('RGB').save(out, quality=92)

if __name__ == '__main__':
    B = sys.argv[1]
    popup(B, 'free_popup.png'); billboard(B, 'free_chest.png')
