"""Re-bake whole road cells from the build that is in the place, with the 25 Nov bake fixes (exact district-edge clip,
gap fill), for a mesh-only swap (25 Nov 2026, road bug sweep).

    python roadbugs_rebake.py plan [counts.json] [kinds]   -> roadbugs_25nov/rebake_plan.json (owner tag -> cells)
    python roadbugs_rebake.py bake <tag>                   -> roads05_<tag>_RBUG/ (collect with pad + bake R05_ONLY),
                                                              glbs in imports/sync/RBUG_<tag>_glb
Owner of a cell = the tag whose glbs the place's meshes of that cell came from (match.json). Cells whose meshes come
from two bakes, from a laptop bake with no pages here (P8) or from an unknown tag are listed as skipped.
The data (roads.json, paint.json, subset.json) is copied from the owner's folder unchanged: the meshes keep their build.
"""
import collections, json, os, shutil, subprocess, sys

sys.path.insert(0, os.path.dirname(__file__))
from roadbugs_index import OUT, ROOT

B = os.path.join(ROOT, 'build', 'city_1to1')
DIR2TAG = {
    'roads05_RB12/glb': 'RB12', 'roads05_RB3/glb': 'RB3', 'roads05_RB3v/glb': 'RB3v', 'roads05_RB4/glb': 'RB4',
    'roads05_RB4M/glb': 'RB4M', 'roads05_RB6/glb': 'RB6', 'roads05_RB7/glb': 'RB7', 'roads05_RB9/glb': 'RB9',
    'roads05_RBM/glb': 'RBM', 'DJ3x_glb': 'RB3x', 'DJRB10_glb': 'RB10', 'DJRB11_glb': 'RB11', 'DJRB3_glb': 'RB3',
    'DJRB5_glb': 'RB5', 'DJRB6_glb': 'RB6', 'DJRB6s_glb': 'RB6s', 'RB11_glb': 'RB11', 'RB12P_glb': 'RB12P',
    'RB3rJ_glb': 'RB3r', 'RB4h_glb': 'RB4h', 'RB6sS_glb': 'RB6s', 'RB7aS_glb': 'RB7a', 'RB7sS_glb': 'RB7s',
    'RB8sJ_glb': 'RB8s', 'ovl24_glb': 'RB3o', 'rb10_glb': 'RB10', 'rb5_glb': 'RB5', 'rb9_glb': 'RB9',
    'rebuild_P1_glb': 'RB12', 'rebuild_P2_glb': 'RB12', 'rebuild_P3_glb': 'RB3', 'rebuild_P4F_glb': 'RB4F',
    'rebuild_P4_glb': 'RB4', 'rebuild_P6_glb': 'RB6', 'rebuild_P7M_glb': 'RB7M', 'rebuild_P7_glb': 'RB7',
    'RBUG_RB5c_glb': 'RB5',
}


def owners():
    m = json.load(open(os.path.join(OUT, 'match.json')))['match']
    by = collections.defaultdict(set)
    for v in m.values():
        g = v['glb'].replace(chr(92), '/')
        if g.startswith('p8:'):
            by[v['cell']].add('P8_laptop')
            continue
        d = '/'.join(g.split('/')[-3:-1]) if '/roads05_' in g else g.split('/')[-2]
        by[v['cell']].add(DIR2TAG.get(d, '?' + d))
    return by


def plan(counts_file, kinds):
    c = json.load(open(counts_file))['cells']
    own = owners()
    tags, skip = collections.defaultdict(list), {}
    for cell, v in sorted(c.items()):
        if not any(v.get(k, 0) for k in kinds):
            continue
        o = own.get(cell, set())
        if len(o) != 1 or next(iter(o)).startswith('?') or 'P8_laptop' in o:
            skip[cell] = sorted(o)
            continue
        t = next(iter(o))
        if not os.path.isdir(os.path.join(B, 'roads05_' + t, 'pages')):
            skip[cell] = [t + ' (no pages)']
            continue
        tags[t].append(cell)
    json.dump(dict(tags=tags, skipped=skip, kinds=kinds), open(os.path.join(OUT, 'rebake_plan.json'), 'w'), indent=1)
    print(json.dumps(dict(tags={k: len(v) for k, v in tags.items()}, skipped=skip), indent=1))


def bake(tag):
    p = json.load(open(os.path.join(OUT, 'rebake_plan.json')))
    cells = p['tags'][tag]
    src = os.path.join(B, 'roads05_' + tag)
    dst = os.path.join(B, 'roads05_' + tag + '_RBUG')
    os.makedirs(dst, exist_ok=True)
    for f in ('roads.json', 'paint.json', 'subset.json'):
        if os.path.exists(os.path.join(src, f)):
            shutil.copy(os.path.join(src, f), dst)
    env = dict(os.environ, YANGON_SCALE='1to1', R05_ONLY=','.join(cells),
               R05_GLB_DIR=os.path.join(ROOT, 'imports', 'sync', 'RBUG_%s_glb' % tag))
    here = os.path.dirname(os.path.abspath(__file__))
    with open(os.path.join(dst, 'rbug.log'), 'w') as log:
        subprocess.run([sys.executable, 'roads05_bake.py', tag + '_RBUG', 'collect', os.path.join(src, 'pages')], cwd=here,
                       env=env, stdout=log, stderr=subprocess.STDOUT, check=True)
        subprocess.run([sys.executable, 'roads05_bake.py', tag + '_RBUG', 'bake'], cwd=here, env=env, stdout=log,
                       stderr=subprocess.STDOUT, check=True)
    print(tag, 'baked', len(cells), 'cells ->', env['R05_GLB_DIR'])


if __name__ == '__main__':
    if sys.argv[1] == 'plan':
        plan(sys.argv[2] if len(sys.argv) > 2 else os.path.join(OUT, 'counts_before.json'),
             sys.argv[3].split(',') if len(sys.argv) > 3 else ['spike', 'gap'])
    elif sys.argv[1] == 'bake':
        bake(sys.argv[2])
