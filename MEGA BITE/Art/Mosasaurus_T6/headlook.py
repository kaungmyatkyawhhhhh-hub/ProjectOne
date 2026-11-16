import bpy, math
from mathutils import Vector
sc=bpy.context.scene; sc.render.engine='BLENDER_WORKBENCH'; sh=sc.display.shading; sh.light='STUDIO'; sh.color_type='VERTEX'; sh.background_type='VIEWPORT'; sh.background_color=(0.05,0.15,0.3)
cam=sc.camera; cam.data.type='PERSP'; cam.data.lens=50
t=Vector((2.4,0,0.0)); p=t+Vector((0.7,-0.6,0.3)).normalized()*2.6
cam.location=p; cam.rotation_euler=(t-p).to_track_quat('-Z','Y').to_euler()
sc.render.resolution_x,sc.render.resolution_y=700,500; sc.render.filepath=bpy.path.abspath('//head34.png'); bpy.ops.render.render(write_still=True)
n=sum(1 for p in bpy.data.objects['M6_LowerJaw'].data.polygons if p.normal.z>0.5)
print('jaw top faces',n)
