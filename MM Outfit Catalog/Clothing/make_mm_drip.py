"""MM drip collection (16 Nov 2026, owner: "make the drippiest outfits"). Six original looks on Roblox's official
585x559 template, built on make_mm_clothing.py (same boxes, strips and check). Trends from the catalog research note
"2026-11-16 Classic clothing - what sells as drip": big chrome lettering, all-over prints, Y2K stars, baggy cargos with
straps/chains, racer jackets. No real brands: only MM marks and made-up names.
Run: python make_mm_drip.py  -> out/MM_D*_*.png + out/drip_preview_*.png
Strip coords: torso R 0-64 | F 64-192 (centre 128) | L 192-256 | B 256-384 (centre 320).
Right limb L 0 | B 64 | R(outer) 128 | F 192.  Left limb F 0 | L(outer) 64 | B 128 | R(inner) 192.
"""
import os, math
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from make_mm_clothing import (noise, fbm, solid, shade, to_img, clear_rows, P, cotton, denim, leather, rib, stitch,
                              zipper, place_torso, place_limb, place_cap, blank, check, overlay, front_view,
                              RLIMB_STRIP, LLIMB_STRIP, S, OUT, ORANGE)

IMPACT = "C:/Windows/Fonts/impact.ttf"
BLACK = "C:/Windows/Fonts/ariblk.ttf"
SILVER = (206, 210, 220, 255)

def front_of(layout): return 192 if layout is RLIMB_STRIP else 0
def outer_of(layout): return 128 if layout is RLIMB_STRIP else 64

# ---------------------------------------------------------------- shapes + prints
def star_pts(cx, cy, r, rot=-90, inner=0.45):
    pts = []
    for k in range(10):
        rr = r if k % 2 == 0 else r * inner
        a = math.radians(rot + k * 36)
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    return pts

def star(d, cx, cy, r, fill, outline=None, rot=-90, ow=1.0):
    pts = [tuple(P(x, y)) for x, y in star_pts(cx, cy, r, rot)]
    d.polygon(pts, fill=fill, outline=outline, width=int(ow * S) if outline else 0)

def glint(d, cx, cy, r, col=(255, 255, 255, 255)):
    d.polygon([tuple(P(*p)) for p in ((cx, cy - r), (cx + r * .18, cy), (cx, cy + r), (cx - r * .18, cy))], fill=col)
    d.polygon([tuple(P(*p)) for p in ((cx - r, cy), (cx, cy - r * .18), (cx + r, cy), (cx, cy + r * .18))], fill=col)

def chrome_text(img, text, cx, cy, size, font=IMPACT, outline=(14, 12, 18, 255), ow=2.4, stops=None, shear=0.0):
    """Y2K chrome lettering: vertical chrome gradient, thick outline, a few glints."""
    stops = stops or [(0, (252, 252, 255)), (0.42, (176, 184, 200)), (0.5, (66, 70, 88)), (0.6, (150, 158, 176)), (1, (240, 242, 248))]
    f = ImageFont.truetype(font, int(size * S))
    out_m = Image.new("L", img.size, 0)
    in_m = Image.new("L", img.size, 0)
    ImageDraw.Draw(out_m).text((cx * S, cy * S), text, font=f, anchor="mm", fill=255, stroke_width=int(ow * S), stroke_fill=255)
    ImageDraw.Draw(in_m).text((cx * S, cy * S), text, font=f, anchor="mm", fill=255)
    if shear:
        m = (1, shear, -shear * cy * S, 0, 1, 0)
        out_m = out_m.transform(img.size, Image.AFFINE, m, Image.BILINEAR)
        in_m = in_m.transform(img.size, Image.AFFINE, m, Image.BILINEAR)
    box = in_m.getbbox()
    if not box:
        return
    y0, y1 = box[1], box[3]
    grad = np.zeros((img.height, img.width, 4), np.float32)
    ys = np.clip((np.arange(img.height) - y0) / max(1, y1 - y0), 0, 1)
    col = np.zeros((img.height, 3), np.float32)
    for (a, ca), (b, cb) in zip(stops, stops[1:]):
        sel = (ys >= a) & (ys <= b)
        t = ((ys[sel] - a) / max(1e-6, b - a))[:, None]
        col[sel] = np.array(ca) * (1 - t) + np.array(cb) * t
    grad[..., :3] = col[:, None, :]
    grad[..., 3] = np.asarray(in_m, np.float32)
    ol = Image.new("RGBA", img.size, outline)
    ol.putalpha(out_m)
    img.alpha_composite(ol)
    img.alpha_composite(to_img(grad))
    d = ImageDraw.Draw(img)
    bx = [v / S for v in box]
    glint(d, bx[0] + (bx[2] - bx[0]) * 0.18, bx[1] + 2, 3.2)
    glint(d, bx[0] + (bx[2] - bx[0]) * 0.82, bx[1] + (bx[3] - bx[1]) * 0.55, 2.4)

def distress(img, seed, amount=0.45):
    """Worn screen-print look: knocks speckled holes into whatever was drawn on img's alpha."""
    a = np.asarray(img, np.float32).copy()
    n = fbm(a.shape[0], a.shape[1], [(S, S), (3 * S, 3 * S)], seed)
    a[..., 3] *= np.clip((n - amount * 0.5) * 2.4, 0.15, 1)
    return to_img(a)

def rhinestones(img, mask, seed, spacing=2.2, col=(236, 244, 255)):
    """Fills a mask (L image, supersampled) with a jittered grid of tiny sparkling stones."""
    m = np.asarray(mask) > 128
    rng = np.random.default_rng(seed)
    d = ImageDraw.Draw(img)
    st = spacing * S
    for y in np.arange(0, img.height, st):
        off = st / 2 if int(y / st) % 2 else 0
        for x in np.arange(off, img.width, st):
            xi, yi = int(x), int(y)
            if 0 <= yi < m.shape[0] and 0 <= xi < m.shape[1] and m[yi, xi]:
                r = S * (0.7 + 0.25 * rng.random())
                shadeC = tuple(int(c * (0.78 + 0.22 * rng.random())) for c in col)
                d.ellipse([x - r, y - r, x + r, y + r], fill=shadeC + (255,))
                d.ellipse([x - r * .45, y - r * .55, x, y - r * .1], fill=(255, 255, 255, 255))
                if rng.random() < 0.08:
                    glint(d, x / S, y / S, 2.0)

def chain(d, pts, link=2.6):
    """Painted silver chain along a polyline (template px)."""
    segs = []
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        L = math.hypot(x1 - x0, y1 - y0)
        n = max(1, int(L / link))
        for i in range(n):
            t = (i + 0.5) / n
            segs.append((x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, math.atan2(y1 - y0, x1 - x0)))
    for i, (x, y, a) in enumerate(segs):
        w, h = (link * 0.75, link * 0.42) if i % 2 == 0 else (link * 0.75, link * 0.2)
        ca, sa = math.cos(a), math.sin(a)
        poly = []
        for k in range(12):
            t = k / 12 * 2 * math.pi
            ex, ey = w * math.cos(t), h * math.sin(t)
            poly.append(tuple(P(x + ex * ca - ey * sa, y + ex * sa + ey * ca)))
        d.polygon(poly, outline=(214, 218, 226, 255), width=int(0.7 * S))
        d.line(poly[1:4], fill=(250, 250, 255, 255), width=int(0.4 * S))

def heart_pts(cx, cy, r):
    pts = []
    for k in range(60):
        t = k / 60 * 2 * math.pi
        x = 16 * math.sin(t) ** 3
        y = -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t))
        pts.append((cx + x * r / 17, cy + y * r / 17))
    return pts

def flames_pts(cx, base_y, w, h, seed):
    rng = np.random.default_rng(seed)
    pts = [(cx - w / 2, base_y)]
    n = 7
    for i in range(n):
        x0 = cx - w / 2 + w * i / n
        peak = h * (0.55 + 0.45 * math.sin(math.pi * (i + 0.5) / n)) * (0.8 + 0.3 * rng.random())
        pts.append((x0 + w / n * 0.35, base_y - peak * 0.55))
        pts.append((x0 + w / n * 0.5 + rng.uniform(-1, 1), base_y - peak))
        pts.append((x0 + w / n * 0.75, base_y - peak * 0.5))
    pts.append((cx + w / 2, base_y))
    return pts

def camo(h, w, seed, cols):
    a = solid(h, w, cols[0])
    for i, c in enumerate(cols[1:]):
        n = fbm(h, w, [(18 * S, 18 * S), (7 * S, 7 * S)], seed + i * 31)
        m = (n > 0.54)[..., None]
        a[..., :3] = np.where(m, np.array(c, np.float32), a[..., :3])
    shade(a, 0.92 + 0.12 * fbm(h, w, [(40 * S, 14 * S)], seed + 99))
    return a

def galaxy(h, w, seed):
    n1 = fbm(h, w, [(30 * S, 30 * S), (12 * S, 12 * S), (5 * S, 5 * S)], seed)
    n2 = fbm(h, w, [(22 * S, 40 * S), (9 * S, 9 * S)], seed + 7)
    deep, mag, pink = np.array([34, 12, 70.]), np.array([150, 40, 160.]), np.array([255, 150, 220.])
    c = deep + (mag - deep) * np.clip(n1 * 1.3 - 0.2, 0, 1)[..., None]
    c = c + (pink - c) * (np.clip(n2 - 0.55, 0, 1) * 2.2)[..., None]
    a = np.zeros((h, w, 4), np.float32)
    a[..., :3] = c
    a[..., 3] = 255
    img = to_img(a)
    d = ImageDraw.Draw(img)
    rng = np.random.default_rng(seed)
    for _ in range(int(w * h / (S * S) / 55)):
        x, y = rng.random() * w / S, rng.random() * h / S
        r = 0.35 + rng.random() ** 3 * 0.9
        b = int(200 + 55 * rng.random())
        d.ellipse(P(x - r, y - r, x + r, y + r), fill=(b, b, 255, 255))
        if rng.random() < 0.05:
            glint(d, x, y, 2.6)
    return np.asarray(img, np.float32).copy()

def monogram(h, w, seed, base=(150, 190, 232)):
    a = cotton(h, w, seed, base=base)
    img = to_img(a)
    d = ImageDraw.Draw(img)
    f = ImageFont.truetype(BLACK, int(6.5 * S))
    light = tuple(min(255, int(c * 1.12)) for c in base) + (255,)
    dark = tuple(int(c * 0.86) for c in base) + (255,)
    for row, y in enumerate(range(6, h // S + 12, 13)):
        for col, x in enumerate(range(-6 + (row % 2) * 10, w // S + 12, 20)):
            if (row + col) % 2 == 0:
                d.text((x * S, y * S), "MM", font=f, fill=light, anchor="mm")
            else:
                star(d, x, y, 3.0, dark, rot=-90)
    return np.asarray(img, np.float32).copy()

# ---------------------------------------------------------------- garment parts
def hoodie_front(t, rib_col, pocket_col, strings=(245, 245, 248, 255), zip_=False):
    d = ImageDraw.Draw(t)
    # hood folded behind the neck (back) + neck opening (front)
    d.arc(P(98, -22, 158, 14), 0, 180, fill=tuple(int(c * .7) for c in pocket_col[:3]) + (255,), width=4 * S)
    d.chord(P(280, -30, 360, 30), 0, 180, fill=tuple(int(c * .82) for c in pocket_col[:3]) + (255,))
    d.arc(P(280, -30, 360, 30), 0, 180, fill=tuple(int(c * .62) for c in pocket_col[:3]) + (255,), width=S)
    if not zip_:
        for x, sway in ((120, -2), (136, 2)):
            d.line(P(x, 8, x + sway, 34), fill=strings, width=int(1.4 * S))
            d.rectangle(P(x + sway - 0.9, 32, x + sway + 0.9, 37), fill=(200, 200, 206, 255))
        d.polygon([tuple(P(*p)) for p in ((92, 60), (164, 60), (172, 92), (84, 92))], fill=pocket_col)   # kangaroo pocket
        d.line(P(92, 60, 164, 60), fill=tuple(int(c * .7) for c in pocket_col[:3]) + (255,), width=S)
        stitch(d, 93, 62, 163, 62, tuple(int(c * .8) for c in pocket_col[:3]) + (255,), dash=2, gap=1.5)
    rib(t, 0, 92, 384, 102, rib_col)

def sleeves(tpl, fabric_fn, seeds, rib_col, deco=None, cuff=(82, 91)):
    for layout, seed, cap in ((RLIMB_STRIP, seeds[0], "rU"), (LLIMB_STRIP, seeds[1], "lU")):
        a = to_img(fabric_fn(128 * S, 256 * S, seed))
        if deco:
            deco(a, layout)
        rib(a, 0, cuff[0], 256, cuff[1], rib_col)
        clear_rows(a, cuff[1], 128)
        place_limb(tpl, a, layout)
        place_cap(tpl, cap, to_img(fabric_fn(64 * S, 64 * S, seed + 50)))

def shoes(a, layout, upper, sole, accent=None, chunky=False, boot=False):
    d = ImageDraw.Draw(a)
    top = 84 if boot else 91
    sole_top = 112 if chunky else 119
    d.rectangle(P(0, top, 256, 128), fill=upper)
    shine = tuple(min(255, int(c * 1.12)) for c in upper[:3]) + (255,)
    d.rectangle(P(0, top + 2, 256, top + 4), fill=shine)
    d.rectangle(P(0, sole_top, 256, 128), fill=sole)
    d.line(P(0, sole_top, 256, sole_top), fill=tuple(int(c * .8) for c in sole[:3]) + (255,), width=S)
    if chunky:
        for x in range(0, 256, 6):
            d.line(P(x, sole_top + 3, x + 3, sole_top + 3), fill=tuple(int(c * .88) for c in sole[:3]) + (255,), width=S)
    f = front_of(layout)
    lace = (236, 236, 240, 255) if sum(upper[:3]) < 300 else (150, 150, 158, 255)
    for k in range(4 if boot else 3):
        y = top + 4 + k * 5
        d.line(P(f + 22, y, f + 42, y + 3), fill=lace, width=S)
        d.line(P(f + 42, y, f + 22, y + 3), fill=lace, width=S)
    if accent:
        o = outer_of(layout)
        for k in (0, 6):
            d.line(P(o + 14 + k, sole_top - 3, o + 30 + k, top + 6), fill=accent, width=int(2.6 * S))

def sole_cap(col):
    s = Image.new("RGBA", (64 * S, 64 * S), col)
    ds = ImageDraw.Draw(s)
    for y in range(5, 64, 7):
        ds.line(P(5, y, 59, y), fill=tuple(int(c * .85) for c in col[:3]) + (255,), width=2 * S)
    return s

def stacked(arr, seed, start=62, end=91, depth=0.2):
    yy = np.mgrid[0:arr.shape[0], 0:arr.shape[1]][0].astype(np.float32) / S
    wob = fbm(arr.shape[0], arr.shape[1], [(6 * S, 20 * S)], seed)
    st = np.clip((yy - start) / (end - start), 0, 1) * (0.5 + 0.5 * np.sin(yy * 2 * np.pi / 6 + 3 * wob))
    arr[..., :3] *= (1 - depth * st)[..., None]
    return arr

def legs(tpl, fabric_fn, seeds, deco, shoe_args, sole_col, capU_fn=None):
    for layout, seed, caps in ((RLIMB_STRIP, seeds[0], ("rU", "rD")), (LLIMB_STRIP, seeds[1], ("lU", "lD"))):
        arr = fabric_fn(128 * S, 256 * S, seed)
        a = to_img(arr)
        if deco:
            deco(a, layout, seed)
        shoes(a, layout, **shoe_args)
        place_limb(tpl, a, layout)
        place_cap(tpl, caps[0], to_img(fabric_fn(64 * S, 64 * S, seed + 70)))
        place_cap(tpl, caps[1], sole_cap(sole_col))

def waistband(t, col, loops=True, button=True, fly_col=None):
    d = ImageDraw.Draw(t)
    d.rectangle(P(0, 96, 384, 106), fill=col)
    dk = tuple(int(c * .8) for c in col[:3]) + (255,)
    d.line(P(0, 106, 384, 106), fill=dk, width=S)
    if loops:
        for bx in (30, 86, 170, 226, 290, 350):
            d.rectangle(P(bx - 1.5, 95, bx + 1.5, 108), fill=dk)
    if button:
        d.ellipse(P(125, 98, 131, 104), fill=(196, 196, 204, 255))
    d.line(P(128, 106, 128, 128), fill=fly_col or dk, width=S)

# ================================================================ D1 NEON STAR
def d1_shirt():
    tpl = blank()
    fab = lambda h, w, s: cotton(h, w, s, base=(30, 28, 34))
    t = to_img(fab(128 * S, 384 * S, 201))
    hoodie_front(t, (24, 22, 28, 255), (36, 34, 40, 255))
    chrome_text(t, "MM", 128, 40, 34, shear=-0.12)
    d = ImageDraw.Draw(t)
    for x, y, r in ((84, 24, 5), (174, 30, 4), (96, 58, 3), (166, 52, 3.5)):
        star(d, x, y, r, (220, 224, 236, 255), outline=(14, 12, 18, 255), ow=0.8)
    chrome_text(t, "NEON STAR", 320, 52, 15, font=IMPACT, ow=1.6)
    star(d, 320, 76, 9, (220, 224, 236, 255), outline=(14, 12, 18, 255), ow=1)
    clear_rows(t, 102, 128)
    place_torso(tpl, t)
    place_cap(tpl, "torsoU", to_img(fab(64 * S, 128 * S, 202)))
    def deco(a, layout):
        d = ImageDraw.Draw(a)
        o = outer_of(layout)
        rng = np.random.default_rng(o)
        for _ in range(7):
            star(d, o + 8 + rng.random() * 48, 10 + rng.random() * 66, 2 + rng.random() * 3.5, (214, 218, 230, 255), outline=(10, 10, 14, 255), ow=0.6)
    sleeves(tpl, fab, (203, 204), (24, 22, 28, 255), deco)
    return tpl

def d1_pants():
    tpl = blank()
    fab = lambda h, w, s: denim(h, w, s, base=(150, 152, 162))
    t = to_img(fab(128 * S, 384 * S, 211))
    waistband(t, (138, 140, 150, 255))
    clear_rows(t, 0, 96)
    place_torso(tpl, t)
    place_cap(tpl, "torsoD", to_img(fab(64 * S, 128 * S, 212)))
    def deco(a, layout, seed):
        arr = stacked(np.asarray(a, np.float32).copy(), seed)
        b = to_img(arr)
        a.paste(b)
        d = ImageDraw.Draw(a)
        rng = np.random.default_rng(seed)
        for _ in range(16):
            x, y, r = rng.random() * 256, 6 + rng.random() * 74, 2.5 + rng.random() * 5
            if rng.random() < 0.5:
                star(d, x, y, r, (246, 246, 250, 255), rot=-90 + rng.random() * 40)
            else:
                star(d, x, y, r, (20, 20, 26, 255), rot=-90 + rng.random() * 40)
        stitch(d, outer_of(layout) + 32, 0, outer_of(layout) + 32, 91, (120, 122, 132, 255), dash=2, gap=1.5)
    legs(tpl, fab, (213, 214), deco, dict(upper=(26, 26, 30, 255), sole=(246, 246, 248, 255), chunky=True), (236, 236, 240, 255))
    return tpl

# ================================================================ D2 STAGE NIGHT
def stripes_fn(h, w, s, a=(170, 24, 44), b=(18, 16, 20), every=5):
    arr = cotton(h, w, s, base=a)
    yy = np.mgrid[0:h, 0:w][0] / S
    m = ((yy // every) % 2 == 1)[..., None]
    arr[..., :3] = np.where(m, np.array(b, np.float32), arr[..., :3])
    return arr

def d2_shirt():
    tpl = blank()
    fab = lambda h, w, s: cotton(h, w, s, base=(26, 24, 28))
    t = to_img(fab(128 * S, 384 * S, 221))
    d = ImageDraw.Draw(t)
    d.arc(P(102, -18, 154, 14), 0, 180, fill=(16, 14, 18, 255), width=4 * S)
    # rhinestone flaming heart
    m = Image.new("L", t.size, 0)
    dm = ImageDraw.Draw(m)
    dm.polygon([tuple(P(*p)) for p in flames_pts(128, 44, 40, 26, 5)], fill=255)
    fl = Image.new("RGBA", t.size, (0, 0, 0, 0))
    ImageDraw.Draw(fl).polygon([tuple(P(*p)) for p in flames_pts(128, 44, 40, 26, 5)], fill=(255, 120, 40, 255))
    t.alpha_composite(fl)
    rhinestones(t, m, 7, col=(255, 196, 120))
    hm = Image.new("L", t.size, 0)
    ImageDraw.Draw(hm).polygon([tuple(P(*p)) for p in heart_pts(128, 54, 20)], fill=255)
    hl = Image.new("RGBA", t.size, (196, 18, 52, 255))
    hl.putalpha(hm)
    t.alpha_composite(hl)
    rhinestones(t, hm, 8, col=(255, 90, 120))
    d = ImageDraw.Draw(t)
    d.text((128 * S, 84 * S), "MM", font=ImageFont.truetype(BLACK, 8 * S), fill=(236, 236, 240, 255), anchor="mm")
    chrome_text(t, "MM", 320, 42, 40, ow=2.6)
    t2 = Image.new("RGBA", t.size, (0, 0, 0, 0))
    ImageDraw.Draw(t2).text((320 * S, 76 * S), "STAGE NIGHT  \u00b7  TOUR 26", font=ImageFont.truetype(BLACK, 6 * S), fill=(236, 236, 240, 255), anchor="mm")
    t.alpha_composite(distress(t2, 229))
    # a ripped hem showing the red stripes underneath
    for x in (78, 170, 300):
        d.polygon([tuple(P(*p)) for p in ((x, 92), (x + 6, 86), (x + 11, 93), (x + 4, 98))], fill=(160, 24, 44, 255))
    stitch(d, 0, 100, 384, 100, (60, 58, 64, 255), dash=2, gap=1.5)
    clear_rows(t, 103, 128)
    place_torso(tpl, t)
    place_cap(tpl, "torsoU", to_img(fab(64 * S, 128 * S, 222)))
    for layout, seed, cap in ((RLIMB_STRIP, 223, "rU"), (LLIMB_STRIP, 224, "lU")):
        a = to_img(stripes_fn(128 * S, 256 * S, seed))          # long-sleeve striped layer underneath
        tee = to_img(fab(46 * S, 256 * S, seed + 1))
        a.alpha_composite(tee, (0, 0))
        dd = ImageDraw.Draw(a)
        stitch(dd, 0, 42, 256, 42, (64, 62, 68, 255), dash=2, gap=1.5)
        rib(a, 0, 84, 256, 91, (20, 18, 22, 255))
        clear_rows(a, 91, 128)
        place_limb(tpl, a, layout)
        place_cap(tpl, cap, to_img(fab(64 * S, 64 * S, seed + 9)))
    return tpl

def d2_pants():
    tpl = blank()
    fab = lambda h, w, s: denim(h, w, s, base=(44, 44, 54))
    t = to_img(fab(128 * S, 384 * S, 231))
    waistband(t, (38, 38, 46, 255))
    d = ImageDraw.Draw(t)
    chain(d, [(96, 106), (70, 114), (40, 117), (18, 112), (2, 106)])      # front pocket -> hip
    chain(d, [(382, 106), (364, 113), (340, 108)])                       # continues round the back
    clear_rows(t, 0, 96)
    place_torso(tpl, t)
    place_cap(tpl, "torsoD", to_img(fab(64 * S, 128 * S, 232)))
    def deco(a, layout, seed):
        d = ImageDraw.Draw(a)
        f = front_of(layout)
        # knee rip: pale threads across a dark hole
        d.ellipse(P(f + 16, 50, f + 48, 64), fill=(234, 196, 168, 255))
        for k in range(6):
            y = 51.5 + k * 2.2
            d.line(P(f + 15, y, f + 49, y + (k % 2)), fill=(226, 226, 232, 255), width=int(0.8 * S))
        # flare: lighter whiskers widening at the hem
        for x in range(0, 256, 9):
            d.line(P(x, 70, x - 2, 84), fill=(64, 64, 76, 255), width=S)
        stitch(d, outer_of(layout) + 32, 0, outer_of(layout) + 32, 84, (90, 90, 104, 255), dash=2, gap=1.5)
    legs(tpl, fab, (233, 234), deco, dict(upper=(20, 18, 22, 255), sole=(34, 32, 36, 255), chunky=True, boot=True), (34, 32, 36, 255))
    return tpl

# ================================================================ D3 RACER 06
RED, WHITE, BLK = (206, 30, 46, 255), (244, 244, 246, 255), (22, 22, 26, 255)

def d3_shirt():
    tpl = blank()
    fab = lambda h, w, s: leather(h, w, s, base=(236, 236, 240))
    t = to_img(fab(128 * S, 384 * S, 241))
    d = ImageDraw.Draw(t)
    for x0, x1 in ((0, 64), (192, 256)):                         # red side panels
        d.rectangle(P(x0, 0, x1, 100), fill=RED)
    d.rectangle(P(64, 0, 192, 16), fill=RED)                     # red shoulder yoke front
    d.rectangle(P(256, 0, 384, 16), fill=RED)
    for x in (82, 174):                                          # black racing stripes down the front
        d.rectangle(P(x - 3, 16, x + 3, 100), fill=BLK)
    d.line(P(108, 0, 132, 100), fill=(30, 30, 34, 255), width=2 * S)   # off-centre moto zip
    d.line(P(108, 0, 132, 100), fill=SILVER, width=int(0.8 * S))
    d.text((152 * S, 44 * S), "06", font=ImageFont.truetype(IMPACT, 22 * S), fill=BLK, anchor="mm", stroke_width=int(1.4 * S), stroke_fill=RED)
    for i, (txt, y) in enumerate((("MM", 28), ("NIGHTLINE", 40), ("SKY DECK", 52))):   # made-up patches
        d.rounded_rectangle(P(90, y - 5, 120, y + 5), radius=2 * S, fill=BLK if i % 2 == 0 else RED)
        d.text((105 * S, y * S), txt, font=ImageFont.truetype(BLACK, (5 if len(txt) > 3 else 6) * S), fill=WHITE, anchor="mm")
    d.rectangle(P(256, 30, 384, 60), fill=BLK)                   # back: big number band
    d.text((320 * S, 45 * S), "MM RACING", font=ImageFont.truetype(IMPACT, 16 * S), fill=WHITE, anchor="mm")
    d.text((320 * S, 80 * S), "06", font=ImageFont.truetype(IMPACT, 26 * S), fill=RED, anchor="mm", stroke_width=int(1.4 * S), stroke_fill=BLK)
    rib(t, 0, 94, 384, 102, BLK)
    d.rectangle(P(0, 0, 384, 5), fill=BLK)                       # collar
    clear_rows(t, 102, 128)
    place_torso(tpl, t)
    place_cap(tpl, "torsoU", to_img(fab(64 * S, 128 * S, 242)))
    def deco(a, layout):
        d = ImageDraw.Draw(a)
        d.rectangle(P(0, 0, 256, 82), fill=RED)
        arr = np.asarray(a, np.float32).copy()
        arr[..., :3] *= (0.85 + 0.25 * fbm(arr.shape[0], arr.shape[1], [(7 * S, 40 * S)], 7))[..., None]
        a.paste(to_img(arr))
        d = ImageDraw.Draw(a)
        o = outer_of(layout)
        d.rectangle(P(o + 26, 0, o + 38, 82), fill=WHITE)          # white stripe down the outer arm
        d.rectangle(P(o + 30, 0, o + 34, 82), fill=BLK)
        f = front_of(layout)
        d.rounded_rectangle(P(f + 14, 40, f + 50, 58), radius=3 * S, fill=BLK)   # elbow/forearm pad
        for x in range(int(f + 18), int(f + 50), 6):
            d.line(P(x, 42, x, 56), fill=(48, 48, 56, 255), width=S)
    sleeves(tpl, fab, (243, 244), BLK, deco)
    return tpl

def d3_pants():
    tpl = blank()
    fab = lambda h, w, s: leather(h, w, s, base=(30, 30, 34), horizontal_folds=True)
    t = to_img(fab(128 * S, 384 * S, 251))
    waistband(t, (24, 24, 28, 255), button=False)
    clear_rows(t, 0, 96)
    place_torso(tpl, t)
    place_cap(tpl, "torsoD", to_img(fab(64 * S, 128 * S, 252)))
    def deco(a, layout, seed):
        d = ImageDraw.Draw(a)
        o = outer_of(layout)
        d.rectangle(P(o + 24, 0, o + 40, 91), fill=WHITE)
        d.rectangle(P(o + 29, 0, o + 35, 91), fill=RED)
        f = front_of(layout)
        d.rounded_rectangle(P(f + 10, 42, f + 54, 66), radius=4 * S, fill=(52, 52, 60, 255), outline=(14, 14, 18, 255), width=S)
        for y in range(46, 64, 5):
            d.line(P(f + 12, y, f + 52, y), fill=(36, 36, 42, 255), width=S)
    legs(tpl, fab, (253, 254), deco, dict(upper=RED, sole=WHITE, accent=BLK, chunky=True), (236, 236, 240, 255))
    return tpl

# ================================================================ D4 URBAN CAMO
def d4_shirt():
    tpl = blank()
    def fab(h, w, s):
        a = cotton(h, w, s, base=(146, 146, 150))
        shade(a, 0.9 + 0.16 * fbm(h, w, [(14 * S, 30 * S), (5 * S, 5 * S)], s + 3))   # washed
        return a
    t = to_img(fab(128 * S, 384 * S, 261))
    d = ImageDraw.Draw(t)
    d.arc(P(102, -18, 154, 14), 0, 180, fill=(116, 116, 120, 255), width=4 * S)
    big = Image.new("RGBA", t.size, (0, 0, 0, 0))
    db = ImageDraw.Draw(big)
    db.text((128 * S, 48 * S), "MM", font=ImageFont.truetype(IMPACT, 50 * S), fill=(244, 244, 246, 255), anchor="mm")
    db.text((128 * S, 80 * S), "URBAN  CAMO  DIVISION", font=ImageFont.truetype(BLACK, 5 * S), fill=(30, 30, 32, 255), anchor="mm")
    db.text((320 * S, 40 * S), "NO. 04", font=ImageFont.truetype(IMPACT, 22 * S), fill=(30, 30, 32, 255), anchor="mm")
    t.alpha_composite(distress(big, 269, 0.6))
    stitch(d, 0, 102, 384, 102, (120, 120, 124, 255), dash=2, gap=1.5)
    clear_rows(t, 106, 128)
    place_torso(tpl, t)
    place_cap(tpl, "torsoU", to_img(fab(64 * S, 128 * S, 262)))
    for layout, seed, cap in ((RLIMB_STRIP, 263, "rU"), (LLIMB_STRIP, 264, "lU")):
        a = to_img(stripes_fn(128 * S, 256 * S, seed, a=(232, 232, 234), b=(30, 30, 34), every=3))   # thermal
        a.alpha_composite(to_img(fab(46 * S, 256 * S, seed + 1)), (0, 0))
        dd = ImageDraw.Draw(a)
        stitch(dd, 0, 42, 256, 42, (116, 116, 120, 255), dash=2, gap=1.5)
        rib(a, 0, 84, 256, 91, (28, 28, 32, 255))
        clear_rows(a, 91, 128)
        place_limb(tpl, a, layout)
        place_cap(tpl, cap, to_img(fab(64 * S, 64 * S, seed + 9)))
    return tpl

def d4_pants():
    tpl = blank()
    cols = [(126, 128, 130), (82, 84, 88), (176, 176, 178), (40, 40, 44)]
    fab = lambda h, w, s: camo(h, w, s, cols)
    t = to_img(fab(128 * S, 384 * S, 271))
    waistband(t, (36, 36, 40, 255))
    clear_rows(t, 0, 96)
    place_torso(tpl, t)
    place_cap(tpl, "torsoD", to_img(fab(64 * S, 128 * S, 272)))
    def deco(a, layout, seed):
        d = ImageDraw.Draw(a)
        o, f = outer_of(layout), front_of(layout)
        d.rectangle(P(o + 10, 38, o + 54, 72), fill=(70, 72, 76, 255), outline=(30, 30, 34, 255), width=S)
        d.rectangle(P(o + 9, 36, o + 55, 46), fill=(58, 60, 64, 255), outline=(26, 26, 30, 255), width=S)
        # bondage-style straps across the front, with silver buckles
        d.line(P(f + 2, 26, f + 62, 40), fill=(18, 18, 22, 255), width=3 * S)
        d.rectangle(P(f + 28, 29, f + 36, 37), outline=SILVER, width=int(1.2 * S))
        d.line(P(f + 2, 70, f + 62, 62), fill=(18, 18, 22, 255), width=3 * S)
        d.rectangle(P(f + 30, 62, f + 38, 70), outline=SILVER, width=int(1.2 * S))
        arr = stacked(np.asarray(a, np.float32).copy(), seed, start=70, end=84, depth=0.15)
        a.paste(to_img(arr))
    legs(tpl, fab, (273, 274), deco, dict(upper=(24, 22, 24, 255), sole=(40, 38, 42, 255), chunky=True, boot=True), (40, 38, 42, 255))
    return tpl

# ================================================================ D5 PINK GALAXY
def d5_shirt():
    tpl = blank()
    t = to_img(galaxy(128 * S, 384 * S, 281))
    hoodie_front(t, (210, 70, 160, 255), (90, 24, 110, 255))
    d = ImageDraw.Draw(t)
    star(d, 150, 26, 3.5, (255, 255, 255, 255))
    d.text((150 * S, 34 * S), "MM", font=ImageFont.truetype(BLACK, 6 * S), fill=(255, 255, 255, 255), anchor="mt")
    chrome_text(t, "PINK GALAXY", 320, 56, 15, stops=[(0, (255, 236, 250)), (0.45, (255, 150, 214)), (0.5, (150, 40, 130)), (0.62, (255, 130, 200)), (1, (255, 230, 248))], ow=1.6)
    clear_rows(t, 102, 128)
    place_torso(tpl, t)
    place_cap(tpl, "torsoU", to_img(galaxy(64 * S, 128 * S, 282)))
    sleeves(tpl, galaxy, (283, 284), (210, 70, 160, 255))
    return tpl

def d5_pants():
    tpl = blank()
    fab = lambda h, w, s: cotton(h, w, s, base=(240, 238, 242))
    t = to_img(fab(128 * S, 384 * S, 291))
    waistband(t, (232, 230, 236, 255))
    clear_rows(t, 0, 96)
    place_torso(tpl, t)
    place_cap(tpl, "torsoD", to_img(fab(64 * S, 128 * S, 292)))
    PK = (240, 110, 180, 255)
    def deco(a, layout, seed):
        d = ImageDraw.Draw(a)
        o, f = outer_of(layout), front_of(layout)
        d.rectangle(P(o + 10, 38, o + 54, 72), fill=(230, 228, 234, 255), outline=(196, 194, 202, 255), width=S)
        d.rectangle(P(o + 9, 36, o + 55, 46), fill=(224, 222, 230, 255), outline=(190, 188, 196, 255), width=S)
        d.line(P(f + 2, 30, f + 62, 22), fill=PK, width=3 * S)
        d.rectangle(P(f + 26, 22, f + 34, 30), outline=SILVER, width=int(1.2 * S))
        d.line(P(o + 4, 60, o + 4, 84), fill=PK, width=2 * S)         # hanging strap
        arr = stacked(np.asarray(a, np.float32).copy(), seed, start=64, end=91, depth=0.12)
        a.paste(to_img(arr))
    legs(tpl, fab, (293, 294), deco, dict(upper=(250, 150, 200, 255), sole=(250, 250, 252, 255), accent=(255, 255, 255, 255), chunky=True), (240, 240, 244, 255))
    return tpl

# ================================================================ D6 MM MONOGRAM
def d6_shirt():
    tpl = blank()
    t = to_img(monogram(128 * S, 384 * S, 301))
    hoodie_front(t, (128, 168, 214, 255), (140, 180, 224, 255), zip_=True)
    d = ImageDraw.Draw(t)
    zipper(d, 128, 0, 102, pull=SILVER)
    for x0, x1 in ((86, 98), (170, 158)):                         # slanted side pockets
        d.line(P(x0, 62, x1, 88), fill=(106, 144, 190, 255), width=2 * S)
    clear_rows(t, 102, 128)
    place_torso(tpl, t)
    place_cap(tpl, "torsoU", to_img(monogram(64 * S, 128 * S, 302)))
    sleeves(tpl, monogram, (303, 304), (128, 168, 214, 255))
    return tpl

def d6_pants():
    tpl = blank()
    fab = lambda h, w, s: denim(h, w, s, base=(168, 196, 230))
    t = to_img(fab(128 * S, 384 * S, 311))
    waistband(t, (156, 186, 222, 255), fly_col=None)
    d = ImageDraw.Draw(t)
    for x0 in (272, 328):                                          # monogram back pockets
        pocket = to_img(monogram(20 * S, 26 * S, 319 + x0))
        t.alpha_composite(pocket, (x0 * S, 108 * S))
        d.rectangle(P(x0, 108, x0 + 26, 128), outline=ORANGE, width=S)
    clear_rows(t, 0, 96)
    place_torso(tpl, t)
    place_cap(tpl, "torsoD", to_img(fab(64 * S, 128 * S, 312)))
    def deco(a, layout, seed):
        arr = stacked(np.asarray(a, np.float32).copy(), seed, depth=0.22)
        a.paste(to_img(arr))
        d = ImageDraw.Draw(a)
        stitch(d, outer_of(layout) + 32, 0, outer_of(layout) + 32, 91, ORANGE, dash=2, gap=1.5)
    legs(tpl, fab, (313, 314), deco, dict(upper=(246, 246, 248, 255), sole=(214, 214, 220, 255), accent=(140, 180, 224, 255)), (214, 214, 220, 255))
    return tpl

LOOKS = [("D1_neon_star", d1_shirt, d1_pants), ("D2_stage_night", d2_shirt, d2_pants), ("D3_racer_06", d3_shirt, d3_pants),
         ("D4_urban_camo", d4_shirt, d4_pants), ("D5_pink_galaxy", d5_shirt, d5_pants), ("D6_mm_monogram", d6_shirt, d6_pants)]

if __name__ == "__main__":
    import sys
    os.makedirs(OUT, exist_ok=True)
    only = sys.argv[1:] or [n for n, _, _ in LOOKS]
    for name, fs, fp in LOOKS:
        if name not in only:
            continue
        shirt, pants = fs(), fp()
        for kind, img, tp in (("shirt", shirt, "Template-Shirts-R15.png"), ("pants", pants, "Template-Pants-R15.png")):
            check(img, f"{name}_{kind}")
            path = os.path.join(OUT, f"MM_{name}_{kind}.png")
            img.save(path, optimize=True)
            overlay(img, tp).save(os.path.join(OUT, f"check_{name}_{kind}_on_template.png"))
            print(f"{os.path.basename(path)}  {os.path.getsize(path)//1024} KB  ok")
