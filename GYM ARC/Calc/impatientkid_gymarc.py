"""GYM ARC impatient-kid simulation (owner's method), first 5 minutes of a NEW player, build v1914.
Timeline = MEASURED in a Studio play-through on 25 Nov 2026 (23:30 MMT): UI state logged every 0.5 s + Config/Onboarding.
  PLAY tapped -> 0.6 s logo -> INTRO CUTSCENE 18.1 s (no control) -> auto-walk + seat on the Flat Bench (3 s) ->
  first rep ~32 s -> 8 reps (FillBar gift 100 coins) -> auto-leave -> Squat 5 reps -> Crunch 5 -> Pull-up 5 ->
  Growth Spurt goal 25/50/75 % (coins each) -> READY at ~96 s -> GROW transform 102-108 s -> Benny story shot 109-114 s ->
  step BeatBenny: the kid is walked to Benny's table, but NOTHING opens: no tap-to-start on screen (the prompt sits behind
  the player's own body), the line blinks 3 s of every 12 s. In the play-through it waited 40-120 s until E was pressed.
A kid has a boredom meter (+1/s when nothing happens; x0.6 while a cutscene plays and he's watching; x0.5 while he can
tap something that pays), rewards cut it (new things more than repeats; all wear off). Patience: lognormal median 11 s.
A heuristic model, not real players. Run: python impatientkid_gymarc.py
"""
import random, math, statistics as st
P = dict(watch=0.1, tap=0.03, drag=0.4, rew=6.0)  # calibrated (calib.py) so LIVE matches the 56-day Home funnel: ~85% past 60 s, ~62% past 3 min

def timeline(V):
    """list of (t, kind, value, label) for the first 300 s after PLAY. kinds: watch (non-interactive from t to t+value),
    tap (tappable stretch t..t+value, small pay each tap), reward (one moment, value = size), stall (nothing to do),"""
    ev = []; t = 0.6
    intro = V.get("intro", 18.1)
    ev.append((t, "watch", intro, "intro cutscene")); t += intro
    if V.get("gift_at_start"): ev.append((t + 0.5, "reward", 3.0, "FREE GIFT claimed (Christmas tree)"))
    ev.append((t, "watch", 3.0, "auto-walk to the bench")); t += 3.0
    ev.append((t + 1.0, "reward", 2.5, "first rep: big moment + coins")); 
    # bench 8 reps at ~1.3 s each (auto reps + taps)
    ev.append((t, "tap", 8 * 1.3, "bench reps")); t += 8 * 1.3
    ev.append((t, "reward", 1.5, "+100 coins gift, 25% goal")); 
    for name in ("squat", "crunch", "pull-up"):
        ev.append((t, "watch", 4.5, f"auto-leave + walk to {name}")); t += 4.5
        ev.append((t + 0.5, "reward", 1.2, f"new machine: {name}"))
        ev.append((t, "tap", 5 * 1.3, f"{name} reps")); t += 5 * 1.3
        ev.append((t, "reward", 0.8, "goal % up / personal record"))
    fill = V.get("fill_to_ready", 96 - t - 0.6)
    ev.append((t, "tap", max(fill, 0), "GO TRAIN reps to READY")); t += max(fill, 0)
    ev.append((t, "reward", 2.0, "GROWTH SPURT READY")); t += V.get("ready_gap", 6)
    ev.append((t, "watch", 6, "GROW transform")); ev.append((t + 5, "reward", 4.0, "you grew TALLER")); t += 6
    ev.append((t, "watch", 5, "Benny story shot")); t += 5
    ev.append((t, "watch", 2.5, "walked to Benny's table")); t += 2.5
    stall = V.get("benny_stall", "find")
    ev.append((t, "stall", stall, "standing at Benny's table, nothing opens")); 
    ev.append(("after_stall", "watch", 3, "Benny's card")); 
    ev.append(("after_stall+3", "tap", 15, "arm wrestle Benny (tap fast)"))
    ev.append(("after_stall+18", "reward", 4.0, "BEAT BENNY: Beach Gym opens + 900 coins"))
    ev.append(("after_stall+20", "watch", 6, "walk to the Beach Gym"))
    ev.append(("after_stall+26", "reward", 2.0, "new gym: the beach"))
    ev.append(("after_stall+26", "tap", 200, "beach reps (15/15/20/20)"))
    return ev

def kid_run(V, rng, patience):
    ev = timeline(V)
    # when does the kid find Benny's start? live: the prompt is hidden behind his own body -> 3%/s chance he finds it
    if ev and any(e[1] == "stall" for e in ev):
        st_ev = [e for e in ev if e[1] == "stall"][0]
        if V.get("benny_stall") == "auto":
            find = 1.5
        else:
            find = 0.0
            while find < 400:
                find += 1
                if rng.random() < V.get("find_rate", 0.15): break
        t0 = st_ev[0] + find
        ev = [e for e in ev if e[1] != "stall"] + [(st_ev[0], "stall", find, st_ev[3])]
        ev = [((t0 + float(e[0].split("+")[1]) if "+" in e[0] else t0) if isinstance(e[0], str) else e[0], *e[1:]) for e in ev]
    bored = 0.0; had = 0.0; tick = 0.5; t = 0.0
    react = rng.uniform(0.6, 2.2)
    rewards = sorted([e for e in ev if e[1] == "reward"], key=lambda e: e[0])
    ri = 0; deadest = 0; dead = 0
    while t < 300:
        kind = None
        for e in ev:
            if e[1] in ("watch", "tap", "stall") and e[0] <= t < e[0] + e[2]: kind = e[1]
        rate = {"watch": P["watch"], "tap": P["tap"], "stall": 1.0, None: 1.0}[kind]
        if kind == "watch" and t > 8 and t < V.get("intro", 18.1): rate = P["drag"]  # a long cutscene drags after ~8 s
        if kind == "stall": rate = 1.3 if t > 25 else 1.0   # "nothing new for 25 s"
        bored += rate * tick
        dead = dead + tick if kind in ("stall", None) else 0; deadest = max(deadest, dead)
        while ri < len(rewards) and rewards[ri][0] <= t:
            if rng.random() < 0.85:  # noticed
                bored = max(0.0, bored - rewards[ri][2] * P["rew"] / (1 + 0.15 * had)); had += 1
            ri += 1
        if bored > patience: return t, deadest
        t += tick
    return 300, deadest

def run(V, n=3000, med=11, seed=3):
    rng = random.Random(seed); stays = {k: 0 for k in (15, 30, 60, 120, 180, 300)}; quits = []; dead = []
    for _ in range(n):
        p = rng.lognormvariate(math.log(med), 0.45)
        q, d = kid_run(V, rng, p); quits.append(q); dead.append(d)
        for k in stays:
            if q >= k: stays[k] += 1
    return {k: 100 * v / n for k, v in stays.items()}, st.median(dead)

VERS = [
    ("A  live v1914", {}),
    ("B  + intro cutscene 18 s -> 8 s (keep Benny's taunt, cut the walk-up shots; SKIP after 3 s)", {"intro": 8}),
    ("C  + Benny's card opens by itself when the tutorial walks you to his table", {"intro": 8, "benny_stall": "auto"}),
    ("D  + GROW right when READY (no 6 s wait on the READY card)", {"intro": 8, "benny_stall": "auto", "ready_gap": 1.5}),
    ("E  + (Christmas) free gift under the tree in the first 10 s", {"intro": 8, "benny_stall": "auto", "ready_gap": 1.5, "gift_at_start": True}),
]

if __name__ == "__main__":
    print(f"{'version':92} {'15s':>5} {'30s':>5} {'60s':>5} {'2m':>5} {'3m':>5} {'5m':>5}  longest dead (median)")
    for name, V in VERS:
        s, d = run(V)
        print(f"{name:92} " + " ".join(f"{s[k]:4.0f}%" for k in (15, 30, 60, 120, 180, 300)) + f"   {d:4.0f} s")
    print("\nsensitivity (version E):")
    for med in (7, 11, 16):
        s, d = run(VERS[-1][1], med=med); print(f"  median patience {med:2d} s: " + " ".join(f"{s[k]:4.0f}%" for k in (15, 30, 60, 120, 180, 300)))
    for med in (7, 11, 16):
        s, d = run(VERS[0][1], med=med); print(f"  live, patience {med:2d} s:     " + " ".join(f"{s[k]:4.0f}%" for k in (15, 30, 60, 120, 180, 300)))
    for fr in (0.05, 0.15, 0.30):
        s, d = run(dict(VERS[1][1], find_rate=fr)); print(f"  B with prompt-find rate {fr:.2f}/s: 3m {s[180]:.0f}%  5m {s[300]:.0f}%")
