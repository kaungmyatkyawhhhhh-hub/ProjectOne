"""carbon_split.py -- in.blend out.blend: Body_Carbon cut in two: the cabin's carbon (dash strip, console, door strips, seat
shells: loose pieces lying wholly inside the cabin box) becomes Body_CabinCarbon, so it can be matt (a glossy part inside
the cabin mirrors the sky: a white band on the dash); the outside carbon (roof, mirrors, lip, diffuser) stays Body_Carbon.
The file keeps only these two and Body_Base (a small pack to swap them in CarModels)."""
import bpy, sys, bmesh
import numpy as np
a = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.open_mainfile(filepath=a[0])
BOX = (-0.80, -0.95, 0.30, 0.80, 1.50, 1.28)
src = bpy.data.objects["Body_Carbon"]
M = src.matrix_world
bm = bmesh.new(); bm.from_mesh(src.data); bm.faces.ensure_lookup_table()
seen, inside = set(), set()
rows = []
for f in bm.faces:
    if f.index in seen: continue
    st, comp = [f], []; seen.add(f.index)
    while st:
        g = st.pop(); comp.append(g)
        for e in g.edges:
            for h in e.link_faces:
                if h.index not in seen: seen.add(h.index); st.append(h)
    P = np.array([list(M @ v.co) for g in comp for v in g.verts])
    lo, hi = P.min(0), P.max(0)
    isin = lo[0] >= BOX[0] and lo[1] >= BOX[1] and lo[2] >= BOX[2] and hi[0] <= BOX[3] and hi[1] <= BOX[4] and hi[2] <= BOX[5]
    if isin: inside.update(g.index for g in comp)
    rows.append((len(comp), isin, ((lo + hi) / 2).round(2).tolist(), (hi - lo).round(2).tolist()))
bm.free()
for r in sorted(rows, key=lambda r: -r[0])[:40]: print("ISL", r)
print("CARBON faces", len(src.data.polygons), "inside", len(inside), "pieces", len(rows), "inside pieces", sum(1 for r in rows if r[1]))
def part(name, keep_inside):
    o = src.copy(); o.data = src.data.copy(); o.name = name; o.data.name = name
    bpy.context.scene.collection.objects.link(o)
    b = bmesh.new(); b.from_mesh(o.data); b.faces.ensure_lookup_table()
    kill = [f for f in b.faces if (f.index in inside) != keep_inside]
    bmesh.ops.delete(b, geom=kill, context="FACES")
    b.to_mesh(o.data); b.free(); o.data.update()
    for ca in o.data.color_attributes:
        k = len(ca.data); arr = np.zeros(k * 4, dtype=np.float32); ca.data.foreach_get("color", arr)
        arr = arr.reshape(-1, 4); arr[:, 3] = 1.0; ca.data.foreach_set("color", arr.reshape(-1))
    return o
cab = part("Body_CabinCarbon", True)
out = part("Body_Carbon_out", False)
bpy.data.objects.remove(src, do_unlink=True)
out.name = "Body_Carbon"; out.data.name = "Body_Carbon"
for o in list(bpy.data.objects):
    if o.type == "MESH" and o.name not in ("Body_Carbon", "Body_CabinCarbon", "Body_Base"):
        bpy.data.objects.remove(o, do_unlink=True)
for o in bpy.data.objects:
    if o.type == "MESH":
        cs = [o.matrix_world @ v.co for v in o.data.vertices]
        lo = [min(c[i] for c in cs) for i in range(3)]; hi = [max(c[i] for c in cs) for i in range(3)]
        print("PART", o.name, len(o.data.polygons), "size", [round(hi[i] - lo[i], 4) for i in range(3)], "mid", [round((hi[i] + lo[i]) / 2, 4) for i in range(3)])
bpy.ops.wm.save_as_mainfile(filepath=a[1])
