"""Census of the roads05 Studio built-surface faults (J28 QA, 18 Nov 2026).

    python roads05_census.py faults.json [net dir]  -> prints the pattern table, writes <faults>_census.json

faults.json = { spot: [ {t, x, z, edge, c: [[kind, road, folder above, class, y], ...]}, ... ] }, the dump of
Roads05StudioTest's T.faults (T.qa, the deterministic check). Each fault is put in ONE pattern, first rule that fits
(order below), from the network data (roads.json): road ends (mouth / continuation / map edge / free), junction
centres, decks' feet, roundabouts, islands. Data heights, world x / z.
"""
import json, math, os, sys
from collections import Counter, defaultdict

import numpy as np
from shapely.geometry import Point, Polygon
from shapely.strtree import STRtree

sys.stdout.reconfigure(encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
NET = os.path.normpath(os.path.join(HERE, '..', '..', '..', 'build', 'city_1to1', 'roads05_P1_P2_P3_P4_P5_P6_P7_P8_P9_P10_P11_P12'))
EDGE = 30          # within this of the test box (QA skips 20): the box clips roads square
END_R = 14         # a fault this far past / round a road's end sample + its half belongs to that end
DECK_R = 30        # a deck's foot (first / last sample)
JUNC_PAD = 18      # junction zone = widest arm's half + walk + this


def load(net):
    d = json.load(open(os.path.join(net, 'roads.json'), encoding='utf-8'))
    R = {r['name']: r for r in d['roads']}
    S = {n: np.array([(q[0], q[2]) for q in r['s']]) for n, r in R.items()}
    return d, R, S


def side_reach(r, q):
    return max(q[6], q[7]) + max(r.get('walkL', 0), r.get('walkR', 0))


def on_road(R, S, name, x, z, pad=0.0):
    """True when (x, z) lies on road `name`'s carriageway + walk (+ pad)."""
    r, A = R.get(name), S.get(name)
    if r is None:
        return False
    i = int(np.argmin(((A - (x, z)) ** 2).sum(1)))
    q = r['s'][i]
    return math.hypot(q[0] - x, q[2] - z) < side_reach(r, q) + pad


def classify(f, d, R, S, ctx):
    x, z, t = f['x'], f['z'], f['t']
    cells = f['c']
    roads = sorted({c[1] for c in cells if c[1]})
    kinds = [c[0] for c in cells]
    folders = {c[2] for c in cells if c[2]}
    if f['edge'] < EDGE:
        return 'test-box edge (box clip)'
    for dk in d['decks']:
        for q in (dk['s'][0], dk['s'][-1]):
            if math.hypot(q[0] - x, q[2] - z) < dk['half'] + DECK_R:
                return 'deck foot'
    if 'Decks' in folders:
        return 'on a deck (not its foot)'
    for rb in d['roundabouts']:
        dd = math.hypot(rb['c'][0] - x, rb['c'][2] - z)
        if dd < rb['r_out'] + 40:
            return 'roundabout (ring / arm mouth)'
    # a road end within reach: which kind of end
    best = None
    for n in ctx['near'](x, z):
        r = R[n]
        for k, q in ((0, r['s'][0]), (-1, r['s'][-1])):
            dd = math.hypot(q[0] - x, q[2] - z)
            if dd < max(q[6], q[7]) + END_R and (best is None or dd < best[0]):
                best = (dd, n, k)
    if best:
        _, n, k = best
        r = R[n]
        q = r['s'][k]
        if r.get('startsOnEnd' if k == 0 else 'endsOnEnd'):
            return 'continuation joint (road end on a road end)'
        if r.get('edgeStart' if k == 0 else 'edgeEnd'):
            return 'map-edge road end'
        host = [m for m in ctx['near'](q[0], q[2]) if m != n and on_road(R, S, m, q[0], q[2], 2)]
        if host:
            return 'mouth end (smaller road ends on a bigger one)'
        return 'free road end'
    for j in d['junctions']:
        w = max((side_reach(R[a['road']], R[a['road']]['s'][min(a['i'], len(R[a['road']]['s']) - 1)]) for a in j['arms'] if a['road'] in R), default=20)
        if math.hypot(j['x'] - x, j['z'] - z) < w + JUNC_PAD:
            return 'junction corner zone'
    if ctx['isl'].query(Point(x, z).buffer(8)).size:
        return 'island'
    if len(roads) >= 2:
        return 'two roads side by side (along, not a junction)'
    return 'along one road'


# where each location class is built (the likely root cause; see the census note for the close-ups)
CAUSE = {
    'roundabout (ring / arm mouth)': 'YangonRoads.buildRoundabout (arm kerbs on the ring, ring corner spans) + buildIslands (gore noses between arms get no nose kerb)',
    'mouth end (smaller road ends on a bigger one)': 'YangonRoads.buildMouth (mouth edge walk / MOUTH_SNAP) + roads05_fix.py mouth run-on: the end strip leaves a slot or an unkerbed edge',
    'deck foot': 'YangonRoads.buildDecks + side ground lanes (roads05.py `side`, walk 1: no kerb on the open side) + roads05_fix.py deck_feet',
    'junction corner zone': 'YangonRoads.buildCorners (dropped / one-sided corners, corner kerb chords) + Roads.luau sideZone cut',
    'continuation joint (road end on a road end)': 'YangonRoads.mendCutEnds + roads05_fix.py butt_match (startsOnEnd / endsOnEnd ends)',
    'two roads side by side (along, not a junction)': "Roads.luau pavement height per road: the two roads' pavements meet back to back with no shared height (YangonRoads opts.paveY only at zone edges)",
    'island': "YangonRoads.buildIslands (island / fill outline vs the roads' own pavements)",
    'along one road': 'Roads.luau sideZone kerb / pavement cut along a straight stretch',
    'on a deck (not its foot)': 'YangonRoads.buildDecks',
    'map-edge road end': 'roads05.py edgeStart / edgeEnd',
    'free road end': 'YangonRoads.endKerbs',
    'test-box edge (box clip)': 'the test box (QA margin): check by hand',
}


def sub(f):
    k = sorted({c[0] for c in f['c']} - {'Road'}) if f['t'] == 'kerb_gap' else []
    return f" ({'asphalt next to nothing' if k == ['None'] else 'asphalt next to pavement' if k == ['Pavement'] else '/'.join(k)})" if k else ''


def main():
    src = sys.argv[1]
    net = sys.argv[2] if len(sys.argv) > 2 else NET
    F = json.load(open(src, encoding='utf-8'))
    d, R, S = load(net)
    # coarse grid of road samples for "roads near a point"
    G = defaultdict(set)
    for n, A in S.items():
        for x, z in A:
            G[(int(x // 64), int(z // 64))].add(n)

    def near(x, z):
        out = set()
        cx, cz = int(x // 64), int(z // 64)
        for a in (-2, -1, 0, 1, 2):
            for b in (-2, -1, 0, 1, 2):
                out |= G.get((cx + a, cz + b), set())
        return sorted(out)
    ctx = {'near': near, 'isl': STRtree([Polygon([(q[0], q[2]) for q in i]).buffer(0) for i in d.get('islands', []) if len(i) >= 3])}
    table = Counter()
    ex = {}
    out = []
    for spot in sorted(F):
        for f in F[spot]:
            p = classify(f, d, R, S, ctx) + sub(f)
            key = (f['t'], p)
            table[key] += 1
            ex.setdefault(key, (spot, f['x'], f['z'], sorted({c[1] for c in f['c'] if c[1]})))
            out.append(dict(f, spot=spot, pattern=p))
    tot = Counter(f['t'] for f in out)
    print('totals', dict(tot))
    print('| count | fault | pattern | example (spot, x, z, roads) | likely root cause |')
    print('|---|---|---|---|---|')
    for key, n in sorted(table.items(), key=lambda kv: -kv[1]):
        s, x, z, rs = ex[key]
        base = key[1].split(' (asphalt')[0]
        print(f'| {n} | {key[0]} | {key[1]} | {s} ({x:.0f}, {z:.0f}) {", ".join(rs)[:60]} | {CAUSE.get(base, "")} |')
    json.dump(out, open(os.path.splitext(src)[0] + '_census.json', 'w', encoding='utf-8'), indent=0)


if __name__ == '__main__':
    main()
