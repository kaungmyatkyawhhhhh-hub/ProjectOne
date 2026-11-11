"""MEGA BITE Reef Shark sound set, made in code (owner 9 Nov: "the codemade are better").
Every sound: layered (transient / body / tail), identity in 1-5 kHz for phone speakers, underwater low-pass on world
layers, levelled by LUFS, 48 kHz mono WAV. Variants for high-repeat sounds."""
import numpy as np, soundfile as sf, os
exec(open('synth.py').read().split("for k in range(3):")[0])   # reuse helpers + chomp()
OUT='set'; os.makedirs(OUT,exist_ok=True)
def sweep_noise(dur, f_path, q=1.6, seed=0):
    """noise through a band-pass whose centre follows f_path(t) (block-wise)"""
    r=np.random.default_rng(seed); n=T(dur); x=r.standard_normal(n); out=np.zeros(n); B=T(0.01)
    for i in range(0,n,B):
        t=i/SR; fc=f_path(t); lo=max(40,fc/q); hi=min(SR/2-100,fc*q)
        seg=x[max(0,i-T(0.02)):i+B]; y=bp(seg,lo,hi,2)[-min(B,n-i):]; out[i:i+len(y)]=y
    return out
def save(name,y,lufs):
    y=fade(norm(y,lufs),0.003,0.08); sf.write(f'{OUT}/{name}.wav',y.astype(np.float32),SR); return y
S={}
# BITE (chomp) x3 - from synth.py, the version the owner picked
for k in range(3): S[f'Bite_Chomp_{k+1}']=save(f'Bite_Chomp_{k+1}',chomp(11+k,1.0+0.06*(k-1)),-15)
# GULP x3 - funny cartoon swallow when food is eaten: a resonant "glunk" (down-up sweep) + pop + bubbles
for k in range(3):
    r=np.random.default_rng(40+k); n=T(0.22); t=np.arange(n)/SR
    f=np.interp(t,[0,0.08,0.22],[700+40*k,260,430+30*k]); g=np.sin(2*np.pi*np.cumsum(f)/SR)
    g+=0.35*np.sin(2*np.pi*np.cumsum(2*f)/SR); g*=env(n,0.006,0.12)
    pop=bp(r.standard_normal(T(0.01)),1500,5000)*env(T(0.01),0.0005,0.003)
    out=np.zeros(T(0.5)); place(out,0.5*pop,0); place(out,g,0.004); place(out,lp(bubbles(0.3,5,700,1500,50+k),4000)*0.3,0.12)
    S[f'Gulp_{k+1}']=save(f'Gulp_{k+1}',out,-16)
# DART whoosh x2 - a fast water rush: swept noise up then down, + bubble trail
for k in range(2):
    dur=0.6; fp=lambda t: 350+2200*np.exp(-((t-0.16)/0.09)**2)+300*t
    w=sweep_noise(dur,fp,1.5,60+k)*env(T(dur),0.07,0.25)
    out=np.zeros(T(0.8)); place(out,lp(w,6000),0); place(out,lp(bubbles(0.45,10,600,1600,70+k),4500)*0.35,0.18)
    S[f'Dart_Whoosh_{k+1}']=save(f'Dart_Whoosh_{k+1}',out,-15)
# SWIM swish x3 - soft tail swish (plays each tail half-beat, low volume in game)
for k in range(3):
    dur=0.35; fp=lambda t,k=k: 420+500*np.sin(np.pi*min(t/0.35,1))+40*k
    w=sweep_noise(dur,fp,1.4,80+k)*env(T(dur),0.08,0.12)
    S[f'Swim_Swish_{k+1}']=save(f'Swim_Swish_{k+1}',lp(w,3500),-22)
# SHARK SENSE - magical sonar: bright ping (E6) with a small upward glide, 2 echoes, a shimmer; signature sound
n=T(1.6); t=np.arange(n)/SR
def ping(at,amp,dec):
    m=t>=at; tt=t[m]-at; f=1318.5*(1+0.02*np.minimum(tt/0.05,1))
    s=np.zeros(n); ph=2*np.pi*np.cumsum(f)/SR
    s[m]=amp*(np.sin(ph)+0.25*np.sin(2*ph)+0.1*np.sin(3.01*ph))*np.exp(-tt/dec)*np.minimum(tt/0.003,1); return s
sense=ping(0.0,1,0.35)+ping(0.28,0.45,0.3)+ping(0.56,0.2,0.3)
sh=np.zeros(n); r=np.random.default_rng(90)
for k in range(14):
    at=r.uniform(0.05,0.9); L=0.12; m=T(L); tt=np.arange(m)/SR; fr=r.choice([2637,3136,3520,3951])
    place(sh,0.12*np.sin(2*np.pi*fr*tt)*np.sin(np.pi*tt/L)**2,at)
sense=sense+sh+0.25*lp(sweep_noise(1.0,lambda t:600+1500*t,1.3,91)*env(T(1.0),0.3,0.4),3000).tolist()+[0]*0 if False else sense+sh
S['Sense_Ping']=save('Sense_Ping',sense,-15)
# HURT bonk x3 - cartoon thud + boing wobble + a burst of bubbles (no pain, no gore)
for k in range(3):
    r=np.random.default_rng(100+k); n=T(0.45); t=np.arange(n)/SR
    thud=np.sin(2*np.pi*np.cumsum(260*np.exp(-t*14)+90)/SR)*env(n,0.001,0.09)
    boing=np.sin(2*np.pi*np.cumsum((330+20*k)*(1+0.06*np.sin(2*np.pi*13*t)))/SR)*env(n,0.01,0.28)*0.45
    hit=bp(r.standard_normal(T(0.02)),900,4000)*env(T(0.02),0.0005,0.006)
    out=np.zeros(T(0.7)); place(out,0.6*hit,0); place(out,thud+boing,0.002); place(out,lp(bubbles(0.4,12,500,1400,110+k),4000)*0.4,0.05)
    S[f'Hurt_Bonk_{k+1}']=save(f'Hurt_Bonk_{k+1}',out,-15)
# IDLE bubbles x3 - a few lazy bloops from the gills
for k in range(3):
    S[f'Idle_Bubbles_{k+1}']=save(f'Idle_Bubbles_{k+1}',lp(bubbles(0.8,4,450,900,120+k),3500),-24)
# AMBIENCE (for the preview only): soft underwater room tone
amb=lp(np.random.default_rng(5).standard_normal(T(12)),500)*0.5+lp(bubbles(12,25,400,1000,6),3000)*0.15
S['_Ambience']=save('_Ambience',amb,-30)
for k,v in S.items(): print(k, round(len(v)/SR,2),'s')
