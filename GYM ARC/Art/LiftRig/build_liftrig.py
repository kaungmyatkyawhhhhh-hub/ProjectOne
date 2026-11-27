# GYM ARC Mega Gift Lift rig frame, from sheet.png (FRONT x 173-658, SIDE, TOP, EXPLODED: pad, hazard border, corner post, top beam, bulb, pulley, sign).
# Headless: blender -b --factory-startup --python build_liftrig.py -> LiftRig.glb + gate/front.png
# 1 unit = pad width (485 front px). Origin = pad bottom centre. Front = -Y. One object per colour = one MeshPart.
# No cable: MegaLiftService resizes the rig's own Cable part. The Pad object becomes the MeshPart named "Pad" (MegaLift uses rig.Pad).
import bpy, bmesh, math, os
from mathutils import Vector
HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\LiftRig"
CX, GY = 416, 382
S = 1 / 485
COL = {"Pad": (0.18, 0.19, 0.22, 1), "Hazard": (0.96, 0.77, 0.09, 1), "Black": (0.1, 0.1, 0.12, 1), "Red": (0.83, 0.13, 0.16, 1),
       "White": (0.96, 0.95, 0.92, 1), "Gold": (1.0, 0.78, 0.23, 1), "Bulbs": (1.0, 0.91, 0.63, 1)}
V = {k: [] for k in COL}; F = {k: [] for k in COL}

def add(c, verts, faces):
    o = len(V[c]); V[c] += [tuple(v) for v in verts]; F[c] += [tuple(i + o for i in f) for f in faces]

BOXF = [(0, 2, 3, 1), (4, 5, 7, 6), (0, 1, 5, 4), (2, 6, 7, 3), (0, 4, 6, 2), (1, 3, 7, 5)]
def box(c, x0, x1, y0, y1, z0, z1):     # px units (front view), z measured up from the ground
    v = [Vector((x * S, y * S, z * S)) for z in (z0, z1) for y in (y0, y1) for x in (x0, x1)]
    add(c, v, BOXF)

def ico(c, p, r):
    bm = bmesh.new(); bmesh.ops.create_icosphere(bm, subdivisions=1, radius=r * S)
    add(c, [v.co + Vector(p) * S for v in bm.verts], [[v.index for v in f.verts] for f in bm.faces]); bm.free()

PH, BW = 242, 24                          # pad half width, hazard border width
box("Pad", -PH + BW, PH - BW, -PH + BW, PH - BW, 0, 18)
# hazard border: diagonal yellow/black stripes round the pad (parallelogram blocks along each edge)
STEP, SK = 34, 14
for e in range(4):
    a = e * math.pi / 2; ca, sa = round(math.cos(a)), round(math.sin(a))
    rot = lambda x, y: (x * ca - y * sa, x * sa + y * ca)
    n = int(2 * PH / STEP)
    for i in range(n):
        u0 = -PH + i * 2 * PH / n; u1 = u0 + 2 * PH / n
        # footprint along the edge y in [-PH, -PH+BW], ends slanted by SK
        quad = [(u0, -PH), (u1, -PH), (u1 + SK, -PH + BW), (u0 + SK, -PH + BW)]
        quad = [(min(max(x, -PH + (BW if j > 1 else 0)), PH - (BW if j > 1 else 0)), y) for j, (x, y) in enumerate(quad)]
        pts = [rot(x, y) for x, y in quad]
        verts = [Vector((x * S, y * S, 0)) for x, y in pts] + [Vector((x * S, y * S, 22 * S)) for x, y in pts]
        add("Hazard" if i % 2 == 0 else "Black", verts, [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)])

PO, PW = 197, 44                          # post outer half extent, post width
TOP = 317
for sx in (-1, 1):
    for sy in (-1, 1):
        cx, cy = sx * (PO - PW / 2), sy * (PO - PW / 2)
        box("Black", cx - 30, cx + 30, cy - 30, cy + 30, 18, 42)           # foot
        # candy stripes: bands between parallel slanted planes z = a + 0.5 (x + y) (local), 30 px tall
        h = PW / 2; corners = [(-h, -h), (h, -h), (h, h), (-h, h)]
        a, k = 42, 0
        while a < TOP:
            b = min(a + 30, TOP)
            zf = lambda base, x, y: min(max(base + 0.5 * (x + y), 42), TOP) if base > 42 and base < TOP else base
            lo = [Vector(((cx + x) * S, (cy + y) * S, (zf(a, x, y)) * S)) for x, y in corners]
            hi = [Vector(((cx + x) * S, (cy + y) * S, (zf(b, x, y)) * S)) for x, y in corners]
            add("Red" if k % 2 == 0 else "White", lo + hi, [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)])
            a, k = b, k + 1
        box("Red", cx - 26, cx + 26, cy - 26, cy + 26, TOP - 1, TOP + 40)   # cap
        for gx in (-12, 12):                                                 # gold studs on the cap front/sides
            box("Gold", cx + gx - 4, cx + gx + 4, cy - 27, cy - 25, TOP + 26, TOP + 34)
# top frame: 4 gold perimeter beams between the caps, a lower bulb rail inside, a centre cross
B0, B1 = TOP + 2, TOP + 34
for s in (-1, 1):
    box("Gold", -PO + 6, PO - 6, s * (PO - PW / 2) - 16, s * (PO - PW / 2) + 16, B0, B1)
    box("Gold", s * (PO - PW / 2) - 16, s * (PO - PW / 2) + 16, -PO + 6, PO - 6, B0, B1)
    box("Gold", -PO + PW, PO - PW, s * (PO - PW - 6) - 8, s * (PO - PW - 6) + 8, 282, 300)
    box("Gold", s * (PO - PW - 6) - 8, s * (PO - PW - 6) + 8, -PO + PW, PO - PW, 282, 300)
box("Gold", -PO + PW, PO - PW, -12, 12, B0 + 4, B1 - 4)
box("Gold", -12, 12, -PO + PW, PO - PW, B0 + 4, B1 - 4)
# marquee bulbs: under the perimeter beams (z 308) and on the inner rail (z 275), all 4 sides
for s in (-1, 1):
    for i in range(7):
        u = -123 + i * 41
        for p in ((u, s * (PO - PW / 2), 307), (s * (PO - PW / 2), u, 307)):
            ico("Bulbs", p, 9)
    for i in range(8):
        u = -115 + i * 33
        for p in ((u, s * (PO - PW - 6), 274), (s * (PO - PW - 6), u, 274)):
            ico("Bulbs", p, 8)
# pulley under the cross (x 398-438, y 82-122): dark block + gold wheel on its front
box("Black", -20, 20, -20, 20, 262, 302)
r, n = 11, 10
ring = lambda yy: [Vector((r * math.cos(2 * math.pi * i / n) * S, yy * S, (282 + r * math.sin(2 * math.pi * i / n)) * S)) for i in range(n)]
add("Gold", ring(-26) + ring(-20), [tuple(range(n)), tuple(range(2 * n - 1, n - 1, -1))] + [(i, (i + 1) % n, n + (i + 1) % n, n + i) for i in range(n)])
# sign: red board with a gold frame standing on the front beam (x 315-516, y 16-66)
fy = -(PO - PW / 2) - 18
box("Gold", -101, 101, fy - 6, fy + 2, TOP, TOP + 50)
box("Red", -93, 93, fy - 9, fy - 5, TOP + 6, TOP + 44)

for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
sc = bpy.context.scene; tot = 0
for c in COL:
    me = bpy.data.meshes.new("LR_" + c); me.from_pydata(V[c], [], F[c]); me.validate()
    bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
    bmesh.ops.triangulate(bm, faces=bm.faces); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(me); bm.free()
    for p in me.polygons: p.use_smooth = False
    o = bpy.data.objects.new(c, me); o["xmas_part"] = "liftrig"
    mt = bpy.data.materials.new("LR_" + c); mt.use_nodes = True
    next(n for n in mt.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = COL[c]; mt.diffuse_color = COL[c]
    me.materials.append(mt); sc.collection.objects.link(o); tot += len(me.polygons)
    print(c, len(me.polygons), "tris")
print("TOTAL", tot)
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
cam.data.type = "ORTHO"; cam.data.ortho_scale = 1536 * S
sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.light = "FLAT"; sc.display.shading.color_type = "MATERIAL"
sc.render.film_transparent = True; sc.render.resolution_x, sc.render.resolution_y, sc.render.resolution_percentage = 1536, 1024, 100
os.makedirs(os.path.join(HERE, "gate"), exist_ok=True)
cam.location = ((768 - CX) * S, -30, (GY - 512) * S); cam.rotation_euler = (math.pi / 2, 0, 0)
sc.render.filepath = os.path.join(HERE, "gate", "front.png"); bpy.ops.render.render(write_still=True)
# top gate: the sheet TOP view (pad 122-570 px, centre 346,702) is drawn 448/485 of the front scale
k = 448 / 485
cam.data.ortho_scale = 1536 * S / k
cam.location = ((768 - 346) * S / k, -(702 - 512) * S / k * -1, 30); cam.rotation_euler = (0, 0, 0)
sc.render.filepath = os.path.join(HERE, "gate", "top.png"); bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)
for o in sc.objects: o.select_set(o.get("xmas_part") == "liftrig")
bpy.ops.export_scene.gltf(filepath=os.path.join(HERE, "LiftRig.glb"), use_selection=True, export_format="GLB", export_yup=True)
print("glb", os.path.getsize(os.path.join(HERE, "LiftRig.glb")))
