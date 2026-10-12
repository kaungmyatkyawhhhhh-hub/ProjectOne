import sys, math, random, colorsys
from PIL import Image, ImageDraw, ImageFilter, ImageChops, ImageFont
import kit, sim, shop3, fx
from kit import mix, label, FONT

random.seed(7)
DARK = (18, 14, 26)

def tint(im, col, a=1.0):
    t = Image.new('RGBA', im.size, col + (0,)); t.putalpha(im.getchannel('A').point(lambda v: int(v * a))); return t

def add(base, layer):
    """additive blend (light)"""
    rgb = ImageChops.add(base.convert('RGB'), Image.composite(layer.convert('RGB'), Image.new('RGB', base.size), layer.getchannel('A')))
    out = rgb.convert('RGBA'); out.putalpha(base.getchannel('A')); return out

def bloom(im, radius=14, strength=0.9, thresh=170):
    rgb = im.convert('RGB')
    lum = rgb.convert('L').point(lambda v: 255 if v > thresh else int(v * v / 255 * 0.4))
    bright = Image.composite(rgb, Image.new('RGB', im.size), lum).filter(ImageFilter.GaussianBlur(radius))
    bright = bright.point(lambda v: int(v * strength))
    out = ImageChops.add(rgb, bright).convert('RGBA'); out.putalpha(im.getchannel('A')); return out

def burst(n, col, count=14, a=150):
    r = kit.rays(n, count, a)
    g = fx.glow().resize((n, n))
    out = tint(r, col, 0.55); out.alpha_composite(tint(g, col, 0.55)); out.alpha_composite(tint(g.resize((n // 3, n // 3)), (255, 255, 255), 0.35), (n // 3, n // 3))
    return out

def galaxy(n, c1=(190, 80, 255), c2=(90, 210, 255), arms=4):
    W = n * 2
    im = Image.new('RGBA', (W, W), (0, 0, 0, 0)); d = ImageDraw.Draw(im); c = W / 2
    for arm in range(arms):
        for k in range(260):
            t = k / 259; ang = arm * 2 * math.pi / arms + t * 4.2
            r = W * (0.02 + 0.44 * t)
            x, y = c + r * math.cos(ang), c + r * math.sin(ang) * 0.92
            s = W * 0.03 * (1 - t) + 2
            col = mix(mix((255, 255, 255), c1, min(1, t * 2)), c2, max(0, t * 2 - 1))
            d.ellipse((x - s, y - s, x + s, y + s), fill=col + (int(230 * (1 - t * 0.7)),))
    for _ in range(140):
        ang = random.random() * 6.283; r = W * 0.45 * random.random() ** 0.6; s = random.random() * W * 0.006 + 1
        x, y = c + r * math.cos(ang), c + r * math.sin(ang)
        d.ellipse((x - s, y - s, x + s, y + s), fill=(255, 255, 255, 220))
    im = im.filter(ImageFilter.GaussianBlur(W * 0.006))
    core = fx.glow().resize((W // 5, W // 5)); im.alpha_composite(tint(core, (255, 240, 255), 0.9), (W * 2 // 5, W * 2 // 5))
    return im.resize((n, n), Image.LANCZOS)

def aura_art(kind, n):
    im = Image.new('RGBA', (n, n), (0, 0, 0, 0))
    if kind == 'spark':
        im.alpha_composite(tint(fx.glow().resize((n, n)), (200, 210, 230), 0.45))
        for i in range(9):
            s = int(n * (0.18 + 0.22 * random.random())); a = i / 9 * 6.283
            im.alpha_composite(fx.star4().resize((s, s)), (int(n/2 + math.cos(a)*n*0.25 - s/2), int(n/2 + math.sin(a)*n*0.25 - s/2)))
        im.alpha_composite(fx.star4().resize((int(n*0.6),)*2), (int(n*0.2),)*2)
    elif kind == 'frost':
        im.alpha_composite(tint(fx.glow().resize((n, n)), (60, 190, 255), 0.5))
        for k, s in enumerate((0.9, 0.62, 0.36)):
            r = fx.ring().resize((int(n*s), int(n*s*0.45)))
            im.alpha_composite(tint(r, (170, 240, 255) if k else (90, 210, 255)), (int(n*(1-s)/2), int(n*0.62 - n*s*0.22)))
        for i in range(7):
            sh = fx.shards().resize((int(n*0.12), int(n*0.32))).rotate(-30 + i * 10, expand=True)
            im.alpha_composite(tint(sh, (220, 250, 255)), (int(n*0.18 + i*n*0.09), int(n*0.18 + abs(3-i)*n*0.04)))
    elif kind == 'blaze':
        im.alpha_composite(tint(fx.glow().resize((n, n)), (255, 110, 20), 0.5))
        for i in range(11):
            h = n * (0.35 + 0.35 * random.random()); w = n * 0.2
            sh = fx.shards().resize((int(w), int(h))).rotate(random.uniform(-15, 15), expand=True)
            col = random.choice([(255, 80, 10), (255, 160, 30), (255, 230, 120)])
            im.alpha_composite(tint(sh, col), (int(n*0.15 + i*n*0.06), int(n*0.85 - sh.height)))
    elif kind == 'angel':
        im.alpha_composite(tint(fx.glow().resize((n, n)), (255, 200, 80), 0.45))
        for sx in (-1, 1):
            for k in range(6):
                f = fx.shards().resize((int(n*0.11), int(n*(0.42 - k*0.04)))).rotate(sx * (25 + k*14), expand=True)
                im.alpha_composite(tint(f, (255, 255, 255) if k % 2 == 0 else (255, 235, 160)), (int(n/2 - f.width/2 + sx*n*(0.14 + k*0.03)), int(n*0.2 + k*n*0.02)))
        hal = fx.ring().resize((int(n*0.42), int(n*0.13))); im.alpha_composite(tint(hal, (255, 225, 80)), (int(n*0.29), int(n*0.1)))
    elif kind == 'galaxy':
        im.alpha_composite(tint(fx.glow().resize((n, n)), (150, 70, 255), 0.45))
        g = galaxy(int(n*0.95)); im.alpha_composite(g, (int(n*0.025),)*2)
    elif kind == 'infinity':
        g0 = fx.glow().resize((n, n))
        for i, col in enumerate([(255, 60, 120), (255, 200, 40), (60, 230, 120), (60, 160, 255), (200, 80, 255)]):
            a = i / 5 * 6.283; im.alpha_composite(tint(g0.resize((int(n*0.6),)*2), col, 0.45), (int(n*0.2 + math.cos(a)*n*0.12), int(n*0.2 + math.sin(a)*n*0.12)))
        g = galaxy(int(n*0.9), (255, 90, 200), (255, 220, 90), 5); im.alpha_composite(g, (int(n*0.05),)*2)
        for sx in (-1, 1):
            for k in range(5):
                f = fx.shards().resize((int(n*0.09), int(n*(0.36 - k*0.04)))).rotate(sx * (30 + k*15), expand=True)
                im.alpha_composite(tint(f, (255, 255, 255)), (int(n/2 - f.width/2 + sx*n*(0.3 + k*0.02)), int(n*0.15 + k*n*0.03)))
    return bloom(im, n * 0.03, 0.35, 220)

def stroke_text(img, xy, s, size, top, bot, ital=False, anchor='lm', sw=None):
    path = FONT
    if ital:
        import os; path = os.path.join(os.path.dirname(__file__), '..', 'fonts', 'Montserrat-BlackItalic.ttf')
    f = ImageFont.truetype(path, size * 3)
    sw = (sw or max(2, round(size * 0.12))) * 3
    tw = int(f.getlength(s)) + sw * 4; th = int(size * 3 * 1.5)
    m = Image.new('L', (tw, th), 0); ImageDraw.Draw(m).text((sw * 2, th / 2), s, font=f, anchor='lm', fill=255)
    o = Image.new('L', (tw, th), 0); ImageDraw.Draw(o).text((sw * 2, th / 2), s, font=f, anchor='lm', fill=255, stroke_width=sw, stroke_fill=255)
    shadow = ImageChops.offset(o, 0, int(size * 0.25))
    lay = Image.new('RGBA', (tw, th), (0, 0, 0, 0))
    lay.paste(DARK + (255,), (0, 0), ImageChops.lighter(o, shadow))
    g = kit.vgrad((tw, th), top, bot, int(th * 0.3), int(th * 0.7))
    lay.paste(g, (0, 0), m)
    hl = Image.new('L', (tw, th), 0); ImageDraw.Draw(hl).rectangle((0, 0, tw, int(th * 0.47)), fill=70)
    lay.alpha_composite(Image.merge('RGBA', [Image.new('L', (tw, th), 255)] * 3 + [ImageChops.multiply(hl, m)]))
    t = lay.resize((tw // 3, th // 3), Image.LANCZOS)
    x = xy[0] - (t.width / 2 if anchor == 'mm' else t.width if anchor == 'rm' else 0)
    img.alpha_composite(t, (int(x), int(xy[1] - t.height / 2)))

def slot(w, h, rar, art, pct, label_top=None):
    cols = {'common': ((95, 100, 115), (40, 42, 52), (220, 225, 235)), 'rare': ((40, 140, 230), (15, 40, 100), (120, 210, 255)),
            'epic': ((240, 110, 20), (90, 25, 5), (255, 170, 60)), 'legend': ((240, 190, 40), (110, 70, 10), (255, 230, 120)),
            'mythic': ((150, 60, 240), (40, 15, 90), (210, 140, 255)), 'secret': ((220, 40, 160), (40, 5, 50), (255, 150, 230))}
    a, b, glowc = cols[rar]
    c = Image.new('RGBA', (w, h), DARK + (255,))
    bw = 4
    bg = Image.new('RGB', (w - 2*bw, h - 2*bw)); px = bg.load(); cx, cy = (w - 2*bw) / 2, (h - 2*bw) * 0.45
    for y in range(h - 2*bw):
        for x in range(w - 2*bw):
            t = min(1, ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 / (max(w, h) * 0.62)); px[x, y] = mix(a, b, t)
    c.paste(bg, (bw, bw))
    br = burst(int(max(w, h) * 1.3), glowc, 12, 70)
    inner = Image.new('RGBA', (w - 2*bw, h - 2*bw), (0, 0, 0, 0)); inner.alpha_composite(br, (int(-(br.width - w) / 2) - bw, int(-(br.height - h) / 2 - h * 0.05) - bw))
    c.alpha_composite(inner, (bw, bw))
    s = int(min(w, h) * 0.98); c.alpha_composite(art.resize((s, s), Image.LANCZOS), ((w - s) // 2, int(h * 0.44 - s / 2)))
    if rar == 'secret':
        d = ImageDraw.Draw(c)
        for i in range(bw + 2):
            for x in range(w):
                r_, g_, b_ = colorsys.hsv_to_rgb((x / w + i * 0.02) % 1, 0.85, 1); d.point((x, i), (int(r_*255), int(g_*255), int(b_*255))); d.point((x, h - 1 - i), (int(r_*255), int(g_*255), int(b_*255)))
            for y in range(h):
                r_, g_, b_ = colorsys.hsv_to_rgb((y / h * 0.5 + 0.5) % 1, 0.85, 1); d.point((i, y), (int(r_*255), int(g_*255), int(b_*255)))
                r_, g_, b_ = colorsys.hsv_to_rgb((y / h * 0.5) % 1, 0.85, 1); d.point((w - 1 - i, y), (int(r_*255), int(g_*255), int(b_*255)))
    if label_top:
        stroke_text(c, (w / 2, 22), label_top, 24, (255, 240, 150), (255, 170, 30), ital=True, anchor='mm')
    fsz = 30 if w < 140 else 34
    stroke_text(c, (w - 8, h - 22), pct, fsz, (255, 255, 255) if rar in ('common', 'rare', 'epic') else (255, 240, 120),
                (230, 230, 240) if rar in ('common', 'rare', 'epic') else (255, 190, 30), ital=True, anchor='rm')
    return c

def scene(w, h):
    bg = Image.new('RGB', (w, h)); px = bg.load()
    for y in range(h):
        for x in range(w):
            t = min(1, ((x - w * 0.22) ** 2 + (y - h * 0.45) ** 2) ** 0.5 / (w * 0.85))
            px[x, y] = mix((120, 40, 200), (14, 6, 40), t ** 0.8)
    im = bg.convert('RGBA')
    neb = Image.new('RGBA', (w, h), (0, 0, 0, 0)); d = ImageDraw.Draw(neb)
    for _ in range(26):
        x, y, r = random.uniform(0, w), random.uniform(0, h), random.uniform(60, 200)
        col = random.choice([(220, 60, 200), (60, 120, 255), (140, 60, 255), (40, 200, 255)])
        d.ellipse((x - r, y - r * 0.6, x + r, y + r * 0.6), fill=col + (40,))
    im.alpha_composite(neb.filter(ImageFilter.GaussianBlur(40)))
    st = Image.new('RGBA', (w, h), (0, 0, 0, 0)); d = ImageDraw.Draw(st)
    for _ in range(220):
        x, y, s = random.uniform(0, w), random.uniform(0, h), random.random() ** 3 * 2.6 + 0.6
        d.ellipse((x - s, y - s, x + s, y + s), fill=(255, 255, 255, random.randint(120, 255)))
    im.alpha_composite(st)
    for _ in range(14):
        s = random.randint(14, 34); im.alpha_composite(tint(fx.star4().resize((s, s)), (255, 255, 255), 0.9), (random.randint(0, w - s), random.randint(0, h - s)))
    # big blurred galaxy in the background, right side
    g = galaxy(int(h * 1.3), (90, 50, 200), (40, 120, 220)); g.putalpha(g.getchannel('A').point(lambda v: v // 3))
    im.alpha_composite(g, (int(w * 0.62), int(-h * 0.2)))
    return im

def card(W, H):
    outer = 6
    c = Image.new('RGBA', (W, H), DARK + (255,))
    border = kit.vgrad((W, H), (255, 220, 90), (230, 120, 20), 0, H); c.paste(border, (0, 0))
    c.paste(DARK + (255,), (outer, outer, W - outer, H - outer))
    sc = scene(W - 2 * outer - 4, H - 2 * outer - 4); c.alpha_composite(sc, (outer + 2, outer + 2))
    # hero
    hero = Image.new('RGBA', (430, 430), (0, 0, 0, 0))
    hero.alpha_composite(burst(430, (190, 90, 255), 16, 90))
    hero.alpha_composite(aura_art('galaxy', 380), (25, 25))
    c.alpha_composite(hero, (-40, 70))
    nb = sim.sbox(150, 54, 'red', radius=0.04, cell=40, stud=(0, 0)); label(nb, (75, 25), 'New!', 30, anchor='mm')
    c.alpha_composite(nb, (24, 22))
    stroke_text(c, (190, 50), 'GALAXY AURAS', 56, (255, 250, 140), (255, 180, 20))
    label(c, (196, 100), 'Limited Time!', 26, anchor='lm')
    stroke_text(c, (W - 26, 50), '6d 23h 41m 08s', 32, (255, 255, 255), (225, 225, 235), anchor='rm')
    data = [('common', 'spark', '40%', 104), ('rare', 'frost', '30%', 112), ('epic', 'blaze', '18%', 120),
            ('legend', 'angel', '9%', 130), ('mythic', 'galaxy', '2.9%', 142), ('secret', 'infinity', '0.1%', 186)]
    x = 290; base = H - 108
    for rar, kind, pct, sz in data:
        h_ = sz + (30 if rar == 'secret' else 0)
        s = slot(sz, h_, rar, aura_art(kind, 220), pct, 'INFINITY' if rar == 'secret' else None)
        c.alpha_composite(s, (x, base - h_))
        x += sz + 10
    # buy row
    gs = 64; colw = (W - 60) // 3
    for i, (p, lbl, red, old) in enumerate((('399', '10 Auras', True, '490'), ('129', '3 Auras', False, None), ('49', '1 Aura', False, None))):
        bx = 30 + i * colw
        c.alpha_composite(shop3.giftbtn(gs), (bx, H - 92))
        pw = colw - gs - 24
        if red:
            pb = sim.sbox(pw, gs, 'red', radius=0.04, cell=22, stud=(22, 22))
            f = ImageFont.truetype(FONT, 40); tw = f.getlength(p); xx = (pw - 46 - tw) / 2
            pb.alpha_composite(shop3.robux(40), (int(xx), 12)); label(pb, (xx + 46, 30), p, 40, anchor='lm')
            rb = Image.new('RGBA', (pw, gs), (0, 0, 0, 0)); d = ImageDraw.Draw(rb)
            for k in range(6):
                r_, g_, b_ = colorsys.hsv_to_rgb(k / 6, 0.8, 1); d.rectangle((k * pw // 6, gs - 7, (k + 1) * pw // 6, gs - 3), fill=(int(r_*255), int(g_*255), int(b_*255), 255))
            pb.alpha_composite(rb)
        else:
            pb = shop3.price(pw, gs, p)
        c.alpha_composite(pb, (bx + gs + 8, H - 92))
        if old:
            ox = bx + gs + 8 + 20; label(c, (ox, H - 104), old, 24, fill=(255, 70, 70), anchor='lm')
            ImageDraw.Draw(c).line((ox - 2, H - 104, ox + 56, H - 104), fill=(255, 70, 70), width=3)
        label(c, (bx + gs + 8 + pw / 2, H - 16), lbl, 22, anchor='mm')
    return bloom(c, 8, 0.2, 230)

def main(bgpath, out):
    Wd, Hd = 1600, 900
    bg = Image.open(bgpath).convert('RGBA').resize((Wd, Hd)).filter(ImageFilter.GaussianBlur(10))
    img = Image.blend(bg, Image.new('RGBA', (Wd, Hd), (40, 90, 30, 255)), 0.15)
    x0, y0, ww, wh = 160, 70, 1180, 800
    img.alpha_composite(shop3.window(ww, wh), (x0, y0))
    img.alpha_composite(sim.header(ww - 12, 100, 'green', 'Shop'), (x0 + 6, y0 + 6))
    img.alpha_composite(kit.x_mark(sim.sbox(84, 84, 'red', radius=0.04, cell=40, stud=(0, 0))), (x0 + ww - 100, y0 + 14))
    stroke_text(img, (x0 + ww / 2, y0 + 150), '-- FEATURED --', 46, (255, 245, 120), (255, 190, 20), anchor='mm')
    img.alpha_composite(card(ww - 44, 580), (x0 + 22, y0 + 192))
    from hud import gloss
    from preview import icon
    for i, (k, t) in enumerate([('star', 'Featured'), ('bolt', 'Strength'), ('cash', 'Cash'), ('gift', 'Passes')]):
        img.alpha_composite(gloss(icon(k, 100)), (x0 + ww + 22, y0 + 130 + i * 150))
        label(img, (x0 + ww + 72, y0 + 238 + i * 150), t, 26, anchor='mm')
    t = Image.new('RGBA', (Wd, 70), (0, 0, 0, 0))
    stroke_text(t, (Wd / 2 - 290, 35), 'Rong', 38, (255, 255, 255), (230, 230, 240))
    stroke_text(t, (Wd / 2 - 170, 35), 'got the', 38, (255, 255, 255), (230, 230, 240))
    stroke_text(t, (Wd / 2 + 10, 35), 'INFINITY AURA!', 38, (255, 120, 230), (160, 90, 255))
    img.alpha_composite(t, (0, 0))
    img.convert('RGB').save(out, quality=93)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
