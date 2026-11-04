"""Depth across a car's cluster frame, seen from the driver's side along the screen's normal (tools/svj_bezel's
probe, for a finished car): what the frame's ribs and edges leave open, to fit a flat panel behind them.

    blender -b --python tools/lambo/frame_probe.py -- car.blend out.json cx,cy,cz nx,ny,nz

c: a point on the screen, n: the way it faces (both Blender: x left, y back, z up). Rows run down, columns from
the driver's left to right, every 2 mm. depth: + towards the driver.
"""

import json
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1 :]
bpy.ops.wm.open_mainfile(filepath=args[0])
out = args[1]
c = Vector([float(v) for v in args[2].split(",")])
F = Vector([float(v) for v in args[3].split(",")]).normalized()
up = (Vector((0, 0, 1)) - F * F.z).normalized()
left = up.cross(F).normalized()  # (the driver looks along -F: +x in Blender is the driver's left... checked below)
if left.x < 0:
    left = -left
for o in bpy.data.objects:
    if o.name.startswith("SteeringWheel") or o.name.startswith("SeeThrough"):
        o.hide_viewport = True
        o.hide_set(True)
bpy.context.view_layer.update()
dg = bpy.context.evaluated_depsgraph_get()
STEP = 0.002
HALF_U, HALF_V = 0.34, 0.13
U, V = int(2 * HALF_U / STEP), int(2 * HALF_V / STEP)
rows = []
parts = {}
for j in range(V):
    v = HALF_V - j * STEP
    row = []
    for i in range(U):
        u = -HALF_U + i * STEP  # + = the driver's right
        p = c - left * u + up * v + F * 0.12
        ok, loc, nor, idx, obj, mat = bpy.context.scene.ray_cast(dg, p, -F, distance=0.4)
        if ok:
            k = parts.setdefault(obj.name, len(parts))
            row.append([round((loc - c).dot(F), 4), k])
        else:
            row.append([None, -1])
    rows.append(row)
json.dump({"step": STEP, "u0": -HALF_U, "v0": HALF_V, "rows": rows, "parts": parts}, open(out, "w"))
print("FRAME", U, V, parts)
