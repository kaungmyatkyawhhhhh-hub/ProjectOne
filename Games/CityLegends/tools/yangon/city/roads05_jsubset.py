"""A Studio junction test's data: only the roads within REACH of the test junctions (17 Nov 2026).

    python roads05_jsubset.py <net dir> <out dir> <junctions.json {name: [x, z]}>
-> <out>/Roads05_<k>.luau (YangonData modules) + junctions.json
"""
import json, math, os, sys

REACH = 800.0
CHUNK = 185000


def main():
    src, out, jf = sys.argv[1:4]
    J = json.load(open(jf))
    d = json.load(open(os.path.join(src, 'roads.json'), encoding='utf-8'))
    pts = list(J.values())
    keep = [r for r in d['roads'] if any(math.hypot(q[0] - x, q[2] - z) < REACH for q in r['s'][::2] + [r['s'][-1]] for x, z in pts)]
    names = set(r['name'] for r in keep)
    d['roads'] = keep
    d['cut'] = {k: v for k, v in d['cut'].items() if k in names}
    d['decks'] = [k for k in d['decks'] if k['of'] in names]
    d['roundabouts'] = [g for g in d['roundabouts'] if any(math.hypot(g['c'][0] - x, g['c'][2] - z) < REACH + g['r_out'] for x, z in pts)]
    d['driveways'] = [w for w in d.get('driveways', []) if any(math.hypot(w['x'] - x, w['z'] - z) < REACH for x, z in pts)]
    os.makedirs(out, exist_ok=True)
    for f in os.listdir(out):
        if f.startswith('Roads05_'):
            os.remove(os.path.join(out, f))
    txt = json.dumps(d, separators=(',', ':'))
    k = 0
    for a in range(0, len(txt), CHUNK):
        k += 1
        part = txt[a:a + CHUNK]
        assert ']==]' not in part
        open(os.path.join(out, 'Roads05_%d.luau' % k), 'w', encoding='utf-8').write('return [==[' + part + ']==]')
    json.dump(J, open(os.path.join(out, 'junctions.json'), 'w'))
    open(os.path.join(out, 'roads.json'), 'w', encoding='utf-8').write(txt)
    print('roads %d decks %d rings %d modules %d chars %d' % (len(keep), len(d['decks']), len(d['roundabouts']), k, len(txt)))


if __name__ == '__main__':
    main()
