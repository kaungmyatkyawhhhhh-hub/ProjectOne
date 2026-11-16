"""Partial roads05 rebuild without re-sending whole cells (17 Nov 2026, owner's road bugs 1-5).

When only the medians and the decks change (roads05.py med_runs / deck_profile, YangonRoads.buildDecks), Studio
rebuilds just those (Median / MedianKerb parts of the changed roads, the Decks folder) and RoadBake05 pages them out
under the cell name "FIX". This swaps them into the baked parts:

    YANGON_SCALE=1to1 python roads05_patch.py <tag> <old roads.json> <pages folder> <parts.pkl> [<parts.pkl> ...]
-> build/city_1to1/roads05_<tag>/parts.pkl (old one kept as parts_before_patch.pkl) and patch_cells.txt (the 1536
cells to re-bake: R05_ONLY)

Old parts dropped: kerb bands / median grass (r, w, m) lying inside an old median (|lateral| < mb + 0.6 at a sample
with mb > 0) of a road whose medians changed; deck surface (R within the slab and 3 studs of the old deck height,
inside the cut run) and bridge concrete (B within the slab + 10, under the old deck + 5) of every old deck.
"""
import json, os, pickle, sys

import numpy as np
from scipy.spatial import cKDTree

import geo
import roads05_bake as RB


def main():
    tag, old_json, pages = sys.argv[1], sys.argv[2], sys.argv[3]
    pkls = sys.argv[4:]
    D = RB.od(tag)
    old = json.load(open(old_json, encoding='utf-8'))
    new = json.load(open(os.path.join(D, 'roads.json'), encoding='utf-8'))
    parts = []
    for p in pkls:
        parts.extend(pickle.load(open(p, 'rb')))
    N = {r['name']: r for r in new['roads']}
    # roads whose medians changed
    med = []
    for r in old['roads']:
        n = N.get(r['name'])
        a = np.array(r['s'])
        if n is None or len(n['s']) != len(a) or np.abs(np.array(n['s'])[:, 8] - a[:, 8]).max() > 0.01:
            if (a[:, 8] > 0).any():
                med.append(a)
    pos = np.array([p[2] for p in parts])
    kind = np.array([p[0] for p in parts])
    drop = np.zeros(len(parts), bool)
    cells = set()
    for a in med:
        t = cKDTree(a[:, [0, 2]])
        sel = np.isin(kind, ['r', 'w', 'm'])
        idx = np.where(sel)[0]
        d, j = t.query(pos[idx][:, [0, 2]], distance_upper_bound=40)
        ok = np.isfinite(d)
        idx, j = idx[ok], j[ok]
        q = a[j]
        lat = np.abs((pos[idx, 0] - q[:, 0]) * -q[:, 4] + (pos[idx, 2] - q[:, 2]) * q[:, 3])
        mbn = np.maximum(q[:, 8], np.maximum(a[np.maximum(j - 1, 0), 8], a[np.minimum(j + 1, len(a) - 1), 8]))
        hit = idx[(mbn > 0) & (lat < mbn + 0.6) & (np.abs(pos[idx, 1] - q[:, 1]) < 6)]
        drop[hit] = True
        for i in np.where(a[:, 8] > 0)[0]:
            cells.add(RB.cell_of(a[i, 0], a[i, 2]))
    nmed = int(drop.sum())
    for d in old['decks']:
        s = np.array(d['s'])
        c = np.r_[0, np.cumsum(np.linalg.norm(np.diff(s[:, [0, 2]], axis=0), axis=1))]
        t = cKDTree(s[:, [0, 2]])
        dd, j = t.query(pos[:, [0, 2]], distance_upper_bound=d['half'] + 14)
        ok = np.where(np.isfinite(dd))[0]
        j = j[ok]
        q = s[j]
        f = np.c_[q[:, 3], q[:, 4]]
        rel = pos[ok][:, [0, 2]] - q[:, [0, 2]]
        lat = np.abs(rel[:, 0] * -f[:, 1] + rel[:, 1] * f[:, 0])
        along = c[j] + rel[:, 0] * f[:, 0] + rel[:, 1] * f[:, 1]
        dy = pos[ok, 1] - q[:, 1]
        inrun = (along > 2) & (along < c[-1] - 2)
        surf = (kind[ok] == 'R') & inrun & (lat < d['half'] + 2) & (np.abs(dy) < 3)
        conc = (kind[ok] == 'B') & (along > -4) & (along < c[-1] + 4) & (lat < d['half'] + 10) & (dy < 5)
        drop[ok[surf | conc]] = True
        for p in s:
            cells.add(RB.cell_of(p[0], p[2]))
    ndeck = int(drop.sum()) - nmed
    pg = RB.read_pages([pages])
    fresh = []
    for (cell, k) in sorted(pg):
        _, body, fmt = pg[(cell, k)]
        fresh.extend(RB.decode_q(body) if fmt == 'Q' else RB.decode(body))
    for p in fresh:
        cells.add(RB.cell_of(p[2][0], p[2][2]))
    out = [p for i, p in enumerate(parts) if not drop[i]] + fresh
    dst = os.path.join(D, 'parts.pkl')
    if os.path.exists(dst) and not os.path.exists(os.path.join(D, 'parts_before_patch.pkl')):
        os.replace(dst, os.path.join(D, 'parts_before_patch.pkl'))
    pickle.dump(out, open(dst, 'wb'))
    open(os.path.join(D, 'patch_cells.txt'), 'w').write(','.join(sorted(cells)))
    print(json.dumps(dict(parts_in=len(parts), dropped_median=nmed, dropped_deck=ndeck, fresh=len(fresh), parts_out=len(out),
                          cells=len(cells), median_roads=len(med)), indent=1))


if __name__ == '__main__':
    main()
