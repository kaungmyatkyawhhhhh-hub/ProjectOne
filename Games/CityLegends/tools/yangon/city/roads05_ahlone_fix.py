"""Ahlone Road #3 deck foot step (24 Nov 2026, ROAD FIX agent; vault '2026-11-24 Traffic fix - racer bumps and rear doors'
spot #10, a 4.6-stud step at (27503, 39765)).

The road under the 'Ahlone Road Flyover' deck (Ahlone Road #3 samples 312..394, cut) kept the old profile's ground
height 56.58 to the very foot, while the deck and the ground road from the foot on (sample 395) are at 61.82: a 5.2-stud
jump between two neighbouring samples. The builder eases a road's heights over its neighbours (cut ones too), so the
built ground road started 4.6 under the deck foot and climbed back over ~50 studs. Sample 394 (the first uncut one, the foot) was still 56.58 next to
395 at 61.82. Fix: every road sample in the deck's range takes the deck's own height (the cut ones are under it, never
built), so the road's profile is continuous through the foot.

    python roads05_ahlone_fix.py <roads.json>...   (idempotent)
"""
import json, sys

ROAD, DECK, NOTE = 'Ahlone Road #3', 'Ahlone Road Flyover', 'ahlone foot fix 24nov'


def fix(path):
    d = json.load(open(path, encoding='utf-8'))
    if NOTE in d.get('note', ''):
        return 'already fixed'
    R = {r['name']: r for r in d['roads']}
    dk = [k for k in d['decks'] if k['name'] == DECK and k['of'] == ROAD]
    if ROAD not in R or not dk:
        return 'no %s / deck' % ROAD
    k, s = dk[0], R[ROAD]['s']
    n = 0
    for q, i in enumerate(range(k['from'], k['to'] + 1)):
        if abs(s[i][0] - k['s'][q][0]) < 0.05 and abs(s[i][2] - k['s'][q][2]) < 0.05:
            s[i][1] = k['s'][q][1]
            n += 1
    d['note'] = d.get('note', '') + ' | ' + NOTE
    json.dump(d, open(path, 'w', encoding='utf-8'), separators=(',', ':'))
    return 'samples on the deck heights: %d' % n


if __name__ == '__main__':
    for p in sys.argv[1:]:
        print(p, fix(p))
