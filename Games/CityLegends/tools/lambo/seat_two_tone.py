"""Seat centres in a second colour: faces of a palette cell inside the seats' boxes move to another cell of the
same picture (the LFAs: black bolsters, red centres; owner, 2026-11-06: "red / black leather").

    blender -b --python tools/lambo/seat_two_tone.py -- in.blend out.blend spec.json

spec: {"seats": [[x, half width, y0, y1, z0, z1], ...], "from_u": [u0, u1], "to": [u, v]}   (v measured from the top)
"""

import json
import sys

import bmesh
import bpy

args = sys.argv[sys.argv.index("--") + 1 :]
bpy.ops.wm.open_mainfile(filepath=args[0])
spec = json.load(open(args[2]))
moved = 0
for o in bpy.data.objects:
    if o.type != "MESH" or not o.data.uv_layers or o.name.startswith("SteeringWheel"):
        continue
    bm = bmesh.new()
    bm.from_mesh(o.data)
    uv = bm.loops.layers.uv.active
    M = o.matrix_world
    hit = 0
    for f in bm.faces:
        u = sum(l[uv].uv.x for l in f.loops) / len(f.loops) % 1.0
        if not spec["from_u"][0] <= u <= spec["from_u"][1]:
            continue
        c = M @ f.calc_center_median()
        for x, hw, y0, y1, z0, z1 in spec["seats"]:
            if abs(c.x - x) < hw and y0 < c.y < y1 and z0 < c.z < z1:
                for l in f.loops:
                    l[uv].uv = (spec["to"][0], 1 - spec["to"][1])
                hit += 1
                break
    if hit:
        bm.to_mesh(o.data)
        moved += hit
    bm.free()
bpy.ops.wm.save_as_mainfile(filepath=args[1])
print("SEATS moved", moved)
