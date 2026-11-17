import sys, numpy as np
from PIL import Image
from scipy import ndimage
src = np.asarray(Image.open(sys.argv[1]).convert("RGB")).astype(float)
M = np.array([255, 0, 255.])
d = np.sqrt(((src - M) ** 2).sum(-1))
bg_cand = d < 90
lab, n = ndimage.label(bg_cand)
border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
bg = np.isin(lab, list(border))
alpha = np.where(bg, 0.0, 1.0)
# soft edge + global soft pass for enclosed magenta pockets
soft = np.clip((d - 45) / 110, 0, 1)
alpha = np.where(d < 150, np.minimum(alpha + (bg & (d >= 45)) * soft, 1), alpha)
alpha = np.where(d < 150, np.minimum(alpha, soft), alpha)
a = alpha[..., None]
rgb = np.where(a > 0.02, (src - (1 - a) * M) / np.maximum(a, 0.02), 0)
out = np.dstack([np.clip(rgb, 0, 255), alpha * 255]).astype(np.uint8)
lab2, n2 = ndimage.label(alpha > 0.5)
boxes = []
for i, sl in enumerate(ndimage.find_objects(lab2)):
    if (lab2[sl] == i + 1).sum() > 2000:
        boxes.append((sl[0].start, sl[1].start, sl[0].stop, sl[1].stop))
boxes.sort(key=lambda b: (round((b[0] + b[2]) / 2 / 150), b[1]))
img = Image.fromarray(out, "RGBA")
for k, (y0, x0, y1, x1) in enumerate(boxes):
    img.crop((x0 - 2, y0 - 2, x1 + 2, y1 + 2)).save(f"{sys.argv[2]}_{k}.png")
    print(k, x0, y0, x1 - x0, y1 - y0)
