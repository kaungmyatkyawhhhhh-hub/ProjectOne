"""3/4 before/after previews of the hub props, same camera and light for both.
blender --background --factory-startup --python preview_compare.py -- <v1 folder> <v2 folder> <out folder> [names...]
Writes "<Name> before.png", "<Name> after.png" and "<Name> compare.png" (side by side).
"""
import glob
import os
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
V1, V2, OUT = args[0], args[1], args[2]
ONLY = set(args[3:])
os.makedirs(OUT, exist_ok=True)
RES = 640


def render(blend, out_png):
    bpy.ops.wm.open_mainfile(filepath=blend)
    scene = bpy.context.scene
    obj = [o for o in scene.objects if o.type == "MESH"][0]
    pts = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    center = sum(pts, Vector()) / 8
    radius = max((p - center).length for p in pts)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    scene.collection.objects.link(cam)
    cam.data.lens = 50
    d = radius * 2.9
    # 3/4 view from the front-right, a little above (front = +Y in design space)
    cam.location = center + Vector((0.72, 0.95, 0.5)).normalized() * d
    cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    scene.render.engine = "BLENDER_WORKBENCH"
    sh = scene.display.shading
    sh.light = "STUDIO"
    sh.color_type = "VERTEX"
    sh.show_shadows = True
    sh.shadow_intensity = 0.35
    sh.show_cavity = False
    sh.show_specular_highlight = True
    if not scene.world:
        scene.world = bpy.data.worlds.new("w")
    scene.world.color = (0.32, 0.36, 0.44)
    scene.render.resolution_x = RES
    scene.render.resolution_y = RES
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "Standard"
    scene.render.filepath = out_png
    bpy.ops.render.render(write_still=True)


def compose(a_png, b_png, out_png):
    import numpy as np
    a = bpy.data.images.load(a_png)
    b = bpy.data.images.load(b_png)
    w, h = a.size
    pa = np.array(a.pixels[:]).reshape(h, w, 4)
    pb = np.array(b.pixels[:]).reshape(h, w, 4)
    gap = np.ones((h, 8, 4)) * np.array([0.04, 0.05, 0.07, 1.0])
    full = np.concatenate([pa, gap, pb], axis=1)
    img = bpy.data.images.new("compare", width=w * 2 + 8, height=h)
    img.pixels = full.flatten().tolist()
    img.filepath_raw = out_png
    img.file_format = "PNG"
    img.save()


for blend in sorted(glob.glob(os.path.join(V2, "*.blend"))):
    name = os.path.splitext(os.path.basename(blend))[0]
    if ONLY and name not in ONLY:
        continue
    before = os.path.join(OUT, f"{name} before.png")
    after = os.path.join(OUT, f"{name} after.png")
    render(os.path.join(V1, name + ".blend"), before)
    render(blend, after)
    compose(before, after, os.path.join(OUT, f"{name} compare.png"))
    print("[preview]", name)
