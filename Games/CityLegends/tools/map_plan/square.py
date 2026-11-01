"""Makes streets meet other roads square-on, and works out which road gives way at each junction.

Where a street ENDS on another road (any road), its end is snapped onto that road's centre line and
an extra point is put D metres along that road's normal, so the street arrives at about 90
degrees. Where a street's middle point sits on an earlier road (a crossing), points go D metres
either side. Square junctions are short, so they can be made flat and bump-free.

square(routes, streets) -> (streets, depends): depends[name] = names of roads it ends on (they must
be finished before it, network.py). Used by network.py, plan.py and junction_angles.py."""
import math
from routes import catmull

D = 45.0  # metres of square approach


def _near(line, p):
    best = None
    for k, q in enumerate(line):
        d = (q[0] - p[0]) ** 2 + (q[1] - p[1]) ** 2
        if best is None or d < best[0]:
            best = (d, k)
    return math.sqrt(best[0]), best[1]


def _normal(line, k):
    a = line[max(k - 2, 0)]; b = line[min(k + 2, len(line) - 1)]
    L = math.hypot(b[0] - a[0], b[1] - a[1]) or 1
    tx, ty = (b[0] - a[0]) / L, (b[1] - a[1]) / L
    return (-ty, tx)


def square(routes, streets, with_depends=False):
    lines = [(n, catmull(p, 4, o.get("closed", False))) for n, p, c, o in routes + streets]
    out, depends = [], {}
    for si, (n, pts, col, opts) in enumerate(streets):
        depends[n] = set()
        if opts.get("closed"):
            out.append((n, pts, col, opts))
            continue
        new = []
        for i, p in enumerate(pts):
            end = i == 0 or i == len(pts) - 1
            # an end may sit on any road (routes first); a middle point only on an earlier one
            pool = [l for l in lines if l[0] != n] if end else lines[:len(routes) + si]
            host = None
            for on, ol in pool:
                d, k = _near(ol, p)
                if d < 15 and (end or 10 < k < len(ol) - 11):  # a crossing: the other road runs through
                    host = (d, ol, k, on)
                    break
            if not host:
                new.append(p)
                continue
            if end:
                depends[n].add(host[3])
            p = host[1][host[2]]  # onto the other road's centre line
            nx, ny = _normal(host[1], host[2])

            def side(q):
                return 1 if (q[0] - p[0]) * nx + (q[1] - p[1]) * ny >= 0 else -1

            def at(sgn, dist):
                return (p[0] + nx * sgn * dist, p[1] + ny * sgn * dist)

            prev = pts[i - 1] if i > 0 else None
            nxt = pts[i + 1] if i < len(pts) - 1 else None
            if prev is not None:
                new.append(at(side(prev), min(D, math.hypot(prev[0] - p[0], prev[1] - p[1]) * 0.45)))
            new.append(p)
            if nxt is not None:
                new.append(at(side(nxt), min(D, math.hypot(nxt[0] - p[0], nxt[1] - p[1]) * 0.45)))
        out.append((n, new, col, opts))
    return (out, depends) if with_depends else out
