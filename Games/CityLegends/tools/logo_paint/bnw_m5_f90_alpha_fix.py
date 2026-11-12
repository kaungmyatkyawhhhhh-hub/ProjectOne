"""alpha_fix.py -- in.blend out.blend [only]: the vertex colours' alpha set to 1 on every mesh (this rip's corner colours
carry alpha 0: Roblox uses it once a part is see-through, so the glass and the red lenses were invisible in the game).
With "only": the file keeps just the SeeThrough_* parts and Body_Base (a small pack to swap the glass in CarModels)."""
import bpy, sys
import numpy as np
a = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.open_mainfile(filepath=a[0])
only = len(a) > 2 and a[2] == "only"
n = 0
for o in list(bpy.data.objects):
    if o.type != "MESH": continue
    if only and not (o.name.startswith("SeeThrough") or o.name == "Body_Base"):
        bpy.data.objects.remove(o, do_unlink=True); continue
    for ca in o.data.color_attributes:
        k = len(ca.data)
        arr = np.zeros(k * 4, dtype=np.float32); ca.data.foreach_get("color", arr)
        arr = arr.reshape(-1, 4); arr[:, 3] = 1.0
        ca.data.foreach_set("color", arr.reshape(-1)); n += 1
    o.data.update()
print("ALPHAFIX layers", n, "objects", len([o for o in bpy.data.objects if o.type == "MESH"]))
bpy.ops.wm.save_as_mainfile(filepath=a[1])
