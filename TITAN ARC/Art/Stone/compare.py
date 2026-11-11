import numpy as np, sys
from PIL import Image
fg=np.load("fg.npy"); sheet=Image.open("/mnt/user-data/uploads/Claude+Obsidian/TITAN ARC/Art/Concepts/stomp_sheet_stage3_stone_v9_head_fixed.png").convert("RGB")
cx={"front":328,"side":778,"back":1212}; tiles=[]
for k in ("front","side","back"):
    r=Image.open(f"r_{k}.png").convert("RGBA"); a=np.asarray(r)[...,3]>128
    x0=cx[k]-320; m=np.zeros((660,640),bool); xs0=max(0,x0); m[:, xs0-x0:xs0-x0+min(1536,x0+640)-xs0]=fg[10:670, xs0:min(1536,x0+640)]
    if k=="side": m[:, :627-x0-6]=False; m[:, 883-x0+6:]=False
    if k=="front": m[:, 600-x0:]=False
    if k=="back": m[:, :940-x0]=False
    iou=(a&m).sum()/max(1,(a|m).sum()); print(k,"IoU %.3f"%iou, "render-only %.3f sheet-only %.3f"%((a&~m).sum()/m.sum(), (m&~a).sum()/m.sum()))
    s=sheet.crop((x0,10,x0+640,670)); bgd=Image.new("RGBA",(640,660),(255,0,255,255)); bgd.alpha_composite(r)
    d=np.zeros((660,640,3),np.uint8); d[a&m]=(90,90,90); d[a&~m]=(255,60,60); d[m&~a]=(60,120,255)
    t=Image.new("RGB",(1920,660)); t.paste(s,(0,0)); t.paste(bgd.convert("RGB"),(640,0)); t.paste(Image.fromarray(d),(1280,0)); tiles.append(t)
out=Image.new("RGB",(1920,1980))
for i,t in enumerate(tiles): out.paste(t,(0,660*i))
out=out.resize((1280,1320)); out.save("compare.png")
