"""street_kit.py (2026-11-16, rescale step 3: the 1:1 STREET DETAIL layer): the reusable street-prop kit.

Every piece is built at its real size (3 studs a metre) in its own frame: Y up, origin on the ground at the item's anchor,
+X along the road (or the arm / the item's long side), +Z across. The street generator (street_1to1.py) places pieces as
kit_pack P / Q records; the client builds them near the camera (YangonKitStream, decoder YangonKitData) from the templates
in ReplicatedStorage.YgnKit.Templates, made in Studio by tools/yangon/YangonStreetKit.luau from street_kit.glb.

Sizes and looks come from the vault research notes (City Legends/2026-11-16 Research - Yangon street furniture and traffic
life, Research - Real Yangon street detail survey) and the photos in build/landmarks/refs/street_kit/:
  power_pole/01-05, tea_shop/01-03, trishaw/01-02 (sidecar BESIDE the bike, on the rider's right, two seats back to back),
  traffic_signal/crop (HORIZONTAL black heads with a countdown, white pole and mast arm), ybs_bus_stop, food_cart.
No text is drawn into any mesh (street-name and stop plates get their real names from an image atlas: street_signs.py).

Classes (the first word of a mesh name; YangonStreetKit gives each its material, colours ride in the vertex colours):
  SCO  concrete (Concrete + YgnConcreteBare): power poles, drain slabs
  SMT  painted / galvanised steel (Metal + YgnSteelPainted): lamp posts, signal poles, frames, railings, carts
  SPL  plastic, rubber, glass-less bits (SmoothPlastic): stools, tables, bins, signal heads, tyres, seats
  SFB  cloth (Fabric + YgnCanvas): umbrellas, tarps, banners, cushions
  SGL  glass (Glass, 0.55 transparent): the bus shelter's back panel
  SNE  lamp heads (SmoothPlastic white by day; tag LampGlow -> Neon at night; a white SpotLight, tags LODLight + DayOff)

    python street_kit.py          -> imports/sync/ygn1to1_street/street_kit.glb + build/city_1to1/street/kit_meta.json
                                     (pid -> parts, tris, box) + the flicker test of every piece (must print 0)
Mesh names: CLASS_<pid>_<cx>_<cy>_<cz>_<sx>_<sy>_<sz> (glb.code; hundredths of a stud, n = minus), as the building kit.
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from glb import Mesh, write_glb, check_glb, code  # noqa: E402
from flicker_check import check as flicker  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
GLB = os.path.join(ROOT, "imports", "sync", "ygn1to1_street")
OUT = os.path.join(ROOT, "build", "city_1to1", "street")
S = 3.0  # studs a metre
UVK = 1.0 / 4.0  # 1 UV = 4 studs on the props (finer than the walls: small pieces)

# ------------------------------------------------------------------------------------------------ colours (sRGB)
CONC = (206, 202, 190)        # weathered concrete pole (renders ~150 on Concrete + YgnConcreteBare)
CONC_DIRT = (128, 122, 112)   # the splash band 0-1.5 m
CONC_SLAB = (190, 186, 176)
CONC_DARK = (70, 68, 64)      # the drain's dark gap
STEEL = (120, 122, 124)       # crossarms, brackets
GALV = (196, 198, 200)        # galvanised lamp post
WHITE_POLE = (236, 236, 232)  # signal poles (white / light grey)
BLACK = (24, 24, 26)
INSUL = (226, 226, 222)
TANK = (150, 156, 158)        # transformer
CAB = (170, 176, 182)         # signal controller cabinet (grey)
CAB_BLUE = (52, 92, 150)
HEAD = (236, 244, 255)        # LED head (the owner's white)
RED_LENS = (210, 40, 34)
DARK_LENS = (40, 38, 36)
SHELTER = (220, 222, 224)
SEAT_STEEL = (180, 184, 188)
ORANGE_BIN = (232, 112, 30)
BLUE_STOOL = (40, 120, 200)
STOOLS = [(40, 120, 200), (200, 44, 40), (40, 150, 80), (226, 110, 160), (40, 150, 170)]
TABLE_BLUE = (52, 130, 206)
TABLE_WHITE = (232, 232, 228)
THERMOS = [(200, 40, 40), (40, 90, 170), (230, 230, 226)]
UMB = [[(200, 40, 40), (40, 140, 70), (240, 200, 40), (40, 90, 190)],
       [(40, 90, 190), (240, 240, 236), (40, 90, 190), (240, 240, 236)],
       [(240, 120, 30), (240, 200, 40), (240, 120, 30), (240, 200, 40)],
       [(200, 40, 40), (240, 240, 236), (200, 40, 40), (240, 240, 236)]]
BANNER = [[(30, 80, 170), (230, 200, 40), (200, 40, 40)], [(200, 30, 40), (240, 240, 236), (40, 110, 200)],
          [(240, 190, 30), (40, 40, 44), (200, 40, 40)]]
TRI_FRAME = [(150, 30, 34), (120, 24, 30), (176, 40, 36), (40, 40, 44)]
TRI_SEAT = [(180, 30, 34), (40, 40, 44), (40, 110, 70), (120, 24, 40)]
TYRE = (30, 30, 32)
RIM = (180, 182, 186)
BIKE_BLACK = (34, 34, 36)
RAIL = (190, 194, 198)
PLASTIC_WHITE = (236, 236, 232)
GREEN_SIGN = (30, 120, 70)


def _sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def _add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def _mul(a, k):
    return (a[0] * k, a[1] * k, a[2] * k)


def _cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def _dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def _unit(a):
    L = math.sqrt(_dot(a, a)) or 1.0
    return (a[0] / L, a[1] / L, a[2] / L)


def _uv(P, n):
    n = (abs(n[0]), abs(n[1]), abs(n[2]))
    if n[1] >= n[0] and n[1] >= n[2]:
        return [(p[0] * UVK, p[2] * UVK) for p in P]
    if n[0] >= n[2]:
        return [(p[2] * UVK, -p[1] * UVK) for p in P]
    return [(p[0] * UVK, -p[1] * UVK) for p in P]


class Piece:
    """one kit piece: a Mesh per class"""

    def __init__(self, pid):
        self.pid = pid
        self.m = {}
        self.attach = []   # wire attach points (pole frame), for the meta

    def mesh(self, cls):
        if cls not in self.m:
            self.m[cls] = Mesh()
        return self.m[cls]

    def face(self, cls, pts, out, rgb):
        """a flat polygon (3 or 4 corners) whose shown side faces `out` (any vector on that side)"""
        n = _cross(_sub(pts[1], pts[0]), _sub(pts[2], pts[0]))
        if _dot(n, out) < 0:
            pts = list(reversed(pts))
            n = _mul(n, -1)
        m = self.mesh(cls)
        U = _uv(pts, n)
        if len(pts) == 3:
            m.tri(pts[0], pts[1], pts[2], U[0], U[1], U[2], rgb)
        else:
            m.quad(pts[0], pts[1], pts[2], pts[3], U[0], U[1], U[2], U[3], rgb)

    def box(self, cls, c, s, rgb, yaw=0.0, skip=()):
        """axis box (turned by yaw about Y) centre c, size s; skip faces '+x', '-x', '+y', '-y', '+z', '-z'"""
        hx, hy, hz = s[0] / 2, s[1] / 2, s[2] / 2
        cy_, sy_ = math.cos(yaw), math.sin(yaw)

        def P(x, y, z):
            # Roblox yaw: local X -> (cos, 0, -sin), local Z -> (sin, 0, cos)
            return (c[0] + x * cy_ + z * sy_, c[1] + y, c[2] - x * sy_ + z * cy_)

        def D(x, y, z):
            return (x * cy_ + z * sy_, y, -x * sy_ + z * cy_)
        F = {
            "+x": ([P(hx, -hy, -hz), P(hx, hy, -hz), P(hx, hy, hz), P(hx, -hy, hz)], D(1, 0, 0)),
            "-x": ([P(-hx, -hy, -hz), P(-hx, -hy, hz), P(-hx, hy, hz), P(-hx, hy, -hz)], D(-1, 0, 0)),
            "+y": ([P(-hx, hy, -hz), P(-hx, hy, hz), P(hx, hy, hz), P(hx, hy, -hz)], D(0, 1, 0)),
            "-y": ([P(-hx, -hy, -hz), P(hx, -hy, -hz), P(hx, -hy, hz), P(-hx, -hy, hz)], D(0, -1, 0)),
            "+z": ([P(-hx, -hy, hz), P(hx, -hy, hz), P(hx, hy, hz), P(-hx, hy, hz)], D(0, 0, 1)),
            "-z": ([P(-hx, -hy, -hz), P(-hx, hy, -hz), P(hx, hy, -hz), P(hx, -hy, -hz)], D(0, 0, -1)),
        }
        for k, (pts, out) in F.items():
            if k not in skip:
                self.face(cls, pts, out, rgb)

    def prism(self, cls, a, b, r0, r1, rgb, n=8, caps=(True, True), rot=0.0):
        """an n-sided tube from a to b, radius r0 at a, r1 at b (square posts: n = 4, rot = pi / 4)"""
        ax = _unit(_sub(b, a))
        ref = (0.0, 1.0, 0.0) if abs(ax[1]) < 0.9 else (1.0, 0.0, 0.0)
        e1 = _unit(_cross(ax, ref))
        e2 = _cross(ax, e1)
        A, B, O = [], [], []
        for k in range(n):
            t = rot + 2 * math.pi * k / n
            d = _add(_mul(e1, math.cos(t)), _mul(e2, math.sin(t)))
            O.append(d)
            A.append(_add(a, _mul(d, r0)))
            B.append(_add(b, _mul(d, r1)))
        for k in range(n):
            k2 = (k + 1) % n
            mid = _unit(_add(O[k], O[k2]))
            self.face(cls, [A[k], A[k2], B[k2], B[k]], mid, rgb)
        if caps[0]:
            for k in range(1, n - 1):
                self.face(cls, [A[0], A[k], A[k + 1]], _mul(ax, -1), rgb)
        if caps[1]:
            for k in range(1, n - 1):
                self.face(cls, [B[0], B[k], B[k + 1]], ax, rgb)

    def ring(self, cls, c, axis, R, r, rgb, n1=16, n2=4):
        """a torus (tyres, fibre slack coils): centre c, axis, big radius R, tube radius r"""
        ax = _unit(axis)
        ref = (0.0, 1.0, 0.0) if abs(ax[1]) < 0.9 else (1.0, 0.0, 0.0)
        e1 = _unit(_cross(ax, ref))
        e2 = _cross(ax, e1)
        grid = []
        for i in range(n1):
            t = 2 * math.pi * i / n1
            rd = _add(_mul(e1, math.cos(t)), _mul(e2, math.sin(t)))
            row = []
            for j in range(n2):
                s = 2 * math.pi * j / n2 + math.pi / n2
                d = _add(_mul(rd, math.cos(s)), _mul(ax, math.sin(s)))
                row.append((_add(c, _add(_mul(rd, R), _mul(d, r))), d))
            grid.append(row)
        for i in range(n1):
            i2 = (i + 1) % n1
            for j in range(n2):
                j2 = (j + 1) % n2
                p = [grid[i][j][0], grid[i2][j][0], grid[i2][j2][0], grid[i][j2][0]]
                out = _unit(_add(_add(grid[i][j][1], grid[i2][j][1]), _add(grid[i2][j2][1], grid[i][j2][1])))
                self.face(cls, p, out, rgb)

    def disc(self, cls, c, axis, r, rgb, n=12):
        """a thin two-sided disc (umbrella canopies use cone())"""
        ax = _unit(axis)
        ref = (0.0, 1.0, 0.0) if abs(ax[1]) < 0.9 else (1.0, 0.0, 0.0)
        e1 = _unit(_cross(ax, ref))
        e2 = _cross(ax, e1)
        P = [_add(c, _add(_mul(e1, r * math.cos(2 * math.pi * k / n)), _mul(e2, r * math.sin(2 * math.pi * k / n)))) for k in range(n)]
        for k in range(1, n - 1):
            self.face(cls, [P[0], P[k], P[k + 1]], ax, rgb)

    def cone(self, cls, apex, base_c, R, cols, n=8, under=True):
        """an umbrella / parasol: n panels from the apex to a ring, coloured in turn; a darker underside 0.06 below"""
        ring = [(base_c[0] + R * math.cos(2 * math.pi * k / n + math.pi / n), base_c[1],
                 base_c[2] + R * math.sin(2 * math.pi * k / n + math.pi / n)) for k in range(n)]
        for k in range(n):
            a, b = ring[k], ring[(k + 1) % n]
            col = cols[k % len(cols)]
            self.face(cls, [apex, a, b], (0, 1, 0), col)
            if under:
                d = (0, -0.06, 0)
                dark = tuple(int(x * 0.62) for x in col)
                self.face(cls, [_add(apex, d), _add(a, d), _add(b, d)], (0, -1, 0), dark)

    def tris(self):
        return sum(m.tris for m in self.m.values())


KIT = {}


def piece(pid):
    p = Piece(pid)
    KIT[pid] = p
    return p


# ============================================================================================== power poles
POLE_H = 9.0 * S          # 27 studs (9 m street pole)
ARM_Y = POLE_H - 0.9      # top crossarm
RACK_Y = 7.0 * S          # the LV / cable rack
# wire attach points in the pole frame (x along the road, y up, z across): the client spreads a span's n wires over them
ATTACH = [(0.0, ARM_Y + 0.35, -2.6), (0.0, ARM_Y + 0.35, 2.6), (0.0, ARM_Y + 0.35, -1.2), (0.0, ARM_Y + 0.35, 1.2),
          (0.0, RACK_Y + 1.2, 0.75), (0.0, RACK_Y + 0.6, 0.75), (0.0, RACK_Y, 0.75), (0.0, RACK_Y - 0.6, 0.75),
          (0.0, RACK_Y + 1.2, -0.75), (0.0, RACK_Y + 0.6, -0.75), (0.0, RACK_Y, -0.75), (0.0, RACK_Y - 0.6, -0.75),
          (0.0, RACK_Y - 2.4, 0.6), (0.0, RACK_Y - 2.4, -0.6)]


def pole_body(p, h=POLE_H):
    """a prestressed concrete pole, square, tapering 0.30 -> 0.16 m, the bottom 1.5 m dirty"""
    w0, w1 = 0.30 * S / 2 * math.sqrt(2), 0.16 * S / 2 * math.sqrt(2)
    split = 1.5 * S
    ws = w0 + (w1 - w0) * split / h
    p.prism("SCO", (0, -1.0, 0), (0, split, 0), w0, ws, CONC_DIRT, n=4, rot=math.pi / 4, caps=(False, False))
    p.prism("SCO", (0, split, 0), (0, h, 0), ws, w1, CONC, n=4, rot=math.pi / 4, caps=(False, True))


def crossarm(p, y, L=2.0 * S, insulators=4):
    """a steel channel across the road (local Z) with pin insulators on top"""
    p.box("SMT", (0, y, 0), (0.24, 0.3, L), STEEL)
    for k in range(insulators):
        z = -L / 2 + 0.5 + (L - 1.0) * k / max(1, insulators - 1)
        if abs(z) < 0.45:
            continue
        p.prism("SPL", (0, y + 0.15, z), (0, y + 0.6, z), 0.13, 0.09, INSUL, n=6)


def rack(p, y):
    """the cable rack: two short brackets with four shackle insulators each side"""
    for side in (-1, 1):
        p.box("SMT", (0, y, side * 0.42), (0.16, 2.2, 0.16), STEEL)
        for k in range(4):
            yy = y - 0.6 + 0.6 * k - 0.3
            p.prism("SPL", (0, yy, side * 0.5), (0, yy, side * 0.82), 0.1, 0.1, INSUL, n=6)


def make_poles():
    for pid, kind in (("ppolea", "plain"), ("ppoleb", "coil"), ("ppolel", "lamp"), ("ppolebl", "coillamp")):
        p = piece(pid)
        pole_body(p)
        crossarm(p, ARM_Y)
        rack(p, RACK_Y)
        p.attach = ATTACH
        if "coil" in kind:
            # a coiled slack loop of fibre and a grey junction box (one pole in three, survey 2.4)
            p.ring("SPL", (0.55, RACK_Y - 3.6, 0), (1, 0, 0), 0.9, 0.06, BLACK, n1=14, n2=4)
            p.box("SPL", (0.38, RACK_Y - 5.4, 0), (0.3, 1.2, 0.9), (150, 152, 150))
        if "lamp" in kind:
            # an LED cobra head on a 1.8 m arm toward the road (local -X... the road is local +Z side: see street_1to1)
            y0 = RACK_Y + 2.2
            pts = [(0, y0, 0.25), (0, y0 + 0.9, 2.0), (0, y0 + 1.5, 4.0), (0, y0 + 1.6, 5.2)]
            for a, b in zip(pts, pts[1:]):
                p.prism("SMT", a, b, 0.09, 0.08, GALV, n=6)
            p.box("SNE", (0, y0 + 1.42, 5.75), (0.6, 0.3, 1.5), HEAD)
        # the head of the lamp variant is SNE: YangonStreetKit adds the light to it


def make_transformer():
    """two poles 2.5 m apart along the road, an H-frame platform at 3.7 m, a grey tank, fuse cut-outs, a warning plate"""
    p = piece("trafo")
    gap = 2.5 * S / 2
    for sx in (-gap, gap):
        q = Piece("tmp")
        pole_body(q)
        crossarm(q, ARM_Y)
        for cls, m in q.m.items():
            mm = p.mesh(cls)
            k = len(mm.P)
            mm.P += [(v[0] + sx, v[1], v[2]) for v in m.P]
            mm.N += m.N
            mm.U += m.U
            mm.C += m.C
            mm.T += [t + k for t in m.T]
    rack(p, RACK_Y)
    py = 3.7 * S
    p.box("SMT", (0, py, -0.75), (2 * gap + 0.9, 0.3, 0.2), STEEL)
    p.box("SMT", (0, py, 0.75), (2 * gap + 0.9, 0.3, 0.2), STEEL)
    for sx in (-gap + 0.9, 0, gap - 0.9):
        p.box("SMT", (sx, py + 0.2, 0), (0.18, 0.1, 1.7), STEEL)
    p.box("SPL", (0, py + 0.25 + 1.4 * S / 2, 0), (1.2 * S, 1.4 * S, 1.0 * S * 0.9), TANK, skip=("-y",))
    for k in (-1, 0, 1):
        p.prism("SPL", (k * 0.9, py + 0.25 + 1.4 * S, -0.4), (k * 0.9, py + 0.25 + 1.4 * S + 0.8, -0.4), 0.15, 0.1, (90, 70, 50), n=6)
        p.prism("SPL", (k * 1.4, ARM_Y - 2.4, 0), (k * 1.4, ARM_Y - 1.2, 0), 0.08, 0.08, INSUL, n=6)
    p.box("SMT", (0, ARM_Y - 2.6, 0), (2 * gap + 0.6, 0.24, 0.24), STEEL)
    # the red warning plate on the near pole
    p.box("SPL", (-gap, 2.4 * S, 0.33), (0.6, 0.75, 0.04), (200, 30, 30))
    p.attach = ATTACH


# ============================================================================================== street lamps
def lamp_post(p, h, arms):
    """a galvanised octagonal post 10 m, tapering 0.2 -> 0.1 m, arms (direction z sign) of 2 m with a white LED head"""
    p.prism("SMT", (0, -0.5, 0), (0, 0.45, 0), 0.75, 0.75, (150, 150, 150), n=8)       # base flange
    p.prism("SMT", (0, 0.45, 0), (0, h, 0), 0.32, 0.17, GALV, n=8, caps=(True, True))
    for sgn in arms:
        pts = [(0, h - 1.2, 0), (0, h - 0.2, sgn * 1.5), (0, h + 0.2, sgn * 3.6), (0, h + 0.3, sgn * 5.4)]
        for a, b in zip(pts, pts[1:]):
            p.prism("SMT", a, b, 0.12, 0.1, GALV, n=6)
        p.box("SNE", (0, h + 0.12, sgn * 6.3), (0.36 * S / 1.2, 0.36, 0.7 * S), HEAD)


def make_lamps():
    lamp_post(piece("lamp1"), 10.0 * S, (1,))
    lamp_post(piece("lamp2"), 10.0 * S, (1, -1))


# ============================================================================================== traffic signals
def signal_head(p, x, y, z):
    """a HORIZONTAL black housing 1.25 x 0.40 x 0.25 m: three lamps side by side and a two-digit countdown, visors.
    Front faces local -Z."""
    W, Hh, D = 1.25 * S, 0.40 * S, 0.25 * S
    p.box("SPL", (x, y, z), (W, Hh, D), BLACK)
    for k, col in enumerate((DARK_LENS, DARK_LENS, RED_LENS)):
        lx = x - W / 2 + 0.55 + k * 0.9
        p.disc("SPL", (lx, y, z - D / 2 - 0.06), (0, 0, -1), 0.42, col, n=10)
        p.box("SPL", (lx, y + 0.5, z - D / 2 - 0.25), (0.95, 0.06, 0.5), BLACK)
    # the countdown panel (dark, red digits off): a recessed dark face at the end
    p.box("SPL", (x + W / 2 - 0.55, y, z - D / 2 - 0.07), (0.8, 0.8, 0.08), (60, 20, 18))
    # the hanger
    p.prism("SMT", (x, y + Hh / 2, z), (x, y + Hh / 2 + 0.55, z), 0.07, 0.07, BLACK, n=6)


def make_signals():
    """a white pole 7 m with a mast arm of L (6 / 8 / 10 m) along +X over the carriageway, two heads (mid, tip), a CCTV
    camera on the pole top; heads face local -Z (the oncoming traffic)"""
    for L in (6, 8, 10):
        p = piece("sig%d" % L)
        h = 7.0 * S
        p.prism("SMT", (0, -0.5, 0), (0, h, 0), 0.4, 0.33, WHITE_POLE, n=10)
        arm_y = h - 1.2
        p.prism("SMT", (0.2, arm_y, 0), (L * S, arm_y, 0), 0.2, 0.14, WHITE_POLE, n=8)
        p.prism("SMT", (0.2, arm_y - 1.6, 0), (2.4, arm_y - 0.05, 0), 0.08, 0.08, WHITE_POLE, n=6)   # brace
        hy = arm_y - 0.2 - 0.55 - 0.6
        signal_head(p, L * S * 0.5, hy, 0)
        signal_head(p, L * S - 2.2, hy, 0)
        # CCTV camera on a bracket at the top
        p.box("SMT", (0, h + 0.15, -0.5), (0.2, 0.3, 1.1), WHITE_POLE)
        p.box("SPL", (0, h + 0.15, -1.3), (0.55, 0.5, 1.0), PLASTIC_WHITE)
        p.disc("SPL", (0, h + 0.15, -1.86), (0, 0, -1), 0.18, BLACK, n=8)
    c = piece("sigcab")   # the grey and blue controller cabinet 0.6 x 0.4 x 1.1 m
    c.box("SMT", (0, 0.2, 0), (1.9, 0.9, 1.3), (110, 108, 104))        # plinth (sunk 0.25)
    c.box("SMT", (0, 0.65 + 1.65, 0), (1.8, 3.3, 1.2), CAB, skip=("-y",))
    c.box("SMT", (0, 0.65 + 3.3 + 0.08, 0), (2.0, 0.16, 1.4), CAB_BLUE)


# ============================================================================================== bus stops
def make_bus_stops():
    """FMI Decaux shelter 4.2 x 1.5 m, roof 2.4-2.6 m, two round back posts and one front post, glass back, a lit ad box
    closing one end, 4 perforated steel seats at 0.45 m, the white YBS box on top (its face is an atlas plate, T record),
    a white tiled plinth 0.1 m. Open side = local -Z (the road)."""
    p = piece("busd")
    L, D = 4.2 * S, 1.5 * S
    p.box("SPL", (0, 0.15, 0), (L + 0.6, 0.3 + 0.3, D + 0.6), (226, 226, 222), skip=("-y",))       # plinth (0.3 over)
    base = 0.45
    for x, z in ((-L / 2 + 0.3, D / 2 - 0.3), (L / 2 - 0.3, D / 2 - 0.3), (-L / 2 + 0.3, -D / 2 + 0.4)):
        p.prism("SMT", (x, base, z), (x, 7.4, z), 0.16, 0.16, SHELTER, n=8)
    # roof: a flat slab sloping a little back
    p.box("SMT", (0, 7.55, 0), (L + 0.6, 0.3, D + 0.9), SHELTER)
    # glass back panel
    p.box("SGL", (0.6, 3.9, D / 2 - 0.3), (L - 2.4, 5.6, 0.12), (150, 172, 178))
    # the ad box at the +X end (silver frame, a lit face both sides: plain light panel, no ad text)
    p.box("SMT", (L / 2 - 0.3, 3.4, 0.2), (0.6, 5.6, 3.6), (200, 202, 206))
    p.box("SPL", (L / 2 - 0.3 - 0.36, 3.6, 0.2), (0.06, 4.8, 3.2), (238, 236, 220))
    p.box("SPL", (L / 2 - 0.3 + 0.36, 3.6, 0.2), (0.06, 4.8, 3.2), (238, 236, 220))
    # seats on a rail
    p.box("SMT", (-1.0, 1.0, D / 2 - 1.0), (L - 3.6, 0.15, 0.15), SEAT_STEEL)
    for k in range(4):
        x = -L / 2 + 1.4 + k * 1.75
        p.box("SMT", (x, 1.38, D / 2 - 1.15), (1.35, 0.1, 1.2), SEAT_STEEL)
        p.box("SMT", (x, 2.0, D / 2 - 0.55), (1.35, 1.2, 0.1), SEAT_STEEL)
        p.box("SMT", (x, 0.9 + base / 2, D / 2 - 1.1), (0.12, 1.0, 0.12), SEAT_STEEL)
    # the YBS box on the roof (white, 1.2 x 0.45 x 0.15 m): its road face carries the atlas plate (T record)
    p.box("SPL", (-1.2, 7.7 + 0.68, -D / 2 + 0.2), (3.6, 1.35, 0.45), (245, 245, 243))
    # a pole stop: a 3 m steel pole with a white plate 0.6 x 0.4 m (atlas plate both sides, T records)
    q = piece("busp")
    q.prism("SMT", (0, -0.5, 0), (0, 9.0, 0), 0.1, 0.1, (170, 172, 176), n=8)
    q.box("SPL", (0, 7.6, 0), (1.85, 1.25, 0.09), (245, 245, 243))
    # the orange YCDC wheelie bin 0.6 x 0.7 x 1.1 m
    b = piece("bin")
    b.box("SPL", (0, 1.5, 0), (1.75, 2.9, 2.0), ORANGE_BIN)
    b.box("SPL", (0, 3.05, -0.05), (1.9, 0.2, 2.2), (200, 92, 24))
    for z in (-0.7, 0.7):
        b.prism("SPL", (0.95, 0.3, z), (1.05, 0.3, z), 0.3, 0.3, TYRE, n=8)


# ============================================================================================== street name signs
def make_signs():
    """older YCDC sign: a 2.6 m grey pole; plates (0.9 x 0.3 m, green; both faces carry the atlas plate) go on as their
    own piece, turned to their street"""
    p = piece("spole")
    p.prism("SMT", (0, -0.5, 0), (0, 8.5, 0), 0.09, 0.09, (150, 152, 156), n=8)
    q = piece("splate")   # plate along local X, centre at its origin
    q.box("SMT", (0, 0, 0), (2.85, 1.05, 0.1), (200, 204, 206))
    # the stop / street plate faces are T records 0.06 in front of this plate (no mesh face under the picture's area
    # differs by more than the plate's own colour: the picture covers it whole)


# ============================================================================================== tea shops
def stool(p, x, z, col, h=0.28 * S):
    """a low moulded stool 0.27 m square, 0.28 m high (splayed legs as one tapered box)"""
    p.box("SPL", (x, h - 0.06, z), (0.82, 0.12, 0.82), col)
    p.prism("SPL", (x, 0.0, z), (x, h - 0.12, z), 0.56, 0.46, col, n=4, rot=math.pi / 4, caps=(False, False))


def low_table(p, x, z, col, h=0.47 * S, w=0.6 * S, cups=True, seed=0):
    p.box("SPL", (x, h - 0.08, z), (w, 0.16, w), col)
    p.prism("SPL", (x, 0.0, z), (x, h - 0.16, z), w * 0.5, w * 0.42, col, n=4, rot=math.pi / 4, caps=(False, False))
    if cups:
        th = THERMOS[seed % len(THERMOS)]
        p.prism("SPL", (x - 0.35, h, z - 0.3), (x - 0.35, h + 1.0, z - 0.3), 0.2, 0.2, th, n=8)
        p.box("SPL", (x + 0.3, h + 0.04, z + 0.25), (0.75, 0.08, 0.55), (180, 120, 60))     # the cup tray
        for k in range(3):
            p.prism("SPL", (x + 0.1 + k * 0.22, h + 0.08, z + 0.25), (x + 0.1 + k * 0.22, h + 0.32, z + 0.25),
                    0.07, 0.08, (240, 240, 236), n=6)


def chair(p, x, z, yaw, col):
    """a blue moulded plastic chair: seat 0.43 m, back to 0.80 m; front faces local -X rotated by yaw"""
    c, s = math.cos(yaw), math.sin(yaw)

    def R(u, w):
        return (x + u * c + w * s, z - u * s + w * c)
    sx_, sz_ = R(0, 0)
    p.box("SPL", (sx_, 1.25, sz_), (1.3, 0.12, 1.3), col, yaw=yaw)
    bx, bz = R(0.6, 0)
    p.box("SPL", (bx, 1.9, bz), (0.1, 1.2, 1.25), col, yaw=yaw)
    for u, w in ((-0.55, -0.55), (-0.55, 0.55), (0.55, -0.55), (0.55, 0.55)):
        lx, lz = R(u, w)
        p.prism("SPL", (lx, 0, lz), (lx, 1.19, lz), 0.09, 0.08, col, n=4, rot=math.pi / 4, caps=(False, False))


def make_tea():
    """the classic low setup (2 low tables, 7 stools) in two colour mixes, and the chair-and-table setup (photo
    tea_shop/02: blue plastic chairs round blue tables 0.70 m). Footprint about 2.4 x 1.6 m (7 x 5 studs)."""
    for k, cols in enumerate(([BLUE_STOOL] * 5 + [STOOLS[1], STOOLS[2]], [STOOLS[1], STOOLS[3], BLUE_STOOL, STOOLS[2], BLUE_STOOL, STOOLS[4], STOOLS[1]])):
        p = piece("tealow%d" % k)
        low_table(p, -1.6, 0, TABLE_BLUE if k == 0 else TABLE_WHITE, seed=k)
        low_table(p, 1.8, 0.2, TABLE_BLUE, seed=k + 1)
        spots = [(-1.6, -1.6), (-1.6, 1.6), (-3.1, 0.1), (1.8, -1.45), (1.8, 1.85), (3.3, 0.3), (0.1, 1.9)]
        for (x, z), col in zip(spots, cols):
            stool(p, x, z, col)
    p = piece("teachair")
    h = 0.70 * S
    for tx in (-2.2, 2.2):
        p.box("SPL", (tx, h - 0.1, 0), (2.1, 0.2, 2.1), TABLE_BLUE)
        p.prism("SPL", (tx, 0, 0), (tx, h - 0.2, 0), 0.95, 0.8, TABLE_BLUE, n=4, rot=math.pi / 4, caps=(False, False))
        for ang, dx, dz in ((0.0, -1.75, 0.0), (math.pi, 1.75, 0.0), (math.pi / 2, 0.0, 1.75)):
            chair(p, tx + dx, dz, ang, (40, 130, 210))


# ============================================================================================== stalls and carts
def umbrella(p, x, z, cols, R=1.1 * S, h=2.3 * S):
    p.prism("SMT", (x, 0, z), (x, h + 0.4, z), 0.07, 0.06, (60, 60, 62), n=6)
    p.cone("SFB", (x, h + 0.75, z), (x, h - 0.15, z), R, cols, n=8)


def make_stalls():
    """the street food cart (photo food_cart/02-03): a steel counter 1.7 x 0.6 x 0.9 m wrapped in a banner of colour
    blocks (no text), steel trays, a stove and a pot, under a 2.2 m multi-colour umbrella, a stool; the betel stall: a
    small table with a glass-top box and a stool, a blue umbrella"""
    for k in range(4):
        p = piece("cart%d" % k)
        L, D, H_ = 1.7 * S, 0.6 * S, 0.9 * S
        p.box("SMT", (0, H_ - 0.06, 0), (L, 0.12, D), (196, 198, 200))
        p.box("SMT", (0, (H_ - 0.12) / 2 + 0.25, 0), (L - 0.2, H_ - 0.12 - 0.5, D - 0.2), (150, 152, 154), skip=("-z", "+y", "-y"))
        bl = BANNER[k % len(BANNER)]
        for j in range(3):
            x0 = -L / 2 + 0.1 + j * (L - 0.2) / 3
            p.box("SFB", (x0 + (L - 0.2) / 6, (H_ - 0.12) / 2 + 0.25, -D / 2 + 0.04), ((L - 0.2) / 3 - 0.02, H_ - 0.12 - 0.5, 0.06), bl[j])
        for x in (-L / 2 + 0.2, L / 2 - 0.2):
            for z in (-D / 2 + 0.2, D / 2 - 0.2):
                p.prism("SMT", (x, 0, z), (x, 0.26, z), 0.08, 0.08, (120, 120, 122), n=4, caps=(False, False))
        p.box("SMT", (-1.2, H_ + 0.06, 0.1), (1.6, 0.12, 1.2), (210, 212, 214))     # tray
        p.prism("SMT", (1.3, H_, 0.1), (1.3, H_ + 0.9, 0.1), 0.55, 0.55, (90, 90, 92), n=10)   # pot
        p.prism("SPL", (2.4, 0, 1.3), (2.4, 1.1, 1.3), 0.55, 0.6, (40, 90, 170), n=8)        # a plastic bucket
        umbrella(p, 0.4, 1.0, UMB[k])
        stool(p, -1.6, 1.9, STOOLS[k % len(STOOLS)], h=0.45 * S)
    p = piece("betel")
    p.box("SPL", (0, 2.18, 0), (2.4, 0.12, 1.5), (120, 80, 50))
    for x in (-1.05, 1.05):
        for z in (-0.6, 0.6):
            p.prism("SPL", (x, 0, z), (x, 2.12, z), 0.07, 0.07, (90, 60, 40), n=4, caps=(False, False))
    p.box("SPL", (0, 2.24 + 0.45, -0.05), (1.9, 0.9, 1.2), (170, 190, 186))              # the glass-top box (opaque)
    p.box("SPL", (0, 2.24 + 0.95, -0.05), (2.0, 0.1, 1.3), (200, 214, 210))
    p.box("SPL", (-0.5, 3.36, 0.0), (0.6, 0.2, 0.6), (40, 120, 50), skip=("-y",))                      # betel leaves pile
    stool(p, 0.2, 1.7, STOOLS[2], h=0.45 * S)
    umbrella(p, 1.4, 0.9, UMB[1], R=0.9 * S, h=2.1 * S)
    # litter clump (white and coloured plastic) at pole bases
    q = piece("litter")
    for k, (x, z, s_, col) in enumerate(((0, 0, 0.6, (236, 236, 230)), (0.5, 0.3, 0.4, (200, 40, 40)), (-0.4, 0.4, 0.45, (40, 90, 180)),
                                       (0.2, -0.5, 0.35, (236, 236, 230)), (-0.6, -0.3, 0.3, (80, 160, 70)))):
        q.box("SPL", (x, s_ / 2 - 0.05 - k * 0.01, z), (s_ * 1.4, s_, s_), col, yaw=k * 0.7, skip=("-y",))


# ============================================================================================== trishaw
def wheel(p, c, R, axis=(0, 0, 1), hub=True):
    p.ring("SPL", c, axis, R - 0.12, 0.11, TYRE, n1=18, n2=4)
    p.ring("SMT", c, axis, R - 0.3, 0.05, RIM, n1=18, n2=3)
    if hub:
        a = _unit(axis)
        p.prism("SMT", _add(c, _mul(a, -0.18)), _add(c, _mul(a, 0.18)), 0.12, 0.12, RIM, n=6)
        for k in range(6):   # a few spokes
            t = 2 * math.pi * k / 6
            e1 = (math.cos(t), math.sin(t), 0.0) if abs(a[2]) > 0.9 else (0.0, math.sin(t), math.cos(t))
            p.prism("SMT", c, _add(c, _mul(e1, R - 0.32)), 0.025, 0.025, RIM, n=3, caps=(False, False))


def make_trishaws():
    """saiq-ka (photos trishaw/01-02): a black roadster bicycle (28-inch wheels 0.71 m, wheelbase 1.15 m, 1.85 m long,
    handlebar 1.05 m) with a red / maroon sidecar bolted BESIDE it on the rider's RIGHT, its wheel level with the bike's
    rear wheel, two padded seats back to back (one faces forward, one back), box about 1.2 x 0.65 m, seats at 0.55-0.6 m.
    Forward = local +X; the rider's right = local +Z."""
    for k in range(4):
        p = piece("tri%d" % k)
        fr, seat = TRI_FRAME[k], TRI_SEAT[k]
        R = 0.71 * S / 2
        rear, front = (-1.15 * S / 2, R, 0.0), (1.15 * S / 2, R, 0.0)
        wheel(p, rear, R)
        wheel(p, front, R)
        # bicycle frame (black): top tube, down tube, seat tube, stays, fork, handlebar, saddle
        bb = (-0.15, R - 0.2, 0.0)
        st_top = (-0.55, 2.85, 0.0)
        head = (1.05, 3.0, 0.0)
        for a, b in ((bb, st_top), (st_top, head), (bb, head), (bb, rear), (st_top, rear), (head, front),
                     (head, (1.0, 3.35, 0.0))):
            p.prism("SMT", a, b, 0.06, 0.06, BIKE_BLACK, n=4, caps=(False, False))
        p.prism("SMT", (0.95, 3.35, -0.9), (0.95, 3.35, 0.9), 0.05, 0.05, BIKE_BLACK, n=4)
        p.box("SPL", (-0.6, 3.05, 0.0), (0.75, 0.22, 0.5), BLACK)        # saddle
        p.prism("SMT", (-0.6, 2.85, 0), (-0.6, 2.95, 0), 0.05, 0.05, RIM, n=4)
        # sidecar: chassis rails + two mounting bars to the bike, its wheel level with the rear wheel
        sz = 2.85                            # sidecar centre line, rider's right
        rs = 0.6 * S / 2
        wheel(p, (rear[0], rs, sz + 1.1), rs)
        p.box("SMT", (-0.4, 1.25, sz), (3.6, 0.22, 1.95), fr)            # floor / foot board frame
        p.box("SMT", (-0.4, 1.2, sz + 0.85), (1.4, 0.16, 0.16), fr)      # axle arm
        for x in (-1.2, 0.6):
            p.prism("SMT", (x, 1.3, sz - 0.95), (x, 1.5, 0.05), 0.07, 0.07, fr, n=4)
        # the seat box (red vinyl), two cushions back to back with a shared back board
        p.box("SMT", (-0.4, 1.36 + 0.4, sz), (3.0, 0.8, 1.85), fr, skip=("-y",))
        for sgn in (-1, 1):
            p.box("SFB", (-0.4 + sgn * 0.75, 2.16 + 0.18, sz), (1.25, 0.36, 1.7), seat)
            p.box("SFB", (-0.4 + sgn * 0.08, 2.16 + 0.9, sz), (0.14, 1.2, 1.7), seat)
        # side panel (rider side) and a grab bar
        p.box("SMT", (-0.4, 2.0, sz - 0.98), (3.0, 0.5, 0.06), fr)
        p.prism("SMT", (0.9, 2.3, sz - 0.95), (0.9, 2.3, sz + 0.95), 0.04, 0.04, RIM, n=4)


# ============================================================================================== drains, fences
def make_drains():
    """a slab-covered drain run (survey 1A-1C; photo kerb_paint/01): 4 m (12 studs) of concrete covers 0.5 x 0.6 m with
    hairline gaps (dark channel under), along local X, the channel walls going 1.6 studs into the ground. Variants: whole,
    one slab missing (black water shows), a square grate."""
    for pid, kind in (("draina", "whole"), ("drainb", "gap"), ("draing", "grate")):
        p = piece(pid)
        L, W, top = 12.0, 1.8, 0.36
        p.box("SCO", (0, top - 1.0, -W / 2 + 0.12), (L, 2.0, 0.24), CONC_SLAB, skip=("-y", "+y"))   # channel walls
        p.box("SCO", (0, top - 1.0, W / 2 - 0.12), (L, 2.0, 0.24), CONC_SLAB, skip=("-y", "+y"))
        p.box("SCO", (-L / 2 + 0.12, top - 1.0, 0), (0.24, 2.0, W - 0.48), CONC_SLAB, skip=("-y", "+y", "+z", "-z"))
        p.box("SCO", (L / 2 - 0.12, top - 1.0, 0), (0.24, 2.0, W - 0.48), CONC_SLAB, skip=("-y", "+y", "+z", "-z"))
        p.box("SPL", (0, top - 0.55, 0), (L - 0.7, 0.02, W - 0.6), (26, 28, 26), skip=("-y", "+x", "-x", "+z", "-z"))   # dark water
        n = 8
        sl = (L - 0.1) / n
        miss = 5 if kind == "gap" else -1
        for k in range(n):
            if k == miss:
                continue
            x = -L / 2 + 0.05 + sl * (k + 0.5)
            col = tuple(int(c_ * (0.9 + 0.1 * ((k * 37) % 5) / 4)) for c_ in CONC_SLAB)
            if kind == "grate" and k == 3:
                for j in range(5):
                    p.box("SMT", (x - 0.6 + j * 0.3, top - 0.06, 0), (0.12, 0.12, W - 0.5), (60, 58, 56))
                continue
            p.box("SCO", (x, top - 0.12, 0), (sl - 0.08, 0.24, W + 0.12), col, skip=("-y",))


def make_fence():
    """median railing 1.1 m, 3 m (9 studs) along X: top and bottom rails, vertical bars every 0.15 m, posts at the ends"""
    p = piece("mfence")
    L, H_ = 9.0, 1.1 * S
    for y in (0.5, H_ - 0.12):
        p.box("SMT", (0, y, 0), (L - 0.02, 0.14, 0.14), RAIL)
    for x in (-L / 2 + 0.12, L / 2 - 0.12):
        p.box("SMT", (x, H_ / 2 - 0.25, 0), (0.22, H_ + 0.5, 0.22), RAIL)
    n = 18
    for k in range(1, n):
        x = -L / 2 + L * k / n
        p.prism("SMT", (x, 0.57, 0), (x, H_ - 0.19, 0), 0.05, 0.05, RAIL, n=4, caps=(False, False))


# ============================================================================================== build + export
def build():
    make_poles()
    make_transformer()
    make_lamps()
    make_signals()
    make_bus_stops()
    make_signs()
    make_tea()
    make_stalls()
    make_trishaws()
    make_drains()
    make_fence()
    return KIT


def export():
    build()
    os.makedirs(GLB, exist_ok=True)
    os.makedirs(OUT, exist_ok=True)
    named, meta, bad_total = [], {}, 0
    for pid, p in KIT.items():
        items = []
        for cls, m in p.m.items():
            for i in range(0, len(m.T), 3):
                tri = (m.P[m.T[i]], m.P[m.T[i + 1]], m.P[m.T[i + 2]])
                items.append((tri, (cls, m.C[m.T[i]])))
        bad, tl = flicker(items)
        if bad:
            print("  flicker", pid, len(bad))
            for i, j, g, ar in bad[:4]:
                print("     ", tl[i][1], tl[j][1], "gap %.3f area %.3f" % (g, ar), [tuple(round(c, 2) for c in p) for p in tl[i][0]])
        bad_total += len(bad)
        meta[pid] = dict(parts={}, tris=p.tris(), attach=p.attach)
        for cls, m in p.m.items():
            lo, hi = m.box()
            cen = [(lo[i] + hi[i]) / 2 for i in range(3)]
            siz = [max(0.05, hi[i] - lo[i]) for i in range(3)]
            nm = code(cls, pid, cen, siz)
            named.append((nm, m))
            meta[pid]["parts"][cls] = dict(name=nm, tris=m.tris, lo=lo, hi=hi)
    path = os.path.join(GLB, "street_kit.glb")
    info = write_glb(path, named, generator="street_kit.py")
    n, bad = check_glb(path, info)
    assert not bad, bad
    json.dump(meta, open(os.path.join(OUT, "kit_meta.json"), "w"), indent=1)
    tot = sum(v["tris"] for v in meta.values())
    print("street kit: %d pieces, %d meshes, %d triangles, flicker pairs %d -> %s" % (len(KIT), n, tot, bad_total, path))
    for pid, v in meta.items():
        print("  %-10s %5d tris  %s" % (pid, v["tris"], " ".join(v["parts"])))
    return meta


if __name__ == "__main__":
    export()
