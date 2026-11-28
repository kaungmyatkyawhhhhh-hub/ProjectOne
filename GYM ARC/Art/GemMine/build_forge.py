# GYM ARC Gem Mine: Plate Forge shell (28 Nov MAP-5: the forge's back was a plain 14x14 Slate slab "cutting the sightline";
# the whole shell was a Part assembly). One faceted low-poly mesh in the old parts' places (Roblox units, origin = the
# PlateForge model pivot, front = -Z, back wall at z +6). Objects Forge_<Colour>:
#   StoneA (58,54,64) / StoneB (72,68,80): back-wall core + staggered masonry blocks on both faces, furnace hood
#   Wood (90,58,34): chamfered posts + beam      Floor (42,39,48): chamfered platform
#   Furnace (74,63,58): furnace body + tapered 6-sided chimney    Brick (122,100,88): arch columns + top
# Kept as Parts (functional): FurnaceMouth (fire + lights), Coal, anvil, bench, rack, sign, attachments.
# Axes: Blender X = Roblox X, Blender Z = Roblox Y, Blender Y = -Roblox Z. KitRef / KitRefX give the import yaw.
# Headless: blender -b --factory-startup --python build_forge.py -> Forge.glb + gate/forge.png
import bpy, bmesh, os, math, random
from mathutils import Vector
HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\GemMine"
random.seed(3)
PAL = {"StoneA": (58, 54, 64), "StoneB": (72, 68, 80), "Wood": (90, 58, 34), "Floor": (42, 39, 48), "Furnace": (74, 63, 58),
       "Brick": (122, 100, 88), "Ref": (255, 0, 255)}
G = {}

def R(x, y, z): return Vector((x, -z, y))

def hull(col, pts):
    bm = bmesh.new()
    for p in pts: bm.verts.new(p)
    bmesh.ops.convex_hull(bm, input=bm.verts)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    V, F = G.setdefault(col, [[], []]); o = len(V)
    idx = {v: i for i, v in enumerate(bm.verts)}
    V += [tuple(v.co) for v in bm.verts]; F += [tuple(idx[v] + o for v in f.verts) for f in bm.faces]
    bm.free()

def cbox(col, c, s, ch):
    hx, hy, hz = s[0] / 2, s[1] / 2, s[2] / 2; pts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            for sz in (-1, 1):
                x, y, z = sx * hx, sy * hy, sz * hz
                pts += [R(c[0] + x - sx * ch, c[1] + y, c[2] + z), R(c[0] + x, c[1] + y - sy * ch, c[2] + z), R(c[0] + x, c[1] + y, c[2] + z - sz * ch)]
    hull(col, pts)

def tcyl(col, c, r0, r1, h, n=6):
    pts = [R(c[0] + r * math.cos(2 * math.pi * k / n), c[1] + y, c[2] + r * math.sin(2 * math.pi * k / n)) for r, y in ((r0, -h / 2), (r1, h / 2)) for k in range(n)]
    hull(col, pts)

# back wall: core slab, then masonry rows on the back face (z 6.5 out) and the front face (z 5.5 out)
# (MAP-6: "reads like a tall boxy block": the top two courses step in 1.5 per side under a sloped cap, and two blocks
# on the left stick out 0.35 more)
cbox("StoneA", (0, -1.66, 6.0), (14, 10.52, 0.8), 0.15)
cbox("StoneA", (0, 4.4, 6.0), (11, 1.6, 0.8), 0.1)
cbox("StoneA", (0, 6.14, 6.0), (8, 1.88, 0.8), 0.1)
y = -6.9
row = 0
while y < 7.0:
    h = 1.6 if y + 1.6 < 7.05 else 7.05 - y
    inset = 0.0 if y < 3.6 else (1.5 if y < 5.2 else 3.0)
    x0, x1 = -7.0 + inset, 7.0 - inset
    x = x0 + (0.9 if row % 2 else 0.0)
    if row % 2: cbox("StoneB", (x0 + 0.45, y + h / 2, 6.0), (0.9, h - 0.12, 1.2), 0.07)
    while x < x1 - 0.05:
        w = min(random.uniform(2.2, 3.4), x1 - x)
        if w > 0.5:
            col = "StoneB" if random.random() < 0.5 else "StoneA"
            deep = 0.7 if (row in (2, 5) and x < x0 + 1.0) else 0.0
            cbox(col, (x + w / 2, y + h / 2, 6.0), (w - 0.12, h - 0.12, 1.2 + random.uniform(0, 0.12) + deep), 0.08)
        x += w
    y += h; row += 1
# sloped cap on the stepped top: a low faceted ridge along X
hull("StoneB", [R(sx * 4.2, 7.0, sz * 0.8) for sx in (-1, 1) for sz in (-1, 1)] + [R(sx * 3.6, 7.8, 0) for sx in (-1, 1)])
for sx in (-1, 1):  # sloped shoulders where each course steps in
    hull("StoneA", [R(sx * 7.0, 3.55, z) for z in (5.4, 6.6)] + [R(sx * 5.5, 3.55, z) for z in (5.4, 6.6)] + [R(sx * 5.5, 4.3, z) for z in (5.4, 6.6)])
    hull("StoneA", [R(sx * 5.5, 5.15, z) for z in (5.4, 6.6)] + [R(sx * 4.0, 5.15, z) for z in (5.4, 6.6)] + [R(sx * 4.0, 5.9, z) for z in (5.4, 6.6)])
# timber
for px in (6.6, -6.6): cbox("Wood", (px, 0.08, 5.3), (0.8, 14, 0.8), 0.12)
cbox("Wood", (0, 6.98, 5.3), (14.6, 0.9, 1.0), 0.12)
cbox("Floor", (0, -7.17, 0.5), (14, 0.5, 11), 0.12)
# furnace
cbox("Furnace", (-4.8, -4.17, 3.9), (3.8, 5.5, 3.2), 0.22)
cbox("StoneA", (-4.8, -1.02, 3.9), (4.4, 0.9, 3.8), 0.18)
tcyl("Furnace", (-4.8, 1.68, 4.6), 1.05, 0.8, 4.6)
for ax in (-3.5, -6.1): cbox("Brick", (ax, -4.82, 2.15), (0.45, 2.7, 0.45), 0.07)
cbox("Brick", (-4.8, -3.37, 2.15), (3.0, 0.5, 0.45), 0.07)

def marker(name, loc, n):
    hull("Ref_" + name, [Vector((loc[0] + 0.15 * dx, loc[1] + 0.15 * dy, loc[2] + dz)) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))[:n] for dz in (0, 0.3)])
marker("KitRef", (0, -30, 0), 4); marker("KitRefX", (100, -30, 0), 3)

for o_ in list(bpy.data.objects): bpy.data.objects.remove(o_, do_unlink=True)
sc = bpy.context.scene; mats = {}; tot = 0
for col, (V, F) in G.items():
    name = col[4:] if col.startswith("Ref_") else "Forge_" + col
    pc = "Ref" if col.startswith("Ref_") else col
    me = bpy.data.meshes.new(name); me.from_pydata(V, [], F); me.validate()
    for pl in me.polygons: pl.use_smooth = False
    ob = bpy.data.objects.new(name, me); sc.collection.objects.link(ob)
    if pc not in mats:
        m = bpy.data.materials.new("F_" + pc); m.use_nodes = True; rgba = tuple(v / 255 for v in PAL[pc]) + (1,)
        next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = rgba; m.diffuse_color = rgba; mats[pc] = m
    me.materials.append(mats[pc])
    tot += len(me.polygons); print(f"{name}: {len(me.polygons)} tris")
print("TOTAL", tot)
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.light = "STUDIO"; sc.display.shading.color_type = "MATERIAL"
sc.render.resolution_x, sc.render.resolution_y = 600, 500
os.makedirs(os.path.join(HERE, "gate"), exist_ok=True)
for tag, loc in (("back", (14, 26, 4)), ("front", (10, -24, 4))):
    cam.location = Vector(loc); cam.rotation_euler = (Vector((0, -3, 0)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(HERE, "gate", f"forge_{tag}.png"); bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)
bpy.ops.export_scene.gltf(filepath=os.path.join(HERE, "Forge.glb"), export_format="GLB", export_yup=True, export_apply=True)
print("glb", os.path.getsize(os.path.join(HERE, "Forge.glb")))
