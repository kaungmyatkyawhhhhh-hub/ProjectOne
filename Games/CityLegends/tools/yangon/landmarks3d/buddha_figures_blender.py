"""buddha_figures_blender.py (2026-11-16): the Chaukhtatgyi (reclining) and Ngahtatgyi (seated) Buddha figures, HEADLESS Blender 3.6.

References: the turnaround sheets made from the real photos (imports/refs/exploded/<name>/<name>_turnaround_v1.png) + the photos.
    blender -b --factory-startup --python buddha_figures_blender.py -- <chauk|ngah> <out.json> [preview_dir]
Forms: metaball families (one smooth closed shell per family: body, head+neck, arms, feet), converted to meshes, then
"sculpt" brushes (gaussian displacements along the normal) for the face, robe folds and jewelled bands, flat cuts where the
figure meets the dais / at the soles, decimated (head kept dense), and the paint (eyes, liner, lids, brows, lips, hair,
maroon border, bands) as material regions ON the same surface, so nothing is stacked (no flicker). Output: triangles with
smooth normals in the hall model's metres (bahan_buddhas3d.py frame), by group:
  FSK skin white, FGO satin gold robe, FGB bright gold (crown, bands, wings, jewels), FMR maroon border, FBK black (hair,
  liner, brows, eye glass, nostrils, lashes), FLD pale blue lids, FLP red lips, FPK pink (inner ears, nails), FSO salmon soles.
"""
import bpy
import bmesh
import json
import math
import os
import sys

import numpy as np
from mathutils import Vector, Quaternion, Matrix
from mathutils.bvhtree import BVHTree
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ornament_kit as OK  # noqa: E402  (2026-11-16 carved ornament kit: the crown filigree)

ARGS = sys.argv[sys.argv.index("--") + 1:]
WHICH, OUT = ARGS[0], ARGS[1]
PREV = ARGS[2] if len(ARGS) > 2 else None
K = 1 / 0.574


def clear():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)


def fam(name, res):
    mb = bpy.data.metaballs.new(name)
    mb.resolution = res
    mb.render_resolution = res
    mb.threshold = 0.6
    ob = bpy.data.objects.new(name, mb)
    bpy.context.scene.collection.objects.link(ob)
    return mb


def quat_to(d):
    return Vector((1, 0, 0)).rotation_difference(Vector(d).normalized())


def ell(mb, c, h, q=None, neg=False):
    e = mb.elements.new(type="ELLIPSOID")
    e.co = c
    e.radius = K
    e.size_x, e.size_y, e.size_z = h
    if q is not None:
        e.rotation = q
    e.use_negative = neg
    return e


def box(mb, c, h, rr=0.5, q=None):
    e = mb.elements.new(type="CUBE")
    e.co = c
    e.radius = rr / 0.574
    e.size_x, e.size_y, e.size_z = [max(0.01, v - rr) for v in h]
    if q is not None:
        e.rotation = q
    return e


def limb(mb, pts):
    """pts: [(point, radius)]: a capsule per segment (radius = mean of the two ends)."""
    for (p0, r0), (p1, r1) in zip(pts[:-1], pts[1:]):
        p0, p1 = Vector(p0), Vector(p1)
        d = p1 - p0
        e = mb.elements.new(type="CAPSULE")
        e.co = (p0 + p1) / 2
        r = (r0 + r1) / 2
        e.radius = r / 0.574
        e.size_x = max(0.01, d.length / 2)
        e.rotation = quat_to(d)


def to_bm(name):
    ob = bpy.data.objects[name]
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.normal_update()
    return bm


def displace(bm, fn):
    """fn(P (n,3), N (n,3)) -> offsets (n,) along the normal."""
    vs = list(bm.verts)
    P = np.array([v.co[:] for v in vs])
    N = np.array([v.normal[:] for v in vs])
    d = fn(P, N)
    for v, p, n, o in zip(vs, P, N, d):
        if o != 0:
            v.co = Vector(p + n * o)
    bm.normal_update()


def bisect(bm, co, no, keep_side=-1, fill=False):
    """Cut by a plane and drop the part on the +no side (keep_side=-1). fill: close the hole flat."""
    geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
    res = bmesh.ops.bisect_plane(bm, geom=geom, plane_co=co, plane_no=no, clear_outer=(keep_side < 0), clear_inner=(keep_side > 0))
    if fill:
        edges = [e for e in bm.edges if e.is_boundary]
        if edges:
            bmesh.ops.holes_fill(bm, edges=edges, sides=0)
    bm.normal_update()


def decimate(bm, target):
    me = bpy.data.meshes.new("tmp")
    bm.to_mesh(me)
    ob = bpy.data.objects.new("tmp", me)
    bpy.context.scene.collection.objects.link(ob)
    nf = sum(len(p.vertices) - 2 for p in me.polygons)
    if nf > target:
        m = ob.modifiers.new("d", "DECIMATE")
        m.ratio = target / nf
        m.use_collapse_triangulate = True
    dg = bpy.context.evaluated_depsgraph_get()
    me2 = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    out = bmesh.new()
    out.from_mesh(me2)
    bmesh.ops.triangulate(out, faces=out.faces[:])
    out.normal_update()
    bpy.data.objects.remove(ob, do_unlink=True)
    return out


GROUPS = {}
MIRROR = [False]   # the Chaukhtatgyi frame maps u -> 34 - u (a mirror): triangles must be turned over


def refine(bm, classify, levels=4, default="FSK"):
    """Split edges whose two ends paint differently (no T-junctions: subdivide_edges re-fans the faces), so painted
    outlines (eyes, liner, lips, borders) come out crisp on a coarse mesh."""
    for _ in range(levels):
        lab = {v: (classify(v.co, v.normal) or default) for v in bm.verts}
        edges = [e for e in bm.edges if lab[e.verts[0]] != lab[e.verts[1]]]
        if not edges:
            break
        bmesh.ops.subdivide_edges(bm, edges=edges, cuts=1, use_grid_fill=False)
        bmesh.ops.triangulate(bm, faces=bm.faces[:])
        bm.normal_update()
    return bm


def emit(bm, classify, xf, smooth_deg=50.0, default="FSK"):
    """Triangles of bm into GROUPS; classify(centre (model), normal) -> group or None (default). xf: model -> hall."""
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bm.normal_update()
    cos_lim = math.cos(math.radians(smooth_deg))
    for f in bm.faces:
        c = f.calc_center_median()
        g = classify(c, f.normal) if classify else None
        g = g or default
        fn = f.normal
        pts, nrm = [], []
        for v in f.verts:
            vn = v.normal if v.normal.dot(fn) > cos_lim else fn
            pts.append(xf(v.co))
            nrm.append(xf(vn, direction=True))
        if MIRROR[0]:
            pts, nrm = pts[::-1], nrm[::-1]
        GROUPS.setdefault(g, []).append([pts, nrm])


def gauss(P, c, s):
    d = (P - np.array(c)) / np.array(s)
    return np.exp(-np.sum(d * d, axis=1))


# ------------------------------------------------------------------------------------------------ head helpers
class HeadFrame:
    def __init__(self, c, R, U, F, rad):
        self.c = np.array(c, float)
        self.R, self.U, self.F = (np.array(v, float) / np.linalg.norm(v) for v in (R, U, F))
        self.rad = np.array(rad, float)   # half sizes along R, U, F

    def local(self, P):
        D = np.atleast_2d(P) - self.c
        return np.stack([D @ self.R / self.rad[0], D @ self.U / self.rad[1], D @ self.F / self.rad[2]], axis=1)

    def world(self, l):
        return self.c + self.R * l[0] * self.rad[0] + self.U * l[1] * self.rad[1] + self.F * l[2] * self.rad[2]


def face_sculpt(P, N, H, style):
    """Offsets (m) for a face, in head-local normalised coords (x across, y up, z forward)."""
    L = H.local(P)
    x, y, z = L[:, 0], L[:, 1], L[:, 2]
    ax = np.abs(x)
    front = np.clip((z - 0.15) / 0.35, 0, 1)
    s = H.rad[1]   # metres per unit (vertical)
    d = np.zeros(len(P))
    g = lambda cx, cy, sx, sy: np.exp(-(((ax - cx) / sx) ** 2 + ((y - cy) / sy) ** 2))
    gc = lambda cy, sx, sy: np.exp(-((x / sx) ** 2 + ((y - cy) / sy) ** 2))
    # eye sockets, brow ridge, cheeks
    ey = -0.06 if style == "chauk" else -0.04
    if style == "chauk":
        d += -0.050 * g(0.36, ey, 0.30, 0.12)
        d += 0.028 * g(0.36, ey, 0.24, 0.07)        # big glass eyeball inside the socket
    else:
        d += -0.045 * g(0.35, ey, 0.24, 0.11)
        d += 0.024 * g(0.35, ey + 0.02, 0.19, 0.045)  # lowered upper lid
    d += 0.030 * g(0.38, ey + 0.22, 0.30, 0.06)       # brow ridge
    d += 0.040 * g(0.46, -0.42, 0.24, 0.24)           # cheeks
    # nose: ridge, tip, wings, groove under it
    ridge = np.exp(-((x / 0.07) ** 2)) * np.clip((0.12 - y) / 0.5, 0, 1) * np.clip((y + 0.47) / 0.08, 0, 1)
    d += (0.11 if style == "chauk" else 0.095) * ridge
    d += 0.055 * gc(-0.44, 0.085, 0.06)
    d += 0.024 * g(0.095, -0.47, 0.05, 0.04)
    d += -0.012 * gc(-0.53, 0.045, 0.035)
    # lips: upper and lower, mouth corners, chin
    lw = 0.16 if style == "chauk" else 0.15
    d += 0.040 * gc(-0.60, lw, 0.04)
    d += 0.048 * gc(-0.68, lw * 0.85, 0.045)
    d += -0.018 * gc(-0.64, lw * 1.05, 0.012)
    d += -0.015 * g(lw * 1.05, -0.63, 0.04, 0.05)
    d += 0.040 * gc(-0.90, 0.22, 0.10)
    return d * s * front


def face_paint(L, style):
    """Group for a face point (head-local), or None."""
    x, y, z = L
    if z < 0.25:
        return None
    ax = abs(x)
    # urna
    if (x / 0.04) ** 2 + ((y - 0.24) / 0.065) ** 2 < 1:
        return "FGB"
    # brows: an arch
    by = (0.17 if style == "chauk" else 0.13) - 1.1 * (ax - 0.40) ** 2
    if 0.13 < ax < 0.68 and abs(y - by) < (0.038 if style == "chauk" else 0.03) * (1.2 - abs(ax - 0.40) * 1.2):
        return "FBK"
    # eyes: almond (outer corner up a little)
    ecx, ecy = (0.36, -0.06) if style == "chauk" else (0.35, -0.04)
    ew, eh = (0.25, 0.072) if style == "chauk" else (0.2, 0.055)
    t = (ax - ecx) / ew
    if abs(t) < 1.3:
        tilt = 0.04 * t
        top = ecy + tilt + eh * max(0.0, 1 - t * t) ** 0.85
        bot = ecy + tilt - eh * 0.7 * max(0.0, 1 - t * t) ** 0.85
        if abs(t) < 1 and bot < y < top:
            if style == "chauk":
                return "FBK"            # the big dark glass eye
            # serene lowered eye: dark iris strip under the lid
            return "FBK" if y < ecy + 0.012 and abs(t) < 0.75 else "FSK"
        # liner round the eye + a wing at the outer corner
        lw = 0.035 if style == "chauk" else 0.018
        if abs(t) < 1.05 and (top <= y < top + lw or bot - lw * 0.6 < y <= bot):
            return "FBK"
        if style == "chauk" and 1.0 < t < 1.3 and abs(y - (ecy + tilt + 0.03 + (t - 1) * 0.12)) < 0.02:
            return "FBK"
        if style == "chauk" and abs(t) < 1.05 and top + lw <= y < top + lw + 0.085 * max(0.0, 1 - t * t) ** 0.5 + 0.01:
            return "FLD"
    # nostrils (underside of the tip)

    # lips
    lw = 0.15 if style == "chauk" else 0.14
    if abs(x) < lw:
        bow = 0.012 * math.cos(math.pi * x / 0.06) if ax < 0.06 else 0.0
        upper = -0.58 - 0.05 * (x / lw) ** 2 + bow
        lower = -0.73 + 0.07 * (x / lw) ** 2
        if lower < y < upper:
            return "FLP"
    return None


# ---------------------------------------------------------------- Chaukhtatgyi head v3 (coordinator, 16 Nov: "still cartoonish")
V3 = dict(eyey=-0.03, eyex=0.355, ew=0.27, eh=0.10, brow=0.235, nosey=-0.40, mouth=-0.57, lw=0.15)


def face_sculpt_v3(P, N, H):
    L = H.local(P)
    x, y, z = L[:, 0], L[:, 1], L[:, 2]
    ax = np.abs(x)
    front = np.clip((z - 0.15) / 0.35, 0, 1)
    g = lambda cx, cy, sx, sy: np.exp(-(((ax - cx) / sx) ** 2 + ((y - cy) / sy) ** 2))
    gc = lambda cy, sx, sy: np.exp(-((x / sx) ** 2 + ((y - cy) / sy) ** 2))
    v = V3
    d = np.zeros(len(P))
    d += -0.078 * g(v["eyex"], v["eyey"], 0.27, 0.13)              # eye sockets (v4: deeper set, photo 1)
    d += 0.022 * g(v["eyex"], v["eyey"], 0.22, 0.065)               # eyeball / lids
    d += 0.040 * g(0.38, v["brow"] - 0.01, 0.30, 0.045)             # brow ridge (v4: stronger, shades the eyes)
    d += 0.060 * g(0.44, -0.36, 0.26, 0.26)                          # full cheeks
    d += 0.030 * g(0.30, -0.62, 0.16, 0.14)                          # lower cheeks
    ridge = np.exp(-((x / 0.042) ** 2)) * np.clip((0.16 - y) / 0.4, 0, 1) * np.clip((y - v["nosey"] + 0.02) / 0.04, 0, 1)
    d += 0.17 * ridge                                                # straight nose ridge (v4: sharper, higher)
    d += 0.035 * np.exp(-((x / 0.11) ** 2)) * np.clip((0.1 - y) / 0.45, 0, 1) * np.clip((y - v["nosey"]) / 0.06, 0, 1)  # its flanks
    d += 0.075 * gc(v["nosey"] + 0.01, 0.06, 0.045)                 # tip (v4: narrower)
    d += 0.040 * g(0.10, v["nosey"] - 0.005, 0.045, 0.04)           # wings
    d += -0.020 * g(0.062, v["nosey"] - 0.04, 0.03, 0.02)          # nostrils
    d += -0.014 * gc(v["nosey"] - 0.085, 0.035, 0.03)               # philtrum
    lw = v["lw"]
    d += 0.032 * gc(v["mouth"] + 0.025, lw, 0.025)
    d += 0.038 * gc(v["mouth"] - 0.03, lw * 0.85, 0.03)
    d += -0.012 * np.exp(-((x / (lw * 1.1)) ** 2 + ((y - (v["mouth"] + 0.03 * (x / lw) ** 2)) / 0.008) ** 2))
    d += -0.012 * g(lw * 1.05, v["mouth"] + 0.025, 0.03, 0.03)
    d += -0.010 * gc(v["mouth"] - 0.09, 0.10, 0.025)
    d += 0.060 * gc(-0.86, 0.26, 0.12)                               # chin
    return d * H.rad[1] * front


def face_paint_v3(L):
    """v3 face paint: white glass eye with iris and highlight, winged liner, thin blue lid, high thin brows,
    small red lips with a dark line, and soft grey baked shading (FSH light, FS2 darker)."""
    x, y, z = L
    if z < 0.2:
        return None
    ax = abs(x)
    v = V3
    ew, eh, ex, ey = v["ew"], v["eh"], v["eyex"], v["eyey"]
    if (x / 0.03) ** 2 + ((y - 0.27) / 0.05) ** 2 < 1:
        return "FGB"
    by = v["brow"] - 1.3 * (ax - 0.39) ** 2
    if 0.16 < ax < 0.66 and abs(y - by) < 0.017 * (1.2 - abs(ax - 0.40) * 1.5):
        return "FBK"
    t = (ax - ex) / ew
    tilt = 0.03 * t
    if abs(t) < 1.6:
        k = max(0.0, 1 - t * t)
        top = ey + tilt + eh * k ** 0.75
        bot = ey + tilt - eh * 0.72 * k ** 0.75
        if abs(t) < 1 and bot < y < top:
            ix, iy = ex - 0.01, ey + 0.035
            dx, dy = (ax - ix), (y - iy) * (3.3 / 2.35)
            if dx * dx + dy * dy < 0.098 ** 2:
                hx, hy = ix - 0.03, iy + 0.012
                if (ax - hx) ** 2 + ((y - hy) * 1.4) ** 2 < 0.016 ** 2:
                    return "FEW"
                return "FBK"
            return "FEW"
        if abs(t) < 1.04 and top <= y < top + 0.026 + 0.008 * max(0.0, t):
            return "FBK"
        if 0.95 <= t < 1.5:
            wy = ey + tilt + 0.02 + (t - 0.95) * 0.13
            if abs(y - wy) < 0.02 * (1.55 - t) / 0.6 + 0.002:
                return "FBK"
        if -0.2 < t < 1.0 and bot - 0.011 < y <= bot:
            return "FBK"
        if abs(t) < 1.0 and top + 0.026 <= y < top + 0.026 + 0.026 * k ** 0.5:
            return "FLD"
        if abs(t) < 1.05 and bot - 0.04 < y <= bot - 0.011:
            return "FSH"
    lw = v["lw"]
    if ax < lw:
        q = (x / lw) ** 2
        ym = v["mouth"] + 0.03 * q
        bow = 0.008 * math.cos(math.pi * x / 0.05) if ax < 0.05 else 0.0
        upper = ym + 0.032 * (1 - q) ** 0.8 + bow
        lower = ym - 0.045 * (1 - q) ** 0.7
        if abs(y - ym) < 0.0055:
            return "FMR"
        if lower < y < upper:
            return "FLP"
        if lower - 0.03 < y <= lower and ax < 0.09:
            return "FSH"
    if ((ax - lw * 1.05) / 0.03) ** 2 + ((y - v["mouth"] - 0.03) / 0.03) ** 2 < 1:
        return "FS2"
    if ax < 0.06 and v["nosey"] - 0.12 < y < v["nosey"] - 0.07:
        return "FSH"
    return None


# ================================================================================================ CHAUKHTATGYI
def chauk():
    """Figure frame: u from the head end (0) to the soles (65), y to the front (face side), z up from the dais top.
    Hall model: x = 34 - u, y = y, z = 2.6 + z (bahan_buddhas3d chauk())."""
    XH, PZ = 34.0, 2.6
    MIRROR[0] = True

    def F(u, y, z):
        return Vector((u, y, z))

    def xf(p, direction=False):
        if direction:
            return [-p[0], p[1], p[2]]
        return [XH - p[0], p[1], PZ + p[2]]

    # --- body (robe): a smooth loft of cross-sections (u, zc, hz, hy back, hy front), plus the robe flaring onto the dais
    PROF = [(9.6, 4.6, 0.6, 0.6, 0.6), (10.2, 4.5, 2.4, 2.0, 2.0), (11.0, 4.4, 3.4, 2.9, 3.0), (12.6, 4.35, 4.0, 3.4, 3.5),
            (15.5, 4.4, 4.25, 3.7, 3.9), (19.5, 4.1, 3.95, 3.5, 3.8), (23.5, 3.85, 3.7, 3.4, 3.7), (27.5, 4.0, 3.95, 3.6, 3.9),
            (31.0, 3.8, 3.8, 3.5, 3.8), (35.0, 3.35, 3.35, 3.1, 3.4), (39.0, 3.0, 3.0, 2.8, 3.0), (43.0, 2.75, 2.75, 2.55, 2.75),
            (47.0, 2.55, 2.55, 2.35, 2.55), (51.0, 2.4, 2.4, 2.2, 2.4), (55.0, 2.35, 2.35, 2.15, 2.3), (59.5, 2.3, 2.3, 2.1, 2.2),
            (60.2, 2.3, 1.2, 1.0, 1.0)]
    body_bm = loft_body(PROF, step=0.6, seg=52, flare=(14.0, 56.0, 1.6))
    larm = fam("LArm", 0.08)
    limb(larm, [(F(12.4, 0.6, 7.7), 1.45), (F(20.5, 1.6, 7.45), 1.25), (F(28.6, 2.2, 7.15), 1.0)])
    # --- right arm (bare white): upper arm on the dais to the elbow at the head end, forearm up behind the head
    rarm = fam("RArm", 0.08)
    limb(rarm, [(F(11.5, -0.6, 1.5), 1.35), (F(5.5, -0.2, 1.4), 1.25), (F(0.9, 0.2, 1.4), 1.15)])
    limb(rarm, [(F(0.9, 0.2, 1.5), 1.1), (F(2.3, -0.4, 4.6), 0.95), (F(3.2, -0.9, 7.0), 0.85)])
    ell(rarm, F(3.7, -1.0, 8.4), (0.55, 1.1, 1.45), q=Quaternion((0, 1, 0), math.radians(-18)))
    for k in range(4):
        ell(rarm, F(3.95, -0.9 + 0.32 * (k - 1.5), 9.9 + 0.1 * abs(k - 1.5)), (0.25, 0.16, 0.55), q=Quaternion((0, 1, 0), math.radians(-18)))
    # --- left hand on the hip (white)
    lhand = fam("LHand", 0.06)
    ell(lhand, F(30.9, 2.5, 6.75), (1.9, 1.05, 0.45))
    for k in range(4):
        ell(lhand, F(33.1, 2.0 + 0.42 * k, 6.62), (0.75, 0.2, 0.25))
    ell(lhand, F(30.3, 3.6, 6.7), (0.8, 0.25, 0.25), q=Quaternion((0, 0, 1), math.radians(35)))
    # --- head + neck (one family), tilted so the crown leans to the head end; face to +y
    tilt = math.radians(17)
    HC = Vector((6.9, 0.45, 8.85))
    Rv = Vector((math.cos(tilt), 0, math.sin(tilt)))          # across the face (towards the feet = +u), tilted
    Uv = Vector((-math.sin(tilt), 0, math.cos(tilt)))
    Fv = Vector((0, 1, 0))
    rad = (2.35, 3.3, 2.5)
    head = fam("Head", 0.04)
    qh = Matrix((Rv, Fv, Uv)).transposed().to_quaternion()     # local x=R, y=F, z=U
    ell(head, HC, (rad[0], rad[2], rad[1]), q=qh)
    ell(head, HC - Fv * 0.35 + Uv * 0.75, (rad[0] * 0.97, rad[2] * 0.95, rad[1] * 0.85), q=qh)   # tall skull
    ell(head, HC + Fv * 0.75 - Uv * 2.15, (1.35, 1.1, 1.0), q=qh)     # chin / jaw (fuller)
    for s in (-1, 1):
        ell(head, HC + Fv * 0.8 + Rv * s * 1.0 - Uv * 1.05, (0.95, 0.95, 1.2), q=qh)   # full cheeks
        ec = HC + Rv * s * 2.25 - Fv * 0.25 - Uv * 0.5               # long ears with an open lobe
        ell(head, ec, (0.28, 0.66, 1.6), q=qh)
        ell(head, ec - Uv * 1.65 + Rv * s * 0.08, (0.27, 0.52, 0.95), q=qh)
        ell(head, ec - Uv * 1.75 + Rv * s * 0.12 + Fv * 0.12, (0.2, 0.2, 0.42), q=qh, neg=True)
    # neck down to the shoulders
    limb(head, [(HC - Uv * 2.1 + Fv * 0.1, 1.55), (F(9.6, 0.3, 4.6), 1.6), (F(11.4, 0.2, 3.2), 1.7)])
    H = HeadFrame(HC, Rv, Uv, Fv, rad)
    # --- feet (salmon), stacked, soles at u = 65; toes to +y
    feet = []
    radii = [0.44, 0.34, 0.31, 0.28, 0.25]
    for i, (zc, yc) in enumerate(((1.55, 1.0), (4.5, 1.35))):
        mb = fam("Foot%d" % i, 0.06)
        box(mb, F(62.6, yc, zc), (2.6, 4.0, 1.5), rr=1.1)
        ell(mb, F(60.4, yc - 2.0, zc), (2.0, 1.8, 1.35))       # heel / ankle
        rr = radii if i == 0 else radii[::-1]
        z = zc + 1.55
        for r in rr:
            z -= r + 0.03
            ell(mb, F(63.9, yc + 4.15, z), (1.05, 0.95, r * 1.12))
            z -= r + 0.03
        feet.append("Foot%d" % i)
    # ---------------- convert, sculpt, cut, decimate, paint
    def robe_folds(P, N):
        u, y, z = P[:, 0], P[:, 1], P[:, 2]
        front = np.clip(y / 2.5, 0, 1) * 0.8 + 0.2
        # long diagonal drapery folds (from the upper back down to the front), slowly changing spacing
        ph = (z + 0.22 * u + 0.6 * np.sin(u * 0.21)) * 2 * math.pi / (1.9 + 0.5 * np.sin(u * 0.13))
        w1 = np.sign(np.sin(ph)) * np.abs(np.sin(ph)) ** 0.7 * 0.085
        # pleats where the robe spreads onto the dais
        pleat = np.exp(-((z - 0.5) / 0.8) ** 2) * np.sin(u * 2 * math.pi / 1.7) * 0.07
        return (w1 + pleat) * front

    bm = body_bm
    displace(bm, robe_folds)
    bisect(bm, Vector((0, 0, -0.05)), Vector((0, 0, -1)))

    # maroon border: a band on the front from the shoulder diagonally down to the dais, and a cuff near the wrist
    border = [(12.6, 7.9), (14.5, 6.2), (18.0, 3.6), (21.5, 1.6), (24.6, 0.3)]

    def seg_dist(pu, pz, pts):
        best = 9e9
        for (a0, b0), (a1, b1) in zip(pts[:-1], pts[1:]):
            du, dz = a1 - a0, b1 - b0
            t = max(0, min(1, ((pu - a0) * du + (pz - b0) * dz) / (du * du + dz * dz)))
            best = min(best, math.hypot(pu - a0 - t * du, pz - b0 - t * dz))
        return best

    def body_cls(c, n):
        if c.y > 0.5 and seg_dist(c.x, c.z, border) < 0.24:
            return "FMR"
        if 28.0 < c.x < 28.45 and c.z > 5.6:
            return "FMR"
        return "FGO"
    refine(bm, body_cls, levels=3, default="FGO")
    emit(bm, body_cls, xf)

    la = to_bm("LArm")
    displace(la, lambda P, N: np.sin(P[:, 0] * 2 * math.pi / 2.2 + P[:, 2] * 1.5) * 0.03)
    la = decimate(la, 2600)
    emit(la, lambda c, n: "FMR" if 27.9 < c.x < 28.5 else "FGO", xf)
    for name, tgt in (("RArm", 3200), ("LHand", 1400)):
        b = to_bm(name)
        bisect(b, Vector((0, 0, -0.05)), Vector((0, 0, -1)))
        b = decimate(b, tgt)
        emit(b, lambda c, n: "FPK" if (name == "LHand" and c.x > 33.6) else None, xf)

    hb = to_bm("Head")
    displace(hb, lambda P, N: face_sculpt_v3(P, N, H))
    # hair: dark tight curls (a bump lattice) above the crown and at the back
    def hair_curls(P, N):
        L = H.local(P)
        hair = (L[:, 1] > 0.93) | ((L[:, 2] < -0.55) & (L[:, 1] > -0.15))
        k = 2 * math.pi / 0.38
        b = np.sin(P[:, 0] * k) * np.sin(P[:, 1] * k + 0.7) * np.sin(P[:, 2] * k + 1.3)
        return np.where(hair, 0.07 * np.clip(b + 0.2, 0, None), 0.0)
    displace(hb, hair_curls)
    hb = decimate(hb, 8500)

    def head_cls(c, n):
        L = H.local(np.array(c[:]))[0]
        x, y, z = L
        # inner ears pink (front face of the ear, inside its rim)
        if abs(x) > 0.93 and -0.5 < z < 0.15 and -1.05 < y < 0.3 and n.dot(Fv) > 0.55:
            return "FPK"
        if y > 0.44:
            return "FBK"
        if z < -0.25 and y > -0.15 and abs(x) < 0.9:
            return "FBK"
        return face_paint_v3(L)
    refine(hb, head_cls, levels=5)
    H.bvh = BVHTree.FromBMesh(hb)
    emit(hb, head_cls, xf)

    for nm in feet:
        b = to_bm(nm)
        bisect(b, Vector((65.0, 0, 0)), Vector((1, 0, 0)), fill=True)
        bisect(b, Vector((0, 0, -0.05)), Vector((0, 0, -1)))
        b = decimate(b, 2400)
        emit(b, None, xf, default="FSO")

    # ---------------- crown: a gold band round the forehead and sides, scalloped top, pointed flap by each ear
    # v4 (2026-11-16): the band ends lower and the petals are now open filigree from the ornament kit (below)
    crown_band(H, xf, th0=-118, th1=118, ylo=0.33, yhi=0.60, flap=92, off=0.09, petals=(0, 0))
    crown_band(H, xf, th0=-116, th1=116, ylo=0.325, yhi=0.38, flap=999, off=0.16, petals=(0, 0), thick=0.07)   # lower rim
    crown_band(H, xf, th0=-114, th1=114, ylo=0.62, yhi=0.655, flap=999, off=0.16, petals=(0, 0), thick=0.06)  # upper rim
    for row, (yy, n, r0, grp) in enumerate(((0.515, 19, 0.11, "FLP"), (0.585, 27, 0.06, "FLD"))):
        for k in range(n):
            th = math.radians(-104 + 208 * k / (n - 1))
            r = max(0.05, 1 - yy * yy) ** 0.5
            p, nv = surface_hit(H, r * math.sin(th), yy, r * math.cos(th))
            jewel(p + nv * (0.17 + r0 * 0.4), r0, grp if (k % 2 == 0 or row == 1) else "FGB", xf)
    # v4 crown filigree (ornament kit): 13 carved kanote flame finials (knob, curled leaves, lobed blade, raised
    # beaded spine) standing round the band's top edge with open gaps between them, and a pair of curled scroll leaves
    # on the band between each two; leaning out a little like the photo's crown points
    Uw = Vector(H.U.tolist())
    fin = OK.flame_finial(1.05, lod="lo")
    for k in range(13):
        th = math.radians(-100 + 200 * k / 12)
        yy = 0.55
        r = max(0.05, 1 - yy * yy) ** 0.5
        p, nv = surface_hit(H, r * math.sin(th), yy, r * math.cos(th))
        oh = (nv - Uw * nv.dot(Uw)).normalized()
        up = (Uw + oh * 0.35).normalized()
        out = (oh - up * oh.dot(up)).normalized()
        o = p + nv * 0.16
        kit_on(fin, o, out.cross(up), out, up, "FGB", xf)
    for k in range(12):
        th = math.radians(-100 + 200 * (k + 0.5) / 12)
        yy = 0.45
        r = max(0.05, 1 - yy * yy) ** 0.5
        p, nv = surface_hit(H, r * math.sin(th), yy, r * math.cos(th))
        oh = (nv - Uw * nv.dot(Uw)).normalized()
        up = (Uw - oh * Uw.dot(oh)).normalized()
        out = oh
        sp = OK.Piece("sc")
        for hand in (1, -1):
            OK.slab(sp, "G", OK.scroll(0.32, hand * 0.03, -0.12, ang=-hand * 20, mirror=hand < 0, n=5), 0.0, 0.05, 0.015,
                    band=False)
        kit_on(sp, p + nv * 0.205, out.cross(up), out, up, "FGB", xf)
    # (v3: no lashes, the long winged liner carries the eye)
    for s in ():
        for k in range(11):
            t = -0.6 + 1.5 * k / 10
            ex = s * (0.36 + 0.25 * t)
            ey = -0.06 + 0.04 * t + 0.072 * max(0.0, 1 - t * t) ** 0.85 + 0.03
            base = surface_point(H, ex, ey)
            nrm = Vector(base[1])
            tip = Vector(base[0]) + nrm * 0.14 + Vector(H.U.tolist()) * 0.13 + Vector(H.R.tolist()) * (0.10 * s * (t + 0.4))
            stick(Vector(base[0]) - nrm * 0.02, tip, 0.03, "FBK", xf)
    return xf


# ------------------------------------------------------------------------------------------------ shared pieces
def loft_body(prof, step, seg, flare):
    """Rings along u from a profile table (Catmull-Rom between rows); rounded start, closed end. flare = (u0, u1, metres):
    the robe spreads onto the dais at the bottom front between u0 and u1."""
    U = np.array([r[0] for r in prof])
    cols = np.array([r[1:] for r in prof])
    us = np.arange(U[0], U[-1] + 1e-6, step)
    def interp(u):
        return np.array([np.interp(u, U, cols[:, k]) for k in range(cols.shape[1])])
    rows = [interp(u) for u in us]
    # smooth the sampled rows (3 passes of a 1-2-1 filter) so the table's corners do not show
    R = np.array(rows)
    for _ in range(6):
        R[1:-1] = (R[:-2] + 2 * R[1:-1] + R[2:]) / 4
    bm = bmesh.new()
    rings = []
    u0, u1, fl = flare
    for u, (zc, hz, hyb, hyf) in zip(us, R):
        fw = fl * min(1, max(0, (u - u0) / 3.0)) * min(1, max(0, (u1 - u) / 3.0))
        ring = []
        for i in range(seg):
            th = 2 * math.pi * i / seg
            c, s_ = math.cos(th), math.sin(th)
            hy = hyf if c > 0 else hyb
            ex = 2.3
            y = hy * math.copysign(abs(c) ** (2 / ex), c)
            z = hz * math.copysign(abs(s_) ** (2 / ex), s_)
            if c > 0 and s_ < 0:
                y += fw * (abs(s_) ** 3) * c
            ring.append(bm.verts.new((u, y, zc + z)))
        rings.append(ring)
    for a, b in zip(rings[:-1], rings[1:]):
        for i in range(seg):
            bm.faces.new((a[i], b[i], b[(i + 1) % seg], a[(i + 1) % seg]))
    bm.faces.new(rings[0])
    bm.faces.new(rings[-1][::-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.normal_update()
    return bm


def surface_hit(H, x, y, z):
    """The real head surface (BVH ray) in the direction of head-local (x, y, z): (point, normal)."""
    pe = Vector(H.world((x, y, z)).tolist())
    c = Vector(H.c.tolist())
    d = (pe - c)
    o = c + d * 3.0
    hit = H.bvh.ray_cast(o, -d.normalized(), d.length * 4)
    if hit[0] is None:
        return pe, d.normalized()
    return hit[0], hit[1]


def surface_point(H, x, y):
    zz = max(0.05, 1 - x * x - y * y) ** 0.5
    p, n = surface_hit(H, x, y, zz)
    return p[:], n

def jewel(c, r, grp, xf):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=r)
    for v in bm.verts:
        v.co = v.co + c
    bm.normal_update()
    emit(bm, None, xf, smooth_deg=80, default=grp)


def stick(p0, p1, w, grp, xf):
    """A thin square stick (lashes)."""
    d = (p1 - p0)
    a = d.orthogonal().normalized() * w / 2
    b = d.cross(a).normalized() * w / 2
    c0 = [p0 + a + b, p0 - a + b, p0 - a - b, p0 + a - b]
    c1 = [p + d * 1.0 for p in c0]
    c1 = [p1 + (q - p0) * 0.4 for q in c0]
    faces = [(c0[i], c0[(i + 1) % 4], c1[(i + 1) % 4], c1[i]) for i in range(4)] + [(c1[0], c1[1], c1[2], c1[3])]
    for q in faces:
        n = (q[1] - q[0]).cross(q[2] - q[0]).normalized()
        cen = sum(q, Vector()) / 4
        if n.dot(cen - (p0 + p1) / 2) < 0:
            q = q[::-1]
            n = -n
        for tri in ((q[0], q[1], q[2]), (q[0], q[2], q[3])):
            pts = [xf(v) for v in tri]
            GROUPS.setdefault(grp, []).append([pts[::-1] if MIRROR[0] else pts, [xf(n, direction=True)] * 3])


def kit_on(piece, origin, right, out, up, grp, xf):
    """An ornament_kit piece (metres, x right / y out / z up) onto the figure at origin (model coords), flat-shaded."""
    for _g, a, b, c in piece.placed(tuple(origin), tuple(right), tuple(out), tuple(up)):
        A, B, C = Vector(a), Vector(b), Vector(c)
        n = (B - A).cross(C - A)
        if n.length < 1e-12:
            continue
        n.normalize()
        pts = [xf(A), xf(B), xf(C)]
        nn = xf(n, direction=True)
        if MIRROR[0]:
            pts = pts[::-1]
        GROUPS.setdefault(grp, []).append([pts, [nn, nn, nn]])


def crown_band(H, xf, th0, th1, ylo, yhi, flap, off, grp="FGB", n=160, thick=0.12, petals=(0, 0.035)):
    """A band on the head ellipsoid (offset outward) between local heights ylo..yhi (front), angle th0..th1 (deg, 0 = face)."""
    bm = bmesh.new()
    rows = []
    for i in range(n + 1):
        th = math.radians(th0 + (th1 - th0) * i / n)
        dth = math.degrees(th)
        pc, pa = petals
        if pc:
            ph = (dth / 208.0 * pc * 2 + 0.5) % 1.0          # one pointed lotus petal per period
            petal = pa * max(0.0, 1 - abs(ph - 0.5) * 2) ** 1.8 + 0.03 * max(0.0, math.cos(math.radians(dth * pc * 6)))
        else:
            petal = 0.0
        top = yhi + petal + 0.30 * math.exp(-((abs(dth) - flap) / 9.0) ** 2)
        bot = ylo + 0.08 * (abs(dth) / 90.0) ** 2
        ring = []
        for y in (bot, top):
            yy = min(y, 0.97)
            r = max(0.05, 1 - yy * yy) ** 0.5
            x, z = r * math.sin(th), r * math.cos(th)
            p, nv = surface_hit(H, x, yy, z)
            nv = (p - Vector(H.c.tolist())).normalized() * 0.5 + nv * 0.5
            nv.normalize()
            ring.append((p + nv * off, p + nv * (off + thick)))
        rows.append(ring)
    V = []
    for ring in rows:
        V.append([bm.verts.new(ring[0][0]), bm.verts.new(ring[1][0]), bm.verts.new(ring[1][1]), bm.verts.new(ring[0][1])])
    for a, b in zip(V[:-1], V[1:]):
        for k in range(4):
            bm.faces.new((a[k], a[(k + 1) % 4], b[(k + 1) % 4], b[k]))
    bm.faces.new(V[0][::-1])
    bm.faces.new(V[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.normal_update()
    emit(bm, None, xf, smooth_deg=35, default=grp)


def flame(points, frame, thick, grp, xf):
    """A flat flame ornament: 2D outline (a, b) in frame (origin, ea, eb, en), extruded thick along en."""
    o, ea, eb, en = (Vector(v) for v in frame)
    bm = bmesh.new()
    lo = [bm.verts.new(o + ea * a + eb * b) for a, b in points]
    hi = [bm.verts.new(o + ea * a + eb * b + en * thick) for a, b in points]
    bm.faces.new(lo[::-1])
    bm.faces.new(hi)
    m = len(points)
    for i in range(m):
        bm.faces.new((lo[i], lo[(i + 1) % m], hi[(i + 1) % m], hi[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    emit(bm, None, xf, smooth_deg=20, default=grp)


# ================================================================================================ NGAHTATGYI
def ngah():
    """Hall model frame directly (bahan_buddhas3d ngah()): seat top S = 3.6, figure faces -x, its right = +y.
    Local: fwd = -x from X0 = 12.0, lat = y, z up."""
    S, X0 = 3.6, 12.0

    def P(f, l, z):
        return Vector((X0 - f, l, S + z))

    def xf(p, direction=False):
        return [p[0], p[1], p[2]]

    body = fam("Body", 0.07)
    # lap and knees (wider than the shoulders), hips
    ell(body, P(1.4, 0, 0.7), (3.3, 4.4, 0.7))
    for s in (-1, 1):
        ell(body, P(2.1, s * 4.5, 0.9), (2.2, 2.0, 1.0))
    ell(body, P(-0.2, 0, 1.4), (2.2, 3.1, 1.2))
    # torso: short chest, broad sloping shoulders
    ell(body, P(0.0, 0, 2.9), (1.7, 2.3, 1.35))
    ell(body, P(0.05, 0, 4.6), (1.8, 2.6, 1.45))
    ell(body, P(0.0, 0, 6.0), (1.55, 2.75, 0.95))
    for s in (-1, 1):
        ell(body, P(0.0, s * 2.4, 6.4), (1.15, 1.2, 0.8), q=Quaternion((1, 0, 0), math.radians(-16 * s)))
    # left arm robed: shoulder -> elbow -> wrist (to the lap)
    larm = fam("LArm", 0.06)
    limb(larm, [(P(0.0, -2.95, 6.25), 1.0), (P(0.25, -3.7, 3.8), 0.92), (P(2.0, -2.0, 2.15), 0.62)])
    # right arm bare: separate family (white), hand over the right knee pointing down
    rarm = fam("RArm", 0.05)
    limb(rarm, [(P(0.0, 2.95, 6.25), 0.98), (P(0.3, 3.65, 3.7), 0.85), (P(3.3, 4.1, 1.75), 0.6)])
    ell(rarm, P(3.95, 4.1, 1.15), (0.42, 0.62, 0.72), q=Quaternion((0, 1, 0), math.radians(-25)))
    for k in range(4):
        ell(rarm, P(4.2, 3.7 + 0.27 * k, 0.55), (0.17, 0.13, 0.3))
    # left hand palm up in the lap, right shin across the lap with the sole up
    lhand = fam("LHand", 0.04)
    ell(lhand, P(2.55, -0.55, 2.05), (0.85, 1.25, 0.28))
    for k in range(4):
        ell(lhand, P(3.3, -1.0 + 0.3 * k, 2.08), (0.55, 0.13, 0.15))
    shin = fam("Shin", 0.05)
    limb(shin, [(P(1.9, 4.6, 1.35), 0.8), (P(2.0, 0.6, 1.62), 0.74), (P(1.9, -2.4, 1.72), 0.66)])
    ell(shin, P(2.0, -3.25, 1.78), (1.25, 0.85, 0.4), q=Quaternion((0, 0, 1), math.radians(-10)))
    # head + neck
    HC = P(0.15, 0, 8.85)
    Rv, Uv, Fv = Vector((0, 1, 0)), Vector((0, 0, 1)), Vector((-1, 0, 0))
    rad = (1.58, 1.66, 1.45)
    head = fam("Head", 0.03)
    qh = Matrix((Rv, Fv, Uv)).transposed().to_quaternion()
    ell(head, HC, (rad[0], rad[2], rad[1]), q=qh)
    ell(head, HC - Fv * 0.25 + Uv * 0.3, (rad[0] * 0.97, rad[2] * 0.95, rad[1] * 0.85), q=qh)
    ell(head, HC + Fv * 0.5 - Uv * 1.0, (0.55, 0.5, 0.42), q=qh)
    for s in (-1, 1):
        ell(head, HC + Fv * 0.45 + Rv * s * 0.6 - Uv * 0.45, (0.62, 0.6, 0.62), q=qh)
        ec = HC + Rv * s * 1.28 - Fv * 0.15 - Uv * 0.25
        ell(head, ec, (0.16, 0.36, 0.72), q=qh)
        ell(head, ec - Uv * 0.85 + Rv * s * 0.04, (0.15, 0.28, 0.5), q=qh)
    neck = fam("Neck", 0.05)
    limb(neck, [(HC - Uv * 0.25 - Fv * 0.35, 0.68), (P(0.15, 0, 7.4), 0.86), (P(0.0, 0, 6.6), 1.05)])
    H = HeadFrame(HC, Rv, Uv, Fv, rad)

    def robe_folds(Pp, N):
        f = X0 - Pp[:, 0]
        l, z = Pp[:, 1], Pp[:, 2] - S
        lap = np.exp(-((z - 0.8) / 0.9) ** 2) * np.sin(np.arctan2(l, f + 1.0) * 26) * 0.045
        torso = np.clip((z - 1.8) / 0.5, 0, 1) * np.sin(l * 2 * math.pi / 0.55 + z * 0.4) * 0.02
        return lap + torso

    # jewelled bands (bright gold, raised): the robe's edge from the left shoulder to the right waist, a U collar, a sash
    def band_d(Pp):
        l, z = Pp[:, 1], Pp[:, 2] - S
        f = X0 - Pp[:, 0]
        edge = np.abs((z - (6.6 - 0.5 * (l + 1.6))) ) < 0.32
        collar = (np.abs(np.hypot(l / 1.0, (z - 6.9) / 1.15) - 1.35) < 0.14) & (z < 6.9)
        sash = (np.abs(z - 2.35) < 0.18) & (f > 0.3)
        return edge, collar, sash

    def skin_side(l, z):
        return z > 6.6 - 0.5 * (l + 1.6)

    def band_disp(Pp, N):
        edge, collar, sash = band_d(Pp)
        l, z = Pp[:, 1], Pp[:, 2] - S
        raised = (edge | collar | sash).astype(float) * 0.05
        jewels = (edge | collar).astype(float) * 0.03 * (np.sin(l * 22) * np.sin(z * 22) > 0.6)
        return raised + jewels

    bm = to_bm("Body")
    displace(bm, robe_folds)
    displace(bm, band_disp)
    bisect(bm, P(0, 0, -0.08), Vector((0, 0, -1)))
    bm = decimate(bm, 8000)

    def body_cls(c, n):
        l, z, f = c.y, c.z - S, X0 - c.x
        a = np.array([c[:]])
        edge, collar, sash = band_d(a)
        if collar[0] or edge[0] or sash[0]:
            return "FGB"
        if skin_side(l, z) and z > 4.0:
            return "FSK"
        return "FGO"
    refine(bm, body_cls, levels=3, default="FGO")
    emit(bm, body_cls, xf)
    la = to_bm("LArm")
    displace(la, lambda Pp, N: np.sin((Pp[:, 2] - S) * 2 * math.pi / 0.9 + Pp[:, 0] * 2) * 0.025)
    la = decimate(la, 2400)
    emit(la, lambda c, n: "FGB" if (X0 - c.x) > 1.55 and c.z < S + 2.6 else "FGO", xf)
    for name, tgt in (("RArm", 2600), ("LHand", 1000), ("Shin", 1600), ("Neck", 1400)):
        b = to_bm(name)
        if name == "Neck":
            displace(b, lambda Pp, N: -0.035 * (np.exp(-((Pp[:, 2] - (S + 7.55)) / 0.05) ** 2) + np.exp(-((Pp[:, 2] - (S + 7.15)) / 0.05) ** 2)))
        b = decimate(b, tgt)
        emit(b, (lambda c, n: "FPK" if c.z < S + 0.12 + 0.2 else None) if name == "RArm" else None, xf)

    hb = to_bm("Head")
    displace(hb, lambda Pp, N: face_sculpt(Pp, N, H, "ngah"))
    hb = decimate(hb, 7000)

    def head_cls(c, n):
        L = H.local(np.array(c[:]))[0]
        x, y, z = L
        if y > 0.45 and z < 0.5:
            return "FBK"
        if z < -0.2 and y > -0.2 and abs(x) < 0.9:
            return "FBK"
        if y < -1.0:
            for k in range(3):     # neck folds as lines
                if abs(y - (-1.15 - 0.3 * k)) < 0.02 and z > 0:
                    return None
        return face_paint(L, "ngah")
    refine(hb, head_cls, levels=4)
    emit(hb, head_cls, xf)

    # crown: tiered pointed cone with jewel rings (bright gold), band over the forehead
    prof = [(9.5, 1.7), (9.95, 1.74), (10.13, 1.8), (10.33, 1.7), (10.55, 1.57), (10.7, 1.61), (11.15, 1.39), (11.3, 1.43),
            (11.9, 1.15), (12.05, 1.18), (12.6, 0.88), (13.2, 0.56), (13.7, 0.26), (14.0, 0.04)]
    cb = bmesh.new()
    rings = []
    n = 64
    for z, r in prof:
        ring = []
        for i in range(n):
            a = 2 * math.pi * i / n
            jw = 1 + 0.02 * (math.cos(a * 16) > 0.7) * (1 if 10.4 < z < 11.8 else 0)
            ring.append(cb.verts.new(HC + Vector((-math.cos(a) * r * 0.97 * jw, math.sin(a) * r * jw, 0)) + Vector((0, 0, S + z - HC.z))))
        rings.append(ring)
    for a_, b_ in zip(rings[:-1], rings[1:]):
        for i in range(n):
            cb.faces.new((a_[i], a_[(i + 1) % n], b_[(i + 1) % n], b_[i]))
    cb.faces.new(rings[0][::-1])
    cb.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(cb, faces=cb.faces[:])
    cb.normal_update()
    emit(cb, None, xf, smooth_deg=40, default="FGB")

    # flame wings: beside the head, on the shoulders, at the elbows (front-facing plates, outer edge swept back)
    def flame_outline(a0, b0, h, w, lean, lobes=3):
        """A tall flame leaf: spine from (a0, b0) up h, leaning outwards by lean; half width w; curled tip; side lobes."""
        n = 24
        L, Rr = [], []
        for i in range(n + 1):
            t = i / n
            sa = a0 + lean * t ** 1.6
            sb = b0 + h * t
            hw = w * math.sin(math.pi * min(1, t * 1.05)) ** 0.8 * (1 - 0.45 * t)
            lob = 0.35 * w * max(0.0, math.sin(t * math.pi * (2 * lobes))) * (1 - t)
            L.append((sa - hw, sb))
            Rr.append((sa + hw + lob, sb - 0.15 * lob))
        tip = (a0 + lean * 1.15, b0 + h * 1.04)
        return L + [tip] + Rr[::-1]

    pieces = [(flame_outline(1.75, 8.0, 3.6, 0.48, 1.1), -0.6, 18),     # beside the head
              (flame_outline(2.5, 6.45, 1.35, 0.42, 0.9, 2), -0.2, 12),   # on the shoulders
              (flame_outline(4.1, 2.9, 2.8, 0.32, 0.55, 3), -0.35, 6)]    # at the elbows
    for s in (-1, 1):
        for pts, fx, yaw in pieces:
            yv = math.radians(yaw)
            o = Vector((X0 - fx, 0, S))
            ea = Vector((math.sin(yv), s * math.cos(yv), 0)).normalized()
            eb = Vector((0, 0, 1))
            en = ea.cross(eb).normalized() * (-s)
            flame(pts, (o, ea, eb, en), 0.12, "FGB", xf)
    # a row of jewels round the crown band
    for k in range(28):
        a = 2 * math.pi * k / 28
        if math.cos(a) < -0.2:
            continue
        r = 1.77
        jewel(HC + Vector((-math.cos(a) * r * 0.97, math.sin(a) * r, S + 10.23 - HC.z)), 0.08, "FLP" if k % 2 else "FSK", xf)
    return xf


# ================================================================================================ run
clear()
if WHICH == "chauk":
    chauk()
else:
    ngah()
tot = sum(len(v) for v in GROUPS.values())
json.dump({"groups": {g: v for g, v in GROUPS.items()}}, open(OUT, "w"))
print("FIGURE_DONE", WHICH, tot, {g: len(v) for g, v in GROUPS.items()})
