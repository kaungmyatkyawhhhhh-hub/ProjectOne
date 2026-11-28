# GYM ARC giant candy cane, LOW-POLY STYLE (owner 28 Nov: faceted paper-craft look, like the reference cane in
# lowpoly_reference.png): 8 sides, rings tilted so every stripe is a whole diagonal band of flat facets, 2 ring
# segments per band, small seeded jitter so facets catch light differently. Same path/size as build_cane.py.
# Headless: blender -b --factory-startup --python build_cane_lowpoly.py -> GiantCane_lp.glb + gate/side_lp.png
import bpy, bmesh, math, os, random
from mathutils import Vector
HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\GiantCane"
random.seed(7)
S = 8.0 / (922 - 35)
CX, BOT = 192.5, 922
P = lambda x, y: Vector(((x - CX) * S, 0, (BOT - y) * S))
R = 57.5 * S
N = 8
BAND = 118 * S          # one stripe width along the cane (about one diameter, like the reference)
TILT = math.radians(32)
JIT = 0.06 * R
COL = {"Red": (0.84, 0.16, 0.13, 1), "White": (0.96, 0.92, 0.86, 1), "Gold": (0.98, 0.72, 0.12, 1)}
V = {k: [] for k in COL}; F = {k: [] for k in COL}
def add(c, verts, faces):
    o = len(V[c]); V[c] += [tuple(v) for v in verts]; F[c] += [tuple(i + o for i in f) for f in faces]

# dense centre line, then resample every BAND/2
HC = (298.0, 198.0); HR = 105.5
dense = [P(CX, y) for y in range(827, 198, -4)] + [P(CX, 198)]
for i in range(1, 120):
    a = math.pi - math.pi * i / 120
    dense.append(P(HC[0] + HR * math.cos(a), HC[1] - HR * math.sin(a)))
dense += [P(403.5, y) for y in range(198, 276, 4)]
L = [0.0]
for i in range(1, len(dense)): L.append(L[-1] + (dense[i] - dense[i - 1]).length)
step = BAND / 2; nseg = max(2, round(L[-1] / step)); step = L[-1] / nseg
path, j = [], 0
for k in range(nseg + 1):
    s = k * step
    while j < len(dense) - 2 and L[j + 1] < s: j += 1
    f = (s - L[j]) / max(1e-9, L[j + 1] - L[j]); path.append(dense[j].lerp(dense[j + 1], min(1, f)))
rings = []
for i, p in enumerate(path):
    t = (path[min(i + 1, len(path) - 1)] - path[max(i - 1, 0)]).normalized()
    nrm = Vector((0, 1, 0)).cross(t).normalized(); bi = t.cross(nrm)
    end = i in (0, len(path) - 1)
    ring = []
    for k in range(N):
        a = 2 * math.pi * (k + 0.5 * (i % 2)) / N        # stagger alternate rings -> triangle facets, not boxy quads
        off = 0 if end else R * math.tan(TILT) * math.sin(a)
        j3 = Vector(((random.random() - .5), (random.random() - .5), (random.random() - .5))) * (0 if end else JIT)
        ring.append(p + (nrm * math.cos(a) + bi * math.sin(a)) * R + t * off + j3)
    rings.append(ring)
for i in range(len(rings) - 1):
    c = "Red" if (i // 2) % 2 == 0 else "White"
    a, b = rings[i], rings[i + 1]
    for k in range(N):
        if i % 2 == 0: add(c, [a[k], a[(k + 1) % N], b[k]], [(0, 1, 2)]); add(c, [a[(k + 1) % N], b[(k + 1) % N], b[k]], [(0, 1, 2)])
        else: add(c, [a[k], b[(k + 1) % N], b[k]], [(0, 1, 2)]); add(c, [a[k], a[(k + 1) % N], b[(k + 1) % N]], [(0, 1, 2)])
end = rings[-1]; add("White", end + [path[-1] + (path[-1] - path[-2]).normalized() * R * 0.35], [(N, (k + 1) % N, k) for k in range(N)])
start = rings[0]; add("Red", start + [path[0]], [(N, k, (k + 1) % N) for k in range(N)])
def ring_at(r, y, rot=0.0): return [Vector((r * S * math.cos(2 * math.pi * k / N + rot), r * S * math.sin(2 * math.pi * k / N + rot), (BOT - y) * S)) for k in range(N)]
def tube(c, rs):
    vs = [v for r in rs for v in r]; fs = []
    for i in range(len(rs) - 1):
        for k in range(N): fs.append((i * N + k, i * N + (k + 1) % N, (i + 1) * N + (k + 1) % N, (i + 1) * N + k))
    fs += [tuple(range(N - 1, -1, -1)), tuple(range((len(rs) - 1) * N, len(rs) * N))]
    add(c, vs, fs)
tube("Gold", [ring_at(65, 827), ring_at(68, 850), ring_at(65, 874)])
tube("Red", [ring_at(55, 874), ring_at(57, 905), ring_at(44, 922)])

for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
sc = bpy.context.scene; tot = 0
for c in COL:
    me = bpy.data.meshes.new("GC_" + c); me.from_pydata(V[c], [], F[c]); me.validate()
    bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(me); bm.free()
    for p in me.polygons: p.use_smooth = False
    o = bpy.data.objects.new(c, me); o["xmas_part"] = "cane"
    m = bpy.data.materials.new("GC_" + c); m.use_nodes = True
    next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = COL[c]; m.diffuse_color = COL[c]
    me.materials.append(m); sc.collection.objects.link(o)
    n = sum(len(p.vertices) - 2 for p in me.polygons); tot += n; print(c, n, "tris")
print("total", tot)
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
cam.data.type = "ORTHO"; cam.data.ortho_scale = 1024 * S
cam.location = ((384 - CX) * S, -30, (BOT - 512) * S); cam.rotation_euler = (math.pi / 2, 0, 0)
sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.light = "STUDIO"; sc.display.shading.color_type = "MATERIAL"
sc.render.film_transparent = True; sc.render.resolution_x, sc.render.resolution_y, sc.render.resolution_percentage = 768, 1024, 100
sc.render.filepath = os.path.join(HERE, "gate", "side_lp.png"); bpy.ops.render.render(write_still=True)
# 3/4 look render
cam.data.type = "PERSP"; cam.location = (9, -9, 5); cam.rotation_euler = (math.radians(72), 0, math.radians(45))
sc.render.filepath = os.path.join(HERE, "gate", "look_lp.png"); bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)
for o in sc.objects: o.select_set(o.get("xmas_part") == "cane")
bpy.ops.export_scene.gltf(filepath=os.path.join(HERE, "GiantCane_lp.glb"), use_selection=True, export_format="GLB", export_yup=True)
print("glb", os.path.getsize(os.path.join(HERE, "GiantCane_lp.glb")))
