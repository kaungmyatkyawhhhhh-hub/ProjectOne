# STOMP EVOLUTION - STONE armour set, model v2 (11 Nov 2026): REAL 3D SHAPES.
# Owner (15:54): "its suppose to be 3d and not just pictures on a block ... same for the body and legs and shoulders too ... make the legs longer by 1.2x".
# v1 put the sheet picture on rounded boxes. v2 builds every form as geometry: separate stone blocks, finger columns with
# knuckle plates, carved glowing runes, layered plates, straps, rivets, crystals and moss. No sheet picture is used on the model.
# Sizes are the pixels measured on the approved sheet (1 px = 1 cm); legs are 1.2x longer (210 -> 252).
# Run in Blender: exec(open(r"<vault>\TITAN ARC\Art\Stone\stone_v2.py").read())    (rebuild from this script, never hand-edit)
import bpy, bmesh, math, random
from collections import defaultdict
from mathutils import Vector, Matrix, Euler

COLL = "StoneSet_v2"
S = 0.01
LEG = 252.0                      # leg length (sheet 210 x 1.2)
UP = LEG - 210.0                 # everything above the legs moves up by this
def ZU(y): return 650.0 - y + UP # sheet y px -> model height for the upper body

MAT_ORDER = ["stone", "stone2", "slate", "leather", "metal", "glow", "groove", "crystal", "moss", "skin", "face", "sole", "gap"]
MI = {n: i for i, n in enumerate(MAT_ORDER)}
PAL = {  # sRGB 0-255, sampled from the sheet
    "stone": (138, 108, 88), "stone2": (108, 90, 72), "slate": (58, 60, 66), "leather": (118, 58, 32), "metal": (172, 172, 178),
    "glow": (205, 255, 40), "groove": (92, 120, 22), "crystal": (96, 200, 12), "moss": (104, 122, 26), "skin": (252, 207, 2),
    "face": (22, 20, 18), "sole": (40, 42, 46), "gap": (40, 28, 24)}
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

def bevel(bm, off, seg=1):
    if off > 0: bmesh.ops.bevel(bm, geom=bm.edges[:], offset=off, segments=seg, profile=0.5, affect='EDGES')

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
def head():
    bm = bmesh.new(); bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=28, radius1=71, radius2=71, depth=144.0)
    rim = [e for e in bm.edges if abs(e.verts[0].co.z - e.verts[1].co.z) < 1e-4]
    bmesh.ops.bevel(bm, geom=rim, offset=24, segments=4, profile=0.5, affect='EDGES')
    bm.transform(Matrix.Translation(V(0, 0, ZU(132)))); setmat(bm, "skin"); fin(bm, "Head", True)
    zc = ZU(132)
    def onhead(pts):          # (x, z) outline -> wrapped on the front of the head
        bm = bmesh.new(); vs = []
        for x, z in pts:
            a = math.asin(max(-1, min(1, x / 71.0))); vs.append(bm.verts.new(V(71.6 * math.sin(a), 71.6 * math.cos(a), zc + z)))
        return bm, vs
    for sx in (-1, 1):       # eyes
        pts = [(sx * 26 + 5.5 * math.cos(2 * math.pi * i / 12), 14 + 11 * math.sin(2 * math.pi * i / 12)) for i in range(12)]
        bm, vs = onhead(pts); f = bm.faces.new(vs); f.normal_update()
        if f.normal.y > 0: f.normal_flip()
        setmat(bm, "face"); fin(bm, "Head", True, recalc=False)
    up, lo = [], []          # smile
    for i in range(13):
        t = -1 + 2 * i / 12.0; x = 40 * t; th = 5.5 * (1 - 0.55 * t * t)
        zc_ = -36 + 20 * t * t; up.append((x, zc_ + th / 2)); lo.append((x, zc_ - th / 2))
    bm, vs = onhead(up + lo[::-1]); n = 13
    for i in range(n - 1):
        f = bm.faces.new([vs[i], vs[i + 1], vs[2 * n - 2 - i], vs[2 * n - 1 - i]]); f.normal_update()
        if f.normal.y > 0: f.normal_flip()
    setmat(bm, "face"); fin(bm, "Head", True, recalc=False)

def torso():
    G = "UpperTorso"
    box(G, "slate", (0, 0, ZU(204)), (128, 118, 30), 6)                                   # neck
    t = box(G, "slate", (0, 1, 407), (222, 158, 164), 10, taper=(256 / 222.0, 1.0))        # chest (z 325..489)
    PARTS[G].remove(t)
    F = FR("F", 0, 80, 0)
    t = carve(t, F, crack([(-102, 408), (-76, 394), (-94, 366), (-66, 348)], 1) + crack([(102, 408), (76, 394), (94, 366), (66, 348)], 2), 3.6, 3.0)
    Bk = FR("B", 0, -78, 0)
    t = carve(t, Bk, crack([(-100, 430), (-94, 396), (-104, 362)], 3, 3, False) + crack([(100, 430), (94, 396), (104, 362)], 4, 3, False), 3.6, 3.0)
    keepfin(t, G)
    # --- chest armour: six stone wedges round a framed gem ---
    O = [(-66, 477), (67, 477), (102, 430), (64, 362), (-62, 362), (-100, 430)]
    I = [(-24, 458), (24, 458), (42, 420), (24, 382), (-24, 382), (-42, 420)]
    for i in range(6):
        j = (i + 1) % 6; q = [O[i], O[j], I[j], I[i]]
        cx = sum(p[0] for p in q) / 4; cy = sum(p[1] for p in q) / 4
        q = [(cx + (x - cx) * 0.965, cy + (y - cy) * 0.965) for x, y in q]
        plate(G, "stone", F, q, -2, 15 + (i % 2) * 2.5, 3.5, top=0.93, jit=0.8, seed=40 + i)
    plate(G, "slate", F, [(-40, 460), (40, 460), (44, 420), (40, 380), (-40, 380), (-44, 420)], -2, 9, 2)   # backing under the frame
    Ro = [(0, 472), (40, 450), (40, 392), (0, 368), (-40, 392), (-40, 450)]; Ri = [(0, 458), (28, 442), (28, 399), (0, 382), (-28, 399), (-28, 442)]
    for i in range(6):
        j = (i + 1) % 6; q = [Ro[i], Ro[j], Ri[j], Ri[i]]
        cx = sum(p[0] for p in q) / 4; cy = sum(p[1] for p in q) / 4
        plate(G, "stone", F, [(cx + (x - cx) * 0.95, cy + (y - cy) * 0.95) for x, y in q], 8, 24, 2.5, top=0.9, seed=50 + i)
    # the gem: a cut crystal (girdle, crown facets, table)
    bm = bmesh.new(); g = [(0, 456), (26, 441), (26, 400), (0, 384), (-26, 400), (-26, 441)]
    a = [bm.verts.new((x, y, 10)) for x, y in g]; b = [bm.verts.new((x * 0.5, 420 + (y - 420) * 0.6, 30)) for x, y in g]
    bm.faces.new(a[::-1]); bm.faces.new(b)
    for i in range(6): bm.faces.new([a[i], a[(i + 1) % 6], b[(i + 1) % 6], b[i]])
    bm.transform(F); setmat(bm, "crystal"); fin(bm, G)
    # collar slabs, lower V stones
    for sx in (-1, 1):
        q = [(sx * 14, 504), (sx * 92, 498), (sx * 106, 476), (sx * 72, 462), (sx * 26, 478)]
        plate(G, "stone", FR("F", 0, 62, 0), q if sx > 0 else q[::-1], 0, 26, 4.5, top=0.9, jit=1.2, seed=60 + sx)
        q = [(sx * 6, 360), (sx * 60, 360), (sx * 44, 340), (sx * 6, 334)]
        plate(G, "stone", F, q if sx > 0 else q[::-1], -2, 12, 3, top=0.9, seed=64 + sx)
        # leather straps with rivets
        q = [(sx * 128, 470), (sx * 108, 478), (sx * 66, 418), (sx * 84, 408)]
        plate(G, "leather", F, q if sx > 0 else q[::-1], -1, 6, 1.5)
        q = [(sx * 126, 436), (sx * 118, 448), (sx * 84, 398), (sx * 96, 388)]
        plate(G, "leather", F, q if sx > 0 else q[::-1], -1, 4.5, 1.5)
        rivet(G, FR("F", 0, 86, 0), sx * 106, 458); rivet(G, FR("F", 0, 86, 0), sx * 84, 426, 5.5, 4)
    # --- back: the rune slab, held by straps ---
    slab = plate(G, "stone", FR("B", 0, -78, 0), [(0, 537), (87, 497), (89, 362), (49, 272), (0, 222), (-49, 272), (-89, 362), (-87, 497)], 6, 36, 5, top=0.9, keep=True)
    Bs = FR("B", 0, -78 - 36, 0)
    slab = carve(slab, Bs, [[(0, 250), (0, 392)], spiral(0, 424, 30), [(0, 462), (0, 512)], [(-46, 330), (-30, 316)], [(46, 330), (30, 316)]], 6.0, 4.0)
    slab = split(slab, Bs, [[(-70, 470), (-30, 440), (-44, 392)], [(60, 480), (34, 452)], [(-60, 330), (-22, 356)], [(66, 372), (30, 392), (22, 440)], [(-26, 262), (-10, 300)]], (611, 612, 613, 614, 615))
    keepfin(slab, G)
    for sx in (-1, 1):
        q = [(sx * 76, 462), (sx * 132, 468), (sx * 132, 444), (sx * 76, 438)]
        plate(G, "leather", FR("B", 0, -78, 0), q if sx > 0 else q[::-1], -1, 12, 1.5)
        rivet(G, FR("B", 0, -90, 0), sx * 100, 453); rivet(G, FR("B", 0, -90, 0), sx * 120, 455, 5, 3.5)
    moss(G, (-30, -112, 268), 22, 6, 5, 91, strands=3, slen=34, sdir=(0, -1, 0), size=(6, 10))

def waist():
    G = "LowerTorso"
    box(G, "slate", (0, -1, 283), (214, 146, 104), 9)                                     # hips (z 231..335)
    box(G, "leather", (0, 0, 319), (236, 166, 40), 3)                                     # belt
    F = FR("F", 0, 83, 0); Bk = FR("B", 0, -83, 0)
    for u in (-64, 64): rivet(G, F, u, 319); rivet(G, Bk, u, 319)
    for u in (-98, 98): rivet(G, F, u, 319, 5, 3.5)
    for sd, x in (("R", 118), ("L", -118)): rivet(G, FR(sd, x, 0, 0), 0, 319)
    # buckle: a ring of stones round a panel with a carved rune
    ring_pts = octa(0, 319, 42, 31, 0.36); inn = octa(0, 319, 29, 20, 0.36)
    for i in range(8):
        j = (i + 1) % 8; q = [ring_pts[i], ring_pts[j], inn[j], inn[i]]
        cx = sum(p[0] for p in q) / 4; cy = sum(p[1] for p in q) / 4
        plate(G, "stone", F, [(cx + (x - cx) * 0.94, cy + (y - cy) * 0.94) for x, y in q], 0, 15, 2.2, top=0.9, seed=80 + i)
    pn = plate(G, "stone2", F, octa(0, 319, 31, 22, 0.36), 0, 9, 1.5, keep=True)
    pn = carve(pn, FR("F", 0, 92, 0), [spiral(1, 319, 11.5)], 3.2, 2.4); keepfin(pn, G)
    # skirt: side plates under a pointed centre plate, front and back; tassets on the sides
    for sd, f0 in (("F", 70), ("B", -72)):
        M = FR(sd, 0, f0, 300) @ Matrix.Rotation(math.radians(-7), 4, 'X') @ Matrix.Translation((0, -300, 0))
        for sx in (-1, 1):
            q = [(sx * 52, 302), (sx * 134, 302), (sx * 132, 262), (sx * 84, 244), (sx * 46, 262)]
            plate(G, "stone", M, q if sx > 0 else q[::-1], 0, 13, 3.2, top=0.93, jit=0.8, seed=100 + sx + (5 if sd == "B" else 0), chips=1)
        cp = plate(G, "stone", M, [(-56, 306), (56, 306), (52, 262), (0, 222), (-52, 262)], 9, 24, 3.5, top=0.92, seed=110 + (5 if sd == "B" else 0), keep=True)
        keepfin(cp, G)
    for sd, x in (("R", 110), ("L", -110)):
        M = FR(sd, x, 0, 300) @ Matrix.Rotation(math.radians(-6), 4, 'X') @ Matrix.Translation((0, -300, 0))
        plate(G, "stone", M, [(-52, 302), (52, 302), (46, 256), (0, 240), (-46, 256)], 0, 13, 3.2, top=0.93, jit=0.8, seed=120 + (1 if sd == "R" else 0))
    moss(G, (-70, 84, 298), 16, 5, 4, 93, strands=3, slen=40, sdir=(0, 1, 0), size=(5, 9))
    moss(G, (40, 96, 300), 9, 4, 2, 94, strands=2, slen=26, sdir=(0, 1, 0), size=(4, 7))

def leg(s):
    side = "Left" if s > 0 else "Right"; cx = s * 72.0; cf = -20.0; out = "R" if s > 0 else "L"
    # upper leg (z 150..266) with glowing cracks
    t = box(side + "UpperLeg", "slate", (cx, cf, 208), (104, 100, 118), 8); PARTS[side + "UpperLeg"].remove(t)
    t = carve(t, FR("F", cx, cf + 50, 0), crack([(-s * 26, 256), (-s * 4, 232), (-s * 22, 210)], 500 + s), 3.2, 3.0)
    t = carve(t, FR("B", cx, cf - 50, 0), crack([(s * 10, 256), (s * 28, 226), (s * 8, 196)], 502 + s), 3.2, 3.0)
    keepfin(t, side + "UpperLeg")
    ring(side + "UpperLeg", "stone2", cx, cf, 160, 188, 58, 56, 7, 10, (0, 1, 2, 1), 200 + s, bev=2.2, jit=1.0)      # knee strap
    kp = plate(side + "UpperLeg", "stone", FR("F", cx, cf + 54, 0), octa(0, 174, 63, 33, 0.38), 0, 17, 4.5, top=0.86, seed=210 + s, keep=True)   # knee plate
    keepfin(kp, side + "UpperLeg")
    # lower leg (z 40..152)
    t = box(side + "LowerLeg", "slate", (cx, cf, 96), (102, 98, 114), 8); PARTS[side + "LowerLeg"].remove(t)
    t = carve(t, FR("F", cx, cf + 49, 0), crack([(s * 22, 146), (s * 2, 124), (s * 18, 98)], 504 + s), 3.2, 3.0)
    t = carve(t, FR(out, cx + s * 51, cf, 0), crack([(-14, 144), (8, 120), (-10, 94)], 506 + s), 3.2, 3.0)
    t = carve(t, FR("B", cx, cf - 49, 0), crack([(-s * 20, 142), (s * 2, 118), (-s * 16, 94)], 508 + s), 3.2, 3.0)
    keepfin(t, side + "LowerLeg")
    ring(side + "LowerLeg", "stone", cx, cf + 2, 52, 86, 65, 62, 13, 12, (2, 2, 2, 2), 220 + s, bev=3.2)               # boot cuff
    # boot
    G = side + "Foot"
    sole = [(-60, -86), (60, -86), (64, -70), (64, 78), (48, 100), (-48, 100), (-64, 78), (-64, -70)]              # (x, f) from above
    T = FR("T", cx, cf + 8, 0)
    plate(G, "sole", T, [(x * 1.035, -f * 1.03) for x, f in sole][::-1], 0, 12.5, 2.5)
    plate(G, "glow", T, [(x, -f) for x, f in sole][::-1], 11, 17.5, 0.0)
    box(G, "stone", (cx, cf - 22, 40), (124, 116, 46), 8, jit=1.2, seed=230 + s, chips=1, chipamt=14)               # heel block
    pts = []
    for (x, f, z) in ((-61, -6, 17), (61, -6, 17), (63, 70, 17), (50, 94, 17), (30, 101, 17), (-30, 101, 17), (-50, 94, 17), (-63, 70, 17),
                      (-56, -6, 60), (56, -6, 60), (-54, 30, 63), (54, 30, 63), (-58, 62, 44), (58, 62, 44), (-46, 88, 36), (46, 88, 36), (-26, 96, 34), (26, 96, 34),
                      (-34, 56, 60), (34, 56, 60), (-24, 80, 50), (24, 80, 50), (0, 34, 66), (0, 66, 60)):
        pts.append(V(cx + x, cf + 8 + f, z))
    hull(G, "stone", pts, 3.0)                                                                                      # faceted toe cap
    box(G, "stone", (cx, cf + 30, 62), (138, 40, 17), 4, rot=(-22, 0, 0), jit=1.0, seed=240 + s)                     # instep strap
    for sd, x in (("R", cx + 62), ("L", cx - 62)):
        q = [(-30, 24), (26, 44), (26, 72), (-30, 54)] if sd == "L" else [(30, 24), (30, 54), (-26, 72), (-26, 44)]
        plate(G, "stone", FR(sd, x, cf + 10, 0), q, 0, 11, 3.0, top=0.9, seed=250)
        rivet(G, FR(sd, x + (10 if sd == "R" else -10), cf + 10, 0), (-16 if sd == "L" else 16), 42, 8.5, 5.5)

def arm(s):
    side = "Left" if s > 0 else "Right"; ax = s * 188.0; af = -8.0; out = "R" if s > 0 else "L"; inn = "L" if s > 0 else "R"
    box(side + "UpperArm", "slate", (ax - s * 2, af, 432), (90, 108, 96), 9)
    # ---- forearm: cracked stone core with carved runes, between two bands of stone blocks ----
    G = side + "LowerArm"
    t = box(G, "stone2", (ax, af, 346), (110, 122, 116), 9, jit=1.0, seed=300 + s); PARTS[G].remove(t)
    t = carve(t, FR("F", ax, af + 61, 0), [spiral(-s * 4, 351, 31, flip=-s, skew=0.16), [(-45, 326.2), (45, 326.2)]], 6.5, 4.0)
    t = carve(t, FR(out, ax + s * 55, af, 0), [spiral(-4, 351, 31, flip=1, skew=0.16), [(-51, 326.2), (51, 326.2)]], 6.5, 4.0)
    t = carve(t, FR("B", ax, af - 61, 0), [[(-45, 326.2), (45, 326.2)]] + crack([(-s * 30, 374), (-s * 8, 352), (-s * 24, 329)], 510 + s, 4, False), 6.0, 4.0)
    keepfin(t, G)
    ring(G, "stone", ax, af, 384, 414, 64, 71, 12, 13, (2, 2, 2, 2), 310 + s, bev=3.2)        # top band
    ring(G, "stone", ax, af, 286, 318, 69, 76, 15, 15, (3, 2, 3, 2), 320 + s, bev=3.6)        # bottom band (bigger)
    # ---- fist: palm, thumb, finger columns with glowing knuckle plates ----
    G = side + "Hand"; fz = 250.0; ff = af + 8
    box(G, "slate", (ax, ff, fz + 6), (112, 106, 70), 10)                                      # palm
    box(G, "slate", (ax, ff, 288), (88, 84, 22), 5)                                            # wrist
    box(G, "slate", (ax - s * 58, ff + 8, 246), (24, 60, 50), 7, rot=(0, 0, s * 4))            # thumb on the inner side
    for sd, x, f, n, pitch in (("F", ax, ff + 53, 3, 38.5), (out, ax + s * 56, ff, 3, 36.5), ("B", ax, ff - 53, 3, 38.5)):
        for k in range(n):
            u = (k - (n - 1) / 2.0) * pitch; wd = pitch - 4.5
            M = FR(sd, x, f, fz) @ Matrix.Translation((u, 0, 0))
            plate(G, "stone2", M @ Matrix.Rotation(math.radians(-8), 4, 'X'), [(-wd / 2, 13), (wd / 2, 13), (wd / 2, 38), (-wd / 2, 38)], -4, 11, 3.2, top=0.9, seed=330 + k)    # first joint (stone)
            plate(G, "slate", M, [(-wd / 2, -24), (wd / 2, -24), (wd / 2, 12), (-wd / 2, 12)], -4, 14, 3.2)                                                                   # second joint (frame)
            plate(G, "glow", M, [(-wd / 2 + 4.5, -19.5), (wd / 2 - 4.5, -19.5), (wd / 2 - 4.5, 7.5), (-wd / 2 + 4.5, 7.5)], 13, 18.5, 0, top=0.7)                           # knuckle plate (cut gem)
            plate(G, "slate", M @ Matrix.Translation((0, -24, 0)) @ Matrix.Rotation(math.radians(24), 4, 'X') @ Matrix.Translation((0, 24, 0)), [(-wd / 2 + 1, -45), (wd / 2 - 1, -45), (wd / 2, -25), (-wd / 2, -25)], -9, 11, 3.2, top=0.88)   # finger tip curling under

def shoulders():
    G = "UpperTorso"
    # ---- right shoulder (viewer's left): a boulder of fitted stones with a carved rune, crystals and moss on top ----
    cx, cf, cz = -177.0, -22.0, 487.0
    def rk(pts, bev=3.5, keep=False, m="stone", **kw): return hull(G, m, [V(cx + x, cf + f, cz + z) for x, f, z in pts], bev, keep, **kw)
    main = rk([(-44, -50, 72), (46, -58, 78), (62, 38, 72), (-36, 54, 62), (-68, 0, 70), (20, 60, 66),
               (-87, -66, 36), (80, -78, 40), (92, 56, 34), (-87, 58, 26), (-60, 82, 30), (74, 82, 38), (90, 70, 20),
               (-87, -70, -28), (84, -80, -24), (90, 60, -30), (-87, 56, -38), (-72, 82, -32), (70, 82, -36),
               (-56, -52, -74), (52, -58, -68), (60, 46, -77), (-52, 48, -77)], 3.5, keep=True,
              cuts=[(V(cx - 62, cf + 58, cz + 52), (-0.55, -0.5, 0.7)), (V(cx + 66, cf - 62, cz + 58), (0.5, 0.65, 0.6)), (V(cx + 74, cf + 66, cz - 46), (0.55, -0.4, -0.75)),
                    (V(cx - 70, cf - 60, cz - 50), (-0.6, 0.5, -0.65))])
    Mf = FR("F", cx, cf + 82, cz)
    main = carve(main, Mf, [[(-62, -22), (-42, -22), (-28, -6), (-12, -6), (-4, -17.6)] + spiral(10, 4, 27)[::-1]], 7.0, 4.5)
    main = split(main, Mf, [[(-64, 30), (-44, 8), (-56, -4)], [(-14, 34), (-8, 16)], [(50, 32), (58, -30)], [(-20, -24), (-8, -32)]], (601, 602, 603, 606))
    Ml = FR("L", cx - 87, cf, cz)
    main = carve(main, Ml, [[(-50, -14), (-26, -14), (-12, 8), (14, 8), (28, -8), (46, -8)]], 6.5, 4.2)
    main = split(main, Ml, [[(-20, 30), (-34, 0), (-22, -30)], [(30, 28), (20, 10)]], (604, 605))
    keepfin(main, G)
    rk([(-34, -34, 68), (40, -38, 72), (44, 26, 70), (-30, 34, 64), (-24, -24, 90), (28, -28, 94), (30, 18, 90), (-20, 24, 86)], 3)        # cap stone under the crystals
    box(G, "stone", (cx + 60, cf + 44, cz - 60), (60, 62, 38), 5, jit=3.0, seed=401, rot=(5, -9, 7), chips=2)                            # lower chunks
    box(G, "stone", (cx - 56, cf - 34, cz - 64), (56, 74, 32), 5, jit=3.0, seed=402, rot=(-6, 7, -9), chips=2)
    box(G, "stone", (cx + 50, cf - 50, cz - 56), (50, 50, 30), 5, jit=3.0, seed=403, rot=(8, 5, 12), chips=2)
    crystal(G, (cx + 2, cf - 4, cz + 78), (cx - 2, cf + 4, cz + 186), 30, lean=0.25)
    crystal(G, (cx + 40, cf + 6, cz + 76), (cx + 54, cf + 14, cz + 136), 18, lean=0.2)
    crystal(G, (cx - 36, cf + 14, cz + 72), (cx - 52, cf + 26, cz + 118), 16, lean=-0.2)
    crystal(G, (cx + 18, cf - 36, cz + 76), (cx + 26, cf - 54, cz + 122), 13, lean=0.2)
    crystal(G, (cx - 30, cf - 30, cz + 74), (cx - 44, cf - 46, cz + 106), 11)
    moss(G, (cx + 28, cf + 50, cz + 70), 50, 24, 18, 95, strands=7, slen=46, sdir=(0, 1, 0), size=(10, 17))
    moss(G, (cx + 66, cf - 2, cz + 70), 20, 44, 10, 96, strands=4, slen=38, sdir=(1, 0, 0), size=(9, 15))
    shard(G, (cx - 74, cf - 82, cz + 108), 17, 24, 11); shard(G, (cx - 102, cf - 108, cz + 52), 13, 18, 12)
    # ---- left shoulder (viewer's right): layered slabs, tilted, with moss ----
    cx, cf, cz = 160.0, -5.0, 482.0
    T = Matrix.Translation(V(cx, cf, cz)) @ Euler((0, math.radians(13), 0)).to_matrix().to_4x4()
    def sl(pts, bev=5):
        bm = hull(G, "stone", [T @ Vector((x, -f, z)) for x, f, z in pts], bev)
    sl([(-70, -64, 14), (66, -60, 10), (74, 62, 12), (-66, 68, 16), (-76, -70, -16), (74, -68, -22), (80, 70, -20), (-74, 72, -14), (-60, -56, -38), (62, -54, -40), (64, 56, -40), (-58, 58, -36)], 6)
    sl([(-50, -44, 34), (40, -40, 30), (46, 46, 32), (-44, 50, 36), (-58, -52, 12), (50, -50, 8), (56, 54, 10), (-52, 56, 14)], 4.5)
    sl([(52, -30, 6), (86, -26, -8), (88, 30, -8), (54, 34, 6), (56, -28, -30), (84, -24, -34), (84, 28, -34), (56, 30, -30)], 4)
    moss(G, (cx - 6, cf + 30, cz + 40), 40, 22, 13, 97, strands=5, slen=34, sdir=(0, 1, 0), size=(9, 15))
    moss(G, (cx + 34, cf - 6, cz + 26), 16, 30, 6, 98, strands=3, slen=28, sdir=(1, 0, 0), size=(8, 12))

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
    head(); torso(); waist(); shoulders()
    for s in (-1, 1): leg(s); arm(s)
    tris = 0
    for grp, bms in PARTS.items():
        me = bpy.data.meshes.new(grp); big = bmesh.new()
        for bm in bms:
            tmp = bpy.data.meshes.new("_tmp"); bm.to_mesh(tmp); big.from_mesh(tmp); bpy.data.meshes.remove(tmp); bm.free()
        bmesh.ops.triangulate(big, faces=[f for f in big.faces if len(f.verts) > 4])
        big.to_mesh(me); tris += sum(len(f.verts) - 2 for f in big.faces); big.free()
        for mm in MATS: me.materials.append(mm)
        o = bpy.data.objects.new(grp, me); o.scale = (S, S, S); c.objects.link(o)
    print("StoneSet v2:", len(PARTS), "body parts,", tris, "triangles")
    for o in c.objects: print("   %-14s %5d tris" % (o.name, sum(len(p.vertices) - 2 for p in o.data.polygons)))

build()
