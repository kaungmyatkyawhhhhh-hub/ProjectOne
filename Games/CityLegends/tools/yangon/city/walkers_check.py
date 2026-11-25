"""Walker check (26 Nov 2026, owner: "people are walking on the road near myanmar plaza"): every pavement walker path
(P lines of src/shared/YangonStreetLife*.lua, YangonStreetLifeMall.lua) against the road collision boxes that are IN THE
PLACE (Workspace.Yangon1to1.Roads.Collide, RoadBox R = carriageway, D = deck carriageway, M = median), dumped from Studio
to build/city_1to1/walkers_26nov/roadboxes_place.txt (15 chars a box, see decode()).

A walker walks its path line shifted sideways by lat (YangonStreetLife.lua: 0.3..2.4 studs away from the kerb on "m"
paths, -0.4..0.5 on the others), so both ends of that band are tested, every 2 studs along each segment. A sample is on
the road when it is inside an R / D / M box's footprint and within 4 studs of its top (a walker under a deck is not on it).
No walker path is meant to cross a road (they turn back at junction mouths), so every hit counts.

    python walkers_check.py [boxes.txt] [modules dir]        -> per-district counts; spots in walkers_26nov/spots.json
"""
import glob, json, math, os, re, sys

import numpy as np
from shapely import points as spoints
from shapely.geometry import Polygon
from shapely.strtree import STRtree

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..', '..'))
OUT = os.path.join(ROOT, 'build', 'city_1to1', 'walkers_26nov')
A = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_'
# district boxes (geo.PILOT_LL in world studs, rounded; first match wins)
DISTRICTS = {
    'P1': (27762, 25357, 36074, 33316), 'P2': (27762, 16072, 37992, 25357), 'P3': (30000, 40943, 42148, 48405),
    'P4': (22967, 17398, 27762, 33316), 'P5': (16574, 17067, 22967, 27347), 'P6': (22967, 33316, 30000, 44591),
    'P7': (30000, 33316, 36074, 40943), 'P8': (36074, 32653, 45984, 40943), 'P9': (37992, 15409, 45984, 25357),
    'P10': (45984, 15409, 55254, 25357), 'P11': (36074, 25357, 45984, 32653), 'P12': (45984, 25357, 55254, 35306),
}
MYANMAR_PLAZA = (34845, 27534)   # Myanmar Centre (MenuShots' subject point)


def district(x, z):
    for k, (x0, z0, x1, z1) in DISTRICTS.items():
        if x0 <= x < x1 and z0 <= z < z1:
            return k
    return 'out'


def num(s):
    v = 0
    for ch in s:
        v = v * 64 + A.index(ch)
    return v


def decode(path):
    """kind, footprint polygon, top y for each box (kind + x*2 (3) + z*2 (3) + (top+100)*10 (2) + sx*4 (2) + sz*4 (2) + yaw*20 (2))"""
    s = open(path, encoding='utf-8').read().strip()
    out = []
    for i in range(0, len(s), 15):
        r = s[i:i + 15]
        x, z = num(r[1:4]) / 2, num(r[4:7]) / 2
        top = num(r[7:9]) / 10 - 100
        sx, sz = num(r[9:11]) / 4, num(r[11:13]) / 4
        a = math.radians(num(r[13:15]) / 20)
        ux, uz = math.cos(a) * sx / 2, math.sin(a) * sx / 2
        vx, vz = -math.sin(a) * sz / 2, math.cos(a) * sz / 2
        poly = Polygon([(x + ux + vx, z + uz + vz), (x - ux + vx, z - uz + vz), (x - ux - vx, z - uz - vz), (x + ux - vx, z + uz - vz)])
        out.append((r[0], poly, top))
    return out


def load_paths(mod_dir):
    """[(name, wide, [(x, y, z) ...])] from every StreetLife module (streetlife_1to1.py's P line format)"""
    paths = []
    first = open(os.path.join(mod_dir, 'YangonStreetLife.lua'), encoding='utf-8').read()
    ox, oz = (float(v) for v in re.search(r'origin = \{ (-?\d+), (-?\d+) \}', first).groups())
    files = sorted(glob.glob(os.path.join(mod_dir, 'YangonStreetLife*.lua')))
    for f in files:
        for ln in open(f, encoding='utf-8'):
            b = ln.split()
            if not b or b[0] != 'P':
                continue
            n, x, z, y = int(b[2]), int(b[3]), int(b[4]), int(b[5])
            pts = [(x / 10 + ox, y / 10, z / 10 + oz)]
            for k in range(1, n):
                j = 3 + 3 * k
                x += int(b[j]); z += int(b[j + 1]); y += int(b[j + 2])
                pts.append((x / 10 + ox, y / 10, z / 10 + oz))
            paths.append((os.path.basename(f), b[1] == 'm', pts))
    return paths


def samples(pts, wide):
    """(segment index, x, y, z) every 2 studs along both edges of the walker band"""
    lats = (0.3, 2.4) if wide else (-0.4, 0.5)
    out = []
    for k in range(len(pts) - 1):
        (ax, ay, az), (bx, by, bz) = pts[k], pts[k + 1]
        dx, dz = bx - ax, bz - az
        L = math.hypot(dx, dz)
        if L < 0.01:
            continue
        nx, nz = -dz / L, dx / L   # YangonStreetLife.lua target(): away from the kerb
        m = max(1, int(L / 2))
        for i in range(m + 1):
            t = i / m
            for lat in lats:
                out.append((k, ax + dx * t + nx * lat, ay + (by - ay) * t, az + dz * t + nz * lat))
    return out


class Clipper:
    """Cuts walker runs to the place's surfaces: a point must lie on a P (pavement) box and its walker band must touch
    no R / D / M box (within 4 studs of height); each kept point takes its pavement box's top as its height."""

    def __init__(self, boxes):
        self.road = [(g, t) for k, g, t in boxes if k in 'RDM']
        self.pave = [(g, t) for k, g, t in boxes if k == 'P']
        self.rtree = STRtree([g for g, _ in self.road])
        self.ptree = STRtree([g for g, _ in self.pave])
        self.rtop = np.array([t for _, t in self.road])
        self.ptop = np.array([t for _, t in self.pave])

    def pave_y(self, x, y, z):
        """the top of the pavement box under (x, z) nearest to y (within 8), or None"""
        hit = self.ptree.query(spoints([(x, z)]), predicate='within')[1]
        if len(hit) == 0:
            return None
        t = self.ptop[hit]
        best = t[np.argmin(np.abs(t - y))]
        return float(best) if abs(best - y) < 8 else None

    def clip(self, run, wide=True, minlen=4):
        """run: [(x, y, z)] -> list of sub-runs with every point on a pavement and no segment band on a carriageway"""
        pts = []
        for x, y, z in run:
            py = self.pave_y(x, y, z)
            pts.append((x, py, z) if py is not None else None)
        bad = set()
        ss = []
        for k in range(len(pts) - 1):
            if pts[k] is None or pts[k + 1] is None:
                bad.add(k)
        good = [p if p is not None else (0, 0, 0) for p in pts]
        ss = samples(good, wide)
        ss = [s for s in ss if s[0] not in bad]
        if ss:
            arr = np.array([(x, z) for _, x, _, z in ss])
            ys = np.array([y for _, _, y, _ in ss])
            pi, bi = self.rtree.query(spoints(arr), predicate='within')
            ok = np.abs(ys[pi] - self.rtop[bi]) < 4
            bad.update(ss[p][0] for p in pi[ok])
        out, cur = [], []
        for k in range(len(pts)):
            if pts[k] is None:
                if len(cur) >= minlen:
                    out.append(cur)
                cur = []
                continue
            cur.append(pts[k])
            if k in bad:  # segment k -> k + 1 is not walkable: end the run at k
                if len(cur) >= minlen:
                    out.append(cur)
                cur = []
        if len(cur) >= minlen:
            out.append(cur)
        return out


def check(boxes, paths):
    road = [(k, g, top) for k, g, top in boxes if k in 'RDM']
    tree = STRtree([g for _, g, _ in road])
    tops = np.array([t for _, _, t in road])
    kinds = np.array([k for k, _, _ in road])
    per = {}
    spots = []
    for name, wide, pts in paths:
        ss = samples(pts, wide)
        if not ss:
            continue
        arr = np.array([(x, z) for _, x, _, z in ss])
        ys = np.array([y for _, _, y, _ in ss])
        pi, bi = tree.query(spoints(arr), predicate='within')
        ok = np.abs(ys[pi] - tops[bi]) < 4
        badseg = {}
        for p, b in zip(pi[ok], bi[ok]):
            badseg.setdefault(ss[p][0], kinds[b])
        d = district(*pts[0][::2]) if pts else 'out'
        c = per.setdefault(d, {'paths': 0, 'points': 0, 'segments': 0, 'bad_points': 0, 'bad_segments': 0, 'bad_paths': 0, 'median_segments': 0})
        c['paths'] += 1
        c['points'] += len(pts)
        c['segments'] += len(pts) - 1
        badpts = set()
        for k, kind in badseg.items():
            if kind == 'M':
                c['median_segments'] += 1
            c['bad_segments'] += 1
            badpts.update((k, k + 1))
        c['bad_points'] += len(badpts)
        c['bad_paths'] += 1 if badseg else 0
        for k in sorted(badseg):
            x, y, z = pts[k]
            spots.append({'d': d, 'mod': name, 'x': round(x, 1), 'z': round(z, 1), 'y': round(y, 1), 'kind': str(badseg[k]),
                          'mp_dist': round(math.hypot(x - MYANMAR_PLAZA[0], z - MYANMAR_PLAZA[1]))})
    return per, spots


def report(per, spots, label):
    tot = {}
    print('%s: district paths points segments | bad points / segments / paths (median segs)' % label)
    for d in sorted(per, key=lambda k: (len(k), k)):
        c = per[d]
        for k, v in c.items():
            tot[k] = tot.get(k, 0) + v
        print('  %-4s %5d %7d %7d | %6d %6d %5d (%d)' % (d, c['paths'], c['points'], c['segments'], c['bad_points'], c['bad_segments'], c['bad_paths'], c['median_segments']))
    print('  all  %5d %7d %7d | %6d %6d %5d (%d)' % (tot.get('paths', 0), tot.get('points', 0), tot.get('segments', 0), tot.get('bad_points', 0),
                                                 tot.get('bad_segments', 0), tot.get('bad_paths', 0), tot.get('median_segments', 0)))
    near = [s for s in spots if s['mp_dist'] < 600]
    print('  within 600 studs of Myanmar Plaza: %d bad segments' % len(near))
    return tot


if __name__ == '__main__':
    bpath = sys.argv[1] if len(sys.argv) > 1 else os.path.join(OUT, 'roadboxes_place.txt')
    mdir = sys.argv[2] if len(sys.argv) > 2 else os.path.join(ROOT, 'src', 'shared')
    boxes = decode(bpath)
    print('%d boxes: %s' % (len(boxes), {k: sum(1 for b in boxes if b[0] == k) for k in 'RDM'}))
    per, spots = check(boxes, load_paths(mdir))
    report(per, spots, mdir)
    os.makedirs(OUT, exist_ok=True)
    tag = os.environ.get('WC_TAG', 'check')
    json.dump({'per': per, 'spots': spots}, open(os.path.join(OUT, 'spots_%s.json' % tag), 'w'), indent=0)
