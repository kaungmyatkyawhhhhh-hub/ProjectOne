"""Test for the Yangon detail layer (details.py -> build/city/details_05.json + Details_05_<n>.luau).

Checks, from the files alone (it does not import details.py's geometry):
  1. no part of any item lies on a road carriageway (the game's part roads between their cuts, the flyover decks, the
     roundabout, and the new mesh streets) or inside a building plot (plots_05.json), with these by-design exceptions:
       * parts whose underside is 14+ studs over the item's ground (signal arms and heads, footbridge decks and rails,
         pole crossarms: overhead, over the road on purpose);
       * kind "patch" (road patches lie ON the asphalt, 0.06 over it);
       * a GreenKit tree counts as its trunk (a circle of 1.2): its crown overhangs.
     An overlap is an intersection of more than 0.05 square studs in plan.
  2. footbridges: at least 17 studs from the road under them to the lowest part over the carriageway.
  3. the data modules: each under 190,000 bytes, `return [==[ ... ]==]`, and they hold exactly the JSON's items and parts.
Prints the counts and the parts per kind (prototypes and kit trees included).

Run from Games/CityLegends/tools/yangon/city:  python details_test.py
"""
import glob, json, math, os, re, sys

from shapely.geometry import LineString, MultiPoint, Point, Polygon
from shapely.ops import unary_union
from shapely.strtree import STRtree

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import geo

OVERHEAD = 14.0
TOL = 0.05


def rot(v, ry, rx, rz):
    x, y, z = v
    c, s = math.cos(rz), math.sin(rz)
    x, y = x * c - y * s, x * s + y * c
    c, s = math.cos(rx), math.sin(rx)
    y, z = y * c - z * s, y * s + z * c
    c, s = math.cos(ry), math.sin(ry)
    x, z = x * c + z * s, -x * s + z * c
    return x, y, z


def part_geo(it, q):
    """plan polygon, bottom and top (relative to the item's ground) of a part [shape, sx, sy, sz, ox, oy, oz, ry, rx, rz, ...]
    (angles in radians in the JSON)"""
    shape, sx, sy, sz, ox, oy, oz, ry, rx, rz = q[:10]
    if shape == 'S':
        sy = sz = sx
    cy, sy_ = math.cos(it['yaw']), math.sin(it['yaw'])
    pts, lo, hi = [], 1e9, -1e9
    for a in (-0.5, 0.5):
        for b in (-0.5, 0.5):
            for c in (-0.5, 0.5):
                x, y, z = rot((a * sx, b * sy, c * sz), ry, rx, rz)
                x, y, z = x + ox, y + oy, z + oz
                pts.append((it['x'] + x * cy + z * sy_, it['z'] - x * sy_ + z * cy))
                lo, hi = min(lo, y), max(hi, y)
    return MultiPoint(pts).convex_hull, lo, hi


def carriageways():
    game = json.load(open(os.path.join(geo.MAP, 'ygn_roads_v5.json'), encoding='utf-8'))
    out = []
    for r in game['roads']:
        cs = set(game.get('cut', {}).get(r['name'], []))
        run = []
        for k, s in enumerate(r['s'] + [None]):
            if s is None or k in cs:
                if len(run) > 1:
                    out.append(('game ' + r['name'], LineString([(q[0], q[2]) for q in run]).buffer(max(max(q[6], q[7]) for q in run), cap_style=2)))
                run = []
                continue
            run.append(s)
    for d in game['decks']:
        out.append(('deck ' + d['name'], LineString([(q[0], q[2]) for q in d['s']]).buffer(32, cap_style=2)))
    out.append(('roundabout', Point(29072.0, 1172.8).buffer(108)))
    st = json.load(open(os.path.join(geo.BUILD, 'city', 'streets_05.json'), encoding='utf-8'))['streets']
    for s in st:
        out.append(('street ' + str(s['name']), LineString(s['pts']).buffer(s['half'], cap_style=2, join_style=1)))
    return out


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    D = json.load(open(os.path.join(geo.BUILD, 'city', 'details_05.json'), encoding='utf-8'))
    items, protos = D['items'], D['protos']
    carr = carriageways()
    ctree = STRtree([g for _, g in carr])
    plots = json.load(open(os.path.join(geo.BUILD, 'city', 'plots_05.json'), encoding='utf-8'))['plots']
    ppoly = [Polygon(p['poly']).buffer(0) for p in plots]
    ptree = STRtree(ppoly)
    per = {}
    bad = {}
    examples = []
    for it in items:
        k = per.setdefault(it['kind'], [0, 0])
        k[0] += 1
        parts = list(it['parts'])
        for u in it['uses']:
            parts += protos[u]
        k[1] += len(parts) + sum(3 + (1 if kit[2] else 0) for kit in it['kits'])
        if it['kind'] == 'patch':
            continue
        geoms = []
        for q in parts:
            g, lo, hi = part_geo(it, q)
            if lo >= OVERHEAD:
                continue
            geoms.append(g)
        for kit in it['kits']:
            geoms.append(Point(it['x'], it['z']).buffer(1.2))
        if not geoms:
            continue
        fp = unary_union(geoms)
        why = None
        for i in ctree.query(fp, predicate='intersects'):
            a = carr[int(i)][1].intersection(fp).area
            if a > TOL:
                why = 'carriageway (%s, %.2f sq)' % (carr[int(i)][0], a)
                break
        if not why:
            for i in ptree.query(fp, predicate='intersects'):
                a = ppoly[int(i)].intersection(fp).area
                if a > TOL:
                    why = 'plot %s (%.2f sq)' % (plots[int(i)]['id'], a)
                    break
        if why:
            bad[it['kind']] = bad.get(it['kind'], 0) + 1
            if len(examples) < 25:
                examples.append('%s at %.0f, %.0f: %s' % (it['kind'], it['x'], it['z'], why))
    # footbridge clearance: the lowest part over a carriageway, from the item's ground (the road under it)
    fb = []
    for it in items:
        if it['kind'] != 'footbridge':
            continue
        low = 1e9
        for q in it['parts']:
            g, lo, hi = part_geo(it, q)
            if ctree.query(g, predicate='intersects').size and any(carr[int(i)][1].intersection(g).area > TOL for i in ctree.query(g, predicate='intersects')):
                low = min(low, lo)
        fb.append((it['name'], it['x'], it['z'], low))
    # the data modules
    mods = sorted(glob.glob(os.path.join(geo.BUILD, 'city', 'Details_05_*.luau')), key=lambda p: int(re.findall(r'_(\d+)\.luau$', p)[0]))
    n_items = n_parts = 0
    ok_mods = True
    for m in mods:
        raw = open(m, 'rb').read()
        txt = raw.decode('utf-8')
        if len(raw) >= 190000 or 'return [==[' not in txt or not txt.rstrip().endswith(']==]'):
            ok_mods = False
            print('BAD MODULE', m, len(raw))
        body = txt.split('return [==[', 1)[1].rsplit(']==]', 1)[0]
        inproto = False
        for line in body.split('\n'):
            c = line[:1]
            if c == 'D':
                inproto = True
            elif c == 'E':
                inproto = False
            elif c == 'I':
                n_items += 1
            elif c in 'BCHSW' and line and not inproto:
                n_parts += 1
    json_parts = sum(len(it['parts']) for it in items)
    print('%-12s %7s %8s %9s' % ('kind', 'items', 'parts', 'overlaps'))
    for k, (n, p) in sorted(per.items(), key=lambda kv: -kv[1][1]):
        print('%-12s %7d %8d %9d' % (k, n, p, bad.get(k, 0)))
    total = sum(p for _, p in per.values())
    print('%-12s %7d %8d %9d' % ('TOTAL', len(items), total, sum(bad.values())))
    print()
    for e in examples:
        print('  overlap:', e)
    print('footbridges (lowest part over a carriageway, studs over the road):')
    for name, x, z, low in fb:
        print('  %-24s at %.0f, %.0f: %s' % (name, x, z, 'not over a road' if low > 1e8 else '%.2f' % low))
    print('modules: %d, %d items and %d inline parts in them (JSON: %d items, %d parts)%s' % (
        len(mods), n_items, n_parts, len(items), json_parts, '' if ok_mods else '  MODULE PROBLEM'))
    fails = []
    if sum(bad.values()):
        fails.append('%d items overlap a carriageway or a plot' % sum(bad.values()))
    if any(low < 17 for _, _, _, low in fb):
        fails.append('a footbridge under 17 studs')
    if not ok_mods or n_items != len(items) or n_parts != json_parts:
        fails.append('modules do not match the JSON')
    if total > 25000:
        fails.append('over the 25,000-part budget')
    print('RESULT:', 'PASS' if not fails else 'FAIL: ' + '; '.join(fails))
    return 0 if not fails else 1


if __name__ == '__main__':
    sys.exit(main())
