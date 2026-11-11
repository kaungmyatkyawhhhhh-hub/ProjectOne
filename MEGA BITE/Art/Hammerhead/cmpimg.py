import numpy as np, sys
from PIL import Image
tag=sys.argv[1] if len(sys.argv)>1 else 'v'
sheet=Image.open('Hammerhead_sheet_chatgpt.png').convert('RGBA')
side=np.load('side.npy'); top=np.load('top.npy'); front=np.load('front.npy')
comp=Image.new('RGBA',sheet.size,(255,0,255,255))
for f,m in [('r_side.png',side),('r_top.png',top),('r_front.png',front)]:
    r=Image.open(f).convert('RGBA'); a=np.array(r)
    ys,xs=np.where(m); pad=40; box=(max(0,xs.min()-pad),max(0,ys.min()-pad),min(1536,xs.max()+pad),min(1024,ys.max()+pad))
    comp.alpha_composite(r.crop(box),box[:2])
    rm=a[...,3]>127; R=np.zeros_like(m); R[box[1]:box[3],box[0]:box[2]]=rm[box[1]:box[3],box[0]:box[2]]
    print(f,'IoU %.3f'%((R&m).sum()/(R|m).sum()))
comp=comp.convert('RGB'); both=Image.new('RGB',(1536,2048)); both.paste(sheet.convert('RGB'),(0,0)); both.paste(comp,(0,1024)); both.resize((1152,1536)).save(f'cmp_{tag}.png')
# head close-up side by side
h1=sheet.convert('RGB').crop((1150,230,1500,450)); h2=comp.crop((1150,230,1500,450))
hh=Image.new('RGB',(700,440)); hh.paste(h1,(0,0)); hh.paste(h2,(350,0)); hh=hh.resize((1400,880)); 
f1=sheet.convert('RGB').crop((1000,600,1470,975)); f2=comp.crop((1000,600,1470,975))
ff=Image.new('RGB',(940,375)); ff.paste(f1,(0,0)); ff.paste(f2,(470,0))
out=Image.new('RGB',(1400,880+750)); out.paste(hh,(0,0)); out.paste(ff.resize((1880,750)).crop((0,0,1400,750)),(0,880)); out.save(f'head_{tag}.png')
