"""Merge several .glb models into one file for a single Import 3D.
Each model becomes a top node <name>, scaled so it is <height> studs tall (Import 3D reads
glTF units as studs), standing on y 0 at its middle, set out in a row.

usage: python -I merge_glb.py out.glb file.glb=Name=height [file.glb=Name=height ...]
  (height "w20" scales to 20 studs wide instead, for flat things)
"""
import sys, os, json, struct, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gltf_io import read_glb


def mat_mul(a, b):
    return [sum(a[r + 4 * k] * b[k + 4 * c] for k in range(4)) for c in range(4) for r in range(4)]


def node_matrix(n):
    if "matrix" in n:
        return list(n["matrix"])
    t = n.get("translation", [0, 0, 0]); r = n.get("rotation", [0, 0, 0, 1]); s = n.get("scale", [1, 1, 1])
    x, y, z, w = r
    R = [1 - 2 * (y * y + z * z), 2 * (x * y + z * w), 2 * (x * z - y * w), 0,
         2 * (x * y - z * w), 1 - 2 * (x * x + z * z), 2 * (y * z + x * w), 0,
         2 * (x * z + y * w), 2 * (y * z - x * w), 1 - 2 * (x * x + y * y), 0,
         0, 0, 0, 1]
    S = [s[0], 0, 0, 0, 0, s[1], 0, 0, 0, 0, s[2], 0, 0, 0, 0, 1]
    T = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, t[0], t[1], t[2], 1]
    return mat_mul(T, mat_mul(R, S))


def world_bbox(j):
    lo, hi = [1e18] * 3, [-1e18] * 3
    I = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]

    def walk(ni, M):
        n = j["nodes"][ni]
        W = mat_mul(M, node_matrix(n))
        if "mesh" in n:
            for p in j["meshes"][n["mesh"]]["primitives"]:
                a = j["accessors"][p["attributes"]["POSITION"]]
                for cx in (a["min"][0], a["max"][0]):
                    for cy in (a["min"][1], a["max"][1]):
                        for cz in (a["min"][2], a["max"][2]):
                            v = [W[0] * cx + W[4] * cy + W[8] * cz + W[12], W[1] * cx + W[5] * cy + W[9] * cz + W[13], W[2] * cx + W[6] * cy + W[10] * cz + W[14]]
                            for k in range(3):
                                lo[k] = min(lo[k], v[k]); hi[k] = max(hi[k], v[k])
        for c in n.get("children", []):
            walk(c, W)

    for r in j["scenes"][j.get("scene", 0)]["nodes"]:
        walk(r, I)
    return lo, hi


out = {"asset": {"version": "2.0", "generator": "CityLegends merge_glb.py"}, "scene": 0, "scenes": [{"nodes": []}],
       "nodes": [], "meshes": [], "accessors": [], "bufferViews": [], "buffers": [{"byteLength": 0}],
       "materials": [], "textures": [], "images": [], "samplers": []}
buf = bytearray()
credits = []
x_at = 0.0
for spec in sys.argv[2:]:
    path, name, height = spec.split("=")
    by_width = height.startswith("w")
    height = float(height.lstrip("w"))
    j, b = read_glb(path)
    ex = j.get("asset", {}).get("extras", {})
    if ex:
        credits.append("%s: \"%s\" by %s (%s)" % (name, ex.get("title"), ex.get("author", "").split(" (")[0], ex.get("license", "").split(" (")[0]))
    lo, hi = world_bbox(j)
    k = height / max((hi[0] - lo[0]) if by_width else (hi[1] - lo[1]), 1e-9)
    width = (hi[0] - lo[0]) * k
    off = {k2: len(out[k2]) for k2 in ("nodes", "meshes", "accessors", "bufferViews", "materials", "textures", "images", "samplers")}
    while len(buf) % 4:
        buf.append(0)
    boff = len(buf)
    buf.extend(b)
    for v in j.get("bufferViews", []):
        v = dict(v); v["buffer"] = 0; v["byteOffset"] = v.get("byteOffset", 0) + boff
        out["bufferViews"].append(v)
    for a in j.get("accessors", []):
        a = dict(a)
        if "bufferView" in a:
            a["bufferView"] += off["bufferViews"]
        out["accessors"].append(a)
    for im in j.get("images", []):
        im = dict(im)
        if "bufferView" in im:
            im["bufferView"] += off["bufferViews"]
        out["images"].append(im)
    for s in j.get("samplers", []):
        out["samplers"].append(s)
    for t in j.get("textures", []):
        t = dict(t)
        if "source" in t:
            t["source"] += off["images"]
        if "sampler" in t:
            t["sampler"] += off["samplers"]
        out["textures"].append(t)

    def fix_tex(d):
        if isinstance(d, dict):
            for kk, vv in list(d.items()):
                if kk.endswith("Texture") and isinstance(vv, dict) and "index" in vv:
                    vv["index"] += off["textures"]
                else:
                    fix_tex(vv)

    for m in j.get("materials", []):
        m = json.loads(json.dumps(m))
        fix_tex(m)
        m.pop("extensions", None) if False else None
        out["materials"].append(m)
    for me in j.get("meshes", []):
        me = json.loads(json.dumps(me))
        for p in me["primitives"]:
            p["attributes"] = {kk: vv + off["accessors"] for kk, vv in p["attributes"].items()}
            if "indices" in p:
                p["indices"] += off["accessors"]
            if "material" in p:
                p["material"] += off["materials"]
            p.pop("targets", None)
        out["meshes"].append(me)
    for n in j["nodes"]:
        n = json.loads(json.dumps(n))
        if "mesh" in n:
            n["mesh"] += off["meshes"]
        if "children" in n:
            n["children"] = [c + off["nodes"] for c in n["children"]]
        n.pop("skin", None); n.pop("camera", None)
        out["nodes"].append(n)
    roots = [r + off["nodes"] for r in j["scenes"][j.get("scene", 0)]["nodes"]]
    cx, cz = (lo[0] + hi[0]) / 2, (lo[2] + hi[2]) / 2
    out["nodes"].append({"name": name, "children": roots, "scale": [k, k, k],
                         "translation": [x_at + width / 2 - cx * k, -lo[1] * k, -cz * k]})
    out["scenes"][0]["nodes"].append(len(out["nodes"]) - 1)
    x_at += width + 20
    print("%-16s %s  scale %.5g  -> %.1f x %.1f x %.1f studs" % (name, os.path.basename(path), k, (hi[0] - lo[0]) * k, (hi[1] - lo[1]) * k, (hi[2] - lo[2]) * k))

for kk in ("samplers", "textures", "images", "materials"):
    if not out[kk]:
        del out[kk]
while len(buf) % 4:
    buf.append(0)
out["buffers"][0]["byteLength"] = len(buf)
used = set()
for j2 in []:
    pass
js = json.dumps(out).encode()
while len(js) % 4:
    js += b" "
glb = (struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(js) + 8 + len(buf)) + struct.pack("<I4s", len(js), b"JSON") + js
       + struct.pack("<I4s", len(buf), b"BIN\0") + bytes(buf))
open(sys.argv[1], "wb").write(glb)
print("wrote", sys.argv[1], len(glb) // 1024, "KB")
print("credits:\n  " + "\n  ".join(credits))
