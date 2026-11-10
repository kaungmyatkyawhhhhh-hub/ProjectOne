"""cabin_tone.py in.png out.png: the Horizon R35's cabin atlas with its silver trim toned down (2026-11-10): in Studio
the prep's satin silver (149,152,157) still read white from the seat (console, door pulls, spokes), and the pale ring
tone (195,204,214) glared. Silver -> satin gunmetal, rings -> satin silver; smooth blend so soft edges follow."""
import sys
import numpy as np
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB")
a = np.asarray(im).astype(float)
sat = a.max(2) - a.min(2)
m = a.mean(2)
out = a.copy()
# low-saturation tones between 110 and 225: scale so 152 -> 72 and 204 -> 132 (a straight line through both), keep hue
grey = (sat < 26) & (m > 110) & (m < 226)
k = (72 + (m - 152) * (132 - 72) / (204 - 152)) / np.maximum(m, 1)
out[grey] = a[grey] * k[grey][:, None]
Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)).save(sys.argv[2])
print("toned", int(grey.sum()), "px of", grey.size)
