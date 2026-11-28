# GYM ARC giant candy cane, LOW-POLY STYLE (owner 28 Nov: faceted paper-craft look, like the reference cane in
# lowpoly_reference.png): 8 sides, rings tilted so every stripe is a whole diagonal band of flat facets, 2 ring
# segments per band, small seeded jitter so facets catch light differently. Same path/size as build_cane.py.
# Headless: blender -b --factory-startup --python build_cane_lowpoly.py -> GiantCane_lp2.glb + gate/side_lp2.png
import bpy, bmesh, math, os, random
from mathutils import Vector
HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\GiantCane"
random.seed(7)
# v2 (owner 28 Nov, 2nd note: "the reference image saves more triangles"): like the reference, the straight shaft has ONE
# ring per stripe (long flat quads, no zig-zag triangles, no jitter), 6 sides, strongly tilted bands; extra rings only
# where the hook bends; each stripe stays one colour across its segments.
S = 8.0 / (922 - 35)
CX, BOT = 192.5, 922
P = lambda x, y: Vector(((x - CX) * S, 0, (BOT - y) * S))
R = 57.5 * S
N = 8
BAND = 125 * S
TILT = math.radians(30)
COL = {"Red": (0.84, 0.16, 0.13, 1), "White": (0.96, 0.92, 0.86, 1), "Gold": (0.98, 0.72, 0.12, 1)}
V = {k: [] for k in COL}; F = {k: [] for k in COL}
def add(c, verts, faces):
    o = len(V[c]); V[c] += [tuple(v) for v in verts]; F[c] += [tuple(i + o for i in f) for f in faces]
HC = (298.0, 198.0); HR = 105.5
dense, hookflag = [], []
for y in range(827, 198, -2): dense.append(P(CX, y)); hookflag.append(False)
for i in range(0, 181):
    a_ = math.pi - math.pi * i / 180
    dense.append(P(HC[0] + HR * math.cos(a_), HC[1] - HR * math.sin(a_))); hookflag.append(True)
for y in range(200, 276, 2): dense.append(P(403.5, y)); hookflag.append(True)
L = [0.0]
for i in range(1, len(dense)): L.append(L[-1] + (dense[i] - dense[i - 1]).length)
# stations: every BAND on the shaft, every BAND/2 round the hook (curvature), always at band edges
hook0 = L[hookflag.index(True)]
st = [0.0]; s_ = 0.0
while True:
    nxt = s_ + (BAND if s_ + BAND <= hook0 + 1e-6 else BAND / 2)
    if s_ < hook0 < nxt - 1e-6: nxt = min(nxt, hook0 + 0.0) if hook0 - s_ > BAND * 0.3 else nxt
    if nxt >= L[-1] - BAND * 0.2: st.append(L[-1]); break
    st.append(nxt); s_ = nxt
def at(sv):
    j = max(0, min(len(L) - 2, next((i for i in range(len(L) - 1) if L[i + 1] >= sv), len(L) - 2)))
    f = (sv - L[j]) / max(1e-9, L[j + 1] - L[j]); return dense[j].lerp(dense[j + 1], min(1, max(0, f))), (dense[j + 1] - dense[j]).normalized(), hookflag[j]
rings, path, cols = [], [], []
for i, sv in enumerate(st):
    p, t, hk = at(sv)
    nrm = Vector((0, 1, 0)).cross(t).normalized(); bi = t.cross(nrm)
    end = i in (0, len(st) - 1)
    tw = 0.5                              # fixed half-step offset (a twist per station looked wobbly)
    rings.append([p + (nrm * math.cos(2 * math.pi * (k + tw) / N) + bi * math.sin(2 * math.pi * (k + tw) / N)) * R
                  + t * (0 if end else R * math.tan(TILT) * math.sin(2 * math.pi * k / N + 0.0)) for k in range(N)])
    path.append(p)
for i in range(len(rings) - 1):
    c = "Red" if int((st[i] + 1e-6) // BAND) % 2 == 0 else "White"
    A, B = rings[i], rings[i + 1]
    for k in range(N): add(c, [A[k], A[(k + 1) % N], B[(k + 1) % N], B[k]], [(0, 1, 2, 3)])
tdir = (path[-1] - path[-2]).normalized(); end = rings[-1]; mid = [path[-1] + (v - path[-1]) * 0.7 + tdir * R * 0.45 for v in end]
lastc = "Red" if int((st[-2] + 1e-6) // BAND) % 2 == 0 else "White"
for k in range(N): add(lastc, [end[k], end[(k + 1) % N], mid[(k + 1) % N], mid[k]], [(0, 1, 2, 3)])
add(lastc, mid + [path[-1] + tdir * R * 0.7], [(N, (k + 1) % N, k) for k in range(N)])
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
sc.render.filepath = os.path.join(HERE, "gate", "side_lp2.png"); bpy.ops.render.render(write_still=True)
# 3/4 look render
cam.data.type = "PERSP"; cam.location = Vector((9, -12, 6)); cam.rotation_euler = (Vector((0.8, 0, 4.3)) - cam.location).to_track_quat("-Z", "Y").to_euler()
sc.render.filepath = os.path.join(HERE, "gate", "look_lp2.png"); bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)
for o in sc.objects: o.select_set(o.get("xmas_part") == "cane")
bpy.ops.export_scene.gltf(filepath=os.path.join(HERE, "GiantCane_lp2.glb"), use_selection=True, export_format="GLB", export_yup=True)
print("glb", os.path.getsize(os.path.join(HERE, "GiantCane_lp2.glb")))
