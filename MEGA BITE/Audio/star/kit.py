"""MEGA BITE UI sound set v3 (12 Nov 2026): Shop, Index and Settings. All code-made (no recordings, no AI audio).
Owner: "the shop and index and settings sfx should be better". Before: ONE click sample for every action + one open sound.
Research used: vault "Playbook notes - Sound and music" (UI vocabulary: one family, one key; tap dry and short; open = rising
whoosh; close = falling; confirm = two notes rising; toggle = two pitches; hover PC only; avoid harsh 2-5 kHz; -16..-18 LUFS),
K06 SFX recipe (transient + body + tail), and the owner's reference recording (Pets window 12.7-24 s: window open = airy
noise whoosh ~0.9 s + a rising chime arpeggio; tile taps = bright, harmonic-rich pops of ~90 ms; plain clicks are dry ticks).
Family: a "glass bubble" pluck (sine + soft FM + 2 partials, a 25 ms upward bloop on the attack) in C major pentatonic,
the key of the game's Bank / Buy / Size-up bells (C6 E6 G6).  48 kHz mono."""
import numpy as np, soundfile as sf, pyloudnorm as pyln, os, sys
from scipy import signal
from pedalboard import Pedalboard, HighpassFilter, LowpassFilter, Reverb, Limiter, Gain, HighShelfFilter, Compressor
SR=48000; rng=np.random.default_rng(12); OUT=sys.argv[1] if len(sys.argv)>1 else 'out'; os.makedirs(OUT,exist_ok=True)
def T(s): return int(round(s*SR))
def N(m): return 440.0*2**((m-69)/12)            # midi -> Hz   (C5=72, G5=79, C6=84, E6=88, G6=91)
C5,D5,E5,G5,A5,C6,D6,E6,G6,A6,C7=72,74,76,79,81,84,86,88,91,93,96
def tt(L): return np.arange(T(L))/SR
def pluck(midi,L=0.35,dec=0.09,bloop=0.22,fm=0.9,bright=1.0,att=0.002):
    """glass-bubble pluck: the pitch starts `bloop` below and rises in ~25 ms; a soft FM bell + 2nd and 4th partials"""
    t=tt(L); f0=N(midi); f=f0*(1-bloop*np.exp(-t/0.012)); ph=2*np.pi*np.cumsum(f)/SR
    mod=np.sin(ph*2.0)*fm*np.exp(-t/(dec*0.5))
    y=np.sin(ph+mod)*np.exp(-t/dec)
    y+=0.30*bright*np.sin(2*ph)*np.exp(-t/(dec*0.6))+0.12*bright*np.sin(4*ph+0.3)*np.exp(-t/(dec*0.35))
    a=np.minimum(t/att,1.0); return (y*a).astype(np.float32)
def tick(L=0.03,lo=2500,hi=7500,dec=0.004):
    """the transient: a few ms of band-passed noise"""
    t=tt(L); n=rng.standard_normal(len(t))*np.exp(-t/dec)
    sos=signal.butter(2,[lo,hi],'bp',fs=SR,output='sos'); return signal.sosfilt(sos,n).astype(np.float32)
def thup(f0=210,f1=120,L=0.06,dec=0.018):
    t=tt(L); f=f1+(f0-f1)*np.exp(-t/0.012); return (np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-t/dec)).astype(np.float32)
def swish(L,f_a,f_b,f_c=None,peak=0.5,q=1.4,flutter=0.0,air=0.5):
    """airy whoosh: noise through a band-pass whose centre moves f_a -> f_b (-> f_c); bell-shaped loudness peaking at `peak`"""
    n=T(L); t=np.arange(n)/SR; x=t/L
    if f_c is None: fc=f_a*(f_b/f_a)**x
    else: fc=np.where(x<peak,f_a*(f_b/f_a)**(x/peak),f_b*(f_c/f_b)**((x-peak)/(1-peak)))
    noise=rng.standard_normal(n).astype(np.float32); y=np.zeros(n,np.float32); B=256
    zi=None
    for i in range(0,n,B):      # time-varying band-pass, block by block with carried state
        c=float(fc[min(i+B//2,n-1)]); lo=max(60,c/q); hi=min(SR/2-200,c*q)
        sos=signal.butter(2,[lo,hi],'bp',fs=SR,output='sos')
        if zi is None: zi=signal.sosfilt_zi(sos)*0
        y[i:i+B],zi=signal.sosfilt(sos,noise[i:i+B],zi=zi)
    env=np.exp(-0.5*((x-peak)/0.26)**2)*np.minimum(x/0.08,1)*np.minimum((1-x)/0.15,1)
    if flutter: env*=1-flutter*0.5*(1+np.sin(2*np.pi*34*t))
    y=y*env; y/=np.abs(y).max()+1e-9
    return (y*(0.6+0.4*air)).astype(np.float32)
def sparkle(L=0.45,n=14,lo=3800,hi=8200,dec=0.05,seed=1):
    r=np.random.default_rng(seed); y=np.zeros(T(L),np.float32)
    for k in range(n):
        at=r.uniform(0,L*0.7); f=r.uniform(lo,hi); g=r.uniform(0.3,1.0)*(1-at/L)
        t=tt(min(0.14,L-at)); s=np.sin(2*np.pi*f*t)*np.exp(-t/dec)*np.minimum(t/0.002,1)*g
        i=T(at); y[i:i+len(s)]+=s
    return y/ (np.abs(y).max()+1e-9)
def bubble(f0=700,f1=1500,L=0.07,dec=0.03):
    t=tt(L); f=f0*(f1/f0)**(t/L); return (np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-t/dec)*np.minimum(t/0.003,1)).astype(np.float32)
def mix(L,*parts):
    y=np.zeros(T(L),np.float32)
    for x,at,g in parts:
        i=T(at); n=min(len(x),len(y)-i)
        if n>0:
            p=x[:n].copy(); k=min(n//2,T(0.008)); p[-k:]*=np.linspace(1,0,k)**2      # every layer ends on a short fade: no click where it is cut
            y[i:i+n]+=g*p
    return y
def master(x,lufs=-18.0,hp=180,lp=11000,verb=0.06,room=0.18,shelf=0.0,tail=0.08,ceil=-1.5,peak=None):
    fx=[HighpassFilter(hp),LowpassFilter(lp)]
    if shelf: fx.append(HighShelfFilter(cutoff_frequency_hz=5000,gain_db=shelf))
    if verb: fx.append(Reverb(room_size=room,damping=0.7,wet_level=verb,dry_level=1.0,width=0.0))
    y=Pedalboard(fx)(np.concatenate([x,np.zeros(T(tail),np.float32)])[None,:],SR)[0]
    y=y-np.mean(y)
    m=pyln.Meter(SR,block_size=min(0.1,len(y)/SR*0.45)); l=m.integrated_loudness(y)
    if np.isfinite(l): y=y*10**((lufs-l)/20)
    pk=np.abs(y).max()
    if pk>10**(ceil/20): y=np.tanh(y/pk*1.2)/np.tanh(1.2)*10**(ceil/20)      # soft ceiling
    if peak is not None: y=y/(np.abs(y).max()+1e-9)*10**(peak/20)      # very short sounds: loudness meters are unreliable, match the peak instead
    a=T(0.0015); b=min(len(y)//2,T(0.03)); y[:a]*=np.linspace(0,1,a); y[-b:]*=np.linspace(1,0,b)**2
    # trim the silent end
    e=np.nonzero(np.abs(y)>10**(-60/20))[0]; y=y[:min(len(y),e[-1]+T(0.02))] if len(e) else y
    return y.astype(np.float32)
def out(name,y,**k):
    y=master(y,**k); sf.write(f'{OUT}/{name}.wav',y,SR,subtype='PCM_24'); return y

