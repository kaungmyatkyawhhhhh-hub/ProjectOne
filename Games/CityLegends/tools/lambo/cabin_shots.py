"""Looking into a converted car's open cabin: from above, each side, behind, and the driver's seat,
to find holes, clipped parts and grey pieces.

    blender -b --python tools/lambo/cabin_shots.py -- car.blend out.jpg [--night]

Writes one contact sheet. The car lies like auto_car.py makes it: front along -Y, up +Z, metres.
"""

import json
import os
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1 :]
blend, out = args[0], args[1]
bpy.ops.wm.open_mainfile(filepath=blend)
sc = bpy.context.scene
w = bpy.data.worlds.new("w")
sc.world = w
w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.82, 0.85, 0.9, 1)
w.node_tree.nodes["Background"].inputs[1].default_value = 1.3
sc.render.engine = "CYCLES"
sc.cycles.device = "CPU"
sc.cycles.samples = 32
sc.cycles.use_denoising = True
sc.render.image_settings.file_format = "PNG"
sc.render.resolution_x, sc.render.resolution_y = 720, 450
cam = bpy.data.cameras.new("c")
co = bpy.data.objects.new("cam", cam)
sc.collection.objects.link(co)
sc.camera = co
rep = json.load(open(blend + ".json")) if os.path.exists(blend + ".json") else {"steering": {"centre": [0.35, -0.55, 0.7]}}
c = Vector(rep["steering"]["centre"])
mid = Vector((0, c.y + 0.45, c.z + 0.05))
SHOTS = [
    ("top", mid + Vector((0, 0.01, 2.3)), mid, 32),
    ("left", mid + Vector((-1.9, 0.2, 0.95)), mid, 30),
    ("right", mid + Vector((1.9, 0.2, 0.95)), mid, 30),
    ("rear", mid + Vector((0, 2.6, 1.1)), mid, 34),
    ("front", mid + Vector((0, -2.6, 1.0)), mid, 34),
    ("seat", Vector((c.x, c.y + 0.62, c.z + 0.3)), Vector((0, c.y - 0.4, c.z + 0.05)), 24),
]
paths = []
for name, eye, look, lens in SHOTS:
    cam.lens = lens
    co.location = eye
    co.rotation_euler = (look - eye).normalized().to_track_quat("-Z", "Y").to_euler()
    bpy.context.view_layer.update()
    p = out + "_" + name + ".png"
    sc.render.filepath = p
    bpy.ops.render.render(write_still=True)
    paths.append(p)
print("SHOTS", paths)
