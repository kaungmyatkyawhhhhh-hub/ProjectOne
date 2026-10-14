import numpy as np, wave, sys
from scipy.signal import butter, sosfilt
SR = 44100; rng = np.random.default_rng(4)
def bp(x, lo, hi): return sosfilt(butter(2, [lo, hi], "band", fs=SR, output="sos"), x)
d = 1.8; n = int(SR*d); x = np.zeros(n)
# 1) the snap/crack
crack = bp(rng.normal(0, 1, int(SR*0.08)), 1500, 7000)*np.exp(-np.arange(int(SR*0.08))/SR*60)
x[:len(crack)] += crack*1.4
# 2) hollow bamboo knocks: each piece hits the ground and bounces 2-3 times
def knock(f, amp, dur=0.18):
    t = np.arange(int(SR*dur))/SR
    tone = np.sin(2*np.pi*f*t) + 0.5*np.sin(2*np.pi*f*2.3*t) + 0.25*np.sin(2*np.pi*f*3.9*t)
    click = bp(rng.normal(0, 1, len(t)), 800, 5000)*np.exp(-t*120)*0.6
    return (tone*np.exp(-t*28) + click)*amp
for piece in range(7):
    t0 = rng.uniform(0.12, 0.45); f = rng.uniform(380, 950); amp = rng.uniform(0.5, 1.0)
    gap = rng.uniform(0.12, 0.2)
    for b in range(rng.integers(2, 4)):
        i0 = int(t0*SR)
        k = knock(f*rng.uniform(0.97, 1.03), amp)
        x[i0:i0+len(k)] += k[:max(0, n-i0)]
        t0 += gap; gap *= 0.62; amp *= 0.5
x /= np.abs(x).max(); x *= 0.9
y = (np.stack([x, np.r_[np.zeros(300), x[:-300]]], 1)*32767).astype(np.int16)
w = wave.open(sys.argv[1], "wb"); w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(y.tobytes()); w.close()
