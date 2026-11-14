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
  GOLD   gilded surfaces: Foil, warm gold, tag LandmarkGlow (glows at night)
  WHITE  lime-washed / marble masonry: SmoothPlastic white, vertex colours carry the trims
  MIX    painted parts in several colours (red columns, roofs, floors): SmoothPlastic, vertex colours
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
WHITE = (246, 244, 238)
WHITE_SH = (222, 218, 210)
MARBLE = (236, 233, 226)
MARBLE_BAND = (150, 62, 52)
MARBLE_TEAL = (70, 128, 122)
RED = (176, 38, 30)
RED_DK = (122, 30, 24)
ROOF_RED = (132, 40, 30)
ROOF_GREEN = (52, 104, 74)
BRICK = (170, 104, 80)
STONE = (196, 190, 178)
DARK = (40, 30, 24)
GOLD_V = (222, 176, 74)      # gold as a vertex colour in MIX meshes (trims)


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


def hall(w, d, h, wall=WHITE, col=RED, trim=GOLD_V):
    """a tazaung shrine hall body (local: front facing +z, base at y=0, half sizes w (x), d (z), eave height h):
    a white plinth, red columns round an open front, back and side walls, a dark interior, gold beam. Returns mix mesh."""
    m = Mesh()
    pl = 1.6
    prism(m, rect(w + 1.2, d + 1.2), 0, 0, -6.0, pl, WHITE)  # plinth (runs down 6 so a slope never shows under it)
    # back wall and side walls (thin), interior dark
    box(m, 0, pl + (h - pl) / 2, -d + 0.8, 2 * w - 1.6, h - pl, 1.6, wall)
    box(m, -w + 0.8, pl + (h - pl) / 2, -d * 0.25, 1.6, h - pl, d * 1.5, wall)
    box(m, w - 0.8, pl + (h - pl) / 2, -d * 0.25, 1.6, h - pl, d * 1.5, wall)
    box(m, 0, pl + 0.05, 0, 2 * w - 3.4, 0.1, 2 * d - 3.4, DARK, top=True)
    box(m, 0, pl + (h - pl) / 2, -d + 1.7, 2 * w - 3.4, h - pl, 0.2, (92, 50, 30))  # inner back wall (warm wood)
    # columns along the front and down the sides' open half
    n = max(2, int(round(2 * w / 7.0)))
    for i in range(n + 1):
        x = -w + 0.9 + (2 * w - 1.8) * i / n
        box(m, x, pl + (h - pl) / 2, d - 0.9, 1.5, h - pl, 1.5, col)
        box(m, x, pl + 0.9, d - 0.9, 2.1, 1.8, 2.1, trim)
    for zf in (0.45,):
        for sx in (-1, 1):
            box(m, sx * (w - 0.9), pl + (h - pl) / 2, d * zf, 1.5, h - pl, 1.5, col)
    # the beam band round the top, gold
    prism(m, rect(w, d), 0, 0, h - 1.4, h, trim, top=True)
    # a Buddha image glint inside (gold seated block) at the back
    box(m, 0, pl + 2.4, -d + 3.6, 3.2, 4.8, 2.4, trim)
    return m


def hipped(w, d, over, rise, rgb=ROOF_RED, trim=GOLD_V):
    """a low hipped roof over a hall (local base y=0): eaves out by `over`, ridge rise. mix mesh."""
    m = Mesh()
    prism(m, rect(w + over, d + over), 0, 0, -0.6, 0.0, trim, top=False, bottom=True)
    frustum(m, rect(w + over, d + over), rect(max(0.6, w * 0.45), max(0.6, d * 0.35)), 0, 0, 0.0, rise, rgb, top=True)
    return m


def chinthe(H):
    """a seated chinthe (guardian lion), stylised and low-poly (local: facing +z, base at y=0, total height H).
    Returns (white_mesh, gold_mesh)."""
    w, gm = Mesh(), Mesh()
    s = H / 27.0
    up, X, Z = (0, 1, 0), (1, 0, 0), (0, 0, 1)
    # plinth
    prism(w, rect(9 * s, 12 * s), 0, 0, 0, 3.2 * s, WHITE_SH)
    prism(gm, rect(9.3 * s, 12.3 * s), 0, 0, 3.2 * s, 3.8 * s, G_HI, top=False)
    prism(w, rect(8.6 * s, 11.6 * s), 0, 0, 3.8 * s, 4.6 * s, WHITE)
    y0 = 4.6 * s
    # haunches (rear, sitting), tail
    obox(w, (0, y0 + 4 * s, -5.5 * s), X, up, Z, 6.6 * s, 4 * s, 5 * s, WHITE)
    for sx in (-1, 1):
        obox(w, (sx * 6.2 * s, y0 + 3.4 * s, -3.6 * s), X, up, Z, 1.6 * s, 3.4 * s, 4.2 * s, WHITE)  # thighs
        obox(w, (sx * 4.6 * s, y0 + 0.8 * s, 1.6 * s), X, up, Z, 1.6 * s, 0.8 * s, 2.6 * s, WHITE)  # hind paws
    # torso: tilted back, from the haunches up to the chest
    t = math.radians(14)
    ay = (0, math.cos(t), -math.sin(t))
    az = (0, math.sin(t), math.cos(t))
    obox(w, (0, y0 + 11 * s, -1.5 * s), X, ay, az, 5.6 * s, 6.6 * s, 4.6 * s, WHITE)
    # chest plate (gold breast ornament) and collar
    obox(gm, (0, y0 + 13.2 * s, 2.0 * s), X, ay, az, 4.2 * s, 2.6 * s, 1.0 * s, G_HI)
    obox(gm, (0, y0 + 16.4 * s, 0.2 * s), X, up, Z, 5.4 * s, 0.9 * s, 4.4 * s, G_HI)
    # front legs, straight
    for sx in (-1, 1):
        obox(w, (sx * 3.4 * s, y0 + 5.6 * s, 3.4 * s), X, up, Z, 1.5 * s, 5.6 * s, 1.6 * s, WHITE)
        obox(w, (sx * 3.4 * s, y0 + 0.6 * s, 4.4 * s), X, up, Z, 1.8 * s, 0.6 * s, 2.4 * s, WHITE)
        obox(gm, (sx * 3.4 * s, y0 + 7.0 * s, 3.4 * s), X, up, Z, 1.7 * s, 0.5 * s, 1.8 * s, G_HI)  # anklet
    # head: big, square, raised; mane crest flaring behind it (gold trimmed)
    hy = y0 + 20.0 * s
    obox(w, (0, hy, 1.6 * s), X, up, Z, 3.6 * s, 3.4 * s, 3.4 * s, WHITE)
    obox(w, (0, hy - 1.6 * s, 4.6 * s), X, up, Z, 2.8 * s, 1.6 * s, 1.4 * s, WHITE)  # muzzle (upper jaw)
    obox(w, (0, hy - 3.9 * s, 4.0 * s), X, up, Z, 2.6 * s, 0.6 * s, 1.6 * s, WHITE)  # lower jaw
    obox(w, (0, hy - 2.9 * s, 4.1 * s), X, up, Z, 2.2 * s, 0.5 * s, 1.3 * s, (196, 52, 60))  # open red mouth
    for sx in (-1, 1):
        obox(w, (sx * 1.7 * s, hy + 0.8 * s, 5.0 * s), X, up, Z, 0.8 * s, 0.6 * s, 0.1 * s, DARK)  # eyes
        obox(gm, (sx * 1.7 * s, hy + 1.6 * s, 4.95 * s), X, up, Z, 1.0 * s, 0.25 * s, 0.1 * s, G_HI)  # brows
        obox(w, (sx * 3.6 * s, hy + 2.6 * s, 0.4 * s), X, up, Z, 0.8 * s, 1.4 * s, 0.8 * s, WHITE)  # ears
    # the mane: a flared crest ring behind the head (frustum), gold edge
    mane = Mesh()
    frustum(mane, rect(3.9, 3.9), rect(6.2, 1.2), 0, 0, -3.6, 4.6, WHITE)
    place(w, mane, 0, hy, -0.6 * s, 0.0, s)
    obox(gm, (0, hy + 4.4 * s, -0.6 * s), X, up, Z, 6.3 * s, 0.35 * s, 1.3 * s, G_HI)
    # tail: rising curl behind
    for k in range(5):
        a = k / 4.0
        obox(w, (0, y0 + (6 + 9 * a) * s, (-10.4 - 1.2 * math.sin(a * 3)) * s), X, up, Z, 1.1 * s, 1.6 * s, 1.1 * s, WHITE)
    obox(gm, (0, y0 + 16.4 * s, -10.8 * s), X, up, Z, 1.8 * s, 1.2 * s, 1.6 * s, G_HI)
    return w, gm


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
        return '\n'.join('%.2f %.2f %.2f %.2f %.2f %.2f %.4f %.4f %s' % b for b in self.boxes)


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
