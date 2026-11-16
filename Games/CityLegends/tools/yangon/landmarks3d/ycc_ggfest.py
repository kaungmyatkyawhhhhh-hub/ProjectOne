"""ycc_ggfest.py (2026-11-17): the Yangon Convention Centre (YCC) at 1:1, with the GG Gaming Fest dressing (21-22 Nov 2026).

    python tools/yangon/landmarks3d/ycc_ggfest.py          (from Games/CityLegends)

Where: the empty landmark lot "inya_lake_hotel" in P2 (buildings_1to1 LANDMARK_SITES_BY_TAG). The hall is OSM way/522822402
(172 x 62 m, 2 levels in OSM), its rectangle fitted from the outline. The Inya Lake Hotel block itself (OSM 216882182) lies
west of the lot and is already a kit building, so it is not rebuilt here.
Look, from the photos (yangoncc.com gallery via image search, 17 Nov; reference only, nothing copied into the game):
  * one long hall under a single white barrel-vault roof spanning the short side, arched gable ends (aerial photo)
  * long sides: a low glass curtain wall, grey metal cladding above, the roof sweeping down past the wall
  * the north-east side: a drop-off canopy along the drive ("Drop Off" signs), a white slanted name monolith
  * inside (exhibition photos): curved steel arch trusses, grey metal deck ceiling, high-bay lamps, polished concrete
    floor, red carpet aisles, white shell-scheme booths. Cvent: 3 halls of 56 x 53 m, 10,000 sq m: one open hall here.
GG Gaming Fest dressing (real names as plain text only, no GG logo artwork): banners, an outdoor LED screen, a stage
with an LED wall, the zones GG ARCADE / GG QUEST / GG COSPLAY / GG ESPORTS, a photo spot in front of the stage.
Text goes on SurfaceGuis (place.json "signs"); screens tagged GGFestScreen are written by server/GGFest.lua.
Cars drive in through 3 doors on the north-east side (the floor is level with the forecourt).
Outputs: imports/sync/landmarks/ycc_ggfest.glb + build/landmarks/ycc_ggfest/place.json -> YccPlace.luau in Studio.
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
os.environ.setdefault("YANGON_SCALE", "1to1")
import numpy as np  # noqa: E402

import dt_landmarks as DT  # noqa: E402
from dt_landmarks import Scene, Frame, S, LOOKS, cylinder, up_quad, down_quad  # noqa: E402
import geo  # noqa: E402

LID = "ycc_ggfest"

# hall rectangle (world studs) from OSM way/522822402: A west, B north, C east, D south corner
A, B, C, D = (33412.5, 21916.6), (33537.9, 21779.2), (33922.3, 22124.8), (33797.9, 22263.2)
O = ((A[0] + B[0] + C[0] + D[0]) / 4, (A[1] + B[1] + C[1] + D[1]) / 4)
_l = math.hypot(C[0] - B[0], C[1] - B[1])
AX = ((C[0] - B[0]) / _l, (C[1] - B[1]) / _l)          # u: along the hall, north-west -> south-east
_w = math.hypot(B[0] - A[0], B[1] - A[1])
NE = ((B[0] - A[0]) / _w, (B[1] - A[1]) / _w)           # v: across, + = the north-east (entrance) side
L2 = _l / S / 2      # 86.2 m
W2 = _w / S / 2      # 31.0 m

# the vault: a circular arc across v, crown 15 m, 6.5 m at the eaves (3 m past the walls)
VO = W2 + 3.0
CROWN = 15.0
SAG = CROWN - 6.5
R = (VO * VO + SAG * SAG) / (2 * SAG)
YC = CROWN - R
ROOF_T = 0.5
NSEG = 18

DOORS_NE = (-55.0, 0.0, 55.0)
DOOR_W, DOOR_H = 9.0, 5.5

LOOKS.update({
    "FLR": ("SmoothPlastic", (150, 152, 150), 0.0, 0.04, None, False, None),   # polished concrete floor
    "CLD": ("SmoothPlastic", (196, 200, 204), 0.0, 0.02, None, True, None),    # grey metal cladding
    "GLB": ("SmoothPlastic", (46, 64, 82), 0.0, 0.22, None, True, None),       # curtain wall glass (opaque, reflective)
    "MUL": ("SmoothPlastic", (70, 74, 80), 0.0, 0.0, None, True, None),        # mullions, door frames
    "RFW": ("SmoothPlastic", (238, 240, 242), 0.0, 0.04, None, True, None),    # white vault roof, canopy, fascia
    "DCK": ("SmoothPlastic", (150, 156, 162), 0.0, 0.0, None, False, None),    # metal deck ceiling / soffit
    "STL": ("SmoothPlastic", (104, 112, 122), 0.0, 0.0, None, False, None),    # arch trusses, columns
    "INW": ("SmoothPlastic", (214, 216, 218), 0.0, 0.0, None, False, None),    # inside wall lining
    "PLN": ("SmoothPlastic", (176, 174, 168), 0.0, 0.0, None, False, None),    # plinth, kerbs, skirts
    "ASP": ("Asphalt", (84, 86, 88), 0.0, 0.0, None, False, None),             # forecourt drive
    "LNW": ("SmoothPlastic", (236, 236, 230), 0.0, 0.0, None, False, None),    # white road lines
    "SGW": ("SmoothPlastic", (246, 246, 244), 0.0, 0.0, None, True, None),     # the name monolith
    # festival (vivid, clean)
    "RCP": ("SmoothPlastic", (186, 28, 40), 0.0, 0.0, None, False, None),      # red carpet aisle
    "CYN": ("SmoothPlastic", (0, 196, 228), 0.0, 0.0, None, True, None),
    "MAG": ("SmoothPlastic", (236, 38, 150), 0.0, 0.0, None, True, None),
    "YLW": ("SmoothPlastic", (255, 204, 0), 0.0, 0.0, None, True, None),
    "PUR": ("SmoothPlastic", (176, 60, 220), 0.0, 0.0, None, True, None),
    "GRN": ("SmoothPlastic", (40, 206, 120), 0.0, 0.0, None, True, None),
    "BLK": ("SmoothPlastic", (34, 36, 42), 0.0, 0.0, None, True, None),
    "WHT": ("SmoothPlastic", (245, 245, 245), 0.0, 0.0, None, True, None),
    "SCR": ("SmoothPlastic", (16, 18, 24), 0.0, 0.1, None, False, None),      # screens (text on SurfaceGuis)
    "NCY": ("Neon", (0, 150, 190), 0.0, 0.0, None, False, None),              # neon edges (dimmed: Neon blooms)
    "NMG": ("Neon", (200, 40, 170), 0.0, 0.0, None, False, None),
    "LMP": ("Neon", (196, 190, 170), 0.0, 0.0, None, False, None),            # high-bay lamps
    "CMG": ("SmoothPlastic", (150, 40, 120), 0.0, 0.0, None, False, None),    # zone carpets
    "CBL": ("SmoothPlastic", (30, 60, 150), 0.0, 0.0, None, False, None),
    "CPU": ("SmoothPlastic", (84, 44, 160), 0.0, 0.0, None, False, None),
    "CTL": ("SmoothPlastic", (0, 120, 120), 0.0, 0.0, None, False, None),
    "CGR": ("SmoothPlastic", (64, 66, 72), 0.0, 0.0, None, False, None),
})

# ------------------------------------------------------------------------------------------ ground
_st = np.load(os.path.join(geo.BUILD, "city_1to1", "terrain_P2_state.npz"))
_H, _ORG = _st["H"], _st["origin"]


def ground(x, z):
    return float(_H[int((x - _ORG[0]) / 4), int((z - _ORG[1]) / 4)])


def W0(u, v):
    """(u, v) metres -> world (X, Z)"""
    return (O[0] + (AX[0] * u + NE[0] * v) * S, O[1] + (AX[1] * u + NE[1] * v) * S)


# the floor: level with the forecourt at the doors (the ground falls ~1.4 m to the south-east)
_door_g = [ground(*W0(u, v)) for u in DOORS_NE for v in (W2 + 2, W2 + 10)]
FY = round(max(_door_g) + 0.3, 2)


def yarc(v):
    """roof top over the floor (m) at v"""
    return YC + math.sqrt(max(0.0, R * R - v * v))


def build():
    sc = Scene()
    F = Frame(sc, O, AX, NE, FY)
    boxes, signs, lights, clears, fills = [], [], [], [], []

    def sign(u, v, y, nu, nv, w, h, text, fg=(255, 255, 255), bg=None, tag=None, font="GothamBlack", name="Sign"):
        x, yy, z = F.W(u, v, y)
        n = (AX[0] * nu + NE[0] * nv, AX[1] * nu + NE[1] * nv)
        signs.append(dict(p=[round(x, 2), round(yy, 2), round(z, 2)], n=[round(n[0], 4), round(n[1], 4)], w=round(w * S, 2),
                          h=round(h * S, 2), text=text, fg=list(fg), bg=list(bg) if bg else None, tag=tag, font=font, name=name))

    def light(u, v, y, rng=60, br=1.2):
        x, yy, z = F.W(u, v, y)
        lights.append([round(x, 2), round(yy, 2), round(z, 2), rng, br])

    def wall(look, u0, u1, v, y0, y1, out):
        """a wall face at v from u0 to u1, showing toward v + out"""
        F.wq(look, u0, v, u1, v, y0, y1, inside=((u0 + u1) / 2, v + out * 50))

    def endwall(look, u, v0, v1, y0, y1, out):
        F.wq(look, u, v0, u, v1, y0, y1, inside=(u + out * 50, (v0 + v1) / 2))

    # ------------------------------------------------------------------ the roof (vault)
    vs = [-VO + 2 * VO * k / NSEG for k in range(NSEG + 1)]
    U0, U1 = -L2 - 2.0, L2 + 2.0
    for k in range(NSEG):
        va, vb = vs[k], vs[k + 1]
        ya, yb = yarc(va), yarc(vb)
        up_quad(sc, "RFW", F.W(U0, va, ya), F.W(U1, va, ya), F.W(U1, vb, yb), F.W(U0, vb, yb))
        down_quad(sc, "DCK", F.W(U0, va, ya - ROOF_T), F.W(U1, va, ya - ROOF_T), F.W(U1, vb, yb - ROOF_T), F.W(U0, vb, yb - ROOF_T))
        for uu, out in ((U0, -1), (U1, 1)):   # the arched end edges (white fascia)
            q = [F.W(uu, va, ya - ROOF_T - 0.3), F.W(uu, vb, yb - ROOF_T - 0.3), F.W(uu, vb, yb), F.W(uu, va, ya)]
            DT.side_quad(sc, "RFW", *q, away=F.XZ(uu - out * 10, (va + vb) / 2))
    for vv, out in ((-VO, -1), (VO, 1)):       # the long edges: a 0.8 m white fascia
        y = yarc(vv)
        F.wq("RFW", U0, vv, U1, vv, y - ROOF_T - 0.8, y, inside=(0, vv + out * 50))
        F.hq("RFW", U0, vv, U1, vv - out * 0.25, y - ROOF_T - 0.8, up=False)
        F.wq("DCK", U0, vv - out * 0.25, U1, vv - out * 0.25, y - ROOF_T - 0.8, y - ROOF_T, inside=(0, 0))
    yw = yarc(W2) - ROOF_T          # the long walls run up to the roof's underside: 7.5 m

    # ------------------------------------------------------------------ long walls
    def long_wall(v, out, doors):
        segs, u = [], -L2
        for d in sorted(doors):
            segs.append((u, d - DOOR_W / 2))
            u = d + DOOR_W / 2
        segs.append((u, L2))
        vin = v - out * 0.3
        for a_, b_ in segs:
            wall("PLN", a_, b_, v, -3.0, 0.0, out)                 # plinth below the floor
            wall("GLB", a_, b_, v, 0.0, 4.6, out)                  # glass curtain wall
            wall("CLD", a_, b_, v, 4.6, yw, out)                   # cladding band
            wall("INW", a_, b_, vin, 0.0, yw, -out)                # inside lining
            n = int((b_ - a_) / 3.0)
            for i in range(1, n + 1):                              # mullions every ~3 m, 0.12 m proud
                um = a_ + (b_ - a_) * i / (n + 1)
                F.bx("MUL", um, v + out * 0.08, 0.0, 0.14, 0.16, 4.6)
            F.bx("MUL", (a_ + b_) / 2, v + out * 0.09, 4.52, b_ - a_, 0.18, 0.16)   # transom under the cladding
            F.cb(boxes, (a_ + b_) / 2, v - out * 0.15, -3.0, b_ - a_, 0.3, yw + 3.0)
        for d in doors:                                            # door openings: frame, head, soffit
            a_, b_ = d - DOOR_W / 2, d + DOOR_W / 2
            wall("CLD", a_, b_, v, DOOR_H, yw, out)
            wall("INW", a_, b_, vin, DOOR_H, yw, -out)
            F.hq("MUL", a_, vin, b_, v, DOOR_H, up=False)
            for uu, s in ((a_, 1), (b_, -1)):
                endwall("MUL", uu, vin, v, 0.0, DOOR_H, s)
            F.hq("FLR", a_, vin, b_, v, 0.0)
            F.cb(boxes, d, v - out * 0.15, DOOR_H, DOOR_W, 0.3, yw - DOOR_H)
            # a dark frame round the opening, 0.2 m proud
            F.bx("MUL", a_ - 0.15, v + out * 0.12, 0.0, 0.3, 0.24, DOOR_H + 0.3)
            F.bx("MUL", b_ + 0.15, v + out * 0.12, 0.0, 0.3, 0.24, DOOR_H + 0.3)
            F.bx("MUL", d, v + out * 0.12, DOOR_H, DOOR_W + 0.6, 0.24, 0.3)

    long_wall(W2, 1, DOORS_NE)
    long_wall(-W2, -1, ())

    # ------------------------------------------------------------------ gable ends (walls up to the vault)
    vw = [v for v in vs if abs(v) < W2] + [-W2, W2]
    vw = sorted(set(round(v, 4) for v in vw))
    for uu, out in ((-L2, -1), (L2, 1)):
        uin = uu - out * 0.3
        endwall("PLN", uu, -W2, W2, -3.0, 0.0, out)
        endwall("GLB", uu, -W2, W2, 0.0, 4.6, out)
        endwall("INW", uin, -W2, W2, 0.0, 4.6, -out)
        for i in range(len(vw) - 1):
            va, vb = vw[i], vw[i + 1]
            ya, yb = yarc(va) - ROOF_T, yarc(vb) - ROOF_T
            for look, u_, o_ in (("CLD", uu, out), ("INW", uin, -out)):
                q = [F.W(u_, va, 4.6), F.W(u_, vb, 4.6), F.W(u_, vb, yb), F.W(u_, va, ya)]
                DT.side_quad(sc, look, *q, away=F.XZ(u_ - o_ * 10, (va + vb) / 2))
        n = 20
        for i in range(1, n):
            vm = -W2 + 2 * W2 * i / n
            F.bx("MUL", uu + out * 0.08, vm, 0.0, 0.16, 0.14, 4.6)
        F.cb(boxes, uu - out * 0.15, 0.0, -3.0, 0.3, 2 * W2, yw + 3.0)

    # ------------------------------------------------------------------ inside: floor, trusses, columns, lamps
    F.hq("FLR", -L2 + 0.3, -W2 + 0.3, L2 - 0.3, W2 - 0.3, 0.0)
    F.cb(boxes, 0.0, 0.0, -2.0, 2 * L2, 2 * W2, 2.0)
    clears.append(_box(F, 0.0, 0.0, -1.25, 2 * L2 + 1, 2 * W2 + 1, 21.2))   # smooth terrain bulges ~2 studs: keep it 4 under
    fills.append(_box(F, 0.0, 0.0, -4.0, 2 * L2, 2 * W2, 2.67))
    TW, TD = 0.3, 1.1
    ut = [-L2 + 6 + 8 * k for k in range(int((2 * L2 - 12) / 8) + 1)]
    vin = W2 - 0.3
    vt = [v for v in vs if abs(v) < vin - 0.5]
    vt = [-(vin - 0.5)] + vt + [vin - 0.5]
    for u in ut:
        for i in range(len(vt) - 1):
            va, vb = vt[i], vt[i + 1]
            ta, tb = yarc(va) - ROOF_T - 0.02, yarc(vb) - ROOF_T - 0.02
            for uu, s in ((u - TW / 2, -1), (u + TW / 2, 1)):
                q = [F.W(uu, va, ta - TD), F.W(uu, vb, tb - TD), F.W(uu, vb, tb), F.W(uu, va, ta)]
                DT.side_quad(sc, "STL", *q, away=F.XZ(uu - s * 10, (va + vb) / 2))
            down_quad(sc, "STL", F.W(u - TW / 2, va, ta - TD), F.W(u + TW / 2, va, ta - TD), F.W(u + TW / 2, vb, tb - TD),
                      F.W(u - TW / 2, vb, tb - TD))
        for vc in (-(vin - 0.5), vin - 0.5):                       # columns under the truss ends
            F.bx("STL", u, vc - math.copysign(0.0, vc), 0.0, 0.5, 0.5, yarc(vc) - ROOF_T - TD - 0.02)
        for vl in (-14.0, 0.0, 14.0):                              # high-bay lamps
            F.bx("LMP", u, vl, yarc(vl) - ROOF_T - TD - 0.5, 0.7, 0.7, 0.3, bottom=True)
    for u in (-70, -45, -20, 5, 30, 55, 76):
        for vl in (-14.0, 14.0):
            light(u, vl, 9.0, 60, 1.1)

    # ------------------------------------------------------------------ forecourt + drop-off canopy (north-east)
    FC0, FC1 = W2, W2 + 22.0
    # (the south-east end stops at the hall's end: its ramp must stay 3 m off U Tun Nyein Street's kerb, measured in Studio)
    UF0, UF1 = -L2 - 6.0, L2
    RAMP_END = {1: 99.5}
    F.hq("ASP", UF0, FC0, UF1, FC1, 0.0)
    for uu, out in ((UF0, -1), (UF1, 1)):
        endwall("PLN", uu, FC0, FC1, -3.0, 0.0, out)
    wall("PLN", UF0, UF1, FC1, -3.0, 0.0, 1)
    F.cb(boxes, 0.0, (FC0 + FC1) / 2, -2.0, UF1 - UF0, FC1 - FC0, 2.0)
    clears.append(_box(F, 0.0, (FC0 + FC1) / 2, -1.25, UF1 - UF0 + 1, FC1 - FC0 + 1, 13.2))
    fills.append(_box(F, 0.0, (FC0 + FC1) / 2, -4.0, UF1 - UF0, FC1 - FC0, 2.67))
    # lines: the drive's edge (broken at the doors), the bays
    door_gaps = [(d - DOOR_W / 2 - 1, d + DOOR_W / 2 + 1) for d in DOORS_NE]
    u = UF0 + 2
    for a_, b_ in door_gaps + [(UF1 - 2, UF1)]:
        if a_ > u:
            F.bx("LNW", (u + a_) / 2, W2 + 3.2, 0.0, a_ - u, 0.15, 0.02)
        u = b_
    F.bx("LNW", 0.0, W2 + 13.5, 0.0, UF1 - UF0 - 4, 0.15, 0.02)
    for k in range(int((UF1 - UF0 - 8) / 2.6)):
        F.bx("LNW", UF0 + 4 + 2.6 * k, FC1 - 3.0, 0.0, 0.12, 5.4, 0.02)
    # ramps down to the ground at both ends of the forecourt
    for uu, s in ((UF0, -1), (UF1, 1)):
        g = min(ground(*W0(uu + s * 18, v)) for v in (FC0 + 2, FC1 - 2))
        drop = (FY - g) / S + 0.15
        if drop > 0.05:
            ln = max(6.0, drop * 9)
            if s in RAMP_END:
                ln = RAMP_END[s] - uu
            p0, p1 = F.W(uu, FC0, 0.0), F.W(uu + s * ln, FC0, -drop)
            p2, p3 = F.W(uu + s * ln, FC1, -drop), F.W(uu, FC1, 0.0)
            up_quad(sc, "ASP", p0, p1, p2, p3)
            for vv, o in ((FC0, -1), (FC1, 1)):
                q = [F.W(uu, vv, -3.0), F.W(uu + s * ln, vv, -3.0), F.W(uu + s * ln, vv, -drop), F.W(uu, vv, 0.0)]
                DT.side_quad(sc, "PLN", *q, away=F.XZ(uu + s * ln / 2, vv - o * 10))
            c = F.W(uu + s * ln / 2, (FC0 + FC1) / 2, -drop / 2 - 1.0)
            pitch = math.atan2(drop, ln) * s
            boxes.append([c[0], c[1], c[2], math.hypot(ln, drop) * S, 2.0 * S, (FC1 - FC0) * S, -F.yaw, pitch])
    # the canopy: a white slab sweeping down over the drive, on white posts every 12 m
    CU0, CU1, CV0, CV1 = -64.0, 64.0, VO - 0.4, W2 + 12.0
    ca, cb_ = yarc(VO) - 0.6, 5.2
    up_quad(sc, "RFW", F.W(CU0, CV0, ca), F.W(CU1, CV0, ca), F.W(CU1, CV1, cb_), F.W(CU0, CV1, cb_))
    down_quad(sc, "DCK", F.W(CU0, CV0, ca - 0.35), F.W(CU1, CV0, ca - 0.35), F.W(CU1, CV1, cb_ - 0.35), F.W(CU0, CV1, cb_ - 0.35))
    F.wq("RFW", CU0, CV1, CU1, CV1, cb_ - 0.35, cb_, inside=(0, 100))
    for uu, s in ((CU0, -1), (CU1, 1)):
        q = [F.W(uu, CV0, ca - 0.35), F.W(uu, CV1, cb_ - 0.35), F.W(uu, CV1, cb_), F.W(uu, CV0, ca)]
        DT.side_quad(sc, "RFW", *q, away=F.XZ(uu - s * 10, (CV0 + CV1) / 2))
    for k in range(11):
        uu = CU0 + 4 + 12 * k
        if any(abs(uu - d) < DOOR_W / 2 + 3 for d in DOORS_NE):
            uu += 6
        F.bx("RFW", uu, CV1 - 0.6, 0.0, 0.4, 0.4, cb_ - 0.35)
        F.cb(boxes, uu, CV1 - 0.6, 0.0, 0.5, 0.5, cb_ - 0.35)

    # ------------------------------------------------------------------ the name monolith (white, slanted top)
    mu, mv = L2 + 1.0, FC1 + 3.0
    a0, a1, b0, b1 = mu - 2.5, mu + 2.5, mv - 0.5, mv + 0.5
    hi, lo = 3.2, 1.0
    corners = [(a0, b0, lo), (a1, b0, hi), (a1, b1, hi), (a0, b1, lo)]
    top = [F.W(u_, v_, y_) for u_, v_, y_ in corners]
    bot = [F.W(u_, v_, 0.0 - 1.0) for u_, v_, _ in corners]
    up_quad(sc, "SGW", *top)
    for i in range(4):
        q = [bot[i], bot[(i + 1) % 4], top[(i + 1) % 4], top[i]]
        DT.side_quad(sc, "SGW", *q, away=F.XZ(mu, mv))
    F.cb(boxes, mu, mv, -1.0, 5.0, 1.0, 4.0)
    sign(mu, b1 + 0.03, 0.35, 0, 1, 4.4, 0.9, "YANGON\nCONVENTION CENTRE", fg=(28, 30, 34), font="GothamBold", name="YccName")
    fills.append(_box(F, mu, mv, -4.0, 6.0, 2.0, 3.0))

    # ------------------------------------------------------------------ GGFest outside: facade banners, flags, LED screen
    for d in DOORS_NE:                     # a banner on the cladding over each door
        bw = 22.0 if d == 0.0 else 14.0
        F.bx("MAG", d, W2 + 0.02, DOOR_H + 0.55, bw, 0.1, 1.5)
        sign(d, W2 + 0.13, DOOR_H + 0.6, 0, 1, bw - 0.4, 1.4,
             "GG GAMING FEST  ·  21-22 NOV" if d == 0.0 else "GG GAMING FEST", fg=(255, 255, 255), name="FacadeBanner")
    cols = ("CYN", "MAG", "YLW", "PUR")
    for k in range(14):                    # feather flags along the forecourt's far edge
        uu = UF0 + 6 + k * (UF1 - UF0 - 12) / 13
        vv = FC1 - 0.8
        F.bx("WHT", uu, vv, 0.0, 0.1, 0.1, 5.2)
        F.bx(cols[k % 4], uu + 0.4, vv, 1.6, 0.7, 0.04, 3.4)
    # festival gateways over the drive at both ends of the forecourt: two truss towers and a lit header
    for gu, face in ((UF0 + 3.0, -1), (UF1 - 3.0, 1)):
        for gv in (FC0 + 1.5, FC1 - 1.5):
            F.bx("BLK", gu, gv, 0.0, 1.0, 1.0, 7.6)
            F.bx("NCY" if face < 0 else "NMG", gu + face * 0.52, gv, 0.3, 0.04, 0.3, 7.0)
            F.cb(boxes, gu, gv, 0.0, 1.0, 1.0, 7.6)
        F.bx("BLK", gu, (FC0 + FC1) / 2, 7.6, 1.0, FC1 - FC0 - 2.0, 2.2)
        F.bx("MAG" if face < 0 else "PUR", gu + 0.52, (FC0 + FC1) / 2, 7.75, 0.04, FC1 - FC0 - 3.0, 1.9)
        F.bx("MAG" if face < 0 else "PUR", gu - 0.52, (FC0 + FC1) / 2, 7.75, 0.04, FC1 - FC0 - 3.0, 1.9)
        for s_ in (1, -1):
            sign(gu + s_ * 0.56, (FC0 + FC1) / 2, 7.8, s_, 0, FC1 - FC0 - 3.4, 1.8, "GG GAMING FEST  ·  21-22 NOV", name="Gateway")
    # outdoor LED screen on two legs, beyond the bays, facing the hall
    su, sv = -12.0, FC1 + 4.0
    F.bx("BLK", su - 5.6, sv, -1.0, 0.5, 0.5, 4.0)
    F.bx("BLK", su + 5.6, sv, -1.0, 0.5, 0.5, 4.0)
    F.bx("BLK", su, sv, 3.0, 12.0, 0.6, 6.6)
    F.bx("SCR", su, sv - 0.32, 3.3, 11.4, 0.04, 6.0)
    F.cb(boxes, su, sv, -1.0, 12.0, 0.6, 10.6)
    sign(su, sv - 0.36, 3.3, 0, -1, 11.4, 6.0, "GG GAMING FEST\n21-22 NOV · YANGON CONVENTION CENTRE", tag="GGFestScreen",
         bg=(16, 18, 24), name="OutdoorScreen")
    fills.append(_box(F, su, sv, -4.0, 14.0, 3.0, 3.0))

    # ------------------------------------------------------------------ GGFest inside
    # main aisle (red carpet) and the stage at the south-east end
    F.bx("RCP", -10.0, 0.0, 0.0, 150.0, 8.0, 0.03)
    SU0, SU1, SV = 68.0, 84.0, 20.0
    SH = 1.2
    F.bx("BLK", (SU0 + SU1) / 2, 0.0, 0.0, SU1 - SU0, 2 * SV, SH)
    F.bx("NCY", SU0 - 0.03, 0.0, SH - 0.15, 0.06, 2 * SV - 0.4, 0.1)      # neon lip on the stage front
    F.cb(boxes, (SU0 + SU1) / 2, 0.0, 0.0, SU1 - SU0, 2 * SV, SH)
    for i in range(3):                     # steps up at both front corners
        for vv in (-SV + 2.0, SV - 2.0):
            F.bx("BLK", SU0 - 0.4 - 0.4 * i, vv, 0.0, 0.4, 3.0, SH * (3 - i) / 4)
    # LED wall, truss towers, top truss, speakers
    F.bx("BLK", SU1 - 0.5, 0.0, SH, 0.6, 31.0, 9.6)
    F.bx("SCR", SU1 - 0.82, 0.0, SH + 0.4, 0.04, 30.0, 8.8)
    sign(SU1 - 0.86, 0.0, SH + 0.4, -1, 0, 30.0, 8.8, "GG GAMING FEST\n21-22 NOV · YANGON CONVENTION CENTRE", tag="GGFestScreen",
         bg=(16, 18, 24), name="StageScreen")
    for vv in (-16.6, 16.6):
        F.bx("STL", SU1 - 1.6, vv, SH, 0.7, 0.7, 11.5)
        F.bx("BLK", SU0 + 2.0, vv + math.copysign(0.0, vv), SH, 1.6, 2.2, 3.2)    # speaker stacks
    F.bx("STL", SU1 - 1.6, 0.0, SH + 11.5, 0.7, 34.0, 0.7)
    F.bx("MAG", SU1 - 2.05, 0.0, SH + 10.2, 0.04, 26.0, 1.0)
    sign(SU1 - 2.1, 0.0, SH + 10.2, -1, 0, 25.6, 1.0, "GG GAMING FEST", name="StageHeader")
    F.cb(boxes, SU1 - 1.0, 0.0, SH, 2.0, 34.0, 12.2)
    # the photo spot in front of the stage: a neon ring on the floor and a sign on a stand
    PU = 58.0
    n = 24
    for k in range(n):
        t0, t1 = 2 * math.pi * k / n, 2 * math.pi * (k + 1) / n
        for r0, r1, look in ((4.0, 4.4, "NCY"),):
            a_ = F.W(PU + r0 * math.cos(t0), r0 * math.sin(t0), 0.05)
            b_ = F.W(PU + r1 * math.cos(t0), r1 * math.sin(t0), 0.05)
            c_ = F.W(PU + r1 * math.cos(t1), r1 * math.sin(t1), 0.05)
            d_ = F.W(PU + r0 * math.cos(t1), r0 * math.sin(t1), 0.05)
            up_quad(sc, look, a_, b_, c_, d_)
    F.bx("BLK", PU, 6.5, 0.03, 0.15, 0.15, 2.6)
    F.bx("YLW", PU, 6.5, 2.0, 2.6, 0.08, 1.2)
    sign(PU, 6.42, 2.05, 0, -1, 2.5, 1.1, "PHOTO SPOT", fg=(20, 20, 24), name="PhotoSpot")
    F.cb(boxes, PU, 6.5, 0.0, 0.3, 0.3, 3.2)

    def zone(u0, u1, v0, v1, carpet, accent, title, face_v):
        """a zone carpet, a pylon with its name at the aisle corner and an overhead header"""
        F.bx(carpet, (u0 + u1) / 2, (v0 + v1) / 2, 0.0, u1 - u0, v1 - v0, 0.03)
        pv = v0 + 0.6 if face_v < 0 else v1 - 0.6
        pu = u0 + 1.0
        F.bx("BLK", pu, pv, 0.03, 1.4, 0.5, 5.0)
        F.bx(accent, pu, pv, 5.03, 1.4, 0.5, 0.25)
        sign(pu, pv + face_v * 0.27, 1.4, 0, face_v, 1.3, 3.4, title.replace(" ", "\n"), fg=(255, 255, 255), name="ZonePylon")
        F.cb(boxes, pu, pv, 0.0, 1.4, 0.5, 5.3)
        # a hanging header over the zone, on two thin cables
        hu = (u0 + u1) / 2
        hv = pv
        F.bx(accent, hu, hv, 6.0, 12.0, 0.2, 1.6)
        sign(hu, hv + face_v * 0.13, 6.05, 0, face_v, 11.6, 1.5, title, fg=(255, 255, 255), name="ZoneHeader")
        sign(hu, hv - face_v * 0.13, 6.05, 0, -face_v, 11.6, 1.5, title, fg=(255, 255, 255), name="ZoneHeader")
        for du in (-5.5, 5.5):
            F.bx("STL", hu + du, hv, 7.6, 0.05, 0.05, yarc(hv) - ROOF_T - TD - 7.6)

    # GG ARCADE (north-east, west half): three rows of cabinets
    zone(-50.0, -6.0, 6.0, 28.0, "CMG", "MAG", "GG ARCADE", -1)
    for row, vv in enumerate((12.0, 17.0, 22.5)):
        for k in range(24):
            uu = -45.0 + 1.3 * k
            face = -1 if row != 1 else 1
            F.bx("BLK", uu, vv, 0.03, 1.0, 0.9, 1.9)
            F.bx("NCY" if k % 2 else "NMG", uu, vv + face * 0.46, 1.0, 0.7, 0.03, 0.55)
            F.bx(cols[k % 4], uu, vv + face * 0.3, 1.93, 1.0, 0.3, 0.3)
        F.cb(boxes, -45.0 + 1.3 * 11.5, vv, 0.0, 1.3 * 24, 1.0, 2.3)
    # GG ESPORTS (south-west, west half): a low stage, two team desks with monitors, a big screen, bleachers
    zone(-50.0, -6.0, -28.0, -6.0, "CBL", "CYN", "GG ESPORTS", 1)
    F.bx("BLK", -28.0, -23.0, 0.03, 26.0, 8.0, 0.6)
    F.bx("NCY", -28.0, -18.98, 0.5, 25.6, 0.04, 0.08)
    F.cb(boxes, -28.0, -23.0, 0.0, 26.0, 8.0, 0.63)
    for du, look in ((-7.0, "CYN"), (7.0, "MAG")):
        F.bx("WHT", -28.0 + du, -22.0, 0.63, 9.0, 1.2, 0.8)
        F.bx(look, -28.0 + du, -21.38, 0.68, 8.8, 0.04, 0.6)
        for m in range(5):
            F.bx("SCR", -28.0 + du - 3.6 + 1.8 * m, -22.2, 1.43, 1.2, 0.08, 0.7)
        F.cb(boxes, -28.0 + du, -22.0, 0.63, 9.0, 1.2, 1.5)
    F.bx("BLK", -28.0, -27.3, 0.63, 16.0, 0.5, 7.0)
    F.bx("SCR", -28.0, -27.03, 1.2, 15.2, 0.04, 5.8)
    sign(-28.0, -26.99, 1.2, 0, 1, 15.2, 5.8, "GG ESPORTS\nTOURNAMENT STAGE", bg=(16, 18, 24), name="EsportsScreen")
    for i in range(3):                     # bleachers facing the esports stage
        F.bx("CGR", -28.0, -12.0 + 1.2 * i, 0.03, 26.0, 1.2, 0.45 * (i + 1))
    F.cb(boxes, -28.0, -10.8, 0.0, 26.0, 3.6, 1.4)
    # GG COSPLAY (north-east, east half): photo backdrop wall, runway, light stands
    zone(6.0, 50.0, 6.0, 28.0, "CPU", "PUR", "GG COSPLAY", -1)
    F.bx("WHT", 28.0, 26.6, 0.03, 26.0, 0.4, 4.4)
    F.bx("PUR", 28.0, 26.6, 4.43, 26.4, 0.5, 0.35)
    sign(28.0, 26.38, 1.2, 0, -1, 24.0, 2.6, "GG COSPLAY · PHOTO WALL", fg=(124, 66, 240), name="CosplayWall")
    F.cb(boxes, 28.0, 26.6, 0.0, 26.0, 0.4, 4.8)
    F.bx("BLK", 28.0, 19.0, 0.03, 16.0, 6.0, 0.5)
    F.bx("NMG", 28.0, 15.98, 0.4, 15.6, 0.04, 0.08)
    F.cb(boxes, 28.0, 19.0, 0.0, 16.0, 6.0, 0.53)
    for du in (-11.0, -6.0, 6.0, 11.0):
        F.bx("BLK", 28.0 + du, 13.0, 0.03, 0.08, 0.08, 2.4)
        F.bx("WHT", 28.0 + du, 13.0, 2.4, 0.9, 0.4, 0.9)
    # GG QUEST (south-west, east half): the quest desk, three checkpoint arches, the quest board
    zone(6.0, 50.0, -28.0, -6.0, "CTL", "GRN", "GG QUEST", 1)
    F.bx("WHT", 28.0, -24.5, 0.03, 12.0, 1.0, 1.1)
    F.bx("GRN", 28.0, -23.98, 0.1, 11.8, 0.04, 0.9)
    F.cb(boxes, 28.0, -24.5, 0.0, 12.0, 1.0, 1.2)
    F.bx("BLK", 28.0, -27.3, 0.03, 12.0, 0.4, 6.0)
    F.bx("SCR", 28.0, -27.08, 1.6, 11.4, 0.04, 4.2)
    sign(28.0, -27.04, 1.6, 0, 1, 11.4, 4.2, "GG QUEST\nDrive to YCC · Cut up · Combo · Drift · Photo at the stage",
         bg=(16, 18, 24), name="QuestBoard")
    F.cb(boxes, 28.0, -27.3, 0.0, 12.0, 0.4, 6.1)
    for du in (-14.0, 0.0, 14.0):
        F.bx("GRN", 28.0 + du - 2.2, -14.0, 0.03, 0.4, 0.4, 4.0)
        F.bx("GRN", 28.0 + du + 2.2, -14.0, 0.03, 0.4, 0.4, 4.0)
        F.bx("GRN", 28.0 + du, -14.0, 4.03, 4.8, 0.4, 0.4)
        F.cb(boxes, 28.0 + du - 2.2, -14.0, 0.0, 0.4, 0.4, 4.4)
        F.cb(boxes, 28.0 + du + 2.2, -14.0, 0.0, 0.4, 0.4, 4.4)
    # exhibitor booths (white shell scheme, coloured fascias) at the north-west end, both sides
    k = 0
    for v0, face in ((8.0, -1), (-8.0, 1)):
        for i in range(7):
            u0 = -83.0 + 3.2 * i
            vb = v0 + (-face) * 3.0
            F.bx("WHT", u0 + 1.5, vb, 0.03, 3.0, 0.08, 2.5)                       # back wall
            F.bx("WHT", u0, v0 - face * 1.5, 0.03, 0.08, 2.92, 2.5)               # side wall
            F.bx(cols[k % 4], u0 + 1.5, v0 + face * 0.02, 2.53, 3.0, 0.06, 0.4)   # fascia
            F.bx("WHT", u0 + 1.5, v0 - face * 0.8, 0.03, 1.6, 0.6, 1.0)           # counter
            k += 1
        F.cb(boxes, -83.0 + 3.2 * 3.5, v0 - face * 1.5, 0.0, 3.2 * 7, 3.0, 2.6)
    return sc, F, boxes, signs, lights, clears, fills


def _box(F, u, v, y, su, sv, sy):
    """a terrain box [x, y, z, sx, sy, sz, yaw] (u, v, y metres over the floor; y = bottom)"""
    c = F.W(u, v, y + sy / 2)
    return [round(c[0], 2), round(c[1], 2), round(c[2], 2), round(su * S, 2), round(sy * S, 2), round(sv * S, 2), -F.yaw]


def main():
    sc, F, boxes, signs, lights, clears, fills = build()
    bad, tr = DT.flicker(sc)
    path, nm, badglb = DT.export(sc, LID)
    out = os.path.join(DT.OUT, LID)
    os.makedirs(out, exist_ok=True)
    used = {k: list(LOOKS[k]) for k in sc.g}
    spot = F.W(0.0, W2 + 8.0, 0.0)
    stage = F.W(58.0, 0.0, 0.0)
    meta = dict(id=LID, base=FY, looks=used, collide=[[round(x, 3) for x in b] for b in boxes], signs=signs, lights=lights,
                clear=clears, fill=fills,
                arrive=[round(spot[0], 2), round(spot[1] + 3, 2), round(spot[2], 2), round(AX[0], 4), round(AX[1], 4)],
                centre=[round(O[0], 2), round(FY, 2), round(O[1], 2)], photo=[round(stage[0], 2), round(FY, 2), round(stage[2], 2)])
    json.dump(meta, open(os.path.join(out, "place.json"), "w"), indent=0)
    # preview scene for preview_blend.py (metres, z up, origin at the hall's middle on the floor)
    pv = {"look": {k: list(LOOKS[k][1]) for k in sc.g}, "tris": {}}
    for k, tris in sc.g.items():
        pv["tris"][k] = [[[(p[0] - O[0]) / S, -(p[2] - O[1]) / S, (p[1] - FY) / S] for p in t] for t in tris]
    json.dump(pv, open(os.path.join(out, "preview_tris.json"), "w"))
    print("%s: %d tris, %d meshes, floor %.2f, %d boxes, %d signs, %d lights, flicker pairs %d, glb bad %s"
          % (LID, sc.count(), nm, FY, len(boxes), len(signs), len(lights), len(bad), badglb))
    print("arrive", meta["arrive"], "centre", meta["centre"], "photo", meta["photo"])
    for i, j, gp, a_ in bad[:12]:
        print("  ", tr[i][1], tr[j][1], round(gp, 3), [round(v, 1) for v in tr[i][0][0]])


if __name__ == "__main__":
    main()
