"""Print the bounding box (Blender axes, Z up) of the mesh in every .blend in a folder as JSON.
blender --background --factory-startup --python bbox_dump.py -- <folder> <out.json>
"""
import glob
import json
import os
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
folder, out = args[0], args[1]
result = {}
for path in sorted(glob.glob(os.path.join(folder, "*.blend"))):
    bpy.ops.wm.open_mainfile(filepath=path)
    obj = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
    pts = [obj.matrix_world @ v.co for v in obj.data.vertices]
    mn = [min(p[i] for p in pts) for i in range(3)]
    mx = [max(p[i] for p in pts) for i in range(3)]
    tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    result[os.path.splitext(os.path.basename(path))[0]] = {"min": mn, "max": mx, "tris": tris}
with open(out, "w") as f:
    json.dump(result, f, indent=1)
print("[bbox] wrote", out)
