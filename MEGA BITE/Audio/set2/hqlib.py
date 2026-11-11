"""MEGA BITE Reef Shark sound set v2 (HIGH QUALITY): real CC0 recordings from Freesound, sliced, layered with small
code-made sweeteners, then a pro chain (high-pass, compressor, light saturation, EQ, short dark reverb, limiter,
loudness). 48 kHz / 24-bit WAV. Sources: MEGA BITE/Audio/freesound_cc0 (all CC0 1.0, list in the sound note)."""
import numpy as np, soundfile as sf, pyloudnorm as pyln, os
from pedalboard import Pedalboard, HighpassFilter, LowpassFilter, Compressor, Distortion, Reverb, Limiter, PitchShift, HighShelfFilter, PeakFilter, Gain
SR=48000; rng=np.random.default_rng(3); OUT='set2'; os.makedirs(OUT,exist_ok=True)
def load(n): x,sr=sf.read(f'src/{n}.wav'); return x.astype(np.float32)
def T(s): return int(s*SR)
def env_db(x,hop=0.005):
    h=T(hop); return np.array([np.sqrt(np.mean(x[i:i+h]**2))+1e-9 for i in range(0,max(1,len(x)-h),h)])
def slices(x, thresh_db=16, maxlen=0.45, pre=0.008):
    """cut a recording into single events (onset to decay)"""
    e=20*np.log10(env_db(x)); h=T(0.005); floor=np.percentile(e,15); out=[]; i=6
    while i<len(e):
        if e[i]-e[max(0,i-6):i].min()>thresh_db and e[i]>floor+22:
            j=i+1; pk=e[i]
            while j<len(e) and (j-i)*0.005<maxlen:
                pk=max(pk,e[j])
                if e[j]<pk-38: break
                j+=1
            s=x[max(0,i*h-T(pre)):j*h]; out.append(s); i=j+4
        else: i+=1
    return out
def fit(x,length):
    y=np.zeros(T(length),np.float32); n=min(len(x),len(y)); y[:n]=x[:n]; return y
def fades(x,fi=0.002,fo=0.04):
    x=x.copy(); a=max(1,T(fi)); b=min(len(x)//2,T(fo)); x[:a]*=np.linspace(0,1,a); x[-b:]*=np.linspace(1,0,b)**2; return x
def peaknorm(x,db=-3): p=np.abs(x).max()+1e-9; return x*(10**(db/20)/p)
def pitch(x,semi): return Pedalboard([PitchShift(semitones=semi)])(x[None,:],SR)[0] if semi else x
def mixat(L,*parts):
    y=np.zeros(T(L),np.float32)
    for x,at,g in parts:
        i=T(at); n=min(len(x),len(y)-i); y[i:i+n]+=g*x[:n]
    return y
def master(x,lufs=-14.0,hp=60,lp=None,sat=3.0,verb=0.10,room=0.12,shelf=1.5,mid=None,tail=0.06):
    fx=[HighpassFilter(hp),Compressor(threshold_db=-20,ratio=3.5,attack_ms=2,release_ms=80)]
    if sat: fx.append(Distortion(drive_db=sat))
    if mid: fx.append(PeakFilter(cutoff_frequency_hz=mid[0],gain_db=mid[1],q=1.0))
    fx.append(HighShelfFilter(cutoff_frequency_hz=4500,gain_db=shelf))
    if lp: fx.append(LowpassFilter(lp))
    if verb: fx.append(Reverb(room_size=room,damping=0.8,wet_level=verb,dry_level=1.0,width=0.0))
    y=Pedalboard(fx)(np.concatenate([x,np.zeros(T(tail),np.float32)])[None,:],SR)[0]
    y=y-np.mean(y); m=pyln.Meter(SR,block_size=min(0.1,len(y)/SR*0.5)); l=m.integrated_loudness(y)
    if np.isfinite(l): y=pyln.normalize.loudness(y,l,lufs)
    pk=20*np.log10(np.abs(y).max()+1e-9)
    if pk>-1.0:   # JUCE limiter adds make-up gain to 0 dBFS: limit the overshoot only, then set the ceiling to -1 dBFS
        y=Pedalboard([Gain(-(pk+1.0)),Limiter(threshold_db=-(pk+1.0),release_ms=40)])(y[None,:].astype(np.float32),SR)[0]
        y=y*(10**(-1.0/20)/(np.abs(y).max()+1e-9))
    return fades(y.astype(np.float32),0.0015,0.05)
def save(name,y): sf.write(f'{OUT}/{name}.wav',y,SR,subtype='PCM_24'); return y
