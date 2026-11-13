"""Yangon map, build step 9c (14 Nov 2026, owner: "Move houses and races"): src/shared/YangonWorld.lua.

The same shape as Monaco's RivieraWorld.lua (tools/map_plan/export_world.py): house lots, races, the delivery
dispatches and drop points, the Legends chips. Plus the Racing Hub lot (rings for every race) near Optima Werkz.

Two passes, because the heights must be the ones Studio built (eased junctions, kerbs, decks):
  python tools/yangon/d15_world.py probe            -> build/yangon_world/probe.json (points to measure) + probe.luau
     run probe.luau in Studio (Edit, execute_luau), save its answer as build/yangon_world/probe_out.txt
  python tools/yangon/d15_world.py build            -> src/shared/YangonWorld.lua + build/yangon_world/lots.json
                                                       (the lot pads for YangonSites.prepare) + preview.png

Rules (from the code, 2026-11-14 workflow "yangon-houses-races-map"):
  * Lots: { id, zone, tier, number, x, y, z, fx, fz, w, d }, (fx, fz) towards the road, y = the pavement top
    in front (EntranceRamp finds the road within 40 of the front edge). Tiers as Monaco: low 60 x 72, mid
    104 x 100, high 120 x 130 (>= 110 x 120 for the underground garage). The front edge 3 studs behind the
    pavement. Clear of every road, deck (40), the roundabout, water, landmarks, venue lots, the hub and each
    other with the pad's margin (YangonSites pads are w + 16 by d + 10).
  * Races follow the main roads' traffic lanes (YangonLanes, way 1 lane 1 = 8 right of the centre line):
    checkpoints every 180 studs, the last one the finish; start >= 60 past a junction with 40 straight behind
    (the grid); nothing within 70 (start) / 90 (finish) of a flyover deck it isn't on; nothing within 160 of
    the roundabout's middle.
  * Dispatch / drops on the middle of a pavement (+0.5 over the pavement top; the client drops the ring
    0.6); chips on a pavement + 2.6 + 0.5, >= 300 apart. Not on cut samples, not within 90 of a road's end,
    not in a deck corridor, not in a venue lot or its forecourt. Every drop at least 900 from both
    dispatches, and the straight line between them never crosses the lake (job time limits are straight-line).
"""
import json, math, os, random, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(ROOT, 'build', 'yangon_world')
src = open(os.path.join(HERE, 'd10_plots.py'), encoding='utf-8').read()
ns = {'__file__': os.path.join(HERE, 'd10_plots.py')}
exec(compile(src[:src.index('# the landmarks first')], 'd10', 'exec'), ns)
road_clear, near_water, in_poly, water = ns['road_clear'], ns['near_water'], ns['in_poly'], ns['water']
R, roads, CUT, RING, MAP, data = ns['R'], ns['roads'], ns['CUT'], ns['RING'], ns['MAP'], ns['data']
X0, X1, Z0, Z1, WALK = ns['X0'], ns['X1'], ns['Z0'], ns['Z1'], ns['WALK']
plots = json.load(open(os.path.join(MAP, 'ygn_plots.json'), encoding='utf-8'))['plots']
landmarks = [p for p in plots if p.get('landmark')]
OPTIMA = [p for p in landmarks if p['landmark'] == 'optima'][0]
rng = random.Random(20261114)

# the lots already used (Config.YangonVenues + the fuel station): (x, z, fx, fz, width, depth)
USED = [
    (30836.8, 957.4, -0.560, -0.829, 216, 216), (31025.7, 646.7, -0.990, -0.144, 216, 216), (31125.7, 960.7, 0.326, 0.945, 216, 216),
    (31074.1, 394.2, -0.991, -0.136, 216, 216), (32358.8, -1833.6, 0.992, 0.127, 216, 216), (30742.3, 223.9, 0.969, -0.249, 216, 216),
    (30730.5, 552.9, 0.987, 0.159, 304, 216), (29745.3, 1089.0, 0, 1, 216, 216), (30655.1, 1303.2, 0, -1, 216, 216),
    (30911.0, 1306.4, 0, -1, 216, 216), (29867.2, 1398.6, 0, -1, 216, 216), (30465.2, 921.7, 0.560, 0.829, 80, 80),
]
DECKS = [d['s'] for d in data['decks']]


def rect(x, z, fx, fz, w, d, grow=0.0):
    ax, az = -fz, fx
    hw, hd = w / 2 + grow, d / 2 + grow
    return [(x + ax * u * hw + fx * v * hd, z + az * u * hw + fz * v * hd) for u, v in ((-1, -1), (1, -1), (1, 1), (-1, 1))]


def overlap(p, q):
    for poly in (p, q):
        for i in range(4):
            a, b = poly[i], poly[(i + 1) % 4]
            nx, nz = -(b[1] - a[1]), b[0] - a[0]
            pa = [nx * x + nz * z for x, z in p]
            pb = [nx * x + nz * z for x, z in q]
            if max(pa) < min(pb) or max(pb) < min(pa):
                return False
    return True


TAKEN = [rect(*u, grow=12) for u in USED]


def deck_dist(x, z):
    best = 1e9
    for s in DECKS:
        for q in s[::2]:
            best = min(best, math.hypot(q[0] - x, q[2] - z))
    return best


def chain(s):
    c = [0.0]
    for k in range(1, len(s)):
        c.append(c[-1] + math.hypot(s[k][0] - s[k - 1][0], s[k][2] - s[k - 1][2]))
    return c


def lot_ok(cx, cz, fx, fz, w, d, others):
    ax, az = -fz, fx
    for u in range(-4, 5):
        for v in range(-4, 5):
            x = cx + ax * u * (w / 8) - fx * v * ((d - 4) / 8)
            z = cz + az * u * (w / 8) - fz * v * ((d - 4) / 8)
            if not (X0 < x < X1 and Z0 < z < Z1) or math.hypot(x - RING[0], z - RING[1]) < RING[2]:
                return False
            if not road_clear(x, z) or near_water(x, z, 8):
                return False
    for p in landmarks:
        if math.hypot(p['x'] - cx, p['z'] - cz) < max(w, d) / 2 + max(p['w'], p['d']) / 2 + 10:
            return False
    me = rect(cx, cz, fx, fz, w + 16, d + 10)
    return all(not overlap(me, t) for t in TAKEN) and all(not overlap(me, o) for o in others)


# ---------------------------------------------------------------- the Racing Hub: a 216 lot near Optima Werkz
def find_hub():
    best = None
    for name in ('Yangon Loop', 'New Road', 'University Avenue'):
        s = R[name]['s']
        c = chain(s)
        cs = CUT.get(name, set())
        k = 0
        for i in range(len(s)):
            if c[i] < 200 or c[i] > c[-1] - 200 or i in cs or i % 3:
                continue
            x, y, z, tx, tz = s[i][0], s[i][1], s[i][2], s[i][3], s[i][4]
            L = math.hypot(tx, tz)
            tx, tz = tx / L, tz / L
            for side in (1, -1):
                nx, nz = -tz * side, tx * side
                hs = s[i][6] if side < 0 else s[i][7]
                off = hs + WALK + 3 + 108
                cx, cz = x + nx * off, z + nz * off
                dd = math.hypot(cx - OPTIMA['x'], cz - OPTIMA['z'])
                if best and dd >= best[0]:
                    continue
                if lot_ok(cx, cz, -nx, -nz, 216, 216, []):
                    best = (dd, name, i, round(cx, 1), round(cz, 1), round(-nx, 3), round(-nz, 3), y)
    return best


# ---------------------------------------------------------------- house lots along the streets
TIERS = {0: ('low', 60, 72), 1: ('mid', 104, 100), 2: ('high', 120, 130)}
LEAFY = {'Inya Road', 'Inya Road West', 'Inya Road East', 'Inya Myaing Street', 'Kan Road', 'University Avenue'}
WANT = {2: 10, 1: 13, 0: 22}


def find_lots(hub):
    others = [rect(*hub, grow=0)] if hub else []
    lots = []
    order = []
    for r in roads:
        if r.get('kind') != 'street':
            continue
        order.append(r)
    # the leafy streets first for the big lots
    order.sort(key=lambda r: (0 if r['name'] in LEAFY else 1, r['name']))
    for tier in (2, 1, 0):
        zone, w, d = TIERS[tier]
        for r in order:
            if sum(1 for l in lots if l['tier'] == tier) >= WANT[tier]:
                break
            if tier == 2 and r['name'] not in LEAFY:
                continue
            s = r['s']
            c = chain(s)
            cs = CUT.get(r['name'], set())
            walk = WALK
            i = 0
            while i < len(s) and sum(1 for l in lots if l['tier'] == tier) < WANT[tier]:
                if c[i] < 70 or c[i] > c[-1] - 70 or i in cs:
                    i += 1
                    continue
                x, y, z, tx, tz = s[i][0], s[i][1], s[i][2], s[i][3], s[i][4]
                L = math.hypot(tx, tz)
                tx, tz = tx / L, tz / L
                placed = False
                for side in (1, -1):
                    nx, nz = -tz * side, tx * side
                    hs = s[i][6] if side < 0 else s[i][7]
                    off = hs + walk + 3 + d / 2
                    cx, cz = x + nx * off, z + nz * off
                    if lot_ok(cx, cz, -nx, -nz, w, d, [l['pad'] for l in lots]):
                        lots.append({'tier': tier, 'zone': zone, 'w': w, 'd': d, 'x': cx, 'z': cz, 'fx': -nx, 'fz': -nz, 'road': r['name'],
                                     'front': (x + nx * (hs + walk / 2), z + nz * (hs + walk / 2)), 'ry': y,
                                     'pad': rect(cx, cz, -nx, -nz, w + 16, d + 10)})
                        placed = True
                        break
                # the next try a lot's width further on
                step = w + 18 if placed else 8
                d0 = c[i]
                while i < len(s) and c[i] < d0 + step:
                    i += 1
    return lots


# ---------------------------------------------------------------- races, from the traffic lanes
def lanes():
    out = {}
    srcl = open(os.path.join(ROOT, 'src', 'shared', 'YangonLanes.lua'), encoding='utf-8').read()
    for m in re.finditer(r'\{ road = "([^"]+)", way = (-?\d+), lane = (\d+), kind = "(\w+)".*?pts = \{ ([^}]*) \}', srcl):
        v = list(map(float, m.group(5).split(',')))
        out[(m.group(1), int(m.group(2)), int(m.group(3)))] = [v[i:i + 3] for i in range(0, len(v), 3)]
    return out


def resample(pts, a, b):
    """the polyline from flat distance a to b, as points every 4 studs (with y)"""
    c = [0.0]
    for k in range(1, len(pts)):
        c.append(c[-1] + math.hypot(pts[k][0] - pts[k - 1][0], pts[k][2] - pts[k - 1][2]))
    out = []
    t = a
    j = 0
    b = min(b, c[-1])
    while t <= b:
        while j < len(c) - 2 and c[j + 1] < t:
            j += 1
        f = (t - c[j]) / max(c[j + 1] - c[j], 1e-6)
        p, q = pts[j], pts[j + 1]
        out.append([p[i] + (q[i] - p[i]) * f for i in range(3)])
        t += 4
    return out, c[-1]


def race(rid, name, path):
    """path: points every 4 studs; start = first, checkpoints every 180, finish = last"""
    L = 0.0
    cps = []
    acc = 0.0
    for k in range(1, len(path)):
        st = math.hypot(path[k][0] - path[k - 1][0], path[k][2] - path[k - 1][2])
        L += st
        acc += st
        if acc >= 180 or k == len(path) - 1:
            cps.append(path[k])
            acc = 0.0
    s0, s1 = path[0], path[3]
    dx, dz = s1[0] - s0[0], s1[2] - s0[2]
    n = math.hypot(dx, dz)
    return {'id': rid, 'name': name, 'start': s0, 'dir': (dx / n, dz / n), 'length': round(L), 'checkpoints': cps}


def make_races():
    ln = lanes()
    out = []
    ring = lambda p: math.hypot(p[0] - RING[0], p[2] - RING[1])
    # 1. Optima Run: loop A from the roundabout past Optima Werkz to before the Kabar Aye split
    a = ln[('Yangon Loop A', 1, 1)]
    full, L = resample(a, 0, 1e9)
    i0 = next(i for i, p in enumerate(full) if ring(p) > 175)
    i1 = max(i for i, p in enumerate(full) if deck_dist(p[0], p[2]) > 110)
    out.append(race('ygn_optima', 'Optima Run', full[i0:i1 + 1]))
    # 2. New Road Flyover: New Road from past its first junction, over the Kabar Aye deck, onto loop B
    nr, _ = resample(ln[('New Road', 1, 1)], 0, 1e9)
    lb, _ = resample(ln[('Yangon Loop B', 1, 1)], 0, 1e9)
    path = nr[20:] + lb[1:]
    j = next(k for k in range(len(nr) - 20, len(path)) if deck_dist(path[k][0], path[k][2]) > 110 and k > len(nr) - 20 + 40)
    out.append(race('ygn_newroad', 'New Road Flyover', path[:j + 1]))
    # 3. University Avenue: the whole avenue, clear of the Pyay deck at its start
    ua, _ = resample(ln[('University Avenue', 1, 1)], 0, 1e9)
    k0 = next(i for i, p in enumerate(ua) if deck_dist(p[0], p[2]) > 120 and i > 15)
    out.append(race('ygn_university', 'University Avenue', ua[k0:len(ua) - 8]))
    # 4. Pyay Road Flyover: the last ~5,200 studs of loop B, over the Pyay deck, to the roundabout
    end = max(i for i, p in enumerate(lb) if ring(p) > 175 and i < len(lb) - 5)
    st = max(0, end - 1300)
    while deck_dist(lb[st][0], lb[st][2]) < 80:
        st += 1
    out.append(race('ygn_pyay', 'Pyay Road Flyover', lb[st:end + 1]))
    return out


# ---------------------------------------------------------------- pavement points: dispatch, drops, chips
def pavement_points(step=24):
    pts = []
    for r in roads:
        if r.get('kind') == 'side':
            continue
        s = r['s']
        c = chain(s)
        cs = CUT.get(r['name'], set())
        for i in range(0, len(s), max(1, int(step / 6.4))):
            if c[i] < 90 or c[i] > c[-1] - 90 or i in cs or (i + 1) in cs or (i - 1) in cs:
                continue
            x, y, z, tx, tz = s[i][0], s[i][1], s[i][2], s[i][3], s[i][4]
            L = math.hypot(tx, tz)
            tx, tz = tx / L, tz / L
            for side in (1, -1):
                nx, nz = -tz * side, tx * side
                hs = s[i][6] if side < 0 else s[i][7]
                walk = (r.get('walkL') if side < 0 else r.get('walkR')) or WALK
                px, pz = x + nx * (hs + walk / 2), z + nz * (hs + walk / 2)
                if deck_dist(px, pz) < 60 or math.hypot(px - RING[0], pz - RING[1]) < 160:
                    continue
                if any(in_poly(px, pz, t) for t in TAKEN):
                    continue
                if any(math.hypot(px - p['x'], pz - p['z']) < max(p['w'], p['d']) / 2 + 30 for p in landmarks):
                    continue
                pts.append({'x': px, 'z': pz, 'ry': y, 'road': r['name'], 'kind': r.get('kind'), 'nx': nx, 'nz': nz})
    return pts


def crosses_water(a, b):
    for k in range(1, 40):
        x = a[0] + (b[0] - a[0]) * k / 40
        z = a[1] + (b[1] - a[1]) * k / 40
        if any(in_poly(x, z, w) for w in water):
            return True
    return False


DROP_NAMES = ['Inya Lake Tea Shop', 'Hledan Market Stall', 'Kamayut Flats', 'University Bookshop', 'Pyay Road Bakery',
              'Golden Valley Villa', 'Shwe Taung Gyar Flats', 'Kabar Aye Office', 'Parami Noodle House', 'New Road Garage',
              'Lakeside Apartments', 'Mayangone Pharmacy', 'Thingangyun Florist', 'Bahan Print Shop']


# ---------------------------------------------------------------- the two passes
def probe():
    os.makedirs(OUT, exist_ok=True)
    hub = find_hub()
    print('hub lot:', hub)
    hubrect = (hub[3], hub[4], hub[5], hub[6], 216, 216) if hub else None
    lots = find_lots(hubrect)
    print('lots:', {t: sum(1 for l in lots if l['tier'] == t) for t in (0, 1, 2)})
    races = make_races()
    for r in races:
        print('race %-14s %5d studs, %2d checkpoints, start %s' % (r['id'], r['length'], len(r['checkpoints']), [round(v) for v in r['start']]))
    pave = pavement_points()
    print('pavement points:', len(pave))
    P = []  # (key, x, z, yHint, kind)
    for k, l in enumerate(lots):
        P.append(('lot%d' % k, l['front'][0], l['front'][1], l['ry'], 'pave'))
    for r in races:
        P.append(('%s:s' % r['id'], r['start'][0], r['start'][2], r['start'][1], 'road'))
        for j, q in enumerate(r['checkpoints']):
            P.append(('%s:%d' % (r['id'], j), q[0], q[2], q[1], 'road'))
    for k, p in enumerate(pave):
        P.append(('pv%d' % k, p['x'], p['z'], p['ry'], 'pave'))
    if hub:
        P.append(('hub', hub[3], hub[4], hub[7], 'any'))
    json.dump({'hub': hub, 'lots': [{k: v for k, v in l.items() if k != 'pad'} for l in lots], 'races': races, 'pave': pave, 'P': P},
              open(os.path.join(OUT, 'probe.json'), 'w'))
    # the Studio side: one line per point, "key y name" (nil hit = "-")
    lines = ['local P = {']
    for key, x, z, y, kind in P:
        lines.append('{"%s",%.2f,%.2f,%.2f},' % (key, x, z, y))
    lines.append('}')
    lines.append('''local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances = { workspace.Yangon.Roads, workspace.Yangon:FindFirstChild("Decks") }
local out = {}
for _, p in P do
	local h = workspace:Raycast(Vector3.new(p[2], p[4] + 16, p[3]), Vector3.new(0, -40, 0), rp)
	table.insert(out, p[1] .. " " .. (if h then string.format("%.2f %s", h.Position.Y, h.Instance.Name) else "- -"))
end
return table.concat(out, "\\n")''')
    open(os.path.join(OUT, 'probe.luau'), 'w', newline='\n').write('\n'.join(lines))
    print('probe points:', len(P), '->', os.path.join(OUT, 'probe.luau'), os.path.getsize(os.path.join(OUT, 'probe.luau')), 'bytes')


def v3(p):
    return 'Vector3.new(%.1f, %.2f, %.1f)' % (p[0], p[1], p[2])


def build():
    J = json.load(open(os.path.join(OUT, 'probe.json')))
    M = {}
    for line in open(os.path.join(OUT, 'probe_out.txt'), encoding='utf-8'):
        a = line.split()
        if len(a) >= 3 and a[1] != '-':
            M[a[0]] = (float(a[1]), a[2])
    hub = J['hub']
    # lots: the pavement top in front (Pavement hits only)
    lots = []
    for k, l in enumerate(J['lots']):
        h = M.get('lot%d' % k)
        if not h or h[1] != 'Pavement':
            print('lot dropped (no pavement in front):', l['road'], round(l['x']), round(l['z']), h)
            continue
        l['y'] = h[0]
        lots.append(l)
    num = {0: 0, 1: 0, 2: 0}
    rows = []
    for l in sorted(lots, key=lambda l: (-l['tier'], l['x'])):
        num[l['tier']] += 1
        l['id'] = 'ygn_%s_%d' % (l['zone'], num[l['tier']])
        l['number'] = num[l['tier']]
        rows.append('\t\t{ id = "%s", zone = "%s", tier = %d, number = %d, x = %.1f, y = %.2f, z = %.1f, fx = %.3f, fz = %.3f, w = %d, d = %d },' % (
            l['id'], l['zone'], l['tier'], l['number'], l['x'], l['y'], l['z'], l['fx'], l['fz'], l['w'], l['d']))
    # races: road heights from Studio
    rrows = []
    for r in J['races']:
        hs = M.get('%s:s' % r['id'])
        assert hs and hs[1] in ('Road', 'DeckSurface', 'Deck', 'Surface'), ('start not on a road', r['id'], hs)
        start = [r['start'][0], hs[0], r['start'][2]]
        cps = []
        for j, q in enumerate(r['checkpoints']):
            h = M.get('%s:%d' % (r['id'], j))
            cps.append([q[0], h[0] if h else q[1], q[2]])
        rrows.append('\t\t{ id = "%s", name = "%s", start = %s, dir = Vector3.new(%.3f, 0, %.3f), length = %d, checkpoints = { %s } },' % (
            r['id'], r['name'], v3(start), r['dir'][0], r['dir'][1], r['length'], ', '.join(v3(c) for c in cps)))
    # pavement points that really are pavement
    pave = []
    for k, p in enumerate(J['pave']):
        h = M.get('pv%d' % k)
        if h and h[1] == 'Pavement':
            p['y'] = h[0]
            pave.append(p)
    print('pavement points on pavement:', len(pave), 'of', len(J['pave']))
    # lots' pads and their fronts must not take a pavement point (a ring on a ramp)
    def by_lot(p):
        for l in lots:
            if math.hypot(p['x'] - l['front'][0], p['z'] - l['front'][1]) < l['w'] / 2 + 20:
                return True
        return False
    pave = [p for p in pave if not by_lot(p)]
    # dispatch: one on the street nearest Optima Werkz, one on the far (east) side by Myanmar Plaza
    mm = [p for p in landmarks if p['landmark'] == 'mmplaza'][0]
    def nearest(x, z, pool):
        return min(pool, key=lambda p: math.hypot(p['x'] - x, p['z'] - z))
    d1 = nearest(OPTIMA['x'] + 60, OPTIMA['z'] + 260, [p for p in pave if p['kind'] == 'street'])
    d2 = nearest(mm['x'], mm['z'] + 300, [p for p in pave if p['kind'] == 'street'])
    dispatch = [('Optima Dispatch', d1), ('Myanmar Plaza Dispatch', d2)]
    # drops: spread out, each >= 900 from both dispatches with no lake between
    drops = []
    pool = [p for p in pave if all(math.hypot(p['x'] - d['x'], p['z'] - d['z']) >= 900 and not crosses_water((p['x'], p['z']), (d['x'], d['z'])) for _, d in dispatch)]
    rng.shuffle(pool)
    for p in pool:
        if all(math.hypot(p['x'] - q['x'], p['z'] - q['z']) > 450 for q in drops):
            drops.append(p)
        if len(drops) >= 12:
            break
    print('drops:', len(drops))
    # chips: 25 spread over every road, >= 300 apart, not at a dispatch or drop
    chips = []
    pool = list(pave)
    rng.shuffle(pool)
    for p in pool:
        if all(math.hypot(p['x'] - q['x'], p['z'] - q['z']) > 300 for q in chips + drops + [d for _, d in dispatch]):
            chips.append(p)
        if len(chips) >= 25:
            break
    print('chips:', len(chips))
    lua = ['-- generated by tools/yangon/d15_world.py: do not edit',
           '-- the Yangon map\'s house lots, races, delivery jobs and Legends chips (RivieraWorld\'s format; ActivityData and',
           '-- IsleLayout load it when Config.activeMap() is "Yangon")',
           'return {', '\tlots = {'] + rows + ['\t},', '\traces = {'] + rrows + ['\t},', '\tdispatch = {']
    for n, d in dispatch:
        lua.append('\t\t{ name = "%s", pos = Vector3.new(%.1f, %.2f, %.1f) },' % (n, d['x'], d['y'] + 0.5, d['z']))
    lua.append('\t},')
    lua.append('\tdropPoints = {')
    for k, p in enumerate(drops):
        lua.append('\t\t{ name = "%s", pos = Vector3.new(%.1f, %.2f, %.1f) },' % (DROP_NAMES[k], p['x'], p['y'] + 0.5, p['z']))
    lua.append('\t},')
    lua.append('\tchips = { %s },' % ', '.join('Vector3.new(%.1f, %.2f, %.1f)' % (p['x'], p['y'] + 0.5 + 2.6, p['z']) for p in chips))
    hy = M.get('hub', (hub[7] + 0.5, '?'))[0] if hub else 0
    if hub:
        cx, cz, fx, fz = hub[3], hub[4], hub[5], hub[6]
        ax, az = -fz, fx
        bays = []
        for k, r in enumerate(J['races']):
            u = (k - (len(J['races']) - 1) / 2) * 44
            bays.append('\t\t%s = Vector3.new(%.1f, %.2f, %.1f),' % (r['id'], cx + ax * u - fx * 10, hy, cz + az * u - fz * 10))
        sx, sz = cx + fx * 80, cz + fz * 80
        lua.append('\t-- the Racing Hub: a 216 lot near Optima Werkz (pad: YangonSites.prepare "racing_hub"); a ring per race')
        lua.append('\thub = {')
        lua.append('\t\tsite = { x = %.1f, z = %.1f, fx = %.3f, fz = %.3f, y = %.2f },' % (cx, cz, fx, fz, hy))
        lua.append('\t\tspot = CFrame.lookAt(Vector3.new(%.1f, %.2f, %.1f), Vector3.new(%.1f, %.2f, %.1f)),' % (sx, hy + 2.6, sz, cx, hy + 2.6, cz))
        lua.append('\t\tbays = {')
        lua += ['\t' + b for b in bays]
        lua.append('\t\t},')
        lua.append('\t},')
    lua.append('}')
    path = os.path.join(ROOT, 'src', 'shared', 'YangonWorld.lua')
    open(path, 'w', encoding='utf-8', newline='\n').write('\n'.join(lua) + '\n')
    print('wrote', path, os.path.getsize(path), 'bytes')
    # the pads for YangonSites.prepare: lot_<id> = { x, z, fx, fz, y, size = d, w }
    pads = {('lot_' + l['id']): {'x': round(l['x'], 1), 'z': round(l['z'], 1), 'fx': round(l['fx'], 3), 'fz': round(l['fz'], 3), 'y': l['y'], 'size': l['d'], 'w': l['w']} for l in lots}
    if hub:
        pads['racing_hub'] = {'x': hub[3], 'z': hub[4], 'fx': hub[5], 'fz': hub[6], 'y': hy}
    json.dump(pads, open(os.path.join(OUT, 'pads.json'), 'w'), indent=0)
    print('pads:', len(pads))
    try:
        preview(lots, J['races'], dispatch, drops, chips, hub)
    except Exception as e:
        print('no preview:', e)


def preview(lots, races, dispatch, drops, chips, hub):
    from PIL import Image, ImageDraw
    S = 0.18
    W, H = int((X1 - X0) * S) + 20, int((Z1 - Z0) * S) + 20
    im = Image.new('RGB', (W, H), (30, 40, 36))
    d = ImageDraw.Draw(im)
    P = lambda x, z: ((x - X0) * S + 10, (z - Z0) * S + 10)
    for w in water:
        d.polygon([P(x, z) for x, z in w], fill=(20, 50, 90))
    for r in roads:
        d.line([P(q[0], q[2]) for q in r['s']], fill=(120, 120, 130), width=2)
    for u in USED:
        d.polygon([P(x, z) for x, z in rect(*u)], outline=(240, 200, 80))
    if hub:
        d.polygon([P(x, z) for x, z in rect(hub[3], hub[4], hub[5], hub[6], 216, 216)], outline=(255, 60, 60), width=2)
    cols = {0: (120, 220, 120), 1: (80, 200, 255), 2: (255, 120, 255)}
    for l in lots:
        d.polygon([P(x, z) for x, z in rect(l['x'], l['z'], l['fx'], l['fz'], l['w'], l['d'])], outline=cols[l['tier']], width=2)
    for r in races:
        d.line([P(r['start'][0], r['start'][2])] + [P(c[0], c[2]) for c in r['checkpoints']], fill=(255, 80, 80), width=2)
    for _, p in dispatch:
        d.ellipse([P(p['x'], p['z'])[0] - 5, P(p['x'], p['z'])[1] - 5, P(p['x'], p['z'])[0] + 5, P(p['x'], p['z'])[1] + 5], fill=(60, 120, 255))
    for p in drops:
        x, y = P(p['x'], p['z'])
        d.rectangle([x - 3, y - 3, x + 3, y + 3], fill=(255, 255, 255))
    for p in chips:
        x, y = P(p['x'], p['z'])
        d.ellipse([x - 3, y - 3, x + 3, y + 3], fill=(255, 210, 0))
    im.save(os.path.join(OUT, 'preview.png'))


if __name__ == '__main__':
    {'probe': probe, 'build': build}[sys.argv[1]]()
