"""glb_split.py <file.glb> <n> (19 Nov 2026, P4 night cells were 23 MB > the 20 MB Open Cloud cap): split a glb.write_glb file by mesh into <file>_a.glb, _b.glb ... (bytes copied as-is)."""
# split a glb (one view per accessor, like glb.write_glb) into N files by mesh, bytes copied as-is
import json, struct, sys
sys.path.insert(0, r"D:/ObsidianOne/Claude+Obsidian/Games/CityLegends/tools")
from gltf_io import read_glb
src, n = sys.argv[1], int(sys.argv[2])
j, b = read_glb(src)
ms = j["meshes"]; per = -(-len(ms) // n)
for f in range(n):
    buf = bytearray(); views = []; accs = []; meshes = []; nodes = []
    for m in ms[f * per:(f + 1) * per]:
        p = dict(m["primitives"][0]); amap = {}
        for k in list(p["attributes"].values()) + [p["indices"]]:
            a = dict(j["accessors"][k]); v = j["bufferViews"][a["bufferView"]]
            while len(buf) % 4: buf.append(0)
            views.append(dict(buffer=0, byteOffset=len(buf), byteLength=v["byteLength"], target=v.get("target", 34962)))
            buf += b[v.get("byteOffset", 0):v.get("byteOffset", 0) + v["byteLength"]]
            a["bufferView"] = len(views) - 1; accs.append(a); amap[k] = len(accs) - 1
        p["attributes"] = {kk: amap[vv] for kk, vv in p["attributes"].items()}; p["indices"] = amap[p["indices"]]
        meshes.append(dict(name=m["name"], primitives=[p])); nodes.append(dict(name=m["name"], mesh=len(meshes) - 1))
    nodes.append(dict(name="YangonBuildingMeshes", children=list(range(len(meshes)))))
    g = dict(asset=j["asset"], scene=0, scenes=[dict(nodes=[len(nodes) - 1])], nodes=nodes, meshes=meshes, materials=j["materials"],
             accessors=accs, bufferViews=views, buffers=[dict(byteLength=len(buf))])
    js = json.dumps(g, separators=(",", ":")).encode()
    while len(js) % 4: js += b" "
    while len(buf) % 4: buf.append(0)
    out = src.replace(".glb", "_%s.glb" % "ab"[f])
    with open(out, "wb") as o:
        o.write(struct.pack("<4sII", b"glTF", 2, 28 + len(js) + len(buf))); o.write(struct.pack("<I4s", len(js), b"JSON")); o.write(js)
        o.write(struct.pack("<I4s", len(buf), b"BIN\0")); o.write(bytes(buf))
    j2, b2 = read_glb(out); assert len(j2["meshes"]) == len(meshes)
    print(out, len(meshes), len(buf))
print("meshes", len(ms))
