"""Automatic version of convert_car.py: turns a downloaded car (.glb) into game-ready geometry
without a hand-made layout file. It finds, by shape:

  * the car's size and axes (stray props, floors and backdrops dropped)
  * the four road wheels (round parts at the corners) and the wheelbase -> real size in metres
  * the steering wheel (a ring of ~37 cm in front of a front seat) -> which way is the front
    (a steering wheel leans forward at the top) and which side the driver sits

then lays the car out like convert_car.py does (front along -Y, up +Z, metres, ground at 0): a
"SteeringWheel" part with its own tilted frame, FL/FR/RL/RR wheels in a "Wheels" group, glass named
"SeeThrough_*", one part per material, plain colours baked into tiny textures, every part under
~18,000 triangles and the whole car under a triangle budget.

    python tools/auto_car.py imports/car.glb <real wheelbase in metres> out.blend ['{"tilt": 20}']
Writes a .blend (for checking renders) and a JSON report; tools/pack_cars.py puts several
.blend cars into one .fbx, one group per car id, for a single Import 3D in Studio.
"""

import json
import math
import sys

import bpy  # first: bmesh comes with it
import bmesh
import numpy as np
from mathutils import Matrix, Vector
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import connected_components

MAX_TRIS = 18000
BUDGET = 160000  # triangles for the whole car
DEBUG = False


def tris(o) -> int:
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


def meshes():
    return [o for o in bpy.data.objects if o.type == "MESH"]


def separate(o, pick: set):
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bm.verts.ensure_lookup_table()
    for v in bm.verts:
        v.select = v.index in pick
    for e in bm.edges:
        e.select = all(v.index in pick for v in e.verts)
    for f in bm.faces:
        f.select = all(v.index in pick for v in f.verts)
    bm.to_mesh(o.data)
    bm.free()
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = o
    o.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    try:
        bpy.ops.mesh.separate(type="SELECTED")
    except RuntimeError:
        pass
    bpy.ops.object.mode_set(mode="OBJECT")
    new = [x for x in bpy.context.selected_objects if x != o]
    return new[0] if new else None


def join(objs, name):
    objs = [o for o in objs if o and o.name in bpy.data.objects]
    if not objs:
        return None
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active
    o.name = name
    return o


def verts_world(o):
    n = len(o.data.vertices)
    co = np.empty(n * 3)
    o.data.vertices.foreach_get("co", co)
    return co.reshape(n, 3)


def load(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    for o in meshes():
        mw = o.matrix_world.copy()
        o.parent = None
        o.data = o.data.copy()
        o.data.transform(mw)
        o.matrix_world = Matrix.Identity(4)
    for o in list(bpy.data.objects):
        if o.type != "MESH" or len(o.data.polygons) == 0:
            bpy.data.objects.remove(o, do_unlink=True)


def align_yaw(turn=None):
    """Some files have the car turned on the ground: turn it so its length runs along an axis.
    Returns the turn in degrees; pass it back in to turn a fresh copy the same way."""
    if turn is None:
        allv = np.concatenate([verts_world(o) for o in meshes()])
        xy = allv[:, :2] - allv[:, :2].mean(axis=0)
        _, vecs = np.linalg.eigh(np.cov(xy.T))
        ang = math.atan2(vecs[1, 1], vecs[0, 1])  # the long direction
        turn = -ang + round(ang / (math.pi / 2)) * (math.pi / 2)  # to the nearest axis
        if abs(turn) < math.radians(4):  # small: just uneven insides (a door open, the wheel on one side)
            return 0.0
    else:
        turn = math.radians(turn)
        if turn == 0:
            return 0.0
    R = Matrix.Rotation(turn, 4, "Z")
    for o in meshes():
        o.data.transform(R)
    return math.degrees(turn)


def drop_props():
    """Floors, backdrops and stray objects: anything much bigger than the car or outside it (the
    car's extent from the middle 90% of all points, so a big prop can't stretch it)."""
    allv = np.concatenate([verts_world(o) for o in meshes()])
    lo = np.percentile(allv, 5, axis=0)
    hi = np.percentile(allv, 95, axis=0)
    size = hi - lo
    pad = size * 0.3
    dropped = []
    for o in list(meshes()):
        v = verts_world(o)
        a, b = v.min(axis=0), v.max(axis=0)
        c = (a + b) / 2
        too_big = np.any((b - a) > size * 1.6)
        outside = np.any(c < lo - pad) or np.any(c > hi + pad)
        if too_big or outside:
            dropped.append(o.name)
            bpy.data.objects.remove(o, do_unlink=True)
    return dropped


def smooth_normals(o):
    """After a mesh is thinned out its stored normals no longer fit and glossy paint shows every
    facet: smooth shading again, with sharp edges only where faces meet at a real angle."""
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = o
    o.select_set(True)
    try:
        bpy.ops.mesh.customdata_custom_splitnormals_clear()
    except RuntimeError:
        pass
    o.data.shade_smooth()
    o.data.set_sharp_from_angle(angle=math.radians(35))


def weld(o, dist):
    """glTF stores a mesh cut open at every seam: join it up again (a mesh thinned out while cut
    open comes out crumpled under glossy paint)."""
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=dist)
    bm.to_mesh(o.data)
    bm.free()


def decimate(o, ratio, dist=None):
    if dist:
        weld(o, dist)
    bpy.context.view_layer.objects.active = o
    m = o.modifiers.new("shrink", "DECIMATE")
    m.ratio = ratio
    bpy.ops.object.modifier_apply(modifier="shrink")
    if dist:
        smooth_normals(o)


def decimate_to(budget, final=True, keep=()):
    """Thin the car out to the triangle budget. final=False is a quick thinning for the search
    only (seams left open, so a steering wheel isn't joined to its neighbours)."""
    total = sum(tris(o) for o in meshes())
    if total <= budget:
        return total
    k = budget / total
    allv = np.concatenate([verts_world(o) for o in meshes()])
    dist = float(np.max(allv.max(axis=0) - allv.min(axis=0))) * 1e-6 if final else None
    for o in meshes():
        if tris(o) > 1500 and o.name not in keep:
            decimate(o, max(k, 0.03), dist)
    return sum(tris(o) for o in meshes())


def object_parts(o, weld):
    """The loose parts of a mesh as (vertex indices, points, points along the edges too). With a
    weld distance, vertices at the same spot count as joined (glTF files split meshes at every
    seam, which cuts a tyre into strips)."""
    me = o.data
    n = len(me.vertices)
    if n == 0:
        return []
    co = verts_world(o)
    ne = len(me.edges)
    ev = np.empty(ne * 2, dtype=np.int64)
    me.edges.foreach_get("vertices", ev)
    ev = ev.reshape(ne, 2)
    if weld:
        _, inv = np.unique(np.round(co / weld).astype(np.int64), axis=0, return_inverse=True)
        inv = inv.ravel()
        m = int(inv.max()) + 1
        rows = np.concatenate([ev[:, 0], np.arange(n)])
        cols = np.concatenate([ev[:, 1], n + inv])
    else:
        m = 0
        rows, cols = ev[:, 0], ev[:, 1]
    g = coo_matrix((np.ones(len(rows)), (rows, cols)), shape=(n + m, n + m))
    _, lab = connected_components(g, directed=False)
    lab = lab[:n]
    order = np.argsort(lab, kind="stable")
    cuts = np.flatnonzero(np.diff(lab[order])) + 1
    elab = lab[ev[:, 0]] if ne else np.zeros(0, dtype=lab.dtype)
    eorder = np.argsort(elab, kind="stable")
    ecuts = np.searchsorted(elab[eorder], lab[order][np.concatenate([[0], cuts])])
    ecuts = np.append(ecuts, ne)
    out = []
    for gi, grp in enumerate(np.split(order, cuts)):
        pts = co[grp]
        es = ev[eorder[ecuts[gi]:ecuts[gi + 1]]]
        if len(es):
            e0, e1 = co[es[:, 0]], co[es[:, 1]]
            dense = np.concatenate([pts] + [e0 * (1 - t) + e1 * t for t in (0.25, 0.5, 0.75)])
        else:
            dense = pts
        out.append((grp, pts, dense))
    return out


def parts_index(weld):
    """Every loose part of every mesh: (object, vertex indices, bbox min, bbox max, points)."""
    out = []
    for o in meshes():
        for idx, pts, dense in object_parts(o, weld):
            out.append((o, idx, pts.min(axis=0), pts.max(axis=0), dense))
    return out


def find_wheels(parts, up, length_axis, side_axis, lo, hi):
    """Round parts low at the four corners: tyres / rims. Returns 4 (centre, radius)."""
    L = hi[length_axis] - lo[length_axis]
    cands = []
    for o, idx, a, b, co in parts:
        d = b - a
        dl, du, ds = d[length_axis], d[up], d[side_axis]
        diam = max(dl, du)
        if not (0.09 * L < diam < 0.2 * L):
            continue
        if abs(dl - du) > 0.18 * diam or ds > 0.7 * diam:
            continue
        c = (a + b) / 2
        if c[up] - lo[up] > 0.75 * diam:  # wheels sit on the ground
            continue
        cands.append((c, diam / 2))
    if len(cands) < 4:
        return None
    mid = (lo + hi) / 2
    corners = {}
    for c, r in cands:
        key = (c[length_axis] > mid[length_axis], c[side_axis] > mid[side_axis])
        corners.setdefault(key, []).append((c, r))
    if len(corners) != 4:
        return None
    wheels = {}
    for key, lst in corners.items():
        rmax = max(r for _, r in lst)
        big = [c for c, r in lst if r > rmax * 0.85]  # the tyre, not the small discs inside
        wheels[key] = (np.mean(big, axis=0), rmax)
    return wheels


def ring_fit(s, u):
    """Where the points (side, up in metres, around a centre) make a steering wheel rim: the
    radius (0.15-0.235 m) at which points reach round the most of 24 directions, and how many.
    Things beside the wheel (a gauge hood, buttons) don't spoil it, and a missing hub is fine."""
    r = np.hypot(s, u)
    bins = ((np.arctan2(u, s) + math.pi) / (2 * math.pi) * 24).astype(int) % 24
    best = (0, None, None)
    for r0 in np.arange(0.15, 0.2351, 0.005):
        m = np.abs(r - r0) <= 0.025
        if m.any():
            n = len(np.unique(bins[m]))
            if n >= best[0]:  # on a tie the bigger circle: the rim, not the hub or spokes inside it
                best = (n, r0, m)
    return best


def find_steering(parts, scale, up, la, sa, centre, ground, wb):
    """The steering wheel: {"centre" (model units), "radius" (m), "ratio", "names"} or None."""
    # every part in metres: side off the middle, height off the ground, length off the middle
    P = []
    for i, (o, idx, a, b, co) in enumerate(parts):
        s0, s1 = (a[sa] - centre[sa]) * scale, (b[sa] - centre[sa]) * scale
        u0, u1 = (a[up] - ground) * scale, (b[up] - ground) * scale
        l0, l1 = sorted(((a[la] - centre[la]) * scale, (b[la] - centre[la]) * scale))
        s0, s1 = min(s0, s1), max(s0, s1)
        if u1 < 0.35 or u0 > 1.7 or s1 < -0.85 or s0 > 0.85 or l1 < -wb / 2 - 0.4 or l0 > wb / 2 + 0.4:
            continue
        pts = np.stack([(co[:, sa] - centre[sa]) * scale, (co[:, up] - ground) * scale, (co[:, la] - centre[la]) * scale], axis=1)
        P.append((i, np.array([s0, u0, l0]), np.array([s1, u1, l1]), pts))
    if not P:
        return None
    lo = np.array([p[1] for p in P])
    hi = np.array([p[2] for p in P])
    hinted = {i for i, *_ in P if any(k in parts[i][0].name.lower() for k in ("steer", "lenk", "volant"))}

    def gather(c, R, depth=0.15):
        ok = (lo[:, 0] >= c[0] - R) & (hi[:, 0] <= c[0] + R) & (lo[:, 1] >= c[1] - R) & (hi[:, 1] <= c[1] + R) & (lo[:, 2] >= c[2] - depth) & (hi[:, 2] <= c[2] + depth)
        got = []
        for k in np.nonzero(ok)[0]:
            pts = P[k][3]
            if np.all(np.hypot(pts[:, 0] - c[0], pts[:, 1] - c[1]) <= R):
                got.append(k)
        return got

    seeds = []
    for k, (i, a, b, pts) in enumerate(P):
        c = (a + b) / 2
        d = b - a
        if 0.18 < abs(c[0]) < 0.62 and 0.55 < c[1] < 1.45 and abs(c[2]) < wb / 2 + 0.1 and max(d[0], d[1]) >= 0.04 and max(d) < 0.5:
            seeds.append(c)
    allp = np.concatenate([p[3] for p in P])
    seen, found = set(), []
    for c in seeds:
        c = c.copy()
        n = 0
        for _ in range(5):
            got = gather(c, 0.26)
            if not got:
                break
            pts = np.concatenate([P[k][3] for k in got])
            n, r0, m = ring_fit(pts[:, 0] - c[0], pts[:, 1] - c[1])
            if r0 is None:
                break
            ring = pts[m]
            # onto the middle of the ring found
            nc = np.array([(ring[:, 0].min() + ring[:, 0].max()) / 2, (ring[:, 1].min() + ring[:, 1].max()) / 2, np.median(ring[:, 2])])
            if np.allclose(nc, c, atol=0.005):
                break
            c = nc
        key = tuple(np.round(c / 0.02).astype(int))
        if key in seen:
            continue
        seen.add(key)
        if not (0.18 < abs(c[0]) < 0.62 and 0.55 < c[1] < 1.45):
            continue
        got = gather(c, 0.26)
        if not got:
            continue
        pts = np.concatenate([P[k][3] for k in got])
        n, r0, m = ring_fit(pts[:, 0] - c[0], pts[:, 1] - c[1])
        if n < 21:
            continue
        # the steering wheel has no twin across the car (seats, headrests and speakers do)
        twin_c = np.array([-c[0], c[1], c[2]])
        twin = gather(twin_c, 0.26)
        if twin:
            tp = np.concatenate([P[k][3] for k in twin])
            tn, tr0, _ = ring_fit(tp[:, 0] - twin_c[0], tp[:, 1] - twin_c[1])
            if tr0 is not None and abs(tr0 - r0) <= 0.03:
                continue
        R = min(r0 + 0.04, 0.26)
        inner = gather(c, R)
        # the dashboard right ahead of it and the driver's empty space right behind: lopsided
        # (a gauge pod or vent just ahead of the wheel has the wheel behind it)
        box = (np.abs(allp[:, 0] - c[0]) < 0.25) & (allp[:, 1] - c[1] > -0.1) & (allp[:, 1] - c[1] < 0.25)
        dl = allp[:, 2] - c[2]
        a1 = np.sum(box & (dl > 0.18) & (dl < 0.5))
        a2 = np.sum(box & (dl < -0.18) & (dl > -0.5))
        lopsided = abs(a1 - a2) / (a1 + a2 + 1)
        score = n / 24 + (0.3 if any(P[k][0] in hinted for k in inner) else 0) - abs(abs(c[0]) - 0.38) * 0.5 + min(len(inner), 20) * 0.005 + 0.5 * lopsided
        found.append((score, c, R, n / 24, inner, r0))
    if not found:
        if not hinted:
            return None
        # by name only: the biggest part called "steering ..."
        k = max((k for k, p in enumerate(P) if p[0] in hinted), key=lambda k: np.linalg.norm(P[k][2] - P[k][1]))
        c = (P[k][1] + P[k][2]) / 2
        found = [(0, c, max(0.2, np.max(P[k][2] - P[k][1]) / 2), 0.0, [k], 0.18)]
    if DEBUG:
        for f in sorted(found, key=lambda f: -f[0])[:12]:
            print("steer candidate score %.3f at side %.2f up %.2f along %.2f R %.3f parts %d" % (f[0], f[1][0], f[1][1], f[1][2], f[2], len(f[4])))
    score, c, R, ratio, got, r0 = max(found, key=lambda f: f[0])
    if score > 0:
        # true it up on the rim's outer edge: the farthest point in each of 24 directions (leaving
        # out ones much farther or nearer than the rest), and a circle through them
        for tol in (0.1, 0.06, 0.03, 0.03, 0.03):
            got = gather(c, 0.27)
            if not got:
                break
            pts = np.concatenate([P[k][3] for k in got])
            ds, du = pts[:, 0] - c[0], pts[:, 1] - c[1]
            r = np.hypot(ds, du)
            b24 = ((np.arctan2(du, ds) + math.pi) / (2 * math.pi) * 24).astype(int) % 24
            edge = []
            for k in range(24):
                idx = np.nonzero((b24 == k) & (r < 0.25))[0]
                if len(idx):
                    j = idx[np.argmax(r[idx])]
                    edge.append((ds[j], du[j], r[j], pts[j, 2]))
            e = np.array(edge)
            if DEBUG:
                print("refine: edges", len(e), "radii", np.round(e[:, 2], 3) if len(e) else None)
            if len(e) < 16:
                break
            # leave out edge points far off the typical radius: loosely at first (the centre can
            # start a few cm off), then tighter
            e = e[np.abs(e[:, 2] - np.median(e[:, 2])) < tol]
            if len(e) < 12:
                break
            A = np.stack([2 * e[:, 0], 2 * e[:, 1], np.ones(len(e))], axis=1)
            sol = np.linalg.lstsq(A, e[:, 0] ** 2 + e[:, 1] ** 2, rcond=None)[0]
            c = np.array([c[0] + sol[0], c[1] + sol[1], c[2]])
            outer = np.hypot(e[:, 0] - sol[0], e[:, 1] - sol[1])
            R = float(min(outer.max() + 0.015, 0.26))
            r0 = float(np.median(outer) - 0.015)
            if DEBUG:
                print("refine: centre %.3f %.3f %.3f R %.3f edges %d" % (c[0], c[1], c[2], R, len(e)))
            if abs(sol[0]) + abs(sol[1]) < 0.003:
                break
        got = gather(c, R)
    # back into model units
    cm = np.array(centre, dtype=float)
    cm[sa] = centre[sa] + c[0] / scale
    cm[up] = ground + c[1] / scale
    cm[la] = centre[la] + c[2] / scale
    names = sorted({parts[P[k][0]][0].name for k in got})
    return {"centre": cm, "radius": float(R), "r0": float(r0), "ratio": float(ratio), "names": names[:6], "candidates": len(found)}


def main():
    args = sys.argv[1:]
    src, real_wb, out = args[0], float(args[1]), args[2]
    # hand-set help for a car the search gets wrong: {"front": 1 or -1 (along the model's length
    # axis), "tilt": degrees}
    hint = json.loads(args[3]) if len(args) > 3 else {}
    report = {"src": src, "hint": hint}
    # first pass, to find things: a quick thinning keeps the search fast
    load(src)
    report["turned"] = align_yaw()
    report["dropped"] = drop_props()
    report["tris_in"] = sum(tris(o) for o in meshes())
    decimate_to(BUDGET, final=False)

    allv = np.concatenate([verts_world(o) for o in meshes()])
    lo, hi = allv.min(axis=0), allv.max(axis=0)
    size = hi - lo
    up = 2  # glTF comes in Z-up
    length_axis = 0 if size[0] > size[1] else 1
    side_axis = 1 - length_axis
    # wheels from welded parts (whole tyres); the steering wheel from the parts as they are (a rim
    # welded to its column would be too big to pass)
    wheels = find_wheels(parts_index(size.max() * 1e-6), up, length_axis, side_axis, lo, hi)
    parts = parts_index(None)
    if not wheels:
        report["error"] = "wheels not found"
        json.dump(report, open(out + ".json", "w"), indent=1)
        print(json.dumps(report))
        return
    axle = {}
    for (front_hi, _), (c, r) in wheels.items():
        axle.setdefault(front_hi, []).append(c[length_axis])
    wb_model = abs(np.mean(axle[True]) - np.mean(axle[False]))
    scale = real_wb / wb_model
    wr = np.mean([r for _, r in wheels.values()])
    ground = np.mean([c[up] for c, _ in wheels.values()]) - wr
    centre = np.mean([c for c, _ in wheels.values()], axis=0)

    # steering wheel: about 37 cm round, a fifth to over half a metre off the middle, 0.6-1.3 m up,
    # between the axles. Its rim is often cut into arcs, so every part there is a seed: gather
    # everything inside a circle around it, move the circle onto what was gathered, and repeat.
    # Only a real ring passes: points all the way round at nearly the same distance (a seat back
    # or a panel is square-ish or too big and fails)
    best = find_steering(parts, scale, up, length_axis, side_axis, centre, ground, real_wb)
    if best is None:
        report["error"] = "steering wheel not found"
        json.dump(report, open(out + ".json", "w"), indent=1)
        print(json.dumps(report))
        return
    sc, R, depth = best["centre"], best["radius"] / scale, 0.14 / scale
    # the steering wheel's pieces: any within its radius (side/up plane) and a short depth either
    # side of it
    sel_pts = []
    for o, idx, a, b, co in parts:
        if np.all(np.hypot(co[:, side_axis] - sc[side_axis], co[:, up] - sc[up]) <= R) and np.all(np.abs(co[:, length_axis] - sc[length_axis]) <= depth):
            sel_pts.append(co)
    pts = np.concatenate(sel_pts)
    # front, two ways: the dashboard is just ahead of the wheel while the driver's space just
    # behind it is empty; and the rim leans forward at the top (height rises towards the front)
    allp = np.concatenate([verts_world(o) for o in meshes()])
    rs = (allp[:, side_axis] - sc[side_axis]) * scale
    ru = (allp[:, up] - sc[up]) * scale
    rl = (allp[:, length_axis] - sc[length_axis]) * scale
    box = (np.abs(rs) < 0.25) & (ru > -0.1) & (ru < 0.25)
    ahead = int(np.sum(box & (rl > 0.18) & (rl < 0.5)))
    behind = int(np.sum(box & (rl < -0.18) & (rl > -0.5)))
    r = np.hypot((pts[:, side_axis] - sc[side_axis]) * scale, (pts[:, up] - sc[up]) * scale)
    rim = pts[np.abs(r - best["r0"]) <= 0.025]
    lean = 1 if np.cov(rim[:, length_axis], rim[:, up])[0, 1] > 0 else -1
    if "front" in hint:
        front_sign = hint["front"]
    elif max(ahead, behind) > 2 * min(ahead, behind) + 50:
        front_sign = 1 if ahead > behind else -1
    else:
        front_sign = lean
    report["front_cues"] = {"dash_plus": ahead, "dash_minus": behind, "lean": lean}
    report.update({"scale": scale, "wheelbase_model": wb_model, "steering_from": best["names"], "steering_ring": best["ratio"], "steering_radius": best["radius"], "front_sign": front_sign, "driver_side": float(np.sign(sc[side_axis] - centre[side_axis]))})

    # second pass, for the car itself: a fresh copy at full detail, laid out the same way, the
    # steering wheel cut out of it, then the rest thinned out
    load(src)
    align_yaw(report["turned"])
    for name in report["dropped"]:
        o = bpy.data.objects.get(name)
        if o:
            bpy.data.objects.remove(o, do_unlink=True)
    lo_c = np.array(sc, dtype=float)
    hi_c = np.array(sc, dtype=float)
    for ax, reach in ((side_axis, R), (up, R), (length_axis, 0.3 / scale)):
        lo_c[ax] -= reach
        hi_c[ax] += reach
    parts = []
    for o in meshes():
        v = verts_world(o)
        if np.all(v.max(axis=0) >= lo_c) and np.all(v.min(axis=0) <= hi_c):
            for idx, pts_, _ in object_parts(o, None):
                parts.append((o, idx, pts_.min(axis=0), pts_.max(axis=0), pts_))
    pick_by_obj = {}
    for o, idx, a, b, co in parts:
        if np.all(np.hypot(co[:, side_axis] - sc[side_axis], co[:, up] - sc[up]) <= R) and np.all(np.abs(co[:, length_axis] - sc[length_axis]) <= depth):
            pick_by_obj.setdefault(o.name, set()).update(idx.tolist())
    # the centre (airbag, logo) is often one piece with the column behind it: from such a piece
    # (named as the steering wheel, or mostly inside the wheel) take what lies within the wheel,
    # from just behind the rim to a little into the column
    for o, idx, a, b, co in parts:
        v = co[: len(idx)]
        inside = np.hypot(v[:, side_axis] - sc[side_axis], v[:, up] - sc[up]) <= R
        fwd = front_sign * (v[:, length_axis] - sc[length_axis]) * scale
        inside &= (fwd >= -0.14) & (fwd <= 0.1)
        if not inside.any() or inside.all():
            continue
        named = any(k in o.name.lower() for k in ("steer", "lenk", "volant"))
        if named or (inside.mean() >= 0.5 and np.max(b - a) * scale < 0.8):
            pick_by_obj.setdefault(o.name, set()).update(np.asarray(idx)[inside].tolist())
    cut = []
    for name, pick in pick_by_obj.items():
        o = bpy.data.objects.get(name)
        if o:
            piece = separate(o, pick)
            if piece:
                cut.append(piece)
    wheel = join(cut, "SteeringWheel")
    report["tris"] = decimate_to(BUDGET, keep=("SteeringWheel",))
    if tris(wheel) > 9000:
        decimate(wheel, 9000 / tris(wheel), 1e-6 / scale)

    # bake: metres, ground at 0, centre between the axles, front along -Y, up +Z; the third axis
    # follows (a turn, never a mirror), which puts a car's left at +X
    M = np.zeros((3, 3))
    M[1, length_axis] = -front_sign * scale
    M[2, up] = scale
    M[0] = np.cross(M[1], M[2]) / scale
    P0 = np.array(centre, dtype=float)
    P0[up] = ground
    tvec = -M @ P0
    T = Matrix.Identity(4)
    for i in range(3):
        for j in range(3):
            T[i][j] = M[i, j]
        T[i][3] = tvec[i]
    for o in meshes():
        o.data.transform(T)

    co = verts_world(wheel)
    # its frame: the ring's middle, and the turning axis from how far the top of the rim leans
    # forward of its bottom (the hub and column bits would skew a fit of the whole piece)
    c0 = np.array(T @ Vector(sc))
    if "tilt" in hint:
        t = math.radians(hint["tilt"])
    else:
        dx, dz = co[:, 0] - c0[0], co[:, 2] - c0[2]
        top = co[(np.abs(dx) < 0.07) & (dz > 0.13)]
        bot = co[(np.abs(dx) < 0.07) & (dz < -0.13)]
        if len(top) >= 3 and len(bot) >= 3:
            t = math.atan2(bot[:, 1].mean() - top[:, 1].mean(), top[:, 2].mean() - bot[:, 2].mean())
        else:
            t = math.radians(20)
        t = min(max(t, math.radians(0)), math.radians(40))
    n = Vector((0, -math.cos(t), -math.sin(t)))
    right = Vector((-1, 0, 0))
    up_v = n.cross(right).normalized()
    right = up_v.cross(n).normalized()
    R4 = Matrix((right, up_v, -n)).transposed().to_4x4()
    T2 = Matrix.Translation(Vector(c0))
    wheel.data.transform((T2 @ R4).inverted())
    wheel.matrix_world = T2 @ R4
    report["steering"] = {"centre": [round(x, 3) for x in c0], "tilt": round(math.degrees(math.asin(max(-1, min(1, -n.z)))), 1), "tris": tris(wheel)}

    # road wheels: every piece inside a wheel's cylinder goes with that corner
    allv = np.concatenate([verts_world(o) for o in meshes() if o != wheel])
    centres = {}
    for key, (c, r) in wheels.items():
        p = np.asarray(T @ Vector(c))
        name = ("F" if p[1] < 0 else "R") + ("L" if p[0] > 0 else "R")
        centres[name] = (p, r * scale)
    groups = {k: [] for k in centres}
    for o in [o for o in meshes() if o != wheel]:
        # one corner at a time: splitting renumbers the mesh's vertices
        for key, (p, r) in centres.items():
            pick = set()
            for idx, cc, _ in object_parts(o, 1e-5):
                if np.all(np.hypot(cc[:, 1] - p[1], cc[:, 2] - p[2]) <= r * 1.04) and np.all(np.abs(cc[:, 0] - p[0]) <= r * 0.6):
                    if "calip" not in o.name.lower():
                        pick.update(idx.tolist())
            if pick:
                piece = separate(o, pick)
                if piece:
                    groups[key].append(piece)
    holder = bpy.data.objects.new("Wheels", None)
    bpy.context.scene.collection.objects.link(holder)
    report["wheels"] = {}
    for key, objs in groups.items():
        w = join(objs, key)
        if w:
            w.parent = holder
            report["wheels"][key] = tris(w)

    # the rest: one part per material; glass (by name or see-through material) -> SeeThrough_
    def is_glass(o, m):
        n = (o.name + " " + (m.name if m else "")).lower()
        if any(k in n for k in ("glass", "window", "windshield", "windscreen", "scheibe")) and not any(k in n for k in ("surround", "frame", "light", "lamp", "red", "orange", "mirror")):
            return True
        if m and m.use_nodes and "Principled BSDF" in m.node_tree.nodes:
            a = m.node_tree.nodes["Principled BSDF"].inputs["Alpha"]
            if not a.is_linked and a.default_value < 0.6:
                return True
            tr = m.node_tree.nodes["Principled BSDF"].inputs.get("Transmission Weight")
            if tr and not tr.is_linked and tr.default_value > 0.5:
                return True
        return False

    rest = [o for o in meshes() if o.parent is None and o.name != "SteeringWheel" and len(o.data.polygons) > 0]
    bymat = {}
    for o in rest:
        m = o.data.materials[0] if o.data.materials else None
        key = (m.name if m else "none", is_glass(o, m))
        bymat.setdefault(key, []).append(o)
    glass_parts = 0
    for (mname, glass), objs in bymat.items():
        part = join(objs, ("SeeThrough_" if glass else "Body_") + "".join(ch if ch.isalnum() else "_" for ch in mname)[:24])
        if glass:
            glass_parts += 1
    report["glass_parts"] = glass_parts
    for o in list(bpy.data.objects):
        if o.type == "MESH" and len(o.data.polygons) == 0:
            bpy.data.objects.remove(o, do_unlink=True)

    # colours, UVs, limits
    def to_srgb(c):
        return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055

    thinned = report["tris"] < report["tris_in"] * 0.9
    for m in bpy.data.materials:
        if not (m.use_nodes and "Principled BSDF" in m.node_tree.nodes):
            continue
        nt = m.node_tree
        bsdf = nt.nodes["Principled BSDF"]
        if thinned:
            # a thinned-out mesh no longer matches its bump detail: it would look crumpled
            for link in list(bsdf.inputs["Normal"].links):
                nt.links.remove(link)
        inp = bsdf.inputs["Base Color"]
        if inp.is_linked:
            if inp.links[0].from_node.type != "TEX_IMAGE":
                found = [x for x in nt.nodes if x.type == "TEX_IMAGE" and x.image and x.image.colorspace_settings.name != "Non-Color"]
                if found:
                    nt.links.new(found[0].outputs["Color"], inp)
            continue
        r, g, b, _ = inp.default_value
        img = bpy.data.images.new("col_" + m.name[:20], 8, 8)
        img.pixels = [to_srgb(r), to_srgb(g), to_srgb(b), 1.0] * 64
        img.pack()
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = img
        nt.links.new(tex.outputs["Color"], inp)
    for o in meshes():
        if not o.data.uv_layers:
            o.data.uv_layers.new(name="UVMap")
        if tris(o) > MAX_TRIS:
            decimate(o, MAX_TRIS / tris(o) * 0.95, 1e-5)
    for img in bpy.data.images:
        w, h = img.size
        if max(w, h) > 1024:
            k = 1024 / max(w, h)
            img.scale(max(1, int(w * k)), max(1, int(h * k)))
        if img.has_data:
            img.pack()
    # the tilt goes into the name: Studio's importer flattens the part's own turn
    wheel = bpy.data.objects["SteeringWheel"]
    wheel.name = "SteeringWheel_t%d" % max(0, round(report["steering"]["tilt"]))
    report["parts"] = len(meshes())
    report["tris_out"] = sum(tris(o) for o in meshes())
    bpy.ops.wm.save_as_mainfile(filepath=out)
    json.dump(report, open(out + ".json", "w"), indent=1, default=float)
    print(json.dumps(report, default=float))


if __name__ == "__main__":
    main()
