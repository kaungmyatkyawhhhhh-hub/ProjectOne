"""What you see of the cluster from the driver's seat, cabin lit up so nothing hides in the dark.

    blender -b --python tools/lambo/seat_view.py -- car.blend out.png [lens] [eye height, metres]

The eye is render_car.py's driver's seat; the view is aimed at the cluster, steering wheel left in.
"""

import json
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1 :]
blend, out = args[0], args[1]
lens = float(args[2]) if len(args) > 2 else 40.0
c = Vector(json.load(open(blend + ".json"))["steering"]["centre"])
bpy.ops.wm.open_mainfile(filepath=blend)
sc = bpy.context.scene
w = bpy.data.worlds.new("w")
sc.world = w
w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.86, 0.88, 0.92, 1)
w.node_tree.nodes["Background"].inputs[1].default_value = 1.6
sc.render.engine = "CYCLES"
sc.cycles.device = "CPU"
sc.cycles.samples = 40
sc.cycles.use_denoising = True
sc.render.image_settings.file_format = "PNG"
sc.render.resolution_x, sc.render.resolution_y = 900, 560
cam = bpy.data.cameras.new("c")
co = bpy.data.objects.new("cam", cam)
sc.collection.objects.link(co)
sc.camera = co
eye = c + Vector((0, 0.55, 0.30))
if len(args) > 3:  # the height the game works out (CarSkin: from the roof and the wheel)
    eye.z = float(args[3])
look = c + Vector((0, -0.25, 0.09))
cam.lens = lens
co.location = eye
co.rotation_euler = (look - eye).normalized().to_track_quat("-Z", "Y").to_euler()
for p, e in ((eye + Vector((0, -0.1, -0.05)), 14), (c + Vector((0, 0.1, 0.28)), 6)):
    l = bpy.data.lights.new("l", "POINT")
    l.energy = e
    l.shadow_soft_size = 0.2
    o = bpy.data.objects.new("l", l)
    sc.collection.objects.link(o)
    o.location = p
sc.render.filepath = out
bpy.ops.render.render(write_still=True)
print("SEAT", out)
