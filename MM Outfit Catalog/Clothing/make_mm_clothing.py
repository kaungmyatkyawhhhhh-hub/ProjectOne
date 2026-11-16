"""MM Outfit Catalog: original classic shirts + pants on Roblox's official 585x559 template (16 Nov 2026).

Owner rule: clothing must be on the official template, or it can't be uploaded. Panel boxes were measured from
Roblox's own Template-Shirts-R15.png / Template-Pants-R15.png (in this folder):
  torso  UP 231,8 128x64 | R 165,74 | FRONT 231,74 128x128 | L 361,74 | BACK 427,74 128x128 | DOWN 231,204 128x64
  r.arm/r.leg  L 19,355 | B 85,355 | R 151,355 | F 217,355 (64x128) | U 217,289 | D 217,485 (64x64)
  l.arm/l.leg  F 308,355 | L 374,355 | B 440,355 | R 506,355 (64x128) | U 308,289 | D 308,485 (64x64)
  R15 split lines: torso row 96 of 128 (lower torso below), arms/legs row 91 of 128 (hands/feet below).

Each garment is painted as continuous wrap-around strips (torso R|F|L|B = 384x128, limbs 256x128), so folds and
seams meet across the faces, at 4x size, then shrunk and cut into the boxes. `check()` fails if any opaque pixel
lands outside a box. Run: python make_mm_clothing.py  -> out/*.png + previews.
"""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")
S = 4  # supersample
W, H = 585, 559

TORSO = {"R": (165, 74, 64), "F": (231, 74, 128), "L": (361, 74, 64), "B": (427, 74, 128)}
TORSO_STRIP = [("R", 0, 64), ("F", 64, 128), ("L", 192, 64), ("B", 256, 128)]
RLIMB_STRIP = [("L", 0, 19), ("B", 64, 85), ("R", 128, 151), ("F", 192, 217)]   # right arm / right leg
LLIMB_STRIP = [("F", 0, 308), ("L", 64, 374), ("B", 128, 440), ("R", 192, 506)]  # left arm / left leg
CAPS = {"torsoU": (231, 8, 128, 64), "torsoD": (231, 204, 128, 64),
        "rU": (217, 289, 64, 64), "rD": (217, 485, 64, 64), "lU": (308, 289, 64, 64), "lD": (308, 485, 64, 64)}
BOXES = [(165, 74, 64, 128), (231, 74, 128, 128), (361, 74, 64, 128), (427, 74, 128, 128)] + \
        [(x, 355, 64, 128) for x in (19, 85, 151, 217, 308, 374, 440, 506)] + list(CAPS.values())
FONT = "C:/Windows/Fonts/arialbd.ttf"

# ---------------------------------------------------------------- noise + colour helpers
def noise(h, w, cy, cx, seed, wrap=True):
    """Smooth value noise, cells cy x cx px, tileable left-right (strips wrap around the body)."""
    rng = np.random.default_rng(seed)
    gh, gw = max(2, h // cy + 2), max(2, w // cx)
    g = rng.random((gh, gw))
    if wrap:
        g3 = np.concatenate([g, g, g], axis=1)
        img = Image.fromarray((g3 * 255).astype(np.uint8)).resize((w * 3, h + 2 * cy), Image.BICUBIC)
        a = np.asarray(img, dtype=np.float32)[cy:cy + h, w:2 * w] / 255
    else:
        img = Image.fromarray((g * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
        a = np.asarray(img, dtype=np.float32) / 255
    return a

def fbm(h, w, cells, seed):
    tot, amp, out = 0, 1.0, np.zeros((h, w), np.float32)
    for i, (cy, cx) in enumerate(cells):
        out += amp * noise(h, w, cy, cx, seed + i * 17)
        tot += amp
        amp *= 0.5
    return out / tot

def solid(h, w, rgb):
    a = np.zeros((h, w, 4), np.float32)
    a[..., :3] = np.array(rgb, np.float32)
    a[..., 3] = 255
    return a

def shade(arr, f):
    arr[..., :3] = np.clip(arr[..., :3] * f[..., None], 0, 255)
    return arr

def to_img(arr):
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")

def clear_rows(img, y0, y1):
    """Make rows [y0,y1) (template px) transparent."""
    d = ImageDraw.Draw(img)
    d.rectangle([0, y0 * S, img.width, y1 * S], fill=(0, 0, 0, 0))

def P(*v):  # template px -> supersampled px
    return [int(round(x * S)) for x in v]

# ---------------------------------------------------------------- fabrics (return supersampled RGBA arrays)
def leather(h, w, seed, base=(48, 36, 31), horizontal_folds=False):
    a = solid(h, w, base)
    big = fbm(h, w, [(40 * S, 30 * S), (16 * S, 12 * S)], seed)
    if horizontal_folds:   # sleeves / legs scrunch around the limb
        r = 1 - np.abs(fbm(h, w, [(7 * S, 44 * S), (4 * S, 22 * S)], seed + 5) * 2 - 1)
    else:                  # torso hangs: mostly vertical creases
        r = 1 - np.abs(fbm(h, w, [(46 * S, 9 * S), (20 * S, 5 * S)], seed + 5) * 2 - 1)
    # matte leather: broad soft folds + a faint sheen only on the sharpest fold tops (strong sheen read as water)
    soft = Image.fromarray((r * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.6 * S))
    r = np.asarray(soft, np.float32) / 255
    crease = np.clip((r - 0.72) / 0.28, 0, 1) ** 2
    grain = fbm(h, w, [(2, 2)], seed + 9)
    pores = fbm(h, w, [(1, 1)], seed + 13)
    f = 0.80 + 0.32 * big - 0.14 * r + 0.05 * (grain - 0.5) + 0.04 * (pores - 0.5)
    shade(a, f)
    a[..., :3] += (crease * 26)[..., None] * np.array([1.0, 0.9, 0.82])
    return a

def cotton(h, w, seed, base=(245, 243, 239)):
    a = solid(h, w, base)
    folds = fbm(h, w, [(60 * S, 18 * S), (24 * S, 10 * S)], seed)
    weave = fbm(h, w, [(1, 1)], seed + 3)
    shade(a, 0.9 + 0.12 * folds + 0.025 * (weave - 0.5))
    return a

def denim(h, w, seed, base=(150, 176, 210)):
    a = solid(h, w, base)
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    twill = np.sin((xx + yy) * 2 * np.pi / (2.4 * S)) * 0.5 + 0.5
    slub = fbm(h, w, [(30 * S, 1 * S), (12 * S, 2)], seed)
    fade = fbm(h, w, [(50 * S, 30 * S)], seed + 4)
    shade(a, 0.86 + 0.07 * twill + 0.10 * slub + 0.12 * fade)
    return a

def puffer(h, w, seed, base=(252, 248, 251), channel=13):
    a = solid(h, w, base)
    yy = np.mgrid[0:h, 0:w][0].astype(np.float32) / S
    ph = (yy % channel) / channel
    pillow = np.sin(np.pi * ph) ** 0.5
    bumps = fbm(h, w, [(channel * S, 7 * S), (channel * S // 2, 4 * S)], seed)     # padding bunches inside each channel
    light = np.exp(-((ph - 0.32) / 0.16) ** 2)                                    # light from above: bright upper half
    seam = np.clip(1 - ph / 0.07, 0, 1) + np.clip((ph - 0.95) / 0.05, 0, 1)
    f = 0.70 + 0.24 * pillow + 0.08 * light + 0.07 * (bumps - 0.5) * pillow - 0.16 * seam
    shade(a, f)
    a[..., 2] += (1 - pillow) * 10          # cool-pink shadow in the stitched seams
    a[..., 0] += (1 - pillow) * 4
    return a

def tiedye(h, w, seed):
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32) / S
    n = fbm(h, w, [(34 * S, 34 * S), (14 * S, 14 * S), (6 * S, 6 * S)], seed)
    t = 0.5 + 0.5 * np.sin(n * 13 + xx * 0.05)
    t = np.clip(t, 0, 1)
    white, pink, hot = np.array([252, 238, 246.]), np.array([246, 140, 192.]), np.array([228, 52, 132.])
    c = np.where(t[..., None] < 0.5, white + (pink - white) * (t[..., None] * 2), pink + (hot - pink) * ((t[..., None] - 0.5) * 2))
    a = np.zeros((h, w, 4), np.float32)
    a[..., :3] = c
    a[..., 3] = 255
    shade(a, 0.93 + 0.1 * fbm(h, w, [(30 * S, 12 * S)], seed + 2))
    return a

# ---------------------------------------------------------------- shared details
def stitch(d, x0, y0, x1, y1, col, dash=3, gap=2, width=1):
    """Dashed stitch line between two template-px points."""
    L = max(1e-6, np.hypot(x1 - x0, y1 - y0))
    t = 0.0
    while t < L:
        t2 = min(L, t + dash)
        d.line(P(x0 + (x1 - x0) * t / L, y0 + (y1 - y0) * t / L, x0 + (x1 - x0) * t2 / L, y0 + (y1 - y0) * t2 / L), fill=col, width=int(width * S))
        t += dash + gap

def rib(img, x0, y0, x1, y1, base, dark=0.78, every=2):
    d = ImageDraw.Draw(img)
    d.rectangle(P(x0, y0, x1, y1), fill=base)
    darker = tuple(int(c * dark) for c in base[:3]) + (255,)
    x = x0
    while x < x1:
        d.line(P(x, y0, x, y1), fill=darker, width=S // 2)
        x += every

def zipper(d, x, y0, y1, light=(196, 196, 204, 255), dark=(108, 108, 118, 255), pull=None):
    y = y0
    i = 0
    while y < y1:
        d.rectangle(P(x - 2, y, x + 2, y + 1), fill=light if i % 2 == 0 else dark)
        y += 1
        i += 1
    if pull:
        d.rounded_rectangle(P(x - 1.5, y0 + 6, x + 1.5, y0 + 15), radius=S, fill=pull)

def studs(d, pts, r=1.3):
    for x, y in pts:
        d.ellipse(P(x - r, y - r, x + r, y + r), fill=(168, 160, 150, 255))
        d.ellipse(P(x - r * 0.45, y - r * 0.6, x + r * 0.1, y - r * 0.05), fill=(236, 230, 220, 255))

def place_torso(tpl, strip):
    small = strip.resize((strip.width // S, strip.height // S), Image.LANCZOS)
    for name, sx, w in TORSO_STRIP:
        tpl.alpha_composite(small.crop((sx, 0, sx + w, 128)), (TORSO[name][0], 74))

def place_limb(tpl, strip, layout):
    small = strip.resize((strip.width // S, strip.height // S), Image.LANCZOS)
    for _, sx, tx in layout:
        tpl.alpha_composite(small.crop((sx, 0, sx + 64, 128)), (tx, 355))

def place_cap(tpl, key, img):
    x, y, w, h = CAPS[key]
    tpl.alpha_composite(img.resize((w, h), Image.LANCZOS), (x, y))

def blank():
    return Image.new("RGBA", (W, H), (0, 0, 0, 0))

def strip_img(arr):
    return to_img(arr)

# ================================================================ 01 MIDNIGHT TRACK
def midnight_shirt():
    tpl = blank()
    # torso: biker jacket, ends at the R15 waist line (row 96) so the belt on the pants shows
    t = strip_img(leather(128 * S, 384 * S, 11))
    d = ImageDraw.Draw(t)
    rib(t, 0, 86, 384, 96, (34, 26, 23, 255))                        # waist band
    d.rectangle(P(0, 0, 384, 7), fill=(30, 23, 21, 255))             # stand collar
    stitch(d, 0, 7.5, 384, 7.5, (92, 74, 62, 255))
    for cx in (32, 224):                                             # side seams
        d.line(P(cx, 8, cx, 86), fill=(26, 20, 18, 255), width=S)
        stitch(d, cx + 1.5, 8, cx + 1.5, 86, (90, 72, 60, 255))
    d.line(P(256, 30, 384, 30), fill=(28, 21, 19, 255), width=S)    # back yoke
    stitch(d, 256, 31.5, 384, 31.5, (90, 72, 60, 255))
    for x0, x1 in ((82, 104), (174, 152)):                           # slanted chest zip pockets
        d.line(P(x0, 44, x1, 62), fill=(22, 17, 15, 255), width=3 * S)
        d.line(P(x0, 44, x1, 62), fill=(170, 170, 178, 255), width=S)
    zipper(d, 128, 0, 96, pull=(214, 214, 222, 255))
    studs(d, [(x, 11) for x in list(range(70, 112, 6)) + list(range(148, 190, 6))] +
             [(x, 11) for x in range(262, 380, 6)] + [(x, 11) for x in range(6, 60, 6)] + [(x, 11) for x in range(198, 252, 6)])
    clear_rows(t, 96, 128)
    place_torso(tpl, t)
    u = strip_img(leather(64 * S, 128 * S, 12))
    du = ImageDraw.Draw(u)
    du.rectangle(P(44, 18, 84, 46), outline=(28, 22, 19, 255), width=3 * S)   # collar ring round the neck
    place_cap(tpl, "torsoU", u)
    # sleeves: long, scrunched, ribbed cuff, bare hands below row 91
    for layout, seed, cap in ((RLIMB_STRIP, 21, "rU"), (LLIMB_STRIP, 22, "lU")):
        a = strip_img(leather(128 * S, 256 * S, seed, horizontal_folds=True))
        rib(a, 0, 80, 256, 91, (34, 26, 23, 255))
        clear_rows(a, 91, 128)
        place_limb(tpl, a, layout)
        c = strip_img(leather(64 * S, 64 * S, seed + 40))
        studs(ImageDraw.Draw(c), [(32 + 23 * np.cos(k * np.pi / 7), 32 + 23 * np.sin(k * np.pi / 7)) for k in range(14)])
        place_cap(tpl, cap, c)
    return tpl

def midnight_pants():
    tpl = blank()
    t = strip_img(leather(128 * S, 384 * S, 31))
    d = ImageDraw.Draw(t)
    d.rectangle(P(0, 96, 384, 106), fill=(22, 18, 17, 255))          # belt
    stitch(d, 0, 97.5, 384, 97.5, (70, 60, 54, 255))
    stitch(d, 0, 104.5, 384, 104.5, (70, 60, 54, 255))
    for bx in (32, 84, 172, 224, 286, 354):                           # belt loops
        d.rectangle(P(bx - 1.5, 95, bx + 1.5, 107), fill=(40, 31, 27, 255))
    d.rectangle(P(119, 95, 137, 107), outline=(206, 200, 190, 255), width=int(1.6 * S))   # buckle
    d.line(P(128, 96, 128, 106), fill=(206, 200, 190, 255), width=S)
    d.line(P(128, 106, 128, 128), fill=(24, 19, 17, 255), width=S)   # fly
    stitch(d, 132, 107, 132, 122, (88, 72, 60, 255))
    d.arc(P(118, 112, 132, 128), 0, 90, fill=(88, 72, 60, 255), width=S)
    for x0, x1 in ((70, 92), (186, 164)):                             # front pocket openings
        d.line(P(x0, 106, x1, 122), fill=(26, 20, 18, 255), width=S * 2)
    clear_rows(t, 0, 96)
    place_torso(tpl, t)
    place_cap(tpl, "torsoD", strip_img(leather(64 * S, 128 * S, 32)))
    for layout, seed, outer, (capU, capD) in ((RLIMB_STRIP, 41, 128, ("rU", "rD")), (LLIMB_STRIP, 42, 64, ("lU", "lD"))):
        a = strip_img(leather(128 * S, 256 * S, seed, horizontal_folds=True))
        d = ImageDraw.Draw(a)
        # cargo pocket on the outer face, with flap + snap
        d.rectangle(P(outer + 10, 40, outer + 54, 74), fill=(42, 32, 28, 255), outline=(24, 19, 17, 255), width=S)
        d.rectangle(P(outer + 9, 38, outer + 55, 48), fill=(36, 28, 24, 255), outline=(22, 17, 15, 255), width=S)
        stitch(d, outer + 12, 46, outer + 52, 46, (84, 68, 58, 255))
        d.ellipse(P(outer + 30, 41, outer + 34, 45), fill=(190, 184, 174, 255))
        # boots below the R15 foot line
        boot = strip_img(leather(37 * S, 256 * S, seed + 7, base=(20, 18, 18)))
        a.alpha_composite(boot, (0, 91 * S))
        d = ImageDraw.Draw(a)
        d.rectangle(P(0, 122, 256, 128), fill=(44, 42, 46, 255))
        d.line(P(0, 122, 256, 122), fill=(80, 78, 84, 255), width=S)
        front = 192 if layout is RLIMB_STRIP else 0
        for k in range(4):                                            # laces
            y = 95 + k * 6
            d.line(P(front + 24, y, front + 40, y + 4), fill=(70, 66, 70, 255), width=S)
            d.line(P(front + 40, y, front + 24, y + 4), fill=(70, 66, 70, 255), width=S)
        place_limb(tpl, a, layout)
        place_cap(tpl, capU, strip_img(leather(64 * S, 64 * S, seed + 60)))
        sole = Image.new("RGBA", (64 * S, 64 * S), (40, 40, 44, 255))
        ds = ImageDraw.Draw(sole)
        for y in range(4, 64, 6):
            ds.line(P(4, y, 60, y), fill=(28, 28, 30, 255), width=2 * S)
        place_cap(tpl, capD, sole)
    return tpl

# ================================================================ 02 FROST
def frost_shirt():
    tpl = blank()
    t = strip_img(cotton(128 * S, 384 * S, 51))
    d = ImageDraw.Draw(t)
    for cx in (32, 224):
        d.line(P(cx, 0, cx, 112), fill=(226, 224, 220, 255), width=S)
    stitch(d, 0, 106, 384, 106, (214, 212, 208, 255), dash=2, gap=1.5)   # hem (oversized: covers the waist)
    stitch(d, 0, 108.5, 384, 108.5, (214, 212, 208, 255), dash=2, gap=1.5)
    d.arc(P(102, -18, 154, 14), 0, 180, fill=(206, 204, 200, 255), width=4 * S)   # crew neck rib, front
    d.arc(P(105, -15, 151, 11), 0, 180, fill=(232, 230, 226, 255), width=S)
    d.arc(P(294, -9, 346, 6), 0, 180, fill=(206, 204, 200, 255), width=4 * S)     # back neck
    font_s = ImageFont.truetype(FONT, 9 * S)
    d.text(P(146, 30), "MM", font=font_s, fill=(150, 172, 204, 255))                 # small chest mark
    font_b = ImageFont.truetype(FONT, 42 * S)
    layer = Image.new("RGBA", t.size, (0, 0, 0, 0))
    dl = ImageDraw.Draw(layer)
    dl.text((P(320)[0], P(46)[0]), "MM", font=font_b, fill=(160, 196, 236, 255), anchor="mm")
    dl.text((P(320)[0], P(76)[0]), "FROST  \u00b7  02", font=ImageFont.truetype(FONT, 8 * S), fill=(160, 196, 236, 255), anchor="mm")
    crack = fbm(layer.height, layer.width, [(S, S), (S // 2 or 1, S // 2 or 1)], 57)   # fine worn-print speckle
    la = np.asarray(layer, np.float32)
    la[..., 3] *= np.clip(0.55 + (crack - 0.5) * 2.2, 0.35, 1)
    t.alpha_composite(to_img(la))
    clear_rows(t, 112, 128)
    place_torso(tpl, t)
    u = strip_img(cotton(64 * S, 128 * S, 52))
    ImageDraw.Draw(u).ellipse(P(42, 16, 86, 48), outline=(222, 220, 216, 255), width=3 * S)
    place_cap(tpl, "torsoU", u)
    for layout, seed, cap in ((RLIMB_STRIP, 61, "rU"), (LLIMB_STRIP, 62, "lU")):
        a = strip_img(cotton(128 * S, 256 * S, seed))
        d = ImageDraw.Draw(a)
        stitch(d, 0, 42, 256, 42, (214, 212, 208, 255), dash=2, gap=1.5)
        clear_rows(a, 46, 128)                                           # short sleeves
        place_limb(tpl, a, layout)
        place_cap(tpl, cap, strip_img(cotton(64 * S, 64 * S, seed + 9)))
    return tpl

ORANGE = (214, 150, 74, 255)

def frost_pants():
    tpl = blank()
    t = strip_img(denim(128 * S, 384 * S, 71))
    d = ImageDraw.Draw(t)
    d.rectangle(P(0, 92, 384, 103), fill=(140, 166, 200, 255))           # waistband
    stitch(d, 0, 93.5, 384, 93.5, ORANGE, dash=2, gap=1.5)
    stitch(d, 0, 101.5, 384, 101.5, ORANGE, dash=2, gap=1.5)
    for bx in (30, 86, 170, 226, 290, 350):
        d.rectangle(P(bx - 1.5, 91, bx + 1.5, 105), fill=(132, 158, 194, 255))
    d.ellipse(P(125, 94, 131, 100), fill=(182, 140, 92, 255))           # button
    stitch(d, 133, 104, 133, 122, ORANGE, dash=2, gap=1.5)               # fly
    d.arc(P(119, 110, 133, 126), 0, 90, fill=ORANGE, width=S)
    for x0 in (72, 184):                                                 # front pockets
        d.arc(P(x0 - 18, 92, x0 + 18, 124), 0 if x0 > 128 else 90, 90 if x0 > 128 else 180, fill=ORANGE, width=S)
    for rx in (88, 168):
        d.ellipse(P(rx - 1.2, 106, rx + 1.2, 108.4), fill=(190, 150, 100, 255))   # rivets
    for x0 in (272, 328):                                                # back pockets
        d.rectangle(P(x0, 108, x0 + 26, 128), outline=ORANGE, width=S)
    clear_rows(t, 0, 92)
    place_torso(tpl, t)
    place_cap(tpl, "torsoD", strip_img(denim(64 * S, 128 * S, 72)))
    for layout, seed, outer, (capU, capD) in ((RLIMB_STRIP, 81, 128, ("rU", "rD")), (LLIMB_STRIP, 82, 64, ("lU", "lD"))):
        a = strip_img(denim(128 * S, 256 * S, seed))
        arr = np.asarray(a, np.float32).copy()
        # light thigh fade on the front face + stacked folds near the hem (baggy)
        front = 192 if layout is RLIMB_STRIP else 0
        yy, xx = np.mgrid[0:arr.shape[0], 0:arr.shape[1]].astype(np.float32) / S
        fx = np.minimum(np.abs(xx - (front + 32)), 256 - np.abs(xx - (front + 32)))
        fade = np.exp(-(fx / 16) ** 2 - ((yy - 34) / 22) ** 2)
        arr[..., :3] += fade[..., None] * 34
        stack = np.clip((yy - 64) / 27, 0, 1) * (0.5 + 0.5 * np.sin(yy * 2 * np.pi / 6 + 3 * fbm(arr.shape[0], arr.shape[1], [(6 * S, 20 * S)], seed + 5)))
        arr[..., :3] *= (1 - 0.18 * stack)[..., None]
        a = to_img(arr)
        d = ImageDraw.Draw(a)
        stitch(d, outer + 32, 0, outer + 32, 91, ORANGE, dash=2, gap=1.5)   # outseam
        inner = 0 if layout is RLIMB_STRIP else 192
        d.line(P(inner + 32, 0, inner + 32, 91), fill=(128, 152, 188, 255), width=S)
        # white sneakers
        d.rectangle(P(0, 91, 256, 128), fill=(240, 240, 238, 255))
        d.rectangle(P(0, 118, 256, 128), fill=(206, 206, 210, 255))
        d.line(P(0, 118, 256, 118), fill=(180, 180, 186, 255), width=S)
        for k in range(3):
            y = 95 + k * 5
            d.line(P(front + 22, y, front + 42, y), fill=(196, 196, 202, 255), width=S)
        d.rectangle(P((front + 128) % 256 + 22, 100, (front + 128) % 256 + 42, 117), fill=(226, 226, 230, 255))  # heel tab
        place_limb(tpl, a, layout)
        place_cap(tpl, capU, strip_img(denim(64 * S, 64 * S, seed + 7)))
        sole = Image.new("RGBA", (64 * S, 64 * S), (210, 210, 214, 255))
        ds = ImageDraw.Draw(sole)
        for y in range(5, 64, 7):
            ds.line(P(5, y, 59, y), fill=(186, 186, 192, 255), width=2 * S)
        place_cap(tpl, capD, sole)
    return tpl

# ================================================================ 03 SAKURA
PINK = (240, 112, 172, 255)

def sakura_shirt():
    tpl = blank()
    t = strip_img(puffer(128 * S, 384 * S, 91))
    d = ImageDraw.Draw(t)
    d.rectangle(P(0, 0, 384, 9), fill=(246, 238, 243, 255))           # high collar
    d.line(P(0, 9, 384, 9), fill=(226, 214, 222, 255), width=S)
    rib(t, 0, 98, 384, 104, (244, 236, 241, 255), dark=0.93, every=3)  # elastic hem
    zipper(d, 128, 0, 104, light=(250, 150, 196, 255), dark=(214, 92, 150, 255), pull=PINK)
    for cx in (32, 224):
        d.line(P(cx, 9, cx, 98), fill=(230, 220, 228, 255), width=S)
    clear_rows(t, 104, 128)
    place_torso(tpl, t)
    u = strip_img(puffer(64 * S, 128 * S, 92))
    ImageDraw.Draw(u).rectangle(P(44, 18, 84, 46), outline=(236, 226, 233, 255), width=3 * S)
    place_cap(tpl, "torsoU", u)
    for layout, seed, cap in ((RLIMB_STRIP, 101, "rU"), (LLIMB_STRIP, 102, "lU")):
        a = strip_img(puffer(128 * S, 256 * S, seed, channel=12))
        rib(a, 0, 82, 256, 91, (242, 134, 184, 255), dark=0.86)
        clear_rows(a, 91, 128)
        place_limb(tpl, a, layout)
        place_cap(tpl, cap, strip_img(puffer(64 * S, 64 * S, seed + 9)))
    return tpl

def sakura_pants():
    tpl = blank()
    t = strip_img(tiedye(128 * S, 384 * S, 111))
    rib(t, 0, 96, 384, 107, (250, 246, 248, 255), dark=0.9)
    d = ImageDraw.Draw(t)
    for cx, sway in ((125, -2), (131, 3)):                              # drawstrings
        d.line(P(cx, 106, cx + sway, 124), fill=(255, 255, 255, 255), width=int(1.6 * S))
        d.rectangle(P(cx + sway - 1, 122, cx + sway + 1, 126), fill=(220, 210, 216, 255))
    d.ellipse(P(124, 103, 132, 108), outline=(255, 255, 255, 255), width=S)   # bow knot
    clear_rows(t, 0, 96)
    place_torso(tpl, t)
    place_cap(tpl, "torsoD", strip_img(tiedye(64 * S, 128 * S, 112)))
    for layout, seed, outer, (capU, capD) in ((RLIMB_STRIP, 121, 128, ("rU", "rD")), (LLIMB_STRIP, 122, 64, ("lU", "lD"))):
        a = strip_img(tiedye(128 * S, 256 * S, seed))
        rib(a, 0, 80, 256, 91, (230, 70, 142, 255), dark=0.85)          # jogger cuffs
        d = ImageDraw.Draw(a)
        d.rectangle(P(0, 91, 256, 128), fill=(250, 248, 249, 255))      # white sneakers
        d.rectangle(P(0, 119, 256, 128), fill=(214, 212, 216, 255))
        for k in (0, 6):                                                # slanted double side stripe
            d.line(P(outer + 14 + k, 116, outer + 30 + k, 96), fill=PINK, width=int(2.6 * S))
        front = 192 if layout is RLIMB_STRIP else 0
        for k in range(3):
            y = 95 + k * 5
            d.line(P(front + 22, y, front + 42, y), fill=(236, 186, 212, 255), width=S)
        place_limb(tpl, a, layout)
        place_cap(tpl, capU, strip_img(tiedye(64 * S, 64 * S, seed + 7)))
        sole = Image.new("RGBA", (64 * S, 64 * S), (214, 212, 216, 255))
        ds = ImageDraw.Draw(sole)
        for y in range(5, 64, 7):
            ds.line(P(5, y, 59, y), fill=(190, 188, 194, 255), width=2 * S)
        place_cap(tpl, capD, sole)
    return tpl

# ================================================================ checks + previews
def check(img, name):
    a = np.asarray(img)
    assert img.size == (W, H), f"{name}: size {img.size}"
    inside = np.zeros((H, W), bool)
    for x, y, w, h in BOXES:
        inside[y:y + h, x:x + w] = True
    stray = (a[..., 3] > 8) & ~inside
    assert stray.sum() == 0, f"{name}: {stray.sum()} opaque px outside the template boxes"
    cover = {f"{x},{y}": round(float((a[y:y + h, x:x + w, 3] > 128).mean()), 2) for x, y, w, h in BOXES}
    return cover

def overlay(img, template_png):
    base = Image.open(os.path.join(HERE, template_png)).convert("RGBA")
    base.putalpha(110)
    out = Image.new("RGBA", (W, H), (255, 255, 255, 255))
    out.alpha_composite(base)
    out.alpha_composite(img)
    return out

def front_view(shirt, pants, back=False):
    """Flat R6-style mock: what the front (or back) of the avatar shows. Shirt is drawn over pants."""
    sk = (234, 192, 160, 255)
    c = Image.new("RGBA", (256, 256), (36, 30, 44, 255))
    def face(img, box):
        return img.crop((box[0], box[1], box[0] + box[2], box[1] + box[3]))
    tb = (427, 74, 128, 128) if back else (231, 74, 128, 128)
    torso = Image.new("RGBA", (128, 128), sk)
    torso.alpha_composite(face(pants, tb))
    torso.alpha_composite(face(shirt, tb))
    c.alpha_composite(torso, (64, 0))
    ra, la = ((85, 355, 64, 128), (440, 355, 64, 128)) if back else ((217, 355, 64, 128), (308, 355, 64, 128))
    for arm, x in ((ra, 0 if not back else 192), (la, 192 if not back else 0)):
        a = Image.new("RGBA", (64, 128), sk)
        a.alpha_composite(face(shirt, arm))
        c.alpha_composite(a, (x, 0))
    for leg, x in ((ra, 64 if not back else 128), (la, 128 if not back else 64)):
        l = Image.new("RGBA", (64, 128), sk)
        l.alpha_composite(face(pants, leg))
        c.alpha_composite(l, (x, 128))
    return c.resize((512, 512), Image.NEAREST)

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    looks = [("01_midnight_track", midnight_shirt, midnight_pants),
             ("02_frost", frost_shirt, frost_pants),
             ("03_sakura", sakura_shirt, sakura_pants)]
    sheet = Image.new("RGBA", (512 * 2, 512 * len(looks)), (20, 16, 24, 255))
    for i, (name, fs, fp) in enumerate(looks):
        shirt, pants = fs(), fp()
        for kind, img, tp in (("shirt", shirt, "Template-Shirts-R15.png"), ("pants", pants, "Template-Pants-R15.png")):
            cov = check(img, f"{name}_{kind}")
            path = os.path.join(OUT, f"MM_{name}_{kind}.png")
            img.save(path, optimize=True)
            overlay(img, tp).save(os.path.join(OUT, f"check_{name}_{kind}_on_template.png"))
            print(f"{os.path.basename(path)}  {os.path.getsize(path)//1024} KB  ok")
        sheet.alpha_composite(front_view(shirt, pants), (0, 512 * i))
        sheet.alpha_composite(front_view(shirt, pants, back=True), (512, 512 * i))
    sheet.save(os.path.join(OUT, "preview_front_back.png"))
    print("preview_front_back.png")
