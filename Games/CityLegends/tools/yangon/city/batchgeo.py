"""Whole-Yangon map (14 Nov 2026): what the detail layer, the trees and the street lamps of a BATCH (1, 2, 3) must know about
the ground: its outline, its roads (as built by roads.py), lanes, buildings, water, landmark grounds and decks.

  load(tag) -> Bundle with
    REGION          the batch outline (geo.batch_poly) minus batch 0.5's box; inside(x, z, margin)
    EDGES           every road edge of the batch (roads_<tag>_profile.json) with:
                      line, pts (x, z), ys (surface), hs {+1: offset of the carriageway edge on the right-hand normal
                      (-dz, dx), -1: on the other side}, sides (the sides with a kerb or edge strip: a one-way carriageway of
                      a divided road has none on its median side), walk, flush (no raised pavement: residential streets
                      without traffic), main, kind (route = 2+ lanes each way, big, street, lane), lanes {way: n},
                      raised (a bridge / flyover), carr (carriageway strip), outer (carriageway + pavement), mouth (end 0,
                      end 1 meet a main road)
    BOXES           the collision boxes of every batch built so far (RoadCollide_<t>_<n>.luau): (kind, polygon, top y)
                    kinds R carriageway, P pavement, M median, J junction square, D deck, W parapet
    CARR            carriageways: R / J / D boxes of all batches, batch 0.5's part roads, decks, ring and mesh streets,
                    and every traffic lane of the batch (4 either side)
    PAVE            CARR + pavements and medians (P / M boxes, batch 0.5's pavements)
    DECK_ZONE       30 round every deck / parapet box (no ground clutter under a flyover)
    WATER, LMZ      water (+2), landmark grounds (build/landmarks/<id>.json pads / platform + 12, discs for the others,
                    parks and the zoo excepted)
    PLOTS, PPOLY, PTREE   the batch's plots (+ batch 0.5's and other batches' near the outline)
    yhint(x, z)     the nearest road surface height (within 160)
Every road box is read from the files roads.py wrote; nothing here changes them.
"""
import glob, json, math, os, re

import numpy as np
import shapely
from shapely.geometry import LineString, Point, Polygon, box as sbox
from shapely.ops import unary_union
from shapely.strtree import STRtree
from scipy.spatial import cKDTree

import geo

OUT = os.path.join(geo.BUILD, 'city')
NL = chr(10)


class Bundle:
    pass


def _strip(P, lo, hi):
    """polygon between offsets lo and hi along the right-hand normal (-dz, dx) of a polyline"""
    P = np.asarray(P, dtype=float)
    if len(P) < 2:
        return Polygon()
    D = np.zeros_like(P)
    D[1:-1] = P[2:] - P[:-2]
    D[0] = P[1] - P[0]
    D[-1] = P[-1] - P[-2]
    D /= (np.linalg.norm(D, axis=1)[:, None] + 1e-9)
    Rn = np.stack([-D[:, 1], D[:, 0]], axis=1)
    A = P + Rn * lo
    B = P + Rn * hi
    pg = Polygon(np.vstack([A, B[::-1]]))
    if not pg.is_valid:
        pg = pg.buffer(0)
    return pg


def read_boxes(tags=('1', '2', '3'), within=None):
    out = []
    for t in tags:
        for f in sorted(glob.glob(os.path.join(OUT, 'RoadCollide_%s_*.luau' % t))):
            for line in open(f, encoding='utf-8'):
                w = line.split()
                if len(w) != 9:
                    continue
                try:
                    cx, cy, cz, dx, dy, dz, wd = (float(v) for v in w[:7])
                except ValueError:
                    continue
                L = math.hypot(dx, dz)
                if L < 1e-6:
                    continue
                ux, uz = dx / L, dz / L
                nx, nz = -uz, ux
                hl, hw = L / 2, wd / 2
                pg = Polygon([(cx + ux * a * hl + nx * b * hw, cz + uz * a * hl + nz * b * hw) for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1))])
                if within is not None and not within.intersects(pg):
                    continue
                out.append((w[8], pg, cy, t))
    return out


def read_lanes(tag):
    lanes = []
    for f in sorted(glob.glob(os.path.join(OUT, 'YangonLanesB%s_*.lua' % tag))):
        src = open(f, encoding='utf-8').read()
        for m in re.finditer(r'road = "([^"]*)", way = (\d+), lane = (\d+), kind = "(\w+)"[^}]*?pts = \{ ([^}]*) \}', src):
            name, way, lane, kind, pts = m.groups()
            v = [float(x) for x in pts.split(',') if x.strip()]
            P = [(v[i], v[i + 1], v[i + 2]) for i in range(0, len(v) - 2, 3)]
            em = re.search(r'B%s\.(\d+)$' % re.escape(tag), name)
            lanes.append({'road': name, 'edge': int(em.group(1)) if em else None, 'way': int(way), 'lane': int(lane),
                          'kind': kind, 'pts': P})
    return lanes


def landmark_zone():
    polys = []
    lm = json.load(open(os.path.join(geo.ROOT, 'tools', 'yangon', 'city', 'landmarks.json'), encoding='utf-8'))['landmarks']
    have = set()
    for f in glob.glob(os.path.join(geo.BUILD, 'landmarks', '*.json')):
        d = json.load(open(f, encoding='utf-8'))
        if not isinstance(d, dict) or 'cx' not in d:
            continue
        have.add(d.get('id'))
        got = False
        if d.get('platform_outline'):
            polys.append(Polygon(d['platform_outline']).buffer(30))
            for s in (d.get('stairs') or {}).values():
                polys.append(LineString([s['top'][::2], s['foot'][::2]]).buffer(22))
            got = True
        if d.get('pads'):
            for pad in d['pads'].split('|'):
                w = pad.split(' ')
                pts = [tuple(float(v) for v in q.split(',')) for q in ' '.join(w[4:]).split(';') if q]
                if len(pts) >= 3:
                    polys.append(Polygon(pts).buffer(12))
                    got = True
        if not got:
            polys.append(Point(d['cx'], d['cz']).buffer(110))
    ids_short = {'shwedagon': 'shw', 'sule': 'sule', 'city_hall': 'ch', 'independence_monument': 'indep', 'botataung': 'bota',
                 'karaweik': 'kara', 'chaukhtatgyi': 'chauk', 'kaba_aye': 'kaba', 'maha_wizaya': 'wiz'}
    for l in lm:
        if l.get('kind') in ('park', 'zoo'):
            continue
        if ids_short.get(l['id']) in have:
            continue
        x, z = geo.world(l['lon'], l['lat'])
        polys.append(Point(x, z).buffer(55))
    return unary_union(polys)


def load(tag, log=print):
    B = Bundle()
    B.TAG = tag
    B05 = sbox(*geo.BOX_05)
    B.REGION = geo.batch_poly(tag).difference(B05)
    near = B.REGION.buffer(250)
    shapely.prepare(B.REGION)
    _reg = {}

    def inside(x, z, m=10.0):
        g = _reg.get(m)
        if g is None:
            g = B.REGION.buffer(-m)
            shapely.prepare(g)
            _reg[m] = g
        return g.contains(Point(x, z))
    B.inside = inside

    # ---------------------------------------------------------------- roads of this batch
    prof = json.load(open(os.path.join(OUT, 'roads_%s_profile.json' % tag), encoding='utf-8'))
    lanes = read_lanes(tag)
    B.LANES = lanes
    lane_n = {}
    for l in lanes:
        if l['edge'] is None:
            continue
        d = lane_n.setdefault(l['edge'], {})
        d[l['way']] = max(d.get(l['way'], 0), l['lane'])
    edges = []
    for e in prof:
        P = [(p[0], p[2]) for p in e['pts']]
        if len(P) < 2:
            continue
        h0, h1 = float(e['half'][0]), float(e['half'][1])
        ln = lane_n.get(e['id'], {})
        traffic = bool(ln)
        flush = (not traffic) and e['hw'] in ('residential', 'living_street', 'service', 'unclassified', 'track', 'road')
        n_each = max(ln.values()) if ln else 0
        if not flush and (n_each >= 2):
            kind = 'route'
        elif not flush:
            kind = 'big'
        else:
            kind = 'lane' if e['walk'] <= 3.2 else 'street'
        sides = [1] + ([-1] if h0 > 0.5 else [])
        walk = float(e['walk'])
        rd = {'id': 'b%s:%d' % (tag, e['id']), 'eid': e['id'], 'name': e['name'] or e['hw'], 'src': 'batch', 'hw': e['hw'],
              'kind': kind, 'flush': flush, 'main': not flush, 'raised': bool(e.get('raised')), 'hs': {1: h1, -1: h0},
              'sides': sides, 'walk': walk, 'lanes': ln, 'pts': P, 'ys': [p[1] for p in e['pts']], 'mouth': (False, False)}
        rd['line'] = LineString(P)
        rd['carr'] = _strip(P, -h0, h1)
        rd['outer'] = _strip(P, -h0 - (walk if -1 in sides else 0.0), h1 + walk)
        edges.append(rd)
    # a flush street's end that meets a main road (a lane mouth)
    mains = [rd for rd in edges if rd['main']]
    mtree = STRtree([rd['outer'] for rd in mains]) if mains else None
    for rd in edges:
        if rd['main'] or mtree is None:
            continue
        m = []
        for end in (0, -1):
            p = Point(rd['pts'][end]).buffer(6)
            m.append(len(mtree.query(p, predicate='intersects')) > 0)
        rd['mouth'] = (m[0], m[1])
    B.EDGES = edges
    log('batch %s: %d road edges (%d main, %d with lanes), %d lanes' % (tag, len(edges), len(mains), len(lane_n), len(lanes)))

    # ---------------------------------------------------------------- the built boxes (every batch, near this one)
    tags = [t for t in ('1', '2', '3') if glob.glob(os.path.join(OUT, 'RoadCollide_%s_*.luau' % t))]
    boxes = read_boxes(tags, within=near)
    B.BOXES = boxes
    carr_parts = [pg for k, pg, y, t in boxes if k in ('R', 'J', 'D')]
    pave_parts = [pg for k, pg, y, t in boxes if k in ('P', 'M')]
    deck_parts = [pg for k, pg, y, t in boxes if k in ('D', 'W')]
    lane_polys = [LineString([(p[0], p[2]) for p in l['pts']]).buffer(4.0, cap_style=2) for l in lanes if len(l['pts']) >= 2]
    # batch 0.5's part roads and mesh streets (they reach the seam)
    import streets as streets_mod
    game = json.load(open(os.path.join(geo.MAP, 'ygn_roads_v5.json'), encoding='utf-8'))
    gpave, gcarr = streets_mod.game_pave(game)
    st = json.load(open(os.path.join(OUT, 'streets_05.json'), encoding='utf-8'))['streets']
    s_carr = [LineString(s['pts']).buffer(s['half'], cap_style=2, join_style=1) for s in st]
    s_out = [LineString(s['pts']).buffer(s['half'] + s['walk'], cap_style=2, join_style=1) for s in st]
    decks05 = [LineString([(q[0], q[2]) for q in d['s']]).buffer(32, cap_style=2) for d in game['decks']]
    t0 = __import__('time').time()
    B.CARR = unary_union(carr_parts + lane_polys + [gcarr.intersection(near)] + [g for g in s_carr + decks05 if g.intersects(near)])
    B.PAVE = unary_union([B.CARR] + pave_parts + [gpave.intersection(near)] + [g for g in s_out if g.intersects(near)])
    B.DECK_ZONE = unary_union([g.buffer(30) for g in deck_parts + [g for g in decks05 if g.intersects(near)]]) if deck_parts else Polygon()
    log('  carriageway / pavement unions %.0f s (%d boxes)' % (__import__('time').time() - t0, len(boxes)))
    # ---------------------------------------------------------------- water, landmarks
    water = []
    for a in geo.load('areas'):
        t = a['t']
        if t.get('natural') == 'water' or t.get('water') or t.get('landuse') in ('reservoir', 'basin') or t.get('waterway') == 'riverbank':
            pp = geo.proj(a['p'])
            if len(pp) >= 3:
                pg = Polygon(pp).buffer(0)
                if pg.intersects(near):
                    water.append(pg)
    B.WATER_RAW = unary_union(water) if water else Polygon()
    B.WATER = B.WATER_RAW.buffer(2) if water else Polygon()
    B.LMZ = landmark_zone()
    for g in (B.CARR, B.PAVE, B.DECK_ZONE, B.WATER, B.LMZ):
        shapely.prepare(g)
    # ---------------------------------------------------------------- plots
    plots = []
    for t in ('05', '1', '2', '3'):
        f = os.path.join(OUT, 'plots_%s.json' % t)
        if not os.path.exists(f):
            continue
        for p in json.load(open(f, encoding='utf-8'))['plots']:
            if t != tag:
                c = p['poly'][0]
                if not near.contains(Point(c)):
                    continue
            p = dict(p)
            p['tag'] = t
            plots.append(p)
    B.PLOTS = plots
    B.PPOLY = [Polygon(p['poly']).buffer(0) for p in plots]
    B.PTREE = STRtree(B.PPOLY)
    log('  plots: %d (own %d)' % (len(plots), sum(1 for p in plots if p['tag'] == tag)))
    # ---------------------------------------------------------------- heights
    hp = [(p[0], p[2], p[1]) for e in prof for p in e['pts']] + [(q[0], q[2], q[1]) for r in game['roads'] for q in r['s']]
    HP = np.array(hp)
    tree = cKDTree(HP[:, :2])

    def yhint(x, z):
        d, i = tree.query((x, z))
        return float(HP[i, 2]) if d < 160 else None
    B.yhint = yhint
    return B
