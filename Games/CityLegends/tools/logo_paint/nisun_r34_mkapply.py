"""nisun_r34: CarApply's table from the finished parts (build/r34/parts.json + nisun_r34.pbr.json): every plain part gets the
white picture tinted to its colour and uniform roughness / metal maps (tools/lambo/pbr_ids.json), so no pictures are uploaded.
    python tools/logo_paint/nisun_r34_mkapply.py steer_sizes.json out.json
steer_sizes.json: {"SteeringWheel_t10": [x, y, z], "SteeringWheel_t10.001": [...]} = Studio's own Size of each piece."""
import json, sys

ids = json.load(open("tools/lambo/pbr_ids.json"))
parts = json.load(open("build/r34/parts.json"))
pbr = json.load(open("build/r34/nisun_r34.pbr.json"))["parts"]
steer = json.load(open(sys.argv[1]))
TINT = {"Rim": [72, 74, 78], "Cabin": [40, 40, 42], "CabinTrim": [50, 50, 53], "CabinDoor": [62, 62, 66], "CabinCloth": [58, 59, 63]}  # (lighter than the model: Roblox's cabin light is dim)
METAL = {"Rim": 0.85}


def near(table, v):
    return table[min(table, key=lambda k: abs(float(k) - v))]


def row(name):
    p, e = parts[name], pbr[name]
    role = e["role"]
    if role == "Paint":
        return {"role": "Paint"}
    if name.startswith("SeeThrough"):
        return {"role": role}  # (glass: Transparency set in Studio, no surface)
    return {"role": role, "c": ids["white"], "r": near(ids["rough"], e["r"]), "m": near(ids["metal"], METAL.get(role, e["m"])),
            "tint": TINT.get(role, p["col"])}


out = {"parts": {}, "steer": []}
for name in parts:
    if name.startswith("LampFx") or name.startswith("SteeringWheel"):
        continue
    out["parts"][name] = row(name)
for name, size in steer.items():
    r = row(name)
    r["size"] = sorted(size)
    out["steer"].append(r)
assert out["parts"]["Body_Paint_p1"]["role"] == "Paint" and len(out["steer"]) == 2
json.dump(out, open(sys.argv[2], "w"))
print("parts", len(out["parts"]), "steer", len(out["steer"]))
