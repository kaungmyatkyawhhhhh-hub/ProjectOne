"""Road steps fix (24 Nov 2026, ROAD STEPS FIX agent; vault 'City Legends/2026-11-24 Road steps fix.md').

The data side of the built steps measured on 24 Nov (the code side is in Roads.luau relax, roads05.py smooth_chain /
BRIDGE_NEAR, roads05_fix.repin_crossers and roads05_bake.fit_boxes):
  * Ahlone Road #3: the road samples under its deck take the deck's heights (roads05_ahlone_fix; with the builder fixed
    the cut samples no longer hold the built start up, so this now gives a level foot);
  * Maha Bandula Road #2 by Sule: ring_level lowered it 3.8 where 31st Street crosses (31st Street left at the old
    height): roads05_fix.repin_crossers on the faded stretch;
  * the inverse-distance stair (every other sample +-8% grade) on Ziwaka, Shwe Gone Dine, Old Yay Ta Shay #2,
    Merchant, May Ni Gone Overpass and Maha Bandula #2: their free samples (not cut, not on another road's carriageway,
    not an end) smoothed with roads05.smooth_chain, only inside the rebuilt cells (fading to nothing over EDGE studs
    at the cells' edges, so the seams with cells built before stay level), then the roads on them re-pinned.

    python roads05_steps_fix.py <roads.json> ...     (idempotent)
    python roads05_steps_fix.py modules <subset dir>  (re-chunk roads.json into Roads05_<k>.luau)
    python roads05_steps_fix.py test
"""
import json, math, os, shutil, sys, tempfile

sys.path.insert(0, os.path.dirname(__file__))
import numpy as np

NOTE = 'steps fix 24nov'
ROADS = ['Ziwaka Road', 'Shwe Gone Dine Road', 'Old Yay Ta Shay Street #2', 'Merchant Road', 'May Ni Gone Overpass',
         'Maha Bandula Road #2']
RING, ARM = 'Roundabout 4', 'Maha Bandula Road #2'
# the cells rebuilt for this fix (1536 cells, x0 z0 x1 z1)
BOXES = [(26112, 38400, 27648, 39936),   # 17x25 Ahlone Road #3 deck foot (RB6)
         (27648, 33792, 29184, 35328),   # 18x22 May Ni Gone Overpass (RB6)
         (33792, 44544, 36864, 46080),   # 22x29 + 23x29 Merchant Road, Maha Bandula Road #2 (RB3)
         (32256, 38400, 35328, 39936),   # 21x25 + 22x25 Ziwaka Road (RB7)
         (33792, 36864, 35328, 38400),   # 22x24 Old Yay Ta Shay Street #2 (RB7)
         (35328, 32256, 36864, 33792)]   # 23x21 Shwe Gone Dine Road (RB8)
EDGE = 60.0
B = os.path.join(os.path.dirname(__file__), '..', '..', '..', 'build', 'city_1to1')


def weight(x, z):
    w = 0.0
    for x0, z0, x1, z1 in BOXES:
        d = min(x - x0, x1 - x, z - z0, z1 - z)
        w = max(w, min(1.0, max(0.0, d / EDGE)))
    return w


def on_other(d, r, i, segs):
    """is sample i of road r on another road's carriageway (a junction: its height is that road's business)?"""
    q = r['s'][i]
    for o, a in segs.get((int(q[0] // 64), int(q[2] // 64)), ()):
        if o is r:
            continue
        A, Bq = o['s'][a], o['s'][a + 1]
        vx, vz = Bq[0] - A[0], Bq[2] - A[2]
        L2 = vx * vx + vz * vz
        if L2 < 1e-9:
            continue
        u = min(1.0, max(0.0, ((q[0] - A[0]) * vx + (q[2] - A[2]) * vz) / L2))
        dd = math.hypot(A[0] + vx * u - q[0], A[2] + vz * u - q[2])
        if dd < max(A[6], A[7]) + max(q[6], q[7]) * 0.5 + 1 and abs(A[1] + (Bq[1] - A[1]) * u - q[1]) < 8:
            return True
    return False


def fix(path):
    import roads05_fix as F
    import roads05_ahlone_fix as AF
    from roads05 import smooth_chain
    d = json.load(open(path, encoding='utf-8'))
    if NOTE in d.get('note', ''):
        return 'already fixed'
    json.dump(d, open(path, 'w', encoding='utf-8'), separators=(',', ':'))
    ahl = AF.fix(path)
    d = json.load(open(path, encoding='utf-8'))
    R = {r['name']: r for r in d['roads']}
    cutd = {k: set(v) for k, v in d['cut'].items()}
    out = dict(ahlone=ahl)
    # Maha Bandula Road #2's faded stretch by Sule: the roads crossing it take its height
    g = next((g for g in d.get('roundabouts', []) if g['name'] == RING), None)
    if g and ARM in R:
        cx, cz = g['c'][0], g['c'][2]
        flat, reach = g['r_out'] + 4 + F.RING_FLAT, g['r_out'] + g.get('level', 344.0)
        s = R[ARM]['s']
        idx = {i for i, q in enumerate(s) if flat <= math.hypot(q[0] - cx, q[2] - cz) < reach}
        out['ring_repin'] = F.repin_crossers(d, {ARM: idx})
    # the stair: free samples smoothed inside the rebuilt cells
    segs = {}
    for o in d['roads']:
        cut = cutd.get(o['name'], set())
        for a in range(len(o['s']) - 1):
            if a in cut or a + 1 in cut:
                continue
            q = o['s'][a]
            segs.setdefault((int(q[0] // 64), int(q[2] // 64)), []).append((o, a))
    grid = {}
    for k, v in segs.items():
        for dx in (-1, 0, 1):
            for dz in (-1, 0, 1):
                grid.setdefault((k[0] + dx, k[1] + dz), []).extend(v)
    moved, worst = {}, 0.0
    for name in ROADS:
        if name not in R:
            continue
        r = R[name]
        s, cut = r['s'], cutd.get(name, set())
        n = len(s)
        c = np.concatenate([[0.0], np.cumsum([math.hypot(s[i][0] - s[i - 1][0], s[i][2] - s[i - 1][2]) for i in range(1, n)])])
        y = np.array([q[1] for q in s])
        sm = smooth_chain(y, c)
        ch = set()
        for i in range(n):
            if i in (0, n - 1) or i in cut or (i - 1) in cut or (i + 1) in cut or on_other(d, r, i, grid):
                continue
            w = weight(s[i][0], s[i][2])
            if w <= 0:
                continue
            ny = s[i][1] + w * (sm[i] - s[i][1])
            if abs(ny - s[i][1]) > 0.005:
                worst = max(worst, abs(ny - s[i][1]))
                s[i][1] = round(float(ny), 3)
                ch.add(i)
        moved[name] = ch
    out['smoothed'] = {k: len(v) for k, v in moved.items()}
    out['smooth_worst'] = round(worst, 3)
    out['smooth_repin'] = F.repin_crossers(d, moved)
    d['note'] = d.get('note', '') + ' | ' + NOTE
    json.dump(d, open(path, 'w', encoding='utf-8'), separators=(',', ':'))
    return out


def modules(D):
    txt = open(os.path.join(D, 'roads.json'), encoding='utf-8').read()
    for f in os.listdir(D):
        if f.startswith('Roads05_') and f.endswith('.luau'):
            os.remove(os.path.join(D, f))
    k = 0
    for a in range(0, len(txt), 185000):
        k += 1
        part = txt[a:a + 185000]
        assert ']==]' not in part
        open(os.path.join(D, 'Roads05_%d.luau' % k), 'w', encoding='utf-8').write('return [==[' + part + ']==]')
    return k


def alt_grade(s, i0, i1):
    """worst grade change between neighbouring sample pairs (the stair's signature)"""
    w = 0.0
    for i in range(max(1, i0), min(len(s) - 1, i1)):
        a, b, c = s[i - 1], s[i], s[i + 1]
        la, lb = math.hypot(b[0] - a[0], b[2] - a[2]), math.hypot(c[0] - b[0], c[2] - b[2])
        if la > 1 and lb > 1:
            w = max(w, abs((c[1] - b[1]) / lb - (b[1] - a[1]) / la))
    return w


def test():
    src = os.path.join(B, 'roads05_RB3o', 'roads.json')
    tmp = os.path.join(tempfile.mkdtemp(), 'roads.json')
    shutil.copy(src, tmp)
    before = {r['name']: r for r in json.load(open(src, encoding='utf-8'))['roads']}
    print(fix(tmp))
    assert fix(tmp) == 'already fixed'
    after = {r['name']: r for r in json.load(open(tmp, encoding='utf-8'))['roads']}
    for name in ('Merchant Road', 'Maha Bandula Road #2'):
        s0, s1 = before[name]['s'], after[name]['s']
        idx = [i for i, q in enumerate(s1) if weight(q[0], q[2]) >= 1]
        g0, g1 = alt_grade(s0, idx[0], idx[-1]), alt_grade(s1, idx[0], idx[-1])
        print('%s: worst grade change in the cells %.1f%% -> %.1f%%' % (name, g0 * 100, g1 * 100))
    # 31st Street now meets Maha Bandula Road #2 at its height
    mb, st = after['Maha Bandula Road #2']['s'], after['31st Street']['s']
    j = min(range(len(st)), key=lambda j: math.hypot(st[j][0] - 35655, st[j][2] - 45133))
    i = min(range(len(mb)), key=lambda i: math.hypot(mb[i][0] - st[j][0], mb[i][2] - st[j][2]))
    print('31st Street %.2f on Maha Bandula Road #2 %.2f' % (st[j][1], mb[i][1]))
    assert abs(st[j][1] - mb[i][1]) < 0.3
    print('ok')


if __name__ == '__main__':
    if sys.argv[1] == 'test':
        test()
    elif sys.argv[1] == 'modules':
        print('modules', modules(sys.argv[2]))
    else:
        for p in sys.argv[1:]:
            print(p, fix(p))
