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


ISLAND_MAX = 2500.0  # studs^2: a traffic island (real ones are paved concrete: Pyay x University Ave, satellite)


def islands(data):
    """(J9) Small traffic islands (a hole in the union of every carriageway and ring, under ISLAND_MAX) that the
    kerb + pavement bands round them do not cover were left unpaved (ground showed). Each such island goes to the
    builder as its kerb-line outline: [x, y, z, walk of the edge from this point to the next]; YangonRoads.buildIslands
    paves what is left inside the bands and the round corners (exactly, nothing on top of them)."""
    cutd = {k: set(v) for k, v in data['cut'].items()}
    polys, owner = [], []
    for r in data['roads']:
        g = unary_union(quads(r['s'], cutd.get(r['name'], ())))
        if not g.is_empty:
            polys.append(g)
            owner.append(r)
    for g in data['roundabouts']:
        rv = g['r_out'] / math.cos(math.pi / 96)
        polys.append(Polygon([(g['c'][0] + rv * math.cos(2 * math.pi * j / 96), g['c'][2] + rv * math.sin(2 * math.pi * j / 96)) for j in range(96)]))
        owner.append(g)
    allg = unary_union(polys)
    tree = STRtree(polys)
    out = []
    for poly in getattr(allg, 'geoms', [allg]):
        for ring in poly.interiors:
            H = Polygon(ring)
            if H.area >= ISLAND_MAX or H.area < 4:
                continue
            pts = list(Polygon(ring).simplify(0.15).exterior.coords)[:-1]
            if len(pts) < 3:
                continue
            rows, wmin = [], 99.0
            for k, (x, z) in enumerate(pts):
                x2, z2 = pts[(k + 1) % len(pts)]
                mid = Point((x + x2) / 2, (z + z2) / 2)
                best, bo = 1e9, None
                for i in tree.query(mid.buffer(1.0)):
                    d = polys[i].distance(mid)
                    if d < best:
                        best, bo = d, owner[i]
                if bo is None:
                    rows = None
                    break
                if 'r_out' in bo:
                    walk, y = RING_WALK, bo['c'][1]
                else:
                    s = bo['s']
                    j = min(range(len(s)), key=lambda j: (s[j][0] - mid.x) ** 2 + (s[j][2] - mid.y) ** 2)
                    q = s[j]
                    right = (-q[4]) * (mid.x - q[0]) + q[3] * (mid.y - q[2]) > 0
                    walk = (bo.get('walkR') if right else bo.get('walkL')) or RING_WALK
                    y = q[1]
                wmin = min(wmin, walk)
                rows.append([round(x, 2), round(y, 3), round(z, 2), walk])
            # only an island the bands leave open
            if rows and not H.buffer(-wmin - 0.3).is_empty:
                out.append(rows)
    data['islands'] = out
    return len(out)


def check(data):
    """what YangonRoads.load needs, or it errors (17 Nov: a 3-sample leftover by Sule's ring ran its arm loop off the
    road): unique names / ranks, decks and cuts inside their roads, every ring arm reaching past R_OUT + FLAT (12).
    A road that breaks the ring rule goes (logged)."""
    names = [r['name'] for r in data['roads']]
    assert len(set(names)) == len(names), 'two roads share a name'
    assert len(set(r['rank'] for r in data['roads'])) == len(names), 'two roads share a rank'
    by = {r['name']: r for r in data['roads']}
    for d in data['decks']:
        r = by[d['of']]
        assert 0 <= d['from'] < d['to'] < len(r['s']) and len(d['s']) == d['to'] - d['from'] + 1, d['name']
    for n, c in data['cut'].items():
        assert n in by and 0 <= min(c) and max(c) < len(by[n]['s']), n
    gone = []
    for r in data['roads']:
        for g in data['roundabouts']:
            rad = [math.hypot(q[0] - g['c'][0], q[2] - g['c'][2]) for q in r['s']]
            if min(rad[0], rad[-1]) < g['r_out'] and max(rad) < g['r_out'] + 12 + 1:
                gone.append(r['name'])
    if gone:
        decked = set(d['of'] for d in data['decks'])
        gone = [n for n in gone if n not in decked]
        data['roads'] = [r for r in data['roads'] if r['name'] not in gone]
        for n in gone:
            data['cut'].pop(n, None)
    return dict(ok=True, ring_stubs_dropped=gone, duplicates_dropped=drop_dups(data))


def drop_dups(data):
    """a road the builder would drop as lying wholly on a bigger one (mouthsim 'dropped') goes from the data, and the
    continuation flags naming it go too (the roads that carried on from it then get a mouth)"""
    import roads05_mouthsim
    dup = sorted(set(d['road'] for d in roads05_mouthsim.run(data)['dropped']) - set(d['of'] for d in data['decks']))
    if dup:
        data['roads'] = [r for r in data['roads'] if r['name'] not in dup]
        for n in dup:
            data['cut'].pop(n, None)
        for r in data['roads']:
            for f in ('startsOnEnd', 'endsOnEnd'):
                if r.get(f) in dup:
                    del r[f]
    return dup


RING_WALK, KERB_W = 7.5, 0.9  # YangonRoads 1:1 ring pavement / kerb


def ring_clear(data):
    """A road passing a roundabout without joining it (a slip like Lane #4701 by Roundabout 1, 2-3 m off the ring in
    OSM) had its kerb inside the ring's kerb / pavement band: the builder cut it piece by piece (a sawtooth). Its
    samples are pushed out radially until its inner kerb clears the ring's pavement (the shift tapers off at 15%
    a stud along the road), directions re-taken from the neighbours. Never a road with any sample inside r_out."""
    moved = []
    for r in data['roads']:
        s = r['s']
        if len(s) < 2 or r.get('closed'):
            continue
        for g in data['roundabouts']:
            if r['name'] in g.get('arms', ()):
                continue
            cx, cz, ro = g['c'][0], g['c'][2], g['r_out']
            rads = [math.hypot(q[0] - cx, q[2] - cz) for q in s]
            if min(rads) < ro or min(rads) > ro + 60:
                continue
            rv = ro / math.cos(math.pi / 96)
            push = []
            for q, rad in zip(s, rads):
                ux, uz = (cx - q[0]) / rad, (cz - q[2]) / rad  # towards the centre
                hin = q[7] if (-q[4]) * ux + q[3] * uz > 0 else q[6]  # right = (-dz, dx)
                push.append(max(0.0, rv + RING_WALK + KERB_W + 0.5 + hin - rad))
            if max(push) <= 0:
                continue
            # taper: along-road distance between samples
            along = [0.0]
            for a, b in zip(s, s[1:]):
                along.append(along[-1] + math.hypot(b[0] - a[0], b[2] - a[2]))
            disp = [max(p - abs(along[i] - along[j]) * 0.15 for j, p in enumerate(push)) for i in range(len(s))]
            if disp[0] > 0.01 or disp[-1] > 0.01:
                continue  # it would move a road end (a mouth): leave it to the mouth tools
            for q, rad, dd in zip(s, rads, disp):
                if dd > 0:
                    q[0] = round(q[0] + (q[0] - cx) / rad * dd, 2)
                    q[2] = round(q[2] + (q[2] - cz) / rad * dd, 2)
            for i in range(len(s)):
                if disp[i] > 0 or (i > 0 and disp[i - 1] > 0) or (i + 1 < len(s) and disp[i + 1] > 0):
                    a, b = s[max(i - 1, 0)], s[min(i + 1, len(s) - 1)]
                    L = math.hypot(b[0] - a[0], b[2] - a[2]) or 1
                    s[i][3], s[i][4] = round((b[0] - a[0]) / L, 4), round((b[2] - a[2]) / L, 4)
            moved.append(dict(road=r['name'], ring=g['name'], max_shift=round(max(disp), 2)))
    return moved


MORPH = 40.0


RING_RAMP = 100.0
RING_FLAT = 40.0  # (J12, Sule west: 32nd Street crosses Maha Bandula #2 30 studs off the ring at 1.3 over it; the
# builder's junction height left Maha Bandula 0.7 over the ring 4 studs from its edge: a crease (the "seam").
# Flat at c.y out to r_out + 4 + RING_FLAT, then the ramp)


def ring_level(data):
    """(J9, Sule) the ring is flat at c.y, but its arms reached it up to 4.8 studs higher or lower (the DEM round the
    pagoda): a step at the ring's edge. Every road sample within r_out + 4 + RING_RAMP of a ring eases to c.y: the
    gap to c.y scales by (rad - r_out - 4) / RING_RAMP (0 at the ring, whole at the ramp's end). Roads sharing a
    junction sample share its height before, so they still do. Raised samples (12+ over the ring: decks) stay."""
    out = []
    for g in data['roundabouts']:
        cx, cy, cz, ro = g['c'][0], g['c'][1], g['c'][2], g['r_out']
        worst = 0.0
        for r in data['roads']:
            for q in r['s']:
                rad = math.hypot(q[0] - cx, q[2] - cz)
                if rad >= ro + 4 + RING_FLAT + RING_RAMP or q[1] - cy > 12:
                    continue
                w = min(1.0, max(0.0, (rad - ro - 4 - RING_FLAT) / RING_RAMP))
                ny = round(cy + (q[1] - cy) * w, 3)
                worst = max(worst, abs(ny - q[1]))
                q[1] = ny
        if worst > 0.05:
            out.append(dict(ring=g['name'], max_change=round(worst, 2)))
    return out


def butt_match(data):
    """A continuation (startsOnEnd / endsOnEnd) narrower than, or off-centre from, its host's end left a strip of the
    host's end line with no slab on the far side (the Bogyoke x Pazundaung Y: Upper Pazundaung #3 is 63 wide, Lower
    Pazundaung 45 and 14 off-centre: grass in the gore). The continuation's first MORPH studs now start on the host's
    end cross-section exactly (centre and both edges) and taper back to its own. Only where one road continues that
    end (a real fork keeps both branches as they are)."""
    R = {r['name']: r for r in data['roads']}
    users = {}
    for r in data['roads']:
        for key, e in (('startsOnEnd', 0), ('endsOnEnd', -1)):
            h = R.get(r.get(key))
            if not h or len(r['s']) < 2:
                continue
            c = r['s'][e]
            he = min((0, -1), key=lambda k: math.hypot(h['s'][k][0] - c[0], h['s'][k][2] - c[2]))
            users.setdefault((h['name'], he), []).append((r, e))
    done = []
    for (hn, he), us in users.items():
        if len(us) != 1:
            continue
        r, e = us[0]
        hq = R[hn]['s'][he]
        rh = (-hq[4], hq[3])
        eL = (hq[0] - rh[0] * hq[6], hq[2] - rh[1] * hq[6])
        eR = (hq[0] + rh[0] * hq[7], hq[2] + rh[1] * hq[7])
        tc = ((eL[0] + eR[0]) / 2, (eL[1] + eR[1]) / 2)
        H = math.hypot(eL[0] - eR[0], eL[1] - eR[1]) / 2
        s = r['s'] if e == 0 else r['s'][::-1]
        c0 = s[0]
        rc = (-c0[4], c0[3])
        lat = (tc[0] - c0[0]) * rc[0] + (tc[1] - c0[2]) * rc[1]
        if abs(lat) < 1 and abs(H - c0[6]) < 1 and abs(H - c0[7]) < 1:
            continue
        # (only the same road going on: same one-way-ness, mostly on the host's end, at least half as wide; a one-way
        # carriageway leaving a two-way host is half of a split, not this)
        if bool(r.get('oneway')) != bool(R[hn].get('oneway')):
            continue
        lo, hi = max(-lat - c0[6], -H), min(-lat + c0[7], H)  # own span along its right vector, host centre = 0
        if hi - lo < 0.7 * (c0[6] + c0[7]) or (c0[6] + c0[7]) < H:
            continue
        cutn = set(data['cut'].get(r['name'], ())) | set(data['cut'].get(hn, ()))
        if cutn and (0 in cutn or len(r['s']) - 1 in cutn or 0 in set(data['cut'].get(hn, ())) or len(R[hn]['s']) - 1 in set(data['cut'].get(hn, ()))):
            continue
        if any(q[8] > 0 for q in s[:8]):
            continue  # (a median at the joint: leave it)
        along = 0.0
        for i, q in enumerate(s):
            if i:
                along += math.hypot(q[0] - s[i - 1][0], q[2] - s[i - 1][2])
            t = 1 - along / MORPH
            if t <= 0:
                break
            q[0] = round(q[0] + rc[0] * lat * t, 2)
            q[2] = round(q[2] + rc[1] * lat * t, 2)
            q[6] = round(q[6] + (H - q[6]) * t, 2)
            q[7] = round(q[7] + (H - q[7]) * t, 2)
        done.append(dict(road=r['name'], host=hn, lateral=round(lat, 1), half=round(H, 1)))
    return done


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
    import roads05_absorb
    chained['absorb'] = roads05_absorb.absorb(data)
    chained['duplicates_dropped'] = drop_dups(data)
    chained['ring_clear'] = ring_clear(data)
    chained['ring_level'] = ring_level(data)
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
    # 1b. what the builder's edge walk still fails (mouthsim): smallest edit that passes
    import roads05_repair
    st['repair'] = roads05_repair.repair(data)
    print('repair', json.dumps(dict(st['repair'], fixed=len(st['repair']['fixed']), repair_left=len(st['repair']['repair_left']))))
    st['butt_match'] = butt_match(data)  # (after repair: it flags the last continuations)
    roads = data['roads']
    names = [r['name'] for r in roads]
    cutd = {k: set(v) for k, v in data['cut'].items()}
    geoms = [unary_union(quads(r['s'], cutd.get(r['name'], ()))) for r in roads]
    tree = STRtree(geoms)
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
    st['islands'] = islands(data)
    print('islands', st['islands'])
    st['checks'] = check(data)
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
