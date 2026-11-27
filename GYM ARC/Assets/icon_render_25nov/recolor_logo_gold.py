# Turns the blue parts of the GYM ARC logo gold/orange (Power Lifters style: coloured word matches the hero prop, warm border pops on a blue icon).
import numpy as np, colorsys
from PIL import Image
im = np.asarray(Image.open('gymarc_logo_v10_blue_simple.png').convert('RGBA')).astype(float)/255
rgb = im[..., :3]; mx, mn = rgb.max(-1), rgb.min(-1); sat = (mx-mn)/(mx+1e-6)
r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
blue = (b > r) & (b >= g*0.9) & (sat > 0.25)
hsv = np.vectorize(colorsys.rgb_to_hsv)(r, g, b)
h = np.where(blue, 0.115 - 0.06*(1-hsv[2]), hsv[0])  # bright = gold, darker = deep orange, like a metal gradient
s = np.where(blue, np.clip(hsv[1]*1.05, 0, 1), hsv[1])
out = np.stack(np.vectorize(colorsys.hsv_to_rgb)(h, s, hsv[2]), -1)
Image.fromarray((np.dstack([out, im[..., 3]])*255).astype('uint8')).save('gymarc_logo_v11_gold.png')
assert blue.mean() > 0.05, 'no blue found to recolour'
print('blue px', round(blue.mean(), 3))
