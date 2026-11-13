# Colossal eel: straighten the wavy side view. Axis = middle of the BODY (between the back line under the crest and the belly line),
# found from the navy flank band + the belly outline; the picture is resampled along that axis (arc length -> x, normal -> y).
import sys; sys.path.insert(0, '/tmp/claude-0/lm2/cr')
import gk, numpy as np, cv2, json
from PIL import Image
from scipy import ndimage as ndi
OUT = '/tmp/claude-0/lm2/cr/eel'
SH, fg = gk.load('/tmp/claude-0/lm2/cr/eel.png'); H, W = fg.shape
side = gk.comp_in(fg, (0, 60, 1536, 520))
R, G, B = SH[..., 0], SH[..., 1], SH[..., 2]
navy = side & (R < 70) & (G < 90) & (B > 70) & (B < 150) & (B > G + 15)
navy = ndi.binary_opening(navy, iterations=2)
cols = np.arange(200, 1489)
yb = np.array([np.where(side[:, x])[0].max() for x in cols], float); ytop = np.array([np.where(side[:, x])[0].min() for x in cols], float)
yn = np.full(len(cols), np.nan)
for i, x in enumerate(cols):
    ys = np.where(navy[:, x])[0]
    if len(ys) > 6: yn[i] = np.median(ys)
ok = ~np.isnan(yn) & (cols < 1230)
yn_i = np.interp(cols, cols[ok], yn[ok])
# the belly line near the head is hidden by the pink frill (x 1110..1260): bridge it
from scipy.interpolate import PchipInterpolator
keep = (cols < 1128) | (cols > 1262); yb = np.where(keep, yb, PchipInterpolator(cols[keep], yb[keep])(cols))
yt_body = yn_i - 0.20 * (yb - yn_i)                          # back line under the crest
headk = np.clip((cols - 1255) / 85.0, 0, 1)                  # on the head the outline itself is the top
yt_body = yt_body * (1 - headk) + ytop * headk
yc = ndi.gaussian_filter1d((yt_body + yb) / 2, 14)
# axis as a polyline, extended straight at the tail
ax = np.stack([cols.astype(float), yc], 1)
t0 = (ax[40] - ax[0]); t0 /= np.linalg.norm(t0)
ext = np.array([ax[0] - t0 * d for d in range(175, 0, -1)])
ax = np.r_[ext, ax]
seg = np.r_[0, np.cumsum(np.linalg.norm(np.diff(ax, axis=0), axis=1))]
S = int(seg[-1]); ss = np.arange(S)
C = np.stack([np.interp(ss, seg, ax[:, 0]), np.interp(ss, seg, ax[:, 1])], 1)
T = np.gradient(C, axis=0); T = np.stack([ndi.gaussian_filter1d(T[:, 0], 10), ndi.gaussian_filter1d(T[:, 1], 10)], 1); T /= np.linalg.norm(T, axis=1, keepdims=True)
N = np.stack([-T[:, 1], T[:, 0]], 1)                         # points down the sheet (+y) when the eel heads right
HH = 190; hh = np.arange(-HH, HH + 1)
mapx = (C[:, 0][None, :] + N[:, 0][None, :] * hh[:, None]).astype(np.float32); mapy = (C[:, 1][None, :] + N[:, 1][None, :] * hh[:, None]).astype(np.float32)
img = SH.copy(); img[~side] = (255, 0, 255)
rect = cv2.remap(img.astype(np.uint8), mapx, mapy, cv2.INTER_LINEAR, borderValue=(255, 0, 255))
Image.fromarray(rect).save(OUT + '/side_rect.png')
np.savez(OUT + '/axis.npz', C=C, N=N, yt=np.interp(C[:, 0], cols, yt_body), yb=np.interp(C[:, 0], cols, yb), HH=HH)
# check picture: the axis and body lines on the sheet, and the straightened view
chk = SH.copy().astype(np.uint8)
for i, x in enumerate(cols):
    for y, col in ((yt_body[i], (255, 255, 255)), (yb[i], (255, 255, 255)), (yc[i], (255, 0, 0)), (yn_i[i], (0, 0, 0))):
        cv2.circle(chk, (int(x), int(y)), 1, col, -1)
o = Image.new('RGB', (1536, 460 + rect.shape[0] * 1536 // rect.shape[1] + 10), (0, 0, 0)); o.paste(Image.fromarray(chk[60:520]), (0, 0))
o.paste(Image.fromarray(rect).resize((1536, rect.shape[0] * 1536 // rect.shape[1])), (0, 470)); o.save(OUT + '/rect_check.jpg', quality=88)
print('arc length px', S, 'rect', rect.shape)
