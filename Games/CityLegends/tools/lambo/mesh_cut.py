"""Deleting faces without losing a model's shading. bmesh drops the custom normals a converted car
carries, and the rest of that part then shades in dark flat shapes (the LP560 Spyder's dash), so
they are read first and put back."""

import bmesh


def delete_faces(o, drop):
    """o: mesh object; drop: polygon indices to delete"""
    me = o.data
    drop = set(drop)
    if not drop:
        return
    normals = [tuple(n.vector) for n in me.corner_normals]
    kept = []
    for p in me.polygons:
        if p.index not in drop:
            kept += [normals[li] for li in p.loop_indices]
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[bm.faces[i] for i in drop], context="FACES")
    bm.to_mesh(me)
    bm.free()
    me.normals_split_custom_set(kept)
