# Statue: atlas + UVs + OBJ/MTL with per-corner UVs. Run after build.py (imports it).
import numpy as np, math, cv2, sys
from PIL import Image
from scipy import ndimage as ndi
exec(open('/tmp/claude-0/lm/st2/build.py').read())
TEX = 1024; ATL = np.zeros((TEX, TEX, 3), np.float32)
magish = (Rr > 150) & (Bb > 150) & (Gg < 130)
def nearest_fill(img, valid):
    idx = ndi.distance_transform_edt(~valid, return_distances=False, return_indices=True); return img[idx[0], idx[1]]
def view_img(k, clean):
    x0, x1, y0, y1 = bb[k]; m = VW[k]; img = SH.copy()
    valid = ndi.binary_erosion(m & ~magish, iterations=3)
    img = nearest_fill(img, valid)            # first: no magenta anywhere (the inpaint below would pull it in from outside the outline)
    if clean:      # corals are 3D parts with their own paint: paint them out of the head's texture
        bad = ndi.binary_dilation(coral & m, iterations=9)
        img = nearest_fill(img, valid & ~bad)
        im8 = cv2.inpaint(np.clip(img, 0, 255).astype(np.uint8), bad.astype(np.uint8), 6, cv2.INPAINT_TELEA).astype(np.float32)
        img = np.where(bad[..., None], im8, img)
    return img[y0:y1 + 1, x0:x1 + 1]
REG = {}
def put(name, img, ax, ay, scale):
    h, w = img.shape[:2]; nw, nh = int(round(w * scale)), int(round(h * scale))
    ATL[ay:ay + nh, ax:ax + nw] = cv2.resize(img, (nw, nh), interpolation=cv2.INTER_AREA); REG[name] = (ax, ay, scale)
put('front', view_img('front', True), 0, 0, 0.95); put('side', view_img('side', True), 512, 0, 0.93)
put('top', view_img('top', True), 0, 462, 0.82)
put('front_o', view_img('front', False), 372, 462, 0.6); put('side_o', view_img('side', False), 700, 462, 0.58)
# swatches (medians sampled from the sheet): dark cave, sand, rock top, rock side, stone
def med(mask): return np.median(SH[mask], 0)
sand_c = med(VW['top'] & (np.indices(SH.shape[:2])[1] < 200) & (Rr > 200) & (Gg > 160) & (Bb > 90) & (Bb < 170))
dark_c = med(VW['front'] & (Rr < 70) & (Gg < 90) & (Bb < 90))
teal = VW['front'] & (Bb > Rr + 8) & (Gg > Rr) & (Rr > 90) & (Rr < 175) & (np.indices(SH.shape[:2])[0] > 880)
rock_t = np.percentile(SH[teal], 75, 0); rock_s = np.percentile(SH[teal], 30, 0)
SW = {}
stone_c = med(VW['front'] & (Rr > 200) & (Gg > 170) & (Bb > 120) & (Bb < 190) & (np.indices(SH.shape[:2])[0] < 760) & (np.indices(SH.shape[:2])[0] > 700))
for i, (nm, c) in enumerate((('dark', dark_c), ('sand', sand_c), ('rock_t', rock_t), ('rock_s', rock_s), ('stone', stone_c))):
    ATL[960:1010, 20 + i * 70:70 + i * 70] = c; SW[nm] = ((45 + i * 70) / TEX, 1 - 985 / TEX)
# sand: a real patch of the top view's sand so the mound is not a flat colour
print('swatches', {k: tuple(int(v) for v in c) for k, c in (('sand', sand_c), ('dark', dark_c), ('rock_t', rock_t), ('rock_s', rock_s))})
Image.fromarray(np.clip(ATL, 0, 255).astype(np.uint8)).save(OUT + '/MB_LM_OceanKing_atlas.png')
def UV(reg, u, v):
    ax, ay, s = REG[reg]; k = reg.split('_')[0]; x0, x1, y0, y1 = bb[k]
    u = np.clip(u, x0 + 2, x1 - 2); v = np.clip(v, y0 + 2, y1 - 2)
    return ((ax + (u - x0) * s) / TEX, 1 - (ay + (v - y0) * s) / TEX)
def uv_front(p, reg='front'): return UV(reg, FCX + p[1] * SF, FFL - p[2] * SF)
def uv_side(p, reg='side'): return UV(reg, SCX + p[0] * SS, SFL - p[2] * SS)
def uv_top(p): return UV('top', 385 + (p[0] + 4.5) * 2.2, 745 - p[1] * 2.2)      # the skull's top = the cracked dome inside the moss ring (radius ~110 px round (385, 745))
def uv_back(p):          # the back of the head: the side view wrapped round (the rear edge of the side view meets itself at the spine)
    z = p[2]; cx = (front(z) + back(z)) / 2; th = math.atan2(abs(p[1]), -(p[0] - cx))        # 0 = dead astern, pi/2 = abeam
    f = min(1.0, th / (math.pi / 2)); u0 = SCX + back(z) * SS + 10; u1 = SCX + cx * SS
    return UV('side', u0 + (u1 - u0) * f, SFL - z * SS)
OBJ = []     # (name, V, F, UVc[m,3,2])
for i, (name, V, F) in enumerate(PARTS):
    tri = V[F]; n = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0]); n /= np.linalg.norm(n, axis=1, keepdims=True) + 1e-12
    uvc = np.zeros((len(F), 3, 2))
    for fi in range(len(F)):
        nx, ny, nz = n[fi]; P = tri[fi]
        if name == 'Cave': uvc[fi] = SW['dark']; continue
        if name == 'Sand': uvc[fi] = SW['sand']; continue
        if name == 'Rock': uvc[fi] = SW['rock_t'] if nz > 0.35 else SW['rock_s']; continue
        if name in ('CoralF', 'CoralS'):
            px = PILLOW_PX[i][1][F[fi]]; reg = 'front_o' if name == 'CoralF' else 'side_o'
            uvc[fi] = [UV(reg, u, v) for u, v in px]; continue
        if name == 'Core':
            w = (max(nx, 0), abs(ny), max(nz, 0) * 0.9, max(-nx, 0)); k = int(np.argmax(w))
            if nz < -0.6: uvc[fi] = SW['rock_s']; continue
            if k == 2 and P[:, 2].mean() < 90: uvc[fi] = SW['stone']; continue          # the tops of the base blocks: plain stone
            fn = (uv_front, uv_side, uv_top, uv_back)[k]
        elif name == 'Ear': fn = uv_side
        elif name == 'Block':
            if nz > 0.55: uvc[fi] = SW['stone']; continue
            fn = uv_side if abs(ny) >= abs(nx) * 0.8 else (uv_back if nx < 0 else uv_front)
        elif name in ('Gem', 'Ring', 'Nose', 'Brow', 'Moustache', 'Braid'): fn = uv_front if abs(nx) + 0.25 >= abs(ny) else uv_side
        else: fn = uv_front if abs(nx) >= abs(ny) else uv_side          # spikes: both faces of a horn wear the view they face
        uvc[fi] = [fn(p) for p in P]
    OBJ.append((name, V, F, uvc))
with open(OUT + '/model.obj', 'w') as fo:
    fo.write('mtllib model.mtl\n'); vo = 1; to = 1
    for i, (name, V, F, uvc) in enumerate(OBJ):
        fo.write(f'o {name}_{i}\nusemtl Atlas\n')
        for v in V: fo.write(f'v {v[0]:.4f} {v[2]:.4f} {-v[1]:.4f}\n')
        for t in uvc.reshape(-1, 2): fo.write(f'vt {t[0]:.5f} {t[1]:.5f}\n')
        for fi, f in enumerate(F): fo.write(f'f {f[0]+vo}/{to+fi*3} {f[1]+vo}/{to+fi*3+1} {f[2]+vo}/{to+fi*3+2}\n')
        vo += len(V); to += len(F) * 3
open(OUT + '/model.mtl', 'w').write('newmtl Atlas\nKd 1 1 1\nmap_Kd MB_LM_OceanKing_atlas.png\n')
print('wrote obj + atlas')
