"""Yangon map, build step 9 (13 Nov 2026): venue lots.

The game's venues (WestLayout / Config.RivieraVenues) stand on a 216-stud square lot centred 150 studs
from its road's centre line, facing the road. This searches the main roads for such lots clear of every
other road (its half + pavement + 3), the decks, the roundabout, the lake and the landmarks, and prints
them by distance from Optima Werkz (the start), with the site line for Config.

Run from Games/CityLegends:  python tools/yangon/d11_sites.py [n]
"""
import json, math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(HERE, 'd10_plots.py'), encoding='utf-8').read()
ns = {'__file__': os.path.join(HERE, 'd10_plots.py')}
exec(compile(src[:src.index('# the landmarks first')], 'd10', 'exec'), ns)
road_clear, near_water, R, roads, chain, at = ns['road_clear'], ns['near_water'], ns['R'], ns['roads'], ns['chain'], ns['at']
X0, X1, Z0, Z1, RING = ns['X0'], ns['X1'], ns['Z0'], ns['Z1'], ns['RING']

LOT, OFF = 216.0, 153.0  # (150 put the front row inside the road's clearance: 3 more)
plots = json.load(open(os.path.join(ns['MAP'], 'ygn_plots.json'), encoding='utf-8'))['plots']
landmarks = [p for p in plots if p.get('landmark')]
optima = [p for p in landmarks if p['landmark'] == 'optima'][0]

# the lot's own road counts only past its front edge: tested points stay 2 behind the front
def lot_ok(cx, cz, fx, fz):
    ax, az = -fz, fx
    for u in range(-4, 5):
        for v in range(-4, 5):
            # v = -4 is the front row (towards the road); keep it 2 studs inside the lot
            x = cx + ax * u * (LOT / 8) - fx * v * ((LOT - 4) / 8)
            z = cz + az * u * (LOT / 8) - fz * v * ((LOT - 4) / 8)
            if not (X0 < x < X1 and Z0 < z < Z1):
                return False
            if math.hypot(x - RING[0], z - RING[1]) < RING[2]:
                return False
            if not road_clear(x, z) or near_water(x, z, 8):
                return False
    for p in landmarks:
        if math.hypot(p['x'] - cx, p['z'] - cz) < LOT / 2 + max(p['w'], p['d']) / 2 + 6:
            return False
    return True


cands = []
for name in ('Yangon Loop', 'New Road', 'University Avenue'):
    r = R[name]
    s = r['s']
    c = chain(s)
    cs = ns['CUT'].get(name, set())
    d = 200.0
    while d < c[-1] - 200:
        x, z, tx, tz, h, k = at(s, c, d)
        if k in cs:
            d += 32
            continue
        for side in (1, -1):
            nx, nz = -tz * side, tx * side  # away from the road
            cx, cz = x + nx * OFF, z + nz * OFF
            # the entrance faces the road: (fx, fz) = towards the road
            if lot_ok(cx, cz, -nx, -nz):
                y = s[k][1]
                cands.append({'road': name, 'at': d, 'side': side, 'x': round(cx, 1), 'z': round(cz, 1), 'fx': round(-nx, 3), 'fz': round(-nz, 3), 'y': round(y + 0.5, 2),
                              'd_optima': math.hypot(cx - optima['x'], cz - optima['z'])})
        d += 32

# one per stretch: drop candidates within 180 of a better (nearer Optima) one
cands.sort(key=lambda q: q['d_optima'])
picked = []
for q in cands:
    if all(math.hypot(q['x'] - p['x'], q['z'] - p['z']) > 240 for p in picked):
        picked.append(q)
n = int(sys.argv[1]) if len(sys.argv) > 1 else 12
print('%d lot positions pass, %d distinct' % (len(cands), len(picked)))
for q in picked[:n]:
    print('%-18s at %6.0f side %+d  %.0f from Optima  { x = %.1f, z = %.1f, fx = %.3f, fz = %.3f, y = %.2f }' % (q['road'], q['at'], q['side'], q['d_optima'], q['x'], q['z'], q['fx'], q['fz'], q['y']))
json.dump(picked, open(os.path.join(ns['MAP'], 'ygn_sites_candidates.json'), 'w'), indent=0)
