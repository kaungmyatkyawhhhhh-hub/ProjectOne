"""MEGA BITE map simulation (9 Nov 2026, design stage: no build yet).
Two kid models swim the PLANNED map:
  1. Impatient kid (the owner's method): boredom meter, quits when it passes his patience.
  2. Quality-nerd kid (new): looks at every view for 'cheap / AI-slop' tells vs 'wow' detail,
     then likes, dislikes or doesn't vote.
Map numbers come from the research notes (Map and world, Core design). It's a model for
comparing map designs, not real players: check the real funnel after a test build.
Run: python mapsim.py
"""
import math, random, statistics as st

SPEED = 20.0          # studs/s, small fish (Roblox default swim ~16, research suggests 16-24)
DT = 0.5

# ---------------------------------------------------------------- map versions (cumulative)
BASE = dict(
    name="A  DEVOUR-like: big map, sparse food, 1 bank, few landmarks",
    reef_radius=250, reef_spacing=40, open_spacing=90,   # studs between food fish
    landmark_every=600,        # studs of swimming between landmarks / set pieces
    bank_spacing=None,         # None = only the reef centre banks
    predator_per_s=1/60,       # NPC predator catches a careless small fish (Open Sea)
    ambient_life=False,        # fish schools that scatter, kelp sway, bubbles
    kit_size=5,                # unique meshes in the set-dressing kit
    zone_identity=False,       # each zone has its own colour / light / sound
    natural_borders=False,     # rock walls + currents instead of invisible walls
    streaming_tuned=False,     # landmarks as persistent models, low-detail stand-ins far away
    guide=False,               # arrow / glowing current to the next goal
    newbie_safe=False,         # nothing carried is lost while below Reef Shark
    telegraph=False,           # predators glow red before they strike; DART dodges
    first_bag=None,            # smaller bag on the first Open Sea trip
    frenzy=False,              # FRENZY ability unlocked on the Piranha evolve
    shiny_per_min=0.0,         # golden fish spawns near you per minute (server alert)
    evo2=None,                 # EXP for Barracuda
    home_food=False,           # fish to eat along the way to a bank vent
    bait_every=None,           # seconds between sardine bait balls near you (Open Sea)
    evo_list=None,             # EXP to each evolve (overrides EVO)
    quest_every=None,          # a small quest completes about every N s ("eat 5 tunas", "bank 30")
    index_pages=False,         # every 3 new species = a Fish Index page pop
    chase_escape=False,        # below Barracuda, predators chase; 70% escape with an ESCAPED! pop
    bank_juice=1.0,            # size of the BANK moment (count-up + evolve bar jump)
    growth_stages=False,       # each shark grows Baby -> Teen -> Adult between evolves (visible)
)
V = [BASE]
def add(name, **kw):
    v = dict(V[-1]); v.update(kw); v["name"] = name; V.append(v)
add("B  + compact map (~2,000 studs), food 2x denser on the route", reef_radius=200, reef_spacing=22, open_spacing=45)
add("C  + a landmark / set piece every ~15 s of swimming + guide current", landmark_every=300, guide=True)
add("D  + bank vents every ~30 s of swimming", bank_spacing=600)
add("E  + ambient life (schools scatter, kelp, bubbles) + 14-mesh kit", ambient_life=True, kit_size=14)
add("F  + zone identity, natural borders, streaming tuned", zone_identity=True, natural_borders=True, streaming_tuned=True)
add("G  + new players drop nothing below Reef Shark (keep 25% after)", newbie_safe=True)
add("H  + red outline warns of predators, DART dodges them", telegraph=True)
add("I  + a food current along the routes to the vents (eat on the way)", home_food=True)
add("J  + a BAIT BALL event every ~60 s in the Open Sea (8 quick bites)", bait_every=60)
add("K  + FRENZY unlocks at Piranha + shiny fish (~1 a minute)", frenzy=True, shiny_per_min=1.0)

EVO = [25, 90, 260]                 # bites (EXP) to Piranha, Barracuda, Reef Shark (first ~15 min)
BAG = 30                            # carried EXP before the kid wants to bank (Open Sea x2 food)

# ---------------------------------------------------------------- 1. impatient kid
def impatient(v, rng, patience, T=300):
    EV = list(v["evo_list"] or EVO)
    if v["evo2"]: EV[1] = v["evo2"]
    banks = 0
    stage_done = set()
    t = 0.0; boredom = 0.0; exp = 0; tier = 0; carried = 0; seen = {}
    zone = "reef"; travelled = 0.0; next_landmark = v["landmark_every"] * rng.uniform(0.3, 1.0)
    next_food = rng.expovariate(1.0) * v["reef_spacing"] / SPEED + rng.uniform(0.6, 2.2)
    heading_home = False; home_dist = 0.0; fish_types_seen = 1
    def reward(kind, base):
        n = seen.get(kind, 0); seen[kind] = n + 1
        wear = 0.015 if kind == "bite" else 0.05
        return base / (1 + wear * n) / (1 + 0.002 * sum(seen.values()))
    timeline = []
    while t < T:
        t += DT
        # travel, food, landmarks
        if heading_home:
            home_dist -= SPEED * DT; travelled += SPEED * DT
            if home_dist <= 0:
                heading_home = False
                banks += 1
                exp += carried; boredom -= reward("bank", 9 * v["bank_juice"]); timeline.append((t, f"BANKED +{carried}")); carried = 0
                for i, need in enumerate(EV):
                    if tier == i and exp >= need:
                        tier += 1; boredom -= reward("evolve", 28); timeline.append((t, f"EVOLVE {tier}"))
            rate = 1.4 if home_dist / SPEED > 30 else 1.0
            if v["home_food"]:
                next_food -= DT; rate = 0.5 if next_food < 3 else rate
                if next_food <= 0:
                    carried += 2; boredom -= reward("bite", 3.2)
                    next_food = rng.expovariate(1.0) * v["open_spacing"] / SPEED + rng.uniform(0.6, 2.2)
        else:
            spacing = v["reef_spacing"] if zone == "reef" else v["open_spacing"]
            next_food -= DT; travelled += SPEED * DT * 0.6
            rate = 0.5 if next_food < 3 else (1.4 if next_food > 30 else 1.0)
            if zone == "open" and carried >= BAG - 6: rate *= 0.7          # bag almost full
            if tier < len(EV) and exp + carried >= EV[tier] - 6: rate *= 0.7  # evolve bar almost full
            if next_food <= 0:
                gain = 1 if zone == "reef" else 2
                if zone == "reef":
                    exp += gain
                    for i, need in enumerate(EV):
                        if tier == i and exp >= need:
                            tier += 1; boredom -= reward("evolve", 28); timeline.append((t, f"EVOLVE {tier}"))
                            if tier == 1 and v["frenzy"]:
                                boredom -= reward("ability", 14); timeline.append((t, "FRENZY unlocked"))
                else:
                    carried += gain
                boredom -= reward("bite", 3.2)
                bites = seen.get("bite", 0)
                if bites % 8 == 0: boredom -= reward("sizeup", 5)   # SIZE number jumps, fish grows
                if rng.random() < (0.10 if zone == "reef" else 0.18) and fish_types_seen < 18:
                    fish_types_seen += 1; boredom -= reward("newfish", 6)
                    if v["index_pages"] and fish_types_seen % 3 == 0:
                        boredom -= reward("indexpage", 9); timeline.append((t, "INDEX PAGE"))
                next_food = rng.expovariate(1.0) * spacing / SPEED + rng.uniform(0.6, 2.2)
            # after the first evolve the guide points to the Open Sea
            if zone == "reef" and tier >= 1:
                gap = (v["reef_radius"] * 0.6) / SPEED
                if not v["guide"]: gap *= rng.uniform(1.3, 2.2)   # kid wanders looking for it
                t += gap; travelled += gap * SPEED
                boredom += gap * (1.0 if gap < 30 else 1.4) * (0.85 if v["ambient_life"] else 1)
                if boredom > patience: return False, t, timeline
                zone = "open"; boredom -= reward("newzone", 14); timeline.append((t, "OPEN SEA"))
                next_food = rng.expovariate(1.0) * v["open_spacing"] / SPEED + 1
            if zone == "open":
                if v["chase_escape"] and tier < 2 and rng.random() < v["predator_per_s"] * DT * 0.7:
                    boredom -= reward("escape", 7); timeline.append((t, "ESCAPED!"))
                elif rng.random() < v["predator_per_s"] * DT * (0.3 if (v["chase_escape"] and tier < 2) else 1) and not (v["telegraph"] and rng.random() < 0.6):
                    if v["newbie_safe"]: lost = 0 if tier < 3 else int(carried * 0.75)
                    else: lost = carried
                    carried -= lost; boredom += 3 + lost * 0.2
                    t += 3   # respawn / swim back a bit
                    timeline.append((t, f"EATEN, lost {lost}"))
                bag = v["first_bag"] if (v["first_bag"] and banks == 0) else BAG
                if v["frenzy"] and tier >= 1 and rng.random() < DT / 20:   # FRENZY ready ~every 20 s
                    carried += 4; boredom -= reward("frenzy", 5)
                if carried >= bag:
                    if v["bank_spacing"]:
                        home_dist = rng.uniform(0.2, 0.5) * v["bank_spacing"]
                    else:
                        home_dist = v["reef_radius"] * 0.5 + rng.uniform(150, 450)
                    heading_home = True
        if v["growth_stages"] and tier < len(EV):
            lo = EV[tier - 1] if tier > 0 else 0; gap = EV[tier] - lo
            for frac in (1/3, 2/3):
                if (tier, frac) not in stage_done and exp + carried >= lo + gap * frac:
                    stage_done.add((tier, frac)); boredom -= reward("stage", 12); timeline.append((t, "GROWTH STAGE"))
        if v["quest_every"] and tier >= 1 and rng.random() < DT / v["quest_every"]:
            boredom -= reward("quest", 9); carried += 3; timeline.append((t, "QUEST"))
        if v["bait_every"] and zone == "open" and rng.random() < DT / v["bait_every"]:
            carried += 8; boredom -= reward("baitball", 10); timeline.append((t, "BAIT BALL"))
        if v["shiny_per_min"] and rng.random() < v["shiny_per_min"] * DT / 60:
            boredom -= reward("shiny", 12); carried += 6 if zone == "open" else 0; timeline.append((t, "SHINY"))
        if travelled >= next_landmark:
            boredom -= reward("landmark", 11); timeline.append((t, "LANDMARK"))
            next_landmark += v["landmark_every"] * rng.uniform(0.7, 1.3)
        if v["ambient_life"]: rate *= 0.85
        boredom = max(0.0, boredom + rate * DT)
        if boredom > patience: return False, t, timeline
    return True, T, timeline

def run_impatient(v, n=2000, med=11, seed=1):
    rng = random.Random(seed); quits = []; first_evo = []; long_dead = []
    for _ in range(n):
        pat = med * math.exp(rng.gauss(0, 0.35))
        stayed, t, tl = impatient(v, rng, pat)
        quits.append(T_ if (T_ := (300 if stayed else t)) else t)
        evo = [x for x, e in tl if e.startswith("EVOLVE 1")]
        if evo: first_evo.append(evo[0])
    def stay(s): return 100 * sum(q >= s for q in quits) / n
    return dict(s30=stay(30), s60=stay(60), s120=stay(120), s300=stay(300),
                evo1=st.median(first_evo) if first_evo else float("nan"))

# ---------------------------------------------------------------- 2. quality-nerd kid
def nerd(v, rng, T=600):
    """Looks at a view every 2 s for 10 min. Counts 'cheap' tells and 'wow' moments."""
    tells = {}; wows = 0; t = 0; since_detail = 0; since_landmark_studs = 0
    recent_props = []
    def tell(k): tells[k] = tells.get(k, 0) + 1
    zone_changes = 0
    while t < T:
        t += 2; since_landmark_studs += SPEED * 2
        # what is in view
        near_landmark = since_landmark_studs < 120
        if since_landmark_studs >= v["landmark_every"] * rng.uniform(0.7, 1.3):
            since_landmark_studs = 0; wows += 1                     # a hand-made set piece
            if not v["streaming_tuned"] and rng.random() < 0.45: tell("pop-in")
        props_in_view = rng.randint(3, 8) if near_landmark else rng.randint(0, 3 if v["kit_size"] < 10 else 5)
        if v["ambient_life"]: props_in_view += 2
        if props_in_view == 0: since_detail += 2
        else: since_detail = 0
        if since_detail >= 6: tell("empty view"); since_detail = 0
        for _ in range(props_in_view):
            recent_props.append(rng.randrange(v["kit_size"]))
        recent_props = recent_props[-40:]
        if recent_props:
            most = max(recent_props.count(p) for p in set(recent_props))
            if most >= 9 and rng.random() < 0.25: tell("same prop again")
        if not v["ambient_life"] and rng.random() < 0.05: tell("fish don't react")
        if rng.random() < 1/90:                                     # crosses into a new zone
            zone_changes += 1
            if v["zone_identity"]: wows += 1
            else: tell("zones look the same")
        if not v["natural_borders"] and rng.random() < 1/150: tell("invisible wall")
    W = {"same prop again": 1.0, "fish don't react": 1.2, "pop-in": 0.9, "empty view": 1.0,
         "zones look the same": 1.1, "invisible wall": 1.4}
    score = 1.6 * math.log1p(wows) - sum(W[k] * math.log1p(c) for k, c in tells.items())
    p_like = 1 / (1 + math.exp(-(score - 1.0) / 1.2))
    p_dislike = 1 / (1 + math.exp((score + 1.0) / 1.2))
    vote = rng.random()
    verdict = "like" if vote < p_like * 0.35 else ("dislike" if vote > 1 - p_dislike * 0.35 else "none")
    return verdict, tells, wows

def run_nerd(v, n=2000, seed=2):
    rng = random.Random(seed); likes = dislikes = 0; agg = {}; w = 0
    for _ in range(n):
        verdict, tells, wows = nerd(v, rng); w += wows
        likes += verdict == "like"; dislikes += verdict == "dislike"
        for k, c in tells.items(): agg[k] = agg.get(k, 0) + c
    voters = likes + dislikes
    top = sorted(agg.items(), key=lambda kv: -kv[1])[:3]
    return dict(ratio=100 * likes / voters if voters else float("nan"),
                tells=sum(agg.values()) / n, wows=w / n,
                top=", ".join(f"{k} {c/n:.1f}" for k, c in top))

if __name__ == "__main__":
    print("IMPATIENT KID (2,000 kids, patience median 11 s)")
    print(f"{'version':66} 30s   60s  2min  5min  1st evolve")
    for v in V:
        r = run_impatient(v)
        print(f"{v['name']:66} {r['s30']:4.0f}% {r['s60']:4.0f}% {r['s120']:4.0f}% {r['s300']:4.0f}%  {r['evo1']:5.0f} s")
    for med in (7, 16):
        a, f = run_impatient(V[0], med=med), run_impatient(V[-1], med=med)
        print(f"  sensitivity patience {med:2d} s: A stay 5 min {a['s300']:.0f}%  ->  last {f['s300']:.0f}%")
    print("\nQUALITY-NERD KID (2,000 kids, 10 min swim, like ratio among voters)")
    print(f"{'version':66} likes  tells/10min wows/10min  top tells")
    for v in V:
        r = run_nerd(v)
        print(f"{v['name']:66} {r['ratio']:4.0f}%  {r['tells']:5.1f}      {r['wows']:5.1f}     {r['top']}")
