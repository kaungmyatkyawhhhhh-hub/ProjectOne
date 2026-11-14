"""Whole-Yangon map (14 Nov 2026): checks on roads.py's outputs for a batch, read back from the files.

    python roads_check.py <tag>

  * lane modules (build/city/YangonLanesB<tag>_<n>.lua): `first` follows on from src/shared's modules (and the earlier
    batches'), every module < 190,000 characters, every link points at a real lane and a real point, every lane's end has
    a way on (the dead-end check, the same rule as d9_lanes.py), lanes never jump (points <= 40 studs apart, <= 4 up/down)
  * collision modules (RoadCollide_<tag>_<n>.luau): < 190,000 characters, 9 fields a line, known kinds
  * glb manifest: no mesh over 17,000 triangles, no file over 100 meshes
"""
import json, math, os, re, sys

import geo
import roadlanes as rl

OUT = os.path.join(geo.BUILD, 'city')


def lanes_of(src):
    out = []
    for m in re.finditer(r'\{ road = "([^"]*)", way = (-?\d+), lane = (\d+), kind = "(\w+)", closed = (\w+)[^}]*?pts = \{ ([^}]*) \}', src):
        v = [float(x) for x in m.group(6).split(',')]
        out.append(dict(road=m.group(1), closed=m.group(5) == 'true', pts=[v[k:k + 3] for k in range(0, len(v), 3)]))
    return out


def main(tag):
    errs = []
    mods = rl.existing_modules()
    glob = {}
    total = 0
    for nm, n, first, src in mods:
        for k, l in enumerate(lanes_of(src)):
            glob[first + k] = l
        total = max(total, first + n - 1)
    # (2026-11-14) the earlier batches' lanes too: a batch's seam links run into them (roadlanes._seam_batches)
    for t in ('1', '2', '3'):
        if t == tag:
            break
        for f in sorted((f for f in os.listdir(OUT) if re.match(r'YangonLanesB%s_\d+\.lua$' % t, f)),
                        key=lambda f: int(re.search(r'_(\d+)\.lua$', f).group(1))):
            src = open(os.path.join(OUT, f), encoding='utf-8').read()
            first = int(re.search(r'first\s*=\s*(\d+)', src).group(1))
            for k, l in enumerate(lanes_of(src)):
                glob[first + k] = l
    files = sorted((f for f in os.listdir(OUT) if re.match(r'YangonLanesB%s_\d+\.lua$' % tag, f)),
                   key=lambda f: int(re.search(r'_(\d+)\.lua$', f).group(1)))
    expect = rl.first_index(tag)
    links = []
    mine = set()
    for f in files:
        src = open(os.path.join(OUT, f), encoding='utf-8').read()
        if len(src) >= 190000:
            errs.append('%s is %d characters' % (f, len(src)))
        first = int(re.search(r'first\s*=\s*(\d+)', src).group(1))
        if first != expect:
            errs.append('%s first %d, expected %d' % (f, first, expect))
        ls = lanes_of(src)
        for k, l in enumerate(ls):
            glob[first + k] = l
            mine.add(first + k)
        expect = first + len(ls)
        for m in re.finditer(r'\{ (\d+), (\d+), (\d+), (\d+) \},', src.split('links = {', 1)[1]):
            links.append(tuple(int(x) for x in m.groups()))
    out_end = {i: False for i in mine}
    for a, fk, b, tk in links:
        if a not in glob or b not in glob:
            errs.append('link to a missing lane %s' % str((a, fk, b, tk)))
            continue
        if not (1 <= fk <= len(glob[a]['pts'])) or not (1 <= tk <= len(glob[b]['pts'])):
            errs.append('link point out of range %s' % str((a, fk, b, tk)))
        if a in mine and fk >= len(glob[a]['pts']) - 3:
            out_end[a] = True
        pa, pb = glob[a]['pts'][min(fk, len(glob[a]['pts'])) - 1], glob[b]['pts'][min(tk, len(glob[b]['pts'])) - 1]
        if math.hypot(pa[0] - pb[0], pa[2] - pb[2]) > 160:
            errs.append('long link %s: %.0f studs' % (str((a, fk, b, tk)), math.hypot(pa[0] - pb[0], pa[2] - pb[2])))
    dead = [i for i, v in out_end.items() if not v and not glob[i]['closed']]
    jumps = 0
    for i in mine:
        p = glob[i]['pts']
        for q, r in zip(p, p[1:]):
            if math.hypot(q[0] - r[0], q[2] - r[2]) > 40 or abs(q[1] - r[1]) > 4:
                jumps += 1
    seam = sum(1 for a, fk, b, tk in links if (a in mine) != (b in mine))
    print('lanes %d (%d..%d), links %d (%d to / from batch 0.5), dead ends %d, point jumps %d' % (
        len(mine), min(mine), max(mine), len(links), seam, len(dead), jumps))
    for f in sorted(os.listdir(OUT)):
        if re.match(r'RoadCollide_%s_\d+\.luau$' % tag, f):
            src = open(os.path.join(OUT, f), encoding='utf-8').read()
            if len(src) >= 190000:
                errs.append('%s is %d characters' % (f, len(src)))
            for line in src.split('\n')[1:-2]:
                w = line.split()
                if len(w) != 9 or w[8] not in 'RPMJDW':
                    errs.append('%s bad line %r' % (f, line[:60]))
                    break
    man = json.load(open(os.path.join(OUT, 'roads_%s' % tag, 'manifest.json')))
    for fl in man['files']:
        if len(fl['meshes']) > 100:
            errs.append('%s has %d meshes' % (fl['glb'], len(fl['meshes'])))
        for m in fl['meshes']:
            if m['tris'] > 17000:
                errs.append('%s %s has %d triangles' % (fl['glb'], m['name'], m['tris']))
    print('glb files %d, meshes %d, biggest mesh %d triangles' % (len(man['files']), man['meshes'],
                                                                 max(m['tris'] for fl in man['files'] for m in fl['meshes'])))
    print('errors: %s' % ('none' if not errs else '\n  '.join(errs[:30]) + ('\n  ... %d more' % (len(errs) - 30) if len(errs) > 30 else '')))
    for i in dead[:10]:
        print('  dead end:', glob[i]['road'], glob[i]['pts'][-1])


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    main(sys.argv[1])
