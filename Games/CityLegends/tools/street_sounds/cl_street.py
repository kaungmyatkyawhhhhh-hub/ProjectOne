"""City Legends street sound set v1 (27 Nov 2026). All code-made: no recordings, no AI audio.
Owner (27 Nov): "npc traffic has like some car passing wind sound and npc footsteps", "they can honk",
"add sound to npc when they get hit with car too".
  CL_Roar      4 s seamless loop: tyre roar on asphalt (pink noise, tread hum 300-900 Hz, slow wobble) + wind (2-6 kHz).
               The game moves its pitch (Doppler) and volume (speed, distance); one loop serves every car.
  CL_HornCar   1.2 s: a car's twin disc horn (420 + 525 Hz, buzzy). Code cuts it short for a tap; pitched per car.
  CL_HornBus   1.4 s: a bus / truck air horn (185 + 233 Hz), slower attack, more buzz.
  CL_Step_1..4 flip-flop / slipper step on concrete: the sole slap, then the loose heel flapping up against it.
  CL_Thud_Soft / CL_Thud_Heavy: a body bump (low knock + cloth puff); heavy = deeper, longer, a little rattle.
  CL_Tumble    0.9 s: rolling on the ground: cloth scuffs + gravel scrape + two soft knocks.
48 kHz mono, -18 LUFS (loops -20), peaks under -1.5 dB. Run: python cl_street.py <outdir>"""
import numpy as np, soundfile as sf, pyloudnorm as pyln, os, sys
from scipy import signal
SR = 48000
rng = np.random.default_rng(27)
OUT = sys.argv[1] if len(sys.argv) > 1 else 'out'
os.makedirs(OUT, exist_ok=True)
def T(s): return int(round(s * SR))
def tt(L): return np.arange(T(L)) / SR
def bp(x, lo, hi, order=2): return signal.sosfilt(signal.butter(order, [lo, hi], 'bandpass', fs=SR, output='sos'), x)
def lp(x, f, order=2): return signal.sosfilt(signal.butter(order, f, 'lowpass', fs=SR, output='sos'), x)
def hp(x, f, order=2): return signal.sosfilt(signal.butter(order, f, 'highpass', fs=SR, output='sos'), x)
def norm(x): return x / (np.abs(x).max() + 1e-9)
def env(L, att, dec):
    t = tt(L); return np.minimum(t / max(att, 1e-4), 1) * np.exp(-t / dec)

def loop_noise(L, shape):
    """noise shaped in the frequency domain over exactly L seconds: circular, so the loop has no seam"""
    n = T(L); f = np.fft.rfftfreq(n, 1 / SR)
    spec = (rng.normal(size=len(f)) + 1j * rng.normal(size=len(f))) * shape(np.maximum(f, 1))
    return np.fft.irfft(spec, n)

def roar(L=4.0):
    tyre = norm(loop_noise(L, lambda f: f ** -0.5 * np.exp(-((np.log(f / 600)) / 0.9) ** 2)))
    hum = norm(loop_noise(L, lambda f: np.exp(-((f - 140) / 60) ** 2)))  # tread / road hum
    wind = norm(loop_noise(L, lambda f: np.exp(-((np.log(f / 3200)) / 0.6) ** 2)))
    t = tt(L)
    wob = 1 + 0.12 * np.sin(2 * np.pi * t / L * 3) + 0.06 * np.sin(2 * np.pi * t / L * 7 + 1)  # whole cycles: seamless
    return (tyre * 0.8 + hum * 0.35 + wind * 0.3) * wob

def horn(f1, f2, L, att, buzz, body):
    t = tt(L); y = np.zeros(len(t))
    for f in (f1, f2):
        ph = 2 * np.pi * f * (1 + 0.003 * np.sin(2 * np.pi * 6 * t)) * t
        y += signal.sawtooth(ph, 0.5 + 0.45 * buzz) + 0.6 * np.sign(np.sin(ph)) * buzz
    y = bp(y, body[0], body[1], 2) + 0.25 * y  # the horn's bell / the car's front
    y = np.tanh(2.2 * norm(y))  # the diaphragm clips
    e = np.minimum(t / att, 1) * np.minimum((L - t) / 0.04, 1)
    return y * e

def step(seed):
    r = np.random.default_rng(seed)
    L = 0.28; y = np.zeros(T(L))
    slap = bp(r.normal(size=T(0.05)), 500 + r.uniform(-80, 80), 3200 + r.uniform(-300, 300)) * env(0.05, 0.0015, 0.009)
    thump = np.sin(2 * np.pi * (110 + r.uniform(-15, 15)) * tt(0.06)) * env(0.06, 0.002, 0.018) * 0.6
    gap = T(0.05 + r.uniform(0, 0.03))  # the loose heel comes up and slaps the foot
    flap = bp(r.normal(size=T(0.035)), 1400, 5500) * env(0.035, 0.001, 0.006) * (0.45 + r.uniform(0, 0.15))
    grit = hp(r.normal(size=T(0.12)), 3000) * env(0.12, 0.01, 0.03) * 0.06
    y[:len(slap)] += slap; y[:len(thump)] += thump; y[gap:gap + len(flap)] += flap; y[:len(grit)] += grit
    return y

def thud(heavy):
    L = 0.7 if heavy else 0.4; t = tt(L)
    f = (75 if heavy else 120) * (1 + 0.8 * np.exp(-t / 0.02))
    knock = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(L, 0.002, 0.09 if heavy else 0.05)
    puff = lp(rng.normal(size=len(t)), 1800) * env(L, 0.003, 0.05) * 0.5
    cloth = bp(rng.normal(size=len(t)), 1500, 6000) * env(L, 0.01, 0.08) * 0.12
    y = knock + puff + cloth
    if heavy:  # a little rattle of whatever they carried
        for k in range(4):
            o = T(0.08 + 0.07 * k + rng.uniform(0, 0.03))
            c = bp(rng.normal(size=T(0.02)), 2500, 7000) * env(0.02, 0.0005, 0.004) * 0.15
            y[o:o + len(c)] += c
    return y

def tumble(L=0.9):
    t = tt(L); y = np.zeros(len(t))
    scrape = bp(rng.normal(size=len(t)), 900, 6000) * (np.sin(np.pi * t / L) ** 1.5) * (0.6 + 0.4 * np.abs(np.sin(2 * np.pi * 5 * t)))
    y += scrape * 0.35
    for at, a in ((0.05, 0.8), (0.42, 0.55)):
        k = thud(False) * a; o = T(at); n = min(len(k), len(y) - o); y[o:o + n] += k[:n]
    return y * np.minimum((L - t) / 0.08, 1)

def master(x, lufs=-18.0, ceil=-1.5, fade_in=0.004, loop=False):
    y = hp(x, 60).astype(np.float64)
    if not loop:
        y *= np.minimum(tt(len(y) / SR) / fade_in, 1)
        y[-T(0.01):] *= np.linspace(1, 0, T(0.01))
    m = pyln.Meter(SR, block_size=min(0.4, len(y) / SR * 0.45))
    y = y * 10 ** ((lufs - m.integrated_loudness(y)) / 20)
    pk = np.abs(y).max(); lim = 10 ** (ceil / 20)
    if pk > lim: y *= lim / pk
    return y.astype(np.float32)

def out(name, y, **k):
    y = master(y, **k); sf.write(f'{OUT}/{name}.wav', y, SR, subtype='PCM_16')
    m = pyln.Meter(SR, block_size=min(0.4, len(y) / SR * 0.45))
    print(f'{name:14s} {len(y) / SR:5.2f}s  {m.integrated_loudness(y):6.1f} LUFS  peak {20 * np.log10(np.abs(y).max()):5.1f} dB')

out('CL_Roar', roar(), lufs=-20, loop=True)
out('CL_HornCar', horn(420, 525, 1.2, 0.012, 0.35, (500, 2600)))
out('CL_HornBus', horn(185, 233, 1.4, 0.05, 0.6, (250, 1600)), lufs=-17)
for i in range(4): out(f'CL_Step_{i + 1}', step(100 + i), lufs=-20)
out('CL_Thud_Soft', thud(False))
out('CL_Thud_Heavy', thud(True), lufs=-16)
out('CL_Tumble', tumble(), lufs=-19)
# self-check: the roar loop has no seam (the jump at the wrap is no bigger than a normal sample step)
r, _ = sf.read(f'{OUT}/CL_Roar.wav')
assert abs(r[0] - r[-1]) < 6 * np.abs(np.diff(r)).mean(), 'roar loop seam'
