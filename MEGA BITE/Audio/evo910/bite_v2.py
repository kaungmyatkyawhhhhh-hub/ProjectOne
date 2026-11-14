"""MEGA BITE - Mosasaurus + Leviathan bites v2 (14 Nov 2026). Owner: "mosasaurus and leviathan biting sound effects are so bad".
v1 (new_sfx.py) was pure synth (sine 'wood' clacks + noise): it sounded like a toy xylophone, not jaws.
v2 = REAL teeth: CC0 recordings already in the vault (Freesound, licences in the Reef Shark sound set note):
  830093 Wigglesworth "Jaw or teeth bite at air" (many single bites)  |  392883 clif_creates "Hard Candy / Bone Crunch"
Each bite = a water rush before the snap -> the SNAP (the real bite slowed down for size + a crisp copy at normal speed so a
phone speaker still hears the teeth) -> a second row of teeth -> a heavy body thump -> bubbles. Played at speed 1.0 in game
(the MB_SoundMap swap skips the size-pitch), so the size is baked in here. Kid-safe: no growl, no gore."""
import numpy as np, soundfile as sf
from scipy import signal
from sfxlib import *
r = np.random.default_rng(1414)
def load(n):
    y, sr = sf.read(f'../freesound_cc0/{n}.ogg')
    if y.ndim > 1: y = y.mean(1)
    return signal.resample_poly(y, SR, sr) if sr != SR else y
TEETH = load('fs_830093'); CRUNCH = load('fs_392883')
HITS = [1.197, 1.676, 2.357, 2.979, 5.37, 6.889, 7.453, 8.225, 9.096]
def cut(y, t, L):
    i = max(0, int((t - 0.004) * SR)); x = y[i:i + int(L * SR)].copy()
    k = int(0.003 * SR); x[:k] *= np.linspace(0, 1, k); return x / (np.abs(x).max() + 1e-9)
def speed(x, s):   # tape-style: slower = deeper + longer (a bigger mouth)
    n = int(len(x) / s); return signal.resample(x, n)

def bite(name, size, hitA, hitB, seed):
    global r
    r = np.random.default_rng(seed)
    big = size   # 0 = Mosasaurus, 1 = Leviathan
    c = 0.12 + 0.04 * big
    N = int((0.75 + 0.35 * big) * SR); mix = np.zeros(N)
    # 1. the water rush as the jaws swing in
    place(mix, sweep(c, 350 - 100 * big, 1900 - 400 * big, curve=1.6, q=0.45) * ramp(c, 1.6, 0.006), 0, 0.28)
    place(mix, lp(noise(int(c * SR)), 220) * ramp(c, 2.0, 0.006), 0, 0.15 + 0.1 * big)
    # 2. THE SNAP: the real bite slowed for size + the same bite crisp on top
    a = cut(TEETH, hitA, 0.09)
    place(mix, speed(a, 0.8 - 0.14 * big), c, 0.9)
    place(mix, hp(a, 1500), c + 0.002, 1.1 + 0.5 * big); place(mix, hp(speed(a, 0.9 - 0.1 * big), 1200), c + 0.001, 0.7)   # the crisp teeth a phone hears
    place(mix, hp(speed(cut(CRUNCH, 0.01, 0.12), 0.85 - 0.12 * big), 700), c + 0.004, 0.7 + 0.1 * big)
    # 3. the second row of teeth closing just after (a long snout / a huge mouth)
    b = cut(TEETH, hitB, 0.08)
    place(mix, hp(speed(b, 0.88 - 0.12 * big), 900), c + 0.045 + 0.01 * big, 0.8 + 0.3 * big)
    # 4. the heavy head: a thump with a falling sub (kept above ~45 Hz) + a dull water boom
    place(mix, subdrop(0.30 + 0.2 * big, 150 - 30 * big, 48 - 6 * big, 0.04, 0.08 + 0.06 * big), c, 0.45 - 0.08 * big)
    place(mix, lp(noise(int(0.35 * SR)), 260 - 60 * big) * dec(0.35, 0.06 + 0.04 * big), c, 0.3)
    # 5. bubbles rising after the bite
    place(mix, bubbles(0.45 + 0.25 * big, 10 + 6 * big, 450 - 150 * big, 1900 - 500 * big), c + 0.05, 0.3)
    return finish(mix, name, lufs=-13.0, lpf=12500 - 2500 * big, verb=0.13 + 0.06 * big, room=0.45 + 0.2 * big)

for k, (ha, hb) in enumerate([(HITS[0], HITS[4]), (HITS[2], HITS[6]), (HITS[7], HITS[3])]):
    bite(f'MosaBite_v2_{k + 1}', 0, ha, hb, 500 + k)
for k, (ha, hb) in enumerate([(HITS[8], HITS[1]), (HITS[5], HITS[2]), (HITS[3], HITS[7])]):
    bite(f'LeviBite_v2_{k + 1}', 1, ha, hb, 900 + k)
print('done')
