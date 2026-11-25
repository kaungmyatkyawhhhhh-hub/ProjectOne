"""Top-down picture of the place's road meshes (25 Nov 2026, road bug sweep).

    python roadbugs_view.py x z size out.png [spots_<tag>.json]
Colours: R asphalt dark, P pavement grey, KR red, KW white-ish, MG green, B concrete blue-grey, L white, LY yellow, LZ cream.
Spots (if given) are drawn as magenta rings with a letter per kind. Data centre lines thin cyan.
"""
import json, os, sys
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.collections import PolyCollection

sys.path.insert(0, os.path.dirname(__file__))
from roadbugs_index import read_glb, ROOT, OUT

COL = {'R': '#2b2f3a', 'P': '#9a968e', 'KR': '#c0303a', 'KW': '#e8e8e8', 'MG': '#3f9a3a', 'B': '#7d8a9a',
       'L': '#ffffff', 'LY': '#f0d040', 'LZ': '#f6efc8'}
ORDER = ['R', 'P', 'MG', 'B', 'KR', 'KW', 'LZ', 'L', 'LY']


def view(x, z, size, out, spots=None, title=''):
    match = json.load(open(os.path.join(OUT, 'match.json')))['match']
    x0, z0, x1, z1 = x - size / 2, z - size / 2, x + size / 2, z + size / 2
    cells = set('%dx%d' % (cx, cz) for cx in range(int(x0 // 1536), int(x1 // 1536) + 1)
                for cz in range(int(z0 // 1536), int(z1 // 1536) + 1))
    by = {}
    cache = {}
    for m in match.values():
        if m['cell'] not in cells:
            continue
        if m['glb'] not in cache:
            cache[m['glb']] = read_glb(os.path.join(ROOT, m['glb']))
        T = cache[m['glb']][m['name']]
        c = T.mean(1)
        T = T[(c[:, 0] > x0 - 50) & (c[:, 0] < x1 + 50) & (c[:, 2] > z0 - 50) & (c[:, 2] < z1 + 50)]
        by.setdefault(m['kind'], []).append(T)
    fig = plt.figure(figsize=(10, 10), dpi=110)
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_facecolor('#6f8f4a')
    for k in ORDER:
        if k not in by:
            continue
        T = np.concatenate(by[k])
        if not len(T):
            continue
        # higher kinds drawn later; within a kind lower triangles first
        o = np.argsort(T[:, :, 1].mean(1))
        T = T[o]
        ax.add_collection(PolyCollection(T[:, :, [0, 2]], facecolors=COL[k], edgecolors='none', linewidths=0))
    if spots:
        for kind, rows in spots.items():
            pts = [r for r in rows if x0 <= r[1] <= x1 and z0 <= r[3] <= z1]
            if pts:
                ax.scatter([r[1] for r in pts], [r[3] for r in pts], s=90, facecolors='none', edgecolors='m', linewidths=1.2)
                for r in pts[:60]:
                    ax.text(r[1] + 3, r[3] + 3, kind[:3], color='m', fontsize=6)
    ax.set_xlim(x0, x1)
    ax.set_ylim(z1, z0)  # z down the page (north up when -z is north)
    ax.set_aspect('equal')
    ax.text(x0 + 5, z0 + 15, '%s (%.0f, %.0f) %d studs' % (title, x, z, size), color='w', fontsize=9)
    fig.savefig(out)
    plt.close(fig)


if __name__ == '__main__':
    x, z, size = map(float, sys.argv[1:4])
    sp = json.load(open(sys.argv[5])) if len(sys.argv) > 5 else None
    view(x, z, size, sys.argv[4], sp)
