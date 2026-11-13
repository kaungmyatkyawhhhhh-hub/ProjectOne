# MEGA BITE blue whale (giant prey) from mb_sheet_cr_whale.png. Model axes: X length (tail tip 0 -> nose L), Y side, Z up.
import sys; sys.path.insert(0, '/tmp/claude-0/lm2/cr')
import gk, numpy as np, json, cv2, math
from PIL import Image
from scipy import ndimage as ndi
from scipy.interpolate import PchipInterpolator
OUT = '/tmp/claude-0/lm2/cr/whale'; L = 100.0
SH, fg = gk.load('/tmp/claude-0/lm2/cr/whale.png'); H, W = fg.shape
side = gk.comp_in(fg, (30, 60, 1500, 500)); top = gk.comp_in(fg, (30, 530, 900, 990))
SX0, SX1 = 46, 1484; TX0, TX1 = 38, 885; TYC = 759.0
s = L / (SX1 - SX0); st = L / (TX1 - TX0)                         # studs per px: side view, top view
Zpx = 430.0                                                       # side-view row of z = 0 (below the belly)
sideX = lambda xs: (xs - SX0) * s; sideZ = lambda ys: (Zpx - ys) * s
topX = lambda xt: (xt - TX0) * st; topY = lambda yt: (TYC - yt) * st
side_px = lambda x, z: (SX0 + x / s, Zpx - z / s)
top_px = lambda x, y: (TX0 + x / st, TYC - y / st)
# ---------------- side profile of the BODY (no fluke, no flipper, no dorsal fin, no barnacle bumps)
cols = np.arange(322, SX1 + 1)
tp = np.array([np.where(side[:, x])[0].min() for x in cols], float); bt = np.array([np.where(side[:, x])[0].max() for x in cols], float)
def bridge(arr, x0, x1):
    keep = (cols < x0) | (cols > x1); f = PchipInterpolator(cols[keep], arr[keep]); a = arr.copy(); a[~keep] = f(cols[~keep]); return a
tp_body = bridge(tp, 628, 812)                                   # under the dorsal fin
tp_body = bridge(tp_body, 1276, 1402)                            # under the head barnacles
bt_body = bridge(bt, 646, 944)                                   # behind the flipper
bt_body = bridge(bt_body, 1118, 1196)                            # chin barnacles
tp_body = ndi.gaussian_filter1d(tp_body, 4); bt_body = ndi.gaussian_filter1d(bt_body, 4)
# ---------------- top-view half width of the body (flippers bridged)
tcols = np.arange(199, TX1 + 1)
hw = np.array([(lambda ys: (ys.max() - ys.min()) / 2 if len(ys) else 0)(np.where(top[640:880, x])[0]) for x in tcols], float)
keep = (tcols < 442) | (tcols > 668); hw = np.where(keep, hw, PchipInterpolator(tcols[keep], hw[keep])(tcols)); hw = ndi.gaussian_filter1d(hw, 3)
hw_at = lambda x: np.interp(TX0 + x / st, tcols, hw) * st       # studs, by model x
zt_at = lambda x: sideZ(np.interp(SX0 + x / s, cols, tp_body)); zb_at = lambda x: sideZ(np.interp(SX0 + x / s, cols, bt_body))
# ---------------- body loft
XP = sideX(322.0); XN = L
xs_st = np.r_[np.linspace(XP, 60, 12, endpoint=False), np.linspace(60, 90, 7, endpoint=False), [90, 93.5, 96.3, 98.2, 99.3, 99.85]]
NS = 16; rings = []
def ring(x, zt, zb, w, n_exp=2.25):
    zc = zb + (zt - zb) * 0.5; r = []
    for i in range(NS):
        a = 2 * math.pi * i / NS; c, sn = math.cos(a), math.sin(a)
        r.append((x, w * math.copysign(abs(c) ** (2 / n_exp), c), zc + (zt - zb) / 2 * math.copysign(abs(sn) ** (2 / n_exp), sn)))
    return r
# the tail stock behind the measured part: tapers into the fluke
zcP = (zt_at(XP) + zb_at(XP)) / 2; hP = (zt_at(XP) - zb_at(XP)) / 2; wP = hw_at(XP)
for x, k in ((topX(150.0), 0.34), (topX(176.0), 0.62)):
    rings.append(ring(x, zcP + hP * k, zcP - hP * k, wP * (0.5 + 0.5 * k)))
for x in xs_st:
    rings.append(ring(x, zt_at(x), zb_at(x), max(hw_at(x), 0.12)))
Vb, Fb = gk.loft(np.array(rings), True, True)
RC = np.array([[r[0][0], 0.0, (r[NS // 4][2] + r[3 * NS // 4][2]) / 2] for r in rings])       # ring centres
_cx = Vb[Fb].mean(1)[:, 0]
Fb = gk.orient(Vb, Fb, np.stack([np.clip(_cx, RC[0, 0] + 0.3, RC[-1, 0] - 0.3), np.zeros(len(Fb)), np.interp(_cx, RC[:, 0], RC[:, 2])], 1))
parts = [(Vb, Fb, 0)]
# ---------------- flippers (top view outlines), tilted down, the top-view outline kept
hw_px = lambda xt: np.interp(xt, tcols, hw)
yy, xx = np.mgrid[0:H, 0:W]
edge_up = TYC - hw_px(xx); edge_dn = TYC + hw_px(xx)
inx = (xx > 436) & (xx < 676)
flipU = top & inx & (yy < edge_up + 16); flipD = top & inx & (yy > edge_dn - 16)
PHI = math.radians(27); XR = topX(625.0)
z_root = zb_at(XR) + (zt_at(XR) - zb_at(XR)) * 0.40
def flip3d(sign):
    def f(u, v, t):
        x = topX(u); y = topY(v); e = abs(y) - hw_at(x) * 0.9
        z = z_root - max(e, -1.5) * math.tan(PHI)
        return (x, y + sign * t * math.sin(PHI), z + t * math.cos(PHI))
    return f
for m, sign, pid in ((flipU, 1, 1), (flipD, -1, 2)):
    V, F, UV = gk.pillow(m, 14, 0.75, flip3d(sign), pid, edge_pts=34, power=0.5)
    parts.append((V, F, pid))
# ---------------- fluke (top view), flat, at the tail stock's height
fluke = top & (xx < 212)
V, F, UV = gk.pillow(fluke, 13, 0.95, lambda u, v, t: (topX(u), topY(v), zcP + t), 3, edge_pts=46, power=0.55)
parts.append((V, F, 3))
# ---------------- dorsal fin (side view)
back_line = np.interp(xx, cols, tp_body)
dors = side & (xx > 632) & (xx < 808) & (yy < back_line + 9)
dors = ndi.binary_opening(dors, iterations=2)
V, F, UV = gk.pillow(dors, 12, 0.45, lambda u, v, t: (sideX(u), t, sideZ(v)), 4, edge_pts=18, power=0.6)
parts.append((V, F, 4))
# ---------------- barnacles (the sheet's beige clusters): short cones on the skin
rb = np.random.default_rng(4)
def skin(x, a, n_exp=2.25):
    zt, zb, w = zt_at(x), zb_at(x), hw_at(x); zc = zb + (zt - zb) / 2; c, sn = math.cos(a), math.sin(a)
    p = np.array([x, w * math.copysign(abs(c) ** (2 / n_exp), c), zc + (zt - zb) / 2 * math.copysign(abs(sn) ** (2 / n_exp), sn)])
    n = np.array([0, c / max(w, 0.1), sn / max((zt - zb) / 2, 0.1)]); return p, n / np.linalg.norm(n)
BV, BF = [], []
def barnacle(x, a, r):
    p, n = skin(x, a); u = np.cross(n, [1, 0, 0]); u /= np.linalg.norm(u); v = np.cross(n, u); k = 7; base = len(BV)
    for (rr, hh) in ((r, -0.25 * r), (r * 0.62, r * 0.75), (r * 0.34, r * 0.5)):
        for i in range(k):
            t = 2 * math.pi * i / k; BV.append(p + n * hh + (u * math.cos(t) + v * math.sin(t)) * rr)
    for i in range(k):
        j = (i + 1) % k
        BF.extend([[base + i, base + j, base + k + j], [base + i, base + k + j, base + k + i], [base + k + i, base + k + j, base + 2 * k + j], [base + k + i, base + 2 * k + j, base + 2 * k + i]])
    BV.append(p + n * r * 0.42); c0 = len(BV) - 1
    for i in range(k): BF.append([base + 2 * k + i, base + 2 * k + (i + 1) % k, c0])
for (x0, a0, cnt) in ((90.5, math.radians(62), 4), (90.5, math.radians(118), 4), (28.5, math.radians(8), 3), (28.5, math.radians(172), 3), (34.5, math.radians(-38), 4), (76.0, math.radians(-62), 3)):
    for j in range(cnt):
        barnacle(x0 + rb.uniform(-1.6, 1.6), a0 + rb.uniform(-0.09, 0.09), rb.uniform(0.5, 0.85))
BV = np.array(BV); BF = np.array(BF)
BF = gk.orient(BV, BF, np.stack([BV[BF].mean(1)[:, 0], np.zeros(len(BF)), np.interp(BV[BF].mean(1)[:, 0], RC[:, 0], RC[:, 2])], 1))
parts.append((BV, BF, 5))
# pillow faces: outward = away from the plate's mid surface
def orient_plate(V, F, axis_fn):
    c = V[F].mean(1); n = np.cross(V[F[:, 1]] - V[F[:, 0]], V[F[:, 2]] - V[F[:, 0]]); ref = axis_fn(c)
    flip = (n * ref).sum(1) < 0; F = F.copy(); F[flip] = F[flip][:, ::-1]; return F
nb1 = None
VV, FF, PP = [], [], []; off = 0
for (V, F, pid) in parts:
    if pid in (1, 2, 3):
        n = len(V); half = None
    VV.append(V); FF.append(F + off); PP += [pid] * len(F); off += len(V)
V = np.concatenate(VV); F = np.concatenate(FF); part = np.array(PP)
# plates: fix the facing with the triangle's own side (first half of a pillow = +t face)
import trimesh
m = trimesh.Trimesh(V, F, process=False)
for pid, up in ((1, np.array([0, math.sin(PHI), math.cos(PHI)])), (2, np.array([0, -math.sin(PHI), math.cos(PHI)])), (3, np.array([0, 0, 1.0])), (4, np.array([0, 1.0, 0]))):
    idx = np.where(part == pid)[0]; h = len(idx) // 2
    for j, k in enumerate(idx):
        want = up if j < h else -up
        n = np.cross(V[F[k, 1]] - V[F[k, 0]], V[F[k, 2]] - V[F[k, 0]])
        if n @ want < 0: F[k] = F[k][::-1]
# ---------------- colours: the sheet's own pixels
Cs_raw = gk.fill_colours(SH, side, 3); Ct = gk.fill_colours(SH, top, 3)
# the body's flank behind the flipper: rebuilt from the columns just outside it, at the same relative height
poly = [(1084, 232), (1060, 216), (1000, 222), (945, 238), (895, 260), (845, 294), (795, 338), (745, 378), (695, 410), (648, 446), (636, 482), (690, 498), (745, 502), (800, 496),
        (850, 480), (900, 454), (950, 412), (1000, 372), (1052, 330), (1084, 290)]
pm = ndi.binary_dilation(gk.poly_mask((H, W), poly), iterations=3)
Cs = Cs_raw.copy()
xl, xr = 622, 1096
tpi = lambda x: np.interp(x, cols, tp_body); bti = lambda x: np.interp(x, cols, bt_body)
ys_, xs_ = np.where(pm)
rel = (ys_ - tpi(xs_)) / np.maximum(bti(xs_) - tpi(xs_), 1)
k = np.clip((xs_ - xl) / (xr - xl), 0, 1)[:, None]
def col_at(xref, rel):
    y = np.clip(np.round(tpi(xref) + np.clip(rel, 0.02, 0.98) * (bti(xref) - tpi(xref))).astype(int), 0, H - 1)
    return np.stack([ndi.uniform_filter1d(Cs_raw[:, xref - 6:xref + 7].mean(1)[:, c], 3)[y] for c in range(3)], 1)
Cs[ys_, xs_] = col_at(xl, rel) * (1 - k) + col_at(xr, rel) * k
Cs = np.where(pm[..., None], cv2.GaussianBlur(Cs, (0, 0), 3), Cs)
chin = ndi.binary_dilation(gk.poly_mask((H, W), [(1112, 372), (1204, 372), (1204, 424), (1112, 424)]), iterations=2)
beige = (Cs[..., 0] > Cs[..., 2] - 10) & chin
idxb = ndi.distance_transform_edt(ndi.binary_dilation(beige, iterations=4), return_distances=False, return_indices=True); Cs = Cs[idxb[0], idxb[1]]
Image.fromarray(np.clip(Cs, 0, 255).astype(np.uint8)[60:500, 30:1500]).save(OUT + '/side_inpaint.jpg', quality=88)
def pick(Ci, u, v): return Ci[np.clip(np.round(v).astype(int), 0, H - 1), np.clip(np.round(u).astype(int), 0, W - 1)]
def sm(a, b, x): t = np.clip((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t)
def sampler(pid, pos, nrm):
    if pid == 0:
        zt = zt_at(pos[:, 0]); zb = zb_at(pos[:, 0])
        z = np.clip(pos[:, 2], zb + 0.35, zt - 0.3)                     # stay inside the painted flank
        xcl = np.clip(pos[:, 0], XP + 2.6, L - 0.9)
        cs = pick(Cs, *side_px(xcl, np.clip(z, zb_at(xcl) + 0.35, zt_at(xcl) - 0.3)))
        ycl = np.clip(pos[:, 1], -hw_at(pos[:, 0]) * 0.93, hw_at(pos[:, 0]) * 0.93)
        ct = pick(Ct, *top_px(pos[:, 0], ycl))
        wt = sm(0.50, 0.82, nrm[:, 2])[:, None] * (pos[:, 0] > XP + 1.5)[:, None]
        col = cs * (1 - wt) + ct * wt
        # throat grooves under the head half (the sheet draws them along the body)
        under = sm(0.35, 0.8, -nrm[:, 2]) * sm(48, 60, pos[:, 0]) * (1 - sm(93, 98, pos[:, 0]))
        stripe = (np.mod(pos[:, 1] / 1.25 + 0.5, 1.0) < 0.2)
        col = col * (1 - 0.13 * (under * stripe)[:, None])
        return col
    if pid in (1, 2, 3): return pick(Ct, *top_px(pos[:, 0], pos[:, 1]))
    if pid == 5:
        return np.where((nrm[:, 2:3] * 0 + 1) * 0 == 0, np.array([[226, 200, 150]]), 0) * np.clip(0.72 + 0.28 * np.abs(nrm @ np.array([0.3, 0.3, 0.9])), 0, 1)[:, None]
    return pick(Cs_raw, *side_px(pos[:, 0], pos[:, 2]))
P, ind, uvs, tex, vmap = gk.bake(V, F, part, sampler, T=1024)
tex = cv2.bilateralFilter(tex, 5, 24, 3)
Image.fromarray(tex).transpose(Image.FLIP_TOP_BOTTOM).save(OUT + '/MB_Whale_tex.png')
gk.write_obj(OUT + '/model.obj', P, ind, uvs, 'MB_Whale_tex.png')
np.savez(OUT + '/mesh.npz', P=P, ind=ind, uvs=uvs)
# ---------------- gates: body-only side outline, whole top outline
sideR = gk.raster(P, ind, lambda p: np.stack(side_px(p[:, 0], p[:, 2]), 1), (H, W)); topR = gk.raster(P, ind, lambda p: np.stack(top_px(p[:, 0], p[:, 1]), 1), (H, W))
bodyband = (xx > 330)
side_body = side & bodyband & ~(pm & (yy > np.interp(xx, cols, bt_body)))
sideR_b = sideR & bodyband & ~(gk.raster(P[np.isin(vmap, np.arange(len(V)))], ind[np.isin(part, (1, 2))], lambda p: np.stack(side_px(p[:, 0], p[:, 2]), 1), (H, W)) & (yy > np.interp(xx, cols, bt_body)))
g = dict(side_body_iou=gk.iou(sideR_b, side_body), top_iou=gk.iou(topR, top), tris=int(len(ind)), verts=int(len(P)),
         size=[round(float(P[:, i].max() - P[:, i].min()), 1) for i in range(3)])
ov = np.zeros((H, W, 3), np.uint8)
for R_, M_ in ((sideR_b, side_body), (topR, top)):
    ov[R_ & M_] = (235, 235, 235); ov[M_ & ~R_] = (40, 200, 60); ov[R_ & ~M_] = (230, 50, 50)
Image.fromarray(ov).save(OUT + '/mismatch.png')
# ---------------- rig: bones and weights by position
zc_mid = (zt_at(62) + zb_at(62)) / 2
B = [('Root', (62, 0, zc_mid), (70, 0, zc_mid), None), ('Tail1', (50, 0, zc_mid), (38, 0, zc_mid), 'Root'), ('Tail2', (38, 0, zc_mid), (27, 0, zcP), 'Tail1'),
     ('Tail3', (27, 0, zcP), (18.5, 0, zcP), 'Tail2'), ('Fluke', (18.5, 0, zcP), (8, 0, zcP), 'Tail3'),
     ('FlipL', (XR, hw_at(XR) * 0.86, z_root), (XR - 6, hw_at(XR) * 0.86 + 9, z_root - 4.5), 'Root'), ('FlipR', (XR, -hw_at(XR) * 0.86, z_root), (XR - 6, -hw_at(XR) * 0.86 - 9, z_root - 4.5), 'Root')]
names = [b[0] for b in B]; Wt = np.zeros((len(P), len(B)))
x = P[:, 0]; vpart = np.zeros(len(P), int)
for f_, pid in zip(ind, part): vpart[f_] = pid
t1 = 1 - sm(44, 56, x); t2 = 1 - sm(32, 44, x); t3 = 1 - sm(22, 32, x); t4 = 1 - sm(15, 22, x)
Wt[:, 0] = 1 - t1; Wt[:, 1] = t1 - t2; Wt[:, 2] = t2 - t3; Wt[:, 3] = t3 - t4; Wt[:, 4] = t4
for pid, bn in ((1, 'FlipL'), (2, 'FlipR')):
    msk = vpart == pid; Wt[msk] = 0; Wt[msk, names.index(bn)] = 1
Wt = np.clip(Wt, 0, 1); Wt /= Wt.sum(1, keepdims=True)
json.dump(dict(name='MB_Whale', tex='MB_Whale_tex.png', bones=[dict(name=b[0], head=b[1], tail=b[2], parent=b[3]) for b in B], weights=np.round(Wt, 3).tolist()), open(OUT + '/rig.json', 'w'))
json.dump(g, open(OUT + '/gates.json', 'w'), indent=1); print(json.dumps(g))
