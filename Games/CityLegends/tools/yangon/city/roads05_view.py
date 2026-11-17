"""Top-down preview of roads05 data (what Roads.luau + YangonRoads will build), before Studio.

    YANGON_SCALE=1to1 python roads05_view.py <tags joined by _> <name> <x> <z> <size> [--paint]
-> build/city_1to1/roads05_<tags>/view_<name>.png

Draws each road the way the builder lays it: asphalt from -wl to +wr round the centre line, pavement walkL / walkR beyond
it (minus every carriageway: the builder's sideZone), red-white kerb bands 3.2 studs on the carriageway edge, the built
median (s[8]) as kerbed grass, roundabouts (ring, island, pavement), decks on top, and the paint plan (roads05_paint.py).
"""
import json, math, os, sys

import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon as MPoly
from shapely.geometry import Polygon, LineString, Point, box as sbox, MultiPolygon
from shapely.ops import unary_union

sys.stdout.reconfigure(encoding='utf-8')
import geo

LABELS = '--labels' in sys.argv
ASPHALT = '#2e2f32'
PAVER = '#807c74'
GRASS = '#55703a'
GROUND = '#6f8a4c'
KERB_W = '#f4e4c8'
KERB_R = '#c82826'
DECK = '#9a9690'


def strip(s, lo_f, hi_f, rng=None):
    """polygon between lateral offsets lo_f(sample) .. hi_f(sample) (right positive) over samples rng"""
    idx = range(len(s)) if rng is None else rng
    A, B = [], []
    for i in idx:
        q = s[i]
        rx, rz = -q[4], q[3]
        lo, hi = lo_f(q), hi_f(q)
        A.append((q[0] + rx * lo, q[2] + rz * lo))
        B.append((q[0] + rx * hi, q[2] + rz * hi))
    if len(A) < 2:
        return None
    pg = Polygon(A + B[::-1])
    if not pg.is_valid:
        pg = pg.buffer(0)
    return pg


def runs(mask):
    out = []
    i = 0
    n = len(mask)
    while i < n:
        if not mask[i]:
            i += 1
            continue
        j = i
        while j + 1 < n and mask[j + 1]:
            j += 1
        out.append((i, j))
        i = j + 1
    return out


def geoms(g):
    if g is None or g.is_empty:
        return []
    if g.geom_type == 'Polygon':
        return [g]
    if hasattr(g, 'geoms'):
        out = []
        for x in g.geoms:
            out.extend(geoms(x))
        return out
    return []


def draw_poly(ax, g, color, z, alpha=1.0, ec='none', lw=0):
    for p in geoms(g):
        ax.add_patch(MPoly(np.array(p.exterior.coords), closed=True, fc=color, ec=ec, lw=lw, zorder=z, alpha=alpha))
        for h in p.interiors:
            ax.add_patch(MPoly(np.array(h.coords), closed=True, fc=GROUND, ec='none', zorder=z + 0.01))


def surfaces(data, view):
    """carriageways, pavements, medians per road (built samples only), plus ring and deck polygons"""
    cut = {k: set(v) for k, v in data['cut'].items()}
    out = []
    for r in data['roads']:
        s = r['s']
        xs = [q[0] for q in s]
        zs = [q[2] for q in s]
        if max(xs) < view.bounds[0] - 200 or min(xs) > view.bounds[2] + 200 or max(zs) < view.bounds[1] - 200 or min(zs) > view.bounds[3] + 200:
            continue
        c = cut.get(r['name'], set())
        built = [i not in c for i in range(len(s))]
        cw, pv, md = [], [], []
        for a, b in runs(built):
            if b - a < 1:
                continue
            rng = range(a, b + 1)
            cw.append(strip(s, lambda q: -q[6], lambda q: q[7], rng))
            pv.append(strip(s, lambda q: -q[6] - r.get('walkL', 7.5), lambda q: -q[6], rng))
            pv.append(strip(s, lambda q: q[7], lambda q: q[7] + r.get('walkR', 7.5), rng))
            mb = [s[i][8] > 0.3 for i in rng]
            for m0, m1 in runs(mb):
                if m1 > m0:
                    md.append(strip(s, lambda q: -q[8], lambda q: q[8], range(a + m0, a + m1 + 1)))
        out.append(dict(r=r, cw=unary_union([g for g in cw if g]), pv=unary_union([g for g in pv if g]),
                        md=unary_union([g for g in md if g]) if md else None))
    rings = []
    for R in data.get('roundabouts', []):
        C = Point(R['c'][0], R['c'][2])
        rings.append(dict(R=R, ring=C.buffer(R['r_out'], 96).difference(C.buffer(R['r_in'], 96)), island=C.buffer(R['r_in'], 96),
                          walk=C.buffer(R['r_out'] + 7.5, 96).difference(C.buffer(R['r_out'], 96)), cut=C.buffer(R['r_out'] - 2, 96)))
    decks = []
    for d in data.get('decks', []):
        decks.append(dict(d=d, poly=strip(d['s'], lambda q: -q[6], lambda q: q[7])))
    return out, rings, decks


def render(data, name, cx, cz, size, paint=None, out=None, title=None):
    view = sbox(cx - size / 2, cz - size / 2, cx + size / 2, cz + size / 2)
    S, rings, decks = surfaces(data, view)
    fig, ax = plt.subplots(figsize=(12, 12), dpi=110)
    ax.set_facecolor(GROUND)
    ring_cut = unary_union([g['cut'] for g in rings]) if rings else None
    all_cw = unary_union([x['cw'] for x in S] + [g['ring'] for g in rings])
    # pavements: minus every carriageway (sideZone), minus ring inside
    for x in S:
        pv = x['pv'].difference(all_cw)
        if ring_cut is not None:
            pv = pv.difference(ring_cut)
        draw_poly(ax, pv.intersection(view.buffer(50)), PAVER, 1)
    for g in rings:
        wk = g['walk'].difference(unary_union([x['cw'] for x in S]))
        draw_poly(ax, wk, PAVER, 1)
    # carriageways
    cwu = unary_union([x['cw'].difference(ring_cut) if ring_cut is not None else x['cw'] for x in S])
    draw_poly(ax, cwu.intersection(view.buffer(50)), ASPHALT, 2)
    for g in rings:
        draw_poly(ax, g['ring'], ASPHALT, 2)
        draw_poly(ax, g['island'], GRASS, 3)
        # island kerb bands
        kerb_ring(ax, g['island'].exterior, 4)
    # kerbs on each carriageway edge not inside another carriageway
    others_all = all_cw
    for x in S:
        for p in geoms(x['cw']):
            edge = p.exterior
            cut_by = unary_union([y['cw'] for y in S if y is not x] + [g['ring'] for g in rings]) if True else None
            e = edge.difference(cut_by.buffer(0.3)) if cut_by is not None and not cut_by.is_empty else edge
            kerb_lines(ax, e, 4)
    # medians
    for x in S:
        if x['md'] is not None and not x['md'].is_empty:
            draw_poly(ax, x['md'], GRASS, 3)
            for p in geoms(x['md']):
                kerb_lines(ax, p.exterior, 4)
    # paint
    if paint:
        for it in paint:
            pts = np.array(it['p'])
            if len(pts) < 3:
                continue
            if not view.buffer(40).intersects(Polygon(pts).buffer(0)):
                continue
            col = {'LW': '#ebebe6', 'LY': '#e8b834', 'LZ': '#e6be6e'}[it['k']]
            z = 6 if not it.get('deck') else 9
            ax.add_patch(MPoly(pts, closed=True, fc=col, ec='none', zorder=z))
    # decks
    for d in decks:
        if d['poly'] is None:
            continue
        draw_poly(ax, d['poly'], DECK, 7, ec='#222', lw=1.2)
        # lane line on the deck centre
    if LABELS:
        for x in S:
            r = x['r']
            inv = [q for q in r['s'] if view.contains(Point(q[0], q[2]))]
            q = inv[len(inv) // 2] if inv else None
            if q is not None:
                ax.text(q[0], q[2], '%s r%s' % (r['name'], r['rank']), fontsize=6, color='yellow', zorder=30)
            for k in (0, -1):
                q = r['s'][k]
                if view.contains(Point(q[0], q[2])):
                    ax.plot(q[0], q[2], 'o', ms=3, color='cyan' if k == 0 else 'magenta', zorder=31)
    ax.set_xlim(cx - size / 2, cx + size / 2)
    ax.set_ylim(cz + size / 2, cz - size / 2)   # +Z down = north up? Z grows to the south: north at the top
    ax.set_aspect('equal')
    ax.set_title(title or name, fontsize=11)
    ax.tick_params(labelsize=7)
    # scale bar 30 m
    L = geo.m(30)
    ax.plot([cx - size / 2 + 20, cx - size / 2 + 20 + L], [cz + size / 2 - 20] * 2, color='w', lw=3, zorder=20)
    ax.text(cx - size / 2 + 20, cz + size / 2 - 30, '30 m', color='w', fontsize=9, zorder=20)
    fig.tight_layout()
    fig.savefig(out, facecolor='#333')
    plt.close(fig)
    return out


def kerb_lines(ax, geom, z):
    lines = []
    if geom.is_empty:
        return
    if geom.geom_type == 'LineString' or geom.geom_type == 'LinearRing':
        lines = [geom]
    elif hasattr(geom, 'geoms'):
        lines = [g for g in geom.geoms if g.geom_type in ('LineString', 'LinearRing')]
    for ln in lines:
        Lt = ln.length
        if Lt < 0.5:
            continue
        n = max(1, int(Lt / 3.2))
        for k in range(n):
            a = ln.interpolate(k * Lt / n)
            b = ln.interpolate((k + 1) * Lt / n)
            ax.plot([a.x, b.x], [a.y, b.y], color=KERB_R if k % 2 else KERB_W, lw=1.6, zorder=z, solid_capstyle='butt')


def kerb_ring(ax, ring, z):
    kerb_lines(ax, LineString(ring.coords), z)


if __name__ == '__main__':
    tag = sys.argv[1]
    nm, cx, cz, size = sys.argv[2], float(sys.argv[3]), float(sys.argv[4]), float(sys.argv[5])
    od = os.path.join(geo.BUILD, 'city_1to1', 'roads05_' + tag)
    data = json.load(open(os.path.join(od, 'roads.json'), encoding='utf-8'))
    paint = None
    pp = os.path.join(od, 'paint.json')
    if '--paint' in sys.argv and os.path.exists(pp):
        paint = json.load(open(pp))['items']
    print(render(data, nm, cx, cz, size, paint, os.path.join(od, 'view_%s.png' % nm)))
