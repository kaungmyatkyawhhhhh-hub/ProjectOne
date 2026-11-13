"""Yangon map, build step 9b (14 Nov 2026): lots for the rest of the venues.

Same lots as d11_sites.py (216 square, front 153 from the road's centre line, clear of everything), minus the
ones already used (Config.YangonVenues: dealership, customs, fuel_yangon), plus lots square to the world
axes with the entrance facing -Z (north) for the luxury towers (their plazas and facade tiers are built
square to the axes): along stretches where the road runs within 15 degrees of east-west, the lot's middle
153 studs south of the road.

Run from Games/CityLegends:  python tools/yangon/d13_more_sites.py
"""
import json, math, os

HERE = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(HERE, 'd11_sites.py'), encoding='utf-8').read()
ns = {'__file__': os.path.join(HERE, 'd11_sites.py')}
exec(compile(src[:src.index('cands = []')], 'd11', 'exec'), ns)
lot_ok, R, chain, at, landmarks, optima = ns['lot_ok'], ns['R'], ns['chain'], ns['at'], ns['landmarks'], ns['optima']
CUT, MAP = ns['ns']['CUT'], ns['ns']['MAP']
OFF = 153.0

used = [(30836.8, 957.4), (31025.7, 646.7), (31125.7, 960.7)]
picked = [q for q in json.load(open(os.path.join(MAP, 'ygn_sites_candidates.json')))
          if all(math.hypot(q['x'] - x, q['z'] - z) > 240 for x, z in used)]

axis = []
for name in ('Yangon Loop', 'New Road', 'University Avenue'):
    s = R[name]['s']
    c = chain(s)
    cs = CUT.get(name, set())
    d = 200.0
    while d < c[-1] - 200:
        x, z, tx, tz, h, k = at(s, c, d)
        if k not in cs and abs(tx) > math.cos(math.radians(15)):
            cx, cz = x, z + OFF
            if lot_ok(cx, cz, 0.0, -1.0):
                axis.append({'road': name, 'at': d, 'x': round(cx, 1), 'z': round(cz, 1), 'fx': 0, 'fz': -1, 'y': round(s[k][1] + 0.5, 2),
                             'd_optima': math.hypot(cx - optima['x'], cz - optima['z'])})
        d += 16
axis.sort(key=lambda q: q['d_optima'])
apick = []
for q in axis:
    if all(math.hypot(q['x'] - p['x'], q['z'] - p['z']) > 240 for p in apick):
        apick.append(q)
print('road-facing lots left:', len(picked))
for q in picked:
    lm = min(landmarks, key=lambda p: math.hypot(p['x'] - q['x'], p['z'] - q['z']))
    print('  %-18s at %6.0f side %+d  %5.0f from Optima  near %-8s %4.0f  { x = %.1f, z = %.1f, fx = %.3f, fz = %.3f, y = %.2f }' % (
        q['road'], q['at'], q['side'], q['d_optima'], lm['landmark'], math.hypot(lm['x'] - q['x'], lm['z'] - q['z']), q['x'], q['z'], q['fx'], q['fz'], q['y']))
print('axis lots (entrance -Z):', len(apick))
for q in apick:
    print('  %-18s at %6.0f  %5.0f from Optima  { x = %.1f, z = %.1f, fx = 0, fz = -1, y = %.2f }' % (q['road'], q['at'], q['d_optima'], q['x'], q['z'], q['y']))
json.dump({'road': picked, 'axis': apick}, open(os.path.join(MAP, 'ygn_sites_more.json'), 'w'), indent=0)
