"""Chain roads that meet end to end at one node into one road (17 Nov 2026, roads05 fix 2).

YangonRoads makes a mouth for a road that ends on a bigger road, and its edge walk only knows ONE road's edge: where the
bigger road itself ends at that node (an L corner, or a T whose through road is two pieces), the walk never meets it
and the builder fails ("an edge of X never meets Y"; 1,543 of 1,621 predicted failures). OSM-wise a node where two
ways meet is a continuation, so the pieces become one road:
  * two ends alone at a node (nothing else there): joined at any angle short of a hairpin (<= 150 deg turn)
  * three or more: the straightest pair, if it turns <= 135 deg (the other roads then end on the joined one)
  * same kind only (route / street / side never mixed), one-way only with one-way in travel order, never a ring arm,
    a map-edge end, a side lane's start / end or a cut (deck) end
The corner sample gets the bisector direction and a mitred width. Ranks are re-sorted after (old rank as the key,
"X ends inside Y" puts Y first), the cut lists, deck refs, ring arms and side-lane labels follow the new names.

    python roads05_chain.py <data in> <data out>        (used by roads05_fix.py)
"""
import collections, heapq, json, math, sys

from roads05_mouthsim import Net

NODE = 8.0          # ends this close are one node (OSM corners whose two ways stop a few studs apart)
TURN_ALONE = 150.0  # degree-2 node: join unless it turns back more than this
TURN_SHARP = 100.0  # (J35) a turn sharper than this is not chained when another road's end lies within NEAR_END of the node
NEAR_END = 15.0     # (Lane #544: Dhobi Street 3 #2 chained through a 140 deg U-turn, OSM's short link to Lane #544 never existed)
TURN_MANY = 135.0   # 3+ ends: the straightest pair if it turns no more than this (a Y fork too: the third road then ends on a bend, which the edge walk meets)
MITRE_MAX = 1.6


def unit(x, z):
    L = math.hypot(x, z) or 1.0
    return x / L, z / L


def out_dir(s, k):
    q = s[k]
    dx, dz = unit(q[3], q[4])
    return (-dx, -dz) if k == 0 else (dx, dz)


def reverse(r):
    s = []
    for q in reversed(r['s']):
        q = list(q)
        q[3], q[4] = -q[3], -q[4]
        q[6], q[7] = q[7], q[6]
        s.append(q)
    r['s'] = s
    r['walkL'], r['walkR'] = r.get('walkR'), r.get('walkL')
    r['edgeStart'], r['edgeEnd'] = r.get('edgeEnd'), r.get('edgeStart')
    r['startsOnEnd'], r['endsOnEnd'] = r.get('endsOnEnd'), r.get('startsOnEnd')
    for k in [k for k, v in r.items() if v is None]:
        del r[k]


def chain(data):
    roads = data['roads']
    n = len(roads)
    cut = {k: set(v) for k, v in data['cut'].items()}
    rings = [(g['c'][0], g['c'][2], g['r_out']) for g in data['roundabouts']]
    deck_of = collections.defaultdict(list)
    for d in data['decks']:
        deck_of[d['of']].append(d)
    # ends that may join
    ends = []
    for ri, r in enumerate(roads):
        s = r['s']
        if r.get('closed') or len(s) < 2:
            continue
        for k, flag in ((0, 'Start'), (-1, 'End')):
            if r.get('edge' + flag) or r.get(('starts' if k == 0 else 'ends') + 'OnEnd'):
                continue
            i = 0 if k == 0 else len(s) - 1
            if i in cut.get(r['name'], ()):
                continue
            q = s[k]
            if any(math.hypot(q[0] - cx, q[2] - cz) < ro + 30 for cx, cz, ro in rings):
                continue
            ends.append((ri, k, q[0], q[2]))
    # nodes
    from scipy.spatial import cKDTree
    T = cKDTree([(e[2], e[3]) for e in ends])
    parent = list(range(len(ends)))

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a
    for a, b in T.query_pairs(NODE):
        parent[find(a)] = find(b)
    nodes = collections.defaultdict(list)
    for i in range(len(ends)):
        nodes[find(i)].append(i)
    # a node that lies on a third road's carriageway is a junction on that road, not a plain node
    net = Net(data)
    link = {}
    skipped = collections.Counter()
    for members in nodes.values():
        if len(members) < 2:
            continue
        x = sum(ends[i][2] for i in members) / len(members)
        z = sum(ends[i][3] for i in members) / len(members)
        mine = set(ends[i][0] for i in members)
        onother = any(oi not in mine and net.poly_dist(oi, b[1], x, z) < net.half_at(oi, b[1]) for oi, b in net.near(x, z, 2).items())
        near_end = any(j not in members for j in T.query_ball_point((x, z), NEAR_END))
        cand = []
        for a in members:
            for b in members:
                if a >= b:
                    continue
                ra, ka = ends[a][0], ends[a][1]
                rb, kb = ends[b][0], ends[b][1]
                if ra == rb:
                    continue
                A, B = roads[ra], roads[rb]
                if A['kind'] != B['kind'] or A['kind'] == 'side':
                    skipped['kind'] += 1
                    continue
                if bool(A.get('oneway')) != bool(B.get('oneway')):
                    skipped['oneway_mix'] += 1
                    continue
                if A.get('oneway') and ka == kb:
                    skipped['oneway_against'] += 1
                    continue
                da, db = out_dir(A['s'], ka), out_dir(B['s'], kb)
                turn = math.degrees(math.acos(max(-1.0, min(1.0, -(da[0] * db[0] + da[1] * db[1])))))
                if turn > TURN_SHARP and near_end:
                    skipped['sharp_near_end'] += 1
                    continue
                cand.append((turn, min(A['rank'], B['rank']), a, b))
        if not cand:
            continue
        cand.sort()
        lim = TURN_ALONE if len(members) == 2 and not onother else TURN_MANY
        used = set()
        for turn, _, a, b in cand:
            if turn > lim or a in used or b in used:
                continue
            link[a] = b
            link[b] = a
            used.update((a, b))
            if len(members) > 2 or onother:
                break  # one pair through a junction; the rest end on it
    # chains (end index i = ends[] entry; per road its two entries)
    endid = {(e[0], e[1]): i for i, e in enumerate(ends)}

    def other_end(ri, k):
        return endid.get((ri, -1 if k == 0 else 0))
    seen = set()
    groups = []
    for ri in range(n):
        if ri in seen:
            continue
        # walk back to a chain start
        cur, k_in = ri, 0  # entering cur at its start
        guard = 0
        while True:
            e = endid.get((cur, k_in))
            if e is None or e not in link or guard > n:
                break
            pr, pk = ends[link[e]][0], ends[link[e]][1]
            if pr == ri:
                break  # a ring of pieces: start anywhere
            cur, k_in = pr, (-1 if pk == 0 else 0)
            guard += 1
        g = []
        while cur not in seen:
            seen.add(cur)
            g.append((cur, k_in != 0))  # reversed if entered at its end
            e = endid.get((cur, -1 if k_in == 0 else 0))
            if e is None or e not in link:
                break
            nr, nk = ends[link[e]][0], ends[link[e]][1]
            cur, k_in = nr, nk
        groups.append(g)
    # merge
    rename = {}
    out = []
    joins = 0
    for g in groups:
        if len(g) == 1:
            out.append(roads[g[0][0]])
            continue
        head = min((roads[ri] for ri, _ in g), key=lambda r: r['rank'])
        name = head['name']
        S, newcut, decks = [], set(), []
        rec = None
        for ri, rev in g:
            r = roads[ri]
            nm = r['name']
            rcut = cut.pop(nm, set())
            ns = len(r['s'])
            if rev:
                reverse(r)
                rcut = set(ns - 1 - i for i in rcut)
                for d in deck_of.get(nm, ()):
                    d['from'], d['to'] = ns - 1 - d['to'], ns - 1 - d['from']
                    d['s'] = d['s'][::-1]
                    for q in d['s']:
                        if len(q) > 4:
                            q[3], q[4] = -q[3], -q[4]
                        if len(q) > 7:
                            q[6], q[7] = q[7], q[6]
            s = r['s']
            off = len(S)
            if S and math.hypot(S[-1][0] - s[0][0], S[-1][2] - s[0][2]) < 0.5:
                a, b = S[-1], s[0]
                ta, tb = unit(a[3], a[4]), unit(b[3], b[4])
                bx, bz = unit(ta[0] + tb[0], ta[1] + tb[1])
                c = max(1.0 / MITRE_MAX, bx * ta[0] + bz * ta[1])
                m = list(b)
                m[1] = round((a[1] + b[1]) / 2, 2)
                m[3], m[4] = round(bx, 4), round(bz, 4)
                m[6] = round(max(a[6], b[6]) / c, 2)
                m[7] = round(max(a[7], b[7]) / c, 2)
                S[-1] = m
                s = s[1:]
                off -= 1
            newcut.update(i + off for i in rcut)
            for d in deck_of.get(nm, ()):
                d['from'] += off
                d['to'] += off
                d['of'] = name
            S.extend(s)
            if nm != name:
                rename[nm] = name
            if rec is None:
                rec = r
            else:
                joins += 1
            rec['half'] = min(rec['half'], r['half'])
            for f in ('lanes', 'median'):
                if f in r:
                    rec[f] = max(rec.get(f, 0), r[f])
        # the head road's own fields, the chain's ends' flags
        first, last = roads[g[0][0]], roads[g[-1][0]]
        new = {k: v for k, v in head.items() if k not in ('s', 'edgeStart', 'edgeEnd', 'startsOnEnd', 'endsOnEnd')}
        new.update(half=rec['half'], s=S, lanes=rec.get('lanes', head.get('lanes')), median=rec.get('median', head.get('median')))
        if head is not first and head is not last:
            pass
        for k in ('walkL', 'walkR'):
            vals = [roads[ri].get(k) for ri, _ in g if roads[ri].get(k)]
            if vals:
                new[k] = max(vals)
        for src, f in ((first, 'edgeStart'), (first, 'startsOnEnd'), (last, 'edgeEnd'), (last, 'endsOnEnd')):
            if src.get(f):
                new[f] = src[f]
        if newcut:
            cut[name] = newcut
        out.append(new)
    # names elsewhere
    for r in out:
        for f in ('startsOnEnd', 'endsOnEnd'):
            if isinstance(r.get(f), str) and r[f] in rename:
                r[f] = rename[r[f]]
    for g in data['roundabouts']:
        if 'arms' in g:
            g['arms'] = sorted(set(rename.get(a, a) for a in g['arms']))
    data['roads'] = out
    data['cut'] = {k: sorted(v) for k, v in cut.items() if v}
    rerank(data)
    return dict(joins=joins, chains=sum(1 for g in groups if len(g) > 1), roads_before=n, roads_after=len(out), skipped=dict(skipped))


def butt(data, cut, A, ka, B, kb, st):
    """A's end ka trimmed / run on to B's end line kb (a butt joint, no overlap, no gap); False if it cannot"""
    qb = B['s'][kb]
    ub = out_dir(B['s'], kb)  # out of B, into A
    s = A['s']
    n0 = len(s)
    ca = cut.get(A['name'], set())
    # drop A's samples behind B's end line (on B)
    idx = list(range(n0)) if ka == 0 else list(range(n0 - 1, -1, -1))
    drop = 0
    for i in idx:
        q = s[i]
        if (q[0] - qb[0]) * ub[0] + (q[2] - qb[2]) * ub[1] < 0.5 and i not in ca:
            drop += 1
        else:
            break
    if n0 - drop < 3:
        st['too_short'] += 1
        return False
    keep = s[drop:] if ka == 0 else s[:n0 - drop]
    q = keep[0] if ka == 0 else keep[-1]
    d = out_dir(keep, 0 if ka == 0 else -1)  # towards B
    den = d[0] * ub[0] + d[1] * ub[1]
    if den > -0.3:
        st['slant'] += 1
        return False
    t = ((qb[0] - q[0]) * ub[0] + (qb[2] - q[2]) * ub[1]) / den
    m = list(q)
    m[0] = round(q[0] + d[0] * t, 2)
    m[2] = round(q[2] + d[1] * t, 2)
    m[1] = qb[1]
    # the end's cross-section along B's end cross-section (B's travel direction, signed like A's)
    tb = unit(qb[3], qb[4])
    sg = 1 if tb[0] * q[3] + tb[1] * q[4] >= 0 else -1
    m[3], m[4] = round(tb[0] * sg, 4), round(tb[1] * sg, 4)
    if math.hypot(m[0] - q[0], m[2] - q[2]) < 1.0:
        keep[0 if ka == 0 else -1] = m
    elif ka == 0:
        keep.insert(0, m)
    else:
        keep.append(m)
    shift = len(keep) - n0 if ka == 0 else 0  # index change at the start
    A['s'] = keep
    if A['name'] in cut:
        cut[A['name']] = set(i + shift for i in cut[A['name']] if 0 <= i + shift < len(keep))
    for dk in data['decks']:
        if dk['of'] == A['name']:
            dk['from'] += shift
            dk['to'] += shift
    st['trimmed_samples'] += drop
    return True


def continuations(data, reach=40.0, opposed=-0.7):  # (reach 12 -> 40: May Ni Gone Overpass started 30 short of Pyay Road's end)
    """an end that carries straight on from another road's END (a dual carriageway splitting into two one-ways, a
    one-way piece on a two-way one): both ends get startsOnEnd / endsOnEnd (YangonRoads makes no mouth there) and the
    carrying-on road is trimmed to start exactly on the other's end cross-section, along its direction (a butt joint,
    no overlap, no gap)"""
    roads = data['roads']
    cut = {k: set(v) for k, v in data['cut'].items()}
    by = {r['name']: r for r in roads}
    E = []
    for ri, r in enumerate(roads):
        if r.get('closed') or len(r['s']) < 2:
            continue
        for k in (0, -1):
            E.append((ri, k))
    from scipy.spatial import cKDTree
    T = cKDTree([(roads[ri]['s'][k][0], roads[ri]['s'][k][2]) for ri, k in E])
    flag = lambda k: 'startsOnEnd' if k == 0 else 'endsOnEnd'
    pairs = []
    for a, (ra, ka) in enumerate(E):
        A = roads[ra]
        qa = A['s'][ka]
        da = out_dir(A['s'], ka)
        for b in T.query_ball_point((qa[0], qa[2]), 60):
            rb, kb = E[b]
            if rb == ra:
                continue
            B = roads[rb]
            qb = B['s'][kb]
            hb = max(qb[6], qb[7])
            dist = math.hypot(qa[0] - qb[0], qa[2] - qb[2])
            if dist > hb + reach + 40:
                continue
            db = out_dir(B['s'], kb)
            if da[0] * db[0] + da[1] * db[1] > opposed:
                continue
            # A's end within B's end cross-section (across) and near its line (along)
            ub = db
            along = (qa[0] - qb[0]) * ub[0] + (qa[2] - qb[2]) * ub[1]
            across = abs((qa[0] - qb[0]) * ub[1] - (qa[2] - qb[2]) * ub[0])
            if across > hb + 1 or not -40 <= along <= reach:  # (it may start up to 40 back on the host)
                continue
            pairs.append((dist, a, b))
    pairs.sort()
    used = set()
    st = collections.Counter()
    for dist, a, b in pairs:
        ra, ka = E[a]
        rb, kb = E[b]
        A, B = roads[ra], roads[rb]
        # the smaller road (higher rank) is the one trimmed onto the other's end line; one host end can carry
        # several (a two-way road splitting into two one-ways)
        if A['rank'] < B['rank'] or A['kind'] == 'side':
            a, b, ra, ka, rb, kb, A, B = b, a, rb, kb, ra, ka, B, A
        if a in used or A.get(flag(ka)):
            continue
        if not butt(data, cut, A, ka, B, kb, st):
            continue
        A[flag(ka)] = B['name']
        B.setdefault(flag(kb), A['name'])
        used.update((a, b))
        st['joined'] += 1
    data['cut'] = {k: sorted(v) for k, v in cut.items() if v}
    return dict(st)


def rerank(data):
    """unique ranks again: old rank as the key, a road that ends inside another comes after it"""
    roads = data['roads']
    net = Net(data)
    n = len(roads)
    succ = collections.defaultdict(set)
    indeg = [0] * n
    for xi, r in enumerate(roads):
        if r['kind'] == 'side':
            continue
        s = r['s']
        for k in (0, -1):
            q = s[k]
            for oi, (d, bi) in net.near(q[0], q[2], 2).items():
                if oi == xi:
                    continue
                o = roads[oi]['s']
                if min(math.hypot(o[e][0] - q[0], o[e][2] - q[2]) for e in (0, -1)) < 2:
                    continue
                if net.poly_dist(oi, bi, q[0], q[2]) < net.half_at(oi, bi) and xi not in succ[oi]:
                    succ[oi].add(xi)
                    indeg[xi] += 1
    key = [r['rank'] for r in roads]
    heap = [(key[i], i) for i in range(n) if indeg[i] == 0]
    heapq.heapify(heap)
    done = [False] * n
    order = []
    broken = 0
    while len(order) < n:
        if not heap:
            i = min((i for i in range(n) if not done[i]), key=lambda i: key[i])
            heapq.heappush(heap, (key[i], i))
            broken += 1
        _, i = heapq.heappop(heap)
        if done[i]:
            continue
        done[i] = True
        order.append(i)
        for x in succ[i]:
            indeg[x] -= 1
            if indeg[x] == 0 and not done[x]:
                heapq.heappush(heap, (key[x], x))
    for rk, i in enumerate(order):
        roads[i]['rank'] = rk
    data['rank_cycles_broken'] = broken


def main():
    data = json.load(open(sys.argv[1], encoding='utf-8'))
    st = chain(data)
    json.dump(data, open(sys.argv[2], 'w', encoding='utf-8'), separators=(',', ':'))
    print(json.dumps(st))


if __name__ == '__main__':
    main()
