"""
Road meshes, step 3: writes the meshes from build.py into FBX files for Open Cloud (each under 20 MB).
Each object's name carries its true box, in hundredths of a stud: Studio's importer scales and centres every
mesh, and Place.luau puts it back from the name.

run:  blender.exe -b --factory-startup --python tools/road_mesh/export_fbx.py -- <work folder> <out folder>
"""
import os
import pickle
import sys

import bpy

work, out = sys.argv[sys.argv.index("--") + 1 : sys.argv.index("--") + 3]
os.makedirs(out, exist_ok=True)
meshes = pickle.load(open(os.path.join(work, "meshes.pkl"), "rb"))
OX, OY, OZ = 14000.0, 100.0, 0.0
BATCH = 90000  # triangles a file
MESHES = 120  # meshes a file: a Model of 150 or more fails with "Failed to load package asset"


def code(v):
    n = int(round(v * 100))
    return ("n" + str(-n)) if n < 0 else str(n)


def to_b(p):
    return (p[0] - OX, -(p[2] - OZ), p[1] - OY)


batches = [[]]
tris = 0
for m in sorted(meshes, key=lambda q: (q[1], q[0])):
    if (tris + len(m[4]) > BATCH or len(batches[-1]) >= MESHES) and batches[-1]:
        batches.append([])
        tris = 0
    batches[-1].append(m)
    tris += len(m[4])

for bi, batch in enumerate(batches):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for i, (kind, cell, v, uv, f) in enumerate(batch):
        xs = [p[0] for p in v]
        ys = [p[1] for p in v]
        zs = [p[2] for p in v]
        c = ((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, (min(zs) + max(zs)) / 2)
        s = (max(xs) - min(xs), max(max(ys) - min(ys), 0.05), max(zs) - min(zs))
        name = "_".join([kind, str(bi) + "x" + str(i), code(c[0]), code(c[1]), code(c[2]), code(s[0]), code(s[1]), code(s[2])])
        me = bpy.data.meshes.new(name)
        me.from_pydata([to_b(p) for p in v], [], f)
        layer = me.uv_layers.new(name="UVMap")
        loops = [0] * len(me.loops)
        me.loops.foreach_get("vertex_index", loops)
        flat = []
        for li in loops:
            flat += uv[li]
        layer.data.foreach_set("uv", flat)
        me.polygons.foreach_set("use_smooth", [True] * len(me.polygons))
        me.update()
        ob = bpy.data.objects.new(name, me)
        bpy.context.collection.objects.link(ob)
    for ob in bpy.context.scene.objects:
        ob.select_set(True)
    path = os.path.join(out, f"roads_{bi}.fbx")
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, object_types={"MESH"}, global_scale=1.0, apply_unit_scale=True, bake_space_transform=False, axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", use_mesh_modifiers=False)
    print("FILE", path, len(batch), "meshes", sum(len(m[4]) for m in batch), "tris", os.path.getsize(path) // 1024, "KB")
