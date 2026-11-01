"""Lists every junction with its angle (degrees, 90 = square). Roads meeting below ~60 degrees
overlap over a long stretch and are hard to make bump-free.
usage: python -I tools/map_plan/junction_angles.py tools/map_plan"""
import sys, math
sys.path.insert(0, sys.argv[1])
from geo import Elev
from routes import catmull
ns = {"el": Elev(sys.argv[1] + "/data/elev.json")}
exec(open(sys.argv[1] + "/layout.py", encoding="utf-8").read(), ns)
from square import square
roads = [(n, catmull(p, 4, o.get("closed", False))) for n, p, c, o in ns["ROUTES"] + square(ns["ROUTES"], ns["STREETS"])]
def tang(line, k):
    a = line[max(k - 2, 0)]; b = line[min(k + 2, len(line) - 1)]
    d = math.hypot(b[0] - a[0], b[1] - a[1]) or 1
    return ((b[0] - a[0]) / d, (b[1] - a[1]) / d)
seen = []
for i, (na, la) in enumerate(roads):
    for j, (nb, lb) in enumerate(roads):
        if j <= i:
            continue
        best = None
        for ka in range(0, len(la), 2):
            for kb in range(0, len(lb), 2):
                d = math.hypot(la[ka][0] - lb[kb][0], la[ka][1] - lb[kb][1])
                if d < 4 and (best is None or d < best[0]):
                    best = (d, ka, kb)
        if best:
            ta, tb = tang(la, best[1]), tang(lb, best[2])
            ang = math.degrees(math.acos(min(1, abs(ta[0] * tb[0] + ta[1] * tb[1]))))
            p = la[best[1]]
            flag = "  <-- shallow" if ang < 60 else ""
            print("%-16s x %-16s at %6.0f,%5.0f  %3.0f deg%s" % (na, nb, p[0], p[1], ang, flag))
