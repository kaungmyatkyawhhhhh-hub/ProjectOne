import json, os, pickle, sys
sys.path.insert(0, r'D:/ObsidianOne/Claude+Obsidian/Games/CityLegends/tools/yangon/city')
import roads05_bake as RB, roads05_collide_check as CC
import numpy as np
tag, name, i0, i1 = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
D = RB.od(tag)
parts = pickle.load(open(os.path.join(D, 'parts.pkl'), 'rb'))
data = json.load(open(os.path.join(D, 'roads.json'), encoding='utf-8'))
cache = os.path.join(os.path.dirname(__file__), 'rows_%s.pkl' % tag)
if os.path.exists(cache):
    rows = pickle.load(open(cache, 'rb'))
else:
    tris = [t for p in parts if p[0] == 'R' for t in RB.faces_of(p)]
    rows = RB.collision(data, RB.Surface(tris), parts)
    pickle.dump(rows, open(cache, 'wb'))
r = [q for q in data['roads'] if q['name'] == name][0]
xs = [r['s'][i][0] for i in range(i0, i1)]; zs = [r['s'][i][2] for i in range(i0, i1)]
B = [b for b in CC.boxes_of(rows) if min(xs) - 200 < b[0][0] < max(xs) + 200 and min(zs) - 200 < b[0][2] < max(zs) + 200]
tris = [t for p in parts if p[0] == 'R' for t in RB.faces_of(p) if min(xs) - 60 < t[0][0] < max(xs) + 60 and min(zs) - 60 < t[0][2] < max(zs) + 60]
S = RB.Surface(tris)
prev = None
for i in range(i0, i1):
    q = r['s'][i]
    for f in (0.0, 0.5):
        if i + 1 >= len(r['s']) and f: continue
        a = np.array(q[:3]); b = np.array(r['s'][min(i + 1, len(r['s']) - 1)][:3]); p = a + (b - a) * f
        out = []
        for off in (-6, 0, 6):
            x, z = p[0] - q[4] * off, p[2] + q[3] * off
            hs = S.heights(x, z); h = max(hs) if hs else None
            tops = [y for y in (CC.top_at(bb, x, z) for bb in B) if y is not None and (h is None or abs(y - h) < 3)]
            out.append('%s/%s' % ('%.2f' % h if h else '-', '%.2f' % max(tops) if tops else '-'))
        print(i + f, round(p[1], 2), out)
