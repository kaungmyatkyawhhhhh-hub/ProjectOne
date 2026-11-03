import bpy, sys
from mathutils import Vector
args = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=args[0])
objs = [o for o in bpy.data.objects if o.type == "MESH"]
lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
info = []
for o in objs:
    pts = [o.matrix_world @ Vector(v) for v in o.bound_box]
    a = Vector(map(min, *pts)); b = Vector(map(max, *pts))
    lo = Vector(map(min, lo, a)); hi = Vector(map(max, hi, b))
    info.append((o, a, b))
size = hi - lo
la = 0 if size.x > size.y else 1
sa = 1 - la
print("BOUNDS", tuple(round(v, 3) for v in lo), tuple(round(v, 3) for v in hi), "length axis", "xy"[la])
L = size[la]
for o, a, b in info:
    c = (a + b) / 2; s = b - a
    nearEnd = min(abs(c[la] - lo[la]), abs(c[la] - hi[la])) < 0.12 * L
    central = abs(c[sa] - (lo[sa] + hi[sa]) / 2) < 0.12 * size[sa]
    small = max(s) < 0.2 * L
    if nearEnd and central and small:
        mats = [m.name for m in o.data.materials if m]
        print("P", o.name[:70], "size", tuple(round(v / L * 4.5, 3) for v in s), "end", "lo" if abs(c[la] - lo[la]) < abs(c[la] - hi[la]) else "hi", "up", round((c.z - lo.z) / L * 4.5, 2), "tris", len(o.data.polygons), mats[:2])
