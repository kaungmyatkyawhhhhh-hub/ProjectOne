"""places_extract.py <tag> (2026-11-16): every tagged OSM object of a 1:1 pilot district WITH ALL ITS TAGS (e0_extract keeps
a fixed key list, so fuel / parking / pitch / condo levels details were lost). Nodes, ways and multipolygons in the
district box + 300 m.  -> build/city_1to1/places_<tag>/osm_all.json   {nodes:[{id,t,p}], ways:[{id,t,p,closed}],
areas:[{id,way,t,p,h}]}

    YANGON_SCALE=1to1 python places_extract.py P1        (about 2-3 minutes: the whole Myanmar pbf with node locations)
"""
import glob
import json
import os
import sys
import time

import osmium

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import geo  # noqa: E402

TAG = sys.argv[1] if len(sys.argv) > 1 else "P1"
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
SRC = sorted(glob.glob(os.path.join(ROOT, "build", "osm_extract", "myanmar-*.osm.pbf")))[-1]
OUT = os.path.join(ROOT, "build", "city_1to1", "places_%s" % TAG)
lo0, la0, lo1, la1 = geo.PILOT_LL[TAG]
MG = 0.003
W, S, E, N = lo0 - MG, la0 - MG, lo1 + MG, la1 + MG
SKIP = {"created_by", "source"}


def inbox(lon, lat):
    return W <= lon <= E and S <= lat <= N


def tags(t):
    return {k: v for k, v in t if k not in SKIP}


def ring(nodes):
    out = []
    for n in nodes:
        if n.location.valid():
            out.append([round(n.lon, 7), round(n.lat, 7)])
    return out


class H(osmium.SimpleHandler):
    def __init__(self):
        super().__init__()
        self.nodes, self.ways, self.areas = [], [], []

    def node(self, n):
        if n.tags and n.location.valid() and inbox(n.lon, n.lat):
            self.nodes.append({"id": n.id, "t": tags(n.tags), "p": [round(n.lon, 7), round(n.lat, 7)]})

    def way(self, w):
        if not w.tags or len(w.nodes) < 2:
            return
        pts = ring(w.nodes)
        if not pts or not any(inbox(*p) for p in pts[:: max(1, len(pts) // 8)] + [pts[-1]]):
            return
        self.ways.append({"id": w.id, "t": tags(w.tags), "p": pts, "closed": w.is_closed()})

    def area(self, a):
        if not a.tags or a.from_way():
            return        # closed ways are in `ways` already; only relations here
        try:
            outers = list(a.outer_rings())
        except Exception:
            return
        for o in outers:
            pts = ring(o)
            if pts and any(inbox(*p) for p in pts):
                self.areas.append({"id": a.orig_id(), "t": tags(a.tags), "p": pts,
                                   "h": [ring(r) for r in a.inner_rings(o)]})


def main():
    t0 = time.time()
    os.makedirs(OUT, exist_ok=True)
    h = H()
    h.apply_file(SRC, locations=True, idx="flex_mem")
    out = {"box": [W, S, E, N], "nodes": h.nodes, "ways": h.ways, "areas": h.areas}
    json.dump(out, open(os.path.join(OUT, "osm_all.json"), "w", encoding="utf-8"), ensure_ascii=False)
    print("nodes %d ways %d relations %d  %.0f s" % (len(h.nodes), len(h.ways), len(h.areas), time.time() - t0))


if __name__ == "__main__":
    main()
