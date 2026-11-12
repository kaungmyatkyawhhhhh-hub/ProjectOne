"""Stomp Evolution sound set v2 (13 Nov 2026): UI family, card sounds, crumble by material, rebuild, giant step, evolve riser.
All code-made. Same family as v1: C-major-pentatonic glass plucks for UI, chunky toy thuds for the world."""
import sys; sys.argv=['x','out']
from kit import *
from scipy import signal
import numpy as np
def lp(x,f): return signal.sosfilt(signal.butter(4,f,'lp',fs=SR,output='sos'),x).astype(np.float32)
def hp_(x,f): return signal.sosfilt(signal.butter(2,f,'hp',fs=SR,output='sos'),x).astype(np.float32)
def bp(x,lo,hi): return signal.sosfilt(signal.butter(2,[lo,hi],'bp',fs=SR,output='sos'),x).astype(np.float32)
def noise(L): return rng.standard_normal(T(L)).astype(np.float32)
def env(L,a,d): t=tt(L); return (np.minimum(t/max(a,1e-4),1)*np.exp(-t/d)).astype(np.float32)
def thud(f0,f1,L,dec,drop=0.03):
    t=tt(L); f=f1+(f0-f1)*np.exp(-t/drop); return (np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-t/dec)*np.minimum(t/0.002,1)).astype(np.float32)
def rattle(L,n,lo,hi,dec_each=0.012,seed=3,fall=0.35):
    r=np.random.default_rng(seed); y=np.zeros(T(L),np.float32)
    for k in range(n):
        at=r.exponential(fall)
        if at>L-0.05: continue
        fc=r.uniform(lo,hi); c=bp(noise(0.05),fc*0.7,fc*1.3)*env(0.05,0.001,dec_each)*r.uniform(0.3,1)*np.exp(-at/(L*0.6))
        i=T(at); y[i:i+len(c)]+=c
    return y/(np.abs(y).max()+1e-9)
def chord(ms,L,dec,**k):
    y=np.zeros(T(L),np.float32)
    for m in ms: y+=pluck(m,L=L,dec=dec,**k)
    return y/len(ms)
def clang(f0,L,dec,partials=(1,2.76,5.4,8.9),seed=1):
    t=tt(L); y=np.zeros(len(t),np.float32)
    for i,p in enumerate(partials): y+=np.sin(2*np.pi*f0*p*t+i)*np.exp(-t/(dec/(1+i*0.6)))/(1+i)
    return (y*np.minimum(t/0.001,1)).astype(np.float32)
# ---------------- UI family (C pentatonic glass) ----------------
out('UI_Tap',mix(0.12,(pluck(84,0.1,0.03,bloop=0.25,fm=0.5),0,1.0),(tick(0.015,3000,8000,0.002),0,0.3)),lufs=-20,hp=300,verb=0.0,peak=-8)
out('UI_Hover',mix(0.08,(pluck(91,0.07,0.018,bloop=0.15,fm=0.2,bright=0.5),0,1.0)),lufs=-26,hp=600,verb=0.0,peak=-18)
out('UI_Open',mix(0.6,(swish(0.45,500,3500,peak=0.7,q=1.5),0,0.45),(pluck(79,0.25,0.07),0.12,0.7),(pluck(84,0.25,0.07),0.19,0.75),(pluck(88,0.35,0.1),0.26,0.85)),lufs=-18,hp=200,verb=0.1,room=0.3)
out('UI_Close',mix(0.4,(swish(0.3,2800,500,peak=0.35,q=1.5),0,0.4),(pluck(84,0.2,0.05),0.03,0.7),(pluck(79,0.25,0.06),0.1,0.75)),lufs=-20,hp=200,verb=0.06)
# ---------------- cards ----------------
out('Card_Deal',mix(0.25,(swish(0.22,1200,4500,peak=0.4,q=2.2,flutter=0.4),0,0.8),(tick(0.02,2000,6000,0.004),0.16,0.5)),lufs=-21,hp=400,verb=0.03)
out('Card_Flip',mix(0.3,(swish(0.14,900,3800,peak=0.5,q=2.0),0,0.6),(pluck(91,0.2,0.05,bloop=0.2),0.08,0.7),(tick(0.02,2500,7000,0.003),0.07,0.5)),lufs=-20,hp=300,verb=0.06)
pick=mix(1.2,(swish(0.5,400,5000,peak=0.85,q=1.5),0,0.5),(pluck(72,0.3,0.08),0.1,0.7),(pluck(79,0.3,0.08),0.18,0.75),(pluck(84,0.3,0.08),0.26,0.8),(chord([84,88,91,96],0.8,0.3),0.34,1.0),(sparkle(0.7,22,4500,9000,0.05,seed=31),0.34,0.45),(thud(170,90,0.15,0.05),0.34,0.4))
out('Card_Pick',pick,lufs=-15,hp=150,verb=0.18,room=0.45)
fr=mix(1.0,(sparkle(0.9,34,5000,10500,0.07,seed=41),0,0.8),(swish(0.6,6000,2500,peak=0.2,q=1.8),0,0.4),(pluck(96,0.6,0.25,bloop=0.05,fm=1.6),0,0.5),(pluck(91,0.6,0.25,bloop=0.05,fm=1.6),0.06,0.4),(rattle(0.5,14,4000,9000,0.01,seed=42,fall=0.08),0.02,0.35))
out('Card_Freeze',fr,lufs=-17,hp=500,verb=0.22,room=0.4)
crack=rattle(1.0,60,800,5000,0.006,seed=51,fall=0.35)
bu=mix(1.1,(swish(0.8,200,1800,peak=0.25,q=1.3),0,0.8),(lp(noise(1.0),900)*env(1.0,0.02,0.35),0,0.6),(crack,0.05,0.45),(thud(140,70,0.3,0.1),0,0.4))
out('Card_Burn',bu,lufs=-16,hp=80,verb=0.1)
# ---------------- crumble by material ----------------
g=mix(0.8,(lp(noise(0.5),600)*env(0.5,0.002,0.09),0,0.9),(thud(160,80,0.25,0.07),0,0.6),(bp(noise(0.7),1500,6000)*env(0.7,0.01,0.18),0.03,0.45),(rattle(0.6,16,600,2500,0.02,seed=61,fall=0.12),0.02,0.5),(pluck(88,0.2,0.05,bloop=0.3),0.05,0.25))
out('Crumble_Garden',g,lufs=-17,hp=60,verb=0.05)
p=mix(0.7,(rattle(0.6,24,1800,6500,0.008,seed=71,fall=0.1),0,0.9),(bubble(450,1100,0.08,0.03),0,0.6),(thud(260,140,0.12,0.04),0,0.5),(tick(0.03,2500,8000,0.006),0,0.5))
out('Crumble_Plastic',p,lufs=-16,hp=120,verb=0.05)
m=mix(1.2,(thud(120,50,0.6,0.16),0,0.8),(bp(noise(0.4),300,3000)*env(0.4,0.001,0.08),0,0.8),(clang(520,0.9,0.35,seed=2),0.02,0.35),(clang(830,0.7,0.25,seed=3),0.09,0.25),(rattle(1.0,30,1200,6000,0.01,seed=81,fall=0.25),0.04,0.55),(tick(0.03,1500,7000,0.006),0,0.5))
out('Crumble_Metal',m,lufs=-14,hp=40,verb=0.1,room=0.3)
b=mix(1.4,(thud(100,45,0.9,0.25,0.05),0,0.8),(bp(noise(0.6),200,2200)*env(0.6,0.002,0.14),0,0.85),(rattle(1.3,80,500,4000,0.016,seed=91,fall=0.45),0.03,1.2),(thud(330,150,0.25,0.07),0,0.8),(lp(noise(1.0),400)*env(1.0,0.01,0.35),0.02,0.4))
out('Crumble_Brick',b,lufs=-13,hp=30,verb=0.14,room=0.4)
c=mix(2.0,(thud(80,32,1.4,0.45,0.06),0,0.9),(lp(noise(1.2),350)*env(1.2,0.003,0.4),0,0.7),(bp(noise(0.7),150,1600)*env(0.7,0.002,0.18),0,0.8),(rattle(1.8,110,300,3500,0.02,seed=101,fall=0.6),0.05,1.3),(thud(300,140,0.3,0.08),0,0.9),(bp(noise(0.5),500,2500)*env(0.5,0.002,0.12),0,0.8),(swish(1.0,1800,250,peak=0.12),0,0.3))
out('Crumble_Concrete',c,lufs=-12,hp=25,verb=0.2,room=0.55)
# ---------------- world ----------------
rb=mix(0.6,(bubble(300,900,0.18,0.08),0,0.7),(pluck(79,0.25,0.07,bloop=0.35),0.05,0.6),(pluck(84,0.3,0.09,bloop=0.25),0.11,0.6),(sparkle(0.4,10,5000,9000,0.04,seed=111),0.1,0.3),(thud(180,110,0.12,0.04),0,0.4))
out('Rebuild',rb,lufs=-21,hp=150,verb=0.08)
out('Step',mix(0.6,(thud(90,40,0.55,0.16,0.04),0,0.7),(thud(340,170,0.14,0.04),0,0.8),(bp(noise(0.25),300,1600)*env(0.25,0.002,0.05),0,0.8),(rattle(0.3,8,700,2500,0.01,seed=7,fall=0.05),0.01,0.3),(tick(0.02,800,2500,0.006),0,0.35)),lufs=-17,hp=28,lp=4000,verb=0.06)
out('Ting',mix(0.4,(pluck(84,0.35,0.12,bloop=0.08),0,1.0),(sparkle(0.2,4,6000,9500,0.03,seed=121),0,0.25)),lufs=-21,hp=400,verb=0.1,peak=-8)
out('Tick',mix(0.05,(tick(0.03,3000,9000,0.003),0,1.0),(pluck(96,0.04,0.01,bloop=0.0,fm=0.0,bright=0.3),0,0.4)),lufs=-26,hp=800,verb=0.0,peak=-16)
# evolve riser 2 s (plays at cutscene start) and the hit
L=2.0; t=tt(L); f=140*(2**((t/L)**1.5*3.0)); rise=(np.sin(2*np.pi*np.cumsum(f)/SR)*(t/L)**2).astype(np.float32)
trem=(0.5+0.5*np.sin(2*np.pi*(4+14*(t/L)**2)*t)).astype(np.float32)
out('EvolveRise',mix(2.05,(swish(2.0,200,6500,peak=0.97,q=1.5),0,0.7),(rise*trem*0.5,0,0.6),(sparkle(1.9,40,3000,9000,0.05,seed=131)*np.linspace(0,1,T(1.9)).astype(np.float32),0.1,0.35)),lufs=-15,hp=60,verb=0.15,room=0.4)
out('Whoosh',mix(0.5,(swish(0.45,300,3000,600,peak=0.45,q=1.6),0,1.0)),lufs=-19,hp=120,verb=0.06)
out('Combo',mix(0.6,(pluck(84,0.25,0.07),0,0.8),(pluck(88,0.25,0.07),0.06,0.8),(pluck(91,0.3,0.09),0.12,0.9),(tick(0.03,2000,8000,0.005),0,0.4)),lufs=-17,hp=200,verb=0.1)
print('done')
