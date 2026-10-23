from geo import *

def phoenix_dummy():
    P = {}
    P["Post"] = [loft([V(0, 0, 0), V(0, 9, 0)], [0.95, 0.9], seg=24, smooth=False, samples=12),
                 ellipsoid(V(0, 9, 0), V(0.9, 0.35, 0.9))]
    arms = []
    for s in (1, -1):  # two upper arms, angled forward and slightly inward
        arms.append(loft([V(s*0.45, 6.6, -0.6), V(s*0.35, 6.75, -2.0), V(s*0.2, 6.9, -3.1)], [0.22, 0.2, 0.17], seg=12))
        arms.append(ellipsoid(V(s*0.2, 6.9, -3.15), V(0.2, 0.2, 0.2)))
    arms.append(loft([V(0, 5.2, -0.6), V(0, 5.0, -2.0), V(0, 4.9, -2.9)], [0.24, 0.21, 0.18], seg=12))   # middle arm
    arms.append(ellipsoid(V(0, 4.9, -2.95), V(0.21, 0.21, 0.21)))
    P["Arms"] = arms
    P["Leg"] = [loft([V(0, 2.4, -0.6), V(0, 2.0, -1.8), V(0.0, 0.7, -2.4), V(0, 0.25, -2.5)], [0.3, 0.26, 0.24, 0.22], seg=12)]
    frame = []
    for s in (1, -1):  # side frame posts + slats (the stand)
        frame.append(box((0.5, 10.5, 0.5), (s*2.2, 5.25, 0.9)))
    frame.append(box((4.9, 0.45, 0.45), (0, 7.9, 0.9))); frame.append(box((4.9, 0.45, 0.45), (0, 3.2, 0.9)))
    frame.append(box((5.6, 0.5, 2.6), (0, 0.25, 0.3)))
    P["Frame"] = frame
    P["Star"] = [star_prism(V(0, 11.0, 0), 0.9, 0.38, 0.3)]
    P["Pad"] = [loft([V(0, 0.05, 0), V(0, 0.25, 0)], [3.6, 3.6], seg=40, smooth=False, samples=3)]
    return P

def phoenix_glove(side=1):
    """blocky padded glove, sized for a Roblox hand (fits around ~1x1 stud fist)."""
    P = {}
    P["Glove"] = [roundbox(V(0, 0, 0), V(0.75, 0.7, 0.8), e=0.35),
                  roundbox(V(side*0.72, -0.05, -0.25), V(0.26, 0.42, 0.3), e=0.4)]          # thumb bump
    P["Cuff"] = [roundbox(V(0, 0.95, 0.05), V(0.7, 0.35, 0.72), e=0.25)]
    wings = []
    for s in (1, -1):
        for k in range(4):
            a = 0.35 + k*0.28
            base = V(s*0.62, 0.95, 0.15 - k*0.05)
            tip = base + V(s*np.cos(a)*1.3, np.sin(a)*1.3, 0.35)
            wings.append(leaf([base, (base+tip)/2 + V(0, 0.1, 0.05), tip], 0.26, 0.04, up=(0, 0, 1), shape=0.8))
    P["Wings"] = wings
    return P

def sensei_legs():
    """lotus-pose crossed legs for the R15 Sensei (replace the blocky legs). Hip center at origin."""
    P = {}
    legs = []
    for s in (1, -1):
        hip = V(s*0.45, 0, 0.1)
        knee = V(s*1.75, -0.55, -0.85)
        ankle = V(-s*0.55, -0.35, -1.45 + (0.25 if s > 0 else 0))
        legs.append(loft([hip, (hip+knee)/2 + V(0, 0.05, 0), knee], [(0.55, 0.5), (0.52, 0.48), (0.45, 0.42)], seg=18))
        legs.append(ellipsoid(knee, V(0.47, 0.44, 0.47)))
        legs.append(loft([knee, (knee+ankle)/2 + V(0, 0.12, -0.15), ankle], [(0.43, 0.4), (0.4, 0.37), (0.34, 0.32)], seg=18, up=(0, 1, 0)))
    legs.append(roundbox(V(0, -0.15, -0.1), V(1.0, 0.45, 0.65), e=0.6))   # seat/pelvis cloth
    P["Legs"] = legs
    feet = []
    for s in (1, -1):
        ankle = V(-s*0.55, -0.35, -1.45 + (0.25 if s > 0 else 0))
        feet.append(ellipsoid(ankle + V(-s*0.35, 0.05, 0), V(0.42, 0.2, 0.26)))
    P["Feet"] = feet
    return P
