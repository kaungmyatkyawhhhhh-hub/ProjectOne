"""MEGA BITE fish kit v2 (11 Nov): the approved Minnow v2b look for every species.
Smooth superellipse lofts traced from a ChatGPT turnaround sheet (side heights, top widths), less-toy proportions
(height x HS, width x WY), rule-based colours from the sheet's palette (nearest colour, smoothed one-hot), fine scales +
countershading baked in, cute glossy eyes, pillow fins traced from the silhouette, a fine inverted-hull edge line, and
(for biters) a real mouth: the upper head and the lower jaw are separate lofts so the Jaw bone opens a dark-red mouth
with teeth. Writes out/<name>_geo.json + out/<name>_tex.png + out/<name>_cls.npy for build.py."""
import numpy as np, json, math, cv2, sys, os
from PIL import Image
from scipy import ndimage as ndi
from scipy.spatial import Delaunay

def run(C):
    D=C['dir']; os.makedirs(D+'/out',exist_ok=True)
    SH=np.array(Image.open(D+'/sheet.png').convert('RGB')).astype(np.float32)
    Hh,Ww,_=SH.shape
    dmag=np.sqrt(((SH-[255,0,255])**2).sum(-1))
    lab,n=ndi.label(dmag<90)
    border=set(np.unique(np.concatenate([lab[0],lab[-1],lab[:,0],lab[:,-1]])))-{0}
    fg=ndi.binary_opening(~np.isin(lab,list(border)),iterations=1)
    lab,n=ndi.label(fg); sizes=ndi.sum(fg,lab,range(1,n+1))
    views={}
    for c in [i+1 for i in np.argsort(-sizes)[:3]]:
        ys,xs=np.where(lab==c); cx,cy=xs.mean(),ys.mean()
        name='side' if cy<Hh*0.47 else ('top' if cx<Ww*0.55 else 'front')
        views[name]=lab==c
    side=views['side']; top=views['top']; front=views['front']
    # body = silhouette with the thin fins opened away
    def body_of(m,r):
        k=cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(2*r+1,2*r+1))
        b=cv2.morphologyEx(m.astype(np.uint8),cv2.MORPH_OPEN,k)>0
        l,nn=ndi.label(b); s=ndi.sum(b,l,range(1,nn+1)); return l==(np.argmax(s)+1)
    finc=None
    if C.get('fin_rule'):
        R_,G_,B_=SH[...,0],SH[...,1],SH[...,2]
        finc=eval(C['fin_rule'],{"np":np,"R":R_,"G":G_,"B":B_})
        finc=ndi.binary_closing(finc,iterations=2)
        def body_c(m,r):
            b=m&~finc; b=body_of(b,r); return ndi.binary_fill_holes(b)
        sbody=body_c(side,C['open_r']); tbody=body_c(top,C['open_r_top']); fbody=body_c(front,C['open_r'])
    else:
        sbody=body_of(side,C['open_r']); tbody=body_of(top,C['open_r_top']); fbody=body_of(front,C['open_r'])
    ys,xs=np.where(side); NOSE=xs.max(); TAILTIP=xs.min()
    S=C['length']/(NOSE-TAILTIP)
    bx=np.where(sbody.any(0))[0]; X0P,X1P=bx.min(),bx.max()
    xs_=np.arange(X0P,X1P+1)
    zt=np.array([np.where(sbody[:,x])[0].min() for x in xs_],float); zb=np.array([np.where(sbody[:,x])[0].max() for x in xs_],float)
    if C.get('env_px'):
        # sharks: fins have the body colour, so the body is the silhouette's ENVELOPE without fin bumps: the lowest top edge
        # and the highest bottom edge in a sliding window, from the tail stalk (body_x0_px) to the snout
        X0P=C['body_x0_px']; keep=xs_>=X0P
        if C.get('body_x1_px'): X1P=C['body_x1_px']; keep&=xs_<=X1P      # the body ends before things that stick out in front (a shrimp's antennae)
        xs_,zt,zb=xs_[keep],zt[keep],zb[keep]
        wv=C['env_px']; zt=ndi.maximum_filter1d(zt,wv,mode='nearest'); zb=ndi.minimum_filter1d(zb,wv,mode='nearest')
        zt=ndi.gaussian_filter1d(zt,wv/6,mode='nearest'); zb=ndi.gaussian_filter1d(zb,wv/6,mode='nearest')
        # use the envelope ONLY where fins attach (env_top / env_bot x-ranges); elsewhere the true silhouette
        zt0=np.array([np.where(side[:,x])[0].min() for x in xs_],float); zb0=np.array([np.where(side[:,x])[0].max() for x in xs_],float)
        def rng_w(rngs):
            w_=np.zeros(len(xs_))
            for (a_,b_) in rngs: w_=np.maximum(w_,((xs_>=a_)&(xs_<=b_)).astype(float))
            return ndi.gaussian_filter1d(w_,12,mode='nearest')
        wt_,wb_=rng_w(C.get('env_top',[])),rng_w(C.get('env_bot',[]))
        zt0s=ndi.gaussian_filter1d(zt0,2,mode='nearest'); zb0s=ndi.gaussian_filter1d(zb0,2,mode='nearest')
        zt=zt*wt_+zt0s*(1-wt_); zb=zb*wb_+zb0s*(1-wb_)
        if C.get('bridge_top') is not None:   # exact: the true silhouette, bridged straight across each fin base (a,b[,bulge px])
            def bridged(z0,rngs,sgn_):
                z=z0.copy()
                for r_ in rngs:
                    a_,b_=r_[0],r_[1]; bg_=r_[2] if len(r_)>2 else 0.0
                    ia,ib=np.searchsorted(xs_,a_),np.searchsorted(xs_,b_); ia=max(ia,0); ib=min(ib,len(xs_)-1); t_=np.linspace(0,1,ib-ia+1)
                    za_,zb_=(r_[3],r_[4]) if len(r_)>=5 else (z[ia],z[ib])      # optional explicit rows at both ends (fins that overlap each other)
                    z[ia:ib+1]=za_+(zb_-za_)*t_+sgn_*bg_*np.sin(np.pi*t_)
                return ndi.gaussian_filter1d(z,C.get('bridge_blur',5),mode='nearest')
            zt=bridged(zt0s,C['bridge_top'],-1); zb=bridged(zb0s,C.get('bridge_bot',[]),1)
        elif C.get('stalk_env',True):   # the tail stalk: envelope too (tail lobes)
            st=np.clip((C['body_x0_px']+C.get('stalk_px',80)-xs_)/20,0,1); zt=zt*(1-st)+ndi.maximum_filter1d(zt,wv,mode='nearest')*st; zb=zb*(1-st)+ndi.minimum_filter1d(zb,wv,mode='nearest')*st
        sbody=np.zeros_like(side)
        for k,x in enumerate(xs_): sbody[int(zt[k]):int(zb[k])+1,x]=True
        sbody&=side
    tys,txs=np.where(tbody); TN=C.get('top_x1_px',txs.max()); T0=C.get('top_x0_px',txs.min())
    TSC=(TN-T0)/max(X1P-X0P,1) if C.get('top_rescale',True) else 1.0   # ChatGPT often draws the top view shorter: map body ends onto body ends
    def TX(xside): return TN-(X1P-xside)*TSC
    TCEN=np.median([(np.where(tbody[:,x])[0].min()+np.where(tbody[:,x])[0].max())/2 for x in np.where(tbody.any(0))[0]])
    tw=[]
    for x in xs_:
        xt=int(round(TX(x)))
        if 0<=xt<Ww and tbody[:,xt].any(): r=np.where(tbody[:,xt])[0]; tw.append((r.max()-r.min())/2/TSC)
        else: tw.append(np.nan)
    tw=np.array(tw); ok=~np.isnan(tw); tw=np.interp(xs_,xs_[ok],tw[ok])
    # notches where fins/eyes were cut out of the top view: fill concave dips (running max), then smooth
    if C.get('tw_min_ranges'):    # min-envelope only where the pectorals stick out (keeps a hammer head wide)
        twm=ndi.minimum_filter1d(tw,C.get('tw_win',101),mode='nearest'); wr=np.zeros(len(xs_))
        for (a_,b_) in C['tw_min_ranges']: wr=np.maximum(wr,((xs_>=a_)&(xs_<=b_)).astype(float))
        wr=ndi.gaussian_filter1d(wr,15,mode='nearest'); tw=tw*(1-wr)+twm*wr; tw=ndi.gaussian_filter1d(tw,3,mode='nearest')
    elif C.get('tw_mode')=='min':   # pectoral fins stick out of the top view: take the narrow envelope
        tw=ndi.gaussian_filter1d(ndi.minimum_filter1d(tw,C.get('tw_win',101),mode='nearest'),C.get('tw_win',101)/6,mode='nearest')
    else:
        tw=ndi.gaussian_filter1d(ndi.maximum_filter1d(tw,C.get('tw_fill',41),mode='nearest'),6,mode='nearest')
    fys,fxs=np.where(fbody); FW=(fxs.max()-fxs.min())/2; FCX=(fxs.max()+fxs.min())/2; FCY=(fys.max()+fys.min())/2
    if C.get('front_box'):   # (x0,y0,x1,y1) of the front-view BODY (without pectorals/dorsal)
        fx0,fy0,fx1,fy1=C['front_box']; FW=(fx1-fx0)/2; FCX=(fx0+fx1)/2; FCY=(fy0+fy1)/2
    for (a_,b_) in C.get('tw_interp_ranges',[]):   # bridge over fins sticking out of the top view (smooth, slightly convex)
        ia,ib=np.searchsorted(xs_,a_),np.searchsorted(xs_,b_); ia=max(ia,1); ib=min(ib,len(xs_)-2)
        t_=np.linspace(0,1,ib-ia+1); bulge=C.get('tw_bulge',0.04)*max(tw[ia],tw[ib])*np.sin(np.pi*t_)
        tw[ia:ib+1]=tw[ia]+(tw[ib]-tw[ia])*(3*t_**2-2*t_**3)+bulge
        tw=ndi.gaussian_filter1d(tw,4,mode='nearest')
    for (a_,b_,k_) in C.get('tw_scale_ranges',[]):
        wr=ndi.gaussian_filter1d(((xs_>=a_)&(xs_<=b_)).astype(float),10,mode='nearest'); tw=tw*(1-wr*(1-k_))
    if C.get('debug_tw'): print('TW',[(int(x),round(float(t),1)) for x,t in zip(xs_[::60],tw[::60])])
    WSC=C.get('WSC',0.5*(1+FW/tw.max()))          # split the top/front width disagreement
    g=lambda a:ndi.gaussian_filter1d(a,2.0,mode='nearest')
    zt,zb,tw=g(zt),g(zb),g(tw)
    imax=np.argmax(zb-zt); BASEZ=(zt[imax]+zb[imax])/2
    X=lambda px:(px-NOSE)*S; Z=lambda py:(BASEZ-py)*S; PXs=lambda x:NOSE+x/S; PYs=lambda z:BASEZ-z/S
    HS,WY,FN=C.get('HS',0.88),C.get('WY',0.70),C.get('FN',2.05)
    TPS,TPA=C.get('taper_start',0.55),C.get('taper',0.5)      # taper the rear part (fraction of body length from the front)
    XM=X(xs_)
    xts=XM[-1]+(XM[0]-XM[-1])*TPS
    def TP(x):
        x=np.asarray(x,float); t=np.clip((x-xts)/(XM[0]-xts),0,1); t=np.where(x<xts,t,0.0); return 1-TPA*t*t*(3-2*t)
    TPX=TP(XM)
    # mouth (biters): sheet columns -> upper lip / lower lip rows
    M=C.get('mouth')
    if M:
        mx0,mx1=M['corner_px'],X1P
        up=np.interp(xs_,[M['corner_px'],M['front_px']],[M['corner_row'],M['front_up_row']])
        lo=np.interp(xs_,[M['corner_px'],M['front_px']],[M['corner_row'],M['front_lo_row']])
        if M.get('up_pts'): up=ndi.gaussian_filter1d(np.interp(xs_,[p_[0] for p_ in M['up_pts']],[p_[1] for p_ in M['up_pts']]),4,mode='nearest')
        if M.get('lo_pts'): lo=ndi.gaussian_filter1d(np.interp(xs_,[p_[0] for p_ in M['lo_pts']],[p_[1] for p_ in M['lo_pts']]),4,mode='nearest')
    def ring_profile(which):
        """returns zc,h,w arrays (metres) for the 'upper' head/body or the 'jaw'"""
        a,b=zt.copy(),zb.copy()
        if M and which=='upper':
            bl=np.clip((xs_-(M['corner_px']-M['blend_px']))/M['blend_px'],0,1); bl=bl*bl*(3-2*bl)
            b=np.minimum(b*(1-bl)+up*bl,b)   # never below the silhouette (hammer heads)
        if which=='jaw':
            a=lo.copy()
        zc=Z((a+b)/2); h=np.maximum((b-a)/2,0)*S
        cz=Z(BASEZ*0+((zt+zb)/2))      # squeeze heights toward the body centre line (HS)
        zc=cz+(zc-cz)*HS; h=h*HS*TPX
        w=tw*WSC*S*WY*TPX
        if which=='jaw':
            w=w*M.get('jaw_w',0.86)
            if M.get('jaw_w_max_px'): w=np.minimum(w,M['jaw_w_max_px']*S*WSC*WY)
            jb=M['corner_px']-M.get('jaw_back_px',10)
            f=np.clip((xs_-jb)/max(M.get('jaw_back_px',10),1),0,1); f=np.sqrt(f*(2-f))     # rounded back end, hidden in the body
            h=h*f; w=w*f
        if M and which in ('upper','jaw'):
            front=xs_>M['corner_px']+M.get('round_from',0.7)*(M['front_px']-M['corner_px'])
            w=np.where(front,np.minimum(w,h*M.get('round_k',1.7)+w*0.15),w)        # no flat 'duck bill' at the snout
        return zc,h,w
    PROF={'upper':ring_profile('upper')}
    XEND_U=None
    if M:   # the snout ends in a rounded dome where the head gets thin above the lip (no beak point)
        hu=PROF['upper'][1]; ic=np.searchsorted(xs_,M['corner_px']); hmax=hu[ic:].max()
        idx=np.where((np.arange(len(xs_))>ic+np.argmax(hu[ic:]))&(hu<M.get('snout_frac',0.42)*hmax))[0]
        if len(idx): XEND_U=XM[idx[0]]
    if M: PROF['jaw']=ring_profile('jaw')
    CAP=C.get('cap_px',30)*S
    def prof(x,which='upper'):
        zc_,h_,w_=PROF[which]; x=np.asarray(x,float)
        xc=np.clip(x,XM[0],XM[-1])
        zc=np.interp(xc,XM,zc_); h=np.interp(xc,XM,h_); w=np.interp(xc,XM,w_)
        f=np.where(x<XM[0],np.sqrt(np.clip(1-((XM[0]-x)/CAP)**2,0,1)),1.0)
        if which=='upper' and XEND_U is not None:
            capf=M.get('snout_cap_px',26)*S; x0c=XEND_U-capf
            f=f*np.where(x>x0c,np.sqrt(np.clip(1-((x-x0c)/capf)**2,0,1)),1.0)
            hh=float(np.interp(x0c,XM,PROF['upper'][1])); ww=float(np.interp(x0c,XM,PROF['upper'][2])); zz=float(np.interp(x0c,XM,PROF['upper'][0]))
            h=np.where(x>x0c,hh,h); w=np.where(x>x0c,ww,w); zc=np.where(x>x0c,zz,zc)
        return zc,h*f,w*f
    def sp(c,n): return np.sign(c)*np.abs(c)**(2.0/n)
    FNR=C.get('FN_ranges',[])     # (px0, px1, fn): the section gets boxier from px0 to px1 and stays so (a hammer head needs a blunt end, not an edge)
    def FNX(x):
        f_=np.zeros(np.shape(x))+FN
        for (a_,b_,fn_) in FNR:
            t_=np.clip((PXs(np.asarray(x,float))-a_)/max(b_-a_,1),0,1); t_=t_*t_*(3-2*t_); f_=f_+(fn_-FN)*t_
        return f_
    def pt(x,th,which='upper'):
        zc,h,w=prof(x,which)
        fn=C.get('jaw_FN',3.0) if which=='jaw' else (FNX(x) if FNR else FN)
        return np.stack([np.broadcast_to(x,np.shape(th)), w*sp(np.sin(th),fn), zc+h*sp(np.cos(th),fn)],-1)
    def inside(p,which='upper'):
        zc,h,w=prof(p[...,0],which)
        fn=C.get('jaw_FN',3.0) if which=='jaw' else (FNX(p[...,0]) if FNR else FN)
        return (np.abs(p[...,1])/np.maximum(w,1e-6))**fn+(np.abs(p[...,2]-zc)/np.maximum(h,1e-6))**fn
    def surf_along(p0,d,lo_=-0.05,hi_=1.2,which='upper'):
        lo_,hi_=lo_*C['length']/3.4,hi_*C['length']/3.4
        for _ in range(40):
            m=(lo_+hi_)/2
            if inside(np.array(p0)+d*m,which)<1: lo_=m
            else: hi_=m
        return np.array(p0)+d*(lo_+hi_)/2
    def body_normal(q,which='upper'):
        e=1e-3*C['length']/3.4; g_=np.array([(inside(q+np.eye(3)[k]*e,which)-inside(q-np.eye(3)[k]*e,which)) for k in range(3)]); return g_/np.linalg.norm(g_)
    # x range of each loft (upper: whole body; jaw: corner..front)
    XR={'upper':(XM[0]-CAP*0.999, X(X1P) if XEND_U is None else XEND_U)}
    if M:
        jf=X(M['jaw_front_px']); XR['jaw']=(X(M['corner_px']-M.get('jaw_back_px',10)),jf)
        # the upper loft ends at the snout (its height there ~0 from the lip line)
    # ------------------------------------------------ texture atlas (1024): body rows 1023..(1024-NV), jaw strip, tiles on top
    TEX=1024; NV=C.get('NV',640); NJ=C.get('NJ',128) if M else 0
    A=np.zeros((TEX,TEX,3),np.float32)
    PAL={k:np.array(v,np.float32) for k,v in C['palette'].items()}      # body classes (from the sheet)
    keys=list(PAL)
    def classify(src,pmask=None):
        d=np.stack([np.linalg.norm(src-PAL[k],axis=-1) for k in keys],0)
        return np.argmin(d,0)
    def bil(img,px,py):
        px=np.clip(px,0,img.shape[1]-1.001); py=np.clip(py,0,img.shape[0]-1.001)
        x0=np.floor(px).astype(int); y0=np.floor(py).astype(int); fx=(px-x0)[...,None]; fy=(py-y0)[...,None]
        return img[y0,x0]*(1-fx)*(1-fy)+img[y0,x0+1]*fx*(1-fy)+img[y0+1,x0]*(1-fx)*fy+img[y0+1,x0+1]*fx*fy
    if C.get('edge_px'):
        SIDE_IN=ndi.binary_erosion(side,iterations=C['edge_px']).astype(np.float32)[...,None]; TOP_IN=ndi.binary_erosion(top,iterations=C['edge_px']).astype(np.float32)[...,None]
    def paint(which,nv):
        U,V=np.meshgrid((np.arange(TEX)+0.5)/TEX,(np.arange(nv)+0.5)/nv)
        x0_,x1_=XR[which]; x=x0_+(x1_-x0_)*U; th=math.pi+math.pi*V   # owner 16:54 'blurry': both flanks share (mirror) the texture = 2x pixels per side
        p=pt(x,th,which)
        pu=pt(np.clip(x+1e-3,x0_,x1_),th,which)-pt(np.clip(x-1e-3,x0_,x1_),th,which); pv=pt(x,th+1e-3,which)-pt(x,th-1e-3,which)
        nrm=np.cross(pu,pv); nrm/=np.linalg.norm(nrm,axis=-1,keepdims=True)+1e-9
        zc0=prof(p[...,0],which)[0]
        if (nrm[...,2]*(p[...,2]-zc0)).mean()<0: nrm=-nrm
        # sheet space (undo the less-toy squeeze)
        cz=np.interp(np.clip(p[...,0],XM[0],XM[-1]),XM,Z((zt+zb)/2)); tp=TP(np.clip(p[...,0],XM[0],XM[-1]))
        ps=p.copy(); ps[...,1]=p[...,1]/(WY*tp); ps[...,2]=cz+(p[...,2]-cz)/(HS*tp)
        ws=np.abs(nrm[...,1]); wt=np.maximum(nrm[...,2],0)*C.get('top_w',0.95); wf=np.maximum(nrm[...,0],0)*C.get('front_w',1.1); wb=np.maximum(-nrm[...,2],0)*C.get('bot_w',1.0)
        if which=='jaw': wt=wt*0
        view=np.argmax(np.stack([ws,wt,wf,wb],-1),-1)
        sxp,syp=PXs(ps[...,0]),PYs(ps[...,2])
        if C.get('cap_clamp_px') is not None and which=='upper': sxp=np.maximum(sxp,X0P+C['cap_clamp_px'])
        if C.get('top_inset_px'):   # the sheet's rim light / outline along the back and belly: sample from inside the body instead
            zt_x=np.interp(sxp,xs_,zt); zb_x=np.interp(sxp,xs_,zb); hh_=np.maximum(zb_x-zt_x,1)
            ins_=np.minimum(C['top_inset_px'],0.35*hh_); d_=np.maximum(syp-zt_x,0)
            syp=np.where(d_<2*ins_,zt_x+ins_+d_*d_/(4*ins_),syp)      # soft: no hard edge where the inset starts
            syp=np.minimum(syp,zb_x-np.minimum(C.get('bot_inset_px',6),0.2*hh_))
        cs=bil(SH,sxp,syp)
        ct=bil(SH,TX(PXs(ps[...,0])),TCEN-ps[...,1]/(S*WSC)*TSC)
        cf=bil(SH,FCX+ps[...,1]/S*(FW/(tw.max()*WSC)),FCY-(ps[...,2]-Z(BASEZ))/S)
        belly=PAL[C['belly_class']]
        src=np.where(view[...,None]==0,cs,np.where(view[...,None]==1,ct,np.where(view[...,None]==2,cf,belly)))
        cl=classify(src)
        # ignore non-body pixels (eye, teeth, mouth, edge line, fins over the flank): fill from nearest body class
        bad=np.zeros(cl.shape,bool)
        fxq=FCX+ps[...,1]/S*(FW/(tw.max()*WSC)); fyq=FCY-(ps[...,2]-Z(BASEZ))/S
        zone=np.ones(cl.shape,bool)
        if C.get('ignore_boxes') is not None:
            zone=np.zeros(cl.shape,bool)
            for (a0,b0,a1,b1) in C['ignore_boxes']: zone|=(view==0)&(sxp>=a0)&(sxp<=a1)&(syp>=b0)&(syp<=b1)
            for (a0,b0,a1,b1) in C.get('ignore_boxes_front',[]): zone|=(view==2)&(fxq>=a0)&(fxq<=a1)&(fyq>=b0)&(fyq<=b1)
        for k,v in C.get('ignore',{}).items():
            bad|=zone&(np.linalg.norm(src-np.array(v,np.float32),axis=-1)<C.get('ignore_tol',40))
        if M and which=='jaw': bad|=(view==0)&(syp<np.interp(sxp,xs_,lo)+C.get('lip_pad',6))
        if M and which=='upper' and C.get('lip_pad') is not None: bad|=(view==0)&(sxp>M['corner_px']-5)&(syp>np.interp(sxp,xs_,up)-C['lip_pad'])
        if C.get('ignore_top') is not None:
            ctq=bil(SH,TX(sxp),TCEN-ps[...,1]/(S*WSC)*TSC)
            for k,v in C['ignore_top'].items(): bad|=(view==1)&(np.linalg.norm(ctq-np.array(v,np.float32),axis=-1)<C.get('ignore_top_tol',40))
            if C.get('ignore_top_rule'): bad|=(view==1)&eval(C['ignore_top_rule'],{'np':np,'R':ctq[...,0],'G':ctq[...,1],'B':ctq[...,2]})
        if C.get('edge_px'):   # the sheet's black outline: never sample closer than edge_px to the silhouette edge
            bad|=(view==0)&(bil(SIDE_IN,sxp,syp)[...,0]<0.5)
            bad|=(view==1)&(bil(TOP_IN,TX(sxp),TCEN-ps[...,1]/(S*WSC)*TSC)[...,0]<0.5)
        bad|=np.linalg.norm(src-np.array([255,0,255]),axis=-1)<C.get('magenta_tol',120)
        if not C.get('no_magenta_rule'): bad|=(src[...,2]>src[...,1]+35)&(src[...,0]>src[...,1]+35)      # magenta-tinted edge pixels (off for pink / purple creatures)
        if C.get('fin_rule'):   # fins painted over the flank in the side view (the 3D fins cover them anyway)
            fs=bil(finc.astype(np.float32)[...,None],sxp,syp)[...,0]; bad|=(view==0)&(fs>0.3)
            ft=bil(finc.astype(np.float32)[...,None],TX(sxp),TCEN-ps[...,1]/(S*WSC)*TSC)[...,0]; bad|=(view==1)&(ft>0.3)
            ff=bil(finc.astype(np.float32)[...,None],FCX+ps[...,1]/S*(FW/(tw.max()*WSC)),FCY-(ps[...,2]-Z(BASEZ))/S)[...,0]; bad|=(view==2)&(ff>0.3)
        ec=C['eye']; bad|=(view==0)&(np.hypot(sxp-ec['x_px'],syp-ec['y_px'])<ec['r_px']*C.get('eye_ignore_k',1.25))
        for poly in C.get('ignore_polys',[]):
            pm=np.zeros((Hh,Ww),np.uint8); cv2.fillPoly(pm,[np.array(poly,np.int32)],1)
            bad|=(view==0)&(bil(pm.astype(np.float32)[...,None],sxp,syp)[...,0]>0.5)
        for (cx_,cy_,cr_) in C.get('ignore_circles',[]): bad|=(view==0)&(np.hypot(sxp-cx_,syp-cy_)<cr_)
        if C.get('ignore_circles_front'):   # e.g. the glowing eyes drawn in the FRONT view (they'd smear onto the snout)
            fxp_=FCX+ps[...,1]/S*(FW/(tw.max()*WSC)); fyp_=FCY-(ps[...,2]-Z(BASEZ))/S
            for (cx_,cy_,cr_) in C['ignore_circles_front']: bad|=(view==2)&(np.hypot(fxp_-cx_,fyp_-cy_)<cr_)
        for bw in C.get('brows',[]):
            for (bxp,byp) in bw['pts']: bad|=(view==0)&(np.hypot(sxp-bxp,syp-byp)<bw['r_px']*2.2)
        for k,v in C.get('ignore_tight',{}).items(): bad|=np.linalg.norm(src-np.array(v,np.float32),axis=-1)<C.get('tight_tol',28)
        if C.get('belly_from_bottom',True): cl[view==3]=keys.index(C['belly_class']); bad[view==3]=False
        iy=ix=None
        if bad.any() and (~bad).any():
            _,(iy,ix)=ndi.distance_transform_edt(bad,return_indices=True); cl=cl[iy,ix]
        # smooth borders: blur each class' one-hot, take the max
        oh=np.stack([cv2.GaussianBlur((cl==i).astype(np.float32),(0,0),C.get('cls_blur',3.0)) for i in range(len(keys))],0)
        cl=np.argmax(oh,0)
        col=np.zeros(p.shape,np.float32)
        for i,k in enumerate(keys): col[cl==i]=PAL[k]
        col=cv2.GaussianBlur(col,(0,0),C.get('col_blur',4.0))      # soft colour borders like the sheet's gradients
        if C.get('colour_mode')=='sample':
            # the sheet's own soft gradients: blurred projected colour, with eye/teeth/lines/fins in-painted from the body
            sm=src.copy()
            if bad.any() and (~bad).any():
                sm=sm[iy,ix]
                if C.get('fill_blur'):
                    wgt=cv2.GaussianBlur(bad.astype(np.float32),(0,0),3)[...,None]; sm=sm*(1-wgt)+cv2.GaussianBlur(sm,(0,0),C['fill_blur'])*wgt
            sm=cv2.GaussianBlur(sm,(0,0),C.get('sharp_blur',0.7))
            sm=np.clip(sm*1.6-cv2.GaussianBlur(sm,(0,0),2.5)*0.6,0,255)   # light unsharp mask
            col=sm*C.get('sample_mix',0.85)+col*(1-C.get('sample_mix',0.85))
        # mouth interior (biters): the upper head's underside and the jaw's top, in the mouth zone
        if M:
            inner=np.zeros(cl.shape,bool)
            if which=='upper': inner=(p[...,0]>X(M['corner_px'])+0.0)&(p[...,0]<X(M['front_px']+M.get('inner_fwd_px',1000)))&(nrm[...,2]<-0.7)&(ps[...,2]<Z(np.interp(PXs(p[...,0]),xs_,up))+8*S)
            if which=='jaw': inner=(nrm[...,2]>0.7)&(p[...,2]>prof(p[...,0],'jaw')[0])&(np.abs(p[...,1])<0.7*prof(p[...,0],'jaw')[2])
            if M.get('inner_w_max_px'): inner&=np.abs(p[...,1])<M['inner_w_max_px']*S*WSC*WY
            col[inner]=np.array(C['mouth_col'],np.float32); cl=np.where(inner,len(keys),cl)
        # countershading + scales
        hgt=np.clip((p[...,2]-zc0)/np.maximum(prof(p[...,0],which)[1],1e-6),-1,1)
        back=np.clip(hgt,0,1)[...,None]**1.3
        ba=C.get('back_amt',0.18); col=col*(1-ba*back)+np.array(C.get('back_tint',(40,40,60)),np.float32)*ba*back
        cs_=C.get('scale_px',16.0); uu=np.arange(TEX)[None,:].repeat(nv,0).astype(np.float32); vv=np.arange(nv)[:,None].repeat(TEX,1).astype(np.float32)
        off=(np.floor(vv/cs_)%2)*cs_/2; fu=((uu+off)%cs_)/cs_-0.5; fv=(vv%cs_)/cs_-0.5
        arc=np.clip(1-np.abs(np.hypot(fu,fv)-0.42)/0.09,0,1)*(fu<0.05)
        head=np.clip((p[...,0]-X(C.get('scales_end_px',X1P-0.2*(X1P-X0P))))/(-0.1*C['length']),0,1) if which=='upper' else np.zeros(U.shape)
        col=col*(1-0.13*(arc*head)[...,None])
        return col,cl
    body,clb=paint('upper',NV)
    A[TEX-NV:]=body[::-1]
    if M:
        jaw,clj=paint('jaw',NJ); A[TEX-NV-NJ:TEX-NV]=jaw[::-1]
    np.save(D+'/out/cls.npy',clb)
    # tiles (rows 0..255 minus the jaw strip): eye 0..255 cols 0..255 (if room), fin gradient, dark, tooth, mouth
    E=min(256,TEX-NV-NJ); yy,xx=np.mgrid[0:E,0:E]; cx=cy=(E-1)/2; r=np.hypot(xx-cx,yy-cy)/(E/2)
    ey=np.zeros((E,E,3),np.float32)+np.array((42,34,51))
    irisT=np.array(C.get('iris_top',(25,95,205)),np.float32); irisB=np.array(C.get('iris_bot',(120,215,255)),np.float32)
    t=np.clip((yy/E-0.12)/0.8,0,1)[...,None]; iris=irisT*(1-t)+irisB*t
    if C.get('sclera',False):
        ey=np.where((r<0.9)[...,None],np.array((246,246,246),np.float32),ey); ir=0.62
    else: ir=0.88
    LF=C.get('look_fwd',0.0)*E/2          # owner 16:30: the iris/pupil look FORWARD (toward the nose = +x in this tile), not out to the side
    ri=np.hypot(xx-(cx+LF),yy-cy)/(E/2)
    ey=np.where(((ri<ir)&(r<0.9))[...,None],iris,ey); ey=np.where(((ri<ir)&(ri>ir-0.12)&(r<0.9))[...,None],ey*0.82,ey)
    pr=np.hypot(xx-(cx+LF*1.15),yy-(cy+E*0.03))/(E/2); ey=np.where(((pr<ir*0.56)&(r<0.9))[...,None],np.array((22,26,52),np.float32),ey)
    for (ax,ay,ar) in [(0.28*ir/0.88,-0.30*ir/0.88,0.24*ir/0.88),(-0.28*ir/0.88,0.30*ir/0.88,0.10*ir/0.88)]:
        crr=np.hypot(xx-(cx+LF+ax*E/2),yy-(cy+ay*E/2))/(E/2); ey=np.where(((crr<ar)&(r<0.9))[...,None],np.array((255,255,255),np.float32),ey)
    if C.get('eye_style')=='slit':   # menacing boss eye: glowing iris edge to edge, thin vertical slit, one small glint
        ey=np.zeros((E,E,3),np.float32)+np.array((10,12,20))
        ci=np.array(C.get('iris_bot',(90,235,255)),np.float32); co=np.array(C.get('iris_top',(10,130,185)),np.float32)
        t=np.clip(r/0.92,0,1)[...,None]; ey=np.where((r<0.92)[...,None],ci*(1-t**2)+co*t**2,ey)
        LF=C.get('look_fwd',0.0)*E/2
        slit=(np.abs(xx-cx-LF)/(E/2)<0.09*np.sqrt(np.clip(1-((yy-cy)/(E/2*0.8))**2,0,1)))&(r<0.85)
        ey=np.where(slit[...,None],np.array((8,10,18),np.float32),ey)
        crr=np.hypot(xx-(cx+0.3*E/2),yy-(cy-0.35*E/2))/(E/2); ey=np.where((crr<0.09)[...,None],np.array((255,255,255),np.float32),ey)
    if C.get('eye_style')=='glow':   # HSE-inspired boss eye (owner 17:56): glowing cyan orb, small ROUND pupil looking forward, glint
        ey=np.zeros((E,E,3),np.float32)+np.array((12,20,36))
        ci=np.array(C.get('iris_bot',(150,255,255)),np.float32); co=np.array(C.get('iris_top',(10,150,200)),np.float32)
        t=np.clip(r/0.9,0,1)[...,None]; ey=np.where((r<0.9)[...,None],ci*(1-t**1.6)+co*t**1.6,ey)
        LF=C.get('look_fwd',0.0)*E/2
        pr=np.hypot(xx-(cx+LF*1.3),yy-cy)/(E/2); ey=np.where(((pr<C.get('pupil_r',0.26))&(r<0.9))[...,None],np.array((10,30,55),np.float32),ey)
        crr=np.hypot(xx-(cx+0.32*E/2),yy-(cy-0.3*E/2))/(E/2); ey=np.where((crr<0.1)[...,None],np.array((255,255,255),np.float32),ey)
    if C.get('eye_style')=='orb':   # the HSE sheets' eye: a glowing orb with a white-hot core, no pupil, dark socket ring
        ey=np.zeros((E,E,3),np.float32)+np.array(C.get('socket_col',(14,30,58)),np.float32)
        ci=np.array(C.get('iris_bot',(120,240,255)),np.float32); co=np.array(C.get('iris_top',(0,160,225)),np.float32)
        OR_=C.get('orb_r',0.84); t=np.clip(r/OR_,0,1)[...,None]; orb=ci*(1-t**2.2)+co*t**2.2
        hx_,hy_=cx+0.10*E/2,cy-0.14*E/2; hr=np.hypot(xx-hx_,yy-hy_)/(E/2); k_=np.clip(1-hr/0.42,0,1)[...,None]**1.5
        orb=orb*(1-k_)+np.array((255,255,255),np.float32)*k_
        ey=np.where((r<OR_)[...,None],orb,ey)
    if C.get('lid'):   # angry upper lid in the body colour, slanting DOWN toward the nose (+x), with a dark lash line
        top,front=C['lid']            # lid edge height (fraction of radius from centre, negative = above) at the back / at the front
        u=(xx-cx)/(E/2); edge=(cy+(top+(front-top)*(u+1)/2)*E/2)
        lidm=(yy<edge)&(r<1.0)
        ey=np.where(lidm[...,None],np.array(C.get('lid_col',C.get('brow_col',(80,90,110))),np.float32),ey)
        ey=np.where(((yy>=edge)&(yy<edge+E*0.035)&(r<0.93))[...,None],np.array((15,15,25),np.float32),ey)
    A[0:E,0:E]=cv2.GaussianBlur(ey,(0,0),0.8)
    s=np.linspace(0,1,256); fa,fb=np.array(C['fin_edge'],np.float32),np.array(C['fin_root'],np.float32)
    A[0:E,256:512]=(fa[None]*(1-s[:,None])+fb[None]*s[:,None])[None,:,:]
    if C.get('fin_tips'):
        kk=np.clip((np.arange(E)/E-0.5)/0.45,0,1)[:,None,None]; A[0:E,256:512]=A[0:E,256:512]*(1-kk)+np.array(C.get('tip_col',(22,24,30)),np.float32)*kk
        lum=SH.mean(-1); inn=ndi.binary_erosion(fg,iterations=C.get('tip_edge',7)); dk=((lum<C.get('tip_lum',70))&inn).astype(np.float32)
        _,(ty_,tx_)=ndi.distance_transform_edt(~inn,return_indices=True); TIPMAP=ndi.gaussian_filter(dk[ty_,tx_],C.get('tip_blur',4))

    A[0:64,512:576]=(42,34,51); A[0:64,576:640]=C.get('tooth_col',(250,244,230)); A[0:64,640:704]=C.get('mouth_col',(120,30,40))
    A[64:128,512:576]=C.get('brow_col',(200,50,40))
    for (c0_,c1_,r0_,r1_) in C.get('tex_seams',[]):   # inpaint thin seam lines left by the view stitching
        A8=np.clip(A,0,255).astype(np.uint8); mk=np.zeros(A8.shape[:2],np.uint8); mk[r0_:r1_,c0_:c1_]=255
        A=cv2.inpaint(np.ascontiguousarray(A8[...,:3]),mk,5,cv2.INPAINT_TELEA).astype(A.dtype) if A8.shape[2]==3 else A
    UVT=dict(dark=(544/TEX,1-32/TEX),tooth=(608/TEX,1-32/TEX),mouth=(672/TEX,1-32/TEX),brow=(544/TEX,1-96/TEX))
    EUV=E/TEX
    # ------------------------------------------------ geometry
    V_=[];F_=[];UV_=[];K_=[]
    def addv(p): V_.append(tuple(map(float,p))); return len(V_)-1
    def loft(which,nr,na,v0,v1):
        x0_,x1_=XR[which]
        us=np.unique(np.clip((1-np.cos(np.linspace(0,math.pi,nr)))/2,0.004,0.998))
        rings=[[addv(pt(np.array(x0_+(x1_-x0_)*u),np.array(math.pi+2*math.pi*j/na),which)) for j in range(na)] for u in us]
        zc_a=float(prof(np.array(x0_),which)[0]); zc_b=float(prof(np.array(x1_),which)[0])
        tp=addv((x0_-0.0005,0,zc_a)); npole=addv((x1_+0.002,0,zc_b))
        uvf=lambda u,v:(u,v0+(v1-v0)*(0.004+0.992*(1-abs(2*v-1))))   # mirrored: v=0.5 (top) -> 1, belly seam -> 0
        for i in range(len(us)-1):
            for j in range(na):
                a,b=rings[i][j],rings[i][(j+1)%na]; c,d=rings[i+1][(j+1)%na],rings[i+1][j]
                F_.append((a,b,c,d)); UV_.append([uvf(us[i],j/na),uvf(us[i],(j+1)/na),uvf(us[i+1],(j+1)/na),uvf(us[i+1],j/na)]); K_.append(which)
        for j in range(na):
            a,b=rings[0][j],rings[0][(j+1)%na]; F_.append((tp,b,a)); UV_.append([uvf(0,(j+.5)/na),uvf(us[0],(j+1)/na),uvf(us[0],j/na)]); K_.append(which)
            a,b=rings[-1][j],rings[-1][(j+1)%na]; F_.append((a,b,npole)); UV_.append([uvf(us[-1],j/na),uvf(us[-1],(j+1)/na),uvf(1,(j+.5)/na)]); K_.append(which)
    loft('upper',C.get('NR',46),C.get('NA',40),0.0,NV/TEX)
    if M: loft('jaw',C.get('NRJ',20),C.get('NA',40)//2*2,NV/TEX,(NV+NJ)/TEX)
    # eyes
    EC=C['eye']; ER=EC['r_px']*S
    cz_e=float(np.interp(X(EC['x_px']),XM,Z((zt+zb)/2))); ez=cz_e+(Z(EC['y_px'])-cz_e)*HS
    eyes=[]
    for sgn in ([] if C.get('no_eye_geo') else (1,-1)):
        ed=math.radians(EC.get('fwd_deg',16))
        sx0=X(EC['x_px'])-0.15*C['length']/3.4
        q=surf_along(np.array([sx0,0,ez]),np.array([math.sin(ed),sgn*math.cos(ed),0.0]))
        if C.get('exact_place'):
            for _ in range(4):
                sx0+=X(EC['x_px'])-q[0]; q=surf_along(np.array([sx0,0,ez]),np.array([math.sin(ed),sgn*math.cos(ed),0.0]))
        nn=body_normal(q); fwd=np.array([1,0,0.0]); fwd=fwd-nn*fwd.dot(nn); fwd/=np.linalg.norm(fwd)
        upv=np.cross(nn,fwd)*sgn; upv=upv if upv[2]>0 else -upv
        NRI,NS=7,28
        def ept(rho,a,q=q,nn=nn,fwd=fwd,upv=upv):
            o=q+(fwd*math.cos(a)+upv*math.sin(a)*1.04)*ER*rho
            return surf_along(o,nn,-0.4,0.4)+nn*(0.004*C['length']/3.4+ER*C.get('eye_dome',0.14)*(1-rho*rho))
        cidx=addv(ept(0,0)); rings=[[addv(ept((k+1)/NRI,2*math.pi*a/NS)) for a in range(NS)] for k in range(NRI)]
        def euv(rho,a): return ((0.5+0.5*rho*math.cos(a))*EUV, 1-(0.5-0.5*rho*math.sin(a))*EUV)
        for a in range(NS):
            a0,a1=2*math.pi*a/NS,2*math.pi*(a+1)/NS
            tri=(cidx,rings[0][a],rings[0][(a+1)%NS]); uvs=[euv(0,0),euv(1/NRI,a0),euv(1/NRI,a1)]
            if sgn<0: tri=tri[::-1]; uvs=uvs[::-1]
            F_.append(tri); UV_.append(uvs); K_.append('eye')
            for k in range(NRI-1):
                qd=(rings[k][a],rings[k+1][a],rings[k+1][(a+1)%NS],rings[k][(a+1)%NS]); uq=[euv((k+1)/NRI,a0),euv((k+2)/NRI,a0),euv((k+2)/NRI,a1),euv((k+1)/NRI,a1)]
                if sgn<0: qd=qd[::-1]; uq=uq[::-1]
                F_.append(qd); UV_.append(uq); K_.append('eye')
        sk=[addv(np.array(V_[i])-nn*0.022*C['length']/3.4) for i in rings[-1]]
        for a in range(NS):
            qd=(rings[-1][a],sk[a],sk[(a+1)%NS],rings[-1][(a+1)%NS])
            if sgn<0: qd=qd[::-1]
            F_.append(qd); UV_.append([euv(1,0)]*4); K_.append('eye')
        eyes.append((q,nn,fwd,upv))
    # tubes (brow ridges, mouth line) along sheet polylines projected onto the head
    def tube(pts3,rad,uv,kind,nseg=8):
        pts3=np.array(pts3); rings=[]
        for k,c in enumerate(pts3):
            tg=pts3[min(k+1,len(pts3)-1)]-pts3[max(k-1,0)]; tg/=np.linalg.norm(tg)
            a=np.array([0,0,1.0]) if abs(tg[2])<0.9 else np.array([1.0,0,0]); a=a-tg*a.dot(tg); a/=np.linalg.norm(a); b=np.cross(tg,a)
            rr=rad*(0.55+0.45*math.sin(math.pi*(k+0.5)/len(pts3))) if kind=='brow' else rad
            rings.append([addv(c+(a*math.cos(2*math.pi*j/nseg)+b*math.sin(2*math.pi*j/nseg))*rr) for j in range(nseg)])
        for k in range(len(rings)-1):
            for j in range(nseg):
                F_.append((rings[k][j],rings[k][(j+1)%nseg],rings[k+1][(j+1)%nseg],rings[k+1][j])); UV_.append([uv]*4); K_.append(kind)
        F_.append(tuple(rings[0][::-1])); UV_.append([uv]*nseg); K_.append(kind)
        F_.append(tuple(rings[-1])); UV_.append([uv]*nseg); K_.append(kind)
    for bw in C.get('brows',[]):
        for sgn in (1,-1):
            pts=[]
            for (bxp,byp) in bw['pts']:
                cz_=float(np.interp(X(bxp),XM,Z((zt+zb)/2))); z_=cz_+(Z(byp)-cz_)*HS
                bx0_=X(bxp)-0.1*C['length']/3.4; bd_=np.array([0.25,sgn*1.0,0])/np.hypot(0.25,1.0)
                q=surf_along(np.array([bx0_,0,z_]),bd_)
                if C.get('exact_place'):
                    for _ in range(4):
                        bx0_+=X(bxp)-q[0]; q=surf_along(np.array([bx0_,0,z_]),bd_)
                pts.append(q+body_normal(q)*bw['r_px']*S*bw.get('lift',0.4))
            tube(pts,bw['r_px']*S,UVT['brow'],'brow')
    # teeth (biters): cones on the upper lip (pointing down) and the lower lip (pointing up, Jaw bone)
    if M:
        for row,(n_t,z_side,dirz,kind) in {'up':(M['n_up'],'upper',-1,'tooth_up'),'lo':(M['n_lo'],'jaw',1,'tooth_lo')}.items():
            xe_t=X(M['front_px'] if z_side=='upper' else M.get('lo_front_px',M['front_px']))-0.03*C['length']/3.4
            if z_side=='upper' and XEND_U is not None: xe_t=min(xe_t,XEND_U-M.get('snout_cap_px',26)*S*0.6)
            xs_t=np.linspace(X(M['corner_px'])+M.get('tooth_start',0.12)*(X(M['front_px'])-X(M['corner_px'])),xe_t,n_t)
            for sgn in (1,-1):
                for k,xt in enumerate(xs_t):
                    if sgn<0 and k==len(xs_t)-1 and n_t%2==1: continue
                    zc,h,w=prof(np.array(xt),z_side); zc,h,w=float(zc),float(h),float(w)
                    if M.get('tooth_w_max_px'): w=min(w,M['tooth_w_max_px']*S*WSC*WY)
                    zl=(zc-h*0.93) if dirz<0 else (zc+h*0.93)   # lip edge: bottom of the upper head / top of the jaw
                    frac=(xt-xs_t[0])/max(xs_t[-1]-xs_t[0],1e-6)
                    yl=sgn*w*(M.get('tooth_inset',0.92) if dirz<0 else M.get('tooth_inset_lo',M.get('tooth_inset',0.92)))*math.cos(frac*math.pi/2*0.95)
                    if sgn>0 and k==len(xs_t)-1 and n_t%2==1: yl=0.0
                    ht=M['tooth_px']*S*(0.8+0.4*math.sin(frac*math.pi))*(1.0 if dirz<0 else M.get('lo_tooth_k',1.0))
                    if M.get('tooth_fit'): ht=min(ht,max(float(np.interp(PXs(xt),xs_,lo-up)),3.0)*S*M['tooth_fit'])
                    br=ht*M.get('tooth_w',0.55)
                    base=np.array([xt,yl,zl-dirz*ht*0.25]); tip=base+np.array([0,0,dirz*ht])
                    ring=[addv(base+np.array([math.cos(2*math.pi*j/6)*br*0.8, math.sin(2*math.pi*j/6)*br,0])) for j in range(6)]
                    tp_=addv(tip)
                    for j in range(6):
                        f=(ring[j],ring[(j+1)%6],tp_) if dirz<0 else (ring[(j+1)%6],ring[j],tp_)
                        F_.append(f); UV_.append([UVT['tooth']]*3); K_.append(kind)
                    F_.append(tuple(ring if dirz<0 else ring[::-1])); UV_.append([UVT['tooth']]*6); K_.append(kind)
    JAWV=[]
    if M and C.get('mouth_wall'):
        xw=np.linspace(M['corner_px']-6,min(M['jaw_front_px'],M.get('wall_front_px',1e9))-M.get('wall_back_px',4),14); rows=[]
        for xp in xw:
            zu=Z(float(np.interp(xp,xs_,up))-5); zl=Z(float(np.interp(xp,xs_,lo))+5)
            a_=addv((X(xp),0.0,zu)); b_=addv((X(xp),0.0,zl)); rows.append((a_,b_)); JAWV.append(b_)
        for k in range(len(rows)-1):
            q_=(rows[k][0],rows[k][1],rows[k+1][1],rows[k+1][0])
            for qq in (q_,q_[::-1]): F_.append(qq); UV_.append([UVT['mouth']]*4); K_.append('wall')
    # fins: silhouette minus body (pushed into the body), pillow plates in the XZ plane; pectorals from a colour box
    fin_all=side&~sbody
    fin_all=ndi.binary_opening(fin_all,iterations=2)
    l,nf=ndi.label(fin_all); sz=ndi.sum(fin_all,l,range(1,nf+1))
    fins=[]
    for i in range(nf):
        if sz[i]<C.get('fin_min_px',400): continue
        m=l==i+1; ys_,xs__=np.where(m); cx_,cy_=xs__.mean(),ys_.mean()
        kind='tail' if cx_<X0P+15 else ('top' if cy_<np.interp(cx_,xs_,(zt+zb)/2) else 'bottom')
        if any(bx0<=cx_<=bx1 and by0<=cy_<=by1 for (bx0,by0,bx1,by1) in C.get('pect_comp_boxes',[])): kind='pect'
        if any(bx0<=cx_<=bx1 and by0<=cy_<=by1 for (bx0,by0,bx1,by1) in C.get('skip_comp_boxes',[])): continue
        m=m|(ndi.binary_dilation(m,iterations=C.get('root_px',22))&sbody)
        fins.append((kind,ndi.binary_fill_holes(m)))
    for poly in C.get('pect_polys',[]):
        pm=np.zeros((Hh,Ww),np.uint8); cv2.fillPoly(pm,[np.array(poly,np.int32)],1); fins.append(('pect',pm>0))
    for (bx0,by0,bx1,by1,rule) in C.get('pect_boxes',[]):
        sub=np.zeros_like(side); R_,G_,B_=SH[...,0],SH[...,1],SH[...,2]
        sel=eval(rule,{"np":np,"R":R_,"G":G_,"B":B_}); sub[by0:by1,bx0:bx1]=sel[by0:by1,bx0:bx1]
        sub=ndi.binary_fill_holes(ndi.binary_closing(ndi.binary_opening(sub,iterations=2),iterations=3))
        ll,nn_=ndi.label(sub); ss_=ndi.sum(sub,ll,range(1,nn_+1)); sub=ll==(np.argmax(ss_)+1)
        fins.append(('pect',sub))
    print('fins',[(k,int(m.sum())) for k,m in fins])
    PILLOWS=[]
    def pillow(mask,place,tmax,two,rect=None):
        dt=ndi.distance_transform_edt(mask); dmax=dt.max()
        cs_,_=cv2.findContours(mask.astype(np.uint8),cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_NONE)
        c=max(cs_,key=len)[:,0,:].astype(float)
        c=np.stack([ndi.gaussian_filter1d(c[:,0],7,mode='wrap'),ndi.gaussian_filter1d(c[:,1],7,mode='wrap')],1)
        step=C.get('fin_step',7.0); pts=[c[0]]; acc=0
        for k in range(1,len(c)):
            acc+=np.hypot(*(c[k]-c[k-1]))
            if acc>=step: pts.append(c[k]); acc=0
        edge=np.array(pts); gy,gx=np.mgrid[0:mask.shape[0]:C.get('fin_grid',11),0:mask.shape[1]:C.get('fin_grid',11)]
        inner=np.stack([gx.ravel(),gy.ravel()],1).astype(float); inner=inner[dt[inner[:,1].astype(int),inner[:,0].astype(int)]>5]
        allp=np.concatenate([edge,inner]); ne=len(edge); tri=Delaunay(allp)
        keep=[t for t in tri.simplices if mask[int(allp[t,1].mean()),int(allp[t,0].mean())]]
        dd=np.array([0.0]*ne+[dt[int(y),int(x)] for x,y in inner]); ht=np.maximum(tmax*(dd/dmax)**0.55*S,C.get('fin_min_t',0)*S); tt=np.clip(dd/dmax,0,1)      # fin_min_t: thin strips (antennae) need some thickness or their two sides z-fight
        tv=np.array([0.5+0.45*float(TIPMAP[int(np.clip(y,0,Hh-1)),int(np.clip(x,0,Ww-1))] if C.get('fin_tips') else 0.0) for x,y in allp])
        for sgn_side in ([1,-1] if two else [0]):
            topv=[];botv=[]
            for k,(px,py) in enumerate(allp):
                topv.append(addv(place(X(px),Z(py),ht[k],sgn_side))); botv.append(addv(place(X(px),Z(py),-ht[k],sgn_side)))
            for t in keep:
                a,b,c_=t
                for arr,flip in ((topv,False),(botv,True)):
                    tri_=(arr[a],arr[b],arr[c_]); uv=[((256+256*tt[a])/TEX,1-float(tv[a])*EUV),((256+256*tt[b])/TEX,1-float(tv[b])*EUV),((256+256*tt[c_])/TEX,1-float(tv[c_])*EUV)]
                    if rect is not None:
                        ax_,ay_,sc_,x0e,y0e=rect; uv=[(float(ax_+(allp[i_,0]-x0e)*sc_)/TEX,1-float(ay_+(allp[i_,1]-y0e)*sc_)/TEX) for i_ in (a,b,c_)]
                    if flip: tri_=tri_[::-1]; uv=uv[::-1]
                    F_.append(tri_); UV_.append(uv); K_.append('fin')
    cz_line=lambda x:float(np.interp(np.clip(x,XM[0],XM[-1]),XM,Z((zt+zb)/2)))
    for kind,m in fins:
        if kind=='pect':
            mo=m&~sbody if (m&~sbody).sum()>200 else m
            ys_,xs__=np.where(mo); hx,hz=X(xs__.max()-6),Z(ys_.min()+4); SPL=math.radians(C.get('pect_splay',50))
            def place(x,z,o,s,hx=hx,hz=hz):
                zc,h,w=prof(np.array(hx)); zc=float(zc)
                z=zc+(z-zc)*HS; hz2=zc+(hz-zc)*HS
                if C.get('pect_hinge_flank'):
                    hzf=zc-float(prof(np.array(hx))[1])*C['pect_hinge_flank']; z=z+(hzf-hz2); hz2=hzf
                dz=z-hz2
                y=float(w)*0.86+(-dz)*math.sin(SPL)+o*math.cos(SPL); zz=hz2+dz*math.cos(SPL)+o*math.sin(SPL)
                return (x,s*y,zz)
            PILLOWS.append((m,place,C['fin_t']*0.85,True))
        else:
            def place(x,z,o,s,kind=kind):
                xc=float(np.clip(x,XM[0],XM[-1])); cz=cz_line(x)
                zc,h,w=prof(np.array(xc)); zc,h=float(zc),float(h)
                tp=float(TP(xc)); hs=h/(HS*tp) if tp>0 else h
                if C.get('fin_follow_exact'):   # follow the body's real top / bottom line (the old formula lifted fins in the mouth zone)
                    hs_t=float(np.interp(PXs(xc),xs_,(zb-zt)/2))*S
                    if kind=='top': dz=(cz+hs_t*HS*tp)-(cz+hs_t)
                    elif kind=='bottom': dz=(cz-hs_t*HS*tp)-(cz-hs_t)
                    else: dz=(z-cz)*(HS-1)
                elif kind=='top': dz=(zc+h)-(cz+hs)
                elif kind=='bottom': dz=(zc-h)-(cz-hs)
                else: dz=(z-cz)*(HS-1)
                return (x,o,z+dz)
            PILLOWS.append((m,place,C.get('tail_t',C['fin_t']) if kind=='tail' else C['fin_t'],False))
    PT=C.get('pect_top')
    if PT:   # pectorals traced from the TOP view (their true outline), hinged on the flank and drooped
        bx0,by0,bx1,by1=PT['box']; yy_,xx_=np.mgrid[0:Hh,0:Ww]
        sx_=X1P-(TN-xx_)/TSC; hw=np.interp(sx_,xs_,tw)*TSC
        inb=views['top']&(xx_>=bx0)&(xx_<=bx1)&(yy_>=by0)&(yy_<=by1)
        mk=inb&((TCEN-yy_)>hw+PT.get('out_px',3))
        mk=ndi.binary_opening(mk,iterations=3); ll,nn_=ndi.label(mk); ss_=ndi.sum(mk,ll,range(1,nn_+1)); mk=ll==(np.argmax(ss_)+1)
        mk=ndi.binary_fill_holes(mk|(ndi.binary_dilation(mk,iterations=PT.get('root_px',14))&inb))
        print('pect_top px',int(mk.sum()))
        ys_,xs__=np.where(mk); hxp=X1P-(TN-(xs__.min()+xs__.max())/2)/TSC; hx=X(hxp)
        zc_h,h_h,w_h=[float(v) for v in prof(np.array(hx))]; zh=zc_h-h_h*PT.get('z_frac',0.5); DR=math.radians(PT.get('droop',30)); LK=S*WSC*WY/TSC
        def place(x,z,o,s):
            px=NOSE+x/S; py=BASEZ-z/S
            xm=X(X1P-(TN-px)/TSC); yl=(TCEN-py)*LK
            y0=float(prof(np.array(np.clip(xm,XM[0],XM[-1])))[2])*PT.get('hinge_in',0.8)
            d=max(yl-y0,-0.05)
            return (xm,s*(y0+d*math.cos(DR)+o*math.sin(DR)),zh-d*math.sin(DR)+o*math.cos(DR))
        PILLOWS.append((mk,place,C['fin_t']*PT.get('thick',0.9),True))
    # fin atlas: every fin is textured with its own piece of the sheet (rays, shading, black tips), packed into the free tiles
    RECTS=[None]*len(PILLOWS); FINRECTS=[]
    if C.get('fin_atlas'):
        REG=[(704,0,1024,E),(512,128,704,E)]; PADP=3; EP=C.get('fin_edge_px',6)
        boxes=[]
        for (m,_,_,_) in PILLOWS:
            ys_,xs__=np.where(m); boxes.append((max(xs__.min()-PADP,0),max(ys_.min()-PADP,0),min(xs__.max()+PADP,Ww-1),min(ys_.max()+PADP,Hh-1)))
        def pack(sc):
            order=sorted(range(len(boxes)),key=lambda i:-(boxes[i][3]-boxes[i][1])); out={}; cur=[[r[0],r[1],0] for r in REG]
            for i in order:
                w=int(math.ceil((boxes[i][2]-boxes[i][0]+1)*sc)); h=int(math.ceil((boxes[i][3]-boxes[i][1]+1)*sc)); ok=False
                for ri,(rx0,ry0,rx1,ry1) in enumerate(REG):
                    cx_,cy_,sh=cur[ri]
                    if cx_+w>rx1: cx_=rx0; cy_=cy_+sh; sh=0
                    if cx_+w<=rx1 and cy_+h<=ry1:
                        out[i]=(cx_,cy_,w,h); cur[ri]=[cx_+w,cy_,max(sh,h)]; ok=True; break
                if not ok: return None
            return out
        sc=C.get('fin_atlas_scale',0.9); pk=None
        while sc>0.25:
            pk=pack(sc)
            if pk: break
            sc-=0.04
        print('fin atlas scale',round(sc,2),'ok' if pk else 'FAILED')
        if pk:
            for i,(m,_,_,_) in enumerate(PILLOWS):
                x0e,y0e,x1e,y1e=boxes[i]; ax_,ay_,w,h=pk[i]
                mm_=m[y0e:y1e+1,x0e:x1e+1]; lb_,nl_=ndi.label(mm_); dtm_=ndi.distance_transform_edt(mm_)
                # thin parts (antennae, legs) get a gentler erosion than broad fins: erode each pixel by at most 40% of its part's half-width
                crop=SH[y0e:y1e+1,x0e:x1e+1].copy(); mc=dtm_>np.minimum(EP,np.maximum(1.5,0.45*ndi.maximum_filter(dtm_,size=31)))
                if mc.sum()<20: mc=m[y0e:y1e+1,x0e:x1e+1]
                _,(iy_,ix_)=ndi.distance_transform_edt(~mc,return_indices=True); crop=crop[iy_,ix_]
                A[ay_:ay_+h,ax_:ax_+w]=cv2.resize(crop,(w,h),interpolation=cv2.INTER_AREA)
                RECTS[i]=(ax_,ay_,sc,x0e,y0e); FINRECTS.append([int(ax_),int(ay_),int(w),int(h)])
    for i,(m,pl_,tm_,tw_) in enumerate(PILLOWS): pillow(m,pl_,tm_,tw_,RECTS[i])
    Image.fromarray(np.clip(A,0,255).astype(np.uint8)).save(D+'/out/tex.png')
    json.dump(FINRECTS,open(D+'/out/fin_atlas.json','w'))
    json.dump(dict(sx=float((XR['upper'][1]-XR['upper'][0])/S/TEX),sy=float(np.median(np.pi*np.sqrt((((zb-zt)/2*HS)**2+(tw*WSC*WY)**2)/2))/NV)),open(D+'/out/meta.json','w'))
    json.dump(dict(V=V_,F=F_,UV=UV_,K=K_,S=S,jaw_verts=JAWV,px=dict(nose=int(NOSE),basez=float(BASEZ),S=float(S),W=int(Ww),H=int(Hh)),axis=dict(x=list(map(float,XM)),zc=list(map(float,PROF['upper'][0]))),
                   jaw=dict(axis=dict(x=list(map(float,XM)),zc=list(map(float,PROF['jaw'][0]))),head=[X(M['corner_px']),0,float(prof(np.array(X(M['corner_px'])),'jaw')[0])+float(prof(np.array(X(M['corner_px'])),'jaw')[1])],
                            tail=[X(M['jaw_front_px']),0,float(prof(np.array(X(M['jaw_front_px'])-0.02),'jaw')[0])]) if M else None),
              open(D+'/out/geo.json','w'))
    print('TSC',round(TSC,3),'WSC',round(WSC,3))
    print('verts',len(V_),'faces',len(F_),'S',S,'nose px',NOSE,'body',X0P,X1P)
if __name__=='__main__':
    exec(open(sys.argv[1]).read()); run(C)
