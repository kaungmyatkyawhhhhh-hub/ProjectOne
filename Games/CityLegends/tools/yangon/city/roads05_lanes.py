"""Traffic lanes for the roads05 roads (16 Nov 2026): src/shared/YangonLanes1to1_<k>.lua (the 1:1 set, numbered from 1,
RivieraTraffic.build adds it last), from the same data the builder used.

    YANGON_SCALE=1to1 python roads05_lanes.py <tags joined by _>

Lanes on every main road (kind route / side), over decks (a deck's samples carry its heights), round each roundabout
(closed loops, anticlockwise seen from above: traffic keeps right). 12-stud lanes where the road holds them (the road's
own lane width, never wider than the half it runs in). A road is cut into pieces where it runs inside a bigger road's
carriageway (or a ring): links join a piece's end to the next piece (straight on), to the bigger road's lanes (right turn
from the outer lane, left turn from lane 1), and the bigger road's lanes to the pieces leaving the junction. A lane end
with nothing to go to turns round onto its own road's other way (map edges, a main road ending in a street). Checks:
0 lane ends without a way on.
"""
import collections, json, math, os, re, sys

import numpy as np
from shapely.geometry import Point, LineString
from shapely.strtree import STRtree

sys.stdout.reconfigure(encoding='utf-8')
import geo

DEBUG = None
EVERY = 3            # one lane point every 3 samples (24 studs)
MAXCHARS = 185000


def od(tag):
    return os.path.join(geo.BUILD, 'city_1to1', 'roads05_' + tag)


def main(tag):
    data = json.load(open(os.path.join(od(tag), 'roads.json'), encoding='utf-8'))
    roads = [r for r in data['roads'] if r['kind'] in ('route', 'side')]
    allr = {r['name']: r for r in data['roads']}
    rings = data.get('roundabouts', [])
    deck_of = {d['of']: d for d in data.get('decks', [])}
    region_poly = None
    try:
        from shapely.ops import unary_union
        region_poly = unary_union([geo.batch_poly(t) for t in data['tags']])
    except Exception:
        pass
    # samples with deck heights
    S = {}
    for r in roads:
        s = [list(q) for q in r['s']]
        d = deck_of.get(r['name'])
        if d:
            for k, i in enumerate(range(d['from'], d['to'] + 1)):
                s[i][1] = d['s'][k][1]
        S[r['name']] = s
    # carriageway test against bigger main roads
    lines = [LineString([(q[0], q[2]) for q in r['s']]) for r in roads]
    tree = STRtree(lines)
    rank = {r['name']: r['rank'] for r in roads}

    def inside(x, z, o):
        s = o['s']
        P = np.array([[q[0], q[2]] for q in s])
        d = np.hypot(P[:, 0] - x, P[:, 1] - z)
        i = int(np.argmin(d))
        q = s[i]
        rx, rz = -q[4], q[3]
        lat = (x - q[0]) * rx + (z - q[2]) * rz
        along = abs((x - q[0]) * q[3] + (z - q[2]) * q[4])
        if along > 12:
            return None
        if -q[6] - 0.5 <= lat <= q[7] + 0.5:
            return i
        return None

    def in_ring(x, z):
        for g in rings:
            if math.hypot(x - g['c'][0], z - g['c'][2]) < g['r_out'] + 2:
                return g
        return None

    lanes = []        # dicts: road, way, lane, kind, closed, pts (list of (x,y,z)), outer, info
    piece_ends = []   # (lane index, 'end'/'start', road, piece id, way, lane k, nlanes, (x,z), junction info)
    pieces = {}
    for ri, r in enumerate(roads):
        s = S[r['name']]
        n = len(s)
        big = [int(j) for j in tree.query(lines[ri].buffer(80)) if int(j) != ri and roads[int(j)]['rank'] < r['rank']]
        mask = []
        jinfo = []
        for i in range(n):
            q = s[i]
            hit = None
            g = in_ring(q[0], q[2])
            if g:
                hit = ('ring', g['name'])
            else:
                for j in big:
                    if inside(q[0], q[2], roads[j]) is not None:
                        hit = ('road', roads[j]['name'])
                        break
            mask.append(hit is None)
            jinfo.append(hit)
        runs = []
        i = 0
        while i < n:
            if not mask[i]:
                i += 1
                continue
            j = i
            while j + 1 < n and mask[j + 1]:
                j += 1
            if j - i >= 2:
                runs.append((i, j))
            i = j + 1
        nl = max(1, max(q[9] for q in s))
        one = r.get('oneway')
        for pid, (a, b) in enumerate(runs):
            idx = list(range(a, b + 1, EVERY))
            if idx[-1] != b:
                idx.append(b)
            before = jinfo[a - 1] if a > 0 else None
            after = jinfo[b + 1] if b + 1 < n else None
            for way in ((1,) if one else (1, -1)):
                for k in range(1, nl + 1):
                    pts = []
                    for i in idx:
                        q = s[i]
                        rx, rz = -q[4], q[3]
                        if one:
                            W = (q[6] + q[7]) / nl
                            off = -q[6] + W * (k - 0.5)
                        else:
                            half = q[7] if way > 0 else q[6]
                            lm = q[11]
                            W = min(q[10], max(6.0, (half - lm) / nl))
                            off = way * min(lm + W * (k - 0.5), half - W / 2)
                        pts.append((q[0] + rx * off, q[1], q[2] + rz * off))
                    if way < 0:
                        pts = pts[::-1]
                    li = len(lanes)
                    lanes.append(dict(road=r['name'], way=way, lane=k, kind='route', closed=False, pts=pts,
                                      outer=(k == nl), nl=nl, rname=r['name'], pid=pid))
                    # the junctions at this lane's ends (in its own direction)
                    jend = after if way > 0 else before
                    jstart = before if way > 0 else after
                    pieces.setdefault((r['name'], pid), {})[(way, k)] = li
                    lanes[-1]['jend'] = jend
                    lanes[-1]['jstart'] = jstart
                    lanes[-1]['edge_end'] = (way > 0 and b == n - 1) or (way < 0 and a == 0)
    # ring lanes
    ring_lanes = {}
    for g in rings:
        cx, cy, cz = g['c']
        L = g['lanes']
        W = (g['r_out'] - g['r_in']) / L
        for k in range(1, L + 1):
            rr = g['r_in'] + W * (k - 0.5)
            m = max(16, int(2 * math.pi * rr / 24))
            pts = []
            for j in range(m):
                a = -2 * math.pi * j / m        # decreasing angle = anticlockwise seen from above (Z points south)
                pts.append((cx + rr * math.cos(a), cy, cz + rr * math.sin(a)))
            li = len(lanes)
            lanes.append(dict(road=g['name'], way=1, lane=k, kind='route', closed=True, pts=pts, outer=(k == L), nl=L,
                              rname=g['name'], pid=0, jend=None, jstart=None, edge_end=False))
            ring_lanes[(g['name'], k)] = li
    links = []

    def nearest(li, x, z):
        P = lanes[li]['pts']
        d = [math.hypot(p[0] - x, p[2] - z) for p in P]
        return int(np.argmin(d))

    def ldir(li, k):
        P = lanes[li]['pts']
        k = max(0, min(len(P) - 2, k))
        d = np.array([P[k + 1][0] - P[k][0], P[k + 1][2] - P[k][2]])
        n = np.linalg.norm(d)
        return d / n if n > 1e-9 else np.array([1.0, 0.0])

    def right_of(d):
        return np.array([-d[1], d[0]])

    by_road = collections.defaultdict(list)
    for li, l in enumerate(lanes):
        by_road[l['rname']].append(li)

    # 1. straight on across a junction gap (same road, next piece, same way, same lane)
    for li, l in enumerate(lanes):
        if l['closed']:
            continue
        nxt = (l['rname'], l['pid'] + l['way'])
        tgt = pieces.get(nxt, {}).get((l['way'], min(l['lane'], l['nl'])))
        if tgt is not None and l['jend'] is not None:
            links.append([li, len(l['pts']), tgt, 1])
            l['linked'] = True
    # 2. turns: a lane ending at a junction with a bigger road / ring; 3. into lanes starting at a junction
    for li, l in enumerate(lanes):
        if l['closed']:
            continue
        j = l['jend']
        if j:
            end = l['pts'][-1]
            din = ldir(li, len(l['pts']) - 2)
            if j[0] == 'ring':
                tgt = ring_lanes.get((j[1], max(k for (nm, k) in ring_lanes if nm == j[1])))
                kk = nearest(tgt, end[0], end[2])
                links.append([li, len(l['pts']), tgt, (kk + 1) % len(lanes[tgt]['pts']) + 1])
                l['linked'] = True
            else:
                for ti in by_road[j[1]]:
                    t = lanes[ti]
                    kk = nearest(ti, end[0], end[2])
                    dout = ldir(ti, kk)
                    if float(din @ dout) < -0.7:
                        continue
                    turn_right = float(right_of(din) @ dout) > 0.25
                    turn_left = float(right_of(din) @ dout) < -0.25
                    ok = (turn_right and l['lane'] > l['nl'] / 2 and t['outer']) \
                        or (turn_left and l['lane'] <= math.ceil(l['nl'] / 2) and t['lane'] == min(l['lane'], t['nl'])) \
                        or (not turn_left and not turn_right and t['lane'] == min(l['lane'], t['nl']))
                    near_ok = math.hypot(t['pts'][kk][0] - end[0], t['pts'][kk][2] - end[2]) < 70
                    if ok and near_ok and kk + 2 < len(t['pts']):
                        links.append([li, len(l['pts']), ti, kk + 2])
                        l['linked'] = True
                    if DEBUG and l['road'] == DEBUG:
                        print('dbg', li, l['way'], l['lane'], '->', ti, t['road'], t['way'], t['lane'], kk, len(t['pts']), round(float(din @ dout), 2), turn_right, turn_left, ok)
        j = l['jstart']
        if j:
            st = l['pts'][0]
            dout = ldir(li, 0)
            if j[0] == 'ring':
                src = ring_lanes.get((j[1], max(k for (nm, k) in ring_lanes if nm == j[1])))
                kk = nearest(src, st[0], st[2])
                links.append([src, kk + 1, li, 1])
            else:
                for si in by_road[j[1]]:
                    sl = lanes[si]
                    kk = nearest(si, st[0], st[2])
                    din = ldir(si, kk)
                    if float(din @ dout) < -0.7:
                        continue
                    turn_right = float(right_of(din) @ dout) > 0.25
                    turn_left = float(right_of(din) @ dout) < -0.25
                    ok = (turn_right and sl['outer'] and l['lane'] > l['nl'] / 2) \
                        or (turn_left and sl['lane'] == 1 and l['lane'] <= math.ceil(l['nl'] / 2)) \
                        or (not turn_left and not turn_right and l['lane'] == min(sl['lane'], l['nl']))
                    near_ok = math.hypot(sl['pts'][kk][0] - st[0], sl['pts'][kk][2] - st[2]) < 70
                    if ok and near_ok and kk >= 1:
                        links.append([si, kk, li, 1])
    # straight across a junction onto another road that carries on ahead (University Avenue -> New University Avenue
    # under the flyover): a lane end with no straight-on link takes the nearest lane start ahead, same heading
    starts = [(li, l) for li, l in enumerate(lanes) if not l['closed']]
    straight_from = set(a for a, ka, b, kb in links if lanes[b]['road'] == lanes[a]['road'] or kb == 1)
    for li, l in enumerate(lanes):
        if l['closed'] or li in straight_from:
            continue
        end = np.array([l['pts'][-1][0], l['pts'][-1][2]])
        din = ldir(li, len(l['pts']) - 2)
        best = None
        for ti, t in starts:
            if t['road'] == l['road'] or t['lane'] != min(l['lane'], t['nl']):
                continue
            st = np.array([t['pts'][0][0], t['pts'][0][2]])
            v = st - end
            d = float(np.linalg.norm(v))
            if d < 1 or d > 160:
                continue
            if float(v @ din) / d < 0.9 or float(ldir(ti, 0) @ din) < 0.85:
                continue
            if best is None or d < best[0]:
                best = (d, ti)
        if best:
            links.append([li, len(l['pts']), best[1], 1])
            continue
        # else any lane passing just ahead, the same heading (a one-way piece running into its own road)
        for ti, t in starts:
            if ti == li:
                continue
            kk = nearest(ti, end[0], end[1])
            if kk + 2 >= len(t['pts']):
                continue
            q = np.array([t['pts'][kk + 1][0], t['pts'][kk + 1][2]])
            if np.linalg.norm(q - end) < 60 and float(ldir(ti, kk) @ din) > 0.7:
                links.append([li, len(l['pts']), ti, kk + 2])
                break
    # ring: loops, lane changes outward a few times a turn
    for (nm, k), li in ring_lanes.items():
        P = lanes[li]['pts']
        links.append([li, len(P), li, 1])
        out = ring_lanes.get((nm, k + 1))
        if out:
            for q in range(0, len(P), max(1, len(P) // 4)):
                kk = nearest(out, P[q][0], P[q][2])
                links.append([li, q + 1, out, (kk + 1) % len(lanes[out]['pts']) + 1])
    # 4. dead ends: turn round onto the road's other way (same piece, lane 1)
    turned = 0
    inner_turn = []
    linked_from_end = set(l[0] for l in links if l[1] >= len(lanes[l[0]]['pts']))
    for li, l in enumerate(lanes):
        if l['closed'] or li in linked_from_end:
            continue
        back = pieces.get((l['rname'], l['pid']), {}).get((-l['way'], 1))
        if back is not None:
            links.append([li, len(l['pts']), back, 1])
            turned += 1
            if not l['edge_end']:
                inner_turn.append((l['road'], l['way'], [round(v) for v in l['pts'][-1]], l['jend']))
        elif l['way'] == 1 and l['nl'] >= 1:
            # a one-way road ending nowhere: on to the nearest other lane start
            pass
    linked_from_end = set(l[0] for l in links if l[1] >= len(lanes[l[0]]['pts']))
    dead = [li for li, l in enumerate(lanes) if not l['closed'] and li not in linked_from_end]
    # write
    SRC = os.path.join(geo.ROOT, 'src', 'shared') if '--install' in sys.argv else os.path.join(od(tag), 'lanes')
    os.makedirs(SRC, exist_ok=True)
    for f in os.listdir(SRC):
        if re.match(r'YangonLanes1to1_\d+\.lua$', f):
            os.remove(os.path.join(SRC, f))

    def lane_txt(l):
        flat = ','.join('%.2f,%.2f,%.2f' % p for p in l['pts'])
        return '\t\t{ road = %s, way = %d, lane = %d, kind = "route", closed = %s, yangon = true%s, pts = { %s } },' % (
            json.dumps(l['road']), l['way'], l['lane'], 'true' if l['closed'] else 'false', ', outer = true' if l['outer'] else '', flat)
    mods = []
    cur, n, first = [], 0, 1
    for li, l in enumerate(lanes):
        t = lane_txt(l)
        if cur and n + len(t) > MAXCHARS - 30000:
            mods.append((first, cur))
            first += len(cur)
            cur, n = [], 0
        cur.append(t)
        n += len(t) + 1
    mods.append((first, cur))
    # links go with the module of their source lane
    link_mod = collections.defaultdict(list)
    for a, ka, b, kb in links:
        for mi, (f0, ls) in enumerate(mods):
            if f0 <= a + 1 < f0 + len(ls):
                link_mod[mi].append('\t\t{ %d, %d, %d, %d },' % (a + 1, ka, b + 1, kb))
                break
    for mi, (f0, ls) in enumerate(mods):
        head = ['-- generated by tools/yangon/city/roads05_lanes.py from roads05_%s/roads.json (OSM ODbL): do not edit' % tag,
                '-- the 1:1 Yangon frame\'s traffic lanes, module %d of %d; numbered from 1 within the 1:1 set (`first`, links too);' % (mi + 1, len(mods)),
                '-- RivieraTraffic.build adds them after every other module',
                'return {', '\tfirst = %d,' % f0, '\tlanes = {']
        body = head + ls + ['\t},', '\tlinks = {'] + link_mod[mi] + ['\t},', '}', '']
        text = '\n'.join(body)
        assert len(text) < 199000, len(text)
        open(os.path.join(SRC, 'YangonLanes1to1_%d.lua' % (mi + 1)), 'w', encoding='utf-8', newline='\n').write(text)
        print('YangonLanes1to1_%d.lua %d chars, %d lanes, %d links' % (mi + 1, len(text), len(ls), len(link_mod[mi])))
    st = dict(lanes=len(lanes), links=len(links), turned_round=turned, dead_ends=len(dead), ring_lanes=len(ring_lanes), turned_inside=len(inner_turn), turned_inside_sample=inner_turn[:25],
              dead_sample=[lanes[i]['road'] for i in dead[:10]])
    json.dump(st, open(os.path.join(od(tag), 'lanes_stats.json'), 'w'), indent=1)
    print(json.dumps(st))


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else 'P1_P2')
