# GYM ARC Frost Titan pedestal, from sheet.png (FRONT x 49-725, SIDE, TOP, EXPLODED: base tier, middle tier, top tier, glow ring, ice cluster, plaque).
# Headless: blender -b --factory-startup --python build_pedestal.py -> TitanPedestal.glb + gate/front.png, gate/side.png
# 1 unit = base radius (338 px). Origin = bottom centre. Front = -Y. One object per colour = one MeshPart.
# Studio swap scales it to the old pedestal's footprint.
import bpy, bmesh, math, os
from mathutils import Vector, Matrix
HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\TitanPedestal"
CX, GY = 387, 246                         # front view centre x, ground y
S = 1 / 338
Z = lambda y: (GY - y) * S
N = 20                                    # faceted discs, like the TOP view
COL = {"Navy": (0.12, 0.18, 0.28, 1), "Frost": (0.68, 0.86, 0.95, 1), "Glow": (0.22, 0.94, 1.0, 1),
       "Crystal": (0.56, 0.79, 0.95, 1), "Plaque": (0.79, 0.81, 0.84, 1)}
V = {k: [] for k in COL}; F = {k: [] for k in COL}

def add(c, verts, faces):
    o = len(V[c]); V[c] += [tuple(v) for v in verts]; F[c] += [tuple(i + o for i in f) for f in faces]

def ring(r, z, n=N, rot=math.pi / N):
    return [Vector((r * math.cos(rot + 2 * math.pi * i / n), r * math.sin(rot + 2 * math.pi * i / n), z)) for i in range(n)]

def stack(c, prof, n=N):
    """closed solid of revolution from (r_px, y_px) pairs, bottom to top."""
    rs = [ring(r * S, Z(y), n) for r, y in prof]
    verts = [v for rg in rs for v in rg]; faces = [tuple(range(n - 1, -1, -1)), tuple(range((len(rs) - 1) * n, len(rs) * n))]
    for k in range(len(rs) - 1):
        faces += [(k * n + i, k * n + (i + 1) % n, (k + 1) * n + (i + 1) % n, (k + 1) * n + i) for i in range(n)]
    add(c, verts, faces)

# base tier: chamfered bottom, glow band proud round its side (y 226-234)
stack("Navy", [(318, 246), (338, 238), (338, 212), (326, 206)])
stack("Glow", [(342, 235), (342, 226)])
# middle tier: sloped frustum (r 314 at y 206 to r 281 at y 148)
stack("Navy", [(316, 207), (281, 148), (262, 145)])
# top tier: frosted disc with a chamfered top edge
stack("Frost", [(258, 147), (262, 141), (262, 118), (250, 112)])
# glow ring round the top tier's foot (y 132-142)
stack("Glow", [(268, 142), (268, 132)])

def crystal(base, h, r, tilt, yaw):
    """6-sided ice crystal: prism with a pointed top, tilted outward by tilt (rad) in the direction yaw."""
    lo = ring(r, 0, 6, 0); hi = ring(r, h * 0.7, 6, 0); tip = Vector((0, 0, h))
    m = Matrix.Rotation(yaw, 3, "Z") @ Matrix.Rotation(tilt, 3, "Y")
    verts = [base + m @ v for v in lo + hi + [tip]]
    faces = [tuple(range(5, -1, -1))] + [(i, (i + 1) % 6, 6 + (i + 1) % 6, 6 + i) for i in range(6)] + [(6 + i, 6 + (i + 1) % 6, 12) for i in range(6)]
    add("Crystal", verts, faces)

# 4 ice clusters on the top tier rim (TOP + SIDE views: left, right, front, back), each a tall centre crystal + 2 leaning ones
for a in (0, math.pi / 2, math.pi, 3 * math.pi / 2):
    d = Vector((math.cos(a), math.sin(a), 0)); t = Vector((-d.y, d.x, 0))
    c = d * 240 * S + Vector((0, 0, Z(146)))
    crystal(c, 78 * S, 20 * S, 0, a)
    crystal(c + t * 26 * S, 50 * S, 14 * S, 0.45, a + math.pi / 2)
    crystal(c - t * 26 * S, 50 * S, 14 * S, 0.45, a - math.pi / 2)

# plaque: bevelled plate on the middle tier's front slope (front view x 301-474, y 156-208)
w, h, th = 173 / 2 * S, 52 / 2 * S, 0.03
zc = (Z(156) + Z(208)) / 2; rmid = 300 * S
slope = math.atan2((316 - 281) * S, Z(148) - Z(207))
pts = [(-w + h * 0.4, -h), (w - h * 0.4, -h), (w, -h * 0.5), (w, h * 0.5), (w - h * 0.4, h), (-w + h * 0.4, h), (-w, h * 0.5), (-w, -h * 0.5)]
m = Matrix.Rotation(-slope, 3, "X")
fr = [Vector((0, -rmid, zc)) + m @ Vector((x, -th, z)) for x, z in pts]
bk = [Vector((0, -rmid, zc)) + m @ Vector((x, th, z)) for x, z in pts]
add("Plaque", fr + bk, [tuple(range(8)), tuple(range(15, 7, -1))] + [(i, 8 + i, 8 + (i + 1) % 8, (i + 1) % 8) for i in range(8)])

for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
sc = bpy.context.scene; tot = 0
for c in COL:
    me = bpy.data.meshes.new("TP_" + c); me.from_pydata(V[c], [], F[c]); me.validate()
    bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.triangulate(bm, faces=bm.faces); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(me); bm.free()
    for p in me.polygons: p.use_smooth = False
    o = bpy.data.objects.new(c, me); o["xmas_part"] = "pedestal"
    mt = bpy.data.materials.new("TP_" + c); mt.use_nodes = True
    next(n for n in mt.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = COL[c]; mt.diffuse_color = COL[c]
    me.materials.append(mt); sc.collection.objects.link(o); tot += len(me.polygons)
    print(c, len(me.polygons), "tris")
print("TOTAL", tot)
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
cam.data.type = "ORTHO"; cam.data.ortho_scale = 1536 * S
sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.light = "FLAT"; sc.display.shading.color_type = "MATERIAL"
sc.render.film_transparent = True; sc.render.resolution_x, sc.render.resolution_y, sc.render.resolution_percentage = 1536, 1024, 100
os.makedirs(os.path.join(HERE, "gate"), exist_ok=True)
cam.location = ((768 - CX) * S, -30, Z(512)); cam.rotation_euler = (math.pi / 2, 0, 0)
sc.render.filepath = os.path.join(HERE, "gate", "front.png"); bpy.ops.render.render(write_still=True)
SX = 1147                                 # sheet SIDE view centre x
cam.location = (30, (768 - SX) * S, Z(512)); cam.rotation_euler = (math.pi / 2, 0, math.pi / 2)
sc.render.filepath = os.path.join(HERE, "gate", "side.png"); bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)
for o in sc.objects: o.select_set(o.get("xmas_part") == "pedestal")
bpy.ops.export_scene.gltf(filepath=os.path.join(HERE, "TitanPedestal.glb"), use_selection=True, export_format="GLB", export_yup=True)
print("glb", os.path.getsize(os.path.join(HERE, "TitanPedestal.glb")))
