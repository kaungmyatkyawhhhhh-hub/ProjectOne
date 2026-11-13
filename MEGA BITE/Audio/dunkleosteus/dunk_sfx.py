"""MEGA BITE Dunkleosteus sounds (13 Nov 2026). Owner 14:19: "put sfx for the new ones". All code-made (sfxlib = the helpers of
Audio/abil3/abil3.py). The family: BONE and STONE (armour plates, bone blades) with a lime-green energy shimmer, so it never
sounds like the Hammerhead it borrows its ram clip from.
  BoneRam   - the ability BONE RAM, on the HammerRam clip's own timeline: starts at RamIn (0.01 s), the HIT at Ram (0.42 s)
  BoneBite1-3 - the bite: two bone blades snapping shut (a hollow wood-block TOK, not teeth) + the heavy jaw + a crunch
  EvolveAncient - evolving INTO the Dunkleosteus: same timeline as Evolve (riser, hit on the cutscene flash at 1.1 s, tail)
Rules: identity in 1-5 kHz (phones), about -13.5 LUFS, true peak under -1 dB, kid-friendly (no screams, no gore sounds)."""
import numpy as np
from sfxlib import *
rng2 = np.random.default_rng(808)

def tok(f=820, tau=0.045, p=1.0):
    """bone/wood block: a pitched hollow knock (two inharmonic modes), the phone-speaker part of every bone hit"""
    t = t_(0.25); y = np.zeros(len(t))
    for k, (m, a) in enumerate([(1.0, 1.0), (2.76, 0.42), (5.4, 0.16)]):
        y += np.sin(2 * np.pi * f * p * m * t + rng2.uniform(0, 6)) * a * np.exp(-t / (tau / (1 + k * 0.9)))
    return y * np.minimum(t / 0.0008, 1)

def plates(d, rate=22, f0=1300):
    """armour plates shifting: a fast irregular rattle of small bone clicks"""
    n = int(d * SR); y = np.zeros(n); at = 0.0
    while at < d:
        at += rng2.exponential(1 / rate); g = rng2.uniform(0.3, 1.0)
        place(y, tok(f0 * rng2.uniform(0.8, 1.3), 0.012), at, g * 0.5)
    return y

def shimmer(d, f_hi=5200, f_lo=1800):
    """the lime glow: a soft glassy chime falling, a few partials"""
    t = t_(d); y = np.zeros(len(t))
    for k, r in enumerate([1.0, 1.26, 1.5, 2.0]):
        f = f_hi * r * (f_lo / f_hi) ** (t / d) ** 0.6
        y += np.sin(2 * np.pi * np.cumsum(f) / SR + k) * np.exp(-t / (d * 0.35)) * (0.6 ** k)
    return y * np.minimum(t / 0.01, 1) * np.clip((d - t) / (0.45 * d), 0, 1) ** 1.5   # fades out over its last 45% (no hard stop)

# ---------------- BONE RAM (1.7 s) ----------------
N = int(1.7 * SR); mix = np.zeros(N); W = 0.33 - OFF; I = 0.42 - OFF
t = t_(W); f0 = np.interp(t, [0, W], [44, 64])
gr = lp(saws(f0, [(1, 1), (1.013, 0.8), (0.5, 0.7)]) * (1 + 0.6 * np.sin(2 * np.pi * 13 * t)), 420)
place(mix, gr * ramp(W, 1.4, 0.02), 0, 0.34)                                                     # a deep ancient growl gathering
place(mix, plates(W, 26, 1250) * ramp(W, 1.2, 0.02), 0, 0.5)                                   # the armour plates locking into place
d = I - W + 0.03; place(mix, sweep(d + 0.06, 300, 3600, curve=1.8, q=0.42) * ramp(d + 0.06, 1.6, 0.008), W - 0.05, 0.55)   # the charge
place(mix, hp(noise(int(0.04 * SR)), 2400) * dec(0.04, 0.006), I, 1.4)                        # HIT: crack
place(mix, tok(560, 0.11), I, 1.7)                                                             # the skull: one huge hollow bone TOK
place(mix, tok(1040, 0.05), I + 0.004, 0.8)
place(mix, bp(noise(int(0.16 * SR)), 900, 3200) * dec(0.16, 0.04), I, 1.3)                     # the smack
place(mix, lp(noise(int(0.5 * SR)), 260) * dec(0.5, 0.11), I, 1.15)                            # the mass
place(mix, subdrop(1.1, 78, 26, 0.25, 0.55), I, 0.7)
for _ in range(16):                                                                            # stone and bone chips rattling off
    at = I + rng2.uniform(0.03, 0.5); L_ = rng2.uniform(0.008, 0.025)
    place(mix, tok(rng2.uniform(900, 2600), L_ * 0.6), at, 0.42 * (1 - (at - I) / 0.6))
place(mix, lp(noise(int(0.6 * SR)), 900) * dec(0.6, 0.18, 0.02) * (0.5 + 0.5 * np.sin(2 * np.pi * 9 * t_(0.6))), I + 0.05, 0.35)   # rubble settling
place(mix, shimmer(0.9), I + 0.02, 0.32)                                                       # the lime energy rings out
place(mix, bubbles(0.8, 90, 330, 1400) * np.linspace(1, 0, int(0.8 * SR)) ** 1.2, I + 0.03, 0.30)
finish(mix, 'BoneRam', lufs=-13.0, lpf=10000, verb=0.17, room=0.55)

# ---------------- BONE BITE x3 (0.55 s) ----------------
for k, p in enumerate([1.0, 0.94, 1.07]):
    N = int(0.55 * SR); mix = np.zeros(N); c = 0.012
    place(mix, sweep(0.07, 500, 2400 * p, curve=1.6, q=0.4) * ramp(0.07, 1.5, 0.006), 0, 0.25)  # the jaw swinging shut
    place(mix, tok(980, 0.04, p), c + 0.07, 1.25)                                                # blade meets blade
    place(mix, tok(1480, 0.025, p), c + 0.079, 0.7)                                              # and the second pair, a few ms later
    place(mix, hp(noise(int(0.01 * SR)), 3000) * dec(0.01, 0.0015), c + 0.07, 0.8)
    place(mix, bp(noise(int(0.1 * SR)), 380 * p, 1500 * p) * dec(0.1, 0.024), c + 0.075, 1.15)  # the crunch
    place(mix, subdrop(0.18, 120 * p, 55, 0.03, 0.06), c + 0.07, 0.85)                         # the heavy armoured jaw
    place(mix, bubbles(0.2, 9, 600, 2000), c + 0.1, 0.2)
    finish(mix, f'BoneBite{k + 1}', lufs=-14.0, lpf=11000, verb=0.1, room=0.35)

# ---------------- EVOLVE ANCIENT (3.3 s; hit on the cutscene flash at 1.1 s) ----------------
N = int(3.3 * SR); mix = np.zeros(N); H = 1.1
t = t_(H); f0 = np.interp(t, [0, H], [38, 66])
place(mix, lp(saws(f0, [(1, 1), (1.008, 0.8), (0.5, 0.7), (1.5, 0.25)]), 600) * ramp(H, 1.6, 0.02), 0, 0.42)   # the deep horn rising
place(mix, plates(H, 14, 1100) * ramp(H, 2.2, 0.02), 0, 0.45)                                              # plates growing over the body
place(mix, sweep(H, 120, 4200, curve=2.4, q=0.38) * ramp(H, 2.4, 0.01), 0, 0.42)
place(mix, hp(noise(int(0.05 * SR)), 2400) * dec(0.05, 0.008), H, 1.3)                                     # HIT on the white flash
place(mix, tok(420, 0.16), H, 1.6); place(mix, tok(760, 0.09), H + 0.005, 1.0)
place(mix, lp(noise(int(0.8 * SR)), 240) * dec(0.8, 0.18), H, 1.2)
place(mix, subdrop(1.8, 70, 24, 0.35, 0.8), H, 0.75)
tt = t_(2.1); ch = np.zeros(len(tt))
for f, a in [(392, 1.0), (494, 0.8), (587, 0.75), (784, 0.55), (988, 0.4)]:                               # G-major bell chord (the Gold Rush / evolve key family)
    for m, am in [(1, 1), (2.01, 0.35), (3.02, 0.15)]:
        ch += np.sin(2 * np.pi * f * m * tt + rng2.uniform(0, 6)) * a * am * np.exp(-tt / (0.9 / m))
place(mix, ch * np.minimum(tt / 0.004, 1), H + 0.02, 0.28)
place(mix, shimmer(1.6, 6200, 2200), H + 0.05, 0.3)
for _ in range(22):
    at = H + rng2.uniform(0.04, 1.0); place(mix, tok(rng2.uniform(900, 2800), 0.012), at, 0.3 * (1 - (at - H) / 1.2))
place(mix, bubbles(1.6, 120, 300, 1500) * np.linspace(1, 0, int(1.6 * SR)) ** 1.3, H + 0.05, 0.3)
finish(mix, 'EvolveAncient', lufs=-13.0, lpf=11000, verb=0.2, room=0.6)
print('done')
