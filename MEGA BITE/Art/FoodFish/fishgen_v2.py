"""MEGA BITE food fish generator (10 Nov 2026). One script, per-species config. Traced from the ChatGPT model sheet.
Body = ring loft from the side profile (top/bottom per column) + the top-view half width; fins = thick plates traced
from the sheet (roots pushed into the body); pectorals hinged out from the flank; eyes = domes + shine; puffer spikes =
cones at the sheet's spike blobs. Colours = the sheet itself as ONE texture atlas (side view for flanks, top view for the
back), so stripes, spots and the face match the design exactly. Rig: Root + Spine0..Spine3 (tail wag is code in Roblox).
Run:  python3 fishgen.py <Species> [out_dir]
"""
import sys, os, json, math
import numpy as np, cv2
from PIL import Image
from scipy import ndimage as ndi
import bpy, bmesh
from mathutils import Vector, Matrix

SP = sys.argv[1] if len(sys.argv) > 1 else 'Sardine'
OUT = sys.argv[2] if len(sys.argv) > 2 else f'/home/claude/megabite_fish/out/{SP}'
os.makedirs(OUT, exist_ok=True)
SHEET = f'/mnt/user-data/uploads/Claude+Obsidian/MEGA BITE/Art/FoodFish/{SP}/{SP}_sheet_chatgpt.png'

# ---------------------------------------------------------------- per-species config
CFG = {
    'Sardine':  dict(length=3.0, fin=[(153, 181, 207)], fin_tol=34, exp=2.4),
    'Mackerel': dict(length=7.5, fin=[(112, 139, 166)], fin_tol=30, exp=2.2),
    'Puffer':   dict(length=3.6, fin=[(233, 138, 53)], fin_tol=34, not_fin=[(150, 100, 56)], not_fin_tol=50, spike=[(247, 213, 112)], spike_tol=34,
                     spots=[(154, 104, 58)], exp=2.0, nose_keep=60),
    'Damsel':   dict(length=3.0, exp=2.1, manual_body=[  # (x, top, bottom) in sheet px, tail base -> nose
        (492, 226, 330), (515, 212, 342), (560, 182, 385), (620, 140, 425), (700, 110, 450), (800, 98, 462),
        (900, 100, 462), (1000, 125, 450), (1080, 165, 420), (1130, 220, 365), (1158, 278, 318)],
        pec=dict(col=(252, 207, 45), tol=40, box=(740, 270, 960, 430))),
    'Tuna':     dict(length=10.5, fin=[(252, 216, 32)], fin_tol=42, paint_frac=0.45, finmin=90, pec_min=2500, exp=2.2),
    'Squid':    dict(length=5.6 * (1398 - 548) / (1398 - 118), fin=[(160, 208, 250)], fin_tol=34, top_fins=True, exp=2.3, eyes_left=True,
                     arms=dict(x=548, full=(118, 1398), col=(139, 148, 238), tip=(165, 172, 245), n=8)),
    'GoldenFish': dict(length=3.6, crest_open=30, fin=[(149, 234, 239), (234, 251, 251)], fin_tol=40, exp=2.0),
    'Shrimp':   dict(length=2.3, fin=[(253, 211, 159)], fin_tol=22, exp=2.2, body_open=4, body_close=1, longest_run=True, antennae=True, eye_stalk=True, stalk_col=(250, 118, 58)),
}[SP]

# ---------------------------------------------------------------- sheet analysis
im = np.asarray(Image.open(SHEET).convert('RGB')).astype(np.float32)
H, W, _ = im.shape
dmag = np.sqrt(((im - np.array([255, 0, 255])) ** 2).sum(-1))
lab, n = ndi.label(dmag < 90)
border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
fg = ~np.isin(lab, list(border))
fg = ndi.binary_opening(fg, iterations=1)

def split_views(fg):
    lab, n = ndi.label(fg)
    rows = fg.sum(1); cand = [y for y in range(int(H * .35), int(H * .7)) if rows[y] == 0]
    ys = int(np.median(cand)) if cand else int(H * .55)
    cols = fg[ys:].sum(0); cx = [x for x in range(int(W * .45), int(W * .85)) if cols[x] == 0]
    xs = int(np.median(cx)) if cx else int(W * .62)
    side = np.zeros_like(fg); top = np.zeros_like(fg); front = np.zeros_like(fg)
    for i in range(1, n + 1):
        m = lab == i
        if m.sum() < 150: continue
        yy, xx = np.where(m)
        if yy.mean() < ys: side |= m
        elif xx.mean() < xs: top |= m
        else: front |= m
    return side, top, front
SIDE, TOP, FRONT = split_views(fg)

def near(cols, tol, mask):
    out = np.zeros(mask.shape, bool)
    for c in cols:
        out |= (np.sqrt(((im - np.array(c)) ** 2).sum(-1)) < tol)
    return out & mask

def largest(m):
    l, k = ndi.label(m)
    if k == 0: return m
    s = ndi.sum(m, l, range(1, k + 1)); return l == (int(np.argmax(s)) + 1)

# body silhouette in the side view
if 'manual_body' in CFG:
    pts = CFG['manual_body']
    poly = [(x, t) for x, t, b in pts] + [(x, b) for x, t, b in reversed(pts)]
    BODY = np.zeros((H, W), np.uint8); cv2.fillPoly(BODY, [np.array(poly, np.int32)], 1); BODY = BODY.astype(bool) & SIDE
    FIN = SIDE & ~BODY
    FIN = ndi.binary_opening(FIN, iterations=2)
    if 'pec' in CFG:
        x0_, y0_, x1_, y1_ = CFG['pec']['box']
        pm = near([CFG['pec']['col']], CFG['pec']['tol'], SIDE); box = np.zeros_like(pm); box[y0_:y1_, x0_:x1_] = True
        FIN |= ndi.binary_fill_holes(ndi.binary_opening(pm & box, iterations=2))
else:
    FIN = near(CFG['fin'], CFG['fin_tol'], SIDE)
    if 'not_fin' in CFG: FIN &= ~ndi.binary_dilation(near(CFG['not_fin'], CFG['not_fin_tol'], SIDE), iterations=3)
    SPK = near(CFG.get('spike', []), CFG.get('spike_tol', 30), SIDE)
    FIN = ndi.binary_opening(FIN, iterations=1)
    b = SIDE & ~FIN & ~SPK
    b = ndi.binary_opening(b, iterations=CFG.get('body_open', 3))   # (shrimp: 7 strips the antennae)
    BODY = ndi.binary_fill_holes(largest(b))
    BODY = ndi.binary_closing(BODY, iterations=CFG.get('body_close', 6))
    BODY = ndi.binary_fill_holes(BODY)
    if CFG.get('nose_keep'):   # orange pouty mouth at the nose = body
        xs_ = np.where(BODY.any(0))[0]; nose = xs_.max()
        l, k = ndi.label(FIN)
        for i in range(1, k + 1):
            yy, xx = np.where(l == i)
            if xx.mean() > nose - CFG['nose_keep']: BODY |= (l == i); FIN &= ~(l == i)
        BODY = ndi.binary_fill_holes(ndi.binary_closing(BODY, iterations=3))

if CFG.get('crest_open'):   # a thin crest/star on the head: not body, a plate (traced outline, sheet colours)
    bo = ndi.binary_fill_holes(largest(ndi.binary_opening(BODY, iterations=CFG['crest_open'])))
    cr = BODY & ~ndi.binary_dilation(bo, iterations=2)
    lcr, kcr = ndi.label(cr)
    if kcr:
        sz = ndi.sum(cr, lcr, range(1, kcr + 1)); ci = int(np.argmax(sz)) + 1
        if sz[ci - 1] > 300:
            crest = lcr == ci
            BODY = bo; FIN |= crest
if 'arms' in CFG:   # squid: the loft is mantle + head only; the arms are built as their own tubes below
    BODY[:, :CFG['arms']['x']] = False; BODY = largest(BODY)
bx = np.where(BODY.any(0))[0]; X0, X1 = int(bx.min()), int(bx.max())     # tail base .. nose (px)
YT = np.full(W, np.nan); YB = np.full(W, np.nan)
for x in range(X0, X1 + 1):
    c = np.where(BODY[:, x])[0]
    if len(c) and CFG.get('longest_run'):   # only the main run of the column (antennae above are separate runs)
        runs = np.split(c, np.where(np.diff(c) > 1)[0] + 1); c = max(runs, key=len)
    if len(c): YT[x], YB[x] = c.min(), c.max()
xs_ = np.arange(X0, X1 + 1)
YT[X0:X1 + 1] = ndi.gaussian_filter1d(np.interp(xs_, xs_[~np.isnan(YT[X0:X1 + 1])], YT[X0:X1 + 1][~np.isnan(YT[X0:X1 + 1])]), 2)
YB[X0:X1 + 1] = ndi.gaussian_filter1d(np.interp(xs_, xs_[~np.isnan(YB[X0:X1 + 1])], YB[X0:X1 + 1][~np.isnan(YB[X0:X1 + 1])]), 2)
def yt(px): return float(np.interp(px, xs_, YT[X0:X1 + 1]))
def yb(px): return float(np.interp(px, xs_, YB[X0:X1 + 1]))
ZMID = float(np.nanmean((YT[X0:X1 + 1] + YB[X0:X1 + 1]) / 2))
S = CFG['length'] / float(X1 - X0)            # studs per px (body length = config length; fins add to it)
def X(px): return (px - X1) * S               # nose at 0, tail toward -X
def Z(py): return (ZMID - py) * S
def PX(x): return X1 + x / S
def PY(z): return ZMID - z / S

# top view: body half width per side-x (fins in the top view removed the same way)
if 'manual_body' in CFG:
    TB = TOP.copy()
    TB = ndi.binary_opening(TB, iterations=12)
else:
    TF = near(CFG['fin'], CFG['fin_tol'], TOP)
    TS = near(CFG.get('spike', []), CFG.get('spike_tol', 30), TOP)
    TB = ndi.binary_opening(TOP & ~TF & ~TS, iterations=3)
TB = ndi.binary_fill_holes(ndi.binary_closing(largest(TB), iterations=5))
if 'arms' in CFG:
    txf = np.where(TB.any(0))[0]; f0, f1 = CFG['arms']['full']
    tcut = int(txf.min() + (CFG['arms']['x'] - f0) / (f1 - f0) * (txf.max() - txf.min()))
    TB[:, :tcut] = False; TB = largest(TB)
tx = np.where(TB.any(0))[0]; T0, T1 = int(tx.min()), int(tx.max())
# map top-view x to side x by matching the body ends; the same factor scales the width
KT = (X1 - X0) / float(T1 - T0)
HW = np.zeros(X1 - X0 + 1); YC = np.zeros(X1 - X0 + 1)
for i, sx in enumerate(range(X0, X1 + 1)):
    tx_ = T0 + (sx - X0) / KT
    c = np.where(TB[:, int(round(min(max(tx_, T0), T1)))])[0]
    if len(c): HW[i] = (c.max() - c.min()) / 2 * KT; YC[i] = (c.max() + c.min()) / 2
HW = ndi.gaussian_filter1d(HW, 2); TYC = float(np.median(YC[YC > 0]))
def hw(px): return float(np.interp(px, xs_, HW))
def side2top(px, ylat):   # side px + lateral offset (studs) -> top-view pixel
    return T0 + (px - X0) / KT, TYC - ylat / S / KT

# ---------------------------------------------------------------- texture atlas (1024 x 1024: body side / fins side / top / palette)
def crop_box(mask, pad=12):
    yy, xx = np.where(mask); return max(0, xx.min() - pad), max(0, yy.min() - pad), min(W, xx.max() + pad), min(H, yy.max() + pad)
def bleed(rgb, mask, it=None):
    """fill the background with the NEAREST clean foreground colour, so UV edges never sample magenta"""
    m = ndi.binary_erosion(mask, iterations=1)
    if not m.any(): return rgb
    _, (iy, ix) = ndi.distance_transform_edt(~m, return_indices=True)
    return rgb[iy, ix]
# body texture: the side view with the pectoral fins painted out (inpaint)
l, k = ndi.label(FIN); PECS = []
FINMIN = CFG.get('finmin') or max(120, 0.04 * max([(l == i).sum() for i in range(1, k + 1)] or [0]))
def is_paint(c):   # long thin coloured stripe inside the body (tuna gold line) = texture, not a fin
    if 'paint_frac' not in CFG: return False
    xx_ = np.where(c.any(0))[0]; return (xx_.max() - xx_.min()) > CFG['paint_frac'] * (X1 - X0)
if 'paint_frac' in CFG:   # a fin touching the stripe: open the stripe away, keep the chunky fin part
    l0, k0 = ndi.label(FIN)
    for i in range(1, k0 + 1):
        c = l0 == i
        if is_paint(c):
            FIN &= ~c
            stripe = ndi.binary_opening(c, structure=np.ones((1, CFG.get('paint_run', 160)), bool))   # long horizontal runs = the stripe
            rest = c & ~ndi.binary_dilation(stripe, iterations=3)
            FIN |= ndi.binary_opening(rest, iterations=2)
    l, k = ndi.label(FIN)
for i in range(1, k + 1):
    c = l == i
    if c.sum() < FINMIN or is_paint(c): continue
    inside = (c & ndi.binary_erosion(BODY, iterations=4)).sum() / c.sum()
    if inside > 0.5 and c.sum() >= CFG.get('pec_min', 0): PECS.append(c)
pecmask = np.zeros_like(BODY)
for c in PECS: pecmask |= c
base8 = bleed(im, fg & (dmag > 200)).clip(0, 255).astype(np.uint8)   # background -> nearest fish colour, so inpainting never pulls in magenta
def eye_blob(region, x_front):
    # the painted eye = the biggest very dark blob toward the head (spots/stripes are lighter than sum 150)
    dk = region & (im.sum(-1) < 150); le_, ke_ = ndi.label(dk); best_ = None
    for i in range(1, ke_ + 1):
        m_ = le_ == i; n_ = m_.sum()
        if n_ < 60: continue
        yy_, xx_ = np.where(m_)
        sc_ = n_ * (1 + (xx_.mean() - x_front[0]) / max(x_front[1] - x_front[0], 1))
        if best_ is None or sc_ > best_[0]: best_ = (sc_, m_)
    return best_[1] if best_ else np.zeros_like(region)
EYEPAINT = ndi.binary_fill_holes(ndi.binary_dilation(eye_blob(ndi.binary_erosion(BODY, iterations=2), (X0, X1)), iterations=8))
body_tex = cv2.inpaint(base8, (ndi.binary_dilation(ndi.binary_fill_holes(ndi.binary_closing(pecmask, iterations=4)), iterations=CFG.get('pec_grow', 12)) | EYEPAINT).astype(np.uint8), 9, cv2.INPAINT_TELEA)
# (the top view: pectorals sticking out are outside the body mask anyway)
AT = 1024
ROWS = {'A': (0, 320), 'B': (320, 640), 'C': (640, 960)}
atlas = np.zeros((AT, AT, 3), np.float32)
bxA = crop_box(SIDE); bxC = crop_box(TOP)
def put(row, src, mask, box):
    x0, y0, x1, y1 = box
    sub = bleed(src[y0:y1, x0:x1].astype(np.float32), mask[y0:y1, x0:x1])
    r0, r1 = ROWS[row]
    atlas[r0:r1] = np.asarray(Image.fromarray(sub.clip(0, 255).astype(np.uint8)).resize((AT, r1 - r0), Image.LANCZOS)).astype(np.float32)
CLEAN = dmag > 200   # anti-aliased magenta fringe pixels are not colour sources
AMASK = (BODY | (SIDE & ~FIN)) & CLEAN
if CFG.get('eye_stalk'): AMASK &= ~ndi.binary_dilation(SIDE & (im.sum(-1) < 150), iterations=18)   # stalk eyes are their own spheres
put('A', body_tex, AMASK, bxA)
put('B', im, SIDE & CLEAN, bxA)
if 'fin' in CFG:
    tf = near(CFG['fin'], CFG['fin_tol'] + 18, TOP) & ndi.binary_erosion(TB, iterations=3)
    tf = ndi.binary_opening(tf, iterations=2)
    top_tex = cv2.inpaint(base8, ndi.binary_dilation(ndi.binary_fill_holes(tf), iterations=16).astype(np.uint8), 15, cv2.INPAINT_NS)
else:
    top_tex = base8
tdark = TOP & (im.sum(-1) < 150)
if not CFG.get('eyes_left'): tdark[:, :int(T0 + (T1 - T0) * 0.6)] = False      # eyes sit in the front of the top view
teye = ndi.binary_fill_holes(ndi.binary_dilation(tdark, iterations=8))
if not CFG.get('eye_stalk'): top_tex = cv2.inpaint(top_tex, teye.astype(np.uint8), 9, cv2.INPAINT_TELEA)   # (stalk eyes: the bleed fills them)
put('C', top_tex, TOP & CLEAN & ~teye, bxC)
print('pectorals found', len(PECS), 'pec px', int(pecmask.sum()))
# palette swatches (row D): black eye, white shine, spike colour
SW = {'black': (18, 18, 22), 'white': (250, 250, 252), 'spike': tuple(CFG.get('spike', [(240, 240, 240)])[0]),
      'stalk': tuple(CFG.get('stalk_col', (200, 200, 200))),
      'arm': tuple(CFG['arms']['col']) if 'arms' in CFG else (200, 200, 200), 'armtip': tuple(CFG['arms']['tip']) if 'arms' in CFG else (220, 220, 220)}
for i, (nm, c) in enumerate(SW.items()):
    atlas[960:1024, i * 64:(i + 1) * 64] = c
def uv_side(px, py, row='A'):
    x0, y0, x1, y1 = bxA; r0, r1 = ROWS[row]
    return ((px - x0) / (x1 - x0), 1 - (r0 + (py - y0) / (y1 - y0) * (r1 - r0)) / AT)
def uv_top(tx, ty):
    x0, y0, x1, y1 = bxC; r0, r1 = ROWS['C']
    return ((tx - x0) / (x1 - x0), 1 - (r0 + (ty - y0) / (y1 - y0) * (r1 - r0)) / AT)
def uv_sw(nm):
    i = list(SW).index(nm); return ((i * 64 + 32) / AT, 1 - 992 / AT)
Image.fromarray(atlas.clip(0, 255).astype(np.uint8)).save(f'{OUT}/{SP}_atlas.png')

# ---------------------------------------------------------------- build
for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
for m in list(bpy.data.meshes): bpy.data.meshes.remove(m)
bm = bmesh.new()
uvl = bm.loops.layers.uv.new('UVMap')
KIND = bm.faces.layers.int.new('kind')     # 0 body, 1 fin, 2 eye/swatch
EXP = CFG.get('exp', 2.2)
M = 16
def ring_pts(px):
    a = (yb(px) - yt(px)) / 2 * S; b = max(hw(px) * S, 0.02); zc = Z((yt(px) + yb(px)) / 2)
    pts = []
    for j in range(M):
        th = 2 * math.pi * j / M
        c, s = math.cos(th), math.sin(th)
        y = b * math.copysign(abs(c) ** (2 / EXP), c); z = zc + a * math.copysign(abs(s) ** (2 / EXP), s)
        pts.append(Vector((X(px), y, z)))
    return pts
L = X1 - X0
stations = sorted(set([X0 + int(round(L * t)) for t in
                       np.concatenate([np.linspace(0, 0.12, 4), np.linspace(0.15, 0.85, 12), 1 - (np.linspace(0.12, 0, 7) ** 1.0)])]))
stations[-1] = X1 - 2
rings = [[bm.verts.new(p) for p in ring_pts(sx)] for sx in stations]
tip = bm.verts.new(Vector((X(X1) + 0.0, 0, Z((yt(X1 - 2) + yb(X1 - 2)) / 2))))
tailc = bm.verts.new(Vector((X(X0) - 0.01, 0, Z((yt(X0) + yb(X0)) / 2))))
def addf(vs):
    try: return bm.faces.new(vs)
    except ValueError: return None
for i in range(len(rings) - 1):
    for j in range(M):
        a, b2, c, d = rings[i][j], rings[i][(j + 1) % M], rings[i + 1][(j + 1) % M], rings[i + 1][j]
        f1 = addf([a, b2, c]); f2 = addf([a, c, d])
for j in range(M):
    addf([rings[-1][j], rings[-1][(j + 1) % M], tip])
    addf([rings[0][(j + 1) % M], rings[0][j], tailc])
bm.normal_update()
for f in bm.faces:
    f[KIND] = 0
# fins
def plate(poly_px, side_y=0.0, hinge=None, row='B', thick=None):
    """flat fin plate from a side-view pixel polygon; side_y = lateral offset; hinge=(axis_point, angle) rotates out"""
    t = thick if thick is not None else max(0.03, CFG['length'] * 0.012)
    P = [Vector((X(px), side_y, Z(py))) for px, py in poly_px]
    nrm = Vector((0, 1, 0))
    if hinge is not None:
        piv, R = hinge          # R = 3x3 rotation about the fin root
        P = [piv + (R @ (p - piv)) for p in P]
        nrm = R @ Vector((0, 1, 0))
    A = [bm.verts.new(p + nrm * t / 2) for p in P]; B = [bm.verts.new(p - nrm * t / 2) for p in P]
    fa = addf(A); fb = addf(list(reversed(B)))
    faces = [f for f in (fa, fb) if f]
    for i in range(len(P)):
        f = addf([A[i], B[i], B[(i + 1) % len(P)], A[(i + 1) % len(P)]])
        if f: faces.append(f)
    for f in faces:
        f[KIND] = 1
        for lp in f.loops:
            # UV from the original side pixel of this vertex
            idx = (A.index(lp.vert) if lp.vert in A else B.index(lp.vert))
            lp[uvl].uv = uv_side(*poly_px[idx], row=row)
    return faces
def contour(mask, eps=2.0):
    cs, _ = cv2.findContours(mask.astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    c = max(cs, key=cv2.contourArea)
    ap = cv2.approxPolyDP(c, eps, True)[:, 0, :]
    return [(int(x), int(y)) for x, y in ap]
l, k = ndi.label(FIN)
body_in = ndi.binary_erosion(BODY, iterations=4)
for i in range(1, k + 1):
    c = l == i
    if os.environ.get('FDBG'):
        yy_, xx_ = np.where(c); print('FINCOMP', c.sum(), xx_.min(), xx_.max(), yy_.min(), yy_.max(), 'paint', is_paint(c), 'inside', round((c & body_in).sum() / c.sum(), 2))
    if c.sum() < FINMIN or is_paint(c): continue
    inside = (c & body_in).sum() / c.sum()
    if CFG.get('top_fins'): continue   # squid: its fins stick out SIDEWAYS, traced from the top view below
    if inside > 0.5 and c.sum() < CFG.get('pec_min', 0): continue   # small painted mark (mouth line) stays paint
    if inside > 0.5:
        # pectoral: hinge along its root (the front/top edge), out from the flank, both sides
        yy, xx = np.where(c)
        rx = xx.max() - (xx.max() - xx.min()) * 0.15; ry = yy.mean()
        poly = contour(c, 1.6)
        # the flank surface at the fin root height (superellipse), fin root tucked just inside it
        top_, bot_ = yt(rx), yb(rx); a_ = (bot_ - top_) / 2; zc_ = (top_ + bot_) / 2
        dz = min(abs(ry - zc_) / max(a_, 1), 0.95)
        lat = hw(rx) * (1 - dz ** EXP) ** (1 / EXP) * S * 0.9
        yaw, roll = math.radians(CFG.get('pec_yaw', 30)), math.radians(CFG.get('pec_roll', 25))
        for sgn in (1, -1):
            piv = Vector((X(rx), sgn * lat, Z(ry)))
            # choose the rotation signs that swing the fin tip (behind + below the root) OUT from the body
            best = None
            for sy in (1, -1):
                for sr in (1, -1):
                    R = (Matrix.Rotation(sy * yaw, 3, 'Z') @ Matrix.Rotation(sr * roll, 3, 'X'))
                    P = [piv + R @ (Vector((X(px), sgn * lat, Z(py))) - piv) for px, py in poly]
                    out = sum(abs(p.y) for p in P) / len(P)
                    if best is None or out > best[0]: best = (out, R)
            plate(poly, side_y=sgn * lat, hinge=(piv, best[1]))
    else:
        # centre fin (dorsal, anal, tail, pelvic): push the root ~14 px into the body
        ext = c | (ndi.binary_dilation(c, iterations=14) & BODY)
        plate(contour(ext, 2.0))

# squid: lateral fins = horizontal plates traced from the TOP view
def plate_h(poly_t, thick=None):
    t = thick if thick is not None else max(0.03, CFG['length'] * 0.012)
    P = []
    for tx_, ty_ in poly_t:
        sx = X0 + (tx_ - T0) * KT
        sxc = min(max(sx, X0), X1)
        P.append(Vector((X(sx), (TYC - ty_) * S * KT, Z((yt(sxc) + yb(sxc)) / 2))))
    A = [bm.verts.new(p + Vector((0, 0, t / 2))) for p in P]; B = [bm.verts.new(p - Vector((0, 0, t / 2))) for p in P]
    faces = [f for f in (addf(A), addf(list(reversed(B)))) if f]
    for i in range(len(P)):
        f = addf([A[i], B[i], B[(i + 1) % len(P)], A[(i + 1) % len(P)]])
        if f: faces.append(f)
    for f in faces:
        f[KIND] = 1
        for lp in f.loops:
            idx = (A.index(lp.vert) if lp.vert in A else B.index(lp.vert))
            lp[uvl].uv = uv_top(*poly_t[idx])
if CFG.get('top_fins'):
    TFm = ndi.binary_opening(near(CFG['fin'], CFG['fin_tol'], TOP), iterations=2)
    lt, kt = ndi.label(TFm)
    for i in range(1, kt + 1):
        c = lt == i
        if c.sum() < 400: continue
        ext = c | (ndi.binary_dilation(c, iterations=14) & TB)
        plate_h(contour(ext, 2.0))
    # the top-view texture row keeps the fins (they are UV'd from it)

# eyes: the darkest blob on the head
dark = SIDE & (im.sum(-1) < 150) & ndi.binary_erosion(BODY, iterations=2)
le, ke = ndi.label(dark); best = None
for i in range(1, ke + 1):
    yy, xx = np.where(le == i)
    if len(yy) < 60: continue
    score = len(yy) * (1 + (xx.mean() - X0) / L)
    if best is None or score > best[0]: best = (score, xx.mean(), yy.mean(), math.sqrt(len(yy) / math.pi))
EYE = None
if CFG.get('eye_stalk'):   # shrimp: the eyes sit on stalks ABOVE the head (outside the body outline)
    dk = SIDE & (im.sum(-1) < 150); le2, ke2 = ndi.label(dk); best = None
    for i in range(1, ke2 + 1):
        yy, xx = np.where(le2 == i)
        if len(yy) < 200: continue
        if best is None or len(yy) > best[0]: best = (len(yy), xx.mean(), yy.mean(), math.sqrt(len(yy) / math.pi))
    tdk = TOP & (im.sum(-1) < 150); lt2, kt2 = ndi.label(tdk); offs = []
    for i in range(1, kt2 + 1):
        yy, xx = np.where(lt2 == i)
        if len(yy) > 150: offs.append(abs(yy.mean() - TYC))
    if best:
        _, ex, ey, er = best
        lat = (np.mean(offs) if offs else hw(min(ex, X1)) * 0.6) * S * KT
        r = er * S
        for sgn in (1, -1):
            cen = Vector((X(ex), sgn * lat, Z(ey)))
            res = bmesh.ops.create_uvsphere(bm, u_segments=10, v_segments=6, radius=r)
            for v in res['verts']: v.co = v.co + cen
            for f in {f for v in res['verts'] for f in v.link_faces}:
                f[KIND] = 2
                for lp in f.loops: lp[uvl].uv = uv_sw('black')
            sc = cen + Vector((r * 0.45, sgn * r * 0.35, r * 0.5))
            res = bmesh.ops.create_uvsphere(bm, u_segments=6, v_segments=4, radius=r * 0.24)
            for v in res['verts']: v.co = v.co + sc
            for f in {f for v in res['verts'] for f in v.link_faces}:
                f[KIND] = 2
                for lp in f.loops: lp[uvl].uv = uv_sw('white')
            # the stalk: a short cone from inside the head up to the eye
            exc = min(ex, X1 - 4); base = Vector((X(exc), sgn * lat * 0.6, Z(yt(exc)) - r * 0.8))
            d = cen - base; res = bmesh.ops.create_cone(bm, cap_ends=True, segments=6, radius1=r * 0.42, radius2=r * 0.3, depth=d.length)
            q = Vector((0, 0, 1)).rotation_difference(d.normalized())
            for v in res['verts']: v.co = base + d * 0.5 + q @ v.co
            for f in {f for v in res['verts'] for f in v.link_faces}:
                f[KIND] = 2
                for lp in f.loops: lp[uvl].uv = uv_sw('stalk')
    best = None
if best:
    _, ex, ey, er = best
    EYE = (ex, ey, er)
    a = (yb(ex) - yt(ex)) / 2; zc = (yt(ex) + yb(ex)) / 2; b = hw(ex)
    dz = min(abs(ey - zc) / max(a, 1), 0.95)
    lat = max(b * (1 - dz ** EXP) ** (1 / EXP), b * 0.35)
    # surface normal of the superellipse at the eye (side px units), so the dome sits flush on the head
    zrel = (zc - ey) / max(a, 1)                       # +1 = top
    ny_ = (lat / max(b, 1)) ** (EXP - 1) / max(b, 1); nz_ = math.copysign(abs(zrel) ** (EXP - 1) / max(a, 1), zrel)
    lat *= S; r = er * S
    for sgn in (1, -1):
        nrm = (Vector((0, sgn * ny_, nz_)).normalized() + Vector((CFG.get('eye_fwd', 0.18), 0, 0))).normalized()
        cen = Vector((X(ex), sgn * lat, Z(ey))) - nrm * r * 0.12
        q = Vector((0, 0, 1)).rotation_difference(nrm)
        res = bmesh.ops.create_uvsphere(bm, u_segments=10, v_segments=5, radius=1.0)
        for v in res['verts']:
            v.co = cen + q @ Vector((v.co.x * r * 1.02, v.co.y * r * 1.02, v.co.z * r * 0.42))
        for f in {f for v in res['verts'] for f in v.link_faces}:
            f[KIND] = 2
            for lp in f.loops: lp[uvl].uv = uv_sw('black')
        # shine: a small flat disc up-front on the dome
        up_ = (Vector((0, 0, 1)) - nrm * nrm.z).normalized() if abs(nrm.z) < 0.95 else Vector((1, 0, 0))
        fw_ = nrm.cross(up_).normalized()
        if fw_.x < 0: fw_ = -fw_
        sc = cen + nrm * r * 0.40 + up_ * r * 0.30 + fw_ * r * 0.22
        res = bmesh.ops.create_uvsphere(bm, u_segments=6, v_segments=4, radius=1.0)
        for v in res['verts']:
            v.co = sc + q @ Vector((v.co.x * r * 0.22, v.co.y * r * 0.22, v.co.z * r * 0.08))
        for f in {f for v in res['verts'] for f in v.link_faces}:
            f[KIND] = 2
            for lp in f.loops: lp[uvl].uv = uv_sw('white')

def tube(path, radii, uvname, segs=6):
    rings_ = []
    for k_, (p, r) in enumerate(zip(path, radii)):
        d = (path[min(k_ + 1, len(path) - 1)] - path[max(k_ - 1, 0)]).normalized()
        u = d.cross(Vector((0, 0, 1)))
        if u.length < 1e-4: u = d.cross(Vector((0, 1, 0)))
        u.normalize(); v_ = d.cross(u).normalized()
        rings_.append([bm.verts.new(p + (u * math.cos(2 * math.pi * j / segs) + v_ * math.sin(2 * math.pi * j / segs)) * max(r, 0.004)) for j in range(segs)])
    fs = []
    for k_ in range(len(rings_) - 1):
        for j in range(segs):
            a1, b1, c1, d1 = rings_[k_][j], rings_[k_][(j + 1) % segs], rings_[k_ + 1][(j + 1) % segs], rings_[k_ + 1][j]
            fs += [addf([a1, b1, c1]), addf([a1, c1, d1])]
    tipv = bm.verts.new(path[-1] + (path[-1] - path[-2]).normalized() * radii[-1] * 0.8)
    for j in range(segs): fs.append(addf([rings_[-1][j], rings_[-1][(j + 1) % segs], tipv]))
    cap = bm.verts.new(path[0] - (path[1] - path[0]).normalized() * radii[0] * 0.3)
    for j in range(segs): fs.append(addf([rings_[0][(j + 1) % segs], rings_[0][j], cap]))
    for f in fs:
        if not f: continue
        f[KIND] = 2
        for lp in f.loops: lp[uvl].uv = uv_sw(uvname)

# squid arms: 8 tapered 6-sided tubes from the head, bulging out then gathering to a point, + 2 tentacles with round clubs
if 'arms' in CFG:
    A_ = CFG['arms']; ax0 = X0
    f0 = A_['full'][0]
    a_h = (yb(ax0 + 3) - yt(ax0 + 3)) / 2 * S; b_h = hw(ax0 + 3) * S; zc_h = Z((yt(ax0 + 3) + yb(ax0 + 3)) / 2)
    xb = X(ax0 + 4); span = (ax0 - f0) * S
    n = A_['n']
    for i in range(n):
        th = 2 * math.pi * (i + 0.5) / n
        cy, cz = math.cos(th), math.sin(th)
        ts = [0.0, 0.18, 0.42, 0.68, 0.9]
        path = []
        for t_ in ts:
            spread = 0.62 + 0.55 * math.sin(math.pi * min(t_ / 0.6, 1.0) * 0.5) - 0.9 * max(t_ - 0.45, 0)   # flare out, then gather
            path.append(Vector((xb - span * 0.78 * t_, cy * b_h * spread, zc_h + cz * a_h * spread)))
        rad = [min(a_h, b_h) * k_ for k_ in (0.34, 0.33, 0.27, 0.17, 0.07)]
        tube(path, rad, 'arm')
    for sgn in (1, -1):   # the 2 tentacles + clubs
        path = [Vector((xb - span * t_, sgn * b_h * (0.18 + 0.1 * math.sin(math.pi * t_)), zc_h + sgn * a_h * 0.12)) for t_ in (0.0, 0.3, 0.6, 0.86)]
        tube(path, [min(a_h, b_h) * k_ for k_ in (0.16, 0.14, 0.12, 0.11)], 'arm')
        res = bmesh.ops.create_uvsphere(bm, u_segments=8, v_segments=5, radius=1.0)
        cc = path[-1] + Vector((-min(a_h, b_h) * 0.22, 0, 0))
        for v in res['verts']: v.co = cc + Vector((v.co.x * min(a_h, b_h) * 0.36, v.co.y * min(a_h, b_h) * 0.24, v.co.z * min(a_h, b_h) * 0.24))
        for f in {f for v in res['verts'] for f in v.link_faces}:
            f[KIND] = 2
            for lp in f.loops: lp[uvl].uv = uv_sw('armtip')

if CFG.get('antennae'):   # shrimp: 2 thin antennae from the head, sweeping back over the body (like the sheet)
    hx = X1 - (X1 - X0) * 0.12; a_h = (yb(hx) - yt(hx)) / 2 * S; zt = Z(yt(hx))
    for sgn in (1, -1):
        path = [Vector((X(hx), sgn * a_h * 0.25, zt - a_h * 0.1)), Vector((X(hx) - 0.05 * CFG['length'], sgn * a_h * 0.32, zt + a_h * 0.6)),
                Vector((X(hx) - 0.3 * CFG['length'], sgn * a_h * 0.42, zt + a_h * 0.95)), Vector((X(hx) - 0.62 * CFG['length'], sgn * a_h * 0.5, zt + a_h * 1.0))]
        tube(path, [a_h * 0.09, a_h * 0.08, a_h * 0.06, a_h * 0.04], 'stalk', segs=5)

# puffer spikes: cones at the spike blobs (rim -> up/down, flank -> sideways)
if 'spike' in CFG:
    SPK = near(CFG['spike'], CFG['spike_tol'], SIDE)
    ls, ks = ndi.label(ndi.binary_opening(SPK, iterations=1))
    for i in range(1, ks + 1):
        yy, xx = np.where(ls == i)
        if len(yy) < 40: continue
        sx, sy = xx.mean(), yy.mean(); size = math.sqrt(len(yy)) * S * 1.25
        if sx < X0 + 6 or sx > X1 - 6: continue
        top_, bot_ = yt(sx), yb(sx)
        a = (bot_ - top_) / 2; zc = (top_ + bot_) / 2
        rim = (sy < top_ + a * 0.25) or (sy > bot_ - a * 0.25)
        targets = []
        if rim:
            up = 1 if sy < zc else -1
            zz = Z(top_ if up > 0 else bot_)
            targets.append((Vector((X(sx), 0, zz - up * size * 0.25)), Vector((0, 0, up))))
        else:
            dz = min(abs(sy - zc) / max(a, 1), 0.95)
            lat = hw(sx) * (1 - dz ** EXP) ** (1 / EXP) * S
            nz = (zc - sy) / max(a, 1) * 0.6
            for sgn in (1, -1):
                nrm = Vector((0, sgn, nz)).normalized()
                targets.append((Vector((X(sx), sgn * lat, Z(sy))) - nrm * size * 0.25, nrm))
        for base_p, nrm in targets:
            res = bmesh.ops.create_cone(bm, cap_ends=True, segments=7, radius1=size * 0.5, radius2=size * 0.16, depth=size * 0.85)
            q = Vector((0, 0, 1)).rotation_difference(nrm)
            for v in res['verts']:
                v.co = (q @ v.co) + base_p + nrm * size * 0.5
            for f in {f for v in res['verts'] for f in v.link_faces}:
                f[KIND] = 2
                for lp in f.loops: lp[uvl].uv = uv_sw('spike')

# body UVs: flank faces from the (fin-free) side view, back faces from the top view
for f in bm.faces:
    if f[KIND] != 0: continue
    nz = f.normal.z
    for lp in f.loops:
        v = lp.vert.co
        if nz > 0.72:
            tx_, ty_ = side2top(PX(v.x), v.y); lp[uvl].uv = uv_top(tx_, ty_)
        else:
            lp[uvl].uv = uv_side(PX(v.x), PY(v.z), 'A')
bmesh.ops.recalc_face_normals(bm, faces=[f for f in bm.faces if f[KIND] == 0])
me = bpy.data.meshes.new(SP); bm.to_mesh(me); bm.free()
ob = bpy.data.objects.new(SP, me); bpy.context.scene.collection.objects.link(ob)
for p in me.polygons: p.use_smooth = False
# material with the atlas
img = bpy.data.images.load(f'{OUT}/{SP}_atlas.png'); img.name = f'{SP}_atlas'
mat = bpy.data.materials.new(SP + '_Mat'); mat.use_nodes = True
tn = mat.node_tree.nodes.new('ShaderNodeTexImage'); tn.image = img; tn.interpolation = 'Linear'
bsdf = mat.node_tree.nodes['Principled BSDF']; bsdf.inputs['Roughness'].default_value = 0.65
mat.node_tree.links.new(tn.outputs['Color'], bsdf.inputs['Base Color'])
me.materials.append(mat)

# ---------------------------------------------------------------- rig: Root + Spine0..3 (head -> tail)
arm = bpy.data.armatures.new(SP + 'Rig'); rig = bpy.data.objects.new(SP + 'Rig', arm)
bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig; bpy.ops.object.mode_set(mode='EDIT')
xmin = min(v.co.x for v in me.vertices); xmax = 0.0
zc0 = Z((yt(X0 + L * 0.6) + yb(X0 + L * 0.6)) / 2)
root = arm.edit_bones.new('Root'); root.head = (0, 0, 0); root.tail = (0, 0, S * 30)
NB = 4; joints = [xmax - (xmax - X(X0)) * t for t in (0.0, 0.35, 0.6, 0.8, 1.0)]
prev = root; bones = []
for i in range(NB):
    b_ = arm.edit_bones.new(f'Spine{i}'); b_.head = (joints[i], 0, zc0); b_.tail = (joints[i + 1], 0, zc0)
    b_.parent = prev; b_.use_connect = i > 0; prev = b_; bones.append(b_.name)
bpy.ops.object.mode_set(mode='OBJECT')
ob.parent = rig
mod = ob.modifiers.new('Armature', 'ARMATURE'); mod.object = rig
for nme in ['Root'] + bones: ob.vertex_groups.new(name=nme)
jx = joints
for v in me.vertices:
    x = v.co.x
    # weight along the body: head stiff, tail flexible (tail fin past the body follows Spine3)
    if x >= jx[1]: w = {'Spine0': 1.0}
    else:
        w = {}
        for i in range(1, NB):
            a_, b_ = jx[i], jx[i + 1] if i + 1 < len(jx) else jx[-1] - 1
            if b_ <= x <= a_ or (i == NB - 1 and x < a_):
                t = min(max((a_ - x) / max(a_ - b_, 1e-6), 0), 1)
                w = {f'Spine{i - 1}': 1 - t, f'Spine{i}': t} if i > 1 else {'Spine0': 1 - t, 'Spine1': t}
                if i == NB - 1 and x < b_: w = {f'Spine{NB - 1}': 1.0}
                break
        if not w: w = {f'Spine{NB - 1}': 1.0}
    for g, val in w.items():
        if val > 0.001: ob.vertex_groups[g].add([v.index], val, 'REPLACE')

tris = sum(len(p.vertices) - 2 for p in me.polygons)
info = dict(species=SP, tris=tris, length_studs=CFG['length'], S=S, X0=X0, X1=X1, eye=EYE,
            bbox=[[min(v.co[i] for v in me.vertices) for i in range(3)], [max(v.co[i] for v in me.vertices) for i in range(3)]])
json.dump(info, open(f'{OUT}/{SP}_info.json', 'w'), indent=1, default=float)
bpy.ops.wm.save_as_mainfile(filepath=f'{OUT}/{SP}.blend')
print('BUILT', json.dumps(info, default=float))
