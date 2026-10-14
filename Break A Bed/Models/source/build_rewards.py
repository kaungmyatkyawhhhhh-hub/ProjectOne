import sys, os, numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build as B   # reuse export/render (build.py runs nothing when given an unknown filter)
from rewards import *
from reward_tex import tex_for, bed_blanket, bed_pillow, koi_v2, koi_fins_v2
OUT, PREV = sys.argv[1], sys.argv[2]
B.OUT = OUT; os.makedirs(OUT, exist_ok=True); os.makedirs(PREV, exist_ok=True)
def mirror(P):
    Q = {}
    for k, ms in P.items():
        out = []
        for m in ms:
            uv = m.metadata["uv"]; m = m.copy(); m.metadata["uv"] = uv
            m.vertices[:, 0] *= -1; m.faces = m.faces[:, ::-1]; out.append(m)
        Q[k] = out
    return Q
items = {"R1_PhoenixDummy": phoenix_dummy(), "R2_PhoenixGlove_R": phoenix_glove(1), "R2_PhoenixGlove_L": mirror(phoenix_glove(1)), "SenseiLegs": sensei_legs()}
for name, parts in items.items():
    tex = tex_for(name)
    t, merged = B.export(name, parts, tex)
    B.render(name, merged, tex, os.path.join(PREV, name + ".png"))
    print(name, t, list(parts))
bed_blanket().save(os.path.join(OUT, "R7_PhoenixBed_blanket.png")); bed_pillow().save(os.path.join(OUT, "R7_PhoenixBed_pillow.png"))
kd = os.path.join(OUT, "7_RainbowKoi_textures_v2"); os.makedirs(kd, exist_ok=True)
koi_v2().save(os.path.join(kd, "Body.png")); koi_fins_v2().save(os.path.join(kd, "TailFin.png")); koi_fins_v2().save(os.path.join(kd, "Fins.png"))
