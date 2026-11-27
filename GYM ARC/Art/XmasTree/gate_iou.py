# python gate_iou.py -> silhouette IoU of the render vs the sheet's side view, and a side-by-side image
import os, numpy as np
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
sh = np.asarray(Image.open(os.path.join(HERE, "turnaround_sheet.png")).convert("RGB")).astype(int)[:600, :768]
mag = (sh[..., 0] > 200) & (sh[..., 2] > 200) & (sh[..., 1] < 90)
ref = ~mag; ref[560:] = False
rd = np.asarray(Image.open(os.path.join(HERE, "gate", "front.png")).convert("RGBA"))
mine = rd[..., 3] > 128
iou = (ref & mine).sum() / (ref | mine).sum()
print("silhouette IoU %.3f" % iou)
# the sheet draws the skirt as a tilted ellipse (perspective) that no flat ortho disc can match: score the tree above it too
t = slice(0, 505)
print("tree-only IoU (above skirt) %.3f" % ((ref[t] & mine[t]).sum() / (ref[t] | mine[t]).sum()))
diff = np.zeros((600, 768, 3), np.uint8); diff[ref & ~mine] = (255, 0, 0); diff[mine & ~ref] = (0, 120, 255); diff[ref & mine] = (200, 200, 200)
bg = Image.new("RGB", (768, 600), (255, 0, 255)); bg.paste(Image.fromarray(rd), (0, 0), Image.fromarray(rd))
side = Image.new("RGB", (768 * 3, 600)); side.paste(Image.fromarray(sh.astype(np.uint8)), (0, 0)); side.paste(bg, (768, 0)); side.paste(Image.fromarray(diff), (1536, 0))
side.save(os.path.join(HERE, "gate", "compare_front.png"))
