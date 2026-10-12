import sys, math
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops
import kit, sim
from kit import S, mix, mask_rr, label, FONT
from preview import icon
from products import dumbbell
from hud import gloss

DARK = (24, 24, 32)

def lpat(size, cell, alpha=34, col=(0, 0, 0)):
    """The reference's subtle 'L' stud marks: a short line down the left and along the bottom of each cell."""
    lay = Image.new('RGBA', size, (0, 0, 0, 0)); d = ImageDraw.Draw(lay)
    w, h = size; lw = max(1, cell // 12); L = cell * 0.42
    for gy in range(0, h // cell + 2):
        for gx in range(0, w // cell + 2):
            x, y = gx * cell + cell * 0.3, gy * cell + cell * 0.3
            d.line((x, y, x, y + L), fill=col + (alpha,), width=lw)
            d.line((x, y + L, x + L, y + L), fill=col + (alpha,), width=lw)
    return lay

def grad2(w, h, a, b):
    """diagonal gradient a (top-left) -> b (bottom-right)"""
    g = Image.new('RGB', (w, h)); px = g.load()
    for y in range(h):
        for x in range(0, w):
            t = (x / w * 0.7 + y / h * 0.3)
            px[x, y] = mix(a, b, t)
    return g

def card(w, h, a, b, rays=True):
    W, H = w * S, h * S
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    img.paste(DARK + (255,), (0, 0, W, H), mask_rr((W, H), (0, 0, W - 1, H - 1), 4 * S))
    ow = 4 * S
    m = mask_rr((W, H), (ow, ow, W - ow - 1, H - ow - 1), 2 * S)
    img.paste(grad2(W // 4, H // 4, a, b).resize((W, H)), (0, 0), m)
    if rays:
        r = kit.rays(max(W, H), 14, 70)
        r = r.crop(((r.width - W) // 2, int(r.height * 0.12), (r.width - W) // 2 + W, int(r.height * 0.12) + H))
        r.putalpha(ImageChops.multiply(r.getchannel('A'), m)); img.alpha_composite(r)
    p = lpat((W, H), 26 * S, 30); p.putalpha(ImageChops.multiply(p.getchannel('A'), m)); img.alpha_composite(p)
    return img.resize((w, h), Image.LANCZOS)

def window(w, h):
    W, H = w * S, h * S
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    img.paste((20, 20, 26, 255), (0, 0, W, H), mask_rr((W, H), (0, 0, W - 1, H - 1), 8 * S))
    m = mask_rr((W, H), (6 * S, 6 * S, W - 6 * S - 1, H - 6 * S - 1), 5 * S)
    img.paste((44, 45, 54, 255), (0, 0), m)
    lay = Image.new('RGBA', (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(lay)
    cell = 26 * S; s = cell * 0.46
    for gy in range(H // cell + 1):
        for gx in range(W // cell + 1):
            x, y = gx * cell + cell * 0.27, gy * cell + cell * 0.27
            d.rectangle((x, y, x + s, y + s), fill=(30, 31, 38, 255))
            d.line((x, y + s, x + s, y + s), fill=(60, 62, 72, 255), width=S * 2)
    lay.putalpha(ImageChops.multiply(lay.getchannel('A'), m)); img.alpha_composite(lay)
    return img.resize((w, h), Image.LANCZOS)

def lime(w, h):
    W, H = w * S, h * S
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    img.paste((22, 60, 10, 255), (0, 0, W, H), mask_rr((W, H), (0, 0, W - 1, H - 1), 4 * S))
    m = mask_rr((W, H), (3 * S, 3 * S, W - 3 * S - 1, H - 3 * S - 1), 2 * S)
    img.paste(kit.vgrad((W, H), (150, 245, 40), (70, 200, 20), 0, H), (0, 0), m)
    p = lpat((W, H), 22 * S, 28); p.putalpha(ImageChops.multiply(p.getchannel('A'), m)); img.alpha_composite(p)
    return img.resize((w, h), Image.LANCZOS)

def purple(w, h):
    W, H = w * S, h * S
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    img.paste((40, 10, 60, 255), (0, 0, W, H), mask_rr((W, H), (0, 0, W - 1, H - 1), 4 * S))
    m = mask_rr((W, H), (3 * S, 3 * S, W - 3 * S - 1, H - 3 * S - 1), 2 * S)
    img.paste(kit.vgrad((W, H), (220, 90, 255), (160, 40, 220), 0, H), (0, 0), m)
    return img.resize((w, h), Image.LANCZOS)

def robux(n):
    W = n * S; im = Image.new('RGBA', (W, W), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    pts = [(W/2 + W*0.46*math.cos(math.radians(a)), W/2 + W*0.46*math.sin(math.radians(a))) for a in range(-90, 270, 60)]
    d.polygon(pts, fill=DARK)
    sc = lambda k: [(W/2 + (x-W/2)*k, W/2 + (y-W/2)*k) for x, y in pts]
    d.polygon(sc(0.82), fill=(255, 255, 255)); d.polygon(sc(0.55), fill=DARK); d.polygon(sc(0.37), fill=(255, 255, 255))
    return im.resize((n, n), Image.LANCZOS)

def price(w, h, amount):
    b = lime(w, h)
    fs = int(h * 0.62); f = ImageFont.truetype(FONT, fs)
    isz = int(h * 0.62); tw = f.getlength(amount); x = (w - isz - 8 - tw) / 2
    b.alpha_composite(robux(isz), (int(x), (h - isz) // 2))
    label(b, (x + isz + 6, h / 2 - 2), amount, fs, anchor='lm')
    return b

def giftbtn(s):
    b = purple(s, s); b.alpha_composite(sim.glyph('gift', int(s * 0.62)), (int(s * 0.19), int(s * 0.16))); return b

def item(w, h, a, b, ic, amt, word, cost, amt_col=(110, 240, 40)):
    c = card(w, h, a, b)
    c.alpha_composite(ic, ((w - ic.width) // 2, -8))
    sim.wtext(c, (w / 2, h - 96), amt + ' ' + word, 30, anchor='mm', hl=amt) if amt_col == (110, 240, 40) else None
    gs = 56
    c.alpha_composite(giftbtn(gs), (14, h - gs - 14))
    c.alpha_composite(price(w - gs - 40, gs, cost), (gs + 24, h - gs - 14))
    return c

def main(bgpath, out):
    Wd, Hd = 1600, 900
    bg = Image.open(bgpath).convert('RGBA').resize((Wd, Hd)).filter(ImageFilter.GaussianBlur(10))
    img = Image.blend(bg, Image.new('RGBA', (Wd, Hd), (40, 90, 30, 255)), 0.15)
    x0, y0, ww, wh = 220, 60, 1080, 790
    img.alpha_composite(window(ww, wh), (x0, y0))
    hd = sim.header(ww - 12, 100, 'green', 'Shop')
    img.alpha_composite(hd, (x0 + 6, y0 + 6))
    xb = kit.x_mark(sim.sbox(84, 84, 'red', radius=0.04, cell=40, stud=(0, 0)))
    img.alpha_composite(xb, (x0 + ww - 100, y0 + 14))
    sim.wtext(img, (x0 + ww / 2, y0 + 150), '-- CASH --', 44, fill=(110, 240, 40), anchor='mm')
    cw, ch, gap = (ww - 48 - 2 * 18) // 3, 280, 18
    packs = [('+$15K', '9', 1), ('+$60K', '15', 2), ('+$250K', '30', 3), ('+$1M', '49', 4)]
    for i, (amt, cost, n) in enumerate(packs[:3]):
        import art
        ic = art.cash_pile(200, {1: 1, 2: 3, 3: 5}[n])
        c = item(cw, ch, (40, 170, 20), (120, 230, 60), ic, amt, 'CASH', cost)
        img.alpha_composite(c, (x0 + 24 + i * (cw + gap), y0 + 190))
    sim.wtext(img, (x0 + ww / 2, y0 + 520), '-- STRENGTH --', 44, fill=(40, 210, 255), anchor='mm')
    up = card(ww - 48, 230, (20, 150, 240), (70, 220, 255))
    sim.wtext(up, (up.width / 2, 44), 'DOUBLE Your STRENGTH', 44, anchor='mm', hl='DOUBLE')
    up.alpha_composite(gloss(dumbbell(170)), (40, 50))
    sim.itext(up, (300, 140), 'x5', 104, (255, 255, 255))
    ImageDraw.Draw(up).polygon([(500, 108), (500, 172), (548, 140)], fill=(255, 255, 255), outline=DARK, width=5)
    sim.itext(up, (566, 140), 'x7', 104, (255, 210, 30))
    up.alpha_composite(price(220, 84, '149'), (up.width - 250, 100))
    img.alpha_composite(up, (x0 + 24, y0 + 565))
    for i, (k, t) in enumerate([('star', 'Passes'), ('bolt', 'Strength'), ('cash', 'Cash')]):
        img.alpha_composite(gloss(icon(k, 104)), (x0 + ww + 26, y0 + 150 + i * 160))
        label(img, (x0 + ww + 78, y0 + 262 + i * 160), t, 28, anchor='mm')
    img.convert('RGB').save(out, quality=92)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
