"""MEGA BITE giant-creature kit (13 Nov). Sheet-locked like the fish kit, for big swimmers whose sheet has a clean side and top view:
body = loft from the measured side profile (top/bottom per column) and top-view half-width; fins = rounded plates cut from the
sheet's own outlines; colour = the sheet's pixels projected from the view each surface faces, in one atlas; rig = bones by position."""
import numpy as np, json, math, cv2
from PIL import Image
from scipy import ndimage as ndi
from scipy.spatial import Delaunay
from scipy.interpolate import PchipInterpolator
MAG = np.array([255, 0, 255], float)

def load(sheet, key=95):
    SH = np.array(Image.open(sheet).convert('RGB')).astype(np.float32)
    d = np.sqrt(((SH - MAG) ** 2).sum(-1)); bgc = d < key
    lab, n = ndi.label(bgc); border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    fg = ndi.binary_opening(~np.isin(lab, list(border)), iterations=1)
    return SH, fg

def comp_in(fg, box):
    """the art inside a box (x0, y0, x1, y1) as a full-size mask"""
    m = np.zeros_like(fg); x0, y0, x1, y1 = box; m[y0:y1, x0:x1] = fg[y0:y1, x0:x1]; return m

def fill_colours(SH, mask, edge_px=3):
    """sheet colours with the outline's anti-aliased rim replaced by the nearest inside colour (no magenta fringe)"""
    magish = (SH[..., 0] > 140) & (SH[..., 2] > 140) & (SH[..., 1] < 0.62 * np.minimum(SH[..., 0], SH[..., 2])) & (np.abs(SH[..., 0] - SH[..., 2]) < 90)
    good = ndi.binary_erosion(mask, iterations=edge_px) & ~ndi.binary_dilation(magish, iterations=1)
    idx = ndi.distance_transform_edt(~good, return_distances=False, return_indices=True); return SH[idx[0], idx[1]]

def poly_mask(shape, pts):
    m = np.zeros(shape, np.uint8); cv2.fillPoly(m, [np.array(pts, np.int32)], 1); return m.astype(bool)

def pillow(mask, step, thick, to3d, part, edge_pts=40, power=0.5, tmin=0.0, insets=(), profile=None):
    """a rounded plate from a 2D mask: Delaunay over the outline + inner grid, both faces, thickness from the distance to the edge.
    to3d(u, v, t) -> xyz where (u, v) are sheet px and t the signed thickness (studs). Returns V (n,3), F (m,3), UVpx (n,2)."""
    cs, _ = cv2.findContours(mask.astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    c = max(cs, key=cv2.contourArea)[:, 0, :].astype(float)
    # resample the outline evenly
    seg = np.r_[0, np.cumsum(np.linalg.norm(np.diff(np.r_[c, c[:1]], axis=0), axis=1))]
    tt = np.linspace(0, seg[-1], edge_pts, endpoint=False); cc = np.r_[c, c[:1]]
    out = np.stack([np.interp(tt, seg, cc[:, 0]), np.interp(tt, seg, cc[:, 1])], 1)
    dist = ndi.distance_transform_edt(mask)
    ys, xs = np.mgrid[0:mask.shape[0]:step, 0:mask.shape[1]:step]; g = np.stack([xs.ravel(), ys.ravel()], 1).astype(float)
    gi = g.astype(int); keep = mask[gi[:, 1], gi[:, 0]] & (dist[gi[:, 1], gi[:, 0]] > step * 0.55)
    inner = g[keep] + 0.01
    for k_in in insets:                       # extra rings just inside the outline (they give a rounded rim its shape)
        me_ = ndi.binary_erosion(mask, iterations=int(k_in)); cs2, _ = cv2.findContours(me_.astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
        if not cs2: continue
        c2 = max(cs2, key=cv2.contourArea)[:, 0, :].astype(float); sg = np.r_[0, np.cumsum(np.linalg.norm(np.diff(np.r_[c2, c2[:1]], axis=0), axis=1))]
        t2 = np.linspace(0, sg[-1], edge_pts, endpoint=False) + sg[-1] / edge_pts / 2; c2c = np.r_[c2, c2[:1]]
        ring_ = np.stack([np.interp(t2, sg, c2c[:, 0]), np.interp(t2, sg, c2c[:, 1])], 1)
        inner = inner[dist[inner[:, 1].astype(int), inner[:, 0].astype(int)] > k_in + step * 0.5]
        inner = np.r_[ring_, inner]
    pts = np.r_[out, inner]; tri = Delaunay(pts).simplices
    cen = pts[tri].mean(1).astype(int); ok = mask[np.clip(cen[:, 1], 0, mask.shape[0] - 1), np.clip(cen[:, 0], 0, mask.shape[1] - 1)]
    tri = tri[ok]
    dmax = dist.max(); dv = np.r_[np.zeros(len(out)), dist[inner[:, 1].astype(int), inner[:, 0].astype(int)]]
    th = np.maximum(tmin * (np.arange(len(pts)) >= len(out)), thick * ((dv / dmax) ** power if profile is None else profile(dv / dmax)))
    nb = len(out)
    top = np.array([to3d(p[0], p[1], t) for p, t in zip(pts, th)])
    bot = np.array([to3d(p[0], p[1], -t) for p, t in zip(pts[nb:], th[nb:])])
    V = np.r_[top, bot]; remap = np.r_[np.arange(nb), np.arange(len(inner)) + len(pts)]       # bottom shares the outline ring
    F = np.r_[tri, remap[tri][:, ::-1]]
    UV = np.r_[pts, pts[nb:]]
    return V, F, UV

def orient(V, F, inside):
    """flip faces so normals point away from 'inside' (a point or an (n,3) array of per-face reference points)"""
    c = V[F].mean(1); n = np.cross(V[F[:, 1]] - V[F[:, 0]], V[F[:, 2]] - V[F[:, 0]])
    flip = (n * (c - inside)).sum(1) < 0; F = F.copy(); F[flip] = F[flip][:, ::-1]; return F

def loft(rings, cap0=True, cap1=True):
    """rings: (k, n, 3). Quads split with alternating diagonals. Returns V, F."""
    k, n, _ = rings.shape; V = rings.reshape(-1, 3); F = []
    for a in range(k - 1):
        for i in range(n):
            j = (i + 1) % n; p, q, r, s = a * n + i, a * n + j, (a + 1) * n + j, (a + 1) * n + i
            F += [[p, q, r], [p, r, s]] if (a + i) % 2 == 0 else [[p, q, s], [q, r, s]]
    V = list(V)
    if cap0:
        V.append(rings[0].mean(0)); c = len(V) - 1; F += [[c, (i + 1) % n, i] for i in range(n)]
    if cap1:
        V.append(rings[-1].mean(0)); c = len(V) - 1; b = (k - 1) * n; F += [[c, b + i, b + (i + 1) % n] for i in range(n)]
    return np.array(V), np.array(F)

def bake(V, F, part, sampler, T=1024, pad=6):
    """one atlas (xatlas) painted by sampler(part_id, pos (m,3), nrm (m,3)) -> rgb (m,3). Returns P, ind, uvs, tex, vmap."""
    import xatlas, trimesh
    m = trimesh.Trimesh(V, F, process=False)
    atlas = xatlas.Atlas(); atlas.add_mesh(V.astype(np.float32), F.astype(np.uint32))
    po = xatlas.PackOptions(); po.padding = pad; po.resolution = T; atlas.generate(pack_options=po)
    vmap, ind, uvs = atlas[0]
    P = V[vmap]; Nn = np.asarray(m.vertex_normals)[vmap]
    # per-face flat-ish normals keep plates from picking the wrong side at their rim
    FN = np.asarray(m.face_normals)
    img = np.zeros((T, T, 3), np.float32); hit = np.zeros((T, T), bool)
    tri_uv = uvs[ind] * (T - 1)
    for t in range(len(ind)):
        U = tri_uv[t]; p3 = P[ind[t]]; n3 = Nn[ind[t]] * 0.5 + FN[t] * 0.5
        mn = np.floor(U.min(0)).astype(int) - 1; mx = np.ceil(U.max(0)).astype(int) + 1
        gx, gy = np.meshgrid(np.arange(max(mn[0], 0), min(mx[0], T - 1) + 1), np.arange(max(mn[1], 0), min(mx[1], T - 1) + 1)); q = np.stack([gx.ravel(), gy.ravel()], 1).astype(float)
        v0 = U[1] - U[0]; v1 = U[2] - U[0]; den = v0[0] * v1[1] - v1[0] * v0[1]
        if abs(den) < 1e-9: continue
        d2 = q - U[0]; l1 = (d2[:, 0] * v1[1] - v1[0] * d2[:, 1]) / den; l2 = (v0[0] * d2[:, 1] - d2[:, 0] * v0[1]) / den; l0 = 1 - l1 - l2
        ok = (l0 >= -0.25) & (l1 >= -0.25) & (l2 >= -0.25)
        if not ok.any(): continue
        bc = np.clip(np.stack([l0, l1, l2], 1)[ok], 0, 1); bc /= bc.sum(1, keepdims=True); pxy = q[ok].astype(int)
        pos = bc @ p3; nrm = bc @ n3; nrm /= np.linalg.norm(nrm, axis=1, keepdims=True) + 1e-9
        inside = (np.stack([l0, l1, l2], 1)[ok] >= -0.02).all(1)
        new = inside | ~hit[pxy[:, 1], pxy[:, 0]]
        col = sampler(int(part[t]), pos, nrm)
        img[pxy[new, 1], pxy[new, 0]] = col[new]; hit[pxy[new, 1], pxy[new, 0]] = True
    idx = ndi.distance_transform_edt(~hit, return_distances=False, return_indices=True); tex = img[idx[0], idx[1]]
    return P, ind, uvs, np.clip(tex, 0, 255).astype(np.uint8), vmap

def write_obj(path, P, ind, uvs, texname):
    """model axes: X length (nose +X), Y side, Z up -> OBJ y-up (x, z, -y)"""
    with open(path, 'w') as fo:
        fo.write('mtllib model.mtl\nusemtl m\n')
        for v in P: fo.write(f'v {v[0]:.4f} {v[2]:.4f} {-v[1]:.4f}\n')
        for u in uvs: fo.write(f'vt {u[0]:.5f} {u[1]:.5f}\n')
        for a_, b_, c_ in ind + 1: fo.write(f'f {a_}/{a_} {b_}/{b_} {c_}/{c_}\n')
    open(path.rsplit('/', 1)[0] + '/model.mtl', 'w').write('newmtl m\nmap_Kd %s\n' % texname)

def raster(P, ind, proj, shape):
    img_ = np.zeros(shape, np.uint8); pts = proj(P)
    for f_ in ind: cv2.fillConvexPoly(img_, np.round(pts[f_]).astype(np.int32), 1)
    return img_.astype(bool)
def iou(a, b): return float((a & b).sum() / max(1, (a | b).sum()))

def tube(path, radii, sides=5, cap=True):
    """a tube along 3D points with per-point radius (parallel-transport frames). Returns V, F (outward)."""
    path = np.array(path, float); n = len(path); T = np.array([path[min(i + 1, n - 1)] - path[max(i - 1, 0)] for i in range(n)]); T /= np.linalg.norm(T, axis=1, keepdims=True)
    a = np.cross(T[0], [0, 0, 1.0]); a = np.cross(T[0], [0, 1.0, 0]) if np.linalg.norm(a) < 1e-3 else a; a /= np.linalg.norm(a); rings = []
    for i in range(n):
        a = a - T[i] * (a @ T[i]); a /= np.linalg.norm(a); b = np.cross(T[i], a)
        rings.append([path[i] + (a * math.cos(2 * math.pi * j / sides) + b * math.sin(2 * math.pi * j / sides)) * radii[i] for j in range(sides)])
    V, F = loft(np.array(rings), cap, cap)
    c = V[F].mean(1); d = ((c[:, None, :] - path[None, :, :]) ** 2).sum(-1).argmin(1)
    return V, orient(V, F, path[d])

def blob(c, size, sub=1, seed=0, rough=0.0):
    """an icosphere scaled to size (3,) at c. Returns V, F."""
    import trimesh
    m = trimesh.creation.icosphere(subdivisions=sub, radius=1.0); V = np.array(m.vertices) * np.array(size)
    if rough:
        r = np.random.default_rng(seed); V = V * (1 + r.uniform(-rough, rough, (len(V), 1)))
    return V + np.array(c), np.array(m.faces)
