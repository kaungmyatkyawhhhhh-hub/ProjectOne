"""The owner's trailer (imports/importing cars/trailer.glb: "Flatbed Baked" by 3DE_Study, CC BY 4.0) for the game: the body
and four wheel sets, the orange placard taken off, origin on the ground between the axles, rear at +Y (it comes into
Studio with the rear at +Z). Then Trailer picture maps: colour, normal, roughness, metal at 768 px.

    blender -b --factory-startup --python tools/trailer_export.py -- <out dir>
"""
import os
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

OUT = sys.argv[sys.argv.index("--") + 1]
SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "imports", "importing cars", "trailer.glb")
AXLE_Y = 12.6  # the middle of the two axles
MID_X = -0.02

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
names = {"lp_flatbed_lp_flatbed_0": "Body", "flatbed_wheels_front_L_lp_flatbed_wheels_0": "Wheel_FL", "flatbed_wheels_front_R_lp_flatbed_wheels_0": "Wheel_FR", "flatbed_wheels_rear_L_lp_flatbed_wheels_0": "Wheel_RL", "flatbed_wheels_rear_R_lp_flatbed_wheels_0": "Wheel_RR"}
keep = []
source = list(bpy.data.objects)
for o in source:
    if o.type != "MESH":
        continue
    mw = o.matrix_world.copy()
    me = o.data.copy()
    me.transform(Matrix.Translation(Vector((-MID_X, -AXLE_Y, 0))) @ mw)
    if o.name.startswith("lp_flatbed"):
        bm = bmesh.new()
        bm.from_mesh(me)
        bm.faces.ensure_lookup_table()
        kill = []
        seen = set()
        for f0 in bm.faces:
            if f0.index in seen:
                continue
            stack, faces = [f0], []
            seen.add(f0.index)
            while stack:
                f = stack.pop()
                faces.append(f)
                for e in f.edges:
                    for g in e.link_faces:
                        if g.index not in seen:
                            seen.add(g.index)
                            stack.append(g)
            ps = np.array([v.co[:] for f in faces for v in f.verts])
            size = ps.max(0) - ps.min(0)
            # the placard: a thin flat diamond hanging from each side
            if size[0] < 0.03 and 0.7 < size[1] < 0.95 and 0.7 < size[2] < 0.9 and abs(abs(ps[:, 0].mean()) - 2.38) < 0.05:
                kill += faces
        print("placard faces", len(kill))
        bmesh.ops.delete(bm, geom=kill, context="FACES")
        bm.to_mesh(me)
        bm.free()
    n = bpy.data.objects.new(names[o.name], me)
    keep.append((n, me))
for o in source:
    bpy.data.objects.remove(o)
sc = bpy.context.scene
holder = bpy.data.objects.new("hauler", None)
sc.collection.objects.link(holder)
for n, _ in keep:
    sc.collection.objects.link(n)
    n.parent = holder
    n.data.update()
    print(n.name, len(n.data.polygons), [round(x, 3) for x in n.dimensions])
imgs = {im.name: im for im in bpy.data.images}
bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, "trailer.fbx"), apply_unit_scale=True, apply_scale_options="FBX_SCALE_ALL", axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", path_mode="STRIP")
for prefix, (c, mr, nrm) in {"body": ("Image_0", "Image_1", "Image_2"), "wheel": ("Image_3", "Image_4", "Image_5")}.items():
    def arr(name):
        im = imgs[name]
        w, h = im.size
        return np.array(im.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]
    np.save(os.path.join(OUT, prefix + "_c.npy"), (arr(c)[:, :, :3] * 255).astype(np.uint8))
    a = arr(mr)
    np.save(os.path.join(OUT, prefix + "_r.npy"), (a[:, :, 1] * 255).astype(np.uint8))
    np.save(os.path.join(OUT, prefix + "_m.npy"), (a[:, :, 2] * 255).astype(np.uint8))
    np.save(os.path.join(OUT, prefix + "_n.npy"), (arr(nrm)[:, :, :3] * 255).astype(np.uint8))
print("done")
