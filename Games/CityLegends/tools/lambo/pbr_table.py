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
CARS = {"lp700": "lambrini_lp700", "sv": "lambrini_lp750", "sl": "lambrini_lp570", "spyder560": "lambrini_lp560", "evo": "lambrini_huracan", "perf": "lambrini_performante", "sto": "lambrini_sto", "sterrato": "lambrini_sterrato", "revuelto": "lambrini_revuelto"}
# cars whose wheel atlas has the tyre ring in the middle of the picture
ATLAS = {"lp700": "wheel", "sv": "wheel", "perf": "wheel", "sto": "wheel", "revuelto": "wheel", "sterrato": "wheelS"}


def nearest(table, v):
    k = min(table, key=lambda x: abs(float(x) - v))
    return table[k]


def main():
    done = sys.argv[1]
    out = os.path.join(HERE, "pbr")
    os.makedirs(out, exist_ok=True)
    for key, cid in CARS.items():
        d = json.load(open(os.path.join(done, key + ".pbr.json")))
        rows = {}
        for name, p in d["parts"].items():
            if p["role"] in ("Paint", "Window", "Lens_Red", "Lens_Orange", "Lens_Clear"):
                continue  # src/client/CarFinish.lua does these
            e = {"r": nearest(IDS["rough"], p["r"]), "m": nearest(IDS["metal"], p["m"])}
            if p["n"]:
                e["n"] = IDS["normals"][key][p["n"]]
            if p["role"] in ("Screen", "LampGlow"):
                e["e"] = 1
            if p["role"] == "Rim" and key in ATLAS:
                e["r"], e["m"] = IDS[ATLAS[key]]["r"], IDS[ATLAS[key]]["m"]
            rows[name] = e
        json.dump({"id": cid, "parts": rows, "white": IDS["white"]}, open(os.path.join(out, cid + ".json"), "w"), indent=0)
        print(cid, len(rows), "of", len(d["parts"]), "tris", d["tris"])


if __name__ == "__main__":
    main()
