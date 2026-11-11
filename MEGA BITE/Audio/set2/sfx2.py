"""MEGA BITE sound set 2 (night shift 10 Nov): bank, evolve, size-up, UI, eat pop, predator warning, the 5 missing ability
sounds and the Safe Reef ambience. Same method as the Reef Shark HQ set: real CC0 Freesound recordings, sliced and layered
with code-made sweeteners (FM bells, sub thumps, synth pads), then the hq.py mastering chain. 48 kHz / 24-bit WAV."""
exec(open('hqlib.py').read())
import os; os.makedirs(OUT,exist_ok=True)
def bellf(L,notes,dec=0.45,mod=2.0,ratio=1.4,amp=1.0):
    t=np.arange(T(L))/SR; y=np.zeros_like(t)
    for at,f,a in notes:
        m=t>=at; tt=t[m]-at
        y[m]+=a*amp*np.sin(2*np.pi*f*tt+mod*np.exp(-tt*6)*np.sin(2*np.pi*f*ratio*tt))*np.exp(-tt/dec)*np.minimum(tt/0.002,1)
    return y.astype(np.float32)
def pad(L,freqs,att=0.3,rel=0.8,cut=2500):
    t=np.arange(T(L))/SR; y=np.zeros_like(t)
    for f in freqs:
        for d in (-0.15,0,0.15):
            ph=2*np.pi*(f*(1+d/100))*t; y+=(2*((ph/(2*np.pi))%1)-1)*0.2   # detuned saws
    env=np.minimum(t/att,1)*np.clip((L-t)/rel,0,1)
    return Pedalboard([LowpassFilter(cut)])((y*env).astype(np.float32)[None,:],SR)[0]
def rev(x): return x[::-1].copy()
def sub(f0=110,f1=48,L=0.14):
    t=np.arange(T(L))/SR; f=f1+(f0-f1)*np.exp(-t*30); return (np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-t*22/max(1,L/0.14))).astype(np.float32)
N=lambda n: 440*2**((n-69)/12)   # midi -> Hz (C6=84)
bub=sorted(slices(load('fs_59978'),12,0.3)+slices(load('fs_16740'),10,0.3),key=lambda s:-np.abs(s).max())
def bubbletail(k,n=3,spread=0.25,g=0.5,L=0.6):
    parts=[(peaknorm(fades(bub[(k*3+i)%len(bub)]),-6),0.03+i*spread/n+rng.uniform(0,0.04),g*rng.uniform(0.5,1)) for i in range(n)]
    return Pedalboard([LowpassFilter(3800),HighpassFilter(250)])(mixat(L,*parts)[None,:],SR)[0]
rows=[]
def out(name,y,**k): save(name,master(y,**k)); rows.append(name)
# 1 BANK ding (signature, 2D): real victory chime + C6-E6-G6 bell arpeggio + sparkle + bubbles
vic=peaknorm(fades(load('fs_717771')),-3)
sp=load('fs_351408'); sp=peaknorm(fades(sp[T(0.0):T(1.2)],0.005,0.3),-10)
arp=bellf(1.4,[(0,N(84),1),(0.07,N(88),0.9),(0.14,N(91),0.9),(0.21,N(96),0.6)],dec=0.35)
out('Bank_Ding',mixat(1.5,(vic,0,0.9),(arp,0.02,0.55),(sp,0.05,0.5),(bubbletail(30,3,0.3),0.1,0.25)),lufs=-13,hp=180,sat=1,verb=0.18,room=0.35,shelf=2)
# 2 EVOLVE sting (signature): reversed whoosh riser -> water explosion hit + major chord swell + rising bells + bubble cloud
riser=peaknorm(fades(rev(load('fs_648729')),0.3,0.01),-6)
hit=peaknorm(fades(load('fs_519008')),-3)
chord=pad(1.8,[N(48),N(55),N(60),N(64),N(67)],att=0.05,rel=1.2,cut=3000)
up=bellf(1.6,[(i*0.06,N(n),0.8) for i,n in enumerate([72,76,79,84,88,91,96])],dec=0.4)
y=mixat(2.6,(riser,0,0.8),(hit,0.72,1.0),(peaknorm(chord,-6),0.74,0.6),(up,0.78,0.5),(bubbletail(31,6,0.8,1.0,1.2),0.8,0.5),(sub(90,40,0.4),0.72,0.35))
out('Evolve_Sting',y,lufs=-12,hp=40,sat=2,verb=0.2,room=0.5,shelf=1.5,tail=0.3)
# 3 SIZE up: quick 4-note rising bell
out('Size_Up',bellf(0.8,[(0,N(84),1),(0.05,N(88),1),(0.1,N(91),1),(0.15,N(96),0.8)],dec=0.22),lufs=-16,hp=300,sat=0,verb=0.12,room=0.3,shelf=1)
# 4 UI
out('UI_Click',mixat(0.25,(peaknorm(fades(load('fs_396193')),-3),0,1.0)),lufs=-18,hp=200,sat=0,verb=0.04,shelf=0)
pop=bellf(0.2,[(0,N(91),1)],dec=0.03,mod=0.5)+bellf(0.2,[(0.005,N(79),0.6)],dec=0.04,mod=0)
out('UI_Pop',pop,lufs=-19,hp=300,sat=0,verb=0.03,shelf=0)
wo=load('fs_683101'); wo=peaknorm(fades(pitch(wo[:T(0.5)],4),0.01,0.15),-6)
out('UI_Open',mixat(0.45,(wo,0,0.8),(bubbletail(32,2,0.15),0.05,0.3)),lufs=-20,hp=250,lp=8000,sat=0,verb=0.05,shelf=0)
fb=peaknorm(fades(load('fs_376749')),-3)
out('Buy_Success',mixat(1.2,(fb,0,1.0),(bellf(1.0,[(0.08,N(88),0.8),(0.16,N(96),0.7)],dec=0.3),0,0.5),(sp,0.05,0.35)),lufs=-14,hp=200,sat=0,verb=0.15,room=0.3,shelf=1.5)
t=np.arange(T(0.32))/SR; eb=(np.sign(np.sin(2*np.pi*150*t))*0.4*np.exp(-((t%0.15)/0.08))*(t<0.28)).astype(np.float32)
out('UI_Error',eb,lufs=-20,hp=100,lp=2500,sat=0,verb=0.03,shelf=0)
# 5 EAT pop x3 (tiny food): real bubble pop pitched up + soft click
b1=load('fs_269583')
for k in range(3):
    y=mixat(0.35,(peaknorm(fades(pitch(b1,[5,7,3][k])),-3),0,1.0),(bellf(0.2,[(0,N([96,98,93][k]),0.5)],dec=0.03,mod=0.3),0.0,0.25))
    out(f'Eat_Pop_{k+1}',y,lufs=-17,hp=250,lp=7000,sat=0,verb=0.05,shelf=0)
# 6 PREDATOR warning (2D): two low muffled pulses (heartbeat) + a dark sub swell
t=np.arange(T(1.3))/SR
def thump(at): m=t>=at; tt=t[m]-at; y=np.zeros_like(t); y[m]=np.sin(2*np.pi*(55+40*np.exp(-tt*25))*tt)*np.exp(-tt*9); return y
pw=(thump(0)+0.8*thump(0.22)+0.9*thump(0.7)+0.7*thump(0.92)).astype(np.float32)
out('Predator_Warning',mixat(1.4,(pw,0,1.0),(peaknorm(pad(1.3,[N(36),N(43)],0.4,0.5,500),-12),0,0.4)),lufs=-15,hp=30,lp=900,sat=4,verb=0.1,room=0.3,shelf=0)
# 7 ABILITIES
jaw=sorted(slices(load('orig_830093__wigglesworth__jaw-or-teeth-bite-at-air')),key=lambda s:-np.abs(s).max())
# FRENZY: 5 accelerating chomps (pitched up) over a rising swoosh
ch=[(peaknorm(fades(pitch(jaw[i%len(jaw)],3+i)),-3),at,0.9) for i,at in enumerate([0,0.17,0.31,0.42,0.5])]
sw=peaknorm(fades(rev(load('fs_169867')[:T(0.8)]),0.2,0.02),-8)
out('Ability_Frenzy',mixat(1.1,*ch,(sw,0,0.5),(bubbletail(33,4,0.5),0.4,0.4)),lufs=-13,hp=90,lp=9000,sat=3,verb=0.08,mid=(3000,3))
# TORPEDO: deep cinematic woosh + jet of bubbles + low push
jet=load('fs_16740')[T(2):T(3.2)]
out('Ability_Torpedo',mixat(1.5,(peaknorm(fades(load('fs_648729')),-3),0,1.0),(peaknorm(fades(jet,0.02,0.3),-6),0.05,0.7),(sub(80,35,0.5),0.0,0.4)),lufs=-13,hp=40,lp=7000,sat=2,verb=0.12,room=0.3)
# HAMMER RAM: heavy hit + structure thud + sub + bubble burst
h1=load('fs_648534'); s1=slices(h1,10,0.8); h1=s1[0] if s1 else h1[:T(0.8)]
h2=load('fs_653294'); s2=slices(h2,10,0.9); h2=s2[0] if s2 else h2[:T(0.9)]
out('Ability_HammerRam',mixat(1.2,(peaknorm(fades(h1),-3),0,1.0),(peaknorm(fades(h2),-4),0.01,0.8),(sub(120,40,0.35),0,0.6),(bubbletail(34,6,0.4,1.0,0.9),0.05,0.5)),lufs=-12,hp=35,lp=8000,sat=4,verb=0.1,room=0.3,mid=(2200,2))
# BREACH: up-whoosh then a big real splash (above water = bright, no low-pass)
out('Ability_Breach',mixat(2.3,(peaknorm(fades(rev(load('fs_683101')[:T(0.6)]),0.2,0.02),-8),0,0.6),(peaknorm(fades(load('fs_442773')),-3),0.45,1.0),(peaknorm(fades(load('fs_316744')),-5),0.5,0.6)),lufs=-12,hp=60,sat=1,verb=0.1,room=0.3,shelf=1.5)
# TIDAL ROAR: monster roar pitched down + underwater rumble + low explosion, all under water (low-pass)
ro=load('fs_398908'); ro=ro[:T(2.6)]
out('Ability_TidalRoar',mixat(3.0,(peaknorm(fades(pitch(ro,-5),0.02,0.6),-3),0,1.0),(peaknorm(fades(load('fs_151854')),-4),0.1,0.8),(peaknorm(fades(pitch(load('fs_124544')[:T(2.5)],-3)),-6),0.05,0.6),(sub(70,30,1.2),0,0.5),(bubbletail(35,8,1.5,1.0,2.2),0.3,0.4)),lufs=-12,hp=30,lp=3200,sat=3,verb=0.2,room=0.6,tail=0.3)
# 8 AMBIENCE: Safe Reef seamless 20 s loop (underwater room tone + sparse bubbles); master first, loop after (no fade dip)
a=load('fs_195509'); L=T(20); xf=T(2)
bb=mixat(22,*[(peaknorm(fades(bub[i%len(bub)]),-6),rng.uniform(0,21),rng.uniform(0.15,0.35)) for i in range(15)])
x=a[:T(22)]+Pedalboard([LowpassFilter(3000)])(bb[None,:],SR)[0]
x=master(x,-28,hp=40,lp=4000,sat=0,verb=0,shelf=0,tail=0.0)
fade=np.linspace(0,1,xf).astype(np.float32)
loop=x[:L].copy(); loop[:xf]=loop[:xf]*fade+x[L:L+xf]*(1-fade)
sf.write(f'{OUT}/Ambience_SafeReef_Loop.wav',loop,SR,subtype='PCM_24'); rows.append('Ambience_SafeReef_Loop')
# trim leading silence on the UI sounds and level the breach
for nm,g in [('UI_Open',0),('Buy_Success',0),('Ability_Breach',-2.2)]:
    y,_=sf.read(f'{OUT}/{nm}.wav'); k=max(0,int(np.argmax(np.abs(y)>0.01))-T(0.004)) if nm!='Ability_Breach' else 0
    y=y[k:]*10**(g/20); y[:T(0.002)]*=np.linspace(0,1,T(0.002)); sf.write(f'{OUT}/{nm}.wav',y,SR,subtype='PCM_24')
print('made',len(rows),rows)
