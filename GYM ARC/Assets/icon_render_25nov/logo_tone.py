# Same logo and gradient, only the tone changes: rotates the hue of the blue layers by <deg> (saturation/brightness kept).
# Optional <light_sat>: the white highlight inside "ARC" becomes a very light blue of the same tone (owner: lightest colour
# should be "SUPER SUPER light blue", not white).
# usage: python logo_tone.py <deg> <out.png> [light_sat]
import sys, numpy as np
from PIL import Image
from scipy import ndimage
deg, out = float(sys.argv[1]), sys.argv[2]
light_sat = float(sys.argv[3]) if len(sys.argv) > 3 else 0
im = Image.open('gymarc_logo_v10_blue_simple.png').convert('RGBA'); a = np.asarray(im).copy()
hsv = np.asarray(im.convert('RGB').convert('HSV')).astype(float)
rgb = a[..., :3].astype(float)/255; al = a[..., 3]/255; mx, mn = rgb.max(-1), rgb.min(-1); sat = (mx-mn)/(mx+1e-6)
blue = (rgb[..., 2] > rgb[..., 0]) & (sat > 0.15)
hue = 192/360*256 + deg/360*256  # the original blue sits at ~192 deg
hsv[..., 0] = np.where(blue, (hsv[..., 0] + deg/360*256) % 256, hsv[..., 0])
if light_sat:
    dist = ndimage.distance_transform_edt(al > 0.5)
    inner = (dist > 8) & (mx >= 0.42); lab, n = ndimage.label(inner)
    inner &= ~np.isin(lab, [i for i in range(1, n+1) if dist[lab == i].min() < 20])  # drop the edge glow ring
    rows = np.nonzero(inner.any(1))[0]; prof = inner.sum(1); lo = rows.min() + (rows.max()-rows.min())//3
    mid = lo + int(np.argmin(prof[lo: rows.min() + 2*(rows.max()-rows.min())//3]))  # gap between GYM and ARC
    arc = ndimage.binary_dilation(inner, iterations=2); arc[:mid] = False
    light = arc & (mx > 0.7) & (sat < light_sat)
    hsv[..., 0] = np.where(light, hue % 256, hsv[..., 0]); hsv[..., 1] = np.where(light, light_sat*255, hsv[..., 1])
    assert light.sum() > 1000, 'no white highlight found in ARC'
a[..., :3] = np.asarray(Image.fromarray(hsv.clip(0, 255).astype('uint8'), 'HSV').convert('RGB'))
assert blue.mean() > 0.05
Image.fromarray(a).save(out); print('saved', out)
