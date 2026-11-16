"""props1to1.py (2026-11-16): player-scale site props for the 1:1 landmark refits (Sedona; mc3d.py has its own copies).
Every prop is built inside a KEEP frame of an onetoone.XGeo at its base point, so it keeps its true size (studs at
3 a metre) wherever the site lands. Groups: KTW trunks, KTL leaves (landmark_glb3d's kit groups)."""
import math


def palm(g, coll, x, y, z0, h):
    with g.keep(x, y, z0):
        lean = (0.04 * math.cos(x), 0.04 * math.sin(y))
        top = (x + lean[0] * h, y + lean[1] * h, z0 + h)
        prev = (x, y, z0 - 2.0)
        for k in range(1, 7):
            t = k / 6
            cur = (x + lean[0] * h * t, y + lean[1] * h * t, z0 - 2.0 + (h + 2.0) * t)
            g.tube("KTW", prev, cur, 1.3 - 0.4 * t)
            prev = cur
        for j in range(9):
            a = 2 * math.pi * j / 9 + 0.3
            mid = (top[0] + math.cos(a) * 4.5, top[1] + math.sin(a) * 4.5, top[2] + 1.2)
            tip = (top[0] + math.cos(a) * 9.0, top[1] + math.sin(a) * 9.0, top[2] - 2.5)
            sx, sy = -math.sin(a) * 1.4, math.cos(a) * 1.4
            for p0, p1, w0, w1 in ((top, mid, 0.3, 1.0), (mid, tip, 1.0, 0.1)):
                A = (p0[0] - sx * w0, p0[1] - sy * w0, p0[2])
                B = (p0[0] + sx * w0, p0[1] + sy * w0, p0[2])
                C = (p1[0] + sx * w1, p1[1] + sy * w1, p1[2])
                D = (p1[0] - sx * w1, p1[1] - sy * w1, p1[2])
                g.quad("KTL", A, B, C, D)
        coll.append((x, y, z0, 1.4, 1.4, h, 0.0))


def rain_tree(g, coll, x, y, z0, h):
    """A broad rain tree: trunk, three limbs, a flattened 12-sided crown (canopy about 1.1 h across)."""
    with g.keep(x, y, z0):
        g.tube("KTW", (x, y, z0 - 2.0), (x, y, z0 + h * 0.45), 2.2)
        for j in range(3):
            a = 2 * math.pi * j / 3 + x
            g.tube("KTW", (x, y, z0 + h * 0.4), (x + math.cos(a) * 7, y + math.sin(a) * 7, z0 + h * 0.7), 1.2)
        R, n = h * 0.55, 12
        zb, zt = z0 + h * 0.6, z0 + h
        lo = [(x + R * math.cos(2 * math.pi * k / n), y + R * math.sin(2 * math.pi * k / n)) for k in range(n)]
        hi = [(x + R * 0.6 * math.cos(2 * math.pi * (k + 0.5) / n), y + R * 0.6 * math.sin(2 * math.pi * (k + 0.5) / n))
              for k in range(n)]
        for k in range(n):
            a_, b_ = lo[k], lo[(k + 1) % n]
            c_, d_ = hi[k], hi[(k + 1) % n]
            g.tri("KTL", (a_[0], a_[1], zb + 2), (b_[0], b_[1], zb + 2), (c_[0], c_[1], zt))
            g.tri("KTL", (b_[0], b_[1], zb + 2), (d_[0], d_[1], zt), (c_[0], c_[1], zt))
            g.tri("KTL", (b_[0], b_[1], zb + 2), (a_[0], a_[1], zb + 2), (x, y, zb))
        g.cap("KTL", hi, zt)
        coll.append((x, y, z0, 2.2, 2.2, h * 0.45, 0.0))
