import sys, json, numpy as np
from PIL import Image
sys.path.insert(0, '/tmp/claude-0/hk'); import hk
d = sys.argv[1]; C = json.load(open(sys.argv[2]))
SH, V, bb, PAL = hk.analyse(C); H, W = V['side'].shape
canvas = Image.new('RGB', (W, H), (255, 0, 255))
for k in ('side', 'top', 'front'):
    x0, x1, y0, y1 = bb[k]; im = Image.open(f'{d}/o_{k}.png').convert('RGBA'); im = im.crop(im.getbbox())
    sc_ = min((x1 - x0 + 1) / im.width, (y1 - y0 + 1) / im.height); im = im.resize((max(1, int(im.width * sc_)), max(1, int(im.height * sc_))))
    canvas.paste(im, (x0 + ((x1 - x0 + 1) - im.width) // 2, y0 + ((y1 - y0 + 1) - im.height) // 2), im)
sheet = Image.open(C['sheet']).convert('RGB')
both = Image.new('RGB', (W * 2 + 20, H), (40, 40, 40)); both.paste(sheet, (0, 0)); both.paste(canvas, (W + 20, 0))
both.resize((both.width // 2, both.height // 2)).save(d + '/compare.jpg', quality=88)
tiles = []; bad = 0; tot = 0
for i in range(6):
    on = np.array(Image.open(f'{d}/bf_{i}_1.png').convert('RGBA')); off = np.array(Image.open(f'{d}/bf_{i}_0.png').convert('RGBA'))
    extra = (off[..., 3] > 128) & (on[..., 3] <= 128)
    t = on[..., :3].copy(); t[on[..., 3] <= 128] = (40, 70, 110); t[extra] = (255, 0, 255)
    bad += extra.sum(); tot += (off[..., 3] > 128).sum(); tiles.append(Image.fromarray(t))
strip = Image.new('RGB', (300 * 6, 220)); [strip.paste(b_, (300 * i, 0)) for i, b_ in enumerate(tiles)]; strip.save(d + '/backfaces.jpg', quality=85)
heroes = [Image.open(f'{d}/hero_{i}.png').convert('RGB').resize((600, 400)) for i in range(3)]
hh = Image.new('RGB', (1800, 400)); [hh.paste(h, (600 * i, 0)) for i, h in enumerate(heroes)]; hh.save(d + '/hero.jpg', quality=88)
g = json.load(open(d + '/gates.json')); g['backface_frac'] = round(float(bad / max(1, tot)), 4); json.dump(g, open(d + '/gates.json', 'w'), indent=1)
print('backface frac', g['backface_frac'])
