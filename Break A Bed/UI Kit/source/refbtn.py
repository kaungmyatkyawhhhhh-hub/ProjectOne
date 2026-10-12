"""Button identical in style to the owner's 'Shop' reference."""
import sys, math
from PIL import Image, ImageDraw, ImageFilter, ImageChops
from kit import S, mix, vgrad
import pixtext

BLACK = (12, 2, 4)
BASES = {'red': (250, 46, 48), 'orange': (255, 128, 10), 'purple': (150, 60, 235), 'pink': (240, 40, 180),
         'green': (44, 185, 44), 'blue': (30, 115, 235), 'cyan': (15, 175, 235), 'yellow': (250, 190, 0),
         'light': (225, 230, 242)}

def lattice(size, cell, color, alpha, lw):
    lay = Image.new('RGBA', size, (0, 0, 0, 0)); d = ImageDraw.Draw(lay)
    w, h = size
    for k in range(-h, w + h, cell):
        d.line((k, 0, k + h, h), fill=color + (alpha,), width=lw)
        d.line((k, h, k + h, 0), fill=color + (alpha,), width=lw)
    return lay

def button(w, h, col):
    base = BASES[col]
    W, H = w * S, h * S
    ow = round(h * 0.058) * S
    lip = round(h * 0.055) * S
    img = Image.new('RGBA', (W, H), BLACK + (255,))
    face = (ow, ow, W - ow, H - ow - lip)
    img.paste(mix(base, (0, 0, 0), 0.5) + (255,), (ow, H - ow - lip, W - ow, H - ow))     # dark 3D bottom band
    fw, fh = face[2] - face[0], face[3] - face[1]
    g = vgrad((fw, fh), base, mix(base, (255, 255, 255), 0.80), int(fh * 0.12), fh)
    img.paste(g, (face[0], face[1]))
    top = Image.new('RGBA', (fw, fh), (0, 0, 0, 0))                           # slight darker band under the top outline
    ImageDraw.Draw(top).rectangle((0, 0, fw, int(fh * 0.06)), fill=mix(base, (0, 0, 0), 0.25) + (110,))
    img.alpha_composite(top.filter(ImageFilter.GaussianBlur(S * 1.5)), (face[0], face[1]))
    lat = lattice((fw, fh), int(h * 0.36 * S), (255, 255, 255), 40, max(1, int(S * h / 90)))
    img.alpha_composite(lat, (face[0], face[1]))
    hl = Image.new('RGBA', (fw, 2 * S), (255, 255, 255, 50))                  # thin light line above the bottom band
    img.alpha_composite(hl, (face[0], face[3] - 2 * S))
    return img.resize((w, h), Image.LANCZOS)

def basket(n, body=(232, 48, 82)):
    W = n * S
    im = Image.new('RGBA', (W, W), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    ol = (40, 18, 48); ow = int(W * 0.045)
    dark = mix(body, (0, 0, 0), 0.25); light = mix(body, (255, 255, 255), 0.25)
    # handle (light grey), drawn behind
    d.line([(W*0.36, W*0.46), (W*0.40, W*0.12), (W*0.80, W*0.20), (W*0.74, W*0.50)], fill=ol, width=int(ow*2.6), joint='curve')
    d.line([(W*0.36, W*0.46), (W*0.40, W*0.12), (W*0.80, W*0.20), (W*0.74, W*0.50)], fill=(205, 212, 225), width=int(ow*1.2), joint='curve')
    # box faces (isometric)
    top = [(W*0.10, W*0.42), (W*0.56, W*0.30), (W*0.94, W*0.44), (W*0.48, W*0.58)]
    front = [(W*0.10, W*0.42), (W*0.48, W*0.58), (W*0.46, W*0.94), (W*0.16, W*0.78)]
    side = [(W*0.48, W*0.58), (W*0.94, W*0.44), (W*0.86, W*0.80), (W*0.46, W*0.94)]
    d.polygon(top, fill=mix(body, (0, 0, 0), 0.45))
    d.polygon(front, fill=body); d.polygon(side, fill=dark)
    # weave
    for face, c in ((front, light), (side, body)):
        m = Image.new('L', (W, W), 0); ImageDraw.Draw(m).polygon(face, fill=255)
        wv = Image.new('RGBA', (W, W), (0, 0, 0, 0)); wd = ImageDraw.Draw(wv)
        step = W * 0.07
        for i in range(30):
            for j in range(30):
                if (i + j) % 2 == 0:
                    x, y = i * step, j * step
                    wd.rectangle((x, y, x + step * 0.55, y + step * 0.55), fill=c + (150,))
        wv.putalpha(ImageChops.multiply(wv.getchannel('A'), m)); im.alpha_composite(wv)
    for poly in (front, side):
        d.line(poly + [poly[0]], fill=ol, width=ow, joint='curve')
    d.line(top + [top[0]], fill=ol, width=ow, joint='curve')
    # rim highlight
    d.line([(W*0.12, W*0.44), (W*0.48, W*0.60), (W*0.92, W*0.46)], fill=light, width=int(ow*0.8))
    # handle front part over the rim
    d.line([(W*0.74, W*0.50), (W*0.80, W*0.20)], fill=ol, width=int(ow*2.6))
    d.line([(W*0.74, W*0.50), (W*0.80, W*0.20)], fill=(225, 230, 240), width=int(ow*1.2))
    return im.resize((n, n), Image.LANCZOS)

def full(col, ic, text, w=288, h=105):
    b = button(w, h, col)
    b.alpha_composite(ic, (int(h * 0.12), int((h - ic.height) / 2 - h * 0.03)))
    t = pixtext.render(text, height=h * 0.5)
    maxw = w - (h * 0.12 + ic.width + h * 0.08) - h * 0.1
    if t.width > maxw: t = pixtext.render(text, height=h * 0.5 * maxw / t.width)
    b.alpha_composite(t, (int(h * 0.12 + ic.width + h * 0.08), int((h - t.height) / 2 - h * 0.02)))
    return b

if __name__ == '__main__':
    mine = full('red', basket(70), 'Shop')
    ref = Image.open(sys.argv[1]).convert('RGBA')
    cmp_ = Image.new('RGBA', (288 * 2 + 30, 105), (40, 40, 50, 255))
    cmp_.alpha_composite(ref.resize((288, 105)), (0, 0)); cmp_.alpha_composite(mine, (318, 0))
    cmp_.resize((cmp_.width * 2, cmp_.height * 2), Image.LANCZOS).save('compare.png')
