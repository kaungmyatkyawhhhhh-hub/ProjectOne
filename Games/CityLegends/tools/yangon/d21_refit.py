"""Yangon batch 0.5 accuracy pass (14 Nov 2026): refit YangonWorld to the widened roads (v4, d18_widen.py).

Inya Road (and the other roads widened to 2+2) is 16 studs wider each side, so:
  * a house lot whose front now reaches into the road's carriageway or pavement moves straight back from its road until its
    front is 3 studs behind the pavement again (YangonWorld.lots + build/yangon_world/pads.json are rewritten);
  * a job ring, drop point or chip now on a carriageway moves out onto the middle of the new pavement.
Then re-run d19_buildings.py, d20_green.py and d16_lamps.py (they keep clear of the lots), and in Studio re-prepare the moved
lots (YangonSites.prepare with the new pads.json entries) and rebuild buildings, green and lamps.

Run from Games/CityLegends:  python tools/yangon/d21_refit.py
"""
import json, math, os, re

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
MAP = os.path.join(ROOT, 'imports', 'refs', 'map')
WORLD = os.path.join(ROOT, 'src', 'shared', 'YangonWorld.lua')
PADS = os.path.join(ROOT, 'build', 'yangon_world', 'pads.json')
WALK, SETBACK = 10.0, 3.0

d = json.load(open(os.path.join(MAP, 'ygn_roads_v5.json'), encoding='utf-8'))
CUT = {k: set(v) for k, v in d['cut'].items()}


def nearest(x, z):
    """(distance past the carriageway edge, road name, nearest centre point, half, walk)"""
    best = (1e9, None, None, None, None)
    for r in d['roads']:
        s = r['s']
        cs = CUT.get(r['name'], set())
        walk = r.get('walkL') or WALK
        for k in range(len(s) - 1):
            if k in cs or k + 1 in cs:
                continue
            a, b = s[k], s[k + 1]
            vx, vz = b[0] - a[0], b[2] - a[2]
            L = vx * vx + vz * vz
            t = 0 if L == 0 else max(0, min(1, ((x - a[0]) * vx + (z - a[2]) * vz) / L))
            qx, qz = a[0] + t * vx, a[2] + t * vz
            half = max(a[6], a[7])
            e = math.hypot(x - qx, z - qz) - half
            if e < best[0]:
                best = (e, r['name'], (qx, qz), half, walk)
    return best


w = open(WORLD, encoding='utf-8').read()
pads = json.load(open(PADS))
moved_lots = []


def fix_lot(m):
    lid = m.group(1)
    x, z, fx, fz, W, D = (float(v) for v in m.group(2, 4, 5, 6, 7, 8))
    ax, az = -fz, fx
    # the deepest any point of the lot's front half reaches past (walk + setback) from a carriageway edge
    need = 0.0
    for u in (-0.5, -0.25, 0, 0.25, 0.5):
        for v in (-0.5, -0.25, 0):
            px, pz = x + ax * u * W + fx * (-v) * D, z + az * u * W + fz * (-v) * D
            e, name, q, half, walk = nearest(px, pz)
            need = max(need, (walk + SETBACK) - e)
    if need <= 0.05:
        return m.group(0)
    step = need + 0.2
    nx, nz = x - fx * step, z - fz * step  # (fx, fz) points towards the road: move away from it
    moved_lots.append((lid, round(step, 1)))
    pk = 'lot_' + lid
    if pk in pads:
        pads[pk]['x'] = round(nx, 1)
        pads[pk]['z'] = round(nz, 1)
    s = m.group(0)
    s = s.replace('x = %s,' % m.group(2), 'x = %.1f,' % nx, 1).replace('z = %s,' % m.group(4), 'z = %.1f,' % nz, 1)
    return s


w = re.sub(r'\{ id = "([^"]+)", zone = "[^"]+", tier = \d+, number = \d+, x = ([-\d.]+), y = ([-\d.]+), z = ([-\d.]+), fx = ([-\d.]+), fz = ([-\d.]+), w = (\d+), d = (\d+) \},', fix_lot, w)

# rings and chips on a carriageway: out onto the new pavement's middle
moved_pts = []


def fix_point(m):
    x, y, z = float(m.group(1)), float(m.group(2)), float(m.group(3))
    e, name, q, half, walk = nearest(x, z)
    if e >= 1.0:
        return m.group(0)
    ux, uz = x - q[0], z - q[1]
    L = math.hypot(ux, uz) or 1
    off = half + walk / 2
    nx, nz = q[0] + ux / L * off, q[1] + uz / L * off
    moved_pts.append((name, round(off - (math.hypot(x - q[0], z - q[1])), 1)))
    return 'Vector3.new(%.1f, %s, %.1f)' % (nx, m.group(2), nz)


head, rest = w.split('\tdispatch = {', 1)
mid, tail = rest.split('\thub = {', 1)
mid = re.sub(r'Vector3\.new\(([-\d.]+), ([-\d.]+), ([-\d.]+)\)', fix_point, mid)
w = head + '\tdispatch = {' + mid + '\thub = {' + tail
open(WORLD, 'w', encoding='utf-8', newline='\n').write(w)
json.dump(pads, open(PADS, 'w'), indent=0)
print('lots moved back:', len(moved_lots), moved_lots)
print('rings / chips moved onto the pavement:', len(moved_pts), moved_pts)
