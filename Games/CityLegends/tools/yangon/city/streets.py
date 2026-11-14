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
            if 0.01 < d < 22:
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
    for s in st:
        pts = s['pts']
        y = s['y0']
        old = list(y)
        for end in (0, -1):
            x, z = pts[end]
            if min(abs(x - box[0]), abs(x - box[2]), abs(z - box[1]), abs(z - box[3])) > 1.0:
                continue
            d = np.hypot(E[:, 0] - x, E[:, 1] - z)
            i = int(d.argmin())
            if d[i] > 3.0:
                continue
            pin = float(E[i, 2])
            dy = pin - y[end]
            if abs(dy) < 0.02:
                continue
            if abs(dy) > SEAM_MAX_STEP:
                print(f'  seam step NOT eased: {s["name"]} at {x:.0f}, {z:.0f}: the neighbouring road is {dy:+.1f} studs off')
                continue
            g = SEAM_GRADE.get(s['cls'], 0.10)
            L = max(SEAM_EASE_MIN, abs(dy) / g)
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

    carr = unary_union([LineString(s['pts']).buffer(s['half'], cap_style=2, join_style=1) for s in st])
    outer = unary_union([LineString(s['pts']).buffer(s['half'] + s['walk'], cap_style=2, join_style=1) for s in st])
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
    lines_poly = unary_union(lines_geo).difference(gpave) if lines_geo else Polygon()
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
    for s in st:
        pts, ys = s['pts'], s['y0']
        i = 0
        while i < len(pts) - 1:
            j = min(len(pts) - 1, i + 2)
            (x1, z1), (x2, z2) = pts[i], pts[j]
            y1, y2 = ys[i], ys[j]
            L = math.hypot(x2 - x1, z2 - z1)
            if L > 0.5:
                rows.append('%.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f' % ((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2, x2 - x1, y2 - y1, z2 - z1,
                                                                          2 * s['half'], s['walk']))
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
