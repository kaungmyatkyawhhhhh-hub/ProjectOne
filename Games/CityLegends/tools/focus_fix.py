"""The Dearborn C346 Rallye (owner, 2026-11-06): the real names off, and small changes so it reads as our
own (Prompts/Better upgrade area and part shop.md, Part 2). Runs on auto_car.py's .blend, before
lambo/finish_car.py. Metres: front -Y, up +Z, ground 0, +X the car's left.

    blender -b --python tools/focus_fix.py -- in.blend out.blend

  * badges: the ovals (Logo parts), the chrome letters on the tailgate and grille
  * wheels: our own "Saetta Y5": five Y spokes, same size and fit, the tyre and disc stay
  * tips: round -> oval; diffuser: four small fins; spoiler: small end plates
  * "C346" on the tailgate
"""

import math
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

args = sys.argv[sys.argv.index("--") + 1 :]
src, out = args[0], args[1]
bpy.ops.wm.open_mainfile(filepath=src)
FONT = "C:/Windows/Fonts/arialbi.ttf"


def plain(name, rgb, rough=0.35, metal=0.0):
    """a material with a tiny picture of one colour (the FBX carries pictures, not plain colours)"""
    img = bpy.data.images.new(name + "_px", 4, 4)
    img.pixels = [v for _ in range(16) for v in (rgb[0] / 255, rgb[1] / 255, rgb[2] / 255, 1)]
    img.pack()
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    t = nt.nodes.new("ShaderNodeTexImage")
    t.image = img
    nt.links.new(t.outputs["Color"], b.inputs["Base Color"])
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    return m


# ------------------------------------------------------------------ badges
# the ovals go flat and take the paint: a hole would show the dark panel behind them
paint = bpy.data.objects["Body_RsMI_ChangeB_Decals_Pain"]
logo = bpy.data.objects.get("Body_RsMI_Logo1")
if logo:
    bm = bmesh.new()
    bm.from_mesh(logo.data)
    bm.transform(logo.matrix_world)
    bm.faces.ensure_lookup_table()
    uv = bm.loops.layers.uv.active
    groups = []
    seen = set()
    for f in bm.faces:
        if f.index in seen:
            continue
        stack, comp = [f], []
        seen.add(f.index)
        while stack:
            g = stack.pop()
            comp.append(g)
            for e in g.edges:
                for h in e.link_faces:
                    if h.index not in seen:
                        seen.add(h.index)
                        stack.append(h)
        groups.append(comp)
    # (faces of one badge touch: a badge is one group; drop any that isn't on the outside skin)
    for comp in groups:
        vs = {v for f in comp for v in f.verts}
        c = sum((v.co for v in vs), Vector()) / len(vs)
        n = sum((f.normal * f.calc_area() for f in comp), Vector())
        if n.length < 1e-9:
            continue
        n.normalize()
        print("FIX oval", [round(x, 3) for x in c], [round(x, 2) for x in n], len(comp))
        # (flat, a touch bigger and proud of the panel: it covers the seam round the old badge)
        big = len(comp) > 100
        for v in vs:
            v.co = v.co - n * (v.co - c).dot(n) * (1.0 if big else 0.9)
            if big:
                v.co = c + (v.co - c) * 1.14 + n * 0.0012
    for f in bm.faces:
        for l in f.loops:
            l[uv].uv = (0.4, 0.4)  # (the paint picture's plain blue)
    bm.transform(logo.matrix_world.inverted())
    bm.to_mesh(logo.data)
    bm.free()
    logo.data.materials.clear()
    logo.data.materials.append(paint.data.materials[0])
    bpy.ops.object.select_all(action="DESELECT")
    logo.select_set(True)
    paint.select_set(True)
    bpy.context.view_layer.objects.active = paint
    bpy.ops.object.join()
o = bpy.data.objects.get("SeeThrough_RsMI_Logo1")
if o:
    bpy.data.objects.remove(o, do_unlink=True)

CHROME = ["Body_RsMI_Exhaust1", "SeeThrough_RsMI_Exhaust1"]
BOXES = [
    ((-0.66, 1.6, 0.8), (-0.34, 2.25, 0.96)),  # RS, tailgate
    ((0.2, 1.6, 0.64), (0.58, 2.25, 0.78)),  # the name, tailgate
    ((0.28, -2.32, 0.46), (0.62, -1.9, 0.62)),  # RS, grille
]


def islands(bm):
    seen = set()
    for f in bm.faces:
        if f.index in seen:
            continue
        stack, comp = [f], []
        seen.add(f.index)
        while stack:
            g = stack.pop()
            comp.append(g)
            for e in g.edges:
                for h in e.link_faces:
                    if h.index not in seen:
                        seen.add(h.index)
                        stack.append(h)
        yield comp


cut = 0
for n in CHROME:
    o = bpy.data.objects.get(n)
    if not o:
        continue
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bm.faces.ensure_lookup_table()
    kill = []
    for comp in islands(bm):
        pts = [o.matrix_world @ v.co for f in comp for v in f.verts]
        lo = [min(p[i] for p in pts) for i in range(3)]
        hi = [max(p[i] for p in pts) for i in range(3)]
        for a, b in BOXES:
            if all(lo[i] >= a[i] and hi[i] <= b[i] for i in range(3)):
                kill += comp
                break
    if kill:
        bmesh.ops.delete(bm, geom=kill, context="FACES")
        bm.to_mesh(o.data)
        cut += len(kill)
    bm.free()
print("FIX letters cut", cut)

# ------------------------------------------------------------------ the steering wheel: only the wheel
# (the rim needs a wide pick, and that also takes bits of vent and dash: they go back to the body, or they
# would turn with the wheel)
tilt = math.radians(22)
axis = Vector((0, math.cos(tilt), math.sin(tilt)))
centre = Vector((0.36, -0.43, 0.925))
back = 0
for o in [x for x in bpy.data.objects if x.name.startswith("SteeringWheel")]:
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bm.faces.ensure_lookup_table()
    W = o.matrix_world
    out_faces = []
    for comp in islands(bm):
        far = 0
        for f in comp:
            for v in f.verts:
                d = (W @ v.co) - centre
                far = max(far, (d - axis * d.dot(axis)).length)
        if far > 0.218:
            out_faces += comp
    if out_faces:
        # a body part of the same material
        me2 = o.data.copy()
        o2 = bpy.data.objects.new("Body_FromWheel" + str(back), me2)
        bpy.context.scene.collection.objects.link(o2)
        o2.matrix_world = W
        bm2 = bmesh.new()
        bm2.from_mesh(me2)
        bm2.faces.ensure_lookup_table()
        ids = {f.index for f in out_faces}
        bmesh.ops.delete(bm2, geom=[f for f in bm2.faces if f.index not in ids], context="FACES")
        bm2.to_mesh(me2)
        bm2.free()
        bmesh.ops.delete(bm, geom=out_faces, context="FACES")
        bm.to_mesh(o.data)
        back += 1
        print("FIX wheel bits back to the body", o.name, len(ids))
    bm.free()

# ------------------------------------------------------------------ the oval on the steering wheel's hub
# (it goes on the hub's own leather)
sw = bpy.data.objects.get("SteeringWheel_t22")
hub = next((o for o in bpy.data.objects if o.name.startswith("SteeringWheel") and o.data.materials and o.data.materials[0].name == "uvMI_Leather_C1"), None)
if sw and hub:
    bm = bmesh.new()
    bm.from_mesh(sw.data)
    bm.faces.ensure_lookup_table()
    W = sw.matrix_world
    keep = hub.data.materials[0]
    if keep.name not in sw.data.materials:
        sw.data.materials.append(keep)
    idx = list(sw.data.materials).index(keep) if keep.name in [m.name for m in sw.data.materials] else 0
    moved = 0
    for comp in islands(bm):
        pts = [W @ v.co for f in comp for v in f.verts]
        lo = [min(p[i] for p in pts) for i in range(3)]
        hi = [max(p[i] for p in pts) for i in range(3)]
        print("FIX hub isle", len(comp), [round(x, 3) for x in lo], [round(hi[i] - lo[i], 3) for i in range(3)])
        if hi[0] - lo[0] < 0.11 and abs((lo[0] + hi[0]) / 2 - 0.36) < 0.02 and lo[2] > 0.84 and hi[2] < 1.0:
            for f in comp:
                f.material_index = idx
            moved += len(comp)
    bm.to_mesh(sw.data)
    bm.free()
    print("FIX hub oval faces", moved)

# ------------------------------------------------------------------ the tips: oval
o = bpy.data.objects["Body_RsMI_Exhaust1"]
M = o.matrix_world
Mi = M.inverted()
n_tip = 0
for sx in (1, -1):
    pts = [v for v in o.data.vertices if 0.36 < sx * (M @ v.co).x < 0.68 and (M @ v.co).y > 1.98 and 0.2 < (M @ v.co).z < 0.44]
    if pts:
        zs = [(M @ v.co).z for v in pts]
        mid = (min(zs) + max(zs)) / 2
        for v in pts:
            w = M @ v.co
            w.z = mid + (w.z - mid) * 0.78
            v.co = Mi @ w
        n_tip += len(pts)
print("FIX tip points", n_tip)

# ------------------------------------------------------------------ added small parts
dark = plain("Trim_Fins", (20, 21, 24), 0.4)
silver = plain("Trim_Script", (206, 208, 214), 0.25, 0.8)


def box_mesh(name, centre, size, mat, rot=None):
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
    bm.to_mesh(me)
    bm.free()
    me.materials.append(mat)
    ob = bpy.data.objects.new(name, me)
    ob.location = centre
    if rot:
        ob.rotation_euler = rot
    bpy.context.scene.collection.objects.link(ob)
    return ob


# the diffuser: four fins between the tips
for i, x in enumerate((-0.17, -0.06, 0.06, 0.17)):
    box_mesh(f"Body_Fin{i}", (x, 2.0, 0.28), (0.01, 0.13, 0.03), dark)

# the spoiler's end plates: on its outermost points
paint = bpy.data.objects["Body_RsMI_ChangeB_Decals_Pain"]
xs = [(paint.matrix_world @ v.co) for v in paint.data.vertices if (paint.matrix_world @ v.co).z > 1.3 and (paint.matrix_world @ v.co).y > 1.72]
if xs:
    tip = max(xs, key=lambda p: abs(p.x))
    print("FIX spoiler end", tip)
    for sx, name in ((1, "L"), (-1, "R")):
        box_mesh("Body_EndPlate" + name, (sx * (abs(tip.x) + 0.002), tip.y + 0.01, tip.z - 0.005), (0.007, 0.2, 0.06), dark)

# ------------------------------------------------------------------ C346 on the tailgate
dg = bpy.context.evaluated_depsgraph_get()
hit, P, N, *_ = bpy.context.scene.ray_cast(dg, Vector((-0.5, 3, 0.875)), Vector((0, -1, 0)), distance=3)
cu = bpy.data.curves.new("C346", "FONT")
cu.body = "C346"
cu.font = bpy.data.fonts.load(FONT)
cu.size = 0.058
cu.extrude = 0.0012
cu.align_x = "CENTER"
cu.align_y = "CENTER"
tx = bpy.data.objects.new("C346_src", cu)
bpy.context.scene.collection.objects.link(tx)
dg = bpy.context.evaluated_depsgraph_get()
me = bpy.data.meshes.new_from_object(tx.evaluated_get(dg))
bpy.data.objects.remove(tx, do_unlink=True)
me.materials.clear()
me.materials.append(silver)
ob = bpy.data.objects.new("Body_Script", me)
bpy.context.scene.collection.objects.link(ob)
nrm = N.normalized()
X = Vector((-1, 0, 0))
X = (X - nrm * X.dot(nrm)).normalized()
Y = nrm.cross(X)
ob.matrix_world = Matrix((X.to_4d(), Y.to_4d(), nrm.to_4d(), (P + nrm * 0.002).to_4d())).transposed()
for i in range(3):
    ob.matrix_world[i][3] = (P + nrm * 0.002)[i]
print("FIX script at", P, nrm)

# ------------------------------------------------------------------ our own wheels: Saetta Y5
rim_mat = plain("Rim_Saetta", (52, 54, 60), 0.3, 0.85)


def limb(bm, a, b, wa, wb, xa, xb, depth, sign):
    """one spoke piece from a to b (y, z in the wheel's plane): a tapered bar, its front a little narrower"""
    d = (b - a).normalized()
    n = Vector((-d.y, d.x))
    ring = []
    for p, w, x in ((a, wa, xa), (b, wb, xb)):
        face = []
        for (off, back) in ((-1, 0), (-0.55, 1), (0.55, 1), (1, 0)):
            q = p + n * (w * off)
            face.append(bm.verts.new((x - sign * depth * (1 - back) * 1.0, q.x, q.y)))
        ring.append(face)
    for i in range(3):
        bm.faces.new((ring[0][i], ring[1][i], ring[1][i + 1], ring[0][i + 1]) if sign > 0 else (ring[0][i + 1], ring[1][i + 1], ring[1][i], ring[0][i]))


def build_rim(cx, cy, cz, R, x_in, x_out):
    """in wheel-centred metres: cx axle x, sign outward"""
    sign = 1 if x_out > x_in else -1
    bm = bmesh.new()
    N = 56
    # the barrel: inner edge, barrel, the lip
    prof = [(x_in, R - 0.012), (x_in + sign * 0.018, R - 0.03), (x_out - sign * 0.045, R - 0.03), (x_out - sign * 0.02, R - 0.022), (x_out - sign * 0.006, R - 0.006), (x_out, R), (x_out - sign * 0.003, R + 0.004)]
    rings = []
    for x, r in prof:
        row = []
        for k in range(N):
            a = 2 * math.pi * k / N
            row.append(bm.verts.new((x, cy + r * math.cos(a), cz + r * math.sin(a))))
        rings.append(row)
    for j in range(len(rings) - 1):
        for k in range(N):
            k2 = (k + 1) % N
            f = (rings[j][k], rings[j][k2], rings[j + 1][k2], rings[j + 1][k])
            bm.faces.new(f if sign < 0 else f[::-1])
    # the hub: a shallow dish, a blank cap, five bolts
    hub_x = x_out - sign * 0.055
    r_hub = 0.062
    hub = [[bm.verts.new((hub_x + sign * dx, cy + r * math.cos(2 * math.pi * k / 24), cz + r * math.sin(2 * math.pi * k / 24))) for k in range(24)] for r, dx in ((r_hub, -0.03), (r_hub, 0.0), (0.04, 0.006), (0.03, 0.006))]
    for j in range(3):
        for k in range(24):
            k2 = (k + 1) % 24
            f = (hub[j][k], hub[j][k2], hub[j + 1][k2], hub[j + 1][k])
            bm.faces.new(f if sign < 0 else f[::-1])
    c = bm.verts.new((hub_x + sign * 0.006, cy, cz))
    for k in range(24):
        f = (hub[3][k], hub[3][(k + 1) % 24], c)
        bm.faces.new(f if sign < 0 else f[::-1])
    for s in range(5):
        a = 2 * math.pi * (s + 0.5) / 5
        py, pz = cy + 0.05 * math.cos(a), cz + 0.05 * math.sin(a)
        bolt = [[bm.verts.new((hub_x + sign * dx, py + 0.008 * math.cos(2 * math.pi * k / 8), pz + 0.008 * math.sin(2 * math.pi * k / 8))) for k in range(8)] for dx in (0.0, 0.006)]
        for k in range(8):
            k2 = (k + 1) % 8
            f = (bolt[0][k], bolt[0][k2], bolt[1][k2], bolt[1][k])
            bm.faces.new(f if sign < 0 else f[::-1])
        bm.faces.new(bolt[1] if sign < 0 else bolt[1][::-1])
    # five Y spokes: a stem, then two arms to the lip, dished towards the hub
    x_rim = x_out - sign * 0.022
    x_mid = hub_x + (x_rim - hub_x) * 0.55
    r_fork = R * 0.56
    for s in range(5):
        a = 2 * math.pi * s / 5
        u = Vector((math.cos(a), math.sin(a)))
        o2 = Vector((cy, cz))
        h = o2 + u * (r_hub - 0.008)
        fork = o2 + u * r_fork
        limb(bm, h, fork, 0.03, 0.023, hub_x + sign * 0.0, x_mid, 0.03, sign)
        for t in (-1, 1):
            at = a + t * 0.27
            end = o2 + Vector((math.cos(at), math.sin(at))) * (R - 0.024)
            limb(bm, fork, end, 0.0185, 0.015, x_mid, x_rim, 0.024, sign)
    bm.normal_update()
    return bm


done = 0
for key in ("FL", "FR", "RL", "RR"):
    old = bpy.data.objects[key + "_RsMI_ChangeA_Rim1"]
    st = bpy.data.objects.get(key + "_static_RsMI_ChangeA_Rim1")
    W = old.matrix_world
    corners = [W @ Vector(c) for c in old.bound_box]
    lo = [min(c[i] for c in corners) for i in range(3)]
    hi = [max(c[i] for c in corners) for i in range(3)]
    cy, cz = (lo[1] + hi[1]) / 2, (lo[2] + hi[2]) / 2
    R = (hi[1] - lo[1]) / 2
    left = key[1] == "L"
    x_out, x_in = (hi[0], lo[0]) if left else (lo[0], hi[0])
    bm = build_rim((lo[0] + hi[0]) / 2, cy, cz, R, x_in, x_out)
    Wi = W.inverted()
    for v in bm.verts:
        v.co = Wi @ v.co
    bm.to_mesh(old.data)
    bm.free()
    old.data.materials.clear()
    old.data.materials.append(rim_mat)
    old.name = key + "_Rim_Saetta"
    if st:
        bpy.data.objects.remove(st, do_unlink=True)
    done += 1
print("FIX wheels", done)

bpy.ops.wm.save_as_mainfile(filepath=out)
print("FIX saved", out)
