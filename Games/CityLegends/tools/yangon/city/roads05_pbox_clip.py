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
G0 = __import__('os').path.abspath(__import__('os').path.join(__import__('os').path.dirname(__file__), '..', '..', '..')).replace(chr(92), '/')  # game folder (was a fixed D: path)
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
        # (24 Nov, May Ni Gone Overpass deck end: a P box stood 0.7 over the deck's D box, "covered" by the ground
        # road's pavement 6 below) a point with a road surface just under the box top (top - 2 .. top + 0.2) is over
        # asphalt or a deck: never covered
        self.rpolys, self.rtops = footprints(parts, ('R',))
        self.rtree = STRtree(self.rpolys)

    def covered(self, pts):
        g = shapely.points(pts[:, [0, 2]])
        cov = np.zeros(len(pts), bool)
        a, b = self.tree.query(g, predicate='intersects')
        # (wide on purpose: a built piece 6 under to 3 over still keeps the box; only bare asphalt / ground loses it)
        ok = (self.tops[b] > pts[a, 1] - 6.0) & (self.tops[b] < pts[a, 1] + 3.0)
        ok &= ~self.bridge[b] | (np.abs(self.tops[b] - pts[a, 1]) < 1.0)
        cov[a[ok]] = True
        a, b = self.rtree.query(g, predicate='intersects')
        road = (self.rtops[b] > pts[a, 1] - 2.0) & (self.rtops[b] < pts[a, 1] + 0.2)
        cov[a[road]] = False
        return cov


def clip_row(row, cover):
    """the row's pieces over built pavement: [] (none), [row] (all of it) or the pieces. 1-stud slices along, each
    cut in 3 across; a piece = a run of slices with the same covered thirds, one box per covered band of thirds"""
    kind, c, R, U, S = parse(row)
    Bk = np.cross(R, U)
    top = c + U * S[1] / 2
    L, W = S[2], S[0]
    n = max(1, int(math.ceil(L)))
    t = (np.arange(n) + 0.5) / n * L - L / 2  # slice middles along
    across = (-W / 3, 0.0, W / 3)
    pts = np.array([top + R * a + Bk * ti for ti in t for a in across])
    cov = cover.covered(pts).reshape(n, 3)
    if cov.all():
        return [row]
    out = []
    i = 0
    while i < n:
        pat = tuple(cov[i])
        j = i
        while j + 1 < n and tuple(cov[j + 1]) == pat:
            j += 1
        a0, a1 = i / n * L - L / 2, (j + 1) / n * L - L / 2
        if any(pat) and a1 - a0 >= 1.0:
            k = 0
            while k < 3:  # bands of covered thirds
                if not pat[k]:
                    k += 1
                    continue
                m = k
                while m + 1 < 3 and pat[m + 1]:
                    m += 1
                l0, l1 = -W / 2 + k * W / 3, -W / 2 + (m + 1) * W / 3
                mid = c + Bk * ((a0 + a1) / 2) + R * ((l0 + l1) / 2)
                out.append(fmt(kind, mid, R, U, (l1 - l0, S[1], a1 - a0)))
                k = m + 1
        i = j + 1
    return out


def deck_tops(rows):
    """top faces of the deck boxes (D rows) as (polygons, top heights): a deck built in another cell has no R parts here"""
    polys, tops = [], []
    for r in rows:
        if r.split(' ', 1)[0] != 'D':
            continue
        kind, c, R, U, S = parse(r)
        Bk = np.cross(R, U)
        top = c + U * S[1] / 2
        pts = np.array([top + R * (a * S[0] / 2) + Bk * (b * S[2] / 2) for a in (-1, 1) for b in (-1, 1)])
        polys.append(shapely.convex_hull(shapely.multipoints(pts[:, [0, 2]])))
        tops.append(pts[:, 1].max())
    return polys, tops


def clip(rows, parts):
    cover = Cover(parts)
    dp, dt = deck_tops(rows)
    if dp:
        cover.rpolys = np.concatenate([cover.rpolys, np.array(dp, dtype=object)])
        cover.rtops = np.concatenate([cover.rtops, np.array(dt)])
        cover.rtree = STRtree(cover.rpolys)
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
    D = G0 + '/build/city_1to1/roads05_%s/' % tag
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
