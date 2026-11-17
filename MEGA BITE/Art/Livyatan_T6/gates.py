# hard gates: open edges, outward normals per island, flippers and crystals rooted in the body
import bpy, bmesh
from mathutils.bvhtree import BVHTree
from mathutils import Vector
objs=[o for o in bpy.data.objects if o.name.startswith('L6_')]
bad=0
for o in objs:
    bm=bmesh.new(); bm.from_mesh(o.data)
    ob=[e for e in bm.edges if not e.is_manifold]
    seen=set(); inward=0; islands=0
    for f0 in bm.faces:
        if f0.index in seen: continue
        isl=[]; stack=[f0]; seen.add(f0.index)
        while stack:
            f=stack.pop(); isl.append(f)
            for e in f.edges:
                for g in e.link_faces:
                    if g.index not in seen: seen.add(g.index); stack.append(g)
        islands+=1
        c=sum((v.co for f in isl for v in f.verts),Vector())/sum(len(f.verts) for f in isl)
        if 'Runes' in o.name:   # thin strips bent round the body: the centroid test misfires, use the signed volume
            vol=sum(f.verts[0].co.dot(f.verts[i].co.cross(f.verts[i+1].co)) for f in isl for i in range(1,len(f.verts)-1))
            if vol<0: inward+=1
            continue
        n_in=sum(1 for f in isl if f.normal.dot(f.calc_center_median()-c)<0)
        if n_in>len(isl)*0.25: inward+=1
    if ob or inward: bad+=1; print('FAIL',o.name,'open',len(ob),'inward islands',inward,'of',islands)
    bm.free()
def bvh(name):
    bm=bmesh.new(); bm.from_mesh(bpy.data.objects[name].data); return BVHTree.FromBMesh(bm)
body=[bvh(n) for n in tuple(o.name for o in objs if 'Segment' in o.name or o.name in ('L6_UpperHead','L6_TailStock'))]
def inside(p):
    for t in body:
        n=0; q=p.copy()
        for _ in range(20):
            h=t.ray_cast(q,Vector((0,0,1)))
            if h[0] is None: break
            n+=1; q=h[0]+Vector((0,0,1e-4))
        if n%2: return True
    return False
for o in objs:
    if 'PectoralFin' in o.name or 'TailFluke' in o.name or 'Jaw' in o.name:
        k=sum(inside(v.co) for v in o.data.vertices)
        if k<3: bad+=1; print('FAIL not rooted',o.name,k)
print('parts',len(objs),'GATES','PASS' if not bad else 'FAIL %d'%bad)
