import numpy as np, cv2, json
from scipy import ndimage as nd
fg=np.load('fg.npy').astype(np.uint8)
UP=[(1450,258),(1420,233),(1390,224),(1360,216),(1300,201),(1240,187),(1180,178),(1120,170),(1060,163),(1000,162),(940,165),(880,171),(820,180),(760,192),(700,203),(640,215),(580,224),(520,232),(460,240),(400,246),(340,258),(300,268),(285,276)]
LO=[(1450,262),(1420,292),(1390,318),(1356,398),(1330,410),(1300,418),(1240,420),(1180,426),(1120,429),(1060,431),(1000,433),(940,433),(880,432),(820,430),(760,426),(700,415),(640,404),(580,390),(520,367),(460,358),(400,343),(340,333),(300,300),(285,282)]
H,W=fg.shape
body=np.zeros_like(fg)
poly=np.array(UP+LO[::-1],np.int32)
cv2.fillPoly(body,[poly],1)
side=fg.copy(); side[560:]=0
fins=(side&(1-cv2.dilate(body,np.ones((7,7),np.uint8)))).astype(np.uint8)
fins=cv2.morphologyEx(fins,cv2.MORPH_OPEN,np.ones((5,5),np.uint8))
lab,n=nd.label(fins)
out={}
for i in range(1,n+1):
    m=(lab==i).astype(np.uint8)
    if m.sum()<300: continue
    cs,_=cv2.findContours(m,cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_NONE)
    c=max(cs,key=cv2.contourArea)
    ap=cv2.approxPolyDP(c,3.0,True)[:,0].tolist()
    x,y,w,h=cv2.boundingRect(c)
    print(i,m.sum(),(x,y,w,h),len(ap))
    out[f'{x}_{y}']=ap
json.dump(out,open('fins_side.json','w'))
# overlay check
vis=np.dstack([fg*80+body*100,fins*255,fins*0])
cv2.imwrite('check.png',cv2.resize(vis[:560].astype(np.uint8),(768,280)))
