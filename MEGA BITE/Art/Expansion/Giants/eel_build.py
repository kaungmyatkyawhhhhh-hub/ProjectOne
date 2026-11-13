# MEGA BITE colossal eel from mb_sheet_cr_eel.png. The wavy side view is straightened first (rectify.py). Axes: X length (tail 0 -> nose L), Y side, Z up.
import sys; sys.path.insert(0, '/tmp/claude-0/lm2/cr')
import gk, numpy as np, json, cv2, math
from PIL import Image
from scipy import ndimage as ndi
from scipy.interpolate import PchipInterpolator
OUT = '/tmp/claude-0/lm2/cr/eel'; L = 100.0
RC = np.array(Image.open(OUT + '/side_rect.png').convert('RGB')).astype(np.float32); HR, WR = RC.shape[:2]
d = np.sqrt(((RC - gk.MAG) ** 2).sum(-1)); side = ndi.binary_opening(d > 95, iterations=1)
lab, n = ndi.label(side); side = lab == (np.argmax(ndi.sum(side, lab, range(1, n + 1))) + 1)
SH, fg = gk.load('/tmp/claude-0/lm2/cr/eel.png'); H, W = fg.shape
top = gk.comp_in(fg, (0, 600, 1100, 920))
R_, G_, B_ = RC[..., 0], RC[..., 1], RC[..., 2]
yy, xx = np.mgrid[0:HR, 0:WR]
gold = side & (R_ > 190) & (G_ > 130) & (B_ < 110) & (R_ > B_ + 90)
pink = side & (R_ > 150) & (R_ > G_ + 45) & (R_ > B_ + 35) & (B_ > 55) & ~((G_ > 125) & (B_ < 110))
navy = ndi.binary_opening(side & (R_ < 75) & (G_ < 95) & (B_ > 70) & (B_ < 150) & (B_ > G_ + 15), iterations=2)
plate = ndi.binary_closing(gold & (xx > 1190) & (xx < 1370) & (yy > 95), iterations=3); plate = ndi.binary_fill_holes(plate)
lab, n = ndi.label(plate); plate = lab == (np.argmax(ndi.sum(plate, lab, range(1, n + 1))) + 1)
frill = ndi.binary_fill_holes(ndi.binary_closing(pink & (xx > 1090) & (xx < 1330) & (yy > 150), iterations=3)) & ~plate
lab, n = ndi.label(frill); frill = lab == (np.argmax(ndi.sum(frill, lab, range(1, n + 1))) + 1)
print('plate bbox', np.where(plate)[1].min(), np.where(plate)[1].max(), np.where(plate)[0].min(), np.where(plate)[0].max(), 'frill', np.where(frill)[1].min(), np.where(frill)[1].max(), np.where(frill)[0].min(), np.where(frill)[0].max())
# ---------------- body lines in the straightened view
X0B = 188                                                         # the body starts here (tail fin before it)
cols = np.arange(X0B, WR - 2)
ytop = np.array([np.where(side[:, x])[0].min() for x in cols], float); yb = np.array([np.where(side[:, x])[0].max() for x in cols], float)
fx0, fx1 = np.where(frill)[1].min() - 6, np.where(plate | frill)[1].max() + 8
keep = (cols < fx0) | (cols > fx1); yb = np.where(keep, yb, PchipInterpolator(cols[keep], yb[keep])(cols))
yn = np.full(len(cols), np.nan)
for i, x in enumerate(cols):
    ys = np.where(navy[:, x])[0]
    if len(ys) > 5: yn[i] = np.median(ys)
ok = ~np.isnan(yn) & (cols < 1290); yn = np.interp(cols, cols[ok], yn[ok])
yt = yn - 0.20 * (yb - yn); hk = np.clip((cols - 1335) / 55.0, 0, 1); yt = yt * (1 - hk) + ytop * hk
yt = ndi.gaussian_filter1d(yt, 6); yb = ndi.gaussian_filter1d(yb, 5)
yc = ndi.gaussian_filter1d((yt + yb) / 2, 30)                     # body mid line; the model is built straight on it
yc_full = np.interp(np.arange(WR), cols, yc)
s = L / WR                                                        # studs per px (straightened side)
sideX = lambda u: u * s; sideZ = lambda u, v: (np.interp(u, np.arange(WR), yc_full) - v) * s
side_px = lambda x, z: (x / s, np.interp(x / s, np.arange(WR), yc_full) - z / s)
zt_at = lambda x: (np.interp(x / s, cols, yc) - np.interp(x / s, cols, yt)) * s
zb_at = lambda x: (np.interp(x / s, cols, yc) - np.interp(x / s, cols, yb)) * s
# ---------------- width from the top view (frills and plates bridged), scaled so the head is 0.86 as wide as tall (front view)
TX0, TX1 = 32, 1069; ys_, xs_ = np.where(top); TYC = (ys_[xs_ > 300].min() + ys_[xs_ > 300].max()) / 2
tys = np.where(top[:, 500])[0]; TYC = (tys.min() + tys.max()) / 2
st = L / (TX1 - TX0)
tcols = np.arange(170, TX1 + 1)
hw = np.array([(lambda y_: (y_.max() - y_.min()) / 2 if len(y_) else 0)(np.where(top[:, x])[0]) for x in tcols], float)
keep = (tcols < 792) | (tcols > 962); hw = np.where(keep, hw, PchipInterpolator(tcols[keep], hw[keep])(tcols)); hw = ndi.gaussian_filter1d(hw, 4)
x_head = 93.0; h_head = zt_at(x_head) - zb_at(x_head)
KY = 0.86 * h_head / (2 * np.interp(TX0 + x_head / st, tcols, hw) * st)
hw_at = lambda x: np.interp(TX0 + x / st, tcols, hw) * st * KY
top_px = lambda x, y: (TX0 + x / st, TYC - y / (st * KY))
print('KY', round(float(KY), 3), 'head h', round(float(h_head), 2), 'w', round(float(2 * hw_at(x_head)), 2), 'mid h', round(float(zt_at(50) - zb_at(50)), 2), 'w', round(float(2 * hw_at(50)), 2))
# ---------------- body loft
XB = sideX(X0B + 4.0)
xs_st = np.r_[np.linspace(XB, 84, 22, endpoint=False), np.linspace(84, 96, 7, endpoint=False), [96, 97.6, 98.8, 99.5, 99.9]]
NS = 12; NE = 2.15; rings = []
def ring(x, zt, zb, w):
    zc = (zt + zb) / 2; r = []
    for i in range(NS):
        a = 2 * math.pi * i / NS; c, sn = math.cos(a), math.sin(a)
        r.append((x, w * math.copysign(abs(c) ** (2 / NE), c), zc + (zt - zb) / 2 * math.copysign(abs(sn) ** (2 / NE), sn)))
    return r
rings.append(ring(XB - 2.2, zt_at(XB) * 0.45, zb_at(XB) * 0.45, hw_at(XB) * 0.4))
for x in xs_st: rings.append(ring(x, zt_at(x), zb_at(x), max(hw_at(x), 0.1) if x < 99 else max(hw_at(x), 0.1) * (1 - (x - 99) * 0.5)))
RCn = np.array([[r[0][0], 0.0, (r[NS // 4][2] + r[3 * NS // 4][2]) / 2] for r in rings])
Vb, Fb = gk.loft(np.array(rings), True, True); cx = Vb[Fb].mean(1)[:, 0]
Fb = gk.orient(Vb, Fb, np.stack([np.clip(cx, RCn[0, 0] + 0.2, RCn[-1, 0] - 0.2), np.zeros(len(Fb)), np.interp(cx, RCn[:, 0], RCn[:, 2])], 1))
parts = [(Vb, Fb, 0)]
def ysurf(x, z, k=1.0):
    """half width of the body at height z (the skin), for things that sit on the flank"""
    zt, zb = zt_at(x), zb_at(x); zc = (zt + zb) / 2; zn = min(0.97, abs((z - zc) / max((zt - zb) / 2, 0.05)))
    return hw_at(x) * (1 - zn ** NE) ** (1 / NE) * k
# ---------------- crest (thin plate on the mid line) and tail fin
back = np.interp(xx, cols, yt)
crest = side & (xx >= X0B) & (xx < 1392) & (yy < back + 10); crest = ndi.binary_opening(crest, iterations=2)
lab, n = ndi.label(crest); crest = lab == (np.argmax(ndi.sum(crest, lab, range(1, n + 1))) + 1)
V, F, UV = gk.pillow(crest, 17, 0.32, lambda u, v, t: (sideX(u), t, float(sideZ(u, v))), 1, edge_pts=120, power=0.5, tmin=0.1); parts.append((V, F, 1))
tail = side & (xx < X0B + 22)
V, F, UV = gk.pillow(tail, 15, 0.42, lambda u, v, t: (sideX(u), t, float(sideZ(u, v))), 2, edge_pts=44, power=0.5, tmin=0.12); parts.append((V, F, 2))
# ---------------- gold plates and pink frills, one pair each side, lying on the skin; frills flare outward toward the back
xf_front = sideX(np.where(frill)[1].max())
def onskin(sign, flare):
    def f(u, v, t):
        x = sideX(u); z = float(sideZ(u, v)); y = ysurf(x, z) + 0.3 + (max(0.0, xf_front - x) * flare)
        return (x, sign * (y + t), z)
    return f
pid = 3
for sign in (1, -1):
    V, F, UV = gk.pillow(ndi.binary_dilation(plate, iterations=2), 13, 0.5, onskin(sign, 0.0), pid, edge_pts=40, power=0.35, tmin=0.3); parts.append((V, F, pid)); pid += 1
    V, F, UV = gk.pillow(frill, 14, 0.28, onskin(sign, 0.42), pid, edge_pts=46, power=0.5, tmin=0.08); parts.append((V, F, pid)); pid += 1
SIGN = {3: 1, 4: 1, 5: -1, 6: -1}
# ---------------- fangs: two cones per side on the lower lip
fang = side & (R_ > 225) & (G_ > 215) & (B_ > 170) & (xx > 1380)
lab, n = ndi.label(ndi.binary_opening(fang, iterations=1)); FV, FF = [], []
for i in range(1, n + 1):
    ys2, xs2 = np.where(lab == i)
    if len(ys2) < 40: continue
    x = sideX(xs2.mean()); zb_ = float(sideZ(xs2.mean(), ys2.max())); zt_ = float(sideZ(xs2.mean(), ys2.min())); r = (xs2.max() - xs2.min()) * s / 2
    for sign in (1, -1):
        y0 = sign * (ysurf(x, zb_) * 0.92); base = len(FV); k = 6
        for j in range(k): FV.append((x + math.cos(2 * math.pi * j / k) * r, y0 + math.sin(2 * math.pi * j / k) * r * 0.8, zb_ - 0.2))
        FV.append((x, y0 + sign * 0.15, zt_ + 0.15)); FV.append((x, y0, zb_ - 0.2))
        for j in range(k): FF += [[base + j, base + (j + 1) % k, base + k], [base + (j + 1) % k, base + j, base + k + 1]]
if FV:
    FV = np.array(FV); FF = np.array(FF); FF = gk.orient(FV, FF, np.repeat(FV.reshape(-1, 8, 3).mean(1), 12, axis=0)); parts.append((FV, FF, 7))
print('fangs', len(FV) // 8 if len(FV) else 0)
VV, FA, PP = [], [], []; off = 0
for (V, F, p) in parts: VV.append(V); FA.append(F + off); PP += [p] * len(F); off += len(V)
V = np.concatenate(VV); F = np.concatenate(FA); part = np.array(PP)
for p_, up in ((1, np.array([0, 1.0, 0])), (2, np.array([0, 1.0, 0])), (3, np.array([0, 1.0, 0])), (4, np.array([0, 1.0, 0])), (5, np.array([0, -1.0, 0])), (6, np.array([0, -1.0, 0]))):
    idx = np.where(part == p_)[0]; h = len(idx) // 2
    for j, k in enumerate(idx):
        want = up if j < h else -up
        n_ = np.cross(V[F[k, 1]] - V[F[k, 0]], V[F[k, 2]] - V[F[k, 0]])
        if n_ @ want < 0: F[k] = F[k][::-1]
# ---------------- colours
Cs_raw = gk.fill_colours(RC, side, 3); Ct = gk.fill_colours(SH, top, 3)
cover = ndi.binary_dilation(plate | frill, iterations=5); Cs = Cs_raw.copy()
for y in range(HR):                                               # the flank under the plate and frill: each row carried across from both sides
    xs2 = np.where(cover[y])[0]
    if not len(xs2): continue
    a, b = xs2.min() - 3, xs2.max() + 3; ca, cb = Cs_raw[y, max(a - 6, 0):a + 1].mean(0), Cs_raw[y, b:b + 7].mean(0)
    k = ((np.arange(a, b + 1) - a) / max(b - a, 1))[:, None]; Cs[y, a:b + 1] = ca * (1 - k) + cb * k
Cs = np.where(ndi.binary_dilation(cover, iterations=4)[..., None], cv2.GaussianBlur(Cs, (0, 0), 2.5), Cs)
fmask = ndi.binary_dilation(fang, iterations=3); idxf = ndi.distance_transform_edt(fmask, return_distances=False, return_indices=True); Cs = np.where(fmask[..., None], Cs[idxf[0], idxf[1]], Cs)
Image.fromarray(np.clip(Cs, 0, 255).astype(np.uint8)).save(OUT + '/side_inpaint.jpg', quality=88)
def pick(Ci, u, v): return Ci[np.clip(np.round(v).astype(int), 0, Ci.shape[0] - 1), np.clip(np.round(u).astype(int), 0, Ci.shape[1] - 1)]
def sm(a, b, x): t = np.clip((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t)
def sampler(p_, pos, nrm):
    if p_ == 0:
        xcl = np.clip(pos[:, 0], XB + 0.5, L - 0.5)
        z = np.clip(pos[:, 2], zb_at(xcl) + 0.22, zt_at(xcl) - 0.22)
        cs = pick(Cs, *side_px(xcl, z))
        ycl = np.clip(pos[:, 1], -hw_at(xcl) * 0.9, hw_at(xcl) * 0.9)
        ct = pick(Ct, *top_px(np.clip(xcl, 14, L - 0.6), ycl))
        wt = sm(0.62, 0.9, nrm[:, 2])[:, None]
        return cs * (1 - wt) + ct * wt
    if p_ == 7: return np.tile(np.array([[250, 240, 214]], np.float32), (len(pos), 1))
    return pick(Cs_raw, *side_px(pos[:, 0], pos[:, 2]))
P, ind, uvs, tex, vmap = gk.bake(V, F, part, sampler, T=1024)
tex = cv2.bilateralFilter(tex, 5, 24, 3)
Image.fromarray(tex).transpose(Image.FLIP_TOP_BOTTOM).save(OUT + '/MB_Eel_tex.png')
gk.write_obj(OUT + '/model.obj', P, ind, uvs, 'MB_Eel_tex.png'); np.savez(OUT + '/mesh.npz', P=P, ind=ind, uvs=uvs)
# ---------------- gates (straightened side view; top view with the width factor)
sideR = gk.raster(P, ind, lambda p: np.stack(side_px(p[:, 0], p[:, 2]), 1), (HR, WR)); topR = gk.raster(P, ind, lambda p: np.stack(top_px(p[:, 0], p[:, 1]), 1), (H, W))
tb = np.zeros_like(top); tb[:, 175:] = True
g = dict(side_iou=gk.iou(sideR, side), top_iou_whole=gk.iou(topR, top), top_iou_body=gk.iou(topR & tb, top & tb), tris=int(len(ind)), verts=int(len(P)), size=[round(float(P[:, i].max() - P[:, i].min()), 1) for i in range(3)], width_factor=round(float(KY), 3))
ov = np.zeros((HR, WR, 3), np.uint8); ov[sideR & side] = (235, 235, 235); ov[side & ~sideR] = (40, 200, 60); ov[sideR & ~side] = (230, 50, 50); Image.fromarray(ov).save(OUT + '/mismatch_side.png')
ov = np.zeros((H, W, 3), np.uint8); ov[topR & top] = (235, 235, 235); ov[top & ~topR] = (40, 200, 60); ov[topR & ~top] = (230, 50, 50); Image.fromarray(ov[600:920, 0:1100]).save(OUT + '/mismatch_top.png')
# ---------------- rig: Root at the head, seven spine bones back to the tail
J = [88, 77, 66, 55, 44, 33, 22, 11]
B = [('Root', (J[0], 0, 0), (J[0] + 8, 0, 0), None)] + [('Spine%d' % (i + 1), (J[i], 0, 0), (J[i + 1], 0, 0), 'Root' if i == 0 else 'Spine%d' % i) for i in range(7)]
x = P[:, 0]; Wt = np.zeros((len(P), len(B)))
t = [1 - sm(J[i] - 5.5, J[i] + 5.5, x) for i in range(1, 8)]          # past joint i (toward the tail)
Wt[:, 0] = sm(J[0] - 5.5, J[0] + 5.5, x)
past0 = 1 - Wt[:, 0]
Wt[:, 1] = past0 - t[0]
for i in range(1, 7): Wt[:, i + 1] = t[i - 1] - t[i]
Wt[:, 7] += t[6]
Wt = np.clip(Wt, 0, 1); Wt /= Wt.sum(1, keepdims=True)
json.dump(dict(name='MB_Eel', tex='MB_Eel_tex.png', bones=[dict(name=b[0], head=b[1], tail=b[2], parent=b[3]) for b in B], weights=np.round(Wt, 3).tolist()), open(OUT + '/rig.json', 'w'))
json.dump(g, open(OUT + '/gates.json', 'w'), indent=1); print(json.dumps(g))
