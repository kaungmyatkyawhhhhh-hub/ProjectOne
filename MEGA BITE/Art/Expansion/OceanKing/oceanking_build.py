# MEGA BITE Ocean King statue (13 Nov, skill roblox-3d-model-from-sheet). Sheet: mb_sheet_lm_statue_v2.png.
# CONTRACT = the two elevations. SIDE view (top row; camera at -Y, +X = the face, to the right) and FRONT view (camera at +X, +Y right).
# Registration (measured): side: mound centre col 751, floor row 468, 3.04 px/stud (456 px = 150 studs, floor to crown tip);
#   front: axis col 1114 (gem, crown tip, cave), floor row 979, 3.19 px/stud (the front view is drawn 5% bigger: gem, cave and tip agree).
# Model axes: X forward (nose), Y to the statue's left (right in the front view), Z up. Origin = mound centre on the floor.
# Every number below is a sheet pixel measured from the silhouettes (measure in the notes) or from the grid crops.
import numpy as np, math, json, sys, os, cv2, trimesh
import triangle as tr
from scipy import ndimage as ndi
from skimage.morphology import skeletonize
sys.path.insert(0, '/tmp/claude-0/hk'); import hk
OUT = '/tmp/claude-0/lm/st2'
SS, SCX, SFL = 3.04, 751.0, 468.0
SF, FCX, FFL = 3.19, 1114.0, 979.0
sx = lambda px: (px - SCX) / SS
sz = lambda row: (SFL - row) / SS
fy = lambda px: (px - FCX) / SF
fz = lambda row: (FFL - row) / SF
PARTS = []          # (name, V[n,3], F[m,3])
def add(name, V, F):
    V = np.asarray(V, float); F = np.asarray(F, int)
    if len(F): PARTS.append((name, V, F))
def ring_pts(cx, cy, a, b, z, n, ex=2.0):
    t = np.arange(n) / n * 2 * math.pi
    c, s = np.cos(t), np.sin(t)
    x = cx + a * np.sign(c) * np.abs(c) ** (2 / ex); y = cy + b * np.sign(s) * np.abs(s) ** (2 / ex)
    return np.stack([x, y, np.full(n, z)], 1)
def loft(rings, cap0=True, cap1=True, tip=None):
    n = len(rings[0]); V = np.concatenate(rings); F = []
    for i in range(len(rings) - 1):
        a0, b0 = i * n, (i + 1) * n
        for k in range(n):
            k2 = (k + 1) % n
            F += [(a0 + k, a0 + k2, b0 + k2), (a0 + k, b0 + k2, b0 + k)]
    if cap0:
        c = len(V); V = np.vstack([V, rings[0].mean(0)]); F += [(c, (k + 1) % n, k) for k in range(n)]
    o = (len(rings) - 1) * n
    if tip is not None:
        c = len(V); V = np.vstack([V, tip]); F += [(c, o + k, o + (k + 1) % n) for k in range(n)]
    elif cap1:
        c = len(V); V = np.vstack([V, rings[-1].mean(0)]); F += [(c, o + k, o + (k + 1) % n) for k in range(n)]
    return V, np.array(F)
def frame_ring(c, d, ra, rb, n, up=(0, 0, 1)):
    d = np.asarray(d, float); d /= np.linalg.norm(d); u = np.cross(up, d)
    if np.linalg.norm(u) < 1e-6: u = np.array([1.0, 0, 0])
    u /= np.linalg.norm(u); v = np.cross(d, u)
    t = np.arange(n) / n * 2 * math.pi
    return np.asarray(c, float) + np.outer(np.cos(t), u) * ra + np.outer(np.sin(t), v) * rb
def horn(path, radii, n=7, up=(0, 0, 1)):
    """rings along a path (last point = the tip)"""
    P = [np.asarray(p, float) for p in path]; rings = []
    for i in range(len(P) - 1):
        d = P[i + 1] - P[i] if i == 0 else P[i + 1] - P[i - 1]
        rings.append(frame_ring(P[i], d, radii[i][0], radii[i][1], n, up))
    V, F = loft(rings, cap0=True, tip=P[-1])
    return V, F[:, ::-1] if signed_volume(V, F) < 0 else F
def tube(path, radii, n=6, up=(1, 0, 0)):
    P = [np.asarray(p, float) for p in path]; rings = []
    for i in range(len(P)):
        d = P[min(i + 1, len(P) - 1)] - P[max(i - 1, 0)]
        rings.append(frame_ring(P[i], d, radii[i][0], radii[i][1], n, up))
    V, F = loft(rings)
    return V, F[:, ::-1] if signed_volume(V, F) < 0 else F
def signed_volume(V, F):
    a, b, c = V[F[:, 0]], V[F[:, 1]], V[F[:, 2]]; return float(np.einsum('ij,ij->i', a, np.cross(b, c)).sum() / 6)
def outward(V, F): return (V, F[:, ::-1]) if signed_volume(V, F) < 0 else (V, F)
def ellipsoid(c, r, nu=8, nv=5):
    rings = []
    for j in range(1, nv):
        ph = -math.pi / 2 + math.pi * j / nv
        rings.append(ring_pts(c[0], c[1], r[0] * math.cos(ph), r[1] * math.cos(ph), c[2] + r[2] * math.sin(ph), nu))
    n = nu; V = np.concatenate(rings); F = []
    for i in range(len(rings) - 1):
        for k in range(n):
            k2 = (k + 1) % n; F += [(i * n + k, i * n + k2, (i + 1) * n + k2), (i * n + k, (i + 1) * n + k2, (i + 1) * n + k)]
    b = len(V); V = np.vstack([V, (c[0], c[1], c[2] - r[2]), (c[0], c[1], c[2] + r[2])]); o = (len(rings) - 1) * n
    F += [(b, (k + 1) % n, k) for k in range(n)] + [(b + 1, o + k, o + (k + 1) % n) for k in range(n)]
    return outward(V, np.array(F))
def box(x0, x1, y0, y1, z0, z1):
    V = np.array([(x, y, z) for x in (x0, x1) for y in (y0, y1) for z in (z0, z1)], float)
    F = np.array([(0, 1, 3), (0, 3, 2), (4, 6, 7), (4, 7, 5), (0, 4, 5), (0, 5, 1), (2, 3, 7), (2, 7, 6), (0, 2, 6), (0, 6, 4), (1, 5, 7), (1, 7, 3)])
    return outward(V, F)
def boulder(c, r, seed, sub=1):
    m = trimesh.creation.icosphere(subdivisions=sub); rs = np.random.default_rng(seed)
    V = np.asarray(m.vertices) * (1 + rs.uniform(-0.16, 0.16, (len(m.vertices), 1))); V = V * np.asarray(r) + np.asarray(c)
    V[:, 2] = np.maximum(V[:, 2], 0.5)
    return V, np.asarray(m.faces)
# ---------------------------------------------------------------- sheet
C = json.load(open(OUT + '/cfg.json')); SH, VW, bb, PAL = hk.analyse(C)
Rr, Gg, Bb = SH[..., 0], SH[..., 1], SH[..., 2]
pink = (Rr > 215) & (Gg > 70) & (Gg < 160) & (Bb > 95) & (Bb < 200) & (Rr > Gg + 60)
orange = (Rr > 215) & (Gg > 70) & (Gg < 150) & (Bb < 95)
coral = ndi.binary_closing(pink | orange, iterations=2)
# ---------------------------------------------------------------- core head (skull + face plane + beard mass): measured rows (px)
S_PROF = [  # side row, back col, front col (front = the face plane and the beard; nose, brow, gem are separate parts)
 (436, 520, 960), (424, 522, 958), (412, 534, 957), (400, 548, 946), (388, 548, 946), (376, 551, 943), (364, 564, 938), (352, 566, 930),
 (340, 574, 920), (328, 582, 909), (316, 581, 904), (304, 580, 903), (292, 578, 905), (280, 566, 903), (268, 564, 896), (256, 562, 891),
 (244, 562, 889), (232, 561, 887), (220, 560, 884), (208, 556, 880), (196, 557, 878), (184, 568, 877), (172, 566, 873), (160, 572, 866),
 (148, 590, 862), (136, 615, 860), (124, 640, 860), (112, 668, 858), (102, 700, 850), (96, 760, 815)]
F_PROF = [  # front row, half-width px (band ridge at rows 670-700; ears, blocks, spikes are separate parts)
 (950, 128), (930, 150), (900, 165), (880, 168), (850, 165), (820, 160), (800, 150), (780, 140), (760, 128), (740, 126), (720, 128),
 (705, 148), (690, 162), (680, 164), (670, 158), (650, 148), (630, 136), (610, 108), (598, 72), (590, 20)]
zs_s = np.array([sz(r) for r, _, _ in S_PROF]); xb_ = np.array([sx(b) for _, b, _ in S_PROF]); xf_ = np.array([sx(f) for _, _, f in S_PROF])
zs_f = np.array([fz(r) for r, _ in F_PROF]); hw_ = np.array([h for _, h in F_PROF]) / SF
back = lambda z: np.interp(z, zs_s, xb_); front = lambda z: np.interp(z, zs_s, xf_); halfw = lambda z: np.interp(z, zs_f, hw_)
EX = 2.5
def surf_x(y, z, sign=1):
    """the core's surface x at (y, z): front (sign 1) or back (sign -1)"""
    a = (front(z) - back(z)) / 2; cx = (front(z) + back(z)) / 2; b = halfw(z)
    t = np.clip(1 - (np.abs(y) / b) ** EX, 0, 1) ** (1 / EX)
    return cx + sign * a * t
NS = 28
ZR = [9.0, 13, 17, 22, 27, 32, 38, 44, 50, 56, 62, 67, 72, 77, 82, 86, 90, 93.5, 97, 101, 105, 109, 113, 117, 120, 122.3]
rings = []
for z in ZR:
    a = (front(z) - back(z)) / 2; cx = (front(z) + back(z)) / 2; b = halfw(z)
    rings.append(ring_pts(cx, 0, a, b, z, NS, ex=EX))
Vc, Fc = outward(*loft(rings))
# back-side stone blocks under the ears (front rows 815-900 are wider than the beard: hw 175-185 px)
blocks = []          # (they are boulders now, added with the rocks: two stacked stone blocks per side)
# ---- the cave: front arch (front cols 1076-1159, rows 892-951) and side arch (side cols 754-819, rows 373-436), one room inside
def arch_prism(c, hw, ztop, zbot, axis, a0, a1, n=10):
    pts = [(c - hw, zbot), (c + hw, zbot)] + [(c + hw * math.cos(t), (ztop - hw) + hw * math.sin(t)) for t in np.linspace(0, math.pi, n)]
    V = []; m = len(pts)
    for a in (a0, a1):
        for (u, z) in pts: V.append((a, u, z) if axis == 'x' else (u, a, z))
    F = []
    for k in range(m): k2 = (k + 1) % m; F += [(k, k2, m + k2), (k, m + k2, m + k)]
    for k in range(1, m - 1): F += [(0, k + 1, k), (m, m + k, m + k + 1)]
    return outward(np.array(V, float), np.array(F))
CY0, CY1 = fy(1076), fy(1159); CX0, CX1 = sx(754), sx(819)
cut = [arch_prism((CY0 + CY1) / 2, (CY1 - CY0) / 2, fz(892), 5.0, 'x', (CX0 + CX1) / 2, 100.0),
       arch_prism((CX0 + CX1) / 2, (CX1 - CX0) / 2, sz(373), 5.0, 'y', -80.0, 80.0),
       ellipsoid(((CX0 + CX1) / 2, (CY0 + CY1) / 2, 12.0), (19, 19, 22), 12, 7)]
tm = lambda VF: trimesh.Trimesh(VF[0], VF[1], process=True)
solid = tm((Vc, Fc))
cutter = trimesh.boolean.union([tm(c) for c in cut], engine='manifold')
head = trimesh.boolean.difference([solid, cutter], engine='manifold')
cen = head.triangles_center; _, dist, _ = trimesh.proximity.closest_point(cutter, cen)
dark = dist < 0.02
Vh = np.asarray(head.vertices); Fh = np.asarray(head.faces)
add('Core', Vh, Fh[~dark]); add('Cave', Vh, Fh[dark])
# ---------------------------------------------------------------- sand mound: a lens (the sheet draws the disc from slightly above)
MA, MB = 86.5, 82.5; RIM = 7.0
def mound():
    V = [(0, 0, RIM + 6.0)]; F = []; nr, ns = 6, 32; rr = [0.3, 0.55, 0.75, 0.88, 0.96, 1.0]
    for r in rr:
        for k in range(ns):
            t = k / ns * 2 * math.pi; V.append((MA * r * math.cos(t), MB * r * math.sin(t), RIM + 6.0 * (1 - r ** 2) ** 0.22))
    top = lambda i, k: 1 + (i - 1) * ns + k % ns
    for k in range(ns): F.append((0, top(1, k), top(1, k + 1)))
    for i in range(1, nr):
        for k in range(ns): F += [(top(i, k), top(i + 1, k), top(i + 1, k + 1)), (top(i, k), top(i + 1, k + 1), top(i, k + 1))]
    o = len(V); rb = [0.5, 0.8, 0.93]
    for r in rb:
        for k in range(ns):
            t = k / ns * 2 * math.pi; V.append((MA * r * math.cos(t), MB * r * math.sin(t), RIM * r ** 8))
    V.append((0, 0, 0)); cb = len(V) - 1; nb = len(rb)
    bot = lambda i, k: (o + (i - 1) * ns + k % ns) if i <= nb else top(nr, k)
    for k in range(ns): F.append((cb, bot(1, k + 1), bot(1, k)))
    for i in range(1, nb + 1):
        for k in range(ns): F += [(bot(i, k), bot(i + 1, k + 1), bot(i + 1, k)), (bot(i, k), bot(i, k + 1), bot(i + 1, k + 1))]
    return np.array(V), np.array(F)
add('Sand', *mound())
# ---------------------------------------------------------------- ears (side: cols 662-731, rows 213-301; front: out to hw 163 px)
for sgn in (-1, 1):
    add('Ear', *ellipsoid((sx(696), sgn * (163 / SF - 6.0), sz(257)), (11.3, 6.5, 14.5), 8, 5))
# ---------------------------------------------------------------- nose (side rows 190-266: tip col 916 at row 256; front: bridge 1100-1133, nostrils 1083-1147)
NO = [(190, 880, 4.5), (208, 887, 5.0), (220, 896, 5.2), (232, 904, 5.6), (244, 912, 7.0), (256, 916, 10.0), (266, 899, 10.0)]
rings = []
for row, tipc, hwn in NO:
    z = sz(row); xb0 = surf_x(hwn, z) - 3.0; xt = sx(tipc)
    rings.append(np.array([(xb0, -hwn * 1.15, z), (xt, -hwn * 0.55, z), (xt, hwn * 0.55, z), (xb0, hwn * 1.15, z)]))
add('Nose', *outward(*loft(rings)))
# ---------------------------------------------------------------- brows (front: cols 1016-1098 / 1129-1210, rows 670-705, outer ends lower; side: out to col 884)
for sgn in (-1, 1):
    ys = np.linspace(4.7, 30.0, 6); Vb = []; 
    for i, y in enumerate(ys):
        droop = 3.0 * (i / 5) ** 2; zt, zb2 = fz(670) - droop, fz(703) - droop; xo = surf_x(y, (zt + zb2) / 2) + 3.6; xi = xo - 6.5
        Vb += [(xi, sgn * y, zb2), (xo, sgn * y, zb2 + 1.0), (xo, sgn * y, zt - 0.6), (xi, sgn * y, zt)]
    Vb = np.array(Vb); Fb = []
    for i in range(5):
        for k in range(4): k2 = (k + 1) % 4; Fb += [(i * 4 + k, i * 4 + k2, (i + 1) * 4 + k2), (i * 4 + k, (i + 1) * 4 + k2, (i + 1) * 4 + k)]
    Fb += [(0, 2, 1), (0, 3, 2), (20, 21, 22), (20, 22, 23)]
    add('Brow', *outward(Vb, np.array(Fb)))
# ---------------------------------------------------------------- moustache (front path), braids with gold rings (front cols 989-1048 / 1187-1248, rows 867-905)
def on_face(pts_px, lift):
    out = []
    for (u, v) in pts_px:
        y, z = fy(u), fz(v); out.append((surf_x(y, z) + lift, y, z))
    return out
for mir in (False, True):
    m = (lambda u: 2 * FCX - u) if mir else (lambda u: u)
    path = on_face([(m(1108), 778), (m(1075), 772), (m(1045), 785), (m(1020), 808), (m(1003), 835)], 1.5)
    rad = [(r / SF, r / SF * 0.8) for r in (14, 20, 20, 15, 7)]
    add('Moustache', *tube(path, rad, 6))
    cxp = m(1018)
    path = on_face([(m(1042), 805), (m(1028), 838), (cxp, 868), (cxp, 905), (cxp, 930), (cxp, 955)], 2.0)
    rad = [(r / SF, r / SF * 0.75) for r in (20, 24, 25, 28, 26, 10)]
    add('Braid', *tube(path, rad, 7))
    y, z = fy(cxp), fz(886); x = surf_x(y, z) + 2.0
    add('Ring', *tube([(x, y, z - 6.2), (x, y, z + 6.2)], [(10.6, 9.0), (10.6, 9.0)], 8))
# ---------------------------------------------------------------- gem plate (front: cols 1077-1150, rows 578-653; side: out to col 866, the stone to 871)
gz0, gz1 = fz(653), fz(578); gzc = (gz0 + gz1) / 2; gh = (gz1 - gz0) / 2; gw = (1150 - 1077) / 2 / SF
xg = sx(866)
Vg = np.array([(xg, 0, gz1), (xg, gw, gzc), (xg, 0, gz0), (xg, -gw, gzc), (sx(871.5), 0, gzc), (xg - 14, 0, gzc)])
Fg = np.array([(0, 1, 4), (1, 2, 4), (2, 3, 4), (3, 0, 4), (1, 0, 5), (2, 1, 5), (3, 2, 5), (0, 3, 5)])
add('Gem', *outward(Vg, Fg))
# ---------------------------------------------------------------- crown: five horns (tips and edges measured in both elevations)
add('Spike', *horn([(22.5, 0, 119.0), (17.5, 0, 133.0), (12.5, 0, 143.0), (sx(781), 0, 148.7)], [(13.7, 11.8), (8.5, 7.0), (3.6, 3.0)], 8, up=(0, 1, 0)))
for sgn in (-1, 1):
    add('Spike', *horn([(-27, sgn * 33, 110.0), (-40, sgn * 41.5, 126.0), (-47, sgn * 46, 133.0), (sx(597), sgn * 48.4, 137.0)], [(16, 12), (9, 6.5), (4, 3)], 7, up=(0, sgn, 0)))
    # the small rear pair sweeps back from the temples (side: tip col 525, row 128; front: tip at hw 199 px, row 640)
    add('Spike', *horn([(-28, sgn * 44, 99.0), (-52, sgn * 54, 105.0), (-66, sgn * 59.5, 108.0), (sx(525), sgn * 63, 109.5)], [(6, 10), (4.2, 6.5), (2.2, 3.2)], 6))
# ---------------------------------------------------------------- rocks
for sgn in (-1, 1):
    add('Block', *boulder((-36, sgn * 46, 22), (25, 12.5, 17), 11 + sgn)); add('Block', *boulder((-42, sgn * 45, 41), (17, 11.5, 12), 14 + sgn))
add('Rock', *boulder((-59, -62, 15), (13, 10, 11), 3)); add('Rock', *boulder((-34, -70, 9), (8, 6, 6), 5))
add('Rock', *boulder((40, 67, 14), (13, 10, 10), 7)); add('Rock', *boulder((73.5, 30, 12.5), (8, 7, 7), 9))
# ---------------------------------------------------------------- corals: the sheet's own outlines as pillows. A coral seen in both elevations = two crossed pillows.
def cdt(mc, eps, interior):
    cs, hier = cv2.findContours(mc.astype(np.uint8), cv2.RETR_CCOMP, cv2.CHAIN_APPROX_NONE)
    verts, segs, holes = [], [], []
    for ci, c in enumerate(cs):
        poly = cv2.approxPolyDP(c, eps, True)[:, 0, :].astype(float)
        if len(poly) < 3: continue
        if hier[0][ci][3] != -1:
            hm_ = np.zeros(mc.shape, np.uint8); cv2.drawContours(hm_, [c], -1, 1, -1); hy, hx = np.where((hm_ > 0) & ~mc)
            if not len(hx): continue
            k = len(hx) // 2; holes.append((float(hx[k]), float(hy[k])))
        base = len(verts); verts += [tuple(p) for p in poly]; segs += [(base + k, base + (k + 1) % len(poly)) for k in range(len(poly))]
    if len(verts) < 3: return None
    seen = {v: i for i, v in reversed(list(enumerate(verts)))}
    for p in interior:
        if tuple(p) not in seen: seen[tuple(p)] = len(verts); verts.append(tuple(p))
    A = dict(vertices=np.array(verts, float), segments=np.array([(seen[verts[a]], seen[verts[b]]) for a, b in segs if seen[verts[a]] != seen[verts[b]]], np.int32))
    if holes: A['holes'] = np.array(holes, float)
    try: B = tr.triangulate(A, 'p')
    except Exception: return None
    if 'triangles' not in B or not len(B['triangles']): return None
    pts = [tuple(p) for p in B['vertices']]; tris = [tuple(int(v) for v in t) for t in B['triangles']]
    for it in range(3):
        ec = {}
        for t in tris:
            for a, b in ((t[0], t[1]), (t[1], t[2]), (t[2], t[0])): ec[(min(a, b), max(a, b))] = ec.get((min(a, b), max(a, b)), 0) + 1
        bnd = {v for e, n in ec.items() if n == 1 for v in e}; out = []; changed = False
        for t in tris:
            if all(v in bnd for v in t):
                m = len(pts); pts.append(tuple(np.mean([pts[v] for v in t], 0))); out += [(t[0], t[1], m), (t[1], t[2], m), (t[2], t[0], m)]; changed = True
            else: out.append(t)
        tris = out
        if not changed: break
    return np.array(pts), tris, bnd
def pillow(m, to3d, S, dscale=0.9, eps=2.0, step=14):
    ys, xs = np.where(m); y0, x0 = ys.min() - 2, xs.min() - 2; mc = m[y0:ys.max() + 3, x0:xs.max() + 3]
    d = ndi.distance_transform_edt(mc); sk = skeletonize(mc)
    if not sk.any(): return None
    idx = ndi.distance_transform_edt(~sk, return_distances=False, return_indices=True); w = np.maximum(d[idx[0], idx[1]], d)
    dep = np.sqrt(np.clip(w * w - (w - d) ** 2, 0, None)) * dscale
    sy_, sx_ = np.where(sk & (d > 2.0)); order = np.argsort(sy_ * 10000 + sx_); inter = [(float(sx_[k]), float(sy_[k])) for k in order[::step]]
    R_ = cdt(mc, eps, inter)
    if R_ is None: return None
    pts, tris, bnd = R_; V = []; fv, bv = {}, {}; px = []
    H_, W_ = dep.shape
    for v in sorted({v for t in tris for v in t}):
        u, vv = pts[v]; dd = 0.0 if v in bnd else max(1.0, float(dep[min(H_ - 1, max(0, int(vv))), min(W_ - 1, max(0, int(u)))])) * S
        fv[v] = len(V); V.append(to3d(u + x0, vv + y0, dd)); px.append((u + x0, vv + y0))
        if v in bnd: bv[v] = fv[v]
        else: bv[v] = len(V); V.append(to3d(u + x0, vv + y0, -dd)); px.append((u + x0, vv + y0))
    F = []
    for t in tris: F += [(fv[t[0]], fv[t[1]], fv[t[2]]), (bv[t[2]], bv[t[1]], bv[t[0]])]
    V = np.array(V); F = np.array(F)
    return (V, F[:, ::-1], np.array(px)) if signed_volume(V, F) < 0 else (V, F, np.array(px))
def comp(view, x0, x1, y0, y1):
    m = np.zeros_like(coral); m[y0 - 3:y1 + 4, x0 - 3:x1 + 4] = True; m &= coral & VW[view]
    lab, n = ndi.label(m); 
    if n == 0: return None
    sizes = ndi.sum(m, lab, range(1, n + 1)); return ndi.binary_fill_holes(lab == (np.argmax(sizes) + 1))
FRONT_CORALS = [  # front bbox (x0,x1,y0,y1) -> X of the pillow plane (from the matching side-view coral)
 ((1006, 1071, 522, 600), sx(736)), ((1151, 1206, 538, 598), sx(736)), ((923, 982, 598, 657), sx(676)), ((1242, 1300, 598, 643), sx(676)),
 ((930, 951, 794, 825), sx(616)), ((1277, 1340, 852, 922), -30.0), ((928, 979, 875, 932), sx(697))]
SIDE_CORALS = [   # side bbox -> Y of the pillow plane(s) (from the matching front-view corals)
 ((693, 779, 20, 104), [fy(1038), fy(1178)]), ((644, 708, 91, 183), [fy(952), fy(1271)]), ((590, 643, 278, 342), [fy(940)]),
 ((668, 726, 374, 430), [fy(953)]), ((536, 579, 375, 423), [-45.0])]
PILLOW_PX = {}
for bbx, X0 in FRONT_CORALS:
    m = comp('front', *bbx)
    if m is None: continue
    R_ = pillow(m, lambda u, v, d, X0=X0: (X0 + d, fy(u), fz(v)), 1 / SF)
    if R_: add('CoralF', R_[0], R_[1]); PILLOW_PX[len(PARTS) - 1] = ('front', R_[2])
for bbx, Ys in SIDE_CORALS:
    m = comp('side', *bbx)
    if m is None: continue
    for Y0 in Ys:
        R_ = pillow(m, lambda u, v, d, Y0=Y0: (sx(u), Y0 - d, sz(v)), 1 / SS)
        if R_: add('CoralS', R_[0], R_[1]); PILLOW_PX[len(PARTS) - 1] = ('side', R_[2])
# ---------------------------------------------------------------- write OBJ (y-up, like the gate expects)
def write_obj(path):
    with open(path, 'w') as fo:
        off = 1
        for i, (name, V, F) in enumerate(PARTS):
            fo.write(f'o {name}_{i}\n')
            for v in V: fo.write(f'v {v[0]:.4f} {v[2]:.4f} {-v[1]:.4f}\n')
            for f in F: fo.write(f'f {f[0]+off} {f[1]+off} {f[2]+off}\n')
            off += len(V)
if __name__ == '__main__' or True:
    write_obj(OUT + '/model.obj')
    cnt = {}
    for n, _, F in PARTS: cnt[n] = cnt.get(n, 0) + len(F)
    print('tris', sum(cnt.values()), cnt)
