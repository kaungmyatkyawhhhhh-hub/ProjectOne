"""p1_site_ground.py (2026-11-16, the 1:1 refit of Myanmar Centre and Sedona in pilot P1): the real ground round the two
sites, read from the P1 build itself (no game-scale guessing):

  * the road footprint (carriageway R, flush strip F, pavement P, medians MG, kerbs K*) from the P1 road meshes
    (build/city_1to1/roads_P1_meshes.pkl), as one shapely shape in the OLD model frame (onetoone.old_of_world);
  * the pavement heights round a site (P triangles) -> a plane y = a + b (X - OX1) + c (Z - OZ1) in 1:1 world studs;
  * the terrain top (build/city_1to1/terrain_P1_state.npz, 4-stud columns);
  * the buildings agent's built plots (build/city_1to1/buildings_P1/plots.json) as shapes, to stay off them.

    from p1_site_ground import Ground; G = Ground((x0, y0, x1, y1))   # OLD model box
"""
import json
import os
import pickle

import numpy as np
from shapely.geometry import Polygon, box as sbox
from shapely.ops import unary_union

import onetoone as X1

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "..", "..")
B11 = os.path.join(ROOT, "build", "city_1to1")
ROAD_KINDS = ("R", "F", "P", "MG", "KR", "KW", "KG", "B")


class Ground:
    def __init__(self, box_old):
        self.box_old = box_old
        x0, y0, x1, y1 = box_old
        X0, Z1 = X1.world_of_model(x0 * X1.S, y0 * X1.S)
        X1_, Z0 = X1.world_of_model(x1 * X1.S, y1 * X1.S)
        self.wbox = (X0, Z0, X1_, Z1)
        d = pickle.load(open(os.path.join(B11, "roads_P1_meshes.pkl"), "rb"))["meshes"]
        polys, pave = [], []
        for k, v in d.items():
            if k[0] not in ROAD_KINDS:
                continue
            v = np.asarray(v)
            c = v.mean(axis=1)
            m = (c[:, 0] > X0 - 40) & (c[:, 0] < X1_ + 40) & (c[:, 2] > Z0 - 40) & (c[:, 2] < Z1 + 40)
            for t in v[m]:
                pts = [X1.old_of_world(p[0], p[2]) for p in t]
                P = Polygon(pts)
                if P.area > 1e-6:
                    polys.append(P.buffer(0.02))
                if k[0] == "P":
                    pave.append(t.mean(axis=0))
        self.road = unary_union(polys)
        self.pave_pts = np.array(pave) if pave else np.zeros((0, 3))
        st = np.load(os.path.join(B11, "terrain_P1_state.npz"))
        self.H, self.ox, self.oz = st["H"], float(st["origin"][0]), float(st["origin"][1])
        self.plots = []
        for p in json.load(open(os.path.join(B11, "buildings_P1", "plots.json"))):
            P = Polygon([X1.old_of_world(a, b) for a, b in p["poly"]])
            if P.is_valid and P.intersects(sbox(*box_old)):
                self.plots.append(P)
        self.plots_u = unary_union(self.plots) if self.plots else Polygon()

    def terrain(self, X, Z):
        i, j = int((X - self.ox) / 4.0), int((Z - self.oz) / 4.0)
        return float(self.H[i, j])

    def terrain_old(self, x, y):
        X, Z = X1.world_of_model(x * X1.S, y * X1.S)
        return self.terrain(X, Z)

    def plane_near(self, shape_old, reach_old=40.0):
        """Least-squares pavement plane from the P triangles within reach of a shape (OLD frame)."""
        from shapely.geometry import Point
        zone = shape_old.buffer(reach_old)
        from shapely.prepared import prep
        pz = prep(zone)
        rows = [p for p in self.pave_pts if pz.contains(Point(*X1.old_of_world(p[0], p[2])))]
        A = np.array([[1.0, p[0] - X1.OX1, p[2] - X1.OZ1] for p in rows])
        y = np.array([p[1] for p in rows])
        coef, *_ = np.linalg.lstsq(A, y, rcond=None)
        res = y - A @ coef
        return [float(c) for c in coef], len(rows), float(np.abs(res).max()) if len(res) else 0.0

    def free(self, box_old=None):
        """The site box minus the roads (OLD frame)."""
        return sbox(*(box_old or self.box_old)).difference(self.road)
