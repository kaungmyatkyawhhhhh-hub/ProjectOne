import numpy as np, math
from scipy.optimize import least_squares
b=191.0; PH=10.87; bw=(79-2*PH)/4  # v2: porch 191, the next porch to the right at 112 (Esri)
def rot(p,bear):
    t=math.radians(-bear); c,s=math.cos(t),math.sin(t)
    return np.array([c*p[0]-s*p[1], s*p[0]+c*p[1], p[2]])
def polar(bear,r,z): return np.array([r*math.sin(math.radians(bear)), r*math.cos(math.radians(bear)), z])
P=[];U=[]
def add(p,u): P.append(np.array(p,float)); U.append(u)
add([0,0,34],(833,45)); add([0,0,10.4],(810,712))
for lp,u in [((2.45,21,5.25),(235,945)),((2.45,21,4.35),(240,1005)),((-2.45,21,5.25),(590,940)),((-2.45,21,4.35),(588,998)),((0,21.42,6.5),(422,862)),((0,21.2,10.3),(450,605))]:
    add(rot(lp,b),u)
for j,u in enumerate([(805,1005),(1070,1000),(1295,1010),(1440,1040)]):
    add(polar(b-PH-bw*(j+.5),17.5*math.cos(math.radians(bw/2))+0.12,5.02),u)
for j,u in [(1,(955,940)),(2,(1195,967))]:
    add(polar(b-PH-bw*j,12.35,6.725),u)
P=np.array(P);U=np.array(U,float)
def proj(cam,yaw,pitch,f,P):
    cp,sp=math.cos(pitch),math.sin(pitch); cy,sy=math.cos(yaw),math.sin(yaw)
    fwd=np.array([sy*cp,cy*cp,sp]); right=np.array([cy,-sy,0.0]); up=np.cross(right,fwd)
    d=P-cam; z=d@fwd
    return np.stack([960+f*(d@right)/z, 640-f*(d@up)/z],1)
def res(v):
    phi,L,yaw,pitch,f=v
    cam=polar(phi,L,1.6)
    return (proj(cam,yaw,pitch,f,P)-U).ravel()
best=None
for phi in range(150,200,5):
  for L in (35,45,55,70):
    cam=polar(phi,L,1.6); yaw=math.atan2(-cam[0],-cam[1])
    r=least_squares(res,[phi,L,yaw,0.3,1500],bounds=([120,22,-10,-0.5,300],[230,150,10,1.2,6000]))
    if best is None or r.cost<best.cost: best=r
v=best.x
print('phi',v[0],'L',v[1],'yaw',math.degrees(v[2]),'pitch',math.degrees(v[3]),'f',v[4],'lens mm',v[4]/1920*36)
print('cam',polar(v[0],v[1],1.6))
print('rms',math.sqrt(np.mean(best.fun**2)))
print(np.round(best.fun.reshape(-1,2),0))
phi,L,yaw,pitch,f=v
cam=polar(phi,L,1.6)
from scipy.optimize import brentq
def ypix(p): return proj(cam,yaw,pitch,f,np.array([p]))[0]
# direction from centre toward the camera, ring point nearest the camera
bc=math.degrees(math.atan2(cam[0],cam[1]))
for name,(r,ytarget) in {'bell base axis':(0,712),'merlon top front':(12.6,725),'merlon base front (790)':(12.6,790),'frieze drop bottom 885':(12.35,885)}.items():
    z=brentq(lambda z: ypix(polar(bc,r,z))[1]-ytarget, 0, 40)
    print(name, round(z,2), 'x', round(ypix(polar(bc,r,z))[0]))
# spire widths -> r(z) with this camera
rows=[(80,7),(140,10),(160,30),(180,55),(200,68),(220,72),(240,50),(260,54),(280,67),(300,70),(320,69),(340,79),(360,75),(380,80),(400,88),(420,93),(440,101),(460,115),(480,138),(500,156),(520,185),(540,209),(560,244),(580,273),(600,299),(620,324),(640,339),(660,347),(680,364),(700,377)]
out=[]
for y,w in rows:
    z=brentq(lambda z: ypix(np.array([0,0,z]))[1]-y, 0, 40)
    d=np.linalg.norm(np.array([0,0,z])-cam)
    out.append((round(w/2*d/f,2), round(z,2)))
print(out)
