# Measures the exploded sheet's armour silhouettes into profiles.json (read by build_armour.py in Blender).
import numpy as np, cv2, json, sys
im = cv2.imread('exploded_sheet.png')[:, :, ::-1].astype(int)
R, G, B = im[..., 0], im[..., 1], im[..., 2]
mag = (R > 200) & (G < 80) & (B > 200)
navy = ((R < 60) & (G < 90) & (B < 130)).astype(np.uint8)
n, lab, st, _ = cv2.connectedComponentsWithStats(navy)
lbl = np.zeros_like(navy)
for i in range(1, n):
    x, y, w, h, a = st[i]
    if a > 300:
        lbl[max(0, y - 7):y + h + 7, max(0, x - 7):x + w + 7] = 1
ice = ((~mag) & (B > 130) & (R < 235) & (lbl == 0)).astype(np.uint8)
ice = cv2.morphologyEx(ice, cv2.MORPH_OPEN, np.ones((5, 5), np.uint8))
ice = cv2.morphologyEx(ice, cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8))
n, lab, st, cen = cv2.connectedComponentsWithStats(ice)

PIECES = {  # sheet box top-left -> name
    (156, 150): 'plate1', (162, 272): 'plate2', (204, 382): 'plate3', (877, 170): 'pauldron_assembled',
    (519, 152): 'crown_front', (556, 282): 'crown_top', (140, 564): 'bracer_front', (377, 569): 'bracer_side',
}
glow = (G > 200) & (B > 220) & (R < 150)  # saturated cyan edge glow
out = {}
for i in range(1, n):
    x, y, w, h, a = (int(v) for v in st[i])
    name = PIECES.get((x, y))
    if not name:
        continue
    m = (lab[y:y + h, x:x + w] == i)
    cols = []
    for cx in range(w):
        ys = np.nonzero(m[:, cx])[0]
        cols.append([int(ys.min()), int(ys.max())] if len(ys) else None)
    rows = []
    for ry in range(h):
        xs = np.nonzero(m[ry, :])[0]
        rows.append([int(xs.min()), int(xs.max())] if len(xs) else None)
    g = glow[y:y + h, x:x + w] & m
    glow_rows = [round(float(g[ry].sum()) / max(1, m[ry].sum()), 3) for ry in range(h)]
    cv2.imwrite(f'mask_{name}.png', (m * 255).astype(np.uint8))
    out[name] = dict(box=[x, y, w, h], area=int(m.sum()), cols=cols, rows=rows, glow_rows=glow_rows)
assert len(out) == len(PIECES), sorted(out)
json.dump(out, open('profiles.json', 'w'))
print({k: v['box'] for k, v in out.items()})
