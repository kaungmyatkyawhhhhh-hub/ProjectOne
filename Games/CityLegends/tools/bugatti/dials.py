import numpy as np
from PIL import Image, ImageDraw
from collections import deque
T = "C:/Users/USER/.claude/jobs/a86b922d/tmp/bug/tex/"
def comps(mask):
    H, W = mask.shape
    seen = np.zeros_like(mask, bool)
    out = []
    for y in range(H):
        for x in range(W):
            if mask[y, x] and not seen[y, x]:
                q = deque([(y, x)]); seen[y, x] = True; pts = []
                while q:
                    cy, cx = q.popleft(); pts.append((cy, cx))
                    for dy, dx in ((1,0),(-1,0),(0,1),(0,-1)):
                        ny, nx = cy+dy, cx+dx
                        if 0 <= ny < H and 0 <= nx < W and mask[ny, nx] and not seen[ny, nx]:
                            seen[ny, nx] = True; q.append((ny, nx))
                out.append(np.array(pts))
    return out
def fit(pts):
    x, y = pts[:,0], pts[:,1]
    A = np.c_[2*x, 2*y, np.ones(len(x))]
    b = x*x + y*y
    c, *_ = np.linalg.lstsq(A, b, rcond=None)
    r = np.sqrt(c[2] + c[0]**2 + c[1]**2)
    return c[0], c[1], r
def dial(img, win, c0, r0, thr=150, maxa=None):
    a = np.asarray(img.convert("L")).astype(float)
    x0, y0, x1, y1 = win
    sub = a[y0:y1, x0:x1] > thr
    cs = comps(sub)
    pts = []
    for p in cs:
        cy, cx = p.mean(axis=0)
        if maxa is None or len(p) <= maxa:
            pts.append((cx + x0, cy + y0, len(p)))
    pts = np.array(pts)
    # keep blobs near the guessed ring
    d = np.hypot(pts[:,0]-c0[0], pts[:,1]-c0[1])
    sel = pts[np.abs(d - r0) < r0 * 0.12]
    for _ in range(4):
        cx, cy, r = fit(sel[:, :2])
        d = np.hypot(sel[:,0]-cx, sel[:,1]-cy)
        keep = np.abs(d - r) < max(2.0, r * 0.04)
        if keep.sum() < 6: break
        sel = sel[keep]
    return cx, cy, r, len(sel)
def show(img, name, results):
    im = img.convert("RGB").copy(); d = ImageDraw.Draw(im)
    for k, (cx, cy, r, n) in results.items():
        d.ellipse((cx-r, cy-r, cx+r, cy+r), outline=(0,255,0)); d.ellipse((cx-3, cy-3, cx+3, cy+3), fill=(255,0,0)); d.text((cx+4, cy+4), k, fill=(0,255,0))
    im.save(T + name)
don = Image.open(T + "2009_bugatti_PLASTIC_INTEIROR_col_6.png")
R = {}
R["rpm"] = dial(don, (600, 680, 1024, 1024), (812, 845), 190, maxa=60)
R["speed"] = dial(don, (280, 770, 570, 1024), (420, 905), 130, maxa=60)
R["power"] = dial(don, (0, 770, 290, 1024), (140, 905), 130, maxa=60)
R["fuel"] = dial(don, (195, 570, 410, 770), (300, 670), 90, maxa=60)
R["oil"] = dial(don, (800, 430, 1024, 610), (912, 505), 90, maxa=60)
print("donor", {k: tuple(round(v, 1) for v in val) for k, val in R.items()})
show(don, "fit_donor.png", R)
for tag, fn in (("ss", "2010_bugatti_ronSuperSportGold_2012InteriorB_Material_col_18.png"), ("gsv", "2013_bugatti_ndSportVitesseWRE_2012InteriorB_Material_col_17.png")):
    t = Image.open(T + fn)
    Q = {}
    Q["rpm"] = dial(t, (0, 300, 145, 450), (72, 378), 58, thr=120, maxa=20)
    Q["speed"] = dial(t, (145, 320, 280, 460), (212, 392), 56, thr=120, maxa=20)
    Q["power"] = dial(t, (270, 320, 410, 460), (338, 392), 56, thr=120, maxa=20)
    Q["up1"] = dial(t, (40, 95, 130, 185), (85, 140), 40, thr=120, maxa=20)
    Q["up2"] = dial(t, (125, 95, 215, 185), (168, 140), 40, thr=120, maxa=20)
    print(tag, {k: tuple(round(v, 1) for v in val) for k, val in Q.items()})
    show(t.resize((1024, 1024)), f"fit_{tag}.png", {k: (v[0]*2, v[1]*2, v[2]*2, v[3]) for k, v in Q.items()})
