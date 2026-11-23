"""Road #25 valley data fix (23 Nov 2026, DISTRICT REBUILD agent; rebuild_progress.json road25.open_valley).

Road #25 is two one-way ramps (decks 'Road Flyover #2' 14..225 and 'Road Flyover' 225..458) that meet in a hairpin
at sample 225 (31522, 45702), 20 studs NORTH of Aung Yadana Street's centre line: the only uncut sample, so the decks'
feet stood on AY's pavement (a kerb box across one ramp, a gap before the other). Fix, in the data:
  * samples 223..227 pulled south onto AY's centre line (weights 1/3, 2/3, 1, 2/3, 1/3 of the apex's pull), halves 10.5
  * both decks end 6 samples earlier (#2 to 219, the other from 231): the ground stretch 219..231 crosses AY's south
    pavement at grade; the last 10 deck samples are eased down to the ground height at the new foot
  * cut = the decks' inner samples again; a crossing [Road #25, 226, AY, j, x, z] (1-based) so YangonRoads.crossMouths
    drops #25's slab on AY and cuts AY's kerbs with mouths (the U-turn lies on AY's carriageway)

    python roads05_valley_fix.py <roads.json> [...]   (idempotent: a patched file is left alone)
"""
import json, math, sys

R25, AY, APEX, SHIFT = 'Road #25', 'Aung Yadana Street', 225, 6
W = {223: 1 / 3, 224: 2 / 3, 225: 1.0, 226: 2 / 3, 227: 1 / 3}
EASE = 10


def ay_z(ay, x):
    s = ay['s']
    for a, b in zip(s, s[1:]):
        if min(a[0], b[0]) <= x <= max(a[0], b[0]):
            t = (x - a[0]) / (b[0] - a[0])
            return a[2] + (b[2] - a[2]) * t, a[1] + (b[1] - a[1]) * t
    raise ValueError('x off Aung Yadana Street')


def fix(path):
    d = json.load(open(path, encoding='utf-8'))
    R = {r['name']: r for r in d['roads']}
    if R25 not in R or AY not in R:
        return 'no Road #25 / AY'
    dk = {k['name']: k for k in d['decks'] if k['of'] == R25}
    a, b = dk['Road Flyover #2'], dk['Road Flyover']
    if int(a['to']) != APEX:
        return 'already patched'
    s, ay = R[R25]['s'], R[AY]
    assert abs(s[APEX][0] - 31522.44) < 0.1 and abs(s[APEX][2] - 45701.64) < 0.1, 'apex moved: re-check the fix'
    old = {i: list(s[i]) for i in W}
    pull = ay_z(ay, s[APEX][0])[0] - s[APEX][2]
    for i, w in W.items():
        s[i][2] = round(s[i][2] + pull * w, 2)
        s[i][1] = round(ay_z(ay, s[i][0])[1], 2)
        s[i][6] = s[i][7] = 10.5
    for i in range(222, 229):
        dx, dz = s[i + 1][0] - s[i - 1][0], s[i + 1][2] - s[i - 1][2]
        n = math.hypot(dx, dz)
        s[i][3], s[i][4] = round(dx / n, 4), round(dz / n, 4)
    # decks: #2 ends at APEX - SHIFT, the other starts at APEX + SHIFT; the eased deck keeps the road's x / z
    ta, fb = APEX - SHIFT, APEX + SHIFT
    a['s'] = a['s'][:ta - int(a['from']) + 1]
    b['s'] = b['s'][fb - int(b['from']):]
    a['to'], b['from'] = ta, fb
    for dek, foot, step in ((a, len(a['s']) - 1, -1), (b, 0, 1)):
        g = s[ta if dek is a else fb][1]
        drop = dek['s'][foot][1] - g
        for k in range(EASE):
            j = foot + step * k
            dek['s'][j][1] = round(dek['s'][j][1] - drop * (1 - k / EASE), 3)
    cut = set(d['cut'][R25])
    cut -= set(range(ta, fb + 1))
    d['cut'][R25] = sorted(cut)
    az = ay_z(ay, s[APEX][0])[0]
    j = min(range(len(ay['s'])), key=lambda k: (ay['s'][k][0] - s[APEX][0]) ** 2 + (ay['s'][k][2] - az) ** 2)
    d['crossings'] = [c for c in d.get('crossings', []) if not (c[0] == R25 and c[2] == AY)]
    d['crossings'].append([R25, APEX + 1, AY, j + 1, round(s[APEX][0], 1), round(az, 1)])
    d['note'] = d.get('note', '') + ' | valley fix 23 Nov (roads05_valley_fix.py)'
    json.dump(d, open(path, 'w', encoding='utf-8'), separators=(',', ':'))
    moved = max(abs(s[i][2] - old[i][2]) for i in W)
    return 'patched: apex pull %.1f (max %.1f), decks %d..%d / %d..%d, cut %d, crossing AY j=%d' % (
        pull, moved, int(a['from']), ta, fb, int(b['to']), len(cut), j + 1)


if __name__ == '__main__':
    for p in sys.argv[1:]:
        print(p, fix(p))
