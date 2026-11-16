import bpy, sys
fbx=sys.argv[sys.argv.index('--')+1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=fbx)
for o in bpy.context.scene.objects:
    if o.type=='ARMATURE': print('ARM',o.name,[b.name for b in o.data.bones])
    if o.type=='MESH':
        me=o.data; vg={g.index:g.name for g in o.vertex_groups}
        mx=max(len([g for g in v.groups if g.weight>0.004]) for v in me.vertices)
        unw=sum(1 for v in me.vertices if not v.groups)
        imgs=[n.image.name for m in me.materials for n in m.node_tree.nodes if n.type=='TEX_IMAGE' and n.image]
        print('MESH',o.name,'tris',sum(len(p.vertices)-2 for p in me.polygons),'max infl',mx,'unweighted',unw,'groups',len(vg),'uv',len(me.uv_layers),'img',imgs, 'size',[round(v,2) for v in o.dimensions])
print('packed', [i.name for i in bpy.data.images if i.packed_file])
