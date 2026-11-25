# Match the character's skin colour/contrast to a reference image (the approved icon G): per-channel mean/std transfer
# in Lab, inside an orange-skin mask, blended softly. Usage: match_skin.py src ref out
import sys, numpy as np
from PIL import Image, ImageFilter, ImageCms
src, ref, out = sys.argv[1:4]
def lab(im):
    srgb = ImageCms.createProfile("sRGB"); labp = ImageCms.createProfile("LAB")
    return ImageCms.applyTransform(im, ImageCms.buildTransformFromOpenProfiles(srgb, labp, "RGB", "LAB"))
def rgb(im):
    srgb = ImageCms.createProfile("sRGB"); labp = ImageCms.createProfile("LAB")
    return ImageCms.applyTransform(im, ImageCms.buildTransformFromOpenProfiles(labp, srgb, "LAB", "RGB"))
def mask(im):
    hsv = np.asarray(im.convert("HSV")).astype(np.float32) / 255
    h, s, v = hsv[..., 0] * 360, hsv[..., 1], hsv[..., 2]
    return (h > 8) & (h < 50) & (s > 0.3) & (v > 0.3)
S = Image.open(src).convert("RGB"); R = Image.open(ref).convert("RGB")
ms, mr = mask(S), mask(R)
ls = np.asarray(lab(S)).astype(np.float32); lr = np.asarray(lab(R)).astype(np.float32)
o = ls.copy()
for c in range(3):
    a, b = ls[..., c][ms], lr[..., c][mr]
    o[..., c] = (ls[..., c] - a.mean()) * (b.std() / max(a.std(), 1e-3)) + b.mean()
o = np.clip(o, 0, 255).astype(np.uint8)
M = Image.fromarray((ms * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(4))
M = (np.asarray(M).astype(np.float32) / 255)[..., None]
res = np.asarray(rgb(Image.fromarray(o, "LAB"))).astype(np.float32)
fin = np.asarray(S).astype(np.float32) * (1 - M) + res * M
Image.fromarray(fin.clip(0, 255).astype(np.uint8)).save(out)
for n, im, m in (("src", S, ms), ("ref", R, mr), ("out", Image.open(out), mask(Image.open(out)))):
    l = np.asarray(lab(im.convert("RGB"))).astype(np.float32)
    print(n, ["%.0f±%.0f" % (l[..., c][m].mean(), l[..., c][m].std()) for c in range(3)])
