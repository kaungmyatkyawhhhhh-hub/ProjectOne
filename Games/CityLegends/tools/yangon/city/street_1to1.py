"""street_1to1.py <tag> (2026-11-16, rescale step 3: the STREET DETAIL layer of a 1:1 pilot district). Run with
YANGON_SCALE=1to1:

    YANGON_SCALE=1to1 python street_kit.py          (the kit: imports/sync/ygn1to1_street/street_kit.glb)
    YANGON_SCALE=1to1 python street_signs.py P1     (the name plates: an image atlas of real street / stop names)
    YANGON_SCALE=1to1 python street_1to1.py P1      (this: where everything stands)

What makes a street read "Yangon" (vault: Research - Real Yangon street detail survey, section 0 and 2; Research -
Yangon street furniture and traffic life, sections 2-3), placed per REAL km from the P1 roads, buildings, walls and OSM:
  * concrete power poles every 30-40 m on one side of every street, crossarm + cable rack, a fibre slack coil on one in
    three, a white LED cobra head on every second street pole; a transformer platform about every 300 m; 6-14 black
    cables a span (Beams, made on the client: record L), service drops to the houses (record K)
  * main roads: galvanised lamp posts every 35 m, double-arm in a narrow median, single-arm on the kerb otherwise (white)
  * traffic signals at the OSM signal junctions: a white pole on the right-hand kerb of each main-road approach, mast arm
    over the lanes, two horizontal heads, a CCTV camera, the controller cabinet
  * YBS stops at the 31 OSM stops (about 1 in 4 a Decaux shelter, the rest a pole plate), the stop's real name (atlas
    plate), an orange bin
  * street-name signs at named junctions (real OSM Burmese / English names only; an atlas plate each face)
  * tea-shop spills, food carts, betel stalls in front of the OSM cafes / tea shops and the shophouse fronts; trishaw stands
    at lane mouths on the main roads
  * slab-covered drains along main-road pavements (outer edge) and street verges; median railings on narrow medians;
    litter at pole bases
No motorbikes (banned in these townships), no footbridges (none mapped in P1), no invented text, nothing in a traffic lane
or on a carriageway, nothing over a building, wall, gate, landmark lot, water or under a flyover; no two props overlap.

Output (build/city_1to1/street_<tag>/ and imports/sync/ygn1to1_street/):
  ygnstreet_<tag>.rbxmx    Folder Data_<tag>S: Meta (TILE, LOAD, PIDS, CODES, ATLAS, wire attach table) + a StringValue
                           a 256-stud tile in kit_pack's format plus the street records (YangonKitData):
     L x1(4) y1(3) z1(4) yaw1(3) x2(4) y2(3) z2(4) yaw2(3) n(1) seed(1)   a span of n cables between two poles
     K x1(4) y1(3) z1(4) x2(4) y2(3) z2(4) sag(2)                         one cable (service drop)
     T x(4) y(3) z(4) yaw(3) w(2) h(2) atlas(1) cell(2)                   a name plate picture (faces local -Z)
  items.json, stats.json, preview.png
"""
import glob
import json
import math
import os
import re
import sys
import time
import zlib
from collections import Counter, defaultdict

import numpy as np
import shapely
from shapely.geometry import Polygon, Point, LineString, box as sbox
from shapely.ops import unary_union
from shapely.strtree import STRtree

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import geo  # noqa: E402
import kit_pack  # noqa: E402
from kit_pack import enc, B64, _yaw  # noqa: E402

assert geo.ONE_TO_ONE, "run with YANGON_SCALE=1to1"
TAG = sys.argv[1] if len(sys.argv) > 1 else "P1"
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
B1 = os.path.join(ROOT, "build", "city_1to1")
BLD = os.path.join(B1, "buildings_%s" % TAG)
OUT = os.path.join(B1, "street_%s" % TAG)
GLB = os.path.join(ROOT, "imports", "sync", "ygn1to1_street")
TILE = 256.0
LOAD = 700.0       # street props are built within 700 studs of the camera (buildings: 1,000)
M = geo.m
KMETA = json.load(open(os.path.join(B1, "street", "kit_meta.json")))

# ------------------------------------------------------------------------------------------- densities (real metres)
POLE_EVERY = 35.0          # m (survey 2: 30-40 m, one side)
TRAFO_EVERY = 9            # one transformer platform in about 9 poles (300 m; survey 0.3-0.5 / 100 m)
LAMP_EVERY = 35.0          # main-road lamp posts (30-35 m)
WIRES = dict(main=12, street=8, lane=6)
DROP_SHARE = 0.55          # street poles with a service drop to a house
TEA_EVERY = 220.0          # m of shop frontage per tea-shop spill (survey: a tea shop every 150-300 m)
STALL_EVERY = 90.0         # m of shop frontage per cart / betel stall (1 per 50-100 m)
TRISHAW_MOUTHS = 0.35      # share of lane mouths on a main road with a trishaw stand
DRAIN_PIECE = 12.0


def H(*k):
    return zlib.crc32(repr(k).encode())


def rnd(*k):
    return (H(*k) % 100000) / 100000.0


def yaw_of(dx, dz):
    """Roblox yaw that turns local +X onto (dx, dz)"""
    return math.atan2(-dz, dx)


def rect(x, z, yaw, lo, hi):
    """the footprint polygon of a local box lo..hi (x, z) placed at (x, z) turned by yaw"""
    c, s = math.cos(yaw), math.sin(yaw)
    out = []
    for u, w in ((lo[0], lo[1]), (hi[0], lo[1]), (hi[0], hi[1]), (lo[0], hi[1])):
        out.append((x + u * c + w * s, z - u * s + w * c))
    return Polygon(out)


def foot(pid, x, z, yaw, grow=0.0, ytop=None):
    """the ground footprint of a kit piece from its parts' boxes (all classes), optionally only parts below ytop"""
    lo, hi = [1e9, 1e9], [-1e9, -1e9]
    for p in KMETA[pid]["parts"].values():
        lo[0], lo[1] = min(lo[0], p["lo"][0]), min(lo[1], p["lo"][2])
        hi[0], hi[1] = max(hi[0], p["hi"][0]), max(hi[1], p["hi"][2])
    return rect(x, z, yaw, (lo[0] - grow, lo[1] - grow), (hi[0] + grow, hi[1] + grow))


# =================================================================================================== inputs
def load_profile():
    prof = json.load(open(os.path.join(B1, "roads_%s_profile.json" % TAG)))
    lanes = []
    for f in sorted(glob.glob(os.path.join(B1, "YangonLanesB%s_*.lua" % TAG))):
        src = open(f, encoding="utf-8").read()
        for m_ in re.finditer(r'road = "([^"]*)", way = (\d+), lane = (\d+), kind = "(\w+)"[^}]*?pts = \{ ([^}]*) \}', src):
            name, way, lane, kind, pts = m_.groups()
            v = [float(x) for x in pts.split(",") if x.strip()]
            P = [(v[i], v[i + 2]) for i in range(0, len(v) - 2, 3)]
            em = re.search(r"B%s\.(\d+)$" % re.escape(TAG), name)
            lanes.append(dict(edge=int(em.group(1)) if em else None, pts=P))
    lane_edges = Counter(l["edge"] for l in lanes if l["edge"] is not None)
    edges = []
    for e in prof:
        P = np.array([[p[0], p[2]] for p in e["pts"]], float)
        if len(P) < 2:
            continue
        Y = np.array([p[1] for p in e["pts"]], float)
        d = np.diff(P, axis=0)
        L = np.hypot(d[:, 0], d[:, 1])
        s = np.r_[0, np.cumsum(L)]
        traffic = e["id"] in lane_edges
        flush = (not traffic) and e["hw"] in ("residential", "living_street", "service", "unclassified", "track", "road")
        kind = "main" if not flush else ("lane" if e["walk"] <= 3.2 else "street")
        edges.append(dict(id=e["id"], name=e["name"] or "", hw=e["hw"], raised=bool(e["raised"]), P=P, Y=Y, s=s,
                          L=float(s[-1]), h0=float(e["half"][0]), h1=float(e["half"][1]), walk=float(e["walk"]),
                          flush=flush, kind=kind, traffic=traffic))
    return edges, lanes


def at(e, s):
    """(point, tangent, y) at distance s along an edge"""
    s = min(max(s, 0.0), e["L"])
    i = int(np.searchsorted(e["s"], s, side="right") - 1)
    i = min(max(i, 0), len(e["P"]) - 2)
    seg = e["s"][i + 1] - e["s"][i]
    t = (s - e["s"][i]) / seg if seg > 1e-9 else 0.0
    p = e["P"][i] + (e["P"][i + 1] - e["P"][i]) * t
    d = e["P"][i + 1] - e["P"][i]
    n = math.hypot(d[0], d[1]) or 1.0
    return (float(p[0]), float(p[1])), (float(d[0] / n), float(d[1] / n)), float(e["Y"][i] + (e["Y"][i + 1] - e["Y"][i]) * t)


def lateral(c, t, off):
    """off studs right of the heading t (right = (-tz, tx))"""
    return c[0] - t[1] * off, c[1] + t[0] * off


def edge_strips(e, trim=None):
    """the flush edge strips of a street (both sides), trimmed 6 m from the ends (junctions)"""
    k = M(6) if trim is None else trim
    return unary_union([strip_poly(e, e["h1"], e["h1"] + e["walk"], k, e["L"] - k),
                        strip_poly(e, -e["h0"] - e["walk"], -e["h0"], k, e["L"] - k)])


def strip_poly(e, lo, hi, s0=0.0, s1=None):
    s1 = e["L"] if s1 is None else s1
    if s1 - s0 < 1.0:
        return Polygon()
    ss = [s for s in e["s"] if s0 < s < s1]
    ss = [s0] + ss + [s1]
    A, B = [], []
    for s in ss:
        c, t, _ = at(e, s)
        A.append(lateral(c, t, lo))
        B.append(lateral(c, t, hi))
    pg = Polygon(A + B[::-1])
    return pg if pg.is_valid else pg.buffer(0)


def read_boxes():
    out = []
    for f in sorted(glob.glob(os.path.join(B1, "RoadCollide_%s_*.luau" % TAG))):
        for line in open(f, encoding="utf-8"):
            w = line.split()
            if len(w) != 9:
                continue
            try:
                cx, cy, cz, dx, dy, dz, wd = (float(v) for v in w[:7])
            except ValueError:
                continue
            L = math.hypot(dx, dz)
            if L < 1e-6:
                continue
            ux, uz = dx / L, dz / L
            nx, nz = -uz, ux
            pg = Polygon([(cx + ux * a * L / 2 + nx * b * wd / 2, cz + uz * a * L / 2 + nz * b * wd / 2)
                          for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1))])
            out.append(dict(kind=w[8], poly=pg, cx=cx, cy=cy, cz=cz, ux=ux, uz=uz, L=L, dy=dy))
    return out


class Ground:
    def __init__(self, boxes):
        d = np.load(os.path.join(B1, "terrain_%s_state.npz" % TAG))
        self.H, self.code, self.org = d["H"], d["code"], d["origin"]
        self.boxes = boxes
        self.tree = STRtree([b["poly"] for b in boxes])

    def terrain(self, x, z):
        i = int((x - self.org[0]) / 4.0)
        j = int((z - self.org[1]) / 4.0)
        i = min(max(i, 0), self.H.shape[0] - 1)
        j = min(max(j, 0), self.H.shape[1] - 1)
        return float(self.H[i, j]), int(self.code[i, j])

    def y(self, x, z, kinds=("R", "P", "M", "J")):
        """the top of the road box under (x, z), else the terrain"""
        best = None
        for k in self.tree.query(Point(x, z)):
            b = self.boxes[int(k)]
            if b["kind"] not in kinds or not b["poly"].covers(Point(x, z)):
                continue
            t = ((x - b["cx"]) * b["ux"] + (z - b["cz"]) * b["uz"]) / b["L"]
            yy = b["cy"] + b["dy"] * t
            best = yy if best is None else max(best, yy)
        if best is not None:
            return best, "road"
        h, c = self.terrain(x, z)
        return h, ("water" if c == 4 else "ground")


def load_buildings():
    plots = json.load(open(os.path.join(BLD, "plots.json")))
    polys, info = [], []
    for p in plots:
        g = Polygon(p["poly"]).buffer(0)
        if g.is_empty:
            continue
        polys.append(g)
        info.append(p)
    walls, gates = [], []
    gate_pids = set()
    km = json.load(open(os.path.join(BLD, "kit_meta.json")))
    for pid, v in km.items():
        if v["key"][0] == "prop" and "gate" in str(v["key"]):
            gate_pids.add(pid)
    for f in glob.glob(os.path.join(BLD, "Inst_*.txt")):
        for line in open(f, encoding="utf-8"):
            w = line.split()
            if not w or w[0].startswith("#"):
                continue
            if w[0] == "B" and w[-1] == "WCOL":
                x, y, z, sx, sy, sz, yaw = (float(v) for v in w[1:8])
                walls.append(rect(x, z, yaw, (-sx / 2, -sz / 2), (sx / 2, sz / 2)))
            elif w[0] in gate_pids:
                sx, x, y, z, yaw = (float(v) for v in w[1:6])
                # a gate panel: its origin is the bottom-left corner on the wall plane, width about 4.5 m x sx
                wdt = km[w[0]].get("w", 13.5) * sx
                gates.append(rect(x, z, yaw, (-1.0, -6.0), (wdt + 1.0, 6.0)))
    # the landmark lots (re-fitted on their own) and the shells (taller pieces than plots: towers, the mall)
    sys.argv = [sys.argv[0], TAG]
    shells = []
    for f in glob.glob(os.path.join(BLD, "Shell_*.txt")):
        for line in open(f, encoding="utf-8"):
            w = line.split()
            if w and w[0] == "S":
                x, y, z, sx, sy, sz, yaw = (float(v) for v in w[2:9])
                shells.append(rect(x, z, yaw, (-sx / 2, -sz / 2), (sx / 2, sz / 2)))
    return polys, info, walls, gates, shells


def landmark_zone():
    sites = {
        "myanmar_centre": dict(pts=[(96.15439, 16.82723), (96.15476, 16.82866)], grow=60.0),
        "sedona": dict(pts=[(96.154804, 16.830686), (96.154804, 16.830816), (96.156476, 16.830081),
                            (96.154886, 16.829420), (96.155045, 16.829389), (96.154687, 16.829663)], grow=45.0),
    }
    fp = json.load(open(os.path.join(ROOT, "build", "footprints", "ygn_footprints.json"), encoding="utf-8"))["buildings"]
    by_id = {b["id"]: b for b in fp}
    zs = []
    for name, oids in (("myanmar_centre", ["o421632377", "o463189671"]), ("sedona", ["o374512164", "o452876267"])):
        g = [Point(geo.world(*p)) for p in sites[name]["pts"]]
        for o in oids:
            if o in by_id:
                g.append(Polygon(geo.proj(by_id[o]["poly"])))
        zs.append(unary_union(g).convex_hull.buffer(M(sites[name]["grow"]) / 3.0 * 1.0))
    # P1 refit site outlines when the refit wrote them
    for f in glob.glob(os.path.join(ROOT, "build", "landmarks", "p1_refit", "*.json")):
        try:
            d = json.load(open(f, encoding="utf-8"))
        except Exception:
            continue
        for key in ("site", "site_outline", "outline"):
            v = d.get(key) if isinstance(d, dict) else None
            if v and isinstance(v, list) and len(v) >= 3 and isinstance(v[0], (list, tuple)):
                try:
                    zs.append(Polygon([(q[0], q[-1]) for q in v]).buffer(6))
                except Exception:
                    pass
    return unary_union(zs)


# =================================================================================================== the world
class World:
    def __init__(self):
        t0 = time.time()
        self.edges, self.lanes = load_profile()
        self.boxes = read_boxes()
        self.G = Ground(self.boxes)
        self.district = geo.batch_poly(TAG).buffer(-M(4))
        shapely.prepare(self.district)
        b = self.boxes
        self.CARR = unary_union([x["poly"] for x in b if x["kind"] in ("R", "J", "D")]).buffer(0)
        self.PAVE = unary_union([x["poly"] for x in b if x["kind"] == "P"]).buffer(0)
        self.MED = unary_union([x["poly"] for x in b if x["kind"] == "M"]).buffer(0)
        self.ROADS = unary_union([self.CARR, self.PAVE, self.MED] + [x["poly"] for x in b if x["kind"] == "W"]).buffer(0)
        deck = [x["poly"] for x in b if x["kind"] in ("D", "W")]
        self.DECK = unary_union(deck).buffer(M(3)) if deck else Polygon()
        self.LANES = unary_union([LineString(l["pts"]).buffer(M(2.2), cap_style=2) for l in self.lanes if len(l["pts"]) >= 2])
        polys, self.binfo, walls, gates, shells = load_buildings()
        self.BLDS = polys
        self.BLD = unary_union(polys + shells).buffer(0.4)
        self.WALL = unary_union(walls + gates).buffer(0.3)
        self.GATES = unary_union(gates) if gates else Polygon()
        self.LMZ = landmark_zone()
        self.btree = STRtree(polys)
        for g in (self.CARR, self.PAVE, self.MED, self.ROADS, self.DECK, self.LANES, self.BLD, self.WALL, self.LMZ, self.GATES):
            shapely.prepare(g)
        self.occ = defaultdict(list)
        self.items = []
        self.wires = []
        self.drops = []
        self.plates = []
        self.stats = Counter()
        print("world ready %.0f s: %d edges, %d lanes, %d boxes, %d buildings, %d wall boxes" %
              (time.time() - t0, len(self.edges), len(self.lanes), len(self.boxes), len(polys), len(walls)))

    # ---------------------------------------------------------------------------------------- occupancy
    def occ_free(self, g):
        x0, z0, x1, z1 = g.bounds
        for i in range(int(x0 // 32), int(x1 // 32) + 1):
            for j in range(int(z0 // 32), int(z1 // 32) + 1):
                for h in self.occ[(i, j)]:
                    if h.intersects(g):
                        return False
        return True

    def occ_add(self, g):
        x0, z0, x1, z1 = g.bounds
        for i in range(int(x0 // 32), int(x1 // 32) + 1):
            for j in range(int(z0 // 32), int(z1 // 32) + 1):
                self.occ[(i, j)].append(g)

    def clear_of(self, g, allow=None, tall=None):
        """True when the footprint g stands clear of buildings, walls, gates, landmark lots, decks, water and (unless
        allowed) roads; `allow` = a polygon of road where this item may stand (its own pavement / edge strip)"""
        if not self.district.contains(g):
            return False
        if self.BLD.intersects(g) or self.WALL.intersects(g) or self.LMZ.intersects(g) or self.DECK.intersects(g):
            return False
        if self.LANES.intersects(g):
            return False
        rest = g if allow is None else g.difference(allow.buffer(0.01))
        if not rest.is_empty and rest.area > 0.01 and self.ROADS.intersects(rest):
            return False
        if tall is not None and self.BLD.intersects(tall):
            return False
        for x, z in list(g.exterior.coords)[:-1] + [(g.centroid.x, g.centroid.y)]:
            if self.G.terrain(x, z)[1] == 4:
                return False
        return self.occ_free(g)

    # ---------------------------------------------------------------------------------------- records
    def put(self, kind, pid, x, z, yaw, g, y=None, occupy=True, sx=1.0):
        if y is None:
            y = self.G.y(x, z)[0]
        self.items.append(dict(kind=kind, pid=pid, x=round(x, 3), y=round(y, 3), z=round(z, 3), yaw=round(yaw % (2 * math.pi), 5), sx=sx))
        if occupy and g is not None:
            self.occ_add(g)
        self.stats[kind] += 1
        return self.items[-1]

    def pave_allow(self, e, side):
        """the pavement polygon on one side of a main edge (union of P boxes near it)"""
        return self.PAVE


W = None
EDGE = {}


# =================================================================================================== 1. poles + wires
def side_offsets(e, side):
    """(carriageway edge offset, outer offset of the pavement / edge strip) on side +1 (right) / -1 (left)"""
    h = e["h1"] if side == 1 else e["h0"]
    return h, h + e["walk"]


def poles():
    n_poles = n_trafo = 0
    for e in W.edges:
        if e["raised"] or e["L"] < M(25):
            continue
        side = 1 if H("pside", e["id"]) % 2 else -1
        if e["h0"] < -0.5:
            side = 1          # a carriageway of a divided road: its left is the median
        h, outer = side_offsets(e, side)
        if e["flush"]:
            offs = [outer - 0.8, outer + 0.9, outer - 1.8]        # the edge strip's outer part, else the verge
            allow = edge_strips(e)
        else:
            offs = [h + 1.25, h + 1.9]                           # main road: just inside the kerb, on the pavement
            allow = W.PAVE
        every = M(POLE_EVERY) * (0.92 + 0.16 * rnd("pe", e["id"]))
        s = M(6) + rnd("ps", e["id"]) * every * 0.6
        chain = None
        nth = 0
        while s < e["L"] - M(6):
            placed = None
            for ds in (0, 4, -4, 9, -9, 15):
                for off in offs:
                    c, t, _ = at(e, s + ds)
                    x, z = lateral(c, t, side * off)
                    # local +Z points to the road (the lamp arm and the head), local X along the road
                    rz = (t[1] * side, -t[0] * side)        # toward the road centre = -side * right
                    yaw = yaw_of(t[0], t[1])
                    zdir = (-t[1], t[0])       # local +Z for this yaw = right of t
                    if (zdir[0] * rz[0] + zdir[1] * rz[1]) < 0:
                        yaw = yaw_of(-t[0], -t[1])
                    trafo = (nth % TRAFO_EVERY == TRAFO_EVERY - 1) and not e["kind"] == "lane"
                    pid = "trafo" if trafo else "ppolea"
                    g = rect(x, z, yaw, (-0.5, -0.5), (0.5, 0.5)) if not trafo else rect(x, z, yaw, (-4.6, -0.9), (4.6, 0.9))
                    tall = rect(x, z, yaw, (-0.6 - (4 if trafo else 0), -3.5), (0.6 + (4 if trafo else 0), 3.5))
                    if W.clear_of(g, allow=allow, tall=tall):
                        placed = (x, z, yaw, g, pid, t)
                        break
                if placed:
                    break
            if not placed:
                chain = None
                s += every * 0.5
                continue
            x, z, yaw, g, pid, t = placed
            nth += 1
            if pid != "trafo":
                lamp = e["flush"] and nth % 2 == 1
                coil = rnd("coil", e["id"], nth) < 0.33
                pid = ("ppolebl" if coil else "ppolel") if lamp else ("ppoleb" if coil else "ppolea")
            else:
                n_trafo += 1
            it = W.put("pole", pid, x, z, yaw, g)
            it["edge"] = e["id"]
            n_poles += 1
            if chain is not None:
                px, pz, pyaw, pt, py = chain
                d = math.hypot(x - px, z - pz)
                ln = LineString([(px, pz), (x, z)])
                if d < M(55) and not W.BLD.intersects(ln) and (pt[0] * t[0] + pt[1] * t[1]) > math.cos(math.radians(30)):
                    n = WIRES[e["kind"]] + (H("wn", e["id"], nth) % 3) - 1
                    # wiring yaw of this end within 90 degrees of the last one (the cables do not cross)
                    wy = yaw
                    if math.cos(wy - pyaw) < 0:
                        wy = yaw + math.pi
                    W.wires.append(dict(a=(px, py, pz, pyaw), b=(x, it["y"], z, wy), n=max(2, min(14, n)), seed=H("ws", e["id"], nth) % 64))
                    W.stats["wire_spans"] += 1
                    W.stats["wire_m"] += d / 3.0 * n
            chain = (x, z, yaw if pid != "trafo" else yaw, t, it["y"])
            # service drops to the houses on the pole's side (flush streets)
            if e["flush"] and rnd("drop", e["id"], nth) < DROP_SHARE:
                drops(x, it["y"], z, e, side, t, nth)
            s += every
    print("poles %d (transformers %d), spans %d, drops %d" % (n_poles, n_trafo, W.stats["wire_spans"], len(W.drops)))


def drops(x, y, z, e, side, t, nth):
    """1-2 service cables from the pole's rack to the nearest house fronts within 20 m on either side"""
    made = 0
    p = Point(x, z)
    for k in W.btree.query(p.buffer(M(20))):
        g = W.BLDS[int(k)]
        info = W.binfo[int(k)]
        if info.get("arch") in ("civic", "condo", "shed"):
            continue
        q = g.exterior.interpolate(g.exterior.project(p))
        d = p.distance(q)
        if d < M(3) or d > M(20):
            continue
        ln = LineString([(x, z), (q.x, q.y)])
        if W.BLD.buffer(-0.6).intersects(ln.interpolate(0.85, normalized=True).buffer(0.1)):
            continue
        if W.BLD.intersects(LineString([(x, z), ln.interpolate(0.9, normalized=True).coords[0]])):
            continue
        floors = info.get("floors", 2) or 2
        gy = W.G.terrain(q.x, q.y)[0]
        top = gy + min(floors * 10.0, 15.0) - 2.0
        # end 0.3 studs off the wall, toward the pole
        vx, vz = (x - q.x) / d, (z - q.y) / d
        W.drops.append(dict(a=(x, y + 19.6, z), b=(q.x + vx * 0.3, top, q.y + vz * 0.3), sag=round(0.35 + 0.02 * d, 2)))
        made += 1
        if made >= 1 + (H("d2", e["id"], nth) % 2):
            break


# =================================================================================================== 2. lamps
def lamps():
    n1 = n2 = 0
    for e in W.edges:
        if e["raised"] or not e["traffic"] or e["L"] < M(20):
            continue
        every = M(LAMP_EVERY)
        s = M(8) + rnd("ls", e["id"]) * every
        # a paired one-way carriageway (median at offset 0..h0 on its left: inner edge offset = -h0 < 0?)
        median = e["h0"] < -0.5   # the inner carriageway edge is right of the line: a median lies between
        lead = e["P"][-1] - e["P"][0]
        mine = lead[0] > 0 or (abs(lead[0]) < 1e-6 and lead[1] > 0)
        while s < e["L"] - M(6):
            c, t, _ = at(e, s)
            if median:
                if mine:
                    x, z = c
                    yaw = yaw_of(t[0], t[1])
                    g = rect(x, z, yaw, (-0.8, -0.8), (0.8, 0.8))
                    if W.MED.contains(g) and W.clear_of(g, allow=W.MED):
                        W.put("lamp", "lamp2", x, z, yaw, g, y=W.G.y(x, z, ("M",))[0])
                        n2 += 1
            else:
                # single-arm posts on the kerb of the side WITHOUT the power poles
                side = -1 if H("pside", e["id"]) % 2 else 1
                h, outer = side_offsets(e, side)
                for off in (h + 1.2, h + 1.8):
                    x, z = lateral(c, t, side * off)
                    rz = (t[1] * side, -t[0] * side)
                    yaw = yaw_of(t[0], t[1])
                    if ((-t[1]) * rz[0] + t[0] * rz[1]) < 0:
                        yaw = yaw_of(-t[0], -t[1])
                    g = rect(x, z, yaw, (-0.8, -0.8), (0.8, 0.8))
                    if W.clear_of(g, allow=W.PAVE, tall=rect(x, z, yaw, (-0.6, -0.6), (0.6, 7))):
                        W.put("lamp", "lamp1", x, z, yaw, g)
                        n1 += 1
                        break
            s += every
    print("lamp posts: %d single, %d double (median)" % (n1, n2))


# =================================================================================================== 3. signals
def osm_items():
    d = json.load(open(os.path.join(ROOT, "build", "landmarks", "refs", "street_kit", "osm_street_items.json"), encoding="utf-8"))
    lo0, la0, lo1, la1 = geo.PILOT_LL[TAG]
    return [it for it in d["items"] if lo0 <= it["lon"] <= lo1 and la0 <= it["lat"] <= la1]


def signals(items):
    pts = [geo.world(it["lon"], it["lat"]) for it in items if it["kind"] == "traffic_signals"]
    # cluster within 50 m -> junctions
    clusters = []
    for p in pts:
        for c in clusters:
            if math.dist(p, c["c"]) < M(50):
                c["pts"].append(p)
                c["c"] = tuple(np.mean(c["pts"], axis=0))
                break
        else:
            clusters.append(dict(c=p, pts=[p]))
    n = 0
    for k, cl in enumerate(clusters):
        cx, cz = cl["c"]
        made = 0
        for e in W.edges:
            if not e["traffic"] or e["raised"]:
                continue
            for end in (0, 1):
                ep = e["P"][0] if end == 0 else e["P"][-1]
                if math.hypot(ep[0] - cx, ep[1] - cz) > M(45):
                    continue
                # the approach: traffic on this edge heading INTO the junction on its right half
                # one-way edges drive along their direction (end 1 = into the junction); two-way: both
                if e["h0"] < -0.5 and end == 0:
                    continue   # a one-way carriageway leaving the junction
                for back in (M(14), M(18), M(24), M(30)):
                    s = e["L"] - back if end == 1 else back
                    if s < M(4) or s > e["L"] - M(4):
                        continue
                    c, t, _ = at(e, s)
                    d_in = t if end == 1 else (-t[0], -t[1])       # heading into the junction
                    # the right-hand kerb of that heading
                    if end == 1:
                        h, outer = side_offsets(e, 1)
                        sgn = 1
                    else:
                        h, outer = side_offsets(e, -1)
                        sgn = -1
                    x, z = lateral(c, t, sgn * (h + 1.4))
                    # arm (local +X) toward the road centre: -right of d_in; heads face local -Z = against d_in
                    ax = (d_in[1], -d_in[0])
                    yaw = yaw_of(ax[0], ax[1])
                    width = (h if e["h0"] >= -0.5 else (e["h1"] - (-e["h0"])))
                    L = 6 if width < M(7) else (8 if width < M(9.5) else 10)
                    g = rect(x, z, yaw, (-0.7, -0.7), (0.7, 0.7))
                    if not W.clear_of(g, allow=W.PAVE, tall=rect(x, z, yaw, (-0.5, -2), (2, 2))):
                        continue
                    W.put("signal", "sig%d" % L, x, z, yaw, g)
                    # the controller cabinet 1.2 m behind the pole on the pavement (only one per junction)
                    if made == 0:
                        bx, bz = x - ax[0] * 1.2 - d_in[0] * 2.5, z - ax[1] * 1.2 - d_in[1] * 2.5
                        gb = rect(bx, bz, yaw, (-1.0, -0.7), (1.0, 0.7))
                        if W.clear_of(gb, allow=W.PAVE):
                            W.put("signal", "sigcab", bx, bz, yaw, gb)
                    made += 1
                    n += 1
                    break
        W.stats["signal_junctions"] += 1 if made else 0
    print("signals: %d poles at %d of %d junctions" % (n, W.stats["signal_junctions"], len(clusters)))


# =================================================================================================== 4. bus stops
def nearest_main(x, z, reach=M(30)):
    best = None
    for e in W.edges:
        if not e["traffic"] or e["raised"]:
            continue
        ln = LineString(e["P"])
        d = ln.distance(Point(x, z))
        if d < reach and (best is None or d < best[0]):
            best = (d, e, ln.project(Point(x, z)))
    return best


def plate_name(tags):
    nm = tags.get("name", "")
    en = tags.get("name:en", "")
    my = "".join(ch for ch in nm if "က" <= ch <= "႟" or ch in " ()0123456789").strip()
    my = re.sub(r"\s+", " ", my)
    my = my if any("က" <= ch <= "႟" for ch in my) else ""
    if not en:
        lat = re.sub(r"[က-႟]", "", nm).strip(" -")
        en = lat if re.search(r"[A-Za-z]", lat) else ""
    return my, en


def bus_stops(items, atlas):
    n = 0
    for it in items:
        if it["kind"] != "bus_stop":
            continue
        x0, z0 = geo.world(it["lon"], it["lat"])
        hit = nearest_main(x0, z0)
        if not hit:
            W.stats["bus_stop_no_road"] += 1
            continue
        d, e, s0 = hit
        # which side: the stop point's side of the edge line (one-way edges: their own right-hand pavement)
        c, t, _ = at(e, s0)
        cr = (x0 - c[0]) * (-t[1]) + (z0 - c[1]) * t[0]
        side = 1 if (cr >= 0 or e["h0"] < -0.5) else -1
        h, outer = side_offsets(e, side)
        my, en = plate_name(it["tags"])
        cell = atlas.get(("stop", my, en)) if atlas else None
        shelter = (H("shelter", it["id"]) % 100) < 26
        placed = False
        for ds in (0, 6, -6, 12, -12, 20, -20, 30, -30):
            s = s0 + ds
            if s < M(10) or s > e["L"] - M(10):
                continue
            c, t, _ = at(e, s)
            rz = (t[1] * side, -t[0] * side)            # toward the road
            yaw = yaw_of(t[0], t[1])
            if ((-t[1]) * rz[0] + t[0] * rz[1]) > 0:
                yaw = yaw_of(-t[0], -t[1])              # local +Z = away from the road (the shelter's back)
            if shelter:
                off = outer - 3.0
                x, z = lateral(c, t, side * off)
                g = foot("busd", x, z, yaw, grow=0.1)
                if not W.clear_of(g, allow=W.PAVE):
                    continue
                it_ = W.put("busstop", "busd", x, z, yaw, g)
                if cell is not None:
                    # the YBS box's road face: centre (-1.2, 8.38, -D/2 + 0.2 - 0.225), 3.6 x 1.35
                    add_plate(it_, (-1.2, 8.38, -2.25 + 0.2 - 0.225 - 0.085), 3.5, 1.25, cell, back=False)
            else:
                off = h + 1.3
                x, z = lateral(c, t, side * off)
                g = rect(x, z, yaw, (-1.0, -0.4), (1.0, 0.4))
                if not W.clear_of(g, allow=W.PAVE):
                    continue
                it_ = W.put("busstop", "busp", x, z, yaw, g)
                if cell is not None:
                    add_plate(it_, (0, 7.6, -0.045 - 0.085), 1.8, 1.2, cell, back=True)
            # an orange bin beside it
            for bd in (4.5, -4.5, 7.0):
                bx, bz = lateral(at(e, s + bd)[0], t, side * (outer - 2.0))
                gb = rect(bx, bz, yaw, (-1.0, -1.1), (1.0, 1.1))
                if W.clear_of(gb, allow=W.PAVE):
                    W.put("bin", "bin", bx, bz, yaw, gb)
                    break
            placed = True
            n += 1
            break
        if not placed:
            W.stats["bus_stop_no_room"] += 1
    print("bus stops %d (no road %d, no room %d)" % (n, W.stats["bus_stop_no_road"], W.stats["bus_stop_no_room"]))


def add_plate(it, local, w, h, cell, back=True):
    """a name plate picture on a placed piece: local (x, y, z) in the piece frame, facing local -Z (and +Z when back)"""
    c, s = math.cos(it["yaw"]), math.sin(it["yaw"])

    def world(u, y, w_):
        return (it["x"] + u * c + w_ * s, it["y"] + y, it["z"] - u * s + w_ * c)
    x, y, z = world(*local)
    W.plates.append(dict(x=x, y=y, z=z, yaw=it["yaw"], w=w, h=h, atlas=cell[0], cell=cell[1]))
    if back:
        x2, y2, z2 = world(local[0], local[1], -local[2])
        W.plates.append(dict(x=x2, y=y2, z=z2, yaw=it["yaw"] + math.pi, w=w, h=h, atlas=cell[0], cell=cell[1]))
    W.stats["plates"] += 2 if back else 1


# =================================================================================================== 5. street-name signs
def street_names():
    """edge id -> (my, en) from the OSM roads (profile names are OSM 'name')"""
    roads = json.load(open(os.path.join(geo.OSM, "roads.json"), encoding="utf-8"))["roads"]
    by = {}
    for r in roads:
        t = r.get("t", {})
        if t.get("name"):
            by.setdefault(t["name"], t)
    out = {}
    for e in W.edges:
        if not e["name"]:
            continue
        t = by.get(e["name"], {"name": e["name"]})
        my, en = plate_name(t)
        if my or en:
            out[e["id"]] = (my, en)
    return out


def name_signs(atlas):
    names = street_names()
    ends = defaultdict(list)
    for e in W.edges:
        if e["raised"] or e["id"] not in names:
            continue
        for end in (0, 1):
            p = e["P"][0] if end == 0 else e["P"][-1]
            key = (int(p[0] // 20), int(p[1] // 20))
            ends[key].append((e, end, p))
    # join near ends into junctions
    junctions = []
    seen = set()
    for key, lst in ends.items():
        if key in seen:
            continue
        group = []
        for di in (-1, 0, 1):
            for dj in (-1, 0, 1):
                k2 = (key[0] + di, key[1] + dj)
                if k2 in ends and k2 not in seen:
                    group += ends[k2]
                    seen.add(k2)
        junctions.append(group)
    n = 0
    for jn, group in enumerate(junctions):
        nm = {}
        for e, end, p in group:
            nm.setdefault(names[e["id"]], (e, end, p))
        if len(nm) < 2 or rnd("sign", jn) > 0.7:
            continue
        cells = [atlas.get(("street",) + k) for k in nm]
        if not all(cells):
            continue
        # the pole on the corner of the first (smaller) street, its right side, 8-14 m back
        lst = sorted(nm.items(), key=lambda kv: (kv[1][0]["kind"] == "main", kv[1][0]["walk"]))
        (k1, (e, end, p)) = lst[0]
        placed = None
        for back in (M(8), M(11), M(14), M(18)):
            s = back if end == 0 else e["L"] - back
            if not (0 < s < e["L"]):
                continue
            c, t, _ = at(e, s)
            for side in (1, -1):
                h, outer = side_offsets(e, side)
                for off in ((outer + 0.9, outer - 0.6) if e["flush"] else (outer - 1.0, h + 2.0)):
                    x, z = lateral(c, t, side * off)
                    g = rect(x, z, 0, (-0.5, -0.5), (0.5, 0.5))
                    allow = W.PAVE if not e["flush"] else edge_strips(e)
                    if W.clear_of(g, allow=allow, tall=Point(x, z).buffer(1.6)):
                        placed = (x, z, t)
                        break
                if placed:
                    break
            if placed:
                break
        if not placed:
            continue
        x, z, t = placed
        pole = W.put("sign", "spole", x, z, 0.0, rect(x, z, 0, (-0.5, -0.5), (0.5, 0.5)))
        for k, (key, (e2, end2, p2)) in enumerate(lst[:2]):
            # plate k along street k's direction at its junction end, beside the pole (cantilevered 1.55 along)
            c2, t2, _ = at(e2, 0 if end2 == 0 else e2["L"])
            yaw = yaw_of(t2[0], t2[1])
            y = 6.6 + k * 1.2
            px, pz = x + t2[0] * 1.55, z + t2[1] * 1.55
            it = W.put("sign", "splate", px, pz, yaw, None, y=pole["y"] + y, occupy=False)
            add_plate(it, (0, 0, -0.05 - 0.085), 2.75, 0.95, atlas[("street",) + key], back=True)
        n += 1
    print("street-name signs: %d junction poles" % n)


# =================================================================================================== 6. tea shops, stalls, trishaws
def frontage_spots(e, side, step, start_key):
    """spots along a side of an edge in front of shophouses / walk-ups (township / walkup archetypes) within 12 m"""
    out = []
    s = M(15) + rnd(start_key, e["id"], side) * step
    h, outer = side_offsets(e, side)
    while s < e["L"] - M(15):
        c, t, _ = at(e, s)
        px, pz = lateral(c, t, side * (outer + M(6)))
        ok = False
        for k in W.btree.query(Point(px, pz).buffer(M(8))):
            if W.binfo[int(k)].get("arch") in ("township", "walkup") and W.BLDS[int(k)].distance(Point(px, pz)) < M(8):
                ok = True
                break
        if ok:
            out.append(s)
        s += step
    return out


def place_on_side(e, side, s, pid, kind, depth_from_outer):
    """a piece on the pavement (main) or the edge strip / verge (street) at s, its long side along the road"""
    h, outer = side_offsets(e, side)
    for ds in (0, 3, -3, 7, -7):
        c, t, _ = at(e, s + ds)
        rz = (t[1] * side, -t[0] * side)
        yaw = yaw_of(t[0], t[1])
        if ((-t[1]) * rz[0] + t[0] * rz[1]) > 0:
            yaw = yaw_of(-t[0], -t[1])         # local -Z toward the road
        if e["flush"]:
            offs = [outer + depth_from_outer + 0.6, outer - depth_from_outer]
            allow = edge_strips(e)
        else:
            offs = [outer - depth_from_outer - 2.0, outer - depth_from_outer - 1.0]
            allow = W.PAVE
        for off in offs:
            x, z = lateral(c, t, side * off)
            g = foot(pid, x, z, yaw, grow=0.2)
            if W.clear_of(g, allow=allow):
                return W.put(kind, pid, x, z, yaw, g)
    return None


def street_life(items):
    n_tea = n_stall = 0
    # 1. the OSM cafes / tea shops / local restaurants: a spill in front
    for it in items:
        if it["kind"] not in ("cafe", "teashop", "restaurant", "fast_food"):
            continue
        tags = it["tags"]
        local = any("က" <= ch <= "႟" for ch in tags.get("name", "")) or it["kind"] in ("teashop", "cafe")
        if not local or it["tags"].get("cuisine") in ("steak_house", "pizza", "burger", "italian", "japanese", "korean"):
            continue
        x0, z0 = geo.world(it["lon"], it["lat"])
        best = None
        for e in W.edges:
            if e["raised"]:
                continue
            ln = LineString(e["P"])
            d = ln.distance(Point(x0, z0))
            if d < M(35) and (best is None or d < best[0]):
                best = (d, e, ln.project(Point(x0, z0)))
        if not best:
            continue
        d, e, s0 = best
        c, t, _ = at(e, s0)
        side = 1 if (x0 - c[0]) * (-t[1]) + (z0 - c[1]) * t[0] >= 0 else -1
        pid = "teachair" if H("tc", it["id"]) % 3 == 0 else "tealow%d" % (H("tl", it["id"]) % 2)
        if place_on_side(e, side, s0, pid, "tea", 0.0):
            n_tea += 1
    # 2. shop frontage: tea spills and stalls at the survey's densities
    for e in W.edges:
        if e["raised"] or e["L"] < M(40) or e["kind"] == "lane":
            continue
        for side in (1, -1):
            if not e["flush"] and e["h0"] < -0.5 and side == -1:
                continue
            for s in frontage_spots(e, side, M(TEA_EVERY), "tea"):
                pid = "teachair" if H("tc", e["id"], s) % 3 == 0 else "tealow%d" % (H("tl", e["id"], s) % 2)
                if place_on_side(e, side, s, pid, "tea", 0.0):
                    n_tea += 1
            for s in frontage_spots(e, side, M(STALL_EVERY), "stall"):
                pid = "betel" if H("bt", e["id"], s) % 3 == 0 else "cart%d" % (H("ct", e["id"], s) % 4)
                if place_on_side(e, side, s, pid, "stall", 0.4):
                    n_stall += 1
    # 3. stalls by the bus stops (a tea or betel stall is often within 10 m)
    for it in [i for i in W.items if i["kind"] == "busstop"]:
        hit = nearest_main(it["x"], it["z"], reach=M(12))
        if not hit:
            continue
        d, e, s0 = hit
        c, t, _ = at(e, s0)
        side = 1 if (it["x"] - c[0]) * (-t[1]) + (it["z"] - c[1]) * t[0] >= 0 else -1
        for ds in (M(10), -M(10), M(14)):
            if place_on_side(e, side, s0 + ds, "betel" if H("bsb", it["x"]) % 2 else "cart%d" % (H("bsc", it["x"]) % 4), "stall", 0.4):
                n_stall += 1
                break
    print("tea spills %d, stalls %d" % (n_tea, n_stall))


def trishaws():
    mains = [e for e in W.edges if e["traffic"]]
    mtree = STRtree([LineString(e["P"]).buffer(e["h1"] + e["walk"] + max(0.0, e["h0"]) + 4) for e in mains])
    n = stands = 0
    for e in W.edges:
        if not e["flush"] or e["raised"] or e["L"] < M(30):
            continue
        for end in (0, 1):
            p = e["P"][0] if end == 0 else e["P"][-1]
            if not len(mtree.query(Point(p).buffer(4), predicate="intersects")):
                continue
            if rnd("trim", e["id"], end) > TRISHAW_MOUTHS:
                continue
            side = 1 if H("tside", e["id"], end) % 2 else -1
            h, outer = side_offsets(e, side)
            made = 0
            allow = edge_strips(e)
            for k in range(3 + H("tn", e["id"], end) % 3):
                s = M(9) + k * 6.6 if end == 0 else e["L"] - M(9) - k * 6.6
                c, t, _ = at(e, s)
                # parked nose to tail along the edge, the sidecar (local +Z) on the outer side
                yaw = yaw_of(t[0], t[1])
                if ((-t[1]) * (-t[1] * side) + t[0] * (t[0] * side)) < 0:
                    yaw = yaw_of(-t[0], -t[1])
                for off in (outer - 2.6, outer - 1.6, outer + 0.4):
                    x, z = lateral(c, t, side * off)
                    g = foot("tri0", x, z, yaw, grow=0.05)
                    if W.clear_of(g, allow=allow):
                        W.put("trishaw", "tri%d" % (H("tc", e["id"], end, k) % 4), x, z, yaw, g)
                        made += 1
                        n += 1
                        break
            stands += 1 if made else 0
    print("trishaws %d at %d lane mouths" % (n, stands))


# =================================================================================================== 7. drains, fences, litter
def drains():
    n = 0
    for e in W.edges:
        if e["raised"] or e["L"] < M(12) or e["kind"] == "lane":
            continue
        for side in (1, -1):
            if not e["flush"] and e["h0"] < -0.5 and side == -1:
                continue
            h, outer = side_offsets(e, side)
            off = (outer - 1.0) if not e["flush"] else (outer + 1.05)
            allow = W.PAVE if not e["flush"] else None
            s = M(8)
            while s + DRAIN_PIECE < e["L"] - M(8):
                c0, t0, _ = at(e, s)
                c1, t1, _ = at(e, s + DRAIN_PIECE)
                if t0[0] * t1[0] + t0[1] * t1[1] < math.cos(math.radians(6)):
                    s += DRAIN_PIECE / 2
                    continue
                cm, tm, _ = at(e, s + DRAIN_PIECE / 2)
                x, z = lateral(cm, tm, side * off)
                yaw = yaw_of(tm[0], tm[1])
                g = rect(x, z, yaw, (-6.0, -0.95), (6.0, 0.95))
                if W.clear_of(g, allow=allow):
                    k = H("dr", e["id"], side, int(s))
                    pid = "draing" if k % 7 == 0 else ("drainb" if k % 5 == 0 else "draina")
                    if e["flush"]:
                        # top of the slabs 0.15 under the road edge, the walls into the ground
                        y = W.G.y(*lateral(cm, tm, side * (outer - 0.3)))[0] - 0.5
                    else:
                        y = W.G.y(x, z, ("P",))[0] - 0.36 + 0.07
                    W.put("drain", pid, x, z, yaw, g, y=y)
                    n += 1
                s += DRAIN_PIECE + 0.08
    print("drain pieces %d (%.1f km)" % (n, n * DRAIN_PIECE / 3000.0))


def fences():
    n = 0
    for e in W.edges:
        if not e["traffic"] or e["raised"] or e["h0"] >= -0.5:
            continue
        lead = e["P"][-1] - e["P"][0]
        if not (lead[0] > 0 or (abs(lead[0]) < 1e-6 and lead[1] > 0)):
            continue
        s = M(12)
        while s + 9 < e["L"] - M(12):
            c, t, _ = at(e, s + 4.5)
            c0, t0, _ = at(e, s)
            c1, t1, _ = at(e, s + 9)
            if t0[0] * t1[0] + t0[1] * t1[1] < math.cos(math.radians(4)):
                s += 4.5
                continue
            x, z = c
            yaw = yaw_of(t[0], t[1])
            g = rect(x, z, yaw, (-4.6, -0.3), (4.6, 0.3))
            # only on narrow medians (a railing; wide medians are planted)
            if W.MED.contains(g) and W.MED.intersection(Point(x, z).buffer(5.0)).area < 34 and W.clear_of(g, allow=W.MED):
                W.put("fence", "mfence", x, z, yaw, g, y=W.G.y(x, z, ("M",))[0])
                n += 1
            s += 9.06
    print("median railing pieces %d (%.2f km)" % (n, n * 9 / 3000.0))


def litter():
    n = 0
    EDGE.update({e["id"]: e for e in W.edges})
    for it in list(W.items):
        if it["kind"] != "pole" or rnd("lit", it["x"], it["z"]) > 0.3:
            continue
        for dx, dz in ((1.6, 0.8), (-1.6, 0.9), (1.4, -1.2)):
            x, z = it["x"] + dx, it["z"] + dz
            g = rect(x, z, 0.3, (-0.9, -0.8), (0.9, 0.8))
            e = EDGE[it["edge"]]
            if W.clear_of(g, allow=edge_strips(e) if e["flush"] else W.PAVE):
                W.put("litter", "litter", x, z, rnd("ly", x) * 6, g)
                n += 1
                break
    print("litter clumps %d" % n)


# =================================================================================================== write
def tile_of(x, z):
    return (int(math.floor(x / TILE)), int(math.floor(z / TILE)))


def pos(v, o):
    return enc((v - o + 16384) * 500, 4)


def ypos(v):
    return enc((v + 200) * 200, 3)


def write(atlas_meta):
    os.makedirs(OUT, exist_ok=True)
    detail = defaultdict(list)
    for it in W.items:
        detail[tile_of(it["x"], it["z"])].append(("P", it["pid"], it["x"], it["y"], it["z"], it["yaw"], it.get("sx", 1.0), "S"))
    pids, codes = {}, {"S": 0}
    for recs in detail.values():
        for r in recs:
            pids.setdefault(r[1], len(pids))
    extra = defaultdict(list)
    for w in W.wires:
        (x1, y1, z1, a1), (x2, y2, z2, a2) = w["a"], w["b"]
        i, j = tile_of(x1, z1)
        o = (i * TILE, j * TILE)
        extra[(i, j)].append("L" + pos(x1, o[0]) + ypos(y1) + pos(z1, o[1]) + _yaw(a1) + pos(x2, o[0]) + ypos(y2) +
                             pos(z2, o[1]) + _yaw(a2) + B64[w["n"]] + B64[w["seed"]])
    for w in W.drops:
        (x1, y1, z1), (x2, y2, z2) = w["a"], w["b"]
        i, j = tile_of(x1, z1)
        o = (i * TILE, j * TILE)
        extra[(i, j)].append("K" + pos(x1, o[0]) + ypos(y1) + pos(z1, o[1]) + pos(x2, o[0]) + ypos(y2) + pos(z2, o[1]) +
                             enc(w["sag"] * 100, 2))
    for p in W.plates:
        i, j = tile_of(p["x"], p["z"])
        o = (i * TILE, j * TILE)
        extra[(i, j)].append("T" + pos(p["x"], o[0]) + ypos(p["y"]) + pos(p["z"], o[1]) + _yaw(p["yaw"]) +
                             enc(p["w"] * 50, 2) + enc(p["h"] * 50, 2) + B64[p["atlas"]] + enc(p["cell"], 2))
    tiles = sorted(set(detail) | set(extra))
    items = [("Meta", "TILE=%g\nLOAD=%g\nPIDS=%s\nCODES=S\nATTACH=%s\n%s" % (
        TILE, LOAD, " ".join(sorted(pids, key=pids.get)),
        ";".join("%g,%g,%g" % tuple(a) for a in KMETA["ppolea"]["attach"]), atlas_meta))]
    chars = 0
    for (i, j) in tiles:
        s = kit_pack.pack_tile(detail.get((i, j), []), i * TILE, j * TILE, pids, codes) + "".join(extra.get((i, j), []))
        assert len(s) < 190000
        items.append(("%d_%d" % (i, j), s))
        chars += len(s)
    from xml.sax.saxutils import escape
    body = "".join('<Item class="StringValue" referent="R%d"><Properties><string name="Name">%s</string>'
                   '<string name="Value">%s</string></Properties></Item>' % (k + 2, n, escape(v)) for k, (n, v) in enumerate(items))
    x = ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
         'version="4"><Item class="Folder" referent="R1"><Properties><string name="Name">Data_%sS</string></Properties>%s</Item>'
         '</roblox>' % (TAG, body))
    os.makedirs(GLB, exist_ok=True)
    path = os.path.join(GLB, "ygnstreet_%s.rbxmx" % TAG.lower())
    open(path, "w", encoding="utf-8", newline="\n").write(x)
    json.dump(dict(items=W.items, wires=W.wires, drops=W.drops, plates=W.plates), open(os.path.join(OUT, "items.json"), "w"))
    return dict(path=path, chars=chars, tiles=len(tiles), bytes=len(x.encode("utf-8")), pids=len(pids))


def preview(path):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, ax = plt.subplots(figsize=(14, 14))
    for g in W.BLDS[::2]:
        ax.fill(*g.exterior.xy, color="#cccccc", lw=0)
    for b in W.boxes:
        if b["kind"] in ("R", "J"):
            ax.fill(*b["poly"].exterior.xy, color="#555555", lw=0)
        elif b["kind"] == "P":
            ax.fill(*b["poly"].exterior.xy, color="#999999", lw=0)
    col = dict(pole="k", lamp="#3070ff", signal="r", busstop="#00a0a0", sign="g", tea="#ff8800", stall="#ff00aa",
               trishaw="#880000", drain="#bbaa88", fence="#7777ff", bin="#ff8800", litter="#aaaaaa")
    for k, c in col.items():
        xs = [i["x"] for i in W.items if i["kind"] == k]
        zs = [i["z"] for i in W.items if i["kind"] == k]
        ax.scatter(xs, zs, s=3 if k in ("pole", "drain") else 9, c=c, label="%s %d" % (k, len(xs)))
    for w in W.wires[::1]:
        ax.plot([w["a"][0], w["b"][0]], [w["a"][2], w["b"][2]], color="k", lw=0.3)
    ax.set_aspect("equal")
    ax.invert_yaxis()
    ax.legend(loc="upper right", fontsize=8)
    plt.savefig(path, dpi=110)


def main():
    global W
    t0 = time.time()
    W = World()
    atlas_path = os.path.join(OUT, "atlas.json")
    atlas, atlas_meta = {}, ""
    if os.path.exists(atlas_path):
        A = json.load(open(atlas_path, encoding="utf-8"))
        for c in A["cells"]:
            atlas[tuple(c["key"])] = (c["atlas"], c["cell"])
        atlas_meta = "ATLAS=%s\nCELL=%d %d %d\n" % (" ".join(A["ids"]) if A.get("ids") else "-", A["cw"], A["ch"], A["cols"])
    items = osm_items()
    lamps()          # lamps and signals first: they need the kerb spots
    signals(items)
    bus_stops(items, atlas)
    name_signs(atlas)
    poles()
    trishaws()
    street_life(items)
    fences()
    drains()
    litter()
    info = write(atlas_meta)
    km = sum(e["L"] for e in W.edges if not e["raised"]) / 3000.0
    area = geo.batch_poly(TAG).area / 9e6
    tris = sum(KMETA[i["pid"]]["tris"] for i in W.items)
    st = dict(W.stats)
    st.update(road_km=round(km, 1), area_km2=round(area, 2), items=len(W.items), wires=len(W.wires), drops=len(W.drops),
              plates=len(W.plates), item_tris=tris, per_km={k: round(v / km, 1) for k, v in Counter(i["kind"] for i in W.items).items()},
              unique_meshes=sum(len(v["parts"]) for v in KMETA.values()), seconds=round(time.time() - t0), **info)
    st["parts"] = sum(len(KMETA[i["pid"]]["parts"]) for i in W.items)
    json.dump(st, open(os.path.join(OUT, "stats.json"), "w"), indent=1)
    preview(os.path.join(OUT, "preview.png"))
    print(json.dumps(st, indent=1))


if __name__ == "__main__":
    main()
