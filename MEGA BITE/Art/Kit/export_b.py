import bpy
exec(open('build_corals.py').read())
GROUPS={k:[o.name for o in v] for k,v in objs.items()}; NAME='MB_Kit_B'
exec(open('export_kit.py').read())
