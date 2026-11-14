"""preview3d_blend.py: renders a real-geometry landmark (geom3d triangles by material group) in Blender, back faces
culled like Roblox, each group in its Roblox colour (glass a little see-through).

    blender -b --factory-startup --python preview3d_blend.py -- <tris.json> <outdir> <views.json>
views.json: {name: [[cam x, y, z], [look x, y, z], lens_mm]} in model coords.
"""
import json
import math
import os
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
args = sys.argv[sys.argv.index("--") + 1:]
tris_path, outdir, views_path = args[0], args[1], args[2]
sys.modules.pop("landmark_glb3d", None)
import importlib.util  # noqa: E402
spec = importlib.util.spec_from_file_location("LG", os.path.join(os.path.dirname(os.path.abspath(__file__)), "landmark_glb3d.py"))
# landmark_glb3d imports glb.py (pure Python): fine inside Blender
LG = importlib.util.module_from_spec(spec)
spec.loader.exec_module(LG)

data = json.load(open(tris_path))
views = json.load(open(views_path))
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)
sc = bpy.context.scene
for grp, tris in data.items():
    verts, faces = [], []
    for t in tris:
        i0 = len(verts)
        verts.extend([tuple(p) for p in t])
        faces.append((i0, i0 + 1, i0 + 2))
    me = bpy.data.meshes.new(grp)
    me.from_pydata(verts, [], faces)
    me.update()
    mat_name, rgb, tr, rf, ds, sh = LG.GROUPS[grp]
    mat = bpy.data.materials.new("M_" + grp)
    mat.use_nodes = True
    b = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    lin = [(c / 255.0) ** 2.2 for c in rgb]
    b.inputs["Base Color"].default_value = (lin[0], lin[1], lin[2], 1)
    b.inputs["Roughness"].default_value = 0.25 if mat_name in ("Glass", "Metal") else 0.7
    if mat_name == "Metal":
        b.inputs["Metallic"].default_value = 0.6
    if mat_name == "Neon":
        b.inputs["Emission"].default_value = (lin[0], lin[1], lin[2], 1)
        b.inputs["Emission Strength"].default_value = 2.0
    if tr > 0:
        b.inputs["Alpha"].default_value = 1 - tr
        mat.blend_method = "BLEND"
    mat.use_backface_culling = not ds
    me.materials.append(mat)
    ob = bpy.data.objects.new(grp, me)
    sc.collection.objects.link(ob)
try:
    sc.render.engine = "BLENDER_EEVEE"
except TypeError:
    pass
sc.eevee.use_gtao = True
sc.eevee.use_ssr = True
w = bpy.data.worlds.new("W")
sc.world = w
w.use_nodes = True
bg = next(n for n in w.node_tree.nodes if n.type == "BACKGROUND")
bg.inputs[0].default_value = (0.5, 0.66, 0.88, 1)
bg.inputs[1].default_value = 1.0
ld = bpy.data.lights.new("sun", "SUN")
ld.energy = 3.2
sun = bpy.data.objects.new("sun", ld)
sun.rotation_euler = (math.radians(48), 0, math.radians(130))
sc.collection.objects.link(sun)
bpy.ops.mesh.primitive_plane_add(size=2000, location=(0, 0, -0.1))
gm = bpy.data.materials.new("ground")
gm.use_nodes = True
next(n for n in gm.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = (0.1, 0.1, 0.11, 1)
bpy.context.active_object.data.materials.append(gm)
cd = bpy.data.cameras.new("cam")
cam = bpy.data.objects.new("cam", cd)
sc.collection.objects.link(cam)
sc.camera = cam
sc.render.resolution_x, sc.render.resolution_y = 1280, 900
os.makedirs(outdir, exist_ok=True)
for name, (pos, look, lens) in views.items():
    cam.location = pos
    d = Vector(look) - Vector(pos)
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    cd.lens = lens
    cd.clip_start = 0.5
    cd.clip_end = 6000
    sc.render.filepath = os.path.join(outdir, name + ".png")
    bpy.ops.render.render(write_still=True)
print("rendered", list(views))
