# Same logo and gradient, only the tone changes: rotates the hue of the blue layers by <deg> (saturation/brightness kept).
# usage: python logo_tone.py <deg> <out.png>
import sys, numpy as np
from PIL import Image
deg, out = float(sys.argv[1]), sys.argv[2]
im = Image.open('gymarc_logo_v10_blue_simple.png').convert('RGBA'); a = np.asarray(im).copy()
hsv = np.asarray(im.convert('RGB').convert('HSV')).astype(int)
rgb = a[..., :3].astype(float)/255; mx, mn = rgb.max(-1), rgb.min(-1)
blue = (rgb[..., 2] > rgb[..., 0]) & ((mx-mn)/(mx+1e-6) > 0.15)
hsv[..., 0] = np.where(blue, (hsv[..., 0] + round(deg/360*256)) % 256, hsv[..., 0])
a[..., :3] = np.asarray(Image.fromarray(hsv.astype('uint8'), 'HSV').convert('RGB'))
assert blue.mean() > 0.05
Image.fromarray(a).save(out); print('saved', out)
