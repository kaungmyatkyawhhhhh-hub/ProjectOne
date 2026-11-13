"""bnw_m3_e92_glbfix.py in.glb out.glb : the E92 GTS .glb readied for auto_car.py, after tools/paint_glb.py
(tools/logo_paint/bnw_m3_e92.json), 2026-11-13. Pure Python (numpy, Pillow), no Blender. What this model needs that the
paint job can't say:

  * the roll cage (node "...M_Internal_Engine_High_carPaint_0") wears the body's paint material: it gets its own material
    "cage_orange", so finish_car.py makes it its own part and Customs paint never recolours it;
  * the lower grilles' material is made opaque with a colour factor of 1 (the file has a white see-through hex picture
    and a dark factor Studio drops; the paint job swaps in a dark opaque picture);
  * the cabin's carbon trim (node "...M_InternalTiled_High_carbon_0": dash strip, door and rear side strips) gets its
    own material "Cabin_Carbon", so finish_car.py makes Body_CabinCarbon (glossy carbon inside a cabin mirrors the sky;
    the roof, node "...PlasticRoughBlack_High_carbon_0", stays "carbon" = Body_Carbon);
  * the cabin mesh ("...M_Internal_Engine_High_internal_0", one 256 x 512 picture) is split in three nodes by where
    each piece's UVs lie and where it is on the car:
        "Interior_Main"  the picture's lower half (the cabin's controls and flat colours): UVs stretched to a square,
                         picture = the paint job's 1024 x 1024 cabin picture (image 21) and its normal picture (22);
        "Engine_Bay"     the upper half's pieces under the bonnet (all of a piece ahead of y = -1.0 m);
        "Interior_Parts" the upper half's other pieces (gear lever, handbrake, the scuttle under the windscreen,
                         the boot's side pieces): both use tools/logo_paint/bnw_m3_e92_bay.png / _bay_n.png,
                         put into the file here;
    so the controls get 4 picture pixels for each of the model's and the engine is its own part (Body_Engine);
  * the four loose tyre valves (38 triangles each, in the rim node) are cut: they would float after the kit wheels
    replace the rims.
"""
import copy
import io
import json
import os
import struct
import sys

import numpy as np
from PIL import Image

src, out = sys.argv[1:3]
HERE = os.path.dirname(os.path.abspath(__file__))
b = open(src, "rb").read()
n = struct.unpack("<I", b[12:16])[0]
j = json.loads(b[20 : 20 + n])
off = 20 + n
blen = struct.unpack("<I", b[off : off + 4])[0]
binc = bytearray(b[off + 8 : off + 8 + blen])
mats = j["materials"]
CT = {5126: np.float32, 5123: np.uint16, 5125: np.uint32, 5121: np.uint8}
NC = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def midx(name):
    return next(i for i, m in enumerate(mats) if m.get("name") == name)


def clone(name, new):
    m = copy.deepcopy(mats[midx(name)])
    m["name"] = new
    mats.append(m)
    return len(mats) - 1


def node(word):
    return next(nd for nd in j["nodes"] if "mesh" in nd and word in nd.get("name", ""))


def _local(nd):
    if "matrix" in nd:
        return np.array(nd["matrix"], dtype=np.float64).reshape(4, 4).T
    x, y, z, w = nd.get("rotation", [0, 0, 0, 1])
    R = np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)], [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)], [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])
    M = np.eye(4)
    M[:3, :3] = R @ np.diag(nd.get("scale", [1, 1, 1]))
    M[:3, 3] = nd.get("translation", [0, 0, 0])
    return M


WORLD = {}


def _walk(i, Pm):
    M = Pm @ _local(j["nodes"][i])
    WORLD[i] = M
    for c in j["nodes"][i].get("children", []):
        _walk(c, M)


for r in j["scenes"][j.get("scene", 0)]["nodes"]:
    _walk(r, np.eye(4))


def car_frame(nd, P):
    """a node's points in the car's frame, metres (x across, y back, z up; the file's world is 1 = 100 m, y up, -z back)"""
    M = WORLD[j["nodes"].index(nd)]
    W = P @ M[:3, :3].T + M[:3, 3]
    return np.c_[W[:, 0], -W[:, 2], W[:, 1]] * 100.0


def read(i):
    a = j["accessors"][i]
    bv = j["bufferViews"][a["bufferView"]]
    k = NC[a["type"]]
    dt = CT[a["componentType"]]
    o = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    sz = np.dtype(dt).itemsize * k
    st = bv.get("byteStride", 0) or sz
    raw = np.frombuffer(bytes(binc[o : o + (a["count"] - 1) * st + sz]), dtype=np.uint8)
    idx = (np.arange(a["count"])[:, None] * st + np.arange(sz)[None, :]).ravel()
    return np.frombuffer(raw[idx].tobytes(), dtype=dt).reshape(a["count"], k)


def add_view(data, target=None):
    while len(binc) % 4:
        binc.append(0)
    bv = {"buffer": 0, "byteOffset": len(binc), "byteLength": len(data)}
    if target:
        bv["target"] = target
    binc.extend(data)
    j["bufferViews"].append(bv)
    return len(j["bufferViews"]) - 1


def add_acc(arr, kind):
    arr = np.ascontiguousarray(arr)
    ct = {np.dtype(np.float32): 5126, np.dtype(np.uint32): 5125, np.dtype(np.uint16): 5123}[arr.dtype]
    a = {"bufferView": add_view(arr.tobytes(), 34963 if kind == "SCALAR" else 34962), "componentType": ct, "count": int(arr.shape[0]), "type": kind}
    if kind == "VEC3" and ct == 5126:
        a["min"] = [float(v) for v in arr.min(0)]
        a["max"] = [float(v) for v in arr.max(0)]
    j["accessors"].append(a)
    return len(j["accessors"]) - 1


def sub_prim(prim, arrays, I, faces, material, uv_fn=None):
    """a new primitive of the triangles `faces` with its own compact vertex arrays"""
    t = I[faces]
    used, inv = np.unique(t, return_inverse=True)
    att = {}
    for name, arr in arrays.items():
        a = arr[used].astype(np.float32)
        if uv_fn and name.startswith("TEXCOORD"):
            a = uv_fn(a.copy())
        att[name] = add_acc(a, {2: "VEC2", 3: "VEC3", 4: "VEC4"}[a.shape[1]])
    p = {"attributes": att, "indices": add_acc(inv.reshape(-1).astype(np.uint32), "SCALAR"), "material": material, "mode": 4}
    return p


def groups(I, keys):
    par = {}

    def find(x):
        while par.setdefault(x, x) != x:
            par[x] = par[par[x]]
            x = par[x]
        return x

    for t in I:
        r = find(keys[t[0]])
        for v in t[1:]:
            par[find(keys[v])] = r
    return np.array([find(keys[t[0]]) for t in I])


def weld(A, dec):
    return np.unique(np.round(A, dec), axis=0, return_inverse=True)[1].reshape(-1)


report = {}
# 1. the roll cage out of the paint
cage = clone("carPaint", "cage_orange")
for p in j["meshes"][node("M_Internal_Engine_High_carPaint_0")["mesh"]]["primitives"]:
    p["material"] = cage
# 2. the lower grilles: opaque, no dark factor
g = mats[midx("grille")]
g["alphaMode"] = "OPAQUE"
g.setdefault("pbrMetallicRoughness", {})["baseColorFactor"] = [1.0, 1.0, 1.0, 1.0]
# 3. the cabin's carbon
cc = clone("carbon", "Cabin_Carbon")
for p in j["meshes"][node("M_InternalTiled_High_carbon_0")["mesh"]]["primitives"]:
    p["material"] = cc
report["cabin carbon tris"] = sum(j["accessors"][p["indices"]]["count"] // 3 for p in j["meshes"][node("M_InternalTiled_High_carbon_0")["mesh"]]["primitives"])


# 4. the cabin mesh in three
def add_image(path):
    data = open(path, "rb").read()
    j["images"].append({"bufferView": add_view(data), "mimeType": "image/png"})
    j["textures"].append({"sampler": 0, "source": len(j["images"]) - 1})
    return len(j["textures"]) - 1


main = midx("internal")
mats[main]["name"] = "Interior_Main"
mats[main]["alphaMode"] = "OPAQUE"
t_bay, t_bay_n = add_image(os.path.join(HERE, "bnw_m3_e92_bay.png")), add_image(os.path.join(HERE, "bnw_m3_e92_bay_n.png"))
bay = clone("Interior_Main", "Engine_Bay")
mats[bay]["pbrMetallicRoughness"]["baseColorTexture"] = {"index": t_bay}
mats[bay]["normalTexture"] = {"index": t_bay_n}
parts_m = clone("Engine_Bay", "Interior_Parts")
cab_node = node("M_Internal_Engine_High_internal_0")
mesh = j["meshes"][cab_node["mesh"]]
assert len(mesh["primitives"]) == 1
prim = mesh["primitives"][0]
arrays = {k: read(v) for k, v in prim["attributes"].items()}
I = read(prim["indices"]).reshape(-1, 3).astype(np.int64)
P, UV = car_frame(cab_node, arrays["POSITION"].astype(np.float64)), arrays["TEXCOORD_0"].astype(np.float64)
vmid = UV[I][:, :, 1].mean(1)
assert not ((UV[I][:, :, 1].min(1) < 0.4995) & (UV[I][:, :, 1].max(1) > 0.5005)).any(), "a face lies across the picture's two halves"
lab = groups(I, weld(np.c_[P, UV], 4))  # the picture's pieces (faces joined through shared corners)
ymax = {l: P[np.unique(I[lab == l])][:, 1].max() for l in np.unique(lab)}
under = np.array([ymax[l] < -1.0 for l in lab])  # the whole piece ahead of y = -1.0 m: under the bonnet
f_main = np.where(vmid >= 0.5)[0]
f_bay = np.where((vmid < 0.5) & under)[0]
f_parts = np.where((vmid < 0.5) & ~under)[0]


def lower(uv):
    uv[:, 1] = (uv[:, 1] - 0.5) * 2.0
    return uv


def upper(uv):
    uv[:, 1] = uv[:, 1] * 2.0
    return uv


# (three nodes, not three primitives of one mesh: auto_car.py keeps a node as one part and names it after its first material)
mesh["primitives"] = [sub_prim(prim, arrays, I, f_main, main, lower)]
parent = next(nd for nd in j["nodes"] if j["nodes"].index(cab_node) in nd.get("children", []))
for word, faces, mat in (("bay", f_bay, bay), ("parts", f_parts, parts_m)):
    j["meshes"].append({"primitives": [sub_prim(prim, arrays, I, faces, mat, upper)]})
    nd = {k: copy.deepcopy(v) for k, v in cab_node.items() if k in ("matrix", "translation", "rotation", "scale")}
    nd["name"] = "Mesh:M_Internal_Engine_High_%s_0" % word
    nd["mesh"] = len(j["meshes"]) - 1
    j["nodes"].append(nd)
    parent["children"].append(len(j["nodes"]) - 1)
report["cabin tris main / engine bay / parts"] = [len(f_main), len(f_bay), len(f_parts)]
assert len(f_main) + len(f_bay) + len(f_parts) == len(I)

# 5. the tyre valves out of the rim node
rim_node = node("M_Rim_High")
mesh = j["meshes"][rim_node["mesh"]]
prim = mesh["primitives"][0]
arrays = {k: read(v) for k, v in prim["attributes"].items()}
I = read(prim["indices"]).reshape(-1, 3).astype(np.int64)
P = car_frame(rim_node, arrays["POSITION"].astype(np.float64))
lab = groups(I, weld(P, 5))
keep = np.ones(len(I), bool)
cut = 0
for l in np.unique(lab):
    f = np.where(lab == l)[0]
    v = P[np.unique(I[f])]
    if len(f) == 38 and (v.max(0) - v.min(0)).max() < 0.05:  # (a valve is 32 mm long)
        keep[f] = False
        cut += 1
assert cut == 4, cut
mesh["primitives"] = [sub_prim(prim, arrays, I, np.where(keep)[0], prim["material"])]
report["valves cut"] = cut

j["buffers"][0]["byteLength"] = len(binc)
js = json.dumps(j, separators=(",", ":")).encode()
js += b" " * ((4 - len(js) % 4) % 4)
while len(binc) % 4:
    binc.append(0)
j["buffers"][0]["byteLength"] = len(binc)
js = json.dumps(j, separators=(",", ":")).encode()
js += b" " * ((4 - len(js) % 4) % 4)
with open(out, "wb") as f:
    f.write(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(binc)))
    f.write(struct.pack("<II", len(js), 0x4E4F534A))
    f.write(js)
    f.write(struct.pack("<II", len(binc), 0x004E4942))
    f.write(bytes(binc))
print("GLBFIX", json.dumps(report), "->", out)
