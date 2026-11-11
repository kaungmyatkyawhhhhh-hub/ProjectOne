"""STOMP EVOLUTION quality-nerd kid simulation (owner's method), 11 Nov 2026.
DESIGN STAGE: no build exists, so 'what the player sees' comes from the design doc v0. Where the doc is
silent (set pieces, moving things, borders, streaming) version A assumes the cheap default, because
that is what gets built when nothing is specified.
The kid walks the streets and looks at a view every 2 s for 10 minutes. He counts cheap TELLS and WOWS.
Score = 1.6 x log(1 + wows) - sum(weight x log(1 + count)) per tell kind. 2,000 kids per version.
Added for this game (not in the MEGA BITE model): 'same crumble every time' and 'buildings pop back'.
Run: python nerdkid.py
"""
import math, random

SPEED = 16.0   # studs/s walking
BASE = dict(
    name="A  the plan v0: 6 prop kinds per district, one crumble, props pop back",
    kinds=6, variants=1, decor=0,      # breakable kinds in view, look-alike variants of each, non-breakable dressing meshes
    landmark_every=600,                # studs of walking between hand-made set pieces
    ambient=False,                     # things that move and react (toy cars, birds, lights, alarms)
    crumbles=1,                        # different ways things break
    rebuild_anim=False,                # rubble stays, then a visible rebuild (scaffold, bricks stacking)
    zone_identity=False, natural_borders=False, streaming_tuned=False,
    forms_10min=3,                     # evolves the kid goes through in 10 min (each is a hand-made look)
    form_kits=False,                   # each form has its own kit + cutscene (else: just bigger)
)
V = [BASE]
def add(name, **kw):
    v = dict(V[-1]); v.update(kw); v["name"] = name; V.append(v)
add("B  + 3 look-alike variants of every breakable prop (colours, roofs)", variants=3)
add("C  + a 12-mesh dressing kit (lamps, benches, trees, signs, fences)", decor=12)
add("D  + a hand-made set piece every ~250 studs that breaks in 3 stages", landmark_every=250)
add("E  + moving life: toy cars swerve, birds scatter, lights blink, alarms", ambient=True)
add("F  + 5 crumbles by material, rubble stays, a visible rebuild", crumbles=5, rebuild_anim=True)
add("G  + district identity (palette, light, music), natural borders, streaming tuned", zone_identity=True, natural_borders=True, streaming_tuned=True)
add("H  + evolution-first: 8 forms in 10 min, each with its own kit + cutscene", forms_10min=8, form_kits=True)

W = {"same prop again": 1.0, "nothing reacts": 1.2, "pop-in": 0.9, "empty view": 1.0, "districts look the same": 1.1,
     "invisible wall": 1.4, "same crumble every time": 1.0, "buildings pop back": 0.9, "new form is just bigger": 1.1}

def nerd(v, rng, T=600):
    tells = {}; wows = 0; t = 0; since_detail = 0; since_lm = 0.0; recent = []
    def tell(k): tells[k] = tells.get(k, 0) + 1
    kit = v["kinds"] * v["variants"] + v["decor"]
    form_times = sorted(rng.uniform(20, T) for _ in range(v["forms_10min"])); fi = 0
    while t < T:
        t += 2; since_lm += SPEED * 2 * 0.6
        near_lm = since_lm < 120
        if since_lm >= v["landmark_every"] * rng.uniform(0.7, 1.3):
            since_lm = 0; wows += 1
            if not v["streaming_tuned"] and rng.random() < 0.45: tell("pop-in")
        # a flattened street: nothing left to look at until it comes back
        flattened = rng.random() < (0.03 if v["rebuild_anim"] else 0.14)
        props = 0 if flattened else (rng.randint(4, 9) if near_lm else rng.randint(2, 6))
        if v["ambient"]: props += 2
        since_detail = since_detail + 2 if props == 0 else 0
        if since_detail >= 6: tell("empty view"); since_detail = 0
        for _ in range(props): recent.append(rng.randrange(max(1, kit)))
        recent = recent[-40:]
        if recent and max(recent.count(p) for p in set(recent)) >= 9 and rng.random() < 0.25: tell("same prop again")
        if not v["ambient"] and rng.random() < 0.05: tell("nothing reacts")
        if v["crumbles"] < 3 and rng.random() < 0.05: tell("same crumble every time")
        if not v["rebuild_anim"] and rng.random() < 0.03: tell("buildings pop back")
        if rng.random() < 1 / 150:
            if v["zone_identity"]: wows += 1
            else: tell("districts look the same")
        if not v["natural_borders"] and rng.random() < 1 / 150: tell("invisible wall")
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
                top=", ".join(f"{k} {c/n:.1f}" for k, c in top[:3]), worst=(top[0][1] / n if top else 0))

if __name__ == "__main__":
    print("QUALITY-NERD KID on the PLAN (2,000 kids, a 10-minute walk; trust tells per 10 min, not the like %)")
    print(f"{'version':78} likes  tells/10min  wows/10min  worst kind  top tells")
    for v in V:
        r = run(v)
        print(f"{v['name']:78} {r['ratio']:4.0f}%   {r['tells']:5.1f}       {r['wows']:5.1f}      {r['worst']:4.1f}     {r['top']}")
