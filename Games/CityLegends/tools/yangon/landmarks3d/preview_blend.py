"""preview_blend.py: Workbench renders of a solid3d model (tris by group, model metres), back faces culled like Roblox.

    blender -b --factory-startup --python preview_blend.py -- <tris.json> <outdir> <views.json>
tris.json: {"look": {grp: [r, g, b]}, "tris": {grp: [[[x,y,z]x3], ...]}}; views.json: {name: [[cam], [look], lens_mm]}.
"""
import json
import os
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
data = json.load(open(args[0]))
outdir = args[1]
views = json.load(open(args[2]))
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)
sc = bpy.context.scene
for grp, tris in data["tris"].items():
    verts, faces = [], []
    for t in tris:
        i0 = len(verts)
        verts.extend([tuple(p) for p in t])
        faces.append((i0, i0 + 1, i0 + 2))
    me = bpy.data.meshes.new(grp)
    me.from_pydata(verts, [], faces)
    me.update()
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-4)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    try:
        me.use_auto_smooth = True
        me.auto_smooth_angle = 0.8
    except Exception:
        pass
    mat = bpy.data.materials.new("M_" + grp)
    r, g, b = data["look"][grp]
    mat.diffuse_color = (r / 255.0, g / 255.0, b / 255.0, 1.0)
    mat.use_backface_culling = True
    me.materials.append(mat)
    ob = bpy.data.objects.new(grp, me)
    sc.collection.objects.link(ob)
sc.render.engine = "BLENDER_WORKBENCH"
sh = sc.display.shading
sh.light = "STUDIO"
sh.color_type = "MATERIAL"
sh.show_backface_culling = True
sh.show_shadows = True
sh.show_cavity = False
sc.render.resolution_x = 1280
sc.render.resolution_y = 800
sc.world = bpy.data.worlds.new("w") if not sc.world else sc.world
cam_data = bpy.data.cameras.new("cam")
cam_data.clip_end = 2000
cam = bpy.data.objects.new("cam", cam_data)
sc.collection.objects.link(cam)
sc.camera = cam
os.makedirs(outdir, exist_ok=True)
for name, (pos, look, lens) in views.items():
    cam.location = Vector(pos)
    d = Vector(look) - Vector(pos)
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    cam_data.lens = lens
    sc.render.filepath = os.path.join(outdir, name + ".png")
    bpy.ops.render.render(write_still=True)
print("PREVIEW_DONE")
