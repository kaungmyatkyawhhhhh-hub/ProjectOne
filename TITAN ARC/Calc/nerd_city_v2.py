"""Quality-nerd kid on the LIVE city v2 build (13 Nov 2026, after the landmarks pass). Same kid as nerdkid.py."""
import nerdkid as N
base = dict(N.BASE)
V = []
def ver(name, **kw):
    v = dict(V[-1] if V else base); v.update(kw); v["name"] = name; V.append(v)
ver("L1 live 13 Nov 02:00: grid city, 4 landmarks (~450 studs apart), walls behind hills",
    kinds=6, variants=3, decor=12, landmark_every=450, ambient=True, crumbles=5, rebuild_anim=True,
    zone_identity=False, natural_borders=False, streaming_tuned=False, forms_10min=8, form_kits=True)
ver("L2 city v2 step 1: hill ring + sea edge (no visible end)", natural_borders=True)
ver("L3 + 8 landmarks (one per district) + 4 old set pieces (~270 studs apart)", landmark_every=270)
ver("L4 + landmarks persistent + streaming mesh LOD (no pop-in)", streaming_tuned=True)
ver("L5 + 6 district prop kinds (containers, tanks, warehouses, glass/neon towers, palaces)", kinds=9)
ver("L6 (next) + per-district light + music change", zone_identity=True)
print("QUALITY-NERD KID on the LIVE city v2 (2,000 kids, 10-minute walk; trust tells per 10 min)")
print(f"{'version':86} likes  tells/10min  wows/10min  worst kind  top tells")
for v in V:
    r = N.run(v)
    print(f"{v['name']:86} {r['ratio']:4.0f}%   {r['tells']:5.1f}       {r['wows']:5.1f}      {r['worst']:4.1f}     {r['top']}")
