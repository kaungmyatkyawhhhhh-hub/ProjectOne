"""Whole-Yangon map (14 Nov 2026): the real street network for the city generator.

Owner: "in real life its compact and in game theres like barely any" (the game had 37.6 km of the ~192 km of real public
streets in batch 0.5). This takes every public OSM street in a box, works out which ones the game already has (they lie in a
game road's corridor), and returns the rest as new streets with a width class:

  class      OSM highway                          half (studs)   walk   lanes
  big        trunk / primary / secondary not in   by lanes: 2+2 -> 26, 3+3 -> 39 (+ median 3 when divided)   5
             the game (by their OSM lanes)
  street     tertiary, unclassified, residential   10             4      1 + 1 (no traffic)
             with lanes >= 2 or width >= 7 m
  lane       residential / living_street narrower  8              3      one lane, two-way (no traffic)

(Game roads keep their own widths: routes 32-42, game streets 16.)

network(box, game_roads) -> dict with 'new' (list of street records) and 'covered' (OSM ways the game already has).
A street record: {id, name, cls, half, walk, lanes, oneway, bridge, layer, pts: [[x, z], ...]}.
"""
import math

from shapely.geometry import LineString, Point, box as sbox
from shapely.ops import unary_union
from shapely.strtree import STRtree

from geo import load, proj, in_box

PUBLIC = {'trunk', 'primary', 'secondary', 'tertiary', 'unclassified', 'residential', 'living_street', 'trunk_link',
          'primary_link', 'secondary_link', 'tertiary_link'}
BIG = {'trunk', 'primary', 'secondary', 'trunk_link', 'primary_link', 'secondary_link'}
CLIP_MIN = 4.0     # a street cut on the box edge shorter than this is dropped
TAIL_MAX = 300.0   # seam tails (network()) at most this long


def lanes_each_way(t):
    one = t.get('oneway') in ('yes', '-1', 'true', '1')
    try:
        if one:
            return one, int(float(t['lanes']))
        if 'lanes:forward' in t:
            return one, int(float(t['lanes:forward']))
        return one, max(1, int(round(float(t['lanes']) / 2)))
    except (KeyError, ValueError):
        return one, None


def width_m(t):
    try:
        return float(str(t.get('width', '')).replace('m', '').strip())
    except ValueError:
        return None


def classify(t):
    hw = t.get('highway')
    one, ln = lanes_each_way(t)
    w = width_m(t)
    if hw in BIG:
        n = ln or 2
        n = max(1, min(3, n))
        if n >= 2:
            return 'big', (26.0 if n == 2 else 39.0) / (2 if one else 1), 5.0, n
        return 'street', 10.0, 4.0, 1
    # (most Yangon residential streets are two-way and about 6-8 m wide with no lane tags: a street; only living streets and
    # streets tagged narrower than 5.5 m are lanes)
    if hw == 'living_street' or (w and w < 5.5) or (ln == 1 and not one and hw == 'residential' and w and w < 6):
        return 'lane', 8.0, 3.0, 1
    return 'street', 10.0, 4.0, 1


def game_corridors(game_roads, grow=6.0):
    """Polygons of the game's roads (carriageway + pavement + grow), and the cut samples left out."""
    polys = []
    for r in game_roads['roads']:
        cs = set(game_roads.get('cut', {}).get(r['name'], []))
        walk = r.get('walkL') or 10.0
        run = []
        for k, s in enumerate(r['s']):
            if k in cs:
                if len(run) > 1:
                    polys.append(LineString(run).buffer(max(s[6], s[7]) + walk + grow, cap_style=2))
                run = []
                continue
            run.append((s[0], s[2]))
        if len(run) > 1:
            half = max(max(q[6], q[7]) for q in r['s'])
            polys.append(LineString(run).buffer(half + walk + grow, cap_style=2))
    for d in game_roads.get('decks', []):
        pts = [(q[0], q[2]) for q in d['s']]
        if len(pts) > 1:
            polys.append(LineString(pts).buffer(40, cap_style=2))
    return unary_union(polys)


def network(box, game_roads, min_len=24.0, margin=200.0, clip=True, plots=None):
    """the streets of `box` (x0, z0, x1, z1). Which OSM pieces are new streets (length, covered by a game road) is decided on
    the box grown by `margin`; with `clip` every new street is then cut exactly on the box's edge (2026-11-14: batch 0.5's
    streets reached 200 studs past BOX_05 and overlapped batch 1's roads, which start on that edge), so the streets inside
    are the same ones as before and a street crossing the edge stops on it (pieces under CLIP_MIN studs dropped)."""
    area = sbox(box[0] - margin, box[1] - margin, box[2] + margin, box[3] + margin)
    inner = sbox(*box)
    covered_poly = game_corridors(game_roads) if game_roads else None
    new, covered, tails = [], [], []
    for r in load('roads'):
        t = r['t']
        hw = t.get('highway')
        if hw not in PUBLIC:
            continue
        if t.get('access') in ('private', 'no'):
            continue
        pts = proj(r['p'])
        line = LineString(pts)
        if not line.intersects(area):
            continue
        line = line.intersection(area)
        if line.is_empty:
            continue
        parts = [line] if line.geom_type == 'LineString' else [g for g in getattr(line, 'geoms', []) if g.geom_type == 'LineString']
        cls, half, walk, n = classify(t)
        one, _ = lanes_each_way(t)
        for g in parts:
            if g.length < min_len:
                continue
            if covered_poly is not None:
                inside = g.intersection(covered_poly).length
                g2 = g.difference(covered_poly)
                pieces = [g2] if g2.geom_type == 'LineString' else [x for x in getattr(g2, 'geoms', []) if x.geom_type == 'LineString']
                if inside > 0.6 * g.length:
                    covered.append(r['id'])
                    # (2026-11-14) seam tails: a mostly-covered way's uncovered end can be the only link from a game road's end
                    # to the box's edge or to the street that leads there (Nar Nat Taw: ~150 studs between the v5 end and its
                    # junction with the street to the edge were lost). Kept below when it links up.
                    if clip:
                        for x in pieces:
                            xi = x if x.within(inner) else x.intersection(inner)
                            for y in ([xi] if xi.geom_type == 'LineString' else [z for z in getattr(xi, 'geoms', []) if z.geom_type == 'LineString']):
                                if min_len <= y.length <= TAIL_MAX:
                                    tails.append((r, t, hw, y))
                    continue
            else:
                pieces = [g]
            for p in pieces:
                if p.length < min_len:
                    continue
                add(new, r, t, hw, p, clip, inner)
    # seam tails that link up: one end on a game road's corridor, the other on the box's edge or on a street kept above
    new_tails = 0
    blocked = []
    if tails:
        from shapely.geometry import MultiPoint
        edge = inner.exterior
        # ends of kept streets that run on to the box's edge
        lead = [Point(s_['pts'][k]) for s_ in new for k, o in ((0, -1), (-1, 0)) if edge.distance(Point(s_['pts'][o])) < 1.5]
        lead = MultiPoint(lead) if lead else None
        others, nends = neighbour_roads()
        ptree = None
        if plots:
            from shapely.geometry import Polygon
            ppolys = [Polygon(q['poly']) for q in plots if len(q['poly']) >= 3]
            ptree = STRtree(ppolys)
        for r, t, hw, x in tails:
            if others is not None and x.intersection(others).length > 0.5 * x.length:
                continue        # a neighbouring batch's road already runs here (its seam edge reaches the game road's end)
            a, b = Point(x.coords[0]), Point(x.coords[-1])
            for p_, q_ in ((a, b), (b, a)):
                at_edge = edge.distance(q_) < 1.5 and nends is not None and nends.distance(q_) < 3.0
                if covered_poly.distance(p_) < 0.5 and (at_edge or (lead is not None and lead.distance(q_) < 1.5)):
                    _, half, walk, _ = classify(t)
                    foot = x.buffer(half + walk)
                    if ptree is not None and any(ppolys[int(i)].intersects(foot) for i in ptree.query(foot)):
                        blocked.append({'id': r['id'], 'name': t.get('name:en') or t.get('name'), 'from': [round(v) for v in x.coords[0]],
                                        'to': [round(v) for v in x.coords[-1]], 'length': round(x.length)})
                        break   # batch 0.5's buildings stand on it: the plots must be rebuilt first (reported, not built)
                    new_tails += add(new, r, t, hw, x, clip, inner)
                    break
    return {'new': new, 'covered': covered, 'tails': new_tails, 'tails_blocked': blocked}


def neighbour_roads():
    """the batch 1-3 roads built so far (roads.py profiles): their centre lines buffered 8 studs, and their end points
    (or None, None)"""
    import json, os
    from geo import BUILD
    lines, ends = [], []
    for tag in ('1', '2', '3'):
        p = os.path.join(BUILD, 'city', 'roads_%s_profile.json' % tag)
        if os.path.exists(p):
            for e in json.load(open(p)):
                if len(e['pts']) > 1:
                    lines.append(LineString([(q[0], q[2]) for q in e['pts']]).buffer(8))
                    ends += [(e['pts'][0][0], e['pts'][0][2]), (e['pts'][-1][0], e['pts'][-1][2])]
    if not lines:
        return None, None
    from shapely.geometry import MultiPoint
    return unary_union(lines), MultiPoint(ends)


def add(new, r, t, hw, p, clip, inner):
    cls, half, walk, n = classify(t)
    one, _ = lanes_each_way(t)
    cut = [p]
    if clip and not p.within(inner):
        q = p.intersection(inner)
        cut = [q] if q.geom_type == 'LineString' else [x for x in getattr(q, 'geoms', []) if x.geom_type == 'LineString']
    k = 0
    for p in cut:
        if p.is_empty or p.length < CLIP_MIN:
            continue
        new.append({'id': r['id'], 'name': t.get('name:en') or t.get('name'), 'hw': hw, 'cls': cls, 'half': half,
                    'walk': walk, 'lanes': n, 'oneway': one, 'bridge': bool(t.get('bridge')),
                    'layer': int(t.get('layer', 0) or 0) if str(t.get('layer', '0')).lstrip('-').isdigit() else 0,
                    'pts': [[round(x, 2), round(z, 2)] for x, z in p.coords]})
        k += 1
    return k


if __name__ == '__main__':
    import json, os, sys
    from geo import MAP, BOX_05, BUILD
    sys.stdout.reconfigure(encoding='utf-8')
    gr = json.load(open(os.path.join(MAP, 'ygn_roads_v5.json'), encoding='utf-8'))
    pp = os.path.join(BUILD, 'city', 'plots_05.json')
    net = network(BOX_05, gr, plots=json.load(open(pp, encoding='utf-8'))['plots'] if os.path.exists(pp) else None)
    print('seam tails added:', net['tails'], '| blocked by batch 0.5 buildings:', net['tails_blocked'])
    by = {}
    for s in net['new']:
        L = LineString(s['pts']).length
        by.setdefault(s['cls'], [0, 0.0])
        by[s['cls']][0] += 1
        by[s['cls']][1] += L
    for k, (n, L) in by.items():
        print(f'{k:7s} {n:5d} pieces {L / 1.6 / 1000:6.1f} km real')
    print('covered OSM ways:', len(set(net['covered'])))
    big = {}
    for s in net['new']:
        if s['cls'] == 'big':
            big[s['name']] = big.get(s['name'], 0) + LineString(s['pts']).length / 1.6
    for k, v in sorted(big.items(), key=lambda kv: -kv[1]):
        print('  big not in game:', k, round(v), 'm')
    os.makedirs(os.path.join(BUILD, 'city'), exist_ok=True)
    json.dump(net, open(os.path.join(BUILD, 'city', 'network_05.json'), 'w', encoding='utf-8'), ensure_ascii=False)
