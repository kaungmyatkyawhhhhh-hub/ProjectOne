"""toyoka_supra_mk4_rejoin.py -- in.blend out.blend [max_tris] [families] : the 1994 Supra's split parts packed again so that every
loose piece is whole in ONE part (2026-11-14, after the Studio check).

In Play the left door showed rows of fine dark dots from 1-3 m. finish_car.py had cut the big parts into _p1.._pN (under 17,000
triangles each) by face middles along the longest axis, so the cut between Body_Paint_p1 and p2 ran across both doors (y -0.29
to -0.21) and the cabin / engine / trim cuts ran through their panels too: in Roblox each MeshPart's mesh is placed and scaled
on its own, an edge shared by two parts never meets bit-exactly, and pixels drop out along it (the Chaser's finding,
tools/logo_paint/toyoka_chaser_rejoin.py). That script moves each split piece into the part holding most of it; on this car
the paint shell is ONE welded piece of 17,364 triangles (and the cabin one of 16,021), too big to move into a part that already
holds 15,500, so here each family is packed afresh instead:

  * the family's parts are joined, corners welded by position (0.02 mm) into loose pieces,
  * the pieces go whole into as many parts as before (more only if needed), biggest first, each into the emptiest part, every
    part under max_tris (default 18,000: the paint shell needs 17,364; Roblox takes 20,000 a mesh),
  * the parts are separated again with Blender's own separate (place, picture map, shading normals and material stay) and keep
    the old names (Body_Paint_p1, _p2 ...), so Studio swaps them by name.

A piece bigger than max_tris is left in its own part and reported (none on this car at 18,000).

    blender -b --python tools/logo_paint/toyoka_supra_mk4_rejoin.py -- in.blend out.blend 18000 Body_Paint,Body_Cabin,Body_Engine,Body_Trim
"""
import sys
from collections import defaultdict

import bmesh
import bpy
import numpy as np

a = sys.argv[sys.argv.index("--") + 1 :]
bpy.ops.wm.open_mainfile(filepath=a[0])
MAX = int(a[2]) if len(a) > 2 else 18000
FAMILIES = a[3].split(",") if len(a) > 3 else ["Body_Paint"]


def tris(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


def repack(fam):
    parts = sorted([o for o in bpy.data.objects if o.type == "MESH" and o.name.startswith(fam + "_p")], key=lambda o: o.name)
    if len(parts) < 2:
        return
    names = [o.name for o in parts]
    before = {o.name: tris(o) for o in parts}
    bpy.ops.object.mode_set(mode="OBJECT") if bpy.context.object and bpy.context.object.mode != "OBJECT" else None
    bpy.ops.object.select_all(action="DESELECT")
    for o in parts:
        o.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    with bpy.context.temp_override(active_object=parts[0], object=parts[0], selected_objects=parts, selected_editable_objects=parts):
        bpy.ops.object.join()
    o = parts[0]
    me = o.data
    # loose pieces by corner position
    co = np.empty(len(me.vertices) * 3)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    M = np.array(o.matrix_world)
    co = co @ M[:3, :3].T + M[:3, 3]
    key = np.unique(np.round(co / 2e-5).astype(np.int64), axis=0, return_inverse=True)[1].reshape(-1)
    par = np.arange(key.max() + 1)

    def find(x):
        while par[x] != x:
            par[x] = par[par[x]]
            x = par[x]
        return x

    for p in me.polygons:
        ks = [key[v] for v in p.vertices]
        r = find(ks[0])
        for q in ks[1:]:
            rq = find(q)
            if rq != r:
                par[rq] = r
    root = np.array([find(key[p.vertices[0]]) for p in me.polygons])
    tc = np.array([len(p.vertices) - 2 for p in me.polygons])
    size = defaultdict(int)
    for r, t in zip(root, tc):
        size[r] += int(t)
    # pack: biggest first, into the emptiest part that takes it
    n = len(names)
    load = [0] * n
    where = {}
    for r, s in sorted(size.items(), key=lambda kv: -kv[1]):
        fits = [b for b in range(n) if load[b] + s <= MAX]
        if not fits:
            if s > MAX:
                print("REPACK %s: a piece of %d triangles is over %d: own part" % (fam, s, MAX))
            n += 1
            load.append(0)
            fits = [n - 1]
        b = min(fits, key=lambda b: load[b])
        where[r] = b
        load[b] += s
    binv = np.array([where[r] for r in root], dtype=np.int32)
    at = me.attributes.new("_bin", "INT", "FACE")
    at.data.foreach_set("value", binv)
    print("REPACK %s: %d pieces (biggest %d tris), %d parts -> loads %s" % (fam, len(size), max(size.values()), n, load))
    # separate bins 1..n-1 (bin 0 stays in o)
    out = [o]
    for b in range(1, n):
        bpy.ops.object.select_all(action="DESELECT")
        bpy.context.view_layer.objects.active = o
        o.select_set(True)
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.context.tool_settings.mesh_select_mode = (False, False, True)
        bm = bmesh.from_edit_mesh(o.data)
        lay = bm.faces.layers.int.get("_bin")
        for v in bm.verts:
            v.select_set(False)
        for f in bm.faces:
            f.select_set(f[lay] == b)
        bm.select_flush_mode()
        bmesh.update_edit_mesh(o.data)
        bpy.ops.mesh.separate(type="SELECTED")
        bpy.ops.object.mode_set(mode="OBJECT")
        new = [x for x in bpy.context.selected_objects if x is not o]
        out.append(new[0])
    for i, x in enumerate(out):
        nm = names[i] if i < len(names) else "%s_p%d" % (fam, i + 1)
        x.name = nm
        x.data.name = nm
        if "_bin" in x.data.attributes:
            x.data.attributes.remove(x.data.attributes["_bin"])
        bm = bmesh.new()  # (separate leaves corners no face uses)
        bm.from_mesh(x.data)
        loose = [v for v in bm.verts if not v.link_faces]
        if loose:
            bmesh.ops.delete(bm, geom=loose, context="VERTS")
        bm.to_mesh(x.data)
        bm.free()
    after = {x.name: tris(x) for x in out}
    print("REPACK %s tris before %s (%d) after %s (%d)" % (fam, before, sum(before.values()), after, sum(after.values())))


for fam in FAMILIES:
    repack(fam)
bpy.ops.wm.save_as_mainfile(filepath=a[1])
