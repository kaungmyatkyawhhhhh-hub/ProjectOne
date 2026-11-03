import bpy, sys
from mathutils import Vector
args = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.open_mainfile(filepath=args[0])
lo = Vector([float(v) for v in args[1].split(",")]); hi = Vector([float(v) for v in args[2].split(",")])
for o in bpy.data.objects:
    if o.type != "MESH": continue
    mw = o.matrix_world
    n = 0; ys = []
    for p in o.data.polygons:
        c = mw @ p.center
        if all(lo[i] <= c[i] <= hi[i] for i in range(3)):
            n += 1; ys.append(c.y)
    if n:
        print("F", o.name, o.data.materials[0].name if o.data.materials else "", n, "y", round(min(ys), 3), round(max(ys), 3))
