# Preview sheet: v8 art with the background hue-shifted to candidate schemes + a matching logo, for the owner to pick a colour.
import colorsys, numpy as np
from PIL import Image, ImageDraw
art = Image.open('gymarc_v8_action_gpt.png').convert('RGB').resize((1024, 1024), Image.LANCZOS)
_h = np.asarray(art.convert('HSV'), float)
# shortcut: the character has no blue, so 'blue and saturated' = background + rim light; fine for a preview, not a final render
mask = 1 - (((_h[..., 0] > 125) & (_h[..., 0] < 200) & (_h[..., 1] > 70)).astype(float))[..., None]
logo_src = Image.open('../../icon_render_25nov/gymarc_logo_v10_blue_simple.png').convert('RGBA')
def shift(a, hue, keep_mask=None, sat=1.0):
    hsv = np.asarray(Image.fromarray(a).convert('HSV'), float)
    hsv[..., 0] = (hsv[..., 0] + hue) % 256; hsv[..., 1] = np.clip(hsv[..., 1]*sat, 0, 255)
    return np.asarray(Image.fromarray(hsv.astype('uint8'), 'HSV').convert('RGB'))
BLUE_H = 160  # PIL hue (0-255) of our royal blue
OPTS = [('Blue (now)', 0), ('Green', 85-BLUE_H), ('Red', 0-BLUE_H), ('Purple', 195-BLUE_H), ('Cyan / teal', 128-BLUE_H), ('Orange', 18-BLUE_H)]
a = np.asarray(art)
tiles = []
for name, d in OPTS:
    bg = shift(a, d)
    im = Image.fromarray((a*mask + bg*(1-mask)).astype('uint8')).convert('RGBA')
    lr = np.asarray(logo_src).copy(); lr[..., :3] = shift(lr[..., :3].copy(), d)
    lg = Image.fromarray(lr); w = int(1024*0.55); lg = lg.resize((w, int(lg.height*w/lg.width)), Image.LANCZOS)
    im.alpha_composite(lg, (22, 18)); tiles.append((name, im.convert('RGB')))
sheet = Image.new('RGB', (3*340+20, 2*380+20), (240, 240, 240)); dr = ImageDraw.Draw(sheet)
for i, (n, t) in enumerate(tiles):
    x, y = 20 + (i % 3)*340, 20 + (i//3)*380
    sheet.paste(t.resize((320, 320), Image.LANCZOS), (x, y)); sheet.paste(t.resize((60, 60), Image.LANCZOS), (x+260, y+325))
    dr.text((x, y+330), f'{i+1}. {n}', fill=(20, 20, 20))
sheet.save('colour_options_v8.png'); print('ok', mask.mean().round(2))
