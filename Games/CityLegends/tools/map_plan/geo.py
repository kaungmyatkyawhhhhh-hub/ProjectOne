import json, math
LAT0, LON0 = 43.74, 7.42
KX = math.cos(math.radians(LAT0)) * 111320
KY = 110540
ROT = math.radians(-50)
def proj(lat, lon):
    x = (lon - LON0) * KX
    y = (lat - LAT0) * KY
    c, s = math.cos(ROT), math.sin(ROT)
    return (x * c - y * s, x * s + y * c)  # metres, x along the strip (NE), y up = inland (NW)

def load(osm_path):
    d = json.load(open(osm_path, encoding="utf-8"))
    ways = []
    for e in d["elements"]:
        if e["type"] == "way" and "geometry" in e:
            ways.append({"id": e["id"], "tags": e.get("tags", {}), "pts": [proj(g["lat"], g["lon"]) for g in e["geometry"]]})
        elif e["type"] == "relation":
            for m in e.get("members", []):
                if m.get("role") == "outer" and "geometry" in m:
                    ways.append({"id": "b%s" % m["ref"], "tags": {"boundary": "monaco"}, "pts": [proj(g["lat"], g["lon"]) for g in m["geometry"]]})
    return ways

class Elev:
    def __init__(self, path):
        d = json.load(open(path))
        self.N = d["N"]; self.lat0, self.lat1, self.lon0, self.lon1 = d["bbox"]
        self.e = [x if x is not None else 0 for x in d["elev"]]
    def at_ll(self, lat, lon):
        N = self.N
        fi = (lat - self.lat0) / (self.lat1 - self.lat0) * (N - 1)
        fj = (lon - self.lon0) / (self.lon1 - self.lon0) * (N - 1)
        fi = min(max(fi, 0), N - 1.001); fj = min(max(fj, 0), N - 1.001)
        i, j = int(fi), int(fj); a, b = fi - i, fj - j
        g = lambda ii, jj: self.e[ii * N + jj]
        return (g(i, j) * (1 - a) * (1 - b) + g(i + 1, j) * a * (1 - b) + g(i, j + 1) * (1 - a) * b + g(i + 1, j + 1) * a * b)
    def at(self, x, y):
        c, s = math.cos(-ROT), math.sin(-ROT)
        X, Y = x * c - y * s, x * s + y * c
        return self.at_ll(LAT0 + Y / KY, LON0 + X / KX)
