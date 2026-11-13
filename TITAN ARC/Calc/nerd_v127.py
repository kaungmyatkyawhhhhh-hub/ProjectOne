"""Quality-nerd kid on LIVE v127 (13 Nov 11:55). Same kid as nerdkid.py, plus what the last model MISSED and what is new:
 * HONEST MISS: the 13 Nov model said 0 tells while the owner saw an empty Starter Park ("this area look so bad").
   The old model used one prop density for the whole city. Now the walk is split by zone: the kid spends the first
   ~2 minutes in the spawn park (it's where he starts), so a sparse park = 'empty field' tells right at the start.
 * new tells: plain default heads on NPC giants, a terrain grass patch that doesn't match, see-through area walls
   (only when he walks into one before he can open it).
 * new wows: wild titans walking past, the Rogue Alert drop, the pond + flower garden set pieces, the Sumo arena.
Run: python nerd_v127.py"""
import math, random
import nerdkid as N
W = dict(N.W); W.update({"empty field": 1.2, "plain NPC heads": 0.8, "grass patch": 0.5, "wall in the way": 0.6})

def nerd(v, rng, T=600):
    tells = {}; wows = 0; t = 0; since_detail = 0; since_lm = 0.0; recent = []
    def tell(k): tells[k] = tells.get(k, 0) + 1
    kit = v["kinds"] * v["variants"] + v["decor"]
    form_times = sorted(rng.uniform(20, T) for _ in range(v["forms_10min"])); fi = 0
    park_until = rng.uniform(90, 150)                   # the spawn park is the first stretch of every session
    rogue_at = rng.uniform(200, 260) if v.get("rogue") else None
    while t < T:
        t += 2; since_lm += N.SPEED * 2 * 0.6
        in_park = t < park_until
        lm_every = v["park_lm_every"] if in_park else v["landmark_every"]
        near_lm = since_lm < 120
        if since_lm >= lm_every * rng.uniform(0.7, 1.3):
            since_lm = 0; wows += 1
            if not v["streaming_tuned"] and rng.random() < 0.45: tell("pop-in")
        flattened = rng.random() < (0.03 if v["rebuild_anim"] else 0.14)
        if in_park: props = rng.randint(*v["park_props"])
        else: props = 0 if flattened else (rng.randint(4, 9) if near_lm else rng.randint(2, 6))
        if v["ambient"]: props += 2
        if in_park and props <= 2 and rng.random() < 0.35: tell("empty field")
        since_detail = since_detail + 2 if props == 0 else 0
        if since_detail >= 6: tell("empty view"); since_detail = 0
        for _ in range(props): recent.append(rng.randrange(max(1, kit)))
        recent = recent[-40:]
        if recent and max(recent.count(p) for p in set(recent)) >= 9 and rng.random() < 0.25: tell("same prop again")
        if not v["ambient"] and rng.random() < 0.05: tell("nothing reacts")
        if rng.random() < 1 / 150:
            if v["zone_identity"]: wows += 1
            else: tell("districts look the same")
        if not v["natural_borders"] and rng.random() < 1 / 150: tell("invisible wall")
        if v.get("wild") and rng.random() < 1 / 60:          # a wild titan walks past
            wows += 0.5
            if v.get("npc_plain_heads") and rng.random() < 0.3: tell("plain NPC heads")
        if v.get("grass_patch") and in_park and rng.random() < 1 / 120: tell("grass patch")
        if v.get("area_walls") and rng.random() < 1 / 200: tell("wall in the way")
        if rogue_at and t >= rogue_at: rogue_at = None; wows += 2
        while fi < len(form_times) and t >= form_times[fi]:
            fi += 1
            if v["form_kits"]: wows += 1
            elif rng.random() < 0.5: tell("new form is just bigger")
    score = 1.6 * math.log1p(wows) - sum(W[k] * math.log1p(c) for k, c in tells.items())
    p_like = 1 / (1 + math.exp(-(score - 1.0) / 1.2)); p_dis = 1 / (1 + math.exp((score + 1.0) / 1.2))
    x = rng.random()
    return ("like" if x < p_like * 0.35 else ("dislike" if x > 1 - p_dis * 0.35 else "none")), tells, wows

def run(v, n=2000, seed=2):
    rng = random.Random(seed); likes = dis = 0; agg = {}; w = 0
    for _ in range(n):
        verdict, tells, wows = nerd(v, rng); w += wows
        likes += verdict == "like"; dis += verdict == "dislike"
        for k, c in tells.items(): agg[k] = agg.get(k, 0) + c
    top = sorted(agg.items(), key=lambda kv: -kv[1])
    return dict(ratio=100 * likes / (likes + dis) if likes + dis else float("nan"), tells=sum(agg.values()) / n, wows=w / n,
                top=", ".join(f"{k} {c/n:.1f}" for k, c in top[:3]) or "none", worst=(top[0][1] / n if top else 0))

base = dict(N.BASE, kinds=9, variants=3, decor=12, landmark_every=270, ambient=True, crumbles=5, rebuild_anim=True,
            zone_identity=True, natural_borders=True, streaming_tuned=True, forms_10min=8, form_kits=True)
V = []
def ver(name, **kw):
    v = dict(V[-1] if V else base); v.update(kw); v["name"] = name; V.append(v)
ver("P0 v120 (before the park redo): sparse spawn park, playground the only set piece there", park_props=(0, 3), park_lm_every=600)
ver("P1 v124 park v3: plaza, paths, pond, garden, 545 trees, 73 props", park_props=(4, 9), park_lm_every=160)
ver("P2 LIVE v127: + wild titans (plain heads), Rogue Alert, area walls, pond grass patch",
    wild=True, npc_plain_heads=True, rogue=True, area_walls=True, grass_patch=True)
ver("P3 + NPC giants get a face + hair look (helmet from their armour set)", npc_plain_heads=False)
ver("P4 + pond terrain recoloured / blended to the slab green", grass_patch=False)
if __name__ == "__main__":
    print("QUALITY-NERD KID on LIVE v127 (2,000 kids, 10-minute walk starting in the spawn park; trust tells per 10 min)")
    print(f"{'version':92} likes  tells/10min  wows/10min  top tells")
    for v in V:
        r = run(v)
        print(f"{v['name']:92} {r['ratio']:4.0f}%   {r['tells']:5.1f}       {r['wows']:5.1f}      {r['top']}")
