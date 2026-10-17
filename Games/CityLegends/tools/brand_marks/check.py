import bpy, sys, re, json, math
from mathutils import Vector
sys.path.insert(0, "/tmp/claude-0/logo")
from picks import KEEP
from helpers import colour_at, median, lin2s
blend, car, outdir = sys.argv[-3], sys.argv[-2], sys.argv[-1]
bpy.ops.wm.open_mainfile(filepath=blend)
F = json.load(open("/tmp/claude-0/logo/final.json"))[car]
MARK = re.compile(r"badge|logo|emblem|letter|decal_badg|sign\b", re.I)
sc = bpy.context.scene
dg = bpy.context.evaluated_depsgraph_get()
def cast(o, d):
    hit, loc, nrm, idx, obj, _ = sc.ray_cast(dg, o, d)
    return (loc, nrm, idx, obj) if hit else None
wc = {k: bpy.data.objects[k].matrix_world @ (sum((Vector(v) for v in bpy.data.objects[k].bound_box), Vector()) / 8) for k in ("FL", "FR", "RL", "RR")}
mid = sum(wc.values(), Vector()) / 4
def B(a): return mid + Vector((-a[0], a[2], a[1]))
def Bd(a): return Vector((-a[0], a[2], a[1]))
def G(v): return [round(-v.x, 4), round(v.z, 4), round(v.y, 4)]
# badge-spot emblems: the badge's own front face (found before it goes)
for c in F["covers"]:
    if c.get("group"):
        p = B(c["at"]); out = Vector((0, 0.5, 1 if c["at"][2] > 0 else -1)).normalized()
        h = cast(p + Bd(out) * 0.6, -Bd(out))
        if h and (h[0] - p).length < max(0.06, c["w"]):
            n = h[1] if h[1].dot(Bd(out)) > 0 else -h[1]
            c["at"] = G(h[0] - mid); c["face"] = G(n)
        else:
            c["face"] = G(Bd(out))
for o in list(bpy.data.objects):
    if o.type == "MESH" and not o.name.startswith(("FL", "FR", "RL", "RR", "SteeringWheel")) and o.name not in KEEP.get(car, []):
        if MARK.search(o.name) or any(m and MARK.search(m.name) for m in o.data.materials):
            bpy.data.objects.remove(o)
    elif o.name.startswith("SeeThrough"): o.hide_render = True; o.hide_set(True)
bpy.context.view_layer.update()
dg = bpy.context.evaluated_depsgraph_get()
for c in F["covers"]:
    if c.get("group"):
        n = Bd(c["face"]); p = B(c["at"])
        right = n.cross(Vector((0, 0, 1))).normalized(); up = right.cross(n)
        ring = []
        for k in range(8):
            q = p + (right * math.cos(k * math.pi / 4) + up * math.sin(k * math.pi / 4)) * c["w"] * 0.62
            hh = cast(q + n * 0.3, -n)
            if hh: ring.append(colour_at(hh[3], hh[0], hh[2]))
        c["color"] = median(ring)
json.dump(F, open(f"/tmp/claude-0/logo/f2/{car}.json", "w"), indent=1)
# show them: blank covers in their colour, emblems as brand-coloured discs
def mat(col, emit=0):
    m = bpy.data.materials.new("c"); m.use_nodes = True; b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*[((x + 0.055) / 1.055) ** 2.4 if x > 0.04045 else x / 12.92 for x in col], 1)
    b.inputs["Roughness"].default_value = 0.5
    return m
EMB = {"BNW": (0.16, 0.47, 0.8), "Mercer": (0.85, 0.86, 0.9), "Lexis": (0.75, 0.76, 0.8), None: (1, 1, 0)}
def add(at, face, w, h, col, disc, z=0.004, tint=None):
    n = Bd(face).normalized(); p = B(at) + n * z
    if disc:
        bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=w / 2, depth=0.002, location=p)
    else:
        bpy.ops.mesh.primitive_cube_add(size=1, location=p)
        o = bpy.context.object; o.scale = (w, h, 0.002)
    o = bpy.context.object
    up = Vector((0, 0, 1)); xr = up.cross(n)
    if xr.length < 1e-6: xr = Vector((1, 0, 0))
    xr.normalize(); yr = n.cross(xr)
    from mathutils import Matrix
    o.matrix_world = Matrix((xr, yr, n)).transposed().to_4x4() @ Matrix.Diagonal((1, 1, 1, 1)) if False else (Matrix.Translation(p) @ Matrix((xr, yr, n)).transposed().to_4x4() @ (Matrix.Diagonal((w, h, 0.002, 1)) if not disc else Matrix.Diagonal((1, 1, 1, 1))))
    o.data.materials.append(mat(col))
    if tint:
        bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=w / 2 * 0.7, depth=0.002, location=p)
        e = bpy.context.object
        e.matrix_world = Matrix.Translation(p + n * 0.002) @ Matrix((xr, yr, n)).transposed().to_4x4()
        e.data.materials.append(mat(tint))
for c in F["covers"]:
    add(c["at"], c["face"], c["w"], c["h"], c["color"], c["shape"] == "disc", tint=EMB[F["brand"]] if c["kind"] == "emblem" else None)
for k, cp in F["caps"].items():
    s = -1 if cp["at"][0] < 0 else 1
    at = list(cp["at"]); at[0] += s * cp["surface"]
    add(at, [s, 0, 0], cp["r"] * 2, cp["r"] * 2, cp["color"], True, z=0.002, tint=EMB[F["brand"]] if F["brand"] else None)
# hub
hub = F["hub"]
sw = next((o for o in bpy.data.objects if o.name.startswith("SteeringWheel")), None)
if hub and sw:
    v = [sw.matrix_world @ x.co for x in sw.data.vertices]
    a = Vector(map(min, zip(*v))); b = Vector(map(max, zip(*v))); c = (a + b) / 2
    t = math.radians(int(re.match(r"SteeringWheel_t(\d+)", sw.name).group(1)))
    axis_g = Vector((0, -math.sin(t), -math.cos(t))); zg = -axis_g; xg = Vector((0, 1, 0)).cross(zg).normalized(); yg = zg.cross(xg)
    lp = hub["local"]; pg = xg * lp[0] + yg * lp[1] + zg * lp[2]
    fl = hub["face"]; fg = xg * fl[0] + yg * fl[1] + zg * fl[2]
    at = G(c - mid); at = [at[i] + pg[i] for i in range(3)]
    add(at, list(fg), hub["r"] * 2, hub["r"] * 2, hub["color"], True, z=0.008, tint=EMB[F["brand"]] if F["brand"] else None)
# render the same views as the grids, plus the hub and a wheel
w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True; w.node_tree.nodes["Background"].inputs[1].default_value = 3
sc.render.engine = "CYCLES"; sc.cycles.samples = 12; sc.cycles.use_denoising = False
cam = bpy.data.cameras.new("c"); co = bpy.data.objects.new("cam", cam); sc.collection.objects.link(co); sc.camera = co
views = json.load(open(f"/tmp/claude-0/logo/v/{car}.views.json"))
def shot(name, eye, look, lens, W, H):
    sc.render.resolution_x = W; sc.render.resolution_y = H; cam.lens = lens
    co.location = Vector(eye); co.rotation_euler = (Vector(look) - Vector(eye)).normalized().to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = f"{outdir}/{car}_{name}.png"; bpy.ops.render.render(write_still=True)
for k, v in views.items(): shot(k, v["eye"], v["look"], v["lens"], v["W"], v["H"])
if sw:
    shot("s", (c.x, c.y + 0.55, c.z + 0.2), tuple(c), 30, 560, 380)
