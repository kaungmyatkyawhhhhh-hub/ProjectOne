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

    # ---------- office storeys: champagne spandrel band over a ribbon of dark blue-grey glass ----------
    def office_row(name, y0, spandrel, glass_hi, glass_lo, band, bay=32, lit=0.5):
        reg(name, 0, y0, 1024, y0 + 64)
        for yy in range(y0, y0 + band):
            d.line([0, yy, 1023, yy], fill=lerp(spandrel, lerp(spandrel, (0, 0, 0), 0.12), (yy - y0) / band))
        d.line([0, y0, 1023, y0], fill=lerp(spandrel, (255, 255, 255), 0.35))
        d.line([0, y0 + band - 1, 1023, y0 + band - 1], fill=lerp(spandrel, (40, 40, 40), 0.45))
        for i in range(1024 // bay):
            bx = i * bay
            t = rnd.random()
            for yy in range(y0 + band, y0 + 64):
                k = (yy - y0 - band) / (64 - band)
                d.line([bx + 1, yy, bx + bay - 2, yy], fill=lerp(glass_hi, glass_lo, k * 0.9 + t * 0.1))
            # a sky reflection line under the band
            d.line([bx + 1, y0 + band + 3, bx + bay - 2, y0 + band + 3], fill=lerp(glass_hi, (150, 168, 184), 0.5))
            d.line([bx, y0 + band, bx, y0 + 63], fill=(64, 70, 76))
            d.line([bx + bay - 1, y0 + band, bx + bay - 1, y0 + 63], fill=(64, 70, 76))
            if rnd.random() < lit:
                c = rnd.choice([(255, 248, 228), (236, 244, 255), (255, 236, 196)])
                n.rectangle([bx + 1, y0 + band + 1, bx + bay - 2, y0 + 62], fill=c)
                m.rectangle([bx + 1, y0 + band + 1, bx + bay - 2, y0 + 62], fill=rnd.choice([140, 180, 220]))
            else:
                n.rectangle([bx + 1, y0 + band + 1, bx + bay - 2, y0 + 62], fill=(16, 22, 30))

    office_row("officeA", 0, (204, 186, 154), (56, 74, 92), (18, 26, 38), band=29)
    office_row("officeB", 64, (196, 180, 150), (52, 70, 88), (20, 30, 42), band=35, bay=16)
    office_row("melia", 128, (244, 242, 236), (70, 92, 112), (28, 40, 56), band=34, lit=0.6)

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

    # ---------- podium (mall) storey: speckled beige granite spandrel, recessed dark glass ribbon (50 %) ----------
    x0, y0, x1, y1 = reg("podium", 0, 256, 1024, 320)
    speckle(0, y0, 1024, y0 + 26, (186, 174, 158), 8)
    speckle(0, y0 + 58, 1024, y1, (186, 174, 158), 8)
    for yy in range(y0 + 26, y0 + 58):
        d.line([0, yy, 1023, yy], fill=lerp((52, 64, 76), (28, 38, 48), (yy - y0 - 26) / 32))
    d.rectangle([0, y0 + 26, 1023, y0 + 28], fill=(58, 56, 52))  # shadow under the granite lip
    for i in range(0, 1024, 24):
        d.line([i, y0 + 29, i, y0 + 57], fill=(90, 96, 100))
    for i in range(0, 1024, 48):
        d.line([i, y0, i, y0 + 25], fill=(168, 158, 144))
        d.line([i, y0 + 58, i, y1 - 1], fill=(168, 158, 144))
    for i in range(0, 1024, 48):
        if rnd.random() < 0.6:
            c = rnd.choice([(255, 238, 200), (255, 246, 226), (236, 240, 255)])
            n.rectangle([i + 1, y0 + 29, i + 47, y0 + 57], fill=c)
            m.rectangle([i + 1, y0 + 29, i + 47, y0 + 57], fill=rnd.choice([110, 150, 190]))

    # ---------- shopfront storey: a light soffit band, dark granite piers, tall lit glazing ----------
    x0, y0, x1, y1 = reg("shop", 0, 320, 1024, 384)
    d.rectangle([0, y0, 1023, y0 + 9], fill=(220, 214, 204))
    d.line([0, y0 + 9, 1023, y0 + 9], fill=(120, 116, 110))
    for i in range(16):
        bx = i * 64
        inner = rnd.choice([(232, 214, 180), (210, 222, 230), (240, 230, 214), (200, 190, 170), (226, 206, 190)])
        for yy in range(y0 + 10, y1):
            k = (yy - y0 - 10) / 54
            d.line([bx + 8, yy, bx + 63, yy], fill=lerp((86, 100, 110), inner, 0.3 + 0.45 * k))
        d.rectangle([bx, y0 + 10, bx + 7, y1 - 1], fill=(40, 40, 44))
        d.line([bx + 2, y0 + 10, bx + 2, y1 - 1], fill=(70, 70, 76))
        d.rectangle([bx + 8, y0 + 11, bx + 63, y0 + 16], fill=lerp(inner, (40, 40, 40), 0.5))
        n.rectangle([bx + 8, y0 + 11, bx + 63, y1 - 2], fill=lerp(inner, (255, 255, 255), 0.3))
        m.rectangle([bx + 8, y0 + 11, bx + 63, y1 - 2], fill=210)
    n.rectangle([0, y0, 1023, y0 + 9], fill=(255, 236, 200))
    m.rectangle([0, y0, 1023, y0 + 9], fill=90)

    # ---------- crown storeys of the towers: plain champagne panels ----------
    x0, y0, x1, y1 = reg("crown", 0, 384, 1024, 448)
    for yy in range(y0, y1):
        d.line([0, yy, 1023, yy], fill=lerp((206, 190, 162), (192, 176, 148), (yy - y0) / 64))
    for i in range(0, 1024, 64):
        d.line([i, y0, i, y1 - 1], fill=(198, 188, 170))
    d.line([0, y0 + 32, 1023, y0 + 32], fill=(204, 194, 176))

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
    speckle(x0, y0, x1, y1, (100, 48, 42), 7)
    for yy in range(y0, y0 + 30):
        for xx in range(x0, x1, 4):
            px = day.getpixel((xx, yy))
            day.putpixel((xx, yy), lerp(px, (150, 96, 88), 0.18 * (1 - (yy - y0) / 30)))
    for xx in (x0 + 85, x0 + 170):
        d.line([xx, y0, xx, y1 - 1], fill=(82, 38, 34))
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

    # ---------- LED screen: orange header / footer bars with grey number boxes, a photo-like middle ----------
    x0, y0, x1, y1 = reg("screen", 0, 704, 384, 896)
    hb = 24
    for yy in range(y0 + hb, y1 - hb):
        d.line([x0, yy, x1 - 1, yy], fill=lerp((60, 50, 44), (196, 170, 140), (yy - y0 - hb) / (y1 - y0 - 2 * hb)))
    # a made-up interior photo: warm light pools, people silhouettes, a white text block
    for _ in range(14):
        cx, cy = rnd.randint(x0 + 20, x1 - 120), rnd.randint(y0 + 40, y1 - 50)
        d.ellipse([cx - 22, cy - 14, cx + 22, cy + 14], fill=rnd.choice([(250, 220, 160), (230, 190, 130), (255, 236, 200)]))
    for k in range(5):
        px = x0 + 40 + k * 48
        d.ellipse([px - 8, y1 - hb - 86, px + 8, y1 - hb - 70], fill=(40, 34, 30))
        d.rectangle([px - 12, y1 - hb - 68, px + 12, y1 - hb - 4], fill=(48, 40, 36))
    d.rectangle([x1 - 140, y0 + 50, x1 - 20, y0 + 70], fill=(255, 255, 255))
    d.rectangle([x1 - 140, y0 + 78, x1 - 50, y0 + 88], fill=(255, 240, 210))
    d.rectangle([x1 - 140, y0 + 96, x1 - 70, y0 + 104], fill=(255, 240, 210))
    for yb in (y0, y1 - hb):
        d.rectangle([x0, yb, x1 - 1, yb + hb - 1], fill=(240, 120, 30))
        d.rectangle([x0 + 260, yb + 3, x1 - 4, yb + hb - 4], fill=(70, 74, 80))
        for k in range(8):
            d.rectangle([x0 + 268 + k * 14, yb + 7, x0 + 277 + k * 14, yb + hb - 8], fill=(250, 250, 250))
        for k in range(6):
            d.rectangle([x0 + 14 + k * 38, yb + 8, x0 + 44 + k * 38, yb + hb - 9], fill=(255, 244, 230))
    night.paste(day.crop((x0, y0, x1, y1)), (x0, y0))
    m.rectangle([x0, y0, x1 - 1, y1 - 1], fill=255)
    # ---------- three portrait billboards, three different made-up layouts ----------
    def bill(i, draw_fn):
        x0, y0, x1, y1 = reg("bill%d" % i, 384 + i * 128, 704, 384 + (i + 1) * 128, 896)
        draw_fn(x0, y0, x1, y1)
        d.rectangle([x0, y0, x1 - 1, y1 - 1], outline=(200, 200, 200), width=3)
        night.paste(day.crop((x0, y0, x1, y1)), (x0, y0))
        m.rectangle([x0 + 3, y0 + 3, x1 - 4, y1 - 4], fill=220)

    def b0(x0, y0, x1, y1):  # a person with a headline (fashion)
        for yy in range(y0, y1):
            d.line([x0, yy, x1 - 1, yy], fill=lerp((236, 226, 214), (190, 170, 150), (yy - y0) / (y1 - y0)))
        d.ellipse([x0 + 44, y0 + 50, x0 + 84, y0 + 92], fill=(150, 100, 80))
        d.polygon([(x0 + 30, y1), (x0 + 40, y0 + 100), (x0 + 88, y0 + 100), (x0 + 98, y1)], fill=(160, 40, 50))
        d.rectangle([x0 + 12, y0 + 14, x1 - 13, y0 + 30], fill=(30, 30, 30))
        d.rectangle([x0 + 12, y0 + 36, x0 + 80, y0 + 42], fill=(80, 80, 80))

    def b1(x0, y0, x1, y1):  # a round mascot on blue
        for yy in range(y0, y1):
            d.line([x0, yy, x1 - 1, yy], fill=lerp((40, 110, 200), (180, 220, 250), (yy - y0) / (y1 - y0)))
        d.ellipse([x0 + 24, y0 + 60, x1 - 25, y0 + 140], fill=(250, 250, 250))
        d.ellipse([x0 + 46, y0 + 86, x0 + 56, y0 + 98], fill=(30, 30, 30))
        d.ellipse([x1 - 57, y0 + 86, x1 - 47, y0 + 98], fill=(30, 30, 30))
        d.arc([x0 + 44, y0 + 96, x1 - 45, y0 + 124], 20, 160, fill=(200, 40, 40), width=4)
        d.rectangle([x0 + 14, y0 + 16, x1 - 15, y0 + 34], fill=(255, 255, 255))
        d.rectangle([x0 + 24, y1 - 34, x1 - 25, y1 - 18], fill=(255, 210, 40))

    def b2(x0, y0, x1, y1):  # a phone-like device and text on green
        for yy in range(y0, y1):
            d.line([x0, yy, x1 - 1, yy], fill=lerp((20, 120, 80), (230, 220, 120), (yy - y0) / (y1 - y0)))
        d.rounded_rectangle([x0 + 40, y0 + 46, x0 + 88, y0 + 146], radius=8, fill=(30, 30, 36))
        d.rectangle([x0 + 45, y0 + 54, x0 + 83, y0 + 136], fill=(120, 200, 240))
        d.rectangle([x0 + 12, y0 + 14, x1 - 13, y0 + 30], fill=(255, 255, 255))
        d.rectangle([x0 + 12, y1 - 30, x0 + 90, y1 - 20], fill=(255, 255, 255))
    bill(0, b0)
    bill(1, b1)
    bill(2, b2)

    # ---------- plain colour, concrete, pavers ----------
    x0, y0, x1, y1 = reg("concrete", 768, 704, 896, 896)
    speckle(x0, y0, x1, y1, (200, 198, 192), 6, step=4)
    x0, y0, x1, y1 = reg("paver", 896, 704, 1024, 896)
    d.rectangle([x0, y0, x1 - 1, y1 - 1], fill=(104, 100, 94))
    for yy in range(y0, y1, 16):
        off = 0 if ((yy - y0) // 16) % 2 == 0 else 16
        for xx in range(x0 - 16 + off, x1, 32):
            v = rnd.randint(-8, 8)
            d.rectangle([max(x0, xx + 1), yy + 1, min(x1 - 1, xx + 30), yy + 14], fill=(114 + v, 110 + v, 102 + v))

    # ---------- the names (plain text) ----------
    def text_strip(name, x0, y0, x1, y1, txt, bg, fg, font, glow=True, fill=0.78, night_fg=None):
        reg(name, x0, y0, x1, y1)
        if bg is not None:
            d.rectangle([x0, y0, x1 - 1, y1 - 1], fill=bg)
        size = int((y1 - y0) * fill)
        f = ImageFont.truetype(font, size)
        while d.textlength(txt, font=f) > (x1 - x0) * 0.96:
            size -= 1
            f = ImageFont.truetype(font, size)
        tw = d.textlength(txt, font=f)
        tx = x0 + ((x1 - x0) - tw) / 2
        ty = y0 + ((y1 - y0) - size) / 2 - size * 0.1
        d.text((tx, ty), txt, font=f, fill=fg)
        if glow:
            n.text((tx, ty), txt, font=f, fill=night_fg or fg)
            m.text((tx, ty), txt, font=f, fill=255)

    text_strip("txt_centre", 0, 896, 768, 944, "MYANMAR CENTRE", (204, 194, 176), (246, 110, 30), FONT2, fill=0.86)
    # the four building names on the granite (light cream), then an address line (gold)
    reg("names", 0, 944, 768, 960)
    speckle(0, 944, 768, 960, (100, 48, 42), 7)
    f = ImageFont.truetype(FONT3, 12)
    names = ["THE LAKE SUITES", "MYANMAR CENTRE TOWER", "MYANMAR PLAZA", "MELIA YANGON"]
    for i, t in enumerate(names):
        cx = 96 + i * 192
        tw = d.textlength(t, font=f)
        d.text((cx - tw / 2, 945), t, font=f, fill=(226, 212, 186))
    text_strip("txt_suites", 768, 896, 1024, 960, "THE LAKE SUITES", (236, 230, 214), (120, 96, 60), FONT2)
    text_strip("txt_plaza", 0, 960, 512, 1024, "MYANMAR PLAZA", (38, 44, 52), (238, 238, 234), FONT2, fill=0.82)
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
