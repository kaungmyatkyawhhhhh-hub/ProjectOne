"""MEGA BITE treasure chest sounds (13 Nov), made in code (numpy). Key of C like the bank / buy bells.
ChestOpen.ogg  2.7 s: 0.00 rattle (6 wooden knocks getting faster + latch pings) under a riser -> 0.60 a breath of silence ->
               0.64 THE HIT (lid clack + low thump + air) -> C major bell strum up to G6 -> coin shower -> sparkle tail.
               The game starts the picture with the sound: the lid bursts open at 0.64 s.
ChestHum.ogg   4.0 s seamless loop: a soft glass shimmer that sits on a full chest (3D), so you hear treasure before you see it."""
import numpy as np, soundfile as sf, subprocess, sys
SR = 44100; rng = np.random.default_rng(13)
def env_exp(n, tau): return np.exp(-np.arange(n) / (tau * SR))
def place(buf, x, t, gain=1.0):
    i = int(t * SR); j = min(len(buf), i + len(x)); buf[i:j] += x[:j - i] * gain
def bp_noise(n, lo, hi):
    X = np.fft.rfft(rng.standard_normal(n)); f = np.fft.rfftfreq(n, 1 / SR)
    X *= np.exp(-0.5 * ((np.log(np.maximum(f, 1)) - np.log(np.sqrt(lo * hi))) / (np.log(hi / lo) / 2.2)) ** 2)
    x = np.fft.irfft(X, n); return x / (np.abs(x).max() + 1e-9)
def knock(strength):
    n = int(0.14 * SR); t = np.arange(n) / SR
    f = rng.uniform(170, 250)
    body = np.sin(2 * np.pi * (f * t + 30 * np.exp(-t * 60) / 60)) * env_exp(n, 0.028)
    wood = np.sin(2 * np.pi * rng.uniform(820, 1150) * t) * env_exp(n, 0.012) * 0.5
    click = bp_noise(n, 1500, 6000) * env_exp(n, 0.004) * 0.6
    latch = (np.sin(2 * np.pi * rng.uniform(2600, 3900) * t) + 0.6 * np.sin(2 * np.pi * rng.uniform(4300, 5600) * t)) * env_exp(n, 0.03) * 0.16
    return (body + wood + click + latch) * strength
def bell(f, dur, bright=1.0):
    n = int(dur * SR); t = np.arange(n) / SR; x = np.zeros(n)
    for ratio, amp, tau in ((1, 1.0, 0.75), (2.0, 0.42, 0.5), (2.76, 0.30 * bright, 0.30), (4.07, 0.16 * bright, 0.2), (5.4, 0.10 * bright, 0.12), (8.9, 0.05 * bright, 0.07)):
        if f * ratio < 18000: x += amp * np.sin(2 * np.pi * f * ratio * t + rng.uniform(0, 6.28)) * np.exp(-t / (tau * dur / 1.6))
    a = int(0.003 * SR); x[:a] *= np.linspace(0, 1, a); return x
def coin(f):
    n = int(rng.uniform(0.05, 0.11) * SR); t = np.arange(n) / SR
    x = np.sin(2 * np.pi * f * t) + 0.7 * np.sin(2 * np.pi * f * 1.48 * t) + 0.35 * np.sin(2 * np.pi * f * 2.31 * t)
    return x * env_exp(n, rng.uniform(0.012, 0.03))
def norm(x, peak): return x / np.abs(x).max() * peak
NOTE = lambda semis_from_c5: 523.251 * 2 ** (semis_from_c5 / 12)
# ------------------------------------------------------------------ ChestOpen
D = 2.75; N = int(D * SR); y = np.zeros(N); T = np.arange(N) / SR
HIT = 0.64
for i, tk in enumerate((0.02, 0.17, 0.29, 0.39, 0.47, 0.535)): place(y, knock(0.34 + 0.085 * i), tk)
# riser: noise sweep + gliding tone cluster, crescendo to the breath
nr = int(0.60 * SR); tr = np.arange(nr) / SR; k = tr / 0.60
sweep = np.zeros(nr); blk = 512
noise = rng.standard_normal(nr + blk)
for s0 in range(0, nr, blk // 2):                      # a moving band-pass, block by block
    fc = 350 * (6500 / 350) ** (s0 / nr); seg = noise[s0:s0 + blk] * np.hanning(blk)
    X = np.fft.rfft(seg); f = np.fft.rfftfreq(blk, 1 / SR); X *= np.exp(-0.5 * ((f - fc) / (0.35 * fc)) ** 2)
    out = np.fft.irfft(X, blk); e = min(nr, s0 + blk); sweep[s0:e] += out[:e - s0]
sweep = norm(sweep, 1.0) * k ** 2.2 * 0.30
glide = sum(np.sin(2 * np.pi * np.cumsum(f0 * 2 ** (k * 1.0)) / SR) for f0 in (261.6, 392.0, 523.25)) / 3 * k ** 2.6 * 0.22
trem = 1 + 0.25 * np.sin(2 * np.pi * (9 + 14 * k) * tr)
ris = (sweep + glide * trem); ris[-int(0.012 * SR):] *= np.linspace(1, 0, int(0.012 * SR)); place(y, ris, 0.0)
# THE HIT
n = int(0.5 * SR); t = np.arange(n) / SR
thump = np.sin(2 * np.pi * np.cumsum(45 + 55 * np.exp(-t * 22)) / SR) * np.exp(-t / 0.11) * 0.95
body = np.sin(2 * np.pi * 196 * t) * np.exp(-t / 0.07) * 0.5 + np.sin(2 * np.pi * 392 * t) * np.exp(-t / 0.05) * 0.25      # so a phone speaker hears the weight
clack = bp_noise(n, 900, 7000) * np.exp(-t / 0.006) * 0.9 + np.sin(2 * np.pi * 1180 * t) * np.exp(-t / 0.03) * 0.4
air = bp_noise(n, 300, 3200) * np.exp(-t / 0.12) * 0.32 * np.minimum(1, t / 0.01)
place(y, thump + body + clack + air, HIT)
# bell strum: C major (add 9) rolling up, then two high answers
for i, semi in enumerate((0, 4, 7, 12, 14, 16, 19)): place(y, bell(NOTE(semi), 1.9 - i * 0.06, 1.0), HIT + 0.012 + i * 0.03, 0.2 - i * 0.008)
place(y, bell(NOTE(24), 1.2, 0.8), HIT + 0.30, 0.12); place(y, bell(NOTE(28), 1.0, 0.8), HIT + 0.42, 0.08)
n = int(1.4 * SR); t = np.arange(n) / SR
pad = sum(np.sin(2 * np.pi * f * t) for f in (261.63, 392.0, 659.26)) / 3 * np.minimum(1, t / 0.03) * np.exp(-t / 0.5) * 0.16; place(y, pad, HIT)
# coin shower (dense, then thinning) + a few lower clinks
tc = HIT + 0.07
while tc < 2.25:
    place(y, coin(rng.uniform(3000, 7600)), tc, rng.uniform(0.09, 0.17) * (1 - (tc - HIT) / 2.2) ** 0.6)
    if rng.random() < 0.3: place(y, coin(rng.uniform(1800, 2700)), tc + 0.01, 0.11)
    tc += rng.uniform(0.018, 0.05) * (1 + 2.6 * (tc - HIT))
# sparkle tail
n = int(1.9 * SR); t = np.arange(n) / SR
sh = bp_noise(n, 6000, 14000) * (0.55 + 0.45 * np.sin(2 * np.pi * 11 * t)) * np.minimum(1, t / 0.08) * np.exp(-t / 0.55) * 0.085; place(y, sh, HIT + 0.05)
y[-int(0.06 * SR):] *= np.linspace(1, 0, int(0.06 * SR)); y[:64] *= np.linspace(0, 1, 64)
y = np.tanh(y * 1.25) / np.tanh(1.25); y = norm(y, 0.89)
sf.write('ChestOpen.wav', y, SR)
# ------------------------------------------------------------------ ChestHum (seamless 4 s loop)
D2 = 4.0; N2 = int(D2 * SR); t = np.arange(N2) / SR; h = np.zeros(N2)
for f, a, lfo in ((523.25, 0.5, 0.25), (784.0, 0.34, 0.5), (1318.5, 0.2, 0.75), (1568.0, 0.1, 0.5), (2093.0, 0.06, 1.0)):
    f = round(f * D2) / D2                                   # whole cycles in the loop = no click at the seam
    h += a * np.sin(2 * np.pi * f * t) * (0.6 + 0.4 * np.sin(2 * np.pi * lfo * t + rng.uniform(0, 6.28)))
h *= 0.22
for tk in (0.35, 0.9, 1.5, 1.95, 2.6, 3.05, 3.6):            # tiny twinkles, written with wrap-around
    x = coin(rng.uniform(3800, 6800)) * 0.05; i = int(tk * SR)
    for j, v in enumerate(x): h[(i + j) % N2] += v
h = norm(h, 0.5); sf.write('ChestHum.wav', h, SR)
for nme in ('ChestOpen', 'ChestHum'):
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', nme + '.wav', '-c:a', 'libvorbis', '-q:a', '6', nme + '.ogg'], check=True)
import pyloudnorm as pyln
m = pyln.Meter(SR); print('ChestOpen LUFS %.1f peak %.2f | hum LUFS %.1f' % (m.integrated_loudness(y), np.abs(y).max(), m.integrated_loudness(h)))
# where the energy is (phone check): share above 250 Hz around the hit
seg = y[int(HIT * SR):int((HIT + 0.3) * SR)]; S = np.abs(np.fft.rfft(seg)) ** 2; f = np.fft.rfftfreq(len(seg), 1 / SR)
print('hit energy: <250 Hz %.0f%%, 250-1k %.0f%%, 1-5k %.0f%%, >5k %.0f%%' % tuple(100 * S[(f >= a) & (f < b)].sum() / S.sum() for a, b in ((0, 250), (250, 1000), (1000, 5000), (5000, 30000))))
