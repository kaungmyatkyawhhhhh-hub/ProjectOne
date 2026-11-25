"""Road bug detector: meshes with no local .glb (the laptop-baked P8 cells), read in Studio with EditableMesh and printed
to the Studio log as `P8D <cell> <kind> <mesh#> <part#> <27-char triangles>` (25 Nov 2026).

    python roadbugs_p8.py <studio log>   -> roadbugs_25nov/p8/<cell>_<kind>_<mesh#>.npy + entries added to match.json
Only up-facing triangles were dumped (all for B). Coordinates: 0.05 studs, x/z from the cell corner - 50, y + 200.
"""
import collections, json, os, re, sys
import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from roadbugs_index import OUT, ROOT

BASE = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!#$%&()*+,-./:;<=>?@[]^_{|}"
IDX = {c: i for i, c in enumerate(BASE)}
NB = len(BASE)


def main(log):
    txt = open(log, encoding='utf-8', errors='replace').read()
    txt = txt[txt.rfind('P8DUMPSTART'):]
    parts = collections.defaultdict(dict)
    for m in re.finditer(r'P8D (\d+x\d+) (\w+) (\d+) (\d+) (\S+)', txt):
        parts[(m.group(1), m.group(2), int(m.group(3)))][int(m.group(4))] = m.group(5)
    d = os.path.join(OUT, 'p8')
    os.makedirs(d, exist_ok=True)
    mj = json.load(open(os.path.join(OUT, 'match.json')))
    match = mj['match']
    for k in [k for k, v in match.items() if v['glb'].startswith('p8:')]:
        del match[k]
    n = 0
    for (cell, kind, mi), pg in sorted(parts.items()):
        s = ''.join(pg[i] for i in sorted(pg))
        s = s[:len(s) // 27 * 27]
        a = np.array([IDX[c] for c in s], dtype=np.int64).reshape(-1, 3)
        v = (a[:, 0] * NB * NB + a[:, 1] * NB + a[:, 2]).reshape(-1, 9).astype(np.float64) / 20.0
        cx, cz = (int(t) * 1536 for t in cell.split('x'))
        T = v.reshape(-1, 3, 3)
        T[:, :, 0] += cx - 50
        T[:, :, 1] -= 200
        T[:, :, 2] += cz - 50
        name = '%s_%s_%d' % (cell, kind, mi)
        np.save(os.path.join(d, name + '.npy'), T)
        match['p8_' + name] = dict(cell=cell, kind=kind, glb='p8:' + name, name=name, meshid='')
        n += len(T)
    json.dump(mj, open(os.path.join(OUT, 'match.json'), 'w'), indent=0)
    print('meshes', len(parts), 'triangles', n)


if __name__ == '__main__':
    main(sys.argv[1])
