"""Keep landmark ramps open in a roads05 network (18 Nov 2026, the Myanmar Centre basement ramps).

build/city_1to1/ramp_mouths.json lists each ramp (top on the street, axis, len, outer width), the street mouth
(a driveway of kind "ramp": YangonRoads.sideZone drops the kerb AND the pavement there) and the OSM ways to drop
(basement aisles that run through the building at street level). apply(data, paint) then:
  - drops the listed roads (and their paint),
  - cuts every other road's samples from the first one on a ramp's footprint to that road's far end (no asphalt,
    no collision over the ramp; the cut end is square),
  - adds the mouths to data.driveways, drops paint whose middle lies on a ramp.
roads05_fix.py calls it before its checks; standalone (an already-fixed network, in place, backup *_preramps.json):
    YANGON_SCALE=1to1 python roads05_ramps.py <network tag>
"""
import json, os, shutil, sys
from shapely.geometry import Point, Polygon
import geo

SRC = os.path.join(geo.BUILD, 'city_1to1', 'ramp_mouths.json')


def footprints(cfg, grow=2.0):
    out = []
    for r in cfg['ramps']:
        (x, z), (ax, az), L, hw = r['top'], r['axis'], r['len'], r['w'] / 2
        nx, nz = -az, ax
        out.append(Polygon([(x + nx * hw, z + nz * hw), (x + ax * L + nx * hw, z + az * L + nz * hw),
                            (x + ax * L - nx * hw, z + az * L - nz * hw), (x - nx * hw, z - nz * hw)]).buffer(grow))
    return out


def apply(data, paint=None, cfg=None):
    cfg = cfg or json.load(open(SRC))
    feet = footprints(cfg)
    drop = set(cfg.get('drop', []))
    n0 = len(data['roads'])
    data['roads'] = [r for r in data['roads'] if r['name'] not in drop]
    cut = data.setdefault('cut', {})
    for k in drop:
        cut.pop(k, None)
    cuts = {}
    for r in data['roads']:
        inside = [i for i, s in enumerate(r['s']) if any(f.contains(Point(s[0], s[2])) for f in feet)]
        if not inside:
            continue
        # the ramp is at one end: cut from it to that end
        i0, n = inside[0], len(r['s'])
        idx = range(i0, n) if i0 >= n - 1 - inside[-1] else range(0, inside[-1] + 1)
        old = set(cut.get(r['name'], []))
        cut[r['name']] = sorted(old | set(idx))
        cuts[r['name']] = len(cut[r['name']]) - len(old)
    dw = [d for d in data.get('driveways', []) if d.get('kind') != 'ramp']
    for r in cfg['ramps']:
        if 'mouth' in r:
            m = r['mouth']
            dw.append(dict(x=m['x'], z=m['z'], hw=m['hw'], across=m['across'], kind='ramp'))
    data['driveways'] = dw
    gone = 0
    if paint is not None:
        keep = []
        for it in paint['items']:
            p = it['p']
            c = Point(sum(q[0] for q in p) / len(p), sum(q[1] for q in p) / len(p))
            if it.get('r') in drop or any(f.contains(c) for f in feet):
                gone += 1
            else:
                keep.append(it)
        paint['items'] = keep
    return dict(dropped=n0 - len(data['roads']), cut=cuts, mouths=sum('mouth' in r for r in cfg['ramps']), paint_dropped=gone)


if __name__ == '__main__':
    D = os.path.join(geo.BUILD, 'city_1to1', 'roads05_' + sys.argv[1])
    rp, pp = os.path.join(D, 'roads.json'), os.path.join(D, 'paint.json')
    for p in (rp, pp):
        b = p.replace('.json', '_preramps.json')
        if os.path.exists(p) and not os.path.exists(b):
            shutil.copy(p, b)
    data = json.load(open(rp, encoding='utf-8'))
    paint = json.load(open(pp, encoding='utf-8')) if os.path.exists(pp) else None
    st = apply(data, paint)
    # self-check: nothing of a dropped road left, no kept sample on a ramp
    feet = footprints(json.load(open(SRC)))
    for r in data['roads']:
        cs = set(data['cut'].get(r['name'], []))
        for i, s in enumerate(r['s']):
            assert i in cs or not any(f.contains(Point(s[0], s[2])) for f in feet), (r['name'], i)
    open(rp, 'w', encoding='utf-8').write(json.dumps(data, separators=(',', ':')))
    if paint is not None:
        open(pp, 'w', encoding='utf-8').write(json.dumps(paint, separators=(',', ':')))
    print(json.dumps(st))
