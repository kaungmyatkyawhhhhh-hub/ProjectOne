import math, os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops

S = 4  # supersample
OUTLINE = (26, 20, 40)
FONT = os.path.join(os.path.dirname(__file__), '..', 'fonts', 'Montserrat-Black.ttf')

# (top, bottom) face colours
COLORS = {
    'pink':   ((255, 105, 250), (205, 30, 215)),
    'purple': ((185, 120, 255), (120, 55, 230)),
    'cyan':   ((110, 235, 255), (25, 175, 245)),
    'blue':   ((90, 190, 255),  (25, 120, 235)),
    'orange': ((255, 200, 60),  (255, 125, 15)),
    'green':  ((140, 240, 80),  (40, 175, 40)),
    'red':    ((255, 110, 100), (215, 35, 45)),
    'yellow': ((255, 240, 90),  (255, 195, 10)),
    'slate':  ((92, 104, 128),  (58, 66, 86)),
}

def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

def mask_rr(size, box, r):
    m = Image.new('L', size, 0)
    ImageDraw.Draw(m).rounded_rectangle(box, r, fill=255)
    return m

def vgrad(size, top, bottom, y0, y1):
    w, h = size
    g = Image.new('RGB', (1, h))
    for y in range(h):
        t = min(1, max(0, (y - y0) / max(1, y1 - y0)))
        g.putpixel((0, y), mix(top, bottom, t))
    return g.resize((w, h))

def studs(size, cell, light=28, dark=26):
    """Small square studs: a lighter square with a darker bottom/right edge."""
    lay = Image.new('RGBA', size, (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    w, h = size
    s = cell * 0.56
    off = (cell - s) / 2
    e = max(1, cell * 0.09)
    for gy in range(-1, h // cell + 2):
        for gx in range(-1, w // cell + 2):
            x, y = gx * cell + off, gy * cell + off
            d.rectangle((x + e, y + e, x + s + e, y + s + e), fill=(0, 0, 0, dark))
            d.rectangle((x, y, x + s, y + s), fill=(255, 255, 255, light))
    return lay

def box(w, h, col, radius=None, outline=None, lip=None, pattern=True, cell=None, split=True):
    """Sharp chunky box: dark outline, light bevel, darker bottom lip, gradient face, square studs."""
    top, bot = COLORS[col] if isinstance(col, str) else col
    W, H = w * S, h * S
    radius = (radius if radius is not None else max(4, min(w, h) * 0.07)) * S
    ow = (outline if outline is not None else max(3, round(min(w, h) * 0.045))) * S
    lp = (lip if lip is not None else max(4, round(min(w, h) * 0.07))) * S
    cell = (cell or 16) * S
    bev = max(S * 2, int(ow * 0.6))
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    img.paste(OUTLINE + (255,), (0, 0, W, H), mask_rr((W, H), (0, 0, W - 1, H - 1), radius))
    inner = (ow, ow, W - 1 - ow, H - 1 - ow)
    ir = max(1, radius - ow)
    img.paste(mix(bot, (0, 0, 0), 0.35) + (255,), (0, 0, W, H), mask_rr((W, H), inner, ir))
    # light bevel ring around the face
    face_o = (ow, ow, W - 1 - ow, H - 1 - ow - lp)
    img.paste(mix(top, (255, 255, 255), 0.45) + (255,), (0, 0, W, H), mask_rr((W, H), face_o, ir))
    face = (face_o[0] + bev, face_o[1] + bev, face_o[2] - bev, face_o[3] - bev)
    fr = max(1, ir - bev)
    fm = mask_rr((W, H), face, fr)
    img.paste(vgrad((W, H), top, bot, face[1], face[3]), (0, 0), fm)
    if split:  # lighter top half, the classic simulator two-tone
        sp = Image.new('L', (W, H), 0)
        ImageDraw.Draw(sp).rectangle((0, 0, W, face[1] + (face[3] - face[1]) * 0.46), fill=34)
        sp = ImageChops.multiply(sp, fm)
        img.alpha_composite(Image.merge('RGBA', [Image.new('L', (W, H), 255)] * 3 + [sp]))
    if pattern:
        st = studs((W, H), cell)
        st.putalpha(ImageChops.multiply(st.getchannel('A'), fm))
        img.alpha_composite(st)
    return img.resize((w, h), Image.LANCZOS)

def x_mark(img, color=(255, 255, 255)):
    w, h = img.size
    W, H = w * S, h * S
    lay = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    f = ImageFont.truetype(FONT, int(H * 0.62))
    c = (W / 2, H * 0.45)
    sw = int(H * 0.07)
    d.text((c[0], c[1] + H * 0.04), 'X', font=f, anchor='mm', fill=OUTLINE, stroke_width=sw, stroke_fill=OUTLINE)
    d.text(c, 'X', font=f, anchor='mm', fill=color, stroke_width=sw, stroke_fill=OUTLINE)
    img.alpha_composite(lay.resize((w, h), Image.LANCZOS))
    return img

def stud_tile(n=64):
    t = studs((n * S, n * S), n * S // 4, 70, 60)
    return t.resize((n, n), Image.LANCZOS)

if __name__ == '__main__':
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for c in COLORS:
        box(400, 108, c).save(f'{out}/btn-{c}.png')
        box(160, 160, c).save(f'{out}/btn-square-{c}.png')
    box(320, 86, 'green').save(f'{out}/price-green.png')
    x_mark(box(120, 120, 'red')).save(f'{out}/close-red.png')
    box(1100, 760, 'slate', radius=10, outline=8, lip=10, cell=20).save(f'{out}/panel-window.png')
    box(1100, 130, 'cyan', radius=8, outline=7, lip=8, cell=18).save(f'{out}/panel-header.png')
    box(960, 300, 'yellow', radius=8, outline=6, lip=8, cell=18).save(f'{out}/card-yellow.png')
    box(300, 330, 'cyan', radius=8, outline=6, lip=8, cell=18).save(f'{out}/card-cyan.png')
    stud_tile().save(f'{out}/pattern-studs.png')
    print('done')
