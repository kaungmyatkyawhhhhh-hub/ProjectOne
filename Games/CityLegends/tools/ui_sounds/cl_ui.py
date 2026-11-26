"""City Legends UI sound set v1 (26 Nov 2026). All code-made: no recordings, no AI audio.
Owner: "we need to improve our city legends' too" (after the modern GUI / sound / VFX studies). Before: ONE Roblox
built-in sound (volume_slider.ogg, "tick") played for every button, every menu, every reward.
Research used (vault):
  Roblox Playbook/Research notes/2026-11-26 Research - Modern lobby HUD, window motion and UI SFX (TDS): clicks ~3 kHz
    ~0.2 s, a louder whoosh to open, the claim is the loudest and shortest (56 ms pop), buy = punchy hit + sparkle,
    no hover sound, music ~20 dB under UI;
  .../2026-11-26 Research - Driving-game UI, sound and motion (gap study): clicks under 100 ms, stingers under 300 ms
    (rewards) / ~1 s (level up), UI about music level, music ducks under a stinger;
  MEGA BITE UI sound set v3 (same method: transient + body + tail, every layer ends on a fade, -16..-19 LUFS,
    peaks under -1.5 dB, one family in one key).
Family: "night drive". A tight two-blade switch click (a car's switchgear) + a warm filtered-saw synth pluck
(synthwave, the game's night city) in A minor pentatonic (A C D E G). 48 kHz mono.
Run: python cl_ui.py <outdir>"""
import numpy as np, soundfile as sf, pyloudnorm as pyln, os, sys
from scipy import signal
from pedalboard import Pedalboard, HighpassFilter, LowpassFilter, Reverb, HighShelfFilter
SR = 48000
rng = np.random.default_rng(26)
OUT = sys.argv[1] if len(sys.argv) > 1 else 'out'
os.makedirs(OUT, exist_ok=True)
def T(s): return int(round(s * SR))
def N(m): return 440.0 * 2 ** ((m - 69) / 12)
A4, C5, D5, E5, G5, A5, C6, D6, E6, G6, A6, C7, E7 = 69, 72, 74, 76, 79, 81, 84, 86, 88, 91, 93, 96, 100
def tt(L): return np.arange(T(L)) / SR

def synth(midi, L=0.3, dec=0.08, cut=4200, harm=7, att=0.002, glide=0.0):
    """warm saw pluck: harmonics 1..harm at 1/n, two voices 7 cents apart, a quick filter-like brightness decay"""
    t = tt(L); y = np.zeros(len(t))
    for det in (-0.0035, 0.0035):
        f = N(midi) * (1 + det) * (1 - glide * np.exp(-t / 0.015))
        ph = 2 * np.pi * np.cumsum(f) / SR
        for n in range(1, harm + 1):
            if N(midi) * n > cut * 2.2: break
            # higher harmonics die faster: the "filter envelope" of a synth pluck
            y += np.sin(n * ph) / n * np.exp(-t / (dec / (1 + 0.45 * (n - 1))))
    y *= np.exp(-t / dec * 0.35) * np.minimum(t / att, 1)
    return (y / (np.abs(y).max() + 1e-9)).astype(np.float32)
def switch(L=0.03, gap=0.006, lo=1600, hi=6500, dec=0.0025):
    """the switch: two short band-passed clicks `gap` apart (press + latch)"""
    t = tt(L); n = rng.standard_normal(len(t))
    e = np.exp(-t / dec) + 0.55 * np.exp(-np.maximum(t - gap, 0) / (dec * 0.8)) * (t >= gap)
    sos = signal.butter(2, [lo, hi], 'bp', fs=SR, output='sos')
    return signal.sosfilt(sos, n * e).astype(np.float32)
def thump(f0=150, f1=55, L=0.16, dec=0.05):
    t = tt(L); f = f1 + (f0 - f1) * np.exp(-t / 0.02)
    return (np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / dec) * np.minimum(t / 0.002, 1)).astype(np.float32)
def swish(L, f_a, f_b, peak=0.5, q=1.5):
    """airy whoosh (a car passing): band-passed noise whose centre moves f_a -> f_b, bell-shaped loudness"""
    n = T(L); t = np.arange(n) / SR; x = t / L
    fc = f_a * (f_b / f_a) ** x
    noise = rng.standard_normal(n).astype(np.float32); y = np.zeros(n, np.float32); B = 256; zi = None
    for i in range(0, n, B):
        c = float(fc[min(i + B // 2, n - 1)]); lo = max(60, c / q); hi = min(SR / 2 - 200, c * q)
        sos = signal.butter(2, [lo, hi], 'bp', fs=SR, output='sos')
        if zi is None: zi = signal.sosfilt_zi(sos) * 0
        y[i:i + B], zi = signal.sosfilt(sos, noise[i:i + B], zi=zi)
    env = np.exp(-0.5 * ((x - peak) / 0.26) ** 2) * np.minimum(x / 0.08, 1) * np.minimum((1 - x) / 0.15, 1)
    y = y * env; return (y / (np.abs(y).max() + 1e-9)).astype(np.float32)
def ping(f, L=0.3, dec=0.07):
    """a coin's ring: a bright partial set (1, 2.76, 5.4) like a small metal disc"""
    t = tt(L); y = np.zeros(len(t))
    for r, g, d in ((1, 1.0, 1.0), (2.76, 0.45, 0.6), (5.4, 0.2, 0.35)):
        y += g * np.sin(2 * np.pi * f * r * t) * np.exp(-t / (dec * d))
    return (y * np.minimum(t / 0.001, 1) / 1.65).astype(np.float32)
def sparkle(L=0.4, n=12, lo=4000, hi=8500, dec=0.045, seed=1):
    r = np.random.default_rng(seed); y = np.zeros(T(L), np.float32)
    for k in range(n):
        at = r.uniform(0, L * 0.7); f = r.uniform(lo, hi); g = r.uniform(0.3, 1.0) * (1 - at / L)
        t = tt(min(0.14, L - at)); s = np.sin(2 * np.pi * f * t) * np.exp(-t / dec) * np.minimum(t / 0.002, 1) * g
        i = T(at); y[i:i + len(s)] += s
    return y / (np.abs(y).max() + 1e-9)
def mix(L, *parts):
    y = np.zeros(T(L), np.float32)
    for x, at, g in parts:
        i = T(at); n = min(len(x), len(y) - i)
        if n > 0:
            p = x[:n].copy(); k = min(n // 2, T(0.008)); p[-k:] *= np.linspace(1, 0, k) ** 2  # no click where a layer is cut
            y[i:i + n] += g * p
    return y
def master(x, lufs=-18.0, hp=120, lp=12000, verb=0.06, room=0.2, shelf=0.0, tail=0.08, ceil=-1.5, peak=None):
    fx = [HighpassFilter(hp), LowpassFilter(lp)]
    if shelf: fx.append(HighShelfFilter(cutoff_frequency_hz=5000, gain_db=shelf))
    if verb: fx.append(Reverb(room_size=room, damping=0.7, wet_level=verb, dry_level=1.0, width=0.0))
    y = Pedalboard(fx)(np.concatenate([x, np.zeros(T(tail), np.float32)])[None, :], SR)[0]
    y = y - np.mean(y)
    m = pyln.Meter(SR, block_size=min(0.1, len(y) / SR * 0.45)); l = m.integrated_loudness(y)
    if np.isfinite(l): y = y * 10 ** ((lufs - l) / 20)
    pk = np.abs(y).max()
    if pk > 10 ** (ceil / 20): y = np.tanh(y / pk * 1.2) / np.tanh(1.2) * 10 ** (ceil / 20)
    if peak is not None: y = y / (np.abs(y).max() + 1e-9) * 10 ** (peak / 20)  # short sounds: match the peak
    a = T(0.0015); b = min(len(y) // 2, T(0.03)); y[:a] *= np.linspace(0, 1, a); y[-b:] *= np.linspace(1, 0, b) ** 2
    e = np.nonzero(np.abs(y) > 10 ** (-60 / 20))[0]; y = y[:min(len(y), e[-1] + T(0.02))] if len(e) else y
    return y.astype(np.float32)
REPORT = []
def out(name, y, **k):
    y = master(y, **k); sf.write(f'{OUT}/{name}.wav', y, SR, subtype='PCM_16')
    m = pyln.Meter(SR, block_size=min(0.1, len(y) / SR * 0.45)); l = m.integrated_loudness(y)
    REPORT.append(f'{name}: {len(y) / SR * 1000:.0f} ms, {l:.1f} LUFS, peak {20 * np.log10(np.abs(y).max()):.1f} dB')
    return y

# 1 CLICK (every small button, 3 takes so repeats never machine-gun): the switch + a muted synth blip. ~90 ms
for i, m in enumerate([A5, C6, D6]):
    out(f'CL_Click_{i + 1}', mix(0.1, (switch(), 0.003, 0.9), (synth(m, 0.08, 0.018, 3500, 5), 0.005, 0.55)), lufs=-19, verb=0.0, shelf=1.5, peak=-5.0)
# 2 TAB (menu tabs): one crisp E6 pluck on the switch; the code raises the pitch per tab (A minor pentatonic steps)
out('CL_Tab', mix(0.2, (switch(0.02, 0.005), 0, 0.6), (synth(E6, 0.18, 0.04, 5000, 6), 0.001, 0.9), (swish(0.09, 2000, 4500, 0.4), 0, 0.12)), lufs=-19, verb=0.03)
# 3 OPEN (a big window: main menu, garage, dealer, store): a car-pass whoosh up into A5 + E6 together, then A6. ~0.6 s
out('CL_Open', mix(0.7, (swish(0.32, 300, 4800, 0.7), 0, 0.6), (thump(130, 60, 0.12, 0.035), 0.04, 0.45), (switch(), 0.0, 0.35),
                   (synth(A5, 0.45, 0.13, 4000), 0.20, 0.7), (synth(E6, 0.45, 0.13, 4500), 0.20, 0.55), (synth(A6, 0.35, 0.10, 6000), 0.29, 0.4),
                   (sparkle(0.3, 6, 4500, 8000, 0.04, 2), 0.28, 0.08)), lufs=-17.5, verb=0.1, room=0.3)
# 4 CLOSE: the mirror: a falling whoosh and E6 -> A5
out('CL_Close', mix(0.45, (swish(0.2, 4200, 500, 0.3), 0, 0.5), (synth(E6, 0.14, 0.04, 4500, 6), 0.0, 0.7), (synth(A5, 0.22, 0.06, 3500, 6), 0.07, 0.7)), lufs=-19.5, verb=0.05)
# 5 CONFIRM (buy, equip, claim, fit a part): a thump, then A5 -> E6 -> A6 rising, short shimmer. ~0.6 s
out('CL_Confirm', mix(0.7, (thump(170, 60, 0.14, 0.04), 0, 0.8), (switch(), 0, 0.4), (synth(A5, 0.25, 0.07, 4000), 0.002, 0.7),
                      (synth(E6, 0.3, 0.09, 5000), 0.07, 0.75), (synth(A6, 0.45, 0.14, 6500), 0.14, 0.75), (sparkle(0.35, 9, 4200, 8500, 0.05, 7), 0.15, 0.12)),
    lufs=-16.5, verb=0.1, room=0.26, shelf=1.0)
# 6 CASH (money in: a pay popup, a cut-up bonus banked, a paycheck): two coin rings and a sparkle. Short and bright. ~0.3 s
out('CL_Cash', mix(0.35, (switch(0.02, 0.004, 3000, 9000), 0, 0.35), (ping(2637, 0.25, 0.06), 0.0, 0.8), (ping(3520, 0.25, 0.06), 0.055, 0.7),
                   (sparkle(0.22, 7, 5000, 9000, 0.03, 4), 0.05, 0.18)), lufs=-17, verb=0.05, hp=400)
# 7 LEVEL UP (player or car level): the big one. Bass hit, whoosh up, A-C-E-A arpeggio, a held A chord, sparkle. ~1.2 s
arp = [(A5, 0.08), (C6, 0.15), (E6, 0.22), (A6, 0.29)]
out('CL_LevelUp', mix(1.3, (thump(160, 45, 0.3, 0.09), 0, 1.0), (swish(0.36, 300, 5600, 0.75), 0, 0.5),
                      *[(synth(m, 0.35, 0.09, 5500), at, 0.6 + 0.08 * k) for k, (m, at) in enumerate(arp)],
                      (synth(A5, 0.9, 0.35, 3500), 0.36, 0.45), (synth(E6, 0.9, 0.35, 4500), 0.36, 0.4), (synth(A6, 0.8, 0.3, 6000), 0.36, 0.35),
                      (sparkle(0.7, 18, 4200, 9000, 0.06, 11), 0.3, 0.16)), lufs=-15.5, verb=0.14, room=0.35, shelf=1.0)
# 8 ERROR (can't afford, locked): two low notes falling with a dull buzz. ~0.25 s
t = tt(0.22); buzz = (signal.sawtooth(2 * np.pi * 110 * t) * np.exp(-t / 0.08)).astype(np.float32)
out('CL_Error', mix(0.3, (switch(), 0, 0.4), (synth(E5, 0.12, 0.05, 1800, 5), 0.0, 0.7), (synth(C5, 0.16, 0.06, 1500, 5), 0.08, 0.7), (buzz, 0.0, 0.18)),
    lufs=-19, verb=0.02, lp=5000)
print('\n'.join(REPORT))
