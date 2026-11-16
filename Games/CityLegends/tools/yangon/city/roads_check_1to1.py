"""1:1 road checks for a pilot district (2026-11-16, rescale step 3): run after roads.py <tag> with YANGON_SCALE=1to1.

    YANGON_SCALE=1to1 python roads_check_1to1.py P1

Prints and writes build/city_1to1/roads_<tag>_check.json:
  * per named main road: lanes a side, lane width (studs and m), carriageway and median widths, kerb to kerb (m), its
    length, the traffic lanes built (roadlanes), against the vault audit's real cross-sections
  * the flyovers: clearance under the girders (studs), deck height
  * dead ends: lanes whose end has no link (after roadlanes' prune: must be 0), lanes dropped by the prune
  * triangles per real km against batches 1-3 (the budget: today's figure or fewer), unique meshes, collision boxes per km
  * ground roads that push_beside moved, and how far
"""
import json, os, re, sys
from collections import defaultdict

import numpy as np

import geo
import ground
import heights as hts
import roadnet as rn

REAL = {   # vault "Audit - Yangon roads 1 to 1" (kerb to kerb, metres; lanes a side)
    'Kabar Aye Pagoda Road': '3+3, ~19.5 m incl. a ~1 m barrier (road_04); flyover deck 2+2 ~17 m (junc_06)',
    'Pyay Road': '3+3, 2 x ~11.5 m, 12-14 m planted median at Inya Lake (road_01)',
    'U Wisara Road': '2+2, 2 x ~7.5 m, ~5 m tree median (road_22, read off the ruler)',
    'Inya Road': 'OSM lanes=4 two-way (2+2); not measured in the audit',
    'University Avenue Road': 'OSM lanes=4 two-way (2+2); not measured in the audit',
    'New University Avenue Road': 'OSM one-way lanes=2 pair; not measured in the audit',
}


def main(tag):
    out = os.path.join(geo.BUILD, 'city_1to1' if geo.ONE_TO_ONE else 'city')
    st = json.load(open(os.path.join(out, 'roads_%s_stats.json' % tag), encoding='utf-8'))
    net = rn.build(tag)
    G = ground.Ground()
    hts.solve(net, G, log=lambda *a: None)
    if hts.extend_short(net, G, log=lambda *a: None):
        hts.solve(net, G, log=lambda *a: None)
    res = dict(tag=tag, roads={}, flyovers=st['bridges'])
    by = defaultdict(list)
    for e in net.edges:
        if e.look == 'main' and e.name:
            by[e.name].append(e)
    for name, es in sorted(by.items(), key=lambda kv: -sum(rn.chain(e.P)[-1] for e in kv[1])):
        L = sum(rn.chain(e.P)[-1] for e in es) / geo.SPM
        xs = defaultdict(float)
        for e in es:
            lo, hi = rn.offsets(e)
            ln = rn.chain(e.P)[-1] / geo.SPM
            bridge = ' bridge' if (e.bridge or e.layer >= 1) else ''
            if e.oneway:
                med = 2 * float(np.median(lo)) if (e.w > 0.5).mean() > 0.5 else 0.0
                k = 'one-way %d x %.1f = %.1f m%s%s' % (e.nf, e.Wf, e.nf * e.Wf / geo.SPM,
                                                        (', median %.1f m' % (med / geo.SPM)) if med else '', bridge)
            else:
                k = '%d+%d x %.1f / %.1f = %.1f m%s' % (e.nf, e.nb, e.Wf, e.Wb, (hi - lo).mean() / geo.SPM, bridge)
            xs[k] += ln
        if L < 60:
            continue
        res['roads'][name] = dict(m=round(L), real=REAL.get(name), built={k: round(v) for k, v in sorted(xs.items(), key=lambda kv: -kv[1])})
    # traffic lanes per road (the written modules)
    lanes = defaultdict(lambda: defaultdict(int))
    nl = 0
    for f in sorted(os.listdir(out)):
        if re.match(r'YangonLanesB%s_\d+\.lua$' % tag, f):
            src = open(os.path.join(out, f), encoding='utf-8').read()
            for m in re.finditer(r'\{ road = "([^"]*) B%s\.\d+", way = (-?\d+), lane = (\d+)' % tag, src):
                lanes[m.group(1)][(int(m.group(2)), int(m.group(3)))] += 1
                nl += 1
    for name in res['roads']:
        d = lanes.get(name, {})
        res['roads'][name]['lane_records'] = {'way %d lane %d' % k: v for k, v in sorted(d.items())}
    # dead ends in the written lanes: every lane's last point must have a link from it
    dead, links_from = 0, set()
    total = 0
    first = None
    for f in sorted(os.listdir(out)):
        if re.match(r'YangonLanesB%s_\d+\.lua$' % tag, f):
            src = open(os.path.join(out, f), encoding='utf-8').read()
            fst = int(re.search(r'first = (\d+)', src).group(1))
            first = fst if first is None else min(first, fst)
            n = len(re.findall(r'\{ road = ', src))
            pts = [len(m.group(1).split(',')) // 3 for m in re.finditer(r'pts = \{ ([^}]*) \}', src)]
            for m in re.finditer(r'\{ (\d+), (\d+), (\d+), (\d+) \},', src):
                a, fk = int(m.group(1)), int(m.group(2))
                links_from.add((a, fk))
            total += n
    lens = {}
    for f in sorted(os.listdir(out)):
        if re.match(r'YangonLanesB%s_\d+\.lua$' % tag, f):
            src = open(os.path.join(out, f), encoding='utf-8').read()
            fst = int(re.search(r'first = (\d+)', src).group(1))
            for j, m in enumerate(re.finditer(r'pts = \{ ([^}]*) \}', src)):
                lens[fst + j] = len(m.group(1).split(',')) // 3
    ends = {}
    for (a, fk) in links_from:
        ends[a] = max(ends.get(a, 0), fk)
    for g, n in lens.items():
        if ends.get(g, 0) < n - 3:
            dead += 1
    res['lanes'] = dict(total=total, dead_ends=dead, dropped_by_prune=st['lane_stats'].get('dropped'),
                        turnround=st['lane_stats'].get('turnround'))
    # budget
    km = st['km_total']
    tri = st['triangles']['total']
    ref = {}
    for t in ('1', '2', '3'):
        p = os.path.join(geo.BUILD, 'city', 'roads_%s_stats.json' % t)
        if os.path.exists(p):
            s = json.load(open(p, encoding='utf-8'))
            ref[t] = dict(tris_per_km=round(s['triangles']['total'] / s['km_total']),
                          boxes_per_km=round(s['collision_boxes'] / s['km_total']),
                          meshes_per_km2=None)
    res['budget'] = dict(km=km, triangles=tri, tris_per_km=round(tri / km), meshes=st['meshes'],
                         collision_boxes=st['collision_boxes'], boxes_per_km=round(st['collision_boxes'] / km),
                         reference_1p6=ref)
    # push_beside
    moved = []
    for e in net.edges:
        pm = getattr(e, 'push', None)
        if pm is not None:
            mx = float(np.linalg.norm(pm, axis=1).max())
            if mx > 0.5:
                moved.append((round(mx / geo.SPM, 1), e.name or e.hw, e.hw))
    moved.sort(reverse=True)
    res['pushed_beside_flyovers'] = moved[:20]
    json.dump(res, open(os.path.join(out, 'roads_%s_check.json' % tag), 'w', encoding='utf-8'), indent=1, ensure_ascii=False)
    print(json.dumps(res, indent=1, ensure_ascii=False))


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    main(sys.argv[1])
