import bpy, sys, json, re
sys.path.insert(0, "/tmp/claude-0/logo")
from helpers import colour_at
from mathutils import Vector
blend, car, out = sys.argv[-3], sys.argv[-2], sys.argv[-1]
bpy.ops.wm.open_mainfile(filepath=blend)
objs = [o for o in bpy.data.objects if o.type == "MESH"]
lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
for o in objs:
    for v in o.bound_box:
        p = o.matrix_world @ Vector(v); lo = Vector(map(min, lo, p)); hi = Vector(map(max, hi, p))
L = hi.y - lo.y
wc = [bpy.data.objects[k].matrix_world.translation for k in ("FL", "FR", "RL", "RR") if k in bpy.data.objects]
res = []
NAME = re.compile(r"tail|brake|stop|back_?l|rear_?l|rearlight|backlight|taillight", re.I)
for o in objs:
    if o.name.startswith(("FL", "FR", "RL", "RR", "SteeringWheel")):
        continue
    me = o.data; M = o.matrix_world
    tot = 0; rear = 0; reds = 0; samples = 0; acc = [0, 0, 0]
    for p in me.polygons:
        c = M @ p.center
        tot += p.area
        if c.y > hi.y - 0.16 * L and c.z > lo.z + 0.25:
            rear += p.area
            if samples < 400 and (len(me.polygons) < 400 or p.index % max(1, len(me.polygons) // 400) == 0):
                col = colour_at(o, c, p.index)
                if col:
                    samples += 1
                    if col[0] > 0.3 and col[0] > 1.8 * col[1] and col[0] > 1.8 * col[2]:
                        reds += 1
    if tot == 0: continue
    frac = rear / tot
    redf = reds / samples if samples else 0
    named = bool(NAME.search(o.name)) or any(m and NAME.search(m.name) for m in me.materials)
    if (frac > 0.5 and (redf > 0.3 or named)) or (named and frac > 0.3):
        d = o.dimensions
        res.append({"name": o.name, "rearFrac": round(frac, 2), "red": round(redf, 2), "named": named, "dims": [round(d.x, 4), round(d.z, 4), round(d.y, 4)]})
json.dump({"car": car, "parts": res}, open(out, "w"), indent=1)
print("TAIL", car, [(r["name"], r["rearFrac"], r["red"], r["named"]) for r in res])
