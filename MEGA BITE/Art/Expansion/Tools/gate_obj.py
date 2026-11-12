"""Gate for hand-built models (skill step 4): rasterise the model's three orthographic silhouettes at the sheet's pixel
scale (one uniform scale per view from the sheet's own view size; aspect kept, never stretched; centred on the view's
bbox), IoU per view >= 0.90, open edges, and a mismatch overlay (white both, green sheet only, red model only).
Model axes: X = length (front of the object +X, nose right in the side view), Y = depth, Z = up."""
import sys, json, numpy as np, cv2, trimesh
from PIL import Image
sys.path.insert(0, '/tmp/claude-0/hk'); import hk
def run(obj, cfg, out):
    C = json.load(open(cfg)); SH, V, bb, PAL = hk.analyse(C)
    sc = trimesh.load(obj, force='scene', process=False)
    meshes = [g for g in sc.geometry.values()]
    P = []; F = []; off = 0; open_e = 0
    for m in meshes:
        v = np.asarray(m.vertices); P.append(v); F.append(np.asarray(m.faces) + off); off += len(v)
        mm = trimesh.Trimesh(v, m.faces, process=True); open_e += len(trimesh.grouping.group_rows(mm.edges_sorted, require_count=1))
    P = np.concatenate(P); F = np.concatenate(F)
    P = np.stack([P[:, 0], -P[:, 2], P[:, 1]], 1)      # OBJ y-up -> model (x, y, z)
    mn, mx = P.min(0), P.max(0); ext = mx - mn; ctr = (mn + mx) / 2
    HW = V['side'].shape
    AN = C.get('anchor', {})
    def view(k, ax_u, ax_v, flip_u=1, size_axis='u'):
        x0, x1, y0, y1 = bb[k]
        if k in AN:     # explicit registration: the model origin's pixel and px per stud in this view (measured)
            au, av, s = AN[k]
            u = au + flip_u * P[:, ax_u] * s; v = av - P[:, ax_v] * s
        else:
            s = ((x1 - x0 + 1) / ext[ax_u]) if size_axis == 'u' else ((y1 - y0 + 1) / ext[ax_v])
            u = (x0 + x1) / 2 + flip_u * (P[:, ax_u] - ctr[ax_u]) * s; v = (y0 + y1) / 2 - (P[:, ax_v] - ctr[ax_v]) * s
        im = np.zeros(HW, np.uint8); pts = np.stack([u, v], 1)
        for f in F: cv2.fillConvexPoly(im, np.round(pts[f]).astype(np.int32), 1)
        return im.astype(bool), s
    sideR, s_s = view('side', 0, 2, size_axis=C.get('side_size', 'u'))
    topR, s_t = view('top', 0, 1, size_axis=C.get('top_size', 'u'), flip_u=1)
    frontR, s_f = view('front', 1, 2, size_axis=C.get('front_size', 'v'))
    iou = lambda a, b: float((a & b).sum() / max(1, (a | b).sum()))
    g = dict(side_iou=round(iou(sideR, V['side']), 3), top_iou=round(iou(topR, V['top']), 3), front_iou=round(iou(frontR, V['front']), 3),
             open_edges=int(open_e), tris=int(len(F)), size_studs=[round(float(e), 1) for e in ext],
             px_per_stud=dict(side=round(s_s, 3), top=round(s_t, 3), front=round(s_f, 3)))
    g['pass'] = all(g[k] >= 0.90 for k in ('side_iou', 'top_iou', 'front_iou')) and open_e == 0
    ov = np.zeros(HW + (3,), np.uint8)
    for R_, M_ in ((sideR, V['side']), (topR, V['top']), (frontR, V['front'])):
        ov[R_ & M_] = (235, 235, 235); ov[M_ & ~R_] = (40, 200, 60); ov[R_ & ~M_] = (230, 50, 50)
    Image.fromarray(ov).resize((HW[1] // 2, HW[0] // 2)).save(out + '/mismatch.png')
    json.dump(g, open(out + '/gates.json', 'w'), indent=1); print(json.dumps(g)); return g
if __name__ == '__main__': run(sys.argv[1], sys.argv[2], sys.argv[3])
