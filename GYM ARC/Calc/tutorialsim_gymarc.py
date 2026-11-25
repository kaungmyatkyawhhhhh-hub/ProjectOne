"""GYM ARC tutorial + cutscene redesign: impatient-kid simulation, first 5 minutes (26 Nov 2026, 04:00 MMT).
Built on impatientkid_gymarc.py (same calibration to the live 56-day funnel) with what the owner felt ("the tutorial is
boring", "the intro cutscene and cutscenes too") and what the bug-hunt play-through showed on live v1914:
  * the tutorial PLAYS ITSELF: autoGo walks you, autoLeave stops the set, the PUMP bar fills by itself while any step is left
    (owner 3 Nov), reps kept coming with no input, GO TRAIN presses itself (autoTrain), Benny's first match is an auto win.
    A kid who never touches the screen reaches Benny and the beach.
  * cutscenes: intro 18.1 s, GROW 6 s, Benny story 5 s, Coral story ~8 s, none skippable on the first view.
New in this model (research in the vault note):
  * OWN vs AUTO: a reward the kid caused himself cuts boredom fully; a reward that happened on its own while he watched cuts
    only AUTO_PAY of it (CHI 2024, 1,699 players: feedback tied to the player's own success raised motivation, effects that
    were just bigger lowered it; "IKEA effect" thesis; Roblox docs: fixed sequences that restrict choice drive drop-off).
    AUTO_PAY is a guess: tested at 0.35 / 0.55 / 0.75.
  * a watched stretch with no control drags after DRAG_AFTER s (cutscene = 0 actions a minute; long forced intros named as a
    top reason to leave).
  * tapping needs the kid to know he should: some kids don't tap at first; a pulsing REP + hand after 3 s finds them.
  * a CHOICE (pick your next muscle) is a NEW thing, worth more than being taken there.
A heuristic model, not real kids. The real check is the onboarding funnel after the update. Run: python tutorialsim_gymarc.py
"""
import random, math, statistics as st
P = dict(watch=0.1, tap=0.03, drag=0.4, rew=6.0)   # from impatientkid_gymarc.py calibration
DRAG_AFTER = 6.0
AUTO_RATE = 0.03   # boredom per s while the game plays itself; calibrated with calib_tutorial.py (live: ~79% past 60 s, ~49% past 3 min; funnel says ~85% / ~62%, the old sim 90/54)

def timeline(V):
    """(t, kind, length/size, label, own) kinds: watch / tap / auto (things happen by themselves) / reward / stall"""
    ev = []; t = 0.6; own = V.get("own", False)
    intro = V.get("intro", 18.1)
    ev.append((t, "watch", intro, "intro cutscene", False)); t += intro
    if V.get("gift"): ev.append((t + 0.5, "reward", 3.0, "FREE GIFT", True))
    walk = V.get("walk", 3.0)
    ev.append((t, "watch", walk, "auto-walk to the bench", False)); t += walk
    rep = V.get("rep_s", 1.3)              # seconds per rep: auto ~1.3 s; a kid tapping ~0.6 s
    juice = V.get("juice", 1.0)            # reward size per rep milestone (visible growth, numbers, combo)
    k = "tap" if own else "auto"
    ev.append((t + 0.6, "reward", 2.5, "first rep: big moment + coins", own))
    ev.append((t, k, 8 * rep, "bench reps", own)); t += 8 * rep
    for m in (2, 4, 6): ev.append((t - (8 - m) * rep, "reward", 0.6 * juice, "rep milestone", own))
    ev.append((t, "reward", 1.5, "+100 coins, 25% goal", own))
    names = ("squat", "crunch", "pull-up")
    for i, name in enumerate(names):
        if V.get("choice") and i == 0:
            ev.append((t, "tap", 2.5, "PICK YOUR NEXT MUSCLE (3 glowing machines)", True))
            ev.append((t + 2.5, "reward", 2.0, "your own pick", True)); t += 2.5
        ev.append((t, "watch", V.get("move", 4.5), f"leave + walk to {name}", False)); t += V.get("move", 4.5)
        ev.append((t + 0.5, "reward", 1.2, f"new machine: {name}", own or bool(V.get("choice"))))
        ev.append((t, k, 5 * rep, f"{name} reps", own))
        if juice > 1: ev.append((t + 3 * rep, "reward", 0.6 * juice, "you can SEE the muscle grow", own))
        t += 5 * rep
        ev.append((t, "reward", 0.8, "goal % up / personal record", own))
    fill = V.get("fill_to_ready", max(0, 96 - t - 0.6) * (rep / 1.3))
    ev.append((t, k, fill, "GO TRAIN reps to READY", own)); t += fill
    ev.append((t, "reward", 2.0, "GROWTH SPURT READY", own)); t += V.get("ready_gap", 6)
    grow = V.get("grow", 6.0)
    ev.append((t, "watch", grow, "GROW transform", False))
    ev.append((t + grow - 1, "reward", 4.0, "you grew TALLER", bool(V.get("grow_tap")) or own)); t += grow
    ev.append((t, "watch", V.get("benny_story", 5.0), "Benny story shot", False)); t += V.get("benny_story", 5.0)
    ev.append((t, "watch", 2.5, "walked to Benny's table", False)); t += 2.5
    if V.get("benny_auto_card"):
        ev.append((t, "watch", 1.5, "Benny's card opens", False)); t += 1.5
    else:
        ev.append((t, "stall", "find", "standing at Benny's table, nothing opens", False))
    ev.append(("S+0", "watch", 3, "Benny's card", False))
    wrestle_own = bool(V.get("wrestle_tap"))
    ev.append(("S+3", "tap" if wrestle_own else "auto", 8 if wrestle_own else 15, "arm wrestle Benny", wrestle_own))
    ev.append(("S+11" if wrestle_own else "S+18", "reward", 4.0, "BEAT BENNY: Beach Gym + 900 coins", wrestle_own))
    ev.append(("S+13" if wrestle_own else "S+20", "watch", V.get("coral", 8.0), "Coral story + walk to beach", False))
    c = 13 + V.get("coral", 8.0) if wrestle_own else 20 + V.get("coral", 8.0)
    ev.append((f"S+{c}", "reward", 2.0, "new gym: the beach", False))
    ev.append((f"S+{c}", k, 300, "beach reps", own))
    for j in range(1, 12): ev.append((f"S+{c + j * 12}", "reward", 0.8 * juice, "beach milestone", own))
    return ev

def kid_run(V, rng, patience, auto_pay):
    ev = timeline(V)
    stall = [e for e in ev if e[1] == "stall"]
    if stall:
        find = 0.0
        while find < 400:
            find += 1
            if rng.random() < V.get("find_rate", 0.15): break
        s0 = stall[0][0] + find
        ev = [e for e in ev if e[1] != "stall"] + [(stall[0][0], "stall", find, stall[0][3], False)]
    else:
        s0 = max(e[0] + (e[2] if e[1] in ("watch", "tap", "auto") else 0) for e in ev if not isinstance(e[0], str))
    ev = [((s0 + float(e[0][2:])) if isinstance(e[0], str) else e[0], *e[1:]) for e in ev]
    # a kid who must tap may not realise it at first: hand hint after HINT s, or he works it out
    knows = rng.random() < 0.7
    hint = V.get("hint", 99.0)
    bored = 0.0; had = 0.0; tick = 0.5; t = 0.0; ri = 0; watched = 0.0; deadest = 0; dead = 0
    rewards = sorted([e for e in ev if e[1] == "reward"], key=lambda e: e[0])
    first_tap = next((e[0] for e in sorted(ev, key=lambda e: e[0]) if e[1] == "tap"), None)
    learned_at = None
    while t < 300:
        kind = None
        for e in ev:
            if e[1] in ("watch", "tap", "auto", "stall") and e[0] <= t < e[0] + e[2]: kind = e[1]
        if kind == "tap" and not knows:
            if learned_at is None: learned_at = t + min(hint, rng.uniform(2, 15))
            if t < learned_at: kind = "stall"
            else: knows = True
        watched = watched + tick if kind == "watch" else 0.0
        rate = {"watch": P["watch"], "auto": P["watch"], "tap": P["tap"], "stall": 1.0, None: 1.0}[kind]
        if kind == "watch" and watched > DRAG_AFTER: rate = P["drag"]
        if kind == "auto": rate = AUTO_RATE
        bored += rate * tick
        dead = dead + tick if kind in ("stall", None) else 0; deadest = max(deadest, dead)
        while ri < len(rewards) and rewards[ri][0] <= t:
            r = rewards[ri]
            if rng.random() < 0.85:
                pay = r[2] * P["rew"] / (1 + 0.15 * had) * (1.0 if r[4] else auto_pay)
                bored = max(0.0, bored - pay); had += 1
            ri += 1
        if bored > patience: return t, deadest
        t += tick
    return 300, deadest

def run(V, n=2500, med=11, seed=5, auto_pay=0.65):
    rng = random.Random(seed); stays = {k: 0 for k in (15, 30, 60, 120, 180, 300)}; dead = []
    for _ in range(n):
        p = rng.lognormvariate(math.log(med), 0.45)
        q, d = kid_run(V, rng, p, auto_pay); dead.append(d)
        for k in stays:
            if q >= k: stays[k] += 1
    return {k: 100 * v / n for k, v in stays.items()}, st.median(dead)

PHASE2B = dict(intro=8, benny_auto_card=True, ready_gap=1.5)   # already in the Christmas brief
VERS = [
    ("A  live v1914 (plays itself, 18 s intro)", {}),
    ("B  Phase 2b only (8 s intro, Benny card opens, GROW on READY)", dict(PHASE2B)),
    ("C  + YOUR taps lift: no auto reps / auto pump in the tutorial (pump fills from your reps)", dict(PHASE2B, own=True, rep_s=0.7)),
    ("D  + pulsing REP + hand after 3 s of no tap", dict(PHASE2B, own=True, rep_s=0.7, hint=3)),
    ("E  + juice: every 2nd rep the muscle visibly swells, +EXP pops, combo x5", dict(PHASE2B, own=True, rep_s=0.7, hint=3, juice=1.8)),
    ("F  + after the bench: PICK your next muscle (3 glowing machines), dash 2 s", dict(PHASE2B, own=True, rep_s=0.7, hint=3, juice=1.8, choice=True, move=2.0, walk=2.0)),
    ("G  + YOU tap GROW, 4 s transform; Benny story 4 s (3-word caption); Coral 4 s; all skippable after 1 s", dict(PHASE2B, own=True, rep_s=0.7, hint=3, juice=1.8, choice=True, move=2.0, walk=2.0, grow=4, grow_tap=True, benny_story=4, coral=4)),
    ("H  + Benny: YOU tap to win (winnable at 2 taps/s; Benny tires if you're slow)", dict(PHASE2B, own=True, rep_s=0.7, hint=3, juice=1.8, choice=True, move=2.0, walk=2.0, grow=4, grow_tap=True, benny_story=4, coral=4, wrestle_tap=True)),
    ("I  + intro 8 s -> 5 s, one shot: you, the gym, BENNY's taunt (skippable after 1 s)", dict(PHASE2B, own=True, rep_s=0.7, hint=3, juice=1.8, choice=True, move=2.0, walk=2.0, grow=4, grow_tap=True, benny_story=4, coral=4, wrestle_tap=True, intro=5)),
]

if __name__ == "__main__":
    print(f"{'version (cumulative)':96} {'15s':>5} {'30s':>5} {'60s':>5} {'2m':>5} {'3m':>5} {'5m':>5}  dead")
    for name, V in VERS:
        s, d = run(V)
        print(f"{name:96} " + " ".join(f"{s[k]:4.0f}%" for k in (15, 30, 60, 120, 180, 300)) + f"  {d:3.0f} s")
    print("\nsensitivity: how much does a reward that happened BY ITSELF count (AUTO_PAY)?  (3 min / 5 min)")
    for ap in (0.35, 0.65, 1.0):
        a, _ = run(VERS[0][1], auto_pay=ap); b, _ = run(VERS[1][1], auto_pay=ap); z, _ = run(VERS[-1][1], auto_pay=ap)
        print(f"  AUTO_PAY {ap:.2f}: live {a[180]:3.0f}/{a[300]:3.0f}%   Phase 2b only {b[180]:3.0f}/{b[300]:3.0f}%   new tutorial {z[180]:3.0f}/{z[300]:3.0f}%")
    print("sensitivity: patience median (new tutorial vs live), 3 min / 5 min")
    for med in (7, 11, 16):
        a, _ = run(VERS[0][1], med=med); z, _ = run(VERS[-1][1], med=med)
        print(f"  patience {med:2d} s: live {a[180]:3.0f}/{a[300]:3.0f}%   new {z[180]:3.0f}/{z[300]:3.0f}%")
    print("check: kids who need the hint (30% don't tap at first) - D without the hint:")
    s, _ = run(dict(VERS[3][1], hint=99)); print("  C-without-hint: " + " ".join(f"{s[k]:4.0f}%" for k in (15, 30, 60, 120, 180, 300)))
