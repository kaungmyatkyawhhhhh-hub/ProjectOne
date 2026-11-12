import numpy as np, sys
from PIL import Image
from scipy import ndimage as ndi
im = np.asarray(Image.open('sheet.png').convert('RGB')).astype(np.float32)
H, W, _ = im.shape
M = np.array([255, 0, 255], np.float32)
d = np.sqrt(((im - M) ** 2).sum(-1))
bgc = d < 70
lab, n = ndi.label(bgc)
border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
bg = np.isin(lab, list(border))
# enclosed magenta pockets (inside lighthouse rays etc.) that are big are background too
# enclosed pockets: only the ones that really are the key colour (a violet crystal is close to magenta but is art)
for i in range(1, n + 1):
    if i in border: continue
    m = lab == i
    if m.sum() >= 6 and (d[m].mean() < 37 or d[m].min() < 8): bg |= m
fg = ~bg
# soft edge: 3 px band
dist_in = ndi.distance_transform_edt(fg)
alpha = np.clip((d - 45) / 70, 0, 1)
a = np.where(dist_in > 3, 1.0, alpha) * fg
# un-mix the fringe in the band
band = (a > 0) & (a < 1)
rgb = im.copy()
aa = np.clip(a[..., None], 0.05, 1)
rgb[band] = ((im - (1 - aa) * M) / aa)[band]
rgb = np.clip(rgb, 0, 255)
out = np.dstack([rgb, a * 255]).astype(np.uint8)
# components
lab2, n2 = ndi.label(a > 0.5)
objs = ndi.find_objects(lab2)
sizes = ndi.sum(a > 0.5, lab2, range(1, n2 + 1))
boxes = [(o, s) for o, s in zip(objs, sizes) if s > 6000]
print('pieces', len(boxes))
# merge boxes that belong to the same cell (5 x 2 grid)
cells = {}
for o, s in zip(objs, sizes):
    if s < 60: continue
    cy, cx = (o[0].start + o[0].stop) / 2, (o[1].start + o[1].stop) / 2
    key = (int(cy // (H / 2)), int(cx // (W / 5)))
    b = cells.get(key)
    if b is None: cells[key] = [o[0].start, o[0].stop, o[1].start, o[1].stop]
    else: cells[key] = [min(b[0], o[0].start), max(b[1], o[0].stop), min(b[2], o[1].start), max(b[3], o[1].stop)]
names = [['LmLighthouse', 'LmOceanKing', 'LmWhaleArch', 'LmCrystalArch', 'LmGalleon'], ['Chest', 'ChestOpen', 'Pin', 'Compass', 'Map']]
for (r, c), b in sorted(cells.items()):
    y0, y1, x0, x1 = b
    piece = out[max(y0 - 4, 0):y1 + 4, max(x0 - 4, 0):x1 + 4]
    p = Image.fromarray(piece, 'RGBA')
    s = max(p.size)
    canvas = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    canvas.paste(p, ((s - p.size[0]) // 2, (s - p.size[1]) // 2))
    canvas = canvas.resize((256, 256), Image.LANCZOS)
    canvas.save(f'mb_icon_{names[r][c]}.png')
    print(names[r][c], p.size)
# preview on dark and light
prev = Image.new('RGB', (5 * 260, 4 * 260), (16, 34, 74))
for r in range(2):
    for c in range(5):
        ic = Image.open(f'mb_icon_{names[r][c]}.png')
        prev.paste(ic, (c * 260 + 2, r * 260 + 2), ic)
        bgl = Image.new('RGB', (256, 256), (244, 249, 255))
        bgl.paste(ic, (0, 0), ic)
        prev.paste(bgl, (c * 260 + 2, (r + 2) * 260 + 2))
prev.save('preview.png')
