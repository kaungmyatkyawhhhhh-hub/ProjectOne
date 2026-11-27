# GYM ARC giant candy cane, from turnaround_sheet.png (SIDE view x 128-462, y 35-922; one sheet with side, front, exploded).
# Headless: blender -b --factory-startup --python build_cane.py -> GiantCane.glb + gate/side.png
# 1 unit = 1 stud, 8 studs tall. Origin = bottom centre of the shaft. Hook curls toward +X.
import bpy, bmesh, math, os
from mathutils import Vector
HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\GiantCane"
S = 8.0 / (922 - 35)
CX, BOT = 192.5, 922                       # shaft centre line x, cane bottom y (sheet px)
P = lambda x, y: Vector(((x - CX) * S, 0, (BOT - y) * S))
R_TUBE = 57.5 * S
N = 16                                    # ring sides
PITCH = 150 * S                           # one red+white stripe pair along the length
COL = {"Red": (0.82, 0.07, 0.08, 1), "White": (0.97, 0.94, 0.90, 1), "Gold": (0.98, 0.72, 0.12, 1)}
V = {k: [] for k in COL}; F = {k: [] for k in COL}

def add(c, verts, faces):
    o = len(V[c]); V[c] += [tuple(v) for v in verts]; F[c] += [tuple(i + o for i in f) for f in faces]

# centre line: band top (y 827) up the shaft to the hook centre height, over the semicircle, down to the hook end (y 275)
HC = (298.0, 198.0); HR = 105.5
path = [P(CX, y) for y in range(827, 198, -24)] + [P(CX, 198)]
for i in range(1, 24):
    a = math.pi - math.pi * i / 24
    path.append(P(HC[0] + HR * math.cos(a), HC[1] - HR * math.sin(a)))
path += [P(403.5, y) for y in range(198, 276, 26)][:-1] + [P(403.5, 275)]
# frames (parallel transport, the cane lies in the XZ plane so the normal is simply +Y x tangent)
rings, svals, s = [], [], 0.0
for i, p in enumerate(path):
    t = (path[min(i + 1, len(path) - 1)] - path[max(i - 1, 0)]).normalized()
    nrm = Vector((0, 1, 0)).cross(t).normalized(); bi = t.cross(nrm)
    if i: s += (p - path[i - 1]).length
    svals.append(s)
    tw = 2 * math.pi * s / PITCH          # rings twist along the helix, so each stripe is a run of quads (clean diagonal edges)
    rings.append([p + (nrm * math.cos(tw + 2 * math.pi * k / N) + bi * math.sin(tw + 2 * math.pi * k / N)) * R_TUBE for k in range(N)])
# stripe colour per quad: helical bands
for i in range(len(rings) - 1):
    for k in range(N):
        c = "Red" if k < N // 2 else "White"
        add(c, [rings[i][k], rings[i][(k + 1) % N], rings[i + 1][(k + 1) % N], rings[i + 1][k]], [(0, 1, 2, 3)])
# flat white hook end cap, and a hidden cap inside the gold band
end = rings[-1]; add("White", end + [path[-1]], [(N, (k + 1) % N, k) for k in range(N)])
start = rings[0]; add("Red", start + [path[0]], [(N, k, (k + 1) % N) for k in range(N)])
# gold band (y 827-874, r 65) and red end cap (y 874-922, r 55, bevelled bottom)
def cyl(c, y0, y1, r, bevel=0.0):
    lo = [P(CX + r * math.cos(2 * math.pi * k / N), y0) + Vector((0, r * S * math.sin(2 * math.pi * k / N) - 0, 0)) for k in range(N)]
    lo = [Vector(((r * math.cos(2 * math.pi * k / N)) * S, r * S * math.sin(2 * math.pi * k / N), (BOT - y0) * S)) for k in range(N)]
    hi = [Vector((v.x, v.y, (BOT - y1) * S)) for v in lo]
    if bevel:
        hi2 = [Vector((v.x * (1 - bevel), v.y * (1 - bevel), (BOT - y1 + 10) * S)) for v in lo]
        hi = [Vector((v.x, v.y, (BOT - y1 + 10) * S + 10 * S * 0)) for v in lo]
        verts = lo + hi2 + [Vector((v.x * (1 - bevel), v.y * (1 - bevel), 0)) for v in lo]
        # ring lo (top) -> hi2 (just above bottom) -> bottom ring smaller
        verts = lo + [Vector((v.x, v.y, (BOT - y1 + 12) * S)) for v in lo] + [Vector((v.x * (1 - bevel), v.y * (1 - bevel), 0)) for v in lo]
        faces = [(k, (k + 1) % N, N + (k + 1) % N, N + k) for k in range(N)] + [(N + k, N + (k + 1) % N, 2 * N + (k + 1) % N, 2 * N + k) for k in range(N)]
        faces += [tuple(range(N - 1, -1, -1)), tuple(range(2 * N, 3 * N))]
        add(c, verts, faces); return
    add(c, lo + hi, [(k, (k + 1) % N, N + (k + 1) % N, N + k) for k in range(N)] + [tuple(range(N - 1, -1, -1)), tuple(range(N, 2 * N))])
cyl("Gold", 827, 874, 65)
cyl("Red", 874, 922, 55, bevel=0.18)

for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
sc = bpy.context.scene
objs = []
for c in COL:
    me = bpy.data.meshes.new("GC_" + c); me.from_pydata(V[c], [], F[c]); me.validate()
    bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(me); bm.free()
    for p in me.polygons: p.use_smooth = False
    o = bpy.data.objects.new(c, me); o["xmas_part"] = "cane"
    m = bpy.data.materials.new("GC_" + c); m.use_nodes = True
    next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = COL[c]; m.diffuse_color = COL[c]
    me.materials.append(m); sc.collection.objects.link(o); objs.append(o)
    print(c, sum(len(p.vertices) - 2 for p in me.polygons), "tris")
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
cam.data.type = "ORTHO"; cam.data.ortho_scale = 1024 * S   # ortho scale follows the longer side (1024 px)
cam.location = ((384 - CX) * S, -30, (BOT - 300) * S); cam.rotation_euler = (math.pi / 2, 0, 0)
sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.light = "FLAT"; sc.display.shading.color_type = "MATERIAL"
sc.render.film_transparent = True; sc.render.resolution_x, sc.render.resolution_y, sc.render.resolution_percentage = 768, 600, 100
# gate: the cane is 887 px tall, taller than the 600 px window -> render the full 1024 height instead
sc.render.resolution_y = 1024; cam.location.z = (BOT - 512) * S
sc.render.filepath = os.path.join(HERE, "gate", "side.png"); bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)
for o in sc.objects: o.select_set(o.get("xmas_part") == "cane")
bpy.ops.export_scene.gltf(filepath=os.path.join(HERE, "GiantCane.glb"), use_selection=True, export_format="GLB", export_yup=True)
print("glb", os.path.getsize(os.path.join(HERE, "GiantCane.glb")))
