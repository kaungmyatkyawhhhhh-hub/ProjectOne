# Xmas landmark tree: measure the turnaround SIDE view (left half) -> profiles.json
# Run: python analyse_sheet.py   (reads turnaround_sheet.png next to this file)
import json, os, numpy as np
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
im = np.asarray(Image.open(os.path.join(HERE, "turnaround_sheet.png")).convert("RGB")).astype(int)
r, g, b = im[..., 0], im[..., 1], im[..., 2]
mag = (r > 200) & (b > 200) & (g < 90)
side = ~mag[:, :768].copy(); side[560:] = False   # side view only, above the label
R, G, B = r[:, :768], g[:, :768], b[:, :768]
green = side & (G > R + 25) & (G > B + 25)
yellow = side & (R > 180) & (G > 150) & (B < 90)
red = side & (R > 150) & (G < 70) & (B < 70)
white = side & (R > 220) & (G > 220) & (B > 200)
brown = side & (R > 70) & (R < 160) & (G > 35) & (G < 100) & (B < 60) & (R > G + 20)
def bbox(m):
    ys, xs = np.nonzero(m); return [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())]
cx = None
rows = []
ys, xs = np.nonzero(green)
cx = float((xs.min() + xs.max()) / 2)
for y in range(ys.min(), ys.max() + 1):
    xr = np.nonzero(green[y])[0]
    if len(xr): rows.append([y, float(max(cx - xr.min(), xr.max() - cx))])
w = np.array([h for _, h in rows])
# tier lower edges: rows where the width peaks (then drops >8%)
peaks = [i for i in range(3, len(w) - 3) if w[i] >= w[i-3:i+4].max() and w[i] > w[min(len(w)-1, i+6)] * 1.05]
out = {"cx": cx, "green": bbox(green), "star": bbox(yellow & (np.arange(768)[None, :] > cx - 90) & (np.arange(768)[None, :] < cx + 90) & (np.arange(1024)[:, None] < bbox(green)[1] + 15)),
       "skirt_red": bbox(red & (np.arange(1024)[:, None] > bbox(green)[3] - 20)), "skirt_white": bbox(white & (np.arange(1024)[:, None] > bbox(green)[3] - 20)),
       "trunk": bbox(brown) if brown.any() else None, "profile": rows[::2], "peaks": [rows[i] for i in peaks]}
json.dump(out, open(os.path.join(HERE, "profiles.json"), "w"))
print({k: v for k, v in out.items() if k != "profile"})
