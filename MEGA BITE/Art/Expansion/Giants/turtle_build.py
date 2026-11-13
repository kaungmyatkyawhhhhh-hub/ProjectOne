# MEGA BITE giant turtle (tanky giant with a reef garden on its shell) from mb_sheet_cr_turtle.png.
# The TOP view is the contract (the sheet's "side" is a 3/4 picture). Axes: X length (tail 0 -> nose L), Y side, Z up, shell rim at z = 0.
import sys; sys.path.insert(0, '/tmp/claude-0/lm2/cr')
import gk, numpy as np, json, cv2, math
from PIL import Image
from scipy import ndimage as ndi
OUT = '/tmp/claude-0/lm2/cr/turtle'; L = 100.0
SH, fg = gk.load('/tmp/claude-0/lm2/cr/turtle.png'); H, W = fg.shape
top = gk.comp_in(fg, (60, 525, 770, 1010)); front = gk.comp_in(fg, (790, 560, 1500, 970))
R_, G_, B_ = SH[..., 0], SH[..., 1], SH[..., 2]; yy, xx = np.mgrid[0:H, 0:W]
gold = ndi.binary_closing(top & (R_ > 200) & (G_ > 130) & (G_ < 200) & (B_ < 100), iterations=3)
lab, n = ndi.label(gold); rim = lab == (np.argmax(ndi.sum(gold, lab, range(1, n + 1))) + 1)
pts = np.stack(np.where(rim)[::-1], 1).astype(np.int32); hull = cv2.convexHull(pts)
shell = np.zeros((H, W), np.uint8); cv2.fillConvexPoly(shell, hull, 1); shell = shell.astype(bool) & top
TX0, TX1 = 79, 752; s = L / (TX1 - TX0); ys_, xs_ = np.where(shell); TYC = (ys_.min() + ys_.max()) / 2
topX = lambda u: (u - TX0) * s; topY = lambda v: (TYC - v) * s
top_px = lambda x, y: (TX0 + x / s, TYC - y / s)
rest = ndi.binary_opening(top & ~ndi.binary_dilation(shell, iterations=1), iterations=2)
lab, n = ndi.label(rest); sz = ndi.sum(rest, lab, range(1, n + 1)); comps = {}
for i in np.argsort(-sz)[:6]:
    m = lab == i + 1; ys2, xs2 = np.where(m); cx, cy = xs2.mean(), ys2.mean()
    key = 'head' if cx > 600 else ('tail' if cx < 160 else (('FF' if cx > 400 else 'RF') + ('L' if cy < TYC else 'R')))
    comps[key] = m
print({k: int(v.sum()) for k, v in comps.items()})
HD, PD = 15.0, 6.2                                               # carapace height, plastron depth (studs)
dist = ndi.distance_transform_edt(shell); dmax = dist.max()
def prof(k): k = np.clip(np.asarray(k, float) / 0.9, 0, 1); return 0.6 * (1 - (1 - k) ** 2) + 0.4 * np.sqrt(1 - (1 - k) ** 2)      # a low round dome
def dome_z(u, v): return HD * float(prof(dist[int(np.clip(v, 0, H - 1)), int(np.clip(u, 0, W - 1))] / dmax))
parts = []            # (V, F, pid)
# ---------------- shell: carapace dome over the top-view outline + plastron bowl under it
V, F, UV = gk.pillow(shell, 30, HD, lambda u, v, t: (topX(u), topY(v), t if t >= 0 else t * PD / HD), 0, edge_pts=48, insets=(7, 20, 42), profile=prof)
nF = len(F) // 2; up = np.array([0, 0, 1.0])
for k in range(len(F)):
    nrm = np.cross(V[F[k, 1]] - V[F[k, 0]], V[F[k, 2]] - V[F[k, 0]])
    if (nrm @ up < 0) == (k < nF): F[k] = F[k][::-1]
parts.append((V, F[:nF], 0)); parts.append((V, F[nF:], 1))        # 0 carapace, 1 plastron (same vertices)
# ---------------- head and neck: loft from the top-view outline of the head
hm = comps['head']; hc = np.arange(np.where(hm)[1].min(), np.where(hm)[1].max() + 1)
hwid = np.array([(lambda y_: (y_.max() - y_.min()) / 2 if len(y_) else 0)(np.where(hm[:, x])[0]) for x in hc], float) * s
hmid = np.array([(lambda y_: (y_.max() + y_.min()) / 2 if len(y_) else TYC)(np.where(hm[:, x])[0]) for x in hc], float)
hwid = ndi.gaussian_filter1d(hwid, 3); hy_at = lambda x: topY(np.interp(TX0 + x / s, hc, ndi.gaussian_filter1d(hmid, 6))); hw_at = lambda x: np.interp(TX0 + x / s, hc, hwid)
XH0 = topX(hc[0]) - 5.0; XH1 = topX(hc[-1])
NSH = 12; rings = []; RCh = []
def hz(x):                                                       # head centre height and half height along x
    k = np.clip((x - XH0) / (XH1 - XH0), 0, 1); zc = -2.6 + 3.0 * k ** 0.8; hh = hw_at(max(x, topX(hc[0]) + 0.5)) * (0.74 + 0.16 * k); return zc, hh
for x in np.r_[np.linspace(XH0, XH1 - 5.5, 7), XH1 - 3.6, XH1 - 2.0, XH1 - 0.9, XH1 - 0.25]:
    zc, hh = hz(x); w = hw_at(max(x, topX(hc[0]) + 0.5)); ne = 2.5; r = []
    for i in range(NSH):
        a = 2 * math.pi * i / NSH; c, sn = math.cos(a), math.sin(a)
        r.append((x, hy_at(max(x, topX(hc[0]))) + w * math.copysign(abs(c) ** (2 / ne), c), zc + hh * math.copysign(abs(sn) ** (2 / ne), sn)))
    rings.append(r); RCh.append((x, hy_at(max(x, topX(hc[0]))), zc))
RCh = np.array(RCh); Vh, Fh = gk.loft(np.array(rings), True, True); cx = Vh[Fh].mean(1)[:, 0]
Fh = gk.orient(Vh, Fh, np.stack([np.clip(cx, RCh[0, 0] + 0.2, RCh[-1, 0] - 0.4), np.interp(cx, RCh[:, 0], RCh[:, 1]), np.interp(cx, RCh[:, 0], RCh[:, 2])], 1))
parts.append((Vh, Fh, 2))
# ---------------- flippers and tail: plates from the top view, roots pushed under the shell edge
def flip(key, pid, thick, tilt_deg, z0, step):
    m = comps[key] | (ndi.binary_dilation(comps[key], iterations=16) & shell & ndi.binary_dilation(~shell, iterations=22))
    m = ndi.binary_fill_holes(ndi.binary_closing(m, iterations=2)); ys2, xs2 = np.where(comps[key]); sgn = 1 if ys2.mean() < TYC else -1
    ph = math.radians(tilt_deg)
    def f(u, v, t):
        x, y = topX(u), topY(v); e = max(0.0, abs(y) - 16.0)
        return (x, y + sgn * t * math.sin(ph) * (0 if key == 'tail' else 1), z0 - e * math.tan(ph) + t * math.cos(ph))
    V, F, UV = gk.pillow(m, step, thick, f, pid, edge_pts=40, power=0.5)
    n2 = len(F) // 2
    for k in range(len(F)):
        nrm = np.cross(V[F[k, 1]] - V[F[k, 0]], V[F[k, 2]] - V[F[k, 0]])
        if (nrm[2] < 0) == (k < n2): F[k] = F[k][::-1]
    parts.append((V, F, pid))
flip('FFL', 3, 1.25, 16, -2.2, 17); flip('FFR', 4, 1.25, 16, -2.2, 17); flip('RFL', 5, 0.95, 8, -2.4, 17); flip('RFR', 6, 0.95, 8, -2.4, 17); flip('tail', 7, 0.9, 0, -2.6, 17)
# ---------------- the reef garden on the shell (the sheet paints it; here it is real): coral, sea grass, tube sponges, a clam
COL = {10: (244, 112, 124), 11: (60, 190, 130), 12: (250, 196, 50), 13: (150, 100, 220), 14: (40, 170, 170), 15: (250, 226, 170)}
rb = np.random.default_rng(7)
def on_shell(u, v, dz=0.0): return np.array([topX(u), topY(v), dome_z(u, v) + dz])
def add(Vx, Fx, pid): parts.append((Vx, Fx, pid))
base = on_shell(378, 770, -0.8)
def branch(p, d, ln, r, depth):
    q = p + d * ln; add(*gk.tube([p, (p + q) / 2 + rb.uniform(-0.25, 0.25, 3), q], [r, r * 0.9, r * 0.78], sides=5), 10)
    if depth > 0:
        for sgn in (-1, 1):
            side_ = np.cross(d, [rb.uniform(-1, 1), rb.uniform(-1, 1), 0.2]); side_ /= np.linalg.norm(side_)
            d2 = d * 0.78 + side_ * sgn * 0.6; d2 /= np.linalg.norm(d2); branch(q - d * 0.2, d2, ln * 0.74, r * 0.74, depth - 1)
for a_, tl in ((0.3, 0.32), (2.4, 0.3), (4.4, 0.36)):
    d = np.array([math.cos(a_) * tl, math.sin(a_) * tl, 1.0]); d /= np.linalg.norm(d); branch(base, d, 5.6, 1.15, 2)
for (u, v, hgt, lean) in ((300, 756, 8.6, -0.8), (316, 780, 6.6, 0.3), (330, 748, 7.6, 0.8), (296, 790, 5.2, -0.3), (322, 764, 5.8, 0.1)):
    p = on_shell(u, v, -0.4); add(*gk.tube([p, p + np.array([lean * 0.5, 0.3, hgt * 0.5]), p + np.array([lean * 1.6, 0.5, hgt])], [0.95, 0.8, 0.15], sides=4), 11)
for (u, v, hgt, r) in ((436, 762, 5.4, 1.5), (450, 778, 3.9, 1.25), (426, 780, 3.0, 1.1)):
    p = on_shell(u, v, -0.4); add(*gk.tube([p, p + np.array([0, 0, hgt * 0.6]), p + np.array([0.1, 0, hgt])], [r * 0.85, r, r * 1.02], sides=7), 12)
pc = on_shell(452, 812, 0.9)
Vc, Fc = gk.blob(pc, (4.6, 3.6, 1.7), sub=1); add(Vc, Fc, 13)
Vc, Fc = gk.blob(pc + np.array([-0.8, 0.3, 2.1]), (4.3, 3.4, 1.3), sub=1); Vc[:, 2] += (Vc[:, 0] - pc[0]) * 0.3; add(Vc, Fc, 13)
Vc, Fc = gk.blob(pc + np.array([1.6, -0.3, 1.3]), (1.5, 1.8, 0.8), sub=1); add(Vc, Fc, 15)
for (u, v, r) in ((404, 798, 3.0), (352, 802, 2.3), (336, 788, 1.7), (398, 742, 1.9)):
    Vc, Fc = gk.blob(on_shell(u, v, 0.25), (r, r * 0.9, r * 0.55), sub=1, seed=int(u), rough=0.08); add(Vc, Fc, 14)
# two little reef fish that swim over the garden (cut from the sheet's 3/4 picture)
sideim = gk.comp_in(fg, (740, 15, 910, 110)); lab, n = ndi.label(sideim); szf = ndi.sum(sideim, lab, range(1, n + 1)); FISH = []
for j, i in enumerate(np.argsort(-szf)[:2]):
    m = ndi.binary_fill_holes(lab == i + 1); ys2, xs2 = np.where(m); cu, cv_ = xs2.mean(), ys2.mean(); ln = (xs2.max() - xs2.min())
    k = (9.0 if ln > 70 else 7.2) / ln; home = on_shell(*((512, 760) if ln > 70 else (452, 716)), 9.5 if ln > 70 else 13.0)
    V, F, UV = gk.pillow(m, 12, 0.85, lambda u, v, t, cu=cu, cv_=cv_, k=k, home=home: (home[0] + (u - cu) * k, home[1] + t, home[2] + (cv_ - v) * k), 20 + j, edge_pts=22, power=0.5)
    n2 = len(F) // 2
    for q in range(len(F)):
        nrm = np.cross(V[F[q, 1]] - V[F[q, 0]], V[F[q, 2]] - V[F[q, 0]])
        if (nrm[1] < 0) == (q < n2): F[q] = F[q][::-1]
    parts.append((V, F, 20 + j)); FISH.append(dict(cu=cu, cv=cv_, k=k, home=home.tolist()))
# ---------------- merge (the two shell halves share vertices)
VV, FA, PP = [], [], []; off = 0; seen = None
for (V, F, p) in parts:
    if p == 1: FA.append(F + off - len(V)); PP += [p] * len(F); continue
    VV.append(V); FA.append(F + off); PP += [p] * len(F); off += len(V)
V = np.concatenate(VV); F = np.concatenate(FA); part = np.array(PP)
for p in set(COL) :
    idx = np.where(part == p)[0]
# ---------------- colours
Ct_raw = gk.fill_colours(SH, top, 3)
# the painted garden and fish come off the shell picture (they are real now): keep only shell greens and golds, fill the rest from them
sat = Ct_raw.max(-1) - Ct_raw.min(-1); r_, g_, b_ = Ct_raw[..., 0], Ct_raw[..., 1], Ct_raw[..., 2]
olive = (g_ > r_ - 12) & (g_ > b_ + 45) & (r_ > 90) & (r_ < 200) & (g_ < 205); goldc = (r_ > 195) & (g_ > 125) & (g_ < 205) & (b_ < 105)
gz = shell & (xx > 280) & (xx < 550) & (yy > 690) & (yy < 845)
bad = gz & ~ndi.binary_opening(olive | goldc, iterations=1); bad = ndi.binary_dilation(bad, iterations=4) & gz
keepc = shell & olive & ~bad
idxc = ndi.distance_transform_edt(~keepc, return_distances=False, return_indices=True)
lum = Ct_raw.mean(-1); ol = olive & shell & ~bad
med = np.median(lum[ol & gz]); shadow = gz & olive & (lum < med * 0.86)             # the garden's painted shadows
seams = ndi.binary_opening(rim, iterations=2)                                  # the real seam net (thick lines); thin yellow bits are garden paint
stray = gz & goldc & ~ndi.binary_dilation(seams, iterations=4)
bad = (ndi.binary_dilation(bad | ndi.binary_opening(shadow, iterations=1), iterations=3) & gz & ~ndi.binary_dilation(seams, iterations=1)) | ndi.binary_dilation(stray, iterations=2)
keepc = shell & olive & ~bad & (lum > med * 0.9)
idxc = ndi.distance_transform_edt(~keepc, return_distances=False, return_indices=True)
Ct = np.where(bad[..., None], cv2.GaussianBlur(Ct_raw[idxc[0], idxc[1]], (0, 0), 6), Ct_raw)
Image.fromarray(np.clip(Ct, 0, 255).astype(np.uint8)[520:1015, 60:775]).save(OUT + '/top_clean.jpg', quality=88)
Cf = gk.fill_colours(SH, front, 3); Cside = gk.fill_colours(SH, fg, 2)
# the head in the front view (face): centre column and rows, found from the picture
FCX, FY0, FY1, FHW = 1155.0, 668.0, 806.0, 82.0
def pick(Ci, u, v): return Ci[np.clip(np.round(v).astype(int), 0, H - 1), np.clip(np.round(u).astype(int), 0, W - 1)]
def sm(a, b, x): t = np.clip((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t)
CREAM = np.array([240, 224, 160], np.float32)
def sampler(p, pos, nrm):
    if p == 0: return pick(Ct, *top_px(pos[:, 0], pos[:, 1]))
    if p == 1:
        e = np.minimum(np.abs(np.mod(pos[:, 0] - 30, 11.5) - 5.75), np.abs(np.abs(pos[:, 1]) - 0.0) + 0.0 * pos[:, 0])
        line = (np.abs(np.mod(pos[:, 0] - 30, 11.5)) < 0.45) | (np.abs(pos[:, 1]) < 0.4)
        rimk = sm(0.0, 1.6, -pos[:, 2])[:, None]
        c = CREAM[None, :] * (1 - 0.14 * line[:, None]) * (0.86 + 0.14 * np.clip(-nrm[:, 2:3], 0, 1))
        return pick(Ct, *top_px(pos[:, 0], pos[:, 1])) * (1 - rimk) + c * rimk
    if p == 2:
        ct = pick(Ct_raw, *top_px(np.minimum(pos[:, 0], XH1 - 0.5), np.clip(pos[:, 1] - hy_at(XH1 - 8), -hw_at(pos[:, 0]) * 0.9, hw_at(pos[:, 0]) * 0.9) + hy_at(XH1 - 8)))
        zc, hh = hz(XH1 - 6.0); wH = hw_at(XH1 - 6.0)
        u = FCX - (pos[:, 1] - hy_at(XH1 - 6)) / wH * FHW; v = FY0 + (zc + hh - pos[:, 2]) / (2 * hh) * (FY1 - FY0)
        cf = pick(Cf, u, np.clip(v, FY0 + 3, FY1 - 3))
        wf = (sm(0.05, 0.5, nrm[:, 0]) * sm(XH1 - 11.5, XH1 - 8.5, pos[:, 0]))[:, None]
        wt = sm(0.12, 0.5, nrm[:, 2])[:, None]
        under = sm(0.1, 0.6, -nrm[:, 2])[:, None]
        cheek = np.array([226, 214, 150], np.float32)[None, :]
        base = ct * wt + cheek * (1 - wt); base = base * (1 - under) + CREAM[None, :] * 0.96 * under
        return base * (1 - wf) + cf * wf
    if p in (3, 4, 5, 6, 7):
        c = pick(Ct_raw, *top_px(pos[:, 0], pos[:, 1]))
        return np.where(nrm[:, 2:3] < -0.2, c * 0.45 + CREAM[None, :] * 0.55, c)
    if p in COL:
        return np.array(COL[p], np.float32)[None, :] * np.clip(0.8 + 0.22 * nrm[:, 2:3] + 0.06 * nrm[:, 0:1], 0.62, 1.05)
    if p >= 20:
        f = FISH[p - 20]; return pick(Cside, f['cu'] + (pos[:, 0] - f['home'][0]) / f['k'], f['cv'] - (pos[:, 2] - f['home'][2]) / f['k'])
    return np.tile(CREAM, (len(pos), 1))
P, ind, uvs, tex, vmap = gk.bake(V, F, part, sampler, T=1024)
tex = cv2.bilateralFilter(tex, 5, 22, 3)
Image.fromarray(tex).transpose(Image.FLIP_TOP_BOTTOM).save(OUT + '/MB_Turtle_tex.png')
gk.write_obj(OUT + '/model.obj', P, ind, uvs, 'MB_Turtle_tex.png'); np.savez(OUT + '/mesh.npz', P=P, ind=ind, uvs=uvs)
# ---------------- gate: top outline against the sheet's top view (garden and fish are inside the outline)
topR = gk.raster(P, ind, lambda p: np.stack(top_px(p[:, 0], p[:, 1]), 1), (H, W))
g = dict(top_iou=gk.iou(topR, top), tris=int(len(ind)), verts=int(len(P)), size=[round(float(P[:, i].max() - P[:, i].min()), 1) for i in range(3)])
ov = np.zeros((H, W, 3), np.uint8); ov[topR & top] = (235, 235, 235); ov[top & ~topR] = (40, 200, 60); ov[topR & ~top] = (230, 50, 50); Image.fromarray(ov[520:1015, 60:775]).save(OUT + '/mismatch_top.png')
# ---------------- rig (rigid parts; the neck blends into the shell)
vpart = np.zeros(len(P), int)
for f_, p in zip(ind, part): vpart[f_] = p
def root_of(key):
    ys2, xs2 = np.where(comps[key]); d = (xs2 - (TX0 + 50 / s)) ** 2 + (ys2 - TYC) ** 2; i = d.argmin(); j = d.argmax()
    return (topX(xs2[i]), topY(ys2[i]), -2.2), (topX(xs2[j]), topY(ys2[j]), -4.0)
B = [('Root', (50, 0, 0), (58, 0, 0), None), ('Neck', (XH0 + 2.0, 0, -2.0), (XH0 + 9, 0, -1.0), 'Root'), ('Head', (XH0 + 9, 0, -1.0), (XH1, 0, 0.4), 'Neck')]
for key, bn in (('FFL', 'FlipFL'), ('FFR', 'FlipFR'), ('RFL', 'FlipRL'), ('RFR', 'FlipRR'), ('tail', 'Tail')):
    h_, t_ = root_of(key); B.append((bn, h_, t_, 'Root'))
for j, f in enumerate(FISH): B.append(('Fish%d' % (j + 1), tuple(f['home']), (f['home'][0] + 2, f['home'][1], f['home'][2]), 'Root'))
names = [b[0] for b in B]; Wt = np.zeros((len(P), len(B))); Wt[:, 0] = 1
hd = vpart == 2; k1 = sm(XH0 + 0.5, XH0 + 5.0, P[:, 0]); k2 = sm(XH0 + 6.5, XH0 + 11.5, P[:, 0])
Wt[hd, 0] = (1 - k1)[hd]; Wt[hd, 1] = (k1 - k2)[hd]; Wt[hd, 2] = k2[hd]
for p, bn in ((3, 'FlipFL'), (4, 'FlipFR'), (5, 'FlipRL'), (6, 'FlipRR'), (7, 'Tail'), (20, 'Fish1'), (21, 'Fish2')):
    m = vpart == p; Wt[m] = 0; Wt[m, names.index(bn)] = 1
Wt = np.clip(Wt, 0, 1); Wt /= Wt.sum(1, keepdims=True)
json.dump(dict(name='MB_Turtle', tex='MB_Turtle_tex.png', bones=[dict(name=b[0], head=b[1], tail=b[2], parent=b[3]) for b in B], weights=np.round(Wt, 3).tolist()), open(OUT + '/rig.json', 'w'))
json.dump(g, open(OUT + '/gates.json', 'w'), indent=1); print(json.dumps(g))
