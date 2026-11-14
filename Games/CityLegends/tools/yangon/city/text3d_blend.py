"""text3d_blend.py: 3D letter meshes for landmark names, made with Blender's text objects (headless).

    blender -b --factory-startup --python text3d_blend.py -- out.json "MYANMAR CENTRE" "MYANMAR PLAZA" ...

Each string becomes a solid extruded mesh in a unit frame: x along the text from 0, z up from the baseline with the
capital height = 1, y = depth from 0 (front face) to 1 (back) (scale them when placing). Written as JSON:
{ text: {"w": width, "tris": [[x, y, z] * 3, ...]} }, triangles counter-clockwise seen from outside.
Font: Arial Bold (C:/Windows/Fonts/arialbd.ttf); a different one per string with "text@font_path".
"""
import json
import sys

import bpy
import bmesh

args = sys.argv[sys.argv.index("--") + 1:]
out = args[0]
res = {}
for spec in args[1:]:
    text, _, font = spec.partition("@")
    font = font or "C:/Windows/Fonts/arialbd.ttf"
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    cu = bpy.data.curves.new("t", "FONT")
    cu.body = text
    cu.font = bpy.data.fonts.load(font)
    cu.size = 1.0
    cu.extrude = 0.5
    cu.resolution_u = 3
    ob = bpy.data.objects.new("t", cu)
    bpy.context.scene.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.convert(target="MESH")
    me = ob.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])  # outward, so Roblox (front faces only) shows them
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bm.normal_update()
    # measure the capital height on an "H" to normalise
    xs = [v.co.x for v in bm.verts]
    zs = [v.co.y for v in bm.verts]  # Blender text lies in XY, extruded along Z
    cap = max(zs)  # caps-only names: the top of the letters
    x0 = min(xs)
    tris = []
    for f in bm.faces:
        pts = []
        for v in f.verts:
            # text x -> x, text y (up) -> z, extrude z (-0.5..0.5, +z toward the viewer) -> y (front 0 .. back 1)
            pts.append([round((v.co.x - x0) / cap, 4), round((0.5 - v.co.z), 4), round(v.co.y / cap, 4)])
        # the mapping (x, y, z) -> (x, -z', y) keeps handedness? x->x, y->z, z->-y: a rotation about x by +90 deg: yes.
        tris.append(pts)
    res[text] = {"w": round((max(xs) - x0) / cap, 4), "tris": tris}
    bm.free()
json.dump(res, open(out, "w"))
print("texts", {k: (v["w"], len(v["tris"])) for k, v in res.items()})
