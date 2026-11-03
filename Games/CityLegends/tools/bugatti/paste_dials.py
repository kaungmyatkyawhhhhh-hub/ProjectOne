"""The 16.4's own dial faces (sharp, no needles) pasted into the Super Sport / Grand Sport Vitesse
interior atlas over their own painted dials (same layout, matched by 3D position), atlas 2x."""
import numpy as np
from PIL import Image
T = "C:/Users/USER/.claude/jobs/a86b922d/tmp/bug/tex/"
don = Image.open(T + "2009_bugatti_PLASTIC_INTEIROR_col_6.png").convert("RGB")
D = {"rpm": (810.0, 804.9, 193.9), "speed": (420.8, 892.1, 127.2), "power": (142.4, 880.6, 128.8), "fuel": (300.3, 664.3, 90.9), "oil": (913.1, 498.0, 93.6)}
K = 1.05
def paste(src_fn, out_fn, dials):
    t = Image.open(T + src_fn).convert("RGB")
    S = 2
    big = t.resize((t.width * S, t.height * S), Image.LANCZOS)
    for tk, dk in dials:
        tx, ty, tr = tk
        dx, dy, dr = D[dk]
        R = dr * K
        crop = don.crop((round(dx - R), round(dy - R), round(dx + R), round(dy + R)))
        Rt = tr * K * S
        size = int(round(2 * Rt))
        crop = crop.resize((size, size), Image.LANCZOS)
        yy, xx = np.mgrid[0:size, 0:size]
        d = np.hypot(xx - size / 2 + 0.5, yy - size / 2 + 0.5) / (size / 2)
        m = np.clip((1.0 - d) / 0.04, 0, 1)
        mask = Image.fromarray((m * 255).astype(np.uint8))
        big.paste(crop, (int(round(tx * S - size / 2)), int(round(ty * S - size / 2))), mask)
    big.save(T + out_fn)
    print(out_fn, big.size)
SS = {"rpm": (73.3, 372.1, 61.7), "speed": (208.5, 386.5, 54.0), "power": (331.3, 385.2, 54.5), "up1": (84.2, 140.7, 35.3), "up2": (164.2, 142.0, 34.5)}
GSV = {"rpm": (73.3, 372.1, 61.7), "speed": (210.3, 394.0, 55.5), "power": (332.6, 388.3, 54.7), "up1": (84.2, 140.7, 35.3), "up2": (164.2, 142.0, 34.5)}
pairs = [("rpm", "rpm"), ("speed", "speed"), ("power", "power"), ("up1", "oil"), ("up2", "fuel")]
paste("2010_bugatti_ronSuperSportGold_2012InteriorB_Material_col_18.png", "veyronss_interior_dials.png", [(SS[a], b) for a, b in pairs])
paste("2013_bugatti_ndSportVitesseWRE_2012InteriorB_Material_col_17.png", "veyrongsv_interior_dials.png", [(GSV[a], b) for a, b in pairs])
