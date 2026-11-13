"""Yangon step 9b (14 Nov 2026): a lot for Legends Rewards, whose car courts make it about 300 wide (across the front)
by 216 deep. Same rules as d11 (front 153 from the road's centre line, clear of roads, decks, water, the roundabout and
the landmarks), the width given, and clear of the lots already chosen (SAT on their rectangles + 8 margin).

Run from Games/CityLegends:  python tools/yangon/d14_wide_lot.py [width]
"""
import json, math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(HERE, 'd11_sites.py'), encoding='utf-8').read()
ns = {'__file__': os.path.join(HERE, 'd11_sites.py')}
exec(compile(src[:src.index('cands = []')], 'd11', 'exec'), ns)
d10 = ns['ns']
road_clear, near_water, R, chain, at = d10['road_clear'], d10['near_water'], d10['R'], d10['chain'], d10['at']
X0, X1, Z0, Z1, RING, CUT = d10['X0'], d10['X1'], d10['Z0'], d10['Z1'], d10['RING'], d10['CUT']
landmarks, optima = ns['landmarks'], ns['optima']
LOT, OFF = 216.0, 153.0
WIDTH = float(sys.argv[1]) if len(sys.argv) > 1 else 304.0

USED = {  # (x, z, fx, fz, width, depth)
    'dealership': (30836.8, 957.4, -0.560, -0.829, 216, 216), 'customs': (31025.7, 646.7, -0.990, -0.144, 216, 216),
    'fuel_yangon': (31125.7, 960.7, 0.326, 0.945, 216, 216),
    'tower_aurum': (30911.0, 1306.4, 0, -1, 216, 216), 'tower_skyline': (30655.1, 1303.2, 0, -1, 216, 216), 'tower_crown': (29867.2, 1398.6, 0, -1, 216, 216),
    'hotel': (29745.3, 1089.0, 0, 1, 216, 216), 'gems': (30742.3, 223.9, 0.969, -0.249, 216, 216), 'bank': (31074.1, 394.2, -0.991, -0.136, 216, 216),
    'realty': (30465.2, 921.7, 0.560, 0.829, 80, 80), 'dropoff': (32358.8, -1833.6, 0.992, 0.127, 216, 216),
}


def rect(x, z, fx, fz, w, d, grow=8):
    ax, az = -fz, fx
    hw, hd = w / 2 + grow, d / 2 + grow
    return [(x + ax * u * hw + fx * v * hd, z + az * u * hw + fz * v * hd) for u, v in ((-1, -1), (1, -1), (1, 1), (-1, 1))]


def overlap(p, q):
    for poly in (p, q):
        for i in range(4):
            a, b = poly[i], poly[(i + 1) % 4]
            nx, nz = -(b[1] - a[1]), b[0] - a[0]
            pa = [nx * x + nz * z for x, z in p]
            pb = [nx * x + nz * z for x, z in q]
            if max(pa) < min(pb) or max(pb) < min(pa):
                return False
    return True


def ok(cx, cz, fx, fz):
    ax, az = -fz, fx
    for u in range(-6, 7):
        for v in range(-4, 5):
            x = cx + ax * u * (WIDTH / 12) - fx * v * ((LOT - 4) / 8)
            z = cz + az * u * (WIDTH / 12) - fz * v * ((LOT - 4) / 8)
            if not (X0 < x < X1 and Z0 < z < Z1) or math.hypot(x - RING[0], z - RING[1]) < RING[2]:
                return False
            if not road_clear(x, z) or near_water(x, z, 8):
                return False
    for p in landmarks:
        if math.hypot(p['x'] - cx, p['z'] - cz) < WIDTH / 2 + max(p['w'], p['d']) / 2 + 6:
            return False
    me = rect(cx, cz, fx, fz, WIDTH, LOT, 0)
    return all(not overlap(me, rect(*u)) for u in USED.values())


out = []
for name in ('Yangon Loop', 'New Road', 'University Avenue'):
    s = R[name]['s']
    c = chain(s)
    cs = CUT.get(name, set())
    d = 200.0
    while d < c[-1] - 200:
        x, z, tx, tz, h, k = at(s, c, d)
        if k not in cs:
            # a straight stretch: the direction 150 either side within 6 degrees
            a, b = at(s, c, d - 150), at(s, c, d + 150)
            straight = (a[2] * b[2] + a[3] * b[3]) / (math.hypot(a[2], a[3]) * math.hypot(b[2], b[3])) > math.cos(math.radians(6))
            for side in (1, -1):
                nx, nz = -tz * side, tx * side
                cx, cz = x + nx * OFF, z + nz * OFF
                if straight and ok(cx, cz, -nx, -nz):
                    out.append((math.hypot(cx - optima['x'], cz - optima['z']), name, d, side, round(cx, 1), round(cz, 1), round(-nx, 3), round(-nz, 3), round(s[k][1] + 0.5, 2)))
        d += 16
out.sort()
seen = []
for q in out:
    if all(math.hypot(q[4] - p[4], q[5] - p[5]) > 200 for p in seen):
        seen.append(q)
for q in seen[:10]:
    print('%5.0f from Optima  %-18s at %6.0f side %+d  { x = %.1f, z = %.1f, fx = %.3f, fz = %.3f, y = %.2f, w = %d }' % (q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7], q[8], WIDTH))
