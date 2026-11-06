"""Plain colours on a converted car whose .glb had no pictures or came with grey placeholders (the Maybach GLS: a
game mod's file without its textures). Each material whose name holds a word gets a colour: its tiny col_ picture is
refilled, or a new one made.

    blender -b --python tools/lambo/recolour.py -- in.blend out.blend spec.json

spec: {"colours": {"word in the material's name": [r, g, b] (0-255), ...}}   first match by longest word
"""

import json
import sys

import bpy

args = sys.argv[sys.argv.index("--") + 1 :]
bpy.ops.wm.open_mainfile(filepath=args[0])
spec = json.load(open(args[2]))["colours"]
words = sorted(spec, key=len, reverse=True)
done = {}


def linear(c):
    c /= 255.0
    return c / 12.92 if c < 0.04045 else ((c + 0.055) / 1.055) ** 2.4


for m in bpy.data.materials:
    n = m.name.lower()
    w = next((x for x in words if x in n), None)
    if not w or not m.use_nodes:
        continue
    r, g, b = spec[w]
    bsdf = next((k for k in m.node_tree.nodes if k.type == "BSDF_PRINCIPLED"), None)
    if not bsdf:
        continue
    col = (linear(r), linear(g), linear(b), 1.0)
    bsdf.inputs["Base Color"].default_value = col
    link = bsdf.inputs["Base Color"].links[0] if bsdf.inputs["Base Color"].is_linked else None
    img = link.from_node.image if link and link.from_node.type == "TEX_IMAGE" else None
    name = "col_" + m.name.replace(".", "_")[:24]
    new = bpy.data.images.new(name, 8, 8)
    new.colorspace_settings.name = "sRGB"
    new.pixels = [r / 255.0, g / 255.0, b / 255.0, 1.0] * 64
    new.pack()
    if img is not None:
        link.from_node.image = new
    else:
        t = m.node_tree.nodes.new("ShaderNodeTexImage")
        t.image = new
        m.node_tree.links.new(t.outputs["Color"], bsdf.inputs["Base Color"])
    done[m.name] = w
bpy.ops.wm.save_as_mainfile(filepath=args[1])
print("RECOLOUR", len(done))
