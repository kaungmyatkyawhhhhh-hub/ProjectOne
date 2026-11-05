"""A family member's steering wheel in another car (owner, 2026-11-05: the 458 Speciale's in the 458 Spider).
The target's wheel goes; the donor's comes in, tilted to the target's column and set on its centre, and
takes the target's tilt in its name (the game turns the wheel about that tilt).

    blender -b --python tools/lambo/share_wheel.py -- target.blend donor.blend out.blend

Both .blend files have auto_car.py's report beside them (<file>.blend.json).
"""

import json
import math
import sys

import bpy
from mathutils import Matrix, Vector

args = sys.argv[sys.argv.index("--") + 1 :]
target, donor, out = args[0], args[1], args[2]
rt = json.load(open(target + ".json"))["steering"]
rd = json.load(open(donor + ".json"))["steering"]
ct, cd = Vector(rt["centre"]), Vector(rd["centre"])
turn = math.radians(rt["tilt"] - rd["tilt"])

bpy.ops.wm.open_mainfile(filepath=target)
tilt_name = None
for o in [x for x in bpy.data.objects if x.name.startswith("SteeringWheel")]:
    tilt_name = tilt_name or o.name.split(".")[0]
    bpy.data.objects.remove(o)
with bpy.data.libraries.load(donor, link=False) as (src, dst):
    dst.objects = [n for n in src.objects if n.startswith("SteeringWheel")]
col = bpy.context.scene.collection
# (a wheel leaning further back: its top moves towards the front, -Y)
R = Matrix.Translation(ct) @ Matrix.Rotation(turn, 4, "X") @ Matrix.Translation(-cd)
for i, o in enumerate(x for x in dst.objects if x):
    col.objects.link(o)
    o.parent = None
    o.matrix_world = R @ o.matrix_basis  # (just linked: matrix_world isn't worked out yet)
    o.name = tilt_name if i == 0 else "%s.%03d" % (tilt_name, i)
    print("WHEEL in", o.name, len(o.data.polygons))
bpy.ops.wm.save_as_mainfile(filepath=out)
print("WHEEL saved", out, "turned", round(math.degrees(turn), 2))
