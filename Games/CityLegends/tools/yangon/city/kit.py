"""kit.py: the 1:1 Yangon building kit, pilot (rescale step 2, 2026-11-16; owner: "Everything at player scale").

Six archetypes from the reference pack (vault note '2026-11-16 Research - Yangon building kit references'), modelled in
METRES and written at S studs a metre (3: the cars' and players' scale). Every number below is a real size from that note.
Faces are wound like geom3d (visible from outside). Groups use landmark_glb3d.GROUPS (the K* kit groups; their colours
come from look_calib.KIT_SPEC: python look_calib.py --kit).

Second pass (2026-11-16, build/landmarks/refs/kit/kit_critique.md, top 10 fixes):
 1. per-type weighted wall palettes, 55-85% neutral (white, grey, stained); pink / green only on corner landmark plots
 2. dark colours keep their hue (look_calib), shutters brown / green / blue / orange-teak, one colour a plot
 3. weathering at real strength: streaks up to a storey over 60-80% of the width, a per-building age, a see-through
    grime overlay darkest at the top storey and parapet, a dark base band, grey walk-up slab edges
 4. materials: walls / wood / rust / cloth try Concrete / WoodPlanks / CorrodedMetal / Fabric (SmoothPlastic where those
    can't reach the colour: look_calib.pick)
 5. laundry on ~30% of balconies (small, pale, behind the rail), shutters closed or flat with louvre lines
 6. street_wires(): poles every 30-40 m and sagging wire bundles; a blue drainpipe a plot; weeds on cornices
 7. colonial depth: windows 0.35 m into the wall with reveals, pilasters, string courses, balcony brackets, dark
    fanlights, balustrade parapets, a corner pediment
 8. ground floors: an awning per shop (or none), signs as plain colour areas on white / yellow grounds (real words
    come later from the atlas), township fascia + pillar sign + lightbox, goods on the pavement
 9. walk-up patchwork: per-bay paint, black / rust / white cages, shade nets, tarps, blue awnings over ~60% of bays,
    AC units on every type, dark mesh dishes
10. condo: white punched-window tower, a blue stripe, balconies on some bays, a crown; villa: trees over a stained
    wall with razor wire, a near-black gate, a muted brick-red roof

    python kit.py [out_tris.json]     -> triangles by group for preview3d_blend.py (all six side by side on a street,
                                         with a car and a person for scale)
Each archetype is a function (x0, y0) -> its footprint (W, D, H) in metres, front on y0 facing -y (the street).
"""
import json
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from geom3d import Geo  # noqa: E402

S = 3.0  # studs per metre
SEED = 245  # chosen so the pilot shows the measured mix (grey + tan + dark-stained colonial plots, blue-white blocks)
g = Geo()
R = random.Random(SEED)
LOG = []  # (type, wall group, age) per building / plot, for the pilot report


def reset(seed=SEED):
    """A fresh geometry and random stream (the pilot scene is built from one seed)."""
    global g, R
    g = Geo()
    R = random.Random(seed)
    del LOG[:]

# offsets in front of a wall (metres; >= 0.05 studs apart so nothing flickers)
OFF_GRIME, OFF_STAIN, OFF_STREAK = 0.022, 0.040, 0.058
REVEAL = 0.35  # windows set this deep into the wall


def m(v):
    return v * S


def M(p):
    return (m(p[0]), m(p[1]), m(p[2]))


def wpick(table):
    """Weighted pick from {item: weight}."""
    keys = list(table)
    return R.choices(keys, [table[k] for k in keys])[0]


# --------------------------------------------------------------------------------------------- primitives (metres)
def box(grp, x, y, z, sx, sy, sz, faces=("+x", "-x", "+y", "-y", "top", "bottom")):
    """An axis box in metres: (x, y, z) = min corner."""
    g.box(grp, m(x + sx / 2), m(y + sy / 2), m(z), m(sx), m(sy), m(sz), 0.0, faces=faces)


def front_quad(grp, x0, x1, z0, z1, y):
    """A rectangle on the plane y (metres), facing -y (the street)."""
    g.quad(grp, (m(x0), m(y), m(z0)), (m(x1), m(y), m(z0)), (m(x1), m(y), m(z1)), (m(x0), m(y), m(z1)))


def _newell(pts):
    n = [0.0, 0.0, 0.0]
    for i in range(len(pts)):
        a, b = pts[i], pts[(i + 1) % len(pts)]
        n[0] += (a[1] - b[1]) * (a[2] + b[2])
        n[1] += (a[2] - b[2]) * (a[0] + b[0])
        n[2] += (a[0] - b[0]) * (a[1] + b[1])
    return n


def face(grp, pts, n):
    """A convex polygon (metres) facing the direction n."""
    nn = _newell(pts)
    if nn[0] * n[0] + nn[1] * n[1] + nn[2] * n[2] < 0:
        pts = pts[::-1]
    for i in range(1, len(pts) - 1):
        g.tri(grp, M(pts[0]), M(pts[i]), M(pts[i + 1]))


def cyl(grp, cx, cy, z0, h, r, n=10):
    pts = [(m(cx + r * math.cos(2 * math.pi * k / n)), m(cy + r * math.sin(2 * math.pi * k / n))) for k in range(n)]
    g.ring(grp, pts, m(z0), m(z0 + h))
    g.cap(grp, pts, m(z0 + h))


def bar(grp, a, b, w=0.04):
    g.tube(grp, tuple(m(v) for v in a), tuple(m(v) for v in b), m(w))


def blob(grp, cx, cy, cz, rx, ry, rz, n=7):
    """A lumpy low-poly ellipsoid (tree crowns): two rings and two poles."""
    rings = []
    for zi, (k, rad) in enumerate(((-0.45, 0.8), (0.35, 0.9))):
        ring = []
        for i in range(n):
            a = 2 * math.pi * (i + 0.5 * zi) / n
            j = R.uniform(0.85, 1.15)
            ring.append((cx + rx * rad * j * math.cos(a), cy + ry * rad * j * math.sin(a), cz + rz * k))
        rings.append(ring)
    bot, top = (cx, cy, cz - rz), (cx, cy, cz + rz * R.uniform(0.9, 1.1))
    c = (cx, cy, cz)

    def tri(a, b, d):
        mid = ((a[0] + b[0] + d[0]) / 3 - c[0], (a[1] + b[1] + d[1]) / 3 - c[1], (a[2] + b[2] + d[2]) / 3 - c[2])
        face(grp, [a, b, d], mid)
    lo, hi = rings
    for i in range(n):
        j = (i + 1) % n
        tri(bot, lo[i], lo[j])
        tri(lo[i], lo[j], hi[i])
        tri(lo[j], hi[j], hi[i])
        tri(hi[i], hi[j], top)


def rect_minus(x0, x1, z0, z1, holes):
    """The rectangle [x0,x1] x [z0,z1] minus the hole rectangles (x0, x1, z0, z1): a list of rectangles."""
    hs = [h for h in holes if h[0] < x1 and h[1] > x0 and h[2] < z1 and h[3] > z0]
    xs = sorted(set([x0, x1] + [min(max(h[i], x0), x1) for h in hs for i in (0, 1)]))
    cols = []
    for a, b in zip(xs, xs[1:]):
        if b - a < 1e-6:
            continue
        mid = (a + b) / 2
        cov = sorted((max(h[2], z0), min(h[3], z1)) for h in hs if h[0] < mid < h[1])
        z = z0
        for c0, c1 in cov:
            if c0 > z + 1e-6:
                cols.append((a, b, z, c0))
            z = max(z, c1)
        if z < z1 - 1e-6:
            cols.append((a, b, z, z1))
    cols.sort(key=lambda r: (r[2], r[3], r[0]))
    out = []
    for r in cols:
        if out and abs(out[-1][1] - r[0]) < 1e-6 and abs(out[-1][2] - r[2]) < 1e-6 and abs(out[-1][3] - r[3]) < 1e-6:
            out[-1] = (out[-1][0], r[1], r[2], r[3])
        else:
            out.append(r)
    return out


def facade(grp, x0, x1, z0, z1, y, holes):
    """A front wall with holes (openings), facing -y."""
    for (a, b, c, d) in rect_minus(x0, x1, z0, z1, holes):
        front_quad(grp, a, b, c, d, y)


def opening(holes, x, z, w, h, y, reveal_grp, depth=REVEAL, glass="KGL", lit=True):
    """A hole in the wall, its four reveal faces and the glass (or interior) at the back."""
    holes.append((x, x + w, z, z + h))
    yb = y + depth
    face(reveal_grp, [(x, y, z), (x, yb, z), (x, yb, z + h), (x, y, z + h)], (1, 0, 0))
    face(reveal_grp, [(x + w, y, z), (x + w, yb, z), (x + w, yb, z + h), (x + w, y, z + h)], (-1, 0, 0))
    face(reveal_grp, [(x, y, z + h), (x + w, y, z + h), (x + w, yb, z + h), (x, yb, z + h)], (0, 0, -1))
    face(reveal_grp, [(x, y, z), (x + w, y, z), (x + w, yb, z), (x, yb, z)], (0, 0, 1))
    if glass:
        front_quad(glass, x, x + w, z, z + h, yb)
        if lit and R.random() < LIT:
            front_quad(R.choice(["NWH", "NWH", "NWA", "NWY", "NWC"]), x + 0.03, x + w - 0.03, z + 0.03, z + h - 0.03,
                       yb - 0.03)


LIT = 0.22  # share of windows lit at night (tag FacadeNight panes; the vault's night measurements: 15-25%)


# ------------------------------------------------------------------------------------------------- weathering
def grime_group(age):
    return "KGM1" if age < 0.4 else ("KGM2" if age < 0.7 else "KGM3")


def stains(x0, x1, z, y, storey=3.0, age=0.5, holes=()):
    """Rain streaks hanging under a ledge: soft wide stains over 60-80% of the width, up to a storey long (longer on
    older buildings), with a few dark narrow ones in each; clipped round the openings."""
    x = x0 + R.uniform(0.0, 0.3)
    while x < x1 - 0.15:
        w = R.uniform(0.4, 1.6)
        L = min(storey * 1.05, R.uniform(0.3, 1.0) * storey * (0.5 + age))
        xa, xb = x, min(x1, x + w)
        # tapering down: full width for the top third, then narrower bands drifting to one side
        za, wa, xs0 = z, xb - xa, xa
        for share, frac in ((0.35, 1.0), (0.35, R.uniform(0.55, 0.8)), (0.3, R.uniform(0.25, 0.45))):
            ww = (xb - xa) * frac
            xs0 = min(max(xa, xs0 + R.uniform(-0.1, 0.1) * wa), xb - ww)
            for (a, b, c, d) in rect_minus(xs0, xs0 + ww, za - L * share, za, holes):
                front_quad("KSU", a, b, c, d, y - OFF_STAIN)
            za -= L * share
        for _ in range(R.randint(1, 3)):
            xs = xa + R.uniform(0.0, max(0.05, (xb - xa) - 0.08))
            L2 = min(storey * 1.1, L * R.uniform(0.6, 1.3))
            for (a, b, c, d) in rect_minus(xs, min(xb, xs + R.uniform(0.03, 0.12)), z - L2, z, holes):
                front_quad("KST", a, b, c, d, y - OFF_STREAK)
        x += w + R.uniform(0.0, 0.6)


def grime(x0, x1, z_top_storey, z_top, y, age, holes=(), z_base=0.0, whole_from=None):
    """The see-through grime layer: darkest over the top storey and parapet, a lighter one over the rest on older
    buildings, and a dark splash band at the base."""
    for (a, b, c, d) in rect_minus(x0, x1, z_top_storey, z_top, holes):
        front_quad(grime_group(age), a, b, c, d, y - OFF_GRIME)
    if whole_from is not None and age > 0.45:
        for (a, b, c, d) in rect_minus(x0, x1, whole_from, z_top_storey, holes):
            front_quad(grime_group(age - 0.3), a, b, c, d, y - OFF_GRIME)
    for (a, b, c, d) in rect_minus(x0, x1, z_base, z_base + 0.6, holes):
        front_quad("KGB", a, b, c, d, y - OFF_GRIME)


def drip(x, z, y, L):
    front_quad("KST", x, x + R.uniform(0.05, 0.12), z - L, z, y - OFF_STREAK)


# ------------------------------------------------------------------------------------------------- clutter
def ac_unit(x, z, y, drip_len=None):
    """An air-con box on two brackets, with its drip streak down the wall."""
    box("KAC", x, y - 0.35, z, 0.8, 0.3, 0.55, faces=("-y", "+x", "-x", "top", "bottom"))
    front_quad("KGR", x + 0.42, x + 0.74, z + 0.1, z + 0.42, y - 0.352)  # the fan grille (dark)
    for bx in (x + 0.1, x + 0.62):
        box("KGR", bx, y - 0.38, z - 0.04, 0.05, 0.38, 0.04, faces=("-y", "top", "bottom"))
    drip(x + 0.3, z, y, drip_len if drip_len is not None else R.uniform(0.8, 2.0))


def laundry(x0, x1, z, y, rail_y=None, rail_z=None):
    """Clothes on a line behind the rail on ~30% of balconies: small, mostly pale, jittered; towels over the rail."""
    if R.random() > 0.3:
        return
    x = x0 + R.uniform(0, (x1 - x0) * 0.4)
    while x < x1 - 0.25:
        w = R.uniform(0.2, 0.45)
        grp = R.choice(["KL4", "KL4", "KL5", "KL6"]) if R.random() < 0.6 else R.choice(["KL1", "KL2", "KL3"])
        top = z + R.uniform(-0.25, 0.25)
        front_quad(grp, x, x + w, top - R.uniform(0.3, 0.7), top, y)
        x += w + R.uniform(0.08, 0.4)
    if rail_y is not None and R.random() < 0.6:
        tx = R.uniform(x0, x1 - 0.4)
        front_quad(R.choice(["KL4", "KL5", "KL6", "KL1"]), tx, tx + 0.4, rail_z - 0.3, rail_z + 0.02, rail_y - 0.03)


def drainpipe(x, z0, z1, y):
    bar("KPP", (x, y - 0.12, z0), (x, y - 0.12, z1), 0.1)
    bar("KPP", (x, y - 0.12, z1), (x, y + 0.02, z1 + 0.25), 0.1)


def weeds(x0, x1, z, y, n=None):
    """Plant tufts growing out of a ledge."""
    for _ in range(n if n is not None else R.randint(2, 3)):
        s = R.uniform(0.3, 0.6)
        x = R.uniform(x0, x1 - s)
        box("KPL", x, y - 0.2, z, s, 0.2, s * R.uniform(0.6, 1.0), faces=("-y", "+x", "-x", "top"))


def small_dish(x, z, y):
    bar("KCG", (x, y, z), (x, y - 0.25, z), 0.04)
    pts = [(x + 0.3 * math.cos(2 * math.pi * k / 8), y - 0.25, z + 0.3 * math.sin(2 * math.pi * k / 8)) for k in range(8)]
    c = (x, y - 0.4, z)
    for k in range(8):
        face("KDS", [c, pts[k], pts[(k + 1) % 8]], (0, -1, 0))
        face("KDS", [c, pts[k], pts[(k + 1) % 8]], (0, 1, 0))


def mesh_dish(cx, cy, z, d):
    """A big dark mesh satellite dish on a post: a rim ring, spokes and a feed arm (KGR lattice)."""
    r = d / 2
    tilt = 0.35
    bar("KCG", (cx, cy, z), (cx, cy, z + 1.0 + r * 0.5), 0.06)
    c = (cx, cy - 0.25, z + 1.0 + r)
    ring = []
    for k in range(10):
        a = 2 * math.pi * k / 10
        ring.append((c[0] + r * math.cos(a), c[1] + r * math.sin(a) * math.sin(tilt) * 0.3, c[2] + r * math.sin(a) * math.cos(tilt)))
    hub = (c[0], c[1] + 0.35, c[2])
    for k in range(10):
        bar("KGR", ring[k], ring[(k + 1) % 10], 0.04)
        if k % 2 == 0:
            bar("KGR", hub, ring[k], 0.025)
    bar("KGR", hub, (c[0], c[1] - r * 0.7, c[2] - 0.1), 0.03)


def awning(x0, x1, z, y, depth, kind):
    """A shop or window awning: blue plastic / red canvas (with a valance) / rusty corrugated sheet, sloping down."""
    if kind is None:
        return
    drop = depth * 0.5
    face(kind, [(x0, y, z), (x1, y, z), (x1, y - depth, z - drop), (x0, y - depth, z - drop)], (0, -0.3, 1))
    if kind in ("KAR", "KAW"):
        front_quad(kind, x0, x1, z - drop - 0.22, z - drop, y - depth)
    else:
        for k in range(int((x1 - x0) / 0.35)):  # corrugation lines
            xx = x0 + 0.17 + k * 0.35
            face("KST", [(xx, y - 0.02, z + 0.012), (xx + 0.06, y - 0.02, z + 0.012),
                         (xx + 0.06, y - depth, z - drop + 0.012), (xx, y - depth, z - drop + 0.012)], (0, -0.3, 1))


def sign(x, z, w, h, y, ground=None, stripe=None):
    """A plain signboard: a white or yellow ground, maybe a coloured band. No fake text (real words come later)."""
    ground = ground or R.choice(["KSW", "KSW", "KSW", "KS2"])
    box(ground, x, y - 0.08, z, w, 0.08, h, faces=("-y", "+x", "-x", "top", "bottom"))
    stripe = stripe if stripe is not None else (R.choice(["KS1", "KS1", "KS3", "KS4"]) if R.random() < 0.6 else None)
    if stripe:
        hb = h * R.uniform(0.18, 0.3)
        if R.random() < 0.5:
            front_quad(stripe, x, x + w, z, z + hb, y - 0.085)
        else:
            front_quad(stripe, x, x + w * R.uniform(0.2, 0.3), z, z + h, y - 0.085)


def goods(x0, x1, y, depth=0.8):
    """Stock spilling out onto the pavement: crates, sacks, racks of packets."""
    x = x0
    while x < x1 - 0.4:
        w = R.uniform(0.4, 0.8)
        kind = R.random()
        if kind < 0.4:
            box("KWD", x, y - depth, 0.15, w, R.uniform(0.4, depth), R.uniform(0.3, 0.6))
        elif kind < 0.7:
            box(R.choice(["PRC", "PRC", "PRA", "PRF"]), x, y - depth * 0.7, 0.15, w, 0.5, R.uniform(0.3, 0.5))
        else:
            box("KCG", x, y - 0.5, 0.15, w, 0.4, 1.4, faces=("-y", "+x", "-x", "top"))
            for k in range(3):
                front_quad(R.choice(["PRA", "PRB", "PRE", "PRF", "KL4"]), x + 0.05, x + w - 0.05, 0.35 + k * 0.42,
                           0.65 + k * 0.42, y - 0.505)
        x += w + R.uniform(0.05, 0.3)


def shop_bay(x, w, h, y, wall, holes, state=None, spill=0.4):
    """A ground-floor shop opening: open (dark inside, shelves, goods out front), roller shutter, or glazed."""
    state = state or R.choices(["open", "shutter", "glass"], [0.4, 0.4, 0.2])[0]
    if state == "open":
        opening(holes, x, 0.0, w, h, y, "KSI", depth=2.6, glass="KSI", lit=False)
        front_quad("KSW", x + 0.2, x + w - 0.2, h - 0.12, h - 0.06, y + 2.55)  # a fluorescent tube
        for k in range(3):  # shelves of mostly muted stock, small items
            xx = x + 0.15
            while xx < x + w - 0.35:
                iw = R.uniform(0.2, 0.45)
                box(R.choice(["PRC", "PRC", "KWD", "KL4", "KL6", "PRD", "PRD", "PRA"]), xx, y + 2.1, 0.45 + k * 0.7, iw, 0.4,
                    R.uniform(0.2, 0.4), faces=("-y", "top"))
                xx += iw + R.uniform(0.03, 0.15)
        if R.random() < spill:
            goods(x, x + w, y, R.uniform(0.6, 0.9))
    elif state == "shutter":
        opening(holes, x, 0.0, w, h, y, wall, depth=0.25, glass="KRS", lit=False)
        zz = 0.15
        while zz < h - 0.1:
            front_quad("KST", x, x + w, zz, zz + 0.03, y + 0.24)
            zz += 0.16
    else:
        opening(holes, x, 0.0, w, h, y, wall, depth=0.3, glass="KGL", lit=False)
        front_quad("KFR", x + w / 2 - 0.04, x + w / 2 + 0.04, 0.0, h, y + 0.28)
        front_quad("KFR", x, x + w, 2.2, 2.28, y + 0.28)
    return state


# ------------------------------------------------------------------------------------------------- windows
def louvres(x0, x1, z0, z1, y, step=0.09):
    zz = z0 + step * 0.6
    while zz < z1 - 0.03:
        front_quad("KST", x0, x1, zz, zz + 0.025, y)
        zz += step


def shutters(x, z, w, h, y, colour, state):
    """Teak louvred shutters: closed in the window (y + 0.10), open flat on the wall, or ajar (<= 0.5 rad)."""
    if state == "closed":
        front_quad(colour, x, x + w, z, z + h, y + 0.10)
        louvres(x + 0.05, x + w / 2 - 0.04, z + 0.08, z + h - 0.08, y + 0.095)
        louvres(x + w / 2 + 0.04, x + w - 0.05, z + 0.08, z + h - 0.08, y + 0.095)
        front_quad("KST", x + w / 2 - 0.02, x + w / 2 + 0.02, z, z + h, y + 0.094)
        return
    for s, side in ((-1, x), (1, x + w)):
        if state == "flat":  # folded back flat on the wall beside the window
            a, b = (side, y - 0.03), (side + s * w / 2, y - 0.03 - 0.02 * R.random())
        else:  # ajar: turned out 0.15-0.5 rad from shut
            ang = R.uniform(0.15, 0.5)
            a, b = (side, y), (side - s * math.cos(ang) * w / 2, y - math.sin(ang) * w / 2)
        q = [(a[0], a[1], z), (b[0], b[1], z), (b[0], b[1], z + h), (a[0], a[1], z + h)]
        face(colour, q, (0, -1, 0))
        face(colour, q, (0, 1, 0))
        if state == "flat":
            zz = z + 0.1
            while zz < z + h - 0.08:
                lo, hi = min(a[0], b[0]) + 0.04, max(a[0], b[0]) - 0.04
                front_quad("KST", lo, hi, zz, zz + 0.025, min(a[1], b[1]) - 0.01)
                zz += 0.12


def window(x, z, w, h, y, holes, reveal_grp, grille=True, awning_kind=None):
    """A plain punched window 0.35 m into the wall: reveals, glass, a frame cross, an iron grille, maybe an awning."""
    opening(holes, x, z, w, h, y, reveal_grp)
    front_quad("KFR", x + w / 2 - 0.03, x + w / 2 + 0.03, z, z + h, y + REVEAL - 0.02)
    front_quad("KFR", x, x + w, z + h * 0.62, z + h * 0.62 + 0.05, y + REVEAL - 0.02)
    box("KW0", x - 0.05, y - 0.06, z - 0.08, w + 0.1, 0.12, 0.08, faces=("-y", "top", "+x", "-x"))  # sill
    if grille:
        n = max(2, int(w / 0.12))
        for k in range(1, n):
            front_quad("KGR", x + w * k / n - 0.012, x + w * k / n + 0.012, z, z + h, y + 0.02)
        for k in (0.33, 0.66):
            front_quad("KGR", x, x + w, z + h * k - 0.012, z + h * k + 0.012, y + 0.02)
    if awning_kind:
        awning(x - 0.15, x + w + 0.15, z + h + 0.45, y, 0.9, awning_kind)


def arch_window(x, z, w, h, y, holes, wall, shutter_col, shutter_state):
    """A colonial arched window or French door: recessed 0.35 m, reveals, a dark glass fanlight with radial bars and a
    moulding ring in the arch, teak shutters below it."""
    r = w / 2
    cx, zc = x + r, z + h
    yb = y + REVEAL
    opening(holes, x, z, w, h + r, y, wall, glass=None)
    # the lower part: glass + shutters
    front_quad("KGL", x, x + w, z, z + h, yb)
    if R.random() < LIT:
        front_quad(R.choice(["NWH", "NWA", "NWY"]), x + 0.03, x + w - 0.03, z + 0.03, z + h - 0.03, yb - 0.03)
    # the fanlight: dark glass half-disc at the back, radial bars, the spandrels filled with wall in the front plane
    arc = [(cx + r * math.cos(math.pi * t / 8), zc + r * math.sin(math.pi * t / 8)) for t in range(9)]
    for t in range(8):
        face("KGL", [(cx, yb, zc), (arc[t][0], yb, arc[t][1]), (arc[t + 1][0], yb, arc[t + 1][1])], (0, -1, 0))
    for t in (1, 2, 4, 6, 7):
        bar("KGR", (cx, yb - 0.03, zc), (arc[t][0], yb - 0.03, arc[t][1]), 0.03)
    bar("KGR", (x, yb - 0.03, zc), (x + w, yb - 0.03, zc), 0.04)
    # the hole's top corners (outside the arc) are wall again: fans from each corner
    for corner, ts in (((x + w, zc + r), range(0, 4)), ((x, zc + r), range(4, 8))):
        for t in ts:
            face(wall, [(corner[0], y, corner[1]), (arc[t][0], y, arc[t][1]), (arc[t + 1][0], y, arc[t + 1][1])], (0, -1, 0))
    # arch reveal (the soffit, facing in) and the side reveals were made by opening(); the soffit replaces the top one
    for t in range(8):
        a, b = arc[t], arc[t + 1]
        nx, nz = -(a[0] + b[0]) / 2 + cx, -(a[1] + b[1]) / 2 + zc
        face(wall, [(a[0], y, a[1]), (b[0], y, b[1]), (b[0], yb, b[1]), (a[0], yb, a[1])], (nx, 0, nz))
    # moulding ring
    for t in range(8):
        a, b = arc[t], arc[t + 1]
        k = (r + 0.08) / r
        bar("KW0", (cx + (a[0] - cx) * k, y - 0.05, zc + (a[1] - zc) * k), (cx + (b[0] - cx) * k, y - 0.05, zc + (b[1] - zc) * k), 0.12)
    box("KW0", cx - 0.12, y - 0.1, zc + r - 0.05, 0.24, 0.1, 0.3, faces=("-y", "+x", "-x", "top"))  # keystone
    shutters(x, z, w, h, y, shutter_col, shutter_state)


def cage(x, z, y, w, h, depth, colour):
    """A steel balcony cage bolted onto the front (walk-ups): a slab, a roof, a dense grid (verticals every 0.10 m,
    horizontals every 0.3 m) on three sides, in black, rust or white."""
    box("KCO", x, y - depth, z, w, depth, 0.12, faces=("-y", "+x", "-x", "top", "bottom"))
    box("KCO", x, y - depth, z + h - 0.1, w, depth, 0.08, faces=("-y", "+x", "-x", "top", "bottom"))
    yf = y - depth - 0.01
    n = max(3, int(w / 0.10))
    for k in range(n + 1):
        xx = x + w * k / n
        front_quad(colour, xx - 0.012, xx + 0.012, z + 0.12, z + h - 0.1, yf)
    nz = max(2, int((h - 0.22) / 0.3))
    for k in range(nz + 1):
        zz = z + 0.12 + (h - 0.22) * k / nz
        front_quad(colour, x, x + w, zz - 0.015, zz + 0.015, yf)
        for sx, nrm in ((x, -1), (x + w, 1)):
            face(colour, [(sx, y - depth, zz - 0.015), (sx, y, zz - 0.015), (sx, y, zz + 0.015), (sx, y - depth, zz + 0.015)],
                 (nrm, 0, 0))
    for sx, nrm in ((x, -1), (x + w, 1)):
        nd = max(2, int(depth / 0.12))
        for k in range(nd + 1):
            yy = y - depth + depth * k / nd
            face(colour, [(sx, yy - 0.012, z + 0.12), (sx, yy + 0.012, z + 0.12), (sx, yy + 0.012, z + h - 0.1),
                          (sx, yy - 0.012, z + h - 0.1)], (nrm, 0, 0))


def roof_clutter(x0, y0, w, d, z, n_tanks=2, dishes=0, shed=False):
    for k in range(n_tanks):
        cx, cy = x0 + 1.0 + k * 1.6, y0 + d - 1.5
        bar("KCG", (cx - 0.5, cy, z), (cx - 0.5, cy, z + 0.8), 0.06)
        bar("KCG", (cx + 0.5, cy, z), (cx + 0.5, cy, z + 0.8), 0.06)
        cyl("KTK", cx, cy, z + 0.8, 1.2, 0.6)
    for k in range(dishes):
        mesh_dish(x0 + w - 1.6 - k * 2.6, y0 + 2.0 + k * 1.5, z, R.uniform(1.5, 2.4))
    if dishes:
        bar("KCG", (x0 + 1.5, y0 + 3.0, z), (x0 + 1.5, y0 + 3.0, z + 3.5), 0.04)  # an aerial
        for k in range(4):
            bar("KCG", (x0 + 1.0, y0 + 3.0, z + 2.6 + k * 0.25), (x0 + 2.0, y0 + 3.0, z + 2.6 + k * 0.25), 0.03)
    if shed:
        sx, sy = x0 + w * 0.5, y0 + d * 0.45
        box("KWG", sx, sy, z, 3.0, 2.6, 2.2, faces=("+x", "-x", "+y", "-y"))
        face(R.choice(["KRF", "KRG"]), [(sx - 0.3, sy - 0.4, z + 2.5), (sx + 3.3, sy - 0.4, z + 2.5),
                                         (sx + 3.3, sy + 3.0, z + 2.1), (sx - 0.3, sy + 3.0, z + 2.1)], (0, 0, 1))


# ------------------------------------------------------------------------------------------------- the archetypes
# per-type weighted wall palettes (kit_critique section 1 / fix 1): neutral = KW6 white, KW4 blue-white, KWG grey
COLONIAL_WALLS = {"KW6": 0.33, "KWG": 0.22, "KW3": 0.25, "KW1": 0.10, "KW2": 0.10}
CORNER_WALLS = {"KW5": 0.5, "KW7": 0.5}  # landmark corner plots only
WALKUP_WALLS = {"KW4": 0.35, "KWG": 0.25, "KW6": 0.15, "KW1": 0.12, "KW2": 0.08, "KW3": 0.05}
TOWNSHIP_WALLS = {"KW4": 0.35, "KWB": 0.20, "KW6": 0.20, "KWG": 0.15, "KW1": 0.10}
CONDO_WALLS = {"KW6": 0.6, "KWG": 0.4}
SHUTTERS = {"KSH": 0.5, "KSH2": 0.25, "KSH3": 0.1, "KSH4": 0.15}
CAGES = {"KCB": 0.5, "KCU": 0.3, "KCW": 0.2}
AWNINGS = {"KAW": 0.35, "KAR": 0.2, "KRF": 0.15, None: 0.3}


def walkup(x0, y0, bays=None, floors=6, wall=None, age=None):
    """Type 2: a 1960s-90s concrete walk-up. Bay 3.0, GF 3.9 (shops), upper 3.0, cages and balconies, tanks on top.
    Each flat paints and encloses its own bay; blue corrugated awnings over most of them."""
    BAY, GF, FH, D = 3.0, 3.9, 3.0, 20.0
    bays = bays or R.randint(4, 8)
    wall = wall or wpick(WALKUP_WALLS)
    age = R.uniform(0.45, 0.95) if age is None else age
    W = bays * BAY
    H = GF + FH * (floors - 1)
    LOG.append(("walkup", wall, round(age, 2)))
    holes = []
    box(wall, x0, y0, 0, W, D, H, faces=("+x", "-x", "+y", "top"))
    # parapet
    box("KWG", x0 - 0.1, y0 - 0.1, H, W + 0.2, 0.4, 0.15)
    box(wall, x0, y0, H + 0.15, W, 0.15, 0.9, faces=("-y", "+y", "+x", "-x", "top"))
    for (a, b) in ((x0, x0 + 0.15), (x0 + W - 0.15, x0 + W)):
        box(wall, a, y0, H, b - a, D, 1.05, faces=("+x", "-x", "top"))
    box(wall, x0, y0 + D - 0.15, H, W, 0.15, 1.05, faces=("+y", "-y", "top"))
    # ground floor: shops, each its own awning and sign; signs full-bay or vertical on the pillars
    for k in range(bays):
        x = x0 + k * BAY
        shop_bay(x + 0.35, BAY - 0.7, 2.9, y0, wall, holes)
        aw = wpick(AWNINGS)
        awning(x + 0.15, x + BAY - 0.15, R.uniform(2.9, 3.3), y0, R.uniform(0.8, 1.8), aw)
        if R.random() < 0.65:
            sw = R.uniform(1.6, BAY - 0.3)
            sign(x + (BAY - sw) / 2, 3.15, sw, R.uniform(0.55, 0.7), y0)
        else:
            sign(x - 0.3, 1.0, 0.6, 2.0, y0 - 0.02)
    # upper floors
    awn_bays = []
    for f in range(1, floors):
        z = GF + FH * (f - 1)
        box("KWG", x0 - 0.15, y0 - 0.15, z - 0.12, W + 0.3, 0.3, 0.12, faces=("-y", "+x", "-x", "top", "bottom"))
        for k in range(bays):
            x = x0 + k * BAY
            kind = R.random()
            paint = R.choice(["KW1", "KW4", "KW6", "KWG"]) if R.random() < 0.25 else wall
            blue = R.random() < 0.6
            if kind < 0.4:
                depth = R.uniform(0.6, 0.9)
                window(x + 0.6, z + 0.9, 1.6, 1.3, y0, holes, wall, grille=False)
                cage(x + 0.15, z, y0, BAY - 0.3, FH - 0.2, depth, wpick(CAGES))
                if paint != wall:
                    front_quad(paint, x + 0.15, x + BAY - 0.15, z + 0.12, z + 0.9, y0 - depth + 0.02)
                laundry(x + 0.3, x + BAY - 0.3, z + 2.1, y0 - depth + 0.3)
                if R.random() < 0.12:
                    face("KNT", [(x + 0.15, y0 - depth - 0.04, z + 0.15), (x + BAY - 0.15, y0 - depth - 0.04, z + 0.15),
                                 (x + BAY - 0.15, y0 - depth - 0.04, z + FH - 0.2), (x + 0.15, y0 - depth - 0.04, z + FH - 0.2)],
                         (0, -1, 0))
                elif R.random() < 0.12:
                    tw = R.uniform(1.0, 2.0)
                    face("KTP", [(x + 0.2, y0 - depth - 0.05, z + 0.4), (x + 0.2 + tw, y0 - depth - 0.08, z + 0.5),
                                 (x + 0.2 + tw, y0 - depth - 0.04, z + 1.9), (x + 0.2, y0 - depth - 0.04, z + 2.0)], (0, -1, 0))
                if blue:
                    awning(x + 0.05, x + BAY - 0.05, z + FH - 0.05, y0, depth + 0.5, "KAW")
                elif R.random() < 0.4:
                    ac_unit(x + 1.1, z + FH - 0.9, y0 - depth)
            elif kind < 0.55:
                # an enclosed balcony with horizontal concrete louvres (photo balcony_grilles_grime)
                box(paint, x + 0.1, y0 - 1.0, z, BAY - 0.2, 1.0, 0.15)
                for k2 in range(6):
                    zz = z + 0.3 + k2 * 0.42
                    box(paint, x + 0.1, y0 - 1.05, zz, BAY - 0.2, 0.12, 0.12, faces=("-y", "top", "bottom"))
                front_quad(grime_group(age), x + 0.25, x + BAY - 0.25, z + 0.15, z + FH - 0.3, y0 - 0.95)
                front_quad(paint, x + 0.25, x + BAY - 0.25, z + 0.15, z + FH - 0.3, y0 - 0.93)
                for (a, b) in ((x + 0.1, x + 0.25), (x + BAY - 0.25, x + BAY - 0.1)):
                    box(paint, a, y0 - 1.0, z + 0.15, b - a, 1.0, FH - 0.3, faces=("-y", "+x", "-x"))
                box(paint, x + 0.1, y0 - 1.0, z + FH - 0.3, BAY - 0.2, 1.0, 0.15)
                stains(x + 0.1, x + BAY - 0.1, z, y0 - 1.05, FH, age)
                ac_unit(x + 1.1, z + 0.4, y0 - 1.05, 0.6)
            elif kind < 0.75:
                window(x + 0.6, z + 0.2, 1.6, 2.1, y0, holes, wall, grille=True)
                box(paint, x + 0.1, y0 - 1.1, z, BAY - 0.2, 1.1, 0.15)
                box(paint, x + 0.1, y0 - 1.1, z + 0.15, BAY - 0.2, 0.1, 0.9, faces=("-y", "+y", "+x", "-x", "top"))
                stains(x + 0.1, x + BAY - 0.1, z, y0 - 1.1, FH * 0.5, age)
                laundry(x + 0.3, x + BAY - 0.3, z + 2.0, y0 - 0.8, y0 - 1.1, z + 1.05)
                for k2 in range(R.randint(0, 3)):
                    cyl("KPL", x + 0.4 + k2 * 0.7, y0 - 0.8, z + 0.15, 0.5, 0.22, 6)
                if blue:
                    awning(x + 0.05, x + BAY - 0.05, z + FH - 0.1, y0, 1.4, "KAW")
                if R.random() < 0.3:
                    small_dish(x + BAY - 0.5, z + 1.6, y0)
            else:
                window(x + 0.7, z + 0.9, 1.5, 1.3, y0, holes, wall, grille=True, awning_kind="KAW" if blue else None)
                if paint != wall:
                    front_quad(paint, x + 0.1, x + BAY - 0.1, z + 0.05, z + FH - 0.2, y0 - OFF_GRIME * 0.5)
                ac_unit(x + R.choice([0.15, 2.1]), z + 0.3, y0)
    # the wall itself (with the openings), then the weathering over it
    facade(wall, x0, x0 + W, 0, H, y0, holes)
    for f in range(1, floors):
        z = GF + FH * (f - 1)
        stains(x0, x0 + W, z - 0.12, y0 - 0.15, 2.5 / 3.0 * FH, age, holes)
    stains(x0, x0 + W, H + 1.05, y0, FH, age, holes)
    grime(x0, x0 + W, H - FH, H + 1.05, y0, age, holes, whole_from=GF)
    # the stained side wall (Anawrahta side 115, 114, 118)
    face(grime_group(age), [(x0 + W + OFF_GRIME, y0, 0), (x0 + W + OFF_GRIME, y0 + D, 0), (x0 + W + OFF_GRIME, y0 + D, H + 1.05),
                            (x0 + W + OFF_GRIME, y0, H + 1.05)], (1, 0, 0))
    drainpipe(x0 + W - 0.2, 0.0, H + 0.8, y0)
    weeds(x0, x0 + W, H + 1.05, y0 + 0.15, 2)
    # a banner hung on a first-floor rail
    bw = R.uniform(2.0, 4.0)
    bx = x0 + R.uniform(0.2, max(0.3, W - bw - 0.2))
    face(R.choice(["KSW", "KS2", "KSV"]), [(bx, y0 - 1.15, GF + 0.15), (bx + bw, y0 - 1.15, GF + 0.15),
                                           (bx + bw, y0 - 1.15, GF + 1.1), (bx, y0 - 1.15, GF + 1.1)], (0, -1, 0))
    roof_clutter(x0, y0, W, D, H, n_tanks=2, dishes=R.randint(2, 3), shed=True)
    return W, D, H


def township_shop(x0, y0, floors=None, wall=None, age=None):
    """Type 3: a township shophouse (Kamayut / Yankin): one plot 4.5-6 m wide, GF 3.6 open shop, a fascia sign,
    pillar signs, a telecom lightbox, a vinyl banner upstairs, sometimes a low pitched metal roof front."""
    W, D, GF, FH = R.uniform(4.5, 6.0), 18.0, 3.6, 3.1
    floors = floors or R.choice([2, 3, 3, 4])
    wall = wall or wpick(TOWNSHIP_WALLS)
    age = R.uniform(0.2, 0.6) if age is None else age
    H = GF + FH * (floors - 1)
    LOG.append(("township_shop", wall, round(age, 2)))
    holes = []
    box(wall, x0, y0, 0, W, D, H, faces=("+x", "-x", "+y", "top"))
    box("KW0", x0 - 0.05, y0 - 0.05, H, W + 0.1, D + 0.1, 0.12)
    # ground floor
    state = shop_bay(x0 + 0.35, W - 0.7, 2.8, y0, wall, holes, state=R.choice(["open", "open", "shutter"]), spill=0.7)
    fh = R.uniform(0.8, 1.2)
    sign(x0 - 0.05, 2.85, W + 0.1, fh, y0 - 0.1, ground=R.choice(["KSW", "KS2"]), stripe=R.choice(["KS1", "KS3", "KS4"]))
    for px in ([x0 + 0.02] + ([x0 + W - 0.32] if R.random() < 0.5 else [])):
        sign(px, 0.5, 0.3, 2.0, y0 - 0.02, ground=R.choice(["KSW", "KS2", "KS1"]), stripe=None)
    # the projecting telecom lightbox: a rounded shield on an arm, white with a plain logo disc
    lz, lx = R.uniform(2.5, 4.0), x0 + W - 0.15
    if lz < 2.85 + fh:
        lz = 2.85 + fh + 0.6
    bar("KCG", (lx, y0, lz + 0.45), (lx, y0 - 0.9, lz + 0.45), 0.05)
    shield = [(lx, y0 - 0.6 + 0.45 * math.cos(math.pi * t / 8), lz + 0.55 + 0.35 * math.sin(math.pi * t / 8))
              for t in range(9)] + [(lx, y0 - 1.05, lz + 0.15), (lx, y0 - 0.85, lz), (lx, y0 - 0.35, lz), (lx, y0 - 0.15, lz + 0.15)]
    lbox = R.choice(["KS3", "KS1", "KS2"])
    for sxo, nrm in ((-0.08, -1), (0.08, 1)):
        face(lbox, [(lx + sxo, p[1], p[2]) for p in shield], (nrm, 0, 0))
        disc = [(lx + sxo * 1.05, y0 - 0.6 + 0.18 * math.cos(2 * math.pi * k / 8), lz + 0.45 + 0.18 * math.sin(2 * math.pi * k / 8))
                for k in range(8)]
        face("KSW", disc, (nrm, 0, 0))
    awning(x0, x0 + W, 2.75, y0 - 0.1, R.uniform(1.0, 2.0), wpick({"KAW": 0.4, "KAR": 0.3, None: 0.3}))
    if state == "open" and R.random() < 0.4:
        # a tea stall / cart with an umbrella out front
        cx = x0 + R.uniform(0.8, W - 1.6)
        box("KWD", cx, y0 - 2.6, 0.15, 1.2, 0.7, 0.8)
        bar("KCG", (cx + 0.6, y0 - 2.25, 0.95), (cx + 0.6, y0 - 2.25, 2.3), 0.04)
        um = R.choice(["KS1", "KAW", "KS2"])
        pts = [(cx + 0.6 + 1.1 * math.cos(2 * math.pi * t / 8), y0 - 2.25 + 1.1 * math.sin(2 * math.pi * t / 8), 2.1) for t in range(8)]
        for t in range(8):
            face(um, [pts[t], pts[(t + 1) % 8], (cx + 0.6, y0 - 2.25, 2.5)], (0, 0, 1))
            face(um, [pts[t], pts[(t + 1) % 8], (cx + 0.6, y0 - 2.25, 2.5)], (0, 0, -1))
    # upper floors
    for f in range(1, floors):
        z = GF + FH * (f - 1)
        box("KW0", x0, y0 - 0.12, z - 0.1, W, 0.12, 0.1, faces=("-y", "+x", "-x", "top", "bottom"))
        ww = min(1.6, (W - 1.4) / 2)
        for wx in (x0 + 0.5, x0 + W - 0.5 - ww):
            window(wx, z + 0.9, ww, 1.3, y0, holes, wall, grille=True,
                   awning_kind="KAW" if R.random() < 0.35 else None)
        if f == 1:
            face(R.choice(["KSV", "KS2", "KS1"]), [(x0 + 0.3, y0 - 0.06, z + 0.1), (x0 + W - 0.3, y0 - 0.06, z + 0.1),
                                                   (x0 + W - 0.3, y0 - 0.06, z + 0.8), (x0 + 0.3, y0 - 0.06, z + 0.8)], (0, -1, 0))
        else:
            ac_unit(x0 + W / 2 - 0.4, z + 0.3, y0)
    facade(wall, x0, x0 + W, 0, H, y0, holes)
    for f in range(1, floors):
        stains(x0, x0 + W, GF + FH * (f - 1) - 0.1, y0, FH * 0.8, age, holes)
    stains(x0, x0 + W, H, y0, FH, age, holes)
    grime(x0, x0 + W, H - FH, H, y0, age, holes, whole_from=GF)
    drainpipe(x0 + 0.12, 0.0, H, y0)
    weeds(x0, x0 + W, H + 0.12, y0 + 0.1, 1)
    # 30%: a low pitched coloured-metal roof front over a 0.6 m parapet
    if R.random() < 0.3:
        rc = R.choice(["KRB", "KRF", "KRG"])
        face(rc, [(x0 - 0.2, y0 - 0.4, H + 0.6), (x0 + W + 0.2, y0 - 0.4, H + 0.6), (x0 + W + 0.2, y0 + 4.0, H + 1.6),
                  (x0 - 0.2, y0 + 4.0, H + 1.6)], (0, -0.3, 1))
        box(wall, x0, y0, H + 0.12, W, 0.15, 0.48, faces=("-y", "+x", "-x", "top"))
    # a rusty corrugated lean-to at the back
    face("KRF", [(x0, y0 + D - 6, H + 1.2), (x0 + W, y0 + D - 6, H + 1.2), (x0 + W, y0 + D, H + 0.2), (x0, y0 + D, H + 0.2)],
         (0, 0, 1))
    roof_clutter(x0, y0, W, D - 6, H, n_tanks=1, dishes=0)
    return W, D, H


def colonial_row(x0, y0, plots=3):
    """Type 1: a downtown colonial shophouse row: plots 7 m, GF 5.0, upper 3.9, arched windows 0.35 m deep with teak
    shutters, pilasters, string courses, bracketed balconies, cornices, a 1.2 parapet (solid or balustrade); each
    plot its own weighted colour and age; the end plot is the corner (pediment, sometimes a pink / green landmark)."""
    PW, D, GF, FH = 7.0, 24.0, 5.0, 3.9
    top = 0.0
    for p in range(plots):
        x = x0 + p * PW
        corner = p == plots - 1
        age = R.random()
        wall = wpick(CORNER_WALLS) if corner and R.random() < 0.35 else wpick(COLONIAL_WALLS)
        if age > 0.7 and wall not in CORNER_WALLS:
            wall = "KWD2"
        trim = R.choice(["KW0", wall])
        LOG.append(("colonial_row", wall, round(age, 2)))
        shut = wpick(SHUTTERS)
        floors = 4 if p != 1 else 5
        H = GF + FH * (floors - 1)
        top = max(top, H)
        holes = []
        box(wall, x, y0, 0, PW, D, H, faces=("+x", "-x", "+y", "top"))
        # cornice + parapet (balustrade on half the plots)
        box("KW0", x - 0.1, y0 - 0.35, H - 0.4, PW + 0.2, 0.35, 0.4, faces=("-y", "+x", "-x", "top", "bottom"))
        if R.random() < 0.5:
            box(wall, x, y0, H, PW, 0.3, 0.25, faces=("-y", "+x", "-x", "top"))
            n = int((PW - 0.3) / 0.25)
            for k in range(n):
                bx = x + 0.2 + k * (PW - 0.4) / n
                box(trim, bx, y0 + 0.05, H + 0.25, 0.12, 0.12, 0.7, faces=("-y", "+x", "-x"))
            for (a, b) in ((x, x + 0.4), (x + PW - 0.4, x + PW)):
                box(wall, a, y0, H + 0.25, b - a, 0.3, 0.7, faces=("-y", "+x", "-x"))
            box(trim, x - 0.05, y0 - 0.05, H + 0.95, PW + 0.1, 0.4, 0.25)
            box(wall, x, y0 + 0.3, H, PW, 0.15, 1.2, faces=("-y", "+y"))
        else:
            box(wall, x, y0, H, PW, 0.3, 1.2, faces=("-y", "+y", "+x", "-x", "top"))
            box(trim, x - 0.05, y0 - 0.05, H + 1.1, PW + 0.1, 0.4, 0.15)
        if corner:
            # the corner pediment: a triangle 2.5 m tall over the middle of the end plot
            cx = x + PW / 2
            base, apex = H + 1.2, H + 3.7
            for yy, nrm in ((y0 - 0.02, -1), (y0 + 0.3, 1)):
                face(wall, [(cx - 2.2, yy, base), (cx + 2.2, yy, base), (cx, yy, apex)], (0, nrm, 0))
            for (ax, az) in ((cx - 2.2, base), (cx + 2.2, base)):
                face("KW0", [(ax, y0 - 0.1, az), (cx, y0 - 0.1, apex + 0.1), (cx, y0 + 0.35, apex + 0.1), (ax, y0 + 0.35, az)],
                     (ax - cx, 0, 1))
            face("KGL", [(cx - 0.4, y0 - 0.03, base + 0.3), (cx + 0.4, y0 - 0.03, base + 0.3), (cx, y0 - 0.03, base + 1.2)],
                 (0, -1, 0))
        # the hidden pitched rusty roof behind the parapet
        face("KRF", [(x, y0 + 1.0, H + 0.2), (x + PW, y0 + 1.0, H + 0.2), (x + PW, y0 + D / 2, H + 2.2), (x, y0 + D / 2, H + 2.2)],
             (0, -0.5, 1))
        face("KRF", [(x, y0 + D / 2, H + 2.2), (x + PW, y0 + D / 2, H + 2.2), (x + PW, y0 + D - 0.5, H + 0.2), (x, y0 + D - 0.5, H + 0.2)],
             (0, 0.5, 1))
        # ground floor: three shop bays, an awning (or none) and its own signs
        for k in range(3):
            shop_bay(x + 0.4 + k * 2.2, 1.9, 3.4, y0, wall, holes)
        aw = wpick(AWNINGS)
        awning(x + 0.1, x + PW - 0.1, R.uniform(2.6, 3.4) + 0.4, y0, R.uniform(0.8, 2.0), aw)
        sw = R.uniform(1.5, 3.0)
        sign(x + R.uniform(0.3, PW - sw - 0.3), R.uniform(3.6, 3.9), sw, R.uniform(0.6, 1.0), y0)
        if R.random() < 0.5:
            sw2 = R.uniform(1.5, 2.2)
            sign(x + R.uniform(0.3, PW - sw2 - 0.3), 4.0, sw2, 0.6, y0 - 0.12)
        # upper floors
        balc = R.choices(["none", "f1", "all"], [0.25, 0.4, 0.35])[0]
        iron = R.random() < 0.5
        for f in range(1, floors):
            z = GF + FH * (f - 1)
            has_balc = balc == "all" or (balc == "f1" and f == 1)
            box("KW0", x - 0.1, y0 - 0.25, z - 0.25, PW + 0.2, 0.25, 0.25, faces=("-y", "+x", "-x", "top", "bottom"))
            box(trim, x, y0 - 0.12, z + 0.43, PW, 0.12, 0.1, faces=("-y", "+x", "-x", "top", "bottom"))  # string course
            for k in range(3):
                wx = x + 0.6 + k * 2.2
                zz = z + 0.12 if has_balc else z + 0.55
                hh = 2.45 if has_balc else 2.0
                state = R.choices(["closed", "flat", "ajar"], [0.5, 0.3, 0.2])[0]
                arch_window(wx, zz, 1.15, hh, y0, holes, wall, shut, state)
            for px, pw in ((x, 0.35), (x + 2.05, 0.45), (x + 4.25, 0.45), (x + PW - 0.35, 0.35)):
                box(trim, px, y0 - 0.15, z - 0.02, pw, 0.15, FH - 0.25, faces=("-y", "+x", "-x"))
            if has_balc:
                bd = 1.2
                box(wall, x + 0.3, y0 - bd, z, PW - 0.6, bd, 0.18, faces=("-y", "+x", "-x", "top", "bottom"))
                face("KSU", [(x + 0.3, y0 - bd, z - 0.02), (x + PW - 0.3, y0 - bd, z - 0.02), (x + PW - 0.3, y0, z - 0.02),
                             (x + 0.3, y0, z - 0.02)], (0, 0, -1))
                for bx in (x + 0.5, x + PW / 2 - 0.06, x + PW - 0.62):  # brackets
                    for sx, nrm in ((bx, -1), (bx + 0.12, 1)):
                        face(trim, [(sx, y0, z), (sx, y0 - 0.6, z), (sx, y0, z - 0.3 - 0.3)], (nrm, 0, 0))
                    face(trim, [(bx, y0 - 0.6, z), (bx + 0.12, y0 - 0.6, z), (bx + 0.12, y0, z - 0.6), (bx, y0, z - 0.6)],
                         (0, -1, -0.6))
                yr = y0 - bd + 0.06
                if iron:
                    n = int((PW - 0.7) / 0.14)
                    for k in range(n + 1):
                        xx = x + 0.35 + (PW - 0.7) * k / n
                        front_quad("KGR", xx - 0.015, xx + 0.015, z + 0.18, z + 1.0, yr)
                    front_quad("KGR", x + 0.35, x + PW - 0.35, z + 0.55, z + 0.58, yr)
                    box("KGR", x + 0.32, yr - 0.03, z + 1.0, PW - 0.64, 0.08, 0.06)
                else:
                    n = int((PW - 0.7) / 0.3)
                    for k in range(n + 1):
                        xx = x + 0.35 + (PW - 0.7) * k / n
                        box(trim, xx - 0.05, yr - 0.05, z + 0.18, 0.1, 0.1, 0.82, faces=("-y", "+x", "-x"))
                    box(trim, x + 0.32, yr - 0.08, z + 1.0, PW - 0.64, 0.16, 0.08)
                laundry(x + 0.6, x + PW - 0.6, z + 2.0, y0 - 0.9, yr - 0.05, z + 1.08)
                if R.random() < 0.3:
                    small_dish(x + PW - 0.9, z + 1.6, y0 - 0.3)
        # the wall with its openings, then the weathering
        facade(wall, x, x + PW, 0, H, y0, holes)
        for f in range(1, floors):
            z = GF + FH * (f - 1)
            stains(x, x + PW, z - 0.25, y0 - 0.25, FH, age, holes)
        stains(x, x + PW, H - 0.4, y0 - 0.35, FH, age, holes)
        grime(x, x + PW, H - FH, H, y0, age, holes, whole_from=GF)
        for (a, b, c, d) in rect_minus(x, x + PW, H + 0.05, H + 1.1, []):
            front_quad(grime_group(min(1.0, age + 0.3)), a, b, c, d, y0 - OFF_GRIME)
        # clutter: AC units, a drainpipe on the party wall, weeds on the cornice and ledges
        for _ in range(R.randint(1, 2)):
            f = R.randint(1, floors - 1)
            ac_unit(R.choice([x + 1.85, x + 4.05]), GF + FH * (f - 1) + 1.3, y0 - 0.15)
        drainpipe(x + PW - 0.18 if p < plots - 1 else x + 0.18, 0.0, H, y0)
        weeds(x, x + PW, H, y0 - 0.35, R.randint(1, 2))
        weeds(x, x + PW, GF + FH * R.randint(0, floors - 2), y0 - 0.25, 1)
        roof_clutter(x, y0, PW, D, H, n_tanks=1, dishes=1 if p == 0 else 0)
    return PW * plots, D, top


def tree(x, y, kind="shade"):
    """A shade tree (trunk + 2-4 crown blobs, 3-6 m) or a palm (7-10 m trunk + 8 drooping fronds)."""
    if kind == "palm":
        h = R.uniform(7.0, 10.0)
        lean = (R.uniform(-0.4, 0.4), R.uniform(-0.4, 0.4))
        topp = (x + lean[0], y + lean[1], h)
        bar("KTW", (x, y, 0), topp, 0.3)
        for k in range(8):
            a = 2 * math.pi * k / 8 + R.uniform(-0.2, 0.2)
            L = R.uniform(2.2, 3.0)
            tip = (topp[0] + L * math.cos(a), topp[1] + L * math.sin(a), h - R.uniform(0.8, 1.6))
            midp = (topp[0] + 0.55 * L * math.cos(a), topp[1] + 0.55 * L * math.sin(a), h + 0.25)
            px, py = -math.sin(a) * 0.35, math.cos(a) * 0.35
            face("KTL", [(topp[0], topp[1], h), (midp[0] + px, midp[1] + py, midp[2]), tip, (midp[0] - px, midp[1] - py, midp[2])],
                 (0, 0, 1))
        return h
    h = R.uniform(4.0, 6.5)
    bar("KTW", (x, y, 0), (x, y, h * 0.6), 0.35)
    for k in range(R.randint(2, 4)):
        r = R.uniform(1.6, 3.0)
        blob("KTL", x + R.uniform(-1.2, 1.2), y + R.uniform(-1.2, 1.2), h * R.uniform(0.7, 1.0), r, r, r * 0.7)
    return h


def villa(x0, y0):
    """Type 4: a walled villa (Bahan / Golden Valley): plot 24 x 30, a 2.1 m stained wall with razor wire and a 5 m
    near-black gate between pillars, palms and shade trees over the wall, a white house 12 x 10 on a 0.7 m base, two
    floors of 3.5, a veranda, a hipped roof (muted brick-red tiles, or rust / blue metal) with 1 m eaves."""
    PW, PD = 24.0, 30.0
    WALL_H = 2.1
    age = R.uniform(0.2, 0.5)
    gx0, gx1 = x0 + 9.5, x0 + 14.5
    for (a, b) in ((x0, gx0 - 0.6), (gx1 + 0.6, x0 + PW)):
        box("KWC", a, y0, 0, b - a, 0.25, WALL_H, faces=("-y", "+y", "+x", "-x"))
        box("KWC", a - 0.05, y0 - 0.05, WALL_H, b - a + 0.1, 0.35, 0.12)
        stains(a, b, WALL_H, y0 - 0.05, WALL_H, 0.7)
        grime(a, b, 0.0, WALL_H, y0, 0.6)
        # a spiked rail and razor-wire coils on top
        for k in range(int((b - a) / 0.6)):
            cx = a + 0.3 + k * 0.6
            ring = [(cx + 0.05 * math.sin(2 * math.pi * t / 6) + 0.1 * t / 6, y0 + 0.12 + 0.22 * math.cos(2 * math.pi * t / 6),
                     WALL_H + 0.42 + 0.22 * math.sin(2 * math.pi * t / 6)) for t in range(7)]
            for t in range(6):
                bar("KGR", ring[t], ring[t + 1], 0.02)
        for k in range(int((b - a) / 1.5) + 1):
            bar("KGR", (a + k * 1.5, y0 + 0.12, WALL_H + 0.12), (a + k * 1.5, y0 + 0.12, WALL_H + 0.7), 0.04)
        bar("KGR", (a, y0 + 0.12, WALL_H + 0.65), (b, y0 + 0.12, WALL_H + 0.65), 0.03)
    for (a, b) in ((x0, x0 + 0.25), (x0 + PW - 0.25, x0 + PW)):
        box("KWC", a, y0, 0, b - a, PD, WALL_H, faces=("+x", "-x", "top"))
    box("KWC", x0, y0 + PD - 0.25, 0, PW, 0.25, WALL_H, faces=("-y", "+y", "top"))
    for px in (gx0 - 0.6, gx1):
        box("KWC", px, y0 - 0.1, 0, 0.6, 0.6, 2.8)
        box("KW0", px - 0.1, y0 - 0.2, 2.8, 0.8, 0.8, 0.25)
        cyl("KW0", px + 0.3, y0 + 0.2, 3.05, 0.35, 0.18, 8)
        grime(px, px + 0.6, 0.0, 2.8, y0 - 0.1, 0.7)
    gate = R.choice(["KGT", "KGT", "KGU"])
    front_quad(gate, gx0, gx1, 0.05, 2.4, y0 + 0.1)
    for k in range(26):
        xx = gx0 + 5.0 * k / 25
        bar(gate, (xx, y0 + 0.08, 0.05), (xx, y0 + 0.08, 2.5 + 0.15 * math.sin(math.pi * k / 25)), 0.03)
    bar(gate, (gx0, y0 + 0.06, 1.2), (gx1, y0 + 0.06, 1.2), 0.06)
    # grass with a paved drive
    box("KGS", x0 + 0.25, y0 + 0.25, 0, PW - 0.5, PD - 0.5, 0.03, faces=("top",))
    box("KPV", gx0, y0 + 0.25, 0.01, gx1 - gx0, 11.0, 0.03, faces=("top",))
    # the house
    hx, hy, HW, HD, BASE, FH = x0 + 6.0, y0 + 11.0, 12.0, 10.0, 0.7, 3.5
    holes = []
    box("KWG", hx - 0.2, hy - 0.2, 0, HW + 0.4, HD + 0.4, BASE)
    box("KW6", hx, hy, BASE, HW, HD, 2 * FH, faces=("+x", "-x", "+y"))
    box("KW0", hx - 0.15, hy - 0.15, BASE + FH - 0.15, HW + 0.3, HD + 0.3, 0.15)
    for f in range(2):
        z = BASE + f * FH
        for k in range(3):
            if f == 0 and k == 1:
                opening(holes, hx + 0.9 + k * 3.9 + 0.1, z, 1.1, 2.3, hy, "KW6", glass="KSH")  # the front door
                continue
            window(hx + 0.9 + k * 3.9, z + 0.85, 1.3, 1.6, hy, holes, "KW6", grille=(f == 0))
            shutters(hx + 0.9 + k * 3.9, z + 0.85, 1.3, 1.6, hy, "KSH", R.choice(["flat", "flat", "closed"]))
    facade("KW6", hx, hx + HW, BASE, BASE + 2 * FH, hy, holes)
    stains(hx, hx + HW, BASE + 2 * FH, hy, FH, age, holes)
    stains(hx, hx + HW, BASE + FH - 0.15, hy - 0.15, FH, age, holes)
    grime(hx, hx + HW, BASE + FH, BASE + 2 * FH, hy, age, holes, z_base=BASE)
    ac_unit(hx + HW - 1.2, BASE + FH + 0.4, hy)
    ac_unit(hx + 0.3, BASE + 0.4, hy)
    drainpipe(hx + HW - 0.15, BASE, BASE + 2 * FH, hy)
    # veranda on 4 posts under a flat roof, steps
    box("KW0", hx + 3.5, hy - 2.5, BASE + 2.9, 5.0, 2.5, 0.18)
    for px in (hx + 3.6, hx + 8.3):
        box("KW0", px, hy - 2.4, BASE, 0.2, 0.2, 2.9)
    box("KWG", hx + 4.5, hy - 3.4, 0, 3.0, 0.9, 0.35)
    # hipped roof, eaves 1 m
    z = BASE + 2 * FH
    e = 1.0
    A, B, C, Dd = (hx - e, hy - e), (hx + HW + e, hy - e), (hx + HW + e, hy + HD + e), (hx - e, hy + HD + e)
    rise = (HD / 2 + e) * 0.55
    r0, r1 = (hx + HD / 2, hy + HD / 2, z + rise), (hx + HW - HD / 2, hy + HD / 2, z + rise)
    roof = wpick({"KRT": 0.6, "KRF": 0.25, "KRB": 0.15})
    LOG.append(("villa", "KW6 / roof " + roof + " / gate " + gate, round(age, 2)))
    P = [(p[0], p[1], z) for p in (A, B, C, Dd)]
    face(roof, [P[0], P[1], r1, r0], (0, -1, 1))
    face(roof, [P[1], P[2], r1], (1, 0, 1))
    face(roof, [P[2], P[3], r0, r1], (0, 1, 1))
    face(roof, [P[3], P[0], r0], (-1, 0, 1))
    g.ring("KW0", [(m(p[0]), m(p[1])) for p in (A, B, C, Dd)], m(z - 0.3), m(z))
    g.cap("KW0", [(m(p[0]), m(p[1])) for p in (A, B, C, Dd)], m(z - 0.3), down=True)
    # trees between the wall and the house, over the wall
    for (tx, ty, kind) in ((x0 + 2.5, y0 + 3.0, "palm"), (x0 + 6.0, y0 + 1.8, "shade"), (x0 + 17.0, y0 + 2.0, "shade"),
                           (x0 + 21.0, y0 + 5.0, "palm"), (x0 + 3.0, y0 + 20.0, "shade"), (x0 + 20.5, y0 + 1.6, "shade")):
        tree(tx + R.uniform(-0.5, 0.5), ty + R.uniform(-0.5, 0.5), kind)
    return PW, PD, z + rise


def condo(x0, y0, floors=15, wall=None):
    """Type 5: a modern condo: 16 x 24, a 2-floor podium of 4.2, upper floors 3.1. A white or grey tower with punched
    windows, a blue cladding / glass stripe up the middle, recessed balconies on some bay columns, AC ledges with
    louvres, a crown frame with a curved fin."""
    W, D, PF, FH = 16.0, 24.0, 4.2, 3.1
    wall = wall or wpick(CONDO_WALLS)
    age = R.uniform(0.1, 0.3)
    LOG.append(("condo", wall, round(age, 2)))
    # podium: white with a dark glass band, a bank sign, a car-park opening
    box("KW0", x0, y0, 0, W, D, 2 * PF)
    front_quad("KGL", x0 + 0.8, x0 + W - 5, 0.3, 3.6, y0 - 0.01)  # shopfront glass with mullions
    for k in range(6):
        xx = x0 + 0.8 + k * (W - 5.8) / 5
        front_quad("KFR", xx - 0.05, xx + 0.05, 0.3, 3.6, y0 - 0.02)
    front_quad("KSI", x0 + W - 4.4, x0 + W - 0.8, 0.0, 2.6, y0 - 0.01)  # the car-park mouth
    for k in range(4):  # the podium's upper floor: a band of narrow windows
        front_quad("KGL", x0 + 1.0 + k * 3.6, x0 + 3.6 + k * 3.6, PF + 1.0, PF + 2.9, y0 - 0.01)
    sign(x0 + 1.2, 3.75, 4.0, 0.6, y0 - 0.02, ground="KSW", stripe="KS3")
    sign(x0 + 6.5, 3.75, 3.0, 0.6, y0 - 0.02)
    grime(x0, x0 + W, PF, 2 * PF, y0, age)
    tx0, tx1, ty0 = x0 + 1, x0 + W - 1, y0 + 1
    H = 2 * PF + FH * (floors - 2)
    holes = []
    box(wall, tx0, ty0, 2 * PF, tx1 - tx0, D - 2, H - 2 * PF, faces=("+x", "-x", "+y", "top"))
    # the blue stripe: a band 3.5 m wide up the middle, slightly proud, with glass in it
    sx0, sx1 = x0 + W / 2 - 1.75, x0 + W / 2 + 1.75
    box("KBC", sx0, ty0 - 0.2, 2 * PF, sx1 - sx0, 0.2, H - 2 * PF + 1.0, faces=("-y", "+x", "-x", "top"))
    # bay columns either side: punched windows, recessed balconies (on whole columns), AC ledges
    cols = [tx0 + 0.3, tx0 + 3.0, sx1 + 0.3, sx1 + 3.0]
    kinds = ["win", "balc", "win", "acl"]
    R.shuffle(kinds)
    for f in range(floors - 2):
        z = 2 * PF + f * FH
        for cx, kind in zip(cols, kinds):
            kk = kind if R.random() < 0.85 else "win"
            if kk == "balc":
                opening(holes, cx, z + 0.15, 2.4, 2.6, ty0, wall, depth=1.2, glass="KGL")
                front_quad("KRL", cx, cx + 2.4, z + 0.15, z + 1.15, ty0 + 0.05)
                laundry(cx + 0.2, cx + 2.2, z + 2.2, ty0 + 0.6)
            elif kk == "acl":
                opening(holes, cx + 0.2, z + 0.3, 2.0, 1.8, ty0, wall, depth=0.6, glass="KSI", lit=False)
                for k2 in range(6):
                    front_quad("KW0", cx + 0.2, cx + 2.2, z + 0.4 + k2 * 0.28, z + 0.5 + k2 * 0.28, ty0 + 0.02)
            else:
                window(cx + 0.35, z + 0.75, 1.7, 1.8, ty0, holes, wall, grille=False)
        for k in range(3):  # glass in the stripe
            front_quad("KGL", sx0 + 0.3 + k * 1.0, sx0 + 1.1 + k * 1.0, z + 0.5, z + 2.7, ty0 - 0.21)
        box("KW0", tx0, ty0 - 0.12, z - 0.15, tx1 - tx0, 0.12, 0.15, faces=("-y", "+x", "-x", "top", "bottom"))
    facade(wall, tx0, tx1, 2 * PF, H, ty0, holes)
    for f in range(floors - 2):
        stains(tx0, tx1, 2 * PF + f * FH - 0.15, ty0 - 0.12, FH * 0.6, age, holes)
    grime(tx0, tx1, H - FH, H, ty0, age, holes, z_base=2 * PF)
    for k in range(5):
        ac_unit(R.choice([tx0 + 2.6, sx1 + 2.5]), 2 * PF + R.randint(0, floors - 3) * FH + 0.3, ty0)
    # crown: a frame with a curved fin
    box("KW0", tx0, ty0, H, tx1 - tx0, D - 2, 0.3)
    for (a, b) in ((tx0, tx0 + 0.6), (tx1 - 0.6, tx1)):
        box("KW0", a, ty0, H, b - a, 0.6, 5.0)
    box("KW0", tx0, ty0, H + 4.6, tx1 - tx0, 0.6, 0.6)
    # the fin: a blade on top of the blue stripe, curving back as it rises
    fx0, fx1 = sx0 + 1.1, sx1 - 1.1
    fin = [(ty0 - 0.2 + 3.2 * (t / 8) ** 2, H + 1.0 + 6.5 * (t / 8)) for t in range(9)]
    for t in range(8):
        (ya, za), (yb, zb) = fin[t], fin[t + 1]
        face("KBC", [(fx0, ya, za), (fx1, ya, za), (fx1, yb, zb), (fx0, yb, zb)], (0, -(zb - za), (yb - ya)))
        face("KBC", [(fx0, ya + 0.25, za), (fx1, ya + 0.25, za), (fx1, yb + 0.25, zb), (fx0, yb + 0.25, zb)], (0, zb - za, -(yb - ya)))
        for xx, nrm in ((fx0, -1), (fx1, 1)):
            face("KBC", [(xx, ya, za), (xx, yb, zb), (xx, yb + 0.25, zb), (xx, ya + 0.25, za)], (nrm, 0, 0))
    roof_clutter(tx0, ty0, tx1 - tx0, D - 2, H + 0.3, n_tanks=2, dishes=0)
    return W, D, H + 7.5


def market(x0, y0):
    """Type 6: a market shed: 20 x 30, posts every 4.5, eaves 4.5, a patched corrugated gable roof (rust and grey
    strips, a ridge vent), stalls with umbrellas."""
    W, D, E = 20.0, 30.0, 4.5
    for i in range(5):
        for j in range(7):
            px, py = x0 + i * W / 4, y0 + j * D / 6
            box("KCO", px - 0.15, py - 0.15, 0, 0.3, 0.3, E)
    ridge = E + 2.5
    yy = y0 - 1
    while yy < y0 + D + 1:
        y1 = min(y0 + D + 1, yy + 0.9)
        grp = "KRF" if R.random() < 0.65 else "KRG"
        face(grp, [(x0 - 1, yy, E), (x0 + W / 2, yy, ridge), (x0 + W / 2, y1, ridge), (x0 - 1, y1, E)], (-1, 0, 2))
        grp = "KRF" if R.random() < 0.65 else "KRG"
        face(grp, [(x0 + W / 2, yy, ridge), (x0 + W + 1, yy, E), (x0 + W + 1, y1, E), (x0 + W / 2, y1, ridge)], (1, 0, 2))
        yy = y1
    box("KRG", x0 + W / 2 - 1.0, y0 - 1, ridge - 0.2, 2.0, D + 2, 1.0, faces=("+x", "-x", "-y", "+y"))
    face("KRF", [(x0 + W / 2 - 1.3, y0 - 1, ridge + 0.8), (x0 + W / 2 + 1.3, y0 - 1, ridge + 0.8),
                 (x0 + W / 2 + 1.3, y0 + D + 1, ridge + 0.8), (x0 + W / 2 - 1.3, y0 + D + 1, ridge + 0.8)], (0, 0, 1))
    for i in range(4):
        for j in range(5):
            sx, sy = x0 + 1.5 + i * 4.7, y0 + 2 + j * 5.5
            box("KWD", sx, sy, 0, 3.0, 1.4, 0.85)
            for k in range(4):
                box(R.choice(["PRC", "PRC", "KL4", "KPL", "KL1", "KWD"]), sx + 0.2 + k * 0.7, sy + 0.2, 0.85, 0.5, 1.0, 0.25)
    for k in range(5):
        cx, cy = x0 + 2 + k * 4.0, y0 - 2.0
        bar("KCG", (cx, cy, 0), (cx, cy, 2.3), 0.04)
        pts = [(cx + 1.2 * math.cos(2 * math.pi * t / 8), cy + 1.2 * math.sin(2 * math.pi * t / 8), 2.1) for t in range(8)]
        col = R.choice(["KS1", "KSW", "KAW", "KAR"])
        for t in range(8):
            face(col, [pts[t], pts[(t + 1) % 8], (cx, cy, 2.6)], (0, 0, 1))
            face(col, [pts[t], pts[(t + 1) % 8], (cx, cy, 2.6)], (0, 0, -1))
    return W, D, ridge


def street_wires(x0, x1, y):
    """Concrete poles every 30-40 m at the kerb (9 m, a cross-arm, a transformer on some) and sagging bundles of 4-8
    wires between them at 5-8 m; a few drop wires to the facades."""
    xs = [x0]
    while xs[-1] < x1:
        xs.append(xs[-1] + R.uniform(30.0, 40.0))
    tops = []
    for x in xs:
        box("KCO", x - 0.15, y - 0.15, 0, 0.3, 0.3, 9.0, faces=("-y", "+y", "+x", "-x", "top"))
        bar("KCG", (x, y - 0.9, 8.4), (x, y + 0.9, 8.4), 0.08)
        if R.random() < 0.4:
            box("KCG", x - 0.35, y + 0.15, 5.5, 0.7, 0.5, 0.9)
            cyl("KCG", x, y + 0.4, 6.4, 0.3, 0.2, 6)
        tops.append(x)
    for a, b in zip(tops, tops[1:]):
        n = R.randint(4, 8)
        for k in range(n):
            za = R.uniform(5.0, 8.0)
            zb = min(8.2, max(5.0, za + R.uniform(-0.6, 0.6)))
            ya = y + R.uniform(-0.6, 0.6)
            yb = y + R.uniform(-0.6, 0.6)
            sag = R.uniform(0.5, 1.4)
            pts = []
            for t in range(9):
                u = t / 8
                pts.append((a + (b - a) * u, ya + (yb - ya) * u, za + (zb - za) * u - sag * 4 * u * (1 - u)))
            for t in range(8):
                bar("KWI", pts[t], pts[t + 1], 0.025)
        # a drop wire to a facade bracket
        for _ in range(R.randint(1, 2)):
            fx = R.uniform(a, b)
            pts = [(a, y, 7.0), ((a + fx) / 2, y * 0.5, 5.6), (fx, 0.0 - 0.1, 6.0)]
            for t in range(2):
                bar("KWI", pts[t], pts[t + 1], 0.025)


def car(x, y):
    """A car for scale: 4.5 x 1.8 x 1.45 m."""
    box("KCR", x, y, 0.25, 4.5, 1.8, 0.75)
    box("KGL", x + 1.1, y + 0.1, 1.0, 2.3, 1.6, 0.45)
    for (cx, cy) in ((x + 0.8, y), (x + 3.7, y), (x + 0.8, y + 1.8), (x + 3.7, y + 1.8)):
        box("KTY", cx - 0.32, cy - 0.12, 0, 0.64, 0.24, 0.64)


def person(x, y):
    """A person for scale: 1.75 m."""
    cyl("KL2", x, y, 0.0, 0.85, 0.16, 8)
    cyl("KL1", x, y, 0.85, 0.6, 0.2, 8)
    cyl("KSK", x, y, 1.47, 0.28, 0.11, 8)


def scene():
    """The six types side by side along a street (the street is y < 0), a car and a person in front of each, poles
    and wires along the kerb."""
    g.cap("KRD", [(m(-10), m(-12)), (m(260), m(-12)), (m(260), m(0)), (m(-10), m(0))], 0.0)
    g.cap("KPV", [(m(-10), m(-3.2)), (m(260), m(-3.2)), (m(260), m(0)), (m(-10), m(0))], m(0.15))
    out = {}
    x = 0.0
    for name, fn, kw in (("colonial_row", colonial_row, {}), ("township_shop", township_shop, {"floors": 3}),
                         ("walkup", walkup, {"bays": 5}), ("villa", villa, {}), ("condo", condo, {}),
                         ("market", market, {})):
        Wd, Dd, Hh = fn(x, 0.0, **kw)
        out[name] = {"x": x, "w": Wd, "d": Dd, "h": Hh}
        car(x + 1.0, -9.0)
        person(x + 2.5, -2.0)
        x += Wd + 6.0
    street_wires(-6.0, x, -2.9)
    return out


if __name__ == "__main__":
    info = scene()
    path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "..", "build", "kit", "kit_pilot_tris.json")
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    json.dump({k: v for k, v in g.g.items()}, open(path, "w"))
    json.dump(info, open(path.replace("_tris.json", "_info.json"), "w"), indent=1)
    print(info)
    print(LOG)
    counts = {}
    for k, v in g.g.items():
        counts[k] = len(v)
    print("tris", sum(counts.values()))
    print(sorted(counts.items(), key=lambda kv: -kv[1])[:12])
