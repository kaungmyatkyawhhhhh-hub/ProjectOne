"""MEGA BITE Reef Shark v3 (9 Nov 2026): TRACED from the ChatGPT model sheet (ReefShark_sheet_chatgpt.png).
All outlines below are pixel coordinates measured on that sheet (side view: nose at x=1450; top view: nose at x=919).
Low-poly, flat shaded, flat colour regions (Fisch style). Builds into its own scene "MEGA BITE". Blender 4.x/5.x."""
import bpy, bmesh, math
from mathutils import Vector
from mathutils.bvhtree import BVHTree

def lin(h):
    c = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]
    return tuple((x / 12.92) if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c) + (1.0,)

PAL = dict(top="5D7E9F", belly="F0F2F5", tip="1E2127", mouth="6E2235", tooth="FBF8F0", eye="3FF2FF", gill="22272F")

# ---------- traced data (side view px) ----------
NOSE_PX, TAIL_PX = 1450, 285
S = 3.7 / 1158                      # metres per side-view px (body ~3.7 m nose to tail joint)
def X(px): return 2.15 + (px - NOSE_PX) * S
def Z(py): return (300 - py) * S
UP = [(285,276),(300,268),(340,258),(400,246),(460,240),(520,232),(580,224),(640,215),(700,203),(760,192),(820,180),(880,171),(940,165),(1000,162),(1060,163),(1120,170),(1180,178),(1240,187),(1300,201),(1360,216),(1390,224),(1420,233),(1440,244),(1450,258)]
LO = [(285,282),(300,300),(340,333),(400,343),(460,358),(520,367),(580,390),(640,404),(700,415),(760,426),(820,430),(880,432),(940,433),(1000,433),(1060,431),(1120,429),(1180,426),(1240,420),(1300,418),(1340,412),(1380,395),(1420,330),(1440,290),(1450,262)]
CORNER = 1255
PALATE = [(1255,322),(1300,312),(1400,312),(1430,300),(1450,262)]   # bottom edge of the upper jaw
JAWTOP = [(1255,322),(1280,362),(1330,385),(1358,398)]               # top edge of the open lower jaw
JAWBOT = [(1255,420),(1300,418),(1330,410),(1358,398)]
# top view: half-width in px at top-view x (nose 919, tail joint 190)
TOPW = [(190,13.5),(220,19.5),(250,26.5),(280,36),(310,39.5),(340,42),(370,50),(430,64.5),(490,79.5),(520,84.5),(580,86),(640,90),(700,89.5),(730,86),(760,81.5),(790,74),(820,65),(850,54),(880,39),(910,17.5),(919,4)]
TOP_NOSE, TOP_TAIL = 919, 190

def interp(tab, x):
    if x <= tab[0][0]: return tab[0][1]
    for (x0, y0), (x1, y1) in zip(tab, tab[1:]):
        if x <= x1: return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
    return tab[-1][1]
def halfw(px):  # metres
    t = (NOSE_PX - px) / (NOSE_PX - TAIL_PX); tx = TOP_NOSE - t * (TOP_NOSE - TOP_TAIL)
    return interp(TOPW, tx) * (NOSE_PX - TAIL_PX) * S / (TOP_NOSE - TOP_TAIL)

# fins (side px), from the sheet's silhouette minus the body
FINS = dict(
    Dorsal=dict(pts=[(813,32),(841,95),(849,135),(828,190),(940,175),(1040,170),(1031,153),(917,66),(843,37)], tips=[((813,32),100)], t=0.06),
    Tail=dict(pts=[(70,109),(118,158),(150,202),(174,244),(190,295),(174,365),(133,446),(112,473),(111,479),(163,462),(217,431),(255,393),(281,359),(330,320),(330,270),(320,253),(255,180),(194,141),(138,119)], tips=[((70,109),105),((111,479),105)], t=0.06),
    Dorsal2=dict(pts=[(547,178),(557,232),(625,226),(615,208),(585,189)], tips=[((547,178),45)], t=0.035),
    Anal=dict(pts=[(410,382),(455,365),(462,350),(416,345)], tips=[((410,382),30)], t=0.03),
)
PAIRED = dict(  # bent outward-down: (outline, tips, tip spread in m, root depth py, tip depth py)
    Pectoral=dict(pts=[(782,539),(854,521),(911,495),(938,478),(984,437),(1035,340),(960,350),(900,400),(852,435)], tips=[((782,539),125)], spread=1.0, root=(1000,370), t=0.05),
    Pelvic=dict(pts=[(543,444),(595,428),(631,411),(640,395),(575,385)], tips=[((543,444),48)], spread=0.22, root=(600,395), t=0.03),
)
EYE = [(1318,252),(1332,237),(1362,248),(1354,266),(1328,267)]
BROW = [(1281,228),(1378,256),(1368,268),(1340,256),(1298,244)]
GILLS = [[(1062,240),(1072,240),(1062,342),(1053,342)], [(1100,234),(1110,236),(1095,358),(1086,356)],
         [(1135,229),(1143,231),(1128,363),(1120,361)], [(1172,228),(1182,230),(1163,363),(1154,361)]]

# ---------- helpers ----------
def clear():
    sc = bpy.data.scenes.get("MEGA BITE") or bpy.data.scenes.new("MEGA BITE")
    if bpy.context.window is not None: bpy.context.window.scene = sc
    for o in list(sc.objects): bpy.data.objects.remove(o, do_unlink=True)
    return sc

def mat(name, hexc, emit=0.0):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]; col = lin(hexc)
    b.inputs["Base Color"].default_value = col; b.inputs["Roughness"].default_value = 0.55
    b.inputs["Emission Strength"].default_value = emit
    if emit: b.inputs["Emission Color"].default_value = col
    return m

HALF = [(0.0, 1.0), (0.45, 0.93), (0.85, 0.55), (1.0, 0.05), (0.92, -0.45), (0.62, -0.85), (0.0, -1.0)]
RING = HALF + [(-u, v) for u, v in reversed(HALF[1:-1])]    # 12 points, top -> right side -> bottom -> left side

def ring(px, up_py, lo_py, wmul=1.0, zmin=None, zmax=None):
    zt, zb = Z(up_py), Z(lo_py); zc, hh = (zt + zb) / 2, (zt - zb) / 2; hw = halfw(px) * wmul; x = X(px)
    out = []
    for u, v in RING:
        z = zc + v * hh; cl = False
        if zmin is not None and z < zmin: z = zmin; cl = True
        if zmax is not None and z > zmax: z = zmax; cl = True
        out.append(((x, u * hw, z), cl))
    return out

def line_v(px):   # countershade line (-1 belly .. +1 back). In the body band (ring v 0.05..-0.45) a constant -0.2 makes
    # every quad split white/blue along its alternating diagonal = one continuous jagged zig-zag line, like the sheet.
    return interp([(285,-0.2),(1000,-0.2),(1090,-0.5),(1180,-0.5),(1230,0.0),(1265,0.3),(1450,0.3)], px)

class Builder:
    def __init__(s):
        s.bm = bmesh.new(); s.mats = {}
    def m(s, key): return s.mats[key]
    def face(s, vs, key):
        f = s.bm.faces.new(vs); f.material_index = s.m(key); return f

def loft(B, rings, colour_fn):
    """rings: list of (px, [((x,y,z),clamped), ...]) -> triangles with alternating diagonals (gives the zig-zag)."""
    vr = [[B.bm.verts.new(p) for p, _ in r] for _, r in rings]
    n = len(RING)
    for i in range(len(rings) - 1):
        for j in range(n):
            a, b = vr[i][j], vr[i][(j + 1) % n]; c, d = vr[i + 1][(j + 1) % n], vr[i + 1][j]
            cl = [rings[i][1][j][1], rings[i][1][(j + 1) % n][1], rings[i + 1][1][(j + 1) % n][1], rings[i + 1][1][j][1]]
            tris = [(a, b, c), (a, c, d)] if (i + j) % 2 == 0 else [(a, b, d), (b, c, d)]
            for t in tris:
                if len({id(v) for v in t}) < 3 or len({tuple(round(k, 5) for k in v.co) for v in t}) < 3: continue
                try: f = B.bm.faces.new(t)
                except ValueError: continue
                f.material_index = B.m(colour_fn(f, all(cl)))
    return vr

def colour_body(f, mouth):
    if mouth: return "mouth"
    c = f.calc_center_median(); px = NOSE_PX + (c.x - 2.15) / S
    up, lo = Z(interp(UP, px)), Z(interp(LO if px < CORNER else [(CORNER, 420), (1300, 418), (1340, 412), (1380, 395), (1420, 330), (1440, 290), (1450, 262)], px))
    v = (c.z - (up + lo) / 2) / max((up - lo) / 2, 1e-4)
    return "belly" if v < line_v(px) else "top"

def plate(B, pts3, normal, thick, cols, inner=0.55):
    """A faceted fin: outline at the edge, a smaller raised inner outline on both faces (thick root, thin edge)."""
    c = sum(pts3, Vector()) / len(pts3); n = normal.normalized()
    edge = [B.bm.verts.new(p) for p in pts3]
    for sgn in (1, -1):
        inn = [B.bm.verts.new(c + (p - c) * inner + n * thick * sgn) for p in pts3]
        k = len(pts3)
        for i in range(k):
            q = [edge[i], edge[(i + 1) % k], inn[(i + 1) % k], inn[i]]
            if sgn < 0: q = q[::-1]
            f = B.bm.faces.new(q); f.material_index = B.m(cols(f))
        cap = inn if sgn > 0 else inn[::-1]
        f = B.bm.faces.new(cap); f.material_index = B.m(cols(f))

def tipper(tips, to2d):
    def cols(f):
        p = to2d(f.calc_center_median())
        for (tx, ty), r in tips:
            if (p[0] - tx) ** 2 + (p[1] - ty) ** 2 < r * r: return "tip"
        return "top"
    return cols

def side2d(v): return (NOSE_PX + (v.x - 2.15) / S, 300 - v.z / S)

def embed(pts, depth=16):
    """Push fin points that sit on the body outline into the body so roots never float."""
    out = []
    for px, py in pts:
        up, lo = interp(UP, px), interp(LO, px)
        if abs(py - up) < 14 and TAIL_PX + 20 < px: py += depth
        elif abs(py - lo) < 14 and TAIL_PX + 20 < px < CORNER: py -= depth
        out.append((px, py))
    return out

def build():
    sc = clear()
    me = bpy.data.meshes.new("ReefShark"); ob = bpy.data.objects.new("ReefShark", me); sc.collection.objects.link(ob)
    B = Builder()
    for i, (k, hx) in enumerate(PAL.items()):
        me.materials.append(mat("MB_" + k, hx, emit=4.0 if k == "eye" else 0.0)); B.mats[k] = i
    # 1) body: tail joint -> mouth corner
    stations = [285, 300, 340, 400, 460, 520, 580, 640, 700, 760, 820, 880, 940, 1000, 1060, 1120, 1180, 1220, CORNER]
    body = [(px, ring(px, interp(UP, px), interp(LO, px))) for px in stations]
    vr = loft(B, body, colour_body)
    f = B.bm.faces.new(vr[0][::-1]); f.material_index = B.m("top")        # tail joint cap (hidden by the tail)
    f = B.bm.faces.new(vr[-1]); f.material_index = B.m("mouth")            # throat at the mouth corner
    # 2) upper jaw: body section clamped from below by the palate
    VLO = [(CORNER, 420), (1300, 418), (1340, 412), (1380, 395), (1420, 330), (1440, 290), (1450, 262)]
    head = [(px, ring(px, interp(UP, px), interp(VLO, px), zmin=Z(interp(PALATE, px)))) for px in [CORNER, 1290, 1330, 1370, 1400, 1425, 1440]]
    vh = loft(B, head, colour_body)
    tip = B.bm.verts.new((X(1452), 0, Z(259)))
    for j in range(len(RING)):
        a, b = vh[-1][j], vh[-1][(j + 1) % len(RING)]
        if a.co == b.co: continue
        try: f = B.bm.faces.new((a, b, tip)); f.material_index = B.m("mouth" if head[-1][1][j][1] and head[-1][1][(j + 1) % len(RING)][1] else colour_body(f, False))
        except ValueError: pass
    # 3) lower jaw: clamped from above by the jaw line, a bit narrower towards its tip
    jaw = []
    for px in [CORNER, 1280, 1305, 1330, 1350]:
        w = 1.0 - 0.35 * (px - CORNER) / (1358 - CORNER)
        jaw.append((px, ring(px, interp(UP, px), interp(JAWBOT, px), wmul=w, zmax=Z(interp(JAWTOP, px)))))
    vj = loft(B, jaw, lambda f, m: "mouth" if m else "belly")
    jt = B.bm.verts.new((X(1360), 0, Z(396)))
    for j in range(len(RING)):
        a, b = vj[-1][j], vj[-1][(j + 1) % len(RING)]
        if a.co == b.co: continue
        try: f = B.bm.faces.new((a, b, jt)); f.material_index = B.m("belly")
        except ValueError: pass
    # mouth interior walls (maroon), set inside the cheeks so the open mouth reads dark from the side
    MOUTH = [(CORNER, 322), (1300, 312), (1350, 312), (1400, 312), (1395, 345), (1375, 380), (1358, 398), (1330, 385), (1280, 362)]
    for sy in (1, -1):
        vs = [B.bm.verts.new((X(px), sy * halfw(px) * (0.72 if px < 1400 else 0.6), Z(py))) for px, py in MOUTH]
        f = B.bm.faces.new(vs if sy < 0 else vs[::-1]); f.material_index = B.m("mouth")
    head_faces = len(B.bm.faces)
    # 4) teeth along the jaw edges (upper point down, lower point up), sizes varied like the sheet
    def edge_path(rset, zf, inset):
        right = [(Vector((X(px), max(abs(p[0][1]) for p in r if abs(p[0][2] - zf(px)) < 1e-6 or True) * 0 + halfw_at(r, zf(px)) - inset, zf(px)))) for px, r in rset[1:]]
        return right
    def halfw_at(r, z):
        best = 0.0
        pts = [p for p, _ in r]
        for i in range(len(pts)):
            a, b = Vector(pts[i]), Vector(pts[(i + 1) % len(pts)])
            if (a.z - z) * (b.z - z) <= 0 and a.z != b.z:
                y = a.y + (b.y - a.y) * (z - a.z) / (b.z - a.z); best = max(best, abs(y))
        return best
    def teeth(rset, zf, down, sizes, inset=0.035):
        path = []
        for px, r in rset[1:]:
            path.append(Vector((X(px), halfw_at(r, zf(px)) - inset, zf(px))))
        # front arc across the snout
        last = path[-1]; arc = [Vector((last.x + 0.05 * math.sin(a), last.y * math.cos(a), last.z)) for a in (0.6, 1.2)]
        path = path + arc
        L = [0.0]
        for a, b in zip(path, path[1:]): L.append(L[-1] + (b - a).length)
        n = len(sizes)
        for k, sz in enumerate(sizes):
            d = L[-1] * (0.12 + 0.88 * (k + 0.5) / n)
            for i in range(len(L) - 1):
                if L[i + 1] >= d: break
            f_ = (d - L[i]) / max(L[i + 1] - L[i], 1e-6); p = path[i].lerp(path[i + 1], f_); tng = (path[i + 1] - path[i]).normalized()
            for sy in (1, -1):
                base = Vector((p.x, p.y * sy, p.z)); tg = Vector((tng.x, tng.y * sy, 0)).normalized()
                w = sz * 0.55; h = sz * (-1 if down else 1); th = 0.022
                outn = Vector((0, sy, 0))
                a1, a2 = base - tg * w, base + tg * w; pt = base + Vector((0, 0, h)) - outn * 0.01
                vs = [B.bm.verts.new(q) for q in (a1 + outn * th, a2 + outn * th, pt + outn * th * 0.3, a1 - outn * th, a2 - outn * th, pt - outn * th * 0.3)]
                for tri in ((0, 1, 2), (5, 4, 3), (0, 3, 4, 1), (1, 4, 5, 2), (2, 5, 3, 0)):
                    try: ff = B.bm.faces.new([vs[t] for t in tri]); ff.material_index = B.m("tooth")
                    except ValueError: pass
    teeth(head, lambda px: Z(interp(PALATE, px)), True, [0.12, 0.16, 0.13, 0.17, 0.12, 0.10])
    teeth(jaw, lambda px: Z(interp(JAWTOP, px)), False, [0.11, 0.14, 0.12, 0.10])
    # 5) fins
    for name, F in FINS.items():
        pts = embed(F["pts"]); p3 = [Vector((X(px), 0, Z(py))) for px, py in pts]
        plate(B, p3, Vector((0, 1, 0)), F["t"], tipper(F["tips"], side2d))
    for name, F in PAIRED.items():
        rz = F["root"][1]; tz = max(py for _, py in F["pts"])
        for sy in (1, -1):
            p3 = []
            for px, py in F["pts"]:
                k = min(max((py - rz) / (tz - rz), 0.0), 1.0)
                y = halfw(px) * 0.78 + (F["spread"]) * k
                p3.append(Vector((X(px), y * sy, Z(py) + 0.12 * k * 0)))
            # plane normal
            n = (p3[1] - p3[0]).cross(p3[2] - p3[0])
            if n.length < 1e-6: n = Vector((0, 0, 1))
            plate(B, p3 if sy > 0 else p3[::-1], n, F["t"], tipper(F["tips"], side2d))
    bmesh.ops.recalc_face_normals(B.bm, faces=B.bm.faces[:head_faces])
    B.bm.to_mesh(me); B.bm.free()
    # 6) decals projected onto the body surface (eye, brow, gills) on both sides
    deps = bpy.context.evaluated_depsgraph_get(); bvh = BVHTree.FromObject(ob, deps)
    dm = bmesh.new(); dm.from_mesh(me)
    def proj(px, py, sy):
        o = Vector((X(px), 3.0 * sy, Z(py))); hit = bvh.ray_cast(o, Vector((0, -sy, 0)))
        if hit[0] is None: return None
        n = hit[1] if hit[1].y * sy > 0 else Vector((0, sy, 0))
        return hit[0], n
    def decal(poly, key, lift, th, sub=4):
        """Fan of small triangles, every vertex projected onto the body, so the decal hugs the curved surface."""
        ring2 = []
        for (ax, ay), (bx, by) in zip(poly, poly[1:] + poly[:1]):
            for k in range(sub): ring2.append((ax + (bx - ax) * k / sub, ay + (by - ay) * k / sub))
        cx = sum(p[0] for p in poly) / len(poly); cy = sum(p[1] for p in poly) / len(poly)
        for sy in (1, -1):
            hits = [proj(px, py, sy) for px, py in ring2]; hc = proj(cx, cy, sy)
            if hc is None or any(h is None for h in hits): continue
            top = [dm.verts.new(p + n * (lift + th)) for p, n in hits]; ctr = dm.verts.new(hc[0] + hc[1] * (lift + th * 1.4))
            bot = [dm.verts.new(p - n * 0.012) for p, n in hits]
            k = len(top)
            for i in range(k):
                tri = (top[i], top[(i + 1) % k], ctr) if sy < 0 else (top[(i + 1) % k], top[i], ctr)
                f = dm.faces.new(tri); f.material_index = B.m(key)
                q = (bot[i], bot[(i + 1) % k], top[(i + 1) % k], top[i]) if sy < 0 else (top[i], top[(i + 1) % k], bot[(i + 1) % k], bot[i])
                f = dm.faces.new(q); f.material_index = B.m(key)
    decal(BROW, "tip", 0.0, 0.03)
    decal(EYE, "eye", 0.0, 0.035)
    for g in GILLS: decal(g, "gill", 0.0, 0.01, sub=6)
    dm.to_mesh(me); dm.free()
    for p in me.polygons: p.use_smooth = False
    me.update()
    return ob

def rig(sh, bones=8, jaw_open=8):
    sc = bpy.context.scene
    arm = bpy.data.armatures.new("ReefSharkRig"); ob = bpy.data.objects.new("ReefSharkRig", arm)
    sc.collection.objects.link(ob); bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    xs = [2.25 - i * (2.25 - X(70)) / bones for i in range(bones + 1)]
    prev = None
    for i in range(bones):
        b = arm.edit_bones.new(f"Spine{i}"); b.head = (xs[i], 0, 0); b.tail = (xs[i + 1], 0, 0)
        if prev: b.parent = prev; b.use_connect = True
        prev = b
    zc = Z(322); j = arm.edit_bones.new("Jaw"); j.head = (X(CORNER) - 0.05, 0, zc); j.tail = (X(1358), 0, Z(398)); j.parent = arm.edit_bones["Spine0"]
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="DESELECT"); sh.select_set(True); ob.select_set(True); bpy.context.view_layer.objects.active = ob
    bpy.ops.object.parent_set(type="ARMATURE_NAME")
    seg = (xs[0] - xs[-1]) / bones; groups = [sh.vertex_groups[f"Spine{i}"] for i in range(bones)]; jg = sh.vertex_groups["Jaw"]
    for v in sh.data.vertices:
        c = v.co
        if c.x > X(CORNER) - 0.02 and c.z < Z(interp(JAWTOP, NOSE_PX + (c.x - 2.15) / S)) + 0.005 and c.z < Z(330) and abs(c.y) < 0.6:
            jg.add([v.index], 1.0, "REPLACE"); continue
        u = min(max((xs[0] - c.x) / seg - 0.5, 0.0), bones - 1.0); i0 = int(u); i1 = min(i0 + 1, bones - 1); f = u - i0
        groups[i0].add([v.index], 1 - f, "REPLACE")
        if i1 != i0 and f > 0: groups[i1].add([v.index], f, "REPLACE")
    ob.animation_data_create(); act = bpy.data.actions.new("Swim"); ob.animation_data.action = act
    bpy.ops.object.mode_set(mode="POSE")
    for pb in ob.pose.bones: pb.rotation_mode = "XYZ"
    for fr in range(0, 25, 3):
        for i in range(bones):
            pb = ob.pose.bones[f"Spine{i}"]; amp = math.radians(0.3 + 9 * (i / (bones - 1)) ** 2.2)
            pb.rotation_euler = (0, 0, amp * math.sin(2 * math.pi * fr / 24 - i * 0.7)); pb.keyframe_insert("rotation_euler", frame=fr)
        jb = ob.pose.bones["Jaw"]; jb.rotation_euler = (0, math.radians(jaw_open * (0.6 + 0.4 * math.sin(2 * math.pi * fr / 24))), 0); jb.keyframe_insert("rotation_euler", frame=fr)
    bpy.ops.object.mode_set(mode="OBJECT")
    sc.frame_start, sc.frame_end = 0, 24; sc.frame_set(0)
    return ob

def stage():
    sc = bpy.context.scene
    w = bpy.data.worlds.get("MB_World") or bpy.data.worlds.new("MB_World"); w.use_nodes = True; sc.world = w
    bg = w.node_tree.nodes.get("Background"); bg.inputs[0].default_value = (0.03, 0.30, 0.42, 1); bg.inputs[1].default_value = 0.8
    for name, rot, e in (("MB_Sun", (math.radians(40), 0, math.radians(30)), 3.5), ("MB_Rim", (math.radians(-120), 0, math.radians(-40)), 1.5)):
        ld = bpy.data.lights.get(name) or bpy.data.lights.new(name, "SUN"); ld.energy = e
        o = bpy.data.objects.new(name, ld); sc.collection.objects.link(o); o.rotation_euler = rot
    sc.view_settings.view_transform = "Standard"

sh = build()
RIG = globals().get("WITH_RIG", True)
if RIG: rig(sh)
stage()
print("V3", sh.name, "triangles:", sum(len(p.vertices) - 2 for p in sh.data.polygons))
