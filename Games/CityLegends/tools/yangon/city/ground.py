"""Whole-Yangon map (14 Nov 2026): the ground height field for batches 1-3 (roads.py uses it; the terrain step should too).

Source: build/city/dem_ygn.json (SRTM 30 m via api.opentopodata.org, tools/yangon/city/dem_fetch.py: lon 96.095-96.235,
lat 16.75-16.89, step 0.0005 deg, rows south to north), or while that download runs, build/city/dem_partial.json (the rows
it has; missing cells are filled from their neighbours and reported).

Made the way batch 0.5's ground was (tools/yangon/d4_heights.py): SRTM includes roofs and trees, so over land the 3 x 3
minimum, then a land-only normalised Gaussian (sigma 150 m, as d4's 2.5 cells of ~60 m). Studs: Y = metres x 1.6 (VS 1.6,
datum 0 m = 0 studs: d6_export.py `world()`, YangonTerrain.luau `M.height`); a road's surface is at Y, its terrain shows
1 stud lower (YangonTerrain M.UNDER).

Batch 0.5's ground (imports/refs/map/ygn_road_design.json `ground`, the field its terrain and roads were built from, with
its 17.5 m floor at Inya Lake's level) is kept exactly inside BOX_05, and the new field is blended onto it over BLEND studs
outside the box, so the new terrain and roads meet batch 0.5's at the seam.

Water: every OSM water area (natural=water, rivers, ponds, lakes) gets its own level: the 20th percentile of the raw DEM
cells inside it (at least WATER_MIN m; SRTM over water is noisy), and the land within 60 m of it is kept at least 1.5 m above
that level (d4's lake rule, per body instead of one level for the whole city).

    import ground
    G = ground.Ground()            # loads and smooths once (about 2 s)
    G.y(x, z)  / G.ys(P)           # ground height in studs at world x, z (P: N x 2 array)
    G.water_at(x, z)               # (level studs, body name) or None
    G.water                        # list of {name, kind, level_m, area_ha, poly (world studs)}
"""
import json, math, os

import numpy as np
from scipy.ndimage import minimum_filter, gaussian_filter, distance_transform_edt

import geo

VS = 1.6
BLEND = 480.0          # studs outside BOX_05 over which the new field fades onto batch 0.5's
SIGMA_M = 150.0
WATER_MIN = 1.0        # metres
BANK_M = 1.5           # land near water at least this far above the water level
BIG_WATER_HA = 3.0     # a water body this big is "water" for bridges (clearance 10+); smaller ones are ponds / drains


def _load_dem():
    full = os.path.join(geo.BUILD, 'city', 'dem_ygn.json')
    if os.path.exists(full):
        d = json.load(open(full))
        return d['lon0'], d['lat0'], d['step'], np.array(d['h'], dtype=float), 'full'
    import dem_fetch as df
    got = json.load(open(df.PART))
    nx, ny = df.NX, df.NY
    flat = np.full(nx * ny, np.nan)
    for k, v in got.items():
        k = int(k)
        vals = [np.nan if e is None else e for e in v]
        flat[k:k + len(vals)] = vals
    return df.LON0, df.LAT0, df.STEP, flat.reshape(ny, nx), 'partial %.0f%%' % (100 * np.isfinite(flat).mean())


class Ground:
    def __init__(self):
        lon0, lat0, step, Z, self.source = _load_dem()
        self.missing = int(np.isnan(Z).sum())
        if self.missing:
            # fill unknown cells from the nearest known one (partial download)
            idx = distance_transform_edt(np.isnan(Z), return_distances=False, return_indices=True)
            Z = Z[tuple(idx)]
        self.Z = Z
        ny, nx = Z.shape
        self.nx, self.ny = nx, ny
        # cell centres in world studs (x grows east, z grows SOUTH: row j = lat0 + j*step)
        self.gx = np.array([geo.world(lon0 + i * step, lat0)[0] for i in range(nx)])
        self.gz = np.array([geo.world(lon0, lat0 + j * step)[1] for j in range(ny)])
        self._water(lon0, lat0, step)
        land = ~self.W
        zmin = minimum_filter(np.where(land, Z, 1e9), size=3, mode='nearest')
        zmin = np.where(zmin > 1e8, Z, zmin)
        cell_m = step * geo.KY
        sig = SIGMA_M / cell_m
        num = gaussian_filter(np.where(land, zmin, 0.0), sig, mode='nearest')
        den = gaussian_filter(land.astype(float), sig, mode='nearest')
        F = np.where(den > 0.05, num / np.maximum(den, 1e-6), Z)
        # banks: land near each body at least BANK_M over its level; water cells at the level
        F = np.maximum(F, self.bank_floor)
        F = np.where(self.W, self.level_grid, F)
        self.F = F
        self._load05()

    # ------------------------------------------------------------ water bodies
    def _water(self, lon0, lat0, step):
        from shapely.geometry import Polygon
        from shapely import contains_xy
        ny, nx = self.Z.shape
        LON = lon0 + np.arange(nx) * step
        LAT = lat0 + np.arange(ny) * step
        X, Y = np.meshgrid(LON, LAT)
        W = np.zeros(self.Z.shape, bool)
        level = np.full(self.Z.shape, np.nan)
        floor = np.full(self.Z.shape, -1e9)
        self.water = []
        for a in geo.load('areas'):
            t = a['t']
            if not (t.get('natural') == 'water' or t.get('waterway') == 'riverbank' or t.get('landuse') in ('reservoir', 'basin')):
                continue
            p = a['p']
            if len(p) < 4:
                continue
            try:
                pl = Polygon(p).buffer(0)
            except Exception:
                continue
            if pl.is_empty:
                continue
            area_ha = pl.area * geo.KX * geo.KY / 1e4
            inside = contains_xy(pl, X, Y)
            vals = self.Z[inside & np.isfinite(self.Z)]
            if vals.size == 0:
                c = pl.representative_point()
                i = int(round((c.x - lon0) / step))
                j = int(round((c.y - lat0) / step))
                if not (0 <= i < nx and 0 <= j < ny):
                    continue
                vals = np.array([self.Z[j, i]])
            lv = max(WATER_MIN, float(np.percentile(vals, 20)))
            name = t.get('name:en') or t.get('name') or ''
            kind = t.get('water') or t.get('waterway') or 'water'
            W |= inside
            level = np.where(inside, np.fmin(level, lv), level)
            # bank floor within ~60 m of the body (1-2 cells)
            if inside.any():
                near = distance_transform_edt(~inside) * step * geo.KY < 60
                floor = np.where(near & ~inside, np.maximum(floor, lv + BANK_M), floor)
            wpoly = Polygon([geo.world(x, y) for x, y in pl.exterior.coords]) if pl.geom_type == 'Polygon' else None
            if wpoly is None:
                from shapely.ops import unary_union
                wpoly = unary_union([Polygon([geo.world(x, y) for x, y in g.exterior.coords]) for g in pl.geoms])
            self.water.append(dict(id=a['id'], name=name, kind=kind, level_m=round(lv, 2), area_ha=round(area_ha, 2),
                                   big=area_ha >= BIG_WATER_HA or kind in ('river', 'canal'), poly=wpoly))
        self.W = W
        self.level_grid = np.where(np.isnan(level), 0.0, level)
        self.bank_floor = floor
        from shapely.strtree import STRtree
        self._wtree = STRtree([w['poly'] for w in self.water])

    def water_at(self, x, z, big_only=False):
        from shapely.geometry import Point
        p = Point(x, z)
        best = None
        for i in self._wtree.query(p):
            w = self.water[int(i)]
            if big_only and not w['big']:
                continue
            if w['poly'].contains(p):
                if best is None or w['level_m'] > best['level_m']:
                    best = w
        return (best['level_m'] * VS, best) if best else None

    # ------------------------------------------------------------ batch 0.5's field
    def _load05(self):
        d = json.load(open(os.path.join(geo.MAP, 'ygn_road_design.json'), encoding='utf-8'))
        g = d['ground']
        self.g05 = np.array(g['height_m'], dtype=float)  # rows south -> north, metres in the plan frame
        self.g05_x = np.linspace(g['west_m'], g['east_m'], g['nx'])
        self.g05_y = np.linspace(g['south_m'], g['north_m'], g['ny'])

    def _f05(self, X, Z):
        """batch 0.5's ground (metres) at world X, Z, clamped to its grid (d4 sampler)"""
        x = (X - geo.OX) / geo.SPM
        y = -Z / geo.SPM
        gx, gy, F = self.g05_x, self.g05_y, self.g05
        fi = np.clip((x - gx[0]) / (gx[1] - gx[0]), 0, len(gx) - 1.001)
        fj = np.clip((y - gy[0]) / (gy[1] - gy[0]), 0, len(gy) - 1.001)
        i = fi.astype(int)
        j = fj.astype(int)
        a = fi - i
        b = fj - j
        return F[j, i] * (1 - a) * (1 - b) + F[j, i + 1] * a * (1 - b) + F[j + 1, i] * (1 - a) * b + F[j + 1, i + 1] * a * b

    def _fnew(self, X, Z):
        gx, gz, F = self.gx, self.gz, self.F
        # gz decreases with j (north = -Z): use the row index from the top
        fi = np.clip((X - gx[0]) / (gx[1] - gx[0]), 0, len(gx) - 1.001)
        fj = np.clip((Z - gz[0]) / (gz[1] - gz[0]), 0, len(gz) - 1.001)
        i = fi.astype(int)
        j = fj.astype(int)
        a = fi - i
        b = fj - j
        return F[j, i] * (1 - a) * (1 - b) + F[j, i + 1] * a * (1 - b) + F[j + 1, i] * (1 - a) * b + F[j + 1, i + 1] * a * b

    def ys(self, P):
        """ground height in studs at world points P (N x 2)"""
        P = np.atleast_2d(np.asarray(P, dtype=float))
        X, Z = P[:, 0], P[:, 1]
        x0, z0, x1, z1 = geo.BOX_05
        dx = np.maximum(np.maximum(x0 - X, X - x1), 0)
        dz = np.maximum(np.maximum(z0 - Z, Z - z1), 0)
        d = np.hypot(dx, dz)
        u = np.clip(d / BLEND, 0, 1)
        w = u * u * (3 - 2 * u)
        return ((1 - w) * self._f05(X, Z) + w * self._fnew(X, Z)) * VS

    def y(self, x, z):
        return float(self.ys([[x, z]])[0])


if __name__ == '__main__':
    import sys
    sys.stdout.reconfigure(encoding='utf-8')
    G = Ground()
    print('DEM', G.source, 'missing cells filled:', G.missing, 'grid', G.nx, 'x', G.ny)
    print('field m: min %.1f max %.1f' % (G.F.min(), G.F.max()))
    for nm, lo, la in (('Sule', 96.1588, 16.7744), ('Shwedagon', 96.1494, 16.7991), ('Chaukhtatgyi', 96.1639, 16.8117),
                       ('Hledan', 96.1286, 16.8240), ('Kandawgyi', 96.1640, 16.7960), ('Thaketa', 96.2050, 16.7950)):
        x, z = geo.world(lo, la)
        print('%-13s %.1f studs (%.1f m)' % (nm, G.y(x, z), G.y(x, z) / VS))
    for w in sorted(G.water, key=lambda w: -w['area_ha'])[:10]:
        print('water %-28s %-6s %7.1f ha level %.1f m' % (w['name'][:28], w['kind'], w['area_ha'], w['level_m']))
