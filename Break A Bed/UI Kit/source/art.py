"""Higher-quality 2D item art: shaded faces, thick dark silhouette outline, shine."""
import sys, math
from PIL import Image, ImageDraw, ImageFilter, ImageChops, ImageFont
from kit import FONT, mix

S = 4
OL = (24, 30, 22)

def outline(im, px):
    a = im.getchannel('A').point(lambda v: 255 if v > 40 else 0)
    big = a.filter(ImageFilter.MaxFilter(px * 2 + 1))
    o = Image.new('RGBA', im.size, OL + (0,)); o.putalpha(big)
    o.alpha_composite(im)
    return o

def grad_poly(d_img, pts, c1, c2, axis='y'):
    W, H = d_img.size
    m = Image.new('L', (W, H), 0); ImageDraw.Draw(m).polygon(pts, fill=255)
    xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
    g = Image.new('RGB', (W, H)); gd = ImageDraw.Draw(g)
    lo, hi = (min(ys), max(ys)) if axis == 'y' else (min(xs), max(xs))
    for v in range(int(lo), int(hi) + 1):
        t = (v - lo) / max(1, hi - lo); c = mix(c1, c2, t)
        if axis == 'y': gd.line((0, v, W, v), fill=c)
        else: gd.line((v, 0, v, H), fill=c)
    d_img.paste(g, (0, 0), m)

def stack(cx, cy, w, h, depth, layers=1):
    """one bundle of bills in 2:1 isometric; returns list of draw ops on a canvas"""
    pass

def cash_bundle(n=512, tilt=0):
    W = n * S
    im = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # isometric box: top diamond, left face, right face
    cx, cy = W * 0.5, W * 0.40
    a, b = W * 0.40, W * 0.20      # half-width / half-height of top diamond
    t = W * 0.26                   # thickness
    top = [(cx - a, cy), (cx, cy - b), (cx + a, cy), (cx, cy + b)]
    left = [(cx - a, cy), (cx, cy + b), (cx, cy + b + t), (cx - a, cy + t)]
    right = [(cx, cy + b), (cx + a, cy), (cx + a, cy + t), (cx, cy + b + t)]
    grad_poly(im, left, (70, 175, 55), (40, 120, 35))
    grad_poly(im, right, (55, 150, 45), (30, 95, 28))
    # bill edges on the side faces
    for i in range(1, 9):
        f = i / 9
        y1 = cy + t * f
        d.line([(cx - a, y1), (cx, cy + b + t * f)], fill=(150, 225, 120), width=int(W * 0.006))
        d.line([(cx, cy + b + t * f), (cx + a, y1)], fill=(120, 200, 100), width=int(W * 0.006))
    grad_poly(im, top, (150, 230, 110), (85, 190, 70))
    # inner border on top bill
    k = 0.82
    inner = [(cx + (x - cx) * k, cy + (y - cy) * k) for x, y in top]
    d.line(inner + [inner[0]], fill=(50, 140, 45), width=int(W * 0.008))
    # $ circle on top (squashed to the iso plane)
    r = W * 0.085
    d.ellipse((cx - r * 1.6, cy - r * 0.8, cx + r * 1.6, cy + r * 0.8), fill=(205, 245, 175), outline=(50, 140, 45), width=int(W * 0.008))
    f = ImageFont.truetype(FONT, int(W * 0.11))
    tmp = Image.new('L', (W, W), 0); ImageDraw.Draw(tmp).text((cx, cy), '$', font=f, anchor='mm', fill=255)
    tmp = tmp.resize((W, W)).transform((W, W), Image.AFFINE, (1, 0, 0, 0, 2, -cy), Image.BICUBIC)
    sq = Image.new('L', (W, W), 0); sq.paste(tmp.crop((0, 0, W, W)), (0, 0))
    im.paste((45, 130, 40, 255), (0, 0), sq.point(lambda v: v))
    # yellow paper band across the bundle (top + both sides)
    bw = W * 0.07
    def band_pts(u):  # u along the left->right diagonal of the top
        return u
    p1 = (cx - a * 0.5 - bw, cy - b * 0.5 + bw * 0.5); p2 = (cx + a * 0.5 - bw, cy + b * 0.5 + bw * 0.5)
    bt = [(cx - a * 0.5 - bw, cy - b * 0.5 - bw * 0.5 + bw), (cx - a * 0.5 + bw, cy - b * 0.5 - bw * 0.5),
          (cx + a * 0.5 + bw, cy + b * 0.5 - bw * 0.5), (cx + a * 0.5 - bw, cy + b * 0.5 + bw * 0.5)]
    grad_poly(im, bt, (255, 230, 90), (250, 190, 30), axis='x')
    bs = [(cx + a * 0.5 - bw, cy + b * 0.5 + bw * 0.5), (cx + a * 0.5 + bw, cy + b * 0.5 - bw * 0.5),
          (cx + a * 0.5 + bw, cy + b * 0.5 - bw * 0.5 + t), (cx + a * 0.5 - bw, cy + b * 0.5 + bw * 0.5 + t)]
    grad_poly(im, bs, (240, 180, 20), (200, 130, 10))
    bl = [(cx - a * 0.5 - bw, cy - b * 0.5 + bw * 0.5), (cx - a * 0.5 + bw, cy - b * 0.5 - bw * 0.5 + 0),
          (cx - a * 0.5 + bw, cy - b * 0.5 - bw * 0.5 + t), (cx - a * 0.5 - bw, cy - b * 0.5 + bw * 0.5 + t)]
    # (left band part is hidden behind the top, skip)
    # edges
    for poly in (top, left, right):
        d.line(poly + [poly[0]], fill=(30, 80, 25), width=int(W * 0.007))
    # shine
    sh = Image.new('L', (W, W), 0)
    ImageDraw.Draw(sh).polygon([(cx - a * 0.7, cy - b * 0.05), (cx - a * 0.25, cy - b * 0.75), (cx - a * 0.1, cy - b * 0.65), (cx - a * 0.55, cy + b * 0.05)], fill=120)
    sh = sh.filter(ImageFilter.GaussianBlur(W * 0.01))
    im.alpha_composite(Image.merge('RGBA', [Image.new('L', (W, W), 255)] * 3 + [sh]))
    im = outline(im, int(W * 0.018))
    return im.resize((n, n), Image.LANCZOS)

def cash_pile(n=512, count=3):
    W = n
    out = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    spots = {1: [(0, 0, 0.9)], 2: [(-0.12, 0.08, 0.7), (0.14, -0.06, 0.7)],
             3: [(-0.18, 0.12, 0.62), (0.18, 0.1, 0.62), (0.0, -0.12, 0.62)],
             5: [(-0.2, 0.18, 0.55), (0.2, 0.18, 0.55), (0, 0.05, 0.55), (-0.12, -0.12, 0.55), (0.14, -0.14, 0.55)]}[count]
    for dx, dy, sc in spots:
        b = cash_bundle(int(n * sc))
        out.alpha_composite(b, (int(W / 2 - b.width / 2 + dx * W), int(W / 2 - b.height / 2 + dy * W)))
    return out

if __name__ == '__main__':
    sheet = Image.new('RGBA', (1560, 520), (60, 180, 60, 255))
    for i, c in enumerate((1, 3, 5)):
        sheet.alpha_composite(cash_pile(512, c), (i * 520, 0))
    sheet.convert('RGB').save('art_test.png')
