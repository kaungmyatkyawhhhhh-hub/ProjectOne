# Recolours the GYM ARC logo's blue layers with a designed palette (not a hue shift):
# outer glow border, the bright "ARC" letter fill (vertical 2-stop gradient: light top -> deep bottom, plus its shading), the dark backing plate.
# usage: python recolor_logo_palette.py <name> <border_hex> <fill_dark_hex> <fill_light_hex> <plate_hex>
import sys, numpy as np
from PIL import Image
from scipy import ndimage
hx = lambda h: np.array([int(h[i:i+2], 16) for i in (0, 2, 4)], float)/255
name, border, f0, f1, plate = sys.argv[1], *map(hx, sys.argv[2:6])
a = np.asarray(Image.open('gymarc_logo_v10_blue_simple.png').convert('RGBA')).astype(float)/255
rgb, al = a[..., :3], a[..., 3]
mx, mn = rgb.max(-1), rgb.min(-1); sat = (mx-mn)/(mx+1e-6)
blue = (rgb[..., 2] > rgb[..., 0]) & (sat > 0.25)
dist = ndimage.distance_transform_edt(al > 0.5)
v = mx[..., None]
out = rgb.copy()
m_border = blue & (dist <= 8)
m_fill = blue & (dist > 8) & (mx >= 0.45)
m_plate = blue & (dist > 8) & (mx < 0.45)
lo, hi = v[m_fill].min(), v[m_fill].max()
ys = np.nonzero(m_fill)[0]; yy = np.arange(a.shape[0])[:, None, None]
y_t = np.clip((ys.max() - yy)/(ys.max() - ys.min() + 1e-6), 0, 1)  # 1 at top of ARC, 0 at bottom, like the Power Lifters word gradient
t = np.clip(0.65*y_t + 0.35*np.clip((v - lo)/(hi - lo + 1e-6), 0, 1), 0, 1)**1.3
out = np.where(m_fill[..., None], f0*(1-t) + f1*t, out)
out = np.where(m_border[..., None], border*np.clip(v*1.15, 0, 1), out)
out = np.where(m_plate[..., None], plate*np.clip(v/0.45, 0.3, 1), out)
assert m_fill.mean() > 0.05 and m_border.mean() > 0.01, 'logo layers not found'
Image.fromarray((np.dstack([out, al])*255).astype('uint8')).save(f'gymarc_logo_v12_{name}.png'); print('saved', name)
