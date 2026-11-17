"""Junction fixes on a roads05 network, run after roads05.py and before roads05_paint.py (17 Nov 2026, owner: kerbs
lying diagonally across a junction, a grass median running through a junction; "Friday's builder never did that").

    YANGON_SCALE=1to1 python roads05_fix.py <tags joined by _>
-> rewrites build/city_1to1/roads05_<tags>/roads.json + Roads05_<k>.luau, prints counts (fix.json)

  * mouths: a road that ends on a bigger road (lower rank) is run on straight until BOTH its carriageway edges reach
    the bigger road's carriageway (YangonRoads.buildMouth walks each edge to the bigger road's edge and fails, leaving
    the kerbs across the junction, when one never gets there). Never further than the bigger road's half width.
  * medians: no median sample on another road's carriageway or a ring, plus MED_GAP studs before it (the median ends
    before the junction box).
"""
import json, math, os, sys

import numpy as np
from shapely.geometry import LineString, Point, Polygon
from shapely.ops import unary_union
from shapely.strtree import STRtree

import geo
from roads05_qa import quads

STEP = 8.0
MED_GAP = 6.0
CHUNK = 185000


ISLAND_MAX = 2500.0
# (J13, owner's drawing 18 Nov, `City Legends/Owner ref - junction wrong shape (owner drawing).webp`): places where the
# satellite shows one asphalt area but OSM's links leave a gore: (x, z, why). The hole round the point is paved as road
# (data.fills), with no kerb / pavement / corner in it; OWNER_MEDIAN_OFF clears a merged road's median near a spot
OWNER_GORES = [(36350.0, 42490.0, 'Kun Chan Road x Gyophyu Road (Zoological Garden Rd) by Yangon Central')]
OWNER_MEDIAN_OFF = [('Kun Chan Road', 36395.0, 42482.0, 140.0)]  # studs^2: a traffic island (real ones are paved concrete: Pyay x University Ave, satellite)


def islands(data):
    """(J9) Small traffic islands (a hole in the union of every carriageway and ring, under ISLAND_MAX) that the
    kerb + pavement bands round them do not cover were left unpaved (ground showed). Each such island goes to the
    builder as its kerb-line outline: [x, y, z, walk of the edge from this point to the next]; YangonRoads.buildIslands
    paves what is left inside the bands and the round corners (exactly, nothing on top of them)."""
    cutd = {k: set(v) for k, v in data['cut'].items()}
    polys, owner = [], []
    for r in data['roads']:
        g = unary_union(quads(r['s'], cutd.get(r['name'], ())))
        if not g.is_empty:
            polys.append(g)
            owner.append(r)
    for g in data['roundabouts']:
        rv = g['r_out'] / math.cos(math.pi / 96)
        polys.append(Polygon([(g['c'][0] + rv * math.cos(2 * math.pi * j / 96), g['c'][2] + rv * math.sin(2 * math.pi * j / 96)) for j in range(96)]))
        owner.append(g)
    allg = unary_union(polys)
    tree = STRtree(polys)
    out = []
    for poly in getattr(allg, 'geoms', [allg]):
        for ring in poly.interiors:
            H = Polygon(ring)
            if H.area >= ISLAND_MAX or H.area < 4:
                continue
            pts = list(Polygon(ring).simplify(0.15).exterior.coords)[:-1]
            if len(pts) < 3:
                continue
            rows, wmin = [], 99.0
            for k, (x, z) in enumerate(pts):
                x2, z2 = pts[(k + 1) % len(pts)]
                mid = Point((x + x2) / 2, (z + z2) / 2)
                best, bo = 1e9, None
                for i in tree.query(mid.buffer(1.0)):
                    d = polys[i].distance(mid)
                    if d < best:
                        best, bo = d, owner[i]
                if bo is None:
                    rows = None
                    break
                if 'r_out' in bo:
                    walk, y = RING_WALK, bo['c'][1]
                else:
                    s = bo['s']
                    j = min(range(len(s)), key=lambda j: (s[j][0] - mid.x) ** 2 + (s[j][2] - mid.y) ** 2)
                    q = s[j]
                    right = (-q[4]) * (mid.x - q[0]) + q[3] * (mid.y - q[2]) > 0
                    walk = (bo.get('walkR') if right else bo.get('walkL')) or RING_WALK
                    y = q[1]
                wmin = min(wmin, walk)
                rows.append([round(x, 2), round(y, 3), round(z, 2), walk])
            # only an island the bands leave open
            if rows and not H.buffer(-wmin - 0.3).is_empty:
                out.append(rows)
    data['islands'] = out
    # (J13) owner-drawn asphalt gores (OWNER_GORES): the hole round each point is one road surface (data.fills)
    fills = []
    for gx, gz, why in OWNER_GORES:
        P = Point(gx, gz)
        Cm = P.buffer(250).difference(allg)
        # (the gore can leak out through a sliver under 3 studs at a corner: cut necks off, keep the part round P)
        Op = Cm.buffer(-1.5).buffer(1.5).intersection(Cm)
        for H in getattr(Op, 'geoms', [Op]):
            if H.geom_type != 'Polygon' or not H.buffer(0.5).contains(P) or H.area > 30000:
                continue
            rows = []
            for x, z in list(H.simplify(0.15).exterior.coords)[:-1]:
                best = min((r for r in owner if 's' in r), key=lambda r: min((q[0] - x) ** 2 + (q[2] - z) ** 2 for q in r['s']))
                q = min(best['s'], key=lambda q: (q[0] - x) ** 2 + (q[2] - z) ** 2)
                rows.append([round(x, 2), round(q[1], 3), round(z, 2), 0.0])
            fills.append(rows)
            out[:] = [o for o in out if not H.contains(Point(o[0][0], o[0][2]))]
    data['fills'] = fills
    return dict(islands=len(out), fills=len(fills))


def check(data):
    """what YangonRoads.load needs, or it errors (17 Nov: a 3-sample leftover by Sule's ring ran its arm loop off the
    road): unique names / ranks, decks and cuts inside their roads, every ring arm reaching past R_OUT + FLAT (12).
    A road that breaks the ring rule goes (logged)."""
    names = [r['name'] for r in data['roads']]
    assert len(set(names)) == len(names), 'two roads share a name'
    assert len(set(r['rank'] for r in data['roads'])) == len(names), 'two roads share a rank'
    by = {r['name']: r for r in data['roads']}
    for d in data['decks']:
        r = by[d['of']]
        assert 0 <= d['from'] < d['to'] < len(r['s']) and len(d['s']) == d['to'] - d['from'] + 1, d['name']
    for n, c in data['cut'].items():
        assert n in by and 0 <= min(c) and max(c) < len(by[n]['s']), n
    gone = []
    for r in data['roads']:
        for g in data['roundabouts']:
            rad = [math.hypot(q[0] - g['c'][0], q[2] - g['c'][2]) for q in r['s']]
            if min(rad[0], rad[-1]) < g['r_out'] and max(rad) < g['r_out'] + 12 + 1:
                gone.append(r['name'])
    if gone:
        decked = set(d['of'] for d in data['decks'])
        gone = [n for n in gone if n not in decked]
        data['roads'] = [r for r in data['roads'] if r['name'] not in gone]
        for n in gone:
            data['cut'].pop(n, None)
    return dict(ok=True, ring_stubs_dropped=gone, duplicates_dropped=drop_dups(data))


def drop_dups(data):
    """a road the builder would drop as lying wholly on a bigger one (mouthsim 'dropped') goes from the data, and the
    continuation flags naming it go too (the roads that carried on from it then get a mouth)"""
    import roads05_mouthsim
    dup = sorted(set(d['road'] for d in roads05_mouthsim.run(data)['dropped']) - set(d['of'] for d in data['decks']))
    if dup:
        data['roads'] = [r for r in data['roads'] if r['name'] not in dup]
        for n in dup:
            data['cut'].pop(n, None)
        for r in data['roads']:
            for f in ('startsOnEnd', 'endsOnEnd'):
                if r.get(f) in dup:
                    del r[f]
    return dup


RING_WALK, KERB_W = 7.5, 0.9  # YangonRoads 1:1 ring pavement / kerb


def ring_clear(data):
    """A road passing a roundabout without joining it (a slip like Lane #4701 by Roundabout 1, 2-3 m off the ring in
    OSM) had its kerb inside the ring's kerb / pavement band: the builder cut it piece by piece (a sawtooth). Its
    samples are pushed out radially until its inner kerb clears the ring's pavement (the shift tapers off at 15%
    a stud along the road), directions re-taken from the neighbours. Never a road with any sample inside r_out."""
    moved = []
    for r in data['roads']:
        s = r['s']
        if len(s) < 2 or r.get('closed'):
            continue
        for g in data['roundabouts']:
            if r['name'] in g.get('arms', ()):
                continue
            cx, cz, ro = g['c'][0], g['c'][2], g['r_out']
            rads = [math.hypot(q[0] - cx, q[2] - cz) for q in s]
            if min(rads) < ro or min(rads) > ro + 60:
                continue
            rv = ro / math.cos(math.pi / 96)
            push = []
            for q, rad in zip(s, rads):
                ux, uz = (cx - q[0]) / rad, (cz - q[2]) / rad  # towards the centre
                hin = q[7] if (-q[4]) * ux + q[3] * uz > 0 else q[6]  # right = (-dz, dx)
                push.append(max(0.0, rv + RING_WALK + KERB_W + 0.5 + hin - rad))
            if max(push) <= 0:
                continue
            # taper: along-road distance between samples
            along = [0.0]
            for a, b in zip(s, s[1:]):
                along.append(along[-1] + math.hypot(b[0] - a[0], b[2] - a[2]))
            disp = [max(p - abs(along[i] - along[j]) * 0.15 for j, p in enumerate(push)) for i in range(len(s))]
            if disp[0] > 0.01 or disp[-1] > 0.01:
                continue  # it would move a road end (a mouth): leave it to the mouth tools
            for q, rad, dd in zip(s, rads, disp):
                if dd > 0:
                    q[0] = round(q[0] + (q[0] - cx) / rad * dd, 2)
                    q[2] = round(q[2] + (q[2] - cz) / rad * dd, 2)
            for i in range(len(s)):
                if disp[i] > 0 or (i > 0 and disp[i - 1] > 0) or (i + 1 < len(s) and disp[i + 1] > 0):
                    a, b = s[max(i - 1, 0)], s[min(i + 1, len(s) - 1)]
                    L = math.hypot(b[0] - a[0], b[2] - a[2]) or 1
                    s[i][3], s[i][4] = round((b[0] - a[0]) / L, 4), round((b[2] - a[2]) / L, 4)
            moved.append(dict(road=r['name'], ring=g['name'], max_shift=round(max(disp), 2)))
    return moved


MORPH = 40.0


RING_RAMP = 100.0
RING_MODE = os.environ.get('RING_MODE', 'scale')
RING_GRADE = 0.05  # YangonRoads.EDGE_GRADE: no eased road steeper than this (unless it was already)
RING_FLAT = 40.0  # (J12, Sule west: 32nd Street crosses Maha Bandula #2 30 studs off the ring at 1.3 over it; the
# builder's junction height left Maha Bandula 0.7 over the ring 4 studs from its edge: a crease (the "seam").
# Flat at c.y out to r_out + 4 + RING_FLAT, then the ramp)


def ring_level(data):
    """(J9, Sule) the ring is flat at c.y, but its arms reached it up to 4.8 studs higher or lower (the DEM round the
    pagoda): a step at the ring's edge. Every road sample within r_out + 4 + RING_FLAT of a ring goes to c.y (J12:
    flat, the Sule crease). (J13) Past the flat, each run of a road's samples keeps its own shape and only takes off
    the step it had at the flat's edge, fading out over the ring's ramp: y - gap * (1 - w). (J9-J12 scaled the whole
    gap to c.y, which flattened a road climbing away from the ring and made it 6.5% steep at the ramp's end, Sule.)
    The ramp is RING_RAMP, longer (to 300) until the steps' fade adds at most RING_GRADE - the road's own grade;
    the reach past r_out goes to the builder as the ring's `level` (verge air clear). Cut samples stay."""
    out = []
    cutd = {k: set(v) for k, v in data['cut'].items()}
    for g in data['roundabouts']:
        cx, cy, cz, ro = g['c'][0], g['c'][1], g['c'][2], g['r_out']
        flat = ro + 4 + RING_FLAT
        near = [r for r in data['roads'] if any(abs(q[0] - cx) < ro + 400 and abs(q[2] - cz) < ro + 400 for q in r['s'])]
        # (J13) the step to fade = a field round the ring (position only, so roads sharing a junction sample still
        # share its height): G(angle) = the kernel-weighted gap (y - c.y) of the samples at the flat's edge
        edge = []
        for r in near:
            cut = cutd.get(r['name'], set())
            for i, q in enumerate(r['s']):
                if i not in cut and abs(math.hypot(q[0] - cx, q[2] - cz) - flat) < 12:
                    edge.append((math.atan2(q[2] - cz, q[0] - cx), q[1] - cy))

        def G(a):
            sw = sv = 0.0
            for b_, v in edge:
                d = (a - b_ + math.pi) % (2 * math.pi) - math.pi
                w_ = math.exp(-(d / 0.6) ** 2)
                sw += w_
                sv += w_ * v
            return sv / sw if sw > 1e-3 else 0.0
        runs = []  # (road, [sample indices in reach, along the road], radii, step to fade per sample)
        for r in near:
            s, cut = r['s'], cutd.get(r['name'], set())
            rad = [math.hypot(q[0] - cx, q[2] - cz) for q in s]
            cur = []
            for i in range(len(s) + 1):
                if i < len(s) and rad[i] < flat + 300 and i not in cut:
                    cur.append(i)
                    continue
                if cur and min(rad[j] for j in cur) < flat + 2:
                    gap = {j: G(math.atan2(s[j][2] - cz, s[j][0] - cx)) for j in cur}
                    runs.append((r, cur, rad, gap))
                cur = []
        cnt = {}
        for r in near:
            for q in r['s']:
                k_ = (round(q[0], 1), round(q[2], 1))
                cnt[k_] = cnt.get(k_, 0) + 1
        shared = {k_ for k_, v in cnt.items() if v > 1}
        ramp = RING_RAMP
        while True:
            new, steep, at = {}, 0.0, None
            for r, idx, rad, gap in runs:
                s = r['s']
                for i in idx:
                    if rad[i] < flat:
                        new[(id(r), i)] = cy
                    elif rad[i] < flat + ramp:
                        w = (rad[i] - flat) / ramp
                        new[(id(r), i)] = (s[i][1] - gap[i] * (1 - w)) if RING_MODE == 'fade' else (cy + (s[i][1] - cy) * w)
                # (J13) the change spread evenly along the road between pinned samples (flat ones, junction samples
                # shared with another road, the ramp's end): the least extra grade, shared samples still shared
                pins = [i for i in idx if rad[i] < flat or (round(s[i][0], 1), round(s[i][2], 1)) in shared
                        or (id(r), i) not in new or i in (idx[0], idx[-1])]
                along = {idx[0]: 0.0}
                for a, b in zip(idx, idx[1:]):
                    along[b] = along[a] + math.hypot(s[b][0] - s[a][0], s[b][2] - s[a][2])
                dl = {i: new.get((id(r), i), s[i][1]) - s[i][1] for i in pins}
                for a, b in zip(pins, pins[1:]):
                    span = along[b] - along[a]
                    for i in idx[idx.index(a) + 1: idx.index(b)]:
                        u = (along[i] - along[a]) / span if span > 1e-6 else 0.0
                        new[(id(r), i)] = s[i][1] + dl[a] + (dl[b] - dl[a]) * u
                for a, b in zip(idx, idx[1:]):
                    if b != a + 1:
                        continue
                    ya, yb = new.get((id(r), a), s[a][1]), new.get((id(r), b), s[b][1])
                    L = math.hypot(s[b][0] - s[a][0], s[b][2] - s[a][2])
                    if L > 2:
                        oldg, g2 = abs(s[b][1] - s[a][1]) / L, abs(yb - ya) / L
                        if g2 > RING_GRADE and g2 > oldg + 0.005 and g2 > steep:
                            steep, at = g2, (r['name'], round(s[a][0]), round(s[a][2]), round(oldg, 3))
            if steep <= RING_GRADE or ramp >= 300:
                break
            ramp += 20
        worst = 0.0
        R = {id(r): r for r in near}
        for (rid, i), ny in new.items():
            q = R[rid]['s'][i]
            worst = max(worst, abs(ny - q[1]))
            q[1] = round(ny, 3)
        g['level'] = round(4 + RING_FLAT + ramp, 1)
        if worst > 0.05:
            out.append(dict(ring=g['name'], max_change=round(worst, 2), ramp=ramp, max_grade=round(steep, 3), at=at))
    return out


def butt_match(data):
    """A continuation (startsOnEnd / endsOnEnd) narrower than, or off-centre from, its host's end left a strip of the
    host's end line with no slab on the far side (the Bogyoke x Pazundaung Y: Upper Pazundaung #3 is 63 wide, Lower
    Pazundaung 45 and 14 off-centre: grass in the gore). The continuation's first MORPH studs now start on the host's
    end cross-section exactly (centre and both edges) and taper back to its own. Only where one road continues that
    end (a real fork keeps both branches as they are)."""
    R = {r['name']: r for r in data['roads']}
    users = {}
    for r in data['roads']:
        for key, e in (('startsOnEnd', 0), ('endsOnEnd', -1)):
            h = R.get(r.get(key))
            if not h or len(r['s']) < 2:
                continue
            c = r['s'][e]
            he = min((0, -1), key=lambda k: math.hypot(h['s'][k][0] - c[0], h['s'][k][2] - c[2]))
            users.setdefault((h['name'], he), []).append((r, e))
    done = []
    for (hn, he), us in users.items():
        if len(us) != 1:
            continue
        r, e = us[0]
        hq = R[hn]['s'][he]
        rh = (-hq[4], hq[3])
        eL = (hq[0] - rh[0] * hq[6], hq[2] - rh[1] * hq[6])
        eR = (hq[0] + rh[0] * hq[7], hq[2] + rh[1] * hq[7])
        tc = ((eL[0] + eR[0]) / 2, (eL[1] + eR[1]) / 2)
        H = math.hypot(eL[0] - eR[0], eL[1] - eR[1]) / 2
        s = r['s'] if e == 0 else r['s'][::-1]
        c0 = s[0]
        rc = (-c0[4], c0[3])
        lat = (tc[0] - c0[0]) * rc[0] + (tc[1] - c0[2]) * rc[1]
        if abs(lat) < 1 and abs(H - c0[6]) < 1 and abs(H - c0[7]) < 1:
            continue
        # (only the same road going on: same one-way-ness, mostly on the host's end, at least half as wide; a one-way
        # carriageway leaving a two-way host is half of a split, not this)
        if bool(r.get('oneway')) != bool(R[hn].get('oneway')):
            continue
        lo, hi = max(-lat - c0[6], -H), min(-lat + c0[7], H)  # own span along its right vector, host centre = 0
        if hi - lo < 0.7 * (c0[6] + c0[7]) or (c0[6] + c0[7]) < H:
            continue
        cutn = set(data['cut'].get(r['name'], ())) | set(data['cut'].get(hn, ()))
        if cutn and (0 in cutn or len(r['s']) - 1 in cutn or 0 in set(data['cut'].get(hn, ())) or len(R[hn]['s']) - 1 in set(data['cut'].get(hn, ()))):
            continue
        if any(q[8] > 0 for q in s[:8]):
            continue  # (a median at the joint: leave it)
        along = 0.0
        for i, q in enumerate(s):
            if i:
                along += math.hypot(q[0] - s[i - 1][0], q[2] - s[i - 1][2])
            t = 1 - along / MORPH
            if t <= 0:
                break
            q[0] = round(q[0] + rc[0] * lat * t, 2)
            q[2] = round(q[2] + rc[1] * lat * t, 2)
            q[6] = round(q[6] + (H - q[6]) * t, 2)
            q[7] = round(q[7] + (H - q[7]) * t, 2)
        done.append(dict(road=r['name'], host=hn, lateral=round(lat, 1), half=round(H, 1)))
    return done


OSM_DRV = set('motorway trunk primary secondary tertiary unclassified residential service living_street road motorway_link '
              'trunk_link primary_link secondary_link tertiary_link'.split())


def osm_join_nodes():
    """world (x, z) of every OSM driveable way end that other ways share (a join in OSM), and the ways' lines"""
    use, ends = {}, []
    ways = [w for w in geo.load('roads') if w['t'].get('highway') in OSM_DRV]
    osm_join_nodes.lines = [LineString([geo.world(*p) for p in w['p']]) for w in ways]
    for w in ways:
        for p in w['p']:
            use.setdefault((round(p[0], 7), round(p[1], 7)), set()).add(w['id'])
    for w in ways:
        for p in (w['p'][0], w['p'][-1]):
            key = (round(p[0], 7), round(p[1], 7))
            if len(use[key]) > 1:
                ends.append(geo.world(p[0], p[1]))
    return ends


def _set_dirs(s, idx):
    for i in idx:
        a, b = s[max(i - 1, 0)], s[min(i + 1, len(s) - 1)]
        L = math.hypot(b[0] - a[0], b[2] - a[2]) or 1
        s[i][3], s[i][4] = round((b[0] - a[0]) / L, 4), round((b[2] - a[2]) / L, 4)


def osm_joins(data):
    """(J13) A road end that OSM joins to another way (shared end node) but that ours leaves open: it stops 1-12 studs
    beside a carriageway (a street meeting a merged dual road's far carriageway, a slip ending beside a frontage
    road, a shallow join), or runs on past a bigger road's far edge. Its end is moved onto the other road's centre
    line: an overshoot is cut back to where it crosses that centre line; otherwise the last stretch bends onto the
    nearest centre-line point (a merge taper, smoothstep over max(40, 4 x the move); heights ease to that road's).
    roads05_fix's mouth run-on / repair then make the mouth. Same end filters as roads05_kerbsim's join rows."""
    from scipy.spatial import cKDTree
    J = cKDTree(osm_join_nodes())
    OL = osm_join_nodes.lines
    OT = STRtree(OL)
    roads = data['roads']
    cutd = {k: set(v) for k, v in data['cut'].items()}
    geoms = [unary_union(quads(r['s'], cutd.get(r['name'], ()))) for r in roads]
    lines = [LineString([(q[0], q[2]) for q in r['s']]) if len(r['s']) > 1 else None for r in roads]
    tree = STRtree(geoms)
    endpts = [(r['s'][k][0], r['s'][k][2], ri) for ri, r in enumerate(roads) if len(r['s']) > 1 for k in (0, -1)]
    ET = cKDTree([(x, z) for x, z, _ in endpts])
    feet = [(d['s'][k][0], d['s'][k][2]) for d in data['decks'] for k in (0, -1)]
    deck_of = {d['of'] for d in data['decks']}
    out = []
    for ri, r in enumerate(roads):
        s = r['s']
        if len(s) < 3 or r.get('closed') or r['kind'] == 'side':
            continue
        cut = cutd.get(r['name'], set())
        for k, fl, ed in ((0, 'startsOnEnd', 'edgeStart'), (-1, 'endsOnEnd', 'edgeEnd')):
            i0 = 0 if k == 0 else len(s) - 1
            if r.get(fl) or r.get(ed) or i0 in cut:
                continue
            q = s[k]
            p = Point(q[0], q[2])
            if not J.query_ball_point((q[0], q[2]), 12.0):  # (Sagawar 2 street: OSM's end 11 off ours, on the road)
                # (or our end lies inside an OSM way, away from its ends: the way goes on, so must ours)
                mid = [int(j) for j in OT.query(p.buffer(3)) if OL[int(j)].distance(p) < 3
                       and min(Point(OL[int(j)].coords[e]).distance(p) for e in (0, -1)) > 6]
                if not mid:
                    continue  # not a join in OSM
            if any(math.hypot(q[0] - g['c'][0], q[2] - g['c'][2]) < g['r_out'] + 2 for g in data['roundabouts']):
                continue
            if any(math.hypot(q[0] - x, q[2] - z) < 40 for x, z in feet):
                continue
            if any(endpts[j][2] != ri for j in ET.query_ball_point((q[0], q[2]), 4.0)):
                continue
            near = [int(j) for j in tree.query(p.buffer(14)) if int(j) != ri and lines[int(j)] is not None]
            if not near:
                continue
            dmin = min(geoms[j].distance(p) for j in near)
            # tail (end first): the last ~48 studs
            seq = list(range(len(s))) if k == -1 else list(range(len(s) - 1, -1, -1))
            tail = seq[::-1][:7]  # end sample first
            tl = LineString([(s[i][0], s[i][2]) for i in tail])
            over = None
            if dmin > 0.5:
                for j in near:
                    if roads[j]['rank'] < r['rank'] and tl.intersects(geoms[j]):
                        X = tl.intersection(lines[j])
                        if not X.is_empty:
                            over = j
                            break
            if over is None and not (0.9 < dmin <= 12):
                continue
            if r['name'] in deck_of or any(i in cut for i in tail):
                continue
            if over is not None:
                j = over
                X = tl.intersection(lines[j])
                pts = list(X.geoms) if hasattr(X, 'geoms') else [X]
                tp = min(pts, key=lambda P: tl.project(P))  # the crossing nearest the end
                # cut the tail back: drop samples past the crossing, end exactly on it
                a = tl.project(tp)
                acc, keep = 0.0, 0
                for m in range(1, len(tail)):
                    acc += math.hypot(s[tail[m]][0] - s[tail[m - 1]][0], s[tail[m]][2] - s[tail[m - 1]][2])
                    if acc > a + 0.01:
                        keep = m
                        break
                if keep == 0:
                    continue
                drop = keep  # samples tail[0 .. keep-1] go, a new end at tp
                nq = list(s[tail[keep]])
                nq[0], nq[2] = round(tp.x, 2), round(tp.y, 2)
                if k == -1:
                    del s[len(s) - drop:]
                    s.append(nq)
                    _set_dirs(s, [len(s) - 1])
                else:
                    del s[:drop]
                    s.insert(0, nq)
                    _shift_idx(data, r['name'], 1 - drop, cutd)
                    _set_dirs(s, [0])
                out.append(dict(road=r['name'], on=roads[j]['name'], how='cut back', x=round(tp.x, 1), z=round(tp.y, 1)))
                continue
            j = min(near, key=lambda jj: geoms[jj].distance(p))
            if dmin < 0.9 or geoms[j].distance(p) > 12:
                continue
            tp = lines[j].interpolate(lines[j].project(p))
            vx, vz = tp.x - q[0], tp.y - q[2]
            mv = math.hypot(vx, vz)
            if mv < 0.5:
                # on that road's centre line, in a gap of its cut samples (it is cut for THIS road, a rank-inverted
                # T: Independence Street on Bayint Naung Street): run on straight across the gap to its far edge
                cj = cutd.get(roads[j]['name'], set())
                os_ = roads[j]['s']
                if not cj or min(math.hypot(os_[i][0] - q[0], os_[i][2] - q[2]) for i in cj if i < len(os_)) > 40:
                    continue
                bi = min(range(len(os_)), key=lambda i: (os_[i][0] - q[0]) ** 2 + (os_[i][2] - q[2]) ** 2)
                t_ = max(os_[bi][6], os_[bi][7]) + 1.0
                d = (q[3], q[4]) if k == -1 else (-q[3], -q[4])
                n = max(1, int(math.ceil(t_ / STEP)))
                add = []
                for m in range(1, n + 1):
                    nq = list(q)
                    nq[0], nq[2] = round(q[0] + d[0] * t_ * m / n, 2), round(q[2] + d[1] * t_ * m / n, 2)
                    add.append(nq)
                if k == -1:
                    s.extend(add)
                else:
                    for nq in add:
                        s.insert(0, nq)
                    _shift_idx(data, r['name'], n, cutd)
                out.append(dict(road=r['name'], on=roads[j]['name'], how='across cut gap', run=round(t_, 1), x=round(q[0], 1), z=round(q[2], 1)))
                continue
            dj = geoms[j].distance(p)
            if mv > dj + 2 + max(q[6], q[7]):
                # a wide road (Road #14 beside Lay Daungkan Road #2): land own half + 2 inside its edge, not on its centre
                f = (dj + 2 + max(q[6], q[7])) / mv
                vx, vz, mv = vx * f, vz * f, mv * f
                tp = Point(q[0] + vx, q[2] + vz)
            if mv > 25:
                continue  # (the nearest centre point is past that road's end)
            # height of the other road there
            os_ = roads[j]['s']
            bi = min(range(len(os_)), key=lambda i: (os_[i][0] - tp.x) ** 2 + (os_[i][2] - tp.y) ** 2)
            dy = os_[bi][1] - q[1]
            L = max(40.0, 4 * mv)
            along, moved = 0.0, []
            for m, i in enumerate(seq[::-1]):
                if m:
                    pi = seq[::-1][m - 1]
                    along += math.hypot(s[i][0] - s[pi][0], s[i][2] - s[pi][2])
                u = 1 - along / L
                if u <= 0:
                    break
                w = u * u * (3 - 2 * u)
                s[i][0] = round(s[i][0] + vx * w, 2)
                s[i][2] = round(s[i][2] + vz * w, 2)
                s[i][1] = round(s[i][1] + dy * w, 3)
                moved.append(i)
            if any(i in cut for i in moved) or len(moved) >= len(s) - 1:
                continue  # (cannot happen often; the move stays, the mouth tools decide)
            _set_dirs(s, moved)
            out.append(dict(road=r['name'], on=roads[j]['name'], how='bend', move=round(mv, 1), x=round(tp.x, 1), z=round(tp.y, 1)))
    return out


DECK_MAX = 0.078   # QA deck_grade is 8%
DECK_FLAT = 24.0   # roads05.deck_profile's level start off each foot
DECK_CLEAR = 13.5  # 4.5 m under a deck over another road (3 studs a metre; the usual road minimum)


def deck_regrade(data):
    """(J13) roads05.deck_profile lets a short deck climb as steep as its top needs (up to 45%: QA deck_grade 24).
    Each deck is re-profiled with its grade capped at DECK_MAX: level DECK_FLAT off each foot, straight ramps, the
    top no higher than the ramps reach; never lower than DECK_CLEAR over a road it crosses (where that cannot be
    met at DECK_MAX the deck keeps the grade it needs there). Feet take their road's height (deck_foot)."""
    R = {r['name']: r for r in data['roads']}
    lines = [(r, LineString([(q[0], q[2]) for q in r['s']])) for r in data['roads'] if len(r['s']) > 1]
    out = []
    for dk in data['decks']:
        r = R.get(dk['of'])
        s = dk['s']
        if r is None or len(s) < 3:
            continue
        y0, y1 = r['s'][dk['from']][1], r['s'][dk['to']][1]
        c = [0.0]
        for a, b in zip(s, s[1:]):
            c.append(c[-1] + math.hypot(b[0] - a[0], b[2] - a[2]))
        L = c[-1]
        old = [q[1] for q in s]
        top = max(old)
        # what it crosses: the lowest height it must keep at each crossing
        DL = LineString([(q[0], q[2]) for q in s])
        need = []
        for o, ol in lines:
            if o['name'] == r['name'] or o.get('kind') == 'side':
                continue
            if not DL.intersects(ol):
                continue
            X = DL.intersection(ol)
            for P in (list(X.geoms) if hasattr(X, 'geoms') else [X]):
                if P.geom_type != 'Point':
                    continue
                cc = DL.project(P)
                if cc < DECK_FLAT + 10 or cc > L - DECK_FLAT - 10:
                    continue  # at a foot, not under the deck
                oi = min(range(len(o['s'])), key=lambda i: (o['s'][i][0] - P.x) ** 2 + (o['s'][i][2] - P.y) ** 2)
                if abs(o['s'][oi][1] - (y0 + (y1 - y0) * cc / L)) < 8:  # a ground road under it (not another deck)
                    m = max(0, min(len(s) - 2, next((i for i in range(len(c) - 1) if c[i + 1] >= cc), len(s) - 2)))
                    oy = old[m] + (old[m + 1] - old[m]) * (cc - c[m]) / max(c[m + 1] - c[m], 1e-6)
                    need.append((cc, min(oy, o['s'][oi][1] + DECK_CLEAR)))  # never lower than now under 5 m
        g = max(DECK_MAX, abs(y1 - y0) / max(L - 2 * DECK_FLAT, 1.0) * 1.05)
        for cc, ny in need:  # the grade a crossing needs
            run0, run1 = cc - DECK_FLAT, L - cc - DECK_FLAT
            if run0 > 1:
                g = max(g, (ny - y0) / run0)
            if run1 > 1:
                g = max(g, (ny - y1) / run1)
        ny_ = [min(top, y0 + g * max(0.0, x - DECK_FLAT), y1 + g * max(0.0, L - x - DECK_FLAT)) for x in c]
        k = 3
        if len(ny_) > 2 * k + 1:
            pad = [ny_[0]] * k + ny_ + [ny_[-1]] * k
            ny_ = [sum(pad[i:i + 2 * k + 1]) / (2 * k + 1) for i in range(len(ny_))]
        ny_[0], ny_[-1] = y0, y1
        gmax = max(abs(ny_[i + 1] - ny_[i]) / max(c[i + 1] - c[i], 1e-6) for i in range(len(s) - 1))
        gold = max(abs(old[i + 1] - old[i]) / max(c[i + 1] - c[i], 1e-6) for i in range(len(s) - 1))
        if gmax > max(0.08, gold) - 1e-6 and gold <= 0.08:
            continue  # (no better than it was)
        if gmax >= gold:
            out.append(dict(deck=dk['name'], kept=True, grade=round(gold, 3), crossings=len(need)))
            s[0][1], s[-1][1] = y0, y1  # feet only (deck_foot)
            continue
        for q, y in zip(s, ny_):
            q[1] = round(y, 3)
        out.append(dict(deck=dk['name'], top=round(top - max(ny_), 1), grade=round(gmax, 3), crossings=len(need)))
    return out


def deck_butt(data):
    """(J13, owner: open gaps where deck ends meet, P3 / Sule Pagoda Road's deck forking into Alan Pya Pagoda Road's and
    Gyophyu Road's by Yangon Central). Deck ends that meet (within 6 studs) are fitted onto the widest one's end
    cross-section: one branch takes it whole, two or more split it at the middle between their inner edges. Each
    branch's first sample lies on that end line exactly (centre, halves, direction), tapering back to its own over
    MORPH studs; its heights are left alone (the decks already share the end height)."""
    ends = []
    for d in data['decks']:
        if len(d['s']) > 2:
            ends += [(d, 0), (d, -1)]
    used, out = set(), []
    for d, k in ends:
        if (id(d), k) in used:
            continue
        q = d['s'][k]
        reach = max(6.0, q[6] + q[7])  # (Sule Pagoda Road's deck end: the two branch ends sit 27 off its centre)
        grp = [(e, kk) for e, kk in ends if math.hypot(e['s'][kk][0] - q[0], e['s'][kk][2] - q[2]) < reach]
        if len(grp) < 2:
            continue
        host, hk = max(grp, key=lambda g: g[0]['s'][g[1]][6] + g[0]['s'][g[1]][7])
        h = host['s'][hk]
        fx, fz = (h[3], h[4]) if hk == -1 else (-h[3], -h[4])  # the host's direction out of this end
        L = math.hypot(fx, fz) or 1
        fx, fz = fx / L, fz / L
        rx, rz = -fz, fx
        HL, HR = (h[6], h[7]) if hk == -1 else (h[7], h[6])  # host halves on (left, right) of fx
        br = []
        for e, kk in grp:
            if e is host:
                continue
            b = e['s'][kk]
            lat = (b[0] - h[0]) * rx + (b[2] - h[2]) * rz
            if abs((b[0] - h[0]) * fx + (b[2] - h[2]) * fz) > 8 or not (-HL - 1 < lat < HR + 1):
                continue  # (not on the host's end line: a parallel deck landing beside it)
            bl, brr = (b[6], b[7]) if kk == 0 else (b[7], b[6])  # branch halves on (left, right) of fx
            br.append((lat, bl, brr, e, kk))
            used.add((id(e), kk))
        if not br:
            continue
        used.add((id(host), hk))
        br.sort(key=lambda x: x[0])
        if len(br) >= 2:
            # a fork (two decks leaving one): the host's end widens to span both branches (tapering back over
            # MORPH), each branch starts exactly on that end line, in the host's direction; the gap between the
            # branches beyond it is real (two bridges side by side, Alan Pya Pagoda Rd / Gyophyu Rd)
            lo = min(lat - bl for lat, bl, brr, e, kk in br)
            hi = max(lat + brr for lat, bl, brr, e, kk in br)
            lo, hi = min(lo, -HL), max(hi, HR)
            cmid, half = (lo + hi) / 2, (hi - lo) / 2
            hs = host['s'] if hk == 0 else host['s'][::-1]
            along = 0.0
            for i, x in enumerate(hs):
                if i:
                    along += math.hypot(x[0] - hs[i - 1][0], x[2] - hs[i - 1][2])
                u = 1 - along / MORPH
                if u <= 0:
                    break
                w = u * u * (3 - 2 * u)
                x[0] = round(x[0] + rx * cmid * w, 2)
                x[2] = round(x[2] + rz * cmid * w, 2)
                x[6] = round(x[6] + (half - x[6]) * w, 2)
                x[7] = round(x[7] + (half - x[7]) * w, 2)
            for lat, bl, brr, e, kk in br:
                b = e['s'][kk]
                b[0], b[2] = round(h[0] + rx * lat, 2), round(h[2] + rz * lat, 2)
                b[3], b[4] = round(fx * (1 if kk == 0 else -1), 4), round(fz * (1 if kk == 0 else -1), 4)
                out.append(dict(deck=e['name'], host=host['name'], fork=True, host_span=[round(lo, 1), round(hi, 1)]))
            continue
        lo = -HL
        for n_, (lat, bl, brr, e, kk) in enumerate(br):
            hi = HR if n_ == len(br) - 1 else ((lat + brr) + (br[n_ + 1][0] - br[n_ + 1][1])) / 2
            c = ((lo + hi) / 2, (hi - lo) / 2)
            s = e['s'] if kk == 0 else e['s'][::-1]
            # the branch's samples in its own direction (left / right halves s[6] / s[7] of its stored direction)
            sgn = 1 if kk == 0 else -1
            along = 0.0
            for i, x in enumerate(s):
                if i:
                    along += math.hypot(x[0] - s[i - 1][0], x[2] - s[i - 1][2])
                u = 1 - along / MORPH
                if u <= 0:
                    break
                w = u * u * (3 - 2 * u)
                own = (x[0] - h[0]) * rx + (x[2] - h[2]) * rz  # its lateral place now
                if i == 0:
                    x[0], x[2] = round(h[0] + rx * c[0], 2), round(h[2] + rz * c[0], 2)
                    x[3], x[4] = round(fx * sgn, 4), round(fz * sgn, 4)
                else:
                    x[0] = round(x[0] + rx * (c[0] - lat) * w, 2)
                    x[2] = round(x[2] + rz * (c[0] - lat) * w, 2)
                x[6] = round(x[6] + (c[1] - x[6]) * w, 2)
                x[7] = round(x[7] + (c[1] - x[7]) * w, 2)
            out.append(dict(deck=e['name'], host=host['name'], span=[round(lo, 1), round(hi, 1)], moved=round(c[0] - lat, 1)))
            lo = hi
    return out


def _shift_idx(data, name, n, cutd):
    """sample indices of road `name` move by n (samples added / removed at its start)"""
    if name in data['cut']:
        cutd[name] = set(i + n for i in cutd[name] if i + n >= 0)
        data['cut'][name] = sorted(cutd[name])
    for dk in data['decks']:
        if dk['of'] == name:
            dk['from'] += n
            dk['to'] += n


def main():
    tag = sys.argv[1]
    D = os.path.join(geo.BUILD, 'city_1to1', 'roads05_' + tag)
    raw = os.path.join(D, 'roads_unfixed.json')  # roads05.py's own output: every fix starts from it (re-runnable)
    if not os.path.exists(raw):
        os.replace(os.path.join(D, 'roads.json'), raw)
    data = json.load(open(raw, encoding='utf-8'))
    import roads05_chain
    chained = roads05_chain.chain(data)
    chained['continuations'] = roads05_chain.continuations(data)
    import roads05_absorb
    chained['absorb'] = roads05_absorb.absorb(data)
    chained['duplicates_dropped'] = drop_dups(data)
    chained['ring_clear'] = ring_clear(data)
    chained['ring_level'] = ring_level(data)
    chained['osm_joins'] = osm_joins(data)
    chained['deck_regrade'] = deck_regrade(data)
    chained['deck_butt'] = deck_butt(data)
    print('chain', json.dumps(chained))
    roads = data['roads']
    cutd = {k: set(v) for k, v in data['cut'].items()}
    names = [r['name'] for r in roads]
    geoms = [unary_union(quads(r['s'], cutd.get(r['name'], ()))) for r in roads]
    tree = STRtree(geoms)
    rank = {r['name']: r['rank'] for r in roads}
    rings = [Point(g['c'][0], g['c'][2]).buffer(g['r_out'] + 1, 64) for g in data['roundabouts']]
    ringU = unary_union(rings) if rings else Polygon()
    st = dict(chain=chained, ends_extended=0, extend_studs=0.0, ends_unreached=[], median_samples_cleared=0)
    # 1. mouths
    for ri, r in enumerate(roads):
        s = r['s']
        if len(s) < 2 or r.get('closed'):
            continue
        cut = cutd.get(r['name'], set())
        for k in (0, -1):
            if (k == 0 and 0 in cut) or (k == -1 and len(s) - 1 in cut):
                continue
            if r.get('startsOnEnd' if k == 0 else 'endsOnEnd'):
                continue  # carries on from another road's end: no mouth
            q = s[k]
            p = Point(q[0], q[2])
            # a ring arm: both its edges must end inside the ring's outer polygon (buildMouth walks them to it),
            # an arm arriving off-centre is run on straight (the part inside R_OUT - 14 is cut by the builder anyway)
            for g in data['roundabouts']:
                cx, cz, ro = g['c'][0], g['c'][2], g['r_out']
                if math.hypot(q[0] - cx, q[2] - cz) >= ro:
                    continue
                d = np.array([q[3], q[4]]) * (1 if k == -1 else -1)
                d = d / (np.linalg.norm(d) or 1)
                right = np.array([-d[1], d[0]])
                rv = ro / math.cos(math.pi / 96) - 1.5
                t = 0.0
                while t < 80:
                    c = np.array([q[0], q[2]]) + d * t
                    if all(math.hypot(*(c + right * sd * h - np.array([cx, cz]))) < rv for sd, h in ((-1, max(q[6], q[7])), (1, max(q[6], q[7])))):
                        break
                    t += 2.0
                if t > 0 and t < 80:
                    add = []
                    for i in range(1, int(math.ceil(t / STEP)) + 1):
                        tt = min(t, i * STEP)
                        nq = list(q)
                        nq[0], nq[2] = round(q[0] + d[0] * tt, 2), round(q[2] + d[1] * tt, 2)
                        add.append(nq)
                    if k == -1:
                        s.extend(add)
                    else:
                        for nq in add:
                            s.insert(0, nq)
                        if r['name'] in cutd:
                            cutd[r['name']] = set(i + len(add) for i in cutd[r['name']])
                            data['cut'][r['name']] = sorted(cutd[r['name']])
                        for dk in data['decks']:
                            if dk['of'] == r['name']:
                                dk['from'] += len(add)
                                dk['to'] += len(add)
                    st['ring_arms_extended'] = st.get('ring_arms_extended', 0) + 1
                break
            if ringU.distance(p) < 2:
                continue
            big = None
            for j in tree.query(p.buffer(12)):
                o = names[int(j)]
                if o != r['name'] and rank[o] < rank[r['name']] and geoms[int(j)].distance(p) < 12:
                    if big is None or geoms[int(j)].distance(p) < geoms[big].distance(p):
                        big = int(j)
            if big is None or r['kind'] == 'side':
                continue  # (a side lane starts / ends on its road's cut end: the builder's own join)
            bs = roads[big]['s']
            if min(math.hypot(bs[e][0] - q[0], bs[e][2] - q[2]) for e in (0, -1)) < 40:
                continue  # end to end (a road running on into the next piece), not a mouth
            G = geoms[big]
            d = np.array([q[3], q[4]]) * (1 if k == -1 else -1)
            right = np.array([-q[4], q[3]])
            need = 0.0
            reach = max(max(x[6] + x[7] for x in roads[big]['s']), 20.0)
            ok = True
            for side, h in ((-1, q[6]), (1, q[7])):
                e = np.array([q[0], q[2]]) + right * side * h
                if G.contains(Point(e)):
                    continue
                ray = LineString([e, e + d * reach])
                X = ray.intersection(G)
                if X.is_empty:
                    ok = False
                    continue
                hits = list(X.geoms) if hasattr(X, 'geoms') else [X]
                need = max(need, min(ray.project(Point(h.coords[0])) for h in hits))
            if not ok:
                st['ends_unreached'].append(dict(road=r['name'], on=names[big], x=round(q[0], 1), z=round(q[2], 1)))
                continue
            if need <= 0.3:
                continue
            need += 1.0  # past the edge, so the edge walk meets it inside a segment
            n = max(1, int(math.ceil(need / STEP)))
            add = []
            for i in range(1, n + 1):
                t = need * i / n
                nq = list(q)
                nq[0] = round(q[0] + d[0] * t, 2)
                nq[2] = round(q[2] + d[1] * t, 2)
                add.append(nq)
            if k == -1:
                s.extend(add)
            else:
                for nq in add:
                    s.insert(0, nq)
                if r['name'] in cutd:  # sample indices move
                    cutd[r['name']] = set(i + n for i in cutd[r['name']])
                    data['cut'][r['name']] = sorted(cutd[r['name']])
                for dk in data['decks']:
                    if dk['of'] == r['name']:
                        dk['from'] += n
                        dk['to'] += n
            st['ends_extended'] += 1
            st['extend_studs'] += need
    # 1b. what the builder's edge walk still fails (mouthsim): smallest edit that passes
    import roads05_repair
    st['repair'] = roads05_repair.repair(data)
    print('repair', json.dumps(dict(st['repair'], fixed=len(st['repair']['fixed']), repair_left=len(st['repair']['repair_left']))))
    st['butt_match'] = butt_match(data)  # (after repair: it flags the last continuations)
    roads = data['roads']
    names = [r['name'] for r in roads]
    cutd = {k: set(v) for k, v in data['cut'].items()}
    geoms = [unary_union(quads(r['s'], cutd.get(r['name'], ()))) for r in roads]
    tree = STRtree(geoms)
    # 2. medians end before any other carriageway / ring
    for ri, r in enumerate(roads):
        s = r['s']
        if not any(q[8] > 0 for q in s):
            continue
        clear = set()
        for i, q in enumerate(s):
            if q[8] <= 0:
                continue
            p = Point(q[0], q[2])
            hit = ringU.distance(p) < MED_GAP
            if not hit:
                for j in tree.query(p.buffer(MED_GAP + q[8])):
                    if names[int(j)] != r['name'] and geoms[int(j)].distance(p) < MED_GAP:
                        hit = True
                        break
            if hit:
                clear.add(i)
        for i in clear:
            s[i][8] = 0
        st['median_samples_cleared'] += len(clear)
    for nm, mx, mz, rr in OWNER_MEDIAN_OFF:
        for r in data['roads']:
            if r['name'] == nm:
                for q in r['s']:
                    if math.hypot(q[0] - mx, q[2] - mz) < rr and q[8] > 0:
                        q[8] = 0
                        st['median_samples_cleared'] += 1
    st['islands'] = islands(data)
    print('islands', st['islands'])
    st['checks'] = check(data)
    txt = json.dumps(data, separators=(',', ':'))
    open(os.path.join(D, 'roads.json'), 'w', encoding='utf-8').write(txt)
    for f in os.listdir(D):
        if f.startswith('Roads05_') and f.endswith('.luau'):
            os.remove(os.path.join(D, f))
    k = 0
    for a in range(0, len(txt), CHUNK):
        k += 1
        part = txt[a:a + CHUNK]
        assert ']==]' not in part
        open(os.path.join(D, 'Roads05_%d.luau' % k), 'w', encoding='utf-8').write('return [==[' + part + ']==]')
    st['extend_studs'] = round(st['extend_studs'])
    json.dump(st, open(os.path.join(D, 'fix.json'), 'w'), indent=1)
    print(json.dumps(dict(st, ends_unreached=len(st['ends_unreached']))))


if __name__ == '__main__':
    main()
