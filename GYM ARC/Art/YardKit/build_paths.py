# GYM ARC Winter Yard path network (ChatGPT + Gemini round 1: "no walking paths, no central plaza").
# Low-poly flagstones (bevelled top via an inset top face), built in Roblox world X/Z (Blender y = -Roblox z).
# Main path 12 studs door -> tree plaza; 9-stud branches to shop / lift / Frost Titan; ring plaza round the tree
# with a gold outer border and a dark-red inner border. Prints each object's world bbox centre for placement.
import bpy, bmesh, math, os, random, json
from mathutils import Vector
HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\YardKit"
random.seed(5)
T = Vector((34, -152)); R_IN, R_OUT = 11.4, 19.0
PAL = {"Stone": (189, 207, 220), "StoneDark": (158, 175, 192), "Gold": (223, 182, 79), "RedTrim": (160, 29, 43)}
G = {}
TOP, BOT, INS = 0.28, -0.25, 0.14

def add(col, V, F):
    v_, f_ = G.setdefault(col, [[], []]); o = len(v_); v_ += V; f_ += [tuple(i + o for i in f) for f in F]

def slab(col, quad, top=TOP, ins=INS):
    # quad: 4 (x, z) Roblox corners CCW from above -> prism with inset top (chamfer)
    c = sum((Vector(q) for q in quad), Vector((0, 0))) / 4
    inner = [c + (Vector(q) - c) * max(0.0, 1 - ins / max(0.01, (Vector(q) - c).length)) for q in quad]
    b = lambda p, y: (p[0], -p[1], y)
    V = [b(q, BOT) for q in quad] + [b(q, top - 0.1) for q in quad] + [b(q, top) for q in inner]
    F = [(3, 2, 1, 0), (8, 9, 10, 11)]
    for k in range(4):
        k1 = (k + 1) % 4
        F += [(k, k1, 4 + k1, 4 + k), (4 + k, 4 + k1, 8 + k1, 8 + k)]
    # winding: Blender y = -z mirrors the plane, so flip all faces
    add(col, V, [tuple(reversed(f)) for f in F])

def jit(p, a=0.14): return Vector((p[0] + random.uniform(-a, a), p[1] + random.uniform(-a, a)))

def path(A, B, w, tile=2.6, gap=0.2):
    A, B = Vector(A), Vector(B); d = (B - A); L = d.length; d.normalize(); n = Vector((-d.y, d.x))
    rows = max(1, round(L / tile)); tl = L / rows; cols = max(1, round(w / tile)); tw = w / cols
    for r in range(rows):
        off = (tw / 2) if r % 2 else 0.0
        edges = [-w / 2] + [-w / 2 + off + tw * k for k in range(1, cols + (1 if off else 0))] + [w / 2]
        edges = sorted(set(round(e, 4) for e in edges if -w / 2 <= e <= w / 2))
        for k in range(len(edges) - 1):
            s0, s1 = edges[k] + gap / 2, edges[k + 1] - gap / 2
            if s1 - s0 < 0.6: continue
            l0, l1 = r * tl + gap / 2, (r + 1) * tl - gap / 2
            q = [A + d * l0 + n * s0, A + d * l1 + n * s0, A + d * l1 + n * s1, A + d * l0 + n * s1]
            q = [jit(p) for p in q]
            slab("StoneDark" if random.random() < 0.35 else "Stone", q)

def ring(r0, r1, col, step=2.6, gap=0.2, top=TOP, ins=INS, j=0.12):
    n = max(8, round(2 * math.pi * (r0 + r1) / 2 / step)); ph = random.uniform(0, 1)
    for k in range(n):
        a0 = 2 * math.pi * (k + ph) / n + gap / 2 / ((r0 + r1) / 2); a1 = 2 * math.pi * (k + 1 + ph) / n - gap / 2 / ((r0 + r1) / 2)
        q = [T + Vector((math.cos(a0), math.sin(a0))) * (r0 + gap / 2), T + Vector((math.cos(a1), math.sin(a1))) * (r0 + gap / 2),
             T + Vector((math.cos(a1), math.sin(a1))) * (r1 - gap / 2), T + Vector((math.cos(a0), math.sin(a0))) * (r1 - gap / 2)]
        if j: q = [jit(p, j) for p in q]
        slab(col if col else ("StoneDark" if random.random() < 0.35 else "Stone"), [q[0], q[3], q[2], q[1]] if True else q, top, ins)

# plaza
ring(R_IN - 0.7, R_IN, "RedTrim", step=3.2, gap=0.12, top=0.34, ins=0.08, j=0)
for r0 in (R_IN, R_IN + 2.55, R_IN + 5.1):
    ring(r0, min(r0 + 2.55, R_OUT), None)
ring(R_OUT, R_OUT + 0.9, "Gold", step=3.4, gap=0.12, top=0.38, ins=0.1, j=0)

def edge_pt(target, extra=0.0):
    d = (Vector(target) - T).normalized(); return T + d * (R_OUT + 0.9 + extra)
# main path: door (0,-94) -> plaza
path((0, -95), edge_pt((0, -95)), 12)
for tgt, stop in (((-24, -126), 7.5), ((-14, -172), 9.5), ((80, -162), 10.5)):
    a = edge_pt(tgt); b = Vector(tgt) - (Vector(tgt) - a).normalized() * stop
    path(a, b, 9)

for o_ in list(bpy.data.objects): bpy.data.objects.remove(o_, do_unlink=True)
sc = bpy.context.scene; info = {}
for col, (V, F) in G.items():
    me = bpy.data.meshes.new("Path_" + col); me.from_pydata([tuple(v) for v in V], [], F); me.validate()
    bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(me); bm.free()
    for p in me.polygons: p.use_smooth = False
    ob = bpy.data.objects.new("Path_" + col, me); sc.collection.objects.link(ob)
    m = bpy.data.materials.new("P_" + col); m.use_nodes = True; rgba = tuple(v / 255 for v in PAL[col]) + (1,)
    next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = rgba; m.diffuse_color = rgba
    me.materials.append(m)
    xs = [v[0] for v in V]; ys = [v[1] for v in V]; zs = [v[2] for v in V]
    cx, cy, cz = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, (min(zs) + max(zs)) / 2
    info["Path_" + col] = {"centre_roblox": [cx, cz, -cy], "size": [max(xs) - min(xs), max(zs) - min(zs), max(ys) - min(ys)],
                           "tris": sum(len(p.vertices) - 2 for p in me.polygons)}
print("INFO", json.dumps(info))
json.dump(info, open(os.path.join(HERE, "paths_info.json"), "w"), indent=1)
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
cam.data.type = "ORTHO"; cam.data.ortho_scale = 130; cam.location = (34, 140, 80); cam.rotation_euler = (0, 0, 0)
sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.light = "STUDIO"; sc.display.shading.color_type = "MATERIAL"
sc.render.resolution_x, sc.render.resolution_y = 900, 900
sc.render.filepath = os.path.join(HERE, "gate", "paths_top.png"); bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)
bpy.ops.export_scene.gltf(filepath=os.path.join(HERE, "YardPaths.glb"), export_format="GLB", export_yup=True)
print("glb", os.path.getsize(os.path.join(HERE, "YardPaths.glb")))
