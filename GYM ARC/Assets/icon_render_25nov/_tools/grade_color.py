# GYM ARC icon (25 Nov): colour fix vs Power Lifters. Skin: un-clip highlights, richer saturation, deeper shadows.
# Whole frame: warm the mids/highlights a little (PL is warm-dominant: 41% warm vs 22% cool; ours was 29/31).
import sys, numpy as np
from PIL import Image, ImageFilter
src, out = sys.argv[1], sys.argv[2]
im = Image.open(src).convert("RGB")
hsv = np.asarray(im.convert("HSV")).astype(np.float32) / 255
h, s, v = hsv[..., 0] * 360, hsv[..., 1], hsv[..., 2]
skin = ((h > 8) & (h < 50) & (s > 0.3) & (v > 0.3)).astype(np.float32)
m = Image.fromarray((skin * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.GaussianBlur(5))
m = np.asarray(m).astype(np.float32) / 255
# skin: V curve (highlights 1.0 -> ~0.93, shadows deeper), saturation up towards PL 0.82
v2 = np.clip(v, 0, 1)
v2 = 0.93 * v2 ** 1.25 / (0.93 ** 0.0)          # compress top, deepen lows
v2 = np.where(v > 0.97, v2 + (v - 0.97) * 1.5, v2)  # keep a tiny specular glint
s2 = np.clip(s * 1.13 + 0.03, 0, 1)
h2 = h + (24 - h) * 0.25                          # nudge hue to PL's golden orange (24)
H = np.where((h > 0) & (h < 60) & (m > 0), h + (h2 - h) * m, h); S = s + (s2 - s) * m; V = v + (np.clip(v2, 0, 1) - v) * m
rgb = Image.fromarray((np.dstack([H / 360, S, V]) * 255).clip(0, 255).astype(np.uint8), "HSV").convert("RGB")
a = np.asarray(rgb).astype(np.float32) / 255
# warm split-tone on mids/highlights of the whole frame
lum = a @ np.array([0.2126, 0.7152, 0.0722], np.float32)
w = np.clip((lum - 0.25) / 0.6, 0, 1)[..., None]
a = np.clip(a * (1 + w * np.array([0.05, 0.015, -0.05], np.float32)), 0, 1)
Image.fromarray((a * 255).astype(np.uint8)).save(out)
