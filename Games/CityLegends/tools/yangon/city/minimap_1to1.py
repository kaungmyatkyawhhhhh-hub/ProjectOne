"""The minimap picture tiles for the 1:1 map (redone 18 Nov 2026, owner: "redo the viewable map ... on the new yangon map").

d12_minimap's night look on the J37 roads05 network: ground, green areas (OSM parks / grass / wood), water with a light
edge (Inya Lake, Kandawgyi, the river and the creek), pagoda compounds, the building shells (soft shadow + light edge),
the roads with dark edges and pavements (main roads gold, streets light grey, minor streets darker), the roundabouts and
the flyover decks over everything. Districts the game holds (FULL) are drawn in colour; the rest of P1-P12 greyed.

Two sets of 1024 x 512 tiles:
  detail    SPP_DETAIL studs a pixel, only over the FULL districts (the minimap, loaded near you)
  overview  SPP_OVER studs a pixel, the whole P1-P12 box (the main menu / loading screen map, and the minimap's backdrop)

    YANGON_SCALE=1to1 python minimap_1to1.py build <roads05 tag>   -> imports/sync/minimap_1to1/{d,o}_<c>_<r>.png
    YANGON_SCALE=1to1 python minimap_1to1.py --lua ids.json        -> src/client/YangonMapArt.lua
"""
import json, math, os, sys

from PIL import Image, ImageDraw, ImageFilter, ImageOps
from shapely.affinity import translate
from shapely.geometry import LineString, Polygon, box as sbox
from shapely.ops import unary_union

sys.stdout.reconfigure(encoding='utf-8')
import geo
from roads05_clear import road_polys, shells

OUT = os.path.join(geo.ROOT, 'imports', 'sync', 'minimap_1to1')  # (imports/: the folder approved for Open Cloud uploads)
TW, TH = 1024, 512
SPP_DETAIL, SPP_OVER = 5.0, 16.0
SS = 2  # drawn at twice the size, then shrunk (smooth edges)
FULL = ('P1', 'P2', 'P3')  # in the game (roads built in Studio, 18 Nov)
ALL = ['P%d' % i for i in range(1, 13)]
MARGIN = 300.0

# Monaco's / d12's night palette
GROUND, WATER, WATER_EDGE = (34, 44, 42), (14, 36, 64), (30, 70, 108)
GREEN, GREEN_EDGE = (36, 60, 44), (44, 72, 52)
BUILDING, BUILDING_EDGE, SHADOW = (60, 68, 84), (92, 102, 122), (18, 22, 28)
SHRINE, SHRINE_EDGE = (96, 84, 60), (170, 146, 92)
PAVEMENT, EDGE = (64, 68, 80), (12, 14, 18)
GREY_WATER = (20, 34, 50)
STREET, MINOR, ROUTE = (156, 164, 180), (118, 126, 142), (222, 184, 98)
MAJOR_HW = ('trunk', 'primary', 'secondary', 'tertiary', 'trunk_link', 'primary_link', 'secondary_link', 'tertiary_link')
GREEN_TAGS = {('leisure', 'park'), ('leisure', 'garden'), ('leisure', 'golf_course'), ('leisure', 'pitch'), ('leisure', 'stadium'),
              ('landuse', 'grass'), ('landuse', 'forest'), ('landuse', 'recreation_ground'), ('landuse', 'cemetery'),
              ('landuse', 'village_green'), ('natural', 'wood'), ('natural', 'scrub'), ('natural', 'grassland'),
              ('natural', 'wetland'), ('landuse', 'meadow')}


def district_box(t):
    lo0, la0, lo1, la1 = geo.PILOT_LL[t]
    (x0, z0), (x1, z1) = geo.world(lo0, la1), geo.world(lo1, la0)
    return x0, z0, x1, z1


class Data:
    def __init__(self, tag):
        data = json.load(open(os.path.join(geo.BUILD, 'city_1to1', 'roads05_' + tag, 'roads.json'), encoding='utf-8'))
        self.data = data
        cw, pv = road_polys(data)
        road = {r['name']: r for r in data['roads']}

        def col(n):
            r = road.get(n)
            if r is None:  # a roundabout ring
                return ROUTE
            if r['kind'] in ('route', 'side'):
                return ROUTE
            return STREET if r.get('hw') in MAJOR_HW else MINOR

        def rank(n):
            r = road.get(n)
            return -(r['rank'] if r else 0)
        # streets first, the main roads over them (d12: low rank on top)
        self.cw = sorted([(rank(n), col(n), g) for n, g in cw], key=lambda q: (q[1] == ROUTE, q[1] == STREET, q[0]))
        self.pv = [g for _, g in pv]
        self.edge = [g.buffer(1.8, 4) for g in self.pv] + [g.buffer(1.8, 4) for _, _, g in self.cw]
        self.decks = data.get('decks', [])
        self.rings = data.get('roundabouts', [])
        self.water, self.green, self.shrine = [], [], []
        for a in geo.load('areas'):
            t = a.get('t', {})
            pts = [geo.world(lon, lat) for lon, lat in a['p']]
            if len(pts) < 3:
                continue
            if t.get('natural') == 'water' or t.get('water') or t.get('waterway') in ('riverbank', 'dock') or t.get('landuse') in ('basin', 'reservoir'):
                self.water.append(pts)
            elif any((k, t.get(k)) in GREEN_TAGS for k in ('leisure', 'landuse', 'natural')):
                self.green.append(pts)
            elif t.get('landuse') == 'religious' or (t.get('amenity') in ('place_of_worship', 'monastery') and t.get('religion', 'buddhist') == 'buddhist'):
                self.shrine.append(pts)
        self.shells = []
        for d in ALL:
            self.shells += [list(s.exterior.coords) for s in shells(d)]
        print('roads %d, pavements %d, water %d, green %d, shrines %d, shells %d' % (len(self.cw), len(self.pv), len(self.water), len(self.green), len(self.shrine), len(self.shells)))


def polys_of(g):
    for p in getattr(g, 'geoms', [g]):
        if p.geom_type == 'Polygon' and not p.is_empty:
            yield p


def render(D, spp, x0, z0, W, H):
    """Everything drawn in colour onto a W x H picture whose top-left is world (x0, z0)."""
    k = SS / spp
    px = lambda x, z: ((x - x0) * k, (z - z0) * k)
    view = sbox(x0 - 400, z0 - 400, x0 + W * spp + 400, z0 + H * spp + 400)
    inview = lambda pts: any(view.bounds[0] <= x <= view.bounds[2] and view.bounds[1] <= z <= view.bounds[3] for x, z in pts[::max(1, len(pts) // 16)]) or Polygon(pts).buffer(0).intersects(view)
    S = (W * SS, H * SS)
    im = Image.new('RGB', S, GROUND)
    d = ImageDraw.Draw(im)
    for pts in D.green:
        if inview(pts):
            d.polygon([px(*q) for q in pts], fill=GREEN, outline=GREEN_EDGE)
    for pts in D.shrine:
        if inview(pts):
            d.polygon([px(*q) for q in pts], fill=SHRINE, outline=SHRINE_EDGE)
    # water with a lighter edge band (d12)
    mask = Image.new('L', S, 0)
    md = ImageDraw.Draw(mask)
    for pts in D.water:
        if inview(pts):
            md.polygon([px(*q) for q in pts], fill=255)
    im.paste(Image.new('RGB', S, WATER_EDGE), (0, 0), mask)
    im.paste(Image.new('RGB', S, WATER), (0, 0), mask.filter(ImageFilter.MinFilter(5 if spp < 8 else 3)))
    d = ImageDraw.Draw(im)
    # buildings: a soft shadow, then the roof with a lighter edge (only where they show as more than a dot)
    shown = [pts for pts in D.shells if inview(pts)]
    if spp < 8:
        sh = Image.new('L', S, 0)
        sd = ImageDraw.Draw(sh)
        for pts in shown:
            sd.polygon([(a + 3, b + 4) for a, b in (px(*q) for q in pts)], fill=150)
        im.paste(Image.new('RGB', S, SHADOW), (0, 0), sh.filter(ImageFilter.GaussianBlur(3)))
        d = ImageDraw.Draw(im)
    for pts in shown:
        pp = [px(*q) for q in pts]
        d.polygon(pp, fill=BUILDING_EDGE if spp < 8 else BUILDING)
        if spp < 8:
            cx = sum(q[0] for q in pp[:-1]) / (len(pp) - 1)
            cy = sum(q[1] for q in pp[:-1]) / (len(pp) - 1)
            d.polygon([(cx + (a - cx) * 0.8, cy + (b - cy) * 0.8) for a, b in pp], fill=BUILDING)
    # roads: dark edge, pavement, carriageway
    for g in D.edge:
        if g.intersects(view):
            for p in polys_of(g):
                d.polygon([px(*q) for q in p.exterior.coords], fill=EDGE)
    for g in D.pv:
        if g.intersects(view):
            for p in polys_of(g):
                d.polygon([px(*q) for q in p.exterior.coords], fill=PAVEMENT)
    for _, c, g in D.cw:
        if g.intersects(view):
            for p in polys_of(g):
                d.polygon([px(*q) for q in p.exterior.coords], fill=c)
                for h in p.interiors:  # (a roundabout's middle)
                    d.polygon([px(*q) for q in h.coords], fill=GREEN)
    # flyover decks over everything: a shadow, an edge, the deck
    for deck in D.decks:
        s = deck['s']
        if len(s) < 2:
            continue
        half = max(max(q[6], q[7]) for q in s)
        line = LineString([(q[0], q[2]) for q in s])
        if not line.intersects(view):
            continue
        for off, grow, colr in (((6, 8), half + 4, SHADOW), ((0, 0), half + 3, EDGE), ((0, 0), half - 1.5, ROUTE)):
            g = translate(line, *off).buffer(grow, 8, cap_style=2)
            for p in polys_of(g):
                d.polygon([px(*q) for q in p.exterior.coords], fill=colr)
    return im, mask


def grey_of(im, water):
    """the districts not in the game: dim and colourless, the water still a dim blue"""
    g = ImageOps.grayscale(im).convert('RGB')
    g = Image.blend(Image.new('RGB', im.size, GROUND), g, 0.42)
    g.paste(Image.new('RGB', im.size, GREY_WATER), (0, 0), water)
    return g


def full_mask(spp, x0, z0, size, tags=FULL):
    m = Image.new('L', size, 0)
    md = ImageDraw.Draw(m)
    k = SS / spp
    for t in tags:
        bx0, bz0, bx1, bz1 = district_box(t)
        md.rectangle(((bx0 - x0) * k, (bz0 - z0) * k, (bx1 - x0) * k, (bz1 - z0) * k), fill=255)
    return m.filter(ImageFilter.GaussianBlur(6))


def tileset(D, name, spp, x0, z0, cols, rows, keep):
    """draws the grid in bands of rows (memory), saves the kept tiles; keep(c, r) says which"""
    ts = (TW * spp, TH * spp)
    kept = []
    r = 0
    while r < rows:
        band = [rr for rr in range(r, min(rows, r + 3)) if any(keep(c, rr) for c in range(cols))]
        if not band:
            r += 3
            continue
        r0, r1 = band[0], band[-1] + 1
        bz0 = z0 + r0 * ts[1]
        im, water = render(D, spp, x0, bz0, cols * TW, (r1 - r0) * TH)
        im = Image.composite(im, grey_of(im, water), full_mask(spp, x0, bz0, im.size))
        # (past P1-P12 the OSM cut leaves torn shapes: plain ground there)
        im = Image.composite(im, Image.new('RGB', im.size, GROUND), full_mask(spp, x0, bz0, im.size, ALL))
        im = im.resize((cols * TW, (r1 - r0) * TH), Image.LANCZOS)
        for rr in range(r0, r1):
            for c in range(cols):
                if not keep(c, rr):
                    continue
                t = im.crop((c * TW, (rr - r0) * TH, (c + 1) * TW, (rr - r0 + 1) * TH))
                if all(h - l <= 2 for l, h in t.getextrema()):
                    continue
                t.save(os.path.join(OUT, '%s_%d_%d.png' % (name, c, rr)))
                kept.append((c, rr))
        print(name, 'rows', r0, r1 - 1, 'done')
        r = r1
    return dict(x0=x0, z0=z0, spp=spp, cols=cols, rows=rows, tiles=kept)


def build(tag):
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        if f.endswith('.png'):
            os.remove(os.path.join(OUT, f))
    D = Data(tag)
    boxes = [district_box(t) for t in ALL]
    X0, Z0 = min(b[0] for b in boxes) - MARGIN, min(b[1] for b in boxes) - MARGIN
    X1, Z1 = max(b[2] for b in boxes) + MARGIN, max(b[3] for b in boxes) + MARGIN
    # detail: a grid over the FULL districts, only the tiles touching one
    fb = [district_box(t) for t in FULL]
    dx0, dz0 = math.floor(min(b[0] for b in fb) - MARGIN), math.floor(min(b[1] for b in fb) - MARGIN)
    dts = (TW * SPP_DETAIL, TH * SPP_DETAIL)
    dcols = math.ceil((max(b[2] for b in fb) + MARGIN - dx0) / dts[0])
    drows = math.ceil((max(b[3] for b in fb) + MARGIN - dz0) / dts[1])
    zone = unary_union([sbox(*b).buffer(MARGIN) for b in fb])
    dkeep = lambda c, r: sbox(dx0 + c * dts[0], dz0 + r * dts[1], dx0 + (c + 1) * dts[0], dz0 + (r + 1) * dts[1]).intersects(zone)
    det = tileset(D, 'd', SPP_DETAIL, dx0, dz0, dcols, drows, dkeep)
    ots = (TW * SPP_OVER, TH * SPP_OVER)
    ox0, oz0 = math.floor(X0), math.floor(Z0)
    ocols, orows = math.ceil((X1 - ox0) / ots[0]), math.ceil((Z1 - oz0) / ots[1])
    ov = tileset(D, 'o', SPP_OVER, ox0, oz0, ocols, orows, lambda c, r: True)
    # a small preview of the overview
    big = Image.new('RGB', (ocols * TW, orows * TH), GROUND)
    for c, r in ov['tiles']:
        big.paste(Image.open(os.path.join(OUT, 'o_%d_%d.png' % (c, r))), (c * TW, r * TH))
    big.resize((big.width // 3, big.height // 3), Image.LANCZOS).save(os.path.join(OUT, 'preview.png'))
    json.dump(dict(detail=det, overview=ov, map=[X0, Z0, X1, Z1], full=[district_box(t) for t in FULL]),
              open(os.path.join(OUT, 'layout.json'), 'w'))
    print('detail %d tiles, overview %d tiles' % (len(det['tiles']), len(ov['tiles'])))


def lua(ids_path):
    L = json.load(open(os.path.join(OUT, 'layout.json')))
    ids = json.load(open(ids_path))
    out = ['-- generated by tools/yangon/city/minimap_1to1.py: do not edit',
           "-- the 1:1 Yangon map as picture tiles (world studs): detail (the minimap, near you) over the overview (the whole",
           "-- P1-P12 box: the menu's world map, the loading screen, the minimap's backdrop); the rim and the arrow are MinimapArt's",
           'return {',
           '\tback = Color3.fromRGB(%d, %d, %d),' % GROUND,
           '\tmap = { x0 = %d, z0 = %d, x1 = %d, z1 = %d },' % tuple(L['map'])]
    for key, pre in (('detail', 'd'), ('overview', 'o')):
        s = L[key]
        out.append('\t%s = {' % key)
        out.append('\t\tx0 = %d, z0 = %d, tileStuds = Vector2.new(%d, %d), cols = %d, rows = %d,' % (s['x0'], s['z0'], TW * s['spp'], TH * s['spp'], s['cols'], s['rows']))
        out.append('\t\ttiles = {')
        for c, r in sorted(s['tiles']):
            out.append('\t\t\t{ col = %d, row = %d, image = "%s" },' % (c, r, ids['%s_%d_%d' % (pre, c, r)]))
        out += ['\t\t},', '\t},']
    out += ['}', '']
    open(os.path.join(geo.ROOT, 'src', 'client', 'YangonMapArt.lua'), 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
    print('wrote YangonMapArt.lua')


if __name__ == '__main__':
    assert geo.ONE_TO_ONE, 'run with YANGON_SCALE=1to1'
    if sys.argv[1] == '--lua':
        lua(sys.argv[2])
    else:
        build(sys.argv[2])
