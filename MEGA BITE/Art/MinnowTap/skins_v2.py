"""Skins for Minnow v2 (same UV layout): recolour per class, keeping v2's scales + back shading (modulation = v2 / flat)."""
import numpy as np, json, cv2
from PIL import Image
base=np.array(Image.open('out/MB_Minnow_tap_tex.png').convert('RGB')).astype(np.float32)
M=np.load('out/cls.npy'); keys=json.load(open('out/cls_keys.json'))
PAL=dict(yellow=(255,214,58),stripe=(255,178,40),cream=(255,240,200),blush=(255,160,150),mouth=(70,36,40),dark=(42,34,51))
NV=M.shape[1]
def flat(P):
    col=np.zeros((NV,M.shape[2],3),np.float32)
    for i,k in enumerate(keys): col[M[i]>0]=P.get(k,PAL[k])
    st=M[keys.index('stripe')]>0; col[st]=col[st]*0.55+np.array(P.get('yellow',PAL['yellow']),np.float32)*0.45
    return cv2.GaussianBlur(col,(0,0),0.8)
body=base[1024-NV:][::-1]
mod=body/np.maximum(flat(PAL),1)
SK={
 'Coral':  dict(yellow=(255,138,170),stripe=(255,96,128),cream=(255,232,236),fin=((150,240,230),(32,170,175)),eye=None),
 'Lantern':dict(yellow=(62,92,214),stripe=(92,222,255),cream=(196,224,255),fin=((255,240,140),(230,170,30))),
 'Ghost':  dict(yellow=(232,238,255),stripe=(196,198,244),cream=(255,255,255),fin=((225,245,255),(150,200,240))),
 'Ember':  dict(yellow=(70,56,62),stripe=(255,96,40),cream=(140,82,66),fin=((255,180,70),(220,70,20))),
}
for name,P in SK.items():
    A=base.copy()
    A[1024-NV:]=np.clip(flat(P)*mod,0,255)[::-1]
    s=np.linspace(0,1,256)[:,None]; a,b=np.array(P['fin'][0]),np.array(P['fin'][1])
    A[0:256,256:512]=(a*(1-s)+b*s)[None]
    Image.fromarray(np.clip(A,0,255).astype(np.uint8)).save(f'out/MB_Minnow_v2_{name}.png')
print('ok')
