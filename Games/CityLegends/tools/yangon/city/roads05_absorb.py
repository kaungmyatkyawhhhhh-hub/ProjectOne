"""Doubled carriageways (17 Nov 2026, roads05 fix 3): two roads whose carriageways lie on each other along their length
(OSM's parallel one-ways a few metres apart whose lane widths overlap: Maha Bandula Road's two eastbound lines 6 m apart,
a third Pyay Road line beside the merged dual carriageway). YangonRoads builds both, so kerbs, pavements and a second
slab lie on the other road ("loose kerbs on the ring" at Sule roundabout, the QA's 'overlap').

The smaller road (higher rank) is absorbed where it runs alongside the bigger one: the bigger road widens on that side
to the smaller one's outer edge (eased over EASE samples), the alongside samples of the smaller road go, and what is left
of it (its own approach to a junction) stays as separate pieces ending on the widened road (mouths).

    used by roads05_fix.py: absorb(data) -> stats
"""
import math

import numpy as np
from shapely.geometry import LineString, Point
from shapely.ops import unary_union
from shapely.strtree import STRtree

import roadnet as RN
from roads05_qa import quads

PARALLEL = 0.9      # |cos| between the two directions
KEEP_IN = 2         # absorbed samples kept at each cut so the leftover piece still ends inside the bigger road
EASE = 8            # samples over which the bigger road's widening eases in / out
MIN_PIECE = 8       # a leftover shorter than this goes (3 samples by Sule's ring were all inside the ring's flat)
MIN_RUN = 6         # alongside runs shorter than this are a junction, not a doubled road
ALONG_SHARE = 0     # (J16) off: see absorb()
BESIDE_GAP = 3.0    # (J16) 1 m: a stretch this close beside the bigger road, between two absorbed stretches, goes too


def unit(x, z):
    L = math.hypot(x, z) or 1.0
    return x / L, z / L


def absorb(data, min_area=None):
    roads = data['roads']
    cut = {k: set(v) for k, v in data['cut'].items()}
    deck_of = set(d['of'] for d in data['decks'])
    side_of = set()
    for d in data['decks']:
        side_of.update(d.get('sides', ()))
    names = [r['name'] for r in roads]
    geoms = [unary_union(quads(r['s'], cut.get(r['name'], ()))) for r in roads]
    tree = STRtree(geoms)
    wid = [max(q[6] + q[7] for q in r['s']) for r in roads]
    pairs = []
    for a in range(len(roads)):
        for j in tree.query(geoms[a]):
            b = int(j)
            if b <= a:
                continue
            inter = geoms[a].intersection(geoms[b]).area
            small = min(geoms[a].area, geoms[b].area)
            # (the QA's 'overlap' rule; or a short one-way piece lying half on the other: Bahan Road #2 by the ring,
            # whose pulled-back mouth left jagged kerbs along the merge in the J7 Studio test)
            one = roads[a] if geoms[a].area <= geoms[b].area else roads[b]
            # (J16 tried pairing any road with a quarter of its area on another (ALONG_SHARE 0.25, QA kerb_cross lanes
            # along a road): kerb_cross 17 -> 23 (the cut lanes' pieces ended alongside the road): off)
            strong = inter > 2.5 * wid[a] * wid[b] + 500 or (one.get('oneway') and one['kind'] == 'route' and inter > 0.5 * small)
            if strong or (ALONG_SHARE and inter > ALONG_SHARE * small):
                pairs.append((inter, a, b, strong))
    pairs.sort(reverse=True)
    st = dict(pairs=len(pairs), absorbed=[], skipped=[])
    gone = set()
    out_extra = []
    newcut = {}
    for inter, a, b, strong in pairs:
        if a in gone or b in gone:
            continue
        # (J15) the bigger road by OSM class first, rank only between equals: "ends on" ranks can invert (Shwedagon
        # Pagoda Road, a primary, was absorbed INTO Lane #427, a service lane, J14)
        ka = (RN.RANK.get(roads[a].get('hw'), 9), roads[a]['rank'])
        kb = (RN.RANK.get(roads[b].get('hw'), 9), roads[b]['rank'])
        A, B = (roads[a], roads[b]) if ka < kb else (roads[b], roads[a])
        if B['name'] in side_of or B['kind'] == 'side' or A.get('closed') or B.get('closed') or A['name'] in side_of:
            st['skipped'].append([A['name'], B['name']])
            continue
        sa, sb = A['s'], B['s']
        LA = LineString([(q[0], q[2]) for q in sa])
        ca = np.r_[0, np.cumsum([math.hypot(sa[i + 1][0] - sa[i][0], sa[i + 1][2] - sa[i][2]) for i in range(len(sa) - 1)])]
        cutA = cut.get(A['name'], set())
        along = np.zeros(len(sb), bool)
        widen = {}  # A sample -> (side, half needed)
        near = {}   # (J16) B samples just beside A (edge gap < BESIDE_GAP): A sample, side, half needed, A's half
        for i, q in enumerate(sb):
            p = Point(q[0], q[2])
            t = LA.project(p)
            j = int(np.clip(np.searchsorted(ca, t), 0, len(sa) - 1))
            if j > 0 and abs(ca[j - 1] - t) < abs(ca[j] - t):
                j -= 1
            if j in cutA or t <= 0 or t >= LA.length:
                continue
            qa = sa[j]
            ta, tb = unit(qa[3], qa[4]), unit(q[3], q[4])
            if abs(ta[0] * tb[0] + ta[1] * tb[1]) < PARALLEL:
                continue
            rx, rz = -ta[1], ta[0]
            off = (q[0] - qa[0]) * rx + (q[2] - qa[2]) * rz  # B's centre right of A's
            hb = max(q[6], q[7])
            side = 1 if off > 0 else -1
            ha = qa[7] if side > 0 else qa[6]
            if abs(off) - hb >= ha - 0.5:
                if abs(off) - hb < ha + BESIDE_GAP:
                    near[i] = (j, side, abs(off) + hb, ha)
                continue  # beside, not on it
            along[i] = True
            need = abs(off) + hb
            # (J14, owner ref `road width jumps`) a service / track way alongside never widens the road (its strip
            # stays verge: the alongside part of the service way still goes)
            if B.get('hw') in ('service', 'track') or (A.get('hw') in ('service', 'track')) or not strong:
                continue  # (J16: a lane only partly along a road goes there, the road keeps its width: no width jump)
            if need > ha + 0.5 and need > widen.get(j, (side, 0.0))[1]:
                widen[j] = (side, need)
        # (J16, QA overlap: Bogyoke Aung San Road #2's middle ran 0-3 studs beside the road, its two ends on it: the
        # ends were absorbed, the widening eased onto the kept middle piece) a stretch of B just beside A between two
        # alongside stretches goes too (A widens over it as well)
        idx = np.flatnonzero(along)
        if len(idx):
            i = int(idx[0])
            while i < idx[-1]:
                if along[i]:
                    i += 1
                    continue
                j = i
                while not along[j]:
                    j += 1
                if all(k in near for k in range(i, j)):
                    for k in range(i, j):
                        along[k] = True
                        ja, side, need, ha = near[k]
                        if (strong and not (B.get('hw') in ('service', 'track') or A.get('hw') in ('service', 'track'))
                                and need > ha + 0.5 and need > widen.get(ja, (side, 0.0))[1]):
                            widen[ja] = (side, need)
                i = j
        # runs of alongside samples
        runs, i = [], 0
        while i < len(sb):
            if not along[i]:
                i += 1
                continue
            j = i
            while j + 1 < len(sb) and along[j + 1]:
                j += 1
            if j - i + 1 >= MIN_RUN:
                runs.append((i, j))
            i = j + 1
        if not runs:
            continue
        # B: keep what is not alongside (plus KEEP_IN samples into each run, so the piece ends on A)
        keep = np.ones(len(sb), bool)
        for i, j in runs:
            lo = i + (KEEP_IN if i > 0 else 0)
            hi = j - (KEEP_IN if j < len(sb) - 1 else 0)
            keep[lo:hi + 1] = False
        pieces, i = [], 0
        while i < len(sb):
            if not keep[i]:
                i += 1
                continue
            j = i
            while j + 1 < len(sb) and keep[j + 1]:
                j += 1
            if j - i + 1 >= MIN_PIECE and not along[i:j + 1].all():
                pieces.append((i, j))
            i = j + 1
        # B's decks / cut samples must fall inside one kept piece (they move with it)
        cb = cut.get(B['name'], set())
        home = {}
        ok = all(any(i <= c <= j for i, j in pieces) for c in cb)
        for dk in data['decks']:
            if dk['of'] == B['name']:
                h = [n for n, (i, j) in enumerate(pieces) if i <= dk['from'] and dk['to'] <= j]
                if not h:
                    ok = False
                else:
                    home[id(dk)] = h[0]
        if not ok:
            st['skipped'].append([A['name'], B['name'], 'deck / cut in the absorbed part'])
            continue
        # widen A (eased)
        for j, v in widen.items():
            side, need = v
            k = 7 if side > 0 else 6
            for d in range(-EASE, EASE + 1):
                jj = j + d
                if 0 <= jj < len(sa) and jj not in cutA:
                    u = 1 - abs(d) / (EASE + 1)
                    u = u * u * (3 - 2 * u)
                    tgt = sa[jj][k] + (need - sa[jj][k]) * u
                    if tgt > sa[jj][k]:
                        sa[jj][k] = round(tgt, 2)
        st['absorbed'].append(dict(into=A['name'], road=B['name'], samples=int((~keep).sum()), pieces=len(pieces)))
        gone.add(b if roads[b] is B else a)
        for n, (i, j) in enumerate(pieces):
            P = {k: v for k, v in B.items() if k not in ('s', 'startsOnEnd', 'endsOnEnd', 'edgeStart', 'edgeEnd')}
            P['s'] = [list(q) for q in sb[i:j + 1]]
            if i == 0:
                for f in ('startsOnEnd', 'edgeStart'):
                    if B.get(f):
                        P[f] = B[f]
            if j == len(sb) - 1:
                for f in ('endsOnEnd', 'edgeEnd'):
                    if B.get(f):
                        P[f] = B[f]
            P['name'] = B['name'] if n == 0 else '%s ~%d' % (B['name'], n + 1)
            P['rank'] = B['rank'] + n * 1e-3
            pc = sorted(c - i for c in cb if i <= c <= j)
            newcut[P['name']] = pc
            for dk in data['decks']:
                if dk['of'] == B['name'] and home.get(id(dk)) == n:
                    dk['from'] -= i
                    dk['to'] -= i
                    dk['moved_to'] = P['name']
            out_extra.append(P)
        cut.pop(B['name'], None)
        cut.update({k: set(v) for k, v in newcut.items() if v})
        newcut.clear()
    for dk in data['decks']:
        if 'moved_to' in dk:
            dk['of'] = dk.pop('moved_to')
    data['cut'] = {k: sorted(v) for k, v in cut.items() if v}
    if gone:
        data['roads'] = [r for k, r in enumerate(roads) if k not in gone] + out_extra
        alive = set(x['name'] for x in data['roads'])
        for r in data['roads']:  # flags naming a road that is gone point at nothing now
            for f in ('startsOnEnd', 'endsOnEnd'):
                if isinstance(r.get(f), str) and r[f] not in alive:
                    del r[f]
        from roads05_chain import rerank
        rerank(data)
    st['count'] = len(st['absorbed'])
    return st
