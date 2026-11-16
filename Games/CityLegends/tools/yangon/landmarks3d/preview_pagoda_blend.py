"""preview_pagoda_blend.py: Blender (headless) check renders of a pagoda scene dump (pagoda_lib.dump_scene), back faces
culled like Roblox unless the group is double-sided.

    blender -b --factory-startup --python preview_pagoda_blend.py -- <scene.json> <outdir> <views.json>
views.json: {name: [[cam x, y, z], [look x, y, z], lens_mm]} in site metres (x east, y north, z up).
"""
import json, math, os, sys
import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
data = json.load(open(args[0]))
outdir, views = args[1], json.load(open(args[2]))
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)
sc = bpy.context.scene
for grp, d in data.items():
    verts, faces = [], []
    for t in d["tris"]:
        i0 = len(verts)
        verts.extend([tuple(p) for p in t])
        faces.append((i0, i0 + 1, i0 + 2))
    me = bpy.data.meshes.new(grp)
    me.from_pydata(verts, [], faces)
    me.update()
    mat = bpy.data.materials.new("M_" + grp)
    mat.use_nodes = True
    b = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    rgb = d["rgb"]
    if d["mat"] == "Metal" and d.get("variant") == "YgnGoldLeaf":
        rgb = (232, 196, 110)
    lin = [(c / 255.0) ** 2.2 for c in rgb]
    b.inputs["Base Color"].default_value = (lin[0], lin[1], lin[2], 1)
    b.inputs["Roughness"].default_value = 0.3 if d["mat"] in ("Glass", "Metal", "Foil") else 0.7
    if d["mat"] == "Metal":
        b.inputs["Metallic"].default_value = 0.7
    if d["tr"] > 0:
        b.inputs["Alpha"].default_value = 1 - d["tr"]
        mat.blend_method = "BLEND"
    mat.use_backface_culling = not d["ds"]
    me.materials.append(mat)
    ob = bpy.data.objects.new(grp, me)
    sc.collection.objects.link(ob)
try:
    sc.render.engine = "BLENDER_EEVEE"
except TypeError:
    pass
sc.eevee.use_gtao = True
w = bpy.data.worlds.new("W")
sc.world = w
w.use_nodes = True
bg = next(n for n in w.node_tree.nodes if n.type == "BACKGROUND")
bg.inputs[0].default_value = (0.45, 0.62, 0.9, 1)
bg.inputs[1].default_value = 1.0
ld = bpy.data.lights.new("sun", "SUN")
ld.energy = 3.5
sun = bpy.data.objects.new("sun", ld)
sun.rotation_euler = (math.radians(40), 0, math.radians(150))
sc.collection.objects.link(sun)
bpy.ops.mesh.primitive_plane_add(size=3000, location=(0, 0, -0.02))
gm = bpy.data.materials.new("ground")
gm.use_nodes = True
next(n for n in gm.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = (0.12, 0.12, 0.13, 1)
bpy.context.active_object.data.materials.append(gm)
cd = bpy.data.cameras.new("cam")
cam = bpy.data.objects.new("cam", cd)
sc.collection.objects.link(cam)
sc.camera = cam
sc.render.resolution_x, sc.render.resolution_y = 1100, 1000
os.makedirs(outdir, exist_ok=True)
for name, (pos, look, lens) in views.items():
    cam.location = pos
    cam.rotation_euler = (Vector(look) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
    cd.lens = lens
    cd.clip_start = 0.1
    cd.clip_end = 3000
    sc.render.filepath = os.path.join(outdir, name + ".png")
    bpy.ops.render.render(write_still=True)
print("rendered", list(views))
