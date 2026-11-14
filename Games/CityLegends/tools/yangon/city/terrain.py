"""Whole-Yangon map (14 Nov 2026): the GROUND of a batch (terrain heights, road beds, water) for Studio.

    python terrain.py 1            (run from Games/CityLegends/tools/yangon/city; ~1 min)
    python terrain.py fill 05 [old_seamfill.json]   (the ground under batch 0.5 streets eased onto batch 1's road ends;
                                   an older fill json's columns go back to the natural ground)

What it makes, on the 4-stud terrain grid, for the batch outline MINUS batch 0.5 (BOX_05 and the v5 game roads' corridors,
roadnet.game_exclusion: batch 0.5's own terrain is never rewritten), plus EXT studs of river and far bank outside the
outline where no other batch lies (so the Hlaing River reaches its far bank):
  * land: ground.Ground's field (SRTM smoothed like d4, blended onto batch 0.5's field over 480 studs outside BOX_05, so the
    seam meets batch 0.5's terrain exactly) shown UNDER (1) stud lower, as batch 0.5's terrain is (YangonTerrain.luau);
  * road beds: under every ground-level road of roads_<tag> (the same network / heights roads.py built: roadnet + heights)
    the ground is the road surface - UNDER across the carriageway, its pavements / edge strips and BED_EXTRA studs past them
    (the meshes' skirts reach 1.6 down, so no gap shows); past that a bank at BANK_S (fill where the road is held above the
    ground, cut where the ground rises beside it) out to BANK_MAX. Bridges / ramps built raised keep the natural ground
    (their piers and walls stand on it);
  * water: every OSM water body (ground.Ground.water: own level from the DEM, natural=water / rivers / ponds / lakes) as
    terrain Water at its level, a riverbed sloping from the shore (1 stud + 0.3 a stud inward, at most 14 under a river,
    8 under a big lake, 4 under a pond; Mud under rivers, Sand under lakes), land within 40 studs at least 0.6 over it,
    Mud on the river banks (24 studs);
  * Singuttara Hill as the DEM gives it (the Shwedagon platform is flattened later from the landmark agent's numbers).
Outputs (build/city/):
  terrain_<tag>/Terrain<tag>_<n>.luau   data modules (one string each, < 189,000 characters), a line per 256-stud tile:
        "tx tz F|P <base>|<codes>|<explicit>"  (tile origin x = tx * 256, z = tz * 256; F = every column ours, P = some
        columns kept as they are). base: 17 x 17 heights (2 chars each) at the tile's 16-stud grid, row by row along x
        (index i * 17 + j, x = X0 + 16 i, z = Z0 + 16 j); codes: run-length pairs (code char, run length char 1..64) over
        the 4096 columns in order ix * 64 + iz; explicit: 2 chars a column for every 'h' / 'n' column (its top) and 4 for
        every 'w' / 'v' column (bed top, water level), in column order.
        Codes: '.' keep, 'g' grass on the base grid, 'm' mud on the base grid, 'h' grass at an explicit top, 'n' mud at an
        explicit top, 'w' water over a mud bed, 'v' water over a sand bed,
        'c' / 'k' concrete on the base grid / at an explicit top (batch 2: the riverfront quay edge and the piers). Heights: 2 base-64 chars (A-Za-z0-9+/), value
        = round((h + 40) * 10), h in studs (the top the terrain SHOWS at).
  terrain_<tag>.png                      preview (heights, water, beds)
  terrain_<tag>_stats.json
Studio: tools/yangon/YangonTerrain2.luau writes it (WriteVoxels per tile, resumable).
"""
import json, math, os, sys, time

import numpy as np
from scipy.ndimage import distance_transform_edt

import geo
import ground
import heights as hts
import roadnet as rn
import roadmesh as rm

OUT = os.path.join(geo.BUILD, 'city')
RES = 4.0
TILE = 256
UNDER = 1.0
BED_EXTRA = 2.0
BANK_S = 0.6
BANK_MAX = 60.0
EXT = 1600.0
CHARS = 189000
B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
WATER_LAND_MIN = 0.6
WATER_NEAR = 40.0
MUD_NEAR = 24.0
OVERLAP_LOW = 6.0
# (2026-11-14, batch 2) the river outside the outline per batch: how far out (studs from the outline), the far-bank strip
# kept (studs from the water), and the land round a bridge landing built past the outline (roadnet.REACH_OUT: the
# Yangon-Dala Bridge lands on Dala-Twante Road). Batch 1 keeps its own rule (west of batch 0.5, EXT, a 600-stud bank).
RIVER_EXT = {'2': dict(reach=2700.0, bank=320.0, landings=[(30391.0, 11066.0, 420.0)], ways=(1219935185,), way_bank=220.0)}
# batches written after another one: shared lakes keep the earlier batch's columns and level, the earlier batch's road
# banks reach over the seam, and the earlier batch's state file is read for both (terrain_<u>_state.npz)
LATER_BATCH_BLEND = {'2': ('1',), '3': ('1', '2')}
# riverfront (batch 2): docks (OSM waterway=dock) are river water; piers (man_made=pier touching the river) are solid
# concrete at the quay's level; land within QUAY_W of the river inside the outline is a concrete quay edge
QUAY_W = 10.0
FAR_SHORE = 120.0          # studs of low far shore where a river runs out of the region into the void
FAR_UP = 1.2
PIER_UP_MIN = 3.0          # a pier's top at least this over the river level


def enc(h):
    v = int(round((float(h) + 40.0) * 10.0))
    v = max(0, min(4095, v))
    return B64[v >> 6] + B64[v & 63]


def dec(s):
    return ((B64.index(s[0]) << 6) + B64.index(s[1])) / 10.0 - 40.0


def regions(tag):
    from shapely.geometry import box as sbox
    from shapely.ops import unary_union
    game, _ = rn.game_roads()
    ex = rn.game_exclusion(game)
    poly = geo.batch_poly(tag)
    core = poly.difference(ex)
    others = unary_union([geo.batch_poly(t) for t in ('1', '2', '3') if t != tag] + [sbox(*geo.BOX_05)])
    return poly, core, others, ex


def road_net(tag, G, log=print):
    net = rn.build(tag)
    q = lambda *a: None
    hts.solve(net, G, log=q)
    if hts.extend_short(net, G, log=q):
        hts.solve(net, G, log=q)
    # check against the profile roads.py wrote with the meshes
    prof = json.load(open(os.path.join(OUT, 'roads_%s_profile.json' % tag)))
    bad = 0
    for e, p in zip(net.edges, prof):
        ys = np.array([q_[1] for q_ in p['pts']])
        if len(ys) != len(e.y) or np.abs(ys - e.y).max() > 0.02:
            bad += 1
    log('  network %d edges, %d differ from roads_%s_profile.json' % (len(net.edges), bad, tag))
    return net


def segments(net):
    """ground-level road segments: A, B (x, z), ya, yb, right half-reach, left half-reach (studs from the line)"""
    S = []
    raised_len = 0.0
    for e in net.edges:
        r = rm.raised_samples(net, e)
        lo, hi = rn.offsets(e)
        paired = e.oneway and bool((e.w > 0.5).any())
        for i in range(len(e.P) - 1):
            if r[i] or r[i + 1]:
                raised_len += float(np.linalg.norm(e.P[i + 1] - e.P[i]))
                continue
            hr = max(hi[i], hi[i + 1]) + e.walk
            l_ = min(lo[i], lo[i + 1])
            hl = (-l_ + e.walk) if l_ <= 0.5 else 0.0
            if paired and l_ > 0.5:
                hl = 0.0
            S.append((e.P[i][0], e.P[i][1], e.P[i + 1][0], e.P[i + 1][1], e.y[i], e.y[i + 1], max(hr, 0.0), max(hl, 0.0)))
    return np.array(S), raised_len


# Landmark ground (lead, 14 Nov 2026, from the landmark agent's models in Workspace.Yangon.Landmarks): the terrain is set to `top`
# under each footprint, then falls at `slope` (1:2.5) to the DEM ground (a smooth max, no crease at the toe); nothing within
# CAP_NEAR of a footprint stands over its top. Covered stairways: the ground is set RAMP_UNDER under the ramp surface (a straight
# line from the platform edge to the foot) across its width + 2, falls at `slope` beside it, and never rises over it there; a pad
# of radius FOOT_PAD at each foot (gates, chinthe) at the foot's level. Roads keep their beds (applied after this).
LANDMARK_GROUND = [
    dict(name='Shwedagon (Singuttara Hill)', top=92.5, slope=0.4,
         poly=[(31871, 3973), (31871, 3617), (31799, 3545), (31473, 3545), (31401, 3617), (31401, 3973), (31473, 4045), (31799, 4045)],
         ramps=[((31698.5, 93.57, 4045.0), (31769.0, 71.91, 4299.0), 26.0), ((31580.5, 93.58, 3545.0), (31553.0, 73.97, 3390.0), 22.0),
                ((31871.0, 93.58, 3779.5), (32129.0, 51.51, 3725.0), 22.0), ((31401.0, 93.58, 3893.5), (31191.0, 63.39, 3948.0), 22.0)]),
    dict(name='Maha Wizaya terrace', top=62.5, slope=0.4, poly=[(32013, 4366), (32153, 4366), (32153, 4506), (32013, 4506)], ramps=[]),
    dict(name='Chaukhtatgyi', top=38.3, slope=0.4, poly=[(33982, 1396), (34162, 1396), (34162, 1552), (33982, 1552)], ramps=[]),
    # (batch 2, 14 Nov 2026) the downtown landmarks' ground: their pads (build/landmarks/YangonLandmarkData_<id>.luau), the
    # terrain 0.6 under each structure's base (the models' gy), roads keep their beds
    dict(name='Sule Pagoda (roundabout island)', top=19.2, slope=0.4, poly=[(33280.0, 8066.0), (33273.9, 8096.6), (33256.6, 8122.6), (33230.6, 8139.9), (33200.0, 8146.0), (33169.4, 8139.9), (33143.4, 8122.6), (33126.1, 8096.6), (33120.0, 8066.0), (33126.1, 8035.4), (33143.4, 8009.4), (33169.4, 7992.1), (33200.0, 7986.0), (33230.6, 7992.1), (33256.6, 8009.4), (33273.9, 8035.4)], ramps=[]),
    dict(name='Yangon City Hall', top=19.5, slope=0.4, poly=[(33258.0, 7981.0), (33287.0, 8008.0), (33337.0, 8009.0), (33337.0, 8013.0), (33340.0, 8013.0), (33340.0, 8019.0), (33387.0, 8021.0), (33387.0, 8014.0), (33390.0, 8014.0), (33390.0, 8011.0), (33437.0, 8013.0), (33448.0, 8002.0), (33451.0, 7887.0), (33270.0, 7881.0), (33261.0, 7881.0), (33261.0, 7888.0)], ramps=[]),
    dict(name='Independence Monument', top=19.6, slope=0.4, poly=[(33361.0, 8294.0), (33358.0, 8309.3), (33349.3, 8322.3), (33336.3, 8331.0), (33321.0, 8334.0), (33305.7, 8331.0), (33292.7, 8322.3), (33284.0, 8309.3), (33281.0, 8294.0), (33284.0, 8278.7), (33292.7, 8265.7), (33305.7, 8257.0), (33321.0, 8254.0), (33336.3, 8257.0), (33349.3, 8265.7), (33358.0, 8278.7)], ramps=[]),
    dict(name='Botataung Pagoda', top=12.5, slope=0.4, poly=[(35546.0, 9186.0), (35546.0, 9046.0), (35516.0, 9016.0), (35396.0, 9016.0), (35366.0, 9046.0), (35366.0, 9186.0), (35396.0, 9216.0), (35516.0, 9216.0)], ramps=[]),
]
RAMP_UNDER = 1.2
FOOT_PAD = 34.0
CAP_NEAR = 60.0
SOFT = 5.0
USE_LANDMARKS = True


def _smax(a, b, k=SOFT):
    return 0.5 * (a + b + np.sqrt((a - b) ** 2 + k * k))


def _smin(a, b, k=SOFT):
    return 0.5 * (a + b - np.sqrt((a - b) ** 2 + k * k))


def landmark_ground(nat, xs, zs, inR, log=print):
    protect = np.zeros(nat.shape, bool)       # under a stairway / on its foot pad: road banks keep off (beds still win)
    if not USE_LANDMARKS:
        return nat, protect
    from shapely.geometry import Polygon
    from shapely import contains_xy, distance as sdist, points
    out = nat.copy()
    for L in LANDMARK_GROUND:
        pg = Polygon(L['poly'])
        reach = (L['top'] - 0.0) / L['slope'] + 80
        x0, z0, x1, z1 = pg.buffer(reach).bounds
        for (a, b, w) in L['ramps']:
            x0, z0 = min(x0, b[0] - 80), min(z0, b[2] - 80)
            x1, z1 = max(x1, b[0] + 80), max(z1, b[2] + 80)
        i0, i1 = max(0, int((x0 - xs[0]) / RES)), min(len(xs), int((x1 - xs[0]) / RES) + 1)
        j0, j1 = max(0, int((z0 - zs[0]) / RES)), min(len(zs), int((z1 - zs[0]) / RES) + 1)
        if i1 <= i0 or j1 <= j0:
            continue
        XX, ZZ = np.meshgrid(xs[i0:i1], zs[j0:j1], indexing='ij')
        sub = (slice(i0, i1), slice(j0, j1))
        n0 = out[sub].copy()
        d = sdist(pg, points(XX.ravel(), ZZ.ravel())).reshape(XX.shape)   # 0 inside
        T = L['top'] - L['slope'] * d
        H = _smax(n0, T)
        H = np.where(d <= 0, L['top'], H)
        H = np.where((d > 0) & (d < CAP_NEAR), np.minimum(H, L['top']), H)
        for (a, b, w) in L['ramps']:
            ax, ay, az = a
            bx, by, bz = b
            dx, dz = bx - ax, bz - az
            L2 = dx * dx + dz * dz
            t = np.clip(((XX - ax) * dx + (ZZ - az) * dz) / L2, 0, 1)
            px, pz = ax + t * dx - XX, az + t * dz - ZZ
            dp = np.sqrt(px * px + pz * pz)
            surf = ay + t * (by - ay) - RAMP_UNDER
            e = np.maximum(dp - (w / 2 + 2), 0)
            Tr = surf - L['slope'] * e
            H = np.where(e <= 0, surf, _smax(H, Tr, 2.0))
            # the foot pad (gates, chinthe) at the foot's level
            df = np.hypot(XX - bx, ZZ - bz)
            ef = np.maximum(df - FOOT_PAD, 0)
            foot = by - RAMP_UNDER
            Tf = foot - L['slope'] * ef
            H = np.where(ef <= 0, foot, _smax(H, Tf, 2.0))
            # under the ramp: exactly under its surface; beside it (6 studs) never over it
            H = np.where(e <= 0, surf, np.where(e < 6, np.minimum(H, surf), H))
        H = np.where(d <= 0, L['top'], H)
        pr = np.zeros(H.shape, bool)
        for (a, b, w) in L['ramps']:
            ax, ay, az = a
            bx, by, bz = b
            dx, dz = bx - ax, bz - az
            t = np.clip(((XX - ax) * dx + (ZZ - az) * dz) / (dx * dx + dz * dz), 0, 1)
            dp = np.hypot(ax + t * dx - XX, az + t * dz - ZZ)
            pr |= (dp <= w / 2 + 2) | (np.hypot(XX - bx, ZZ - bz) <= FOOT_PAD)
        protect[sub] |= pr & inR[sub]
        # only inside the region, and only where it changes something
        changed = inR[sub] & (np.abs(H - n0) > 0.02)
        out[sub] = np.where(changed, H, n0)
        log('  landmark ground %s: %d columns, raised up to %.1f, cut up to %.1f' % (
            L['name'], changed.sum(), float((H - n0)[changed].max()) if changed.any() else 0,
            float((n0 - H)[changed].max()) if changed.any() else 0))
    return out, protect


def profile_segments(u, bounds, pad=200.0):
    """(2026-11-14, batch 2) batch u's ground-level road segments near bounds (x0, z0, x1, z1), from roads_<u>_profile.json
    (as segments() makes them; the reach per edge is its widest), and its ground samples (P, y) for the bed blend"""
    p = os.path.join(OUT, 'roads_%s_profile.json' % u)
    if not os.path.exists(p):
        return [], None, None
    x0, z0, x1, z1 = bounds
    S, P, Y = [], [], []
    for e in json.load(open(p)):
        pts = e['pts']
        xs_ = [q[0] for q in pts]
        zs_ = [q[2] for q in pts]
        if max(xs_) < x0 - pad or min(xs_) > x1 + pad or max(zs_) < z0 - pad or min(zs_) > z1 + pad:
            continue
        hl_, hr_ = e['half']
        hr = hr_ + e['walk']
        hl = (hl_ + e['walk']) if hl_ >= -0.5 else 0.0
        low = [(q[1] - q[3]) <= hts.RAISE for q in pts]
        for i in range(len(pts) - 1):
            if not (low[i] and low[i + 1]):
                continue
            a, b = pts[i], pts[i + 1]
            S.append((a[0], a[2], b[0], b[2], a[1], b[1], max(hr, 0.0), max(hl, 0.0)))
        for q, lo_ in zip(pts, low):
            if lo_:
                P.append((q[0], q[2]))
                Y.append(q[1])
    if not P:
        return S, None, None
    return S, np.array(P), np.array(Y)


_EARLIER = {}


def earlier_level(tag, pg):
    """(2026-11-14, batch 2) the water level an earlier batch wrote inside polygon pg (median of its water columns), or None"""
    from shapely import contains_xy
    vals = []
    for u in LATER_BATCH_BLEND.get(tag, ()):
        if u not in _EARLIER:
            sp = os.path.join(OUT, 'terrain_%s_state.npz' % u)
            _EARLIER[u] = dict(np.load(sp)) if os.path.exists(sp) else None
        st = _EARLIER[u]
        if st is None:
            continue
        ox, oz = st['origin']
        nx_, nz_ = st['code'].shape
        bx0, bz0, bx1, bz1 = pg.bounds
        i0, i1 = max(0, int((bx0 - ox) / RES)), min(nx_, int((bx1 - ox) / RES) + 1)
        j0, j1 = max(0, int((bz0 - oz) / RES)), min(nz_, int((bz1 - oz) / RES) + 1)
        if i1 <= i0 or j1 <= j0:
            continue
        XX, ZZ = np.meshgrid(ox + RES * np.arange(i0, i1) + RES / 2, oz + RES * np.arange(j0, j1) + RES / 2, indexing='ij')
        ins = contains_xy(pg, XX, ZZ) & (st['code'][i0:i1, j0:j1] >= 3)
        if ins.any():
            vals.append(st['level'][i0:i1, j0:j1][ins])
    if not vals:
        return None
    return float(np.median(np.concatenate(vals)))


def build(tag, log=print, diff=False):
    t0 = time.time()
    from shapely import contains_xy
    from shapely.geometry import box as sbox, Point
    from shapely.ops import unary_union
    G = ground.Ground()
    poly, core, others, ex = regions(tag)
    rivers = [w for w in G.water if w['kind'] in ('river', 'riverbank', 'canal') or w['name'] == 'Simmalaik Dockyard']
    piers = []
    if tag in RIVER_EXT and rivers:
        rv_all = unary_union([w['poly'] for w in rivers])
        lvl = min(w['level_m'] for w in rivers)
        from shapely.geometry import Polygon as _P
        for a in geo.load('areas'):
            t = a['t']
            if len(a['p']) < 4:
                continue
            if t.get('waterway') == 'dock' or t.get('man_made') == 'pier':
                pg = _P(geo.proj(a['p'])).buffer(0)
                if pg.is_empty or pg.distance(rv_all) > 30.0:
                    continue
                if t.get('waterway') == 'dock':
                    d_ = dict(id=a['id'], name='dock', kind='dock', level_m=lvl, area_ha=pg.area / 2.56 / 1e4, poly=pg, big=False)
                    G.water.append(d_)
                    rivers.append(d_)
                else:
                    piers.append(pg)
        log('  riverfront: %d docks, %d piers' % (sum(1 for w in rivers if w['kind'] == 'dock'), len(piers)))
    riv_u = unary_union([w['poly'] for w in rivers]) if rivers else None
    # outside the outline: the river and its far bank west of batch 0.5 (no other batch there), and every water body the
    # outline cuts, whole, with a 60-stud bank (a lake cut by the outline would end in a wall of water)
    xr = RIVER_EXT.get(tag)
    if xr is None:
        ext = poly.buffer(EXT).difference(poly).difference(others).intersection(sbox(-1e9, -1e9, geo.BOX_05[0], 1e9))
        bank_ = 600
    else:
        # (batch 2) the Yangon River to its far (Dala) bank and Pazundaung Creek: every side, a narrower far-bank strip
        ext = poly.buffer(xr['reach']).difference(poly).difference(others)
        bank_ = xr['bank']
    if riv_u is not None:
        ext = ext.intersection(riv_u.buffer(bank_))
    else:
        ext = ext.intersection(poly.buffer(-1e9))
    cut = [w['poly'] for w in G.water if w not in rivers and w['area_ha'] < 100 and w['poly'].intersects(core) and not w['poly'].within(core)]
    if cut:
        cu = unary_union(cut).buffer(60).difference(poly).difference(sbox(*geo.BOX_05)).difference(ex)
        if tag in LATER_BATCH_BLEND:
            # (batch 2) a lake an earlier batch already wrote (Kandawgyi's north part in batch 1) keeps that batch's
            # columns: only its own part is written here, at the earlier batch's level (water_levels_written)
            cu = cu.difference(others)
        ext = ext.union(cu)
    # (only pieces that touch the batch: a stray bit of bank far off would float in the void)
    near_core = core.buffer(16)
    ext = unary_union([g for g in getattr(ext, 'geoms', [ext]) if g.geom_type == 'Polygon' and g.intersects(near_core)])
    if xr is not None and xr.get('landings'):
        # the landing of a bridge built on past the outline (roadnet.REACH_OUT): its far bank round it
        for lx, lz, r_ in xr['landings']:
            ext = ext.union(Point(lx, lz).buffer(r_).difference(others))
        # and the far bank along the bridge out to that landing (no void between the river's bank strip and the landing)
        from shapely.geometry import LineString as _LS
        ways = [r['p'] for r in geo.load('roads') if r['id'] in xr.get('ways', ())]
        for w_ in ways:
            ext = ext.union(_LS(geo.proj(w_)).buffer(xr.get('way_bank', 220.0)).difference(poly).difference(others))
    region = core.union(ext)
    x0, z0, x1, z1 = region.buffer(64).bounds
    X0 = math.floor(x0 / TILE) * TILE
    Z0 = math.floor(z0 / TILE) * TILE
    X1 = math.ceil(x1 / TILE) * TILE
    Z1 = math.ceil(z1 / TILE) * TILE
    nx, nz = int((X1 - X0) / RES), int((Z1 - Z0) / RES)
    xs = X0 + RES * np.arange(nx) + RES / 2
    zs = Z0 + RES * np.arange(nz) + RES / 2
    log('grid %d x %d (%d columns), x %d..%d z %d..%d' % (nx, nz, nx * nz, X0, X1, Z0, Z1))
    # ---- road beds first (they also widen the region: a road on the outline has half its pavement outside it)
    net = road_net(tag, G, log)
    S, raised_len = segments(net)
    log('  %d ground road segments, %.0f studs built raised (natural ground under them) (%.0f s)' % (len(S), raised_len, time.time() - t0))
    best = np.full((nx, nz), np.inf, np.float32)     # excess over the footprint of the nearest road
    bedv = np.zeros((nx, nz), np.float32)            # that road's bed
    lowb = np.full((nx, nz), np.inf, np.float32)     # the lowest bed of every footprint holding the column
    for (ax, az, bx, bz, ya, yb, hr, hl) in S:
        reach = max(hr, hl) + BED_EXTRA + BANK_MAX
        i0 = max(0, int((min(ax, bx) - reach - X0) / RES))
        i1 = min(nx, int((max(ax, bx) + reach - X0) / RES) + 1)
        j0 = max(0, int((min(az, bz) - reach - Z0) / RES))
        j1 = min(nz, int((max(az, bz) + reach - Z0) / RES) + 1)
        if i1 <= i0 or j1 <= j0:
            continue
        px = xs[i0:i1][:, None]
        pz = zs[j0:j1][None, :]
        dx, dz = bx - ax, bz - az
        L2 = dx * dx + dz * dz
        if L2 < 1e-6:
            continue
        t = np.clip(((px - ax) * dx + (pz - az) * dz) / L2, 0.0, 1.0)
        qx = ax + t * dx - px
        qz = az + t * dz - pz
        dist = np.sqrt(qx * qx + qz * qz)
        u = (px - ax) * (-dz) + (pz - az) * dx      # right of the direction (R = (-D.z, D.x)), times |D|
        hw = np.where(u >= 0, hr, hl)
        exc = dist - hw
        bed = ya + t * (yb - ya) - UNDER
        sub = (slice(i0, i1), slice(j0, j1))
        inside = exc <= BED_EXTRA
        if inside.any():
            lowb[sub] = np.where(inside, np.minimum(lowb[sub], bed), lowb[sub])
        better = exc < best[sub]
        if not better.any():
            continue
        best[sub] = np.where(better, exc, best[sub])
        bedv[sub] = np.where(better, bed, bedv[sub])
    best_own = best.copy()
    # (2026-11-14, batch 2) the earlier batches' ground roads by the seam (from their roads_<u>_profile.json): their banks
    # reach over the seam into this batch's ground (never widening this batch's region)
    oHP, oHH = [], []
    for u in LATER_BATCH_BLEND.get(tag, ()):
        S2, P2, Y2 = profile_segments(u, (X0, Z0, X0 + nx * RES, Z0 + nz * RES))
        if P2 is not None:
            oHP.append(P2)
            oHH.append(Y2)
        nb_ = 0
        for (ax, az, bx, bz, ya, yb, hr, hl) in S2:
            reach = max(hr, hl) + BED_EXTRA + BANK_MAX
            i0 = max(0, int((min(ax, bx) - reach - X0) / RES))
            i1 = min(nx, int((max(ax, bx) + reach - X0) / RES) + 1)
            j0 = max(0, int((min(az, bz) - reach - Z0) / RES))
            j1 = min(nz, int((max(az, bz) + reach - Z0) / RES) + 1)
            if i1 <= i0 or j1 <= j0:
                continue
            px = xs[i0:i1][:, None]
            pz = zs[j0:j1][None, :]
            dx, dz = bx - ax, bz - az
            L2 = dx * dx + dz * dz
            if L2 < 1e-6:
                continue
            t = np.clip(((px - ax) * dx + (pz - az) * dz) / L2, 0.0, 1.0)
            qx = ax + t * dx - px
            qz = az + t * dz - pz
            dist = np.sqrt(qx * qx + qz * qz)
            u_ = (px - ax) * (-dz) + (pz - az) * dx
            exc = dist - np.where(u_ >= 0, hr, hl)
            bed = ya + t * (yb - ya) - UNDER
            sub = (slice(i0, i1), slice(j0, j1))
            better = exc < best[sub]
            if better.any():
                nb_ += 1
                best[sub] = np.where(better, exc, best[sub])
                bedv[sub] = np.where(better, bed, bedv[sub])
        log('  batch %s roads by the seam: %d segments near this grid, %d reach it' % (u, len(S2), nb_))
    # (2026-11-14) the bed follows the road meshes' own surface: roadmesh.Builder.h, the inverse-distance blend of every
    # road's ground-level samples (6 nearest), so where two carriageways overlap the ground meets the ONE drawn surface
    from scipy.spatial import cKDTree
    HP, HH = list(oHP), list(oHH)
    for e in net.edges:
        r = rm.raised_samples(net, e)
        HP.append(e.P[~r])
        HH.append(e.y[~r])
    HP, HH = np.concatenate(HP), np.concatenate(HH)
    htree = cKDTree(HP)
    near_any = np.isfinite(best) & (best <= BED_EXTRA + BANK_MAX)
    ii, jj = np.nonzero(near_any)
    for k0 in range(0, len(ii), 500000):
        sl = slice(k0, k0 + 500000)
        Q = np.column_stack([xs[ii[sl]], zs[jj[sl]]])
        d, ix = htree.query(Q, k=6)
        w = 1.0 / np.maximum(d, 0.5) ** 2
        bedv[ii[sl], jj[sl]] = (HH[ix] * w).sum(1) / w.sum(1) - UNDER
    log('  road loop done (%.0f s)' % (time.time() - t0))
    # ---- region mask (the outline + river / cut lakes + every road footprint and its first BED_EXTRA + 12 studs, never
    # batch 0.5's ground) and natural ground (rows along z)
    inR = np.zeros((nx, nz), bool)
    nat = np.zeros((nx, nz), np.float32)
    nearR = np.isfinite(best_own) & (best_own <= BED_EXTRA + 12)
    inP = np.zeros((nx, nz), bool)
    inO = np.zeros((nx, nz), bool)
    for i in range(nx):
        X = np.full(nz, xs[i])
        inR[i] = contains_xy(region, X, zs)
        inP[i] = contains_xy(poly, X, zs)
        if tag in RIVER_EXT:
            inO[i] = contains_xy(others, X, zs)
        extra = nearR[i] & ~inR[i]
        if extra.any():
            inR[i] |= extra & ~contains_xy(ex, X, zs)
        if inR[i].any():
            nat[i] = G.ys(np.column_stack([X, zs])) - UNDER
    # (2026-11-14, batch 2) outside this batch's own outline, never rewrite a column an earlier batch wrote (batch 1's
    # Hlaing River ext, its lake banks): the owner of a column is the batch whose outline holds it
    for u in LATER_BATCH_BLEND.get(tag, ()):
        sp = os.path.join(OUT, 'terrain_%s_state.npz' % u)
        if not os.path.exists(sp):
            continue
        with np.load(sp) as st:
            c_u, (ox, oz) = st['code'], st['origin']
        I = ((xs - RES / 2 - ox) / RES).round().astype(int)
        J = ((zs - RES / 2 - oz) / RES).round().astype(int)
        vi = (I >= 0) & (I < c_u.shape[0])
        vj = (J >= 0) & (J < c_u.shape[1])
        wr = np.zeros((nx, nz), bool)
        wr[np.ix_(vi, vj)] = c_u[np.ix_(I[vi], J[vj])] > 0
        drop = inR & wr & ~inP
        inR &= ~drop
        inO |= wr
        log('  %d columns batch %s wrote outside this outline left as they are' % (drop.sum(), u))
    log('  region %d columns (%.0f s)' % (inR.sum(), time.time() - t0))
    nat, protect = landmark_ground(nat, xs, zs, inR, log)
    H = nat.copy()
    code = np.where(inR, 1, 0).astype(np.int8)   # 0 keep, 1 grass, 2 mud, 3 water mud bed, 4 water sand bed
    level = np.zeros((nx, nz), np.float32)
    # ---- water
    wet = np.zeros((nx, nz), bool)
    bigriv = np.zeros((nx, nz), bool)    # the Yangon River and its docks (not Pazundaung Creek): the quay edge
    nwb = 0
    from shapely.geometry import Polygon as _Poly
    lm_polys = [_Poly(L['poly']).buffer(20) for L in LANDMARK_GROUND] if USE_LANDMARKS else []
    for w in sorted(G.water, key=lambda w: w['level_m']):
        pg = w['poly']
        if not pg.intersects(region):
            continue
        if any(lp.contains(pg.representative_point()) for lp in lm_polys):
            log('  water %s (%.1f m) dropped: it lies on a landmark platform' % (w['name'] or w['id'], w['level_m']))
            continue
        bx0, bz0, bx1, bz1 = pg.bounds
        i0 = max(0, int((bx0 - X0) / RES) - 2)
        i1 = min(nx, int((bx1 - X0) / RES) + 3)
        j0 = max(0, int((bz0 - Z0) / RES) - 2)
        j1 = min(nz, int((bz1 - Z0) / RES) + 3)
        if i1 <= i0 or j1 <= j0:
            continue
        XX, ZZ = np.meshgrid(xs[i0:i1], zs[j0:j1], indexing='ij')
        ins = contains_xy(pg, XX, ZZ) & inR[i0:i1, j0:j1]
        if not ins.any():
            continue
        nwb += 1
        L = w['level_m'] * ground.VS
        # (SRTM over a small pond can read roofs or trees: a level over the ground round it would stand as a block of water)
        if not (w in rivers):
            Lg = float(np.median(H[i0:i1, j0:j1][ins])) + UNDER - 0.6
            if L > Lg:
                L = Lg
            # (batch 2) a lake an earlier batch already wrote keeps that batch's level (Kandawgyi: 25.02)
            Le = earlier_level(tag, pg)
            if Le is not None:
                if abs(Le - L) > 0.05:
                    log('  water %s: level %.2f -> %.2f (as written by an earlier batch)' % (w['name'] or w['id'], L, Le))
                L = Le
        pad = np.pad(ins, 1)
        d = distance_transform_edt(pad)[1:-1, 1:-1] * RES
        river = w in rivers
        dmax = 14.0 if river else (8.0 if w['big'] else 4.0)
        bed = L - np.minimum(dmax, 1.0 + 0.3 * d)
        sub = (slice(i0, i1), slice(j0, j1))
        H[sub] = np.where(ins, bed, H[sub])
        level[sub] = np.where(ins, L, level[sub])
        code[sub] = np.where(ins, 3 if river else 4, code[sub])
        wet[sub] |= ins
        if river and (w['area_ha'] > 300 or w['kind'] == 'dock'):
            bigriv[sub] |= ins
    log('  %d water bodies, %d water columns (%.0f s)' % (nwb, wet.sum(), time.time() - t0))
    # land near water: at least WATER_LAND_MIN over the nearest water's level; mud on river banks
    if wet.any():
        d, idx = distance_transform_edt(~wet, return_indices=True)
        d *= RES
        Lnear = level[idx[0], idx[1]]
        near = (~wet) & inR & (d <= WATER_NEAR)
        H = np.where(near, np.maximum(H, Lnear + WATER_LAND_MIN), H)
        rnear = (~wet) & inR & (d <= MUD_NEAR) & (code[idx[0], idx[1]] == 3)
        if tag in RIVER_EXT:
            # (batch 2) downtown's riverfront is a built quay, not a mud bank: concrete within QUAY_W of the river inside
            # the outline (the far bank keeps its mud)
            quay = rnear & inP & (d <= QUAY_W) & bigriv[idx[0], idx[1]]
            rnear &= ~(inP & bigriv[idx[0], idx[1]])
            code = np.where(quay, 5, code)
            log('  quay edge: %d columns' % quay.sum())
        code = np.where(rnear, 2, code)
        del d, idx, Lnear
    if tag in RIVER_EXT and wet.any():
        # (batch 2) where the river runs out of the region into the void (the OSM extract's edge, the reach limit), a low
        # far shore closes it: water within FAR_SHORE of such an edge becomes grass FAR_UP over the water, rising gently
        void = ~inR & ~inO
        dv = distance_transform_edt(~void) * RES
        shore = wet & ~inP & (dv <= FAR_SHORE)
        if shore.any():
            H = np.where(shore, level + FAR_UP + 0.03 * (FAR_SHORE - dv), H)
            code = np.where(shore, 1, code)
            level = np.where(shore, 0.0, level)
            wet &= ~shore
        log('  far shore where the river meets the void: %d columns' % shore.sum())
        del dv, void
    if piers:
        # piers / jetties: solid concrete from the riverbed up to the quay's level (the land behind them)
        npc = 0
        for pg in piers:
            bx0, bz0, bx1, bz1 = pg.buffer(40).bounds
            i0 = max(0, int((bx0 - X0) / RES))
            i1 = min(nx, int((bx1 - X0) / RES) + 1)
            j0 = max(0, int((bz0 - Z0) / RES))
            j1 = min(nz, int((bz1 - Z0) / RES) + 1)
            if i1 <= i0 or j1 <= j0:
                continue
            XX, ZZ = np.meshgrid(xs[i0:i1], zs[j0:j1], indexing='ij')
            sub = (slice(i0, i1), slice(j0, j1))
            ins = contains_xy(pg, XX, ZZ) & inR[sub]
            if not ins.any():
                continue
            ring = contains_xy(pg.buffer(40), XX, ZZ) & ~ins & inR[sub] & ~wet[sub]
            lv = float(level[sub][wet[sub]].max()) if wet[sub].any() else float(min(w['level_m'] for w in rivers) * ground.VS)
            top = max(lv + PIER_UP_MIN, float(np.median(H[sub][ring])) if ring.any() else lv + PIER_UP_MIN)
            H[sub] = np.where(ins, top, H[sub])
            code[sub] = np.where(ins, 5, code[sub])
            level[sub] = np.where(ins, 0.0, level[sub])
            wet[sub] &= ~ins
            npc += int(ins.sum())
        log('  piers: %d columns' % npc)
    near = inR & np.isfinite(best) & (best <= BED_EXTRA + BANK_MAX)
    onbed = near & (best <= BED_EXTRA)
    bank = near & ~onbed & ~wet & ~protect
    e_ = np.where(bank, best - BED_EXTRA, 0.0)
    Hb = np.clip(H, bedv - BANK_S * e_, bedv + BANK_S * e_)
    H = np.where(onbed, bedv, np.where(bank, Hb, H))
    code = np.where(onbed & wet, 1, code)       # a ground road over a pond / drain: land
    wet &= ~onbed
    log('  beds: %d columns on a bed, %d on a bank (%.0f s)' % (onbed.sum(), bank.sum(), time.time() - t0))
    filled = onbed & (bedv > nat + 0.05)
    log('  bed over the natural ground: %d columns, max %.1f studs' % (filled.sum(), float((bedv - nat)[filled].max()) if filled.any() else 0))
    # ---- tiles (diff: only the tiles that differ from the last state written, terrain_<tag>_state.npz, into
    # terrain_<tag>d/Terrain<tag>d_<n>.luau; the full set otherwise)
    state_p = os.path.join(OUT, 'terrain_%s_state.npz' % tag)
    prev = None
    if diff:
        with np.load(state_p) as zf:
            z_ = {k: zf[k] for k in zf.files}
        assert list(z_['origin']) == [X0, Z0] and z_['H'].shape == H.shape, 'grid changed: write the full set'
        prev = z_
    np.savez_compressed(state_p, H=H.astype(np.float32), code=code, level=level.astype(np.float32), origin=np.array([X0, Z0]))
    sfx = 'd' if diff else ''
    tdir = os.path.join(OUT, 'terrain_%s%s' % (tag, sfx))
    os.makedirs(tdir, exist_ok=True)
    for f in os.listdir(tdir):
        if f.endswith('.luau'):
            os.remove(os.path.join(tdir, f))
    lines = []
    ntx, ntz = nx // 64, nz // 64
    expl_n = 0
    stats_tiles = dict(full=0, partial=0)
    maxerr = 0.0
    for ti in range(ntx):
        for tj in range(ntz):
            sub = (slice(ti * 64, ti * 64 + 64), slice(tj * 64, tj * 64 + 64))
            c = code[sub]
            if not (c > 0).any():
                continue
            if prev is not None and (prev['code'][sub] == c).all() and np.abs(prev['H'][sub] - H[sub]).max() < 0.05 and                     np.abs(prev['level'][sub] - level[sub]).max() < 0.05:
                continue
            TX0, TZ0 = X0 + ti * TILE, Z0 + tj * TILE
            gx = TX0 + 16.0 * np.arange(17)
            gz = TZ0 + 16.0 * np.arange(17)
            GX, GZ = np.meshgrid(gx, gz, indexing='ij')
            base = (G.ys(np.column_stack([GX.ravel(), GZ.ravel()])) - UNDER).reshape(17, 17)
            # bilinear of the base grid at the column centres
            fx = (np.arange(64) * RES + RES / 2) / 16.0
            i_ = np.minimum(fx.astype(int), 15)
            a_ = fx - i_
            Bq = (base[i_][:, i_] * (1 - a_)[:, None] * (1 - a_)[None, :] + base[i_ + 1][:, i_] * a_[:, None] * (1 - a_)[None, :] +
                  base[i_][:, i_ + 1] * (1 - a_)[:, None] * a_[None, :] + base[i_ + 1][:, i_ + 1] * a_[:, None] * a_[None, :])
            h = H[sub]
            lv = level[sub]
            land = (c == 1) | (c == 2) | (c == 5)
            err = np.abs(h - Bq)
            maxerr = max(maxerr, float(err[land & (err < 0.08)].max()) if (land & (err < 0.08)).any() else 0.0)
            chars = np.full((64, 64), '.', dtype='<U1')
            chars[(c == 1) & (err < 0.08)] = 'g'
            chars[(c == 1) & (err >= 0.08)] = 'h'
            chars[(c == 2) & (err < 0.08)] = 'm'
            chars[(c == 2) & (err >= 0.08)] = 'n'
            chars[c == 3] = 'w'
            chars[c == 4] = 'v'
            chars[(c == 5) & (err < 0.08)] = 'c'
            chars[(c == 5) & (err >= 0.08)] = 'k'
            flat = chars.ravel()
            hf = h.ravel()
            lf = lv.ravel()
            rle = []
            k = 0
            while k < 4096:
                ch = flat[k]
                n = 1
                while k + n < 4096 and n < 64 and flat[k + n] == ch:
                    n += 1
                rle.append(ch + B64[n - 1])
                k += n
            ex_ = []
            for k in range(4096):
                ch = flat[k]
                if ch in 'hnk':
                    ex_.append(enc(hf[k]))
                elif ch in 'wv':
                    ex_.append(enc(hf[k]) + enc(lf[k]))
            expl_n += len(ex_)
            full = '.' not in flat
            stats_tiles['full' if full else 'partial'] += 1
            tx, tz = TX0 // TILE, TZ0 // TILE
            lines.append('%d %d %s %s|%s|%s' % (tx, tz, 'F' if full else 'P', ''.join(enc(v) for v in base.ravel()),
                                                 ''.join(rle), ''.join(ex_)))
    mods, cur, size = [], [], 0
    for ln in lines:
        if cur and size + len(ln) + 1 > CHARS - 40:
            mods.append(cur)
            cur, size = [], 0
        cur.append(ln)
        size += len(ln) + 1
    if cur:
        mods.append(cur)
    for k, m in enumerate(mods):
        open(os.path.join(tdir, 'Terrain%s%s_%d.luau' % (tag, sfx, k + 1)), 'w', encoding='utf-8', newline='\n').write(
            'return [==[\n' + '\n'.join(m) + '\n]==]\n')
    tot = sum(len(x) for x in lines)
    log('  %d tiles (%d full, %d partial) in %d modules, %d characters; %d explicit columns; base-grid error <= %.3f' % (
        len(lines), stats_tiles['full'], stats_tiles['partial'], len(mods), tot, expl_n, maxerr))
    st = dict(tag=tag, grid=[nx, nz], origin=[X0, Z0], region_columns=int(inR.sum()), water_columns=int(wet.sum()),
              water_bodies=nwb, bed_columns=int(onbed.sum()), bank_columns=int(bank.sum()),
              fill_max=round(float((bedv - nat)[filled].max()), 2) if filled.any() else 0.0,
              raised_studs=round(raised_len), tiles=len(lines), tiles_full=stats_tiles['full'], tiles_partial=stats_tiles['partial'],
              modules=len(mods), characters=tot, land_min=round(float(H[inR & ~wet].min()), 2), land_max=round(float(H[inR & ~wet].max()), 2),
              land_max_at=[float(xs[np.unravel_index(np.argmax(np.where(inR & ~wet, H, -1e9)), H.shape)[0]]),
                           float(zs[np.unravel_index(np.argmax(np.where(inR & ~wet, H, -1e9)), H.shape)[1]])],
              seconds=round(time.time() - t0))
    json.dump(st, open(os.path.join(OUT, 'terrain_%s%s_stats.json' % (tag, sfx)), 'w'), indent=1)
    preview(tag, H, code, inR, wet, onbed, X0, Z0, nx, nz, poly, core)
    log(json.dumps(st))
    return st


def preview(tag, H, code, inR, wet, onbed, X0, Z0, nx, nz, poly, core):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    s = 4
    img = np.full((nz // s, nx // s, 3), 0.15)
    h = H[::s, ::s].T[:nz // s, :nx // s]
    r = inR[::s, ::s].T[:nz // s, :nx // s]
    wv = wet[::s, ::s].T[:nz // s, :nx // s]
    b = onbed[::s, ::s].T[:nz // s, :nx // s]
    m = (code[::s, ::s].T[:nz // s, :nx // s] == 2)
    hn = np.clip((h - 0) / 80.0, 0, 1)
    img[r] = np.stack([0.25 + 0.5 * hn, 0.45 + 0.45 * hn, 0.2 + 0.3 * hn], -1)[r]
    img[r & m] = (0.45, 0.35, 0.25)
    img[r & b] = (0.35, 0.35, 0.38)
    img[r & wv] = (0.2, 0.45, 0.8)
    fig, ax = plt.subplots(figsize=(16, 16 * nz / nx))
    ax.imshow(img, extent=(X0, X0 + nx * RES, Z0 + nz * RES, Z0), interpolation='nearest')
    for pg in (poly,):
        xs_, zs_ = pg.exterior.xy
        ax.plot(xs_, zs_, color='w', lw=0.8)
    from shapely.geometry import box as sbox
    xs_, zs_ = sbox(*geo.BOX_05).exterior.xy
    ax.plot(xs_, zs_, color='r', lw=0.8)
    ax.set_title('Yangon batch %s ground: height (green, dark low / light high, 0-80 studs), road beds grey, water blue, mud '
                 'brown; white = batch outline, red = BOX_05' % tag, fontsize=9)
    fig.savefig(os.path.join(OUT, 'terrain_%s.png' % tag), dpi=90, bbox_inches='tight')
    plt.close(fig)


def seam_fill(tag='05', log=print, restore=None):
    """(14 Nov 2026) the ground under batch 0.5's streets where streets.py eased them onto a neighbouring batch's road end
    (streets_<tag>_seamfill.json: x, z, surface y, half + walk): the footprint (+ BED_EXTRA) filled up to y - UNDER, a bank
    at slope 1 beside it (at most FILL_BANK studs, never over another street of the box, never lowering anything).
    Writes build/city/terrain_<tag>fill/Terrain<tag>fill_<n>.luau (YangonTerrain2 tiles, every other column kept)."""
    from scipy.spatial import cKDTree
    FILL_BANK = 14.0
    G = ground.Ground()
    smp = json.load(open(os.path.join(OUT, 'streets_%s_seamfill.json' % tag)))['samples']
    # restore: an older seamfill json whose fill is taken back (its columns go back to the natural ground)
    old = json.load(open(restore))['samples'] if restore else []
    if not smp and not old:
        log('no seam fill')
        return
    st = json.load(open(os.path.join(OUT, 'streets_%s.json' % tag), encoding='utf-8'))['streets']
    tdir = os.path.join(OUT, 'terrain_%sfill' % tag)
    os.makedirs(tdir, exist_ok=True)
    for f in os.listdir(tdir):
        os.remove(os.path.join(tdir, f))
    S = np.array(smp + old)
    # every street sample of the box (with its reach), to keep banks off other streets
    allp = np.array([p for s_ in st for p in s_['pts']])
    allr = np.array([s_['half'] + s_['walk'] for s_ in st for _ in s_['pts']])
    tree = cKDTree(allp)
    x0, z0 = S[:, 0].min() - 80, S[:, 1].min() - 80
    x1, z1 = S[:, 0].max() + 80, S[:, 1].max() + 80
    X0, Z0 = math.floor(x0 / TILE) * TILE, math.floor(z0 / TILE) * TILE
    X1, Z1 = math.ceil(x1 / TILE) * TILE, math.ceil(z1 / TILE) * TILE
    nx, nz = int((X1 - X0) / RES), int((Z1 - Z0) / RES)
    xs = X0 + RES * np.arange(nx) + RES / 2
    zs = Z0 + RES * np.arange(nz) + RES / 2
    XX, ZZ = np.meshgrid(xs, zs, indexing='ij')
    P = np.column_stack([XX.ravel(), ZZ.ravel()])
    nat = (G.ys(P) - UNDER).reshape(nx, nz)
    def raised(samples):
        H_ = np.full((nx, nz), -1e9)
        on_ = np.zeros((nx, nz), bool)
        for x, z, y, reach in samples:
            d = np.hypot(XX - x, ZZ - z)
            e = d - (reach + BED_EXTRA)
            on = e <= 0
            on_ |= on
            H_ = np.maximum(H_, np.where(on, y - UNDER, np.where(e <= FILL_BANK, y - UNDER - e, -1e9)))
        return H_, on_
    Hold, onold = raised(old)
    H = np.full((nx, nz), -1e9)
    onbed = np.zeros((nx, nz), bool)
    for x, z, y, reach in smp:
        d = np.hypot(XX - x, ZZ - z)
        e = d - (reach + BED_EXTRA)
        bed = y - UNDER
        on = e <= 0
        onbed |= on
        H = np.maximum(H, np.where(on, bed, np.where(e <= FILL_BANK, bed - e, -1e9)))
    # bank columns under another street of the box (not raised) are left alone
    dd, ii = tree.query(P)
    under_street = (dd <= allr[ii] + 1.0).reshape(nx, nz)
    write = (H > nat + 0.1) & (onbed | ~under_street)
    back = (Hold > nat + 0.1) & (onold | ~under_street) & ~write
    H = np.where(back, nat, H)
    write |= back
    inbox = (XX >= geo.BOX_05[0]) & (XX <= geo.BOX_05[2]) & (ZZ >= geo.BOX_05[1]) & (ZZ <= geo.BOX_05[3])
    write &= inbox
    log('seam fill: %d columns (%d put back to the natural ground), max fill %.1f studs' % (
        write.sum(), (back & inbox).sum(), float((H - nat)[write].max()) if write.any() else 0))
    lines = []
    for ti in range(nx // 64):
        for tj in range(nz // 64):
            sub = (slice(ti * 64, ti * 64 + 64), slice(tj * 64, tj * 64 + 64))
            w = write[sub]
            if not w.any():
                continue
            TX0, TZ0 = X0 + ti * TILE, Z0 + tj * TILE
            flat = np.where(w, 'h', '.').ravel()
            hf = H[sub].ravel()
            rle = []
            k = 0
            while k < 4096:
                ch = flat[k]
                n = 1
                while k + n < 4096 and n < 64 and flat[k + n] == ch:
                    n += 1
                rle.append(ch + B64[n - 1])
                k += n
            ex_ = ''.join(enc(hf[k]) for k in range(4096) if flat[k] == 'h')
            lines.append('%d %d P %s|%s|%s' % (TX0 // TILE, TZ0 // TILE, enc(0) * 289, ''.join(rle), ex_))
    open(os.path.join(tdir, 'Terrain%sfill_1.luau' % tag), 'w', encoding='utf-8', newline='\n').write(
        'return [==[\n' + '\n'.join(lines) + '\n]==]\n')
    log('  %d tiles -> %s' % (len(lines), tdir))


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    if len(sys.argv) > 1 and sys.argv[1] == 'fill':
        seam_fill(sys.argv[2] if len(sys.argv) > 2 else '05', restore=sys.argv[3] if len(sys.argv) > 3 else None)
    else:
        if '--no-landmarks' in sys.argv:
            USE_LANDMARKS = False
        build(sys.argv[1] if len(sys.argv) > 1 else '1', diff='--diff' in sys.argv)
