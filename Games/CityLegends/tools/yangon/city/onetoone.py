"""onetoone.py (2026-11-16): runs the real-geometry landmark scripts (mc3d.py, sedona3d.py), written in the OLD model
frame (1.6 studs a metre across, player-scale floors), at the 1:1 scale (geo.SPM 3) without rewriting them.

The scripts keep building in old model studs; every triangle, collision box and light goes through a transform:
  * across: x, y * S (S = 3 / 1.6 = 1.875), so footprints, galleries, drives and plazas get their real size;
  * up: a per-building height map f(z) (real floor heights: mall 5.5 / 5.0 m, office 3.75 m, hotel / Sedona 3.3 m);
  * KEEP frames for pieces that were already player scale (furniture, shop fit-outs, escalators, lamps, letters,
    the Melia interior): the piece's anchor moves with the building (S * anchor, f(z)) but the piece keeps its own size.

Model frame at 1:1: x = world X - OX1, y = -(world Z - OZ1), with OX1 / OZ1 the old origin (32600, -1350) carried to
the new frame through lon / lat, so an old model point p lands at S * p (the site audit's coordinates stay valid).
"""
import math
from contextlib import contextmanager

import geo
from geom3d import Geo

S = 3.0 / 1.6
# the old model origin (world 32600, -1350 at 1.6 studs a metre) in the 1:1 world (geo.world at SPM 3)
OX1 = 30000.0 + (32600.0 - 30000.0) * S          # 34875
OZ1 = 30000.0 + (-1350.0 - 0.0) * S              # 27468.75


def zmap_factory(z_ground_old, z_ground_new, k_up):
    """f(z): the street storey 0..z_ground_old -> 0..z_ground_new, then k_up per old stud above."""
    a = z_ground_new / z_ground_old

    def f(z):
        if z <= z_ground_old:
            return z * a
        return z_ground_new + (z - z_ground_old) * k_up
    return f


class XGeo(Geo):
    """A Geo whose triangles go through the 1:1 transform (and KEEP frames)."""

    def __init__(self, f, text_k=1.5, arc_k=1.25):
        super().__init__()
        self.f = f
        self.stack = []
        self.text_k = text_k
        self.arc_k = arc_k
        self.ground_mode = False
        self.gg = {}            # triangles that follow the pavement plane (site ground, plaza, drives, props on them)

    @contextmanager
    def ground(self):
        old = self.ground_mode
        self.ground_mode = True
        try:
            yield
        finally:
            self.ground_mode = old

    # ---- the transform ----
    def X(self, p):
        x, y, z = p
        if not self.stack:
            return (x * S, y * S, self.f(z))
        ax, ay, az, zkeep = self.stack[-1]
        return (S * ax + (x - ax), S * ay + (y - ay), (self.f(az) + (z - az)) if zkeep else self.f(z))

    def box_x(self, b):
        """(cx, cy, z0, sx, sy, sz, yaw[, pitch]): a pitched box (an escalator ramp) is only made in a KEEP frame."""
        cx, cy, z0, sx, sy, sz, yaw = b[:7]
        if not self.stack:
            return (cx * S, cy * S, self.f(z0), sx * S, sy * S, self.f(z0 + sz) - self.f(z0), yaw) + tuple(b[7:])
        X, Y, Z = self.X((cx, cy, z0))
        zkeep = self.stack[-1][3]
        return (X, Y, Z, sx, sy, sz if zkeep else self.f(z0 + sz) - self.f(z0), yaw) + tuple(b[7:])

    @contextmanager
    def keep(self, ax, ay, az=0.0, zkeep=True):
        """Inside: coordinates are true-scale offsets from (ax, ay, az) (nested keeps reuse the outer anchor)."""
        self.stack.append(self.stack[-1] if self.stack else (ax, ay, az, zkeep))
        try:
            yield
        finally:
            self.stack.pop()

    def local(self, p_old):
        """An old-frame point -> its position in the current KEEP frame's local coords (where a point that must meet
        the scaled building, e.g. an escalator's top landing, has to be put)."""
        ax, ay, az, zk = self.stack[-1]
        return (ax + (p_old[0] - ax) * S, ay + (p_old[1] - ay) * S)

    def tri(self, grp, a, b, c):
        if self.ground_mode:
            self.gg.setdefault(grp, []).append((self.X(a), self.X(b), self.X(c)))
        else:
            super().tri(grp, self.X(a), self.X(b), self.X(c))

    def count(self):
        out = {k: len(v) for k, v in self.g.items()}
        for k, v in self.gg.items():
            out[k] = out.get(k, 0) + len(v)
        return out

    # letters keep their shape (no 1.875 stretch along the line): a KEEP frame at the origin, size by text_k
    def text(self, grp, letters, text, origin, right, h, depth, align="center", max_w=None):
        if self.stack:
            return super().text(grp, letters, text, origin, right, h, depth, align, max_w)
        with self.keep(origin[0], origin[1], origin[2]):
            return super().text(grp, letters, text, origin, right, h * self.text_k, depth, align,
                                max_w * S if max_w else None)

    def text_arc(self, grp, letters, text, centre, r, a_mid, z0, h, depth, width=None):
        if self.stack:
            return super().text_arc(grp, letters, text, centre, r, a_mid, z0, h, depth, width)
        with self.keep(centre[0], centre[1], z0):
            return super().text_arc(grp, letters, text, centre, r * S, a_mid, z0, h * self.arc_k, depth,
                                    width * self.arc_k if width else None)


class XColl(list):
    """Collision boxes (cx, cy, z0, sx, sy, sz, yaw) through the geo's current transform; boxes added in the geo's
    ground mode go to `ground` (they follow the pavement plane)."""

    def __init__(self, geo_, ground=None):
        super().__init__()
        self.geo = geo_
        self.ground = ground

    def append(self, b):
        if self.geo.ground_mode and self.ground is not None:
            self.ground.append(self.geo.box_x(b))
        else:
            super().append(self.geo.box_x(b))

    def extend(self, bs):
        for b in bs:
            self.append(b)


class XLights(list):
    """Lights / points ({"p": (x, y, z), ...}) through the geo's current transform."""

    def __init__(self, geo_):
        super().__init__()
        self.geo = geo_

    def append(self, d):
        d = dict(d)
        d["p"] = self.geo.X(d["p"])
        if self.geo.ground_mode:
            d["ground"] = True
        super().append(d)


def world_of_model(x, y):
    """1:1 model coords (already scaled) -> world X, Z."""
    return OX1 + x, OZ1 - y


def old_of_world(X, Z):
    """1:1 world -> OLD model coords (the frame the scripts and the site audit use)."""
    return (X - OX1) / S, -(Z - OZ1) / S


assert abs(geo.LON0 - 96.14) < 1e-9


def plane_y(plane, X, Z):
    return plane[0] + plane[1] * (X - OX1) + plane[2] * (Z - OZ1)


NUDGE = 0.12


def export(geo_, y0, plane, out_glb, tag, nudge=True):
    """Write the 1:1 meshes: building triangles on y0, ground triangles on the pavement plane (per vertex).
    Model (already scaled) -> world: X = OX1 + x, Y = base + z, Z = OZ1 - y. Same packs / names as landmark_glb3d."""
    import os
    from glb import Mesh, write_glb, code, check_glb
    import landmark_glb3d as LG
    named = []
    k = 0
    # world triangles first, then the flicker rule (owner, 2026-11-16: no visible faces closer than 0.05): every
    # same-facing coplanar overlap found by flicker_check gets its smaller triangle moved NUDGE out along its normal
    W = {}
    items, keys = [], []
    for layer, tg, ground in ((geo_.g, tag, False), (getattr(geo_, "gg", {}), tag + "g", True)):
        for grp in sorted(layer):
            if grp not in LG.GROUPS:
                raise KeyError("unknown group " + grp)
            lst = []
            for a, b, c in layer[grp]:
                P = []
                for (x, y, z) in (a, b, c):
                    X, Z = OX1 + x, OZ1 - y
                    P.append((X, (plane_y(plane, X, Z) if ground else y0) + z, Z))
                lst.append(P)
                items.append((tuple(P), grp))
                keys.append((tg, grp, len(lst) - 1))
            W[(tg, grp)] = lst
    nudged = 0
    if nudge:
        from flicker_check import check, _n as _fn

        def area_of(t):
            (ax, ay, az), (bx, by, bz), (cx, cy, cz) = t
            u, v = (bx - ax, by - ay, bz - az), (cx - ax, cy - ay, cz - az)
            n = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
            L = (n[0] ** 2 + n[1] ** 2 + n[2] ** 2) ** 0.5
            return L / 2, ((n[0] / L, n[1] / L, n[2] / L) if L > 1e-12 else (0, 0, 0))
        cur = items
        first = None
        for rnd in range(5):
            bad, _ = check(cur)
            # check() numbers only the triangles it kept (no degenerate ones): map back to items
            kept = [q for q, (t, _k) in enumerate(cur) if (lambda r: r[0] is not None and r[1] >= 1e-4)(_fn(t))]
            bad = [(kept[i], kept[j], gp, ar) for i, j, gp, ar in bad]
            if first is None:
                first = len(bad)
            if not bad:
                break
            done = set()
            for i, j, gap, area in bad:
                ai, ni = area_of(cur[i][0])
                aj, nj = area_of(cur[j][0])
                m_ = i if ai <= aj else j
                if m_ in done:
                    continue
                done.add(m_)
                tg, grp, idx = keys[m_]
                n = ni if m_ == i else nj
                W[(tg, grp)][idx] = [(p[0] + n[0] * NUDGE, p[1] + n[1] * NUDGE, p[2] + n[2] * NUDGE) for p in W[(tg, grp)][idx]]
                nudged += 1
            cur = [(tuple(W[(keys[q][0], keys[q][1])][keys[q][2]]), items[q][1]) for q in range(len(items))]
        print("flicker pairs", first, "triangles nudged", nudged, "-> pairs left", len(bad), "after", rnd + 1, "checks")
        geo_.flicker = (first, nudged, len(bad))
    for layer, tg, ground in ((geo_.g, tag, False), (getattr(geo_, "gg", {}), tag + "g", True)):
        for grp in sorted(layer):
            rgb = LG.GROUPS[grp][1]
            tris = W[(tg, grp)]
            for start in range(0, len(tris), LG.MAX_TRIS):
                m = Mesh()
                for P in tris[start:start + LG.MAX_TRIS]:
                    m.tri(P[0], P[1], P[2], *LG.box_uv(P), rgb)
                if not m.T:
                    continue
                k += 1
                lo, hi = m.box()
                cc = [(lo[i] + hi[i]) / 2 for i in range(3)]
                ss = [hi[i] - lo[i] for i in range(3)]
                assert max(ss) < 2040, ("mesh over 2048 studs", grp, ss)
                named.append((code(grp, "%ss%d" % (tg, k), cc, ss), m))
    os.makedirs(os.path.dirname(out_glb), exist_ok=True)
    files = []
    for i in range(0, len(named), 90):
        path = out_glb if i == 0 else out_glb.replace(".glb", "_%d.glb" % (i // 90 + 1))
        info = write_glb(path, named[i:i + 90], generator="onetoone.py")
        n, bad = check_glb(path, info)
        files.append((path, n, sum(v["tris"] for v in info.values()), bad))
    return files


def collide_text(boxes, gboxes, y0, plane, tag):
    """1:1 collision data in YangonBuildingMeshes.collide's line format: building boxes on y0, ground boxes on the
    plane at their middle."""
    parts = []
    for lst, ground in ((boxes, False), (gboxes, True)):
        for b in lst:
            cx, cy, z0, sx, sy, sz, yaw = b[:7]
            X, Z = OX1 + cx, OZ1 - cy
            base = plane_y(plane, X, Z) if ground else y0
            # an 8th number = pitch (radians, the box's x end raised): P1Refit.collide turns it about the box's z
            parts.append("%.2f %.2f %.2f %.2f %.2f %.2f %.4f" % (X, base + z0 + sz / 2, Z, sx, sz, sy, yaw)
                         + (" %.4f" % b[7] if len(b) > 7 else ""))
    return tag + "|" + "|".join(parts)


def lights_world(lights, y0, plane=None):
    """Light dicts (model p, already scaled) -> world positions."""
    out = []
    for d in lights:
        x, y, z = d["p"]
        X, Z = OX1 + x, OZ1 - y
        base = plane_y(plane, X, Z) if (plane and d.get("ground")) else y0
        out.append({"kind": d["kind"], "w": [round(X, 2), round(base + z, 2), round(Z, 2)]})
    return out
