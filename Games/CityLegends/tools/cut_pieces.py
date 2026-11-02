"""Removes loose pieces (badge letters, model names standing off the body) from a converted car
(.blend from auto_car.py). A piece goes when all of it lies inside one of the boxes given for its
part (metres, the car's own layout: front -Y, up +Z, ground 0).

    blender -b --python tools/cut_pieces.py -- in.blend out.blend cuts.json

cuts.json: [{"part": "Body_A_PLAS_BLACK", "box": [x0, y0, z0, x1, y1, z1], "mirror": true,
              "into": "Body_MAIN_PAINT"}, ...]
("mirror": the same box on the other side, x flipped; "into": instead of deleting, the pieces move
into that part and take its material: for letters inlaid in the body, whose removal would leave a
hole)
An entry {"rename": {"Body_MAIN_PINT": "Body_MAIN_PAINT"}} renames parts (Legends Customs paints the
parts whose names say paint / colour, and treats "stripe" as the second colour).
{"clean_names": "<regex>", "match": "Lamborghini"}: parts named after the maker (game-file material names) are renamed
from their material with that pattern taken out, keeping the "Body_" / "FL_static_" start.
"""

import json
import re
import sys

import bmesh
import bpy
import numpy as np

args = sys.argv[sys.argv.index("--") + 1 :]
src, out, spec = args[0], args[1], json.load(open(args[2]))
bpy.ops.wm.open_mainfile(filepath=src)
removed = {}
for cut in spec:
    if "clean_names" in cut:
        pat = re.compile(cut["clean_names"])
        for o in list(bpy.data.objects):
            if o.type != "MESH" or not re.search(cut.get("match", "Lamborghini"), o.name):
                continue
            m = o.data.materials[0] if o.data.materials else None
            start = re.match(r"^((?:Body|FL|FR|RL|RR|SeeThrough)(?:_static)?_)", o.name)
            core = pat.sub("", m.name if m else o.name)
            core = re.sub(r"[^A-Za-z0-9]+", "_", core).strip("_")[:24] or "Part"
            o.name = (start.group(1) if start else "") + core
        for m in bpy.data.materials:
            if re.search(cut.get("match", "Lamborghini"), m.name):
                m.name = re.sub(r"[^A-Za-z0-9]+", "_", pat.sub("", m.name)).strip("_")[:40] or "Material"
        continue
    if "rename" in cut:
        for a, b in cut["rename"].items():
            if bpy.data.objects.get(a):
                bpy.data.objects[a].name = b
        continue
    o = bpy.data.objects.get(cut["part"])
    if o is None:
        print("no part", cut["part"])
        continue
    boxes = [cut["box"]]
    if cut.get("mirror"):
        b = cut["box"]
        boxes.append([-b[3], b[1], b[2], -b[0], b[4], b[5]])
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bm.verts.ensure_lookup_table()
    M = o.matrix_world
    co = np.array([tuple(M @ v.co) for v in bm.verts])
    seen = np.zeros(len(bm.verts), bool)
    kill = []
    for v in bm.verts:
        if seen[v.index]:
            continue
        stack, comp = [v], []
        seen[v.index] = True
        while stack:
            x = stack.pop()
            comp.append(x.index)
            for e in x.link_edges:
                y = e.other_vert(x)
                if not seen[y.index]:
                    seen[y.index] = True
                    stack.append(y)
        p = co[comp]
        lo, hi = p.min(0), p.max(0)
        for b in boxes:
            if np.all(lo >= np.array(b[:3])) and np.all(hi <= np.array(b[3:])):
                kill.extend(comp)
                break
    into = bpy.data.objects.get(cut.get("into", "")) if cut.get("into") else None
    if into is not None and kill:
        # a copy of the pieces in the target part, with the target's material
        keep = set(kill)
        nb = bm.copy()
        nb.verts.ensure_lookup_table()
        bmesh.ops.delete(nb, geom=[v for v in nb.verts if v.index not in keep], context="VERTS")
        for f in nb.faces:
            f.material_index = 0
        me = bpy.data.meshes.new("moved")
        nb.to_mesh(me)
        nb.free()
        piece = bpy.data.objects.new("moved", me)
        bpy.context.scene.collection.objects.link(piece)
        piece.matrix_world = o.matrix_world
        piece.data.materials.clear()
        for m in into.data.materials:
            piece.data.materials.append(m)
        bpy.ops.object.select_all(action="DESELECT")
        piece.select_set(True)
        into.select_set(True)
        bpy.context.view_layer.objects.active = into
        bpy.ops.object.join()
    bmesh.ops.delete(bm, geom=[bm.verts[i] for i in kill], context="VERTS")
    bm.to_mesh(o.data)
    bm.free()
    removed[cut["part"]] = removed.get(cut["part"], 0) + len(kill)
bpy.ops.wm.save_as_mainfile(filepath=out)
print("removed vertices", removed)
