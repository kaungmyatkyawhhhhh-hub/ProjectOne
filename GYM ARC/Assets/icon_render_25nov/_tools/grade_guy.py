# GYM ARC icon (25 Nov): more contrast + a little more definition on the character only (orange skin + hair mask).
import sys, numpy as np
from PIL import Image, ImageFilter
src, out = sys.argv[1], sys.argv[2]
im = Image.open(src).convert("RGB"); N = im.size[0]
a = np.asarray(im).astype(np.float32) / 255
hsv = np.asarray(im.convert("HSV")).astype(np.float32) / 255
h, s, v = hsv[..., 0] * 360, hsv[..., 1], hsv[..., 2]
skin = ((h > 8) & (h < 45) & (s > 0.35) & (v > 0.25)).astype(np.float32)
m = Image.fromarray((skin * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.GaussianBlur(6))
m = np.asarray(m).astype(np.float32)[..., None] / 255
# contrast on the guy: S-curve around his mid tone
lum = a @ np.array([0.2126, 0.7152, 0.0722], np.float32)
mid = float(np.median(lum[skin > 0]))
# contrast on LUMINANCE only (keeps the skin colour, no extra orange)
L2 = np.clip(mid + (lum - mid) * 1.25, 0, 1)
Lb = np.asarray(Image.fromarray((L2 * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(14))).astype(np.float32) / 255
L2 = np.clip(L2 + (L2 - Lb) * 0.3, 0, 1)   # a little definition (local contrast)
ratio = (L2 + 1e-3) / (lum + 1e-3)
c = np.clip(a * ratio[..., None], 0, 1)
guy = a * (1 - m) + c * m
# a touch of global contrast so the whole frame stays punchy
g = np.clip(0.5 + (guy - 0.5) * 1.06, 0, 1)
img = Image.fromarray((g * 255).astype(np.uint8)).filter(ImageFilter.UnsharpMask(radius=1.4, percent=35, threshold=3))
img.save(out)
print("mid", round(mid, 3), "mask cover", round(float(skin.mean()), 3))
