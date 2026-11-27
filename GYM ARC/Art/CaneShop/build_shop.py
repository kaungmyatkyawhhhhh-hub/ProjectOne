# GYM ARC Candy Cane Shop booth, built from turnaround_sheet.png (front x 155-817 / side x 997-1376, ground y 570).
# Headless: blender -b --factory-startup --python build_shop.py  -> CaneShop.glb + gate/front.png, side.png
# 1 unit = 1 stud. S = studs per sheet px (counter top 3.65 high, total 11.9). Origin = floor centre on the ground.
# Axes (Blender): X = booth width, -Y = the customer side (front), Z = up.
import bpy, bmesh, math, os, sys
from mathutils import Vector

HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\CaneShop"
S = 0.0215
GY = 570                          # ground line in the sheet
FX = 486                          # front view centre x
SX = 1000                         # side view: front edge of the floor
Z = lambda y: (GY - y) * S
X = lambda x: (x - FX) * S
U = lambda x: -((x - SX) * S - 4.0)   # side px -> Blender y (front at +4 -> flipped so the front is -Y)

COL = {"Red": (0.80, 0.07, 0.08, 1), "White": (0.96, 0.93, 0.88, 1), "Wood": (0.62, 0.36, 0.13, 1),
       "WoodDark": (0.40, 0.21, 0.08, 1), "Gold": (0.98, 0.70, 0.12, 1), "Bulbs": (1.0, 0.86, 0.45, 1),
       "Sign": (0.98, 0.95, 0.88, 1)}


class Acc:
    def __init__(s): s.v, s.f = [], []
    def add(s, verts, faces):
        o = len(s.v); s.v += [tuple(v) for v in verts]; s.f += [tuple(i + o for i in fc) for fc in faces]


A = {k: Acc() for k in COL}


def box(c, x0, x1, y0, y1, z0, z1):
    v = [(x, y, z) for z in (z0, z1) for y in (y0, y1) for x in (x0, x1)]
    A[c].add(v, [(0, 2, 3, 1), (4, 5, 7, 6), (0, 1, 5, 4), (2, 6, 7, 3), (0, 4, 6, 2), (1, 3, 7, 5)])


def cyl(c, cx, cy, z0, z1, r, n=10):
    v = [(cx + r * math.cos(2 * math.pi * i / n), cy + r * math.sin(2 * math.pi * i / n), z) for z in (z0, z1) for i in range(n)]
    A[c].add(v, [(i, (i + 1) % n, n + (i + 1) % n, n + i) for i in range(n)] + [tuple(range(n - 1, -1, -1)), tuple(range(n, 2 * n))])


def ico(c, p, r, sub=1):
    bm = bmesh.new(); bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=r)
    A[c].add([v.co + Vector(p) for v in bm.verts], [[v.index for v in f.verts] for f in bm.faces]); bm.free()


def cane_post(cx, cy, z0, z1, r, turns=5, n=12):
    """Red/white helical striped post: rings offset along a helix, each band between two rings one colour.
    Each band is its own closed ring tube so both colours are watertight."""
    bands = turns * 4
    h = (z1 - z0) / bands
    for k in range(bands):
        c = "Red" if k % 2 else "White"
        ring = lambda kk: [(cx + r * math.cos(2 * math.pi * i / n), cy + r * math.sin(2 * math.pi * i / n),
                            z0 + kk * h + (i / n) * h * 2 if 0 < kk < bands else z0 + kk * h) for i in range(n)]
        lo, hi = ring(k), ring(k + 1)
        # clamp so bands never cross the ends
        lo = [(a, b, min(max(z, z0), z1)) for a, b, z in lo]; hi = [(a, b, min(max(z, z0), z1)) for a, b, z in hi]
        ccen, cch = (cx, cy, sum(p[2] for p in lo) / n), (cx, cy, sum(p[2] for p in hi) / n)
        A[c].add(lo + hi + [ccen, cch], [(i, (i + 1) % n, n + (i + 1) % n, n + i) for i in range(n)]
                 + [(2 * n, (i + 1) % n, i) for i in range(n)] + [(2 * n + 1, n + i, n + (i + 1) % n) for i in range(n)])


def build():
    # floor platform (front x 160-815, y 540-570; side depth 1000-1375)
    box("Wood", X(160), X(815), U(1375), U(1000), 0, Z(540))
    box("WoodDark", X(165), X(810), U(1372), U(1003), Z(546), Z(540) + 0.02)   # plank seam strip on top edge
    # back wall (wood planks) + dark plank lines
    bw0, bw1 = U(1360), U(1318)
    box("Wood", X(248), X(728), bw0, bw1, Z(540), Z(118))
    for i in range(1, 6):
        x = X(248 + i * 80)
        box("WoodDark", x - 0.04, x + 0.04, bw1, bw1 + 0.03, Z(540), Z(118))
    # side walls with a window (side view x 1195-1355, window y 215-400)
    for sx in (X(240), X(728)):
        x0, x1 = (sx, sx + 0.35) if sx > 0 else (sx - 0.35 + 0.35, sx + 0.35)
        x0, x1 = (X(728), X(736)) if sx > 0 else (X(240), X(248))
        box("Wood", x0, x1, bw0, U(1195), Z(540), Z(215))
        box("Wood", x0, x1, bw0, U(1195), Z(400), Z(540))
        box("Wood", x0, x1, bw0, U(1290), Z(400), Z(215))
        box("Wood", x0, x1, U(1200), U(1195), Z(400), Z(215))
    # shelf (x 285-690, y 342-358) + 2 brackets
    box("Wood", X(285), X(690), U(1318), U(1250), Z(358), Z(342))
    # 3 santa hats on the shelf (cone + brim + pompom), centres x 350, 488, 618
    for hx in (350, 488, 618):
        cx, cy, zb = X(hx), U(1284), Z(342)
        n = 10
        brim_r, tip = 1.0, (cx + 0.55, cy, zb + 1.55)
        base = [(cx + 0.8 * math.cos(2 * math.pi * i / n), cy + 0.6 * math.sin(2 * math.pi * i / n), zb + 0.3) for i in range(n)]
        A["Red"].add(base + [tip, (cx, cy, zb + 0.3)], [(i, (i + 1) % n, n) for i in range(n)] + [(n + 1, (i + 1) % n, i) for i in range(n)])
        cyl("White", cx, cy, zb, zb + 0.4, 0.95, 10)
        ico("White", tip, 0.28, 1)
    # counter: red plank body (y 440-540), gold trim (430-445), wood top lip (400-430)
    cf, cb = U(1025), U(1120)
    box("Red", X(250), X(726), cb, cf, Z(540), Z(445))
    box("Wood", X(250), X(726), U(1196), cb + 0.01, Z(540), Z(430))   # counter body behind the red front, up to the side walls
    for i in range(1, 12):                               # plank grooves
        x = X(250 + i * 40)
        box("WoodDark", x - 0.03, x + 0.03, cf - 0.02, cf + 0.01, Z(536), Z(449))
    box("Gold", X(246), X(730), cb + 0.05, cf - 0.06, Z(445), Z(430))
    box("Wood", X(235), X(740), U(1195), U(1010), Z(430), Z(402))
    # gold feet + candy cane posts + gold caps (front x 188-247 / 728-788; side x 1120-1180)
    pc_y = U(1150)
    for px in (217, 758):
        cx = X(px)
        box("Gold", cx - 0.75, cx + 0.75, pc_y - 0.75, pc_y + 0.75, Z(540), Z(515))
        cane_post(cx, pc_y, Z(515), Z(245), 0.62, turns=5)
        box("Gold", cx - 0.72, cx + 0.72, pc_y - 0.72, pc_y + 0.72, Z(245), Z(225))
    # awning: 9 stripes, sloped from the back roof (side x 1300, y 118) to the front edge (x 1005, y 200)
    n = 9
    xa, xb = X(160), X(815)
    yf, yb_ = U(1005), U(1268)
    zf, zb_ = Z(185), Z(126)
    t = 0.55
    for k in range(n):
        c = "Red" if k % 2 == 0 else "White"
        x0 = xa + (xb - xa) * k / n; x1 = xa + (xb - xa) * (k + 1) / n
        v = [(x0, yf, zf), (x1, yf, zf), (x1, yb_, zb_), (x0, yb_, zb_)]
        v += [(a, b, z - t) for a, b, z in v]
        A[c].add(v, [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)])
        # scallop: a half disc hanging under the front edge, same colour
        m = 8
        cxs, rr = (x0 + x1) / 2, (x1 - x0) / 2
        arc = [(cxs + rr * math.cos(math.pi + math.pi * i / m), yf, zf - t + 0.05 - rr * 0.55 * math.sin(math.pi * i / m)) for i in range(m + 1)]
        front = arc; back = [(a, b + 0.12, z) for a, b, z in arc]
        A[c].add(front + back, [tuple(range(m, -1, -1)), tuple(range(m + 1, 2 * m + 2))]
                 + [(i, i + 1, m + 2 + i, m + 1 + i) for i in range(m)] + [(m, 0, m + 1, 2 * m + 1)])
    # side valances: thin red strip under each side edge of the awning
    for x0 in (xa, xb - 0.12):
        v = [(x0, yf, zf - t), (x0 + 0.12, yf, zf - t), (x0 + 0.12, yb_, zb_ - t), (x0, yb_, zb_ - t)]
        v += [(a, b, z - 0.45) for a, b, z in v]
        A["Red"].add(v, [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)])
    # flat wood roof over the booth body (side x 1170-1360, y 105-130)
    box("WoodDark", X(240), X(736), U(1360), U(1170), Z(130), Z(105))
    box("Wood", X(240), X(736), U(1300), U(1255), Z(215), Z(128))      # fascia between the awning and the roof
    # bulbs under the front edge (7 across) and 3 down each side edge
    for i in range(7):
        bx = X(220 + i * (760 - 220) / 6)
        ico("Bulbs", (bx, yf + 0.25, Z(238)), 0.36, 1)
        box("Gold", bx - 0.15, bx + 0.15, yf + 0.1, yf + 0.4, Z(225), Z(212))
    for x0 in (xa + 0.06, xb - 0.06):
        for j in range(1, 4):
            f = j / 4
            ico("Bulbs", (x0, yf + (yb_ - yf) * f, zf - t - 0.55 + (zb_ - zf) * f), 0.3, 1)
    # sign: white board x 285-692 y 20-115 with gold frame, red end posts + gold caps (x 245-285 / 692-730)
    sy0, sy1 = U(1200), U(1160)
    box("Sign", X(292), X(685), sy0, sy1, Z(108), Z(28))
    box("Gold", X(282), X(695), sy0 + 0.05, sy1 - 0.05, Z(118), Z(18))
    for ex in ((248, 284), (693, 729)):
        box("Red", X(ex[0]), X(ex[1]), sy0 + 0.1, sy1 - 0.1, Z(205), Z(40))
        box("Gold", X(ex[0]) - 0.08, X(ex[1]) + 0.08, sy0 + 0.05, sy1 - 0.05, Z(40), Z(28))
        box("Gold", X(ex[0]) - 0.08, X(ex[1]) + 0.08, sy0 + 0.05, sy1 - 0.05, Z(110), Z(98))


def make(sc, name, acc):
    me = bpy.data.meshes.new("CS_" + name); me.from_pydata(acc.v, [], acc.f); me.validate()
    bm = bmesh.new(); bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    for p in me.polygons: p.use_smooth = False
    o = bpy.data.objects.new(name, me); o["xmas_part"] = "shop"
    m = bpy.data.materials.new("CS_" + name); m.use_nodes = True
    bsdf = next(nd for nd in m.node_tree.nodes if nd.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = COL[name]; m.diffuse_color = COL[name]
    o.data.materials.append(m); sc.collection.objects.link(o)
    return o


def main():
    for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
    sc = bpy.context.scene
    build()
    objs = [make(sc, k, a) for k, a in A.items() if a.v]
    tot = 0
    for o in objs:
        n = sum(len(p.vertices) - 2 for p in o.data.polygons); tot += n
        bm = bmesh.new(); bm.from_mesh(o.data); op = sum(1 for e in bm.edges if not e.is_manifold); bm.free()
        print(o.name, n, "tris, open", op)
    print("TOTAL", tot)
    # gate renders: ortho front and side at the sheet's px scale, transparent
    os.makedirs(os.path.join(HERE, "gate"), exist_ok=True)
    cam = bpy.data.objects.new("GateCam", bpy.data.cameras.new("GateCam")); sc.collection.objects.link(cam); sc.camera = cam
    cam.data.type = "ORTHO"
    sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.light = "FLAT"; sc.display.shading.color_type = "MATERIAL"
    sc.render.film_transparent = True; sc.render.resolution_percentage = 100
    for name, w, h, loc, rot in (("front", 768, 600, (X(384), -50, Z(300)), (math.pi / 2, 0, 0)),
                                 ("side", 768, 600, (-50, U(1234), Z(300)), (math.pi / 2, 0, -math.pi / 2))):
        sc.render.resolution_x, sc.render.resolution_y = w, h
        cam.data.ortho_scale = w * S; cam.location = loc; cam.rotation_euler = rot
        sc.render.filepath = os.path.join(HERE, "gate", name + ".png"); bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam, do_unlink=True)
    for o in sc.objects: o.select_set(o.get("xmas_part") == "shop")
    bpy.ops.export_scene.gltf(filepath=os.path.join(HERE, "CaneShop.glb"), use_selection=True, export_format="GLB", export_yup=True)
    print("glb", os.path.getsize(os.path.join(HERE, "CaneShop.glb")))


main()
