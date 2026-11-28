# GYM ARC Gem Mine kit 2 (28 Nov MAP-5: ChatGPT "reduce stalactite length 20-25%", "back wall too flat: 6-8 faceted rock
# breakups per wall, 2-4 studs wide, ~RGB 88,88,96"; Gemini "shorten/thicken the rock spikes into broader stalactites").
#   Stalac  : replacement for CeilSlab's RockDark part: the same 3 roots (same template base as GemKit's CeilSlab), each
#             cone 0.72x as long and 1.35x as thick, + 2 stubby ones. Base = the slab's top (z 0), hangs down.
#   Boulder : a faceted wall rock, ~3.2 x 2.6 x 2.4, flat bottom at z 0 (Rock) with a darker chip (RockDark)
#   BoulderT: a taller narrow wall rock, ~2.4 x 2 x 3.6
# Same conventions as build_gemkit.py (objects <Prop>_<Colour>, props at (i*16,0,0), KitRef / KitRefX).
# Headless: blender -b --factory-startup --python build_gemkit2.py -> GemKit2.glb + gate/k2.png
import bpy, math, os, random
from mathutils import Vector, Euler
HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\GemMine"
random.seed(11)
PAL = {"Rock": (88, 88, 96), "RockDark": (44, 46, 56), "Ref": (255, 0, 255)}
G = {}

def add(prop, col, verts, faces):
    V, F = G.setdefault((prop, col), [[], []]); o = len(V)
    V += [tuple(v) for v in verts]; F += [tuple(i + o for i in f) for f in faces]

def xf(vs, loc=(0, 0, 0), rot=(0, 0, 0)):
    M = Euler(rot).to_matrix(); L = Vector(loc)
    return [M @ Vector(v) + L for v in vs]

def cone(p, c, loc, r, h, n=6, rot=(0, 0, 0)):
    vs = [(r * math.cos(2 * math.pi * k / n), r * math.sin(2 * math.pi * k / n), -h / 2) for k in range(n)] + [(0, 0, h / 2)]
    add(p, c, xf(vs, loc, rot), [tuple(range(n - 1, -1, -1))] + [(k, (k + 1) % n, n) for k in range(n)])

def rock(p, c, loc, r, s, jit=0.2, n=7, m=4):
    vs = [(0, 0, -r)]
    for j in range(1, m):
        th = math.pi * j / m - math.pi / 2
        for k in range(n):
            a = 2 * math.pi * k / n + (j % 2) * math.pi / n
            q = r * (1 + random.uniform(-jit, jit))
            vs.append((q * math.cos(th) * math.cos(a), q * math.cos(th) * math.sin(a), q * math.sin(th)))
    vs.append((0, 0, r))
    vs = [(x * s[0], y * s[1], max(z * s[2], 0.0)) for x, y, z in vs]
    fs = [(0, 1 + (k + 1) % n, 1 + k) for k in range(n)]
    for j in range(m - 2):
        a0, b0 = 1 + j * n, 1 + (j + 1) * n
        for k in range(n):
            fs += [(a0 + k, a0 + (k + 1) % n, b0 + k), (a0 + (k + 1) % n, b0 + (k + 1) % n, b0 + k)]
    top = len(vs) - 1; a0 = 1 + (m - 2) * n
    fs += [(a0 + k, a0 + (k + 1) % n, top) for k in range(n)]
    add(p, c, xf(vs, loc), fs)

# Stalac: GemKit's CeilSlab roots (dx, dy, r, len) at z -1.0, now 0.72x long, 1.35x thick, + 2 stubs
o = Vector((0, 0, 0))
for (dx, dy, r, ln) in ((-3.2, 1.0, 0.9, 3.0), (1.5, -2.2, 0.75, 2.4), (3.6, 2.0, 0.8, 2.6), (-0.8, -0.6, 0.85, 1.4), (5.2, -1.0, 0.7, 1.2)):
    r2, l2 = r * 1.35, ln * 0.72 if ln > 2 else ln
    cone("Stalac", "RockDark", o + Vector((dx, dy, -1.0 - l2 / 2)), r2, l2, n=6, rot=(math.pi, 0, random.uniform(0, 1)))

o = Vector((16, 0, 0))
rock("Boulder", "Rock", o, 1.0, (1.6, 1.3, 2.6))
rock("Boulder", "RockDark", o + Vector((1.0, -0.5, 0)), 1.0, (0.8, 0.7, 1.3))
o = Vector((32, 0, 0))
rock("BoulderT", "Rock", o, 1.0, (1.2, 1.0, 3.6), n=6)
rock("BoulderT", "RockDark", o + Vector((-0.7, 0.3, 0)), 1.0, (0.6, 0.6, 1.6), n=6)

cone("KitRef", "Ref", Vector((0, -30, 0.15)), 0.3, 0.3, 4); cone("KitRefX", "Ref", Vector((100, -30, 0.15)), 0.3, 0.3, 3)

for o_ in list(bpy.data.objects): bpy.data.objects.remove(o_, do_unlink=True)
sc = bpy.context.scene; mats = {}; tot = 0
for (prop, col), (V, F) in G.items():
    name = f"{prop}_{col}" if not prop.startswith("KitRef") else prop
    me = bpy.data.meshes.new(name); me.from_pydata(V, [], F); me.validate()
    for pl in me.polygons: pl.use_smooth = False
    ob = bpy.data.objects.new(name, me); sc.collection.objects.link(ob)
    if col not in mats:
        m = bpy.data.materials.new("K2_" + col); m.use_nodes = True; rgba = tuple(v / 255 for v in PAL[col]) + (1,)
        next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = rgba; m.diffuse_color = rgba; mats[col] = m
    me.materials.append(mats[col])
    n = sum(len(p.vertices) - 2 for p in me.polygons); tot += n; print(f"{name}: {n} tris")
print("TOTAL", tot)
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.light = "STUDIO"; sc.display.shading.color_type = "MATERIAL"
sc.render.resolution_x, sc.render.resolution_y = 700, 300
cam.location = Vector((16, -40, 4)); cam.rotation_euler = (Vector((16, 0, 0)) - cam.location).to_track_quat("-Z", "Y").to_euler()
os.makedirs(os.path.join(HERE, "gate"), exist_ok=True)
sc.render.filepath = os.path.join(HERE, "gate", "k2.png"); bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)
bpy.ops.export_scene.gltf(filepath=os.path.join(HERE, "GemKit2.glb"), export_format="GLB", export_yup=True, export_apply=True)
print("glb", os.path.getsize(os.path.join(HERE, "GemKit2.glb")))
