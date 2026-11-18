"""self-check for roads05_pbox_clip.clip_row: a 10-long, 6-wide P box with pavement under its first 4 studs (full width)
and under the left third of the rest -> one full-width piece of 4 and one left-third piece of 6."""
import numpy as np
import roads05_pbox_clip as C

row = C.fmt('P', np.array([5.0, -1.0, 0.0]), np.array([0.0, 0.0, 1.0]), np.array([0.0, 1.0, 0.0]), (6.0, 2.0, 10.0))
# box frame: R = +z (across), along = R x U = (0,0,1) x (0,1,0) = -x ; along runs x 10 -> 0
parts = [('P', 'B', (8.0, -0.5, 0.0), (1, 0, 0), (0, 1, 0), (4.0, 0.5, 6.0)),   # x 6..10, full width
         ('P', 'B', (3.0, -0.5, -2.0), (1, 0, 0), (0, 1, 0), (6.0, 0.5, 2.0))]  # x 0..6, z -3..-1
out = C.clip_row(row, C.Cover(parts))
got = sorted((round(float(r.split()[10]), 2), round(float(r.split()[12]), 2)) for r in out)
assert got == [(2.0, 6.0), (6.0, 4.0)], got
print('ok', got)
