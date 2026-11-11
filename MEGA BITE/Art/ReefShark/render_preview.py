"""Preview render: studio light, ocean-blue background, three views in one sheet."""
import bpy, math, sys
from mathutils import Vector

OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "/tmp/preview.png"
sc = bpy.context.scene
sc.render.engine = "CYCLES"; sc.cycles.samples = 24; sc.cycles.use_denoising = True
try: sc.cycles.denoiser = "OPENIMAGEDENOISE"
except Exception: pass
sc.render.resolution_x, sc.render.resolution_y = 640, 480
sc.view_settings.view_transform = "Standard"
w = sc.world or bpy.data.worlds.new("W"); sc.world = w; w.use_nodes = True
bg = w.node_tree.nodes.get("Background"); bg.inputs[0].default_value = (0.05, 0.35, 0.45, 1); bg.inputs[1].default_value = 0.6
for n in ("Key", "Rim", "Fill"):
    if n in bpy.data.objects: bpy.data.objects.remove(bpy.data.objects[n])
def light(name, loc, power, size=3, col=(1, 1, 1)):
    ld = bpy.data.lights.new(name, "AREA"); ld.energy = power; ld.size = size; ld.color = col
    ob = bpy.data.objects.new(name, ld); sc.collection.objects.link(ob); ob.location = loc
    d = Vector((0, 0, 0)) - Vector(loc); ob.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
light("Key", (3, -4, 5), 900); light("Rim", (-4, 3, 3), 600, col=(0.7, 0.95, 1)); light("Fill", (2, 4, -1), 150)
cam = bpy.data.objects.get("Cam") or bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
if cam.name not in sc.collection.objects: sc.collection.objects.link(cam)
sc.camera = cam; cam.data.lens = 50
views = {"three_quarter": (4.8, -5.2, 2.0), "side": (0.0, -7.5, 0.4), "front": (7.0, -1.2, 0.8)}
import os
paths = []
for name, pos in views.items():
    cam.location = pos; tgt = Vector((-0.2, 0, 0.1))
    cam.rotation_euler = (tgt - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
    p = OUT.replace(".png", f"_{name}.png"); sc.render.filepath = p
    bpy.ops.render.render(write_still=True); paths.append(p)
print("rendered", paths)
