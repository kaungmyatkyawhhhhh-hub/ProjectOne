"""Whole-Yangon map (14 Nov 2026): building plots at the REAL density, in the mesh kit's plot schema.

Owner: "the ingame yangon is too clean compared to real life yangon because in real life its compact".
Lesson (Lessons note, 14 Nov): real data is a floor, not the answer: OSM has only part of Yangon's buildings, so every block is
filled to the real density with buildings of the area's own type.

1. Every OSM building outline in the box (build/osm_ygn/buildings.json), simplified, clipped off the road corridors (the game's
   roads are wider than the real ones, so real buildings that touch them are cut back, not dropped), floors from the tags or an
   estimate, a Yangon style, wall and roof colours.
2. Infill on a 2-stud raster: free land = not road (game roads and the new streets with their pavements + 1), not water (+ 4),
   not a venue / house lot, not a park / pitch / cemetery / wood / pagoda ground, not the lake's shore strip, not an existing
   building (+ 3). City blocks = connected free land. Each block gets a target cover by its land use (residential / untagged 45%,
   commercial 60%, school 25%, university 15%, hospital 35%, military 12%, industrial 45%).
   a. Frontage rows: along every road side, wall-to-wall rows of shophouses (big roads and busy streets) or walk-ups / houses
      (quiet streets), 8-16 studs a unit, 22-30 deep, with gaps for lanes and gates.
   b. The interior: walk-up blocks, compound houses and sheds packed until the block's target is met.

Plot schema (tools/yangon/city/d24_bmesh.py reads it):
  {"id", "poly": [[x, z], ...] CCW from above, "floors", "style", "roof", "roof_colour", "wall_colour", "front", "shop",
   "name", "src": "osm"|"infill", "use": land use}

Run from Games/CityLegends/tools/yangon/city:  python plots.py 05   -> build/city/plots_05.json + a preview PNG
"""
import json, math, os, random, re as _re, sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
from shapely.geometry import LineString, Polygon, Point, box as sbox
from shapely.ops import unary_union
from shapely.strtree import STRtree
from shapely import affinity

import geo
from geo import load, proj, floors_from_tags

HERE = os.path.dirname(os.path.abspath(__file__))
RES = 2.0  # studs a raster cell
ROW_SETBACK = 2.5  # studs between the pavement and a frontage row

WALLS = [(226, 218, 196), (222, 222, 216), (226, 214, 170), (196, 214, 198), (220, 190, 172), (198, 208, 214),
         (176, 176, 170), (204, 182, 140), (214, 204, 186), (222, 200, 198), (232, 228, 214), (178, 192, 172)]
WALL_W = [10, 12, 6, 5, 4, 4, 6, 3, 8, 2, 8, 2]
ROOF_METAL = [(150, 72, 52), (168, 62, 46), (146, 148, 150), (112, 122, 136), (124, 96, 70), (96, 104, 92)]
ROOF_FLAT = (166, 160, 150)

TARGET = {'lakeside': 0.16, 'residential': 0.45, 'untagged': 0.40, 'commercial': 0.60, 'retail': 0.60, 'industrial': 0.45, 'school': 0.25,
          'college': 0.2, 'university': 0.15, 'hospital': 0.35, 'military': 0.12, 'construction': 0.30, 'religious': 0.15,
          'place_of_worship': 0.10, 'government': 0.30, 'railway': 0.10}
GREEN_USES = {'park', 'pitch', 'garden', 'golf_course', 'cemetery', 'grave_yard', 'forest', 'wood', 'grass', 'recreation_ground',
              'playground', 'sports_centre', 'stadium', 'swimming_pool', 'parking', 'farmland', 'meadow', 'scrub', 'wetland',
              'water', 'reservoir', 'basin', 'nature_reserve', 'zoo', 'theme_park'}


# Named buildings whose OSM tags miss or understate the real building (checked against photos / the operators' own
# descriptions; 14 Nov 2026). name regex -> (floors, style). Grown batch by batch.
OVERRIDES = [
    (r'lotte hotel', 23, 'tower'),
    (r'hledan cent', 9, 'mass'),
    (r'junction square$', 4, 'hall'),
    # batch 2, downtown (15 Nov 2026): the colonial landmarks without a model of their own (landmarks.json facts), as
    # buildings on their real outlines with their real floors and colours. Optional 4th item: wall / roof colour, roof.
    (r'^the strand hotel$', 3, 'mass', {'wall': (236, 228, 206)}),
    (r"ministers' building|secretariat", 3, 'mass', {'wall': (170, 78, 56)}),
    (r'^high court$', 3, 'mass', {'wall': (176, 84, 62)}),
    (r'^customs house$', 4, 'mass', {'wall': (168, 82, 64)}),
    (r'yangon central railway station', 3, 'hall', {'wall': (230, 214, 170), 'roof': 'gable', 'roof_colour': (150, 60, 46)}),
    (r'lokanat', 3, 'mass', {'wall': (232, 222, 196)}),
    (r'yangon central post office', 4, 'mass', {'wall': (226, 210, 176)}),
    (r'myanma port authority$|^myanmar port authority$', 4, 'mass', {'wall': (230, 222, 200)}),
    (r'holy trinity cathedral|saint mary.s cathedral|st\.? mary.s cathedral', 3, 'hall',
     {'wall': (172, 80, 60), 'roof': 'gable', 'roof_colour': (110, 70, 60)}),
    (r'^junction city$', 7, 'mass', {'wall': (214, 208, 196)}),
    (r'^sakura tower$', 20, 'tower', None),
    (r'sule shangri', 22, 'tower', None),
    (r'^sule square$', 22, 'tower', None),
]


def override(name):
    if not name:
        return None
    for ov in OVERRIDES:
        if _re.search(ov[0], name, _re.I):
            return ov[1], ov[2]
    return None


def override_look(name):
    """the optional colours / roof of an override (or None)"""
    if not name:
        return None
    for ov in OVERRIDES:
        if _re.search(ov[0], name, _re.I):
            return ov[3] if len(ov) > 3 else None
    return None


# landmarks.json id -> the model tools/yangon/city/landmarks.py builds (build/landmarks/<model>.json). Only these grounds
# are kept free of generic buildings; a landmark with no model yet (Bogyoke Market, the Strand, the Secretariat, the
# station, the towers) is built from its real OSM outlines with the OVERRIDES above, so downtown has no empty holes.
LANDMARK_MODEL = {'shwedagon': 'shw', 'sule': 'sule', 'city_hall': 'ch', 'independence_monument': 'indep',
                  'botataung': 'bota', 'karaweik': 'kara', 'chaukhtatgyi': 'chauk', 'kaba_aye': 'kaba',
                  'maha_wizaya': 'wiz'}
LANDMARK_GROUND_KINDS = {'pagoda', 'pagoda_roundabout', 'zoo', 'park'}
# Bogyoke Aung San Market (1926): long two-storey colonial market halls, ochre and cream walls, red and green pitched
# roofs (landmarks.json facts); every plot inside its OSM marketplace ground gets that look.
# towers standing on a podium whose OSM outline is the whole complex: name regex -> [(floors, width, depth, where along the
# podium's long axis -1..1, name)]. Junction City (2017): a 25-floor office tower and the 23-floor Pan Pacific Yangon on a
# 7-floor mall (landmarks.json facts).
PODIUM_TOWERS = {r'^junction city$': [(25, 64, 52, -0.62, 'Junction City Tower'), (23, 70, 46, 0.62, 'Pan Pacific Yangon')]}
MARKET_LOOK = {'name_re': r'bogyoke aung san market', 'floors': 2, 'style': 'hall', 'roof': 'gable',
               'walls': [(226, 196, 120), (232, 222, 196), (220, 186, 112)], 'roofs': [(150, 62, 46), (70, 110, 80)]}


def podium_towers(allp):
    """towers on a podium (OSM has one outline for the whole complex, PODIUM_TOWERS): each tower is cut out of the podium's
    street-side edge as its own plot (a notch, never a hole: the plot schema has no holes). Returns the towers added."""
    extra = []
    for pl in allp:
        spec = next((v for k, v in PODIUM_TOWERS.items() if _re.search(k, pl.get('name') or '', _re.I)), None)
        if not spec or any(q['id'].startswith(pl['id'] + 't') for q in allp):
            continue
        g = Polygon(pl['poly']).buffer(0)
        mrr = list(g.minimum_rotated_rectangle.exterior.coords)[:4]
        e0 = (mrr[1][0] - mrr[0][0], mrr[1][1] - mrr[0][1])
        e1 = (mrr[2][0] - mrr[1][0], mrr[2][1] - mrr[1][1])
        ax, cross = (e0, e1) if math.hypot(*e0) >= math.hypot(*e1) else (e1, e0)
        L, W = math.hypot(*ax), math.hypot(*cross)
        ux, uz = ax[0] / L, ax[1] / L
        px, pz = -uz, ux
        c = g.centroid
        cuts = []
        for k, (fl, w, dep, at, name) in enumerate(spec):
            off = W / 2 - dep / 2 + 3  # (pushed out past the street-side edge, so the cut is a notch)
            tx, tz = c.x + ux * at * L / 2 + px * off, c.y + uz * at * L / 2 + pz * off
            tp = Polygon(rect_poly(tx, tz, px, pz, w, dep)).intersection(g)
            if tp.geom_type != 'Polygon' or tp.area < 0.5 * w * dep:
                continue
            cuts.append(tp)
            pts = ccw(list(tp.exterior.coords)[:-1])
            extra.append(dict(pl, id=f"{pl['id']}t{k}", poly=[[round(x, 2), round(z, 2)] for x, z in pts], floors=fl,
                              style='tower', roof='flat', front=None, shop=False, name=name, wall_colour=[196, 206, 214]))
        if cuts:
            rest = g.difference(unary_union(cuts).buffer(1.0))
            if rest.geom_type != 'Polygon':
                rest = max(rest.geoms, key=lambda t: t.area)
            if len(rest.interiors):
                raise ValueError('podium towers left a hole in ' + pl['id'])
            pl['poly'] = [[round(x, 2), round(z, 2)] for x, z in ccw(list(rest.simplify(0.4).exterior.coords)[:-1])]
            pl['front'] = None
    allp += extra
    return len(extra)


def landmark_models(tag):
    """footprints of this batch's landmark MODELS (build/landmarks/<model>.json: every mesh's box and the pads), grown 6"""
    lms = json.load(open(os.path.join(HERE, 'landmarks.json'), encoding='utf-8'))['landmarks']
    out = []
    for l in lms:
        mid = LANDMARK_MODEL.get(l['id'])
        if l.get('batch') != tag or not mid:
            continue
        path = os.path.join(geo.BUILD, 'landmarks', f'{mid}.json')
        if not os.path.exists(path):
            continue
        d = json.load(open(path, encoding='utf-8'))
        meshes = d['meshes']
        if isinstance(meshes, str):
            import ast
            meshes = ast.literal_eval(meshes)
        for m in meshes:
            (cx, _, cz), (sx, _, sz) = m['centre'], m['size']
            if sx * sz > 2.5e5:  # (a hill / ground mesh: its pads say where the buildings are)
                continue
            out.append(sbox(cx - sx / 2, cz - sz / 2, cx + sx / 2, cz + sz / 2))
        for row in (d.get('pads') or '').split('|'):
            pts = row.split(' ')[-1] if row.strip() else ''
            try:
                q = [tuple(float(v) for v in s.split(',')) for s in pts.split(';') if ',' in s]
                if len(q) >= 3:
                    out.append(Polygon(q).buffer(0))
            except ValueError:
                pass
    return unary_union(out).buffer(6) if out else Polygon()


def rng_for(*k):
    return random.Random(hash(k) & 0xffffffff)


def pick(r, items, weights=None):
    return r.choices(items, weights=weights, k=1)[0]


def ccw(coords):
    p = Polygon(coords)
    if not p.exterior.is_ccw:
        coords = list(reversed(coords))
    return coords


def rect_poly(cx, cz, ux, uz, w, d):
    """A rectangle centred at (cx, cz), front direction (ux, uz) (towards the road), width w along the road, depth d."""
    ax, az = -uz, ux
    hw, hd = w / 2, d / 2
    return [(cx + ax * a * hw + ux * b * hd, cz + az * a * hw + uz * b * hd) for a, b in ((-1, 1), (1, 1), (1, -1), (-1, -1))]


class Raster:
    def __init__(self, box):
        self.x0, self.z0 = box[0], box[1]
        self.nx = int(math.ceil((box[2] - box[0]) / RES))
        self.nz = int(math.ceil((box[3] - box[1]) / RES))

    def img(self):
        return Image.new('L', (self.nx, self.nz), 0)

    def px(self, pts):
        return [((x - self.x0) / RES, (z - self.z0) / RES) for x, z in pts]

    def draw_geom(self, im, g, val=255):
        # (each polygon is drawn on its own mask first: a hole must not erase what earlier layers drew there)
        geoms = [g] if g.geom_type == 'Polygon' else list(getattr(g, 'geoms', []))
        for p in geoms:
            if p.geom_type != 'Polygon' or p.is_empty:
                continue
            ext = self.px(p.exterior.coords)
            i0 = max(0, int(min(q[0] for q in ext)) - 1)
            j0 = max(0, int(min(q[1] for q in ext)) - 1)
            i1 = min(im.size[0], int(max(q[0] for q in ext)) + 2)
            j1 = min(im.size[1], int(max(q[1] for q in ext)) + 2)
            if i1 <= i0 or j1 <= j0:
                continue
            mask = Image.new('L', (i1 - i0, j1 - j0), 0)
            d = ImageDraw.Draw(mask)
            d.polygon([(x - i0, y - j0) for x, y in ext], fill=255)
            for h in p.interiors:
                d.polygon([(x - i0, y - j0) for x, y in self.px(h.coords)], fill=0)
            im.paste(val, (i0, j0, i1, j1), mask)

    def cells(self, poly):
        """raster rows / cols covered by a small polygon (for the free test)"""
        xs = [p[0] for p in poly]
        zs = [p[1] for p in poly]
        i0 = max(0, int((min(xs) - self.x0) / RES))
        i1 = min(self.nx - 1, int((max(xs) - self.x0) / RES))
        j0 = max(0, int((min(zs) - self.z0) / RES))
        j1 = min(self.nz - 1, int((max(zs) - self.z0) / RES))
        return i0, i1, j0, j1


def landuse_polys(box):
    out = []
    bb = sbox(*box)
    for a in load('areas'):
        t = a['t']
        use = None
        for k in ('landuse', 'leisure', 'amenity', 'natural', 'military', 'aeroway', 'tourism'):
            if k in t:
                use = t[k]
                break
        if use is None:
            continue
        try:
            p = Polygon(proj(a['p']), [proj(h) for h in a.get('h', [])])
        except Exception:
            continue
        if not p.is_valid:
            p = p.buffer(0)
        if p.is_empty or not p.intersects(bb):
            continue
        out.append((use, p, t))
    return out


def water_polys(box):
    bb = sbox(box[0] - 300, box[1] - 300, box[2] + 300, box[3] + 300)
    polys = []
    for a in load('areas'):
        t = a['t']
        if t.get('natural') == 'water' or t.get('waterway') in ('riverbank',) or t.get('landuse') in ('reservoir', 'basin'):
            rings = [a['p']] + a.get('more', [])
            for rg in rings:
                try:
                    p = Polygon(proj(rg))
                except Exception:
                    continue
                if not p.is_valid:
                    p = p.buffer(0)
                if p.intersects(bb):
                    polys.append(p)
    return unary_union(polys) if polys else Polygon()


def blocked_polys():
    """the venue sites, house lots and Racing Hub (as d19), the step 8 landmarks: their rectangles grown 10"""
    import re
    sites = [
        (30836.8, 957.4, -0.560, -0.829, 216, 216), (31025.7, 646.7, -0.990, -0.144, 216, 216), (31125.7, 960.7, 0.326, 0.945, 216, 216),
        (31074.1, 394.2, -0.991, -0.136, 216, 216), (32358.8, -1833.6, 0.992, 0.127, 216, 216), (30742.3, 223.9, 0.969, -0.249, 216, 216),
        (30730.5, 552.9, 0.987, 0.159, 304, 216), (29745.3, 1089.0, 0, 1, 216, 216), (30655.1, 1303.2, 0, -1, 216, 216),
        (30911.0, 1306.4, 0, -1, 216, 216), (29867.2, 1398.6, 0, -1, 216, 216), (30465.2, 921.7, 0.560, 0.829, 80, 80),
        (31424.3, 1181.3, -0.327, -0.945, 216, 216),
    ]
    wsrc = open(os.path.join(geo.ROOT, 'src', 'shared', 'YangonWorld.lua'), encoding='utf-8').read()
    for m in re.finditer(r'x = ([-\d.]+), y = [-\d.]+, z = ([-\d.]+), fx = ([-\d.]+), fz = ([-\d.]+), w = (\d+), d = (\d+)', wsrc):
        sites.append(tuple(float(v) for v in m.groups()))
    m = re.search(r'site = \{ x = ([-\d.]+), z = ([-\d.]+), fx = ([-\d.]+), fz = ([-\d.]+)', wsrc)
    sites.append((float(m.group(1)), float(m.group(2)), float(m.group(3)), float(m.group(4)), 216, 216))
    polys = []
    for x, z, fx, fz, w, d in sites:
        polys.append(Polygon(rect_poly(x, z, fx, fz, w + 20, d + 20)))
    old = json.load(open(os.path.join(geo.MAP, 'ygn_plots.json'), encoding='utf-8'))['plots']
    lms = []
    for p in old:
        if p.get('landmark'):
            poly = Polygon(rect_poly(p['x'], p['z'], p['fx'], p['fz'], p['w'] + 16, p['d'] + 16))
            polys.append(poly)
            lms.append(p)
    return unary_union(polys), lms


def road_geoms(game_roads, streets):
    """carriageway+pavement polygons of every road (game + new), and centre segments for facing"""
    polys, segs = [], []
    for r in game_roads['roads']:
        cs = set(game_roads.get('cut', {}).get(r['name'], []))
        walk = r.get('walkL') or 10.0
        run = []
        for k, s in enumerate(r['s'] + [None]):
            if s is None or k in cs:
                if len(run) > 1:
                    ls = LineString([(q[0], q[2]) for q in run])
                    half = max(max(q[6], q[7]) for q in run)
                    polys.append(ls.buffer(half + walk + 1.0, cap_style=1))
                    segs.append((ls, half + walk, r.get('kind'), r['name']))
                run = []
                continue
            run.append(s)
    for d in game_roads.get('decks', []):
        ls = LineString([(q[0], q[2]) for q in d['s']])
        polys.append(ls.buffer(36, cap_style=2))
    for s in streets:
        ls = LineString(s['pts'])
        polys.append(ls.buffer(s['half'] + s['walk'] + 1.0, cap_style=1))
        segs.append((ls, s['half'] + s['walk'], s['cls'], s['name']))
    return unary_union(polys), segs


import re as _re
HALL_WORDS = _re.compile(r'court|stadium|gymnasium|gym|arena|indoor|sports? (hall|centre|center|complex)|market|cinema|theat(re|er)|'
                         r'warehouse|factory|hangar|workshop|auditorium|convention|exhibition', _re.I)
PAGODA_WORDS = _re.compile(r'pagoda|zedi|ceti|cetiya|stupa|paya|phaya', _re.I)


def kind_for(t):
    """the real kind of a named / tagged building, for its look and its sign (owner: "wheres the fusan basketball court")"""
    name = (t.get('name:en') or '') + ' ' + (t.get('name') or '')
    b = t.get('building', 'yes')
    if b in ('pagoda', 'stupa') or (t.get('religion') == 'buddhist' and PAGODA_WORDS.search(name)) or PAGODA_WORDS.search(name):
        return 'pagoda'
    if b in ('monastery',) or 'monastery' in name.lower() or 'kyaung' in name.lower():
        return 'monastery'
    if b in ('church', 'cathedral', 'chapel') or t.get('religion') == 'christian':
        return 'church'
    if b == 'mosque' or t.get('religion') == 'muslim':
        return 'mosque'
    if b in ('temple',) or t.get('religion') == 'hindu':
        return 'temple'
    if HALL_WORDS.search(name) or b in ('sports_hall', 'sports_centre', 'stadium', 'grandstand', 'warehouse', 'industrial',
                                        'factory', 'hangar', 'retail', 'supermarket', 'market'):
        return 'hall'
    if b in ('school', 'university', 'college', 'kindergarten') or t.get('amenity') in ('school', 'university', 'college'):
        return 'school'
    if b in ('hospital', 'clinic') or t.get('amenity') in ('hospital', 'clinic'):
        return 'hospital'
    if b == 'hotel' or t.get('tourism') == 'hotel':
        return 'hotel'
    if b in ('office', 'commercial') or t.get('office'):
        return 'office'
    return None


def batch_road_geoms(tag):
    """batches 1-3: every road roads.py built (build/city/roads_<tag>_profile.json: pts [x, surface y, z, ground y],
    half [left, right], walk), as carriageway+pavement polygons and centre segments"""
    prof = json.load(open(os.path.join(geo.BUILD, 'city', f'roads_{tag}_profile.json'), encoding='utf-8'))
    polys, segs = [], []
    for r in prof:
        pts = [(q[0], q[2]) for q in r['pts']]
        if len(pts) < 2:
            continue
        ls = LineString(pts)
        half = max(r['half']) if isinstance(r['half'], list) else r['half']
        edge = half + (r.get('walk') or 0)
        polys.append(ls.buffer(edge + 1.0, cap_style=1))
        kind = 'big' if half >= 20 else 'street'
        segs.append((ls, edge, kind, r.get('name')))
    return unary_union(polys), segs


def landmark_areas(tag):
    """the OSM grounds of this batch's landmarks (tools/yangon/city/landmarks.json): no generic buildings or infill there"""
    lms = json.load(open(os.path.join(HERE, 'landmarks.json'), encoding='utf-8'))['landmarks']
    names = [l['name'].lower() for l in lms if l.get('batch') == tag and (l['id'] in LANDMARK_MODEL or l.get('kind') in LANDMARK_GROUND_KINDS)]
    out = []
    for a in load('areas'):
        nm = ((a['t'].get('name:en') or '') + ' ' + (a['t'].get('name') or '')).lower()
        if any(n in nm for n in names):
            try:
                pg = Polygon(proj(a['p']))
            except Exception:
                continue
            if not pg.is_valid:
                pg = pg.buffer(0)
            if pg.area > 400:
                out.append(pg.buffer(8))
    return unary_union(out) if out else Polygon()


def style_for(t, area_m2, floors, circ, near_big):
    k = kind_for(t)
    if k == 'hall':
        return 'hall'
    b = t.get('building', 'yes')
    if b in ('shed', 'garage', 'garages', 'hut', 'roof', 'carport', 'kiosk', 'cabin'):
        return 'shed'
    if circ > 0.88 and area_m2 > 250:
        return 'round'
    if floors >= 12:
        return 'tower'
    if b in ('house', 'detached', 'bungalow', 'semidetached_house'):
        return 'villa' if area_m2 > 220 else 'house'
    if b in ('industrial', 'warehouse', 'hangar', 'factory'):
        return 'hall'
    if area_m2 > 2200 and floors <= 4:
        return 'hall'
    if floors <= 2 and area_m2 < 220:
        return 'house'
    if floors <= 5 and near_big and area_m2 < 600:
        return 'shophouse'
    if 3 <= floors <= 9:
        return 'walkup'
    return 'mass'


def roof_for(style, r):
    if style in ('house', 'villa', 'shed'):
        return pick(r, ['gable', 'hip', 'shed'], [5, 3, 2]), pick(r, ROOF_METAL)
    if style == 'hall':
        return pick(r, ['gable', 'flat'], [6, 4]), pick(r, ROOF_METAL + [ROOF_FLAT])
    return 'flat', ROOF_FLAT


def front_edge(coords, segs_tree, segs):
    """index of the polygon edge whose middle is nearest a road, and the distance"""
    best, bi = 1e9, None
    n = len(coords)
    for i in range(n):
        a, b = coords[i], coords[(i + 1) % n]
        if math.hypot(b[0] - a[0], b[1] - a[1]) < 3:
            continue
        m = Point((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
        for j in segs_tree.query(m.buffer(80)):
            ls, edge = segs[j][0], segs[j][1]
            dd = ls.distance(m) - edge
            if dd < best:
                best, bi = dd, i
    return bi, best


def build(tag, box):
    t0 = __import__('time').time()
    if tag == '05':
        game_roads = json.load(open(os.path.join(geo.MAP, 'ygn_roads_v5.json'), encoding='utf-8'))
        net = json.load(open(os.path.join(geo.BUILD, 'city', f'network_{tag}.json'), encoding='utf-8'))
        streets = net['new']
        roads_poly, segs = road_geoms(game_roads, streets)
        blocked, landmarks = blocked_polys()
        region = sbox(*box)
    else:
        # (batches 1-3: the batch's outline minus the built 0.5 box; the batch's own roads; the landmark grounds)
        roads_poly, segs = batch_road_geoms(tag)
        region = geo.batch_poly(tag).difference(sbox(*geo.BOX_05))
        landmarks = []
        lm_models = landmark_models(tag)
        blocked = unary_union([sbox(*box).buffer(400).difference(region), landmark_areas(tag), lm_models])
    segs_tree = STRtree([s[0] for s in segs])
    water = water_polys(box)
    lm_polys = [Polygon(rect_poly(p['x'], p['z'], p['fx'], p['fz'], p['w'] + 16, p['d'] + 16)) for p in landmarks]
    if tag != '05' and not lm_models.is_empty:
        # (a landmark model stands there: an OSM building over a sixth of it under the model goes, e.g. City Hall's own outline)
        lm_polys += list(lm_models.geoms) if hasattr(lm_models, 'geoms') else [lm_models]
    # (the step 8 landmark models with real names: never a second copy from the OSM outline)
    LM_NAME = {'novotel': 'novotel', 'mmplaza': 'myanmar plaza', 'optima': 'optima'}
    lm_names = [(LM_NAME.get(p.get('landmark'), '?'), p['x'], p['z']) for p in landmarks]
    uses = landuse_polys(box)
    bb = region
    print('inputs ready', round(__import__('time').time() - t0), 's')

    # ---------------------------------------------------------------- 1. the OSM buildings
    plots = []
    keep_out = unary_union([roads_poly, water.buffer(3), blocked])
    ko_tree = STRtree([keep_out]) if False else None
    n_drop = {'small': 0, 'road': 0, 'outside': 0, 'part': 0}
    for b in load('buildings'):
        t = b['t']
        if 'building:part' in t and 'building' not in t:
            n_drop['part'] += 1
            continue
        if t.get('building') in ('no', 'construction', 'ruins', 'collapsed'):
            continue
        pts = proj(b['p'])
        if len(pts) < 4:
            continue
        try:
            p = Polygon(pts)
        except Exception:
            continue
        if not p.is_valid:
            p = p.buffer(0)
            if p.geom_type != 'Polygon':
                continue
        if not bb.contains(p.centroid):
            n_drop['outside'] += 1
            continue
        nm = (t.get('name:en') or t.get('name') or '').lower()
        if any(p.intersection(lm).area > 0.15 * p.area for lm in lm_polys) or                 any(k in nm and p.centroid.distance(Point(x, z)) < 260 for k, x, z in lm_names):
            n_drop['landmark'] = n_drop.get('landmark', 0) + 1
            continue
        area_m2 = p.area / (geo.SPM * geo.SPM)
        if area_m2 < 12:
            n_drop['small'] += 1
            continue
        if p.intersects(keep_out):
            q = p.difference(keep_out)
            if q.is_empty:
                n_drop['road'] += 1
                continue
            if q.geom_type != 'Polygon':
                q = max(q.geoms, key=lambda g: g.area) if hasattr(q, 'geoms') else None
                if q is None or q.geom_type != 'Polygon':
                    n_drop['road'] += 1
                    continue
            if q.area < 0.35 * p.area or q.area < 40:
                n_drop['road'] += 1
                continue
            p = q
        p = p.simplify(0.6, preserve_topology=True)
        if p.geom_type != 'Polygon' or p.is_empty:
            continue
        coords = ccw(list(p.exterior.coords)[:-1])
        if len(coords) < 3:
            continue
        r = rng_for('osm', b['id'])
        fl = floors_from_tags(t)
        if fl is None:
            fl = est_floors(t, area_m2, r)
        circ = 4 * math.pi * p.area / (p.length ** 2) if p.length > 0 else 0
        fi, fd = front_edge(coords, segs_tree, segs)
        near_big = fd < 14
        style = style_for(t, area_m2, fl, circ, near_big)
        ov = override(t.get('name:en') or t.get('name'))
        if ov:
            fl, style = ov
        kind = kind_for(t)
        if kind == 'hall' and not floors_from_tags(t):
            fl = 2 if area_m2 > 300 else 1
        roof, rc = roof_for(style, r)
        if kind == 'hall' and HALL_WORDS.search((t.get('name:en') or '') + ' ' + (t.get('name') or '')):
            roof, rc = 'gable', (146, 148, 150)
        wc = pick(r, WALLS, WALL_W)
        look = override_look(t.get('name:en') or t.get('name'))
        if look:
            wc = look.get('wall', wc)
            roof = look.get('roof', roof)
            rc = look.get('roof_colour', rc)
        plots.append({'id': f"o{b['id']}", 'poly': [[round(x, 2), round(z, 2)] for x, z in coords], 'floors': int(fl),
                      'style': style, 'roof': roof, 'roof_colour': list(rc), 'wall_colour': list(wc),
                      'front': fi if fd < 30 else None, 'shop': bool(style == 'shophouse' or (near_big and fl <= 6 and r.random() < 0.6)),
                      'name': t.get('name:en') or t.get('name'), 'src': 'osm', 'use': None, 'kind': kind,
                      'sign': bool(t.get('name:en') or t.get('name'))})
    print('osm plots', len(plots), n_drop, round(__import__('time').time() - t0), 's')

    # ---------------------------------------------------------------- 2. the raster of free land
    R = Raster(box)
    occ = R.img()
    rbox = sbox(*box).buffer(50)
    R.draw_geom(occ, roads_poly.intersection(rbox))
    R.draw_geom(occ, water.buffer(4).intersection(rbox))
    R.draw_geom(occ, blocked.intersection(rbox))
    green = R.img()
    use_img = Image.new('L', (R.nx, R.nz), 0)
    use_codes = {'untagged': 0}
    for use, p, t in uses:
        if use in GREEN_USES or t.get('leisure') in GREEN_USES or t.get('amenity') in ('place_of_worship', 'grave_yard', 'parking'):
            R.draw_geom(green, p.intersection(bb))
        elif use in TARGET:
            code = use_codes.setdefault(use, len(use_codes))
            R.draw_geom(use_img, p.intersection(bb), code)
    # Inya Lake's shore and peninsulas are villa compounds in big gardens (Google Earth): land within 260 studs of the big water
    lake_code = use_codes.setdefault('lakeside', len(use_codes))
    if tag == '05':
        big_water = max(list(water.geoms) if hasattr(water, 'geoms') else [water], key=lambda g: g.area)
        R.draw_geom(use_img, big_water.buffer(260).difference(big_water).intersection(bb), lake_code)
    for use, p, t in uses:
        if use in TARGET and use != 'residential' and use in use_codes:
            R.draw_geom(use_img, p.intersection(bb), use_codes[use])
    # the lake's shore strip stays green (embankment, walk, trees): 40 studs from the big water
    R.draw_geom(green, water.buffer(44).difference(water).intersection(bb))
    bld = R.img()
    d = ImageDraw.Draw(bld)
    for pl in plots:
        d.polygon(R.px(pl['poly']), fill=255)
    occ_a = np.array(occ) > 0
    green_a = np.array(green) > 0
    bld_a = np.array(bld) > 0
    bld_grow = ndimage.binary_dilation(bld_a, iterations=2)
    land = ~occ_a
    blocks, nblocks = ndimage.label(land)
    print('blocks', nblocks, round(__import__('time').time() - t0), 's')
    use_a = np.array(use_img)
    inv = {v: k for k, v in use_codes.items()}
    # per block: land cells (not green), built cells, majority use
    lab = blocks.ravel()
    buildable = (land & ~green_a).ravel()
    land_n = np.bincount(lab, weights=buildable, minlength=nblocks + 1)
    built_n = np.bincount(lab, weights=(bld_a.ravel() & buildable), minlength=nblocks + 1)
    use_major = {}
    for code in range(len(use_codes)):
        cnt = np.bincount(lab, weights=(use_a.ravel() == code) & buildable, minlength=nblocks + 1)
        for bi in np.nonzero(cnt)[0]:
            if cnt[bi] > use_major.get(bi, (0, 0))[0]:
                use_major[bi] = (cnt[bi], code)
    free = land & ~green_a & ~bld_grow
    target_cells = {}
    for bi in range(1, nblocks + 1):
        if land_n[bi] < 30:
            continue
        use = inv.get(use_major.get(bi, (0, 0))[1], 'untagged')
        tgt = TARGET.get(use, 0.45)
        if tag == '2' and use in ('untagged', 'residential', 'commercial', 'retail'):
            tgt = 0.72  # (downtown Yangon: 70-85% built, continuous 4-7 floor shophouse blocks)
        need = tgt * land_n[bi] - built_n[bi]
        if need > 20:
            target_cells[bi] = [need, use]

    def try_place(poly, bi_expect=None):
        i0, i1, j0, j1 = R.cells(poly)
        if i1 <= i0 or j1 <= j0:
            return False
        sub = np.zeros((j1 - j0 + 1, i1 - i0 + 1), dtype=bool)
        im = Image.new('L', (i1 - i0 + 1, j1 - j0 + 1), 0)
        ImageDraw.Draw(im).polygon([((x - R.x0) / RES - i0, (z - R.z0) / RES - j0) for x, z in poly], fill=255)
        sub = np.array(im) > 0
        win = free[j0:j1 + 1, i0:i1 + 1]
        if sub.sum() < 4 or not np.all(win[sub]):
            return False
        if bi_expect is not None:
            bw = blocks[j0:j1 + 1, i0:i1 + 1][sub]
            if np.any(bw != bi_expect):
                return False
        # mark it (and a 1-cell margin) as taken
        grown = ndimage.binary_dilation(sub, iterations=1)
        free[j0:j1 + 1, i0:i1 + 1] &= ~grown
        return int(sub.sum())

    def block_at(x, z):
        i = int((x - R.x0) / RES)
        j = int((z - R.z0) / RES)
        if 0 <= i < R.nx and 0 <= j < R.nz:
            return int(blocks[j, i])
        return 0

    infill = []

    def add(poly, style, floors, front, shop, use, r, kind):
        roof, rc = roof_for(style, r)
        if not Polygon(poly).exterior.is_ccw:
            n = len(poly)
            poly = list(reversed(poly))
            if front is not None:
                front = (n - 2 - front) % n  # (edge i -> i+1 runs backwards as edge n-2-i)
        infill.append({'id': f'i{len(infill)}', 'poly': [[round(x, 2), round(z, 2)] for x, z in poly], 'floors': int(floors),
                       'style': style, 'roof': roof, 'roof_colour': list(rc), 'wall_colour': list(pick(r, WALLS, WALL_W)),
                       'front': front, 'shop': bool(shop), 'name': None, 'src': 'infill', 'use': use, 'kind': kind})

    # ---------------------------------------------------------------- 3a. frontage rows along every road side
    for si, (ls, edge, kind, name) in enumerate(segs):
        busy = kind in ('route', 'big')
        L = ls.length
        for side in (1, -1):
            r = rng_for('row', si, side)
            t = 0.0
            while t < L - 4:
                if r.random() < 0.08:  # a gap: a lane, a gate, a little yard
                    t += r.uniform(6, 14)
                    continue
                w = r.uniform(9, 13) if busy else r.uniform(9, 16)
                dep = r.uniform(24, 30) if busy else r.uniform(20, 28)
                a = ls.interpolate(t)
                b = ls.interpolate(min(L, t + w))
                dx, dz = b.x - a.x, b.y - a.y
                ln = math.hypot(dx, dz)
                if ln < 6:
                    break
                tx, tz = dx / ln, dz / ln
                nx, nz = -tz * side, tx * side  # away from the road on this side
                off = edge + ROW_SETBACK + dep / 2
                cx, cz = (a.x + b.x) / 2 + nx * off, (a.y + b.y) / 2 + nz * off
                bi = block_at(cx, cz)
                need = target_cells.get(bi)
                if not need or need[0] <= 0:
                    t += w
                    continue
                poly = rect_poly(cx, cz, -nx, -nz, ln, dep)
                got = try_place(poly, bi)
                if got:
                    need[0] -= got
                    if need[1] == 'lakeside':
                        style, fl, shop = ('villa' if r.random() < 0.5 else 'house'), r.choice([2, 2, 3]), False
                    elif tag == '2':
                        style, fl, shop = 'shophouse', r.choice([4, 4, 5, 5, 6, 6, 7]), True
                    elif busy:
                        style, fl, shop = 'shophouse', r.choice([3, 3, 4, 4, 5, 5, 6]), True
                    else:
                        roll = r.random()
                        if roll < 0.45:
                            style, fl, shop = 'walkup', r.choice([4, 5, 5, 6, 6, 7, 8]), r.random() < 0.35
                        elif roll < 0.8:
                            style, fl, shop = 'shophouse', r.choice([2, 3, 3, 4, 5]), r.random() < 0.5
                        else:
                            style, fl, shop = 'house', r.choice([2, 2, 3]), False
                    # the front edge of rect_poly is edge 0 ((-1, 1) -> (1, 1) is on the +u side = towards the road)
                    add(poly, style, fl, 0, shop, need[1], r, 'row')
                t += w + (0 if r.random() < 0.85 else r.uniform(1, 3))
    print('frontage rows', len(infill), round(__import__('time').time() - t0), 's')

    # ---------------------------------------------------------------- 3b. the interior of each block
    ys, xs = np.nonzero(free)
    order = np.arange(len(xs))
    rr = np.random.default_rng(1411)
    rr.shuffle(order)
    tries = 0
    for k in order[: min(len(order), 2_500_000)]:
        j, i = ys[k], xs[k]
        if not free[j, i]:
            continue
        bi = int(blocks[j, i])
        need = target_cells.get(bi)
        if not need or need[0] <= 0:
            continue
        tries += 1
        x, z = R.x0 + (i + 0.5) * RES, R.z0 + (j + 0.5) * RES
        r = rng_for('in', int(i), int(j))
        use = need[1]
        roll = r.random()
        if use == 'lakeside':
            if roll < 0.55:
                style, w, dep, fl = 'villa', r.uniform(20, 30), r.uniform(18, 26), r.choice([2, 2, 3])
            elif roll < 0.85:
                style, w, dep, fl = 'house', r.uniform(14, 20), r.uniform(14, 20), r.choice([2, 3])
            else:
                style, w, dep, fl = 'walkup', r.uniform(22, 30), r.uniform(18, 24), r.choice([4, 5, 6])
        elif use in ('university', 'school', 'college', 'hospital', 'military', 'government'):
            style, w, dep, fl = 'hall' if roll < 0.4 else 'walkup', r.uniform(20, 44), r.uniform(16, 30), r.choice([2, 3, 3, 4])
        elif use in ('commercial', 'retail'):
            style, w, dep, fl = 'mass', r.uniform(18, 36), r.uniform(18, 32), r.choice([4, 5, 6, 7, 8, 10])
        elif use == 'industrial':
            style, w, dep, fl = 'hall', r.uniform(24, 48), r.uniform(20, 40), r.choice([1, 1, 2])
        elif roll < 0.62:
            # (Yangon's townships are mostly 4-8 floor walk-up blocks, often two or three units joined)
            style, w, dep, fl = 'walkup', r.uniform(24, 40), r.uniform(20, 30), r.choice([4, 4, 5, 5, 6, 6, 7, 8])
        elif roll < 0.9:
            style, w, dep, fl = 'house', r.uniform(14, 22), r.uniform(14, 22), r.choice([2, 2, 3])
        else:
            style, w, dep, fl = 'shed', r.uniform(10, 16), r.uniform(12, 20), 1
        # face the nearest road
        best = None
        for jj in segs_tree.query(Point(x, z).buffer(220)):
            dd = segs[jj][0].distance(Point(x, z))
            if best is None or dd < best[0]:
                best = (dd, jj)
        if best is None:
            ux, uz = 0.0, -1.0
        else:
            ls = segs[best[1]][0]
            q = ls.interpolate(ls.project(Point(x, z)))
            ux, uz = q.x - x, q.y - z
            L = math.hypot(ux, uz) or 1
            ux, uz = ux / L, uz / L
        poly = rect_poly(x, z, ux, uz, w, dep)
        got = try_place(poly, bi)
        if got:
            need[0] -= got
            add(poly, style, fl, 0, False, use, r, 'inner')
    print('interior', len(infill), 'tries', tries, round(__import__('time').time() - t0), 's')

    allp = plots + infill
    if tag != '05':
        # the market grounds with a look of their own (Bogyoke Aung San Market's halls)
        mk = []
        for a in load('areas'):
            nm = ((a['t'].get('name:en') or '') + ' ' + (a['t'].get('name') or '')).lower()
            if _re.search(MARKET_LOOK['name_re'], nm):
                try:
                    pg = Polygon(proj(a['p'])).buffer(0)
                except Exception:
                    continue
                if pg.area > 400 and region.intersects(pg):
                    mk.append(pg.buffer(2))
        n_mk = 0
        if mk:
            mku = unary_union(mk)
            for pl in allp:
                c = Polygon(pl['poly']).centroid
                if mku.contains(c):
                    r = rng_for('market', pl['id'])
                    pl.update({'floors': MARKET_LOOK['floors'], 'style': MARKET_LOOK['style'], 'roof': MARKET_LOOK['roof'],
                               'roof_colour': list(r.choice(MARKET_LOOK['roofs'])), 'wall_colour': list(r.choice(MARKET_LOOK['walls'])),
                               'shop': True, 'kind': 'market'})
                    n_mk += 1
        print('market look on', n_mk, 'plots')
        n_tw = podium_towers(allp)
        print('podium towers', n_tw)
    out = {'box': list(box), 'note': 'tools/yangon/city/plots.py (OSM outlines + infill to the real density), 14 Nov 2026',
           'landmarks_kept': [p.get('name') for p in landmarks], 'plots': allp}
    path = os.path.join(geo.BUILD, 'city', f'plots_{tag}.json')
    json.dump(out, open(path, 'w', encoding='utf-8'), separators=(',', ':'))
    # numbers: coverage of buildable land before and after
    fin = R.img()
    d = ImageDraw.Draw(fin)
    for pl in allp:
        d.polygon(R.px(pl['poly']), fill=255)
    fin_a = np.array(fin) > 0
    lb = (land & ~green_a)
    print(f"plots: {len(plots)} OSM + {len(infill)} infill = {len(allp)}; cover of buildable land {bld_a[lb].mean():.3f} -> {fin_a[lb].mean():.3f}")
    styles = {}
    for pl in allp:
        styles[pl['style']] = styles.get(pl['style'], 0) + 1
    print('styles', styles)
    # preview
    W = 1400
    sc = W / (box[2] - box[0])
    H = int((box[3] - box[1]) * sc)
    im = Image.new('RGB', (W, H), (60, 78, 58))
    dd = ImageDraw.Draw(im)
    f = lambda pts: [((x - box[0]) * sc, (z - box[1]) * sc) for x, z in pts]
    for g in ([water] if water.geom_type == 'Polygon' else list(water.geoms)):
        if g.geom_type == 'Polygon':
            dd.polygon(f(g.exterior.coords), fill=(40, 80, 130))
    for g in ([roads_poly] if roads_poly.geom_type == 'Polygon' else list(roads_poly.geoms)):
        if g.geom_type == 'Polygon':
            dd.polygon(f(g.exterior.coords), fill=(120, 120, 128))
            for h in g.interiors:
                dd.polygon(f(h.coords), fill=(60, 78, 58))
    for g in ([water] if water.geom_type == 'Polygon' else list(water.geoms)):
        if g.geom_type == 'Polygon':
            dd.polygon(f(g.exterior.coords), fill=(40, 80, 130))
    for pl in allp:
        dd.polygon(f(pl['poly']), fill=(214, 200, 170) if pl['src'] == 'osm' else (190, 120, 100))
    im.save(os.path.join(geo.BUILD, 'city', f'plots_{tag}.png'))
    print('wrote', path, round(__import__('time').time() - t0), 's')


def est_floors(t, area_m2, r):
    b = t.get('building', 'yes')
    if b in ('hut', 'shed', 'garage', 'garages', 'roof', 'kiosk', 'carport'):
        return 1
    if b in ('house', 'detached', 'bungalow'):
        return 2 if r.random() < 0.7 else 3
    if b in ('apartments', 'residential', 'dormitory'):
        return 5 + int(r.random() * 4)
    if b in ('university', 'school', 'college', 'hospital', 'public', 'civic', 'government'):
        return 2 + int(r.random() * 3)
    if b in ('retail', 'commercial', 'office', 'hotel'):
        return 4 + int(r.random() * 5)
    if b in ('industrial', 'warehouse', 'church', 'temple', 'religious', 'service'):
        return 1 + int(r.random() * 2)
    if area_m2 < 90:
        return 1 + int(r.random() * 2)
    if area_m2 < 250:
        return 2 + int(r.random() * 3)
    if area_m2 < 900:
        return 4 + int(r.random() * 5)
    if area_m2 < 2500:
        return 3 + int(r.random() * 5)
    return 2 + int(r.random() * 3)


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    tag = sys.argv[1] if len(sys.argv) > 1 else '05'
    box = geo.BOX_05 if tag == '05' else tuple(geo.batch_poly(tag).bounds)
    build(tag, box)
