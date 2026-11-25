"""Road bug detector (25 Nov 2026, owner: "countless bugs" on the roads; shots City Legends/refs_2026-11-25_owner_road_bugs/).

Reads the triangles of the road meshes that are really in the place (roadbugs_index.py -> match.json) and counts each bug
kind per 1536 cell:
  sliver      R (asphalt) triangle with a tiny angle (< 3 deg), long (> 20 studs) and reaching > 4 studs past the data's
              carriageway (the sawtooth spikes into the grass, shot 2)
  hole        data carriageway points (ground roads, not cut / deck) with no asphalt under them (the missing carriageway, shot 2)
  grass_flat  MG (median / island grass) triangle lying on the asphalt (< 0.3 over it) (shots 3, 4)
  median_jct  median grass piece (connected) whose nearest point is < 12 studs from a junction / crossing point (stub in the
              junction, shots 1, 3)
  median_stub median grass piece under 25 sq studs (wedge / stub)
  kerb_loose  kerb top triangle over the asphalt, > 3 studs from any pavement / median grass (kerb lying on the road, shot 4)
  paint_cross two paint triangles (L / LY) overlapping at > 10 deg (lines crossing, shot 4)
  yellow_jct  yellow paint < 10 studs from a junction / crossing point (yellow running into the junction, shot 4)
  lone_dash   white lane dash with no other lane mark in line within 40 studs (shot 1)
  wall_low    bridge concrete (B) triangle within 2.5 studs of the asphalt, < 30 studs from a junction / crossing (ramp wall
              at ground level in a junction, shot 4: DECK agent's, report only)
    python roadbugs_detect.py [cells,...]     -> build/city_1to1/roadbugs_25nov/counts.json + spots.json
"""
import collections, json, math, os, sys
import numpy as np
import shapely
from shapely.geometry import Polygon, Point, LineString
from shapely.strtree import STRtree

sys.path.insert(0, os.path.dirname(__file__))
from roadbugs_index import read_glb, ROOT, OUT

NET = os.path.join(ROOT, 'build', 'city_1to1', 'roads05_P1_P2_P3_P4_P5_P6_P7_P8_P9_P10_P11_P12')
CELL = 1536.0
SPIKE_ANG = float(os.environ.get('SPIKE_ANG', 75))
KINDS = ('spike', 'gap', 'hole', 'grass_flat', 'median_jct', 'median_stub', 'kerb_loose', 'paint_cross', 'yellow_jct',
         'lone_dash', 'wall_low')


def cell_of(x, z):
    return '%dx%d' % (math.floor(x / CELL), math.floor(z / CELL))


def angles(T):
    a, b, c = T[:, 0], T[:, 1], T[:, 2]
    def ang(p, q, r):
        u, v = q - p, r - p
        cu = (u * v).sum(1) / (np.linalg.norm(u, axis=1) * np.linalg.norm(v, axis=1) + 1e-12)
        return np.degrees(np.arccos(np.clip(cu, -1, 1)))
    return np.stack([ang(a, b, c), ang(b, c, a), ang(c, a, b)], 1)


def up(T):
    n = np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0])
    L = np.linalg.norm(n, axis=1) + 1e-12
    return n[:, 1] / L, L / 2


def polys(T):
    return [Polygon([(t[0, 0], t[0, 2]), (t[1, 0], t[1, 2]), (t[2, 0], t[2, 2])]) for t in T]


class Surf:
    """2D index of up-facing triangles; y at a point (highest within dy of a ref, or all)."""
    def __init__(self, T):
        uy, area = up(T) if len(T) else (np.zeros(0), np.zeros(0))
        keep = (np.abs(uy) > 0.5) & (area > 1e-4)
        self.T = T[keep] if len(T) else T
        self.P = polys(self.T)
        self.tree = STRtree(self.P) if self.P else None

    def ys(self, x, z):
        if self.tree is None:
            return []
        out = []
        pt = Point(x, z)
        for i in self.tree.query(pt):
            if self.P[i].covers(pt):
                t = self.T[i]
                n = np.cross(t[1] - t[0], t[2] - t[0])
                if abs(n[1]) < 1e-9:
                    continue
                out.append(t[0, 1] - (n[0] * (x - t[0, 0]) + n[2] * (z - t[0, 2])) / n[1])
        return out

    def near(self, x, y, z, r, dy):
        if self.tree is None:
            return False
        pt = Point(x, z)
        for i in self.tree.query(pt.buffer(r)):
            if abs(self.T[i][:, 1].mean() - y) < dy and self.P[i].distance(pt) <= r:
                return True
        return False

    def dist(self, x, z, r):
        if self.tree is None:
            return 1e9
        pt = Point(x, z)
        best = 1e9
        for i in self.tree.query(pt.buffer(r)):
            best = min(best, self.P[i].distance(pt))
        return best


def load_net():
    d = json.load(open(os.path.join(NET, 'roads.json'), encoding='utf-8'))
    jpts = [(j['x'], j['z']) for j in d['junctions']] + [(c[4], c[5]) for c in d['crossings']]
    deck_rng = collections.defaultdict(list)
    for dk in d['decks']:
        deck_rng[dk['of']].append((dk['from'] - 2, dk['to'] + 2))
    cut = {k: set(v) for k, v in d['cut'].items()}
    car = collections.defaultdict(list)   # cell -> carriageway quads (2D) of ground roads
    probes = collections.defaultdict(list)  # cell -> (x, y, z, road) points that must have asphalt
    for r in d['roads']:
        s = r['s']
        rng = deck_rng.get(r['name'], [])
        cs = cut.get(r['name'], set())
        for i in range(len(s) - 1):
            a, b = s[i], s[i + 1]
            if any(lo <= i <= hi for lo, hi in rng) or i in cs:
                continue
            nx, nz = a[4], -a[3]
            hl, hr = a[6], a[7]
            q = Polygon([(a[0] + nx * hl, a[2] + nz * hl), (b[0] + b[4] * hl, b[2] - b[3] * hl),
                         (b[0] - b[4] * hr, b[2] + b[3] * hr), (a[0] - nx * hr, a[2] - nz * hr)])
            if q.is_valid and q.area > 0:
                car[cell_of(a[0], a[2])].append(q)
            if r.get('kind') != 'street' or True:
                med = a[8] if len(a) > 8 else 0
                for f in (0.55, -0.55):
                    h = hl if f > 0 else hr
                    off = f * max(h, med / 2 + 2)
                    if abs(off) <= med / 2 + 1:
                        continue
                    probes[cell_of(a[0], a[2])].append((a[0] + nx * off, a[1], a[2] + nz * off, r['name']))
    return d, jpts, car, probes


_G = {}


def _init():
    d, jpts, car, probes = load_net()
    _G.update(d=d, car=car, probes=probes, jtree=STRtree([Point(p) for p in jpts]),
              dtree=STRtree([LineString([(q[0], q[2]) for q in dk['s']]).buffer(dk.get('half', 24) + 6)
                             for dk in d['decks'] if len(dk['s']) > 1]))


def cell_job(arg):
    cell, ms, nbms = arg
    if not _G:
        _init()
    car, probes, jtree, dtree = _G['car'], _G['probes'], _G['jtree'], _G['dtree']
    byk = collections.defaultdict(list)
    cache = {}
    for m in ms:
        if m['glb'] not in cache:
            cache[m['glb']] = read_glb(os.path.join(ROOT, m['glb']))
        byk[m['kind']].append(cache[m['glb']][m['name']])
    nbR = []
    for m in nbms:
        if m['glb'] not in cache:
            cache[m['glb']] = read_glb(os.path.join(ROOT, m['glb']))
        nbR.append(cache[m['glb']][m['name']])
    spots = collections.defaultdict(list)
    if True:
        K = {k: (np.concatenate(v) if v else np.zeros((0, 3, 3))) for k, v in byk.items()}
        get = lambda k: K.get(k, np.zeros((0, 3, 3)))
        R = Surf(get('R'))
        c = collections.Counter()
        def spot(kind, x, y, z, info=''):
            c[kind] += 1
            spots[kind].append((cell, round(float(x), 1), round(float(y), 1), round(float(z), 1), info))
        def near_deck(m):
            return len(dtree.query(Point(m[0], m[2]), predicate='dwithin', distance=6)) > 0

        def near_j(x, z, r):
            return len(jtree.query(Point(x, z).buffer(r))) > 0
        # carriageway of the data in this cell (+ neighbours' quads that reach in)
        cx, cz = map(int, cell.split('x'))
        quads = [q for dx in (-1, 0, 1) for dz in (-1, 0, 1) for q in car.get('%dx%d' % (cx + dx, cz + dz), [])]
        cw = shapely.union_all(quads) if quads else Polygon()
        shapely.prepare(cw)
        # spike: a sharp tip on the outline of the asphalt (sawtooth teeth at a clip seam, slivers into the grass)
        if len(R.T):
            # (the neighbours' asphalt within 80 studs too: triangles go to a cell by their middle, so a cell's own outline
            # is toothed along its border)
            x0c, z0c = cx * CELL, cz * CELL
            NB_ = [T2 for T2 in nbR if len(T2)]
            allP = list(R.P)
            if NB_:
                T2 = np.concatenate(NB_)
                c2 = T2.mean(1)
                T2 = T2[(c2[:, 0] > x0c - 80) & (c2[:, 0] < x0c + CELL + 80) & (c2[:, 2] > z0c - 80) & (c2[:, 2] < z0c + CELL + 80)]
                allP += Surf(T2).P
            U = shapely.union_all([p.buffer(0.03, join_style=2) for p in allP])
            cellbox = Polygon([(x0c, z0c), (x0c + CELL, z0c), (x0c + CELL, z0c + CELL), (x0c, z0c + CELL)])
            for g in getattr(U, 'geoms', [U]):
                for ring in [g.exterior] + list(g.interiors):
                    xy = np.array(ring.coords)[:-1]
                    if len(xy) < 3:
                        continue
                    seen = set()
                    for i in range(len(xy)):
                        p0, p1, p2 = xy[i - 1], xy[i], xy[(i + 1) % len(xy)]
                        u, v = p0 - p1, p2 - p1
                        lu, lv = np.linalg.norm(u), np.linalg.norm(v)
                        if lu < 3 or lv < 3:
                            continue
                        ang = math.degrees(math.acos(max(-1, min(1, (u @ v) / (lu * lv)))))
                        if ang < SPIKE_ANG:
                            mid = (p1 + (p0 + p2) / 2) / 2
                            if g.contains(Point(mid)) and cellbox.contains(Point(p1)) and not near_deck((p1[0], 0, p1[1])):  # a convex tip (not a notch)
                                key = (round(p1[0] / 6), round(p1[1] / 6))
                                if key not in seen:
                                    seen.add(key)
                                    ys = [yy for yy in R.ys(mid[0], mid[1])]
                                    spot('spike', p1[0], ys[0] if ys else 0, p1[1], 'ang %.0f' % ang)
        # gap: a small bare patch enclosed by road surfaces (grass showing through at a mouth corner, shot 3)
        if len(R.T) and os.environ.get('RB_GAP', '1') == '1':
            surf_all = [R.P] + [Surf(get(k)).P for k in ('P', 'KR', 'KW', 'MG', 'B') if len(get(k))]
            UA = shapely.union_all([p.buffer(0.05, join_style=2) for ps in surf_all for p in ps])
            for g in getattr(UA, 'geoms', [UA]):
                for ring in g.interiors:
                    h = Polygon(ring)
                    if 1.5 < h.area < 600:
                        pc = h.representative_point()
                        if not near_deck((pc.x, 0, pc.y)):
                            ys = R.ys(pc.x, pc.y)
                            spot('gap', pc.x, 0, pc.y, 'area %.0f' % h.area)
        # hole
        for (x, y, z, nm) in (probes.get(cell, []) if os.environ.get('RB_HOLE') else []):
            if not R.near(x, y, z, 0.5, 12):
                spot('hole', x, y, z, nm)
        # grass flat on asphalt
        MG = get('MG')
        if len(MG):
            uy, area = up(MG)
            kerbs = np.concatenate([get('KR'), get('KW')])
            KS = Surf(kerbs) if len(kerbs) else None
            top0 = MG[(uy > 0.5) & (area > 0.05)]
            if len(top0):
                U0 = shapely.union_all([p.buffer(0.05) for p in polys(top0)])
                for g in getattr(U0, 'geoms', [U0]):
                    pc = g.representative_point()
                    ys = R.ys(pc.x, pc.y)
                    my = [t for t in top0 if Polygon([(t[0, 0], t[0, 2]), (t[1, 0], t[1, 2]), (t[2, 0], t[2, 2])]).buffer(0.1).covers(pc)]
                    gy = my[0][:, 1].mean() if my else None
                    if gy is None or not ys or min(abs(gy - yy) for yy in ys) > 0.4:
                        continue
                    # a median / island is ringed by kerbs; grass lying loose on the asphalt is not
                    ring = g.exterior
                    n = max(4, int(ring.length / 2))
                    lined = sum(1 for k2 in range(n) if KS is not None and KS.dist(*ring.interpolate(k2 / n, normalized=True).coords[0], 2.5) < 2.0)
                    if lined / n < 0.5:
                        spot('grass_flat', pc.x, gy, pc.y, 'area %.0f lined %.0f%%' % (g.area, 100 * lined / n))
            # median pieces
            top = MG[(uy > 0.5) & (area > 1e-3)]
            if len(top):
                U = shapely.union_all([p.buffer(0.05) for p in polys(top)])
                for g in getattr(U, 'geoms', [U]):
                    pc = g.representative_point()
                    if g.area < 25:
                        spot('median_stub', pc.x, top[:, :, 1].mean(), pc.y, 'area %.1f' % g.area)
                    hit = jtree.query(g.buffer(12))
                    if len(hit):
                        spot('median_jct', pc.x, top[:, :, 1].mean(), pc.y, 'area %.0f' % g.area)
        # loose kerbs
        side = np.concatenate([get('P'), get('MG')])
        S = Surf(side)
        for k in ('KR', 'KW'):
            Kt = get(k)
            if not len(Kt):
                continue
            uy, area = up(Kt)
            for t in Kt[(uy > 0.7) & (area > 0.2)]:
                m = t.mean(0)
                ys = [yy for yy in R.ys(m[0], m[2]) if yy < m[1] + 0.05]
                if ys and m[1] - max(ys) < 1.5 and S.dist(m[0], m[2], 4) > 3:
                    spot('kerb_loose', m[0], m[1], m[2], k)
        # paint crossing / yellow in junction / lone dash
        pt = []
        for k in ('L', 'LY'):
            Pk = get(k)
            if len(Pk):
                uy, area = up(Pk)
                Pk = Pk[(uy > 0.5) & (area > 0.01)]
                for t in Pk:
                    e = [t[1] - t[0], t[2] - t[1], t[0] - t[2]]
                    L = max(e, key=lambda v: v[0] ** 2 + v[2] ** 2)
                    pt.append((k, t, math.atan2(L[2], L[0]) % math.pi))
        if pt:
            P2 = polys(np.array([q[1] for q in pt]))
            tr = STRtree(P2)
            seen = set()
            for i, (k, t, a) in enumerate(pt):
                for j in tr.query(P2[i]):
                    if j <= i:
                        continue
                    da = abs(a - pt[j][2])
                    da = min(da, math.pi - da)
                    if da > math.radians(10) and P2[i].intersection(P2[j]).area > 0.15:
                        m = t.mean(0)
                        key = (round(m[0] / 4), round(m[2] / 4))
                        if key not in seen:
                            seen.add(key)
                            spot('paint_cross', m[0], m[1], m[2], '%s/%s %.0f' % (k, pt[j][0], math.degrees(da)))
            ys_ = [q for q in pt if q[0] == 'LY']
            seen = set()
            for k, t, a in ys_:
                m = t.mean(0)
                if near_j(m[0], m[2], 10):
                    key = (round(m[0] / 6), round(m[2] / 6))
                    if key not in seen:
                        seen.add(key)
                        spot('yellow_jct', m[0], m[1], m[2])
        Lw = get('L')
        if len(Lw):
            uy, area = up(Lw)
            Lw = Lw[(uy > 0.5) & (area > 0.01)]
            U = shapely.union_all([p.buffer(0.02) for p in polys(Lw)])
            gs = list(getattr(U, 'geoms', [U]))
            mr = []
            for g in gs:
                r = g.minimum_rotated_rectangle
                xy = list(r.exterior.coords)
                e1 = np.subtract(xy[1], xy[0]); e2 = np.subtract(xy[2], xy[1])
                l1, l2 = np.linalg.norm(e1), np.linalg.norm(e2)
                ax = e1 / (l1 + 1e-9) if l1 >= l2 else e2 / (l2 + 1e-9)
                mr.append((g, max(l1, l2), min(l1, l2), ax))
            gt = STRtree([q[0] for q in mr])
            for i, (g, ln, wd, ax) in enumerate(mr):
                if not (3 < ln < 14 and wd < 1.2):
                    continue  # a dash
                cpt = g.centroid
                ok = False
                for j in gt.query(cpt.buffer(40)):
                    if j == i:
                        continue
                    h = mr[j]
                    v = np.array([h[0].centroid.x - cpt.x, h[0].centroid.y - cpt.y])
                    along = abs(v @ ax)
                    lat = abs(v[0] * ax[1] - v[1] * ax[0])
                    if lat < 1.5 and along < 40 and abs(abs(h[3] @ ax) - 1) < 0.02:
                        ok = True
                        break
                if not ok:
                    spot('lone_dash', cpt.x, 0, cpt.y, 'len %.1f' % ln)
        # bridge concrete at ground level in a junction
        B = get('B')
        if len(B):
            seen = set()
            for t in B:
                m = t.mean(0)
                if not near_j(m[0], m[2], 30):
                    continue
                ys = R.ys(m[0], m[2])
                if ys and min(abs(m[1] - yy) for yy in ys) < 2.5:
                    key = (round(m[0] / 8), round(m[2] / 8))
                    if key not in seen:
                        seen.add(key)
                        spot('wall_low', m[0], m[1], m[2])
        return cell, dict(c), spots


def run(cells_only=None, procs=int(os.environ.get('RB_PROCS', 3))):
    import multiprocessing as mp
    match = json.load(open(os.path.join(OUT, 'match.json')))['match']
    ov = os.environ.get('RB_OVERRIDE')
    if ov:
        import glob as _g
        from roadbugs_index import glb_names
        newm = {}
        for f in _g.glob(os.path.join(ov, '*.glb')):
            for mm in glb_names(f)['meshes']:
                pp = mm['name'].split('_')
                newm['ov_' + mm['name']] = dict(cell=pp[1].split('s')[0], kind=pp[0], glb=os.path.relpath(f, ROOT), name=mm['name'])
        cov = set(v['cell'] for v in newm.values())
        match = {k: v for k, v in match.items() if v['cell'] not in cov}
        match.update(newm)
        print('override cells', sorted(cov))
    bycell = collections.defaultdict(list)
    for m in match.values():
        if cells_only and m['cell'] not in cells_only:
            continue
        bycell[m['cell']].append(m)
    counts, spots = {}, collections.defaultdict(list)
    allR = collections.defaultdict(list)
    for m in match.values():
        if m['kind'] == 'R':
            allR[m['cell']].append(m)
    def nb(cell):
        cx, cz = map(int, cell.split('x'))
        return [m for dx in (-1, 0, 1) for dz in (-1, 0, 1) if dx or dz for m in allR.get('%dx%d' % (cx + dx, cz + dz), [])]
    jobs = [(c, ms, nb(c)) for c, ms in sorted(bycell.items())]
    with mp.Pool(procs) as pool:
        for cell, c, sp in pool.imap_unordered(cell_job, jobs):
            counts[cell] = c
            for k, v in sp.items():
                spots[k].extend(v)
            print(cell, c, flush=True)
    tot = collections.Counter()
    for v in counts.values():
        tot.update(v)
    tag = os.environ.get('RB_TAG', 'run')
    json.dump(dict(total=tot, cells=counts), open(os.path.join(OUT, 'counts_%s.json' % tag), 'w'), indent=1)
    json.dump(spots, open(os.path.join(OUT, 'spots_%s.json' % tag), 'w'))
    print('TOTAL', dict(tot))
    return tot, counts, spots


if __name__ == '__main__':
    only = set(sys.argv[1].split(',')) if len(sys.argv) > 1 else None
    run(only)
