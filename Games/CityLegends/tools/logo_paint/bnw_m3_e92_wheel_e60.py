"""bnw_m3_e92_wheel_e60.py [out.glb]: the E60 model's steering wheel for the E92 (owner, 2026-11-13: "can u make the m3 e92
have the m5 e60's steering wheel"), made with no Blender. Rim, hub and spokes, pad, stitching ring, paddles and face marks of
`CarModels.bnw_m5_e60`'s five SteeringWheel_t21 parts; its column stalks, shroud and stray bits are left out (loose pieces
that start 6 cm or more ahead of the rim plane). The pieces were read in Studio Edit with EditableMesh (positions, normals
and UVs by face corner, metres, relative to the E60 rim's middle (-0.3731, 0.8903, -0.3241), rim normal (0.0002, -0.3714,
-0.9285)) and dumped as text: `@name|verts|tris`, then `x,y,z,nx,ny,nz,u,v,r,g,b,a;` rows (1e-5 m, 1e-3, 1e-4), then the
triangles' indices. Here they are laid on the E92's column: the rim's middle on the E92 rim's middle, turned 1.8 degrees
about the car's side axis (the E60's 21.8 degree lean to the E92's 20.0), and written as a .glb (x and z negated: Roblox's
importer turns a .glb half a turn about the up axis, so it lands straight; 1 unit = 1 stud; UVs kept as they are).
Then: Open Cloud upload as a Model (group 33151111), LoadAsset, the five parts into `CarModels.bnw_m3_e92` with the E60
pieces' TextureIDs and SurfaceAppearances; parts named SteeringWheel_t20[.001-.004]."""
import json, math, struct, sys, os

HERE = os.path.dirname(os.path.abspath(__file__))
DUMP = os.path.join(HERE, "..", "..", "imports", "new_cars", "bnw_m3_e92_wheel_e60.dump.txt")  # (on the PC, not in git)
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "imports", "new_cars", "bnw_m3_e92_wheel_e60.glb")
V_FLIP = REV = False  # (not needed: Roblox keeps a .glb's UVs and winding)
s = open(DUMP, encoding="utf-8").read()
assert len(s) == 422917, len(s)

C92 = (-0.3593, 0.9065, -0.2615)  # the E92 rim's middle, Studio axes (x right, y up, z back), metres
A60 = math.atan2(0.3714, 0.9285)  # the E60 rim plane's lean (21.8 deg)
TH = A60 - math.radians(20.0)  # about +X: 21.8 -> 20.0
ct, st = math.cos(TH), math.sin(TH)


def rot(x, y, z):
    return (x, y * ct - z * st, y * st + z * ct)


pieces = []
for blk in s.split("@")[1:]:
    head, vtxt, ttxt = blk.split("\n")[:3]
    name, nv, nt = head.split("|")
    nv, nt = int(nv), int(nt)
    verts = [tuple(int(a) for a in row.split(",")) for row in vtxt.split(";")]
    tris = [int(a) for a in ttxt.split(",")]
    assert len(verts) == nv and len(tris) == nt * 3, (name, len(verts), nv, len(tris), nt)
    P, N, U = [], [], []
    for v in verts:
        x, y, z = rot(v[0] / 1e5, v[1] / 1e5, v[2] / 1e5)
        # Roblox's importer turns a .glb half a turn about the up axis: written turned, it lands straight
        P.append((-(x + C92[0]), y + C92[1], -(z + C92[2])))
        nx, ny, nz = rot(v[3] / 1000, v[4] / 1000, v[5] / 1000)
        l = math.sqrt(nx * nx + ny * ny + nz * nz) or 1.0
        if l < 1e-6:
            nx, ny, nz, l = 0.0, 1.0, 0.0, 1.0
        N.append((-nx / l, ny / l, -nz / l))
        u, w = v[6] / 1e4, v[7] / 1e4
        U.append((u, 1 - w if V_FLIP else w))
    if REV:
        tris = [t for i in range(0, len(tris), 3) for t in (tris[i], tris[i + 2], tris[i + 1])]
    pieces.append(dict(name=name.replace("_t21", "_t20"), P=P, N=N, U=U, T=tris))

buf = bytearray()
views, accs, meshes, nodes, mats = [], [], [], [], []


def add(data, target):
    while len(buf) % 4:
        buf.append(0)
    views.append(dict(buffer=0, byteOffset=len(buf), byteLength=len(data), target=target))
    buf.extend(data)
    return len(views) - 1


info = {}
for i, pc in enumerate(pieces):
    P, N, U, T = pc["P"], pc["N"], pc["U"], pc["T"]
    lo = [min(p[k] for p in P) for k in range(3)]
    hi = [max(p[k] for p in P) for k in range(3)]
    vp = add(b"".join(struct.pack("<3f", *p) for p in P), 34962)
    accs.append(dict(bufferView=vp, componentType=5126, count=len(P), type="VEC3", min=lo, max=hi))
    vn = add(b"".join(struct.pack("<3f", *n) for n in N), 34962)
    accs.append(dict(bufferView=vn, componentType=5126, count=len(N), type="VEC3"))
    vu = add(b"".join(struct.pack("<2f", *u) for u in U), 34962)
    accs.append(dict(bufferView=vu, componentType=5126, count=len(U), type="VEC2"))
    vi = add(struct.pack("<%dH" % len(T), *T), 34963)
    accs.append(dict(bufferView=vi, componentType=5123, count=len(T), type="SCALAR"))
    b = len(accs) - 4
    mats.append(dict(name="wheel_e60_%d" % i, pbrMetallicRoughness=dict(baseColorFactor=[0.2, 0.2, 0.2, 1], metallicFactor=0, roughnessFactor=0.8)))
    meshes.append(dict(name=pc["name"], primitives=[dict(attributes=dict(POSITION=b, NORMAL=b + 1, TEXCOORD_0=b + 2), indices=b + 3, material=i)]))
    nodes.append(dict(name=pc["name"], mesh=i))
    step = max(1, len(P) // 12)
    info[pc["name"]] = dict(mid=[(lo[k] + hi[k]) / 2 for k in range(3)], ext=[hi[k] - lo[k] for k in range(3)], tris=len(T) // 3, verts=len(P),
                            samples=[[round(c, 5) for c in P[j]] for j in range(0, len(P), step)][:12],
                            uvs=[[round(c, 4) for c in U[j]] for j in range(0, len(P), step)][:12])
nodes.append(dict(name="bnw_m3_e92_wheel_e60", children=list(range(len(pieces)))))
gltf = dict(asset=dict(version="2.0", generator="mkwheel.py"), scene=0, scenes=[dict(nodes=[len(nodes) - 1])], nodes=nodes, meshes=meshes, materials=mats,
            accessors=accs, bufferViews=views, buffers=[dict(byteLength=len(buf))])
js = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
while len(js) % 4:
    js += b" "
while len(buf) % 4:
    buf.append(0)
total = 12 + 8 + len(js) + 8 + len(buf)
with open(OUT, "wb") as f:
    f.write(struct.pack("<4sII", b"glTF", 2, total))
    f.write(struct.pack("<I4s", len(js), b"JSON"))
    f.write(js)
    f.write(struct.pack("<I4s", len(buf), b"BIN\0"))
    f.write(bytes(buf))
json.dump(info, open(os.path.splitext(OUT)[0] + ".json", "w"), separators=(",", ":"))
allp = [p for pc in pieces for p in pc["P"]]
lo = [min(p[k] for p in allp) for k in range(3)]
hi = [max(p[k] for p in allp) for k in range(3)]
print("wrote", OUT, total, "bytes;", "theta %.2f deg" % math.degrees(TH))
for k, v in info.items():
    print(k, "tris", v["tris"], "verts", v["verts"], "mid", [round(a, 4) for a in v["mid"]], "ext", [round(a, 4) for a in v["ext"]])
print("union box lo", [round(a, 4) for a in lo], "hi", [round(a, 4) for a in hi], "mid", [round((lo[k] + hi[k]) / 2, 4) for k in range(3)], "ext", [round(hi[k] - lo[k], 4) for k in range(3)])
