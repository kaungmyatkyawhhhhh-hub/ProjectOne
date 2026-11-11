"""MEGA BITE Reef Shark v4 (9 Nov 2026): body TRACED from ReefShark_sheet_chatgpt.png, HEAD traced from the close-up
ReefShark_head_sheet_chatgpt.png (mouth opening, lip band, teeth tips, eye, socket, brow, gills = measured landmarks).
All outlines below are pixel coordinates measured on that sheet (side view: nose at x=1450; top view: nose at x=919).
Low-poly, flat shaded, flat colour regions (Fisch style). Builds into its own scene "MEGA BITE". Blender 4.x/5.x."""
import bpy, bmesh, math
from mathutils import Vector
from mathutils.bvhtree import BVHTree

def lin(h):
    c = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]
    return tuple((x / 12.92) if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c) + (1.0,)

PAL = dict(top="557693", belly="F7F8FA", tip="1E2127", mouth="6E2235", tooth="FBF8F0", eye="3FF2FF", gill="22272F")

# ---------- traced data (side view px) ----------
NOSE_PX, TAIL_PX = 1450, 285
S = 3.7 / 1158                      # metres per side-view px (body ~3.7 m nose to tail joint)
def X(px): return 2.15 + (px - NOSE_PX) * S
def Z(py): return (300 - py) * S
UP = [(285,276),(300,268),(340,258),(400,246),(460,240),(520,232),(580,224),(640,215),(700,203),(760,192),(820,180),(880,171),(940,165),(1000,162),(1060,163),(1120,170),(1180,178),(1240,187),(1300,201),(1360,216),(1390,224),(1420,233),(1440,244),(1450,258)]
LO = [(285,282),(300,300),(340,333),(400,343),(460,358),(520,367),(580,390),(640,404),(700,415),(760,426),(820,430),(880,432),(940,433),(1000,433),(1060,431),(1120,429),(1180,426),(1240,420),(1300,418),(1340,412),(1380,395),(1420,330),(1440,290),(1450,262)]
CORNER = 1238
PALATE = [(1238,302),(1290,292),(1400,298),(1432,292),(1450,262)]   # bottom edge of the upper jaw
JAWTOP = [(1238,302),(1262,362),(1330,388),(1360,400)]               # top edge of the open lower jaw
JAWBOT = [(1238,421),(1300,420),(1335,414),(1360,400)]
# top view: half-width in px at top-view x (nose 919, tail joint 190)
TOPW = [(190,13.5),(220,19.5),(250,26.5),(280,36),(310,39.5),(340,42),(370,50),(430,64.5),(490,79.5),(520,84.5),(580,86),(640,90),(700,89.5),(730,86),(760,81.5),(790,74),(820,65),(850,54),(880,39),(910,17.5),(919,4)]
TOP_NOSE, TOP_TAIL = 919, 190

def interp(tab, x):
    if x <= tab[0][0]: return tab[0][1]
    for (x0, y0), (x1, y1) in zip(tab, tab[1:]):
        if x <= x1: return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
    return tab[-1][1]
def halfw(px):  # metres
    t = (NOSE_PX - px) / (NOSE_PX - TAIL_PX); tx = TOP_NOSE - t * (TOP_NOSE - TOP_TAIL)
    return interp(TOPW, tx) * (NOSE_PX - TAIL_PX) * S / (TOP_NOSE - TOP_TAIL)

# fins (side px), from the sheet's silhouette minus the body
FINS = dict(
    Dorsal=dict(pts=[(813,32),(841,95),(849,135),(828,190),(940,175),(1040,170),(1031,153),(917,66),(843,37)], tips=[((813,32),100)], t=0.06),
    Tail=dict(pts=[(70,109),(118,158),(150,202),(174,244),(190,295),(174,365),(133,446),(112,473),(111,479),(163,462),(217,431),(255,393),(281,359),(330,320),(330,270),(320,253),(255,180),(194,141),(138,119)], tips=[((70,109),105),((111,479),105)], t=0.06),
    Dorsal2=dict(pts=[(547,178),(557,232),(625,226),(615,208),(585,189)], tips=[((547,178),45)], t=0.035),
    Anal=dict(pts=[(410,382),(455,365),(462,350),(416,345)], tips=[((410,382),30)], t=0.03),
)
PAIRED = dict(  # bent outward-down: (outline, tips, tip spread in m, root depth py, tip depth py)
    Pectoral=dict(pts=[(782,539),(854,521),(911,495),(938,478),(984,437),(1035,340),(960,350),(900,400),(852,435)], tips=[((782,539),125)], spread=0.72, root=(1000,370), t=0.05),
    Pelvic=dict(pts=[(543,444),(595,428),(631,411),(640,395),(575,385)], tips=[((543,444),48)], spread=0.22, root=(600,395), t=0.03),
)
EYE = [(1312,254),(1330,234),(1368,247),(1358,271),(1324,272)]
BROW = [(1276,222),(1384,252),(1376,266),(1336,250),(1292,242)]
GILLS = [[(1062,240),(1072,240),(1062,342),(1053,342)], [(1100,234),(1110,236),(1095,358),(1086,356)],
         [(1135,229),(1143,231),(1128,363),(1120,361)], [(1172,228),(1182,230),(1163,363),(1154,361)]]

# ---------- HEAD from the close-up sheet (head-sheet px -> full-sheet px) ----------
HKX, HKY = 410 / 770, 268 / 527                       # head sheet: cut x=60 -> full 1040, nose x=830 -> full 1450
def H(hx, hy): return (1450 - (830 - hx) * HKX, 163 + (hy - 318) * HKY)
def HL(pts): return [H(x, y) for x, y in pts]
_HTOP = [(60,315),(120,328),(180,342),(240,354),(300,363),(360,371),(420,384),(480,398),(540,412),(600,428),(660,444),(720,461),(780,479),(810,487),(828,500),(834,518)]
_HBOT = [(60,848),(120,856),(180,855),(240,854),(300,853),(360,851),(420,847),(480,843),(540,839),(600,835),(630,826),(660,810),(680,798)]
_HSNOUT = [(740,630),(760,624),(780,605),(810,567),(828,540),(834,518)]   # upper jaw underside in front of the mouth
UP = [p for p in UP if p[0] < 1040] + HL(_HTOP)
LO = [p for p in LO if p[0] < 1040] + HL(_HBOT)
NOSE_TIP = H(836, 515)
CORNER = H(455, 595)[0]
PALATE = HL([(455,595),(520,603),(600,612),(680,621),(740,630)]) + HL(_HSNOUT[1:])
JAWTOP = HL([(455,595),(485,697),(560,735),(620,765),(680,792)])
JAWBOT = HL([(455,846),(540,839),(600,835),(630,826),(660,810),(680,798)])
JAWTIP = H(684, 790)
VLO = HL([(455,846),(540,839),(600,835),(660,810),(700,700),(740,640)]) + HL(_HSNOUT[1:])
EYE_TURN, EYE_SEAT, EYE_DOME, EYE_W, EYE_H = 40.0, 0.04, 0.02, 1.488, 1.587
EYE_IN = HL([(586, 492), (618, 499), (660, 514), (650, 527), (628, 536), (606, 535), (590, 514)])   # measured cyan
MOUTH = HL([(455,595),(600,612),(740,630),(720,690),(690,760),(680,792),(620,765),(485,697)])
WHITE = [(285,0),(960,330)] + HL([(60,757),(120,738),(180,719),(360,644),(390,600),(420,577),(450,562),(480,551),(600,556),(720,559),(810,556),(836,560)])
TEETH_UP = [(HL([(b0,y0),(b1,y1)]), H(tx,ty)) for (b0,y0,b1,y1,tx,ty) in
            [(462,597,522,603,492,642),(522,603,585,610,552,670),(585,610,648,618,615,680),(648,618,690,623,667,690),(688,623,715,627,700,692),(714,627,742,630,730,680)]]
TEETH_LO = [(HL([(b0,y0),(b1,y1)]), H(tx,ty)) for (b0,y0,b1,y1,tx,ty) in
            [(495,702,555,732,525,675),(552,731,600,755,575,695),(600,755,650,778,630,712),(645,775,676,790,665,720),(668,786,684,792,682,722)]]
EYE = HL([(587,487),(625,498),(657,515),(645,530),(620,537),(598,530),(589,512)])
SOCKET = HL([(495,450),(560,472),(640,500),(702,527),(612,544),(585,524),(530,478)])
BROW = HL([(470,428),(600,466),(722,505),(708,522),(598,484),(482,450)])
GILLS = [HL(g) for g in [
    [(358,464),(319,503),(309,538),(304,583),(302,649),(307,677),(338,737),(324,649),(325,601),(333,536)],
    [(285,465),(247,505),(239,540),(236,579),(236,653),(252,694),(281,737),(259,649),(259,592),(265,533)],
    [(213,474),(177,512),(169,544),(168,599),(172,648),(207,709),(224,731),(197,652),(193,603),(195,544)],
    [(143,487),(108,519),(99,550),(100,599),(106,645),(141,697),(127,643),(123,557),(131,518)]]]

# ---------- helpers ----------
def clear():
    sc = bpy.data.scenes.get("MEGA BITE") or bpy.data.scenes.new("MEGA BITE")
    if bpy.context.window is not None: bpy.context.window.scene = sc
    for o in list(sc.objects): bpy.data.objects.remove(o, do_unlink=True)
    return sc

def mat(name, hexc, emit=0.0):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]; col = lin(hexc)
    b.inputs["Base Color"].default_value = col; b.inputs["Roughness"].default_value = 0.8
    if "Specular IOR Level" in b.inputs: b.inputs["Specular IOR Level"].default_value = 0.12
    b.inputs["Emission Strength"].default_value = emit
    if emit: b.inputs["Emission Color"].default_value = col
    return m

HALF = [(0.0, 1.0), (0.425, 0.93), (0.85, 0.6), (1.0, 0.05), (0.84, -0.475), (0.6, -0.85), (0.0, -1.0)]
RING = HALF + [(-u, v) for u, v in reversed(HALF[1:-1])]    # 12 points, top -> right side -> bottom -> left side

# the head sheet's FRONT view is a round, blunt face (as wide as tall right up to the snout), so the top view's
# pointed nose is widened in front of the mouth corner (owner 18:49: 'looks different from the front')
TOPN = [(1080,1.0),(1250,1.0255),(1300,0.9745),(1340,0.864),(1380,0.745),(1420,0.643),(1450,1.0)]
BLUNT = [(1080,1.0),(1250,1.0825),(1300,1.165),(1340,1.3025),(1380,1.5225),(1410,1.7563),(1435,2.0312),(1450,1.0)]
LIP_ARCH_UP, LIP_ARCH_LO = 0.08, 0.09   # front view: the mouth is a crescent - upper lip edge drops and lower lip edge rises toward the sides
def arch(px, y, upper):
    hwf = max(halfw(px) * interp(BLUNT, px), 1e-6); t = min(abs(y) / hwf, 1.0)
    return -LIP_ARCH_UP * t * t if upper else LIP_ARCH_LO * t * t
def ring(px, up_py, lo_py, wmul=1.0, zmin=None, zmax=None):
    zt, zb = Z(up_py), Z(lo_py); zc, hh = (zt + zb) / 2, (zt - zb) / 2; x = X(px)
    hw_lo = halfw(px) * wmul * interp(BLUNT, px)      # grin level: wide, blunt face (front view)
    hw_hi = halfw(px) * wmul * interp(TOPN, px)       # eye level and above: the snout narrows in front of the eyes, so
    out = []                                          # from the front the eyes sit INSIDE the face, like the sheet
    for u, v in RING:
        k = min(max((v - 0.05) / 0.5, 0.0), 1.0); hw = hw_lo + (hw_hi - hw_lo) * k
        z = zc + v * hh; cl = False
        if zmin is not None and z < zmin + arch(px, u * hw, True): z = zmin + arch(px, u * hw, True); cl = True
        if zmax is not None and z > zmax + arch(px, u * hw, False): z = zmax + arch(px, u * hw, False); cl = True
        out.append(((x, u * hw, z), cl))
    return out

def line_v(px):   # countershade line (-1 belly .. +1 back). In the body band (ring v 0.05..-0.45) a constant -0.2 makes
    # every quad split white/blue along its alternating diagonal = one continuous jagged zig-zag line, like the sheet.
    return interp([(285,-0.2),(1000,-0.2),(1090,-0.5),(1180,-0.5),(1230,0.0),(1265,0.3),(1450,0.3)], px)

class Builder:
    def __init__(s):
        s.bm = bmesh.new(); s.mats = {}
    def m(s, key): return s.mats[key]
    def face(s, vs, key):
        f = s.bm.faces.new(vs); f.material_index = s.m(key); return f

def loft(B, rings, colour_fn):
    """rings: list of (px, [((x,y,z),clamped), ...]) -> triangles with alternating diagonals (gives the zig-zag)."""
    vr = [[B.bm.verts.new(p) for p, _ in r] for _, r in rings]
    n = len(RING)
    for i in range(len(rings) - 1):
        for j in range(n):
            a, b = vr[i][j], vr[i][(j + 1) % n]; c, d = vr[i + 1][(j + 1) % n], vr[i + 1][j]
            cl = [rings[i][1][j][1], rings[i][1][(j + 1) % n][1], rings[i + 1][1][(j + 1) % n][1], rings[i + 1][1][j][1]]
            tris = [(a, b, c), (a, c, d)] if (i + j) % 2 == 0 else [(a, b, d), (b, c, d)]
            for t in tris:
                if len({id(v) for v in t}) < 3 or len({tuple(round(k, 5) for k in v.co) for v in t}) < 3: continue
                try: f = B.bm.faces.new(t)
                except ValueError: continue
                f.material_index = B.m(colour_fn(f, all(cl)))
    return vr

def colour_body(f, mouth):
    if mouth: return "mouth"
    c = f.calc_center_median(); px = NOSE_PX + (c.x - 2.15) / S
    if px >= 960: return "belly" if c.z < Z(interp(WHITE, px)) else "top"
    up, lo = Z(interp(UP, px)), Z(interp(LO, px))
    v = (c.z - (up + lo) / 2) / max((up - lo) / 2, 1e-4)
    return "belly" if v < -0.2 else "top"


# ---------- face carving ----------
F_LINE = HL([(430, 402), (600, 440), (830, 500)])          # upper fold of the brow plane (side, head sheet px)
C_LINE = HL([(494, 450), (600, 490), (701, 529)])          # brow crease = top of the socket
L_LINE = HL([(494, 450), (541, 489), (586, 527), (616, 544), (661, 537), (701, 531)])   # socket bottom edge
BROW_OUT, SOCK_IN = 0.045, 0.075                           # metres

# ---------- split the difference between the sheet's side and front (owner 9 Nov 20:1x) ----------
# The sheet's FRONT drawing puts the eyes ~31 px and the upper lip ~58 px (head-sheet px) higher than its SIDE drawing,
# the lower jaw ~26 px higher. One 3D head cannot match both, so the face moves HALF way up: both views within ~3%.
FACE_DY = dict(eye=-5, lip=-38.0, white=-32, jaw=-35.5)       # head-sheet px (negative = up)
def _clamp01(t): return min(max(t, 0.0), 1.0)
def _trap(px, a, b, c, d):   # 0 before a, ramps to 1 at b, holds to c, back to 0 at d
    if px <= a or px >= d: return 0.0
    if px < b: return (px - a) / (b - a)
    if px <= c: return 1.0
    return (d - px) / (d - c)
_XC, _XL, _XS, _XN = H(455, 0)[0], H(740, 0)[0], H(770, 0)[0], NOSE_TIP[0]
def _shift(pts, dy, f): return [(x, y + dy * HKY * f(x)) for x, y in pts]
PALATE = _shift(PALATE, FACE_DY['lip'], lambda x: _trap(x, _XC, _XL, _XS, _XN + 1e-6))
VLO = _shift(VLO, FACE_DY['lip'], lambda x: _trap(x, _XL - 1e-3, _XL, _XS, _XN + 1e-6))
JAWTOP = _shift(JAWTOP, FACE_DY['jaw'], lambda x: _clamp01((x - _XC) / (H(680, 0)[0] - _XC)))
JAWTIP = (JAWTIP[0], JAWTIP[1] + FACE_DY['jaw'] * HKY)
WHITE = WHITE[:2] + _shift(WHITE[2:], FACE_DY['white'], lambda x: _clamp01((x - H(420, 0)[0]) / (_XL - H(420, 0)[0])))
EYE_IN = _shift(EYE_IN, FACE_DY['eye'], lambda x: 1.0)
F_LINE = _shift(F_LINE, FACE_DY['eye'], lambda x: 1.0)
C_LINE = _shift(C_LINE, FACE_DY['eye'], lambda x: 1.0)
L_LINE = _shift(L_LINE, FACE_DY['eye'], lambda x: 1.0)

def _side_px(v): return NOSE_PX + (v.x - 2.15) / S, 300 - v.z / S
def _radial(v):
    px = NOSE_PX + (v.x - 2.15) / S; zc = (Z(interp(UP, px)) + Z(interp(LO, px))) / 2
    d = Vector((0, v.y, (v.z - zc) * 0.6)); return d.normalized() if d.length > 1e-6 else Vector((0, 1, 0))
def _line_y(line, px):   # sheet-y of a polyline at px (None outside its x range)
    if px < line[0][0] or px > line[-1][0]: return None
    return interp(line, px)

def carve_face(B):
    bm = B.bm
    def cut(line, dy=0.0):
        for (ax, ay), (bx, by) in zip(line, line[1:]):
            ay += dy; by += dy
            x0, x1 = X(ax), X(bx); z0, z1 = Z(ay), Z(by)
            d = Vector((x1 - x0, 0, z1 - z0)).normalized(); n = Vector((-d.z, 0, d.x))
            fs = [f for f in bm.faces if f.material_index != B.m("mouth") and x0 - 0.03 <= f.calc_center_median().x <= x1 + 0.03
                  and abs(f.calc_center_median().y) > 0.05 and f.calc_center_median().z > Z(interp(PALATE, NOSE_PX + (f.calc_center_median().x - 2.15) / S))]
            if not fs: continue
            vs = list({v for f in fs for v in f.verts}); es = list({e for f in fs for e in f.edges})
            bmesh.ops.bisect_plane(bm, geom=vs + es + fs, plane_co=Vector((x0, 0, z0)), plane_no=n)
    # finer facets around the eye so the groove and the brow read cleanly
    reg = [f for f in bm.faces if X(F_LINE[0][0]) - 0.05 < f.calc_center_median().x < X(F_LINE[-1][0]) + 0.02
           and abs(f.calc_center_median().y) > 0.08 and f.material_index != B.m("mouth")
           and Z(L_LINE[2][1]) - 0.06 < f.calc_center_median().z < Z(F_LINE[0][1]) + 0.08]
    bmesh.ops.subdivide_edges(bm, edges=list({e for f in reg for e in f.edges}), cuts=1, use_grid_fill=True)
    bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 4])
    cut(F_LINE); cut(C_LINE); cut(C_LINE, dy=4); cut(L_LINE)
    orig = {vv: vv.co.copy() for vv in bm.verts}
    bm.faces.ensure_lookup_table()
    # colour first, on the un-carved positions (carving moves z, which would shift the side-view classification)
    for f in bm.faces:
        if f.material_index == B.m("mouth"): continue
        c = sum((orig[v] for v in f.verts), Vector()) / len(f.verts)
        if abs(c.y) < 0.05: continue
        px, py = _side_px(c)
        yc, yl, yf = _line_y(C_LINE, px), _line_y(L_LINE, px), _line_y(F_LINE, px)
        if yc is not None and yl is not None and yc < py < yl: f.material_index = B.m("tip")    # black socket
        elif yf is not None and yc is not None and py < yc and f.material_index == B.m("belly"): f.material_index = B.m("top")
    x_back, x_front = C_LINE[0][0], C_LINE[-1][0]
    for vv in bm.verts:
        v = orig[vv]
        if abs(v.y) < 0.05: continue
        px, py = _side_px(v)
        yf, yc, yl = _line_y(F_LINE, px), _line_y(C_LINE, px), _line_y(L_LINE, px)
        if yf is None: continue
        r = _radial(v)
        if yc is not None and yf - 0.5 <= py <= yc + 0.5:          # brow chamfer: 0 at the fold, BROW_OUT at the crease
            t = (py - yf) / max(yc - yf, 1e-6); vv.co = v + r * BROW_OUT * min(max(t, 0), 1) ** 1.2
        elif yc is not None and yl is not None and yc + 0.5 < py <= yl + 0.5:   # groove: deepest under the crease and at
            t = (py - yc) / max(yl - yc, 1e-6)                                   # the back, so its floor faces forward
            back = 1.0 - 0.55 * min(max((px - x_back) / (x_front - x_back), 0), 1)
            vv.co = v - r * SOCK_IN * back * (1 - min(max(t, 0), 1)) ** 0.8

def plate(B, pts3, normal, thick, cols, inner=0.55):
    """A faceted fin: outline at the edge, a smaller raised inner outline on both faces (thick root, thin edge)."""
    c = sum(pts3, Vector()) / len(pts3); n = normal.normalized()
    edge = [B.bm.verts.new(p) for p in pts3]
    for sgn in (1, -1):
        inn = [B.bm.verts.new(c + (p - c) * inner + n * thick * sgn) for p in pts3]
        k = len(pts3)
        for i in range(k):
            q = [edge[i], edge[(i + 1) % k], inn[(i + 1) % k], inn[i]]
            if sgn < 0: q = q[::-1]
            f = B.bm.faces.new(q); f.material_index = B.m(cols(f))
        cap = inn if sgn > 0 else inn[::-1]
        f = B.bm.faces.new(cap); f.material_index = B.m(cols(f))

def tipper(tips, to2d):
    def cols(f):
        p = to2d(f.calc_center_median())
        for (tx, ty), r in tips:
            if (p[0] - tx) ** 2 + (p[1] - ty) ** 2 < r * r: return "tip"
        return "top"
    return cols

def side2d(v): return (NOSE_PX + (v.x - 2.15) / S, 300 - v.z / S)

def embed(pts, depth=16):
    """Push fin points that sit on the body outline into the body so roots never float."""
    out = []
    for px, py in pts:
        up, lo = interp(UP, px), interp(LO, px)
        if abs(py - up) < 14 and TAIL_PX + 20 < px: py += depth
        elif abs(py - lo) < 14 and TAIL_PX + 20 < px < CORNER: py -= depth
        out.append((px, py))
    return out

def build():
    sc = clear()
    me = bpy.data.meshes.new("ReefShark"); ob = bpy.data.objects.new("ReefShark", me); sc.collection.objects.link(ob)
    B = Builder()
    for i, (k, hx) in enumerate(PAL.items()):
        me.materials.append(mat("MB_" + k, hx, emit=4.0 if k == "eye" else (0.35 if k == "mouth" else 0.0))); B.mats[k] = i
    # 1) body: tail joint -> mouth corner
    stations = [285, 300, 340, 400, 460, 520, 580, 640, 700, 760, 820, 880, 940, 1000, 1060, 1110, 1160, 1200, CORNER]
    body = [(px, ring(px, interp(UP, px), interp(LO, px))) for px in stations]
    vr = loft(B, body, colour_body)
    f = B.bm.faces.new(vr[0][::-1]); f.material_index = B.m("top")        # tail joint cap (hidden by the tail)
    # cap at the mouth corner: the gape has zero height there, so the cap is never seen from inside the mouth; a maroon cap
    # showed as a red OUTLINE around the narrower jaw from outside (owner 18:35). Fan it and colour it like the skin.
    cc = sum((v.co for v in vr[-1]), Vector()) / len(vr[-1]); cv = B.bm.verts.new(cc)
    for k in range(len(vr[-1])):
        a_, b_ = vr[-1][k], vr[-1][(k + 1) % len(vr[-1])]
        if (a_.co - b_.co).length < 1e-6: continue
        try: f = B.bm.faces.new((a_, b_, cv)); f.material_index = B.m(colour_body(f, False))
        except ValueError: pass
    # 2) upper jaw: body section clamped from below by the palate
    head = [(px, ring(px, interp(UP, px), interp(VLO, px), zmin=Z(interp(PALATE, px)))) for px in [CORNER, CORNER + 20, 1300, 1330, 1360, 1385, 1405, 1425, 1440, 1447]]
    n_head0 = len(B.bm.faces)
    vh = loft(B, head, colour_body)
    tip = B.bm.verts.new((X(NOSE_TIP[0]), 0, Z(NOSE_TIP[1])))
    for j in range(len(RING)):
        a, b = vh[-1][j], vh[-1][(j + 1) % len(RING)]
        if a.co == b.co: continue
        try: f = B.bm.faces.new((a, b, tip)); f.material_index = B.m("mouth" if head[-1][1][j][1] and head[-1][1][(j + 1) % len(RING)][1] else colour_body(f, False))
        except ValueError: pass
    # 3) lower jaw: clamped from above by the jaw line, a bit narrower towards its tip
    jaw = []
    for px in [CORNER, CORNER + 8, CORNER + 30, 1300, 1325, 1345, JAWTIP[0] - 2]:
        w = 0.97 - 0.3 * (px - CORNER) / (JAWTIP[0] - CORNER)   # the lower jaw sits just INSIDE the upper jaw (front view)
        # chin keeps a real thickness (owner 19:45: the jaw front was a razor-thin white plate). Bottom never closer than
        # 45 sheet px (~0.075 m) under the jaw top, and the last ring is pulled in so the chin is a rounded block
        lo = max(interp(JAWBOT, px), interp(JAWTOP, px) + 23)   # full-sheet px (= 45 head px)
        if px >= JAWTIP[0] - 2: w *= 0.8
        jaw.append((px, ring(px, interp(UP, px), lo, wmul=w, zmax=Z(interp(JAWTOP, px)))))
    n_jaw0 = len(B.bm.faces)
    vj = loft(B, jaw, lambda f, m: "mouth" if m else "belly")
    jt = B.bm.verts.new((X(JAWTIP[0]) + 0.015, 0, Z(JAWTIP[1] + 11)))   # centre of the blunt chin face
    for j in range(len(RING)):
        a, b = vj[-1][j], vj[-1][(j + 1) % len(RING)]
        if a.co == b.co: continue
        try: f = B.bm.faces.new((a, b, jt)); f.material_index = B.m("belly")
        except ValueError: pass
    # clean, straight blue/white boundary on the head: cut the faces exactly along the white line, then recolour
    segs = [p for p in WHITE if p[0] >= 960]
    for (ax, ay), (bx, by) in zip(segs, segs[1:]):
        x0, x1 = X(ax), X(bx); z0, z1 = Z(ay), Z(by)
        d = Vector((x1 - x0, 0, z1 - z0)).normalized(); n = Vector((-d.z, 0, d.x))
        fs = [f for f in B.bm.faces if f.material_index != B.m("mouth") and x0 - 0.01 <= f.calc_center_median().x <= x1 + 0.01]
        if not fs: continue
        vs = list({v for f in fs for v in f.verts}); es = list({e for f in fs for e in f.edges})
        bmesh.ops.bisect_plane(B.bm, geom=vs + es + fs, plane_co=Vector((x0, 0, z0)), plane_no=n)
    for f in B.bm.faces:
        if f.material_index in (B.m("top"), B.m("belly")) and f.calc_center_median().x >= X(960):
            f.material_index = B.m(colour_body(f, False))
    # ---- FACE CARVING (owner 19:08: brow must be blended INTO the forehead, the eye sits in a groove) ----
    # Traced from the head sheet's side close-up: the brow is a chamfer plane of the head itself between the fold line
    # F and the crease C; under C a deep black groove (socket) runs forward and the eye lies on the groove floor.
    carve_face(B)
    head_faces = len(B.bm.faces)
    # 4) teeth along the jaw edges (upper point down, lower point up), sizes varied like the sheet
    def edge_path(rset, zf, inset):
        right = [(Vector((X(px), max(abs(p[0][1]) for p in r if abs(p[0][2] - zf(px)) < 1e-6 or True) * 0 + halfw_at(r, zf(px)) - inset, zf(px)))) for px, r in rset[1:]]
        return right
    def halfw_at(r, z):
        best = 0.0
        pts = [p for p, _ in r]
        for i in range(len(pts)):
            a, b = Vector(pts[i]), Vector(pts[(i + 1) % len(pts)])
            if (a.z - z) * (b.z - z) <= 0 and a.z != b.z:
                y = a.y + (b.y - a.y) * (z - a.z) / (b.z - a.z); best = max(best, abs(y))
        return best
    def teeth(rset, zf, down, sizes, inset=0.035):
        path = []
        for px, r in rset[1:]:
            cl = [abs(q[1]) for q, c in r if c]
            path.append(Vector((X(px), (max(cl) if cl else halfw_at(r, zf(px))) - inset, zf(px))))
        # front arc across the snout
        last = path[-1]; arc = [Vector((last.x + 0.05 * math.sin(a), last.y * math.cos(a), last.z)) for a in (0.6, 1.2)]
        path = path + arc
        L = [0.0]
        for a, b in zip(path, path[1:]): L.append(L[-1] + (b - a).length)
        n = len(sizes)
        for k, sz in enumerate(sizes):
            d = L[-1] * (0.12 + 0.88 * (k + 0.5) / n)
            for i in range(len(L) - 1):
                if L[i + 1] >= d: break
            f_ = (d - L[i]) / max(L[i + 1] - L[i], 1e-6); p = path[i].lerp(path[i + 1], f_); tng = (path[i + 1] - path[i]).normalized()
            for sy in (1, -1):
                base = Vector((p.x, p.y * sy, p.z)); tg = Vector((tng.x, tng.y * sy, 0)).normalized()
                w = sz * 0.55; h = sz * (-1 if down else 1); th = 0.022
                outn = Vector((0, sy, 0))
                a1, a2 = base - tg * w, base + tg * w; pt = base + Vector((0, 0, h)) - outn * 0.01
                vs = [B.bm.verts.new(q) for q in (a1 + outn * th, a2 + outn * th, pt + outn * th * 0.3, a1 - outn * th, a2 - outn * th, pt - outn * th * 0.3)]
                for tri in ((0, 1, 2), (5, 4, 3), (0, 3, 4, 1), (1, 4, 5, 2), (2, 5, 3, 0)):
                    try: ff = B.bm.faces.new([vs[t] for t in tri]); ff.material_index = B.m("tooth")
                    except ValueError: pass
    # 4) teeth: ONE neat row per jaw along a U-shaped jaw edge (seen from above), every blade facing outward,
    #    touching at the base like the sheet's zig-zag. Front teeth face the front view, side teeth face the side view.
    def lip_w(rows, px):
        """true lip-edge half-width at px: the widest clamped (lip) vertex, interpolated between the two nearest rings"""
        ws = []
        for r_px, r in rows:
            cl = [abs(q[1]) for q, c in r if c]
            if cl: ws.append((r_px, max(cl)))
        ws.sort()
        return interp(ws, px) if ws else halfw(px) * 0.8
    def lip_path(rows, zline, x_back, x_front, inset, n_side=40, n_arc=24):
        """U-shaped path that always stays INSIDE the lips: follows the lip edge minus inset, rounds off at the front"""
        pxf = NOSE_PX + (x_front - 2.15) / S
        yf = max(lip_w(rows, pxf) - inset, 0.05); rx = min(0.12, yf * 0.8); xc = x_front - rx
        right = []
        for k in range(n_side + 1):
            x = x_back + (xc - x_back) * k / n_side; px = NOSE_PX + (x - 2.15) / S
            y = max(lip_w(rows, px) - inset, 0.03)
            right.append(Vector((x, y, Z(interp(zline, px)) + arch(px, y, zline is PALATE))))
        yl = right[-1].y
        arc = []
        for k in range(1, n_arc):
            th = math.pi / 2 - math.pi * k / n_arc
            x = xc + rx * math.cos(th); y = yl * math.sin(th); px = NOSE_PX + (x - 2.15) / S
            arc.append(Vector((x, y, Z(interp(zline, px)) + arch(px, y, zline is PALATE))))
        left = [Vector((v.x, -v.y, v.z)) for v in reversed(right)]
        return right + arc + left
    def tooth_row(rows, zline, x_back, x_front, n, h_back, h_front, down, inset=0.06):
        pts = lip_path(rows, zline, x_back, x_front, inset)
        L = [0.0]
        for a, b in zip(pts, pts[1:]): L.append(L[-1] + (b - a).length)
        def at(d):
            for k in range(len(L) - 1):
                if L[k + 1] >= d:
                    f = (d - L[k]) / max(L[k + 1] - L[k], 1e-9); return pts[k].lerp(pts[k + 1], f), (pts[k + 1] - pts[k]).normalized()
            return pts[-1], (pts[-1] - pts[-2]).normalized()
        start, end = L[-1] * 0.03, L[-1] * 0.97; step = (end - start) / n
        for k in range(n):
            c, tg = at(start + step * (k + 0.5)); a0, _ = at(start + step * (k + 0.04)); a1, _ = at(start + step * (k + 0.96))
            out = Vector((tg.y, -tg.x, 0)).normalized()
            if out.dot(Vector((0, c.y, 0)) + Vector((c.x - x_back, 0, 0)) * 0.0) < 0 and abs(c.y) > 0.02: out = -out
            if abs(c.y) <= 0.02: out = Vector((1, 0, 0))
            mid = 1 - abs((k + 0.5) / n - 0.5) * 2
            h = (h_back + (h_front - h_back) * mid) * (-1 if down else 1)
            sink = Vector((0, 0, 0.025 if down else -0.006))   # lower bases barely sink: the jaw wall curves in right under the lip      # bases sink into the gum, never float on the lip
            tip = c + Vector((0, 0, h)) - out * 0.02; th = 0.018
            b0, b1 = a0 + sink, a1 + sink
            vs = [B.bm.verts.new(q) for q in (b0 + out * th, b1 + out * th, tip + out * th * 0.2, b0 - out * th, b1 - out * th, tip - out * th * 0.2)]
            for tri in ((0, 1, 2), (5, 4, 3), (0, 3, 4, 1), (1, 4, 5, 2), (2, 5, 3, 0)):
                try: ff = B.bm.faces.new([vs[t] for t in tri]); ff.material_index = B.m("tooth")
                except ValueError: pass
    n_teeth0 = len(B.bm.faces)
    # sizes measured on the head sheet: tooth height 45-65 sheet px = 0.07-0.11 m
    tooth_row(head, PALATE, X(H(468, 598)[0]), X(H(728, 628)[0]), 10, 0.1265, 0.1495, True, inset=0.035)   # stop before the snout rises
    tooth_row(jaw, JAWTOP, X(H(500, 705)[0]), X(H(668, 786)[0]), 8, 0.0902, 0.1045, False, inset=0.075)  # well inside the lip so no base shows under the jaw  # stop before the jaw tip
    n_teeth1 = len(B.bm.faces)
    # mouth cavity: cheek walls that join the INSIDE of the upper lip to the inside of the lower lip on each side,
    # so nothing red can poke out of the lips; the upper verts stay with the head, the lower ones follow the Jaw bone
    x0 = X(CORNER) + 0.01; x1 = min(X(JAWTIP[0]), X(H(740, 630)[0])) - 0.03
    for sy in (1, -1):
        up, lo = [], []
        for k in range(13):
            x = x0 + (x1 - x0) * k / 12; px = NOSE_PX + (x - 2.15) / S
            wu = lip_w(head, px) - 0.11; wl = lip_w(jaw, px) - 0.11
            zu = Z(interp(PALATE, px)) + arch(px, wu, True); zl = Z(interp(JAWTOP, px)) + arch(px, wl, False)   # walls sit BEHIND the teeth (teeth inset 0.06)
            up.append(B.bm.verts.new((x, sy * wu, zu))); lo.append(B.bm.verts.new((x, sy * wl, zl)))
        for k in range(12):
            q = (up[k], lo[k], lo[k + 1], up[k + 1]) if sy > 0 else (up[k], up[k + 1], lo[k + 1], lo[k])   # normals face INTO the mouth
            f = B.bm.faces.new(q); f.normal_update()
            # back-to-back twin so the cheek reads maroon from inside AND outside (Roblox renders one side only)
            up2 = [B.bm.verts.new(v.co + Vector((0, sy * 0.006, 0))) for v in (q[3], q[2], q[1], q[0])]   # twin just outside, facing out
            f2 = B.bm.faces.new(up2); f2.normal_update()
            for ff in (f, f2):   # the face that looks INTO the mouth is maroon, the one facing out is white cheek skin
                ff.material_index = B.m("mouth")   # both faces maroon: seen through the gape they are mouth interior (a white face read as a slab)
    # lip rims + clean mouth colours: the outer 0.045 of the palate and the jaw top is WHITE lip (teeth stand on it),
    # everything inside the mouth opening (side view, between the jaw line and the palate) is maroon - no white squares
    B.bm.faces.ensure_lookup_table()
    xa, xb = X(CORNER), X(H(745, 630)[0])
    for f in B.bm.faces[:n_teeth0]:
        c = f.calc_center_median()
        if not (xa - 0.01 <= c.x <= xb + 0.02): continue
        px = NOSE_PX + (c.x - 2.15) / S; zp = Z(interp(PALATE, px)) + arch(px, c.y, True); zj = Z(interp(JAWTOP, px)) + arch(px, c.y, False)
        if f.material_index == B.m("mouth"):
            if c.z > (zp + zj) / 2:   # roof (palate) side: white gum rim + the overhang outside the jaw
                if abs(c.y) > min(lip_w(head, px) - 0.045, max(lip_w(jaw, px), lip_w(head, px) - 0.105)): f.material_index = B.m("belly")
            elif abs(c.y) > lip_w(jaw, px) - 0.10:   # floor (jaw top) side, incl. the steep slope at the mouth corner
                f.material_index = B.m("belly")
        elif zj + 0.015 < c.z < zp - 0.015 and abs(c.y) < max(lip_w(head, px), lip_w(jaw, px)) - 0.02:
            f.material_index = B.m("mouth")
    n_fins0 = len(B.bm.faces)
    # 5) fins
    for name, F in FINS.items():
        pts = embed(F["pts"]); p3 = [Vector((X(px), 0, Z(py))) for px, py in pts]
        plate(B, p3, Vector((0, 1, 0)), F["t"], tipper(F["tips"], side2d))
    for name, F in PAIRED.items():
        rz = F["root"][1]; tz = max(py for _, py in F["pts"])
        for sy in (1, -1):
            p3 = []
            for px, py in F["pts"]:
                k = min(max((py - rz) / (tz - rz), 0.0), 1.0)
                y = halfw(px) * 0.78 + (F["spread"]) * k
                p3.append(Vector((X(px), y * sy, Z(py) + 0.12 * k * 0)))
            # plane normal
            n = (p3[1] - p3[0]).cross(p3[2] - p3[0])
            if n.length < 1e-6: n = Vector((0, 0, 1))
            plate(B, p3 if sy > 0 else p3[::-1], n, F["t"], tipper(F["tips"], side2d))
    B.bm.faces.ensure_lookup_table()
    bmesh.ops.recalc_face_normals(B.bm, faces=B.bm.faces[:head_faces])
    # open shells (head, jaw) can come out inside-out after recalc: flip any island whose faces point inward
    def fix_islands(faces):
        todo = set(faces); 
        while todo:
            f0 = todo.pop(); comp = [f0]; stack = [f0]
            while stack:
                g = stack.pop()
                for e in g.edges:
                    for h in e.link_faces:
                        if h in todo: todo.discard(h); comp.append(h); stack.append(h)
            c = sum((f.calc_center_median() for f in comp), Vector()) / len(comp)
            if sum(1 for f in comp if f.normal.dot(f.calc_center_median() - c) > 0) < len(comp) / 2:
                for f in comp: f.normal_flip()
    fix_islands(list(B.bm.faces[:head_faces]))
    # per-face guarantee on the lower jaw shell only (its open ends confuse recalc)
    for f in B.bm.faces[:head_faces]:
        c = f.calc_center_median(); px = NOSE_PX + (c.x - 2.15) / S
        if c.x < X(CORNER) + 0.005 or any(v.co.z > Z(interp(JAWTOP, NOSE_PX + (v.co.x - 2.15) / S)) + arch(NOSE_PX + (v.co.x - 2.15) / S, v.co.y, False) + 0.003 for v in f.verts): continue
        zc = (Z(interp(JAWTOP, px)) + Z(interp(JAWBOT, px))) / 2
        f.normal_update()
        inner = Vector((max(X(CORNER) + 0.02, c.x - 0.15), 0, zc))   # a point inside the jaw, a bit behind the face
        if f.normal.dot(c - inner) < 0: f.normal_flip()
    # closed islands (teeth prisms, fin plates): outward normals, so Roblox can render them single-sided
    bmesh.ops.recalc_face_normals(B.bm, faces=B.bm.faces[n_teeth0:n_teeth1])
    bmesh.ops.recalc_face_normals(B.bm, faces=B.bm.faces[n_fins0:])
    B.bm.to_mesh(me); B.bm.free()
    # 6) decals projected onto the body surface (eye, brow, gills) on both sides
    deps = bpy.context.evaluated_depsgraph_get(); bvh = BVHTree.FromObject(ob, deps)
    dm = bmesh.new(); dm.from_mesh(me)
    FACE_TURN = math.radians(55)   # face decals (eye, socket, brow) look 40 deg forward so they read from the FRONT too
    # FRONT-view mapping (head sheet front: centre x 1205, head half-width ~262 px, top y 355, bottom y 870)
    _zt = max(Z(py) for px, py in UP if px > 1000); _zb = min(Z(py) for px, py in LO if px > 1000)
    _hw = max(halfw(q) * interp(BLUNT, q) for q in range(1000, 1450, 5))
    def proj_front(fx, fy, sy):
        y = sy * abs(fx - 1205) / 262 * _hw; z = _zt - (fy - 355) / (870 - 355) * (_zt - _zb)
        hit = bvh.ray_cast(Vector((6.0, y, z)), Vector((-1, 0, 0)))
        if hit[0] is None: return None
        n = hit[1] if hit[1].x > -0.2 else Vector((1, 0, 0))
        return hit[0], n
    def proj(px, py, sy, turn=0.0, cen=None):
        if turn == 0.0 or cen is None:
            o = Vector((X(px), 3.0 * sy, Z(py))); hit = bvh.ray_cast(o, Vector((0, -sy, 0)))
        else:   # project from a plane turned towards the front, centred on the decal's side-view hit point
            d = Vector((math.sin(turn), sy * math.cos(turn), 0)); hz = Vector((math.cos(turn), -sy * math.sin(turn), 0))
            q = cen + hz * (X(px) - X(cen_px[0])) + Vector((0, 0, Z(py) - Z(cen_px[1])))
            hit = bvh.ray_cast(q + d * 3.0, -d)
        if hit[0] is None: return None
        n = hit[1] if hit[1].y * sy > 0 else Vector((0, sy, 0))
        return hit[0], n
    cen_px = [0, 0]
    def decal(poly, key, lift, th, sub=4, turn=0.0, anchor=None, front=False, wedge=None):
        """Fan of small triangles, every vertex projected onto the body, so the decal hugs the curved surface."""
        ring2 = []
        for (ax, ay), (bx, by) in zip(poly, poly[1:] + poly[:1]):
            for k in range(sub): ring2.append((ax + (bx - ax) * k / sub, ay + (by - ay) * k / sub))
        cx = sum(p[0] for p in poly) / len(poly); cy = sum(p[1] for p in poly) / len(poly)
        for sy in (1, -1):
            if front:
                hits = [proj_front(px, py, sy) for px, py in ring2]; hc = proj_front(cx, cy, sy)
            elif turn:
                h0 = proj(*anchor, sy)
                if h0 is None: continue
                cen_px[:] = list(anchor)
                hits = [proj(px, py, sy, turn, h0[0]) for px, py in ring2]; hc = proj(cx, cy, sy, turn, h0[0])
            else:
                hits = [proj(px, py, sy) for px, py in ring2]; hc = proj(cx, cy, sy)
            if hc is None or any(h is None for h in hits): continue
            if wedge:   # visor: thin at the top edge, thickest along the lower edge so it overhangs the eye
                tops, bots = wedge
                ws = []
                for px_, py_ in ring2:
                    yt, yb = interp(tops, px_), interp(bots, px_)
                    a_ = min(max((py_ - yt) / max(yb - yt, 1e-6), 0.0), 1.0)          # 0 top edge .. 1 lower edge
                    e_ = min(max((px_ - tops[0][0]) / max(tops[-1][0] - tops[0][0], 1e-6), 0.0), 1.0)
                    ws.append(a_ ** 1.5 * math.sin(math.pi * min(max(e_, 0.0), 1.0)) ** 0.6)   # 0 at both ends
                # owner 18:58: the brow must grow OUT of the forehead, not sit on it like a separate part
                top = [dm.verts.new(p + n * (lift + th * w_)) for (p, n), w_ in zip(hits, ws)]
                ctr = dm.verts.new(hc[0] + hc[1] * (lift + th * 0.35))
            else:
                top = [dm.verts.new(p + n * (lift + th)) for p, n in hits]; ctr = dm.verts.new(hc[0] + hc[1] * (lift + th * 1.4))
            bot = [dm.verts.new(p - n * 0.012) for p, n in hits]
            k = len(top)
            for i in range(k):
                tri = (top[i], top[(i + 1) % k], ctr) if sy < 0 else (top[(i + 1) % k], top[i], ctr)
                f = dm.faces.new(tri); f.material_index = B.m(key); f.normal_update()
                if f.normal.dot(hc[1]) < 0: f.normal_flip()
                q = (bot[i], bot[(i + 1) % k], top[(i + 1) % k], top[i]) if sy < 0 else (top[i], top[(i + 1) % k], bot[(i + 1) % k], bot[i])
                f = dm.faces.new(q); f.material_index = B.m(key); f.normal_update()
                if f.normal.dot(f.calc_center_median() - ctr.co) < 0: f.normal_flip()
    ea = (sum(p[0] for p in EYE) / len(EYE), sum(p[1] for p in EYE) / len(EYE))   # one shared anchor keeps the 3 layers stacked
    # BROW (owner 18:53 'its the brow too'): the sheet's front shows a heavy angry V visor - outer end high, inner end
    # low near the centre, sticking out over the eye. Traced from the sheet's FRONT view and projected from the front.
    # eye = thin glowing inlay lying on the groove floor (no slab, no turn: the carved groove already faces it forward)
    # EYE = a domed glowing lens SEATED in the groove, facing 45 deg between side and front (like the sheet, where it
    # reads from both views). Its outline is the sheet's side eye, widened by 1/cos(45) so the side view keeps its size.
    ec = (sum(p[0] for p in EYE_IN) / len(EYE_IN), sum(p[1] for p in EYE_IN) / len(EYE_IN))
    t = math.radians(EYE_TURN)
    for sy in (1, -1):
        hit = bvh.ray_cast(Vector((X(ec[0]), 3.0 * sy, Z(ec[1]))), Vector((0, -sy, 0)))
        if hit[0] is None: continue
        n = Vector((math.sin(t), sy * math.cos(t), 0)); U = Vector((math.cos(t), -sy * math.sin(t), 0)); V = Vector((0, 0, 1))
        C = hit[0] + n * EYE_SEAT
        ring_ = []
        for (ax, ay), (bx, by) in zip(EYE_IN, EYE_IN[1:] + EYE_IN[:1]):
            for k in range(3): ring_.append((ax + (bx - ax) * k / 3, ay + (by - ay) * k / 3))
        front = [dm.verts.new(C + U * ((x - ec[0]) * S / math.cos(t) * EYE_W) + V * ((ec[1] - y) * S * EYE_H)) for x, y in ring_]
        back = [dm.verts.new(v.co - n * 0.04) for v in front]
        top = dm.verts.new(C + n * EYE_DOME); bot = dm.verts.new(C - n * 0.04)
        m_ = len(front)
        for k in range(m_):
            a_, b_ = front[k], front[(k + 1) % m_]
            for q in ((a_, b_, top), (back[(k + 1) % m_], back[k], bot), (a_, back[k], back[(k + 1) % m_], b_)):
                f = dm.faces.new(q); f.material_index = B.m("eye"); f.normal_update()
                cen = f.calc_center_median()
                if f.normal.dot(cen - (C - n * 0.02)) < 0: f.normal_flip()
    for g in GILLS: decal(g, "gill", 0.0, 0.01, sub=6)
    dm.to_mesh(me); dm.free()
    for p in me.polygons: p.use_smooth = False
    me.update()
    return ob

def rig(sh, bones=8):
    sc = bpy.context.scene
    arm = bpy.data.armatures.new("ReefSharkRig"); ob = bpy.data.objects.new("ReefSharkRig", arm)
    sc.collection.objects.link(ob); bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    xs = [2.25 - i * (2.25 - X(70)) / bones for i in range(bones + 1)]
    rb = arm.edit_bones.new("Root"); rb.head = (0, 0, 0); rb.tail = (0.4, 0, 0)   # Roblox: root at the origin, no weights
    prev = rb
    for i in range(bones):
        b = arm.edit_bones.new(f"Spine{i}"); b.head = (xs[i], 0, 0); b.tail = (xs[i + 1], 0, 0)
        b.parent = prev; b.use_connect = i > 0
        prev = b
    zc = Z(H(455, 650)[1]); j = arm.edit_bones.new("Jaw"); j.head = (X(CORNER) - 0.05, 0, zc); j.tail = (X(JAWTIP[0]), 0, Z(JAWTIP[1])); j.parent = arm.edit_bones["Spine0"]
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="DESELECT"); sh.select_set(True); ob.select_set(True); bpy.context.view_layer.objects.active = ob
    bpy.ops.object.parent_set(type="ARMATURE_NAME")
    seg = (xs[0] - xs[-1]) / bones; groups = [sh.vertex_groups[f"Spine{i}"] for i in range(bones)]; jg = sh.vertex_groups["Jaw"]
    for v in sh.data.vertices:
        c = v.co
        if c.x > X(CORNER) - 0.02 and c.z < Z(interp(JAWTOP, NOSE_PX + (c.x - 2.15) / S)) + arch(NOSE_PX + (c.x - 2.15) / S, c.y, False) + 0.005 and c.z < Z(H(455, 640)[1]) and abs(c.y) < 0.6:
            jg.add([v.index], 1.0, "REPLACE"); continue
        # SMOOTH skinning: Gaussian falloff over the 3 nearest spine bones (Roblox max 4), so the body bends in a
        # curve instead of kinking at each joint
        u = (xs[0] - c.x) / seg - 0.5
        ws = sorted(((math.exp(-((u - k) / 0.75) ** 2), k) for k in range(bones)), reverse=True)[:3]
        tot = sum(w for w, _ in ws)
        for w, k in ws: groups[k].add([v.index], w / tot, "REPLACE")
    make_clips(ob, bones)
    return ob

# ---------- animation clips (30 fps = Roblox). The mesh is modelled with the mouth OPEN (the grin); Jaw +X closes it. ----------
# From the art research: every shark gets Swim + Bite + its ability clip (Reef Shark = SHARK SENSE). Added for the
# slice's gameplay: Idle (stopped), Dart (everyone's dodge) and Hurt (cartoon flinch). Turning = spine bend in code.
# SMOOTHNESS RULES (owner 9 Nov: "we need the animations to look smooth"):
#  - every clip is a continuous body CURVE y(s,t) / z(s,t) (metres, s along the body), not bone angles: the bones are
#    solved to follow the curve, so bends flow nose -> tail with no kinks or piled-up joints;
#  - the curve is re-centred every frame (weighted by body mass) so the fish never drifts or swings around its nose:
#    the head counter-sways a little like a real shark;
#  - keyed on EVERY frame; loops are exactly periodic; one-shots use eased timing (anticipation, snap, overshoot,
#    settle) and start and end on the rest pose so Roblox can blend them with Swim.
FPS = 30
CLIPS = {}
def ss(x):  # smootherstep 0..1
    x = min(max(x, 0.0), 1.0); return x * x * x * (x * (6 * x - 15) + 10)
def make_clips(ob, bones):
    sc = bpy.context.scene
    bpy.context.view_layer.objects.active = ob; bpy.ops.object.mode_set(mode="POSE")
    ob.animation_data_create()
    for pb in ob.pose.bones: pb.rotation_mode = "XYZ"
    sp = [ob.pose.bones[f"Spine{i}"] for i in range(bones)]; jaw = ob.pose.bones["Jaw"]; root = ob.pose.bones["Root"]
    xs = [b.head_local.x for b in [ob.data.bones[f"Spine{i}"] for i in range(bones)]] + [ob.data.bones[f"Spine{bones-1}"].tail_local.x]
    Ltot = xs[0] - xs[-1]; seglen = Ltot / bones
    us = [(xs[0] - x) / Ltot for x in xs]                        # 0 = nose .. 1 = tail tip, at the joints
    mass = [max(0.05, halfw(NOSE_PX + (x - 2.15) / S)) ** 2 for x in xs]  # cross-section area ~ weight (traced top view)
    def recentre(vals):
        # remove the mass-weighted mean offset and mean slope: the body's centre and heading stay put
        W = sum(mass); mu = sum(m * u for m, u in zip(mass, us)) / W; mv = sum(m * v for m, v in zip(mass, vals)) / W
        cov = sum(m * (u - mu) * (v - mv) for m, u, v in zip(mass, us, vals)); var = sum(m * (u - mu) ** 2 for m, u in zip(mass, us))
        b = cov / var if var else 0.0
        return [v - (mv + b * (u - mu)) for u, v in zip(us, vals)]
    def solve(curve):   # joint offsets -> absolute segment angles (yaw: +angle sends the tail to -Y)
        return [-math.atan2(curve[k + 1] - curve[k], seglen) for k in range(bones)]
    def rel(absl): return [absl[0]] + [absl[k] - absl[k - 1] for k in range(1, len(absl))]
    def clip(name, length, fn, loop=True, centre=True):
        act = bpy.data.actions.get(name)
        if act: bpy.data.actions.remove(act)
        act = bpy.data.actions.new(name); act.use_fake_user = True; ob.animation_data.action = act
        for fr in range(0, length + 1):
            t = (fr % length) / length if loop else fr / length
            ylat, zver, jawang, fwd = fn(t)
            if centre: ylat = recentre(ylat)
            yaw = solve(ylat); pit = [-a for a in solve(zver)]
            ry, rp = rel(yaw), rel(pit)
            for k, pb in enumerate(sp):
                pb.rotation_euler = (rp[k], 0, ry[k]); pb.keyframe_insert("rotation_euler", frame=fr)
            jaw.rotation_euler = (math.radians(jawang), 0, 0); jaw.keyframe_insert("rotation_euler", frame=fr)
            root.location = (-ylat[0], fwd, zver[0]); root.keyframe_insert("location", frame=fr)
        for fc in getattr(act, "fcurves", []):
            for kp in fc.keyframe_points: kp.interpolation = "LINEAR"   # every frame is keyed: no Bezier overshoot
        act["frame_range"] = (0, length); act["loop"] = loop; act["fps"] = FPS
        CLIPS[name] = (act, length)
    flat = [0.0] * (bones + 1)
    def env(u):  # carangiform amplitude envelope (fraction of body length): small at the head, big at the tail
        return 0.008 - 0.03 * u + 0.11 * u * u
    def wave(t, scale, cycles=1.0, wavelength=1.0):
        return [scale * Ltot * env(u) * math.sin(2 * math.pi * (cycles * t - u / wavelength)) for u in us]
    # IDLE 2 s loop: slow, small sway; the jaw breathes
    clip("Idle", 60, lambda t: (wave(t, 0.45), flat, -2.5 + 2.5 * math.sin(2 * math.pi * t), 0))
    # SWIM 1 s loop: one full tail beat, about one body-length wave
    clip("Swim", 30, lambda t: (wave(t, 0.75), flat, -1.5 + 1.2 * math.sin(2 * math.pi * t - 1.0), 0))
    # DART 0.8 s: smooth coil, two strong tail beats, fades back to straight
    def dart(t):
        a = ss(t / 0.2) * (1 - ss((t - 0.35) / 0.65)) ** 1.2
        y = [2.6 * a * Ltot * env(u) * math.sin(2 * math.pi * (2.2 * t - u * 0.9) - 0.6) for u in us]
        return y, flat, -4 * a, 0
    clip("Dart", 24, dart, loop=False)
    # BITE 0.5 s: anticipation (head up, jaw gapes) -> fast snap (head down, jaw shut, lunge) -> overshoot -> settle
    def bite(t):
        up = ss(t / 0.38)                       # 0..0.38 anticipation
        snap = ss((t - 0.38) / 0.22)            # 0.38..0.6 the snap (~4 frames: fast but readable, no pop)
        settle = ss((t - 0.6) / 0.4)            # back to rest
        bounce = math.sin(math.pi * min(max((t - 0.6) / 0.4, 0), 1) * 2) * 0.25 * (1 - settle)
        head = 0.10 * up - 0.16 * snap * (1 - settle) - 0.10 * up * snap   # metres the nose moves up(+)/down(-)
        head += 0.04 * bounce
        z = [head * max(0.0, 1 - u / 0.4) ** 2 for u in us]
        j = -16 * up * (1 - snap) + 24 * snap * (1 - settle) + 6 * bounce
        fw = 0.32 * snap * (1 - settle)
        return flat, z, j, fw
    clip("Bite", 18, bite, loop=False)
    # SHARK SENSE 1.5 s: slows to a glide, the HEAD scans left-right twice (body counter-sways), jaw eases half shut
    def sense(t):
        e = ss(t / 0.15) * (1 - ss((t - 0.8) / 0.2))
        sweep = 0.22 * e * math.sin(2 * math.pi * 2 * t)
        y = [sweep * max(0.0, 1 - u / 0.45) ** 2 for u in us]
        y = [a + b for a, b in zip(y, wave(t * 1.5, 0.3 * (1 - e) + 0.15))]
        return y, flat, 9 * e, 0
    clip("SharkSense", 45, sense, loop=False)
    # HURT 0.5 s: a jolt into a C-bend that shakes out smoothly (cartoon, no blood)
    def hurt(t):
        J = 0.30 * math.sin(2 * math.pi * 2.5 * t) * math.exp(-5 * t) * (1 - math.exp(-40 * t)) * (1 - ss((t - 0.8) / 0.2))
        y = [J * (4 * (u - 0.5) ** 2 - 1 / 3) for u in us]
        return y, flat, -10 * math.exp(-5 * t) * (1 - ss((t - 0.8) / 0.2)), 0
    clip("Hurt", 15, hurt, loop=False)
    ob.animation_data.action = CLIPS["Swim"][0]
    bpy.ops.object.mode_set(mode="OBJECT")
    sc.render.fps = FPS; sc.frame_start, sc.frame_end = 0, 29; sc.frame_set(0)   # 30 = 0 again: preview loops without a repeated frame

def stage():
    sc = bpy.context.scene
    w = bpy.data.worlds.get("MB_World") or bpy.data.worlds.new("MB_World"); w.use_nodes = True; sc.world = w
    bg = w.node_tree.nodes.get("Background"); bg.inputs[0].default_value = (0.03, 0.30, 0.42, 1); bg.inputs[1].default_value = 0.8
    for name, rot, e in (("MB_Sun", (math.radians(40), 0, math.radians(30)), 3.5), ("MB_Rim", (math.radians(-120), 0, math.radians(-40)), 1.5)):
        ld = bpy.data.lights.get(name) or bpy.data.lights.new(name, "SUN"); ld.energy = e
        o = bpy.data.objects.new(name, ld); sc.collection.objects.link(o); o.rotation_euler = rot
    sc.view_settings.view_transform = "Standard"

sh = build()
RIG = globals().get("WITH_RIG", True)
if RIG: rig(sh)
stage()
print("V4", sh.name, "triangles:", sum(len(p.vertices) - 2 for p in sh.data.polygons))
