# STOMP EVOLUTION - STONE armour set, model v1 (first pass, 11 Nov 2026).
# Built from the approved sheet stomp_sheet_stage3_stone_v9_head_fixed.png: every size below is a pixel measured on that sheet.
# The sheet itself is the texture: each face takes its picture from the FRONT, SIDE or BACK view by the way it faces.
# Run in Blender: exec(open(r"<vault>\TITAN ARC\Art\Stone\stone_v1.py").read())   (rebuild from this script, never hand-edit)
import bpy, bmesh, math, random, os
from mathutils import Vector, Matrix

HERE = os.environ.get("STONE_DIR") or r"C:\ObsidianOne\Claude+Obsidian\TITAN ARC\Art\Stone"
TEX, EMIT = os.path.join(HERE, "stone_v9_tex.png"), os.path.join(HERE, "stone_v9_emit.png")
W, H = 1536.0, 1024.0
CXF, CXS, CXB, GY = 328.0, 778.0, 1212.0, 650.0     # centre x of the front / side / back view, ground line y (sheet px)
S = 0.01                                             # 1 sheet px = 1 cm; the set stands 6.08 m (scaled for Roblox later)
COLL = "StoneSet_v1"

def X(x): return x - CXF            # front-view x px -> model X (viewer's right = +X)
def Z(y): return GY - y             # sheet y px -> model height
def P(x, y, f): return Vector((X(x), -f, Z(y)))     # f = px towards the character's FRONT (Blender front is -Y)

def fresh():
    c = bpy.data.collections.get(COLL)
    if c:
        for o in list(c.objects): bpy.data.objects.remove(o, do_unlink=True)
    else:
        c = bpy.data.collections.new(COLL); bpy.context.scene.collection.children.link(c)
    return c

def finish(bm, name, pol="std", smooth=False):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    for p in me.polygons: p.use_smooth = smooth
    o = bpy.data.objects.new(name, me); o.scale = (S, S, S); o["pol"] = pol
    bpy.data.collections[COLL].objects.link(o); return o

def bevel_all(bm, off, seg=2):
    if off > 0:
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=off, segments=seg, profile=0.6, affect='EDGES')

def box(name, x0, x1, y0, y1, f0, f1, bev=8, pol="std", bottom=1.0, seg=2):
    """rounded box from sheet px: x0..x1 (front view), y0..y1 (top..bottom), f0..f1 (back..front). bottom = width ratio at the bottom."""
    bm = bmesh.new(); bmesh.ops.create_cube(bm, size=1.0)
    cx = (x0 + x1) / 2
    for v in bm.verts:
        t = 1.0 if v.co.z > 0 else bottom
        x = cx + v.co.x * (x1 - x0) * t; y = y0 if v.co.z > 0 else y1; f = f0 if v.co.y > 0 else f1
        v.co = P(x, y, f)
    bevel_all(bm, bev, seg); return finish(bm, name, pol)

def prism(name, pts, f0, f1, bev=3, pol="std", back=False):
    """a flat plate: polygon pts in sheet px (front view, or back view when back=True), pushed from f0 to f1."""
    bm = bmesh.new()
    cv = (lambda x: CXF - (x - CXB)) if back else (lambda x: x)
    a = [bm.verts.new(P(cv(x), y, f0)) for x, y in pts]; b = [bm.verts.new(P(cv(x), y, f1)) for x, y in pts]
    bm.faces.new(a); bm.faces.new(b[::-1]); n = len(pts)
    for i in range(n): bm.faces.new([a[i], b[i], b[(i + 1) % n], a[(i + 1) % n]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bevel_all(bm, bev, 1); return finish(bm, name, pol)

def octa(cx, cy, rx, ry, k=0.42):
    return [(cx - rx * (1 - k), cy - ry), (cx + rx * (1 - k), cy - ry), (cx + rx, cy - ry * (1 - k)), (cx + rx, cy + ry * (1 - k)),
            (cx + rx * (1 - k), cy + ry), (cx - rx * (1 - k), cy + ry), (cx - rx, cy + ry * (1 - k)), (cx - rx, cy - ry * (1 - k))]

def rock(name, x0, x1, y0, y1, f0, f1, n=22, seed=1, pol="std"):
    """a faceted boulder: the hull of random points, fitted exactly to the box x0..x1, y0..y1, f0..f1."""
    r = random.Random(seed); bm = bmesh.new(); pts = []
    for i in range(n):
        v = Vector((r.gauss(0, 1), r.gauss(0, 1), r.gauss(0, 1))).normalized() * r.uniform(0.82, 1.0); pts.append(v)
    mn = [min(p[i] for p in pts) for i in range(3)]; mx = [max(p[i] for p in pts) for i in range(3)]
    for p in pts:
        u = [(p[i] - mn[i]) / (mx[i] - mn[i]) for i in range(3)]
        bm.verts.new(P(x0 + u[0] * (x1 - x0), y0 + u[2] * (y1 - y0), f0 + u[1] * (f1 - f0)))
    bmesh.ops.convex_hull(bm, input=list(bm.verts))
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
    return finish(bm, name, pol)

def crystal(name, base, tip, rad, sides=6):
    b, t = P(*base), P(*tip); ax = (t - b); L = ax.length; ax.normalize()
    rot = Vector((0, 0, 1)).rotation_difference(ax).to_matrix().to_4x4()
    bm = bmesh.new(); r0 = [], []
    for k, (h, rr) in enumerate(((0.0, rad * 0.8), (0.62, rad))):
        for i in range(sides):
            a = 2 * math.pi * i / sides; r0[k].append(bm.verts.new(b + rot @ Vector((math.cos(a) * rr, math.sin(a) * rr, h * L))))
    top = bm.verts.new(t)
    for i in range(sides):
        j = (i + 1) % sides
        bm.faces.new([r0[0][i], r0[0][j], r0[1][j], r0[1][i]]); bm.faces.new([r0[1][i], r0[1][j], top])
    bm.faces.new(r0[0][::-1]); return finish(bm, name)

def head(name, cx, y0, y1, rad):
    bm = bmesh.new(); bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=32, radius1=rad, radius2=rad, depth=1.0)
    for v in bm.verts: v.co = P(cx + v.co.x, y0 if v.co.z > 0 else y1, -v.co.y)
    rim = [e for e in bm.edges if abs(e.verts[0].co.z - e.verts[1].co.z) < 1e-4]
    bmesh.ops.bevel(bm, geom=rim, offset=24, segments=5, profile=0.5, affect='EDGES'); return finish(bm, name, "head", True)

def build():
    fresh()
    # ---- body (dark slate under-layer) ----
    head("Head", 329, 60, 204, 71)
    box("Collar", 258, 398, 190, 218, -66, 66, 7)
    box("Chest", 200, 456, 205, 365, -78, 80, 14, "torso", bottom=0.86)
    box("Belt", 207, 441, 350, 397, -80, 82, 5, "torso")
    box("Hips", 215, 433, 395, 456, -72, 66, 10, "torso")
    for sx, nm in ((1, "R"), (-1, "L")):                      # R = the character's right = viewer's left in the front view
        m = lambda x: x if sx == 1 else 2 * CXF - x
        o = lambda a, b: (min(m(a), m(b)), max(m(a), m(b)))
        box("Thigh_" + nm, *o(200, 312), 440, 582, -78, 22, 8)
        prism("Knee_" + nm, octa(m(254), 505, 64, 30), 14, 60, 4)
        box("ShinBand_" + nm, *o(188, 316), 568, 600, -84, 28, 5)
        box("BootHeel_" + nm, *o(182, 312), 586, 650, -88, 34, 12)
        box("BootToe_" + nm, *o(180, 312), 606, 650, 0, 102, 18, seg=3)
    # ---- arms ----
    box("UpperArm_R", 98, 192, 250, 312, -66, 46, 10); box("Bracer_R", 68, 196, 292, 405, -83, 62, 9); box("Fist_R", 60, 180, 398, 462, -48, 62, 16, seg=3)
    box("UpperArm_L", 463, 552, 255, 312, -66, 46, 10); box("Bracer_L", 448, 572, 292, 405, -83, 62, 9); box("Fist_L", 468, 582, 398, 462, -48, 62, 16, seg=3)
    # ---- armour plates ----
    prism("ChestPlate", [(262, 215), (395, 215), (430, 262), (392, 330), (266, 330), (228, 262)], 76, 92, 4)
    prism("Core", [(332, 235), (362, 258), (362, 295), (332, 316), (302, 295), (302, 258)], 90, 106, 4)
    prism("Buckle", octa(332, 375, 40, 28), 80, 94, 3)
    sk = [(192, 397), (456, 397), (452, 432), (400, 442), (330, 470), (262, 442), (196, 432)]
    prism("SkirtFront", sk, 64, 80, 3); prism("SkirtBack", sk, -86, -70, 3)
    box("Tasset_R", 186, 214, 396, 446, -58, 58, 5); box("Tasset_L", 442, 470, 396, 446, -58, 58, 5)
    prism("BackSlab", [(1213, 155), (1300, 195), (1302, 330), (1262, 420), (1213, 470), (1165, 420), (1125, 330), (1128, 195)], -133, -92, 5, back=True)
    # ---- shoulders, crystals, floating shards ----
    rock("Boulder_R", 62, 240, 128, 282, -118, 52, 26, 7)
    rock("Slab_L", 412, 560, 166, 264, -76, 66, 20, 3)
    crystal("Crystal_1", (172, 136, -30), (172, 42, -23), 27)
    crystal("Crystal_2", (220, 140, -8), (228, 88, 6), 16)
    crystal("Crystal_3", (140, 140, -58), (135, 106, -74), 14)
    crystal("Crystal_4", (196, 138, -68), (202, 100, -84), 11)
    rock("Shard_1", 87, 120, 72, 118, -128, -96, 12, 11); rock("Shard_2", 65, 92, 132, 168, -153, -123, 12, 12)

def material():
    m = bpy.data.materials.get("StoneSet") or bpy.data.materials.new("StoneSet"); m.use_nodes = True
    nt = m.node_tree; nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial"); b = nt.nodes.new("ShaderNodeBsdfPrincipled")
    t = nt.nodes.new("ShaderNodeTexImage"); t.image = bpy.data.images.load(TEX, check_existing=True)
    e = nt.nodes.new("ShaderNodeTexImage"); e.image = bpy.data.images.load(EMIT, check_existing=True)
    nt.links.new(t.outputs["Color"], b.inputs["Base Color"]); nt.links.new(e.outputs["Color"], b.inputs["Emission Color"])
    b.inputs["Emission Strength"].default_value = 2.5; b.inputs["Roughness"].default_value = 0.85
    nt.links.new(b.outputs["BSDF"], out.inputs["Surface"]); return m

def uvs(mat):
    """each face takes its picture from the view it faces: FRONT, BACK or SIDE of the sheet."""
    for o in bpy.data.collections[COLL].objects:
        me = o.data; me.materials.clear(); me.materials.append(mat); pol = o.get("pol", "std")
        uv = me.uv_layers.new(name="sheet") if not me.uv_layers else me.uv_layers[0]
        for p in me.polygons:
            nx, nf, nz = p.normal.x, -p.normal.y, p.normal.z
            side = abs(nx) > abs(nf) and abs(nx) > 0.6 * abs(nz)
            for li in p.loop_indices:
                v = me.vertices[me.loops[li].vertex_index].co; x, f, z = v.x, -v.y, v.z
                if pol == "head" and nf < 0.35: u, y = 1205.0, 110.0 + 0.2 * (GY - z - 110.0) * 0      # plain yellow from the back of the head
                elif side and pol == "torso": u, y = CXB + f, GY - z                                       # flanks hidden by the arms: stone from the back view
                elif side: u, y = CXS + f, GY - z
                elif nf >= 0: u, y = CXF + x, GY - z
                else: u, y = CXB - x, GY - z
                uv.data[li].uv = (u / W, 1.0 - y / H)

def run():
    build(); uvs(material())
    print("StoneSet v1:", len(bpy.data.collections[COLL].objects), "parts,", sum(len(o.data.polygons) for o in bpy.data.collections[COLL].objects), "faces")

run()
