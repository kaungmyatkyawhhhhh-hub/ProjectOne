# MEGA BITE: our own synthesized SFX (owner 20:32: "fish audio is bad, ur audio that u made before without fish audio is better")
# Recipe (vault Bible notes - modern_sfx): bright attack >1 kHz + body ~200 Hz + sub sine 30-60 Hz falling over 200-400 ms
# + dark reverb tail; risers curve up so most change lands in the last beat and PEAK exactly on the impact.
import numpy as np, soundfile as sf
from scipy import signal
from pedalboard import Pedalboard, Reverb, LowpassFilter, HighpassFilter, Compressor, Limiter, Chorus, Distortion, PeakFilter
import pyloudnorm as pyln
SR=48000
rng=np.random.default_rng(7)
def t_(d): return np.arange(int(SR*d))/SR
def env(n,a,d,s=0,r=0.0):
    e=np.zeros(n); A=int(a*SR); D=int(d*SR)
    e[:A]=np.linspace(0,1,max(A,1))[:A]
    e[A:A+D]=np.linspace(1,s,max(D,1))[:len(e[A:A+D])]
    e[A+D:]=s
    return e
def place(buf,x,at):
    i=int(at*SR); j=min(len(buf),i+len(x)); buf[i:j]+=x[:j-i]
def noise(n): return rng.standard_normal(n)
def bp(x,lo,hi,o=2): b,a=signal.butter(o,[lo/(SR/2),hi/(SR/2)],'band'); return signal.lfilter(b,a,x)
def lp(x,f,o=2): b,a=signal.butter(o,f/(SR/2),'low'); return signal.lfilter(b,a,x)
def hp(x,f,o=2): b,a=signal.butter(o,f/(SR/2),'high'); return signal.lfilter(b,a,x)
def sweep_noise(d,f0,f1,curve=3.0,q=0.25):
    # smooth band-pass sweep via STFT mask (no block clicks)
    n=int(d*SR); x=noise(n+2048)
    f,tt,Z=signal.stft(x,SR,nperseg=1024,noverlap=768)
    u=np.clip(tt/d,0,1)**curve; fc=f0+(f1-f0)*u
    bw=np.maximum(fc*q,60)
    M=np.exp(-0.5*((f[:,None]-fc[None,:])/bw[None,:])**2)
    _,y=signal.istft(Z*M,SR,nperseg=1024,noverlap=768)
    y=y[:n]; return y/(np.max(np.abs(y))+1e-9)
def bubbles(d,count,fmin=400,fmax=1800):
    n=int(d*SR); out=np.zeros(n)
    for _ in range(count):
        st=rng.uniform(0,d*0.95); f0=rng.uniform(fmin,fmax); L=rng.uniform(0.03,0.09)
        tt=t_(L); f=f0*(1+tt/L*1.2)   # bubbles chirp UP (Minnaert resonance as the bubble shrinks)
        b=np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-tt/(L*0.35))*np.clip(tt/0.003,0,1)*np.clip((L-tt)/0.015,0,1)*rng.uniform(0.3,1)
        place(out,b,st)
    return out
def norm(x,peak=0.95): return x/ (np.max(np.abs(x))+1e-9)*peak
def finish(x,name,lufs=-16.0,lpf=None,verb=0.0,room=0.6):
    fx=[]
    if verb>0: fx.append(Reverb(room_size=room,damping=0.55,wet_level=verb,dry_level=1.0,width=1.0))
    fx+= [HighpassFilter(28), Compressor(threshold_db=-14,ratio=3,attack_ms=4,release_ms=120), Limiter(threshold_db=-1.2)]
    if lpf: fx.insert(0,LowpassFilter(lpf))
    y=Pedalboard(fx)(x.astype(np.float32),SR)
    m=pyln.Meter(SR); l=m.integrated_loudness(y)
    y=pyln.normalize.loudness(y,l,lufs)
    pk=np.max(np.abs(y)); 
    if pk>0.89: y=y/pk*0.89     # < -1 dBTP
    # 5 ms fade in, 60 ms fade out
    fi=int(0.005*SR); fo=int(0.06*SR); y[:fi]*=np.linspace(0,1,fi); y[-fo:]*=np.linspace(1,0,fo)
    sf.write(name+'.ogg',y,SR,format='OGG',subtype='VORBIS'); sf.write(name+'.wav',y,SR)
    print(name, 'len %.2fs'%(len(y)/SR), 'LUFS %.1f'%m.integrated_loudness(y), 'peak %.2f'%np.max(np.abs(y)))
    return y

# ---------------- 1) EVOLVE TRANSFORMATION (matches the cutscene: burst 0.7 s, white flash 1.1 s, card 1.2 s, ends 2.5 s) ----------
D=3.2; N=int(D*SR); mix=np.zeros(N); IMP=1.1
# a) underwater swell: deep filtered noise + bubbles rising, 0 -> impact
sw=sweep_noise(IMP,120,2600,curve=2.6,q=0.35)*np.linspace(0.05,1,int(IMP*SR))**2.2
place(mix,sw*0.55,0)
place(mix,bubbles(IMP,90,500,2400)*np.linspace(0.2,1,int(IMP*SR))*0.35,0)
# b) the riser tone: a shimmering major chord gliding up a 5th, most of the rise in the last third
tt=t_(IMP); u=(tt/IMP)**3
for ratio,amp in [(1,0.5),(1.25,0.35),(1.5,0.35),(2,0.25)]:
    f=220*ratio*(1+0.5*u)
    ph=np.cumsum(f)/SR*2*np.pi
    tone=(np.sin(ph)+0.3*np.sin(2*ph+0.4))*amp*(0.15+0.85*u**1.5)*(1+0.2*np.sin(2*np.pi*7*tt))
    place(mix,tone*0.22,0)
# c) the impact at the flash: sub drop + body thump + bright transient + crystalline bell chord + whoosh
ti=t_(2.0)
rel=np.clip((2.0-ti)/0.6,0,1)**2
sub=np.sin(2*np.pi*np.cumsum(60*np.exp(-ti/0.25)+28)/SR)*np.exp(-ti/0.45); place(mix,sub*1.0,IMP)
body=lp(noise(len(ti)),320)*np.exp(-ti/0.08)*3.0; place(mix,body,IMP)
crack=hp(noise(int(0.05*SR)),2500)*np.exp(-t_(0.05)/0.012); place(mix,crack*0.9,IMP)
bell=np.zeros(len(ti))
for f,a in [(1046.5,1),(1318.5,0.7),(1568,0.7),(2093,0.5),(2637,0.35),(3136,0.25)]:   # C major 9 sparkle chord
    for h,ha in [(1,1),(2.76,0.25),(5.4,0.08)]:   # bell partials
        bell+=np.sin(2*np.pi*f*h*ti+rng.uniform(0,6))*a*ha*np.exp(-ti/(0.9/h))
place(mix,bell*rel*0.16,IMP+0.01)
wh=sweep_noise(0.7,4000,300,curve=0.5,q=0.4)*env(int(0.7*SR),0.02,0.68); place(mix,wh*0.5,IMP-0.05)
# d) sparkle tail: a fast rising arpeggio of glints + fizzing bubbles
for k,f in enumerate([1568,1760,2093,2349,2637,3136,3520,4186]):
    g=np.sin(2*np.pi*f*t_(0.35))*np.exp(-t_(0.35)/0.09)
    place(mix,g*0.10,IMP+0.12+k*0.07)
place(mix,bubbles(1.6,70,700,3000)*np.linspace(1,0,int(1.6*SR))*0.3,IMP+0.05)
evo=finish(norm(mix),'mb_sfx_evolve_v2',lufs=-15.5,verb=0.28,room=0.75)

# ---------------- 2) MEGALODON TIDAL ROAR: huge + intimidating but kid-safe (no screams, no gore) ----------
D=2.6; N=int(D*SR); mix=np.zeros(N)
# a) inhale/anticipation: a short sucking bubble swell (0 -> 0.32 s)
A0=0.32
pre=sweep_noise(A0,300,1400,curve=2,q=0.4)*np.linspace(0,1,int(A0*SR))**2; place(mix,pre*0.35,0)
# b) the roar body: a growling vocal-ish tone (detuned saws ~55-75 Hz) through moving "AWW" formants, roughness from AM
L=1.7; tt=t_(L)
f0=np.interp(tt,[0,0.15,0.9,1.7],[48,74,66,42])+3*np.sin(2*np.pi*5.5*tt)
src=np.zeros(len(tt))
for det in [1,1.007,0.993,2.003]:
    ph=np.cumsum(f0*det)/SR
    src+=signal.sawtooth(2*np.pi*ph)*(0.5 if det>1.5 else 1)
src*= (1+0.6*np.sin(2*np.pi*31*tt))*(1+0.25*noise(len(tt))*0.3)   # growl roughness
src+=lp(noise(len(tt)),900)*0.6   # breath
roar=np.zeros(len(tt))
for F,BW,A in [(520,140,1.0),(900,180,0.7),(2450,300,0.25),(3200,400,0.12)]:   # 'aw' vowel formants
    roar+=bp(src,max(60,F-BW/2),F+BW/2,2)*A
roar+=lp(src,180)*0.8    # chest
e=env(len(tt),0.09,0.0,1.0); e*=np.clip((L-tt)/0.7,0,1)**1.4
roar=np.tanh(roar*e*1.6)
place(mix,roar*0.9,A0)
# c) sub + shockwave: a falling sub sine and a downward whooshing pressure wave on the onset
ti=t_(1.2); sub=np.sin(2*np.pi*np.cumsum(55*np.exp(-ti/0.35)+26)/SR)*np.exp(-ti/0.6)
place(mix,sub*1.0,A0)
shock=sweep_noise(0.9,3200,180,curve=0.45,q=0.45)*env(int(0.9*SR),0.01,0.88); place(mix,shock*0.55,A0+0.02)
# d) bubble eruption from the jaws
place(mix,bubbles(1.4,160,250,1400)*np.linspace(1,0.1,int(1.4*SR))*0.35,A0+0.05)
roarS=finish(norm(mix),'mb_sfx_megaroar_v2',lufs=-14.5,lpf=7200,verb=0.22,room=0.85)
