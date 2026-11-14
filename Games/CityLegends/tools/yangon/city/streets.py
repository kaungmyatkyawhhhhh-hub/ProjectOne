"""Whole-Yangon map (14 Nov 2026): the real streets the game lacks, as meshes.

Owner: "in real life its compact and in game theres like barely any" (batch 0.5 had 37.6 km of ~192 km of real streets).
network.py gives the new streets (build/city/network_<tag>.json). This tool:

  prep  -> densifies every street every 8 studs, pushes a street end that stops short of a game road up to that road's
           pavement edge (a dropped-kerb crossing, like a Yangon side street meeting a main road), and writes the probe
           points (build/city/streets_<tag>_probe_*.luau, one string each) for tools/yangon/YangonProbe2.luau.
  build -> reads the probe answers (build/city/streets_<tag>_probe_out.txt: "gy|ty|k" a line), gives every sample a height
           (the ground + 0.25, smoothed along the street, shared at junctions, the game road's pavement top at a mouth),
           and makes per 256-stud cell: R asphalt, P pavement (+0.5, its kerb face), L lines (big roads only) as triangle
           meshes (build/city/streets_<tag>_meshes.pkl, written to .glb by d24_bmesh's glb writer), plus collision boxes
           (carriageway + pavements every <= 16 studs) and terrain beds as one string (build/city/StreetCollide_<tag>_*.luau).

Run from Games/CityLegends/tools/yangon/city:  python streets.py prep 05   /   python streets.py build 05
"""
import json, math, os, pickle, sys

import numpy as np
import shapely
from scipy.spatial import cKDTree
from shapely.geometry import LineString, Point, Polygon, box as sbox
from shapely.ops import unary_union

import geo

STEP = 8.0
CELL = 256.0
PAVE_UP = 0.5
NL = chr(10)


def game_pave(game_roads):
    """the game roads' carriageway+pavement polygons (no grow) and carriageway polygons"""
    pave, carr = [], []
    for r in game_roads['roads']:
        cs = set(game_roads.get('cut', {}).get(r['name'], []))
        walk = r.get('walkL') or 10.0
        run = []
        for k, s in enumerate(r['s'] + [None]):
            if s is None or k in cs:
                if len(run) > 1:
                    ls = LineString([(q[0], q[2]) for q in run])
                    half = max(max(q[6], q[7]) for q in run)
                    pave.append(ls.buffer(half + walk, cap_style=2))
                    carr.append(ls.buffer(half, cap_style=2))
                run = []
                continue
            run.append(s)
    return unary_union(pave), unary_union(carr)


def densify(pts, step=STEP):
    ls = LineString(pts)
    L = ls.length
    n = max(1, int(math.ceil(L / step)))
    return [list(ls.interpolate(L * i / n).coords[0]) for i in range(n + 1)]


def prep(tag):
    net = json.load(open(os.path.join(geo.BUILD, 'city', f'network_{tag}.json'), encoding='utf-8'))
    game = json.load(open(os.path.join(geo.MAP, 'ygn_roads_v5.json'), encoding='utf-8'))
    gpave, gcarr = game_pave(game)
    gb = gpave.boundary
    streets = []
    pushed = 0
    for i, s in enumerate(net['new']):
        pts = [tuple(p) for p in s['pts']]
        # push an end that stops 0..20 studs short of a game road's pavement onto its outer edge
        for end in (0, -1):
            p = Point(pts[end])
            d = gpave.distance(p)
            # (2026-11-14) a seam tail (network.py) already ends exactly where it should: on a game road's end or on a
            # neighbouring batch's seam piece (pushing it on would lay it over that piece)
            if 0.01 < d < 22 and not s.get('tail'):
                q = pts[1] if end == 0 else pts[-2]
                dx, dz = p.x - q[0], p.y - q[1]
                L = math.hypot(dx, dz) or 1
                ray = LineString([(p.x, p.y), (p.x + dx / L * 40, p.y + dz / L * 40)])
                hit = ray.intersection(gb)
                if not hit.is_empty:
                    hp = min((g for g in getattr(hit, 'geoms', [hit])), key=lambda g: g.distance(p))
                    np_ = (hp.x, hp.y) if hp.geom_type == 'Point' else hp.coords[0]
                    if end == 0:
                        pts.insert(0, np_)
                    else:
                        pts.append(np_)
                    pushed += 1
        d = densify(pts)
        streets.append(dict(s, pts=[[round(x, 2), round(z, 2)] for x, z in d],
                            mouth=[gpave.distance(Point(d[0])) < 0.5, gpave.distance(Point(d[-1])) < 0.5]))
    # probe points: every sample, plus the pavement edges at mouths (for the pavement-top height there)
    lines = []
    for s in streets:
        for x, z in s['pts']:
            lines.append(f'{x:.1f} {z:.1f}')
    out = os.path.join(geo.BUILD, 'city')
    json.dump({'streets': streets}, open(os.path.join(out, f'streets_{tag}.json'), 'w', encoding='utf-8'))
    chunk = 11000
    files = []
    for k in range(0, len(lines), chunk):
        n = k // chunk + 1
        txt = NL.join(lines[k:k + chunk])
        path = os.path.join(out, f'ProbePoints_{n}.luau')
        open(path, 'w', encoding='utf-8', newline=NL).write('return [==[' + NL + txt + NL + ']==]' + NL)
        files.append(path)
    print(f'{len(streets)} streets, {len(lines)} probe points in {len(files)} modules, {pushed} ends pushed to a game road')


def heights(tag):
    st = json.load(open(os.path.join(geo.BUILD, 'city', f'streets_{tag}.json'), encoding='utf-8'))['streets']
    rows = open(os.path.join(geo.BUILD, 'city', f'streets_{tag}_probe_out.txt'), encoding='utf-8').read().split(NL)
    rows = [r for r in rows if r.strip()]
    k = 0
    for s in st:
        hs, kinds = [], []
        for _ in s['pts']:
            gy, ty, kind = rows[k].split('|')
            k += 1
            g = float(gy) if gy else None
            t = float(ty) if ty else None
            hs.append((g, t, kind))
        s['probe'] = hs
    assert k == len(rows), (k, len(rows))
    # sample heights: ground + 0.25; where the sample stands on a game pavement / road (a mouth), its top
    for s in st:
        y = []
        for (g, t, kind) in s['probe']:
            if kind in ('P', 'K', 'R', 'S') and t is not None:
                y.append(t + (0.0 if kind != 'R' else PAVE_UP))
            elif g is not None:
                y.append(g + 0.25)
            else:
                y.append(None)
        # fill gaps
        good = [v for v in y if v is not None]
        fill = sum(good) / len(good) if good else 40.0
        y = [v if v is not None else fill for v in y]
        s['y0'] = y
    # smooth along each street (keep the mouth ends), then share at junctions (same rounded point)
    for _ in range(3):
        for s in st:
            y = s['y0']
            ys = y[:]
            for i in range(1, len(y) - 1):
                ys[i] = (y[i - 1] + 2 * y[i] + y[i + 1]) / 4
            if s['mouth'][0]:
                ys[0] = y[0]
            if s['mouth'][1]:
                ys[-1] = y[-1]
            s['y0'] = ys
        nodes = {}
        for s in st:
            for e in (0, -1):
                key = (round(s['pts'][e][0]), round(s['pts'][e][1]))
                nodes.setdefault(key, []).append((s, e))
        for key, ends in nodes.items():
            if len(ends) < 2:
                continue
            fixed = [s['y0'][e] for s, e in ends if s['mouth'][0 if e == 0 else 1]]
            v = fixed[0] if fixed else sum(s['y0'][e] for s, e in ends) / len(ends)
            for s, e in ends:
                s['y0'][e] = v
    seam_pins(tag, st)
    return st


SEAM_GRADE = {'big': 0.06}      # a street eased onto a neighbouring batch's road end climbs at most this (else 0.10)
SEAM_EASE_MIN = 24.0
SEAM_EASE_BIG = 90.0
SEAM_EXT = 40.0
SEAM_COLLIDE_EXT = 12.0
EDGE_TOL = 1.5        # (an OSM way can stop a stud or so short of the box edge: Insein Road 1.2)


_B1_ENDS = None


def _edge_end(p):
    """an end on batch 0.5's box edge where a batch 1-3 road continues it"""
    global _B1_ENDS
    x, z = p
    if min(abs(x - geo.BOX_05[0]), abs(x - geo.BOX_05[2]), abs(z - geo.BOX_05[1]), abs(z - geo.BOX_05[3])) > EDGE_TOL:
        return False
    if _B1_ENDS is None:
        ends = []
        for t in ('1', '2', '3'):
            pp = os.path.join(geo.BUILD, 'city', f'roads_{t}_profile.json')
            if os.path.exists(pp):
                for e in json.load(open(pp)):
                    ends += [(e['pts'][0][0], e['pts'][0][2]), (e['pts'][-1][0], e['pts'][-1][2])]
        _B1_ENDS = cKDTree(np.array(ends)) if ends else False
    return bool(_B1_ENDS) and _B1_ENDS.query((x, z))[0] < 3.0


SEAM_MAX_STEP = 1.5    # a bigger step is a design fault (the neighbour's ramp ends in the air), not eased: reported


def seam_pins(tag, st):
    """(14 Nov 2026) a street that stops on its box's edge where a neighbouring batch's road continues (roads.py's
    roads_<t>_profile.json) ends at THAT road's surface height and is eased back along itself at SEAM_GRADE, so the two meet
    with no step (batch 0.5's streets sit at the probed ground + 0.25, batch 1's roads on the field: 0.75 apart; Nar Nat
    Taw's ramp leaves the box 10 studs up). Writes build/city/streets_<tag>_seamfill.json: the samples raised more than
    0.3 over their old height, for the terrain under them (terrain.py fill)."""
    if tag != '05':
        return
    box = geo.BOX_05
    ends = []
    for t in ('1', '2', '3'):
        p = os.path.join(geo.BUILD, 'city', f'roads_{t}_profile.json')
        if not os.path.exists(p):
            continue
        for e in json.load(open(p)):
            for k in (0, -1):
                q = e['pts'][k]
                ends.append((q[0], q[2], q[1]))
    if not ends:
        return
    E = np.array(ends)
    fill = []
    pinned = 0
    # every street end on the box's edge with its own (un-eased) height, for heights.py's street pins
    edge_ends = []
    for s in st:
        for end in (0, -1):
            x, z = s['pts'][end]
            if min(abs(x - box[0]), abs(x - box[2]), abs(z - box[1]), abs(z - box[3])) <= EDGE_TOL:
                edge_ends.append([round(x, 2), round(z, 2), round(s['y0'][end], 2), s['name']])
    json.dump({'ends': edge_ends}, open(os.path.join(geo.BUILD, 'city', f'streets_{tag}_edgeends.json'), 'w'))
    for s in st:
        pts = s['pts']
        y = s['y0']
        old = list(y)
        for end in (0, -1):
            x, z = pts[end]
            d = np.hypot(E[:, 0] - x, E[:, 1] - z)
            i = int(d.argmin())
            # (2026-11-14) also a street end inside the box on a neighbouring batch's seam piece (the piece from a game
            # road's map-edge end to its first junction: Inya Road / Chindwin, Nar Nat Taw), not only ends on the edge
            on_edge = min(abs(x - box[0]), abs(x - box[2]), abs(z - box[1]), abs(z - box[3])) <= EDGE_TOL
            if not on_edge and d[i] > 1.5:
                continue
            # (an end on the edge takes a neighbouring end up to 6 studs along it: a divided pair split back onto its OSM
            # lines over the last 120 studs can end a few studs off the street's own end, Insein Road 4)
            if d[i] > (6.0 if on_edge else 3.0):
                continue
            pin = float(E[i, 2])
            dy = pin - y[end]
            if abs(dy) < 0.02:
                continue
            if abs(dy) > SEAM_MAX_STEP:
                print(f'  seam step NOT eased: {s["name"]} at {x:.0f}, {z:.0f}: the neighbouring road is {dy:+.1f} studs off')
                continue
            g = SEAM_GRADE.get(s['cls'], 0.10)
            # (2026-11-14) eased over at least SEAM_EASE_BIG studs on big streets: a divided pair's two one-way streets
            # overlap near the edge, and one eased over 24 studs stood 0.75 over its partner there (Insein Road)
            L = max(SEAM_EASE_BIG if s['cls'] == 'big' else SEAM_EASE_MIN, abs(dy) / g)
            idx = range(len(pts)) if end == 0 else range(len(pts) - 1, -1, -1)
            run = 0.0
            prev = None
            for j in idx:
                if prev is not None:
                    run += math.hypot(pts[j][0] - pts[prev][0], pts[j][1] - pts[prev][1])
                if run >= L:
                    break
                w = 1.0 - run / L
                w = w * w * (3 - 2 * w)
                y[j] = y[j] + dy * w
                prev = j
            pinned += 1
        # (2026-11-14) a seam tail (network.py) joins two neighbouring-batch / game road ends: one straight grade between
        # its two ends (eased only near each end it dipped 0.75 to the 0.5 streets' ground level in the middle)
        if s.get('tail') and len(pts) > 1:
            c = [0.0]
            for j in range(1, len(pts)):
                c.append(c[-1] + math.hypot(pts[j][0] - pts[j - 1][0], pts[j][1] - pts[j - 1][1]))
            for j in range(len(pts)):
                y[j] = y[0] + (y[-1] - y[0]) * c[j] / c[-1]
        for j in range(len(pts)):
            if y[j] - old[j] > 0.3:
                fill.append([round(pts[j][0], 2), round(pts[j][1], 2), round(y[j], 2), s['half'] + s['walk']])
    json.dump({'samples': fill}, open(os.path.join(geo.BUILD, 'city', f'streets_{tag}_seamfill.json'), 'w'))
    print(f'seam pins: {pinned} street ends eased onto a neighbouring batch road; {len(fill)} samples raised > 0.3')


def tri_poly(poly, maxseg=6.0):
    """constrained triangulation of a polygon (with holes), its edges cut to maxseg first"""
    poly = shapely.segmentize(poly, maxseg)
    tris = shapely.constrained_delaunay_triangles(poly)
    out = []
    for t in tris.geoms:
        c = list(t.exterior.coords)[:3]
        # counter-clockwise from above in x/z means... keep a consistent winding: normal must point up (+y)
        (x1, z1), (x2, z2), (x3, z3) = c
        cross = (x2 - x1) * (z3 - z1) - (z2 - z1) * (x3 - x1)
        if cross > 0:  # in x/z with y up, a positive cross in (x, z) gives a normal pointing -y: flip
            c = [c[0], c[2], c[1]]
        out.append(c)
    return out


def build(tag):
    st = heights(tag)
    game = json.load(open(os.path.join(geo.MAP, 'ygn_roads_v5.json'), encoding='utf-8'))
    gpave, gcarr = game_pave(game)
    # height field: every sample of every street
    P = np.array([p for s in st for p in s['pts']])
    H = np.array([y for s in st for y in s['y0']])
    tree = cKDTree(P)

    def h_at(x, z):
        d, i = tree.query((x, z), k=4)
        w = 1.0 / np.maximum(d, 0.5) ** 2
        return float((H[i] * w).sum() / w.sum())

    # (2026-11-14) a street cut on its box's edge runs on SEAM_EXT studs past it and every surface is clipped ON the edge
    # (its square end met the oblique edge with a gap on one side and an overlap on the neighbouring batch's road on the
    # other); the neighbouring batch's roads do the same from their side (roadmesh._seam_extend)
    clipbox = sbox(*geo.BOX_05) if tag == '05' else None

    def ext(s):
        pts = [tuple(p) for p in s['pts']]
        if clipbox is None or len(pts) < 2:
            return LineString(pts)
        for end in (0, -1):
            x, z = pts[end]
            if min(abs(x - geo.BOX_05[0]), abs(x - geo.BOX_05[2]), abs(z - geo.BOX_05[1]), abs(z - geo.BOX_05[3])) <= EDGE_TOL:
                q = pts[1] if end == 0 else pts[-2]
                dx, dz = x - q[0], z - q[1]
                L = math.hypot(dx, dz) or 1.0
                np_ = (x + dx / L * SEAM_EXT, z + dz / L * SEAM_EXT)
                if end == 0:
                    pts.insert(0, np_)
                else:
                    pts.append(np_)
        return LineString(pts)

    def clip(g):
        return g.intersection(clipbox) if clipbox is not None else g

    carr = clip(unary_union([ext(s).buffer(s['half'], cap_style=2, join_style=1) for s in st]))
    outer = clip(unary_union([ext(s).buffer(s['half'] + s['walk'], cap_style=2, join_style=1) for s in st]))
    # (2026-11-14) a neighbouring batch's seam piece reaching into the box (from a game road's map-edge end to its first
    # junction: Inya Road, Nar Nat Taw) lays its own carriageway: the streets keep off it (the same height: they flickered)
    if clipbox is not None:
        inb = sbox(geo.BOX_05[0] + 1, geo.BOX_05[1] + 1, geo.BOX_05[2] - 1, geo.BOX_05[3] - 1)
        seam = []
        for t in ('1', '2', '3'):
            pp = os.path.join(geo.BUILD, 'city', f'roads_{t}_profile.json')
            if os.path.exists(pp):
                for e in json.load(open(pp)):
                    L = LineString([(q[0], q[2]) for q in e['pts']])
                    if len(e['pts']) > 1 and L.intersects(inb):
                        seam.append(L.buffer(max(abs(e['half'][0]), abs(e['half'][1])), cap_style=2))
        if seam:
            sp = unary_union(seam)
            carr = carr.difference(sp)
            outer = outer.difference(sp)
    # the streets' surfaces never go over a game road's carriageway or pavement (the parts are there)
    carr = carr.difference(gpave)
    pave = outer.difference(carr).difference(gpave)
    lines_geo = []
    for s in st:
        if s['cls'] != 'big':
            continue
        ls = LineString(s['pts'])
        for off in ([0.0] if not s['oneway'] else []):
            lines_geo.append(ls.buffer(0.25, cap_style=2))
    lines_poly = clip(unary_union(lines_geo).difference(gpave)) if lines_geo else Polygon()
    xs, zs = P[:, 0], P[:, 1]
    cx0, cz0 = math.floor(xs.min() / CELL), math.floor(zs.min() / CELL)
    cx1, cz1 = math.floor(xs.max() / CELL), math.floor(zs.max() / CELL)
    meshes = {}
    nt = 0
    for cx in range(cx0, cx1 + 1):
        for cz in range(cz0, cz1 + 1):
            cb = sbox(cx * CELL, cz * CELL, (cx + 1) * CELL, (cz + 1) * CELL)
            for kind, geom, up in (('R', carr, 0.0), ('P', pave, PAVE_UP), ('L', lines_poly, 0.06)):
                g = geom.intersection(cb)
                if g.is_empty:
                    continue
                tris = []
                for poly in (getattr(g, 'geoms', [g])):
                    if poly.geom_type != 'Polygon' or poly.area < 0.5:
                        continue
                    for c in tri_poly(poly):
                        tris.append([(x, h_at(x, z) + up, z) for x, z in c])
                if kind == 'P':
                    # the kerb face: along the carriageway edge where pavement lies outside it
                    for poly in getattr(g, 'geoms', [g]):
                        if poly.geom_type != 'Polygon':
                            continue
                        for ring in [poly.exterior] + list(poly.interiors):
                            cs = list(ring.coords)
                            for a, b in zip(cs, cs[1:]):
                                m = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
                                if carr.distance(Point(m)) > 0.05:
                                    continue
                                ya, yb = h_at(*a), h_at(*b)
                                # face from the road up to the pavement; outward = towards the carriageway
                                q = [(a[0], ya, a[1]), (b[0], yb, b[1]), (b[0], yb + PAVE_UP, b[1]), (a[0], ya + PAVE_UP, a[1])]
                                tris.append([q[0], q[1], q[2]])
                                tris.append([q[0], q[2], q[3]])
                if tris:
                    meshes[(kind, cx, cz)] = tris
                    nt += len(tris)
    pickle.dump(meshes, open(os.path.join(geo.BUILD, 'city', f'streets_{tag}_meshes.pkl'), 'wb'))
    # collision: boxes along every street, at most 16 studs long: the carriageway, and each pavement 0.5 higher
    rows = []
    from shapely.strtree import STRtree
    cpolys, cowner = [], []
    for s_ in st:
        cpolys.append(LineString(s_['pts']).buffer(s_['half'], cap_style=2))
        cowner.append(s_)
    for g_ in getattr(gcarr, 'geoms', [gcarr]):
        cpolys.append(g_)
        cowner.append(None)
    for t_ in ('1', '2', '3'):
        pp_ = os.path.join(geo.BUILD, 'city', f'roads_{t_}_profile.json')
        if os.path.exists(pp_):
            for e_ in json.load(open(pp_)):
                if len(e_['pts']) > 1:
                    cpolys.append(LineString([(q[0], q[2]) for q in e_['pts']]).buffer(max(abs(e_['half'][0]), abs(e_['half'][1])), cap_style=2))
                    cowner.append(None)
    ctree = STRtree(cpolys)
    for s in st:
        pts, ys = s['pts'], s['y0']
        i = 0
        while i < len(pts) - 1:
            j = min(len(pts) - 1, i + 2)
            (x1, z1), (x2, z2) = pts[i], pts[j]
            y1, y2 = ys[i], ys[j]
            # (2026-11-14) an end on the box's edge: a flat box SEAM_COLLIDE_EXT on past it, 0.15 under the end's height (an
            # oblique edge left a wedge with no road; where the neighbouring batch's box is there too, that one is on top)
            if clipbox is not None:
                Lc = math.hypot(x2 - x1, z2 - z1) or 1.0
                ux, uz = (x2 - x1) / Lc, (z2 - z1) / Lc
                for at, sg in ((0, -1.0), (len(pts) - 1, 1.0)):
                    if (i if at == 0 else j) == at and _edge_end(pts[at]):
                        xa, za = pts[at]
                        dist_ = [abs(xa - geo.BOX_05[0]), abs(xa - geo.BOX_05[2]), abs(za - geo.BOX_05[1]), abs(za - geo.BOX_05[3])]
                        c_ = max(abs(ux) if dist_.index(min(dist_)) < 2 else abs(uz), 1e-3)
                        ext_ = min(80.0, max(SEAM_COLLIDE_EXT, (s['half'] + s['walk']) * math.sqrt(max(0.0, 1 - c_ * c_)) / c_ + 4.0))
                        xb, zb = xa + ux * sg * ext_, za + uz * sg * ext_
                        ye = ys[at] - 0.15
                        # (dipping 8 % away from the edge: past the wedge it stays under the neighbouring road's surface)
                        dye = -0.08 * ext_
                        rows.append('%.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f 0 0' % ((xa + xb) / 2, ye + dye / 2, (za + zb) / 2, xb - xa, dye, zb - za,
                                                                              2 * s['half'], 0.0))
            L = math.hypot(x2 - x1, z2 - z1)
            if L > 0.5:
                # (2026-11-14) a pavement box lying on another street's or road's carriageway (a junction mouth) is left out:
                # it stood 0.5 over the asphalt across the mouth (a kerb-high bump on the driving line)
                vx, vz = (x2 - x1) / L, (z2 - z1) / L
                rx, rz = -vz, vx
                fl = []
                for sd in (1.0, -1.0):
                    o0, o1 = s['half'] * sd, (s['half'] + s['walk']) * sd
                    q = Polygon([(x1 + rx * o0, z1 + rz * o0), (x2 + rx * o0, z2 + rz * o0), (x2 + rx * o1, z2 + rz * o1), (x1 + rx * o1, z1 + rz * o1)])
                    blocked = False
                    for k_ in ctree.query(q):
                        if cowner[int(k_)] is s:
                            continue
                        if cpolys[int(k_)].intersection(q).area > 0.2 * q.area:
                            blocked = True
                            break
                    fl.append('0' if blocked else '1')
                # (rows: "cx cy cz dx dy dz width walk wr wl": wr / wl = the pavement box right / left of the direction)
                rows.append('%.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %s %s' % ((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2, x2 - x1, y2 - y1, z2 - z1,
                                                                               2 * s['half'], s['walk'], fl[0], fl[1]))
            i = j
    chunk = 3500
    files = 0
    for k in range(0, len(rows), chunk):
        files += 1
        open(os.path.join(geo.BUILD, 'city', f'StreetCollide_{tag}_{files}.luau'), 'w', encoding='utf-8', newline=NL).write(
            'return [==[' + NL + NL.join(rows[k:k + chunk]) + NL + ']==]' + NL)
    print(f'{len(meshes)} meshes, {nt} triangles, {len(rows)} collision segments in {files} modules')


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    mode, tag = sys.argv[1], sys.argv[2]
    {'prep': prep, 'build': build}[mode](tag)
