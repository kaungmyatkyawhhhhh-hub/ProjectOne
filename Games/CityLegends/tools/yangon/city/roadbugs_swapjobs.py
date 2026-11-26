"""Studio job list for RoadMeshSwap.luau from a re-bake's glb folder and its ids file (25 Nov 2026).

    python roadbugs_swapjobs.py <tag> [max cells per job]   -> prints the Lua table for _G.MSWALL
ids file: build/city_1to1/roadbugs_25nov/ids_RBA_<tag>.txt ("roads05_<n>.glb <assetId>"); glbs: imports/sync/RBA_<tag>_glb.
Cells = the cells the glbs' meshes hold. A job takes the glbs of a group of cells (a glb holds meshes of several cells).
"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from roadbugs_index import glb_names, ROOT, OUT

tag = sys.argv[1]
PRE = os.environ.get('RB_GLB_PREFIX', 'RBA_')   # (26 Nov) round 3 bakes are RBC_
ids = dict(l.split() for l in open(os.path.join(OUT, 'ids_%s%s.txt' % (PRE, tag))) if l.strip())
gdir = os.path.join(ROOT, 'imports', 'sync', '%s%s_glb' % (PRE, tag))
cells_of = {f: sorted(set(m['name'].split('_')[1].split('s')[0] for m in glb_names(os.path.join(gdir, f))['meshes'])) for f in ids}
# group glbs into connected sets by shared cells (a cell's meshes may be split over two glbs)
groups = []
for f, cs in cells_of.items():
    hit = [g for g in groups if g[1] & set(cs)]
    ng = ({f}, set(cs))
    for g in hit:
        ng[0].update(g[0]); ng[1].update(g[1]); groups.remove(g)
    groups.append(ng)
out = []
for k, (fs, cs) in enumerate(sorted(groups, key=lambda g: sorted(g[1]))):
    out.append('{"%s%s_%d",{%s},{%s}}' % (PRE, tag, k, ','.join(ids[f] for f in sorted(fs)), ','.join('"%s"' % c for c in sorted(cs))))
print('{' + ',\n'.join(out) + '}')
print('-- %d jobs, %d cells' % (len(out), sum(len(g[1]) for g in groups)), file=sys.stderr)
