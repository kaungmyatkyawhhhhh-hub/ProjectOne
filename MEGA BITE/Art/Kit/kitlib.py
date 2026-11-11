import numpy as np, bpy, bmesh, json, math
from mathutils import Vector
from skimage import measure
from scipy import ndimage as ndi
from PIL import Image
M=json.load(open('kit_manifest.json'))
def srgb2lin(c):
    c=np.array(c,float)/255
    return np.where(c<=0.04045,c/12.92,((c+0.055)/1.055)**2.4)
PALETTE={}   # name -> rgb 0-255 (filled by builders), shared atlas for the whole kit
def mat(name,rgb):
    PALETTE[name]=tuple(int(v) for v in rgb)
    m=bpy.data.materials.get('K_'+name) or bpy.data.materials.new('K_'+name)
    m.use_nodes=True; b=m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value=(*srgb2lin(rgb),1); b.inputs['Roughness'].default_value=0.85
    return m
def clear():
    for o in list(bpy.data.objects): bpy.data.objects.remove(o,do_unlink=True)
    for me in list(bpy.data.meshes): bpy.data.meshes.remove(me)
def mesh_from(verts,faces,name):
    me=bpy.data.meshes.new(name); me.from_pydata([tuple(v) for v in verts],[],[tuple(f) for f in faces]); me.update()
    o=bpy.data.objects.new(name,me); bpy.context.scene.collection.objects.link(o); return o
def visual_hull(front,top,res=110,height=None):
    """front: mask [H,W] (y down), top: mask [D,Wt] (z down = towards viewer is bottom row? top view: up in image = back).
    returns verts in units where width = 1."""
    H,W=front.shape
    # resample top to the front width
    D=int(round(top.shape[0]*W/top.shape[1]))
    topr=np.array(Image.fromarray((top*255).astype(np.uint8)).resize((W,D),Image.BILINEAR))>127
    s=res/max(W,H,D)
    fW,fH,fD=max(2,int(W*s)),max(2,int(H*s)),max(2,int(D*s))
    fr=np.array(Image.fromarray((front*255).astype(np.uint8)).resize((fW,fH),Image.BILINEAR))>127
    tp=np.array(Image.fromarray((topr*255).astype(np.uint8)).resize((fW,fD),Image.BILINEAR))>127
    # vol[x,y,z]: y up
    vol=fr.T[:,::-1][:,:,None] & tp.T[:,None,:]
    vol=np.pad(vol,2)
    vol=ndi.gaussian_filter(vol.astype(float),1.0)
    v,f,_,_=measure.marching_cubes(vol,0.5)
    v=v-2
    v=v/fW  # width = 1
    v[:,0]-=0.5; v[:,2]-=fD/fW/2
    # blender: x right, y depth, z up
    verts=np.stack([v[:,0],v[:,2],v[:,1]],1)
    return verts,f
def decimate(o,ratio):
    if ratio>1: ratio=ratio/max(1,len(o.data.polygons))   # ratio>1 = target face count
    m=o.modifiers.new('d','DECIMATE'); m.ratio=ratio
    bpy.context.view_layer.objects.active=o; o.select_set(True)
    bpy.ops.object.modifier_apply(modifier='d'); o.select_set(False)
def shade_by_normal(o,mats_ldm,mask_fn=None):
    """assign light/mid/dark by face normal (light from top-front-left like the sheets)."""
    me=o.data
    for m in mats_ldm:
        if m.name not in [x.name for x in me.materials]: me.materials.append(m)
    names=[x.name for x in me.materials]
    L=Vector((-0.45,-0.55,0.7)).normalized()
    for p in me.polygons:
        n=p.normal
        if mask_fn:
            grp=mask_fn(p)
            if grp is not None:
                trip=grp
            else: trip=mats_ldm
        else: trip=mats_ldm
        d=n.dot(L)
        k=0 if (n.z>0.72 or d>0.78) else (1 if d>-0.15 else 2)
        p.material_index=names.index(trip[k].name)
def flat(o):
    for p in o.data.polygons: p.use_smooth=False

def inflated_points(front,top,res=90,power=0.5):
    """sample the surface of an 'inflated' solid that matches the front silhouette and the top-view depth."""
    H,W=front.shape
    s=res/max(H,W); fW,fH=max(3,int(W*s)),max(3,int(H*s))
    fr=np.array(Image.fromarray((front*255).astype(np.uint8)).resize((fW,fH),Image.BILINEAR))>127
    D=int(round(top.shape[0]*W/top.shape[1]))
    tp=np.array(Image.fromarray((top*255).astype(np.uint8)).resize((fW,max(3,int(D*s))),Image.BILINEAR))>127
    # top-view depth range per x column (z0,z1) in front-pixel units
    zr=[]
    for x in range(fW):
        col=np.where(tp[:,x])[0]
        zr.append((col.min(),col.max()) if len(col) else None)
    dt=ndi.distance_transform_edt(np.pad(fr,1))[1:-1,1:-1]
    pts=[]
    gmx=dt.max()
    for y in range(fH):
        row=dt[y]; mx=gmx
        if row.max()<=0: continue
        for x in range(fW):
            if not fr[y,x] or zr[x] is None: continue
            z0,z1=zr[x]; zc=(z0+z1)/2; hd=(z1-z0)/2
            f=(row[x]/mx)**power
            for z in (zc-hd*f, zc+hd*f):
                pts.append((x/fW-0.5, (z-tp.shape[0]/2)/fW, (fH-1-y)/fW))
    return np.array(pts)
def fps(points,n,seed=0,jitter=0.06):
    rng=np.random.default_rng(seed); idx=[rng.integers(len(points))]
    points=points.copy(); c=points.mean(0)
    points=c+(points-c)*(1+rng.uniform(-jitter,jitter,(len(points),1)))
    d=np.linalg.norm(points-points[idx[0]],axis=1)
    for _ in range(n-1):
        i=int(d.argmax()); idx.append(i); d=np.minimum(d,np.linalg.norm(points-points[i],axis=1))
    return points[idx]
def hull_mesh(points,name):
    from scipy.spatial import ConvexHull
    h=ConvexHull(points)
    faces=[]
    c=points.mean(0)
    for s in h.simplices:
        a,b,cc=points[s]; n=np.cross(b-a,cc-a)
        faces.append(list(s) if np.dot(n,a-c)>0 else [s[0],s[2],s[1]])
    o=mesh_from(points,faces,name)
    # merge coplanar triangles into bigger flat facets
    bm=bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.dissolve_limit(bm,angle_limit=math.radians(2),verts=bm.verts,edges=bm.edges)
    bm.to_mesh(o.data); bm.free(); flat(o); return o
