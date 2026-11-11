"""MEGA BITE: Reef Shark, built by code (pipeline test, 9 Nov 2026).
Style: bright chunky "toy" cartoon (MEGA BITE art style guide): big head, round fins, big eyes,
grey-blue top + white belly, no blood/scars. Runs in any Blender 4.x/5.x (bpy).
Makes: the mesh (one joined model), a 5-bone spine rig with automatic weights, a swim-wiggle loop.
"""
import bpy, bmesh, math
from mathutils import Vector

def hexcol(h, a=1.0):
    h = h.lstrip("#"); c = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]
    return tuple((x / 12.92) if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c) + (a,)

TOP, BELLY, FIN = hexcol("4F7FAE"), hexcol("F2F6FA"), hexcol("44709C")
INK, WHITE, MOUTH = hexcol("0A1424"), hexcol("FFFFFF"), hexcol("2A1630")

def clear():
    for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.armatures, bpy.data.curves, bpy.data.actions):
        for d in list(coll): coll.remove(d)

def mat(name, col, rough=0.45):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = col; b.inputs["Roughness"].default_value = max(rough, 0.55)
    return m

def body_mat():
    """Grey-blue on top, white belly, soft line: countershading by object-space Z."""
    m = bpy.data.materials.new("SharkBody"); m.use_nodes = True
    nt = m.node_tree; b = nt.nodes["Principled BSDF"]; b.inputs["Roughness"].default_value = 0.6
    tc = nt.nodes.new("ShaderNodeTexCoord"); sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    add = nt.nodes.new("ShaderNodeMath"); add.operation = "ADD"; add.inputs[1].default_value = 0.14   # belly line ~0.13 below centre
    nt.links.new(tc.outputs["Object"], sep.inputs[0]); nt.links.new(sep.outputs["Z"], add.inputs[0])
    nt.links.new(add.outputs[0], ramp.inputs[0])
    nt.links.new(ramp.outputs["Color"], b.inputs["Base Color"])
    # map Z (about -0.6 .. 0.7) through the ramp: Z is fed raw, so put stops near 0
    r = ramp.color_ramp; r.interpolation = "EASE"
    r.elements[0].position = 0.0; r.elements[0].color = BELLY
    r.elements[1].position = 0.05; r.elements[1].color = TOP
    return m

L0, L1 = 1.55, -1.45          # nose x, tail-stock x (chunky: ~2.4x as long as tall)

def radius(t):
    """Body height radius along the body, t: 0 nose .. 1 tail stock. Chunky head, quick taper."""
    if t < 0.36:
        u = t / 0.36
        return 0.66 * (math.sin(u * math.pi / 2) ** 0.45)
    u = (t - 0.36) / 0.64
    return 0.66 * (1 - u) ** 1.1 + 0.17 * u

def surface(x, ang, inset=0.0):
    """A point on the body surface at x, angle ang (0 = side, +90 = top), pushed in by inset."""
    t = min(max((L0 - x) / (L0 - L1), 0), 1)
    h = max(radius(t), 0.02); w = h * 0.86
    a = math.radians(ang); z = math.sin(a); y = math.cos(a)
    zz = h * (z if z > 0 else z * 0.82) - 0.06 * (1 - t)
    p = Vector((x, w * y, zz)); n = Vector((0, y, z)).normalized()
    return p - n * inset, n

def make_body(rings=30, seg=20):
    bm = bmesh.new(); prev = None; first = None
    for i in range(rings + 1):
        t = i / rings; x = L0 + (L1 - L0) * t
        h = max(radius(t), 0.02); w = h * 0.86
        ring = []
        for j in range(seg):
            a = 2 * math.pi * j / seg
            z = math.sin(a); y = math.cos(a)
            zz = h * (z if z > 0 else z * 0.82)        # flatter belly
            zz += -0.06 * (1 - t)                       # head sits a bit low
            ring.append(bm.verts.new((x, w * y, zz)))
        if prev:
            for j in range(seg):
                bm.faces.new((prev[j], prev[(j + 1) % seg], ring[(j + 1) % seg], ring[j]))
        else:
            first = ring
        prev = ring
    nose = bm.verts.new((L0 + 0.06, 0, -0.04)); tail = bm.verts.new((L1 - 0.05, 0, 0))
    for j in range(seg):
        bm.faces.new((first[(j + 1) % seg], first[j], nose))
        bm.faces.new((prev[j], prev[(j + 1) % seg], tail))
    me = bpy.data.meshes.new("Body"); bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new("Body", me); bpy.context.collection.objects.link(ob)
    return ob

def fin(name, pts, thick=0.07, plane="XZ", loc=(0, 0, 0), rot=(0, 0, 0), m=None):
    """A fin from a 2D outline, made thick and rounded."""
    bm = bmesh.new()
    vs = []
    for p in pts:
        if plane == "XZ": vs.append(bm.verts.new((p[0], 0, p[1])))
        else: vs.append(bm.verts.new((p[0], p[1], 0)))
    bm.faces.new(vs)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(ob)
    ob.location = loc; ob.rotation_euler = rot
    s = ob.modifiers.new("Solid", "SOLIDIFY"); s.thickness = thick; s.offset = 0
    sub = ob.modifiers.new("Sub", "SUBSURF"); sub.levels = 1; sub.render_levels = 1
    if m: ob.data.materials.append(m)
    return ob

def sphere(name, loc, r, m, scale=(1, 1, 1), seg=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=seg // 2, radius=r, location=loc)
    ob = bpy.context.active_object; ob.name = name; ob.scale = scale
    bpy.ops.object.shade_smooth(); ob.data.materials.append(m); return ob

def tube(name, pts, r, m):
    cu = bpy.data.curves.new(name, "CURVE"); cu.dimensions = "3D"; cu.bevel_depth = r; cu.bevel_resolution = 2; cu.resolution_u = 6
    sp = cu.splines.new("BEZIER"); sp.bezier_points.add(len(pts) - 1)
    for bp, p in zip(sp.bezier_points, pts):
        bp.co = p; bp.handle_left_type = bp.handle_right_type = "AUTO"
    cu.use_fill_caps = True
    ob = bpy.data.objects.new(name, cu); bpy.context.collection.objects.link(ob); ob.data.materials.append(m)
    return ob

def build():
    clear()
    mb, mf = body_mat(), mat("Fin", FIN)
    mi, mw, mm = mat("Ink", INK, 0.3), mat("EyeWhite", WHITE, 0.25), mat("Mouth", MOUTH, 0.6)
    body = make_body(); body.data.materials.append(mb)
    sub = body.modifiers.new("Sub", "SUBSURF"); sub.levels = 1; sub.render_levels = 1
    for p in body.data.polygons: p.use_smooth = True
    parts = [body]
    # dorsal fin: chunky, rounded tip, swept back; base sunk into the back
    top, _ = surface(0.05, 90, inset=0.12)
    parts.append(fin("Dorsal", [(0.42, 0.0), (0.0, 0.0), (-0.3, 0.0), (-0.22, 0.2), (0.0, 0.52), (0.14, 0.6), (0.26, 0.46), (0.36, 0.2)],
                     thick=0.11, loc=(top.x, 0, top.z), m=mf))
    # tail: crescent, upper lobe bigger, base inside the tail stock
    parts.append(fin("Tail", [(0.18, 0.1), (-0.2, 0.5), (-0.46, 0.85), (-0.6, 0.82), (-0.5, 0.42), (-0.38, 0.0),
                              (-0.5, -0.32), (-0.46, -0.55), (-0.34, -0.53), (-0.08, -0.22), (0.18, -0.08)],
                     thick=0.1, loc=(L1 + 0.12, 0, 0.0), m=mf))
    # pectoral fins: round paddles on the lower sides, angled down and back
    for side in (1, -1):
        p, n = surface(0.42, -30, inset=0.06)
        parts.append(fin(f"Pec{side}", [(0.26, 0.0), (-0.1, 0.0), (-0.6, -0.5), (-0.72, -0.68), (-0.44, -0.64), (0.08, -0.22)],
                         thick=0.09, loc=(p.x, side * p.y, p.z), rot=(side * math.radians(-62), 0, side * math.radians(-18)), m=mf))
    # small second dorsal + anal fin (silhouette)
    p, _ = surface(-0.85, 90, inset=0.06)
    parts.append(fin("Dorsal2", [(0.12, 0), (-0.12, 0), (-0.16, 0.14), (-0.02, 0.2)], thick=0.07, loc=(p.x, 0, p.z), m=mf))
    p, _ = surface(-0.8, -90, inset=0.06)
    parts.append(fin("Anal", [(0.12, 0), (-0.12, 0), (-0.16, -0.14), (-0.02, -0.18)], thick=0.07, loc=(p.x, 0, p.z), m=mf))
    # BIG cartoon eyes, set into the head, looking forward
    ER = 0.2
    for side in (1, -1):
        c, n = surface(1.0, 28, inset=ER * 0.62)
        c = Vector((c.x, side * c.y, c.z)); n = Vector((0, side * n.y, n.z))
        fwd = Vector((1, 0, 0))
        look = (n * 0.75 + fwd * 0.65).normalized()
        parts.append(sphere(f"Eye{side}", c, ER, mw, scale=(1.0, 1.0, 1.1)))
        parts.append(sphere(f"Pupil{side}", c + look * ER * 0.62, ER * 0.5, mi, scale=(1, 1, 1.15)))
        parts.append(sphere(f"Glint{side}", c + look * ER * 0.95 + Vector((0, 0, ER * 0.3)), ER * 0.16, mw))
        # brow: a confident little line just above the eye (friendly-tough)
        b0 = c + n * ER * 0.7 + Vector((-0.16, 0, ER * 0.95)); b2 = c + n * ER * 0.75 + Vector((0.17, 0, ER * 0.85))
        b1 = (b0 + b2) / 2 + Vector((0, 0, 0.05))
        parts.append(tube(f"Brow{side}", [b0, b1, b2], 0.032, mf))
    # smile: a dark crescent wrapping the FRONT of the snout (seen from the front and the side),
    # small white teeth along the top lip
    SM = [(-12, 1.08), (-45, 1.30), (-90, 1.44), (-135, 1.30), (-168, 1.08)]
    pts = [surface(x, ang, inset=0.012)[0] for ang, x in SM]
    parts.append(tube("Mouth", pts, 0.045, mm))
    for k, (ang, x) in enumerate([(-30, 1.21), (-62, 1.38), (-118, 1.38), (-150, 1.21)]):
        p, n = surface(x, ang + 9, inset=0.0)
        bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.06, depth=0.13, location=p)
        tooth = bpy.context.active_object; tooth.name = f"Tooth{k}"
        tooth.rotation_euler = (n * -1).to_track_quat("Z", "Y").to_euler()   # point down/out of the lip
        tooth.rotation_euler.rotate_axis("X", math.pi)
        tooth.data.materials.append(mw); parts.append(tooth)
    # gills: 3 short curved lines on the surface
    for side in (1, -1):
        for k in range(3):
            x = 0.55 - k * 0.12
            q = [surface(x, ang, inset=-0.005)[0] for ang in (22, 2, -18)]
            q = [Vector((v.x - (0.03 if i == 1 else 0), side * v.y, v.z)) for i, v in enumerate(q)]
            parts.append(tube(f"Gill{side}{k}", q, 0.018, mf))
    # make everything a mesh and join
    bpy.ops.object.select_all(action="DESELECT")
    for o in parts:
        o.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.convert(target="MESH")
    bpy.ops.object.join()
    shark = bpy.context.active_object; shark.name = "ReefShark"
    bpy.ops.object.shade_smooth()
    return shark

def rig(shark, bones=5):
    arm = bpy.data.armatures.new("ReefSharkRig"); ob = bpy.data.objects.new("ReefSharkRig", arm)
    bpy.context.collection.objects.link(ob); bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    xs = [L0 + 0.05 - i * (L0 + 0.05 - (L1 - 0.5)) / bones for i in range(bones + 1)]
    prev = None
    for i in range(bones):
        b = arm.edit_bones.new(f"Spine{i}"); b.head = (xs[i], 0, 0); b.tail = (xs[i + 1], 0, 0)
        if prev: b.parent = prev; b.use_connect = True
        prev = b
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="DESELECT")
    shark.select_set(True); ob.select_set(True); bpy.context.view_layer.objects.active = ob
    bpy.ops.object.parent_set(type="ARMATURE_NAME")      # empty groups; weights set below
    # weights by position along the body: every vertex (eyes, gills, teeth too) follows the spine
    seg = (xs[0] - xs[-1]) / bones
    groups = [shark.vertex_groups[f"Spine{i}"] for i in range(bones)]
    for v in shark.data.vertices:
        u = (xs[0] - v.co.x) / seg - 0.5            # 0 = middle of bone 0
        u = min(max(u, 0.0), bones - 1.0)
        i0 = int(math.floor(u)); i1 = min(i0 + 1, bones - 1); f1 = u - i0
        groups[i0].add([v.index], 1.0 - f1, "REPLACE")
        if i1 != i0 and f1 > 0: groups[i1].add([v.index], f1, "REPLACE")
    # swim wiggle: a travelling sine wave, head almost still, strongest at the tail, 24 frames = 1 s loop
    act = bpy.data.actions.new("Swim"); ob.animation_data_create(); ob.animation_data.action = act
    bpy.ops.object.mode_set(mode="POSE")
    for f in range(0, 25, 3):
        for i in range(bones):
            pb = ob.pose.bones[f"Spine{i}"]; pb.rotation_mode = "XYZ"
            amp = math.radians(0.5 + 9.5 * (i / (bones - 1)) ** 1.5)
            pb.rotation_euler = (0, 0, amp * math.sin(2 * math.pi * f / 24 - i * 0.9))
            pb.keyframe_insert("rotation_euler", frame=f)
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.context.scene.frame_start, bpy.context.scene.frame_end = 0, 24
    return ob

if __name__ == "__main__" or True:
    shark = build()
    rigob = rig(shark)
    tris = sum(len(p.vertices) - 2 for p in shark.data.polygons)
    print("ReefShark triangles:", tris, "| bones:", len(rigob.data.bones))
