import json, re, sys
sys.path.insert(0, "/tmp/claude-0/logo")
from picks import KEEP
P = json.load(open("parts.json"))
BRAND = lambda c: "BNW" if c.startswith("bnw_") else "Mercer" if (c.startswith("bentz_") and c != "bentz_gt63s") or c.startswith("brabos_") else "Lexis" if c.startswith("lexis_") else None
# hub logos that are badge-named parts (hidden): no blank cover needed there, only an emblem
cars = [l.split()[0] for l in open("blends.txt")]
MARK = re.compile(r"badge|logo|emblem|letter|decal_badg|sign\b", re.I)
out = {}
for car in cars:
    d = json.load(open(f"t/{car}.json"))
    brand = BRAND(car)
    # parts to hide: badge-named blend objects -> the model's parts (by name; by size too when the name is shared)
    hide = []
    m = json.load(open(f"m/{car}.json"))
    for mk in m["marks"]:
        if mk["obj"] in KEEP.get(car, []): continue
        name = re.sub(r"\.\d\d\d$", "", mk["obj"])
        dims = mk["dims"]  # blender x, y, z
        same = [p for p in P[car] if p[0] == name]
        if not same: print("NOPART", car, name); continue
        if len(same) == 1: hide.append({"name": name}); continue
        want = (dims[0], dims[2], dims[1])
        best = min(same, key=lambda p: sum(abs(p[1 + i] - want[i]) for i in range(3)))
        err = sum(abs(best[1 + i] - want[i]) for i in range(3))
        if err > 0.01: print("SIZEMISS", car, name, want, best[1:4]); continue
        hide.append({"name": name, "size": [round(best[1], 4), round(best[2], 4), round(best[3], 4)]})
    covers = list(d["covers"])
    if brand:
        for gr in d["groups"]:
            x, y, z = gr["at"]; s = max(gr["size"])
            if abs(x) < 0.02 and abs(z) > 1.2 and 0.05 <= s <= 0.25:
                covers.append({"kind": "emblem", "shape": "disc", "at": gr["at"], "face": None, "w": round(s * 0.9, 4), "h": round(s * 0.9, 4), "color": None, "group": True})
    hub = d["hub"]
    if hub:
        fz = hub["face"][2]
        if fz < 0.866: hub["face"] = [0, 0, 1]
    out[car] = {"wb": d["wb"], "brand": brand, "hide": hide, "covers": covers, "caps": d["caps"], "hub": d["hub"]}
json.dump(out, open("final.json", "w"), indent=1)
print(sum(len(v["covers"]) for v in out.values()), "covers;", sum(len(v["hide"]) for v in out.values()), "hidden parts")
