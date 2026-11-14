"""Whole-Yangon map: terrain study (14 Nov 2026, owner: "the terrains and everything is wrong too, in real life theres
hills and stuff").

Compares the ground the generator uses now (ground.py: SRTM 30 m, 3 x 3 minimum + Gaussian sigma 150 m, batch 0.5's d4 field
inside BOX_05) with the raw SRTM grid and the Copernicus GLO-30 DSM, tries a few de-building / de-tree filters that keep the
real hills, and writes previews, profiles, a vertical-scale comparison and the effect on batch 0.5's roads.

Inputs:
  build/city/dem_ygn.json                         SRTM 30 m (api.opentopodata.org), 0.0005 deg, rows south to north
  build/terrain_study/dl/glo30_N16_E096.tif       Copernicus GLO-30 DSM tile (public S3 open data, 1 arcsec, EGM2008 m)
      (c) DLR e.V. 2010-2014 and (c) Airbus Defence and Space GmbH 2014-2018, provided under COPERNICUS by the European
      Union and ESA; all rights reserved. Free to use with that attribution (Copernicus DEM licence).
  build/osm_ygn/areas.json                        water bodies and green areas (OSM, ODbL)
  imports/refs/map/ygn_roads_v5.json              batch 0.5 roads (sample y)

Outputs (build/terrain_study/):
  fields.npz            lon, lat, srtm, glo, current, proposed, options (metres), water mask, levels
  compare_fields.png    hill shade + 5 m contours: current | SRTM raw | GLO-30 raw | proposed
  compare_filters.png   the filter options side by side
  diff_proposed_minus_current.png
  profiles.png          4 profiles (metres), all fields
  vscale.png            the 2 main profiles in studs at VS 1.6 / 2.0 / 2.4 / 3.0 with a 6-floor building and a car
  places.json / roads_delta.json  heights at named places, per-road height changes
  zoom_<name>.png       close-ups (Shwedagon-Bahan, Inya, Kandawgyi-downtown)

    python terrain_study.py            (about 30 s)
"""
import json, math, os, sys

import numpy as np
from scipy.ndimage import (gaussian_filter, map_coordinates, minimum_filter, maximum_filter, percentile_filter,
                           distance_transform_edt)

import geo

OUT = os.path.join(geo.BUILD, 'terrain_study')
TIF = os.path.join(OUT, 'dl', 'glo30_N16_E096.tif')
VS = 1.6
BOX = (96.095, 96.235, 16.75, 16.89)   # lon0, lon1, lat0, lat1
ARC = 1.0 / 3600
CELL_M = ARC * geo.KY                  # ~30.7 m north-south (~29.4 m east-west)
WATER_MIN = 0.5
BANK_M = 1.5

PLACES = [  # name, lon, lat (OSM / landmarks.json; "~" = approximate)
    ('Shwedagon platform', 96.14935, 16.79815),
    ("People's Park (west foot)", 96.1430, 16.7975),
    ('Maha Wizaya', 96.1508, 16.7966),
    ('Sule Pagoda', 96.15875, 16.77445),
    ('Strand (river front)', 96.1625, 16.7695),
    ('Botataung', 96.1720, 16.7685),
    ('Theinbyu (~)', 96.1670, 16.7860),
    ('Pazundaung Market', 96.1758, 16.7824),
    ('Kandawgyi Lake', 96.1625, 16.7955),
    ('Karaweik', 96.1640, 16.7915),
    ('Kandawgyi east hill (~)', 96.1690, 16.7930),
    ('Bahan / Shwegondaing', 96.1570, 16.8071),
    ('Chaukhtatgyi', 96.1638, 16.8113),
    ('Golden Valley (~)', 96.1490, 16.8140),
    ('Yangon University', 96.1360, 16.8290),
    ('Kamayut, Hlaing riverside (~)', 96.1200, 16.8200),
    ('Ahlone riverside (~)', 96.1270, 16.7860),
    ('Inya Lake (water)', 96.1450, 16.8370),
    ('Inya Lake Hotel', 96.1525, 16.8437),
    ('Yankin', 96.1627, 16.8236),
    ('Kaba Aye Pagoda', 96.1545, 16.8568),
    ('Thamaing (~)', 96.1280, 16.8580),
    ('Thingangyun', 96.2012, 16.8386),
    ('Thaketa', 96.2050, 16.7950),
]

PROFILES = [  # name, [(lon, lat), ...]
    ('A  W-E across Shwedagon (lat 16.7982)', [(96.100, 16.79815), (96.230, 16.79815)]),
    ('B  W-E across Inya Lake (lat 16.8370)', [(96.100, 16.8370), (96.230, 16.8370)]),
    ('C  N-S ridge: Sule - Shwedagon - Bahan - Kaba Aye', [(96.15875, 16.7700), (96.14935, 16.79815), (96.1550, 16.8100),
                                                          (96.1530, 16.8300), (96.1545, 16.8568), (96.1560, 16.8890)]),
    ('D  W-E across downtown (lat 16.7790)', [(96.100, 16.7790), (96.230, 16.7790)]),
]


# ------------------------------------------------------------------ data
def load_glo():
    import tifffile
    with tifffile.TiffFile(TIF) as t:
        p = t.pages[0]
        tie = p.tags['ModelTiepointTag'].value
        a = p.asarray().astype(float)
    lon_w, lat_n = tie[3], tie[4]
    c0 = int(math.floor((BOX[0] - lon_w) / ARC))
    c1 = int(math.ceil((BOX[1] - lon_w) / ARC))
    r0 = int(math.floor((lat_n - BOX[3]) / ARC))
    r1 = int(math.ceil((lat_n - BOX[2]) / ARC))
    Z = a[r0:r1 + 1, c0:c1 + 1][::-1]            # rows south -> north
    lon = lon_w + np.arange(c0, c1 + 1) * ARC
    lat = lat_n - np.arange(r1, r0 - 1, -1) * ARC
    return lon, lat, Z


def load_srtm_on(lon, lat):
    d = json.load(open(os.path.join(geo.BUILD, 'city', 'dem_ygn.json')))
    H = np.array(d['h'], dtype=float)
    LON, LAT = np.meshgrid(lon, lat)
    fi = (LON - d['lon0']) / d['step']
    fj = (LAT - d['lat0']) / d['step']
    return map_coordinates(H, [fj, fi], order=1, mode='nearest'), d


def world_grid(lon, lat):
    LON, LAT = np.meshgrid(lon, lat)
    X = geo.OX + (LON - geo.LON0) * geo.KX * geo.SPM
    Zw = -(LAT - geo.LAT0) * geo.KY * geo.SPM
    return X, Zw


def osm_masks(lon, lat, Z):
    """water bodies (mask, per-cell level from GLO-30) and green / wooded areas"""
    from shapely.geometry import Polygon
    from shapely import contains_xy
    LON, LAT = np.meshgrid(lon, lat)
    W = np.zeros(Z.shape, bool)
    level = np.full(Z.shape, np.nan)
    floor = np.full(Z.shape, -1e9)
    G = np.zeros(Z.shape, bool)
    bodies = []
    for a in geo.load('areas'):
        t = a['t']
        water = t.get('natural') == 'water' or t.get('waterway') == 'riverbank' or t.get('landuse') in ('reservoir', 'basin')
        green = (t.get('leisure') in ('park', 'golf_course', 'garden', 'nature_reserve') or t.get('natural') in ('wood', 'scrub')
                 or t.get('landuse') in ('forest', 'recreation_ground'))   # not religious: pagoda hills are real hills
        if not (water or green) or len(a['p']) < 4:
            continue
        try:
            pl = Polygon(a['p']).buffer(0)
        except Exception:
            continue
        if pl.is_empty:
            continue
        x0, y0, x1, y1 = pl.bounds
        i0, i1 = np.searchsorted(lon, [x0, x1]); j0, j1 = np.searchsorted(lat, [y0, y1])
        if i1 <= i0 or j1 <= j0:
            continue
        sub = contains_xy(pl, LON[j0:j1, i0:i1], LAT[j0:j1, i0:i1])
        inside = np.zeros(Z.shape, bool); inside[j0:j1, i0:i1] = sub
        if not inside.any():
            continue
        if green and not water:
            G |= inside
            continue
        vals = Z[inside]
        lv = max(WATER_MIN, float(np.percentile(vals, 20)))
        W |= inside
        level = np.where(inside, np.fmin(level, lv), level)
        near = distance_transform_edt(~inside) * CELL_M < 60
        floor = np.where(near & ~inside, np.maximum(floor, lv + BANK_M), floor)
        area = pl.area * geo.KX * geo.KY / 1e4
        bodies.append(dict(name=t.get('name:en') or t.get('name') or '', kind=t.get('water') or t.get('waterway') or 'water',
                           area_ha=round(area, 1), level_m=round(lv, 2), glo_median=round(float(np.median(vals)), 2),
                           glo_p05=round(float(np.percentile(vals, 5)), 2), cells=int(inside.sum())))
    return W, np.where(np.isnan(level), 0.0, level), floor, G & ~W, bodies


# ------------------------------------------------------------------ filters
def disk(r):
    y, x = np.mgrid[-r:r + 1, -r:r + 1]
    return x * x + y * y <= r * r + 0.5


def opening(Z, land, r):
    """grey opening over land only (water cells neither lower nor raise the land): removes things narrower than 2r+1 cells"""
    fp = disk(r)
    e = minimum_filter(np.where(land, Z, 1e9), footprint=fp, mode='nearest')
    e = np.where(e > 1e8, Z, e)
    d = maximum_filter(np.where(land, e, -1e9), footprint=fp, mode='nearest')
    return np.where(d < -1e8, e, d)


def land_blur(Z, land, sig_cells):
    num = gaussian_filter(np.where(land, Z, 0.0), sig_cells, mode='nearest')
    den = gaussian_filter(land.astype(float), sig_cells, mode='nearest')
    return np.where(den > 0.05, num / np.maximum(den, 1e-6), Z)


def finish(F, W, level, floor):
    F = np.maximum(F, floor)
    return np.where(W, level, F)


def make_options(glo, srtm, W, level, floor, Gm):
    land = ~W
    o = {}
    # A: what ground.py does, on GLO-30 (3x3 min of 30 m cells, sigma 150 m) - shows the blur is what flattens
    o['A min3+blur150 (GLO)'] = land_blur(minimum_filter(np.where(land, glo, 1e9), 3, mode='nearest').clip(max=1e8), land,
                                          150 / CELL_M)
    # B: opening r 2 (~150 m disk) + sigma 30 m
    o['B open150+blur30'] = land_blur(opening(glo, land, 2), land, 1.0)
    # C: opening r 4 (~270 m disk) + sigma 45 m
    o['C open270+blur45'] = land_blur(opening(glo, land, 4), land, 1.5)
    # D: 10th percentile in a 7 x 7 window (~210 m) + sigma 45 m
    o['D pct10x7+blur45'] = land_blur(percentile_filter(np.where(land, glo, np.nan_to_num(glo)), 10, size=7), land, 1.5)
    # E: C plus a wider opening r 6 (~390 m) inside parks / woods / golf to take more canopy off. REJECTED: Shwedagon's
    # hill lies inside a park polygon and its ~250 m wide top was cut from ~57 to ~45 m (the old field's flat-top fault)
    b = opening(glo, land, 4)
    big = opening(glo, land, 6)
    gw = gaussian_filter(Gm.astype(float), 2.0)          # soft edge of the green areas
    mix = b * (1 - gw) + np.minimum(b, big) * gw
    o['E C+open390 in parks'] = land_blur(mix, land, 1.5)
    return {k: finish(v, W, level, floor) for k, v in o.items()}


# ------------------------------------------------------------------ helpers
def sampler(lon, lat, F):
    def at(lo, la):
        fi = (np.asarray(lo) - lon[0]) / ARC
        fj = (np.asarray(la) - lat[0]) / ARC
        return map_coordinates(F, [np.atleast_1d(fj), np.atleast_1d(fi)], order=1, mode='nearest')
    return at


def line_pts(poly, step_m=15.0):
    out = []
    for (a0, b0), (a1, b1) in zip(poly, poly[1:]):
        L = math.hypot((a1 - a0) * geo.KX, (b1 - b0) * geo.KY)
        n = max(1, int(L / step_m))
        for k in range(n):
            t = k / n
            out.append((a0 + (a1 - a0) * t, b0 + (b1 - b0) * t))
    out.append(poly[-1])
    P = np.array(out)
    s = np.r_[0, np.cumsum(np.hypot(np.diff(P[:, 0]) * geo.KX, np.diff(P[:, 1]) * geo.KY))]
    return P, s


def hillshade_ax(ax, lon, lat, F, title, vmax=60, places=True, step=5):
    from matplotlib.colors import LightSource
    import matplotlib.pyplot as plt
    ls = LightSource(azdeg=315, altdeg=35)
    dx = ARC * geo.KX
    rgb = ls.shade(F, cmap=plt.get_cmap('terrain'), vert_exag=4, dx=dx, dy=CELL_M, blend_mode='soft', vmin=-15, vmax=vmax)
    ext = (lon[0], lon[-1], lat[0], lat[-1])
    ax.imshow(rgb, origin='lower', extent=ext, aspect=1 / math.cos(math.radians(16.82)))
    cs = ax.contour(lon, lat, F, levels=np.arange(0, 80, step), colors='k', linewidths=0.35, alpha=0.6)
    ax.contour(lon, lat, F, levels=np.arange(0, 80, 25), colors='k', linewidths=0.9)
    ax.clabel(cs, levels=[l for l in cs.levels if l % 10 == 0], fontsize=5, fmt='%d')
    if places:
        for nm, lo, la in PLACES:
            if ext[0] <= lo <= ext[1] and ext[2] <= la <= ext[3]:
                ax.plot(lo, la, 'r.', ms=3)
                ax.text(lo, la, ' ' + nm.split(' (')[0], fontsize=4.5, color='darkred')
    ax.set_title(title, fontsize=8)
    ax.tick_params(labelsize=5)


# ------------------------------------------------------------------ main
def main():
    sys.stdout.reconfigure(encoding='utf-8')
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    import ground

    lon, lat, glo = load_glo()
    srtm, _ = load_srtm_on(lon, lat)
    X, Zw = world_grid(lon, lat)
    G = ground.Ground()
    cur = (G.ys(np.column_stack([X.ravel(), Zw.ravel()])) / VS).reshape(glo.shape)
    W, level, floor, Gm, bodies = osm_masks(lon, lat, glo)
    opts = make_options(glo, srtm, W, level, floor, Gm)
    prop = opts['C open270+blur45']   # the proposed field (see the report)
    land = ~W
    print('grid %d x %d (1 arcsec), water cells %.1f%%, green cells %.1f%%' % (glo.shape[1], glo.shape[0], 100 * W.mean(),
                                                                                100 * Gm.mean()))

    # ---- GLO vs SRTM
    d = (glo - srtm)[land]
    print('GLO-30 minus SRTM over land: mean %+.2f m, median %+.2f, sd %.2f, p5 %+.1f p95 %+.1f' % (
        d.mean(), np.median(d), d.std(), np.percentile(d, 5), np.percentile(d, 95)))
    dw = (glo - srtm)[W]
    print('GLO-30 minus SRTM over water: mean %+.2f m; GLO water cells sd %.2f, SRTM water sd %.2f' % (
        dw.mean(), glo[W].std(), srtm[W].std()))
    for b in sorted(bodies, key=lambda b: -b['area_ha'])[:8]:
        print('  water %-24s %-6s %6.1f ha  level %.2f (GLO median %.2f, p5 %.2f)' % (
            b['name'][:24], b['kind'], b['area_ha'], b['level_m'], b['glo_median'], b['glo_p05']))

    fields = {'current (ground.py)': cur, 'SRTM raw': srtm, 'GLO-30 raw': glo}
    fields.update(opts)
    fields['proposed (C)'] = prop
    np.savez_compressed(os.path.join(OUT, 'fields.npz'), lon=lon, lat=lat, srtm=srtm, glo=glo, current=cur, proposed=prop,
                        water=W, green=Gm, level=level, **{'opt_' + k[0]: v for k, v in opts.items()})

    # ---- named places
    rows = []
    print('\n%-30s %7s %7s %7s %7s %7s %7s %7s' % ('place (m)', 'current', 'SRTM', 'GLO', 'B', 'C', 'D', 'E'))
    for nm, lo, la in PLACES:
        v = {k: float(sampler(lon, lat, F)(lo, la)[0]) for k, F in fields.items()}
        rows.append(dict(name=nm, lon=lo, lat=la, **{k: round(x, 1) for k, x in v.items()}))
        print('%-30s %7.1f %7.1f %7.1f %7.1f %7.1f %7.1f %7.1f' % (nm[:30], v['current (ground.py)'], v['SRTM raw'],
              v['GLO-30 raw'], v['B open150+blur30'], v['C open270+blur45'], v['D pct10x7+blur45'], v['E C+open390 in parks']))
    json.dump(rows, open(os.path.join(OUT, 'places.json'), 'w'), indent=1)

    # relief summary
    for k in ('current (ground.py)', 'SRTM raw', 'GLO-30 raw', 'proposed (C)'):
        F = fields[k]
        gy, gx = np.gradient(F, CELL_M, ARC * geo.KX)
        sl = np.hypot(gx, gy)[land]
        print('%-22s land p5 %.1f p50 %.1f p95 %.1f max %.1f m | slope p50 %.1f%% p95 %.1f%% p99 %.1f%%' % (
            k, *np.percentile(F[land], [5, 50, 95]), F[land].max(), *(np.percentile(sl, [50, 95, 99]) * 100)))

    # ---- maps
    fig, axs = plt.subplots(1, 4, figsize=(22, 6.4), dpi=170)
    for ax, k in zip(axs, ['current (ground.py)', 'SRTM raw', 'GLO-30 raw', 'proposed (C)']):
        hillshade_ax(ax, lon, lat, fields[k], k + ' - contours 5 m')
    for ax in axs:
        for nm, poly in PROFILES:
            P = np.array(poly); ax.plot(P[:, 0], P[:, 1], 'b-', lw=0.5, alpha=0.6); ax.text(*P[0], nm[0], color='b', fontsize=6)
    fig.tight_layout(); fig.savefig(os.path.join(OUT, 'compare_fields.png')); plt.close(fig)

    fig, axs = plt.subplots(1, 5, figsize=(27, 6.4), dpi=150)
    for ax, k in zip(axs, list(opts)):
        hillshade_ax(ax, lon, lat, opts[k], k, places=False)
    fig.tight_layout(); fig.savefig(os.path.join(OUT, 'compare_filters.png')); plt.close(fig)

    fig, ax = plt.subplots(figsize=(9, 8), dpi=160)
    im = ax.imshow(prop - cur, origin='lower', extent=(lon[0], lon[-1], lat[0], lat[-1]), cmap='RdBu_r', vmin=-15, vmax=15,
                   aspect=1 / math.cos(math.radians(16.82)))
    ax.contour(lon, lat, prop, levels=np.arange(0, 80, 5), colors='k', linewidths=0.3, alpha=0.5)
    x0, z0, x1, z1 = geo.BOX_05
    (a0, b0), (a1, b1) = geo.lonlat(x0, z0), geo.lonlat(x1, z1)
    ax.plot([a0, a1, a1, a0, a0], [b0, b0, b1, b1, b0], 'g-', lw=1)
    ax.text(a0, b0, ' batch 0.5 box', color='g', fontsize=7, va='bottom')
    for nm, lo, la in PLACES:
        ax.plot(lo, la, 'k.', ms=2); ax.text(lo, la, ' ' + nm.split(' (')[0], fontsize=5)
    fig.colorbar(im, ax=ax, label='proposed minus current (m)')
    ax.set_title('Proposed ground minus current ground (m); contours = proposed, 5 m', fontsize=9)
    fig.tight_layout(); fig.savefig(os.path.join(OUT, 'diff_proposed_minus_current.png')); plt.close(fig)

    for nm, box in (('shwedagon_bahan', (96.13, 96.18, 16.785, 16.825)), ('inya_kabaaye', (96.125, 96.175, 16.82, 16.865)),
                    ('kandawgyi_downtown', (96.145, 96.20, 16.762, 16.805))):
        i0, i1 = np.searchsorted(lon, box[:2]); j0, j1 = np.searchsorted(lat, box[2:])
        fig, axs = plt.subplots(1, 4, figsize=(20, 5.6), dpi=170)
        for ax, k in zip(axs, ['current (ground.py)', 'SRTM raw', 'GLO-30 raw', 'proposed (C)']):
            hillshade_ax(ax, lon[i0:i1], lat[j0:j1], fields[k][j0:j1, i0:i1], k + ' (5 m contours)', step=2.5 if False else 5)
        fig.tight_layout(); fig.savefig(os.path.join(OUT, 'zoom_%s.png' % nm)); plt.close(fig)

    # ---- profiles
    styles = {'A min3+blur150 (GLO)': ('tab:cyan', 0.7, ':'), 'current (ground.py)': ('k', 1.6, '-'), 'SRTM raw': ('tab:orange', 0.7, '-'), 'GLO-30 raw': ('0.6', 0.6, '-'),
              'B open150+blur30': ('tab:green', 0.8, '--'), 'C open270+blur45': ('tab:purple', 0.8, '--'),
              'D pct10x7+blur45': ('tab:brown', 0.8, ':'), 'E C+open390 in parks': ('tab:pink', 0.7, ':'),
              'proposed (C)': ('tab:red', 1.8, '-')}
    fig, axs = plt.subplots(4, 1, figsize=(14, 15), dpi=150)
    prof_out = {}
    for ax, (nm, poly) in zip(axs, PROFILES):
        P, s = line_pts(poly)
        prof_out[nm] = {}
        for k, F in fields.items():
            h = sampler(lon, lat, F)(P[:, 0], P[:, 1])
            prof_out[nm][k] = h
            c, lw, ls_ = styles[k]
            ax.plot(s / 1000, h, color=c, lw=lw, ls=ls_, label=k)
        wat = sampler(lon, lat, W.astype(float))(P[:, 0], P[:, 1]) > 0.5
        ax.fill_between(s / 1000, -2, 0, where=wat, color='tab:blue', alpha=0.4, step='mid', label='water (OSM)')
        for pn, lo, la in PLACES:
            dd = np.hypot((P[:, 0] - lo) * geo.KX, (P[:, 1] - la) * geo.KY)
            if dd.min() < 350:
                k = int(dd.argmin()); ax.axvline(s[k] / 1000, color='0.8', lw=0.5)
                ax.text(s[k] / 1000, 62, pn.split(' (')[0], rotation=90, fontsize=6, va='top')
        ax.set_ylim(-2, 75); ax.set_title(nm, fontsize=9); ax.set_ylabel('m'); ax.grid(alpha=0.3)
        ax.set_yticks(np.arange(0, 76, 5)); ax.tick_params(labelsize=6)
    axs[0].legend(fontsize=6, ncol=4, loc='upper right')
    axs[-1].set_xlabel('km along the line (west to east / south to north)')
    fig.tight_layout(); fig.savefig(os.path.join(OUT, 'profiles.png')); plt.close(fig)

    # ---- vertical scale
    VSS = ((1.6, 'tab:blue'), (2.0, 'tab:green'), (2.4, 'tab:red'), (3.0, 'tab:purple'))
    fig, axs = plt.subplots(2, 1, figsize=(15, 9), dpi=150)
    print('\nvertical scale (proposed field): relief and steepest grade (smoothed over 60 m) in the 5 km window')
    for ax, (nm, poly) in zip(axs, [PROFILES[0], PROFILES[2]]):
        P, s = line_pts(poly)
        h = prof_out[nm]['proposed (C)']
        k = int(np.argmax(h))
        win = (s > s[k] - 2500) & (s < s[k] + 2500)
        sx = (s[win] - s[k]) * geo.SPM
        hw = h[win]
        ax.plot(sx, prof_out[nm]['current (ground.py)'][win] * 1.6, 'k-', lw=1.2, label='current field, VS 1.6')
        for vs, c in VSS:
            g = np.abs(hw[4:] - hw[:-4]) * vs / (np.diff(s[win])[0] * 4 * geo.SPM)
            lab = 'proposed, VS %.1f (%s): top %.0f studs, relief %.0f, steepest %.0f%%' % (
                vs, 'true' if vs == 1.6 else 'x%.2f' % (vs / 1.6), hw.max() * vs, (hw.max() - hw.min()) * vs, 100 * g.max())
            print('  ' + nm[:2] + lab)
            ax.plot(sx, hw * vs, color=c, lw=1.4, label=lab)
        # a 6-floor walk-up (12 + 5 x 9 = 57 studs, 70 wide) at the hill's foot and a 3-floor shophouse on top, at VS 2.4
        foot = int(np.argmin(np.abs(sx - 1800)))
        ax.add_patch(plt.Rectangle((sx[foot], hw[foot] * 2.4), 70, 57, color='0.35', alpha=0.7))
        ax.text(sx[foot], hw[foot] * 2.4 + 62, '6-floor block\n(57 studs)', fontsize=6)
        top = int(np.argmax(hw))
        ax.add_patch(plt.Rectangle((sx[top] + 150, hw[top] * 2.4 - 2), 40, 30, color='0.35', alpha=0.7))
        ax.text(sx[top] + 150, hw[top] * 2.4 + 32, '3-floor (30)', fontsize=6)
        ax.set_title(nm + ' - 5 km round the highest point, studs (horizontal 1.6 a metre; drawn with vertical x5)', fontsize=9)
        ax.set_aspect(5); ax.set_ylabel('studs'); ax.grid(alpha=0.3); ax.tick_params(labelsize=6)
        ax.set_ylim(-5, 200)
        ax.legend(fontsize=6.5, loc='upper left')
    axs[1].set_xlabel('studs from the highest point')
    fig.tight_layout(); fig.savefig(os.path.join(OUT, 'vscale.png')); plt.close(fig)

    # ---- batch 0.5 roads
    R = json.load(open(os.path.join(geo.MAP, 'ygn_roads_v5.json'), encoding='utf-8'))
    deck = {k: set(v) for k, v in R['cut'].items()}
    at_new = sampler(lon, lat, prop)
    res = []
    print('\nbatch 0.5 roads: ground change at their samples (studs; proposed - old), VS 1.6 and 2.4')
    print('%-30s %5s %7s %7s %7s %7s | %7s %7s | %6s %6s' % ('road', 'n', 'mean', 'min', 'max', 'max|d|', 'mean2.4', 'max|d|',
                                                          'grade', 'grd2.4'))
    for r in R['roads']:
        S = np.array([s[:3] for s in r['s']], dtype=float)
        old = G.ys(S[:, [0, 2]]) / VS
        lo, la = geo.lonlat(S[:, 0], S[:, 2])
        new = at_new(lo, la)
        d16 = (new - old) * 1.6
        d24 = new * 2.4 - old * 1.6
        ds = np.hypot(np.diff(S[:, 0]), np.diff(S[:, 2]))
        ok = ds > 0.5
        g16 = np.abs(np.diff(new * 1.6))[ok] / ds[ok]
        g24 = np.abs(np.diff(new * 2.4))[ok] / ds[ok]
        # smooth the grade over ~40 studs (a road's own profile is smoothed when it is rebuilt)
        def sgrade(h, w=10):
            if len(h) < w + 2:
                return float(np.max(np.abs(np.diff(h))[ok] / ds[ok])) if ok.any() else 0.0
            L = np.r_[0, np.cumsum(ds)]
            return float(np.max(np.abs(h[w:] - h[:-w]) / np.maximum(L[w:] - L[:-w], 1)))
        rec = dict(name=r['name'], kind=r['kind'], n=len(S), deck_samples=len(deck.get(r['name'], ())),
                   old_ground_m=[round(float(old.min()), 1), round(float(old.max()), 1)],
                   new_ground_m=[round(float(new.min()), 1), round(float(new.max()), 1)],
                   d_studs_vs16=dict(mean=round(float(d16.mean()), 1), min=round(float(d16.min()), 1),
                                     max=round(float(d16.max()), 1), maxabs=round(float(np.abs(d16).max()), 1),
                                     p90abs=round(float(np.percentile(np.abs(d16), 90)), 1)),
                   d_studs_vs24=dict(mean=round(float(d24.mean()), 1), maxabs=round(float(np.abs(d24).max()), 1)),
                   grade_pct_vs16=round(100 * sgrade(new * 1.6), 1), grade_pct_vs24=round(100 * sgrade(new * 2.4), 1),
                   old_grade_pct=round(100 * sgrade(old * 1.6), 1))
        res.append(rec)
        print('%-30s %5d %+7.1f %+7.1f %+7.1f %7.1f | %+7.1f %7.1f | %5.1f%% %5.1f%%' % (
            r['name'][:30], len(S), d16.mean(), d16.min(), d16.max(), np.abs(d16).max(), d24.mean(), np.abs(d24).max(),
            rec['grade_pct_vs16'], rec['grade_pct_vs24']))
    allabs = np.array([x['d_studs_vs16']['maxabs'] for x in res])
    print('roads moving > 8 studs (VS 1.6): %d of %d' % ((allabs > 8).sum(), len(res)))
    json.dump(dict(note='ground change under each batch 0.5 road: proposed field (terrain_study E) minus the field it was '
                        'built on (ygn_road_design ground), studs; grades smoothed over ~40 studs', roads=res, water=bodies),
              open(os.path.join(OUT, 'roads_delta.json'), 'w'), indent=1)
    print('\nwrote', OUT)


if __name__ == '__main__':
    main()
