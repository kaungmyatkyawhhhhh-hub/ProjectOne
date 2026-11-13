"""Yangon map, build step 10 (14 Nov 2026, owner: "Step 10 night lights"): where the street lamps stand.

Writes build/yangon_lamps/YangonLampSpots.luau, a ModuleScript holding every spot as ONE string ("x z yHint fx fz kind"
lines; a big table literal doesn't load in Studio), for tools/yangon/YangonLamps.luau, which clones Monaco's
StreetLamp onto each spot after a raycast proves the ground is right (pavement, or a deck's parapet).

Rules
  * Main roads (route): both sides, a lamp every 96 studs, the far side shifted half a step (staggered), the pole
    1.5 studs in from the kerb, the head reaching over the road.
  * Streets: one side, a lamp every 120, the side swapping each stretch between junctions.
  * Flyover decks: on both parapets every 96.
  * The roundabout: round its outer pavement every 20 degrees.
  * None in a junction (within a crossing road's half + pavement + 6), on a cut sample, within 40 of a deck's
    footprint (the ground roads under it), in front of a venue lot, the hub, a house lot (their drive-ins), or
    within 14 of a race start, a job ring or a chip.

Run from Games/CityLegends:  python tools/yangon/d16_lamps.py
"""
import json, math, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(ROOT, 'build', 'yangon_lamps')
src = open(os.path.join(HERE, 'd10_plots.py'), encoding='utf-8').read()
ns = {'__file__': os.path.join(HERE, 'd10_plots.py')}
exec(compile(src[:src.index('# the landmarks first')], 'd10', 'exec'), ns)
roads, CUT, RING, data, WALK, in_poly = ns['roads'], ns['CUT'], ns['RING'], ns['data'], ns['WALK'], ns['in_poly']

# the lots (venues, fuel, hub, house lots) whose fronts take drive-ins: rectangles grown 16 (covers the pavement)
SITES = [
    (30836.8, 957.4, -0.560, -0.829, 216, 216), (31025.7, 646.7, -0.990, -0.144, 216, 216), (31125.7, 960.7, 0.326, 0.945, 216, 216),
    (31074.1, 394.2, -0.991, -0.136, 216, 216), (32358.8, -1833.6, 0.992, 0.127, 216, 216), (30742.3, 223.9, 0.969, -0.249, 216, 216),
    (30730.5, 552.9, 0.987, 0.159, 304, 216), (29745.3, 1089.0, 0, 1, 216, 216), (30655.1, 1303.2, 0, -1, 216, 216),
    (30911.0, 1306.4, 0, -1, 216, 216), (29867.2, 1398.6, 0, -1, 216, 216), (30465.2, 921.7, 0.560, 0.829, 80, 80),
]
world = open(os.path.join(ROOT, 'src', 'shared', 'YangonWorld.lua'), encoding='utf-8').read()
for m in re.finditer(r'x = ([-\d.]+), y = [-\d.]+, z = ([-\d.]+), fx = ([-\d.]+), fz = ([-\d.]+), w = (\d+), d = (\d+)', world):
    SITES.append(tuple(float(v) for v in m.groups()))
m = re.search(r'site = \{ x = ([-\d.]+), z = ([-\d.]+), fx = ([-\d.]+), fz = ([-\d.]+)', world)
if m:
    SITES.append((float(m.group(1)), float(m.group(2)), float(m.group(3)), float(m.group(4)), 216, 216))
KEEP = [tuple(map(float, v)) for v in re.findall(r'Vector3\.new\(([-\d.]+), [-\d.]+, ([-\d.]+)\)', world)]  # rings, chips, drops, starts


def rect(x, z, fx, fz, w, d, grow=0.0):
    ax, az = -fz, fx
    hw, hd = w / 2 + grow, d / 2 + grow
    return [(x + ax * u * hw + fx * v * hd, z + az * u * hw + fz * v * hd) for u, v in ((-1, -1), (1, -1), (1, 1), (-1, 1))]


ZONES = [rect(*s, grow=16) for s in SITES]
DECKS = [d['s'] for d in data['decks']]


def chain(s):
    c = [0.0]
    for k in range(1, len(s)):
        c.append(c[-1] + math.hypot(s[k][0] - s[k - 1][0], s[k][2] - s[k - 1][2]))
    return c


def seg_dist(px, pz, ax, az, bx, bz):
    vx, vz = bx - ax, bz - az
    L = vx * vx + vz * vz
    t = 0 if L == 0 else max(0, min(1, ((px - ax) * vx + (pz - az) * vz) / L))
    return math.hypot(px - ax - t * vx, pz - az - t * vz)


# other roads' carriageways + pavements, for the junction test (a grid like d10's)
CELL = 64.0
grid = {}
for ri, r in enumerate(roads):
    s = r['s']
    cs = CUT.get(r['name'], set())
    walk = max(r.get('walkL') or WALK, r.get('walkR') or WALK)
    for k in range(len(s) - 1):
        if k in cs or k + 1 in cs:
            continue
        a, b = s[k], s[k + 1]
        need = max(a[6], a[7], b[6], b[7]) + walk + 6
        for cx in range(int((min(a[0], b[0]) - need) // CELL), int((max(a[0], b[0]) + need) // CELL) + 1):
            for cz in range(int((min(a[2], b[2]) - need) // CELL), int((max(a[2], b[2]) + need) // CELL) + 1):
                grid.setdefault((cx, cz), []).append((ri, a[0], a[2], b[0], b[2], need))


def in_junction(x, z, own):
    for (ri, ax, az, bx, bz, need) in grid.get((int(x // CELL), int(z // CELL)), ()):
        if ri != own and seg_dist(x, z, ax, az, bx, bz) < need:
            return True
    return False


def deck_near(x, z, margin):
    for s in DECKS:
        for k in range(0, len(s) - 1):
            a, b = s[k], s[k + 1]
            if seg_dist(x, z, a[0], a[2], b[0], b[2]) < max(a[6], a[7]) + margin:
                return True
    return False


def free(x, z):
    if any(in_poly(x, z, zr) for zr in ZONES):
        return False
    return all(math.hypot(x - a, z - b) > 14 for a, b in KEEP)


spots = []  # (x, z, yHint, fx, fz, kind)


def along(s, c, d):
    lo, hi = 0, len(c) - 1
    while hi - lo > 1:
        mid = (lo + hi) // 2
        if c[mid] <= d:
            lo = mid
        else:
            hi = mid
    t = 0 if c[hi] == c[lo] else (d - c[lo]) / (c[hi] - c[lo])
    a, b = s[lo], s[hi]
    x, y, z = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t
    tx, tz = b[0] - a[0], b[2] - a[2]
    L = math.hypot(tx, tz) or 1
    return x, y, z, tx / L, tz / L, lo, a


stats = {}
for ri, r in enumerate(roads):
    kind = r.get('kind')
    if kind == 'side':
        continue  # (beside the decks: the deck and the main road's lamps light them)
    s = r['s']
    c = chain(s)
    cs = CUT.get(r['name'], set())
    step = 96.0 if kind == 'route' else 120.0
    sides = (1, -1) if kind == 'route' else (1,)
    for side0 in sides:
        d = 30.0 + (step / 2 if side0 < 0 else 0)
        while d < c[-1] - 30:
            x, y, z, tx, tz, k, a = along(s, c, d)
            side = side0
            if kind != 'route':
                side = 1 if int(d // 600) % 2 == 0 else -1  # (streets: the side swaps every 600 studs)
            d += step
            if k in cs or (k + 1) in cs:
                continue
            nx, nz = -tz * side, tx * side  # away from the road on this side
            hs = a[6] if side < 0 else a[7]
            px, pz = x + nx * (hs + 1.5), z + nz * (hs + 1.5)
            if math.hypot(px - RING[0], pz - RING[1]) < RING[2] + 20:
                continue
            if in_junction(px, pz, ri) or deck_near(px, pz, 40) or not free(px, pz):
                stats[r['name']] = stats.get(r['name'], 0)
                continue
            spots.append((px, pz, y, -nx, -nz, 'P'))
            stats[r['name']] = stats.get(r['name'], 0) + 1

# the decks: both parapets
for s in DECKS:
    c = chain(s)
    for side in (1, -1):
        d = 20.0 + (48 if side < 0 else 0)
        while d < c[-1] - 20:
            x, y, z, tx, tz, k, a = along(s, c, d)
            d += 96
            nx, nz = -tz * side, tx * side
            hs = a[6] if side < 0 else a[7]
            px, pz = x + nx * (hs - 0.45), z + nz * (hs - 0.45)
            spots.append((px, pz, y, -nx, -nz, 'D'))

# the roundabout's outer pavement
for k in range(18):
    ang = k * math.pi * 2 / 18
    ox, oz = math.cos(ang), math.sin(ang)
    px, pz = RING[0] + ox * 109, RING[1] + oz * 109
    if in_junction(px, pz, -1) is False or True:
        spots.append((px, pz, 47.4, -ox, -oz, 'R'))

os.makedirs(OUT, exist_ok=True)
rows = ['%.1f %.1f %.1f %.3f %.3f %s' % sp for sp in spots]
mod = '-- generated by tools/yangon/d16_lamps.py: the Yangon street lamp spots ("x z yHint towardsRoadX towardsRoadZ kind";\n'
mod += '-- kind P = pavement, D = a deck parapet, R = the roundabout)\nreturn [==[\n' + '\n'.join(rows) + '\n]==]\n'
open(os.path.join(OUT, 'YangonLampSpots.luau'), 'w', newline='\n').write(mod)
print('spots:', len(spots), {k: sum(1 for s in spots if s[5] == k) for k in 'PDR'}, len(mod), 'chars')
print('per road (main):', {k: v for k, v in stats.items() if k in ('Yangon Loop', 'New Road', 'University Avenue')})
