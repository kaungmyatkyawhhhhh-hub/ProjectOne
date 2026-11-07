"""The tail lenses out of a model's one lamp part into a part of their own (Body_TailLens), so the game lights them and not
the whole lamp mesh. Whole loose pieces inside a box go; the box is mirrored for the other side.

    blender -b --python tools/lambo/tail_split.py -- car.blend out.blend Body_Lamp x0,y0,z0,x1,y1,z1 [maxlen]

Coordinates: car metres, x side (+ driver's side of the file), y back, z up; x0..x1 on the + side. Also adds the part to
car.pbr.json next to the output, with the numbers of the part it came from."""

import json
import os
import sys

import bmesh
import bpy

args = sys.argv[sys.argv.index("--") + 1 :]
src, out, part = args[0], args[1], args[2]
box = [float(v) for v in args[3].split(",")]
maxlen = float(args[4]) if len(args) > 4 else 0.6
bpy.ops.wm.open_mainfile(filepath=src)
o = bpy.data.objects[part]
bpy.context.scene.tool_settings.mesh_select_mode = (False, False, True)
M = o.matrix_world
bm = bmesh.new()
bm.from_mesh(o.data)
bm.faces.ensure_lookup_table()
seen = set()
take = []
for f0 in bm.faces:
    if f0.index in seen:
        continue
    seen.add(f0.index)
    st, comp = [f0], []
    while st:
        g = st.pop()
        comp.append(g)
        for e in g.edges:
            for h in e.link_faces:
                if h.index not in seen:
                    seen.add(h.index)
                    st.append(h)
    pts = [M @ v.co for g in comp for v in g.verts]
    lo = [min(p[i] for p in pts) for i in range(3)]
    hi = [max(p[i] for p in pts) for i in range(3)]
    ax = abs((lo[0] + hi[0]) / 2)
    half = (hi[0] - lo[0]) / 2
    if ax - half >= box[0] and ax + half <= box[3] and lo[1] >= box[1] and hi[1] <= box[4] and lo[2] >= box[2] and hi[2] <= box[5] and max(hi[i] - lo[i] for i in range(3)) <= maxlen:
        take.append(comp)
for f in bm.faces:
    f.select = False
n = 0
for comp in take:
    for f in comp:
        f.select = True
        n += 1
bm.to_mesh(o.data)
bm.free()
print("TAILSPLIT pieces", len(take), "faces", n)
bpy.ops.object.select_all(action="DESELECT")
bpy.context.view_layer.objects.active = o
o.select_set(True)
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.separate(type="SELECTED")
bpy.ops.object.mode_set(mode="OBJECT")
new = next(x for x in bpy.context.selected_objects if x is not o)
new.name = new.data.name = "Body_TailLens"
bpy.ops.wm.save_as_mainfile(filepath=out)
p = os.path.splitext(out)[0] + ".pbr.json"
d = json.load(open(p))
d["parts"]["Body_TailLens"] = dict(d["parts"][part])
json.dump(d, open(p, "w"))
print("TAILSPLIT saved")
