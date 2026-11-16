"""glb_split.py in.glb n (up to batch 3): writes in_s1.glb .. in_s<n>.glb, the meshes dealt out in name order (glb_subset),
so each stays under the ~10 MB an Open Cloud upload takes without timing out."""
import os, subprocess, sys, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from glb_subset import read

src, n = sys.argv[1], int(sys.argv[2])
js, _ = read(src)
names = [nd['name'] for nd in js['nodes'] if 'mesh' in nd]
k = -(-len(names) // n)
for i in range(n):
    part = names[i * k:(i + 1) * k]
    if not part:
        continue
    lst = os.path.join(tempfile.gettempdir(), 'glb_split_%d.txt' % i)
    open(lst, 'w').write('\n'.join(part))
    subprocess.run([sys.executable, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'glb_subset.py'),
                    src.replace('.glb', '_s%d.glb' % (i + 1)), lst, src], check=True)
