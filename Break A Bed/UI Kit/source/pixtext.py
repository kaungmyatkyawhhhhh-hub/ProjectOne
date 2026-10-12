"""Chunky pixel text like the owner's 'Shop' reference: Press Start 2P made bold by one font-pixel,
a hard-edged black outline one font-pixel wide, and a light grey bottom edge inside each letter."""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops
PFONT = os.path.join(os.path.dirname(__file__), '..', 'fonts', 'PressStart2P.ttf')
OUT = (22, 24, 34)

def render(s, unit=4, fill=(255, 255, 255), shade=None):
    f = ImageFont.truetype(PFONT, 16)             # 16 px = 2 px per font pixel
    w = int(f.getlength(s)) + 12
    m = Image.new('L', (w, 26), 0)
    ImageDraw.Draw(m).text((6, 5), s, font=f, fill=255)
    m = m.point(lambda v: 255 if v > 100 else 0)
    bold = Image.new('L', m.size, 0)            # thicken right and down by one font pixel
    for dx, dy in ((0, 0), (1, 0)):
        bold = ImageChops.lighter(bold, ImageChops.offset(m, dx, dy))
    outline = bold.filter(ImageFilter.MaxFilter(5))
    shade_m = ImageChops.subtract(bold, ImageChops.offset(bold, 0, -1))   # bottom row of each stroke
    shade = shade or tuple(int(c * 0.82) for c in fill)
    im = Image.new('RGBA', m.size, (0, 0, 0, 0))
    im.paste(OUT + (255,), (0, 0), outline)
    im.paste(fill + (255,), (0, 0), bold)
    im.paste(shade + (255,), (0, 0), shade_m)
    bb = im.getbbox()
    im = im.crop(bb)
    return im.resize((im.width * unit, im.height * unit), Image.NEAREST)

def put(img, xy, s, height, fill=(255, 255, 255), anchor='lm'):
    unit = max(1, round(height / 20))
    t = render(s, unit, fill)
    x, y = xy
    if anchor == 'mm': x -= t.width / 2
    elif anchor == 'rm': x -= t.width
    img.alpha_composite(t, (int(x), int(y - t.height / 2)))
    return t.width

if __name__ == '__main__':
    bg = Image.new('RGBA', (900, 200), (240, 70, 80, 255))
    put(bg, (40, 100), 'Shop', 70); put(bg, (420, 100), 'Gifts 1/4', 40)
    bg.convert('RGB').save('pixtext_test.png')
