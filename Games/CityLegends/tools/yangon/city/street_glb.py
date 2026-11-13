"""Whole-Yangon map (14 Nov 2026): the street meshes from streets.py as .glb packs for Open Cloud.

Reads build/city/streets_<tag>_meshes.pkl ({(kind, cx, cz): [triangle [(x, y, z) x3], ...]}), writes
imports/sync/ygn_streets/<tag>_<n>.glb (at most 100 meshes / 90,000 triangles a file; Open Cloud only uploads from imports/)
and build/city/streets_<tag>_manifest.json. Mesh names: KIND_<cx>x<cz>[s<k>]_<centre>_<size> (glb.code), KIND = SR (asphalt),
SP (pavement + kerb faces), SL (lines). Colours are vertex colours matching the part roads (Road Asphalt 46, 47, 50;
Pavement Sandstone 128, 124, 116; Line 235, 235, 230); the Studio placer sets the Material and a white Color.

  python street_glb.py 05
"""
import json, os, pickle, sys

import geo
from glb import Mesh, write_glb, code

MAXT = 17000
COL = {'R': (46, 47, 50), 'P': (128, 124, 116), 'L': (235, 235, 230)}


def main(tag):
    meshes = pickle.load(open(os.path.join(geo.BUILD, 'city', f'streets_{tag}_meshes.pkl'), 'rb'))
    named = []
    for (kind, cx, cz), tris in sorted(meshes.items()):
        parts = [tris[i:i + MAXT] for i in range(0, len(tris), MAXT)]
        for k, part in enumerate(parts):
            m = Mesh()
            for t in part:
                a, b, c = t
                if kind == 'P' and abs(a[1] - b[1]) + abs(b[1] - c[1]) + abs(a[1] - c[1]) > 0.3 and \
                        abs(a[0] - c[0]) + abs(a[2] - c[2]) < 0.01 + max(abs(a[0] - b[0]), abs(a[2] - b[2])) * 2:
                    pass
                m.tri(a, b, c, (0, 0), (0, 0), (0, 0), COL[kind])
                # (the kerb faces are vertical: draw them from both sides, their winding depends on the ring's direction)
                if kind == 'P':
                    ys = (a[1], b[1], c[1])
                    flat = max(ys) - min(ys) < 0.45
                    if not flat and abs(a[0] - b[0]) + abs(a[2] - b[2]) + abs(a[0] - c[0]) + abs(a[2] - c[2]) < 40:
                        m.tri(a, c, b, (0, 0), (0, 0), (0, 0), COL[kind])
            if not m.T:
                continue
            lo, hi = m.box()
            centre = [(lo[i] + hi[i]) / 2 for i in range(3)]
            size = [max(0.05, hi[i] - lo[i]) for i in range(3)]
            cid = f"{cx}x{cz}".replace('-', 'n') + (f"s{k}" if len(parts) > 1 else '')
            named.append((code('S' + kind, cid, centre, size), m))
    outdir = os.path.join(geo.ROOT, 'imports', 'sync', 'ygn_streets')
    os.makedirs(outdir, exist_ok=True)
    for f in os.listdir(outdir):
        if f.startswith(tag + '_'):
            os.remove(os.path.join(outdir, f))
    files, cur, curt = [], [], 0
    for name, m in named:
        if cur and (len(cur) >= 100 or curt + m.tris > 90000):
            files.append(cur)
            cur, curt = [], 0
        cur.append((name, m))
        curt += m.tris
    if cur:
        files.append(cur)
    man = []
    for i, f in enumerate(files, 1):
        path = os.path.join(outdir, f'{tag}_{i}.glb')
        write_glb(path, f)
        man.append({'glb': os.path.basename(path), 'meshes': len(f), 'tris': sum(m.tris for _, m in f)})
    json.dump({'files': man}, open(os.path.join(geo.BUILD, 'city', f'streets_{tag}_manifest.json'), 'w'), indent=1)
    print(len(named), 'meshes,', sum(x['tris'] for x in man), 'triangles,', len(files), 'files')


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    main(sys.argv[1])
