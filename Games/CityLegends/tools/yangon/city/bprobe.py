"""Whole-Yangon map (14 Nov 2026): ground heights for the building plots (for d24_bmesh's "y").

  python bprobe.py prep 05   -> build/city/BProbe_<n>.luau (lines "x z": each plot's corners and middle) + bprobe_05_index.json
  (Studio: YangonProbe2.spawn({"BProbe_1", ...}), read the pages, join them with join_pages.py into build/city/bprobe_05_out.txt)
  python bprobe.py apply 05  -> writes "y" into build/city/plots_05.json: the lowest ground under the plot (points on a road
                                part are ignored), so no building floats; its walls go 0.4 below that.
"""
import json, os, sys

import geo

NL = chr(10)


def prep(tag):
    path = os.path.join(geo.BUILD, 'city', f'plots_{tag}.json')
    d = json.load(open(path, encoding='utf-8'))
    lines, index = [], []
    for p in d['plots']:
        pts = p['poly']
        cx = sum(q[0] for q in pts) / len(pts)
        cz = sum(q[1] for q in pts) / len(pts)
        mine = [(cx, cz)] + [(cx + (x - cx) * 0.9, cz + (z - cz) * 0.9) for x, z in pts]
        index.append(len(mine))
        lines += [f'{x:.1f} {z:.1f}' for x, z in mine]
    json.dump(index, open(os.path.join(geo.BUILD, 'city', f'bprobe_{tag}_index.json'), 'w'))
    for f in os.listdir(os.path.join(geo.BUILD, 'city')):
        if f.startswith('BProbe_'):
            os.remove(os.path.join(geo.BUILD, 'city', f))
    chunk, n = 11000, 0
    for k in range(0, len(lines), chunk):
        n += 1
        open(os.path.join(geo.BUILD, 'city', f'BProbe_{n}.luau'), 'w', encoding='utf-8', newline=NL).write(
            'return [==[' + NL + NL.join(lines[k:k + chunk]) + NL + ']==]' + NL)
    print(len(d['plots']), 'plots,', len(lines), 'points in', n, 'modules')


def apply(tag):
    path = os.path.join(geo.BUILD, 'city', f'plots_{tag}.json')
    d = json.load(open(path, encoding='utf-8'))
    index = json.load(open(os.path.join(geo.BUILD, 'city', f'bprobe_{tag}_index.json')))
    rows = [r for r in open(os.path.join(geo.BUILD, 'city', f'bprobe_{tag}_out.txt'), encoding='utf-8').read().split(NL) if r.strip()]
    assert len(rows) == sum(index), (len(rows), sum(index))
    k = 0
    miss = 0
    for p, n in zip(d['plots'], index):
        ys = []
        for r in rows[k:k + n]:
            gy, ty, kind = r.split('|')
            if kind in ('R', 'P', 'K', 'D'):
                continue
            if gy:
                ys.append(float(gy))
        k += n
        if ys:
            p['y'] = round(min(ys) - 0.4, 2)
        else:
            miss += 1
            p['y'] = None
    d['plots'] = [p for p in d['plots'] if p.get('y') is not None]
    json.dump(d, open(path, 'w', encoding='utf-8'), separators=(',', ':'))
    print('heights set;', miss, 'plots dropped (no ground found: all points on roads)')


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    {'prep': prep, 'apply': apply}[sys.argv[1]](sys.argv[2])
