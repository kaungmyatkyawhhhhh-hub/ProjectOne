import bpy, sys, json, math, collections
from mathutils import Vector
args = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.open_mainfile(filepath=args[0])
dials = json.loads(open(args[1]).read())
for kind, (c, r, n) in dials.items():
    c = Vector(c); n = Vector(n).normalized()
    h = collections.defaultdict(lambda: collections.Counter())
    for o in bpy.data.objects:
        if o.type != "MESH" or o.name.startswith(("SteeringWheel", "Needle_")): continue
        mw = o.matrix_world
        for p in o.data.polygons:
            q = mw @ p.center
            d = q - c
            a = d.dot(n)
            rad = (d - n * a).length / r
            if rad < 1.6 and abs(a) < 0.04:
                m = o.data.materials[p.material_index].name if o.data.materials else "?"
                h[m][(round(rad * 10) / 10, round(a * 1000 / 4) * 4)] += 1
    print("==", kind, "r", r)
    for m, cnt in h.items():
        byr = collections.Counter()
        for (rr, aa), v in cnt.items(): byr[rr] += v
        zs = collections.defaultdict(list)
        for (rr, aa), v in cnt.items(): zs[rr].append(aa)
        print("  ", m[:40], " ".join(f"{rr:.1f}:{byr[rr]}[{min(zs[rr])},{max(zs[rr])}]" for rr in sorted(byr)))
