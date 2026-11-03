import bpy, sys
args = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.open_mainfile(filepath=args[0])
for o in sorted(bpy.data.objects, key=lambda o: o.name):
    if o.type == "MESH":
        n = o.name.lower()
        if any(w in n for w in ("red", "tail", "light", "lamp", "brake", "emis", "glass")):
            pts = [o.matrix_world @ v.co for v in o.data.vertices]
            ymin = min(p.y for p in pts); ymax = max(p.y for p in pts)
            print("N", o.name, len(o.data.polygons), round(ymin, 2), round(ymax, 2))
