"""MEGA BITE UI v2: clean the cut pieces (edge fringe, studs that would stretch), split the window ribbon/coral, write the
final images + slice manifest. python3 ui_finish.py"""
import json, os
import numpy as np
from PIL import Image
from scipy import ndimage as ndi
IN, OUT = 'out', 'final'
os.makedirs(OUT, exist_ok=True)
NAVY = np.array([14, 31, 61], np.float32)

def load(n): return np.asarray(Image.open(f'{IN}/{n}.png').convert('RGBA')).astype(np.float32)
def save(a, n): Image.fromarray(a.clip(0, 255).astype(np.uint8)).save(f'{OUT}/{n}.png')

def defringe(a):
    al = a[..., 3]
    edge = (al > 0) & (al < 250)
    # any partly transparent pixel takes the outline colour (all pieces have a dark navy outline): no purple halo
    a[edge, :3] = NAVY
    return a

def erase_studs(a, keep_corners=True, sides=True):
    """studs on straight edges would stretch in a 9-slice: copy the rim profile over them from beside the stud"""
    h, w = a.shape[:2]
    rgb = a[..., :3]; al = a[..., 3] > 128
    bright = al & (rgb.min(-1) > 205)
    lab, n = ndi.label(bright)
    for i in range(1, n + 1):
        yy, xx = np.where(lab == i)
        if len(yy) < 25 or len(yy) > 1500: continue
        cy, cx = yy.mean(), xx.mean(); r = max(np.ptp(yy), np.ptp(xx)) / 2 + 5
        # only studs on the rim (near the outline), not shine bands: roundish
        if max(np.ptp(yy), np.ptp(xx)) > 2.2 * (min(np.ptp(yy), np.ptp(xx)) + 1): continue
        nearTop, nearBot = cy < h * 0.2, cy > h * 0.8
        nearL, nearR = cx < w * 0.2, cx > w * 0.8
        corner = (nearTop or nearBot) and (nearL or nearR)
        if keep_corners and corner: continue
        y0, y1 = int(max(cy - r, 0)), int(min(cy + r + 1, h)); x0, x1 = int(max(cx - r, 0)), int(min(cx + r + 1, w))
        if (nearTop or nearBot) and not (nearL or nearR):      # top/bottom edge: copy columns from the left
            sh = int(2 * r + 6)
            src = a[y0:y1, x0 - sh:x1 - sh] if x0 - sh >= 0 else a[y0:y1, x0 + sh:x1 + sh]
            a[y0:y1, x0:x1] = src
        elif sides and (nearL or nearR) and not (nearTop or nearBot):    # left/right edge: copy rows from above
            sh = int(2 * r + 6)
            src = a[y0 - sh:y1 - sh, x0:x1] if y0 - sh >= 0 else a[y0 + sh:y1 + sh, x0:x1]
            a[y0:y1, x0:x1] = src
    return a

M = {}
def put(name, a, slice_=None, note=''):
    a = defringe(a)
    save(a, name)
    h, w = a.shape[:2]
    M[name] = dict(size=[w, h], slice=slice_, note=note)

# --- buttons sheet: 6 pills + 4 round bases
pills = ['Green', 'Gold', 'Red', 'Blue', 'Purple', 'Grey']
for i, c in enumerate(pills):
    a = erase_studs(load(f'Buttons_{i + 1:02d}'), sides=False)
    h, w = a.shape[:2]
    put(f'Pill{c}', a, [150, h // 2 - 6, w - 150, h // 2 + 6], 'pill: ends fixed, middle stretches; SliceScale = height / image height')
for i, c in enumerate(['Turquoise', 'Gold', 'Coral', 'Blue']):
    put(f'Round{c}', load(f'Buttons_{i + 7:02d}'), None, 'round icon-button base (fixed)')

# --- frames sheet: 01 window, 02 X, 03 plus, 04 capsule, 05 square panel, 06 progress trough
put('Close', load('Frames_02'), None, 'red round X (fixed)')
put('Plus', load('Frames_03'), None, 'green round plus (fixed)')
a = erase_studs(load('Frames_04'), sides=False); h, w = a.shape[:2]
put('Capsule', a, [120, h // 2 - 4, w - 120, h // 2 + 4], 'counter/toast capsule')
a = erase_studs(load('Frames_05')); h, w = a.shape[:2]
put('Panel', a, [86, 86, w - 86, h - 86], 'window / panel 9-slice (corner studs kept)')
a = erase_studs(load('Frames_06'), sides=False); h, w = a.shape[:2]
put('Trough', a, [64, h // 2 - 3, w - 64, h // 2 + 3], 'progress bar trough')
# window: lift the ribbon (seafoam green) and the coral + shell ornament off as their own images
win = load('Frames_01'); h, w = win.shape[:2]
rgb = win[..., :3]; al = win[..., 3] > 10
r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
green = al & (g > r + 40) & (g > b - 10) & (g > 110)
rib = ndi.binary_fill_holes(ndi.binary_closing(green, iterations=4))
lab, n = ndi.label(rib); s = ndi.sum(rib, lab, range(1, n + 1)); rib = lab == (int(np.argmax(s)) + 1)
rib = ndi.binary_opening(rib, iterations=2)
# rebuild the ribbon from its per-column top/bottom (median-smoothed), so the rim it sat on leaves no jagged bits
cols = np.where(rib.any(0))[0]
tops = np.array([np.where(rib[:, c])[0].min() for c in cols]); bots = np.array([np.where(rib[:, c])[0].max() for c in cols])
tops = ndi.median_filter(tops, 21); bots = ndi.median_filter(bots, 9)
rib2 = np.zeros_like(rib)
for c, t_, b_ in zip(cols, tops, bots): rib2[t_:b_ + 1, c] = True
rib = rib2 & ndi.binary_dilation(rib, iterations=6)
ribd = ndi.binary_dilation(rib, iterations=4)                 # a clean navy outline drawn around the green ribbon
ribd = ndi.binary_fill_holes(ndi.binary_closing(ribd, iterations=6))
wr = win.copy(); wr[ribd & ~rib, :3] = NAVY
band8 = ribd & ~ndi.binary_erosion(ribd, iterations=9)
wr[band8 & (wr[..., :3].min(-1) > 150), :3] = NAVY            # the window rim's white highlight bits on the ribbon edge
wr[band8 & (wr[..., 2] > wr[..., 1] + 20), :3] = NAVY         # and blue rim flecks
wr[..., 3] = np.where(ribd, 255, 0)
yy, xx = np.where(ribd)
rb = wr[yy.min():yy.max() + 1, xx.min():xx.max() + 1].copy()
put('Ribbon', rb, [int(rb.shape[1] * 0.3), 0, int(rb.shape[1] * 0.7), rb.shape[0]], 'title ribbon: middle stretches horizontally')
coral = al & (((r > 190) & (g < 170) & (b < 170)) | ((r > 200) & (g > 170) & (b < 170) & (b > 100)))   # coral pink-red + cream shell
coral[:, int(w * 0.25):] = False; coral[int(h * 0.3):] = False
coral = ndi.binary_closing(coral, iterations=3)
cd = ndi.binary_fill_holes(ndi.binary_dilation(coral, iterations=5) & al & ((rgb.sum(-1) < 200) | coral))
yy, xx = np.where(cd)
co = win[yy.min():yy.max() + 1, xx.min():xx.max() + 1].copy(); co[..., 3] *= cd[yy.min():yy.max() + 1, xx.min():xx.max() + 1]
put('Coral', co, None, 'corner ornament for big windows (top-left)')
# --- cards sheet: 8 rarity cards
for i, c in enumerate(['Common', 'Uncommon', 'Rare', 'Epic', 'Legendary', 'Mythic', 'Secret', 'Locked']):
    a = erase_studs(load(f'Cards_{i + 1:02d}')); h, w = a.shape[:2]
    put(f'Card{c}', a, [80, 80, w - 80, h - 120], 'rarity card: name strip in the fixed bottom part')
json.dump(M, open(f'{OUT}/manifest.json', 'w'), indent=1)
print(len(M), 'assets'); print({k: v['size'] for k, v in M.items()})

# --- ribbons sheet (straight banners: the arched window ribbon couldn't be 9-sliced)
for idx, c in [(1, 'Green'), (3, 'Blue'), (4, 'Gold'), (5, 'Red')]:
    a = load(f'Ribbons_{idx:02d}'); h, w = a.shape[:2]
    put(f'Banner{c}', a, [175, 0, w - 175, h], 'straight title banner: tails+caps fixed, middle stretches; SliceScale = height / image height')
put('Sunburst', load('Ribbons_02'), None, 'reward pop background (rotate it)')
put('Badge', load('Ribbons_06'), None, 'red notification badge')
put('Pearl', load('Ribbons_07'), None, 'pearl')
json.dump(M, open(f'{OUT}/manifest.json', 'w'), indent=1)
print('ribbons added', len(M))
