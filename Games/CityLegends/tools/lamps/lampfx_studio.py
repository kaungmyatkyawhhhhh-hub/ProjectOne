"""Lamp shells for a car that is already in Studio (no .glb, no Blender), 2026-11-21.

  python lampfx_studio.py jobs_studio/<id>.json <dump.txt> [<dump.txt> ...]   ->  imports/sync/lamp_shells/<id>.glb

The dump is `LS.dump(id, part names, zone)` from LampStudio.luau (EditableMesh, Edit): every face of the
model's lamp parts near the nose and tail, in the model's own space (metres, nose at -Z, left at -X).
A job gives each role a list of sources; only the left half is cut, the right is its mirror image:
  part   the model's part
  in     [ax0, ax1, y0, y1, z0, z1]: whole loose pieces whose middle is in the box (ax = distance from the middle)
  box    [ax0, ax1, y0, y1, z0, z1]: cut the faces at the box (clean edges)
  disc   [ax, y, z, r] (+ ring, squash, n): a round piece made here, for a lamp the model has no piece for
  drape  a part (the lens): lay the piece on that part's outer surface along `dir` (default: the piece's own facing)
  off    how far out of the surface (metres)
Each mesh's name carries its true box in mm (LF_<role><L/R>_<centre>_<size>): LampStudio's apply puts it there.
  python lampfx_studio.py scan <dump pages>   lists the loose pieces
Self-check: python lampfx_studio.py test
"""
import json, struct, sys, os
import numpy as np


def load(paths):
    """The pages of one dump (LS.page(1..n), in order): a header line, a slice, '#' padding."""
    text = ''
    for path in paths:
        t = open(path, encoding='utf-8', errors='ignore').read()
        if t.startswith('['):  # a short page comes wrapped as JSON
            t = json.loads(t)[0]['text']
        text += t[t.index('\n') + 1:].rstrip('#\n ')
    parts, name = {}, None
    for line in text.split('\n'):
        if line.startswith('P '):
            name = line.split(' ')[1]
        elif line.startswith('V ') and name:
            h = line[2:].strip()
            V = (np.array([int(h[i:i + 4], 16) for i in range(0, len(h), 4)], float).reshape(-1, 3) - 32768) / 1000
        elif line.startswith('T ') and name:
            h = line[2:].strip()
            T = np.array([int(h[i:i + 5], 16) for i in range(0, len(h), 5)], int).reshape(-1, 4)
            parts[name] = (V, T[:, :3], T[:, 3])
            name = None
    return parts


def scan(parts, min_area=0.0008):
    """The loose pieces of the left half, biggest first: where to point a job's boxes."""
    for name, (V, T, I) in parts.items():
        print('%s  %d faces' % (name, len(T)))
        rows = []
        for root in np.unique(I):
            P = V[T[I == root]]
            n = np.cross(P[:, 1] - P[:, 0], P[:, 2] - P[:, 0])
            area = np.linalg.norm(n, axis=1).sum() / 2
            lo, hi = P.reshape(-1, 3).min(axis=0), P.reshape(-1, 3).max(axis=0)
            if area >= min_area and lo[0] < 0.02:
                nn = n.sum(axis=0) / max(np.linalg.norm(n.sum(axis=0)), 1e-9)
                rows.append((area, '  %5d tris %.4f m2  ax %.2f..%.2f  y %.2f..%.2f  z %.2f..%.2f  n %.1f,%.1f,%.1f' % (len(P), area, max(-hi[0], 0), -lo[0], lo[1], hi[1], lo[2], hi[2], nn[0], nn[1], nn[2])))
        for _, r in sorted(rows, reverse=True)[:60]:
            print(r)


def soup(V, T):
    return V[T]  # n x 3 x 3


def clip(tri, axis, value, keep_less, fn=lambda p: p):
    """Cut a triangle soup at fn(point)[axis] = value (Sutherland-Hodgman, fan back into triangles)."""
    out = []
    for t in tri:
        d = np.array([fn(p)[axis] - value for p in t]) * (1 if keep_less else -1)
        poly = []
        for i in range(3):
            a, b, da, db = t[i], t[(i + 1) % 3], d[i], d[(i + 1) % 3]
            if da <= 0:
                poly.append(a)
            if (da < 0 < db) or (db < 0 < da):
                poly.append(a + (b - a) * (da / (da - db)))
        for i in range(1, len(poly) - 1):
            out.append([poly[0], poly[i], poly[i + 1]])
    return np.array(out, float).reshape(-1, 3, 3)


def absx(p):
    return np.array([abs(p[0]), p[1], p[2]])


def cut_box(tri, box):
    for axis in range(3):
        lo, hi = box[axis * 2], box[axis * 2 + 1]
        tri = clip(tri, axis, lo, False, absx)
        tri = clip(tri, axis, hi, True, absx)
    return tri


def disc(src):
    """A flat round (or ring) piece facing back, on the left: disc = [ax, y, z, r], ring = inner radius, n = sides,
    squash = [sx, sy] (an oval). For lamps the model has no separate piece for (a round indicator inside a tail lamp)."""
    ax, y, z, r = src['disc']
    r0 = src.get('ring', 0)
    n = src.get('n', 28)
    sx, sy = src.get('squash', [1, 1])
    tri = []
    for i in range(n):
        a0, a1 = 2 * np.pi * i / n, 2 * np.pi * (i + 1) / n
        o0 = [-ax + r * sx * np.cos(a0), y + r * sy * np.sin(a0), z]
        o1 = [-ax + r * sx * np.cos(a1), y + r * sy * np.sin(a1), z]
        if r0 > 0:
            i0 = [-ax + r0 * sx * np.cos(a0), y + r0 * sy * np.sin(a0), z]
            i1 = [-ax + r0 * sx * np.cos(a1), y + r0 * sy * np.sin(a1), z]
            tri += [[i0, o0, o1], [i0, o1, i1]]
        else:
            tri.append([[-ax, y, z], o0, o1])
    return np.array(tri, float)


def pick(parts, src):
    if 'disc' in src:
        tri = disc(src)
        if 'box' in src:
            tri = cut_box(tri, src['box'])
        return tri
    V, T, I = parts[src['part']]
    keep = np.ones(len(T), bool)
    if 'in' in src:
        b = src['in']
        keep[:] = False
        for root in np.unique(I):
            m = I == root
            P = V[T[m]].reshape(-1, 3)
            c = (P.min(axis=0) + P.max(axis=0)) / 2
            c[0] = abs(c[0])
            if all(b[k * 2] <= c[k] <= b[k * 2 + 1] for k in range(3)):
                keep |= m
    tri = clip(soup(V, T[keep]), 0, 0.0, True)  # the left half first: |x| is only straight on one side
    if 'box' in src:
        tri = cut_box(tri, src['box'])
    area = np.linalg.norm(np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0]), axis=1) if len(tri) else np.zeros(0)
    return tri[area > 1e-9]


def weld(tri):
    P = tri.reshape(-1, 3)
    uq, inv = np.unique(np.round(P, 4), axis=0, return_inverse=True)
    return uq, inv.reshape(-1, 3)


def normals(V, T):
    N = np.zeros_like(V)
    fn = np.cross(V[T[:, 1]] - V[T[:, 0]], V[T[:, 2]] - V[T[:, 0]])
    for i in range(3):
        np.add.at(N, T[:, i], fn)
    L = np.linalg.norm(N, axis=1, keepdims=True)
    L[L < 1e-12] = 1
    return N / L


def drape(V, target, d, off):
    """Each point onto the outermost face of `target` (n x 3 x 3) along d; a miss moves like the hits' median."""
    a, e1, e2 = target[:, 0], target[:, 1] - target[:, 0], target[:, 2] - target[:, 0]
    h = np.cross(d, e2)
    det = (e1 * h).sum(axis=1)
    ok = np.abs(det) > 1e-12
    inv = np.where(ok, 1 / np.where(ok, det, 1), 0)
    best = np.full(len(V), -np.inf)
    for i, p in enumerate(V):
        s = p - a
        u = (s * h).sum(axis=1) * inv
        q = np.cross(s, e1)
        v = (q @ d) * inv
        t = (q * e2).sum(axis=1) * inv
        hit = ok & (u >= -1e-6) & (v >= -1e-6) & (u + v <= 1 + 1e-6)
        if hit.any():
            best[i] = t[hit].max()
    got = np.isfinite(best)
    if not got.any():
        raise SystemExit('drape: nothing hit')
    best[~got] = np.median(best[got])
    return V + d * (best[:, None] + off)


def build(parts, job):
    out = {}
    for role, srcs in job['roles'].items():
        Vs, Ts, n = [], [], 0
        for src in srcs:
            tri = pick(parts, src)
            if not len(tri):
                print('  EMPTY', role, src)
                continue
            V, T = weld(tri)
            N = normals(V, T)
            off = src.get('off', 0.008)
            if 'drape' in src:
                d = np.array(src['dir'], float) if 'dir' in src else N.mean(axis=0)
                d /= np.linalg.norm(d)
                tV, tT, _ = parts[src['drape']]
                V = drape(V, soup(tV, tT), d, off)
            else:
                V = V + N * off
            Vs.append(V)
            Ts.append(T + n)
            n += len(V)
        if Vs:
            V, T = np.vstack(Vs), np.vstack(Ts)
            out[role + 'L'] = (V, T)
            M = V.copy()
            M[:, 0] *= -1
            out[role + 'R'] = (M, T[:, ::-1])
    return out


def mm(x):
    v = int(round(x * 1000))
    return ('n%d' % -v) if v < 0 else str(v)


def glb(shells, path):
    """Names carry the true box. x and z are written negated: Roblox turns a .glb half a turn about the up axis."""
    blob, views, accs, meshes, nodes = bytearray(), [], [], [], []

    def add(data, target, comp, kind, count, lo=None, hi=None):
        while len(blob) % 4:
            blob.append(0)
        views.append({'buffer': 0, 'byteOffset': len(blob), 'byteLength': len(data), 'target': target})
        blob.extend(data)
        a = {'bufferView': len(views) - 1, 'componentType': comp, 'count': count, 'type': kind}
        if lo is not None:
            a['min'], a['max'] = lo, hi
        accs.append(a)
        return len(accs) - 1

    for name, (V, T) in shells.items():
        lo, hi = V.min(axis=0), V.max(axis=0)
        c, s = (lo + hi) / 2, hi - lo
        full = 'LF_%s_%s_%s_%s_%s_%s_%s' % (name, mm(c[0]), mm(c[1]), mm(c[2]), mm(s[0]), mm(s[1]), mm(s[2]))
        W = ((V - c) * np.array([-1, 1, -1])).astype('<f4')
        N = (normals(V, T) * np.array([-1, 1, -1])).astype('<f4')
        ip = add(W.tobytes(), 34962, 5126, 'VEC3', len(W), W.min(axis=0).tolist(), W.max(axis=0).tolist())
        inn = add(N.tobytes(), 34962, 5126, 'VEC3', len(N))
        ii = add(T.astype('<u4').tobytes(), 34963, 5125, 'SCALAR', T.size)
        meshes.append({'name': full, 'primitives': [{'attributes': {'POSITION': ip, 'NORMAL': inn}, 'indices': ii}]})
        nodes.append({'name': full, 'mesh': len(meshes) - 1, 'translation': [float(-c[0]), float(c[1]), float(-c[2])]})
    doc = {'asset': {'version': '2.0'}, 'scene': 0, 'scenes': [{'nodes': list(range(len(nodes)))}], 'nodes': nodes,
           'meshes': meshes, 'accessors': accs, 'bufferViews': views, 'buffers': [{'byteLength': len(blob)}]}
    js = json.dumps(doc).encode()
    js += b' ' * (-len(js) % 4)
    while len(blob) % 4:
        blob.append(0)
    with open(path, 'wb') as f:
        f.write(struct.pack('<4sII', b'glTF', 2, 28 + len(js) + len(blob)))
        f.write(struct.pack('<I4s', len(js), b'JSON') + js)
        f.write(struct.pack('<I4s', len(blob), b'BIN\0') + bytes(blob))


def test():
    tri = np.array([[[-1, 0, 0], [1, 0, 0], [0, 1, 0]]], float)
    half = clip(tri, 0, 0.0, True)
    area = sum(np.linalg.norm(np.cross(t[1] - t[0], t[2] - t[0])) / 2 for t in half)
    assert abs(area - 0.5) < 1e-9, area
    boxed = cut_box(half, [0.25, 0.5, -9, 9, -9, 9])
    assert len(boxed) >= 1 and np.abs(boxed[:, :, 0]).min() >= 0.25 - 1e-9 and np.abs(boxed[:, :, 0]).max() <= 0.5 + 1e-9
    V = np.array([[0.2, 0.2, -1.0]])
    D = drape(V, np.array([[[0, 0, 2], [1, 0, 2], [0, 1, 2]], [[0, 0, 3], [1, 0, 3], [0, 1, 3]]], float), np.array([0, 0, 1.0]), 0.01)
    assert abs(D[0, 2] - 3.01) < 1e-9, D
    print('ok')


if __name__ == '__main__':
    if sys.argv[1] == 'test':
        test()
        sys.exit()
    if sys.argv[1] == 'want':  # the Lua call that fetches just a job's pieces
        for path in sys.argv[2:]:
            job = json.load(open(path))
            rows = []
            for srcs in job['roles'].values():
                for src in srcs:
                    if 'part' in src:
                        rows.append('{"%s"%s}' % (src['part'], ''.join(',%g' % v for v in src.get('in', []))))
                    if 'drape' in src:
                        rows.append('{"%s"}' % src['drape'])
            print('return _G.LS.get("%s",{%s})' % (job['id'], ','.join(sorted(set(rows)))))
        sys.exit()
    if sys.argv[1] == 'scan':
        scan(load(sys.argv[2:]))
        sys.exit()
    job = json.load(open(sys.argv[1]))
    shells = build(load(sys.argv[2:]), job)
    here = os.path.dirname(os.path.abspath(__file__))
    out = os.path.join(here, '..', '..', 'imports', 'sync', 'lamp_shells')  # imports/ is the approved upload folder
    os.makedirs(out, exist_ok=True)
    path = os.path.abspath(os.path.join(out, job['id'] + '.glb'))
    glb(shells, path)
    for name, (V, T) in shells.items():
        if name.endswith('L'):
            lo, hi = V.min(axis=0), V.max(axis=0)
            print('  %-10s %4d tris  x %.3f..%.3f  y %.3f..%.3f  z %.3f..%.3f' % (name, len(T), lo[0], hi[0], lo[1], hi[1], lo[2], hi[2]))
    print(path, os.path.getsize(path))
