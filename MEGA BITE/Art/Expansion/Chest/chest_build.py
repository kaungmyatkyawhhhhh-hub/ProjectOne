"""MEGA BITE treasure chest from its design sheet (mb_sheet_prop_chest.png).
Three meshes: Body (wood box, gold frame, lock plate + gem), Lid (barrel lid, straps, end arches, coral/barnacle/seaweed cluster),
Gold (coin heap + two gems, seen when the lid is open). One 1024 px atlas cut from the sheet itself.
Axes (OBJ, y up): x = width (left..right in the front view), y = up, z = depth (+z = front). Units = studs. Origin = bottom centre."""
import numpy as np, cv2, json, math
from PIL import Image
from scipy import ndimage as ndi
import trimesh, shapely.geometry as sg

SH = np.asarray(Image.open('sheet.png').convert('RGB')).astype(np.float32)
M = np.array([255, 0, 255], np.float32)
dM = np.sqrt(((SH - M) ** 2).sum(-1)); FG = dM > 80
hsv = cv2.cvtColor(SH.astype(np.uint8), cv2.COLOR_RGB2HSV).astype(np.float32); hh, ss, vv = hsv[..., 0], hsv[..., 1], hsv[..., 2]
DECOR = FG & (((hh > 150) | (hh < 4)) & (ss > 70) & (vv > 140) | ((hh > 35) & (hh < 75) & (ss > 70)) | ((ss < 70) & (vv > 150)))

# ---------------------------------------------------------------- measured from the sheet (px)
S_F, XC_F, Y0_F = 32.5, 438.5, 463.0          # front view: px per stud, centre column, floor row
HX, HZ = 7.0, 4.9                              # half width (the feet), half depth
WALL = 6.74                                    # half width of the posts / walls (the feet and caps stand out from them)
# the sheet's views disagree on the depth (end view 9.2 studs, top view 10.5): the model uses 9.8 and each view's texture
# is mapped with its own horizontal scale
S_T, XC_T, YC_T, S_TZ = 34.2, 424.5, 770.0, 170.0 / HZ     # top view (front of the chest = bottom of the view)
S_E, XC_E, Y0_E, S_EZ = 33.7, 1108.5, 957.0, 154.5 / HZ    # end view (front of the chest = left)
RIM = 5.82                                     # top of the body = hinge height
RY, RZ = 4.52, HZ - 0.12                       # lid: half-ellipse (height, half depth)
LID_X = 6.72                                   # the lid's half length; its ends are rounded (front view: 2.55 studs, top view: 1.3)
STRAP_X, STRAP_W = 3.6, 1.9

parts = []   # (group, kind, V, F)  kind: 'proj' | 'lid' | ('sw', name) | 'decorF' | 'decorE'
def add(group, kind, V, F): parts.append((group, kind, np.asarray(V, float), np.asarray(F, int)))
def box(x0, x1, y0, y1, z0, z1):
    V = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0), (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]
    F = [(0, 2, 1), (0, 3, 2), (4, 5, 6), (4, 6, 7), (0, 1, 5), (0, 5, 4), (3, 6, 2), (3, 7, 6), (0, 4, 7), (0, 7, 3), (1, 2, 6), (1, 6, 5)]
    return np.array(V, float), np.array(F)
def dome(c, r, n=7, squash=0.42, axis='z', sign=1):   # a rivet: a low rounded dome (two rings + a flat tip) sitting on a face
    ax = {'x': 0, 'y': 1, 'z': 2}[axis]; o = [i for i in range(3) if i != ax]
    V = []; F = []
    for (rr, hh_) in ((1.0, 0.0), (0.62, 0.72)):
        for i in range(n):
            a_ = 2 * math.pi * i / n; p = np.array(c, float); p[o[0]] += r * rr * math.cos(a_); p[o[1]] += r * rr * math.sin(a_); p[ax] += sign * r * squash * hh_; V.append(p)
    tip = np.array(c, float); tip[ax] += sign * r * squash; V.append(tip)
    for i in range(n):
        j = (i + 1) % n
        F += [(i, j, n + j), (i, n + j, n + i), (n + i, n + j, 2 * n)]
    return fix(np.array(V), np.array(F))
def fix(V, F):   # outward winding
    m = trimesh.Trimesh(V, F, process=False)
    if m.is_watertight:
        trimesh.repair.fix_normals(m); return np.asarray(m.vertices), np.asarray(m.faces)
    V = np.asarray(V, float); F = np.asarray(F).copy(); c = V.mean(0)
    for i, f in enumerate(F):
        nrm = np.cross(V[f[1]] - V[f[0]], V[f[2]] - V[f[0]])
        if np.dot(nrm, V[f].mean(0) - c) < 0: F[i] = f[[0, 2, 1]]
    return V, F

# ---------------------------------------------------------------- BODY
ZW = HZ - (HX - WALL)   # the walls' half depth
add('Body_Wood', 'proj', *box(-WALL + 0.12, WALL - 0.12, 0.3, RIM - 0.1, -ZW + 0.12, ZW - 0.12))
add('Body_Base', 'proj', *box(-WALL - 0.1, WALL + 0.1, 0, 0.95, -ZW - 0.1, ZW + 0.1))
add('Body_Rim', 'proj', *box(-WALL - 0.1, WALL + 0.1, RIM - 1.42, RIM, -ZW - 0.1, ZW + 0.1))
for sx in (-1, 1):
    for sz in (-1, 1):
        x0, x1 = sorted((sx * (WALL + 0.04), sx * (WALL - 1.7))); z0, z1 = sorted((sz * (ZW + 0.04), sz * (ZW - 1.7)))
        add('Body_Post', 'proj', *box(x0, x1, 0, RIM, z0, z1))
        x0, x1 = sorted((sx * HX, sx * (HX - 2.3))); z0, z1 = sorted((sz * HZ, sz * (HZ - 2.3)))
        add('Body_Foot', 'proj', *box(x0, x1, 0, 1.8, z0, z1))
        CX, CZ = 7.12, HZ + 0.12
        x0, x1 = sorted((sx * CX, sx * (CX - 2.5))); z0, z1 = sorted((sz * CZ, sz * (CZ - 2.5)))
        add('Body_Cap', 'proj', *box(x0, x1, 4.1, 6.18, z0, z1))
        # rivets on the front/back faces and the end faces of the caps and feet
        add('Body_Rivet', ('sw', 'gold_hi'), *dome((sx * (CX - 1.25), 5.15, sz * CZ), 0.36, axis='z', sign=sz))
        add('Body_Rivet', ('sw', 'gold_hi'), *dome((sx * CX, 5.15, sz * (CZ - 1.25)), 0.36, axis='x', sign=sx))
        add('Body_Rivet', ('sw', 'gold_hi'), *dome((sx * (HX - 1.15), 0.9, sz * HZ), 0.34, axis='z', sign=sz))
        add('Body_Rivet', ('sw', 'gold_hi'), *dome((sx * HX, 0.9, sz * (HZ - 1.15)), 0.34, axis='x', sign=sx))
# lock plate: a 4-point star (diamond with pinched sides) + the gem
LY = (Y0_F - 318.5) / S_F
def star(rx, ry, pinch, z0, z1):
    pts = []
    for i in range(8):
        a = math.pi / 2 - i * math.pi / 4
        k = 1.0 if i % 2 == 0 else pinch
        pts.append((math.cos(a) * rx * k, LY + math.sin(a) * ry * k))
    n = len(pts); V = [(p[0], p[1], z0) for p in pts] + [(p[0], p[1], z1) for p in pts] + [(0, LY, z0), (0, LY, z1)]
    F = []
    for i in range(n):
        j = (i + 1) % n
        F += [(i, j, n + j), (i, n + j, n + i), (2 * n, j, i), (2 * n + 1, n + i, n + j)]
    return fix(np.array(V, float), np.array(F))
add('Body_Lock', 'proj', *star(2.77, 2.66, 0.52, ZW, ZW + 0.5))
gx, gy = 1.23, 1.38
G = np.array([(0, LY + gy, ZW + 0.5), (gx, LY, ZW + 0.5), (0, LY - gy, ZW + 0.5), (-gx, LY, ZW + 0.5), (0, LY, ZW + 1.05), (0, LY, ZW + 0.3)])
add('Body_Gem', 'proj', *fix(G, np.array([(0, 1, 4), (1, 2, 4), (2, 3, 4), (3, 0, 4), (1, 0, 5), (2, 1, 5), (3, 2, 5), (0, 3, 5)])))

# ---------------------------------------------------------------- LID (hinge: y = RIM, z = -HZ)
def kfac(x, c, p=2.6):   # how much of the full arch is left at x (1 in the middle, 0 at the very end)
    t = np.clip((abs(x) - (LID_X - c)) / c, 0, 1)
    return (1 - t ** p) ** (1 / p)
def loft(xs, grow, n=12):
    """half-ellipse sections along x (the arch shrinks toward the lid's rounded ends); grow = offset outward (studs)"""
    V = []; F = []
    for xi in xs:
        ky, kz = max(kfac(xi, 2.55), 0.02), max(kfac(xi, 1.3), 0.02)
        for i in range(n + 1):
            t = math.pi * i / n
            V.append((xi, RIM + (RY * ky + grow) * math.sin(t), (RZ * kz + grow) * math.cos(t)))
    for a_ in range(len(xs) - 1):
        for i in range(n):
            p, q = a_ * (n + 1) + i, (a_ + 1) * (n + 1) + i
            F += [(p, q, q + 1), (p, q + 1, p + 1)]
    return np.array(V, float), np.array(F), n
def solid(xs, grow_out, grow_in, n=12):
    """a closed shell between an outer and an inner loft: bottom rims + end walls"""
    Vo, Fo, _ = loft(xs, grow_out, n); Vi, Fi, _ = loft(xs, grow_in, n)
    m = len(Vo); V = np.concatenate([Vo, Vi]); F = [tuple(f) for f in Fo] + [(f[0] + m, f[2] + m, f[1] + m) for f in Fi]
    S = len(xs)
    for a_ in range(S - 1):
        for i in (0, n):
            p, q = a_ * (n + 1) + i, (a_ + 1) * (n + 1) + i
            F += [(p, p + m, q + m), (p, q + m, q)]
    for a_ in (0, S - 1):
        for i in range(n):
            p = a_ * (n + 1) + i
            F += [(p, p + 1, p + 1 + m), (p, p + 1 + m, p + m)]
    return fix(V, np.array(F))
TH = 0.5
XS = [-LID_X, -6.6, -6.35, -5.95, -5.42, -4.7, -4.17, -2.0, 0, 2.0, 4.17, 4.7, 5.42, 5.95, 6.35, 6.6, LID_X]
add('Lid_Shell', 'lid', *solid(XS, 0, -TH))
for sx in (-1, 1):
    xs = sorted(sx * np.array([STRAP_X - STRAP_W / 2, STRAP_X, STRAP_X + STRAP_W / 2]))
    add('Lid_Strap', 'lid', *solid(list(xs), 0.2, -TH - 0.06))
    xs = sorted(sx * np.array([5.25, 5.6, 5.95, 6.25]))
    add('Lid_Arch', 'lid', *solid(list(xs), 0.2, -TH - 0.06))
    add('Lid_Rivet', ('sw', 'gold_hi'), *dome((sx * STRAP_X, RIM + 0.75, RZ + 0.16), 0.34, axis='z', sign=1))
    add('Lid_Rivet', ('sw', 'gold_hi'), *dome((sx * STRAP_X, RIM + 0.75, -RZ - 0.16), 0.34, axis='z', sign=-1))
# the inside of the lid is a warm gold glow
# (the shell's inner surface gets the 'inside' swatch in the UV step: faces whose normal points at the lid's axis)

# decor cluster: two crossed cards cut from the sheet's own outlines (front view + end view)
def card(mask, x0p, y0p, to_xyz, thick, kind, group):
    cs, _ = cv2.findContours(mask.astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    for c in cs:
        if cv2.contourArea(c) < 120: continue
        c = cv2.approxPolyDP(c, 1.6, True)[:, 0, :].astype(float)
        if len(c) < 3: continue
        poly = sg.Polygon(c).buffer(0)
        if poly.is_empty: continue
        if poly.geom_type == 'MultiPolygon': poly = max(poly.geoms, key=lambda g: g.area)
        v2, f2 = trimesh.creation.triangulate_polygon(poly, engine='earcut')
        n = len(v2)
        A = np.array([to_xyz(p[0] + x0p, p[1] + y0p, +thick / 2) for p in v2]); B = np.array([to_xyz(p[0] + x0p, p[1] + y0p, -thick / 2) for p in v2])
        V = np.concatenate([A, B]); F = [tuple(f) for f in f2] + [(f[0] + n, f[2] + n, f[1] + n) for f in f2]
        # the rim
        ring = np.asarray(poly.exterior.coords)[:-1]
        import scipy.spatial as sp
        tree = sp.cKDTree(v2); ids = tree.query(ring)[1]
        for i in range(len(ids)):
            a, b = ids[i], ids[(i + 1) % len(ids)]
            F += [(a, b, b + n), (a, b + n, a + n)]
        add(group, kind, *fix(V, np.array(F)))
fx0, fx1, fy0, fy1 = 168, 304, 56, 320
mF = ndi.binary_opening(DECOR[fy0:fy1, fx0:fx1], iterations=1)
mF = ndi.binary_closing(mF, iterations=3); mF = ndi.binary_fill_holes(mF)
card(mF, fx0, fy0, lambda px, py, t: ((px - XC_F) / S_F, (Y0_F - py) / S_F, 1.6 + t), 0.5, 'decorF', 'Lid_DecorF')
ex0, ex1, ey0, ey1 = 930, 1112, 548, 784
mE = ndi.binary_opening(DECOR[ey0:ey1, ex0:ex1], iterations=1)
mE = ndi.binary_closing(mE, iterations=3); mE = ndi.binary_fill_holes(mE)
card(mE, ex0, ey0, lambda px, py, t: (-6.35 + t, (Y0_E - py) / S_E, (XC_E - px) / S_EZ), 0.5, 'decorE', 'Lid_DecorE')

tx0, tx1, ty0, ty1 = 150, 304, 684, 926
mT = ndi.binary_opening(DECOR[ty0:ty1, tx0:tx1], iterations=1)
mT = ndi.binary_closing(mT, iterations=3); mT = ndi.binary_fill_holes(mT)
card(mT, tx0, ty0, lambda px, py, t: ((px - XC_T) / S_T, 8.9 + t, (py - YC_T) / S_TZ), 0.4, 'decorT', 'Lid_DecorT')

# ---------------------------------------------------------------- GOLD (coins heap + gems)
rng = np.random.default_rng(7)
def heap():
    nx, nz = 10, 8; V = []; F = []
    for j in range(nz + 1):
        for i in range(nx + 1):
            u, w = i / nx * 2 - 1, j / nz * 2 - 1
            x, z = u * (WALL - 0.3), w * (ZW - 0.3)
            y = RIM - 0.55 + 1.75 * max(0.0, 1 - (u * u * 0.8 + w * w * 0.9)) ** 0.7 + 0.12 * math.sin(i * 2.1 + j * 1.3)
            V.append((x, y, z))
    for j in range(nz):
        for i in range(nx):
            a = j * (nx + 1) + i; b = a + 1; c = a + nx + 1; d = c + 1
            F += [(a, c, b), (b, c, d)]
    return fix(np.array(V, float), np.array(F))
hv, hf = heap(); add('Gold_Heap', ('sw', 'gold_mid'), hv, hf)
def heap_y(x, z):
    u, w = x / (WALL - 0.3), z / (ZW - 0.3)
    return RIM - 0.55 + 1.75 * max(0.0, 1 - (u * u * 0.8 + w * w * 0.9)) ** 0.7
def coin(c, r, h, tilt, yaw, n=8):
    V = []; F = []
    Rm = trimesh.transformations.euler_matrix(tilt, yaw, 0, 'sxyz')[:3, :3]
    for s in (0, 1):
        for i in range(n):
            a = 2 * math.pi * i / n; V.append(Rm @ np.array((r * math.cos(a), h * s, r * math.sin(a))) + c)
    V.append(Rm @ np.array((0, h, 0)) + c); V.append(Rm @ np.array((0, 0, 0)) + c)
    for i in range(n):
        j = (i + 1) % n
        F += [(i, j, n + j), (i, n + j, n + i), (2 * n, n + j, n + i), (2 * n + 1, i, j)]
    return fix(np.array(V), np.array(F))
for k in range(22):
    x, z = rng.uniform(-HX + 1.6, HX - 1.6), rng.uniform(-HZ + 1.5, HZ - 1.5)
    add('Gold_Coin', ('sw', 'gold_hi' if k % 2 == 0 else 'gold_lo'), *coin(np.array((x, heap_y(x, z) + 0.02, z)), rng.uniform(0.75, 0.95), 0.2, rng.uniform(-0.5, 0.5), rng.uniform(0, 6.28)))
def gem(c, r, h, group, sw):
    n = 6; V = [c + np.array((0, h * 0.62, 0))]
    for i in range(n):
        a = 2 * math.pi * i / n; V.append(c + np.array((r * math.cos(a), h * 0.12, r * math.sin(a))))
    V.append(c + np.array((0, -h * 0.38, 0)))
    F = []
    for i in range(n):
        j = (i + 1) % n
        F += [(0, 1 + i, 1 + j), (n + 1, 1 + j, 1 + i)]
    add(group, ('sw', sw), *fix(np.array(V), np.array(F)))
gem(np.array((-2.1, heap_y(-2.1, 1.2) + 0.75, 1.2)), 1.25, 2.3, 'Gold_GemT', 'teal')
gem(np.array((2.7, heap_y(2.7, 0.6) + 0.7, 0.6)), 1.15, 2.1, 'Gold_GemP', 'pink')

# ---------------------------------------------------------------- ATLAS
AT = np.zeros((1024, 1024, 3), np.float32)
def nearest_fill(img, valid):
    idx = ndi.distance_transform_edt(~valid, return_distances=False, return_indices=True)
    return img[idx[0], idx[1]]
def clean_crop(x0, x1, y0, y1, xc, decor_box):
    """a view crop with the decor cluster's whole box replaced by the mirror image of the other half (the chest is
    symmetric and the other half has no decor), background filled from the chest"""
    img = SH.copy(); ok = FG.copy()
    dx0, dx1, dy0, dy1 = decor_box
    ys, xs = np.mgrid[dy0:dy1, dx0:dx1]
    mx = np.clip(np.round(2 * xc - xs).astype(int), 0, SH.shape[1] - 1)
    img[ys, xs] = SH[ys, mx]; ok[ys, xs] = FG[ys, mx] & ~DECOR[ys, mx]
    sub, v = img[y0:y1, x0:x1], ok[y0:y1, x0:x1]
    v = ndi.binary_erosion(v, iterations=2)
    return nearest_fill(sub, v)
F_BOX = (196, 682, 112, 466)
F_CLEAN = clean_crop(F_BOX[0], F_BOX[1], F_BOX[2], F_BOX[3], XC_F, (168, 304, 56, 320))
B_CLEAN = F_CLEAN.copy()   # the back: no lock plate (rows smeared from a column just left of the plate), and nothing of the lid's end
c0, c1 = 344 - F_BOX[0], 536 - F_BOX[0]
rl = 274 - F_BOX[2]   # the lid / body line
B_CLEAN[:rl, c0:c1] = F_CLEAN[:rl, 372 - F_BOX[0]:378 - F_BOX[0]].mean(1, keepdims=True)    # lid rows: wood beside the plate's tip
B_CLEAN[rl:, c0:c1] = F_CLEAN[rl:, 296 - F_BOX[0]:302 - F_BOX[0]].mean(1, keepdims=True)    # body rows: band / wood / base
T_BOX = (182, 666, 596, 946)
T_CLEAN = clean_crop(T_BOX[0], T_BOX[1], T_BOX[2], T_BOX[3], XC_T, (155, 300, 690, 920))
E_BOX = (948, 1270, 594, 960)
E_CLEAN = clean_crop(E_BOX[0], E_BOX[1], E_BOX[2], E_BOX[3], XC_E, (930, 1112, 548, 784))
def put(img, ax, ay):
    h, w = img.shape[:2]; AT[ay:ay + h, ax:ax + w] = img; return (ax, ay, w, h)
R_F = put(F_CLEAN, 2, 2); R_B = put(B_CLEAN, 2, 360); R_T = put(T_CLEAN, 492, 2); R_E = put(E_CLEAN, 492, 356)
T_LID = T_CLEAN.copy()
bx0, bx1, by0 = 336 - T_BOX[0], 516 - T_BOX[0], 872 - T_BOX[2]
T_LID[by0:, bx0:bx1] = T_CLEAN[by0:, 300 - T_BOX[0]:306 - T_BOX[0]].mean(1, keepdims=True)
# lid unwrap: u = x, v = angle from the front rim (0) over the top to the back rim (pi)
LW, LH = F_BOX[1] - F_BOX[0], 300
LID = np.zeros((LH, LW, 3), np.float32)
us = np.arange(LW)
for v in range(LH):
    t = (v + 0.5) / LH * math.pi; tf = t if t <= math.pi / 2 else math.pi - t
    fy = (Y0_F - (RIM + RY * math.sin(tf)) * S_F) - F_BOX[2]
    rowF = B_CLEAN[int(np.clip(round(fy), 0, B_CLEAN.shape[0] - 1)), :]
    ty = (YC_T + RZ * math.cos(t) * S_TZ) - T_BOX[2]
    tx = np.clip(np.round((us + F_BOX[0] - XC_F) / S_F * S_T + XC_T - T_BOX[0]).astype(int), 0, T_CLEAN.shape[1] - 1)
    rowT = T_LID[int(np.clip(round(ty), 0, T_LID.shape[0] - 1)), tx]
    k_ = (math.sin(t) - 0.5) / 0.32; k_ = min(max(k_, 0.0), 1.0); wT = k_ * k_ * (3 - 2 * k_)
    LID[v] = rowT * wT + rowF * (1 - wT)
R_L = put(LID, 2, 720)
# decor crops (the sheet's own pixels, background filled from the art)
def decor_crop(x0, x1, y0, y1):
    sub = SH[y0:y1, x0:x1]; v = ndi.binary_erosion(DECOR[y0:y1, x0:x1], iterations=1)
    return nearest_fill(sub, v)
R_DF = put(decor_crop(fx0, fx1, fy0, fy1), 840, 356); R_DE = put(decor_crop(ex0, ex1, ey0, ey1), 840, 624); R_DT = put(decor_crop(tx0, tx1, ty0, ty1), 680, 780)
SW = {}
def swatch(name, rgb, i):
    x, y = 492 + (i % 8) * 42, 730 + (i // 8) * 42
    AT[y:y + 40, x:x + 40] = rgb; SW[name] = (x + 20, y + 20)
def med(mask):
    return np.median(SH[mask], 0)
gold_m = FG & (hh > 15) & (hh < 32) & (ss > 120) & (vv > 150)
swatch('gold_mid', med(gold_m), 0); swatch('gold_hi', np.percentile(SH[gold_m], 88, 0), 1); swatch('gold_lo', np.percentile(SH[gold_m], 12, 0), 2)
wood_m = FG & (hh >= 5) & (hh <= 20) & (ss > 90) & (vv > 80) & ~gold_m
swatch('wood_dark', np.percentile(SH[wood_m], 15, 0), 3)
ins = SH[60:200, 960:1240]; swatch('inside', np.median(ins.reshape(-1, 3), 0), 4)
teal_m = FG & (hh > 80) & (hh < 100) & (ss > 80); swatch('teal', med(teal_m), 5)
pk = SH[230:300, 1150:1225].reshape(-1, 3); swatch('pink', np.median(pk[(pk[:, 0] > 200) & (pk[:, 1] < 170)], 0), 6)
Image.fromarray(np.clip(AT, 0, 255).astype(np.uint8)).save('MB_Chest_atlas.png')

# ---------------------------------------------------------------- UVs + OBJ
def uv_px(group, kind, p, n):
    x, y, z = p
    if isinstance(kind, tuple): return SW[kind[1]]
    if kind == 'decorF': return (R_DF[0] + (x * S_F + XC_F - fx0), R_DF[1] + (Y0_F - y * S_F - fy0))
    if kind == 'decorT': return (R_DT[0] + (x * S_T + XC_T - tx0), R_DT[1] + (z * S_TZ + YC_T - ty0))
    if kind == 'decorE': return (R_DE[0] + (XC_E - z * S_EZ - ex0), R_DE[1] + (Y0_E - y * S_E - ey0))
    if kind == 'lid':
        # inner surface (normal points at the lid's axis) = the warm inside
        ry = (y - RIM) / RY; rz = z / RZ
        if n[1] * ry + n[2] * rz < -0.15: return SW['inside']
        if n[1] < -0.7: return SW['gold_lo']
        if abs(n[0]) > 0.8 and group != 'Lid_Shell': return SW['gold_mid']
        if abs(n[0]) > 0.75:      # the lid's rounded end: the end view
            zz = z if n[0] > 0 else -z
            return (R_E[0] + np.clip(XC_E - zz * S_EZ - E_BOX[0], 1, R_E[2] - 2), R_E[1] + np.clip(Y0_E - y * S_E - E_BOX[2], 1, R_E[3] - 2))
        t = math.atan2(max(ry, 0.0), rz)
        return (R_L[0] + np.clip(x * S_F + XC_F - F_BOX[0], 1, LW - 2), R_L[1] + np.clip(t / math.pi * LH, 1, LH - 2))
    ax = int(np.argmax(np.abs(n)))
    if ax == 2:
        R = R_F if n[2] > 0 else R_B
        u = x * S_F + XC_F - F_BOX[0]
        if n[2] < 0: u = (-x) * S_F + XC_F - F_BOX[0]
        return (R[0] + np.clip(u, 1, R[2] - 2), R[1] + np.clip(Y0_F - y * S_F - F_BOX[2], 1, R[3] - 2))
    if ax == 0:
        zz = z if n[0] > 0 else -z
        return (R_E[0] + np.clip(XC_E - zz * S_EZ - E_BOX[0], 1, R_E[2] - 2), R_E[1] + np.clip(Y0_E - y * S_E - E_BOX[2], 1, R_E[3] - 2))
    if n[1] > 0:
        return (R_T[0] + np.clip(x * S_T + XC_T - T_BOX[0], 1, R_T[2] - 2), R_T[1] + np.clip(YC_T + z * S_TZ - T_BOX[2], 1, R_T[3] - 2))
    return SW['wood_dark']
tris = 0
with open('model.obj', 'w') as fo:
    fo.write('mtllib model.mtl\n'); vo = 1; to = 1
    for gi, (group, kind, V, F) in enumerate(parts):
        fo.write(f'o {group}_{gi}\nusemtl Atlas\n')
        for v in V: fo.write('v %.4f %.4f %.4f\n' % tuple(v))
        m = trimesh.Trimesh(V, F, process=False); FN = m.face_normals
        for fi, f in enumerate(F):
            for vi in f:
                px = uv_px(group, kind, V[vi], FN[fi]); fo.write('vt %.5f %.5f\n' % (px[0] / 1024.0, 1 - px[1] / 1024.0))
        for fi, f in enumerate(F):
            fo.write('f %d/%d %d/%d %d/%d\n' % (f[0] + vo, to + fi * 3, f[1] + vo, to + fi * 3 + 1, f[2] + vo, to + fi * 3 + 2))
        vo += len(V); to += len(F) * 3; tris += len(F)
open('model.mtl', 'w').write('newmtl Atlas\nKd 1 1 1\nmap_Kd MB_Chest_atlas.png\n')

# ---------------------------------------------------------------- GATES (silhouette IoU against the sheet, closed chest)
def sil(view, groups_prefix=('Body', 'Lid')):
    im = np.zeros(SH.shape[:2], np.uint8)
    for (group, kind, V, F) in parts:
        if not group.startswith(groups_prefix): continue
        if view == 'front': P = np.stack([V[:, 0] * S_F + XC_F, Y0_F - V[:, 1] * S_F], 1)
        elif view == 'end': P = np.stack([XC_E - V[:, 2] * S_EZ, Y0_E - V[:, 1] * S_E], 1)
        else: P = np.stack([V[:, 0] * S_T + XC_T, YC_T + V[:, 2] * S_TZ], 1)
        for f in F: cv2.fillConvexPoly(im, np.round(P[f]).astype(np.int32), 1)
    return im.astype(bool)
quads = {'front': (0, 512, 0, 768), 'top': (512, 1024, 0, 768), 'end': (512, 1024, 768, 1536)}
g = {}
ov = np.zeros(SH.shape[:2] + (3,), np.uint8)
for k, (y0, y1, x0, x1) in quads.items():
    ref = np.zeros_like(FG); ref[y0:y1, x0:x1] = FG[y0:y1, x0:x1]
    R = sil(k)
    g[k + '_iou'] = round(float((R & ref).sum() / max(1, (R | ref).sum())), 3)
    ov[R & ref] = (235, 235, 235); ov[ref & ~R] = (40, 200, 60); ov[R & ~ref] = (230, 50, 50)
Image.fromarray(ov).resize((768, 512)).save('mismatch.png')
allV = np.concatenate([p[2] for p in parts]); ext = allV.max(0) - allV.min(0)
g['tris'] = tris; g['size_studs'] = [round(float(e), 2) for e in ext]
# open edges per part (each part is its own closed solid)
oe = 0
for (group, kind, V, F) in parts:
    if group.startswith(('Gold_Heap', 'Body_Rivet', 'Lid_Rivet')): continue   # flat walls / open-bottomed pieces that sit on other parts
    mm = trimesh.Trimesh(np.round(V, 4), F, process=True)
    oe += len(trimesh.grouping.group_rows(mm.edges_sorted, require_count=1))
g['open_edges'] = int(oe)
g['pass'] = all(g[k + '_iou'] >= 0.90 for k in quads) and oe == 0
json.dump(g, open('gates.json', 'w'), indent=1); print(json.dumps(g))
