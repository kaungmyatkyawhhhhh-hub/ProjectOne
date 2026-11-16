"""fig_preview.py: turns a buddha_figures_blender.py json into preview_blend.py input and renders it.
    python fig_preview.py <fig.json> <outdir> <views json string>"""
import json
import os
import subprocess
import sys

COL = {"FSK": (250, 250, 246), "FGO": (205, 165, 90), "FGB": (225, 180, 70), "FMR": (110, 30, 36), "FBK": (20, 20, 24),
       "FLD": (160, 200, 225), "FLP": (200, 50, 60), "FPK": (230, 140, 140), "FSO": (214, 128, 112), "FEW": (248, 248, 248), "FSH": (214, 212, 206), "FS2": (190, 186, 180)}
fig, out, views = sys.argv[1], os.path.abspath(sys.argv[2]), json.loads(sys.argv[3])
d = json.load(open(fig))["groups"]
data = {"look": {g: COL.get(g, (200, 200, 200)) for g in d}, "tris": {g: [t[0] for t in v] for g, v in d.items()}}
os.makedirs(out, exist_ok=True)
tj = os.path.join(out, "_tris.json")
vj = os.path.join(out, "_views.json")
json.dump(data, open(tj, "w"))
json.dump(views, open(vj, "w"))
here = os.path.dirname(os.path.abspath(__file__))
r = subprocess.run([r"C:\Program Files\Blender Foundation\Blender 3.6\blender.exe", "-b", "--factory-startup", "--python",
                    os.path.join(here, "preview_blend.py"), "--", tj, out, vj], capture_output=True, text=True)
print("ok" if "PREVIEW_DONE" in r.stdout else r.stdout[-2000:] + r.stderr[-2000:])
