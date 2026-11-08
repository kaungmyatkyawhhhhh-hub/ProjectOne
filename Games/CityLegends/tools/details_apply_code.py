"""Studio code for DetailsApply: the reports of tools/details.py builds and the grille picture ids, ready to paste into
execute_luau (Edit). Also adds newly uploaded picture ids to tools/details/tile_ids.json.

    python tools/details_apply_code.py --ids uploads.json            (url -> rbxassetid map from upload_image)
    python tools/details_apply_code.py car_id[=holding_name] ...      prints the code
"""
import json
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
IDS = os.path.join(ROOT, "tools/details/tile_ids.json")
ids = json.load(open(IDS)) if os.path.exists(IDS) else {}

if sys.argv[1] == "--ids":
    up = json.load(open(sys.argv[2]))
    by_file = {}
    for url, aid in up.items():
        f = url.split("/tiles/")[-1]
        by_file[f] = aid
    for jf in sorted(os.listdir(os.path.join(ROOT, "tools/details"))):
        if not jf.endswith(".json") or jf == "tile_ids.json":
            continue
        car = jf[:-5]
        job = json.load(open(os.path.join(ROOT, "tools/details", jf)))
        for part, t in job.get("tiles", {}).items():
            for key in ("colour", "normal"):
                f = os.path.basename(t.get(key) or "")
                if f in by_file:
                    ids.setdefault(car, {}).setdefault(part, {})[key] = by_file[f]
    json.dump(ids, open(IDS, "w"), indent=1)
    print("tile ids for", sorted(ids))
    sys.exit(0)


def r(x):
    if isinstance(x, float):
        return round(x, 5)
    if isinstance(x, list):
        return [r(i) for i in x]
    if isinstance(x, dict):
        return {k: r(v) for k, v in x.items()}
    return x


lines = ['local HS = game:GetService("HttpService")', "local DA = require(game.ServerStorage.ClaudeTools.DetailsApply:Clone())",
         "local out = {}", "local function add(t) for _, v in t do table.insert(out, v) end end"]
for a in sys.argv[1:]:
    car, _, holding = a.partition("=")
    holding = holding or "details_" + car
    rep_path = os.path.join(ROOT, "imports/details", car + ".fbx.json")
    if os.path.exists(rep_path):
        rep = json.dumps(r(json.load(open(rep_path))), separators=(",", ":"))
        lines.append('add(DA.run("%s", "%s", HS:JSONDecode([=[%s]=])))' % (car, holding, rep))
    if car in ids:
        lines.append('add(DA.tiles("%s", HS:JSONDecode([=[%s]=])))' % (car, json.dumps(ids[car], separators=(",", ":"))))
lines.append('return table.concat(out, string.char(10))')
print("\n".join(lines))
