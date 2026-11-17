"""(J14) dropped-ways overlay: which OSM highway ways roads05 builds and which it leaves out, per district.

    YANGON_SCALE=1to1 python dropped_overlay.py [P1 ...] [--box name x0 z0 x1 z1]
-> "<vault>/City Legends/2026-11-18 roads05 J14 dropped ways - <name>.png": grey = built before J14, green = added by
   the J14 keep_way (service, private compound roads, paved tracks, long linking driveways), red = still left out
   (footways / paths / steps thin pink: not car ways). Data: OpenStreetMap contributors (ODbL).
"""
import os, sys
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import geo, roadnet as RN, roads05 as R

VAULT = os.path.normpath(os.path.join(os.path.dirname(__file__), '..', '..', '..', '..', '..', 'City Legends'))
FOOT = {'footway', 'path', 'steps', 'pedestrian', 'cycleway', 'bridleway', 'corridor', 'platform', 'elevator', 'proposed', 'construction', 'raceway'}


def old_keep(r):
    """keep_way as it was before J14"""
    t = r['t']; hw = t.get('highway')
    if hw in RN.LINKS:
        return t.get('access') not in ('private', 'no') and t.get('area') != 'yes'
    if hw == 'service':
        if not (t.get('name') or t.get('name:en') or t.get('service') == 'alley'):
            return False
        if t.get('service') in ('driveway', 'parking_aisle', 'drive-through'):
            return False
    elif hw not in RN.PUBLIC:
        return False
    return not (t.get('access') in ('private', 'no') or t.get('area') == 'yes' or t.get('motor_vehicle') == 'no')


def draw(ways, nodes, name, box):
    x0, z0, x1, z1 = box
    w = 14 if (x1 - x0) > 3000 else 10
    fig = plt.figure(figsize=(w, w * (z1 - z0) / max(x1 - x0, 1)), dpi=110)
    ax = fig.add_axes([0, 0, 1, 1]); ax.set_facecolor('#1c1c1c')
    n = dict(old=0, new=0, out=0)
    for r, P in ways:
        xs, zs = [p[0] for p in P], [p[1] for p in P]
        if max(xs) < x0 or min(xs) > x1 or max(zs) < z0 or min(zs) > z1:
            continue
        hw = r['t'].get('highway')
        if old_keep(r):
            ax.plot(xs, zs, color='#9a9a9a', lw=1.2); n['old'] += 1
        elif R.keep_way(r, set()) or R.drive_link(r, nodes):
            ax.plot(xs, zs, color='#33dd55', lw=2.0); n['new'] += 1
        elif hw in FOOT:
            ax.plot(xs, zs, color='#ff99cc', lw=0.4)
        else:
            ax.plot(xs, zs, color='#ff3030', lw=1.6); n['out'] += 1
    ax.set_xlim(x0, x1); ax.set_ylim(z1, z0); ax.set_aspect('equal'); ax.axis('off')
    ax.text(x0 + 10, z0 + 10, '%s  grey built before J14 %d, green added %d, red still out %d' % (name, n['old'], n['new'], n['out']),
            color='w', va='top', fontsize=11, bbox=dict(fc='k', alpha=.6))
    out = os.path.join(VAULT, '2026-11-18 roads05 J14 dropped ways - %s.png' % name)
    fig.savefig(out); plt.close(fig)
    print(out, n)


def main():
    a = sys.argv[1:]
    boxes = []
    while '--box' in a:
        i = a.index('--box'); boxes.append((a[i + 1], [float(v) for v in a[i + 2:i + 6]])); del a[i:i + 6]
    tags = a or ['P%d' % i for i in range(1, 13)]
    ways = []
    for r in geo.load('roads'):
        if r['t'].get('highway') and len(r['p']) >= 2:
            ways.append((r, geo.proj(r['p'])))
    nodes = {R.key_of(q) for r, _ in ways if R.keep_way(r, set()) for q in r['p']}
    for name, b in boxes:
        draw(ways, nodes, name, b)
    if not boxes:
        for t in tags:
            x0, z0, x1, z1 = geo.batch_poly(t).bounds
            draw(ways, nodes, t, (x0, z0, x1, z1))


if __name__ == '__main__':
    main()
