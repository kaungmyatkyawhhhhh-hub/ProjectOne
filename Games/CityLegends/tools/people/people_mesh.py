"""people_mesh.py (2026-11-27): low-poly realistic Yangon street people for client/YangonStreetLife.

Owner (27 Nov, vs a TorqX Racing reference): "the street people look like blocky Roblox figures". This builds the 8 body
pieces YangonStreetLife poses (same split as the old blocks: 1 shirt/blouse/robe, 2 head + neck + ears, 3 hair (two
kinds: short, bun), 4 longyi / htamein (tapered wrap skirt, closed hem), 5 / 6 arms with hands, 7 / 8 sandalled foot)
as one FBX, plus a 512 px texture atlas (face features and sandal straps on a transparent background, so the part's
Color shows through as skin): atlas_a plain, atlas_b with thanaka on the cheeks.

Authored in Roblox studs (3 a metre), feet on y = 0, facing -Z; written to Blender as (x, -z, y) and exported with
axis_forward -Z / axis_up Y (as tools/lamps/lamp_fbx.py). Each object is centred on its own bounding box (a MeshPart's
pivot), and people.json lists every piece's centre and size in figure space plus the joints, for the Lua tables.

    blender -b --factory-startup --python tools/people/people_mesh.py -- [render]
"""
import json
import math
import os
import sys

import bpy
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(ROOT, "imports", "people")
os.makedirs(OUT, exist_ok=True)
RENDER = "render" in sys.argv

NECK = (0.0, 4.40, 0.0)
SHOULDER = (0.54, 4.15, 0.0)  # left arm at -x
WAIST = (0.0, 3.0, 0.0)
HEAD_C = (0.0, 4.83, 0.02)
HEAD_R = (0.25, 0.35, 0.30)

# atlas regions (Blender UV, v up)
FACE_BOX = (-0.30, 0.30, 4.40, 5.20)   # head x, y -> u 0..0.5, v 0.5..1
FOOT_BOX = (-0.20, 0.20, -0.50, 0.35)  # foot x, z -> u 0..0.5, v 0..0.5
UV_CLEAR = (0.75, 0.75)                # transparent texel block
UV_SOLE = (0.75, 0.25)                 # solid sole colour block


# ------------------------------------------------------------------ geometry helpers
def ring(y, rx, rzf, rzb=None, n=12, p=2.0, cx=0.0, cz=0.0):
    rzb = rzf if rzb is None else rzb
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        c, s = math.cos(t), math.sin(t)
        x = rx * math.copysign(abs(c) ** (2 / p), c)
        z = (rzf if s < 0 else rzb) * math.copysign(abs(s) ** (2 / p), s)
        pts.append((cx + x, y, cz + z))
    return pts


class Mesh:
    def __init__(self):
        self.v, self.f = [], []

    def add_v(self, pts):
        i0 = len(self.v)
        self.v += [tuple(p) for p in pts]
        return list(range(i0, i0 + len(pts)))

    def loft(self, rings, cap_top=False, cap_bottom=False):
        """rings: list of vertex lists, all the same length, ordered (any direction); quads between them."""
        idx = [self.add_v(r) for r in rings]
        n = len(rings[0])
        for a, b in zip(idx, idx[1:]):
            for i in range(n):
                j = (i + 1) % n
                self.f.append((a[i], a[j], b[j], b[i]))
        if cap_bottom:
            self.cap(idx[0])
        if cap_top:
            self.cap(idx[-1])
        return idx

    def cap(self, ids):
        c = [sum(self.v[i][k] for i in ids) / len(ids) for k in range(3)]
        ci = self.add_v([c])[0]
        n = len(ids)
        for i in range(n):
            self.f.append((ids[i], ids[(i + 1) % n], ci))

    def ellipsoid(self, c, r, nu=8, nv=6):
        rings = []
        for k in range(1, nv):
            ph = -math.pi / 2 + math.pi * k / nv
            rings.append([(c[0] + r[0] * math.cos(ph) * math.cos(2 * math.pi * i / nu), c[1] + r[1] * math.sin(ph),
                           c[2] + r[2] * math.cos(ph) * math.sin(2 * math.pi * i / nu)) for i in range(nu)])
        idx = self.loft(rings)
        bot = self.add_v([(c[0], c[1] - r[1], c[2])])[0]
        top = self.add_v([(c[0], c[1] + r[1], c[2])])[0]
        for i in range(nu):
            j = (i + 1) % nu
            self.f.append((idx[0][j], idx[0][i], bot))
            self.f.append((idx[-1][i], idx[-1][j], top))

    def tris(self):
        return sum(len(f) - 2 for f in self.f)


# ------------------------------------------------------------------ pieces
def torso():
    m = Mesh()
    P = 2.4
    rings = [
        ring(2.62, 0.57, 0.40, 0.39, p=P), ring(2.95, 0.52, 0.36, 0.35, p=P), ring(3.30, 0.46, 0.33, 0.31, p=P),
        ring(3.65, 0.47, 0.36, 0.31, p=P), ring(3.95, 0.48, 0.33, 0.30, p=P), ring(4.12, 0.46, 0.27, 0.27, p=P + 0.6),
        ring(4.28, 0.34, 0.24, 0.25, p=P), ring(4.37, 0.24, 0.22, 0.26), ring(4.42, 0.23, 0.21, 0.26),  # collar clear of the neck (0.05+)
    ]
    m.loft(rings, cap_top=True)
    # short sleeves round the arms (open at the cuff)
    for sx in (-1, 1):
        sl = []
        for y, x, r in ((4.10, 0.42, 0.13), (4.07, 0.51, 0.18), (3.95, 0.56, 0.205), (3.76, 0.575, 0.205), (3.70, 0.57, 0.185)):
            sl.append(ring(y, r, r, n=8, cx=sx * x))
        m.loft(sl, cap_bottom=True)  # top inside the shoulder; the cuff turns in onto the arm
    return m


def skull_point(ph, th, scale=1.0):
    """deformed head surface at latitude ph, azimuth th (th = -pi/2 is the front, -z)"""
    rx, ry, rz = HEAD_R
    x = rx * math.cos(ph) * math.cos(th)
    y = ry * math.sin(ph)
    z = rz * math.cos(ph) * math.sin(th)
    s = math.sin(ph)
    if s < 0:  # jaw and the back of the neck taper
        x *= 1 - 0.30 * (-s)
        z *= (1 - 0.12 * (-s)) if z < 0 else (1 - 0.38 * (-s))
    front = math.exp(-((th + math.pi / 2) / 0.22) ** 2)
    z -= 0.075 * front * math.exp(-((y + 0.07) / 0.07) ** 2)  # nose
    z -= 0.022 * math.exp(-((th + math.pi / 2) / 0.6) ** 2) * math.exp(-((y - 0.07) / 0.05) ** 2)  # brow
    z -= 0.03 * math.exp(-((th + math.pi / 2) / 0.35) ** 2) * math.exp(-((y + 0.29) / 0.05) ** 2)  # chin
    if -0.12 < y < 0.12:
        x *= 0.96
    return (HEAD_C[0] + x * scale, HEAD_C[1] + y * scale, HEAD_C[2] + z * scale)


def head():
    m = Mesh()
    nu, nv = 16, 12
    rings = []
    for k in range(1, nv):
        ph = -math.pi / 2 + math.pi * k / nv
        rings.append([skull_point(ph, 2 * math.pi * i / nu) for i in range(nu)])
    idx = m.loft(rings)
    bot = m.add_v([skull_point(-math.pi / 2 + 1e-4, 0)])[0]
    top = m.add_v([skull_point(math.pi / 2 - 1e-4, 0)])[0]
    for i in range(nu):
        j = (i + 1) % nu
        m.f.append((idx[0][j], idx[0][i], bot))
        m.f.append((idx[-1][i], idx[-1][j], top))
    # neck (into the collar below, the skull above)
    m.loft([ring(4.26, 0.16, 0.15, 0.17, n=8, cz=0.03), ring(HEAD_C[1] - 0.21, 0.15, 0.14, 0.15, n=8, cz=0.04)])
    # ears
    for sx in (-1, 1):
        m.ellipsoid((sx * 0.245, HEAD_C[1] - 0.04, 0.05), (0.04, 0.075, 0.06), nu=6, nv=4)
    return m


def hairline(th):
    s = math.sin(th)
    return 0.32 + 0.28 * (-s) if s < 0 else 0.32 - 0.86 * s  # (sides clear of the ears)


def hair(bun):
    m = Mesh()
    nu, nv = 16, 6
    rings = []
    for k in range(nv + 1):
        row = []
        for i in range(nu):
            th = 2 * math.pi * i / nu
            lo = hairline(th) - (0.18 * math.sin(th) ** 3 if bun and math.sin(th) > 0 else 0.0)  # (lower at the nape only, clear of the ears)
            t = k / (nv + 0.6)
            ph = lo + (math.pi / 2 - lo) * t
            sc = 1.25 + 0.03 * math.sin(math.pi * min(1, t * 1.6)) + 0.02 * t  # >= 0.05 off the skull: no flicker
            row.append(skull_point(ph, th, sc))
        rings.append(row)
    idx = m.loft(rings)
    m.cap(idx[-1])
    if bun:
        m.ellipsoid((0.0, HEAD_C[1] + 0.05, HEAD_C[2] + 0.36), (0.13, 0.12, 0.10), nu=8, nv=6)
    return m


def longyi():
    m = Mesh()
    P = 2.2
    rings = [
        ring(0.22, 0.44, 0.33, 0.33, p=P), ring(0.60, 0.45, 0.34, 0.34, p=P), ring(1.20, 0.47, 0.35, 0.35, p=P),
        ring(1.80, 0.48, 0.36, 0.36, p=P), ring(2.30, 0.49, 0.36, 0.36, p=P), ring(2.62, 0.48, 0.34, 0.33, p=P),
        ring(2.90, 0.45, 0.31, 0.30, p=P), ring(3.15, 0.40, 0.28, 0.27, p=P),
    ]
    m.loft(rings, cap_bottom=True)
    return m


ARM = [  # (y, x out, z, r thickness (x), r width (z)) from the shoulder pivot, left arm (x out = -x)
    (-0.12, 0.00, 0.00, 0.09, 0.09), (-0.18, 0.01, 0.00, 0.145, 0.145), (-0.30, 0.03, 0.00, 0.14, 0.14),
    (-0.65, 0.05, 0.00, 0.125, 0.125), (-0.95, 0.065, -0.01, 0.11, 0.11), (-1.10, 0.07, -0.03, 0.115, 0.115),
    (-1.40, 0.075, -0.07, 0.115, 0.12), (-1.70, 0.08, -0.10, 0.085, 0.095), (-1.80, 0.085, -0.11, 0.055, 0.12),
    (-1.98, 0.09, -0.11, 0.06, 0.135), (-2.10, 0.09, -0.11, 0.05, 0.12), (-2.19, 0.085, -0.10, 0.035, 0.07),
]


def arm(side):
    m = Mesh()
    rings = []
    for y, xo, z, rx, rz in ARM:
        cx = side * (SHOULDER[0] + xo)
        rings.append(ring(SHOULDER[1] + y, rx, rz, n=6, cx=cx, cz=z))
    m.loft(rings, cap_top=True, cap_bottom=True)
    return m


def foot():
    m = Mesh()
    rings = []
    for z, w, h in ((0.30, 0.10, 0.17), (0.17, 0.13, 0.21), (0.02, 0.14, 0.22), (-0.18, 0.15, 0.14),
                    (-0.36, 0.13, 0.09), (-0.45, 0.08, 0.06)):
        rings.append([(-w, 0.0, z), (-w, 0.05, z), (-w * 0.85, h * 0.6, z), (0.0, h, z), (w * 0.85, h * 0.6, z),
                      (w, 0.05, z), (w, 0.0, z), (0.0, 0.0, z)])
    m.loft(rings, cap_top=True, cap_bottom=True)
    m.loft([ring(0.14, 0.085, 0.09, n=6, cz=0.15), ring(0.50, 0.08, 0.08, n=6, cz=0.13)])  # ankle (under the hem)
    return m


# ------------------------------------------------------------------ uv rules
def uv_head(c):
    if c[2] - HEAD_C[2] < -0.05 and c[1] > 4.5:
        x0, x1, y0, y1 = FACE_BOX
        return None, lambda p: (0.5 * (p[0] - x0) / (x1 - x0), 0.5 + 0.5 * (p[1] - y0) / (y1 - y0))
    return UV_CLEAR, None


def uv_foot(c):
    if c[1] < 0.055:
        return UV_SOLE, None
    x0, x1, z0, z1 = FOOT_BOX
    return None, lambda p: (0.5 * (p[0] - x0) / (x1 - x0), 0.5 * (p[2] - z0) / (z1 - z0))


def uv_clear(c):
    return UV_CLEAR, None


# ------------------------------------------------------------------ atlas
def atlas(thanaka):
    S = 512
    vv, uu = np.mgrid[0:S, 0:S]
    u = (uu + 0.5) / S
    v = (vv + 0.5) / S
    x0, x1, y0, y1 = FACE_BOX
    hx = x0 + (u / 0.5) * (x1 - x0)
    hy = y0 + ((v - 0.5) / 0.5) * (y1 - y0)
    fx0, fx1, fz0, fz1 = FOOT_BOX
    img = features(hx, hy, v >= 0.5, fx0 + (u / 0.5) * (fx1 - fx0), fz0 + (v / 0.5) * (fz1 - fz0), (u < 0.5) & (v < 0.5),
                   thanaka)
    sole = ((u >= 0.5) & (v < 0.5)).astype(np.float32)[..., None]
    img[:] = img * (1 - sole) + np.array([0.16, 0.12, 0.10, 1.0], np.float32) * sole
    return img


def decal_face(info, thanaka):
    """(27 Nov, Studio: a MeshPart's TextureID ignores alpha, the head came out black) the face as a Decal on the
    head's Front: the picture spans the head's box, top row = top of the head"""
    c, sz = info["parts"]["Head"]["centre"], info["parts"]["Head"]["size"]
    W, H = 256, int(256 * sz[1] / sz[0])
    vv, uu = np.mgrid[0:H, 0:W]
    hx = c[0] - sz[0] / 2 + (uu + 0.5) / W * sz[0]
    hy = c[1] - sz[1] / 2 + (vv + 0.5) / H * sz[1]  # rows bottom-up
    none = np.zeros((H, W), bool)
    return features(hx, hy, np.ones((H, W), bool), hx, hy, none, thanaka)


def decal_sandal(info):
    """the flip-flop strap as a Decal on the foot's Top: x across, the picture's top row at the toes (-z)"""
    c, sz = info["parts"]["Foot"]["centre"], info["parts"]["Foot"]["size"]
    W, H = 128, int(128 * sz[2] / sz[0])
    vv, uu = np.mgrid[0:H, 0:W]
    fx = c[0] - sz[0] / 2 + (uu + 0.5) / W * sz[0]
    fz = c[2] + sz[2] / 2 - (vv + 0.5) / H * sz[2]  # rows bottom-up: bottom row = heel (+z)
    none = np.zeros((H, W), bool)
    return features(fx, fx, none, fx, fz, np.ones((H, W), bool), False)


def features(hx, hy, face, fx, fz, foot, thanaka):
    """face features over head coordinates (hx, hy; where face), sandal straps over foot coordinates (fx, fz; where foot)"""
    img = np.zeros(hx.shape + (4,), np.float32)  # rows bottom-up (v), rgb 0..1, a
    img[..., :3] = (0.76, 0.6, 0.46)  # a mid skin under the clear pixels, so soft edges fade to skin, not black
    hy = hy + (4.88 - HEAD_C[1])  # features drawn for a head centred at 4.88

    def paint(mask_a, rgb):
        a = np.clip(mask_a, 0, 1)[..., None]
        col = np.array(list(rgb) + [1.0], np.float32)
        img[:] = img * (1 - a) + col * a

    def ell(cx, cy, rx, ry, soft=0.25):
        d = np.sqrt(((hx - cx) / rx) ** 2 + ((hy - cy) / ry) ** 2)
        return np.clip((1 - d) / soft, 0, 1) * face

    for sx in (-1, 1):
        if thanaka:
            paint(0.80 * ell(sx * 0.135, 4.80, 0.06, 0.05, soft=0.8), (0.97, 0.91, 0.72))
        # eye socket shade, white, iris, upper lid, brow
        paint(0.18 * ell(sx * 0.085, 4.885, 0.06, 0.03, soft=0.9), (0.25, 0.15, 0.10))
        paint(0.75 * ell(sx * 0.085, 4.885, 0.040, 0.016), (0.92, 0.90, 0.86))
        paint(1.00 * ell(sx * 0.083, 4.884, 0.017, 0.017, soft=0.4), (0.13, 0.08, 0.05))
        lid = ell(sx * 0.085, 4.893, 0.044, 0.008, soft=0.5)
        paint(0.85 * lid, (0.08, 0.06, 0.05))
        brow = ell(sx * 0.092, 4.945 - 0.15 * (hx * sx - 0.092) ** 2, 0.055, 0.011, soft=0.6)
        paint(0.85 * brow, (0.09, 0.07, 0.06))
        paint(0.35 * ell(sx * 0.028, 4.795, 0.016, 0.009, soft=0.6), (0.20, 0.10, 0.07))  # nostril
    paint(0.55 * ell(0.0, 4.712, 0.055, 0.017, soft=0.6), (0.55, 0.28, 0.24))  # lips
    paint(0.55 * ell(0.0, 4.714, 0.050, 0.004, soft=0.6), (0.22, 0.10, 0.08))  # mouth line
    # sandals: strap V on the top of the foot
    for sx in (-1, 1):
        # line from the toe post (x 0.02, z -0.33) back to the side (x 0.14 sx, z -0.05)
        ax, az, bx, bz = 0.02, -0.33, 0.145 * sx, -0.04
        t = np.clip(((fx - ax) * (bx - ax) + (fz - az) * (bz - az)) / ((bx - ax) ** 2 + (bz - az) ** 2), 0, 1)
        d = np.sqrt((fx - (ax + t * (bx - ax))) ** 2 + (fz - (az + t * (bz - az))) ** 2)
        paint(np.clip((0.022 - d) / 0.008, 0, 1) * foot, (0.12, 0.10, 0.09))
    return img


def save_png(arr, path, name):
    im = bpy.data.images.new(name, arr.shape[1], arr.shape[0], alpha=True)
    im.pixels.foreach_set(arr.reshape(-1))
    im.filepath_raw = path
    im.file_format = "PNG"
    im.save()
    return im


# ------------------------------------------------------------------ build
PIECES = [  # (name, part number, builder, uv rule)
    ("Torso", 1, torso, uv_clear), ("Head", 2, head, uv_head), ("HairShort", 3, lambda: hair(False), uv_clear),
    ("HairBun", 3, lambda: hair(True), uv_clear), ("Longyi", 4, longyi, uv_clear),
    ("ArmL", 5, lambda: arm(-1), uv_clear), ("ArmR", 6, lambda: arm(1), uv_clear), ("Foot", 7, foot, uv_foot),
]


def to_blender(p):
    return (p[0], -p[2], p[1])


def make_object(name, m, rule, centre):
    me = bpy.data.meshes.new(name)
    # (27 Nov) Roblox's FBX import turns each mesh 180 degrees about y (Studio: the hair's nape edge came in at the
    # front), so the export is turned first: x and z negated (a turn, not a mirror, so the faces keep their winding)
    me.from_pydata([to_blender((-(p[0] - centre[0]), p[1] - centre[1], -(p[2] - centre[2]))) for p in m.v], [], m.f)
    me.update()
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.faces.index_update()
    # (27 Nov) recalc can leave an open shell (the hair cap) facing in; Roblox culls back faces, so each loose piece
    # must face out: flip any whose faces point at its own middle
    seen = set()
    for f0 in bm.faces:
        if f0.index in seen:
            continue
        island, stack = [], [f0]
        seen.add(f0.index)
        while stack:
            f = stack.pop()
            island.append(f)
            for e in f.edges:
                for g in e.link_faces:
                    if g.index not in seen:
                        seen.add(g.index)
                        stack.append(g)
        vs = list({v for f in island for v in f.verts})
        c = vs[0].co.copy() * 0
        for v in vs:
            c += v.co
        c /= len(vs)
        vol = sum((f.calc_center_median() - c).dot(f.normal) * f.calc_area() for f in island)
        if vol < 0:
            bmesh.ops.reverse_faces(bm, faces=island)
            print("  flipped a piece of", name, len(island), "faces")
    bm.to_mesh(me)
    bm.free()
    uvl = me.uv_layers.new(name="UVMap")
    for poly in me.polygons:
        c = [sum(m.v[me.loops[li].vertex_index][k] for li in poly.loop_indices) / poly.loop_total for k in range(3)]
        fixed, fn = rule(c)
        for li in poly.loop_indices:
            uvl.data[li].uv = fixed if fixed else fn(m.v[me.loops[li].vertex_index])
    me.polygons.foreach_set("use_smooth", [True] * len(me.polygons))
    me.update()
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    return ob


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    info = {"joints": {"neck": NECK, "shoulder": SHOULDER, "waist": WAIST}, "parts": {}}
    objs, total = [], 0
    for name, num, build, rule in PIECES:
        m = build()
        xs, ys, zs = zip(*m.v)
        lo, hi = (min(xs), min(ys), min(zs)), (max(xs), max(ys), max(zs))
        c = tuple((a + b) / 2 for a, b in zip(lo, hi))
        info["parts"][name] = {"part": num, "centre": [round(v, 4) for v in c],
                               "size": [round(b - a, 4) for a, b in zip(lo, hi)], "tris": m.tris()}
        total += m.tris() if name != "HairBun" else 0
        objs.append(make_object(name, m, rule, c))
        print(name, "tris", m.tris(), "size", info["parts"][name]["size"])
    info["tris_per_person"] = total + info["parts"]["Foot"]["tris"]  # two feet, one hair
    print("TRIS PER PERSON", info["tris_per_person"])
    for ob in objs:
        ob.select_set(True)
    fbx = os.path.join(OUT, "people.fbx")
    bpy.ops.export_scene.fbx(filepath=fbx, use_selection=True, object_types={"MESH"}, global_scale=1.0,
                             apply_unit_scale=True, bake_space_transform=False, add_leaf_bones=False, bake_anim=False,
                             axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", use_mesh_modifiers=False)
    for nm, th in (("atlas_a", False), ("atlas_b", True)):
        save_png(atlas(th), os.path.join(OUT, nm + ".png"), nm)
    for nm, th in (("face_a", False), ("face_b", True)):
        save_png(decal_face(info, th), os.path.join(OUT, nm + ".png"), nm)
    save_png(decal_sandal(info), os.path.join(OUT, "sandal.png"), "sandal")
    with open(os.path.join(OUT, "people.json"), "w") as fh:
        json.dump(info, fh, indent=1)
    print("WROTE", fbx)
    flicker_check(objs, info)
    if RENDER:
        import people_render
        people_render.render(info, OUT)


def flicker_check(objs, info):
    """owner's no-flicker rule: in the rest pose, faces of one piece closer than 0.05 studs to a near-parallel face of
    another (z-fighting) are counted for every pair that touch; prints FLICKER <a> <b> <n> (0 everywhere = pass)"""
    from mathutils import Matrix, Vector
    from mathutils.bvhtree import BVHTree
    P = info["parts"]
    place = {"Torso": P["Torso"]["centre"], "Head": P["Head"]["centre"], "HairShort": P["HairShort"]["centre"],
             "HairBun": P["HairBun"]["centre"], "Longyi": P["Longyi"]["centre"], "ArmL": P["ArmL"]["centre"],
             "ArmR": P["ArmR"]["centre"], "FootL": (-0.19, P["Foot"]["centre"][1], P["Foot"]["centre"][2]),
             "FootR": (0.19, P["Foot"]["centre"][1], P["Foot"]["centre"][2])}
    by = {o.name: o for o in objs}
    tris = {}
    for name, c in place.items():
        ob = by["Foot" if name.startswith("Foot") else name]
        M = Matrix.Translation(Vector(to_blender(c))) @ Matrix.Rotation(math.pi, 4, "Z")
        vs = [M @ v.co for v in ob.data.vertices]
        tris[name] = (vs, [tuple(p.vertices) for p in ob.data.polygons])
    worst = 0
    names = list(place)
    for i, a in enumerate(names):
        for b in names[i + 1:]:
            if {a, b} == {"HairShort", "HairBun"}:
                continue
            tb = BVHTree.FromPolygons(*tris[b])
            n = 0
            va, fa = tris[a]
            for f in fa:
                pts = [va[k] for k in f]
                cen = sum(pts, Vector()) / len(pts)
                nor = (pts[1] - pts[0]).cross(pts[2] - pts[0])
                if nor.length < 1e-9:
                    continue
                hit = tb.find_nearest(cen, 0.05)
                if hit[0] is not None and abs(nor.normalized().dot(hit[1])) > 0.9:
                    n += 1
                    if n <= 3:
                        print("   at", a, b, tuple(round(x, 2) for x in cen))
            if n:
                print("FLICKER", a, b, n)
                worst += n
    print("FLICKER TOTAL", worst)


if __name__ == "__main__":
    sys.path.insert(0, HERE)
    main()
