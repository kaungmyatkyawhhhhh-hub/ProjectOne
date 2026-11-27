# Shared gate for prop sheets: python gate_views.py <ArtFolder> <view>:<sheet x0>:<ymax> ...
# Compares gate/<view>.png (768x600 render, transparent bg) with sheet columns x0..x0+768, rows 0..600 (rows >= ymax ignored: labels).
import sys, os, numpy as np
from PIL import Image
D = sys.argv[1]
sh = np.asarray(Image.open(os.path.join(D, "turnaround_sheet.png")).convert("RGB")).astype(int)
for spec in sys.argv[2:]:
    view, x0, ymax = spec.split(":"); x0, ymax = int(x0), int(ymax)
    s = np.full((600, 768, 3), (255, 0, 255)); s[:, :min(768, sh.shape[1] - x0)] = sh[:600, x0:x0 + 768]
    ref = ~((s[..., 0] > 200) & (s[..., 2] > 200) & (s[..., 1] < 90)); ref[ymax:] = False
    rd = np.asarray(Image.open(os.path.join(D, "gate", view + ".png")).convert("RGBA"))
    mine = rd[..., 3] > 128; mine[ymax:] = False
    iou = (ref & mine).sum() / max(1, (ref | mine).sum())
    print("%s IoU %.3f" % (view, iou))
    diff = np.zeros((600, 768, 3), np.uint8); diff[ref & ~mine] = (255, 0, 0); diff[mine & ~ref] = (0, 120, 255); diff[ref & mine] = (200, 200, 200)
    bg = Image.new("RGB", (768, 600), (255, 0, 255)); bg.paste(Image.fromarray(rd), (0, 0), Image.fromarray(rd))
    out = Image.new("RGB", (768 * 3, 600)); out.paste(Image.fromarray(s.astype(np.uint8)), (0, 0)); out.paste(bg, (768, 0)); out.paste(Image.fromarray(diff), (1536, 0))
    out.save(os.path.join(D, "gate", "compare_" + view + ".png"))
