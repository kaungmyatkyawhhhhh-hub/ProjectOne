"""GYM ARC long-session simulation: average session length, incl. very impatient kids (26 Nov 2026, 06:00 MMT).
Owner: "we need very long average session even with the very impatient kids".
Minutes 0-10 = tenmin_gymarc.py (live or the LEAN plan). After Growth Spurt 3 the LIVE structure, read from Studio config:
  * Growth Spurts every ~5 min of normal play (Config/GrowthSpurts Targets {2,5,5,5,5,5}), 6 spurts, then Body Alters
    (5 per tier) - each spurt = GROW + bigger body + gains bonus;
  * bosses: Coral at GS3 (opens the Pro Gym), Dante at GS5 (opens the Powerlifting Gym);
  * THE RUNWAY posing show every 300 s (Config/PosingComp Interval), open after Growth Spurt 1;
  * PLAYTIME GIFTS at 3, 6, 10, 15, 20, 25, 30, 40, 60 min (Config/Playtime; rolls at 20 and 60).
Session capped at 60 min (Roblox counts at most 60 min of playtime per user per day). Calibrated: live players who pass
3 min play ~18 min on average (Creator Hub D1 playtime 11.8 min). A heuristic model, not real kids.
Run: python session_gymarc.py
"""
import random, math, statistics as st
import tenmin_gymarc as TM
END = 60 * 60
TM.END = END
TM.HAB = 0.11   # calibrated with calib_session.py: live survivors of 3 min average ~19 min (target ~18; D1 playtime 11.8 min)

def tail(V, t0):
    """events after Growth Spurt 3 (t0)"""
    ev = []
    def R(t, s, l, own=True, new=False):
        if t < END: ev.append((t, "reward", s, l, own, new))
    gs = V.get("gs_s", 300); t = t0; n = 3
    ev.append((t0, "tap", END - t0, "later play", True, False))
    if V.get("afk_spot"): pass
    while t < END:
        t += gs; n += 1
        big = n in (5,) or (n > 6)
        R(t, 3.0 if n <= 6 else 3.5, f"GROWTH SPURT {n}" if n <= 6 else f"BODY ALTER {n-6}", new=True)
        if n == 5: R(t + 20, 3.5, "DANTE beaten: POWERLIFTING GYM", new=True)
        if V.get("spurt_steps_late"):
            for j in (0.25, 0.5, 0.75): R(t - gs + gs * j, 1.1, "body changes: 25/50/75% step")
        else:
            for j in range(1, 5): R(t - gs + gs * j / 5, 0.6, "repeat (title, coach level, weight)")
    # posing shows (THE RUNWAY), live every 300 s from server start; a new player joins at a random point of the cycle
    if V.get("shows", True):
        off = V.get("show_offset", 150)
        k = 0
        while True:
            st_ = 120 + off + 300 * k; k += 1
            if st_ >= END: break
            if st_ < t0 and not V.get("shows_early"): continue
            joins = V.get("show_join", 0.35)          # live: an invite card on the side; many miss it
            R(st_, 2.5 if k <= 2 else 1.5, "THE RUNWAY show (joined)", new=(k <= 1)) if random.random() < joins else None
    for gt in V.get("gifts_late", (900, 1200, 1500, 1800, 2400, 3600)):
        if gt > t0: R(gt, 1.5 * (2.0 if gt in V.get("roll_gifts", (1200, 3600)) else 1.0), "PLAYTIME GIFT", new=gt in V.get("roll_gifts", (1200, 3600)))
    if V.get("rolls_every"):
        r = t0 + V["rolls_every"]
        while r < END: R(r, 2.2, "TRAINER ROLL with earned coins (a new face 1 in 3)", new=random.random() < 0.33); r += V["rolls_every"]
    if V.get("quests"):
        for q in V["quests"]: R(q, 1.5, "DAILY QUEST done: chest", new=True)
    if V.get("events_every"):
        e = t0 + 120
        while e < END: R(e, 2.0, "SERVER EVENT: Protein Drop / Gift Rush 3 min x2", new=True); e += V["events_every"]
    return ev

def full_timeline(V):
    base = TM.timeline(V["first10"])
    # cut the tenmin tail ("later play" + its loop rewards) at its GS3 time and replace it with the live structure
    gs3 = [e for e in base if e[1] == "reward" and "GS3" in e[3]]
    t0 = gs3[0][0] if gs3 else 600
    kept = [e for e in base if not (e[3] in ("later play", "next GROWTH SPURT", "repeat reward")) and not (e[1] == "reward" and "PLAYTIME GIFT" in e[3] and e[0] > t0)]
    return kept + tail(V, t0)

def kid(V, rng, patience):
    random.seed(rng.random())
    ev = full_timeline(V)
    spans = sorted([e for e in ev if e[1] != "reward"], key=lambda e: e[0])
    rewards = sorted([e for e in ev if e[1] == "reward"], key=lambda e: e[0])
    bored = 0.0; had = 0.0; t = 0.0; ri = 0; watched = 0.0
    while t < END:
        kind = None
        for e in spans:
            if e[0] <= t < e[0] + e[2]: kind = e[1]
        if kind == "tour" and bored > 0.6 * patience:
            cut = [e for e in spans if e[1] == "tour" and e[0] <= t < e[0] + e[2]]
            spans = sorted([e for e in spans if e not in cut] + [(t, "tap", c[0] + c[2] - t, "back", True, False) for c in cut], key=lambda e: e[0]); kind = "tap"
        watched = watched + 1 if kind == "watch" else 0
        rate = {"watch": TM.P["watch"], "auto": TM.P["auto"], "tap": TM.P["tap"], "tour": 0.2, "stall": 1.0, None: 1.0}[kind]
        if kind == "watch" and watched > 6: rate = TM.P["drag"]
        if V["first10"].get("dusk", True) and 540 <= t < 900 and rng.random() < 0.3: rate *= 1.25
        bored += rate
        while ri < len(rewards) and rewards[ri][0] <= t:
            r = rewards[ri]; ri += 1
            if rng.random() > 0.9: continue
            size = r[2] * (TM.NEW_BONUS if r[5] else 1.0) * (1.0 if r[4] else 0.65)
            bored = max(0.0, bored - size * TM.P["rew"] / (1 + TM.HAB * had)); had += 1
        if bored > patience:
            # AFK option: a kid about to leave may park at the AFK spot if it pays and he knows it (counts as play time)
            if V.get("afk_spot") and rng.random() < V.get("afk_share", 0.25):
                return min(END, t + rng.uniform(5, 25) * 60), True
            return t, False
        t += 1
    return END, False

def run(V, n=400, med=11, seed=11, cond=False):
    rng = random.Random(seed); qs = []
    for _ in range(n):
        q, afk = kid(V, rng, rng.lognormvariate(math.log(med), 0.45)); qs.append(q)
    if cond:
        s = [q for q in qs if q >= 180] or [0]; return st.mean(s) / 60
    return {m: 100 * sum(q >= m * 60 for q in qs) / n for m in (3, 10, 20, 30, 45)}, st.mean(qs) / 60

LIVE10 = TM.PLAN[0][1]           # minutes 0-10 after the new first 3 minutes, 3-10 as live
LEAN10 = TM.LEAN[1]
VERS = [
  ("A  minutes 3-60 as live (only the first 3 min fixed)", dict(first10=LIVE10)),
  ("B  + the 10-minute plan (Phase 2e)", dict(first10=LEAN10)),
  ("C  + every Growth Spurt bar pays 3 visible steps (25/50/75%: the body changes, a coin pop)", dict(first10=LEAN10, spurt_steps_late=True)),
  ("D  + THE RUNWAY: new players get a big JOIN card + auto-walk, 90% join (was ~35%)", dict(first10=LEAN10, spurt_steps_late=True, show_join=0.9)),
  ("E  + shows every 150 s for servers with new players (half the wait)", dict(first10=LEAN10, spurt_steps_late=True, show_join=0.9, show_offset=60)),
  ("F  + a trainer roll every ~4 min from earned coins (roll price tuned to first-session coins)", dict(first10=LEAN10, spurt_steps_late=True, show_join=0.9, rolls_every=240)),
  ("G  + 3 first-day quests that finish at ~12, ~18, ~25 min (each a chest)", dict(first10=LEAN10, spurt_steps_late=True, show_join=0.9, rolls_every=240, quests=(720, 1080, 1500))),
  ("H  + playtime gifts every 5 min to 60 min (live: 15, 20, 25, 30, 40, 60), rolls at 20/40/60", dict(first10=LEAN10, spurt_steps_late=True, show_join=0.9, rolls_every=240, quests=(720, 1080, 1500),
        gifts_late=tuple(range(900, 3601, 300)), roll_gifts=(1200, 2400, 3600))),
  ("I  + a server event every 15 min (3-min x2 gains 'PROTEIN DROP', the whole server)", dict(first10=LEAN10, spurt_steps_late=True, show_join=0.9, rolls_every=240, quests=(720, 1080, 1500),
        gifts_late=tuple(range(900, 3601, 300)), roll_gifts=(1200, 2400, 3600), events_every=900)),
  ("J  + the AFK gift chair (Phase 2c): a bored kid may park there instead of leaving", dict(first10=LEAN10, spurt_steps_late=True, show_join=0.9, rolls_every=240, quests=(720, 1080, 1500),
        gifts_late=tuple(range(900, 3601, 300)), roll_gifts=(1200, 2400, 3600), events_every=900, afk_spot=True)),
]

if __name__ == "__main__" and "final" not in __import__("sys").argv:
    import sys
    pats = (5, 7, 11)
    print(f"{'version (cumulative)':100} " + "  ".join(f"mean@{p}s" for p in pats) + "   [patience 5 s: 10m 20m 30m 45m]")
    for name, V in VERS:
        means = []; five = None
        for p in pats:
            s, m = run(V, med=p); means.append(m)
            if p == 5: five = s
        print(f"{name:100} " + "  ".join(f"{m:6.1f}  " for m in means) + "   " + " ".join(f"{five[k]:4.0f}%" for k in (10, 20, 30, 45)))

FINAL = dict(first10=LEAN10, spurt_steps_late=True, show_join=0.9, rolls_every=240,
             gifts_late=tuple(range(900, 3601, 300)), roll_gifts=(1200, 2400, 3600), events_every=900)
FINAL_AFK = dict(FINAL, afk_spot=True)
if __name__ == "__main__" and "final" in __import__("sys").argv:
    for lab, V in (("PLAN (B C D F H I, no E/G)", FINAL), ("PLAN + AFK chair (J)", FINAL_AFK)):
        for p in (5, 7, 11, 16):
            s, m = run(V, med=p)
            print(f"{lab:28} patience {p:2d} s: mean {m:5.1f} min | still playing 10m {s[10]:3.0f}% 20m {s[20]:3.0f}% 30m {s[30]:3.0f}% 45m {s[45]:3.0f}%")
