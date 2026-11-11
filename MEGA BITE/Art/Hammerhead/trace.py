import numpy as np, json
from PIL import Image
from scipy import ndimage as ndi
a=np.array(Image.open('Hammerhead_sheet_chatgpt.png').convert('RGB')).astype(float)
d=np.sqrt(((a-[255,0,255])**2).sum(-1)); fg=d>90
lab,n=ndi.label(fg); sizes=ndi.sum(fg,lab,range(1,n+1)); order=np.argsort(-sizes)
side=lab==order[0]+1; top=lab==order[1]+1; front=lab==order[2]+1
side=ndi.binary_fill_holes(side); top=ndi.binary_fill_holes(top)
np.save('side.npy',side); np.save('top.npy',top); np.save('front.npy',front)
ys,xs=np.where(side); x0,x1=xs.min(),xs.max()
yt=np.array([np.where(side[:,x])[0].min() if side[:,x].any() else -1 for x in range(x0,x1+1)])
yb=np.array([np.where(side[:,x])[0].max() if side[:,x].any() else -1 for x in range(x0,x1+1)])
for x in range(x0,x1+1,40): print(x, yt[x-x0], yb[x-x0])
