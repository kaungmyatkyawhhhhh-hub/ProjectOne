# MEGA BITE manta ray v1 generator (sheet method): builds the mesh data from mb_manta_sheet.png
# Output: manta_v1.json  {verts:[[x,y,z]], faces:[[a,b,c]], col:[palette index]}  (Blender units, 1 = 100 sheet px)
import json, sys, math
import numpy as np, cv2
from PIL import Image
from scipy.spatial import Delaunay
from scipy import ndimage as nd

SHEET = sys.argv[1]
OUT = sys.argv[2]
im = np.array(Image.open(SHEET).convert('RGB')).astype(int)
H, W, _ = im.shape
dkey = np.sqrt(((im - [255, 0, 255]) ** 2).sum(-1))
fg = dkey > 90
CX = 768.0           # centre column of the top view
Y0 = 300.0           # origin row (about the wing tips)
S = 100.0            # px per Blender unit

# palette (index -> colour); the Blender script writes the same list into the texture
PAL = [(30, 84, 122), (22, 64, 96), (70, 236, 246), (58, 178, 222), (244, 236, 210),
       (14, 14, 22), (255, 255, 255), (118, 30, 46), (244, 124, 136)]
NAVY, NAVYD, CYAN, SPOT, CREAM, BLACK, WHITE, MOUTH, TONGUE = range(9)

# ---------------- body mask (top view, horns + tail removed)
top = np.zeros_like(fg)
top[25:745, 263:1275] = fg[25:745, 263:1275]
body = top.copy()
body[:108, :] = False          # horns sit above the head front (rows 25-108)
body[548:, :] = False          # the thin whip tail is its own cone
body = nd.binary_fill_holes(body)
lab, n = nd.label(body)
sizes = nd.sum(body, lab, range(1, n + 1))
body = lab == (int(np.argmax(sizes)) + 1)
body = nd.binary_opening(body, iterations=2)
dist = nd.distance_transform_edt(body)

cnts, _ = cv2.findContours(body.astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
cnt = max(cnts, key=cv2.contourArea)[:, 0, :].astype(float)
outline = cv2.approxPolyDP(cnt.astype(np.float32), 2.5, True)[:, 0, :].astype(float)
# resample long outline edges so no outline edge is longer than 34 px
ol = []
for i in range(len(outline)):
    a, b = outline[i], outline[(i + 1) % len(outline)]
    L = np.linalg.norm(b - a)
    k = max(1, int(math.ceil(L / 34)))
    for j in range(k):
        ol.append(a + (b - a) * j / k)
outline = np.array(ol)
nO = len(outline)

# inner band ring (9 px in): the cyan wing-edge line sits between outline and this ring
cen = np.array([CX, 300.0])
band = []
for i, p in enumerate(outline):
    a, b = outline[i - 1], outline[(i + 1) % nO]
    t = b - a
    nrm = np.array([t[1], -t[0]]); nrm /= (np.linalg.norm(nrm) + 1e-9)
    q = p + nrm * 9
    if not body[int(np.clip(q[1], 0, H - 1)), int(np.clip(q[0], 0, W - 1))]:
        q = p - nrm * 9
    band.append(q)
band = np.array(band)

# interior points: jittered grid, denser near the centre ridge
rng = np.random.default_rng(7)
pts = []
for yy in np.arange(110, 548, 30):
    for xx in np.arange(263, 1275, 30):
        x = xx + rng.uniform(-8, 8); y = yy + rng.uniform(-8, 8)
        xi, yi = int(x), int(y)
        if 0 <= yi < H and 0 <= xi < W and body[yi, xi] and dist[yi, xi] > 16:
            pts.append((x, y))
for yy in np.arange(112, 545, 22):          # centre ridge line
    if body[int(yy), int(CX)]:
        pts.append((CX, yy))
pts = np.array(pts)

allp = np.vstack([outline, band, pts])
tri = Delaunay(allp)
faces2 = []
for t in tri.simplices:
    c = allp[t].mean(0)
    if body[int(c[1]), int(c[0])]:
        faces2.append(t)
faces2 = np.array(faces2)

# ---------------- thickness
# side view profile: column -> thickness (px), mapped to top-view rows
side_cols = np.array([845, 875, 905, 935, 965, 995, 1025, 1055, 1085, 1115, 1145, 1175, 1205, 1235, 1265, 1295, 1325, 1355, 1385, 1415, 1445, 1475, 1500])
side_th = np.array([2, 3, 6, 9, 11, 15, 19, 29, 44, 60, 86, 107, 122, 131, 133, 131, 121, 101, 97, 85, 90, 77, 70])
side_rows = 100 + (1505 - side_cols) * (644 / 660.0)
order = np.argsort(side_rows)
side_rows, side_th = side_rows[order], side_th[order]
def Tc(row):
    return float(np.interp(row, side_rows, side_th))
# front view: thickness falls off across the span (top-view px from the centre)
fx = np.array([0, 100, 140, 200, 266, 330, 400, 460, 505])
fw = np.array([1.0, 0.93, 0.80, 0.52, 0.38, 0.30, 0.22, 0.10, 0.02])
def wx(x):
    return float(np.interp(abs(x - CX), fx, fw))

def edgeT(x, y):
    # the head front keeps a real thickness (the face); elsewhere a thin edge that carries the cyan line
    if y < 160 and abs(x - CX) < 150:
        k = min(1.0, (160 - y) / 45.0) * max(0.0, 1 - (abs(x - CX) / 150.0) ** 2) ** 0.5
        return 8 + 64 * k
    return 7.0
TOPF = 0.56   # share of the thickness above the edge line (domed back, flatter belly)

def thick(x, y):
    xi, yi = int(np.clip(x, 0, W - 1)), int(np.clip(y, 0, H - 1))
    dd = dist[yi, xi]
    t = Tc(y) * wx(x)
    e = edgeT(x, y)
    return max(e, min(t, e + 1.25 * dd))

def lift(x, y):
    # gentle gull curve from the front view: tips a little up
    u = abs(x - CX) / 505.0
    return 18 * u * u

verts = []
faces = []
cols = []
def V(x, y, z):
    verts.append([(x - CX) / S, -(y - Y0) / S, z / S])
    return len(verts) - 1

N = len(allp)
topI = [None] * N
botI = [None] * N
for i, (x, y) in enumerate(allp):
    if i < nO:
        e = edgeT(x, y)
        topI[i] = V(x, y, lift(x, y) + TOPF * e)
        botI[i] = V(x, y, lift(x, y) - (1 - TOPF) * e)
    else:
        t = thick(x, y)
        topI[i] = V(x, y, lift(x, y) + TOPF * t)
        botI[i] = V(x, y, lift(x, y) - (1 - TOPF) * t)

def sample(x, y):
    return im[int(np.clip(y, 0, H - 1)), int(np.clip(x, 0, W - 1))]
def classify_top(x, y):
    c = sample(x, y)
    # cyan line / spots / navy (two navy tones from the sheet's facet shading)
    if c[1] > 200 and c[2] > 200 and c[0] < 140:
        return CYAN
    return NAVY   # spots are separate decal plates (clean round shapes, not jaggy triangles)

for t in faces2:
    a, b, c = t
    cx, cy = allp[t].mean(0)
    inband = all(k < 2 * nO for k in t) and any(k < nO for k in t)
    # top (counter-clockwise seen from +Z: image y is flipped, so reverse)
    faces.append([topI[a], topI[c], topI[b]])
    cols.append(CYAN if inband and not (cy < 160 and abs(cx - CX) < 150) else classify_top(cx, cy))
    faces.append([botI[a], botI[b], botI[c]])
    cols.append(CYAN if inband and not (cy < 160 and abs(cx - CX) < 150) else CREAM)

# side wall around the outline (the cyan rim line; cream face at the head front)
for i in range(nO):
    j = (i + 1) % nO
    x, y = (outline[i] + outline[j]) / 2
    face_front = y < 160 and abs(x - CX) < 150
    cc = CREAM if face_front else CYAN
    faces.append([topI[i], botI[i], botI[j]]); cols.append(cc)
    faces.append([topI[i], botI[j], topI[j]]); cols.append(cc)

# ---------------- helpers for primitive parts
def add_tube(path, radii, colfn, sides=7):
    rings = []
    P = [np.array(p, float) for p in path]
    for k, p in enumerate(P):
        tg = (P[min(k + 1, len(P) - 1)] - P[max(k - 1, 0)]); tg /= np.linalg.norm(tg) + 1e-9
        up = np.array([0, 0, 1.0]) if abs(tg[2]) < 0.9 else np.array([1.0, 0, 0])
        n1 = np.cross(tg, up); n1 /= np.linalg.norm(n1); n2 = np.cross(tg, n1)
        ring = []
        for s in range(sides):
            a = 2 * math.pi * s / sides
            q = p + (n1 * math.cos(a) + n2 * math.sin(a)) * radii[k]
            verts.append(list(q)); ring.append(len(verts) - 1)
        rings.append((ring, n1, n2))
    for k in range(len(rings) - 1):
        r0, n1, n2 = rings[k]; r1 = rings[k + 1][0]
        for s in range(sides):
            s2 = (s + 1) % sides
            a = 2 * math.pi * (s + 0.5) / sides
            cc = colfn(k, n1 * math.cos(a) + n2 * math.sin(a))
            faces.append([r0[s], r0[s2], r1[s2]]); cols.append(cc)
            faces.append([r0[s], r1[s2], r1[s]]); cols.append(cc)
    # caps
    for ring, idx in ((rings[0][0], True), (rings[-1][0], False)):
        c = np.mean([verts[v] for v in ring], 0); verts.append(list(c)); ci = len(verts) - 1
        for s in range(sides):
            s2 = (s + 1) % sides
            if idx: faces.append([ci, ring[s2], ring[s]])
            else: faces.append([ci, ring[s], ring[s2]])
            cols.append(colfn(0 if idx else len(rings) - 2, np.zeros(3)))

def add_ball(c, r, cc, seg=8, rings=6, squash=(1, 1, 1)):
    c = np.array(c, float); idx = []
    for i in range(rings + 1):
        th = math.pi * i / rings; row = []
        for j in range(seg):
            ph = 2 * math.pi * j / seg
            p = c + np.array([math.sin(th) * math.cos(ph) * squash[0], math.sin(th) * math.sin(ph) * squash[1], math.cos(th) * squash[2]]) * r
            verts.append(list(p)); row.append(len(verts) - 1)
        idx.append(row)
    for i in range(rings):
        for j in range(seg):
            j2 = (j + 1) % seg
            a, b, c2, d = idx[i][j], idx[i][j2], idx[i + 1][j2], idx[i + 1][j]
            faces.append([a, d, c2]); cols.append(cc)
            faces.append([a, c2, b]); cols.append(cc)

def P(x, y, z):   # sheet px -> Blender units
    return [(x - CX) / S, -(y - Y0) / S, z / S]

# ---------------- horns (cephalic fins): a curl, tilted 50 deg up so it reads from the top AND the front
tilt = math.radians(32)
for side in (-1, 1):
    cxh = CX + side * (768 - 668)
    path, radii = [], []
    nseg = 16
    for k in range(nseg + 1):
        u = k / nseg
        th = math.radians(225 - 285 * u) if side < 0 else math.radians(-45 + 285 * u)
        r = 40 - 12 * u
        px = cxh + r * math.cos(th)
        base_row = 108
        y_pt = 65 - r * math.sin(th)   # the curl as drawn in the top view (image y points down)
        # image-up distance from the head front, split into forward (Y) and up (Z)
        upd = base_row - y_pt          # rows above the head front
        y_img = base_row - upd * math.cos(tilt)
        z = 30 + upd * math.sin(tilt)
        path.append(P(px, y_img, z)); radii.append((17 - 9 * u) / S)
    hc = np.array(P(cxh, 108 - 43 * math.cos(tilt), 30 + 43 * math.sin(tilt)))
    def hcol(k, nv, hc=hc, path=path):
        p = np.array(path[min(k, len(path) - 1)])
        toC = hc - p
        return CREAM if np.dot(nv, toC) > 0.2 * np.linalg.norm(toC) * np.linalg.norm(nv) else NAVY
    add_tube(path, radii, hcol, sides=7)

# ---------------- tail: thin whip from the body back to row 744
tpath = [P(CX, y, lift(CX, y) + 6) for y in np.linspace(530, 744, 9)]
trad = [(15 - 13.5 * u) / S for u in np.linspace(0, 1, 9)]
add_tube(tpath, trad, lambda k, nv: NAVY, sides=6)

# ---------------- spots: traced from the sheet's light-blue blobs, raised plates on the back
spotmask = top & (im[:, :, 2] > 170) & (im[:, :, 1] > 120) & (im[:, :, 0] < 120) & ~((im[:, :, 1] > 200) & (im[:, :, 2] > 200) & (im[:, :, 0] < 140) & (im[:, :, 1] > im[:, :, 2] - 10))
spotmask = nd.binary_opening(spotmask, iterations=2) & body & (dist > 14)
sl, sn = nd.label(spotmask)
nsp = 0
for i in range(1, sn + 1):
    m = (sl == i)
    if m.sum() < 120: continue
    cs, _ = cv2.findContours(m.astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    poly = cv2.approxPolyDP(max(cs, key=cv2.contourArea).astype(np.float32), 2.0, True)[:, 0, :].astype(float)
    if len(poly) < 5: continue
    cxs, cys = poly.mean(0)
    ring = []
    for (x, y) in poly:
        ring.append(V(x, y, lift(x, y) + TOPF * thick(x, y) + 1.6))
    ci = V(cxs, cys, lift(cxs, cys) + TOPF * thick(cxs, cys) + 2.2)
    for k in range(len(ring)):
        faces.append([ci, ring[(k + 1) % len(ring)], ring[k]]); cols.append(SPOT)
    nsp += 1
print('spots', nsp)

# ---------------- face: eyes in navy sockets on the head corners, a big smile on the cream front
for side in (-1, 1):
    ex = CX + side * 124
    ey = 112
    add_ball(P(ex, ey + 6, 22), 33 / S, NAVY, squash=(1, 0.8, 0.9))          # the socket bump
    add_ball(P(ex + side * -2, ey - 6, 24), 25 / S, BLACK, squash=(0.95, 0.8, 1))
    add_ball(P(ex + side * -8, ey - 22, 33), 7.5 / S, WHITE, seg=6, rings=4)   # catch-light
# mouth: a wide dark smile with a pink tongue, low on the face
add_ball(P(CX, 108, -10), 46 / S, MOUTH, seg=12, rings=6, squash=(1, 0.3, 0.42))
add_ball(P(CX, 103, -18), 24 / S, TONGUE, seg=8, rings=5, squash=(1, 0.35, 0.4))

json.dump({'verts': verts, 'faces': faces, 'col': cols, 'pal': PAL,
           'span': [float(np.min(outline[:, 0])), float(np.max(outline[:, 0]))]}, open(OUT, 'w'))
print('verts', len(verts), 'faces', len(faces), 'outline', nO)
