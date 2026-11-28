# GYM ARC Christmas landmark tree, built from profiles.json (analyse_sheet.py, turnaround_sheet.png + exploded_sheet.png).
# Run in Blender: exec(open(r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\XmasTree\build_tree.py").read())
# 1 Blender unit = 1 Roblox stud. Origin = trunk centre on the ground. One object per colour = one MeshPart each.
import bpy, bmesh, json, math, os
from mathutils import Vector

HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\XmasTree"
P = json.load(open(os.path.join(HERE, "profiles.json")))
GROUND = 559                       # sheet y of the fur rim bottom
S = 30.68 / (GROUND - 11)          # studs per px: star top (y 11) to ground = old tree height 30.68
Z = lambda y: (GROUND - y) * S

# tiers measured from the side profile: (y_top, r_top, y_bottom, r_bottom) in px
TIERS = [(118, 40, 166, 72), (169, 54, 250, 103), (253, 86, 339, 139), (341, 107, 439, 181), (441, 155, 500, 190)]
SEG = 10                           # LOW-POLY (28 Nov): 5 jagged points per tier edge = 10 rim verts

COL = {"Foliage": (0.13, 0.42, 0.12, 1), "FoliageTop": (0.33, 0.66, 0.2, 1), "Trunk": (0.45, 0.26, 0.1, 1),
       "Skirt": (0.78, 0.09, 0.08, 1), "Fur": (0.96, 0.96, 0.94, 1), "Star": (0.98, 0.78, 0.15, 1),
       "BaubleRed": (0.9, 0.15, 0.07, 1), "BaubleGold": (0.96, 0.72, 0.12, 1), "BaubleSilver": (0.75, 0.8, 0.82, 1),
       "Bulbs": (1.0, 0.94, 0.75, 1), "Wire": (0.93, 0.88, 0.65, 1)}


def scene():
    if not bpy.context.window:                 # headless (blender -b): build in the one scene; a 2nd scene crashes the glTF export
        bpy.context.scene.name = "GYM ARC Xmas"
    sc = bpy.data.scenes.get("GYM ARC Xmas") or bpy.data.scenes.new("GYM ARC Xmas")
    if bpy.context.window: bpy.context.window.scene = sc
    for ob in list(sc.collection.objects):
        if ob.get("xmas_part") == "tree":
            bpy.data.objects.remove(ob, do_unlink=True)
    return sc


def mat(name):
    m = bpy.data.materials.get("XT_" + name) or bpy.data.materials.new("XT_" + name)
    m.use_nodes = True
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = COL[name]
    bsdf.inputs["Roughness"].default_value = 0.6
    if name in ("Bulbs", "Star"):
        bsdf.inputs["Emission Color"].default_value = COL[name]
        bsdf.inputs["Emission Strength"].default_value = 1.5 if name == "Bulbs" else 0.3
    m.diffuse_color = COL[name]
    return m


class Acc:
    """Collects verts/faces for one colour object."""
    def __init__(s): s.v, s.f = [], []
    def add(s, verts, faces):
        o = len(s.v); s.v += [tuple(v) for v in verts]; s.f += [tuple(i + o for i in fc) for fc in faces]


def make(sc, name, acc):
    me = bpy.data.meshes.new("XT_" + name)
    me.from_pydata(acc.v, [], acc.f)
    me.validate()
    bm = bmesh.new(); bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    for p in me.polygons: p.use_smooth = False
    o = bpy.data.objects.new(name, me); o["xmas_part"] = "tree"
    o.data.materials.append(mat(name)); sc.collection.objects.link(o)
    return o


def ico(acc, c, r, sub=1):
    bm = bmesh.new(); bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=r)
    acc.add([v.co + Vector(c) for v in bm.verts], [[v.index for v in f.verts] for f in bm.faces]); bm.free()


def ring(r, z, n=SEG, rot=0.0):
    return [Vector((r * math.cos(rot + 2 * math.pi * i / n), r * math.sin(rot + 2 * math.pi * i / n), z)) for i in range(n)]


def build():
    sc = scene()
    fol, top, misc = Acc(), Acc(), {k: Acc() for k in COL}
    tips = []                                   # (position, tier index) of each jagged tip, for baubles
    for t, (yt, rt, yb, rb) in enumerate(TIERS):
        rot = (t % 2) * math.pi / SEG           # stagger the points tier to tier
        if t: yt, rt = yt - 16, rt * 0.86       # top tucked up inside the tier above (no see-through gap)
        zt, zb = Z(yt), Z(yb)
        zm = zt + (zb - zt) * 0.55              # light-green cap ends here
        rm = rt + (rb - rt) * 0.55
        A = ring(rt * S, zt, rot=rot)           # top ring
        M = ring(rm * S, zm, rot=rot)           # cap edge
        E = []                                  # jagged rim: tips out and down, valleys in and up
        for i in range(SEG):
            tip = i % 2 == 0
            r = rb * S * (1.0 if tip else 0.86)
            z = zb - (0.6 if tip else -0.2)
            a = rot + 2 * math.pi * i / SEG
            E.append(Vector((r * math.cos(a), r * math.sin(a), z)))
            if tip:                              # bauble seat: on the dark band, 75% down the tier, at the tip's angle
                f = 0.78
                rr, zz = (rt + (rb - rt) * f) * S, zt + (zb - zt) * f
                tips.append((Vector((rr * math.cos(a), rr * math.sin(a), zz)), t))
        U = ring(rt * S * 0.75, zb + 0.15, rot=rot)  # underside back to the core
        cz = Vector((0, 0, zt + 0.05))
        # light cap: top disc + sloped band A->M
        top.add([cz] + A, [(0, 1 + (i + 1) % SEG, 1 + i) for i in range(SEG)])
        top.add(A + M, [(i, (i + 1) % SEG, SEG + (i + 1) % SEG, SEG + i) for i in range(SEG)])
        # dark band M->E, underside E->U, U closed
        fol.add(M + E, [(i, (i + 1) % SEG, SEG + (i + 1) % SEG, SEG + i) for i in range(SEG)])
        fol.add(E + U, [(i, (i + 1) % SEG, SEG + (i + 1) % SEG, SEG + i) for i in range(SEG)])
        cm = Vector((0, 0, zm))                 # hidden disc at the colour seam so both pieces are watertight
        top.add([cm] + M, [(0, 1 + i, 1 + (i + 1) % SEG) for i in range(SEG)])
        fol.add([cm] + M, [(0, 1 + (i + 1) % SEG, 1 + i) for i in range(SEG)])
        cu = Vector((0, 0, zb + 0.15))
        fol.add([cu] + U, [(0, 1 + i, 1 + (i + 1) % SEG) for i in range(SEG)])
    # trunk: short octagonal post from the ground to inside tier 5
    tr = 40 * S
    B, T = ring(tr, 0, 8), ring(tr, Z(470), 8)
    misc["Trunk"].add(B + T, [(i, (i + 1) % 8, 8 + (i + 1) % 8, 8 + i) for i in range(8)] + [tuple(range(7, -1, -1)), tuple(range(8, 16))])
    # skirt: thin 24-gon disc, red; fur: ring tube round its edge
    rs = 170 * S
    D0, D1 = ring(rs, 0.05, 12), ring(rs * 0.97, 0.35, 12)
    misc["Skirt"].add(D0 + D1, [(i, (i + 1) % 12, 12 + (i + 1) % 12, 12 + i) for i in range(12)] + [tuple(range(11, -1, -1)), tuple(range(12, 24))])
    fr, tube = 182 * S, 0.55
    V, F = [], []
    for i in range(12):
        a = 2 * math.pi * i / 12
        bump = 1.0 + 0.18 * (i % 2)            # scalloped fluffy rim
        for j in range(4):
            b = 2 * math.pi * j / 4
            rr = fr + tube * bump * math.cos(b)
            V.append(Vector((rr * math.cos(a), rr * math.sin(a), tube * bump * (1 + math.sin(b)) * 0.8)))
    for i in range(12):
        for j in range(4):
            F.append((i * 4 + j, i * 4 + (j + 1) % 4, ((i + 1) % 12) * 4 + (j + 1) % 4, ((i + 1) % 12) * 4 + j))
    misc["Fur"].add(V, F)
    # star: chunky bevelled 5-point star facing +/-Y (front), centre at the sheet's star centre
    sc_z, R_out, R_in, depth = Z(69), 59 * S, 34 * S, 0.95
    pts = []
    for i in range(10):
        a = math.pi / 2 + i * math.pi / 5
        r = R_out if i % 2 == 0 else R_in
        pts.append(Vector((r * math.cos(a), 0, sc_z + r * math.sin(a))))
    front, back = Vector((0, -depth, sc_z)), Vector((0, depth, sc_z))
    misc["Star"].add([front, back] + pts, [(0, 2 + i, 2 + (i + 1) % 10) for i in range(10)] + [(1, 2 + (i + 1) % 10, 2 + i) for i in range(10)])
    # baubles on the jagged tips of tiers 2-5 (every other tip), colours cycling; 1 on each tip of tier 1 alternately
    kinds = ["BaubleRed", "BaubleGold", "BaubleSilver"]
    k = 0
    for n, (p, t) in enumerate(tips):
        d = Vector((p.x, p.y, 0)).normalized()
        c = p - d * 0.15
        ico(misc[kinds[k % 3]], c, 0.85, sub=0); k += 1   # faceted 20-tri bauble
        cap = Vector(c) + Vector((0, 0, 0.72))
        ico(misc["BaubleGold"], cap, 0.24, sub=0)
    # bulb string: 4 turns spiralling down the cone surface, bulbs every ~1.6 studs
    z0, z1 = Z(140), Z(490)
    def surf_r(z):
        y = GROUND - z / S
        for (yt, rt, yb, rb) in TIERS:
            if yt <= y <= yb: return (rt + (rb - rt) * (y - yt) / (yb - yt)) * S + 0.15
        return 60 * S
    path = []
    N = 48                                      # low-poly wire: 12 segments per turn
    for i in range(N + 1):
        f = i / N
        z = z0 + (z1 - z0) * f
        a = f * 4 * 2 * math.pi
        r = surf_r(z)
        path.append(Vector((r * math.cos(a), r * math.sin(a), z)))
    # wire: thin square tube along the path
    w = 0.06
    V, F = [], []
    for i, p in enumerate(path):
        tdir = (path[min(i + 1, N)] - path[max(i - 1, 0)]).normalized()
        nrm = Vector((p.x, p.y, 0)).normalized(); bi = tdir.cross(nrm).normalized()
        for q in (nrm * w * 1.5, -nrm * w + bi * w * 1.3, -nrm * w - bi * w * 1.3):
            V.append(p + q)
    for i in range(N):
        for j in range(3):
            F.append((i * 3 + j, i * 3 + (j + 1) % 3, (i + 1) * 3 + (j + 1) % 3, (i + 1) * 3 + j))
    F += [(2, 1, 0), (N * 3, N * 3 + 1, N * 3 + 2)]
    misc["Wire"].add(V, F)
    acc_len, last = 0.0, None
    for p in path:
        if last is not None: acc_len += (p - last).length
        last = p
        if acc_len >= 2.4:
            acc_len = 0.0
            ico(misc["Bulbs"], p + Vector((p.x, p.y, 0)).normalized() * 0.12, 0.26, sub=0)
    objs = [make(sc, "Foliage", fol), make(sc, "FoliageTop", top)] + [make(sc, k, a) for k, a in misc.items() if a.v and k not in ("Foliage", "FoliageTop")]
    tot = 0
    for o in objs:
        n = sum(len(p.vertices) - 2 for p in o.data.polygons); tot += n
        print(o.name, n, "tris")
    print("TOTAL", tot)
    return objs


build()
