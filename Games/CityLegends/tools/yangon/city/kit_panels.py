"""kit_panels.py (2026-11-16, rescale step 3.7): the reusable facade kit of the 1:1 Yangon buildings.

Ordinary buildings are no longer one unique mesh per cell (the 15,537-mesh trap, CLAUDE.md "Unique meshes stop the map
loading"). Every street wall is cut into PANELS: k bays wide (k in K_SET) x the building's full height (ground floor +
upper floors at real heights). A panel is built once from kit.py's primitives (windows with reveals and grilles, cages,
blue corrugated awnings, shop bays, signs, AC units, laundry, stains) and reused by every wall of that archetype /
role / floor count, stretched along the wall by at most +-15% (rescale plan: "about +-15% stretch at most").

Each panel is up to three MeshParts, one per material class, named like the YangonMaterials kit rules expect:
  W  "KWX" -> in Studio the part takes the BUILDING's wall code (KW1, KW4, KW6, KWG ...): Plaster + YgnRenderPainted
       (KWG / KWD2 / KWC: YgnRenderStained), Color = that code's calibrated colour; the mesh's vertex colours only darken
       (stains, slab edges, grime), so one mesh serves every wall colour.
  M  "KGR" -> glass, grilles, cages, frames, AC units, shutters, shop insides, roller shutters: Metal + YgnSteelPainted,
       Color white, the colours in the vertex colours (landmark_glb3d.GROUPS, the midday-calibrated kit colours).
  C  "KAR" -> awnings, signs, banners, laundry, tarps, nets: Fabric + YgnCanvas, Color white, vertex colours.
Window panes for the night layer are NOT in the panels: every window's pane is returned as a quad, and the placer
lights ~22% of them per building in the cell night meshes (tag FacadeNight).

Panel frame (studs): X along the wall (0 .. k * bay), Y up from the base, Z out of the wall (+Z = the street side; the
wall plane is Z = 0, the building is at Z < 0). kit.py works in metres with y into the building and z up: the map
(x, y, z) -> (X, Y, Z) = (x*3, z*3, -y*3) is a proper rotation, so kit.py's winding stays right.

    from kit_panels import Kit
    kit = Kit()
    pid, bay = kit.panel("walkup", "front", floors=5, k=3, var=1, shop=True)   # -> id, bay width in studs
    kit.meshes()   # {pid: {"W": Mesh, "M": Mesh, "C": Mesh, "panes": [quad, ...], "w": width, "h": height}}
"""
import math
import os
import sys
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kit as K  # noqa: E402
from glb import Mesh  # noqa: E402
from landmark_glb3d import GROUPS, box_uv  # noqa: E402

S = 3.0
GF_SHOP = 13.0 / S     # ground floor with shops: 4.33 m (13 studs)
FH = 10.0 / S          # every upper floor: 3.33 m (10 studs; owner: "about 3.3 m a floor = 10 studs")
K_SET = (1, 2, 3, 4, 6)

# archetype -> bay (m), ground floor (m), parapet (m)
ARCH = {
    "walkup":   dict(bay=3.0, gf=3.9, par=0.9),
    "township": dict(bay=5.0, gf=GF_SHOP, par=0.6),
    "house":    dict(bay=3.5, gf=3.3, par=0.0),
    "villa":    dict(bay=4.0, gf=3.6, par=0.0),
    "condo":    dict(bay=3.6, gf=4.5, par=1.2),
    "civic":    dict(bay=3.5, gf=3.6, par=0.8),
    "shed":     dict(bay=4.5, gf=4.5, par=0.0),
    # (2026-11-16, P3 downtown) the colonial shophouse row (kit_reference section 1: Pansodan / Mahabandoola / 19th-50th
    # streets): bay 2.4 (window pitch 1.8-2.4), ground floor 4.6 (4.5-5.5 main roads), upper floors 3.8 (3.6-4.2), a 1.2 m
    # parapet over a heavy cornice. Its own floor height `fh` (the other archetypes use FH)
    "colonial": dict(bay=2.4, gf=4.6, par=1.2, fh=3.8),
}

# class of each kit group
WALL_K = {"KWX": 1.0, "KW0": 1.0, "KWG": 0.74, "KCO": 0.82, "KSU": 0.84, "KST": 0.66, "KGM1": 0.93, "KGM2": 0.88,
          "KGM3": 0.8, "KGB": 0.72, "KW1": 1.0, "KW4": 1.0, "KW6": 1.0}
CLOTH = {"KAW", "KAR", "KTP", "KNT", "KS1", "KS2", "KS3", "KS4", "KSW", "KSV", "KL1", "KL2", "KL3", "KL4", "KL5", "KL6"}
NIGHT = {"NWH", "NWA", "NWY", "NWC"}
ROOF_G = {"KRO", "KRS2"}   # the pitched roof sheet of the hip / gable pieces (class R: named by the sheet code in Studio)
# per-bay repaints inside a wall mesh are relative tints (the part's Color is the building's wall colour)
PAINT_TINT = {"KW1": (1.0, 0.93, 0.8), "KW4": (0.95, 0.99, 1.0), "KW6": (1.0, 1.0, 1.0), "KWB": (0.85, 0.92, 1.0)}

# (2026-11-16, owner rule "no flickering / overlapping parts") layers in front of a wall, in metres: grime 0.02, paint
# patches 0.04, soft stains 0.06, dark streaks 0.08 (0.06 studs or more apart); kit.py's own small offsets that flicker
# (awning ribs 0.012, louvres 0.005 in front of the shutter, AC grille 0.002, sign stripes 0.005, shutter ribs 0.01) are
# overridden below
K.OFF_GRIME, K.OFF_STAIN, K.OFF_STREAK = 0.02, 0.08, 0.10
OFF_PAINT = 0.04


def awning(x0, x1, z, y, depth, kind):
    if kind is None:
        return
    drop = depth * 0.5
    K.face(kind, [(x0, y, z), (x1, y, z), (x1, y - depth, z - drop), (x0, y - depth, z - drop)], (0, -0.3, 1))
    if kind in ("KAR", "KAW"):
        K.front_quad(kind, x0, x1, z - drop - 0.22, z - drop, y - depth)
    else:
        for k in range(int((x1 - x0) / 0.35)):
            xx = x0 + 0.17 + k * 0.35
            K.face("KST", [(xx, y - 0.02, z + 0.03), (xx + 0.06, y - 0.02, z + 0.03),
                           (xx + 0.06, y - depth, z - drop + 0.03), (xx, y - depth, z - drop + 0.03)], (0, -0.3, 1))


def sign(x, z, w, h, y, ground=None, stripe=None):
    ground = ground or K.R.choice(["KSW", "KSW", "KSW", "KS2"])
    K.box(ground, x, y - 0.14, z, w, 0.12, h, faces=("-y", "+x", "-x", "top", "bottom"))
    stripe = stripe if stripe is not None else (K.R.choice(["KS1", "KS1", "KS3", "KS4"]) if K.R.random() < 0.6 else None)
    if stripe:
        hb = h * K.R.uniform(0.18, 0.3)
        if K.R.random() < 0.5:
            K.front_quad(stripe, x, x + w, z, z + hb, y - 0.165)
        else:
            K.front_quad(stripe, x, x + w * K.R.uniform(0.2, 0.3), z, z + h, y - 0.165)


def ac_unit(x, z, y, drip_len=None):
    K.box("KAC", x, y - 0.35, z, 0.8, 0.3, 0.55, faces=("-y", "+x", "-x", "top", "bottom"))
    K.front_quad("KGR", x + 0.42, x + 0.74, z + 0.1, z + 0.42, y - 0.37)
    for bx in (x + 0.1, x + 0.62):
        K.box("KGR", bx, y - 0.38, z - 0.04, 0.05, 0.38, 0.04, faces=("-y", "top", "bottom"))
    K.drip(x + 0.3, z, y, drip_len if drip_len is not None else K.R.uniform(0.8, 2.0))


def louvres(x0, x1, z0, z1, y, step=0.09):
    zz = z0 + step * 0.6
    while zz < z1 - 0.03:
        K.front_quad("KST", x0, x1, zz, zz + 0.025, y)
        zz += step


def shutters(x, z, w, h, y, colour, state):
    if state == "closed":
        K.front_quad(colour, x, x + w, z, z + h, y + 0.12)
        louvres(x + 0.05, x + w / 2 - 0.04, z + 0.08, z + h - 0.08, y + 0.09)
        louvres(x + w / 2 + 0.04, x + w - 0.05, z + 0.08, z + h - 0.08, y + 0.09)
        K.front_quad("KST", x + w / 2 - 0.02, x + w / 2 + 0.02, z, z + h, y + 0.07)
        return
    for s_, side in ((-1, x), (1, x + w)):
        if state == "flat":
            a, b = (side, y - 0.13), (side + s_ * w / 2, y - 0.13)
        else:
            ang = K.R.uniform(0.15, 0.5)
            a, b = (side, y), (side - s_ * math.cos(ang) * w / 2, y - math.sin(ang) * w / 2)
        q = [(a[0], a[1], z), (b[0], b[1], z), (b[0], b[1], z + h), (a[0], a[1], z + h)]
        K.face(colour, q, (0, -1, 0))
        K.face(colour, q, (0, 1, 0))
        if state == "flat":
            zz = z + 0.1
            while zz < z + h - 0.08:
                lo, hi = min(a[0], b[0]) + 0.04, max(a[0], b[0]) - 0.04
                K.front_quad("KST", lo, hi, zz, zz + 0.025, min(a[1], b[1]) - 0.03)
                zz += 0.12


_shop_bay = K.shop_bay


def shop_bay(x, w, h, y, wall, holes, state=None, spill=0.4):
    state = state or K.R.choices(["open", "shutter", "glass"], [0.4, 0.4, 0.2])[0]
    if state == "shutter":
        K.opening(holes, x, 0.0, w, h, y, wall, depth=0.25, glass="KRS", lit=False)
        zz = 0.15
        while zz < h - 0.1:
            K.front_quad("KST", x, x + w, zz, zz + 0.03, y + 0.21)
            zz += 0.16
        return state
    if state == "glass":
        K.opening(holes, x, 0.0, w, h, y, wall, depth=0.3, glass="KGL", lit=False)
        K.front_quad("KFR", x + w / 2 - 0.04, x + w / 2 + 0.04, 0.0, h, y + 0.27)
        K.front_quad("KFR", x, x + w / 2 - 0.04, 2.2, 2.28, y + 0.27)
        K.front_quad("KFR", x + w / 2 + 0.04, x + w, 2.2, 2.28, y + 0.27)
        return state
    return _shop_bay(x, w, h, y, wall, holes, state=state, spill=spill)


def drainpipe(x, z0, z1, y):
    K.bar("KPP", (x, y - 0.45, z0), (x, y - 0.45, z1), 0.05)
    K.bar("KPP", (x, y - 0.45, z1), (x, y + 0.02, z1 + 0.25), 0.05)


def band(grp, W, z, h, d):
    """a horizontal band on the wall (floor line, ledge, plinth, string course): d out of the wall, h tall at the
    wall, its top sloping 0.03 m down to the front and its bottom 0.03 m up (a drip): where two walls meet at a corner
    the two bands cross along a crease instead of lying in one plane (no flicker); no end faces (bands of panels along
    one wall run on)"""
    s_ = min(0.03, h * 0.3)
    K.face(grp, [(0.0, -d, z + s_), (W, -d, z + s_), (W, -d, z + h - s_), (0.0, -d, z + h - s_)], (0, -1, 0))
    K.face(grp, [(0.0, -d, z + h - s_), (W, -d, z + h - s_), (W, 0.0, z + h), (0.0, 0.0, z + h)], (0, -0.3, 1))
    K.face(grp, [(0.0, 0.0, z), (W, 0.0, z), (W, -d, z + s_), (0.0, -d, z + s_)], (0, -0.3, -1))


def goods(x0, x1, y, depth=0.8):
    x = x0
    while x < x1 - 0.4:
        w = K.R.uniform(0.4, 0.8)
        kind = K.R.random()
        if kind < 0.4:
            K.box("KWD", x, y - depth, 0.15, w, K.R.uniform(0.4, depth), K.R.uniform(0.3, 0.6))
        elif kind < 0.7:
            K.box(K.R.choice(["PRC", "PRC", "PRA", "PRF"]), x, y - depth * 0.7, 0.15, w, 0.5, K.R.uniform(0.3, 0.5))
        else:
            K.box("KCG", x, y - 0.5, 0.15, w, 0.4, 1.4, faces=("-y", "+x", "-x", "top"))
            for k in range(3):
                K.front_quad(K.R.choice(["PRA", "PRB", "PRE", "PRF", "KL4"]), x + 0.05, x + w - 0.05, 0.35 + k * 0.42,
                             0.65 + k * 0.42, y - 0.53)
        x += w + K.R.uniform(0.05, 0.3)


K.goods = goods
K.awning, K.sign, K.ac_unit, K.louvres, K.shutters, K.shop_bay, K.drainpipe = awning, sign, ac_unit, louvres, shutters, shop_bay, drainpipe

# lighter windows and cages than kit.py's (a district has tens of thousands of them): grille bars every 0.2 m,
# cage bars every 0.2 m


def window(x, z, w, h, y, holes, wall, grille=True, awning_kind=None):
    K.opening(holes, x, z, w, h, y, wall)
    K.front_quad("KFR", x + w / 2 - 0.03, x + w / 2 + 0.03, z, z + h, y + K.REVEAL - 0.03)
    K.box("KW0", x - 0.05, y - 0.06, z - 0.08, w + 0.1, 0.12, 0.08, faces=("-y", "top"))
    if grille:
        n = max(2, int(w / 0.25))
        for k in range(1, n):
            K.front_quad("KGR", x + w * k / n - 0.015, x + w * k / n + 0.015, z, z + h, y + 0.02)
        K.front_quad("KGR", x, x + w, z + h * 0.5 - 0.015, z + h * 0.5 + 0.015, y + 0.02)
    if awning_kind:
        K.awning(x - 0.15, x + w + 0.15, z + h + 0.45, y, 0.8, awning_kind)


def cage(x, z, y, w, h, depth, colour):
    K.box("KCO", x, y - depth, z, w, depth, 0.12, faces=("-y", "+x", "-x", "top", "bottom"))
    K.box("KCO", x, y - depth, z + h - 0.1, w, depth, 0.08, faces=("-y", "+x", "-x", "top", "bottom"))
    yf = y - depth - 0.03
    n = max(3, int(w / 0.2))
    for k in range(n + 1):
        xx = x + w * k / n
        K.front_quad(colour, xx - 0.015, xx + 0.015, z + 0.12, z + h - 0.1, yf)
    for zz in (z + 0.12 + (h - 0.22) * t for t in (0.0, 0.33, 0.66, 1.0)):
        K.front_quad(colour, x, x + w, zz - 0.02, zz + 0.02, yf)
        for sx, nrm in ((x - 0.02, -1), (x + w + 0.02, 1)):
            K.face(colour, [(sx, y - depth, zz - 0.02), (sx, y, zz - 0.02), (sx, y, zz + 0.02), (sx, y - depth, zz + 0.02)],
                   (nrm, 0, 0))


def stains_light(x0, x1, z, y, storey, age, holes):
    """kit.stains with fewer pieces: wide soft stains and one dark streak each."""
    x = x0 + K.R.uniform(0.0, 0.4)
    while x < x1 - 0.2:
        w = K.R.uniform(0.5, 1.6)
        L = min(storey * 1.0, K.R.uniform(0.3, 1.0) * storey * (0.5 + age))
        for (a, b, c, d) in K.rect_minus(x, min(x1, x + w), z - L, z, holes):
            K.front_quad("KSU", a, b, c, d, y - K.OFF_STAIN)
        xs = x + K.R.uniform(0.0, max(0.05, w - 0.1))
        xe = min(x1, xs + K.R.uniform(0.04, 0.12))
        if xe - xs > 0.02:
            for (a, b, c, d) in K.rect_minus(xs, xe, z - L * 1.2, z, holes):
                K.front_quad("KST", a, b, c, d, y - K.OFF_STREAK)
        x += w + K.R.uniform(0.2, 1.2)


def parapet(W, H, par, wall):
    if par <= 0:
        return
    band("KWG", W, H, 0.12, 0.1)
    K.front_quad(wall, 0.0, W, H + 0.12, H + par, 0.0)
    K.face(wall, [(0.0, 0.0, H + par), (W, 0.0, H + par), (W, 0.18, H + par - 0.04), (0.0, 0.18, H + par - 0.04)], (0, 0.2, 1))
    K.face(wall, [(0.0, 0.18, H), (W, 0.18, H), (W, 0.18, H + par - 0.04), (0.0, 0.18, H + par - 0.04)], (0, 1, 0))
    for (a, b, c, d) in K.rect_minus(0.0, W, H + 0.12, H + par, []):
        K.front_quad(K.grime_group(0.6), a, b, c, d, -K.OFF_GRIME)


def height(arch, floors):
    a = ARCH[arch]
    return a["gf"] + a.get("fh", FH) * max(0, floors - 1)


def fh(arch):
    """an archetype's upper floor height (m)"""
    return ARCH.get(arch, {}).get("fh", FH)


# ------------------------------------------------------------------------------------------ panel builders (metres)
def p_walkup(W, bays, floors, role, shop, age, civic=False):
    A = ARCH["civic" if civic else "walkup"]
    BAY, GF = W / bays, A["gf"]
    H = height("civic" if civic else "walkup", floors)
    holes = []
    wall = "KWX"
    front = role == "front"
    for k in range(bays):
        x = k * BAY
        if shop and front:
            K.shop_bay(x + 0.35, BAY - 0.7, 2.9, 0.0, wall, holes)
            K.awning(x + 0.15, x + BAY - 0.15, K.R.uniform(2.95, 3.3), 0.0, K.R.uniform(0.8, 1.6), K.wpick(K.AWNINGS))
            if K.R.random() < 0.7:
                sw = K.R.uniform(1.6, BAY - 0.3)
                K.sign(x + (BAY - sw) / 2, 3.05, sw, K.R.uniform(0.5, 0.6), 0.0)
        elif civic and front and k == bays // 2:
            K.opening(holes, x + BAY / 2 - 0.9, 0.0, 1.8, 2.4, 0.0, wall, glass="KSI", lit=False)
        else:
            window(x + BAY / 2 - 0.8, 0.95, 1.6, 1.4, 0.0, holes, wall, grille=True)
    for f in range(1, floors):
        z = GF + FH * (f - 1)
        band("KWG", W, z - 0.12, 0.12, 0.15)
        for k in range(bays):
            x = k * BAY
            r = K.R.random()
            if front and not civic and r < 0.35:
                depth = K.R.uniform(0.6, 0.9)
                window(x + BAY / 2 - 0.8, z + 0.9, 1.6, 1.3, 0.0, holes, wall, grille=False)
                cage(x + 0.15, z, 0.0, BAY - 0.3, FH - 0.2, depth, K.wpick(K.CAGES))
                K.laundry(x + 0.3, x + BAY - 0.3, z + 2.1, -depth + 0.3)
                if K.R.random() < 0.15:
                    K.face("KNT", [(x + 0.15, -depth - 0.08, z + 0.15), (x + BAY - 0.15, -depth - 0.08, z + 0.15),
                                   (x + BAY - 0.15, -depth - 0.08, z + FH - 0.2), (x + 0.15, -depth - 0.08, z + FH - 0.2)], (0, -1, 0))
                if K.R.random() < 0.6:
                    K.awning(x + 0.05, x + BAY - 0.05, z + FH - 0.05, 0.0, depth + 0.45, "KAW")
            elif front and not civic and r < 0.55:
                window(x + BAY / 2 - 0.8, z + 0.2, 1.6, 2.1, 0.0, holes, wall, grille=True)
                K.box("KCO", x + 0.1, -1.1, z, BAY - 0.2, 1.1, 0.15)
                K.box("KWX", x + 0.1, -1.1, z + 0.15, BAY - 0.2, 0.1, 0.9, faces=("-y", "+y", "+x", "-x", "top"))
                K.laundry(x + 0.3, x + BAY - 0.3, z + 2.0, -0.8, -1.1, z + 1.05)
                if K.R.random() < 0.6:
                    K.awning(x + 0.05, x + BAY - 0.05, z + FH - 0.1, 0.0, 1.4, "KAW")
            else:
                blue = (not civic) and K.R.random() < (0.55 if front else 0.25)
                window(x + BAY / 2 - 0.75, z + 0.9, 1.5, 1.35 if not civic else 1.6, 0.0, holes, wall, grille=True,
                       awning_kind="KAW" if blue else None)
            paint = K.R.choice(["KW1", "KW4", "KW6"]) if (front and not civic and K.R.random() < 0.2) else None
            if paint:
                for (a, b, c, d) in K.rect_minus(x + 0.05, x + BAY - 0.05, z + 0.05, z + FH - 0.2, holes):
                    K.front_quad(paint, a, b, c, d, -OFF_PAINT)
    K.facade(wall, 0.0, W, 0.0, H, 0.0, holes)
    for f in range(1, floors, 2 if front else 3):
        stains_light(0.0, W, GF + FH * (f - 1) - 0.12, 0.0, FH * 0.8, age, holes)
    stains_light(0.0, W, H, 0.0, FH, age, holes)
    K.grime(0.0, W, H - FH if floors > 1 else 0.0, H, 0.0, age, holes)
    parapet(W, H, ARCH["walkup"]["par"], wall)
    return H


def p_township(W, bays, floors, role, shop, age):
    BAY, GF = W / bays, ARCH["township"]["gf"]
    H = height("township", floors)
    holes, wall = [], "KWX"
    front = role == "front"
    for k in range(bays):
        x = k * BAY
        if front and shop:
            st = K.shop_bay(x + 0.35, BAY - 0.7, 2.9, 0.0, wall, holes, state=K.R.choice(["open", "open", "shutter"]), spill=0.5)
            fh = K.R.uniform(0.8, 1.15)
            K.sign(x + 0.03, 3.05, BAY - 0.06, fh, -0.1, ground=K.R.choice(["KSW", "KS2"]), stripe=K.R.choice(["KS1", "KS3", "KS4"]))
            if K.R.random() < 0.6:
                K.sign(x + 0.02, 0.5, 0.3, 2.0, -0.02, ground=K.R.choice(["KSW", "KS2", "KS1"]), stripe=None)
            K.awning(x, x + BAY, 2.95, -0.1, K.R.uniform(1.0, 1.8), K.wpick({"KAW": 0.4, "KAR": 0.3, None: 0.3}))
        else:
            window(x + BAY / 2 - 0.8, 0.95, 1.6, 1.4, 0.0, holes, wall, grille=True)
        for f in range(1, floors):
            z = GF + FH * (f - 1)
            ww = min(1.6, (BAY - 1.4) / 2)
            for wx in (x + 0.5, x + BAY - 0.5 - ww):
                window(wx, z + 0.9, ww, 1.3, 0.0, holes, wall, grille=True,
                       awning_kind="KAW" if (front and K.R.random() < 0.35) else None)
            if front and f == 1 and K.R.random() < 0.5:
                K.face(K.R.choice(["KSV", "KS2", "KS1"]), [(x + 0.3, -0.06, z + 0.1), (x + BAY - 0.3, -0.06, z + 0.1),
                                                           (x + BAY - 0.3, -0.06, z + 0.75), (x + 0.3, -0.06, z + 0.75)], (0, -1, 0))
    for f in range(1, floors):
        band("KW0", W, GF + FH * (f - 1) - 0.1, 0.1, 0.12)
    K.facade(wall, 0.0, W, 0.0, H, 0.0, holes)
    for f in range(1, floors):
        stains_light(0.0, W, GF + FH * (f - 1) - 0.1, 0.0, FH * 0.8, age, holes)
    K.grime(0.0, W, H - FH, H, 0.0, age, holes)
    parapet(W, H, ARCH["township"]["par"], wall)
    return H


def p_house(W, bays, floors, role, age, villa=False):
    arch = "villa" if villa else "house"
    BAY, GF = W / bays, ARCH[arch]["gf"]
    H = height(arch, floors)
    holes, wall = [], "KWX"
    front = role == "front"
    base = 0.6 if villa else 0.35
    band("KWG", W, 0.0, base, 0.12)  # the raised plinth
    shut = K.wpick(K.SHUTTERS)
    for f in range(floors):
        z = (base if f == 0 else GF + FH * (f - 1))
        for k in range(bays):
            x = k * BAY
            if f == 0 and front and k == bays // 2:
                K.opening(holes, x + BAY / 2 - 0.55, z, 1.1, 2.2, 0.0, wall, glass="KSH4", lit=False)  # the door
                continue
            ww, wh = (1.3, 1.6) if villa else (1.2, 1.4)
            window(x + BAY / 2 - ww / 2, z + 0.85, ww, wh, 0.0, holes, wall, grille=(f == 0 or not villa))
            if villa and K.R.random() < 0.5:
                K.shutters(x + BAY / 2 - ww / 2, z + 0.85, ww, wh, 0.0, shut, K.R.choice(["flat", "flat", "closed"]))
        if f > 0:
            band("KW0", W, z - 0.15, 0.15, 0.15)
    K.facade(wall, 0.0, W, 0.0, H, 0.0, holes)
    stains_light(0.0, W, H, 0.0, min(FH, H), age, holes)
    K.grime(0.0, W, max(0.6, H - FH), H, 0.0, age, holes, z_base=0.0)
    return H


def p_condo(W, bays, floors, role, age, stripe=False):
    BAY, PF = W / bays, ARCH["condo"]["gf"]
    H = height("condo", floors)
    holes, wall = [], "KWX"
    front = role == "front"
    # podium (2 floors): shopfront glass on the front, plain windows elsewhere
    if front:
        K.front_quad("KGL", 0.4, W - 0.4, 0.3, 3.6, -0.05)
        for k in range(bays + 1):
            K.front_quad("KFR", 0.4 + k * (W - 0.8) / bays - 0.05, 0.4 + k * (W - 0.8) / bays + 0.05, 0.3, 3.6, -0.07)
        K.sign(0.8, 3.75, min(4.0, W - 1.6), 0.6, -0.02, ground="KSW", stripe="KS3")
    for k in range(bays):
        window(k * BAY + BAY / 2 - 1.0, PF + 0.9, 2.0, 1.8, 0.0, holes, wall, grille=False)
    for f in range(2, floors):
        z = PF + FH * (f - 1)
        for k in range(bays):
            x = k * BAY
            if stripe:
                K.front_quad("KBC", x, x + BAY, z - 0.1, z + FH - 0.1, -0.2)
                K.front_quad("KGL", x + 0.3, x + BAY - 0.3, z + 0.5, z + 2.7, -0.25)
                continue
            r = K.R.random()
            if front and r < 0.3:
                K.opening(holes, x + 0.3, z + 0.15, BAY - 0.6, 2.6, 0.0, wall, depth=1.2, glass="KGL")
                K.front_quad("KRL", x + 0.3, x + BAY - 0.3, z + 0.15, z + 1.15, 0.05)
            elif r < 0.45:
                K.opening(holes, x + 0.5, z + 0.3, BAY - 1.0, 1.8, 0.0, wall, depth=0.6, glass="KSI", lit=False)
                for k2 in range(5):
                    K.front_quad("KW0", x + 0.5, x + BAY - 0.5, z + 0.4 + k2 * 0.32, z + 0.5 + k2 * 0.32, 0.02)
            else:
                window(x + BAY / 2 - 0.85, z + 0.75, 1.7, 1.8, 0.0, holes, wall, grille=False)
        band("KW0", W, z - 0.15, 0.15, 0.12)
    if not stripe:
        K.facade(wall, 0.0, W, 0.0, H, 0.0, holes)
    else:
        K.facade(wall, 0.0, W, 0.0, PF + FH, 0.0, holes)
        K.box("KBC", 0.0, -0.2, PF + FH, W, 0.2, H - PF - FH + 1.0, faces=("+x", "-x", "top"))
    for f in range(2, floors, 2):
        stains_light(0.0, W, PF + FH * (f - 1) - 0.15, 0.0, FH * 0.6, age, holes)
    K.grime(0.0, W, H - FH, H, 0.0, age, holes, z_base=0.0)
    return H


def p_condo_band(W, bays, nf, role, age, stripe=False):
    """nf typical tower floors (FH each) starting at 0, no podium, no parapet"""
    BAY = W / bays
    H = nf * FH
    holes, wall = [], "KWX"
    front = role == "front"
    for f in range(nf):
        z = FH * f
        for k in range(bays):
            x = k * BAY
            if stripe:
                K.front_quad("KBC", x, x + BAY, z, z + FH, -0.2)
                K.front_quad("KGL", x + 0.3, x + BAY - 0.3, z + 0.5, z + 2.7, -0.25)
                continue
            r = K.R.random()
            if front and r < 0.3:
                K.opening(holes, x + 0.3, z + 0.15, BAY - 0.6, 2.6, 0.0, wall, depth=1.2, glass="KGL")
                K.front_quad("KRL", x + 0.3, x + BAY - 0.3, z + 0.15, z + 1.15, 0.05)
            elif r < 0.45:
                K.opening(holes, x + 0.5, z + 0.3, BAY - 1.0, 1.8, 0.0, wall, depth=0.6, glass="KSI", lit=False)
                for k2 in range(5):
                    K.front_quad("KW0", x + 0.5, x + BAY - 0.5, z + 0.4 + k2 * 0.32, z + 0.5 + k2 * 0.32, 0.02)
            else:
                window(x + BAY / 2 - 0.85, z + 0.75, 1.7, 1.8, 0.0, holes, wall, grille=False)
        band("KW0", W, z - 0.15 if f else 0.0, 0.15, 0.12)
    if stripe:
        K.box("KBC", 0.0, -0.2, 0.0, W, 0.2, H, faces=("+x", "-x"))
    else:
        K.facade(wall, 0.0, W, 0.0, H, 0.0, holes)
        stains_light(0.0, W, H - 0.15, 0.0, FH * 0.6, age, holes)
    return H


def p_condo_top(W, bays, role, age, stripe=False):
    """the parapet / crown strip on top of a tower face (height 0 at the roof line)"""
    if stripe:
        K.box("KBC", 0.0, -0.2, 0.0, W, 0.2, 1.5, faces=("-y", "+x", "-x", "top"))
    parapet(W, 0.0, ARCH["condo"]["par"], "KWX")
    return 0.0


def p_shed(W, bays, floors, role, age, market=False):
    BAY, E = W / bays, ARCH["shed"]["gf"]
    H = E + FH * max(0, floors - 1)
    holes, wall = [], "KWX"
    front = role == "front"
    for k in range(bays):
        x = k * BAY
        if front and (market or k == bays // 2):
            if market:
                K.opening(holes, x + 0.3, 0.0, BAY - 0.6, 3.2, 0.0, wall, depth=3.0, glass="KSI", lit=False)
                K.awning(x, x + BAY, 3.3, 0.0, K.R.uniform(1.5, 2.5), K.R.choice(["KTP", "KAW", "KRF"]))
            else:
                K.opening(holes, x + BAY / 2 - 1.6, 0.0, 3.2, 3.2, 0.0, wall, depth=0.25, glass="KRS", lit=False)
                zz = 0.15
                while zz < 3.1:
                    K.front_quad("KST", x + BAY / 2 - 1.6, x + BAY / 2 + 1.6, zz, zz + 0.03, 0.21)
                    zz += 0.2
        # the row of small vents high in the wall
        for vx in (x + BAY * 0.3, x + BAY * 0.7):
            K.opening(holes, vx - 0.3, 3.4, 0.6, 0.95, 0.0, wall, depth=0.2, glass="KSI", lit=False)
        for f in range(1, floors):
            window(x + BAY / 2 - 0.8, E + FH * (f - 1) + 0.9, 1.6, 1.3, 0.0, holes, wall, grille=True)
    K.facade(wall, 0.0, W, 0.0, H, 0.0, holes)
    stains_light(0.0, W, H, 0.0, FH, age, holes)
    K.grime(0.0, W, 0.6, H, 0.0, age, holes, z_base=0.0)
    return H


def p_colonial(W, bays, floors, role, shop, age):
    """(2026-11-16, P3 downtown) a colonial shophouse front in kit panels (kit.colonial_row's details, per bay): shops
    under a ground-floor cornice, arched windows / French doors 0.35 m deep with teak shutters, a bracketed balcony on
    some bays (iron or concrete balustrade), pilasters between the bays and at the panel ends, a cornice at every floor
    line and a heavy one under the parapet. The pilaster faces at the panel ends that lie on the joint are left out
    (the next panel's pilaster butts on)."""
    A = ARCH["colonial"]
    BAY, GF, FC = W / bays, A["gf"], A["fh"]
    H = height("colonial", floors)
    holes, wall, trim = [], "KWX", "KW0"
    front = role == "front"
    shut = K.wpick(K.SHUTTERS)
    iron = K.R.random() < 0.5
    # ground floor
    for k in range(bays):
        x = k * BAY
        if front and shop:
            shop_bay(x + 0.3, BAY - 0.6, 3.3, 0.0, wall, holes, state=K.R.choice(["open", "open", "shutter", "glass"]), spill=0.4)
            if K.R.random() < 0.55:
                K.awning(x + 0.2, x + BAY - 0.2, 3.5, 0.0, K.R.uniform(0.8, 1.6), K.wpick({"KAW": 0.35, "KAR": 0.4, "KRF": 0.25}))
            if K.R.random() < 0.6:
                sw = K.R.uniform(1.2, BAY - 0.5)
                K.sign(x + (BAY - sw) / 2, 3.62, sw, K.R.uniform(0.45, 0.6), 0.0)
        elif front:
            K.arch_window(x + BAY / 2 - 0.6, 0.15, 1.2, 2.6, 0.0, holes, wall, shut, "closed")
        else:
            window(x + BAY / 2 - 0.7, 1.0, 1.4, 1.5, 0.0, holes, wall, grille=True)
    band(trim, W, GF - 0.3, 0.3, 0.28)
    # upper floors
    levels = [(0.0, GF - 0.3)]
    for f in range(1, floors):
        z = GF + FC * (f - 1)
        top_z = (H - 0.35) if f == floors - 1 else (z + FC - 0.22)
        levels.append((z, top_z))
        if f > 1:
            band(trim, W, z - 0.22, 0.22, 0.2)
        pb = (0.5 if f == 1 else 0.3) if front else 0.0
        for k in range(bays):
            x = k * BAY
            balc = K.R.random() < pb
            zz, hh = (z + 0.12, 2.4) if balc else (z + 0.6, 1.9)
            state = K.R.choices(["closed", "flat", "ajar"], [0.5, 0.3, 0.2])[0]
            K.arch_window(x + BAY / 2 - 0.575, zz, 1.15, hh, 0.0, holes, wall, shut, state)
            if not balc:
                continue
            bd, x0, x1 = 1.1, x + 0.17, x + BAY - 0.17
            K.box(wall, x0, -bd, z, x1 - x0, bd, 0.18, faces=("-y", "+x", "-x", "top", "bottom"))
            for bx in (x0 + 0.15, x1 - 0.27):   # brackets
                for sx, nrm in ((bx, -1), (bx + 0.12, 1)):
                    K.face(trim, [(sx, 0.0, z), (sx, -0.6, z), (sx, 0.0, z - 0.6)], (nrm, 0, 0))
                K.face(trim, [(bx, -0.6, z), (bx + 0.12, -0.6, z), (bx + 0.12, 0.0, z - 0.6), (bx, 0.0, z - 0.6)], (0, -1, -0.6))
            yr = -bd + 0.06
            if iron:
                n = max(4, int((x1 - x0 - 0.1) / 0.14))
                for j in range(n + 1):
                    xx = x0 + 0.05 + (x1 - x0 - 0.1) * j / n
                    K.front_quad("KGR", xx - 0.015, xx + 0.015, z + 0.18, z + 1.0, yr)
                K.box("KGR", x0 + 0.02, yr - 0.03, z + 1.0, x1 - x0 - 0.04, 0.08, 0.06)
            else:
                n = max(3, int((x1 - x0 - 0.1) / 0.3))
                for j in range(n + 1):
                    xx = x0 + 0.05 + (x1 - x0 - 0.1) * j / n
                    K.box(trim, xx - 0.05, yr - 0.05, z + 0.18, 0.1, 0.1, 0.82, faces=("-y", "+x", "-x"))
                K.box(trim, x0 + 0.02, yr - 0.08, z + 1.0, x1 - x0 - 0.04, 0.16, 0.08)
            K.laundry(x0 + 0.1, x1 - 0.1, z + 1.9, yr + 0.1)
    # pilasters: between the bays and at both panel ends (no face on the joint plane)
    for (z0, z1) in levels:
        if z1 - z0 < 0.3:
            continue
        for k in range(1, bays):
            K.box(trim, k * BAY - 0.15, -0.15, z0, 0.3, 0.15, z1 - z0, faces=("-y", "+x", "-x"))
        K.box(trim, 0.0, -0.15, z0, 0.15, 0.15, z1 - z0, faces=("-y", "+x"))
        K.box(trim, W - 0.15, -0.15, z0, 0.15, 0.15, z1 - z0, faces=("-y", "-x"))
    band(trim, W, H - 0.35, 0.35, 0.4)   # the heavy cornice
    K.facade(wall, 0.0, W, 0.0, H, 0.0, holes)
    for f in range(1, floors):
        stains_light(0.0, W, GF + FC * (f - 1) - 0.22, 0.0, FC * 0.8, age, holes)
    stains_light(0.0, W, H - 0.35, 0.0, FC, age, holes)
    K.grime(0.0, W, H - FC if floors > 1 else 0.0, H, 0.0, age, holes)
    parapet(W, H, A["par"], wall)
    return H


def p_pier(arch, W, floors, role, age):
    """(2026-11-16, light pass) a half-bay pier: the archetype's wall, bands, plinth and parapet at the same heights as
    its full panels, no openings. It closes a wall whose length does not fit whole bays (no plain end strips)."""
    holes, wall = [], "KWX"
    if arch in ("walkup", "civic"):
        A = ARCH["civic" if arch == "civic" else "walkup"]
        GF = A["gf"]
        H = height("civic" if arch == "civic" else "walkup", floors)
        for f in range(1, floors):
            band("KWG", W, GF + FH * (f - 1) - 0.12, 0.12, 0.15)
        K.facade(wall, 0.0, W, 0.0, H, 0.0, holes)
        stains_light(0.0, W, H, 0.0, FH, age, holes)
        K.grime(0.0, W, H - FH if floors > 1 else 0.0, H, 0.0, age, holes)
        parapet(W, H, ARCH["walkup"]["par"], wall)
        return H
    if arch == "colonial":
        A = ARCH["colonial"]
        GF, FC = A["gf"], A["fh"]
        H = height("colonial", floors)
        band("KW0", W, GF - 0.3, 0.3, 0.28)
        for f in range(2, floors):
            band("KW0", W, GF + FC * (f - 1) - 0.22, 0.22, 0.2)
        band("KW0", W, H - 0.35, 0.35, 0.4)
        K.facade(wall, 0.0, W, 0.0, H, 0.0, holes)
        stains_light(0.0, W, H - 0.35, 0.0, FC, age, holes)
        K.grime(0.0, W, H - FC, H, 0.0, age, holes)
        parapet(W, H, A["par"], wall)
        return H
    if arch == "township":
        GF = ARCH["township"]["gf"]
        H = height("township", floors)
        for f in range(1, floors):
            band("KW0", W, GF + FH * (f - 1) - 0.1, 0.1, 0.12)
        K.facade(wall, 0.0, W, 0.0, H, 0.0, holes)
        K.grime(0.0, W, H - FH, H, 0.0, age, holes)
        parapet(W, H, ARCH["township"]["par"], wall)
        return H
    if arch in ("house", "villa"):
        GF = ARCH[arch]["gf"]
        H = height(arch, floors)
        band("KWG", W, 0.0, 0.6 if arch == "villa" else 0.35, 0.12)
        for f in range(1, floors):
            band("KW0", W, GF + FH * (f - 1) - 0.15, 0.15, 0.15)
        K.facade(wall, 0.0, W, 0.0, H, 0.0, holes)
        stains_light(0.0, W, H, 0.0, min(FH, H), age, holes)
        K.grime(0.0, W, max(0.6, H - FH), H, 0.0, age, holes, z_base=0.0)
        return H
    if arch == "condo":       # the 2-floor podium
        H = height("condo", 2)
        K.facade(wall, 0.0, W, 0.0, H, 0.0, holes)
        K.grime(0.0, W, H - FH, H, 0.0, age, holes, z_base=0.0)
        return H
    if arch == "condo_band":
        H = floors * FH
        for f in range(floors):
            band("KW0", W, FH * f - 0.15 if f else 0.0, 0.15, 0.12)
        K.facade(wall, 0.0, W, 0.0, H, 0.0, holes)
        return H
    if arch == "condo_top":
        parapet(W, 0.0, ARCH["condo"]["par"], "KWX")
        return 0.0
    E = ARCH["shed"]["gf"]   # shed / market
    H = E + FH * max(0, floors - 1)
    K.facade(wall, 0.0, W, 0.0, H, 0.0, holes)
    K.grime(0.0, W, 0.6, H, 0.0, age, holes, z_base=0.0)
    return H


# ------------------------------------------------------------------------------------------ the kit
def stable_id(prefix, key):
    """(2026-11-16, light pass) a piece's id from its key, the same in every district run (the kit is shared by the
    whole city: templates are named KIND_<id>)"""
    return prefix + format(zlib.crc32(repr(key).encode()) & 0xffffffff, "08x")


class Kit:
    def __init__(self):
        self.p = {}      # key -> pid
        self.data = {}   # pid -> dict(W, M, C, panes, w, h, key)

    @staticmethod
    def bay(arch):
        return ARCH[arch]["bay"] * S

    def panel(self, arch, role, floors, k, var, shop=False, stripe=False):
        """the panel's id (made on first use) for an archetype ('walkup', 'township', 'house', 'villa', 'condo',
        'civic', 'shed', 'market'), a role ('front' | 'side'), the floor count, k bays, a variant"""
        key = (arch, role, floors, k, var, bool(shop), bool(stripe))
        if key in self.p:
            return self.p[key]
        pid = stable_id("p", key)
        self.p[key] = pid
        seed = hash(key) & 0xffffff
        seed = sum(ord(c) * (i + 7) for i, c in enumerate(repr(key))) * 7919 + var
        K.reset(seed)
        K.LIT = 1.0  # every window gets a pane: the placer picks the lit ones
        age = K.R.uniform(0.35, 0.8)
        base = "shed" if arch == "market" else ("condo" if arch.startswith("condo") else arch)
        W = ARCH[base]["bay"] * k
        if k == 0:   # the half-bay pier
            W = ARCH[base]["bay"] * 0.5
            H = p_pier(arch, W, floors, role, age)
        elif arch in ("walkup", "civic"):
            H = p_walkup(W, k, floors, role, shop, age, civic=arch == "civic")
        elif arch == "township":
            H = p_township(W, k, floors, role, shop, age)
        elif arch == "colonial":
            H = p_colonial(W, k, floors, role, shop, age)
        elif arch in ("house", "villa"):
            H = p_house(W, k, floors, role, age, villa=arch == "villa")
        elif arch == "condo":
            H = p_condo(W, k, 2, role, age, stripe=stripe)
        elif arch == "condo_band":
            W = ARCH["condo"]["bay"] * k
            H = p_condo_band(W, k, floors, role, age, stripe=stripe)
        elif arch == "condo_top":
            W = ARCH["condo"]["bay"] * k
            H = p_condo_top(W, k, role, age, stripe=stripe)
        else:
            H = p_shed(W, k, floors, role, age, market=arch == "market")
        self.data[pid] = self._collect(K.g, W * S, H * S, key)
        return pid

    def _collect(self, g, w, h, key):
        out = dict(W=Mesh(), M=Mesh(), C=Mesh(), R=Mesh(), panes=[], w=w, h=h, key=key)
        for grp, tris in g.g.items():
            if grp in NIGHT:
                for i in range(0, len(tris) - 1, 2):  # front_quad: two triangles a quad
                    a, b, c = tris[i]
                    d = tris[i + 1][2]
                    out["panes"].append([self.tx(p) for p in (a, b, c, d)])
                continue
            if grp in WALL_K or grp in PAINT_TINT:
                cls = "W"
                if grp in PAINT_TINT:
                    rgb = tuple(255 * v for v in PAINT_TINT[grp])
                else:
                    rgb = (255 * WALL_K[grp],) * 3
            elif grp in CLOTH:
                # (cloth went into the metal class: 2 parts a panel, not 3; YgnSteelPainted is neutral like YgnCanvas)
                cls, rgb = "M", tuple(min(255, v * 1.15) for v in GROUPS[grp][1])
            elif grp in ROOF_G:
                cls, rgb = "R", ((150, 150, 150) if grp == "KRS2" else (255, 255, 255))
            else:
                cls = "M"
                rgb = GROUPS[grp][1] if grp in GROUPS else (60, 60, 60)
                rgb = tuple(min(255, v * 1.2) for v in rgb)
            m = out[cls]
            for (a, b, c) in tris:
                P = [self.tx(a), self.tx(b), self.tx(c)]
                m.tri(P[0], P[1], P[2], *box_uv(P), rgb)
        return out

    @staticmethod
    def tx(p):
        """kit (studs, x along, y into the building, z up) -> panel (X along, Y up, Z out of the wall)"""
        return (p[0], p[2], -p[1])

    # roof props (one mesh each, class M): two black tanks on stands, a big dark mesh dish with an aerial
    def prop(self, name):
        key = ("prop", name)
        if key in self.p:
            return self.p[key]
        pid = stable_id("q", key)
        self.p[key] = pid
        K.reset(99 + zlib.crc32(name.encode()) % 100000)
        if name == "tanks":
            for k in range(2):
                cx, cy = 0.8 + k * 1.6, 0.0
                K.bar("KCG", (cx - 0.5, cy, 0), (cx - 0.5, cy, 0.8), 0.06)
                K.bar("KCG", (cx + 0.5, cy, 0), (cx + 0.5, cy, 0.8), 0.06)
                K.cyl("KTK", cx, cy, 0.8, 1.2, 0.6, 8)
        elif name == "dish":
            K.mesh_dish(0.0, 0.0, 0.0, 2.0)
            K.bar("KCG", (1.5, 0.5, 0), (1.5, 0.5, 3.5), 0.04)
            for k in range(4):
                K.bar("KCG", (1.0, 0.5, 2.6 + k * 0.25), (2.0, 0.5, 2.6 + k * 0.25), 0.03)
        elif name == "stair":  # the stair room on a flat roof (wall class)
            K.box("KWX", 0.0, 0.0, 0.0, 3.0, 2.6, 2.6, faces=("+x", "-x", "+y", "-y", "top"))
            K.front_quad("KSI", 1.0, 1.9, 0.0, 2.1, -0.02)
        elif name == "gate_green" or name == "gate_rust":
            col = "KGT" if name == "gate_green" else "KGU"
            K.front_quad(col, 0.0, 4.5, 0.05, 2.3, 0.0)
            for k in range(19):
                xx = 4.5 * k / 18
                K.bar(col, (xx, -0.04, 0.05), (xx, -0.04, 2.4 + 0.12 * math.sin(math.pi * k / 18)), 0.04)
            K.bar(col, (0.0, -0.06, 1.15), (4.5, -0.06, 1.15), 0.06)
            for px in (-0.55, 4.5):  # pillars with lamp caps (wall class)
                K.box("KWX", px, -0.3, 0.0, 0.55, 0.6, 2.8)
                K.box("KW0", px - 0.08, -0.38, 2.8, 0.71, 0.76, 0.2)
                K.cyl("KAC", px + 0.27, 0.0, 3.0, 0.35, 0.16, 6)
        elif name == "pipe":
            # (2026-11-16) one drainpipe a building on a street face: 5 cm square, 1 cm off the wall (the old per-panel
            # pipe stood 0.45 m off), 3 m tall (scaled in Y to the building); no back face (it would lie 1 cm from the
            # wall: flicker), its front 6 cm out (2 cm from the paint 4 cm and stain 8 cm layers)
            K.box("KPP", -0.025, -0.06, 0.0, 0.05, 0.05, 3.0, faces=("-y", "+x", "-x"))
        elif name == "ac":
            # (2026-11-16) an AC unit 0.12 m off the wall on two brackets (clear of sills 0.06 m out), the fan grille
            # 0.02 m in front of the box (no drip streak: every free layer near the wall is taken by the panels' bands)
            K.box("KAC", 0.0, -0.42, 0.0, 0.8, 0.3, 0.55, faces=("-y", "+x", "-x", "top", "bottom"))
            K.front_quad("KGR", 0.42, 0.74, 0.1, 0.42, -0.44)
            for bx in (0.1, 0.62):
                K.box("KGR", bx, -0.45, -0.04, 0.05, 0.44, 0.04, faces=("-y", "+x", "-x", "top", "bottom"))
        elif name in ("cwall1", "cwall2", "cwall4", "cwall8"):
            # a compound wall run: 1 or 4 bays of 3.5 m, 2.1 m tall + 0.3 m into the ground, 0.22 m thick, a pillar at
            # each bay start (0.4 m, 2.4 m), coping, a dark splash band, rain stains under the coping (all wall class)
            nb = int(name[5:])
            W = 3.5 * nb
            K.box("KWX", 0.0, -0.11, -0.3, W, 0.22, 2.4, faces=("-y", "+y"))
            # the coping: a ridge (0.03 m fall to each side), so two runs meeting at a corner cross along a line
            K.box("KW0", 0.0, -0.15, 2.1, W, 0.30, 0.06, faces=("-y", "+y"))
            K.face("KW0", [(0.0, -0.15, 2.16), (W, -0.15, 2.16), (W, 0.0, 2.19), (0.0, 0.0, 2.19)], (0, -0.2, 1))
            K.face("KW0", [(0.0, 0.0, 2.19), (W, 0.0, 2.19), (W, 0.15, 2.16), (0.0, 0.15, 2.16)], (0, 0.2, 1))
            for side, y in ((-1, -0.11), (1, 0.11)):
                q = [(0.0, y + side * 0.03, -0.3), (W, y + side * 0.03, -0.3), (W, y + side * 0.03, 0.45), (0.0, y + side * 0.03, 0.45)]
                K.face("KGB", q, (0, side, 0))
            for b in range(nb):
                x = b * 3.5
                K.box("KWX", x - 0.2, -0.2, -0.3, 0.4, 0.4, 2.7, faces=("-y", "+y", "+x", "-x", "top"))
                for xs in (x + 0.3, x + 1.6, x + 2.6):
                    w = K.R.uniform(0.3, 0.9)
                    L = K.R.uniform(0.4, 1.4)
                    K.front_quad("KSU", xs, xs + w, 2.1 - L, 2.08, -0.15)
        elif name in ("hip", "gable"):
            # a reference roof 10 x 6 m on plan, 3 m rise, eaves included (the placer scales it to the building's
            # rectangle): the sheet (class R) and, for a gable, the two end triangles (wall class)
            a, b, r = 5.0, 3.0, 3.0
            A, Bq, C, D = (-a, -b, 0.0), (a, -b, 0.0), (a, b, 0.0), (-a, b, 0.0)
            if name == "hip":
                R0, R1 = (-(a - b), 0.0, r), (a - b, 0.0, r)
                K.face("KRO", [A, Bq, R1, R0], (0, -1, 1))
                K.face("KRO", [C, D, R0, R1], (0, 1, 1))
                K.face("KRO", [Bq, C, R1], (1, 0, 1))
                K.face("KRO", [D, A, R0], (-1, 0, 1))
            else:
                R0, R1 = (-a, 0.0, r), (a, 0.0, r)
                K.face("KRO", [A, Bq, R1, R0], (0, -1, 1))
                K.face("KRO", [C, D, R0, R1], (0, 1, 1))
                e = 0.6 / 5.0  # the gable wall sits at the wall line, 0.6 m in from the eave
                for sx in (-a + 0.6, a - 0.6):
                    K.face("KWX", [(sx, -b + 0.6, 0.0), (sx, b - 0.6, 0.0), (sx, 0.0, r * (1 - 0.6 / b))], (sx, 0, 0))
            # the soffit: the sheet's underside in the roof class (one part a hip roof; 2026-11-16), darker
            K.face("KRS2", [A, Bq, C, D], (0, 0, -1))
        self.data[pid] = self._collect(K.g, 0, 0, key)
        return pid

