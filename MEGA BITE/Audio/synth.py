import numpy as np, soundfile as sf, pyloudnorm as pyln
from scipy.signal import butter, sosfilt
SR=48000
rng=np.random.default_rng(7)
def bp(x,lo,hi,o=4): return sosfilt(butter(o,[lo,hi],btype='band',fs=SR,output='sos'),x)
def lp(x,f,o=4): return sosfilt(butter(o,f,btype='low',fs=SR,output='sos'),x)
def hp(x,f,o=2): return sosfilt(butter(o,f,btype='high',fs=SR,output='sos'),x)
def env(n,a,d,curve=4):
    t=np.arange(n)/SR; e=np.minimum(t/max(a,1e-4),1)*np.exp(-np.maximum(t-a,0)/d*curve/4); return e
def T(sec): return int(sec*SR)
def place(out,x,at): i=T(at); out[i:i+len(x)]+=x[:len(out)-i]
def norm(x,lufs=-16.0):
    x=x-np.mean(x); m=pyln.Meter(SR,block_size=0.1); l=m.integrated_loudness(x)
    y=pyln.normalize.loudness(x,l,lufs); pk=np.abs(y).max()
    if pk>0.89: y*=0.89/pk
    return y
def fade(x,fi=0.004,fo=0.05):
    a=T(fi); b=T(fo); x=x.copy(); x[:a]*=np.linspace(0,1,a); x[-b:]*=np.linspace(1,0,b); return x
def bubbles(dur,count,lo,hi,seed):
    r=np.random.default_rng(seed); out=np.zeros(T(dur))
    for k in range(count):
        at=r.uniform(0,dur*0.8); L=r.uniform(0.025,0.06); n=T(L); t=np.arange(n)/SR
        f0=r.uniform(lo,hi); f=f0*(1+1.8*t/L)            # rising "bloop"
        ph=2*np.pi*np.cumsum(f)/SR; b=np.sin(ph)*np.sin(np.pi*t/L)**2*r.uniform(0.3,1)
        place(out,b,at)
    return out
def chomp(seed, size=1.0):
    r=np.random.default_rng(seed); out=np.zeros(T(0.6))
    # 1 transient: teeth CLICK (bright, 12 ms) - the identity in 2-5 kHz
    n=T(0.012); click=bp(r.standard_normal(n),2200,6000)*env(n,0.0005,0.004)
    click+=0.6*np.sin(2*np.pi*3400*np.arange(n)/SR)*env(n,0.0003,0.003)
    # 2 body: jaw THUMP (pitch drop) + wet crunch noise
    n=T(0.16); t=np.arange(n)/SR; f=(170*size)*np.exp(-t*9)+55*size
    thump=np.sin(2*np.pi*np.cumsum(f)/SR)*env(n,0.002,0.07)
    crunch=bp(r.standard_normal(n),700,2600)*env(n,0.001,0.035)*(1+0.5*np.sin(2*np.pi*60*t))
    body=0.9*thump+0.55*crunch
    # 3 tail: a few bubbles, low-passed (underwater)
    tail=lp(bubbles(0.35,7,500,1100,seed+1),3500)*0.35
    place(out,0.8*click,0.0); place(out,body,0.004); place(out,tail,0.06)
    out=hp(out,45)
    return fade(norm(out,-15.0),0.002,0.12)
for k in range(3):
    y=chomp(11+k, size=1.0+0.06*(k-1)); sf.write(f'mb_bite_synth_v{k+1}.wav',y,SR)
# the fish take, levelled for a fair comparison
x,sr=sf.read('fish_bite_take1.wav'); x=x.mean(1) if x.ndim>1 else x
sf.write('fish_bite_take1_level.wav',norm(x,-15.0),sr)
print('ok')
