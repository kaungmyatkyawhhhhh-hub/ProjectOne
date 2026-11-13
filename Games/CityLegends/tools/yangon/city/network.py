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


def network(box, game_roads, min_len=24.0):
    area = sbox(box[0] - 200, box[1] - 200, box[2] + 200, box[3] + 200)
    covered_poly = game_corridors(game_roads) if game_roads else None
    new, covered = [], []
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
                if inside > 0.6 * g.length:
                    covered.append(r['id'])
                    continue
                g2 = g.difference(covered_poly)
                pieces = [g2] if g2.geom_type == 'LineString' else [x for x in getattr(g2, 'geoms', []) if x.geom_type == 'LineString']
            else:
                pieces = [g]
            for p in pieces:
                if p.length < min_len:
                    continue
                new.append({'id': r['id'], 'name': t.get('name:en') or t.get('name'), 'hw': hw, 'cls': cls, 'half': half,
                            'walk': walk, 'lanes': n, 'oneway': one, 'bridge': bool(t.get('bridge')),
                            'layer': int(t.get('layer', 0) or 0) if str(t.get('layer', '0')).lstrip('-').isdigit() else 0,
                            'pts': [[round(x, 2), round(z, 2)] for x, z in p.coords]})
    return {'new': new, 'covered': covered}


if __name__ == '__main__':
    import json, os, sys
    from geo import MAP, BOX_05, BUILD
    sys.stdout.reconfigure(encoding='utf-8')
    gr = json.load(open(os.path.join(MAP, 'ygn_roads_v5.json'), encoding='utf-8'))
    net = network(BOX_05, gr)
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
