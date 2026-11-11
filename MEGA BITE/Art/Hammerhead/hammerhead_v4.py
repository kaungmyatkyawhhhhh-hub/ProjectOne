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
IMG=np.array(Image.open('Hammerhead_sheet_chatgpt.png').convert('RGB')).astype(int)
side=np.load('side.npy'); top=np.load('top.npy'); front=np.load('front.npy')
S=4.0/1408; NOSE=1471; BASEZ=300
def X(px): return (px-NOSE)*S
def Z(py): return (BASEZ-py)*S
def PX(x): return NOSE+x/S
def PY(z): return BASEZ-z/S
K=1.698431845597105; TX0,TY0=48,799
FK=1.038; FX0,FY0=1232,780
def top2side(xt,yt): return 63+(xt-TX0)*K,(yt-TY0)*K
# ---------- profiles
def col_edges(m,x):
    c=np.where(m[:,int(x)])[0]; return (c.min(),c.max()) if len(c) else (None,None)
def patch(xs,arr,rngs):
    arr=arr.copy()
    for a,b in rngs:
        i=np.searchsorted(xs,a); j=np.searchsorted(xs,b); arr[i:j+1]=np.linspace(arr[i],arr[j],j-i+1)
    return arr
XS=np.arange(330,1472)
YT=np.array([col_edges(side,x)[0] for x in XS],float); YB=np.array([col_edges(side,x)[1] for x in XS],float)
YT=ndi.gaussian_filter1d(patch(XS,YT,[(482,575),(728,1072)]),3); YB=ndi.gaussian_filter1d(patch(XS,YB,[(432,500),(596,676),(722,1052)]),3)
def yt(px): return float(np.interp(px,XS,YT))
def yb(px): return float(np.interp(px,XS,YB))
HW=[]
for x in XS:
    xt=int(round(TX0+(x-63)/K)); lab,_=ndi.label(top[:,min(max(xt,0),top.shape[1]-1)]); l=lab[TY0]
    HW.append((np.where(lab==l)[0].max()-TY0)*K if l else 0)
HW=patch(XS,np.array(HW,float),[(560,700),(839,1190)]); H_=YB-YT
HW=ndi.gaussian_filter1d(np.clip(HW,0.34*H_,0.56*H_),6)
def hw(px): return float(np.interp(px,XS,HW))
# countershade line (top of the white belly) traced per column from the sheet, light smoothing keeps the zig-zag
WH=(IMG.min(-1)>185)&side
CS=[]
for x in XS:
    c=np.where(WH[int(yt(x))+5:int(yb(x)),x])[0]
    CS.append(c.min()+int(yt(x))+5 if len(c) else yb(x))
CS=np.array(CS,float); CS=np.clip(CS,YT+0.35*(YB-YT),YB-5)
CS=patch(XS,CS,[(1040,1160)])           # the gill slits sit on the line: bridge them
CS=ndi.gaussian_filter1d(CS,2)
def csline(px): return float(np.interp(px,XS,CS))
# ---------- palette (from the sheet)
P=dict(teal_l=(104,150,142),teal_m=(84,125,117),teal_d=(64,101,95),fin_l=(78,118,110),fin_m=(56,92,86),fin_d=(36,66,63),
       white=(232,236,241),white_d=(200,206,214),maroon=(110,32,48),tooth=(250,250,248),eye=(63,242,255),gill=(30,56,54),brow=(40,70,67))
def lin(c): c=np.array(c)/255.0; return tuple(np.where(c<=0.04045,c/12.92,((c+0.055)/1.055)**2.4))
MATS={}
def mat(name):
    if name in MATS: return MATS[name]
    m=bpy.data.materials.get('HH_'+name) or bpy.data.materials.new('HH_'+name); m.use_nodes=True
    b=m.node_tree.nodes['Principled BSDF']; b.inputs['Base Color'].default_value=(*lin(P[name]),1); b.inputs['Roughness'].default_value=0.8
    if name=='eye': b.inputs['Emission Color'].default_value=(*lin(P[name]),1); b.inputs['Emission Strength'].default_value=4
    MATS[name]=m; return m
L=Vector((-0.35,-0.6,0.72)).normalized()
def tone(n,base):
    d=n.dot(L)
    return base+('_l' if (n.z>0.75 or d>0.72) else ('_m' if d>0.1 else '_d'))
# ---------- mouth geometry (side px), traced on the sheet's head
CORNER=1232
def lip_up(px):  return float(np.interp(px,[1232,1300,1370,1400],[342,344,347,343]))
def lip_lo(px):  return float(np.interp(px,[1232,1262,1300,1336,1352,1372],[342,366,384,394,397,397]))
# the lower jaw's underside (side sheet), and the jaw ends at x=1356 (the upper jaw + snout carry on under the hammer)
JAWB=lambda px: float(np.interp(px,[1180,1232,1300,1330,1348,1356],[yb(1180),426,437,433,420,402]))
HAM_BOT=lambda px: float(np.interp(px,[1300,1372,1420,1471],[333,332,318,302]))
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
    stations=list(range(330,1000,20))+list(range(1000,1356,12))+[1356,1357,1366,1376]
    rings=[]
    for px in stations:
        ybot=yb(px)
        if px>1180: ybot=JAWB(px) if px<=1356 else min(yb(px),lip_up(px)+8)
        zc=(yt(px)+ybot)/2; hh=(ybot-yt(px))/2; w=hw(px)
        if px>1220: w=max(w*0.55,98-0.3*max(0,px-1330))
        lv=ring_levels(px,zc,hh)
        right=[(float(np.interp(-v,-HV,HU)),v) for v in lv]
        pts=right+[(-u,v) for u,v in reversed(right[1:-1])]
        r=[]
        for u,v in pts:
            py=zc-v*hh; lat=u*w
            if px>CORNER+2 and lip_up(px)+1.0<py<lip_lo(px)-1.0:
                depth=min(1.0,(px-CORNER)/40.0)          # the gape deepens from the mouth corner forward
                lat*=1-0.72*depth
            r.append(bm.verts.new((X(px),lat*S,Z(py))))
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
    finm=side&~ndi.binary_dilation(body_m,iterations=2); finm[:,:330]=side[:,:330]
    lab,n=ndi.label(ndi.binary_opening(finm,iterations=2)); sizes=ndi.sum(finm,lab,range(1,n+1))
    for i in np.argsort(-sizes)[:6]:
        m=(lab==i+1).astype(np.uint8); ys,xs=np.where(m); cx,cy=xs.mean(),ys.mean()
        cs,_=cv2.findContours(m,cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_NONE); cnt=max(cs,key=cv2.contourArea)
        poly=cv2.approxPolyDP(cnt,2.5,True)[:,0,:]
        below=cy>yb(min(max(cx,330),1471))-10
        if cx<330 or not below or not (596<cx<1060):
            pts=[Vector((X(x),0,Z(y))) for x,y in embed_flat(poly,cx,cy)]
            plate(bm,pts,Vector((0,(8 if cx<330 else 6)*S,0)),'fin'); continue
        pect=cx>722; rootz=yb(cx)-(25 if pect else 6)
        for s in (1,-1):
            pts=[]
            for x,y in poly:
                x=float(x); y=float(y)
                if y<yb(cl(x))+10:            # root edge tucked up into the belly side
                    y2=yb(cl(x))-24; _p=Vector((X(x),s*0.75*blat(x,y2)*S,Z(y2)))
                    if not pts or (pts[-1]-_p).length>3*S: pts.append(_p)
                    continue
                d=max(0,y-rootz); lat=(70+d*1.75) if pect else (34+d*0.7)
                _d0=d; d=0; _b=(70+d*1.75) if pect else (34+d*0.7); d=_d0; lat=lat-_b+0.75*blat(x,yb(cl(x))-24)
                pts.append(Vector((X(x),s*lat*S,Z(y))))
            # thickness along the fin's own normal
            nrm=(pts[len(pts)//3]-pts[0]).cross(pts[2*len(pts)//3]-pts[0]); nrm.normalize()
            plate(bm,pts,nrm*5*S,'fin')
def gills(bm):
    dark=(IMG.sum(-1)<230)&side; sub=np.zeros_like(dark); sub[270:400,1035:1160]=dark[270:400,1035:1160]
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
    def arcpt(th,zpx):
        px=1372-142*(1-math.cos(th))**1.15; lat=74*math.sin(th)
        return px,lat
    for row,(n,span,ln,base) in enumerate([(9,1.40,32,'up'),(7,1.25,27,'lo')]):
        for i in range(n):
            th=-span+2*span*i/(n-1)
            px,lat=arcpt(th,0)
            big=1.0+0.35*math.cos(th*1.6)          # front teeth bigger
            L_=ln*big; W_=19*big
            zb=lip_up(px)-1 if base=='up' else lip_lo(px)+1
            tip=zb+L_ if base=='up' else zb-L_
            # tooth = triangular prism facing out along the arc normal
            nrm=Vector((math.cos(th),math.sin(th),0)); tang=Vector((-math.sin(th),math.cos(th),0))
            c=Vector((X(px),lat*S,0))-nrm*2*S
            p0=c+tang*(W_/2)*S; p1=c-tang*(W_/2)*S
            pts=[Vector((p0.x,p0.y,Z(zb))),Vector((p1.x,p1.y,Z(zb))),Vector((c.x,c.y,Z(tip)))]
            plate(bm,pts,nrm*3.5*S,'tooth')
def eyes_brows(objs):
    for s in (1,-1):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=10,ring_count=6,radius=18*S,location=(X(1432),s*222*S,Z(297)))
        e=bpy.context.object; e.name='Eye_'+('L' if s>0 else 'R'); e.scale=(0.95,0.75,1); e.data.materials.append(mat('eye'))
        for p in e.data.polygons: p.use_smooth=False
        objs.append(e)
    bm=bmesh.new()
    for s in (1,-1):
        # brow wedge over each eye: angled down toward the front (angry), from the sheet's head close-up
        pts=[Vector((X(1398),s*206*S,Z(281))),Vector((X(1456),s*214*S,Z(276))),Vector((X(1452),s*240*S,Z(282))),Vector((X(1400),s*236*S,Z(290)))]
        A=[bm.verts.new(p+Vector((0,0,5*S))) for p in pts]; B=[bm.verts.new(p-Vector((0,0,8*S))) for p in pts]
        bm.faces.new(A); bm.faces.new(B[::-1])
        for k in range(4): bm.faces.new((A[k],B[k],B[(k+1)%4],A[(k+1)%4]))
    bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
    me=bpy.data.meshes.new('Brows'); bm.to_mesh(me); bm.free(); orient_convex_islands(me,None,()); o=bpy.data.objects.new('Brows',me); bpy.context.scene.collection.objects.link(o)
    me.materials.append(mat('brow')); [setattr(p,'use_smooth',False) for p in me.polygons]; objs.append(o)
def colour(me,keys):
    names=list(P.keys())
    for nm in names: me.materials.append(mat(nm))
    idx={nm:i for i,nm in enumerate(names)}
    for p,key in zip(me.polygons,keys):
        c=p.center; n=p.normal; px=PX(c.x); py=PY(c.z)
        if key=='body' or key=='head_front':
            if px>CORNER+2 and lip_up(px)+0.5<py<lip_lo(px)-0.5: k='maroon'
            elif n.z<-0.55: k='white'
            elif py>csline(px) or (px>1240 and py>HAM_BOT(px)-2): k='white' if n.dot(L)>-0.2 else 'white_d'
            else: k=tone(n,'teal')
        elif key=='hammer': k='white' if n.z<-0.35 else tone(n,'teal')
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
def fix_hammer_normals(me,keys):
    """The cephalofoil is convex in every cross-section across its span: orient each face away from the
    centre of its own lateral slice (the ray-parity test fails on its bevels)."""
    bm=bmesh.new(); bm.from_mesh(me); bm.faces.ensure_lookup_table(); bm.normal_update()
    hf=[f for f,k in zip(bm.faces,keys) if k=='hammer']
    hv=list({v for f in hf for v in f.verts}); ys=np.array([v.co.y for v in hv]); P=np.array([v.co[:] for v in hv])
    n=0
    for f in hf:
        c=f.calc_center_median(); band=np.abs(ys-c.y)<12*S
        if band.sum()<3: band=np.abs(ys-c.y)<30*S
        m=P[band].mean(0); cen=Vector((m[0],c.y,m[2]))
        d=c-cen
        if d.length<1e-6: continue
        if f.normal.dot(d)<0: f.normal_flip(); n+=1
    bm.to_mesh(me); bm.free(); print('hammer flips',n)
def orient_convex_islands(me,keys,which):
    """Small convex pieces (teeth, brow wedges): every face points away from its own island's centre."""
    bm=bmesh.new(); bm.from_mesh(me); bm.faces.ensure_lookup_table(); bm.normal_update()
    seen=set(); n=0
    for f0 in bm.faces:
        if f0.index in seen or (keys is not None and keys[f0.index] not in which): continue
        isl=[]; st=[f0]; seen.add(f0.index)
        while st:
            g=st.pop(); isl.append(g)
            for e in g.edges:
                for h in e.link_faces:
                    if h.index not in seen: seen.add(h.index); st.append(h)
        cen=sum((v.co for g in isl for v in g.verts),Vector())/sum(len(g.verts) for g in isl)
        for g in isl:
            if g.normal.dot(g.calc_center_median()-cen)<0: g.normal_flip(); n+=1
    bm.to_mesh(me); bm.free(); return n
def build():
    clear(); FACES.clear()
    bm=bmesh.new(); body(bm); hammer(bm); fins(bm); gills(bm); teeth(bm)
    keys=[k for _,k in FACES]
    # keep face order = key order
    me=bpy.data.meshes.new('Hammerhead'); bm.to_mesh(me); bm.free()
    ob=bpy.data.objects.new('Hammerhead',me); bpy.context.scene.collection.objects.link(ob)
    # outward normals: per island, flip so faces point away from the island's own centre line
    bm2=bmesh.new(); bm2.from_mesh(me); bm2.faces.ensure_lookup_table()
    for f,key in zip(bm2.faces,keys):
        c=f.calc_center_median()
        if key in ('body','head_front'):
            px=PX(c.x); ax=Vector((c.x,0,Z((yt(min(max(px,330),1471))+yb(min(max(px,330),1471)))/2)))
            if f.normal.dot(c-ax)<0: f.normal_flip()
        elif key=='hammer':
            px=PX(c.x); ax=Vector((c.x,c.y,Z((yt(px)+HAM_BOT(px))/2)))
            if f.normal.dot(c-ax)<0: f.normal_flip()
    bm2.to_mesh(me); bm2.free()
    print('parity flips',fix_normals_parity(me,{i for i,k in enumerate(keys) if k=='hammer'}))
    fix_hammer_normals(me,keys)
    print('tooth flips',orient_convex_islands(me,keys,('tooth',)))
    colour(me,keys)
    extra=[]; eyes_brows(extra)
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
    me = sh.data; tooth = [i for i, m in enumerate(me.materials) if m.name == 'HH_tooth'][0]
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
    arm = bpy.data.armatures.new("HammerheadRig"); ob = bpy.data.objects.new("HammerheadRig", arm)
    sc.collection.objects.link(ob); bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    x0, x1 = X(1420), X(150)
    xs = [x0 - i * (x0 - x1) / bones for i in range(bones + 1)]
    rb = arm.edit_bones.new("Root"); rb.head = (0, 0, 0); rb.tail = (0.4, 0, 0)
    prev = rb
    for i in range(bones):
        b = arm.edit_bones.new(f"Spine{i}"); b.head = (xs[i], 0, 0); b.tail = (xs[i + 1], 0, 0)
        b.parent = prev; b.use_connect = i > 0; prev = b
    j = arm.edit_bones.new("Jaw"); j.head = (X(CORNER) - 0.03, 0, Z(352)); j.tail = (X(1352), 0, Z(400)); j.parent = arm.edit_bones["Spine0"]
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
            if o is sh and (v.index in JAWV or (CORNER - 4 < px < 1362 and py > lip_lo(px) - 3 and abs(c.y) < 120 * S)):
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
    mass = [max(0.05, hw(min(max(PX(x),330),1471))*S) ** 2 for x in xs]  # cross-section area ~ weight (traced top view)
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
    # HAMMER RAM 1.0 s: coil back (head up), charge (body straight, head drives DOWN like a battering ram, lunge),
    # impact shake of the hammer, recover
    def ram(t):
        coil = ss(t / 0.3) * (1 - ss((t - 0.3) / 0.15))
        hit = ss((t - 0.3) / 0.15) * (1 - ss((t - 0.62) / 0.38))
        shake = math.sin(2 * math.pi * 9 * t) * math.exp(-8 * max(0.0, t - 0.45)) * (t > 0.45) * 0.05
        head = 0.12 * coil - 0.14 * hit
        z = [head * max(0.0, 1 - u / 0.45) ** 2 for u in us]
        y = [shake * max(0.0, 1 - u / 0.35) for u in us]
        y = [a + b for a, b in zip(y, wave(t, 0.25 * coil))]
        return y, z, -6 * coil + 10 * hit, 0.45 * hit
    clip("HammerRam", 30, ram, loop=False)
    ob.animation_data.action = CLIPS["Swim"][0]
    bpy.ops.object.mode_set(mode="OBJECT")
    sc.render.fps = FPS; sc.frame_start, sc.frame_end = 0, 29; sc.frame_set(0)   # 30 = 0 again: preview loops without a repeated frame


if globals().get('WITH_RIG',True):
    RIGOB=rig(ob)
    print('rigged', list(CLIPS.keys()))
