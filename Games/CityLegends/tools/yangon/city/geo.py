"""Whole-Yangon map (14 Nov 2026): shared geography for the city generator (tools/yangon/city/).

World studs: X = OX + (lon - 96.14) * KX * SPM, Z = OZ - (lat - 16.82) * KY * SPM. SPM (across) and VS (up) are THE scale
setting of every Yangon tool: no tool may keep its own 1.6 or 30000 (2026-11-16, the 1:1 rescale to 3 studs a metre,
the cars' and players' scale, is planned in the vault note '2026-11-16 Yangon rescale plan - 1 to 1 at player scale').
Today 1.6 (the map built 13-14 Nov). Data: build/osm_ygn/*.json from tools/yangon/e0_extract.py (OpenStreetMap contributors, ODbL).
"""
import json, math, os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
MAP = os.path.join(ROOT, 'imports', 'refs', 'map')
OSM = os.path.join(ROOT, 'build', 'osm_ygn')
BUILD = os.path.join(ROOT, 'build')

LON0, LAT0, SPM = 96.14, 16.82, 1.6
VS = SPM                 # studs per metre up (terrain, water levels, DEM heights)
KX = 111320 * math.cos(math.radians(LAT0))
KY = 110540
OX = 30000.0
OZ = 0.0

# The 1:1 rebuild (owner, 16 Nov 2026: "Everything at player scale"): run any tool with YANGON_SCALE=1to1 to work at
# 3 studs a metre, in its own frame north of the old map (Z = 30000 - north metres x 3: the whole OSM box lands at
# Z about 6,800 to 53,200, clear of the old map's Z -12,000 to 3,000), so both maps can sit in the place while the new
# one is built. The old map's tools run as before without the variable.
if os.environ.get("YANGON_SCALE") == "1to1":
    SPM = 3.0
    VS = 3.0
    OZ = 30000.0
ONE_TO_ONE = SPM == 3.0
# (2026-11-16, rescale step 3) lengths in studs that the batch 1-3 tools tuned at 1.6 studs a metre (spacings, reaches,
# seam distances, height thresholds): multiply by LK to keep them in metres. Exactly 1.0 at the default scale.
LK = SPM / 1.6


def m(v):
    """Metres -> studs across (sizes, spacings, distances)."""
    return v * SPM

# the batch boxes in world studs (x0, z0, x1, z1). 0.5 = the ground of steps 0-11 (d10/d19's X0..Z1).
BOX_05 = (27977.0, -6469.0, 33455.0, 1693.0)


def world(lon, lat):
    return (OX + (lon - LON0) * KX * SPM, OZ - (lat - LAT0) * KY * SPM)


def lonlat(x, z):
    return (LON0 + (x - OX) / (KX * SPM), LAT0 - (z - OZ) / (KY * SPM))


def proj(pts):
    return [world(p[0], p[1]) for p in pts]


_cache = {}


def load(name):
    """build/osm_ygn/<name>.json's list (roads, buildings, areas, lines, points)."""
    if name not in _cache:
        _cache[name] = json.load(open(os.path.join(OSM, name + '.json'), encoding='utf-8'))[name]
    return _cache[name]


def in_box(x, z, box, margin=0.0):
    return box[0] - margin <= x <= box[2] + margin and box[1] - margin <= z <= box[3] + margin


def floors_from_tags(t):
    """building:levels, or height / 3.2 m; None when the tags don't say."""
    for k in ('building:levels',):
        v = t.get(k)
        if v:
            try:
                return max(1, int(round(float(str(v).split(';')[0].replace(',', '.')))))
            except ValueError:
                pass
    h = t.get('height')
    if h:
        try:
            return max(1, int(round(float(str(h).lower().replace('m', '').strip()) / 3.2)))
        except ValueError:
            pass
    return None


# The owner's batches (14 Nov 2026, "Yangon map - batches (owner, 14 Nov).webp"), traced on that picture with a fit on Lotte
# Hotel, Shwedagon, Yangon Zoo and Chaukhtatgyi (about +-0.002 deg): lon = 96.1372 + (px - 283) * 0.0002,
# lat = 16.8445 - (py - 340) * 0.000199. Outlines as (lon, lat), clockwise from the north-west.
def _px(x, y):
    return (round(96.1372 + (x - 283) * 0.0002, 5), round(16.8445 - (y - 340) * 0.000199, 5))


BATCH_LL = {
    '1': [_px(*p) for p in ((90, 290), (220, 272), (380, 293), (385, 340), (380, 420), (400, 460), (460, 505), (520, 527),
                            (535, 560), (470, 570), (400, 575), (340, 600), (250, 640), (190, 655), (200, 560), (190, 420),
                            (150, 360), (120, 330))],
    '2': [_px(*p) for p in ((190, 655), (250, 640), (340, 600), (400, 575), (470, 570), (535, 560), (530, 600), (470, 640),
                            (480, 690), (560, 735), (565, 750), (430, 745), (330, 720), (200, 690))],
    '3': [_px(*p) for p in ((380, 293), (440, 270), (470, 245), (520, 262), (560, 300), (600, 310), (640, 330), (660, 370),
                            (650, 420), (670, 470), (690, 500), (640, 540), (600, 500), (580, 500), (560, 525), (535, 560),
                            (520, 527), (460, 505), (400, 460), (380, 420), (385, 340))],
}


# (2026-11-16, rescale step 3) the 1:1 pilot districts: built standalone (no batch 0.5 box, no v4/v5 game roads, no seam
# with batches 1-3: none of them exists in the 1:1 frame), the map edge is the district box, the ground straight from the DEM
PILOT_LL = {
    # Myanmar Plaza / Kabar Aye Pagoda Road and its flyover, Hanthawaddy roundabout, Sedona, Inya Lake's east shore
    'P1': (96.133, 16.810, 96.159, 16.834),
}
for _t, (_lo0, _la0, _lo1, _la1) in PILOT_LL.items():
    BATCH_LL[_t] = [(_lo0, _la1), (_lo1, _la1), (_lo1, _la0), (_lo0, _la0)]


def standalone(tag):
    """a pilot district (PILOT_LL): no seams with batch 0.5 or other batches"""
    return tag in PILOT_LL


def batch_poly(tag, grow=0.0):
    """a batch's outline as a shapely Polygon in world studs ('05' = the built box)"""
    from shapely.geometry import Polygon, box as sbox
    if tag == '05':
        return sbox(*BOX_05).buffer(grow)
    return Polygon([world(lo, la) for lo, la in BATCH_LL[tag]]).buffer(grow)
