"""Yangon batch 0.5 accuracy pass (14 Nov 2026, owner: "the industrial road is wrong, its 2 lane in real life and in
game its 1 lane", "do everything"): the real big roads become 2+2.

OpenStreetMap (imports/refs/map/osm_b05, see the reference-study note) gives 4 or more lanes (or 2-3 each way on a
divided road) for these roads, which the step-0 plan had made 1+1 streets. They become routes (kind "route",
half 32 like the loop: 2 lanes of 16 each way, pavements, lane lines). Residential streets really are 1+1 and stay.

Writes imports/refs/map/ygn_roads_v4.json (v3 with those roads widened) and checks that no widened road's
carriageway + pavement now overlaps another road it doesn't meet (two roads running side by side).

Run from Games/CityLegends:  python tools/yangon/d18_widen.py
"""
import json, math, os

HERE = os.path.dirname(os.path.abspath(__file__))
MAP = os.path.join(os.path.dirname(os.path.dirname(HERE)), 'imports', 'refs', 'map')
WIDEN = ['Saya San Road', 'Insein Road', 'New University Avenue Road', 'No.1 Industrial Road', 'Kanbe Road',
         'Pyay Road North', 'Pyay Road South', 'Parami Road West', 'Parami Road East', 'Hledan Road',
         'Kabar Aye Pagoda Road South', 'Kabar Aye Pagoda Road North', 'Inya Road West', 'Inya Road', 'Inya Road East',
         'Hanthawaddy Road']
HALF = 32.0
WALK = 10.0

d = json.load(open(os.path.join(MAP, 'ygn_roads_v3.json'), encoding='utf-8'))
R = {r['name']: r for r in d['roads']}
for n in WIDEN:
    r = R[n]
    r['kind'] = 'route'
    r['half'] = HALF
    for s in r['s']:
        s[6] = max(s[6], HALF)
        s[7] = max(s[7], HALF)
d['note'] = (d.get('note', '') + ' | v4 (14 Nov 2026): the real 4+ lane roads widened to 2+2 routes (d18_widen.py).').strip(' |')

# the check: a widened road's samples (away from its own ends' junctions) against every other road's centre line
CUT = {k: set(v) for k, v in d['cut'].items()}


def seg_dist(px, pz, s, cut):
    best = 1e18
    for k in range(len(s) - 1):
        if k in cut or (k + 1) in cut:
            continue
        a, b = s[k], s[k + 1]
        vx, vz = b[0] - a[0], b[2] - a[2]
        L = vx * vx + vz * vz
        t = 0 if L == 0 else max(0, min(1, ((px - a[0]) * vx + (pz - a[2]) * vz) / L))
        best = min(best, math.hypot(px - a[0] - t * vx, pz - a[2] - t * vz))
    return best


problems = []
for n in WIDEN:
    r = R[n]
    s = r['s']
    for o in d['roads']:
        if o['name'] == n:
            continue
        oc = CUT.get(o['name'], set())
        ohalf = max(max(q[6], q[7]) for q in o['s'])
        need = HALF + WALK + ohalf + WALK - 2  # the two roads' pavements may touch, not overlap
        # samples of this road near the other road but NOT at a junction with it (a junction: this road's centre
        # line comes within the other's half)
        mind = min(seg_dist(p[0], p[2], o['s'], oc) for p in s)
        if mind < ohalf + 1:
            continue  # they meet: a junction, the mouth logic handles it
        if mind < need:
            problems.append('%s runs %.0f studs from %s (needs %.0f)' % (n, mind, o['name'], need))
print('widened:', len(WIDEN))
print('side-by-side problems:', len(problems))
for p in problems:
    print('  ' + p)
json.dump(d, open(os.path.join(MAP, 'ygn_roads_v4.json'), 'w', encoding='utf-8'), separators=(',', ':'))
# the Studio modules (YangonData.Roads3_1..3, the names YangonRoads.load reads): the JSON in three pieces
txt = open(os.path.join(MAP, 'ygn_roads_v4.json'), encoding='utf-8').read()
out = os.path.join(os.path.dirname(os.path.dirname(HERE)), 'build', 'yangon_v4')
os.makedirs(out, exist_ok=True)
n = (len(txt) + 2) // 3
for k in range(3):
    NL = chr(10)
    open(os.path.join(out, 'Roads3_%d.luau' % (k + 1)), 'w', encoding='utf-8', newline=NL).write('return [==[' + txt[k * n:(k + 1) * n] + ']==]' + NL)
print('modules in', out)
print('wrote ygn_roads_v4.json')
