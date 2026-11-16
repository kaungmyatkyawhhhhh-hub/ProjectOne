"""Standing Buddha figure for Kaba Aye's 20 arch niches (replaces the cone stand-ins in Studio).

Pure Python .glb, units = studs (1 m = 3 studs). Pedestal (octagon, 1 stud, no bottom) + a lathe figure
(robe hem, knees, waist, chest, shoulders, neck, head, ushnisha) with an elliptical cross-section (depth 0.7),
no bottom cap (it stands on the pedestal top: no coplanar faces). Same footprint as the old stand-in:
2.3 wide, 6.5 high. Box UVs, 1 UV = 1 stud.
    python kaba_aye_buddha_glb.py <out.glb>
"""
import json, math, struct, sys

SEG = 20
DEPTH = 0.7
# (height above pedestal top, radius) in studs
PROFILE = [(0.0, 0.56), (0.25, 0.60), (0.9, 0.55), (1.6, 0.50), (2.4, 0.54), (2.9, 0.50), (3.5, 0.62),
           (4.05, 0.73), (4.25, 0.64), (4.38, 0.40), (4.45, 0.22), (4.62, 0.22), (4.72, 0.30), (4.95, 0.37),
           (5.2, 0.33), (5.32, 0.24), (5.38, 0.17), (5.47, 0.10), (5.5, 0.0)]
PED_H, PED_R = 1.0, 1.15

P, N, UV, IDX = [], [], [], []


def vert(p, n):
    P.append(p); N.append(n); UV.append((p[0] + p[2], -p[1])); return len(P) - 1


def pedestal():
    k = 8
    pts = [(PED_R * math.cos(2 * math.pi * (i + .5) / k), PED_R * math.sin(2 * math.pi * (i + .5) / k)) for i in range(k)]
    for i in range(k):
        (x0, z0), (x1, z1) = pts[i], pts[(i + 1) % k]
        nx, nz = (x0 + x1) / 2, (z0 + z1) / 2; l = math.hypot(nx, nz); n = (nx / l, 0, nz / l)
        a = vert((x0, 0, z0), n); b = vert((x1, 0, z1), n); c = vert((x1, PED_H, z1), n); d = vert((x0, PED_H, z0), n)
        IDX.extend([a, c, b, a, d, c])
    ctr = vert((0, PED_H, 0), (0, 1, 0))
    ring = [vert((x, PED_H, z), (0, 1, 0)) for x, z in pts]
    for i in range(k):
        IDX.extend([ctr, ring[(i + 1) % k], ring[i]])


def figure():
    rows = []
    m = len(PROFILE)
    for j, (h, r) in enumerate(PROFILE):
        h0, r0 = PROFILE[max(j - 1, 0)]; h1, r1 = PROFILE[min(j + 1, m - 1)]
        dh, dr = h1 - h0, r1 - r0  # profile tangent -> normal (dh, -dr) in (radial, up)
        row = []
        for i in range(SEG):
            a = 2 * math.pi * i / SEG
            ca, sa = math.cos(a), math.sin(a)
            x, z = r * ca, r * sa * DEPTH
            nr, ny = dh, -dr
            nx, nz = nr * ca * DEPTH, nr * sa  # ellipse normal ~ (cos/1, sin/DEPTH) scaled
            l = math.sqrt(nx * nx + ny * ny + nz * nz) or 1
            row.append(vert((x, PED_H + h, z), (nx / l, ny / l, nz / l)))
        rows.append(row)
    for j in range(m - 1):
        for i in range(SEG):
            a, b = rows[j][i], rows[j][(i + 1) % SEG]
            c, d = rows[j + 1][(i + 1) % SEG], rows[j + 1][i]
            IDX.extend([a, c, b, a, d, c])


def check_winding():
    # outward faces: normal from the cross product must agree with the vertex normals
    bad = 0
    for t in range(0, len(IDX), 3):
        a, b, c = (P[i] for i in IDX[t:t + 3])
        u = [b[k] - a[k] for k in range(3)]; v = [c[k] - a[k] for k in range(3)]
        n = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
        if math.sqrt(sum(x * x for x in n)) < 1e-9: continue
        vn = N[IDX[t]]
        if sum(n[k] * vn[k] for k in range(3)) < 0: bad += 1
    return bad


pedestal(); figure()
bad = check_winding()
if bad > len(IDX) // 6:  # mostly inverted: flip all
    for t in range(0, len(IDX), 3): IDX[t + 1], IDX[t + 2] = IDX[t + 2], IDX[t + 1]
print('verts', len(P), 'tris', len(IDX) // 3, 'inverted before fix', bad, 'after', check_winding())

def pack(fmt, rows): return b''.join(struct.pack(fmt, *r) for r in rows)
pb, nb, ub = pack('<3f', P), pack('<3f', N), pack('<2f', UV)
ib = struct.pack('<%dI' % len(IDX), *IDX)
bins = [pb, nb, ub, ib]
off, views = 0, []
blob = b''
for b in bins:
    views.append({"buffer": 0, "byteOffset": len(blob), "byteLength": len(b)})
    blob += b + b'\0' * ((4 - len(b) % 4) % 4)
mn = [min(p[k] for p in P) for k in range(3)]; mx = [max(p[k] for p in P) for k in range(3)]
gl = {"asset": {"version": "2.0"}, "scene": 0, "scenes": [{"nodes": [0]}],
      "nodes": [{"name": "KabaAyeBuddha_YgnGoldLeaf_Bell", "mesh": 0}],
      "meshes": [{"name": "KabaAyeBuddha", "primitives": [{"attributes": {"POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2}, "indices": 3, "material": 0}]}],
      "materials": [{"name": "YgnGoldLeaf_Bell", "pbrMetallicRoughness": {"baseColorFactor": [0.77, 0.5, 0.2, 1], "metallicFactor": 0.6, "roughnessFactor": 0.4}}],
      "buffers": [{"byteLength": len(blob)}], "bufferViews": views,
      "accessors": [{"bufferView": 0, "componentType": 5126, "count": len(P), "type": "VEC3", "min": mn, "max": mx},
                    {"bufferView": 1, "componentType": 5126, "count": len(N), "type": "VEC3"},
                    {"bufferView": 2, "componentType": 5126, "count": len(UV), "type": "VEC2"},
                    {"bufferView": 3, "componentType": 5125, "count": len(IDX), "type": "SCALAR"}]}
js = json.dumps(gl).encode(); js += b' ' * ((4 - len(js) % 4) % 4)
out = struct.pack('<III', 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(blob)) + struct.pack('<II', len(js), 0x4E4F534A) + js + struct.pack('<II', len(blob), 0x004E4942) + blob
open(sys.argv[1], 'wb').write(out)
print('bbox', mn, mx)
