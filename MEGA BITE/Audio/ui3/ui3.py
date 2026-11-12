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

# 1 CLICK (every small button): a dry bubble pop. 3 takes a tone apart so repeats never machine-gun.
for i,m in enumerate([C6,D6,E6]):
    out(f'UI_Click_{i+1}',mix(0.14,(tick(0.02,3000,9000,0.003),0,0.6),(pluck(m,0.12,0.03,0.34,0.6,1.6),0.001,1.0),(thup(230,150,0.04,0.012),0,0.3)),lufs=-19,verb=0.03,hp=200,shelf=2.0,peak=-4.0)
# 2 SELECT (tap a skin / pass / fish: the 3D card spins 0.5 s): pop -> the card's whoosh, loudest as it turns edge-on -> a soft landing chime
sel=mix(0.95,(tick(0.02),0,0.3),(pluck(E6,0.12,0.03,0.34,0.5),0.001,0.9),(swish(0.46,500,3600,800,peak=0.5,q=1.5),0.03,0.55),
        (pluck(G6,0.4,0.11,0.12,0.8),0.47,0.62),(pluck(C7,0.3,0.09,0.1,0.6),0.50,0.28),(sparkle(0.3,6,4500,8000,0.04,3),0.48,0.10))
out('UI_Select',sel,lufs=-19,verb=0.08,room=0.25)
# 3 TAB (Featured / Skins / Passes): one crisp note; the code raises the pitch per tab
out('UI_Tab',mix(0.2,(tick(0.015,3500,8500,0.0025),0,0.3),(pluck(C6,0.16,0.045,0.18,0.7,1.1),0.001,1.0),(swish(0.09,1800,4200,peak=0.4,q=1.3),0.0,0.18)),lufs=-19,verb=0.04)
# 4 OPEN SHOP: an up-whoosh into a rising G-C-E-G run, sparkle on top, one bubble underneath. The exciting one.
arp=[(G5,0.13),(C6,0.19),(E6,0.25),(G6,0.31)]
osh=mix(1.15,(swish(0.34,350,5200,peak=0.72,q=1.6),0,0.60),(thup(200,110,0.07,0.02),0.02,0.5),
        *[(pluck(m,0.5,0.13+0.02*k,0.16,0.9),at,0.55+0.1*k) for k,(m,at) in enumerate(arp)],
        (sparkle(0.5,16,4200,8600,0.05,5),0.30,0.16),(bubble(600,1500,0.08),0.08,0.22))
out('UI_Open_Shop',osh,lufs=-17,verb=0.12,room=0.3,shelf=1.0)
# 5 OPEN INDEX: a page turning (fluttering swish) and two calm wooden notes A-E. The curious one.
oix=mix(0.8,(swish(0.22,1400,5200,2200,peak=0.45,q=1.5,flutter=0.7),0,0.6),(thup(190,120,0.05,0.016),0.0,0.35),
        (pluck(A5,0.4,0.10,0.10,0.4,1.0),0.10,0.85),(pluck(E6,0.45,0.13,0.10,0.4,1.0),0.19,0.85),(bubble(800,1700,0.06),0.26,0.15))
out('UI_Open_Index',oix,lufs=-18,verb=0.08,room=0.22)
# 6 OPEN SETTINGS: a small dry pop and two muted ticks G-D. The quiet one.
ose=mix(0.5,(swish(0.14,900,3000,peak=0.5,q=1.3),0,0.30),(tick(0.015),0.0,0.3),(pluck(G5,0.14,0.035,0.2,0.35,1.0),0.001,0.9),
        (pluck(D6,0.2,0.05,0.14,0.35,1.0),0.085,0.85))
out('UI_Open_Settings',ose,lufs=-19,verb=0.04)
# 7 CLOSE (all three): the mirror of an open: two notes falling C-G under a falling whoosh
ucl=mix(0.5,(swish(0.22,4200,500,peak=0.3,q=1.5),0,0.5),(pluck(C6,0.16,0.045,0.10,0.5,1.1),0.0,0.8),(pluck(G5,0.25,0.07,0.08,0.5,1.1),0.075,0.8))
out('UI_Close',ucl,lufs=-19.5,verb=0.05)
# 8 EQUIP (confirm): a soft "thup", then C-G rising (a fifth) with a little shimmer and a bubble rising under it
ueq=mix(0.9,(thup(240,120,0.07,0.022),0,0.7),(tick(0.02),0,0.25),(pluck(C6,0.3,0.08,0.2,0.8),0.002,0.85),(pluck(G6,0.55,0.16,0.14,0.9),0.085,0.95),
        (pluck(C7,0.4,0.12,0.1,0.6),0.10,0.25),(sparkle(0.4,10,4200,8200,0.05,9),0.10,0.14),(bubble(500,1900,0.12,0.06),0.02,0.20))
out('UI_Equip',ueq,lufs=-17,verb=0.12,room=0.28,shelf=1.0)
# 9 SWITCH (a Settings choice): a pill snapping into place; the code plays it higher for options further right
out('UI_Switch',mix(0.18,(tick(0.012,4000,9000,0.002),0,0.4),(thup(260,170,0.035,0.01),0,0.45),(pluck(E6,0.13,0.035,0.26,0.4,0.9),0.004,1.0)),lufs=-19,verb=0.03,peak=-4.5)
# 10 SWIPE (banner arrows): a quick swish with a tiny pop
out('UI_Swipe',mix(0.26,(swish(0.17,900,4200,1500,peak=0.45,q=1.4),0,0.7),(pluck(D6,0.1,0.025,0.3,0.4),0.02,0.45)),lufs=-20,verb=0.04)
# 11 HOVER (mouse only): barely there
out('UI_Hover',mix(0.08,(pluck(A6,0.06,0.012,0.12,0.2,0.5),0,1.0),(tick(0.008,5000,9000,0.0015),0,0.15)),lufs=-26,verb=0.0,ceil=-9)
print('done')
