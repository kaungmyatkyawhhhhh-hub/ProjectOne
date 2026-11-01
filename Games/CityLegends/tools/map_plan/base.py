import sys, math
sys.path.insert(0, sys.path[0])
from geo import load, Elev

def coast_chains(ways):
    segs = [w["pts"] for w in ways if w["tags"].get("natural") == "coastline"]
    chains = []
    while segs:
        c = list(segs.pop(0))
        grown = True
        while grown:
            grown = False
            for i, s in enumerate(segs):
                if dist(s[0], c[-1]) < 1:
                    c += s[1:]; segs.pop(i); grown = True; break
                if dist(s[-1], c[0]) < 1:
                    c = s[:-1] + c; segs.pop(i); grown = True; break
        chains.append(c)
    return chains

def dist(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])

def point_in_poly(p, poly):
    x, y = p; inside = False
    for i in range(len(poly)):
        x1, y1 = poly[i]; x2, y2 = poly[i - 1]
        if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
            inside = not inside
    return inside
