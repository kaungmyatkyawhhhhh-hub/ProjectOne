# MEGA BITE trench jellyfish, built by code (our own model). Parts exported as separate meshes so Roblox can
# give each its own material: Bell (translucent glass), Rim (neon frill), Core (neon heart), Arms (frilly oral arms), Tentacles (thin trailing lines).
import bpy, bmesh, math, random
from mathutils import Vector
random.seed(4)
bpy.ops.wm.read_factory_settings(use_empty=True)
def obj(name, bm):
    me=bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o=bpy.data.objects.new(name,me); bpy.context.collection.objects.link(o); return o
def bell_profile(t):  # t 0 (top) .. 1 (rim): radius, height
    a=t*math.pi*0.5
    r=math.sin(a)*1.0
    h=math.cos(a)*0.75
    return r,h
# --- Bell: a scalloped dome (16 lobes), double-sided shell
SEG,RING=48,14
bm=bmesh.new(); rows=[]
for i in range(RING+1):
    t=i/RING; r,h=bell_profile(t); row=[]
    for j in range(SEG):
        a=j/SEG*2*math.pi
        lobe=1+0.06*math.cos(a*16)*t**3      # scallops grow toward the rim
        rr=r*lobe*(1+0.04*math.sin(t*math.pi))
        row.append(bm.verts.new((rr*math.cos(a), rr*math.sin(a), h - (0.06*t**4*(1+math.cos(a*16))))))
    rows.append(row)
top=bm.verts.new((0,0,0.76))
for j in range(SEG): bm.faces.new((top,rows[1][j],rows[1][(j+1)%SEG])) if False else None
for j in range(SEG): bm.faces.new((top,rows[0][(j+1)%SEG],rows[0][j]))
for i in range(RING):
    for j in range(SEG):
        a,b,c,d=rows[i][j],rows[i][(j+1)%SEG],rows[i+1][(j+1)%SEG],rows[i+1][j]
        bm.faces.new((a,d,c,b))
# inner shell (so it reads from below; Roblox draws one side)
inner=[]
for i in range(RING+1):
    row=[]
    for j in range(SEG):
        v=rows[i][j].co*0.93; v.z-=0.04; row.append(bm.verts.new(v))
    inner.append(row)
for i in range(RING):
    for j in range(SEG):
        a,b,c,d=inner[i][j],inner[i][(j+1)%SEG],inner[i+1][(j+1)%SEG],inner[i+1][j]
        bm.faces.new((a,b,c,d))
for j in range(SEG):  # close the lip
    bm.faces.new((rows[RING][j],inner[RING][j],inner[RING][(j+1)%SEG],rows[RING][(j+1)%SEG]))
bmesh.ops.recalc_face_normals(bm,faces=bm.faces[:]) if False else None
obj("Bell",bm)
# --- Rim: a wavy neon frill ring just under the bell edge
bm=bmesh.new(); n=96; outer=[];inn=[]
for j in range(n):
    a=j/n*2*math.pi; w=0.05*math.sin(a*16)
    r0,h0=bell_profile(1.0)
    outer.append(bm.verts.new(((r0+0.07)*math.cos(a),(r0+0.07)*math.sin(a),h0-0.1+w)))
    inn.append(bm.verts.new(((r0-0.05)*math.cos(a),(r0-0.05)*math.sin(a),h0-0.02+w)))
for j in range(n):
    k=(j+1)%n; bm.faces.new((outer[j],outer[k],inn[k],inn[j]))
obj("Rim",bm)
# --- Core: 4-lobed glowing heart (gonads, the classic four-leaf clover) inside the bell
bm=bmesh.new()
for q in range(4):
    a=q*math.pi/2+math.pi/4
    c=Vector((0.28*math.cos(a),0.28*math.sin(a),0.42))
    s=bmesh.ops.create_uvsphere(bm,u_segments=12,v_segments=8,radius=0.16)
    for v in s['verts']:
        v.co=Vector((v.co.x*1.25,v.co.y*0.75,v.co.z*0.6))
        v.co.rotate(__import__('mathutils').Euler((0,0,a)))
        v.co+=c
obj("Core",bm)
# --- Oral arms: 4 ruffled ribbons twisting down from the centre
def ribbon(bm,path,width,twist,ruffle):
    prev=None
    for k,(p,t) in enumerate(path):
        ang=twist*t
        side=Vector((math.cos(ang),math.sin(ang),0))*width*(1-0.6*t)*(1+ruffle*math.sin(t*30))
        a=bm.verts.new(p+side); b=bm.verts.new(p-side)
        if prev:
            bm.faces.new((prev[0],prev[1],b,a))
        prev=(a,b)
bm=bmesh.new()
for q in range(4):
    a0=q*math.pi/2; path=[]
    for k in range(40):
        t=k/39; r=0.12+0.1*t
        path.append((Vector((r*math.cos(a0+t*2.2),r*math.sin(a0+t*2.2),0.1-2.2*t)),t))
    ribbon(bm,path,0.13,7,0.25)
obj("Arms",bm)
# --- Tentacles: 16 thin tapered tubes trailing from the rim, gently wavy
bm=bmesh.new()
for q in range(16):
    a0=q/16*2*math.pi; r0,h0=bell_profile(1.0); L=random.uniform(2.6,3.6)
    pts=[]
    for k in range(18):
        t=k/17; wob=0.22*math.sin(t*7+q*1.3)*t
        pts.append(Vector(((r0-0.08)*math.cos(a0)*(1-0.25*t)+wob*math.cos(a0+1.57),(r0-0.08)*math.sin(a0)*(1-0.25*t)+wob*math.sin(a0+1.57),h0-0.08-L*t)))
    ringsv=[]
    for k,p in enumerate(pts):
        rad=0.022*(1-0.7*k/17); ring=[]
        for m in range(3):
            b=m/3*2*math.pi; ring.append(bm.verts.new(p+Vector((rad*math.cos(b),rad*math.sin(b),0))))
        ringsv.append(ring)
    for k in range(17):
        for m in range(3):
            a,b,c,d=ringsv[k][m],ringsv[k][(m+1)%3],ringsv[k+1][(m+1)%3],ringsv[k+1][m]
            bm.faces.new((a,b,c,d))
obj("Tentacles",bm)
for o in bpy.data.objects:
    bpy.context.view_layer.objects.active=o; o.select_set(True)
    m=o.modifiers.new("t","TRIANGULATE")
for o in bpy.data.objects:
    o.select_set(False)
tris=0
for o in bpy.data.objects:
    me=o.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh(); tris+=sum(len(p.vertices)-2 for p in me.polygons); print(o.name,len(me.polygons))
print("tris",tris)
# scale to ~8 studs bell diameter (Roblox: 1 unit = 1 stud with FBX scale fix below)
for o in bpy.data.objects: o.scale=(4,4,4)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.transform_apply(scale=True)
bpy.ops.export_scene.fbx(filepath='/tmp/claude-0/jelly/mb_jelly.fbx',use_selection=False,apply_unit_scale=True,global_scale=1.0,add_leaf_bones=False,mesh_smooth_type='FACE',axis_forward='-Z',axis_up='Y')
# preview render
import bpy
for o in bpy.data.objects:
    mat=bpy.data.materials.new(o.name); mat.use_nodes=True
    bsdf=mat.node_tree.nodes['Principled BSDF']
    col={'Bell':(0.6,0.3,1,1),'Rim':(1,0.3,0.8,1),'Core':(1,0.5,0.9,1),'Arms':(0.9,0.5,1,1),'Tentacles':(0.8,0.6,1,1)}[o.name]
    bsdf.inputs['Base Color'].default_value=col
    if o.name!='Bell': bsdf.inputs['Emission Color'].default_value=col; bsdf.inputs['Emission Strength'].default_value=3
    else: bsdf.inputs['Alpha'].default_value=0.45
    o.data.materials.append(mat)
cam=bpy.data.cameras.new('c'); co=bpy.data.objects.new('c',cam); bpy.context.collection.objects.link(co)
co.location=(17,-17,-5); co.rotation_euler=(math.radians(92),0,math.radians(45)); bpy.context.scene.camera=co
w=bpy.data.worlds.new('w'); w.use_nodes=True; w.node_tree.nodes['Background'].inputs[0].default_value=(0.03,0.01,0.03,1); bpy.context.scene.world=w
s=bpy.context.scene; s.render.engine='CYCLES'; s.cycles.samples=24; s.cycles.device='CPU'
s.render.resolution_x=600; s.render.resolution_y=700; s.render.filepath='/tmp/claude-0/jelly/preview.png'
l=bpy.data.lights.new('l','SUN'); lo=bpy.data.objects.new('l',l); bpy.context.collection.objects.link(lo); lo.rotation_euler=(0.6,0.3,0.5); l.energy=3
bpy.ops.render.render(write_still=True)
