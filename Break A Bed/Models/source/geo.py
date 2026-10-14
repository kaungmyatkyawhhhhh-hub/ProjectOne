import numpy as np, trimesh

def V(*a): return np.array(a, float)
def nrm(v):
    n = np.linalg.norm(v, axis=-1, keepdims=True); n[n == 0] = 1; return v / n

def catmull(pts, n=40):
    p = np.asarray(pts, float)
    p = np.vstack([2*p[0]-p[1], p, 2*p[-1]-p[-2]])
    out = []
    segs = len(p) - 3
    for i in range(segs):
        p0, p1, p2, p3 = p[i:i+4]
        m = max(2, n // segs)
        for t in np.linspace(0, 1, m, endpoint=(i == segs-1)):
            t2, t3 = t*t, t*t*t
            out.append(0.5*((2*p1) + (-p0+p2)*t + (2*p0-5*p1+4*p2-p3)*t2 + (-p0+3*p1-3*p2+p3)*t3))
    return np.array(out)

def frames(P, up):
    T = np.gradient(P, axis=0); T = nrm(T)
    up = nrm(np.asarray(up, float))
    N = up - np.dot(up, T[0]) * T[0]
    if np.linalg.norm(N) < 1e-4:
        N = V(1, 0, 0) - T[0][0]*T[0]
    N = N/np.linalg.norm(N)
    Ns = []
    for t in T:
        N = N - np.dot(N, t)*t
        if np.linalg.norm(N) < 1e-6: N = Ns[-1]
        N = N/np.linalg.norm(N); Ns.append(N)
    Ns = np.array(Ns); B = np.cross(T, Ns)
    return T, Ns, B

def loft(path, radii, seg=16, up=(0, 1, 0), samples=40, smooth=True, cap=True):
    """radii: list of (rx, ry) or scalars at the control points (interpolated)."""
    P = catmull(path, samples) if smooth and len(path) > 2 else np.array(path, float)
    if not smooth and len(path) == 2:
        P = np.linspace(path[0], path[1], samples)
    r = np.array([(x, x) if np.isscalar(x) else x for x in radii], float)
    s_ctrl = np.linspace(0, 1, len(r))
    d = np.r_[0, np.cumsum(np.linalg.norm(np.diff(P, axis=0), axis=1))]; s = d/d[-1]
    rx = np.interp(s, s_ctrl, r[:, 0]); ry = np.interp(s, s_ctrl, r[:, 1])
    return tube(P, rx, ry, seg, up, cap)

def tube(P, rx, ry, seg=16, up=(0, 1, 0), cap=True):
    T, N, B = frames(P, up)
    a = np.linspace(0, 2*np.pi, seg, endpoint=False)
    verts = (P[:, None, :] + rx[:, None, None]*np.cos(a)[None, :, None]*B[:, None, :]
             + ry[:, None, None]*np.sin(a)[None, :, None]*N[:, None, :]).reshape(-1, 3)
    n = len(P); f = []
    for i in range(n-1):
        for j in range(seg):
            a0 = i*seg+j; a1 = i*seg+(j+1) % seg; b0 = a0+seg; b1 = a1+seg
            f += [[a0, b0, b1], [a0, b1, a1]]
    verts = list(verts)
    if cap:
        c0 = len(verts); verts.append(P[0]); c1 = len(verts); verts.append(P[-1])
        for j in range(seg):
            f.append([c0, (j+1) % seg, j])
            f.append([c1, (n-1)*seg+j, (n-1)*seg+(j+1) % seg])
    m = trimesh.Trimesh(np.array(verts), np.array(f), process=True)
    trimesh.repair.fix_normals(m)
    return m

def ellipsoid(c, r, R=None, sub=3):
    m = trimesh.creation.icosphere(subdivisions=sub)
    m.apply_scale(r)
    if R is not None: m.apply_transform(R)
    m.apply_translation(c); return m

def leaf(path, width, thick=0.08, up=(0, 1, 0), seg=10, samples=24, shape=0.8, tipw=0.0):
    """flat pointed blade: width lies along B (perp to up and the path)."""
    P = catmull(path, samples) if len(path) > 2 else np.linspace(path[0], path[1], samples)
    t = np.linspace(0, 1, len(P))
    w = width*np.sin(np.pi*np.clip(t, 0, 1)**shape)**0.7 + tipw*t
    w = np.maximum(w, 0.02)
    return tube(P, w, np.full_like(w, thick), seg, up)

def sheet(grid, thick=0.06):
    """grid: (nu, nv, 3) surface -> thin closed slab (both sides)."""
    g = np.asarray(grid, float); nu, nv, _ = g.shape
    du = np.gradient(g, axis=0); dv = np.gradient(g, axis=1)
    nn = nrm(np.cross(du, dv))
    top = (g + nn*thick/2).reshape(-1, 3); bot = (g - nn*thick/2).reshape(-1, 3)
    verts = np.vstack([top, bot]); off = nu*nv; f = []
    idx = lambda i, j: i*nv+j
    for i in range(nu-1):
        for j in range(nv-1):
            a, b, c, d = idx(i, j), idx(i+1, j), idx(i+1, j+1), idx(i, j+1)
            f += [[a, b, c], [a, c, d], [a+off, c+off, b+off], [a+off, d+off, c+off]]
    # close the rim
    rim = [idx(i, 0) for i in range(nu)] + [idx(nu-1, j) for j in range(1, nv)] + \
          [idx(i, nv-1) for i in range(nu-2, -1, -1)] + [idx(0, j) for j in range(nv-2, 0, -1)]
    for k in range(len(rim)):
        a = rim[k]; b = rim[(k+1) % len(rim)]
        f += [[a, b, b+off], [a, b+off, a+off]]
    m = trimesh.Trimesh(verts, np.array(f), process=True)
    trimesh.repair.fix_normals(m); return m

def cone(base, tip, r, seg=12, up=(0, 1, 0)):
    return loft([base, tip], [r, 0.01], seg=seg, up=up, smooth=False, samples=8)

def crystal(base, tip, r):
    return loft([base, (np.array(base)*0.3+np.array(tip)*0.7), tip], [r, r*1.05, 0.01], seg=6, smooth=False, samples=3)

def look(fwd, up=(0, 1, 0)):
    """rotation matrix mapping local -Z to fwd."""
    f = nrm(np.asarray(fwd, float)); z = -f
    x = np.cross(up, z)
    if np.linalg.norm(x) < 1e-5: x = V(1, 0, 0)
    x = x/np.linalg.norm(x); y = np.cross(z, x)
    R = np.eye(4); R[:3, 0] = x; R[:3, 1] = y; R[:3, 2] = z; return R

def place(meshes, R=None, t=(0, 0, 0)):
    out = []
    for m in meshes:
        m = m.copy()
        if R is not None: m.apply_transform(R)
        m.apply_translation(t); out.append(m)
    return out
