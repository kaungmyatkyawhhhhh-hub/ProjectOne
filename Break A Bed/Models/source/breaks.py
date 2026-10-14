import numpy as np, wave, subprocess, os, sys
from scipy.signal import butter, sosfilt
SR = 44100; OUT = sys.argv[1]; os.makedirs(OUT, exist_ok=True)
R = np.random.default_rng(11)
def T(d): return np.arange(int(SR*d))/SR
def filt(x, kind, hz, o=2): return sosfilt(butter(o, hz, kind, fs=SR, output="sos"), x)
def noise(d): return R.normal(0, 1, int(SR*d))
def place(buf, x, t0, g=1.0):
    i = int(t0*SR); n = min(len(x), len(buf)-i)
    if n > 0: buf[i:i+n] += x[:n]*g
def burst(d, lo, hi, dec):
    return filt(noise(d), "band", [lo, hi])*np.exp(-T(d)*dec)
def knock(f, dec=28, d=0.25):
    t = T(d); return (np.sin(2*np.pi*f*t) + 0.5*np.sin(2*np.pi*f*2.3*t) + 0.2*np.sin(2*np.pi*f*3.9*t))*np.exp(-t*dec) + burst(d, 800, 5000, 120)*0.4
def knocks(buf, flo, fhi, n, t0=0.1, spread=0.35, dec=28, g=0.8):
    for _ in range(n):
        t = t0 + R.uniform(0, spread); f = R.uniform(flo, fhi); a = g*R.uniform(0.5, 1); gap = R.uniform(0.1, 0.18)
        for b in range(R.integers(2, 4)):
            place(buf, knock(f*R.uniform(.97, 1.03), dec), t, a); t += gap; gap *= .6; a *= .5
def ping(f, dec=6, d=1.0):
    t = T(d); return (np.sin(2*np.pi*f*t) + 0.3*np.sin(2*np.pi*f*2.76*t))*np.exp(-t*dec)
def shatter(buf, flo, fhi, n=30, t0=0.0, g=0.5, nb=(2000, 12000)):
    place(buf, burst(0.25, nb[0], nb[1], 18), t0, 1.2)
    for _ in range(n): place(buf, ping(R.uniform(flo, fhi), R.uniform(8, 18), 0.6), t0 + R.exponential(0.12), g*R.uniform(.3, 1))
def metal(f, dec=3, d=1.5):
    t = T(d); x = sum(a*np.sin(2*np.pi*f*r*t + R.random()*6)*np.exp(-t*dec*(1+r/3)) for r, a in [(1, 1), (2.41, .7), (3.73, .5), (5.2, .35), (6.9, .2)])
    return x + burst(d, 1000, 8000, 60)*0.5
def boom(f0=40, d=1.6, g=1.0):
    t = T(d); f = f0 + 70*np.exp(-t*7)
    return (np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-t*2.5) + filt(noise(d), "low", 200, 4)*np.exp(-t*5)*3)*g
def hiss(d, lo=2000, hi=9000, att=0.05, dec=2.0):
    t = T(d); return filt(noise(d), "band", [lo, hi])*np.minimum(1, t/att)*np.exp(-t*dec)
def sweep(f0, f1, d, wave_="sin"):
    t = T(d); f = f0*(f1/f0)**(t/d); ph = 2*np.pi*np.cumsum(f)/SR
    x = np.sin(ph) if wave_ == "sin" else np.sign(np.sin(ph))*0.6
    return x
def chime(buf, freqs, t0=0.0, g=0.5, step=0.06):
    for i, f in enumerate(freqs): place(buf, ping(f, 3.5, 1.6), t0 + i*step, g)
def reverb(x, dur=1.2, mix=0.25):
    n = int(SR*dur); ir = filt(noise(dur), "low", 5000, 4)*np.exp(-T(dur)*4/dur); ir /= np.sqrt((ir**2).sum())
    m = 1 << (len(x)+n-1).bit_length(); wet = np.fft.irfft(np.fft.rfft(x, m)*np.fft.rfft(ir, m), m)[:len(x)+n]
    return np.r_[x, np.zeros(n)]*(1-mix) + wet*mix*1.5
def save(name, x, rv=(1.0, 0.2)):
    x = reverb(x, *rv); x = x/np.abs(x).max()*0.88
    tail = np.where(np.abs(x) > 0.002)[0]; x = x[:tail[-1]+2000] if len(tail) else x
    fade = np.minimum(1, (len(x)-np.arange(len(x)))/(SR*0.05)); x *= fade
    Rr = np.r_[np.zeros(260), x[:-260]]
    y = (np.stack([x, Rr], 1)*32767).astype(np.int16); p = f"{OUT}/{name}.wav"
    w = wave.open(p, "wb"); w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(y.tobytes()); w.close()
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", p, "-c:a", "libvorbis", "-q:a", "5", p[:-4]+".ogg"]); os.remove(p)
def buf(d=2.2): return np.zeros(int(SR*d))

# ---- 25 recipes ----
b = buf(); place(b, burst(0.35, 300, 3000, 9), 0, 1.2); place(b, burst(0.25, 500, 4000, 14), 0.08, .8)   # paper rip
knocks(b, 120, 220, 4, 0.2, 0.3, 40, 0.6); save("bed01_cardboard", b)
b = buf(); place(b, burst(0.06, 200, 6000, 60), 0, 2); place(b, hiss(1.2, 1500, 7000, 0.01, 3), 0.03, .9)   # pop + air hiss
place(b, sweep(300, 120, 0.6)*np.exp(-T(0.6)*4), 0.05, .4); save("bed02_air_mattress", b)
b = buf(); place(b, burst(0.5, 400, 3500, 6), 0, 1.0); place(b, burst(0.3, 150, 800, 10), 0.15, 1.0)        # fabric rip + soft thud
place(b, boom(60, 0.5, .5), 0.2); save("bed03_sleeping_bag", b)
b = buf(); place(b, burst(0.08, 1500, 7000, 60), 0, 1.4); knocks(b, 380, 900, 7); save("bed04_wooden", b)
b = buf(); place(b, burst(0.1, 1000, 6000, 40), 0, 1.4); place(b, boom(50, 0.8, .7), 0.05); knocks(b, 250, 700, 11, 0.1, 0.6); save("bed05_bunk", b)
b = buf(); place(b, burst(0.05, 300, 5000, 70), 0, 1.5)                                                   # pop + splash
sp = filt(noise(1.0), "band", [400, 6000])*np.exp(-T(1.0)*3.5)*(1+0.5*np.sin(2*np.pi*14*T(1.0))); place(b, sp, 0.04, 1.2)
for _ in range(8): place(b, sweep(R.uniform(700, 1400), R.uniform(1500, 2500), 0.05)*np.exp(-T(0.05)*40), 0.1 + R.uniform(0, 0.6), .3)
save("bed06_water", b)
b = buf(); place(b, metal(420, 4), 0, 1.0); knocks(b, 600, 1100, 4, 0.15, 0.3, 30, .5)
for i in range(2): place(b, np.sin(2*np.pi*1000*T(0.12))*np.minimum(1, T(0.12)*200), 0.6 + i*0.25, .35)   # monitor beeps
save("bed07_hospital", b)
b = buf(); place(b, burst(0.1, 1000, 6000, 40), 0, 1.3); knocks(b, 300, 800, 7); chime(b, [1568, 1976, 2349, 3136], 0.15, .45); save("bed08_royal", b)
b = buf(); place(b, metal(880, 3.5), 0, .8)
for _ in range(18): place(b, metal(R.uniform(2500, 4200), 18, 0.25), R.uniform(0.05, 0.9), R.uniform(.15, .4))   # coins
save("bed09_gold", b)
b = buf(); shatter(b, 3500, 7500, 40, 0, .5); chime(b, [2637, 3136, 3951], 0.1, .3); save("bed10_diamond", b, (1.4, 0.3))
b = buf(); shatter(b, 2000, 4500, 32, 0, .55, (1500, 9000)); place(b, ping(1318, 2.5, 1.5), 0.05, .5); save("bed11_emerald", b, (1.4, 0.3))
b = buf(); shatter(b, 1500, 3500, 28, 0, .55, (1000, 8000)); place(b, boom(45, 1.2, .6), 0.0); save("bed12_ruby", b, (1.4, 0.3))
b = buf(); place(b, burst(0.15, 1500, 9000, 25), 0, 1.4); place(b, sweep(2400, 600, 0.12)*np.exp(-T(0.12)*20), 0, .6)   # ice crack
for _ in range(20): place(b, ping(R.uniform(3000, 6500), 14, 0.4), 0.1 + R.exponential(0.2), R.uniform(.1, .35))
save("bed13_ice", b, (1.6, 0.35))
b = buf(); place(b, filt(noise(0.6), "low", 900, 4)*np.exp(-T(0.6)*6), 0, 2.0); place(b, boom(45, 1.0, .7), 0)  # rock crunch
place(b, hiss(1.6, 3000, 10000, 0.1, 1.6)*(0.6+0.4*np.abs(np.sin(2*np.pi*9*T(1.6)))), 0.1, .6); save("bed14_lava", b)
b = buf(); shatter(b, 2500, 6000, 36, 0, .45); chime(b, [1760, 2217, 2637, 3520], 0.05, .4, 0.05)
place(b, hiss(1.5, 6000, 12000, 0.2, 1.5), 0.1, .15); save("bed15_crystal", b, (1.8, 0.35))
b = buf(); shatter(b, 2000, 5000, 20, 0, .4)
bz = sweep(120, 120, 0.7, "sq")*(0.5+0.5*np.sign(np.sin(2*np.pi*23*T(0.7))))*np.exp(-T(0.7)*3); place(b, bz, 0, .5)
place(b, sweep(3000, 200, 0.25)*np.exp(-T(0.25)*8), 0.02, .5); save("bed16_neon", b)
b = buf(); place(b, metal(220, 2.5), 0, 1.0); place(b, metal(330, 3), 0.12, .7); knocks(b, 500, 900, 5, 0.2, 0.4, 25, .5)
place(b, sweep(900, 150, 0.9)*np.exp(-T(0.9)*1.5), 0.15, .35)
for _ in range(10): place(b, burst(0.02, 3000, 10000, 200), R.uniform(0.05, 0.6), .5)    # sparks
save("bed17_robot", b)
b = buf(); fm = np.sin(2*np.pi*np.cumsum(500 + 300*np.sin(2*np.pi*14*T(0.8)))/SR)*np.exp(-T(0.8)*3); place(b, fm, 0, .7)
goo = filt(noise(0.7), "low", 700, 2)*np.exp(-T(0.7)*5)*(1+np.sin(2*np.pi*7*T(0.7))); place(b, goo, 0.05, 1.3)
place(b, sweep(200, 1200, 0.5)*np.exp(-T(0.5)*4), 0.3, .35); save("bed18_alien", b)
b = buf(); place(b, filt(noise(1.2), "low", 500, 4)*np.exp(-T(1.2)*3), 0, 2.2); place(b, boom(35, 1.4, .6), 0)  # muffled crumble
knocks(b, 150, 300, 5, 0.1, 0.6, 18, .4); save("bed19_lunar", b, (2.0, 0.4))
b = buf(); place(b, hiss(1.2, 300, 5000, 0.25, 2.0), 0, 1.2); place(b, boom(40, 1.6, 1.0), 0.25)
place(b, filt(noise(1.0), "band", [80, 600])*np.exp(-T(1.0)*2.5), 0.25, 1.0); save("bed20_solar", b)
b = buf(); place(b, hiss(0.9, 1000, 9000, 0.3, 2.5), 0, .9); chime(b, [2093, 2637, 3136, 3951, 4186], 0.3, .35, 0.07)
place(b, boom(50, 1.2, .6), 0.3); save("bed21_galaxy", b, (2.0, 0.4))
b = buf(); place(b, hiss(1.4, 400, 4000, 0.4, 1.5), 0, 1.0); chime(b, [1318, 1661, 1976, 2637], 0.35, .35, 0.09)
place(b, ping(659, 1.8, 1.6), 0.35, .4); save("bed22_nebula", b, (2.2, 0.45))
b = buf(2.6); rev = hiss(1.0, 200, 6000, 0.9, 0.0)[::-1]*np.linspace(0, 1, int(SR*1.0))**2   # reverse suck-in
place(b, hiss(1.0, 200, 6000, 0.02, 0)*np.linspace(0, 1, int(SR*1.0))**3, 0, 1.0); place(b, sweep(80, 600, 0.9)*np.linspace(0, 1, int(SR*0.9))**2, 0, .4)
place(b, boom(30, 1.8, 1.4), 0.95); save("bed23_black_hole", b, (1.5, 0.3))
b = buf(); chime(b, [1046, 1568, 2093, 2637, 3136, 4186], 0, .35, 0.05); place(b, boom(45, 1.5, .8), 0.05)
place(b, hiss(1.5, 5000, 12000, 0.05, 1.8), 0, .25); save("bed24_cosmic", b, (2.2, 0.45))
b = buf(3.0)
for f in [523, 659, 784, 1046, 1318, 1568, 2093]: place(b, ping(f, 1.2, 2.5), 0.02*R.random(), .4)   # heavenly C major chord
place(b, boom(40, 1.8, 1.0), 0); place(b, hiss(2.0, 4000, 12000, 0.3, 1.5), 0, .25)
shatter(b, 3000, 7000, 20, 0.05, .25); save("bed25_infinity", b, (2.5, 0.5))
print(len([f for f in os.listdir(OUT) if f.endswith(".ogg")]))
