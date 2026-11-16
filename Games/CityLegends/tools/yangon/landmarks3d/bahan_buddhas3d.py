"""Chaukhtatgyi (66 m reclining Buddha hall) and Ngahtatgyi (14 m seated Buddha hall), Bahan, Yangon, at 1:1.

Pure Python (solid3d.py), 2026-11-16. Metres in the model, 3 studs a metre in the .glb (geo.py at YANGON_SCALE=1to1).
    python bahan_buddhas3d.py            -> imports/sync/landmarks/{chaukhtatgyi,ngahtatgyi}.glb
                                            + build/landmarks/<name>/<name>_place.json (pivot, materials, collision)
Sources and sizes: vault note "City Legends/2026-11-16 Chaukhtatgyi and Ngahtatgyi 3D models.md".

Chaukhtatgyi: OSM way/117384553 + Esri z19 (site audit 16 Nov): shed 94 x 46 m, long axis bearing 122.3 deg (NW -> SE),
  centre lon 96.163884 lat 16.811666. Head at the SE end, face to the NE (main door, car park), lying on the right side.
  Local model: x along 122.3 deg, y to its left (NE), z up, origin = shed centre on the ground.
Ngahtatgyi: OSM way/314121257 (72 x 58 m, axis-aligned), checked on Esri z19 (red roofs + a gold five-tier tower on the
  outline; the old landmarks.json point 96.1645, 16.8104 was 299 m off). Local x = east, y = north, origin = bbox centre.
  Buddha under the tower, facing west (down the nave; not confirmed by a source: the tower sits in the east half).
"""
import sys as _sys, os as _os
_sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
import ornament_kit as OK  # noqa: E402  (2026-11-16 carved ornament kit)
import json
import math
import os
import sys

os.environ["YANGON_SCALE"] = "1to1"
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "city"))
import geo  # noqa: E402
from solid3d import Model, export, collide_rows, add, sub, mul, unit, cross  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
SYNC = os.path.join(ROOT, "imports", "sync", "landmarks")
BUILD = os.path.join(ROOT, "build", "landmarks")

# group -> (Material, (r, g, b), MaterialVariant or "", Reflectance)
LOOK = {
    "SKN": ("SmoothPlastic", (255, 255, 250), "", 0.05),   # white skin (Kaba Aye white)
    "GLD": ("Metal", (226, 222, 245), "YgnGoldLeaf", 0),   # gold leaf (Kaba Aye look pass v2)
    "ROB": ("Metal", (226, 222, 245), "YgnGoldLeaf", 0),   # gold robe
    "LIP": ("SmoothPlastic", (186, 44, 52), "", 0.05),
    "BLK": ("SmoothPlastic", (28, 28, 34), "", 0.1),
    "LID": ("SmoothPlastic", (172, 206, 230), "", 0.05),
    "SOL": ("SmoothPlastic", (214, 128, 112), "", 0.03),   # Chaukhtatgyi soles, salmon pink (photo 205,120,110)
    "MOS": ("Foil", (150, 160, 140), "", 0.2),             # glass mosaic (Kaba Aye settled)
    "PLT": ("SmoothPlastic", (196, 196, 190), "", 0.05),
    "FLR": ("SmoothPlastic", (150, 160, 150), "", 0.15),   # green-grey polished floor
    "RFG": ("SmoothPlastic", (72, 104, 76), "", 0),        # green shed roof (satellite 110,140,108; up faces render light)
    "CEL": ("SmoothPlastic", (236, 236, 230), "", 0),      # white ceiling panels
    "WRD": ("Metal", (120, 46, 44), "YgnCorrugatedZinc", 0),  # dark red corrugated walls
    "STM": ("SmoothPlastic", (112, 50, 44), "", 0.05),     # maroon steel
    "SKY": ("SmoothPlastic", (228, 236, 240), "", 0.1),    # window / skylight bands
    "RUG": ("SmoothPlastic", (96, 96, 100), "", 0),        # aisle roof underside
    "NCM": ("SmoothPlastic", (122, 46, 40), "", 0),        # niche wall maroon
    "NMI": ("SmoothPlastic", (164, 206, 184), "", 0),      # niche mint
    "TEA": ("SmoothPlastic", (44, 92, 102), "", 0),        # teal dado
    "LMP": ("Neon", (255, 232, 160), "", 0),               # railing lamps
    "CUS": ("SmoothPlastic", (150, 40, 40), "", 0.05),     # cushion
    # Ngahtatgyi
    "TEK": ("Wood", (96, 52, 40), "", 0),                  # carved teak backdrop
    "TKL": ("Wood", (128, 72, 52), "", 0),                 # carving relief
    "FRD": ("SmoothPlastic", (150, 46, 40), "", 0.2),      # red polished floor
    "MIR": ("Foil", (204, 208, 214), "", 0.3),             # mirror-mosaic columns
    "RBS": ("SmoothPlastic", (176, 32, 32), "", 0.05),     # red column bases
    "STW": ("SmoothPlastic", (226, 229, 232), "", 0.05),   # white steel
    "RUS": ("Metal", (132, 66, 50), "YgnCorrugatedZinc", 0),  # rusty red-brown corrugated roofs
    "WDR": ("SmoothPlastic", (112, 40, 36), "", 0),        # dark red walls
    "UND": ("SmoothPlastic", (74, 54, 48), "", 0),         # roof undersides
    "GBL": ("SmoothPlastic", (204, 218, 212), "", 0.1),    # glass-block band
    "CLT": ("SmoothPlastic", (240, 240, 236), "", 0),      # white cloth
    "PLN": ("SmoothPlastic", (196, 190, 180), "", 0),      # plinth sides
    # the Blender figures (buddha_figures_blender.py): satin gold measured on the lit photo d02 (208, 185, 133), no grain
    "FSK": ("SmoothPlastic", (240, 238, 232), "", 0.15),   # glossy white skin
    "FGO": ("SmoothPlastic", (204, 164, 86), "", 0.12),   # satin gold robe
    "FGB": ("SmoothPlastic", (222, 172, 64), "", 0.18),   # bright gold: crown, bands, flames
    "FMR": ("SmoothPlastic", (112, 30, 38), "", 0.05),     # maroon robe border
    "FBK": ("SmoothPlastic", (22, 22, 26), "", 0.04),       # black: hair, liner, brows, glass eyes, lashes
    "FLD": ("SmoothPlastic", (170, 205, 230), "", 0.05),   # pale blue lids
    "FLP": ("SmoothPlastic", (192, 46, 56), "", 0.1),      # red lips, red jewels
    "FPK": ("SmoothPlastic", (232, 142, 142), "", 0.05),   # pink inner ears, nails
    "FSO": ("SmoothPlastic", (214, 128, 112), "", 0.03),   # salmon soles
    "FEW": ("SmoothPlastic", (250, 250, 250), "", 0.3),    # white glass eyeball / highlight
    "FSH": ("SmoothPlastic", (218, 215, 208), "", 0.1),    # baked soft shading (light)
    "FS2": ("SmoothPlastic", (192, 188, 181), "", 0.08),   # baked soft shading (darker)
}


FIG_DIR = os.path.join(BUILD, "figures")


def add_figure(m, key):
    """Triangles (with smooth normals) of a Buddha figure made by buddha_figures_blender.py, in this model's metres."""
    d = json.load(open(os.path.join(FIG_DIR, key + "_fig.json")))["groups"]
    for g, tris in d.items():
        m._put(g, [(tuple(t[0][0]), tuple(t[0][1]), tuple(t[0][2]), tuple(tuple(n) for n in t[1])) for t in tris])


# ===================================================================== Chaukhtatgyi
def chauk():
    m = Model()
    boxes = []
    L2, W2 = 47.0, 23.0          # half length / width of the shed
    FL = 0.4                     # floor top
    # floor slab
    m.box("FLR", -L2, L2, -W2, W2, 0, FL, skip=("-z", "+z"))
    m.grid_top("FLR", -L2, L2, -W2, W2, FL, 12, 6)
    boxes.append((0, 0, 0, 2 * L2, 2 * W2, FL, 0))

    # ---- columns
    xs = [-44 + 8 * k for k in range(12)]
    for x in xs:
        for s in (-1, 1):
            m.box("STM", x - 0.25, x + 0.25, s * 23 - 0.25, s * 23 + 0.25, FL, 10.15, skip=("-z",))
            m.box("STM", x - 0.3, x + 0.3, s * 15 - 0.3, s * 15 + 0.3, FL, 14.7, skip=("-z",))
            boxes.append((x, s * 23, FL, 0.5, 0.5, 3.6, 0))
            boxes.append((x, s * 15, FL, 0.6, 0.6, 3.6, 0))
    # eave beams along the nave lines
    for s in (-1, 1):
        m.box("STM", -L2, L2, s * 15 - 0.3, s * 15 + 0.3, 14.6, 15.3)

    # ---- walls: aisle outer walls (open band below 4 m), clerestory with window band, gables
    for s in (-1, 1):
        m.box("WRD", -L2 + 0.1, L2 - 0.1, s * 23 - 0.1, s * 23 + 0.1, 4.0, 10.2)
        m.box("WRD", -L2 + 0.1, L2 - 0.1, s * 15 - 0.1, s * 15 + 0.1, 15.0, 18.3, skip=("+z",))
        m.box("SKY", -L2 + 0.1, L2 - 0.1, s * 15 - 0.1, s * 15 + 0.1, 18.3, 19.8, skip=("+z", "-z"))
        m.box("WRD", -L2 + 0.1, L2 - 0.1, s * 15 - 0.1, s * 15 + 0.1, 19.8, 21.05, skip=("-z",))
    gable = [(-23.1, 4.0), (23.1, 4.0), (23.1, 10.1), (15.1, 15.2), (15.1, 20.95), (0, 26.75), (-15.1, 20.95),
             (-15.1, 15.2), (-23.1, 10.1)]
    for x0 in (-L2 - 0.1, L2 - 0.1):
        m.prism("WRD", gable, 0, 0.2, frame=((x0, 0, 0), (0, 1, 0), (0, 0, 1), (1, 0, 0)), top=True, bottom=True)

    # ---- roofs (top green, underside white in the nave / grey in the aisles)
    RX = L2 + 0.8
    for s in (-1, 1):
        # aisle roof: from the eave (y 23.8, z 9.9) up to the clerestory (y 14.95, z 15.5)
        a = [(-RX, s * 23.8, 9.9), (RX, s * 23.8, 9.9), (RX, s * 14.95, 15.5), (-RX, s * 14.95, 15.5)]
        m.slab("RFG", "RUG", "RFG", a, 0.3, edges=(True, True, False, True))
        # nave roof: from y 15.8 z 20.9 to the ridge y 0 z 27.0
        b = [(-RX, s * 15.8, 20.9), (RX, s * 15.8, 20.9), (RX, 0, 27.0), (-RX, 0, 27.0)]
        m.slab("RFG", "CEL", "RFG", b, 0.3, edges=(True, True, False, True))

    # ---- trusses (maroon steel) across the nave and rafters under the aisle roofs
    def ceil_z(y):  # nave underside
        return 20.85 + (15 - abs(y)) / 15 * (26.68 - 20.85)
    for x in xs:
        m.beam("STM", (x, -15, 19.4), (x, 15, 19.4), 0.3, 0.35)
        m.beam("STM", (x, -15, ceil_z(15) - 0.35), (x, 0, ceil_z(0) - 0.35), 0.32, 0.3)
        m.beam("STM", (x, 0, ceil_z(0) - 0.35), (x, 15, ceil_z(15) - 0.35), 0.32, 0.3)
        for y in (-10, -5, 0, 5, 10):
            m.beam("STM", (x, y, 19.55), (x, y, ceil_z(y) - 0.4), 0.2, 0.2)
        for y0, y1 in ((-15, -10), (-10, -5), (-5, 0), (0, 5), (5, 10), (10, 15)):
            ya, yb = (y0, y1) if abs(y0) > abs(y1) else (y1, y0)
            m.beam("STM", (x, ya, 19.55), (x, yb, ceil_z(yb) - 0.41), 0.16, 0.16)
        for s in (-1, 1):
            # aisle rafters under the aisle roof underside (top 9.9 at 23.8 -> 15.5 at 14.95, 0.3 thick)
            zt = lambda y: 9.9 + (23.8 - abs(y)) / 8.85 * 5.6 - 0.35 - 0.35
            m.beam("STM", (x, s * 22.75, zt(22.75)), (x, s * 15.3, zt(15.3)), 0.24, 0.3)

    # ---- niche wall along the back (SW, y = -23) in the open band: maroon, teal dado, mint niches with gold frames
    yb = -22.9
    m.box("NCM", -L2 + 0.1, L2 - 0.1, -23.1, yb, FL, 4.0, skip=("-z", "+z"))
    boxes.append((0, -23.0, FL, 2 * L2 - 0.2, 0.2, 3.6, 0))
    m.box("TEA", -L2 + 0.1, L2 - 0.1, yb, yb + 0.08, FL, 1.2, skip=("-y", "-z"))
    for z0, z1 in ((1.45, 2.35), (2.75, 3.6)):
        x = -46.2
        while x < 46.3:
            if min(abs(x - c) for c in xs) > 0.95:
                w = 0.36
                m.box("NMI", x - w, x + w, yb, yb + 0.06, z0, z1, skip=("-y",))
                m.box("GLD", x - w - 0.1, x - w, yb, yb + 0.14, z0, z1, skip=("-y",))
                m.box("GLD", x + w, x + w + 0.1, yb, yb + 0.14, z0, z1, skip=("-y",))
                m.box("GLD", x - w - 0.1, x + w + 0.1, yb, yb + 0.14, z0 - 0.1, z0, skip=("-y",))
                # pointed gold hood over the niche
                hood = [(-w - 0.15, 0), (w + 0.15, 0), (0, 0.38)]
                m.prism("GLD", hood, 0, 0.14, frame=((x, yb, z1), (-1, 0, 0), (0, 0, 1), (0, 1, 0)), top=True, bottom=False)
            x += 1.3
    # gold cornice over the niches
    m.box("GLD", -L2 + 0.1, L2 - 0.1, yb, yb + 0.09, 3.88, 4.0, skip=("-y",))

    # ---- mosaic dais (plinth) with a white top lip
    PX0, PX1, PY0, PY1, PZ = -33.0, 36.5, -7.0, 8.0, 2.6
    m.box("MOS", PX0, PX1, PY0, PY1, FL, 2.25, skip=("-z", "+z"))
    m.box("MOS", PX0 - 0.4, PX1 + 0.4, PY0 - 0.4, PY1 + 0.4, 2.25, PZ, skip=("+z",))
    m.box("PLT", PX0 - 0.4, PX1 + 0.4, PY0 - 0.4, PY1 + 0.4, 2.25, PZ, skip=("-z", "+x", "-x", "+y", "-y"))
    boxes.append(((PX0 + PX1) / 2, (PY0 + PY1) / 2, FL, PX1 - PX0 + 0.8, PY1 - PY0 + 0.8, PZ - FL, 0))

    # ---- railing (gold, lamps) in front and at the feet end
    def railing(p0, p1):
        d = (p1[0] - p0[0], p1[1] - p0[1])
        Ln = math.hypot(d[0], d[1])
        m.beam("GLD", (p0[0], p0[1], FL + 0.08), (p1[0], p1[1], FL + 0.08), 0.12, 0.16, skip=("-w",))
        m.beam("GLD", (p0[0], p0[1], FL + 1.45), (p1[0], p1[1], FL + 1.45), 0.08, 0.1)
        n = int(Ln / 0.5)
        for i in range(n + 1):
            t = i / n
            px, py = p0[0] + d[0] * t, p0[1] + d[1] * t
            m.prism("GLD", [(-0.04, -0.04), (0.04, -0.04), (0.04, 0.04), (-0.04, 0.04)], FL + 0.16, FL + 1.75,
                    frame=((px, py, 0), (1, 0, 0), (0, 1, 0), (0, 0, 1)), top=False)
            m.face("GLD", [(px - 0.04, py - 0.04, FL + 1.75), (px + 0.04, py - 0.04, FL + 1.75), (px, py, FL + 2.0)], (0, -1, 0.3))
            m.face("GLD", [(px + 0.04, py + 0.04, FL + 1.75), (px - 0.04, py + 0.04, FL + 1.75), (px, py, FL + 2.0)], (0, 1, 0.3))
            m.face("GLD", [(px + 0.04, py - 0.04, FL + 1.75), (px + 0.04, py + 0.04, FL + 1.75), (px, py, FL + 2.0)], (1, 0, 0.3))
            m.face("GLD", [(px - 0.04, py + 0.04, FL + 1.75), (px - 0.04, py - 0.04, FL + 1.75), (px, py, FL + 2.0)], (-1, 0, 0.3))
            if i % 2 == 1:
                m.ellipsoid("LMP", (px, py, FL + 1.62), (0.11, 0.11, 0.11), nu=6, nv=3)
        boxes.append(((p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2, FL, max(abs(d[0]), 0.3), max(abs(d[1]), 0.3), 1.6, 0))
    railing((-32.5, 9.3), (35.5, 9.3))
    railing((-34.4, -6.5), (-34.4, 9.0))

    # ================= the reclining Buddha (lying on the right side, head SE (+x), face NE (+y))
    XH = 34.0

    def F(u, y, z):
        return (XH - u, y, PZ + z)

    # the figure itself: tools/yangon/landmarks3d/buddha_figures_blender.py (headless Blender) -> build/landmarks/figures/chauk_fig.json
    add_figure(m, "chauk")
    # gold grid of the 108 marks and the wheel on each flat sole (x = XH - 65), raised 0.06-0.1 m
    for zc, yc in ((1.55, 1.0), (4.5, 1.35)):
        xs0 = XH - 65.0
        for k in range(7):
            zz = zc - 0.9 + k * 1.8 / 6
            m.box("GLD", xs0 - 0.06, xs0, yc - 2.6, yc + 2.65, PZ + zz - 0.045, PZ + zz + 0.045, skip=("+x",))
        for k in range(15):
            yy = yc - 2.6 + k * 5.25 / 14
            m.box("GLD", xs0 - 0.09, xs0, yy - 0.045, yy + 0.045, PZ + zc - 0.9, PZ + zc + 0.9, skip=("+x",))
        m.loft("GLD", [((xs0, yc + 0.3, PZ + zc), (0, 0.8, 0), (0, 0, 0.8)), ((xs0 - 0.12, yc + 0.3, PZ + zc), (0, 0.8, 0), (0, 0, 0.8))],
               seg=24, cap0="flat", cap1="flat")
    # figure collision: body + head
    boxes.append((XH - 32.5, 0.5, PZ, 66.0, 12.0, 12.0, 0))
    boxes.append((XH - 4.5, 0.2, PZ, 7.0, 7.0, 16.0, 0))
    return m, boxes


# ===================================================================== Ngahtatgyi
def ngah():
    from shapely.geometry import Polygon, box as sbox
    m = Model()
    boxes = []
    HX, HY = 35.9, 28.8           # half sizes of the hall (OSM bbox 71.8 x 57.6 m)
    FL = 0.8                      # floor top (the hall stands on a plinth on its hill)
    m.grid_top("FRD", -HX, HX, -HY, HY, FL, 10, 8)
    m.box("PLN", -HX, HX, -HY, HY, 0, FL, skip=("-z", "+z"))
    boxes.append((0, 0, 0, 2 * HX, 2 * HY, FL, 0))

    # ---- outer walls: ring 0.25 thick; lower part with doors, glass-block band, upper wall
    outer = sbox(-HX, -HY, HX, HY)
    inner = sbox(-HX + 0.25, -HY + 0.25, HX - 0.25, HY - 0.25)
    ring = outer.difference(inner)
    doors = [sbox(-21.0, HY - 0.3, -14.0, HY + 0.1), sbox(-21.0, -HY - 0.1, -14.0, -HY + 0.3),
             sbox(-HX - 0.1, -4.0, -HX + 0.3, 4.0), sbox(2.0, HY - 0.3, 7.0, HY + 0.1)]
    gaps = doors[0].union(doors[1]).union(doors[2]).union(doors[3])
    lower = ring.difference(gaps)
    m.shape("WDR", lower, FL, 4.6, top=False, bottom=False)
    m.shape("GBL", ring, 4.6, 6.0, top=False, bottom=False)
    m.shape("WDR", ring.intersection(gaps), 4.6, 4.6001, top=False, bottom=True, sides=False)  # lintel undersides
    m.shape("WDR", ring, 6.0, 9.45, top=False, bottom=False)
    # wall collision: each side minus its door spans
    def spans(lo, hi, cuts):
        out, cur = [], lo
        for c0, c1 in sorted(cuts):
            if c0 > cur:
                out.append((cur, c0))
            cur = max(cur, c1)
        if cur < hi:
            out.append((cur, hi))
        return out
    for s in (-1, 1):
        cuts = [(-21.0, -14.0)] + ([(2.0, 7.0)] if s > 0 else [])
        for a0, a1 in spans(-HX, HX, cuts):
            boxes.append(((a0 + a1) / 2, s * (HY - 0.125), FL, a1 - a0, 0.25, 8.6, 0))
        cuts = [(-4.0, 4.0)] if s < 0 else []
        for a0, a1 in spans(-HY, HY, cuts):
            boxes.append((s * (HX - 0.125), (a0 + a1) / 2, FL, 0.25, a1 - a0, 8.6, 0))
    # steps up to each door (3 x 0.27 m)
    for d in doors:
        b = d.bounds
        cx, cy = (b[0] + b[2]) / 2, (b[1] + b[3]) / 2
        if abs(cx) > HX - 1:   # west door
            for k in range(2):
                x0 = -HX - 0.4 * (k + 1)
                m.box("PLN", x0, x0 + 0.4, b[1] - 0.5, b[3] + 0.5, 0, FL - 0.27 * (k + 1), skip=("-z", "+x"))
                boxes.append((x0 + 0.2, cy, 0, 0.4, b[3] - b[1] + 1.0, FL - 0.27 * (k + 1), 0))
        else:
            s = 1 if cy > 0 else -1
            for k in range(2):
                y0 = s * (HY + 0.4 * k)
                m.box("PLN", b[0] - 0.5, b[2] + 0.5, min(y0, y0 + s * 0.4), max(y0, y0 + s * 0.4), 0, FL - 0.27 * (k + 1),
                      skip=("-z", "-y" if s > 0 else "+y"))
                boxes.append((cx, y0 + s * 0.2, 0, b[2] - b[0] + 1.0, 0.4, FL - 0.27 * (k + 1), 0))

    # ---- skirt roof: bbox + 1 m eave at z 9.4 up to the inner rect (inset 11) at z 13.2
    OX_, OY_ = HX + 1.0, HY + 1.0
    IX, IY = OX_ - 11.0, OY_ - 11.0
    zo, zi = 9.4, 13.2
    sk = [[(-OX_, -OY_, zo), (OX_, -OY_, zo), (IX, -IY, zi), (-IX, -IY, zi)],
          [(OX_, -OY_, zo), (OX_, OY_, zo), (IX, IY, zi), (IX, -IY, zi)],
          [(OX_, OY_, zo), (-OX_, OY_, zo), (-IX, IY, zi), (IX, IY, zi)],
          [(-OX_, OY_, zo), (-OX_, -OY_, zo), (-IX, -IY, zi), (-IX, IY, zi)]]
    for q in sk:
        m.slab("RUS", "UND", "RUS", q, 0.25, edges=(True, False, False, False))
    sk_under = lambda d: zo - 0.264 + d * (zi - zo) / 11.0     # underside z at distance d in from the eave

    # ---- clerestory ring on the inner rect: dark red, skylight band, dark red
    cl_out = sbox(-IX, -IY, IX, IY)
    cl_in = sbox(-IX + 0.25, -IY + 0.25, IX - 0.25, IY - 0.25)
    cring = cl_out.difference(cl_in)
    m.shape("WDR", cring, 13.05, 14.0, top=False, bottom=True)
    m.shape("SKY", cring, 14.0, 16.4, top=False, bottom=False)
    m.shape("WDR", cring, 16.4, 17.25, top=False, bottom=False)
    # gable roof over the inner rect, ridge along x at z 22.0
    GX, GY, ze, zr = IX + 0.6, IY + 0.6, 17.2, 22.0
    for s in (-1, 1):
        q = [(-GX, s * GY, ze), (GX, s * GY, ze), (GX, 0, zr), (-GX, 0, zr)]
        m.slab("RUS", "UND", "RUS", q, 0.25, edges=(True, True, False, True))
    slope = (zr - ze) / GY
    inner_top = lambda y: ze + (GY - abs(y)) * slope
    gtri = [(-IY, 17.25), (IY, 17.25), (0, 21.88)]
    for x0 in (-IX, IX - 0.25):
        m.prism("WDR", gtri, 0, 0.25, frame=((x0, 0, 0), (0, 1, 0), (0, 0, 1), (1, 0, 0)), top=True, bottom=True)

    # ---- columns (mirror mosaic on red bases) round the inner rect, white girders, rafters, trusses
    colx = [-IX + 0.125 + k * (2 * IX - 0.25) / 8 for k in range(9)]
    coly = [-IY + 0.125 + k * (2 * IY - 0.25) / 6 for k in range(7)]
    posts = set()
    for x in colx:
        posts.add((round(x, 3), round(-IY + 0.125, 3)))
        posts.add((round(x, 3), round(IY - 0.125, 3)))
    for y in coly:
        if abs(y) < 1.0:
            continue   # keep the west door axis clear
        posts.add((round(-IX + 0.125, 3), round(y, 3)))
        posts.add((round(IX - 0.125, 3), round(y, 3)))
    for x, y in sorted(posts):
        m.box("RBS", x - 0.55, x + 0.55, y - 0.55, y + 0.55, FL, 1.8, skip=("-z",))
        m.box("MIR", x - 0.35, x + 0.35, y - 0.35, y + 0.35, 1.8, 13.15, skip=("-z",))
        boxes.append((x, y, FL, 1.1, 1.1, 12.3, 0))
    # girders under the clerestory ring
    for s in (-1, 1):
        m.box("STW", -IX + 0.125 - 0.225, IX - 0.125 + 0.225, s * (IY - 0.125) - 0.225, s * (IY - 0.125) + 0.225, 12.55, 13.1)
        m.box("STW", s * (IX - 0.125) - 0.225, s * (IX - 0.125) + 0.225, -IY + 0.125 + 0.225, IY - 0.125 - 0.225, 12.55, 13.1)
    # rafters from each post out to the outer wall, under the skirt underside
    for x, y in sorted(posts):
        ax, ay = abs(x), abs(y)
        dirs = []
        if abs(ay - (IY - 0.125)) < 0.01 and ax < IX - 1:
            dirs.append((0, math.copysign(1, y)))
        if abs(ax - (IX - 0.125)) < 0.01 and ay < IY - 1:
            dirs.append((math.copysign(1, x), 0))
        for dx, dy in dirs:
            p_in = (x, y)
            p_out = (x + dx * (11.0 - 1.0 - 0.6), y + dy * (11.0 - 1.0 - 0.6)) if dx == 0 else None
            if dx == 0:
                p_out = (x, math.copysign(HY - 0.4, y))
                d_in = OY_ - abs(y)
                d_out = OY_ - (HY - 0.4)
            else:
                p_out = (math.copysign(HX - 0.4, x), y)
                d_in = OX_ - abs(x)
                d_out = OX_ - (HX - 0.4)
            m.beam("STW", (p_out[0], p_out[1], sk_under(d_out) - 0.3), (p_in[0], p_in[1], sk_under(d_in) - 0.3), 0.26, 0.3)
    # nave trusses (white) under the gable, west of the shrine
    under = lambda y: inner_top(y) - 0.258
    for x in colx:
        if x > 7.0 or abs(x) > IX - 1.0:
            continue
        yl = IY - 0.125
        m.beam("STW", (x, -yl, 17.0), (x, yl, 17.0), 0.3, 0.35)
        m.beam("STW", (x, -yl, under(yl) - 0.3), (x, 0, under(0) - 0.3), 0.3, 0.3)
        m.beam("STW", (x, 0, under(0) - 0.3), (x, yl, under(yl) - 0.3), 0.3, 0.3)
        for y in (-12.0, -6.0, 0.0, 6.0, 12.0):
            m.beam("STW", (x, y, 17.18), (x, y, under(y) - 0.35), 0.18, 0.18)
        for y0, y1 in ((-18, -12), (-12, -6), (-6, 0), (0, 6), (6, 12), (12, 18)):
            ya, yb = (y0, y1) if abs(y0) > abs(y1) else (y1, y0)
            m.beam("STW", (x, ya, 17.18), (x, yb, under(yb) - 0.36), 0.14, 0.14)

    # ---- five-tier tower over the shrine (centre x 11), walls follow the gable roof at their foot
    TCX = 11.0
    tiers = [(8.0, 23.0, 8.8, 22.8, 6.5, 24.4), (6.5, 25.5, 7.2, 25.3, 5.1, 26.7), (5.1, 27.6, 5.8, 27.4, 3.8, 28.6),
             (3.8, 29.4, 4.4, 29.2, 2.6, 30.3), (2.6, 31.0, 3.2, 30.8, 0.0, 33.3)]
    prev_roof = None
    for i, (h, top, eh, ez, ih, iz) in enumerate(tiers):
        # wall foot: on the gable (tier 0) or inside the previous tier's roof
        if i == 0:
            foot = lambda x, y: inner_top(y) - 0.12
        else:
            ph, pz0, pih, pz1 = prev_roof
            zz = pz0 + (ph - h) / (ph - pih) * (pz1 - pz0) - 0.12
            foot = lambda x, y, zz=zz: zz
        # roof top at the wall line (for the wall's top)
        wtop = ez + (eh - h) / (eh - ih) * (iz - ez) - 0.12 if ih > 0 else ez + (eh - h) / eh * (iz - ez) - 0.12
        corners = [(TCX - h, -h), (TCX + h, -h), (TCX + h, h), (TCX - h, h)]
        for k in range(4):
            a, b = corners[k], corners[(k + 1) % 4]
            n = 24 if i == 0 else 1
            nrm = unit((b[1] - a[1], -(b[0] - a[0]), 0))
            for j in range(n):
                p = (a[0] + (b[0] - a[0]) * j / n, a[1] + (b[1] - a[1]) * j / n)
                q = (a[0] + (b[0] - a[0]) * (j + 1) / n, a[1] + (b[1] - a[1]) * (j + 1) / n)
                m.quad("WDR", (p[0], p[1], foot(*p)), (q[0], q[1], foot(*q)), (q[0], q[1], wtop), (p[0], p[1], wtop), nrm)
        # roof
        if ih > 0:
            Q = [[(TCX - eh, -eh, ez), (TCX + eh, -eh, ez), (TCX + ih, -ih, iz), (TCX - ih, -ih, iz)],
                 [(TCX + eh, -eh, ez), (TCX + eh, eh, ez), (TCX + ih, ih, iz), (TCX + ih, -ih, iz)],
                 [(TCX + eh, eh, ez), (TCX - eh, eh, ez), (TCX - ih, ih, iz), (TCX + ih, ih, iz)],
                 [(TCX - eh, eh, ez), (TCX - eh, -eh, ez), (TCX - ih, -ih, iz), (TCX - ih, ih, iz)]]
            for q in Q:
                m.slab("RUS", "UND", "RUS", q, 0.22, edges=(True, False, False, False))
        else:
            apex = (TCX, 0, iz)
            E = [(TCX - eh, -eh, ez), (TCX + eh, -eh, ez), (TCX + eh, eh, ez), (TCX - eh, eh, ez)]
            for k in range(4):
                a, b = E[k], E[(k + 1) % 4]
                mid = ((a[0] + b[0]) / 2 - TCX, (a[1] + b[1]) / 2, 0.6)
                m.face("RUS", [a, b, apex], mid)
            m.face("UND", E[::-1], (0, 0, -1))
        prev_roof = (eh, ez, ih, iz)
    # gold finial (hti) on the top
    hp = [(32.9, 0.55), (33.6, 0.5), (34.0, 0.62), (34.3, 0.45), (35.0, 0.3), (35.8, 0.16), (36.5, 0.0)]
    m.loft("GLD", [((TCX, 0, z), (r, 0, 0), (0, r, 0)) for z, r in hp], seg=16, cap0="flat", cap1=None)

    # ================= the seated Buddha (bhumisparsha), facing west (-x), throne and teak backdrop
    S = 3.6   # seat top
    m.box("GLD", 6.0, 16.5, -9.0, 9.0, FL, 2.0, skip=("-z",))
    m.box("RBS", 6.8, 16.0, -8.2, 8.2, 2.0, 3.1, skip=("-z",))
    m.box("GLD", 7.4, 15.5, -7.6, 7.6, 3.1, S, skip=("-z",))
    boxes.append((11.25, 0, FL, 10.5, 18.0, S - FL, 0))
    boxes.append((11.0, 0, S, 8.0, 13.0, 14.0, 0))
    # the figure itself: tools/yangon/landmarks3d/buddha_figures_blender.py (headless Blender) -> build/landmarks/figures/ngah_fig.json
    add_figure(m, "ngah")
    # carved teak backdrop with gold flames and relief
    bd = [(-10.5, FL), (10.5, FL), (10.5, 13.5), (9.6, 14.6), (9.9, 15.6), (8.4, 16.4), (8.2, 17.6), (6.2, 18.0), (5.4, 19.0),
          (3.0, 19.2), (1.4, 20.0), (0, 20.6), (-1.4, 20.0), (-3.0, 19.2), (-5.4, 19.0), (-6.2, 18.0), (-8.2, 17.6),
          (-8.4, 16.4), (-9.9, 15.6), (-9.6, 14.6), (-10.5, 13.5)]
    m.prism("TEK", bd, 0, 0.6, frame=((15.2, 0, 0), (0, 1, 0), (0, 0, 1), (1, 0, 0)), top=True, bottom=True)
    boxes.append((15.5, 0, FL, 0.6, 21.0, 19.0, 0))
    # carved relief: two rows of leaf plates following the backdrop's outline (TKL, 0.12 proud), gold flames
    from shapely.geometry import Polygon as SPoly
    outline = SPoly(bd)
    leaf = [(0, -0.75), (0.42, -0.35), (0.5, 0.15), (0.3, 0.55), (0.05, 0.95), (-0.1, 0.55), (-0.42, 0.3), (-0.5, -0.3)]
    relief = []
    for inset, step, sc, dep in ((0.9, 1.25, 1.0, 0.12), (2.2, 1.5, 0.85, 0.2)):
        ring2 = outline.buffer(-inset, join_style=2).exterior
        L = ring2.length
        k = 0
        while k * step < L:
            p = ring2.interpolate(k * step)
            q = ring2.interpolate(min(L, k * step + 0.3))
            k += 1
            if p.y < FL + 2.5:
                continue   # nothing along the bottom (hidden behind the throne)
            tx, ty = q.x - p.x, q.y - p.y
            tl = math.hypot(tx, ty) or 1.0
            tx, ty = tx / tl, ty / tl
            nx, ny = ty, -tx       # outward of the CCW ring
            if outline.contains(type(p)(p.x + nx * 0.5, p.y + ny * 0.5)):
                nx, ny = -nx, -ny
            # 2026-11-16: an acanthus scroll leaf from the ornament kit (bevelled, curling into a volute, alternating
            # hands) in place of a flat leaf plate; it rises from the ring along the outward normal
            ang = math.degrees(math.atan2(ny, nx)) - 90.0
            sl = OK.scroll(1.25 * sc, p.x, p.y, ang=ang, mirror=(k % 2 == 0), n=6)
            relief.append((sl, dep))
    for sl, dep in relief:
        P_ = OK.Piece("bd")
        OK.slab(P_, "G", sl, 0.0, dep, 0.035, back=False, band=False)
        OK.into_model(P_, m, {"G": "TKL"}, (15.2, 0.0, 0.0), (0.0, 1.0, 0.0), (-1.0, 0.0, 0.0), (0.0, 0.0, 1.0))
    # gold flames by the crown: the ornament kit's carved kanote (bevelled, flame tongues, raised spine) on the teak
    for sy in (-1, 1):
        fl = OK.Piece("fl")
        OK.slab(fl, "G", OK.move(OK.flame_outline(1.4, 5.4, lobes=3, n_lobe=3, barb=0.6, lean=sy * 0.06), dx=sy * 4.95,
                                 dz=S + 7.4), 0.0, 0.14, 0.04, back=False, band=True)
        OK.slab(fl, "G", OK.move(OK.flame_outline(0.5, 3.6, lobes=2, n_lobe=2, barb=0.4, lean=sy * 0.05), dx=sy * 4.95,
                                 dz=S + 8.2), 0.14, 0.08, 0.025, back=False, band=False)
        OK.into_model(fl, m, {"G": "FGB"}, (15.2, 0.0, 0.0), (0.0, 1.0, 0.0), (-1.0, 0.0, 0.0), (0.0, 0.0, 1.0))
    # offering table (white cloth)
    m.box("CLT", 4.4, 5.8, -9.0, 9.0, FL, 2.0, skip=("-z",))
    boxes.append((5.1, 0, FL, 1.4, 18.0, 1.2, 0))
    return m, boxes


# ===================================================================== run
SITES = {
    "chaukhtatgyi": dict(build=chauk, lonlat=(96.163884, 16.811666), bearing=122.3,
                         plate=(100.0, 52.0), name="Chaukhtatgyi"),
    "ngahtatgyi": dict(build=ngah, lonlat=(96.1625601, 16.80844755), bearing=90.0,
                       plate=(76.0, 64.0), name="Ngahtatgyi"),
}


def run(which=None, flicker=True):
    import ground
    from flicker_check import check
    G = ground.Ground()
    report = {}
    for key, S in SITES.items():
        if which and key != which:
            continue
        m, boxes = S["build"]()
        X, Z = geo.world(*S["lonlat"])
        Y = G.y(X, Z)
        pivot = (round(X, 2), round(Y, 2), round(Z, 2))
        out = os.path.join(SYNC, key + ".glb")
        info, world = export(m, pivot, S["bearing"], out, key[:4])
        per = {g: len(v) for g, v in sorted(m.g.items())}
        res = dict(pivot=pivot, bearing=S["bearing"], tris=info["tris"], meshes=info["meshes"], bad_glb=info["bad"], per_group=per)
        if flicker:
            bad, T = check([(t, g) for t, g, sid in world])
            res["flicker_pairs"] = len(bad)
            res["flicker_examples"] = [(T[i][1], T[j][1], round(g_, 3), round(a, 3), [round(c, 1) for c in T[i][0][0]])
                                       for i, j, g_, a in bad[:12]]
        os.makedirs(os.path.join(BUILD, key), exist_ok=True)
        place = dict(name=S["name"], pivot=pivot, bearing=S["bearing"], lonlat=S["lonlat"],
                     plate=[S["plate"][0] * 3, S["plate"][1] * 3],
                     plate_yaw=collide_rows([(0, 0, 0, 1, 1, 1, 0)], pivot, S["bearing"])[0][6],
                     look={k: v for k, v in LOOK.items() if k in m.g},
                     collide=collide_rows(boxes, pivot, S["bearing"]), names=info["names"])
        json.dump(place, open(os.path.join(BUILD, key, key + "_place.json"), "w"), indent=0)
        report[key] = res
        print(key, json.dumps(res, indent=1))
    return report


if __name__ == "__main__":
    run(sys.argv[1] if len(sys.argv) > 1 else None)


VIEWS = {
    "chaukhtatgyi": {"aerial": [[-90, 90, 80], [0, 0, 5], 30], "inside_front": [[0, 19, 1.7], [0, 0, 8], 14],
                     "head": [[28, 13, 3], [30, 0, 11], 22], "feet": [[-44, 3, 3], [-31, 3, 4], 22],
                     "outside_ne": [[10, 70, 8], [0, 0, 8], 24]},
    "ngahtatgyi": {"aerial": [[-80, -80, 75], [0, 0, 10], 30], "inside_west": [[-30, 0, 1.7], [11, 0, 9], 18],
                   "buddha": [[-5, 0, 2.5], [11, 0, 11], 22], "outside_n": [[-15, 75, 6], [0, 0, 14], 24],
                   "hall_n": [[-12, -16, 1.7], [-12, 18, 8], 14]},
}


def dump(key, out_json):
    m, _ = SITES[key]["build"]()
    data = {"look": {g: ((212, 172, 92) if g in ("GLD", "ROB") else LOOK[g][1]) for g in m.g},
            "tris": {g: [[list(a), list(b), list(c)] for a, b, c, n, sid in T] for g, T in m.g.items()}}
    json.dump(data, open(out_json, "w"))
    json.dump(VIEWS[key], open(out_json.replace(".json", "_views.json"), "w"))
