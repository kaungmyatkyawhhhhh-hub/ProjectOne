"""The steering wheel moved in a converted car (owner, 2026-11-05: "U cant see the cluster"). The Murcielago
model's rim stands in the line from the driver's eye to the dials; the game sets the eye from the wheel,
so raising the wheel clears the dials from the seat. Its .blend.json gets the new centre.

    blender -b --python tools/lambo/lift_wheel.py -- in.blend out.blend dz
"""

import json
import shutil
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1 :]
src, out, dz = args[0], args[1], float(args[2])
bpy.ops.wm.open_mainfile(filepath=src)
n = 0
for o in bpy.data.objects:
    if o.name.startswith("SteeringWheel"):
        o.location = o.location + Vector((0, 0, dz))
        n += 1
bpy.ops.wm.save_as_mainfile(filepath=out)
r = json.load(open(src + ".json"))
r["steering"]["centre"][2] += dz
json.dump(r, open(out + ".json", "w"))
print("LIFT", n, "parts", dz)
