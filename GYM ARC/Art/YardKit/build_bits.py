# GYM ARC Winter Yard round-4 ground pieces (ChatGPT R3): Frost Titan sanctuary base (22 wide, blue-grey, faceted),
# photo-corner compacted-snow oval (18 x 14), gold-trimmed plinth for the lift's giant canes.
# Each object is built round its own origin (all symmetric) and placed in Studio by name.
import bpy, bmesh, math, os, json, random
HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\YardKit"
random.seed(7)
PAL = {"TitanBase": (166, 197, 219), "TitanRing": (152, 181, 202), "TitanEdge": (110, 140, 170), "PhotoSnow": (210, 226, 238),
       "PlinthRed": (150, 30, 42), "PlinthGold": (223, 182, 79)}
G = {}
def add(col, V, F):
    v_, f_ = G.setdefault(col, [[], []]); o = len(v_); v_ += V; f_ += [tuple(i + o for i in f) for f in F]

def disc(col, rx, ry, z0, z1, n, r_in=0.0, chamfer=0.0, jit=0.0):
    # flat prism ring/disc in Blender XY, z0..z1; chamfered top edge
    def pts(r_x, r_y, z): return [(r_x * math.cos(2 * math.pi * k / n) * (1 + (random.uniform(-jit, jit) if jit else 0)),
                                    r_y * math.sin(2 * math.pi * k / n), z) for k in range(n)]
    O0 = pts(rx, ry, z0); O1 = pts(rx - chamfer, ry - chamfer * ry / rx, z1)
    V = O0 + O1; F = [(k, (k + 1) % n, n + (k + 1) % n, n + k) for k in range(n)]
    if r_in > 0:
        I0 = pts(r_in, r_in * ry / rx, z0); I1 = pts(r_in, r_in * ry / rx, z1); b = len(V); V += I0 + I1
        F += [(b + n + k, b + n + (k + 1) % n, b + (k + 1) % n, b + k) for k in range(n)]
        F += [(n + k, n + (k + 1) % n, b + n + (k + 1) % n, b + n + k) for k in range(n)]
        F += [(b + k, b + (k + 1) % n, (k + 1) % n, k) for k in range(n)]
    else:
        F += [tuple(range(n, 2 * n)), tuple(reversed(range(n)))]
    add(col, V, F)

OFF = {"Titan": (0, 0), "Photo": (40, 0), "Plinth": (70, 0)}
# Titan sanctuary: outer edge band + ring + inner deck (top 0.28, the pedestal sits on it)
disc("TitanEdge", 11.6, 11.6, -0.3, 0.16, 24, r_in=10.9, chamfer=0.25)
disc("TitanRing", 10.9, 10.9, -0.3, 0.24, 24, r_in=9.4)
disc("TitanBase", 9.4, 9.4, -0.3, 0.28, 24)
s0 = len(G["TitanBase"][0])
# photo corner compacted snow oval, slightly irregular, low
for col in ("PhotoSnow",):
    v0 = len(G.get(col, [[]])[0]) if col in G else 0
disc("PhotoSnow", 9.0, 7.0, -0.3, 0.1, 18, chamfer=0.35, jit=0.05)
# cane plinth: dark red block + gold top band
disc("PlinthRed", 1.25, 1.25, 0.0, 0.55, 8, chamfer=0.08)
disc("PlinthGold", 1.32, 1.32, 0.45, 0.62, 8, r_in=1.0)

for o_ in list(bpy.data.objects): bpy.data.objects.remove(o_, do_unlink=True)
sc = bpy.context.scene; info = {}
GROUP = {"TitanBase": "Titan", "TitanRing": "Titan", "TitanEdge": "Titan", "PhotoSnow": "Photo", "PlinthRed": "Plinth", "PlinthGold": "Plinth"}
for col, (V, F) in G.items():
    ox, oy = OFF[GROUP[col]]; V = [(v[0] + ox, v[1] + oy, v[2]) for v in V]
    me = bpy.data.meshes.new("Bits_" + col); me.from_pydata(V, [], F); me.validate()
    bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(me); bm.free()
    for p in me.polygons: p.use_smooth = False
    ob = bpy.data.objects.new("Bits_" + col, me); sc.collection.objects.link(ob)
    m = bpy.data.materials.new("B_" + col); m.use_nodes = True; rgba = tuple(v / 255 for v in PAL[col]) + (1,)
    next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = rgba; m.diffuse_color = rgba
    me.materials.append(m)
    xs = [v[0] for v in V]; ys = [v[1] for v in V]; zs = [v[2] for v in V]
    # offset of this object's bbox centre from its group's origin, in Roblox axes (x, y=up, z=-blender y)
    info["Bits_" + col] = {"group": GROUP[col], "centre_off": [(min(xs) + max(xs)) / 2 - ox, (min(zs) + max(zs)) / 2, -((min(ys) + max(ys)) / 2 - oy)],
                           "tris": sum(len(p.vertices) - 2 for p in me.polygons)}
print("INFO", json.dumps(info))
json.dump(info, open(os.path.join(HERE, "bits_info.json"), "w"), indent=1)
bpy.ops.export_scene.gltf(filepath=os.path.join(HERE, "YardBits.glb"), export_format="GLB", export_yup=True)
