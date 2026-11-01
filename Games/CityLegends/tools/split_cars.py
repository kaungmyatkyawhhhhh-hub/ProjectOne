"""Split the low-poly car pack (Sketchfab "Low Poly cars pack" by matisosanimation, CC-BY-4.0)
into one group per car for Studio's Import 3D: Traffic_<type><n> = Body + FL/FR/RL/RR wheels.
Each car faces -Z, right is +X, the wheels' bottom sits at y 0; each wheel's pivot is its hub.

usage: python -I split_cars.py in.glb out.glb [--views views.svg] [--flip A,B]
  --views  side views of one car per type (+along to the right) to tell which end is the front
  --flip   types whose front is the -along end
"""
import sys, json, struct, math, collections
import os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gltf_io import read_glb, accessor

src, dst = sys.argv[1], sys.argv[2]
views = sys.argv[sys.argv.index("--views") + 1] if "--views" in sys.argv else None
flip = set(sys.argv[sys.argv.index("--flip") + 1].split(",")) if "--flip" in sys.argv else set()
j, b = read_glb(src)
SCALE = 0.7227900624275208  # the pack's own root scale

prims = []
for mi, m in enumerate(j["meshes"]):
    for p in m["primitives"]:
        a = p["attributes"]
        prims.append({
            "mesh": mi, "mat": p["material"],
            "pos": accessor(j, b, a["POSITION"]),
            "nor": accessor(j, b, a["NORMAL"]) if "NORMAL" in a else None,
            "uv": accessor(j, b, a["TEXCOORD_0"]) if "TEXCOORD_0" in a else None,
            "idx": accessor(j, b, p["indices"]),
        })


def bbox(pts):
    xs, ys, zs = zip(*pts)
    return [min(xs), min(ys), min(zs), max(xs), max(ys), max(zs)]


# car slots from the painted bodies (a texture each); touching ones merge (the pickups' two parts)
TYPE = {966: "A", 492: "B", 1954: "C", 910: "D", 1288: "E", 416: "F", 340: "F"}
slots = []
for pi, p in enumerate(prims):
    tex = j["materials"][p["mat"]].get("pbrMetallicRoughness", {}).get("baseColorTexture")
    if not tex or p["mesh"] == 56:
        continue
    bb = bbox(p["pos"])
    for s in slots:
        o = s["bb"]
        if bb[0] <= o[3] + 0.05 and o[0] <= bb[3] + 0.05 and bb[1] <= o[4] + 0.05 and o[1] <= bb[4] + 0.05:
            s["bb"] = [min(o[i], bb[i]) for i in range(3)] + [max(o[i], bb[i]) for i in range(3, 6)]
            s["body"].append(pi)
            break
    else:
        slots.append({"bb": bb, "body": [pi], "type": TYPE.get(len(p["idx"]) // 3, "X")})


def rect_dist(x, y, bb):
    return math.hypot(max(bb[0] - x, 0, x - bb[3]), max(bb[1] - y, 0, y - bb[4]))


for s in slots:
    s["tris"] = collections.defaultdict(list)
    for pi in s["body"]:
        s["tris"][pi] = list(range(0, len(prims[pi]["idx"]), 3))
lost = 0
body_set = {pi for s in slots for pi in s["body"]}
for pi, p in enumerate(prims):
    if pi in body_set:
        continue
    pos, idx = p["pos"], p["idx"]
    for t in range(0, len(idx), 3):
        cx = sum(pos[idx[t + k]][0] for k in range(3)) / 3
        cy = sum(pos[idx[t + k]][1] for k in range(3)) / 3
        best = min(slots, key=lambda s: rect_dist(cx, cy, s["bb"]))
        if rect_dist(cx, cy, best["bb"]) < 0.6:
            best["tris"][pi].append(t)
        else:
            lost += 1
print("slots", len(slots), "lost tris", lost, dict(collections.Counter(s["type"] for s in slots)))


def components(p, tris):
    pos, idx = p["pos"], p["idx"]
    key = lambda v: (round(pos[v][0], 4), round(pos[v][1], 4), round(pos[v][2], 4))
    parent = {}

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    for t in tris:
        ks = [key(idx[t + k]) for k in range(3)]
        for k in ks:
            parent.setdefault(k, k)
        for k in ks[1:]:
            ra, rb = find(ks[0]), find(k)
            if ra != rb:
                parent[ra] = rb
    groups = collections.defaultdict(list)
    for t in tris:
        groups[find(key(idx[t]))].append(t)
    return list(groups.values())


cars = []
for s in sorted(slots, key=lambda s: (s["type"], s["bb"][0], s["bb"][1])):
    bb = s["bb"]
    along_x = (bb[3] - bb[0]) >= (bb[4] - bb[1])
    cx, cy = (bb[0] + bb[3]) / 2, (bb[1] + bb[4]) / 2
    L = (bb[3] - bb[0]) if along_x else (bb[4] - bb[1])
    Wd = (bb[4] - bb[1]) if along_x else (bb[3] - bb[0])
    # (side, up, along), chosen so that (side, up, -along) is a proper rotation of the source axes
    if along_x:
        loc = lambda v, cx=cx, cy=cy: (-(v[1] - cy), v[2], v[0] - cx)
        dirf = lambda n: (-n[1], n[2], n[0])
    else:
        loc = lambda v, cx=cx, cy=cy: (v[0] - cx, v[2], v[1] - cy)
        dirf = lambda n: (n[0], n[2], n[1])
    body = collections.defaultdict(list)
    wheels = {q: collections.defaultdict(list) for q in ("FL", "FR", "RL", "RR")}
    wpts = {q: [] for q in wheels}
    for pi, tris in s["tris"].items():
        p = prims[pi]
        if pi in s["body"]:
            body[pi] += tris
            continue
        for comp in components(p, tris):
            pts = [loc(p["pos"][p["idx"][t + k]]) for t in comp for k in range(3)]
            b2 = bbox(pts)
            ext = max(b2[3] - b2[0], b2[4] - b2[1], b2[5] - b2[2])
            mid = [(b2[i] + b2[i + 3]) / 2 for i in range(3)]
            if ext < 1.0 and mid[1] < 0.9 and abs(mid[0]) > 0.22 * Wd and abs(mid[2]) > 0.18 * L:
                q = ("F" if mid[2] > 0 else "R") + ("R" if mid[0] > 0 else "L")
                wheels[q][pi] += comp
                wpts[q] += pts
            else:
                body[pi] += comp
    n = sum(1 for c in cars if c["type"] == s["type"]) + 1
    cars.append({"name": "%s%d" % (s["type"], n), "type": s["type"], "loc": loc, "dir": dirf,
                 "body": body, "wheels": wheels, "wpts": wpts, "L": L, "W": Wd,
                 "ok": all(wpts[q] for q in wpts)})
print("cars without 4 wheels:", [c["name"] for c in cars if not c["ok"]])

if views:
    out = ['<svg xmlns="http://www.w3.org/2000/svg" width="1300" height="%d" style="background:#fff" font-family="Arial">' % (200 * 6)]
    row = 0
    for t in "ABCDEF":
        c = next((c for c in cars if c["type"] == t), None)
        if not c:
            continue
        out.append('<text x="10" y="%d" font-size="22">%s  (+along is RIGHT; wheels red)</text>' % (row * 200 + 26, t))
        groups = [(c["body"], "#333")] + [(g, "#d00") for g in c["wheels"].values()]
        for group, col in groups:
            for pi, tris in group.items():
                p = prims[pi]
                for tt in tris:
                    pts = [c["loc"](p["pos"][p["idx"][tt + k]]) for k in range(3)]
                    d = " ".join("%.1f,%.1f" % (650 + q[2] * 100, row * 200 + 185 - q[1] * 100) for q in pts)
                    out.append('<polygon points="%s" fill="none" stroke="%s" stroke-width="0.3"/>' % (d, col))
        row += 1
    out.append("</svg>")
    open(views, "w").write("\n".join(out))

# ---- write the glb
buf = bytearray()
bviews, accs, meshes, nodes = [], [], [], []


def add_view(data, target=None):
    while len(buf) % 4:
        buf.append(0)
    off = len(buf)
    buf.extend(data)
    v = {"buffer": 0, "byteOffset": off, "byteLength": len(data)}
    if target:
        v["target"] = target
    bviews.append(v)
    return len(bviews) - 1


def add_acc(vals, typ, comp, minmax=False, target=None):
    n = {"SCALAR": 1, "VEC2": 2, "VEC3": 3}[typ]
    flat = [x for v in vals for x in (v if n > 1 else (v,))]
    fmt = {5126: "f", 5125: "I"}[comp]
    a = {"bufferView": add_view(struct.pack("<%d%s" % (len(flat), fmt), *flat), target),
         "componentType": comp, "count": len(vals), "type": typ}
    if minmax:
        a["min"] = [min(v[i] for v in vals) for i in range(n)]
        a["max"] = [max(v[i] for v in vals) for i in range(n)]
    accs.append(a)
    return len(accs) - 1


def make_mesh(name, group, car, origin, f):
    prs = []
    for pi, tris in sorted(group.items()):
        if not tris:
            continue
        p = prims[pi]
        remap, P, N, U, I = {}, [], [], [], []
        for t in tris:
            for k in range(3):
                v = p["idx"][t + k]
                if v not in remap:
                    remap[v] = len(P)
                    sd, up, al = car["loc"](p["pos"][v])
                    P.append(((sd * f - origin[0]) * SCALE, (up - origin[1]) * SCALE, (-al * f - origin[2]) * SCALE))
                    if p["nor"]:
                        ns, nu, na = car["dir"](p["nor"][v])
                        N.append((ns * f, nu, -na * f))
                    if p["uv"]:
                        U.append(p["uv"][v])
                I.append(remap[v])
        attrs = {"POSITION": add_acc(P, "VEC3", 5126, True, 34962)}
        if N:
            attrs["NORMAL"] = add_acc(N, "VEC3", 5126, False, 34962)
        if U:
            attrs["TEXCOORD_0"] = add_acc(U, "VEC2", 5126, False, 34962)
        prs.append({"attributes": attrs, "indices": add_acc(I, "SCALAR", 5125, False, 34963), "material": p["mat"]})
    if not prs:
        return None
    meshes.append({"name": name, "primitives": prs})
    return len(meshes) - 1


SWAP = {"FL": "RR", "FR": "RL", "RL": "FR", "RR": "FL"}
roots = []
for i, car in enumerate(cars):
    f = -1 if car["type"] in flip else 1
    ground = min(min(p[1] for p in car["wpts"][q]) for q in car["wpts"] if car["wpts"][q]) if any(car["wpts"].values()) else 0
    kids = []
    nodes.append({"name": "Body", "mesh": make_mesh("Body", car["body"], car, (0, ground, 0), f)})
    kids.append(len(nodes) - 1)
    for q, group in car["wheels"].items():
        if not car["wpts"][q]:
            continue
        b2 = bbox(car["wpts"][q])
        c = [(b2[k] + b2[k + 3]) / 2 for k in range(3)]
        o = (c[0] * f, c[1], -c[2] * f)
        name = q if f > 0 else SWAP[q]
        nodes.append({"name": name, "mesh": make_mesh(name, group, car, o, f),
                      "translation": [o[0] * SCALE, (o[1] - ground) * SCALE, o[2] * SCALE]})
        kids.append(len(nodes) - 1)
    nodes.append({"name": "Traffic_" + car["name"], "children": kids, "translation": [(i % 7) * 8.0, 0, (i // 7) * 8.0]})
    roots.append(len(nodes) - 1)

imgs = []
for im in j["images"]:
    bv = j["bufferViews"][im["bufferView"]]
    o = bv.get("byteOffset", 0)
    imgs.append({"bufferView": add_view(b[o: o + bv["byteLength"]]), "mimeType": im["mimeType"]})
out = {"asset": {"version": "2.0", "generator": "CityLegends split_cars.py", "extras": j["asset"].get("extras", {})},
       "scene": 0, "scenes": [{"nodes": roots}], "nodes": nodes, "meshes": meshes, "accessors": accs,
       "bufferViews": bviews, "buffers": [{"byteLength": 0}], "materials": j["materials"],
       "textures": j["textures"], "images": imgs}
if "samplers" in j:
    out["samplers"] = j["samplers"]
while len(buf) % 4:
    buf.append(0)
out["buffers"][0]["byteLength"] = len(buf)
js = json.dumps(out).encode()
while len(js) % 4:
    js += b" "
glb = (struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(js) + 8 + len(buf)) + struct.pack("<I4s", len(js), b"JSON") + js
       + struct.pack("<I4s", len(buf), b"BIN\0") + bytes(buf))
open(dst, "wb").write(glb)
print("wrote", dst, len(glb) // 1024, "KB,", len(cars), "cars")
