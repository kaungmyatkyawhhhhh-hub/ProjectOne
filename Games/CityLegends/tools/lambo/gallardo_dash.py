"""The Superleggera's instrument binnacle in the LP560-4 Spyder (owner, 2026-11-04: "make the LP560
dashboard look a bit better, you can copy from the SL"). The Spyder's own hood and dials are a few
hundred flat faces. The SL's hood, carbon panel, dial cowls, warning lights and dials are moved in,
with the Spyder's own cut away first.

    blender -b --python tools/lambo/gallardo_dash.py -- spyder.blend sl_fixed.blend out.blend

spyder.blend: the plain conversion. sl_fixed.blend: the SL with its middle screen fixed.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mesh_cut import delete_faces  # noqa: E402

import bmesh
import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
car, donor, out = args[0], args[1], args[2]
bpy.ops.wm.open_mainfile(filepath=car)

# SL -> Spyder: the middle of the two big dials
MOVE = Vector((0.3657 - 0.3608, -0.75 + 0.7283, 0.7503 - 0.7924))
KEEP = ("SeeThrough_SLMI_Cabin1", "SeeThrough_SLMI_Carbon_A1", "SeeThrough_SLMI_Cabin_Suede_A1", "Body_SLMI_Cabin1", "SeeThrough_SLMI_Cabin_A1", "Body_SLMI_Dashboard1")
# what's taken, in the SL's own numbers
X0, X1 = 0.125, 0.60
Y0, Y1 = -0.84, -0.56
Z0, Z1 = 0.655, 0.93


def in_box(p):
    return X0 < p.x < X1 and Y0 < p.y < Y1 and Z0 < p.z < Z1


with bpy.data.libraries.load(donor) as (src, dst):
    dst.objects = [n for n in src.objects if n.split(".")[0] in KEEP]
donors = [o for o in dst.objects if o is not None]
home = next(o for o in bpy.data.objects if o.name == "Body_MMAT_Details_MAT1")
coll = home.users_collection[0]
taken = 0
for o in donors:
    bm = bmesh.new()
    bm.from_mesh(o.data)
    m = o.matrix_world
    bm.faces.ensure_lookup_table()
    seen = set()
    drop = []
    for f in bm.faces:
        if f.index in seen:
            continue
        stack, isl = [f], []
        seen.add(f.index)
        while stack:
            g = stack.pop()
            isl.append(g)
            for e in g.edges:
                for h in e.link_faces:
                    if h.index not in seen:
                        seen.add(h.index)
                        stack.append(h)
        pts = [m @ v.co for g in isl for v in g.verts]
        lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
        hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
        size = (hi - lo).length
        c = sum(pts, Vector()) / len(pts)
        if size > 0.75:
            # a big shell: only its faces inside the box
            drop += [g for g in isl if not in_box(m @ g.calc_center_median())]
        elif not in_box(c):
            drop += isl
    bmesh.ops.delete(bm, geom=drop, context="FACES")
    if not bm.faces:
        bm.free()
        continue
    for v in bm.verts:
        v.co = m @ v.co + MOVE
    me = bpy.data.meshes.new("x")
    bm.to_mesh(me)
    taken += len(bm.faces)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    name = "Body_SL_" + o.name.split("_", 2)[-1].split(".")[0]
    ob = bpy.data.objects.new(name, me)
    for s in o.material_slots:
        me.materials.append(s.material)
    coll.objects.link(ob)
print("DASH taken faces", taken)

# the Spyder's own: its cluster faces, and the hood in the same box
# (only what the new binnacle covers: the dash under it and at its sides stays, or it leaves holes)
LO = Vector((0.17, -0.84, 0.655))
HI = Vector((0.565, -0.615, 0.95))
cut = {}
for name in ("Body_MMAT_Details_MAT1", "Body_MMAT_Details_INT1"):
    o = bpy.data.objects[name]
    m = o.matrix_world
    drop = []
    for p in o.data.polygons:
        c = m @ p.center
        if LO.x < c.x < HI.x and LO.y < c.y < HI.y and LO.z < c.z < HI.z:
            drop.append(p.index)
    cut[name] = len(drop)
    delete_faces(o, drop)
print("DASH own faces cut", cut)
# the pale plate round the three gauges in the middle of the dash goes dark too, like the SL's
o = bpy.data.objects["Body_MMAT_Details_MAT1"]
bm = bmesh.new()
bm.from_mesh(o.data)
uv = bm.loops.layers.uv.active
m = o.matrix_world
n = 0
for f in bm.faces:
    us = [l[uv].uv.x for l in f.loops]
    vs = [l[uv].uv.y for l in f.loops]
    c = m @ f.calc_center_median()
    if min(us) >= 0.53 and max(us) <= 0.6 and min(vs) >= 0.33 and max(vs) <= 0.49 and c.x < 0.17 and c.z > 0.66:
        for l in f.loops:
            l[uv].uv = (0.072, 0.679)
        n += 1
bm.to_mesh(o.data)
bm.free()
print("DASH plate faces darkened", n)
bpy.ops.wm.save_as_mainfile(filepath=out)
print("DASH saved", out)
