"""Lane data for the districts that are in the game (18 Nov 2026, road rebuild): roads05_lanes.py builds lanes on every
road in its roads.json, and a roads05_subset.py subset keeps whole roads within 600 studs of its districts, so lanes
would run on past the districts' edges where the game has no road meshes. This cuts each road to its longest run of
samples inside the districts (decks re-indexed, roads and decks left with < 2 samples dropped); a cut end then turns
round in roads05_lanes.py like any map edge.

    YANGON_SCALE=1to1 python roads05_lanesubset.py <network tag> <out tag> <district> [district ...]
    YANGON_SCALE=1to1 python roads05_lanes.py <out tag> --install
"""
import json, os, sys
from shapely.geometry import Point
from shapely.ops import unary_union
import geo

src, dst, ds = sys.argv[1], sys.argv[2], sys.argv[3:]
S = os.path.join(geo.BUILD, 'city_1to1', 'roads05_' + src)
D = os.path.join(geo.BUILD, 'city_1to1', 'roads05_' + dst)
os.makedirs(D, exist_ok=True)
d = json.load(open(os.path.join(S, 'roads.json'), encoding='utf-8'))
area = unary_union([geo.batch_poly(t) for t in ds])


def longest_run(s):
    best, cur = (0, -1), None
    for i, q in enumerate(s):
        if area.contains(Point(q[0], q[2])):
            cur = i if cur is None else cur
            if i - cur > best[1] - best[0]:
                best = (cur, i)
        else:
            cur = None
    return best


roads, cut = [], {}
for r in d['roads']:
    a, b = longest_run(r['s'])
    if b - a < 1:
        continue
    if (a, b) != (0, len(r['s']) - 1):
        cut[r['name']] = a
        r = dict(r, s=r['s'][a:b + 1])
    roads.append(r)
names = {r['name']: r for r in roads}
decks = []
for k in d.get('decks', []):
    r = names.get(k['of'])
    if not r:
        continue
    a = cut.get(k['of'], 0)
    f, t = max(k['from'] - a, 0), min(k['to'] - a, len(r['s']) - 1)
    if t - f < 1:
        continue
    decks.append(dict(k, s=k['s'][f + a - k['from']:t + a - k['from'] + 1], **{'from': f, 'to': t}))
d['roads'], d['decks'] = roads, decks
d['roundabouts'] = [o for o in d.get('roundabouts', []) if area.contains(Point(o['c'][0], o['c'][2]))]
d['note'] = d.get('note', '') + ' | lanes subset %s of %s (roads cut to the districts)' % ('+'.join(ds), src)
assert all(len(k['s']) == k['to'] - k['from'] + 1 for k in decks)
json.dump(d, open(os.path.join(D, 'roads.json'), 'w', encoding='utf-8'), separators=(',', ':'))
print('roads %d (cut %d), decks %d, rings %d' % (len(roads), len(cut), len(decks), len(d['roundabouts'])))
