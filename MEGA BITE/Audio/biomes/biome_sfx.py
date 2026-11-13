# MEGA BITE biome ambience: four seamless 12 s loops made in code (owner rule: code-synthesized). 13 Nov 2026.
#   AmbKelp  (N, Kelp Lighthouse)   soft water wash + slow marimba-like notes (C major pentatonic), bright and calm
#   AmbRuins (E, Sunken Kingdom)    a warm open-fifth drone + far, soft bells
#   AmbBones (S, Whale Graveyard)   airy "wind in the water" + very soft far moans
#   AmbGlow  (W, Glow Gardens)      a glassy shimmer pad + small sparkles
# Seamless: every tone runs a whole number of cycles in the loop, events wrap round the end, noise is cross-faded.
import numpy as np, soundfile as sf, pyloudnorm as pyln
from scipy.signal import butter, sosfilt
SR, DUR = 44100, 12.0
N = int(SR * DUR); t = np.arange(N) / SR
rng = np.random.default_rng(11)
def bp(x, lo, hi): return sosfilt(butter(2, [lo, hi], btype='band', fs=SR, output='sos'), x)
def lp(x, f): return sosfilt(butter(2, f, btype='low', fs=SR, output='sos'), x)
def loop_noise(lo, hi):
    x = bp(rng.standard_normal(N + SR), lo, hi)       # one second more, cross-faded into the start
    k = np.linspace(0, 1, SR); y = x[:N].copy(); y[:SR] = x[N:] * (1 - k) + x[:SR] * k
    return y / (np.abs(y).max() + 1e-9)
def cyc(f): return round(f * DUR) / DUR                 # the nearest pitch that fits the loop exactly
def lfo(per_loop, phase=0.0): return 0.5 + 0.5 * np.sin(2 * np.pi * per_loop * t / DUR + phase)
def add_wrapped(buf, i, ev):
    n = len(ev); j = i % N; a = min(n, N - j); buf[j:j + a] += ev[:a]
    if a < n: buf[:n - a] += ev[a:]
def note(f, dur, decay, harm=((1, 1.0), (2, 0.3), (4, 0.12))):
    n = int(dur * SR); tt = np.arange(n) / SR
    e = np.exp(-tt * decay) * np.minimum(1, tt / 0.006)
    return sum(a * np.sin(2 * np.pi * f * h * tt) for h, a in harm) * e
def finish(x, name, lufs):
    m = pyln.Meter(SR); x = pyln.normalize.loudness(x, m.integrated_loudness(x), lufs)
    pk = np.abs(x).max()
    if pk > 0.7: x *= 0.7 / pk
    sf.write(name + '.ogg', x.astype(np.float32), SR, format='OGG', subtype='VORBIS')
    X = np.abs(np.fft.rfft(x)) ** 2; f = np.fft.rfftfreq(len(x), 1 / SR)
    print(name, 'LUFS %.1f' % m.integrated_loudness(x), 'seam %.4f' % abs(x[0] - x[-1]), [round(X[(f >= a) & (f < b)].sum() / X.sum() * 100) for a, b in ((0, 250), (250, 1000), (1000, 4000), (4000, 22050))])
PENT = [261.63, 293.66, 329.63, 392.0, 440.0, 523.25, 587.33, 659.25]
# Kelp
x = loop_noise(250, 1400) * (0.25 + 0.3 * lfo(2)) * 0.5 + loop_noise(1500, 5000) * 0.08 * lfo(3, 1.0)
for i in range(9):
    add_wrapped(x, int(rng.uniform(0, DUR) * SR), note(PENT[rng.integers(0, 8)], 2.2, 2.6, ((1, 1.0), (4, 0.25), (10, 0.05))) * rng.uniform(0.25, 0.45))
finish(x, 'AmbKelp', -24.0)
# Ruins
x = sum(a * np.sin(2 * np.pi * cyc(f) * t + p) * (0.6 + 0.4 * lfo(k, p)) for f, a, p, k in ((293.66, 0.5, 0, 1), (440.0, 0.4, 1, 2), (587.33, 0.25, 2, 1), (880.0, 0.08, 3, 3), (294.5, 0.3, 0.5, 2), (146.83, 0.25, 1.5, 1)))
x += loop_noise(200, 900) * 0.18 * lfo(1, 2.0)
for i, f in enumerate((587.33, 440.0, 659.25, 493.88)):
    add_wrapped(x, int((1.2 + i * 2.9) * SR), note(f, 3.5, 1.3, ((1, 1.0), (2.76, 0.4), (5.4, 0.2), (8.9, 0.08))) * 0.3)
finish(x, 'AmbRuins', -24.0)
# Bones
x = loop_noise(350, 2200) * (0.15 + 0.5 * lfo(1) * lfo(3, 0.7)) + loop_noise(2000, 6000) * 0.06 * lfo(2, 2.2)
for st, f0, f1 in ((1.0, 300, 380), (6.4, 420, 330)):
    n = int(3.2 * SR); tt = np.linspace(0, 1, n); f = f0 + (f1 - f0) * tt ** 1.3
    ph = 2 * np.pi * np.cumsum(f) / SR
    add_wrapped(x, int(st * SR), (np.sin(ph) + 0.4 * np.sin(2 * ph)) * np.sin(np.pi * tt) ** 2 * 0.16)
finish(x, 'AmbBones', -25.0)
# Glow
x = sum(a * np.sin(2 * np.pi * cyc(f) * t + p) * (0.5 + 0.5 * lfo(k, p * 2)) for f, a, p, k in ((523.25, 0.3, 0, 2), (659.25, 0.25, 1, 3), (783.99, 0.22, 2, 2), (987.77, 0.14, 3, 4), (1318.5, 0.08, 4, 5), (261.63, 0.25, 5, 1)))
for i in range(22):
    add_wrapped(x, int(rng.uniform(0, DUR) * SR), note(PENT[rng.integers(3, 8)] * rng.choice([2, 4]), 0.9, 6.0, ((1, 1.0), (3.01, 0.2))) * rng.uniform(0.05, 0.14))
x += loop_noise(3000, 8000) * 0.04 * lfo(4)
finish(x, 'AmbGlow', -25.0)
