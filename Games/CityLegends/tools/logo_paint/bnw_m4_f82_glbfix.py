"""bnw_m4_f82_glbfix.py in.glb out.glb : the F82's .glb readied for auto_car.py, after tools/paint_glb.py
(tools/logo_paint/bnw_m4_f82.json), 2026-11-12. Pure Python, no Blender. Three things this model needs that the paint job
can't say:

  * the cabin material is made opaque (it is "BLEND" in the file: its picture's alpha is a shine mask, not see-through;
    the paint job swaps the picture for an opaque one);
  * the wheel material (one picture for tyre and brake disc) is split by piece: the disc pieces (30, 15 and 6 triangles
    each) get their own material "Disc_Steel", the tyre pieces (320, 80 and 19 triangles) stay "Tyre_Rubber", so
    finish_car.py makes FL_Tyre and FL_Disc (the kit wheels replace them by name);
  * the cabin's carbon strip (the node "...Interior5_Mesh_004_M_Interior_Max1...", material "Carbon_Weave") gets its own
    material "Cabin_Carbon", so finish_car.py makes Body_CabinCarbon (a glossy part inside a cabin mirrors the sky: it
    gets a rough surface; CarFinish's carbon tint skips names with "cabin").
"""
import copy
import json
import struct
import sys

src, out = sys.argv[1:3]
b = open(src, "rb").read()
n = struct.unpack("<I", b[12:16])[0]
j = json.loads(b[20 : 20 + n])
rest = b[20 + n :]
mats = j["materials"]


def idx(name):
    return next(i for i, m in enumerate(mats) if m.get("name") == name)


def clone(name, new):
    m = copy.deepcopy(mats[idx(name)])
    m["name"] = new
    mats.append(m)
    return len(mats) - 1


cab = mats[idx("Interior_Main")]
cab["alphaMode"] = "OPAQUE"
tyre = idx("Tyre_Disc")
mats[tyre]["name"] = "Tyre_Rubber"
disc = clone("Tyre_Rubber", "Disc_Steel")
carbon = idx("Carbon_Weave")
cabcarbon = clone("Carbon_Weave", "Cabin_Carbon")
count = {"disc": 0, "tyre": 0, "cabin carbon": 0}
for nd in j["nodes"]:
    if "mesh" not in nd:
        continue
    for p in j["meshes"][nd["mesh"]]["primitives"]:
        tris = j["accessors"][p["indices"]]["count"] // 3
        if p.get("material") == tyre:
            if tris in (30, 15, 6):
                p["material"] = disc
                count["disc"] += 1
            else:
                assert tris in (320, 80, 19), tris
                count["tyre"] += 1
        elif p.get("material") == carbon and "Interior5_Mesh" in nd.get("name", ""):
            p["material"] = cabcarbon
            count["cabin carbon"] += 1
assert count["disc"] == 48 and count["tyre"] == 88 and count["cabin carbon"] == 1, count
js = json.dumps(j, separators=(",", ":")).encode()
js += b" " * ((4 - len(js) % 4) % 4)
with open(out, "wb") as f:
    f.write(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + len(rest)))
    f.write(struct.pack("<II", len(js), 0x4E4F534A))
    f.write(js)
    f.write(rest)
print("GLBFIX", count, "->", out)
