"""Dense height grid for the Riviera map: EU-DEM 25 m (opentopodata.org) on a 25 m grid in the plan
frame (geo.py), sea points (OpenStreetMap coastline) skipped. Writes data/dem25.json.
usage: python -I dem_fetch.py <map_plan dir>"""
import sys, os, json, math, time, urllib.request
sys.path.insert(0, sys.argv[1])
from geo import load, LAT0, LON0, KX, KY, ROT
from base import coast_chains, point_in_poly
D = sys.argv[1]
ways = load(os.path.join(D, "data", "monaco.json"))
chain = max(coast_chains(ways), key=len)
land = chain + [(9000, 9000), (-9000, 9000)]
X0, X1, Y0, Y1, STEP = -2200, 2300, -1150, 800, 25
xs = list(range(X0, X1 + 1, STEP)); ys = list(range(Y0, Y1 + 1, STEP))
def ll(x, y):
    c, s = math.cos(-ROT), math.sin(-ROT)
    X, Y = x * c - y * s, x * s + y * c
    return LAT0 + Y / KY, LON0 + X / KX
# land points plus a 50 m margin into the sea (the DEM is rough at the shore)
need = []
for j, y in enumerate(ys):
    for i, x in enumerate(xs):
        if any(point_in_poly((x + dx, y + dy), land) for dx, dy in ((0, 0), (50, 0), (-50, 0), (0, 50), (0, -50))):
            need.append((i, j))
print("points", len(need), "of", len(xs) * len(ys))
H = [[None] * len(xs) for _ in ys]
for k in range(0, len(need), 100):
    chunk = need[k:k + 100]
    q = "|".join("%.6f,%.6f" % ll(xs[i], ys[j]) for i, j in chunk)
    for attempt in range(5):
        try:
            req = urllib.request.Request("https://api.opentopodata.org/v1/eudem25m?locations=" + q, headers={"User-Agent": "CityLegends-map/1.0"})
            res = json.load(urllib.request.urlopen(req, timeout=60))["results"]
            break
        except Exception as e:
            print("retry", k, e); time.sleep(3)
    for (i, j), r in zip(chunk, res):
        H[j][i] = r["elevation"]
    time.sleep(1.05)
    if k % 2000 == 0: print(k)
json.dump({"x0": X0, "y0": Y0, "step": STEP, "nx": len(xs), "ny": len(ys), "h": H}, open(os.path.join(D, "data", "dem25.json"), "w"))
print("done")
