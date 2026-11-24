"""Arzani Street deck fix (24 Nov 2026, ROAD FIX agent; rebuild_progress.json "arzani_24nov").

The 'Arzani Street Flyover' deck (Arzani Street samples 17..116, 32045,35799 -> 32726,36170) is not real: OpenStreetMap
has no bridge on Arzani Street (ways 489235410, 23380102, 482651149, 617583031: no bridge / layer tag, checked 24 Nov).
It came from a 'raised' run in the old P7 road profile (roads_P7_profile.json ids 10 / 374 / 380). The same profile left
the hill's road data on two flat shelves (76.97 and 129.56) with 50-stud jumps between them; the 19 Nov P7 build
re-graded those roads into a drivable surface, so the deck stopped 39 studs over the built road (traffic and players
drove off it).

Fix, in the data (cells 1536 20x23 + 21x23 = box 30720,35328 .. 33792,36864, built by RB7):
  * the deck is dropped and Arzani Street is not cut: it is a ground road
  * Arzani 16..120: one smooth grade from its data at 16 (76.96) to the built road at 120, eased into the built grade
  * every other road sample in the box takes the BUILT road top (the place's road collision, RB7 bake = what players
    drive now) where it differs from the data by more than 1 stud; samples with no built top are interpolated
  * Arzani 120.. in the box also takes the built top

    python roads05_arzani_fix.py make            -> arzani_fix_heights.json (needs roads05_RB7/collide + roads.json)
    python roads05_arzani_fix.py <roads.json>... (idempotent: applies the heights by sample position, drops the deck)
    python roads05_arzani_fix.py test
"""
import json, math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
B1 = os.path.abspath(os.path.join(HERE, '..', '..', '..', 'build', 'city_1to1'))
OUT = os.path.join(B1, 'arzani_fix_heights.json')
BOX = (30720.0, 35328.0, 33792.0, 36864.0)
ARZ, DECK = 'Arzani Street', 'Arzani Street Flyover'
FOOT, JOIN = 16, 120     # Arzani: last kept data sample before the old deck, first built sample used for the new grade
NOTE = 'arzani fix 24nov'
MARGIN = 150.0          # stepCell builds roads 140 past the box: their heights there match the neighbours' built roads


def inbox(x, z, m=0.0):
    return BOX[0] - m <= x <= BOX[2] + m and BOX[1] - m <= z <= BOX[3] + m


def boxes():
    out = []
    D = os.path.join(B1, 'roads05_RB7', 'collide_mods', 'P7')  # the whole P7 bake (collide/ holds only the mb24 cells)
    for f in sorted(os.listdir(D)):
        for row in open(os.path.join(D, f)):
            row = row.replace('return [==[', '').replace(']==]', '')
            v = row.split()
            if len(v) != 13 or v[0] != 'R':
                continue
            c = [float(t) for t in v[1:4]]
            r = [float(t) for t in v[4:7]]
            u = [float(t) for t in v[7:10]]
            s = [float(t) for t in v[10:13]]
            if inbox(c[0], c[2], MARGIN + 200):
                out.append((c, r, u, s))
    return out


def top_at(B, x, z):
    """highest R box top over (x, z); None if no box covers it"""
    best = None
    for c, r, u, s in B:
        if abs(c[0] - x) > 80 or abs(c[2] - z) > 80:
            continue
        lk = (r[1] * u[2] - r[2] * u[1], r[2] * u[0] - r[0] * u[2], r[0] * u[1] - r[1] * u[0])
        t = (c[0] + u[0] * s[1] / 2, c[1] + u[1] * s[1] / 2, c[2] + u[2] * s[1] / 2)
        if abs(u[1]) < 0.5:
            continue
        y = t[1] - (u[0] * (x - t[0]) + u[2] * (z - t[2])) / u[1]
        d = (x - c[0], y - c[1], z - c[2])
        if abs(d[0] * r[0] + d[1] * r[1] + d[2] * r[2]) <= s[0] / 2 and abs(d[0] * lk[0] + d[1] * lk[1] + d[2] * lk[2]) <= s[2] / 2:
            best = y if best is None else max(best, y)
    return best


def fill_gaps(ys):
    """None entries interpolated between known neighbours (ends: nearest known)"""
    known = [i for i, y in enumerate(ys) if y is not None]
    if not known:
        return ys
    out = list(ys)
    for i in range(len(ys)):
        if out[i] is None:
            lo = max([k for k in known if k < i], default=None)
            hi = min([k for k in known if k > i], default=None)
            if lo is None:
                out[i] = ys[hi]
            elif hi is None:
                out[i] = ys[lo]
            else:
                out[i] = ys[lo] + (ys[hi] - ys[lo]) * (i - lo) / (hi - lo)
    return out


def make():
    d = json.load(open(os.path.join(B1, 'roads05_RB7', 'roads.json'), encoding='utf-8'))
    B = boxes()
    cut = {k: set(v) for k, v in d['cut'].items()}
    heights = {}
    for r in d['roads']:
        s = r['s']
        idx = [i for i, p in enumerate(s) if inbox(p[0], p[2], MARGIN)]
        if not idx:
            continue
        c = cut.get(r['name'], set()) if r['name'] != ARZ else set()
        ys = [None] * len(s)
        for i in idx:
            if (i + 1) in c:
                continue
            b = top_at(B, s[i][0], s[i][2])
            ys[i] = b
        if r['name'] == ARZ:
            for i in range(FOOT + 1, JOIN):
                ys[i] = None
            yb = fill_gaps(ys)
            # one grade from the foot to the built road, then a 10-sample vertical curve each end
            y0, y1 = s[FOOT][1], yb[JOIN]
            g1 = (yb[JOIN + 8] - yb[JOIN]) / 8
            for i in range(FOOT + 1, JOIN):
                ys[i] = y0 + (y1 - y0) * (i - FOOT) / (JOIN - FOOT)
            # the built road past JOIN, robust-smoothed (median 7 then mean 5: junction mouth boxes sit a stud off the
            # road, and a raw max of the boxes left a 1-stud step at Lane #1957's mouth, Play 24 Nov)
            last = max(idx)
            tail = fill_gaps(ys)
            med = {i: sorted(tail[max(JOIN, i - 3):min(last, i + 3) + 1])[len(tail[max(JOIN, i - 3):min(last, i + 3) + 1]) // 2] for i in range(JOIN, last + 1)}
            tsm = {i: sum(med[j] for j in range(max(JOIN, i - 2), min(last, i + 2) + 1)) / (min(last, i + 2) - max(JOIN, i - 2) + 1) for i in range(JOIN, last + 1)}
            k = 5
            full = [s[i][1] if i <= FOOT else ys[i] for i in range(JOIN)] + [tsm[i] for i in range(JOIN, last + 1)] + [p[1] for p in s[last + 1:]]
            sm = list(full)
            for i in range(FOOT - 6, JOIN + 12):
                w = full[i - k:i + k + 1]
                sm[i] = sum(w) / len(w)
            for i in range(FOOT - 4, last + 1):
                if inbox(s[i][0], s[i][2], MARGIN):
                    heights['%.2f,%.2f' % (s[i][0], s[i][2])] = round(sm[i], 2)
            continue
        # other roads: the built top, robust-smoothed (median 5 then mean 3: overlapping mouth boxes jitter a stud);
        # a road that differs anywhere by > 1.5 takes the whole smoothed run (no half-changed steps)
        run = [i for i in idx if (i + 1) not in c]
        yf = fill_gaps([ys[i] if i in set(run) else None for i in range(len(s))])
        if not run or yf[run[0]] is None:
            continue
        med = {}
        for i in run:
            w = sorted(yf[j] for j in range(max(run[0], i - 2), min(run[-1], i + 2) + 1))
            med[i] = w[len(w) // 2]
        sm = {}
        for i in run:
            w = [med[j] for j in (i - 1, i, i + 1) if j in med]
            sm[i] = sum(w) / len(w)
        if max(abs(sm[i] - s[i][1]) for i in run) > 1.0:
            for i in run:
                heights['%.2f,%.2f' % (s[i][0], s[i][2])] = round(sm[i], 2)
    json.dump(heights, open(OUT, 'w'), indent=0)
    print('heights', len(heights), '->', OUT)


def pin_mouths(d):
    """a smaller road's samples on Arzani's carriageway take Arzani's height there, the change fading back along the road
    over max(40, |d| / 0.06) studs (Roads.luau alignJunctions' rule; the bake's collision boxes come from the data, so a
    lane end 1.2 over Arzani stood as a box step: Lane #1957, Play 24 Nov)"""
    A = [r for r in d['roads'] if r['name'] == ARZ]
    if not A:
        return 0
    A = A[0]['s']
    n = 0
    for r in d['roads']:
        s = r['s']
        if r['name'] == ARZ or not any(inbox(p[0], p[2]) for p in s):
            continue
        tgt = {}
        for i, p in enumerate(s):
            if not inbox(p[0], p[2]):
                continue
            j = min(range(len(A)), key=lambda j: (A[j][0] - p[0]) ** 2 + (A[j][2] - p[2]) ** 2)
            if math.hypot(A[j][0] - p[0], A[j][2] - p[2]) < min(A[j][6], A[j][7]) - 0.5:
                tgt[i] = A[j][1] - p[1]
        tgt = {i: v for i, v in tgt.items() if abs(v) > 0.3}
        if not tgt:
            continue
        arc = [0.0]
        for a, b in zip(s, s[1:]):
            arc.append(arc[-1] + math.hypot(b[0] - a[0], b[2] - a[2]))
        off = [0.0] * len(s)
        for i in range(len(s)):
            if i in tgt:
                off[i] = tgt[i]
                continue
            best = 0.0
            for k, v in tgt.items():
                w = max(0.0, 1 - abs(arc[i] - arc[k]) / max(40.0, abs(v) / 0.06))
                if abs(v * w) > abs(best):
                    best = v * w
            off[i] = best
        for i, p in enumerate(s):
            if off[i]:
                p[1] = round(p[1] + off[i], 2)
                n += 1
    return n


def fix(path, H=None):
    H = H if H is not None else json.load(open(OUT))
    d = json.load(open(path, encoding='utf-8'))
    if NOTE in d.get('note', ''):
        return 'already fixed'
    n = 0
    for r in d['roads']:
        for p in r['s']:
            y = H.get('%.2f,%.2f' % (p[0], p[2]))
            if y is not None and inbox(p[0], p[2], MARGIN):
                p[1] = y
                n += 1
    n += pin_mouths(d)
    nd = len(d['decks'])
    d['decks'] = [k for k in d['decks'] if k['name'] != DECK]
    d['cut'].pop(ARZ, None)
    d['note'] = d.get('note', '') + ' | ' + NOTE
    json.dump(d, open(path, 'w', encoding='utf-8'), separators=(',', ':'))
    return 'samples %d, decks dropped %d' % (n, nd - len(d['decks']))


def test():
    d = json.load(open(os.path.join(B1, 'roads05_RB7', 'roads.json'), encoding='utf-8'))
    H = json.load(open(OUT))
    import copy, tempfile
    tmp = os.path.join(tempfile.mkdtemp(), 'roads.json')
    json.dump(d, open(tmp, 'w', encoding='utf-8'), ensure_ascii=False)
    print(fix(tmp, H))
    assert fix(tmp, H) == 'already fixed'
    e = json.load(open(tmp, encoding='utf-8'))
    assert not any(k['name'] == DECK for k in e['decks']) and ARZ not in e['cut']
    worst = 0
    for r in e['roads']:
        s = r['s']
        for i in range(1, len(s) - 1):
            if not inbox(s[i][0], s[i][2]):
                continue
            a, b, c = s[i - 1], s[i], s[i + 1]
            la, lb = math.hypot(b[0] - a[0], b[2] - a[2]), math.hypot(c[0] - b[0], c[2] - b[2])
            if la < 1 or lb < 1:
                continue
            g = abs((c[1] - b[1]) / lb - (b[1] - a[1]) / la)
            if g > 0.15:
                print('  grade change %.0f%% %s %d (%.0f, %.0f) %.1f %.1f %.1f' % (g * 100, r['name'], i, b[0], b[2], a[1], b[1], c[1]))
            worst = max(worst, g)
    a = [r for r in e['roads'] if r['name'] == ARZ][0]['s']
    print('Arzani 0..200 every 8:', [round(a[i][1], 1) for i in range(0, 201, 8)])
    print('worst grade change in the box %.0f%%' % (worst * 100))


if __name__ == '__main__':
    if sys.argv[1] == 'make':
        make()
    elif sys.argv[1] == 'test':
        test()
    else:
        for p in sys.argv[1:]:
            print(p, fix(p))
