"""Myanmar Plaza roof gardens (2026-11-17, owner drone photo): the real roof is green round the dome (lawn beds with
low hedges between paved terraces). Beds = world-axis rectangles on a grid over the podium roof, kept only where they
stay 10 studs inside the roof edge and clear of the towers, the Melia, the white-roof block, the dome ring and the
corner pergola. Writes build/landmarks/p1_refit/mc_roof_beds.json ([cx, cz, sx, sz]); MCDrone.luau places them."""
import json, math, os
from shapely.geometry import Polygon, Point, box
from shapely import affinity

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..")
m = json.load(open(os.path.join(ROOT, "build/landmarks/p1_refit/mc1_meta.json")))
pod, mel, A, B = [Polygon([(p[0], p[-1]) for p in f]) for f in m["footprints"]]
L = json.load(open(os.path.join(ROOT, "build/landmarks/myanmar_centre/layout_fit_1to1.json")))
W = lambda p: (34875 + p[0] * 1.875, 27468.75 - p[1] * 1.875)
wr = Polygon([W(p) for p in L["whiteroof"]])
dc = W(L["dome_c"])
dome = affinity.scale(Point(dc).buffer(1, 64), 51.6 + 7, 57.2 + 7)
# the pergola (MCDrone.luau): facade mid M, along T 44 wide, 19..33 deep along N
M = (34811.05, 27180.3)
T = (0.7931, -0.6092)
N = (-T[1], T[0])
perg = Polygon([(M[0] + T[0] * s + N[0] * d, M[1] + T[1] * s + N[1] * d) for s, d in ((-26, 15), (26, 15), (26, 37), (-26, 37))])
ok = pod.buffer(-10).difference(A.buffer(10)).difference(B.buffer(10)).difference(mel.buffer(10)) \
    .difference(wr.buffer(8)).difference(dome).difference(perg)
beds = []
x0, z0, x1, z1 = pod.bounds
z = z0
row = 0
while z < z1:
    x = x0 + (row % 2) * 9
    while x < x1:
        sx, sz = 24 + 6 * ((int(x) // 7) % 2), 16 + 4 * ((int(z) // 5) % 2)
        r = box(x, z, x + sx, z + sz)
        if ok.contains(r):
            beds.append([round(x + sx / 2, 2), round(z + sz / 2, 2), sx, sz])
        x += sx + 9
    z += 26
    row += 1
for i, b in enumerate(beds):
    for c in beds[i + 1:]:
        assert box(b[0] - b[2] / 2, b[1] - b[3] / 2, b[0] + b[2] / 2, b[1] + b[3] / 2).intersection(
            box(c[0] - c[2] / 2, c[1] - c[3] / 2, c[0] + c[2] / 2, c[1] + c[3] / 2)).area == 0
print(len(beds), "beds", round(sum(b[2] * b[3] for b in beds)), "studs2 of", round(ok.area))
json.dump(beds, open(os.path.join(ROOT, "build/landmarks/p1_refit/mc_roof_beds.json"), "w"))
