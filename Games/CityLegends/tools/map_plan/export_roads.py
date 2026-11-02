"""Writes build/riviera/roads.json for the Studio builders (tools/riviera/*.luau): every road's
samples in world studs (x, y, z, direction, tunnel), its kind and name, plus the junctions.
usage (from Games/CityLegends): python -I tools/map_plan/export_roads.py tools/map_plan build/riviera"""
import os, sys, json, math
D, OUT = sys.argv[1], sys.argv[2]
sys.path.insert(0, D)
import network
roads = network.build(D)
out = []
for r in roads:
    sm = r["samples"]
    out.append({"name": r["name"], "kind": r["kind"], "closed": r["closed"], "rank": r["rank"],
                "s": [[round(s["x"], 2), round(s["y"], 2), round(s["z"], 2), round(s["dx"], 4), round(s["dz"], 4), 1 if s["tunnel"] or (r["kind"] == "route" and s["ground"] - s["y"] > 45) else 0, round(s["wl"], 2), round(s["wr"], 2)] for s in sm]})
os.makedirs(OUT, exist_ok=True)
json.dump({"roads": out, "ox": network.OX, "oz": network.OZ, "spm": network.SPM}, open(os.path.join(OUT, "roads.json"), "w"), separators=(",", ":"))
print(len(out), "roads,", sum(len(r["s"]) for r in out), "samples")
