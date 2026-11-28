# GYM ARC Gem Mine: Onyx Throne (28 Nov MAP-4: ChatGPT "dark monolith still reads as a plain block: 0.2-0.3 bevel and one
# inset glow seam"; Gemini "bevel/trim the large dark slab"). Replaces the 7-Part box assembly with one faceted low-poly mesh.
# Same layout as the old parts (Roblox units, origin = the old Dais centre, front = -X). Objects Throne_<Colour>:
#   Stone (42,36,51) chamfered dais / seat / arms / back with a faceted crown, Trim (64,44,96) dais rim plate,
#   Glow (120,70,210, Neon in Roblox) a rectangular seam frame on the back's front face.
# Axes: Blender X = Roblox X, Blender Z = Roblox Y, Blender Y = -Roblox Z. KitRef / KitRefX give the import yaw.
# Headless: blender -b --factory-startup --python build_throne.py -> Throne.glb + gate/throne.png
import bpy, bmesh, os
from mathutils import Vector
HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\GemMine"
PAL = {"Stone": (42, 36, 51), "Trim": (64, 44, 96), "Glow": (120, 70, 210), "Ref": (255, 0, 255)}
G = {}

def R(x, y, z): return Vector((x, -z, y))  # Roblox -> Blender

def hull(col, pts):
    bm = bmesh.new()
    for p in pts: bm.verts.new(p)
    bmesh.ops.convex_hull(bm, input=bm.verts)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    V, F = G.setdefault(col, [[], []]); o = len(V)
    idx = {v: i for i, v in enumerate(bm.verts)}
    V += [tuple(v.co) for v in bm.verts]; F += [tuple(idx[v] + o for v in f.verts) for f in bm.faces]
    bm.free()

def cbox(col, c, s, ch, crown=0.0):
    # chamfered box: Roblox centre c, size s, chamfer ch; crown > 0 adds a faceted ridge on top (along Roblox Z)
    hx, hy, hz = s[0] / 2, s[1] / 2, s[2] / 2; pts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            for sz in (-1, 1):
                x, y, z = sx * hx, sy * hy, sz * hz
                pts += [R(c[0] + x - sx * ch, c[1] + y, c[2] + z), R(c[0] + x, c[1] + y - sy * ch, c[2] + z), R(c[0] + x, c[1] + y, c[2] + z - sz * ch)]
    if crown > 0:
        for z in (-hz * 0.45, 0.0, hz * 0.45):
            pts.append(R(c[0], c[1] + hy + crown * (1 - abs(z) / hz), c[2] + z))
    hull(col, pts)

# old parts, same places (DaisTrim / Dais / Seat / ArmL / ArmR / Back)
cbox("Stone", (0, 0, 0), (9, 1.2, 11), 0.28)
cbox("Trim", (0, 0.55, 0), (9.2, 0.2, 11.2), 0.08)
cbox("Stone", (0.5, 1.9, 0), (4, 2.6, 6), 0.25)
for z in (3.2, -3.2): cbox("Stone", (0.5, 3.8, z), (4, 1.2, 1.2), 0.2)
cbox("Stone", (2.6, 7.1, 0), (1.6, 13, 7.5), 0.3, crown=1.4)
# glow seam: a rectangle frame proud 0.06 of the back's front face (x = 1.8), 5.2 wide, from y 4.2 to 12.4
fx = 1.8 - 0.06; W, y0, y1, t = 2.6, 4.2, 12.4, 0.22
for (cy, h, cz, w) in (((y0 + y1) / 2, y1 - y0, W, t), ((y0 + y1) / 2, y1 - y0, -W, t), (y1, t, 0, 2 * W + t), (y0, t, 0, 2 * W + t)):
    cbox("Glow", (fx + 0.04, cy, cz), (0.12, h, w), 0.02)
cbox("Glow", (fx + 0.04, (y0 + y1) / 2, 0), (0.12, y1 - y0 - 1.2, t * 0.8), 0.02)  # centre line

def marker(name, loc, n):
    hull("Ref_" + name, [Vector((loc[0] + 0.15 * dx, loc[1] + 0.15 * dy, loc[2] + dz)) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))[:n] for dz in (0, 0.3)])
marker("KitRef", (0, -30, 0), 4); marker("KitRefX", (100, -30, 0), 3)

for o_ in list(bpy.data.objects): bpy.data.objects.remove(o_, do_unlink=True)
sc = bpy.context.scene; mats = {}; tot = 0
for col, (V, F) in G.items():
    name = col[4:] if col.startswith("Ref_") else "Throne_" + col
    pc = "Ref" if col.startswith("Ref_") else col
    me = bpy.data.meshes.new(name); me.from_pydata(V, [], F); me.validate()
    for pl in me.polygons: pl.use_smooth = False
    ob = bpy.data.objects.new(name, me); sc.collection.objects.link(ob)
    if pc not in mats:
        m = bpy.data.materials.new("T_" + pc); m.use_nodes = True; rgba = tuple(v / 255 for v in PAL[pc]) + (1,)
        next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = rgba; m.diffuse_color = rgba; mats[pc] = m
    me.materials.append(mats[pc])
    tot += len(me.polygons); print(f"{name}: {len(me.polygons)} tris")
print("TOTAL", tot)
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.light = "STUDIO"; sc.display.shading.color_type = "MATERIAL"
sc.render.resolution_x, sc.render.resolution_y = 500, 500
cam.location = Vector((-16, -9, 9)); cam.rotation_euler = (Vector((1, 0, 5)) - cam.location).to_track_quat("-Z", "Y").to_euler()
os.makedirs(os.path.join(HERE, "gate"), exist_ok=True)
sc.render.filepath = os.path.join(HERE, "gate", "throne.png"); bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)
bpy.ops.export_scene.gltf(filepath=os.path.join(HERE, "Throne.glb"), export_format="GLB", export_yup=True, export_apply=True)
print("glb", os.path.getsize(os.path.join(HERE, "Throne.glb")))
