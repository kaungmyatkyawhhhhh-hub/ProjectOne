"""MEGA BITE low-poly shark generator v1 (9 Nov 2026), from the model-quality research:
low-poly + FLAT shading + flat colour regions (Fisch route), angular wedge head + brow, a glowing eye,
an OPEN jaw (own bone) with a maroon inside and big white blade teeth on both jaws, a zig-zag
back/belly line, thick angular fins with dark tips (blacktip reef shark), 8 spine bones.
Species are parameter sets (the "genome"); this file builds the Reef Shark. Blender 4.x/5.x."""
import bpy, bmesh, math
from mathutils import Vector

def lin(h):
    h = h.lstrip("#"); c = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]
    return tuple((x / 12.92) if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c) + (1.0,)

REEF = dict(
    name="ReefShark",
    top="4E6F8C", belly="EEF1F3", fin="476581", tip="17202B", mouth="5A1E2C", tooth="F7F4EA", eye="3FD8FF",
    nose=2.15, stock=-1.55, peak=0.32, height=0.92, width=0.74,
    mouth_corner=1.22, jaw_open=22, eye_x=1.52,
)

def clear():
    """Work in our OWN scene so nothing the owner has open is touched; rebuild it fresh each run."""
    name = "MEGA BITE"
    sc = bpy.data.scenes.get(name)
    if sc is None:
        sc = bpy.data.scenes.new(name)
    if bpy.context.window is not None:
        bpy.context.window.scene = sc
    for o in list(sc.objects): bpy.data.objects.remove(o, do_unlink=True)

def mat(name, col, emit=0.0, rough=0.5):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]; b.inputs["Base Color"].default_value = col; b.inputs["Roughness"].default_value = rough
    if emit:
        b.inputs["Emission Color"].default_value = col; b.inputs["Emission Strength"].default_value = emit
    return m

# half cross-section (y, z) from the top ridge down to the belly centre: a rounded DIAMOND, not a tube
HALF = [(0.0, 1.0), (0.42, 0.86), (0.86, 0.42), (1.0, -0.05), (0.80, -0.55), (0.38, -0.86), (0.0, -0.92)]

def section(G, t):
    """(z_top, z_bottom, half_width, z_centre) at t (0 snout .. 1 tail stock)."""
    p = G["peak"]
    if t < p:
        u = t / p; a = math.sin(u * math.pi / 2) ** 0.6
        h = 0.10 + (G["height"] / 2 - 0.10) * a; w = 0.05 + (G["width"] / 2 - 0.05) * math.sin(u * math.pi / 2) ** 0.55
        zc = 0.02 * (1 - u)
    else:
        u = (t - p) / (1 - p); k = (1 - u) ** 1.3
        h = 0.11 + (G["height"] / 2 - 0.11) * k; w = 0.045 + (G["width"] / 2 - 0.045) * k   # tall, narrow tail stock
        zc = 0.0
    return h, w, zc

def x_at(G, t): return G["nose"] + (G["stock"] - G["nose"]) * t
def t_at(G, x): return min(max((G["nose"] - x) / (G["nose"] - G["stock"]), 0.0), 1.0)

def mouth_z(G, x):
    """The mouth line height (palate) in the head: rises a little toward the snout."""
    h, w, zc = section(G, t_at(G, x)); u = (x - G["mouth_corner"]) / (G["nose"] - G["mouth_corner"])
    return zc - h * (0.32 - 0.22 * max(0, min(1, u)))

def ring_pts(G, x, upper_only=False):
    h, w, zc = section(G, t_at(G, x)); pts = []
    full = [(y, z) for (y, z) in HALF] + [(-y, z) for (y, z) in reversed(HALF[1:-1])]
    for (yy, zz) in full:
        y = yy * w; z = zc + zz * h
        if upper_only and zz < -0.05:                       # head: the lower part becomes the flat palate
            z = mouth_z(G, x); y = yy * w * (0.95 if abs(yy) > 0.5 else 1.0)
        pts.append(Vector((x, y, z)))
    return pts

def build_body(G, rings=16):
    """Low-poly lofted body; the head rings in front of the mouth corner keep only the upper part (open mouth)."""
    bm = bmesh.new(); prev = None; first = None; ringlist = []; rowL = bm.faces.layers.int.new("row"); ringL = bm.faces.layers.int.new("ring")
    ts = [(i / rings) ** 1.2 for i in range(rings + 1)]
    for t in ts:
        x = x_at(G, t)
        pts = ring_pts(G, x, upper_only=(x > G["mouth_corner"]))
        # brow: lift + push out the upper-side vertex over the eye (angular hood)
        if abs(x - G["eye_x"]) < 0.22:
            for k in (1, len(pts) - 1):
                pts[k].z += 0.06; pts[k].y *= 1.08
        ring = [bm.verts.new(p) for p in pts]; ringlist.append(ring)
        if prev:
            n = len(ring)
            gi = len(ringlist) - 1
            for j in range(n):
                row = j if j < 6 else 11 - j              # 0 = top ridge .. 5 = belly centre (same on both sides)
                a, b, c, d = prev[j], prev[(j + 1) % n], ring[(j + 1) % n], ring[j]
                if row == 2:
                    # the countershade line: split the flank quad on a diagonal that flips every ring,
                    # upper triangle = back colour, lower = belly -> a clean low-poly zig-zag
                    if a.co.z < b.co.z: a, b, c, d = b, a, d, c       # make a/d the upper edge
                    if gi % 2: tris = ((a, b, c), (a, c, d))       # diag a-c
                    else:      tris = ((a, b, d), (b, c, d))       # diag b-d
                    for tri in tris:
                        upper = sum(1 for v in tri if v in (a, d)) >= 2
                        f = bm.faces.new(tri); f[rowL] = 1 if upper else 3; f[ringL] = gi
                    continue
                f = bm.faces.new((a, b, c, d)); f[rowL] = row; f[ringL] = gi
        else: first = ring
        prev = ring
    tip = bm.verts.new((G["nose"] + 0.12, 0, section(G, 0)[2] + 0.02))
    n = len(first)
    for j in range(n): bm.faces.new((first[(j + 1) % n], first[j], tip))
    end = bm.verts.new((G["stock"] - 0.05, 0, 0))
    for j in range(n): bm.faces.new((prev[j], prev[(j + 1) % n], end))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new("Body"); bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new("Body", me); bpy.context.scene.collection.objects.link(ob); return ob

def build_jaw(G, rings=6):
    """The lower jaw: an angular wedge from the mouth corner to under the snout; hinged at the corner."""
    bm = bmesh.new(); rr = []
    xs = [G["mouth_corner"] - 0.06 + (G["nose"] - 0.12 - G["mouth_corner"] + 0.06) * i / rings for i in range(rings + 1)]
    for i, x in enumerate(xs):
        h, w, zc = section(G, t_at(G, x)); zm = mouth_z(G, x); u = i / rings
        wj = w * (0.92 - 0.55 * u ** 1.6); bot = zc - h * (0.92 - 0.25 * u)
        half = [(0.0, zm - 0.03), (wj * 0.88, zm), (wj, zm - (zm - bot) * 0.45), (wj * 0.62, bot + 0.02), (0.0, bot)]
        pts = [Vector((x, y, z)) for (y, z) in half] + [Vector((x, -y, z)) for (y, z) in reversed(half[1:-1])]
        rr.append([bm.verts.new(p) for p in pts])
    n = len(rr[0])
    for a, b in zip(rr, rr[1:]):
        for j in range(n): bm.faces.new((a[j], a[(j + 1) % n], b[(j + 1) % n], b[j]))
    bm.faces.new(list(reversed(rr[0]))); c = bm.verts.new(sum((v.co for v in rr[-1]), Vector()) / n + Vector((0.05, 0, 0)))
    for j in range(n): bm.faces.new((rr[-1][j], rr[-1][(j + 1) % n], c))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new("Jaw"); bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new("Jaw", me); bpy.context.scene.collection.objects.link(ob); return ob

def fin(name, outline, root_thick, m_base, m_tip, loc, rot=(0, 0, 0), tip_from=0.62):
    """Angular fin: thick at the root, thin at the edges (each outline point gets its own thickness)."""
    bm = bmesh.new(); top, bot = [], []
    far = max(Vector((p[0], p[1])).length for p in outline)
    for (a, b, *rest) in outline:
        th = root_thick * (rest[0] if rest else 0.35)
        top.append(bm.verts.new((a, th / 2, b))); bot.append(bm.verts.new((a, -th / 2, b)))
    n = len(top)
    bm.faces.new(top); bm.faces.new(list(reversed(bot)))
    for j in range(n): bm.faces.new((top[j], bot[j], bot[(j + 1) % n], top[(j + 1) % n]))
    bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 4])
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob)
    ob.location = loc; ob.rotation_euler = rot
    ob.data.materials.append(m_base); ob.data.materials.append(m_tip)
    for p in ob.data.polygons:   # dark tips: faces whose centre is far from the root
        if p.center.length > far * tip_from: p.material_index = 1
    return ob

def blade(name, base, along, point_dir, size, m):
    """A flat triangular blade tooth (a thin prism)."""
    bm = bmesh.new(); a = along.normalized() * size * 0.42; d = point_dir.normalized() * size
    side = along.cross(point_dir).normalized() * size * 0.12
    tri = [base - a, base + a, base + d]
    v1 = [bm.verts.new(p + side) for p in tri]; v2 = [bm.verts.new(p - side) for p in tri]
    bm.faces.new(v1); bm.faces.new(list(reversed(v2)))
    for j in range(3): bm.faces.new((v1[j], v2[j], v2[(j + 1) % 3], v1[(j + 1) % 3]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob); ob.data.materials.append(m); return ob

def gem(name, loc, r, m, scale=(1, 1, 1), sub=1):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub, radius=r, location=loc)
    ob = bpy.context.active_object; ob.name = name; ob.scale = scale; ob.data.materials.append(m); return ob

def build(G):
    if bpy.context.object is not None and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    clear()
    M = {k: mat(k, lin(G[k])) for k in ("top", "belly", "fin", "tip", "mouth", "tooth")}
    M["eye"] = mat("eye", lin(G["eye"]), emit=3.0, rough=0.2)
    M["gill"] = mat("gill", tuple(c * 0.45 for c in lin(G["top"])[:3]) + (1,))
    body = build_body(G); jaw = build_jaw(G)
    for ob in (body, jaw):
        for k in ("top", "belly", "mouth"): ob.data.materials.append(M[k])
    # colour regions by rule: zig-zag countershade line (alternating per ring), maroon palate / tongue
    rows = body.data.attributes.get("row"); rings_ = body.data.attributes.get("ring")
    for p in body.data.polygons:
        if rows is None or p.index >= len(rows.data): p.material_index = 0; continue
        r = rows.data[p.index].value; g = rings_.data[p.index].value
        mi = 0 if r <= 2 else 1
        if p.center.x > G["mouth_corner"] - 0.02 and p.normal.z < -0.6: mi = 2          # palate
        p.material_index = mi
    for p in jaw.data.polygons:
        p.material_index = 2 if p.normal.z > 0.6 else (1 if p.normal.z < 0.2 else 0)   # tongue / white chin / top edge
    parts = [body]; jaw_parts = [jaw]
    # fins (x, z[, thickness factor]) outlines; roots thick (1.0), edges thin
    h0, w0, _ = section(G, G["peak"])
    dors = [(0.40, -0.06, 1.0), (0.12, 0.30, 0.8), (-0.12, 0.62, 0.35), (-0.28, 0.80, 0.2), (-0.34, 0.74, 0.2), (-0.26, 0.40, 0.3), (-0.34, 0.10, 0.5), (-0.46, -0.06, 1.0)]
    parts.append(fin("Dorsal", dors, 0.16, M["fin"], M["tip"], (0.42, 0, h0 * 0.86)))
    tail = [(0.20, 0.10, 1.0), (-0.10, 0.42, 0.5), (-0.42, 0.86, 0.25), (-0.66, 1.10, 0.2), (-0.74, 1.04, 0.2), (-0.56, 0.62, 0.3), (-0.42, 0.18, 0.5),
            (-0.40, 0.0, 0.6), (-0.54, -0.30, 0.3), (-0.62, -0.56, 0.2), (-0.52, -0.58, 0.2), (-0.26, -0.30, 0.4), (0.20, -0.08, 1.0)]
    parts.append(fin("Tail", tail, 0.12, M["fin"], M["tip"], (G["stock"] + 0.08, 0, 0.02), tip_from=0.7))
    for s in (1, -1):
        pec = [(0.26, 0.0, 1.0), (0.0, -0.08, 0.7), (-0.34, -0.42, 0.35), (-0.64, -0.80, 0.2), (-0.76, -0.86, 0.2), (-0.60, -0.56, 0.3), (-0.30, -0.18, 0.5), (-0.12, 0.0, 1.0)]
        parts.append(fin(f"Pec{s}", pec, 0.12, M["fin"], M["tip"], (0.95, s * w0 * 0.78, -h0 * 0.45),
                         rot=(s * math.radians(-30), 0, s * math.radians(-8))))
        pel = [(0.1, 0, 1.0), (-0.08, -0.16, 0.4), (-0.2, -0.2, 0.3), (-0.16, 0, 1.0)]
        parts.append(fin(f"Pelvic{s}", pel, 0.06, M["fin"], M["tip"], (-0.55, s * 0.1, -0.27), rot=(s * math.radians(-30), 0, 0)))
    parts.append(fin("Dorsal2", [(0.12, 0, 1.0), (-0.04, 0.17, 0.4), (-0.14, 0.18, 0.3), (-0.12, 0.05, 0.5), (-0.18, 0, 1.0)], 0.06, M["fin"], M["tip"], (-0.95, 0, 0.18)))
    parts.append(fin("Anal", [(0.10, 0, 1.0), (-0.04, -0.14, 0.4), (-0.14, -0.15, 0.3), (-0.12, -0.04, 0.5), (-0.16, 0, 1.0)], 0.06, M["fin"], M["tip"], (-1.0, 0, -0.17)))
    # eye: a glowing faceted gem, set under the brow, just above the mouth line
    for s in (1, -1):
        h, w, zc = section(G, t_at(G, G["eye_x"]))
        ez = mouth_z(G, G["eye_x"]) + h * 0.55
        parts.append(gem(f"Eye{s}", (G["eye_x"], s * w * 0.78, ez), 0.1, M["eye"], scale=(1.3, 0.7, 0.9), sub=2))
        # 5 gill cuts: thin dark slabs on the flank
        for k in range(5):
            x = 0.98 - k * 0.085; h2, w2, zc2 = section(G, t_at(G, x))
            g = gem(f"Gill{s}{k}", (x, s * w2 * 0.97, zc2 - 0.03), 0.02, M["gill"], scale=(0.8, 0.6, 9.0))
            g.rotation_euler = (0, math.radians(-12), 0); parts.append(g)
    # teeth: big white blades, varied size, upper row along the palate edge, lower row on the jaw
    xs = [G["mouth_corner"] + 0.06 + (G["nose"] - 0.2 - G["mouth_corner"]) * k / 5 for k in range(6)]
    sizes = [0.10, 0.13, 0.15, 0.14, 0.12, 0.10]
    for s in (1, -1):
        for k, x in enumerate(xs):
            h, w, zc = section(G, t_at(G, x)); zm = mouth_z(G, x)
            parts.append(blade(f"Up{s}{k}", Vector((x, s * w * 0.86, zm + 0.005)), Vector((1, 0, 0)), Vector((0.12, -s * 0.15, -1)), sizes[k], M["tooth"]))
        for k, x in enumerate(xs[:-1]):
            h, w, zc = section(G, t_at(G, x + 0.05)); zm = mouth_z(G, x + 0.05); u = (x + 0.05 - G["mouth_corner"]) / (G["nose"] - G["mouth_corner"])
            wj = w * (0.92 - 0.55 * u ** 1.6)
            jaw_parts.append(blade(f"Lo{s}{k}", Vector((x + 0.05, s * wj * 0.82, zm - 0.02)), Vector((1, 0, 0)), Vector((0.1, -s * 0.1, 1)), sizes[k] * 0.85, M["tooth"]))
    parts.append(blade("UpFront", Vector((G["nose"] - 0.1, 0, mouth_z(G, G["nose"] - 0.1))), Vector((0, 1, 0)), Vector((0.2, 0, -1)), 0.12, M["tooth"]))
    # join (jaw vertices tagged), flat shading
    bpy.ops.object.select_all(action="DESELECT")
    for o in jaw_parts:
        vg = o.vertex_groups.new(name="Jaw"); vg.add(list(range(len(o.data.vertices))), 1.0, "REPLACE")
    for o in parts + jaw_parts: o.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join(); sh = bpy.context.active_object; sh.name = G["name"]
    bpy.ops.object.shade_flat()
    return sh

def rig(G, sh, bones=8):
    arm = bpy.data.armatures.new(G["name"] + "Rig"); ob = bpy.data.objects.new(G["name"] + "Rig", arm)
    bpy.context.scene.collection.objects.link(ob); bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    xs = [G["nose"] + 0.1 - i * (G["nose"] + 0.1 - (G["stock"] - 0.8)) / bones for i in range(bones + 1)]
    prev = None
    for i in range(bones):
        b = arm.edit_bones.new(f"Spine{i}"); b.head = (xs[i], 0, 0); b.tail = (xs[i + 1], 0, 0)
        if prev: b.parent = prev; b.use_connect = True
        prev = b
    zm = mouth_z(G, G["mouth_corner"])
    j = arm.edit_bones.new("Jaw"); j.head = (G["mouth_corner"] - 0.06, 0, zm); j.tail = (G["nose"] - 0.1, 0, zm - 0.1); j.parent = arm.edit_bones["Spine0"]
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="DESELECT"); sh.select_set(True); ob.select_set(True); bpy.context.view_layer.objects.active = ob
    bpy.ops.object.parent_set(type="ARMATURE_NAME")
    seg = (xs[0] - xs[-1]) / bones; groups = [sh.vertex_groups[f"Spine{i}"] for i in range(bones)]; jg = sh.vertex_groups["Jaw"].index
    for v in sh.data.vertices:
        if any(g.group == jg for g in v.groups): continue
        u = min(max((xs[0] - v.co.x) / seg - 0.5, 0.0), bones - 1.0); i0 = int(u); i1 = min(i0 + 1, bones - 1); f = u - i0
        groups[i0].add([v.index], 1 - f, "REPLACE")
        if i1 != i0 and f > 0: groups[i1].add([v.index], f, "REPLACE")
    ob.animation_data_create(); act = bpy.data.actions.new("Swim"); ob.animation_data.action = act
    bpy.ops.object.mode_set(mode="POSE")
    for pb in ob.pose.bones: pb.rotation_mode = "XYZ"
    for f in range(0, 25, 3):   # carangiform: front still, rear third + tail swing
        for i in range(bones):
            pb = ob.pose.bones[f"Spine{i}"]; amp = math.radians(0.3 + 9 * (i / (bones - 1)) ** 2.2)
            pb.rotation_euler = (0, 0, amp * math.sin(2 * math.pi * f / 24 - i * 0.7)); pb.keyframe_insert("rotation_euler", frame=f)
        jb = ob.pose.bones["Jaw"]; jb.rotation_euler = (0, math.radians(G["jaw_open"]), 0); jb.keyframe_insert("rotation_euler", frame=f)
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.context.scene.frame_start, bpy.context.scene.frame_end = 0, 24; bpy.context.scene.frame_set(0)
    return ob

sh = build(REEF); rg = rig(REEF, sh)
print("LOWPOLY", sh.name, "triangles:", sum(len(p.vertices) - 2 for p in sh.data.polygons))

def stage():
    """A simple underwater-blue stage so the shark can be looked at in the viewport (EEVEE)."""
    sc = bpy.context.scene
    w = bpy.data.worlds.get("MB_World") or bpy.data.worlds.new("MB_World"); w.use_nodes = True; sc.world = w
    bg = w.node_tree.nodes.get("Background"); bg.inputs[0].default_value = (0.03, 0.30, 0.42, 1); bg.inputs[1].default_value = 0.8
    for name, rot, e in (("MB_Sun", (math.radians(40), 0, math.radians(30)), 3.5), ("MB_Rim", (math.radians(-120), 0, math.radians(-40)), 1.5)):
        ld = bpy.data.lights.get(name) or bpy.data.lights.new(name, "SUN"); ld.energy = e
        ob = bpy.data.objects.new(name, ld); sc.collection.objects.link(ob); ob.rotation_euler = rot
    sc.view_settings.view_transform = "Standard"
stage()
