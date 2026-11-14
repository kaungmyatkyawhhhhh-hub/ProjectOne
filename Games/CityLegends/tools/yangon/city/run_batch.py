"""One command per batch for the lived-in layer, the trees and the street lamps (14 Nov 2026).

    python run_batch.py <tag>        (run from Games/CityLegends/tools/yangon/city; tag 1, 2, 3, or 05)

  1. details.py <tag>       -> build/city/details_<tag>.json, Details_<tag>_<n>.luau, YangonLampSpots_<tag>_<n>.luau (batches)
  2. details_test.py <tag>  -> overlaps (carriageways, lanes, plots), batch outline, footbridge clearance, lamp spots, modules
  3. green.py <tag>         -> YangonGreenData_<tag>_<n>.luau (+ its own test); after 1, so trees keep off the detail items
  4. prints the pack_sync command with every file the lead uploads.
Needs build/city/plots_<tag>.json, roads_<tag>_profile.json, RoadCollide_<tag>_*.luau and YangonLanesB<tag>_*.lua.
Stops at the first failing step (exit code 1).
"""
import glob, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
CITY = os.path.join(ROOT, 'build', 'city')


def main(tag):
    need = ['plots_%s.json' % tag]
    if tag != '05':
        need += ['roads_%s_profile.json' % tag]
        if not glob.glob(os.path.join(CITY, 'RoadCollide_%s_*.luau' % tag)):
            need.append('RoadCollide_%s_*.luau' % tag)
    missing = [n for n in need if '*' in n or not os.path.exists(os.path.join(CITY, n))]
    if missing:
        print('batch %s: missing %s in build/city: make them first (plots.py %s / roads.py %s)' % (tag, ', '.join(missing), tag, tag))
        return 1
    steps = [['details.py', tag], ['details_test.py', tag]] + ([['green.py', tag]] if tag != '05' else [])
    for st in steps:
        print('==== python %s' % ' '.join(st), flush=True)
        r = subprocess.run([sys.executable, '-u'] + st, cwd=HERE)
        if r.returncode != 0:
            print('==== %s failed (exit %d)' % (st[0], r.returncode))
            return 1
    rel = lambda p: os.path.relpath(p, ROOT).replace(os.sep, '/')
    key = lambda p: int(p.rsplit('_', 1)[1].split('.')[0])
    files = ['tools/yangon/YangonDetails.luau']
    if tag != '05':
        files += ['tools/yangon/YangonLampsBatch.luau', 'tools/yangon/YangonGreenBatch.luau']
    files += [rel(p) for p in sorted(glob.glob(os.path.join(CITY, 'Details_%s_*.luau' % tag)), key=key)]
    files += [rel(p) for p in sorted(glob.glob(os.path.join(CITY, 'YangonLampSpots_%s_*.luau' % tag)), key=key)]
    files += [rel(p) for p in sorted(glob.glob(os.path.join(CITY, 'YangonGreenData_%s_*.luau' % tag)), key=key)]
    print('==== all passed. Pack (from Games/CityLegends):')
    print('python tools/yangon/pack_sync.py imports/sync/yangon_tools_1.rbxmx ' + ' '.join(files))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else '1'))
