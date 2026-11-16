"""Pagoda kit flicker / overlap test (owner rule, 16 Nov): every class x shape assembled as placed (base + bell + top +
hti), scaled to the SMALLEST real width of its class (smaller scale = smaller gaps), through flicker_check.check.
Also counts same-mesh duplicate triangles.   python pagoda_kit_check.py"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import pagoda_kit as K  # noqa: E402
from flicker_check import check  # noqa: E402

MIN_W_M = {'XS': 2.5, 'S': 5.0, 'M': 12.0, 'L': 25.0, 'XL': 45.0}
bad_all = 0
for cls in K.CLASSES:
    k = MIN_W_M[cls] * 3.0 / K.CLASSES[cls][1]
    for sh in K.SHAPES:
        items, dup = [], 0
        for nm, m in (('BASE', K.base_piece(cls, sh)), ('BELL', K.bell_piece(cls)), ('TOP', K.top_piece(cls)), ('HTI', K.hti_piece(cls))):
            seen = set()
            for t in range(0, len(m.T), 3):
                tri = tuple(tuple(c * k for c in m.P[m.T[t + q]]) for q in range(3))
                key = tuple(sorted(tuple(round(c, 4) for c in p) for p in tri))
                if key in seen:
                    dup += 1
                seen.add(key)
                items.append((tri, nm))
        bad, _ = check(items)
        bad_all += len(bad) + dup
        print('%-3s %-4s tris %5d  flicker pairs %d  duplicate tris %d' % (cls, sh, len(items), len(bad), dup))
print('TOTAL problems', bad_all)
