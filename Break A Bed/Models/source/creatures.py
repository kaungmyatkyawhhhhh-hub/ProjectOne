from geo import *

def bird_wing(s, bone, n_prim=11, n_cov=9, prim_len=(3.0, 6.5), flame=False, finger=False, width=0.75):
    """s=+1 right / -1 left. bone: list of control pts. returns list of meshes."""
    out = [loft(bone, [0.45, 0.4, 0.3, 0.15], seg=10)]
    B = catmull(bone, 60)
    us = np.linspace(0.15, 1.0, n_prim)
    for k, u in enumerate(us):
        p = B[int(u*(len(B)-1))]
        # direction: back/down near body, outward at tip
        d_in = V(0, -0.55, 1.0); d_out = V(s*1.0, 0.25, 0.35)
        d = nrm(d_in*(1-u)**1.3 + d_out*u**1.3)
        L = prim_len[0] + (prim_len[1]-prim_len[0])*np.sin(np.pi*min(u*1.15, 1)*0.5)
        tang = nrm(np.gradient(B, axis=0)[int(u*(len(B)-1))])
        upv = np.cross(tang, d)
        if flame:
            side = np.cross(d, upv)
            path = [p, p+d*L*0.35+side*0.35, p+d*L*0.7-side*0.35, p+d*L+side*0.3]
            out.append(leaf(path, width*0.95, 0.07, up=upv, shape=0.55))
        elif finger and u > 0.7:
            path = [p, p+d*L*0.5, p+d*L+V(0, 0.4, 0)]
            out.append(leaf(path, width*0.6, 0.06, up=upv, shape=0.6, tipw=0.0))
        else:
            path = [p, p+d*L*0.5+V(0, -0.15, 0), p+d*L]
            out.append(leaf(path, width, 0.06, up=upv, shape=0.75))
    for k, u in enumerate(np.linspace(0.05, 0.85, n_cov)):
        p = B[int(u*(len(B)-1))] + V(0, 0.08, -0.05)
        d = nrm(V(0, -0.5, 1.0)*(1-u) + V(s*0.8, 0.0, 0.6)*u)
        tang = nrm(np.gradient(B, axis=0)[int(u*(len(B)-1))])
        out.append(leaf([p, p+d*1.4, p+d*2.6], width*1.25, 0.07, up=np.cross(tang, d), shape=0.9))
    return out

def phoenix(flame=False):
    P = {}
    P["Body"] = [loft([V(0, -0.5, 3.5), V(0, 0, 1.5), V(0, 0.8, -1), V(0, 2.2, -3), V(0, 3.6, -4.2)],
                      [(0.5, 0.5), (1.5, 1.6), (1.4, 1.5), (0.7, 0.75), (0.6, 0.6)], seg=20)]
    head = [ellipsoid(V(0, 4.1, -4.8), V(0.95, 1.0, 1.25))]
    P["Beak"] = [loft([V(0, 4.0, -5.8), V(0, 3.85, -6.6), V(0, 3.5, -7.2)], [(0.32, 0.3), (0.18, 0.18), 0.02], seg=12)]
    P["Eyes"] = [ellipsoid(V(s*0.72, 4.35, -5.45), V(0.2, 0.2, 0.16)) for s in (1, -1)]
    for x, tip in [(0, V(0, 7.2, -3.0)), (0.5, V(0.9, 6.6, -2.6)), (-0.5, V(-0.9, 6.6, -2.6)), (0, V(0, 6.0, -1.8))]:
        base = V(x*0.4, 4.7, -4.5)
        mid = (base+tip)/2 + V(0, 0.6, -0.6)
        head.append(leaf([base, mid, tip], 0.45 if not flame else 0.55, 0.06, up=(1, 0, 0), shape=0.6 if flame else 0.8))
    P["Head"] = head
    for s, name in [(1, "WingR"), (-1, "WingL")]:
        bone = [V(s*1.1, 1.4, -1.2), V(s*4.0, 3.2, -0.6), V(s*7.0, 5.2, -0.8), V(s*9.6, 6.4, -0.2)]
        P[name] = bird_wing(s, bone, flame=flame, width=0.85 if flame else 0.75)
    tail = []
    n = 7 if flame else 5
    for k in range(n):
        a = (k-(n-1)/2)/((n-1)/2)
        base = V(0, -0.5, 3.4)
        p1 = base + V(a*1.5, -1.5, 3.0); p2 = base + V(a*3.5, -3.8, 6.5); p3 = base + V(a*4.8, -4.5, 10.5+abs(a)*-1.5)
        if flame:
            p1 += V(0.6*np.sin(k), 0, 0); p2 += V(-0.8*np.cos(k), 0.5, 0)
            tail.append(leaf([base, p1, p2, p3], 1.0, 0.06, up=(0, 1, 0.3), shape=0.5))
        else:
            tail.append(leaf([base, p1, p2, p3], 0.55, 0.06, up=(0, 1, 0.3), shape=1.6, tipw=0.5))
    P["Tail"] = tail
    return P

def tiger():
    P = {}
    P["Body"] = [loft([V(0, 2.2, 3.2), V(0, 2.5, 1.0), V(0, 2.9, -1.3), V(0, 3.0, -2.6)],
                      [(1.25, 1.35), (1.45, 1.55), (1.55, 1.75), (1.2, 1.4)], seg=22)]
    head = [ellipsoid(V(0, 3.7, -3.7), V(1.3, 1.15, 1.25)),
            ellipsoid(V(0, 3.25, -4.75), V(0.85, 0.62, 0.75)),
            ellipsoid(V(0, 2.75, -4.5), V(0.7, 0.35, 0.65)),            # jaw (open roar)
            ellipsoid(V(1.0, 3.3, -3.6), V(0.5, 0.75, 0.75)), ellipsoid(V(-1.0, 3.3, -3.6), V(0.5, 0.75, 0.75))]  # cheek ruff
    for s in (1, -1):
        head.append(loft([V(s*0.75, 4.5, -3.3), V(s*0.95, 5.3, -3.2)], [(0.45, 0.2), 0.05], seg=10, smooth=False, samples=8, up=(0, 0, 1)))
        for k in range(3):  # fangs
            pass
    P["Head"] = head
    P["Nose"] = [ellipsoid(V(0, 3.5, -5.35), V(0.32, 0.22, 0.2))]
    P["Fangs"] = [cone(V(0.35, 2.95, -5.0), V(0.35, 2.5, -5.0), 0.1), cone(V(-0.35, 2.95, -5.0), V(-0.35, 2.5, -5.0), 0.1)]
    P["Eyes"] = [ellipsoid(V(s*0.55, 4.0, -4.62), V(0.24, 0.16, 0.12)) for s in (1, -1)]
    legs = []
    for s in (1, -1):
        legs.append(loft([V(s*0.95, 2.4, -1.9), V(s*1.05, 1.6, -3.3), V(s*1.0, 1.7, -5.0)], [0.55, 0.42, 0.36], seg=14))
        legs.append(ellipsoid(V(s*1.0, 1.65, -5.3), V(0.5, 0.35, 0.55)))
        legs.append(loft([V(s*1.0, 2.0, 2.6), V(s*1.15, 1.2, 3.6), V(s*1.1, 0.7, 5.4), V(s*1.1, 0.5, 6.2)], [0.75, 0.5, 0.33, 0.3], seg=14))
        legs.append(ellipsoid(V(s*1.1, 0.45, 6.5), V(0.45, 0.3, 0.55)))
    P["Legs"] = legs
    P["Tail"] = [loft([V(0, 2.5, 3.6), V(0, 3.4, 5.6), V(0, 5.0, 6.6), V(0, 6.2, 6.0), V(0, 6.5, 5.0)], [0.38, 0.32, 0.27, 0.22, 0.18], seg=12)]
    return P

def crane():
    P = {}
    P["Body"] = [ellipsoid(V(0, 0, 0), V(1.15, 1.05, 2.4))]
    P["Head"] = [loft([V(0, 0.6, -1.9), V(0, 1.8, -2.8), V(0, 3.0, -2.5), V(0, 4.0, -3.3)], [0.55, 0.38, 0.33, 0.33], seg=14),
                 ellipsoid(V(0, 4.1, -3.55), V(0.42, 0.45, 0.62))]
    P["Crown"] = [ellipsoid(V(0, 4.45, -3.5), V(0.28, 0.12, 0.3))]
    P["Beak"] = [loft([V(0, 4.0, -4.05), V(0, 3.75, -6.0)], [(0.16, 0.13), 0.01], seg=10, smooth=False, samples=10)]
    P["Eyes"] = [ellipsoid(V(s*0.36, 4.2, -3.85), V(0.09, 0.09, 0.08)) for s in (1, -1)]
    for s, name in [(1, "WingR"), (-1, "WingL")]:
        bone = [V(s*0.9, 0.6, -0.8), V(s*4.5, 1.6, -0.3), V(s*8.5, 2.6, 0.0), V(s*11.5, 3.0, 0.5)]
        P[name] = bird_wing(s, bone, n_prim=12, n_cov=10, prim_len=(2.5, 4.5), finger=True, width=0.8)
    P["Legs"] = [loft([V(s*0.3, -0.4, 1.5), V(s*0.3, -0.7, 4.0), V(s*0.3, -0.9, 6.5)], [0.14, 0.11, 0.09], seg=8) for s in (1, -1)]
    P["Tail"] = [leaf([V(a*0.4, 0.1, 2.0), V(a*0.9, -0.1, 3.3), V(a*1.2, -0.2, 4.2)], 0.55, 0.05, shape=0.8) for a in (-1, -0.4, 0.4, 1)]
    return P

def serpent_body(turns=1.15, R=5.5, height=10.0, n=9):
    pts = []
    for t in np.linspace(0, 1, n):
        a = 2*np.pi*turns*t
        r = R*(0.55+0.45*t)
        pts.append(V(r*np.cos(a), -height/2 + height*t, r*np.sin(a)))
    return pts

def dragon_head(kind):
    H = {"Head": [ellipsoid(V(0, 0, 0), V(1.15, 0.95, 1.5)),
                  ellipsoid(V(0, -0.15, -1.6), V(0.8, 0.55, 1.35)),
                  ellipsoid(V(0, -0.65, -1.3), V(0.7, 0.3, 1.2)),
                  ellipsoid(V(0.45, 0.45, -0.7), V(0.25, 0.2, 0.35)), ellipsoid(V(-0.45, 0.45, -0.7), V(0.25, 0.2, 0.35))],
         "Horns": [], "Whiskers": [],
         "Eyes": [ellipsoid(V(s*0.62, 0.28, -0.85), V(0.2, 0.15, 0.22)) for s in (1, -1)]}
    for s in (1, -1):
        if kind == "gold":
            H["Horns"].append(loft([V(s*0.5, 0.7, 0.3), V(s*0.9, 1.6, 1.3), V(s*1.1, 2.0, 2.8)], [0.22, 0.17, 0.05], seg=10))
            H["Horns"].append(loft([V(s*0.9, 1.6, 1.3), V(s*1.6, 2.4, 1.6)], [0.12, 0.03], seg=8, smooth=False, samples=6))
            H["Whiskers"].append(loft([V(s*0.6, -0.2, -2.5), V(s*1.8, -0.4, -2.0), V(s*2.8, -1.2, -0.6), V(s*3.4, -0.6, 1.2)], [0.08, 0.06, 0.04, 0.01], seg=6))
            H["Whiskers"].append(leaf([V(s*0.9, 0.2, 0.5), V(s*1.7, 0.6, 1.4), V(s*2.0, 0.2, 2.4)], 0.5, 0.05, up=(s, 1, 0), shape=0.7))
        else:
            H["Horns"].append(loft([V(s*0.55, 0.7, 0.4), V(s*0.9, 1.4, 2.0), V(s*1.0, 1.9, 3.6)], [0.25, 0.15, 0.02], seg=10))
            H["Horns"].append(loft([V(s*0.8, 0.2, 0.7), V(s*1.5, 0.4, 2.0), V(s*1.9, 0.6, 3.0)], [0.16, 0.1, 0.02], seg=8))
            H["Horns"].append(cone(V(s*0.4, -0.85, -2.4), V(s*0.4, -1.3, -2.3), 0.09))
    H["Horns"].append(cone(V(0.3, -0.45, -2.55), V(0.3, -0.85, -2.55), 0.08)); H["Horns"].append(cone(V(-0.3, -0.45, -2.55), V(-0.3, -0.85, -2.55), 0.08))
    return {k: v for k, v in H.items() if v}

def east_dragon(kind="gold"):
    P = {}
    pts = serpent_body()
    radii = [0.12, 0.45, 0.85, 1.1, 1.2, 1.2, 1.05, 0.85, 0.7]
    P["Body"] = [loft(pts, radii, seg=20, samples=120)]
    C = catmull(pts, 120); T, N, Bn = frames(C, (0, 1, 0))
    fins = []
    for i in range(10, len(C)-6, 7):
        r = np.interp(i/len(C), np.linspace(0, 1, len(radii)), radii)
        upw = V(0, 1, 0) - np.dot(V(0, 1, 0), T[i])*T[i]; upw = upw/np.linalg.norm(upw)
        sidew = np.cross(T[i], upw)
        N[i] = upw; Bn[i] = sidew
        base = C[i] + upw*r*0.9
        if kind == "gold":
            fins.append(leaf([base, base+N[i]*0.9 - T[i]*0.6, base+N[i]*1.4 - T[i]*1.6], 0.45, 0.05, up=Bn[i], shape=0.7))
        else:
            fins.append(crystal(base - N[i]*0.2, base+N[i]*1.6 - T[i]*0.8, 0.3))
    P["Spines"] = fins
    legs = []
    for u, s in ((0.35, 1), (0.6, 1), (0.37, -1), (0.62, -1)):
        i = int(u*(len(C)-1))
        upw = V(0, 1, 0) - np.dot(V(0, 1, 0), T[i])*T[i]; upw = upw/np.linalg.norm(upw)
        N[i] = upw; Bn[i] = np.cross(T[i], upw)
        side = Bn[i]*s; base = C[i]+side*0.8
        knee = base + side*1.0 - N[i]*0.8; foot = knee - N[i]*0.9 - T[i]*0.4
        legs.append(loft([base, knee, foot], [0.35, 0.28, 0.22], seg=10))
        for k in (-1, 0, 1):
            legs.append(cone(foot, foot - N[i]*0.2 - T[i]*0.6 + Bn[i]*k*0.3, 0.09, seg=8))
    P["Legs"] = legs
    # head at the top end
    i = len(C)-1
    R = look(T[i]*1.0 + V(0, 0.5, 0))
    S = np.diag([1.45, 1.45, 1.45, 1.0])
    for k, v in dragon_head(kind).items(): P[k] = place(v, R @ S, C[i] + T[i]*1.6)
    # tail tip
    if kind == "gold":
        P["TailTip"] = [leaf([C[0], C[0]-T[0]*1.2 + N[0]*0.5, C[0]-T[0]*2.5], 0.8, 0.05, up=Bn[0], shape=0.6)]
    else:
        P["TailTip"] = [crystal(C[0], C[0]-T[0]*2.6, 0.35)]
    return P

def bat_wing(s, shoulder):
    sh = np.asarray(shoulder, float)
    wrist = sh + V(s*4.5, 3.5, 0.5)
    tips = [wrist + V(s*1.5, 4.5, 0.5), wrist + V(s*5.0, 2.5, 1.0), wrist + V(s*6.0, -1.0, 2.0), wrist + V(s*4.0, -4.0, 3.0)]
    out = [loft([sh, (sh+wrist)/2 + V(0, 0.6, 0), wrist], [0.45, 0.35, 0.3], seg=10)]
    for t in tips:
        out.append(loft([wrist, (wrist+t)/2 + V(0, 0.4, 0), t], [0.22, 0.15, 0.04], seg=8))
    pts_edge = [sh + V(0, 0, 0.8)] + tips[::-1]  # body side to front
    anchors = [wrist]*len(tips)
    # membranes between consecutive fingers and between last finger and body
    edges = [tips[0], tips[1], tips[2], tips[3], sh + V(s*0.6, -0.5, 3.0)]
    for a, b in zip(edges[:-1], edges[1:]):
        nu, nv = 10, 8; grid = np.zeros((nu, nv, 3))
        for i, u in enumerate(np.linspace(0, 1, nu)):
            edge = a*(1-u) + b*u
            sag = 0.22*np.sin(np.pi*u)
            for j, v in enumerate(np.linspace(0, 1, nv)):
                grid[i, j] = wrist + (edge - wrist)*v*(1-sag*v) + V(0, -0.3, 0.2)*np.sin(np.pi*u)*v
        out.append(sheet(grid, 0.08))
    # inner membrane: wrist-shoulder-body
    nu, nv = 8, 6; grid = np.zeros((nu, nv, 3)); body_pt = sh + V(0, -0.5, 3.0)
    for i, u in enumerate(np.linspace(0, 1, nu)):
        edge = sh*(1-u) + body_pt*u
        for j, v in enumerate(np.linspace(0, 1, nv)):
            tgt = edges[-1]
            grid[i, j] = edge*(1-v) + (wrist*(1-u) + tgt*u)*v
    out.append(sheet(grid, 0.08))
    return out

def ice_dragon():
    P = {}
    P["Body"] = [loft([V(0, -2.5, 13), V(0, -1.5, 9), V(0, -0.3, 5), V(0, 0.2, 2), V(0, 0.9, -1), V(0, 2.4, -3), V(0, 4.6, -4.0), V(0, 6.0, -4.6)],
                      [0.12, 0.5, 1.1, 1.6, 1.7, 1.0, 0.75, 0.7], seg=22, samples=90)]
    for k, v in dragon_head("ice").items(): P[k] = place(v, look(V(0, -0.2, -1)), V(0, 6.6, -5.6))
    P["WingR"] = bat_wing(1, V(1.1, 1.6, -0.2)); P["WingL"] = bat_wing(-1, V(-1.1, 1.6, -0.2))
    spikes = []
    path = catmull([V(0, -1.5, 9), V(0, -0.3, 5), V(0, 0.2, 2), V(0, 0.9, -1), V(0, 2.4, -3), V(0, 4.6, -4.0)], 40)
    rad = np.interp(np.linspace(0, 1, 40), [0, .2, .45, .6, .8, 1], [0.5, 1.1, 1.6, 1.7, 1.0, 0.75])
    for i in range(2, 40, 3):
        base = path[i] + V(0, rad[i]*0.85, 0)
        spikes.append(crystal(base, base + V(0, 1.0 + rad[i]*0.6, 0.6), 0.22 + rad[i]*0.12))
    spikes.append(crystal(V(0, -2.5, 13), V(0, -2.2, 16), 0.5))
    P["Crystals"] = spikes
    legs = []
    for s in (1, -1):
        for z, y in ((-0.5, 0.6), (4.0, 0.0)):
            base = V(s*1.1, y, z); knee = base + V(s*0.8, -1.4, -0.6); foot = knee + V(0, -1.4, 0.5)
            legs.append(loft([base, knee, foot], [0.55, 0.4, 0.3], seg=12))
            for k in (-1, 0, 1):
                legs.append(cone(foot, foot + V(k*0.35, -0.35, -0.7), 0.12, seg=8))
    P["Legs"] = legs
    return P

def koi():
    P = {}
    zs = np.linspace(-4.2, 4.2, 9)
    path = [V(0.5*np.sin(z*0.6), 0, z) for z in zs]
    prof = [(0.45, 0.5), (0.85, 1.0), (1.05, 1.3), (1.05, 1.28), (0.95, 1.12), (0.75, 0.85), (0.5, 0.56), (0.3, 0.36), (0.2, 0.26)]
    P["Body"] = [loft(path, prof, seg=22, samples=60)]
    eye = [ellipsoid(V(s*0.6, 0.3, -3.4), V(0.18, 0.18, 0.18)) for s in (1, -1)]
    barbel = [loft([V(s*0.3, -0.25, -4.2), V(s*0.9, -0.5, -3.9), V(s*1.4, -0.9, -3.0)], [0.06, 0.04, 0.01], seg=6) for s in (1, -1)]
    P["Eyes"] = eye; P["Barbels"] = barbel
    tb = path[-1]
    # big flowing double-lobe tail fin (vertical sheet)
    nu, nv = 14, 10; g = np.zeros((nu, nv, 3))
    for i, u in enumerate(np.linspace(-1, 1, nu)):
        L = 3.6 + 1.6*abs(u)**1.5
        for j, v in enumerate(np.linspace(0, 1, nv)):
            g[i, j] = tb + V(0.6*np.sin(v*2.4 + u), u*2.4*v**0.8, v*L - 0.6*abs(u)*v*v)
    P["TailFin"] = [sheet(g, 0.07)]
    # dorsal fin
    nu, nv = 10, 6; g = np.zeros((nu, nv, 3))
    for i, u in enumerate(np.linspace(0, 1, nu)):
        z = -1.8 + 4.4*u; h = 1.1*np.sin(np.pi*u**0.7)
        for j, v in enumerate(np.linspace(0, 1, nv)):
            g[i, j] = V(0.5*np.sin(z*0.6), 1.35 - 0.25*u + v*h, z + v*0.9)
    fins = [sheet(g, 0.06)]
    for s in (1, -1):
        nu, nv = 8, 6; g = np.zeros((nu, nv, 3))
        for i, u in enumerate(np.linspace(0, 1, nu)):
            for j, v in enumerate(np.linspace(0, 1, nv)):
                g[i, j] = V(s*(0.9 + 1.4*v), -0.6 - 0.5*v, -2.0 + (u-0.5)*1.4*np.sin(np.pi*v)**0.6 + v*1.2)
        fins.append(sheet(g, 0.05))
    P["Fins"] = fins
    return P

ALL = {
    "1_Phoenix": (lambda: phoenix(False), "#FFC83A"),
    "2_Tiger": (tiger, "#E08A3C"),
    "3_Crane": (crane, "#D9E4F2"),
    "4_GoldDragon": (lambda: east_dragon("gold"), "#FFD700"),
    "5_IceDragon": (ice_dragon, "#8EE8FF"),
    "6_FirePhoenix": (lambda: phoenix(True), "#FF3B2F"),
    "7_RainbowKoi": (koi, "rainbow"),
    "8_GalaxyDragon": (lambda: east_dragon("galaxy"), "#9B5CFF"),
}
