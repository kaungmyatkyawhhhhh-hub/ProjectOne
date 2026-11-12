import bpy, math, sys, os
from mathutils import Vector
T={'SeaFan':1300,'BrainCoral':2000,'BranchCoral':1000}
def load():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath='/tmp/claude-0/lod/MB_Kit_B.fbx')
def tris(o): return sum(len(p.vertices)-2 for p in o.data.polygons)
def render(o,tag):
    sc=bpy.context.scene
    for x in bpy.data.objects: x.hide_render = (x is not o and x.type=='MESH')
    sc.render.engine='BLENDER_WORKBENCH'; sh=sc.display.shading; sh.light='STUDIO'; sh.color_type='TEXTURE'; sh.show_backface_culling=True
    sc.render.film_transparent=False; w=bpy.data.worlds.get('W') or bpy.data.worlds.new('W'); sc.world=w; w.color=(0.25,0.55,0.85)
    sc.render.resolution_x=600; sc.render.resolution_y=450
    cam=bpy.data.objects.get('C')
    if not cam:
        cd=bpy.data.cameras.new('C'); cam=bpy.data.objects.new('C',cd); sc.collection.objects.link(cam); sc.camera=cam
    d=max(o.dimensions); c=o.matrix_world@Vector((0,0,0))
    bb=[o.matrix_world@Vector(b) for b in o.bound_box]; cen=sum(bb,Vector())/8
    cam.data.lens=50; p=cen+Vector((d*0.9,-d*1.9,d*0.8)); cam.location=p; cam.rotation_euler=(cen-p).to_track_quat('-Z','Y').to_euler()
    sc.render.filepath=f'/tmp/claude-0/lod/r_{tag}.png'; bpy.ops.render.render(write_still=True)
load()
for nm in T: render(bpy.data.objects[nm],nm+'_hi'); print(nm,'hi tris',tris(bpy.data.objects[nm]))
for nm,tg in T.items():
    o=bpy.data.objects[nm]; bpy.context.view_layer.objects.active=o
    m=o.modifiers.new('d','DECIMATE'); m.decimate_type='COLLAPSE'; m.ratio=tg/tris(o); m.use_collapse_triangulate=True; m.delimit={'UV'}
    bpy.ops.object.modifier_apply(modifier='d')
    print(nm,'lo tris',tris(o)); render(o,nm+'_lo')
    # export alone: same axes as export_kit, origin already bottom-centre; move to 0
    loc=o.location.copy(); o.location=(0,0,0)
    bpy.ops.object.select_all(action='DESELECT'); o.select_set(True)
    bpy.ops.export_scene.fbx(filepath=f'/tmp/claude-0/lod/MB_{nm}_LOD.fbx',use_selection=True,object_types={'MESH'},path_mode='COPY',embed_textures=True,apply_unit_scale=True,mesh_smooth_type='FACE',axis_forward='-Z',axis_up='Y')
    o.location=loc
    print(nm,'dims',tuple(round(x,3) for x in o.dimensions))
