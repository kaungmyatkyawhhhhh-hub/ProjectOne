"""A live cluster's picture on a flat panel in a car, where the game's SurfaceGui panel goes, and the numbers
CarSkin.CLUSTER_RECT needs. The model's own faces in a box can go first, so the panel shows through them
(the California's side screens stand in front of its dial).

    blender -b --python tools/lambo/panel_preview.py -- car.blend art.png out.blend spec.json

spec.json: {"c": [x, y, z], "n": [x, y, z],           a point and the way the cluster faces
            "u": 0.0, "v": 0.0, "d": 0.001,           the panel's middle from c: right, up, towards the driver (m)
            "w": 0.38, "h": 0.145,                    the panel's size (m)
            "open": {"r": 0.073, "u": 0.0, "v": 0.0, "d": [0.01, 0.04], "box": [u0, v0, u1, v1]}}
open: faces in the box and the depth range go, except inside radius r of (u, v).
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mesh_cut import delete_faces  # noqa: E402

import bmesh
import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1 :]
car, art, out = args[0], args[1], args[2]
spec = json.load(open(args[3]))
bpy.ops.wm.open_mainfile(filepath=car)
C = Vector(spec["c"])
F = Vector(spec["n"]).normalized()
UP = (Vector((0, 0, 1)) - F * F.z).normalized()
RIGHT = Vector((-1, 0, 0))  # the driver's right
RIGHT = (RIGHT - F * RIGHT.dot(F)).normalized()

gone = 0
if "open" in spec:
    o_ = spec["open"]
    u0, v0, u1, v1 = o_["box"]
    for o in [x for x in bpy.data.objects if x.type == "MESH" and x.name.startswith("Body_")]:
        M = o.matrix_world
        rot = M.to_3x3()
        take = []
        for p in o.data.polygons:
            c = M @ p.center
            q = c - C
            u, v, d = q.dot(RIGHT), q.dot(UP), q.dot(F)
            n = (rot @ p.normal).normalized()
            if u0 < u < u1 and v0 < v < v1 and o_["d"][0] < d < o_["d"][1] and abs(n.dot(F)) > o_.get("facing", 0.75):
                if (u - o_["u"]) ** 2 + (v - o_["v"]) ** 2 > o_["r"] ** 2:
                    take.append(p.index)
        if take:
            delete_faces(o, take)
            gone += len(take)
            print("PANEL opened", o.name[:36], len(take))

mid = C + RIGHT * spec["u"] + UP * spec["v"] + F * spec["d"]
w, h = spec["w"], spec["h"]
if art != "-":
    img = bpy.data.images.load(art)
    mat = bpy.data.materials.new("PanelPreview")
    mat.use_nodes = True
    b = mat.node_tree.nodes["Principled BSDF"]
    t = mat.node_tree.nodes.new("ShaderNodeTexImage")
    t.image = img
    t.extension = "CLIP"
    b.inputs["Base Color"].default_value = (0, 0, 0, 1)
    mat.node_tree.links.new(t.outputs["Color"], b.inputs["Emission Color"])
    mat.node_tree.links.new(t.outputs["Alpha"], b.inputs["Alpha"])
    b.inputs["Emission Strength"].default_value = 1.0
    b.inputs["Roughness"].default_value = 1.0
    b.inputs["Specular IOR Level"].default_value = 0.0  # (a screen in the game has no shine)
    me = bpy.data.meshes.new("PanelPreview")
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    vs = [bm.verts.new(mid + RIGHT * a * w / 2 + UP * c * h / 2) for a, c in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    f = bm.faces.new(vs)
    for l, uv in zip(f.loops, ((0, 0), (1, 0), (1, 1), (0, 1))):
        l[uvl].uv = uv
    bm.to_mesh(me)
    bm.free()
    me.materials.append(mat)
    ob = bpy.data.objects.new("PanelPreview", me)
    bpy.context.scene.collection.objects.link(ob)
bpy.ops.wm.save_as_mainfile(filepath=out)
print("PANEL middle", [round(x, 4) for x in mid], "normal", [round(x, 3) for x in F], "w", w, "h", h, "faces gone", gone)
