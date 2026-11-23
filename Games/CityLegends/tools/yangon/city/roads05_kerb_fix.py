"""roads05_kerb_fix.py (24 Nov 2026, P1-P3 map bugs): no two kerb pieces lie across each other.

roads05_kerb_cross.py finds kerb pieces (kinds r / w) whose footprints overlap by >= 30% of the smaller one with
their long axes > 25 degrees apart and tops within 1.5 (crumpled islands, a corner kerb run on across a straight one:
two kerbs through each other = overlap + z-fighting, and the stray one stands out into the road).
resolve() fixes each pair on the smaller piece: a box is cut back along its long axis to the longest run clear of the
other piece (kept if >= 0.4 long), anything else (wedges, nothing left) is dropped. Greedy, biggest overlap first.
roads05_bake.bake calls it right after drop_scraps, so every bake has it (meshes and the pavement-box clip).

    python roads05_kerb_fix.py test          (self-check)
"""
import math

import numpy as np
import shapely
from shapely.strtree import STRtree

CELL = 1536.0


def _cell(x, z):
    return '%dx%d' % (math.floor(x / CELL), math.floor(z / CELL))


def _frame(R, U):
    R = np.array(R, float)
    U = np.array(U, float)
    R /= np.linalg.norm(R)
    U = U - R * (U @ R)
    U /= np.linalg.norm(U)
    return R, U, np.cross(R, U)


def _foot(p):
    k, cls, pos, R, U, S = p
    R, U, B = _frame(R, U)
    hx, hy, hz = S[0] / 2, S[1] / 2, S[2] / 2
    if cls == 'W':
        loc = [(sx * hx, -hy, sz * hz) for sx in (-1, 1) for sz in (-1, 1)] + [(sx * hx, hy, hz) for sx in (-1, 1)]
    else:
        loc = [(sx * hx, sy * hy, sz * hz) for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)]
    pts = np.array([np.array(pos) + R * a + U * b + B * c for a, b, c in loc])
    return shapely.convex_hull(shapely.multipoints(pts[:, [0, 2]])), pts[:, 1].max()


def _axis(poly):
    mrr = shapely.minimum_rotated_rectangle(poly)
    if mrr.geom_type != 'Polygon':
        return np.array([1.0, 0.0])
    c = np.array(mrr.exterior.coords)[:4]
    e1, e2 = c[1] - c[0], c[2] - c[1]
    ax = e1 if np.linalg.norm(e1) >= np.linalg.norm(e2) else e2
    n = np.linalg.norm(ax)
    return ax / n if n > 1e-9 else np.array([1.0, 0.0])


def pairs(parts, cells=None):
    """[(overlap, i, j)] crossing kerb pairs (indices into parts), the same test as roads05_kerb_cross"""
    idx = [i for i, p in enumerate(parts) if p[0] in ('r', 'w') and (not cells or _cell(p[2][0], p[2][2]) in cells)]
    polys, tops, axes = [], [], []
    for i in idx:
        poly, top = _foot(parts[i])
        polys.append(poly)
        tops.append(top)
        axes.append(_axis(poly))
    if not polys:
        return [], idx, polys
    arr = np.array(polys, dtype=object)
    a_idx, b_idx = STRtree(arr).query(arr, predicate='intersects')
    out = []
    for a, b in zip(a_idx, b_idx):
        if a >= b or abs(tops[a] - tops[b]) > 1.5:
            continue
        ang = math.degrees(math.acos(min(1.0, abs(float(axes[a] @ axes[b])))))
        if ang < 25:
            continue
        inter = polys[a].intersection(polys[b]).area
        if inter < 0.3 * min(polys[a].area, polys[b].area) or inter < 0.4:
            continue
        out.append((inter, int(a), int(b)))
    out.sort(reverse=True)
    return out, idx, polys


def _trim(p, other):
    """box p cut back along its long local axis (X or Z) to the longest run clear of polygon other; None = drop"""
    k, cls, pos, R0, U0, S = p
    if cls != 'B':
        return None
    R, U, B = _frame(R0, U0)
    ax, L, wid, wv = (0, S[0], S[2], B) if S[0] >= S[2] else (2, S[2], S[0], R)
    av = R if ax == 0 else B
    c = np.array(pos, float)
    n = max(4, int(L / 0.1))
    free = []
    for t in range(n):
        s = -L / 2 + (t + 0.5) * L / n
        m = c + av * s
        a, b = m - wv * wid / 2, m + wv * wid / 2
        free.append(not other.intersects(shapely.linestrings([[a[0], a[2]], [b[0], b[2]]])))
    best, run, start = (0, 0), 0, 0
    for t, f in enumerate(free + [False]):
        if f:
            if run == 0:
                start = t
            run += 1
        else:
            if run > best[1] - best[0]:
                best = (start, start + run)
            run = 0
    lo, hi = -L / 2 + best[0] * L / n, -L / 2 + best[1] * L / n
    hi -= 0.05                                   # a hair clear of the other kerb's side (no touching faces)
    if best[1] == n:
        hi += 0.05
    if best[0] > 0:
        lo += 0.05
    if hi - lo < 0.4:
        return None
    nc = c + av * ((lo + hi) / 2)
    S2 = list(S)
    S2[ax] = round(hi - lo, 4)
    return (k, cls, (round(nc[0], 4), round(nc[1], 4), round(nc[2], 4)), R0, U0, tuple(S2))


def _reach(left, near):
    """how far what is left of a piece reaches out from the other kerbs (studs)"""
    if left.is_empty:
        return 0.0
    if not near:
        return 99.0
    u = shapely.union_all(near)
    pts = shapely.get_coordinates(left)
    return max(u.distance(shapely.points(pts)).tolist())


TILT = 15.0


def tilted(p):
    """a kerb piece whose tall (6-stud, mostly buried) axis leans > TILT degrees off vertical: a crumpled piece (it lies
    across the road / median nose as a slanted plate)"""
    k, cls, pos, R, U, S = p
    R, U, B = _frame(R, U)
    tall = [i for i in range(3) if abs(S[i] - 6.04) < 0.15]   # the builder's kerb depth (top + 6 buried)
    if not tall:
        return False
    ax = (R, U, B)[tall[0]]
    return abs(ax[1]) < math.cos(math.radians(TILT))


def resolve(parts, cells=None, _top=True):
    """parts with every crossing kerb pair fixed on its smaller piece; returns (parts, stats)"""
    n_tilt = 0
    if _top:
        keep = [not (p[0] in ('r', 'w') and (not cells or _cell(p[2][0], p[2][2]) in cells) and tilted(p)) for p in parts]
        n_tilt = keep.count(False)
        parts = [p for p, k in zip(parts, keep) if k]
    ps, idx, polys = pairs(parts, cells)
    gone, trimmed, raised = set(), {}, {}
    tree = STRtree(np.array(polys, dtype=object)) if polys else None
    tops = [_foot(parts[i])[1] for i in idx]
    for inter, a, b in ps:
        ia, ib = idx[a], idx[b]
        if ia in gone or ib in gone or ia in trimmed or ib in trimmed:
            continue                              # one of them already moved: re-checked next round
        small, big = (a, b) if polys[a].area <= polys[b].area else (b, a)
        t = _trim(parts[idx[small]], polys[big])
        if t is not None:
            trimmed[idx[small]] = t
            continue
        # drop it only if that leaves no notch: what the other kerbs do not cover is a sliver, or sticks out away
        # from them (a stray piece across the road / crossing); else keep both (one continuous kerb, e.g. two wedge
        # fans on a gore bend) and only lift the smaller 0.06 when their tops are coplanar (no flicker)
        f = polys[small]
        near = [polys[j] for j in tree.query(f.buffer(0.5)) if j != small and idx[j] not in gone]
        left = f.difference(shapely.union_all(near)) if near else f
        if left.area < 0.15 or _reach(f.difference(polys[big]), [polys[big]]) > 1.5:
            gone.add(idx[small])
        elif abs(tops[small] - tops[big]) < 0.05 and idx[small] not in raised:
            k, cls, pos, R, U, S = parts[idx[small]]
            raised[idx[small]] = (k, cls, (pos[0], round(pos[1] + 0.06, 4), pos[2]), R, U, S)
    out = [trimmed.get(i, raised.get(i, p)) for i, p in enumerate(parts) if i not in gone]
    st = dict(pairs=len(ps), dropped=len(gone), trimmed=len(trimmed), raised=len(raised))
    if ps and (gone or trimmed):
        # pairs of pieces untouched in this round (a third piece in a cluster): another round
        out, st2 = resolve(out, cells, False)
        st = dict(pairs=st['pairs'], dropped=st['dropped'] + st2['dropped'], trimmed=st['trimmed'] + st2['trimmed'],
                  raised=st['raised'] + st2['raised'], left=st2.get('left', 0))
    else:
        st['left'] = len(ps)                      # kept on purpose: overlapping pieces of one kerb, tops apart
    if _top:
        st['tilted'] = n_tilt
    return out, st


def _test():
    I = (1, 0, 0)
    Y = (0, 1, 0)
    a = ('r', 'B', (0.0, 0.5, 0.0), I, Y, (4.0, 1.0, 0.9))             # long along x
    b = ('w', 'B', (1.5, 0.5, 0.0), (0, 0, 1), Y, (3.0, 1.0, 0.9))      # long along z (R = z), crosses a near x = 1.5
    c = ('r', 'B', (100.0, 0.5, 0.0), I, Y, (4.0, 1.0, 0.9))            # far away, untouched
    out, st = resolve([a, b, c])
    assert st['pairs'] == 1 and st['left'] == 0, st
    assert c in out and a in out, out
    assert len(pairs(out)[0]) == 0
    t = [p for p in out if p[0] == 'w']
    assert len(t) == 1 and t[0][5][0] < 3.0 and t[0][5][0] >= 0.4, t   # b trimmed, still a box
    poly_a, _ = _foot(a)
    poly_t, _ = _foot(t[0])
    assert poly_a.intersection(poly_t).area < 1e-6
    a2 = ('r', 'B', (0.0, 0.5, 0.0), I, Y, (4.0, 1.0, 2.0))
    w = ('w', 'W', (1.5, 0.5, 1.6), (0, 0, 1), Y, (3.6, 1.0, 1.2))       # a wedge across a2, 2.4 studs out: dropped
    out, st = resolve([a2, w])
    assert st['dropped'] == 1 and out == [a2], (st, out)
    # two wedge fans of one kerb lying over each other at 30 degrees, tops coplanar: dropping one would notch -> kept, lifted
    r30 = (math.cos(math.radians(30)), 0, math.sin(math.radians(30)))
    e = ('r', 'W', (0.0, 0.5, 0.0), I, Y, (2.0, 1.0, 0.9))
    g = ('w', 'W', (0.3, 0.5, 0.1), r30, Y, (2.0, 1.0, 0.9))
    out, st = resolve([e, g])
    assert len(out) == 2 and st['raised'] == 1 and st['dropped'] == 0, (st, out)
    assert abs(_foot(out[0])[1] - _foot(out[1])[1]) >= 0.05
    lean = ('r', 'W', (5.0, 0.5, 5.0), (0.21, -0.9, 0.38), (0.98, 0.21, -0.02), (6.04, 0.69, 0.4))
    out, st = resolve([a, lean])
    assert out == [a] and st['tilted'] == 1, st
    print('kerb_fix self-check ok')


if __name__ == '__main__':
    import sys
    if sys.argv[1:] == ['test']:
        _test()
