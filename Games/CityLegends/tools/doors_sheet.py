"""One picture per car for the notes (scissor doors, 2026-11-08): before (closed) / after (open) renders from tools/doors.py,
the jamb and the door's inside, and a shot from the game.

    python tools/doors_sheet.py build/doors/<car id> "<in-game shot.jpg or ->" "<out.jpg>" "<title>"
"""
import sys

from PIL import Image, ImageDraw, ImageFont

prefix, game, out, title = sys.argv[1:5]
W, H = 640, 400
tiles = [("1_closed", "before: doors shut"), ("3_open", "after: doors up"), ("8_both_front", "both doors"),
         ("6_jamb_rear", "rear jamb"), ("7_inner_panel", "inside of the door")]
ims = []
for name, label in tiles:
    ims.append((Image.open("%s_%s_doors.png" % (prefix, name)).convert("RGB"), label))
if game != "-":
    g = Image.open(game).convert("RGB")
    # (the game shot: cropped to the tile's shape round its middle)
    gw, gh = g.size
    tw = min(gw, int(gh * W / H))
    th = int(tw * H / W)
    x0, y0 = (gw - tw) // 2, (gh - th) // 2
    ims.append((g.crop((x0, y0, x0 + tw, y0 + th)), "in the game"))
cols = 3
rows = (len(ims) + cols - 1) // cols
sheet = Image.new("RGB", (W * cols, H * rows + 44), (20, 20, 24))
d = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype("arial.ttf", 22)
    big = ImageFont.truetype("arialbd.ttf", 28)
except OSError:
    font = big = ImageFont.load_default()
d.text((14, 7), title, fill=(255, 255, 255), font=big)
for i, (im, label) in enumerate(ims):
    x, y = (i % cols) * W, 44 + (i // cols) * H
    sheet.paste(im.resize((W, H)), (x, y))
    d.rectangle((x, y + H - 34, x + 12 + int(d.textlength(label, font=font)) + 12, y + H), fill=(0, 0, 0))
    d.text((x + 12, y + H - 30), label, fill=(255, 255, 255), font=font)
sheet.save(out, quality=88)
print("wrote", out)
