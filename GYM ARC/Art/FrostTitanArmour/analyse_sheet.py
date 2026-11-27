# Measures the exploded sheet's armour silhouettes into profiles.json (read by build_armour.py in Blender).
import numpy as np, cv2, json, sys
im = cv2.imread('exploded_sheet.png')[:, :, ::-1].astype(int)
R, G, B = im[..., 0], im[..., 1], im[..., 2]
mag = (R > 170) & (G < 110) & (B > 170) & (R - G > 90)
navy = ((R < 60) & (G < 90) & (B < 130)).astype(np.uint8)
n, lab, st, _ = cv2.connectedComponentsWithStats(navy)
lbl = np.zeros_like(navy)
for i in range(1, n):
    x, y, w, h, a = st[i]
    if a > 300 and a > 0.6 * w * h and w > 40 and h > 18:  # label boxes only (not leader lines / attach dots)
        lbl[max(0, y - 7):y + h + 7, max(0, x - 7):x + w + 7] = 1
# leader lines and attach dots (dark, outside the label boxes) count as the piece they cross; the opening then removes
# the thin parts that stick out over the magenta
ice = (~mag) & (lbl == 0)
ice = ice.astype(np.uint8)
ice = cv2.morphologyEx(ice, cv2.MORPH_OPEN, np.ones((9, 9), np.uint8))
ice = cv2.morphologyEx(ice, cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8))
n, lab, st, cen = cv2.connectedComponentsWithStats(ice)

SEEDS = {  # a point inside each piece on the sheet -> name
    (286, 212): 'plate1', (295, 321): 'plate2', (310, 418): 'plate3', (1020, 311): 'pauldron_assembled',
    (650, 198): 'crown_front', (650, 300): 'crown_top', (236, 700): 'bracer_front', (446, 654): 'bracer_side',
}
PIECES = {int(lab[y, x]): name for (x, y), name in SEEDS.items()}
glow = (G > 200) & (B > 220) & (R < 150)  # saturated cyan edge glow
out = {}
for i in range(1, n):
    x, y, w, h, a = (int(v) for v in st[i])
    name = PIECES.get(i)
    if not name:
        continue
    m = (lab[y:y + h, x:x + w] == i)
    # fill holes left by attach dots / leader lines: enclosed pixels that are not sheet magenta
    inv = (~m).astype(np.uint8)
    nh, hl, hs, _ = cv2.connectedComponentsWithStats(inv)
    sub_mag = mag[y:y + h, x:x + w]
    for j in range(1, nh):
        hx, hy, hw, hh, ha = hs[j]
        touches = hx == 0 or hy == 0 or hx + hw == w or hy + hh == h
        if not touches and sub_mag[hl == j].mean() < 0.5:
            m |= (hl == j)
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
assert len(out) == len(SEEDS) and 0 not in PIECES, (sorted(out), PIECES)
json.dump(out, open('profiles.json', 'w'))
print({k: v['box'] for k, v in out.items()})
