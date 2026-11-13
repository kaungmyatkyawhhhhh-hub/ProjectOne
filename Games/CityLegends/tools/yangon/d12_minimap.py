"""Yangon map, build step 9 (13 Nov 2026): the minimap picture tiles.

Same look and format as tools/minimap_art.py (Monaco): a night map at 2 studs a pixel, 1024 x 512 tiles
(2048 x 1024 studs each). Ground green-grey, Inya Lake and the ponds (OSM outlines), every building plot,
the roads with pavements and dark edges (the three main roads in gold), the flyover decks over them, the
Hanthawaddy Roundabout. The far city past the map's edge is left plain ground.

Run from Games/CityLegends:
  python tools/yangon/d12_minimap.py                    -> build/minimap_ygn/tile_<c>_<r>.png + preview.png
  python tools/yangon/d12_minimap.py --lua ids.json     -> src/client/YangonMapArt.lua
(ids.json: {"tile_0_0": "rbxassetid://...", ...}; the rim and the arrow stay Monaco's, MinimapArt.)
"""
import json, math, os, sys

from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(ROOT, 'build', 'minimap_ygn')

src = open(os.path.join(HERE, 'd10_plots.py'), encoding='utf-8').read()
ns = {'__file__': os.path.join(HERE, 'd10_plots.py')}
exec(compile(src[:src.index('# the landmarks first')], 'd10', 'exec'), ns)
roads, water, CUT, RING, MAP = ns['roads'], ns['water'], ns['CUT'], ns['RING'], ns['MAP']
MX0, MX1, MZ0, MZ1 = ns['X0'] - 40, ns['X1'] + 40, ns['Z0'] - 40, ns['Z1'] + 40
data = json.load(open(os.path.join(MAP, 'ygn_roads_v3.json'), encoding='utf-8'))
plots = json.load(open(os.path.join(MAP, 'ygn_plots.json'), encoding='utf-8'))['plots']

SPP = 2.0
TILE_W, TILE_H = 1024, 512
TS_X, TS_Z = TILE_W * SPP, TILE_H * SPP
# the drawn area: the map plus a margin, snapped to whole tiles
X0 = math.floor((MX0 - 300) / 64) * 64
Z0 = math.floor((MZ0 - 300) / 64) * 64
COLS = math.ceil((MX1 + 300 - X0) / TS_X)
ROWS = math.ceil((MZ1 + 300 - Z0) / TS_Z)
W, H = TILE_W * COLS, TILE_H * ROWS
SS = 2

# Monaco's night palette
OUTSIDE = (34, 44, 42)  # (= GROUND: the grass skirt goes on past the edge in the game)
GROUND = (34, 44, 42)
WATER = (14, 36, 64)
WATER_EDGE = (30, 70, 108)
BUILDING = (60, 68, 84)
BUILDING_EDGE = (92, 102, 122)
LANDMARK = (96, 84, 60)
LANDMARK_EDGE = (170, 146, 92)
SHADOW = (18, 22, 28)
PAVEMENT = (64, 68, 80)
EDGE = (12, 14, 18)
STREET = (156, 164, 180)
ROUTE = (222, 184, 98)
WALK = 10.0


def px(x, z):
    return ((x - X0) / SPP * SS, (z - Z0) / SPP * SS)


def runs(r):
    """A road's centre line as runs of samples, split at its cut samples (a deck carries it there)."""
    cs = CUT.get(r['name'], set())
    out, cur = [], []
    for k, s in enumerate(r['s']):
        if k in cs:
            if len(cur) > 1:
                out.append(cur)
            cur = []
        else:
            cur.append(s)
    if len(cur) > 1:
        out.append(cur)
    return out


def stroke(d, pts, width, col):
    p = [px(s[0], s[2]) for s in pts]
    w = max(1, int(round(width / SPP * SS)))
    d.line(p, fill=col, width=w)
    rad = w / 2
    for q in (p[0], p[-1]) if len(p) > 1 else ():
        d.ellipse((q[0] - rad, q[1] - rad, q[0] + rad, q[1] + rad), fill=col)
    for q in p[1:-1]:
        if w > 6:
            d.ellipse((q[0] - rad, q[1] - rad, q[0] + rad, q[1] + rad), fill=col)


def ring(d, cx, cz, r0, r1, col):
    a, b = px(cx - r1, cz - r1), px(cx + r1, cz + r1)
    d.ellipse((a[0], a[1], b[0], b[1]), fill=col)
    if r0 > 0:
        a, b = px(cx - r0, cz - r0), px(cx + r0, cz + r0)
        d.ellipse((a[0], a[1], b[0], b[1]), fill=GROUND)


def plot_poly(p, grow=0.0):
    fx, fz = p['fx'], p['fz']
    ax, az = -fz, fx
    hw, hd = p['w'] / 2 + grow, p['d'] / 2 + grow
    out = []
    for u, v in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        out.append(px(p['x'] + ax * u * hw + fx * v * hd, p['z'] + az * u * hw + fz * v * hd))
    return out


def render():
    os.makedirs(OUT, exist_ok=True)
    im = Image.new('RGB', (W * SS, H * SS), OUTSIDE)
    d = ImageDraw.Draw(im)
    a, b = px(MX0, MZ0), px(MX1, MZ1)
    d.rectangle((a[0], a[1], b[0], b[1]), fill=GROUND)
    # water, with a lighter edge
    for poly in water:
        d.polygon([px(x, z) for x, z in poly], fill=WATER_EDGE)
    im2 = im.filter(ImageFilter.MinFilter(9))  # (shrinks the light water: leaves an edge band)
    mask = Image.new('L', im.size, 0)
    md = ImageDraw.Draw(mask)
    for poly in water:
        md.polygon([px(x, z) for x, z in poly], fill=255)
    inner = mask.filter(ImageFilter.MinFilter(9))
    im.paste(Image.new('RGB', im.size, WATER), (0, 0), inner)
    d = ImageDraw.Draw(im)
    # building plots: a soft shadow, then the roof with a lighter edge
    sh = Image.new('L', im.size, 0)
    sd = ImageDraw.Draw(sh)
    for p in plots:
        sd.polygon([(x + 5, y + 7) for x, y in plot_poly(p)], fill=150)
    sh = sh.filter(ImageFilter.GaussianBlur(5))
    im.paste(Image.new('RGB', im.size, SHADOW), (0, 0), sh)
    d = ImageDraw.Draw(im)
    for p in plots:
        lm = p.get('landmark')
        d.polygon(plot_poly(p), fill=LANDMARK_EDGE if lm else BUILDING_EDGE)
        d.polygon(plot_poly(p, -2.5), fill=LANDMARK if lm else BUILDING)
    # roads: dark edge, pavement, carriageway; streets first, the main roads over them
    order = sorted(roads, key=lambda r: -r.get('rank', 99))
    for layer in ('edge', 'walk', 'road'):
        for r in order:
            half = r.get('half', 16)
            walk = r.get('walkL', WALK) if r.get('kind') == 'side' else WALK
            for run in runs(r):
                if layer == 'edge':
                    stroke(d, run, 2 * (half + walk) + 4, EDGE)
                elif layer == 'walk':
                    stroke(d, run, 2 * (half + walk), PAVEMENT)
                else:
                    stroke(d, run, 2 * half - 4, ROUTE if r.get('kind') in ('route', 'side') else STREET)
    # the roundabout (its lanes at radius 76 and 96: the carriageway 66..106)
    cx, cz = RING[0], RING[1]
    ring(d, cx, cz, 60, 112, EDGE)
    ring(d, cx, cz, 62, 110, PAVEMENT)
    ring(d, cx, cz, 68, 104, ROUTE)
    a, b = px(cx - 60, cz - 60), px(cx + 60, cz + 60)
    d.ellipse((a[0], a[1], b[0], b[1]), fill=(40, 62, 48))
    # flyover decks over everything: a shadow, an edge, the deck
    for deck in data.get('decks', []):
        s = deck['s']
        if len(s) < 2:
            continue
        half = max(max(q[6], q[7]) for q in s) if len(s[0]) > 7 else 32
        stroke(d, [[q[0] + 6, 0, q[2] + 8] for q in s], 2 * half + 8, SHADOW)
        stroke(d, s, 2 * half + 6, EDGE)
        stroke(d, s, 2 * half - 4, ROUTE)
    final = im.resize((W, H), Image.LANCZOS)
    kept = []
    for c in range(COLS):
        for r in range(ROWS):
            t = final.crop((c * TILE_W, r * TILE_H, (c + 1) * TILE_W, (r + 1) * TILE_H))
            path = os.path.join(OUT, f'tile_{c}_{r}.png')
            lo, hi = zip(*t.getextrema())
            if max(hi) - min(lo) <= 2:  # plain ground: not drawn (the minimap's backing is that colour)
                if os.path.exists(path):
                    os.remove(path)
                continue
            t.save(path)
            kept.append(f'tile_{c}_{r}')
    json.dump(kept, open(os.path.join(OUT, 'kept.json'), 'w'))
    print(len(kept), 'tiles with something on them')
    final.resize((W // 4, H // 4), Image.LANCZOS).save(os.path.join(OUT, 'preview.png'))
    print('x0', X0, 'z0', Z0, 'cols', COLS, 'rows', ROWS, '->', OUT)


def write_lua(ids_path):
    ids = json.load(open(ids_path))
    lines = [
        '-- generated by tools/yangon/d12_minimap.py: do not edit',
        '-- the Yangon map as picture tiles (world studs); the rim and the arrow are MinimapArt\'s',
        'return {',
        f'\tx0 = {X0}, z0 = {Z0}, tileStuds = Vector2.new({TS_X:g}, {TS_Z:g}), cols = {COLS}, rows = {ROWS},',
        f'\tmap = {{ x0 = {MX0:.0f}, z0 = {MZ0:.0f}, x1 = {MX1:.0f}, z1 = {MZ1:.0f} }},',
        '\ttiles = {',
    ]
    for c in range(COLS):
        for r in range(ROWS):
            if f'tile_{c}_{r}' not in ids:
                continue
            lines.append(f'\t\t{{ col = {c}, row = {r}, image = "{ids[f"tile_{c}_{r}"]}" }},')
    lines += ['\t},', '}']
    path = os.path.join(ROOT, 'src', 'client', 'YangonMapArt.lua')
    open(path, 'w', newline='\n').write('\n'.join(lines) + '\n')
    print('wrote', path)


if __name__ == '__main__':
    if len(sys.argv) > 2 and sys.argv[1] == '--lua':
        write_lua(sys.argv[2])
    else:
        render()
