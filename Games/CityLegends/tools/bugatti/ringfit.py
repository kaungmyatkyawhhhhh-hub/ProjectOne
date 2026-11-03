import sys, math
import numpy as np
from PIL import Image
def fit(pts):
    pts = np.array(pts, float); x, y = pts[:, 0], pts[:, 1]
    A = np.c_[2 * x, 2 * y, np.ones(len(x))]; b = x * x + y * y
    c, *_ = np.linalg.lstsq(A, b, rcond=None)
    return c[0], c[1], math.sqrt(c[2] + c[0] ** 2 + c[1] ** 2)
def robust(pts):
    pts = list(pts)
    for _ in range(6):
        cx, cy, r = fit(pts)
        d = [abs(math.hypot(px - cx, py - cy) - r) for px, py in pts]
        med = sorted(d)[len(d) // 2]
        keep = [p for p, e in zip(pts, d) if e <= max(2.0, 2.5 * med)]
        if len(keep) == len(pts): break
        pts = keep
    return fit(pts), len(pts)
def scan(path, c0, rmin, rmax, cond, run=4, skip=None):
    im = np.asarray(Image.open(path).convert("RGB").rotate(180)).astype(float)
    pts = []
    for deg in range(0, 360, 3):
        if skip and skip(deg): continue
        a = math.radians(deg); cnt = 0
        for r in np.arange(rmin, rmax, 0.5):
            x = int(round(c0[0] + r * math.cos(a))); y = int(round(c0[1] + r * math.sin(a)))
            if cond(im[y, x]):
                cnt += 1
                if cnt >= run:
                    rr = r - (run - 1) * 0.5
                    pts.append((c0[0] + rr * math.cos(a), c0[1] + rr * math.sin(a))); break
            else: cnt = 0
    return robust(pts)
T = "C:/Users/USER/.claude/jobs/a86b922d/tmp/bug/"
silver = lambda p: p.mean() > 140 and (p[2] - p[0]) < 25
black = lambda p: p.mean() < 40
print("chiron silver inner", scan(T + "o_ch.png", (400, 400), 120, 230, silver, 5))
print("pursport black inner", scan(T + "o_ps.png", (400, 419), 120, 260, black, 4))
print("supersport black inner", scan(T + "o_ss.png", (400, 464), 120, 260, black, 4))
