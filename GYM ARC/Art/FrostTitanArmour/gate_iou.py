# Silhouette IoU per view: sheet mask (mask_<view>.png) vs Blender render (gate/<view>.png), same pixel scale,
# aligned by bounding-box centre (never stretched). Writes gate/compare_<view>.png (sheet red, render green).
import cv2, numpy as np, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
views = ["plate1", "plate2", "plate3", "crown_front", "crown_top", "bracer_front", "bracer_side"]
UNIFORM = {"crown_top"}  # front view wins (the sheet draws it ~1.4x the top view)
ok = True
for v in views:
    m = cv2.imread(os.path.join(HERE, f"mask_{v}.png"), 0) > 127
    r = cv2.imread(os.path.join(HERE, "gate", f"{v}.png"), 0) > 60
    ys, xs = np.nonzero(r)
    r = r[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    if v in UNIFORM:  # sheet views drawn at different scales: this view is compared for shape (uniform scale, no stretch)
        k = m.shape[1] / r.shape[1]
        r = cv2.resize(r.astype(np.uint8), (m.shape[1], max(1, round(r.shape[0] * k))), interpolation=cv2.INTER_NEAREST) > 0
    H, W = max(m.shape[0], r.shape[0]) + 20, max(m.shape[1], r.shape[1]) + 20
    A = np.zeros((H, W), bool)
    B = np.zeros((H, W), bool)
    oy, ox = (H - m.shape[0]) // 2, (W - m.shape[1]) // 2
    A[oy:oy + m.shape[0], ox:ox + m.shape[1]] = m
    oy, ox = (H - r.shape[0]) // 2, (W - r.shape[1]) // 2
    B[oy:oy + r.shape[0], ox:ox + r.shape[1]] = r
    iou = (A & B).sum() / max(1, (A | B).sum())
    vis = np.zeros((H, W, 3), np.uint8)
    vis[A] = (0, 0, 200)
    vis[B] = (0, 200, 0)
    vis[A & B] = (200, 200, 200)
    cv2.imwrite(os.path.join(HERE, "gate", f"compare_{v}.png"), vis)
    flag = "PASS" if iou >= 0.90 else "FAIL"
    ok &= iou >= 0.90
    print(f"{v:14s} IoU {iou:.3f} {flag}  sheet {m.shape[1]}x{m.shape[0]}  render {r.shape[1]}x{r.shape[0]}")
print("ALL PASS" if ok else "NOT PASSING")
