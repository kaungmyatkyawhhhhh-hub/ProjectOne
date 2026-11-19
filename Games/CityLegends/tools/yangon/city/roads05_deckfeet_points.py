# (19 Nov) points to check BUILT deck feet in Studio: every deck end of the net + samples 8 / 16 / 32 studs in.
# usage: python roads05_deckfeet_points.py [net roads.json] > points.txt   (lines: name|end|x y z ...)
# Studio side: tools/yangon/DeckFeetCheck.luau rays down from y+12 onto Roads.Collide and reports top - y.
import json, math, sys
P = sys.argv[1] if len(sys.argv) > 1 else 'roads05_P1_P2_P3_P4_P5_P6_P7_P8_P9_P10_P11_P12/roads.json'
D = json.load(open(P, encoding='utf-8'))
for d in D['decks']:
    for end in ('start', 'end'):
        s = d['s'] if end == 'start' else d['s'][::-1]
        out, arc, want = [], 0.0, [0, 8, 16, 32]
        for i, p in enumerate(s):
            if i:
                arc += math.hypot(p[0] - s[i - 1][0], p[2] - s[i - 1][2])
            while want and arc >= want[0]:
                out.append('%.1f %.2f %.1f' % (p[0], p[1], p[2])); want.pop(0)
        print('%s|%s|%s' % (d['name'], end, ' '.join(out)))
