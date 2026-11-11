"""Swim swish v3: a real underwater BODY-THROUGH-WATER swoosh, not droplets.
Layers: (1) smooth real underwater movement (windows with no clicks/drops, picked by low crest factor),
(2) a shaped 'whoom' (band-passed noise sweeping 220 -> 900 -> 300 Hz, bell envelope), (3) a very soft low push.
No transients: slow attack (~80 ms), bell envelope, underwater low-pass, transient smoothing."""
import numpy as np, soundfile as sf, os
exec(open('/home/claude/megabite_audio/hq.py').read().split("# ---- source slices")[0])
from scipy.signal import butter, sosfilt
def bpf(x,lo,hi): return sosfilt(butter(2,[lo,hi],btype='band',fs=SR,output='sos'),x)
def smooth_windows(x, L=0.5, n=6):
    """pick the n smoothest (low crest), reasonably loud windows: water movement without drops/clicks"""
    w=T(L); hop=T(0.05); cands=[]
    for i in range(0,len(x)-w,hop):
        s=x[i:i+w]; r=np.sqrt(np.mean(s**2))+1e-9; c=np.abs(s).max()/r
        cands.append((c - 4*np.log10(r), i))
    cands.sort(); out=[]
    for _,i in cands:
        if all(abs(i-j)>w for j in out): out.append(i)
        if len(out)>=n: break
    return [x[i:i+w] for i in out]
def bell(n,peak=0.35):
    t=np.linspace(0,1,n); return np.where(t<peak,np.sin(0.5*np.pi*t/peak)**2,np.cos(0.5*np.pi*(t-peak)/(1-peak))**1.6).astype(np.float32)
srcs=[]
for f in ['fs_384218','fs_390006','fs_842637','fs_372518','fs_173439']:
    p=f'/home/claude/megabite_audio/src/{f}.wav'
    if os.path.exists(p): srcs+= smooth_windows(load(f),0.5,3)
print('smooth windows', len(srcs))
rng=np.random.default_rng(21)
def whoom(L=0.5,f0=220,f1=900,f2=300,seed=0):
    r=np.random.default_rng(seed); n=T(L); x=r.standard_normal(n).astype(np.float32); out=np.zeros(n,np.float32); B=T(0.01)
    for i in range(0,n,B):
        t=i/n; fc=f0+(f1-f0)*np.sin(np.pi*min(t/0.45,1)*0.5)**2 if t<0.45 else f1+(f2-f1)*((t-0.45)/0.55)
        seg=x[max(0,i-T(0.02)):i+B]; y=bpf(seg,fc/1.6,fc*1.6)[-min(B,n-i):]; out[i:i+len(y)]=y
    return out*bell(n,0.4)
for k in range(3):
    real=srcs[(k*2)%len(srcs)].copy() if srcs else np.zeros(T(0.5),np.float32)
    real=Pedalboard([HighpassFilter(120),LowpassFilter(2600)])(real[None,:],SR)[0]*bell(len(real),0.38)
    w=whoom(0.5,200+30*k,850+60*k,280,seed=30+k)
    t=np.arange(T(0.3))/SR; push=(np.sin(2*np.pi*np.cumsum(90+40*np.sin(np.pi*t/0.3))/SR)*np.sin(np.pi*t/0.3)**2).astype(np.float32)
    y=mixat(0.6,(peaknorm(real,-6),0,0.9),(peaknorm(w,-6),0.0,0.8),(push,0.08,0.10))
    y=master(y,-21,hp=110,lp=3200,sat=0,verb=0.10,room=0.25,shelf=-2,tail=0.08)
    sf.write(f'/home/claude/megabite_audio/set_hq/Swim_Swish_{k+1}.wav',y,SR,subtype='PCM_24')
print('swim ok')
