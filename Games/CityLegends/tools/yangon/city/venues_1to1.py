"""Venue lots on the 1:1 map (17 Nov 2026, the switch-over from the old Yangon map).

The game's venues stand on a lot (216 square; Rewards 304 wide; realty 80) beside a main road, facing it, its front
edge on the road's pavement. This walks the roads05 main roads (kind route / side) of the given districts and scores
every lot spot: it must touch no carriageway or pavement (+2), no landmark, fuel station or the Inya Lake Hotel / YCC
compound (the GGFest build); the score is the shell area it would take away (smaller is better: real car parks,
pitches and open ground score 0). Water, heights and landmarks are checked again in Studio (VenueLots.luau).

    YANGON_SCALE=1to1 python venues_1to1.py <roads05 tags> <district> [<district> ...] [--axis] [--w 216 --d 216]
-> prints the best spots (x z fx fz score), well apart.
"""
import json, math, os, sys

from shapely.geometry import Polygon, Point
from shapely.ops import unary_union
from shapely.strtree import STRtree

sys.stdout.reconfigure(encoding='utf-8')
import geo
from roads05_clear import road_polys, shells

assert geo.ONE_TO_ONE, "run with YANGON_SCALE=1to1"

args = sys.argv[1:]
tag, districts = args[0], [a for a in args[1:] if not a.startswith('--') and not a.replace('.', '').isdigit()]
AXIS = '--axis' in args
W = float(args[args.index('--w') + 1]) if '--w' in args else 216.0
D = float(args[args.index('--d') + 1]) if '--d' in args else 216.0

data = json.load(open(os.path.join(geo.BUILD, 'city_1to1', 'roads05_' + tag, 'roads.json'), encoding='utf-8'))
cw, pv = road_polys(data)
roads = unary_union([g for _, g in cw + pv]).buffer(2.0)
sh = [s for t in districts for s in shells(t)]
tree = STRtree(sh)
# no-go: landmarks (Studio boxes, 17 Nov), the YCC / Inya Lake Hotel compound (GGFest, 350 m), the fuel stations
nogo = [Point(*geo.world(96.1505, 16.8444)).buffer(geo.m(350))]
for name, x, z, sx, sz in [("MyanmarCentre", 34897, 27549, 638, 958), ("Sedona", 34983, 26798, 558, 851), ("KabaAye", 34622, 17803, 320, 320)]:
    nogo.append(Polygon([(x - sx / 2, z - sz / 2), (x + sx / 2, z - sz / 2), (x + sx / 2, z + sz / 2), (x - sx / 2, z + sz / 2)]).buffer(20))
for t in districts:
    f = os.path.join(geo.BUILD, 'city_1to1', 'places_' + t, 'built.json')
    if os.path.exists(f):
        for st in json.load(open(f, encoding='utf-8'))['fuel']:
            nogo.append(Point(*st['canopy']).buffer(geo.m(45)))
nogo = unary_union(nogo)
boxes = [geo.PILOT_LL[t] for t in districts]


def inside_district(x, z):
    lon, lat = geo.lonlat(x, z)
    return any(b[0] + 0.001 < lon < b[2] - 0.001 and b[1] + 0.001 < lat < b[3] - 0.001 for b in boxes)


def lot_poly(cx, cz, fx, fz):
    ax, az = -fz, fx
    pts = []
    for u, v in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        pts.append((cx + ax * u * W / 2 + fx * v * D / 2, cz + az * u * W / 2 + fz * v * D / 2))
    return Polygon(pts)


cands = []
for r in data['roads']:
    if r['kind'] not in ('route', 'side'):
        continue
    s = r['s']
    for i in range(0, len(s), 6):
        q = s[i]
        x, y, z, dx, dz = q[0], q[1], q[2], q[3], q[4]
        for side, half, walk in ((-1, q[6], r.get('walkL', 7.5)), (1, q[7], r.get('walkR', 7.5))):
            # the right of the direction (dx, dz) is (-dz, dx)
            nx, nz = -dz * side, dx * side
            off = half + walk + 3 + D / 2
            cx, cz = x + nx * off, z + nz * off
            fx, fz = -nx, -nz
            if AXIS:  # square to the world axes, entrance -Z or +Z (hotel, towers)
                if abs(fz) < 0.8:
                    continue
                fx, fz = 0.0, (1.0 if fz > 0 else -1.0)
                cz = z - fz * (abs(nz) * half + walk + 3 + D / 2) / max(abs(nz), 0.8)
            if not inside_district(cx, cz):
                continue
            lp = lot_poly(cx, cz, fx, fz)
            if lp.intersects(roads) or lp.intersects(nogo):
                continue
            score = sum(lp.intersection(sh[k]).area for k in tree.query(lp))
            cands.append((score, round(cx, 1), round(y, 2), round(cz, 1), round(fx, 3), round(fz, 3), r['name']))

cands.sort()
picked = []
for c in cands:
    if all(math.hypot(c[1] - p[1], c[3] - p[3]) > max(W, D) + 40 for p in picked):
        picked.append(c)
    if len(picked) >= 120:
        break
out = os.path.join(geo.BUILD, "city_1to1", "venue_lots_%dx%d%s.json" % (W, D, "_axis" if AXIS else ""))
json.dump([dict(score=c[0], x=c[1], y=c[2], z=c[3], fx=c[4], fz=c[5], road=c[6]) for c in picked], open(out, "w"))
for c in picked[:30]:
    lon, lat = geo.lonlat(c[1], c[3])
    print("%8.0f  x=%.1f z=%.1f y~%.1f fx=%.3f fz=%.3f  %s  (%.5f, %.5f)" % (c[0], c[1], c[3], c[2], c[4], c[5], c[6], lon, lat))
