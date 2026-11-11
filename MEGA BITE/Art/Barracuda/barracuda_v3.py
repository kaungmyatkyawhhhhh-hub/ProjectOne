"""MEGA BITE Hammerhead v3 (night shift 10 Nov). Traced from Hammerhead_sheet_chatgpt.png + the head close-up.
Body: ring loft (side profile, fins patched out; top-view widths), alternating diagonals so the countershade line
(traced per column from the sheet) zig-zags like the sheet. Cephalofoil: its own bevelled wing from the top-view T.
Face: carved open mouth (cavity pulled in), real teeth on an arc, glowing eye domes + brow wedges at the hammer tips,
gill slits as thin plates. Colours: flat sheet palette chosen by RULES (no noisy projection)."""
import bpy, bmesh, math, numpy as np
from mathutils import Vector, geometry
from PIL import Image
from scipy import ndimage as ndi
import cv2
IMG=np.array(Image.open('Barracuda_sheet_chatgpt.png').convert('RGB')).astype(int)
side=np.load('side.npy'); top=np.load('top.npy'); front=np.load('front.npy')
S=4.6/1365; NOSE=1486; BASEZ=318
def X(px): return (px-NOSE)*S
def Z(py): return (BASEZ-py)*S
def PX(x): return NOSE+x/S
def PY(z): return BASEZ-z/S
K=1446/996; TX0,TY0=37,772
FK=1.038; FX0,FY0=1232,780
def top2side(xt,yt): return 43+(xt-TX0)*K,(yt-TY0)*K
# ---------- profiles
def col_edges(m,x):
    c=np.where(m[:,int(x)])[0]; return (c.min(),c.max()) if len(c) else (None,None)
def patch(xs,arr,rngs):
    arr=arr.copy()
    for a,b in rngs:
        i=np.searchsorted(xs,a); j=np.searchsorted(xs,b); arr[i:j+1]=np.linspace(arr[i],arr[j],j-i+1)
    return arr
XS=np.arange(300,1487)
YT=np.array([col_edges(side,x)[0] for x in XS],float); YB=np.array([col_edges(side,x)[1] for x in XS],float)
YT=ndi.gaussian_filter1d(patch(XS,YT,[(510,660),(860,1060)]),3); YB=ndi.gaussian_filter1d(patch(XS,YB,[(440,580)]),3)
def yt(px): return float(np.interp(px,XS,YT))
def yb(px): return float(np.interp(px,XS,YB))
HW=[]
for x in XS:
    xt=int(round(TX0+(x-43)/K)); lab,_=ndi.label(top[:,min(max(xt,0),top.shape[1]-1)]); l=lab[TY0]
    HW.append((np.where(lab==l)[0].max()-TY0)*K if l else 0)
HW=patch(XS,np.array(HW,float),[(560,700),(880,1070)]); H_=YB-YT
HW=ndi.gaussian_filter1d(np.clip(HW,0.34*H_,0.56*H_),6)
def hw(px): return float(np.interp(px,XS,HW))
# countershade line (top of the white belly) traced per column from the sheet, light smoothing keeps the zig-zag
WH=(IMG.min(-1)>165)&side
CS=[]
for x in XS:
    c=np.where(WH[int(yt(x))+5:int(yb(x)),x])[0]
    CS.append(c.min()+int(yt(x))+5 if len(c) else yb(x))
CS=np.array(CS,float); CS=np.clip(CS,YT+0.4*(YB-YT),YB-5)
CS=patch(XS,CS,[(890,1070)])           # the gill slits sit on the line: bridge them
CS=ndi.gaussian_filter1d(ndi.median_filter(CS,size=41),6)
def csline(px): return float(np.interp(px,XS,CS))
# ---------- palette (from the sheet)
P=dict(teal_l=(116,164,204),teal_m=(96,140,180),teal_d=(74,112,148),fin_l=(74,108,140),fin_m=(58,88,117),fin_d=(42,66,90),
       white=(222,234,246),white_d=(186,204,222),maroon=(80,18,24),tooth=(250,246,232),eye=(252,226,40),gill=(40,45,54),brow=(30,44,62),spot=(50,78,104),glow=(255,255,255))
def lin(c): c=np.array(c)/255.0; return tuple(np.where(c<=0.04045,c/12.92,((c+0.055)/1.055)**2.4))
MATS={}
def mat(name):
    if name in MATS: return MATS[name]
    m=bpy.data.materials.get('BC_'+name) or bpy.data.materials.new('BC_'+name); m.use_nodes=True
    b=m.node_tree.nodes['Principled BSDF']; b.inputs['Base Color'].default_value=(*lin(P[name]),1); b.inputs['Roughness'].default_value=0.8
    if name=='glow': b.inputs['Emission Color'].default_value=(*lin(P[name]),1); b.inputs['Emission Strength'].default_value=4
    MATS[name]=m; return m
L=Vector((-0.35,-0.6,0.72)).normalized()
def tone(n,base):
    d=n.dot(L)
    return base+('_l' if (n.z>0.75 or d>0.72) else ('_m' if d>0.1 else '_d'))
# ---------- mouth geometry (side px), traced on the sheet's head
CORNER=1230
def lip_up(px):  return float(np.interp(px,[1230,1300,1400,1450,1472,1488],[370,356,342,332,340,352]))
def lip_lo(px):  return float(np.interp(px,[1230,1260,1350,1450,1472,1488],[370,376,374,372,364,354]))
# the lower jaw's underside (side sheet), and the jaw ends at x=1356 (the upper jaw + snout carry on under the hammer)
JAWB=lambda px: float(np.interp(px,[1150,1300,1403,1443,1483,1488],[yb(1150),yb(1300),423,412,381,378]))
BV=lambda px: float(np.interp(px,[1487,1350,1380,1410,1437],[418,409,380,345,300]))
UPJAW=lambda px: float(np.interp(px,[1487,1355,1380,1400,1420,1437],[346,346,341,332,306,272]))
def clear():
    for o in list(bpy.data.objects): bpy.data.objects.remove(o,do_unlink=True)
    for m in list(bpy.data.meshes): bpy.data.meshes.remove(m)
HALF=[(0.0,1.0),(0.425,0.93),(0.85,0.6),(1.0,0.05),(0.84,-0.475),(0.6,-0.85),(0.0,-1.0)]
RING=HALF+[(-u,v) for u,v in reversed(HALF[1:-1])]
FACES=[]   # (bmface, colour key)
def addf(bm,vs,key):
    f=bm.faces.new(vs); FACES.append((f,key)); return f
HV=np.array([v for _,v in HALF]); HU=np.array([u for u,_ in HALF])
def ring_levels(px,zc,hh):
    lv=[1.0,0.93,0.6,0.05,-0.475,-0.85,-1.0]
    vcs=(zc-csline(px))/hh
    if px>CORNER-30:
        vlu=(zc-lip_up(px))/hh; vll=(zc-lip_lo(px))/hh
        vm1=vlu+(vll-vlu)*0.33; vm2=vlu+(vll-vlu)*0.66
    else:
        vlu,vll,vm1,vm2=-0.6,-0.66,-0.62,-0.64
    extra=[min(0.98,max(-0.98,v)) for v in (vcs,vlu,vll,vm1,vm2)]
    allv=sorted(lv+extra,reverse=True)
    for i in range(1,len(allv)):
        if allv[i]>=allv[i-1]-0.004: allv[i]=allv[i-1]-0.004
    return allv
def body(bm):
    stations=list(range(300,1150,22))+list(range(1150,1480,12))+[1478,1483,1486,1493]
    rings=[]
    for px in stations:
        tip=px>NOSE; px0=px; px=min(px,NOSE)
        ybot=yb(px); yreal=1e9
        if px>1150:
            ybot=JAWB(px) if px<=1487 else BV(px)          # virtual section bottom: continuous past the chin (no seam)
            if px>1487: yreal=min(yb(px),UPJAW(px))        # the real underside of the snout: rows below it clamp to it
        zc=(yt(px)+ybot)/2; hh=(ybot-yt(px))/2; w=hw(px)
        if tip: hh*=0.3; w*=0.3
        pass
        lv=ring_levels(px,zc,hh)
        right=[(float(np.interp(-v,-HV,HU)),v) for v in lv]
        pts=right+[(-u,v) for u,v in reversed(right[1:-1])]
        r=[]
        for u,v in pts:
            py=min(zc-v*hh,yreal); lat=u*w
            if not tip and CORNER+2<px<=1487 and lip_up(px)+1.0<py<lip_lo(px)-1.0:
                depth=min(1.0,(px-CORNER)/40.0)          # the gape deepens from the mouth corner forward
                lat*=1-0.72*depth
            r.append(bm.verts.new((X(px0),lat*S,Z(py))))
        rings.append(r)
    n=len(rings[0])
    for i,(a,b) in enumerate(zip(rings,rings[1:])):
        for k in range(n):
            q=[(a[k],a[(k+1)%n],b[(k+1)%n]),(a[k],b[(k+1)%n],b[k])] if (i+k)%2 else [(a[k],a[(k+1)%n],b[k]),(a[(k+1)%n],b[(k+1)%n],b[k])]
            for t in q: addf(bm,t,'body')
    addf(bm,rings[0][::-1],'body'); addf(bm,rings[-1],'head_front')
def hammer(bm):
    xt0=785; ys_,xs_=np.where(top[:,xt0:]); ylo,yhi=ys_.min(),ys_.max()
    secs=[]
    for yl in np.linspace(ylo+2,yhi-2,17):
        rowx=np.where(top[int(round(yl)),xt0:])[0]
        if len(rowx)==0: continue
        xa,_=top2side(xt0+rowx.min(),yl); xb,lat=top2side(xt0+rowx.max(),yl); xb=min(xb,NOSE-2)
        tip=abs(lat)/231.0
        tz=lambda px: yt(px)+8*tip**2
        bz=lambda px: max(HAM_BOT(px)-6*tip, yt(px)+26)
        pts=[(xa,tz(xa)+6),(xa+(xb-xa)*0.25,tz(xa+(xb-xa)*0.25)),(xa+(xb-xa)*0.6,tz(xa+(xb-xa)*0.6)),(xb-4,tz(xb)+3),(xb,(tz(xb)+bz(xb))/2+2),
             (xb-4,bz(xb)),(xa+(xb-xa)*0.6,bz(xa+(xb-xa)*0.6)),(xa+(xb-xa)*0.25,bz(xa+(xb-xa)*0.25)),(xa,bz(xa)-4)]
        secs.append([bm.verts.new((X(px),lat*S,Z(py))) for px,py in pts])
    n=len(secs[0])
    for a,b in zip(secs,secs[1:]):
        for k in range(n): addf(bm,(a[k],a[(k+1)%n],b[(k+1)%n],b[k]),'hammer')
    addf(bm,secs[0],'hammer'); addf(bm,secs[-1][::-1],'hammer')
def plate(bm,pts3,thick_vec,key):
    """pts3: list of Vector outline; extruded by thick_vec both ways; caps tessellated"""
    A=[bm.verts.new(p+thick_vec) for p in pts3]; B=[bm.verts.new(p-thick_vec) for p in pts3]; n=len(A)
    for k in range(n):
        f=addf(bm,(A[k],A[(k+1)%n],B[(k+1)%n],B[k]),key)
        mid=(pts3[k]+pts3[(k+1)%n])/2; cen0=sum(pts3,Vector())/len(pts3)
        if f.normal.dot(mid-cen0)<0: f.normal_flip()
    tris=geometry.tessellate_polygon([[p for p in pts3]])
    new=[]
    for t in tris:
        new.append(addf(bm,(A[t[0]],A[t[1]],A[t[2]]),key)); new.append(addf(bm,(B[t[2]],B[t[1]],B[t[0]]),key))
    # orient: cap A must face +thick_vec; side walls must face away from the outline centre
    cen=sum(pts3,Vector())/len(pts3)
    for f in new:
        if f.calc_center_median().dot(thick_vec)-cen.dot(thick_vec)>0 and f.normal.dot(thick_vec)<0: f.normal_flip()
        if f.calc_center_median().dot(thick_vec)-cen.dot(thick_vec)<0 and f.normal.dot(thick_vec)>0: f.normal_flip()
def fins(bm):
    # --- fin roots are embedded in the body (10 Nov fix: fins used to float 1-60 px off the body) ---
    from mathutils.bvhtree import BVHTree as _B
    bm.normal_update(); _bf=[f for f,k in FACES if k in ('body','head_front')]
    _bv=list({v for f in _bf for v in f.verts}); _vi={v:i for i,v in enumerate(_bv)}
    _bvh=_B.FromPolygons([v.co.copy() for v in _bv],[[_vi[v] for v in f.verts] for f in _bf])
    def blat(x,y):      # body half-width (px) at side-view point (x,y)
        h=_bvh.ray_cast(Vector((X(x),5.0,Z(y))),Vector((0,-1,0)))
        return h[0].y/S if h[0] is not None else 0.0
    X0=float(XS[0])
    def cl(x): return min(max(float(x),X0+1),float(XS[-1])-1)
    def embed_flat(poly,cx,cy):
        out=[]
        for x,y in poly:
            x=float(x); y=float(y); xc=cl(x)
            if cx<X0:                       # tail: root edge pushed forward into the tail stock
                if x>X0-10: x=X0+18; y=min(max(y,yt(X0+18)+5),yb(X0+18)-5)
            elif cy<yt(cl(cx)):             # dorsal-type: root sinks into the back
                if y>yt(xc)-10: y=yt(xc)+16
            else:                           # anal/pelvic: root sinks into the belly
                if y<yb(xc)+10: y=yb(xc)-16
            if not out or abs(out[-1][0]-x)+abs(out[-1][1]-y)>3.0: out.append((x,y))
        if len(out)>2 and abs(out[0][0]-out[-1][0])+abs(out[0][1]-out[-1][1])<=3.0: out.pop()
        return out
    body_m=np.zeros_like(side)
    for x in XS:
        a,b=int(yt(x))+3,int(yb(x))-3
        if b>a: body_m[a:b,x]=True
    finm=side&~ndi.binary_dilation(body_m,iterations=2); finm[:,:300]=side[:,:300]
    lab,n=ndi.label(ndi.binary_opening(finm,iterations=2)); sizes=ndi.sum(finm,lab,range(1,n+1))
    for i in np.argsort(-sizes)[:6]:
        m=(lab==i+1).astype(np.uint8); ys,xs=np.where(m); cx,cy=xs.mean(),ys.mean()
        if ys.max()-ys.min()<18 or sizes[i]<250 or cx>1350: continue
        cs,_=cv2.findContours(m,cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_NONE); cnt=max(cs,key=cv2.contourArea)
        poly=cv2.approxPolyDP(cnt,2.5,True)[:,0,:]
        below=cy>yb(min(max(cx,300),1488))-10
        if True or not below or not (99999<cx<0):
            pts=[Vector((X(x),0,Z(y))) for x,y in embed_flat(poly,cx,cy)]
            plate(bm,pts,Vector((0,(8 if cx<300 else 6)*S,0)),'fin'); continue
        pect=True; rootz=yb(cx)-30
        for s in (1,-1):
            pts=[]
            for x,y in poly:
                x=float(x); y=float(y)
                if y<yb(cl(x))+10:            # root edge tucked up into the belly side
                    y2=yb(cl(x))-24; _p=Vector((X(x),s*0.75*blat(x,y2)*S,Z(y2)))
                    if not pts or (pts[-1]-_p).length>3*S: pts.append(_p)
                    continue
                d=max(0,y-rootz); lat=(80+d*1.45+0.35*max(0,950-x)*min(1,d/60))
                _d0=d; d=0; _b=(80+d*1.45+0.35*max(0,950-x)*min(1,d/60)); d=_d0; lat=lat-_b+0.75*blat(x,yb(cl(x))-24)
                pts.append(Vector((X(x),s*lat*S,Z(y))))
            # thickness along the fin's own normal
            nrm=(pts[len(pts)//3]-pts[0]).cross(pts[2*len(pts)//3]-pts[0]); nrm.normalize()
            plate(bm,pts,nrm*5*S,'fin')
def gills(bm):
    dark=(IMG.sum(-1)<230)&side; sub=np.zeros_like(dark); sub[220:390,1010:1160]=dark[220:390,1010:1160]
    lab,n=ndi.label(sub); sizes=ndi.sum(sub,lab,range(1,n+1))
    for i in np.argsort(-sizes)[:5]:
        if sizes[i]<60: continue
        m=(lab==i+1).astype(np.uint8); cs,_=cv2.findContours(m,cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_NONE)
        poly=cv2.approxPolyDP(max(cs,key=cv2.contourArea),1.5,True)[:,0,:]
        for s in (1,-1):
            pts=[]
            for x,y in poly:
                zc=(yt(x)+yb(x))/2; hh=(yb(x)-yt(x))/2; v=(zc-y)/hh
                # lateral position on the ring surface at that height (+ a hair outside)
                u=np.interp(-v,[-1,-0.85,-0.6,-0.05,0.475,0.85,1],[0,0.425,0.85,1.0,0.84,0.6,0])
                pts.append(Vector((X(x),s*(u*hw(x)+2.5)*S,Z(y))))
            plate(bm,pts,Vector((0,s*1.2*S,0)),'gill')
def teeth(bm):
    def arcpt(th,row):
        f,hw_=(1478,94) if row==0 else (1474,86)
        px=f-(f-1250)*(1-math.cos(th))**1.15
        lw=surf_lat(px,lip_up(px)+3 if row==0 else lip_lo(px)-3)
        lat=math.copysign(0.88*lw*min(1.0,abs(math.sin(th))*1.7),th)
        return px,lat
    for row,(n,span,ln,base) in enumerate([(13,1.35,16,'up'),(11,1.25,14,'lo')]):
        for i in range(n):
            th=-span+2*span*i/(n-1)
            px,lat=arcpt(th,row)
            big=1.0+(1.4 if abs(abs(th)-0.18)<0.12 else 0.0)          # front teeth bigger
            L_=ln*big; W_=12*big
            zb=lip_up(px)-1 if base=='up' else lip_lo(px)+1
            tip=zb+L_ if base=='up' else zb-L_
            # tooth = triangular prism facing out along the arc normal
            nrm=Vector((math.cos(th),math.sin(th),0)); tang=Vector((-math.sin(th),math.cos(th),0))
            c=Vector((X(px),lat*S,0))-nrm*2*S
            p0=c+tang*(W_/2)*S; p1=c-tang*(W_/2)*S
            pts=[Vector((p0.x,p0.y,Z(zb))),Vector((p1.x,p1.y,Z(zb))),Vector((c.x,c.y,Z(tip)))]
            plate(bm,pts,nrm*3.5*S,'tooth')
def surf_lat(px,py):
    zc=(yt(px)+(JAWB(px) if 1150<px<=1487 else yb(px)))/2; hh=((JAWB(px) if 1150<px<=1487 else yb(px))-yt(px))/2; v=(zc-py)/hh
    u=float(np.interp(-v,-HV,HU)); w=hw(px)
    pass
    return u*w
def eyes_brows(objs):
    for s_ in (1,-1):
        lat=surf_lat(1310,280)
        bpy.ops.mesh.primitive_uv_sphere_add(segments=10,ring_count=6,radius=15*S,location=(X(1310),s_*(lat-3)*S,Z(281)))
        e=bpy.context.object; e.name='Eye_'+('L' if s_>0 else 'R'); e.scale=(1.45,0.55,0.75)
        e.rotation_euler=(0,0,s_*math.radians(-40)); e.data.materials.append(mat('eye'))
        for p in e.data.polygons: p.use_smooth=False
        objs.append(e)
    bm=bmesh.new()
    for s_ in (1,-1):
        pts=[(1250,236),(1356,286),(1350,296),(1262,252)]
        P3=[Vector((X(x),s_*(surf_lat(x,y)+2)*S,Z(y))) for x,y in pts]
        A=[bm.verts.new(p+Vector((0,s_*6*S,0))) for p in P3]; B=[bm.verts.new(p-Vector((0,s_*2*S,0))) for p in P3]
        bm.faces.new(A); bm.faces.new(B[::-1])
        for k in range(4): bm.faces.new((A[k],B[k],B[(k+1)%4],A[(k+1)%4]))
    bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
    me=bpy.data.meshes.new('Brows'); bm.to_mesh(me); bm.free(); o=bpy.data.objects.new('Brows',me); bpy.context.scene.collection.objects.link(o)
    me.materials.append(mat('brow')); [setattr(p,'use_smooth',False) for p in me.polygons]; objs.append(o)
from mathutils.bvhtree import BVHTree
def trace_poly(mask,eps=1.2,step=3):
    m=mask.astype(np.uint8); cs,_=cv2.findContours(m,cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_NONE); c=max(cs,key=cv2.contourArea)[:,0,:]
    c=cv2.approxPolyDP(c.reshape(-1,1,2),eps,True)[:,0,:]
    out=[]
    for a,b in zip(c,np.roll(c,-1,0)):
        n=max(1,int(np.hypot(*(b-a))/step))
        for t in range(n): out.append(a+(b-a)*t/n)
    return np.array(out,float)
FRONTMAP=dict(FX0=1298,FY0=752,FK=1.04,EYEY=314)
def decal(bm,bvh,poly,key,off_rim=1.5,off_mid=1.5,back=1.5,view='side',rings=(0.66,0.33)):
    """Thin decal traced on the sheet, ray-cast onto the body. view='side' (rays along y, both sides) or 'front'
    (rays along -x from the nose, one copy). Domed decals (off_mid>off_rim) get interior rings so they hug the curve."""
    cen=poly.mean(0)
    sides=(1,-1) if view=='side' else (1,)
    for s_ in sides:
        def proj(x,y):
            if view=='side':
                hit=bvh.ray_cast(Vector((X(x),s_*600*S,Z(y))),Vector((0,-s_,0)))
            else:
                F=FRONTMAP; yy=(x-F['FX0'])*F['FK']; zz=F['EYEY']+(y-F['FY0'])*F['FK']
                hit=bvh.ray_cast(Vector((X(NOSE)+3.0,yy*S,Z(zz))),Vector((-1,0,0)))
            if hit[0] is None: return None,None
            n=hit[1]
            if view=='side' and n.y*s_<0: n=-n
            if view=='front' and n.x<0: n=-n
            return hit[0],n
        def ring(pts,off):
            R=[];NS=[]
            for x,y in pts:
                p,n=proj(x,y)
                if p is None: return None,None
                R.append(bm.verts.new(p+n*off*S)); NS.append(n)
            return R,NS
        A,NS=ring(poly,off_rim)
        if A is None: continue
        B=[]
        for v,n in zip(A,NS): B.append(bm.verts.new(v.co-n*(off_rim+back)*S))
        k=len(A); nav=sum(NS,Vector()).normalized(); want=[]
        if off_mid>off_rim+0.1:
            prev=A; ok=True
            for f_ in rings:
                pts=cen+(poly-cen)*f_
                Rr,_=ring(pts,off_rim+(off_mid-off_rim)*(1-f_*f_))
                if Rr is None: ok=False; break
                for i in range(k):
                    j=(i+1)%k; want.append((addf(bm,(prev[i],prev[j],Rr[j],Rr[i]),key),nav))
                prev=Rr
            pc,nc=proj(*cen); C=bm.verts.new(pc+nc*off_mid*S)
            for i in range(k): want.append((addf(bm,(prev[i],prev[(i+1)%k],C),key),nav))
        else:
            for t in geometry.tessellate_polygon([[Vector((x,y,0)) for x,y in poly]]): want.append((addf(bm,(A[t[0]],A[t[1]],A[t[2]]),key),nav))
        for t in geometry.tessellate_polygon([[Vector((x,y,0)) for x,y in poly]]): want.append((addf(bm,(B[t[2]],B[t[1]],B[t[0]]),key),-nav))
        area=sum(poly[i][0]*poly[(i+1)%k][1]-poly[(i+1)%k][0]*poly[i][1] for i in range(k))
        for i in range(k):
            j=(i+1)%k; f=addf(bm,(A[j],A[i],B[i],B[j]),key)
            ex,ey=poly[j]-poly[i]; ox,oy=(ey,-ex) if area>0 else (-ey,ex)
            out=Vector((ox,0,-oy)) if view=='side' else Vector((0,ox,-oy))
            out-=nav*out.dot(nav); want.append((f,out))
        for f,d in want:
            f.normal_update()
            if f.normal.dot(d)<0: f.normal_flip()
            DECALF.add(f)
DECALF=set()
def face_decals(bm):
    bm.normal_update(); bvh=BVHTree.FromBMesh(bm)
    box=np.zeros_like(side); box[285:340,1235:1305]=True
    iris=(IMG[...,0]>200)&(IMG[...,1]>180)&(IMG[...,2]<120)&box
    pup=(IMG.max(-1)<50)&box
    eye=ndi.binary_fill_holes(ndi.binary_closing(iris|pup,iterations=2))
    lab,n=ndi.label(eye); sz=ndi.sum(eye,lab,range(1,n+1)); eye=lab==(np.argmax(sz)+1)
    pm_=np.zeros_like(pup); pm_[298:332,1272:1300]=True
    pupil=ndi.binary_opening(pup&eye&pm_,iterations=1)
    bb=np.zeros_like(side); bb[270:345,1220:1345]=True
    sock=ndi.binary_fill_holes(ndi.binary_closing(((IMG.max(-1)<80)&bb)|eye,iterations=2))
    lab,n=ndi.label(sock); sz=ndi.sum(sock,lab,range(1,n+1)); sock=lab==(np.argmax(sz)+1)
    decal(bm,bvh,trace_poly(sock,1.0,4),'brow',2.0,2.0,1.5)
    decal(bm,bvh,trace_poly(eye,1.0,3),'eye',3.0,5.0,1.0)
    if pupil.sum()>20: decal(bm,bvh,trace_poly(pupil,1.0,3),'spot',5.3,6.0,-4.5,rings=(0.5,))
    st=(abs(IMG[...,0]-62)<22)&(abs(IMG[...,1]-94)<22)&(abs(IMG[...,2]-124)<22)&side
    body=np.zeros_like(st)
    for x in XS: body[int(yt(x))+4:int(csline(x))-2,x]=True
    st=ndi.binary_opening(st&body,iterations=2); st[:, 1180:]=False
    lab,n=ndi.label(st); sz=ndi.sum(st,lab,range(1,n+1))
    for i in range(n):
        if sz[i]<500: continue
        mm=lab==i+1; ys_=np.where(mm.any(1))[0]
        for ya in range(ys_.min(),ys_.max()+1,30):           # slice the slanted bands so chords hug the body
            sl=np.zeros_like(mm); sl[ya:ya+31]=mm[ya:ya+31]
            l2,n2=ndi.label(sl)
            for k2 in range(1,n2+1):
                if (l2==k2).sum()>=60: decal(bm,bvh,trace_poly(l2==k2,1.5,6),'spot',2.0,2.0,1.5)
def paddles(bm):
    pm=np.zeros_like(side); pm[355:430,890:1075]=side[355:430,890:1075]
    col=(abs(IMG[...,0]-62)<25)&(abs(IMG[...,2]-122)<30)
    m=ndi.binary_fill_holes(ndi.binary_closing(pm&col,iterations=3)); m=ndi.binary_opening(m,iterations=2)
    lab,n=ndi.label(m); sz=ndi.sum(m,lab,range(1,n+1)); m=ndi.binary_fill_holes(lab==(np.argmax(sz)+1))
    poly=trace_poly(m,1.5,6); xr=poly[:,0].max(); L=xr-poly[:,0].min()  # front 30% of the fin is its root, sunk into the body
    for s_ in (1,-1):
        pts=[Vector((X(x),s_*(surf_lat(x,y)*0.85+max(0,(xr-x)-0.3*L)*1.6)*S,Z(y+max(0,xr-x)*0.25))) for x,y in poly]
        nrm=(pts[len(pts)//3]-pts[0]).cross(pts[2*len(pts)//3]-pts[0]); nrm.normalize()
        plate(bm,pts,nrm*2.5*S,'fin')
def armpit(bm):
    # the great white's dark "armpit" spot behind the pectoral fin (side sheet: ellipse at 840,410)
    for s_ in (1,-1):
        pts=[]
        for k in range(10):
            a=2*math.pi*k/10; x=840+26*math.cos(a); y=410+9*math.sin(a)
            pts.append(Vector((X(x),s_*(surf_lat(x,y)+2.5)*S,Z(y))))
        plate(bm,pts,Vector((0,s_*1.0*S,0)),'spot')
def colour(me,keys):
    names=list(P.keys())
    for nm in names: me.materials.append(mat(nm))
    idx={nm:i for i,nm in enumerate(names)}
    for p,key in zip(me.polygons,keys):
        c=p.center; n=p.normal; px=PX(c.x); py=PY(c.z)
        if key=='body' or key=='head_front':
            if CORNER+2<px<=1487 and lip_up(px)+0.5<py<lip_lo(px)-0.5: k='maroon'
            elif n.z<-0.55: k='white'
            elif py>csline(px): k='white' if n.dot(L)>-0.2 else 'white_d'
            else: k=tone(n,'teal')
        elif key=='fin': k=tone(n,'fin')
        else: k=key
        p.material_index=idx[k]; p.use_smooth=False
def fix_normals_parity(me,skip=()):
    """Roblox draws one side only: per connected island, flip every face whose normal points INTO its own island
    (odd number of hits when shooting a ray along the normal against that island alone)."""
    from mathutils.bvhtree import BVHTree
    bm=bmesh.new(); bm.from_mesh(me); bm.faces.ensure_lookup_table(); bm.normal_update()
    seen=set(); flipped=0
    for f0 in bm.faces:
        if f0.index in seen: continue
        isl=[]; stack=[f0]; seen.add(f0.index)
        while stack:
            f=stack.pop(); isl.append(f)
            for e in f.edges:
                for g in e.link_faces:
                    if g.index not in seen: seen.add(g.index); stack.append(g)
        verts=list({v for f in isl for v in f.verts}); vi={v:i for i,v in enumerate(verts)}
        bvh=BVHTree.FromPolygons([v.co.copy() for v in verts],[[vi[v] for v in f.verts] for f in isl])
        for f in isl:
            if f.index in skip or f.calc_area()<1e-10: continue
            c=f.calc_center_median(); n=f.normal.copy(); votes=0
            for d in (n,(n+Vector((0.013,0.021,-0.017))).normalized()):
                o=c+d*1e-5; hits=0
                for _ in range(60):
                    h=bvh.ray_cast(o,d)
                    if h[0] is None: break
                    hits+=1; o=h[0]+d*1e-5
                votes+=hits%2
            if votes==2: f.normal_flip(); flipped+=1
    bm.to_mesh(me); bm.free(); return flipped
def build():
    clear(); FACES.clear()
    bm=bmesh.new(); body(bm); face_decals(bm); fins(bm); teeth(bm); paddles(bm)
    keys=[k for _,k in FACES]
    # keep face order = key order
    me=bpy.data.meshes.new('Barracuda'); bm.to_mesh(me); bm.free()
    ob=bpy.data.objects.new('Barracuda',me); bpy.context.scene.collection.objects.link(ob)
    # outward normals: per island, flip so faces point away from the island's own centre line
    bm2=bmesh.new(); bm2.from_mesh(me); bm2.faces.ensure_lookup_table()
    for f,key in zip(bm2.faces,keys):
        c=f.calc_center_median()
        if key in ('body','head_front'):
            px=PX(c.x); pxc=min(max(px,300),1488); ax=Vector((c.x,0,Z((yt(pxc)+(JAWB(pxc) if 1150<pxc<=1487 else yb(pxc)))/2)))
            if f.normal.dot(c-ax)<0: f.normal_flip()
    bm2.to_mesh(me); bm2.free()
    print('parity flips',fix_normals_parity(me,{i for i,k in enumerate(keys) if k in ('eye','brow','glow','spot')}))
    bmc=bmesh.new(); bmc.from_mesh(me); bmc.faces.ensure_lookup_table(); bmc.normal_update()
    for f,key in zip(bmc.faces,keys):
        if key=='body':
            c=f.calc_center_median()
            if 99999<PX(c.x)<99990 and abs(f.normal.x)>0.8 and f.normal.x<0: f.normal_flip()
            elif 99999<PX(c.x)<99990 and abs(f.normal.y)>0.5 and f.normal.y*c.y<0: f.normal_flip()
            elif PX(c.x)>99999:
                ax=Vector((c.x,0,Z((yt(min(PX(c.x),1488))+min(yb(min(PX(c.x),1488)),UPJAW(min(PX(c.x),1488))))/2)))
                if f.normal.dot(c-ax)<0: f.normal_flip()
    # teeth are convex prisms: every face points away from its own tooth's centre
    tf=[(f,k) for f,k in zip(bmc.faces,keys) if k=='tooth']
    seen=set()
    for f,_ in tf:
        if f.index in seen: continue
        isl=[]; st=[f]; seen.add(f.index)
        while st:
            g=st.pop(); isl.append(g)
            for e in g.edges:
                for h in e.link_faces:
                    if h.index not in seen: seen.add(h.index); st.append(h)
        cen=sum((v.co for g in isl for v in g.verts),Vector())/sum(len(g.verts) for g in isl)
        for g in isl:
            if g.normal.dot(g.calc_center_median()-cen)<0: g.normal_flip()
    bmc.to_mesh(me); bmc.free()
    pass
    colour(me,keys)
    extra=[]
    return ob,extra
ob,extra=build()
EXTRA=extra
print('faces',len(ob.data.polygons),'tris',sum(len(p.vertices)-2 for p in ob.data.polygons))

def rig(sh, bones=8):
    global EXTRA
    sc = bpy.context.scene
    # one mesh for Roblox: join the eyes and brows into the body
    bpy.ops.object.select_all(action="DESELECT")
    for o in EXTRA: o.select_set(True)
    sh.select_set(True); bpy.context.view_layer.objects.active = sh; bpy.ops.object.join(); EXTRA = []
    # lower-jaw teeth islands (their base sits on the lower lip) go with the Jaw bone
    me = sh.data; tooth = [i for i, m in enumerate(me.materials) if m.name == 'BC_tooth'][0]
    import bmesh as _bm
    b = _bm.new(); b.from_mesh(me); b.verts.ensure_lookup_table(); b.faces.ensure_lookup_table()
    JAWV = set(); seen = set()
    for f in b.faces:
        if f.material_index != tooth or f.index in seen: continue
        isl = set(); st = [f]
        while st:
            g = st.pop()
            if g.index in seen: continue
            seen.add(g.index); isl.add(g)
            for e in g.edges:
                for h in e.link_faces:
                    if h.material_index == tooth and h.index not in seen: st.append(h)
        vs = {v for g in isl for v in g.verts}
        base = max(PY(v.co.z) for v in vs); pxm = sum(PX(v.co.x) for v in vs) / len(vs)
        if base >= lip_lo(pxm) - 3: JAWV |= {v.index for v in vs}
    b.free()
    arm = bpy.data.armatures.new("BarracudaRig"); ob = bpy.data.objects.new("BarracudaRig", arm)
    sc.collection.objects.link(ob); bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    x0, x1 = X(1450), X(100)
    xs = [x0 - i * (x0 - x1) / bones for i in range(bones + 1)]
    rb = arm.edit_bones.new("Root"); rb.head = (0, 0, 0); rb.tail = (0.4, 0, 0)
    prev = rb
    for i in range(bones):
        b = arm.edit_bones.new(f"Spine{i}"); b.head = (xs[i], 0, 0); b.tail = (xs[i + 1], 0, 0)
        b.parent = prev; b.use_connect = i > 0; prev = b
    j = arm.edit_bones.new("Jaw"); j.head = (X(CORNER) - 0.03, 0, Z(372)); j.tail = (X(1480), 0, Z(385)); j.parent = arm.edit_bones["Spine0"]
    bpy.ops.object.mode_set(mode="OBJECT")
    for o in [sh] + EXTRA:
        bpy.ops.object.select_all(action="DESELECT"); o.select_set(True); ob.select_set(True); bpy.context.view_layer.objects.active = ob
        bpy.ops.object.parent_set(type="ARMATURE_NAME")
    seg = (xs[0] - xs[-1]) / bones
    for o in [sh] + EXTRA:
        groups = [o.vertex_groups.get(f"Spine{i}") or o.vertex_groups.new(name=f"Spine{i}") for i in range(bones)]
        jg = o.vertex_groups.get("Jaw") or o.vertex_groups.new(name="Jaw")
        for v in o.data.vertices:
            c = o.matrix_world @ v.co
            px, py = PX(c.x), PY(c.z)
            if o is sh and (v.index in JAWV or (CORNER - 4 < px < 1495 and py > lip_lo(px) - 3 and abs(c.y) < 140 * S)):
                jg.add([v.index], 1.0, "REPLACE"); continue
            u = (xs[0] - c.x) / seg - 0.5
            ws = sorted(((math.exp(-((u - k) / 0.75) ** 2), k) for k in range(bones)), reverse=True)[:3]
            tot = sum(w for w, _ in ws)
            for w, k in ws: groups[k].add([v.index], w / tot, "REPLACE")
    make_clips(ob, bones)
    return ob
FPS = 30
CLIPS = {}
def ss(x):  # smootherstep 0..1
    x = min(max(x, 0.0), 1.0); return x * x * x * (x * (6 * x - 15) + 10)
def make_clips(ob, bones):
    sc = bpy.context.scene
    bpy.context.view_layer.objects.active = ob; bpy.ops.object.mode_set(mode="POSE")
    ob.animation_data_create()
    for pb in ob.pose.bones: pb.rotation_mode = "XYZ"
    sp = [ob.pose.bones[f"Spine{i}"] for i in range(bones)]; jaw = ob.pose.bones["Jaw"]; root = ob.pose.bones["Root"]
    xs = [b.head_local.x for b in [ob.data.bones[f"Spine{i}"] for i in range(bones)]] + [ob.data.bones[f"Spine{bones-1}"].tail_local.x]
    Ltot = xs[0] - xs[-1]; seglen = Ltot / bones
    us = [(xs[0] - x) / Ltot for x in xs]                        # 0 = nose .. 1 = tail tip, at the joints
    mass = [max(0.05, hw(min(max(PX(x),300),1488))*S) ** 2 for x in xs]  # cross-section area ~ weight (traced top view)
    def recentre(vals):
        # remove the mass-weighted mean offset and mean slope: the body's centre and heading stay put
        W = sum(mass); mu = sum(m * u for m, u in zip(mass, us)) / W; mv = sum(m * v for m, v in zip(mass, vals)) / W
        cov = sum(m * (u - mu) * (v - mv) for m, u, v in zip(mass, us, vals)); var = sum(m * (u - mu) ** 2 for m, u in zip(mass, us))
        b = cov / var if var else 0.0
        return [v - (mv + b * (u - mu)) for u, v in zip(us, vals)]
    def solve(curve):   # joint offsets -> absolute segment angles (yaw: +angle sends the tail to -Y)
        return [-math.atan2(curve[k + 1] - curve[k], seglen) for k in range(bones)]
    def rel(absl): return [absl[0]] + [absl[k] - absl[k - 1] for k in range(1, len(absl))]
    def clip(name, length, fn, loop=True, centre=True):
        act = bpy.data.actions.get(name)
        if act: bpy.data.actions.remove(act)
        act = bpy.data.actions.new(name); act.use_fake_user = True; ob.animation_data.action = act
        for fr in range(0, length + 1):
            t = (fr % length) / length if loop else fr / length
            ylat, zver, jawang, fwd = fn(t)
            if centre: ylat = recentre(ylat)
            yaw = solve(ylat); pit = [-a for a in solve(zver)]
            ry, rp = rel(yaw), rel(pit)
            for k, pb in enumerate(sp):
                pb.rotation_euler = (rp[k], 0, ry[k]); pb.keyframe_insert("rotation_euler", frame=fr)
            jaw.rotation_euler = (math.radians(jawang), 0, 0); jaw.keyframe_insert("rotation_euler", frame=fr)
            root.location = (-ylat[0], fwd, zver[0]); root.keyframe_insert("location", frame=fr)
        for fc in getattr(act, "fcurves", []):
            for kp in fc.keyframe_points: kp.interpolation = "LINEAR"   # every frame is keyed: no Bezier overshoot
        act["frame_range"] = (0, length); act["loop"] = loop; act["fps"] = FPS
        CLIPS[name] = (act, length)
    flat = [0.0] * (bones + 1)
    def env(u):  # carangiform amplitude envelope (fraction of body length): small at the head, big at the tail
        return 0.008 - 0.03 * u + 0.11 * u * u
    def wave(t, scale, cycles=1.0, wavelength=1.0):
        return [scale * Ltot * env(u) * math.sin(2 * math.pi * (cycles * t - u / wavelength)) for u in us]
    # IDLE 2 s loop: slow, small sway; the jaw breathes
    clip("Idle", 60, lambda t: (wave(t, 0.45), flat, -2.5 + 2.5 * math.sin(2 * math.pi * t), 0))
    # SWIM 1 s loop: one full tail beat, about one body-length wave
    clip("Swim", 30, lambda t: (wave(t, 0.75), flat, -1.5 + 1.2 * math.sin(2 * math.pi * t - 1.0), 0))
    # DART 0.8 s: smooth coil, two strong tail beats, fades back to straight
    def dart(t):
        a = ss(t / 0.2) * (1 - ss((t - 0.35) / 0.65)) ** 1.2
        y = [2.6 * a * Ltot * env(u) * math.sin(2 * math.pi * (2.2 * t - u * 0.9) - 0.6) for u in us]
        return y, flat, -4 * a, 0
    clip("Dart", 24, dart, loop=False)
    # BITE 0.5 s: anticipation (head up, jaw gapes) -> fast snap (head down, jaw shut, lunge) -> overshoot -> settle
    def bite(t):
        up = ss(t / 0.38)                       # 0..0.38 anticipation
        snap = ss((t - 0.38) / 0.22)            # 0.38..0.6 the snap (~4 frames: fast but readable, no pop)
        settle = ss((t - 0.6) / 0.4)            # back to rest
        bounce = math.sin(math.pi * min(max((t - 0.6) / 0.4, 0), 1) * 2) * 0.25 * (1 - settle)
        head = 0.10 * up - 0.16 * snap * (1 - settle) - 0.10 * up * snap   # metres the nose moves up(+)/down(-)
        head += 0.04 * bounce
        z = [head * max(0.0, 1 - u / 0.4) ** 2 for u in us]
        j = -16 * up * (1 - snap) + 24 * snap * (1 - settle) + 6 * bounce
        fw = 0.32 * snap * (1 - settle)
        return flat, z, j, fw
    clip("Bite", 18, bite, loop=False)
    # SHARK SENSE 1.5 s: slows to a glide, the HEAD scans left-right twice (body counter-sways), jaw eases half shut
    def sense(t):
        e = ss(t / 0.15) * (1 - ss((t - 0.8) / 0.2))
        sweep = 0.22 * e * math.sin(2 * math.pi * 2 * t)
        y = [sweep * max(0.0, 1 - u / 0.45) ** 2 for u in us]
        y = [a + b for a, b in zip(y, wave(t * 1.5, 0.3 * (1 - e) + 0.15))]
        return y, flat, 9 * e, 0
    clip("SharkSense", 45, sense, loop=False)
    # HURT 0.5 s: a jolt into a C-bend that shakes out smoothly (cartoon, no blood)
    def hurt(t):
        J = 0.30 * math.sin(2 * math.pi * 2.5 * t) * math.exp(-5 * t) * (1 - math.exp(-40 * t)) * (1 - ss((t - 0.8) / 0.2))
        y = [J * (4 * (u - 0.5) ** 2 - 1 / 3) for u in us]
        return y, flat, -10 * math.exp(-5 * t) * (1 - ss((t - 0.8) / 0.2)), 0
    clip("Hurt", 15, hurt, loop=False)
    # TORPEDO 0.9 s: coil (S-bend, pulled back), then a straight-as-an-arrow launch with stiff tiny tail flicks, settle
    def torpedo(t):
        coil = ss(t / 0.22) * (1 - ss((t - 0.22) / 0.08))
        go = ss((t - 0.24) / 0.06) * (1 - ss((t - 0.7) / 0.3))
        y = [0.10 * coil * math.sin(math.pi * 2 * u) for u in us]
        y = [a + b for a, b in zip(y, wave(t * 4.0, 0.25 * go))]
        fw = -0.15 * coil + 0.55 * go
        jaw = -10 * go
        return y, flat, jaw, fw
    clip("Torpedo", 27, torpedo, loop=False)
    ob.animation_data.action = CLIPS["Swim"][0]
    bpy.ops.object.mode_set(mode="OBJECT")
    sc.render.fps = FPS; sc.frame_start, sc.frame_end = 0, 29; sc.frame_set(0)   # 30 = 0 again: preview loops without a repeated frame


if globals().get('WITH_RIG',True):
    RIGOB=rig(ob)
    print('rigged', list(CLIPS.keys()))
