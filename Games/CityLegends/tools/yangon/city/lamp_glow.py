"""Lamp-head glow sprite (2026-11-27, night streetlights): a soft white radial falloff on transparent, 128 px.
Writes imports/sync/night_lights/lamp_glow.png (uploaded as an Image, group 33151111; id in src/shared/Config.lua
NightLamps.GlowImage). Run: python tools/yangon/city/lamp_glow.py"""
import os
from PIL import Image

N = 128
out = os.path.join(os.path.dirname(__file__), "..", "..", "..", "imports", "sync", "night_lights", "lamp_glow.png")
img = Image.new("RGBA", (N, N))
px = img.load()
c = (N - 1) / 2
for y in range(N):
    for x in range(N):
        r = ((x - c) ** 2 + (y - c) ** 2) ** 0.5 / c  # 0 centre .. 1 edge
        # a bright core and a long soft tail (camera-like halo), zero at the edge so no square shows
        a = max(0.0, 1 - r) ** 2.2 * 0.75 + max(0.0, 1 - r / 0.25) ** 2 * 0.25
        px[x, y] = (255, 255, 255, int(round(min(1.0, a) * 255)))
assert px[0, 0][3] == 0 and px[int(c), int(c)][3] > 240
img.save(os.path.abspath(out))
print(os.path.abspath(out))
