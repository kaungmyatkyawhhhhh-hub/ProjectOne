# STOMP EVOLUTION - STONE armour set, model v3 (11 Nov 2026): fitted on the BACON HAIR avatar, not blocky.
# Owner (16:32-16:33): "use this [baconhair.obj] instead of the character" + "the armor dont have to be blocky, they look fat cuz the
# bellys pushing outwards and the legs look like sticks when theyre blocky".
# v3: the wearer is the Bacon Hair body (Art\Character\baconhair.obj, scaled 125 cm per stud, which matches the 1.2x legs exactly).
# The dark under-suit IS that body. The armour is thin fitted stones on its real shape: chest plate, belt, flat skirt flaps,
# thigh plates, knee caps, shin greaves, boots, bracers and fists along the real (angled) arms, the rock shoulder and the back slab.
# Every form is geometry (separate stones, finger columns, carved glowing runes, straps, rivets, crystals, moss).
# Run in Blender through stone_v3_paint.py (builds this, then paints the textures).   Rebuild from the script, never hand-edit.
# v4 (12 Nov 2026, owner 02:14): "i dont like those shoulder things on one side only ... its assymmetrical ... and that thing is huge too"
#   -> the crystal boulder and the slab shoulder are gone. BOTH shoulders now wear the same pauldron: three stepped stone plates that sit ON
#      the upper arm (they move with the arm), a carved glowing rune on the outer plate, two rivets, a small flat moss patch. Mirrored left/right.
#   "it looks like the armor have 9 fingers because from each side theres 3 fingers sticking out"
#   -> the fist has 4 fingers on the FRONT only. The outer side and the back are smooth stone plates; a small thumb sits on the inner side.
# v5 (12 Nov 03:20, owner: "the hips are wide and it look feminine ... the classic titan simulator catalog bundles look WAY better").
#   Rebuilt on the measured proportions of 5 classic Roblox armour bundles (Korblox General 256, Redcliff Elite Commander 229,
#   Knightmare 241, Divine Guardian 168, Dark Avenger 193): lower torso never wider than the chest (no hip flare), slim upper legs
#   (~0.85 stud) with chunky boots, legs closer, slim tapered gauntlets (~1 stud) instead of brick rings, a smaller fist (~0.8 stud),
#   bigger pauldrons that sit higher. Few big plates, not many small bricks.
import bpy, bmesh, math, random, os
from collections import defaultdict
from mathutils import Vector, Matrix, Euler

COLL = "StoneSet_v7"
CHAR = os.environ.get("STONE_CHAR") or r"C:\ObsidianOne\Claude+Obsidian\TITAN ARC\Art\Character\baconhair.obj"
CS, CX0, CZ0 = 125.0, -20.0, 14.49        # cm per stud; the avatar's centre line in the OBJ
# Owner (16:55): "the hips need to be wider by 0.3 studs and legs wider by 0.3 studs each side too". Set both to 0 for the stock avatar.
HIPW = float(os.environ.get("STONE_HIPW", "0.0")) * CS       # hips: wider by this much on EACH side
LEGW = 0.0                                                    # (the +0.3 stud block legs "look fat", owner 17:18: legs are now sculpted, see leg())
LEG_X = float(os.environ.get("STONE_LEG_X", "57"))            # each leg's centre line, cm from the middle (stock avatar: 49). Wider stance = a gap between the legs
SH_K = float(os.environ.get("STONE_SH_K", "0.7"))            # size of the rock shoulder (1 = the first, too big, version)
SH_AT = (-152.0, -18.0, 468.0)                                # where its centre sits: on the shoulder joint
ARM_OUT = float(os.environ.get("STONE_ARM_OUT", "0"))       # arms swung this many degrees further out, so the bracers clear the wider hips
S = 0.01
LEG = 252.0                      # leg length (sheet 210 x 1.2) = the Bacon Hair leg (2.01 studs x 125)
UP = LEG - 210.0                 # everything above the legs moves up by this
def ZU(y): return 650.0 - y + UP # sheet y px -> model height for the upper body

MAT_ORDER = ["stone", "stone2", "slate", "leather", "metal", "glow", "groove", "crystal", "moss", "skin", "face", "sole", "gap", "suit", "hair"]
MI = {n: i for i, n in enumerate(MAT_ORDER)}
PAL = {  # sRGB 0-255, sampled from the sheet
    "stone": (138, 108, 88), "stone2": (108, 90, 72), "slate": (58, 60, 66), "leather": (118, 58, 32), "metal": (172, 172, 178),
    "glow": (205, 255, 40), "groove": (92, 120, 22), "crystal": (96, 200, 12), "moss": (104, 122, 26), "skin": (247, 203, 160),
    "face": (22, 20, 18), "sole": (40, 42, 46), "gap": (40, 28, 24), "suit": (58, 60, 66), "hair": (124, 66, 36)}
PARTS = defaultdict(list)

def lin(c): return tuple(((v / 255.0) / 12.92 if v / 255.0 < 0.04045 else ((v / 255.0 + 0.055) / 1.055) ** 2.4) for v in c)

def mats():
    out = []
    for n in MAT_ORDER:
        m = bpy.data.materials.get("SS2_" + n) or bpy.data.materials.new("SS2_" + n)
        m.use_nodes = True; b = m.node_tree.nodes.get("Principled BSDF")
        if b:
            b.inputs["Base Color"].default_value = (*lin(PAL[n]), 1); b.inputs["Roughness"].default_value = 0.85
            if n in ("glow", "crystal", "groove"):
                b.inputs["Emission Color"].default_value = (*lin(PAL[n]), 1)
                b.inputs["Emission Strength"].default_value = {"glow": 3.0, "crystal": 0.8, "groove": 0.5}[n]
        m.diffuse_color = (*lin(PAL[n]), 1); out.append(m)
    return out

def V(x, f, z): return Vector((x, -f, z))          # f = towards the character's FRONT (Blender front is -Y)

def setmat(bm, m):
    for f in bm.faces: f.material_index = MI[m]

def fin(bm, grp, smooth=False, recalc=True):
    if recalc: bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    for f in bm.faces: f.smooth = smooth
    PARTS[grp].append(bm); return bm

ROUND = float(os.environ.get("STONE_ROUND", "1.8"))
def bevel(bm, off, seg=1):
    # v7: round every edge (3 segments, wider): pillowed, sculpted plates instead of blocks (owner: "korblox models are not blocky")
    if off > 0: bmesh.ops.bevel(bm, geom=bm.edges[:], offset=off * ROUND, segments=max(seg, 3), profile=0.5, affect='EDGES', clamp_overlap=True)

def chip(bm, r, amt):
    """knock a corner off, like a chiselled stone."""
    xs = [v.co for v in bm.verts]
    mn = Vector((min(p.x for p in xs), min(p.y for p in xs), min(p.z for p in xs))); mx = Vector((max(p.x for p in xs), max(p.y for p in xs), max(p.z for p in xs)))
    d = Vector((r.choice((-1, 1)), r.choice((-1, 1)), r.choice((-1, 1))))
    corner = Vector(((mx.x if d.x > 0 else mn.x), (mx.y if d.y > 0 else mn.y), (mx.z if d.z > 0 else mn.z)))
    n = Vector((d.x * r.uniform(0.5, 1), d.y * r.uniform(0.5, 1), d.z * r.uniform(0.5, 1))).normalized()
    bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], dist=1e-4, plane_co=corner - n * amt, plane_no=n, clear_outer=True)
    bmesh.ops.holes_fill(bm, edges=bm.edges[:], sides=0)

def box(grp, m, c, size, bev=4, jit=0.0, seed=0, rot=(0, 0, 0), taper=None, chips=0, chipamt=None, seg=1, smooth=False):
    """chamfered block. c = (x, f, z) centre, size = (x, f, z). taper = (x, f) scale of the TOP. rot in degrees (Blender axes)."""
    r = random.Random(seed); bm = bmesh.new(); bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        p = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
        if taper and v.co.z > 0: p.x *= taper[0]; p.y *= taper[1]
        if jit: p += Vector((r.uniform(-jit, jit), r.uniform(-jit, jit), r.uniform(-jit, jit)))
        v.co = p
    bevel(bm, bev, seg)
    for i in range(chips): chip(bm, r, chipamt or min(size) * r.uniform(0.18, 0.32))
    bm.transform(Matrix.Translation(V(*c)) @ Euler([math.radians(a) for a in rot]).to_matrix().to_4x4())
    setmat(bm, m); return fin(bm, grp, smooth)

def FR(side, x, f, z, tilt=0.0, roll=0.0):
    """a drawing board on one side of the body: local (u, v, w) -> world. w points OUT of that side, v is up."""
    u, v, w = {"F": ((1, 0, 0), (0, 0, 1), (0, -1, 0)), "B": ((-1, 0, 0), (0, 0, 1), (0, 1, 0)), "R": ((0, 1, 0), (0, 0, 1), (1, 0, 0)),
               "L": ((0, -1, 0), (0, 0, 1), (-1, 0, 0)), "T": ((1, 0, 0), (0, 1, 0), (0, 0, 1))}[side]
    M = Matrix(((u[0], v[0], w[0], 0), (u[1], v[1], w[1], 0), (u[2], v[2], w[2], 0), (0, 0, 0, 1)))
    M = Matrix.Translation(V(x, f, z)) @ M
    if tilt: M = M @ Matrix.Rotation(math.radians(tilt), 4, 'X')      # lean the board back (+) or forward (-)
    if roll: M = M @ Matrix.Rotation(math.radians(roll), 4, 'Z')      # turn the drawing on the board
    return M

def plate(grp, m, M, pts, w0, w1, bev=3, top=1.0, jit=0.0, seed=0, chips=0, smooth=False, keep=False):
    """a flat stone plate: outline pts (u, v) on board M, from depth w0 to w1. top = scale of the outer face (slanted sides)."""
    r = random.Random(seed); bm = bmesh.new(); n = len(pts)
    cx = sum(p[0] for p in pts) / n; cy = sum(p[1] for p in pts) / n
    a = [bm.verts.new((x, y, w0)) for x, y in pts]
    b = [bm.verts.new((cx + (x - cx) * top + r.uniform(-jit, jit), cy + (y - cy) * top + r.uniform(-jit, jit), w1 + r.uniform(-jit, jit) * 0.5)) for x, y in pts]
    bm.faces.new(a[::-1]); bm.faces.new(b)
    for i in range(n): bm.faces.new([a[i], a[(i + 1) % n], b[(i + 1) % n], b[i]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:]); bevel(bm, bev)
    for i in range(chips): chip(bm, r, abs(w1 - w0) * r.uniform(0.5, 0.9))
    bm.transform(M); setmat(bm, m)
    if keep: bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:]); return bm
    return fin(bm, grp, smooth)

def octa(cx, cy, rx, ry, k=0.42):
    return [(cx - rx * (1 - k), cy - ry), (cx + rx * (1 - k), cy - ry), (cx + rx, cy - ry * (1 - k)), (cx + rx, cy + ry * (1 - k)),
            (cx + rx * (1 - k), cy + ry), (cx - rx * (1 - k), cy + ry), (cx - rx, cy + ry * (1 - k)), (cx - rx, cy - ry * (1 - k))]

def hull(grp, m, pts, bev=4, keep=False, chips=0, seed=0, chipamt=20, cuts=()):
    bm = bmesh.new()
    for p in pts: bm.verts.new(p)
    bmesh.ops.convex_hull(bm, input=bm.verts[:])
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
    bmesh.ops.dissolve_limit(bm, angle_limit=math.radians(2), verts=bm.verts[:], edges=bm.edges[:])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    r = random.Random(seed)
    for i in range(chips): chip(bm, r, chipamt * r.uniform(0.7, 1.2))
    for co, no in cuts:
        bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], dist=1e-4, plane_co=co, plane_no=Vector(no).normalized(), clear_outer=True)
        bmesh.ops.holes_fill(bm, edges=bm.edges[:], sides=0)
    bevel(bm, bev); setmat(bm, m)
    if keep: bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:]); return bm
    return fin(bm, grp)

# ---------- carving: glowing runes and cracks are CUT INTO the stone ----------
def spiral(cx, cy, s, flip=1, skew=0.0, tail=None):
    p = [(0.05, 0.08), (0.42, 0.08), (0.42, -0.36), (-0.42, -0.36), (-0.42, 0.5), (0.85, 0.5), (0.85, -0.8)]
    if tail is not None: p.append((tail, -0.8))
    return [(cx + flip * (x + skew * y) * s, cy + y * s) for x, y in p]

def crack(pts, seed, amp=5.0, branch=True):
    """a jagged lightning crack through the given points, with a small side branch."""
    r = random.Random(seed); out = []; br = []
    for i in range(len(pts) - 1):
        a, b = Vector(pts[i]), Vector(pts[i + 1]); d = b - a; n = Vector((-d.y, d.x)).normalized()
        out.append(tuple(a))
        for t in (0.33, 0.66): out.append(tuple(a + d * t + n * r.uniform(-amp, amp)))
    out.append(tuple(pts[-1]))
    if branch and len(out) > 4:
        k = r.randrange(2, len(out) - 2); a = Vector(out[k]); d = (Vector(out[k + 1]) - a)
        n = Vector((-d.y, d.x)).normalized() * r.choice((-1, 1)); br = [tuple(a), tuple(a + n * 9 + d.normalized() * 5), tuple(a + n * 15 + d.normalized() * 13)]
    return [out] + ([br] if br else [])

def _ribbon(M, ln, width, depth, floor="glow", wall="groove"):
    """one clean cutter for one line: the line widened to a ribbon (mitred corners, square ends) and pushed into the stone."""
    P2 = [Vector((p[0], p[1])) for p in ln]
    P2 = [p for i, p in enumerate(P2) if i == 0 or (p - P2[i - 1]).length > 1e-4]
    if len(P2) < 2: return None
    D = [(P2[i + 1] - P2[i]).normalized() for i in range(len(P2) - 1)]; h = width / 2.0
    Lp, Rp = [], []
    for i, p in enumerate(P2):
        if i == 0: d = D[0]; n = Vector((-d.y, d.x)); q = p - d * h; Lp.append(q + n * h); Rp.append(q - n * h)
        elif i == len(P2) - 1: d = D[-1]; n = Vector((-d.y, d.x)); q = p + d * h; Lp.append(q + n * h); Rp.append(q - n * h)
        else:
            n0 = Vector((-D[i - 1].y, D[i - 1].x)); n1 = Vector((-D[i].y, D[i].x)); m = n0 + n1
            if m.length < 1e-4: m = n0
            m.normalize(); k = min(1.0 / max(m.dot(n0), 0.35), 2.6); Lp.append(p + m * h * k); Rp.append(p - m * h * k)
    poly = Lp + Rp[::-1]; bm = bmesh.new()
    lo = [bm.verts.new((p.x, p.y, -depth)) for p in poly]; hi = [bm.verts.new((p.x, p.y, depth * 4 + 6)) for p in poly]
    f = bm.faces.new(lo); f.material_index = MI[floor]
    f = bm.faces.new(hi[::-1]); f.material_index = MI[wall]; n = len(poly)
    for i in range(n):
        f = bm.faces.new([lo[i], hi[i], hi[(i + 1) % n], lo[(i + 1) % n]]); f.material_index = MI[wall]
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:]); bm.transform(M); return bm

def _obj(bm, name):
    me = bpy.data.meshes.new(name); bm.to_mesh(me)
    for mm in MATS: me.materials.append(mm)
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o); return o

def carve(bm, M, lines, width=5.0, depth=3.5, dark=False):
    """cut channels along the lines; the channel floor glows, the walls are lit stone. (dark=True: a plain dark seam)"""
    ot = _obj(bm, "_t"); cut = []
    for i, ln in enumerate(lines):
        cb = _ribbon(M, ln, width + 0.07 * i, depth + 0.05 * i, *(("gap", "gap") if dark else ("glow", "groove")))
        if cb is None: continue
        oc = _obj(cb, "_c"); cb.free(); cut.append(oc)
        md = ot.modifiers.new("b%d" % i, 'BOOLEAN'); md.operation = 'DIFFERENCE'; md.object = oc
        try: md.material_mode = 'INDEX'
        except Exception: pass
    nb = None
    for solver in ('EXACT', 'MANIFOLD', 'FLOAT', 'FAST'):
        try:
            for md in ot.modifiers: md.solver = solver
        except Exception: continue
        dg = bpy.context.evaluated_depsgraph_get(); dg.update()
        me = bpy.data.meshes.new_from_object(ot.evaluated_get(dg))
        nb = bmesh.new(); nb.from_mesh(me); bpy.data.meshes.remove(me)
        bad = sum(1 for e in nb.edges if len(e.link_faces) != 2)
        if len(nb.faces) > len(bm.faces) and not bad: break
        nb.free(); nb = None
    if nb is None:                                   # every way of cutting failed: keep the uncut stone
        print("carve failed, kept uncut", [round(v, 1) for v in M.translation]); nb = bm.copy()
    for o in [ot] + cut:
        d = o.data; bpy.data.objects.remove(o, do_unlink=True); bpy.data.meshes.remove(d)
    bm.free()
    return nb

def split(bm, M, pts_list, seeds, width=1.8, depth=2.6):
    """dark seams cut into a big stone so it reads as fitted pieces."""
    lines = []
    for pts, sd in zip(pts_list, seeds):
        r = random.Random(sd); ln = []
        for i in range(len(pts) - 1):
            a, b = Vector(pts[i]), Vector(pts[i + 1]); d = b - a; n = Vector((-d.y, d.x)).normalized()
            ln += [tuple(a), tuple(a + d * 0.5 + n * r.uniform(-3, 3))]
        lines.append(ln + [tuple(pts[-1])])
    return carve(bm, M, lines, width, depth, dark=True)

def keepfin(bm, grp):
    for f in bm.faces: f.smooth = False
    PARTS[grp].append(bm); return bm

# ---------- small props ----------
def rivet(grp, M, u, v, r=6.5, h=4.5):
    bm = bmesh.new(); bmesh.ops.create_uvsphere(bm, u_segments=8, v_segments=4, radius=1.0)
    bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], dist=1e-5, plane_co=(0, 0, -0.15), plane_no=(0, 0, -1), clear_outer=True)
    bmesh.ops.holes_fill(bm, edges=bm.edges[:], sides=0)
    bm.transform(Matrix.Translation((u, v, 0)) @ Matrix.Diagonal((r, r, h, 1)))
    bm.transform(M); setmat(bm, "metal"); return fin(bm, grp, True)

def crystal(grp, base, tip, rad, sides=6, lean=0.0):
    b, t = V(*base), V(*tip); ax = (t - b); L = ax.length; ax.normalize()
    rot = Vector((0, 0, 1)).rotation_difference(ax).to_matrix().to_4x4()
    bm = bmesh.new(); rings = [[], []]
    for k, (h, rr) in enumerate(((0.0, rad * 0.72), (0.66, rad))):
        for i in range(sides):
            a = 2 * math.pi * (i + 0.5) / sides
            rings[k].append(bm.verts.new(b + rot @ Vector((math.cos(a) * rr, math.sin(a) * rr, h * L))))
    top = bm.verts.new(t + rot @ Vector((rad * lean, 0, 0)))
    for i in range(sides):
        j = (i + 1) % sides
        bm.faces.new([rings[0][i], rings[0][j], rings[1][j], rings[1][i]]); bm.faces.new([rings[1][i], rings[1][j], top])
    bm.faces.new(rings[0][::-1]); setmat(bm, "crystal"); return fin(bm, grp)

def shard(grp, c, rx, rz, seed):
    r = random.Random(seed); bm = bmesh.new(); pts = []
    for i in range(5):
        a = 2 * math.pi * i / 5 + r.uniform(-0.2, 0.2)
        pts.append(Vector((math.cos(a) * rx * r.uniform(0.8, 1.1), math.sin(a) * rx * r.uniform(0.8, 1.1), r.uniform(-0.15, 0.2) * rz)))
    pts += [Vector((r.uniform(-2, 2), r.uniform(-2, 2), rz)), Vector((r.uniform(-2, 2), r.uniform(-2, 2), -rz * 0.8))]
    for p in pts: bm.verts.new(p + V(*c))
    bmesh.ops.convex_hull(bm, input=bm.verts[:]); setmat(bm, "stone"); return fin(bm, grp)

def moss(grp, c, rx, rf, n, seed, strands=0, slen=30, sdir=(0, 1, 0), flat=0.55, size=(7, 13)):
    """a clump of leafy lumps draped on a top, with strands hanging over the edge."""
    r = random.Random(seed)
    for i in range(n):
        a = r.uniform(0, 2 * math.pi); d = math.sqrt(r.uniform(0, 1)); s = r.uniform(*size)
        bm = bmesh.new(); bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0)
        for v in bm.verts: v.co += Vector((r.uniform(-.18, .18), r.uniform(-.18, .18), r.uniform(-.18, .18)))
        bm.transform(Matrix.Translation(V(c[0] + math.cos(a) * d * rx, c[1] + math.sin(a) * d * rf, c[2] + r.uniform(-1, 2))) @ Euler((r.uniform(-.3, .3), r.uniform(-.3, .3), r.uniform(0, 3))).to_matrix().to_4x4() @ Matrix.Diagonal((s, s * r.uniform(0.7, 1.1), s * flat, 1)))
        setmat(bm, "moss"); fin(bm, grp)
    for i in range(strands):
        t = (i + 0.5) / strands - 0.5; L = slen * r.uniform(0.5, 1.0); wd = r.uniform(2.6, 4.2)
        px = c[0] + sdir[0] * rx * 0.96 + (-sdir[1]) * t * 2 * rx * 0.8; pf = c[1] + sdir[1] * rf * 0.96 + (sdir[0]) * t * 2 * rf * 0.8
        bm = bmesh.new(); k = []
        for (h, w) in ((0, wd), (-L * 0.45, wd * 0.9), (-L * 0.8, wd * 0.55)):
            off = Vector((sdir[0], -sdir[1], 0)) * (2.5 + (-h) * 0.04)
            k.append([bm.verts.new(V(px, pf, c[2] + 2 + h) + off + Vector((math.cos(q) * w, math.sin(q) * w, 0))) for q in (0.5, 2.6, 4.7)])
        tip = bm.verts.new(V(px, pf, c[2] + 2 - L) + Vector((sdir[0], -sdir[1], 0)) * 3)
        for a_, b_ in ((0, 1), (1, 2)):
            for q in range(3): bm.faces.new([k[a_][q], k[a_][(q + 1) % 3], k[b_][(q + 1) % 3], k[b_][q]])
        for q in range(3): bm.faces.new([k[2][q], k[2][(q + 1) % 3], tip])
        bm.faces.new(k[0][::-1]); setmat(bm, "moss"); fin(bm, grp)

def ring(grp, m, cx, cf, z0, z1, hx, hf, th, cham, counts, seed, gap=2.6, bev=3.0, jit=2.2, chipp=0.6):
    """a band of separate stone blocks round a limb. counts = blocks along the (front, right, back, left) sides."""
    r = random.Random(seed)
    def outline(hx, hf, ch):
        return [(hx - ch, hf), (hx, hf - ch), (hx, -hf + ch), (hx - ch, -hf), (-hx + ch, -hf), (-hx, -hf + ch), (-hx, hf - ch), (-hx + ch, hf)]   # (x, f): front-right corner first, clockwise from above
    O = outline(hx, hf, cham); I = outline(hx - th, hf - th, max(cham - th * 0.42, 1.0))
    def at(P, seg, t): a, b = P[seg], P[(seg + 1) % 8]; return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
    # straight sides are segs 1 (right), 3 (back), 5 (left), 7 (front); chamfers are 0, 2, 4, 6. Cuts only on the straight sides.
    cuts = []
    for seg, cnt in ((7, counts[0]), (1, counts[1]), (3, counts[2]), (5, counts[3])):      # counts = number of joints on each side
        for k in range(cnt):
            cuts.append((seg, min(max((k + 1) / (cnt + 1.0) + r.uniform(-0.3, 0.3) / (cnt + 1.0), 0.1), 0.9)))
    cuts.sort(); nC = len(cuts)
    Lseg = lambda P, s_: (Vector(P[(s_ + 1) % 8]) - Vector(P[s_])).length
    for ci in range(nC):
        (s0, t0), (s1, t1) = cuts[ci], cuts[(ci + 1) % nC]
        g0 = gap / 2 / Lseg(O, s0); g1 = gap / 2 / Lseg(O, s1)
        steps = (s1 - s0) % 8
        if steps == 0 and t1 <= t0: steps = 8
        chain = [(s0, t0 + g0)] + [((s0 + k) % 8, 0.0) for k in range(1, steps + 1)] + [(s1, t1 - g1)]
        dz0, dz1, push = r.uniform(-jit, jit), r.uniform(-jit, jit), r.uniform(0, jit * 1.3)
        op = [at(O, s_, t_) for s_, t_ in chain]; ip = [at(I, s_, t_) for s_, t_ in chain]
        mx = sum(p[0] for p in op) / len(op); mf = sum(p[1] for p in op) / len(op); L = math.hypot(mx, mf) or 1
        op = [(p[0] + mx / L * push, p[1] + mf / L * push) for p in op]
        poly = op + ip[::-1]; bm = bmesh.new()
        a = [bm.verts.new(V(cx + x, cf + f, z0 + dz0)) for x, f in poly]; b = [bm.verts.new(V(cx + x, cf + f, z1 + dz1)) for x, f in poly]
        bm.faces.new(a); bm.faces.new(b[::-1]); n = len(poly)
        for i in range(n): bm.faces.new([a[i], b[i], b[(i + 1) % n], a[(i + 1) % n]])
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:]); bevel(bm, bev)
        if r.random() < chipp: chip(bm, r, th * r.uniform(0.45, 0.8))
        setmat(bm, m); fin(bm, grp)

# =====================================================================================================
# the wearer: Bacon Hair. Roblox (x right, y up, -z front) -> here (X = -x, front = -Y, Z = y)
def _ss(a, b, x): t = max(0.0, min(1.0, (x - a) / (b - a))); return t * t * (3 - 2 * t)

def arm_extra(s):
    piv = V(s * 120.0, -22.8, 462.0)
    return Matrix.Translation(piv) @ Matrix.Rotation(math.radians(-s * ARM_OUT), 4, 'Y') @ Matrix.Translation(-piv)

def reshape(g, p):
    """the owner's proportions on the stock avatar: wider hips, wider legs, arms a little further out."""
    sg = 1.0 if p.x > 0 else -1.0
    if g in ("BaconHairBoy2", "BaconHairBoy4"): p.x += sg * LEGW * _ss(30.0, 70.0, abs(p.x))            # the outer half of the leg moves out, corners keep their shape
    elif g == "BaconHairBoy1": p.x += sg * HIPW * _ss(30.0, 80.0, abs(p.x)) * (1.0 - _ss(300.0, 326.0, p.z))   # hips only: they flare out below the waist, the waist and chest stay
    elif g in ("BaconHairBoy3", "BaconHairBoy5"): p = arm_extra(-1.0 if g.endswith("3") else 1.0) @ p
    return p

def character():
    V_, N_, groups, cur = [], [], {}, None
    for l in open(CHAR):
        if l.startswith("v "): a = l.split(); V_.append((float(a[1]), float(a[2]), float(a[3])))
        elif l.startswith("vn "): a = l.split(); N_.append((float(a[1]), float(a[2]), float(a[3])))
        elif l.startswith("g "): cur = l.split()[1]; groups[cur] = []
        elif l.startswith("f ") and cur:
            c = [t.split("/") for t in l.split()[1:]]
            groups[cur].append([(int(t[0]) - 1, (int(t[2]) - 1) if len(t) > 2 and t[2] else -1) for t in c])
    for g, faces in groups.items():
        if g not in ("Handle1", "BaconHairBoy6"): continue        # only the wearer's head and hair are kept: the whole body is OUR bundle (body(), arm(), leg())
        bm = bmesh.new(); vm = {}; lay = bm.loops.layers.float_vector.new("cn")       # the avatar keeps its own smooth normals
        for f in faces:
            vs = []
            for i, ni in f:
                if i not in vm: x, y, z = V_[i]; vm[i] = bm.verts.new(reshape(g, V(-(x - CX0) * CS, (CZ0 - z) * CS, y * CS)))
                vs.append(vm[i])
            try: fc = bm.faces.new(vs)
            except ValueError: continue
            for lp, (i, ni) in zip(fc.loops, f):
                if ni >= 0:
                    nx, ny, nz = N_[ni]; nv = Vector((-nx, nz, ny))
                    if g in ("BaconHairBoy3", "BaconHairBoy5"): nv = arm_extra(-1.0 if g.endswith("3") else 1.0).to_3x3() @ nv
                    lp[lay] = nv
        m = "hair" if g.startswith("Handle") else ("skin" if g.endswith("6") else "suit")
        setmat(bm, m); fin(bm, "Head" if m != "suit" else "Body", True, recalc=False)
    # the classic smile, wrapped on the front of the head (the OBJ came without its face picture)
    zc = 559.5; R_ = 73.3
    def onhead(pts):
        bm = bmesh.new(); vs = []
        for x, z in pts:
            a = math.asin(max(-1, min(1, x / R_))); vs.append(bm.verts.new(V(R_ * math.sin(a), R_ * math.cos(a), zc + z)))
        return bm, vs
    for sx in (-1, 1):
        pts = [(sx * 24 + 5.2 * math.cos(2 * math.pi * i / 12), -2 + 10.5 * math.sin(2 * math.pi * i / 12)) for i in range(12)]
        bm, vs = onhead(pts); f = bm.faces.new(vs); f.normal_update()
        if f.normal.y > 0: f.normal_flip()
        setmat(bm, "face"); fin(bm, "Head", True, recalc=False)
    up, lo = [], []
    for i in range(13):
        t = -1 + 2 * i / 12.0; x = 36 * t; th = 5.2 * (1 - 0.55 * t * t); z_ = -46 + 17 * t * t
        up.append((x, z_ + th / 2)); lo.append((x, z_ - th / 2))
    bm, vs = onhead(up + lo[::-1]); n = 13
    for i in range(n - 1):
        f = bm.faces.new([vs[i], vs[i + 1], vs[2 * n - 2 - i], vs[2 * n - 1 - i]]); f.normal_update()
        if f.normal.y > 0: f.normal_flip()
    setmat(bm, "face"); fin(bm, "Head", True, recalc=False)

def body():
    """Owner 17:59: "the bundles are good but i want our own one to be different from titan simulator armor".
    So the set is built the way a catalog body bundle is built (every body part its own sculpted mesh, the player's head on top),
    with our own design. Measured in Studio for proportion only: a catalog armour bundle puts its bulk in the upper torso and
    shoulders and keeps the limbs about one stud wide. Chest wide, waist narrow, hips flare, slim upper arms, big gauntlets."""
    HW = 92.0 + HIPW
    loft("UpperTorso", "suit", 1, [(522, 0, 37, -42, 30, 9), (487, 0, 62, -54, 40, 12)], 2.0)                                  # neck
    loft("UpperTorso", "suit", 1, [(492, 0, 128, -58, 46, 16), (476, 0, 146, -66, 67, 16), (432, 0, 142, -66, 67, 15), (380, 0, 108, -64, 64, 13), (338, 0, 88, -60, 60, 12)], 2.5)
    loft("LowerTorso", "suit", 1, [(340, 0, 88, -60, 60, 12), (322, 0, 90, -62, 60, 12), (302, 0, HW, -68.6, 61, 14), (262, 0, HW, -68.6, 61, 14), (249, 0, HW - 12, -62, 55, 14)], 2.5)

# body sizes at this scale (cm): chest X +-115, front f 68, back f -66 (z 340..470); hips X +-104.5, f 61 / -68.6 (z 251..326);
# legs: centre X +-50 (thigh 0..97.6, shin 7.4..97.6), f -56..51, foot to f 99.5; arms: shoulder (+-127.5, -22.8, 470.2), 281 long, 17 deg out, 12 deg forward.
def torso():
    G = "UpperTorso"
    # v6: a full stone cuirass from the collar to the belt (owner: Korblox reads better; no under-suit showing above the belt)
    loft(G, "stone2", 1, [(498, 0, 132, -64, 56, 22), (480, 0, 154, -74, 71, 22), (432, 0, 150, -74, 71, 20), (382, 0, 116, -71, 67, 16), (338, 0, 95, -65, 63, 13)], 3.5)
    loft(G, "stone", 1, [(502, 0, 136, -66, 58, 20), (490, 0, 158, -77, 74, 20), (478, 0, 158, -77, 74, 20)], 3.0)          # raised top rim (gorget edge)
    loft(G, "stone", 1, [(350, 0, 99, -67, 65, 13), (336, 0, 97, -66, 64, 13)], 2.5)                                      # raised bottom rim
    F = FR("F", 0, 72, 0)
    O = [(-88, 474), (88, 474), (132, 420), (78, 346), (-78, 346), (-132, 420)]
    I = [(-24, 451), (24, 451), (42, 413), (24, 375), (-24, 375), (-42, 413)]
    for i in range(6):                                                                    # six stone wedges round a framed gem
        j = (i + 1) % 6; q = [O[i], O[j], I[j], I[i]]
        cx = sum(p[0] for p in q) / 4; cy = sum(p[1] for p in q) / 4
        plate(G, "stone", F, [(cx + (x - cx) * 0.965, cy + (y - cy) * 0.965) for x, y in q], -1, 13 + (i % 2) * 2.5, 3.5, top=0.93, jit=0.8, seed=40 + i)
    plate(G, "sole", F, [(-40, 453), (40, 453), (44, 413), (40, 373), (-40, 373), (-44, 413)], -1, 8, 2)
    Ro = [(0, 465), (40, 443), (40, 385), (0, 361), (-40, 385), (-40, 443)]; Ri = [(0, 451), (28, 435), (28, 392), (0, 375), (-28, 392), (-28, 435)]
    for i in range(6):
        j = (i + 1) % 6; q = [Ro[i], Ro[j], Ri[j], Ri[i]]
        cx = sum(p[0] for p in q) / 4; cy = sum(p[1] for p in q) / 4
        plate(G, "stone", F, [(cx + (x - cx) * 0.95, cy + (y - cy) * 0.95) for x, y in q], 7, 21, 2.5, top=0.9, seed=50 + i)
    bm = bmesh.new(); g = [(0, 449), (26, 434), (26, 393), (0, 377), (-26, 393), (-26, 434)]                # the gem: girdle, crown facets, table
    a = [bm.verts.new((x, y, 9)) for x, y in g]; b = [bm.verts.new((x * 0.5, 413 + (y - 413) * 0.6, 27)) for x, y in g]
    bm.faces.new(a[::-1]); bm.faces.new(b)
    for i in range(6): bm.faces.new([a[i], a[(i + 1) % 6], b[(i + 1) % 6], b[i]])
    bm.transform(F); setmat(bm, "crystal"); fin(bm, G)
    for sx in (-1, 1):
        q = [(sx * 20, 487), (sx * 96, 486), (sx * 113, 464), (sx * 76, 448), (sx * 30, 460)]              # collar stones
        plate(G, "stone", FR("F", 0, 44, 0), q if sx > 0 else q[::-1], 0, 29, 5.0, top=0.88, jit=1.2, seed=60 + sx)
        pass   # v6: chest straps and rivets removed (cleaner chest like a catalog bundle)
    # back: the rune slab, held by straps
    Bk = FR("B", 0, -74, 0)
    slab = plate(G, "stone", Bk, [(0, 522), (80, 486), (82, 362), (46, 280), (0, 238), (-46, 280), (-82, 362), (-80, 486)], 3, 26, 5, top=0.9, keep=True)
    Bs = FR("B", 0, -74 - 26, 0)
    slab = carve(slab, Bs, [[(0, 264), (0, 384)], spiral(0, 414, 28), [(0, 450), (0, 498)], [(-44, 330), (-28, 316)], [(44, 330), (28, 316)]], 6.0, 4.0)
    slab = split(slab, Bs, [[(-64, 462), (-28, 436), (-42, 388)], [(56, 470), (32, 446)], [(-56, 330), (-20, 352)], [(60, 370), (28, 388), (22, 434)], [(-24, 268), (-10, 300)]], (611, 612, 613, 614, 615))
    keepfin(slab, G)
    for sx in (-1, 1):
        q = [(sx * 70, 462), (sx * 108, 466), (sx * 108, 442), (sx * 70, 438)]
        plate(G, "leather", Bk, q if sx > 0 else q[::-1], -2, 9, 1.5)
        rivet(G, FR("B", 0, -83, 0), sx * 88, 452, 6, 4); rivet(G, FR("B", 0, -83, 0), sx * 102, 454, 5, 3.5)
    moss(G, (-28, -95, 266), 20, 5, 5, 91, strands=3, slen=30, sdir=(0, -1, 0), size=(6, 10))

def waist():
    G = "LowerTorso"; H = HIPW; HW = 92.0 + HIPW; bh = 92.0                              # the belt sits on the narrow waist; the hips flare out below it
    box(G, "leather", (0, 1, 333), (2 * bh, 142, 28), 3)                                  # belt, snug on the waist
    F = FR("F", 0, 72, 0); Bk = FR("B", 0, -70, 0)
    for u in (-0.49 * bh, 0.49 * bh): rivet(G, F, u, 333, 6, 4); rivet(G, Bk, u, 333, 6, 4)
    for u in (-0.8 * bh, 0.8 * bh): rivet(G, F, u, 333, 5, 3.5); rivet(G, Bk, u, 333, 5, 3.5)
    for sd, x in (("R", bh), ("L", -bh)): rivet(G, FR(sd, x, 0, 0), 0, 333, 6, 4)
    ring_pts = octa(0, 333, 36, 25, 0.36); inn = octa(0, 333, 25, 16, 0.36)               # buckle: a ring of stones round a carved panel
    for i in range(8):
        j = (i + 1) % 8; q = [ring_pts[i], ring_pts[j], inn[j], inn[i]]
        cx = sum(p[0] for p in q) / 4; cy = sum(p[1] for p in q) / 4
        plate(G, "stone", F, [(cx + (x - cx) * 0.94, cy + (y - cy) * 0.94) for x, y in q], 0, 11, 2.0, top=0.9, seed=80 + i)
    pn = plate(G, "stone2", F, octa(0, 333, 26, 17, 0.36), 0, 6.5, 1.3, keep=True)
    pn = carve(pn, FR("F", 0, 78.5, 0), [spiral(1, 333.5, 9.5)], 2.8, 2.0); keepfin(pn, G)
    # skirt: flat flaps that hang straight down, so the belly stays behind the chest plate
    for sd, f0 in (("F", 61), ("B", -68.6)):
        M = FR(sd, 0, f0, 0)
        for sx in (-1, 1):
            q = [(sx * 46, 322), (sx * 96, 322), (sx * (HW - 12), 300), (sx * (HW - 14), 280), (sx * (HW - 42), 262), (sx * 44, 276)]
            plate(G, "stone", M, q if sx > 0 else q[::-1], 0, 8.5, 2.8, top=0.93, jit=0.6, seed=100 + sx + (5 if sd == "B" else 0))
        plate(G, "stone", M, [(-46, 324), (46, 324), (42, 272), (0, 238), (-42, 272)], 4, 13.5, 3.0, top=0.92, seed=110 + (5 if sd == "B" else 0))
    for sd, x in (("R", HW), ("L", -HW)):
        plate(G, "stone", FR(sd, x, -3, 0), [(-50, 303), (50, 303), (44, 268), (0, 252), (-44, 268)], 0, 10, 3.0, top=0.93, jit=0.6, seed=120 + (1 if sd == "R" else 0))
    moss(G, (-62 - H * 0.5, 72, 320), 14, 4, 4, 93, strands=3, slen=30, sdir=(0, 1, 0), size=(5, 8))
    moss(G, (38, 78, 322), 8, 3, 2, 94, strands=2, slen=20, sdir=(0, 1, 0), size=(4, 6))

def loft(grp, m, s, secs, bev=2.5, keep=False):
    """v7: a sculpted limb piece with ROUNDED cross-sections (superellipse, 20 points) instead of chamfered rectangles.
    secs = [(z, centre, half-width, back f, front f, chamfer), ...] from the top down (chamfer now sets how square it stays)."""
    bm = bmesh.new(); rings = []; N = 20
    for sec in secs:
        z, c, w, fb, ff, ch = sec[:6]; tf = sec[6] if len(sec) > 6 else 0.0; tx = sec[7] if len(sec) > 7 else 0.0   # v11: tilted rims
        mid = (ff + fb) / 2.0; hd = (ff - fb) / 2.0
        ex = max(2.2, 4.2 - 0.08 * ch)                       # bigger chamfer = rounder
        pts = []
        for i in range(N):
            t = 2 * math.pi * (i + 0.5) / N; ct, st = math.cos(t), math.sin(t)
            pts.append((c + w * math.copysign(abs(ct) ** (2 / ex), ct), mid + hd * math.copysign(abs(st) ** (2 / ex), st)))
        rings.append([bm.verts.new(V(s * x, f, z + tf * (f - mid) + tx * (x - c))) for x, f in pts])
    for a, b in zip(rings, rings[1:]):
        for i in range(N): bm.faces.new([a[i], a[(i + 1) % N], b[(i + 1) % N], b[i]])
    bm.faces.new(rings[0][::-1]); bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:]); bevel(bm, bev); setmat(bm, m)
    if keep: bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:]); return bm
    return fin(bm, grp)

def leg(s):
    """Sculpted like a Roblox catalog armour bundle (owner 17:18: "why cant u just do like the models from roblox catalog"):
    the leg is its own shaped part, not plates on a box: a slim thigh under the tassets, a bare knee joint with a cap,
    a greave that widens down to the boot, a foot that sticks out in front, and a clear gap between the two legs."""
    side = "Left" if s > 0 else "Right"; out = "R" if s > 0 else "L"; c = LEG_X
    def mu(pts): return [(s * u, v) for u, v in pts]
    # ---- upper leg: dark under-suit (slim), thigh guard over it ----
    G = side + "UpperLeg"
    loft(G, "suit", s, [(304, c + 2, 40, -46, 42, 11), (236, c + 1, 37, -44, 41, 11), (176, c, 34, -42, 40, 10)], 2.0)
    t = loft(G, "stone", s, [(292, c + 2, 44, -49, 49, 19, 0.28, 0.3), (282, c + 2, 47, -51, 51, 20, 0.28, 0.3), (240, c + 1, 45, -49, 50, 19, 0.1, 0.1), (204, c, 41, -46, 49, 17, -0.32), (196, c, 38, -44, 47, 16, -0.36)], 2.6, keep=True)
    t = carve(t, FR("F", s * (c + 1), 50, 0), crack(mu([(-20, 254), (2, 232), (-14, 208)]), 500 + s), 3.2, 3.0); keepfin(t, G)
    plate(G, "stone", FR("F", s * c, 40, 0), octa(0, 177, 36, 24, 0.4), 0, 24, 4.5, top=0.78, seed=210 + s)                     # knee cap
    # ---- lower leg (v9): deep shin greave like Korblox, flows straight into the sabaton, no bucket cuff ----
    G = side + "LowerLeg"
    loft(G, "suit", s, [(178, c, 34, -42, 40, 10), (120, c, 35, -44, 41, 10), (46, c, 34, -42, 40, 10)], 2.0)
    t = loft(G, "stone", s, [(166, c, 48, -51, 62, 20, 0.5), (158, c, 51, -53, 66, 21, 0.45), (146, c, 48, -50, 66, 19, 0.2), (118, c, 45, -47, 62, 18),
                            (92, c, 42, -45, 57, 17), (70, c, 40, -43, 52, 16), (58, c, 39, -42, 50, 15)], 2.6, keep=True)
    t = carve(t, FR("F", s * c, 64, 0), crack(mu([(14, 140), (-6, 116), (10, 92)]), 504 + s), 3.2, 3.0); keepfin(t, G)
    # ---- foot (v9): sabaton = heel cup + three overlapping lames down the instep + rounded toe cap, thin sole with a stone rim ----
    G = side + "Foot"; bx = s * c; cf = -2.0; kb = 50.0 / 54.0
    def ov(f0, f1, w0, w1, n=14):
        """plan-view outline: straight sides from f0, round toe at f1 (x, f)."""
        pts = [(-w0, f0), (w0, f0)]
        for i in range(n + 1):
            t = math.pi * i / n; pts.append((w1 * math.cos(t), f1 - 30 + 30 * math.sin(t) * 1.0))
        return pts
    sole = ov(-60, 104, 52, 46)
    T = FR("T", bx, cf, 0)
    plate(G, "sole", T, [(x * kb, -f) for x, f in sole][::-1], 0, 8, 2.0)                                   # dark sole
    plate(G, "stone2", T, [(x * kb * 1.04, -f * 1.01) for x, f in sole][::-1], 6, 13, 2.5)                # light stone rim lip
    def band(f0, f1, zt0, zt1, w0, w1, zb, m="stone", toe=False):
        P = []
        for f, zt, w in ((f0, zt0, w0), (f1, zt1, w1)):
            for x, z in ((1.0, zb), (1.0, zb + (zt - zb) * 0.55), (0.82, zt - 6), (0.45, zt - 1), (0.0, zt)):
                for sg in (-1, 1): P.append(V(bx + sg * x * w * kb, cf + f, z))
        if toe:
            for i in range(1, 8):
                t = math.pi * i / 8; x = math.cos(t) * w1 * 0.92; ff = f1 + math.sin(t) * 16
                for z in (zb, zb + (zt1 - zb) * 0.6): P.append(V(bx + x * kb, cf + ff, z))
        hull(G, m, P, 3.0)
    band(-58, 6, 84, 80, 50, 50, 11)                                                                     # ankle cup, covers the greave's lower end
    band(-4, 34, 78, 62, 52, 52, 11)                                                                     # lame 1 (steps out over the cup)
    band(28, 62, 64, 47, 53, 51, 11)                                                                     # lame 2
    band(56, 86, 49, 31, 51, 47, 11, toe=True)                                                           # lame 3 + rounded toe cap
    rivet(G, FR(out, bx + s * 55, cf - 22, 0), 0, 34, 6, 4.0)

def arm(s):
    """built straight down from the shoulder, then swung onto the real arm (17 deg out, 12 deg forward)."""
    side = "Left" if s > 0 else "Right"; ax = s * 188.0; af = -8.0; out = "R" if s > 0 else "L"
    n0 = {g: len(PARTS[g]) for g in (side + "UpperArm", side + "LowerArm", side + "Hand")}
    loft(side + "UpperArm", "suit", s, [(500, 188, 25, -33, 18, 9), (490, 188, 33, -42, 27, 10), (440, 188, 31, -40, 25, 10), (396, 188, 29, -38, 23, 9)], 2.0)   # slim upper arm
    loft(side + "UpperArm", "stone2", s, [(472, 188, 38, -48, 33, 15, 0.0, 0.0), (440, 188, 37, -47, 32, 15, 0.0, -0.15), (404, 188, 36, -46, 31, 14, 0.0, -0.42)], 3.0)                  # v6: upper-arm plate (no suit showing)
    G = side + "LowerArm"
    t = loft(G, "stone2", s, [(414, 188, 33, af - 36, af + 36, 15, -0.5), (398, 188, 36, af - 39, af + 39, 16, -0.38), (330, 188, 43, af - 45, af + 45, 19, 0.0, -0.12), (312, 188, 45, af - 47, af + 47, 19, 0.0, -0.2)], 3.2, keep=True)
    t = carve(t, FR("F", ax, af + 45, 0), [spiral(-s * 3, 362, 17, flip=-s, skew=0.12)], 5.0, 3.6)
    t = carve(t, FR(out, ax + s * 44, af, 0), [[(-22, 336), (22, 336)]], 4.4, 3.2)
    keepfin(t, G)
    loft(G, "stone", s, [(322, 188, 49, af - 51, af + 51, 21, 0.18, -0.25), (304, 188, 51, af - 53, af + 53, 22, 0.18, -0.25), (294, 188, 47, af - 49, af + 49, 20, 0.18, -0.25)], 3.4)   # wrist cuff, swept
    loft(G, "stone", s, [(424, 188, 38, af - 42, af + 41, 17, -0.62), (408, 188, 40, af - 43, af + 42, 17, -0.62)], 3.0)                                              # elbow guard, rises at the back
    for fo in (-24.0, 24.0): rivet(G, FR(out, ax + s * 51.5, af + fo, 0), 0, 308, 4.5, 3.2)
    # ---- v5 pauldron (both arms, mirrored): three overlapping rounded stone lames that cap the shoulder, like a catalog bundle ----
    G = side + "UpperArm"; jz = 492.0
    def cap(cu, cf_, cz, rx, ry, rz, cut, m="stone", tilt=0.0, n=14, keep=False):
        pts = []
        for i in range(n):
            a_ = 2 * math.pi * i / n
            for zz in (cut, cut * 0.55 + rz * 0.45, rz * 0.8, rz):
                k = math.sqrt(max(0.0, 1 - (zz / rz) ** 2)) if zz < rz else 0.0
                x = rx * k * math.cos(a_); y = ry * k * math.sin(a_)
                x2 = x * math.cos(tilt) - zz * math.sin(tilt); z2 = x * math.sin(tilt) + zz * math.cos(tilt)
                pts.append(V(ax + s * (cu + x2), af + cf_ + y, cz + z2))
        return hull(G, m, pts, 3.0, keep=keep)
    t = cap(6, 0, jz + 8, 68, 61, 40, -6, "stone", tilt=math.radians(-24), keep=True)                  # top lame
    t = carve(t, FR(out, ax + s * 68.0, af, 0), [spiral(0, jz + 10, 14, flip=-s if out == "L" else s)], 5.0, 3.6); keepfin(t, G)
    cap(20, 0, jz - 18, 64, 59, 30, -4, "stone2", tilt=math.radians(-40))                               # middle lame
    cap(32, 0, jz - 40, 57, 54, 23, -3, "stone", tilt=math.radians(-55))                                 # lower lame
    for fo in (-40.0, 40.0): rivet(G, FR("F" if fo > 0 else "B", ax + s * 30, af + fo * 1.55, 0), 0, jz + 6, 5.0, 3.5)
    # v11b (owner 14:32 "the crystals are floating"): sit every crystal ON the top lame. Find the lame's surface height under each base
    # (same ellipsoid + tilt as cap(6, 0, jz + 8, 68, 61, 40, tilt -24 deg)) and sink the base 9 units into the stone.
    def dome_top(xo, yo, cu=6.0, cz=jz + 8, rx=68.0, ry=61.0, rz=40.0, tilt=math.radians(-24)):
        best = None
        for i in range(0, 401):
            for zz in (rz * k / 40.0 for k in range(0, 41)):
                pass
            break
        # search the ellipsoid surface for the point whose rotated x matches xo
        for a_i in range(0, 721):
            a_ = math.pi * a_i / 720.0                      # 0..pi : polar angle from the top
            x = rx * math.sin(a_); z = rz * math.cos(a_)
            for sgn in (1, -1):
                xx = sgn * x
                k = max(0.0, 1 - (yo / ry) ** 2) ** 0.5    # shrink by the y offset
                x2 = xx * k * math.cos(tilt) - z * k * math.sin(tilt); z2 = xx * k * math.sin(tilt) + z * k * math.cos(tilt)
                if best is None or abs(x2 - (xo - cu)) < best[0] - 1e-9 or (abs(abs(x2 - (xo - cu)) - best[0]) < 0.5 and z2 > best[1]):
                    if best is None or abs(x2 - (xo - cu)) <= best[0] + 0.5: best = (abs(x2 - (xo - cu)), z2)
        return cz + best[1]
    for (bx_, by_, tx_, ty_, tz_, r_) in ((26, -6, 76, -70, 72, 15), (6, 14, 34, -38, 56, 11), (44, -34, 96, -96, 38, 10)):
        bz = dome_top(bx_, by_) - 9.0
        crystal(G, (ax + s * bx_, af + by_, bz), (ax + s * tx_, af + ty_, bz + tz_), r_)
    moss(G, (ax + s * 6, af + 12, dome_top(6, 12) - 2.0), 20, 12, 5, 95 + (1 if s > 0 else 0), strands=3, slen=22, sdir=(0, 1, 0), size=(6, 10))
    # ---- v7 hand: a real gloved hand like the catalog bundles (owner 12:35: "the roblox catalog bundle hands are different from ours")
    #      relaxed open hand, palm towards the leg, the four fingers together and slightly curled in, the thumb in front; smooth dark glove + a stone cuff
    G = side + "Hand"
    loft(G, "stone", s, [(300, 188, 44, af - 46, af + 46, 26), (284, 188, 46, af - 48, af + 48, 28), (272, 188, 42, af - 44, af + 44, 26)], 3.0)      # stone cuff
    for fo in (-22.0, 22.0): rivet(G, FR(out, ax + s * 46.5, af + fo, 0), 0, 286, 4.5, 3.2)
    palm = loft(G, "slate", s, [(276, 188, 34, af - 40, af + 39, 28), (256, 188, 33, af - 42, af + 41, 28), (234, 187, 29, af - 41, af + 39, 26)], 2.4, keep=True)
    palm = carve(palm, FR(out, ax + s * 33.5, af, 0), [spiral(0, 256, 11, flip=-s)], 3.4, 2.4)                    # small glowing rune on the back of the hand
    keepfin(palm, G)
    fing = loft(G, "slate", s, [(238, 186, 27, af - 40, af + 36, 24), (216, 183, 25, af - 39, af + 35, 22), (198, 178, 20, af - 35, af + 31, 18), (186, 173, 14, af - 28, af + 24, 13)], 2.2, keep=True)
    fing = carve(fing, FR(out, ax + s * 25.5, af, 0), [[(-18, 232), (-18, 196)], [(0, 234), (0, 192)], [(18, 232), (18, 196)]], 2.6, 2.2, dark=True)   # finger gaps
    keepfin(fing, G)
    loft(G, "slate", s, [(266, 180, 12, af + 30, af + 52, 11), (244, 177, 11, af + 33, af + 53, 10), (226, 174, 8, af + 35, af + 49, 8)], 1.8)       # thumb in front
    axis = Vector((s * 0.288, -0.202, -0.936)).normalized()
    T = Matrix.Translation(V(s * 127.5, -22.8, 470.2)) @ Vector((0, 0, -1)).rotation_difference(axis).to_matrix().to_4x4() @ Matrix.Translation(-V(ax, af, 492.0))
    T = arm_extra(s) @ T
    if os.environ.get("STONE_STRAIGHT"): T = Matrix.Identity(4)   # Roblox export: the arm stays straight down = the R15 rest pose (arm centre 1.5 studs out, top 4.0 studs up)
    for g, k in n0.items():
        for bm in PARTS[g][k:]: bm.transform(T)

def shoulders():
    """v4: nothing here any more. The two matching pauldrons are built in arm() so they move with the arms."""
    return

SUBD = int(os.environ.get("STONE_SUBD", "0"))
def smooth_round(big):
    """Catmull-Clark once over every armour piece: chamfered boxes and plates become rounded, sculpted shapes.
    Crystal and glow faces keep sharp edges (crease 1), then everything else is shaded smooth."""
    keep = {MI[k] for k in ("crystal", "glow", "groove") if k in MI}
    cr = big.edges.layers.float.get("crease_edge") or big.edges.layers.float.new("crease_edge")
    for e in big.edges:
        if any(f.material_index in keep for f in e.link_faces): e[cr] = 1.0
    tmp = bpy.data.meshes.new("_sub"); big.to_mesh(tmp); big.free()
    ob = bpy.data.objects.new("_sub", tmp); bpy.context.scene.collection.objects.link(ob)
    md = ob.modifiers.new("sub", 'SUBSURF'); md.levels = SUBD; md.render_levels = SUBD; md.quality = 3
    try: md.boundary_smooth = 'PRESERVE_CORNERS'
    except Exception: pass
    dg = bpy.context.evaluated_depsgraph_get(); ev = ob.evaluated_get(dg)
    nm = bpy.data.meshes.new_from_object(ev)
    out = bmesh.new(); out.from_mesh(nm)
    bpy.data.objects.remove(ob, do_unlink=True); bpy.data.meshes.remove(tmp); bpy.data.meshes.remove(nm)
    for f in out.faces: f.smooth = f.material_index not in keep
    return out

def build():
    global MATS
    MATS = mats()
    c = bpy.data.collections.get(COLL)
    if c:
        for o in list(c.objects):
            d = o.data; bpy.data.objects.remove(o, do_unlink=True)
            if d and d.users == 0: bpy.data.meshes.remove(d)
    else:
        c = bpy.data.collections.new(COLL); bpy.context.scene.collection.children.link(c)
    for k in list(PARTS): del PARTS[k]
    character(); body(); torso(); waist(); shoulders()
    for s in (-1, 1): leg(s); arm(s)
    tris = 0; rep = []
    for grp, bms in PARTS.items():
        me = bpy.data.meshes.new(grp); big = bmesh.new()
        for bm in bms:
            tmp = bpy.data.meshes.new("_tmp"); bm.to_mesh(tmp); big.from_mesh(tmp); bpy.data.meshes.remove(tmp); bm.free()
        if grp != "Head" and SUBD > 0:
            big = smooth_round(big)
        if grp != "Head":
            keepf = {MI[k] for k in ("crystal", "glow", "groove") if k in MI}
            for f in big.faces: f.smooth = f.material_index not in keepf
        bmesh.ops.triangulate(big, faces=[f for f in big.faces if len(f.verts) > 4])
        big.to_mesh(me); n = sum(len(f.verts) - 2 for f in big.faces); tris += n; rep.append("%s %d" % (grp, n)); big.free()
        for mm in MATS: me.materials.append(mm)
        att = me.attributes.get("cn")
        if att is not None:
            n = len(me.loops); arr = [0.0] * (n * 3); att.data.foreach_get("vector", arr); cn = []
            for p in me.polygons:
                for li in p.loop_indices:
                    v = Vector(arr[li * 3:li * 3 + 3]); cn.append(tuple(v.normalized()) if v.length > 0.1 else tuple(p.normal))
            me.attributes.remove(att)
            try: me.normals_split_custom_set(cn)
            except Exception as e: print("custom normals:", e)
        old = bpy.data.objects.get(grp)
        if old: old.name = "old_" + grp                      # an earlier version's part keeps out of the way
        o = bpy.data.objects.new(grp, me); o.scale = (S, S, S); c.objects.link(o)
    print("StoneSet v7:", len(PARTS), "parts,", tris, "triangles |", ", ".join(rep))

build()
