# MEGA BITE giants: three sounds made in code (owner rule: code-synthesized, no AI sound tools). 13 Nov 2026.
#   WhaleSong  6.0 s  gentle gliding moans (the Blue Whale, heard when it passes)
#   EelGrowl   1.2 s  a rising rattle-growl (the Colossal Eel has seen you: the warning)
#   KrakenRise 3.4 s  a deep horn swell with bubbles and a hit (the Kraken event starts)
import numpy as np, soundfile as sf, pyloudnorm as pyln
from scipy.signal import butter, sosfilt, fftconvolve
SR = 44100
rng = np.random.default_rng(7)
def env(n, a, r, hold=1.0):
    e = np.ones(n) * hold; na, nr = int(a * SR), int(r * SR)
    e[:na] *= np.linspace(0, 1, na) ** 1.5; e[-nr:] *= np.linspace(1, 0, nr) ** 1.5
    return e
def bp(x, lo, hi, order=2): return sosfilt(butter(order, [lo, hi], btype='band', fs=SR, output='sos'), x)
def lp(x, f, order=2): return sosfilt(butter(order, f, btype='low', fs=SR, output='sos'), x)
def hp(x, f, order=2): return sosfilt(butter(order, f, btype='high', fs=SR, output='sos'), x)
def verb(x, secs=1.6, mix=0.3):
    n = int(secs * SR); ir = rng.standard_normal(n) * np.exp(-np.linspace(0, 6.5, n)); ir = lp(ir, 3200)
    w = fftconvolve(x, ir); w /= np.abs(w).max() + 1e-9
    y = np.zeros(len(w)); y[:len(x)] += x * (1 - mix); y += w * mix * np.abs(x).max()
    return y
def tone(freqs, harm):
    ph = 2 * np.pi * np.cumsum(freqs) / SR
    return sum(a * np.sin(k * ph) for k, a in harm)
def finish(x, name, lufs=-17.0, tail=0.25):
    e = np.abs(x); last = np.nonzero(e > e.max() * 0.004)[0][-1]; x = x[:min(len(x), last + int(0.1 * SR))]
    x = np.concatenate([x, np.zeros(int(0.02 * SR))])
    n = int(tail * SR); x[-n:] *= np.linspace(1, 0, n) ** 2
    x[:220] *= np.linspace(0, 1, 220)
    m = pyln.Meter(SR); x = pyln.normalize.loudness(x, m.integrated_loudness(x), lufs)
    pk = np.abs(x).max()
    if pk > 0.89: x *= 0.89 / pk
    sf.write(name + '.ogg', x.astype(np.float32), SR, format='OGG', subtype='VORBIS')
    print(name, '%.2f s' % (len(x) / SR), 'LUFS %.1f' % m.integrated_loudness(x), 'peak %.2f' % np.abs(x).max())
# ---- WhaleSong
def moan(dur, f0, f1, f2, vib=4.5):
    n = int(dur * SR); t = np.linspace(0, 1, n)
    f = np.where(t < 0.55, f0 + (f1 - f0) * (t / 0.55) ** 1.4, f1 + (f2 - f1) * (np.clip((t - 0.55) / 0.45, 0, 1)) ** 0.8)
    f = f * (1 + 0.012 * np.sin(2 * np.pi * vib * t * dur))
    return tone(f, [(1, 1.0), (2, 0.55), (3, 0.3), (4, 0.12), (5, 0.06)]) * env(n, 0.45, 0.7)
song = np.zeros(int(6.0 * SR))
for start, d, a, b, c, g in ((0.0, 2.3, 150, 300, 230, 1.0), (2.1, 1.7, 260, 420, 380, 0.8), (3.7, 2.2, 330, 210, 170, 0.9)):
    m = moan(d, a, b, c) * g; i = int(start * SR); song[i:i + len(m)] += m[:len(song) - i]
song = lp(hp(song, 110), 2600)
finish(verb(song, 2.2, 0.42), 'WhaleSong', -18.0, 0.6)
# ---- EelGrowl
n = int(1.15 * SR); t = np.arange(n) / SR; k = t / t[-1]
f = 96 + 130 * k ** 1.6
saw = tone(f, [(h, 1.0 / h) for h in range(1, 14)])
rat = 0.5 + 0.5 * np.sign(np.sin(2 * np.pi * np.cumsum(22 + 30 * k) / SR))   # the rattle gets faster
g = hp(lp(saw, 1500), 150) * (0.35 + 0.65 * rat) + bp(rng.standard_normal(n), 400, 2200) * 0.6 * rat
g += bp(rng.standard_normal(n), 900, 2600) * 0.12 * k
g *= (0.25 + 0.75 * k ** 1.3) * env(n, 0.06, 0.12)
finish(verb(g, 0.6, 0.15), 'EelGrowl', -16.0, 0.15)
# ---- KrakenRise
n = int(3.4 * SR); t = np.arange(n) / SR; k = t / t[-1]
horn = np.zeros(n)
for f0, a in ((73.4, 0.5), (146.8, 1.0), (220.0, 0.8), (293.7, 0.6), (440.0, 0.3)):   # D2 A2 D3 A3: an open fifth, big and not sad
    for det in (-0.4, 0.0, 0.5):
        horn += a * tone(np.full(n, f0 * (1 + det / 100)) * (1 + 0.004 * np.sin(2 * np.pi * 5 * t)), [(h, 1.0 / h ** 1.1) for h in range(1, 18)])
swell = np.clip(k / 0.62, 0, 1) ** 2.2
out = np.zeros(n); blk = 2048   # the filter opens as it swells
for i in range(0, n, blk):
    cut = 500 + 4200 * swell[i] ** 1.3
    seg = horn[max(0, i - 4096):i + blk]
    out[i:i + blk] = lp(seg, cut)[-min(blk, n - i):] if i > 0 else lp(seg, cut)[:blk]
out *= swell * env(n, 0.05, 1.1)
sub = np.sin(2 * np.pi * np.cumsum(np.full(n, 55.0)) / SR) * swell * 0.25 * env(n, 0.3, 1.2)
bub = bp(rng.standard_normal(n), 500, 2400) * (0.5 + 0.5 * np.sin(2 * np.pi * 13 * t + 3 * np.sin(2 * np.pi * 2.1 * t))) * 0.22 * swell
hit_i = int(0.62 * 3.4 * SR); m = n - hit_i; th = np.arange(m) / SR
hit = (np.sin(2 * np.pi * (90 * np.exp(-th * 5) + 60) * th) * np.exp(-th * 3.2) * 0.8 + bp(rng.standard_normal(m), 200, 2400) * np.exp(-th * 6) * 0.9)
mix = hp(out, 120) * 0.6 + sub + bub * 1.5; mix[hit_i:] += hit
finish(verb(np.tanh(mix * 0.9), 1.4, 0.22), 'KrakenRise', -15.0, 0.5)
