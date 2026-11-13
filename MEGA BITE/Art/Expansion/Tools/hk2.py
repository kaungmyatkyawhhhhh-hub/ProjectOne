"""MEGA BITE sheet-locked prop kit (13 Nov, owner: "use roblox-3d-model-from-sheet for everything").
The sheet is the contract: side view = X/Z, top view = X/Y, front view = Y/Z (orthographic registration, one shared scale
per axis). Geometry = the volume the three measured silhouettes allow (voxel hull -> marching cubes -> normals fixed ->
Taubin smoothing -> decimate), so every view's outline comes from the sheet's pixels. Colour = the sheet's own pixels
projected from the view each surface faces, snapped to the sheet's flat palette (k-means) and cleaned, in one texture.
Gates (skill step 4): silhouette IoU >= 0.90 per view at the sheet's pixel scale, no open edges, outward normals
(backface renders), and a side-by-side comparison pasted into the sheet layout on magenta."""
import numpy as np, json, os, sys, math
from PIL import Image
from scipy import ndimage as ndi
from skimage import measure
import trimesh, xatlas, fast_simplification, cv2

MAG = np.array([255, 0, 255], float)

def analyse(C):
    SH = np.array(Image.open(C['sheet']).convert('RGB')).astype(np.float32); H, W, _ = SH.shape
    d = np.sqrt(((SH - MAG) ** 2).sum(-1))
    bgc = d < C.get('key', 95)
    lab, n = ndi.label(bgc)
    border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    bg = np.isin(lab, list(border)) | (d < 55)          # enclosed pure-magenta holes count as background (arches, ribs)
    fg = ndi.binary_opening(~bg, iterations=1)
    lab, n = ndi.label(fg); sizes = ndi.sum(fg, lab, range(1, n + 1))
    V = {k: np.zeros_like(fg) for k in ('side', 'top', 'front')}
    sy, sx = C.get('split_y', 0.47), C.get('split_x', 0.55)
    for i in range(n):
        if sizes[i] < C.get('min_px', 150): continue
        m = lab == i + 1; ys, xs = np.where(m); cx, cy = xs.mean() / W, ys.mean() / H
        V['side' if cy < sy else ('top' if cx < sx else 'front')] |= m
    for k in V:
        if C.get('fill_' + k): V[k] = ndi.binary_fill_holes(V[k])
    bb = {}
    for k, m in V.items():
        ys, xs = np.where(m); bb[k] = [int(xs.min()), int(xs.max()), int(ys.min()), int(ys.max())]
    # palette: k-means on the art pixels
    px = SH[fg].reshape(-1, 3); rs = np.random.default_rng(0); px = px[rs.choice(len(px), min(60000, len(px)), replace=False)]
    K = C.get('colours', 12)
    crit = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 60, 0.5)
    _, labels, cent = cv2.kmeans(px.astype(np.float32), K, None, crit, 4, cv2.KMEANS_PP_CENTERS)
    return SH, V, bb, cent

def build(C):
    out = C['out']; os.makedirs(out, exist_ok=True)
    SH, V, bb, PAL = analyse(C)
    sx0, sx1, sy0, sy1 = bb['side']; tx0, tx1, ty0, ty1 = bb['top']; fx0, fx1, fy0, fy1 = bb['front']
    L = C['length']; s = L / (sx1 - sx0 + 1)               # studs per pixel of the side view
    Hz = (sy1 - sy0 + 1) * s
    st = L / (tx1 - tx0 + 1)                                # top view: its own px scale, matched on X
    Dy_top = (ty1 - ty0 + 1) * st
    sf = Hz / (fy1 - fy0 + 1)                               # front view: its own px scale, matched on Z
    Dy_front = (fx1 - fx0 + 1) * sf
    Dy = Dy_top if C.get('depth_from', 'top') == 'top' else Dy_front
    reg = dict(L=L, H=Hz, D_top=Dy_top, D_front=Dy_front, depth_conflict=abs(Dy_top - Dy_front) / max(Dy_top, Dy_front))
    # registration: world (x along length from the side view's left, y depth centred, z up from the bottom)
    side_px = lambda x, z: (sx0 + x / s, sy1 - z / s)
    top_px = lambda x, y: (tx0 + x / st, (ty0 + ty1) / 2 - y / (Dy / (ty1 - ty0 + 1)) * (1 if not C.get('top_flip') else -1))
    front_px = lambda y, z: ((fx0 + fx1) / 2 + y / (Dy / (fx1 - fx0 + 1)) * (1 if not C.get('front_flip') else -1), fy1 - z / sf)
    N = C.get('res', 240); vs = max(L, Hz, Dy) / N
    X = np.arange(-2, int(L / vs) + 3) * vs; Y = np.arange(int(-Dy / 2 / vs) - 2, int(Dy / 2 / vs) + 3) * vs; Z = np.arange(-2, int(Hz / vs) + 3) * vs
    def samp(m, u, v):
        ui = np.round(u).astype(int); vi = np.round(v).astype(int)
        ok = (ui >= 0) & (ui < m.shape[1]) & (vi >= 0) & (vi < m.shape[0])
        r = np.zeros(u.shape, bool); r[ok] = m[vi[ok], ui[ok]]; return r
    Ms = ndi.binary_dilation(V['side'], iterations=1); Mt = ndi.binary_dilation(V['top'], iterations=1); Mf = ndi.binary_dilation(V['front'], iterations=1)
    a = samp(Ms, *side_px(*np.meshgrid(X, Z, indexing='ij')))                  # (x,z)
    b = samp(Mt, *top_px(*np.meshgrid(X, Y, indexing='ij')))                   # (x,y)
    c = samp(Mf, *front_px(*np.meshgrid(Y, Z, indexing='ij')))                 # (y,z)
    if C.get('no_top'): b[:] = True
    if C.get('no_front'): c[:] = True
    vol = a[:, None, :] & b[:, :, None] & c[None, :, :]
    f = ndi.gaussian_filter(vol.astype(np.float32), C.get('blur', 0.8))
    verts, faces, _, _ = measure.marching_cubes(f, 0.5)
    verts = verts * vs + np.array([X[0], Y[0], Z[0]])
    m = trimesh.Trimesh(verts, faces, process=True)
    parts = [p for p in m.split(only_watertight=False) if p.volume > abs(m.volume) * C.get('min_part', 0.0005) or p.area > m.area * 0.002]
    m = trimesh.util.concatenate(parts)
    trimesh.repair.fix_normals(m, multibody=True)
    trimesh.smoothing.filter_taubin(m, lamb=0.5, nu=-0.53, iterations=C.get('taubin', 10))
    tgt = C.get('tris', 12000)
    if len(m.faces) > tgt:
        v2, f2 = fast_simplification.simplify(m.vertices.astype(np.float32), m.faces.astype(np.int32), 1 - tgt / len(m.faces))
        m = trimesh.Trimesh(v2, f2, process=True); trimesh.repair.fix_normals(m, multibody=True)
    # ---- texture: project, snap to the palette, clean
    vmap, ind, uvs = xatlas.parametrize(m.vertices, m.faces)
    P = m.vertices[vmap]; Nn = m.vertex_normals[vmap]
    T = C.get('tex', 1024); img = np.zeros((T, T, 3), np.float32); hit = np.zeros((T, T), bool)
    magish = (SH[..., 0] > 140) & (SH[..., 2] > 140) & (SH[..., 1] < 0.62 * np.minimum(SH[..., 0], SH[..., 2])) & (np.abs(SH[..., 0] - SH[..., 2]) < 90)
    def filled(mask):
        good = ndi.binary_erosion(mask, iterations=C.get('edge_px', 3)) & ~ndi.binary_dilation(magish, iterations=1)
        idx = ndi.distance_transform_edt(~good, return_distances=False, return_indices=True); return SH[idx[0], idx[1]]
    Cs, Ct, Cf = filled(V['side']), filled(V['top']), filled(V['front'])
    def pick(Ci, u, v):
        return Ci[np.clip(np.round(v).astype(int), 0, Ci.shape[0] - 1), np.clip(np.round(u).astype(int), 0, Ci.shape[1] - 1)]
    tri_uv = uvs[ind] * (T - 1)
    for t in range(len(ind)):
        U = tri_uv[t]; p3 = P[ind[t]]; n3 = Nn[ind[t]]
        mn = np.floor(U.min(0)).astype(int); mx = np.ceil(U.max(0)).astype(int)
        gx, gy = np.meshgrid(np.arange(mn[0], mx[0] + 1), np.arange(mn[1], mx[1] + 1)); q = np.stack([gx.ravel(), gy.ravel()], 1).astype(float)
        v0 = U[1] - U[0]; v1 = U[2] - U[0]; den = v0[0] * v1[1] - v1[0] * v0[1]
        if abs(den) < 1e-9: continue
        d2 = q - U[0]; l1 = (d2[:, 0] * v1[1] - v1[0] * d2[:, 1]) / den; l2 = (v0[0] * d2[:, 1] - d2[:, 0] * v0[1]) / den; l0 = 1 - l1 - l2
        ok = (l0 >= -0.03) & (l1 >= -0.03) & (l2 >= -0.03)
        if not ok.any(): continue
        bc = np.stack([l0, l1, l2], 1)[ok]; pxy = q[ok].astype(int)
        pos = bc @ p3; nrm = bc @ n3; nrm /= np.linalg.norm(nrm, axis=1, keepdims=True) + 1e-9
        ws = np.abs(nrm[:, 1]); wt = np.clip(nrm[:, 2], 0, 1) * C.get('top_w', 1.0); wf = np.clip(nrm[:, 0] * (-1 if C.get('front_neg') else 1), 0, 1) * C.get('front_w', 1.0)
        if C.get('front_xmax') is not None: wf = wf * (pos[:, 0] < C['front_xmax'])
        cs = pick(Cs, *side_px(pos[:, 0], pos[:, 2])); ct = pick(Ct, *top_px(pos[:, 0], pos[:, 1])); cf = pick(Cf, *front_px(pos[:, 1], pos[:, 2]))
        best = np.argmax(np.stack([ws, wt, wf], 1), 1)
        col = np.where(best[:, None] == 0, cs, np.where(best[:, None] == 1, ct, cf))
        img[pxy[:, 1], pxy[:, 0]] = col; hit[pxy[:, 1], pxy[:, 0]] = True
    # snap to the sheet palette, then a mode filter so regions are clean and flat
    flat = img.reshape(-1, 3); dd = ((flat[:, None, :] - PAL[None, :, :]) ** 2).sum(-1); li = dd.argmin(1).reshape(T, T)
    if C.get('mode_r', 2):
        r = C.get('mode_r', 2); best = np.zeros((T, T), int); cnt = np.full((T, T), -1.0)
        for k in range(len(PAL)):
            cc = ndi.uniform_filter((li == k).astype(np.float32), 2 * r + 1)
            upd = cc > cnt; best[upd] = k; cnt[upd] = cc[upd]
        li = np.where(hit, best, li)
    tex = PAL[li]
    if C.get('painterly'):
        tex = img.copy()
    idx = ndi.distance_transform_edt(~hit, return_distances=False, return_indices=True); tex = tex[idx[0], idx[1]]
    if C.get('painterly'):
        tex = cv2.bilateralFilter(np.clip(tex, 0, 255).astype(np.uint8), 5, 28, 3).astype(np.float32)
    Image.fromarray(np.clip(tex, 0, 255).astype(np.uint8)).transpose(Image.FLIP_TOP_BOTTOM).save(out + '/tex.png')
    # centre on x (length), y already centred, z from 0 (sits on the floor)
    P2 = P - np.array([L / 2, 0, 0])
    with open(out + '/model.obj', 'w') as fo:
        fo.write('mtllib model.mtl\nusemtl m\n')
        for v in P2: fo.write(f'v {v[0]:.4f} {v[2]:.4f} {-v[1]:.4f}\n')          # OBJ y-up
        for u in uvs: fo.write(f'vt {u[0]:.5f} {u[1]:.5f}\n')
        for a_, b_, c_ in ind + 1: fo.write(f'f {a_}/{a_} {b_}/{b_} {c_}/{c_}\n')
    open(out + '/model.mtl', 'w').write('newmtl m\nmap_Kd tex.png\n')
    # ---- gates
    mesh_final = trimesh.Trimesh(P2, ind, process=True)
    open_edges = int(len(trimesh.grouping.group_rows(mesh_final.edges_sorted, require_count=1)))
    def raster(proj, shape):
        img_ = np.zeros(shape, np.uint8)
        pts = proj(P2 + np.array([L / 2, 0, 0]))
        for f_ in ind:
            tri = np.round(pts[f_]).astype(np.int32); cv2.fillConvexPoly(img_, tri, 1)
        return img_.astype(bool)
    HW = V['side'].shape
    sideR = raster(lambda p: np.stack(side_px(p[:, 0], p[:, 2]), 1), HW)
    topR = raster(lambda p: np.stack(top_px(p[:, 0], p[:, 1]), 1), HW)
    frontR = raster(lambda p: np.stack(front_px(p[:, 1], p[:, 2]), 1), HW)
    def iou(a_, b_): return float((a_ & b_).sum() / max(1, (a_ | b_).sum()))
    gates = dict(side_iou=iou(sideR, V['side']), top_iou=iou(topR, V['top']), front_iou=iou(frontR, V['front']), open_edges=open_edges,
                 tris=int(len(ind)), size_studs=[round(L, 1), round(Dy, 1), round(Hz, 1)], registration=reg)
    gates['pass'] = all(gates[k] >= 0.90 for k in ('side_iou', 'top_iou', 'front_iou')) and open_edges == 0
    # mismatch overlay (green = sheet only, red = model only, white = both)
    ov = np.zeros(HW + (3,), np.uint8)
    for R_, M_ in ((sideR, V['side']), (topR, V['top']), (frontR, V['front'])):
        ov[R_ & M_] = (235, 235, 235); ov[M_ & ~R_] = (40, 200, 60); ov[R_ & ~M_] = (230, 50, 50)
    Image.fromarray(ov).save(out + '/mismatch.png')
    json.dump(gates, open(out + '/gates.json', 'w'), indent=1)
    np.save(out + '/palette.npy', PAL)
    print(C['name'], json.dumps(gates))
    return gates

if __name__ == '__main__':
    build(json.load(open(sys.argv[1])))
