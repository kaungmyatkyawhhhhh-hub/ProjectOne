# collide/Collide05_k.txt -> RColRB_<tag>_k.luau (return [==[...]==]) in roads05_RB12/collide_mods/<tag>, then pack_tools
import glob, os, re, subprocess, sys
tag = sys.argv[1]
D = r"D:/ObsidianOne/Claude+Obsidian/Games/CityLegends/build/city_1to1/roads05_RB12"
out = os.path.join(D, 'collide_mods', tag)
os.makedirs(out, exist_ok=True)
for f in glob.glob(os.path.join(out, '*.luau')):
    os.remove(f)
files = sorted(glob.glob(os.path.join(D, 'collide', 'Collide05_*.txt')), key=lambda p: int(re.findall(r'\d+', os.path.basename(p))[-1]))
mods = []
for i, p in enumerate(files):
    t = open(p).read()
    assert ']==]' not in t
    m = os.path.join(out, 'RColRB_%s_%d.luau' % (tag, i + 1))
    open(m, 'w', newline='\n').write('return [==[' + t + ']==]')
    mods.append(m)
G = r"D:/ObsidianOne/Claude+Obsidian/Games/CityLegends"
subprocess.run([sys.executable, os.path.join(G, 'tools/yangon/pack_tools.py'), os.path.join(G, 'imports/sync/rebuild_%s_collide.rbxmx' % tag)] + mods, check=True)
