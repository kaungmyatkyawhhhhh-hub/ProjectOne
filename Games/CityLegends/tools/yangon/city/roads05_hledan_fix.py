"""Hledan flyover data fix (25 Nov 2026, DECK OVERLAP FIX agent; vault 'City Legends/2026-11-25 Deck overlaps fix.md').

OSM: Pyay Road by Hledan is ONE bridge each way (ways 274922221 + 221165644 south, 504912944 + 514101297 north) from
z ~26440 to ~29260. The data had two decks on Pyay Road #6 with a ground dip between (samples 74..91):
"Pyay Road Flyover #3" (samples 0..74, a 4-stud low hump at 58.3) and "Pyay Road Flyover #2" (91..276, the 73 hump).
22 Nov a hand-built deck (Roads.HledanDeckFix, tools/yangon/HledanDeck.luau) was laid OVER the baked dip: two decks
stacked 1-16 studs apart (the owner's "double overhead roads").

This makes them one deck "Pyay Road Flyover #2" over samples 0..276 with HledanDeck's profile: #3's heights south of
z 29142, a 6.8% ramp up to 73, level 73 until #2's own 73 run, then #2's heights. Pyay Road #6 is cut 1..275.

    python roads05_hledan_fix.py <roads.json> ...     (idempotent)
    python roads05_hledan_fix.py test
"""
import json, math, os, shutil, sys, tempfile

NOTE = 'hledan fix 25nov'
ROAD = 'Pyay Road #6'
KEEP, DROP = 'Pyay Road Flyover #2', 'Pyay Road Flyover #3'
Z_LOW = 29142.0   # south end of the low hump (larger z = south)
TOP, GRADE = 73.0, 0.068
B = os.path.join(os.path.dirname(__file__), '..', '..', '..', 'build', 'city_1to1')
NET = os.path.join(B, 'roads05_P1_P2_P3_P4_P5_P6_P7_P8_P9_P10_P11_P12', 'roads.json')


def fix(path):
    d = json.load(open(path, encoding='utf-8'))
    if NOTE in d.get('note', ''):
        return 'already fixed'
    decks = {k['name']: k for k in d['decks']}
    if KEEP not in decks or DROP not in decks:
        return 'no Hledan decks here'
    a, b = decks[KEEP], decks[DROP]
    assert a['of'] == b['of'] == ROAD and b['from'] == 0 and a['to'] > a['from'] > b['to']
    road = next(r for r in d['roads'] if r['name'] == ROAD)
    s = road['s']
    n0, n1 = 0, a['to']
    ha = {a['from'] + i: q[1] for i, q in enumerate(a['s'])}
    hb = {b['from'] + i: q[1] for i, q in enumerate(b['s'])}
    # arc length along the road
    L = [0.0]
    for i in range(n0 + 1, n1 + 1):
        L.append(L[-1] + math.hypot(s[i][0] - s[i - 1][0], s[i][2] - s[i - 1][2]))
    iA = min(hb, key=lambda i: abs(s[i][2] - Z_LOW))
    iB = min(i for i in ha if ha[i] >= TOP - 0.05)  # first sample of #2's level run, coming from the south
    hA = hb[iA]
    out = []
    for i in range(n0, n1 + 1):
        if i < iA:
            h = hb[i]
        elif i < iB:
            h = min(TOP, hA + GRADE * (L[i] - L[iA]))
        else:
            h = ha[i]
        q = list(s[i])
        q[1] = round(h, 3)
        out.append(q)
    a['s'], a['from'], a['to'] = out, n0, n1
    a['half'] = max(a['half'], b['half'])
    a['sides'] = sorted(set(a.get('sides', [])) | set(b.get('sides', [])))
    d['decks'] = [k for k in d['decks'] if k['name'] != DROP]
    cut = set(d['cut'].get(ROAD, []))
    cut |= set(range(n0 + 1, n1))
    d['cut'][ROAD] = sorted(cut)
    d['note'] = d.get('note', '') + ' | ' + NOTE
    json.dump(d, open(path, 'w', encoding='utf-8'), separators=(',', ':'), ensure_ascii=False)
    return dict(deck=KEEP, samples=(n0, n1), ramp=(iA, iB), dropped=DROP)


def test():
    tmp = os.path.join(tempfile.mkdtemp(), 'roads.json')
    shutil.copy(NET, tmp)
    print(fix(tmp))
    assert fix(tmp) == 'already fixed'
    d = json.load(open(tmp, encoding='utf-8'))
    ds = [k for k in d['decks'] if k['of'] == ROAD]
    assert [k['name'] for k in ds] == [KEEP], ds
    k = ds[0]
    h = [q[1] for q in k['s']]
    # no dip: once up at TOP the deck stays up until #2's north ramp; grades within 7%
    top = [i for i, v in enumerate(h) if v >= TOP - 0.05]
    assert all(h[i] >= TOP - 0.05 for i in range(top[0], top[-1] + 1)), 'dip left in the deck'
    for i in range(1, len(h)):
        q0, q1 = k['s'][i - 1], k['s'][i]
        g = abs(h[i] - h[i - 1]) / max(math.hypot(q1[0] - q0[0], q1[2] - q0[2]), 0.1)
        assert g < 0.075, (i, g)
    cut = set(d['cut'][ROAD])
    assert all(i in cut for i in range(1, 276)) and 0 not in cut and 276 not in cut
    # the deck follows the road's own samples (positions untouched)
    road = next(r for r in d['roads'] if r['name'] == ROAD)
    assert all(abs(road['s'][i][0] - k['s'][i][0]) < 1e-6 and abs(road['s'][i][2] - k['s'][i][2]) < 1e-6 for i in range(277))
    print('test ok: one deck, %d samples, top run %d..%d, max %.2f' % (len(h), top[0], top[-1], max(h)))


if __name__ == '__main__':
    if sys.argv[1:] == ['test']:
        test()
    else:
        for p in sys.argv[1:]:
            print(p, fix(p))
