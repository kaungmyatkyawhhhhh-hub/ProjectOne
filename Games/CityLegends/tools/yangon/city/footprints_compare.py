"""Compare OSM / Microsoft / Overture footprints in sample spots over Esri World Imagery; densities and error stats."""
import json, math, os, subprocess
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from shapely.geometry import shape, Polygon, box as sbox
from shapely.strtree import STRtree

G = 'D:/ObsidianOne/Claude+Obsidian/Games/CityLegends/build'
F = G + '/footprints'
OUT = F + '/samples'; os.makedirs(OUT, exist_ok=True)
TILES = F + '/raw/esri'; os.makedirs(TILES, exist_ok=True)
LAT0 = 16.82
MX = 111320 * math.cos(math.radians(LAT0)); MY = 110574


def m(lon, lat):
    return ((lon - 96.165) * MX, (lat - LAT0) * MY)


SPOTS = {  # name: (lon, lat) centre; each sample is 3x3 z18 tiles (~440 m square)
    'downtown': (96.1560, 16.7765),
    'kamayut_hledan': (96.1290, 16.8240),
    'bahan': (96.1560, 16.8090),
    'inya_lake_east': (96.1505, 16.8380),
    'myanmar_plaza': (96.1565, 16.8260),
}


def load_ll(path):
    d = json.load(open(path, encoding='utf-8'))
    out = []
    for f in d['features']:
        g = shape(f['geometry'])
        if g.geom_type == 'MultiPolygon':
            g = max(g.geoms, key=lambda q: q.area)
        out.append((g, f['properties']))
    return out


def osm_ll():
    d = json.load(open(G + '/osm_ygn/buildings.json', encoding='utf-8'))['buildings']
    out = []
    for b in d:
        t = b['t']
        if 'building' not in t or t.get('building') in ('no', 'construction', 'ruins', 'collapsed'):
            continue
        if len(b['p']) < 4:
            continue
        try:
            g = Polygon(b['p'])
            if not g.is_valid:
                g = g.buffer(0)
            if g.geom_type == 'MultiPolygon':
                g = max(g.geoms, key=lambda q: q.area)
        except Exception:
            continue
        if g.is_empty:
            continue
        out.append((g, {'id': b['id'], 't': t}))
    return out


def to_m(g):
    return Polygon([m(x, y) for x, y in g.exterior.coords])


def tile_xy(lon, lat, z):
    n = 2 ** z
    x = (lon + 180) / 360 * n
    s = math.sin(math.radians(lat))
    y = (0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi)) * n
    return x, y


def xy_ll(x, y, z):
    n = 2 ** z
    lon = x / n * 360 - 180
    lat = math.degrees(math.atan(math.sinh(math.pi * (1 - 2 * y / n))))
    return lon, lat


def fetch(z, x, y):
    p = f'{TILES}/{z}_{y}_{x}.jpg'
    if not os.path.exists(p) or os.path.getsize(p) < 1000:
        subprocess.run(['curl', '-sS', '-o', p,
                        f'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'], check=True)
    return Image.open(p).convert('RGB')


def mosaic(lon, lat, z=18, n=3):
    cx, cy = tile_xy(lon, lat, z)
    x0, y0 = int(cx) - n // 2, int(cy) - n // 2
    im = Image.new('RGB', (256 * n, 256 * n))
    for i in range(n):
        for j in range(n):
            im.paste(fetch(z, x0 + i, y0 + j), (256 * i, 256 * j))
    W, N = xy_ll(x0, y0, z)
    E, S = xy_ll(x0 + n, y0 + n, z)

    def px(lo, la):
        X, Y = tile_xy(lo, la, z)
        return ((X - x0) * 256, (Y - y0) * 256)
    return im, (W, S, E, N), px


def main():
    osm = osm_ll()
    ms = load_ll(F + '/ms_buildings.geojson')
    ov = load_ll(F + '/overture_buildings.geojson')
    ovms = [(g, p) for g, p in ov if p.get('src') == 'Microsoft ML Buildings']
    srcs = {'osm': osm, 'ms': ms, 'overture': ov}
    trees = {k: STRtree([g for g, _ in v]) for k, v in srcs.items()}
    stats = {}
    try:
        font = ImageFont.truetype('arial.ttf', 22)
    except Exception:
        font = ImageFont.load_default()
    for name, (lon, lat) in SPOTS.items():
        im, (W, S, E, N), px = mosaic(lon, lat, 18, 3)
        bb = sbox(W, S, E, N)
        km2 = (E - W) * MX * (N - S) * MY / 1e6
        st = {'box': [round(W, 5), round(S, 5), round(E, 5), round(N, 5)], 'km2': round(km2, 4)}
        sel = {}
        for k, v in srcs.items():
            idx = [i for i in trees[k].query(bb) if bb.contains(v[i][0].centroid)]
            sel[k] = [v[i] for i in idx]
            areas = [to_m(g).area for g, _ in sel[k]]
            st[k] = {'n': len(idx), 'per_km2': round(len(idx) / km2), 'cover': round(sum(areas) / (km2 * 1e6), 3),
                     'median_m2': round(float(np.median(areas)), 1) if areas else 0,
                     'n_lt_40m2': sum(1 for a in areas if a < 40), 'n_gt_1000m2': sum(1 for a in areas if a > 1000)}
        om = [to_m(g) for g, _ in sel['osm']]
        mm = [to_m(g) for g, _ in sel['ms']]
        ot = STRtree(om) if om else None
        mt = STRtree(mm) if mm else None
        offs, merged, ms_new = [], 0, 0
        for g in mm:
            hits = [om[i] for i in ot.query(g) if om[i].intersects(g)] if ot else []
            if not hits:
                ms_new += 1
                continue
            best = max(hits, key=lambda h: h.intersection(g).area)
            iou = best.intersection(g).area / max(1e-9, best.union(g).area)
            if iou > 0.3 and len(hits) <= 2:
                offs.append((best.centroid.x - g.centroid.x, best.centroid.y - g.centroid.y))
            if sum(1 for h in hits if h.intersection(g).area > 0.5 * h.area) >= 3:
                merged += 1
        osm_missed, split = 0, 0
        for g in om:
            cand = [mm[i] for i in mt.query(g)] if mt else []
            if not any(c.intersects(g) for c in cand):
                osm_missed += 1
            if sum(1 for c in cand if c.intersection(g).area > 0.5 * c.area) >= 3:
                split += 1
        st['ms_vs_osm'] = {'ms_not_in_osm': ms_new, 'osm_not_in_ms': osm_missed, 'ms_merging_3plus_osm': merged,
                           'osm_holding_3plus_ms': split, 'matched_pairs': len(offs),
                           'offset_osm_minus_ms_m': [round(float(np.median([o[0] for o in offs])), 2),
                                                     round(float(np.median([o[1] for o in offs])), 2)] if offs else None}
        el = 0
        for g in mm:
            xs = list(g.minimum_rotated_rectangle.exterior.coords)
            a, b = math.dist(xs[0], xs[1]), math.dist(xs[1], xs[2])
            L, Wd = max(a, b), min(a, b)
            if L > 25 and Wd > 8 and L / max(Wd, 1) > 2.0 and g.area > 300:
                el += 1
        st['ms_long_blocks'] = el
        stats[name] = st
        panels = []
        for lab, layers in (('Esri World Imagery', []), ('OSM', [('osm', (255, 220, 0))]),
                            ('Microsoft ML 2026-02', [('ms', (0, 230, 255))]),
                            ('MS cyan + OSM yellow', [('ms', (0, 230, 255)), ('osm', (255, 220, 0))])):
            p = im.copy()
            d = ImageDraw.Draw(p)
            for k, col in layers:
                for g, _ in sel[k]:
                    d.line([px(x, y) for x, y in g.exterior.coords], fill=col, width=2)
            d.rectangle([0, 0, 768, 34], fill=(0, 0, 0))
            cnt = '' if not layers else '  n=' + '/'.join(str(st[k]['n']) for k, _ in layers)
            d.text((8, 6), f'{name}: {lab}{cnt}', fill=(255, 255, 255), font=font)
            panels.append(p)
        sheet = Image.new('RGB', (768 * 2, 768 * 2))
        for i, p in enumerate(panels):
            sheet.paste(p, ((i % 2) * 768, (i // 2) * 768))
        sheet.save(f'{OUT}/{name}.jpg', quality=88)
        print(name, json.dumps(st))
    W, S, E, N = 96.095, 16.75, 96.235, 16.89
    km2 = (E - W) * MX * (N - S) * MY / 1e6
    whole = {'km2': round(km2, 1)}
    for k, v in list(srcs.items()) + [('overture_ms_part', ovms)]:
        inb = [g for g, _ in v if W <= g.centroid.x <= E and S <= g.centroid.y <= N]
        whole[k] = {'n': len(inb), 'per_km2': round(len(inb) / km2)}
    stats['_whole_box'] = whole
    print(json.dumps(whole))
    json.dump(stats, open(F + '/compare_stats.json', 'w'), indent=1)


main()
