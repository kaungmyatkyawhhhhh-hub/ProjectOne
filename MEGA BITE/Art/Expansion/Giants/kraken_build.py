# MEGA BITE Kraken (boss squid) from mb_sheet_cr_kraken.png. The sheet's views are 3/4 pictures with hand-curled arms, so:
# mantle + head = a measured profile turned round the body axis, painted with the sheet's own side and top pictures;
# the 8 arms and 2 long tentacles are tubes on designed 3D curls (the sheet's layout: arms splay round the mouth, tips curl outward);
# suckers, cuffs and fins are painted by rule in the sheet's colours. Axes: X length (club tips 0 -> mantle tip 100), Y side, Z up.
import sys; sys.path.insert(0, '/tmp/claude-0/lm2/cr')
import gk, numpy as np, json, cv2, math
from PIL import Image
from scipy import ndimage as ndi
from scipy.interpolate import PchipInterpolator
OUT = '/tmp/claude-0/lm2/cr/kraken'
SH, fg = gk.load('/tmp/claude-0/lm2/cr/kraken.png'); H, W = fg.shape
R_, G_, B_ = SH[..., 0], SH[..., 1], SH[..., 2]; yy, xx = np.mgrid[0:H, 0:W]
side = gk.comp_in(fg, (0, 0, 1536, 500)); top = gk.comp_in(fg, (0, 560, 940, 960))
orange = (R_ > 215) & (G_ > 95) & (G_ < 190) & (B_ < 95) & (R_ > G_ + 40)
yellow = (R_ > 220) & (G_ > 190) & (B_ < 110); redm = (R_ > 120) & (G_ < 110) & (B_ < 125) & (R_ > G_ + 60)
peach = (R_ > 225) & (G_ > 120) & (G_ < 200) & (B_ > 85) & (B_ < 170); dark = (R_ < 90) & (G_ < 60)
def biggest(m):
    lab, n = ndi.label(m); return lab == (np.argmax(ndi.sum(m, lab, range(1, n + 1))) + 1)
body_s = biggest(ndi.binary_fill_holes(ndi.binary_opening(ndi.binary_closing(side & (redm | peach | yellow | dark) & ~orange & (xx > 930), iterations=3), iterations=4)))
body_t = biggest(ndi.binary_fill_holes(ndi.binary_opening(ndi.binary_closing(top & (redm | peach | yellow) & ~orange & (xx > 500), iterations=3), iterations=4)))
PROF = PchipInterpolator([62, 63.5, 66, 68.5, 70, 71.2, 75, 79, 83.7, 86.3, 89, 91.7, 94.3, 97, 99, 100], [4.8, 6.0, 6.9, 6.7, 6.2, 7.3, 7.7, 7.4, 6.3, 5.3, 3.6, 2.5, 1.7, 1.0, 0.45, 0.12])
r_at = lambda x: PROF(np.clip(x, 62, 100))
PXS = 15.0
side_u = lambda x: 1505 - (100 - x) * PXS
cy_s = lambda u: np.interp(u, [940, 1150, 1505], [268, 268, 256])
top_u = lambda x: np.where(x >= 70, 575 + (x - 70) * 11.5, 505 + (x - 62) * 8.75)
tcols = np.arange(505, 921); hwt = np.array([(lambda y_: (y_.max() - y_.min()) / 2 if len(y_) else 8)(np.where(body_t[:, c])[0]) for c in tcols], float); hwt = np.maximum(ndi.gaussian_filter1d(hwt, 6), 8)
parts = []; META = []           # META per part: per-vertex (group, t)
def add(V, F, pid, grp=0, t=None):
    parts.append((np.array(V, float), np.array(F), pid)); META.append(np.stack([np.full(len(V), grp, float), np.zeros(len(V)) if t is None else np.array(t, float)], 1))
# ---------------- mantle + head
NS = 14; XS = [62, 63.2, 64.6, 66.4, 68.4, 70, 71.1, 73, 76, 80, 83.7, 86.3, 89, 91.7, 94.3, 97, 98.9, 99.85]
rings = np.array([[(x, r_at(x) * math.cos(2 * math.pi * i / NS), r_at(x) * math.sin(2 * math.pi * i / NS)) for i in range(NS)] for x in XS])
Vb, Fb = gk.loft(rings, True, True); cx = Vb[Fb].mean(1)[:, 0]
Fb = gk.orient(Vb, Fb, np.stack([np.clip(cx, 62.3, 99.5), np.zeros(len(Fb)), np.zeros(len(Fb))], 1)); add(Vb, Fb, 0, 0)
EYE = (67.8, 0.3)
for sgn in (1, -1):
    c = np.array([EYE[0], sgn * (float(r_at(EYE[0])) - 0.75), EYE[1]]); Ve, Fe = gk.blob(c, (3.1, 1.55, 3.0), sub=2); Fe = gk.orient(Ve, Fe, c - np.array([0, sgn * 2.0, 0])); add(Ve, Fe, 2, 0)
# ---------------- fins: two flat kites on the mantle's sides
SC = 0.1; fm = np.zeros((260, 420), np.uint8)
kite = [(75.0, float(r_at(75)) - 1.2), (78.6, float(r_at(78.6)) + 7.4), (84.0, float(r_at(84)) + 6.6), (99.7, 0.2), (97, 0.3), (89, float(r_at(89)) - 1.5), (80, float(r_at(80)) - 2.5)]
cv2.fillPoly(fm, [np.array([((x - 62) / SC, y / SC + 20) for x, y in kite], np.int32)], 1)
for sgn in (1, -1):
    V, F, UV = gk.pillow(fm.astype(bool), 22, 0.7, lambda u, v, t, sgn=sgn: (62 + u * SC, sgn * (v - 20) * SC, t), 1, edge_pts=30, power=0.5)
    n2 = len(F) // 2
    for k in range(len(F)):
        nrm = np.cross(V[F[k, 1]] - V[F[k, 0]], V[F[k, 2]] - V[F[k, 0]])
        if (nrm[2] < 0) == (k < n2): F[k] = F[k][::-1]
    add(V, F, 1, 0)
# ---------------- arms: splay round the mouth, curl outward at the tips
rb = np.random.default_rng(11); ARMS = []
def arm_path(phi, Ls, rho0, theta, psi0, drift, r0):
    er = np.array([0, math.cos(phi), math.sin(phi)]); et = np.array([0, -math.sin(phi), math.cos(phi)]); bx = np.array([-1.0, 0, 0])
    Lc = theta * rho0 / 1.768; Ltot = Ls + Lc
    taus = np.r_[[0, 0.3, 4.3, 4.6], np.linspace(4.6, Ls, 5)[1:-1], Ls + Lc * (1 - np.exp(-np.linspace(0, 1, 14) * 1.3)) / (1 - math.exp(-1.3))]
    fine = np.linspace(0, Ltot, 400); psi = np.zeros(400)
    for i in range(1, 400):
        tau = fine[i]
        if tau < Ls: psi[i] = psi0 * (1 - 0.62 * (3 * (tau / Ls) ** 2 - 2 * (tau / Ls) ** 3))
        else: psi[i] = psi[i - 1] + (fine[i] - fine[i - 1]) / (rho0 * (1 - 0.72 * (tau - Ls) / Lc))
    psi[0] = psi0
    head = np.cos(psi)[:, None] * bx + np.sin(psi)[:, None] * er + (drift * np.sin(fine / Ltot * 3.0))[:, None] * et
    head /= np.linalg.norm(head, axis=1, keepdims=True)
    pos = np.cumsum(head * np.gradient(fine)[:, None], axis=0) + np.array([63.0, 0, 0]) + er * 3.9
    U = -(-np.sin(psi)[:, None] * bx + np.cos(psi)[:, None] * er)                     # sucker side: toward the body axis at the root
    rad = r0 * (0.16 + 0.84 * (1 - fine / Ltot) ** 0.85)
    return dict(fine=fine, pos=pos, T=head, U=U, rad=rad, taus=taus, L=Ltot)
def tube_from(path, sides, grp, pid, bulge=None):
    idx = [int(np.searchsorted(path['fine'], t)) for t in path['taus']]; idx[-1] = len(path['fine']) - 1; rg = []; tt = []
    for k in idx:
        p, T, U = path['pos'][k], path['T'][k], path['U'][k]; Bn = np.cross(T, U); rr = path['rad'][k] * (bulge(path['fine'][k]) if bulge else 1.0)
        rg.append([p + (U * math.cos(2 * math.pi * j / sides) + Bn * math.sin(2 * math.pi * j / sides)) * rr for j in range(sides)]); tt += [path['fine'][k] / path['L']] * sides
    V, F = gk.loft(np.array(rg), True, True); tt += [0.0, 1.0]
    c = V[F].mean(1); d = ((c[:, None, :] - path['pos'][None, ::8, :]) ** 2).sum(-1).argmin(1)
    add(V, gk.orient(V, F, path['pos'][::8][d]), pid, grp, tt)
for i in range(8):
    phi = math.radians(22.5 + 45 * i) + rb.uniform(-0.07, 0.07)
    p = arm_path(phi, rb.uniform(15, 21), rb.uniform(4.6, 6.4), rb.uniform(1.3, 1.8) * math.pi, math.radians(rb.uniform(26, 40)), rb.uniform(-0.14, 0.14), 2.75)
    ARMS.append(p); tube_from(p, 6, 10 + i, 10 + i, bulge=lambda tau: 1.16 if 0.25 < tau < 4.4 else 1.0)
# ---------------- two long tentacles with clubs
TENT = []
for j, sgn in enumerate((1, -1)):
    fine = np.linspace(0, 49, 300); x = 62.4 - fine * (48.2 / 49)
    y = sgn * (1.9 + 3.6 * (1 - np.cos(np.pi * np.clip(fine / 30, 0, 1))) / 2); z = -1.0 - 1.6 * np.sin(np.pi * fine / 49) + (0.9 if sgn > 0 else -0.4) * np.sin(2 * np.pi * fine / 49)
    pos = np.stack([x, y, z], 1); T = np.gradient(pos, axis=0); T /= np.linalg.norm(T, axis=1, keepdims=True)
    U = np.tile(np.array([0, 0, -1.0]), (300, 1)); U = U - T * (U * T).sum(1, keepdims=True); U /= np.linalg.norm(U, axis=1, keepdims=True)
    p = dict(fine=fine, pos=pos, T=T, U=U, rad=np.full(300, 1.2), taus=np.linspace(0, 49, 12), L=49.0); TENT.append(p)
    tube_from(p, 5, 20 + j, 20 + j, bulge=lambda tau: 1.5 if tau > 47.6 else 1.0)
    # the club: a flat spindle from the tentacle's end, toward -X
    e = pos[-1]; rg = []
    for k, tq in enumerate(np.linspace(0, 1, 9)):
        w = 3.9 * math.sin(math.pi * (0.06 + 0.94 * tq) ** 0.75) ** 0.8 if tq < 1 else 0.15; hgt = w * 0.5
        rg.append([(e[0] - 0.4 - tq * 13.6, e[1] + w * math.cos(2 * math.pi * q / 8), e[2] + hgt * math.sin(2 * math.pi * q / 8)) for q in range(8)])
    Vc, Fc = gk.loft(np.array(rg), True, True); ccx = Vc[Fc].mean(1)[:, 0]
    Fc = gk.orient(Vc, Fc, np.stack([np.clip(ccx, e[0] - 13.6, e[0] - 0.8), np.full(len(Fc), e[1]), np.full(len(Fc), e[2])], 1)); add(Vc, Fc, 22 + j, 20 + j, np.ones(len(Vc)))
# ---------------- merge
V = np.concatenate([p[0] for p in parts]); offs = np.cumsum([0] + [len(p[0]) for p in parts[:-1]])
F = np.concatenate([p[1] + o for p, o in zip(parts, offs)]); part = np.concatenate([[p[2]] * len(p[1]) for p in parts]); meta = np.concatenate(META)
# ---------------- colours
Cs = gk.fill_colours(SH, body_s, 4); Ct = gk.fill_colours(SH, body_t, 4); Ctop_all = gk.fill_colours(SH, top, 3)
def pick(Ci, u, v): return Ci[np.clip(np.round(v).astype(int), 0, H - 1), np.clip(np.round(u).astype(int), 0, W - 1)]
def sm(a, b, x): t = np.clip((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t)
RED = np.array([202, 36, 60], np.float32); PINK = np.array([232, 98, 106], np.float32); PEACH = np.array([252, 178, 138], np.float32); PEACH2 = np.array([236, 130, 104], np.float32)
NAVY = np.array([36, 44, 112], np.float32); GOLD = np.array([242, 190, 52], np.float32); TEAL = np.array([24, 168, 190], np.float32); ORANGE = np.array([250, 150, 40], np.float32)
def local(path, pos):
    d = ((pos[:, None, :] - path['pos'][None, ::3, :]) ** 2).sum(-1).argmin(1) * 3
    dv = pos - path['pos'][d]; s_ = path['fine'][d] + (dv * path['T'][d]).sum(1); perp = dv - path['T'][d] * (dv * path['T'][d]).sum(1, keepdims=True)
    cu = (perp * path['U'][d]).sum(1) / (np.linalg.norm(perp, axis=1) + 1e-6); return s_, cu, d
def suckers(path, s_, cu, d, rows=1):
    q = np.cumsum(np.gradient(path['fine']) / (1.9 * np.maximum(path['rad'], 0.25)))[d] + (s_ - path['fine'][d]) / (1.9 * np.maximum(path['rad'][d], 0.25))
    fr = np.abs(np.mod(q, 1.0) - 0.5); ang = np.sqrt(np.clip(1 - cu ** 2, 0, 1))            # distance from the strip's middle (0 = dead centre)
    rr = np.sqrt((fr / 0.5) ** 2 * 0.9 + (ang / 0.62) ** 2); on = (cu > 0.2)
    return on & (rr < 0.74), on & (rr < 0.3)
def sampler(p, pos, nrm):
    n = len(pos)
    if p == 0:
        x = np.clip(pos[:, 0], 62.3, 99.6); r = r_at(x); u = side_u(x)
        zc = np.clip(pos[:, 2] / r, -0.93, 0.93); cs = pick(Cs, u, cy_s(u) - zc * r * PXS * 0.97)
        ut = top_u(np.clip(x, 64.0, 99.6)); ct = pick(Ct, ut, 764 - np.clip(pos[:, 1] / r, -0.9, 0.9) * np.interp(ut, tcols, hwt) * 0.94)
        wt = sm(0.6, 0.88, nrm[:, 2])[:, None]; col = cs * (1 - wt) + ct * wt
        mouth = sm(62.9, 62.2, pos[:, 0])[:, None] * sm(0.3, 0.8, -nrm[:, 0])[:, None]
        return col * (1 - mouth) + np.array([110, 16, 40], np.float32)[None, :] * mouth
    if p == 2: return pick(Cs, side_u(pos[:, 0]), cy_s(side_u(pos[:, 0])) - pos[:, 2] * PXS)
    if p == 1:
        e = np.abs(pos[:, 1]) - r_at(pos[:, 0]); k = sm(0, 7.0, e)[:, None]; edge = sm(5.6, 7.2, e)[:, None]
        c = (np.array([236, 104, 44], np.float32) * (1 - k) + ORANGE * k) * (1 - edge) + np.array([255, 196, 84], np.float32) * edge
        rib = (np.abs(np.mod(pos[:, 0] * 0.45 + e * 0.5, 1.0) - 0.5) < 0.07)[:, None]
        return c * (1 - 0.1 * rib)
    if 10 <= p < 18 or p in (20, 21):
        path = ARMS[p - 10] if p < 18 else TENT[p - 20]; s_, cu, d = local(path, pos); shade = (0.84 + 0.16 * np.clip(nrm[:, 2], -1, 1))[:, None]
        if p >= 20:
            col = np.tile(TEAL, (n, 1)) * shade; band = (s_ > 47.6); col[band] = GOLD * 0.96
            cuff = (s_ < 3.2); col[cuff] = NAVY; col[cuff & ((s_ < 0.7) | (s_ > 2.6))] = GOLD
            return col
        under = sm(0.15, 0.5, cu)[:, None]; col = (RED * (1 - under) + PINK * under) * shade
        s1, s2 = suckers(path, s_, cu, d); col[s1 & (s_ > 4.9)] = PEACH; col[s2 & (s_ > 4.9)] = PEACH2
        cuff = (s_ > 0.3) & (s_ < 4.4); col[cuff] = NAVY * shade[cuff]; gb = cuff & ((s_ < 1.05) | (s_ > 3.65)); col[gb] = GOLD * shade[gb]
        return col
    if p in (22, 23):
        path = TENT[p - 22]; e = path['pos'][-1]; xl = (e[0] - 0.4 - pos[:, 0]) / 13.6; yl = (pos[:, 1] - e[1]) / 3.9
        ct = pick(Ctop_all, 150 - xl * 125, 718 - yl * 33 * (1 if p == 22 else -1))
        upk = sm(-0.15, 0.25, nrm[:, 2])[:, None]
        q = xl * 6.0; fr = np.abs(np.mod(q, 1.0) - 0.5); row = np.abs(np.abs(yl) - 0.36) / 0.36
        suck = (np.sqrt((fr / 0.5) ** 2 + row ** 2) < 0.8) & (xl > 0.1) & (xl < 0.93)
        under = np.tile(np.array([170, 30, 56], np.float32), (n, 1)); under[suck] = PEACH; under[suck & (np.sqrt((fr / 0.5) ** 2 + row ** 2) < 0.34)] = PEACH2
        return ct * upk + under * (1 - upk)
    return np.tile(RED, (n, 1))
P, ind, uvs, tex, vmap = gk.bake(V, F, part, sampler, T=1024)
tex = cv2.bilateralFilter(tex, 5, 22, 3)
Image.fromarray(tex).transpose(Image.FLIP_TOP_BOTTOM).save(OUT + '/MB_Kraken_tex.png')
gk.write_obj(OUT + '/model.obj', P, ind, uvs, 'MB_Kraken_tex.png'); np.savez(OUT + '/mesh.npz', P=P, ind=ind, uvs=uvs)
# ---------------- rig: Root (head), Mantle, 3 bones per arm, 4 per tentacle
mt = meta[vmap]; B = [('Root', (66, 0, 0), (70, 0, 0), None), ('Mantle', (71, 0, 0), (86, 0, 0), 'Root')]; names = ['Root', 'Mantle']
Wt = np.zeros((len(P), 2 + 8 * 3 + 2 * 4)); grp = mt[:, 0].astype(int); tv = mt[:, 1]
body = grp == 0; km = sm(69.5, 72.5, P[:, 0]); Wt[body, 0] = (1 - km)[body]; Wt[body, 1] = km[body]
def chain(prefix, path, nb, g):
    cuts = np.linspace(0, 1, nb + 1)[:-1]; col0 = len(names)
    for k in range(nb):
        i0 = int(cuts[k] * (len(path['fine']) - 1)); i1 = int((cuts[k + 1] if k + 1 < nb else 1.0) * (len(path['fine']) - 1))
        B.append((prefix + str(k + 1), tuple(path['pos'][i0]), tuple(path['pos'][i1]), 'Root' if k == 0 else prefix + str(k))); names.append(prefix + str(k + 1))
    m = grp == g; w = 0.07
    for k in range(nb):
        lo = sm(cuts[k] - w, cuts[k] + w, tv) if k > 0 else np.ones(len(tv)); hi = sm(cuts[k + 1] - w, cuts[k + 1] + w, tv) if k + 1 < nb else np.zeros(len(tv))
        Wt[m, col0 + k] = (lo - hi)[m]
for i in range(8): chain('Arm%d_' % (i + 1), ARMS[i], 3, 10 + i)
for j, nm in enumerate(('TentL_', 'TentR_')): chain(nm, TENT[j], 4, 20 + j)
Wt = np.clip(Wt, 0, 1); Wt /= np.maximum(Wt.sum(1, keepdims=True), 1e-6)
json.dump(dict(name='MB_Kraken', tex='MB_Kraken_tex.png', bones=[dict(name=b[0], head=b[1], tail=b[2], parent=b[3]) for b in B], weights=np.round(Wt, 3).tolist()), open(OUT + '/rig.json', 'w'))
g = dict(tris=int(len(ind)), verts=int(len(P)), bones=len(B), size=[round(float(P[:, i].max() - P[:, i].min()), 1) for i in range(3)])
json.dump(g, open(OUT + '/gates.json', 'w'), indent=1); print(json.dumps(g))
