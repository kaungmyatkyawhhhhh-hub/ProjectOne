# GYM ARC safety clothes (2 Nov hotfix): a classic Shirt (tank top) and Pants (gym shorts) template, 585x559.
import sys
from PIL import Image, ImageDraw
out = sys.argv[1]
TORSO = [(231, 8, 128, 64), (231, 74, 128, 128), (165, 74, 64, 128), (427, 74, 128, 128), (361, 74, 64, 128), (231, 204, 128, 64)]
LIMB_FACES = [(x, 355, 64, 128) for x in (19, 85, 151, 217, 308, 374, 440, 506)]
LIMB_TOPS = [(217, 289, 64, 64), (308, 289, 64, 64)]
def rects(draw, boxes, color, frac=1.0):
    for x, y, w, h in boxes:
        draw.rectangle([x, y, x + w - 1, y + int(h * frac) - 1], fill=color)
# tank top: the whole torso (chest, back, sides), arms bare
tank = Image.new("RGBA", (585, 559), (0, 0, 0, 0))
d = ImageDraw.Draw(tank)
rects(d, TORSO, (244, 241, 234, 255))
for x, y, w, h in TORSO[1:2] + TORSO[3:4]:  # a soft seam line near the hem, front and back
    d.rectangle([x, y + h - 10, x + w - 1, y + h - 7], fill=(222, 218, 208, 255))
tank.save(out + "/gymarc_safe_tank.png")
# shorts: the hips (whole lower torso) and each thigh to past mid-thigh, every side
shorts = Image.new("RGBA", (585, 559), (0, 0, 0, 0))
d = ImageDraw.Draw(shorts)
rects(d, TORSO, (30, 30, 34, 255))
rects(d, LIMB_TOPS, (30, 30, 34, 255))
rects(d, LIMB_FACES, (30, 30, 34, 255), 0.62)
for x, y, w, h in LIMB_FACES:  # a lighter hem band
    d.rectangle([x, y + int(h * 0.62) - 5, x + w - 1, y + int(h * 0.62) - 1], fill=(70, 70, 78, 255))
shorts.save(out + "/gymarc_safe_shorts.png")
print("ok")
