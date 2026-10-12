import math, os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops
N = 256

def white(alpha):
    im = Image.new('RGBA', alpha.size, (255, 255, 255, 0)); im.putalpha(alpha); return im

def star4(thin=0.06):
    W = N * 4; a = Image.new('L', (W, W), 0); d = ImageDraw.Draw(a); c = W / 2
    pts = []
    for i in range(8):
        ang = -math.pi / 2 + i * math.pi / 4; r = W * 0.48 if i % 2 == 0 else W * thin
        pts.append((c + r * math.cos(ang), c + r * math.sin(ang)))
    d.polygon(pts, fill=255)
    halo = Image.new('L', (W, W), 0); ImageDraw.Draw(halo).ellipse((W*.35, W*.35, W*.65, W*.65), fill=200)
    a = ImageChops.lighter(a, halo.filter(ImageFilter.GaussianBlur(W * .06)))
    return white(a.resize((N, N), Image.LANCZOS))

def glow():
    a = Image.new('L', (N, N), 0); ImageDraw.Draw(a).ellipse((N*.2, N*.2, N*.8, N*.8), fill=255)
    return white(a.filter(ImageFilter.GaussianBlur(N * .13)))

def ring():
    a = Image.new('L', (N, N), 0); ImageDraw.Draw(a).ellipse((N*.12, N*.12, N*.88, N*.88), outline=255, width=int(N*.06))
    return white(ImageChops.lighter(a, a.filter(ImageFilter.GaussianBlur(N*.04))))

def swirl():
    W = N * 4; a = Image.new('L', (W, W), 0); d = ImageDraw.Draw(a); c = W / 2
    for arm in range(3):
        pts = []
        for k in range(60):
            t = k / 59; ang = arm * 2 * math.pi / 3 + t * 3.2; r = W * (0.06 + 0.38 * t)
            pts.append((c + r * math.cos(ang), c + r * math.sin(ang)))
        for k in range(len(pts) - 1):
            w = int(W * 0.05 * (1 - k / len(pts)) + 4)
            d.line((pts[k], pts[k + 1]), fill=255, width=w)
    return white(a.filter(ImageFilter.GaussianBlur(W * .006)).resize((N, N), Image.LANCZOS))

def spark():
    W = N * 4; a = Image.new('L', (W, W), 0)
    ImageDraw.Draw(a).ellipse((W*.46, W*.04, W*.54, W*.96), fill=255)
    a = ImageChops.lighter(a, a.filter(ImageFilter.GaussianBlur(W*.03)))
    return white(a.resize((N, N), Image.LANCZOS))

def smoke():
    a = Image.new('L', (N, N), 0); d = ImageDraw.Draw(a)
    for x, y, r in ((.5,.5,.3),(.35,.55,.2),(.65,.55,.2),(.5,.38,.2)):
        d.ellipse((N*(x-r), N*(y-r), N*(x+r), N*(y+r)), fill=200)
    return white(a.filter(ImageFilter.GaussianBlur(N*.06)))

def shards():
    W = N * 4; a = Image.new('L', (W, W), 0); d = ImageDraw.Draw(a)
    d.polygon([(W*.5, W*.05), (W*.62, W*.55), (W*.5, W*.95), (W*.4, W*.5)], fill=255)
    return white(a.resize((N, N), Image.LANCZOS))

def beam_tex():
    a = Image.new('L', (N, N), 0); px = a.load()
    for x in range(N):
        for y in range(N):
            v = max(0, 1 - abs(y - N/2) / (N/2)); px[x, y] = int(255 * v ** 2.2)
    return white(a)

if __name__ == '__main__':
    out = sys.argv[1]; os.makedirs(out, exist_ok=True)
    items = dict(star4=star4(), glow=glow(), ring=ring(), swirl=swirl(), spark=spark(), smoke=smoke(), shard=shards(), beam=beam_tex())
    for k, v in items.items(): v.save(f'{out}/fx-{k}.png')
    sheet = Image.new('RGBA', (len(items) * 140 + 10, 150), (30, 30, 40, 255))
    for i, v in enumerate(items.values()): sheet.alpha_composite(v.resize((130, 130)), (10 + i * 140, 10))
    sheet.convert('RGB').save(f'{out}/_fx-sheet.png')
