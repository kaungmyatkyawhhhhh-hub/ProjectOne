"""MEGA BITE Reef Shark sound set v2 (HIGH QUALITY): real CC0 recordings from Freesound, sliced, layered with small
code-made sweeteners, then a pro chain (high-pass, compressor, light saturation, EQ, short dark reverb, limiter,
loudness). 48 kHz / 24-bit WAV. Sources: MEGA BITE/Audio/freesound_cc0 (all CC0 1.0, list in the sound note)."""
import numpy as np, soundfile as sf, pyloudnorm as pyln, os
from pedalboard import Pedalboard, HighpassFilter, LowpassFilter, Compressor, Distortion, Reverb, Limiter, PitchShift, HighShelfFilter, PeakFilter, Gain
SR=48000; rng=np.random.default_rng(3); OUT='set_hq'; os.makedirs(OUT,exist_ok=True)
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
# ---- source slices
jaw=sorted(slices(load('orig_830093__wigglesworth__jaw-or-teeth-bite-at-air')),key=lambda s:-np.abs(s).max())
crunch=slices(load('orig_392883__clif_creates__hard-candy-bone-crunch'))+slices(load('orig_382650__bbrocer__chomp-chew-bite'))
crunch=sorted(crunch,key=lambda s:-np.abs(s).max())
cartoon=load('orig_353067__jofae__bite-cartoon-style')
bub=sorted(slices(load('fs_59978'),12,0.3)+slices(load('fs_16740'),10,0.3),key=lambda s:-np.abs(s).max())
bubble1=load('fs_235264')
print('slices: jaw',len(jaw),'crunch',len(crunch),'bubbles',len(bub))
def bubbletail(k,n=3,spread=0.25,g=0.5):
    parts=[(peaknorm(fades(bub[(k*3+i)%len(bub)]),-6),0.03+i*spread/n+rng.uniform(0,0.04),g*rng.uniform(0.5,1)) for i in range(n)]
    return Pedalboard([LowpassFilter(3800),HighpassFilter(250)])(mixat(0.6,*parts)[None,:],SR)[0]
def sub(f0=110,f1=48,L=0.14):
    t=np.arange(T(L))/SR; f=f1+(f0-f1)*np.exp(-t*30); return (np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-t*22)).astype(np.float32)
# ---- BITE x3: jaw snap (identity) + real crunch + cartoon body (pitched down) + sub thump + bubble tail
for k in range(3):
    snap=peaknorm(fades(jaw[k]),-3); cr=peaknorm(fades(crunch[k+1]),-6); body=peaknorm(pitch(fades(cartoon),-3-k),-8)
    y=mixat(0.75,(snap,0,1.0),(cr,0.006,0.8),(body,0.0,0.55),(sub(),0.0,0.18),(bubbletail(k),0.08,0.35))
    save(f'Bite_Chomp_{k+1}',master(y,-14,hp=85,sat=4,verb=0.08,mid=(3000,4.0)))
# ---- GULP x3: real cartoon gulp + water gulp, pitched for variety, bubbles
gulp=slices(load('fs_450624'),10,0.5); wg=load('fs_56271')
for k in range(3):
    g=peaknorm(pitch(fades(gulp[k%len(gulp)]),[0,2,-2][k]),-3)
    y=mixat(0.8,(g,0,1.0),(peaknorm(pitch(wg,[1,3,-1][k]),-9),0.03,0.5),(bubbletail(k+5,2,0.2),0.15,0.35))
    save(f'Gulp_{k+1}',master(y,-15,hp=140,sat=2,verb=0.07,shelf=1,mid=(1800,3.0)))
# ---- DART x2: real whooshes (fast) + water swish + bubble burst, underwater tilt
wq=load('fs_60013'); w2=load('fs_683101'); w3=load('fs_169867'); sw=slices(load('fs_321489'),10,0.3)
for k in range(2):
    a=peaknorm(fades(pitch(wq,-2+k)),-3); b=peaknorm(fades((w2 if k==0 else w3)[:T(0.6)]),-6); c=peaknorm(fades(sw[k]),-6)
    y=mixat(0.95,(a,0,1.0),(b,0.02,0.6),(c,0.05,0.7),(bubbletail(k+9,5,0.35),0.15,0.45))
    save(f'Dart_Whoosh_{k+1}',master(y,-14,hp=80,lp=9000,sat=2,verb=0.10,room=0.2))
# ---- SWIM swish x3: soft real water swishes
for k in range(3):
    s=peaknorm(fades(sw[(k+1)%len(sw)],0.01,0.08),-6)
    save(f'Swim_Swish_{k+1}',master(mixat(0.5,(s,0,1.0)),-22,hp=120,lp=6000,sat=0,verb=0.06,shelf=0))
# ---- HURT x3: real cartoon bonks + a code boing wobble + bubble burst
bonks=[load('fs_466202'),load('fs_458572'),load('fs_573047')]
def boing(f=320,L=0.35):
    t=np.arange(T(L))/SR; return (np.sin(2*np.pi*np.cumsum(f*(1+0.07*np.sin(2*np.pi*14*t)))/SR)*np.exp(-t*9)).astype(np.float32)
for k in range(3):
    bk=bonks[k]; s=slices(bk,10,0.5); bk=s[0] if s else bk[:T(0.5)]
    y=mixat(0.8,(peaknorm(fades(bk),-3),0,1.0),(boing(300+25*k)*0.5,0.01,0.6),(bubbletail(k+12,5,0.3),0.04,0.5))
    save(f'Hurt_Bonk_{k+1}',master(y,-14,hp=70,sat=2,verb=0.08))
# ---- SHARK SENSE: rich FM bell ping (E6) + echoes + shimmer + soft reversed water swell, big dark reverb (signature)
t=np.arange(T(1.8))/SR
def bell(at,amp,f=1318.5,dec=0.5):
    m=t>=at; tt=t[m]-at; y=np.zeros_like(t)
    mod=2.0*np.exp(-tt*6)*np.sin(2*np.pi*f*1.4*tt)
    y[m]=amp*np.sin(2*np.pi*f*tt+mod)*np.exp(-tt/dec)*np.minimum(tt/0.002,1); return y
pg=bell(0,1)+0.5*bell(0,1,f=1318.5*2.0,dec=0.25)+bell(0.3,0.42)+bell(0.6,0.18)
for k in range(10):
    at=rng.uniform(0.04,0.8); pg+=bell(at,0.07,f=rng.choice([2637,3136,3951,5274]),dec=0.12)
sw_rev=peaknorm(fades(w3[:T(0.7)])[::-1],-12)
y=mixat(1.8,(pg.astype(np.float32)*0.6,0.15,1.0),(sw_rev,0,0.5))
save('Sense_Ping',master(y,-15,hp=200,sat=0,verb=0.3,room=0.6,shelf=0,tail=0.2))
# ---- IDLE bubbles x3: real bubble clusters, quiet
for k in range(3): save(f'Idle_Bubbles_{k+1}',master(bubbletail(k+20,4,0.6,1.0),-24,hp=200,lp=5000,sat=0,verb=0.08))
# ---- AMBIENCE (preview only): real underwater room tone
amb=load('fs_173439'); amb=np.concatenate([amb]*3)[:T(12)]
save('_Ambience',master(amb,-30,hp=40,lp=2500,sat=0,verb=0,shelf=0))
print('done')
