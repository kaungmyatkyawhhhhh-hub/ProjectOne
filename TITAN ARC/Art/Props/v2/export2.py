import bpy, bmesh
from mathutils import Vector
bpy.ops.wm.open_mainfile(filepath="/home/claude/props/out/rubble.blend")
with bpy.data.libraries.load("/home/claude/props/out2/props.blend") as (src, dst):
    dst.objects = [n for n in src.objects if n.startswith("ShopRow_")]
for o in dst.objects: bpy.context.scene.collection.objects.link(o)
for o in bpy.data.objects:
    if o.name.startswith("Rubble_"):
        me = o.data; mw = o.matrix_world
        bm = bmesh.new(); bm.from_mesh(me)
        loc = mw.inverted() @ Vector((0, 0, 0))
        bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=loc, plane_no=(0, 0, 1), clear_inner=True)
        bm.to_mesh(me); bm.free()
        # give the cut faces (no UV meaning) the palette colour already on them: the UV is copied from the cut edges, fine
        bpy.context.view_layer.objects.active = o; o.select_set(True); bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS'); o.select_set(False)
        print(o.name, [round(d, 2) for d in o.dimensions])
for o in bpy.data.objects: o.select_set(o.type == 'MESH')
bpy.ops.export_scene.fbx(filepath="/home/claude/props/out2/StompProps_v2.fbx", use_selection=True, object_types={'MESH'}, mesh_smooth_type='FACE', axis_forward='-Z', axis_up='Y', path_mode='STRIP', add_leaf_bones=False)
bpy.ops.wm.save_as_mainfile(filepath="/home/claude/props/out2/v2.blend")
