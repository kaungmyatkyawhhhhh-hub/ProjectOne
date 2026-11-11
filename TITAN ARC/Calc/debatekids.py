"""STOMP EVOLUTION debate-kids simulation (owner's method), 11 Nov 2026.
Groups of 3-5 kids argue over which Roblox game to play together. Each kid has weights (what he argues
for) and deal-breakers (a veto). Friends only play a game NOBODY vetoes; among those, the best total.
Rivals = the top live games on 11 Nov 2026 (Roblox 'Top Playing Now') + the closest games in our genre.
Scores 0-10 are ESTIMATES from public numbers (players, likes, age, page text). A model of arguments.
Run: python debatekids.py
"""
import random, statistics as st

A = ["first_min", "depth", "social", "pvp_thrill", "pvp_safe", "fair_money", "looks", "cute_funny", "scary",
     "crowd", "updates", "phone", "easy", "novelty", "collect", "show_off", "giant", "original"]
def g(**kw):
    d = {a: 5 for a in A}; d.update(kw); return d

RIVALS = {  # playing now on 11 Nov 2026 in brackets
    "Steal An Egg (613K)":          g(first_min=8, depth=5, social=7, pvp_thrill=7, pvp_safe=5, fair_money=5, looks=6, cute_funny=8, scary=1, crowd=10, updates=8, phone=7, easy=9, novelty=6, collect=8, show_off=7, giant=0, original=5),
    "Murder Mystery 2 (603K)":      g(first_min=8, depth=4, social=8, pvp_thrill=8, pvp_safe=6, fair_money=6, looks=5, cute_funny=4, scary=4, crowd=10, updates=5, phone=8, easy=9, novelty=2, collect=8, show_off=8, giant=0, original=8),
    "Brookhaven RP (349K)":         g(first_min=8, depth=4, social=10, pvp_thrill=1, pvp_safe=9, fair_money=6, looks=6, cute_funny=7, scary=1, crowd=10, updates=6, phone=8, easy=10, novelty=2, collect=4, show_off=8, giant=0, original=8),
    "Blox Fruits (267K)":           g(first_min=5, depth=10, social=8, pvp_thrill=8, pvp_safe=6, fair_money=5, looks=6, cute_funny=3, scary=2, crowd=10, updates=7, phone=6, easy=5, novelty=3, collect=9, show_off=9, giant=2, original=7),
    "Throw Food For Animals (184K)": g(first_min=9, depth=4, social=6, pvp_thrill=1, pvp_safe=10, fair_money=7, looks=6, cute_funny=9, scary=0, crowd=10, updates=7, phone=8, easy=10, novelty=8, collect=7, show_off=5, giant=1, original=8),
    "Steal a Brainrot (114K)":      g(first_min=8, depth=5, social=7, pvp_thrill=7, pvp_safe=5, fair_money=5, looks=5, cute_funny=9, scary=1, crowd=9, updates=8, phone=7, easy=9, novelty=5, collect=8, show_off=7, giant=0, original=6),
    "99 Nights (103K)":             g(first_min=7, depth=6, social=10, pvp_thrill=0, pvp_safe=9, fair_money=7, looks=7, cute_funny=4, scary=7, crowd=9, updates=7, phone=6, easy=7, novelty=6, collect=5, show_off=5, giant=0, original=8),
    "+1 Venom Evolution (24K)":     g(first_min=9, depth=6, social=5, pvp_thrill=3, pvp_safe=9, fair_money=6, looks=6, cute_funny=5, scary=3, crowd=7, updates=8, phone=8, easy=10, novelty=5, collect=7, show_off=8, giant=6, original=5),
    "Depth Incremental (21K)":      g(first_min=8, depth=9, social=4, pvp_thrill=0, pvp_safe=10, fair_money=6, looks=7, cute_funny=4, scary=3, crowd=7, updates=9, phone=8, easy=8, novelty=7, collect=9, show_off=6, giant=0, original=7),
    "Bug Evolution (14K)":          g(first_min=8, depth=6, social=5, pvp_thrill=4, pvp_safe=8, fair_money=5, looks=5, cute_funny=6, scary=3, crowd=7, updates=7, phone=7, easy=9, novelty=6, collect=7, show_off=7, giant=3, original=6),
    "Muscle Legends (2.5K)":        g(first_min=7, depth=8, social=6, pvp_thrill=7, pvp_safe=5, fair_money=4, looks=5, cute_funny=4, scary=1, crowd=4, updates=6, phone=8, easy=9, novelty=1, collect=8, show_off=9, giant=8, original=8),
    "Grow And Build Giants (2.5K)": g(first_min=8, depth=5, social=5, pvp_thrill=6, pvp_safe=6, fair_money=6, looks=6, cute_funny=7, scary=2, crowd=4, updates=8, phone=7, easy=8, novelty=7, collect=8, show_off=7, giant=9, original=7),
    "+1 Titan Evolution (1.7K)":    g(first_min=9, depth=6, social=5, pvp_thrill=3, pvp_safe=9, fair_money=5, looks=6, cute_funny=4, scary=3, crowd=4, updates=8, phone=8, easy=10, novelty=4, collect=7, show_off=8, giant=10, original=4),
    "Titanus Simulator (2, dying)": g(first_min=6, depth=5, social=4, pvp_thrill=6, pvp_safe=5, fair_money=6, looks=4, cute_funny=3, scary=2, crowd=0, updates=6, phone=7, easy=8, novelty=2, collect=3, show_off=7, giant=10, original=3),
}

KIDS = [
    dict(name="Grinder", w=dict(depth=3, collect=2, show_off=2, updates=1), veto=[("depth", "<", 6, "there's nothing to do after a day")]),
    dict(name="PvP sweat", w=dict(pvp_thrill=3, show_off=2, fair_money=1, depth=1), veto=[("pvp_thrill", "<", 6, "there's no real fighting")]),
    dict(name="Little sister (7)", w=dict(cute_funny=3, easy=2, pvp_safe=3, first_min=1), veto=[("scary", ">", 5, "it's too scary"), ("pvp_safe", "<", 6, "big kids will squash me"), ("cute_funny", "<", 5, "it's not cute")]),
    dict(name="Cheap-phone kid", w=dict(phone=3, easy=1, first_min=1), veto=[("phone", "<", 6, "it lags on my phone")]),
    dict(name="Social kid", w=dict(social=3, crowd=2, cute_funny=1), veto=[("social", "<", 6, "we can't even play TOGETHER")]),
    dict(name="Trend chaser", w=dict(crowd=3, novelty=2, updates=2), veto=[("crowd", "<", 4, "nobody plays it, it's dead")]),
    dict(name="Quality nerd", w=dict(looks=3, fair_money=2, novelty=1, depth=1), veto=[("looks", "<", 5, "it looks like AI slop"), ("original", "<", 5, "it's a copy of another game")]),
    dict(name="No-Robux kid", w=dict(fair_money=3, depth=1, first_min=1), veto=[("fair_money", "<", 6, "it's pay to win")]),
    dict(name="Giant fan (8)", w=dict(giant=3, show_off=1, cute_funny=1, first_min=1), veto=[]),
    dict(name="Bored-fast kid", w=dict(first_min=3, novelty=2, easy=1), veto=[("first_min", "<", 7, "it's boring at the start")]),
]
OURS = "STOMP EVOLUTION"

def vetoes(kid, game):
    return [(a, line) for a, op, val, line in kid["veto"] if (op == "<" and game[a] < val) or (op == ">" and game[a] > val)]
def score(kid, game):
    s = sum(w * game[a] for a, w in kid["w"].items())
    if game["scary"] > 6 and kid["name"].startswith("Little"): s -= 10
    return s
def debate(group, slate):
    rows = []
    for name, game in slate.items():
        vs = [(k["name"], v) for k in group for v in vetoes(k, game)]
        rows.append((len({n for n, _ in vs}), -sum(score(k, game) for k in group), name, vs))
    rows.sort()
    return rows[0][2], {r[2]: r[3] for r in rows}, rows

def run(ours, n=3000, seed=4, show=0, name=OURS, pool=None):
    rng = random.Random(seed); picked = no_veto = 0; obj = {}; ex = []
    pool = pool or RIVALS
    for _ in range(n):
        group = rng.sample(KIDS, rng.randint(3, 5))
        rivals = dict(rng.sample(sorted(pool.items()), 3))
        winner, vs, rows = debate(group, {name: ours, **rivals})
        picked += winner == name; no_veto += not vs[name]
        for kid, (attr, line) in vs[name]:
            key = f"{attr}: \"{line}\""; obj[key] = obj.get(key, 0) + 1
        if len(ex) < show: ex.append((group, list(rivals), winner, vs))
    return dict(agree=100 * no_veto / n, first=100 * picked / n, top=sorted(obj.items(), key=lambda kv: -kv[1]), ex=ex)

# our game. S0 scores come from the design doc v0 plus the two other sims' version A:
# first_min 6 (the plan loses 26% of kids by minute 5), looks 4 (115 cheap tells per 10 min on the plan),
# pvp_thrill 3 (no PvP in the city, the Sumo Ring was planned for week 3), crowd 1 (a new game).
S0 = g(first_min=6, depth=6, social=7, pvp_thrill=3, pvp_safe=10, fair_money=9, looks=4, cute_funny=5, scary=1, crowd=1,
       updates=5, phone=8, easy=9, novelty=5, collect=6, show_off=8, giant=10, original=5)
VERS = [("S0  the plan v0 (before the other two sims' fixes)", {})]
def fix(name, **kw): VERS.append((name, kw))
fix("S1  + first-minute fixes (impatient sim H: evolve at ~28 s, pads on the street)", first_min=8)
fix("S2  + hand-made look (nerd sim H: variants, set pieces, life, crumbles, form kits)", looks=8)
fix("S3  + SUMO RING at launch (size brackets) + Rampage = the crown holder vs the server", pvp_thrill=7)
fix("S4  + funny and cute: squeaky toy city, silly props, a pet-size first form", cute_funny=7)
fix("S5  + full servers: fill the fullest first, 10 slots, NPC stompers in the city", crowd=4)
fix("S6  + the difference up front: city + crown + Rampage in minute 1 and on the icon", original=7, novelty=7)
fix("S7  + depth at launch: 8 forms, 3 districts, Smash Index, AWAKEN", depth=8, collect=7)
fix("S8  + visible weekly updates: board in the plaza, countdown, a code", updates=8)
fix("S9  + launch push (marketing, not design): ads + code + Saturday event", crowd=5)

if __name__ == "__main__":
    print("CALIBRATION (each rival as 'our game' against the others): everyone agrees / 1st pick")
    for rn, rg in RIVALS.items():
        pool = {k: v for k, v in RIVALS.items() if k != rn}
        r = run(rg, n=1500, name=rn, pool=pool)
        print(f"  {rn:32} {r['agree']:3.0f}%  {r['first']:3.0f}%")
    print(f"\n{'version':84} agree  1st pick  top objections (groups out of 3,000)")
    ours = dict(S0)
    for name, kw in VERS:
        ours.update(kw); r = run(ours)
        print(f"{name:84} {r['agree']:4.0f}%  {r['first']:4.0f}%    " + ("; ".join(f"{k} {c}" for k, c in r["top"][:3]) or "none"))
    rng = random.Random(9); ag = []; fp = []; back = {}
    for _ in range(60):
        noisy = {k: max(0, min(10, v + rng.choice((-1, 0, 1)))) for k, v in ours.items()}
        r = run(noisy, n=1000, seed=rng.randrange(10**6)); ag.append(r["agree"]); fp.append(r["first"])
        for k, c in r["top"]: back[k] = back.get(k, 0) + 1
    print(f"\nrobustness (every score of ours +-1, 60 tries): agree median {st.median(ag):.0f}% (worst {min(ag):.0f}%), 1st pick median {st.median(fp):.0f}%")
    print("  objections that came back (tries out of 60): " + ("; ".join(f"{k} {c}" for k, c in sorted(back.items(), key=lambda kv: -kv[1])) or "none"))
    for c in (2, 3):
        m2 = dict(ours); m2["crowd"] = c; r = run(m2)
        print(f"if the launch crowd is only {c}/10: agree {r['agree']:.0f}%, 1st pick {r['first']:.0f}%, top: {r['top'][:1]}")
    # example debates: the same friend groups before (S0) and after (S9)
    rng = random.Random(21); shown = 0
    while shown < 3:
        group = rng.sample(KIDS, rng.randint(3, 5)); rivals = dict(rng.sample(sorted(RIVALS.items()), 3))
        w0, v0, _ = debate(group, {OURS: S0, **rivals}); w9, v9, _ = debate(group, {OURS: ours, **rivals})
        if w0 != OURS and v0[OURS] and w9 == OURS:
            shown += 1
            print(f"\nGROUP {shown}: {', '.join(k['name'] for k in group)}  |  on the table: {OURS}, {', '.join(rivals)}")
            print("   BEFORE  " + "; ".join(f"{kid}: \"{line}\"" for kid, (a, line) in v0[OURS]) + f"  -> they play {w0}")
            print(f"   AFTER   nobody says no to {OURS}  -> they play {w9}")
