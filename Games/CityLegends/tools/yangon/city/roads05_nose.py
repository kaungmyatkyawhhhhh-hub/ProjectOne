"""Median noses (25 Nov 2026, road bug sweep; owner shots 1 and 3: "a median nose ending as a small wedge in the middle of
the junction").

YangonRoads.buildMedians lays the stretch where a median narrows below two kerb widths as ONE kerb-coloured wedge (a
long white / red spike, often reaching into the junction box). The bake now drops the median parts (kerb bands r / w and
fill m) whose middle lies on those last narrow pieces, so a median ends where it is still two kerbs wide.

    drop(parts, data) -> parts, n_dropped            python roads05_nose.py test
"""
import sys
import shapely
from shapely.geometry import Polygon, Point

NARROW = 0.95   # YangonRoads: KW (0.9) + 0.05: under this half width a piece is one kerb-coloured nose
PAD = 0.4


def zones(data):
    out = []
    for r in data['roads']:
        s = r['s']
        for i in range(len(s) - 1):
            a, b = s[i], s[i + 1]
            ma, mb = (a[8] if len(a) > 8 else 0), (b[8] if len(b) > 8 else 0)
            if max(ma, mb) <= 0.05 or min(ma, mb) >= NARROW:
                continue
            ha, hb = max(ma, NARROW) + PAD, max(mb, NARROW) + PAD
            # the median's centre line is the road's centre plus the record's offset ((halfR - halfL) / 2 is the
            # carriageway middle; the median sits on the line between the two directions: the sample itself)
            pa, pb = (a[0], a[2]), (b[0], b[2])
            na, nb = (a[4], -a[3]), (b[4], -b[3])
            q = Polygon([(pa[0] + na[0] * ha, pa[1] + na[1] * ha), (pb[0] + nb[0] * hb, pb[1] + nb[1] * hb),
                         (pb[0] - nb[0] * hb, pb[1] - nb[1] * hb), (pa[0] - na[0] * ha, pa[1] - na[1] * ha)])
            if q.is_valid and q.area > 0:
                out.append(q)
    return shapely.union_all(out) if out else Polygon()


def drop(parts, data):
    Z = zones(data)
    if Z.is_empty:
        return parts, 0
    shapely.prepare(Z)
    keep = [p for p in parts if p[0] not in ('r', 'w', 'm') or not Z.contains(Point(p[2][0], p[2][2]))]
    return keep, len(parts) - len(keep)


def _test():
    # a road along +z with a median that is 3 wide, then narrows 3 -> 0.5 -> 0 over two samples
    s = [[0, 0, z, 0, 1, 0, 10, 10, m, 2, 4, m] for z, m in ((0, 3), (10, 3), (20, 0.5), (30, 0))]
    data = dict(roads=[dict(name='a', s=s)])
    parts = [('r', 'W', (0.0, 0.5, 15.0), (1, 0, 0), (0, 1, 0), (1, 1, 1)),   # on the 3 -> 0.5 piece: two kerbs at the start
             ('r', 'W', (0.0, 0.5, 25.0), (1, 0, 0), (0, 1, 0), (1, 1, 1)),   # the 0.5 -> 0 tip
             ('m', 'P', (0.0, 0.5, 5.0), (1, 0, 0), (0, 1, 0), (1, 1, 1)),    # full-width median
             ('R', 'P', (0.0, 0.0, 25.0), (1, 0, 0), (0, 1, 0), (1, 1, 1))]   # asphalt: never dropped
    kept, n = drop(parts, data)
    assert n == 2 and [p[2][2] for p in kept] == [5.0, 25.0], kept
    print('roads05_nose test ok')


if __name__ == '__main__':
    if sys.argv[1:] == ['test']:
        _test()
