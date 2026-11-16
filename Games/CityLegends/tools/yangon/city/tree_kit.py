"""tree_kit.py (2026-11-16, P1 greenery): the reusable Yangon tree / shrub kit as meshes, for every 1:1 district.

    python tree_kit.py            -> imports/sync/ygn1to1_green/treekit.glb + build/city_1to1/green/treekit.json

One mesh per piece, named glb.code(kind, pid, centre, size) like the building kit, so the light-kit loader can make
templates from it (ReplicatedStorage.YgnKit.Templates, KIND_<pid> with attributes C / S). The record origin of every
piece is the foot of the trunk on the ground (y = 0), metres x 3 = studs. Kinds:
  TRC  foliage (Grass + MaterialVariant YgnFoliage; vertex colours tint it: dark undersides, lighter sunlit tops)
  TRB  bark (Wood + YgnBark)
  TRF  flowers (Fabric, vertex colour magenta: bougainvillea)
  TFR  far look of a broadleaf tree (one cheap mesh, placed in the place; hidden on a client near it)
  TFP  far look of a palm
Pieces (pid): rain tree rt1 / rt2 (Samanea saman umbrella, 22 m across), broadleaf bl1 / bl2 (padauk, tamarind, gold
mohur: 12 m), mango mg1 / mg2 (dense dark dome, 11 m), mahogany mh1 (tall oval, 10 m x 18 m), coconut palm cp1 /
cp2 (straight / leaning, 17 m), banana clump bn1 (4 m), hedge hg1 (3 m long, 1 m deep, 1.3 m: stretched along X),
bougainvillea bv1 (3 m mound with magenta bracts), shrub sh1 (1.6 m), far ff1 / fp1.
Sizes: the research (City Legends/2026-11-16 Research - Yangon terrain, water and trees.md, section 4); the placer
scales each piece (kit_pack Q records: sx = sy = sz, with a little extra sy).
"""
import json
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from glb import Mesh, write_glb, code  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
OUT_GLB = os.path.join(ROOT, "imports", "sync", "ygn1to1_green")
OUT_JSON = os.path.join(ROOT, "build", "city_1to1", "green")
S = 3.0  # studs a metre (the 1:1 frame)

# foliage vertex colours (multiply YgnGrassLawn's map 81,117,54): sunlit top, mid, shaded underside
LEAF = {
    "rain": ((0.95, 0.92, 0.80), (0.70, 0.70, 0.62), (0.34, 0.36, 0.33)),
    "broad": ((1.00, 0.98, 0.78), (0.76, 0.76, 0.62), (0.38, 0.40, 0.34)),
    "mango": ((0.70, 0.72, 0.70), (0.50, 0.52, 0.52), (0.26, 0.28, 0.28)),
    "mahog": ((0.78, 0.78, 0.70), (0.56, 0.58, 0.54), (0.28, 0.30, 0.29)),
    "palm": ((1.05, 1.00, 0.70), (0.86, 0.84, 0.60), (0.55, 0.54, 0.42)),
    "banana": ((1.10, 1.10, 0.78), (0.92, 0.95, 0.66), (0.62, 0.62, 0.45)),
    "hedge": ((0.80, 0.84, 0.70), (0.58, 0.62, 0.55), (0.32, 0.34, 0.31)),
    "shrub": ((0.92, 0.94, 0.74), (0.66, 0.70, 0.58), (0.34, 0.36, 0.32)),
}
BARK = {"rain": (92, 80, 70), "broad": (98, 86, 72), "mango": (78, 66, 56), "mahog": (86, 72, 60), "palm": (128, 116, 100)}


# ------------------------------------------------------------------------------------------------- geometry
def icosphere(level):
    t = (1 + 5 ** 0.5) / 2
    V = [(-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0), (0, -1, t), (0, 1, t), (0, -1, -t), (0, 1, -t),
         (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1)]
    V = [tuple(c / math.sqrt(sum(x * x for x in v)) for c in v) for v in V]
    F = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6),
         (7, 1, 8), (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7),
         (9, 8, 1)]
    for _ in range(level):
        cache = {}
        nf = []

        def mid(a, b):
            k = (min(a, b), max(a, b))
            if k not in cache:
                p = [(V[a][i] + V[b][i]) / 2 for i in range(3)]
                l = math.sqrt(sum(x * x for x in p))
                V.append(tuple(x / l for x in p))
                cache[k] = len(V) - 1
            return cache[k]
        for a, b, c in F:
            ab, bc, ca = mid(a, b), mid(b, c), mid(c, a)
            nf += [(a, ab, ca), (b, bc, ab), (c, ca, bc), (ab, bc, ca)]
        F = nf
    return V, F


ICO = {k: icosphere(k) for k in (0, 1, 2)}


def vnoise(x, y, z, seed):
    """cheap smooth pseudo-noise in about -1..1"""
    return (math.sin(x * 1.7 + seed * 3.1) * math.sin(y * 2.3 + seed * 1.3) * math.sin(z * 1.9 + seed * 2.7) * 0.6 +
            math.sin(x * 4.1 + y * 3.3 + seed) * 0.25 + math.sin(z * 5.3 - x * 2.9 + seed * 0.7) * 0.15)


def _sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def _cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def _unit(v):
    l = math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2])
    return (v[0] / l, v[1] / l, v[2] / l) if l > 1e-12 else (0.0, 1.0, 0.0)


def uvbox(p, n):
    ax = max(range(3), key=lambda k: abs(n[k]))
    if ax == 0:
        return (p[2], p[1])
    if ax == 1:
        return (p[0], p[2])
    return (p[0], p[1])


def shaded_mesh(m, V, F, colfn):
    """indexed triangles -> m with smooth normals and a colour per vertex (colfn(p, n) -> rgb 0-255)"""
    N = [(0.0, 0.0, 0.0)] * len(V)
    N = [list(n) for n in N]
    for a, b, c in F:
        fn = _cross(_sub(V[b], V[a]), _sub(V[c], V[a]))
        for k in (a, b, c):
            for i in range(3):
                N[k][i] += fn[i]
    N = [_unit(n) for n in N]
    C = [colfn(V[k], N[k]) for k in range(len(V))]
    for a, b, c in F:
        i = len(m.P)
        fn = _unit(_cross(_sub(V[b], V[a]), _sub(V[c], V[a])))
        if fn == (0.0, 1.0, 0.0) and V[a] == V[b]:
            continue
        m.P += [V[a], V[b], V[c]]
        m.N += [N[a], N[b], N[c]]
        m.U += [uvbox(V[a], fn), uvbox(V[b], fn), uvbox(V[c], fn)]
        m.C += [tuple(int(max(0, min(255, round(x)))) for x in C[k]) for k in (a, b, c)]
        m.T += [i, i + 1, i + 2]


def leafcol(pal, ytop, ybot, rnd, tint=1.0):
    top, midc, bot = pal

    def f(p, n):
        h = (p[1] - ybot) / max(1e-6, ytop - ybot)
        up = max(0.0, n[1])
        a = max(0.0, min(1.0, 0.55 * h + 0.45 * up))
        c = [bot[i] + (midc[i] - bot[i]) * min(1, a * 2) if a < 0.5 else midc[i] + (top[i] - midc[i]) * (a - 0.5) * 2
             for i in range(3)]
        j = 1.0 + 0.07 * vnoise(p[0] * 0.3, p[1] * 0.3, p[2] * 0.3, rnd)
        return tuple(255 * min(1.25, c[i] * j * tint) for i in range(3))
    return f


def lobe(m, centre, radii, seed, pal, ytop, ybot, level=2, amp=0.16, flat_bottom=0.0, tint=1.0):
    V0, F = ICO[level]
    V = []
    for v in V0:
        d = 1.0 + amp * vnoise(v[0] * 2.2, v[1] * 2.2, v[2] * 2.2, seed)
        y = v[1]
        if flat_bottom and y < 0:
            y = y * (1 - flat_bottom)
        V.append((centre[0] + v[0] * radii[0] * d, centre[1] + y * radii[1] * d, centre[2] + v[2] * radii[2] * d))
    shaded_mesh(m, V, F, leafcol(pal, ytop, ybot, seed, tint))


def limb(m, p0, p1, r0, r1, rgb, sides=7, cap=False):
    """a tapered cylinder p0 -> p1 (smooth sides)"""
    ax = _unit(_sub(p1, p0))
    ref = (0, 0, 1) if abs(ax[1]) > 0.9 else (0, 1, 0)
    u = _unit(_cross(ax, ref))
    w = _cross(ax, u)
    ring0, ring1, nn = [], [], []
    for k in range(sides):
        a = 2 * math.pi * k / sides
        d = tuple(u[i] * math.cos(a) + w[i] * math.sin(a) for i in range(3))
        nn.append(d)
        ring0.append(tuple(p0[i] + d[i] * r0 for i in range(3)))
        ring1.append(tuple(p1[i] + d[i] * r1 for i in range(3)))
    L = math.sqrt(sum(x * x for x in _sub(p1, p0)))
    for k in range(sides):
        k2 = (k + 1) % sides
        a, b, c, d = ring0[k], ring0[k2], ring1[k2], ring1[k]
        ua, ub = (k * 2.0 * r0, 0), (k2 * 2.0 * r0 if k2 else sides * 2.0 * r0, 0)
        # counter-clockwise from outside: a (bottom k), b (bottom k+1), c (top k+1), d (top k)
        dark = tuple(x * 0.8 for x in rgb)
        for tri, nrm, uvs, cols in (((a, b, c), (nn[k], nn[k2], nn[k2]), (ua, ub, (ub[0], L)), (dark, dark, rgb)),
                                    ((a, c, d), (nn[k], nn[k2], nn[k]), (ua, (ub[0], L), (ua[0], L)), (dark, rgb, rgb))):
            i = len(m.P)
            m.P += list(tri)
            m.N += list(nrm)
            m.U += list(uvs)
            m.C += [tuple(int(max(0, min(255, x))) for x in c) for c in cols]
            m.T += [i, i + 1, i + 2]
    if cap:
        for k in range(sides):
            k2 = (k + 1) % sides
            m.tri(p1, ring1[k], ring1[k2], (0, 0), (1, 0), (0, 1), rgb)


def ribbon(m, pts, widths, normal_fn, rgbs, fold=0.0, double=True):
    """a strip along pts (width per point, across = normal_fn(i)), optionally folded into a V; both sides drawn"""
    L = []
    for i, p in enumerate(pts):
        if i < len(pts) - 1:
            t = _unit(_sub(pts[i + 1], p))
        else:
            t = _unit(_sub(p, pts[i - 1]))
        up = normal_fn(i)
        side = _unit(_cross(t, up))
        w = widths[i] / 2
        drop = tuple(-up[k] * w * fold for k in range(3))
        L.append((tuple(p[k] - side[k] * w + drop[k] for k in range(3)), p, tuple(p[k] + side[k] * w + drop[k] for k in range(3))))
    for i in range(len(pts) - 1):
        for s in (0, 1):
            a, b = L[i][s], L[i][s + 1]
            c, d = L[i + 1][s + 1], L[i + 1][s]
            col = rgbs[i]
            m.quad(a, b, c, d, (a[0], a[2]), (b[0], b[2]), (c[0], c[2]), (d[0], d[2]), col)
            if double:
                m.quad(a, d, c, b, (a[0], a[2]), (d[0], d[2]), (c[0], c[2]), (b[0], b[2]), tuple(x * 0.8 for x in col))


def scale_m(m, f):
    m.P = [(p[0] * f, p[1] * f, p[2] * f) for p in m.P]
    m.U = [(u[0] * f, u[1] * f) for u in m.U]
    return m


# ------------------------------------------------------------------------------------------------- pieces
def broadleaf_tree(seed, kind, D, Hgt, fork, nlobes, pal_name, nlimbs=3, flat=0.0, spread=0.62, lobe_r=0.36, lobe_h=0.26,
                   crown_mid=None, tint=1.0):
    """D crown diameter (m), Hgt total height (m), fork trunk height (m). Returns (crown, bark) in METRES."""
    r = random.Random(seed)
    crown, bark = Mesh(), Mesh()
    pal = LEAF[pal_name]
    R = D / 2
    cm = crown_mid if crown_mid is not None else Hgt - R * (0.55 if flat else 0.9)
    ytop, ybot = Hgt, cm - R * 0.9
    br = BARK[pal_name]
    r0 = max(0.14, D * 0.028)
    lean = (r.uniform(-0.25, 0.25), r.uniform(-0.25, 0.25))
    top = (lean[0], fork, lean[1])
    limb(bark, (0, -0.4, 0), (lean[0] * 0.5, fork * 0.55, lean[1] * 0.5), r0 * 1.25, r0, br)
    limb(bark, (lean[0] * 0.5, fork * 0.55, lean[1] * 0.5), top, r0, r0 * 0.85, br)
    a0 = r.uniform(0, 2 * math.pi)
    for k in range(nlimbs):
        a = a0 + 2 * math.pi * k / nlimbs + r.uniform(-0.3, 0.3)
        rr = R * spread * r.uniform(0.55, 0.85)
        mid = (top[0] + math.cos(a) * rr * 0.5, fork + (cm - fork) * 0.55, top[2] + math.sin(a) * rr * 0.5)
        end = (top[0] + math.cos(a) * rr, cm + r.uniform(-0.3, 0.4), top[2] + math.sin(a) * rr)
        limb(bark, top, mid, r0 * 0.7, r0 * 0.5, br, sides=6)
        limb(bark, mid, end, r0 * 0.5, r0 * 0.25, br, sides=5)
    # crown: a centre lobe and a ring
    lobe(crown, (top[0], cm + R * lobe_h * 0.6, top[2]), (R * 0.55, R * (0.42 if flat else 0.62), R * 0.55), r.random() * 9,
         pal, ytop, ybot, 2, 0.14, flat, tint)
    for k in range(nlobes):
        a = a0 + 2 * math.pi * (k + 0.5) / nlobes + r.uniform(-0.25, 0.25)
        d = R * spread * r.uniform(0.85, 1.05)
        cy = cm + r.uniform(-0.12, 0.12) * R - (0.10 * R if flat else 0)
        lr = R * lobe_r * r.uniform(0.9, 1.15)
        lobe(crown, (top[0] + math.cos(a) * d, cy, top[2] + math.sin(a) * d),
             (lr, R * (lobe_h if flat else lobe_r * 0.9) * r.uniform(0.9, 1.1), lr), r.random() * 9, pal, ytop, ybot,
             2 if lr > 4.5 else 1, 0.16, flat * 0.6, tint)
    return crown, bark


def palm(seed, Hgt, bend, nfr=11):
    r = random.Random(seed)
    crown, bark = Mesh(), Mesh()
    pal = LEAF["palm"]
    br = BARK["palm"]
    # trunk: a curve with a lean, bulb at the base, thinner up top
    seg = 10
    pts = []
    for k in range(seg + 1):
        t = k / seg
        pts.append((bend * t * t * Hgt * 0.22, -0.3 + t * (Hgt + 0.3), bend * 0.15 * t * Hgt * 0.1))
    for k in range(seg):
        t = k / seg
        r0 = 0.24 - 0.09 * t + (0.08 if k == 0 else 0)
        r1 = 0.24 - 0.09 * (t + 1 / seg)
        limb(bark, pts[k], pts[k + 1], r0, r1, tuple(c * (0.9 + 0.12 * (k % 2)) for c in br), sides=7)
    tip = pts[-1]
    # nut cluster
    for k in range(4):
        a = k * 1.6
        lobe(crown, (tip[0] + math.cos(a) * 0.25, tip[1] - 0.35, tip[2] + math.sin(a) * 0.25), (0.16, 0.16, 0.16), k,
             ((0.75, 0.7, 0.3), (0.6, 0.55, 0.25), (0.4, 0.35, 0.2)), tip[1], tip[1] - 0.6, 1, 0.05)
    lobe(crown, (tip[0], tip[1] + 0.05, tip[2]), (0.32, 0.45, 0.32), 3, pal, tip[1] + 0.5, tip[1] - 0.4, 1, 0.1)
    for k in range(nfr):
        a = 2 * math.pi * k / nfr + r.uniform(-0.15, 0.15)
        up_ang = r.uniform(0.15, 1.75) if k % 3 else r.uniform(0.9, 1.9)   # 0 straight up .. ~1.9 hanging
        L = r.uniform(5.0, 6.0)
        P = []
        n = 6
        for i in range(n + 1):
            t = i / n
            ang = up_ang + t * 0.9 * (0.6 + up_ang * 0.4)
            horiz = math.sin(min(ang, 2.6))
            # integrate the arc
            if i == 0:
                P.append(tip)
            else:
                prev = P[-1]
                step = L / n
                P.append((prev[0] + math.cos(a) * math.sin(ang) * step, prev[1] + math.cos(ang) * step,
                          prev[2] + math.sin(a) * math.sin(ang) * step))
        W = [0.25 + 1.0 * math.sin(math.pi * min(1, (i / n) * 1.15)) * (1 - 0.6 * (i / n)) for i in range(n + 1)]
        side = (-math.sin(a), 0, math.cos(a))

        def nf(i, a=a, P=P):
            t = _unit(_sub(P[min(i + 1, n)], P[max(i - 1, 0)]))
            return _unit(_cross(side, t)) if True else (0, 1, 0)
        cols = []
        for i in range(n):
            c = pal[0] if i < n * 0.6 else pal[1]
            if k % 5 == 0 and i > n * 0.5:
                c = (0.95, 0.85, 0.55)   # an old frond going yellow-brown
            cols.append(tuple(255 * x for x in c))
        ribbon(crown, P, W, nf, cols, fold=0.35)
    return crown, bark


def banana(seed):
    r = random.Random(seed)
    crown = Mesh()
    pal = LEAF["banana"]
    for s in range(4):
        a = s * 1.7 + r.uniform(-0.3, 0.3)
        d = 0.35 + 0.25 * s
        base = (math.cos(a) * d, -0.2, math.sin(a) * d)
        h = r.uniform(2.0, 2.9) - s * 0.2
        top = (base[0] * 1.3, h, base[2] * 1.3)
        limb(crown, base, top, 0.14, 0.09, (150, 170, 110), sides=6)
        for k in range(4):
            b = a + k * 1.55 + r.uniform(-0.2, 0.2)
            L = r.uniform(2.2, 2.8)
            up_ang = r.uniform(0.5, 1.2)
            P = [top]
            n = 4
            for i in range(n):
                ang = up_ang + i * 0.33
                P.append((P[-1][0] + math.cos(b) * math.sin(ang) * L / n, P[-1][1] + math.cos(ang) * L / n,
                          P[-1][2] + math.sin(b) * math.sin(ang) * L / n))
            W = [0.08] + [0.65 * math.sin(math.pi * (i / n) * 0.95 + 0.15) for i in range(1, n + 1)]
            side = (-math.sin(b), 0, math.cos(b))

            def nf(i, P=P, side=side):
                t = _unit(_sub(P[min(i + 1, n)], P[max(i - 1, 0)]))
                return _unit(_cross(side, t))
            cols = []
            for i in range(n):
                c = pal[0] if (k + s) % 4 else (0.95, 0.82, 0.5)  # a dry torn leaf now and then
                cols.append(tuple(255 * x for x in c))
            ribbon(crown, P, W, nf, cols, fold=0.1)
    return crown


def hedge(seed):
    r = random.Random(seed)
    m = Mesh()
    pal = LEAF["hedge"]
    for k in range(4):
        x = -1.15 + k * 0.77
        lobe(m, (x, 0.62, r.uniform(-0.05, 0.05)), (0.62, 0.66, 0.52), r.random() * 9, pal, 1.3, 0.0, 1, 0.14, 0.3)
    return m


def shrub(seed, D, Hh, pal_name="shrub", n=4):
    r = random.Random(seed)
    m = Mesh()
    pal = LEAF[pal_name]
    lobe(m, (0, Hh * 0.52, 0), (D * 0.36, Hh * 0.5, D * 0.36), r.random() * 9, pal, Hh, 0, 2, 0.15, 0.3)
    for k in range(n):
        a = 2 * math.pi * k / n + r.uniform(-0.3, 0.3)
        lobe(m, (math.cos(a) * D * 0.25, Hh * r.uniform(0.3, 0.45), math.sin(a) * D * 0.25),
             (D * 0.26, Hh * 0.32, D * 0.26), r.random() * 9, pal, Hh, 0, 1, 0.16, 0.4)
    return m


def bougainvillea(seed):
    """a 3 m mound of leaves with magenta bract clusters on its sunlit side"""
    r = random.Random(seed)
    leaves = shrub(seed, 3.0, 2.8, "shrub", 5)
    fl = Mesh()
    mag = ((235, 70, 160), (210, 45, 140), (150, 30, 100))
    for k in range(26):
        a = 2 * math.pi * k / 26 * 3.0 + r.uniform(-0.4, 0.4)
        el = r.uniform(0.05, 1.25)
        rr = 1.3 * math.cos(el) + 0.05
        c = (math.cos(a) * rr, 1.25 + math.sin(el) * 1.25, math.sin(a) * rr)
        s = r.uniform(0.2, 0.34)
        V0, F = ICO[0]
        V = [(c[0] + v[0] * s, c[1] + v[1] * s * 0.7, c[2] + v[2] * s) for v in V0]
        col = mag[k % 3]
        shaded_mesh(fl, V, F, lambda p, n, col=col: tuple(x * (0.75 + 0.25 * max(0, n[1])) for x in col))
    return leaves, fl


def far_round(seed):
    m = Mesh()
    V0, F = ICO[1]
    pal = ((0.80, 0.80, 0.68), (0.58, 0.60, 0.52), (0.30, 0.32, 0.29))
    V = []
    for v in V0:
        d = 1.0 + 0.15 * vnoise(v[0] * 2, v[1] * 2, v[2] * 2, seed)
        V.append((v[0] * 0.5 * d, 0.62 + v[1] * 0.3 * d, v[2] * 0.5 * d))
    shaded_mesh(m, V, F, leafcol(pal, 0.92, 0.32, seed))
    # stub trunk (dark: under the crown it reads as shade)
    k0 = len(m.P)
    tr = Mesh()
    limb(tr, (0, -0.02, 0), (0, 0.45, 0), 0.035, 0.025, (64, 82, 46), sides=5)
    m.extend(tr)
    return m


def far_palm(seed):
    m = Mesh()
    limb(m, (0, -0.02, 0), (0.03, 0.92, 0), 0.016, 0.012, (110, 125, 80), sides=5)
    top = (0.03, 0.92, 0)
    for k in range(8):
        a = k * math.pi / 4
        tip = (top[0] + math.cos(a) * 0.24, top[1] - 0.06, top[2] + math.sin(a) * 0.24)
        l = (top[0] + math.cos(a + 0.35) * 0.06, top[1] + 0.03, top[2] + math.sin(a + 0.35) * 0.06)
        rr = (top[0] + math.cos(a - 0.35) * 0.06, top[1] + 0.03, top[2] + math.sin(a - 0.35) * 0.06)
        for tri in ((top, rr, tip), (top, tip, rr), (top, l, tip), (top, tip, l)):
            m.tri(*tri, (0, 0), (1, 0), (0, 1), (225, 220, 160))
    return m


# ------------------------------------------------------------------------------------------------- build
def build():
    pieces = {}   # pid -> dict(kind -> Mesh in studs), info
    info = {}

    def add(pid, parts, meta):
        pieces[pid] = {k: scale_m(v, S) for k, v in parts.items()}
        info[pid] = meta

    # rain tree: 22 m umbrella, 15 m tall, low fork at 4 m, wide low limbs
    for i, sd in enumerate((11, 23)):
        c, b = broadleaf_tree(sd, "rain", 22.0, 15.0, 4.0, 7, "rain", nlimbs=5, flat=0.45, spread=0.66, lobe_r=0.32,
                              lobe_h=0.22, crown_mid=11.2)
        add("rt%d" % (i + 1), {"TRC": c, "TRB": b}, dict(species="rain tree", D=22.0, H=15.0, base=7.5))
    for i, sd in enumerate((31, 37)):
        c, b = broadleaf_tree(sd, "broad", 12.0, 13.0, 3.6, 5, "broad", nlimbs=3, spread=0.5, lobe_r=0.4, crown_mid=8.6)
        add("bl%d" % (i + 1), {"TRC": c, "TRB": b}, dict(species="padauk / tamarind / gold mohur", D=12.0, H=13.0, base=4.5))
    for i, sd in enumerate((41, 47)):
        c, b = broadleaf_tree(sd, "mango", 11.0, 10.0, 1.8, 6, "mango", nlimbs=3, spread=0.48, lobe_r=0.42, crown_mid=5.6)
        add("mg%d" % (i + 1), {"TRC": c, "TRB": b}, dict(species="mango / jackfruit", D=11.0, H=10.0, base=2.0))
    c, b = broadleaf_tree(53, "mahog", 10.0, 18.0, 6.0, 5, "mahog", nlimbs=3, spread=0.42, lobe_r=0.42, crown_mid=12.5)
    # stretch the mahogany crown upward (dense tall oval)
    c.P = [(p[0], 12.5 + (p[1] - 12.5) * 1.35, p[2]) for p in c.P]
    add("mh1", {"TRC": c, "TRB": b}, dict(species="mahogany", D=10.0, H=19.0, base=7.0))
    for i, (sd, bend) in enumerate(((61, 0.25), (67, 1.0))):
        c, b = palm(sd, 16.0, bend)
        add("cp%d" % (i + 1), {"TRC": c, "TRB": b}, dict(species="coconut palm", D=8.0, H=17.0, base=13.0))
    add("bn1", {"TRC": banana(71)}, dict(species="banana clump", D=4.5, H=4.0, base=1.5))
    add("hg1", {"TRC": hedge(81)}, dict(species="hedge (3 m piece)", D=1.0, H=1.3, base=0.0))
    lv, fl = bougainvillea(91)
    add("bv1", {"TRC": lv, "TRF": fl}, dict(species="bougainvillea", D=3.0, H=2.8, base=0.0))
    add("sh1", {"TRC": shrub(95, 1.8, 1.6)}, dict(species="shrub", D=1.8, H=1.6, base=0.0))
    # far looks: unit size (1 stud across), scaled by the placer to the crown
    pieces["ff1"] = {"TFR": far_round(5)}
    info["ff1"] = dict(species="far broadleaf", unit=True)
    pieces["fp1"] = {"TFP": far_palm(6)}
    info["fp1"] = dict(species="far palm", unit=True)
    named = []
    meta = {}
    for pid, parts in pieces.items():
        for kind, mm in parts.items():
            lo, hi = mm.box()
            cen = tuple((lo[k] + hi[k]) / 2 for k in range(3))
            size = tuple(hi[k] - lo[k] for k in range(3))
            nm = code(kind, pid, cen, size)
            named.append((nm, mm))
            meta.setdefault(pid, dict(info[pid], parts={}))["parts"][kind] = dict(name=nm, tris=mm.tris,
                                                                                  centre=[round(v, 3) for v in cen],
                                                                                  size=[round(v, 3) for v in size])
    os.makedirs(OUT_GLB, exist_ok=True)
    os.makedirs(OUT_JSON, exist_ok=True)
    path = os.path.join(OUT_GLB, "treekit.glb")
    write_glb(path, named)
    json.dump(meta, open(os.path.join(OUT_JSON, "treekit.json"), "w"), indent=1)
    tot = 0
    for pid, md in meta.items():
        t = sum(p["tris"] for p in md["parts"].values())
        tot += t
        print("%-4s %-32s %5d tris  %s" % (pid, md["species"], t, {k: v["size"] for k, v in md["parts"].items()}))
    print("%d meshes, %d tris, %s (%d bytes)" % (len(named), tot, path, os.path.getsize(path)))
    return meta


if __name__ == "__main__":
    build()
