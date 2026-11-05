"""Step 3, last stage of a converted car (owner, 2026-11-04: make the new imports look better, inside
and out). auto_car.py with "keep_big" leaves the whole model; this readies it for Studio:

  * badge parts go (whole parts by material, or faces by their place in a picture);
  * parts get plain names by what they are (Body_Paint, Body_Cabin, ...), no maker's names left;
  * hidden parts (engine, underbody) can be thinned, nothing else is;
  * a part over 17,000 triangles is cut into pieces, so the body and cabin keep every triangle
    (they used to be crushed to 18,000 each);
  * a screen drawn as emission gets its picture as the base colour too (the FBX carries that one);
  * a table of surface values for each part goes next to the .blend: roughness, metal, the normal
    picture and the glow picture. Studio's importer drops those, so after the Import 3D they are put on
    the parts as SurfaceAppearances by tools/lambo/PbrApply.luau.

    blender -b --python tools/lambo/finish_car.py -- in.blend out.blend spec.json

spec.json: {"id": "lambrini_x", "drop": ["word in a material name"], "cut_uv": [{"image": "Image_7",
  "rect": [x0, y0, x1, y1]}], "thin": {"Engine": 0.6}, "roles": {"word": "Role"}, "paint": ["word"]}
"""

import json
import os
import re
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

LIMIT = 17000
args = sys.argv[sys.argv.index("--") + 1 :]
src, out, spec_path = args[0], args[1], args[2]
spec = json.load(open(spec_path))
bpy.ops.wm.open_mainfile(filepath=src)
bpy.context.scene.tool_settings.mesh_select_mode = (False, False, True)  # (or the first separate takes it all)
BRAND = re.compile(r"Lamborghini|Aventador|Huracan|Revuelto|Gallardo|Superveloce|Superleggera|Sterrato|RewardRecycled|Performante|Murcielago|Urus|Ferrari|California|Speciale", re.I)

# word in the material's name (first match wins) -> (role, roughness, metal)
ROLES = [
    (r"paint|gallardo_base|1288050001", "Paint", 0.1, 0.0),
    (r"licenseplate|manufacturerplate", "Plate", 0.5, 0.0),
    (r"cluster|avemis|emiss$|dashboard", "Screen", 0.35, 0.0),
    (r"lightemissive", "LampGlow", 0.3, 0.0),
    (r"light", "Lamp", 0.16, 0.5),
    (r"carbon", "Carbon", 0.22, 0.0),
    (r"textured", "Forged", 0.28, 0.0),
    (r"seatbelt|belt", "Belt", 0.7, 0.0),
    (r"suede", "Suede", 0.8, 0.0),
    (r"leather", "Leather", 0.5, 0.0),
    (r"cabin_plastic", "CabinTrim", 0.45, 0.0),
    (r"interiortilling|interiort", "CabinTile", 0.6, 0.0),
    (r"interior|cabin|details_int", "Cabin", 0.5, 0.0),
    (r"engine", "Engine", 0.4, 0.3),
    (r"exhaust", "Exhaust", 0.25, 0.9),
    (r"grill|details_grid|grid", "Grille", 0.45, 0.3),
    (r"softtop", "SoftTop", 0.75, 0.0),
    (r"mirror", "Mirror", 0.06, 1.0),
    (r"calli?per|tire_brake|changea_brake|brake", "Brake", 0.28, 0.35),
    (r"disc|disk", "Disc", 0.35, 0.85),
    (r"tyre|tire|neuma|blur", "Tyre", 0.8, 0.0),
    (r"rim|hub|wheel", "Rim", 0.28, 0.85),
    (r"coloured|phong|details_ext|details_mat", "Trim", 0.25, 0.0),
    (r"base|chassis", "Base", 0.6, 0.0),
]
for word, role in spec.get("roles", {}).items():
    r = next((x for x in ROLES if x[1] == role), (None, role, 0.4, 0.0))
    ROLES.insert(0, (word, role, r[2], r[3]))
LENS = [(r"red_?g", "Lens_Red"), (r"or[a]?[gn]+e_?glass", "Lens_Orange"), (r"glass_light|d_glass|glass_surr", "Lens_Clear")]


def meshes():
    return [o for o in bpy.data.objects if o.type == "MESH"]


def tris(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


def mat_of(o):
    return next((m for m in o.data.materials if m), None)


def principled(m):
    return m.node_tree.nodes.get("Principled BSDF") if m and m.use_nodes and m.node_tree else None


def image_on(b, name):
    s = b.inputs.get(name) if b else None
    if not s or not s.is_linked:
        return None
    n = s.links[0].from_node
    for _ in range(5):
        if n.type == "TEX_IMAGE":
            return n.image
        nxt = next((i.links[0].from_node for i in n.inputs if i.is_linked), None)
        if nxt is None:
            return None
        n = nxt
    return None


# ------------------------------------------------------------------ what goes
report = {"dropped": [], "cut": 0}
removed = []  # where badges were (car metres): the spot on the nose gets a plain cover
for o in list(meshes()):
    m = mat_of(o)
    n = (m.name if m else "").lower()
    if re.search(r"badge", n) or any(w.lower() in n for w in spec.get("drop", [])):
        report["dropped"].append([o.name, tris(o)])
        removed += [tuple(o.matrix_world @ v.co) for v in o.data.vertices]
        bpy.data.objects.remove(o, do_unlink=True)

for c in spec.get("cut_uv", []):
    img = bpy.data.images[c["image"]]
    W, H = img.size
    x0, y0, x1, y1 = c["rect"]
    for o in meshes():
        slots = {i for i, m in enumerate(o.data.materials) if m and m.use_nodes and any(k.type == "TEX_IMAGE" and k.image == img for k in m.node_tree.nodes)}
        if not slots or not o.data.uv_layers:
            continue
        bm = bmesh.new()
        bm.from_mesh(o.data)
        uv = bm.loops.layers.uv.active
        kill = []
        for f in bm.faces:
            if f.material_index in slots:
                u = sum(l[uv].uv.x for l in f.loops) / len(f.loops) % 1.0
                v = sum(l[uv].uv.y for l in f.loops) / len(f.loops) % 1.0
                if x0 <= u * W <= x1 and y0 <= (1 - v) * H <= y1:
                    kill.append(f)
        if kill:
            removed += [tuple(o.matrix_world @ v.co) for f in kill for v in f.verts]
            bmesh.ops.delete(bm, geom=kill, context="FACES")
            bm.to_mesh(o.data)
            report["cut"] += len(kill)
        bm.free()

for c in spec.get("cut_box", []):
    # faces of the parts wearing a picture, inside a box in car metres (a badge in a shared atlas)
    img = bpy.data.images[c["image"]]
    x0, y0, z0, x1, y1, z1 = c["box"]
    for o in meshes():
        slots = {i for i, m in enumerate(o.data.materials) if m and m.use_nodes and any(k.type == "TEX_IMAGE" and k.image == img for k in m.node_tree.nodes)}
        if not slots:
            continue
        M = o.matrix_world
        bm = bmesh.new()
        bm.from_mesh(o.data)
        kill = []
        for f in bm.faces:
            if f.material_index in slots:
                q = M @ f.calc_center_median()
                if x0 <= q.x <= x1 and y0 <= q.y <= y1 and z0 <= q.z <= z1:
                    kill.append(f)
        if kill:
            bmesh.ops.delete(bm, geom=kill, context="FACES")
            bm.to_mesh(o.data)
            report["cut"] += len(kill)
        bm.free()

for c in spec.get("img_fill", []):
    # a logo pressed into a normal map: flat there
    img = bpy.data.images[c["image"]]
    W, H = img.size
    px = np.empty(W * H * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    px = px.reshape(H, W, 4)
    x0, y0, x1, y1 = c["rect"]
    r, g, b_ = [v / 255 for v in c.get("rgb", (128, 128, 255))]
    px[H - y1 : H - y0, x0:x1, :3] = (r, g, b_)
    img.pixels.foreach_set(px.ravel())
    img.update()
    img.pack()

# ------------------------------------------------------------------ pictures on the base colour
for m in bpy.data.materials:
    if not (m.use_nodes and m.node_tree):
        continue
    nt = m.node_tree
    b = principled(m)
    if b is None:
        tex = next((n for n in nt.nodes if n.type == "TEX_IMAGE"), None)
        if tex is None:
            continue
        img = tex.image
        nt.nodes.clear()
        o_ = nt.nodes.new("ShaderNodeOutputMaterial")
        b = nt.nodes.new("ShaderNodeBsdfPrincipled")
        b.name = "Principled BSDF"
        t = nt.nodes.new("ShaderNodeTexImage")
        t.image = img
        nt.links.new(t.outputs["Color"], b.inputs["Base Color"])
        nt.links.new(t.outputs["Color"], b.inputs["Emission Color"])
        b.inputs["Emission Strength"].default_value = 1.0
        nt.links.new(b.outputs["BSDF"], o_.inputs["Surface"])
        continue
    e = image_on(b, "Emission Color")
    if e is not None and image_on(b, "Base Color") is None:
        t = nt.nodes.new("ShaderNodeTexImage")
        t.image = e
        nt.links.new(t.outputs["Color"], b.inputs["Base Color"])

# ------------------------------------------------------------------ names, thinning, pieces
def role_of(m):
    n = (m.name if m else "").lower()
    for pat, role, rough, metal in ROLES:
        if re.search(pat, n):
            return role, rough, metal
    return "Trim", 0.4, 0.0


used = {}
looks = {}
# (biggest first: the body's own paint gets the plain name; "Body_Paint2" is Legends Customs' second colour)
for o in sorted(meshes(), key=tris, reverse=True):
    m = mat_of(o)
    role, rough, metal = role_of(m)
    n = (m.name if m else "").lower()
    head = o.name.split("_")[0]
    glass = o.name.startswith("SeeThrough") and "surr" not in n
    if glass:
        lens = next((r for p, r in LENS if re.search(p, n)), None)
        base = "SeeThrough_" + (lens or "Window")
        role = lens or "Window"
        rough, metal = 0.05, 0.0
    elif head in ("FL", "FR", "RL", "RR"):
        static = "_static" if o.name[3:9] == "static" else ""
        base = head + static + "_" + role
    elif head.startswith("SteeringWheel"):
        base = o.name.split(".")[0]  # the tilt is in the name; the game needs it
    elif o.name == "Body_ClusterArt":
        base, role = "Body_Screen", "Screen"
        rough, metal = 0.35, 0.0
    else:
        base = "Body_" + role
    # the first three of a name stay apart by material, so each gets its own surface values
    i = used.get(base, 0)
    used[base] = i + 1
    o.name = base if i == 0 or head.startswith("SteeringWheel") else "%s%d" % (base, i + 1)
    o.data.name = o.name
    b = principled(m)
    nor = image_on(b, "Normal")
    emi = image_on(b, "Emission Color")
    looks[o.name] = {"role": role, "r": rough, "m": metal, "n": nor.name if nor else None, "e": emi.name if emi else None}

def cover_nose():
    """the badge's spot on the nose: a thin paint-coloured cover that follows the body round it (owner,
    2026-10-22: every logo spot gets a plain cover; the badge leaves a hole or a dark plate)"""
    if not removed:
        return
    ylo = min((o.matrix_world @ Vector(c)).y for o in meshes() for c in o.bound_box)
    pts = np.array(removed)
    pts = pts[(np.abs(pts[:, 0]) < 0.2) & (pts[:, 1] < ylo + 0.75) & (pts[:, 2] > 0.38)]
    paints = [o for o in meshes() if looks.get(o.name, {}).get("role") == "Paint"]
    if len(pts) < 3 or not paints:
        return
    body = max(paints, key=tris)
    dg = bpy.context.evaluated_depsgraph_get()
    bvh = BVHTree.FromObject(body, dg)
    M = body.matrix_world.inverted()
    lo, hi = pts.min(axis=0), pts.max(axis=0)
    c = M @ Vector(((lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2, (lo[2] + hi[2]) / 2))
    half = Vector((hi - lo) / 2)
    r = max(half.x, 0.03)
    r2 = max(half.length * 0.8, r)
    if "cover" in spec:  # by hand, when the badge part also holds other pieces: [x, y, z, radius]
        c = M @ Vector(spec["cover"][:3])
        r = r2 = spec["cover"][3]
    # the way the body faces round the spot
    n = Vector()
    for dx in (-1.6, 1.6):
        hit = bvh.find_nearest(c + Vector((dx * r, 0, 0)))
        if hit[1] is not None:
            n += hit[1]
    n = (n + Vector((0, -0.2, 0.2))).normalized()
    if n.y > 0:
        n = -n
    u = (Vector((1, 0, 0)) - n * n.x).normalized()
    v = n.cross(u).normalized()
    rows = []
    for rad in (1.25, 1.45, 1.7):
        for k in range(32):
            a = k / 32 * 2 * np.pi
            pu, pv = rad * r2 * np.cos(a), rad * r2 * np.sin(a)
            o_ = c + u * pu + v * pv + n * 0.25
            loc, _, _, _ = bvh.ray_cast(o_, -n, 0.6)
            if loc is not None:
                rows.append((pu, pv, (loc - c).dot(n)))
    if len(rows) < 30:
        report["cover"] = "too few hits"
        return
    a_ = np.array(rows)
    A = np.c_[np.ones(len(a_)), a_[:, 0], a_[:, 1], a_[:, 0] ** 2, a_[:, 0] * a_[:, 1], a_[:, 1] ** 2]
    fit = np.linalg.lstsq(A, a_[:, 2], rcond=None)[0]
    h = lambda x, y: fit[0] + fit[1] * x + fit[2] * y + fit[3] * x * x + fit[4] * x * y + fit[5] * y * y
    RINGS, SEG = 8, 32
    R = r2 * 1.14
    verts = [c + n * (h(0, 0) + spec.get("cover_lift", 0.0012))]
    for i in range(1, RINGS + 1):
        for k in range(SEG):
            a = k / SEG * 2 * np.pi
            pu, pv = R * i / RINGS * np.cos(a), R * i / RINGS * np.sin(a)
            verts.append(c + u * pu + v * pv + n * (h(pu, pv) + spec.get("cover_lift", 0.0012)))
    faces = [(0, 1 + k, 1 + (k + 1) % SEG) for k in range(SEG)]
    for i in range(RINGS - 1):
        for k in range(SEG):
            a0, a1 = 1 + i * SEG + k, 1 + i * SEG + (k + 1) % SEG
            faces.append((a0, a0 + SEG, a1 + SEG, a1))
    me = bpy.data.meshes.new("Body_Paint_Cover")
    me.from_pydata([tuple(x) for x in verts], [], faces)
    me.update()
    me.uv_layers.new(name="UVMap")
    if me.polygons[0].normal.dot(n) < 0:
        for p_ in me.polygons:
            p_.flip()
        me.update()
    me.shade_smooth()
    me.materials.append(mat_of(body))
    ob = bpy.data.objects.new("Body_Paint_Cover", me)
    ob.matrix_world = body.matrix_world
    bpy.context.scene.collection.objects.link(ob)
    if body.parent:
        ob.parent = body.parent
        ob.matrix_parent_inverse = body.matrix_parent_inverse
    looks[ob.name] = dict(looks[body.name])
    report["cover"] = [round(x, 3) for x in (body.matrix_world @ c)] + [round(R, 3)]


cover_nose()


def cover_hub():
    """the steering hub: a plain round pad over the spot of the maker's shield (its own piece leaves a
    hole, and some wheels have it pressed in). spec "hub_px": [x, y, radius], the shield's middle in a
    480 x 400 view from c + (0, 0.55, 0.12) at c, 55 mm (c: the middle of the first wheel part)."""
    if "hub_px" not in spec:
        return
    parts = [o for o in meshes() if o.name.startswith("SteeringWheel")]
    first = sorted(parts, key=lambda o: o.name)[0]
    main = max(parts, key=tris)
    dg = bpy.context.evaluated_depsgraph_get()
    c0 = first.matrix_world @ (sum((Vector(q) for q in first.bound_box), Vector()) / 8)
    eye = c0 + Vector((0, 0.55, 0.12))
    f = (c0 - eye).normalized()
    side = f.cross(Vector((0, 0, 1))).normalized()
    up = side.cross(f)
    trees = [(BVHTree.FromObject(o, dg), o.matrix_world) for o in parts]

    def ray(px, py):
        d = (f * 55 + side * ((px - 240) / 480 * 36) + up * ((200 - py) / 480 * 36)).normalized()
        best = None
        for t, M in trees:
            inv = M.inverted()
            q = inv @ eye
            dd = (inv.to_3x3() @ d).normalized()
            loc, _, _, _ = t.ray_cast(q, dd, 2.0)
            if loc is not None:
                w = M @ loc
                if best is None or (w - eye).length < (best - eye).length:
                    best = w
        return best, d

    x, y, rpx = spec["hub_px"]
    hits = []
    for k in range(16):
        a = k / 16 * 2 * np.pi
        for ring in (1.15, 1.35):
            w, _ = ray(x + ring * rpx * np.cos(a), y + ring * rpx * np.sin(a))
            if w is not None:
                hits.append(tuple(w))
    if len(hits) < 8:
        report["hub"] = "too few hits"
        return
    h = np.array(hits)
    mean = h.mean(axis=0)
    _, _, axes = np.linalg.svd(h - mean, full_matrices=False)
    n = Vector(axes[2])
    if n.dot(eye - Vector(mean)) < 0:
        n = -n
    _, d = ray(x, y)
    t_ = (Vector(mean) - eye).dot(n) / d.dot(n)
    c = eye + d * t_
    R = (c - eye).length / 55 * (rpx / 480 * 36)
    # over the highest of the surface under it, or the pad sinks in and the shield's outline stays
    inner = []
    for k in range(16):
        a = k / 16 * 2 * np.pi
        for ring in (0.3, 0.6, 0.85, 1.0):
            w, _ = ray(x + ring * rpx * np.cos(a), y + ring * rpx * np.sin(a))
            if w is not None and abs((w - Vector(mean)).dot(n)) < 0.03:
                inner.append(tuple(w))
    both = np.array(hits + inner)
    top = float(((both - np.array(c)) @ np.array(n)).max())
    u = (Vector((1, 0, 0)) - n * n.x).normalized()
    v = n.cross(u).normalized()
    RINGS, SEG = 6, 36
    world = [c + n * (top + 0.0028)]
    for i in range(1, RINGS + 1):
        rho = i / RINGS
        for k in range(SEG):
            a = k / SEG * 2 * np.pi
            world.append(c + u * (R * rho * np.cos(a)) + v * (R * rho * np.sin(a)) + n * (top + 0.0028 - 0.0024 * rho * rho))
    faces = [(0, 1 + k, 1 + (k + 1) % SEG) for k in range(SEG)]
    for i in range(RINGS - 1):
        for k in range(SEG):
            a0, a1 = 1 + i * SEG + k, 1 + i * SEG + (k + 1) % SEG
            faces.append((a0, a0 + SEG, a1 + SEG, a1))
    inv = main.matrix_world.inverted()
    me = bpy.data.meshes.new("HubCover")
    me.from_pydata([tuple(inv @ w) for w in world], [], faces)
    me.update()
    me.uv_layers.new(name="UVMap")
    if (main.matrix_world.to_3x3() @ me.polygons[0].normal).dot(n) < 0:
        for p_ in me.polygons:
            p_.flip()
        me.update()
    me.shade_smooth()
    img = bpy.data.images.new("col_HubCover", 8, 8)
    img.pixels = [0.1, 0.1, 0.107, 1.0] * 64
    img.pack()
    m = bpy.data.materials.new("HubCover")
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    tex = m.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = img
    m.node_tree.links.new(tex.outputs["Color"], b.inputs["Base Color"])
    me.materials.append(m)
    ob = bpy.data.objects.new(main.name.split(".")[0], me)
    ob.matrix_world = main.matrix_world
    bpy.context.scene.collection.objects.link(ob)
    if main.parent:
        ob.parent = main.parent
        ob.matrix_parent_inverse = main.matrix_parent_inverse
    looks[ob.name] = {"role": "CabinTrim", "r": 0.45, "m": 0.0, "n": None, "e": None}
    report["hub"] = round(R, 3)


cover_hub()

# a dark plate behind a badge that went: its faces take the paint, so no badge shape stays
if spec.get("to_paint"):
    body = max((o for o in meshes() if looks.get(o.name, {}).get("role") == "Paint"), key=tris)
    paint_mat = mat_of(body)
    for o in list(meshes()):
        if not o.name.startswith("Body_") or looks.get(o.name, {}).get("role") == "Paint":
            continue
        M = o.matrix_world
        hit = np.zeros(len(o.data.polygons), dtype=bool)
        for i, poly in enumerate(o.data.polygons):
            q = M @ poly.center
            hit[i] = any(b[0] <= q.x <= b[3] and b[1] <= q.y <= b[4] and b[2] <= q.z <= b[5] for b in spec["to_paint"])
        if not hit.any():
            continue
        o.data.polygons.foreach_set("select", hit)
        o.data.update()
        bpy.ops.object.select_all(action="DESELECT")
        bpy.context.view_layer.objects.active = o
        o.select_set(True)
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_mode(type="FACE")
        bpy.ops.mesh.separate(type="SELECTED")
        bpy.ops.object.mode_set(mode="OBJECT")
        new = next(x for x in bpy.context.selected_objects if x != o)
        new.select_set(False)
        new.name = "Body_Paint_Nose%d" % len(looks)
        new.data.name = new.name
        for i in range(len(new.data.materials)):
            new.data.materials[i] = paint_mat
        looks[new.name] = dict(looks[body.name])
        report["to_paint"] = report.get("to_paint", 0) + int(hit.sum())

for word, k in spec.get("thin", {}).items():
    for o in meshes():
        if o.name.startswith("Body_" + word):
            bpy.context.view_layer.objects.active = o
            d = o.modifiers.new("thin", "DECIMATE")
            d.ratio = k
            bpy.ops.object.modifier_apply(modifier="thin")
            report.setdefault("thinned", []).append([o.name, tris(o)])


def split_big(o):
    """cut a big part into pieces of at most LIMIT triangles, nearest faces together"""
    me = o.data
    n = len(me.polygons)
    centres = np.empty(n * 3, dtype=np.float64)
    me.polygons.foreach_get("center", centres)
    centres = centres.reshape(n, 3)
    tcount = np.empty(n, dtype=np.int64)
    me.polygons.foreach_get("loop_total", tcount)
    tcount = tcount - 2
    groups = []

    def bisect(idx):
        if tcount[idx].sum() <= LIMIT:
            groups.append(idx)
            return
        c = centres[idx]
        ax = int(np.argmax(c.max(axis=0) - c.min(axis=0)))
        order = idx[np.argsort(c[:, ax], kind="stable")]
        half = np.searchsorted(np.cumsum(tcount[order]), tcount[order].sum() / 2)
        half = max(1, min(len(order) - 1, int(half)))
        bisect(order[:half])
        bisect(order[half:])

    bisect(np.arange(n))
    label = np.zeros(n, dtype=np.int32)
    for g, idx in enumerate(groups):
        label[idx] = g
    me.attributes.new("_piece", "INT", "FACE").data.foreach_set("value", label)
    base = o.name
    look = looks.pop(base)
    pieces = [o]
    bpy.ops.object.select_all(action="DESELECT")
    for g in range(1, len(groups)):
        cur = o.data
        lab = np.empty(len(cur.polygons), dtype=np.int32)
        cur.attributes["_piece"].data.foreach_get("value", lab)
        cur.polygons.foreach_set("select", lab == g)
        cur.update()
        bpy.context.view_layer.objects.active = o
        o.select_set(True)
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_mode(type="FACE")
        bpy.ops.mesh.separate(type="SELECTED")
        bpy.ops.object.mode_set(mode="OBJECT")
        new = next(x for x in bpy.context.selected_objects if x != o)
        new.select_set(False)
        pieces.append(new)
    for i, p in enumerate(pieces):
        p.name = "%s_p%d" % (base, i + 1)
        p.data.name = p.name
        if "_piece" in p.data.attributes:
            p.data.attributes.remove(p.data.attributes["_piece"])
        looks[p.name] = dict(look)
    return len(pieces)


for o in list(meshes()):
    if tris(o) > LIMIT:
        report.setdefault("split", []).append([o.name, tris(o), split_big(o)])

for m in bpy.data.materials:
    m.name = BRAND.sub("", m.name) or "Mat"
for img in bpy.data.images:
    w, h = img.size
    if max(w, h) > 1024:
        k = 1024 / max(w, h)
        img.scale(max(1, int(w * k)), max(1, int(h * k)))
        img.pack()

# ------------------------------------------------------------------ the surface table and its pictures
outdir = os.path.splitext(out)[0] + "_pbr"
os.makedirs(outdir, exist_ok=True)


def save(img, kind):
    path = os.path.join(outdir, "%s_%s.png" % (kind, re.sub(r"\W", "_", img.name)))
    if not os.path.exists(path):
        c = img.copy()
        c.scale(min(c.size[0], 512), min(c.size[1], 512))
        c.filepath_raw = path
        c.file_format = "PNG"
        c.save()
        bpy.data.images.remove(c)
    return os.path.basename(path)


table = {}
for name, l in looks.items():
    o = bpy.data.objects.get(name)
    if o is None or tris(o) == 0:
        continue
    e = dict(l)
    e["n"] = save(bpy.data.images[l["n"]], "n") if l["n"] and tris(o) >= 150 else None
    e["e"] = save(bpy.data.images[l["e"]], "e") if l["e"] else None
    e["tris"] = tris(o)
    b = principled(mat_of(o))
    base_img = image_on(b, "Base Color")
    e["base"] = base_img.name if base_img else None
    table[name] = e
json.dump({"id": spec["id"], "parts": table, "report": report, "tris": sum(tris(o) for o in meshes())}, open(os.path.splitext(out)[0] + ".pbr.json", "w"), indent=0)
bpy.ops.wm.save_as_mainfile(filepath=out)
print("FINISH", spec["id"], "parts", len(meshes()), "tris", sum(tris(o) for o in meshes()), json.dumps(report)[:400])
