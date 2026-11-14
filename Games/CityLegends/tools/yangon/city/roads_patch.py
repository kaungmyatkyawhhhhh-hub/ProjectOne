"""Whole-Yangon map (14 Nov 2026): after a roads.py re-run, the mesh cells that changed, as a small patch pack.

    python roads.py <tag> --jobs 6 --dump        (writes build/city/roads_<tag>_meshes.pkl and a new manifest)
    python roads_patch.py <tag> <old manifest.json>

Compares the new manifest's mesh names (KIND_CELL_box: a changed surface changes its box code) with the old one's, per
256-stud cell, and writes every mesh of the changed cells (all kinds) to build/city/roads_<tag>patch/ (+ manifest.json with
"cells": the cell ids to clear in Studio before placing: YangonRoadMeshes Cell_<cell> models) and copies the .glb files to
imports/sync/ygn_roads_<tag>patch/ for Open Cloud. The full new set in build/city/roads_<tag>/ stays the reference.
"""
import json, os, pickle, re, shutil, sys

import geo
import roads


def cell_of(name):
    return re.sub(r's\d+$', '', name.split('_')[1])


def main(tag, old_manifest):
    out = os.path.join(geo.BUILD, 'city')
    om = json.load(open(old_manifest))
    nm = json.load(open(os.path.join(out, 'roads_%s' % tag, 'manifest.json')))
    on = {m['name'] for f in om['files'] for m in f['meshes']}
    nn = {m['name'] for f in nm['files'] for m in f['meshes']}
    cells = sorted({cell_of(n) for n in on ^ nn})
    meshes = pickle.load(open(os.path.join(out, 'roads_%s_meshes.pkl' % tag), 'rb'))['meshes']
    keep = {k: v for k, v in meshes.items() if roads.cell_id(k[1], k[2]) in cells}
    man = roads.write_meshes(keep, tag + 'patch')
    man['cells'] = cells
    json.dump(man, open(os.path.join(out, 'roads_%spatch' % tag, 'manifest.json'), 'w'), indent=1)
    dst = os.path.join(geo.ROOT, 'imports', 'sync', 'ygn_roads_%spatch' % tag)
    os.makedirs(dst, exist_ok=True)
    for f in os.listdir(dst):
        os.remove(os.path.join(dst, f))
    for f in man['files']:
        shutil.copy(os.path.join(out, 'roads_%spatch' % tag, f['glb']), dst)
    print('%d cells changed: %d meshes in %d files -> %s' % (len(cells), man['meshes'], len(man['files']), dst))
    print('cells:', ' '.join(cells))


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    main(sys.argv[1], sys.argv[2])
