# Blender: depth + material map across the SVJ cluster bezel, in the cluster plane (game frame)
import bpy, sys, json, math
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
out, at, face = argv[0], json.loads(argv[1]), json.loads(argv[2])
steer = [o for o in bpy.data.objects if o.name.startswith("SteeringWheel")]
lo = Vector((1e9,)*3); hi = Vector((-1e9,)*3)
for o in steer:
    for v in o.bound_box:
        w = o.matrix_world @ Vector(v)
        lo = Vector(map(min, lo, w)); hi = Vector(map(max, hi, w))
c = (lo + hi) / 2
for o in steer:
    o.hide_viewport = True
def g2b(v):  # game (right, up, back) -> blender (x, y, z)
    return Vector((-v[0], v[2], v[1]))
F = g2b(face).normalized()
centre = c + g2b(at)
upV = (Vector((0, 0, 1)) - F * F.z).normalized()
rightV = upV.cross(F)  # check below
dg = bpy.context.evaluated_depsgraph_get()
STEP = 0.002
U = int(0.7 / STEP); V = int(0.34 / STEP)
rows = []
mats = {}
for j in range(V):
    v = 0.17 - j * STEP
    row = []
    for i in range(U):
        u = -0.35 + i * STEP
        p = centre + rightV * u + upV * v + F * 0.08
        ok, loc, nor, idx, obj, mat = bpy.context.scene.ray_cast(dg, p, -F, distance=0.3)
        if ok:
            d = (loc - centre).dot(F)  # + = towards the driver
            mname = ""
            if obj.material_slots and obj.data.polygons:
                mi = obj.data.polygons[idx].material_index if idx < len(obj.data.polygons) else 0
                if mi < len(obj.material_slots) and obj.material_slots[mi].material:
                    mname = obj.material_slots[mi].material.name
            k = mats.setdefault(obj.name + "|" + mname, len(mats))
            row.append([round(d, 4), k])
        else:
            row.append([None, -1])
    rows.append(row)
json.dump({"step": STEP, "u0": -0.35, "v0": 0.17, "rows": rows, "mats": mats, "c": list(c), "rightV": list(rightV)}, open(out, "w"))
print("probe done", U, V, "right", tuple(round(x, 3) for x in rightV))
