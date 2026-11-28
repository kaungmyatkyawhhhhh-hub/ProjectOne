# GYM ARC Winter Yard prop kit (owner 28 Nov: "so messy & so little stuff"; ChatGPT 4.8 / Gemini 3.5 asked for
# medium 3-7 stud props). Faceted LOW-POLY (6-8 sided, flat shading) + rounded corners via a Bevel modifier
# (owner: "corners rounded like how the blender model artists do"). Front of every prop = Blender +Y (= Roblox -Z).
# One glb, objects named <Prop>_<Colour>; Kit_Ref / Kit_RefX markers give the import yaw.
# Headless: blender -b --factory-startup --python build_yardkit.py -> YardKit.glb + gate/kit.png
import bpy, math, os, random
from mathutils import Vector, Euler, Matrix
HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\YardKit"
random.seed(11)
PAL = {"Red": (181, 44, 61), "White": (240, 244, 248), "Green": (36, 125, 69), "Gold": (223, 182, 79),
       "Wood": (135, 85, 54), "WoodDark": (92, 56, 34), "Iron": (25, 43, 39), "Navy": (16, 29, 53),
       "Frost": (96, 205, 235), "Crystal": (160, 228, 250), "Black": (30, 30, 34), "Orange": (235, 120, 40),
       "Blue": (55, 130, 210), "Snow": (232, 240, 249), "Ref": (255, 0, 255)}
G = {}  # (prop,col) -> [verts, faces]

def add(prop, col, verts, faces):
    k = (prop, col); V, F = G.setdefault(k, [[], []]); o = len(V)
    V += [tuple(v) for v in verts]; F += [tuple(i + o for i in f) for f in faces]

def xf(vs, loc=(0, 0, 0), rot=(0, 0, 0)):
    M = Euler(rot).to_matrix(); L = Vector(loc)
    return [M @ Vector(v) + L for v in vs]

def box(p, c, loc, size, rot=(0, 0, 0)):
    x, y, z = (s / 2 for s in size)
    vs = [(-x, -y, -z), (x, -y, -z), (x, y, -z), (-x, y, -z), (-x, -y, z), (x, -y, z), (x, y, z), (-x, y, z)]
    add(p, c, xf(vs, loc, rot), [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)])

def cyl(p, c, loc, r, h, n=8, r2=None, rot=(0, 0, 0), phase=0.0):
    r2 = r if r2 is None else r2
    ring = lambda rr, z: [(rr * math.cos(2 * math.pi * k / n + phase), rr * math.sin(2 * math.pi * k / n + phase), z) for k in range(n)]
    if r2 <= 1e-6:
        vs = ring(r, -h / 2) + [(0, 0, h / 2)]
        fs = [tuple(range(n - 1, -1, -1))] + [(k, (k + 1) % n, n) for k in range(n)]
    else:
        vs = ring(r, -h / 2) + ring(r2, h / 2)
        fs = [tuple(range(n - 1, -1, -1)), tuple(range(n, 2 * n))] + [(k, (k + 1) % n, n + (k + 1) % n, n + k) for k in range(n)]
    add(p, c, xf(vs, loc, rot), fs)

def sphere(p, c, loc, r, n=8, m=5, s=(1, 1, 1), jit=0.0, rot=(0, 0, 0), flat_bottom=None):
    vs = [(0, 0, -r)]
    for j in range(1, m):
        th = math.pi * j / m - math.pi / 2
        for k in range(n):
            a = 2 * math.pi * k / n + (j % 2) * math.pi / n
            q = r * (1 + random.uniform(-jit, jit))
            vs.append((q * math.cos(th) * math.cos(a), q * math.cos(th) * math.sin(a), q * math.sin(th)))
    vs.append((0, 0, r))
    vs = [(x * s[0], y * s[1], max(z * s[2], flat_bottom) if flat_bottom is not None else z * s[2]) for x, y, z in vs]
    fs = [(0, 1 + (k + 1) % n, 1 + k) for k in range(n)]
    for j in range(m - 2):
        a0, b0 = 1 + j * n, 1 + (j + 1) * n
        for k in range(n):
            if j % 2 == 0: fs += [(a0 + k, a0 + (k + 1) % n, b0 + k), (a0 + (k + 1) % n, b0 + (k + 1) % n, b0 + k)]
            else: fs += [(a0 + k, a0 + (k + 1) % n, b0 + (k + 1) % n), (a0 + k, b0 + (k + 1) % n, b0 + k)]
    top = len(vs) - 1; a0 = 1 + (m - 2) * n
    fs += [(a0 + k, a0 + (k + 1) % n, top) for k in range(n)]
    add(p, c, xf(vs, loc, rot), fs)

def prism(p, c, pts, depth, loc=(0, 0, 0), rot=(0, 0, 0)):
    # polygon pts in local XZ plane, extruded along Y (thickness)
    n = len(pts); d = depth / 2
    vs = [(x, -d, z) for x, z in pts] + [(x, d, z) for x, z in pts]
    fs = [tuple(range(n)), tuple(range(2 * n - 1, n - 1, -1))] + [(k, n + k, n + (k + 1) % n, (k + 1) % n) for k in range(n)]
    add(p, c, xf(vs, loc, rot), fs)

def tube(p, cols, pts, r, n=6):
    # straight segments between pts, colour per segment (cycled) - candy stripes
    for i in range(len(pts) - 1):
        a, b = Vector(pts[i]), Vector(pts[i + 1]); d = b - a
        rot = d.to_track_quat("Z", "Y").to_euler()
        cyl(p, cols[i % len(cols)], tuple((a + b) / 2), r, d.length, n, rot=tuple(rot))

OX = {}
def at(name, i): OX[name] = (i * 16.0, 0.0); return Vector((i * 16.0, 0, 0))

# 1 Snowman spotter (5.6 tall, red sweatband + mini dumbbell)
o = at("Snowman", 0); P = "Snowman"
sphere(P, "Snow", o + Vector((0, 0, 1.25)), 1.45, 8, 5, s=(1, 1, 0.86), jit=0.04, flat_bottom=-1.0)
sphere(P, "Snow", o + Vector((0, 0, 3.05)), 1.05, 8, 5, jit=0.04)
sphere(P, "Snow", o + Vector((0, 0, 4.55)), 0.78, 8, 5, jit=0.03)
cyl(P, "Red", o + Vector((0, 0, 4.85)), 0.8, 0.22, 8)                       # sweatband
cyl(P, "Orange", o + Vector((0, 0.95, 4.55)), 0.13, 0.7, 6, r2=0.0, rot=(-math.pi / 2, 0, 0))  # carrot
for sx in (-0.28, 0.28): sphere(P, "Black", o + Vector((sx, 0.7, 4.75)), 0.09, 5, 3)
for z in (2.7, 3.15, 3.6): sphere(P, "Black", o + Vector((0, 1.03, z - 0.25)), 0.1, 5, 3)
cyl(P, "Red", o + Vector((0, 0, 3.95)), 0.86, 0.3, 8)                       # scarf
box(P, "Red", o + Vector((0.45, 0.72, 3.35)), (0.32, 0.12, 0.9), (0.2, 0, 0.15))
for sx in (-1, 1):                                                          # stick arms
    tube(P, ["WoodDark"], [o + Vector((sx * 0.95, 0, 3.2)), o + Vector((sx * 1.9, 0.2, 3.9))], 0.08, 5)
# dumbbell in the right hand
h = o + Vector((1.95, 0.25, 3.95)); cyl(P, "Iron", h, 0.07, 1.0, 6, rot=(0, 0, math.pi / 2))
for sx in (-0.45, 0.45): cyl(P, "Iron", h + Vector((0, sx, 0)), 0.32, 0.22, 6, rot=(math.pi / 2, 0, 0))

# 2 Bench (6 wide, seat 1.6)
o = at("Bench", 1); P = "Bench"
for i, y in enumerate((-0.45, 0.0, 0.45)): box(P, "Wood", o + Vector((0, y, 1.6)), (6.0, 0.4, 0.16))
for z in (2.35, 2.9): box(P, "Wood", o + Vector((0, -0.78, z)), (6.0, 0.14, 0.38), (-0.18, 0, 0))
for sx in (-2.5, 2.5):
    box(P, "Iron", o + Vector((sx, 0.35, 0.8)), (0.22, 0.22, 1.6)); box(P, "Iron", o + Vector((sx, -0.6, 1.5)), (0.22, 0.22, 3.0))
    box(P, "Iron", o + Vector((sx, -0.1, 1.45)), (0.24, 1.2, 0.2))
box(P, "Snow", o + Vector((-0.8, 0.05, 1.74)), (2.4, 1.1, 0.14))

# 3 Sleigh (7 x 3.4) with 2 gifts
o = at("Sleigh", 2); P = "Sleigh"
prof = [(-3.4, 0.8), (-3.5, 2.7), (-2.7, 2.8), (-2.3, 1.8), (1.6, 1.8), (2.5, 2.3), (3.3, 2.9), (3.7, 2.4), (3.4, 1.4), (2.7, 0.8)]
prism(P, "Red", prof, 3.2, o, (0, 0, math.pi / 2))
box(P, "Gold", o + Vector((0, 0.0, 1.85)), (3.3, 4.6, 0.12))
box(P, "WoodDark", o + Vector((0, -1.2, 2.05)), (2.6, 1.4, 0.35))
for sx in (-1.35, 1.35):
    pts = [o + Vector((sx, y, z)) for y, z in ((-3.6, 0.2), (-1.5, 0.12), (1.5, 0.12), (3.4, 0.35), (4.0, 1.0), (3.7, 1.6))]
    tube(P, ["Gold"], pts, 0.13, 6)
    for y in (-2.0, 1.8): box(P, "Gold", o + Vector((sx, y, 0.5)), (0.14, 0.14, 0.75))
box(P, "Green", o + Vector((-0.5, 0.6, 2.55)), (1.3, 1.3, 1.3), (0, 0, 0.3)); box(P, "Gold", o + Vector((-0.5, 0.6, 2.55)), (1.36, 0.3, 1.36), (0, 0, 0.3))
box(P, "Blue", o + Vector((0.7, 0.9, 2.35)), (1.0, 1.0, 0.9), (0, 0, -0.2)); box(P, "White", o + Vector((0.7, 0.9, 2.35)), (0.24, 1.06, 0.96), (0, 0, -0.2))

# 4 North-Pole signpost (7.5 tall, 3 arrow boards)
o = at("Signpost", 3); P = "Signpost"
cyl(P, "Wood", o + Vector((0, 0, 3.6)), 0.26, 7.2, 6)
sphere(P, "Snow", o + Vector((0, 0, 7.25)), 0.38, 6, 3, s=(1, 1, 0.55))
sphere(P, "Snow", o + Vector((0, 0, 0.15)), 0.9, 7, 3, s=(1, 1, 0.35), flat_bottom=0.0)
arrow = [(-2.2, -0.42), (1.9, -0.42), (2.4, 0.0), (1.9, 0.42), (-2.2, 0.42)]
for i, (z, yaw) in enumerate(((6.4, 0.0), (5.3, math.pi * 0.75), (4.2, -0.6))):
    prism(P, "WoodDark", arrow, 0.16, o + Vector((0, 0, z)), (0, 0, yaw))

# 5 Ice crystal cluster (~3.5 tall)
o = at("Crystals", 4); P = "Crystals"
for i, (x, y, hh, r, tx, ty) in enumerate(((0, 0, 3.0, 0.55, 0, 0), (0.8, 0.3, 2.0, 0.42, 0.35, 0), (-0.75, 0.2, 2.2, 0.45, -0.3, 0.1),
                                             (0.2, -0.75, 1.6, 0.36, 0, 0.35), (-0.3, 0.8, 1.3, 0.32, -0.1, -0.35))):
    col = "Crystal" if i % 2 == 0 else "Frost"
    base = o + Vector((x, y, 0)); rot = (ty, tx, i * 0.4); M = Euler(rot).to_matrix()
    cyl(P, col, base + M @ Vector((0, 0, hh * 0.35)), r, hh * 0.7, 6, rot=rot)
    cyl(P, col, base + M @ Vector((0, 0, hh * 0.85)), r, hh * 0.3, 6, r2=0.0, rot=rot)
sphere(P, "Snow", o + Vector((0, 0, 0.1)), 1.5, 7, 3, s=(1, 1, 0.25), jit=0.08, flat_bottom=0.0)

# 6 Gift stack (3 boxes)
o = at("Gifts", 5); P = "Gifts"
for (x, y, z, s, c, rc, yaw) in ((0, 0, 0.75, 1.5, "Red", "Gold", 0.2), (1.25, 0.3, 0.5, 1.0, "Green", "White", -0.3), (0.1, 0.05, 1.95, 0.9, "Blue", "Gold", 0.7)):
    base = o + Vector((x, y, z)); box(P, c, base, (s, s, s), (0, 0, yaw))
    box(P, rc, base, (s * 1.04, s * 0.2, s * 1.04), (0, 0, yaw)); box(P, rc, base, (s * 0.2, s * 1.04, s * 1.04), (0, 0, yaw))
    for a in (0.7, -0.7):
        sphere(P, rc, base + Vector((0, 0, s / 2 + 0.12)), s * 0.22, 6, 3, s=(1.4, 0.6, 0.8), rot=(0, 0, yaw + a))

# 7 Snowbank (flattened faceted blob, 4 x 2.6 x 0.9)
o = at("Snowbank", 6); P = "Snowbank"
sphere(P, "Snow", o, 1.0, 9, 4, s=(2.2, 1.4, 0.9), jit=0.12, flat_bottom=-0.05)
sphere(P, "Snow", o + Vector((1.2, 0.4, 0)), 1.0, 8, 4, s=(1.2, 1.0, 0.65), jit=0.12, flat_bottom=-0.05)

# 8 Candy-cane barbell on a wooden rack (6 wide)
o = at("Barbell", 7); P = "Barbell"
for sx in (-2.2, 2.2):
    box(P, "Wood", o + Vector((sx, 0, 1.2)), (0.35, 0.35, 2.4)); box(P, "Wood", o + Vector((sx, 0, 0.12)), (0.5, 1.8, 0.24))
    box(P, "WoodDark", o + Vector((sx, 0.25, 2.25)), (0.4, 0.2, 0.5))
pts = [o + Vector((x, 0.05, 2.45)) for x in [-3.2 + i * 0.8 for i in range(9)]]
tube(P, ["Red", "White"], pts, 0.1, 6)
for sx in (-2.7, 2.7):
    c0 = o + Vector((sx, 0.05, 2.45))
    for k in range(8):
        a0, a1 = 2 * math.pi * k / 8, 2 * math.pi * (k + 1) / 8
        tri = [(0, 0), (1.0 * math.cos(a0), 1.0 * math.sin(a0)), (1.0 * math.cos(a1), 1.0 * math.sin(a1))]
        prism(P, "Red" if k % 2 == 0 else "White", tri, 0.3, c0, (0, 0, math.pi / 2))
    cyl(P, "White", c0, 0.3, 0.34, 8, rot=(0, math.pi / 2, 0))

# 9 Banner (navy cloth, gold trim, snowflake; 7 tall)
o = at("Banner", 8); P = "Banner"
cyl(P, "Iron", o + Vector((0, 0, 3.5)), 0.13, 7.0, 6); cyl(P, "Gold", o + Vector((0, 0, 7.15)), 0.22, 0.4, 6, r2=0.0)
box(P, "Gold", o + Vector((0, 0.18, 6.55)), (2.3, 0.14, 0.14))
cloth = [(-1.0, 6.45), (1.0, 6.45), (1.0, 2.6), (0.0, 2.0), (-1.0, 2.6)]
prism(P, "Navy", cloth, 0.1, o + Vector((0, 0.2, 0)))
trim = [(-1.08, 6.5), (1.08, 6.5), (1.08, 2.55), (0.0, 1.9), (-1.08, 2.55)]
prism(P, "Gold", trim, 0.06, o + Vector((0, 0.16, 0)))
for a in (0, math.pi / 3, -math.pi / 3): box(P, "White", o + Vector((0, 0.27, 4.4)), (0.14, 0.06, 1.5), (0, a, 0))

# 10 Candy-cane crate
o = at("CaneCrate", 9); P = "CaneCrate"
box(P, "Wood", o + Vector((0, 0, 0.7)), (2.4, 1.6, 1.4))
for z in (0.25, 1.15): box(P, "WoodDark", o + Vector((0, 0, z)), (2.46, 1.66, 0.22))
for i, (x, y) in enumerate(((-0.7, -0.3), (-0.2, 0.3), (0.35, -0.25), (0.8, 0.25), (0.05, 0.0))):
    b = o + Vector((x, y, 1.3)); tube(P, ["Red", "White"], [b + Vector((0, 0, k * 0.3)) for k in range(5)] + [b + Vector((0.25, 0, 1.45)), b + Vector((0.45, 0, 1.15))], 0.09, 6)

# 11 Frozen ice dumbbell (lying in snow)
o = at("IceDumbbell", 10); P = "IceDumbbell"
cyl(P, "Iron", o + Vector((0, 0, 0.55)), 0.12, 2.2, 6, rot=(0, math.pi / 2, 0))
for sx in (-1.05, 1.05): cyl(P, "Crystal", o + Vector((sx, 0, 0.55)), 0.62, 0.7, 6, rot=(0, math.pi / 2, 0))
sphere(P, "Snow", o + Vector((0, 0, 0.05)), 1.0, 7, 3, s=(1.8, 1.1, 0.25), jit=0.1, flat_bottom=0.0)

# yaw markers
cyl("KitRef", "Ref", Vector((0, -30, 0)), 0.3, 0.3, 4); cyl("KitRefX", "Ref", Vector((100, -30, 0)), 0.3, 0.3, 3)

# bevel only the boxy pieces (round tubes/spheres just multiply triangles)
BEVEL = {"Bench_Wood", "Bench_Iron", "Sleigh_Red", "Sleigh_WoodDark", "Sleigh_Green", "Sleigh_Blue", "Signpost_WoodDark",
         "Gifts_Red", "Gifts_Green", "Gifts_Blue", "Barbell_Wood", "Barbell_WoodDark", "Banner_Navy", "CaneCrate_Wood",
         "CaneCrate_WoodDark", "Crystals_Crystal", "Crystals_Frost", "IceDumbbell_Crystal"}
for o_ in list(bpy.data.objects): bpy.data.objects.remove(o_, do_unlink=True)
sc = bpy.context.scene; mats = {}; tot = 0
for (prop, col), (V, F) in G.items():
    me = bpy.data.meshes.new(f"{prop}_{col}"); me.from_pydata(V, [], F); me.validate()
    for pl in me.polygons: pl.use_smooth = False
    name = f"{prop}_{col}" if not prop.startswith("KitRef") else prop
    ob = bpy.data.objects.new(name, me); sc.collection.objects.link(ob)
    if col not in mats:
        m = bpy.data.materials.new("K_" + col); m.use_nodes = True; rgba = tuple(v / 255 for v in PAL[col]) + (1,)
        next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = rgba; m.diffuse_color = rgba; mats[col] = m
    me.materials.append(mats[col])
    if f"{prop}_{col}" in BEVEL:
        bv = ob.modifiers.new("Bevel", "BEVEL"); bv.width = 0.05 if prop in ("Snowman", "Snowbank") else 0.06
        bv.segments = 2; bv.limit_method = "ANGLE"; bv.angle_limit = math.radians(35); bv.use_clamp_overlap = True
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get(); ev = ob.evaluated_get(dg); em = ev.to_mesh()
    n = sum(len(p.vertices) - 2 for p in em.polygons); ev.to_mesh_clear(); tot += n
    print(f"{name}: {n} tris")
print("TOTAL", tot)
# preview render
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
cam.data.lens = 50
sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.light = "STUDIO"; sc.display.shading.color_type = "MATERIAL"
sc.render.resolution_x, sc.render.resolution_y = 400, 400; sc.render.film_transparent = False
sc.world = bpy.data.worlds.new("W") if sc.world is None else sc.world
for name, (x0, _) in OX.items():
    cam.location = Vector((x0 + 7, 9, 5.5)); cam.rotation_euler = (Vector((x0, 0, 2.0)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(HERE, "gate", f"p_{name}.png"); bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)
bpy.ops.export_scene.gltf(filepath=os.path.join(HERE, "YardKit.glb"), export_format="GLB", export_yup=True, export_apply=True)
print("glb", os.path.getsize(os.path.join(HERE, "YardKit.glb")))
