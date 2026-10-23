import sys, math, random
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import aura2 as A, fx, kit, sim, shop3
from kit import mix, label, FONT
random.seed(31)
OL = (20, 12, 24)

def bat(n, col=(25, 15, 30)):
    W = n * 4; im = Image.new('RGBA', (W, W), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    c = W / 2
    pts = [(c, W*.42), (c-W*.08, W*.36), (c-W*.18, W*.3), (c-W*.3, W*.32), (c-W*.46, W*.42), (c-W*.38, W*.5), (c-W*.3, W*.46),
           (c-W*.26, W*.56), (c-W*.18, W*.5), (c-W*.1, W*.6), (c, W*.62)]
    full = pts + [(2*c - x, y) for x, y in reversed(pts)]
    d.polygon(full, fill=col)
    d.ellipse((c-W*.07, W*.34, c+W*.07, W*.6), fill=col)
    d.polygon([(c-W*.06, W*.36), (c-W*.04, W*.28), (c-W*.01, W*.36)], fill=col)
    d.polygon([(c+W*.06, W*.36), (c+W*.04, W*.28), (c+W*.01, W*.36)], fill=col)
    for sx in (-1, 1): d.ellipse((c+sx*W*.035-W*.012, W*.42, c+sx*W*.035+W*.012, W*.445), fill=(255, 200, 60))
    return im.resize((n, n), Image.LANCZOS)

def ghost(n):
    W = n * 4; im = Image.new('RGBA', (W, W), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.ellipse((W*.25, W*.12, W*.75, W*.62), fill=(250, 250, 255))
    d.rectangle((W*.25, W*.37, W*.75, W*.78), fill=(250, 250, 255))
    for i in range(4):
        x = W*.25 + i * W*.125; d.ellipse((x, W*.7, x + W*.125, W*.86), fill=(250, 250, 255))
    for sx in (-1, 1): d.ellipse((W*.5+sx*W*.1-W*.045, W*.32, W*.5+sx*W*.1+W*.045, W*.44), fill=OL)
    d.ellipse((W*.45, W*.48, W*.55, W*.6), fill=OL)
    return A.bloom(im.resize((n, n), Image.LANCZOS), n * .02, .3)

def pumpkin(n):
    W = n * 4; im = Image.new('RGBA', (W, W), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    for k, (x0, x1) in enumerate(((.12, .48), (.52, .88), (.28, .72))):
        d.ellipse((W*x0, W*.3, W*x1, W*.86), fill=(240, 120, 20) if k < 2 else (255, 150, 30), outline=(150, 60, 10), width=int(W*.01))
    d.rectangle((W*.46, W*.18, W*.54, W*.32), fill=(70, 120, 40))
    glowc = (255, 230, 90)
    d.polygon([(W*.32, W*.52), (W*.4, W*.42), (W*.46, W*.54)], fill=glowc)
    d.polygon([(W*.68, W*.52), (W*.6, W*.42), (W*.54, W*.54)], fill=glowc)
    d.polygon([(W*.28, W*.64), (W*.72, W*.64), (W*.64, W*.76), (W*.56, W*.7), (W*.5, W*.78), (W*.44, W*.7), (W*.36, W*.76)], fill=glowc)
    return A.bloom(im.resize((n, n), Image.LANCZOS), n * .03, .5, 200)

def web(n):
    W = n * 4; im = Image.new('RGBA', (W, W), (0, 0, 0, 0)); d = ImageDraw.Draw(im); c = W / 2
    for i in range(8):
        a = i * math.pi / 4; d.line((c, c, c + W*.46*math.cos(a), c + W*.46*math.sin(a)), fill=(235, 240, 255), width=int(W*.012))
    for r in (.12, .22, .32, .42):
        pts = [(c + W*r*math.cos(i*math.pi/4), c + W*r*math.sin(i*math.pi/4)) for i in range(9)]
        for i in range(8):
            mx, my = (pts[i][0]+pts[i+1][0])/2, (pts[i][1]+pts[i+1][1])/2
            mx, my = c + (mx-c)*0.86, c + (my-c)*0.86
            d.line([pts[i], (mx, my), pts[i+1]], fill=(235, 240, 255), width=int(W*.009), joint='curve')
    d.ellipse((c-W*.07, c-W*.05, c+W*.07, c+W*.11), fill=(30, 20, 40)); d.ellipse((c-W*.05, c-W*.13, c+W*.05, c-W*.03), fill=(30, 20, 40))
    for sx in (-1, 1):
        for k in range(4): d.line((c, c+W*.02+k*W*.02, c+sx*W*.16, c-W*.06+k*W*.07), fill=(30, 20, 40), width=int(W*.012))
    for sx in (-1, 1): d.ellipse((c+sx*W*.02-W*.01, c-W*.1, c+sx*W*.02+W*.01, c-W*.08), fill=(255, 60, 60))
    return im.resize((n, n), Image.LANCZOS)

def cursed(n):
    im = Image.new('RGBA', (n, n), (0, 0, 0, 0))
    for i in range(11):
        h = n * (0.35 + 0.35 * random.random())
        sh = fx.shards().resize((int(n*.2), int(h))).rotate(random.uniform(-15, 15), expand=True)
        im.alpha_composite(A.tint(sh, random.choice([(90, 255, 90), (40, 200, 60), (190, 255, 140)])), (int(n*.15 + i*n*.06), int(n*.85 - sh.height)))
    sk = Image.new('RGBA', (n * 4, n * 4), (0, 0, 0, 0)); d = ImageDraw.Draw(sk); W = n * 4
    d.ellipse((W*.36, W*.36, W*.64, W*.62), fill=(235, 240, 225)); d.rectangle((W*.41, W*.56, W*.59, W*.68), fill=(235, 240, 225))
    for sx in (-1, 1): d.ellipse((W*.5+sx*W*.065-W*.045, W*.45, W*.5+sx*W*.065+W*.045, W*.54), fill=(30, 120, 40))
    for k in range(4): d.line((W*.43+k*W*.045, W*.6, W*.43+k*W*.045, W*.68), fill=(80, 90, 80), width=int(W*.008))
    im.alpha_composite(sk.resize((n, n), Image.LANCZOS))
    return A.bloom(im, n * .03, .4)

def reaper(n):
    W = n * 4; im = Image.new('RGBA', (W, W), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.line((W*.7, W*.1, W*.62, W*.92), fill=(120, 80, 50), width=int(W*.03))
    d.pieslice((W*.28, W*.02, W*.98, W*.42), 180, 300, fill=(200, 210, 230))
    d.pieslice((W*.34, W*.08, W*.92, W*.38), 180, 300, fill=(0, 0, 0, 0))
    d.polygon([(W*.5, W*.16), (W*.28, W*.4), (W*.2, W*.92), (W*.8, W*.92), (W*.72, W*.4)], fill=(30, 22, 40))
    d.ellipse((W*.36, W*.2, W*.64, W*.5), fill=(30, 22, 40)); d.ellipse((W*.41, W*.28, W*.59, W*.48), fill=(5, 2, 10))
    for sx in (-1, 1): d.ellipse((W*.5+sx*W*.04-W*.02, W*.35, W*.5+sx*W*.04+W*.02, W*.39), fill=(255, 40, 60))
    out = im.resize((n, n), Image.LANCZOS)
    g = Image.new('RGBA', (n, n), (0, 0, 0, 0)); g.alpha_composite(A.tint(fx.glow().resize((n, n)), (255, 60, 120), .5)); g.alpha_composite(out)
    return A.bloom(g, n * .03, .5, 180)

def scene(w, h):
    bg = Image.new('RGB', (w, h)); px = bg.load()
    for y in range(h):
        for x in range(w):
            t = min(1, ((x - w*.75) ** 2 + (y - h*.25) ** 2) ** .5 / (w * .9))
            px[x, y] = mix((110, 50, 140), (14, 8, 28), t ** .7)
    im = bg.convert('RGBA'); d = ImageDraw.Draw(im)
    # moon
    mx, my, mr = w * .8, h * .3, h * .2
    im.alpha_composite(A.tint(fx.glow().resize((int(mr*5),)*2), (255, 200, 120), .6), (int(mx - mr*2.5), int(my - mr*2.5)))
    d.ellipse((mx - mr, my - mr, mx + mr, my + mr), fill=(255, 225, 150))
    for cx, cy, r in ((.3, -.2, .2), (-.35, .3, .15), (.1, .45, .1)): d.ellipse((mx+cx*mr*2-r*mr, my+cy*mr*2-r*mr, mx+cx*mr*2+r*mr, my+cy*mr*2+r*mr), fill=(235, 195, 120))
    # orange haze at the bottom
    hz = Image.new('RGBA', (w, h), (0, 0, 0, 0)); ImageDraw.Draw(hz).ellipse((-w*.2, h*.62, w*1.2, h*1.5), fill=(255, 110, 20, 120))
    im.alpha_composite(hz.filter(ImageFilter.GaussianBlur(50)))
    # graveyard silhouette
    d = ImageDraw.Draw(im); ground = (16, 10, 22)
    d.polygon([(0, h), (0, h*.86), (w*.2, h*.82), (w*.45, h*.86), (w*.7, h*.8), (w, h*.84), (w, h)], fill=ground)
    for x in (.38, .5, .62, .9):
        gx, gy = w*x, h*.83; d.rounded_rectangle((gx - 16, gy - 46, gx + 16, gy + 10), 14, fill=ground)
    d.rectangle((w*.95 - 4, h*.62, w*.95 + 4, h*.84), fill=ground); d.rectangle((w*.95 - 18, h*.68, w*.95 + 18, h*.7), fill=ground)
    for k in range(9):
        b = bat(random.randint(30, 60)); im.alpha_composite(b, (int(w*.45 + random.random()*w*.5), int(random.random()*h*.45)))
    for _ in range(80):
        x, y, s = random.uniform(0, w), random.uniform(0, h*.7), random.random() * 1.8 + .5
        d.ellipse((x-s, y-s, x+s, y+s), fill=(255, 240, 220, 200))
    return im

AURAS = [('Ghost', ghost, '40%', 'common'), ('Bats', None, '30%', 'rare'), ('Web', web, '18%', 'epic'),
         ('Pumpkin', pumpkin, '9%', 'legend'), ('Cursed', cursed, '2.9%', 'mythic'), ('Reaper', reaper, '0.1%', 'secret')]

def bats_art(n):
    im = Image.new('RGBA', (n, n), (0, 0, 0, 0))
    im.alpha_composite(A.tint(fx.glow().resize((n, n)), (255, 120, 30), .55))
    for (x, y, s) in ((.5, .45, .62), (.24, .28, .34), (.76, .26, .3), (.3, .72, .3), (.74, .7, .28)):
        b = bat(int(n * s)); im.alpha_composite(b, (int(n*x - b.width/2), int(n*y - b.height/2)))
    return im

def art(name, n):
    f = dict(Ghost=ghost, Bats=bats_art, Web=web, Pumpkin=pumpkin, Cursed=cursed, Reaper=reaper)[name]
    return f(n)

def card(W, H):
    A.scene = scene
    A.aura_art = lambda kind, n: art(kind, n)
    c = Image.new('RGBA', (W, H), A.DARK + (255,))
    c.paste(kit.vgrad((W, H), (255, 160, 40), (200, 70, 10), 0, H), (0, 0)); c.paste(A.DARK + (255,), (6, 6, W - 6, H - 6))
    c.alpha_composite(scene(W - 16, H - 16), (8, 8))
    hero = Image.new('RGBA', (440, 440), (0, 0, 0, 0))
    hero.alpha_composite(A.burst(440, (255, 120, 30), 16, 80)); hero.alpha_composite(pumpkin(380), (30, 40))
    c.alpha_composite(hero, (-40, 60))
    nb = sim.sbox(150, 54, 'red', radius=0.04, cell=40, stud=(0, 0)); label(nb, (75, 25), 'New!', 30, anchor='mm'); c.alpha_composite(nb, (24, 22))
    A.stroke_text(c, (190, 50), 'HALLOWEEN AURAS', 54, (255, 200, 60), (255, 110, 10))
    label(c, (196, 100), 'Limited Time! Ends Nov 1', 26, anchor='lm')
    A.stroke_text(c, (W - 26, 50), '19d 08h 41m', 32, (255, 255, 255), (225, 225, 235), anchor='rm')
    x = 290; base = H - 108
    for (nm, _, pct, rar), sz in zip(AURAS, (104, 112, 120, 130, 142, 186)):
        h_ = sz + (30 if rar == 'secret' else 0)
        s = A.slot(sz, h_, rar, art(nm, 220), pct, 'REAPER' if rar == 'secret' else None)
        c.alpha_composite(s, (x, base - h_)); x += sz + 10
    gs = 64; colw = (W - 60) // 3
    import colorsys
    for i, (p, lbl, red, old) in enumerate((('399', '10 Auras', True, '490'), ('129', '3 Auras', False, None), ('49', '1 Aura', False, None))):
        bx = 30 + i * colw; c.alpha_composite(shop3.giftbtn(gs), (bx, H - 92)); pw = colw - gs - 24
        if red:
            pb = sim.sbox(pw, gs, 'orange', radius=0.04, cell=22, stud=(22, 22)); f = ImageFont.truetype(FONT, 40); tw = f.getlength(p); xx = (pw - 46 - tw) / 2
            pb.alpha_composite(shop3.robux(40), (int(xx), 12)); label(pb, (xx + 46, 30), p, 40, anchor='lm')
        else:
            pb = shop3.price(pw, gs, p)
        c.alpha_composite(pb, (bx + gs + 8, H - 92))
        if old:
            ox = bx + gs + 28; label(c, (ox, H - 104), old, 24, fill=(255, 70, 70), anchor='lm'); ImageDraw.Draw(c).line((ox - 2, H - 104, ox + 56, H - 104), fill=(255, 70, 70), width=3)
        label(c, (bx + gs + 8 + pw / 2, H - 16), lbl, 22, anchor='mm')
    return A.bloom(c, 8, .2, 230)

def main(bgpath, out):
    Wd, Hd = 1600, 900
    bg = Image.open(bgpath).convert('RGBA').resize((Wd, Hd)).filter(ImageFilter.GaussianBlur(10))
    img = Image.blend(bg, Image.new('RGBA', (Wd, Hd), (40, 30, 50, 255)), 0.25)
    x0, y0, ww, wh = 160, 70, 1180, 800
    img.alpha_composite(shop3.window(ww, wh), (x0, y0))
    img.alpha_composite(sim.header(ww - 12, 100, 'orange', 'Shop'), (x0 + 6, y0 + 6))
    img.alpha_composite(kit.x_mark(sim.sbox(84, 84, 'red', radius=0.04, cell=40, stud=(0, 0))), (x0 + ww - 100, y0 + 14))
    A.stroke_text(img, (x0 + ww / 2, y0 + 150), '-- FEATURED --', 46, (255, 200, 60), (255, 110, 10), anchor='mm')
    img.alpha_composite(card(ww - 44, 580), (x0 + 22, y0 + 192))
    t = Image.new('RGBA', (Wd, 70), (0, 0, 0, 0))
    A.stroke_text(t, (Wd / 2 - 300, 35), 'Rong got the', 38, (255, 255, 255), (230, 230, 240))
    A.stroke_text(t, (Wd / 2 - 20, 35), 'REAPER AURA!', 38, (255, 90, 120), (200, 30, 80))
    img.alpha_composite(t, (0, 0))
    img.convert('RGB').save(out, quality=93)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
