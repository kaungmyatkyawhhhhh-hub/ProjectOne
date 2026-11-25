"""Road bug detector, step 1 (25 Nov 2026): match every road mesh in the place to the local .glb it came from.

    python roadbugs_index.py            -> build/city_1to1/roadbugs_25nov/match.json  {place row -> glb path, mesh name}
Input: build/city_1to1/roadbugs_25nov/meshes_place.txt (Studio print: RMLIST cell kind px py pz sx sy sz meshid ...).
Glbs searched: imports/sync/*_glb/*.glb and build/city_1to1/roads05_*/glb/*.glb (mesh names = glb.code: kind_cell sK_cx_cy_cz_sx_sy_sz).
"""
import glob, json, os, re, struct, sys
import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
OUT = os.path.join(ROOT, 'build', 'city_1to1', 'roadbugs_25nov')


def num(t):
    return (-int(t[1:]) if t[0] == 'n' else int(t)) / 100.0


def glb_names(path):
    with open(path, 'rb') as f:
        f.read(12)
        ln, _ = struct.unpack('<I4s', f.read(8))
        js = json.loads(f.read(ln))
    return js


class _P8:
    def __init__(self, path):
        self.path = path

    def __getitem__(self, name):
        return np.load(os.path.join(OUT, 'p8', name + '.npy'))


def read_glb(path):
    """-> {name: (N,3,3) float world triangles}  (a 'p8:' path = triangles dumped from Studio, roadbugs_p8.py)"""
    if 'p8:' in path.replace(os.sep, '/'):
        return _P8(path)
    with open(path, 'rb') as f:
        data = f.read()
    ln = struct.unpack_from('<I', data, 12)[0]
    js = json.loads(data[20:20 + ln])
    off = 20 + ln
    bl = struct.unpack_from('<I', data, off)[0]
    bin_ = data[off + 8: off + 8 + bl]
    out = {}
    for mesh in js['meshes']:
        nm = mesh['name']
        pr = mesh['primitives'][0]
        a = js['accessors'][pr['attributes']['POSITION']]
        v = js['bufferViews'][a['bufferView']]
        P = np.frombuffer(bin_, '<f4', a['count'] * 3, v['byteOffset']).reshape(-1, 3).astype(np.float64)
        ai = js['accessors'][pr['indices']]
        vi = js['bufferViews'][ai['bufferView']]
        I = np.frombuffer(bin_, '<u4' if ai['componentType'] == 5125 else '<u2', ai['count'], vi['byteOffset']).astype(np.int64)
        parts = nm.split('_')
        c = np.array([num(parts[2]), num(parts[3]), num(parts[4])])
        P = np.stack([-P[:, 0], P[:, 1], -P[:, 2]], 1) + c
        out[nm] = P[I].reshape(-1, 3, 3)
    return out


def main():
    pats = [os.path.join(ROOT, 'imports', 'sync', '*_glb', '*.glb'), os.path.join(ROOT, 'build', 'city_1to1', 'roads05_*', 'glb', '*.glb')]
    files = sorted(set(f for p in pats for f in glob.glob(p)), key=os.path.getmtime)
    idx = {}
    for f in files:  # newer files win on an exact key clash
        try:
            js = glb_names(f)
        except Exception as e:
            print('skip', f, e)
            continue
        for m in js['meshes']:
            p = m['name'].split('_')
            if len(p) != 8:
                continue
            key = (p[0], round(num(p[2]), 1), round(num(p[4]), 1), round(num(p[5]), 1), round(num(p[7]), 1))
            idx.setdefault(key, []).append((f, m['name'], num(p[3]), num(p[6])))
    rows = [l.split() for l in open(os.path.join(OUT, 'meshes_place.txt'))]
    match, miss = {}, []
    for i, r in enumerate(rows):
        kind = r[2].replace('RMesh', '')
        px, py, pz, sx, sy, sz = map(float, r[3:9])
        best = None
        for dx in (-0.1, 0, 0.1):
            for dz in (-0.1, 0, 0.1):
                for dsx in (-0.1, 0, 0.1):
                    for dsz in (-0.1, 0, 0.1):
                        for c in idx.get((kind, round(px + dx, 1), round(pz + dz, 1), round(sx + dsx, 1), round(sz + dsz, 1)), []):
                            if abs(c[2] - py) < 0.15 and abs(c[3] - sy) < 0.15:
                                best = c  # last = newest file
        if best:
            match[i] = dict(cell=r[1][5:], kind=kind, glb=os.path.relpath(best[0], ROOT), name=best[1], meshid=r[9])
        else:
            miss.append(' '.join(r[1:10]))
    json.dump(dict(match=match, miss=miss), open(os.path.join(OUT, 'match.json'), 'w'), indent=0)
    print('place meshes', len(rows), 'matched', len(match), 'missing', len(miss))
    by = {}
    for m in miss:
        by.setdefault(m.split()[1], 0)
        by[m.split()[1]] += 1
    print('missing by kind', by)
    print('missing cells', sorted(set(m.split()[0] for m in miss)))


if __name__ == '__main__':
    main()
