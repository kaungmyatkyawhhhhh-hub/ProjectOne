"""Preview renders for the v2 shark: 3/4 front (jaw open a little), side, behind-above (game camera)."""
import bpy, math, sys
from mathutils import Vector
OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "/tmp/v2.png"
JAW = float(sys.argv[sys.argv.index("--") + 2]) if "--" in sys.argv and len(sys.argv) > sys.argv.index("--") + 2 else 14
sc = bpy.context.scene
sc.render.engine = "CYCLES"; sc.cycles.samples = 28; sc.cycles.use_denoising = True
sc.render.resolution_x, sc.render.resolution_y = 720, 460
sc.view_settings.view_transform = "Standard"
w = sc.world or bpy.data.worlds.new("W"); sc.world = w; w.use_nodes = True
bg = w.node_tree.nodes.get("Background"); bg.inputs[0].default_value = (0.03, 0.30, 0.42, 1); bg.inputs[1].default_value = 0.7
def light(name, loc, power, size=3, col=(1, 1, 1)):
    if name in bpy.data.objects: bpy.data.objects.remove(bpy.data.objects[name])
    ld = bpy.data.lights.new(name, "AREA"); ld.energy = power; ld.size = size; ld.color = col
    ob = bpy.data.objects.new(name, ld); sc.collection.objects.link(ob); ob.location = loc
    ob.rotation_euler = (Vector((0, 0, 0)) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
light("Key", (2, -3, 6), 1100, 4); light("Rim", (-5, 3, 3), 700, 3, (0.7, 0.95, 1)); light("Fill", (3, 4, -2), 220, 4, (0.8, 0.9, 1))
rig = bpy.data.objects.get("ReefSharkRig")
if rig:
    rig.animation_data.action = None
    for pb in rig.pose.bones: pb.rotation_mode = "XYZ"; pb.rotation_euler = (0, 0, 0)
    rig.pose.bones["Jaw"].rotation_euler = (0, math.radians(JAW), 0)
    rig.pose.bones["Spine3"].rotation_euler = (0, 0, math.radians(6)); rig.pose.bones["Spine4"].rotation_euler = (0, 0, math.radians(9))
cam = bpy.data.objects.get("Cam") or bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
if cam.name not in sc.collection.objects: sc.collection.objects.link(cam)
sc.camera = cam; cam.data.lens = 50
views = {"front34": ((6.2, -4.2, 1.0), (0.4, 0, 0.0)), "side": ((0.2, -9.0, 0.3), (0.1, 0, 0.1)), "game": ((-6.0, -2.6, 3.6), (0.4, 0, 0.0))}
for name, (pos, tgt) in views.items():
    cam.location = pos; cam.rotation_euler = (Vector(tgt) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = OUT.replace(".png", f"_{name}.png"); bpy.ops.render.render(write_still=True)
print("rendered")
