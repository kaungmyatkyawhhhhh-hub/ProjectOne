import sys, os, numpy as np, trimesh
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from creatures import ALL
from torii import torii
from textures import textures_for
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
from PIL import Image

OUT = sys.argv[1] if len(sys.argv) > 1 else "out"; PREV = sys.argv[2] if len(sys.argv) > 2 else "prev"

def concat(meshes):
    vs, fs, uvs, off = [], [], [], 0
    for m in meshes:
        vs.append(m.vertices); fs.append(m.faces + off); uvs.append(m.metadata["uv"]); off += len(m.vertices)
    m = trimesh.Trimesh(np.vstack(vs), np.vstack(fs), process=False); m.metadata["uv"] = np.vstack(uvs); return m

def export(name, parts, tex):
    tdir = os.path.join(OUT, name + "_textures"); os.makedirs(tdir, exist_ok=True)
    scene = trimesh.Scene(); obj = [f"mtllib {name}.mtl"]; mtl = []; voff = 0; tris = 0; merged = {}
    for pname, meshes in parts.items():
        m = concat(meshes); merged[pname] = m; tris = max(tris, len(m.faces))
        img = tex.get(pname) or Image.new("RGB", (8, 8), (200, 200, 200))
        img.save(os.path.join(tdir, pname + ".png"))
        mat = trimesh.visual.material.SimpleMaterial(image=img)
        g = trimesh.Trimesh(m.vertices, m.faces, process=False,
                            visual=trimesh.visual.TextureVisuals(uv=m.metadata["uv"], material=mat))
        scene.add_geometry(g, node_name=pname, geom_name=pname)
        obj += [f"o {pname}", f"usemtl {pname}"]
        obj += [f"v {x:.4f} {y:.4f} {z:.4f}" for x, y, z in m.vertices]
        obj += [f"vt {a:.5f} {b:.5f}" for a, b in m.metadata["uv"]]
        obj += [f"f {a+1+voff}/{a+1+voff} {b+1+voff}/{b+1+voff} {c+1+voff}/{c+1+voff}" for a, b, c in m.faces]
        voff += len(m.vertices)
        mtl += [f"newmtl {pname}", "Kd 1 1 1", f"map_Kd {name}_textures/{pname}.png", ""]
    scene.export(os.path.join(OUT, name + ".glb"))
    open(os.path.join(OUT, name + ".obj"), "w").write("\n".join(obj) + "\n")
    open(os.path.join(OUT, name + ".mtl"), "w").write("\n".join(mtl))
    return tris, merged

def render(name, merged, tex, path, views=((20, -60), (10, -140))):
    tris_all, cols_all = [], []
    for pname, m in merged.items():
        img = np.asarray((tex.get(pname) or Image.new("RGB", (8, 8), (200, 200, 200))).convert("RGB"), float)/255
        H, W, _ = img.shape
        uv = m.metadata["uv"][m.faces].mean(1)
        px = np.clip((uv[:, 0]*(W-1)).astype(int), 0, W-1); py = np.clip(((1-uv[:, 1])*(H-1)).astype(int), 0, H-1)
        cols_all.append(img[py, px]); tris_all.append(m.vertices[m.faces])
    tri = np.vstack(tris_all)[:, :, [0, 2, 1]].copy(); tri[:, :, 1] *= -1
    cols = np.vstack(cols_all)
    n = np.cross(tri[:, 1]-tri[:, 0], tri[:, 2]-tri[:, 0]); n /= (np.linalg.norm(n, axis=1, keepdims=True)+1e-9)
    vp = tri.reshape(-1, 3)
    fig = plt.figure(figsize=(12, 6), facecolor="#0d1020")
    for k, (el, az) in enumerate(views):
        ax = fig.add_subplot(1, 2, k+1, projection="3d"); ax.set_facecolor("#0d1020")
        L = np.array([0.4, -0.5, 0.75]); L /= np.linalg.norm(L)
        sh = np.clip(np.abs(n @ L), 0, 1)*0.6 + 0.45
        pc = Poly3DCollection(tri, facecolors=np.clip(cols*sh[:, None], 0, 1), edgecolors="none", linewidths=0)
        ax.add_collection3d(pc)
        c = (vp.max(0)+vp.min(0))/2; r = np.ptp(vp, 0).max()/2
        ax.set_xlim(c[0]-r, c[0]+r); ax.set_ylim(c[1]-r, c[1]+r); ax.set_zlim(c[2]-r, c[2]+r)
        ax.set_box_aspect((1, 1, 1)); ax.view_init(el, az); ax.axis("off")
    fig.suptitle(name.split("_", 1)[-1], color="white", fontsize=18)
    plt.tight_layout(); fig.savefig(path, dpi=80, facecolor=fig.get_facecolor()); plt.close(fig)

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True); os.makedirs(PREV, exist_ok=True)
    only = sys.argv[3:] or None
    items = dict(ALL); items["0_ToriiGate"] = (torii, None)
    for name, (fn, _) in sorted(items.items()):
        if only and name not in only: continue
        parts = fn(); tex = textures_for(name)
        missing = [p for p in parts if p not in tex]
        t, merged = export(name, parts, tex)
        render(name, merged, tex, os.path.join(PREV, name + ".png"))
        print(name, "max tris/part", t, "missing tex", missing)
