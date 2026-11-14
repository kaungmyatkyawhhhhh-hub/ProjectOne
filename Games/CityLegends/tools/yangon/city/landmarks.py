"""Yangon landmark models (14 Nov 2026): pure Python meshes for the great landmarks (Shwedagon first).

    python tools/yangon/city/landmarks.py [ids...]      # default: every landmark built here
      -> imports/sync/ygn_landmarks/<id>.glb             (upload as a Model, group 33151111, model/gltf-binary)
      -> build/landmarks/<id>.json                       (meshes: name, tris, centre, size)
      -> build/landmarks/<id>_data.luau                  (collision boxes, hill height grid, trees: pasted into Studio)

Scales (owner's map): the ground plan is 1.6 studs a metre, buildings stand at the cars' scale (3 studs a metre). A landmark
made with both would come out 1.9 times too slender, so each one has its own horizontal scale SH (studs a metre, across)
next to SV = 3 (up): Shwedagon's stupa uses SH 2.0 (a 99 m stupa is 297 studs tall, its plinth 216 studs wide), so it
stays a broad gold bell and still reads tall and majestic.

Kits: lathe (surface of revolution, smooth normals, creases where the profile turns sharply), crown (petal band), prisms
and frustums for terraces, the small pagoda (zedi), the tiered pyatthat roof, the tazaung shrine hall, the covered
stairway (zaungdan) with its gate, the chinthe (stylised), the platform. Positions are world studs (glb.py): every mesh
is named KIND_id_cx_cy_cz_sx_sy_sz (glb.code) and placed with CFrame.new(centre), Size from the name.

Mesh kinds (tools/yangon/YangonLandmarks.luau sets the material by kind):
  GOLD   gilded surfaces: Metal, warm gold (246, 176, 52), tag LandmarkGlow (glows at night)
  WHITE  lime-washed / marble masonry: SmoothPlastic white, vertex colours carry the trims
  MIX    painted parts in several colours (red columns, roofs, floors): SmoothPlastic, vertex colours
  STONE  the platform's marble floor and retaining wall: Marble, a light grey that tones the vertex colours
Every mesh stays under 17,000 triangles.
"""
import json
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from glb import Mesh, write_glb, code, check_glb  # noqa: E402
import geo  # noqa: E402

OUT_GLB = os.path.join(geo.ROOT, 'imports', 'sync', 'ygn_landmarks')
OUT_DATA = os.path.join(geo.BUILD, 'landmarks')
SV = 3.0
MAX_TRIS = 17000

UV0 = (0.0, 0.0)

# colours (vertex colours; GOLD meshes are tinted by the part Color, so their vertex colours are near white shades)
G_HI = (255, 252, 244)
G_MID = (240, 232, 214)
G_LO = (214, 200, 172)
WHITE = (232, 228, 220)
WHITE_SH = (206, 202, 194)
MARBLE = (206, 202, 194)
MARBLE_BAND = (150, 62, 52)
MARBLE_TEAL = (70, 128, 122)
RED = (176, 38, 30)
RED_DK = (122, 30, 24)
ROOF_RED = (132, 40, 30)
ROOF_GREEN = (52, 104, 74)
BRICK = (170, 104, 80)
STONE = (196, 190, 178)
DARK = (40, 30, 24)
GOLD_V = (232, 176, 58)      # gold as a vertex colour in MIX meshes (trims)


# ---------------------------------------------------------------------------------------------------------------- maths
def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def mul(a, s):
    return (a[0] * s, a[1] * s, a[2] * s)


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def unit(v):
    l = math.sqrt(dot(v, v))
    return (v[0] / l, v[1] / l, v[2] / l) if l > 1e-12 else (0.0, 1.0, 0.0)


def tri(m, a, b, c, rgb, want=None, normals=None):
    """a triangle facing `want` (a direction) or along its given normals"""
    n = cross(sub(b, a), sub(c, a))
    if dot(n, n) < 1e-12:
        return
    ref = want
    if ref is None and normals:
        ref = add(add(normals[0], normals[1]), normals[2])
    if ref is not None and dot(n, ref) < 0:
        b, c = c, b
        if normals:
            normals = (normals[0], normals[2], normals[1])
    m.tri(a, b, c, UV0, UV0, UV0, rgb, normals)


def quad(m, a, b, c, d, rgb, want=None, normals=None):
    if normals:
        tri(m, a, b, c, rgb, want, (normals[0], normals[1], normals[2]))
        tri(m, a, c, d, rgb, want, (normals[0], normals[2], normals[3]))
    else:
        tri(m, a, b, c, rgb, want)
        tri(m, a, c, d, rgb, want)


def fan(m, pts, rgb, want, centre=None):
    """a star-shaped polygon (3D points) as a fan from its centre"""
    if centre is None:
        centre = mul(pts[0], 0)
        for p in pts:
            centre = add(centre, p)
        centre = mul(centre, 1.0 / len(pts))
    for i in range(len(pts)):
        tri(m, centre, pts[i], pts[(i + 1) % len(pts)], rgb, want)


# ------------------------------------------------------------------------------------------------------------- shapes 2D
def redent(a, d, steps=2):
    """a square of half-width a with each corner redented `steps` times by d (Burmese stepped corners); (x, z) points
    in order round the centre."""
    pts = []
    for q in range(4):
        ang = q * math.pi / 2
        c, s = math.cos(ang), math.sin(ang)
        # one quarter: from the middle of the +x side up to the middle of the +z side (local), then rotated
        loc = [(a, 0.0)]
        loc.append((a, a - steps * d))
        for k in range(steps):
            loc.append((a - (k + 1) * d, a - (steps - k) * d))
            loc.append((a - (k + 1) * d, a - (steps - k - 1) * d))
        # ... ends at (a - steps*d, a): the start of the +z side
        for x, z in loc:
            pts.append((x * c - z * s, x * s + z * c))
    return pts


def ngon(r, n, rot=0.0):
    return [(r * math.cos(rot + 2 * math.pi * k / n), r * math.sin(rot + 2 * math.pi * k / n)) for k in range(n)]


def rect(hx, hz):
    return [(hx, hz), (-hx, hz), (-hx, -hz), (hx, -hz)]


def scale2(poly, s):
    return [(x * s, z * s) for x, z in poly]


# ------------------------------------------------------------------------------------------------------- solid helpers
def prism(m, poly, cx, cz, y0, y1, rgb, top=True, bottom=False, rgb_top=None, yaw=0.0):
    """vertical walls round a 2D polygon (local x, z about cx, cz) from y0 to y1, optional caps"""
    c, s = math.cos(yaw), math.sin(yaw)
    P = [(cx + x * c - z * s, cz + x * s + z * c) for x, z in poly]
    gx = sum(p[0] for p in P) / len(P)
    gz = sum(p[1] for p in P) / len(P)
    n = len(P)
    for i in range(n):
        a, b = P[i], P[(i + 1) % n]
        mx, mz = (a[0] + b[0]) / 2 - gx, (a[1] + b[1]) / 2 - gz
        ex, ez = b[0] - a[0], b[1] - a[1]
        out = (ez, 0, -ex)
        if out[0] * mx + out[2] * mz < 0:
            out = (-ez, 0, ex)
        quad(m, (a[0], y0, a[1]), (b[0], y0, b[1]), (b[0], y1, b[1]), (a[0], y1, a[1]), rgb, out)
    if top:
        fan(m, [(p[0], y1, p[1]) for p in P], rgb_top or rgb, (0, 1, 0), (gx, y1, gz))
    if bottom:
        fan(m, [(p[0], y0, p[1]) for p in P], rgb, (0, -1, 0), (gx, y0, gz))


def frustum(m, polyA, polyB, cx, cz, y0, y1, rgb, top=False, yaw=0.0, rgb_top=None):
    """sloped sides from polyA at y0 to polyB at y1 (same point count, same order)"""
    c, s = math.cos(yaw), math.sin(yaw)
    A = [(cx + x * c - z * s, cz + x * s + z * c) for x, z in polyA]
    B = [(cx + x * c - z * s, cz + x * s + z * c) for x, z in polyB]
    n = len(A)
    for i in range(n):
        j = (i + 1) % n
        a0, a1 = (A[i][0], y0, A[i][1]), (A[j][0], y0, A[j][1])
        b0, b1 = (B[i][0], y1, B[i][1]), (B[j][0], y1, B[j][1])
        mid = mul(add(add(a0, a1), add(b0, b1)), 0.25)
        out = (mid[0] - cx, 0.0, mid[2] - cz)
        nrm = cross(sub(a1, a0), sub(b0, a0))
        if dot(nrm, out) < 0:
            nrm = mul(nrm, -1)
        quad(m, a0, a1, b1, b0, rgb, nrm)
    if top:
        fan(m, [(p[0], y1, p[1]) for p in B], rgb_top or rgb, (0, 1, 0), (cx, y1, cz))


def box(m, cx, cy, cz, sx, sy, sz, rgb, yaw=0.0, top=True, bottom=False):
    prism(m, rect(sx / 2, sz / 2), cx, cz, cy - sy / 2, cy + sy / 2, rgb, top=top, bottom=bottom, yaw=yaw)


def obox(m, centre, ax, ay, az, hx, hy, hz, rgb):
    """an oriented box: centre, unit axes ax ay az, half sizes (for tilted parts: chinthe, ramps)"""
    corners = {}
    for i in (-1, 1):
        for j in (-1, 1):
            for k in (-1, 1):
                corners[(i, j, k)] = add(add(add(centre, mul(ax, i * hx)), mul(ay, j * hy)), mul(az, k * hz))
    faces = [((1, 0, 0), ax), ((-1, 0, 0), mul(ax, -1)), ((0, 1, 0), ay), ((0, -1, 0), mul(ay, -1)), ((0, 0, 1), az),
             ((0, 0, -1), mul(az, -1))]
    for f, out in faces:
        axis = [i for i in range(3) if f[i] != 0][0]
        sgn = f[axis]
        others = [i for i in range(3) if i != axis]
        cs = []
        for u, v in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
            key = [0, 0, 0]
            key[axis] = sgn
            key[others[0]] = u
            key[others[1]] = v
            cs.append(corners[tuple(key)])
        quad(m, cs[0], cs[1], cs[2], cs[3], rgb, out)


def lathe(m, cx, cz, prof, segs, rgb=G_HI, rot=0.0, crease_deg=35.0, cap_top=False):
    """surface of revolution about the vertical through (cx, cz). prof: [(r, y) or (r, y, rgb)] from the bottom up
    (absolute y). Smooth normals round and along the profile, with a crease where the profile turns more than crease_deg."""
    pts = [(p[0], p[1]) for p in prof]
    cols = [p[2] if len(p) > 2 else rgb for p in prof]
    ns = len(pts) - 1
    segN = []
    for i in range(ns):
        dr = pts[i + 1][0] - pts[i][0]
        dy = pts[i + 1][1] - pts[i][1]
        l = math.hypot(dr, dy) or 1.0
        segN.append((dy / l, -dr / l))
    cosc = math.cos(math.radians(crease_deg))

    def vnorm(i, side):
        """normal at profile point i for segment i (side 0 = segment starting at i, 1 = segment ending at i)"""
        k = i if side == 0 else i - 1
        n = segN[k]
        other = (k - 1) if side == 0 else (k + 1)
        if 0 <= other < ns:
            o = segN[other]
            if n[0] * o[0] + n[1] * o[1] > cosc:
                v = (n[0] + o[0], n[1] + o[1])
                l = math.hypot(*v) or 1.0
                return (v[0] / l, v[1] / l)
        return n

    for i in range(ns):
        (r0, y0), (r1, y1) = pts[i], pts[i + 1]
        if r0 < 1e-6 and r1 < 1e-6:
            continue
        n0, n1 = vnorm(i, 0), vnorm(i + 1, 1)
        for j in range(segs):
            a0 = rot + 2 * math.pi * j / segs
            a1 = rot + 2 * math.pi * (j + 1) / segs
            c0, s0, c1, s1 = math.cos(a0), math.sin(a0), math.cos(a1), math.sin(a1)
            p00 = (cx + r0 * c0, y0, cz + r0 * s0)
            p10 = (cx + r0 * c1, y0, cz + r0 * s1)
            p11 = (cx + r1 * c1, y1, cz + r1 * s1)
            p01 = (cx + r1 * c0, y1, cz + r1 * s0)
            N00 = (c0 * n0[0], n0[1], s0 * n0[0])
            N10 = (c1 * n0[0], n0[1], s1 * n0[0])
            N11 = (c1 * n1[0], n1[1], s1 * n1[0])
            N01 = (c0 * n1[0], n1[1], s0 * n1[0])
            if r0 < 1e-6:
                tri(m, p00, p11, p01, cols[i], None, (N00, N11, N01))
            elif r1 < 1e-6:
                tri(m, p00, p10, p11, cols[i], None, (N00, N10, N11))
            else:
                quad(m, p00, p10, p11, p01, cols[i], None, (N00, N10, N11, N01))
    if cap_top and pts[-1][0] > 1e-6:
        r, y = pts[-1]
        fan(m, [(cx + r * math.cos(rot + 2 * math.pi * j / segs), y, cz + r * math.sin(rot + 2 * math.pi * j / segs))
                for j in range(segs)], cols[-1], (0, 1, 0), (cx, y, cz))


def crown(m, cx, cz, y0, y1, r_in, r_out, n, rgb, up=True, rot=0.0):
    """a band of n lotus petals: pointed leaves leaning out round a core (up = tips at the top)"""
    for k in range(n):
        a0 = rot + 2 * math.pi * k / n
        a1 = rot + 2 * math.pi * (k + 1) / n
        am = (a0 + a1) / 2
        yb, yt = (y0, y1) if up else (y1, y0)
        b0 = (cx + r_in * math.cos(a0), yb, cz + r_in * math.sin(a0))
        b1 = (cx + r_in * math.cos(a1), yb, cz + r_in * math.sin(a1))
        bm = (cx + r_out * 0.92 * math.cos(am), yb + (yt - yb) * 0.35, cz + r_out * 0.92 * math.sin(am))
        tip = (cx + r_out * math.cos(am), yt, cz + r_out * math.sin(am))
        out = (math.cos(am), 0.25 if up else -0.25, math.sin(am))
        quad(m, b0, b1, bm, bm, rgb, out)
        tri(m, b0, bm, tip, rgb, out)
        tri(m, bm, b1, tip, rgb, out)


def sphere(m, cx, cy, cz, r, rgb, segs=12, rings=8):
    prof = [(r * math.sin(math.pi * k / rings), cy - r * math.cos(math.pi * k / rings)) for k in range(rings + 1)]
    prof[0] = (0.0, prof[0][1])
    prof[-1] = (0.0, prof[-1][1])
    lathe(m, cx, cz, prof, segs, rgb, crease_deg=89)


def place(dst, src, ox, oy, oz, yaw=0.0, s=1.0):
    """copy a local-space mesh into dst: scaled by s, turned yaw (radians, about +y) and moved to (ox, oy, oz)"""
    c, si = math.cos(yaw), math.sin(yaw)
    k = len(dst.P)
    for p in src.P:
        x, y, z = p[0] * s, p[1] * s, p[2] * s
        dst.P.append((ox + x * c - z * si, oy + y, oz + x * si + z * c))
    for n in src.N:
        dst.N.append((n[0] * c - n[2] * si, n[1], n[0] * si + n[2] * c))
    dst.U += src.U
    dst.C += src.C
    dst.T += [t + k for t in src.T]


# --------------------------------------------------------------------------------------------------------------- kits
def zedi(H, b, gold=True, segs=10):
    """a small pagoda (local, base centre at the origin, height H, base half-width b): redented base, octagon, bell,
    rings, banana bud, hti. Returns (mesh_gold_or_white,)."""
    m = Mesh()
    col = G_HI if gold else WHITE
    lo = G_LO if gold else WHITE_SH
    prism(m, redent(b, b * 0.12, 2), 0, 0, 0, 0.11 * H, lo)
    prism(m, redent(b * 0.84, b * 0.1, 2), 0, 0, 0.11 * H, 0.19 * H, col)
    prism(m, ngon(b * 0.74, 8, math.pi / 8), 0, 0, 0.19 * H, 0.25 * H, lo)
    prof = [(b * 0.66, 0.25 * H), (b * 0.64, 0.30 * H), (b * 0.6, 0.37 * H), (b * 0.5, 0.44 * H), (b * 0.36, 0.48 * H),
            (b * 0.36, 0.5 * H, lo), (b * 0.3, 0.53 * H), (b * 0.3, 0.55 * H, lo), (b * 0.25, 0.58 * H),
            (b * 0.25, 0.6 * H), (b * 0.22, 0.62 * H), (b * 0.23, 0.66 * H), (b * 0.19, 0.72 * H), (b * 0.12, 0.79 * H),
            (b * 0.07, 0.84 * H, lo), (b * 0.12, 0.86 * H), (b * 0.05, 0.92 * H), (b * 0.025, 0.96 * H), (0.0, H)]
    lathe(m, 0, 0, prof, segs, col)
    return m


def pyatthat(w, tiers, H, roof=G_HI, neck=RED_DK, trim=G_HI, spire=G_HI, gables=True, square=True):
    """a Burmese tiered roof (local; its base centre at the origin, base half-size w, total height H): each tier a
    sloped roof with an eave lip and upturned corner finials, a neck between tiers, a tall spire (bell, rings, bud, hti)
    on top. Returns (gold_mesh, mix_mesh): gold = roofs and spire (when roof is gold), mix = necks and gables."""
    g, x = Mesh(), Mesh()
    rm = g if roof == G_HI else x
    roof_h = H * 0.62       # the tiers take 62 % of the height, the spire the rest
    # tier heights shrink upward: geometric 0.82
    ws = [w * (1 - 0.72 * k / max(1, tiers)) for k in range(tiers)]
    hs = [0.82 ** k for k in range(tiers)]
    sc = roof_h / sum(hs)
    hs = [h * sc for h in hs]
    y = 0.0
    for k in range(tiers):
        wk, hk = ws[k], hs[k]
        eave = 0.16 * hk
        # neck (a short wall under the roof), then the eave lip, then the slope up to the next tier's neck
        nw = wk * 0.62
        neck_h = hk * 0.28
        prism(x, rect(nw, nw) if square else ngon(nw * 1.08, 8, math.pi / 8), 0, 0, y, y + neck_h, neck, top=False)
        y += neck_h
        prism(rm, rect(wk, wk), 0, 0, y, y + eave, trim if rm is g else roof, top=False, bottom=True)
        top_w = wk * 0.5
        frustum(rm, rect(wk, wk), rect(top_w, top_w), 0, 0, y + eave, y + hk - neck_h * 0.2, roof, top=True)
        # corner finials: small upturned spikes at the eave corners
        for sx, sz in ((1, 1), (-1, 1), (-1, -1), (1, -1)):
            base = (sx * wk, y + eave, sz * wk)
            tip = (sx * wk * 1.12, y + eave + hk * 0.55, sz * wk * 1.12)
            side1 = (sx * wk * 0.9, y + eave, sz * wk)
            side2 = (sx * wk, y + eave, sz * wk * 0.9)
            tri(g, base, side1, tip, trim, (sx, 0.3, sz))
            tri(g, base, side2, tip, trim, (sx, 0.3, sz))
            tri(g, side1, side2, tip, trim, (sx * 0.3, 1, sz * 0.3))
        # gable fronts (the pointed pediments) on the lowest two tiers, on all four sides
        if gables and k < 2:
            for q in range(4):
                a = q * math.pi / 2
                c, s = math.cos(a), math.sin(a)
                gw, gh = wk * 0.42, hk * 0.95
                p0 = (c * wk * 1.01 - s * (-gw), y + eave, s * wk * 1.01 + c * (-gw))
                p1 = (c * wk * 1.01 - s * gw, y + eave, s * wk * 1.01 + c * gw)
                p2 = (c * (wk * 0.78), y + eave + gh, s * (wk * 0.78))
                tri(g, p0, p1, p2, trim, (c, 0.2, s))
        y += hk - neck_h
    # the spire: bell, rings, bud, hti, spike
    S = H - y
    r = ws[-1] * 0.5
    prof = [(r, y), (r * 0.95, y + S * 0.08), (r * 0.78, y + S * 0.16), (r * 0.5, y + S * 0.22), (r * 0.48, y + S * 0.26),
            (r * 0.38, y + S * 0.3), (r * 0.4, y + S * 0.36), (r * 0.3, y + S * 0.48), (r * 0.16, y + S * 0.62),
            (r * 0.2, y + S * 0.66), (r * 0.08, y + S * 0.82), (r * 0.03, y + S * 0.9), (0.0, H)]
    lathe(g, 0, 0, prof, 8, spire)
    return g, x


def ellipsoid(m, c, ax, ay, az, rx, ry, rz, rgb, segs=10, rings=7, cut=None):
    """an ellipsoid at c with unit axes ax ay az and radii, smooth normals. cut=(lo, hi) keeps only rings whose
    polar angle fraction is in [lo, hi] (0 = the -ay pole, 1 = the +ay pole), for half shapes."""
    lo, hi = cut or (0.0, 1.0)

    def pt(i, j):
        th = math.pi * (lo + (hi - lo) * i / rings)        # 0 at -ay
        ph = 2 * math.pi * j / segs
        u, v, w_ = math.sin(th) * math.cos(ph), -math.cos(th), math.sin(th) * math.sin(ph)
        p = add(add(add(c, mul(ax, rx * u)), mul(ay, ry * v)), mul(az, rz * w_))
        n = unit(add(add(mul(ax, u / rx), mul(ay, v / ry)), mul(az, w_ / rz)))
        return p, n

    for i in range(rings):
        for j in range(segs):
            p00, n00 = pt(i, j)
            p10, n10 = pt(i, j + 1)
            p11, n11 = pt(i + 1, j + 1)
            p01, n01 = pt(i + 1, j)
            quad(m, p00, p10, p11, p01, rgb, None, (n00, n10, n11, n01))
    if cut and lo > 0:
        # close the open bottom with a flat cap
        ring = [pt(0, j)[0] for j in range(segs)]
        fan(m, ring, rgb, mul(ay, -1))


def tube(m, path, radii, rgb, segs=10, side=(1, 0, 0), squash=1.0):
    """a smooth tube swept along a path (points) with a radius per point; rings turn about `side` (a path in a plane
    square to it). squash < 1 flattens the tube across `side`."""
    rings = []
    for i, p in enumerate(path):
        a = path[max(0, i - 1)]
        b = path[min(len(path) - 1, i + 1)]
        t = unit(sub(b, a))
        n = unit(cross(side, t))
        ring = []
        for j in range(segs):
            ang = 2 * math.pi * j / segs
            d = add(mul(side, math.cos(ang) * squash), mul(n, math.sin(ang)))
            ring.append((add(p, mul(d, radii[i])), unit(add(mul(side, math.cos(ang) / max(0.2, squash)), mul(n, math.sin(ang))))))
        rings.append(ring)
    for i in range(len(rings) - 1):
        for j in range(segs):
            k = (j + 1) % segs
            (p00, n00), (p10, n10) = rings[i][j], rings[i][k]
            (p01, n01), (p11, n11) = rings[i + 1][j], rings[i + 1][k]
            quad(m, p00, p10, p11, p01, rgb, None, (n00, n10, n11, n01))
    end = rings[-1]
    fan(m, [q[0] for q in end], rgb, unit(sub(path[-1], path[-2])), path[-1])


def hall(w, d, h, wall=WHITE, col=RED, trim=GOLD_V, ceil=(122, 32, 26)):
    """a tazaung shrine hall body (local: front facing +z, base at y=0, half sizes w (x), d (z), eave height h): a white
    plinth with steps, an open hall of slim red columns on three sides, the back wall, a red ceiling under the roof, a
    gold frieze, a seated gold Buddha at the back. Returns the MIX mesh (its gold trim as vertex colour)."""
    m = Mesh()
    pl = 1.6
    prism(m, rect(w + 1.4, d + 1.4), 0, 0, -6.0, pl, WHITE, rgb_top=(232, 228, 220))  # plinth (6 down: slopes)
    box(m, 0, pl * 0.5, d + 2.6, w * 0.8, pl, 2.4, WHITE)                              # front step
    box(m, 0, pl + (h - pl) / 2, -d + 0.8, 2 * w - 1.6, h - pl, 1.6, wall)             # back wall
    box(m, 0, pl + (h - pl) / 2, -d + 1.65, 2 * w - 3.0, h - pl - 1.4, 0.12, (118, 40, 30))  # its inner face (red)
    # columns: front and sides, slim, red with gold bases and capitals
    sp = 7.5
    nf = max(2, int(round(2 * w / sp)))
    ns = max(1, int(round(2 * d / sp)))
    spots = [(-w + 0.8 + (2 * w - 1.6) * i / nf, d - 0.8) for i in range(nf + 1)]
    for sx in (-1, 1):
        spots += [(sx * (w - 0.8), d - 0.8 - (2 * d - 1.6) * i / ns) for i in range(1, ns)]
    for x, z in spots:
        box(m, x, pl + (h - pl) / 2, z, 1.1, h - pl, 1.1, col)
        box(m, x, pl + 0.7, z, 1.7, 1.4, 1.7, trim)
        box(m, x, h - 2.0, z, 1.5, 1.0, 1.5, trim)
    # the frieze round the top (gold), its underside the ceiling
    prism(m, rect(w, d), 0, 0, h - 1.5, h, trim, top=True)
    fan(m, [(w, h - 1.5, d), (-w, h - 1.5, d), (-w, h - 1.5, -d), (w, h - 1.5, -d)], ceil, (0, -1, 0), (0, h - 1.5, 0))
    # a hanging valance: pointed gold teeth under the front frieze
    nt = max(3, int(2 * w / 2.2))
    for i in range(nt):
        x0 = -w + 2 * w * i / nt
        x1 = -w + 2 * w * (i + 1) / nt
        for zz, nz in ((d + 0.06, 1), (d - 0.06, -1)):
            tri(m, (x0, h - 1.5, zz), (x1, h - 1.5, zz), ((x0 + x1) / 2, h - 2.6, zz), trim, (0, 0, nz))
    # a seated gold Buddha on a red throne at the back
    bz = -d + 4.2
    box(m, 0, pl + 1.2, bz, 5.0, 2.4, 3.4, (150, 36, 30))
    bud = Mesh()
    ellipsoid(bud, (0, pl + 3.6, bz), (1, 0, 0), (0, 1, 0), (0, 0, 1), 2.3, 1.3, 1.6, trim, 8, 5)
    ellipsoid(bud, (0, pl + 5.6, bz), (1, 0, 0), (0, 1, 0), (0, 0, 1), 1.5, 2.2, 1.1, trim, 8, 5)
    ellipsoid(bud, (0, pl + 8.3, bz + 0.1), (1, 0, 0), (0, 1, 0), (0, 0, 1), 0.9, 1.0, 0.9, trim, 8, 5)
    m.extend(bud)
    return m


def chinthe(H):
    """a seated chinthe (the guardian lion at the pagoda gates; the south gate's pair in white and gold), stylised from
    the reference photo: upright, chest out, straight front legs, a big head held high with the mouth wide open (red),
    round eyes, a flaming mane round the face and a crest behind, gold collar and breast plate, the tail curling up.
    Local: facing +z, base at y=0, height H. Returns (white_mesh, gold_mesh)."""
    w, gm = Mesh(), Mesh()
    s = H / 30.0
    X, Y, Z = (1, 0, 0), (0, 1, 0), (0, 0, 1)

    def tilt(deg):
        t = math.radians(deg)
        return (0, math.cos(t), -math.sin(t)), (0, math.sin(t), math.cos(t))

    # the plinth: white, stepped, a gold band
    prism(w, rect(8.6 * s, 11.0 * s), 0, 0, -4.0 * s, 2.6 * s, WHITE_SH)
    prism(gm, rect(8.9 * s, 11.3 * s), 0, 0, 2.6 * s, 3.2 * s, G_HI, top=False)
    prism(w, rect(8.0 * s, 10.4 * s), 0, 0, 3.2 * s, 4.2 * s, WHITE)
    y0 = 4.2 * s
    # haunches and hind legs folded under (sitting), hind paws forward
    ellipsoid(w, (0, y0 + 4.6 * s, -4.2 * s), X, Y, Z, 6.4 * s, 4.8 * s, 6.0 * s, WHITE, 12, 7)
    for sx in (-1, 1):
        ellipsoid(w, (sx * 5.0 * s, y0 + 3.8 * s, -2.2 * s), X, Y, Z, 2.4 * s, 3.8 * s, 4.8 * s, WHITE, 10, 6)
        ellipsoid(w, (sx * 4.8 * s, y0 + 0.9 * s, 2.6 * s), X, Y, Z, 1.9 * s, 0.95 * s, 2.6 * s, WHITE, 8, 5)
    # the body: upright, leaning back a little, chest out
    ay, az = tilt(12)
    ellipsoid(w, (0, y0 + 11.0 * s, -0.8 * s), X, ay, az, 5.0 * s, 7.6 * s, 4.6 * s, WHITE, 12, 8)
    ellipsoid(w, (0, y0 + 13.4 * s, 1.6 * s), X, ay, az, 4.2 * s, 4.6 * s, 3.4 * s, WHITE, 12, 7)  # chest
    # front legs: straight columns, big paws
    for sx in (-1, 1):
        lathe(w, sx * 2.9 * s, 3.4 * s, [(1.75 * s, y0 + 0.6 * s), (1.55 * s, y0 + 4.0 * s), (1.6 * s, y0 + 8.0 * s),
                                          (2.0 * s, y0 + 11.0 * s), (0.0, y0 + 12.5 * s)], 8, WHITE)
        ellipsoid(w, (sx * 2.9 * s, y0 + 0.8 * s, 4.4 * s), X, Y, Z, 2.0 * s, 1.0 * s, 2.5 * s, WHITE, 8, 5)
        lathe(gm, sx * 2.9 * s, 3.4 * s, [(1.75 * s, y0 + 6.2 * s), (1.9 * s, y0 + 6.6 * s), (1.9 * s, y0 + 7.2 * s),
                                           (1.7 * s, y0 + 7.6 * s)], 8, G_HI)   # gold anklets
    # gold breast plate (a pointed shield) and the collar
    tri(gm, (-3.0 * s, y0 + 15.6 * s, 4.9 * s), (3.0 * s, y0 + 15.6 * s, 4.9 * s), (0, y0 + 10.0 * s, 4.4 * s), G_HI, (0, 0.2, 1))
    tri(gm, (-3.0 * s, y0 + 15.6 * s, 4.9 * s), (0, y0 + 10.0 * s, 4.4 * s), (-3.6 * s, y0 + 14.0 * s, 3.4 * s), G_MID, (-0.5, 0.1, 1))
    tri(gm, (3.0 * s, y0 + 15.6 * s, 4.9 * s), (3.6 * s, y0 + 14.0 * s, 3.4 * s), (0, y0 + 10.0 * s, 4.4 * s), G_MID, (0.5, 0.1, 1))
    lathe(gm, 0, 0.6 * s, [(4.3 * s, y0 + 16.2 * s), (4.7 * s, y0 + 16.6 * s), (4.7 * s, y0 + 17.4 * s),
                           (4.1 * s, y0 + 17.8 * s)], 12, G_HI)
    # the head: big and high, the snout forward, the mouth wide open
    hy = y0 + 21.0 * s
    hz = 1.4 * s
    ellipsoid(w, (0, hy, hz), X, Y, Z, 4.0 * s, 3.8 * s, 3.6 * s, WHITE, 12, 8)
    ellipsoid(w, (0, hy - 0.4 * s, hz + 3.0 * s), X, Y, Z, 2.8 * s, 1.6 * s, 2.0 * s, WHITE, 10, 6)   # snout
    ellipsoid(w, (0, hy + 0.2 * s, hz + 4.6 * s), X, Y, Z, 1.0 * s, 0.7 * s, 0.6 * s, (226, 120, 120), 8, 4)  # nose
    lay, laz = tilt(-28)
    obox(w, (0, hy - 3.2 * s, hz + 3.2 * s), X, lay, laz, 2.5 * s, 0.55 * s, 1.9 * s, WHITE)          # lower jaw, dropped
    obox(w, (0, hy - 2.1 * s, hz + 2.8 * s), X, Y, Z, 2.3 * s, 0.9 * s, 1.6 * s, (200, 40, 52))        # the red mouth
    ellipsoid(w, (0, hy - 2.6 * s, hz + 3.6 * s), X, Y, Z, 1.2 * s, 0.35 * s, 1.0 * s, (232, 92, 110), 8, 4)  # tongue
    for sx in (-1, 1):
        for fz in (4.1, 3.0):
            p = (sx * 1.6 * s, hy - 1.6 * s, hz + fz * s)
            tri(w, add(p, (-0.35 * s, 0.25 * s, 0)), add(p, (0.35 * s, 0.25 * s, 0)), add(p, (0, -0.9 * s, 0.1 * s)),
                (250, 250, 246), (0, 0, 1))                                                        # fangs
        ellipsoid(w, (sx * 1.9 * s, hy + 1.3 * s, hz + 3.0 * s), X, Y, Z, 1.0 * s, 0.9 * s, 0.7 * s, (250, 250, 250), 8, 5)
        ellipsoid(w, (sx * 1.95 * s, hy + 1.3 * s, hz + 3.55 * s), X, Y, Z, 0.5 * s, 0.5 * s, 0.25 * s, DARK, 6, 4)
        obox(gm, (sx * 1.9 * s, hy + 2.5 * s, hz + 3.2 * s), X, Y, Z, 1.3 * s, 0.25 * s, 0.4 * s, G_HI)  # brows
        ellipsoid(w, (sx * 3.9 * s, hy + 2.2 * s, hz - 0.4 * s), X, Y, Z, 0.9 * s, 1.5 * s, 0.6 * s, WHITE, 6, 4)  # ears
    # the mane: flame tufts round the face (a ring in the face's plane), white with gold tips, and a tall crest
    n = 14
    for k in range(n):
        a = math.pi * (-0.1 + 1.2 * k / (n - 1))           # from the right cheek over the top to the left cheek
        ca, sa = math.cos(a), math.sin(a)
        r0, r1 = 3.7 * s, 6.3 * s + (0.8 * s if 0.35 < k / (n - 1) < 0.65 else 0.0)
        da = math.pi / n * 0.95
        b0 = (r0 * math.cos(a - da), hy + r0 * math.sin(a - da), hz + 0.6 * s)
        b1 = (r0 * math.cos(a + da), hy + r0 * math.sin(a + da), hz + 0.6 * s)
        tip = (r1 * ca, hy + r1 * sa, hz - 0.4 * s)
        mid = (r0 * 1.2 * ca, hy + r0 * 1.2 * sa, hz - 1.6 * s)
        tri(w, b0, b1, tip, WHITE, (0, 0, 1))
        tri(w, b0, tip, mid, WHITE_SH, (ca, sa, -0.4))
        tri(w, b1, mid, tip, WHITE_SH, (ca, sa, -0.4))
        tip2 = (r1 * 1.08 * ca, hy + r1 * 1.08 * sa, hz - 0.5 * s)
        tri(gm, add(tip, (-0.4 * s * sa, 0.4 * s * ca, 0.08)), add(tip, (0.4 * s * sa, -0.4 * s * ca, 0.08)), tip2, G_HI, (0, 0, 1))
    for k, (cx_, h_) in enumerate(((-1.6, 4.0), (0.0, 5.6), (1.6, 4.0))):
        b = hy + 3.6 * s
        tri(gm, (cx_ * s - 1.0 * s, b, hz - 1.0 * s), (cx_ * s + 1.0 * s, b, hz - 1.0 * s), (cx_ * s, b + h_ * s, hz - 1.6 * s),
            G_HI, (0, 0.3, 1))
        tri(gm, (cx_ * s + 1.0 * s, b, hz - 1.0 * s), (cx_ * s - 1.0 * s, b, hz - 1.0 * s), (cx_ * s, b + h_ * s, hz - 1.6 * s),
            G_MID, (0, 0.3, -1))
    # the tail: an S rising behind, a gold flame at its tip
    prev = None
    for k in range(7):
        a = k / 6.0
        p = (0, y0 + (3.0 + 14.0 * a) * s, (-9.6 - 2.2 * math.sin(a * math.pi)) * s)
        ellipsoid(w, p, X, Y, Z, (1.2 - 0.3 * a) * s, 1.6 * s, (1.2 - 0.3 * a) * s, WHITE, 8, 4)
        prev = p
    for dx in (-0.8, 0.0, 0.8):
        tri(gm, add(prev, (dx * s - 0.7 * s, 1.0 * s, 0)), add(prev, (dx * s + 0.7 * s, 1.0 * s, 0)),
            add(prev, (dx * 1.6 * s, 4.2 * s, -0.6 * s)), G_HI, (0, 0, -1))
        tri(gm, add(prev, (dx * s + 0.7 * s, 1.0 * s, 0)), add(prev, (dx * s - 0.7 * s, 1.0 * s, 0)),
            add(prev, (dx * 1.6 * s, 4.2 * s, -0.6 * s)), G_HI, (0, 0, 1))
    return w, gm


def hipped(w, d, over, rise, rgb=ROOF_RED, trim=GOLD_V):
    """a low hipped roof over a hall (local base y=0): eaves out by `over`, ridge rise. mix mesh."""
    m = Mesh()
    prism(m, rect(w + over, d + over), 0, 0, -0.6, 0.0, trim, top=False, bottom=True)
    frustum(m, rect(w + over, d + over), rect(max(0.6, w * 0.45), max(0.6, d * 0.35)), 0, 0, 0.0, rise, rgb, top=True)
    return m


# ----------------------------------------------------------------------------------------------------- mesh bookkeeping
class Bucket:
    """meshes of one landmark by kind, split before MAX_TRIS"""

    def __init__(self, lid):
        self.lid = lid
        self.parts = {}

    def mesh(self, kind, need=600):
        lst = self.parts.setdefault(kind, [Mesh()])
        if lst[-1].tris + need > MAX_TRIS:
            lst.append(Mesh())
        return lst[-1]

    def named(self):
        out = []
        for kind, lst in self.parts.items():
            for i, m in enumerate(lst):
                if not m.T:
                    continue
                lo, hi = m.box()
                c = [(lo[k] + hi[k]) / 2 for k in range(3)]
                sz = [hi[k] - lo[k] for k in range(3)]
                out.append((code(kind, '%s%d' % (self.lid, i + 1), c, sz), m))
        return out


class Collide:
    def __init__(self):
        self.boxes = []

    def add(self, cx, cy, cz, sx, sy, sz, yaw=0.0, pitch=0.0, tag=''):
        self.boxes.append((cx, cy, cz, sx, sy, sz, yaw, pitch, tag))

    def lua(self):
        """one line a box: `box cx cy cz sx sy sz yaw tag` or `seg ax ay az bx by bz width thickness` (an oriented box
        whose top runs along the line A -> B, for ramps and sloped walls)"""
        out = []
        for b in self.boxes:
            if b[0] == 'seg':
                _, a, c, w, t = b
                out.append('seg %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f' % (a + c + (w, t)))
            else:
                out.append('box %.2f %.2f %.2f %.2f %.2f %.2f %.4f %s' % (b[:7] + (b[8] or 'x',)))
        return '\n'.join(out)


def write(lid, bucket, collide, extra=None):
    os.makedirs(OUT_GLB, exist_ok=True)
    os.makedirs(OUT_DATA, exist_ok=True)
    named = bucket.named()
    for n, m in named:
        assert m.tris <= MAX_TRIS, (n, m.tris)
    path = os.path.join(OUT_GLB, lid + '.glb')
    info = write_glb(path, named, generator='yangon landmarks.py')
    nm, bad = check_glb(path, info)
    assert not bad, bad
    meta = dict(id=lid, glb=path, meshes=[dict(name=k, **v) for k, v in info.items()],
                tris=sum(v['tris'] for v in info.values()))
    if extra:
        meta.update({k: v for k, v in extra.items() if k not in ('grid', 'trees')})
    json.dump(meta, open(os.path.join(OUT_DATA, lid + '.json'), 'w'), indent=1)
    # the Studio data: collision boxes, the hill grid, trees (one Luau module returning a table of strings)
    parts = ['return {', ' id = "%s",' % lid, ' collide = [[\n%s\n]],' % collide.lua()]
    if extra:
        for k, v in extra.items():
            if isinstance(v, str):
                parts.append(' %s = [[\n%s\n]],' % (k, v))
            elif isinstance(v, (int, float)):
                parts.append(' %s = %s,' % (k, repr(v)))
    parts.append('}')
    open(os.path.join(OUT_DATA, lid + '_data.luau'), 'w', encoding='utf-8').write('\n'.join(parts) + '\n')
    print('%s: %d meshes, %d tris, %d collision boxes -> %s' % (lid, len(named), meta['tris'], len(collide.boxes), path))
    for n, m in named:
        print('   %-60s %6d tris' % (n, m.tris))
    return meta


def yaw_to(fx, fz):
    """the yaw that turns local +z (a kit's front) to face (fx, fz)"""
    return math.atan2(-fx, fz)


def smooth(u):
    u = min(1.0, max(0.0, u))
    return u * u * (3 - 2 * u)


# ------------------------------------------------------------------------------------------------- stairway and gate
def stairway(B, col, A3, B3, W, roof_seg=18.0, step_rise=1.2, chinthes=False, gate_tiers=7, gate_H=72.0, rng=None):
    """a covered stairway (zaungdan) from A3 (top, on the platform edge) down to B3 (the foot): steps, white parapets,
    red columns, a two-tier roof stepping down segment by segment (dark red slopes, gold upper tier, ceilings), the gate
    at the foot with its tiered gold roof, two chinthe in front of it when asked. Collision: a ramp, the parapets, the
    gate piers."""
    ax, ay, az = A3
    bx, by, bz = B3
    L = math.hypot(ax - bx, az - bz)
    rise = ay - by
    d = ((ax - bx) / L, (az - bz) / L)           # horizontal unit, foot -> top
    sd = (-d[1], d[0])                           # sideways
    N = max(4, int(math.ceil(rise / step_rise)))
    r = rise / N
    run = L / N
    floor = B.mesh('MIX', 8 * N + 400)

    def P(s, side, y):
        return (bx + d[0] * s + sd[0] * side, y, bz + d[1] * s + sd[1] * side)

    hw = W / 2
    base_drop = 16.0
    for i in range(N):
        s0, s1 = i * run, (i + 1) * run
        y = by + (i + 1) * r
        yl = by + i * r - base_drop
        # tread, riser, the two side faces down to the foundation
        quad(floor, P(s0, -hw, y), P(s1, -hw, y), P(s1, hw, y), P(s0, hw, y), BRICK if (i % 2) else (180, 114, 90), (0, 1, 0))
        quad(floor, P(s0, -hw, y - r), P(s0, hw, y - r), P(s0, hw, y), P(s0, -hw, y), (150, 90, 70), (-d[0], 0, -d[1]))
        for side, sg in ((-hw, -1), (hw, 1)):
            quad(floor, P(s0, side, yl), P(s1, side, yl + r), P(s1, side, y), P(s0, side, y), STONE, (sd[0] * sg, 0, sd[1] * sg))
        # a white centre stair (as at the real south gate): a strip 0.08 over every second tread
        if i % 2 == 0:
            quad(floor, P(s0 + 0.2, -2.2, y + 0.08), P(s1 - 0.2, -2.2, y + 0.08), P(s1 - 0.2, 2.2, y + 0.08),
                 P(s0 + 0.2, 2.2, y + 0.08), WHITE, (0, 1, 0))
    # parapets: sloped white walls on both sides (oriented boxes)
    along = unit((d[0] * L, rise, d[1] * L))
    upv = unit(cross((sd[0], 0, sd[1]), along))
    if upv[1] < 0:
        upv = mul(upv, -1)
    slen = math.sqrt(L * L + rise * rise)
    wall = B.mesh('WHITE', 200)
    for side in (-hw - 0.6, hw + 0.6):
        c = add(P(L / 2, side, (ay + by) / 2 + r), mul(upv, 1.0))
        obox(wall, c, along, upv, (sd[0], 0, sd[1]), slen / 2, 2.2, 0.7, WHITE)
        col.boxes.append(('seg', P(L, side, ay + r + 3.2), P(0, side, by + r + 3.2), 1.4, 6.0))
    # the walking ramp (top on the nosing line, minus half a step)
    col.boxes.append(('seg', (ax, ay + r * 0.5, az), (bx, by + r * 0.5, bz), W, 3.0))
    # columns and roof segments
    nseg = max(1, int(round(L / roof_seg)))
    seg = L / nseg
    red = B.mesh('MIX', 3000)
    gold = B.mesh('GOLD', 3000)

    def yline(s):
        return by + r + rise * s / L

    for k in range(nseg + 1):
        s = k * seg
        yb = yline(min(L, s + 0.01))
        for side in (-hw - 0.6, hw + 0.6):
            p = P(s, side, 0)
            box(red, p[0], yb + 8.5, p[2], 1.7, 17.0, 1.7, RED, yaw=yaw_to(d[0], d[1]))
            box(gold, p[0], yb + 0.8, p[2], 2.4, 1.6, 2.4, G_HI, yaw=yaw_to(d[0], d[1]))
            box(gold, p[0], yb + 16.4, p[2], 2.2, 1.2, 2.2, G_HI, yaw=yaw_to(d[0], d[1]))
    for k in range(nseg):
        s0, s1 = k * seg, (k + 1) * seg
        yr = yline(s1) + 17.0
        ov = 3.2
        e = hw + ov
        ridge = 6.0
        # lower gable: two slopes, two gable ends (both faces), the ceiling (facing down), the gold eave line
        quad(red, P(s0, -e, yr), P(s1, -e, yr), P(s1, 0, yr + ridge), P(s0, 0, yr + ridge), ROOF_RED, None)
        _fix_up(red)
        quad(red, P(s0, e, yr), P(s0, 0, yr + ridge), P(s1, 0, yr + ridge), P(s1, e, yr), ROOF_RED, None)
        _fix_up(red)
        for s in (s0, s1):
            for sg in (1, -1):
                tri(red, P(s, -e, yr), P(s, e, yr), P(s, 0, yr + ridge), (150, 46, 34), (d[0] * sg, 0, d[1] * sg))
        quad(red, P(s0, -e, yr - 0.05), P(s1, -e, yr - 0.05), P(s1, e, yr - 0.05), P(s0, e, yr - 0.05), (96, 40, 30), (0, -1, 0))
        for side in (-e, e):
            p0, p1 = P(s0, side, yr - 0.6), P(s1, side, yr - 0.6)
            obox(gold, mul(add(p0, p1), 0.5), (d[0], 0, d[1]), (0, 1, 0), (sd[0], 0, sd[1]), seg / 2, 0.6, 0.35, G_HI)
        # upper tier: a neck and a small gold gable
        nh = 3.0
        uw = hw * 0.55
        yu = yr + ridge * (1 - uw / e) + nh * 0.2
        for side in (-uw, uw):
            p0, p1 = P(s0 + 1, side, yu + nh / 2), P(s1 - 1, side, yu + nh / 2)
            obox(red, mul(add(p0, p1), 0.5), (d[0], 0, d[1]), (0, 1, 0), (sd[0], 0, sd[1]), (seg - 2) / 2, nh / 2, 0.3, RED_DK)
        yu2 = yu + nh
        ue = uw + 2.0
        quad(red, P(s0 + 0.5, -ue, yu2), P(s1 - 0.5, -ue, yu2), P(s1 - 0.5, 0, yu2 + 4.0), P(s0 + 0.5, 0, yu2 + 4.0), ROOF_RED, None)
        _fix_up(red)
        quad(red, P(s0 + 0.5, ue, yu2), P(s0 + 0.5, 0, yu2 + 4.0), P(s1 - 0.5, 0, yu2 + 4.0), P(s1 - 0.5, ue, yu2), ROOF_RED, None)
        _fix_up(red)
        rp0, rp1 = P(s0 + 0.5, 0, yu2 + 4.1), P(s1 - 0.5, 0, yu2 + 4.1)
        obox(gold, mul(add(rp0, rp1), 0.5), (d[0], 0, d[1]), (0, 1, 0), (sd[0], 0, sd[1]), (seg - 1) / 2, 0.4, 0.5, G_HI)
        for s in (s0 + 0.5, s1 - 0.5):
            for sg in (1, -1):
                tri(gold, P(s, -ue, yu2), P(s, ue, yu2), P(s, 0, yu2 + 4.0), G_MID, (d[0] * sg, 0, d[1] * sg))
        # a finial on the upper ridge's high end
        tp = P(s1 - 0.5, 0, yu2 + 4.0)
        lathe(gold, tp[0], tp[2], [(0.9, tp[1]), (0.5, tp[1] + 1.6), (0.15, tp[1] + 4.5), (0.0, tp[1] + 6.0)], 6, G_HI)
    # the gate at the foot: piers, lintel, a hipped roof and a tiered gold pyatthat, facing out (away from the top)
    gy = by
    gw = hw + 12.0
    gd = 13.0
    gyaw = yaw_to(-d[0], -d[1])
    gc = P(-6.0, 0, gy)
    gate = B.mesh('WHITE', 900)
    gwht, ggld, gmix = gatehouse(hw, gd, gate_tiers, gate_H)
    place(gate, gwht, gc[0], gy, gc[2], gyaw)
    place(gold, ggld, gc[0], gy, gc[2], gyaw)
    place(red, gmix, gc[0], gy, gc[2], gyaw)
    for sg in (-1, 1):
        p = P(-6.0, sg * (hw + 6.0), gy)
        col.boxes.append((p[0], gy + 11.0, p[2], 12.0, 30.0, 2 * gd, gyaw, 0.0, 'gate'))
    col.boxes.append((gc[0], gy + 22.0, gc[2], 2 * hw, 8.0, 2 * gd, gyaw, 0.0, 'gate'))
    box(floor, gc[0], gy + 0.2, gc[2], 2 * hw, 0.4, 2 * gd, BRICK, yaw=gyaw)
    if chinthes:
        cw, cg = chinthe(30.0)
        for sg in (-1, 1):
            p = P(-30.0, sg * (hw + 22.0), gy)
            place(wall, cw, p[0], gy, p[2], gyaw)
            place(gold, cg, p[0], gy, p[2], gyaw)
            col.boxes.append((p[0], gy + 15.0, p[2], 18.0, 30.0, 24.0, gyaw, 0.0, 'chinthe'))
    return dict(top=A3, foot=B3, steps=N, length=round(L, 1), rise=round(rise, 1), gate=gc)


def gatehouse(hw, gd, tiers, H):
    """a stairway gate (local: front +z = outward, base y=0, passage 2*hw wide, depth 2*gd): white piers with gold edges,
    a gold frame round the passage, a gable roof along the stair (green slopes, gold-bordered gable ends front and back,
    a red ceiling) and a tall gold pyatthat. Returns (white, gold, mix)."""
    wm, gm, xm = Mesh(), Mesh(), Mesh()
    ph = 18.0
    pw = 12.0
    for sg in (-1, 1):
        x = sg * (hw + pw / 2)
        box(wm, x, 11.0, 0, pw, 30.0, 2 * gd, WHITE)
        for zf in (1, -1):
            # gold edge strips on the front / back faces (0.1 proud), a gold base band
            box(gm, sg * (hw + pw - 0.5), 11.5, zf * (gd + 0.06), 1.0, 29.0, 0.12, G_HI)
            box(gm, sg * (hw + 0.5), ph / 2, zf * (gd + 0.06), 1.0, ph, 0.12, G_HI)
        box(gm, x, 1.0, 0, pw + 0.3, 2.0, 2 * gd + 0.3, G_HI)
        # a niche with a guardian figure's outline on the pier's front: dark arch panel
        for zf in (1, -1):
            z = zf * (gd + 0.07)
            a0, a1 = sg * (hw + 3.0), sg * (hw + pw - 3.0)
            quad(xm, (a0, 4.0, z), (a1, 4.0, z), (a1, 13.0, z), (a0, 13.0, z), (120, 36, 30), (0, 0, zf))
            tri(xm, (a0, 13.0, z), (a1, 13.0, z), ((a0 + a1) / 2, 17.0, z), (120, 36, 30), (0, 0, zf))
    box(wm, 0, (ph + 26.0) / 2, 0, 2 * hw, 26.0 - ph, 2 * gd, WHITE)                  # the lintel
    fan(wm, [(hw, ph, gd), (-hw, ph, gd), (-hw, ph, -gd), (hw, ph, -gd)], (122, 32, 26), (0, -1, 0), (0, ph, 0))
    for zf in (1, -1):
        box(gm, 0, ph + 0.5, zf * (gd + 0.06), 2 * hw + 2.0, 1.0, 0.12, G_HI)             # gold lintel edge
        box(gm, 0, 25.4, zf * (gd + 0.06), 2 * (hw + pw), 1.2, 0.12, G_HI)               # cornice
        # a pointed pediment outline over the passage
        z = zf * (gd + 0.08)
        for sg in (-1, 1):
            a = (sg * (hw - 1.0), ph + 1.0, z)
            b = (0.0, 24.6, z)
            nx, ny = -(b[1] - a[1]), (b[0] - a[0])
            l = math.hypot(nx, ny)
            nx, ny = nx / l * 0.6, ny / l * 0.6
            quad(gm, (a[0] - nx, a[1] - ny, z), (b[0] - nx, b[1] - ny, z), (b[0] + nx, b[1] + ny, z),
                 (a[0] + nx, a[1] + ny, z), G_HI, (0, 0, zf))
    # the gable roof along the stair: eaves at 26, ridge at 37
    e = hw + pw + 3.0
    zl = gd + 4.0
    for sg in (-1, 1):
        a, b = (sg * e, 26.0, -zl), (sg * e, 26.0, zl)
        c, d_ = (0.0, 37.0, zl), (0.0, 37.0, -zl)
        quad(xm, a, b, c, d_, ROOF_GREEN, (sg * 0.7, 1, 0))
        quad(xm, a, b, c, d_, (96, 40, 30), (-sg * 0.7, -1, 0))                            # underside
        box(gm, sg * e, 25.7, 0, 0.8, 0.6, 2 * zl, G_HI)                                    # eave trim
    box(gm, 0, 37.2, 0, 1.0, 0.8, 2 * zl, G_HI)                                              # ridge
    for zf in (1, -1):
        z = zf * zl
        tri(gm, (-e, 26.0, z), (e, 26.0, z), (0, 37.0, z), G_HI, (0, 0, zf))
        tri(xm, (-e * 0.8, 27.2, z + zf * 0.1), (e * 0.8, 27.2, z + zf * 0.1), (0, 35.2, z + zf * 0.1), ROOF_GREEN, (0, 0, zf))
        tri(gm, (-e * 0.25, 28.0, z + zf * 0.2), (e * 0.25, 28.0, z + zf * 0.2), (0, 33.5, z + zf * 0.2), G_HI, (0, 0, zf))
        # finials on the gable's peak and ends
        for px_, py_, hh in ((0.0, 37.0, 6.0), (-e, 26.0, 3.5), (e, 26.0, 3.5)):
            tri(gm, (px_ - 0.7, py_, z), (px_ + 0.7, py_, z), (px_ + (0.8 if px_ > 0 else -0.8 if px_ < 0 else 0), py_ + hh, z),
                G_HI, (0, 0, zf))
    pg, px = pyatthat(min(hw + pw, gd + 2.0) * 0.8, tiers, H)
    place(gm, pg, 0, 33.0, 0)
    place(xm, px, 0, 33.0, 0)
    return wm, gm, xm


def _fix_up(m):
    """make the last two triangles face up (roof slopes given in any order)"""
    for t in range(len(m.T) // 3 - 2, len(m.T) // 3):
        i = m.T[3 * t]
        a, b, c = m.P[i], m.P[i + 1], m.P[i + 2]
        n = cross(sub(b, a), sub(c, a))
        if n[1] < 0:
            m.P[i + 1], m.P[i + 2] = m.P[i + 2], m.P[i + 1]
            m.U[i + 1], m.U[i + 2] = m.U[i + 2], m.U[i + 1]
            n = mul(n, -1)
        nn = unit(n)
        m.N[i] = m.N[i + 1] = m.N[i + 2] = nn


# ------------------------------------------------------------------------------------- the great zedi profile (metres)
# Shwedagon's: plinth 6.4 m, 3 redented square terraces, 5 octagonal ones to 21.4 m; then the lathe profile below.
ZEDI_TIERS = [('sq', 54.0, 0.0, 6.4, 3), ('sq', 44.0, 6.4, 8.6, 3), ('sq', 40.0, 8.6, 10.8, 3), ('sq', 36.5, 10.8, 13.0, 2),
              ('oct', 33.0, 13.0, 14.8, 8), ('oct', 30.5, 14.8, 16.6, 8), ('oct', 28.0, 16.6, 18.4, 8),
              ('oct', 26.0, 18.4, 20.0, 16), ('oct', 24.6, 20.0, 21.4, 32)]


def zedi_profile():
    # the bell, turban bands, alms bowl, lotus, banana bud, hti (metres; r, h). Proportions measured on the reference
    # photos (night view from the east, the platform view): bell 22-38 m, the ring cone 38-66 m, bud 66-81 m, hti 81-93 m;
    # widths against the bell's base (bell top 0.76, cone top 0.32, bud 0.24, hti 0.17).
    prof = [(24.4, 21.4), (24.4, 22.0), (21.8, 22.0)]
    for k in range(1, 11):
        t = k / 10
        prof.append((21.8 - 5.2 * t ** 1.5, 22.0 + 15.6 * t))
    prof += [(17.3, 37.6), (17.3, 38.4), (15.6, 38.4)]
    rb = [15.6 - 6.2 * k / 7 for k in range(8)]
    for k in range(7):
        y, hh = 38.4 + 10.6 * k / 7, 10.6 / 7
        prof += [(rb[k] + 0.5, y + 0.3 * hh), (rb[k] + 0.5, y + 0.72 * hh), (rb[k + 1], y + hh)]
    prof += [(10.0, 49.6), (10.3, 50.8), (10.0, 52.0), (9.0, 52.8), (7.8, 53.2), (7.8, 53.6), (7.3, 53.6),
             (6.9, 56.4), (7.2, 56.7), (7.2, 57.3), (6.6, 57.6), (6.9, 57.9), (6.9, 58.6), (6.2, 58.6), (5.4, 62.0),
             (5.6, 62.4), (5.6, 63.0), (5.0, 63.3), (5.2, 63.6), (5.2, 64.4), (4.8, 64.6), (4.8, 66.0),
             (5.1, 67.2), (5.25, 68.6), (5.0, 70.6), (4.4, 72.8), (3.7, 74.8), (2.9, 76.8), (2.1, 78.8), (1.5, 80.4),
             (1.25, 81.0), (1.6, 81.1)]
    for k in range(8):
        y, hh = 81.1 + 11.9 * k / 8, 11.9 / 8
        rk = 3.8 - 2.6 * k / 7
        prof += [(rk * 0.78, y + 0.05), (rk, y + 0.3 * hh), (rk * 0.94, y + 0.62 * hh), (rk * 0.72, y + hh)]
    prof += [(0.42, 93.1), (0.3, 93.3), (0.3, 96.5), (0.0, 96.55)]
    return prof


# ------------------------------------------------------------------------------------------------------ Shwedagon
SHW = dict(
    centre=(31636.0, 3830.0),   # the middle of OSM's ring of 64 small pagodas (buildings 4444702xx) = the stupa's axis
    Y0=93.0,                    # the platform top: 58 m (the real platform; raw SRTM at its edges 56-58 m) x 1.6
    SH=2.3,                     # stupa studs a metre across (SV = 3 up): the photos' silhouette, a touch taller
    # the platform: an axis-aligned octagon round the stupa (real 275 m N-S x 215 m E-W; OSM's landuse 449 x 512)
    plat=(-235.0, -285.0, 235.0, 215.0, 72.0),
    # the four stairways from OSM (highway=steps, relative to the centre): top on the platform's edge, foot
    stairs=dict(S=((62.5, 215.0), (133.0, 469.0), 26.0), N=((-55.5, -285.0), (-83.0, -440.0), 22.0),
                E=((235.0, -50.5), (493.0, -105.0), 22.0), W=((-235.0, 63.5), (-445.0, 118.0), 22.0)),
)


def plat_poly(p):
    x0, z0, x1, z1, c = p
    return [(x1, z1 - c), (x1, z0 + c), (x1 - c, z0), (x0 + c, z0), (x0, z0 + c), (x0, z1 - c), (x0 + c, z1), (x1 - c, z1)]


def _seg_dist(px, pz, a, b):
    ex, ez = b[0] - a[0], b[1] - a[1]
    L2 = ex * ex + ez * ez
    t = max(0.0, min(1.0, ((px - a[0]) * ex + (pz - a[1]) * ez) / L2))
    qx, qz = a[0] + ex * t, a[1] + ez * t
    return math.hypot(px - qx, pz - qz), t


def shwedagon():
    import numpy as np
    from shapely.geometry import Polygon, Point
    import ground
    cfg = SHW
    cx, cz = cfg['centre']
    Y0, SH = cfg['Y0'], cfg['SH']
    rng = random.Random(1453)
    B = Bucket('shw')
    col = Collide()

    def yh(h):
        return Y0 + SV * h

    def R(rm):
        return SH * rm

    # ---- the stupa (GOLD): plinth, 3 redented square terraces, 5 octagonal terraces, the bell and everything above
    g = B.mesh('GOLD', 12000)
    tiers = ZEDI_TIERS
    for kind, a, h0, h1, n in tiers:
        if kind == 'sq':
            poly = redent(R(a), R(a) * 0.075, n)
        else:
            poly = ngon(R(a) / math.cos(math.pi / n), n, math.pi / n)
        prism(g, poly, cx, cz, yh(h0), yh(h1), G_MID, top=True, rgb_top=G_HI)
        # a moulding lip round each terrace's top edge (reads as the stepped bands in photos)
        lip = scale2(poly, 1.0 + 0.5 / R(a))
        prism(g, lip, cx, cz, yh(h1) - 0.9, yh(h1) - 0.1, G_LO, top=False)
    # the plinth's faces: a base band, pilasters and pointed niches (dark gold) along each side's straight run
    a = R(54.0)
    run = a - 3 * R(54.0) * 0.075
    prism(g, scale2(redent(a, a * 0.075, 3), 1.0 + 1.2 / a), cx, cz, Y0, Y0 + 2.4, G_LO, top=True)
    for q in range(4):
        ang = q * math.pi / 2
        c, s_ = math.cos(ang), math.sin(ang)

        def W(x, y, z):
            return (cx + x * c - z * s_, y, cz + x * s_ + z * c)

        out = (c, 0, s_)
        t = -run + 8.0
        k = 0
        while t <= run - 8.0 + 0.01:
            # pilaster (proud 0.8), its capital
            px0, pz0 = a, t
            obox(g, W(a + 0.4, Y0 + 9.6, t), out, (0, 1, 0), (-s_, 0, c), 0.4, 7.2, 1.1, G_MID)
            if k % 1 == 0 and t + 8.0 <= run - 4.0:
                zc = t + 8.0
                y0n, y1n, y2n = Y0 + 3.6, Y0 + 12.0, Y0 + 15.6
                quad(g, W(a + 0.1, y0n, zc - 3.2), W(a + 0.1, y0n, zc + 3.2), W(a + 0.1, y1n, zc + 3.2), W(a + 0.1, y1n, zc - 3.2),
                     (120, 92, 46), out)
                tri(g, W(a + 0.1, y1n, zc - 3.2), W(a + 0.1, y1n, zc + 3.2), W(a + 0.1, y2n, zc), (120, 92, 46), out)
                # a gold seated figure's glint in the niche
                obox(g, W(a + 0.5, Y0 + 6.4, zc), out, (0, 1, 0), (-s_, 0, c), 0.4, 2.8, 1.4, G_HI)
            t += 16.0
            k += 1
    prof = zedi_profile()
    lathe(g, cx, cz, [(R(r_), yh(h_)) for r_, h_ in prof], 48, G_HI)
    # petals: 16 big ones on the bell's shoulder, then the lotus bands (down, up)
    crown(g, cx, cz, yh(34.6), yh(37.6), R(16.9), R(17.7), 16, G_MID, up=False)
    crown(g, cx, cz, yh(53.6), yh(56.4), R(7.1), R(8.1), 24, G_HI, up=False)
    crown(g, cx, cz, yh(58.6), yh(62.0), R(6.0), R(7.0), 24, G_HI, up=True)
    # the vane (hngetmana) and the diamond orb (seinbu) at the very top
    yv0, yv1 = yh(93.6), yh(95.2)
    fw = R(3.0)
    for off, nrm in ((0.06, (0, 0, 1)), (-0.06, (0, 0, -1))):
        quad(g, (cx + 0.3, yv0, cz + off), (cx + fw, yv0 + 0.6, cz + off), (cx + fw, yv1 - 0.4, cz + off),
             (cx + 0.3, yv1, cz + off), G_HI, nrm)
    sphere(g, cx, yh(97.6), cz, R(1.2), G_HI, 16, 10)
    top_y = yh(97.6) + R(1.2)
    # collision: plinth, terraces, the bell's lower half (nobody walks on them; keeps players and cars out)
    for kind, a, h0, h1, n in tiers[:4]:
        col.add(cx, (yh(h0) + yh(h1)) / 2, cz, 2 * R(a), yh(h1) - yh(h0), 2 * R(a), 0, 0, 'stupa')
    col.add(cx, (yh(13.0) + yh(21.4)) / 2, cz, 2 * R(30.0), yh(21.4) - yh(13.0), 2 * R(30.0), 0, 0, 'stupa')
    col.add(cx, (yh(21.4) + yh(40.0)) / 2, cz, 2 * R(19.0), yh(40.0) - yh(21.4), 2 * R(19.0), 0, 0, 'stupa')

    # ---- 64 small pagodas on the plinth, 4 larger ones at the cardinal points
    ring = R(54.0) - 8.0
    small = zedi(27.0, 4.3)
    big = zedi(45.0, 7.5)
    spots = []
    sp = 2 * ring / 15
    for q in range(4):
        a = q * math.pi / 2
        c, s = math.cos(a), math.sin(a)
        for i in range(16):
            t = -ring + i * sp
            if abs(t) < sp * 0.9:
                continue  # the middle: the big pagoda
            x, z = ring, t
            spots.append((x * c - z * s, x * s + z * c))
        # two more on each corner's diagonal, inside the ring
        for k in (1, 2):
            dd = ring - k * 11.0
            x, z = dd * math.cos(math.pi / 4 + a) * math.sqrt(2), dd * math.sin(math.pi / 4 + a) * math.sqrt(2)
            spots.append((x * 0.72, z * 0.72))
    spots = spots[:64]
    for i, (x, z) in enumerate(spots):
        place(B.mesh('GOLD', small.tris), small, cx + x, yh(6.4), cz + z, 0.0)
    for q in range(4):
        a = q * math.pi / 2
        place(B.mesh('GOLD', big.tris), big, cx + math.cos(a) * (ring - 4), yh(6.4), cz + math.sin(a) * (ring - 4), 0.0)

    # ---- the platform: marble slab with a stone retaining wall, a dark red band round the stupa, teal walkways
    P8 = plat_poly(cfg['plat'])
    pl = B.mesh('STONE', 400)
    prism(pl, P8, cx, cz, Y0 - 30.0, Y0, STONE, top=True, rgb_top=MARBLE)
    prism(pl, scale2(P8, 1.0), cx, cz, Y0 - 0.8, Y0 + 0.9, WHITE, top=False)  # the edge kerb (over the slab's top edge)
    # parapet rim (white, low) round the edge, 0.9 over the floor: as a ring inside the kerb
    band_in = ngon(R(54.0) + 34.0, 8, math.pi / 8)
    band_out = ngon(R(54.0) + 40.0, 8, math.pi / 8)
    for i in range(8):
        j = (i + 1) % 8
        a0, a1 = band_in[i], band_in[j]
        b0, b1 = band_out[i], band_out[j]
        quad(pl, (cx + a0[0], Y0 + 0.08, cz + a0[1]), (cx + a1[0], Y0 + 0.08, cz + a1[1]),
             (cx + b1[0], Y0 + 0.08, cz + b1[1]), (cx + b0[0], Y0 + 0.08, cz + b0[1]), MARBLE_BAND, (0, 1, 0))
    st = cfg['stairs']
    for key, (A, Bf, W) in st.items():
        # a teal walkway from the band to the stairway's top
        ux, uz = A[0], A[1]
        l = math.hypot(ux, uz)
        ux, uz = ux / l, uz / l
        s0 = R(54.0) + 40.0
        sx, sz = -uz, ux
        hwk = 5.0
        p0 = (cx + ux * s0 + sx * hwk, cz + uz * s0 + sz * hwk)
        p1 = (cx + A[0] + sx * hwk, cz + A[1] + sz * hwk)
        p2 = (cx + A[0] - sx * hwk, cz + A[1] - sz * hwk)
        p3 = (cx + ux * s0 - sx * hwk, cz + uz * s0 - sz * hwk)
        quad(pl, (p0[0], Y0 + 0.08, p0[1]), (p1[0], Y0 + 0.08, p1[1]), (p2[0], Y0 + 0.08, p2[1]), (p3[0], Y0 + 0.08, p3[1]),
             MARBLE_TEAL, (0, 1, 0))
    # platform collision (an octagon as 3 boxes), its top at Y0
    x0, z0, x1, z1, ch = cfg['plat']
    col.add(cx + (x0 + x1) / 2, Y0 - 3, cz + (z0 + z1) / 2, x1 - x0, 6, (z1 - z0) - 2 * ch, 0, 0, 'platform')
    col.add(cx + (x0 + x1) / 2, Y0 - 3, cz + z0 + ch / 2, (x1 - x0) - 2 * ch, 6, ch, 0, 0, 'platform')
    col.add(cx + (x0 + x1) / 2, Y0 - 3, cz + z1 - ch / 2, (x1 - x0) - 2 * ch, 6, ch, 0, 0, 'platform')
    col.add(cx + (x0 + x1) / 2, Y0 - 3, cz + z0 + ch * 0.75, (x1 - x0) - ch, 6, ch / 2, 0, 0, 'platform')
    col.add(cx + (x0 + x1) / 2, Y0 - 3, cz + z1 - ch * 0.75, (x1 - x0) - ch, 6, ch / 2, 0, 0, 'platform')

    # ---- the four cardinal shrine halls against the plinth, facing the stairways
    for key, (A, Bf, W) in st.items():
        ux, uz = {'S': (0, 1), 'N': (0, -1), 'E': (1, 0), 'W': (-1, 0)}[key]
        hd = 15.0
        hw_ = 21.0
        dist = R(54.0) + hd + 1.0
        hx, hz = cx + ux * dist, cz + uz * dist
        yaw = yaw_to(ux, uz)
        place(B.mesh('MIX', 700), hall(hw_, hd, 24.0, wall=(200, 46, 38), col=RED, trim=GOLD_V), hx, Y0, hz, yaw)
        place(B.mesh('MIX', 100), hipped(hw_, hd, 3.5, 4.0, ROOF_RED), hx, Y0 + 24.0, hz, yaw)
        pg, px = pyatthat(hw_ * 0.62, 9, 96.0)
        place(B.mesh('GOLD', pg.tris), pg, hx, Y0 + 28.0, hz, yaw)
        place(B.mesh('MIX', px.tris), px, hx, Y0 + 28.0, hz, yaw)
        col.add(hx, Y0 + 12.5, hz, 2 * hw_ + 2, 25.0, 2 * hd + 2, yaw, 0, 'hall')

    # ---- the ring of tazaung halls along the platform's edge (facing the stupa), pagodas in the wide corners
    tops = [(cx + A[0], cz + A[1]) for (A, Bf, W) in st.values()]
    halls = 0
    P8w = [(cx + x, cz + z) for x, z in P8]
    for i in range(len(P8w)):
        a, b = P8w[i], P8w[(i + 1) % len(P8w)]
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        ex, ez = (b[0] - a[0]) / L, (b[1] - a[1]) / L
        nx, nz = -ez, ex                              # one of the normals: pick the inward one
        mx, mz = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
        if (cx - mx) * nx + (cz - mz) * nz < 0:
            nx, nz = -nx, -nz
        s = 4.0
        while True:
            hw_ = rng.choice((10.0, 12.0, 13.0, 15.0, 17.0))
            if s + 2 * hw_ > L - 8.0:
                break
            m = s + hw_
            hd = rng.choice((10.0, 11.0, 13.0))
            px_, pz_ = a[0] + ex * m + nx * (hd + 3.0), a[1] + ez * m + nz * (hd + 3.0)
            if min(math.hypot(px_ - t[0], pz_ - t[1]) for t in tops) < 34.0 + hw_:
                s += 2 * hw_ + 6.0
                continue
            yaw = yaw_to(nx, nz)
            eh = rng.choice((15.0, 16.0, 18.0))
            red_roof = rng.random() < 0.3
            white = rng.random() < 0.5
            body = hall(hw_, hd, eh, wall=WHITE if white else (196, 44, 36), col=RED if not white else (230, 226, 216),
                        trim=GOLD_V)
            place(B.mesh('MIX', body.tris), body, px_, Y0, pz_, yaw)
            place(B.mesh('MIX', 100), hipped(hw_, hd, 2.5, 3.0, ROOF_RED if red_roof else ROOF_GREEN), px_, Y0 + eh, pz_, yaw)
            tiers_n = rng.choice((3, 5, 5, 7, 7))
            H = rng.uniform(30.0, 46.0) + tiers_n * 4.0
            pg, px = pyatthat(min(hw_, hd) * 0.8, tiers_n, H, roof=ROOF_RED if red_roof else G_HI, trim=G_HI)
            place(B.mesh('GOLD', pg.tris), pg, px_, Y0 + eh + 3.0, pz_, yaw)
            place(B.mesh('MIX', px.tris), px, px_, Y0 + eh + 3.0, pz_, yaw)
            col.add(px_, Y0 + eh / 2, pz_, 2 * hw_ + 2, eh, 2 * hd + 2, yaw, 0, 'hall')
            halls += 1
            s += 2 * hw_ + rng.choice((2.5, 3.5, 5.0))
    # an inner ring between the halls and the stupa: small pavilions and pagodas (gold and white), off the walkways
    pag = 0
    pav = 0
    x0_, z0_, x1_, z1_, ch_ = cfg['plat']
    inset = 52.0
    ring_p = plat_poly((x0_ + inset, z0_ + inset, x1_ - inset, z1_ - inset, ch_ * 0.6))
    walk = [(0.0, 0.0, A[0], A[1]) for (A, Bf, W) in st.values()]
    k = 0
    for i in range(len(ring_p)):
        a_, b_ = ring_p[i], ring_p[(i + 1) % len(ring_p)]
        L = math.hypot(b_[0] - a_[0], b_[1] - a_[1])
        nst = max(1, int(L // 24.0))
        for j in range(nst):
            t = (j + 0.5) / nst
            x, z = a_[0] + (b_[0] - a_[0]) * t, a_[1] + (b_[1] - a_[1]) * t
            if min(_seg_dist(x, z, (w_[0], w_[1]), (w_[2], w_[3]))[0] for w_ in walk) < 26.0:
                continue
            if abs(x) < R(54.0) + 40 and abs(z) < R(54.0) + 40:
                continue
            k += 1
            if k % 3 == 0:
                gold_ = (k // 3) % 2 == 0
                Hp = rng.uniform(28.0, 40.0)
                zm = zedi(Hp, Hp * 0.17, gold=gold_, segs=10)
                place(B.mesh('GOLD' if gold_ else 'WHITE', zm.tris), zm, cx + x, Y0, cz + z, 0.0)
                col.add(cx + x, Y0 + Hp * 0.12, cz + z, Hp * 0.34, Hp * 0.24, Hp * 0.34, 0, 0, 'pagoda')
                pag += 1
            else:
                pw_ = rng.choice((5.0, 6.0, 7.0))
                yaw = yaw_to(-x, -z)
                pm = Mesh()
                prism(pm, rect(pw_ + 1.0, pw_ + 1.0), 0, 0, -3.0, 1.2, WHITE)
                for sx in (-1, 1):
                    for sz in (-1, 1):
                        box(pm, sx * pw_ * 0.8, 1.2 + 5.0, sz * pw_ * 0.8, 1.0, 10.0, 1.0, RED)
                prism(pm, rect(pw_, pw_), 0, 0, 10.0, 11.2, GOLD_V, top=False, bottom=True)
                place(B.mesh('MIX', pm.tris), pm, cx + x, Y0, cz + z, yaw)
                pg, px = pyatthat(pw_, rng.choice((3, 5)), rng.uniform(22.0, 32.0),
                                  roof=G_HI if k % 4 else ROOF_RED, trim=G_HI)
                place(B.mesh('GOLD', pg.tris), pg, cx + x, Y0 + 11.2, cz + z, yaw)
                place(B.mesh('MIX', px.tris), px, cx + x, Y0 + 11.2, cz + z, yaw)
                col.add(cx + x, Y0 + 6.0, cz + z, 2 * pw_, 12.0, 2 * pw_, yaw, 0, 'pavilion')
                pav += 1

    # ---- the stairways down Singuttara Hill. No terrain is written here (lead, 14 Nov: the batch 1 terrain step builds
    # the hill from SRTM and flattens under the platform outline recorded in build/landmarks/shw.json). The feet stand
    # at the raw SRTM height x 1.6 (the same field that puts the platform's edges at 56-58 m).
    stairs_out = {}
    for key, (A, Bf, W) in st.items():
        Ax, Az = cx + A[0], cz + A[1]
        Bx, Bz = cx + Bf[0], cz + Bf[1]
        yB = round(srtm_y(Bx, Bz), 2)
        stairs_out[key] = stairway(B, col, (Ax, Y0, Az), (Bx, yB, Bz), W, chinthes=(key == 'S'), rng=rng)
    outline = [[round(cx + x, 1), round(cz + z, 1)] for x, z in P8]
    meta = write('shw', B, col, dict(Y0=Y0, top=round(top_y, 1), cx=cx, cz=cz))
    meta.update(stairs={k: dict(top=v['top'], foot=v['foot'], steps=v['steps'], length=v['length'], rise=v['rise'])
                        for k, v in stairs_out.items()},
                platform_y=Y0, platform_outline=outline, platform_slab_bottom=Y0 - 30.0,
                halls=halls + 4, pavilions=pav, pagodas=len(spots) + 4 + pag, top=top_y, Y0=Y0)
    json.dump(meta, open(os.path.join(OUT_DATA, 'shw.json'), 'w'), indent=1)
    print('Shwedagon: platform y %.1f, top y %.1f (%.1f over the platform), %d halls, %d pagodas; stairs %s' % (
        Y0, top_y, top_y - Y0, halls + 4, meta['pagodas'],
        {k: (v['steps'], v['length'], v['rise'], v['foot']) for k, v in stairs_out.items()}))
    print('platform outline (world x, z):', outline)
    return meta


_DEM = None


def srtm_y(x, z):
    """the raw SRTM 30 m height (build/city/dem_ygn.json, bilinear) x 1.6 studs a metre (ground.py's vertical scale,
    without its 3 x 3 minimum and 150 m smoothing, which take Singuttara Hill's top down by about 17 m)"""
    global _DEM
    if _DEM is None:
        d = json.load(open(os.path.join(geo.BUILD, 'city', 'dem_ygn.json')))
        _DEM = d
    d = _DEM
    lo, la = geo.lonlat(x, z)
    fi = (lo - d['lon0']) / d['step']
    fj = (la - d['lat0']) / d['step']
    i, j = int(fi), int(fj)
    a, b = fi - i, fj - j
    h = d['h']
    v = h[j][i] * (1 - a) * (1 - b) + h[j][i + 1] * a * (1 - b) + h[j + 1][i] * (1 - a) * b + h[j + 1][i + 1] * a * b
    return v * 1.6


# --------------------------------------------------------------------------------------------- the other landmarks
def stupa(g, col, cx, cz, y0, Hm, SH, base_k=1.0, bell_k=1.0, octa=False, segs=40, square=True, tiers_from=0):
    """a gilded zedi on Shwedagon's profile scaled to Hm metres: plinth and terraces (base_k widens / narrows them),
    the bell and everything above (bell_k), octagonal all the way up when octa (Sule). Collision boxes for the base.
    Returns the top y."""
    k = Hm / 99.0

    def yh(h):
        return y0 + SV * k * h

    def R(r):
        return SH * k * r

    for i, (kind, a, h0, h1, n) in enumerate(ZEDI_TIERS):
        if i < tiers_from:
            continue
        w = 1.0 + (base_k - 1.0) * (1.0 - i / (len(ZEDI_TIERS) - 1)) if i < len(ZEDI_TIERS) else 1.0
        ra = R(a) * w * (bell_k if i >= 4 else 1.0)
        if octa:
            poly = ngon(ra / math.cos(math.pi / 8), 8, math.pi / 8)
        elif kind == 'sq' and square:
            poly = redent(ra, ra * 0.075, n)
        else:
            nn = 32 if kind == 'sq' else n
            poly = ngon(ra / math.cos(math.pi / nn), nn, math.pi / nn)
        prism(g, poly, cx, cz, yh(h0), yh(h1), G_MID, top=True, rgb_top=G_HI)
        prism(g, scale2(poly, 1.0 + 0.4 / ra), cx, cz, yh(h1) - max(0.4, 0.9 * k), yh(h1) - 0.1, G_LO, top=False)
        if i < 5:
            col.add(cx, (yh(h0) + yh(h1)) / 2, cz, 2 * ra, yh(h1) - yh(h0), 2 * ra, 0, 0, 'stupa')
    prof = zedi_profile()
    bell_end = 66.0
    pts = [(R(r_) * (bell_k if h_ < bell_end else 1.0 + (bell_k - 1.0) * 0.4), yh(h_)) for r_, h_ in prof]
    if octa:
        lathe(g, cx, cz, pts, 8, G_HI, rot=math.pi / 8, crease_deg=30)
    else:
        lathe(g, cx, cz, pts, segs, G_HI)
    crown(g, cx, cz, yh(34.6), yh(37.6), R(16.9) * bell_k, R(17.7) * bell_k, 16, G_MID, up=False)
    crown(g, cx, cz, yh(53.6), yh(56.4), R(7.1) * bell_k, R(8.1) * bell_k, 16, G_HI, up=False)
    crown(g, cx, cz, yh(58.6), yh(62.0), R(6.0) * bell_k, R(7.0) * bell_k, 16, G_HI, up=True)
    yv0, yv1 = yh(93.6), yh(95.2)
    fw = max(2.0, R(3.0))
    for off, nrm in ((0.06, (0, 0, 1)), (-0.06, (0, 0, -1))):
        quad(g, (cx + 0.3, yv0, cz + off), (cx + fw, yv0 + 0.4, cz + off), (cx + fw, yv1 - 0.3, cz + off),
             (cx + 0.3, yv1, cz + off), G_HI, nrm)
    ro = max(0.9, R(1.2))
    sphere(g, cx, yh(97.6), cz, ro, G_HI, 12, 8)
    col.add(cx, (yh(21.4) + yh(40.0)) / 2, cz, 2 * R(19.0) * bell_k, yh(40.0) - yh(21.4), 2 * R(19.0) * bell_k, 0, 0, 'stupa')
    return yh(97.6) + ro


def ground_pad(col, cx, cz, poly, y, depth=14.0, mat='pave'):
    """a pad for terrain under a landmark (the placer fills it): returned as a data line"""
    return '%s %.2f %.2f %.2f %s' % (mat, y, depth, 0.0, ';'.join('%.1f,%.1f' % (cx + x, cz + z) for x, z in poly))


def finish(lid, B, col, pads=None, extra=None):
    ex = dict(extra or {})
    if pads:
        ex['pads'] = '\n'.join(pads)
    return write(lid, B, col, ex)


def maha_wizaya():
    """Maha Wizaya Pagoda (1980s, about 40 m, across U Htaung Bo Road south-east of Shwedagon): a gilded zedi on a
    square white terrace with corner shrines (OSM's 4 small squares at the corners, 126 studs apart), inside a moat with
    green railings and a bridge from the north."""
    cx, cz = 32083.0, 4436.0
    gy = 57.0
    y0 = gy + 6.0
    B = Bucket('wiz')
    col = Collide()
    mix = B.mesh('MIX', 3000)
    # the terrace: white, two steps, a red band; the moat round it (a dark green-blue sheet, its level 2 under the ground)
    prism(mix, rect(70, 70), cx, cz, gy - 10.0, y0 - 3.0, WHITE, rgb_top=MARBLE)
    prism(mix, rect(63, 63), cx, cz, y0 - 3.0, y0, WHITE, rgb_top=MARBLE)
    prism(mix, scale2(rect(70, 70), 1.0), cx, cz, y0 - 3.6, y0 - 3.0 + 0.06, MARBLE_BAND, top=False)
    col.add(cx, y0 - 2.0, cz, 140, 4, 140, 0, 0, 'terrace')
    col.add(cx, y0 - 1.0, cz, 126, 2, 126, 0, 0, 'terrace')
    # railings round the terrace edge (green, low)
    for q in range(4):
        a = q * math.pi / 2
        c, s = math.cos(a), math.sin(a)
        for t in range(-60, 61, 6):
            x, z = 68 * c - t * s, 68 * s + t * c
            box(mix, cx + x, y0 - 3.0 + 1.8, cz + z, 0.6, 3.6, 0.6, (60, 150, 130))
        box(mix, cx + 68 * c, y0 - 3.0 + 3.7, cz + 68 * s, 1.0 if abs(c) > 0.5 else 136, 0.4, 136 if abs(c) > 0.5 else 1.0, (60, 150, 130))
    g = B.mesh('GOLD', 9000)
    top = stupa(g, col, cx, cz, y0, 40.0, 2.4, base_k=0.8, bell_k=1.12)
    # corner shrines: small gold zedis on the terrace corners
    zm = zedi(26.0, 4.4)
    for sx in (-1, 1):
        for sz in (-1, 1):
            place(B.mesh('GOLD', zm.tris), zm, cx + sx * 56, y0, cz + sz * 56, 0.0)
    # four entrance halls (the north one on the bridge's axis) with gold pyatthat roofs
    for q in range(4):
        a = q * math.pi / 2
        ux, uz = math.cos(a), math.sin(a)
        hx, hz = cx + ux * 50, cz + uz * 50
        yaw = yaw_to(-ux, -uz)
        place(B.mesh('MIX', 600), hall(9.0, 6.0, 13.0), hx, y0, hz, yaw)
        pg, px = pyatthat(7.0, 5, 34.0)
        place(B.mesh('GOLD', pg.tris), pg, hx, y0 + 13.0, hz, yaw)
        place(B.mesh('MIX', px.tris), px, hx, y0 + 13.0, hz, yaw)
    pads = [ground_pad(col, cx, cz, rect(110, 110), gy, 16.0, 'grass')]
    meta = finish('wiz', B, col, pads, dict(cx=cx, cz=cz, Y0=y0, top=round(top, 1)))
    print('Maha Wizaya: top %.1f (%.1f over its terrace)' % (top, top - y0))
    return meta


def sule():
    """Sule Pagoda (44 m, octagonal from the base to the bell) in the middle of the Sule roundabout, ringed at street
    level by a ring of one-storey white shophouses with blue awnings and gold pyatthat gates at the four entrances (photos).
    OSM: the stupa's outline 59 studs across at (33200, 8070), the pagoda's ground 150 x 136."""
    cx, cz = 33200.0, 8066.0
    gy = 19.8
    B = Bucket('sule')
    col = Collide()
    g = B.mesh('GOLD', 9000)
    y0 = gy + 13.0                         # the stupa rises from the shops' roof terrace
    top = stupa(g, col, cx, cz, y0, 44.0, 2.3, base_k=0.62, bell_k=1.0, octa=True)
    mix = B.mesh('MIX', 6000)
    wht = B.mesh('WHITE', 3000)
    # the ring of shops: an octagonal ring building, outer radius 66, inner 36, 12 high, flat roof terrace
    ro, ri, h = 66.0, 34.0, 12.0
    Po = ngon(ro / math.cos(math.pi / 8), 8, math.pi / 8)
    Pi = ngon(ri / math.cos(math.pi / 8), 8, math.pi / 8)
    prism(wht, Po, cx, cz, gy - 6.0, gy + h, WHITE, top=False)
    # roof terrace (a ring between the outer and inner octagons) and the inner terrace under the stupa
    for i in range(8):
        j = (i + 1) % 8
        quad(mix, (cx + Pi[i][0], gy + h, cz + Pi[i][1]), (cx + Po[i][0], gy + h, cz + Po[i][1]),
             (cx + Po[j][0], gy + h, cz + Po[j][1]), (cx + Pi[j][0], gy + h, cz + Pi[j][1]), (176, 104, 80), (0, 1, 0))
    prism(mix, Pi, cx, cz, gy + h - 0.5, gy + 13.0, MARBLE)
    # shop fronts: on each of the 8 outer faces, bays with dark doorways and a blue awning, a white parapet with a gold rim
    for i in range(8):
        a, b = Po[i], Po[(i + 1) % 8]
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        ex, ez = (b[0] - a[0]) / L, (b[1] - a[1]) / L
        nx, nz = ez, -ex
        mx, mz = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
        if nx * mx + nz * mz < 0:
            nx, nz = -nx, -nz
        gate = i % 2 == 0     # four gates (every second face)
        nb = 5
        for k in range(nb):
            t0 = (k + 0.12) / nb * L
            t1 = (k + 0.88) / nb * L
            if gate and k == nb // 2:
                continue
            p0 = (cx + a[0] + ex * t0 + nx * 0.08, cz + a[1] + ez * t0 + nz * 0.08)
            p1 = (cx + a[0] + ex * t1 + nx * 0.08, cz + a[1] + ez * t1 + nz * 0.08)
            quad(mix, (p0[0], gy, p0[1]), (p1[0], gy, p1[1]), (p1[0], gy + 6.5, p1[1]), (p0[0], gy + 6.5, p0[1]),
                 (52, 46, 40), (nx, 0, nz))
            # the awning: a sloped blue sheet, its underside
            q0 = (p0[0] + nx * 3.2, p0[1] + nz * 3.2)
            q1 = (p1[0] + nx * 3.2, p1[1] + nz * 3.2)
            quad(mix, (p0[0], gy + 8.6, p0[1]), (p1[0], gy + 8.6, p1[1]), (q1[0], gy + 7.0, q1[1]), (q0[0], gy + 7.0, q0[1]),
                 (40, 110, 196), (nx * 0.5, 1, nz * 0.5))
            quad(mix, (p0[0], gy + 8.6, p0[1]), (p1[0], gy + 8.6, p1[1]), (q1[0], gy + 7.0, q1[1]), (q0[0], gy + 7.0, q0[1]),
                 (30, 80, 150), (-nx * 0.5, -1, -nz * 0.5))
            # a white sign board over the awning (plain, no lettering)
            quad(mix, (p0[0], gy + 9.2, p0[1]), (p1[0], gy + 9.2, p1[1]), (p1[0], gy + 11.2, p1[1]), (p0[0], gy + 11.2, p0[1]),
                 (238, 236, 228), (nx, 0, nz))
        # gold rim on the parapet
        quad(mix, (cx + a[0] + nx * 0.1, gy + h - 0.6, cz + a[1] + nz * 0.1), (cx + b[0] + nx * 0.1, gy + h - 0.6, cz + b[1] + nz * 0.1),
             (cx + b[0] + nx * 0.1, gy + h, cz + b[1] + nz * 0.1), (cx + a[0] + nx * 0.1, gy + h, cz + a[1] + nz * 0.1), GOLD_V, (nx, 0, nz))
        if gate:
            # the entrance: a gate hall straddling the ring with a tall gold pyatthat (the photos' tiered gold gates)
            gx, gz = cx + mx * 1.02, cz + mz * 1.02
            yaw = yaw_to(nx, nz)
            place(B.mesh('MIX', 700), hall(8.0, 6.0, 12.0, wall=(196, 44, 36)), gx, gy, gz, yaw)
            pg, px = pyatthat(7.5, 7, 56.0)
            place(B.mesh('GOLD', pg.tris), pg, gx, gy + 12.0, gz, yaw)
            place(B.mesh('MIX', px.tris), px, gx, gy + 12.0, gz, yaw)
    for i in range(8):
        a, b = Po[i], Po[(i + 1) % 8]
        col.boxes.append(('seg', (cx + a[0], gy + h, cz + a[1]), (cx + b[0], gy + h, cz + b[1]), 4.0, h + 6.0))
    col.add(cx, gy + h / 2, cz, 2 * ri, h, 2 * ri, 0, 0, 'ring')
    # the roundabout's pavement round the ring (a pad)
    pads = [ground_pad(col, cx, cz, ngon(ro + 14.0, 16, 0.0), gy, 14.0, 'pave')]
    meta = finish('sule', B, col, pads, dict(cx=cx, cz=cz, Y0=gy, top=round(top, 1)))
    print('Sule: top %.1f (%.1f over the street)' % (top, top - gy))
    return meta


def botataung():
    """Botataung Pagoda (40 m, gilded, hollow, on the Strand by the river): a broad bell on low octagonal terraces on
    a white marble platform with small shrines and pavilions round it (photos). OSM: outline 46 studs at (35456, 9116),
    the compound 164 x 343 along the Strand."""
    cx, cz = 35456.0, 9116.0
    gy = 13.1
    y0 = gy + 3.0
    B = Bucket('bota')
    col = Collide()
    mix = B.mesh('MIX', 4000)
    plat = plat_poly((-70.0, -80.0, 70.0, 80.0, 24.0))
    prism(mix, plat, cx, cz, gy - 10.0, y0, STONE, rgb_top=MARBLE)
    col.add(cx, y0 - 1.5, cz, 140, 3, 160, 0, 0, 'platform')
    g = B.mesh('GOLD', 9000)
    top = stupa(g, col, cx, cz, y0, 40.0, 2.3, base_k=0.62, bell_k=1.25, segs=36)
    rng = random.Random(77)
    # shrines round the stupa on the platform
    for k in range(10):
        a = 2 * math.pi * (k + 0.5) / 10
        x, z = math.cos(a) * 58.0, math.sin(a) * 66.0
        if k % 2:
            zm = zedi(rng.uniform(18, 26), 3.6, gold=True)
            place(B.mesh('GOLD', zm.tris), zm, cx + x, y0, cz + z, 0.0)
        else:
            yaw = yaw_to(-x, -z)
            place(B.mesh('MIX', 500), hall(6.0, 5.0, 10.0, wall=WHITE, col=(230, 226, 216)), cx + x, y0, cz + z, yaw)
            pg, px = pyatthat(5.0, 5, 26.0)
            place(B.mesh('GOLD', pg.tris), pg, cx + x, y0 + 10.0, cz + z, yaw)
            place(B.mesh('MIX', px.tris), px, cx + x, y0 + 10.0, cz + z, yaw)
    pads = [ground_pad(col, cx, cz, plat_poly((-90.0, -100.0, 90.0, 100.0, 30.0)), gy, 12.0, 'pave')]
    meta = finish('bota', B, col, pads, dict(cx=cx, cz=cz, Y0=y0, top=round(top, 1)))
    print('Botataung: top %.1f (%.1f over its platform)' % (top, top - y0))
    return meta


def kaba_aye():
    """Kaba Aye (World Peace) Pagoda (1952, 34 m, on a low hill): a round gilded stupa whose bell is broad and smooth,
    on a five-sided terrace with five entrance halls (one per side) and a gold umbrella spire. OSM: the compound a round
    168-stud ground at (32470, -6511)."""
    cx, cz = 32470.0, -6511.0
    gy = 42.9
    y0 = gy + 10.0
    B = Bucket('kaba')
    col = Collide()
    mix = B.mesh('MIX', 3000)
    pent = [(math.cos(-math.pi / 2 + 2 * math.pi * k / 5) * 62.0, math.sin(-math.pi / 2 + 2 * math.pi * k / 5) * 62.0) for k in range(5)]
    prism(mix, pent, cx, cz, gy - 10.0, y0, WHITE, rgb_top=MARBLE)
    prism(mix, scale2(pent, 1.0 + 0.6 / 62.0), cx, cz, y0 - 1.2, y0 + 0.4, GOLD_V, top=False)
    col.add(cx, y0 - 3.0, cz, 100, 6, 100, 0, 0, 'terrace')
    g = B.mesh('GOLD', 9000)
    # round terraces (5 tiers) then the bell: the profile with round tiers and a broad bell
    top = stupa(g, col, cx, cz, y0, 34.0, 2.6, base_k=0.7, bell_k=1.3, square=False, segs=40)
    # five entrance halls with tiered roofs, one on each side of the pentagon, facing out
    for k in range(5):
        a = -math.pi / 2 + 2 * math.pi * (k + 0.5) / 5
        ux, uz = math.cos(a), math.sin(a)
        r = 62.0 * math.cos(math.pi / 5) - 2.0
        hx, hz = cx + ux * r, cz + uz * r
        yaw = yaw_to(ux, uz)
        place(B.mesh('MIX', 600), hall(9.0, 7.0, 13.0, wall=WHITE, col=(232, 228, 220)), hx, y0, hz, yaw)
        pg, px = pyatthat(7.0, 5, 32.0)
        place(B.mesh('GOLD', pg.tris), pg, hx, y0 + 13.0, hz, yaw)
        place(B.mesh('MIX', px.tris), px, hx, y0 + 13.0, hz, yaw)
        # steps down from each hall to the ground
        sx_, sz_ = cx + ux * (r + 18.0), cz + uz * (r + 18.0)
        place(B.mesh('MIX', 50), _steps(12.0, 16.0, y0 - gy), sx_, gy, sz_, yaw)
        col.boxes.append(('seg', (cx + ux * (r + 8), y0, cz + uz * (r + 8)), (cx + ux * (r + 26), gy, cz + uz * (r + 26)), 12.0, 3.0))
    pads = [ground_pad(col, cx, cz, ngon(84.0, 20, 0.0), gy, 14.0, 'grass')]
    meta = finish('kaba', B, col, pads, dict(cx=cx, cz=cz, Y0=y0, top=round(top, 1)))
    print('Kaba Aye: top %.1f (%.1f over its terrace)' % (top, top - y0))
    return meta


def _steps(w, run, rise, rgb=WHITE):
    """a flight of steps (local: rising towards -z from z=+run/2 at y=0 to z=-run/2 at y=rise), solid under"""
    m = Mesh()
    n = max(2, int(round(rise / 1.2)))
    r = rise / n
    t = run / n
    for i in range(n):
        z0 = run / 2 - i * t
        z1 = z0 - t
        y = (i + 1) * r
        box(m, 0, y / 2 - 2.0 + 1.0, (z0 + z1) / 2, w, y + 2.0, t, rgb)
    return m


def karaweik():
    """Karaweik Palace (1974, a concrete royal barge on Kandawgyi Lake): twin hulls whose bows are two gold karaweik
    birds with tall curved necks, a stern sweeping up, pavilions with green roofs and gold eaves along the deck and a
    tall gold tiered spire in the middle. OSM outline 138 x 86 studs at (34767, 4382), its long axis turned 9.6 degrees
    (bows to the west). Stands at the lake's level (25.6 studs; the water is not built yet)."""
    cx, cz = 34768.0, 4382.0
    wl = 25.6
    ang = math.atan2(15.0, 89.0)                  # the axis: +x turned towards +z
    ux, uz = math.cos(ang), math.sin(ang)          # bow -> stern direction is +u (stern east)
    yaw = yaw_to(ux, uz)                           # local +z -> towards the stern
    B = Bucket('kara')
    col = Collide()
    gm, mm = Mesh(), Mesh()
    # hulls: two long hulls 60 studs apart (local x = across, z = along, bow at -z)
    L = 128.0
    for sx in (-30.0, 30.0):
        # hull: a lofted shape, deep red under a gold upper band, pointed at both ends
        prof = []
        for k in range(17):
            t = k / 16.0
            z = -L / 2 + L * t
            w = 9.0 * math.sin(math.pi * min(1.0, max(0.0, (t * 1.15 - 0.05)))) ** 0.6 + 1.0
            prof.append((z, w))
        for k in range(16):
            (z0, w0), (z1, w1) = prof[k], prof[k + 1]
            for side in (-1, 1):
                a0, a1 = (sx + side * w0, wl - 3.0, z0), (sx + side * w1, wl - 3.0, z1)
                b0, b1 = (sx + side * w0 * 1.1, wl + 7.0, z0), (sx + side * w1 * 1.1, wl + 7.0, z1)
                c0, c1 = (sx + side * w0 * 1.08, wl + 10.0, z0), (sx + side * w1 * 1.08, wl + 10.0, z1)
                quad(mm, a0, a1, b1, b0, (150, 34, 28), (side, 0, 0))
                quad(gm, b0, b1, c1, c0, G_HI, (side, 0.2, 0))
            quad(mm, (sx - w0 * 1.08, wl + 10.0, z0), (sx + w0 * 1.08, wl + 10.0, z0), (sx + w1 * 1.08, wl + 10.0, z1),
                 (sx - w1 * 1.08, wl + 10.0, z1), (170, 120, 80), (0, 1, 0))
        # the bird at the bow: a neck rising and curving forward, the head with a beak and a crest
        # an S-shaped neck: up and forward from the breast, back over the top, the head leaning forward
        z0n = -L / 2 + 8.0
        neck = [(0.0, wl + 8.0 + yy, z0n + zz) for yy, zz in ((0, 0), (5, -4), (11, -7), (17, -8), (23, -6), (28, -3),
                                                                (32, -2), (35, -3))]
        tube(gm, [(sx + q[0], q[1], q[2]) for q in neck], [7.5, 6.2, 5.0, 4.2, 3.7, 3.4, 3.3, 3.3], G_HI, 12)
        hp = neck[-1]
        ellipsoid(gm, (sx, hp[1] + 1.2, hp[2] - 2.4), (1, 0, 0), (0, 1, 0), (0, 0, 1), 3.6, 3.4, 5.0, G_HI, 12, 7)
        # the beak, pointing forward and a little down; red eyes; the plume behind
        bk = (sx, hp[1] + 0.4, hp[2] - 7.0)
        for side in (-1, 1):
            tri(gm, (sx + side * 1.6, hp[1] + 1.4, hp[2] - 5.6), (sx, hp[1] + 2.0, hp[2] - 5.8), (sx, bk[1], bk[2] - 5.0),
                G_MID, (side, 0.4, -0.3))
            tri(gm, (sx + side * 1.6, hp[1] + 1.4, hp[2] - 5.6), (sx, bk[1], bk[2] - 5.0), (sx, hp[1] - 0.6, hp[2] - 5.2),
                G_LO, (side, -0.4, -0.3))
            ellipsoid(mm, (sx + side * 3.1, hp[1] + 2.0, hp[2] - 4.0), (1, 0, 0), (0, 1, 0), (0, 0, 1), 0.5, 0.7, 0.7,
                      (170, 30, 30), 6, 4)
        for kk in range(4):
            tip = (sx, hp[1] + 8.0 + kk * 1.4, hp[2] + 3.0 + kk * 2.6)
            tri(gm, (sx - 0.9, hp[1] + 3.6, hp[2] + 0.4 + kk), (sx + 0.9, hp[1] + 3.6, hp[2] + 0.4 + kk), tip, G_HI, (0, 0.3, 1))
            tri(gm, (sx + 0.9, hp[1] + 3.6, hp[2] + 0.4 + kk), (sx - 0.9, hp[1] + 3.6, hp[2] + 0.4 + kk), tip, G_HI, (0, 0.3, -1))
        # the bird's breast (a gold bulge at the bow) and wings along the hull's sides
        ellipsoid(gm, (sx, wl + 9.0, -L / 2 + 11.0), (1, 0, 0), (0, 1, 0), (0, 0, 1), 9.5, 10.0, 12.0, G_HI, 14, 7)
        for side in (-1, 1):
            for kk in range(5):
                z = -L / 2 + 20.0 + kk * 7.0
                tri(gm, (sx + side * 10.2, wl + 6.0, z), (sx + side * 10.2, wl + 6.0, z + 9.0),
                    (sx + side * 10.6, wl + 15.0 - kk * 1.2, z + 12.0), G_MID, (side, 0.2, 0))
        # the stern: sweeping up and curling forward (a tail)
        tail = [(0.0, wl + 9.0, L / 2 - 6.0)]
        for k in range(1, 8):
            t = k / 7.0
            tail.append((0.0, wl + 9.0 + 26.0 * t, L / 2 - 6.0 + 10.0 * math.sin(t * math.pi * 0.8)))
        tube(mm, [(sx + q[0], q[1], q[2]) for q in tail], [3.4 - 2.6 * k / 7.0 for k in range(8)], (150, 34, 28), 10)
        tube(gm, [(sx + q[0], q[1] + 0.2, q[2]) for q in tail[2:]], [1.0] * 6, G_HI, 6)
        tp = tail[-1]
        for kk in range(4):
            tri(gm, (sx - 0.6, tp[1], tp[2]), (sx + 0.6, tp[1], tp[2]), (sx, tp[1] + 5.0 + kk, tp[2] - 3.0 * kk), G_HI, (0, 0.2, 1))
            tri(gm, (sx + 0.6, tp[1], tp[2]), (sx - 0.6, tp[1], tp[2]), (sx, tp[1] + 5.0 + kk, tp[2] - 3.0 * kk), G_HI, (0, 0.2, -1))
    # the deck between the hulls and the pavilions
    box(mm, 0, wl + 9.4, 4.0, 72.0, 1.2, L - 40.0, (170, 120, 80))
    for zc, hw_, hd_, hh, tiers, H in ((-24.0, 26.0, 12.0, 12.0, 3, 26.0), (30.0, 26.0, 14.0, 12.0, 3, 26.0)):
        body = hall(hw_, hd_, hh, wall=(196, 44, 36), col=(196, 160, 60))
        place(mm, body, 0, wl + 10.0, zc, 0.0)
        place(mm, hipped(hw_, hd_, 3.0, 4.0, ROOF_GREEN, GOLD_V), 0, wl + 10.0 + hh, zc, 0.0)
        for sx in (-18.0, 18.0):
            pg, px = pyatthat(8.0, tiers, H)
            place(gm, pg, sx, wl + 10.0 + hh + 2.0, zc, 0.0)
            place(mm, px, sx, wl + 10.0 + hh + 2.0, zc, 0.0)
    # the middle: a square hall and the tall gold spire (9 tiers)
    place(mm, hall(16.0, 16.0, 16.0, wall=(196, 44, 36), col=(196, 160, 60)), 0, wl + 10.0, 3.0, 0.0)
    place(mm, hipped(16.0, 16.0, 3.0, 4.0, ROOF_GREEN, GOLD_V), 0, wl + 26.0, 3.0, 0.0)
    pg, px = pyatthat(13.0, 9, 92.0)
    place(gm, pg, 0, wl + 30.0, 3.0, 0.0)
    place(mm, px, 0, wl + 30.0, 3.0, 0.0)
    place(B.mesh('GOLD', gm.tris), gm, cx, 0, cz, yaw)
    place(B.mesh('MIX', mm.tris), mm, cx, 0, cz, yaw)
    for b in ((0, wl + 4.0, 0, 92.0, 14.0, L), (0, wl + 16.0, 3.0, 72.0, 12.0, L - 40.0)):
        x, y, z, sx, sy, sz = b
        col.add(cx + x * math.cos(yaw) - z * math.sin(yaw), y, cz + x * math.sin(yaw) + z * math.cos(yaw), sx, sy, sz, yaw, 0, 'barge')
    meta = finish('kara', B, col, None, dict(cx=cx, cz=cz, Y0=wl, top=round(wl + 30.0 + 92.0, 1)))
    print('Karaweik: water %.1f, spire top %.1f' % (wl, wl + 122.0))
    return meta


def city_hall():
    """Yangon City Hall (1936, Burmese revival): four storeys on its OSM outline (193 x 140 studs, 17 points), white with
    pale blue-green trims, arched ground floor windows, window rows, a tall central bay on Maha Bandula Road with a tiered
    pyatthat tower and smaller tiered roofs on the corner pavilions. Front: south (the outline's z max side faces Maha
    Bandula Road and Maha Bandula Park)."""
    pts = [(33258, 7981), (33287, 8008), (33337, 8009), (33337, 8013), (33340, 8013), (33340, 8019), (33387, 8021),
           (33387, 8014), (33390, 8014), (33390, 8011), (33437, 8013), (33448, 8002), (33451, 7887), (33270, 7881),
           (33261, 7881), (33261, 7888)]
    gy = 20.1
    H = 12.0 + 3 * 9.0 + 3.0                     # 4 floors + parapet
    B = Bucket('ch')
    col = Collide()
    W_ = (238, 236, 228)
    TEAL = (120, 168, 160)
    m = B.mesh('MIX', 6000)
    n = len(pts)
    cxs = sum(p[0] for p in pts) / n
    czs = sum(p[1] for p in pts) / n
    for i in range(n):
        a, b = pts[i], pts[(i + 1) % n]
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        if L < 0.5:
            continue
        ex, ez = (b[0] - a[0]) / L, (b[1] - a[1]) / L
        nx, nz = ez, -ex
        if nx * ((a[0] + b[0]) / 2 - cxs) + nz * ((a[1] + b[1]) / 2 - czs) < 0:
            nx, nz = -nx, -nz
        quad(m, (a[0], gy - 4.0, a[1]), (b[0], gy - 4.0, b[1]), (b[0], gy + H, b[1]), (a[0], gy + H, a[1]), W_, (nx, 0, nz))
        # floors' windows: ground floor arches, then 3 rows; pilasters every bay
        nb = max(1, int(L // 9.0))
        for k in range(nb):
            t0 = (k + 0.25) / nb * L
            t1 = (k + 0.75) / nb * L
            for f, (y0w, y1w) in enumerate(((gy + 2.0, gy + 9.0), (gy + 14.0, gy + 19.0), (gy + 23.0, gy + 28.0), (gy + 32.0, gy + 37.0))):
                p0 = (a[0] + ex * t0 + nx * 0.08, a[1] + ez * t0 + nz * 0.08)
                p1 = (a[0] + ex * t1 + nx * 0.08, a[1] + ez * t1 + nz * 0.08)
                quad(m, (p0[0], y0w, p0[1]), (p1[0], y0w, p1[1]), (p1[0], y1w, p1[1]), (p0[0], y1w, p0[1]), (58, 84, 86), (nx, 0, nz))
                if f == 0:
                    tri(m, (p0[0], y1w, p0[1]), (p1[0], y1w, p1[1]), ((p0[0] + p1[0]) / 2, y1w + 2.2, (p0[1] + p1[1]) / 2), (58, 84, 86), (nx, 0, nz))
            pp = (a[0] + ex * (k / nb * L) + nx * 0.4, a[1] + ez * (k / nb * L) + nz * 0.4)
            obox(m, (pp[0], gy + H / 2, pp[1]), (ex, 0, ez), (0, 1, 0), (nx, 0, nz), 0.7, H / 2, 0.4, W_)
        # cornice bands (teal) at each floor line, 0.12 proud
        for yb in (gy + 12.0, gy + 21.0, gy + 30.0, gy + H - 2.0):
            quad(m, (a[0] + nx * 0.12, yb, a[1] + nz * 0.12), (b[0] + nx * 0.12, yb, b[1] + nz * 0.12),
                 (b[0] + nx * 0.12, yb + 0.8, b[1] + nz * 0.12), (a[0] + nx * 0.12, yb + 0.8, a[1] + nz * 0.12), TEAL, (nx, 0, nz))
    # the roof (flat, grey) as a fan over the outline (it is convex enough from its centre)
    fan(m, [(p[0], gy + H, p[1]) for p in pts], (150, 146, 140), (0, 1, 0), (cxs, gy + H, czs))
    col.add(33354.5, gy + H / 2 - 2.0, 7950.0, 190.0, H + 4.0, 136.0, 0, 0, 'building')
    # the central bay on the south front (Maha Bandula Road): a raised block with a 7-tier white-gold pyatthat
    fxc, fzc = 33363.5, 8012.0
    box(m, fxc, gy + (H + 12.0) / 2, fzc - 6.0, 52.0, H + 12.0, 22.0, W_)
    for k in range(3):
        x0 = fxc - 18.0 + k * 18.0
        quad(m, (x0 - 5.0, gy + 2.0, fzc + 5.1), (x0 + 5.0, gy + 2.0, fzc + 5.1), (x0 + 5.0, gy + 16.0, fzc + 5.1), (x0 - 5.0, gy + 16.0, fzc + 5.1), (58, 84, 86), (0, 0, 1))
        tri(m, (x0 - 5.0, gy + 16.0, fzc + 5.1), (x0 + 5.0, gy + 16.0, fzc + 5.1), (x0, gy + 21.0, fzc + 5.1), (58, 84, 86), (0, 0, 1))
    g = B.mesh('GOLD', 3000)
    for (px_, pz_, w_, tiers, Ht, base) in ((fxc, fzc - 6.0, 12.0, 7, 62.0, gy + H + 12.0),
                                            (33268.0, 7990.0, 7.0, 5, 34.0, gy + H), (33440.0, 8008.0, 7.0, 5, 34.0, gy + H),
                                            (33268.0, 7886.0, 6.0, 3, 24.0, gy + H), (33446.0, 7890.0, 6.0, 3, 24.0, gy + H),
                                            (33314.0, 8012.0, 6.0, 5, 30.0, gy + H), (33413.0, 8016.0, 6.0, 5, 30.0, gy + H)):
        # white tiered roofs with gold trims (the real ones are white-and-gold)
        pg, px = pyatthat(w_, tiers, Ht, roof=(236, 234, 226), neck=(120, 168, 160), trim=G_HI)
        box(m, px_, base + 1.5, pz_, 2 * w_ + 4.0, 3.0, 2 * w_ + 4.0, W_)
        place(g, pg, px_, base + 3.0, pz_, 0.0)
        place(m, px, px_, base + 3.0, pz_, 0.0)
    pads = [ground_pad(col, cxs, czs, [(p[0] - cxs, p[1] - czs) for p in pts], gy, 10.0, 'pave')]
    meta = finish('ch', B, col, pads, dict(cx=cxs, cz=czs, Y0=gy, top=round(gy + H + 12.0 + 3.0 + 62.0, 1), name='YANGON CITY HALL',
                                         plate='%.1f %.1f %.1f' % (fxc, gy + H + 6.0, fzc + 5.2)))
    print('City Hall: roof %.1f, tower top %.1f' % (gy + H, gy + H + 77.0))
    return meta


def independence():
    """Independence Monument (1948) in Maha Bandula Park: a white obelisk 46 m on a round stepped base with five
    smaller white pillars round it (the five states), chinthe at the foot. OSM: the round monument area 48 studs
    across at (33321, 8294)."""
    cx, cz = 33321.0, 8294.0
    gy = 20.2
    B = Bucket('indep')
    col = Collide()
    w = B.mesh('WHITE', 3000)
    g = B.mesh('GOLD', 400)
    # round stepped base
    for r, y0, y1 in ((26.0, gy - 4.0, gy + 1.2), (21.0, gy + 1.2, gy + 2.4), (16.0, gy + 2.4, gy + 3.6)):
        prism(w, ngon(r, 24), cx, cz, y0, y1, WHITE)
    col.add(cx, gy - 1.0, cz, 52.0, 7.0, 52.0, 0, 0, 'base')
    # the obelisk: a square pedestal, then a tapering shaft (46 m: 138 studs) to a pointed tip, a gold band
    yb = gy + 3.6
    prism(w, rect(6.5, 6.5), cx, cz, yb, yb + 12.0, WHITE)
    prism(w, rect(7.2, 7.2), cx, cz, yb + 11.0, yb + 13.0, WHITE_SH)
    frustum(w, rect(5.2, 5.2), rect(2.6, 2.6), cx, cz, yb + 13.0, gy + 128.0, WHITE)
    frustum(w, rect(2.6, 2.6), rect(0.05, 0.05), cx, cz, gy + 128.0, gy + 138.0, WHITE)
    prism(g, rect(5.3, 5.3), cx, cz, yb + 13.0, yb + 14.0, G_HI, top=False)
    col.add(cx, (yb + gy + 138.0) / 2, cz, 10.0, gy + 138.0 - yb, 10.0, 0, 0, 'obelisk')
    # five smaller pillars round it
    for k in range(5):
        a = -math.pi / 2 + 2 * math.pi * k / 5
        x, z = cx + math.cos(a) * 20.0, cz + math.sin(a) * 20.0
        prism(w, rect(1.6, 1.6), x, z, gy + 1.2, gy + 26.0, WHITE, yaw=a)
        frustum(w, rect(1.6, 1.6), rect(0.05, 0.05), x, z, gy + 26.0, gy + 30.0, WHITE, yaw=a)
        prism(g, rect(1.7, 1.7), x, z, gy + 22.0, gy + 22.8, G_HI, top=False, yaw=a)
        col.add(x, gy + 15.0, z, 3.2, 28.0, 3.2, a, 0, 'pillar')
    # two chinthe at the foot facing the park's walk (south)
    cw, cg = chinthe(9.0)
    for sx in (-1, 1):
        place(w, cw, cx + sx * 9.0, gy + 1.2, cz + 22.0, yaw_to(0, 1))
        place(g, cg, cx + sx * 9.0, gy + 1.2, cz + 22.0, yaw_to(0, 1))
    pads = [ground_pad(col, cx, cz, ngon(40.0, 16), gy, 8.0, 'grass')]
    meta = finish('indep', B, col, pads, dict(cx=cx, cz=cz, Y0=gy, top=gy + 138.0))
    print('Independence Monument: top %.1f' % (gy + 138.0))
    return meta


def chaukhtatgyi():
    """Chaukhtatgyi Buddha Temple: the 66 m reclining Buddha (white face and hands, a gold robe, a gold crown, red lips)
    lying on its right side on a long dais, its head propped on the right hand, under a big open-sided steel shed with a
    three-tier metal gable roof. OSM: the shed's outline round (34072, 1474), its long axis 32 degrees off east (towards
    south). Scales: the figure 106 studs long (1.6 a metre, so it fits the real shed), up 2.4 a metre."""
    cx, cz = 34072.0, 1474.0
    gy = 38.6
    ang = math.atan2(72.0, 114.0)
    ux, uz = math.cos(ang), math.sin(ang)
    yaw = yaw_to(-uz, ux)                 # local +x -> the long axis (east-south-east), local +z -> its side
    B = Bucket('chauk')
    col = Collide()
    wm, gm, mm = Mesh(), Mesh(), Mesh()
    X, Y, Z = (1, 0, 0), (0, 1, 0), (0, 0, 1)
    L, Wd = 150.0, 74.0
    # the floor (a pad on the ground) and the dais
    prism(mm, rect(L / 2, Wd / 2), 0, 0, gy - 6.0, gy + 0.8, STONE, rgb_top=(176, 160, 140))
    prism(wm, rect(58.0, 13.0), 0, -4.0, gy + 0.8, gy + 5.0, WHITE)
    prism(gm, rect(58.4, 13.4), 0, -4.0, gy + 4.4, gy + 5.0, G_HI, top=False)
    b = gy + 5.0
    # the body lying on its right side (shoulders stacked up), head at -x, feet at +x, facing +z
    ellipsoid(gm, (-14.0, b + 12.5, -4.0), X, Y, Z, 22.0, 12.5, 8.5, G_HI, 16, 9)           # torso in the robe
    ellipsoid(gm, (12.0, b + 11.5, -4.0), X, Y, Z, 15.0, 11.5, 9.0, G_HI, 14, 8)            # hips
    ellipsoid(gm, (38.0, b + 6.2, -4.0), X, Y, Z, 22.0, 6.2, 6.4, G_HI, 14, 7)              # lower leg
    ellipsoid(gm, (38.0, b + 17.0, -4.0), X, Y, Z, 22.0, 6.0, 6.2, G_HI, 14, 7)             # upper leg
    ellipsoid(gm, (-10.0, b + 25.0, -2.0), X, Y, Z, 20.0, 3.6, 4.2, G_HI, 12, 6)            # the top arm along the side
    ellipsoid(wm, (12.0, b + 25.0, -1.0), X, Y, Z, 4.0, 3.0, 3.6, WHITE, 8, 5)              # its hand on the hip
    for yy in (6.2, 17.0):                                                                  # the soles at +x
        ellipsoid(wm, (60.5, b + yy, -4.0), X, Y, Z, 1.6, 5.8, 5.2, (240, 236, 228), 10, 6)
        for k in range(3):
            quad(gm, (62.15, b + yy - 3.0 + k * 2.6, -7.0), (62.15, b + yy - 3.0 + k * 2.6, -1.0),
                 (62.15, b + yy - 2.2 + k * 2.6, -1.0), (62.15, b + yy - 2.2 + k * 2.6, -7.0), G_MID, X)
    # the propping arm: the elbow on a red pillow, the forearm up to the head
    box(mm, -42.0, b + 3.0, -4.0, 18.0, 6.0, 16.0, (176, 34, 30))
    box(gm, -42.0, b + 6.1, -4.0, 18.4, 0.3, 16.4, G_HI, top=True)
    ellipsoid(wm, (-44.0, b + 15.0, -4.0), X, Y, Z, 3.4, 9.0, 3.6, WHITE, 8, 6)             # forearm
    # the head: white face towards +z, the crown at -x (the top of the head), gold headdress band
    hc = (-47.0, b + 27.0, -4.0)
    ellipsoid(wm, hc, X, Y, Z, 8.0, 8.6, 7.6, WHITE, 14, 9)
    ellipsoid(gm, (hc[0] - 3.0, hc[1], hc[2] - 0.8), X, Y, Z, 6.6, 8.4, 7.0, G_HI, 12, 7)  # hair / headdress
    lathe_x = Mesh()
    lathe(lathe_x, 0, 0, [(5.0, 0.0), (4.4, 2.0), (3.0, 4.0), (1.6, 6.5), (0.6, 8.5), (0.0, 10.0)], 10, G_HI)
    # the crown points along -x: turn the lathe (built along +y) to -x
    for i in range(0, len(lathe_x.P), 3):
        tri_pts = [(hc[0] - 7.0 - q[1], hc[1] + q[0], hc[2] + q[2]) for q in lathe_x.P[i:i + 3]]
        nrm = [(-n[1], n[0], n[2]) for n in lathe_x.N[i:i + 3]]
        tri(gm, tri_pts[0], tri_pts[1], tri_pts[2], G_HI, None, tuple(nrm))
    for sx in (-1, 1):
        ellipsoid(mm, (hc[0] + 1.0, hc[1] + sx * 2.6, hc[2] + 7.25), X, Y, Z, 1.6, 0.8, 0.35, (34, 30, 30), 8, 4)   # eyes
        ellipsoid(gm, (hc[0] + 2.6, hc[1] + sx * 2.6, hc[2] + 7.0), X, Y, Z, 0.4, 1.8, 0.3, G_MID, 6, 3)          # brows
    ellipsoid(mm, (hc[0] + 4.6, hc[1], hc[2] + 7.0), X, Y, Z, 0.7, 1.8, 0.5, (196, 50, 56), 8, 4)                 # lips
    ellipsoid(wm, (hc[0] + 1.6, hc[1], hc[2] + 7.9), X, Y, Z, 1.6, 1.0, 1.2, WHITE, 8, 4)                         # nose
    ellipsoid(gm, (hc[0] + 0.5, hc[1] + 8.6, hc[2] - 0.5), X, Y, Z, 2.0, 1.4, 4.0, G_HI, 8, 4)                    # ear
    # the shed: steel columns round an open hall, a three-tier gable roof of grey metal, its ceiling
    STEEL = (150, 156, 160)
    ROOF = (118, 128, 132)
    for side in (-1, 1):
        for k in range(9):
            x = -L / 2 + 4.0 + (L - 8.0) * k / 8
            box(mm, x, gy + 18.0, side * (Wd / 2 - 2.0), 1.6, 36.0, 1.6, STEEL)
    for (hw_, y0, rise, over) in ((Wd / 2, gy + 36.0, 12.0, 5.0), (Wd * 0.34, gy + 50.0, 9.0, 3.0), (Wd * 0.2, gy + 61.0, 7.0, 2.0)):
        e = hw_ + over
        x0, x1 = -L / 2 - over, L / 2 + over
        for sg in (-1, 1):
            quad(mm, (x0, y0, sg * e), (x1, y0, sg * e), (x1, y0 + rise, 0), (x0, y0 + rise, 0), ROOF, (0, 1, sg * 0.6))
            quad(mm, (x0, y0, sg * e), (x1, y0, sg * e), (x1, y0 + rise, 0), (x0, y0 + rise, 0), (70, 74, 78), (0, -1, -sg * 0.6))
        for xe in (x0, x1):
            for sg in (-1, 1):
                tri(mm, (xe, y0, -e), (xe, y0, e), (xe, y0 + rise, 0), (200, 204, 206), (sg, 0, 0))
        if hw_ < Wd / 2:
            # the clerestory walls under each upper tier
            for sg in (-1, 1):
                quad(mm, (x0 + 4, y0 - 4.0, sg * hw_), (x1 - 4, y0 - 4.0, sg * hw_), (x1 - 4, y0, sg * hw_), (x0 + 4, y0, sg * hw_),
                     (190, 196, 198), (0, 0, sg))
        box(gm, 0, y0 + rise + 0.4, 0, L + 2 * over, 0.8, 1.0, G_HI)
    place(B.mesh('WHITE', wm.tris), wm, cx, 0, cz, yaw)
    place(B.mesh('GOLD', gm.tris), gm, cx, 0, cz, yaw)
    place(B.mesh('MIX', mm.tris), mm, cx, 0, cz, yaw)
    c, s = math.cos(yaw), math.sin(yaw)

    def Wp(x, z):
        return (cx + x * c - z * s, cz + x * s + z * c)
    for x, z, sx, sy, sz, y in ((0, -4.0, 116.0, 30.0, 26.0, gy + 15.0), (0, 0, L, 1.6, Wd, gy)):
        p = Wp(x, z)
        col.add(p[0], y, p[1], sx, sy, sz, yaw, 0, 'chauk')
    pads = [ground_pad(col, cx, cz, [(x * c - z * s, x * s + z * c) for x, z in rect(L / 2 + 6, Wd / 2 + 6)], gy, 10.0, 'pave')]
    meta = finish('chauk', B, col, pads, dict(cx=cx, cz=cz, Y0=gy, top=round(gy + 68.0, 1)))
    print('Chaukhtatgyi: roof ridge %.1f' % (gy + 68.0))
    return meta


BUILDERS = {'shw': shwedagon, 'wiz': maha_wizaya, 'sule': sule, 'bota': botataung, 'kaba': kaba_aye, 'kara': karaweik,
            'ch': city_hall, 'indep': independence, 'chauk': chaukhtatgyi}


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    ids = sys.argv[1:] or list(BUILDERS)
    for lid in ids:
        BUILDERS[lid]()
