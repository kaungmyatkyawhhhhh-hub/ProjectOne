"""Render a quick preview PNG of every .blend in a folder (vertex colours, flat studio light).
blender --background --factory-startup --python preview.py -- <folder>
"""
import glob
import math
import os
import sys

import bpy
from mathutils import Vector

FOLDER = sys.argv[sys.argv.index("--") + 1]
OUT = os.path.join(FOLDER, "previews")
os.makedirs(OUT, exist_ok=True)

for path in sorted(glob.glob(os.path.join(FOLDER, "*.blend"))):
    bpy.ops.wm.open_mainfile(filepath=path)
    scene = bpy.context.scene
    objs = [o for o in scene.objects if o.type == "MESH"]
    if not objs:
        continue
    obj = objs[0]
    pts = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    center = sum(pts, Vector()) / 8
    size = max((p - center).length for p in pts)
    cam_data = bpy.data.cameras.new("cam")
    cam = bpy.data.objects.new("cam", cam_data)
    scene.collection.objects.link(cam)
    d = size * 2.6
    cam.location = center + Vector((d * 0.75, -d * 0.9, d * 0.55))
    direction = center - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    scene.render.engine = "BLENDER_WORKBENCH"
    shading = scene.display.shading
    shading.light = "STUDIO"
    shading.color_type = "VERTEX"
    shading.show_shadows = False
    scene.render.resolution_x = 480
    scene.render.resolution_y = 480
    scene.render.film_transparent = False
    world = bpy.data.worlds.new("w") if not scene.world else scene.world
    scene.world = world
    scene.render.filepath = os.path.join(OUT, os.path.splitext(os.path.basename(path))[0] + ".png")
    bpy.ops.render.render(write_still=True)
    print("[preview]", scene.render.filepath)
