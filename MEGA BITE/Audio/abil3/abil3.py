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
SR=48000; OFF=0.01; OUT=sys.argv[1] if len(sys.argv)>1 else 'abil'; os.makedirs(OUT,exist_ok=True)
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

# ================= FRENZY (Piranha, 1.0 s clip): three lunges, each ending in a chomp at 0.10 / 0.43 / 0.77 =================
N=int(1.4*SR); mix=np.zeros(N); CH=[0.10,0.43,0.77]
for k,c in enumerate(CH):
    c-=OFF; p=2**(2*k/12); g=[0.72,0.86,1.0][k]            # each chomp a tone higher and louder: the frenzy builds
    d=min(0.10,c); place(mix,sweep(d,650,3600*p,curve=1.8,q=0.4)*ramp(d,1.6),c-d,0.42*g)        # the lunge: a swish that ends ON the bite
    place(mix,clack(p),c,0.95*g)
    place(mix,bp(noise(int(0.09*SR)),480*p,1800*p)*dec(0.09,0.022),c,1.25*g)                   # the crunch
    place(mix,subdrop(0.12,175,92,0.02,0.035),c,0.6*g)                                         # the weight of the jaw
    place(mix,bubbles(0.14,7,900,2700),c+0.02,0.22*g)                                          # a wet pop of bubbles after each bite
t=t_(0.78); f0=np.interp(t,[0,0.76],[150,236]); buzz=bp(saws(f0,[(1,1),(1.012,0.7)])*(1+0.8*np.sin(2*np.pi*23*t)),300,1500)
place(mix,buzz*np.minimum(t/0.76,1)**1.3*np.minimum((0.78-t)/0.03,1),0,0.085)                  # an excited buzz that climbs under it
c=CH[2]-OFF
for f,a in [(2637,1.0),(3520,0.7),(4186,0.4)]: place(mix,np.sin(2*np.pi*f*t_(0.3))*dec(0.3,0.07),c+0.004,0.06*a)   # the last bite glints
place(mix,subdrop(0.2,150,70,0.04,0.07),c,0.35)
place(mix,bubbles(0.55,48,700,3000)*np.linspace(1,0,int(0.55*SR))**1.3,c+0.03,0.30)
finish(mix,'Ability_Frenzy_v3',lufs=-14.0,lpf=9500,verb=0.10,room=0.3)

# ================= TORPEDO (Barracuda, 0.9 s clip): coil back 0-0.22, launch at 0.24, cruise, slow down from 0.67 =================
N=int(1.45*SR); mix=np.zeros(N); L=0.24-OFF
u=t_(L)/L
place(mix,sweep(L,240,2700,curve=2.4,q=0.3)*ramp(L,2.0,0.015),0,0.6)                           # pressure building
ph=np.cumsum(230*(1+2.0*u**2.5))/SR*2*np.pi
place(mix,(np.sin(ph)+0.3*np.sin(2*ph))*(0.1+0.9*u**2)*np.minimum((L-t_(L))/0.015,1),0,0.17)   # a rising whine: the spring tightening
place(mix,bubbles(L,14,900,2600)*u**1.5,0,0.2)
place(mix,hp(noise(int(0.03*SR)),3000)*dec(0.03,0.003),L,0.9)                                  # the release: crack
place(mix,glide(0.1,2700,480,0.6)*dec(0.1,0.035),L,0.5)                                       # "thwip"
place(mix,lp(noise(int(0.3*SR)),420)*dec(0.3,0.06),L,1.0)                                      # the push
place(mix,subdrop(0.9,96,34,0.18,0.32),L,0.55)
jet=sweep(0.55,6500,500,curve=0.5,q=0.5)*dec(0.55,0.2,0.006); place(mix,jet,L+0.004,1.1)
place(mix,hp(noise(int(0.2*SR)),4000)*dec(0.2,0.06,0.003),L,0.5)                               # the first spray of the launch       # the wake: bright hiss falling away
place(mix,glide(0.45,900,290,0.7)*dec(0.45,0.16,0.01),L+0.01,0.11)                             # it passes you (pitch falls)
for i in range(1,5): place(mix,sweep(0.05,3200,1300,1.0,0.4)*dec(0.05,0.016,0.003),L+i*0.07,0.22*(1-0.15*i))   # the 4 streaks of the VFX
place(mix,bubbles(0.85,75,500,2200)*np.linspace(1,0,int(0.85*SR))**1.2,L+0.08,0.40)
sl=lp(noise(int(0.3*SR)),600); place(mix,hp(sl,140)*np.hanning(len(sl)),0.66-OFF,0.5)          # the water catching it as it slows
finish(mix,'Ability_Torpedo_v3',lufs=-13.5,lpf=11000,verb=0.14,room=0.4)

# ================= HAMMER RAM (Hammerhead, 1.0 s clip): wind-up 0-0.30, lunge 0.33-0.42, HIT at 0.42, shake to 0.63 =================
N=int(1.65*SR); mix=np.zeros(N); W=0.33-OFF; I=0.42-OFF
t=t_(W); f0=np.interp(t,[0,W],[52,76])
gr=lp(saws(f0,[(1,1),(1.01,0.8),(0.5,0.6)])*(1+0.7*np.sin(2*np.pi*19*t)),520)+0.5*bp(saws(f0,[(1,1)]),300,750)
place(mix,gr*ramp(W,1.5,0.02),0,0.32)                                                          # a low growl gathering
place(mix,sweep(W,140,820,curve=2.2,q=0.4)*ramp(W,2.0,0.02),0,0.30)
d=I-W+0.02; place(mix,sweep(d,480,4300,curve=1.7,q=0.4)*ramp(d,1.5,0.008),W-0.02,0.62)          # the charge: whoosh into the hit
place(mix,hp(noise(int(0.05*SR)),2200)*dec(0.05,0.008),I,1.6)
place(mix,bp(noise(int(0.14*SR)),1500,4500)*dec(0.14,0.035),I,1.8)                              # the smack (what a phone speaker carries)                                  # HIT: crack
place(mix,bp(noise(int(0.12*SR)),500,1500)*dec(0.12,0.03),I,1.8)                               # the knock
place(mix,lp(noise(int(0.45*SR)),300)*dec(0.45,0.09),I,1.0)                                    # the mass
tt=t_(0.9); cl=np.zeros(len(tt))
for f,a,tau in [(196,1,0.5),(318,.8,.4),(447,.6,.32),(603,.45,.25),(811,.35,.18),(1090,.3,.14),(1480,.26,.11),(2010,.2,.09),(2740,.14,.07)]:    # the "hammer": a dull anvil ring (inharmonic)
    cl+=np.sin(2*np.pi*np.cumsum(f*(1+0.015*np.exp(-tt/0.05)))/SR+rng.uniform(0,6))*a*np.exp(-tt/tau)
place(mix,cl*np.minimum(tt/0.002,1),I,0.60)
place(mix,subdrop(1.0,84,30,0.22,0.5),I,0.6)
place(mix,sweep(0.6,3600,200,curve=0.45,q=0.45)*dec(0.6,0.2,0.006),I+0.01,0.9)                 # the shock ring
for _ in range(10):                                                                            # bits of rock rattling off
    at=I+rng.uniform(0.04,0.38); L_=rng.uniform(0.008,0.02); f=rng.uniform(1100,3600)
    place(mix,bp(noise(int(L_*SR)),f*0.7,f*1.4)*dec(L_,L_*0.3),at,0.45*(1-(at-I)/0.5))
place(mix,lp(noise(int(0.3*SR)),200)*dec(0.3,0.07),I+0.09,0.6); place(mix,np.sin(2*np.pi*60*t_(0.4))*dec(0.4,0.15,0.005),I+0.09,0.5)   # the aftershock
place(mix,bubbles(0.75,85,350,1500)*np.linspace(1,0,int(0.75*SR))**1.2,I+0.03,0.30)
finish(mix,'Ability_HammerRam_v3',lufs=-13.0,lpf=10000,verb=0.16,room=0.5)

# ================= BREACH (Great White, 1.2 s clip): gather 0-0.40, rise 0.40-0.50, BURST at 0.50, jaws snap 0.62, back in ~0.99 ====
N=int(2.25*SR); mix=np.zeros(N); G=0.40-OFF; B=0.50-OFF; C=0.62-OFF; R=0.99-OFF
place(mix,lp(noise(int(G*SR)),140)*ramp(G,1.5,0.03),0,0.5); place(mix,np.sin(2*np.pi*44*t_(G))*ramp(G,1.5,0.03),0,0.3)      # deep water moving
place(mix,sweep(G,200,1500,curve=2.2,q=0.4)*ramp(G,2.0,0.03),0,0.35)
d=B-G+0.03; place(mix,sweep(d,700,5400,curve=1.6,q=0.45)*ramp(d,1.3,0.008),G-0.03,0.72)                                     # the rise: whoosh to the surface
place(mix,glide(d,180,540,1.5)*ramp(d,1.5,0.008),G-0.03,0.12)
n=int(0.95*SR); tt=t_(0.95)
spl=hp(noise(n),2500)*np.exp(-tt/0.12)+bp(noise(n),600,3200)*(0.6*np.exp(-tt/0.07)+0.4*np.exp(-tt/0.34))
place(mix,spl*np.minimum(tt/0.005,1),B,1.1)                                                                              # BURST: the splash (bright: it is above water)
place(mix,hp(noise(int(0.03*SR)),3000)*dec(0.03,0.004),B,0.6)
place(mix,lp(noise(int(0.4*SR)),260)*dec(0.4,0.09),B,0.9); place(mix,subdrop(1.1,74,31,0.25,0.55),B,0.4)                   # the boom under it
place(mix,bubbles(0.7,28,1800,5200,0.012,0.03)*np.linspace(1,0.2,int(0.7*SR)),B+0.05,0.22)                                # spray: droplets
place(mix,clack(0.66,0.014,1900),C,0.95); place(mix,bp(noise(int(0.12*SR)),280,900)*dec(0.12,0.035),C,1.6)                 # the jaws snap shut at the top
place(mix,subdrop(0.2,132,70,0.03,0.05),C,0.9)
n=int(0.7*SR); tt=t_(0.7); place(mix,bp(noise(n),300,3500)*np.exp(-tt/0.22)*np.minimum(tt/0.015,1),R,0.55)                  # back into the sea
place(mix,np.sin(2*np.pi*55*t_(0.6))*dec(0.6,0.25,0.01),R,0.3)
place(mix,lp(bubbles(1.05,115,300,1400)*np.linspace(1,0,int(1.05*SR))**1.2,3000),R+0.05,0.34)                              # the bubble column, under water again
finish(mix,'Ability_Breach_v3',lufs=-13.0,lpf=12000,verb=0.14,room=0.5)

# ================= TIDAL ROAR (Megalodon, 1.3 s clip): rear back + inhale 0-0.32, ROAR at 0.32 (3 shock rings 0.14 s apart), shake to 1.2 =========
N=int(2.75*SR); mix=np.zeros(N); A0=0.32-OFF
place(mix,sweep(A0,280,1500,curve=2.0,q=0.4)*ramp(A0,2.0,0.02),0,0.40)                                                    # the inhale: water sucked in
place(mix,glide(A0,34,58)*ramp(A0,1.5,0.02),0,0.35); place(mix,bubbles(A0,10,700,2000)*(t_(A0)/A0)**1.5,0,0.15)
L=2.0; tt=t_(L)
f0=np.interp(tt,[0,0.14,0.5,1.2,2.0],[44,68,62,54,36])+2.5*np.sin(2*np.pi*5.2*tt)
rough=1+0.65*np.sin(2*np.pi*np.cumsum(29+4*np.sin(2*np.pi*0.7*tt))/SR)
src=saws(f0,[(1,1),(1.008,1),(0.992,1),(2.004,0.5),(0.5,0.6)])*rough+lp(noise(len(tt)),1100)*0.7
src+=saws(f0,[(1.5,1)])*0.18*np.clip(1-tt/0.8,0,1)                                                                        # a fifth on top for the first beat: power
OH=[(420,130,1.0),(780,170,0.6),(2400,300,0.2)]; AH=[(680,150,1.0),(1150,200,0.7),(2600,320,0.28),(3300,400,0.12)]
w=np.interp(tt,[0,0.25,1.4,2.0],[0.2,1.0,0.3,0.1])                                                                        # the mouth opens (oh -> AH) and closes again
ro=sum(bp(src,max(60,F-BW/2),F+BW/2)*A for F,BW,A in OH)*(1-w)+sum(bp(src,max(60,F-BW/2),F+BW/2)*A for F,BW,A in AH)*w
ro+=lp(src,170)*0.5+bp(src,1500,3500)*0.6+hp(noise(len(tt)),2500)*0.05      # less chest, more rasp: a phone speaker has no bass
e=np.minimum(tt/0.07,1)*np.clip((L-tt)/0.9,0,1)**1.5
place(mix,np.tanh(ro*e*1.8),A0,0.9)
place(mix,lp(noise(int(0.3*SR)),350)*dec(0.3,0.07),A0,1.0); place(mix,hp(noise(int(0.04*SR)),2000)*dec(0.04,0.006),A0,0.35)
for i in range(3):                                                                                                        # one pressure wave per VFX ring
    place(mix,subdrop(1.0,58-6*i,26,0.3,0.35),A0+0.14*i,[0.55,0.4,0.3][i])
    place(mix,sweep(0.5,3800,170,curve=0.45,q=0.45)*dec(0.5,0.18,0.008),A0+0.14*i+0.01,[0.75,0.45,0.33][i])
n=int(2.2*SR); tr=t_(2.2); place(mix,lp(noise(n),90)*np.minimum(tr/0.5,1)*np.clip((2.2-tr)/1.6,0,1)**1.3,A0,0.4)          # the sea shaking
place(mix,bubbles(1.6,190,220,1300)*np.linspace(1,0.1,int(1.6*SR)),A0+0.05,0.45)
finish(mix,'Ability_TidalRoar_v3',lufs=-13.5,lpf=9000,verb=0.24,room=0.85)
print('done')
