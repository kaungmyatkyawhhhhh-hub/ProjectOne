"""src/shared/YangonWorld.lua for the 1:1 map (17 Nov 2026, the switch-over; d15_world.py's format for the old map).

House lots, races, delivery dispatches and drops, Legends chips and the Racing Hub, on the 1:1 roads (roads05 +
src/shared/YangonLanes1to1_*.lua). New ids (never the old map's): lots y1_<zone>_<n>, races y1_*, chips saved from
chipBase 2000 (the old map's were 1000+).

Lots: venues_1to1.py --streets candidates (60 x 72 low, 104 x 100 mid, 120 x 130 high), checked in Studio (VenueLots1to1.check: no water,
road or landmark in the lot, a road in front) -> build/city_1to1/house_lots_checked.txt rows "<size>:<i> 0 0" for the failed;
the nearest to Myanmar Plaza first, none overlapping each other.
Races: windows along one long outer lane (start 60 in, checkpoints every 250, at most 5,200 long).
Jobs / chips: the main roads' pavement middles (+0.5; chips +3.1), chips >= 300 apart, drops >= 900 from both dispatches.

    YANGON_SCALE=1to1 python world_1to1.py
"""
import json, math, os, re, sys

from shapely.geometry import Polygon

import geo

B = os.path.join(geo.BUILD, 'city_1to1')
SH = os.path.join(geo.ROOT, 'src', 'shared')
MP = (34897.0, 27549.0)  # Myanmar Plaza: the start
HUB = dict(x=34977.1, z=23603.9, fx=0.991, fz=0.133, y=36.6)  # the Racing Hub's lot (Studio: pavement in front)
DISPATCH = [("Myanmar Plaza Dispatch", 34616.7, 27561.2), ("Kabar Aye Dispatch", 35274.8, 22385.0)]
RACES = [  # id, name, road, way, start offset along the lane
    ("y1_kabaraye", "Kabar Aye Run", "Kabar Aye Pagoda Road", -1, 60),
    ("y1_inya", "Inya Road", "Inya Road #2", 1, 60),
    ("y1_university", "University Avenue", "University Avenue Road #2", 1, 60),
    ("y1_parami", "Parami Road", "Parami Road", 1, 60),
    ("y1_strand", "Strand Road", "Strand Road", 1, 400),
]
DROPS = ["Inya Lake Tea Shop", "Hledan Market Stall", "Kamayut Flats", "University Bookshop", "Pyay Road Bakery",
         "Golden Valley Villa", "Parami Noodle House", "Yankin Office", "Mayangone Pharmacy", "Lakeside Apartments",
         "Bahan Garage", "Thingangyun Flats"]


def v3(p):
    return 'Vector3.new(%.1f, %.2f, %.1f)' % p


def lanes():
    out = []
    for k in range(1, 61):
        f = os.path.join(SH, 'YangonLanes1to1_%d.lua' % k)
        if not os.path.exists(f):
            break
        s = open(f, encoding='utf-8').read()
        for m in re.finditer(r'\{ road = "([^"]*)", way = (-?\d), lane = (\d)([^{]*)pts = \{ ([^}]*) \}', s):
            if 'outer = true' in m.group(4):
                v = [float(x) for x in m.group(5).split(',')]
                out.append((m.group(1), int(m.group(2)), [(v[i], v[i + 1], v[i + 2]) for i in range(0, len(v) - 2, 3)]))
    return out


def along(pts, d):
    """the point and direction d studs along a polyline"""
    for a, b in zip(pts, pts[1:]):
        L = math.hypot(b[0] - a[0], b[2] - a[2])
        if d <= L:
            t = d / L
            return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t), ((b[0] - a[0]) / L, (b[2] - a[2]) / L)
        d -= L
    return None, None


def rect(x, z, fx, fz, w, d):
    ax, az = -fz, fx
    return Polygon([(x + ax * u * w / 2 + fx * v * d / 2, z + az * u * w / 2 + fz * v * d / 2) for u, v in ((-1, -1), (1, -1), (1, 1), (-1, 1))])


def main():
    L = lanes()
    # races
    races = []
    for rid, name, road, way, off in RACES:
        cand = [p for r, w, p in L if r == road and w == way]
        pts = max(cand, key=lambda p: sum(math.hypot(b[0] - a[0], b[2] - a[2]) for a, b in zip(p, p[1:])))
        total = sum(math.hypot(b[0] - a[0], b[2] - a[2]) for a, b in zip(pts, pts[1:]))
        length = min(5200, total - off - 40)
        start, dr = along(pts, off)
        cps = []
        d = 250
        while d < length:
            p, _ = along(pts, off + d)
            cps.append((p[0], p[1] + 3, p[2]))
            d += 250
        p, _ = along(pts, off + length)
        cps.append((p[0], p[1] + 3, p[2]))
        races.append((rid, name, (start[0], start[1] + 3, start[2]), dr, int(length), cps))
    # pavement points of the main roads (jobs, chips)
    data = json.load(open(os.path.join(B, 'roads05_P1_P2_P3', 'roads.json'), encoding='utf-8'))
    cut = {k: set(v) for k, v in data['cut'].items()}
    pave = []
    for r in data['roads']:
        if r['kind'] != 'route':
            continue
        s, c = r['s'], cut.get(r['name'], set())
        for i in range(20, len(s) - 20, 12):
            if any(j in c for j in range(i - 12, i + 13)):
                continue
            q = s[i]
            off = q[7] + r.get('walkR', 7.5) / 2
            pave.append((q[0] - q[4] * off, q[1] + 0.5, q[2] + q[3] * off, r['name']))
    # chips: >= 300 apart, the 1:1 districts P1 / P2 / P3
    chips = []
    for p in pave:
        if all(math.hypot(p[0] - c[0], p[2] - c[2]) >= 300 for c in chips):
            chips.append((p[0], p[1] + 2.6, p[2]))
    chips = chips[::max(1, len(chips) // 60)][:60]
    # drops: >= 900 from both dispatches, >= 600 apart, nearest the start first
    drops = []
    for p in sorted(pave, key=lambda p: math.hypot(p[0] - MP[0], p[2] - MP[1])):
        if p[2] > 34000:
            continue  # (P1 / P2 only: P3 has no road to them yet)
        if all(math.hypot(p[0] - x, p[2] - z) >= 900 for _, x, z in DISPATCH) and all(math.hypot(p[0] - d[0], p[2] - d[2]) >= 600 for d in drops):
            drops.append(p)
        if len(drops) == len(DROPS):
            break
    # house lots
    checked = {}
    for ln in open(os.path.join(B, 'house_lots_checked.txt'), encoding='utf-8'):
        a = ln.split()
        if len(a) == 3:
            checked[a[0]] = (a[1] == '1', float(a[2]))
    taken = [rect(HUB['x'], HUB['z'], HUB['fx'], HUB['fz'], 216, 216).buffer(20)]
    lots = []
    for zone, tier, (w, d), want in (("high", 2, (120, 130), 10), ("mid", 1, (104, 100), 12), ("low", 0, (60, 72), 20)):
        cands = json.load(open(os.path.join(B, 'venue_lots_%dx%d_streets.json' % (w, d))))
        order = sorted(range(len(cands)), key=lambda i: math.hypot(cands[i]['x'] - MP[0], cands[i]['z'] - MP[1]))
        n = 0
        for i in order:
            c = cands[i]
            # (Studio's check: listed rows failed it; the rest passed, floor = the road sample + 0.5 kerb)
            ok = checked.get('%dx%d:%d' % (w, d, i)) or (True, c['y'] + 0.5)
            if not ok or not ok[0]:
                continue
            poly = rect(c['x'], c['z'], c['fx'], c['fz'], w + 16, d + 10)
            if any(poly.intersects(t) for t in taken):
                continue
            taken.append(poly)
            n += 1
            lots.append('\t\t{ id = "y1_%s_%d", zone = "%s", tier = %d, number = %d, x = %.1f, y = %.2f, z = %.1f, fx = %.3f, fz = %.3f, w = %d, d = %d },'
                        % (zone, n, zone, tier, n, c['x'], ok[1], c['z'], c['fx'], c['fz'], w, d))
            if n == want:
                break
    # the hub: bays in a row 50 in from the lot's front, the spot on the pavement facing in
    hx, hz, fx, fz = HUB['x'], HUB['z'], HUB['fx'], HUB['fz']
    ax, az = -fz, fx
    front = (hx + fx * 108, hz + fz * 108)
    bays = []
    for k, r in enumerate(races):
        u = (k - (len(races) - 1) / 2) * 40
        bays.append('\t\t\t%s = %s,' % (r[0], v3((front[0] - fx * 60 + ax * u, HUB['y'], front[1] - fz * 60 + az * u))))
    spot = (front[0] + fx * 6, HUB['y'] + 2.6, front[1] + fz * 6)
    out = ['-- generated by tools/yangon/city/world_1to1.py: do not edit',
           "-- the 1:1 Yangon map's house lots, races, delivery jobs and Legends chips (RivieraWorld's format; ActivityData and",
           '-- IsleLayout load it when Config.activeMap() is "Yangon"); new ids y1_*, chips saved from chipBase',
           'return {', '\tchipBase = 2000,', '\tlots = {'] + lots + ['\t},', '\traces = {']
    for rid, name, st, dr, length, cps in races:
        out.append('\t\t{ id = "%s", name = "%s", start = %s, dir = Vector3.new(%.3f, 0, %.3f), length = %d, checkpoints = { %s } },'
                   % (rid, name, v3(st), dr[0], dr[1], length, ', '.join(v3(p) for p in cps)))
    out += ['\t},', '\tdispatch = {']
    for name, x, z in DISPATCH:
        p = min(pave, key=lambda p: math.hypot(p[0] - x, p[2] - z))
        out.append('\t\t{ name = "%s", pos = %s },' % (name, v3(p[:3])))
    out += ['\t},', '\tdropPoints = {']
    for name, p in zip(DROPS, drops):
        out.append('\t\t{ name = "%s", pos = %s },' % (name, v3(p[:3])))
    out += ['\t},', '\tchips = { %s },' % ', '.join(v3(c) for c in chips),
            "\t-- the Racing Hub: a 216 lot on Kabar Aye Pagoda Road's west side (pad: YangonSites.prepare \"racing_hub\"); a ring per race",
            '\thub = {',
            '\t\tsite = { x = %.1f, z = %.1f, fx = %.3f, fz = %.3f, y = %.2f },' % (hx, hz, fx, fz, HUB['y']),
            '\t\tspot = CFrame.lookAt(%s, %s),' % (v3(spot), v3((hx, HUB['y'] + 2.6, hz))),
            '\t\tbays = {'] + bays + ['\t\t},', '\t},', '}', '']
    open(os.path.join(SH, 'YangonWorld.lua'), 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
    print('%d lots, %d races, %d drops, %d chips' % (len(lots), len(races), len(drops), len(chips)))


if __name__ == '__main__':
    assert geo.ONE_TO_ONE, 'run with YANGON_SCALE=1to1'
    main()
