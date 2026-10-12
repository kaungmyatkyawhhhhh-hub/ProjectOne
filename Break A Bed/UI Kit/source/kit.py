import math, os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops

S = 4  # supersample
OUTLINE = (26, 20, 40)
FONT = os.path.join(os.path.dirname(__file__), '..', 'fonts', 'Fredoka.ttf')

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

def studs(size, cell, color, alpha, lw):
    lay = Image.new('RGBA', size, (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    w, h = size
    s = cell * 0.62
    off = (cell - s) / 2
    for gy in range(-1, h // cell + 2):
        for gx in range(-1, w // cell + 2):
            x, y = gx * cell + off, gy * cell + off
            d.rounded_rectangle((x, y, x + s, y + s), s * 0.22, outline=color + (alpha,), width=lw)
    return lay

def box(w, h, col, radius=None, outline=None, lip=None, pattern=True, cell=None):
    """A chunky 3D box: dark outline, darker bottom lip, gradient face, stud pattern, top gloss."""
    top, bot = COLORS[col] if isinstance(col, str) else col
    W, H = w * S, h * S
    radius = (radius if radius is not None else min(w, h) * 0.2) * S
    ow = (outline if outline is not None else max(4, round(min(w, h) * 0.06))) * S
    lp = (lip if lip is not None else max(5, round(min(w, h) * 0.09))) * S
    cell = (cell or 30) * S
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    img.paste(OUTLINE + (255,), (0, 0, W, H), mask_rr((W, H), (0, 0, W - 1, H - 1), radius))
    inner = (ow, ow, W - 1 - ow, H - 1 - ow)
    ir = max(1, radius - ow)
    img.paste(mix(bot, (0, 0, 0), 0.38) + (255,), (0, 0, W, H), mask_rr((W, H), inner, ir))
    face = (ow, ow, W - 1 - ow, H - 1 - ow - lp)
    fm = mask_rr((W, H), face, ir)
    grad = vgrad((W, H), top, bot, face[1], face[3])
    img.paste(grad, (0, 0), fm)
    if pattern:
        st = studs((W, H), cell, (255, 255, 255), 46, max(2, S * 2))
        a = ImageChops.multiply(st.getchannel('A'), fm)
        st.putalpha(a)
        img.alpha_composite(st)
    # top gloss
    gl = Image.new('L', (W, H), 0)
    gd = ImageDraw.Draw(gl)
    gh = min(S * 6, max(S * 3, int((face[3] - face[1]) * 0.07)))
    gd.rounded_rectangle((face[0] + ir * 0.5, face[1] + gh * 0.6, face[2] - ir * 0.5, face[1] + gh * 1.8), gh, fill=120)
    gl = ImageChops.multiply(gl, fm)
    img.alpha_composite(Image.merge('RGBA', [Image.new('L', (W, H), 255)] * 3 + [gl]))
    # thin inner dark rim on face edge for definition
    rim = Image.new('L', (W, H), 0)
    ImageDraw.Draw(rim).rounded_rectangle(face, ir, outline=70, width=max(1, S * 2))
    img.alpha_composite(Image.merge('RGBA', [Image.new('L', (W, H), 0)] * 3 + [rim]))
    return img.resize((w, h), Image.LANCZOS)

def x_mark(img, color=(255, 255, 255)):
    w, h = img.size
    W, H = w * S, h * S
    lay = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    c = (W / 2, H * 0.46)
    r = W * 0.2
    for lw, col in ((int(W * 0.2), OUTLINE), (int(W * 0.11), color)):
        d.line((c[0] - r, c[1] - r, c[0] + r, c[1] + r), fill=col + (255,), width=lw)
        d.line((c[0] - r, c[1] + r, c[0] + r, c[1] - r), fill=col + (255,), width=lw)
        for p in ((c[0]-r, c[1]-r), (c[0]+r, c[1]+r), (c[0]-r, c[1]+r), (c[0]+r, c[1]-r)):
            d.ellipse((p[0]-lw/2, p[1]-lw/2, p[0]+lw/2, p[1]+lw/2), fill=col + (255,))
    img.alpha_composite(lay.resize((w, h), Image.LANCZOS))
    return img

def stud_tile(n=64):
    t = studs((n * S, n * S), n * S // 2, (255, 255, 255), 60, S * 2)
    return t.resize((n, n), Image.LANCZOS)

if __name__ == '__main__':
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for c in COLORS:
        box(400, 108, c, cell=28).save(f'{out}/btn-{c}.png')
        box(160, 160, c, radius=34, cell=28).save(f'{out}/btn-square-{c}.png')
    box(320, 86, 'green', cell=24).save(f'{out}/price-green.png')
    x_mark(box(120, 120, 'red', radius=24, cell=24)).save(f'{out}/close-red.png')
    box(1100, 760, 'blue', radius=40, outline=9, lip=14, cell=34).save(f'{out}/panel-window.png')
    box(820, 120, 'cyan', radius=30, outline=8, lip=10, cell=34).save(f'{out}/panel-header.png')
    box(960, 300, 'yellow', radius=34, outline=8, lip=12, cell=34).save(f'{out}/card-yellow.png')
    box(300, 330, 'cyan', radius=30, outline=7, lip=11, cell=30).save(f'{out}/card-cyan.png')
    stud_tile().save(f'{out}/pattern-studs.png')
    print('done')
