"""3/4 preview of classic clothing on a blocky avatar, folded with the template's wrap rules (16 Nov 2026).
Not Roblox's renderer: a quick check that panels land on the right faces and seams meet. The real check is
Studio (Shirt.ShirtTemplate / Pants.PantsTemplate on an R15 rig).
Usage: python preview3d.py MM_01_midnight_track_shirt.png MM_01_midnight_track_pants.png out.png
"""
import sys, math
import numpy as np
from PIL import Image, ImageDraw

SKIN = (234, 192, 160, 255)
# template boxes per part: face -> (x, y, w, h)
T = {"F": (231, 74, 128, 128), "B": (427, 74, 128, 128), "R": (165, 74, 64, 128), "L": (361, 74, 64, 128),
     "U": (231, 8, 128, 64), "D": (231, 204, 128, 64)}
RA = {"L": (19, 355, 64, 128), "B": (85, 355, 64, 128), "R": (151, 355, 64, 128), "F": (217, 355, 64, 128),
      "U": (217, 289, 64, 64), "D": (217, 485, 64, 64)}
LA = {"F": (308, 355, 64, 128), "L": (374, 355, 64, 128), "B": (440, 355, 64, 128), "R": (506, 355, 64, 128),
      "U": (308, 289, 64, 64), "D": (308, 485, 64, 64)}

def coeffs(dst, src):
    A, b = [], []
    for (x, y), (u, v) in zip(dst, src):
        A.append([x, y, 1, 0, 0, 0, -u * x, -u * y]); b.append(u)
        A.append([0, 0, 0, x, y, 1, -v * x, -v * y]); b.append(v)
    return np.linalg.solve(np.array(A, float), np.array(b, float)).tolist()

def face_corners(c, s, face):
    """World corners (TL, TR, BR, BL as seen on the template image) for a box face. Character faces +z."""
    x0, x1 = c[0] - s[0] / 2, c[0] + s[0] / 2
    y0, y1 = c[1] - s[1] / 2, c[1] + s[1] / 2
    z0, z1 = c[2] - s[2] / 2, c[2] + s[2] / 2
    return {
        "F": [(x0, y1, z1), (x1, y1, z1), (x1, y0, z1), (x0, y0, z1)],
        "L": [(x1, y1, z1), (x1, y1, z0), (x1, y0, z0), (x1, y0, z1)],   # left edge touches FRONT's right edge
        "B": [(x1, y1, z0), (x0, y1, z0), (x0, y0, z0), (x1, y0, z0)],
        "R": [(x0, y1, z0), (x0, y1, z1), (x0, y0, z1), (x0, y0, z0)],   # right edge touches FRONT's left edge
        "U": [(x0, y1, z0), (x1, y1, z0), (x1, y1, z1), (x0, y1, z1)],   # bottom edge = FRONT's top edge
        "D": [(x0, y0, z1), (x1, y0, z1), (x1, y0, z0), (x0, y0, z0)],
    }[face]

NORMAL = {"F": (0, 0, 1), "B": (0, 0, -1), "L": (1, 0, 0), "R": (-1, 0, 0), "U": (0, 1, 0), "D": (0, -1, 0)}

def render(shirt, pants, yaw_deg, size=520):
    a, p = math.radians(yaw_deg), math.radians(-14)
    def rot(v):
        x, y, z = v
        x2 = x * math.cos(a) + z * math.sin(a)
        z2 = -x * math.sin(a) + z * math.cos(a)
        y3 = y * math.cos(p) - z2 * math.sin(p)
        z3 = y * math.sin(p) + z2 * math.cos(p)
        return x2, y3, z3
    k, cx, cy = 80, size / 2, size * 0.86
    proj = lambda v: (cx + rot(v)[0] * k, cy - rot(v)[1] * k)
    canvas = Image.new("RGBA", (size, size), (34, 28, 44, 255))
    parts = [  # (center, size, {face: [layers]})
        ((0, 3, 0), (2, 2, 1), {f: [pants, shirt] for f in T}, T),
        ((-1.5, 3, 0), (1, 2, 1), {f: [shirt] for f in RA}, RA),
        ((1.5, 3, 0), (1, 2, 1), {f: [shirt] for f in LA}, LA),
        ((-0.5, 1, 0), (1, 2, 1), {f: [pants] for f in RA}, RA),
        ((0.5, 1, 0), (1, 2, 1), {f: [pants] for f in LA}, LA),
    ]
    polys = []
    for c, s, layers, boxes in parts:
        for f, n in NORMAL.items():
            if rot(n)[2] <= 0.02:
                continue
            x, y, w, h = boxes[f]
            tex = Image.new("RGBA", (w, h), SKIN)
            for L in layers[f]:
                tex.alpha_composite(L.crop((x, y, x + w, y + h)))
            corners = face_corners(c, s, f)
            depth = sum(rot(v)[2] for v in corners) / 4
            polys.append((depth, [proj(v) for v in corners], tex))
    head = ((0, 4.6, 0), (1.2, 1.2, 1.2))
    for f, n in NORMAL.items():
        if rot(n)[2] > 0.02:
            corners = face_corners(head[0], head[1], f)
            polys.append((sum(rot(v)[2] for v in corners) / 4, [proj(v) for v in corners], Image.new("RGBA", (8, 8), SKIN)))
    for _, pts, tex in sorted(polys, key=lambda t: t[0]):
        w, h = tex.size
        src = [(0, 0), (w, 0), (w, h), (0, h)]
        big = tex.resize((w * 3, h * 3), Image.NEAREST)
        src3 = [(u * 3, v * 3) for u, v in src]
        warped = big.transform((size, size), Image.PERSPECTIVE, coeffs(pts, src3), Image.BILINEAR)
        mask = Image.new("L", (size, size), 0)
        ImageDraw.Draw(mask).polygon(pts, fill=255)
        canvas.paste(warped, (0, 0), mask)
        ImageDraw.Draw(canvas).polygon(pts, outline=(0, 0, 0, 60))
    return canvas

if __name__ == "__main__":
    shirt = Image.open(sys.argv[1]).convert("RGBA")
    pants = Image.open(sys.argv[2]).convert("RGBA")
    out = Image.new("RGBA", (1560, 520))
    for i, yaw in enumerate((-30, 30, 150)):
        out.alpha_composite(render(shirt, pants, yaw), (i * 520, 0))
    out.save(sys.argv[3])
