# GYM ARC plates v4 (owner, 5 Nov: a stripe on EVERY plate, a real metal look). Makes:
#   gymarc_plate_disc.obj   one 12-sided disc, 48 triangles, UVs, axis X, 1 x 1 x 1 (scaled by Size like the old PlateMesh)
#   plate_<type>_color.png  a ColorMap per plate type (8 standard sizes + 6 tiers), 512 x 256
#   plate_metal_metalness / _roughness, plate_crystal_metalness / _roughness   shared maps
# Pure Python (no Pillow). Layout: left square = the face (a circle; both sides share it), right square = the rim.
# Run: python make_plates.py <out folder>
import math, struct, zlib, os, sys

OUT = sys.argv[1] if len(sys.argv) > 1 else "."
W, H = 512, 256
CX, CY, R = 128, 128, 120


def png(path, px, mode="RGBA"):
    ch = 4 if mode == "RGBA" else 1
    ct = 6 if mode == "RGBA" else 0
    raw = bytearray()
    for y in range(H):
        raw.append(0)
        raw.extend(px[y * W * ch:(y + 1) * W * ch])

    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)

    data = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, ct, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b""))
    with open(path, "wb") as f:
        f.write(data)


def hexrgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def clamp(v):
    return max(0, min(255, int(v)))


# zones on the face, by r / R
def zone(r):
    if r < 0.09:
        return "hole"
    if r < 0.22:
        return "hub"
    if r < 0.84:
        return "face"
    if r < 0.89:
        return "bevel"
    return "stripe"


def colormap(kind, face, stripe, alpha_face=255):
    face, stripe = hexrgb(face), hexrgb(stripe)
    px = bytearray(W * H * 4)
    for y in range(H):
        for x in range(W):
            i = (y * W + x) * 4
            a = 255
            if x < 256:
                dx, dy = x - CX, y - CY
                r = math.hypot(dx, dy) / R
                ang = math.atan2(dy, dx)
                z = zone(r)
                if z == "hole":
                    c = (34, 36, 42)
                elif z == "hub":
                    c = mix(face, (90, 96, 106), 0.45) if kind != "crystal" else (70, 74, 82)
                elif z == "face":
                    if kind == "crystal":
                        facet = 0.5 + 0.5 * math.cos(6 * ang)
                        t = 0.25 * (1 - r) + 0.12 * facet
                        c = mix(face, (255, 255, 255), t)
                        a = alpha_face
                    else:
                        rings = 0.035 * math.sin(r * 140) + 0.025 * math.sin(r * 61)
                        sheen = 0.10 * math.cos(ang - 0.8) * (1 - r)
                        c = tuple(clamp(face[k] * (1 + rings + sheen)) for k in range(3))
                elif z == "bevel":
                    c = mix(face, (245, 247, 250), 0.55)
                else:
                    c = stripe
            else:
                v = y / H
                c = tuple(clamp(stripe[k] * (0.85 + 0.25 * math.sin(v * math.pi))) for k in range(3))
            px[i:i + 4] = bytes((c[0], c[1], c[2], a))
    return px


def graymap(values):
    px = bytearray(W * H)
    for y in range(H):
        for x in range(W):
            if x < 256:
                px[y * W + x] = values[zone(math.hypot(x - CX, y - CY) / R)]
            else:
                px[y * W + x] = values["rim"]
    return px


STD = {5: "#C9CDD3", 10: "#2E9E4F", 25: "#E8C21C", 35: "#F07C1A", 45: "#1F5FBF", 55: "#D7262E", 65: "#1B1B1F", 75: "#19B3A6"}
STEEL = "#BAC1CB"
for lb, stripe in STD.items():
    png(os.path.join(OUT, "plate_std_%d_color.png" % lb), colormap("metal", STEEL, stripe))
TIERS = {"bronze": ("#C27A44", "#D98A4A"), "silver": ("#DDE3EC", "#E6EAF0"), "gold": ("#E2BE3A", "#FFD23F"), "platinum": ("#9AACCB", "#9DB8FF")}
for k, (face, stripe) in TIERS.items():
    png(os.path.join(OUT, "plate_%s_color.png" % k), colormap("metal", face, stripe))
png(os.path.join(OUT, "plate_ruby_color.png"), colormap("crystal", "#C8102E", "#FF3A4E", 255))
png(os.path.join(OUT, "plate_diamond_color.png"), colormap("crystal", "#BFE9FF", "#A6E6FF", 150))
# metal = 1 on the plate, 0 on the painted stripe ring (the words are printed by the game on the outer face); crystal face 0
png(os.path.join(OUT, "plate_metal_metalness.png"), graymap({"hole": 0, "hub": 255, "face": 255, "bevel": 255, "stripe": 0, "rim": 255}), "L")
png(os.path.join(OUT, "plate_crystal_metalness.png"), graymap({"hole": 0, "hub": 255, "face": 0, "bevel": 0, "stripe": 0, "rim": 255}), "L")
# roughness: face 0.25, rim / bevel 0.15, paint 0.45, hole 0.8
png(os.path.join(OUT, "plate_metal_roughness.png"), graymap({"hole": 204, "hub": 77, "face": 64, "bevel": 38, "stripe": 115, "rim": 38}), "L")
png(os.path.join(OUT, "plate_crystal_roughness.png"), graymap({"hole": 204, "hub": 77, "face": 20, "bevel": 20, "stripe": 64, "rim": 38}), "L")

# ---- the mesh: 12 sides, 12 + 12 + 24 = 48 triangles
N = 12
v, vt, vn, f = [], [], [], []


def addv(p):
    v.append(p)
    return len(v)


def addvt(u, w):
    vt.append((u, w))
    return len(vt)


def addvn(n):
    vn.append(n)
    return len(vn)


def tri(a, b, c, want):
    pa, pb, pc = v[a[0] - 1], v[b[0] - 1], v[c[0] - 1]
    u = [pb[k] - pa[k] for k in range(3)]
    w = [pc[k] - pa[k] for k in range(3)]
    n = (u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2], u[0] * w[1] - u[1] * w[0])
    if sum(n[k] * want[k] for k in range(3)) < 0:
        b, c = c, b
    f.append((a, b, c))


for x, want in ((0.5, (1, 0, 0)), (-0.5, (-1, 0, 0))):
    ni = addvn(want)
    c = addv((x, 0, 0))
    cuv = addvt(0.25, 0.5)
    ring = []
    for i in range(N):
        a = 2 * math.pi * i / N
        ring.append((addv((x, 0.5 * math.cos(a), 0.5 * math.sin(a))),
                     addvt(0.25 + (R / W) * math.cos(a), 0.5 + (R / H) * math.sin(a))))
    for i in range(N):
        r1, r2 = ring[i], ring[(i + 1) % N]
        tri((c, cuv, ni), (r1[0], r1[1], ni), (r2[0], r2[1], ni), want)
cols = []
for i in range(N + 1):
    a = 2 * math.pi * i / N
    y, z = 0.5 * math.cos(a), 0.5 * math.sin(a)
    n = addvn((0, math.cos(a), math.sin(a)))
    u = 0.5 + 0.5 * i / N
    cols.append((addv((0.5, y, z)), addv((-0.5, y, z)), addvt(u, 0.0), addvt(u, 1.0), n))
for i in range(N):
    a, b = cols[i], cols[i + 1]
    am = 2 * math.pi * (i + 0.5) / N
    want = (0, math.cos(am), math.sin(am))
    tri((a[0], a[2], a[4]), (a[1], a[3], a[4]), (b[1], b[3], b[4]), want)
    tri((a[0], a[2], a[4]), (b[1], b[3], b[4]), (b[0], b[2], b[4]), want)
with open(os.path.join(OUT, "gymarc_plate_disc.obj"), "w") as o:
    o.write("# GYM ARC plate disc v4: 12 sides, %d triangles, axis X, 1 x 1 x 1\n" % len(f))
    for p in v:
        o.write("v %.5f %.5f %.5f\n" % p)
    for t in vt:
        o.write("vt %.5f %.5f\n" % t)
    for n in vn:
        o.write("vn %.5f %.5f %.5f\n" % n)
    o.write("o PlateDisc\n")
    for tr in f:
        o.write("f " + " ".join("%d/%d/%d" % c for c in tr) + "\n")
print("triangles", len(f))
