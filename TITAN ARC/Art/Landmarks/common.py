import sys, math
sys.path.insert(0, "/home/claude/props")
import bpy
from mathutils import Matrix, Vector
from lib import *
from lib import _finish, _place, PARTS
def mark(): return len(PARTS)
def ring4(m, n=4, about=(0, 0)):
    """copy the parts made since mark m around Z (4 faces)."""
    src = PARTS[m:]
    for k in range(1, n):
        R = Matrix.Translation((about[0], about[1], 0)) @ Matrix.Rotation(2 * math.pi * k / n, 4, 'Z') @ Matrix.Translation((-about[0], -about[1], 0))
        for o in src:
            c = o.copy(); c.data = o.data.copy(); bpy.context.collection.objects.link(c)
            c.data.transform(R @ o.matrix_world); c.matrix_world = Matrix.Identity(4)
            PARTS.append(c)
def arch_window(cx, cz, w, h, y, frame='gold', glass='blue', face=-1, depth=0.6, muntin='glass2'):
    """arched window on wall plane y, facing -y. cz = bottom. w,h total incl. arch."""
    r = w / 2; hb = h - r
    box((w + 1.2, depth, hb), (cx, y + face * depth / 2, cz + hb / 2), frame, 0.15)
    cyl(r + 0.6, depth, (cx, y + face * depth / 2, cz + hb), frame, seg=12, bev=0.12, rot=(90, 0, 0))
    box((w, depth + 0.1, hb), (cx, y + face * (depth / 2 + 0.05), cz + hb / 2 + 0.3), glass, 0.05)
    cyl(r, depth + 0.1, (cx, y + face * (depth / 2 + 0.05), cz + hb + 0.3), glass, seg=12, bev=0.05, rot=(90, 0, 0))
    # muntins: one vertical, one horizontal
    box((0.35, depth + 0.3, h - 0.6), (cx, y + face * (depth / 2 + 0.12), cz + (h - 0.6) / 2 + 0.3), frame, 0.05)
    box((w, depth + 0.3, 0.35), (cx, y + face * (depth / 2 + 0.12), cz + hb * 0.55), frame, 0.05)
    # glint
    box((w * 0.12, depth + 0.35, hb * 0.55), (cx - w * 0.25, y + face * (depth / 2 + 0.15), cz + hb * 0.55), muntin, 0.03, rot=(0, 20, 0))
def railing(w, cz, y, h=3.0, posts=None, col='white', face=-1):
    """front railing along x at plane y."""
    box((w, 0.7, 0.6), (0, y, cz + h), col, 0.2)
    box((w, 0.5, 0.4), (0, y, cz + 0.6), col, 0.15)
    n = posts or max(3, int(w / 3))
    for i in range(n + 1):
        x = -w / 2 + i * w / n
        box((0.55, 0.55, h), (x, y, cz + h / 2), col, 0)
import bmesh
def clip_below(o, z):
    """cut a part's mesh at world height z and drop what's below (arches from tori)."""
    me = o.data; mw = o.matrix_world
    bm = bmesh.new(); bm.from_mesh(me)
    co = mw.inverted() @ Vector((0, 0, z)); no = (mw.inverted().to_3x3() @ Vector((0, 0, 1))).normalized()
    bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=co, plane_no=no, clear_inner=True)
    bm.to_mesh(me); bm.free()
