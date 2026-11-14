"""toyoka_supra_mk4_split.py -- in.blend out.blend : the 1994 Supra's steering wheel cleaned, between auto_car.py and finish_car.py
(2026-11-14; the car uses the model's own steering wheel in the game, owner's rule of 2026-11-13).

auto_car.py cuts the steering wheel out of the cabin mesh by place (radius 0.21 m round the rim's middle). On this model it
takes the column stalks (both stalks and their ends), the cluster hood's front lip and two dozen small label / warning-light
decals of the cluster with it: every loose piece of SteeringWheel_* that lies wholly further forward than 0.17 m ahead of the
car's middle (its highest y < -0.17; the rim itself reaches -0.165 at the top, the hub boss -0.196 but ends at -0.104) goes
back into the cabin part with its UVs. The wheel's own decal pieces whose picture is a maker's word (the harness / seat maker's
word laid on the hub) are deleted, not moved: their picture area is see-through now (mkpics.py), so they would turn into
black slips.

    blender -b --python tools/logo_paint/toyoka_supra_mk4_split.py -- in.blend out.blend
"""
import json
import os
import sys

import bmesh
import bpy
import numpy as np

a = sys.argv[sys.argv.index("--") + 1 :]
bpy.ops.wm.open_mainfile(filepath=a[0])
LIMIT_Y = -0.17
# the maker's word boxes of the cabin picture (512 px, v down), the same as the scratch's boxes.json "interior_clear"
CLEAR = [[68, 244, 143, 262], [3, 262, 140, 297], [286, 210, 422, 223], [286, 223, 335, 236], [286, 237, 428, 250],
         [405, 250, 458, 263], [477, 10, 508, 21], [409, 66, 475, 91], [213, 265, 263, 278], [213, 304, 263, 315]]
sw = next(o for o in bpy.data.objects if o.type == "MESH" and o.name.startswith("SteeringWheel"))
cab = bpy.data.objects["Body_InteriorA_Material"]
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
uvl = me.uv_layers.active.data
W = H = 512
move, kill = set(), set()
for l in np.unique(lab):
    faces = np.where(lab == l)[0]
    pts = co[[v for f in faces for v in me.polygons[f].vertices]]
    uv = np.array([uvl[li].uv for f in faces for li in me.polygons[f].loop_indices])
    u, v = uv[:, 0].mean() % 1.0 * W, (1 - uv[:, 1].mean() % 1.0) * H
    if any(x0 <= u <= x1 and y0 <= v <= y1 for x0, y0, x1, y1 in CLEAR):
        kill |= set(int(f) for f in faces)
        print("SPLIT word decal deleted", len(faces), "faces uv", round(u), round(v), "lo", pts.min(0).round(3).tolist())
    elif pts[:, 1].max() < LIMIT_Y:
        move |= set(int(f) for f in faces)
print("SPLIT moving", len(move), "faces to the cabin; deleting", len(kill))
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
    nf = dst.faces.new([dst.verts.new(Ci @ (M @ l.vert.co)) for l in loops])
    nf.smooth = f.smooth
    nf.material_index = 0
    for nl, l in zip(nf.loops, loops):
        nl[duv].uv = l[suv].uv
bmesh.ops.delete(src, geom=[src.faces[i] for i in sorted(move | kill)], context="FACES")
bmesh.ops.delete(src, geom=[v for v in src.verts if not v.link_faces], context="VERTS")
src.to_mesh(me)
dst.to_mesh(cab.data)
src.free()
dst.free()
P = np.array([list(M @ v.co) for v in me.vertices])
print("SPLIT wheel now", len(me.polygons), "faces, box lo", P.min(0).round(4).tolist(), "hi", P.max(0).round(4).tolist(), "middle", ((P.min(0) + P.max(0)) / 2).round(4).tolist())
print("SPLIT cabin now", len(cab.data.polygons), "faces")
bpy.ops.wm.save_as_mainfile(filepath=a[1])
