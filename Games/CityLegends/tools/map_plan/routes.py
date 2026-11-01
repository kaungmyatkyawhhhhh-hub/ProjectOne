import math
from geo import Elev

def catmull(pts, step=10.0, closed=False):
    P = list(pts)
    if closed:
        P = [P[-1]] + P + [P[0], P[1]]
    else:
        P = [(2 * P[0][0] - P[1][0], 2 * P[0][1] - P[1][1])] + P + [(2 * P[-1][0] - P[-2][0], 2 * P[-1][1] - P[-2][1])]
    out = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        L = math.hypot(p2[0] - p1[0], p2[1] - p1[1])
        n = max(2, int(L / step))
        for k in range(n):
            t = k / n
            t2, t3 = t * t, t * t * t
            out.append(tuple(0.5 * ((2 * p1[j]) + (-p0[j] + p2[j]) * t + (2 * p0[j] - 5 * p1[j] + 4 * p2[j] - p3[j]) * t2 + (-p0[j] + 3 * p1[j] - 3 * p2[j] + p3[j]) * t3) for j in (0, 1)))
    if not closed:
        out.append(P[-2])
    return out

def contour_y(el, x, h, ylo, yhi):
    y = ylo
    while y < yhi and el.at(x, y) < h:
        y += 5
    return min(max(y, ylo), yhi)

def contour_route(el, xs, h, ylo, yhi):
    return [(x, contour_y(el, x, h, ylo, yhi)) for x in xs]

def smooth(pts, k=2):
    out = []
    for i in range(len(pts)):
        a = pts[max(0, i - k): i + k + 1]
        if i == 0 or i == len(pts) - 1:
            out.append(pts[i])
        else:
            out.append((pts[i][0], sum(p[1] for p in a) / len(a)))
    return out

def profile(el, line, H, VS, S, maxg, fixed=None):
    """road heights in studs along a sampled line: terrain smoothed, grade-limited (game grade)"""
    n = len(line)
    s = [0.0]
    for i in range(1, n):
        s.append(s[-1] + math.hypot(line[i][0] - line[i - 1][0], line[i][1] - line[i - 1][1]) * S)
    raw = [max(el.at(*p), 2.0) * VS for p in line]
    # wide smoothing (about 300 studs)
    sm = []
    j0 = 0
    for i in range(n):
        lo = i
        while lo > 0 and s[i] - s[lo] < 150: lo -= 1
        hi = i
        while hi < n - 1 and s[hi] - s[i] < 150: hi += 1
        sm.append(sum(raw[lo:hi + 1]) / (hi - lo + 1))
    if fixed:
        for i, v in fixed.items():
            sm[i if i >= 0 else n + i] = v
    h = sm[:]
    fx = set((i if i >= 0 else n + i) for i in (fixed or {}))
    for _ in range(50):
        for i in range(1, n):
            if i in fx: continue
            d = s[i] - s[i - 1]
            h[i] = min(max(h[i], h[i - 1] - maxg * d), h[i - 1] + maxg * d)
        for i in range(n - 2, -1, -1):
            if i in fx: continue
            d = s[i + 1] - s[i]
            h[i] = min(max(h[i], h[i + 1] - maxg * d), h[i + 1] + maxg * d)
        if fixed:
            for i, v in fixed.items():
                h[i if i >= 0 else n + i] = v
    return s, raw, h
