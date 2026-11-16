import numpy as np, cv2, json
m=np.load('masks.npz'); lab=m['lab']
c=(m['cyan']&(lab==1)).astype(np.uint8)
c=cv2.morphologyEx(c,cv2.MORPH_CLOSE,np.ones((5,5),np.uint8))
n,l,st,cen=cv2.connectedComponentsWithStats(c)
cr=sorted([dict(x=float(cen[i][0]),x0=int(st[i][0]),w=int(st[i][2]),top=int(st[i][1]),bot=int(st[i][1]+st[i][3]),a=int(st[i][4])) for i in range(1,n) if st[i][4]>25],key=lambda d:d['x'])
for d in cr: print(d)
json.dump(cr,open('crystals_side.json','w'))
# top view crystals
c2=(m['cyan']&(lab==2)).astype(np.uint8); n,l,st,cen=cv2.connectedComponentsWithStats(c2)
print([ (round(cen[i][0]),round(cen[i][1]),st[i][2],st[i][3]) for i in range(1,n) if st[i][4]>30])
