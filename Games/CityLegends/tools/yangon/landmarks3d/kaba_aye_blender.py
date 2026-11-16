# Kaba Aye Pagoda (Yangon) - true-scale low-poly model, built in the owner's Blender (3.6) by the Blender MCP.
# Run inside Blender:  exec(open(r"D:/ObsidianOne/Claude+Obsidian/Games/CityLegends/tools/yangon/landmarks3d/kaba_aye_blender.py").read()); build()
# Then export():  writes imports/sync/landmarks/kaba_aye.glb at 1 m = 3 studs (pivot = base centre, ground = 0).
#
# Units: metres in Blender (+Z up, +Y north, +X east). Everything lives in the collection "KabaAye"; nothing else is touched.
# One Empty per labelled part of the exploded sheet (kaba_aye_exploded_v1.png), its children one mesh per material.
# Repeated pieces (merlons, arcade bays, Buddha figures, windows, porches) are linked copies of ONE mesh each.
#
# Real sizes and their sources (vault note City Legends/2026-11-16 Kaba Aye 3D model.md):
#   height 34 m to the vane tip (Wikipedia: 111 ft), bell base 10 m across (Wikipedia 111 ft round = 10.8 m; Esri + photo ~9.5 m),
#   merlon ring 25.6 m across (Esri z19: 24.6 m red disc), arcade ring 35 m (Esri z19), 5 porches at bearings 43, 115, 187,
#   259, 331 deg (Esri walkway spokes), 4 arches between porches = 20 and one window per bay join = 15 (photo 2), 88 merlons.
#   Heights from photo 2 with a fitted camera (kaba_aye_camera_fit.py). Owner rule: no flicker / overlap -> check_overlaps().
import bpy, bmesh, math, json, os, sys
from mathutils import Vector, Matrix
_KIT_DIR = r"D:/ObsidianOne/Claude+Obsidian/Games/CityLegends/tools/yangon/landmarks3d"
if _KIT_DIR not in sys.path:
    sys.path.insert(0, _KIT_DIR)
import importlib
import ornament_kit as OK  # noqa: E402  (2026-11-16: the carved-gold ornament kit, real relief instead of flat plates)
importlib.reload(OK)

VAULT = r"D:/ObsidianOne/Claude+Obsidian"
GLB = VAULT + "/Games/CityLegends/imports/sync/landmarks/kaba_aye.glb"
COLL = "KabaAye"
SPM = 3.0  # studs per metre (the game's scale)

# --- materials: flat colours measured from the midday photos (Kaba_Aye_Paya_2.jpg 13:03) + Esri for the roof terrace.
# name prefix = the game's MaterialVariant group (YgnGoldLeaf / YgnGoldPlate / YgnRenderPainted / YgnPaint ...).
MATS = {
    "YgnGoldLeaf_Bell":        ((226, 190, 124), 0.55, 0.35),  # bell, lotus bands, bud, mouldings (lit 247,232,183 / shade 172,146,102)
    "YgnGoldPlate_Trim":       ((212, 170, 98), 0.55, 0.40),   # merlons, porch crest, cornice, frieze, hti, walkway fringe
    "YgnRenderPainted_White":  ((238, 238, 230), 0.0, 0.85),   # drum wall (really white: photo 237,237,229), hood edges, posts
    "YgnRenderPainted_Cream":  ((238, 228, 168), 0.0, 0.80),   # arcade walls + carved panels: cream-yellow (photo 237,226,174 lit)
    "YgnRenderPainted_Mint":   ((188, 208, 168), 0.0, 0.80),   # pale green outlines of the carved panels (photo)
    "YgnPaint_Red":            ((165, 52, 44), 0.0, 0.70),     # arch hoods, pilaster bands, frieze drops, crest field
    "YgnPaint_Maroon":         ((96, 34, 30), 0.0, 0.70),      # porch name panel (photo 69-78, 30, 28 in its shade), left plain
    "YgnPaint_RoofRed":        ((178, 112, 92), 0.0, 0.85),    # roof terrace + porch roofs (Esri: terracotta disc)
    "YgnPaint_DarkHall":       ((46, 36, 30), 0.0, 0.95),      # the dark hall seen through each porch (closed recess)
    "YgnGlassMosaic_Teal":     ((152, 178, 160), 0.30, 0.30),  # porch pillars, arch niches (mirror mosaic)
    "YgnMarbleWhite_Base":     ((232, 230, 222), 0.0, 0.60),   # stepped base
    "YgnConcreteBare_Roof":    ((150, 148, 142), 0.0, 0.90),   # arcade roof ring (hidden behind the panels)
    "YgnSteelPainted_Grille":  ((72, 74, 78), 0.3, 0.60),      # small grille windows
    "YgnSteelPainted_Red":     ((176, 52, 42), 0.3, 0.55),     # terrace stair and rails
    "YgnCorrugatedZinc_Green": ((92, 150, 146), 0.2, 0.60),    # covered walkway roofs (photo: teal)
}

PORCH_BEARINGS = [33.0, 112.0, 191.0, 261.0, 322.0]  # deg from north, clockwise: Esri z19 walkway spokes (79, 79, 70, 61, 71 apart)
PORCH_HALF = 10.87     # deg of the arcade ring a porch takes (6.6 m body at r 17.5, photo)
R_ARC = 17.5           # arcade facade radius
R_DRUM = 12.3          # drum wall radius
N_MERLON = 88
K_BELL = 1.0           # (kept for scale tests) bell base 10.0 m across: photo + Esri ~9-10 m, Wikipedia 111 ft round (10.8 m)
K_SPIRE = 1.0          # lotus bands and bud follow the slimmer bell


def scale_xy(meshes, k):
    for mb in meshes.values():
        mb.v = [(x * k, y * k, z) for x, y, z in mb.v]
    return meshes


def srgb_lin(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def get_mat(name):
    m = bpy.data.materials.get(name)
    if m is None:
        m = bpy.data.materials.new(name)
    rgb, metal, rough = MATS[name]
    m.use_nodes = True
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    col = (srgb_lin(rgb[0]), srgb_lin(rgb[1]), srgb_lin(rgb[2]), 1.0)
    bsdf.inputs["Base Color"].default_value = col
    bsdf.inputs["Metallic"].default_value = metal
    bsdf.inputs["Roughness"].default_value = rough
    m.diffuse_color = col
    m.use_backface_culling = True
    return m


class MB:
    """Mesh builder: verts + faces, flat faces wound to a wanted normal."""
    def __init__(s):
        s.v, s.f = [], []

    def vid(s, p):
        s.v.append((float(p[0]), float(p[1]), float(p[2])))
        return len(s.v) - 1

    def P(s, pts, want=None):
        pts = [tuple(p) for p in pts]
        if want is not None:
            n = Vector((0, 0, 0))
            for i in range(len(pts)):
                a, b = Vector(pts[i]), Vector(pts[(i + 1) % len(pts)])
                n.x += (a.y - b.y) * (a.z + b.z)
                n.y += (a.z - b.z) * (a.x + b.x)
                n.z += (a.x - b.x) * (a.y + b.y)
            if n.dot(Vector(want)) < 0:
                pts = pts[::-1]
        s.f.append([s.vid(p) for p in pts])

    def revolve(s, prof, segs, a0=0.0, a1=2 * math.pi, rmod=None, closed=True):
        """prof [(r, z)] bottom->top; outward normals. rmod(i, j, theta) -> radius multiplier."""
        n = segs if closed else segs + 1
        rings = []
        for i, (r, z) in enumerate(prof):
            ring = []
            for j in range(n):
                t = a0 + (a1 - a0) * j / segs
                k = rmod(i, j, t) if rmod else 1.0
                ring.append(s.vid((r * k * math.cos(t), r * k * math.sin(t), z)))
            rings.append(ring)
        for i in range(len(prof) - 1):
            for j in range(segs):
                j2 = (j + 1) % n
                a, b, c, d = rings[i][j], rings[i][j2], rings[i + 1][j2], rings[i + 1][j]
                if prof[i][0] == 0:
                    s.f.append([a, c, d])
                elif prof[i + 1][0] == 0:
                    s.f.append([a, b, c])
                else:
                    s.f.append([a, b, c, d])

    def extrude(s, outline, frame, t0, t1, back_face=True):
        """outline [(u, v)] in a plane; frame = (origin, U, V, N) Vectors; solid from N*t0 to N*t1.
        back_face=False for a plate laid on another surface (its back would sit on that surface)."""
        o, U, V, N = frame
        front = [o + U * u + V * v + N * t1 for u, v in outline]
        back = [o + U * u + V * v + N * t0 for u, v in outline]
        s.P(front, N)
        if back_face:
            s.P(back, -N)
        # side faces: outward = away from the outline's centre
        cu = sum(u for u, v in outline) / len(outline)
        cv = sum(v for u, v in outline) / len(outline)
        m = len(outline)
        area = 0.0
        for i in range(m):
            u0, v0 = outline[i]
            u1, v1 = outline[(i + 1) % m]
            area += u0 * v1 - u1 * v0
        sgn = 1.0 if area > 0 else -1.0
        for i in range(m):
            u0, v0 = outline[i]
            u1, v1 = outline[(i + 1) % m]
            du, dv = u1 - u0, v1 - v0
            nu, nv = dv * sgn, -du * sgn  # right-hand normal of a CCW outline points out
            want = U * nu + V * nv
            s.P([front[i], front[(i + 1) % m], back[(i + 1) % m], back[i]], want)

    def box(s, x0, x1, y0, y1, z0, z1, skip=()):
        c = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0), (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]
        faces = {"-z": ([0, 1, 2, 3], (0, 0, -1)), "+z": ([4, 5, 6, 7], (0, 0, 1)), "-y": ([0, 1, 5, 4], (0, -1, 0)),
                 "+y": ([3, 2, 6, 7], (0, 1, 0)), "-x": ([0, 3, 7, 4], (-1, 0, 0)), "+x": ([1, 2, 6, 5], (1, 0, 0))}
        for k, (ids, want) in faces.items():
            if k not in skip:
                s.P([c[i] for i in ids], want)


XZ = lambda y: (Vector((0, y, 0)), Vector((1, 0, 0)), Vector((0, 0, 1)), Vector((0, 1, 0)))  # plane facing +Y at depth y


def to_mesh(name, mb, mat):
    me = bpy.data.meshes.new(name)
    me.from_pydata(mb.v, [], mb.f)
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.triangulate(bm, faces=bm.faces[:], quad_method="BEAUTY", ngon_method="BEAUTY")
    bmesh.ops.dissolve_degenerate(bm, edges=bm.edges[:], dist=1e-6)
    # box-projected UVs at real size: 1 UV unit = 1 stud (= 1/3 m)
    uv = bm.loops.layers.uv.verify()
    for f in bm.faces:
        n = f.normal
        ax = max(range(3), key=lambda i: abs(n[i]))
        for l in f.loops:
            co = l.vert.co
            if ax == 2:
                l[uv].uv = (co.x * SPM, co.y * SPM)
            elif ax == 0:
                l[uv].uv = (co.y * SPM, co.z * SPM)
            else:
                l[uv].uv = (co.x * SPM, co.z * SPM)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(get_mat(mat))
    for p in me.polygons:
        p.use_smooth = False
    return me


def add_obj(coll, name, me, parent, rot_deg=0.0):
    ob = bpy.data.objects.new(name, me)
    coll.objects.link(ob)
    ob.parent = parent
    ob.rotation_euler = (0, 0, math.radians(-rot_deg))  # bearing (clockwise from north) -> local +Y points that way
    return ob


def add_empty(coll, name):
    e = bpy.data.objects.new(name, None)
    e.empty_display_size = 2.0
    coll.objects.link(e)
    return e


def clear_coll():
    coll = bpy.data.collections.get(COLL)
    if coll is None:
        coll = bpy.data.collections.new(COLL)
        bpy.context.scene.collection.children.link(coll)
    for ob in list(coll.objects):
        me = ob.data if ob.type == "MESH" else None
        bpy.data.objects.remove(ob, do_unlink=True)
        if me is not None and me.users == 0:
            bpy.data.meshes.remove(me)
    return coll


# ---------------------------------------------------------------- the parts
def part9_base():
    mb = MB()
    prof = [(23.2, 0.0), (23.2, 0.25), (22.85, 0.25), (22.85, 0.5), (22.5, 0.5), (22.5, 0.75), (22.15, 0.75), (22.15, 1.0), (0.0, 1.0)]
    mb.revolve(prof, 96)
    return {"YgnMarbleWhite_Base": mb}


def arch_pts(a, zs, h, n=14):
    return [(a * math.cos(math.pi * i / n), zs + h * math.sin(math.pi * i / n)) for i in range(n + 1)]  # right -> left


def finger_skyline(fingers, zb, pad=0.0):
    """Outline of a row of carved finger panels (photo: tall boards with pointed tops stepping up to a centre one).
    fingers = [(x0, x1, top)] left -> right, touching. pad grows it (the back layer that shows as an outline)."""
    out = [(fingers[-1][1] + pad, zb), (fingers[0][0] - pad, zb)]
    for i, (x0, x1, T) in enumerate(fingers):
        x0p = x0 - (pad if i == 0 else 0.0)
        x1p = x1 + (pad if i == len(fingers) - 1 else 0.0)
        wd = x1 - x0
        T += pad
        sh = min(0.6, 1.4 * wd)  # deep notches between fingers so each reads on its own (photo)
        out += [(x0p, T - sh), (x0 + 0.12 * wd, T - 0.45 * sh), (x0 + 0.32 * wd, T - 0.15 * sh), ((x0 + x1) / 2, T),
                (x1 - 0.32 * wd, T - 0.15 * sh), (x1 - 0.12 * wd, T - 0.45 * sh), (x1p, T - sh)]
    clean = []
    for p in out:
        if not clean or abs(p[0] - clean[-1][0]) > 1e-6 or abs(p[1] - clean[-1][1]) > 1e-6:
            clean.append(p)
    return clean


def ogee(hw, zb, zt, n=10, tip=0.25):
    """Ogee arch outline (S-curved sides to a point), base +-hw at zb, top at zt (+ a small tip)."""
    right = []
    for i in range(n + 1):
        u = i / n
        x = hw * (1 - u)
        f = u - 0.16 * math.sin(2 * math.pi * u)
        right.append((x, zb + (zt - zb) * f))
    right[-1] = (0.0, zt + tip)
    left = [(-x, z) for x, z in reversed(right[:-1])]
    return [(-hw, zb)] + right + left[:-1]


BAY_HB0 = math.radians((72.0 - 2 * PORCH_HALF) / 8.0)  # nominal half-angle of a bay (instances are scaled in x per sector)


def bay_meshes():
    """One arcade bay in local coords (nominal size): facade plane at y = R_ARC*cos(hb0), edges exactly on the
    R_ARC circle, centred on x = 0. Photo 2: arch with a red scalloped hood edged white, a row of cream carved
    finger panels with pale green outlines and red buds above it, pilasters with red bands, a mosaic niche."""
    w = R_ARC * math.sin(BAY_HB0)
    Y = R_ARC * math.cos(BAY_HB0)
    a, zs, h, z0, top, dep = 1.08, 3.4, 1.15, 1.0, 5.6, 1.5
    cream, red, mosaic, white, mint = MB(), MB(), MB(), MB(), MB()
    arc = arch_pts(a, zs, h)
    cream.P([(-w, Y, z0), (-a, Y, z0), (-a, Y, top), (-w, Y, top)], (0, 1, 0))
    cream.P([(a, Y, z0), (w, Y, z0), (w, Y, top), (a, Y, top)], (0, 1, 0))
    for i in range(len(arc) - 1):
        (x0, zA), (x1, zB) = arc[i], arc[i + 1]
        cream.P([(x0, Y, zA), (x1, Y, zB), (x1, Y, top), (x0, Y, top)], (0, 1, 0))
        xm, zm = (x0 + x1) / 2, (zA + zB) / 2
        mosaic.P([(x0, Y, zA), (x1, Y, zB), (x1, Y - dep, zB), (x0, Y - dep, zA)], (-xm, 0, -(zm - zs)))  # mosaic vault
    cream.P([(a, Y, z0), (a, Y, zs), (a, Y - dep, zs), (a, Y - dep, z0)], (-1, 0, 0))
    cream.P([(-a, Y, z0), (-a, Y, zs), (-a, Y - dep, zs), (-a, Y - dep, z0)], (1, 0, 0))
    cream.P([(-w, Y, top), (w, Y, top), (w, Y - 0.45, top), (-w, Y - 0.45, top)], (0, 0, 1))
    mosaic.P([(a, Y - dep, z0)] + [(x, Y - dep, z) for x, z in arc] + [(-a, Y - dep, z0)], (0, 1, 0))  # closed niche back
    # half pilasters at both edges with red bands
    pw, pd = 0.35, 0.3
    for sx in (-1, 1):
        xo, xi = sx * w, sx * (w - pw)
        x0_, x1_ = min(xo, xi), max(xo, xi)
        cream.P([(x0_, Y + pd, z0), (x1_, Y + pd, z0), (x1_, Y + pd, 5.2), (x0_, Y + pd, 5.2)], (0, 1, 0))
        cream.P([(xi, Y, z0), (xi, Y + pd, z0), (xi, Y + pd, 5.2), (xi, Y, 5.2)], (-sx, 0, 0))
        cream.P([(x0_, Y, 5.2), (x1_, Y, 5.2), (x1_, Y + pd, 5.2), (x0_, Y + pd, 5.2)], (0, 0, 1))
        for zb0, zb1 in ((1.0, 1.3), (3.1, 3.4)):
            e = 0.04
            red.P([(x0_, Y + pd + e, zb0), (x1_, Y + pd + e, zb0), (x1_, Y + pd + e, zb1), (x0_, Y + pd + e, zb1)], (0, 1, 0))
            red.P([(xi - sx * e, Y, zb0), (xi - sx * e, Y + pd + e, zb0), (xi - sx * e, Y + pd + e, zb1), (xi - sx * e, Y, zb1)], (-sx, 0, 0))
            red.P([(x0_, Y, zb1), (x1_, Y, zb1), (x1_, Y + pd + e, zb1), (x0_, Y + pd + e, zb1)], (0, 0, 1))
    # arch hood: white inner edge, red scalloped band, white outer edge (photo)
    n = 16
    yh = Y + 0.12

    def ring(rin, rout, mb, s_in, s_out):
        pi_, po = [], []
        for i in range(n + 1):
            t = math.pi * i / n
            odd = i % 2
            ri = rin + (s_in if odd else 0.0)
            ro = rout + (s_out if odd else 0.0)
            pi_.append(((a + ri) * math.cos(t), zs + (h + ri) * math.sin(t)))
            po.append(((a + ro) * math.cos(t), zs + (h + ro) * math.sin(t)))
        for i in range(n):
            (xa, za), (xb, zb) = pi_[i], pi_[i + 1]
            (xc, zc), (xd, zd) = po[i + 1], po[i]
            mb.P([(xa, yh, za), (xb, yh, zb), (xc, yh, zc), (xd, yh, zd)], (0, 1, 0))
            mb.P([(xd, Y, zd), (xc, Y, zc), (xc, yh, zc), (xd, yh, zd)], (xd + xc, 0, (zd + zc) / 2 - zs))
            mb.P([(xa, Y, za), (xb, Y, zb), (xb, yh, zb), (xa, yh, za)], (-(xa + xb), 0, -((za + zb) / 2 - zs)))
    # 2026-11-16: the ornament kit's carved hood (scalloped red band 0.1 m proud, raised white rim 0.14 m, leaf scrolls
    # at the springings) in place of three flat rings
    OK.into_mb(OK.arch_hood(a, h, band=0.4, flame=False, scrolls=False), {"B": red, "W": white, "G": white}, (0.0, Y, zs))
    # carved finger panels over the arch: 2 layers (pale green outline behind, cream in front) + red buds
    fw, cw = 0.25, 0.36
    tops = [5.9, 6.2, 6.55, 6.95]
    fingers = []
    for k in range(4):
        x1 = -cw - fw * (3 - k)
        fingers.append((x1 - fw, x1, tops[k]))
    fingers.append((-cw, cw, 7.35))
    for k in range(4):
        x0 = cw + fw * k
        fingers.append((x0, x0 + fw, tops[3 - k]))
    zb_ = 5.05
    mint.extrude(finger_skyline(fingers, zb_, pad=0.05), XZ(0), Y + 0.12, Y + 0.22)
    cream.extrude(finger_skyline(fingers, zb_), XZ(0), Y + 0.22, Y + 0.32, back_face=False)
    cream.extrude(ogee(0.24, 5.6, 7.0, tip=0.1), XZ(0), Y + 0.32, Y + 0.4, back_face=False)  # raised centre leaf
    for x0, x1, T in fingers:
        if x1 - x0 < 0.3:
            xm = (x0 + x1) / 2
            red.extrude([(xm, T - 0.5), (xm + 0.08, T - 0.3), (xm, T - 0.08), (xm - 0.08, T - 0.3)], XZ(0), Y + 0.32, Y + 0.38, back_face=False)
    # standing gold Buddha in the niche
    st = MB()
    prof = [(0.45, 0.0), (0.45, 0.12), (0.36, 0.2), (0.42, 0.3), (0.34, 0.3)]
    st.revolve(prof, 8)
    body = [(0.34, 0.3), (0.29, 1.3), (0.30, 1.85), (0.24, 1.98), (0.09, 2.04),
            (0.15, 2.17), (0.12, 2.32), (0.06, 2.4), (0.0, 2.55)]
    st.revolve(body, 8)
    st.v = [(x * 0.85, y * 0.85 + Y - 0.85, z * 0.85 + z0) for x, y, z in st.v]
    return {"YgnRenderPainted_Cream": cream, "YgnPaint_Red": red, "YgnGlassMosaic_Teal": mosaic,
            "YgnRenderPainted_White": white, "YgnRenderPainted_Mint": mint}, st


def leaf_meshes():
    """Curled leaf panel over each bay join (photo: tall S-leaves between the arches), pale green outline + cream.
    2026-11-16: the ornament kit's carved leaf (kanote blade with raised inner leaf, spine and foot scrolls) in cream on
    a mint backing leaf, real bevelled relief instead of two flat plates."""
    mint, cream = MB(), MB()
    y0 = R_ARC + 0.32
    back = OK.Piece("leafback")
    OK.slab(back, "M", OK.move(OK.flame_outline(0.82, 2.95, lobes=2, n_lobe=2, barb=0.35, base=0.5, lean=0.04), dz=3.4),
            0.0, 0.06, 0.012, back=True, band=False)
    OK.into_mb(back, {"M": mint}, (0.0, y0, 0.0))
    OK.into_mb(OK.merlon_leaf(2.75, 0.66, lod="hi"), {"G": cream}, (0.0, y0 + 0.06 + 0.045 + 0.004, 3.45))
    return {"YgnRenderPainted_Mint": mint, "YgnRenderPainted_Cream": cream}


def merlon_mesh():
    """Gold leaf merlon (photo 2), from the ornament kit (2026-11-16): a lobed kanote leaf with a raised inner leaf and
    spine, bevelled relief 0.09 + 0.05 + 0.04 m (was two flat cut-out plates). 'lo' detail: 88 copies."""
    mb = MB()
    r = 12.6
    zb = T_TERRACE + 0.3
    OK.into_mb(OK.merlon_leaf(1.45, 0.6, lod="lo"), {"G": mb}, (0.0, r, zb))
    return mb


def window_mesh():
    mb = MB()
    y = R_DRUM + 0.05
    mb.P([(-0.6, y, 6.3), (0.6, y, 6.3), (0.6, y, 7.15), (-0.6, y, 7.15)], (0, 1, 0))
    return mb


# Heights measured on photo Kaba_Aye_Paya_2.jpg with a camera fitted to 14 model points (porch sign corners, sun disc,
# crest, 4 arch hoods, 2 windows, spire tip at 34 m; rms 40 px on 1920x1280): see fit2.py in the note.
# terrace 8.95, merlons 9.1-10.35, moulding steps 8.95-13.0, bell 13.0-20.6, ringed cone 20.6-23.4, petals 23.4-25.8,
# bud 25.8-27.0, hti 27.0-30.0, mast + vane + orb to 34.0.
T_TERRACE = 8.95
Z_BELL = 13.0
R_BELL = 5.0
R_MOULD = 6.35


def part7_drum():
    white, red, gold, roof = MB(), MB(), MB(), MB()
    white.revolve([(R_DRUM, 5.55), (R_DRUM, 8.65)], 120)  # foot 5 cm under the arcade roof
    red.revolve([(R_DRUM + 0.04, 7.3), (R_DRUM + 0.04, 7.43)], 120)
    # red lotus-drop motifs in the frieze (photo: a row of red drops under the cornice)
    nm = 72
    rr = R_DRUM + 0.05
    for i in range(nm):
        t = 2 * math.pi * (i + 0.5) / nm
        c, s_ = math.cos(t), math.sin(t)
        tx, ty = -s_, c
        pts2 = [(-0.24, 8.45), (0.24, 8.45), (0.2, 8.15), (0.0, 7.55), (-0.2, 8.15)]
        cart = [(-0.29, 8.5), (0.29, 8.5), (0.26, 8.12), (0.0, 7.45), (-0.26, 8.12)]
        gold.P([(rr * c + tx * u, rr * s_ + ty * u, z) for u, z in cart], (c, s_, 0))
        r2 = rr + 0.04
        red.P([(r2 * c + tx * u, r2 * s_ + ty * u, z) for u, z in pts2], (c, s_, 0))
    gold.revolve([(R_DRUM, 8.65), (12.8, 8.65), (12.8, T_TERRACE)], 120)
    gold.revolve([(R_DRUM + 0.04, 8.52), (R_DRUM + 0.04, 8.65)], 120)  # gold band over the drops
    roof.revolve([(17.3, 5.55), (R_DRUM, 5.55)], 120)  # 5 cm under the bay wall tops, reaches under them (no slit)
    return {"YgnRenderPainted_White": white, "YgnPaint_Red": red, "YgnGoldPlate_Trim": gold, "YgnConcreteBare_Roof": roof}


def part6_terrace():
    roof, gold = MB(), MB()
    roof.revolve([(12.42, T_TERRACE), (R_MOULD, T_TERRACE)], 120)
    gold.revolve([(12.8, T_TERRACE), (12.8, T_TERRACE + 0.3), (12.42, T_TERRACE + 0.3), (12.42, T_TERRACE)], 120)
    white = MB()
    zb, zt = T_TERRACE + 0.3, T_TERRACE + 1.4
    for i in range(N_MERLON):
        t = 2 * math.pi * i / N_MERLON  # between merlons (merlons sit at (i + 0.5) / N)
        c, s_ = math.cos(t), math.sin(t)
        tx, ty = -s_, c
        def P_(u, r, z):
            return (r * c + tx * u, r * s_ + ty * u, z)
        r0, r1, hw = 12.56, 12.66, 0.04
        white.P([P_(-hw, r1, zb), P_(hw, r1, zb), P_(hw, r1, zt), P_(-hw, r1, zt)], (c, s_, 0))
        white.P([P_(-hw, r0, zb), P_(hw, r0, zb), P_(hw, r0, zt), P_(-hw, r0, zt)], (-c, -s_, 0))
        white.P([P_(hw, r0, zb), P_(hw, r1, zb), P_(hw, r1, zt), P_(hw, r0, zt)], (tx, ty, 0))
        white.P([P_(-hw, r0, zb), P_(-hw, r1, zb), P_(-hw, r1, zt), P_(-hw, r0, zt)], (-tx, -ty, 0))
        white.P([P_(-hw, r0, zt), P_(hw, r0, zt), P_(hw, r1, zt), P_(-hw, r1, zt)], (0, 0, 1))
    return {"YgnPaint_RoofRed": roof, "YgnGoldPlate_Trim": gold, "YgnRenderPainted_White": white}


def part5_mouldings():
    """Four round steps between the roof terrace and the bell (hidden behind the merlons from the ground)."""
    mb = MB()
    steps = [(R_MOULD, 1.05), (5.95, 1.0), (5.6, 1.0), (5.3, 1.0)]
    z = T_TERRACE
    prof = []
    for k, (r, hgt) in enumerate(steps):
        prof += [(r, z), (r, z + hgt - 0.12), (r - 0.1, z + hgt)]
        z += hgt
        nxt = steps[k + 1][0] if k + 1 < len(steps) else R_BELL
        prof.append((nxt, z))
    mb.revolve(prof, 72)
    return {"YgnGoldLeaf_Bell": mb}


BELL_PROF = [(5.0, 13.0), (5.0, 13.2), (4.92, 13.6), (4.79, 14.06), (4.64, 14.59), (4.43, 15.12), (4.34, 15.65), (4.16, 16.18),
             (3.85, 16.72), (3.53, 17.26), (3.17, 17.8), (2.72, 18.35), (2.42, 18.9), (2.05, 19.46), (1.82, 20.01), (1.52, 20.57)]


def r_at(prof, z):
    for (r0, z0), (r1, z1) in zip(prof, prof[1:]):
        if z0 <= z <= z1 and z1 > z0:
            return r0 + (r1 - r0) * (z - z0) / (z1 - z0)
    return prof[-1][0]


def part4_bell():
    bell, band = MB(), MB()
    bell.revolve(BELL_PROF, 64)

    def ring(zc, hgt, out):
        z0, z1 = zc - hgt / 2, zc + hgt / 2
        r0, r1 = r_at(BELL_PROF, z0), r_at(BELL_PROF, z1)
        band.revolve([(r0, z0), (r0 + out, z0 + 0.04), (r1 + out, z1 - 0.04), (r1, z1)], 64)
    ring(15.3, 0.16, 0.06)    # thin double line low on the bell
    ring(15.55, 0.1, 0.05)
    ring(17.1, 0.22, 0.08)    # ornate ring with hanging leaves
    n = 40
    for i in range(n):
        t = 2 * math.pi * (i + 0.5) / n
        c, s_ = math.cos(t), math.sin(t)
        tx, ty = -s_, c

        def at(u, z):
            r = r_at(BELL_PROF, z) + 0.04
            return (r * c + tx * u, r * s_ + ty * u, z)
        band.P([at(-0.26, 16.99), at(0.26, 16.99), at(0.14, 16.6), at(0.0, 16.25), at(-0.14, 16.6)], (c, s_, 0.5))
    return {"YgnGoldLeaf_Bell": bell, "YgnGoldPlate_Trim": band}


def part3_lotus():
    mb = MB()
    prof = []
    z, r = 20.57, 1.52
    nr = 8
    for k in range(nr):  # ringed cone
        prof += [(r, z), (r + 0.07, z + 0.07), (r + 0.07, z + 0.22), (r - 0.03, z + 0.33)]
        z += 0.3575
        r -= 0.45 / nr
    petal_rows = []
    for k in range(3):  # lotus petal rows
        prof += [(r + 0.1, z + 0.05), (r + 0.02, z + 0.65)]
        petal_rows.append(len(prof) - 2)
        z += 0.783
        r -= 0.05
    prof += [(r, z)]

    def rmod(i, j, t):
        if i in petal_rows:
            ph = math.pi / 16 if (petal_rows.index(i) % 2) else 0.0
            return 1.0 + 0.1 * abs(math.cos(8 * t + ph * 8))
        return 1.0
    mb.revolve(prof, 48, rmod=rmod)
    return {"YgnGoldLeaf_Bell": mb}, (z, r)


def part2_bud(z0, r0=0.92):
    mb = MB()
    prof = [(r0, z0), (r0 + 0.04, z0 + 0.3), (0.9, z0 + 0.7), (0.78, z0 + 1.0), (0.69, z0 + 1.2)]
    mb.revolve(prof, 32, rmod=lambda i, j, t: 1.0 + (0.035 * math.cos(8 * t) if 0 < i < 4 else 0.0))
    return {"YgnGoldLeaf_Bell": mb}, z0 + 1.2


def part1_hti(z0):
    mb = MB()
    prof = [(0.69, z0), (0.66, z0 + 0.15)]
    z = z0 + 0.15
    core = 0.55
    for i in range(6):  # umbrella tiers: r 1.01 at the bottom to 0.2 at the top (photo)
        rt = 1.01 - i * 0.16
        prof += [(core, z), (rt, z + 0.06), (rt, z + 0.14), (core * 0.85, z + 0.47)]
        z += 0.47
        core *= 0.82
    prof += [(0.1, z), (0.08, 33.0), (0.18, 33.08), (0.2, 33.2), (0.14, 33.32), (0.04, 33.4), (0.03, 33.75), (0.0, 34.0)]
    mb.revolve(prof, 24)
    # vane (flag) on the mast
    zv = 31.5
    mb.extrude([(0.08, zv), (0.8, zv + 0.12), (0.75, zv + 0.3), (0.08, zv + 0.42)], XZ(0), -0.02, 0.02)
    # two wire fan discs beside the spire at the petal rows (photo: two big wire circles)
    zc, R, tr = 25.2, 1.3, 0.035
    for side in (-1, 1):
        rot = math.radians(45.0)
        ca, sa = math.cos(rot), math.sin(rot)
        segs, sides = 32, 4
        ring = []
        for i in range(segs):
            u = 2 * math.pi * i / segs
            cu, su = math.cos(u), math.sin(u)
            row = []
            for k in range(sides):
                v = 2 * math.pi * k / sides
                rr = R + tr * math.cos(v)
                x, zz = side * 1.35 + rr * cu, zc + rr * su
                yy = tr * math.sin(v)
                row.append(mb.vid((x * ca - yy * sa, x * sa + yy * ca, zz)))
            ring.append(row)
        for i in range(segs):
            for k in range(sides):
                a, b = ring[i][k], ring[(i + 1) % segs][k]
                c, d = ring[(i + 1) % segs][(k + 1) % sides], ring[i][(k + 1) % sides]
                mb.f.append([a, d, c, b])
    return {"YgnGoldPlate_Trim": mb}


def porch_meshes():
    """One entrance porch in local coords, facing +Y, its front at y = 21. Photo 2 (crop): an open front (gold carved
    jambs and a gold valance under the sign, a dark hall behind: here a shallow closed recess, 1.4 m), the plain red
    name panel, a gold eave, then the crest in layers: red backboard, gold carved fingers stepping up to the centre,
    a gold ogee frame, the red ogee field with the gold sun disc; gold scrolls curling out at the eave ends."""
    W = R_ARC * math.sin(math.radians(PORCH_HALF))  # 3.3
    cream, teal, red, gold, dark, roof, maroon = MB(), MB(), MB(), MB(), MB(), MB(), MB()
    yb, yw, yf = 17.6, 19.6, 21.0
    ybw = R_ARC * math.cos(math.radians(PORCH_HALF))  # side walls start exactly at the arcade's edge corner
    z0, ze = 1.0, 5.25
    zs0 = 4.35
    pin = W - 0.6  # inner face of the corner pillars
    for s in (-1, 1):
        x0_, x1_ = (W - 0.4, W) if s > 0 else (-W, -W + 0.4)
        cream.box(x0_, x1_, ybw, yf - 0.64, z0, ze, skip=("-z", "-y", "+y", "+z", "-x" if s > 0 else "+x"))
        cream.P([(x0_, ybw, ze), (x1_, ybw, ze), (x1_, yb, ze), (x0_, yb, ze)], (0, 0, 1))
        xi = s * (W - 0.4)
        dark.P([(xi, yw, z0), (xi, yf - 0.64, z0), (xi, yf - 0.64, zs0), (xi, yw, zs0)], (-s, 0, 0))  # recess side
        px0, px1 = (pin, W) if s > 0 else (-W, -pin)
        teal.box(px0, px1, yf - 0.64, yf, z0, ze, skip=("-z", "+z", "-y"))
    # the recess: dark back wall + dark soffit (no way in)
    dark.P([(-W + 0.4, yw, z0), (W - 0.4, yw, z0), (W - 0.4, yw, zs0), (-W + 0.4, yw, zs0)], (0, 1, 0))
    dark.P([(-W + 0.4, yw, zs0), (W - 0.4, yw, zs0), (W - 0.4, yf - 0.64, zs0), (-W + 0.4, yf - 0.64, zs0)], (0, 0, -1))
    dark.P([(-pin, yf - 0.64, zs0), (pin, yf - 0.64, zs0), (pin, yf - 0.1, zs0), (-pin, yf - 0.1, zs0)], (0, 0, -1))
    # the step of the pillars' back faces into the recess (between the wall and the pillar, x pin..W-0.4)
    for s in (-1, 1):
        dark.P([(s * pin, yf - 0.64, z0), (s * (W - 0.4), yf - 0.64, z0), (s * (W - 0.4), yf - 0.64, zs0), (s * pin, yf - 0.64, zs0)], (0, -1, 0))
    # gold carved jambs, full height, and the gold valance with a scalloped hem under the sign
    jx0, jx1 = 2.45, pin
    for s in (-1, 1):
        a_, b_ = (jx0, jx1) if s > 0 else (-jx1, -jx0)
        gold.box(a_, b_, yf - 0.1, yf + 0.06, z0, ze, skip=("-z", "+z", "-y"))
    dark.P([(-jx0, yf - 0.1, zs0), (jx0, yf - 0.1, zs0), (jx0, yf, zs0), (-jx0, yf, zs0)], (0, 0, -1))
    hem = [(jx0, zs0), (-jx0, zs0)]
    nsc = 12
    for i in range(nsc + 1):
        x = -jx0 + 2 * jx0 * i / nsc
        hem.append((x, 3.8 if i % 2 == 0 else 3.95))
    val = [(-jx0, zs0)] + hem[2:] + [(jx0, zs0)]
    gold.extrude(val, XZ(0), yf - 0.08, yf + 0.04)
    # plain name panel (no fake Burmese), gold frame strips
    maroon.P([(-jx0, yf, zs0), (jx0, yf, zs0), (jx0, yf, ze), (-jx0, yf, ze)], (0, 1, 0))
    for z_a, z_b in ((zs0 + 0.02, zs0 + 0.14), (ze - 0.14, ze)):
        gold.box(-jx0, jx0, yf, yf + 0.05, z_a, z_b, skip=("-y",))
    # eave slab, roof, closed back gable
    gold.box(-3.6, 3.6, yb, yf + 0.35, ze, ze + 0.35, skip=("-y",))
    zb = ze + 0.35
    roof.P([(-3.5, yb, zb), (-3.5, yf + 0.04, zb), (0, yf + 0.04, 8.9), (0, yb, 8.9)], (-1, 0, 1))
    roof.P([(3.5, yb, zb), (3.5, yf + 0.04, zb), (0, yf + 0.04, 8.9), (0, yb, 8.9)], (1, 0, 1))
    cream.P([(-3.5, yb, zb), (3.5, yb, zb), (0.0, yb, 8.9)], (0, -1, 0))
    # crest (2026-11-16): the ornament kit's carved gable: red backboard, gold ogee frame band 0.1 m proud with flame
    # fingers up its edge and a big apex flame, raised gold sun disc (rays + boss) in the red field, scrolls curling out at
    # the eave ends. Base 6.9 m on the eave (zb), apex flame tip ~10.3 m (photo 2).
    OK.into_mb(OK.gable_frame(6.9, 4.0), {"G": gold, "R": red}, (0.0, yf + 0.05, zb))
    return {"YgnRenderPainted_Cream": cream, "YgnGlassMosaic_Teal": teal, "YgnPaint_Red": red,
            "YgnGoldPlate_Trim": gold, "YgnPaint_DarkHall": dark, "YgnPaint_RoofRed": roof, "YgnPaint_Maroon": maroon}


def walkway_meshes():
    """Green-roofed covered walkway from a porch out to the plaza's edge (Esri: 5 spokes ~5.5 m wide to r ~52 m;
    photo 2: teal roof with a gold fretted eave fringe). Local frame like the porch; ground = 0 beyond the platform."""
    green, gold, white = MB(), MB(), MB()
    y0, y1 = 21.05, 52.0
    ze, zr, hw, t = 3.0, 3.8, 3.0, 0.06
    for s in (-1, 1):
        o = [(s * hw, y0, ze), (s * hw, y1, ze), (0, y1, zr), (0, y0, zr)]
        green.P(o, (s * 0.8, 0, 3.0))
        green.P([(x, y, z - t) for x, y, z in o], (-s * 0.8, 0, -3.0))
        green.P([(s * hw, y0, ze - t), (s * hw, y1, ze - t), (s * hw, y1, ze), (s * hw, y0, ze)], (s, 0, 0))
        green.P([(s * hw, y0, ze), (0, y0, zr), (0, y0, zr - t), (s * hw, y0, ze - t)], (0, -1, 0))
        green.P([(s * hw, y1, ze), (0, y1, zr), (0, y1, zr - t), (s * hw, y1, ze - t)], (0, 1, 0))
        # gold fringe board hanging under the eave, scalloped
        fr = [(y0, ze - t), (y1, ze - t)]
        n = 30
        for i in range(n, -1, -1):
            y = y0 + (y1 - y0) * i / n
            fr.append((y, ze - t - (0.38 if i % 2 else 0.24)))
        # plate in the YZ plane at x = s*(hw - 0.05), 0.05 thick
        frame = (Vector((s * (hw - 0.04), 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1)), Vector((s, 0, 0)))
        gold.extrude(fr, frame, -0.06, 0.0)
        # posts every 4 m from y 24 (outside the platform)
        for k in range(8):
            y = 24.0 + 4.0 * k
            px = s * 2.6
            zt = ze - t + (zr - ze) * (hw - 2.6) / hw - 0.03
            white.box(px - 0.09, px + 0.09, y - 0.09, y + 0.09, 0.0, zt, skip=("-z", "+z"))
    return {"YgnCorrugatedZinc_Green": green, "YgnGoldPlate_Trim": gold, "YgnRenderPainted_White": white}


def stair_mesh(bearing):
    """Red steel stair with hand rails from the arcade roof up the drum to the terrace (photo 2, right of the 2nd window)."""
    mb = MB()
    r0, r1 = 12.45, 13.15
    zb, zt = 5.55, 8.55
    run = 2.0

    def at(u, r, z):  # u along the tangent (local x), r radius, rotated later by the object
        return (u, r, z)
    # stringers (thin slanted plates) at both radii
    for r in (r0, r1):
        d = 0.04 if r == r0 else -0.04
        q = [at(-run / 2, r, zb), at(run / 2, r, zt - 0.2), at(run / 2, r, zt), at(-run / 2, r, zb + 0.2)]
        mb.P(q, (0, 1 if r == r1 else -1, 0))
        mb.P([(x, y + d, z) for x, y, z in q], (0, -1 if r == r1 else 1, 0))
    # treads
    nt = 10
    for i in range(1, nt):
        u = -run / 2 + run * i / nt
        z = zb + (zt - zb) * i / nt
        mb.box(u - 0.1, u + 0.1, r0 + 0.04, r1 - 0.04, z - 0.03, z, skip=("-y", "+y"))
    # hand rails 0.9 m over the stringers + posts
    for r in (r0 + 0.02, r1 - 0.02):
        for f in (0.0, 0.5, 1.0):
            u = -run / 2 + run * f
            z = zb + (zt - zb) * f + 0.1
            mb.box(u - 0.02, u + 0.02, r - 0.02, r + 0.02, z + 0.1, z + 0.95, skip=("-z",))
        a_, b_ = (-run / 2, zb + 1.05), (run / 2, zt + 1.05)
        mb.P([(a_[0], r - 0.025, a_[1]), (b_[0], r - 0.025, b_[1]), (b_[0], r - 0.025, b_[1] + 0.05), (a_[0], r - 0.025, a_[1] + 0.05)], (0, -1, 0))
        mb.P([(a_[0], r + 0.025, a_[1]), (b_[0], r + 0.025, b_[1]), (b_[0], r + 0.025, b_[1] + 0.05), (a_[0], r + 0.025, a_[1] + 0.05)], (0, 1, 0))
        mb.P([(a_[0], r - 0.025, a_[1] + 0.05), (b_[0], r - 0.025, b_[1] + 0.05), (b_[0], r + 0.025, b_[1] + 0.05), (a_[0], r + 0.025, a_[1] + 0.05)], (0, 0, 1))
    return mb


def build():
    coll = clear_coll()
    root = add_empty(coll, "KabaAye")
    made = {}

    def part(label, meshes):
        e = add_empty(coll, label)
        e.parent = root
        for mat, mb in meshes.items():
            nm = "%s_%s" % (label.replace(" ", "_"), mat)
            add_obj(coll, nm, to_mesh(nm, mb, mat), e)
        made[label] = e
        return e

    part("9 round base platform", part9_base())
    p7 = part("7 circular hall drum", part7_drum())
    bays, statue = bay_meshes()
    bay_me = {mat: to_mesh("7_bay_" + mat, mb, mat) for mat, mb in bays.items()}
    leaf_me = {mat: to_mesh("7_leaf_" + mat, mb, mat) for mat, mb in leaf_meshes().items()}
    st_me = to_mesh("7_buddha_YgnGoldLeaf_Bell", statue, "YgnGoldLeaf_Bell")
    win_me = to_mesh("7_window_YgnSteelPainted_Grille", window_mesh(), "YgnSteelPainted_Grille")
    B = sorted(PORCH_BEARINGS)
    n = nw = 0
    for k in range(len(B)):
        b0 = B[k]
        span = (B[(k + 1) % len(B)] - b0) % 360.0
        bay_deg = (span - 2 * PORCH_HALF) / 4.0
        hb = math.radians(bay_deg / 2.0)
        sx = math.sin(hb) / math.sin(BAY_HB0)
        dy = R_ARC * (math.cos(hb) - math.cos(BAY_HB0))
        for j in range(4):
            ang = b0 + PORCH_HALF + bay_deg * (j + 0.5)
            n += 1
            rad = math.radians(ang)
            loc = (dy * math.sin(rad), dy * math.cos(rad), 0.0)
            for mat, me in bay_me.items():
                ob = add_obj(coll, "7_bay%02d_%s" % (n, mat), me, p7, ang)
                ob.scale = (sx, 1.0, 1.0)
                ob.location = loc
            ob = add_obj(coll, "7_buddha%02d_YgnGoldLeaf_Bell" % n, st_me, p7, ang)
            ob.location = loc
        for j in range(1, 4):
            nw += 1
            ang = b0 + PORCH_HALF + bay_deg * j
            add_obj(coll, "7_window%02d_YgnSteelPainted_Grille" % nw, win_me, p7, ang)
            for mat, me in leaf_me.items():
                add_obj(coll, "7_leaf%02d_%s" % (nw, mat), me, p7, ang)
    pa = sorted(PORCH_BEARINGS)[(sorted(PORCH_BEARINGS).index(191.0) - 1) % 5]
    span = (191.0 - pa) % 360.0
    bay_deg = (span - 2 * PORCH_HALF) / 4.0
    stair_ang = 191.0 - PORCH_HALF - bay_deg * 2.5
    add_obj(coll, "7_stair_YgnSteelPainted_Red", to_mesh("7_stair_YgnSteelPainted_Red", stair_mesh(stair_ang), "YgnSteelPainted_Red"), p7, stair_ang)
    porch = porch_meshes()
    p8 = add_empty(coll, "8 entrance porch")
    p8.parent = root
    porch_me = {mat: to_mesh("8_porch_" + mat, mb, mat) for mat, mb in porch.items()}
    for k, b in enumerate(PORCH_BEARINGS):
        for mat, me in porch_me.items():
            add_obj(coll, "8_porch%d_%s" % (k + 1, mat), me, p8, b)
    p10 = add_empty(coll, "10 covered walkway")
    p10.parent = root
    walk_me = {mat: to_mesh("10_walkway_" + mat, mb, mat) for mat, mb in walkway_meshes().items()}
    for k, b in enumerate(PORCH_BEARINGS):
        for mat, me in walk_me.items():
            add_obj(coll, "10_walkway%d_%s" % (k + 1, mat), me, p10, b)
    p6 = part("6 upper terrace ring", part6_terrace())
    mer = to_mesh("6_merlon_YgnGoldPlate_Trim", merlon_mesh(), "YgnGoldPlate_Trim")
    for i in range(N_MERLON):
        add_obj(coll, "6_merlon%02d_YgnGoldPlate_Trim" % (i + 1), mer, p6, 360.0 * (i + 0.5) / N_MERLON)
    part("5 bell base moulding rings", scale_xy(part5_mouldings(), K_BELL))
    part("4 bell", scale_xy(part4_bell(), K_BELL))
    lot, (z, rl) = part3_lotus()
    part("3 lotus petal bands", scale_xy(lot, K_SPIRE))
    bud, z2 = part2_bud(z, rl)
    part("2 banana bud", scale_xy(bud, K_SPIRE))
    part("1 hti", part1_hti(z2))
    return report()


def tris(ob):
    ob.data.calc_loop_triangles()
    return len(ob.data.loop_triangles)


def report():
    coll = bpy.data.collections[COLL]
    out = {}
    total = 0
    for e in coll.objects:
        if e.type == "EMPTY" and e.parent is not None:
            t = sum(tris(c) for c in e.children if c.type == "MESH")
            uniq = sum(tris(m) for m in {c.data.name: c for c in e.children if c.type == "MESH"}.values())
            out[e.name] = (t, uniq, len(e.children))
            total += t
    lo = min((v.co.z for o in coll.objects if o.type == "MESH" for v in o.data.vertices), default=0)
    print("parts (rendered tris, unique-mesh tris, objects):")
    for k in sorted(out):
        print("  %-28s %6d %6d %4d" % (k, *out[k]))
    print("TOTAL rendered tris", total)
    return out, total


def export():
    """Scale to studs (1 m = 3 studs) in place, write the .glb, scale back."""
    coll = bpy.data.collections[COLL]
    meshes = {o.data for o in coll.objects if o.type == "MESH"}
    S = Matrix.Scale(SPM, 4)
    for me in meshes:
        me.transform(S)
    try:
        bpy.ops.object.select_all(action="DESELECT")
        for o in coll.objects:
            if o.type in ("MESH", "EMPTY"):
                o.select_set(True)
        os.makedirs(os.path.dirname(GLB), exist_ok=True)
        props = {p.identifier for p in bpy.ops.export_scene.gltf.get_rna_type().properties}
        kw = dict(filepath=GLB, export_format="GLB", use_selection=True, export_yup=True, export_apply=False)
        if "export_colors" in props:
            kw["export_colors"] = False
        if "export_normals" in props:
            kw["export_normals"] = True
        bpy.ops.export_scene.gltf(**kw)
    finally:
        Si = Matrix.Scale(1.0 / SPM, 4)
        for me in meshes:
            me.transform(Si)
    # colour table for the placer (the importer drops baseColorFactor)
    cols = {k: list(v[0]) for k, v in MATS.items()}
    with open(GLB.replace(".glb", "_materials.json"), "w") as f:
        json.dump({"studs_per_metre": SPM, "materials": cols,
                   "axes": "glTF +Y up; Blender +Y (north) = glTF -Z", "pivot": "base centre, ground y = 0"}, f, indent=1)
    print("wrote", GLB, os.path.getsize(GLB))


def photo_cam(cam_xyz, target_xyz, lens_mm=38.0, name="KabaAye_PhotoCam"):
    """A camera matching Kaba_Aye_Paya_2.jpg (1920x1280), kept in the KabaAye collection (not exported)."""
    coll = bpy.data.collections[COLL]
    cam = bpy.data.objects.get(name)
    if cam is None:
        cam = bpy.data.objects.new(name, bpy.data.cameras.new(name))
        coll.objects.link(cam)
    cam.data.lens = lens_mm
    cam.data.sensor_width = 36.0
    cam.data.sensor_fit = "HORIZONTAL"
    cam.location = cam_xyz
    d = Vector(target_xyz) - Vector(cam_xyz)
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    sun = bpy.data.objects.get("KabaAye_Sun")
    if sun is None:
        sun = bpy.data.objects.new("KabaAye_Sun", bpy.data.lights.new("KabaAye_Sun", "SUN"))
        coll.objects.link(sun)
    sun.data.energy = 3.2
    sun.data.angle = math.radians(1.0)
    # 14 Mar 2015 13:03 Yangon: sun ~72 deg high, a little south of west of the meridian
    sun.rotation_euler = (math.radians(18.0), 0.0, math.radians(-20.0))
    return cam


def render_compare(out_png, photo_png, cam_name="KabaAye_PhotoCam"):
    """Render the model through the photo camera and paste photo | model side by side (1920x1280 each, saved half size)."""
    sc = bpy.context.scene
    keep = (sc.camera, sc.render.resolution_x, sc.render.resolution_y, sc.render.resolution_percentage, sc.render.filepath,
            sc.render.film_transparent, sc.world.color[:] if sc.world else None)
    hidden = []
    for o in sc.objects:  # hide everything that is not ours for the render; put it back after
        if o.users_collection and all(c.name != COLL for c in o.users_collection) and not o.hide_render:
            o.hide_render = True
            hidden.append(o)
    vs = sc.view_settings
    keep_view = (vs.view_transform, vs.look, vs.exposure)
    world = sc.world
    bg = next((n for n in world.node_tree.nodes if n.type == "BACKGROUND"), None) if world and world.use_nodes else None
    keep_bg = (tuple(bg.inputs[0].default_value), bg.inputs[1].default_value) if bg else None
    try:
        try:
            vs.view_transform = "Standard"
        except TypeError:
            pass
        vs.look = "None"
        vs.exposure = 0.0
        if bg:  # midday sky fill
            bg.inputs[0].default_value = (0.36, 0.45, 0.6, 1.0)
            bg.inputs[1].default_value = 1.0
        sc.camera = bpy.data.objects[cam_name]
        sc.render.resolution_x, sc.render.resolution_y, sc.render.resolution_percentage = 1920, 1280, 50
        sc.render.film_transparent = True
        tmp = os.path.join(os.path.dirname(out_png), "_model_render.png")
        sc.render.filepath = tmp
        bpy.ops.render.render(write_still=True)
    finally:
        sc.camera, sc.render.resolution_x, sc.render.resolution_y, sc.render.resolution_percentage, sc.render.filepath, sc.render.film_transparent = keep[:6]
        for o in hidden:
            o.hide_render = False
        vs.view_transform, vs.look, vs.exposure = keep_view
        if bg:
            bg.inputs[0].default_value, bg.inputs[1].default_value = keep_bg
    ph = bpy.data.images.load(photo_png, check_existing=False)
    md = bpy.data.images.load(tmp, check_existing=False)
    W, H = 960, 640
    ph.scale(W, H)
    md.scale(W, H)
    sky = (83 / 255.0, 121 / 255.0, 167 / 255.0)
    pp = list(ph.pixels)
    mp = list(md.pixels)
    out = bpy.data.images.new("kaba_compare", W * 2, H, alpha=False)
    px = [0.0] * (W * 2 * H * 4)
    skyl = list(sky)  # both images hold sRGB bytes
    for y in range(H):
        for x in range(W):
            i = (y * W + x) * 4
            o1 = (y * W * 2 + x) * 4
            o2 = (y * W * 2 + W + x) * 4
            px[o1:o1 + 4] = pp[i:i + 4]
            a = mp[i + 3]
            px[o2:o2 + 4] = [mp[i] * a + skyl[0] * (1 - a), mp[i + 1] * a + skyl[1] * (1 - a), mp[i + 2] * a + skyl[2] * (1 - a), 1.0]
    out.pixels = px
    out.filepath_raw = out_png
    out.file_format = "PNG"
    out.save()
    for im in (ph, md, out):
        bpy.data.images.remove(im)
    os.remove(tmp)
    print("wrote", out_png)


PHOTO2 = VAULT + "/Games/CityLegends/build/landmarks/refs/catalogue/kaba_aye/Kaba_Aye_Paya_2.jpg"


def set_photo2_cam(d=30.0, e=4.0, pitch=19.0, yawoff=4.0, lens=38.0, h=1.6, bearing=187.0):
    """Camera for Kaba_Aye_Paya_2.jpg: d m in front of the porch at `bearing`, e m to the viewer's right, eye height h."""
    b = math.radians(bearing)
    u = Vector((math.sin(b), math.cos(b), 0))
    right = Vector((-u.y, u.x, 0))
    C = u * (21.0 + d) + right * e
    C.z = h
    look = -C
    look.z = 0
    look.normalize()
    ya = math.radians(-yawoff)
    look = Vector((look.x * math.cos(ya) - look.y * math.sin(ya), look.x * math.sin(ya) + look.y * math.cos(ya), 0))
    T = C + look * 10
    T.z = h + 10 * math.tan(math.radians(pitch))
    photo_cam(tuple(C), tuple(T), lens)
    return C


def check_overlaps(tol=0.02, fix=True, verbose=True):
    """Owner rule (16 Nov 2026): no flickering / overlapping parts. Finds every pair of triangles (any objects, instances
    in world space) that lie within `tol` m of each other on parallel planes and overlap:
      - opposite normals = a hidden joint (e.g. a merlon's bottom on the parapet): the smaller face is deleted (fix=True);
      - same-facing normals = stacked faces that would flicker: reported, must be fixed in the geometry.
    Returns (n_opposite, n_same, same_pairs)."""
    from mathutils.bvhtree import BVHTree
    bpy.context.view_layer.update()  # matrix_world of fresh objects
    coll = bpy.data.collections[COLL]
    obs = [o for o in coll.objects if o.type == "MESH"]
    verts, polys, owner = [], [], []
    for o in obs:
        mw = o.matrix_world
        me = o.data
        base = len(verts)
        verts += [mw @ v.co for v in me.vertices]
        for p in me.polygons:
            polys.append([base + i for i in p.vertices])
            owner.append((o, p.index))
    bvh = BVHTree.FromPolygons(verts, polys, all_triangles=False, epsilon=0.0)
    norms, cents, areas = [], [], []
    for pv in polys:
        a, b, c = verts[pv[0]], verts[pv[1]], verts[pv[2]]
        n = (b - a).cross(c - a)
        areas.append(n.length / 2)
        norms.append(n.normalized() if n.length > 1e-12 else n)
        cents.append(sum((verts[i] for i in pv), Vector()) / len(pv))
    def covered(k):
        # every corner (pulled 2% toward the middle) has an opposite-facing face within tol right behind it
        for vi in polys[k]:
            p = verts[vi].lerp(cents[k], 0.02)
            ok = False
            for co, no, j, dist in bvh.find_nearest_range(p, tol):
                if j == k or norms[k].dot(norms[j]) > -0.995:
                    continue
                v = p - co
                off = v.dot(norms[j])
                if (v - norms[j] * off).length < 1e-4:
                    ok = True
                    break
            if not ok:
                return False
        return True

    kill = {}
    same = {}
    n_opp = 0
    for i, c in enumerate(cents):
        if areas[i] < 1e-8:
            continue
        for co, no, j, dist in bvh.find_nearest_range(c, tol):
            if j == i or j is None or areas[j] < 1e-8:
                continue
            d = norms[i].dot(norms[j])
            if abs(d) < 0.995:
                continue
            v = c - co
            off = v.dot(norms[j])
            if (v - norms[j] * off).length > 1e-4 or abs(off) > tol:
                continue
            if set(polys[i]) & set(polys[j]) and abs(off) < 1e-6 and d > 0:
                continue  # same-surface neighbour
            if d < 0:
                n_opp += 1
                k = i if areas[i] <= areas[j] else j
                if covered(k):
                    o, pi = owner[k]
                    kill.setdefault(o.data, set()).add(pi)
            else:
                key = tuple(sorted((owner[i][0].name, owner[j][0].name)))
                same.setdefault(key, []).append(round(abs(off), 4))
                if verbose and len(same[key]) == 1:
                    print("   at", tuple(round(x, 2) for x in c), "n", tuple(round(x, 2) for x in norms[i]))
    if fix and kill:
        for me, idx in kill.items():
            bm = bmesh.new()
            bm.from_mesh(me)
            bm.faces.ensure_lookup_table()
            bmesh.ops.delete(bm, geom=[bm.faces[k] for k in idx if k < len(bm.faces)], context="FACES")
            bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
            bm.to_mesh(me)
            bm.free()
    if verbose:
        print("opposite-facing hidden joint pairs: %d -> deleted %d faces in %d meshes" % (n_opp, sum(len(v) for v in kill.values()), len(kill)))
        print("same-facing stacked pairs (flicker): %d object pairs" % len(same))
        for k, offs in sorted(same.items(), key=lambda kv: -len(kv[1]))[:30]:
            print("   ", k, len(offs), "min offset", min(offs))
    return n_opp, len(same), same


# Camera fitted to Kaba_Aye_Paya_2.jpg (least squares on 14 points, rms 40 px): position, heading, pitch, focal length.
PHOTO2_FIT = dict(cam=(4.821, -49.955, 1.6), yaw=-1.584, pitch=15.737, f_px=1993.4)  # v2 fit (porch at 191 deg)


def set_photo2_fit():
    k = PHOTO2_FIT
    y, p = math.radians(k["yaw"]), math.radians(k["pitch"])
    fwd = Vector((math.sin(y) * math.cos(p), math.cos(y) * math.cos(p), math.sin(p)))
    c = Vector(k["cam"])
    return photo_cam(tuple(c), tuple(c + fwd * 10), k["f_px"] / 1920.0 * 36.0)
