"""Software preview of a Parts dump (rows from Studio: group|name|pos|size|right|up|rgb|transparency|shape), in the
hotel's own frame (a, y, b). Z-buffered boxes, back faces culled like Roblox, flat shading. 2026-11-28."""
import sys, math, numpy as np
from PIL import Image

def load(path):
    parts = []
    for line in open(path, encoding="utf-8"):
        f = line.rstrip("\n").split("|")
        if len(f) != 9: continue
        pos = np.array([float(x) for x in f[2].split(",")]); size = np.array([float(x) for x in f[3].split(",")])
        r = np.array([float(x) for x in f[4].split(",")]); u = np.array([float(x) for x in f[5].split(",")])
        r /= np.linalg.norm(r); u /= np.linalg.norm(u); z = np.cross(r, u)
        col = np.array([int(x) for x in f[6].split(",")], dtype=float); tr = float(f[7])
        parts.append((f[0], f[1], pos, size, np.stack([r, u, z], axis=1), col, tr, f[8]))
    return parts

FACES = [((1, 0, 0), [(1, -1, -1), (1, 1, -1), (1, 1, 1), (1, -1, 1)]), ((-1, 0, 0), [(-1, -1, 1), (-1, 1, 1), (-1, 1, -1), (-1, -1, -1)]),
         ((0, 1, 0), [(-1, 1, -1), (-1, 1, 1), (1, 1, 1), (1, 1, -1)]), ((0, -1, 0), [(-1, -1, 1), (-1, -1, -1), (1, -1, -1), (1, -1, 1)]),
         ((0, 0, 1), [(-1, -1, 1), (1, -1, 1), (1, 1, 1), (-1, 1, 1)]), ((0, 0, -1), [(1, -1, -1), (-1, -1, -1), (-1, 1, -1), (1, 1, -1)])]
LIGHT = np.array([0.45, 0.8, -0.4]); LIGHT /= np.linalg.norm(LIGHT)

def render(parts, eye, target, fov, W, H, out, skip=()):
    eye = np.array(eye, float); target = np.array(target, float)
    fwd = target - eye; fwd /= np.linalg.norm(fwd)
    right = np.cross(fwd, [0, 1, 0]); right /= np.linalg.norm(right); up = np.cross(right, fwd)
    fl = (H / 2) / math.tan(math.radians(fov) / 2)
    img = np.zeros((H, W, 3)); img[:] = (176, 204, 232); zb = np.full((H, W), 1e9)
    order = sorted(parts, key=lambda p: p[6])  # opaque first
    for grp, name, pos, size, R, col, tr, shape in order:
        if grp in skip: continue
        for n, quad in FACES:
            nw = R @ np.array(n, float)
            centre = pos + R @ (np.array(n, float) * size / 2)
            if np.dot(nw, centre - eye) >= 0: continue  # back face
            pts = [pos + R @ (np.array(q, float) * size / 2) for q in quad]
            cam = [(np.dot(p - eye, right), np.dot(p - eye, up), np.dot(p - eye, fwd)) for p in pts]
            if min(c[2] for c in cam) < 0.6: continue  # behind / through the camera: skip the face
            scr = [(W / 2 + c[0] / c[2] * fl, H / 2 - c[1] / c[2] * fl, c[2]) for c in cam]
            shade = 0.52 + 0.48 * max(0.0, float(np.dot(nw, LIGHT)))
            c = col * shade
            for tri in ((0, 1, 2), (0, 2, 3)):
                (x0, y0, z0), (x1, y1, z1), (x2, y2, z2) = (scr[i] for i in tri)
                minx, maxx = max(int(min(x0, x1, x2)), 0), min(int(max(x0, x1, x2)) + 1, W)
                miny, maxy = max(int(min(y0, y1, y2)), 0), min(int(max(y0, y1, y2)) + 1, H)
                if minx >= maxx or miny >= maxy: continue
                den = (y1 - y2) * (x0 - x2) + (x2 - x1) * (y0 - y2)
                if abs(den) < 1e-9: continue
                ys, xs = np.mgrid[miny:maxy, minx:maxx]; xs = xs + 0.5; ys = ys + 0.5
                w0 = ((y1 - y2) * (xs - x2) + (x2 - x1) * (ys - y2)) / den
                w1 = ((y2 - y0) * (xs - x2) + (x0 - x2) * (ys - y2)) / den
                w2 = 1 - w0 - w1
                inside = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
                z = 1 / (w0 / z0 + w1 / z1 + w2 / z2 + 1e-12)
                sub = zb[miny:maxy, minx:maxx]; m = inside & (z < sub)
                reg = img[miny:maxy, minx:maxx]
                if tr > 0.05:
                    reg[m] = reg[m] * tr + c * (1 - tr)
                else:
                    reg[m] = c; sub[m] = z[m]
    Image.fromarray(img.clip(0, 255).astype(np.uint8)).save(out, quality=88); print("wrote", out)

if __name__ == "__main__":
    parts = load(sys.argv[1]); print(len(parts), "parts")
    YP, YL, Y6 = 54.5, 63.5, 117.5
    V = {
        "1_front_from_pyay_road": ((470, 78, -175), (300, 96, -165), 62, ()),
        "2_aerial_south_east": ((520, 330, 150), (190, 95, -110), 50, ()),
        "3_lobby_reception": ((294, YL + 6, -150), (226, YL + 7, -196), 78, ()),
        "4_lobby_lounge": ((236, YL + 6, -205), (285, YL + 4, -125), 78, ()),
        "5_pool_deck": ((236, Y6 + 9, -104), (345, Y6 - 2, -58), 72, ()),
        "6_court": ((230, Y6 + 12, -8), (150, Y6, -50), 72, ()),
        "7_car_park": ((170, YP + 5, -216), (176, YP + 3.5, -60), 80, ()),
        "8_gate_from_lane": ((170, YP + 8, -262), (170, YP + 4, -215), 70, ()),
    }
    for k, (eye, tgt, fov, skip) in V.items():
        if len(sys.argv) > 2 and not any(s in k for s in sys.argv[2:]): continue
        render(parts, eye, tgt, fov, 1100, 700, "preview/%s.jpg" % k, skip)
