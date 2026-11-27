# GYM ARC Christmas present, from sheet.png (FRONT x 114-479 y 33-448, SIDE, TOP, EXPLODED: box, lid, ribbon bands, bow loops, knot, tails).
# Headless: blender -b --factory-startup --python build_present.py -> Present.glb + gate/front.png
# 1 unit = box body width. Origin = bottom centre. Front = -Y. 3 objects (= MeshParts): Box, Lid, Ribbon (bands + bow).
# Roblox scales each copy to the old present's box size, so one mesh serves every present.
import bpy, bmesh, math, os
from mathutils import Vector
HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\Present"
CX, GY = 297, 448                         # front view: body centre x, ground y (px)
S = 1 / 330                               # body 132-462 px = 1 unit
X = lambda x: (x - CX) * S
Z = lambda y: (GY - y) * S
BODY_TOP, LID_TOP, LID_HALF = Z(215), Z(129), (479 - 114) / 2 * S
RIB = 66 * S / 2                          # ribbon half width (263-329)
COL = {"Box": (0.83, 0.13, 0.16, 1), "Lid": (0.71, 0.09, 0.12, 1), "Ribbon": (1.0, 0.78, 0.23, 1)}
V = {k: [] for k in COL}; F = {k: [] for k in COL}

def add(c, verts, faces):
    o = len(V[c]); V[c] += [tuple(v) for v in verts]; F[c] += [tuple(i + o for i in f) for f in faces]

def box(c, x0, x1, y0, y1, z0, z1):
    v = [Vector((x, y, z)) for z in (z0, z1) for y in (y0, y1) for x in (x0, x1)]
    add(c, v, [(0, 2, 3, 1), (4, 5, 7, 6), (0, 1, 5, 4), (2, 6, 7, 3), (0, 4, 6, 2), (1, 3, 7, 5)])

box("Box", -0.5, 0.5, -0.5, 0.5, 0, BODY_TOP)
box("Lid", -LID_HALF, LID_HALF, -LID_HALF, LID_HALF, BODY_TOP, LID_TOP)
t = 0.018                                 # ribbon stands proud of the faces
box("Ribbon", -RIB, RIB, -0.5 - t, 0.5 + t, -0.001, BODY_TOP)
box("Ribbon", -0.5 - t, 0.5 + t, -RIB, RIB, -0.001, BODY_TOP)
box("Ribbon", -RIB, RIB, -LID_HALF - t, LID_HALF + t, BODY_TOP - 0.002, LID_TOP + t)
box("Ribbon", -LID_HALF - t, LID_HALF + t, -RIB, RIB, BODY_TOP - 0.002, LID_TOP + t)
# knot (x 268-328, y 65-125; side 736-803)
box("Ribbon", X(268), X(328), -0.1, 0.1, Z(125), Z(65))

def resample(poly, c, n=16):
    """n points on the polygon outline, one per angle around c (polygon must be star-shaped from c)."""
    out = []
    for i in range(n):
        a = 2 * math.pi * i / n; d = (math.cos(a), math.sin(a)); best = None
        for j in range(len(poly)):
            p, q = poly[j], poly[(j + 1) % len(poly)]
            ex, ey = q[0] - p[0], q[1] - p[1]; den = d[0] * ey - d[1] * ex
            if abs(den) < 1e-9: continue
            s = ((p[0] - c[0]) * ey - (p[1] - c[1]) * ex) / den; u = ((p[0] - c[0]) * d[1] - (p[1] - c[1]) * d[0]) / den
            if s > 0 and 0 <= u <= 1 and (best is None or s < best): best = s
        out.append((c[0] + d[0] * best, c[1] + d[1] * best))
    return out

# bow loops (front view px): chunky rings, right loop traced, left mirrored
OUT = [(326, 118), (331, 72), (352, 42), (378, 33), (408, 36), (433, 54), (442, 80), (440, 101), (424, 113), (372, 118)]
HOLE = [(341, 99), (349, 82), (368, 67), (391, 62), (407, 71), (411, 88), (398, 100), (362, 104)]
D = 83 * S / 2                            # loop depth (side view 728-811)
for side in (1, -1):
    o = resample(OUT, (386, 84)); h = resample(HOLE, (386, 84))
    if side < 0: o = [(2 * CX - x, y) for x, y in o][::-1]; h = [(2 * CX - x, y) for x, y in h][::-1]
    n = len(o); verts = []
    for y in (-D, D):
        verts += [Vector((X(x), y, Z(z))) for x, z in o] + [Vector((X(x), y, Z(z))) for x, z in h]
    fo, fh, bo, bh = 0, n, 2 * n, 3 * n
    faces = []
    for k in range(n):
        k1 = (k + 1) % n
        faces += [(fo + k, fo + k1, fh + k1, fh + k), (bo + k, bh + k, bh + k1, bo + k1),
                  (fo + k, bo + k, bo + k1, fo + k1), (fh + k, fh + k1, bh + k1, bh + k)]
    add("Ribbon", verts, faces)

# tails: flat strips from the knot over the lid's front edge, V-notched ends (front view rows 118-207)
TAIL = [(268, 118), (215, 110), (160, 186), (204, 178), (229, 206), (238, 170)]
def ty(z):                                # depth: from the knot (y 0) forward to the lid front face
    f = min(max((Z(112) - z) / (Z(112) - LID_TOP), 0), 1)
    return -(LID_HALF + t + 0.012) * f if z < LID_TOP else -(LID_HALF + t + 0.012) * f
for side in (1, -1):
    pts = [((2 * CX - x) if side < 0 else x, y) for x, y in TAIL]
    if side < 0: pts = pts[::-1]
    fr = [Vector((X(x), ty(Z(y)) - 0.012, Z(y))) for x, y in pts]
    bk = [Vector((p.x, p.y + 0.03, p.z)) for p in fr]
    n = len(pts)
    faces = [tuple(range(n)), tuple(range(2 * n - 1, n - 1, -1))] + [(k, n + k, n + (k + 1) % n, (k + 1) % n) for k in range(n)]
    add("Ribbon", fr + bk, faces)

for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
sc = bpy.context.scene
for c in COL:
    me = bpy.data.meshes.new("PR_" + c); me.from_pydata(V[c], [], F[c]); me.validate()
    bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    if c in ("Box", "Lid"):              # slightly bevelled edges, like the sheet
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=0.025, segments=1, affect="EDGES", profile=0.5)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(me); bm.free()
    for p in me.polygons: p.use_smooth = False
    o = bpy.data.objects.new(c, me); o["xmas_part"] = "present"
    m = bpy.data.materials.new("PR_" + c); m.use_nodes = True
    next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = COL[c]; m.diffuse_color = COL[c]
    me.materials.append(m); sc.collection.objects.link(o)
    print(c, len(me.polygons), "tris")
# gate render: front view over the whole 1536x1024 sheet frame
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
cam.data.type = "ORTHO"; cam.data.ortho_scale = 1536 * S
cam.location = (X(768), -30, Z(512)); cam.rotation_euler = (math.pi / 2, 0, 0)
sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.light = "FLAT"; sc.display.shading.color_type = "MATERIAL"
sc.render.film_transparent = True; sc.render.resolution_x, sc.render.resolution_y, sc.render.resolution_percentage = 1536, 1024, 100
os.makedirs(os.path.join(HERE, "gate"), exist_ok=True)
sc.render.filepath = os.path.join(HERE, "gate", "front.png"); bpy.ops.render.render(write_still=True)
# side gate: sheet SIDE centre x 770, camera from +X looking -X (image right = +Y)
cam.location = (30, -(770 - 768) * S + 0, Z(512)); cam.rotation_euler = (math.pi / 2, 0, math.pi / 2)
sc.render.filepath = os.path.join(HERE, "gate", "side.png"); bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)
for o in sc.objects: o.select_set(o.get("xmas_part") == "present")
bpy.ops.export_scene.gltf(filepath=os.path.join(HERE, "Present.glb"), use_selection=True, export_format="GLB", export_yup=True)
print("glb", os.path.getsize(os.path.join(HERE, "Present.glb")))
