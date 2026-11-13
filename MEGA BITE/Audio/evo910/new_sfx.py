"""MEGA BITE sounds for evolutions 9 and 10 (13 Nov 2026, owner AFK: "1,2" = the new evolutions). All code-made (sfxlib).
MOSASAURUS = a sea lizard: long-snout jaw CLACKS (wood + slap), a dry reptile rasp, the sea bursting when it leaps.
  MosaBite1-3   the bite: the long jaws clap shut (two quick clacks along the snout) + a slap + a reptile throat thud
  MosaLunge     the ability SEA LUNGE on the Great White's Breach clip: gather 0-0.40, rise, BURST at 0.50, jaws CLACK 0.62, back in 0.99
LEVIATHAN = a sea dragon of black scales and glowing gold seams: deep chomps with a fire-crackle and a scale clink.
  LeviBite1-3   the bite
  InfernoRoar   the ability INFERNO ROAR on the Megalodon's TidalRoar clip: inhale 0-0.32, ROAR at 0.32 (3 rings 0.14 s apart)
  EvolveLeviathan  evolving into it: riser, HIT on the cutscene flash at 1.1 s, a minor-to-major bell, embers
Rules: identity in 1-5 kHz (phones), about -13.5 LUFS, true peak under -1 dB, kid-friendly (no screams, no gore)."""
import numpy as np
from sfxlib import *
r2 = np.random.default_rng(909)

def wood(f=1500, tau=0.03, p=1.0):
    t = t_(0.2); y = np.zeros(len(t))
    for k, (m, a) in enumerate([(1.0, 1.0), (2.3, 0.5), (4.1, 0.2)]):
        y += np.sin(2 * np.pi * f * p * m * t + r2.uniform(0, 6)) * a * np.exp(-t / (tau / (1 + k)))
    return y * np.minimum(t / 0.0006, 1)

def crackle(d, rate=60, lo=1800, hi=7000):
    n = int(d * SR); y = np.zeros(n); at = 0.0
    while at < d:
        at += r2.exponential(1 / rate)
        L = int(r2.uniform(0.001, 0.004) * SR); c = hp(noise(L), lo) * np.exp(-np.arange(L) / (L / 3))
        i = int(at * SR)
        if i + L < n: y[i:i + L] += c * r2.uniform(0.3, 1.0)
    return bp(y, lo, hi)

def rasp(d, f0=70, f1=55):
    t = t_(d); f = np.interp(t, [0, d], [f0, f1]) + 3 * np.sin(2 * np.pi * 7 * t)
    src = saws(f, [(1, 1), (1.01, 0.8), (2.0, 0.4)]) * (1 + 0.8 * np.sin(2 * np.pi * np.cumsum(23 + 3 * np.sin(2 * np.pi * t)) / SR))
    return bp(src, 300, 2600) * 0.7 + lp(src, 200) * 0.4

def clink(f=2600, p=1.0):
    t = t_(0.3); y = np.zeros(len(t))
    for m, a in [(1, 1), (2.76, 0.5), (5.4, 0.25), (8.9, 0.1)]:
        y += np.sin(2 * np.pi * f * p * m * t + r2.uniform(0, 6)) * a * np.exp(-t / (0.09 / m ** 0.5))
    return y * np.minimum(t / 0.0005, 1)

# ---------------- MOSASAURUS BITE x3 ----------------
for k, p in enumerate([1.0, 0.93, 1.08]):
    N = int(0.55 * SR); mix = np.zeros(N); c = 0.06
    place(mix, sweep(0.06, 600, 2600 * p, curve=1.5, q=0.4) * ramp(0.06, 1.5, 0.006), 0, 0.22)    # the long jaws swing
    place(mix, wood(1350, 0.03, p), c, 1.2); place(mix, wood(1750, 0.022, p), c + 0.016, 0.9)     # CLACK-clack along the snout
    place(mix, hp(noise(int(0.012 * SR)), 2800) * dec(0.012, 0.002), c, 0.9)
    place(mix, bp(noise(int(0.09 * SR)), 500 * p, 2200 * p) * dec(0.09, 0.02), c + 0.004, 1.0)     # the slap of the lips
    place(mix, subdrop(0.16, 110 * p, 50, 0.03, 0.06), c, 0.8)                                        # the heavy head
    place(mix, rasp(0.18, 80 * p, 60) * ramp(0.18, 0.6, 0.06) * np.linspace(1, 0, int(0.18 * SR)), c + 0.03, 0.22)   # a dry reptile huff
    place(mix, bubbles(0.2, 8, 700, 2200), c + 0.04, 0.2)
    finish(mix, f'MosaBite{k + 1}', lufs=-14.0, lpf=11500, verb=0.1, room=0.35)

# ---------------- SEA LUNGE (Breach clip timeline) ----------------
N = int(2.25 * SR); mix = np.zeros(N); G = 0.40 - OFF; B = 0.50 - OFF; Cc = 0.62 - OFF; R = 0.99 - OFF
place(mix, rasp(G, 60, 78) * ramp(G, 1.4, 0.03), 0, 0.45)                                           # the lizard gathers itself: a rising rasp
place(mix, lp(noise(int(G * SR)), 150) * ramp(G, 1.5, 0.03), 0, 0.45)
d = B - G + 0.03; place(mix, sweep(d, 700, 5600, curve=1.6, q=0.45) * ramp(d, 1.3, 0.008), G - 0.03, 0.72)
n = int(0.95 * SR); tt = t_(0.95)
spl = hp(noise(n), 2500) * np.exp(-tt / 0.12) + bp(noise(n), 600, 3200) * (0.6 * np.exp(-tt / 0.07) + 0.4 * np.exp(-tt / 0.34))
place(mix, spl * np.minimum(tt / 0.005, 1), B, 1.1)                                                  # BURST out of the sea
place(mix, lp(noise(int(0.4 * SR)), 260) * dec(0.4, 0.09), B, 0.9); place(mix, subdrop(1.1, 70, 30, 0.25, 0.55), B, 0.45)
place(mix, bubbles(0.7, 28, 1800, 5200, 0.012, 0.03) * np.linspace(1, 0.2, int(0.7 * SR)), B + 0.05, 0.22)
place(mix, wood(1250, 0.045), Cc, 1.5); place(mix, wood(1700, 0.03), Cc + 0.02, 1.1)                # the jaws CLACK shut in the air
place(mix, bp(noise(int(0.12 * SR)), 400, 1800) * dec(0.12, 0.03), Cc, 1.3); place(mix, subdrop(0.22, 120, 60, 0.03, 0.06), Cc, 0.9)
n = int(0.7 * SR); tt = t_(0.7); place(mix, bp(noise(n), 300, 3500) * np.exp(-tt / 0.22) * np.minimum(tt / 0.015, 1), R, 0.6)
place(mix, lp(bubbles(1.05, 115, 300, 1400) * np.linspace(1, 0, int(1.05 * SR)) ** 1.2, 3000), R + 0.05, 0.34)
finish(mix, 'MosaLunge', lufs=-13.0, lpf=12000, verb=0.14, room=0.5)

# ---------------- LEVIATHAN BITE x3 ----------------
for k, p in enumerate([1.0, 0.94, 1.06]):
    N = int(0.6 * SR); mix = np.zeros(N); c = 0.05
    place(mix, sweep(0.05, 400, 2000 * p, curve=1.6, q=0.4) * ramp(0.05, 1.5, 0.006), 0, 0.25)
    place(mix, hp(noise(int(0.012 * SR)), 2600) * dec(0.012, 0.002), c, 0.9)
    place(mix, bp(noise(int(0.12 * SR)), 320 * p, 1400 * p) * dec(0.12, 0.03), c + 0.004, 1.3)    # the big chomp
    place(mix, subdrop(0.22, 95 * p, 40, 0.035, 0.08), c, 1.0)                                       # dragon-sized jaw
    place(mix, clink(2400, p), c + 0.006, 0.28)                                                      # scales clink (the gold seams)
    place(mix, crackle(0.32, 70) * np.linspace(1, 0, int(0.32 * SR)) ** 1.5, c + 0.02, 0.35)       # a crackle of embers
    place(mix, bubbles(0.22, 9, 500, 1800), c + 0.05, 0.2)
    finish(mix, f'LeviBite{k + 1}', lufs=-14.0, lpf=11000, verb=0.12, room=0.4)

# ---------------- INFERNO ROAR (TidalRoar clip timeline) ----------------
N = int(2.75 * SR); mix = np.zeros(N); A0 = 0.32 - OFF
place(mix, sweep(A0, 250, 1400, curve=2.0, q=0.4) * ramp(A0, 2.0, 0.02), 0, 0.40)
place(mix, crackle(A0, 40) * ramp(A0, 1.5, 0.02), 0, 0.3)                                           # embers stirring as it breathes in
L = 2.0; tt = t_(L)
f0 = np.interp(tt, [0, 0.14, 0.5, 1.2, 2.0], [40, 62, 57, 50, 33]) + 2.5 * np.sin(2 * np.pi * 4.6 * tt)
rough = 1 + 0.7 * np.sin(2 * np.pi * np.cumsum(25 + 4 * np.sin(2 * np.pi * 0.6 * tt)) / SR)
src = saws(f0, [(1, 1), (1.01, 1), (0.99, 1), (2.004, 0.5), (0.5, 0.6)]) * rough + lp(noise(len(tt)), 1100) * 0.7
OH = [(400, 130, 1.0), (760, 170, 0.6), (2300, 300, 0.2)]; AH = [(650, 150, 1.0), (1100, 200, 0.7), (2500, 320, 0.28), (3200, 400, 0.12)]
w = np.interp(tt, [0, 0.25, 1.4, 2.0], [0.2, 1.0, 0.3, 0.1])
ro = sum(bp(src, max(60, F - BW / 2), F + BW / 2) * A for F, BW, A in OH) * (1 - w) + sum(bp(src, max(60, F - BW / 2), F + BW / 2) * A for F, BW, A in AH) * w
ro += lp(src, 170) * 0.5 + bp(src, 1500, 3500) * 0.6
e = np.minimum(tt / 0.07, 1) * np.clip((L - tt) / 0.9, 0, 1) ** 1.5
place(mix, np.tanh(ro * e * 1.8), A0, 0.85)
fire = bp(noise(int(1.6 * SR)), 900, 6000) * np.minimum(t_(1.6) / 0.05, 1) * np.clip((1.6 - t_(1.6)) / 1.1, 0, 1)   # a roaring jet of fire-water
place(mix, fire * (1 + 0.4 * np.sin(2 * np.pi * 11 * t_(1.6))), A0 + 0.02, 0.35)
place(mix, crackle(1.6, 90) * np.clip((1.6 - t_(1.6)) / 1.6, 0, 1), A0 + 0.05, 0.4)
for i in range(3):
    place(mix, subdrop(1.0, 54 - 6 * i, 24, 0.3, 0.35), A0 + 0.14 * i, [0.55, 0.4, 0.3][i])
    place(mix, sweep(0.5, 3600, 160, curve=0.45, q=0.45) * dec(0.5, 0.18, 0.008), A0 + 0.14 * i + 0.01, [0.7, 0.42, 0.3][i])
place(mix, bubbles(1.6, 170, 220, 1300) * np.linspace(1, 0.1, int(1.6 * SR)), A0 + 0.05, 0.4)
finish(mix, 'InfernoRoar', lufs=-13.5, lpf=9500, verb=0.24, room=0.85)

# ---------------- EVOLVE LEVIATHAN (3.3 s; HIT at 1.1 s) ----------------
N = int(3.3 * SR); mix = np.zeros(N); H = 1.1
t = t_(H); f0 = np.interp(t, [0, H], [36, 64])
place(mix, lp(saws(f0, [(1, 1), (1.008, 0.8), (0.5, 0.7), (1.5, 0.25)]), 650) * ramp(H, 1.6, 0.02), 0, 0.42)
place(mix, crackle(H, 50) * ramp(H, 2.0, 0.02), 0, 0.4)
place(mix, sweep(H, 120, 4400, curve=2.4, q=0.38) * ramp(H, 2.4, 0.01), 0, 0.42)
place(mix, hp(noise(int(0.05 * SR)), 2400) * dec(0.05, 0.008), H, 1.3)
place(mix, lp(noise(int(0.9 * SR)), 240) * dec(0.9, 0.2), H, 1.2); place(mix, subdrop(1.9, 66, 22, 0.35, 0.8), H, 0.8)
place(mix, clink(1800), H, 0.6); place(mix, clink(2700), H + 0.01, 0.4)
tt = t_(2.1); ch = np.zeros(len(tt))
for f, a, d0 in [(392, 1.0, 0), (466, 0.8, 0), (587, 0.75, 0), (494, 0.8, 0.35), (784, 0.5, 0.35), (988, 0.4, 0.35)]:   # G minor, then G major on top: dark -> triumphant
    for m, am in [(1, 1), (2.01, 0.35), (3.02, 0.15)]:
        ch += np.sin(2 * np.pi * f * m * tt + r2.uniform(0, 6)) * a * am * np.exp(-np.maximum(tt - d0, 0) / (0.9 / m)) * (tt >= d0)
place(mix, ch * np.minimum(tt / 0.004, 1), H + 0.02, 0.28)
place(mix, crackle(1.8, 70) * np.linspace(1, 0, int(1.8 * SR)), H + 0.05, 0.4)
place(mix, bubbles(1.6, 120, 300, 1500) * np.linspace(1, 0, int(1.6 * SR)) ** 1.3, H + 0.05, 0.3)
finish(mix, 'EvolveLeviathan', lufs=-13.0, lpf=11000, verb=0.2, room=0.6)
print('done')
