"""ronin_cp9a_rejoin.py (a copy of toyoka_chaser_rejoin.py for the Ronin CP9A, 2026-11-14) -- in.blend out.blend [max_tris] [families]:
every loose piece of a part family whole in ONE part
(2026-11-14, after the Studio check).

In Play both rear doors showed rows of fine dark dashed lines from 1-3 m, the front doors none. finish_car.py had cut the paint
into Body_Paint_p1..p8 (under 17,000 triangles each) face by face, and the boundary between p7 and p8 ran through the rear
door's skin (its front 40 %): in Roblox each MeshPart's mesh is placed and scaled on its own, so an edge shared by two parts
never meets bit-exactly, pixels drop out along it and the dark door inside shows through in dashes. Blender draws it clean.

This welds the paint parts' corners by position (0.02 mm) into loose pieces and moves every piece that is split across parts
into the part that holds most of its faces (the backs step's reversed copies lie on their faces, so they go along), as long as
that part stays under max_tris (default 17,000; Roblox takes about 20,000). The faces keep their place, picture map, shading
normals and material (moved with Blender's own separate + join). Pieces too big to move are listed, not moved.

Families (4th argument, comma-separated part-name starts; default Body_Paint): each family is done on its own (a piece never
moves into another family's part).

    blender -b --python tools/logo_paint/ronin_cp9a_rejoin.py -- in.blend out.blend 17000 Body_Paint,Body_Cabin,Body_Trim [Body_Paint 18000]

Added for the Ronin CP9A (5th / 6th arguments): families to REPACK afterwards and their cap: every loose piece whole into as few
parts as fit under the cap (largest first), for models whose biggest pieces cannot be moved under max_tris (repack() below).
"""
import sys
from collections import defaultdict

import bmesh
import bpy
import numpy as np

a = sys.argv[sys.argv.index("--") + 1 :]
bpy.ops.wm.open_mainfile(filepath=a[0])
MAX = int(a[2]) if len(a) > 2 else 17000
FAMILIES = a[3].split(",") if len(a) > 3 else ["Body_Paint"]


def tris(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


def rejoin(parts):
    # ---- pieces across parts (corners welded by position)
    keys, faces = {}, []  # faces: (object index, face index, [key ids])
    for k, o in enumerate(parts):
        me = o.data
        co = np.empty(len(me.vertices) * 3)
        me.vertices.foreach_get("co", co)
        co = co.reshape(-1, 3)
        M = np.array(o.matrix_world)
        co = co @ M[:3, :3].T + M[:3, 3]
        K = [keys.setdefault(tuple(np.round(q / 2e-5).astype(np.int64)), len(keys)) for q in co]
        for p in me.polygons:
            faces.append((k, p.index, [K[v] for v in p.vertices]))
    par = list(range(len(keys)))


    def find(x):
        while par[x] != x:
            par[x] = par[par[x]]
            x = par[x]
        return x


    for _, _, ks in faces:
        r = find(ks[0])
        for q in ks[1:]:
            par[find(q)] = r
    piece = defaultdict(lambda: defaultdict(list))  # root -> object index -> face indices
    for k, fi, ks in faces:
        piece[find(ks[0])][k].append(fi)
    split = [(r, d) for r, d in piece.items() if len(d) > 1]
    print("REJOIN paint parts %s, pieces %d, split across parts %d" % ([o.name for o in parts], len(piece), len(split)))

    # ---- plan: each split piece into its biggest share's part
    load = {k: tris(o) for k, o in enumerate(parts)}
    moves = defaultdict(lambda: defaultdict(set))  # src -> dst -> faces
    for r, d in sorted(split, key=lambda rd: -sum(len(v) for v in rd[1].values())):
        n = {k: len(v) for k, v in d.items()}
        dst = max(n, key=lambda k: (n[k], -load[k]))
        extra = sum(v for k, v in n.items() if k != dst)
        if load[dst] + extra > MAX:
            print("REJOIN too big to move: piece of %d faces %s (into %s would make %d)" % (sum(n.values()), {parts[k].name: v for k, v in n.items()}, parts[dst].name, load[dst] + extra))
            continue
        for k, v in d.items():
            if k != dst:
                moves[k][dst].update(v)
                load[dst] += len(v)
                load[k] -= len(v)
        print("REJOIN piece of %d faces %s -> %s" % (sum(n.values()), {parts[k].name: v for k, v in n.items()}, parts[dst].name))


    # ---- move (Blender's separate + join keep the picture map, shading normals and material); each face carries its target in a
    #      face attribute, so the indices may change between moves
    for k, o in enumerate(parts):
        at = o.data.attributes.new("rejoin_dst", "INT", "FACE")
        vals = np.zeros(len(o.data.polygons), np.int32)
        for dst, idx in moves.get(k, {}).items():
            vals[list(idx)] = dst + 1
        at.data.foreach_set("value", vals)


    def move(src, dst, tag):
        me = src.data
        vals = np.zeros(len(me.polygons), np.int32)
        me.attributes["rejoin_dst"].data.foreach_get("value", vals)
        idx = set(np.flatnonzero(vals == tag).tolist())
        if not idx:
            return 0
        bpy.ops.object.select_all(action="DESELECT")
        bpy.context.view_layer.objects.active = src
        src.select_set(True)
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.context.tool_settings.mesh_select_mode = (False, False, True)
        bm = bmesh.from_edit_mesh(me)
        bm.faces.ensure_lookup_table()
        for v in bm.verts:
            v.select_set(False)
        for f in bm.faces:
            f.select_set(f.index in idx)
        bm.select_flush_mode()
        bmesh.update_edit_mesh(me)
        bpy.ops.mesh.separate(type="SELECTED")
        bpy.ops.object.mode_set(mode="OBJECT")
        new = [o for o in bpy.context.selected_objects if o is not src]
        for o in new:
            with bpy.context.temp_override(active_object=dst, object=dst, selected_objects=[dst, o], selected_editable_objects=[dst, o]):
                bpy.ops.object.join()
        bm = bmesh.new()  # (separate leaves corners no face uses: drop them)
        bm.from_mesh(src.data)
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
        bm.to_mesh(src.data)
        bm.free()
        return len(idx)


    for k, dd in moves.items():
        for dst in dd:
            before = (tris(parts[k]), tris(parts[dst]))
            n = move(parts[k], parts[dst], dst + 1)
            print("REJOIN moved %d faces %s -> %s (tris %d/%d -> %d/%d)" % (n, parts[k].name, parts[dst].name, before[0], before[1], tris(parts[k]), tris(parts[dst])))
    for o in parts:
        if "rejoin_dst" in o.data.attributes:
            o.data.attributes.remove(o.data.attributes["rejoin_dst"])
    for o in parts:
        print("REJOIN part %s tris %d" % (o.name, tris(o)))


def repack(fam, cap):
    """(the Ronin CP9A, 2026-11-14) when pieces too big to move stay split (this model's main body shell is one 17,735-face piece
    over four parts, the front bumper and the bonnet over two), the family's parts are packed afresh: every loose piece (corners
    welded by position) whole into one of as few parts as fit under "cap" triangles (largest first), named <fam>_p1.._pN again.
    The faces are only moved between objects (join, then separate by a face attribute): place, picture map, normals unchanged."""
    parts = sorted([o for o in bpy.data.objects if o.type == "MESH" and o.name.startswith(fam + "_p")], key=lambda o: o.name)
    if len(parts) < 2:
        return
    mat_parent = parts[0].parent
    bpy.ops.object.select_all(action="DESELECT")
    for o in parts:
        o.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    me = ob.data
    co = np.empty(len(me.vertices) * 3)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    M = np.array(ob.matrix_world)
    co = co @ M[:3, :3].T + M[:3, 3]
    K = np.unique(np.round(co / 2e-5).astype(np.int64), axis=0, return_inverse=True)[1].reshape(-1)
    par = list(range(int(K.max()) + 1))

    def find(x):
        while par[x] != x:
            par[x] = par[par[x]]
            x = par[x]
        return x

    for p in me.polygons:
        r = find(K[p.vertices[0]])
        for v in p.vertices[1:]:
            par[find(K[v])] = r
    root = np.array([find(K[p.vertices[0]]) for p in me.polygons])
    ntri = np.array([len(p.vertices) - 2 for p in me.polygons])
    sizes = defaultdict(int)
    for r_, t_ in zip(root, ntri):
        sizes[r_] += int(t_)
    bins = []  # [load, [roots]]
    for r_ in sorted(sizes, key=lambda q: -sizes[q]):
        for b in bins:
            if b[0] + sizes[r_] <= cap:
                b[0] += sizes[r_]
                b[1].append(r_)
                break
        else:
            bins.append([sizes[r_], [r_]])
    where = {r_: i for i, b in enumerate(bins) for r_ in b[1]}
    print("REPACK %s: %d pieces into %d parts under %d: %s" % (fam, len(sizes), len(bins), cap, [b[0] for b in bins]))
    at = me.attributes.new("repack_bin", "INT", "FACE")
    at.data.foreach_set("value", np.array([where[r_] for r_ in root], np.int32))
    for i in range(len(bins) - 1, 0, -1):
        vals = np.zeros(len(me.polygons), np.int32)
        me.attributes["repack_bin"].data.foreach_get("value", vals)
        bpy.ops.object.select_all(action="DESELECT")
        bpy.context.view_layer.objects.active = ob
        ob.select_set(True)
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.context.tool_settings.mesh_select_mode = (False, False, True)
        bm = bmesh.from_edit_mesh(me)
        bm.faces.ensure_lookup_table()
        for v in bm.verts:
            v.select_set(False)
        for f in bm.faces:
            f.select_set(bool(vals[f.index] == i))
        bm.select_flush_mode()
        bmesh.update_edit_mesh(me)
        bpy.ops.mesh.separate(type="SELECTED")
        bpy.ops.object.mode_set(mode="OBJECT")
        new = [o for o in bpy.context.selected_objects if o is not ob]
        for o in new:
            o.name = o.data.name = "%s_p%d" % (fam, i + 1)
            if "repack_bin" in o.data.attributes:
                o.data.attributes.remove(o.data.attributes["repack_bin"])
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(me)
    bm.free()
    me.attributes.remove(me.attributes["repack_bin"])
    ob.name = me.name = "%s_p1" % fam
    for o in sorted([o for o in bpy.data.objects if o.type == "MESH" and o.name.startswith(fam + "_p")], key=lambda o: o.name):
        print("REPACK part %s tris %d" % (o.name, tris(o)))


for fam in FAMILIES:
    rejoin(sorted([o for o in bpy.data.objects if o.type == "MESH" and o.name.startswith(fam + "_p")], key=lambda o: o.name))
REPACK = a[4].split(",") if len(a) > 4 and a[4] else []
for fam in REPACK:
    repack(fam, int(a[5]) if len(a) > 5 else 18000)
bpy.ops.wm.save_as_mainfile(filepath=a[1])
