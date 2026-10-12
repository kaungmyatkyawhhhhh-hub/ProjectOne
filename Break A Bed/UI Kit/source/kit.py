"""Break A Bed UI kit: chunky square-cornered Roblox simulator style (matches the owner's reference)."""
import os, sys
from PIL import Image, ImageDraw, ImageFont, ImageChops

S = 4  # supersample
OUTLINE = (22, 24, 34)          # stroke colour on everything  #161822
FONT = os.path.join(os.path.dirname(__file__), '..', 'fonts', 'Montserrat-Black.ttf')

# base colour of each element
COLORS = {
    'cyan':   (28, 200, 242),
    'blue':   (36, 122, 222),
    'pink':   (236, 34, 205),
    'purple': (150, 72, 232),
    'orange': (255, 148, 22),
    'green':  (84, 202, 52),
    'red':    (226, 54, 60),
    'yellow': (255, 226, 12),
    'slate':  (62, 68, 84),
}
STYLE = dict(
    radius=0.035,       # corner radius, fraction of the short side (nearly square)
    outline=0.045,      # dark stroke, fraction of the short side
    rim=0.032,          # light inner rim
    rim_mix=0.45,       # rim = base mixed with white
    lip=0.065,          # darker 3D bottom edge
    lip_mix=0.30,       # lip = base mixed with black
    top_mix=0.16,       # face top = base mixed with white
    bot_mix=0.06,       # face bottom = base mixed with black
    stud_cell=14,       # pattern cell in px
    stud_light=24,      # pattern alpha (0-255): very faint
    stud_dark=26,
)
WINDOW = dict(color=(36, 40, 52), alpha=150, outline=OUTLINE)  # see-through dark window body

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

def studs(size, cell, light, dark):
    lay = Image.new('RGBA', size, (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    w, h = size
    s = cell * 0.58
    off = (cell - s) / 2
    e = max(1, cell * 0.08)
    for gy in range(-1, h // cell + 2):
        for gx in range(-1, w // cell + 2):
            x, y = gx * cell + off, gy * cell + off
            d.rectangle((x + e, y + e, x + s + e, y + s + e), fill=(0, 0, 0, dark))
            d.rectangle((x, y, x + s, y + s), fill=(255, 255, 255, light))
    return lay

def box(w, h, col, pattern=True, **kw):
    st = dict(STYLE, **kw)
    base = COLORS[col] if isinstance(col, str) else col
    W, H = w * S, h * S
    m = min(w, h)
    rad = max(2, m * st['radius']) * S
    ow = max(3, round(m * st['outline'])) * S
    rim = max(2, round(m * st['rim'])) * S
    lp = max(3, round(m * st['lip'])) * S
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    img.paste(OUTLINE + (255,), (0, 0, W, H), mask_rr((W, H), (0, 0, W - 1, H - 1), rad))
    ir = max(1, rad - ow)
    inner = (ow, ow, W - 1 - ow, H - 1 - ow)
    img.paste(mix(base, (0, 0, 0), st['lip_mix']) + (255,), (0, 0, W, H), mask_rr((W, H), inner, ir))
    rimbox = (ow, ow, W - 1 - ow, H - 1 - ow - lp)
    img.paste(mix(base, (255, 255, 255), st['rim_mix']) + (255,), (0, 0, W, H), mask_rr((W, H), rimbox, ir))
    face = (rimbox[0] + rim, rimbox[1] + rim, rimbox[2] - rim, rimbox[3] - rim)
    fm = mask_rr((W, H), face, max(1, ir - rim))
    img.paste(vgrad((W, H), mix(base, (255, 255, 255), st['top_mix']), mix(base, (0, 0, 0), st['bot_mix']), face[1], face[3]), (0, 0), fm)
    if pattern:
        p = studs((W, H), st['stud_cell'] * S, st['stud_light'], st['stud_dark'])
        p.putalpha(ImageChops.multiply(p.getchannel('A'), fm))
        img.alpha_composite(p)
    return img.resize((w, h), Image.LANCZOS)

def window(w, h):
    """See-through dark window body with the dark stroke."""
    W, H = w * S, h * S
    ow = max(3, round(min(w, h) * 0.008)) * S
    rad = 3 * S
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    img.paste(WINDOW['outline'] + (255,), (0, 0, W, H), mask_rr((W, H), (0, 0, W - 1, H - 1), rad))
    hole = mask_rr((W, H), (ow, ow, W - 1 - ow, H - 1 - ow), rad)
    body = Image.new('RGBA', (W, H), WINDOW['color'] + (WINDOW['alpha'],))
    img.paste((0, 0, 0, 0), (0, 0, W, H), hole)
    img.paste(body, (0, 0), hole)
    return img.resize((w, h), Image.LANCZOS)

def label(img, c, s, size, fill=(255, 255, 255), anchor='mm', rot=0):
    """Heavy white text, dark stroke and a dark drop shadow (as in the reference)."""
    f = ImageFont.truetype(FONT, size * S)
    sw = max(2, round(size * 0.12)) * S
    sh = max(2, round(size * 0.07)) * S
    tmp = Image.new('RGBA', (int(len(s) * size * 1.1 * S + 60 * S), size * 2 * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(tmp)
    cx, cy = tmp.width / 2, tmp.height / 2
    d.text((cx, cy + sh), s, font=f, anchor='mm', fill=OUTLINE, stroke_width=sw, stroke_fill=OUTLINE)
    d.text((cx, cy), s, font=f, anchor='mm', fill=fill, stroke_width=sw, stroke_fill=OUTLINE)
    t = tmp.resize((tmp.width // S, tmp.height // S), Image.LANCZOS)
    if rot: t = t.rotate(rot, Image.BICUBIC, expand=True)
    x, y = c[0] - t.width / 2, c[1] - t.height / 2
    if anchor == 'lm':
        x += (f.getlength(s) + 2 * sw) / S / 2
    img.alpha_composite(t, (int(x), int(y)))

def x_mark(img):
    w, h = img.size
    label(img, (w / 2, h * 0.44), 'X', int(h * 0.56))
    return img

def stud_tile(n=56):
    t = studs((n * S, n * S), n * S // 4, 60, 60)
    return t.resize((n, n), Image.LANCZOS)

if __name__ == '__main__':
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for c in COLORS:
        box(400, 108, c).save(f'{out}/btn-{c}.png')
        box(160, 160, c).save(f'{out}/btn-square-{c}.png')
    box(320, 86, 'green').save(f'{out}/price-green.png')
    x_mark(box(120, 120, 'red')).save(f'{out}/close-red.png')
    window(1100, 780).save(f'{out}/panel-window.png')
    box(1100, 130, 'cyan').save(f'{out}/panel-header.png')
    box(1040, 320, 'yellow').save(f'{out}/card-yellow.png')
    box(320, 360, 'cyan').save(f'{out}/card-cyan.png')
    stud_tile().save(f'{out}/pattern-studs.png')
    print('done')
