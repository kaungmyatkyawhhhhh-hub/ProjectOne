# Power Lifters-style logo: white top word; second word shaded like their 400 KG plate (dark core, neon edges, pale edge highlight),
# thick neon border glow around the whole logo. Letter shapes come from gymarc_logo_v10_blue_simple.png.
# usage: python logo_clean_fill.py <name> <word2_top_hex> <word2_bottom_hex> <border_hex>
import sys, numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage
hx = lambda h: np.array([int(h[i:i+2], 16) for i in (0, 2, 4)], float)/255
name, c_top, c_bot, border = sys.argv[1], *map(hx, sys.argv[2:5])
a = np.asarray(Image.open('gymarc_logo_v10_blue_simple.png').convert('RGBA')).astype(float)/255
rgb, al = a[..., :3], a[..., 3]
mx, mn = rgb.max(-1), rgb.min(-1); sat = (mx-mn)/(mx+1e-6)
dist = ndimage.distance_transform_edt(al > 0.5)
inner = (dist > 8) & (mx >= 0.42)
lab, n = ndimage.label(inner)
ring = [i for i in range(1, n+1) if dist[lab == i].min() < 20]  # the old glow ring hugs the edge; letters start ~38 px in
inner &= ~np.isin(lab, ring)
# split the words by height (GYM on top, ARC below): colour-based split left the chrome highlight lines in ARC
rows = np.nonzero(inner.any(1))[0]; prof = inner.sum(1)
mid = rows.min() + (rows.max()-rows.min())//3 + int(np.argmin(prof[rows.min() + (rows.max()-rows.min())//3: rows.min() + 2*(rows.max()-rows.min())//3]))
letters = ndimage.binary_closing(inner, iterations=5) & (dist > 30)
gym = letters.copy(); gym[mid:] = False
arc = letters.copy(); arc[:mid] = False
H = a.shape[0]; yy = np.arange(H)[:, None]
def fade(mask, top, bot):
    ys = np.nonzero(mask)[0]; t = np.clip((yy - ys.min())/(ys.max() - ys.min() + 1e-6), 0, 1)[..., None]
    return top*(1-t) + bot*t
out = np.zeros_like(rgb); out[al > 0.02] = hx('0a0a12')  # black plate + outline
out = np.where(gym[..., None], fade(gym, hx('ffffff'), hx('d9dce6')), out)
# Power Lifters 400 KG plate look (owner's pick): vivid glossy colour, soft bright sheen streak across the upper part,
# deep shade at the bottom, neon edge glow and a pale edge line.
ys, xs = np.nonzero(arc); yy, xx = np.mgrid[:a.shape[0], :a.shape[1]]
ty = np.clip((yy - ys.min())/(ys.max() - ys.min() + 1e-6), 0, 1)[..., None]
tx = np.clip((xx - xs.min())/(xs.max() - xs.min() + 1e-6), 0, 1)[..., None]
light, mid, deep = np.clip(c_top*0.55 + 0.45, 0, 1), c_top, c_bot*0.55
ss = lambda e0, e1, x: np.clip((x - e0)/(e1 - e0), 0, 1)**2*(3 - 2*np.clip((x - e0)/(e1 - e0), 0, 1))
plate = light + (mid - light)*ss(0.0, 0.42, ty)
plate = plate + (deep - plate)*ss(0.5, 1.0, ty)
u = ty*0.85 - tx*0.15  # slightly diagonal sheen, like light hitting a curved plate from the top-left
plate = plate + (np.clip(c_top*0.25 + 0.75, 0, 1) - plate)*0.6*np.exp(-((u - 0.22)/0.06)**2)
de = ndimage.distance_transform_edt(arc)[..., None]
plate = plate + (np.clip(c_top*1.15, 0, 1) - plate)*0.45*np.exp(-de/6.0)
plate = np.where(de < 2.2, np.clip(c_top*0.35 + 0.65, 0, 1), plate)
out = np.where(arc[..., None], plate, out)
logo = Image.fromarray((np.dstack([out, al])*255).astype('uint8'))
pad = 40; W, Hh = logo.size; canvas = Image.new('RGBA', (W+2*pad, Hh+2*pad), (0, 0, 0, 0))
shape = Image.new('L', canvas.size, 0); shape.paste(Image.fromarray(((al > 0.3)*255).astype('uint8')), (pad, pad))
ring = shape.filter(ImageFilter.MaxFilter(13))
glow = Image.new('RGBA', canvas.size, tuple(int(c*255) for c in border) + (0,)); glow.putalpha(ring.filter(ImageFilter.GaussianBlur(9)))
solid = Image.new('RGBA', canvas.size, tuple(int(c*255) for c in border) + (0,)); solid.putalpha(shape.filter(ImageFilter.MaxFilter(9)))
canvas.alpha_composite(glow); canvas.alpha_composite(glow); canvas.alpha_composite(solid); canvas.alpha_composite(logo, (pad, pad))
assert arc.mean() > 0.05 and gym.mean() > 0.05, 'letter fills not found'
canvas.save(f'gymarc_logo_v13_{name}.png'); print('saved', name, round(arc.mean(), 3), round(gym.mean(), 3))
