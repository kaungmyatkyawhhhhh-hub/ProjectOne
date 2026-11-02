"""Check renders of a converted car (.blend from auto_car.py): front 3/4, rear 3/4, side and the
driver's seat (steering wheel in magenta, the wheels in cyan when --marks). Blender, Cycles CPU.

    blender -b --python tools/render_car.py -- car.blend outdir [--marks] [--eye dx,dy,dz]

The car is laid out like auto_car.py makes it: front along -Y, up +Z, metres, ground at 0.
"""

import os
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1 :]
blend, outdir = args[0], args[1]
marks = "--marks" in args
eye_nudge = Vector((0, 0, 0))
if "--eye" in args:
    eye_nudge = Vector([float(v) for v in args[args.index("--eye") + 1].split(",")])
os.makedirs(outdir, exist_ok=True)
name = os.path.splitext(os.path.basename(blend))[0]
bpy.ops.wm.open_mainfile(filepath=blend)
sc = bpy.context.scene


def flat(rgb):
    m = bpy.data.materials.new("mark")
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Emission Color"].default_value = (*rgb, 1)
    b.inputs["Emission Strength"].default_value = 1.0
    return m


lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
steer = None
for o in bpy.data.objects:
    if o.type != "MESH":
        continue
    for v in o.bound_box:
        p = o.matrix_world @ Vector(v)
        lo = Vector(map(min, lo, p))
        hi = Vector(map(max, hi, p))
    if o.name.startswith("SteeringWheel"):
        steer = o
if marks:
    mag, cyan = flat((1, 0, 1)), flat((0, 1, 1))
    for o in bpy.data.objects:
        if o.type != "MESH":
            continue
        top = o
        while top.parent:
            top = top.parent
        if o.name.startswith("SteeringWheel") or top.name.startswith("SteeringWheel"):
            o.data.materials.clear()
            o.data.materials.append(mag)
        elif o.name[:2] in ("FL", "FR", "RL", "RR") or top.name == "Wheels":
            o.data.materials.clear()
            o.data.materials.append(cyan)

w = bpy.data.worlds.new("w")
sc.world = w
w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.75, 0.8, 0.9, 1)
w.node_tree.nodes["Background"].inputs[1].default_value = 1.2
sun = bpy.data.lights.new("sun", "SUN")
sun.energy = 3
so = bpy.data.objects.new("sun", sun)
so.rotation_euler = (0.7, 0.2, 0.8)
sc.collection.objects.link(so)
bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
sc.render.engine = "CYCLES"
sc.cycles.device = "CPU"
sc.cycles.samples = 24
sc.cycles.use_denoising = True
cam = bpy.data.cameras.new("c")
co = bpy.data.objects.new("cam", cam)
sc.collection.objects.link(co)
sc.camera = co


def shot(tag, eye, look, lens, W=960, H=600):
    sc.render.resolution_x, sc.render.resolution_y = W, H
    cam.lens = lens
    co.location = Vector(eye)
    co.rotation_euler = (Vector(look) - Vector(eye)).normalized().to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(outdir, f"{name}_{tag}.png")
    bpy.ops.render.render(write_still=True)


mid = (lo + hi) / 2
L = hi.y - lo.y
shot("front34", (hi.x + 3.2, lo.y - 3.6, 1.4), (mid.x, mid.y - 0.3, 0.55), 35)
shot("rear34", (lo.x - 3.2, hi.y + 3.6, 1.5), (mid.x, mid.y + 0.3, 0.55), 35)
shot("side", (hi.x + 7.5, mid.y, 0.8), (mid.x, mid.y, 0.6), 40, 1200, 480)
if steer:
    c = steer.matrix_world @ (sum((Vector(v) for v in steer.bound_box), Vector()) / 8)
    eye = c + Vector((0, 0.55, 0.30)) + eye_nudge
    shot("driver", eye, c + Vector((0, -1.0, -0.05)), 18)
    # the cluster close up, just over the rim
    shot("cluster", c + Vector((0, 0.32, 0.16)), c + Vector((0, -0.3, 0.05)), 30)
print("bounds", tuple(round(v, 3) for v in lo), tuple(round(v, 3) for v in hi), "steer", steer and tuple(round(v, 3) for v in (steer.matrix_world @ (sum((Vector(v) for v in steer.bound_box), Vector()) / 8))))
