# EVOLVE creature movement sounds, synthesized (our own, no stock audio). Owner, 18 Nov 2026: "Yes, make sounds".
# Run: python make_moves.py  -> moves/*.wav (48 kHz mono, peak -1 dBFS). Identity sits in 1-5 kHz so phone speakers keep it.
import os
import numpy as np
import soundfile as sf
from scipy.signal import butter, sosfilt

SR = 48000
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "moves")
os.makedirs(OUT, exist_ok=True)


def t(sec):
    return np.arange(int(SR * sec)) / SR


def env(n, attack=0.003, decay=0.08):  # fast attack, exponential decay
    x = np.arange(n) / SR
    return np.minimum(x / attack, 1) * np.exp(-x / decay)


def band(x, lo, hi):
    return sosfilt(butter(2, [lo, hi], btype="band", fs=SR, output="sos"), x)


def sweep(f0, f1, sec):  # sine sliding from f0 to f1
    f = np.geomspace(f0, f1, int(SR * sec))
    return np.sin(2 * np.pi * np.cumsum(f) / SR)


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: len(p)] += p
    return out


def finish(x, name):
    x = x - np.mean(x)
    fade = int(SR * 0.004)
    x[:fade] *= np.linspace(0, 1, fade)
    x[-fade * 3:] *= np.linspace(1, 0, fade * 3)
    x = x / np.max(np.abs(x)) * 10 ** (-1 / 20)
    assert len(x) > SR * 0.03 and np.max(np.abs(x)) < 1  # self-check: real sound, no clipping
    sf.write(os.path.join(OUT, name + ".wav"), x.astype(np.float32), SR, subtype="PCM_16")
    print(name, f"{len(x) / SR:.2f}s")


rng = np.random.default_rng(18)
for v in range(1, 4):
    j = 1 + rng.uniform(-0.08, 0.08)  # each variant a little different
    # small: a soft tap with a light grass tick
    n = len(t(0.07))
    finish(mix(band(rng.standard_normal(n), 2000 * j, 5500), 0.5 * sweep(520 * j, 300, 0.07)) * env(n, 0.001, 0.018), f"step_small_{v}")
    # medium: padded thud + grass crunch
    n = len(t(0.14))
    finish(mix(sweep(150 * j, 70, 0.14) * env(n, 0.002, 0.05), 0.55 * band(rng.standard_normal(n), 900 * j, 3500) * env(n, 0.001, 0.025)), f"step_mid_{v}")
    # big: deep stomp, dirt crunch, short rumble tail
    n = len(t(0.45))
    finish(mix(sweep(85 * j, 38, 0.45) * env(n, 0.003, 0.14),
               0.6 * band(rng.standard_normal(n), 1000 * j, 4000) * env(n, 0.001, 0.05),
               0.25 * band(rng.standard_normal(n), 120, 400) * env(n, 0.01, 0.2)), f"step_big_{v}")
    # swim stroke: water swish rising + a few bubbles
    n = len(t(0.42))
    swish = band(rng.standard_normal(n), 500 * j, 1800 * j) * np.sin(np.pi * np.arange(n) / n) ** 2
    bubbles = np.zeros(n)
    for _ in range(5):
        start = int(rng.uniform(0.12, 0.34) * SR)
        b = sweep(rng.uniform(600, 900) * j, rng.uniform(1300, 1900), 0.035) * env(len(t(0.035)), 0.002, 0.012)
        bubbles[start:start + len(b)] += b[: n - start]
    finish(mix(0.8 * swish, 0.5 * bubbles), f"swim_{v}")

# jump: springy little "fwip" up
n = len(t(0.2))
finish(mix(sweep(280, 760, 0.2) * env(n, 0.004, 0.07), 0.35 * band(rng.standard_normal(n), 1500, 5000) * env(n, 0.002, 0.04)), "jump")
# land: soft thump with a puff
n = len(t(0.18))
finish(mix(sweep(140, 55, 0.18) * env(n, 0.002, 0.06), 0.4 * band(rng.standard_normal(n), 700, 3000) * env(n, 0.001, 0.03)), "land")
