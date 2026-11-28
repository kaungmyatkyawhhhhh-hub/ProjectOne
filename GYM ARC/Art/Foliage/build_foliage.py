# GYM ARC town foliage kit (28 Nov full-game review, ChatGPT MAP-2: "Realistic leafy textures clash with faceted
# Christmas models. Replace with three-tone low-poly foliage"). Faceted LOW-POLY, flat facets, no texture.
#   Blob  : a faceted 8x5 ellipsoid with jitter (round trees, bushes, topiary balls), unit size 1x1x1
#   Spindle: a faceted 7-sided spindle (cypress pieces), unit size 1x1x1
# Each split by facet normal into _Light (upward facing) and _Dark (side/down) so one green reads as 2 tones;
# the swap picks one of 3 base greens per piece = three-tone foliage.
# Objects <Prop>_<Tone>, every prop centred at (i*4, 0, 0). KitRef / KitRefX give the import yaw.
# Headless: blender -b --factory-startup --python build_foliage.py -> Foliage.glb
import bpy, math, os, random
from mathutils import Vector
HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\Foliage"
random.seed(5)
PAL = {"Light": (120, 168, 84), "Dark": (60, 104, 52), "Ref": (255, 0, 255)}
G = {}

def add(prop, col, verts, faces):
    V, F = G.setdefault((prop, col), [[], []]); o = len(V)
    V += [tuple(v) for v in verts]; F += [tuple(i + o for i in f) for f in faces]

def split_add(prop, loc, vs, fs):
    # each triangle goes to _Light if its normal points up (z > 0.35), else _Dark
    for f in fs:
        a, b, c = (Vector(vs[i]) for i in f)
        nz = (b - a).cross(c - a).normalized().z
        add(prop, "Light" if nz > 0.35 else "Dark", [a + loc, b + loc, c + loc], [(0, 1, 2)])

def blob(prop, loc, n=8, m=5, jit=0.12):
    vs = [(0, 0, -0.5)]
    for j in range(1, m):
        th = math.pi * j / m - math.pi / 2
        for k in range(n):
            a = 2 * math.pi * k / n + (j % 2) * math.pi / n
            q = 0.5 * (1 + random.uniform(-jit, jit))
            vs.append((q * math.cos(th) * math.cos(a), q * math.cos(th) * math.sin(a), q * math.sin(th)))
    vs.append((0, 0, 0.5))
    fs = [(0, 1 + (k + 1) % n, 1 + k) for k in range(n)]
    for j in range(m - 2):
        a0, b0 = 1 + j * n, 1 + (j + 1) * n
        for k in range(n):
            fs += [(a0 + k, a0 + (k + 1) % n, b0 + k), (a0 + (k + 1) % n, b0 + (k + 1) % n, b0 + k)]
    top = len(vs) - 1; a0 = 1 + (m - 2) * n
    fs += [(a0 + k, a0 + (k + 1) % n, top) for k in range(n)]
    split_add(prop, loc, vs, fs)

def spindle(prop, loc, n=7):
    # bottom point, widest ring at 30%, a second ring at 65%, top point
    rings = [(0.5 * 0.0, -0.5), (0.5, -0.2), (0.38, 0.15), (0.0, 0.5)]
    vs = [(0, 0, -0.5)]
    for r, z in rings[1:3]:
        ph = random.uniform(0, 0.4)
        vs += [(r * (1 + random.uniform(-0.08, 0.08)) * math.cos(2 * math.pi * k / n + ph),
                r * (1 + random.uniform(-0.08, 0.08)) * math.sin(2 * math.pi * k / n + ph), z) for k in range(n)]
    vs.append((0, 0, 0.5))
    fs = [(0, 1 + (k + 1) % n, 1 + k) for k in range(n)]
    fs += [(1 + k, 1 + (k + 1) % n, 1 + n + k) for k in range(n)] + [(1 + (k + 1) % n, 1 + n + (k + 1) % n, 1 + n + k) for k in range(n)]
    top = len(vs) - 1
    fs += [(1 + n + k, 1 + n + (k + 1) % n, top) for k in range(n)]
    split_add(prop, loc, vs, fs)

def marker(name, loc, n):
    vs = [(0.15 * math.cos(2 * math.pi * k / n) + loc[0], 0.15 * math.sin(2 * math.pi * k / n) + loc[1], loc[2]) for k in range(n)] + [(loc[0], loc[1], loc[2] + 0.3)]
    add(name, "Ref", vs, [tuple(range(n - 1, -1, -1))] + [(k, (k + 1) % n, n) for k in range(n)])

blob("Blob", Vector((0, 0, 0)))
spindle("Spindle", Vector((4, 0, 0)))
marker("KitRef", (0, -30, 0), 4); marker("KitRefX", (100, -30, 0), 3)

for o_ in list(bpy.data.objects): bpy.data.objects.remove(o_, do_unlink=True)
sc = bpy.context.scene; mats = {}; tot = 0
for (prop, col), (V, F) in G.items():
    me = bpy.data.meshes.new(f"{prop}_{col}"); me.from_pydata(V, [], F); me.validate()
    for pl in me.polygons: pl.use_smooth = False
    name = f"{prop}_{col}" if not prop.startswith("KitRef") else prop
    ob = bpy.data.objects.new(name, me); sc.collection.objects.link(ob)
    if col not in mats:
        m = bpy.data.materials.new("F_" + col); m.use_nodes = True; rgba = tuple(v / 255 for v in PAL[col]) + (1,)
        next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = rgba; m.diffuse_color = rgba; mats[col] = m
    me.materials.append(mats[col])
    n = len(me.polygons); tot += n; print(f"{name}: {n} tris")
print("TOTAL", tot)
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.light = "STUDIO"; sc.display.shading.color_type = "MATERIAL"
sc.render.resolution_x, sc.render.resolution_y = 500, 300
cam.location = Vector((2, -7, 2)); cam.rotation_euler = (Vector((2, 0, 0)) - cam.location).to_track_quat("-Z", "Y").to_euler()
os.makedirs(os.path.join(HERE, "gate"), exist_ok=True)
sc.render.filepath = os.path.join(HERE, "gate", "foliage.png"); bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)
bpy.ops.export_scene.gltf(filepath=os.path.join(HERE, "Foliage.glb"), export_format="GLB", export_yup=True, export_apply=True)
print("glb", os.path.getsize(os.path.join(HERE, "Foliage.glb")))
