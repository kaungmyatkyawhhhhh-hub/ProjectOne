# MEGA BITE sunken lighthouse v3 (13 Nov, skill roblox-3d-model-from-sheet; owner: "1:1 exact copy", "dont use lots of triangles").
# CONTRACT = the sheet's two ELEVATIONS: SIDE view (top row, the big one; camera at -Y, +X right) and FRONT view (camera at +X,
# +Y right). The sheet contradicts itself in two places (measured): (1) its top view draws the hill 111 studs deep where its
# front view draws it 168 wide, so the TOP view is reported but cannot be matched; (2) the door faces the camera in BOTH
# elevations, which one door cannot do, so the door sits half-way between them (45 deg), with the hole and the starfish kept
# at their measured angles relative to the door.
# Registration (measured): front: tower axis col 1159, floor row 998, 3.08 px/stud (462 px = 150 studs);
#   top: dome centre (437.7, 745.2), 3.06 px/stud, door points image-DOWN (+X), image-right = +Y; footprint y x0.93 (front/top compromise).
# Everything is measured or traced from the sheet: tower rows, hill skyline per column, hill footprint, kelp/coral/sponge/clam/
# starfish outlines (contour -> pillow meshes), door and hole outlines (boolean cuts: you can swim in). Triangle budget ~7K.
import sys; sys.path.insert(0, '/tmp/claude-0/lm'); sys.path.insert(0, '/tmp/claude-0/hk')
import lmkit as K, hk, math, random, bmesh, bpy, numpy as np, cv2
from mathutils import Vector
from scipy import ndimage as ndi
from scipy.spatial import Delaunay
from skimage.morphology import skeletonize
OUT = '/tmp/claude-0/lm/lh3'
SH, V, bb, _ = hk.analyse({'sheet': '/tmp/claude-0/hk/lighthouse/sheet.png', 'length': 100})
Rr, Gg, Bb = SH[..., 0], SH[..., 1], SH[..., 2]
SF, FCX, FBOT = 462 / 150, 1159.0, 998.0
ST, TCX, TCY, KY = 3.06, 437.7, 745.2, 0.93
S = 1 / SF; z_of = lambda row: (FBOT - row) * S; r_px = lambda px: px * S
FRONT, TOP, SIDE = V['front'], V['top'], V['side']
SS, SCX, SBOT = 501 / 150, 781.0, 515.0            # side view: tower axis col 781, floor row 515, 3.34 px/stud
DOOR_AZ = math.radians(-45)
green = (Gg > Rr + 18) & (Gg > Bb - 10) & (Gg > 70)
CLS = {'CoralPink': (Rr > 200) & (Gg < 150) & (Gg > 60) & (Bb < 150) & (Bb > 60), 'Starfish': (Rr > 225) & (Gg > 80) & (Gg < 150) & (Bb < 70),
       'Sponge': (Rr > 220) & (Gg > 170) & (Bb < 100), 'Teal': (Gg > 150) & (Bb > 140) & (Rr < 100),
       'Barnacle': (Rr > 185) & (Gg > 180) & (Bb > 165) & (abs(Rr - Bb) < 45)}
dark = (Rr < 50) & (Gg < 70) & (Bb < 95)
stone = (Bb > Rr + 12) & (Rr < 150) & (Gg < 170)
# ---------------------------------------------------------------- TEXTURE ATLAS (owner 13 Nov 02:18: "should have some texture")
# One 1024 px image for the whole model, every pixel taken from the approved sheet:
#   HILL  (0,0)    470x370  the sheet's TOP view of the rocks (kelp / coral / sponge / clam / roof painted out), 2 px per stud
#   TWF   (480,0)  226x417  the FRONT view's tower strip with kelp, coral and rocks painted out row by row (door, hole, chips kept)
#   TWB   (716,0)  226x417  the same strip with the door, hole, starfish and barnacles painted out too (for the back of the tower)
#   SIDE  (0,440)  550x376  the SIDE view as drawn (kelp, coral, sponges ... are cut from it, so they wear their own paint)
#   FRONT (560,440) 391x347 the FRONT view as drawn
#   swatches at the bottom: dark (inside the tower)
TEX = 1024; ATL = np.zeros((TEX, TEX, 3), np.float32)
def nearest_fill(img, valid):
    idx = ndi.distance_transform_edt(~valid, return_distances=False, return_indices=True); return img[idx[0], idx[1]]
def put(region, x0, y0, scale):
    h, w = region.shape[:2]; r = cv2.resize(region, (max(1, int(round(w * scale))), max(1, int(round(h * scale)))), interpolation=cv2.INTER_AREA)
    ATL[y0:y0 + r.shape[0], x0:x0 + r.shape[1]] = r; return r.shape
decor_px = green | CLS['CoralPink'] | CLS['Teal'] | (CLS['Sponge'])
rockc = (Bb > Rr + 30) & (Rr < 110) & ~dark
# FRONT / SIDE as drawn (background filled from the nearest paint so edges never show magenta)
fx0, fx1, fy0, fy1 = 893, 1414, 536, 998; sx0, sx1, sy0, sy1 = 374, 1107, 14, 515
magish = (Rr > 150) & (Bb > 150) & (Gg < 130)                         # pixels blended with the magenta key
er = lambda m: ndi.binary_erosion(m & ~magish, iterations=3)                    # the outline pixels are blended with the magenta key: never use them
put(nearest_fill(SH, er(FRONT))[fy0:fy1 + 1, fx0:fx1 + 1], 560, 440, 0.75); put(nearest_fill(SH, er(SIDE))[sy0:sy1 + 1, sx0:sx1 + 1], 0, 440, 0.75)
RF = [(672, 56), (720, 62), (760, 70), (816, 83), (860, 92), (874, 93), (998, 112)]          # the tower's half-width in the FRONT view (px by row)
def rfront(row):
    row = max(672.0, min(998.0, row))
    for (r0, w0), (r1, w1) in zip(RF, RF[1:]):
        if row <= r1: return w0 + (w1 - w0) * (row - r0) / (r1 - r0)
    return RF[-1][1]
# tower strips: row-wise fill (the bands are horizontal, so a hidden pixel takes the nearest visible pixel of its own row)
TX0 = int(FCX) - 125; strip = SH[fy0:fy1 + 1, TX0:TX0 + 251].copy(); smask = FRONT[fy0:fy1 + 1, TX0:TX0 + 251]
rowsz = (FBOT - (np.arange(fy0, fy1 + 1))) * S
def crop(m): return m[fy0:fy1 + 1, TX0:TX0 + 251]
low = (rowsz < 50)[:, None]
colsx = np.arange(TX0, TX0 + 251)[None, :]; rowsy = np.arange(fy0, fy1 + 1)
halfw = np.array([rfront(r) - 3 if r >= 672 else 999 for r in rowsy])[:, None]
smask = ndi.binary_erosion(smask & ~crop(magish), iterations=3) & (np.abs(colsx - FCX) <= halfw)          # only the tower itself is a source
bad_feat = ~smask | crop(ndi.binary_dilation(green, iterations=2)) | crop(CLS['CoralPink']) | crop(CLS['Teal']) | (crop(CLS['Sponge']) & low) | (crop(rockc) & low)
bad_all = bad_feat | ndi.binary_dilation(crop(dark), iterations=4) | ndi.binary_dilation(crop(CLS['Starfish']), iterations=3) | ndi.binary_dilation(crop(CLS['Barnacle']) & ~low, iterations=3)
def rowfill(img, bad):
    out = img.copy(); prev = None
    for r in range(img.shape[0]):
        ok = np.where(~bad[r])[0]
        if len(ok) < 6:
            if prev is not None: out[r] = prev
            continue
        k = np.clip(np.searchsorted(ok, np.arange(img.shape[1])), 0, len(ok) - 1); k2 = np.clip(k - 1, 0, len(ok) - 1)
        pick = np.where(np.abs(ok[k] - np.arange(img.shape[1])) <= np.abs(ok[k2] - np.arange(img.shape[1])), ok[k], ok[k2])
        out[r] = img[r, pick]; prev = out[r]
    return out
put(rowfill(strip, bad_feat), 480, 0, 0.9); put(rowfill(strip, bad_all), 716, 0, 0.9)
ATL[840:880, 0:40] = (17, 33, 51); ATL[840:880, 60:100] = (84, 119, 139); ATL[840:880, 120:160] = (45, 68, 88)
def UVpx(px, py): return (px / TEX, 1.0 - py / TEX)
def UVF(u, v): return UVpx(560 + (u - fx0) * 0.75, 440 + (v - fy0) * 0.75)            # sheet pixel (front view) -> atlas
def UVS(u, v): return UVpx(0 + (u - sx0) * 0.75, 440 + (v - sy0) * 0.75)              # sheet pixel (side view) -> atlas
def UVT(u, v, back=False): return UVpx((716 if back else 480) + min(250.0, max(0.0, u - TX0)) * 0.9, min(462.0, max(0.0, v - fy0)) * 0.9)
UVDARK = UVpx(20, 860); UVROCKTOP = UVpx(80, 860); UVROCKSIDE = UVpx(140, 860)
def set_uv(ob, fn):
    """fn(face) -> g(co) -> (u, v)"""
    bm = bmesh.new(); bm.from_mesh(ob.data); uvl = bm.loops.layers.uv.get('UVMap') or bm.loops.layers.uv.new('UVMap'); bm.normal_update()
    for f in bm.faces:
        g = fn(f)
        for l in f.loops: l[uvl].uv = g(l.vert.co)
    bm.to_mesh(ob.data); bm.free()
def uv_planar_front(f): return lambda co: UVT(FCX + co.y * SF, FBOT - co.z * SF)
def uv_tower(f):
    c = f.calc_center_median(); a0 = math.atan2(c.y, c.x); back = abs(a0) > math.pi / 2
    rad = math.hypot(c.x, c.y)
    if rad < tower_r(c.z) * (1.03 if c.z < ZB else 1.0) - 0.7 or (abs(f.normal.z) > 0.9 and rad < tower_r(c.z) - 0.2): return lambda co: UVDARK
    def g(co):
        a = math.atan2(co.y, co.x)
        if back: a = math.pi - a if a > 0 else -math.pi - a
        a = max(-math.pi / 2, min(math.pi / 2, a)); row = FBOT - co.z * SF
        return UVT(FCX + rfront(row) * math.sin(a) * 0.985, row, back)
    return g
K.reset(); rnd = random.Random(5)
for k_, c_ in dict(Red=(194, 68, 57), Cream=(232, 207, 149), Stone=(45, 68, 88), StoneTop=(84, 119, 139), StoneSide=(45, 68, 88), BaseStone=(126, 134, 146), DoorStone=(158, 164, 174),
                   Deck=(128, 78, 48), Gold=(244, 190, 43), Glass=(255, 226, 120), Dark=(17, 33, 51), Kelp=(73, 129, 44), CoralPink=(243, 93, 91),
                   Sponge=(244, 190, 43), Teal=(39, 178, 160), Barnacle=(232, 226, 212), Starfish=(246, 110, 40)).items(): K.mat(k_, c_)
SIDES = 20
# tower radius (studs) by height: measured in BOTH elevations and averaged where they differ (front flares to 30.2 at z=40,
# side only to 25.8; top of the cone 17.9 at z=105.8). Below z=40 the same slope continues to the floor.
TPROF = [(0.0, 34.2), (40.0, 28.0), (60.0, 24.9), (80.0, 20.6), (100.0, 18.6), (105.8, 17.9)]
def tower_r(z):
    z = max(0.0, min(105.8, z))
    for (z0, r0), (z1, r1) in zip(TPROF, TPROF[1:]):
        if z <= z1: return r0 + (r1 - r0) * (z - z0) / (z1 - z0)
    return TPROF[-1][1]
def ring_solid(profile, name, key, sides=SIDES):
    """a closed ring: the closed (r, z) profile turned round the axis"""
    bm = bmesh.new(); n = len(profile)
    vs = [[bm.verts.new((math.cos(2 * math.pi * i / sides) * r, math.sin(2 * math.pi * i / sides) * r, z)) for i in range(sides)] for (r, z) in profile]
    for k in range(n):
        a, b = vs[k], vs[(k + 1) % n]
        for i in range(sides): bm.faces.new((a[i], a[(i + 1) % sides], b[(i + 1) % sides], b[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces); return K.obj_from_bm(bm, name, key)
# ---------------------------------------------------------------- tower (rows measured in the front view)
ZTOP = z_of(672)                      # the cone ends under the deck (front row 672)
bands = [(672, 699, 'Cream'), (699, 748, 'Red'), (748, 796, 'Cream'), (796, 852, 'Red'), (852, 874, 'Cream')]
ZB = z_of(874); THICK = 2.5
zo = sorted({ZTOP, ZB} | {z_of(b_) for (_, b_, _) in bands} | {z for z, _ in TPROF if ZB < z < ZTOP}, reverse=True)       # outer skin: a ring at every band edge
outer = [(tower_r(z), z) for z in zo] + [(tower_r(ZB) * 1.03, ZB), (tower_r(0) * 1.03, 0.0)]
inner = [(tower_r(z) - THICK, z) for z in [0.0] + [z for z, _ in TPROF if 0 < z < ZTOP] + [ZTOP]]
tower = ring_solid(inner + outer, 'Tower', 'Dark')                               # ONE solid shell: outer skin + inner skin
shell = [tower]
K.lathe([(tower_r(0) - THICK, 0.0), (tower_r(0) - THICK, 0.5), (0.01, 0.55)], 'Floor', 'Dark', sides=SIDES)
# ---- door and hole: the dark shapes traced from the front view, cut through the front wall (EXACT booleans)
def comps(mask, min_px, zmin=-1, zmax=999, FBOT=FBOT, S=S):
    lab, n = ndi.label(mask); out = []
    for i in range(n):
        m = lab == i + 1; ys, xs = np.where(m)
        if len(xs) < min_px: continue
        zc = (FBOT - ys.mean()) * S
        if zmin <= zc <= zmax: out.append(m)
    return out
def contour(m, eps):
    cs, _ = cv2.findContours(m.astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    return cv2.approxPolyDP(max(cs, key=cv2.contourArea), eps, True)[:, 0, :].astype(float)
dk = ndi.binary_fill_holes(ndi.binary_closing(dark & FRONT, iterations=2))
door_m = [m for m in comps(dk, 3000, 5, 40)][0]; hole_m = [m for m in comps(dk, 800, 80, 105)][0]
def prism(m, x0, x1, grow=0.0):
    c = contour(m, 1.5); ctr = c.mean(0); c = ctr + (c - ctr) * (1 + grow)
    bm = bmesh.new(); f = [bm.verts.new((x1, (u - FCX) * S, (FBOT - v) * S)) for u, v in c]; b = [bm.verts.new((x0, (u - FCX) * S, (FBOT - v) * S)) for u, v in c]
    f1 = bm.faces.new(f); f2 = bm.faces.new(list(reversed(b)))
    for k in range(len(c)): bm.faces.new((b[k], b[(k + 1) % len(c)], f[(k + 1) % len(c)], f[k]))
    bmesh.ops.triangulate(bm, faces=[f1, f2]); bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return K.obj_from_bm(bm, 'Cutter', 'Dark'), c
cut_d, door_c = prism(door_m, 3, 60); cut_h, hole_c = prism(hole_m, 3, 40)
for ob in shell:
    for cu in (cut_d, cut_h):
        md = ob.modifiers.new('b', 'BOOLEAN'); md.operation = 'DIFFERENCE'; md.object = cu; md.solver = 'EXACT'
        bpy.context.view_layer.objects.active = ob; bpy.ops.object.modifier_apply(modifier=md.name)
for cu in (cut_d, cut_h): bpy.data.objects.remove(cu)
# colour the one shell by face: outer skin = the band it lies in (stone below the bands), everything else (inside, jambs) dark
def skin_key(f):
    c = f.calc_center_median(); rad = math.hypot(c.x, c.y)
    if rad < tower_r(c.z) * (1.03 if c.z < ZB else 1.0) - 0.7 or abs(f.normal.z) > 0.9 and rad < tower_r(c.z) - 0.2: return 'Dark'
    if c.z < ZB + 0.01: return 'BaseStone'
    for (a, b, key) in bands:
        if z_of(b) - 0.01 <= c.z <= z_of(a) + 0.01: return key
    return 'Cream'
bm0 = bmesh.new(); bm0.from_mesh(tower.data); bm0.normal_update(); bm0.faces.ensure_lookup_table()
keys = [skin_key(f) for f in bm0.faces]
for key in sorted(set(keys)):
    bmk = bm0.copy(); bmk.faces.ensure_lookup_table()
    bmesh.ops.delete(bmk, geom=[f for f, k in zip(bmk.faces, keys) if k != key], context='FACES'); K.obj_from_bm(bmk, 'Shell', key)
bm0.free(); bpy.data.objects.remove(tower)
DY = (door_c[:, 0].mean() - FCX) * S; DHW = (door_c[:, 0].max() - door_c[:, 0].min()) / 2 * S; DZ0 = (FBOT - door_c[:, 1].max()) * S
# stone blocks round the door arch + two steps
dc = door_c.mean(0); arc = [p for p in door_c if (FBOT - p[1]) * S > DZ0 + 3]
last = None
for p in arc:
    q = dc + (p - dc) * 1.17; y = (q[0] - FCX) * S; z = (FBOT - q[1]) * S
    if last is not None and math.hypot(y - last[0], z - last[1]) < 6.2: continue
    last = (y, z); rb = tower_r(z) * 1.03; ang = math.atan2(z - (FBOT - dc[1]) * S, y - (dc[0] - FCX) * S)
    bm = bmesh.new(); bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        lx, ly, lz = v.co.x * 3.0, v.co.y * 5.6, v.co.z * 4.4          # depth, along the arch, across it
        v.co = Vector((math.sqrt(max(1, rb * rb - y * y)) + 0.2 + lx, y + lz * math.cos(ang) - ly * math.sin(ang), z + lz * math.sin(ang) + ly * math.cos(ang)))
    K.obj_from_bm(bm, 'Blk', 'DoorStone')
for i in range(2):
    K.lathe([(DHW + 5 - i * 2.5, 0), (DHW + 5 - i * 2.5, 2.2 + i * 2.2), (0.01, 2.25 + i * 2.2)], 'Step', 'DoorStone', sides=10).location = (tower_r(0) + 5 - i * 4, DY, 0)
door_parts = [o for o in bpy.context.scene.objects if o.type == 'MESH']      # everything so far is built with the door facing +X
# ---------------------------------------------------------------- deck, rail, lantern, dome, ball (measured rows)
K.lathe([(tower_r(ZTOP) - 0.3, z_of(678)), (r_px(66), z_of(670)), (r_px(76), z_of(666)), (r_px(76), z_of(652)), (0.01, z_of(652))], 'Deck', 'Deck', sides=SIDES)
rr = r_px(72)
for k in range(12):
    a = 2 * math.pi * k / 12; p = Vector((math.cos(a) * rr, math.sin(a) * rr, z_of(653)))
    K.tube([p, Vector((p.x, p.y, z_of(626)))], [0.7, 0.7], 'Post', 'Gold', sides=4)
ring_solid([(rr - 0.9, z_of(629)), (rr + 0.9, z_of(629)), (rr + 0.9, z_of(623)), (rr - 0.9, z_of(623))], 'Rail', 'Gold', sides=16)
K.lathe([(r_px(46), z_of(652)), (r_px(46), z_of(622)), (0.01, z_of(622))], 'LanternBase', 'Deck', sides=12)
K.lathe([(r_px(42), z_of(622)), (r_px(42), z_of(592)), (0.01, z_of(592))], 'Glass', 'Glass', sides=12)
for k in range(6):
    a = 2 * math.pi * k / 6 + 0.26; p = Vector((math.cos(a) * r_px(43), math.sin(a) * r_px(43), z_of(622)))
    K.tube([p, Vector((p.x, p.y, z_of(592)))], [0.55, 0.55], 'Mullion', 'Deck', sides=4)
K.lathe([(r_px(47), z_of(593)), (r_px(49), z_of(588)), (r_px(48), z_of(584)), (r_px(42), z_of(580)), (r_px(33), z_of(572)), (r_px(19.5), z_of(564)), (r_px(9), z_of(560)), (0.01, z_of(559.5))], 'Dome', 'Red', sides=12)
K.lathe([(0.01, z_of(561)), (r_px(7), z_of(556)), (r_px(6.5), z_of(552)), (r_px(8.5), z_of(548)), (r_px(8.5), z_of(544)), (r_px(6), z_of(540)), (0.01, z_of(536))], 'Ball', 'Gold', sides=8)
import triangle as tr
def cdt(mc, eps, interior, split=True):
    """constrained Delaunay of a mask: its outline polygons (holes kept) + the given interior points"""
    cs, hier = cv2.findContours(mc.astype(np.uint8), cv2.RETR_CCOMP, cv2.CHAIN_APPROX_NONE)
    verts, segs, holes = [], [], []
    for ci, c in enumerate(cs):
        poly = cv2.approxPolyDP(c, eps, True)[:, 0, :].astype(float)
        if len(poly) < 3: continue
        if hier[0][ci][3] != -1:
            hm_ = np.zeros(mc.shape, np.uint8); cv2.drawContours(hm_, [c], -1, 1, -1); hy, hx = np.where((hm_ > 0) & ~mc)
            if not len(hx): continue
            k = len(hx) // 2; holes.append((float(hx[k]), float(hy[k])))
        base = len(verts); verts += [tuple(p) for p in poly]; segs += [(base + k, base + (k + 1) % len(poly)) for k in range(len(poly))]
    if len(verts) < 3: return None
    seen = {v: i for i, v in reversed(list(enumerate(verts)))}                  # merge duplicate outline points
    for p in interior:
        if tuple(p) not in seen: seen[tuple(p)] = len(verts); verts.append(tuple(p))
    A = dict(vertices=np.array(verts, float), segments=np.array([(seen[verts[a]], seen[verts[b]]) for a, b in segs if seen[verts[a]] != seen[verts[b]]], np.int32))
    if holes: A['holes'] = np.array(holes, float)
    try: B = tr.triangulate(A, 'p')
    except Exception: return None
    if 'triangles' not in B or not len(B['triangles']): return None
    pts = [tuple(p) for p in B['vertices']]; tris = [tuple(int(v) for v in t) for t in B['triangles']]
    for it in range(3 if split else 0):                # a triangle made only of outline points gets a centre point (so it has thickness)
        ec = {}
        for t in tris:
            for a, b in ((t[0], t[1]), (t[1], t[2]), (t[2], t[0])): ec[(min(a, b), max(a, b))] = ec.get((min(a, b), max(a, b)), 0) + 1
        bnd = {v for e, n in ec.items() if n == 1 for v in e}; out = []; changed = False
        for t in tris:
            if all(v in bnd for v in t):
                m = len(pts); pts.append(tuple(np.mean([pts[v] for v in t], 0))); out += [(t[0], t[1], m), (t[1], t[2], m), (t[2], t[0], m)]; changed = True
            else: out.append(t)
        tris = out
        if not changed: break
    if not split:
        ec = {}
        for t in tris:
            for a, b in ((t[0], t[1]), (t[1], t[2]), (t[2], t[0])): ec[(min(a, b), max(a, b))] = ec.get((min(a, b), max(a, b)), 0) + 1
        return np.array(pts), tris, [e for e, n in ec.items() if n == 1]
    return np.array(pts), tris, bnd
# ---------------------------------------------------------------- hill: footprint from the TOP view, skyline from the FRONT view
xs_g = np.arange(-130, 105); ys_g = np.arange(-92, 93)                     # 1-stud lattice
XX, YY = np.meshgrid(xs_g, ys_g, indexing='ij')
decor_any = green.copy()
for cm_ in CLS.values(): decor_any |= cm_
def skyline(mask, cx, bot, sc, coords):
    """per column: the top of the hill = the highest silhouette pixel below z=46 that is not kelp / coral / sponge / clam / starfish.
    Under the tower the hill is hidden in this view, so it is left free (46) and the other elevation decides (visual hull)."""
    out = np.zeros(len(coords)); st = mask & ~decor_any
    for j, c in enumerate(coords):
        col = int(round(cx + c * sc))
        if 0 <= col < mask.shape[1]:
            rws = np.where(st[int(bot - 46 * sc):, col])[0]
            if len(rws): out[j] = 46 - rws.min() / sc
    out[np.abs(coords) < tower_r(40) - 1] = 46
    return ndi.gaussian_filter1d(ndi.median_filter(out, 7), 3.0), ndi.minimum_filter1d(ndi.median_filter(out, 5), 9)
(Ssky, Scap) = skyline(SIDE, SCX, SBOT, SS, xs_g); (Fsky, Fcap) = skyline(FRONT, FCX, FBOT, SF, ys_g)
# footprint: the top view's outline, stretched to the extents the two elevations measure (x -122..96, y -84..84)
Topen = ndi.binary_opening(TOP, iterations=5)
kx = np.where(XX < 0, 105.0 / 122.0, 91.0 / 96.0); ky = np.where(YY > 0, 45.0 / 84.0, 66.0 / 84.0)
uu = np.clip(np.round(TCX + XX * kx * ST).astype(int), 0, TOP.shape[1] - 1); vv = np.clip(np.round(TCY - YY * ky * ST).astype(int), 0, TOP.shape[0] - 1)
foot = Topen[vv, uu]
dist = ndi.distance_transform_edt(foot)
RBASE = tower_r(0)
Sm = np.clip(Ssky, 0.5, 46)[:, None]; Fm = np.clip(Fsky, 0.5, 46)[None, :]
Hraw = 1.0 / np.sqrt(np.clip(1 / Sm ** 2 + 1 / Fm ** 2 - 1 / 46.0 ** 2, 1e-6, None))        # rounded min: = S where F is free (46) and the reverse
Hcap = np.minimum(Scap[:, None], Fcap[None, :])            # nothing on the hill may rise above this (the lower of the two skylines)
Hh = np.clip(np.minimum(Hraw - 5.0, Hcap - 1.0), 0, None) * np.clip(dist / 10.0, 0, 1) ** 0.7
ca, sa = math.cos(-DOOR_AZ), math.sin(-DOOR_AZ); XD = XX * ca - YY * sa; YD = XX * sa + YY * ca       # door-frame coordinates
Hh = np.where(XD > 0, Hh * np.clip((np.abs(YD - DY) - (DHW + 1.5)) / 9.0, 0, 1), Hh)             # the path to the door: a V-shaped cut
Hh[np.hypot(XX, YY) < RBASE - 2.5] = 0                                          # nothing inside the tower
def hgt(x, y):
    i = int(round(x)) - xs_g[0]; j = int(round(y)) - ys_g[0]
    return float(Hh[i, j]) if 0 <= i < Hh.shape[0] and 0 <= j < Hh.shape[1] else 0.0
hm = ndi.binary_opening(Hh > 0.5, iterations=1)                              # footprint of the hill body (holes: tower, path)
gi, gj = np.where(ndi.distance_transform_edt(hm)[::13, ::13] > 4)
pts, tris, bnd = cdt(hm.T, 2.4, [(float(i * 13), float(j * 13)) for i, j in zip(gi, gj)])      # image x = model x lattice, image y = model y lattice
bm = bmesh.new(); tvv, bvv_ = {}, {}
for v in sorted({v for t in tris for v in t}):
    x = pts[v][0] + xs_g[0]; y = pts[v][1] + ys_g[0]
    bvv_[v] = bm.verts.new((x, y, 0.0)); tvv[v] = bvv_[v] if v in bnd else bm.verts.new((x, y, max(0.8, hgt(x, y))))
for t in tris:
    try: bm.faces.new((tvv[t[0]], tvv[t[1]], tvv[t[2]])); bm.faces.new((bvv_[t[2]], bvv_[t[1]], bvv_[t[0]]))
    except ValueError: pass
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
K.obj_from_bm(bm, 'FlatHill', 'Stone')
# ---- boulders (two-tone: lighter top faces as in the sheet), sunk into the hill
def boulder(c, size, seed):
    from mathutils import noise
    bm = bmesh.new(); bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0); off = Vector((seed * 3.1, seed * 1.7, seed * 2.3))
    for v in bm.verts:
        d = 1 + 0.22 * noise.noise(v.co * 1.4 + off); p = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2])) * d
        if p.z < -size[2] * 0.4: p.z = -size[2] * 0.4
        v.co = p + c
        if v.co.z < 0: v.co.z = 0.0
    bm.normal_update()
    top = [f for f in bm.faces if f.normal.z > 0.5]
    bm2 = bm.copy(); bmesh.ops.delete(bm2, geom=[f for f in bm2.faces if f.normal.z > 0.5], context='FACES')
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.normal.z <= 0.5], context='FACES')
    K.obj_from_bm(bm, 'FlatRockTop', 'StoneTop'); K.obj_from_bm(bm2, 'FlatRock', 'StoneSide')
rocks = []
for t in range(4000):
    if len(rocks) >= 54: break
    x = rnd.uniform(xs_g[0] + 4, xs_g[-1] - 4); y = rnd.uniform(ys_g[0] + 4, ys_g[-1] - 4)
    i = int(round(x)) - xs_g[0]; j = int(round(y)) - ys_g[0]
    sz = rnd.uniform(8.5, 14.0)
    if not foot[i, j] or dist[i, j] < sz * 0.55 or (XD[i, j] > 0 and abs(YD[i, j] - DY) < DHW + 3 + sz * 0.8) or math.hypot(x, y) < RBASE + sz * 0.75: continue
    if any(math.hypot(x - a, y - b) < 0.64 * (sz + s2) for a, b, s2 in rocks): continue
    szz = sz * rnd.uniform(0.5, 0.65); r_ = int(sz * 0.6)
    cap = float(Hcap[max(0, i - r_):i + r_ + 1, max(0, j - r_):j + r_ + 1].min())
    if cap < 3.5: continue
    szz = min(szz, cap / 0.95)                    # a rock at the rim is flatter, never taller than the skyline there
    rocks.append((x, y, sz)); boulder(Vector((x, y, min(hgt(x, y) + sz * 0.05, cap - szz * 0.62))), (sz, sz * rnd.uniform(0.8, 1.1), szz), len(rocks))
# ---------------------------------------------------------------- traced pillows (contour-to-mesh): kelp, coral, sponge, clam, starfish
def pillow(m, to3d, name, key, dscale, eps=1.5, step=10, back=1.0, flat=False, S=S, slab=0.0, uvfn=None):
    ys, xs = np.where(m); y0, x0 = ys.min() - 2, xs.min() - 2; mc = m[y0:ys.max() + 3, x0:xs.max() + 3]
    if slab:                                 # a flat ribbon of constant thickness (kelp): outline only, front + back + rim
        R_ = cdt(mc, eps, [], split=False)
        if R_ is None: return 0
        pts, tris, bedges = R_; bm = bmesh.new(); uvl = bm.loops.layers.uv.new('UVMap'); pix = {}
        fv = {v: bm.verts.new(to3d(pts[v][0] + x0, pts[v][1] + y0, slab)) for v in sorted({v for t in tris for v in t})}
        bv = {v: bm.verts.new(to3d(pts[v][0] + x0, pts[v][1] + y0, -slab)) for v in fv}
        for v in fv: pix[fv[v]] = pix[bv[v]] = uvfn(pts[v][0] + x0, pts[v][1] + y0)
        for t in tris: bm.faces.new((fv[t[0]], fv[t[1]], fv[t[2]])); bm.faces.new((bv[t[2]], bv[t[1]], bv[t[0]]))
        for a, b in bedges: bm.faces.new((fv[a], fv[b], bv[b], bv[a]))
        for f in bm.faces:
            for l in f.loops: l[uvl].uv = pix[l.vert]
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces); K.obj_from_bm(bm, ('Flat' if flat else '') + name, key)
        return 2 * len(tris) + 2 * len(bedges)
    d = ndi.distance_transform_edt(mc); sk = skeletonize(mc)
    if not sk.any(): return 0
    idx = ndi.distance_transform_edt(~sk, return_distances=False, return_indices=True); w = np.maximum(d[idx[0], idx[1]], d)
    dep = np.sqrt(np.clip(w * w - (w - d) ** 2, 0, None)) * dscale
    sy, sx = np.where(sk & (d > 2.0)); order = np.argsort(sy * 10000 + sx); inter = [(float(sx[k]), float(sy[k])) for k in order[::step]]
    gy_, gx_ = np.where(d[::step, ::step] > step * 0.7); inter += [(float(x * step), float(y * step)) for x, y in zip(gx_, gy_)]
    R_ = cdt(mc, eps, inter)
    if R_ is None: return 0
    pts, tris, bnd = R_
    bm = bmesh.new(); fv, bvv = {}, {}; uvl = bm.loops.layers.uv.new('UVMap'); pix = {}
    H_, W_ = dep.shape
    for v in sorted({v for t in tris for v in t}):
        u, vv_ = pts[v]; dd = 0.0 if v in bnd else max(0.3, float(dep[min(H_ - 1, max(0, int(vv_))), min(W_ - 1, max(0, int(u)))]) / 1.0 * S)
        fv[v] = bm.verts.new(to3d(u + x0, vv_ + y0, dd)); bvv[v] = fv[v] if v in bnd else bm.verts.new(to3d(u + x0, vv_ + y0, -dd * back))
        pix[fv[v]] = pix[bvv[v]] = uvfn(u + x0, vv_ + y0)
    n = 0
    for t in tris:
        try: bm.faces.new((fv[t[0]], fv[t[1]], fv[t[2]])); bm.faces.new((bvv[t[2]], bvv[t[1]], bvv[t[0]])); n += 2
        except ValueError: pass
    for f in bm.faces:
        for l in f.loops: l[uvl].uv = pix[l.vert]
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    K.obj_from_bm(bm, ('Flat' if flat else '') + name, key); return n
def tsurf(c, z):                            # the tower's surface distance from the axis plane at offset c
    r = tower_r(min(z, ZTOP)) + (r_px(76) - tower_r(ZTOP) if z > ZTOP - 2 else 0)
    return math.sqrt(r * r - c * c) if abs(c) < r else -1e9
ntri = 0
DSC = {'CoralPink': 1.0, 'Sponge': 1.0, 'Teal': 0.8, 'Starfish': 0.4, 'Barnacle': 0.7}
for vname, mask, cx, bot, sc in (('F', FRONT, FCX, FBOT, SF), ('S', SIDE, SCX, SBOT, SS)):
    Sv = 1 / sc; UVV = UVF if vname == 'F' else UVS
    def P3(c, z, depth, vname=vname):       # c = sideways coordinate in the view, depth = toward that view's camera
        return Vector((depth, c, z)) if vname == 'F' else Vector((c, -depth, z))
    def root(cb, zb, vname=vname):          # the spot nearest the camera where the base is buried at least 1 stud in the hill
        best, bh = 0.0, -1e9
        for t in range(110, -110, -1):
            x, y = (t, cb) if vname == 'F' else (cb, -t)
            if math.hypot(x, y) < RBASE + 2: continue
            h = hgt(x, y)
            if h >= zb + 1.0: return float(t), h
            if h > bh: best, bh = float(t), h
        return best, bh
    floaters = []
    # kelp: on the plane through the tower axis, wrapped onto the tower where it crosses in front of it, waving in depth
    gk = ndi.binary_opening(green & mask, iterations=1)
    gk = gk | (ndi.binary_closing(gk, structure=np.ones((13, 5)), iterations=1) & mask)      # re-join strands cut by things drawn in front of them
    for m in comps(gk, 400, FBOT=bot, S=Sv):
        ys, xs = np.where(m); cc = (xs - cx) * Sv; zz = (bot - ys) * Sv
        if zz.min() > 48: print('  dropped a kelp fragment that hangs in mid-air in the sheet (z %.0f-%.0f)' % (zz.min(), zz.max())); continue
        rr_ = np.array([tower_r(z) for z in zz]); over = (np.abs(cc) < rr_) & (zz > 30)
        # a strand that crosses in front of the tower stands on a flat plane just in front of it; the others stand beside the
        # tower on the plane through its axis. A slow wave in depth so it is not a flat card.
        d0 = float(rr_[over].max()) + 3.0 if over.mean() > 0.03 else 0.0
        ph = rnd.uniform(0, 6)
        def to3d(u, v, d, ph=ph, d0=d0):
            c = (u - cx) * Sv; z = (bot - v) * Sv
            return P3(c, z, d0 + 2.5 * math.sin(z / 17.0 + ph) * min(1.0, max(0.0, (z - 20) / 30.0)) + d)
        lo = ys > ys.max() - 6; cb = float(cc[lo].mean()); zb = float(zz.min()); px_, py_ = (d0, cb) if vname == 'F' else (cb, -d0)
        if hgt(px_, py_) < zb + 0.5:
            floaters.append('Kelp z%.0f at (%.0f,%.0f) h%.0f' % (zb, px_, py_, hgt(px_, py_))); boulder(Vector((px_, py_, max(1.0, zb - 3.0))), (7.0, 7.0, 5.5), int(abs(cb * 5 + zb)))
        ntri += pillow(m, to3d, 'KelpP', 'Kelp', 0.22, eps=2.6, flat=True, S=Sv, slab=0.9, uvfn=UVV)
    for key, cm in CLS.items():
        cm = ndi.binary_closing(cm & mask, iterations=2 if key == 'Barnacle' else 1)
        for m in comps(cm, 90 if key == 'Barnacle' else 40, -1, 125, FBOT=bot, S=Sv):
            ys, xs = np.where(m); cc = (xs.mean() - cx) * Sv; zc = (bot - ys.mean()) * Sv
            on_tower = zc > 40 or (abs(cc) < tower_r(zc) * 0.9 and zc > 36)
            if on_tower:
                if vname != 'F' or key not in ('Starfish', 'Barnacle') or zc > ZTOP: continue
                def to3d(u, v, d):                      # wrapped onto the tower's cone (door frame: rotated with the door later)
                    y = (u - cx) * Sv; z = (bot - v) * Sv; r = tower_r(z); a = math.asin(max(-0.98, min(0.98, y / r))); R = r + 0.15 + d
                    return Vector((R * math.cos(a), R * math.sin(a), z))
                n0 = len(bpy.context.scene.objects)
                ntri += pillow(m, to3d, key + 'T', key, 0.5, eps=2.0, step=14, back=0.25, S=Sv, uvfn=UVV)
                door_parts += [o for o in list(bpy.context.scene.objects)[n0:]]
            else:
                lo = ys > ys.max() - max(2, (ys.max() - ys.min()) * 0.12); cb = (xs[lo].mean() - cx) * Sv; zb = (bot - ys.max()) * Sv
                t0, h0 = root(cb, zb)
                if h0 < zb + 0.5:                       # nothing that high there: a rock under it so it never floats
                    px_, py_ = (t0, cb) if vname == 'F' else (cb, -t0); floaters.append(key)
                    boulder(Vector((px_, py_, max(1.0, zb - 2.5))), (5.5, 5.5, 4.5), int(abs(cb * 7 + zb)))
                ntri += pillow(m, lambda u, v, d, t0=t0: P3((u - cx) * Sv, (bot - v) * Sv, t0 + d), key + 'P', key, DSC[key], eps=2.7 if key == 'CoralPink' else 3.0, step=20 if key == 'CoralPink' else 22, S=Sv, uvfn=UVV)
    print('view', vname, 'given a support rock (were not on the hill):', floaters)
# hill texture: the sheet's top view through the same stretch as the footprint, things that are 3D in the model painted out
hx = np.arange(470) / 2.0 - 130; hy = np.arange(370) / 2.0 - 92; HX_, HY_ = np.meshgrid(hx, hy, indexing='xy')
hu = np.clip(np.round(TCX + HX_ * np.where(HX_ < 0, 105.0 / 122.0, 91.0 / 96.0) * ST).astype(int), 0, TOP.shape[1] - 1)
hv = np.clip(np.round(TCY - HY_ * np.where(HY_ > 0, 45.0 / 84.0, 66.0 / 84.0) * ST).astype(int), 0, TOP.shape[0] - 1)
# the tower's own rings in the top view (radius 170 px) and the things that are 3D in the model are painted out (soft rock tones);
# the real rock paint stays at the two ends of the hill
uu_, vv_ = np.meshgrid(np.arange(TOP.shape[1]), np.arange(TOP.shape[0])); rho = np.hypot(uu_ - TCX, vv_ - TCY)
badt = ~ndi.binary_erosion(TOP, iterations=3) | ndi.binary_dilation(decor_px | (Rr > Bb + 12), iterations=3) | (rho < 120)      # rocks are blue: anything warm is not rock
himg = SH[hv, hu]; hbad = badt[hv, hu]
himg = cv2.inpaint(np.clip(himg, 0, 255).astype(np.uint8), ndi.binary_dilation(hbad, iterations=2).astype(np.uint8), 5, cv2.INPAINT_TELEA).astype(np.float32)
ATL[0:370, 0:470] = himg
from PIL import Image as _I
_I.fromarray(np.clip(ATL, 0, 255).astype(np.uint8)).save(OUT + '/MB_LM_Lighthouse_atlas.png')
def uv_top(f): return lambda co: UVpx((co.x + 130) * 2.0, (co.y + 92) * 2.0)
from mathutils import Matrix
for o in door_parts:                                   # these are still in the door frame (door facing +X)
    base = o.name.split('__')[0].replace('Flat', '')
    if base.endswith('T') and base != 'RockT': continue          # wrapped starfish / barnacles carry their own UVs
    key = o.name.split('__')[-1].split('.')[0]
    if base == 'Shell': set_uv(o, (lambda f: (lambda co: UVDARK)) if key == 'Dark' else uv_tower)
    elif base == 'Floor': set_uv(o, lambda f: (lambda co: UVDARK))
    else: set_uv(o, uv_planar_front)
for o in door_parts: o.data.transform(Matrix.Rotation(DOOR_AZ, 4, 'Z'))
dset = set(door_parts)
for o in bpy.context.scene.objects:
    if o.type != 'MESH' or o in dset: continue
    base = o.name.split('__')[0]
    if base.endswith('P') or base.endswith('T'): continue          # traced pillows carry their own UVs
    if base == 'FlatHill': set_uv(o, uv_top)
    elif base == 'FlatRockTop': set_uv(o, lambda f: (lambda co: UVROCKTOP))
    elif base == 'FlatRock': set_uv(o, lambda f: (lambda co: UVROCKSIDE))
    else: set_uv(o, uv_planar_front)                   # deck, rail, lantern, dome, ball: the front view turned round the axis
print('pillow tris', ntri, 'rocks', len(rocks))
# ---------------------------------------------------------------- shading, join, export
for o in bpy.context.scene.objects:
    if o.type != 'MESH': continue
    bm = bmesh.new(); bm.from_mesh(o.data)
    if o.name.startswith('Flat') or o.name.startswith('Blk'):
        for f in bm.faces: f.smooth = False
    else:
        sharp = [e for e in bm.edges if len(e.link_faces) == 2 and e.calc_face_angle(0) > math.radians(38)]
        if sharp: bmesh.ops.split_edges(bm, edges=sharp)
        for f in bm.faces: f.smooth = True
    bm.to_mesh(o.data); bm.free()
K.join_by_key()
img = bpy.data.images.load(OUT + '/MB_LM_Lighthouse_atlas.png')
mt = bpy.data.materials.new('Atlas'); mt.use_nodes = True; tn = mt.node_tree.nodes.new('ShaderNodeTexImage'); tn.image = img
mt.node_tree.links.new(tn.outputs['Color'], mt.node_tree.nodes['Principled BSDF'].inputs['Base Color']); mt.node_tree.nodes.active = tn
for o in bpy.context.scene.objects:
    if o.type == 'MESH': o.data.materials.clear(); o.data.materials.append(mt)
print('TRIS', K.tris(), {o.name: len(o.data.polygons) for o in bpy.context.scene.objects if o.type == 'MESH'})
K.export(OUT + '/MB_LM_Lighthouse_v4.fbx'); K.export_obj(OUT + '/model.obj')
