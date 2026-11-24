"""Merge fix (24 Nov 2026, ROAD JOINS FIX agent; vault 'City Legends/2026-11-24 Road joins fix.md').

Merchant Road runs into Strand Road at a shallow angle: for ~100 studs before its end its carriageway lies on Strand's.
Its data heights there were 1-1.7 over Strand's surface; the builder (Roads.luau alignJunctions: samples within
HALF + 6 of a bigger road's side sit on that road) pulled the built road down onto Strand and faded the change out
behind, so the built surface dipped ~1 stud under the data and stepped 0.8 where the centre line met Strand's edge.

Here the merging road's samples within the builder's reach (the bigger road's side + 6) take the bigger road's height
(its surface is level across, so the foot of the sample on its centre line), and the samples behind ease back to their
own heights over FADE studs. The builder then has nothing to pull.

    python roads05_merge_fix.py <roads.json> ...     (idempotent)
    python roads05_merge_fix.py test
"""
import json, math, os, shutil, sys, tempfile

NOTE = 'merge fix 24nov'
MERGES = [('Merchant Road', 'Strand Road')]   # (the merging road, the bigger road it runs into)
REACH = 6.0     # Roads.luau alignJunctions: otherNear(pos, HALF + 6) with the bigger road's own side past HALF
FADE = 120.0
B = os.path.join(os.path.dirname(__file__), '..', '..', '..', 'build', 'city_1to1')


def foot(big, x, z):
    """(distance, height, side half) of (x, z) on big's centre line"""
    s = big['s']
    best = None
    for a in range(len(s) - 1):
        A, C = s[a], s[a + 1]
        if abs(A[0] - x) > 120 or abs(A[2] - z) > 120:
            continue
        vx, vz = C[0] - A[0], C[2] - A[2]
        L2 = vx * vx + vz * vz
        if L2 < 1e-9:
            continue
        u = min(1.0, max(0.0, ((x - A[0]) * vx + (z - A[2]) * vz) / L2))
        d = math.hypot(A[0] + vx * u - x, A[2] + vz * u - z)
        right = (x - A[0]) * -vz + (z - A[2]) * vx > 0
        if best is None or d < best[0]:
            best = (d, A[1] + (C[1] - A[1]) * u, A[7] if right else A[6])
    return best


def fix(path):
    d = json.load(open(path, encoding='utf-8'))
    if NOTE in d.get('note', ''):
        return 'already fixed'
    R = {r['name']: r for r in d['roads']}
    cutd = {k: set(v) for k, v in d['cut'].items()}
    out, moved = {}, {}
    for name, big in MERGES:
        if name not in R or big not in R:
            continue
        s, cut = R[name]['s'], cutd.get(name, set())
        # which end runs into big
        e = min((0, len(s) - 1), key=lambda k: (foot(R[big], s[k][0], s[k][2]) or (1e9,))[0])
        idx = list(range(len(s))) if e == 0 else list(range(len(s) - 1, -1, -1))
        pinned, worst = [], 0.0
        last = None
        for i in idx:
            f = foot(R[big], s[i][0], s[i][2])
            if f is None or f[0] >= f[2] + REACH or i in cut:
                break
            worst = max(worst, abs(s[i][1] - f[1]))
            s[i][1] = round(f[1], 3)
            pinned.append(i)
            last = i
        # behind the pinned run: blend from the road's own height to big's surface (at each sample's foot) over FADE
        # studs: two smooth profiles blended stay smooth (a grade-capped ease made a 0.6 V before the merge)
        eased = 0
        if last is not None:
            k = idx.index(last)
            run = 0.0
            for a, b in zip(idx[k:], idx[k + 1:]):
                run += math.hypot(s[b][0] - s[a][0], s[b][2] - s[a][2])
                f = foot(R[big], s[b][0], s[b][2])
                if run >= FADE or b in cut or f is None:
                    break
                w = 1 - run / FADE
                s[b][1] = round(s[b][1] + w * (f[1] - s[b][1]), 3)
                eased += 1
        out[name] = dict(pinned=len(pinned), eased=eased, worst_move=round(worst, 2))
        moved[name] = set(pinned) | set(idx[idx.index(last) + 1:idx.index(last) + 1 + eased] if last is not None else [])
    # roads meeting the moved stretch (24th Street, 23rd Street) take its new height there (roads05_fix.repin_crossers)
    import roads05_fix as F
    out['repinned'] = F.repin_crossers(d, moved)
    d['note'] = d.get('note', '') + ' | ' + NOTE
    json.dump(d, open(path, 'w', encoding='utf-8'), separators=(',', ':'))
    return out


def test():
    src = os.path.join(B, 'roads05_RB3r', 'roads.json')
    tmp = os.path.join(tempfile.mkdtemp(), 'roads.json')
    d0 = json.load(open(src, encoding='utf-8'))
    d0['note'] = d0['note'].replace(' | ' + NOTE, '')
    json.dump(d0, open(tmp, 'w', encoding='utf-8'))
    res = fix(tmp)
    print(res)
    assert fix(tmp) == 'already fixed'
    d = json.load(open(tmp, encoding='utf-8'))
    R = {r['name']: r for r in d['roads']}
    for name, big in MERGES:
        s = R[name]['s']
        for i, q in enumerate(s):
            f = foot(R[big], q[0], q[2])
            if f and f[0] < f[2] + REACH:
                assert abs(q[1] - f[1]) < 0.01, (name, i, q[1], f[1])
        gr = [(s[i + 1][1] - s[i][1]) / max(1e-6, math.hypot(s[i + 1][0] - s[i][0], s[i + 1][2] - s[i][2]))
              for i in range(len(s) - 45, len(s) - 1)]
        g = max(abs(b - a) for a, b in zip(gr, gr[1:]))
        print('%s: worst grade change over the merge and its fade %.1f%%' % (name, g * 100))
        assert g < 0.02
    print('ok')


if __name__ == '__main__':
    if sys.argv[1] == 'test':
        test()
    else:
        for p in sys.argv[1:]:
            print(p, fix(p))
