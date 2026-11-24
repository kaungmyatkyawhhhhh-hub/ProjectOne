# Classic Roblox-style confident smirk (black decal eyes, a small highlight, cocky brows, side smirk). 1024 = the head front.
import sys
from PIL import Image, ImageDraw
OUT = sys.argv[1]; N = 1024; INK = (20, 14, 12, 255)
img = Image.new("RGBA", (N, N), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
ey, ex = 455, 140
for s in (-1, 1):
    cx = N/2 + s*ex
    # half-lidded confident eyes: a black oval with the top cut flat by the lid line
    d.ellipse((cx-40, ey-62, cx+40, ey+62), fill=INK)
    d.rectangle((cx-50, ey-80, cx+50, ey-22), fill=(0, 0, 0, 0))
    d.line((cx-52, ey-24, cx+52, ey-20 - 6*s), fill=INK, width=18)
    d.ellipse((cx-12+10, ey-6, cx+12+10, ey+18), fill=(255, 255, 255, 255))
# brows: left flat-low, right raised (cocky)
d.line((N/2-ex-70, ey-95, N/2-ex+55, ey-80), fill=INK, width=26)
d.line((N/2+ex-55, ey-105, N/2+ex+72, ey-135), fill=INK, width=26)
# smirk
pts = [(N/2 - 120 + 250*t, 660 - 60*(t**2.3)) for t in [i/40 for i in range(41)]]
d.line(pts, fill=INK, width=22, joint="curve")
for p in (pts[0], pts[-1]): d.ellipse((p[0]-11, p[1]-11, p[0]+11, p[1]+11), fill=INK)
img.save(f"{OUT}/face_classic_smirk.png"); Image.new("RGB", (N, N), (0, 0, 0)).save(f"{OUT}/face_classic_smirk_glow.png")
