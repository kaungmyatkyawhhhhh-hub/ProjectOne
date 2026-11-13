"""Whole-Yangon map, A1 (14 Nov 2026): the lane survey's OSM half.

For every named road of class tertiary or bigger in build/osm_ygn/roads.json: total length, how much is one-way (a divided
road is drawn in OSM as two one-way ways), the lanes each way (one-way ways: their `lanes`; two-way ways: `lanes` / 2, or
lanes:forward / backward), and a sample point for the satellite check. Writes build/plan/lane_survey_osm.json and prints a table.
Run from Games/CityLegends: python tools/yangon/city/lane_survey.py
"""
import collections, json, math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
KX = 111320 * math.cos(math.radians(16.82))
KY = 110540
BIG = ('motorway', 'trunk', 'primary', 'secondary', 'tertiary', 'motorway_link', 'trunk_link', 'primary_link', 'secondary_link')


def length(p):
    return sum(math.hypot((b[0] - a[0]) * KX, (b[1] - a[1]) * KY) for a, b in zip(p, p[1:]))


def per_dir(t):
    one = t.get('oneway') in ('yes', '-1', 'true', '1')
    try:
        if one:
            return one, float(t['lanes'])
        if 'lanes:forward' in t:
            return one, float(t['lanes:forward'])
        return one, float(t['lanes']) / 2
    except (KeyError, ValueError):
        return one, None


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    roads = json.load(open(os.path.join(ROOT, 'build', 'osm_ygn', 'roads.json'), encoding='utf-8'))['roads']
    agg = collections.defaultdict(lambda: {'len': 0.0, 'one': 0.0, 'lanes': collections.Counter(), 'cls': collections.Counter(),
                                           'bridge': 0.0, 'pts': []})
    for r in roads:
        t = r['t']
        if t.get('highway') not in BIG:
            continue
        name = t.get('name:en') or t.get('name')
        if not name:
            continue
        L = length(r['p'])
        a = agg[name]
        a['len'] += L
        one, ln = per_dir(t)
        if one:
            a['one'] += L
        if t.get('bridge'):
            a['bridge'] += L
        a['lanes'][ln] += L
        a['cls'][t['highway']] += L
        mid = r['p'][len(r['p']) // 2]
        a['pts'].append((L, mid))
    out = []
    for name, a in sorted(agg.items(), key=lambda kv: -kv[1]['len']):
        if a['len'] < 300:
            continue
        known = {k: v for k, v in a['lanes'].items() if k}
        lanes = max(known, key=known.get) if known else None
        sample = max(a['pts'])[1]
        out.append({'name': name, 'class': a['cls'].most_common(1)[0][0], 'len_m': round(a['len']), 'oneway_share': round(a['one'] / a['len'], 2),
                    'lanes_each_way': lanes, 'lanes_known_share': round(sum(known.values()) / a['len'], 2),
                    'lanes_mix': {str(k): round(v) for k, v in a['lanes'].most_common(4)}, 'bridge_m': round(a['bridge']),
                    'sample': sample})
    os.makedirs(os.path.join(ROOT, 'build', 'plan'), exist_ok=True)
    json.dump(out, open(os.path.join(ROOT, 'build', 'plan', 'lane_survey_osm.json'), 'w', encoding='utf-8'), indent=1, ensure_ascii=False)
    for o in out:
        print(f"{o['name'][:34]:34s} {o['class']:10s} {o['len_m']:6d} one {o['oneway_share']:.2f} lanes/way {o['lanes_each_way']} "
              f"(known {o['lanes_known_share']:.2f}) @ {o['sample'][1]:.4f},{o['sample'][0]:.4f}")
    print(len(out), 'roads')


if __name__ == '__main__':
    main()
