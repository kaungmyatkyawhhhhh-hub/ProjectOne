import bpy, json
from mathutils import Vector, Matrix

PARTS = json.load(open(r"C:\Users\kaung\AppData\Local\Temp\claude\c29817fd9653d23b\10817e82-c703-454d-ac35-8c0300f85304\scratchpad\tpl\parts.json"))
TEX = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Assets\pick_card_gfx\textures"
MAP0 = {'Gfxhero1': 'LeftLowerArm', 'Gfxhero10': 'RightUpperArm', 'Gfxhero11': 'LowerTorso', 'Gfxhero12': 'RightLowerArm',
       'Gfxhero13': 'LeftUpperArm', 'Gfxhero14': 'RightLowerLeg', 'Gfxhero15': 'Head', 'Gfxhero2': 'LeftUpperLeg',
       'Gfxhero3': 'LeftLowerLeg', 'Gfxhero4': 'RightFoot', 'Gfxhero5': 'LeftHand', 'Gfxhero6': 'RightUpperLeg',
       'Gfxhero7': 'LeftFoot', 'Gfxhero8': 'RightHand', 'Gfxhero9': 'UpperTorso'}
W, H = 585.0, 559.0
# classic template: per region the six faces as (x, y, w, h) in pixels
TORSO = dict(F=(231, 74, 128, 128), B=(427, 74, 128, 128), R=(165, 74, 64, 128), L=(361, 74, 64, 128), U=(231, 8, 128, 64), D=(231, 204, 128, 64))
RLIMB = dict(L=(19, 355, 64, 128), B=(85, 355, 64, 128), R=(151, 355, 64, 128), F=(217, 355, 64, 128), U=(217, 289, 64, 64), D=(217, 485, 64, 64))
LLIMB = dict(F=(308, 355, 64, 128), L=(374, 355, 64, 128), B=(440, 355, 64, 128), R=(506, 355, 64, 128), U=(308, 289, 64, 64), D=(308, 485, 64, 64))
# each part: region, vertical band (top, bottom) of the 128 px side faces, is it the chain's top / bottom part
CHAIN = {
    'UpperTorso': (TORSO, 0.0, 0.74, True, False), 'LowerTorso': (TORSO, 0.74, 1.0, False, True),
    'RightUpperArm': (RLIMB, 0.0, 0.46, True, False), 'RightLowerArm': (RLIMB, 0.46, 0.81, False, False), 'RightHand': (RLIMB, 0.81, 1.0, False, True),
    'LeftUpperArm': (LLIMB, 0.0, 0.46, True, False), 'LeftLowerArm': (LLIMB, 0.46, 0.81, False, False), 'LeftHand': (LLIMB, 0.81, 1.0, False, True),
    'RightUpperLeg': (RLIMB, 0.0, 0.48, True, False), 'RightLowerLeg': (RLIMB, 0.48, 0.87, False, False), 'RightFoot': (RLIMB, 0.87, 1.0, False, True),
    'LeftUpperLeg': (LLIMB, 0.0, 0.48, True, False), 'LeftLowerLeg': (LLIMB, 0.48, 0.87, False, False), 'LeftFoot': (LLIMB, 0.87, 1.0, False, True),
}

def to_rbx(v):
    return Vector((v.x, v.z, -v.y))

def frame(n):
    a = PARTS[n]
    return Vector(a[0:3]), Matrix(((a[3], a[4], a[5]), (a[6], a[7], a[8]), (a[9], a[10], a[11]))), Vector(a[12:15])

def uv_px(rect, fu, fv):
    x, y, w, h = rect
    return Vector(((x + fu * w) / W, 1 - (y + fv * h) / H))

def mat(name, build):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    build(nt)
    return m

def img(path):
    return bpy.data.images.load(path, check_existing=True)

def body_mat(nt):
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    bs = nt.nodes.new('ShaderNodeBsdfPrincipled')
    t = nt.nodes.new('ShaderNodeTexImage')
    t.image = img(TEX + r"\hero_clothing_composite.png")
    t.interpolation = 'Cubic'
    t.extension = 'EXTEND'
    nt.links.new(t.outputs['Color'], bs.inputs['Base Color'])
    bs.inputs['Roughness'].default_value = 0.55
    nt.links.new(bs.outputs[0], out.inputs[0])

def head_mat(nt):
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    bs = nt.nodes.new('ShaderNodeBsdfPrincipled')
    t = nt.nodes.new('ShaderNodeTexImage')
    t.image = img(TEX + r"\face.png")
    t.interpolation = 'Cubic'
    t.extension = 'CLIP'
    mix = nt.nodes.new('ShaderNodeMix')
    mix.data_type = 'RGBA'
    mix.inputs[6].default_value = (0.82, 0.48, 0.29, 1)
    nt.links.new(t.outputs['Alpha'], mix.inputs[0])
    nt.links.new(t.outputs['Color'], mix.inputs[7])
    nt.links.new(mix.outputs[2], bs.inputs['Base Color'])
    bs.inputs['Roughness'].default_value = 0.5
    nt.links.new(bs.outputs[0], out.inputs[0])

MB = mat('HeroBody', body_mat)
MH = mat('HeroHead', head_mat)

MAP = {'Hero_' + v: v for v in MAP0.values()}
for oname, pname in MAP.items():
    o = bpy.data.objects[oname]
    me = o.data
    pos, R, size = frame(pname)
    Rt = R.transposed()
    loc = {v.index: Rt @ (to_rbx(o.matrix_world @ v.co) - pos) for v in me.vertices}
    keep = me.materials[0] if len(me.materials) else MB
    uvl = me.uv_layers.active or me.uv_layers.new()
    for p in me.polygons:
        n = Rt @ to_rbx((o.matrix_world.to_3x3() @ p.normal).normalized())
        for li in p.loop_indices:
            q = loc[me.loops[li].vertex_index]
            if pname == 'Head':
                # front of the head is -Z; the decal covers the head's front face
                if n.z < -0.15:
                    uvl.data[li].uv = Vector((0.5 - q.x / 1.25, 0.5 + (q.y + 0.02) / 1.25))
                else:
                    uvl.data[li].uv = Vector((5, 5))
                continue
            reg, t0, t1, top, bot = CHAIN[pname]
            sx, sy, sz = size.x, size.y, size.z
            fx, fy, fz = q.x / sx + 0.5, q.y / sy + 0.5, q.z / sz + 0.5
            fx, fy, fz = [min(max(f, 0.0), 1.0) for f in (fx, fy, fz)]
            ax = max(((abs(n.x), 'x'), (abs(n.y), 'y'), (abs(n.z), 'z')))[1]
            if ax == 'y' and (abs(n.y) < 0.85 or not ((n.y > 0 and top and fy > 0.8) or (n.y < 0 and bot and fy < 0.2))):
                ax = 'x' if abs(n.x) >= abs(n.z) else 'z'
            if pname == 'UpperTorso' and ax == 'x' and fy < 0.8:
                ax = 'z'
            band = t0 + (1 - fy) * (t1 - t0)
            if ax == 'z':
                uv = uv_px(reg['F'], 1 - fx, band) if n.z < 0 else uv_px(reg['B'], fx, band)
            elif ax == 'x':
                uv = uv_px(reg['R'], fz, band) if n.x > 0 else uv_px(reg['L'], 1 - fz, band)
            else:
                uv = uv_px(reg['U'], 1 - fx, 1 - fz) if n.y > 0 else uv_px(reg['D'], 1 - fx, fz)
            uvl.data[li].uv = uv
    o.name = 'Hero_' + pname
print('done')
