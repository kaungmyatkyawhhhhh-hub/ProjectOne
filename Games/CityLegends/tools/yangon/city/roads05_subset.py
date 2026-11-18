"""Studio subset of a roads05 network (17 Nov 2026): the districts in Studio built from the WHOLE network (seams match
the districts moved in later), but only the roads near them go into Studio's modules.

    YANGON_SCALE=1to1 python roads05_subset.py <network tag> <subset tag> <district> [district ...]
-> build/city_1to1/roads05_<subset tag>/roads.json + Roads05_<k>.luau (roads with a sample within GROW of the districts'
   boxes, their decks / cuts, roundabouts in reach), paint.json copied when present; subset.json = the district boxes
   (roads05_bake.py R05_CLIP keeps only parts inside them)
"""
import json, os, shutil, sys
from shapely.geometry import Point
from shapely.ops import unary_union
import geo

GROW = float(os.environ.get("R05_GROW", 600))  # R05_GROW: wider reach (seam cells rebuilt whole, P7 18 Nov)
CHUNK = 185000
src, dst, ds = sys.argv[1], sys.argv[2], sys.argv[3:]
S = os.path.join(geo.BUILD, 'city_1to1', 'roads05_' + src)
D = os.path.join(geo.BUILD, 'city_1to1', 'roads05_' + dst)
os.makedirs(D, exist_ok=True)
d = json.load(open(os.path.join(S, 'roads.json'), encoding='utf-8'))
area = unary_union([geo.batch_poly(t) for t in ds])
reach = area.buffer(GROW)
x0, z0, x1, z1 = reach.bounds
keep = []
for r in d['roads']:
    if any(x0 <= s[0] <= x1 and z0 <= s[2] <= z1 and reach.contains(Point(s[0], s[2])) for s in r['s'][::4] + r['s'][-1:]):
        keep.append(r)
names = set(r['name'] for r in keep)
d['roads'] = keep
d['decks'] = [k for k in d['decks'] if k['of'] in names]
d['cut'] = {k: v for k, v in d['cut'].items() if k in names}
d['roundabouts'] = [o for o in d['roundabouts'] if reach.contains(Point(o['c'][0], o['c'][2]))]
d['note'] += ' | subset %s of %s' % ('+'.join(ds), src)
txt = json.dumps(d, separators=(',', ':'))
open(os.path.join(D, 'roads.json'), 'w', encoding='utf-8').write(txt)
for f in os.listdir(D):
    if f.startswith('Roads05_') and f.endswith('.luau'):
        os.remove(os.path.join(D, f))
k = 0
for a in range(0, len(txt), CHUNK):
    k += 1
    part = txt[a:a + CHUNK]
    assert ']==]' not in part
    open(os.path.join(D, 'Roads05_%d.luau' % k), 'w', encoding='utf-8').write('return [==[' + part + ']==]')
if os.path.exists(os.path.join(S, 'paint.json')):
    shutil.copy(os.path.join(S, 'paint.json'), D)
json.dump(dict(src=src, districts=ds, boxes=[list(geo.batch_poly(t).exterior.coords) for t in ds]), open(os.path.join(D, 'subset.json'), 'w'))
print('roads %d decks %d rings %d modules %d chars %d' % (len(keep), len(d['decks']), len(d['roundabouts']), k, len(txt)))
