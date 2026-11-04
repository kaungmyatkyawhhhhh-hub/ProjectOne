"""The Huracan EVO's cluster in another Huracan (owner, 2026-11-04: "Share the EVO's cluster with the
other 3 hurcans"). The four share one cockpit mesh, but each model sits at its own height, so the
offset comes from fitting the EVO's dash onto the target's (translation only, nearest points).

    blender -b --python tools/lambo/share_evo.py -- target.blend evo.blend out.blend gx,gy,gz

gx,gy,gz: a first guess of the offset (metres). Only the cluster's faces of `Body_emiss` are taken
(texture v under 0.38: the atlas also holds the centre screen and the button icons).
"""

import statistics
import sys

import bmesh
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

args = sys.argv[sys.argv.index("--") + 1:]
target, donor, out = args[0], args[1], args[2]
guess = Vector([float(v) for v in args[3].split(",")])
LO, HI = Vector((0.15, -0.86, 0.62)), Vector((0.57, -0.62, 0.98))  # round the EVO's cluster


def inside(p, lo, hi):
    return lo.x <= p.x <= hi.x and lo.y <= p.y <= hi.y and lo.z <= p.z <= hi.z


bpy.ops.wm.open_mainfile(filepath=target)
sc = bpy.context.scene
with bpy.data.libraries.load(donor) as (src, dst):
    dst.objects = [n for n in src.objects if n.startswith("Body_")]
donors = [o for o in dst.objects if o is not None]
donor_names = {o.name for o in donors}

# the donor's dash round the cluster
samples = []
emiss = None
for o in donors:
    if o.type != "MESH":
        continue
    if o.name.startswith("Body_emiss"):
        emiss = o
        continue
    m = o.matrix_world
    for poly in o.data.polygons:
        p = m @ poly.center
        if inside(p, LO, HI):
            samples.append(p)

# the target's dash
verts, polys = [], []
lo2, hi2 = LO + guess - Vector((0.08,) * 3), HI + guess + Vector((0.08,) * 3)
for o in bpy.data.objects:
    if o.type != "MESH" or o.name in donor_names or not o.name.startswith("Body_"):
        continue
    m = o.matrix_world
    world = [m @ v.co for v in o.data.vertices]
    for poly in o.data.polygons:
        if inside(m @ poly.center, lo2, hi2):
            base = len(verts)
            ids = list(poly.vertices)
            verts.extend(world[i] for i in ids)
            polys.append(list(range(base, base + len(ids))))
bvh = BVHTree.FromPolygons(verts, polys)

t = guess.copy()
reach = 0.03
for it in range(30):
    dx, dy, dz = [], [], []
    for p in samples:
        q, _, _, d = bvh.find_nearest(p + t)
        if q is not None and d < reach:
            e = q - (p + t)
            dx.append(e.x)
            dy.append(e.y)
            dz.append(e.z)
    t += Vector((statistics.median(dx), statistics.median(dy), statistics.median(dz)))
    reach = max(0.006, reach * 0.8)
gaps = []
for p in samples:
    q, _, _, d = bvh.find_nearest(p + t)
    if q is not None:
        gaps.append(d)
gaps.sort()
print("SHARE offset", [round(v, 4) for v in t], "samples", len(samples), "median gap mm", round(gaps[len(gaps) // 2] * 1000, 2), "90% mm", round(gaps[int(len(gaps) * 0.9)] * 1000, 2))

# the cluster's faces only, moved onto the target
me = emiss.data.copy()
bm = bmesh.new()
bm.from_mesh(me)
uv = bm.loops.layers.uv.active
m = emiss.matrix_world
drop = []
for f in bm.faces:
    c = m @ f.calc_center_median()
    vs = [l[uv].uv.y for l in f.loops]
    if max(vs) > 0.38 or not inside(c, LO, HI):
        drop.append(f)
bmesh.ops.delete(bm, geom=drop, context="FACES")
for v in bm.verts:
    v.co = m @ v.co + t
print("SHARE faces", len(bm.faces))
bm.to_mesh(me)
bm.free()
# the target's own blank screen stands in front of it in places: its faces at the cluster go
cv = [v.co.copy() for v in me.vertices]
cf = [list(p.vertices) for p in me.polygons]
cbvh = BVHTree.FromPolygons(cv, cf)
normal = sum((p.normal for p in me.polygons), Vector()).normalized()
cut = {}
for o in bpy.data.objects:
    if o.type != "MESH" or o.name in donor_names or not o.name.startswith("Body_"):
        continue
    bm = bmesh.new()
    bm.from_mesh(o.data)
    m = o.matrix_world
    rot = m.to_3x3()
    drop = []
    for f in bm.faces:
        c = m @ f.calc_center_median()
        if not inside(c, lo2, hi2):
            continue
        n = (rot @ f.normal).normalized()
        q, _, _, d = cbvh.find_nearest(c)
        if q is not None and d < 0.022 and abs(n.dot(normal)) > 0.8:
            drop.append(f)
    if drop:
        cut[o.name[:30]] = len(drop)
        bmesh.ops.delete(bm, geom=drop, context="FACES")
        bm.to_mesh(o.data)
    bm.free()
print("SHARE own faces cut", cut)
ob = bpy.data.objects.new("Body_HuracanCluster", me)
home = next(o for o in bpy.data.objects if o.name.startswith("Body_") and o.name not in donor_names and o.users_collection)
home.users_collection[0].objects.link(ob)
bpy.ops.wm.save_as_mainfile(filepath=out)
print("SHARE saved", out)
