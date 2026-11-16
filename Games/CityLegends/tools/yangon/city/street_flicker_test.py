"""street_flicker_test.py <tag> (2026-11-16): the no-flicker check on the placed 1:1 street detail.

Every piece of street_kit.py is already checked on its own (street_kit.py prints 0). This places the kit's triangles for
every item in a sample of tiles round the busiest spots (build/city_1to1/street_<tag>/items.json) and looks for
same-facing faces of DIFFERENT items under 0.05 studs apart that overlap (flicker_check.py). Exits 1 on any pair.

    YANGON_SCALE=1to1 python street_flicker_test.py P1 [n_tiles]
"""
import json
import math
import os
import sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import street_kit as K  # noqa: E402
from flicker_check import check  # noqa: E402

TAG = sys.argv[1] if len(sys.argv) > 1 else "P1"
NT = int(sys.argv[2]) if len(sys.argv) > 2 else 40
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
D = json.load(open(os.path.join(ROOT, "build", "city_1to1", "street_%s" % TAG, "items.json")))
K.build()


def main():
    tiles = Counter((int(i["x"] // 256), int(i["z"] // 256)) for i in D["items"])
    pick = set(t for t, _ in tiles.most_common(NT))
    items = []
    n = 0
    for k, it in enumerate(D["items"]):
        if (int(it["x"] // 256), int(it["z"] // 256)) not in pick:
            continue
        n += 1
        c, s = math.cos(it["yaw"]), math.sin(it["yaw"])
        for cls, m in K.KIT[it["pid"]].m.items():
            for i in range(0, len(m.T), 3):
                tri = []
                for v in (m.P[m.T[i]], m.P[m.T[i + 1]], m.P[m.T[i + 2]]):
                    tri.append((it["x"] + v[0] * c + v[2] * s, it["y"] + v[1], it["z"] - v[0] * s + v[2] * c))
                items.append((tuple(tri), (k, cls, m.C[m.T[i]])))
    bad, tris = check(items)
    cross = [b for b in bad if tris[b[0]][1][0] != tris[b[1]][1][0]]
    print("placed sample: %d tiles, %d items, %d triangles, %d flickering pairs across items" % (len(pick), n, len(items), len(cross)))
    for i, j, g, ar in cross[:10]:
        a, b = D["items"][tris[i][1][0]], D["items"][tris[j][1][0]]
        print("   %s at (%.1f, %.1f) / %s at (%.1f, %.1f): gap %.3f area %.3f" % (a["pid"], a["x"], a["z"], b["pid"], b["x"], b["z"], g, ar))
    sys.exit(1 if cross else 0)


if __name__ == "__main__":
    main()
