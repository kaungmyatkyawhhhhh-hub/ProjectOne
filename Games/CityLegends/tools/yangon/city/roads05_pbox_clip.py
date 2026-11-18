"""roads05_pbox_clip.py (19 Nov 2026, map bug fixes): pavement collision only where a pavement is built.

roads05_bake.collision laid each pavement box (RoadBox "P", top = road + 0.5) along the road's whole length from the
data. Where the builder laid no pavement (junction mouths, driveways, side lanes under / beside a deck, gores) the box
stood 0.5 over the visible asphalt or grass: an invisible kerb (owner 18 Nov: "cars hit things you can't see").

clip(rows, parts) keeps each P row only over runs where the built pavement / kerb / median parts cover it (1-stud
slices, 2 of 3 points across covered, runs >= 1 stud). roads05_bake.collision calls it, so every new bake is clipped.

For a place already swapped (no re-bake needed: only P boxes change):
    python roads05_pbox_clip.py <tag> <collide dir> <out file>
-> <out file>: "-" lines (old P rows to delete, as written) and "+" lines (their clipped pieces). Studio:
tools/yangon/MapBugScan.luau S.pboxSwap(text) deletes each old box (P, centre within 0.03) and adds the new ones.
"""
import glob, math, os, pickle, sys

import numpy as np
import shapely
from shapely.strtree import STRtree

VIS = ('P', 'r', 'w', 'm', 'B')  # B: bridge walkways / parapet bases keep their boxes too


def footprints(parts, kinds):
    polys, tops = [], []
    for k, cls, pos, R, U, S in parts:
        if k not in kinds:
            continue
        R, U = np.array(R), np.array(U)
        B = np.cross(R, U)
        hx, hy, hz = S[0] / 2, S[1] / 2, S[2] / 2
        if cls == 'W':
            loc = [(sx * hx, -hy, sz * hz) for sx in (-1, 1) for sz in (-1, 1)] + [(sx * hx, hy, hz) for sx in (-1, 1)]
        else:
            loc = [(sx * hx, sy * hy, sz * hz) for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)]
        pts = np.array([np.array(pos) + R * a + U * b + B * c for a, b, c in loc])
        polys.append(shapely.convex_hull(shapely.multipoints(pts[:, [0, 2]])))
        tops.append(pts[:, 1].max())
    return np.array(polys, dtype=object), np.array(tops)


def parse(row):
    v = row.split()
    return v[0], np.array(list(map(float, v[1:4]))), np.array(list(map(float, v[4:7]))), np.array(list(map(float, v[7:10]))), np.array(list(map(float, v[10:13])))


def fmt(kind, c, R, U, S):
    return '%s %.2f %.2f %.2f %.4f %.4f %.4f %.4f %.4f %.4f %.2f %.2f %.2f' % ((kind,) + tuple(c) + tuple(R) + tuple(U) + tuple(S))


class Cover:
    def __init__(self, parts):
        self.polys, self.tops = footprints(parts, VIS)
        # bridge pieces (deck walls, girders, piers) count only as a walkway level with the box top (+-1)
        self.bridge = np.array([k == 'B' for k, *_ in parts if k in VIS])
        self.tree = STRtree(self.polys)

    def covered(self, pts):
        g = shapely.points(pts[:, [0, 2]])
        cov = np.zeros(len(pts), bool)
        a, b = self.tree.query(g, predicate='intersects')
        # (wide on purpose: a built piece 6 under to 3 over still keeps the box; only bare asphalt / ground loses it)
        ok = (self.tops[b] > pts[a, 1] - 6.0) & (self.tops[b] < pts[a, 1] + 3.0)
        ok &= ~self.bridge[b] | (np.abs(self.tops[b] - pts[a, 1]) < 1.0)
        cov[a[ok]] = True
        return cov


def clip_row(row, cover):
    """the row's pieces over built pavement: [] (none), [row] (all of it) or the pieces"""
    kind, c, R, U, S = parse(row)
    Bk = np.cross(R, U)
    top = c + U * S[1] / 2
    L = S[2]
    n = max(1, int(math.ceil(L)))
    t = (np.arange(n) + 0.5) / n * L - L / 2  # slice middles along
    pts = np.array([top + R * a * S[0] + Bk * ti for ti in t for a in (-0.35, 0, 0.35)])
    cov = cover.covered(pts).reshape(n, 3).sum(1) >= 2
    if cov.all():
        return [row]
    out = []
    i = 0
    while i < n:
        if not cov[i]:
            i += 1
            continue
        j = i
        while j + 1 < n and cov[j + 1]:
            j += 1
        a0, a1 = i / n * L - L / 2, (j + 1) / n * L - L / 2
        if a1 - a0 >= 1.0:
            mid = c + Bk * ((a0 + a1) / 2)
            out.append(fmt(kind, mid, R, U, (S[0], S[1], a1 - a0)))
        i = j + 1
    return out


def clip(rows, parts):
    cover = Cover(parts)
    out, changed = [], 0
    for r in rows:
        if r.split(' ', 1)[0] != 'P':
            out.append(r)
            continue
        new = clip_row(r, cover)
        if new != [r]:
            changed += 1
        out.extend(new)
    print('pavement boxes clipped to built pavement: %d rows changed' % changed)
    return out


if __name__ == '__main__':
    tag, cdir, outp = sys.argv[1:4]
    D = 'D:/ObsidianOne/Claude+Obsidian/Games/CityLegends/build/city_1to1/roads05_%s/' % tag
    parts = pickle.load(open(D + 'parts.pkl', 'rb'))
    # the bake's own scrap filter first (kerb / pavement scraps on a carriageway are not in the meshes)
    import json
    import roads05_bake as RB
    tris = [t for p in parts if p[0] == 'R' for t in RB.faces_of(p)]
    parts, _ = RB.drop_scraps(parts, json.load(open(D + 'roads.json', encoding='utf-8')), RB.Surface(tris))
    cover = Cover(parts)
    lines, nold, nnew = [], 0, 0
    for f in sorted(glob.glob(os.path.join(cdir, '*.txt'))):
        for r in open(f).read().split('\n'):
            if not r.startswith('P '):
                continue
            new = clip_row(r, cover)
            if new != [r]:
                lines.append('-' + r)
                lines.extend('+' + q for q in new)
                nold += 1
                nnew += len(new)
    open(outp, 'w', newline='\n').write('\n'.join(lines))
    print(tag, cdir, 'old P rows replaced', nold, 'new pieces', nnew)
