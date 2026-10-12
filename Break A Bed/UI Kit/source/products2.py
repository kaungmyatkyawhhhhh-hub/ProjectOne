import sys, os, math
from PIL import Image, ImageDraw
from kit import box, label, OUTLINE, S, mix
import products as P

def _c(n):
    W = n * S
    im = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im), W, int(W * 0.045)

def crown(n):
    im, d, W, ow = _c(n)
    pts = [(0.12,0.78),(0.12,0.34),(0.32,0.55),(0.5,0.22),(0.68,0.55),(0.88,0.34),(0.88,0.78)]
    pts = [(x*W, y*W) for x, y in pts]
    d.polygon(pts, fill=(255, 205, 40), outline=OUTLINE, width=ow)
    d.rectangle((W*0.12, W*0.68, W*0.88, W*0.78), fill=(255, 170, 20), outline=OUTLINE, width=ow)
    for x, y in ((0.12,0.32),(0.5,0.2),(0.88,0.32)):
        r = W*0.06; d.ellipse((W*x-r, W*y-r, W*x+r, W*y+r), fill=(255, 240, 150), outline=OUTLINE, width=ow)
    for x, col in ((0.32,(230,50,70)),(0.5,(60,170,255)),(0.68,(80,210,90))):
        r = W*0.045; d.ellipse((W*x-r, W*0.6-r, W*x+r, W*0.6+r), fill=col, outline=OUTLINE, width=int(ow*0.7))
    return im.resize((n, n), Image.LANCZOS)

def bag(n):
    im, d, W, ow = _c(n)
    d.ellipse((W*0.14, W*0.32, W*0.86, W*0.92), fill=(110, 200, 80), outline=OUTLINE, width=ow)
    d.polygon([(W*0.36,W*0.36),(W*0.30,W*0.12),(W*0.5,W*0.2),(W*0.70,W*0.12),(W*0.64,W*0.36)], fill=(110,200,80), outline=OUTLINE, width=ow)
    d.rectangle((W*0.34, W*0.30, W*0.66, W*0.38), fill=(200, 140, 60), outline=OUTLINE, width=ow)
    d.text((W*0.5, W*0.64), '$', font=P.ImageFont.truetype(P.FONT, int(W*0.34)), anchor='mm', fill=(255,255,255), stroke_width=ow, stroke_fill=OUTLINE)
    return im.resize((n, n), Image.LANCZOS)

def vault(n):
    im, d, W, ow = _c(n)
    d.rounded_rectangle((W*0.1, W*0.12, W*0.9, W*0.86), W*0.06, fill=(120, 130, 150), outline=OUTLINE, width=ow)
    d.rounded_rectangle((W*0.18, W*0.2, W*0.82, W*0.78), W*0.04, fill=(160, 170, 190), outline=OUTLINE, width=ow)
    c, r = (W*0.5, W*0.49), W*0.2
    d.ellipse((c[0]-r, c[1]-r, c[0]+r, c[1]+r), fill=(255, 205, 40), outline=OUTLINE, width=ow)
    for i in range(4):
        a = math.radians(45 + i*90)
        d.line((c[0], c[1], c[0]+r*0.85*math.cos(a), c[1]+r*0.85*math.sin(a)), fill=OUTLINE, width=ow)
    r2 = W*0.06; d.ellipse((c[0]-r2, c[1]-r2, c[0]+r2, c[1]+r2), fill=(255,240,150), outline=OUTLINE, width=ow)
    for x in (0.22, 0.7):
        d.rectangle((W*x, W*0.86, W*(x+0.08), W*0.93), fill=OUTLINE)
    return im.resize((n, n), Image.LANCZOS)

def shoe(n):
    im, d, W, ow = _c(n)
    pts = [(0.1,0.72),(0.12,0.46),(0.3,0.42),(0.42,0.26),(0.58,0.3),(0.62,0.5),(0.86,0.58),(0.92,0.72)]
    pts = [(x*W, y*W) for x, y in pts]
    d.polygon(pts, fill=(60, 170, 255), outline=OUTLINE, width=ow)
    d.rounded_rectangle((W*0.08, W*0.68, W*0.94, W*0.8), W*0.04, fill=(255,255,255), outline=OUTLINE, width=ow)
    for i in range(3):
        y = W*(0.5 + i*0.08); d.line((W*0.0, y, W*0.08 - i*W*0.02, y), fill=(255,255,255), width=ow)
    d.line((W*0.36, W*0.42, W*0.52, W*0.4), fill=(255,255,255), width=int(ow*0.8))
    d.line((W*0.34, W*0.5, W*0.54, W*0.48), fill=(255,255,255), width=int(ow*0.8))
    return im.resize((n, n), Image.LANCZOS)

def bed(n):
    im, d, W, ow = _c(n)
    d.rectangle((W*0.1, W*0.3, W*0.2, W*0.85), fill=(170, 110, 60), outline=OUTLINE, width=ow)
    d.rectangle((W*0.1, W*0.55, W*0.9, W*0.72), fill=(190, 125, 70), outline=OUTLINE, width=ow)
    d.rectangle((W*0.8, W*0.72, W*0.9, W*0.85), fill=(170, 110, 60), outline=OUTLINE, width=ow)
    d.rectangle((W*0.2, W*0.44, W*0.88, W*0.56), fill=(255, 255, 255), outline=OUTLINE, width=ow)
    d.rectangle((W*0.42, W*0.42, W*0.88, W*0.56), fill=(60, 140, 240), outline=OUTLINE, width=ow)
    d.rounded_rectangle((W*0.22, W*0.36, W*0.38, W*0.48), W*0.04, fill=(255,255,255), outline=OUTLINE, width=ow)
    d.line([(W*0.55, W*0.3), (W*0.5, W*0.48), (W*0.6, W*0.6), (W*0.54, W*0.78)], fill=OUTLINE, width=int(ow*1.6), joint='curve')
    d.line([(W*0.55, W*0.3), (W*0.5, W*0.48), (W*0.6, W*0.6), (W*0.54, W*0.78)], fill=(255, 226, 12), width=int(ow*0.7), joint='curve')
    return im.resize((n, n), Image.LANCZOS)

from settings import gear
EXTRA = dict(crown=crown, bag=bag, vault=vault, shoe=shoe, bed=bed, gear=gear)
_old_ic = P.ic
P.ic = lambda kind, n: EXTRA[kind](n) if kind in EXTRA else _old_ic(kind, n)

def make(ribbon_col=None, **kw):
    if ribbon_col:
        orig = P.box
        def patched(w, h, col, *a, **k):
            if (w, h) == (300, 70): col = ribbon_col
            return orig(w, h, col, *a, **k)
        P.box = patched
        try: return P.make(**kw)
        finally: P.box = orig
    return P.make(**kw)

G = 'green'
PRODUCTS = [
    ('plus1-level', dict(bg='yellow', kind='star', big='+1', small='LEVEL', bigcol=(255,255,255))),
    ('plus3-levels', dict(bg='yellow', kind='star', big='+3', small='LEVELS', bigcol=(255,255,255))),
    ('plus9-levels', dict(bg='orange', kind='star', big='+9', small='LEVELS')),
    ('x2-strength-10min', dict(bg='purple', kind='dumbbell', big='x2', small='10 MIN')),
    ('x2-cash-10min', dict(bg='green', kind='cash', big='x2', small='10 MIN')),
    ('plus3-spins', dict(bg='pink', kind='wheel', big='+3', small='SPINS')),
    ('plus10-spins', dict(bg='purple', kind='wheel', big='+10', small='SPINS')),
    ('cash-pile', dict(bg='green', kind='cash', small='CASH PILE')),
    ('cash-bag', dict(bg='cyan', kind='bag', small='CASH BAG')),
    ('cash-vault', dict(bg='slate', kind='vault', small='CASH VAULT')),
]
PASSES = [(f'pass-{m}x-strength', dict(bg=c, kind='dumbbell', big=f'{m}x', small='FOREVER'))
          for m, c in ((2,'cyan'),(3,'blue'),(5,'purple'),(7,'pink'),(10,'orange'),(15,'red'))] + [
    ('pass-vip', dict(bg='yellow', kind='crown', big='VIP', small='FOREVER', bigcol=(255,255,255))),
    ('pass-fast-walk', dict(bg='cyan', kind='shoe', big='SPEED', small='FOREVER')),
    ('pass-break-spam', dict(bg='red', kind='bed', big='SPAM', small='FOREVER')),
    ('pass-x2-cash', dict(bg='green', kind='cash', big='x2', small='FOREVER')),
    ('pass-auto-punch', dict(bg='blue', kind='gear', big='AUTO', small='FOREVER')),
]

if __name__ == '__main__':
    out = sys.argv[1]; os.makedirs(out, exist_ok=True)
    for group, items, sheetname in (('p', PRODUCTS, '_old-products.png'), ('g', PASSES, '_game-passes.png')):
        tiles = []
        for name, kw in items:
            rc = G if kw.get('small') == 'FOREVER' else None
            im = make(ribbon_col=rc, **kw); im.save(f'{out}/{name}.png'); tiles.append(im)
        cols = 6 if len(tiles) > 10 else 5
        rows = math.ceil(len(tiles) / cols)
        sheet = Image.new('RGBA', (cols * 270 + 10, rows * 270 + 10), (24, 26, 34, 255))
        for i, t in enumerate(tiles):
            sheet.alpha_composite(t.resize((256, 256), Image.LANCZOS), (10 + (i % cols) * 270, 10 + (i // cols) * 270))
        sheet.convert('RGB').save(f'{out}/{sheetname}')
    print('ok')
