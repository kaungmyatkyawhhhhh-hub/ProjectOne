"""The surface tables for tools/lambo/PbrApply.luau: finish_car.py's *.pbr.json with picture ids
(pbr_ids.json), written to tools/lambo/pbr/<car id>.json.

    python tools/lambo/pbr_table.py donedir

One entry per part: n normal id, r / m roughness and metal ids, e 1 = the part glows (screens, lit lamps).
Nearest value of the small map sets: every car shares the same few pictures. Wheels whose tyre and rim
share one atlas get a map with the tyre ring (matt, not metal) and the rest (metal).
"""

import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
IDS = json.load(open(os.path.join(HERE, "pbr_ids.json")))
CARS = {"lp650r": "lambrini_lp640", "lp670sv": "lambrini_lp670", "urusp": "lambrini_urusp", "california": "ferrara_california", "f458spider": "ferrara_458spider", "f458speciale": "ferrara_458speciale", "lp700": "lambrini_lp700", "sv": "lambrini_lp750", "sl": "lambrini_lp570", "spyder560": "lambrini_lp560", "evo": "lambrini_huracan", "perf": "lambrini_performante", "sto": "lambrini_sto", "sterrato": "lambrini_sterrato", "revuelto": "lambrini_revuelto"}
# cars whose wheel atlas has the tyre ring in the middle of the picture
ATLAS = {"lp670sv": "wheel", "urusp": "wheel", "california": "wheel", "f458speciale": "wheel", "lp700": "wheel", "sv": "wheel", "perf": "wheel", "sto": "wheel", "revuelto": "wheel", "sterrato": "wheelS"}


MATT = ("Cabin", "CabinTile", "CabinTrim", "Suede", "Leather", "Belt", "SoftTop")


def nearest(table, v):
    k = min(table, key=lambda x: abs(float(x) - v))
    return table[k]


def main():
    done = sys.argv[1]
    out = os.path.join(HERE, "pbr")
    os.makedirs(out, exist_ok=True)
    for key, cid in CARS.items():
        if not os.path.exists(os.path.join(done, key + ".pbr.json")):
            continue  # (each job's cars only)
        d = json.load(open(os.path.join(done, key + ".pbr.json")))
        rows = {}
        dp = os.path.join(done, key + ".dims.json")
        dims = json.load(open(dp)) if os.path.exists(dp) else {}
        for name, p in d["parts"].items():
            if p["role"] in ("Paint", "Window", "Lens_Red", "Lens_Orange", "Lens_Clear"):
                continue  # src/client/CarFinish.lua does these
            e = {"r": nearest(IDS["rough"], p["r"]), "m": nearest(IDS["metal"], p["m"])}
            if p["n"]:
                e["n"] = IDS["normals"][key][p["n"]]
            if p["role"] in ("Screen", "LampGlow"):
                e["e"] = 1
            if p["role"] in MATT:
                e["r"] = IDS["white"]  # full roughness: anything less picks up the blue sky under the roof
            if p["role"] == "Mirror":
                e["tint"] = [96, 102, 112]  # a dark mirror glass (it only reflects the sky, and that blows out white)
            if name.startswith("Body_Paint_Cover") or p["base"] == "col_HubCover":
                e["two"] = 1  # the covers' faces come in the wrong way round
            if p["role"] == "Rim" and key in ATLAS:
                e["r"], e["m"] = IDS[ATLAS[key]]["r"], IDS[ATLAS[key]]["m"]
            if name in dims:
                e["dim"] = dims[name]  # (a steering wheel piece: matched by size, see PbrApply)
            rows[name] = e
        json.dump({"id": cid, "parts": rows, "white": IDS["white"]}, open(os.path.join(out, cid + ".json"), "w"), indent=0)
        print(cid, len(rows), "of", len(d["parts"]), "tris", d["tris"])


if __name__ == "__main__":
    main()
