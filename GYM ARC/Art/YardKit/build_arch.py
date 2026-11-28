# GYM ARC Winter Yard entrance arch (ChatGPT + Gemini round 2: "no ceremonial arrival"; 18 wide x 14 tall,
# candy columns, pine garland, gold baubles, red bows, sign board "WINTER YARD" = SurfaceGui added in Studio).
# Low-poly: 8-sided columns with one ring per stripe band (tilted 30 deg), flat shading, bevel on boxy parts only.
# Blender: x = across the path, y = depth (front = -y = towards the player walking in), z = up. Origin = ground centre.
import bpy, bmesh, math, os
HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\YardKit"
PAL = {"White": (244, 238, 226), "Red": (190, 35, 48), "Gold": (223, 182, 79), "Green": (36, 106, 62), "GreenLight": (57, 131, 79),
       "GreenDark": (22, 71, 46), "RedDark": (130, 20, 35), "Board": (158, 36, 49), "Wood": (92, 56, 34), "Snow": (231, 241, 250), "Stone": (158, 175, 192)}
G = {}; BEV = set()

def add(col, V, F, bevel=False):
    v_, f_ = G.setdefault(col, [[], []]); o = len(v_); v_ += V; f_ += [tuple(i + o for i in f) for f in F]
    if bevel: BEV.add(col)

def box(col, c, s, bevel=True):
    cx, cy, cz = c; sx, sy, sz = (v / 2 for v in s)
    V = [(cx + x * sx, cy + y * sy, cz + z * sz) for z in (-1, 1) for y in (-1, 1) for x in (-1, 1)]
    F = [(0, 2, 3, 1), (4, 5, 7, 6), (0, 1, 5, 4), (2, 6, 7, 3), (0, 4, 6, 2), (1, 3, 7, 5)]
    add(col, V, F, bevel)

def ringpts(cx, cy, z, r, n, tilt=0.0, rot=0.0):
    return [(cx + r * math.cos(2 * math.pi * k / n + rot), cy + r * math.sin(2 * math.pi * k / n + rot),
             z + math.tan(tilt) * r * math.cos(2 * math.pi * k / n + rot)) for k in range(n)]

def band(col, cx, cy, z0, z1, r, n=8, tilt=0.0, cap0=False, cap1=False, r1=None):
    A = ringpts(cx, cy, z0, r, n, tilt, math.pi / n); B = ringpts(cx, cy, z1, r if r1 is None else r1, n, tilt, math.pi / n)
    V = A + B; F = [(k, (k + 1) % n, n + (k + 1) % n, n + k) for k in range(n)]
    if cap0: F.append(tuple(reversed(range(n))))
    if cap1: F.append(tuple(range(n, 2 * n)))
    add(col, V, F)

def ball(col, c, r, n=6):
    # low octa-ish ball: 2 rings + poles
    cx, cy, cz = c; V = [(cx, cy, cz - r)]
    for z, rr in ((-0.45, 0.85), (0.45, 0.85)):
        V += [(cx + r * rr * math.cos(2 * math.pi * k / n + (z > 0) * math.pi / n), cy + r * rr * math.sin(2 * math.pi * k / n + (z > 0) * math.pi / n), cz + z * r) for k in range(n)]
    V.append((cx, cy, cz + r)); top = len(V) - 1
    F = [(0, 1 + (k + 1) % n, 1 + k) for k in range(n)]
    for k in range(n):
        a, b = 1 + k, 1 + (k + 1) % n; c_, d = 1 + n + k, 1 + n + (k + 1) % n
        F += [(a, b, d), (a, d, c_)]
    F += [(1 + n + k, 1 + n + (k + 1) % n, top) for k in range(n)]
    add(col, V, F)

def tube(col, pts, r, n=6):
    rings = []
    for i, p in enumerate(pts):
        a = pts[max(0, i - 1)]; b = pts[min(len(pts) - 1, i + 1)]
        t = [b[k] - a[k] for k in range(3)]; L = math.sqrt(sum(v * v for v in t)) or 1; t = [v / L for v in t]
        u = [0, 0, 1]; s = [t[1] * u[2] - t[2] * u[1], t[2] * u[0] - t[0] * u[2], t[0] * u[1] - t[1] * u[0]]
        Ls = math.sqrt(sum(v * v for v in s)) or 1; s = [v / Ls for v in s]
        w = [s[1] * t[2] - s[2] * t[1], s[2] * t[0] - s[0] * t[2], s[0] * t[1] - s[1] * t[0]]
        rings.append([tuple(p[k] + r * (math.cos(2 * math.pi * j / n) * s[k] + math.sin(2 * math.pi * j / n) * w[k]) for k in range(3)) for j in range(n)])
    V = [v for rg in rings for v in rg]; F = []
    for i in range(len(rings) - 1):
        F += [(i * n + j, i * n + (j + 1) % n, (i + 1) * n + (j + 1) % n, (i + 1) * n + j) for j in range(n)]
    F += [tuple(reversed(range(n))), tuple(range((len(rings) - 1) * n, len(rings) * n))]
    add(col, V, F)

CX = 8.6; H = 12.0; R = 0.85
for sx in (-1, 1):
    x = sx * CX
    box("Stone", (x, 0, 0.5), (2.6, 2.6, 1.0))
    box("Snow", (x, 0, 1.08), (2.7, 2.7, 0.16))
    box("Gold", (x, 0, 0.82), (2.72, 2.72, 0.16), bevel=False)
    z = 1.0; k = 0; tilt = math.radians(30)
    while z < H - 0.01:
        z1 = min(H, z + 1.1)
        band("Red" if k % 2 else "White", x, 0, z, z1, R, tilt=tilt if 0 < z1 < H else 0, cap0=(k == 0), cap1=(z1 >= H))
        z = z1; k += 1
    band("Gold", x, 0, H, H + 0.35, R + 0.15, cap0=True, cap1=True)
    ball("Gold", (x, 0, H + 1.0), 0.65)
# beam + sign board
box("Wood", (0, 0, H - 0.3), (2 * CX + 1.6, 1.1, 0.9))
box("Board", (0, -0.25, H + 1.9), (13.0, 0.4, 3.0))
for zz in (H + 0.4, H + 3.4):
    box("Gold", (0, -0.5, zz), (13.4, 0.2, 0.22))
for xx in (-6.6, 6.6):
    box("Gold", (xx, -0.5, H + 1.9), (0.22, 0.2, 3.2))
box("Snow", (0, -0.2, H + 3.55), (13.2, 0.7, 0.18))
# garland v2 (R3: "green pipe with cubes" -> overlapping faceted pine clumps in 3 greens), baubles on gold stems
import random; random.seed(3)
def clump(col, c, r):
    n = 6; cx, cy, cz = c; V = [(cx, cy, cz - r * 0.7)]
    for ring, (zf, rf) in enumerate(((-0.25, 1.0), (0.3, 0.8))):
        V += [(cx + r * rf * (1 + random.uniform(-0.18, 0.18)) * math.cos(2 * math.pi * k / n + ring * 0.5),
               cy + r * rf * (1 + random.uniform(-0.18, 0.18)) * math.sin(2 * math.pi * k / n + ring * 0.5),
               cz + zf * r + random.uniform(-0.08, 0.08)) for k in range(n)]
    V.append((cx, cy, cz + r * 0.75)); top = len(V) - 1
    F = [(0, 1 + (k + 1) % n, 1 + k) for k in range(n)]
    for k in range(n):
        a, b = 1 + k, 1 + (k + 1) % n; c_, d = 1 + n + k, 1 + n + (k + 1) % n
        F += [(a, b, d), (a, d, c_)]
    F += [(1 + n + k, 1 + n + (k + 1) % n, top) for k in range(n)]
    add(col, V, F)
sag = lambda x: H - 0.5 - 0.9 * math.sin(math.pi * (x + CX) / (2 * CX))
NC = 26
for i in range(NC):
    x = -CX + 2 * CX * i / (NC - 1)
    clump(("GreenDark", "Green", "GreenLight")[i % 3], (x, -0.75 + random.uniform(-0.12, 0.12), sag(x)), 0.62)
    if i % 2: clump(("Green", "GreenLight", "GreenDark")[i % 3], (x + 0.2, -1.05, sag(x) + 0.25), 0.42)
for k, x in enumerate((-6.2, -3.7, -1.2, 1.2, 3.7, 6.2)):
    z = sag(x) - 0.95; col = "Red" if k % 2 else "Gold"
    ball(col, (x, -1.0, z), 0.42)
    box("Gold", (x, -1.0, z + 0.55), (0.16, 0.16, 0.4), bevel=False)
    box("Gold", (x, -1.0, z + 0.4), (0.3, 0.3, 0.14), bevel=False)
# volumetric bows (R3: "flat"): two looped ribbon tubes, a knot and two tails per column top
def loop_pts(x, z, side):
    return [(x + side * (0.15 + 0.85 * (1 - math.cos(a)) / 2 * 1.3), -1.15 - 0.25 * math.sin(a), z + 0.55 * math.sin(a))
            for a in [2 * math.pi * k / 10 for k in range(11)]]
for sx in (-1, 1):
    x = sx * CX; z = H - 0.55
    for side in (-1, 1):
        tube("Red", loop_pts(x, z, side), 0.3, 5)
        tube("RedDark", [(x + side * 0.1, -1.2, z - 0.1), (x + side * 0.35, -1.25, z - 0.8), (x + side * 0.6, -1.2, z - 1.45)], 0.24, 4)
    ball("RedDark", (x, -1.3, z), 0.42)

for o_ in list(bpy.data.objects): bpy.data.objects.remove(o_, do_unlink=True)
sc = bpy.context.scene; tris = 0
for col, (V, F) in G.items():
    me = bpy.data.meshes.new("Arch_" + col); me.from_pydata(V, [], F); me.validate()
    bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new("Arch_" + col, me); sc.collection.objects.link(ob)
    m = bpy.data.materials.new("A_" + col); m.use_nodes = True; rgba = tuple(v / 255 for v in PAL[col]) + (1,)
    next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = rgba; m.diffuse_color = rgba
    me.materials.append(m)
    if col in BEV:
        b = ob.modifiers.new("Bevel", "BEVEL"); b.width = 0.06; b.segments = 2; b.limit_method = "ANGLE"
        b.angle_limit = math.radians(35); b.use_clamp_overlap = True
    for p in me.polygons: p.use_smooth = False
dg = bpy.context.evaluated_depsgraph_get()
for ob in sc.objects:
    tris += sum(len(p.vertices) - 2 for p in ob.evaluated_get(dg).to_mesh().polygons)
print("TRIS", tris)
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
cam.location = (6, -30, 9); cam.rotation_euler = (math.radians(86), 0, math.radians(11))
sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.light = "STUDIO"; sc.display.shading.color_type = "MATERIAL"
sc.render.resolution_x, sc.render.resolution_y = 900, 700
sc.render.filepath = os.path.join(HERE, "gate", "arch.png"); bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)
bpy.ops.export_scene.gltf(filepath=os.path.join(HERE, "YardArch.glb"), export_format="GLB", export_yup=True, export_apply=True)
