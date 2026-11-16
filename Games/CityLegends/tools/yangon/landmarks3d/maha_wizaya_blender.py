# Maha Wizaya Pagoda (Yangon, south of Shwedagon) - true-scale model with its walkable hollow inside.
# HEADLESS Blender 3.6 only (never the owner's open Blender):
#   "C:/Program Files/Blender Foundation/Blender 3.6/blender.exe" -b --factory-startup --python \
#       tools/yangon/landmarks3d/maha_wizaya_blender.py -- all
#   modes: build (+check +export), render (preview pictures), all
# Pictures for the interior come from maha_wizaya_textures.py (painted in code, no photo copied).
#
# Re-uses the Kaba Aye helpers (MB mesh builder, to_mesh with box UVs at 1 UV = 1 stud, add_obj, export, report,
# check_overlaps) by exec'ing kaba_aye_blender.py, then overrides the globals (COLL, GLB, MATS).
#
# Units: metres, +Z up, +Y north, +X east. Pivot = the stupa axis on the PLAZA GROUND (z 0 = the ground under the marble
# plaza; the plaza top is 0.3, every inside floor 0.65). Sizes and sources: vault note
# "City Legends/2026-11-16 Maha Wizaya Pagoda 3D model.md".
import bpy, bmesh, math, os, sys, json
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(HERE, "kaba_aye_blender.py"), encoding="utf-8").read())

VAULT = r"D:/ObsidianOne/Claude+Obsidian"
GAME = VAULT + "/Games/CityLegends"
GLB = GAME + "/imports/sync/landmarks/maha_wizaya.glb"
OUTDIR = GAME + "/build/landmarks/maha_wizaya"
TEX = OUTDIR + "/tex"
COLL = "MahaWizaya"
SPM = 3.0

# name -> ((r, g, b), metal, rough). The name's prefix tells the Studio placer the look (maha_wizaya_place.luau).
MATS = {
    "Gold":        ((226, 190, 124), 0.6, 0.35),  # stupa, terraces, small stupas, trims (photo 2013 12:49: 171,144,96 lit)
    "Cream":       ((244, 232, 182), 0.0, 0.85),  # base wall, porches, ambulatory walls (photo 16, porch cream)
    "White":       ((250, 248, 240), 0.0, 0.80),  # shrine, chinthe, ceilings, cases
    "Red":         ((150, 52, 46), 0.0, 0.80),    # plinth band, porch steps (photo 16: 118,48,46 in morning light)
    "Marble":      ((226, 224, 218), 0.0, 0.50),  # plaza
    "FloorDark":   ((70, 72, 72), 0.1, 0.30),     # chamber floor (photo 17: dark polished grey stone)
    "FloorLight":  ((214, 208, 196), 0.0, 0.40),  # ambulatory + tunnels
    "Lattice":     ((44, 92, 66), 0.0, 0.70),     # green panel behind the gold lattice (photo 16)
    "Wood":        ((118, 74, 44), 0.0, 0.70),    # inner door leaves (photo 17)
    "Trunk":       ((108, 118, 114), 0.0, 0.90),  # relief tree trunks (photo 17: grey-blue)
    "Lotus":       ((196, 98, 92), 0.0, 0.70),    # shrine's lotus basin (photo 21)
    "TileBlue":    ((90, 168, 196), 0.0, 0.40),   # shrine moat tiles
    "Grate":       ((60, 60, 62), 0.4, 0.60),     # grating over the moat
    "Glass":       ((200, 226, 232), 0.0, 0.10),  # shrine case, hti fan
    "Carpet":      ((150, 44, 40), 0.0, 0.95),
    "Roof":        ((70, 120, 92), 0.2, 0.60),    # gate pavilion roofs (Esri: green)
    "TexDome":     ((255, 255, 255), 0.0, 0.80),  # textured: tex/dome.png
    "TexMural":    ((255, 255, 255), 0.0, 0.90),  # textured: tex/mural.png
    "TexLeaves":   ((255, 255, 255), 0.0, 0.90),  # textured: tex/leaves.png
}
TEXFILE = {"TexDome": "dome.png", "TexMural": "mural.png", "TexLeaves": "leaves.png"}

C8 = math.cos(math.pi / 8)
# --- key sizes (m). Sources in the vault note.
A_BASE = 27.4      # base octagon apothem (OSM way/180612556: 54 x 54 m octagon; Esri z19 54.8 m)
PLAZA = 45.0       # plaza half side (Esri z19: 90 x 90 m marble square)
Z_PLAZA = 0.3
Z_FLOOR = 0.65     # all inside floors (porch plinth, photo 16)
Z_WALLTOP = 4.6    # base wall top (corbel above)
PW = 5.35          # porch half width (photo 16: 10.7 m)
PY1 = 31.9         # porch front (4.5 m out from the base)
AW = 2.05          # porch arch half width (photo 16: 4.1 m)
A_SPRING, A_APEX = 3.9, 6.3
P_TOP = 6.8
T1 = 5.8           # first terrace floor
R_CH = 11.0        # chamber radius (interiors catalogue est. 20 m across; photos 17/21: ~22 m)
R_CHW = 13.0       # chamber wall outer face = ambulatory inner wall
R_AMB = 17.0       # ambulatory outer wall
Z_CHWALL = 5.5     # chamber wall top = dome spring
Z_DOME = 15.0      # dome top inside
Z_AMBC = 4.6       # ambulatory ceiling
DW = 1.7           # chamber doorway half width
D_SPRING = 3.2
TW_SPRING = 3.6    # tunnel (through the base) wall top; vault apex = Z_AMBC
G_CH = math.asin(DW / R_CH)
G_CHW = math.asin(DW / R_CHW)
G_AMB = math.asin(AW / R_AMB)
CARD = [0.0, 90.0, 180.0, 270.0]  # porch bearings (N, E, S, W): Esri z19 + interior photos (doors at the cardinal points)


def pol(r, th, z):
    """th = math angle (rad, from +X anticlockwise)."""
    return (r * math.cos(th), r * math.sin(th), z)


def quad_angles(g, n):
    """Angle samples (rad, math angles) of the 4 wall stretches between doorways at the cardinal points, each from
    (cardinal + g) to (next cardinal - g), n segments each. Doorways at math angles 0, 90, 180, 270."""
    out = []
    for q in range(4):
        a0 = math.radians(90 * q) + g
        a1 = math.radians(90 * (q + 1)) - g
        out.append([a0 + (a1 - a0) * i / n for i in range(n + 1)])
    return out


def ring_wall(mb, r, angs, z0, z1, inward):
    for i in range(len(angs) - 1):
        a, b = angs[i], angs[i + 1]
        m = (a + b) / 2
        w = (-math.cos(m), -math.sin(m), 0) if inward else (math.cos(m), math.sin(m), 0)
        mb.P([pol(r, a, z0), pol(r, b, z0), pol(r, b, z1), pol(r, a, z1)], w)


# ------------------------------------------------------------------ outside
def plaza():
    mb, red = MB(), MB()
    h = PLAZA
    mb.P([(-h, -h, Z_PLAZA), (h, -h, Z_PLAZA), (h, h, Z_PLAZA), (-h, h, Z_PLAZA)], (0, 0, 1))
    for (x0, y0, x1, y1, w) in [(-h, -h, h, -h, (0, -1, 0)), (h, -h, h, h, (1, 0, 0)), (h, h, -h, h, (0, 1, 0)), (-h, h, -h, -h, (-1, 0, 0))]:
        red.P([(x0, y0, 0), (x1, y1, 0), (x1, y1, Z_PLAZA), (x0, y0, Z_PLAZA)], w)
    return {"Marble": mb, "Red": red}


def side_frame(k):
    """Octagon side k (0..7) at bearing 45k: outward normal n, tangent t (both XY)."""
    b = math.radians(45 * k)
    n = Vector((math.sin(b), math.cos(b), 0))
    t = Vector((n.y, -n.x, 0))
    return n, t


def side_spans(k, A):
    h = A * math.tan(math.pi / 8)
    if k % 2 == 0:  # cardinal: porch in the middle
        return [(-h, -PW), (PW, h)]
    return [(-h, h)]


def side_wall(mb, A, z0, z1):
    for k in range(8):
        n, t = side_frame(k)
        for t0, t1 in side_spans(k, A):
            P = lambda tt, z: tuple(n * A + t * tt + Vector((0, 0, z)))
            mb.P([P(t0, z0), P(t1, z0), P(t1, z1), P(t0, z1)], tuple(n))


def side_flat(mb, A0, A1, z, up):
    """Horizontal octagon band between apothems A0 < A1 at z, split at the porches (cardinal sides)."""
    for k in range(8):
        n, t = side_frame(k)
        h0, h1 = A0 * math.tan(math.pi / 8), A1 * math.tan(math.pi / 8)
        Z = Vector((0, 0, z))
        if k % 2 == 0:
            for s in (-1, 1):
                pts = [n * A0 + t * (s * PW) + Z, n * A0 + t * (s * h0) + Z, n * A1 + t * (s * h1) + Z, n * A1 + t * (s * PW) + Z]
                mb.P([tuple(p) for p in pts], (0, 0, 1 if up else -1))
        else:
            pts = [n * A0 - t * h0 + Z, n * A0 + t * h0 + Z, n * A1 + t * h1 + Z, n * A1 - t * h1 + Z]
            mb.P([tuple(p) for p in pts], (0, 0, 1 if up else -1))


def base():
    """The cream base round the hollow inside: red plinth band, cream wall, a corbelled cornice with a gold band."""
    cream, red, gold = MB(), MB(), MB()
    side_wall(red, A_BASE, Z_PLAZA, 0.75)
    side_wall(cream, A_BASE, 0.75, Z_WALLTOP)
    side_flat(cream, A_BASE, 27.75, Z_WALLTOP, up=False)
    side_wall(cream, 27.75, Z_WALLTOP, 5.2)
    side_flat(cream, 27.75, 28.05, 5.2, up=False)
    side_wall(gold, 28.05, 5.2, T1)
    return {"Cream": cream, "Red": red, "Gold": gold}


def oct_revolve(mb, prof):
    """prof [(apothem, z)] bottom -> top, outward normals; octagon with flats facing the 8 bearings."""
    mb.revolve([(a / C8, z) for a, z in prof], 8, a0=math.pi / 8)


def terraces():
    gold = MB()
    oct_revolve(gold, [(28.05, T1), (21.2, T1), (21.2, 8.6), (21.45, 8.6), (21.45, 9.2), (17.4, 9.2), (17.4, 11.8),
                       (17.65, 11.8), (17.65, 12.4), (0.0, 12.4)])
    # 2026-11-16: a row of carved gold flames (ornament kit, thick kanote slabs) along each terrace's edge (photos 01 and
    # 2013: the gold terraces are edged with flame leaves); clear of the porches on the cardinal faces
    fl = OK.flame_blade(0.55, 0.95, 0.08, lod="micro")
    for a, z, gap in ((28.05 - 0.25, T1, PW + 0.8), (21.45 - 0.22, 9.2, 0.0), (17.65 - 0.22, 12.4, 0.0)):
        half = a * math.tan(math.pi / 8) - 0.5
        n = max(2, int(2 * half / 1.45))
        for k in range(8):
            th = math.radians(45 * k)
            o, r = (math.cos(th), math.sin(th), 0.0), (math.sin(th), -math.cos(th), 0.0)
            for i in range(n + 1):
                u = -half + 2 * half * i / n
                if k % 2 == 0 and abs(u) < gap:
                    continue
                OK.into_mb(fl, {"G": gold}, (a * o[0] + u * r[0], a * o[1] + u * r[1], z), r, o)
    return {"Gold": gold}


BELL = [(14.0, 12.4), (14.0, 13.2), (13.2, 13.2), (13.2, 14.0), (12.3, 14.0), (12.3, 14.8), (11.6, 14.8), (11.6, 15.7),
        (10.85, 15.7), (11.0, 16.2), (11.15, 16.4), (11.15, 16.8), (11.0, 17.0), (11.0, 18.5), (10.85, 19.9), (10.93, 20.0),
        (10.93, 20.25), (10.8, 20.4), (10.4, 22.4), (10.3, 23.1), (10.38, 23.2), (10.36, 23.45), (10.2, 23.6), (9.8, 24.5),
        (8.9, 26.3), (7.9, 27.8), (7.0, 28.9), (6.3, 29.6), (6.35, 29.8)]


def stupa():
    """Round mouldings, the bell (two raised bands, photos 2010/2013), the ringed cone (9 rings), lotus and bead bands.
    Heights: total 169 ft = 51.5 m, 'dome' to the umbrella 134 ft = 40.8 m, hti 22 ft, diamond bud 13 ft (Burmese
    Wikipedia); bell foot 21.7 m across and the bands' heights from photo Yangon_Maha_Wizaya_Zedi_Pagode_01 scaled to that."""
    gold = MB()
    prof = list(BELL)
    r0, r9, z = 6.0, 2.1, 29.8
    for k in range(9):
        rk = r0 + (r9 - r0) * k / 9
        rn = r0 + (r9 - r0) * (k + 1) / 9
        prof += [(rk + 0.18, z + 0.12), (rk + 0.18, z + 0.55), (rn + 0.02, z + 0.95)]
        z += 0.95
    prof += [(2.1, 38.35), (2.5, 38.8), (2.55, 38.95), (2.2, 39.3), (1.9, 39.4), (1.98, 39.6), (1.9, 39.85), (1.6, 39.9),
             (1.6, 40.5), (1.3, 40.6), (1.0, 40.8), (1.0, 41.4), (1.45, 41.5), (1.5, 41.95), (1.45, 42.4), (1.3, 42.5)]
    # hti: 11 tiers (11-tier umbrella, travel sources), cone 1.3 -> 0.2 m from 42.5 to 47.3
    z = 42.5
    for k in range(11):
        rk = 1.3 - 1.1 * k / 11
        rn = 1.3 - 1.1 * (k + 1) / 11
        prof += [(rk + 0.08, z + 0.05), (rn + 0.02, z + 0.436)]
        z += 0.436
    prof += [(0.2, 47.3), (0.07, 47.35), (0.07, 51.0), (0.16, 51.1), (0.19, 51.25), (0.12, 51.42), (0.0, 51.5)]
    gold.revolve(prof, 48)
    # vane (flag) on the mast
    vane = MB()
    vane.extrude([(0.07, 0.0), (1.25, 0.15), (1.1, 0.35), (1.25, 0.55), (0.07, 0.6)], (Vector((0, 0, 47.9)), Vector((1, 0, 0)), Vector((0, 0, 1)), Vector((0, 1, 0))), -0.04, 0.04)
    return {"Gold": gold}, vane


def fan_mesh():
    """Glass dish: top + bottom surfaces 0.06 apart (no shared faces)."""
    mb = MB()
    n = 32
    for i in range(n):
        a, b = 2 * math.pi * i / n, 2 * math.pi * (i + 1) / n
        r0, r1 = 1.0, 3.4
        for zin, zout, up in ((40.92, 41.18, True), (40.86, 41.12, False)):
            mb.P([pol(r0, a, zin), pol(r1, a, zout), pol(r1, b, zout), pol(r0, b, zin)], (0, 0, 1 if up else -1))
        mb.P([pol(3.4, a, 41.12), pol(3.4, b, 41.12), pol(3.4, b, 41.18), pol(3.4, a, 41.18)], (math.cos((a + b) / 2), math.sin((a + b) / 2), 0))
    return mb


def small_stupa():
    """Unit-height gold zedi (1 m), base radius 0.32: scaled per ring."""
    mb = MB()
    mb.revolve([(0.34, 0.0), (0.34, 0.12), (0.29, 0.12), (0.29, 0.2), (0.25, 0.2), (0.25, 0.26), (0.3, 0.3), (0.31, 0.36),
                (0.29, 0.44), (0.22, 0.52), (0.18, 0.55), (0.18, 0.58), (0.13, 0.62), (0.13, 0.66), (0.09, 0.72),
                (0.09, 0.76), (0.055, 0.82), (0.04, 0.9), (0.015, 0.97), (0.0, 1.0)], 8, a0=math.pi / 8)
    return mb


def porch():
    """One porch facing +Y (photo 16): cream piers and pointed arch, the pediment with sweeping horns and a centre
    finial, gold bands, the green panel with a gold rosette in the arch top, gold gate leaves folded open, the step."""
    cream, gold, lat, red, floor = MB(), MB(), MB(), MB(), MB()
    arch = pointed_arch(AW, A_SPRING, A_APEX)  # right foot of the curve -> apex -> left
    arch = arch[: len(arch) // 2 + 1]
    left = [(-x, z) for x, z in reversed(arch[:-1])]
    arch_line = [(AW, Z_PLAZA)] + arch + left + [(-AW, Z_PLAZA)]  # right foot -> over -> left foot
    body = [(-PW, Z_PLAZA)] + [(-PW, P_TOP), (PW, P_TOP), (PW, Z_PLAZA)] + arch_line
    frame = (Vector((0, PY1, 0)), Vector((1, 0, 0)), Vector((0, 0, 1)), Vector((0, 1, 0)))
    cream.extrude(body, frame, -(PY1 - A_BASE), 0.0, back_face=False)
    # the body's back above the first terrace (seen from the terrace; below it the base closes it)
    cream.P([(-PW, A_BASE, T1), (PW, A_BASE, T1), (PW, A_BASE, P_TOP), (-PW, A_BASE, P_TOP)], (0, -1, 0))
    # pediment (front plate 0.9 deep) with horns and a finial
    half = [(5.6, P_TOP), (6.0, 7.6), (6.15, 8.4), (5.85, 9.25), (5.5, 9.05), (5.55, 8.35), (5.05, 7.95), (3.8, 8.15),
            (2.6, 8.65), (1.5, 9.25), (0.6, 9.85), (0.35, 10.6), (0.5, 11.3)]
    ped = [(-x, z) for x, z in half] + [(0.0, 12.3)] + [(x, z) for x, z in reversed(half)]
    cream.extrude(ped, frame, -0.9, 0.0)
    # gold flame row along both roof slopes, 0.06 proud
    def roof_z(x):
        for (xa, za), (xb, zb) in zip(half[6:10], half[7:11]):
            if xb <= x <= xa:
                return za + (zb - za) * (xa - x) / (xa - xb)
        return 9.0
    xs = [4.9 - i * 0.5 for i in range(8)]  # 4.9 .. 1.4
    top = []
    for i, x in enumerate(xs[:-1]):
        xn = xs[i + 1]
        top += [(x, roof_z(x) - 0.1), ((x + xn) / 2, roof_z((x + xn) / 2) + 0.42)]
    top.append((xs[-1], roof_z(xs[-1]) - 0.1))
    bot = [(x, roof_z(x) - 0.4) for x in reversed(xs)]
    # 2026-11-16: the ornament kit's carved flames (bevelled kanote slabs 0.1 m proud, tongues on both sides, a back
    # face where they stand above the gable) along both roof slopes, in place of a flat zigzag plate; a gold carved
    # flame finial at the centre and a corner flame (horn) on each horn
    row = OK.Piece("pedrow")
    for s in (-1, 1):
        for i, x in enumerate(xs[:-1]):
            xm = (x + xs[i + 1]) / 2
            zr = roof_z(xm) - 0.25
            fl = OK.move(OK.flame_outline(0.42, 0.75, lobes=1, n_lobe=2, barb=0.55, lean=-s * 0.12), dx=s * xm, dz=zr)
            OK.slab(row, "G", fl, 0.0, 0.1, 0.02, back=True, band=False)
    OK.into_mb(row, {"G": gold}, (0.0, PY1, 0.0))
    OK.into_mb(OK.flame_finial(1.9, lod="hi"), {"G": gold}, (0.0, PY1 + 0.02, 10.4))
    # gold band round the arch (0.3 wide, 0.08 proud), from the floor
    oa = pointed_arch(AW + 0.3, A_SPRING, A_APEX + 0.35)
    ia = pointed_arch(AW, A_SPRING, A_APEX)
    band = [(AW + 0.3, Z_FLOOR)] + oa + [(-AW - 0.3, Z_FLOOR), (-AW, Z_FLOOR)] + list(reversed(ia)) + [(AW, Z_FLOOR)]
    gold.extrude(band, frame, 0.0, 0.08, back_face=False)
    # gold pilaster panels on the pier fronts
    for s in (-1, 1):
        x0, x1 = (AW + 0.9, AW + 1.6) if s > 0 else (-AW - 1.6, -AW - 0.9)
        gold.extrude([(x0, 1.1), (x1, 1.1), (x1, 5.6), (x0, 5.6)], frame, 0.0, 0.08, back_face=False)
        x0, x1 = (PW - 0.9, PW - 0.35) if s > 0 else (-PW + 0.35, -PW + 0.9)
        gold.extrude([(x0, 1.1), (x1, 1.1), (x1, 6.2), (x0, 6.2)], frame, 0.0, 0.08, back_face=False)
    # tympanum: green panel (both sides) in the arch top, 0.6 behind the front; gold transom bar; gold rosette + spokes
    ty = PY1 - 0.6
    tymp = arch + left
    fr2 = (Vector((0, ty, 0)), Vector((1, 0, 0)), Vector((0, 0, 1)), Vector((0, 1, 0)))
    lat.extrude(tymp, fr2, -0.05, 0.0)
    gold.extrude([(-AW, A_SPRING - 0.25), (AW, A_SPRING - 0.25), (AW, A_SPRING), (-AW, A_SPRING)], fr2, -0.05, 0.0)
    cx, cz = 0.0, 4.75
    ring = []
    for i in range(16):
        t = 2 * math.pi * i / 16
        ring.append((cx + 0.55 * math.cos(t), cz + 0.55 * math.sin(t)))
    gold.extrude(ring, fr2, 0.0, 0.05, back_face=False)
    for i in range(12):
        t = math.pi * i / 11
        ux, uz = math.cos(t), math.sin(t)
        px_, pz_ = -uz * 0.05, ux * 0.05
        a, b = (cx + 0.6 * ux, cz + 0.6 * uz), (cx + 1.55 * ux, cz + 1.55 * uz)
        if b[1] > A_APEX - 0.25 or abs(b[0]) > AW - 0.1:
            b = (cx + 1.2 * ux, cz + 1.2 * uz)
        if abs(b[0]) > AW - 0.1 or b[1] < A_SPRING:
            continue
        gold.extrude([(a[0] + px_, a[1] + pz_), (a[0] - px_, a[1] - pz_), (b[0] - px_, b[1] - pz_), (b[0] + px_, b[1] + pz_)], fr2, 0.0, 0.05, back_face=False)
    # gate leaves folded open against the tunnel walls (0.1 m off the wall)
    for s in (-1, 1):
        x0, x1 = (AW - 0.18, AW - 0.1) if s > 0 else (-AW + 0.1, -AW + 0.18)
        gold.box(x0, x1, ty - 2.05, ty - 0.05, Z_FLOOR, A_SPRING - 0.3, skip=("-z",))
    # step / floor slab (top + front riser)
    floor.P([(-AW, A_BASE, Z_FLOOR), (AW, A_BASE, Z_FLOOR), (AW, PY1, Z_FLOOR), (-AW, PY1, Z_FLOOR)], (0, 0, 1))
    red.P([(-AW, PY1, Z_PLAZA), (AW, PY1, Z_PLAZA), (AW, PY1, Z_FLOOR), (-AW, PY1, Z_FLOOR)], (0, 1, 0))
    # step face where the tall porch arch meets the lower tunnel at the base wall (faces out, +Y)
    tv = tunnel_vault(AW, TW_SPRING, Z_AMBC)
    step = [(AW, TW_SPRING)] + arch + left + [(-AW, TW_SPRING)] + list(reversed(tv))[1:-1]
    fr3 = (Vector((0, A_BASE, 0)), Vector((1, 0, 0)), Vector((0, 0, 1)), Vector((0, 1, 0)))
    cream.P([tuple(fr3[0] + fr3[1] * u + fr3[2] * v) for u, v in step], (0, 1, 0))
    return {"Cream": cream, "Gold": gold, "Lattice": lat, "Red": red, "FloorLight": floor}


def pointed_arch(hw, zs, za, n=8):
    """Two-centred pointed arch line right -> left: (hw, zs) up to (0, za) down to (-hw, zs)."""
    hgt = za - zs
    c = (hgt * hgt - hw * hw) / (2 * hw)
    R = hw + c
    a1 = math.atan2(hgt, c)
    right = [(-c + R * math.cos(a1 * i / n), zs + R * math.sin(a1 * i / n)) for i in range(n + 1)]
    right[-1] = (0.0, za)
    return right + [(-x, z) for x, z in reversed(right[:-1])]


def tunnel_vault(hw, zs, za, n=8):
    """Segmental vault line right -> left: (hw, zs) up to (0, za) down to (-hw, zs)."""
    rise = za - zs
    R = (hw * hw + rise * rise) / (2 * rise)
    cz = za - R
    a0 = math.atan2(zs - cz, hw)
    pts = []
    for i in range(n + 1):
        t = a0 + (math.pi - 2 * a0) * i / n
        pts.append((R * math.cos(t), cz + R * math.sin(t)))
    pts[0], pts[-1], pts[n // 2] = (hw, zs), (-hw, zs), (0.0, za)
    return pts


def passage(mb_wall, mb_floor, mb_vault, y0, y1, hw, zs, za, floor_mat_mb):
    """A straight passage along +Y from y0 to y1 (local, facing +Y bearing): floor, side walls, vault."""
    floor_mat_mb.P([(-hw, y0, Z_FLOOR), (hw, y0, Z_FLOOR), (hw, y1, Z_FLOOR), (-hw, y1, Z_FLOOR)], (0, 0, 1))
    for s in (-1, 1):
        mb_wall.P([(s * hw, y0, Z_FLOOR), (s * hw, y1, Z_FLOOR), (s * hw, y1, zs), (s * hw, y0, zs)], (-s, 0, 0))
    v = tunnel_vault(hw, zs, za)
    for (xa, za_), (xb, zb) in zip(v[:-1], v[1:]):
        mx, mz = (xa + xb) / 2, (za_ + zb) / 2
        mb_vault.P([(xa, y0, za_), (xb, y0, zb), (xb, y1, zb), (xa, y1, za_)], (-mx, 0, -(mz - zs + 0.5)))
    return v


def spandrel(mb, y, hw, zs, za, ztop, facing):
    """The wall face above a vault up to ztop on the chord plane y (local), facing +-Y."""
    v = tunnel_vault(hw, zs, za)
    poly = v + [(-hw, ztop), (hw, ztop)]
    if ztop - za < 1e-4:
        # two small pieces either side of the apex
        poly_r = v[: len(v) // 2 + 1] + [(hw, ztop)]
        poly_l = v[len(v) // 2:] + [(-hw, ztop)]
        for p in (poly_r, poly_l):
            mb.P([(x, y, z) for x, z in p], (0, facing, 0))
        return
    mb.P([(x, y, z) for x, z in poly], (0, facing, 0))


# ------------------------------------------------------------------ inside
def inside():
    """Chamber (mural wall, dome, dark floor), its 4 doorways, the ambulatory ring, the 4 tunnels through the base."""
    mural, dome, fdark, flight, cream, white, wood, gold, lat = MB(), MB(), MB(), MB(), MB(), MB(), MB(), MB(), MB()
    qch = quad_angles(G_CH, 16)
    qcw = quad_angles(G_CHW, 16)
    qam = quad_angles(G_AMB, 16)
    # chamber floor (one convex polygon on the wall's angle samples; the doorway gaps are chords)
    ring = [a for q in qch for a in q]
    fdark.P([pol(R_CH, a, Z_FLOOR) for a in ring], (0, 0, 1))
    # mural wall
    for q in qch:
        ring_wall(mural, R_CH, q, Z_FLOOR, Z_CHWALL, inward=True)
    # dome: elliptical, every ring on the same angle samples (so its foot meets the wall top and the doorway chords)
    nz = 14
    rings = []
    for i in range(nz + 1):
        t = (math.pi / 2) * i / nz
        r, z = R_CH * math.cos(t), Z_CHWALL + (Z_DOME - Z_CHWALL) * math.sin(t)
        rings.append((r, z))
    for i in range(nz):
        (r0, z0), (r1, z1) = rings[i], rings[i + 1]
        for j in range(len(ring)):
            a, b = ring[j], ring[(j + 1) % len(ring)]
            if i == nz - 1:
                dome.P([pol(r0, a, z0), pol(r0, b, z0), (0, 0, z1)], (0, 0, -1))
            else:
                mx, my = math.cos(a) + math.cos(b), math.sin(a) + math.sin(b)  # (the gap chord at 360/0 deg wraps)
                dome.P([pol(r0, a, z0), pol(r0, b, z0), pol(r1, b, z1), pol(r1, a, z1)], (-mx, -my, -(z0 - Z_CHWALL) * 0.6))
    # ambulatory: floor + ceiling (4 sector polygons + 4 bridges in front of the doorways), walls
    for q_in, q_out in zip(qcw, qam):
        poly = [pol(R_CHW, a, Z_FLOOR) for a in q_in] + [pol(R_AMB, a, Z_FLOOR) for a in reversed(q_out)]
        flight.P(poly, (0, 0, 1))
        white.P([(x, y, Z_AMBC) for x, y, _ in poly], (0, 0, -1))
        ring_wall(cream, R_CHW, q_in, Z_FLOOR, Z_AMBC, inward=False)
        ring_wall(cream, R_AMB, q_out, Z_FLOOR, Z_AMBC, inward=True)
    yc_in, yc_out = R_CH * math.cos(G_CH), R_CHW * math.cos(G_CHW)
    ya = R_AMB * math.cos(G_AMB)
    loc = {}
    for b in CARD:
        th = math.radians(b)
        M = Matrix.Rotation(-th, 4, "Z")  # local +Y -> bearing b

        def T(mbx, pts_want):
            pass
        # bridge (floor + ceiling) between the doorway chord and the tunnel chord, in local coords then rotated
        local = MB()
        local.P([(-DW, yc_out, Z_FLOOR), (DW, yc_out, Z_FLOOR), (AW, ya, Z_FLOOR), (-AW, ya, Z_FLOOR)], (0, 0, 1))
        ceil = MB()
        ceil.P([(-DW, yc_out, Z_AMBC), (DW, yc_out, Z_AMBC), (AW, ya, Z_AMBC), (-AW, ya, Z_AMBC)], (0, 0, -1))
        # doorway passage through the chamber wall (cream walls, white vault), spandrels each side
        pw, pf, pv = MB(), MB(), MB()
        passage(pw, pf, pv, yc_in, yc_out, DW, D_SPRING, Z_AMBC, pf)
        sp_ch, sp_am = MB(), MB()
        spandrel(sp_ch, yc_in, DW, D_SPRING, Z_AMBC, Z_CHWALL, -1)
        spandrel(sp_am, yc_out, DW, D_SPRING, Z_AMBC, Z_AMBC, +1)
        # tunnel through the base
        tw, tf, tvlt = MB(), MB(), MB()
        passage(tw, tf, tvlt, ya, A_BASE, AW, TW_SPRING, Z_AMBC, tf)
        sp_t = MB()
        # (vault apex = ambulatory ceiling: only the two small spandrels at the ambulatory wall)
        spandrel(sp_t, ya, AW, TW_SPRING, Z_AMBC, Z_AMBC, -1)
        # inner door leaves (wood, open against the passage walls) and the gold lattice arch at the chamber side
        dl = MB()
        for s in (-1, 1):
            x0, x1 = (DW - 0.16, DW - 0.1) if s > 0 else (-DW + 0.1, -DW + 0.16)
            dl.box(x0, x1, yc_out - 1.45, yc_out - 0.05, Z_FLOOR, D_SPRING - 0.1, skip=("-z",))
        gl = MB()
        v = tunnel_vault(DW, D_SPRING, Z_AMBC)
        fr = (Vector((0, yc_in + 0.35, 0)), Vector((1, 0, 0)), Vector((0, 0, 1)), Vector((0, 1, 0)))
        gl.extrude([(DW, D_SPRING)] + v[1:-1] + [(-DW, D_SPRING)], fr, -0.04, 0.0)
        gl.extrude([(-DW, D_SPRING - 0.15), (DW, D_SPRING - 0.15), (DW, D_SPRING), (-DW, D_SPRING)], fr, -0.04, 0.0)
        for part, tgt in ((local, flight), (ceil, white), (pw, cream), (pf, flight), (pv, white), (sp_ch, mural),
                          (sp_am, cream), (tw, cream), (tf, flight), (tvlt, white), (sp_t, cream), (dl, wood), (gl, gold)):
            base_i = len(tgt.v)
            for p in part.v:
                q = M @ Vector(p)
                tgt.v.append((q.x, q.y, q.z))
            for f in part.f:
                tgt.f.append([base_i + i for i in f])
    return {"TexMural": mural, "TexDome": dome, "FloorDark": fdark, "FloorLight": flight, "Cream": cream, "White": white,
            "Wood": wood, "Gold": gold}


def noise(a, b, seed):
    s = math.sin(a * 3.1 + seed) * 0.5 + math.sin(a * 7.3 + b * 2.1 + seed * 2) * 0.3 + math.sin(a * 13.7 - b * 3.3 + seed * 3) * 0.2
    return s


TREE_ANG = [math.radians(45 + 90 * q + d) for q in range(4) for d in (-22.0, 22.0)]


def canopy():
    """One lumpy leaf band round the wall top and the dome foot (photo 17), hanging lower over each trunk."""
    mb = MB()
    n = 128
    prof = [(R_CH + 0.02, 4.75), (10.2, 4.85), (9.3, 5.2), (8.7, 5.9), (8.6, 7.0), (9.0, 8.1), (9.6, 8.9)]  # no fold
    # last point on the dome (r at z): z = 5.5 + 9.5 sin t
    zt = 9.4
    st = (zt - Z_CHWALL) / (Z_DOME - Z_CHWALL)
    prof.append((R_CH * math.sqrt(1 - st * st) - 0.02, zt))
    grid = []
    for j in range(n + 1):
        a = 2 * math.pi * j / n
        hang = max(math.exp(-((math.atan2(math.sin(a - ta), math.cos(a - ta))) / 0.16) ** 2) for ta in TREE_ANG)
        row = []
        for i, (r, z) in enumerate(prof):
            if 0 < i < len(prof) - 1:
                wgt = (0.0, 0.6, 1.0, 1.0, 1.0, 0.8, 0.5, 0.0)[i]  # smooth across the band (no folds)
                lump = 0.55 * math.sin(7 * a + 0.4 * i) + 0.35 * math.sin(13 * a + 1.7 + 0.3 * i) + 0.2 * math.sin(3 * a + 0.5)
                lz = 0.6 * math.sin(11 * a + 2.0) + 0.4 * math.sin(5 * a + 0.7 + 0.2 * i)
                r += 0.5 * wgt * lump
                z += 0.3 * wgt * lz
                if i in (1, 2):
                    z -= (0.7 if i == 1 else 0.9) * hang
                    r -= 0.4 * hang
            if i == 0:
                z -= 0.85 * hang  # the wall line drops with the hanging leaves, so the lip never folds back
            row.append(pol(r, a, z))
        grid.append(row)
    for j in range(n):
        for i in range(len(prof) - 1):
            p = [grid[j][i], grid[j + 1][i], grid[j + 1][i + 1], grid[j][i + 1]]
            for tri in ((p[0], p[1], p[2]), (p[0], p[2], p[3])):  # twisted quads: wind each triangle on its own
                c = sum((Vector(x) for x in tri), Vector()) / 3
                mb.P(list(tri), (-c.x, -c.y, 1.7 - c.z))  # face the floor-level viewer
    return mb


def trunk():
    """One relief tree: trunk with a root flare + two limbs, half sunk in the wall (built at bearing 0 = +Y)."""
    mb = MB()

    def tube(p0, p1, r0, r1, n=8, rings=4):
        p0, p1 = Vector(p0), Vector(p1)
        ax = (p1 - p0).normalized()
        u = ax.cross(Vector((0, 1, 0)))
        if u.length < 1e-3:
            u = Vector((1, 0, 0))
        u.normalize()
        w = ax.cross(u)
        R = []
        for k in range(rings + 1):
            f = k / rings
            c = p0.lerp(p1, f)
            r = r0 + (r1 - r0) * f
            R.append([c + (u * math.cos(2 * math.pi * i / n) + w * math.sin(2 * math.pi * i / n)) * r for i in range(n)])
        for k in range(rings):
            for i in range(n):
                q = [R[k][i], R[k][(i + 1) % n], R[k + 1][(i + 1) % n], R[k + 1][i]]
                c = sum(q, Vector()) / 4
                cc = p0.lerp(p1, (k + 0.5) / rings)
                mb.P([tuple(x) for x in q], tuple(c - cc))
    yw = R_CH - 0.35
    tube((0, yw + 0.1, Z_FLOOR), (0, yw, 2.0), 1.05, 0.55, rings=3)
    tube((0, yw, 2.0), (0, yw - 0.1, 4.6), 0.55, 0.42, rings=3)
    tube((0, yw, 3.0), (-1.6, yw - 0.5, 5.0), 0.3, 0.18, rings=3)
    tube((0, yw, 3.4), (1.4, yw - 0.6, 5.1), 0.28, 0.16, rings=3)
    return mb


def shrine():
    """Central relic shrine (photos 19/21): lotus basin (red petals), grating over a blue-tiled moat, a stepped white
    octagonal base with a gold band, the glass case with 8 seated gold Buddhas round a white core, the white bell with a
    niche and the gold spire."""
    lotus, grate, tile, white, gold, glass = MB(), MB(), MB(), MB(), MB(), MB()
    # lotus basin: 32 petals (radius bumps), 0.95 high
    n = 64
    for j in range(n):
        a, b = 2 * math.pi * j / n, 2 * math.pi * (j + 1) / n
        ra = 4.3 + 0.14 * abs(math.sin(16 * a))
        rb = 4.3 + 0.14 * abs(math.sin(16 * b))
        m = (a + b) / 2
        lotus.P([pol(ra, a, Z_FLOOR), pol(rb, b, Z_FLOOR), pol(rb, b, 1.55), pol(ra, a, 1.55)], (math.cos(m), math.sin(m), 0))
        lotus.P([pol(ra, a, 1.55), pol(rb, b, 1.55), pol(4.25, b, 1.6), pol(4.25, a, 1.6)], (math.cos(m), math.sin(m), 1))
        grate.P([pol(4.25, a, 1.6), pol(4.25, b, 1.6), pol(3.85, b, 1.6), pol(3.85, a, 1.6)], (0, 0, 1))
        white.P([pol(3.85, a, 1.6), pol(3.85, b, 1.6), pol(3.85, b, 1.25), pol(3.85, a, 1.25)], (-math.cos(m), -math.sin(m), 0))
        tile.P([pol(3.85, a, 1.25), pol(3.85, b, 1.25), pol(3.35, b, 1.25), pol(3.35, a, 1.25)], (0, 0, 1))
    oct_revolve(white, [(3.3 * math.cos(math.pi / 32) * C8 / C8, 1.25), (3.3, 1.9), (2.95, 1.9), (2.95, 2.4), (2.6, 2.4), (2.6, 2.9)])
    oct_revolve(gold, [(2.6, 2.9), (2.4, 2.9), (2.4, 3.15)])
    oct_revolve(white, [(2.4, 3.15), (2.4, 3.6), (1.25, 3.6), (1.25, 5.25)])
    glass_prof = [(2.35, 3.6), (2.35, 3.62), (1.75, 5.2), (1.25, 5.22)]
    oct_revolve(glass, glass_prof)
    white.revolve([(1.25 / C8, 5.25), (1.5, 5.3), (1.56, 5.9), (1.45, 6.5), (1.2, 6.9), (0.8, 7.25), (0.62, 7.4)], 24)
    g = [(0.62, 7.4), (0.66, 7.5)]
    z = 7.5
    for k in range(6):
        rk = 0.62 - 0.45 * k / 6
        g += [(rk + 0.05, z + 0.08), (0.62 - 0.45 * (k + 1) / 6, z + 0.28)]
        z += 0.28
    g += [(0.15, z), (0.05, z + 0.4), (0.0, z + 0.55)]
    gold.revolve(g, 16)
    return {"Lotus": lotus, "Grate": grate, "TileBlue": tile, "White": white, "Gold": gold, "Glass": glass}


def buddha():
    """Seated figure, 1.35 m (photo 21: 8 gold-robed Buddhas with white faces in the glass case). Faces +Y."""
    robe, face = MB(), MB()
    robe.revolve([(0.6, 0.0), (0.62, 0.12), (0.55, 0.3), (0.32, 0.36), (0.3, 0.6), (0.27, 0.85), (0.24, 0.93), (0.1, 0.98),
                  (0.0, 0.98)], 12, rmod=lambda i, j, t: (1.0 if i > 3 else (0.75 + 0.25 * abs(math.cos(t)))))
    face.revolve([(0.0, 0.97), (0.08, 0.97), (0.09, 1.04), (0.15, 1.1), (0.17, 1.2), (0.15, 1.3), (0.09, 1.36), (0.05, 1.42),
                  (0.0, 1.45)], 10)
    return {"Gold": robe, "White": face}


def chinthe():
    """Seated chinthe on a red plinth (photo 16), simple blocks; faces +Y. 3.3 m to the head."""
    w, g, r = MB(), MB(), MB()
    r.box(-0.75, 0.75, -1.3, 1.3, 0.0, 1.0, skip=("-z",))
    w.box(-0.55, 0.55, -1.1, 0.2, 1.0, 1.7, skip=("-z",))          # haunches
    w.P([(-0.5, 0.2, 1.0), (0.5, 0.2, 1.0), (0.45, 0.6, 2.6), (-0.45, 0.6, 2.6)], (0, 1, 0.3))  # chest (front)
    w.P([(0.5, 0.2, 1.0), (0.5, -0.4, 1.7), (0.45, 0.0, 2.6), (0.45, 0.6, 2.6)], (1, 0, 0))
    w.P([(-0.5, 0.2, 1.0), (-0.45, 0.6, 2.6), (-0.45, 0.0, 2.6), (-0.5, -0.4, 1.7)], (-1, 0, 0))
    w.P([(-0.5, -0.4, 1.7), (-0.45, 0.0, 2.6), (0.45, 0.0, 2.6), (0.5, -0.4, 1.7)], (0, -1, 0.3))
    w.box(-0.4, 0.4, 0.05, 0.95, 2.6, 3.3)                        # head
    g.box(-0.55, 0.55, -0.1, 0.05, 2.3, 3.5, skip=())              # gold mane plate behind the head
    w.box(0.18, 0.4, 0.75, 1.0, 1.0, 1.75, skip=("-z", "+z"))       # fore legs
    w.box(-0.4, -0.18, 0.75, 1.0, 1.0, 1.75, skip=("-z", "+z"))
    g.box(-0.42, 0.42, 0.95, 1.0, 2.85, 3.05, skip=("-y",))        # gold brow band
    return {"White": w, "Gold": g, "Red": r}


def case():
    """Glass donation case (photo 17): white frame base + glass top. 1.0 x 0.7 x 1.1 m."""
    w, gl = MB(), MB()
    w.box(-0.5, 0.5, -0.35, 0.35, Z_FLOOR, Z_FLOOR + 0.55, skip=("-z",))
    gl.box(-0.48, 0.48, -0.33, 0.33, Z_FLOOR + 0.55, Z_FLOOR + 1.1, skip=("-z",))
    return {"White": w, "Glass": gl}


def carpet():
    mb = MB()
    mb.box(-1.2, 1.2, -0.8, 0.8, Z_FLOOR, Z_FLOOR + 0.03, skip=("-z",))
    return {"Carpet": mb}


def gate_pavilion():
    """Gate pavilion at each plaza side (Esri: green-roofed, about 8 x 10 m), facing +Y: 6 cream pillars, 2-tier roof."""
    cream, roof = MB(), MB()
    for x in (-3.6, 0.0, 3.6):
        for y in (-4.3, 4.3):
            if x == 0.0:
                continue
            cream.box(x - 0.3, x + 0.3, y - 0.3, y + 0.3, Z_PLAZA, 4.0, skip=("-z", "+z"))
    cream.box(-4.2, 4.2, -4.9, 4.9, 4.0, 4.5, skip=())
    def hip(x0, y0, z0, z1, ridge):
        pts = [(-x0, -y0, z0), (x0, -y0, z0), (x0, y0, z0), (-x0, y0, z0)]
        top = [(0, -ridge, z1), (0, ridge, z1)]
        roof.P([pts[0], pts[1], top[0]], (0, -1, 1))
        roof.P([pts[1], pts[2], top[1], top[0]], (1, 0, 1))
        roof.P([pts[2], pts[3], top[1]], (0, 1, 1))
        roof.P([pts[3], pts[0], top[0], top[1]], (-1, 0, 1))
        roof.P(pts, (0, 0, -1))
    hip(4.8, 5.6, 4.5, 6.3, 2.6)
    return {"Cream": cream, "Roof": roof}


# ------------------------------------------------------------------ build
def to_mesh_uv(name, mb, mat, uvfn):
    """Like to_mesh but with a picture UV map: uvfn(co, face_centre) -> (u, v) in Blender's convention (v up)."""
    me = bpy.data.meshes.new(name)
    me.from_pydata(mb.v, [], mb.f)
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.triangulate(bm, faces=bm.faces[:], quad_method="BEAUTY", ngon_method="BEAUTY")
    uv = bm.loops.layers.uv.verify()
    for f in bm.faces:
        c = f.calc_center_median()
        for l in f.loops:
            l[uv].uv = uvfn(l.vert.co, c)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(get_mat(mat))
    return me


def ang_near(co, c):
    a = math.atan2(co.y, co.x)
    ac = math.atan2(c.y, c.x)
    while a - ac > math.pi:
        a -= 2 * math.pi
    while a - ac < -math.pi:
        a += 2 * math.pi
    if abs(co.x) < 1e-6 and abs(co.y) < 1e-6:
        a = ac
    return a


def uv_mural(co, c):
    a = ang_near(co, c)
    ac = math.atan2(c.y, c.x) % (2 * math.pi)
    q = int(ac // (math.pi / 2))
    a0 = q * math.pi / 2 + G_CH
    span = math.pi / 2 - 2 * G_CH
    # the doorway spandrels (chord planes) take the picture's strip next to them
    u = (a - a0) / span
    return (u, (co.z - Z_FLOOR) / (Z_CHWALL - Z_FLOOR))


def uv_dome(co, c):
    a = ang_near(co, c)
    r = math.hypot(co.x, co.y)
    t = math.atan2((co.z - Z_CHWALL) / (Z_DOME - Z_CHWALL), r / R_CH)
    return (a / (2 * math.pi), t / (math.pi / 2))


def uv_leaves(co, c):
    a = ang_near(co, c)
    return (a * 24 / (2 * math.pi), co.z / 2.2 + math.hypot(co.x, co.y) / 2.2)


UVF = {"TexMural": uv_mural, "TexDome": uv_dome, "TexLeaves": uv_leaves}


def build():
    coll = clear_coll()
    root = add_empty(coll, "MahaWizaya")

    def mk(nm, mb, mat):
        if mat in UVF:
            return to_mesh_uv(nm, mb, mat, UVF[mat])
        return to_mesh(nm, mb, mat)

    def part(label, meshes, parent=root):
        e = add_empty(coll, label)
        e.parent = parent
        for mat, mb in meshes.items():
            if not mb.f:
                continue
            nm = "%s_%s" % (label, mat)
            add_obj(coll, nm, mk(nm, mb, mat), e)
        return e

    def inst(label, meshes, places):
        """places [(bearing, (x, y, z), scale)] -> linked copies."""
        e = add_empty(coll, label)
        e.parent = root
        mes = {mat: mk("%s_%s" % (label, mat), mb, mat) for mat, mb in meshes.items() if mb.f}
        for k, (b, loc, s) in enumerate(places):
            for mat, me in mes.items():
                ob = add_obj(coll, "%s%02d_%s" % (label, k + 1, mat), me, e, b)
                ob.location = loc
                ob.scale = (s, s, s)
        return e

    part("Plaza", plaza())
    part("Base", base())
    part("Terraces", terraces())
    st, vane = stupa()
    part("Stupa", {"Gold": st["Gold"]})
    part("Vane", {"Gold": vane})
    part("Fan", {"Glass": fan_mesh()})
    zs = small_stupa()
    inst("StupaT1_", {"Gold": zs}, [(0.0, pol(24.6, math.radians(90 - 45 * k), T1), 6.5) for k in range(8)])
    inst("StupaT2_", {"Gold": zs}, [(0.0, pol(19.3 / math.cos(math.radians(11.25)) * math.cos(math.radians(11.25)), math.radians(11.25 + 22.5 * k), 9.2), 2.4) for k in range(16)])
    inst("StupaT3_", {"Gold": zs}, [(0.0, pol(15.9, math.radians(22.5 * k), 12.4), 1.8) for k in range(16)])
    inst("Porch", porch(), [(b, (0, 0, 0), 1.0) for b in CARD])
    # chinthe pairs: in front of the base, either side of each porch (photo 16), facing out
    pl = []
    for b in CARD:
        th = math.radians(b)
        n = Vector((math.sin(th), math.cos(th), 0))
        t = Vector((n.y, -n.x, 0))
        for s in (-1, 1):
            p = n * (A_BASE + 1.6) + t * (s * (PW + 2.4)) + Vector((0, 0, Z_PLAZA))
            pl.append((b, tuple(p), 1.0))
    inst("Chinthe", chinthe(), pl)
    inst("GatePavilion", gate_pavilion(), [(b, tuple(Vector((math.sin(math.radians(b)), math.cos(math.radians(b)), 0)) * (PLAZA - 4.9)), 1.0) for b in CARD])
    part("Inside", inside())
    part("Canopy", {"TexLeaves": canopy()})
    inst("Tree", {"Trunk": trunk()}, [(90 - math.degrees(a), (0, 0, 0), 1.0) for a in TREE_ANG])
    part("Shrine", shrine())
    # 8 Buddhas in the glass case, facing out at the 8 bearings
    inst("Buddha", buddha(), [(45 * k, tuple(Vector((math.sin(math.radians(45 * k)), math.cos(math.radians(45 * k)), 0)) * 1.75 + Vector((0, 0, 3.6))), 1.0) for k in range(8)])
    # donation cases in a ring (photo 17), clear of the 4 doorway axes; carpets on the floor
    cs = []
    for k in range(12):
        b = 15 + 30 * k
        if b % 90 in (0,):
            continue
        cs.append((b, tuple(Vector((math.sin(math.radians(b)), math.cos(math.radians(b)), 0)) * 6.3), 1.0))
    inst("Case", case(), cs)
    inst("Carpet", carpet(), [(45 + 90 * k + d, tuple(Vector((math.sin(math.radians(45 + 90 * k + d)), math.cos(math.radians(45 + 90 * k + d)), 0)) * 8.6), 1.0) for k in range(4) for d in (-14, 14)])
    return report()


def textures_into_blender():
    for mat, fn in TEXFILE.items():
        m = bpy.data.materials.get(mat)
        if m is None:
            continue
        img = bpy.data.images.load(os.path.join(TEX, fn), check_existing=True)
        bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        tn = m.node_tree.nodes.new("ShaderNodeTexImage")
        tn.image = img
        m.node_tree.links.new(tn.outputs["Color"], bsdf.inputs["Base Color"])


def render_views():
    """Preview pictures (Eevee, back faces culled like Roblox): outside like photo 01 and 16, inside like 17 and 20."""
    sc = bpy.context.scene
    try:
        sc.render.engine = "BLENDER_EEVEE"
    except TypeError:
        pass
    sc.render.resolution_x, sc.render.resolution_y = 1280, 800
    sc.view_settings.view_transform = "Standard"
    world = sc.world or bpy.data.worlds.new("W")
    sc.world = world
    world.use_nodes = True
    bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs[0].default_value = (0.35, 0.5, 0.75, 1)
    bg.inputs[1].default_value = 0.8
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sc.collection.objects.link(sun)
    sun.data.energy = 3.5
    sun.rotation_euler = (math.radians(35), 0, math.radians(30))
    lamp = bpy.data.objects.new("InLamp", bpy.data.lights.new("InLamp", "POINT"))
    sc.collection.objects.link(lamp)
    lamp.data.energy = 6000
    lamp.data.shadow_soft_size = 3
    lamp.location = (0, -4, 8)
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    sc.collection.objects.link(cam)
    sc.camera = cam
    views = {
        "render_outside_sw.png": ((-62, -70, 2.0), (0, 0, 22), 32),
        "render_outside_south_porch.png": ((0, -52, 1.7), (0, 0, 10), 28),
        "render_inside_shrine.png": ((0, -10.4, 1.7), (0, 0, 4.6), 16),
        "render_inside_dome.png": ((0.3, -0.3, 1.7), (0.3, -0.2, 20), 12),
        "render_aerial.png": ((0, -0.01, 140), (0, 0, 0), 40),
    }
    for fn, (pos, tgt, lens) in views.items():
        cam.location = pos
        d = Vector(tgt) - Vector(pos)
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        cam.data.lens = lens
        lamp.hide_render = not fn.startswith("render_inside")
        sc.render.filepath = os.path.join(OUTDIR, fn)
        bpy.ops.render.render(write_still=True)
        print("wrote", fn)


def export_scaled():
    """Kaba's export() scales the mesh data to studs but not the objects' locations: scale those too (the instanced
    small stupas, Buddhas, chinthe, cases, carpets, gate pavilions are placed by location)."""
    coll = bpy.data.collections[COLL]
    moved = [(o, o.location.copy()) for o in coll.objects if o.location.length > 1e-9]
    for o, l in moved:
        o.location = l * SPM
    try:
        export()
    finally:
        for o, l in moved:
            o.location = l


def write_meta(total):
    meta = {"studs_per_metre": SPM, "materials": {k: list(v[0]) for k, v in MATS.items()}, "textures": TEXFILE,
            "pivot": "stupa axis on the ground under the plaza (y 0); plaza top 0.3 m, inside floors 0.65 m",
            "axes": "glTF +Y up; Blender +Y (north) = glTF -Z", "tris": total}
    with open(GLB.replace(".glb", "_materials.json"), "w") as f:
        json.dump(meta, f, indent=1)


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else ["all"]
    mode = args[0] if args else "all"
    os.makedirs(OUTDIR, exist_ok=True)
    out, total = build()
    n_opp, n_same, same = check_overlaps(tol=0.02, fix=True)
    check_overlaps(tol=0.02, fix=False)
    out, total = report()
    if mode in ("build", "all"):
        export_scaled()
        write_meta(total)
    if mode in ("render", "all"):
        textures_into_blender()
        render_views()
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUTDIR, "maha_wizaya.blend"))
