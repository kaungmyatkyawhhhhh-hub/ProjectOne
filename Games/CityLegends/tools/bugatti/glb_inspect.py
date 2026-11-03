import sys, json, struct, os, re, collections
sys.path.insert(0, r"C:/Users/USER/ProjectOne/Games/CityLegends/tools")
from gltf_io import read_glb

def img_size(data):
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        w, h = struct.unpack(">II", data[16:24]); return w, h, "png"
    if data[:2] == b"\xff\xd8":
        i = 2
        while i < len(data):
            if data[i] != 0xFF: i += 1; continue
            m = data[i + 1]
            if m in (0xC0, 0xC1, 0xC2):
                h, w = struct.unpack(">HH", data[i + 5:i + 9]); return w, h, "jpg"
            L, = struct.unpack(">H", data[i + 2:i + 4]); i += 2 + L
    if data[:4] == b"RIFF": return 0, 0, "webp"
    return 0, 0, "?"

for path in sys.argv[1:]:
    j, b = read_glb(path)
    print("=" * 100)
    print(os.path.basename(path))
    a = j.get("asset", {})
    print("asset:", json.dumps({k: v for k, v in a.items()}, ensure_ascii=False)[:600])
    # triangles: per mesh, count, times instances
    inst = collections.Counter()
    def walk(n):
        node = j["nodes"][n]
        if "mesh" in node: inst[node["mesh"]] += 1
        for c in node.get("children", []): walk(c)
    for s in j.get("scenes", []):
        for n in s["nodes"]: walk(n)
    tri = 0
    for mi, m in enumerate(j.get("meshes", [])):
        t = 0
        for p in m["primitives"]:
            if "indices" in p: t += j["accessors"][p["indices"]]["count"] // 3
            else: t += j["accessors"][p["attributes"]["POSITION"]]["count"] // 3
        tri += t * inst[mi]
    print("triangles:", tri, " meshes:", len(j.get("meshes", [])), " nodes:", len(j["nodes"]), " materials:", len(j.get("materials", [])))
    # images
    imgs = []
    for ii, im in enumerate(j.get("images", [])):
        if "bufferView" in im:
            bv = j["bufferViews"][im["bufferView"]]
            d = b[bv.get("byteOffset", 0): bv.get("byteOffset", 0) + bv["byteLength"]]
            w, h, f = img_size(d)
            imgs.append((im.get("name", ii), w, h, f, len(d)))
        else:
            imgs.append((im.get("name", ii), 0, 0, "EXTERNAL " + im.get("uri", ""), 0))
    sizes = collections.Counter(f"{w}x{h}" for _, w, h, _, _ in imgs)
    print("images:", len(imgs), dict(sizes), " exts:", j.get("extensionsUsed"))
    # material texture use
    kinds = collections.Counter()
    for m in j.get("materials", []):
        pbr = m.get("pbrMetallicRoughness", {})
        if "baseColorTexture" in pbr: kinds["color"] += 1
        if "metallicRoughnessTexture" in pbr: kinds["metalRough"] += 1
        if "normalTexture" in m: kinds["normal"] += 1
        if "emissiveTexture" in m: kinds["emissive"] += 1
        if "occlusionTexture" in m: kinds["ao"] += 1
    print("material maps:", dict(kinds))
    # names
    names = [n.get("name", "") for n in j["nodes"]] + [m.get("name", "") for m in j.get("materials", [])] + [m.get("name", "") for m in j.get("meshes", [])] + [str(im[0]) for im in imgs]
    def grep(pat):
        return sorted({n for n in names if re.search(pat, n, re.I)})
    for label, pat in [("door", r"door"), ("logo/badge/plate", r"logo|badge|emblem|plate|bugatti|decal|lettering|license|licence|macaron|script"),
                       ("steer", r"steer|wheel_s|sw_|volant|lenk"), ("cluster/gauge", r"cluster|gauge|dial|needle|speedo|tacho|instrument|screen|display|dash|clock|meter|hud"),
                       ("interior", r"interior|seat|cabin|inside|pedal|belt|carpet"), ("glass", r"glass|window|windscreen")]:
        g = grep(pat)
        print(f"{label} ({len(g)}):", ", ".join(g[:30]))
    print("images list:", "; ".join(f"{n}:{w}x{h}" for n, w, h, f, L in imgs[:80]))
