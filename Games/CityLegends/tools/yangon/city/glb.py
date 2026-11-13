"""glb.py: a minimal glTF 2.0 binary (.glb) writer for Roblox map meshes (pure Python, no Blender).

    from glb import Mesh, write_glb, code
    m = Mesh()
    m.quad(a, b, c, d, uva, uvb, uvc, uvd, rgb)     # corners counter-clockwise seen from OUTSIDE (the face that shows)
    m.tri(a, b, c, uva, uvb, uvc, rgb)
    write_glb(path, [(name, m), ...])              # name: see code(); mesh positions are WORLD studs

What goes in the file, per mesh (each mesh is its own node, named `name`):
  * POSITION float32, relative to the mesh's box centre, with x and z NEGATED: Roblox's importer turns a .glb half a turn
    about the up axis (E92 wheel, 2026-11-13), so written turned it lands straight. 1 unit = 1 stud.
  * NORMAL float32, flat by default (every triangle has its own 3 corners, nothing shared), so box corners stay sharp.
  * TEXCOORD_0 float32, as given (Roblox keeps a .glb's UVs: no V flip). U may run past 0..1 (atlas rows tile in U).
  * COLOR_0 normalized ubyte RGBA, alpha 255 (a model whose corner alpha was 0 went invisible: the F90, 2026-11-10).
    Roblox multiplies the vertex colour with the texture, so one atlas serves every wall colour.
  * uint16 indices, uint32 when a mesh has 65,535 vertices or more.
  * one material, no image (the atlas goes on as a SurfaceAppearance in Studio).
Winding: counter-clockwise from outside in world space; negating x and z is a rotation, so it stays right.

code(kind, id, centre, size) -> "kind_id_cx_cy_cz_sx_sy_sz" in hundredths of a stud, "n" for minus (export_fbx.py style).
"""
import json
import math
import struct


def _h(v):
    i = int(round(v * 100))
    return ("n%d" % -i) if i < 0 else ("%d" % i)


def code(kind, mid, centre, size):
    return "%s_%s_%s_%s_%s_%s_%s_%s" % ((kind, mid) + tuple(_h(c) for c in centre) + tuple(_h(s) for s in size))


def _sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def _cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def _unit(v):
    l = math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2])
    return (v[0] / l, v[1] / l, v[2] / l) if l > 1e-12 else (0.0, 1.0, 0.0)


class Mesh:
    """Triangles in world studs. P, N, U, C are per corner; T are corner indices (3 per triangle)."""

    def __init__(self):
        self.P, self.N, self.U, self.C, self.T = [], [], [], [], []

    @property
    def tris(self):
        return len(self.T) // 3

    def tri(self, a, b, c, ua, ub, uc, rgb, normals=None):
        n = _cross(_sub(b, a), _sub(c, a))
        if n[0] * n[0] + n[1] * n[1] + n[2] * n[2] < 1e-14:
            return  # degenerate
        n = _unit(n)
        i = len(self.P)
        self.P += [a, b, c]
        self.N += list(normals) if normals else [n, n, n]
        self.U += [ua, ub, uc]
        col = tuple(int(max(0, min(255, round(x)))) for x in rgb)
        self.C += [col, col, col]
        self.T += [i, i + 1, i + 2]

    def quad(self, a, b, c, d, ua, ub, uc, ud, rgb, normals=None):
        """a b c d counter-clockwise seen from the side that shows."""
        if normals:
            self.tri(a, b, c, ua, ub, uc, rgb, (normals[0], normals[1], normals[2]))
            self.tri(a, c, d, ua, uc, ud, rgb, (normals[0], normals[2], normals[3]))
        else:
            self.tri(a, b, c, ua, ub, uc, rgb)
            self.tri(a, c, d, ua, uc, ud, rgb)

    def extend(self, other):
        k = len(self.P)
        self.P += other.P
        self.N += other.N
        self.U += other.U
        self.C += other.C
        self.T += [t + k for t in other.T]

    def box(self):
        lo = [min(p[k] for p in self.P) for k in range(3)]
        hi = [max(p[k] for p in self.P) for k in range(3)]
        return lo, hi


def write_glb(path, named, generator="yangon city glb.py"):
    """named: list of (name, Mesh). Returns {name: {centre, size, tris, verts}}."""
    buf = bytearray()
    views, accs, meshes, nodes = [], [], [], []
    info = {}

    def add(data, target):
        while len(buf) % 4:
            buf.append(0)
        views.append(dict(buffer=0, byteOffset=len(buf), byteLength=len(data), target=target))
        buf.extend(data)
        return len(views) - 1

    for name, m in named:
        if not m.T:
            continue
        lo, hi = m.box()
        c = [(lo[k] + hi[k]) / 2 for k in range(3)]
        # relative to the box centre, x and z negated (the importer's half turn puts them back)
        P = [(-(p[0] - c[0]), p[1] - c[1], -(p[2] - c[2])) for p in m.P]
        N = [(-n[0], n[1], -n[2]) for n in m.N]
        plo = [min(p[k] for p in P) for k in range(3)]
        phi = [max(p[k] for p in P) for k in range(3)]
        b = len(accs)
        accs.append(dict(bufferView=add(b"".join(struct.pack("<3f", *p) for p in P), 34962), componentType=5126,
                         count=len(P), type="VEC3", min=plo, max=phi))
        accs.append(dict(bufferView=add(b"".join(struct.pack("<3f", *n) for n in N), 34962), componentType=5126,
                         count=len(N), type="VEC3"))
        accs.append(dict(bufferView=add(b"".join(struct.pack("<2f", *u) for u in m.U), 34962), componentType=5126,
                         count=len(m.U), type="VEC2"))
        accs.append(dict(bufferView=add(b"".join(struct.pack("<4B", col[0], col[1], col[2], 255) for col in m.C), 34962),
                         componentType=5121, normalized=True, count=len(m.C), type="VEC4"))
        big = len(P) >= 65535
        idx = struct.pack("<%d%s" % (len(m.T), "I" if big else "H"), *m.T)
        accs.append(dict(bufferView=add(idx, 34963), componentType=5125 if big else 5123, count=len(m.T), type="SCALAR"))
        meshes.append(dict(name=name, primitives=[dict(attributes=dict(POSITION=b, NORMAL=b + 1, TEXCOORD_0=b + 2, COLOR_0=b + 3),
                                                       indices=b + 4, material=0)]))
        nodes.append(dict(name=name, mesh=len(meshes) - 1))
        info[name] = dict(centre=c, size=[hi[k] - lo[k] for k in range(3)], tris=m.tris, verts=len(P))
    root = dict(name="YangonBuildingMeshes", children=list(range(len(nodes))))
    nodes.append(root)
    gltf = dict(asset=dict(version="2.0", generator=generator), scene=0, scenes=[dict(nodes=[len(nodes) - 1])], nodes=nodes,
                meshes=meshes, materials=[dict(name="facade", pbrMetallicRoughness=dict(baseColorFactor=[1, 1, 1, 1],
                                                                                         metallicFactor=0, roughnessFactor=0.9))],
                accessors=accs, bufferViews=views, buffers=[dict(byteLength=len(buf))])
    js = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
    while len(js) % 4:
        js += b" "
    while len(buf) % 4:
        buf.append(0)
    total = 12 + 8 + len(js) + 8 + len(buf)
    with open(path, "wb") as f:
        f.write(struct.pack("<4sII", b"glTF", 2, total))
        f.write(struct.pack("<I4s", len(js), b"JSON"))
        f.write(js)
        f.write(struct.pack("<I4s", len(buf), b"BIN\0"))
        f.write(bytes(buf))
    return info


def check_glb(path, info):
    """Read the file back with tools/gltf_io.py and compare counts and boxes with what was written."""
    import os
    import sys
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    from gltf_io import read_glb, accessor
    j, b = read_glb(path)
    bad = []
    for mesh in j["meshes"]:
        pr = mesh["primitives"][0]
        P = accessor(j, b, pr["attributes"]["POSITION"])
        T = accessor(j, b, pr["indices"])
        C = accessor(j, b, pr["attributes"]["COLOR_0"])
        want = info[mesh["name"]]
        if len(T) // 3 != want["tris"] or len(C) != len(P) or max(T) >= len(P):
            bad.append(mesh["name"])
            continue
        for k in range(3):
            ext = max(p[k] for p in P) - min(p[k] for p in P)
            if abs(ext - want["size"][k]) > 1e-3 or abs(max(p[k] for p in P) + min(p[k] for p in P)) > 1e-3:
                bad.append(mesh["name"])
                break
    return len(j["meshes"]), bad
