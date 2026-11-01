import json, struct
CT = {5120: "b", 5121: "B", 5122: "h", 5123: "H", 5125: "I", 5126: "f"}
NC = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}
def read_glb(path):
    b = open(path, "rb").read()
    clen, = struct.unpack_from("<I", b, 12)
    j = json.loads(b[20:20 + clen])
    off = 20 + clen
    blen, = struct.unpack_from("<I", b, off)
    return j, b[off + 8: off + 8 + blen]
def accessor(j, bin_, i):
    a = j["accessors"][i]; bv = j["bufferViews"][a["bufferView"]]
    n = NC[a["type"]]; fmt = CT[a["componentType"]]; size = struct.calcsize(fmt)
    stride = bv.get("byteStride", n * size)
    base = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    out = []
    for k in range(a["count"]):
        v = struct.unpack_from("<" + fmt * n, bin_, base + k * stride)
        out.append(v if n > 1 else v[0])
    return out
