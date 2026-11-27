# GYM ARC Christmas yard props, from sheet.png (row 1 FENCE SECTION, row 2 STREET LAMP, row 3 LIGHT STRING; FRONT, SIDE, EXPLODED each).
# Headless: blender -b --factory-startup --python build_yardprops.py -> Fence.glb, Lamp.glb, LightString.glb + gate/*.png
# Front = -Y, X right, Z up. One object per colour = one MeshPart. Studio scales each copy to the old one.
# Units: fence post-to-post span = 1 (origin = between the posts on the ground); lamp height = 1 (origin = base centre on the ground);
# light string hook span = 1 (origin = midpoint between the two hook ends).
import bpy, bmesh, math, os
from mathutils import Vector
HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\YardProps"
COL = {"Wood": (0.35, 0.18, 0.1, 1), "WoodDark": (0.27, 0.14, 0.08, 1), "Snow": (0.97, 0.97, 0.98, 1), "Wire": (0.1, 0.1, 0.11, 1),
       "Red": (0.86, 0.1, 0.12, 1), "Yellow": (0.98, 0.76, 0.12, 1), "Green": (0.16, 0.6, 0.22, 1), "Blue": (0.12, 0.42, 0.88, 1),
       "Iron": (0.11, 0.17, 0.14, 1), "Glass": (1.0, 0.9, 0.6, 1), "Pine": (0.13, 0.4, 0.17, 1)}

class M:
    def __init__(s): s.V = {k: [] for k in COL}; s.F = {k: [] for k in COL}
    def add(s, c, verts, faces):
        o = len(s.V[c]); s.V[c] += [tuple(v) for v in verts]; s.F[c] += [tuple(i + o for i in f) for f in faces]
    def box(s, c, x0, x1, y0, y1, z0, z1):
        v = [Vector((x, y, z)) for z in (z0, z1) for y in (y0, y1) for x in (x0, x1)]
        s.add(c, v, [(0, 2, 3, 1), (4, 5, 7, 6), (0, 1, 5, 4), (2, 6, 7, 3), (0, 4, 6, 2), (1, 3, 7, 5)])
    def lathe(s, c, prof, n=8, ctr=(0, 0), rot=math.pi / 8, cap=True):
        """solid of revolution about the Z axis through ctr from (r, z) pairs bottom to top."""
        rs = [[Vector((ctr[0] + r * math.cos(rot + 2 * math.pi * i / n), ctr[1] + r * math.sin(rot + 2 * math.pi * i / n), z)) for i in range(n)] for r, z in prof]
        verts = [v for rg in rs for v in rg]
        faces = [(k * n + i, k * n + (i + 1) % n, (k + 1) * n + (i + 1) % n, (k + 1) * n + i) for k in range(len(rs) - 1) for i in range(n)]
        if cap: faces += [tuple(range(n - 1, -1, -1)), tuple(range((len(rs) - 1) * n, len(rs) * n))]
        s.add(c, verts, faces)
    def pyramid(s, c, cx, cy, half, z0, z1, n=4):
        b = [Vector((cx + half * math.cos(math.pi / 4 + 2 * math.pi * i / n) * math.sqrt(2), cy + half * math.sin(math.pi / 4 + 2 * math.pi * i / n) * math.sqrt(2), z0)) for i in range(n)]
        s.add(c, b + [Vector((cx, cy, z1))], [tuple(range(n - 1, -1, -1))] + [(i, (i + 1) % n, n) for i in range(n)])

def bulb(m, c, x, z_top, S, w=16, h=46, ang=0.0):
    """C9 bulb hanging from z_top: black socket then a teardrop pointing down (sheet: 32 px wide, ~46 px tall), tilted by ang about Y."""
    n0 = {k: len(v) for k, v in m.V.items()}
    m.lathe("Wire", [(12 * S, z_top - 14 * S), (12 * S, z_top + 5 * S)], 4, (x, 0))
    prof = [(0.01 * S, z_top - 12 * S - h * S), (w * 0.55 * S, z_top - 12 * S - h * 0.82 * S), (w * S, z_top - 12 * S - h * 0.45 * S),
            (w * 0.8 * S, z_top - 12 * S - h * 0.12 * S), (8 * S, z_top - 12 * S)]
    m.lathe(c, prof, 8, (x, 0))
    if ang:
        for k in (c, "Wire"):
            for i in range(n0[k], len(m.V[k])):
                vx, vy, vz = m.V[k][i]; dx, dz = vx - x, vz - z_top
                m.V[k][i] = (x + dx * math.cos(ang) + dz * math.sin(ang), vy, z_top - dx * math.sin(ang) + dz * math.cos(ang))

def wire(m, pts, r):
    """thin square tube through pts (x, z) in the XZ plane."""
    V, F = [], []
    for i, (x, z) in enumerate(pts):
        V += [Vector((x, -r, z - r)), Vector((x, r, z - r)), Vector((x, r, z + r)), Vector((x, -r, z + r))]
    for i in range(len(pts) - 1):
        F += [(4 * i + j, 4 * i + (j + 1) % 4, 4 * (i + 1) + (j + 1) % 4, 4 * (i + 1) + j) for j in range(4)]
    F += [(3, 2, 1, 0), tuple(4 * (len(pts) - 1) + j for j in range(4))]
    m.add("Wire", V, F)

def export(m, name, views):
    for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
    sc = bpy.context.scene; tot = 0
    for c in COL:
        if not m.V[c]: continue
        me = bpy.data.meshes.new(name + "_" + c); me.from_pydata(m.V[c], [], m.F[c]); me.validate()
        bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
        bmesh.ops.triangulate(bm, faces=bm.faces); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(me); bm.free()
        for p in me.polygons: p.use_smooth = False
        o = bpy.data.objects.new(c, me); o["xmas_part"] = name
        mt = bpy.data.materials.new(name + c); mt.use_nodes = True
        next(n for n in mt.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = COL[c]; mt.diffuse_color = COL[c]
        me.materials.append(mt); sc.collection.objects.link(o); tot += len(me.polygons)
        print(name, c, len(me.polygons), "tris")
    print(name, "TOTAL", tot)
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
    cam.data.type = "ORTHO"
    sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.light = "FLAT"; sc.display.shading.color_type = "MATERIAL"
    sc.render.film_transparent = True; sc.render.resolution_x, sc.render.resolution_y, sc.render.resolution_percentage = 1536, 1024, 100
    os.makedirs(os.path.join(HERE, "gate"), exist_ok=True)
    for view, (S, ox, oz, side) in views.items():
        cam.data.ortho_scale = 1536 * S
        if side: cam.location = (30, (768 - ox) * S, (oz - 512) * S); cam.rotation_euler = (math.pi / 2, 0, math.pi / 2)
        else: cam.location = ((768 - ox) * S, -30, (oz - 512) * S); cam.rotation_euler = (math.pi / 2, 0, 0)
        sc.render.filepath = os.path.join(HERE, "gate", name + "_" + view + ".png"); bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam, do_unlink=True)
    for o in sc.objects: o.select_set(o.get("xmas_part") == name)
    bpy.ops.export_scene.gltf(filepath=os.path.join(HERE, name + ".glb"), use_selection=True, export_format="GLB", export_yup=True)

# ---------- FENCE (posts 245-309 / 541-604, ground y 335; rails y 205-229 and 277-301; caps y 165-197, snow to y 133) ----------
S = 1 / 295.5; m = M(); CX, GY = 424.75, 335
X = lambda x: (x - CX) * S; Z = lambda y: (GY - y) * S
for p0, p1 in ((245, 309), (541, 604)):
    c = (p0 + p1) / 2; h = (p1 - p0) / 2 * S
    m.box("Wood", X(p0), X(p1), -h, h, 0, Z(197))
    m.box("WoodDark", X(c) - 37 * S, X(c) + 37 * S, -37 * S, 37 * S, Z(197), Z(171))           # cap block
    m.pyramid("Snow", X(c), 0, 37 * S, Z(171), Z(133))                                          # snow-topped pointed cap
for y0, y1 in ((203, 233), (275, 306)):
    m.box("Wood", X(300), X(550), -10 * S, 10 * S, Z(y1), Z(y0))
wire(m, [(X(x), Z(186 + 8 * (1 - ((x - 424) / 120) ** 2))) for x in range(309, 545, 12)], 2.5 * S)
for x, c in ((352, "Red"), (426, "Yellow"), (499, "Green")):
    bulb(m, c, X(x), Z(192), S, 16, 46)
export(m, "Fence", {"front": (S, CX, GY, False)})

# ---------- LAMP (cx 429.5, ground 760; base 388-472 tapering to pole 420-439 at y 690; lantern roof 387-471 at y 470) ----------
S = 1 / 335; m = M(); CX, GY = 429.5, 760
Z = lambda y: (GY - y) * S; R = lambda w: w / 2 * S
m.lathe("Iron", [(R(84), Z(760)), (R(84), Z(750)), (R(70), Z(742)), (R(58), Z(722)), (R(40), Z(700)), (R(34), Z(690))])
m.lathe("Iron", [(R(19), Z(690)), (R(19), Z(560))], 8)
m.lathe("Iron", [(R(24), Z(548)), (R(30), Z(540)), (R(30), Z(528))], 8)   # lantern seat
# lantern: glass frustum (wide top 72 px at y 480, 51 px at y 520), iron frame posts, roof and finial
m.lathe("Glass", [(R(40), Z(526)), (R(72), Z(480))], 6, rot=0)
for i in range(6):
    a = 2 * math.pi * i / 6
    for (r0, y0), (r1, y1) in [((R(37), 526), (R(69), 480))]:
        p0 = Vector((r0 * math.cos(a), r0 * math.sin(a), Z(y0))); p1 = Vector((r1 * math.cos(a), r1 * math.sin(a), Z(y1)))
        d = 3 * S; m.add("Iron", [p0 + Vector((-d, -d, 0)), p0 + Vector((d, -d, 0)), p0 + Vector((d, d, 0)), p0 + Vector((-d, d, 0)),
                                   p1 + Vector((-d, -d, 0)), p1 + Vector((d, -d, 0)), p1 + Vector((d, d, 0)), p1 + Vector((-d, d, 0))],
                         [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)])
m.lathe("Iron", [(R(78), Z(482)), (R(84), Z(470)), (R(40), Z(452)), (R(14), Z(446))], 6, rot=0)
m.lathe("Iron", [(R(6), Z(446)), (R(10), Z(440)), (R(12), Z(433)), (R(6), Z(426))], 6)
# bow + pine sprig on the pole (front, y 540-595)
for sg in (1, -1):
    m.add("Pine", [Vector((sg * 10 * S, -12 * S, Z(552))), Vector((sg * 42 * S, -6 * S, Z(532))), Vector((sg * 40 * S, -6 * S, Z(574))),
                   Vector((sg * 10 * S, -16 * S, Z(558)))], [(0, 1, 2, 3) if sg > 0 else (3, 2, 1, 0)])
    loop = [(sg * 2 * S, Z(550)), (sg * 34 * S, Z(534)), (sg * 34 * S, Z(568)), (sg * 2 * S, Z(560))]
    tail = [(sg * 2 * S, Z(558)), (sg * 16 * S, Z(562)), (sg * 26 * S, Z(592)), (sg * 15 * S, Z(584)), (sg * 7 * S, Z(596))]
    for poly in (loop, tail):
        pts = poly if sg > 0 else poly[::-1]; n = len(pts)
        fr = [Vector((x, -22 * S, z)) for x, z in pts]; bk = [Vector((x, -14 * S, z)) for x, z in pts]
        m.add("Red", fr + bk, [tuple(range(n)), tuple(range(2 * n - 1, n - 1, -1))] + [(i, n + i, n + (i + 1) % n, (i + 1) % n) for i in range(n)])
m.box("Red", -6 * S, 6 * S, -24 * S, -12 * S, Z(560), Z(549))
export(m, "Lamp", {"front": (S, CX, GY, False), "side": (S, 780, GY, True)})

# ---------- LIGHT STRING (wire 234-641 sagging y 869 -> ~899; 7 bulbs at x 257..616) ----------
S = 1 / 407; m = M(); CX, ZY = 437.5, 869
X = lambda x: (x - CX) * S; Z = lambda y: (ZY - y) * S
wy = lambda x: 869 + 36 * (1 - ((x - CX) / 203.5) ** 2)
wire(m, [(X(x), Z(wy(x))) for x in range(234, 646, 14)], 4 * S)
for x, c in zip((257, 315, 375, 436, 496, 556, 616), ("Red", "Yellow", "Green", "Blue", "Red", "Yellow", "Green")):
    slope = 72 * (x - CX) / 203.5 ** 2          # d(wy)/dx in px
    bulb(m, c, X(x), Z(wy(x) + 2), S, 17, 48, ang=-0.35 * math.atan(slope))
export(m, "LightString", {"front": (S, CX, ZY, False)})
