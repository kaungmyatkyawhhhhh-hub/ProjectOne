# MEGA BITE sunken lighthouse v2 (13 Nov, skill roblox-3d-model-from-sheet). Every size below is MEASURED from the
# approved sheet's FRONT view (mb_sheet_lm_lighthouse.png, rows/cols in px; 462 px tall = 150 studs, so 0.3247 studs/px):
#   lantern ball rows 536-550, dome 548-570, lantern 568-624 (glass 589-623, half-width 42-48 px), deck 624-648 (half 69),
#   red band 649-675, cream 675-699, red 699-748, cream 748-796, red 796-852, cream 852-874, stone door base 874-960,
#   tower half-width 58 px at row 650 -> 92 px at row 870, hill to row 998 (half-width 260 px at the bottom).
import sys; sys.path.insert(0, '/tmp/claude-0/lm')
import lmkit as K, math, random
from mathutils import Vector
S = 150 / 462; BOT = 998
z = lambda row: (BOT - row) * S
r = lambda px: px * S
K.reset()
K.mat('Red', (194, 68, 57)); K.mat('Cream', (232, 207, 149)); K.mat('Stone', (53, 79, 101)); K.mat('Stone2', (78, 104, 128)); K.mat('BaseStone', (120, 128, 140))   # medians sampled from the sheet
K.mat('Deck', (128, 78, 48)); K.mat('Gold', (246, 190, 70)); K.mat('Glass', (255, 226, 120)); K.mat('Dark', (22, 34, 50)); K.mat('Kelp', (73, 129, 44))
K.mat('KelpLight', (104, 162, 58)); K.mat('CoralPink', (243, 93, 91)); K.mat('Sponge', (244, 190, 43)); K.mat('Teal', (39, 178, 160)); K.mat('Barnacle', (236, 232, 222))
K.mat('Starfish', (246, 110, 40))
rnd = random.Random(5)
def tower_r(row):          # straight taper measured at rows 650 and 870
    t = (row - 650) / (870 - 650); return r(58 + (92 - 58) * t)
# --- tower bands (measured rows)
bands = [(649, 675, 'Red'), (675, 699, 'Cream'), (699, 748, 'Red'), (748, 796, 'Cream'), (796, 852, 'Red'), (852, 874, 'Cream')]
for (a, b, key) in bands:
    K.lathe([(tower_r(b), z(b)), (tower_r(a), z(a))], f'B{a}', key, sides=32, cap=True)
K.lathe([(tower_r(649) * 1.0, z(649)), (0.01, z(649) + 0.2)], 'TopCap', 'Red', sides=32)
# --- stone base with the door (rows 874-960)
K.lathe([(tower_r(960) * 1.06, z(962)), (tower_r(874) * 1.04, z(874)), (tower_r(874) * 0.98, z(872))], 'Base', 'BaseStone', sides=32, jitter=0.02, seed=4)
dc = Vector((tower_r(920) * 1.03, 0, z(960)))
door = [Vector((0, math.cos(math.pi * k / 14) * r(46), r(46) + math.sin(math.pi * k / 14) * r(46))) for k in range(15)]
door = [Vector((0, r(46), 0))] + door + [Vector((0, -r(46), 0))]
import bmesh
bm = bmesh.new(); f1 = [bm.verts.new(dc + p + Vector((0.8, 0, 0))) for p in door]; f0 = [bm.verts.new(dc + p + Vector((-3.0, 0, 0))) for p in door]
bm.faces.new(f1); bm.faces.new(list(reversed(f0)))
for k in range(len(door)): bm.faces.new((f0[k], f0[(k + 1) % len(door)], f1[(k + 1) % len(door)], f1[k]))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces); K.obj_from_bm(bm, 'Door', 'Dark')
frame = [dc + Vector((0.9, math.cos(math.pi * k / 14) * r(56), r(46) + math.sin(math.pi * k / 14) * r(56))) for k in range(15)]
frame = [frame[0] + Vector((0, 0, -r(46)))] + frame + [frame[-1] + Vector((0, 0, -r(46)))]
K.tube(frame, [r(9)] * len(frame), 'DoorFrame', 'Stone2', sides=8)
# --- deck (rows 624-648, half-width 69 px) + gold rail + lantern (568-624) + dome (548-570) + ball (536-550)
K.lathe([(tower_r(649) * 1.02, z(650)), (r(69), z(640)), (r(69), z(628)), (r(60), z(624))], 'Deck', 'Deck', sides=32)
rr = r(64)
for k in range(18):
    a = 2 * math.pi * k / 18
    K.tube([Vector((math.cos(a) * rr, math.sin(a) * rr, z(626))), Vector((math.cos(a) * rr, math.sin(a) * rr, z(604)))], [0.6, 0.6], 'Post', 'Gold', sides=6)
K.tube([Vector((math.cos(2 * math.pi * k / 48) * rr, math.sin(2 * math.pi * k / 48) * rr, z(604))) for k in range(49)], [0.8] * 49, 'Rail', 'Gold', sides=6, cap=True)
K.lathe([(r(46), z(624)), (r(46), z(618)), (r(44), z(616))], 'LanternBase', 'Deck', sides=24)
K.lathe([(r(42), z(616)), (r(42), z(574))], 'Glass', 'Glass', sides=16)
for k in range(8):
    a = 2 * math.pi * k / 8 + 0.2
    K.tube([Vector((math.cos(a) * r(43), math.sin(a) * r(43), z(616))), Vector((math.cos(a) * r(43), math.sin(a) * r(43), z(574)))], [0.55, 0.55], 'Mullion', 'Deck', sides=6)
K.lathe([(r(50), z(574)), (r(50), z(568)), (r(40), z(560)), (r(22), z(552)), (r(8), z(549)), (0.01, z(548))], 'Dome', 'Red', sides=24)
K.lathe([(0.01, z(551)), (r(7), z(546)), (r(8), z(542)), (r(6), z(538)), (0.01, z(536))], 'Ball', 'Gold', sides=12)
# --- broken hole high on the right (centre col +37 px from the axis, rows 672-704)
hz = z(688); hr = tower_r(688); a = math.asin(min(0.9, r(37) / hr))
n = Vector((math.cos(a), math.sin(a), 0)); t1 = n.cross(Vector((0, 0, 1))).normalized()
bm = bmesh.new(); ring = []
for k in range(12):
    th = 2 * math.pi * k / 12; rad = r(17) * (1 + 0.22 * math.sin(k * 2.9))
    ring.append(bm.verts.new(Vector((0, 0, hz)) + n * (hr + 0.25) + t1 * math.cos(th) * rad + Vector((0, 0, math.sin(th) * rad * 1.15))))
inner = [bm.verts.new(v.co - n * 3.0) for v in ring]
bm.faces.new(ring); bm.faces.new(list(reversed(inner)))
for k in range(12): bm.faces.new((inner[k], inner[(k + 1) % 12], ring[(k + 1) % 12], ring[k]))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces); K.obj_from_bm(bm, 'Hole', 'Dark')
# --- barnacle clusters and a starfish on the tower (front view positions)
def on_tower(row, dx_px, out=0.3):
    rad = tower_r(row); a_ = math.asin(max(-0.95, min(0.95, r(dx_px) / rad)))
    return Vector((math.cos(a_) * (rad + out), math.sin(a_) * (rad + out), z(row))), Vector((math.cos(a_), math.sin(a_), 0))
for (row, dx) in ((724, 4), (790, 30), (812, -40), (668, -20), (884, 50)):
    p, n_ = on_tower(row, dx)
    for j in range(5):
        K.rock(p + Vector((0, rnd.uniform(-2, 2), rnd.uniform(-2, 2))), (1.2, 1.2, 1.1), 'Barn', 'Barnacle', seed=row + j, sub=1, rough=0.1, flat_bottom=False)
p, n_ = on_tower(770, -12, 0.6)
star = []
for k in range(10):
    rad = r(22) if k % 2 == 0 else r(9); th = 2 * math.pi * k / 10 + math.pi / 2
    t1 = n_.cross(Vector((0, 0, 1))).normalized(); star.append(p + t1 * math.cos(th) * rad + Vector((0, 0, math.sin(th) * rad)))
bm = bmesh.new(); vs = [bm.verts.new(q) for q in star]; c = bm.verts.new(p + n_ * 1.2); cb = bm.verts.new(p - n_ * 1.0)
for k in range(10): bm.faces.new((vs[k], vs[(k + 1) % 10], c)); bm.faces.new((vs[(k + 1) % 10], vs[k], cb))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
K.obj_from_bm(bm, 'Star', 'Starfish')
# --- rocky hill (rows 874-998, half-width 92 px at the top -> 260 px at the bottom): a ring of big stones + a core
HX, HY, HOFF = 104 / 60, 1.0, -10.0
HYOFF = -13.0
hc = K.lathe([(60, 0), (56, 14), (48, 27), (38, 35), (tower_r(874) * 1.02, 38)], 'HillCore', 'Stone', sides=32, jitter=0.06, seed=2)
for v in hc.data.vertices:
    k_ = min(1.0, max(0.0, (math.hypot(v.co.x, v.co.y) - tower_r(874)) / (60 - tower_r(874))))
    v.co.x = v.co.x * (1 + (HX - 1) * k_) + HOFF * k_
    v.co.y = v.co.y + HYOFF * k_
for i in range(22):
    a = i / 22 * 2 * math.pi + rnd.uniform(-0.1, 0.1); rr2 = rnd.uniform(46, 66 - 4)
    hz2 = max(2.0, 4 + (60 - rr2) * 1.1)
    K.rock(Vector((math.cos(a) * rr2 * HX + HOFF, math.sin(a) * rr2 + HYOFF, hz2)), (rnd.uniform(9, 14), rnd.uniform(9, 13), rnd.uniform(6, 9)), 'Stone', 'Stone2' if i % 3 == 0 else 'Stone', seed=40 + i, sub=2, rough=0.25)
# --- kelp: 7 tall ribbons around the tower (front view: 3 left, 3 right, 1 behind), reaching row ~640
# kelp = contour-to-mesh (cc-blender-skill): the sheet's own kelp shapes, traced from the FRONT view (placed on the
# y-z plane through the tower axis) and from the SIDE view (on the x-z plane), as flat leaf ribbons 1.6 studs thick.
import numpy as np, cv2
sys.path.insert(0, '/tmp/claude-0/hk'); import hk
from scipy import ndimage as ndi
SHp, Vp, bbp, _ = hk.analyse({'sheet': '/tmp/claude-0/hk/lighthouse/sheet.png', 'length': 100})
Rr, Gg, Bb = SHp[..., 0], SHp[..., 1], SHp[..., 2]
green = (Gg > Rr + 18) & (Gg > Bb - 10) & (Gg > 70)
from scipy.spatial import Delaunay
def contour_ribbons(view, to3d, key, thick=1.6):
    """mask -> boundary points (outer + holes) + interior grid -> Delaunay -> keep triangles inside the mask -> slab"""
    m = ndi.binary_opening(green & Vp[view], iterations=1)
    lab, n = ndi.label(m); sz = ndi.sum(m, lab, range(1, n + 1))
    for i in range(n):
        if sz[i] < 400: continue
        mi = (lab == i + 1)
        cs, _ = cv2.findContours(mi.astype(np.uint8), cv2.RETR_CCOMP, cv2.CHAIN_APPROX_NONE)
        pts = []
        for c in cs:
            c = cv2.approxPolyDP(c, 1.0, True)[:, 0, :]; pts += [tuple(p) for p in c]
        ys, xs = np.where(mi[::6, ::6]); pts += [(x * 6, y * 6) for x, y in zip(xs, ys)]
        pts = np.unique(np.array(pts, float), axis=0)
        if len(pts) < 4: continue
        tri = Delaunay(pts); keep = []
        er = ndi.binary_dilation(mi, iterations=1)
        for t in tri.simplices:
            cx_, cy_ = pts[t].mean(0)
            if er[int(round(cy_)), int(round(cx_))]: keep.append(t)
        if not keep: continue
        bm = bmesh.new()
        fv = [bm.verts.new(to3d(u, v, +thick / 2)) for (u, v) in pts]; bv = [bm.verts.new(to3d(u, v, -thick / 2)) for (u, v) in pts]
        edge_count = {}
        for t in keep:
            try: bm.faces.new((fv[t[0]], fv[t[1]], fv[t[2]])); bm.faces.new((bv[t[2]], bv[t[1]], bv[t[0]]))
            except ValueError: pass
            for a_, b_ in ((t[0], t[1]), (t[1], t[2]), (t[2], t[0])):
                k_ = (min(a_, b_), max(a_, b_)); edge_count[k_] = edge_count.get(k_, 0) + 1
        for (a_, b_), cnt in edge_count.items():
            if cnt == 1:
                try: bm.faces.new((fv[a_], fv[b_], bv[b_], bv[a_]))
                except ValueError: pass
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        ob = K.obj_from_bm(bm, 'KelpC', key if i % 2 else 'KelpLight')
        for p in ob.data.polygons: p.use_smooth = False
fx0, fx1, fy0, fy1 = bbp['front']; fcx = (fx0 + fx1) / 2
contour_ribbons('front', lambda u, v, d: Vector((d + 6.0, (u - fcx) * S, (BOT - v) * S)), 'Kelp')
sx0, sx1, sy0, sy1 = bbp['side']; ss = 150 / (sy1 - sy0 + 1)
scx = 784          # the tower axis column in the side view (measured)
contour_ribbons('side', lambda u, v, d: Vector(((u - scx) * ss, d - 4.0, (sy1 - v) * ss)), 'Kelp')
# --- coral and sponges at the foot (front view: pink branch coral left & right, yellow tube sponges, teal clam)
def branch(c, key, sz, seed):
    rr_ = random.Random(seed)
    for j in range(5):
        a_ = j * 1.25 + rr_.uniform(-0.3, 0.3)
        K.tube([c, c + Vector((math.cos(a_) * sz * 0.3, math.sin(a_) * sz * 0.3, sz * 0.55)), c + Vector((math.cos(a_) * sz * 0.55, math.sin(a_) * sz * 0.55, sz))], [sz * 0.09, sz * 0.07, sz * 0.04], 'Coral', key, sides=6)
# --- decorations placed where the sheet's TOP view shows them (anchor: tower axis at px (437.7, 745.2), 3.06 px/stud;
# image right = +X, image up = +Y); height from a ray cast onto the hill. Sizes from the component sizes.
import bpy
bpy.context.view_layer.update()
dg = bpy.context.evaluated_depsgraph_get()
def ground(x, y):
    hit, loc, nrm, idx, ob, mtx = bpy.context.scene.ray_cast(dg, Vector((x, y, 300)), Vector((0, 0, -1)))
    return (loc.z, nrm) if hit else (0.0, Vector((0, 0, 1)))
tx0, tx1, ty0, ty1 = bbp['top']; TA = (437.7, 745.2, 3.06)
top = Vp['top']
def comps(mask, min_px):
    mm = ndi.binary_opening(mask & top, iterations=1); lab_, n_ = ndi.label(mm); out = []
    for i in range(n_):
        ys, xs = np.where(lab_ == i + 1)
        if len(xs) < min_px: continue
        cxp, cyp = xs.mean(), ys.mean()
        if math.hypot(cxp - TA[0], cyp - TA[1]) < 58: continue          # the tower / lantern itself
        out.append(((cxp - TA[0]) / TA[2], (TA[1] - cyp) / TA[2], math.sqrt(len(xs) / math.pi) / TA[2]))
    return out
pink = (Rr > 200) & (Gg < 150) & (Gg > 60) & (Bb < 150) & (Bb > 60)
orange = (Rr > 225) & (Gg > 80) & (Gg < 150) & (Bb < 70)
yellow = (Rr > 220) & (Gg > 170) & (Bb < 100)
teal = (Gg > 150) & (Bb > 140) & (Rr < 100)
white = (Rr > 205) & (Gg > 205) & (Bb > 195)
for (x, y, rad) in comps(pink, 120):
    zg, _ = ground(x, y); branch(Vector((x, y, zg - 0.5)), 'CoralPink', max(8, rad * 3.2), int(abs(x * 13 + y * 7)))
for (x, y, rad) in comps(yellow, 60):
    zg, _ = ground(x, y)
    for j in range(3):
        c = Vector((x + (j - 1) * rad * 0.7, y + (j % 2) * rad * 0.6, zg - 1))
        K.lathe([(rad * 0.42, 0), (rad * 0.42, rad * 1.6 + j), (rad * 0.5, rad * 1.8 + j), (rad * 0.28, rad * 1.85 + j), (rad * 0.24, rad)], 'Sponge', 'Sponge', sides=12).location = c
for (x, y, rad) in comps(teal, 60):
    zg, _ = ground(x, y)
    K.lathe([(rad * 0.4, zg - 1), (rad, zg + 1.2), (rad * 0.92, zg + 3.0), (rad * 0.55, zg + 2.2)], 'Clam', 'Teal', sides=16)
for (x, y, rad) in comps(orange, 40):
    zg, nrm = ground(x, y); p = Vector((x, y, zg + 0.4)); rad = max(3.0, rad * 1.4)
    t1 = nrm.orthogonal().normalized(); t2 = nrm.cross(t1)
    bm = bmesh.new(); vs = []
    for k in range(10):
        rr_ = rad if k % 2 == 0 else rad * 0.42; th = 2 * math.pi * k / 10
        vs.append(bm.verts.new(p + (t1 * math.cos(th) + t2 * math.sin(th)) * rr_))
    c1 = bm.verts.new(p + nrm * 1.0); c0 = bm.verts.new(p - nrm * 0.6)
    for k in range(10): bm.faces.new((vs[k], vs[(k + 1) % 10], c1)); bm.faces.new((vs[(k + 1) % 10], vs[k], c0))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces); K.obj_from_bm(bm, 'StarG', 'Starfish')
for (x, y, rad) in comps(white, 25):
    zg, _ = ground(x, y)
    for j in range(4):
        K.rock(Vector((x + random.uniform(-1.5, 1.5), y + random.uniform(-1.5, 1.5), zg + 0.6)), (1.1, 1.1, 0.9), 'BarnG', 'Barnacle', seed=j + int(abs(x * 3)), sub=1, rough=0.1, flat_bottom=False)
K.finish(40)
K.join_by_key()
print('TRIS', K.tris())
K.export('/tmp/claude-0/lm/lh2/MB_LM_Lighthouse_v2.fbx')
K.export_obj('/tmp/claude-0/lm/lh2/model.obj')
