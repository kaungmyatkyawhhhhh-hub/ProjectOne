"""MEGA BITE: Reef Shark v2 (9 Nov 2026), rebuilt from the reference study of real shark games
(SharkBite 2, Be a Shark, Hungry Shark World): a sleek shark, NOT a round toy.
- body lofted from a side profile (back + belly lines) and a top profile (width), pointed cone snout
- underslung mouth with a separate LOWER JAW (its own bone: it can bite), rows of big triangle teeth
- small beady eyes low on the head, 5 gill slits, tall sickle dorsal, long swept pectorals, crescent tail
- grey-blue top / white belly with a wavy edge, dark fin tips (blacktip reef shark)
- rig: 5 spine bones + a jaw bone; weights by position along the body; Swim + Bite actions
Runs in any Blender 4.x / 5.x."""
import bpy, bmesh, math
from mathutils import Vector, Matrix

def lin(h, a=1.0):
    h = h.lstrip("#"); c = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]
    return tuple((x / 12.92) if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c) + (a,)

TOP, BELLY, TIP = lin("5D7F99"), lin("EEF2F5"), lin("1C2733")
MOUTH, TOOTH, EYE, GLINT = lin("3B1C2A"), lin("FBFBF4"), lin("0B0F14"), lin("FFFFFF")

NOSE, STOCK = 2.2, -1.55          # snout tip x, tail stock x (body ~3.75 long + tail)

def ease(u, p): return math.sin(max(0.0, min(1.0, u)) * math.pi / 2) ** p

def profile(t):
    """t: 0 snout .. 1 tail stock -> (z_top, z_bottom, half_width)."""
    peak = 0.33
    if t < peak:
        a = ease(t / peak, 0.62)
        top = 0.06 + (0.50 - 0.06) * a
        bot = -0.02 + (-0.44 + 0.02) * ease(t / peak, 0.75)
        wid = 0.02 + (0.40 - 0.02) * ease(t / peak, 0.55)
    else:
        u = (t - peak) / (1 - peak)
        k = (1 - u) ** 1.25
        top = 0.08 + (0.50 - 0.08) * k
        bot = -0.07 + (-0.44 + 0.07) * k
        wid = 0.05 + (0.40 - 0.05) * k
    return top, bot, wid

def tx(t): return NOSE + (STOCK - NOSE) * t
def t_of(x): return min(max((NOSE - x) / (NOSE - STOCK), 0.0), 1.0)

def surf(x, ang, push=0.0):
    """Surface point at x, angle around the body (0 = side +Y, 90 = top, -90 = belly)."""
    top, bot, wid = profile(t_of(x)); zc = (top + bot) / 2; hh = (top - bot) / 2
    a = math.radians(ang); c, s = math.cos(a), math.sin(a)
    e = 2.0 / 2.3   # superellipse
    y = wid * math.copysign(abs(c) ** e, c); z = zc + hh * math.copysign(abs(s) ** e, s)
    n = Vector((0, y / max(wid, 1e-3) ** 2, (z - zc) / max(hh, 1e-3) ** 2)).normalized()
    return Vector((x, y, z)) + n * push, n

def clear():
    for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.armatures, bpy.data.curves, bpy.data.actions):
        for d in list(coll): coll.remove(d)

def principled(name, col, rough=0.55):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]; b.inputs["Base Color"].default_value = col
    b.inputs["Roughness"].default_value = rough; return m

def skin_mat():
    """Countershading with a WAVY edge (noise), darker toward the back."""
    m = bpy.data.materials.new("Skin"); m.use_nodes = True; nt = m.node_tree
    b = nt.nodes["Principled BSDF"]; b.inputs["Roughness"].default_value = 0.6
    tc = nt.nodes.new("ShaderNodeTexCoord"); sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    noise = nt.nodes.new("ShaderNodeTexNoise"); noise.inputs["Scale"].default_value = 3.0
    mul = nt.nodes.new("ShaderNodeMath"); mul.operation = "MULTIPLY"; mul.inputs[1].default_value = 0.16
    add = nt.nodes.new("ShaderNodeMath"); add.operation = "ADD"
    off = nt.nodes.new("ShaderNodeMath"); off.operation = "ADD"; off.inputs[1].default_value = 0.08
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    L = nt.links.new
    L(tc.outputs["Object"], sep.inputs[0]); L(tc.outputs["Object"], noise.inputs["Vector"])
    L(noise.outputs["Fac"], mul.inputs[0]); L(sep.outputs["Z"], add.inputs[0]); L(mul.outputs[0], add.inputs[1])
    L(add.outputs[0], off.inputs[0]); L(off.outputs[0], ramp.inputs[0]); L(ramp.outputs["Color"], b.inputs["Base Color"])
    r = ramp.color_ramp; r.interpolation = "LINEAR"
    r.elements[0].position = 0.06; r.elements[0].color = BELLY
    r.elements[1].position = 0.12; r.elements[1].color = TOP
    e = r.elements.new(0.62); e.color = tuple(c * 0.72 for c in TOP[:3]) + (1,)
    return m

def fin_mat(name, reach):
    """Fin colour with a dark tip: object-space distance from the fin's root."""
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree
    b = nt.nodes["Principled BSDF"]; b.inputs["Roughness"].default_value = 0.6
    tc = nt.nodes.new("ShaderNodeTexCoord"); vl = nt.nodes.new("ShaderNodeVectorMath"); vl.operation = "LENGTH"
    dv = nt.nodes.new("ShaderNodeMath"); dv.operation = "DIVIDE"; dv.inputs[1].default_value = reach
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    nt.links.new(tc.outputs["Object"], vl.inputs[0]); nt.links.new(vl.outputs["Value"], dv.inputs[0])
    nt.links.new(dv.outputs[0], ramp.inputs[0]); nt.links.new(ramp.outputs["Color"], b.inputs["Base Color"])
    r = ramp.color_ramp; r.elements[0].position = 0.68; r.elements[0].color = tuple(c * 0.85 for c in TOP[:3]) + (1,)
    r.elements[1].position = 0.86; r.elements[1].color = TIP
    return m

def new_obj(name, bm):
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(ob); return ob

def body(rings=42, seg=22):
    bm = bmesh.new(); prev = None; first = None
    for i in range(rings + 1):
        t = (i / rings) ** 1.15            # more rings near the snout
        x = tx(t); ring = []
        for j in range(seg):
            p, _ = surf(x, 360 * j / seg)
            ring.append(bm.verts.new(p))
        if prev:
            for j in range(seg):
                bm.faces.new((prev[j], prev[(j + 1) % seg], ring[(j + 1) % seg], ring[j]))
        else: first = ring
        prev = ring
    tip = bm.verts.new((NOSE + 0.03, 0, 0.03)); end = bm.verts.new((STOCK - 0.04, 0, 0.0))
    for j in range(seg):
        bm.faces.new((first[(j + 1) % seg], first[j], tip)); bm.faces.new((prev[j], prev[(j + 1) % seg], end))
    return new_obj("Body", bm)

def flat_fin(name, outline, thick, m, loc, rot=(0, 0, 0), plane="XZ"):
    bm = bmesh.new()
    vs = [bm.verts.new((p[0], 0, p[1]) if plane == "XZ" else (p[0], p[1], 0)) for p in outline]
    bm.faces.new(vs)
    ob = new_obj(name, bm); ob.location = loc; ob.rotation_euler = rot
    s = ob.modifiers.new("S", "SOLIDIFY"); s.thickness = thick; s.offset = 0
    d = ob.modifiers.new("D", "SUBSURF"); d.levels = 1; d.render_levels = 1
    ob.data.materials.append(m); return ob

def loft(name, sections, m):
    """Loft closed rings given as lists of points (for the jaw)."""
    bm = bmesh.new(); rings = [[bm.verts.new(p) for p in sec] for sec in sections]; n = len(rings[0])
    for a, b in zip(rings, rings[1:]):
        for j in range(n): bm.faces.new((a[j], a[(j + 1) % n], b[(j + 1) % n], b[j]))
    c0 = bm.verts.new(sum((v.co for v in rings[0]), Vector()) / n); c1 = bm.verts.new(sum((v.co for v in rings[-1]), Vector()) / n)
    for j in range(n):
        bm.faces.new((rings[0][(j + 1) % n], rings[0][j], c0)); bm.faces.new((rings[-1][j], rings[-1][(j + 1) % n], c1))
    ob = new_obj(name, bm); ob.data.materials.append(m)
    d = ob.modifiers.new("D", "SUBSURF"); d.levels = 1; d.render_levels = 1
    return ob

def ball(name, loc, r, m, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=14, ring_count=8, radius=r, location=loc)
    ob = bpy.context.active_object; ob.name = name; ob.scale = scale; ob.data.materials.append(m); return ob

def tooth(name, base, direction, size, m):
    """A triangular blade tooth pointing along 'direction'."""
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=size * 0.55, depth=size, location=base + direction.normalized() * size * 0.5)
    ob = bpy.context.active_object; ob.name = name
    ob.rotation_euler = direction.to_track_quat("Z", "X").to_euler(); ob.scale = (1, 0.35, 1)
    ob.data.materials.append(m); return ob

MOUTH_CORNER, JAW_TIP = 1.30, 2.02

def build():
    clear()
    skin = skin_mat(); m_mouth = principled("Mouth", MOUTH, 0.7); m_tooth = principled("Tooth", TOOTH, 0.35)
    m_eye = principled("Eye", EYE, 0.2); m_glint = principled("Glint", GLINT, 0.2)
    parts, jaw_parts = [], []
    b = body(); b.data.materials.append(skin)
    s = b.modifiers.new("D", "SUBSURF"); s.levels = 1; s.render_levels = 1
    for p in b.data.polygons: p.use_smooth = True
    parts.append(b)

    # ---- fins (outlines in the fin's own plane; root at the origin so the dark tip works)
    dors = [(0.42, -0.08), (0.18, 0.18), (0.0, 0.48), (-0.16, 0.72), (-0.24, 0.74), (-0.2, 0.5), (-0.24, 0.2), (-0.38, -0.08)]
    p, _ = surf(0.42, 90, -0.06)
    parts.append(flat_fin("Dorsal", dors, 0.06, fin_mat("FinD", 0.78), (p.x, 0, p.z)))
    for side in (1, -1):
        pec = [(0.22, 0.0), (0.0, -0.1), (-0.3, -0.42), (-0.62, -0.8), (-0.72, -0.86), (-0.62, -0.6), (-0.36, -0.22), (-0.2, 0.0)]
        p, _ = surf(1.0, -38, -0.05)
        parts.append(flat_fin(f"Pec{side}", pec, 0.05, fin_mat(f"FinP{side}", 1.05), (p.x, side * p.y, p.z),
                              rot=(side * math.radians(-28), 0, side * math.radians(-6))))
    tail = [(0.18, 0.06), (-0.05, 0.3), (-0.32, 0.66), (-0.62, 1.0), (-0.72, 1.02), (-0.6, 0.66), (-0.48, 0.3), (-0.4, 0.04),
            (-0.5, -0.24), (-0.58, -0.5), (-0.5, -0.52), (-0.26, -0.3), (-0.04, -0.12), (0.18, -0.06)]
    parts.append(flat_fin("Tail", tail, 0.06, fin_mat("FinT", 1.15), (STOCK + 0.1, 0, 0.02)))
    p, _ = surf(-0.95, 90, -0.04)
    parts.append(flat_fin("Dorsal2", [(0.12, 0), (-0.04, 0.16), (-0.12, 0.17), (-0.1, 0.05), (-0.16, 0)], 0.04, fin_mat("FinD2", 0.2), (p.x, 0, p.z)))
    p, _ = surf(-1.0, -90, -0.04)
    parts.append(flat_fin("Anal", [(0.1, 0), (-0.04, -0.13), (-0.12, -0.14), (-0.1, -0.04), (-0.14, 0)], 0.04, fin_mat("FinA", 0.18), (p.x, 0, p.z)))
    for side in (1, -1):
        p, _ = surf(-0.45, -70, -0.03)
        parts.append(flat_fin(f"Pelvic{side}", [(0.1, 0), (-0.08, -0.16), (-0.18, -0.18), (-0.14, 0)], 0.035, fin_mat(f"FinV{side}", 0.24),
                              (p.x, side * p.y, p.z), rot=(side * math.radians(-30), 0, 0)))

    # ---- eyes: small and beady, low on the head, a little white glint
    for side in (1, -1):
        c, n = surf(1.62, 12, -0.025); c.y *= side; n.y *= side
        parts.append(ball(f"Eye{side}", c, 0.065, m_eye, scale=(1.25, 0.8, 1.0)))
        parts.append(ball(f"Glint{side}", c + n * 0.05 + Vector((0.02, 0, 0.025)), 0.016, m_glint))
        # brow ridge: a small skin bump over the eye (makes it look focused, not goofy)
        br, _ = surf(1.6, 26, -0.035); br.y *= side
        g = ball(f"Brow{side}", br, 0.09, skin, scale=(1.7, 0.55, 0.5)); g.rotation_euler = (0, math.radians(-10), side * math.radians(-6))
        parts.append(g)
        # 5 gill slits
        for k in range(5):
            x = 1.08 - k * 0.075
            a, _ = surf(x, 22, 0.004); bq, _ = surf(x - 0.025, -2, 0.006); cq, _ = surf(x, -22, 0.004)
            cu = bpy.data.curves.new(f"Gill{side}{k}", "CURVE"); cu.dimensions = "3D"; cu.bevel_depth = 0.011; cu.bevel_resolution = 1
            sp = cu.splines.new("BEZIER"); sp.bezier_points.add(2)
            for bp, q in zip(sp.bezier_points, (a, bq, cq)):
                bp.co = (q.x, side * q.y, q.z); bp.handle_left_type = bp.handle_right_type = "AUTO"
            ob = bpy.data.objects.new(f"Gill{side}{k}", cu); bpy.context.collection.objects.link(ob)
            ob.data.materials.append(principled(f"GillM{side}{k}", tuple(c * 0.55 for c in TOP[:3]) + (1,)))
            parts.append(ob)

    # ---- mouth: a GRIN along the side of the head (corner under the eye, sweeping to under the snout).
    # The lower jaw is the body's own chin surface (a skin shell), hinged at the corners, so closed it
    # looks like part of the head; a dark line + both teeth rows show the grin; open = a real bite.
    def mouth_ang(x):
        u = min(max((x - MOUTH_CORNER) / (JAW_TIP - MOUTH_CORNER), 0.0), 1.0)
        return -22 - 68 * u ** 1.25
    xs_m = [MOUTH_CORNER + (JAW_TIP - MOUTH_CORNER) * (k / 10) ** 0.85 for k in range(11)]
    line = []    # the mouth line: +y side corner -> snout front -> -y side corner
    for x in xs_m:
        p, _ = surf(x, mouth_ang(x), 0.004); line.append(Vector((p.x, p.y, p.z)))
    full = line + [Vector((q.x, -q.y, q.z)) for q in reversed(line[:-1])]
    cu = bpy.data.curves.new("MouthLine", "CURVE"); cu.dimensions = "3D"; cu.bevel_depth = 0.032; cu.bevel_resolution = 2
    sp = cu.splines.new("POLY"); sp.points.add(len(full) - 1)
    for pt, q in zip(sp.points, full): pt.co = (q.x, q.y, q.z, 1)
    ob = bpy.data.objects.new("MouthLine", cu); bpy.context.collection.objects.link(ob); ob.data.materials.append(m_mouth); parts.append(ob)
    # upper teeth: along the line, pointing down and a bit outward (visible from the side)
    for side in (1, -1):
        for k, x in enumerate(xs_m[1:-1]):
            p, n = surf(x, mouth_ang(x) + 4, 0.0); p.y *= side; n.y *= side
            d = Vector((0.18, 0, -1)) + n * 0.45
            parts.append(tooth(f"UpTooth{side}{k}", p, d, 0.105 if k < 7 else 0.085, m_tooth))
    p, n = surf(JAW_TIP, -90, 0.0)
    parts.append(tooth("UpToothFront", p + Vector((0.01, 0, 0)), Vector((0.25, 0, -1)), 0.1, m_tooth))
    # lower jaw shell: the body's lower surface under the mouth line, pushed out a hair, closed on top
    secs = []
    for x in xs_m[:-1] + [JAW_TIP - 0.02]:
        a0 = mouth_ang(x) - 3; ring = []
        for k in range(9):                                  # arc from +y mouth line, under the chin, to -y
            ang = a0 + (-180 - 2 * a0) * (k / 8)            # a0 .. -180-a0
            q, _ = surf(x, ang, 0.012); ring.append(q)
        q0, q1 = ring[0], ring[-1]
        for k in range(1, 4):                               # inner edge across the top (inside the head)
            f = k / 4; c = q1.lerp(q0, f); ring.append(Vector((c.x, c.y * 0.9, c.z + 0.02)))
        secs.append(ring)
    jaw = loft("Jaw", secs, skin); jaw_parts.append(jaw)
    for side in (1, -1):
        for k, x in enumerate(xs_m[1:-2]):
            q, n = surf(x, mouth_ang(x) - 6, 0.01); q.y *= side; n.y *= side
            jaw_parts.append(tooth(f"LowTooth{side}{k}", q, Vector((0.1, 0, 1)) + n * 0.4, 0.075, m_tooth))
    # convert + join; jaw vertices get their own group so they follow the jaw bone
    for o in parts + jaw_parts: o.select_set(False)
    allp = parts + jaw_parts
    bpy.ops.object.select_all(action="DESELECT")
    for o in allp: o.select_set(True)
    bpy.context.view_layer.objects.active = b
    bpy.ops.object.convert(target="MESH")
    for o in jaw_parts:
        o = bpy.data.objects[o.name]; vg = o.vertex_groups.new(name="Jaw"); vg.add(list(range(len(o.data.vertices))), 1.0, "REPLACE")
    bpy.ops.object.join(); sh = bpy.context.active_object; sh.name = "ReefShark"
    bpy.ops.object.shade_smooth()
    return sh

def rig(sh, bones=5):
    arm = bpy.data.armatures.new("ReefSharkRig"); ob = bpy.data.objects.new("ReefSharkRig", arm)
    bpy.context.collection.objects.link(ob); bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    xs = [NOSE + 0.05 - i * (NOSE + 0.05 - (STOCK - 0.75)) / bones for i in range(bones + 1)]
    prev = None
    for i in range(bones):
        b = arm.edit_bones.new(f"Spine{i}"); b.head = (xs[i], 0, 0); b.tail = (xs[i + 1], 0, 0)
        if prev: b.parent = prev; b.use_connect = True
        prev = b
    hp, _ = surf(MOUTH_CORNER, -22)
    j = arm.edit_bones.new("Jaw"); j.head = (MOUTH_CORNER - 0.02, 0, hp.z); j.tail = (JAW_TIP, 0, hp.z - 0.12)
    j.parent = arm.edit_bones["Spine0"]
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="DESELECT"); sh.select_set(True); ob.select_set(True); bpy.context.view_layer.objects.active = ob
    bpy.ops.object.parent_set(type="ARMATURE_NAME")
    seg = (xs[0] - xs[-1]) / bones
    groups = [sh.vertex_groups[f"Spine{i}"] for i in range(bones)]
    jg = sh.vertex_groups["Jaw"].index
    for v in sh.data.vertices:
        if any(g.group == jg and g.weight > 0.5 for g in v.groups): continue
        u = min(max((xs[0] - v.co.x) / seg - 0.5, 0.0), bones - 1.0)
        i0 = int(math.floor(u)); i1 = min(i0 + 1, bones - 1); f1 = u - i0
        groups[i0].add([v.index], 1.0 - f1, "REPLACE")
        if i1 != i0 and f1 > 0: groups[i1].add([v.index], f1, "REPLACE")
    ob.animation_data_create()
    # Swim: travelling wave, head nearly still, strongest at the tail; jaw slightly open (shows the teeth)
    swim = bpy.data.actions.new("Swim"); ob.animation_data.action = swim
    bpy.ops.object.mode_set(mode="POSE")
    for pb in ob.pose.bones: pb.rotation_mode = "XYZ"
    for f in range(0, 25, 3):
        for i in range(bones):
            pb = ob.pose.bones[f"Spine{i}"]; amp = math.radians(0.6 + 11 * (i / (bones - 1)) ** 1.5)
            pb.rotation_euler = (0, 0, amp * math.sin(2 * math.pi * f / 24 - i * 0.9)); pb.keyframe_insert("rotation_euler", frame=f)
        jb = ob.pose.bones["Jaw"]; jb.rotation_euler = (0, 0, 0)
        jb.rotation_euler = (math.radians(0), 0, 0)
        jb.keyframe_insert("rotation_euler", frame=f)
    bite = bpy.data.actions.new("Bite"); ob.animation_data.action = bite
    for f, ang in ((0, 4), (4, 26), (8, 26), (11, -2), (16, 4)):
        jb = ob.pose.bones["Jaw"]; jb.rotation_euler = (0, math.radians(ang), 0); jb.keyframe_insert("rotation_euler", frame=f)
    ob.animation_data.action = swim
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.context.scene.frame_start, bpy.context.scene.frame_end = 0, 24
    return ob

def pose_jaw(rigob, deg):
    rigob.pose.bones["Jaw"].rotation_mode = "XYZ"; rigob.pose.bones["Jaw"].rotation_euler = (0, math.radians(deg), 0)

if __name__ == "__main__" or True:
    sh = build(); rg = rig(sh)
    tris = sum(len(p.vertices) - 2 for p in sh.data.polygons)
    print("ReefShark v2 triangles (before subdivision):", tris)
