"""UI sheet processor: magenta key by border flood fill, cut pieces, trim, auto 9-slice centre, previews.
python3 process_sheet.py <sheet.png> <out_dir> <prefix>
Writes <prefix>_<n>.png (RGBA, trimmed + 4 px pad), pieces.json (bbox, size, slice centre guess), preview_dark/light.png
"""
import sys, os, json
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

src, out, prefix = sys.argv[1], sys.argv[2], sys.argv[3]
os.makedirs(out, exist_ok=True)
im = np.asarray(Image.open(src).convert('RGB')).astype(np.float32)
H, W, _ = im.shape
M = np.array([255, 0, 255], np.float32)
d = np.sqrt(((im - M) ** 2).sum(-1))
# background = magenta-ish regions connected to the border (never key purple art inside an outline)
lab, n = ndi.label(d < 70)
border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
bg = np.isin(lab, list(border))
# soft edge: 3 px band around the background, alpha from colour distance, un-mix the magenta
band = ndi.binary_dilation(bg, iterations=3) & ~bg
alpha = np.ones((H, W), np.float32)
alpha[bg] = 0
a_band = np.clip((d - 45) / 70, 0, 1)
alpha[band] = a_band[band]
rgb = im.copy()
ab = np.maximum(alpha, 1e-3)[..., None]
unmix = (im - (1 - ab) * M) / ab
rgb[band] = np.clip(unmix[band], 0, 255)
# pieces = connected foreground blobs
fg = alpha > 0.02
lab2, n2 = ndi.label(fg)
sizes = ndi.sum(fg, lab2, range(1, n2 + 1))
pieces = []
k = 0
objs = ndi.find_objects(lab2)
order = sorted([i for i in range(1, n2 + 1) if sizes[i - 1] >= 600], key=lambda i: (objs[i - 1][0].start // 160, objs[i - 1][1].start))
for i in order:
    sl = objs[i - 1]
    y0, y1, x0, x1 = sl[0].start, sl[0].stop, sl[1].start, sl[1].stop
    m = (lab2 == i)[y0:y1, x0:x1]
    a = (alpha[y0:y1, x0:x1] * m)
    rgba = np.dstack([rgb[y0:y1, x0:x1], a * 255]).clip(0, 255).astype(np.uint8)
    pad = 4
    rgba = np.pad(rgba, ((pad, pad), (pad, pad), (0, 0)))
    h, w = rgba.shape[:2]
    # 9-slice guess: the longest run of rows/cols that are (nearly) identical in the middle = the stretch zone
    def stretch(axis):
        A = rgba.astype(np.float32)
        lines = A if axis == 0 else A.transpose(1, 0, 2)
        L = lines.shape[0]
        diff = np.abs(np.diff(lines, axis=0)).mean(axis=(1, 2))
        ok = diff < 2.2
        best = (L // 2, L // 2 + 1); run = 0; start = 0
        for j in range(L - 1):
            if ok[j]:
                if run == 0: start = j
                run += 1
                if run > best[1] - best[0]: best = (start, start + run)
            else: run = 0
        lo, hi = best
        if hi - lo < 4: lo, hi = int(L * 0.4), int(L * 0.6)
        return int(lo), int(hi)
    sy0, sy1 = stretch(0); sx0, sx1 = stretch(1)
    k += 1
    name = f'{prefix}_{k:02d}.png'
    Image.fromarray(rgba).save(os.path.join(out, name))
    pieces.append(dict(file=name, bbox=[int(x0), int(y0), int(x1), int(y1)], size=[w, h], slice=[sx0, sy0, sx1, sy1]))
json.dump(pieces, open(os.path.join(out, f'{prefix}_pieces.json'), 'w'), indent=1)
# previews on dark + light
for nm, col in (('dark', (16, 24, 40)), ('light', (235, 238, 242))):
    canvas = Image.new('RGBA', (W, H), col + (255,))
    for p in pieces:
        pi = Image.open(os.path.join(out, p['file']))
        canvas.alpha_composite(pi, (p['bbox'][0] - 4, p['bbox'][1] - 4))
    canvas.convert('RGB').resize((W // 2, H // 2)).save(os.path.join(out, f'{prefix}_preview_{nm}.png'))
print(len(pieces), 'pieces', [(p['file'], p['size'], p['slice']) for p in pieces])
