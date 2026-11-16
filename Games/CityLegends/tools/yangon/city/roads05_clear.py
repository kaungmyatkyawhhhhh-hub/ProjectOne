"""Clearance check for the roads05 roads (16 Nov 2026): building shells (buildings_<tag>/Shell_*.txt "S" boxes) and street
props (street_<tag>/items.json positions, when present) against the new carriageways and pavements.

    YANGON_SCALE=1to1 python roads05_clear.py <tags joined by _> <district tag> [<district tag> ...]
-> prints counts and the worst overlaps, writes build/city_1to1/roads05_<tags>/clear_<district>.json
"""
import glob, json, math, os, sys

import numpy as np
from shapely.geometry import Polygon, Point, box as sbox
from shapely.ops import unary_union
from shapely.strtree import STRtree

sys.stdout.reconfigure(encoding='utf-8')
import geo
from roads05_view import strip, runs


def road_polys(data):
    cut = {k: set(v) for k, v in data['cut'].items()}
    cw, pv = [], []
    for r in data['roads']:
        s = r['s']
        c = cut.get(r['name'], set())
        for a, b in runs([i not in c for i in range(len(s))]):
            if b - a < 1:
                continue
            rng = range(a, b + 1)
            g = strip(s, lambda q: -q[6], lambda q: q[7], rng)
            if g is not None and not g.is_empty:
                cw.append((r['name'], g))
            for lo, hi in ((lambda q: -q[6] - r.get('walkL', 7.5), lambda q: -q[6]), (lambda q: q[7], lambda q: q[7] + r.get('walkR', 7.5))):
                g = strip(s, lo, hi, rng)
                if g is not None and not g.is_empty:
                    pv.append((r['name'], g))
    for g in data.get('roundabouts', []):
        cw.append((g['name'], Point(g['c'][0], g['c'][2]).buffer(g['r_out'], 64).difference(Point(g['c'][0], g['c'][2]).buffer(g['r_in'], 64))))
    return cw, pv


def shells(tag):
    out = []
    for f in glob.glob(os.path.join(geo.BUILD, 'city_1to1', 'buildings_%s' % tag, 'Shell_*.txt')):
        for ln in open(f, encoding='utf-8'):
            p = ln.split()
            if not p or p[0] != 'S':
                continue
            cx, cy, cz, sx, sy, sz, yaw = map(float, p[2:9])
            c, s_ = math.cos(yaw), math.sin(yaw)
            pts = []
            for dx, dz in ((-sx / 2, -sz / 2), (sx / 2, -sz / 2), (sx / 2, sz / 2), (-sx / 2, sz / 2)):
                # (Roblox yaw about +Y: x' = x cos + z sin, z' = -x sin + z cos)
                pts.append((cx + dx * c + dz * s_, cz - dx * s_ + dz * c))
            out.append(Polygon(pts))
    return out


def main(tag, districts):
    D = os.path.join(geo.BUILD, 'city_1to1', 'roads05_' + tag)
    data = json.load(open(os.path.join(D, 'roads.json'), encoding='utf-8'))
    cw, pv = road_polys(data)
    cwt = STRtree([g for _, g in cw])
    for t in districts:
        S = shells(t)
        bad_cw, bad_pv = [], 0
        for b in S:
            hit = 0.0
            for j in cwt.query(b):
                hit += b.intersection(cw[int(j)][1]).area
            if hit > 4.0:
                bad_cw.append((round(hit, 1), [round(v) for v in b.centroid.coords[0]], cw[int(cwt.query(b)[0])][0]))
        bad_cw.sort(reverse=True)
        res = dict(district=t, shells=len(S), on_carriageway=len(bad_cw), worst=bad_cw[:20])
        json.dump(res, open(os.path.join(D, 'clear_%s.json' % t), 'w'), indent=1)
        print(json.dumps(res)[:1500])


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2:])
