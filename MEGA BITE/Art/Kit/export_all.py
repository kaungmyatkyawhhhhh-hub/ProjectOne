import bpy
exec(open('build_rocks.py').read())
G={'Mesa':[o.name for o in objs['Mesa']],'Boulder_Flat':['Boulder_Flat'],'Boulder_Round':['Boulder_Round'],'Spire':[o.name for o in objs['Spire']]}
NOCLEAR=True
exec(open('build_plants.py').read())
G.update({k:[o.name for o in v] for k,v in objs.items() if k in ('SeaPalm','BubbleCoral','Kelp','Starfish')})
GROUPS=G; NAME='MB_Kit_A'
exec(open('export_kit.py').read())
bpy.ops.wm.save_as_mainfile(filepath='/home/claude/megabite_art/kit/MB_Kit_A.blend')
