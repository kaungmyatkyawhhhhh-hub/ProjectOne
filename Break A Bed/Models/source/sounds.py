import numpy as np, wave, sys, os
SR = 44100; OUT = sys.argv[1]; os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(1)
def t(d): return np.arange(int(SR*d))/SR
def save(name, x, stereo_width=0.0):
    x = x/ (np.max(np.abs(x))+1e-9)*0.89
    L = x; R = x
    if stereo_width:
        d = int(SR*0.012); R = np.r_[np.zeros(d), x[:-d]]*(1-stereo_width) + x*stereo_width
    y = (np.stack([L, R], 1)*32767).astype(np.int16)
    with wave.open(f"{OUT}/{name}.wav", "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(y.tobytes())
from scipy.signal import lfilter, butter, sosfilt
def lp(x, hz, order=4): return sosfilt(butter(order, hz, "low", fs=SR, output="sos"), x)
def lowpass(x, a):  # one-pole
    return lfilter([a], [1, a-1], x)
def reverb(x, decay=2.0, mix=0.3):
    n = int(SR*decay); ir = rng.normal(0, 1, n)*np.exp(-t(decay)*5/decay)
    ir = lp(ir, 3500); ir /= np.sqrt(np.sum(ir**2))
    N = len(x)+len(ir); m = 1 << (N-1).bit_length()
    wet = np.fft.irfft(np.fft.rfft(x, m)*np.fft.rfft(ir, m), m)[:len(x)+len(ir)]
    out = np.r_[x, np.zeros(len(ir))]*(1-mix) + wet*mix*1.6
    return out

# 1) GONG: inharmonic partials, slow swell of upper partials, long decay
d = 5.0; tt = t(d); f0 = 92
x = np.zeros_like(tt)
for r, a, dec in [(1, 1.0, 1.4), (1.52, 0.6, 1.8), (2.03, 0.5, 2.2), (2.6, 0.35, 2.6), (3.18, 0.3, 3.0), (4.27, 0.2, 3.5), (5.4, 0.12, 4.0), (6.9, 0.08, 4.5)]:
    swell = (1 - np.exp(-tt*(2.5 if r > 2 else 30)))
    x += a*np.sin(2*np.pi*f0*r*tt*(1 - 0.004*np.exp(-tt*2)) + rng.random()*6)*np.exp(-tt/dec)*swell
x += 0.4*lp(rng.normal(0, 1, len(tt)), 2500)*np.exp(-tt*40)         # mallet hit
save("gong", reverb(x, 2.5, 0.25), 0.6)

# 2) WIND CHIME: metal bar tones on a pentatonic scale
d = 4.0; tt = t(d); x = np.zeros_like(tt)
notes = [1046.5, 1174.7, 1318.5, 1568.0, 1760.0, 2093.0]
for k in range(9):
    st = rng.uniform(0, 2.2); f = rng.choice(notes); i0 = int(st*SR); tl = tt[:len(tt)-i0]
    tone = sum(a*np.sin(2*np.pi*f*r*tl)*np.exp(-tl/dc) for r, a, dc in [(1, 1, 1.6), (2.76, 0.35, 0.6), (5.4, 0.15, 0.25)])
    x[i0:] += tone*rng.uniform(0.4, 1)*(1-np.exp(-tl*400))
save("wind_chime", reverb(x, 2.0, 0.35), 0.7)

# 3) SINGING BOWL hum (Sensei idle, quiet loop-able 6s)
d = 6.0; tt = t(d); f0 = 262
x = np.sin(2*np.pi*f0*tt)*(0.6+0.4*np.sin(2*np.pi*1.3*tt)) + 0.5*np.sin(2*np.pi*f0*2.71*tt + 1)*(0.6+0.4*np.sin(2*np.pi*0.9*tt+1)) + 0.2*np.sin(2*np.pi*f0*5.1*tt)
env = np.minimum(1, tt/0.8)*np.minimum(1, (d-tt)/0.8)
save("singing_bowl", x*env, 0.5)

# 4) TAIKO hit + 4-beat pattern
def taiko(d=1.2):
    tt = t(d); f = 55 + 70*np.exp(-tt*18)
    ph = 2*np.pi*np.cumsum(f)/SR
    body = np.sin(ph)*np.exp(-tt*4.5)
    skin = lp(rng.normal(0, 1, len(tt)), 1200)*np.exp(-tt*30)*1.5
    return body + skin
save("taiko_hit", reverb(taiko(), 1.2, 0.2), 0.3)
pat = np.zeros(int(SR*3.2))
for st, g in [(0, 1), (0.5, 0.7), (1.0, 1), (1.25, 0.6), (1.5, 1), (2.2, 1.2)]:
    h = taiko()*g; i0 = int(st*SR); pat[i0:i0+len(h)] += h[:len(pat)-i0]
save("taiko_pattern", reverb(pat, 1.2, 0.2), 0.3)

# 5) BAMBOO FLUTE phrase (crane)
seq = [(784, 0.35), (880, 0.35), (1046.5, 0.7), (880, 0.3), (784, 0.9)]
x = np.array([])
for f, dd in seq:
    tt = t(dd); vib = 1 + 0.006*np.sin(2*np.pi*5.5*tt)*np.minimum(1, tt*3)
    ph = 2*np.pi*np.cumsum(f*vib)/SR
    env = np.minimum(1, tt/0.06)*np.minimum(1, (dd-tt)/0.08)
    tone = np.sin(ph) + 0.25*np.sin(2*ph) + 0.08*np.sin(3*ph)
    breath = sosfilt(butter(2, [700, 3000], "band", fs=SR, output="sos"), rng.normal(0, 1, len(tt)))*0.15
    x = np.r_[x, (tone + breath)*env]
save("flute_phrase", reverb(x, 2.0, 0.35), 0.6)

# 6) RISING WHOOSH (rebirth swirl), 2.5s
d = 2.5; tt = t(d); n = rng.normal(0, 1, len(tt)); y = np.zeros_like(n); acc = 0.0; acc2 = 0.0
for i, v in enumerate(n):
    a = 0.02 + 0.35*(i/len(n))**1.5
    acc += a*(v-acc); acc2 += a*(acc-acc2); y[i] = acc - acc2*0.5
env = (tt/d)**1.6*np.minimum(1, (d-tt)/0.15)
save("whoosh_rise", y*env*(1+0.3*np.sin(2*np.pi*tt*(2+6*tt/d))), 0.8)

# 7) SPARKLE / SHIMMER (belt flies on, stripes)
d = 1.6; tt = t(d); x = np.zeros_like(tt)
for k in range(28):
    st = rng.uniform(0, 1.0); f = rng.uniform(2500, 6000); i0 = int(st*SR); tl = tt[:len(tt)-i0]
    x[i0:] += np.sin(2*np.pi*f*tl)*np.exp(-tl*14)*rng.uniform(0.3, 1)
save("sparkle", reverb(x, 1.0, 0.3), 0.8)

# 8) DEEP BOOM (burst moment)
d = 2.0; tt = t(d); f = 38 + 60*np.exp(-tt*6)
x = np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-tt*2.2) + lp(rng.normal(0, 1, len(tt)), 180)*np.exp(-tt*5)*4
save("boom", reverb(x, 1.5, 0.2), 0.4)
print(sorted(os.listdir(OUT)))
