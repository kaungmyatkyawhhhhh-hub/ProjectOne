"""Yangon map, build step 5 (13 Nov 2026): the 30 streets, ready to build.

Reads imports/refs/map/ygn_roads_v2.json (step 4) and writes imports/refs/map/ygn_roads_v3.json:

  * A street that CROSSES a bigger road is split into pieces, each ending inside the road it crosses
    (Y.findMouths then cuts each piece's slab exactly on that road's edge, and the corners are rounded).
    Only Inya Road does: it crosses the Yangon Loop and University Avenue. The pieces are
    "Inya Road West" (map edge to the loop), "Inya Road" (loop to University Avenue) and
    "Inya Road East" (University Avenue to its end on the loop), ranks 15, 15.1, 15.2.
    Streets that end on a piece now end on whichever piece they touch (the tools look by position).
  * Every street end that lands on no road is a map-edge end: `edgeStart` / `edgeEnd` = true. Step 5
    puts a barrier across it (the far-city backdrop is step 8).

A crossing is found where a street's middle samples lie inside another road's carriageway, away from
the street's own ends; T-junctions (a street ending on another) are not crossings.
Run from Games/CityLegends:  python tools/yangon/d8_streets.py
"""
import json, math, os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
MAP = os.path.join(ROOT, 'imports', 'refs', 'map')
C = (29072.0, 1172.8)  # the roundabout's centre
R_OUT = 108.0

data = json.load(open(os.path.join(MAP, 'ygn_roads_v2.json'), encoding='utf-8'))
cut = {k: set(v) for k, v in data['cut'].items()}


def segdist(p, a, b):
    vx, vz = b[0] - a[0], b[2] - a[2]
    L = vx * vx + vz * vz
    t = 0 if L == 0 else max(0, min(1, ((p[0] - a[0]) * vx + (p[2] - a[2]) * vz) / L))
    return math.hypot(p[0] - a[0] - t * vx, p[2] - a[2] - t * vz), t


def dist_road(o, p):
    """distance from p to road o's built centre line (cut stretches left out) and the sample it is at"""
    best, at = 1e9, None
    s = o['s']
    cs = cut.get(o['name'], set())
    for k in range(len(s) - 1):
        if k in cs or k + 1 in cs:
            continue
        d, t = segdist(p, s[k], s[k + 1])
        if d < best:
            best, at = d, k + t
    return best, at


def half_at(o, at):
    s = o['s'][min(int(at), len(o['s']) - 1)]
    return max(s[6], s[7])


def runs_inside(r, o):
    """runs of r's sample numbers that lie inside road o's carriageway"""
    runs, cur = [], None
    for i, p in enumerate(r['s']):
        d, at = dist_road(o, p)
        inside = at is not None and d < half_at(o, at) - 1
        if inside:
            if cur is None:
                cur = [i, i]
            else:
                cur[1] = i
        elif cur is not None:
            runs.append(cur)
            cur = None
    if cur is not None:
        runs.append(cur)
    return runs


out = []
report = []
for r in data['roads']:
    if r.get('kind') != 'street':
        out.append(r)
        continue
    n = len(r['s'])
    # real crossings: a run inside a BIGGER road that touches neither end
    splits = []
    for o in data['roads']:
        if o is r or o['rank'] >= r['rank']:
            continue
        for a, b in runs_inside(r, o):
            if a > 0 and b < n - 1:
                splits.append((a, b, o['name']))
    splits.sort()
    if not splits:
        out.append(r)
        continue
    # pieces: [start .. first inside sample + its middle], [middle .. next], ... each piece ends on the
    # middle sample of the crossing run (well inside the crossed road), the next starts there
    names = [r['name'] + ' West'] + ([r['name']] if len(splits) > 1 else []) + [r['name'] + ' East']
    if len(splits) > 2:
        raise SystemExit('more than two crossings on ' + r['name'])
    cuts = [(a + b) // 2 for a, b, _ in splits]
    bounds = [0] + cuts + [n - 1]
    for k in range(len(bounds) - 1):
        piece = dict(r)
        piece['name'] = names[k]
        piece['rank'] = round(r['rank'] + 0.1 * k, 2)
        piece['s'] = [list(p) for p in r['s'][bounds[k]:bounds[k + 1] + 1]]
        out.append(piece)
        report.append('%s: samples %d..%d (%d), rank %s' % (piece['name'], bounds[k], bounds[k + 1], len(piece['s']), piece['rank']))
    report.append('%s crosses %s' % (r['name'], ', '.join('%s at %d..%d' % (nm, a, b) for a, b, nm in splits)))

# map-edge ends: a street end on no road and not in the roundabout
edge = []
for r in out:
    if r.get('kind') != 'street':
        continue
    for key, p in (('edgeStart', r['s'][0]), ('edgeEnd', r['s'][-1])):
        if math.hypot(p[0] - C[0], p[2] - C[1]) < R_OUT:
            continue
        on = False
        for o in out:
            if o is r:
                continue
            d, at = dist_road(o, p)
            if at is not None and d < half_at(o, at):
                on = True
                break
        if not on:
            r[key] = True
            edge.append('%s %s at (%.0f, %.0f)' % (r['name'], 'start' if key == 'edgeStart' else 'end', p[0], p[2]))

ranks = [r['rank'] for r in out]
assert len(ranks) == len(set(ranks)), 'two roads share a rank'
data['roads'] = out
data['note'] = 'ygn_roads_v2.json + Inya Road split at its crossings, map-edge ends marked (tools/yangon/d8_streets.py, 13 Nov 2026)'
json.dump(data, open(os.path.join(MAP, 'ygn_roads_v3.json'), 'w', encoding='utf-8'), separators=(',', ':'))
print('\n'.join(report))
print('%d map-edge ends:' % len(edge))
print('\n'.join('  ' + e for e in edge))
print('%d roads written to ygn_roads_v3.json' % len(out))
