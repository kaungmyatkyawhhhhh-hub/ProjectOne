"""Drop OSM lanes that run under / through a landmark building (24 Nov 2026, OVERLAPS FIX agent).

Owner decisions (24 Nov): the service lanes under the Bogyoke Market halls are covered market lanes, not roads: drop
them; the lane through Holy Trinity Cathedral: drop the stretch through the church. Rules:
  * DROP: whole roads (every stretch outside the halls is <= 16 studs: mouth stubs) and their crossings
  * CUT: the samples whose carriageway + pavement reach a building box are removed; the road is split into the
    pieces left (first keeps the name, later ones get a letter: "Lane #4266b")

    python roads05_drop_lanes.py <roads.json> [...]     (idempotent: a patched file is left alone)
    python roads05_drop_lanes.py test                   (self-check)
"""
import json, math, sys

# building boxes (Studio, Landmarks.<id>.Collision): cx, cz, size along local X, size along local Z, yaw (rad)
HALLS = [(34771.7, 43143.2, 538.5, 112.0, -1.611), (34913.6, 43148.9, 538.5, 112.0, -1.611),
         (35055.4, 43154.7, 538.5, 112.0, -1.611), (35197.3, 43160.5, 538.5, 112.0, -1.611)]
CHURCH = [(34491.5, 43235.5, 161.6, 91.0, 0.069), (34575.0, 43178.0, 27.0, 27.0, 0.0)]  # nave + tower
DROP = {'Lane #19', 'Lane #3810', 'Lane #3808', 'Lane #3809', 'Lane #3806', 'Lane #3807', 'Lane #3805', 'Lane #3804'}
CUT = {'Lane #4266': CHURCH}
MIN_PIECE = 30.0  # studs: a shorter piece left over is dropped too


def inside(px, pz, b, grow):
    cx, cz, lx, lz, ya = b
    dx, dz = px - cx, pz - cz
    u = dx * math.cos(ya) - dz * math.sin(ya)
    v = dx * math.sin(ya) + dz * math.cos(ya)
    return abs(u) <= lx / 2 + grow and abs(v) <= lz / 2 + grow


def length(s):
    return sum(math.hypot(b[0] - a[0], b[2] - a[2]) for a, b in zip(s, s[1:]))


def patch(d):
    roads, out, log = d['roads'], [], []
    dropped = set()
    top = max(int(float(r['rank'])) for r in roads if 'rank' in r)  # ranks are unique: a split piece takes a new last one
    for r in roads:
        if r['name'] in DROP:
            dropped.add(r['name'])
            log.append('dropped %s (%d samples)' % (r['name'], len(r['s'])))
            continue
        boxes = CUT.get(r['name'])
        if not boxes:
            out.append(r)
            continue
        g = float(r['half']) + max(float(r.get('walkL', 0)), float(r.get('walkR', 0)))
        flags = [any(inside(p[0], p[2], b, g) for b in boxes) for p in r['s']]
        if not any(flags):
            out.append(r)
            continue
        pieces, cur = [], []
        for p, f in zip(r['s'], flags):
            if f:
                if cur:
                    pieces.append(cur)
                cur = []
            else:
                cur.append(p)
        if cur:
            pieces.append(cur)
        pieces = [p for p in pieces if len(p) >= 2 and length(p) >= MIN_PIECE]
        for k, p in enumerate(pieces):
            q = dict(r)
            q['s'] = p
            if k:
                q['name'] = r['name'] + 'abcdefgh'[k]
                top += 1
                q['rank'] = type(r['rank'])(top)
            for key in ('startsOnEnd', 'endsOnEnd'):
                q.pop(key, None)  # the cut ends no longer meet what the whole road met
            out.append(q)
        log.append('cut %s: %d samples off, %d pieces (%s)' % (r['name'], sum(flags), len(pieces), ', '.join('%d' % round(length(p)) for p in pieces)))
        dropped.add(r['name'])  # its crossings: sample numbers no longer hold
    d['roads'] = out
    n0 = len(d.get('crossings', []))
    d['crossings'] = [c for c in d.get('crossings', []) if not (set(x for x in c if isinstance(x, str)) & dropped)]
    log.append('crossings %d -> %d' % (n0, len(d['crossings'])))
    d['note'] = d.get('note', '') + ' | drop_lanes 24nov'
    return log


def check(d):
    for r in d['roads']:
        assert r['name'] not in DROP, r['name']
        if r['name'].rstrip('abcdefgh') in CUT:
            g = float(r['half']) + max(float(r.get('walkL', 0)), float(r.get('walkR', 0)))
            assert not any(inside(p[0], p[2], b, g) for p in r['s'] for b in CUT[r['name'].rstrip('abcdefgh')]), r['name']


def main(paths):
    for path in paths:
        d = json.load(open(path, encoding='utf-8'))
        if 'drop_lanes 24nov' in d.get('note', ''):
            print(path, 'already patched')
            continue
        for line in patch(d):
            print(' ', line)
        check(d)
        open(path, 'w', encoding='utf-8').write(json.dumps(d, separators=(',', ':')))
        print(path, 'patched,', len(d['roads']), 'roads')


def test():
    s = [[34300.0 + 10 * k, 30.0, 43186.0, 1, 0, 0, 8.25, 8.25, 0, 1, 0, 0] for k in range(40)]
    d = {'roads': [{'name': 'Lane #4266', 'rank': '5', 'half': '8.25', 'walkL': '3', 'walkR': '3', 's': s},
                   {'name': 'Lane #19', 'rank': '6', 'half': '6', 's': s[:3]}, {'name': 'Keep', 'rank': '7', 'half': '6', 's': s[:3]}],
         'crossings': [['Lane #19', 1, 'Keep', 2], ['Keep', 1, 'Other', 2]], 'note': ''}
    patch(d)
    check(d)
    names = [r['name'] for r in d['roads']]
    assert names[0] == 'Lane #4266' and 'Keep' in names and 'Lane #19' not in names, names
    assert len(d['crossings']) == 1
    ranks = [r['rank'] for r in d['roads']]
    assert len(set(ranks)) == len(ranks), ranks
    print('test ok', names)


if __name__ == '__main__':
    test() if sys.argv[1:] == ['test'] else main(sys.argv[1:])
