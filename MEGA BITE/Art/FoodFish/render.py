"""Render check views of a generated fish: side / top / front (ortho, for the sheet compare) + 3/4 + below.
python3 render.py <Species>"""
import sys, os, math, json
import bpy
from mathutils import Vector
import numpy as np
from PIL import Image
SP = sys.argv[1]; OUT = f'/home/claude/megabite_fish/out/{SP}'
bpy.ops.wm.open_mainfile(filepath=f'{OUT}/{SP}.blend')
sc = bpy.context.scene
sc.render.engine = 'BLENDER_WORKBENCH'
sh = sc.display.shading
sh.light = 'STUDIO'; sh.color_type = 'TEXTURE'; sh.show_backface_culling = True
sc.render.film_transparent = False
sc.world = sc.world or bpy.data.worlds.new('W')
sh.background_type = 'VIEWPORT' if hasattr(sh, 'background_type') else None
sc.render.resolution_x, sc.render.resolution_y = 900, 600
ob = bpy.data.objects[SP]
bb = [ob.matrix_world @ Vector(c) for c in ob.bound_box]
mn = Vector((min(v.x for v in bb), min(v.y for v in bb), min(v.z for v in bb)))
mx = Vector((max(v.x for v in bb), max(v.y for v in bb), max(v.z for v in bb)))
cen = (mn + mx) / 2; size = (mx - mn).length
cam_d = bpy.data.cameras.new('C'); cam = bpy.data.objects.new('C', cam_d); sc.collection.objects.link(cam); sc.camera = cam
def shot(name, pos, ortho=True, scale=None, backface=False):
    sh.show_backface_culling = True
    cam_d.type = 'ORTHO' if ortho else 'PERSP'
    if ortho: cam_d.ortho_scale = scale or size * 1.05
    else: cam_d.lens = 50
    cam.location = cen + pos
    d = (cen - cam.location); cam.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
    if abs(d.normalized().z) > 0.99: cam.rotation_euler = d.to_track_quat('-Z', 'X').to_euler()
    sc.render.filepath = f'{OUT}/r_{name}.png'
    bpy.ops.render.render(write_still=True)
L = mx.x - mn.x
shot('side', Vector((0, -size * 3, 0)), scale=L * 1.1)
shot('top', Vector((0, 0, size * 3)), scale=L * 1.1)
shot('front', Vector((size * 3, 0, 0)), scale=(mx.z - mn.z) * 1.6)
shot('q34', Vector((size * 0.9, -size * 1.1, size * 0.5)), ortho=False)
shot('back34', Vector((-size * 1.0, size * 0.9, size * 0.45)), ortho=False)
shot('below', Vector((size * 0.6, -size * 0.7, -size * 0.9)), ortho=False)
ims = [Image.open(f'{OUT}/r_{n}.png').convert('RGB') for n in ('side', 'top', 'front', 'q34', 'back34', 'below')]
sheet = Image.open(f'/mnt/user-data/uploads/Claude+Obsidian/MEGA BITE/Art/FoodFish/{SP}/{SP}_sheet_chatgpt.png').convert('RGB').resize((900, 600))
c = Image.new('RGB', (2700, 1200), (30, 30, 30))
c.paste(sheet, (0, 0)); c.paste(ims[0], (900, 0)); c.paste(ims[1], (1800, 0))
c.paste(ims[2], (0, 600)); c.paste(ims[3], (900, 600)); c.paste(ims[4], (1800, 600))
c.resize((1350, 600)).save(f'{OUT}/{SP}_check.png')
ims[5].resize((450, 300)).save(f'{OUT}/{SP}_below.png')
print('ok')
