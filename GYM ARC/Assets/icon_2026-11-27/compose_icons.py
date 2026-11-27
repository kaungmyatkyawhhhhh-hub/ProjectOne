# Adds the GYM ARC logo to the Gemini icon art and makes a small-size test sheet next to real competitor icons.
from PIL import Image, ImageDraw, ImageFilter
import numpy as np, sys
LOGO = Image.open('../icon_render_25nov/gymarc_logo_v10_blue_simple.png').convert('RGBA')
SHOT = r'C:/Users/kaung/AppData/Local/Temp/claude/c29817fd9653d23b/10817e82-c703-454d-ac35-8c0300f85304/images/6.png'

def compose(src, out, frac=0.66, left=None):
    im = Image.open(src).convert('RGBA').resize((1024, 1024), Image.LANCZOS)
    # dark fade under the logo so it reads on any art
    fade = Image.new('L', (1024, 1024), 0)
    a = np.zeros((1024, 1024), np.uint8)
    for y in range(700, 1024):
        a[y, :] = int(170 * ((y - 700) / 324) ** 1.4)
    shade = Image.new('RGBA', (1024, 1024), (4, 8, 24, 255)); shade.putalpha(Image.fromarray(a))
    im = Image.alpha_composite(im, shade)
    w = int(1024 * frac); h = int(LOGO.height * w / LOGO.width)
    lg = LOGO.resize((w, h), Image.LANCZOS)
    x = (1024 - w) // 2 if left is None else left; y = 1024 - h - int(1024 * 0.07)
    im.alpha_composite(lg, (x, y))
    im.convert('RGB').save(out)
    return im.convert('RGB')

def stats(im):
    s = np.asarray(im.resize((64, 64), Image.LANCZOS)).astype(float) / 255
    lum = 0.2126 * s[..., 0] + 0.7152 * s[..., 1] + 0.0722 * s[..., 2]
    sat = s.max(-1) - s.min(-1)
    return dict(white=round(((lum > 215/255) & (sat < 0.25)).mean() * 100, 1), dark=round((lum < 45/255).mean() * 100, 1), mean=round(lum.mean(), 2))

# the small kid's face sits low in the centre: the logo goes bottom-left, smaller
n = compose('gymarc_icon_normal_final_art.png', 'gymarc_icon_normal_logo.png', 0.44, 40)
x = compose('gymarc_icon_xmas_final_art.png', 'gymarc_icon_xmas_logo.png', 0.44, 40)
assert n.size == (1024, 1024) and x.size == (1024, 1024)
shot = Image.open(SHOT).convert('RGB')
comp = {'old GYM ARC': (346, 86), 'Arm Wrestle': (686, 86), 'Pet Sim': (1027, 86), 'Power Lifters': (1538, 86), 'Grow a Garden': (1197, 86)}
tiles = [('NEW normal', n), ('NEW christmas', x)] + [(k, shot.crop((a, b, a + 146, b + 146))) for k, (a, b) in comp.items()]
sheet = Image.new('RGB', (len(tiles) * 170 + 20, 360), (245, 245, 245)); d = ImageDraw.Draw(sheet)
for i, (name, t) in enumerate(tiles):
    sheet.paste(t.resize((150, 150), Image.LANCZOS), (20 + i * 170, 20))
    sheet.paste(t.resize((100, 100), Image.LANCZOS), (20 + i * 170, 185))
    sheet.paste(t.resize((60, 60), Image.LANCZOS), (125 + i * 170 - 0, 225))
    d.text((20 + i * 170, 330), name, fill=(20, 20, 20))
sheet.save('icon_size_test.png')
for name, t in tiles[:3]: print(name, stats(t))
