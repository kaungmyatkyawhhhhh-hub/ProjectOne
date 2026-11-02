"""The colour textures of a converted car (.blend from auto_car.py / cut_pieces.py), for when an
Import 3D came in without them: each image saved as a PNG, plus a list of which part wears which
(part name without Blender's ".001" ending, its size in Studio axes, the image file).

    blender -b --python tools/car_textures.py -- car.blend outdir

outdir/parts.json: [{"name": ..., "size": [x, y, z], "image": "Image_14.png"}, ...]
Sizes are metres as Import 3D gives them (Studio X = Blender x, Y = Blender z, Z = Blender y).
"""

import json
import os
import re
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1 :]
blend, outdir = args[0], args[1]
os.makedirs(outdir, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=blend)


def base_image(mat):
    if not mat or not mat.use_nodes:
        return None
    b = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if not b or not b.inputs["Base Color"].links:
        return None
    src = b.inputs["Base Color"].links[0].from_node
    return src.image if src.type == "TEX_IMAGE" else None


saved = {}
parts = []
for o in bpy.data.objects:
    if o.type != "MESH":
        continue
    img = base_image(o.active_material or (o.data.materials[0] if o.data.materials else None))
    if img is None:
        continue
    if img.name not in saved:
        # the image's own bytes (packed from the .glb): no colour management in the way
        data = img.packed_file.data if img.packed_file else open(bpy.path.abspath(img.filepath), "rb").read()
        ext = ".jpg" if data[:2] == bytes([0xFF, 0xD8]) else ".png"
        fname = re.sub(r"[^A-Za-z0-9_]+", "_", img.name) + ext
        open(os.path.join(outdir, fname), "wb").write(data)
        saved[img.name] = fname
    corners = [o.matrix_world @ Vector(c) for c in o.bound_box]
    lo = Vector(map(min, *corners))
    hi = Vector(map(max, *corners))
    d = hi - lo
    parts.append({"name": re.sub(r"\.\d{3}$", "", o.name), "size": [round(d.x, 4), round(d.z, 4), round(d.y, 4)], "image": saved[img.name]})
json.dump(parts, open(os.path.join(outdir, "parts.json"), "w"), indent=1)
print("images", len(saved), "parts", len(parts))
