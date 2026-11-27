# Frost Titan ice armour (GYM ARC Christmas), built from profiles.json (analyse_sheet.py, exploded_sheet.png).
# Run in Blender: exec(open(r"<vault>/GYM ARC/Art/FrostTitanArmour/build_armour.py").read())
# 1 Blender unit = 100 sheet px. Each object's origin is its attach point. Rebuild from this script, never hand-edit.
import bpy, bmesh, json, math, os
from mathutils import Vector

HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\FrostTitanArmour"
P = json.load(open(os.path.join(HERE, "profiles.json")))
PX = 0.01

ICE = (0.62, 0.84, 0.97, 1)
DEEP = (0.24, 0.55, 0.86, 1)
GLOW = (0.25, 0.95, 1.0, 1)


def scene():
    sc = bpy.data.scenes.get("GYM ARC Armour") or bpy.data.scenes.new("GYM ARC Armour")
    bpy.context.window.scene = sc
    for ob in list(sc.collection.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    return sc


def mat(name, col, emit=0.0):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = col
    bsdf.inputs["Roughness"].default_value = 0.25
    if emit:
        bsdf.inputs["Emission Color"].default_value = col
        bsdf.inputs["Emission Strength"].default_value = emit
    return m


def obj(sc, name, verts, faces, material):
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in verts], [], faces)
    me.validate()
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = False
    o = bpy.data.objects.new(name, me)
    o.data.materials.append(material)
    sc.collection.objects.link(o)
    return o


def grid_solid(top, bot):
    """Closed solid from two grids of the same shape (rows x cols): top surface, bottom surface, side walls."""
    R, C = len(top), len(top[0])
    verts = [v for row in top for v in row] + [v for row in bot for v in row]
    off = R * C
    idx = lambda r, c, b=0: b * off + r * C + c
    faces = []
    for r in range(R - 1):
        for c in range(C - 1):
            faces.append((idx(r, c), idx(r, c + 1), idx(r + 1, c + 1), idx(r + 1, c)))
            faces.append((idx(r, c, 1), idx(r + 1, c, 1), idx(r + 1, c + 1, 1), idx(r, c + 1, 1)))
    ring = [(0, c) for c in range(C)] + [(r, C - 1) for r in range(1, R)] + \
           [(R - 1, c) for c in range(C - 2, -1, -1)] + [(r, 0) for r in range(R - 2, 0, -1)]
    for k in range(len(ring)):
        a, b = ring[k], ring[(k + 1) % len(ring)]
        faces.append((idx(*a), idx(*b), idx(*b, 1), idx(*a, 1)))
    return verts, faces


def column_profile(piece, n):
    """n samples across the piece's front silhouette: (x, top, bottom) in sheet px, x from the centre, y up."""
    cols = P[piece]["cols"]
    w = len(cols)
    good = [i for i, c in enumerate(cols) if c]
    x0, x1 = good[0], good[-1]
    out = []
    for k in range(n):
        i = round(x0 + (x1 - x0) * k / (n - 1))
        while not cols[i]:
            i += 1 if k < n / 2 else -1
        top, bot = cols[i]
        out.append(((i - (x0 + x1) / 2), -top, -bot))
    return out


def plate(sc, piece, depth_ratio, thick_px, y_off, name, mirror=False):
    """A curved roof-tile plate: the front silhouette's top edge, drooping front and back (z) so the front view
    shows top - bottom = thickness + droop. Rim = a glow strip under the outer edge loop."""
    prof = column_profile(piece, 15)
    W = prof[-1][0] - prof[0][0]
    S = [-1 + 2 * j / 8 for j in range(9)]
    top, bot = [], []
    for s in S:
        rt, rb = [], []
        for (x, yt, yb) in prof:
            u = x / (W / 2)
            dz = depth_ratio * W / 2 * math.sqrt(max(0.18, 1 - u * u))
            droop = max(0.0, (yt - yb) - thick_px)
            y = yt - droop * s * s
            sx = -x if mirror else x
            rt.append(Vector((sx, s * dz, y + y_off)) * PX)
            rb.append(Vector((sx * 0.97, s * dz * 0.9, y - thick_px + y_off)) * PX)
        top.append(rt)
        bot.append(rb)
    v, f = grid_solid(top, bot)
    shell = obj(sc, name, v, f, mat("Ice", ICE))
    # glow rim: a thin square-section strip around the bottom surface's outer loop, just outside it
    R, C = len(bot), len(bot[0])
    loop = [bot[0][c] for c in range(C)] + [bot[r][C - 1] for r in range(1, R)] + \
           [bot[R - 1][c] for c in range(C - 2, -1, -1)] + [bot[r][0] for r in range(R - 2, 0, -1)]
    cen = sum(loop, Vector()) / len(loop)
    h, o = thick_px * 0.35 * PX, thick_px * 0.18 * PX
    rv, rf = [], []
    for p in loop:
        d = (p - cen)
        d.z = 0
        d = d.normalized() if d.length else Vector((1, 0, 0))
        rv += [p + d * o, p + d * o + Vector((0, 0, h)), p - d * o * 0.2 + Vector((0, 0, h)), p - d * o * 0.2]
    L = len(loop)
    for k in range(L):
        a, b = 4 * k, 4 * ((k + 1) % L)
        for q in range(4):
            rf.append((a + q, b + q, b + (q + 1) % 4, a + (q + 1) % 4))
    obj(sc, name + "Rim", rv, rf, mat("Glow", GLOW, 3.0))
    return shell


def crown(sc):
    ct, cf = P["crown_top"], P["crown_front"]
    tw, th = ct["box"][2], ct["box"][3]
    ro = (tw + th) / 4
    # inner radius: the hole of the top view (rows through the centre: the gap between the ice spans)
    m = ct["rows"][th // 2]
    ri = ro * 0.62
    fw, fh = cf["box"][2], cf["box"][3]
    cols = cf["cols"]
    band_px = fh * 0.33
    N = 15
    verts, faces = [], []
    for k in range(N):
        a = 2 * math.pi * k / N
        for r, z in ((ro, 0), (ro, band_px), (ri, band_px), (ri, 0)):
            verts.append(Vector((r * math.sin(a), -r * math.cos(a), z)) * PX)
    for k in range(N):
        a, b = 4 * k, 4 * ((k + 1) % N)
        for q in range(4):
            faces.append((a + q, a + (q + 1) % 4, b + (q + 1) % 4, b + q))
    band = obj(sc, "IceCrown", verts, faces, mat("Ice", ICE))
    # five gems: heights read from the front silhouette at x = ro*sin(phi), phi = 0, +-72 (front), +-144 (back)
    gv, gf = [], []
    good = [i for i, c in enumerate(cols) if c]
    cx = (good[0] + good[-1]) / 2
    half = (good[-1] - good[0]) / 2
    for phi_deg in (0, 72, -72, 144, -144):
        phi = math.radians(phi_deg)
        sx = math.sin(phi)
        i = int(round(cx + sx * half * 0.92))
        lo = max(0, i - 6)
        tops = [cols[j][0] for j in range(lo, min(len(cols), i + 7)) if cols[j]]
        height = fh - min(tops)
        tip = max(height - band_px, band_px * 0.8)
        rg = ro * (0.30 if phi_deg == 0 else 0.24)
        base = Vector((ro * 0.86 * sx, -ro * 0.86 * math.cos(phi), band_px * 0.55))
        i0 = len(gv)
        gv.append((base + Vector((0, 0, tip + band_px * 0.45))) * PX)
        gv.append((base + Vector((0, 0, -band_px * 0.25))) * PX)
        for k in range(6):
            a = phi + math.pi * k / 3
            gv.append((base + Vector((rg * math.cos(a), rg * math.sin(a), band_px * 0.45))) * PX)
        for k in range(6):
            a, b = i0 + 2 + k, i0 + 2 + (k + 1) % 6
            gf.append((i0, a, b))
            gf.append((i0 + 1, b, a))
    obj(sc, "IceCrownGems", gv, gf, mat("Ice", ICE))
    rv, rf = [], []
    for k in range(N):
        a = 2 * math.pi * k / N
        for r, z in ((ro * 1.03, band_px * 0.18), (ro * 1.03, band_px * 0.36), (ro * 0.98, band_px * 0.36), (ro * 0.98, band_px * 0.18)):
            rv.append(Vector((r * math.sin(a), -r * math.cos(a), z)) * PX)
    for k in range(N):
        a, b = 4 * k, 4 * ((k + 1) % N)
        for q in range(4):
            rf.append((a + q, a + (q + 1) % 4, b + (q + 1) % 4, b + q))
    obj(sc, "IceCrownRim", rv, rf, mat("Glow", GLOW, 3.0))
    return band


def bracer(sc, name, mirror=False):
    fr, sd = P["bracer_front"], P["bracer_side"]
    H = fr["box"][3]
    N = 10
    rows = 12
    verts, faces = [], []
    centres = []
    for k in range(rows):
        t = k / (rows - 1)
        rf_ = fr["rows"][min(H - 1, int(t * (H - 1)))]
        rs_ = sd["rows"][min(len(sd["rows"]) - 1, int(t * (len(sd["rows"]) - 1)))]
        a = (rf_[1] - rf_[0]) / 2
        b = (rs_[1] - rs_[0]) / 2 * 0.85
        z = (0.5 - t) * H
        for q in range(N):
            ang = 2 * math.pi * q / N
            verts.append(Vector((a * math.cos(ang) * (-1 if mirror else 1), b * math.sin(ang), z)) * PX)
    for k in range(rows - 1):
        for q in range(N):
            a0, a1 = k * N + q, k * N + (q + 1) % N
            faces.append((a0, a1, a1 + N, a0 + N))
    faces.append(tuple(range(N - 1, -1, -1)))
    faces.append(tuple((rows - 1) * N + q for q in range(N)))
    shell = obj(sc, name, verts, faces, mat("Ice", ICE))
    # glow bands at the rows where the sheet shows the most cyan
    g = fr["glow_rows"]
    picks = sorted(range(len(g)), key=lambda r: -g[r])
    chosen = []
    for r in picks:
        if all(abs(r - c) > H * 0.2 for c in chosen):
            chosen.append(r)
        if len(chosen) == 2:
            break
    bv, bf = [], []
    for r in chosen:
        t = r / (H - 1)
        rf_ = fr["rows"][r]
        rs_ = sd["rows"][min(len(sd["rows"]) - 1, int(t * (len(sd["rows"]) - 1)))]
        a = (rf_[1] - rf_[0]) / 2 * 1.03
        b = (rs_[1] - rs_[0]) / 2 * 0.85 * 1.03
        z = (0.5 - t) * H
        i0 = len(bv)
        for q in range(N):
            ang = 2 * math.pi * q / N
            for dz, kk in ((-3, 1.0), (3, 1.0), (3, 0.95), (-3, 0.95)):
                bv.append(Vector((a * kk * math.cos(ang) * (-1 if mirror else 1), b * kk * math.sin(ang), z + dz)) * PX)
        for q in range(N):
            a0, b0 = i0 + 4 * q, i0 + 4 * ((q + 1) % N)
            for s in range(4):
                bf.append((a0 + s, b0 + s, b0 + (s + 1) % 4, a0 + (s + 1) % 4))
    obj(sc, name + "Band", bv, bf, mat("Glow", GLOW, 3.0))
    return shell


def build():
    sc = scene()
    for side, mir, x in (("L", False, -6), ("R", True, 6)):
        # nested like stacked bowls (assembled view): each lower plate tucked under the one above, stepping down and
        # out along the arm (+x outward on L, mirrored on R); y_off moves each plate down from the attach point
        out = -1 if mir else 1
        plate(sc, "plate1", 0.8, 28, 0, f"PauldronPlate1{side}", mir).location.x = x
        plate(sc, "plate2", 0.88, 24, -55, f"PauldronPlate2{side}", mir).location.x = x + out * 0.15
        plate(sc, "plate3", 0.95, 22, -100, f"PauldronPlate3{side}", mir).location.x = x + out * 0.3
        for k in (1, 2, 3):
            sc.objects[f"PauldronPlate{k}{side}Rim"].location.x = sc.objects[f"PauldronPlate{k}{side}"].location.x
        bracer(sc, f"Bracer{side}", mir).location = (x, 0, -6)
        sc.objects[f"Bracer{side}Band"].location = (x, 0, -6)
    crown(sc).location = (0, 0, 3)
    for n in ("IceCrownGems", "IceCrownRim"):
        sc.objects[n].location = (0, 0, 3)
    tris = 0
    for ob in sc.objects:
        if ob.type == "MESH":
            tris += sum(len(p.vertices) - 2 for p in ob.data.polygons)
    print("objects", len(sc.objects), "triangles", tris)


build()
