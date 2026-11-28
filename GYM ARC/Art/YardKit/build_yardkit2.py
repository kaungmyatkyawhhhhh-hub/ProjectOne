# GYM ARC Winter Yard prop kit 2 (generated from build_yardkit.py header + props2.py; rebuild with build_yardkit2.py)
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

# YardKit2 props (ChatGPT R4 8.2 / Gemini 8.0 -> R5): remodelled sleigh, signature candy-cane barbell display,
# irregular snow drifts, one premium volumetric bow (reused on lamps), two gift-cluster variants, tree snow cap.
# Spliced into build_yardkit2.py between the kit helpers and the export tail.
PAL.update({"Burgundy": (120, 28, 40), "RedDark": (130, 20, 35)})

# 0 Sleigh v2: curved side panels, raised rear, curled front, continuous gold runners with struts, burgundy cushion, 5 gifts
o = at("Sleigh2", 0); P = "Sleigh2"
side = [(-3.3, 0.7), (2.4, 0.7), (3.1, 1.0), (3.5, 1.7), (3.5, 2.5), (3.15, 2.85), (2.8, 2.6), (2.7, 2.0), (2.0, 1.75),
        (0.2, 1.8), (-1.2, 2.2), (-2.2, 3.0), (-3.0, 3.4), (-3.4, 3.2)]
for y in (-1.45, 1.45):
    prism(P, "Red", side, 0.28, o + Vector((0, y, 0)))
box(P, "Red", o + Vector((-0.1, 0, 0.85)), (6.4, 2.9, 0.3))                       # floor
box(P, "Red", o + Vector((3.25, 0, 1.7)), (0.3, 2.9, 1.6), (0, -0.35, 0))           # front panel
box(P, "Red", o + Vector((-3.2, 0, 2.2)), (0.3, 2.9, 2.6), (0, 0.2, 0))             # back panel
# gold trim along the top edge of each side panel
top = [(3.5, 2.5), (3.15, 2.85), (2.8, 2.6), (2.7, 2.0), (2.0, 1.75), (0.2, 1.8), (-1.2, 2.2), (-2.2, 3.0), (-3.0, 3.4), (-3.4, 3.2)]
for y in (-1.6, 1.6):
    tube(P, ["Gold"], [(x, y, z + 0.06) for x, z in top], 0.1, 6)
# runners: continuous curve, curled front, with 3 struts each
run = [(-3.5, 0.15), (-2.0, 0.12), (0.0, 0.12), (2.0, 0.14), (3.2, 0.3), (3.9, 0.8), (4.1, 1.5), (3.8, 2.0), (3.4, 2.0)]
for y in (-1.25, 1.25):
    tube(P, ["Gold"], [(x, y, z) for x, z in run], 0.13, 6)
    for x in (-2.4, 0.0, 2.2):
        cyl(P, "Gold", o + Vector((x, y, 0.45)), 0.09, 0.62, 6)
        box(P, "Gold", o + Vector((x, y, 0.72)), (0.36, 0.22, 0.1))
# burgundy cushions (seat + backrest), bevelled
box(P, "Burgundy", o + Vector((0.6, 0, 1.25)), (1.9, 2.6, 0.5))
box(P, "Burgundy", o + Vector((-0.45, 0, 1.85)), (0.45, 2.6, 1.3), (0, 0.25, 0))
# gift load behind the seat: 5 boxes, different sizes
for (x, y, z, s, c, rc, yaw) in ((-1.9, -0.6, 1.0, 1.25, "Green", "Gold", 0.2), (-2.0, 0.65, 1.0, 1.0, "Blue", "White", -0.35),
                                 (-1.95, 0.0, 2.15, 0.85, "Gold", "Red", 0.5), (-2.75, -0.2, 1.0, 0.8, "White", "Red", 0.1),
                                 (-1.2, 0.95, 1.0, 0.6, "Red", "Gold", 0.7)):
    base = o + Vector((x, y, z + s / 2)); box(P, c, base, (s, s, s), (0, 0, yaw))
    box(P, rc, base, (s * 1.04, s * 0.2, s * 1.04), (0, 0, yaw)); box(P, rc, base, (s * 0.2, s * 1.04, s * 1.04), (0, 0, yaw))
# make the run/trim tubes local to the prop origin (tube() takes absolute points)
# (handled below by offsetting: tube points above are prop-local, so shift them now)
for k in ((P, "Gold"),):
    pass

# 1 Signature display: giant candy-cane barbell resting on a decorated rack (9 wide)
o = at("BarbellDisplay", 1); P = "BarbellDisplay"
box(P, "WoodDark", o + Vector((0, 0, 0.25)), (9.6, 3.2, 0.5))
box(P, "Snow", o + Vector((0, 0, 0.55)), (9.4, 3.0, 0.14))
for x in (-3.2, 3.2):
    for dy in (-0.9, 0.9):
        box(P, "Wood", o + Vector((x, dy * 0.55, 1.9)), (0.45, 0.45, 2.9), (dy * 0.33, 0, 0))
    box(P, "Gold", o + Vector((x, 0, 3.35)), (0.7, 0.7, 0.25))
    cyl(P, "Gold", o + Vector((x, 0, 3.45)), 0.55, 0.2, 8, rot=(math.pi / 2, 0, 0))
# striped bar
bar = [(-5.6 + 0.8 * i, 0, 3.95) for i in range(15)]
tube(P, ["Red", "White"], [tuple(o + Vector(b)) for b in bar], 0.26, 8)
# peppermint plates (8 wedges, red/white) + gold collars
for x in (-4.6, -4.0, 4.0, 4.6):
    r = 1.7 if abs(x) > 4.3 else 1.45
    for w in range(8):
        a0 = 2 * math.pi * w / 8; a1 = 2 * math.pi * (w + 1) / 8
        pts = [(0, 0), (r * math.cos(a0), r * math.sin(a0)), (r * math.cos(a1), r * math.sin(a1))]
        prism(P, "Red" if w % 2 else "White", [(px, pz) for px, pz in pts], 0.42, o + Vector((x, 0, 3.95)), (0, 0, math.pi / 2))
    cyl(P, "Gold", o + Vector((x + (0.32 if x > 0 else -0.32), 0, 3.95)), 0.38, 0.2, 8, rot=(0, math.pi / 2, 0))

# 2/3 snow drifts (irregular low mounds)
for i, (name, sx, sy, h) in enumerate((("DriftA", 3.0, 2.0, 0.8), ("DriftB", 2.4, 1.6, 0.6))):
    o = at(name, 2 + i)
    sphere(name, "Snow", o, 1.0, 9, 4, s=(sx, sy, h), jit=0.16, flat_bottom=0.0)
    sphere(name, "Snow", o + Vector((sx * 0.55, sy * 0.3, 0)), 1.0, 7, 4, s=(sx * 0.45, sy * 0.5, h * 0.7), jit=0.18, flat_bottom=0.0)

# 4 premium bow (1.4 wide): broad folded loops, knot, two tails
o = at("Bow", 4); P = "Bow"
for s_ in (-1, 1):
    loop = [(s_ * (0.12 + 0.55 * (1 - math.cos(a)) / 2), 0, 0.3 * math.sin(a)) for a in [2 * math.pi * k / 9 for k in range(10)]]
    tube(P, ["Red"], [tuple(o + Vector(p)) for p in loop], 0.17, 5)
    tube(P, ["RedDark"], [tuple(o + Vector(p)) for p in ((s_ * 0.08, 0.05, -0.05), (s_ * 0.25, 0.05, -0.5), (s_ * 0.38, 0.05, -0.85))], 0.12, 4)
sphere(P, "RedDark", o + Vector((0, -0.05, 0)), 0.2, 6, 3)

# 5/6 gift cluster variants
o = at("GiftsB", 5); P = "GiftsB"
for (x, y, s, c, rc, yaw, z) in ((0, 0, 1.9, "Green", "Red", 0.1, 0), (1.5, 0.6, 1.1, "Red", "Gold", -0.4, 0), (-1.3, 0.5, 0.9, "White", "Red", 0.5, 0), (0.2, 0.1, 0.9, "Gold", "Red", 0.8, 1.9)):
    base = o + Vector((x, y, z + s / 2)); box(P, c, base, (s, s * 0.8, s), (0, 0, yaw))
    box(P, rc, base, (s * 1.04, s * 0.18, s * 1.04), (0, 0, yaw)); box(P, rc, base, (s * 0.18, s * 0.84, s * 1.04), (0, 0, yaw))
o = at("GiftsC", 6); P = "GiftsC"
for (x, y, s, c, rc, yaw) in ((0, 0, 1.3, "Blue", "Gold", 0.3), (1.2, -0.3, 0.8, "Red", "White", -0.2), (-1.1, -0.2, 1.0, "Gold", "Green", 0.6), (0.4, 1.1, 0.7, "Green", "Gold", 0.9)):
    base = o + Vector((x, y, s / 2)); box(P, c, base, (s * 1.3, s, s * 0.8), (0, 0, yaw))
    box(P, rc, base, (s * 1.34, s * 0.18, s * 0.84), (0, 0, yaw))

# 7 tree snow cap (small faceted patch to sit on a tier edge)
o = at("TreeSnow", 7)
sphere("TreeSnow", "Snow", o, 1.0, 7, 4, s=(0.9, 0.6, 0.28), jit=0.2, flat_bottom=-0.05)

cyl("KitRef", "Ref", Vector((0, -30, 0)), 0.3, 0.3, 4); cyl("KitRefX", "Ref", Vector((100, -30, 0)), 0.3, 0.3, 3)

# bevel only the boxy pieces (round tubes/spheres just multiply triangles)
BEVEL = {"Sleigh2_Red", "Sleigh2_Burgundy", "Sleigh2_Green", "Sleigh2_Blue", "Sleigh2_White", "BarbellDisplay_WoodDark", "BarbellDisplay_Wood", "GiftsB_Green", "GiftsB_Red", "GiftsB_White", "GiftsC_Blue", "GiftsC_Red", "GiftsC_Gold"}
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
    sc.render.filepath = os.path.join(HERE, "gate", f"p2_{name}.png"); bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)
bpy.ops.export_scene.gltf(filepath=os.path.join(HERE, "YardKit2.glb"), export_format="GLB", export_yup=True, export_apply=True)
print("glb", os.path.getsize(os.path.join(HERE, "YardKit2.glb")))
