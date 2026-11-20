"""nisun_r34 between auto_car and finish_car: one object per material for the body (the cabin came out as one
multi-material part and finish_car names a part by its first material), the FR tyre auto_car left in the body,
the stray caliper bits.  blender -b in.blend --python nisun_r34_fix.py -- out.blend"""
import bpy, sys
out = sys.argv[sys.argv.index("--") + 1]
O = bpy.data.objects


def only(objs):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]


# the wheels first (names are what the game spins)
O["Body_r34_tyre"].name = "FR_r34_tyre"
only([O["FR_static_r34_caliper"], O["FR_r34_caliper"]]); bpy.ops.object.join()
for n in ("FL_r34_caliper", "Body_Fixed_r34_grill"):
    bpy.data.objects.remove(O[n])
# the body: split by material, then one object per material
for o in [o for o in O if o.type == "MESH" and o.name.startswith("Body_") and len(o.data.materials) > 1]:
    only([o]); bpy.ops.mesh.separate(type="MATERIAL")
by = {}
for o in [o for o in O if o.type == "MESH" and o.name.startswith("Body_")]:
    used = {p.material_index for p in o.data.polygons}
    if len(o.data.polygons) == 0:
        bpy.data.objects.remove(o); continue
    m = o.data.materials[used.pop()]
    by.setdefault(m.name, []).append(o)
for name, objs in by.items():
    only(objs)
    if len(objs) > 1:
        bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active
    for i in reversed(range(len(o.data.materials))):  # drop the unused slots: finish_car reads slot 0
        if o.data.materials[i].name != name:
            o.data.materials.pop(index=i)
    o.name = o.data.name = "Body_" + name
for o in sorted([o for o in O if o.type == "MESH"], key=lambda o: o.name):
    print("FIX", o.name, len(o.data.polygons), [m.name for m in o.data.materials])
bpy.ops.wm.save_as_mainfile(filepath=out)
