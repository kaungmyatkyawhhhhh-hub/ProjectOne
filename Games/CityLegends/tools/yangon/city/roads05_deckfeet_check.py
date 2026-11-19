# Mirror of YangonRoadsChecks.stepCell -> YangonRoads.buildDecks -> riviera/Roads.luau build/alignJunctions
# for the deck-only build of each 3072 build cell, WITH the bug: alignJunctions runs before Roads.build resets
# the module-level finalEdges, so bigSurface's across() reads finalEdges[rj] left by the cell's ground build
# (buildRoads, edgeSurface): ground road #rj's edges, rj = the bigger deck's position in this cell's deck list.
# Stale edge heights are approximated by that ground road's centre-line heights (s[k][1]).
# usage: python deckfeet.py roads.json [cell=3072]
import json, math, sys
HALF, MX = 32, 140
D = json.load(open(sys.argv[1], encoding='utf-8'))
CELL = float(sys.argv[2]) if len(sys.argv) > 2 else 3072.0
G = D['roads']


def run(decks, box, stale):
    roads = []
    for k, d in decks:
        half = d.get('half') or 32
        pts = [dict(x=s[0], y=s[1], z=s[2], wl=s[6], wr=s[7]) for s in d['s']]
        roads.append(dict(name=d['name'], rank=-k, half=half, dh=half - HALF, pts=pts, y0=[p['y'] for p in pts]))
    maxDh = max(r['dh'] for r in roads)
    grid = {}
    for ri, r in enumerate(roads):
        for i, p in enumerate(r['pts']):
            grid.setdefault((math.floor(p['x'] / 24), math.floor(p['z'] / 24)), []).append((ri, i))

    def otherNear(x, z, me, radius, bigger):
        best, bd = None, 1e18
        cx, cz = math.floor(x / 24), math.floor(z / 24)
        reach = math.ceil((radius + maxDh) / 24)
        for a in range(-reach, reach + 1):
            for b in range(-reach, reach + 1):
                for rj, j in grid.get((cx + a, cz + b), []):
                    if rj != me and roads[rj]['rank'] < bigger:
                        q = roads[rj]['pts'][j]
                        dd = math.hypot(q['x'] - x, q['z'] - z)
                        if dd < radius + roads[rj]['dh'] and dd < bd:
                            best, bd = rj, dd
        return best

    def bigSurface(x, z, me, rank):
        rj = otherNear(x, z, me, HALF + 6, rank)
        if rj is None:
            return None
        pts = roads[rj]['pts']
        best, bd = 0, 1e18
        cx, cz = math.floor(x / 24), math.floor(z / 24)
        for a in range(-2, 3):
            for b in range(-2, 3):
                for e, j in grid.get((cx + a, cz + b), []):
                    if e == rj:
                        dd = math.hypot(pts[j]['x'] - x, pts[j]['z'] - z)
                        if dd < bd:
                            best, bd = j, dd
        fe = stale.get(rj + 1) if stale is not None else None  # (Luau 1-based ri)

        def across(k0, k1, t):
            if fe is None:
                return None
            if k1 >= len(fe['s']):
                raise IndexError('crash')  # (fe.L[k] nil: the Luau build would have errored)
            return fe['s'][k0][1] + (fe['s'][k1][1] - fe['s'][k0][1]) * t
        for i0, i1 in ((best - 1, best), (best, best + 1)):
            if 0 <= i0 and i1 < len(pts):
                A, B = pts[i0], pts[i1]
                vx, vz = B['x'] - A['x'], B['z'] - A['z']
                t = ((x - A['x']) * vx + (z - A['z']) * vz) / max(vx * vx + vz * vz, 1e-9)
                if 0 <= t <= 1:
                    v = across(i0, i1, t)
                    return v if v is not None else A['y'] + (B['y'] - A['y']) * t
        v = across(best, best, 0)
        return v if v is not None else pts[best]['y']

    for ri in sorted(range(len(roads)), key=lambda i: roads[i]['rank']):
        r = roads[ri]; pts = r['pts']; n = len(pts); H = r['half']
        arc = [0.0]
        for i in range(1, n):
            arc.append(arc[-1] + math.hypot(pts[i]['x'] - pts[i - 1]['x'], pts[i]['z'] - pts[i - 1]['z']))
        events, cur = [], None
        for i in range(n):
            rj = otherNear(pts[i]['x'], pts[i]['z'], ri, HALF + 6, r['rank'])
            if rj is not None:
                if cur and cur['rj'] == rj and cur['last'] == i - 1:
                    cur['last'] = i
                else:
                    cur = dict(rj=rj, first=i, last=i, wide=False); events.append(cur)
                if pts[i]['wl'] >= H - 0.5 and pts[i]['wr'] >= H - 0.5:
                    cur['wide'] = True
            else:
                cur = None
        target, offs, weight = {}, [0.0] * n, [0.0] * n
        for e in events:
            if not e['wide']:
                continue
            for i in range(e['first'], e['last'] + 1):
                y = bigSurface(pts[i]['x'], pts[i]['z'], ri, r['rank'])
                if y is not None:
                    target[i] = y
            d0 = target[e['first']] - pts[e['first']]['y'] if e['first'] in target else 0
            d1 = target[e['last']] - pts[e['last']]['y'] if e['last'] in target else 0
            for j in range(n):
                if j < e['first'] or j > e['last']:
                    gap = arc[e['first']] - arc[j] if j < e['first'] else arc[j] - arc[e['last']]
                    d = d0 if j < e['first'] else d1
                    w = min(max(1 - gap / max(40, abs(d) / 0.06), 0), 1)
                    if w > weight[j]:
                        weight[j], offs[j] = w, d * w
        for j in range(n):
            if j in target:
                pts[j]['y'] = target[j]
            elif offs[j]:
                pts[j]['y'] += offs[j]
    return roads


def near_box(r, box):  # stepCell's `names`: a road with an odd (1-based) sample within MX of the box
    return any(box[0] - MX < s[0] < box[2] + MX and box[1] - MX < s[2] < box[3] + MX for s in r['s'][::2])


ENDS = [(d['s'][e][0], d['s'][e][2], d['name']) for d in D['decks'] for e in (0, -1)]


def joint(r, p):  # a deck end butting another deck: the edge pin holds it on that deck, not a ground foot
    return any(nm != r['name'] and math.hypot(x - p['x'], z - p['z']) < 2 for x, z, nm in ENDS)


hits, crashes = [], []
cells = {}
for k, d in enumerate(D['decks'], 1):
    mid = d['s'][len(d['s']) // 2]
    cells.setdefault((math.floor(mid[0] / CELL), math.floor(mid[2] / CELL)), []).append((k, d))
for (cx, cz), decks in sorted(cells.items()):
    box = (cx * CELL, cz * CELL, (cx + 1) * CELL, (cz + 1) * CELL)
    stale = {ri: G[ri - 1] for ri in range(1, len(decks) + 1) if near_box(G[ri - 1], box)}
    try:
        built = run(decks, box, stale)
    except IndexError:
        crashes.append((cx, cz)); continue
    for r in built:
        for end in (0, -1):
            p = r['pts'][end]; dy = p['y'] - r['y0'][end]
            if abs(dy) > 0.3 and not joint(r, p):
                hits.append((r['name'], 'start' if end == 0 else 'end', round(p['x'], 1), round(p['z'], 1),
                             round(r['y0'][end], 2), round(dy, 2), '%dx%d' % (p['x'] // 1536, p['z'] // 1536)))
# fixed builder: same run with no stale edges; no foot may move
assert all(abs(p['y'] - y0) <= 0.3 for decks in cells.values() for r in run(decks, None, None)
           for p, y0 in ((r['pts'][0], r['y0'][0]), (r['pts'][-1], r['y0'][-1])) if not joint(r, p)), 'a foot moves even without the bug'
for h in hits:
    print(*h)
print(len(hits), 'deck feet raised/lowered; 1536 cells:', sorted({h[-1] for h in hits}), '; build cells that would crash:', crashes)
