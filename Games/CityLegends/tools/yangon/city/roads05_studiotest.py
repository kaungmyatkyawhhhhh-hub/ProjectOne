"""Studio test data for the roads05 network: the test spots' roads + paint + cameras, packed for Studio (J16, 18 Nov 2026).

    YANGON_SCALE=1to1 python roads05_studiotest.py [net dir] [paint.json]  (the paint agent's newest run may sit in its own dir)
-> build/city_1to1/roads05_studiotest/: Roads05_<k>.luau (YangonData road modules, via roads05_jsubset), Roads05Paint_<k>.luau
   (paint triangles "K x1 z1 y1 x2 z2 y2 x3 z3 y3" per line, data heights; Studio rays them onto the built surface),
   spots.json (box + three cameras per spot, heights WITHOUT the lift), and imports/sync/roads05_studiotest.rbxmx
   (YangonRoads + Roads05StudioTest runner + the modules) for the Open Cloud PATCH of asset 133014134133489.

The Studio side is tools/yangon/city/Roads05StudioTest.luau (load / run one spot / paint / pick / clean): see its header.
The test builds one spot at a time in workspace.Roads05Test, lifted LIFT studs, terrain writes go to a no-op.
"""
import json, math, os, subprocess, sys

import numpy as np
import shapely
from shapely.geometry import Polygon, box as sbox

sys.stdout.reconfigure(encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.normpath(os.path.join(HERE, '..', '..', '..'))
B = os.path.join(GAME, 'build', 'city_1to1')
NET = os.path.join(B, 'roads05_P1_P2_P3_P4_P5_P6_P7_P8_P9_P10_P11_P12')
OUT = os.path.join(B, 'roads05_studiotest')
RBX = os.path.join(GAME, 'imports', 'sync', 'roads05_studiotest.rbxmx')
CHUNK = 185000

# name: (x, z, half box, label, drive road or None, drive back distance)
SPOTS = {
    'univ_kabaraye': (34426.35, 28891.06, 260, 'University Ave x Kabar Aye (under flyover)', 'Hledan Road #3', 110),
    'hanthawaddy': (28250.52, 32193.17, 260, 'Hanthawaddy Roundabout', None, 150),
    'pyay_univ': (27065.65, 27858.72, 260, 'Pyay Road x University Ave', None, 110),
    'roundabout4': (35997, 45118, 260, 'Sule Roundabout', None, 150),
    'slip_triangle': (43471, 29324, 260, 'Waizayandar x Lay Daungkan slips', None, 110),
    'bahan_ring': (35316, 37910, 300, 'Bahan Road at Roundabout 1', None, 150),
    'pazundaung_y': (41000, 43412, 260, 'Bogyoke x Pazundaung Y', None, 110),
    'ycentral': (36120, 42950, 330, 'Yangon Central (Alan Pya / Gyophyu decks)', None, 130),
    'kunchan_gyophyu': (36350, 42490, 220, 'Kun Chan x Gyophyu', None, 100),
    'double_junction': (39959, 32817, 220, 'Double junction (East Horse Race Course x Banyar Dala)', None, 110),
    'sule_shangrila': (36076, 43473, 220, 'Sule Shangri-La corner', None, 110),
    'downtown_straight': (35977.2, 45612.0, 220, 'Downtown straight (Sule Pagoda Rd #2, barrier median)', 'Sule Pagoda Road #2', 110),
    'hledan_flyover': (25387.4, 28565.3, 260, 'Baho Rd under the Hledan flyover', 'Baho Road #3', 110),
    'deck_run': (34266.8, 42814.4, 420, 'Shwedagon Pagoda Rd deck at Phaya Lan (climb, run, land)', 'Shwedagon Pagoda Road', 380),
    'long_median': (42916.6, 27960.9, 260, 'Long straight median (Waizayandar Rd)', 'Waizayandar Road', 200),
    'lane_taper': (38720.9, 44068.2, 220, 'Lane taper (Thein Phyu Rd 3 -> 2)', 'Thein Phyu Road', 120),
}
# close-ups that are not a junction corner: (camera, target), data heights
CLOSE = {
    'ycentral': ((36165, 82, 42790), (36102, 50, 42836)),  # the deck fork: Sule Pagoda Rd's deck -> Alan Pya + Gyophyu decks
    'deck_run': ((34305, 62, 43165), (34261, 44, 43065)),  # the south landing
}


def nearest(road, x, z):
    S = np.array([(q[0], q[2]) for q in road['s']])
    return int(np.argmin(((S - (x, z)) ** 2).sum(1)))


def cams(d, R, J, name, spot):
    """overview (straight down), close-up (a corner: bisector of the junction's first two arms), driver (on an approach)"""
    x, z, h, _, drive, back = spot
    # the road nearest the centre and its height
    best = min(((math.hypot(r['s'][i][0] - x, r['s'][i][2] - z), r['name'], i) for r in R.values()
                for i in [nearest(r, x, z)] if abs(r['s'][i][0] - x) < 200 and abs(r['s'][i][2] - z) < 200), default=None)
    y0 = R[best[1]]['s'][best[2]][1] if best else 30.0
    over = dict(pos=[x, y0 + h * 1.1, z + 0.1], at=[x, y0, z])
    jn = min(J, key=lambda j: math.hypot(j['x'] - x, j['z'] - z))
    if name in CLOSE:
        close = dict(pos=list(CLOSE[name][0]), at=list(CLOSE[name][1]))
    elif math.hypot(jn['x'] - x, jn['z'] - z) < 80 and len(jn['arms']) >= 2:
        a, b = jn['arms'][0]['dir'], jn['arms'][1]['dir']
        bx, bz = a[0] + b[0], a[1] + b[1]
        L = math.hypot(bx, bz) or 1
        bx, bz = bx / L, bz / L
        cx, cz = jn['x'], jn['z']
        close = dict(pos=[cx + bx * 75, y0 + 40, cz + bz * 75], at=[cx + bx * 22, y0, cz + bz * 22])
    else:
        r = R[best[1]]
        s = r['s'][best[2]]
        nx, nz = -s[4], s[3]
        close = dict(pos=[x + nx * 45 + s[3] * 30, y0 + 28, z + nz * 45 + s[4] * 30], at=[x, y0, z])
    # driver: on the drive road (else the nearest road), back distance before the centre, looking along it
    if drive and drive not in R:  # a name prefix: the piece nearest the centre
        drive = min((n for n in R if n.startswith(drive)), key=lambda n: min(math.hypot(q[0] - x, q[2] - z) for q in R[n]['s']))
    r = R[drive] if drive else R[best[1]]
    i = nearest(r, x, z)
    s = r['s']
    j, run = i, 0.0
    # (J23: the driver stands inside the spot (0.55 of the half box), not at the test box edge where roads end)
    while j > 0 and run < back and math.hypot(s[j - 1][0] - x, s[j - 1][2] - z) < h * 0.55:
        run += math.hypot(s[j][0] - s[j - 1][0], s[j][2] - s[j - 1][2])
        j -= 1
    if run < back * 0.6:  # too near the road's start: come from the other end
        j, run = i, 0.0
        while j < len(s) - 1 and run < back and math.hypot(s[j + 1][0] - x, s[j + 1][2] - z) < h * 0.55:
            run += math.hypot(s[j + 1][0] - s[j][0], s[j + 1][2] - s[j][2])
            j += 1
    # (J23: never inside a roundabout's island: a ring arm's nearest sample to the centre lies in the ring)
    while 0 < j < len(s) - 1 and math.hypot(s[j][0] - x, s[j][2] - z) < h * 0.35:
        j = j + 1 if math.hypot(s[j + 1][0] - x, s[j + 1][2] - z) > math.hypot(s[j - 1][0] - x, s[j - 1][2] - z) else j - 1
    q = s[j]
    # the middle of the right-hand carriageway (Yangon drives on the right; past the median on a divided road)
    dx, dz = x - q[0], z - q[2]
    L = math.hypot(dx, dz) or 1
    dx, dz = dx / L, dz / L
    off = (q[8] + q[7]) / 2 if q[8] > 0 else min(q[7] / 2, 14)
    px, pz = q[0] - dz * off, q[2] + dx * off
    # a deck run's driver sits on the deck (the deck's own sample height)
    py = q[1]
    for k in d['decks']:
        if k['of'] == r['name']:
            ks = k['s']
            m = int(np.argmin([(p[0] - px) ** 2 + (p[2] - pz) ** 2 for p in ks]))
            if (ks[m][0] - px) ** 2 + (ks[m][2] - pz) ** 2 < 25 ** 2:
                py = max(py, ks[m][1])
    yc = s[i][1]
    driver = dict(pos=[px, py + 4.0, pz], at=[x - dz * off * 0.3, yc + 2.0, z + dx * off * 0.3])
    return dict(overview=over, closeup=close, driver=driver)


def paint_tris(P, SRC, box):
    x0, z0, x1, z1 = box
    clip = sbox(x0 + 2, z0 + 2, x1 - 2, z1 - 2)  # the builder stops at the box: paint past it would hang in the air
    out = []
    for it in P['items']:
        p = it['p']
        if max(q[0] for q in p) < x0 or min(q[0] for q in p) > x1 or max(q[1] for q in p) < z0 or min(q[1] for q in p) > z1:
            continue
        src = SRC.get(it['r'])  # a road's samples, a deck's (deck paint names the deck), a ring's centre
        poly = Polygon(p)
        if not poly.is_valid:
            poly = poly.buffer(0)
        poly = poly.intersection(clip)
        if poly.is_empty or poly.area < 0.01:
            continue
        tris = shapely.constrained_delaunay_triangles(poly)
        for t in shapely.get_parts(tris):
            c = list(t.exterior.coords)[:3]
            v = []
            for cx, cz in c:
                if src:
                    S = np.array([(q[0], q[2]) for q in src])
                    y = src[int(np.argmin(((S - (cx, cz)) ** 2).sum(1)))][1]
                else:
                    y = 30.0
                v += [cx, cz, y]
            out.append(it['k'] + ' ' + ' '.join('%.2f' % u for u in v))
    return out


def main():
    net = sys.argv[1] if len(sys.argv) > 1 else NET
    os.makedirs(OUT, exist_ok=True)
    J = {k: [v[0], v[1]] for k, v in SPOTS.items()}
    json.dump(J, open(os.path.join(OUT, 'junctions_in.json'), 'w'))
    subprocess.run([sys.executable, os.path.join(HERE, 'roads05_jsubset.py'), net, OUT, os.path.join(OUT, 'junctions_in.json')], check=True)
    d = json.load(open(os.path.join(net, 'roads.json'), encoding='utf-8'))
    R = {r['name']: r for r in d['roads']}
    pj = sys.argv[2] if len(sys.argv) > 2 else os.path.join(net, 'paint.json')
    P = json.load(open(pj, encoding='utf-8'))
    print('paint', pj)
    SRC = {r['name']: r['s'] for r in d['roads']}
    SRC.update({k['name']: k['s'] for k in d['decks']})
    SRC.update({g['name']: [g['c']] for g in d['roundabouts']})
    spots, lines = {}, []
    for name, sp in SPOTS.items():
        x, z, h = sp[:3]
        box = [x - h, z - h, x + h, z + h]
        a = len(lines)
        lines += paint_tris(P, SRC, box)
        spots[name] = dict(label=sp[3], box=box, paint=[a + 1, len(lines)], cams=cams(d, R, d['junctions'], name, sp))
        print('%-18s paint tris %5d' % (name, len(lines) - a))
    for f in os.listdir(OUT):
        if f.startswith('Roads05Paint_'):
            os.remove(os.path.join(OUT, f))
    txt = '\n'.join(lines)
    k, a = 0, 0
    while a < len(txt):
        b = min(len(txt), a + CHUNK)
        if b < len(txt):
            b = txt.rindex('\n', a, b) + 1  # whole lines per module
        k += 1
        open(os.path.join(OUT, 'Roads05Paint_%d.luau' % k), 'w', encoding='utf-8', newline='\n').write('return [==[' + txt[a:b] + ']==]')
        a = b
    ver = open(os.path.join(B, 'roads05_NETWORK_VERSION.txt')).read().strip() if os.path.exists(os.path.join(B, 'roads05_NETWORK_VERSION.txt')) else \
        subprocess.run(['git', 'log', '-1', '--format=%h %s'], cwd=GAME, capture_output=True, text=True).stdout.strip()[:120]  # build/ data is not in git: the HEAD it came with
    json.dump(dict(version=ver, spots=spots), open(os.path.join(OUT, 'spots.json'), 'w'), indent=1)
    # spots as a Luau module too (the runner reads it)
    open(os.path.join(OUT, 'Roads05Spots.luau'), 'w', encoding='utf-8', newline='\n').write('return [==[' + json.dumps(spots) + ']==]')
    nr = len([f for f in os.listdir(OUT) if f.startswith('Roads05_')])
    files = [os.path.join(GAME, 'tools', 'yangon', 'YangonRoads.luau'), os.path.join(GAME, 'tools', 'riviera', 'Roads.luau'), os.path.join(HERE, 'Roads05StudioTest.luau'), os.path.join(OUT, 'Roads05Spots.luau')]
    files += [os.path.join(OUT, 'Roads05_%d.luau' % i) for i in range(1, nr + 1)]
    files += [os.path.join(OUT, 'Roads05Paint_%d.luau' % i) for i in range(1, k + 1)]
    subprocess.run([sys.executable, os.path.join(GAME, 'tools', 'yangon', 'pack_tools.py'), RBX] + files, check=True, stdout=subprocess.DEVNULL)
    print('road modules %d, paint modules %d (%d tris), rbxmx %d bytes, net: %s' % (nr, k, len(lines), os.path.getsize(RBX), ver))


if __name__ == '__main__':
    main()
