"""Pictures from tools/details.py on one sheet, each with its name.

    python tools/details_sheet.py out.jpg cols width a.png b.png ...
    python tools/details_sheet.py out.jpg pairs width <prefix> shot1 shot2 ...   (before | after for each shot, one row each)
"""
import sys

from PIL import Image, ImageDraw, ImageFont

out, mode, W = sys.argv[1], sys.argv[2], int(sys.argv[3])
try:
    font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 22)
except OSError:
    font = ImageFont.load_default()


def tile(path, label):
    im = Image.open(path).convert("RGB")
    im = im.resize((W, int(im.height * W / im.width)))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, len(label) * 13 + 16, 32), fill=(20, 20, 24))
    d.text((8, 4), label, fill=(255, 255, 255), font=font)
    return im


if mode == "pairs":
    prefix, shots = sys.argv[4], sys.argv[5:]
    rows = [[tile("%s_%s_before.png" % (prefix, s), s + ": before"), tile("%s_%s_after.png" % (prefix, s), s + ": after")] for s in shots]
    cols = 2
else:
    cols = int(mode)
    files = sys.argv[4:]
    ims = [tile(f, f.replace("\\", "/").split("/")[-1].rsplit(".", 1)[0]) for f in files]
    rows = [ims[i : i + cols] for i in range(0, len(ims), cols)]
H = max(im.height for r in rows for im in r)
sheet = Image.new("RGB", (W * cols, H * len(rows)), (30, 30, 34))
for y, r in enumerate(rows):
    for x, im in enumerate(r):
        sheet.paste(im, (x * W, y * H))
sheet.save(out, quality=88)
print("sheet", out, sheet.size)
