"""toyoka_chaser_backs.py -- in.blend out.blend : backs for the faces Roblox would draw see-through (2026-11-14, the Chaser JZX100).

Roblox draws only the front of a MeshPart's face. On this model (a Roblox export) the cabin's upper trims, the headlining, the
rear window's chrome surround and the inside of the roof / pillars are single faces whose backs are seen from the seats and
through the windows (the sky would show through them). Rays from all round the car (36,000, 4.5 x 5.5 m out, 0.15-3 m up)
and from the four seats (9,000) find the first face each meets; in every loose piece met on its BACK, each face whose back
can be seen from one of the eyes (24 head places in the four seats, six rings round the car from 0.25 to 2.9 m up, and the
start of every ray that met a back: a clear line from the face's middle to the eye, on its back side) gets a reversed copy
(same place, picture map and part), so it shows from both sides. The steering wheel is left alone (it turns). Glass is
two-sided in the game anyway. Run on the finished car (after finish_car.py). Check: the scratch backcheck.py (2026-11-14:
515 of 38,333 rays met a back before, 78 after; 11,885 faces doubled).

    blender -b --python tools/logo_paint/toyoka_chaser_backs.py -- in.blend out.blend
"""
import math
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Vector

a = sys.argv[sys.argv.index("--") + 1 :]
bpy.ops.wm.open_mainfile(filepath=a[0])
hidden = []
for o in bpy.data.objects:
    if o.name.startswith(("SeeThrough", "LampFx")):
        o.hide_set(True)
        o.hide_viewport = True
        hidden.append(o)
bpy.context.view_layer.update()
dg = bpy.context.evaluated_depsgraph_get()
sc = bpy.context.scene
rays = []
for seed in (7,):  # (four seeds doubled 23,133 faces for a few rays less: one is enough)
  rng = np.random.default_rng(seed)
  for i in range(36000):
    th = rng.uniform(0, 2 * math.pi)
    e = Vector((4.5 * math.cos(th), 5.5 * math.sin(th), rng.uniform(0.15, 3.0)))
    t = Vector((rng.uniform(-0.95, 0.95), rng.uniform(-2.3, 2.6), rng.uniform(0.05, 1.35)))
    rays.append((e, (t - e).normalized()))
  for i in range(9000):
    e = Vector((rng.choice([0.38, -0.38]), rng.choice([0.15, 1.1]), 1.08))
    rays.append((e, Vector((rng.normal(), rng.normal(), rng.normal() * 0.6)).normalized()))
EYES = [Vector((sx * 0.38 + dx, sy, z)) for sx in (1, -1) for sy in (0.1, 0.25, 1.1) for dx in (-0.1, 0.1) for z in (1.0, 1.15)]
EYES += [Vector((4.5 * math.cos(t), 5.5 * math.sin(t), z)) for z in (0.25, 0.6, 1.0, 1.5, 2.1, 2.9) for t in np.radians(np.arange(0, 360, 15))]
hits = {}
for e, d in rays:
    hit, loc, nor, fi, ob, M = sc.ray_cast(dg, e, d)
    if not hit or ob.name.startswith("SteeringWheel"):
        continue
    if ob.matrix_world.to_3x3().determinant() < 0:
        nor = -nor
    if nor.dot(d) > 0:
        hits.setdefault(ob.name, set()).add(fi)
        EYES.append(e)  # (the ray's own start sees that back too)
total = 0
for name, faces in sorted(hits.items()):
    o = bpy.data.objects[name]
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bm.faces.ensure_lookup_table()
    # loose pieces (welded by place) holding a hit face
    co = np.array([v.co[:] for v in bm.verts])
    k = np.unique(np.round(co, 5), axis=0, return_inverse=True)[1].reshape(-1)
    par = list(range(int(k.max()) + 1))

    def find(x):
        while par[x] != x:
            par[x] = par[par[x]]
            x = par[x]
        return x

    for f in bm.faces:
        r = find(k[f.verts[0].index])
        for v in f.verts[1:]:
            par[find(k[v.index])] = r
    lab = np.array([find(k[f.verts[0].index]) for f in bm.faces])
    want = {lab[i] for i in faces if i < len(lab)}
    cand = [f for f in bm.faces if lab[f.index] in want]
    Mw = o.matrix_world
    pick = []
    for f in cand:
        c = Mw @ f.calc_center_median()
        n = (Mw.to_3x3() @ f.normal).normalized()
        if Mw.to_3x3().determinant() < 0:
            n = -n
        for E in EYES:
            v = E - c
            if v.dot(n) >= -1e-4:
                continue
            L = v.length
            hit2 = sc.ray_cast(dg, c + v / L * 0.002, v / L, distance=L - 0.002)[0]
            if not hit2:
                pick.append(f)
                break
    uv = bm.loops.layers.uv.active
    for f in pick:
        loops = list(f.loops)[::-1]
        nf = bm.faces.new([bm.verts.new(l.vert.co) for l in loops])
        nf.material_index = f.material_index
        nf.smooth = f.smooth
        if uv:
            for nl, l in zip(nf.loops, loops):
                nl[uv].uv = l[uv].uv
    bm.to_mesh(o.data)
    bm.free()
    o.data.update()
    total += len(pick)
    print("BACKS %s: %d hit faces in %d pieces -> %d faces doubled" % (name, len(faces), len(want), len(pick)))
print("BACKS total doubled", total)
for o in hidden:
    o.hide_set(False)
    o.hide_viewport = False
bpy.ops.wm.save_as_mainfile(filepath=a[1])
