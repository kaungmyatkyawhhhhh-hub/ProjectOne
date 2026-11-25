"""Invisible collision on the roads (26 Nov 2026, owner: "there is some invisible parts on the roads too", e.g. the
Kabar Aye flyover's lower road by the fuel station).

Checks every collision box of Workspace.Yangon1to1.Roads (Collide + the old CollideFix_* folders; Studio print
"BXD folder kind cx cy cz rx ry rz ux uy uz sx sy sz transparency" -> roadbugs_25nov/boxes_place.txt) against the
road meshes really in the place (match.json): 3 x 3 points on each box top.
  float   the top is > 0.3 over the highest visible surface under it (within 8) and no visible surface is within 0.3 of
          it, at >= 3 points: an invisible step / ceiling (a pavement box left 4-6 over the lower road)
  bare    no visible surface at all under >= 6 of the points: collision with no road there
Walls (W) stand up on purpose and are skipped.
    python roadbugs_boxes.py [boxes file] -> roadbugs_25nov/boxes_bad.txt ("kind_of_bug folder kind cx cy cz ... seat_dy")
"""
import collections, json, math, os, sys
import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from roadbugs_index import read_glb, OUT, ROOT
from roadbugs_detect import Surf

CELL = 1536.0
VISK = ('R', 'P', 'KR', 'KW', 'MG', 'B')


def job(arg):
    cell, ms, rows = arg
    cache, T = {}, []
    for m in ms:
        if m['glb'] not in cache:
            cache[m['glb']] = read_glb(os.path.join(ROOT, m['glb']))
        T.append(cache[m['glb']][m['name']])
    S = Surf(np.concatenate(T)) if T else None
    out = []
    for r in rows:
        folder, kind = r[1], r[2]
        if kind == 'W':
            continue
        c = np.array(list(map(float, r[3:6])))
        R = np.array(list(map(float, r[6:9])))
        U = np.array(list(map(float, r[9:12])))
        Sz = np.array(list(map(float, r[12:15])))
        L = np.cross(R, U)
        fl, bare, gaps = 0, 0, []
        for a in (-0.4, 0, 0.4):
            for b in (-0.4, 0, 0.4):
                top = c + R * Sz[0] * a + U * Sz[1] / 2 + L * Sz[2] * b
                ys = S.ys(top[0], top[2]) if S else []
                if not ys:
                    bare += 1
                    continue
                if any(abs(y - top[1]) <= 0.3 for y in ys):
                    continue
                below = [y for y in ys if top[1] - 8 < y < top[1]]
                if below:
                    fl += 1
                    gaps.append(top[1] - max(below))
        if bare >= 6:
            out.append(('bare', r, 0.0))
        elif fl >= 3:
            out.append(('float', r, -float(np.median(gaps))))
    return cell, out


def main(boxes):
    import multiprocessing as mp
    rows = [l.split() for l in open(boxes) if l.startswith('BXD')]
    by = collections.defaultdict(list)
    for r in rows:
        by['%dx%d' % (math.floor(float(r[3]) / CELL), math.floor(float(r[5]) / CELL))].append(r)
    match = json.load(open(os.path.join(OUT, 'match.json')))['match']
    mcell = collections.defaultdict(list)
    for m in match.values():
        if m['kind'] in VISK:
            mcell[m['cell']].append(m)
    jobs = []
    for cell, rs in by.items():
        cx, cz = map(int, cell.split('x'))
        ms = [m for dx in (-1, 0, 1) for dz in (-1, 0, 1) for m in mcell.get('%dx%d' % (cx + dx, cz + dz), [])]
        jobs.append((cell, ms, rs))
    cnt = collections.Counter()
    with mp.Pool(int(os.environ.get('RB_PROCS', 3))) as pool, open(os.path.join(OUT, os.environ.get('RB_OUTF', 'boxes_bad.txt')), 'w') as f:
        for cell, out in pool.imap_unordered(job, jobs):
            for what, r, dy in out:
                cnt[(what, r[1], r[2])] += 1
                f.write('%s %s %.2f\n' % (what, ' '.join(r[1:]), dy))
            print(cell, len(out), flush=True)
    for k, v in sorted(cnt.items()):
        print(k, v)


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(OUT, 'boxes_place.txt'))
