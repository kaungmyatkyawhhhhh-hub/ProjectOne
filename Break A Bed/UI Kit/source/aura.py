import sys, math, colorsys
from PIL import Image, ImageDraw, ImageFilter, ImageChops, ImageFont
import kit, sim, shop3, fx
from kit import S, mix, mask_rr, label, FONT

def tint(im, col, a=1.0):
    t = Image.new('RGBA', im.size, col + (0,)); t.putalpha(im.getchannel('A').point(lambda v: int(v * a))); return t

def aura_icon(n, c1, c2, kind='swirl'):
    im = Image.new('RGBA', (n, n), (0, 0, 0, 0))
    g = fx.glow().resize((n, n)); im.alpha_composite(tint(g, c1, 0.9)); im.alpha_composite(tint(g.resize((n//2, n//2)), (255,255,255), 0.9), (n//4, n//4))
    if kind == 'swirl':
        sw = fx.swirl().resize((int(n*0.9),)*2); im.alpha_composite(tint(sw, c2), (int(n*0.05),)*2)
    elif kind == 'ring':
        r = fx.ring().resize((int(n*0.85),)*2); im.alpha_composite(tint(r, c2), (int(n*0.075),)*2)
        r2 = fx.ring().resize((int(n*0.55),)*2); im.alpha_composite(tint(r2, (255,255,255), 0.8), (int(n*0.225),)*2)
    elif kind == 'flame':
        for i in range(7):
            s = fx.shards().resize((int(n*0.32), int(n*0.5)))
            s = s.rotate(-60 + i * 20, expand=True, resample=Image.BICUBIC)
            im.alpha_composite(tint(s, c2 if i % 2 else (255, 240, 120)), (n//2 - s.width//2 + int(math.sin(i)*n*0.1), int(n*0.12)))
    elif kind == 'wings':
        for sx in (-1, 1):
            for k in range(4):
                s = fx.shards().resize((int(n*0.16), int(n*0.48))).rotate(sx * (35 + k * 16), expand=True, resample=Image.BICUBIC)
                im.alpha_composite(tint(s, (255,255,255) if k % 2 else c2), (n//2 - s.width//2 + sx * int(n*0.2), int(n*0.18)))
    elif kind == 'galaxy':
        sw = fx.swirl().resize((n, n)); im.alpha_composite(tint(sw, c2)); im.alpha_composite(tint(sw.rotate(60), (255, 120, 255), 0.8))
    for k, (x, y, s) in enumerate(((.18,.2,.18), (.82,.3,.14), (.75,.82,.12), (.2,.78,.1))):
        st = fx.star4().resize((int(n*s),)*2); im.alpha_composite(st, (int(n*x - n*s/2), int(n*y - n*s/2)))
    return im

def slot(w, h, bg, ic, pct, pcol=(255,255,255), rainbow=False):
    c = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    c.paste((20, 20, 26, 255), (0, 0, w, h))
    c.paste(bg + (255,), (3, 3, w - 3, h - 3))
    g = kit.vgrad((w - 6, h - 6), mix(bg, (255,255,255), 0.25), mix(bg, (0,0,0), 0.35), 0, h); c.paste(g, (3, 3))
    if rainbow:
        d = ImageDraw.Draw(c)
        for i in range(4):
            r, gg, b = colorsys.hsv_to_rgb(i / 4, 0.9, 1); d.rectangle((i, i, w - 1 - i, h - 1 - i), outline=(int(r*255), int(gg*255), int(b*255)))
    c.alpha_composite(ic.resize((int(w * 0.9), int(w * 0.9))), (int(w * 0.05), int((h - w * 0.9) / 2) - 6))
    sim.itext(c, (w - 14 - ImageFont.truetype(FONT, 28).getlength(pct) * 1.05, h - 22), pct, 28, pcol)
    return c

def featured(w, h):
    W, H = w, h
    c = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    c.paste((235, 180, 40, 255), (0, 0, W, H)); c.paste((24, 20, 30, 255), (5, 5, W - 5, H - 5))
    bg = Image.new('RGB', (W - 10, H - 10)); px = bg.load()
    for y in range(H - 10):
        for x in range(W - 10):
            t = ((x - W/2) ** 2 + (y - H*0.45) ** 2) ** 0.5 / (W * 0.7)
            px[x, y] = mix((120, 50, 230), (20, 10, 60), min(1, t))
    c.paste(bg, (5, 5))
    r = kit.rays(W, 16, 60); c.alpha_composite(r.crop((0, (r.height - H)//2, W, (r.height - H)//2 + H)))
    for i in range(40):
        x, y = (i * 137) % W, (i * 89) % H; s = 10 + (i * 7) % 18
        c.alpha_composite(fx.star4().resize((s, s)), (x, y))
    nb = sim.sbox(150, 54, 'red', radius=0.04, cell=40, stud=(0, 0)); label(nb, (75, 25), 'New!', 30, anchor='mm')
    c.alpha_composite(nb, (22, 18))
    label(c, (190, 44), 'GALAXY AURA CRATE', 46, fill=(255, 226, 30), anchor='lm')
    label(c, (192, 92), 'Limited Time!', 24, anchor='lm')
    label(c, (W - 24, 44), '6d 23h 41m 08s', 30, anchor='rm') if False else sim.wtext(c, (W - 300, 44), '6d 23h 41m 08s', 30)
    big = aura_icon(200, (200, 90, 255), (120, 220, 255), 'galaxy')
    c.alpha_composite(big, (10, 110))
    auras = [((150,150,160),(255,255,255),'swirl','Spark','40%',(110,110,120)),
             ((60,200,255),(140,240,255),'ring','Frost','30%',(30,110,200)),
             ((255,130,30),(255,80,20),'flame','Blaze','18%',(170,60,10)),
             ((255,240,160),(255,255,255),'wings','Angel','9%',(200,160,40)),
             ((200,90,255),(120,220,255),'galaxy','Galaxy','2.9%',(90,30,170)),
             ((255,60,200),(255,255,255),'galaxy','Infinity','0.1%',(40,10,60))]
    x = 220
    for i, (c1, c2, k, nm, pct, bgc) in enumerate(auras):
        last = i == len(auras) - 1
        sw = 150 if last else 110
        s = slot(sw, 150 if last else 120, bgc, aura_icon(180, c1, c2, k), pct, (255, 226, 30) if i >= 4 else (255,255,255), rainbow=last)
        if last:
            label(s, (sw/2, 18), 'INFINITY', 22, fill=(255, 226, 30), anchor='mm')
        c.alpha_composite(s, (x, H - (150 if last else 120) - 110))
        x += sw + 10
    gs = 62
    for i, (p, lbl, red) in enumerate((('399', '10 Crates', True), ('129', '3 Crates', False), ('49', '1 Crate', False))):
        bx = 30 + i * ((W - 60) // 3)
        c.alpha_composite(shop3.giftbtn(gs), (bx, H - 92))
        pb = shop3.price(((W - 60) // 3) - gs - 24, gs, p)
        if red:
            pb = sim.sbox(pb.width, gs, 'red', radius=0.04, cell=22, stud=(20, 20)); f = ImageFont.truetype(FONT, 38); tw = f.getlength(p)
            xx = (pb.width - 40 - tw) / 2; pb.alpha_composite(shop3.robux(38), (int(xx), 12)); label(pb, (xx + 44, 29), p, 38, anchor='lm')
        c.alpha_composite(pb, (bx + gs + 8, H - 92))
        label(c, (bx + gs + 8 + pb.width / 2, H - 16), lbl, 22, anchor='mm')
    return c

def main(bgpath, out):
    from PIL import ImageFilter
    Wd, Hd = 1600, 900
    bg = Image.open(bgpath).convert('RGBA').resize((Wd, Hd)).filter(ImageFilter.GaussianBlur(10))
    img = Image.blend(bg, Image.new('RGBA', (Wd, Hd), (40, 90, 30, 255)), 0.15)
    x0, y0, ww, wh = 180, 70, 1140, 790
    img.alpha_composite(shop3.window(ww, wh), (x0, y0))
    img.alpha_composite(sim.header(ww - 12, 100, 'green', 'Shop'), (x0 + 6, y0 + 6))
    img.alpha_composite(kit.x_mark(sim.sbox(84, 84, 'red', radius=0.04, cell=40, stud=(0, 0))), (x0 + ww - 100, y0 + 14))
    sim.wtext(img, (x0 + ww / 2, y0 + 150), '-- FEATURED --', 44, fill=(255, 226, 30), anchor='mm')
    img.alpha_composite(featured(ww - 48, 560), (x0 + 24, y0 + 190))
    sim.wtext(img, (Wd / 2, 32), 'Rong got the INFINITY AURA!', 36, anchor='mm', hl='INFINITY AURA!')
    from hud import gloss
    from preview import icon
    for i, (k, t) in enumerate([('star', 'Featured'), ('bolt', 'Strength'), ('cash', 'Cash'), ('gift', 'Passes')]):
        img.alpha_composite(gloss(icon(k, 100)), (x0 + ww + 22, y0 + 130 + i * 150))
        label(img, (x0 + ww + 72, y0 + 238 + i * 150), t, 26, anchor='mm')
    img.convert('RGB').save(out, quality=92)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
