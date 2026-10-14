from geo import *
def torii():
    parts = {}
    H = 14.0; half = 6.0
    # pillars: round, slightly leaning inward, tapering
    pil = []
    for s in (-1, 1):
        pil.append(loft([V(s*half, 0, 0), V(s*(half-0.35), H, 0)], [0.75, 0.6], seg=20, smooth=False, samples=10))
        # black base ring (kamaki)
        pil.append(loft([V(s*half, 0, 0), V(s*half, 1.2, 0)], [0.95, 0.9], seg=20, smooth=False, samples=4))
    parts["Pillars"] = pil[0::2]; parts["Bases"] = pil[1::2]
    # nuki: lower tie beam, rectangular, sticking out past pillars
    nuki = trimesh.creation.box((2*half+3.2, 0.9, 0.6)); nuki.apply_translation((0, H-3.4, 0))
    parts["Nuki"] = [nuki]
    # shimaki + kasagi: top beams, curving up at ends
    xs = np.linspace(-(half+3.0), half+3.0, 41)
    def top_curve(y0, lift):
        return np.array([[x, y0 + lift*(abs(x)/(half+3.0))**3, 0] for x in xs])
    shimaki = tube(top_curve(H+0.2, 0.6), np.full(41, 0.5), np.full(41, 0.45), 4, cap=True)
    kas_path = top_curve(H+1.2, 1.6)
    kasagi = tube(kas_path, np.full(41, 0.55), np.full(41, 0.55), 4, cap=True)
    # make kasagi wider on top: scale z
    kasagi.apply_scale((1, 1, 1.6))
    parts["TopBeam"] = [shimaki]; parts["Roof"] = [kasagi]
    # gakuzuka strut + plaque
    strut = trimesh.creation.box((0.6, 1.4, 0.5)); strut.apply_translation((0, H-2.3, 0))
    plaque = trimesh.creation.box((3.6, 2.2, 0.35)); plaque.apply_translation((0, H-1.8, -0.35))
    frame = trimesh.creation.box((4.0, 2.6, 0.25)); frame.apply_translation((0, H-1.8, -0.2))
    parts["Strut"] = [strut]; parts["PlaqueFrame"] = [frame]; parts["Plaque"] = [plaque]
    return parts
