"""GYM ARC quality-nerd kid simulation (owner's method), first 10 minutes of a new player, live build v1914.
Route and views MEASURED in the 25 Nov 2026 Studio play-through (screenshots at the spawn gym, bench, beach, Hall of Fame
plaza, ProGym): each view = a list of what can be seen. Tells (cheap-looking) and wows (hand-made moments) are counted;
repeats of the same tell kind matter less (log). Score = 1.6*log(1+wows) - sum(w*log(1+count)).
A model with estimated weights, not real kids.  Run: python qualitynerd_gymarc.py
"""
import math, random, statistics as st

# route for minute 0-10: (t_start, t_end, place, chance a kid walks there in this window)
ROUTE = [(0, 32, "spawn_gym", 1.0), (32, 115, "bench_area", 1.0), (115, 180, "benny_table", 1.0),
         (180, 330, "beach_gym", 0.75), (330, 450, "hof_plaza", 0.55), (450, 600, "progym", 0.4)]

def views(V):
    """tells per place: kind -> (chance per look at this place, weight). wows: name -> chance per visit (once)."""
    T = {
        "spawn_gym":  {"trainer ghost over the camera": (0.0 if V.get("ghost") else 0.10, 1.2)},
        "bench_area": {"trainer ghost over the camera": (0.0 if V.get("ghost") else 0.25, 1.2),
                       "same plate/rack prop again": (0.03 if V.get("kit") else 0.08, 0.6)},
        "benny_table":{"own body hides the NPC you need": (0.0 if V.get("cam") else 0.55, 1.0),
                       "nothing tells you what to do": (0.0 if V.get("benny") else 0.30, 1.0)},
        "beach_gym":  {"flat card palm leaves": (0.0 if V.get("palms") else 0.35, 0.9),
                       "floating sign (no post)": (0.0 if V.get("sign") else 0.15, 0.8)},
        "hof_plaza":  {"plain black box in the middle": (0.0 if V.get("box") else 0.45, 1.4),
                       "blank black screen/board": (0.0 if V.get("screens") else 0.40, 1.3)},
        "progym":     {"blank black screen/board": (0.0 if V.get("screens") else 0.30, 1.3),
                       "same plate/rack prop again": (0.03 if V.get("kit") else 0.10, 0.6)},
    }
    W = {"spawn_gym": {"GROW transform": 0.0}, "bench_area": {"GROW transform": 1.0},
         "benny_table": {"Benny story shot": 1.0}, "beach_gym": {"beach view": 0.9},
         "hof_plaza": {"Hall of Fame statues": 0.8, **({"plaza centrepiece (trophy)": 0.9} if V.get("box") else {}),
                       **({"live leaderboard screens": 0.7} if V.get("screens") else {})},
         "progym": {"ProGym city view": 0.8}}
    if V.get("xmas"):
        W["spawn_gym"]["Christmas lights + snow in the spawn gym"] = 0.9
        W["beach_gym"]["Christmas tree on the beach"] = 0.8
    return T, W

def kid(V, rng):
    T, W = views(V); counts = {}; wows = 0
    for a, b, place, p in ROUTE:
        if rng.random() > p: continue
        t = a
        for name, c in W[place].items():
            if rng.random() < c: wows += 1
        seen = set()
        while t < b:   # a look every 2 s; a STATIC tell counts once per visit, a moving one (ghost) at most every 10 s
            for kind, (c, w) in T[place].items():
                moving = "ghost" in kind or "same plate" in kind
                if (moving and int(t) % 10 >= 2) or (not moving and kind in seen): continue
                if rng.random() < c: counts[kind] = counts.get(kind, 0) + 1; seen.add(kind)
            t += 2.0
    score = 1.6 * math.log(1 + wows) - sum(W_[1] * math.log(1 + counts.get(k, 0))
                                           for pl in T.values() for k, W_ in pl.items()) / 1.0
    # de-duplicate the kinds that appear in two places
    kinds = {}
    for pl in T.values():
        for k, (c, w) in pl.items(): kinds[k] = w
    score = 1.6 * math.log(1 + wows) - sum(w * math.log(1 + counts.get(k, 0)) for k, w in kinds.items())
    return counts, wows, score

def run(V, n=2000, seed=3):
    rng = random.Random(seed); tot = {}; tells = []; wows = []; like = 0
    for _ in range(n):
        c, w, s = kid(V, rng); tells.append(sum(c.values())); wows.append(w)
        for k, v in c.items(): tot[k] = tot.get(k, 0) + v
        like += s > 0.0
    top = sorted(((k, v / n) for k, v in tot.items()), key=lambda kv: -kv[1])[:3]
    return st.mean(tells), top, st.mean(wows), 100 * like / n

VERS = [("A  live v1914", {}),
        ("B  + Benny: camera swings to his face + card opens (no hidden NPC)", {"cam": 1, "benny": 1}),
        ("C  + plaza black box -> a real centrepiece (gold trophy)", {"cam": 1, "benny": 1, "box": 1}),
        ("D  + blank screens -> live leaderboard / poster art", {"cam": 1, "benny": 1, "box": 1, "screens": 1}),
        ("E  + trainer NPCs never between the camera and the player (fade/offset)", {"cam": 1, "benny": 1, "box": 1, "screens": 1, "ghost": 1}),
        ("F  + palm leaves as real meshes, sign on a post", {"cam": 1, "benny": 1, "box": 1, "screens": 1, "ghost": 1, "palms": 1, "sign": 1}),
        ("G  + Christmas dressing (spawn lights + snow, beach tree)", {"cam": 1, "benny": 1, "box": 1, "screens": 1, "ghost": 1, "palms": 1, "sign": 1, "xmas": 1}),
        ("H  + 3 plate/rack variants (colour + wear) so the same prop doesn't repeat", {"cam": 1, "benny": 1, "box": 1, "screens": 1, "ghost": 1, "palms": 1, "sign": 1, "xmas": 1, "kit": 1})]

if __name__ == "__main__":
    print(f"{'version':78} tells/10min  wows   like%   top tells (per kid)")
    for name, V in VERS:
        t, top, w, l = run(V)
        print(f"{name:78} {t:7.1f}   {w:5.1f}  {l:5.0f}   " + "; ".join(f"{k} {v:.1f}" for k, v in top))
