import numpy as np, json, cv2
from PIL import Image
from scipy import ndimage as ndi
SRC="/mnt/user-data/uploads/Claude+Obsidian/TITAN ARC/Art/Concepts/stomp_sheet_stage3_stone_v9_head_fixed.png"
im=np.asarray(Image.open(SRC).convert("RGB")).astype(np.int32); H,W=im.shape[:2]
d=np.sqrt((im[...,0]-255)**2+im[...,1]**2+(im[...,2]-255)**2)
bg=d<90; lab,n=ndi.label(bg)
border=set(lab[0,:])|set(lab[-1,:])|set(lab[:,0])|set(lab[:,-1]); border.discard(0)
fg=~np.isin(lab,list(border))
fg=ndi.binary_opening(fg,iterations=1)
lab,n=ndi.label(ndi.binary_closing(fg,iterations=6)); objs=ndi.find_objects(lab)
boxes=[]
for i,s in enumerate(objs):
    a=(lab[s]==i+1).sum()
    if a>4000: boxes.append((s[1].start,s[0].start,s[1].stop,s[0].stop,int(a)))
boxes.sort(key=lambda b:(b[1]>H*0.6,b[0]))
print(W,H)
for b in boxes: print(b, "w",b[2]-b[0],"h",b[3]-b[1])
np.save("fg.npy",fg); json.dump(boxes,open("boxes.json","w"))
