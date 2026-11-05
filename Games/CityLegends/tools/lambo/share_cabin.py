"""One car's whole cabin in another car of its family (owner, 2026-11-05, the LP650-4 Roadster: "use the
SV since interior is way better"). The target's cabin faces go; the donor's cabin faces and steering
wheel come in as new parts, moved by an offset. The roof lining stays behind (spec "top").

    blender -b --python tools/lambo/share_cabin.py -- target.blend donor.blend out.blend spec.json [--count]

spec.json:
  "box": [x0, y0, z0, x1, y1, z1]     the cabin; a face counts when its middle is inside
  "offset": [dx, dy, dz]              donor -> target (metres)
  "top": 0.99                         donor faces above this height stay behind
  "target_all": ["Body_interior"]     target parts deleted whole
  "target_box": ["Body_lights"]       target parts that lose the faces in the box
  "donor": ["Body_x.008"]             donor parts to take from (the faces in the box)
  "donor_keep": {"Body_x.002": [x0, y0, z0, x1, y1, z1]}   its own box for a part
  "paint": [{"material": "InteriorA", "rect": [x0, y0, x1, y1]}]   a mark off the donor's picture (pixels, top left 0, 0)
--count only prints how many faces of each part fall in the box.
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mesh_cut import delete_faces  # noqa: E402

import bmesh
import bpy
import numpy as np
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1 :]
target, donor, out, spec_path = args[0], args[1], args[2], args[3]
count_only = "--count" in args
spec = json.load(open(spec_path))
box = spec["box"]
offset = Vector(spec.get("offset", [0, 0, 0]))


def inside(p, b):
    return b[0] <= p.x <= b[3] and b[1] <= p.y <= b[4] and b[2] <= p.z <= b[5]


def faces_in(o, b, top=None):
    M = o.matrix_world
    out_ = []
    for f in o.data.polygons:
        c = M @ f.center
        if inside(c, b) and (top is None or c.z <= top):
            out_.append(f.index)
    return out_


if count_only:
    for path, label in ((target, "TARGET"), (donor, "DONOR")):
        bpy.ops.wm.open_mainfile(filepath=path)
        for o in sorted(bpy.data.objects, key=lambda x: x.name):
            if o.type != "MESH":
                continue
            n = len(faces_in(o, box))
            if n:
                print("CAB", label, o.name[:40], n, "of", len(o.data.polygons), (o.material_slots[0].material.name[-30:] if o.material_slots and o.material_slots[0].material else ""))
    sys.exit(0)

bpy.ops.wm.open_mainfile(filepath=target)
bpy.context.scene.tool_settings.mesh_select_mode = (False, False, True)

# the target's cabin goes
for name in spec.get("target_all", []):
    o = bpy.data.objects.get(name)
    if o:
        bpy.data.objects.remove(o)
for o in [x for x in bpy.data.objects if x.name.startswith("SteeringWheel")]:
    bpy.data.objects.remove(o)
for name in spec.get("target_box", []):
    o = bpy.data.objects.get(name)
    if o:
        idx = set(faces_in(o, box))
        delete_faces(o, idx)
        print("CAB gone", name, len(idx))

# the donor's come in
with bpy.data.libraries.load(donor, link=False) as (src, dst):
    dst.objects = [n for n in src.objects if n in spec["donor"] or n in spec.get("donor_keep", {}) or n.startswith("SteeringWheel")]
col = bpy.context.scene.collection
for o in dst.objects:
    if o is None:
        continue
    col.objects.link(o)
    o.parent = None
    wheel = o.name.startswith("SteeringWheel")
    if not wheel:
        b = spec.get("donor_keep", {}).get(o.name, box)
        keep = set(faces_in(o, b, spec.get("top")))
        drop = {f.index for f in o.data.polygons} - keep
        delete_faces(o, drop)
        if "top" in spec:  # (a cut along whole faces leaves a saw edge: the corners above come down to the line)
            inv = o.matrix_basis.inverted()
            for v in o.data.vertices:
                w = o.matrix_basis @ v.co
                if w.z > spec["top"]:
                    w.z = spec["top"]
                    v.co = inv @ w
        o.name = "Body_Cabin_" + str(len(keep))
    o.location = o.location + offset
    print("CAB in", o.name, len(o.data.polygons))

# marks off a picture that came with the donor: the rect takes the colour just above it
for c in spec.get("paint", []):
    img = None
    for m in bpy.data.materials:
        if c["material"].lower() in m.name.lower() and m.use_nodes:
            b = m.node_tree.nodes.get("Principled BSDF")
            s = b.inputs["Base Color"] if b else None
            if s and s.is_linked and s.links[0].from_node.type == "TEX_IMAGE":
                img = s.links[0].from_node.image
                break
    W, H = img.size
    px = np.array(img.pixels[:]).reshape(H, W, 4)
    x0, y0, x1, y1 = c["rect"]
    for x in range(x0, x1):
        px[H - y1 : H - y0, x, :3] = px[H - y0 + 1, x, :3]  # (rows run bottom up)
    img.pixels.foreach_set(px.astype(np.float32).ravel())
    img.update()
    img.pack()
    print("CAB painted", img.name, c["rect"])

bpy.ops.wm.save_as_mainfile(filepath=out)
print("CAB saved", out)
