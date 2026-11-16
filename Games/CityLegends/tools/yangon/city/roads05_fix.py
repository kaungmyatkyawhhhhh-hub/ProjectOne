"""Junction fixes on a roads05 network, run after roads05.py and before roads05_paint.py (17 Nov 2026, owner: kerbs
lying diagonally across a junction, a grass median running through a junction; "Friday's builder never did that").

    YANGON_SCALE=1to1 python roads05_fix.py <tags joined by _>
-> rewrites build/city_1to1/roads05_<tags>/roads.json + Roads05_<k>.luau, prints counts (fix.json)

  * mouths: a road that ends on a bigger road (lower rank) is run on straight until BOTH its carriageway edges reach
    the bigger road's carriageway (YangonRoads.buildMouth walks each edge to the bigger road's edge and fails, leaving
    the kerbs across the junction, when one never gets there). Never further than the bigger road's half width.
  * medians: no median sample on another road's carriageway or a ring, plus MED_GAP studs before it (the median ends
    before the junction box).
"""
import json, math, os, sys

import numpy as np
from shapely.geometry import LineString, Point, Polygon
from shapely.ops import unary_union
from shapely.strtree import STRtree

import geo
from roads05_qa import quads

STEP = 8.0
MED_GAP = 6.0
CHUNK = 185000


def main():
    tag = sys.argv[1]
    D = os.path.join(geo.BUILD, 'city_1to1', 'roads05_' + tag)
    raw = os.path.join(D, 'roads_unfixed.json')  # roads05.py's own output: every fix starts from it (re-runnable)
    if not os.path.exists(raw):
        os.replace(os.path.join(D, 'roads.json'), raw)
    data = json.load(open(raw, encoding='utf-8'))
    import roads05_chain
    chained = roads05_chain.chain(data)
    chained['continuations'] = roads05_chain.continuations(data)
    print('chain', json.dumps(chained))
    roads = data['roads']
    cutd = {k: set(v) for k, v in data['cut'].items()}
    names = [r['name'] for r in roads]
    geoms = [unary_union(quads(r['s'], cutd.get(r['name'], ()))) for r in roads]
    tree = STRtree(geoms)
    rank = {r['name']: r['rank'] for r in roads}
    rings = [Point(g['c'][0], g['c'][2]).buffer(g['r_out'] + 1, 64) for g in data['roundabouts']]
    ringU = unary_union(rings) if rings else Polygon()
    st = dict(chain=chained, ends_extended=0, extend_studs=0.0, ends_unreached=[], median_samples_cleared=0)
    # 1. mouths
    for ri, r in enumerate(roads):
        s = r['s']
        if len(s) < 2 or r.get('closed'):
            continue
        cut = cutd.get(r['name'], set())
        for k in (0, -1):
            if (k == 0 and 0 in cut) or (k == -1 and len(s) - 1 in cut):
                continue
            if r.get('startsOnEnd' if k == 0 else 'endsOnEnd'):
                continue  # carries on from another road's end: no mouth
            q = s[k]
            p = Point(q[0], q[2])
            # a ring arm: both its edges must end inside the ring's outer polygon (buildMouth walks them to it),
            # an arm arriving off-centre is run on straight (the part inside R_OUT - 14 is cut by the builder anyway)
            for g in data['roundabouts']:
                cx, cz, ro = g['c'][0], g['c'][2], g['r_out']
                if math.hypot(q[0] - cx, q[2] - cz) >= ro:
                    continue
                d = np.array([q[3], q[4]]) * (1 if k == -1 else -1)
                d = d / (np.linalg.norm(d) or 1)
                right = np.array([-d[1], d[0]])
                rv = ro / math.cos(math.pi / 96) - 1.5
                t = 0.0
                while t < 80:
                    c = np.array([q[0], q[2]]) + d * t
                    if all(math.hypot(*(c + right * sd * h - np.array([cx, cz]))) < rv for sd, h in ((-1, max(q[6], q[7])), (1, max(q[6], q[7])))):
                        break
                    t += 2.0
                if t > 0 and t < 80:
                    add = []
                    for i in range(1, int(math.ceil(t / STEP)) + 1):
                        tt = min(t, i * STEP)
                        nq = list(q)
                        nq[0], nq[2] = round(q[0] + d[0] * tt, 2), round(q[2] + d[1] * tt, 2)
                        add.append(nq)
                    if k == -1:
                        s.extend(add)
                    else:
                        for nq in add:
                            s.insert(0, nq)
                        if r['name'] in cutd:
                            cutd[r['name']] = set(i + len(add) for i in cutd[r['name']])
                            data['cut'][r['name']] = sorted(cutd[r['name']])
                        for dk in data['decks']:
                            if dk['of'] == r['name']:
                                dk['from'] += len(add)
                                dk['to'] += len(add)
                    st['ring_arms_extended'] = st.get('ring_arms_extended', 0) + 1
                break
            if ringU.distance(p) < 2:
                continue
            big = None
            for j in tree.query(p.buffer(12)):
                o = names[int(j)]
                if o != r['name'] and rank[o] < rank[r['name']] and geoms[int(j)].distance(p) < 12:
                    if big is None or geoms[int(j)].distance(p) < geoms[big].distance(p):
                        big = int(j)
            if big is None or r['kind'] == 'side':
                continue  # (a side lane starts / ends on its road's cut end: the builder's own join)
            bs = roads[big]['s']
            if min(math.hypot(bs[e][0] - q[0], bs[e][2] - q[2]) for e in (0, -1)) < 40:
                continue  # end to end (a road running on into the next piece), not a mouth
            G = geoms[big]
            d = np.array([q[3], q[4]]) * (1 if k == -1 else -1)
            right = np.array([-q[4], q[3]])
            need = 0.0
            reach = max(max(x[6] + x[7] for x in roads[big]['s']), 20.0)
            ok = True
            for side, h in ((-1, q[6]), (1, q[7])):
                e = np.array([q[0], q[2]]) + right * side * h
                if G.contains(Point(e)):
                    continue
                ray = LineString([e, e + d * reach])
                X = ray.intersection(G)
                if X.is_empty:
                    ok = False
                    continue
                hits = list(X.geoms) if hasattr(X, 'geoms') else [X]
                need = max(need, min(ray.project(Point(h.coords[0])) for h in hits))
            if not ok:
                st['ends_unreached'].append(dict(road=r['name'], on=names[big], x=round(q[0], 1), z=round(q[2], 1)))
                continue
            if need <= 0.3:
                continue
            need += 1.0  # past the edge, so the edge walk meets it inside a segment
            n = max(1, int(math.ceil(need / STEP)))
            add = []
            for i in range(1, n + 1):
                t = need * i / n
                nq = list(q)
                nq[0] = round(q[0] + d[0] * t, 2)
                nq[2] = round(q[2] + d[1] * t, 2)
                add.append(nq)
            if k == -1:
                s.extend(add)
            else:
                for nq in add:
                    s.insert(0, nq)
                if r['name'] in cutd:  # sample indices move
                    cutd[r['name']] = set(i + n for i in cutd[r['name']])
                    data['cut'][r['name']] = sorted(cutd[r['name']])
                for dk in data['decks']:
                    if dk['of'] == r['name']:
                        dk['from'] += n
                        dk['to'] += n
            st['ends_extended'] += 1
            st['extend_studs'] += need
    # 2. medians end before any other carriageway / ring
    for ri, r in enumerate(roads):
        s = r['s']
        if not any(q[8] > 0 for q in s):
            continue
        clear = set()
        for i, q in enumerate(s):
            if q[8] <= 0:
                continue
            p = Point(q[0], q[2])
            hit = ringU.distance(p) < MED_GAP
            if not hit:
                for j in tree.query(p.buffer(MED_GAP + q[8])):
                    if names[int(j)] != r['name'] and geoms[int(j)].distance(p) < MED_GAP:
                        hit = True
                        break
            if hit:
                clear.add(i)
        for i in clear:
            s[i][8] = 0
        st['median_samples_cleared'] += len(clear)
    txt = json.dumps(data, separators=(',', ':'))
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
    st['extend_studs'] = round(st['extend_studs'])
    json.dump(st, open(os.path.join(D, 'fix.json'), 'w'), indent=1)
    print(json.dumps(dict(st, ends_unreached=len(st['ends_unreached']))))


if __name__ == '__main__':
    main()
