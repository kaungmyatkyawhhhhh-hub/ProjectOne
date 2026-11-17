import numpy as np
from PIL import Image
from scipy import ndimage
src = np.asarray(Image.open("evo_ui_chatgpt_items.png").convert("RGB")).astype(float)
lum = src.max(-1)
dark = lum < 24
lab, n = ndimage.label(dark)
border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
bg = np.isin(lab, list(border))
alpha = np.where(bg, 0, 255).astype(np.uint8)
alpha = ndimage.binary_fill_holes(alpha > 0) * 255
img = Image.fromarray(np.dstack([src.astype(np.uint8), alpha.astype(np.uint8)]), "RGBA")
lab2, _ = ndimage.label(alpha > 0)
boxes = [(sl[1].start, sl[0].start, sl[1].stop, sl[0].stop) for i, sl in enumerate(ndimage.find_objects(lab2)) if (lab2[sl] == i + 1).sum() > 3000]
boxes.sort(key=lambda b: (round((b[1]+b[3])/2/300), b[0]))
names = ["brain","hourglass","cradle","asteroid","dna2","stopwatch","crown","moon","skip","jar"]
for nm, b in zip(names, boxes):
    img.crop(b).save(f"item_{nm}.png"); print(nm, b)
