"""Close-ups of a finished car to look for logos and holes: nose, tail, a wheel, the seats, the hub.

    blender -b --python tools/lambo/closeups.py -- car.blend outprefix
    python tools/lambo/closeups.py outprefix out.jpg      (the shots on one sheet)

The car lies like auto_car.py makes it: front along -Y, up +Z, metres, ground at 0.
"""

import glob
import sys

if "--" not in sys.argv:
    from PIL import Image

    files = sorted(glob.glob(sys.argv[1] + "_s*.png"))
    W, H = 640, 420
    cols = 4
    rows = (len(files) + cols - 1) // cols
    s = Image.new("RGB", (W * cols, H * rows), (30, 30, 34))
    for i, p in enumerate(files):
        s.paste(Image.open(p).convert("RGB"), ((i % cols) * W, (i // cols) * H))
    s.save(sys.argv[2], quality=88)
    sys.exit(0)

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1 :]
blend, out = args[0], args[1]
bpy.ops.wm.open_mainfile(filepath=blend)
sc = bpy.context.scene
lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
steer = None
for o in bpy.data.objects:
    if o.type != "MESH":
        continue
    if o.name.startswith("SteeringWheel") and steer is None:
        steer = o
    for v in o.bound_box:
        p = o.matrix_world @ Vector(v)
        lo = Vector(map(min, lo, p))
        hi = Vector(map(max, hi, p))
w = bpy.data.worlds.new("w")
sc.world = w
w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.8, 0.84, 0.9, 1)
w.node_tree.nodes["Background"].inputs[1].default_value = 1.0
sun = bpy.data.lights.new("sun", "SUN")
sun.energy = 2.5
so = bpy.data.objects.new("sun", sun)
so.rotation_euler = (0.8, 0.2, 0.9)
sc.collection.objects.link(so)
bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
sc.render.engine = "CYCLES"
sc.cycles.device = "CPU"
sc.cycles.samples = 16
sc.cycles.use_denoising = True
cam = bpy.data.cameras.new("c")
co = bpy.data.objects.new("cam", cam)
sc.collection.objects.link(co)
sc.camera = co
shots = []


def shot(eye, look, lens, W=640, H=420):
    sc.render.resolution_x, sc.render.resolution_y = W, H
    cam.lens = lens
    co.location = Vector(eye)
    co.rotation_euler = (Vector(look) - Vector(eye)).normalized().to_track_quat("-Z", "Y").to_euler()
    path = "%s_s%d.png" % (out, len(shots))
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    shots.append(path)


mid = (lo + hi) / 2
shot((0.5, lo.y - 2.2, 1.0), (0, lo.y + 0.25, 0.62), 45)  # nose
shot((-0.4, hi.y + 2.2, 1.15), (0, hi.y - 0.2, 0.72), 45)  # tail
shot((hi.x + 1.7, lo.y + 0.95, 0.6), (hi.x - 0.1, lo.y + 0.95, 0.35), 45)  # front wheel
shot((0, mid.y + 0.2, hi.z + 1.6), (0, mid.y - 0.9, 0.7), 40)  # bonnet from above
if steer:
    c = steer.matrix_world @ (sum((Vector(v) for v in steer.bound_box), Vector()) / 8)
    shot(c + Vector((0, 0.45, 0.08)), c, 40)  # hub
    shot(c + Vector((-0.36, 0.55, 0.1)), c + Vector((-0.36, -0.55, -0.1)), 18)  # the middle of the dash
    shot(c + Vector((-0.75, -0.1, 0.1)), c + Vector((0.1, 0.65, -0.02)), 20)  # the seats
print("CLOSEUPS", out)
