"""MEGA BITE ability sounds v3 (12 Nov 2026): FRENZY, TORPEDO, HAMMER RAM, BREACH, TIDAL ROAR. All code-made.
Owner 12:46: "rework the ability sounds except for reef shark".
Before: set 2 (10 Nov) = CC0 recordings glued together, each started at ONE marker in the middle of its clip (Frenzy's 5 recorded
chomps started at the clip's THIRD chomp, on top of a Bite and a Gulp sound), so nothing lined up with the animation or the VFX.
Now: ONE sound per ability, written on the clip's own timeline and started at the clip's first frame ("...In" marker, 0.01 s):
wind-up (a riser that peaks exactly on the hit) -> the hit (crack >2 kHz + body + falling sub) -> a short dark tail.
Times below are seconds into the CLIP, read from the Blender clips and BonePlayer.Markers; OFF = 0.01 (the In marker).
Rules: K06 SFX recipe; phones: identity in 1-5 kHz; about -13.5 LUFS, peaks under -1 dB; underwater = low-passed tail; kid-safe."""
import numpy as np, soundfile as sf, sys, os
from scipy import signal
from pedalboard import Pedalboard, Reverb, LowpassFilter, HighpassFilter, Compressor
import pyloudnorm as pyln
SR=48000; OFF=0.01; OUT='out'; os.makedirs(OUT,exist_ok=True)
rng=np.random.default_rng(31)
def t_(d): return np.arange(int(SR*d))/SR
def noise(n): return rng.standard_normal(n)
def place(buf,x,at,g=1.0):
    i=int(round(at*SR))
    if i<0: x=x[-i:]; i=0
    j=min(len(buf),i+len(x))
    if j>i:
        p=np.array(x[:j-i],dtype=float); k=min(len(p)//2,int(0.012*SR)); p[-k:]*=np.linspace(1,0,k)**2     # every layer ends on a short fade: a cut makes its own click
        buf[i:j]+=g*p
def bp(x,lo,hi,o=2): return signal.sosfilt(signal.butter(o,[lo,hi],'bp',fs=SR,output='sos'),x)
def lp(x,f,o=2): return signal.sosfilt(signal.butter(o,f,'lp',fs=SR,output='sos'),x)
def hp(x,f,o=2): return signal.sosfilt(signal.butter(o,f,'hp',fs=SR,output='sos'),x)
def dec(d,tau,att=0.001):
    t=t_(d); return np.exp(-t/tau)*np.minimum(t/att,1)
def ramp(d,p=2.0,tail=0.012):
    """0 -> 1 riser envelope with a short release so it stops cleanly ON the hit"""
    t=t_(d); return (t/d)**p*np.minimum((d-t)/tail,1)
def sweep(d,f0,f1,curve=2.0,q=0.35):
    """band of noise whose centre glides f0 -> f1 (STFT mask: no block clicks)"""
    n=int(d*SR); x=noise(n+2048)
    f,tt,Z=signal.stft(x,SR,nperseg=1024,noverlap=768)
    u=np.clip(tt/d,0,1)**curve; fc=f0*(f1/f0)**u
    M=np.exp(-0.5*((f[:,None]-fc[None,:])/np.maximum(fc*q,60)[None,:])**2)
    _,y=signal.istft(Z*M,SR,nperseg=1024,noverlap=768); y=y[:n]
    return y/(np.abs(y).max()+1e-9)
def glide(d,f0,f1,curve=1.0):
    t=t_(d); f=f0*(f1/f0)**((t/d)**curve); return np.sin(2*np.pi*np.cumsum(f)/SR)
def subdrop(d,f0,f1,tau_f,tau_a):
    t=t_(d); f=(f0-f1)*np.exp(-t/tau_f)+f1; return np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-t/tau_a)*np.minimum(t/0.004,1)
def bubbles(d,count,fmin=400,fmax=1800,lmin=0.03,lmax=0.09):
    n=int(d*SR); out=np.zeros(n)
    for _ in range(count):
        st=rng.uniform(0,d*0.95); f0=rng.uniform(fmin,fmax); L=rng.uniform(lmin,lmax)
        tt=t_(L); f=f0*(1+tt/L*1.2)      # a bubble chirps UP as it shrinks
        b=np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-tt/(L*0.35))*np.clip(tt/0.003,0,1)*np.clip((L-tt)/0.015,0,1)*rng.uniform(0.3,1)
        place(out,b,st)
    return out
def saws(f0,dets):
    y=np.zeros(len(f0))
    for d,a in dets: y+=signal.sawtooth(2*np.pi*np.cumsum(f0*d)/SR)*a
    return y
def clack(p=1.0,gap=0.012,tok=1900):
    """teeth: two tiny clicks a few ms apart + a short knock tone (the part a phone speaker carries)"""
    y=np.zeros(int(0.08*SR))
    for k,at in enumerate([0,gap]): place(y,hp(noise(int(0.012*SR)),2600)*dec(0.012,0.0016),at,1.0-0.25*k)
    place(y,np.sin(2*np.pi*tok*p*t_(0.05))*dec(0.05,0.009),0.0005,0.55)
    place(y,np.sin(2*np.pi*tok*p*1.52*t_(0.03))*dec(0.03,0.005),0.0005,0.22)
    return y
def finish(x,name,lufs=-13.5,lpf=None,verb=0.12,room=0.4,ceil=0.86):
    x=x/(np.abs(x).max()+1e-9)*0.95
    fx=[]
    if lpf: fx.append(LowpassFilter(lpf))
    if verb>0: fx.append(Reverb(room_size=room,damping=0.6,wet_level=verb,dry_level=1.0,width=0.0))
    fx+=[HighpassFilter(28),Compressor(threshold_db=-14,ratio=3,attack_ms=5,release_ms=120)]
    y=Pedalboard(fx)(x.astype(np.float32)[None,:],SR)[0].astype(np.float64)
    m=pyln.Meter(SR); thr=0.62*ceil
    for _ in range(4):                                             # level to the target, round off only what pokes above the ceiling, repeat
        y=y*10**((lufs-m.integrated_loudness(y))/20)
        a=np.abs(y); over=a>thr
        y=np.where(over,np.sign(y)*(thr+(ceil-thr)*np.tanh((a-thr)/(ceil-thr))),y)
    tp=np.abs(signal.resample_poly(y,4,1)).max()                  # true peak (between the samples) stays under -1 dB
    if tp>0.885: y*=0.885/tp
    fi=int(0.003*SR); fo=int(0.08*SR); y[:fi]*=np.linspace(0,1,fi); y[-fo:]*=np.linspace(1,0,fo)**2
    sf.write(f'{OUT}/{name}.wav',y,SR,subtype='PCM_24')
    return y

