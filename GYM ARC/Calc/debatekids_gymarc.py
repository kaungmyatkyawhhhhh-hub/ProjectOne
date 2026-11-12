"""GYM ARC debate-kids simulation (owner's method; run 13 Nov 2026 on build v1882: ELEMENTS + Ruby fix + critic fixes).
Groups of 3-5 kids argue over which Roblox game to play together. Each kid has weights (what he argues for) and
deal-breakers (a veto: "I'm NOT playing that"). Friends only play a game nobody vetoes; among those the best total.
Rival scores = estimates from public info: live players checked 13 Nov 2026 ~03:00 MMT via games.roblox.com
(Muscle Legends 2,412, Gym Star 3,244, Power Lifters 3,169, Arm Wrestle Sim 1,830, +1 Break Walls 1,100,
Gym League 622, Strongman 444, Project: Iron 301, GYM ARC 56), RoWatcher / GGRecon Nov 2026 for the big hits,
and the vault's 29 Oct gym genre research. GYM ARC's own scores come from the 12 Nov critic review, the
funnel note and the owner's 13 Nov report (dislikes because it lags). A model of arguments, not real kids.
Run: python debatekids_gymarc.py
"""
import random, statistics as st

A = ["first_min", "depth", "social", "pvp_thrill", "pvp_safe", "fair_money", "looks", "cute_funny",
     "scary", "crowd", "updates", "phone", "easy", "novelty", "collect", "show_off", "gym", "original"]

def g(**kw):
    d = {a: 5 for a in A}; d.update(kw); return d

RIVALS = {
    # the big hits (any friend group might pick them instead)
    "Brookhaven RP":       g(first_min=8, depth=4, social=10, pvp_thrill=1, pvp_safe=9, fair_money=6, looks=6, cute_funny=7, scary=1, crowd=10, updates=6, phone=8, easy=10, novelty=2, collect=4, show_off=8, gym=1, original=8),
    "Steal a Brainrot":    g(first_min=8, depth=5, social=7, pvp_thrill=7, pvp_safe=5, fair_money=5, looks=5, cute_funny=9, scary=1, crowd=9, updates=8, phone=7, easy=9, novelty=5, collect=8, show_off=7, gym=0, original=6),
    "99 Nights":           g(first_min=7, depth=6, social=10, pvp_thrill=0, pvp_safe=9, fair_money=7, looks=7, cute_funny=4, scary=7, crowd=8, updates=7, phone=6, easy=7, novelty=6, collect=5, show_off=5, gym=0, original=8),
    "Murder Mystery 2":    g(first_min=8, depth=4, social=8, pvp_thrill=8, pvp_safe=6, fair_money=6, looks=5, cute_funny=4, scary=4, crowd=10, updates=5, phone=8, easy=9, novelty=2, collect=8, show_off=8, gym=0, original=8),
    "RIVALS":              g(first_min=8, depth=6, social=7, pvp_thrill=10, pvp_safe=3, fair_money=7, looks=7, cute_funny=3, scary=3, crowd=9, updates=8, phone=6, easy=7, novelty=4, collect=7, show_off=8, gym=0, original=7),
    "DONT SPLASH":         g(first_min=9, depth=3, social=8, pvp_thrill=4, pvp_safe=8, fair_money=7, looks=6, cute_funny=8, scary=1, crowd=9, updates=7, phone=8, easy=10, novelty=9, collect=3, show_off=4, gym=0, original=7),
    # the gym genre (the "we want a gym game" groups)
    "Muscle Legends":      g(first_min=7, depth=7, social=7, pvp_thrill=7, pvp_safe=5, fair_money=5, looks=4, cute_funny=5, scary=1, crowd=6, updates=7, phone=8, easy=9, novelty=2, collect=6, show_off=7, gym=9, original=7),
    "Gym Star Simulator":  g(first_min=7, depth=8, social=7, pvp_thrill=5, pvp_safe=7, fair_money=5, looks=6, cute_funny=6, scary=1, crowd=6, updates=8, phone=7, easy=8, novelty=3, collect=9, show_off=8, gym=9, original=6),
    "Power Lifters":       g(first_min=7, depth=6, social=6, pvp_thrill=4, pvp_safe=8, fair_money=6, looks=7, cute_funny=4, scary=1, crowd=6, updates=8, phone=7, easy=8, novelty=6, collect=5, show_off=7, gym=10, original=6),
    "Arm Wrestle Sim":     g(first_min=7, depth=7, social=6, pvp_thrill=7, pvp_safe=7, fair_money=5, looks=6, cute_funny=6, scary=1, crowd=5, updates=9, phone=7, easy=9, novelty=3, collect=9, show_off=7, gym=8, original=6),
    "Gym League":          g(first_min=6, depth=7, social=6, pvp_thrill=6, pvp_safe=6, fair_money=4, looks=6, cute_funny=5, scary=1, crowd=3, updates=7, phone=7, easy=8, novelty=3, collect=7, show_off=7, gym=9, original=6),
    "+1 Break Walls":      g(first_min=8, depth=3, social=4, pvp_thrill=2, pvp_safe=9, fair_money=6, looks=4, cute_funny=6, scary=1, crowd=4, updates=4, phone=8, easy=10, novelty=4, collect=4, show_off=5, gym=7, original=3),
    "Project: Iron":       g(first_min=5, depth=8, social=5, pvp_thrill=3, pvp_safe=8, fair_money=6, looks=7, cute_funny=2, scary=1, crowd=2, updates=6, phone=5, easy=5, novelty=7, collect=5, show_off=7, gym=10, original=7),
}
GYM_GENRE = ["Muscle Legends", "Gym Star Simulator", "Power Lifters", "Arm Wrestle Sim", "Gym League", "+1 Break Walls", "Project: Iron"]

KIDS = [
    dict(name="Grinder", w=dict(depth=3, collect=2, show_off=2, updates=1), veto=[("depth", "<", 6, "there's nothing to do after a day")]),
    dict(name="PvP sweat", w=dict(pvp_thrill=3, show_off=2, fair_money=1, depth=1), veto=[("pvp_thrill", "<", 6, "you can't even fight anyone")]),
    dict(name="Little brother (7)", w=dict(cute_funny=3, easy=2, pvp_safe=3, first_min=1), veto=[("scary", ">", 5, "it's too scary"), ("pvp_safe", "<", 6, "big kids will beat me up"), ("cute_funny", "<", 5, "it's not funny")]),
    dict(name="Cheap-phone kid", w=dict(phone=3, easy=1, first_min=1), veto=[("phone", "<", 6, "it lags on my phone")]),
    dict(name="Social kid", w=dict(social=3, crowd=2, cute_funny=1), veto=[("social", "<", 6, "we can't even play TOGETHER")]),
    dict(name="Trend chaser", w=dict(crowd=3, novelty=2, updates=2), veto=[("crowd", "<", 4, "nobody plays it, it's dead")]),
    dict(name="Quality nerd", w=dict(looks=3, fair_money=2, novelty=1, depth=1), veto=[("looks", "<", 5, "it looks cheap"), ("original", "<", 5, "it's a copy of another game")]),
    dict(name="No-Robux kid", w=dict(fair_money=3, depth=1, first_min=1), veto=[("fair_money", "<", 6, "it's pay to win, it keeps asking for Robux")]),
    dict(name="Gym fan (10)", w=dict(gym=3, show_off=2, depth=1), veto=[]),
    dict(name="Bored-fast kid", w=dict(first_min=3, novelty=2, easy=1), veto=[("first_min", "<", 7, "it's boring at the start")]),
]

def vetoes(kid, game):
    out = []
    for attr, op, val, line in kid["veto"]:
        x = game[attr]
        if (op == "<" and x < val) or (op == ">" and x > val): out.append((attr, line))
    return out

def score(kid, game):
    s = sum(w * game[a] for a, w in kid["w"].items())
    if game["scary"] > 6 and kid["name"].startswith("Little"): s -= 10
    return s

def debate(group, slate):
    rows = []
    for name, game in slate.items():
        vs = [(k["name"], v) for k in group for v in vetoes(k, game)]
        total = sum(score(k, game) for k in group)
        rows.append((len({n for n, _ in vs}), -total, name, vs))
    rows.sort()
    return rows[0][2], {r[2]: r[3] for r in rows}

def slate_for(rng, ours, gym_group):
    """gym_group: the friends already want a gym game (rivals from the genre). Else any 3 rivals."""
    pool = [(n, RIVALS[n]) for n in GYM_GENRE] if gym_group else sorted(RIVALS.items())
    return {"GYM ARC": ours, **dict(rng.sample(pool, 3))}

def run(ours, n=3000, seed=4, show=0, gym_share=0.5, target="GYM ARC"):
    rng = random.Random(seed); picked = 0; no_veto = 0; objections = {}; examples = []
    for i in range(n):
        group = rng.sample(KIDS, rng.randint(3, 5))
        slate = slate_for(rng, ours, rng.random() < gym_share)
        winner, vs = debate(group, slate)
        if winner == "GYM ARC": picked += 1
        if not vs["GYM ARC"]: no_veto += 1
        for kid, (attr, line) in vs["GYM ARC"]:
            key = f"{attr}: \"{line}\""; objections[key] = objections.get(key, 0) + 1
        if len(examples) < show and i % 7 == 0:
            examples.append(([k["name"] for k in group], [x for x in slate if x != "GYM ARC"], winner, vs["GYM ARC"]))
    top = sorted(objections.items(), key=lambda kv: -kv[1])
    return dict(agree=100 * no_veto / n, first=100 * picked / n, top=top, examples=examples)

def calibrate():
    rng = random.Random(1); n = 3000; agree = {k: 0 for k in RIVALS}; seen = {k: 0 for k in RIVALS}
    for _ in range(n):
        group = rng.sample(KIDS, rng.randint(3, 5))
        for name, game in RIVALS.items():
            seen[name] += 1
            if not any(vetoes(k, game) for k in group): agree[name] += 1
    return {k: 100 * agree[k] / seen[k] for k in RIVALS}

# ------------------------------------------------------------- GYM ARC today and the fixes (cumulative)
GYMARC = g(first_min=7, depth=8, social=5, pvp_thrill=4, pvp_safe=9, fair_money=5, looks=7, cute_funny=5,
           scary=1, crowd=2, updates=8, phone=4, easy=7, novelty=6, collect=7, show_off=8, gym=10, original=7)
VERS = [("G0  build v1882 today (ELEMENTS, Ruby fix, critic fixes, short intro)", {})]
def fix(name, **kw): VERS.append((name, kw))

fix("G1  + LAG PASS: auto low-end mode on phones, stream out the far town, fewer parts/triangles, particle caps", phone=7)
fix("G2  + FAIR MONEY: no full-screen pack before Spurt 2, no 'worth/save %/30 min only', free daily boost, no pay-only walls", fair_money=7)
fix("G3  + PLAY TOGETHER: JOIN FRIEND button, SPOT ME duo lifts (+EXP both), crew gym sessions", social=7)
fix("G4  + REAL PVP: arm wrestle any player (ranked, weekly board), posing show voted by players", pvp_thrill=7)
fix("G5  + full-feeling servers: fill the fullest first, 12 slots, gym NPC regulars; Saturday launch event", crowd=3)
fix("G6  + margin on the edges: intro ~15 s / first rep in 10 s; goofy bully + funny poses", first_min=8, cute_funny=6)
fix("G7  + launch push (MARKETING, not design): ads + creators + ELEMENTS event + code", crowd=5)

if __name__ == "__main__":
    import sys
    print("CALIBRATION: % of friend groups with no veto on each rival")
    for k, v in sorted(calibrate().items(), key=lambda kv: -kv[1]): print(f"  {k:22} {v:5.1f}%")
    ours = dict(GYMARC); hist = []
    print(f"\n{'version':108} agree  1st   top objections (groups of 3,000)")
    for name, kw in VERS:
        ours.update(kw); r = run(ours); hist.append((name, r))
        top = "; ".join(f"{k.split(':')[0]} {c}" for k, c in r["top"][:3]) or "none"
        print(f"{name:108} {r['agree']:4.0f}%  {r['first']:3.0f}%  {top}")
    # gym-only groups vs general groups
    for share, lab in ((1.0, "groups that want a gym game"), (0.0, "groups picking from the big hits")):
        q = run(ours, gym_share=share); print(f"final, {lab}: agree {q['agree']:.0f}%  1st pick {q['first']:.0f}%")
    rng = random.Random(9); ag = []; fp = []; back = {}
    for _ in range(60):
        noisy = {k: max(0, min(10, v + rng.choice((-1, 0, 1)))) for k, v in ours.items()}
        r = run(noisy, n=1000, seed=rng.randrange(10**6)); ag.append(r["agree"]); fp.append(r["first"])
        for k, c in r["top"]: back[k.split(':')[0]] = back.get(k.split(':')[0], 0) + c
    print(f"robustness (+-1): agree median {st.median(ag):.0f}% (worst {min(ag):.0f}%), 1st median {st.median(fp):.0f}%; objections that came back: {sorted(back.items(), key=lambda kv:-kv[1])[:4]}")
    for c in (2, 3, 4):
        m2 = dict(ours); m2["crowd"] = c; r = run(m2)
        print(f"if the crowd stays {c}/10: agree {r['agree']:.0f}%, 1st {r['first']:.0f}%, top: {r['top'][:1]}")
    for seed in (5, 6):
        q = run(ours, seed=seed); print(f"seed {seed}: agree {q['agree']:.0f}%  1st {q['first']:.0f}%")
