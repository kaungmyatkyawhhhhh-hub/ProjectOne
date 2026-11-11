# usage: python3 fincheck.py <dir> <generator.py>
import sys, os
d, gen = sys.argv[1], sys.argv[2]
os.chdir(d); sys.argv=[gen]
WITH_RIG=False
exec(open(gen).read())
import bmesh, numpy as np
from mathutils.bvhtree import BVHTree
me=ob.data; keys=[k for _,k in FACES]
bm=bmesh.new(); bm.from_mesh(me); bm.faces.ensure_lookup_table(); bm.verts.ensure_lookup_table(); bm.normal_update()
bodyf=[f for f,k in zip(bm.faces,keys) if k in ('body','head_front')]
bv=list({v for f in bodyf for v in f.verts}); vi={v:i for i,v in enumerate(bv)}
bvh=BVHTree.FromPolygons([v.co.copy() for v in bv],[[vi[v] for v in f.verts] for f in bodyf])
def inside(p):
    hits=0; o=p.copy(); dr=Vector((0.0123,0.0071,0.9999)).normalized()
    for _ in range(50):
        h=bvh.ray_cast(o,dr)
        if h[0] is None: break
        hits+=1; o=h[0]+dr*1e-5
    return hits%2==1
finf=[f for f,k in zip(bm.faces,keys) if k=='fin']
seen=set(); res=[]
for f0 in finf:
    if f0.index in seen: continue
    isl=[]; st=[f0]; seen.add(f0.index)
    while st:
        f=st.pop(); isl.append(f)
        for e in f.edges:
            for g in e.link_faces:
                if g.index not in seen and keys[g.index]=='fin': seen.add(g.index); st.append(g)
    vs=list({v for f in isl for v in f.verts})
    ins=sum(inside(v.co) for v in vs)
    dmin=min((bvh.find_nearest(v.co)[3] for v in vs))/S
    c=sum((v.co for v in vs),Vector())/len(vs)
    res.append((round(PX(c.x)),round(PY(c.z)),round(c.y/S),len(vs),ins,round(dmin,1)))
for r in sorted(res): print('fin @px%d py%d lat%d verts %d inside %d mindist %.1fpx'%r, '<-- DETACHED' if r[4]==0 and r[5]>0.5 else ('<-- barely' if r[4]<3 else ''))
