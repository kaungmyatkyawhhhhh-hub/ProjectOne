import sys, os, numpy as np, trimesh
sys.path.insert(0, os.path.dirname(__file__))
from creatures import ALL
from torii import torii
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
from matplotlib.colors import to_rgb, hsv_to_rgb

OUT = sys.argv[1]; PREV = sys.argv[2]
os.makedirs(OUT, exist_ok=True); os.makedirs(PREV, exist_ok=True)

def export(name, parts):
    scene = trimesh.Scene()
    obj_lines = []; voff = 0; tris = 0
    for pname, meshes in parts.items():
        m = trimesh.util.concatenate(meshes)
        tris += len(m.faces)
        scene.add_geometry(m, node_name=pname, geom_name=pname)
        obj_lines.append(f"o {pname}")
        obj_lines += [f"v {x:.4f} {y:.4f} {z:.4f}" for x, y, z in m.vertices]
        obj_lines += [f"f {a+1+voff} {b+1+voff} {c+1+voff}" for a, b, c in m.faces]
        voff += len(m.vertices)
    scene.export(os.path.join(OUT, name + ".glb"))
    open(os.path.join(OUT, name + ".obj"), "w").write("\n".join(obj_lines) + "\n")
    return tris

def render(name, parts, color, path, views=((20, -60), (10, -140))):
    allm = trimesh.util.concatenate([trimesh.util.concatenate(v) for v in parts.values()])
    v = allm.vertices; f = allm.faces
    # roblox Y-up -> plot: x, z(depth), y(up)
    vp = v[:, [0, 2, 1]].copy(); vp[:, 1] *= -1
    tri = vp[f]
    n = np.cross(tri[:, 1]-tri[:, 0], tri[:, 2]-tri[:, 0]); n /= (np.linalg.norm(n, axis=1, keepdims=True)+1e-9)
    fig = plt.figure(figsize=(12, 6), facecolor="#0d1020")
    for k, (el, az) in enumerate(views):
        ax = fig.add_subplot(1, 2, k+1, projection="3d"); ax.set_facecolor("#0d1020")
        L = np.array([0.4, -0.5, 0.75]); L /= np.linalg.norm(L)
        sh = np.clip(np.abs(n @ L), 0, 1)*0.75 + 0.25
        if color == "rainbow":
            hue = (tri[:, :, 0].mean(1) - vp[:, 0].min())/(np.ptp(vp[:, 0])+1e-9)
            hue = (hue*0.8 + (tri[:, :, 1].mean(1)-vp[:, 1].min())/(np.ptp(vp[:, 1])+1e-9)*0.5) % 1
            base = hsv_to_rgb(np.stack([hue, np.full_like(hue, 0.65), np.ones_like(hue)], 1))
        else:
            base = np.tile(to_rgb(color), (len(tri), 1))
        cols = np.clip(base*sh[:, None] + 0.12, 0, 1)
        pc = Poly3DCollection(tri, facecolors=cols, edgecolors="none", linewidths=0)
        ax.add_collection3d(pc)
        c = (vp.max(0)+vp.min(0))/2; r = np.ptp(vp, 0).max()/2
        ax.set_xlim(c[0]-r, c[0]+r); ax.set_ylim(c[1]-r, c[1]+r); ax.set_zlim(c[2]-r, c[2]+r)
        ax.set_box_aspect((1, 1, 1)); ax.view_init(el, az); ax.axis("off")
    fig.suptitle(name.split("_", 1)[1], color="white", fontsize=18)
    plt.tight_layout(); fig.savefig(path, dpi=80, facecolor=fig.get_facecolor()); plt.close(fig)

only = sys.argv[3:] or None
items = dict(ALL); items["0_ToriiGate"] = (torii, "#D8352A")
for name, (fn, color) in sorted(items.items()):
    if only and name not in only: continue
    parts = fn()
    t = export(name, parts)
    render(name, parts, color, os.path.join(PREV, name + ".png"))
    print(name, "tris", t, "parts", list(parts))
