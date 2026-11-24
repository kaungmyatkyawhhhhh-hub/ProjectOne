"""Rank fix (24 Nov 2026, ROAD JOINS FIX agent; vault 'City Legends/2026-11-24 Road joins fix.md').

Maha Bandula Road #2 (primary) ranked 2378, behind ~25 residential streets that cross it (31st Street 2097 ...): the
builder pins the smaller road to the bigger one, so the main road was held level across each of those streets (the
crest at 31st Street by Sule). A fresh roads05.py gives it 24; roads05_chain.rerank (run by roads05_fix) pushed it
behind a stub its end lies in (fixed there for re-runs: continuations and bigger-class enders are not "ends inside").
This moves the road's rank in the existing data:

  * it goes just after the roads that must stay above it: roads it ends inside, bigger-class roads it touches, and
    every road it touches OUTSIDE `BOX` (the cells rebuilt now; the cells outside keep what they were built with);
  * every other road it touches (the side streets in BOX) then ranks below it and meets its surface.

    python roads05_rank_fix.py <roads.json> ...     (idempotent)
    python roads05_rank_fix.py test
"""
import json, math, os, shutil, sys, tempfile

sys.path.insert(0, os.path.dirname(__file__))
import numpy as np

NOTE = 'rank fix 24nov'
ROAD = 'Maha Bandula Road #2'
BOX = (33792, 44544, 36864, 46080)  # 22x29 + 23x29, rebuilt with this fix
CLASS = {'motorway': 0, 'trunk': 0, 'primary': 1, 'secondary': 2, 'tertiary': 3, 'motorway_link': 4, 'trunk_link': 4,
         'primary_link': 4, 'secondary_link': 4, 'tertiary_link': 5, 'unclassified': 6, 'residential': 6, 'road': 6,
         'living_street': 7, 'service': 8, 'track': 8}  # = roadnet.RANK
B = os.path.join(os.path.dirname(__file__), '..', '..', '..', 'build', 'city_1to1')


def xz(r):
    return np.array([[q[0], q[2]] for q in r['s']])


def touches(d, m):
    """roads whose carriageway overlaps m's: [(road, m sample indices touched, m ends inside it)]"""
    M = xz(m)
    lo, hi = M.min(0) - 80, M.max(0) + 80
    out = []
    for o in d['roads']:
        if o is m:
            continue
        O = xz(o)
        if (O.max(0) < lo).any() or (O.min(0) > hi).any():
            continue
        D = np.linalg.norm(O[:, None, :] - M[None, :, :], axis=2)
        hit = np.argwhere(D < (m['half'] + o['half']) * 0.8)
        if len(hit) == 0:
            continue
        mi = sorted(set(int(i) for i in hit[:, 1]))
        # m ends inside o: one of m's end samples within o's half of o's centre line, away from o's own ends
        ends_in = False
        for k in (0, len(M) - 1):
            dd = np.linalg.norm(O - M[k], axis=1)
            j = int(np.argmin(dd))
            if dd[j] < o['half'] and 0 < j < len(O) - 1:
                ends_in = True
        out.append((o, mi, ends_in))
    return out


def in_box(q):
    return BOX[0] <= q[0] < BOX[2] and BOX[1] <= q[2] < BOX[3]


def fix(path):
    d = json.load(open(path, encoding='utf-8'))
    if NOTE in d.get('note', ''):
        return 'already fixed'
    m = next(r for r in d['roads'] if r['name'] == ROAD)
    old = m['rank']
    held, freed = [], []
    for o, mi, ends_in in touches(d, m):
        if o['rank'] > old:
            continue
        outside = any(not in_box(m['s'][i]) for i in mi)
        bigger = CLASS.get(o['hw'], 6) < CLASS.get(m['hw'], 6)
        (held if (ends_in or bigger or outside) else freed).append(o)
    new = max(o['rank'] for o in held) + 0.5
    ranks = {r['rank'] for r in d['roads']}
    while new in ranks:
        new = round(new + 0.01, 4)
    freed = [o for o in freed if o['rank'] > new]
    m['rank'] = new
    d['note'] = d.get('note', '') + ' | ' + NOTE
    json.dump(d, open(path, 'w', encoding='utf-8'), separators=(',', ':'))
    return dict(road=ROAD, rank=(old, new), now_below=sorted((o['rank'], o['name']) for o in freed))


def test():
    src = os.path.join(B, 'roads05_RB3s', 'roads.json')
    tmp = os.path.join(tempfile.mkdtemp(), 'roads.json')
    shutil.copy(src, tmp)
    res = fix(tmp)
    print(res)
    assert fix(tmp) == 'already fixed'
    d = json.load(open(tmp, encoding='utf-8'))
    R = {r['name']: r for r in d['roads']}
    m = R[ROAD]
    assert R['31st Street']['rank'] > m['rank'], '31st Street must rank below Maha Bandula Road #2 now'
    ranks = [r['rank'] for r in d['roads']]
    assert len(set(ranks)) == len(ranks), 'ranks must stay unique'
    # nothing the road ends inside, no bigger road and nothing touched outside BOX changed sides
    for o, mi, ends_in in touches(d, m):
        if ends_in or any(not in_box(m['s'][i]) for i in mi):
            before = json.load(open(src, encoding='utf-8'))
            ob = next(r for r in before['roads'] if r['name'] == o['name'])['rank']
            assert (ob < 2378) == (o['rank'] < m['rank']), o['name']
    # the shared-code fix: roads05_chain.rerank keeps a main road at its key (a fresh roads05.py run gives it 24;
    # before the guards its end inside the "Maha Bandula Road" stub pushed it to 582 in this subset)
    import roads05_chain
    d = json.load(open(src, encoding='utf-8'))
    R = {r['name']: r for r in d['roads']}
    R[ROAD]['rank'] = 23.5
    roads05_chain.rerank(d)
    print('rerank from the generator key:', R[ROAD]['rank'], '31st Street', R['31st Street']['rank'])
    assert R[ROAD]['rank'] < 50 and R[ROAD]['rank'] < R['31st Street']['rank']
    print('ok')


if __name__ == '__main__':
    if sys.argv[1] == 'test':
        test()
    else:
        for p in sys.argv[1:]:
            print(p, fix(p))
