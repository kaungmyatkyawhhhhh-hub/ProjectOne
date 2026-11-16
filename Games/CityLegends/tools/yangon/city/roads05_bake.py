"""Bake the 1:1 roads built by the batch 0.5 builder into meshes (16 Nov 2026, roads05).

Studio builds the roads cell by cell with YangonRoads.stepCell (parts), RoadBake05.collect / page sends them out as
pages ("@P<cell>_<kk>@ ... @END@", MCP results saved in the session's tool-results folder), and the parts are deleted.
This script reads every page, turns the parts into visible faces, adds the paint (roads05_paint.py's polygons, laid
0.08 over the road surface they sit on), cuts everything into 1536-stud cells per kind (YangonRoadMeshes' kinds: R
asphalt, P pavement, KR / KW kerb bands, MG median / island grass, B bridge concrete, L white paint, LY yellow paint),
writes .glb files (<= 100 meshes, <= 90,000 triangles each; meshes named KIND_<cell>s<k>_<box> as glb.code) and the
collision boxes (RoadBake05.collide lines: kind cx cy cz rx ry rz ux uy uz sx sy sz).

    YANGON_SCALE=1to1 python roads05_bake.py <tags joined by _> collect <tool-results folder> [more folders]
    YANGON_SCALE=1to1 python roads05_bake.py <tags joined by _> bake
-> build/city_1to1/roads05_<tags>/parts.pkl, glb/roads05_<n>.glb, collide/Collide05_<n>.txt, bake_stats.json
"""
import collections, glob, json, math, os, pickle, re, sys

import numpy as np
import shapely
from shapely.geometry import Polygon, Point, LineString, box as sbox
from shapely.strtree import STRtree

sys.stdout.reconfigure(encoding='utf-8')
import geo
from glb import Mesh, write_glb, code

BASE = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!#$%&()*+,-./:;<=>?@[]^_{|}"
NB = len(BASE)
HALF = (NB * NB * NB - 1) // 2
IDX = {c: i for i, c in enumerate(BASE)}
CELL = 1536.0
MAX_TRIS = 17000
FILE_TRIS = 90000
FILE_MESHES = 100
LIFT = 0.08
KIND = {'R': 'R', 'P': 'P', 'r': 'KR', 'w': 'KW', 'm': 'MG', 'B': 'B'}
WHITE = (255, 255, 255)


def od(tag):
    return os.path.join(geo.BUILD, 'city_1to1', 'roads05_' + tag)


# ------------------------------------------------------------------------------------------------ pages
def decode(s):
    """part records -> list of (kind, cls, pos, R, U, size)"""
    out = []
    i = 0
    n = len(s)
    px = py = pz = 0

    def num():
        nonlocal i
        if s[i] == '~':
            j = s.index('~', i + 1)
            v = int(s[i + 1:j])
            i = j + 1
            return v
        v = IDX[s[i]] * NB * NB + IDX[s[i + 1]] * NB + IDX[s[i + 2]] - HALF
        i += 3
        return v
    while i < n:
        k, c = s[i], s[i + 1]
        i += 2
        v = [num() for _ in range(12)]
        px += v[0]
        py += v[1]
        pz += v[2]
        out.append((k, c, (px / 100, py / 100, pz / 100), (v[3] / 1e5, v[4] / 1e5, v[5] / 1e5),
                    (v[6] / 1e5, v[7] / 1e5, v[8] / 1e5), (v[9] / 100, v[10] / 100, v[11] / 100)))
    return out


H2 = (NB * NB - 1) // 2


def decode_q(s):
    """v2 pages (@Q): 2-character numbers; position delta x100, rotation quaternion x, y, z x4000 (w >= 0), size x100"""
    out = []
    i = 0
    n = len(s)
    px = py = pz = 0

    def num():
        nonlocal i
        if s[i] == '~':
            j = s.index('~', i + 1)
            v = int(s[i + 1:j])
            i = j + 1
            return v
        v = IDX[s[i]] * NB + IDX[s[i + 1]] - H2
        i += 2
        return v
    while i < n:
        k, c = s[i], s[i + 1]
        i += 2
        v = [num() for _ in range(9)]
        px += v[0]
        py += v[1]
        pz += v[2]
        x, y, z = v[3] / 4000, v[4] / 4000, v[5] / 4000
        w = math.sqrt(max(0.0, 1 - x * x - y * y - z * z))
        R = (1 - 2 * (y * y + z * z), 2 * (x * y + w * z), 2 * (x * z - w * y))
        U = (2 * (x * y - w * z), 1 - 2 * (x * x + z * z), 2 * (y * z + w * x))
        out.append((k, c, (px / 100, py / 100, pz / 100), R, U, (v[6] / 100, v[7] / 100, v[8] / 100)))
    return out


def read_pages(folders):
    pages = {}
    for f in folders:
        for p in glob.glob(os.path.join(f, '*')):
            if not (p.endswith('.txt') or p.endswith('.json')) or os.path.getsize(p) < 1000:
                continue
            raw = open(p, encoding='utf-8', errors='replace').read()
            if p.endswith('.json') or raw.startswith('['):
                try:
                    raw = ''.join(x.get('text', '') for x in json.loads(raw))
                except Exception:
                    pass
            m = re.search(r'@([PQ])([A-Za-z0-9_\-]+?)_(\d\d)@', raw[:200])
            if not m:
                continue
            body = raw[m.end():]
            e = body.find('@END@')
            if e < 0:
                print('page without end:', p)
                continue
            key = (m.group(2), int(m.group(3)))
            if key not in pages or os.path.getmtime(p) > pages[key][0]:
                pages[key] = (os.path.getmtime(p), body[:e], m.group(1))
    return pages


# ------------------------------------------------------------------------------------------------ faces
def frame(pos, R, U):
    R = np.array(R, float)
    U = np.array(U, float)
    R /= np.linalg.norm(R)
    U = U - R * (U @ R)
    U /= np.linalg.norm(U)
    Bk = np.cross(R, U)       # Roblox ZVector = X x Y
    return np.array(pos, float), R, U, Bk


def faces_of(part, surf=None):
    """visible faces as triangles [(a, b, c)], counter-clockwise from outside"""
    k, cls, pos, R, U, S = part
    c, R, U, Bk = frame(pos, R, U)
    hx, hy, hz = S[0] / 2, S[1] / 2, S[2] / 2

    def P(x, y, z):
        return c + R * x + U * y + Bk * z
    tris = []
    if cls == 'B':
        v = {(sx, sy, sz): P(sx * hx, sy * hy, sz * hz) for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)}
        quads = [
            ((-1, 1, -1), (-1, 1, 1), (1, 1, 1), (1, 1, -1)),      # +Y
            ((1, -1, -1), (1, 1, -1), (1, 1, 1), (1, -1, 1)),      # +X
            ((-1, -1, 1), (-1, 1, 1), (-1, 1, -1), (-1, -1, -1)),  # -X
            ((-1, -1, 1), (1, -1, 1), (1, 1, 1), (-1, 1, 1)),      # +Z
            ((1, -1, -1), (-1, -1, -1), (-1, 1, -1), (1, 1, -1)),  # -Z
            ((-1, -1, -1), (1, -1, -1), (1, -1, 1), (-1, -1, 1)),  # -Y
        ]
        # thin flat pieces (pavement slabs, medians, kerbs): every face but the bottom; bridge pieces: all six
        # (kerbs, pavements, medians: the face looking up, and of the side faces only the long ones that show: a kerb's
        # face to the road, a pavement's outer edge, a median's two sides; never the bottom. The builder lays some
        # pieces on their side (Size.X up), so faces are picked by their world normal, not by the part's axes)
        if k == 'B':
            use = quads
        else:
            use = []
            hl = {}
            for q in quads:
                a, b, cc, d = (v[x] for x in q)
                e = [b - a, cc - b]
                hl[q] = max(math.hypot(x[0], x[2]) for x in e if abs(x[1]) < 0.5 * np.linalg.norm(x) + 1e-9) if any(abs(x[1]) < 0.5 * np.linalg.norm(x) + 1e-9 for x in e) else 0.0
            for q in quads:
                a, b, cc, d = (v[x] for x in q)
                t = fix((a, b, cc), c)
                n = np.cross(t[1] - t[0], t[2] - t[0])
                L = np.linalg.norm(n)
                if L < 1e-9:
                    continue
                n = n / L
                if n[1] > 0.5:
                    use.append(q)
                    continue
                if n[1] < -0.5:
                    continue
                # a side: skip the short ends
                longest = max(hl[x] for x in quads)
                if hl[q] < 0.6 * longest:
                    continue
                fc = (a + b + cc + d) / 4
                if surf is None or k == 'm':
                    use.append(q)
                    continue
                probe = fc + n * 1.0
                road_there = bool(surf.heights(probe[0], probe[2]))
                if k == 'P':
                    probe2 = fc + n * 2.5
                    road_there = road_there or bool(surf.heights(probe2[0], probe2[2]))
                    if not road_there:
                        use.append(q)
                elif road_there:
                    use.append(q)
        for q in use:
            a, b, cc, d = (v[x] for x in q)
            tris.append(fix((a, b, cc), c))
            tris.append(fix((a, cc, d), c))
    elif cls == 'W':
        # Roblox wedge: bottom face, the vertical back face at +Z, the slope from the top back edge down to the front
        # bottom edge; its two side faces (+-X) are right triangles (-hy, -hz), (-hy, +hz), (+hy, +hz)
        sides = []
        for sx in (-1, 1):
            t = (P(sx * hx, -hy, -hz), P(sx * hx, -hy, hz), P(sx * hx, hy, hz))
            sides.append(t)
        if k in ('R', 'P', 'm'):
            # Roads.triangle: the road triangle is one side face; keep the upper one
            top = max(sides, key=lambda t: sum(p[1] for p in t))
            tris.append(fix(top, c))
        else:
            for t in sides:
                tris.append(fix(t, c))
            a, b = P(-hx, hy, hz), P(hx, hy, hz)
            d0, d1 = P(-hx, -hy, -hz), P(hx, -hy, -hz)
            tris.append(fix((a, b, d1), c))
            tris.append(fix((a, d1, d0), c))
            e0, e1 = P(-hx, -hy, hz), P(hx, -hy, hz)
            tris.append(fix((a, e0, e1), c))
            tris.append(fix((a, e1, b), c))
    elif cls == 'C':
        # a cylinder along its X axis: the upper cap and the side
        n = 48
        top = c + R * hx if (R[1] >= 0) else c - R * hx
        bot = c - R * hx if (R[1] >= 0) else c + R * hx
        rr = min(hy, hz)
        ring_t, ring_b = [], []
        for j in range(n):
            a = 2 * math.pi * j / n
            off = U * (rr * math.cos(a)) + Bk * (rr * math.sin(a))
            ring_t.append(top + off)
            ring_b.append(bot + off)
        for j in range(n):
            tris.append(fix((top, ring_t[j], ring_t[(j + 1) % n]), bot))
            tris.append(fix((ring_t[j], ring_b[j], ring_b[(j + 1) % n]), c))
            tris.append(fix((ring_t[j], ring_b[(j + 1) % n], ring_t[(j + 1) % n]), c))
    elif cls == 'S':
        # a sphere-mesh dome (the island's mound): the upper half of the ellipsoid
        nr, na = 6, 48
        rows = []
        for i in range(nr + 1):
            th = (math.pi / 2) * i / nr
            row = []
            for j in range(na):
                a = 2 * math.pi * j / na
                row.append(c + R * (hx * math.cos(th) * math.cos(a)) + Bk * (hz * math.cos(th) * math.sin(a)) + U * (hy * math.sin(th)))
            rows.append(row)
        for i in range(nr):
            for j in range(na):
                a, b = rows[i][j], rows[i][(j + 1) % na]
                cc, d = rows[i + 1][(j + 1) % na], rows[i + 1][j]
                tris.append(fix((a, b, cc), c))
                tris.append(fix((a, cc, d), c))
    return tris


def fix(t, inside):
    """counter-clockwise seen from outside: flip when the normal points at `inside`"""
    a, b, c = (np.asarray(p, float) for p in t)
    n = np.cross(b - a, c - a)
    mid = (a + b + c) / 3
    if n @ (mid - np.asarray(inside, float)) < 0:
        return (a, c, b)
    # a flat top face (the inside point lies on its plane): face up
    if abs(n @ (mid - np.asarray(inside, float))) < 1e-9 and n[1] < 0:
        return (a, c, b)
    return (a, b, c)


def up_fix(t):
    a, b, c = t
    n = np.cross(b - a, c - a)
    return (a, c, b) if n[1] < 0 else t


# ------------------------------------------------------------------------------------------------ collect
def collect(tag, folders):
    pages = read_pages(folders)
    cells = collections.defaultdict(dict)
    for (cell, k), (_, body, fmt) in pages.items():
        cells[cell][k] = (fmt, body)
    parts = []
    report = {}
    for cell, pg in sorted(cells.items()):
        ks = sorted(pg)
        missing = [k for k in range(1, max(ks) + 1) if k not in pg]
        ps = []
        fmts = set(pg[k][0] for k in ks)
        if len(fmts) > 1:
            print('cell %s mixes page formats %s: only Q kept' % (cell, fmts))
            ks = [k for k in ks if pg[k][0] == 'Q']
        for k in ks:
            fmt, body = pg[k]
            ps.extend(decode_q(body) if fmt == 'Q' else decode(body))
        report[cell] = dict(pages=len(ks), missing=missing, parts=len(ps))
        parts.extend(ps)
    pickle.dump(parts, open(os.path.join(od(tag), 'parts.pkl'), 'wb'))
    print(json.dumps(report, indent=1))
    print('parts', len(parts))
    return parts


# ------------------------------------------------------------------------------------------------ bake
def cell_of(x, z):
    return '%dx%d' % (math.floor(x / CELL), math.floor(z / CELL))


def uv_of(p, n):
    ax = np.argmax(np.abs(n))
    if ax == 1:
        return (p[0], p[2])
    if ax == 0:
        return (p[2], p[1])
    return (p[0], p[1])


class Surface:
    """the road surface (R top triangles) for paint heights"""

    def __init__(self, tris):
        self.T = [t for t in tris if abs(np.cross(t[1] - t[0], t[2] - t[0])[1]) > 1e-6]
        self.polys = [Polygon([(p[0], p[2]) for p in t]) for t in self.T]
        self.tree = STRtree(self.polys)

    def heights(self, x, z):
        pt = Point(x, z)
        out = []
        for j in self.tree.query(pt.buffer(0.05)):
            t = self.T[int(j)]
            y = bary_y(t, x, z)
            if y is not None:
                out.append(y)
        return out

    def near(self, x, z, reach=2.0):
        pt = Point(x, z)
        best = None
        for j in self.tree.query(pt.buffer(reach)):
            d = self.polys[int(j)].distance(pt)
            if best is None or d < best[0]:
                best = (d, int(j))
        if best is None:
            return None
        t = self.T[best[1]]
        return plane_y(t, x, z)


def bary_y(t, x, z, tol=0.02):
    a, b, c = t
    v0 = np.array([b[0] - a[0], b[2] - a[2]])
    v1 = np.array([c[0] - a[0], c[2] - a[2]])
    v2 = np.array([x - a[0], z - a[2]])
    d = v0[0] * v1[1] - v1[0] * v0[1]
    if abs(d) < 1e-12:
        return None
    u = (v2[0] * v1[1] - v1[0] * v2[1]) / d
    w = (v0[0] * v2[1] - v2[0] * v0[1]) / d
    if u < -tol or w < -tol or u + w > 1 + tol:
        return None
    return a[1] + u * (b[1] - a[1]) + w * (c[1] - a[1])


def plane_y(t, x, z):
    a, b, c = t
    n = np.cross(b - a, c - a)
    if abs(n[1]) < 1e-9:
        return a[1]
    return a[1] - (n[0] * (x - a[0]) + n[2] * (z - a[2])) / n[1]


def densify_ring(coords, step=3.0):
    out = []
    for i in range(len(coords) - 1):
        a, b = np.array(coords[i]), np.array(coords[i + 1])
        L = np.linalg.norm(b - a)
        n = max(1, int(math.ceil(L / step)))
        for k in range(n):
            out.append(tuple(a + (b - a) * k / n))
    out.append(tuple(coords[-1]))
    return out


def paint_tris(items, surf, deck_surf):
    out = {'L': [], 'LY': []}
    dropped = 0
    for it in items:
        pg = Polygon(it['p'])
        if not pg.is_valid:
            pg = pg.buffer(0)
        if pg.is_empty:
            continue
        geoms = [pg] if pg.geom_type == 'Polygon' else list(pg.geoms)
        for g in geoms:
            g = Polygon(densify_ring(list(g.exterior.coords)))
            if not g.is_valid:
                g = g.buffer(0)
                if g.is_empty or g.geom_type != 'Polygon':
                    continue
            try:
                tri = shapely.constrained_delaunay_triangles(g)
            except Exception:
                tri = shapely.ops.triangulate(g)
            parts = list(tri.geoms) if hasattr(tri, 'geoms') else [tri]
            kind = 'L' if it['k'] == 'LW' else 'LY'
            S = deck_surf if it.get('deck') else surf
            for t in parts:
                if t.area < 1e-4:
                    continue
                cs = list(t.exterior.coords)[:3]
                pts = []
                ok = True
                for x, z in cs:
                    hs = S.heights(x, z)
                    if hs:
                        y = max(hs) if it.get('deck') else min(hs)
                    else:
                        y = S.near(x, z)
                        if y is None:
                            ok = False
                            break
                    pts.append(np.array([x, y + LIFT, z]))
                if not ok:
                    dropped += 1
                    continue
                out[kind].append(up_fix(tuple(pts)))
    return out, dropped


def bake(tag):
    D = od(tag)
    parts = pickle.load(open(os.path.join(D, 'parts.pkl'), 'rb'))
    data = json.load(open(os.path.join(D, 'roads.json'), encoding='utf-8'))
    paint = json.load(open(os.path.join(D, 'paint.json')))['items']
    by = collections.defaultdict(list)       # (kind, cell) -> triangles
    road_tris = []
    deck_box = []
    for d in data.get('decks', []):
        xs = [q[0] for q in d['s']]
        zs = [q[2] for q in d['s']]
        deck_box.append(sbox(min(xs), min(zs), max(xs), max(zs)).buffer(d.get('half', 24) + 4))
    n_unknown = 0
    for p in parts:
        if p[0] == 'R':
            for t in faces_of(p):
                mid = (t[0] + t[1] + t[2]) / 3
                by[('R', cell_of(mid[0], mid[2]))].append(t)
                road_tris.append(t)
    surf = Surface(road_tris)
    for p in parts:
        k = p[0]
        if k == 'R':
            continue
        if k not in KIND:
            n_unknown += 1
            continue
        for t in faces_of(p, surf):
            mid = (t[0] + t[1] + t[2]) / 3
            by[(KIND[k], cell_of(mid[0], mid[2]))].append(t)
    ptris, dropped = paint_tris(paint, surf, surf)
    for kind, ts in ptris.items():
        for t in ts:
            mid = (t[0] + t[1] + t[2]) / 3
            by[(kind, cell_of(mid[0], mid[2]))].append(t)
    # meshes
    gdir = os.path.join(D, 'glb')
    os.makedirs(gdir, exist_ok=True)
    for f in glob.glob(os.path.join(gdir, '*.glb')):
        os.remove(f)
    named = []
    tri_count = collections.Counter()
    for (kind, cell), ts in sorted(by.items()):
        for s0 in range(0, len(ts), MAX_TRIS):
            chunk = ts[s0:s0 + MAX_TRIS]
            m = Mesh()
            P = np.array([p for t in chunk for p in t])
            lo, hi = P.min(0), P.max(0)
            centre = (lo + hi) / 2
            size = np.maximum(hi - lo, 0.05)
            assert size.max() <= 2048, (kind, cell, size)
            for t in chunk:
                n = np.cross(t[1] - t[0], t[2] - t[0])
                L = np.linalg.norm(n)
                if L < 1e-9:
                    continue
                uv = [uv_of(p, n) for p in t]
                m.tri(tuple(t[0]), tuple(t[1]), tuple(t[2]), uv[0], uv[1], uv[2], WHITE)
            name = code(kind, '%ss%d' % (cell, s0 // MAX_TRIS), tuple(centre), tuple(size))
            named.append((name, m, len(chunk)))
            tri_count[kind] += len(chunk)
    files = []
    cur, ct = [], 0
    for item in named:
        if cur and (len(cur) >= FILE_MESHES or ct + item[2] > FILE_TRIS):
            files.append(cur)
            cur, ct = [], 0
        cur.append(item)
        ct += item[2]
    if cur:
        files.append(cur)
    for i, f in enumerate(files):
        write_glb(os.path.join(gdir, 'roads05_%d.glb' % (i + 1)), [(nm, m) for nm, m, _ in f], generator='roads05_bake.py')
    # collision
    rows = collision(data, surf, parts)
    cdir = os.path.join(D, 'collide')
    os.makedirs(cdir, exist_ok=True)
    for f in glob.glob(os.path.join(cdir, '*.txt')):
        os.remove(f)
    k, buf, n = 1, [], 0
    for r in rows:
        buf.append(r)
        n += len(r) + 1
        if n > 180000:
            open(os.path.join(cdir, 'Collide05_%d.txt' % k), 'w', newline='\n').write('\n'.join(buf))
            k, buf, n = k + 1, [], 0
    if buf:
        open(os.path.join(cdir, 'Collide05_%d.txt' % k), 'w', newline='\n').write('\n'.join(buf))
    st = dict(parts=len(parts), unknown=n_unknown, meshes=len(named), files=len(files), triangles=dict(tri_count),
              paint_dropped=dropped, collision_boxes=len(rows), collide_files=k)
    json.dump(st, open(os.path.join(D, 'bake_stats.json'), 'w'), indent=1)
    print(json.dumps(st, indent=1))


# ------------------------------------------------------------------------------------------------ collision
def box_row(kind, c, R, U, S):
    return '%s %.2f %.2f %.2f %.4f %.4f %.4f %.4f %.4f %.4f %.2f %.2f %.2f' % ((kind,) + tuple(c) + tuple(R) + tuple(U) + tuple(S))


def collision(data, surf, parts):
    """carriageway and pavement boxes along each road (runs of up to MERGE samples while straight), the ring, decks
    from their surface, bridge pieces (walls, piers) as their own boxes"""
    rows = []
    cut = {k: set(v) for k, v in data['cut'].items()}
    THK = 2.0
    for r in data['roads']:
        s = r['s']
        c = cut.get(r['name'], set())
        n = len(s)
        i = 0
        while i < n - 1:
            if i in c or (i + 1) in c:
                i += 1
                continue
            # extend while straight (heading within 2 degrees) and the width the same
            j = i + 1
            while j + 1 < n and j + 1 not in c and j - i < 12:
                d0 = np.array([s[i + 1][0] - s[i][0], s[i + 1][2] - s[i][2]])
                d1 = np.array([s[j + 1][0] - s[j][0], s[j + 1][2] - s[j][2]])
                if np.linalg.norm(d0) < 1e-6 or np.linalg.norm(d1) < 1e-6:
                    break
                cosang = d0 @ d1 / np.linalg.norm(d0) / np.linalg.norm(d1)
                if cosang < math.cos(math.radians(2)) or abs(s[j + 1][6] - s[i][6]) > 0.3 or abs(s[j + 1][7] - s[i][7]) > 0.3:
                    break
                j += 1
            a, b = s[i], s[j]
            spans = [(-a[6], a[7], 'R', 0.0)]
            if r['kind'] != 'street':
                spans += [(-a[6] - r.get('walkL', 7.5), -a[6], 'P', 0.5), (a[7], a[7] + r.get('walkR', 7.5), 'P', 0.5)]
            for lat_lo, lat_hi, kind, up in spans:
                rows.extend(strip_box(a, b, lat_lo, lat_hi, kind, up, surf, THK))
            i = j
    # roundabouts: 48 boxes round the ring, 48 round the pavement, an island disc of boxes
    for g in data.get('roundabouts', []):
        cx, cy, cz = g['c']
        n = 48
        for j in range(n):
            a0 = 2 * math.pi * j / n
            a1 = 2 * math.pi * (j + 1) / n
            am = (a0 + a1) / 2
            for r0, r1, kind, up in ((g['r_in'], g['r_out'], 'R', 0.0), (g['r_out'], g['r_out'] + 7.5, 'P', 0.5)):
                rm = (r0 + r1) / 2
                L = 2 * rm * math.sin(math.pi / n) + 0.6
                R = np.array([math.cos(am), 0, math.sin(am)])
                Bk = np.array([-math.sin(am), 0, math.cos(am)])
                ctr = np.array([cx + rm * math.cos(am), cy + up - THK / 2, cz + rm * math.sin(am)])
                rows.append(box_row(kind, ctr, R, (0, 1, 0), (r1 - r0, THK, L)))
        ri = g['r_in'] * 0.7
        for k in range(-2, 3):
            for m in range(-2, 3):
                x, z = cx + k * ri / 2.5, cz + m * ri / 2.5
                if math.hypot(x - cx, z - cz) < g['r_in'] - ri / 5:
                    rows.append(box_row('M', (x, cy + 0.45 - 1.5, z), (1, 0, 0), (0, 1, 0), (ri / 2.5 + 0.2, 3, ri / 2.5 + 0.2)))
    # decks: boxes along the deck from its own surface
    for d in data.get('decks', []):
        s = d['s']
        for i in range(0, len(s) - 1, 2):
            j = min(len(s) - 1, i + 2)
            rows.extend(strip_box(s[i], s[j], -s[i][6], s[i][7], 'D', 0.0, surf, 2.0, prefer='max'))
    # bridge pieces (parapets, ramp walls, girders, pier caps, piers): their own boxes
    for p in parts:
        if p[0] == 'B' and p[1] == 'B':
            c, R, U, Bk = frame(p[2], p[3], p[4])
            rows.append(box_row('W', c, R, U, p[5]))
    return rows


def strip_box(a, b, lo, hi, kind, up, surf, thick, prefer='min'):
    pa = np.array([a[0], a[1], a[2]])
    pb = np.array([b[0], b[1], b[2]])
    fwd = pb - pa
    fwd[1] = 0
    L = np.linalg.norm(fwd)
    if L < 0.3 or hi - lo < 0.3:
        return []
    fwd /= L
    right = np.array([-fwd[2], 0, fwd[0]])
    mid_lat = (lo + hi) / 2

    def top(p):
        hs = surf.heights(p[0], p[2])
        if hs:
            return (max(hs) if prefer == 'max' else min(hs))
        return None
    ya = top(pa + right * mid_lat)
    yb = top(pb + right * mid_lat)
    if ya is None:
        ya = a[1]
    if yb is None:
        yb = b[1]
    ya += up
    yb += up
    A = pa + right * mid_lat
    Bp = pb + right * mid_lat
    A[1], Bp[1] = ya, yb
    d = Bp - A
    length = np.linalg.norm(d)
    fw = d / length
    U = np.cross(fw, right)
    if U[1] < 0:
        U = -U
    # box: X = right (width), Y = U (thickness), Z = along; the top face passes through A and Bp
    ctr = (A + Bp) / 2 - U * (thick / 2)
    Rr = right
    return [box_row(kind, ctr, Rr, U, (hi - lo, thick, length + 0.3))]


if __name__ == '__main__':
    tag, cmd = sys.argv[1], sys.argv[2]
    if cmd == 'collect':
        collect(tag, sys.argv[3:])
    elif cmd == 'bake':
        bake(tag)
