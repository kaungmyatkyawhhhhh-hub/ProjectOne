"""nisun_r34 (2026-11-21): prepares Sketchfab "GTR-r34" by ARjun.JS (CC BY) for auto_car.py.

The model comes plain: every surface is a grey material times vertex colours (most white), and the whole
cabin (seats, dash, MFD, wheel, door cards, headliner) plus the chassis sit in two meshes wearing
"Front_grills". This script:
  * drops the badge pieces left in the export (Brembo caliper text, the small black caliper decal) and the
    front plate's picture face; turns the NISMO wheel-cap discs into plain rim covers;
  * gives every exterior material a role name with the BNR34's colours (r34_*);
  * cuts the cabin into loose pieces and gives each one a role by where it sits (seat cloth, dark plastic,
    door cards, headliner, carpet, leather wheel, alloy pedals, MFD glass), colours from photos of a stock
    BNR34 (black dash and console, black / grey cloth seats, grey door cloth, light grey headliner);
  * takes the vertex colours off (faces whose corners are all black become r34_black first).

    blender -b --factory-startup --python tools/logo_paint/nisun_r34_prep.py -- in.glb out.glb
"""

import sys

import bpy
import numpy as np

a = sys.argv[sys.argv.index("--") + 1 :]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a[0])

# role name -> (base colour 0-255, metal, roughness, alpha)
LOOK = {
    "r34_paint": ((40, 60, 150), 0.0, 0.25, 1),
    "r34_carbon": ((22, 22, 24), 0.0, 0.3, 1),
    "r34_grill": ((18, 18, 19), 0.2, 0.6, 1),
    "r34_trim": ((26, 26, 28), 0.0, 0.55, 1),
    "r34_rubber": ((14, 14, 14), 0.0, 0.85, 1),
    "r34_rim": ((24, 24, 26), 0.6, 0.3, 1),
    "r34_disc": ((120, 120, 122), 0.85, 0.35, 1),
    "r34_caliper": ((190, 20, 16), 0.3, 0.35, 1),
    "r34_tyre": ((22, 22, 22), 0.0, 0.85, 1),
    "r34_exhaust": ((150, 148, 145), 0.9, 0.25, 1),
    "r34_chrome": ((170, 170, 172), 1.0, 0.16, 1),
    "r34_glass": ((20, 24, 28), 0.0, 0.06, 0.35),
    "r34_lens_clear": ((230, 232, 235), 0.0, 0.06, 0.3),
    "r34_lens_red": ((170, 12, 14), 0.0, 0.1, 0.75),
    "r34_lens_orange": ((235, 120, 20), 0.0, 0.1, 0.75),
    "r34_lamp": ((200, 200, 205), 0.5, 0.2, 1),
    "r34_mirror": ((150, 155, 160), 1.0, 0.06, 1),
    "r34_black": ((12, 12, 13), 0.0, 0.7, 1),
    # cabin (stock BNR34 photos)
    "r34_cabin": ((30, 30, 32), 0.0, 0.7, 1),
    "r34_cabin_soft": ((44, 44, 47), 0.0, 0.8, 1),
    "r34_cloth": ((50, 51, 55), 0.0, 0.9, 1),
    "r34_cloth_insert": ((82, 85, 92), 0.0, 0.9, 1),
    "r34_door": ((40, 40, 43), 0.0, 0.8, 1),
    "r34_headliner": ((150, 148, 142), 0.0, 0.9, 1),
    "r34_carpet": ((24, 24, 25), 0.0, 0.95, 1),
    "r34_leather": ((22, 22, 23), 0.0, 0.55, 1),
    "r34_alloy": ((165, 165, 168), 0.85, 0.35, 1),
    "r34_screen": ((8, 10, 12), 0.0, 0.1, 1),
}

# exported material -> role (None = drop the mesh)
EXT = {
    "Main": "r34_paint",
    "Crabon_Fiber": "r34_carbon",
    "Crabon_Fiber.001": "r34_carbon",
    "Front_grills.001": "r34_grill",
    "Disc_normal": "r34_disc",
    "Disc_Spiral": "r34_disc",
    "material.001": "r34_caliper",
    "Material.021": None,  # "Brembo" text on the calipers
    "Material.022": None,  # small black caliper decal
    "Material.023": "r34_caliper",
    "material": "r34_rim",  # NISMO cap disc -> plain cover
    "material01": "r34_rim",  # NISMO cap lettering -> plain cover
    "Nismo_alloy": "r34_rim",
    "Tire": "r34_tyre",
    "Main_head_light_glass": "r34_lens_clear",
    "Main_head_light_glass.001": "r34_lens_clear",
    "Tranparent.002": "r34_lens_clear",
    "Tranparent._orange": "r34_lens_orange",
    "SIDE_INDICATORS": "r34_lens_orange",
    "Tranparent.004": "r34_lens_red",
    "Tranparent.005": "r34_lens_red",
    "Tranparent": "r34_black",  # door keyholes
    "Material.002": "r34_lens_red",  # the four round tail lamps
    "Material.001": "r34_trim",  # boot garnish strip between them
    "Material.003": "r34_grill",  # radiator
    "Material.005": "r34_exhaust",
    "Material.006": "r34_trim",  # front plate holder
    "Material.007": None,  # its picture (plate text)
    "Material.009": "r34_black",  # wipers
    "Material.010": "r34_trim",
    "Material.011": "r34_lamp",
    "Material.014": "r34_mirror",
    "Material.027": "r34_rubber",
    "Material.031": "r34_trim",
    "Material.032": "r34_lens_orange",
    "Windshield": "r34_glass",
}

mats = {}


def mat(role):
    if role in mats:
        return mats[role]
    rgb, metal, rough, alpha = LOOK[role]
    m = bpy.data.materials.new(role)
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = (*(((c / 255) ** 2.2) for c in rgb), 1)
    b.inputs["Metallic"].default_value = metal
    b.inputs["Roughness"].default_value = rough
    if alpha < 1:
        b.inputs["Alpha"].default_value = alpha
        try:
            m.surface_render_method = "BLENDED"
        except (AttributeError, TypeError):
            pass
    mats[role] = m
    return m


def islands(me):
    n = len(me.vertices)
    co = np.empty(n * 3)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    ne = len(me.edges)
    ev = np.empty(ne * 2, dtype=np.int64)
    me.edges.foreach_get("vertices", ev)
    ev = ev.reshape(-1, 2)
    _, inv = np.unique(np.round(co / 1e-5).astype(np.int64), axis=0, return_inverse=True)
    inv = inv.ravel()
    p = np.arange(inv.max() + 1)
    r, c = inv[ev[:, 0]], inv[ev[:, 1]]
    while True:
        while True:
            q = p[p]
            if np.array_equal(q, p):
                break
            p = q
        x, y = p[r], p[c]
        d = x != y
        if not d.any():
            break
        np.minimum.at(p, np.maximum(x[d], y[d]), np.minimum(x[d], y[d]))
    return p[inv]


def cabin_role(lo, hi):
    c = (lo + hi) / 2
    s = hi - lo
    ax = abs(c[0])
    if not (ax < 1.7 and -2.05 < c[1] < 1.8 and 0.4 < c[2] < 2.7):
        return "r34_grill"  # outside the cabin: grilles, chassis
    if c[2] > 2.25 and s[2] < 0.5:
        return "r34_headliner"
    if np.linalg.norm(c - np.array([-0.64, -0.75, 1.55])) < 0.42 and s.max() < 0.8:
        return "r34_leather"  # steering wheel (auto_car cuts it out by shape)
    if c[1] < -1.45 and c[2] < 0.95 and s.max() < 0.25:
        return "r34_alloy"  # pedals
    if c[2] < 0.66 and s[2] < 0.25 and s[0] > 0.4:
        return "r34_carpet"
    if ax > 1.05:
        return "r34_door"
    if c[1] > 0.95 and c[2] < 1.6:
        return "r34_cloth"  # rear bench
    if 0.25 < ax < 1.2 and -0.45 < c[1] < 1.0 and c[2] > 0.5:
        return "r34_cloth"  # front seats
    if c[2] > 2.0:
        return "r34_headliner"
    if c[1] > -0.45:
        return "r34_cabin_soft"  # console, tunnel
    return "r34_cabin"  # dash


log = {}
cards = []
for o in list(bpy.data.objects):
    if o.type != "MESH":
        continue
    me = o.data
    names = [m.name if m else "" for m in me.materials]
    role0 = EXT.get(names[0]) if names else None
    if names and names[0] in EXT and role0 is None:
        bpy.data.objects.remove(o)
        continue
    nf = len(me.polygons)
    fm = np.zeros(nf, dtype=np.int64)
    # black corners -> r34_black
    black = np.zeros(nf, dtype=bool)
    if me.color_attributes:
        ca = me.color_attributes[0]
        if ca.domain == "CORNER":
            col = np.empty(len(ca.data) * 4)
            ca.data.foreach_get("color", col)
            col = col.reshape(-1, 4)
            ls = np.empty(nf, dtype=np.int64)
            me.polygons.foreach_get("loop_start", ls)
            lt = np.empty(nf, dtype=np.int64)
            me.polygons.foreach_get("loop_total", lt)
            dark = col[:, :3].max(1) < 0.05
            black = np.add.reduceat(dark.astype(np.int64), ls) == lt
    if names and names[0] == "Front_grills":
        M = np.array(o.matrix_world)
        lab = islands(me)
        co = np.empty(len(me.vertices) * 3)
        me.vertices.foreach_get("co", co)
        w = co.reshape(-1, 3) @ M[:3, :3].T + M[:3, 3]
        order = np.argsort(lab)
        cuts = np.flatnonzero(np.diff(lab[order])) + 1
        vrole = np.empty(len(lab), dtype=object)
        for grp in np.split(order, cuts):
            p = w[grp]
            vrole[grp] = cabin_role(p.min(0), p.max(0))
        fv = np.empty(nf, dtype=np.int64)
        me.polygons.foreach_get("loop_start", fv)
        lv = np.empty(len(me.loops), dtype=np.int64)
        me.loops.foreach_get("vertex_index", lv)
        froles = vrole[lv[fv]]
    else:
        froles = np.array([role0 or "r34_trim"] * nf, dtype=object)
        if role0 == "r34_paint":
            # body panels seen from inside the cabin (door shells, pillars, roof underside) get trim colours
            M = np.array(o.matrix_world)
            fc = np.empty(nf * 3)
            me.polygons.foreach_get("center", fc)
            fc = fc.reshape(-1, 3) @ M[:3, :3].T + M[:3, 3]
            fn = np.empty(nf * 3)
            me.polygons.foreach_get("normal", fn)
            fn = fn.reshape(-1, 3) @ np.linalg.inv(M[:3, :3])
            fn /= np.linalg.norm(fn, axis=1, keepdims=True) + 1e-9
            inside = (np.abs(fc[:, 0]) < 1.72) & (fc[:, 1] > -2.1) & (fc[:, 1] < 1.9) & (fc[:, 2] > 0.5) & (fc[:, 2] < 2.64)
            side = inside & (fn[:, 0] * -np.sign(fc[:, 0]) > 0.35) & (fc[:, 2] < 2.3)
            roof = inside & (fn[:, 2] < -0.5) & (fc[:, 2] > 2.2)
            froles[side] = "r34_door"
            froles[roof] = "r34_headliner"
            # the door and quarter skins are one layer (seen from inside they vanish in Roblox, which draws one
            # side): copy their outward faces 4 cm inwards, turned round, as plain door cards
            out = inside & (np.abs(fc[:, 0]) > 1.25) & (fn[:, 0] * np.sign(fc[:, 0]) > 0.3) & (fc[:, 2] > 0.72) & (fc[:, 2] < 1.8)
            if out.any():
                cards.append((o, np.flatnonzero(out), M))
    froles[black] = "r34_black"
    roles = sorted(set(froles))
    me.materials.clear()
    for r in roles:
        me.materials.append(mat(r))
        log[r] = log.get(r, 0) + int((froles == r).sum())
    idx = {r: i for i, r in enumerate(roles)}
    me.polygons.foreach_set("material_index", np.array([idx[r] for r in froles], dtype=np.int32))
    for nm in [c.name for c in me.color_attributes]:
        me.color_attributes.remove(me.color_attributes[nm])
    me.update()

for o, faces, M in cards:
    me = o.data
    lv = np.empty(len(me.loops), dtype=np.int64)
    me.loops.foreach_get("vertex_index", lv)
    co = np.empty(len(me.vertices) * 3)
    me.vertices.foreach_get("co", co)
    w = co.reshape(-1, 3) @ M[:3, :3].T + M[:3, 3]
    verts, polys, remap = [], [], {}
    for fi in faces:
        p = me.polygons[fi]
        ids = [lv[li] for li in range(p.loop_start, p.loop_start + p.loop_total)][::-1]
        poly = []
        for vi in ids:
            if vi not in remap:
                q = w[vi].copy()
                q[0] -= 0.08 * np.sign(q[0])
                remap[vi] = len(verts)
                verts.append(tuple(q))
            poly.append(remap[vi])
        polys.append(poly)
    nm = bpy.data.meshes.new(o.name + "_card")
    nm.from_pydata(verts, [], polys)
    nm.materials.append(mat("r34_door"))
    ob = bpy.data.objects.new(o.name + "_DoorCard", nm)
    bpy.context.scene.collection.objects.link(ob)
    log["r34_door_card"] = log.get("r34_door_card", 0) + len(polys)

for k in sorted(log):
    print("role", k, log[k])
bpy.ops.export_scene.gltf(filepath=a[1], export_format="GLB")
print("wrote", a[1])
