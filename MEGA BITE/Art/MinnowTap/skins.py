"""Skin textures for the Tap-style Minnow (same UV layout): recolour the class map; eyes stay."""
import numpy as np, json, cv2
from PIL import Image
base=np.array(Image.open('out/MB_Minnow_tap_tex.png').convert('RGB')).astype(np.float32)
M=np.load('out/cls.npy'); keys=json.load(open('out/cls_keys.json'))
SK={
 'Coral':  dict(yellow=(255,138,170),stripe=(255,96,128),cream=(255,232,236),blush=(255,90,120),fin=((32,170,175),(110,230,220))),
 'Lantern':dict(yellow=(62,92,214),stripe=(92,222,255),cream=(196,224,255),blush=(150,170,255),fin=((230,170,30),(255,232,110))),
 'Ghost':  dict(yellow=(232,238,255),stripe=(196,198,244),cream=(255,255,255),blush=(255,190,215),fin=((150,200,240),(215,240,255))),
 'Ember':  dict(yellow=(70,56,62),stripe=(255,96,40),cream=(140,82,66),blush=(255,110,80),fin=((220,70,20),(255,170,50))),
}
for name,P in SK.items():
    A=base.copy(); NV=M.shape[1]
    col=np.zeros((NV,M.shape[2],3),np.float32)
    for i,k in enumerate(keys):
        c=P.get(k,{'mouth':(70,36,40),'dark':(42,34,51)}.get(k,(0,0,0)))
        col[M[i]>0]=c
    A[1024-NV:]=cv2.GaussianBlur(col,(0,0),0.9)[::-1]
    s=np.linspace(0,1,256)[:,None]; a,b=np.array(P['fin'][0]),np.array(P['fin'][1])
    A[0:256,256:512]=(a*(1-s)+b*s)[None]
    Image.fromarray(np.clip(A,0,255).astype(np.uint8)).save(f'out/MB_Minnow_tap_{name}.png')
print('ok')
