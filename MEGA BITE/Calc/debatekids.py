"""MEGA BITE debate-kids simulation (owner's method, 9 Nov 2026).
Groups of 3-5 kids argue over which Roblox game to play together. Each kid has a personality
(what he cares about) and deal-breakers (a veto: "I'm NOT playing that"). Friends only play a
game nobody vetoes. We log every objection to MEGA BITE, then add one design fix per version.

Rival profiles = estimates from public info (live players: Rowatcher Jun 2026, GGRecon 2 Nov 2026,
Rolimons 9 Nov 2026; research notes). Scores 0-10. A model of arguments, not real kids.
Run: python debatekids.py
"""
import random, statistics as st

A = ["first_min", "depth", "social", "pvp_thrill", "pvp_safe", "fair_money", "looks", "cute_funny",
     "scary", "crowd", "updates", "phone", "easy", "novelty", "collect", "show_off", "ocean", "original"]

def g(**kw):
    d = {a: 5 for a in A}; d.update(kw); return d

RIVALS = {
    "Brookhaven RP":      g(first_min=8, depth=4, social=10, pvp_thrill=1, pvp_safe=9, fair_money=6, looks=6, cute_funny=7, scary=1, crowd=10, updates=6, phone=8, easy=10, novelty=2, collect=4, show_off=8, ocean=0, original=8),
    "Blox Fruits":        g(first_min=5, depth=10, social=8, pvp_thrill=8, pvp_safe=6, fair_money=5, looks=6, cute_funny=3, scary=2, crowd=10, updates=7, phone=6, easy=5, novelty=3, collect=9, show_off=9, ocean=3, original=7),
    "99 Nights":          g(first_min=7, depth=6, social=10, pvp_thrill=0, pvp_safe=9, fair_money=7, looks=7, cute_funny=4, scary=7, crowd=9, updates=7, phone=6, easy=7, novelty=6, collect=5, show_off=5, ocean=0, original=8),
    "Murder Mystery 2":   g(first_min=8, depth=4, social=8, pvp_thrill=8, pvp_safe=6, fair_money=6, looks=5, cute_funny=4, scary=4, crowd=9, updates=5, phone=8, easy=9, novelty=2, collect=8, show_off=8, ocean=0, original=8),
    "Steal a Brainrot":   g(first_min=8, depth=5, social=7, pvp_thrill=7, pvp_safe=5, fair_money=5, looks=5, cute_funny=9, scary=1, crowd=9, updates=8, phone=7, easy=9, novelty=5, collect=8, show_off=7, ocean=0, original=6),
    "Fish It!":           g(first_min=7, depth=7, social=6, pvp_thrill=0, pvp_safe=10, fair_money=6, looks=7, cute_funny=5, scary=1, crowd=9, updates=8, phone=7, easy=9, novelty=5, collect=10, show_off=7, ocean=9, original=6),
    "Break & Steal Egg":  g(first_min=8, depth=4, social=7, pvp_thrill=6, pvp_safe=5, fair_money=5, looks=5, cute_funny=8, scary=1, crowd=9, updates=8, phone=7, easy=9, novelty=8, collect=7, show_off=6, ocean=0, original=4),
    "Be Fish":            g(first_min=8, depth=6, social=6, pvp_thrill=5, pvp_safe=7, fair_money=8, looks=6, cute_funny=7, scary=2, crowd=4, updates=5, phone=8, easy=9, novelty=4, collect=6, show_off=6, ocean=10, original=5),
    "DEVOUR":             g(first_min=6, depth=6, social=5, pvp_thrill=7, pvp_safe=4, fair_money=4, looks=6, cute_funny=4, scary=4, crowd=2, updates=6, phone=4, easy=7, novelty=5, collect=7, show_off=6, ocean=10, original=5),
    "SharkBite 2":        g(first_min=7, depth=5, social=8, pvp_thrill=8, pvp_safe=6, fair_money=4, looks=6, cute_funny=5, scary=4, crowd=4, updates=4, phone=7, easy=8, novelty=3, collect=6, show_off=6, ocean=10, original=7),
}

# kid personalities: weights (what they argue for) + vetoes (deal-breakers) + the line they say
KIDS = [
    dict(name="Grinder", w=dict(depth=3, collect=2, show_off=2, updates=1), veto=[("depth", "<", 6, "there's nothing to do after a day")]),
    dict(name="PvP sweat", w=dict(pvp_thrill=3, show_off=2, fair_money=1, depth=1), veto=[("pvp_thrill", "<", 6, "there's no real fighting")]),
    dict(name="Little sister (7)", w=dict(cute_funny=3, easy=2, pvp_safe=3, first_min=1), veto=[("scary", ">", 5, "it's too scary"), ("pvp_safe", "<", 6, "big kids will eat me"), ("cute_funny", "<", 5, "it's not cute")]),
    dict(name="Cheap-phone kid", w=dict(phone=3, easy=1, first_min=1), veto=[("phone", "<", 6, "it lags on my phone")]),
    dict(name="Social kid", w=dict(social=3, crowd=2, cute_funny=1), veto=[("social", "<", 6, "we can't even play TOGETHER")]),
    dict(name="Trend chaser", w=dict(crowd=3, novelty=2, updates=2), veto=[("crowd", "<", 4, "nobody plays it, it's dead")]),
    dict(name="Quality nerd", w=dict(looks=3, fair_money=2, novelty=1, depth=1), veto=[("looks", "<", 5, "it looks like AI slop"), ("original", "<", 5, "it's a copy of another game")]),
    dict(name="No-Robux kid", w=dict(fair_money=3, depth=1, first_min=1), veto=[("fair_money", "<", 6, "it's pay to win")]),
    dict(name="Shark fan (8)", w=dict(ocean=3, show_off=1, cute_funny=1, first_min=1), veto=[]),
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
    """Friends play the game with the best total score that NOBODY vetoes.
    If every game is vetoed by someone, they pick the one with the fewest vetoes."""
    rows = []
    for name, game in slate.items():
        vs = [(k["name"], v) for k in group for v in vetoes(k, game)]
        total = sum(score(k, game) for k in group)
        rows.append((len({n for n, _ in vs}), -total, name, vs))
    rows.sort()
    return rows[0][2], {r[2]: r[3] for r in rows}

def run(mega, n=3000, seed=4, show=0):
    rng = random.Random(seed); picked = 0; no_veto = 0; objections = {}; examples = []
    for i in range(n):
        group = rng.sample(KIDS, rng.randint(3, 5))
        rivals = dict(rng.sample(sorted(RIVALS.items()), 3))
        slate = {"MEGA BITE": mega, **rivals}
        winner, vs = debate(group, slate)
        if winner == "MEGA BITE": picked += 1
        if not vs["MEGA BITE"]: no_veto += 1
        for kid, (attr, line) in vs["MEGA BITE"]:
            key = f"{attr}: \"{line}\""; objections[key] = objections.get(key, 0) + 1
        if len(examples) < show and vs["MEGA BITE"]:
            examples.append((group, rivals, winner, vs["MEGA BITE"]))
    top = sorted(objections.items(), key=lambda kv: -kv[1])
    return dict(agree=100 * no_veto / n, first=100 * picked / n, top=top, examples=examples)

# ---------------------------------------------------------------- MEGA BITE versions
MEGA = g(first_min=7, depth=7, social=4, pvp_thrill=6, pvp_safe=8, fair_money=9, looks=7, cute_funny=4,
         scary=6, crowd=1, updates=5, phone=7, easy=7, novelty=6, collect=8, show_off=7, ocean=10, original=6)
VERS = [("M0  the concept today (after the map + EXP sims)", {})]
def fix(name, **kw): VERS.append((name, kw))
fix("M1  + SCHOOLS at launch: join a friend, crews of 4, shared FRENZY, co-op squid", social=8)
fix("M2  + cartoon look (big eyes, round fins, funny gulp), scary only in the Trench", scary=3, cute_funny=6)
fix("M3  + full servers: fill the fullest first, 16 slots, NPC life, creator launch", crowd=4)
fix("M4  + visible weekly updates: countdown, roadmap board, Saturday event", updates=8)
fix("M5  + the twist up front: carry-home + abilities in the 1st minute + thumbnail", novelty=8, original=8)
fix("M6  + first-minute fixes from the sims, auto-swim + green/red outlines", first_min=8, easy=8)
fix("M7  + Red Trench made for sweats: crown bounty, APEX HOUR, weekly Trench board", pvp_thrill=8)
fix("M8  + launch push (marketing, not design): creators + code + Saturday event", crowd=5)

if __name__ == "__main__":
    mega = dict(MEGA)
    print(f"{'version':70} agree  1st pick  top objections (groups out of 3,000)")
    for name, kw in VERS:
        mega.update(kw)
        r = run(mega)
        top = "; ".join(f"{k} {c}" for k, c in r["top"][:3]) or "none"
        print(f"{name:70} {r['agree']:4.0f}%  {r['first']:4.0f}%    {top}")
    # robustness: every MEGA BITE score off by -1..+1 at random (200 versions of the final game)
    rng = random.Random(9); ag = []; fp = []
    for _ in range(60):
        noisy = {k: max(0, min(10, v + rng.choice((-1, 0, 1)))) for k, v in mega.items()}
        r = run(noisy, n=1000, seed=rng.randrange(10**6)); ag.append(r["agree"]); fp.append(r["first"])
    print(f"\nrobustness (scores +-1): agree median {st.median(ag):.0f}% (worst {min(ag):.0f}%), 1st pick median {st.median(fp):.0f}%")
    for c in (2, 3):
        m2 = dict(mega); m2["crowd"] = c; r = run(m2)
        print(f"if launch crowd is only {c}/10: agree {r['agree']:.0f}%, 1st pick {r['first']:.0f}%, top: {r['top'][:1]}")
    r = run(mega, show=0)
    for seed in (5, 6):
        q = run(mega, seed=seed); print(f"seed {seed}: agree {q['agree']:.0f}%  1st pick {q['first']:.0f}%")
