"""Yangon map, step 3 (13 Nov 2026): put the build ranks and half widths into ygn_roads.json.

tools/riviera/Roads.luau treats the LOWER rank as the bigger road. ygn_roads.json was exported with the
design's ranks (main roads 5, streets 4 / 3 / 2), the wrong way round. d6_export.py is fixed for the next
export, but the design chain's .pkl files are gone, so this script patches the exported file in place:
every road header gets its build rank (0 = Yangon Loop, 1 = New Road, 2 = University Avenue, then the
streets by class, length and name) and "half" (the half carriageway from its first sample).
Only the headers change: no sample moves.

Run from Games/CityLegends:  python tools/yangon/patch_ranks.py [--check]
It also writes build/yangon/rank_patch.luau: the same replacements as a Luau table, for
ServerStorage.YangonData.Roads_1..n (see the build steps note). Plain Python, no numpy.
"""
import json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRC = os.path.join(ROOT, 'imports', 'refs', 'map', 'ygn_roads.json')
DESIGN = os.path.join(ROOT, 'imports', 'refs', 'map', 'ygn_road_design.json')
MAIN_ORDER = ['Yangon Loop', 'New Road', 'University Avenue']


def checksum(text):
    h = 0
    for ch in text.encode('utf-8'):
        h = (h * 31 + ch) % 2147483647
    return h


def main():
    text = open(SRC, encoding='utf-8').read()
    data = json.loads(text)
    length_m = {r['name']: r['length_m'] for r in json.load(open(DESIGN, encoding='utf-8'))['roads']}
    roads = data['roads']
    if all('half' in r for r in roads):
        ranks = sorted(r['rank'] for r in roads)
        ok = ranks == list(range(len(roads))) and [r['name'] for r in sorted(roads, key=lambda r: r['rank'])][:3] == MAIN_ORDER
        print('already patched: ranks 0..%d unique %s, length %d, checksum %d' % (len(roads) - 1, ok, len(text), checksum(text)))
        return 0 if ok else 1
    if '--check' in sys.argv:
        print('not patched yet')
        return 1

    def key(r):
        if r['kind'] == 'route':
            return (0, MAIN_ORDER.index(r['name']), 0, '')
        return (1, -int(r['rank']), -length_m[r['name']], r['name'])   # (old rank: the bigger number is the bigger street)

    order = sorted(roads, key=key)
    rank = {r['name']: i for i, r in enumerate(order)}
    pairs = []
    for r in roads:
        half = r['s'][0][6]
        assert all(s[6] == half and s[7] == half for s in r['s']), r['name']
        old = '{"name":%s,"kind":"%s","closed":false,"rank":%d,"s":[' % (json.dumps(r['name']), r['kind'], r['rank'])
        new = '{"name":%s,"kind":"%s","closed":false,"rank":%d,"half":%d,"s":[' % (json.dumps(r['name']), r['kind'], rank[r['name']], half)
        assert text.count(old) == 1, (r['name'], text.count(old))
        pairs.append((old, new))
    for old, new in pairs:
        text = text.replace(old, new)
    back = json.loads(text)
    assert [r['s'] for r in back['roads']] == [r['s'] for r in roads]
    open(SRC, 'w', encoding='utf-8', newline='').write(text)
    os.makedirs(os.path.join(ROOT, 'build', 'yangon'), exist_ok=True)
    with open(os.path.join(ROOT, 'build', 'yangon', 'rank_patch.luau'), 'w', encoding='utf-8', newline='\n') as f:
        f.write('return {\n')
        for old, new in pairs:
            f.write('\t{ %s, %s },\n' % (json.dumps(old), json.dumps(new)))
        f.write('}\n')
    for r in sorted(back['roads'], key=lambda r: r['rank']):
        print('%2d  half %2d  %-6s %s' % (r['rank'], r['half'], r['kind'], r['name']))
    print('patched: length %d, checksum %d' % (len(text), checksum(text)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
