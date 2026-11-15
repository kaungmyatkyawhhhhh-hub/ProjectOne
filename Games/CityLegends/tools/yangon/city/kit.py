"""kit.py: the 1:1 Yangon building kit, pilot (rescale step 2, 2026-11-16; owner: "Everything at player scale").

Six archetypes from the reference pack (vault note '2026-11-16 Research - Yangon building kit references'), modelled in
METRES and written at S studs a metre (3: the cars' and players' scale). Every number below is a real size from that note.
Faces are wound like geom3d (visible from outside). Groups use landmark_glb3d.GROUPS (the K* kit groups).

    python kit.py [out_tris.json]     -> triangles by group for preview3d_blend.py (all six side by side on a street,
                                         with a car and a person for scale)
Each archetype is a function (x0, y0) -> its footprint (W, D) in metres, front on y0 facing -y (the street).
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
g = Geo()
R = random.Random(7)


def m(v):
    return v * S


def box(grp, x, y, z, sx, sy, sz, faces=("+x", "-x", "+y", "-y", "top", "bottom")):
    """An axis box in metres: (x, y, z) = min corner."""
    g.box(grp, m(x + sx / 2), m(y + sy / 2), m(z), m(sx), m(sy), m(sz), 0.0, faces=faces)


def front_quad(grp, x0, x1, z0, z1, y):
    """A rectangle on the plane y (metres), facing -y (the street)."""
    g.quad(grp, (m(x0), m(y), m(z0)), (m(x1), m(y), m(z0)), (m(x1), m(y), m(z1)), (m(x0), m(y), m(z1)))


def cyl(grp, cx, cy, z0, h, r, n=10):
    pts = [(m(cx + r * math.cos(2 * math.pi * k / n)), m(cy + r * math.sin(2 * math.pi * k / n))) for k in range(n)]
    g.ring(grp, pts, m(z0), m(z0 + h))
    g.cap(grp, pts, m(z0 + h))


def bar(grp, a, b, w=0.04):
    g.tube(grp, tuple(m(v) for v in a), tuple(m(v) for v in b), m(w))


def stains(x0, x1, z, y, depth=1.2):
    """Black rain streaks hanging under a ledge (the one detail that makes it Yangon): thin strips in two shades, a
    soft wide one behind a few dark narrow ones, longest where the ledge drips most."""
    x = x0 + R.uniform(0.0, 0.4)
    while x < x1 - 0.15:
        w = R.uniform(0.25, 0.9)
        L = R.uniform(0.4, depth)
        front_quad("KSU", x, min(x1, x + w), z - L, z, y - 0.010)
        for _ in range(R.randint(1, 3)):
            xs = x + R.uniform(0.0, max(0.05, w - 0.08))
            front_quad("KST", xs, min(x1, xs + R.uniform(0.03, 0.12)), z - L * R.uniform(0.6, 1.4), z, y - 0.014)
        x += w + R.uniform(0.1, 1.2)


def ac_unit(x, z, y):
    box("KAC", x, y - 0.35, z, 0.8, 0.3, 0.55)


def laundry(x0, x1, z, y):
    if R.random() < 0.45:
        return
    x = x0 + R.uniform(0, (x1 - x0) * 0.5)
    while x < x1 - 0.3:
        w = R.uniform(0.3, 0.6)
        front_quad(R.choice(["KL1", "KL2", "KL3"]), x, x + w, z - R.uniform(0.5, 0.9), z, y - 0.01)
        x += w + R.uniform(0.05, 0.25)


LIT = 0.22  # share of windows lit at night (tag FacadeNight panes; the vault's night measurements: 15-25%)


def window(x, z, y, w, h, grille=True, shutter=False, awning=None):
    """A window set 0.12 into the wall: dark glass, a frame, an iron grille or teak louvred shutters, maybe a blue
    plastic awning; some are lit at night (a Neon pane just in front of the glass, hidden by day)."""
    front_quad("KGL", x, x + w, z, z + h, y + 0.12)
    if R.random() < LIT:
        front_quad(R.choice(["NWH", "NWH", "NWA", "NWY", "NWC"]), x + 0.03, x + w - 0.03, z + 0.03, z + h - 0.03, y + 0.1)
    if awning or (awning is None and R.random() < 0.25):
        g.quad("KAW", (m(x - 0.15), m(y - 0.7), m(z + h + 0.05)), (m(x + w + 0.15), m(y - 0.7), m(z + h + 0.05)),
               (m(x + w + 0.15), m(y), m(z + h + 0.45)), (m(x - 0.15), m(y), m(z + h + 0.45)))
        g.quad("KAW", (m(x + w + 0.15), m(y - 0.7), m(z + h + 0.05)), (m(x - 0.15), m(y - 0.7), m(z + h + 0.05)),
               (m(x - 0.15), m(y), m(z + h + 0.45)), (m(x + w + 0.15), m(y), m(z + h + 0.45)))
    for (a, b, c, d) in ((x, x + w, z - 0.06, z), (x, x + w, z + h, z + h + 0.06)):
        box("KFR", a, y - 0.02, c, b - a, 0.14, d - c)
    if grille:
        n = max(2, int(w / 0.15))
        for k in range(1, n):
            bar("KGR", (x + w * k / n, y + 0.02, z), (x + w * k / n, y + 0.02, z + h), 0.025)
        for k in (0.33, 0.66):
            bar("KGR", (x, y + 0.02, z + h * k), (x + w, y + 0.02, z + h * k), 0.025)
    if shutter:
        for s, side in ((-1, x), (1, x + w)):
            ang = R.uniform(0.2, 1.2)
            dx, dy = math.cos(ang) * w / 2 * s, -math.sin(ang) * w / 2
            g.quad("KSH", (m(side), m(y), m(z)), (m(side + dx), m(y + dy), m(z)), (m(side + dx), m(y + dy), m(z + h)),
                   (m(side), m(y), m(z + h)))
            g.quad("KSH", (m(side + dx), m(y + dy), m(z)), (m(side), m(y), m(z)), (m(side), m(y), m(z + h)),
                   (m(side + dx), m(y + dy), m(z + h)))


def cage(x, z, y, w, h, depth):
    """A steel balcony cage bolted onto the front (walk-ups): a slab, bars on three sides, a little roof."""
    box("KCO", x, y - depth, z, w, depth, 0.12)
    box("KCO", x, y - depth, z + h - 0.1, w, depth, 0.08)
    n = max(3, int(w / 0.18))
    for k in range(n + 1):
        xx = x + w * k / n
        bar("KCG", (xx, y - depth, z + 0.12), (xx, y - depth, z + h - 0.1), 0.03)
    for zz in (0.12, h * 0.45, h - 0.12):
        bar("KCG", (x, y - depth, z + zz), (x + w, y - depth, z + zz), 0.03)
        bar("KCG", (x, y - depth, z + zz), (x, y, z + zz), 0.03)
        bar("KCG", (x + w, y - depth, z + zz), (x + w, y, z + zz), 0.03)


def roof_clutter(x0, y0, w, d, z, n_tanks=2, dish=True):
    for k in range(n_tanks):
        cx, cy = x0 + 1.0 + k * 1.6, y0 + d - 1.5
        bar("KCG", (cx - 0.5, cy, z), (cx - 0.5, cy, z + 0.8), 0.06)
        bar("KCG", (cx + 0.5, cy, z), (cx + 0.5, cy, z + 0.8), 0.06)
        cyl("KTK", cx, cy, z + 0.8, 1.2, 0.6)
    if dish:
        cx, cy = x0 + w - 1.5, y0 + d * 0.5
        bar("KCG", (cx, cy, z), (cx, cy, z + 1.2), 0.05)
        pts = [(m(cx + 0.9 * math.cos(2 * math.pi * k / 12)), m(cy - 0.3), m(z + 1.6 + 0.9 * math.sin(2 * math.pi * k / 12)))
               for k in range(12)]
        c = (m(cx), m(cy - 0.6), m(z + 1.6))
        for k in range(12):
            g.tri("KDS", c, pts[(k + 1) % 12], pts[k])
            g.tri("KDS", c, pts[k], pts[(k + 1) % 12])


# ------------------------------------------------------------------------------------------------- the archetypes
WALLS = ["KW1", "KW2", "KW3", "KW4", "KW5", "KW6"]


def walkup(x0, y0, bays=4, floors=6, wall=None):
    """Type 2: a 1960s-90s concrete walk-up. Bay 3.0, GF 3.9 (shops), upper 3.0, cages and balconies, tanks on top."""
    BAY, GF, FH, D = 3.0, 3.9, 3.0, 20.0
    wall = wall or R.choice(WALLS)
    W = bays * BAY
    H = GF + FH * (floors - 1)
    box(wall, x0, y0, GF, W, D, H - GF)
    box(R.choice(WALLS), x0, y0, 0, W, D, GF)
    box("KW0", x0 - 0.1, y0 - 0.1, H, W + 0.2, D + 0.2, 0.15)
    for (a, b) in ((x0, x0 + 0.15), (x0 + W - 0.15, x0 + W)):
        box(wall, a, y0, H, b - a, D, 0.9)
    box(wall, x0, y0, H, W, 0.15, 0.9)
    box(wall, x0, y0 + D - 0.15, H, W, 0.15, 0.9)
    # ground floor: shops with roller shutters, a blue awning, a sign band
    for k in range(bays):
        x = x0 + k * BAY
        front_quad("KRS" if k % 2 else "KSI", x + 0.25, x + BAY - 0.25, 0, 2.7, y0 - 0.01)
        box("KAW", x + 0.1, y0 - 1.6, 2.7, BAY - 0.2, 1.6, 0.06)
        front_quad(R.choice(["KS1", "KS2", "KS3"]), x + 0.2, x + BAY - 0.2, 3.0, 3.7, y0 - 0.02)
    for f in range(1, floors):
        z = GF + FH * (f - 1)
        box("KW0", x0 - 0.15, y0 - 0.15, z - 0.12, W + 0.3, 0.3, 0.12)
        stains(x0, x0 + W, z - 0.12, y0, 1.4)
        for k in range(bays):
            x = x0 + k * BAY
            kind = R.random()
            if kind < 0.4:
                cage(x + 0.15, z, y0, BAY - 0.3, FH - 0.2, R.uniform(0.6, 0.9))
                window(x + 0.6, z + 0.9, y0, 1.6, 1.3, grille=False)
                laundry(x + 0.3, x + BAY - 0.3, z + 2.2, y0 - 0.7)
            elif kind < 0.55:
                # an enclosed balcony with horizontal concrete louvres (photo balcony_grilles_grime)
                box(wall, x + 0.1, y0 - 1.0, z, BAY - 0.2, 1.0, 0.15)
                for k2 in range(6):
                    zz = z + 0.3 + k2 * 0.42
                    box(wall, x + 0.1, y0 - 1.05, zz, BAY - 0.2, 0.12, 0.12)
                for (a, b) in ((x + 0.1, x + 0.25), (x + BAY - 0.25, x + BAY - 0.1)):
                    box(wall, a, y0 - 1.0, z + 0.15, b - a, 1.0, FH - 0.3)
                box(wall, x + 0.1, y0 - 1.0, z + FH - 0.3, BAY - 0.2, 1.0, 0.15)
                stains(x + 0.1, x + BAY - 0.1, z, y0 - 1.05, 1.0)
            elif kind < 0.75:
                box(wall, x + 0.1, y0 - 1.1, z, BAY - 0.2, 1.1, 0.15)
                box(wall, x + 0.1, y0 - 1.1, z + 0.15, BAY - 0.2, 0.1, 0.9)
                stains(x + 0.1, x + BAY - 0.1, z, y0 - 1.1, 0.8)
                window(x + 0.6, z + 0.2, y0, 1.6, 2.1, grille=True, awning=False)
                for k2 in range(R.randint(0, 3)):
                    cyl("KPL", x + 0.4 + k2 * 0.7, y0 - 0.8, z + 0.15, 0.5, 0.22, 6)
            else:
                window(x + 0.7, z + 0.9, y0, 1.5, 1.3, grille=True)
                ac_unit(x + 1.0, z + 0.3, y0)
    roof_clutter(x0, y0, W, D, H)
    box("KW0", x0 + W * 0.55, y0 + D * 0.4, H, 3.0, 3.0, 2.6)
    return W, D, H


def township_shop(x0, y0, floors=3, wall=None):
    """Type 3: a township shophouse (Kamayut / Yankin): one plot 5 m wide, GF 3.6 open shop, a big signboard."""
    W, D, GF, FH = 5.0, 18.0, 3.6, 3.1
    wall = wall or R.choice(WALLS)
    H = GF + FH * (floors - 1)
    box(wall, x0, y0, 0, W, D, H)
    box("KW0", x0 - 0.05, y0 - 0.05, H, W + 0.1, D + 0.1, 0.12)
    front_quad("KSI", x0 + 0.2, x0 + W - 0.2, 0, 2.9, y0 - 0.01)
    box(R.choice(["KS1", "KS2"]), x0 - 0.05, y0 - 0.35, 2.9, W + 0.1, 0.25, 1.6)
    box("KAW", x0, y0 - 2.0, 2.6, W, 2.0, 0.05)
    for f in range(1, floors):
        z = GF + FH * (f - 1)
        box("KW0", x0, y0 - 0.12, z - 0.1, W, 0.12, 0.1)
        stains(x0, x0 + W, z - 0.1, y0, 1.0)
        window(x0 + 0.5, z + 0.9, y0, 1.6, 1.3)
        window(x0 + 2.8, z + 0.9, y0, 1.6, 1.3)
        if f == 1:
            box(R.choice(["KS3", "KS1"]), x0 + 0.3, y0 - 0.3, z + 2.3, W - 0.6, 0.2, 0.7)
        else:
            ac_unit(x0 + 3.2, z + 0.3, y0)
    # a rusty corrugated lean-to at the back
    g.quad("KRF", (m(x0), m(y0 + D - 6), m(H + 1.2)), (m(x0 + W), m(y0 + D - 6), m(H + 1.2)), (m(x0 + W), m(y0 + D), m(H + 0.2)),
           (m(x0), m(y0 + D), m(H + 0.2)))
    roof_clutter(x0, y0, W, D - 6, H, n_tanks=1, dish=False)
    return W, D, H


def colonial_row(x0, y0, plots=3):
    """Type 1: a downtown colonial shophouse row: plots 7 m, GF 5.0, upper 3.9 / top 3.4, arched windows with
    teak shutters, balustraded balconies, cornices, a 1.2 parapet; every plot its own colour."""
    PW, D, GF, FH = 7.0, 24.0, 5.0, 3.9
    cols = ["KW1", "KW3", "KW5", "KW6"]
    top = 0.0
    for p in range(plots):
        x = x0 + p * PW
        wall = cols[p % len(cols)]
        floors = 4 if p != 1 else 5
        H = GF + FH * (floors - 1)
        top = max(top, H)
        box(wall, x, y0, 0, PW, D, H)
        box(wall, x, y0, H, PW, 0.3, 1.2)
        box("KW0", x - 0.1, y0 - 0.35, H - 0.4, PW + 0.2, 0.35, 0.4)
        stains(x, x + PW, H - 0.4, y0 - 0.35, 2.5)
        for k in range(3):
            front_quad("KRS" if (k + p) % 2 else "KSI", x + 0.4 + k * 2.2, x + 0.4 + k * 2.2 + 1.9, 0, 3.4, y0 - 0.01)
        box(R.choice(["KS1", "KS2", "KS3"]), x + 0.3, y0 - 0.2, 3.6, PW - 0.6, 0.15, 0.9)
        box("KAW", x, y0 - 1.8, 3.4, PW, 1.8, 0.05)
        for f in range(1, floors):
            z = GF + FH * (f - 1)
            box("KW0", x - 0.1, y0 - 0.25, z - 0.25, PW + 0.2, 0.25, 0.25)
            stains(x, x + PW, z - 0.25, y0 - 0.25, 2.2)
            for k in range(3):
                wx = x + 0.6 + k * 2.2
                window(wx, z + 0.1, y0, 1.15, 2.5, grille=False, shutter=True)
                # an arch over each window
                c = (wx + 0.575, y0 - 0.03)
                pts = [(m(c[0] + 0.62 * math.cos(math.pi * t / 8)), m(c[1]), m(z + 2.6 + 0.45 * math.sin(math.pi * t / 8)))
                       for t in range(9)]
                for t in range(8):
                    g.tri("KW0", pts[t], (m(c[0]), m(c[1]), m(z + 2.6)), pts[t + 1])
            if f % 2 == 1:
                box(wall, x + 0.3, y0 - 1.2, z, PW - 0.6, 1.2, 0.18)
                n = 14
                for k in range(n + 1):
                    bar("KW0", (x + 0.35 + (PW - 0.7) * k / n, y0 - 1.15, z + 0.18), (x + 0.35 + (PW - 0.7) * k / n, y0 - 1.15, z + 1.0), 0.07)
                bar("KW0", (x + 0.35, y0 - 1.15, z + 1.0), (x + PW - 0.35, y0 - 1.15, z + 1.0), 0.1)
                laundry(x + 0.6, x + PW - 0.6, z + 2.4, y0 - 1.0)
        roof_clutter(x, y0, PW, D, H, n_tanks=1, dish=(p == 0))
    return PW * plots, D, top


def villa(x0, y0):
    """Type 4: a walled villa (Bahan / Golden Valley): plot 24 x 30, a 2.1 m wall with a 5 m gate and pillars, a house
    12 x 10 on a 0.7 m base, two floors of 3.5, a veranda, a hipped red roof with 1 m eaves."""
    PW, PD = 24.0, 30.0
    WALL_H = 2.1
    gx0, gx1 = x0 + 9.5, x0 + 14.5
    for (a, b) in ((x0, gx0), (gx1, x0 + PW)):
        box("KW6", a, y0, 0, b - a, 0.25, WALL_H)
        box("KW0", a - 0.05, y0 - 0.05, WALL_H, b - a + 0.1, 0.35, 0.12)
        stains(a, b, WALL_H, y0 - 0.05, 0.9)
    for (a, b) in ((x0, x0 + 0.25), (x0 + PW - 0.25, x0 + PW)):
        box("KW6", a, y0, 0, b - a, PD, WALL_H)
    box("KW6", x0, y0 + PD - 0.25, 0, PW, 0.25, WALL_H)
    for px in (gx0 - 0.6, gx1):
        box("KW6", px, y0 - 0.1, 0, 0.6, 0.6, 2.8)
        box("KW0", px - 0.1, y0 - 0.2, 2.8, 0.8, 0.8, 0.25)
        cyl("KW0", px + 0.3, y0 + 0.2, 3.05, 0.35, 0.18, 8)
    front_quad("KGT", gx0, gx1, 0.05, 2.4, y0 + 0.1)
    for k in range(26):
        xx = gx0 + 5.0 * k / 25
        bar("KGT", (xx, y0 + 0.08, 0.05), (xx, y0 + 0.08, 2.5 + 0.15 * math.sin(math.pi * k / 25)), 0.03)
    box("KPV", x0 + 0.25, y0 + 0.25, 0, PW - 0.5, PD - 0.5, 0.03, faces=("top",))
    # the house
    hx, hy, HW, HD, BASE, FH = x0 + 6.0, y0 + 11.0, 12.0, 10.0, 0.7, 3.5
    box("KW0", hx - 0.2, hy - 0.2, 0, HW + 0.4, HD + 0.4, BASE)
    box("KW1", hx, hy, BASE, HW, HD, 2 * FH)
    box("KW0", hx - 0.15, hy - 0.15, BASE + FH - 0.15, HW + 0.3, HD + 0.3, 0.15)
    for f in range(2):
        z = BASE + f * FH
        for k in range(3):
            window(hx + 0.9 + k * 3.9, z + 0.85, hy, 1.3, 1.6, grille=(f == 0))
    # veranda on 4 posts under a flat roof, steps
    box("KW0", hx + 3.5, hy - 2.5, BASE + 2.9, 5.0, 2.5, 0.18)
    for px in (hx + 3.6, hx + 8.3):
        box("KW0", px, hy - 2.4, BASE, 0.2, 0.2, 2.9)
    box("KW0", hx + 4.5, hy - 3.4, 0, 3.0, 0.9, 0.35)
    # hipped roof, eaves 1 m
    z = BASE + 2 * FH
    e = 1.0
    A, B, C, Dd = (hx - e, hy - e), (hx + HW + e, hy - e), (hx + HW + e, hy + HD + e), (hx - e, hy + HD + e)
    rise = (HD / 2 + e) * 0.55
    r0, r1 = (hx + HD / 2 + e - e, hy + HD / 2, z + rise), (hx + HW - HD / 2, hy + HD / 2, z + rise)
    P = [(m(p[0]), m(p[1]), m(z)) for p in (A, B, C, Dd)]
    R0, R1 = tuple(m(v) for v in r0), tuple(m(v) for v in r1)
    g.quad("KRT", P[0], P[1], R1, R0)
    g.tri("KRT", P[1], P[2], R1)
    g.quad("KRT", P[2], P[3], R0, R1)
    g.tri("KRT", P[3], P[0], R0)
    g.ring("KW0", [(m(p[0]), m(p[1])) for p in (A, B, C, Dd)], m(z - 0.3), m(z))
    g.cap("KW0", [(m(p[0]), m(p[1])) for p in (A, B, C, Dd)], m(z - 0.3), down=True)
    return PW, PD, z + rise


def condo(x0, y0, floors=15):
    """Type 5: a modern condo: 16 x 24, a 2-floor podium of 4.2, upper floors 3.1 with balconies and glass rails,
    a crown frame."""
    W, D, PF, FH = 16.0, 24.0, 4.2, 3.1
    box("KW0", x0, y0, 0, W, D, 2 * PF)
    front_quad("KGL", x0 + 1, x0 + W - 1, 0.3, 2 * PF - 0.6, y0 - 0.01)
    H = 2 * PF + FH * (floors - 2)
    box("KW5", x0 + 1, y0 + 1, 2 * PF, W - 2, D - 2, H - 2 * PF)
    for f in range(floors - 2):
        z = 2 * PF + f * FH
        front_quad("KGL", x0 + 1.4, x0 + W - 1.4, z + 0.8, z + 2.9, y0 + 0.99)
        box("KW0", x0 + 1, y0 - 0.4, z, W - 2, 1.4, 0.2)
        front_quad("KRL", x0 + 1, x0 + W - 1, z + 0.2, z + 1.2, y0 - 0.41)
        for k in range(4):
            ac_unit(x0 + 2 + k * 3.6, z + 0.25, y0 + 0.6)
    box("KW0", x0 + 1, y0 + 1, H, W - 2, D - 2, 0.3)
    for (a, b) in ((x0 + 1, x0 + 1.6), (x0 + W - 1.6, x0 + W - 1)):
        box("KW0", a, y0 + 1, H, b - a, 0.6, 4.0)
    box("KW0", x0 + 1, y0 + 1, H + 3.6, W - 2, 0.6, 0.6)
    return W, D, H + 4.2


def market(x0, y0):
    """Type 6: a market shed: 20 x 30, posts every 4.5, eaves 4.5, a corrugated gable roof, stalls with umbrellas."""
    W, D, E = 20.0, 30.0, 4.5
    for i in range(5):
        for j in range(7):
            px, py = x0 + i * W / 4, y0 + j * D / 6
            box("KCO", px - 0.15, py - 0.15, 0, 0.3, 0.3, E)
    ridge = E + 2.5
    g.quad("KRF", (m(x0 - 1), m(y0 - 1), m(E)), (m(x0 + W / 2), m(y0 - 1), m(ridge)), (m(x0 + W / 2), m(y0 + D + 1), m(ridge)),
           (m(x0 - 1), m(y0 + D + 1), m(E)))
    g.quad("KRF", (m(x0 + W / 2), m(y0 - 1), m(ridge)), (m(x0 + W + 1), m(y0 - 1), m(E)), (m(x0 + W + 1), m(y0 + D + 1), m(E)),
           (m(x0 + W / 2), m(y0 + D + 1), m(ridge)))
    for (a, b) in ((x0 - 1, x0 + W / 2), (x0 + W / 2, x0 + W + 1)):
        za, zb = (E, ridge) if a < x0 else (ridge, E)
        g.quad("KRF", (m(b), m(y0 - 1), m(zb)), (m(a), m(y0 - 1), m(za)), (m(a), m(y0 + D + 1), m(za)), (m(b), m(y0 + D + 1), m(zb)))
    for i in range(4):
        for j in range(5):
            sx, sy = x0 + 1.5 + i * 4.7, y0 + 2 + j * 5.5
            box("KWD", sx, sy, 0, 3.0, 1.4, 0.85)
            for k in range(4):
                box(R.choice(["KL1", "KL2", "KL3", "KS2"]), sx + 0.2 + k * 0.7, sy + 0.2, 0.85, 0.5, 1.0, 0.25)
    for k in range(5):
        cx, cy = x0 + 2 + k * 4.0, y0 - 2.0
        bar("KCG", (cx, cy, 0), (cx, cy, 2.3), 0.04)
        pts = [(m(cx + 1.2 * math.cos(2 * math.pi * t / 8)), m(cy + 1.2 * math.sin(2 * math.pi * t / 8)), m(2.1)) for t in range(8)]
        top = (m(cx), m(cy), m(2.6))
        col = R.choice(["KS1", "KS3", "KL2", "KAW"])
        for t in range(8):
            g.tri(col, pts[t], pts[(t + 1) % 8], top)
            g.tri(col, pts[(t + 1) % 8], pts[t], top)
    return W, D, ridge


def car(x, y):
    """A car for scale: 4.5 x 1.8 x 1.45 m."""
    box("KCR", x, y, 0.25, 4.5, 1.8, 0.75)
    box("KGL", x + 1.1, y + 0.1, 1.0, 2.3, 1.6, 0.45)
    for (cx, cy) in ((x + 0.8, y), (x + 3.7, y), (x + 0.8, y + 1.8), (x + 3.7, y + 1.8)):
        cyl("KTY", cx, cy, 0, 0.0001, 0.01)
        box("KTY", cx - 0.32, cy - 0.12, 0, 0.64, 0.24, 0.64)


def person(x, y):
    """A person for scale: 1.75 m."""
    cyl("KL2", x, y, 0.0, 0.85, 0.16, 8)
    cyl("KL1", x, y, 0.85, 0.6, 0.2, 8)
    cyl("KSK", x, y, 1.47, 0.28, 0.11, 8)


def scene():
    """The six types side by side along a street (the street is y < 0), a car and a person in front of each."""
    g.cap("KRD", [(m(-10), m(-12)), (m(260), m(-12)), (m(260), m(0)), (m(-10), m(0))], 0.0)
    g.cap("KPV", [(m(-10), m(-3.2)), (m(260), m(-3.2)), (m(260), m(0)), (m(-10), m(0))], m(0.15))
    out = {}
    x = 0.0
    for name, fn in (("colonial_row", colonial_row), ("township_shop", township_shop), ("walkup", walkup),
                     ("villa", villa), ("condo", condo), ("market", market)):
        Wd, Dd, Hh = fn(x, 0.0)
        out[name] = {"x": x, "w": Wd, "d": Dd, "h": Hh}
        car(x + 1.0, -9.0)
        person(x + 2.5, -2.0)
        x += Wd + 6.0
    return out


if __name__ == "__main__":
    info = scene()
    path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "..", "build", "kit", "kit_pilot_tris.json")
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    json.dump({k: v for k, v in g.g.items()}, open(path, "w"))
    json.dump(info, open(path.replace("_tris.json", "_info.json"), "w"), indent=1)
    print(info)
    print("tris", sum(len(v) for v in g.g.values()))
