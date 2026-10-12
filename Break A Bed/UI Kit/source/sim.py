"""Break A Bed UI in the owner's favourite 'simulator' style (Shop/Index buttons, dark studded shop)."""
import os
import sys, math, colorsys
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops
import kit
from kit import S, mix, mask_rr, vgrad, studs, label, FONT
from preview import icon, price_btn
from products import dumbbell

COL = {'green': (110, 220, 20), 'cyan': (20, 215, 245), 'red': (220, 30, 35), 'purple': (190, 40, 235),
       'yellow': (255, 215, 20), 'orange': (255, 150, 20), 'pink': (240, 60, 190), 'blue': (40, 120, 235)}
EDGE = {'green': (28, 70, 14), 'cyan': (22, 24, 70), 'red': (70, 10, 12), 'purple': (55, 12, 75),
        'yellow': (90, 60, 0), 'orange': (90, 40, 0), 'pink': (75, 10, 55), 'blue': (15, 30, 80)}

def sbox(w, h, col, radius=0.07, cell=14, stud=(30, 26)):
    base = COL[col] if isinstance(col, str) else col
    edge = EDGE[col] if isinstance(col, str) else mix(base, (0, 0, 0), 0.7)
    W, H = w * S, h * S
    m = min(w, h)
    rad = max(3, m * radius) * S
    ow = min(7, max(3, round(m * 0.06))) * S
    rim = min(4, max(2, round(m * 0.035))) * S
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    img.paste(edge + (255,), (0, 0, W, H), mask_rr((W, H), (0, 0, W - 1, H - 1), rad))
    b1 = (ow, ow, W - 1 - ow, H - 1 - ow)
    img.paste(mix(base, (255, 255, 255), 0.55) + (255,), (0, 0, W, H), mask_rr((W, H), b1, max(1, rad - ow)))
    face = (b1[0] + rim, b1[1] + rim, b1[2] - rim, b1[3] - rim)
    fm = mask_rr((W, H), face, max(1, rad - ow - rim))
    img.paste(vgrad((W, H), mix(base, (255, 255, 255), 0.12), mix(base, (0, 0, 0), 0.06), face[1], face[3]), (0, 0), fm)
    p = studs((W, H), cell * S, *stud); p.putalpha(ImageChops.multiply(p.getchannel('A'), fm)); img.alpha_composite(p)
    return img.resize((w, h), Image.LANCZOS)

def wtext(img, xy, s, size, fill=(255, 255, 255), anchor='lm', hl=None):
    """hl: a word drawn in green (like the reference's highlighted 'x2')."""
    if not hl or hl not in s:
        label(img, xy, s, size, fill=fill, anchor=anchor); return
    f = ImageFont.truetype(FONT, size)
    parts = [p for p in s.replace(hl, '|' + hl + '|').split('|') if p]
    total = sum(f.getlength(p) for p in parts) + 6 * (len(parts) - 1)
    x = xy[0] - (total / 2 if anchor == 'mm' else 0)
    for p in parts:
        label(img, (x, xy[1]), p, size, fill=(90, 230, 40) if p == hl else fill, anchor='lm')
        x += f.getlength(p) + 6

# white glyph icons with a dark outline
def glyph(kind, n, ol=(20, 20, 30)):
    W = n * S; im = Image.new('RGBA', (W, W), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    lw = int(W * 0.09)
    def draw(col, extra):
        w2 = lw + extra
        if kind == 'cart':
            d.line([(W*0.06, W*0.2), (W*0.2, W*0.2), (W*0.32, W*0.66), (W*0.82, W*0.66), (W*0.92, W*0.32), (W*0.26, W*0.32)], fill=col, width=w2, joint='curve')
            for x in (0.38, 0.76):
                r = W*0.08 + extra/2; d.ellipse((W*x-r, W*0.82-r, W*x+r, W*0.82+r), fill=col)
        elif kind == 'gift':
            e = extra/2
            d.rectangle((W*0.16-e, W*0.46-e, W*0.84+e, W*0.9+e), fill=col)
            d.rectangle((W*0.1-e, W*0.3-e, W*0.9+e, W*0.44+e), fill=col)
            d.polygon([(W*0.5, W*0.3+e), (W*0.2-e, W*0.08-e), (W*0.22-e, W*0.3+e)], fill=col)
            d.polygon([(W*0.5, W*0.3+e), (W*0.8+e, W*0.08-e), (W*0.78+e, W*0.3+e)], fill=col)
        elif kind == 'dumbbell':
            d.rectangle((W*0.2, W*0.45-extra/2, W*0.8, W*0.55+extra/2), fill=col)
            for x0, hh in ((0.08, 0.6), (0.22, 0.42), (0.68, 0.42), (0.82, 0.6)):
                d.rectangle((W*x0-extra/2, W*(0.5-hh/2)-extra/2, W*(x0+0.1)+extra/2, W*(0.5+hh/2)+extra/2), fill=col)
        elif kind == 'wheel':
            r = W*0.4 + extra/2; d.ellipse((W/2-r, W/2-r, W/2+r, W/2+r), outline=col, width=w2)
            for i in range(4):
                a = math.radians(i*45); d.line((W/2-W*0.38*math.cos(a), W/2-W*0.38*math.sin(a), W/2+W*0.38*math.cos(a), W/2+W*0.38*math.sin(a)), fill=col, width=int(w2*0.8))
        elif kind == 'gear':
            pts = []
            for i in range(48):
                a = i/48*2*math.pi; r = (0.46 if (i//3) % 2 == 0 else 0.36)*W + extra/2
                pts.append((W/2 + r*math.cos(a), W/2 + r*math.sin(a)))
            d.polygon(pts, fill=col)
    draw(ol, int(lw * 1.1))
    draw((255, 255, 255), 0)
    if kind == 'gear':
        r = W*0.14; d.ellipse((W/2-r, W/2-r, W/2+r, W/2+r), fill=ol)
    if kind == 'gift':
        d.rectangle((W*0.46, W*0.3, W*0.54, W*0.9), fill=ol)
        d.line((W*0.16, W*0.45, W*0.84, W*0.45), fill=ol, width=int(W*0.03))
    return im.resize((n, n), Image.LANCZOS)

def hud_btn(col, kind, text, w=200, h=74):
    b = sbox(w, h, col)
    b.alpha_composite(glyph(kind, int(h * 0.62)), (int(h * 0.16), int(h * 0.17)))
    fs = 32
    while ImageFont.truetype(FONT, fs).getlength(text) > w - h * 0.9: fs -= 1
    wtext(b, (h * 0.86 + (w - h * 0.86) / 2 - ImageFont.truetype(FONT, fs).getlength(text) / 2 - 6, h / 2 - 3), text, fs)
    return b

def toggle(on, w=124, h=50):
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    im.alpha_composite(sbox(w, h, (50, 80, 40) if on else (60, 62, 70), cell=12, stud=(10, 20)), (0, 0))
    k = sbox(h - 8, h - 8, 'green', cell=10)
    im.alpha_composite(k, (4 if not on else w - h + 4, 4))
    return im

def header(w, h, col='green', title='Shop'):
    b = sbox(w, h, col, radius=0.05)
    st = Image.new('RGBA', (w, h), (0, 0, 0, 0)); d = ImageDraw.Draw(st)
    for x0, ww in ((w*0.45, h*0.45), (w*0.45 + h*0.62, h*0.22), (w*0.62, h*0.32)):
        d.polygon([(x0, h), (x0 + ww, h), (x0 + ww + h*0.9, 0), (x0 + h*0.9, 0)], fill=(255, 255, 255, 60))
    m = mask_rr((w, h), (5, 5, w - 6, h - 6), 6)
    st.putalpha(ImageChops.multiply(st.getchannel('A'), m)); b.alpha_composite(st)
    wtext(b, (26, h / 2 - 2), title, int(h * 0.5))
    return b

def dark_window(w, h):
    W, H = w * S, h * S
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    img.paste((26, 27, 32, 255), (0, 0, W, H), mask_rr((W, H), (0, 0, W - 1, H - 1), 10 * S))
    body = (6 * S, 6 * S, W - 6 * S - 1, H - 6 * S - 1)
    fm = mask_rr((W, H), body, 7 * S)
    img.paste((62, 64, 72, 255), (0, 0), fm)
    p = studs((W, H), 22 * S, 14, 60); p.putalpha(ImageChops.multiply(p.getchannel('A'), fm)); img.alpha_composite(p)
    return img.resize((w, h), Image.LANCZOS)

def rainbow_card(w, h):
    strip = Image.new('RGB', (w, 1))
    for x in range(w):
        r, g, b = colorsys.hsv_to_rgb((0.12 - x / w * 1.0) % 1, 0.55, 1); strip.putpixel((x, 0), (int(r*255), int(g*255), int(b*255)))
    return strip.resize((w, h))

def card(w, h, bg, ic, title, l1, hl, l2, price):
    W, H = w, h
    c = sbox(w, h, (200, 200, 210), radius=0.03, cell=16, stud=(30, 20))
    face = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    fill = rainbow_card(w, h) if bg == 'rainbow' else vgrad((w, h), (255, 245, 120), (255, 205, 30), 0, h)
    m = mask_rr((w, h), (6, 6, w - 7, h - 7), 3)
    face.paste(fill, (0, 0), m)
    p = studs((w, h), 16, 40, 22); p.putalpha(ImageChops.multiply(p.getchannel('A'), m)); face.alpha_composite(p)
    c.alpha_composite(face)
    c.alpha_composite(ic, (18, 20))
    wtext(c, (w * 0.62, 36), title, 30, anchor='mm')
    wtext(c, (w * 0.66, 92), l1, 30, anchor='mm')
    wtext(c, (w * 0.66, 128), l2, 30, anchor='mm', hl='x2')
    gb = sbox(76, 58, 'purple', cell=10); gb.alpha_composite(glyph('gift', 38), (19, 8)); c.alpha_composite(gb, (22, h - 74))
    pb = sbox(w - 130, 58, 'green', cell=10)
    from preview import icon as ic2
    pb.alpha_composite(ic2('robux', 34), (int(pb.width/2 - 60), 10))
    wtext(pb, (pb.width / 2 - 18, 26), price, 32)
    c.alpha_composite(pb, (108, h - 74))
    return c

def main(bgpath, out):
    Wd, Hd = 1600, 900
    bg = Image.open(bgpath).convert('RGBA').resize((Wd, Hd)).filter(ImageFilter.GaussianBlur(10))
    img = Image.blend(bg, Image.new('RGBA', (Wd, Hd), (40, 80, 30, 255)), 0.15)
    # HUD left
    for i, (col, k, t) in enumerate([('green', 'cart', 'Shop'), ('orange', 'dumbbell', 'Boost'), ('purple', 'wheel', 'Spin'), ('pink', 'gift', 'Gifts'), ('cyan', 'gear', 'Settings')]):
        img.alpha_composite(hud_btn(col, k, t), (24, 230 + i * 88))
    # shop window
    x0, y0, ww, wh = 300, 70, 1020, 760
    img.alpha_composite(dark_window(ww, wh), (x0, y0))
    img.alpha_composite(header(ww - 98, 96), (x0 + 6, y0 + 6))
    xb = kit.x_mark(sbox(86, 86, 'red', radius=0.06))
    img.alpha_composite(xb, (x0 + ww - 94, y0 + 11))
    wtext(img, (x0 + ww / 2, y0 + 150), '-- PASSES --', 40, fill=(255, 226, 40), anchor='mm')
    cw = (ww - 3 * 24) // 2
    img.alpha_composite(card(cw, 250, 'rainbow', dumbbell(150), 'x2 Strength', 'Punch', '', 'x2 harder!', '19'), (x0 + 24, y0 + 190))
    img.alpha_composite(card(cw, 250, 'yellow', icon('cash', 150), 'x2 Cash', 'Get', '', 'x2 Cash!', '99'), (x0 + 48 + cw, y0 + 190))
    wtext(img, (x0 + ww / 2, y0 + 495), '-- BOOSTS --', 40, fill=(40, 220, 255), anchor='mm')
    sp = sbox(ww - 48, 120, 'cyan', radius=0.03, cell=16)
    wtext(sp, (sp.width / 2 - 10, 58), 'x3 STRENGTH for 10 min', 44, anchor='mm', hl='x3')
    img.alpha_composite(sp, (x0 + 24, y0 + 540))
    # side category icons
    for i, (k, t) in enumerate([('star', 'Passes'), ('bolt', 'Boosts'), ('cash', 'Cash'), ('gift', 'Free')]):
        icn = icon(k, 96); img.alpha_composite(icn, (x0 + ww + 30, y0 + 120 + i * 140))
        wtext(img, (x0 + ww + 78, y0 + 222 + i * 140), t, 26, anchor='mm')
    img.convert('RGB').save(out, quality=92)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])

ITAL = os.path.join(os.path.dirname(__file__), '..', 'fonts', 'Montserrat-BlackItalic.ttf') if False else None

def itext(img, xy, s, size, fill):
    import os as _os
    f = ImageFont.truetype(_os.path.join(_os.path.dirname(__file__), '..', 'fonts', 'Montserrat-BlackItalic.ttf'), size * S)
    sw = max(2, round(size * 0.1)) * S
    tmp = Image.new('RGBA', (int(f.getlength(s)) + 8 * sw, int(size * 1.6 * S)), (0, 0, 0, 0)); d = ImageDraw.Draw(tmp)
    d.text((2 * sw, tmp.height / 2 + size * 0.07 * S), s, font=f, anchor='lm', fill=(20, 20, 26), stroke_width=sw, stroke_fill=(20, 20, 26))
    d.text((2 * sw, tmp.height / 2), s, font=f, anchor='lm', fill=fill, stroke_width=sw, stroke_fill=(20, 20, 26))
    t = tmp.resize((tmp.width // S, tmp.height // S), Image.LANCZOS)
    img.alpha_composite(t, (int(xy[0]), int(xy[1] - t.height / 2)))

def square_btn(col, ic, n=86):
    b = sbox(n, n, col, radius=0.06, cell=12)
    b.alpha_composite(ic, ((n - ic.width) // 2, (n - ic.height) // 2 - 2))
    return b

def hud_main(bgpath, out):
    from hud import gloss
    Wd, Hd = 1600, 900
    bg = Image.open(bgpath).convert('RGBA').resize((Wd, Hd)).filter(ImageFilter.GaussianBlur(6))
    img = Image.blend(bg, Image.new('RGBA', (Wd, Hd), (40, 80, 30, 255)), 0.12)
    # left wide buttons
    img.alpha_composite(hud_btn('green', 'cart', 'Shop', w=196, h=76), (18, 330))
    img.alpha_composite(hud_btn('cyan', 'dumbbell', 'Boosts', w=196, h=76), (18, 418))
    tg = toggle(False); img.alpha_composite(tg, (18, 510)); label(img, (154, 534), 'Auto Punch', 24)
    # right square buttons
    for i, (col, ic) in enumerate([('red', gloss(icon('gift', 64))), ('orange', gloss(icon('wheel', 62))), ('yellow', gloss(icon('star', 62))), ('blue', glyph('gear', 58))]):
        img.alpha_composite(square_btn(col, ic), (Wd - 108, 290 + i * 100))
    # floating stats bottom-left
    img.alpha_composite(gloss(dumbbell(84)), (14, 690))
    itext(img, (104, 730), '122.1B', 50, (255, 235, 30))
    img.alpha_composite(gloss(icon('cash', 84)), (14, 770))
    itext(img, (104, 810), '$368.1T', 50, (90, 235, 60))
    itext(img, (14, 868), 'Group Bonus: +10%', 34, (255, 255, 255))
    # tutorial card top center (cyan, like the Index bar)
    tc = sbox(520, 110, 'cyan', radius=0.05)
    label(tc, (260, 34), 'Punch 10 times!', 34, anchor='mm')
    track = sbox(440, 40, (40, 44, 56), cell=12, stud=(10, 30))
    fill = sbox(150, 40, 'green', cell=12)
    track.alpha_composite(fill, (0, 0))
    label(track, (220, 18), '3/10', 26, anchor='mm')
    tc.alpha_composite(track, (40, 60))
    img.alpha_composite(tc, (Wd // 2 - 260, 24))
    sk = sbox(110, 44, 'red', radius=0.08, cell=10); label(sk, (55, 20), 'Skip', 22, anchor='mm')
    img.alpha_composite(sk, (Wd // 2 + 260 - 110, 140))
    img.convert('RGB').save(out, quality=92)

def shop2(bgpath, out):
    from hud import gloss
    Wd, Hd = 1600, 900
    bg = Image.open(bgpath).convert('RGBA').resize((Wd, Hd)).filter(ImageFilter.GaussianBlur(10))
    img = Image.blend(bg, Image.new('RGBA', (Wd, Hd), (40, 80, 30, 255)), 0.15)
    x0, y0, ww, wh = 230, 60, 1060, 790
    img.alpha_composite(dark_window(ww, wh), (x0, y0))
    img.alpha_composite(header(ww - 98, 96), (x0 + 6, y0 + 6))
    img.alpha_composite(kit.x_mark(sbox(86, 86, 'red', radius=0.06)), (x0 + ww - 94, y0 + 11))
    wtext(img, (x0 + ww / 2, y0 + 140), '-- STRENGTH --', 40, fill=(40, 220, 255), anchor='mm')
    up = sbox(ww - 48, 210, 'cyan', radius=0.03, cell=16)
    rays_ = kit.rays(700, 14, 90); up.alpha_composite(rays_.crop((0, 245, 700, 455)).resize((up.width, 210)))
    wtext(up, (up.width / 2, 40), 'DOUBLE Your STRENGTH', 40, anchor='mm', hl='DOUBLE')
    up.alpha_composite(gloss(dumbbell(150)), (30, 45))
    itext(up, (290, 128), 'x5', 92, (255, 255, 255))
    up.alpha_composite(sbox(40, 40, (255, 255, 255), cell=40, stud=(0, 0)).resize((1, 1)), (0, 0))
    ImageDraw.Draw(up).polygon([(475, 100), (475, 156), (520, 128)], fill=(255, 255, 255), outline=(20, 20, 26), width=5)
    itext(up, (540, 128), 'x7', 92, (255, 215, 30))
    pb = sbox(210, 80, 'green', cell=12); pb.alpha_composite(icon('robux', 44), (30, 16)); label(pb, (96, 37), '149', 40)
    up.alpha_composite(pb, (up.width - 230, 90))
    img.alpha_composite(up, (x0 + 24, y0 + 180))
    wtext(img, (x0 + ww / 2, y0 + 430), '-- CASH --', 40, fill=(90, 230, 60), anchor='mm')
    cw = (ww - 4 * 24) // 3
    for i, (amt, price, n) in enumerate((('+$15K', '9', 1), ('+$60K', '15', 2), ('+$250K', '30', 3))):
        c = sbox(cw, 290, 'green', radius=0.03, cell=16)
        c.alpha_composite(kit.soft_glow(260, 170), (cw // 2 - 130, 0))
        for k in range(n):
            c.alpha_composite(gloss(icon('cash', 150)), (int(cw // 2 - 75 + (k - (n - 1) / 2) * 34), 30 - k * 14))
        wtext(c, (cw / 2, 190), amt + ' CASH', 34, anchor='mm', hl=amt)
        gb = sbox(70, 62, 'purple', cell=10); gb.alpha_composite(glyph('gift', 40), (15, 9)); c.alpha_composite(gb, (16, 214))
        p2 = sbox(cw - 110, 62, 'green', cell=10)
        tw = ImageFont.truetype(FONT, 32).getlength(price); x1 = p2.width / 2 - (52 + tw) / 2
        p2.alpha_composite(icon('robux', 34), (int(x1), 12)); label(p2, (x1 + 52, 28), price, 32)
        c.alpha_composite(p2, (94, 214))
        img.alpha_composite(c, (x0 + 24 + i * (cw + 24), y0 + 475))
    for i, (k, t) in enumerate([('star', 'Passes'), ('bolt', 'Strength'), ('cash', 'Cash'), ('gift', 'Free')]):
        img.alpha_composite(gloss(icon(k, 96)), (x0 + ww + 30, y0 + 120 + i * 140))
        label(img, (x0 + ww + 78, y0 + 222 + i * 140), t, 26, anchor='mm')
    # server announcement banner (effect)
    wtext(img, (Wd / 2, 30), 'Rong broke the INFINITY BED!', 36, anchor='mm', hl='INFINITY BED!')
    img.convert('RGB').save(out, quality=92)
