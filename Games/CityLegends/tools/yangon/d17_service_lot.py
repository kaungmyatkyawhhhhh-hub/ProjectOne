"""Yangon step 11 (14 Nov 2026): a lot for Legends Service (the repair shop, 152 x 150 on a 216 lot), clear of the
venues, the fuel station, the Racing Hub and every house lot (with the pads' margins). Uses d15_world's helpers.

Run from Games/CityLegends:  python tools/yangon/d17_service_lot.py
"""
import math, os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.argv = [sys.argv[0]]
ns = {'__file__': os.path.join(HERE, 'd15_world.py'), '__name__': 'd15'}
exec(compile(open(os.path.join(HERE, 'd15_world.py'), encoding='utf-8').read(), 'd15', 'exec'), ns)
world = open(os.path.join(ns['ROOT'], 'src', 'shared', 'YangonWorld.lua'), encoding='utf-8').read()
others = []
for m in re.finditer(r'x = ([-\d.]+), y = [-\d.]+, z = ([-\d.]+), fx = ([-\d.]+), fz = ([-\d.]+), w = (\d+), d = (\d+)', world):
    x, z, fx, fz, w, d = map(float, m.groups())
    others.append(ns['rect'](x, z, fx, fz, w + 16, d + 10))
m = re.search(r'site = \{ x = ([-\d.]+), z = ([-\d.]+), fx = ([-\d.]+), fz = ([-\d.]+)', world)
others.append(ns['rect'](float(m.group(1)), float(m.group(2)), float(m.group(3)), float(m.group(4)), 232, 226))
R, CUT, OPT, WALK, chain, lot_ok = ns['R'], ns['CUT'], ns['OPTIMA'], ns['WALK'], ns['chain'], ns['lot_ok']
best = []
for name in ('Yangon Loop', 'New Road', 'University Avenue'):
    s = R[name]['s']
    c = chain(s)
    cs = CUT.get(name, set())
    for i in range(0, len(s), 3):
        if c[i] < 200 or c[i] > c[-1] - 200 or i in cs:
            continue
        x, y, z, tx, tz = s[i][0], s[i][1], s[i][2], s[i][3], s[i][4]
        L = math.hypot(tx, tz)
        tx, tz = tx / L, tz / L
        for side in (1, -1):
            nx, nz = -tz * side, tx * side
            hs = s[i][6] if side < 0 else s[i][7]
            off = hs + WALK + 3 + 108
            cx, cz = x + nx * off, z + nz * off
            dd = math.hypot(cx - OPT['x'], cz - OPT['z'])
            if dd > 1500:
                continue
            if lot_ok(cx, cz, -nx, -nz, 216, 216, others):
                best.append((round(dd), name, i, side, round(cx, 1), round(cz, 1), round(-nx, 3), round(-nz, 3), round(y + 0.5, 2)))
best.sort()
seen = []
for b in best:
    if all(math.hypot(b[4] - q[4], b[5] - q[5]) > 200 for q in seen):
        seen.append(b)
for b in seen[:6]:
    print(b)
