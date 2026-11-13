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

# A road that ENDS on another must be the smaller (higher rank) of the two, or the builder sees the through
# road crossing a bigger road's end. Two street pairs had it the other way round: Insein Road (4) ends on
# Hledan Road (12), Adipati Road (24) ends on Convocation Road (28). The through roads move below them.
RANK_FIX = {'Hledan Road': 3.5, 'Convocation Road': 23.5}
for r in data['roads']:
    if r['name'] in RANK_FIX:
        r['rank'] = RANK_FIX[r['name']]

# U Tun Nyein Street and Lane 1 both START at one point (the street plan cut each back to its last
# junction and the two met there): one street, Lane 1 reversed then U Tun Nyein, bend radius 40.


STEP = 6.4


def merge_corner(first, second, radius):
    """Two streets that meet end to end at one point (both START there) are one street with a bend:
    `first` reversed, then `second`, the corner rounded with a circular arc of `radius` (streets bend
    at 40 studs or wider). Returns the merged sample list."""
    A = [list(p) for p in reversed(first)]
    for p in A:
        p[3], p[4] = -p[3], -p[4]
    B = [list(p) for p in second]
    P = A[-1]
    da = (A[-1][0] - A[-2][0], A[-1][2] - A[-2][2])
    db = (B[1][0] - B[0][0], B[1][2] - B[0][2])
    la, lb = math.hypot(*da), math.hypot(*db)
    ua, ub = (da[0] / la, da[1] / la), (db[0] / lb, db[1] / lb)
    turn = math.acos(max(-1, min(1, ua[0] * ub[0] + ua[1] * ub[1])))
    T = radius * math.tan(turn / 2)

    def cut_back(pts, dist):  # drop the samples within dist of the corner (the corner is pts[-1])
        out = [q for q in pts if math.hypot(q[0] - P[0], q[2] - P[2]) > dist + 1e-6]
        return out
    A2 = cut_back(A, T)
    B2 = list(reversed(cut_back(list(reversed(B)), T)))
    # arc from the tangent point on A's line to the one on B's line
    ta = (P[0] - ua[0] * T, P[2] - ua[1] * T)
    tb = (P[0] + ub[0] * T, P[2] + ub[1] * T)
    cross = ua[0] * ub[1] - ua[1] * ub[0]
    side = 1 if cross > 0 else -1  # centre to the left (+) or right of the way along A
    nx, nz = -ua[1] * side, ua[0] * side
    cx, cz = ta[0] + nx * radius, ta[1] + nz * radius
    a0 = math.atan2(ta[1] - cz, ta[0] - cx)
    a1 = math.atan2(tb[1] - cz, tb[0] - cx)
    sweep = (a1 - a0 + math.pi) % (2 * math.pi) - math.pi
    k = max(2, int(math.ceil(abs(sweep) * radius / STEP)))
    y0, y1 = A2[-1][1], B2[0][1]
    arc = []
    for i in range(0, k + 1):
        u = i / k
        ang = a0 + sweep * u
        x, z = cx + radius * math.cos(ang), cz + radius * math.sin(ang)
        tx, tz = -math.sin(ang) * (1 if sweep > 0 else -1), math.cos(ang) * (1 if sweep > 0 else -1)
        arc.append([round(x, 2), round(y0 + (y1 - y0) * u, 2), round(z, 2), round(tx, 4), round(tz, 4), 0, A[-1][6], A[-1][7]])
    return A2 + arc + B2, math.degrees(turn), T


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


RN = {r['name']: r for r in data['roads']}
merged, turn, T = merge_corner(RN['Lane 1']['s'], RN['U Tun Nyein Street']['s'], 40.0)
RN['U Tun Nyein Street']['s'] = merged
data['roads'] = [r for r in data['roads'] if r['name'] != 'Lane 1']
print('U Tun Nyein Street + Lane 1: one street, %d samples, a %.0f-degree bend rounded at radius 40 (%.0f studs off each)' % (len(merged), turn, T))

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
        # (o's own end inside r is a T of o onto r, not a crossing)
        o_ends_here = any(dist_road(r, e)[0] < r['half'] + 2 for e in (o['s'][0], o['s'][-1]))
        for a, b in runs_inside(r, o):
            if a > 0 and b < n - 1 and not o_ends_here:
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

# the rule above, checked for every road end that lands on another road
bad = []
for r in out:
    for key, p in (('start', r['s'][0]), ('end', r['s'][-1])):
        if r.get('edgeStart' if key == 'start' else 'edgeEnd') or r.get('startsOnEnd' if key == 'start' else 'endsOnEnd'):
            continue
        under = []
        for o in out:
            if o is r or o.get('kind') == 'deck':
                continue
            d, at = dist_road(o, p)
            if at is not None and d < half_at(o, at) - 1:
                under.append(o)
        # (the end's mouth goes to the biggest road it lies on: that one must be bigger than this road;
        # a crossing's pieces end on each other inside the crossed road, which is fine)
        if under:
            big = min(under, key=lambda o: o['rank'])
            if big['rank'] > r['rank']:
                bad.append('%s %s lies on %s, a smaller road (%s > %s)' % (r['name'], key, big['name'], big['rank'], r['rank']))
print('rank rule: %s' % ('ok' if not bad else '; '.join(bad)))
ranks = [r['rank'] for r in out]
assert len(ranks) == len(set(ranks)), 'two roads share a rank'
data['roads'] = out
data['note'] = 'ygn_roads_v2.json + Inya Road split at its crossings, map-edge ends marked (tools/yangon/d8_streets.py, 13 Nov 2026)'
json.dump(data, open(os.path.join(MAP, 'ygn_roads_v3.json'), 'w', encoding='utf-8'), separators=(',', ':'))
print('\n'.join(report))
print('%d map-edge ends:' % len(edge))
print('\n'.join('  ' + e for e in edge))
print('%d roads written to ygn_roads_v3.json' % len(out))
