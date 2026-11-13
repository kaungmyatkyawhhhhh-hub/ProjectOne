"""bnw_m3_e92_split.py -- in.blend out.blend : the E92 GTS's steering wheel cleaned, between auto_car.py and finish_car.py
(2026-11-13; the car uses the model's own steering wheel in the game).

auto_car.py cuts the steering wheel out of the cabin mesh by place, and on this model it takes three pieces of the
column stalks with it (the cruise stalk under the left spoke, 20 triangles; half of the right stalk, 6; the left
stalk's end face, 3): they would turn with the wheel, and they pull the wheel's box 25 mm forward, off the wheel's
own axis (CarSkin turns the wheel about the middle of that box). Every loose piece of SteeringWheel_* that reaches
further forward than 0.37 m behind the car's middle (y < -0.37; the wheel itself ends at -0.354) goes back into the
cabin part, with its UVs.

    blender -b --python tools/logo_paint/bnw_m3_e92_split.py -- in.blend out.blend
"""
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Vector

a = sys.argv[sys.argv.index("--") + 1 :]
bpy.ops.wm.open_mainfile(filepath=a[0])
LIMIT_Y = -0.37
sw = next(o for o in bpy.data.objects if o.type == "MESH" and o.name.startswith("SteeringWheel"))
cab = bpy.data.objects["Body_Interior_Main"]
assert sw.data.materials[0] == cab.data.materials[0]
M = sw.matrix_world
me = sw.data
co = np.array([list(M @ v.co) for v in me.vertices])
key = np.unique(np.round(co, 4), axis=0, return_inverse=True)[1].reshape(-1)
par = list(range(int(key.max()) + 1))


def find(x):
    while par[x] != x:
        par[x] = par[par[x]]
        x = par[x]
    return x


for p in me.polygons:
    r = find(key[p.vertices[0]])
    for v in p.vertices[1:]:
        par[find(key[v])] = r
lab = np.array([find(key[p.vertices[0]]) for p in me.polygons])
move = set()
for l in np.unique(lab):
    faces = np.where(lab == l)[0]
    pts = co[[v for f in faces for v in me.polygons[f].vertices]]
    if pts[:, 1].min() < LIMIT_Y:
        move |= set(int(f) for f in faces)
        print("SPLIT stalk piece", len(faces), "faces lo", pts.min(0).round(3).tolist(), "hi", pts.max(0).round(3).tolist())
assert len(move) == 29, len(move)
# the faces into the cabin part: world places, UVs and the corners' order kept (auto_car.py puts the wheel in a mirrored
# frame without touching the order, so the order is still the one that faces out in the world: what Roblox draws)
flip = False
src = bmesh.new()
src.from_mesh(me)
src.faces.ensure_lookup_table()
suv = src.loops.layers.uv.active
dst = bmesh.new()
dst.from_mesh(cab.data)
duv = dst.loops.layers.uv.active
Ci = cab.matrix_world.inverted()
for f in [src.faces[i] for i in sorted(move)]:
    loops = list(f.loops)
    if flip:
        loops = loops[::-1]
    nf = dst.faces.new([dst.verts.new(Ci @ (M @ l.vert.co)) for l in loops])
    nf.smooth = f.smooth
    nf.material_index = 0
    for nl, l in zip(nf.loops, loops):
        nl[duv].uv = l[suv].uv
bmesh.ops.delete(src, geom=[src.faces[i] for i in sorted(move)], context="FACES")
src.to_mesh(me)
dst.to_mesh(cab.data)
src.free()
dst.free()
P = np.array([list(M @ v.co) for v in me.vertices])
print("SPLIT wheel now", len(me.polygons), "faces, box lo", P.min(0).round(4).tolist(), "hi", P.max(0).round(4).tolist(), "middle", ((P.min(0) + P.max(0)) / 2).round(4).tolist())
print("SPLIT cabin now", len(cab.data.polygons), "faces")
bpy.ops.wm.save_as_mainfile(filepath=a[1])
