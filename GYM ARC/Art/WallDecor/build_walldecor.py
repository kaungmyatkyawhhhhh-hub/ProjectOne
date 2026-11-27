# GYM ARC Christmas wall decor, from sheet.png (row 1 WREATH, row 2 GARLAND SWAG, row 3 PEPPERMINT; FRONT, SIDE, EXPLODED each).
# Headless: blender -b --factory-startup --python build_walldecor.py -> Wreath.glb, Garland.glb, Peppermint.glb + gate/*.png
# Each model: origin = its centre, front = -Y (faces out of the wall), X right, Z up. One object per colour = one MeshPart.
# Units: wreath outer diameter = 1, garland hook span = 1, peppermint disc diameter = 1. Studio scales each copy to the old one.
import bpy, bmesh, math, os, random
from mathutils import Vector, Matrix
HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\WallDecor"
COL = {"Pine": (0.13, 0.4, 0.17, 1), "PineDark": (0.08, 0.28, 0.12, 1), "Red": (0.86, 0.1, 0.12, 1), "Gold": (0.96, 0.72, 0.12, 1),
       "Bulbs": (1.0, 0.92, 0.55, 1), "White": (0.97, 0.95, 0.92, 1), "Wrapper": (0.85, 0.76, 0.95, 1)}
random.seed(7)

class M:
    def __init__(s): s.V = {k: [] for k in COL}; s.F = {k: [] for k in COL}
    def add(s, c, verts, faces):
        o = len(s.V[c]); s.V[c] += [tuple(v) for v in verts]; s.F[c] += [tuple(i + o for i in f) for f in faces]
    def ico(s, c, p, r, sub=1, sq=(1, 1, 1), rot=None):
        bm = bmesh.new(); bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=1)
        R = rot or Matrix.Identity(3)
        s.add(c, [Vector(p) + R @ Vector((v.co.x * r * sq[0], v.co.y * r * sq[1], v.co.z * r * sq[2])) for v in bm.verts],
              [[v.index for v in f.verts] for f in bm.faces]); bm.free()
    def plate(s, c, pts, y0, y1):
        """flat polygon (x, z) extruded between y0 and y1."""
        n = len(pts); fr = [Vector((x, y0, z)) for x, z in pts]; bk = [Vector((x, y1, z)) for x, z in pts]
        s.add(c, fr + bk, [tuple(range(n)), tuple(range(2 * n - 1, n - 1, -1))] + [(i, n + i, n + (i + 1) % n, (i + 1) % n) for i in range(n)])

def bow(m, cx, cz, s, y0, y1, col="Red"):
    """ribbon bow traced from the wreath sheet (centre 250,268 px, 140 px wide), scaled by s (units per px)."""
    P = lambda pts, sg: [((cx + sg * (x - 250) * s), cz - (y - 268) * s) for x, y in pts]
    loop = [(262, 258), (318, 240), (324, 300), (262, 282)]
    tail = [(258, 284), (284, 286), (300, 366), (286, 352), (270, 372)]
    for sg in (1, -1):
        for poly in (loop, tail):
            pts = P(poly, sg)
            if sg < 0: pts = pts[::-1]
            m.plate(col, pts, y0, y1)
    m.plate(col, P([(238, 254), (262, 254), (264, 284), (236, 284)], 1), y0 - 0.3 * (y1 - y0), y1)

def export(m, name, gate_views):
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
    for view, (S, ox, oz, side) in gate_views.items():     # render over the whole sheet frame: model origin at sheet px (ox, oz)
        cam.data.ortho_scale = 1536 * S
        if side:
            cam.location = (30, (768 - ox) * S, (oz - 512) * S); cam.rotation_euler = (math.pi / 2, 0, math.pi / 2)
        else:
            cam.location = ((768 - ox) * S, -30, (oz - 512) * S); cam.rotation_euler = (math.pi / 2, 0, 0)
        sc.render.filepath = os.path.join(HERE, "gate", name + "_" + view + ".png"); bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam, do_unlink=True)
    for o in sc.objects: o.select_set(o.get("xmas_part") == name)
    bpy.ops.export_scene.gltf(filepath=os.path.join(HERE, name + ".glb"), use_selection=True, export_format="GLB", export_yup=True)

# ---------- WREATH (front: centre 245,190, outer R 145, hole r 67; side depth 579-667) ----------
S = 1 / 290; m = M()
RM, TUBE = 106 * S, 39 * S
for i in range(30):                                     # pine clumps round the ring, two staggered rows
    a = 2 * math.pi * i / 30; rr = RM + (0.25 if i % 2 else -0.45) * TUBE
    rot = Matrix.Rotation(random.uniform(0, 6.28), 3, "Y") @ Matrix.Rotation(random.uniform(0, 6.28), 3, "X")
    m.ico("Pine" if i % 3 else "PineDark", (rr * math.cos(a), 0, rr * math.sin(a)), 36 * S, 1, (1, 1.15, 1), rot)
for i in range(12):                                     # darker core ring behind, fills the gaps
    a = 2 * math.pi * (i + 0.5) / 12
    m.ico("PineDark", (RM * math.cos(a), 6 * S, RM * math.sin(a)), 40 * S, 0, (1, 0.8, 1))
for bx, bz in ((255, 92), (158, 142), (342, 151), (144, 230), (343, 237)):
    m.ico("Red", ((bx - 245) * S, -30 * S, (190 - bz) * S), 17 * S, 1)
bow(m, 0, (190 - 268) * S, S, -46 * S, -28 * S)
export(m, "Wreath", {"front": (S, 247, 200, False), "side": (S, 623, 200, True)})

# ---------- GARLAND SWAG (front: hooks ~ (55,470) and (405,470), dips to y 565 at x 230; bauble (245,600) r 22) ----------
S = 1 / 350; m = M()
X0, X1, YT, YB, XC = 70, 420, 478, 566, 245
def gy(x): return YT + (YB - YT) * (1 - ((x - XC) / (X1 - XC if x > XC else XC - X0)) ** 2)
N = 14
for i in range(N):
    x = X0 + 10 + (X1 - X0 - 20) * i / (N - 1)
    rot = Matrix.Rotation(random.uniform(0, 6.28), 3, "Y") @ Matrix.Rotation(random.uniform(0, 6.28), 3, "Z")
    m.ico("Pine" if i % 3 else "PineDark", ((x - 230) * S, 0, (470 - gy(x) - 10) * S), 48 * S, 1, (1, 0.8, 1.05), rot)
for i in range(6):                                      # warm bulbs on the front of the garland
    x = X0 + 40 + (X1 - X0 - 80) * i / 5
    m.ico("Bulbs", ((x - 230) * S, -26 * S, (470 - gy(x) - 8) * S), 9 * S, 0, (0.75, 0.75, 1.15))
m.ico("Gold", ((245 - 230) * S, -12 * S, (470 - 600) * S), 22 * S, 1)
m.ico("Gold", ((245 - 230) * S, -12 * S, (470 - 576) * S), 6 * S, 0)
for hx in (X0 + 8, X1 - 8):                             # small bows at the hooks
    bow(m, (hx - 230) * S, (470 - 462) * S, S * 0.7, -44 * S, -32 * S)
    m.add("PineDark", [], [])
for hx in (X0 - 3, X1 + 12):
    bm_ = [(hx - 8, 437), (hx + 8, 437), (hx + 8, 462), (hx - 8, 462)]
    m.plate("PineDark", [((x - 230) * S, (470 - y) * S) for x, y in bm_], -8 * S, 8 * S)
export(m, "Garland", {"front": (S, 230, 478, False)})

# ---------- PEPPERMINT (front: disc centre 244.5,846.5, R 117; wrappers to x 24 / 456; side thickness 45) ----------
S = 1 / 234; m = M()
R, D, NS, NR = 117 * S, 22 * S, 16, 4                   # 16 wedges = 8 red + 8 white, swirled
def pt(k, j, y):
    r = R * (0.92 if j == NR + 1 else j / NR) if j <= NR else R
    a = 2 * math.pi * k / (NS * 2) - 0.75 * (min(j, NR) / NR)
    return Vector((r * math.cos(a), y, r * math.sin(a)))
for side_y, flip in ((-D, False), (D, True)):            # front and back faces, each wedge 2 sub-steps wide, NR rings deep
    for w in range(NS):
        c = "Red" if w % 2 == 0 else "White"
        for j in range(NR):
            for kk in range(2):
                k = w * 2 + kk
                if j == 0:
                    f = [Vector((0, side_y, 0)), pt(k, 1, side_y), pt(k + 1, 1, side_y)]
                    m.add(c, f, [(0, 2, 1) if not flip else (0, 1, 2)])
                else:
                    q = [pt(k, j, side_y), pt(k, j + 1, side_y), pt(k + 1, j + 1, side_y), pt(k + 1, j, side_y)]
                    m.add(c, q, [(0, 3, 2, 1) if not flip else (0, 1, 2, 3)])
# rounded rim: the wedge colours carry round the edge (side view shows red/white bands)
for w in range(NS):
    c = "Red" if w % 2 == 0 else "White"
    for kk in range(2):
        k = w * 2 + kk
        a0, a1 = pt(k, NR, -D), pt(k + 1, NR, -D)
        def rim(p, y, s): return Vector((p.x * s, y, p.z * s))
        ring = [rim(a0, -D, 1), rim(a1, -D, 1), rim(a1, 0, 1.06), rim(a0, 0, 1.06), rim(a0, D, 1), rim(a1, D, 1)]
        m.add(c, ring, [(0, 1, 2, 3), (3, 2, 5, 4)])
# wrapper ends: pinched at the disc edge, flaring into a faceted fan (x 24-128 left, 361-456 right, 165 px tall)
for sg in (1, -1):
    x0, x1 = sg * (R - 8 * S), sg * (R + 98 * S)
    pinch = [Vector((x0, 8 * S * math.cos(a), 30 * S * math.sin(a))) for a in [2 * math.pi * i / 6 for i in range(6)]]
    fan = [Vector((x1 - sg * (14 * S if i % 2 else 0), 14 * S * math.cos(a), 86 * S * math.sin(a))) for i, a in enumerate([2 * math.pi * i / 6 for i in range(6)])]
    faces = [(i, (i + 1) % 6, 6 + (i + 1) % 6, 6 + i) for i in range(6)] + [tuple(range(6, 12)), tuple(range(5, -1, -1))]
    m.add("Wrapper", pinch + fan, faces)
export(m, "Peppermint", {"front": (S, 244.5, 846.5, False), "side": (S, 637.5, 846.5, True)})
