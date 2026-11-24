# GYM ARC icon post (25 Nov): grade + vignette + logo in the empty corner + 512 export + 60 px test + side-by-side vs Power Lifters.
import sys, numpy as np
from PIL import Image, ImageFilter, ImageEnhance, ImageDraw
raw, logo_p, out, corner = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
logo_w = float(sys.argv[5]) if len(sys.argv) > 5 else 0.46
im = Image.open(raw).convert("RGB")
N = im.size[0]
a = np.asarray(im).astype(np.float32) / 255
# contrast S-curve + saturation
a = np.clip(a, 0, 1); a = a * a * (3 - 2 * a) * 0.35 + a * 0.65
g = a.mean(axis=2, keepdims=True); a = np.clip(g + (a - g) * 1.06, 0, 1)
# vignette (darker corners pull the eye to the body)
yy, xx = np.mgrid[0:N, 0:N] / N - 0.5
v = 1 - 0.55 * np.clip((np.sqrt(xx**2 + yy**2) - 0.28) / 0.45, 0, 1) ** 1.6
a = a * v[..., None]
im = Image.fromarray((a * 255).astype(np.uint8))
im = im.filter(ImageFilter.UnsharpMask(radius=2, percent=60, threshold=2))
if logo_p != "-":
    lg = Image.open(logo_p).convert("RGBA"); lg = lg.crop(lg.getbbox())
    w = int(N * logo_w); h = int(w * lg.size[1] / lg.size[0]); lg = lg.resize((w, h), Image.LANCZOS)
    m = int(N * 0.05)
    pos = {"tr": (N - w - m, m), "tl": (m, m), "br": (N - w - m, N - h - m), "bl": (m, N - h - m), "bc": ((N - w) // 2, N - h - m)}[corner]
    # soft dark shadow under the logo for read
    sh = Image.new("RGBA", lg.size, (0, 0, 0, 0)); sh.putalpha(lg.split()[3].point(lambda p: int(p * 0.55)))
    sh = sh.filter(ImageFilter.GaussianBlur(N * 0.012))
    base = im.convert("RGBA"); base.alpha_composite(sh, (pos[0] + int(N * 0.006), pos[1] + int(N * 0.01))); base.alpha_composite(lg, pos)
    im = base.convert("RGB")
im.save(out + ".png")
im.resize((512, 512), Image.LANCZOS).save(out + "_512.png")
arr = np.asarray(im.resize((64, 64), Image.LANCZOS)).astype(np.float32) / 255
lum = arr @ np.array([0.2126, 0.7152, 0.0722])
print("mean@64 %.3f  near-black %.0f%%" % (lum.mean(), (lum < 0.12).mean() * 100))
