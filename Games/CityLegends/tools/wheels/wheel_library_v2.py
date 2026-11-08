"""Wheel kit v2 (2026-11-08, Prompts/A million times better wheels (new models).md, Part 1).

Our own rim designs (no real rim copied, no logos, blank caps), built properly: concave faces (deeper on the rear wheels),
spokes with real thickness and soft bevelled edges, a barrel behind them, lug nuts or a centre-lock nut, a centre cap,
a valve stem, a polished lip; brake discs with a hat, our own calipers, a dark backing plate; tyres with a real profile
in three sidewall heights. Baked ambient shade (AO) for the spokes, barrel and calipers; a blurred-disc mesh per design
for speed (no wagon-wheel strobe).

    blender -b --factory-startup --python tools/wheels/wheel_library_v2.py -- <out dir> [designs,comma,list|all] [nobake]

The rim frame: radius 1 (the lip's outer edge), X from -RX to +RX, +X = the outer face. Every mesh in the rim frame
(face, lip, barrel, nuts, cap, blur, disc, calipers, shield) holds tiny hidden slivers at the frame's corners, so all
of them have the same box: in Studio each one gets the same CFrame and Size. Tyres have their own frame: radius 1,
X from -0.5 to 0.5, the bead at radius K (the rim's size inside the tyre is K x the tyre's).

Writes <out>/wheels2.fbx, <out>/tex/*.png (AO, blur), <out>/preview/*.png and <out>/kit.json.
"""

import json
import math
import os
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1 :]
OUT = os.path.abspath(argv[0])
ONLY = argv[1] if len(argv) > 1 else "all"
NOBAKE = len(argv) > 2 and argv[2] == "nobake"
TEX = os.path.join(OUT, "tex")
PRE = os.path.join(OUT, "preview")
for d in (OUT, TEX, PRE):
    os.makedirs(d, exist_ok=True)

SEG = 96
RX = 0.48  # half the rim's width
RIM_FRONT = RX - 0.035  # where the spokes meet the lip
HUB_R = 0.27
DISC_R = 0.74
RING_X = -0.10  # the disc's friction ring (middle)
HAT_X = 0.10  # the disc hat's face (the hub sits on it)
TYRE_K = {"66": 0.66, "71": 0.71, "75": 0.75}

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)


# ------------------------------------------------------------------ helpers
def ease(a, b, e=1.0):
    return lambda t: a + (b - a) * (t ** e)


def lathe(bm, profile, seg=SEG, uvl=None, vs=None, uscale=1.0, close=True):
    """turn a profile [(x, r)] round the X axis. vs: a V per profile point (UV U = angle share x uscale)"""
    rings = []
    for x, r in profile:
        ring = []
        for i in range(seg):
            a = i / seg * math.tau
            ring.append(bm.verts.new((x, r * math.cos(a), r * math.sin(a))))
        rings.append(ring)
    faces = []
    for k in range(len(rings) - 1):
        a, b = rings[k], rings[k + 1]
        for i in range(seg):
            j = (i + 1) % seg
            f = bm.faces.new((a[i], a[j], b[j], b[i]))
            faces.append(f)
            if uvl is not None and vs is not None:
                u0, u1 = i / seg * uscale, (i + 1) / seg * uscale
                for loop, uv in zip(f.loops, ((u0, vs[k]), (u1, vs[k]), (u1, vs[k + 1]), (u0, vs[k + 1]))):
                    loop[uvl].uv = uv
    return faces


def slivers(bm):
    """tiny hidden triangles at the frame's corners (inside the tyre's bead and inside the lip), so every rim-frame mesh
    has the box X -RX..RX, Y and Z -1..1"""
    pts = []
    for ang in (0, 90, 180, 270):
        a = math.radians(ang)
        c, s = math.cos(a), math.sin(a)
        pts.append([(-RX, c * 1.0, s * 1.0), (-RX + 0.01, c * 0.99, s * 0.99), (-RX + 0.01, c * 0.99 - s * 0.004, s * 0.99 + c * 0.004)])
    a = math.radians(45)
    c, s = math.cos(a), math.sin(a)
    pts.append([(RX, c * 0.97, s * 0.97), (RX - 0.012, c * 0.968, s * 0.968), (RX - 0.012, c * 0.972 - s * 0.003, s * 0.972 + c * 0.003)])
    for tri in pts:
        bm.faces.new([bm.verts.new(p) for p in tri])


def spoke(bm, ang, r0, r1, w0, w1, front, thick, steps=12, twist=0.0, side=0.0, side_to=None, cham=1.0):
    """a bar from the hub to the rim with soft chamfered front edges. front(t), thick(t): X of its front face and its
    depth along it (t = 0 at the hub, 1 at the rim)"""
    side_to = side if side_to is None else side_to
    rings = []
    for k in range(steps + 1):
        t = k / steps
        r = r0 + (r1 - r0) * t
        w = w0 + (w1 - w0) * t
        a = ang + twist * t
        s = side + (side_to - side) * t
        dy, dz = math.cos(a), math.sin(a)
        py, pz = -dz, dy
        xf = front(t)
        th = thick(t) if callable(thick) else thick
        c = min(w * 0.24, th * 0.45) * cham
        xb = xf - th
        sec = ((-w / 2, xb), (w / 2, xb), (w / 2, xf - c), (w / 2 - c * 0.85, xf), (-w / 2 + c * 0.85, xf), (-w / 2, xf - c))
        rings.append([bm.verts.new((x, dy * r + py * (s + off), dz * r + pz * (s + off))) for off, x in sec])
    n = 6
    for k in range(steps):
        a, b = rings[k], rings[k + 1]
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((a[i], a[j], b[j], b[i]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])


def hub_body(bm, hx, r=HUB_R):
    """the hub: a short drum from the disc hat to the face, its front gently domed, a recess for the cap"""
    lathe(
        bm,
        [
            (HAT_X - 0.01, r * 0.98),
            (hx - 0.05, r),
            (hx - 0.012, r + 0.004),
            (hx, r - 0.02),
            (hx + 0.006, r * 0.62),
            (hx + 0.004, 0.125),
            (hx - 0.03, 0.118),
            (hx - 0.03, 0.001),
        ],
        seg=64,
    )


def rim_ring(bm):
    """where the spokes run into the rim: a short ring just inside the lip (part of the face, same paint)"""
    lathe(bm, [(RIM_FRONT - 0.09, 0.9), (RIM_FRONT - 0.02, 0.905), (RIM_FRONT + 0.005, 0.925), (RIM_FRONT + 0.02, 0.936)], seg=SEG)


# ------------------------------------------------------------------ designs: each builds its face, returns its hub X and the
# front-surface curve x(r) for the blur disc
def bowl(depth, e_front=1.25, e_deep=1.6):
    hx = 0.27 - 0.13 * depth
    e = e_front + (e_deep - e_front) * depth
    return hx, e


def furia(bm, depth):
    """twin spokes, seven pairs"""
    hx, e = bowl(depth)
    f = ease(hx + 0.02, RIM_FRONT, e)
    for i in range(7):
        a = i / 7 * math.tau
        for sd in (1, -1):
            spoke(bm, a, HUB_R - 0.03, 0.915, 0.095, 0.07, f, lambda t: 0.09 - 0.03 * t, side=0.04 * sd, side_to=0.115 * sd)
    hub_body(bm, hx)
    return hx, f, (7, 5)


def saetta(bm, depth):
    """five Y spokes"""
    hx, e = bowl(depth)
    f = ease(hx + 0.02, RIM_FRONT, e)
    for i in range(5):
        a = i / 5 * math.tau
        spoke(bm, a, HUB_R - 0.03, 0.62, 0.26, 0.17, lambda t: f(t * 0.55), lambda t: 0.11 - 0.02 * t, steps=8)
        for sd in (1, -1):
            spoke(bm, a, 0.56, 0.915, 0.11, 0.105, lambda t: f(0.5 + t * 0.5), lambda t: 0.09 - 0.025 * t, steps=8, side=0.04 * sd, side_to=0.21 * sd)
    hub_body(bm, hx)
    return hx, f, (5, 5)


def corsa(bm, depth):
    """ten forged spokes with a raised spine"""
    hx, e = bowl(depth)
    f = ease(hx + 0.02, RIM_FRONT, e)
    for i in range(10):
        a = i / 10 * math.tau
        spoke(bm, a, HUB_R - 0.03, 0.915, 0.16, 0.105, f, lambda t: 0.1 - 0.03 * t)
        spoke(bm, a, 0.33, 0.87, 0.04, 0.03, lambda t: f(0.06 + t * 0.9) + 0.012, 0.03, steps=10, cham=1.4)
    hub_body(bm, hx)
    return hx, f, (10, 5)


def centro(bm, depth):
    """track wheel: six wide spokes, a slim one between each, one centre-lock nut"""
    hx, e = bowl(depth)
    f = ease(hx + 0.02, RIM_FRONT, e)
    for i in range(6):
        a = i / 6 * math.tau
        spoke(bm, a, HUB_R - 0.05, 0.915, 0.3, 0.2, f, lambda t: 0.11 - 0.035 * t)
        spoke(bm, a + math.pi / 6, 0.5, 0.915, 0.035, 0.11, lambda t: f(0.4 + 0.6 * t), 0.07, steps=8)
    hub_body(bm, hx)
    return hx, f, (6, 0)


def turbine(bm, depth):
    """aero: fourteen swept blades"""
    hx, e = bowl(depth, 1.1, 1.35)
    f = ease(hx + 0.02, RIM_FRONT, e)
    for i in range(14):
        a = i / 14 * math.tau
        spoke(bm, a, HUB_R - 0.03, 0.915, 0.12, 0.27, f, lambda t: 0.07 - 0.015 * t, steps=14, twist=0.62)
    hub_body(bm, hx)
    return hx, f, (14, 5)


def trio(bm, depth):
    """six split spokes (the big cars)"""
    hx, e = bowl(depth)
    f = ease(hx + 0.02, RIM_FRONT, e)
    for i in range(6):
        a = i / 6 * math.tau
        for sd in (1, -1):
            spoke(bm, a, HUB_R - 0.03, 0.915, 0.14, 0.12, f, lambda t: 0.1 - 0.03 * t, side=0.07 * sd, side_to=0.145 * sd)
    hub_body(bm, hx, r=0.29)
    return hx, f, (6, 6)


def royale(bm, depth):
    """twenty slim spokes with a little twist (the long limousines)"""
    hx, e = bowl(depth, 1.15, 1.4)
    f = ease(hx + 0.02, RIM_FRONT, e)
    for i in range(20):
        a = i / 20 * math.tau
        spoke(bm, a, HUB_R - 0.03, 0.915, 0.06, 0.05, f, 0.065, steps=10, twist=0.22, cham=1.2)
    hub_body(bm, hx)
    return hx, f, (20, 5)


def disco_dish(bm, depth):
    """the dished face on its own (a closed solid, so the hole cutting works)"""
    hx, e = bowl(depth, 1.0, 1.2)
    f = ease(hx + 0.02, RIM_FRONT, e)
    prof_f = [(f(t), HUB_R - 0.02 + (0.915 - HUB_R + 0.02) * t) for t in [k / 16 for k in range(17)]]
    prof_b = [(x - 0.07, r) for x, r in reversed(prof_f)]
    lathe(bm, prof_f + prof_b + [prof_f[0]], seg=SEG)


def disco(bm, depth):
    """the eighties: a dished face with five round holes (the dish is made apart and joined in, see below)"""
    hx, e = bowl(depth, 1.0, 1.2)
    f = ease(hx + 0.02, RIM_FRONT, e)
    hub_body(bm, hx)
    return hx, f, (5, 5)


DESIGNS = {
    "Furia7": furia,
    "SaettaY5": saetta,
    "Corsa10": corsa,
    "Centro6": centro,
    "Turbine14": turbine,
    "Trio6": trio,
    "Royale20": royale,
    "Disco5": disco,
}
if ONLY != "all":
    DESIGNS = {k: v for k, v in DESIGNS.items() if k in ONLY.split(",")}


def nuts(bm, hx, lugs, centre_lock):
    if centre_lock:
        lathe(bm, [(hx - 0.02, 0.13), (hx + 0.045, 0.13), (hx + 0.06, 0.112), (hx + 0.06, 0.06), (hx + 0.075, 0.05), (hx + 0.075, 0.001)], seg=6)
        # the safety pin across the nut
        lathe(bm, [(hx + 0.07, 0.012), (hx + 0.09, 0.012), (hx + 0.09, 0.001)], seg=10)
    else:
        for i in range(lugs):
            a = i / lugs * math.tau + math.pi / lugs
            y, z = 0.19 * math.cos(a), 0.19 * math.sin(a)
            sub = bmesh.new()
            # hex body, then a rounded cone tip
            lathe(sub, [(hx - 0.01, 0.034), (hx + 0.03, 0.034), (hx + 0.04, 0.026), (hx + 0.045, 0.012), (hx + 0.047, 0.001)], seg=6)
            for v in sub.verts:
                v.co = Vector((v.co.x, v.co.y + y, v.co.z + z))
            me = bpy.data.meshes.new("tmp")
            sub.to_mesh(me)
            sub.free()
            bm.from_mesh(me)
            bpy.data.meshes.remove(me)


def valve(bm, n_spokes):
    """the valve stem: out of the barrel just behind the lip, between two spokes, leaning out"""
    a = math.pi / max(n_spokes, 1)
    base = Vector((RIM_FRONT - 0.07, 0.885 * math.cos(a), 0.885 * math.sin(a)))
    d = Vector((0.75, -0.66 * math.cos(a), -0.66 * math.sin(a))).normalized()
    sub = bmesh.new()
    lathe(sub, [(0.0, 0.0125), (0.035, 0.0125), (0.037, 0.016), (0.06, 0.016), (0.062, 0.001)], seg=10)
    # point the stem along d
    rot = Vector((1, 0, 0)).rotation_difference(d)
    for v in sub.verts:
        v.co = base + rot @ v.co
    me = bpy.data.meshes.new("tmp")
    sub.to_mesh(me)
    sub.free()
    bm.from_mesh(me)
    bpy.data.meshes.remove(me)


def cap(bm, hx):
    """the centre cap: domed, blank, a thin ring cut round it"""
    lathe(bm, [(hx - 0.03, 0.112), (hx + 0.006, 0.112), (hx + 0.012, 0.104), (hx + 0.014, 0.09), (hx + 0.013, 0.086), (hx + 0.017, 0.08), (hx + 0.022, 0.04), (hx + 0.023, 0.001)], seg=48)


LIP = [(RX - 0.03, 0.928), (RX - 0.004, 0.935), (RX, 0.945), (RX, 0.985), (RX - 0.006, 0.998), (RX - 0.02, 1.0), (RX - 0.06, 0.99), (RX - 0.07, 0.96)]
BARREL = [
    (RX - 0.03, 0.927),
    (0.32, 0.918),
    (0.12, 0.905),
    (-0.04, 0.9),
    (-0.2, 0.885),
    (-0.25, 0.815),
    (-0.36, 0.81),
    (-0.4, 0.88),
    (-RX + 0.04, 0.925),
    (-RX + 0.005, 0.94),
    (-RX, 0.97),
    (-RX + 0.02, 1.0),
]


def disc_mesh(bm, uvl):
    t = 0.035
    prof = [
        (HAT_X, 0.001),
        (HAT_X, DISC_R * 0.36),
        (HAT_X - 0.01, DISC_R * 0.4),
        (RING_X + t, DISC_R * 0.42),
        (RING_X + t, DISC_R * 0.995),
        (RING_X + t - 0.004, DISC_R),
        (RING_X - t + 0.004, DISC_R),
        (RING_X - t, DISC_R * 0.995),
        (RING_X - t, DISC_R * 0.42),
        (HAT_X - 0.04, DISC_R * 0.39),
        (HAT_X - 0.03, 0.001),
    ]
    faces = lathe(bm, prof, seg=72)
    for f in faces:
        for loop in f.loops:
            co = loop.vert.co
            loop[uvl].uv = (0.5 + co.y / (2 * DISC_R), 0.5 + co.z / (2 * DISC_R))


def caliper(bm, sign):
    """our caliper: a U round the disc's edge, swept along an arc, rounded ends. sign: +1 = towards +Y, -1 = -Y; it
    sits 25 degrees above level"""
    centre = math.radians(25)
    span = math.radians(30)
    sec = [(0.125, 0.53), (0.125, 0.752), (0.105, 0.782), (-0.185, 0.782), (-0.205, 0.762), (-0.205, 0.56), (-0.15, 0.56), (-0.15, 0.748), (-0.05, 0.748), (-0.05, 0.53)]
    steps = 18
    rings = []
    for k in range(steps + 1):
        t = k / steps * 2 - 1  # -1..1 along the arc
        a = centre + t * span
        # rounded ends: the section shrinks towards its own middle near the ends
        endk = math.sqrt(max(0.0, 1 - t ** 8))
        mx, mr = -0.04, 0.66
        ring = []
        for x, r in sec:
            xx = mx + (x - mx) * (0.55 + 0.45 * endk)
            rr = mr + (r - mr) * (0.55 + 0.45 * endk)
            y, z = rr * math.cos(a) * sign, rr * math.sin(a)
            ring.append(bm.verts.new((xx, y, z)))
        rings.append(ring)
    n = len(sec)
    for k in range(steps):
        a, b = rings[k], rings[k + 1]
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((a[i], a[j], b[j], b[i]) if sign > 0 else (b[i], b[j], a[j], a[i]))
    bm.faces.new(rings[0] if sign > 0 else list(reversed(rings[0])))
    bm.faces.new(list(reversed(rings[-1])) if sign > 0 else rings[-1])
    # two bleed nipples on the outer face's top end
    tip = rings[-1 if sign > 0 else 0]


def shield(bm):
    lathe(bm, [(-0.235, 0.001), (-0.235, 0.33), (-0.225, 0.62), (-0.205, 0.775), (-0.19, 0.785)], seg=72)


def tyre(bm, uvl, k):
    """radius 1, X -0.5..0.5, bead at radius k. V bands as in tools/wheels/wheel_textures.py"""
    h = 1 - k
    side = [(0.0, 0.42), (0.08, 0.465), (0.15, 0.458), (0.35, 0.49), (0.55, 0.5), (0.75, 0.487), (0.88, 0.452), (0.95, 0.41)]
    out = []
    vs = []
    out.append((0.4, k - 0.012))
    vs.append(0.0)
    for s, x in side:
        out.append((x, k + h * s))
        vs.append(0.30 * s / 0.95)
    for x, r, v in ((0.37, k + h * 0.985, 0.34), (0.33, 1.0 - h * 0.004, 0.38)):
        out.append((x, r))
        vs.append(v)
    crown = []
    for i in range(1, 6):
        x = 0.33 - 0.66 * i / 6
        crown.append((x, 1.0 - h * 0.004 * (abs(x) / 0.33) ** 2))
    for p in crown:
        out.append(p)
        vs.append(0.38 + 0.24 * (0.33 - p[0]) / 0.66)
    inner = [(-x, r) for x, r in reversed(out)]
    ivs = [1 - v for v in reversed(vs)]
    prof = out + inner
    pvs = vs + ivs
    # the bead band across the inside (behind the rim: never seen, keeps the tyre closed)
    prof.append((0.4, k - 0.012))
    pvs.append(1.0)
    # Blender's v runs up from the image's bottom row: the textures' rows run from the top, so v = 1 - V
    lathe(bm, prof, seg=96, uvl=uvl, vs=[1 - v for v in pvs], uscale=2.0)


def blur_disc(bm, uvl, f, hx):
    """the blurred spinning face: a single sheet over the spokes' front, following the bowl, out to the lip"""
    prof = [(hx + 0.035, 0.0)]
    for i in range(1, 15):
        t = i / 14
        r = HUB_R + (0.92 - HUB_R) * t
        prof.append((f(t) + 0.006, r))
    prof = [(hx + 0.035, 0.001), (hx + 0.034, HUB_R * 0.6), (hx + 0.022, HUB_R)] + prof[1:]
    faces = lathe(bm, prof, seg=64)
    for fa in faces:
        for loop in fa.loops:
            co = loop.vert.co
            loop[uvl].uv = (0.5 + co.y / 2, 0.5 + co.z / 2)


# ------------------------------------------------------------------ objects
def make(name, fill, smooth=40, uv=None):
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.verify()
    if uv == "own":
        fill(bm, uvl)
    else:
        fill(bm)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.polygons.foreach_set("use_smooth", [True] * len(me.polygons))
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    if smooth:
        m = o.modifiers.new("split", "EDGE_SPLIT")
        m.split_angle = math.radians(smooth)
    return o


def apply_mods(o):
    bpy.context.view_layer.objects.active = o
    for m in list(o.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)


def smart_uv(o, margin=0.012):
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(55), island_margin=margin)
    bpy.ops.object.mode_set(mode="OBJECT")


def cyl_uv(o):
    me = o.data
    uvl = me.uv_layers.active or me.uv_layers.new()
    for poly in me.polygons:
        angs = []
        for li in poly.loop_indices:
            co = me.vertices[me.loops[li].vertex_index].co
            angs.append(math.atan2(co.z, co.y) % math.tau)
        lo = min(angs)
        for li, a in zip(poly.loop_indices, angs):
            if a - lo > math.pi:
                a -= math.tau
            co = me.vertices[me.loops[li].vertex_index].co
            uvl.data[li].uv = (a / math.tau, (co.x + RX) / (2 * RX))


def planar_uv(o):
    me = o.data
    uvl = me.uv_layers.active or me.uv_layers.new()
    for li, loop in enumerate(me.loops):
        co = me.vertices[loop.vertex_index].co
        uvl.data[li].uv = (0.5 + co.y / 2, 0.5 + co.z / 2)


def mat(name, col, metal, rough, img=None):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = tuple(col) + (1,)
    b.inputs["Metallic"].default_value = metal
    b.inputs["Roughness"].default_value = rough
    if img is not None:
        n = m.node_tree.nodes.new("ShaderNodeTexImage")
        n.image = img
        m.node_tree.nodes.active = n
    return m


def add_slivers(o):
    bm = bmesh.new()
    bm.from_mesh(o.data)
    slivers(bm)
    bm.to_mesh(o.data)
    bm.free()


objs = {}
kit = {"designs": {}, "rimFrame": {"RX": RX, "discR": DISC_R}, "tyres": TYRE_K}

# shared rim-frame pieces
objs["R2_Lip"] = make("R2_Lip", lambda bm: lathe(bm, LIP, seg=SEG), smooth=50)
objs["R2_Barrel"] = make("R2_Barrel", lambda bm: lathe(bm, BARREL, seg=SEG), smooth=50)
objs["R2_Disc"] = make("R2_Disc", disc_mesh, smooth=30, uv="own")
objs["R2_CaliperA"] = make("R2_CaliperA", lambda bm: caliper(bm, 1), smooth=40)
objs["R2_CaliperB"] = make("R2_CaliperB", lambda bm: caliper(bm, -1), smooth=40)
objs["R2_Shield"] = make("R2_Shield", shield, smooth=40)
for key, k in TYRE_K.items():
    objs["R2_Tyre" + key] = make("R2_Tyre" + key, lambda bm, uvl, k=k: tyre(bm, uvl, k), smooth=70, uv="own")

for name, fn in DESIGNS.items():
    info = {}
    for depth, suf in ((0.0, ""), (1.0, "D")):
        store = {}

        def face(bm, fn=fn, depth=depth, store=store):
            hx, f, (n, lugs) = fn(bm, depth)
            rim_ring(bm)
            store.update(hx=hx, f=f, n=n, lugs=lugs)

        o = make("R2_%s_Face%s" % (name, suf), face, smooth=38)
        if name == "Disco5":
            # the dish alone (closed), the five holes cut, then joined into the face
            dish = make("dish_tmp", lambda bm, depth=depth: disco_dish(bm, depth), smooth=0)
            bmesh_d = bmesh.new()
            bmesh_d.from_mesh(dish.data)
            bmesh.ops.remove_doubles(bmesh_d, verts=bmesh_d.verts, dist=1e-5)
            bmesh_d.to_mesh(dish.data)
            bmesh_d.free()
            cutters = []
            for i in range(5):
                a = i / 5 * math.tau
                bpy.ops.mesh.primitive_cylinder_add(vertices=40, radius=0.165, depth=1.2, location=(0.2, 0.6 * math.cos(a), 0.6 * math.sin(a)), rotation=(0, math.pi / 2, 0))
                cutters.append(bpy.context.active_object)
            for c in cutters:
                m = dish.modifiers.new("hole", "BOOLEAN")
                m.operation = "DIFFERENCE"
                m.object = c
                m.solver = "EXACT"
            bpy.ops.object.select_all(action="DESELECT")
            dish.select_set(True)
            bpy.context.view_layer.objects.active = dish
            for m in list(dish.modifiers):
                bpy.ops.object.modifier_apply(modifier=m.name)
            for c in cutters:
                bpy.data.objects.remove(c)
            xs = [v.co.x for v in dish.data.vertices]
            print("DISH", depth, min(xs), max(xs), len(dish.data.polygons), flush=True)
            assert max(xs) < RX and min(xs) > -RX, "the dish's holes left cutter pieces"
            fb = bmesh.new()
            fb.from_mesh(o.data)
            fb.from_mesh(dish.data)
            fb.to_mesh(o.data)
            fb.free()
            bpy.data.objects.remove(dish)

        hx = store["hx"]
        objs[o.name] = o
        lugs = store["lugs"]
        cl = lugs == 0
        objs["R2_%s_Nuts%s" % (name, suf)] = make("R2_%s_Nuts%s" % (name, suf), lambda bm, hx=hx, lugs=lugs, cl=cl, n=store["n"]: (nuts(bm, hx, lugs, cl), valve(bm, n)), smooth=35)
        if not cl:
            objs["R2_%s_Cap%s" % (name, suf)] = make("R2_%s_Cap%s" % (name, suf), lambda bm, hx=hx: cap(bm, hx), smooth=40)
        objs["R2_%s_Blur%s" % (name, suf)] = make("R2_%s_Blur%s" % (name, suf), lambda bm, uvl, f=store["f"], hx=hx: blur_disc(bm, uvl, f, hx), smooth=0, uv="own")
        info[suf or "F"] = {"hubX": hx, "spokes": store["n"], "lugs": lugs, "centreLock": cl}
    kit["designs"][name] = info

# UVs for the ones that need a map of their own
for nm, o in objs.items():
    if nm.endswith(("Face", "FaceD")) or nm.startswith("R2_Caliper"):
        apply_mods(o)
        smart_uv(o)
        m = o.modifiers.new("split", "EDGE_SPLIT")
        m.split_angle = math.radians(38)
    elif nm == "R2_Barrel":
        cyl_uv(o)
    elif nm in ("R2_Lip", "R2_Shield") or "_Nuts" in nm or "_Cap" in nm:
        planar_uv(o)

tris = {nm: sum(len(p.vertices) - 2 for p in o.data.polygons) for nm, o in objs.items()}
print("TRIS", json.dumps(tris))
kit["tris"] = tris

# ------------------------------------------------------------------ AO bakes (spokes, barrel, calipers)
sc = bpy.context.scene
sc.render.engine = "CYCLES"
sc.cycles.device = "CPU"
sc.cycles.samples = 48
world = bpy.data.worlds.new("w")
world.use_nodes = True
sc.world = world
world.light_settings.distance = 0.35
tyre_occ = objs["R2_Tyre71"]


def set_tyre_occluder():
    # the tyre round the rim for the bake: its bead (0.71 of its radius) on the rim's edge
    s = 1.0 / 0.71 * 0.985
    tyre_occ.scale = (RX * 2 / 0.84, s, s)


def bake(target, size, others, out_name):
    path = os.path.join(TEX, out_name + ".png")
    if os.path.exists(path):
        # (already baked on an earlier run: delete the file to bake it again)
        return bpy.data.images.load(path)
    for o in bpy.data.objects:
        o.hide_render = o not in others and o is not target
    img = bpy.data.images.new(out_name, size, size, alpha=False)
    target.data.materials.clear()
    target.data.materials.append(mat(out_name, (0.8, 0.8, 0.8), 0, 0.5, img))
    bpy.ops.object.select_all(action="DESELECT")
    target.select_set(True)
    bpy.context.view_layer.objects.active = target
    sc.render.bake.margin = 6
    bpy.ops.object.bake(type="AO")
    px = np.array(img.pixels[:], dtype=np.float32).reshape(size, size, 4)
    ao = px[:, :, 0]
    # soften: never black, a little lift
    v = 0.3 + 0.7 * ao ** 0.85
    px[:, :, 0] = px[:, :, 1] = px[:, :, 2] = v
    px[:, :, 3] = 1
    img.pixels[:] = px.ravel()
    img.filepath_raw = os.path.join(TEX, out_name + ".png")
    img.file_format = "PNG"
    img.save()
    return img


if not NOBAKE:
    set_tyre_occluder()
    shared = [objs["R2_Lip"], objs["R2_Barrel"], objs["R2_Disc"], objs["R2_CaliperA"], objs["R2_CaliperB"], objs["R2_Shield"], tyre_occ]
    for name in DESIGNS:
        for suf in ("", "D"):
            face = objs["R2_%s_Face%s" % (name, suf)]
            extra = [objs[k] for k in ("R2_%s_Nuts%s" % (name, suf), "R2_%s_Cap%s" % (name, suf)) if k in objs]
            bake(face, 1024, shared + extra, "ao_%s_face%s" % (name, suf))
            bake(objs["R2_Barrel"], 512, shared + extra + [face], "ao_%s_barrel%s" % (name, suf))
            print("BAKED", name, suf, flush=True)
    # calipers: with the disc, shield and a plain spoke-less rim
    for s in ("A", "B"):
        bake(objs["R2_Caliper" + s], 512, [objs["R2_Disc"], objs["R2_Shield"], objs["R2_Barrel"], objs["R2_Lip"]], "ao_caliper" + s)
    tyre_occ.scale = (1, 1, 1)

# ------------------------------------------------------------------ blur textures: the spokes' cover seen from the front, averaged
# round the wheel (a spinning wheel on camera)
cam = bpy.data.cameras.new("c")
cam.type = "ORTHO"
cam.ortho_scale = 2.0
co = bpy.data.objects.new("c", cam)
sc.collection.objects.link(co)
sc.camera = co
co.location = (5, 0, 0)
co.rotation_euler = (Vector((0, 0, 0)) - co.location).to_track_quat("-Z", "Y").to_euler()
sc.render.film_transparent = True
sc.render.resolution_x = sc.render.resolution_y = 512
sc.cycles.samples = 8
white = bpy.data.materials.new("white")
white.use_nodes = True
nt = white.node_tree
for n in list(nt.nodes):
    nt.nodes.remove(n)
em = nt.nodes.new("ShaderNodeEmission")
outn = nt.nodes.new("ShaderNodeOutputMaterial")
nt.links.new(em.outputs[0], outn.inputs[0])
for name in DESIGNS:
    for suf in ("", "D"):
        parts = [objs[k] for k in ("R2_%s_Face%s" % (name, suf), "R2_%s_Nuts%s" % (name, suf), "R2_%s_Cap%s" % (name, suf)) if k in objs]
        for o in bpy.data.objects:
            o.hide_render = o not in parts
        saved = {}
        for o in parts:
            saved[o] = list(o.data.materials)
            o.data.materials.clear()
            o.data.materials.append(white)
        path = os.path.join(TEX, "_cover_%s%s.png" % (name, suf))
        sc.render.filepath = path
        bpy.ops.render.render(write_still=True)
        for o in parts:
            o.data.materials.clear()
            for m in saved[o]:
                o.data.materials.append(m)
        im = bpy.data.images.load(path)
        a = np.array(im.pixels[:], dtype=np.float32).reshape(512, 512, 4)[:, :, 3]
        bpy.data.images.remove(im)
        yy, xx = np.mgrid[0:512, 0:512]
        rr = np.sqrt((xx + 0.5 - 256) ** 2 + (yy + 0.5 - 256) ** 2) / 256
        bins = np.clip((rr * 200).astype(np.int32), 0, 220)
        sums = np.bincount(bins.ravel(), a.ravel(), 221)
        cnt = np.maximum(np.bincount(bins.ravel(), None, 221), 1)
        prof = sums / cnt
        cov = prof[bins]
        # a faint streaky texture round the wheel (fine blur lines), the cover itself a touch lighter than full
        ang = np.arctan2(yy - 256, xx - 256)
        streak = 0.96 + 0.04 * np.sin(rr * 180 + np.sin(ang * 3) * 0.5)
        alpha = np.clip(cov * 0.92, 0, 1)
        alpha[rr > 0.925] = 0
        col = np.clip(0.78 * streak, 0, 1)
        img = np.zeros((512, 512, 4), np.float32)
        img[:, :, 0] = img[:, :, 1] = img[:, :, 2] = col
        img[:, :, 3] = alpha
        out = bpy.data.images.new("blur_%s%s" % (name, suf), 512, 512, alpha=True)
        out.pixels[:] = img.ravel()
        out.filepath_raw = os.path.join(TEX, "blur_%s%s.png" % (name, suf))
        out.file_format = "PNG"
        out.save()
        kit["designs"][name][suf or "F"]["cover"] = float(np.mean(prof[60:180]))
sc.render.film_transparent = False

# ------------------------------------------------------------------ previews: each design on a tyre, with the brakes
def load(n):
    p = os.path.join(TEX, n + ".png")
    return bpy.data.images.load(p) if os.path.exists(p) else None


def pbr(name, col, metal, rough, colimg=None, nrm=None, rgh=None, tint=None):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    b.inputs["Metallic"].default_value = metal
    b.inputs["Roughness"].default_value = rough
    b.inputs["Base Color"].default_value = tuple(col) + (1,)
    if colimg:
        t = nt.nodes.new("ShaderNodeTexImage")
        t.image = colimg
        mix = nt.nodes.new("ShaderNodeMixRGB")
        mix.blend_type = "MULTIPLY"
        mix.inputs[0].default_value = 1
        mix.inputs[1].default_value = tuple(col) + (1,)
        nt.links.new(t.outputs[0], mix.inputs[2])
        nt.links.new(mix.outputs[0], b.inputs["Base Color"])
    if nrm:
        t = nt.nodes.new("ShaderNodeTexImage")
        t.image = nrm
        t.image.colorspace_settings.name = "Non-Color"
        nm = nt.nodes.new("ShaderNodeNormalMap")
        nt.links.new(t.outputs[0], nm.inputs[1])
        nt.links.new(nm.outputs[0], b.inputs["Normal"])
    if rgh:
        t = nt.nodes.new("ShaderNodeTexImage")
        t.image = rgh
        t.image.colorspace_settings.name = "Non-Color"
        nt.links.new(t.outputs[0], b.inputs["Roughness"])
    return m


tyre_tex = (os.path.join(OUT, "tex"),)
tcol, tnrm, trgh = load("tyre_sport_col"), load("tyre_sport_nrm"), load("tyre_sport_rgh")
for o in objs.values():
    o.data.materials.clear()
objs["R2_Lip"].data.materials.append(pbr("lip", (0.85, 0.86, 0.88), 1, 0.2, rgh=load("lip_machined_rgh")))
objs["R2_Disc"].data.materials.append(pbr("disc", (1, 1, 1), 0.9, 0.4, colimg=load("disc_drilled_col"), nrm=load("disc_drilled_nrm")))
objs["R2_Shield"].data.materials.append(pbr("shield", (0.03, 0.03, 0.035), 0.2, 0.7))
for s in ("A", "B"):
    objs["R2_Caliper" + s].data.materials.append(pbr("cal" + s, (0.85, 0.08, 0.05), 0, 0.35, colimg=load("ao_caliper" + s)))
for key in TYRE_K:
    objs["R2_Tyre" + key].data.materials.append(pbr("tyre" + key, (1, 1, 1), 0, 0.85, colimg=tcol, nrm=tnrm, rgh=trgh))

sc.render.engine = "CYCLES"
sc.cycles.samples = 64
sc.render.resolution_x, sc.render.resolution_y = 640, 640
world.node_tree.nodes["Background"].inputs[0].default_value = (0.55, 0.6, 0.68, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = 0.9
sun = bpy.data.lights.new("s", "SUN")
sun.energy = 3.5
so = bpy.data.objects.new("s", sun)
sc.collection.objects.link(so)
so.rotation_euler = (math.radians(50), math.radians(-30), math.radians(40))
cam.type = "PERSP"
cam.lens = 60
k = 0.71
ts = 1.0 / k * 0.985
FINISH = {"Furia7": (0.02, 0.02, 0.025), "SaettaY5": (0.12, 0.12, 0.13), "Corsa10": (0.6, 0.61, 0.63), "Centro6": (0.1, 0.1, 0.11), "Turbine14": (0.55, 0.56, 0.58), "Trio6": (0.02, 0.02, 0.025), "Royale20": (0.7, 0.71, 0.73), "Disco5": (0.6, 0.6, 0.62)}
for name in DESIGNS:
    for suf in ("", "D"):
        show = [objs["R2_Lip"], objs["R2_Barrel"], objs["R2_Disc"], objs["R2_CaliperA"], objs["R2_Shield"], objs["R2_Tyre71"]]
        face = objs["R2_%s_Face%s" % (name, suf)]
        face.data.materials.clear()
        face.data.materials.append(pbr("f" + name + suf, FINISH[name], 0.9, 0.32, colimg=load("ao_%s_face%s" % (name, suf))))
        objs["R2_Barrel"].data.materials.clear()
        objs["R2_Barrel"].data.materials.append(pbr("b", (0.18, 0.18, 0.19), 0.8, 0.45, colimg=load("ao_%s_barrel%s" % (name, suf))))
        show.append(face)
        for kk in ("R2_%s_Nuts%s" % (name, suf), "R2_%s_Cap%s" % (name, suf)):
            if kk in objs:
                o = objs[kk]
                o.data.materials.clear()
                o.data.materials.append(pbr(kk, (0.75, 0.76, 0.78) if "Nuts" in kk else FINISH[name], 1, 0.18 if "Nuts" in kk else 0.3))
                show.append(o)
        objs["R2_Tyre71"].scale = (RX * 2 / 0.84, ts, ts)
        for o in bpy.data.objects:
            o.hide_render = o not in show and o not in (so,)
        for view, loc in (("q", (4.6, -3.3, 1.2)), ("side", (5.6, 0, 0.3))):
            co.location = loc
            co.rotation_euler = (Vector((0, 0, 0)) - co.location).to_track_quat("-Z", "Z").to_euler()
            sc.render.filepath = os.path.join(PRE, "%s%s_%s.png" % (name, suf, view))
            bpy.ops.render.render(write_still=True)
        print("PREVIEW", name, suf, flush=True)
objs["R2_Tyre71"].scale = (1, 1, 1)

# ------------------------------------------------------------------ export (rim frame and tyre frame, every mesh at the origin)
for o in list(bpy.data.objects):
    if o.name not in objs:
        bpy.data.objects.remove(o)
for nm, o in objs.items():
    o.data.materials.clear()
    o.data.materials.append(mat("m_" + nm, (0.8, 0.8, 0.8), 0, 0.5))
    if not nm.startswith("R2_Tyre"):
        apply_mods(o)
        add_slivers(o)
# every rim-frame mesh must fill exactly the same box (else its part lands off in Studio)
for nm, o in objs.items():
    xs = [v.co.x for v in o.data.vertices]
    rs = [math.hypot(v.co.y, v.co.z) for v in o.data.vertices]
    if nm.startswith("R2_Tyre"):
        ok = abs(max(xs) - 0.5) < 1e-3 and abs(min(xs) + 0.5) < 1e-3 and abs(max(rs) - 1) < 1e-3
    else:
        ys = [v.co.y for v in o.data.vertices]
        zs = [v.co.z for v in o.data.vertices]
        ok = abs(max(xs) - RX) < 1e-4 and abs(min(xs) + RX) < 1e-4 and abs(max(ys) - 1) < 1e-4 and abs(min(ys) + 1) < 1e-4 and abs(max(zs) - 1) < 1e-4 and abs(min(zs) + 1) < 1e-4
    if not ok:
        raise SystemExit("BOX WRONG " + nm + " x %.4f..%.4f r %.4f" % (min(xs), max(xs), max(rs)))
print("BOXES OK", flush=True)
bpy.ops.object.select_all(action="DESELECT")
for o in objs.values():
    o.select_set(True)
fbx = os.path.join(OUT, "wheels2.fbx")
bpy.ops.export_scene.fbx(filepath=fbx, use_selection=True, use_mesh_modifiers=True, axis_forward="-Z", axis_up="Y", global_scale=1.0, apply_scale_options="FBX_SCALE_NONE", mesh_smooth_type="FACE", add_leaf_bones=False, bake_anim=False)
with open(os.path.join(OUT, "kit.json"), "w") as fh:
    json.dump(kit, fh, indent=1)
print("FBX", fbx)
