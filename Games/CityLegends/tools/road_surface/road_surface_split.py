"""Split the place's road surface meshes (RMeshR) by real surface (27 Nov 2026, owner: "not every small road is
asphalt, the big roads & overhead roads are always asphalt"; vault `City Legends/2026-11-27 Roads - realistic surfaces
by road type.md`).

Kinds written (YangonRoadSurface.LOOK gives each its MaterialVariant + colour):
  R   big roads (OSM trunk / primary / secondary / tertiary + links) and every flyover deck: asphalt
  RP  (in the R mesh, vertex tint) sparse repair patches on R (rectangles along a lane, some long thin trench patches): same asphalt, darker
  RT  (in the R mesh, vertex tint) sparse tar-sealed crack seams on R (thin strips along / across a lane): same asphalt, near-black, glossier
  RC  small streets (residential / service / living_street / unclassified / track): cast concrete (OSM: untagged
      residential lanes in the owner's Yangon clips are pale concrete; OSM concrete / paving_stones / sett too)
  RA  small streets OSM-tagged asphalt / paved: rough lane asphalt (the asphalt variant, lighter and greyer)
  RU  small streets OSM-tagged unpaved / ground / gravel / dirt / compacted: packed gravel (YgnGravel)
Every piece is the old triangle cut exactly on the patch outline (roads05_clip), in the same plane: nothing new sits
over the road, so nothing can z-fight, and the paint (0.08 over the road) is untouched.

    python road_surface_split.py <work dir>
work dir holds match.json (roadbugs_index.py with RB_OUT=<work dir>, meshes_place.txt = Studio RMLIST rows of RMeshR
only). Writes <work dir>/glb/rsurf_<n>.glb (meshes KIND_<cell>s<k>_<box>), <work dir>/swap.json {old place row -> new
mesh names} and stats.json. Network: NET (roads05 P1-P12, the place's roads), OSM: build/osm_ygn/roads.json.
"""
import collections, json, math, os, sys
import numpy as np
import shapely
from shapely.geometry import Polygon, LineString, box as sbox
from scipy.spatial import cKDTree

os.environ.setdefault('YANGON_SCALE', '1to1')
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'tools', 'yangon', 'city'))
sys.stdout.reconfigure(encoding='utf-8')
import geo
import roads05_clip
from roadbugs_index import read_glb
from glb import Mesh, write_glb, code

NET = os.path.join(ROOT, 'build', 'city_1to1', 'roads05_P1_P2_P3_P4_P5_P6_P7_P8_P9_P10_P11_P12', 'roads.json')
OSM = os.path.join(ROOT, 'build', 'osm_ygn', 'roads.json')
BIG = {'motorway', 'trunk', 'primary', 'secondary', 'tertiary', 'motorway_link', 'trunk_link', 'primary_link',
       'secondary_link', 'tertiary_link'}
SURF = {'asphalt': 'RA', 'paved': 'RA', 'concrete': 'RC', 'concrete:lanes': 'RC', 'concrete:plates': 'RC',
        'paving_stones': 'RC', 'sett': 'RC', 'unpaved': 'RU', 'ground': 'RU', 'gravel': 'RU', 'dirt': 'RU',
        'compacted': 'RU', 'fine_gravel': 'RU', 'sand': 'RU', 'earth': 'RU', 'mud': 'RU'}
MAX_TRIS = 17000
FILE_TRIS = int(os.environ.get('RSURF_FILE_TRIS', 45000))   # ~5 MB a file: 10 MB uploads hung Studio's Assistant (27 Nov)
FILE_MESHES = 100
WHITE = (255, 255, 255)
# patches and tar seams ride in the R mesh as vertex colours (a .glb's vertex colour tints the MaterialVariant): no extra
# meshes for them (each is a unique mesh asset to stream)
MERGE = {'RP': 'R', 'RT': 'R'}
TINT = {'RP': (196, 196, 200), 'RT': (110, 110, 116)}
rng = np.random.default_rng(1127)


# ------------------------------------------------------------------------------------------------ network
def segments():
    """every sample pair of every road and deck: p0, p1 (x, y, z), half, cls ('R' or small kind), road index"""
    d = json.load(open(NET, encoding='utf-8'))
    roads = d['roads']
    small_kind = osm_surface(roads)
    S = []
    for i, r in enumerate(roads):
        cls = 'R' if r.get('hw') in BIG else small_kind.get(i, 'RC')
        s = r['s']
        for a, b in zip(s, s[1:]):
            S.append((a[:3], b[:3], max(a[6], a[7], b[6], b[7]), cls, i))
    for k, dk in enumerate(d['decks']):
        s = dk['s']
        for a, b in zip(s, s[1:]):
            S.append((a[:3], b[:3], max(a[6], a[7], b[6], b[7]), 'R', -1 - k))
    return roads, d['decks'], S


def osm_surface(roads):
    """small road index -> RA / RU where OSM tags the ways under it (majority of its samples), else nothing (RC)"""
    ways = json.load(open(OSM, encoding='utf-8'))['roads']
    pts, kinds = [], []
    for w in ways:
        t = w['t']
        k = SURF.get(t.get('surface', ''))
        if not k or t.get('highway') in BIG or t.get('highway') in ('footway', 'path', 'steps', 'cycleway', 'pedestrian'):
            continue
        P = [geo.world(lon, lat) for lon, lat in w['p']]
        for a, b in zip(P, P[1:]):
            n = max(1, int(math.dist(a, b) / 6))
            for j in range(n):
                f = (j + 0.5) / n
                pts.append((a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f))
                kinds.append(k)
    tree = cKDTree(np.array(pts))
    out = {}
    for i, r in enumerate(roads):
        if r.get('hw') in BIG:
            continue
        xz = np.array([(q[0], q[2]) for q in r['s']])
        dd, ii = tree.query(xz, distance_upper_bound=max(10.0, r['half'] * 0.8))
        votes = collections.Counter(kinds[j] for dist, j in zip(dd, ii) if np.isfinite(dist))
        if votes and sum(votes.values()) >= 0.5 * len(xz):
            out[i] = votes.most_common(1)[0][0]
    return out


class Classifier:
    def __init__(self, S):
        self.A = np.array([s[0] for s in S], float)
        self.B = np.array([s[1] for s in S], float)
        self.H = np.array([s[2] for s in S], float)
        self.C = [s[3] for s in S]
        self.tree = cKDTree(((self.A + self.B) / 2)[:, [0, 2]])

    def many(self, P, k=48):
        """kind of the road surface at each world point (n, 3): the biggest road whose corridor (and level) holds
        it, else the closest road at its level, else R (vectorised over the k nearest sample segments)"""
        k = min(k, len(self.A))
        _, I = self.tree.query(P[:, [0, 2]], k=k)
        A, B = self.A[I], self.B[I]                     # (n, k, 3)
        ab = B - A
        L2 = ab[..., 0] ** 2 + ab[..., 2] ** 2
        t = ((P[:, None, 0] - A[..., 0]) * ab[..., 0] + (P[:, None, 2] - A[..., 2]) * ab[..., 2]) / np.maximum(L2, 1e-9)
        t = np.clip(t, 0, 1)
        Q = A + ab * t[..., None]
        lat = np.hypot(P[:, None, 0] - Q[..., 0], P[:, None, 2] - Q[..., 2])
        over = lat - self.H[I]
        big = np.array([c == 'R' for c in self.C])[I]
        ok = np.abs(P[:, None, 1] - Q[..., 1]) <= 4.0
        # rank: inside a big corridor (0), inside a small one (1), outside: by distance past the edge
        score = np.where(over <= 1.5, np.where(big, -1e6, -1e5) + over, over)
        score = np.where(ok, score, np.inf)
        j = np.argmin(score, axis=1)
        C = np.array(self.C, dtype=object)
        out = C[I[np.arange(len(P)), j]]
        out[~np.isfinite(score[np.arange(len(P)), j])] = 'R'
        return out


# ------------------------------------------------------------------------------------------------ patches, seams
def big_overlays(roads, decks):
    """sparse repair patches (RP) and tar seams (RT) along the big roads: list of (kind, polygon xz, y)"""
    out = []
    lines = [(r['s'], r) for r in roads if r.get('hw') in BIG] + [(dk['s'], dk) for dk in decks]
    for s, r in lines:
        acc = 0.0
        nxt = rng.uniform(40, 160)
        for a, b in zip(s, s[1:]):
            L = math.hypot(b[0] - a[0], b[2] - a[2])
            acc += L
            while acc > nxt:
                f = 1 - (acc - nxt) / max(L, 1e-6)
                x, y, z = (a[i] + (b[i] - a[i]) * f for i in range(3))
                dx, dz = a[3], a[4]
                nx, nz = -dz, dx
                hl, hr = a[6], a[7]
                side = rng.uniform(-hl + 3, hr - 3) if hl + hr > 8 else 0.0
                cx, cz = x + nx * side, z + nz * side
                roll = rng.random()
                if roll < 0.55:      # repair patch: 5-16 long, 4-10 wide, a little skewed
                    l, w = rng.uniform(5, 16), rng.uniform(4, min(10, hl + hr - 2))
                    out.append(('RP', _rect(cx, cz, dx, dz, l, w, rng.uniform(-0.12, 0.12)), y))
                elif roll < 0.68:    # utility trench patch: long and thin along the lane
                    l, w = rng.uniform(30, 90), rng.uniform(2.2, 3.2)
                    out.append(('RP', _rect(cx, cz, dx, dz, l, w, 0), y))
                elif roll < 0.85:    # sealed crack along the lane (wavy)
                    out.append(('RT', _wavy(cx, cz, dx, dz, rng.uniform(25, 70), 0.45), y))
                else:                # sealed crack across the lane
                    out.append(('RT', _wavy(cx, cz, nx, nz, rng.uniform(8, 14), 0.4), y))
                nxt += rng.uniform(50, 170)
    return out


def _rect(cx, cz, dx, dz, l, w, skew):
    c, s = math.cos(skew), math.sin(skew)
    ux, uz = dx * c - dz * s, dx * s + dz * c
    vx, vz = -uz, ux
    return Polygon([(cx + ux * l / 2 * i + vx * w / 2 * j, cz + uz * l / 2 * i + vz * w / 2 * j)
                    for i, j in ((-1, -1), (1, -1), (1, 1), (-1, 1))])


def _wavy(cx, cz, dx, dz, l, w):
    nx, nz = -dz, dx
    n = max(3, int(l / 6))
    pts, off = [], 0.0
    for k in range(n + 1):
        t = -l / 2 + l * k / n
        off += rng.normal(0, 0.5)
        pts.append((cx + dx * t + nx * off, cz + dz * t + nz * off))
    return LineString(pts).buffer(w / 2, cap_style='flat', join_style='mitre', mitre_limit=2.0)


def uv_of(p, n):
    """box projection, 1 UV = 1 stud (roads05_bake.uv_of)"""
    ax = int(np.argmax(np.abs(n)))
    return (p[0], p[2]) if ax == 1 else (p[2], p[1]) if ax == 0 else (p[0], p[1])


# ------------------------------------------------------------------------------------------------ main
def cut(T, poly):
    """T split into (inside poly, outside poly), both exact and in the old triangles' planes"""
    if len(T) == 0:
        return T, T
    polys = shapely.polygons(T[:, :, [0, 2]])
    hit = shapely.intersects(polys, poly) & (shapely.area(shapely.intersection(polys, poly)) > 1e-6)
    if not hit.any():
        return T[:0], T
    miss, T = T[~hit], T[hit]
    # every hit triangle cut both ways explicitly (clip_tris keeps a triangle whole when its 3 corners are outside a
    # polygon, but a patch smaller than the triangle can sit inside it: the patch area was counted twice)
    ins, outs = [], []
    for t in T:
        n = np.cross(t[1] - t[0], t[2] - t[0])
        tp = Polygon(t[:, [0, 2]])
        if not tp.is_valid or abs(n[1]) < 0.05 * np.linalg.norm(n):   # walls stay whole (as clip_tris)
            outs.append(t)
            continue
        up = n[1] > 0
        for g, acc in ((tp.intersection(poly), ins), (tp.difference(poly), outs)):
            for xz in roads05_clip._tris_of(g):
                q = np.stack([xz[:, 0], roads05_clip._lift(t, xz), xz[:, 1]], 1)
                m = np.cross(q[1] - q[0], q[2] - q[0])
                acc.append(q if (m[1] > 0) == up else q[[0, 2, 1]])
    I = np.array(ins).reshape(-1, 3, 3)
    O = np.concatenate([miss, np.array(outs).reshape(-1, 3, 3)])
    return I, O


def area(T):
    return float(np.abs(np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0])[:, 1]).sum() / 2) if len(T) else 0.0


def main(work):
    match = json.load(open(os.path.join(work, 'match.json')))['match']
    roads, decks, S = segments()
    classify = Classifier(S)
    ov = big_overlays(roads, decks)
    otree = shapely.STRtree([g for _, g, _ in ov])
    print('network segments', len(S), 'overlays', collections.Counter(k for k, _, _ in ov))
    glbs = {}
    out = collections.defaultdict(list)   # (kind, cell) -> triangles
    swap = collections.defaultdict(list)  # cell -> old place rows
    stats = collections.Counter()
    for row, m in sorted(match.items(), key=lambda kv: str(kv[0])):
        if m['kind'] != 'R':
            continue
        if m['glb'] not in glbs:
            glbs[m['glb']] = read_glb(os.path.join(ROOT, m['glb']))
        T = glbs[m['glb']][m['name']]
        stats['tris_in'] += len(T)
        stats['area_in'] += area(T)
        swap[m['cell']].append(row)
        mids = T.mean(1)
        cls = classify.many(mids)
        for k in ('RC', 'RA', 'RU'):
            out[(k, m['cell'])].extend(T[cls == k])
        TB = T[cls == 'R']
        # overlays on this mesh's big triangles (same level only)
        if len(TB):
            lo, hi = TB[:, :, [0, 2]].min((0, 1)), TB[:, :, [0, 2]].max((0, 1))
            near = otree.query(sbox(lo[0], lo[1], hi[0], hi[1]))
            ymin, ymax = TB[:, :, 1].min() - 4, TB[:, :, 1].max() + 4
            for k in ('RT', 'RP'):   # seams win over patches where they cross
                gs = [ov[i][1] for i in near if ov[i][0] == k and ymin <= ov[i][2] <= ymax]
                if not gs or not len(TB):
                    continue
                poly = shapely.union_all(gs)
                # only triangles near their overlay's own level (a deck patch never cuts the road under the deck)
                ins, TB = cut(TB, poly)
                out[(k, m['cell'])].extend(ins)
            out[('R', m['cell'])].extend(TB)
    # meshes (<= MAX_TRIS each), files (<= FILE_MESHES meshes, FILE_TRIS triangles)
    gdir = os.path.join(work, 'glb')
    os.makedirs(gdir, exist_ok=True)
    for f in os.listdir(gdir):
        os.remove(os.path.join(gdir, f))
    named = []
    merged = collections.defaultdict(list)   # (mesh kind, cell) -> [(triangles, tint)]
    for (kind, cell), ts in sorted(out.items()):
        ts = np.array(ts, float).reshape(-1, 3, 3)
        stats['tris_' + kind] += len(ts)
        stats['area_out'] += area(ts)
        stats['area_' + kind] += area(ts)
        merged[(MERGE.get(kind, kind), cell)].append((ts, TINT.get(kind, WHITE)))
    for (kind, cell), parts in sorted(merged.items()):
        ts = np.concatenate([t for t, _ in parts])
        cs = [c for t, c in parts for _ in range(len(t))]
        for s0 in range(0, len(ts), MAX_TRIS):
            chunk = ts[s0:s0 + MAX_TRIS]
            P = chunk.reshape(-1, 3)
            lo, hi = P.min(0), P.max(0)
            centre, size = (lo + hi) / 2, np.maximum(hi - lo, 0.05)
            assert size.max() <= 2048, (kind, cell, size)
            mesh = Mesh()
            for t, rgb in zip(chunk, cs[s0:s0 + MAX_TRIS]):
                n = np.cross(t[1] - t[0], t[2] - t[0])
                if np.linalg.norm(n) < 1e-9:
                    continue
                uv = [uv_of(q, n) for q in t]
                mesh.tri(tuple(t[0]), tuple(t[1]), tuple(t[2]), uv[0], uv[1], uv[2], rgb)
            named.append((code(kind, '%ss%d' % (cell, s0 // MAX_TRIS), tuple(centre), tuple(size)), mesh, len(chunk)))
    files, cur, ct = [], [], 0
    for item in named:
        if cur and (len(cur) >= FILE_MESHES or ct + item[2] > FILE_TRIS):
            files.append(cur)
            cur, ct = [], 0
        cur.append(item)
        ct += item[2]
    if cur:
        files.append(cur)
    for i, f in enumerate(files):
        write_glb(os.path.join(gdir, 'rsurf_%d.glb' % (i + 1)), [(nm, mm) for nm, mm, _ in f], generator='road_surface_split.py')
    stats['meshes_out'] = len(named)
    stats['files'] = len(files)
    # self-check: the cut keeps the surface (area in = area out within 0.1%)
    assert abs(stats['area_out'] - stats['area_in']) < 0.001 * stats['area_in'] + 1, (stats['area_in'], stats['area_out'])
    json.dump({c: rows for c, rows in swap.items()}, open(os.path.join(work, 'swap.json'), 'w'))
    json.dump(dict(stats), open(os.path.join(work, 'stats.json'), 'w'), indent=1)
    print(dict(stats))


if __name__ == '__main__':
    main(sys.argv[1])
