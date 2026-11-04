"""A cluster picture on a car's own blank screen (preview for the owner, and the place the game's
screen goes). Starting from one face of the screen, the faces joined to it that lie in nearly its
plane are taken as the screen; they get the picture by a flat projection, left of the picture on
the driver's left.

    blender -b --python tools/lambo/put_art.py -- car.blend art.png out.blend sx,sy,sz [--fit width|height] [--nudge du,dv] [--scale k] [--crop x0,y0,x1,y1]

Prints the screen's middle, its normal, width and height (what CarSkin.CLUSTER_RECT needs).
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mesh_cut import delete_faces  # noqa: E402

import bmesh
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

args = sys.argv[sys.argv.index("--") + 1:]
car, art, out = args[0], args[1], args[2]
seed = Vector([float(v) for v in args[3].split(",")])
fit = args[args.index("--fit") + 1] if "--fit" in args else "width"
nudge = [float(v) for v in args[args.index("--nudge") + 1].split(",")] if "--nudge" in args else [0.0, 0.0]
scale = float(args[args.index("--scale") + 1]) if "--scale" in args else 1.0
bpy.ops.wm.open_mainfile(filepath=car)
sc = bpy.context.scene
dg = bpy.context.evaluated_depsgraph_get()

# the face under the seed, from the driver's side
eye = seed + Vector((0, 0.3, 0.12))
d = (seed - eye).normalized()
hit, loc, nrm, idx, obj, _ = sc.ray_cast(dg, eye, d)
while hit and obj.name.startswith("SteeringWheel"):
    hit, loc, nrm, idx, obj, _ = sc.ray_cast(dg, loc + d * 0.001, d)
print("ART seed face", obj.name[:40], idx)
me = obj.data
m = obj.matrix_world
rot = m.to_3x3()
edge_faces = {}
for p in me.polygons:
    for k in p.edge_keys:
        edge_faces.setdefault(k, []).append(p.index)
n0 = (rot @ me.polygons[idx].normal).normalized()
seen = {idx}
stack = [idx]
faces = []
while stack:
    f = stack.pop()
    faces.append(f)
    for k in me.polygons[f].edge_keys:
        for g in edge_faces[k]:
            if g not in seen:
                seen.add(g)
                if (rot @ me.polygons[g].normal).normalized().dot(n0) > 0.94:
                    stack.append(g)
loops = [[m @ me.vertices[v].co for v in me.polygons[f].vertices] for f in faces]
pts = [p for lp in loops for p in lp]
s = Vector((-1, 0, 0))  # the driver's right
s = (s - n0 * s.dot(n0)).normalized()
t = n0.cross(s).normalized()
if t.z < 0:
    t = -t
mid = sum(pts, Vector()) / len(pts)
ss = [(p - mid).dot(s) for p in pts]
tt = [(p - mid).dot(t) for p in pts]
s0, s1, t0, t1 = min(ss), max(ss), min(tt), max(tt)
centre = mid + s * (s0 + s1) / 2 + t * (t0 + t1) / 2
w, h = s1 - s0, t1 - t0
print("ART screen faces", len(faces), "centre", [round(v, 4) for v in centre], "normal", [round(v, 3) for v in n0], "w", round(w, 4), "h", round(h, 4), "aspect", round(w / h, 3))

img = bpy.data.images.load(art)
iw, ih = img.size
crop = [float(v) for v in args[args.index("--crop") + 1].split(",")] if "--crop" in args else [0.0, 0.0, 1.0, 1.0]
aspect = (iw * (crop[2] - crop[0])) / (ih * (crop[3] - crop[1]))
if fit == "width":
    aw, ah = w, w / aspect
else:
    ah, aw = h, h * aspect
aw *= scale
ah *= scale
mat = bpy.data.materials.new("ClusterArt")
mat.use_nodes = True
b = mat.node_tree.nodes["Principled BSDF"]
tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
tex.image = img
b.inputs["Base Color"].default_value = (0, 0, 0, 1)
mat.node_tree.links.new(tex.outputs["Color"], b.inputs["Emission Color"])
b.inputs["Emission Strength"].default_value = 1.0
b.inputs["Roughness"].default_value = 0.6
b.inputs["Specular IOR Level"].default_value = 0.0

new = bpy.data.meshes.new("Body_ClusterArt")  # (a second run on the same car adds another part)
nb = bmesh.new()
uvl = nb.loops.layers.uv.new("UVMap")
for lp in loops:
    vs = [nb.verts.new(p + n0 * 0.0006) for p in lp]
    nf = nb.faces.new(vs)
    for l, v in zip(nf.loops, vs):
        p = v.co - centre
        cu = 0.5 + (p.dot(s) / aw) + nudge[0]
        cv = 0.5 + (p.dot(t) / ah) + nudge[1]
        # (crop: x0, y0, x1, y1 of the picture as fractions, y from the top)
        l[uvl].uv = (crop[0] + cu * (crop[2] - crop[0]), 1 - crop[3] + cv * (crop[3] - crop[1]))
delete_faces(obj, faces)
nb.to_mesh(new)
nb.free()
new.materials.append(mat)
ob = bpy.data.objects.new("Body_ClusterArt", new)
obj.users_collection[0].objects.link(ob)
bpy.ops.wm.save_as_mainfile(filepath=out)
print("ART saved", out)
