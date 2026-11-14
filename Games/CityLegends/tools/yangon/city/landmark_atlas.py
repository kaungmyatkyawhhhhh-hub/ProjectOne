"""landmark_atlas.py [outdir]: the picture atlas for the Myanmar Centre landmark (Myanmar Plaza mall, its two office towers,
the Melia hotel, the Lake Suites tower, the corner plinth), 2026-11-14 building pilot.

Writes <outdir>/mc_atlas.png (day colours), mc_atlas_night.png (night colours), mc_atlas_mask.png (emissive mask) and
mc_atlas.json: { region name: [x0, y0, x1, y1] in pixels } on a 1024 x 1024 picture.

Rows that tile along a facade span the full width (glb.py: U may run past 0..1, so a row repeats sideways). One row = one
storey. References: Wikimedia Commons photos Myanmar_Plaza_IMG_5386..5391 / 5111 (Bjoertvedt, CC BY-SA 4.0), "Construction
rush" (panoramio), only looked at. Colours and ratios from the critique panel of 2026-11-14 (warm champagne spandrels, dark
blue-grey glass, speckled beige granite podium, dark maroon polished granite plinth). No logos and no brand names: the
landmark's own names as plain text (owner rule, 2026-11-13); ads are made-up shapes, no phone numbers.
"""
import json
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

W = H = 1024
FONT = "C:/Windows/Fonts/arialbd.ttf"
FONT2 = "C:/Windows/Fonts/bahnschrift.ttf"
FONT3 = "C:/Windows/Fonts/segoeui.ttf"

R = {}  # region name -> [x0, y0, x1, y1]


def reg(name, x0, y0, x1, y1):
    R[name] = [x0, y0, x1, y1]
    return x0, y0, x1, y1


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def main(out):
    rnd = random.Random(7)
    day = Image.new("RGB", (W, H), (255, 255, 255))
    night = Image.new("RGB", (W, H), (0, 0, 0))
    mask = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(day)
    n = ImageDraw.Draw(night)
    m = ImageDraw.Draw(mask)

    def speckle(x0, y0, x1, y1, base, var, step=2):
        for yy in range(y0, y1):
            for xx in range(x0, x1, step):
                v = rnd.randint(-var, var)
                d.line([xx, yy, xx + step - 1, yy], fill=tuple(max(0, min(255, c + v)) for c in base))

    # ---------- office storeys: a spandrel band over a ribbon of glass with mullions, blinds and a floor-slab line ----------
    # (in-game critique, 2026-11-14: 1-px mullions vanished, both towers read as the same blue-and-white barcode; the
    # map's light is bright and cool, so A's champagne is pushed warmer and more saturated, B is a cooler silver-white)
    def office_row(name, y0, spandrel, glass_hi, glass_lo, band, bay=32, lit=0.5, mull=(150, 140, 118), mw=3):
        reg(name, 0, y0, 1024, y0 + 64)
        for yy in range(y0, y0 + band):
            d.line([0, yy, 1023, yy], fill=lerp(spandrel, lerp(spandrel, (0, 0, 0), 0.14), (yy - y0) / band))
        d.line([0, y0, 1023, y0], fill=lerp(spandrel, (255, 255, 255), 0.35))
        d.line([0, y0 + band - 1, 1023, y0 + band - 1], fill=lerp(spandrel, (40, 40, 40), 0.45))
        for i in range(1024 // bay):
            bx = i * bay
            t = rnd.random()
            for yy in range(y0 + band, y0 + 62):
                k = (yy - y0 - band) / (62 - band)
                d.line([bx, yy, bx + bay - 1, yy], fill=lerp(glass_hi, glass_lo, k * 0.85 + t * 0.15))
            # blinds: a lighter band from the top of the glass down 20-60 % of it, in about half the bays
            if rnd.random() < 0.55:
                bh = int((62 - band) * rnd.uniform(0.2, 0.6))
                d.rectangle([bx, y0 + band, bx + bay - 1, y0 + band + bh], fill=lerp(glass_hi, (190, 190, 184), 0.5))
            d.line([bx, y0 + band + 2, bx + bay - 1, y0 + band + 2], fill=lerp(glass_hi, (160, 176, 190), 0.45))
            d.rectangle([bx, y0 + band, bx + mw - 1, y0 + 61], fill=mull)
            if rnd.random() < lit:
                c = rnd.choice([(255, 248, 228), (236, 244, 255), (255, 236, 196)])
                n.rectangle([bx + mw, y0 + band + 1, bx + bay - 1, y0 + 60], fill=c)
                m.rectangle([bx + mw, y0 + band + 1, bx + bay - 1, y0 + 60], fill=rnd.choice([140, 180, 220]))
            else:
                n.rectangle([bx + mw, y0 + band + 1, bx + bay - 1, y0 + 60], fill=(16, 22, 30))
        d.rectangle([0, y0 + 62, 1023, y0 + 63], fill=lerp(glass_lo, (0, 0, 0), 0.4))  # floor slab line

    office_row("officeA", 0, (206, 178, 132), (62, 78, 94), (24, 32, 44), band=30, mull=(170, 148, 110))
    office_row("officeB", 64, (222, 222, 216), (48, 64, 82), (18, 26, 36), band=16, bay=16, mull=(186, 186, 182), mw=2)
    office_row("melia", 128, (244, 242, 236), (70, 92, 112), (28, 40, 56), band=34, lit=0.6, mull=(214, 214, 210))

    # ---------- Lake Suites: cream wall, punched windows with balcony rails ----------
    x0, y0, x1, y1 = reg("resid", 0, 192, 1024, 256)
    d.rectangle([0, y0, 1023, y1 - 1], fill=(236, 230, 214))
    for i in range(16):
        bx = i * 64
        d.rectangle([bx + 8, y0 + 14, bx + 56, y0 + 56], fill=(62, 82, 100))
        d.rectangle([bx + 8, y0 + 14, bx + 56, y0 + 19], fill=(140, 160, 176))
        d.line([bx + 6, y0 + 44, bx + 58, y0 + 44], fill=(210, 210, 206), width=2)
        for k in range(bx + 10, bx + 56, 6):
            d.line([k, y0 + 44, k, y0 + 56], fill=(190, 190, 186))
        d.rectangle([bx + 6, y0 + 56, bx + 58, y0 + 59], fill=(208, 200, 184))
        if rnd.random() < 0.5:
            c = rnd.choice([(255, 226, 170), (255, 240, 210), (230, 236, 255)])
            n.rectangle([bx + 10, y0 + 22, bx + 54, y0 + 43], fill=c)
            m.rectangle([bx + 10, y0 + 22, bx + 54, y0 + 43], fill=rnd.choice([140, 190, 220]))

    # ---------- podium (mall) storey: speckled warm granite spandrel, recessed dark glass ribbon (62 %) ----------
    x0, y0, x1, y1 = reg("podium", 0, 256, 1024, 320)
    speckle(0, y0, 1024, y0 + 20, (160, 146, 126), 8)
    speckle(0, y0 + 60, 1024, y1, (160, 146, 126), 8)
    for yy in range(y0 + 20, y0 + 60):
        d.line([0, yy, 1023, yy], fill=lerp((56, 68, 80), (28, 38, 48), (yy - y0 - 20) / 40))
    d.rectangle([0, y0 + 20, 1023, y0 + 22], fill=(52, 50, 46))  # shadow under the granite lip
    for i in range(0, 1024, 48):
        d.rectangle([i, y0 + 23, i + 1, y0 + 59], fill=(196, 196, 192))
        d.line([i, y0, i, y0 + 19], fill=(140, 128, 108))
        d.line([i, y0 + 60, i, y1 - 1], fill=(140, 128, 108))
    for i in range(0, 1024, 48):
        if rnd.random() < 0.6:
            c = rnd.choice([(255, 238, 200), (255, 246, 226), (236, 240, 255)])
            n.rectangle([i + 2, y0 + 23, i + 47, y0 + 59], fill=c)
            m.rectangle([i + 2, y0 + 23, i + 47, y0 + 59], fill=rnd.choice([110, 150, 190]))

    # ---------- shopfront storey: a light soffit band, near-black granite piers, a sign band, lit shop interiors ----------
    x0, y0, x1, y1 = reg("shop", 0, 320, 1024, 384)
    d.rectangle([0, y0, 1023, y0 + 9], fill=(220, 214, 204))
    d.line([0, y0 + 9, 1023, y0 + 9], fill=(120, 116, 110))
    shops = ["CAFE", "SHOES", "BOOKS", "BAKERY", "MOBILE", "FASHION", "OPTICS", "TEA", "SPORT", "BEAUTY", "TOYS", "WATCH",
             "GIFTS", "MUSIC", "BAGS", "JUICE"]
    fsign = ImageFont.truetype(FONT, 8)
    for i in range(16):
        bx = i * 64
        inner = rnd.choice([(250, 226, 180), (236, 230, 214), (250, 236, 206), (240, 214, 178), (226, 232, 236)])
        for yy in range(y0 + 18, y1):
            k = (yy - y0 - 18) / 46
            d.line([bx + 10, yy, bx + 63, yy], fill=lerp((120, 116, 108), inner, 0.45 + 0.4 * k))
        d.rectangle([bx + 10, y0 + 10, bx + 63, y0 + 17], fill=(26, 28, 32))
        t = shops[i]
        tw = d.textlength(t, font=fsign)
        col = rnd.choice([(255, 255, 255), (246, 206, 120), (255, 236, 200)])
        d.text((bx + 10 + (54 - tw) / 2, y0 + 9), t, font=fsign, fill=col)
        n.text((bx + 10 + (54 - tw) / 2, y0 + 9), t, font=fsign, fill=col)
        m.text((bx + 10 + (54 - tw) / 2, y0 + 9), t, font=fsign, fill=255)
        for k in range(rnd.randint(2, 3)):  # shelves / mannequins
            sx = bx + 14 + k * 16 + rnd.randint(0, 6)
            sw = rnd.randint(4, 8)
            d.rectangle([sx, y1 - 26, sx + sw, y1 - 3], fill=lerp(inner, (40, 36, 34), 0.65))
        d.line([bx + 10, y1 - 2, bx + 63, y1 - 2], fill=(236, 232, 224), width=2)
        d.rectangle([bx, y0 + 10, bx + 9, y1 - 1], fill=(30, 30, 34))
        d.line([bx + 2, y0 + 10, bx + 2, y1 - 1], fill=(60, 60, 66))
        n.rectangle([bx + 10, y0 + 18, bx + 63, y1 - 2], fill=lerp(inner, (255, 255, 255), 0.3))
        m.rectangle([bx + 10, y0 + 18, bx + 63, y1 - 2], fill=210)
    n.rectangle([0, y0, 1023, y0 + 9], fill=(255, 236, 200))
    m.rectangle([0, y0, 1023, y0 + 9], fill=90)

    # ---------- crown storeys of the towers: plain champagne panels ----------
    x0, y0, x1, y1 = reg("crown", 0, 384, 1024, 448)
    for yy in range(y0, y1):
        d.line([0, yy, 1023, yy], fill=lerp((210, 184, 142), (194, 168, 128), (yy - y0) / 64))
    for i in range(0, 1024, 64):
        d.line([i, y0, i, y1 - 1], fill=(200, 178, 140))
    d.line([0, y0 + 32, 1023, y0 + 32], fill=(200, 178, 140))

    # ---------- squares ----------
    x0, y0, x1, y1 = reg("roof", 0, 448, 256, 704)
    d.rectangle([x0, y0, x1 - 1, y1 - 1], fill=(150, 152, 152))
    for r in range(8):
        yy = y0 + 8 + r * 31
        d.rectangle([x0 + 8, yy, x1 - 9, yy + 21], fill=(52, 64, 86))
        for k in range(x0 + 8, x1 - 9, 12):
            d.line([k, yy, k, yy + 21], fill=(86, 98, 118))
    x0, y0, x1, y1 = reg("dome", 256, 448, 384, 704)
    d.rectangle([x0, y0, x1 - 1, y1 - 1], fill=(236, 232, 222))
    for k in range(x0, x1, 16):
        d.line([k, y0, k, y1 - 1], fill=(200, 196, 188), width=2)
    # soffit: light grey panels with dark ribs (canopy undersides), glowing warm at night
    x0, y0, x1, y1 = reg("soffit", 384, 448, 512, 704)
    d.rectangle([x0, y0, x1 - 1, y1 - 1], fill=(206, 204, 200))
    for k in range(x0, x1, 16):
        d.line([k, y0, k, y1 - 1], fill=(120, 118, 114), width=2)
    for k in range(y0, y1, 32):
        d.line([x0, k, x1 - 1, k], fill=(150, 148, 144))
    for k in range(x0 + 8, x1, 32):
        for j in range(y0 + 16, y1, 64):
            d.ellipse([k - 3, j - 3, k + 3, j + 3], fill=(250, 246, 230))
            n.ellipse([k - 4, j - 4, k + 4, j + 4], fill=(255, 236, 190))
            m.ellipse([k - 4, j - 4, k + 4, j + 4], fill=255)
    x0, y0, x1, y1 = reg("garden", 512, 448, 768, 704)
    d.rectangle([x0, y0, x1 - 1, y1 - 1], fill=(196, 160, 140))
    for _ in range(40):
        cx, cy = rnd.randint(x0, x1), rnd.randint(y0, y1)
        rr = rnd.randint(8, 22)
        d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=rnd.choice([(74, 120, 60), (90, 140, 70), (60, 104, 52)]))
    d.rectangle([x0 + 150, y0 + 40, x0 + 230, y0 + 120], fill=(70, 170, 200))
    # polished dark maroon granite, large slabs, faint joints and a sheen near the top
    x0, y0, x1, y1 = reg("granite", 768, 448, 1024, 576)
    speckle(x0, y0, x1, y1, (78, 40, 38), 6)
    for yy in range(y0, y0 + 30):
        for xx in range(x0, x1, 4):
            px = day.getpixel((xx, yy))
            day.putpixel((xx, yy), lerp(px, (150, 96, 88), 0.18 * (1 - (yy - y0) / 30)))
    for xx in range(x0 + 64, x1, 64):
        d.line([xx, y0, xx, y1 - 1], fill=(62, 30, 28))
    d.line([x0, y0 + 64, x1 - 1, y0 + 64], fill=(62, 30, 28))
    # leafy clipped hedge: mid green clumps, lighter top half
    x0, y0, x1, y1 = reg("hedge", 768, 576, 1024, 704)
    for yy in range(y0, y1):
        d.line([x0, yy, x1 - 1, yy], fill=lerp((104, 150, 62), (54, 92, 38), (yy - y0) / (y1 - y0)))
    for _ in range(700):
        cx, cy = rnd.randint(x0, x1 - 1), rnd.randint(y0, y1 - 1)
        rr = rnd.randint(2, 5)
        top = (cy - y0) / (y1 - y0)
        d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr],
                  fill=lerp(rnd.choice([(120, 168, 70), (70, 112, 44), (96, 140, 58)]), (40, 70, 30), top * 0.5))

    # ---------- LED screen and billboards: photo-like made-up ads (in-game critique: clip-art read as placeholder) ----------
    def soft(img_w, img_h, draw_fn, blur):
        """Draw on a transparent layer and blur it (soft shadows, glows)."""
        layer = Image.new("RGBA", (img_w, img_h), (0, 0, 0, 0))
        draw_fn(ImageDraw.Draw(layer))
        return layer.filter(ImageFilter.GaussianBlur(blur))

    def vgrad(w, h, stops):
        g = Image.new("RGB", (w, h))
        gd = ImageDraw.Draw(g)
        for yy in range(h):
            t = yy / max(h - 1, 1)
            for i in range(len(stops) - 1):
                t0, c0 = stops[i]
                t1, c1 = stops[i + 1]
                if t0 <= t <= t1:
                    gd.line([0, yy, w - 1, yy], fill=lerp(c0, c1, (t - t0) / max(t1 - t0, 1e-6)))
                    break
        return g

    # LED: a made-up sports car on a coastal road at sunset, a bold headline, the mall's orange header / footer bars
    x0, y0, x1, y1 = reg("screen", 0, 704, 384, 896)
    W_, H_ = x1 - x0, y1 - y0
    hb = 24
    pic = vgrad(W_, H_, [(0, (34, 26, 70)), (0.35, (196, 72, 98)), (0.55, (250, 158, 74)), (0.62, (255, 214, 140)),
                          (0.63, (40, 44, 62)), (1.0, (18, 20, 28))])
    pd = ImageDraw.Draw(pic)
    sun = soft(W_, H_, lambda g: g.ellipse([250, 76, 330, 156], fill=(255, 236, 170, 255)), 6)
    pic.paste(sun, (0, 0), sun)
    hills = soft(W_, H_, lambda g: g.polygon([(0, 122), (90, 96), (170, 112), (260, 92), (384, 118), (384, 124), (0, 124)],
                                            fill=(60, 34, 70, 255)), 1.5)
    pic.paste(hills, (0, 0), hills)
    # the road with its centre line, in perspective
    pd.polygon([(120, 168), (264, 168), (214, 124), (178, 124)], fill=(30, 30, 38))
    for k in range(4):
        yy = 128 + k * 10
        pd.line([196, yy, 196, yy + 5], fill=(250, 220, 150), width=2)
    # the car: a low wedge with glass, wheels and lamp glow
    shadow = soft(W_, H_, lambda g: g.ellipse([118, 158, 266, 176], fill=(0, 0, 0, 200)), 4)
    pic.paste(shadow, (0, 0), shadow)
    pd.polygon([(120, 160), (128, 140), (170, 128), (222, 126), (258, 140), (266, 160)], fill=(196, 24, 34))
    pd.polygon([(150, 138), (176, 129), (214, 128), (236, 138)], fill=(40, 52, 70))
    pd.line([(130, 147), (262, 146)], fill=(250, 120, 120), width=2)
    pd.ellipse([136, 152, 158, 172], fill=(20, 20, 22))
    pd.ellipse([228, 152, 250, 172], fill=(20, 20, 22))
    glow = soft(W_, H_, lambda g: (g.ellipse([118, 146, 136, 156], fill=(255, 250, 220, 255)),
                                   g.ellipse([252, 146, 270, 156], fill=(255, 80, 70, 255))), 3)
    pic.paste(glow, (0, 0), glow)
    # headline blocks (no words: made-up white bars read as text at this size)
    pd.rectangle([18, 34, 170, 52], fill=(255, 255, 255))
    pd.rectangle([18, 58, 132, 68], fill=(255, 226, 190))
    pd.rectangle([18, 74, 104, 82], fill=(255, 226, 190))
    day.paste(pic, (x0, y0))
    for yb in (y0, y1 - hb):
        d.rectangle([x0, yb, x1 - 1, yb + hb - 1], fill=(240, 120, 30))
        d.rectangle([x0 + 260, yb + 3, x1 - 4, yb + hb - 4], fill=(70, 74, 80))
        for k in range(8):
            d.rectangle([x0 + 268 + k * 14, yb + 7, x0 + 277 + k * 14, yb + hb - 8], fill=(250, 250, 250))
        for k in range(6):
            d.rectangle([x0 + 14 + k * 38, yb + 8, x0 + 44 + k * 38, yb + hb - 9], fill=(255, 244, 230))
    night.paste(day.crop((x0, y0, x1, y1)), (x0, y0))
    m.rectangle([x0, y0, x1 - 1, y1 - 1], fill=255)

    def bill(i, draw_fn):
        x0, y0, x1, y1 = reg("bill%d" % i, 384 + i * 128, 704, 384 + (i + 1) * 128, 896)
        img = draw_fn(x1 - x0, y1 - y0)
        day.paste(img, (x0, y0))
        d.rectangle([x0, y0, x1 - 1, y1 - 1], outline=(210, 210, 210), width=3)
        night.paste(day.crop((x0, y0, x1, y1)), (x0, y0))
        m.rectangle([x0 + 3, y0 + 3, x1 - 4, y1 - 4], fill=220)

    def b0(w, h):  # a fashion portrait: soft studio light, a face and shoulders, a headline
        img = vgrad(w, h, [(0, (238, 228, 218)), (1, (196, 176, 160))])
        halo = soft(w, h, lambda g: g.ellipse([20, 30, 108, 150], fill=(255, 250, 244, 200)), 12)
        img.paste(halo, (0, 0), halo)
        fig = soft(w, h, lambda g: (g.polygon([(18, h), (30, 132), (64, 118), (98, 132), (110, h)], fill=(150, 30, 46, 255)),
                                    g.ellipse([44, 62, 84, 108], fill=(176, 122, 96, 255)),
                                    g.ellipse([40, 54, 88, 84], fill=(48, 32, 30, 255)),
                                    g.rectangle([58, 104, 70, 120], fill=(166, 112, 88, 255))), 1.2)
        img.paste(fig, (0, 0), fig)
        g2 = ImageDraw.Draw(img)
        g2.rectangle([12, 14, w - 13, 30], fill=(28, 28, 30))
        g2.rectangle([12, 36, 76, 42], fill=(90, 80, 74))
        return img

    def b1(w, h):  # a red product ad: a lit bottle on deep red, a white headline
        img = vgrad(w, h, [(0, (176, 18, 30)), (1, (96, 8, 16))])
        glow = soft(w, h, lambda g: g.ellipse([24, 60, 104, 170], fill=(255, 120, 110, 160)), 14)
        img.paste(glow, (0, 0), glow)
        btl = soft(w, h, lambda g: (g.rounded_rectangle([48, 88, 80, 168], radius=10, fill=(250, 244, 236, 255)),
                                    g.rectangle([58, 70, 70, 90], fill=(250, 244, 236, 255)),
                                    g.rectangle([56, 64, 72, 72], fill=(220, 180, 60, 255)),
                                    g.rectangle([50, 112, 78, 134], fill=(200, 24, 36, 255))), 0.8)
        img.paste(btl, (0, 0), btl)
        g2 = ImageDraw.Draw(img)
        g2.rectangle([12, 14, w - 13, 34], fill=(255, 255, 255))
        g2.rectangle([12, 40, 90, 46], fill=(255, 210, 200))
        return img

    def b2(w, h):  # a food ad: a steaming noodle bowl on warm wood, a headline
        img = vgrad(w, h, [(0, (250, 214, 150)), (0.55, (214, 140, 70)), (1, (120, 64, 30))])
        steam = soft(w, h, lambda g: [g.arc([30 + k * 18, 40, 60 + k * 18, 110], 200, 340, fill=(255, 255, 255, 170), width=4)
                                      for k in range(3)], 3)
        img.paste(steam, (0, 0), steam)
        bowl = soft(w, h, lambda g: (g.ellipse([18, 118, 110, 140], fill=(250, 240, 226, 255)),
                                     g.pieslice([18, 96, 110, 176], 0, 180, fill=(236, 70, 40, 255)),
                                     g.ellipse([24, 120, 104, 136], fill=(236, 196, 120, 255)),
                                     g.ellipse([40, 122, 56, 130], fill=(120, 170, 70, 255)),
                                     g.ellipse([70, 124, 86, 132], fill=(250, 220, 170, 255))), 0.8)
        img.paste(bowl, (0, 0), bowl)
        g2 = ImageDraw.Draw(img)
        g2.rectangle([12, 14, w - 13, 32], fill=(255, 255, 255))
        g2.rectangle([12, h - 26, 92, h - 18], fill=(255, 255, 255))
        return img
    bill(0, b0)
    bill(1, b1)
    bill(2, b2)

    # ---------- plain colour, concrete, pavers ----------
    x0, y0, x1, y1 = reg("concrete", 768, 704, 896, 896)
    speckle(x0, y0, x1, y1, (200, 198, 192), 6, step=4)
    x0, y0, x1, y1 = reg("paver", 896, 704, 1024, 896)
    d.rectangle([x0, y0, x1 - 1, y1 - 1], fill=(80, 76, 70))
    for yy in range(y0, y1, 16):
        off = 0 if ((yy - y0) // 16) % 2 == 0 else 16
        for xx in range(x0 - 16 + off, x1, 32):
            v = rnd.randint(-8, 8)
            d.rectangle([max(x0, xx + 1), yy + 1, min(x1 - 1, xx + 30), yy + 14], fill=(90 + v, 86 + v, 80 + v))

    # ---------- the names (plain text) ----------
    def text_strip(name, x0, y0, x1, y1, txt, bg, fg, font, glow=True, fill=0.78, night_fg=None, span=None):
        """Plain-text name. fill = cap height / strip height; span = share of the width the letters spread over."""
        reg(name, x0, y0, x1, y1)
        if bg is not None:
            d.rectangle([x0, y0, x1 - 1, y1 - 1], fill=bg)
        size = int((y1 - y0) * fill * 1.35)
        f = ImageFont.truetype(font, size)
        while f.getbbox("M")[3] - f.getbbox("M")[1] > (y1 - y0) * fill:
            size -= 1
            f = ImageFont.truetype(font, size)
        while d.textlength(txt, font=f) > (x1 - x0) * 0.96:
            size -= 1
            f = ImageFont.truetype(font, size)
        widths = [d.textlength(ch, font=f) for ch in txt]
        tw = sum(widths)
        extra = 0.0
        if span and len(txt) > 1:
            extra = max(0.0, ((x1 - x0) * span - tw) / (len(txt) - 1))
        total = tw + extra * (len(txt) - 1)
        bb = f.getbbox("M")
        ty = y0 + ((y1 - y0) - (bb[3] - bb[1])) / 2 - bb[1]
        tx = x0 + ((x1 - x0) - total) / 2
        for ch, w in zip(txt, widths):
            d.text((tx, ty), ch, font=f, fill=fg)
            if glow:
                n.text((tx, ty), ch, font=f, fill=night_fg or fg)
                m.text((tx, ty), ch, font=f, fill=255)
            tx += w + extra

    text_strip("txt_centre", 0, 896, 768, 944, "MYANMAR CENTRE", (204, 194, 176), (246, 110, 30), FONT, fill=0.8, span=0.86)
    # the four building names on the granite (light cream), then an address line (gold)
    reg("names", 0, 944, 768, 960)
    speckle(0, 944, 768, 960, (78, 40, 38), 6)
    f = ImageFont.truetype(FONT3, 12)
    names = ["THE LAKE SUITES", "MYANMAR CENTRE TOWER", "MYANMAR PLAZA", "MELIA YANGON"]
    for i, t in enumerate(names):
        cx = 96 + i * 192
        tw = d.textlength(t, font=f)
        d.text((cx - tw / 2, 945), t, font=f, fill=(226, 212, 186))
    text_strip("txt_suites", 768, 896, 1024, 960, "THE LAKE SUITES", (236, 230, 214), (120, 96, 60), FONT2)
    text_strip("txt_plaza", 0, 960, 512, 1024, "MYANMAR PLAZA", (34, 44, 56), (238, 238, 234), FONT2, fill=0.62, span=0.9)
    text_strip("txt_melia", 512, 960, 768, 1024, "MELIA YANGON", (244, 242, 236), (150, 116, 66), FONT2,
               night_fg=(255, 226, 170))
    reg("white", 768, 960, 832, 1024)
    d.rectangle([768, 960, 831, 1023], fill=(255, 255, 255))
    # a red street banner (made-up: white circle and text dashes)
    x0, y0, x1, y1 = reg("banner", 832, 960, 896, 1024)
    d.rectangle([x0, y0, x1 - 1, y1 - 1], fill=(200, 30, 36))
    d.ellipse([x0 + 18, y0 + 10, x0 + 46, y0 + 38], fill=(255, 255, 255))
    d.rectangle([x0 + 12, y0 + 44, x1 - 13, y0 + 48], fill=(255, 255, 255))
    d.rectangle([x0 + 16, y0 + 52, x1 - 17, y0 + 55], fill=(255, 220, 200))
    # warm uplight / lamp glow swatch
    x0, y0, x1, y1 = reg("lamp", 896, 960, 960, 1024)
    d.rectangle([x0, y0, x1 - 1, y1 - 1], fill=(255, 236, 190))
    n.rectangle([x0, y0, x1 - 1, y1 - 1], fill=(255, 230, 170))
    m.rectangle([x0, y0, x1 - 1, y1 - 1], fill=255)
    # dark glass (screen box, reveals, balustrade)
    x0, y0, x1, y1 = reg("darkglass", 960, 960, 1024, 1024)
    for yy in range(y0, y1):
        d.line([x0, yy, x1 - 1, yy], fill=lerp((60, 72, 84), (24, 30, 38), (yy - y0) / 64))

    # the Yangon map's daytime look is bright and cool (Lighting brightness 2.3, ExposureCompensation 0.75, a blue tint):
    # at full value these colours read white in Studio (2026-11-14 pilot), so everything but the lit pictures and the
    # lettering is darkened by DAY_K
    DAY_K = 0.82
    keep = [R[k] for k in R if k in ("screen", "bill0", "bill1", "bill2", "lamp", "banner")]
    dark = day.point(lambda v: int(v * DAY_K))
    for x0, y0, x1, y1 in keep:
        dark.paste(day.crop((x0, y0, x1, y1)), (x0, y0))
    day = dark
    os.makedirs(out, exist_ok=True)
    day.save(os.path.join(out, "mc_atlas.png"))
    night.save(os.path.join(out, "mc_atlas_night.png"))
    mask.save(os.path.join(out, "mc_atlas_mask.png"))
    json.dump(R, open(os.path.join(out, "mc_atlas.json"), "w"), indent=1)
    print("regions", len(R), "->", out)


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, "..", "..", "..", "build", "landmarks", "myanmar_centre"))
