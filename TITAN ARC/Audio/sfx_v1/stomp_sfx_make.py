"""Stomp Evolution sound set v1 (12 Nov 2026). All code-made (owner rule: no Fish Audio, our own synthesis).
Toy-city stomping: chunky low thuds, plastic-toy crunches, bright C-major-pentatonic UI (same key as MEGA BITE's kit)."""
import sys; sys.argv=['x','out']
from kit import *
from scipy import signal
import numpy as np
def lp(x,f): return signal.sosfilt(signal.butter(4,f,'lp',fs=SR,output='sos'),x).astype(np.float32)
def bp(x,lo,hi): return signal.sosfilt(signal.butter(2,[lo,hi],'bp',fs=SR,output='sos'),x).astype(np.float32)
def noise(L): return rng.standard_normal(T(L)).astype(np.float32)
def env(L,a,d): t=tt(L); return (np.minimum(t/max(a,1e-4),1)*np.exp(-t/d)).astype(np.float32)
def thud(f0,f1,L,dec,drop=0.03):
    t=tt(L); f=f1+(f0-f1)*np.exp(-t/drop); return (np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-t/dec)*np.minimum(t/0.002,1)).astype(np.float32)
def rattle(L,n,lo,hi,dec_each=0.012,seed=3,fall=0.35):
    r=np.random.default_rng(seed); y=np.zeros(T(L),np.float32)
    for k in range(n):
        at=r.exponential(fall); 
        if at>L-0.05: continue
        fc=r.uniform(lo,hi); c=bp(noise(0.05),fc*0.7,fc*1.3)*env(0.05,0.001,dec_each)*r.uniform(0.3,1)*np.exp(-at/(L*0.6))
        i=T(at); y[i:i+len(c)]+=c
    return y/(np.abs(y).max()+1e-9)
def chord(ms,L,dec,**k):
    y=np.zeros(T(L),np.float32)
    for m in ms: y+=pluck(m,L=L,dec=dec,**k)
    return y/len(ms)
# 1 stomp: a chunky toy thud
stomp=mix(0.42,(thud(140,55,0.42,0.09),0,0.7),(thud(420,170,0.16,0.045),0,0.75),(bp(noise(0.14),350,2200)*env(0.14,0.001,0.035),0,0.9),(tick(0.03,1500,5000,0.005),0,0.45),(rattle(0.3,8,1200,4000,seed=2,fall=0.06),0.01,0.25))
out('Stomp',stomp,lufs=-15,hp=35,lp=9000,verb=0.04)
# 2 ground pound: boom + air push + rumble
gp=mix(1.3,(thud(110,36,1.2,0.34,0.06),0,0.8),(thud(380,140,0.3,0.08),0,0.7),(bp(noise(0.5),300,1800)*env(0.5,0.002,0.12),0,0.8),(lp(noise(0.6),500)*env(0.6,0.002,0.18),0,0.8),(swish(0.7,2500,300,peak=0.15,q=1.6),0.02,0.45),(rattle(1.1,40,600,3000,seed=5,fall=0.3),0.05,0.35),(tick(0.04,1200,6000,0.008),0,0.5))
out('GroundPound',gp,lufs=-13,hp=28,lp=10000,verb=0.12,room=0.35)
# 3 small crash: plastic toy crunch + pop
cs=mix(0.55,(rattle(0.5,18,1500,6000,dec_each=0.009,seed=8,fall=0.12),0,0.8),(bubble(500,1300,0.07,0.03),0,0.6),(bp(noise(0.08),700,3000)*env(0.08,0.001,0.02),0,0.7),(thud(220,110,0.12,0.04),0,0.5))
out('CrashSmall',cs,lufs=-16,hp=120,lp=11000,verb=0.05)
# 4 big crash: crunch + debris rain + low hit
cb=mix(1.4,(thud(90,40,0.9,0.25,0.05),0,0.7),(thud(320,140,0.25,0.07),0,0.6),(bp(noise(0.5),200,2500)*env(0.5,0.002,0.12),0,0.85),(rattle(1.3,70,400,4500,dec_each=0.015,seed=11,fall=0.4),0.03,0.7),(swish(0.5,1500,300,peak=0.1),0,0.3))
out('CrashBig',cb,lufs=-14,hp=35,lp=10000,verb=0.12,room=0.3)
# 5 coin: two quick glass plucks (E6 -> G6)
coin=mix(0.3,(pluck(88,0.25,0.06),0,0.8),(pluck(91,0.25,0.07),0.045,1.0),(tick(0.02,4000,9000,0.003),0,0.25))
out('Coin',coin,lufs=-20,hp=300,verb=0.05,peak=-6)
# 6 star: a sparkle ting
star=mix(0.35,(pluck(96,0.3,0.08,bloop=0.1),0,0.8),(sparkle(0.3,6,6000,9500,0.03,seed=4),0,0.35))
out('Star',star,lufs=-21,hp=500,verb=0.08,peak=-8)
# 7 golden: C6 E6 G6 C7 arpeggio + shimmer
g=mix(1.1,(pluck(84,0.4,0.12),0,0.8),(pluck(88,0.4,0.12),0.07,0.8),(pluck(91,0.4,0.12),0.14,0.85),(pluck(96,0.8,0.3),0.21,1.0),(sparkle(0.9,26,4000,9000,0.06,seed=7),0.15,0.45))
out('Golden',g,lufs=-15,hp=250,verb=0.18,room=0.4)
# 8 upgrade: rising C5 E5 G5 + whoosh up + a top C6 ring
up=mix(0.8,(swish(0.35,400,3000,peak=0.8),0,0.35),(pluck(72,0.3,0.08),0.0,0.8),(pluck(76,0.3,0.08),0.07,0.8),(pluck(79,0.3,0.09),0.14,0.85),(chord([84,88,91],0.55,0.2),0.21,0.9))
out('Upgrade',up,lufs=-16,hp=180,verb=0.12,room=0.3)
# 9 deny: two soft low notes down
dn=mix(0.35,(pluck(64,0.18,0.06,bright=0.4,fm=0.3),0,1.0),(pluck(59,0.2,0.07,bright=0.4,fm=0.3),0.09,1.0))
out('Deny',dn,lufs=-19,hp=150,verb=0.03)
# 10 quest done: fanfare C5 E5 G5 -> C6 major chord + sparkle
q=mix(1.3,(pluck(72,0.3,0.09),0,0.8),(pluck(76,0.3,0.09),0.09,0.8),(pluck(79,0.3,0.09),0.18,0.85),(chord([84,88,91,96],1.0,0.35),0.27,1.0),(sparkle(0.8,20,4000,8500,0.05,seed=9),0.3,0.4),(thud(180,90,0.15,0.05),0.27,0.4))
out('Quest',q,lufs=-15,hp=150,verb=0.2,room=0.45)
# 11 evolve: riser (noise swish + rising tone) -> hit at 1.05 s (boom + bright chord + shimmer)
L=3.0; t=tt(1.05); f=180*(2**(np.clip(t/1.05,0,1)*2.2)); rise=(np.sin(2*np.pi*np.cumsum(f)/SR)*(t/1.05)**2*0.5).astype(np.float32)
ev=mix(L,(swish(1.05,300,5000,peak=0.95,q=1.5),0,0.6),(rise,0,0.5),
      (thud(120,36,1.6,0.5,0.06),1.05,1.0),(lp(noise(0.5),700)*env(0.5,0.002,0.15),1.05,0.6),
      (chord([72,79,84,88,91],1.9,0.7),1.05,0.9),(sparkle(1.7,40,3500,9000,0.08,seed=13),1.08,0.5),(tick(0.05,1500,7000,0.01),1.05,0.5))
out('Evolve',ev,lufs=-13,hp=30,lp=12000,verb=0.22,room=0.55)
# 12 crown: regal G5 C6 E6 G6 with a held chord
cr=mix(1.4,(pluck(79,0.25,0.08),0,0.8),(pluck(84,0.25,0.08),0.12,0.8),(pluck(88,0.25,0.08),0.24,0.8),(chord([79,84,88,91],1.1,0.45),0.36,1.0),(sparkle(1.0,24,4500,9000,0.06,seed=21),0.36,0.4))
out('Crown',cr,lufs=-15,hp=180,verb=0.22,room=0.5)
# 13 toast: tiny glass bloop
out('Toast',mix(0.15,(pluck(91,0.12,0.035,bloop=0.3),0,1.0)),lufs=-22,hp=400,verb=0.0,peak=-10)
print('done')
