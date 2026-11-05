"""The Urus Performante's two side gauges (owner's photo, 2026-11-05) on the slanted walls round its screen.
The live screen is a flat panel; these walls stand 15-27 mm in front of it, so the gauges go on the model
itself: a straight-on projection at the same scale as the panel, so they line up with it.

    blender -b --python tools/lambo/urus_pods.py -- car.blend urus_art.png pods.png out.blend

urus_art.png: cluster_live.compose at 3 px per design px. Writes pods.png (both gauges side by side).
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mesh_cut import delete_faces  # noqa: E402

import bmesh
import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1 :]
car, art, pods, out = args[0], args[1], args[2], args[3]
C = Vector((0.3945, -0.6775, 1.0603))
F = Vector((0, 0.994, 0.107)).normalized()
UP = (Vector((0, 0, 1)) - F * F.z).normalized()
MM = 0.00062  # metres per design pixel, as the panel
X0, Y0 = 92, 236  # the design's corner
CX = 372  # the design's middle
TOPV = 0.0509  # the height of design y 236 over C
BOX = (96, 268, 160, 362)  # the left gauge in design pixels; the right one is its mirror about x 372

# the picture
bpy.ops.wm.open_mainfile(filepath=car)
src = bpy.data.images.load(art)
W, H = src.size
import numpy as np  # noqa: E402

px = np.array(src.pixels[:]).reshape(H, W, 4)
K = W / 560
x0, y0, x1, y1 = [int(v) for v in ((BOX[0] - X0) * K, (BOX[1] - Y0) * K, (BOX[2] - X0) * K, (BOX[3] - Y0) * K)]
w, h = x1 - x0, y1 - y0
rx0 = int((744 - BOX[2] - X0) * K)
sheet = np.zeros((h, 2 * w, 4))
sheet[:, :w] = px[H - y1 : H - y0, x0:x1]
sheet[:, w:] = px[H - y1 : H - y0, rx0 : rx0 + w]
sheet[:, :, 3] = 1
img = bpy.data.images.new("urus_pods", 2 * w, h)
img.pixels.foreach_set(sheet.astype(np.float32).ravel())
img.filepath_raw = pods
img.file_format = "PNG"
img.save()
img.pack()

mat = bpy.data.materials.new("ClusterArt")
mat.use_nodes = True
b = mat.node_tree.nodes["Principled BSDF"]
tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
tex.image = img
tex.extension = "EXTEND"
mat.node_tree.links.new(tex.outputs["Color"], b.inputs["Base Color"])
mat.node_tree.links.new(tex.outputs["Color"], b.inputs["Emission Color"])
b.inputs["Emission Strength"].default_value = 1.0
b.inputs["Roughness"].default_value = 0.6

new = bpy.data.meshes.new("Body_ClusterArt")
nb = bmesh.new()
uvl = nb.loops.layers.uv.new("UVMap")
total = 0
for o in [x for x in bpy.data.objects if x.type == "MESH" and x.name.startswith("Body_")]:
    M = o.matrix_world
    rot = M.to_3x3()
    me = o.data
    take = []
    for p in me.polygons:
        c = M @ p.center
        d = (c - C).dot(F)
        v = (c - C).dot(UP)
        u = abs(c.x - C.x)
        n = (rot @ p.normal).normalized()
        if 0.118 < u < 0.19 and -0.036 < v < 0.06 and 0.004 < d < 0.034 and n.dot(F) > 0.3:
            take.append(p.index)
    if not take:
        continue
    for i in take:
        p = me.polygons[i]
        vs = [nb.verts.new(M @ me.vertices[k].co) for k in p.vertices]
        f = nb.faces.new(vs)
        left = (M @ p.center).x > C.x  # (+x is the driver's left)
        for l, vert in zip(f.loops, vs):
            q = vert.co - C
            dx = CX - q.x / MM  # (x falls to the driver's right)
            dy = Y0 + (TOPV - q.dot(UP)) / MM
            bx0 = BOX[0] if left else 744 - BOX[2]
            uu = (dx - bx0) / (BOX[2] - BOX[0])
            vv = (dy - BOX[1]) / (BOX[3] - BOX[1])
            l[uvl].uv = ((uu + (0 if left else 1)) / 2, 1 - vv)
    delete_faces(o, take)
    total += len(take)
    print("PODS took", o.name[:36], len(take))
nb.to_mesh(new)
nb.free()
new.materials.append(mat)
ob = bpy.data.objects.new("Body_ClusterArt", new)
bpy.context.scene.collection.objects.link(ob)
bpy.ops.wm.save_as_mainfile(filepath=out)
print("PODS saved", total)
