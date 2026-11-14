"""Whole-Yangon map (14 Nov 2026): the trees (and lake embankments) of a BATCH, d20_green.py's rules on the batch's own ground.

Owner: "do all the steps until the entire yangon map is finished"; Yangon is very green (big rain trees in every compound and
along the roads; reference study of batch 0.5). Data: OpenStreetMap (build/osm_ygn, ODbL), the batch's roads / plots / lanes
(batchgeo.py), its detail layer when made (build/city/details_<tag>.json: trees keep off its items).

Writes build/city/YangonGreenData_<tag>_<n>.luau (one string each, < 185,000 bytes) in YangonGreen's line format:
  S x1 z1 x2 z2 nx nz     a shore segment of an embankment (n = inland, away from the water)
  P x z                   a park tree spot (denser)
  T x z s k               a city tree (s = size 0.8..1.5, k = R rain tree / M mango / P palm); the OSM natural=tree trees
                          are T lines too (k = R, at their real spot)
  B x z fx fz             a bench on the walkway, facing (fx, fz) = the water
  L x z                   a walkway lamp
for tools/yangon/YangonGreenBatch.luau (Workspace.Yangon.Green_<tag>).

Embankments: where a lake's shore runs within 130 of a main road (d20's rule), and all round Kandawgyi Lake (its real
boardwalk; owner's lead, 14 Nov): segments <= 24 long, benches and lamps every 44 (lamps half way between), a row of trees 17
inland. Trees: never on a road or its pavement (+ 3), a building (+ 4), water (+ 6), a lot, a landmark's ground, under a deck,
on a detail item; parks 24 apart, the city 46 apart (d20's SPACING / PARK_SPACING), OSM trees 6 apart.

Run from Games/CityLegends/tools/yangon/city:  python green.py <tag>
"""
import json, math, os, random, re, sys

import numpy as np
import shapely
from shapely.geometry import LineString, Point, Polygon
from shapely.ops import unary_union
from shapely.strtree import STRtree

import geo
import batchgeo

OUT = os.path.join(geo.BUILD, 'city')
NL = chr(10)
SPACING, PARK_SPACING, OSM_SPACING = 46.0, 24.0, 6.0
MAX_BYTES = 185000


def main(tag):
    sys.stdout.reconfigure(encoding='utf-8')
    B = batchgeo.load(tag)
    rng = random.Random(20261114 + int(tag))
    t0 = __import__('time').time()
    road3 = B.PAVE.buffer(3)
    water6 = B.WATER_RAW.buffer(6) if not B.WATER_RAW.is_empty else Polygon()
    for g in (road3, water6):
        shapely.prepare(g)
    # the venue lots and the roundabout of batch 0.5 (d19's top) reach no batch, but a lot near the seam would
    src = open(os.path.join(geo.ROOT, 'tools', 'yangon', 'd19_buildings.py'), encoding='utf-8').read()
    ns = {'__file__': os.path.join(geo.ROOT, 'tools', 'yangon', 'd19_buildings.py')}
    exec(compile(src[:src.index('# ---------------------------------------------------------------- the OSM buildings')], 'd19', 'exec'), ns)
    blk = unary_union([Polygon(ns['rect'](*s, grow=10)) for s in ns['SITES']])
    shapely.prepare(blk)
    # the detail layer's items (if made): anchors + their footprint boxes
    items = []
    dj = os.path.join(OUT, 'details_%s.json' % tag)
    if os.path.exists(dj):
        for it in json.load(open(dj, encoding='utf-8'))['items']:
            r = max(it['ex'], it['ez']) + 3 if it['ex'] or it['ez'] else 3.0
            items.append(Point(it['x'], it['z']).buffer(r))
    itree = STRtree(items) if items else None
    print('  ground masks %.0f s, %d detail items' % (__import__('time').time() - t0, len(items)))

    def ok_ground(x, z, road=True):
        p = Point(x, z)
        if not B.inside(x, z, 4):
            return False
        if road and road3.contains(p):
            return False
        if not road and B.CARR.intersects(p.buffer(1.5)):
            return False
        if water6.contains(p) or blk.contains(p) or B.LMZ.contains(p) or B.DECK_ZONE.contains(p):
            return False
        if len(B.PTREE.query(p.buffer(4 if road else 2), predicate='intersects')):
            return False
        if itree is not None and len(itree.query(p, predicate='intersects')):
            return False
        return True

    grid = {}

    def free_spot(x, z, spacing):
        k = (int(x // 50), int(z // 50))
        reach = int(spacing // 50) + 1
        for dx in range(-reach, reach + 1):
            for dz in range(-reach, reach + 1):
                for (qx, qz) in grid.get((k[0] + dx, k[1] + dz), ()):
                    if math.hypot(qx - x, qz - z) < spacing:
                        return False
        return True

    def put(x, z):
        grid.setdefault((int(x // 50), int(z // 50)), []).append((x, z))

    # ---------------------------------------------------------------- embankments
    mains = [e for e in B.EDGES if e['main']]
    mtree = STRtree([e['line'] for e in mains]) if mains else None
    lakes = []
    for a in geo.load('areas'):
        t = a['t']
        if not (t.get('natural') == 'water' or t.get('water') in ('lake', 'pond', 'reservoir')) or t.get('water') == 'river':
            continue
        pp = geo.proj(a['p'])
        if len(pp) < 4:
            continue
        pg = Polygon(pp).buffer(0)
        if pg.area < 20000 or not pg.intersects(B.REGION):
            continue
        name = (t.get('name:en') or t.get('name') or '')
        lakes.append((pg.simplify(1.0), 'kandawgyi' in name.lower() or 'ကန်တော်ကြီး' in name, name))
    segs = []
    for pg, whole, name in lakes:
        if pg.geom_type != 'Polygon':
            continue
        ring = list(pg.exterior.coords)
        n0 = len(segs)
        for i in range(len(ring) - 1):
            a, b = ring[i], ring[i + 1]
            L = math.hypot(b[0] - a[0], b[1] - a[1])
            if L < 2:
                continue
            mx, mz = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
            if not B.inside(mx, mz, 2):
                continue
            if not whole and (mtree is None or not len(mtree.query(Point(mx, mz).buffer(130), predicate='intersects'))):
                continue
            nx, nz = -(b[1] - a[1]) / L, (b[0] - a[0]) / L
            if pg.contains(Point(mx + nx * 6, mz + nz * 6)):
                nx, nz = -nx, -nz
            w = Point(mx + nx * 6, mz + nz * 6)
            # the walkway (inland 2..10) must not be on a road, a building, a landmark's ground (Karaweik)
            if B.PAVE.contains(w) or B.LMZ.contains(w) or len(B.PTREE.query(w.buffer(4), predicate='intersects')):
                continue
            k = max(1, int(L // 24))
            for j in range(k):
                t0_, t1_ = j / k, (j + 1) / k
                segs.append((a[0] + (b[0] - a[0]) * t0_, a[1] + (b[1] - a[1]) * t0_, a[0] + (b[0] - a[0]) * t1_, a[1] + (b[1] - a[1]) * t1_, nx, nz))
        if len(segs) > n0:
            print('  embankment: %s %d segments%s' % (name or 'a lake', len(segs) - n0, ' (the whole shore)' if whole else ''))
    bench, lamps, row_trees = [], [], []
    walked = 0.0
    for (x1, z1, x2, z2, nx, nz) in segs:
        L = math.hypot(x2 - x1, z2 - z1)
        t = 0.0
        while t < L:
            x, z = x1 + (x2 - x1) * t / L, z1 + (z2 - z1) * t / L
            phase = walked % 44
            if phase < 1:
                bench.append((x + nx * 4, z + nz * 4, -nx, -nz))
            if abs(phase - 22) < 1:
                lamps.append((x + nx * 11, z + nz * 11))
            if phase < 1 or abs(phase - 22) < 1:
                tx, tz = x + nx * 17, z + nz * 17
                if ok_ground(tx, tz) and free_spot(tx, tz, 12):
                    row_trees.append((tx, tz))
                    put(tx, tz)
            t += 1.0
            walked += 1.0
    # ---------------------------------------------------------------- the OSM trees (real spots)
    osm_trees = []
    for p in geo.load('points'):
        if p['v'] != 'tree':
            continue
        x, z = geo.world(*p['p'])
        if ok_ground(x, z, road=False) and free_spot(x, z, OSM_SPACING):
            osm_trees.append((x, z))
            put(x, z)
    # ---------------------------------------------------------------- parks, then the city
    parks = []
    for a in geo.load('areas'):
        t = a['t']
        if t.get('leisure') in ('park', 'garden') or t.get('landuse') in ('grass', 'forest', 'recreation_ground', 'village_green') or \
                t.get('natural') in ('wood', 'scrub'):
            pp = geo.proj(a['p'])
            if len(pp) >= 3:
                pg = Polygon(pp).buffer(0)
                if pg.intersects(B.REGION):
                    parks.append(pg)
    park_trees, city_trees = [], []
    for pg in parks:
        b = pg.bounds
        for _ in range(int(pg.area / (PARK_SPACING * PARK_SPACING) * 1.6) + 4):
            x, z = rng.uniform(b[0], b[2]), rng.uniform(b[1], b[3])
            if pg.contains(Point(x, z)) and ok_ground(x, z) and free_spot(x, z, PARK_SPACING):
                park_trees.append((x, z))
                put(x, z)
    b = B.REGION.bounds
    tries = int(B.REGION.area / (SPACING * SPACING) * 2.2)
    for _ in range(tries):
        x, z = rng.uniform(b[0], b[2]), rng.uniform(b[1], b[3])
        if free_spot(x, z, SPACING) and ok_ground(x, z):
            city_trees.append((x, z))
            put(x, z)
    # ---------------------------------------------------------------- write
    lines = ['S %.1f %.1f %.1f %.1f %.3f %.3f' % s for s in segs]
    lines += ['P %.1f %.1f' % q for q in row_trees + park_trees]
    for (x, z) in osm_trees:
        lines.append('T %.1f %.1f %.2f R' % (x, z, rng.uniform(0.9, 1.4)))
    for (x, z) in city_trees:
        k = rng.random()
        lines.append('T %.1f %.1f %.2f %s' % (x, z, rng.uniform(0.8, 1.5), 'R' if k < 0.55 else ('M' if k < 0.85 else 'P')))
    lines += ['B %.1f %.1f %.3f %.3f' % q for q in bench]
    lines += ['L %.1f %.1f' % q for q in lamps]
    for f in os.listdir(OUT):
        if re.match(r'YangonGreenData_%s_\d+\.luau$' % tag, f):
            os.remove(os.path.join(OUT, f))
    chunks, cur, size = [], [], 0
    for ln in lines:
        if size + len(ln) + 1 > MAX_BYTES - 300:
            chunks.append(cur)
            cur, size = [], 0
        cur.append(ln)
        size += len(ln) + 1
    chunks.append(cur)
    for k, c in enumerate(chunks, 1):
        txt = ('-- generated by tools/yangon/city/green.py %s: batch %s trees and lake embankments, part %d of %d (see its header; OSM ODbL)' % (tag, tag, k, len(chunks))
               + NL + 'return [==[' + NL + NL.join(c) + NL + ']==]' + NL)
        path = os.path.join(OUT, 'YangonGreenData_%s_%d.luau' % (tag, k))
        open(path, 'w', encoding='utf-8', newline=NL).write(txt)
        print('%s %d bytes' % (os.path.relpath(path, geo.ROOT), len(txt.encode('utf-8'))))
    n_trees = len(row_trees) + len(park_trees) + len(osm_trees) + len(city_trees)
    parts = 3 * n_trees + 3 * len(segs) + 4 * len(bench) + 2 * len(lamps)
    print('green %s: shore segments %d, benches %d, lamps %d; trees: row %d, park %d, OSM %d, city %d; about %d parts' % (
        tag, len(segs), len(bench), len(lamps), len(row_trees), len(park_trees), len(osm_trees), len(city_trees), parts))
    # ---------------------------------------------------------------- self-test (the same rules, read back from the files)
    bad = 0
    for ln in lines:
        w = ln.split()
        if w[0] in ('P', 'T'):
            x, z = float(w[1]), float(w[2])
            p = Point(x, z)
            if B.CARR.intersects(p.buffer(1.2)) or len(B.PTREE.query(p.buffer(1.2), predicate='intersects')) or not B.REGION.contains(p) \
                    or B.WATER_RAW.contains(p) or B.LMZ.contains(p):
                bad += 1
    print('green test: %d trees on a carriageway / lane, a building, water, a landmark or outside the batch -> %s' % (bad, 'PASS' if not bad else 'FAIL'))
    return 0 if not bad else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else '1'))
