import numpy as np
from scipy import ndimage as ndi
A = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
s = open('ring.b64').read().strip()
N, CELL, HALF = 140, 36, 2520
H = np.full((N, N), np.nan, np.float32); M = np.full((N, N), -1, np.int8)
p = 0
for j in range(N):
    z = -HALF + (j + 0.5)*CELL
    for i in range(N):
        x = -HALF + (i + 0.5)*CELL
        r = (x*x + z*z) ** 0.5
        if 1690 < r < 2530:
            v = A.index(s[p])*64 + A.index(s[p+1]); p += 2
            h, m = v >> 3, v & 7
            H[j, i] = h/2 - 150 if h < 511 else 100.0
            M[j, i] = m
assert p == len(s), (p, len(s))
print('cells', p//2, 'h', np.nanmin(H), np.nanmax(H), 'mats', {int(k): int((M == k).sum()) for k in range(-1, 8)})
# fill the holes (inside the ring, outside the world) with the nearest value so interpolation is clean
mask = np.isnan(H)
idx = ndi.distance_transform_edt(mask, return_distances=False, return_indices=True)
Hf = H[tuple(idx)]; Mf = M[tuple(idx)]
np.save('ring_h.npy', Hf); np.save('ring_m.npy', Mf)
