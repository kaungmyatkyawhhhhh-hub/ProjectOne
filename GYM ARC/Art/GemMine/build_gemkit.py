# GYM ARC Gem Mine kit (28 Nov full-game review: ChatGPT MAP-2 "mine crystals still look like solid neon silhouettes",
# "Gem Mine ceiling: extremely rough geometry, replace with larger faceted rock sections"). Sheet: gemmine_kit_sheet.png.
# Faceted LOW-POLY (6-sided crystals, flat facets, whole colour per facet): outer facets 232,138,222, shadow facets
# 145,65,165, a glowing core strip on the front facet only (Neon in Roblox), slate rock bases.
# One glb, objects named <Prop>_<Colour>; KitRef / KitRefX markers give the import yaw. Front = Blender +Y (= Roblox -Z),
# up = Blender +Z, every prop's pivot = its base centre at (i*16, 0, 0).
# Headless: blender -b --factory-startup --python build_gemkit.py -> GemKit.glb + gate/p_*.png
import bpy, math, os, random
from mathutils import Vector, Euler
HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\GemMine"
random.seed(7)
PAL = {"Outer": (232, 138, 222), "Shadow": (145, 65, 165), "Core": (255, 200, 245),
       "Rock": (70, 74, 88), "RockDark": (44, 46, 56), "Ref": (255, 0, 255)}
G = {}

def add(prop, col, verts, faces):
    V, F = G.setdefault((prop, col), [[], []]); o = len(V)
    V += [tuple(v) for v in verts]; F += [tuple(i + o for i in f) for f in faces]

def xf(vs, loc=(0, 0, 0), rot=(0, 0, 0)):
    M = Euler(rot).to_matrix(); L = Vector(loc)
    return [M @ Vector(v) + L for v in vs]

def cyl(p, c, loc, r, h, n=8, r2=None, rot=(0, 0, 0)):
    r2 = r if r2 is None else r2
    ring = lambda rr, z: [(rr * math.cos(2 * math.pi * k / n), rr * math.sin(2 * math.pi * k / n), z) for k in range(n)]
    if r2 <= 1e-6:
        vs = ring(r, -h / 2) + [(0, 0, h / 2)]
        fs = [tuple(range(n - 1, -1, -1))] + [(k, (k + 1) % n, n) for k in range(n)]
    else:
        vs = ring(r, -h / 2) + ring(r2, h / 2)
        fs = [tuple(range(n - 1, -1, -1)), tuple(range(n, 2 * n))] + [(k, (k + 1) % n, n + (k + 1) % n, n + k) for k in range(n)]
    add(p, c, xf(vs, loc, rot), fs)

def rock(p, c, loc, r, s, jit=0.15, n=7, m=4, down=False):
    # faceted blob, flat bottom at loc.z (down=True: mirrored, flat TOP at loc.z, facets hanging below)
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
    if down:
        vs = [(x, y, -z) for x, y, z in vs]; fs = [tuple(reversed(f)) for f in fs]
    add(p, c, xf(vs, loc), fs)

def crystal(p, loc, r, h, tip, tilt=(0, 0), yaw=0.0, core=True):
    # 6-sided prism + pyramid tip; facet colours alternate Outer / Shadow (face 1 = front, Outer, gets the core strip)
    n = 6
    ang = [2 * math.pi * k / n for k in range(n)]
    low = [(r * math.cos(a), r * math.sin(a), -0.4) for a in ang]
    up = [(r * math.cos(a), r * math.sin(a), h) for a in ang]
    apex = (0, 0, h + tip)
    rot = (tilt[0], tilt[1], yaw)
    for k in range(n):
        k2 = (k + 1) % n
        col = "Outer" if k % 2 == 1 else "Shadow"
        add(p, col, xf([low[k], low[k2], up[k2], up[k]], loc, rot), [(0, 1, 2, 3)])
        add(p, "Outer" if k % 2 == 0 else "Shadow", xf([up[k], up[k2], apex], loc, rot), [(0, 1, 2)])
    add(p, "Shadow", xf(list(reversed(low)), loc, rot), [tuple(range(n))])
    if core:
        # thin raised strip on face 1 (normal at 90 deg = +Y before yaw), 18-80% of the height
        a0, a1 = ang[1], ang[2]
        mid = Vector(((math.cos(a0) + math.cos(a1)) / 2, (math.sin(a0) + math.sin(a1)) / 2, 0)) * r
        nrm = mid.normalized(); side = Vector((-nrm.y, nrm.x, 0)) * (r * 0.16)
        z0, z1 = h * 0.18, h * 0.8; d0, d1 = nrm * 0.015, nrm * 0.07
        vs = [mid - side + d0 + Vector((0, 0, z0)), mid + side + d0 + Vector((0, 0, z0)), mid + side + d0 + Vector((0, 0, z1)), mid - side + d0 + Vector((0, 0, z1)),
              mid - side + d1 + Vector((0, 0, z0)), mid + side + d1 + Vector((0, 0, z0)), mid + side + d1 + Vector((0, 0, z1)), mid - side + d1 + Vector((0, 0, z1))]
        fs = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
        add(p, "Core", xf(vs, loc, rot), fs)

OX = {}
def at(name, i): OX[name] = (i * 16.0, 0.0); return Vector((i * 16.0, 0, 0))

# 1 small cluster: 3 crystals on a small rock (~3 wide, ~3.4 tall)
o = at("CrystalS", 0)
rock("CrystalS", "Rock", o, 1.0, (1.5, 1.2, 0.55))
crystal("CrystalS", o + Vector((0, 0, 0.3)), 0.38, 2.2, 0.8)
crystal("CrystalS", o + Vector((-0.8, 0.1, 0.25)), 0.28, 1.4, 0.55, tilt=(0, -0.45), core=False)
crystal("CrystalS", o + Vector((0.8, -0.1, 0.25)), 0.3, 1.6, 0.6, tilt=(0, 0.42))

# 2 medium cluster: 5 crystals fanning out (~5 wide, ~4.8 tall)
o = at("CrystalM", 1)
rock("CrystalM", "Rock", o, 1.0, (2.5, 1.8, 0.7))
rock("CrystalM", "RockDark", o + Vector((1.2, 0.5, 0)), 0.8, (1.0, 0.9, 0.55))
for dx, r, h, tp, tl, cr in ((0, 0.52, 3.2, 1.1, 0, True), (-1.0, 0.4, 2.4, 0.85, -0.3, True), (1.0, 0.42, 2.6, 0.9, 0.3, True),
                             (-1.9, 0.3, 1.5, 0.6, -0.6, False), (1.9, 0.3, 1.6, 0.6, 0.6, False)):
    crystal("CrystalM", o + Vector((dx, 0, 0.35)), r, h, tp, tilt=(0, tl), core=cr)

# 3 tall pillar: one big crystal + 2 small (~3 wide, ~7 tall)
o = at("CrystalP", 2)
rock("CrystalP", "Rock", o, 1.0, (1.8, 1.5, 0.6))
crystal("CrystalP", o + Vector((0, 0, 0.3)), 0.72, 5.2, 1.6)
crystal("CrystalP", o + Vector((-1.0, 0.2, 0.25)), 0.3, 1.5, 0.55, tilt=(0, -0.5), core=False)
crystal("CrystalP", o + Vector((1.0, -0.2, 0.25)), 0.34, 1.9, 0.6, tilt=(0, 0.45), core=False)

# 4 ceiling slab: wide flat faceted rock with 3 short stalactites under it (16 x 14 footprint, base = TOP face at z 0,
# hangs downward: the slab spans z -2.4..0, stalactites reach ~ -4.6)
o = at("CeilSlab", 3)
rock("CeilSlab", "Rock", o, 1.0, (8.0, 7.0, 2.4), jit=0.18, n=9, m=4, down=True)
# stalactites: 6-sided cones flipped to point down, their roots inside the slab's underside
for (dx, dy, r, ln) in ((-3.2, 1.0, 0.9, 3.0), (1.5, -2.2, 0.75, 2.4), (3.6, 2.0, 0.8, 2.6)):
    cyl("CeilSlab", "RockDark", o + Vector((dx, dy, -1.0 - ln / 2)), r, ln, n=6, r2=0.0, rot=(math.pi, 0, random.uniform(0, 1)))

cyl("KitRef", "Ref", Vector((0, -30, 0)), 0.3, 0.3, 4); cyl("KitRefX", "Ref", Vector((100, -30, 0)), 0.3, 0.3, 3)

for o_ in list(bpy.data.objects): bpy.data.objects.remove(o_, do_unlink=True)
sc = bpy.context.scene; mats = {}; tot = 0
for (prop, col), (V, F) in G.items():
    if not F: continue
    me = bpy.data.meshes.new(f"{prop}_{col}"); me.from_pydata(V, [], F); me.validate()
    for pl in me.polygons: pl.use_smooth = False
    name = f"{prop}_{col}" if not prop.startswith("KitRef") else prop
    ob = bpy.data.objects.new(name, me); sc.collection.objects.link(ob)
    if col not in mats:
        m = bpy.data.materials.new("K_" + col); m.use_nodes = True; rgba = tuple(v / 255 for v in PAL[col]) + (1,)
        next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = rgba; m.diffuse_color = rgba; mats[col] = m
    me.materials.append(mats[col])
    n = sum(len(p.vertices) - 2 for p in me.polygons); tot += n
    print(f"{name}: {n} tris")
print("TOTAL", tot)
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
cam.data.lens = 50
sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.light = "STUDIO"; sc.display.shading.color_type = "MATERIAL"
sc.render.resolution_x, sc.render.resolution_y = 400, 400
os.makedirs(os.path.join(HERE, "gate"), exist_ok=True)
for name, (x0, _) in OX.items():
    zc = -2.5 if name == "CeilSlab" else 2.5
    cam.location = Vector((x0 + 6, 11, zc + 3.5 if name != "CeilSlab" else zc - 3.5)); cam.rotation_euler = (Vector((x0, 0, zc)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(HERE, "gate", f"p_{name}.png"); bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)
bpy.ops.export_scene.gltf(filepath=os.path.join(HERE, "GemKit.glb"), export_format="GLB", export_yup=True, export_apply=True)
print("glb", os.path.getsize(os.path.join(HERE, "GemKit.glb")))
