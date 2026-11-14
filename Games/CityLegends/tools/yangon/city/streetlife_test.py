"""Checks the street-life data streetlife.py wrote (src/shared/YangonStreetLife*.lua), read back from the Lua files.

  modules   each under 190,000 characters, one [==[ ]==] string each, braces balanced outside the string, the first
            module's `more` list names exactly the other files
  cars      no footprint (kind length x CAR_W, the yaw as written) within LANE_CLEAR of a traffic lane's centre line
            (YangonLanes + YangonLanes2), on a building plot, on a placed detail (8+ studs from gates, bus stops, tea
            shops), or on another car; street cars sit on their street's surface height
  paths     every point and every 2 studs along every segment off all carriageways (game roads, mesh streets, decks, ring)
  spots     off all carriageways
Prints the counts, and the share of the parkable kerb that is parked (every 8 studs checked with the generator's rules).

Run from Games/CityLegends/tools/yangon/city:  python streetlife_test.py
"""
import math, os, re, sys

from shapely.geometry import Point
from shapely.strtree import STRtree

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import streetlife as SL

FAIL = []


def check(cond, msg):
    if not cond:
        FAIL.append(msg)


def strip_strings(t):
    return re.sub(r'\[==\[.*?\]==\]', '""', t, flags=re.S)


def read_modules():
    first = open(os.path.join(SL.SRC_SHARED, 'YangonStreetLife.lua'), encoding='utf-8').read()
    m = re.search(r'more = \{([^}]*)\}', first)
    more = re.findall(r'"([^"]+)"', m.group(1)) if m else []
    files = ['YangonStreetLife'] + more
    on_disk = sorted(f[:-4] for f in os.listdir(SL.SRC_SHARED) if re.match(r'^YangonStreetLife\d*\.lua$', f))
    check(sorted(files) == on_disk, 'module list %s vs files %s' % (files, on_disk))
    lines = []
    for name in files:
        t = open(os.path.join(SL.SRC_SHARED, name + '.lua'), encoding='utf-8').read()
        print('%-22s %7d characters' % (name, len(t)))
        check(len(t) < 190000, '%s is %d characters' % (name, len(t)))
        check(t.count('[==[') == 1 and t.count(']==]') == 1, '%s: string brackets' % name)
        code = strip_strings(t)
        code = re.sub(r'--[^\n]*', '', code)
        check(code.count('{') == code.count('}'), '%s: braces %d / %d' % (name, code.count('{'), code.count('}')))
        check(code.count('(') == code.count(')'), '%s: parentheses' % name)
        check(re.search(r'^\s*return\b', code, flags=re.M) is not None, '%s: no return' % name)
        body = re.search(r'\[==\[\n(.*?)\n\]==\]', t, flags=re.S).group(1)
        lines += body.split('\n')
    return lines


def decode(lines):
    ox, oz = SL.OX, SL.OZ
    cars, spots, paths, schools, worship = [], [], [], [], []
    for ln in lines:
        b = ln.split()
        if not b:
            continue
        if b[0] == 'C':
            check(len(b) == 8, 'bad car line ' + ln)
            cars.append({'x': int(b[1]) / 10 + ox, 'z': int(b[2]) / 10 + oz, 'y': int(b[3]) / 10, 'yaw': math.radians(int(b[4]) / 10),
                         'kind': b[5], 'col': int(b[6]), 'up': int(b[7])})
        elif b[0] == 'S':
            spots.append((int(b[1]) / 10 + ox, int(b[2]) / 10 + oz, int(b[3]) / 10, b[5]))
        elif b[0] == 'K':
            schools.append(b)
        elif b[0] == 'W':
            worship.append(b)
        elif b[0] == 'P':
            n = int(b[2])
            v = [int(q) for q in b[3:]]
            check(len(v) == 3 * n, 'path length %d vs %d' % (len(v), 3 * n))
            x, z, y = v[0], v[1], v[2]
            pts = [(x / 10 + ox, z / 10 + oz, y / 10)]
            for k in range(1, n):
                x, z, y = x + v[3 * k], z + v[3 * k + 1], y + v[3 * k + 2]
                pts.append((x / 10 + ox, z / 10 + oz, y / 10))
            paths.append((b[1], pts))
        else:
            check(False, 'unknown line ' + ln[:40])
    return cars, spots, paths, schools, worship


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    lines = read_modules()
    cars, spots, paths, schools, worship = decode(lines)
    print('loading the world ...')
    W = SL.load_world()
    # ---- cars
    polys = []
    for c in cars:
        fx, fz = -math.sin(c['yaw']), -math.cos(c['yaw'])
        polys.append(SL.car_poly(c['x'], c['z'], fx, fz, SL.LENGTHS[c['kind']]))
    lane_min, plot_bad, det_bad, keep_min, car_bad, y_bad = 1e9, 0, 0, 1e9, 0, 0
    for c, p in zip(cars, polys):
        for j in W['LTREE'].query(p, predicate='dwithin', distance=10):
            lane_min = min(lane_min, W['LANES'][int(j)].distance(p))
        if len(W['PTREE'].query(p.buffer(-0.15), predicate='intersects')):
            plot_bad += 1
        for j in W['DTREE'].query(p, predicate='dwithin', distance=SL.CLEAR8):
            j = int(j)
            d = W['DFOOT'][j].distance(p)
            if W['DKIND'][j] in SL.KEEP8:
                keep_min = min(keep_min, d)
                if d < SL.CLEAR8 - 0.25:
                    det_bad += 1
            elif W['DFOOT'][j].intersects(p.buffer(-0.15)):
                det_bad += 1
        # height: a mesh-street car on that street's surface, a part-road car on its road's sample height
        ys = SL.street_h(W, c['x'], c['z'])
        yg = SL.surface_y(W, c['x'], c['z']) - 0.5 if W['GPAVE'].distance(Point(c['x'], c['z'])) < 12 else None
        if abs(c['y'] - ys) > 0.3 and (yg is None or abs(c['y'] - yg) > 1.0):
            y_bad += 1
    tree = STRtree(polys)
    for i, p in enumerate(polys):
        for j in tree.query(p.buffer(-0.1), predicate='intersects'):
            if int(j) != i:
                car_bad += 1
    car_bad //= 2
    check(lane_min >= SL.LANE_CLEAR - 0.2, 'a car is %.2f from a traffic lane' % lane_min)
    check(plot_bad == 0, '%d cars on a building plot' % plot_bad)
    check(det_bad == 0, '%d cars on / too near a detail' % det_bad)
    check(car_bad == 0, '%d car pairs overlap' % car_bad)
    check(y_bad == 0, '%d cars off their road height' % y_bad)
    nm = sum(1 for c in cars if c['up'] != 0)
    print('cars: %d (streets %d, half up on main roads %d); nearest lane %.2f, nearest gate / bus stop / tea shop %.2f (99 = none within 8); '
          'plots %d, details %d, car overlaps %d' % (len(cars), len(cars) - nm, nm, lane_min, min(keep_min, 99.0), plot_bad, det_bad, car_bad))
    from collections import Counter
    kc = Counter(c['kind'] for c in cars)
    print('  kinds %s, white / silver / grey %.0f%%' % (dict(sorted(kc.items())), 100 * sum(1 for c in cars if c['col'] <= 6) / max(1, len(cars))))
    # ---- paths and spots
    carr = W['CARR']
    bad_pts, n_checked = 0, 0
    for cls, pts in paths:
        for k in range(len(pts) - 1):
            (ax, az, _), (bx, bz, _) = pts[k], pts[k + 1]
            L = math.hypot(bx - ax, bz - az)
            n = max(1, int(L / 2))
            for t in range(n + 1):
                q = Point(ax + (bx - ax) * t / n, az + (bz - az) * t / n)
                n_checked += 1
                if carr.contains(q):
                    bad_pts += 1
    check(bad_pts == 0, '%d path points on a carriageway' % bad_pts)
    # the walking line keeps clear of the cars half up on the pavement (walkers step 0.3+ further out from it)
    near_car = 1e9
    for cls, pts in paths:
        for x, z, _ in pts:
            for j in tree.query(Point(x, z), predicate='dwithin', distance=3):
                near_car = min(near_car, polys[int(j)].distance(Point(x, z)))
    check(near_car >= 0.9, 'a walking line passes %.2f from a parked car' % near_car)
    print('walking lines: nearest parked car %.2f studs' % near_car)
    bad_spots = sum(1 for x, z, y, k in spots if carr.contains(Point(x, z)))
    check(bad_spots == 0, '%d standing spots on a carriageway' % bad_spots)
    plen = sum(sum(math.hypot(p[i + 1][0] - p[i][0], p[i + 1][1] - p[i][1]) for i in range(len(p) - 1)) for _, p in paths)
    print('paths: %d (main %d, street %d), %d points, %.0f studs; %d points along them checked, %d on a carriageway' % (
        len(paths), sum(1 for c, _ in paths if c == 'm'), sum(1 for c, _ in paths if c == 's'), sum(len(p) for _, p in paths), plen,
        n_checked, bad_pts))
    print('spots: %d (bus %d, tea %d, shop %d), %d on a carriageway; schools %d, worship %d' % (
        len(spots), sum(1 for s in spots if s[3] == 'b'), sum(1 for s in spots if s[3] == 't'), sum(1 for s in spots if s[3] == 's'),
        bad_spots, len(schools), len(worship)))
    # ---- how full the parkable kerb is (mesh streets and part streets)
    elig = 0.0
    for rd in W['RD']:
        if rd['src'] != 'street' or rd['st'].get('bridge'):
            continue
        line = SL.Line(rd['pts'])
        sides = (1, -1) if rd['kind'] != 'lane' else (1,)
        off = rd['half'] - SL.KERB_GAP - SL.CAR_W / 2
        for side in sides:
            s = 8.0
            while s < line.L - 8:
                x, z, dx, dz, i, ex = line.at(s)
                rx, rz = -dz * side, dx * side
                p = SL.car_poly(x + rx * off, z + rz * off, dx, dz, 13.5)
                if SL.car_ok(W, p, rd, {})[0]:
                    elig += 8.0
                s += 8.0
    nst = sum(1 for c in cars if c['up'] == 0)
    print('parkable mesh-street kerb %.0f studs; street cars x 17 = %.0f%% of it' % (elig, 100 * nst * SL.PITCH / max(elig, 1)))
    print()
    if FAIL:
        print('FAILED:')
        for f in FAIL:
            print('  ' + f)
        sys.exit(1)
    print('all checks passed')


if __name__ == '__main__':
    main()
