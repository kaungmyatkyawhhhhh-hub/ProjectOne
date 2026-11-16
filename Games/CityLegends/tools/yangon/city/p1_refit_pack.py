"""p1_refit_pack.py (2026-11-16): the Studio data for the 1:1 refit of Myanmar Centre (mc1) and Sedona (sd1) in P1.

    YANGON_SCALE=1to1 python p1_refit_pack.py   (after mc3d.py / sedona3d.py at 1:1)
      -> build/landmarks/p1_refit/P1Refit.rbxmx: Folder P1RefitData with
           P1Refit (ModuleScript: tools/yangon/P1Refit.luau, the GROUPS table filled in),
           mc1_collide / sd1_collide (YangonBuildingMeshes.collide lines), mc1_lights / sd1_lights (JSON),
           terrain ("X Z X1 top" runs: air above, ground below, over each site), carve (ramp trenches)
Terrain: under paving / lawn the ground goes to the pavement plane - 1.5; under the Myanmar Centre buildings to
min(plane, floor) - 1.5 (no grass through a floor); 4-stud cells (the voxel size), merged into runs along X.
"""
import json
import math
import os
import subprocess
import sys

from shapely.geometry import Polygon, Point
from shapely.ops import unary_union
from shapely.prepared import prep

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import onetoone as X1  # noqa: E402
import landmark_glb3d as LG  # noqa: E402

ROOT = os.path.join(HERE, "..", "..", "..")
OUT = os.path.join(ROOT, "build", "landmarks", "p1_refit")
CELL = 4.0


def terrain_runs(sites, plane, foot=None, y0=None):
    shape = unary_union([Polygon(r).buffer(0) for r in sites])
    ps = prep(shape.buffer(-1.0))
    pf = prep(unary_union([Polygon(f).buffer(2.0) for f in foot])) if foot else None
    x0, z0, x1, z1 = shape.bounds
    rows = []
    z = math.floor(z0 / CELL) * CELL + CELL / 2
    while z < z1:
        run = None
        x = math.floor(x0 / CELL) * CELL + CELL / 2
        while x < x1 + CELL:
            ok = ps.contains(Point(x, z))
            top = None
            if ok:
                top = X1.plane_y(plane, x, z)
                if pf is not None and pf.contains(Point(x, z)):
                    top = min(top, y0)
                top = round((top - 4.0) * 4) / 4   # 4 under (1.5 left smooth terrain poking through lawns)
            if run and (top is None or abs(top - run[3]) > 0.01):
                rows.append(run)
                run = None
            if top is not None:
                if run is None:
                    run = [x - CELL / 2, z, x + CELL / 2, top]
                else:
                    run[2] = x + CELL / 2
            x += CELL
        if run:
            rows.append(run)
        z += CELL
    return rows


def main():
    mm = json.load(open(os.path.join(OUT, "mc1_meta.json")))
    sm = json.load(open(os.path.join(OUT, "sd1_meta.json")))
    rm = terrain_runs(mm["site"], mm["plane"], mm["footprints"], mm["y0"])
    rs = terrain_runs(sm["site"], sm["plane"])
    runs = rm + rs
    for nm, rr in (("terrain_mc", rm), ("terrain_sd", rs)):
        open(os.path.join(OUT, nm + ".txt"), "w").write("\n".join("%.1f %.1f %.1f %.2f" % tuple(r) for r in rr) + "\n")
    open(os.path.join(OUT, "carve.txt"), "w").write("\n".join(" ".join(str(v) for v in c) for c in mm["carve"]) + "\n")
    print("terrain runs", len(runs), "carve", len(mm["carve"]))
    src = open(os.path.join(ROOT, "tools", "yangon", "P1Refit.luau"), encoding="utf-8").read()
    src = src.replace("--@@GROUPS@@", LG.groups_lua())
    tmp = os.path.join(OUT, "P1Refit.luau")
    open(tmp, "w", encoding="utf-8", newline="\n").write(src)
    files = [tmp] + [os.path.join(OUT, f) for f in ("mc1_collide.txt", "sd1_collide.txt", "mc1_lights.json",
                                                      "sd1_lights.json", "terrain_mc.txt", "terrain_sd.txt", "carve.txt")]
    files.append(os.path.join(ROOT, "tools", "yangon", "YangonMaterials.luau"))
    # pack_strings names each StringValue after its file
    subprocess.check_call([sys.executable, os.path.join(ROOT, "tools", "yangon", "pack_strings.py"),
                           os.path.join(ROOT, "imports", "sync", "P1Refit.rbxmx"), "P1RefitData"] + files)


if __name__ == "__main__":
    main()
