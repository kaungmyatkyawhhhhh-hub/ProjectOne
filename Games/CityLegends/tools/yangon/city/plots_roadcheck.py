"""plots_roadcheck.py <tag> [--fix]: do any building plots stand on the batch's roads AS BUILT? (15 Nov 2026)

Reads build/city/plots_<tag>.json and the road collision boxes build/city/RoadCollide_<tag>_*.luau (the same boxes that are in
Workspace.Yangon.RoadCollideB<tag>: "cx cy cz dx dy dz width walk kind"; R carriageway, J junction square, M median, D deck,
P pavement, W parapet). A plot that covers more than 2 square studs of a carriageway / junction / median / deck box, or more
than 6 % of its own area of pavement, is listed. --fix clips such plots off the boxes (+1 stud) and drops what is left under
40 square studs or under 60 % of the plot (the same rules as plots.py), then writes the plots file back.
"""
import glob
import json
import math
import os
import sys

from shapely.geometry import Polygon
from shapely.ops import unary_union
from shapely.strtree import STRtree

HERE = os.path.dirname(os.path.abspath(__file__))
CITY = os.path.join(HERE, '..', '..', '..', 'build', 'city')


def boxes(tag):
    out = {'car': [], 'pave': []}
    for path in glob.glob(os.path.join(CITY, f'RoadCollide_{tag}_*.luau')):
        for line in open(path, encoding='utf-8'):
            w = line.split()
            if len(w) < 9:
                continue
            try:
                cx, cy, cz, dx, dy, dz, width = (float(v) for v in w[:7])
            except ValueError:
                continue
            kind = w[-1]
            L = math.hypot(dx, dz)
            if L < 0.05:
                continue
            ux, uz = dx / L, dz / L
            rx, rz = -uz, ux
            h = width / 2
            pts = [(cx + ux * L / 2 * a + rx * h * b, cz + uz * L / 2 * a + rz * h * b) for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
            g = Polygon(pts)
            if kind in ('R', 'J', 'M', 'D'):
                out['car'].append(g)
            elif kind == 'P':
                out['pave'].append(g)
    return out


def main(tag, fix):
    path = os.path.join(CITY, f'plots_{tag}.json')
    d = json.load(open(path, encoding='utf-8'))
    bx = boxes(tag)
    print('boxes: carriageway', len(bx['car']), 'pavement', len(bx['pave']))
    car_t, pave_t = STRtree(bx['car']), STRtree(bx['pave'])
    bad = []
    for p in d['plots']:
        g = Polygon(p['poly']).buffer(0)
        car = sum(g.intersection(bx['car'][j]).area for j in car_t.query(g, predicate='intersects'))
        pav = sum(g.intersection(bx['pave'][j]).area for j in pave_t.query(g, predicate='intersects'))
        if car > 2 or pav > 0.06 * g.area:
            bad.append((p, g, car, pav))
    print('plots', len(d['plots']), 'on a carriageway / pavement:', len(bad))
    for p, g, car, pav in sorted(bad, key=lambda t: -t[2])[:25]:
        c = g.centroid
        print('  %-14s %-10s %6.0f on road, %6.0f on pavement (area %6.0f) at %.0f %.0f' % (p['id'], p['style'], car, pav, g.area, c.x, c.y))
    if fix and bad:
        drop, clipped = set(), 0
        for p, g, car, pav in bad:
            near = [bx['car'][j] for j in car_t.query(g.buffer(2), predicate='intersects')] + \
                   [bx['pave'][j] for j in pave_t.query(g.buffer(2), predicate='intersects')]
            q = g.difference(unary_union(near).buffer(1.0))
            if q.geom_type != 'Polygon':
                q = max(q.geoms, key=lambda t: t.area) if hasattr(q, 'geoms') and len(q.geoms) else None
            if q is None or q.is_empty or q.area < 40 or q.area < 0.6 * g.area:
                drop.add(p['id'])
                continue
            q = q.simplify(0.4, preserve_topology=True)
            pts = list(q.exterior.coords)[:-1]
            if not q.exterior.is_ccw:
                pts = pts[::-1]
            p['poly'] = [[round(x, 2), round(z, 2)] for x, z in pts]
            p['front'] = None if p.get('front') is not None and p['front'] >= len(pts) else p.get('front')
            clipped += 1
        d['plots'] = [p for p in d['plots'] if p['id'] not in drop]
        json.dump(d, open(path, 'w', encoding='utf-8'), separators=(',', ':'))
        print('fixed: clipped', clipped, 'dropped', len(drop), '->', len(d['plots']), 'plots')


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    main(sys.argv[1], '--fix' in sys.argv)
