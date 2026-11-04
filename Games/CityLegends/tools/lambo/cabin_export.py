"""The pictures of a finished car's cabin parts as PNGs, and each part's colour factor (the game files tint
a grey picture; Studio's importer drops the tint, so cabins come in pale). tools/lambo/cabin_dark.py
darkens the pictures.

    blender -b --python tools/lambo/cabin_export.py -- car.blend car.pbr.json outdir
"""

import json
import os
import re
import sys

import bpy

args = sys.argv[sys.argv.index("--") + 1 :]
blend, table_path, outdir = args[0], args[1], args[2]
os.makedirs(outdir, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=blend)
parts = json.load(open(table_path))["parts"]
CABIN = ("Cabin", "CabinTile", "CabinTrim", "Suede", "Leather", "Belt", "Trim", "Forged", "Carbon", "Lamp", "Rim", "Tyre", "Brake", "Disc", "Grille", "Engine", "Base", "SoftTop")
rows = {}
saved = {}


def tint_of(b):
    """the constant colour multiplied into the base colour (the glTF factor), or None"""
    s = b.inputs["Base Color"]
    if not s.is_linked:
        return None
    n = s.links[0].from_node
    if n.type == "MIX" or n.type == "MIX_RGB":
        for i in n.inputs:
            if i.type == "RGBA" and not i.is_linked:
                c = list(i.default_value)[:3]
                if max(c) < 0.985:
                    return [round(v, 4) for v in c]
    return None


for o in bpy.data.objects:
    if o.type != "MESH" or o.name not in parts:
        continue
    e = parts[o.name]
    if e["role"] not in CABIN:
        continue
    m = next((x for x in o.data.materials if x), None)
    b = m.node_tree.nodes.get("Principled BSDF") if m and m.use_nodes else None
    if not b:
        continue
    img = None
    s = b.inputs["Base Color"]
    if s.is_linked:
        n = s.links[0].from_node
        for _ in range(4):
            if n.type == "TEX_IMAGE":
                img = n.image
                break
            nxt = next((i.links[0].from_node for i in n.inputs if i.is_linked), None)
            if nxt is None:
                break
            n = nxt
    row = {"role": e["role"], "base": img.name if img else None, "mat": m.name}
    rows[o.name] = row
    if img and img.name not in saved and img.size[0] >= 64 and not img.name.startswith("col_"):
        path = os.path.join(outdir, "b_%s.png" % re.sub(r"\W", "_", img.name))
        c = img.copy()
        c.filepath_raw = path
        c.file_format = "PNG"
        c.save()
        bpy.data.images.remove(c)
        saved[img.name] = os.path.basename(path)
json.dump({"parts": rows, "saved": saved}, open(os.path.join(outdir, "cabin.json"), "w"), indent=0)
print("CABIN", len(rows), len(saved))
