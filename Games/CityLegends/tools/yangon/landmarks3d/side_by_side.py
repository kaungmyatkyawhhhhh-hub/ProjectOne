"""side_by_side.py: photo | in-game picture, same height, labelled.  python side_by_side.py out.png photo.jpg game.jpg [label1 label2]"""
import sys
from PIL import Image, ImageDraw

out, a, b = sys.argv[1:4]
la = sys.argv[4] if len(sys.argv) > 4 else "photo"
lb = sys.argv[5] if len(sys.argv) > 5 else "in game (Studio, PlayLight 13)"
A, B = Image.open(a).convert("RGB"), Image.open(b).convert("RGB")
H = 720
A = A.resize((int(A.width * H / A.height), H))
B = B.resize((int(B.width * H / B.height), H))
im = Image.new("RGB", (A.width + B.width + 10, H + 34), (20, 20, 20))
im.paste(A, (0, 34))
im.paste(B, (A.width + 10, 34))
d = ImageDraw.Draw(im)
d.text((8, 10), la, fill=(255, 255, 255))
d.text((A.width + 18, 10), lb, fill=(255, 255, 255))
im.save(out)
print(out, im.size)
