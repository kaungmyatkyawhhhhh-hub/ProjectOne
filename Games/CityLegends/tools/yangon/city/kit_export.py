"""kit_export.py: the kit pilot scene (kit.py) as a .glb for a check in Studio, on a test platform away from the map.

    python kit_export.py  -> imports/sync/landmarks/kit_pilot.glb (+ _2 ...) placed at world X = 32600 + DX + x,
                             Y = Y0 + z, Z = -1350 - y (studs), and build/kit/kit_pilot_place.json (platform size)
The platform: a collision Part made in Studio from the json (the meshes are visual only).
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kit  # noqa: E402
import landmark_glb3d as LG  # noqa: E402

DX = 4400.0   # studs east of landmark_glb3d's origin: X about 37000, east of the built map
Y0 = 600.0    # the platform's top

if __name__ == "__main__":
    info = kit.scene()
    # a big ground under everything (pavement colour), then shift the whole scene east
    S = kit.S
    kit.g.cap("KPV", [(-40 * S, -40 * S), (420 * S, -40 * S), (420 * S, 120 * S), (-40 * S, 120 * S)], -0.05)
    for grp, tris in kit.g.g.items():
        kit.g.g[grp] = [tuple((p[0] + DX, p[1], p[2]) for p in t) for t in tris]
    out = os.path.normpath(os.path.join(HERE, "..", "..", "..", "imports", "sync", "landmarks", "kit_pilot.glb"))
    files = LG.export(kit.g, Y0, out, tag="kt")
    for f in files:
        print(f)
    place = {"platform": {"x0": LG.OX + DX - 40 * S, "x1": LG.OX + DX + 420 * S, "z0": LG.OZ - 120 * S, "z1": LG.OZ + 40 * S,
                          "y": Y0}, "info": info, "dx": DX, "y0": Y0, "scale": S}
    json.dump(place, open(os.path.join(HERE, "..", "..", "..", "build", "kit", "kit_pilot_place.json"), "w"), indent=1)
    print(place["platform"])
