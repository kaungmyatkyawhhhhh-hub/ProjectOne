"""GYM ARC first-session simulation: what keeps a new player to 10 minutes (26 Nov 2026, 05:30 MMT).
Minutes 3-10 MEASURED in Studio on live v1914 (26 Nov 05:00, a fresh player, UI logged every second; reps by the tutorial,
then the AUTO REP pass as a tapping kid):
  1:42 GROW (GS1) -> 1:43 Benny story -> stands at his table until E (2:00-2:07) -> card, match (won with no taps) 2:12-2:18 ->
  VICTORY + result card -> 2:28 Coral story 5 s -> GO TO BEACH -> 2:44 Coral meets you (4 s) -> 2:50 BEACH GRIND:
  chest 15, core 15, legs 20, back 20, then fill GS2 = 70+ reps, 2:50-5:20, only repeats (titles, coach LV up, a quest),
  OUT OF STAMINA at 4:25 -> 5:20 GS2 READY -> GROW 6 s -> free trainer roll (2 rolls) -> PLAYTIME GIFT 1/9 (first one, 5:33)
  -> a forced QUESTS TOUR (3 tap-to-continue pages; the big CLAIM button doesn't react during it) ~50 s -> "Heavier weight
  open! Tap +" dialog -> STARTER PACK R$29 sticky -> free play: GS3 0%, needs CHEST + SHOULDERS, but the kid sits on the
  machine he's on (Bicep Curl): 16% then nothing counts; "out of stamina" + a R$5/R$49 refill OFFER (8:45);
  PLAYTIME GIFT 3/9 at 9:53; next goal "Coral at Growth Spurt 3" / Pro Gym; the sky turns to dusk at ~9 min on a new server.
Mean playtime target (calibration): Creator Hub D1 playtime 11.8 min a day per new user.
Same boredom model as impatientkid / tutorialsim. A heuristic model, not real kids. Run: python tenmin_gymarc.py
"""
import random, math, statistics as st
P = dict(watch=0.1, tap=0.03, drag=0.4, rew=6.0, auto=0.03)
HAB = 0.09        # repeats wear off; calibrated (calib_tenmin.py) so live survivors of 3 min average ~18 min (D1 playtime 11.8 min)
NEW_BONUS = 2.0   # a NEW thing (first of its kind) is worth this much more than a repeat
END = 30 * 60

def timeline(V):
    """(t, kind, len/size, label, own, new) ; kinds watch / tap / auto / stall / reward"""
    ev = []
    def W(t, d, l): ev.append((t, "watch", d, l, False, False))
    def T(t, d, l, own=True): ev.append((t, "tap" if own else "auto", d, l, own, False))
    def S(t, d, l): ev.append((t, "stall", d, l, False, False))
    def R(t, s, l, own=True, new=False): ev.append((t, "reward", s, l, own, new))
    # 0 - 3 min: the redesigned tutorial (Phase 2b + 2d, tutorialsim version L), compressed to its events
    W(0.6, 5, "intro"); T(5.6, 30, "tutorial lifts"); R(8, 2.5, "first rep", new=True)
    for x in range(10, 36, 3): R(x, 0.6, "rep swell")
    R(14, 2.0, "picked a muscle", new=True); R(20, 1.2, "new machine", new=True); R(26, 1.2, "new machine", new=True)
    T(36, 30, "GO TRAIN to READY"); [R(36 + 7 * j, 1.0, "bar step") for j in range(1, 5)]
    R(66, 2.0, "READY", new=True); W(67.5, 4, "GROW"); R(70.5, 4.0, "you grew TALLER", new=True)
    T(71.5, 1.5, "Benny challenge"); W(73, 1.5, "dash"); T(74.5, 8, "arm wrestle Benny"); R(82.5, 4.0, "BEAT BENNY", new=True)
    W(84.5, 4, "Coral"); R(88.5, 2.0, "the beach", new=True)
    t = 88.5
    # 3 - 10 min
    grind = V.get("grind_reps", 70); rep = 2.1 if V.get("stamina_wall", True) else 1.6   # measured: 70+ reps in ~150 s incl. moves + stamina
    g = grind * rep
    T(t, g, "beach grind to GS2", own=True)
    marks = V.get("beach_marks", 4)
    for j in range(1, marks + 1): R(t + g * j / (marks + 1), 1.0, "group done", new=(j == 1))
    for j in range(1, int(g // 30) + 1): R(t + 30 * j, 0.5, "title / coach level")
    if V.get("stamina_wall", True): S(t + g * 0.6, 5, "OUT OF STAMINA (wait)")
    t += g
    R(t, 2.0, "GS2 READY"); W(t + 1, 4 if V.get("short_grow") else 6, "GROW 2"); t += 5 if V.get("short_grow") else 7
    R(t, 4.0, "you grew TALLER (GS2)", new=True)
    W(t, 4, "free trainer roll"); R(t + 4, 3.5, "NEW TRAINER", new=True); t += 6
    if V.get("tour", True):
        ev.append((t, "tour", 50, "QUESTS TOUR (3 pages, CLAIM doesn't work; SKIP exists)", False, False)); t += 50
    else:
        T(t, 3, "quest claimed (toast)"); R(t + 3, 1.5, "+750 daily claim", new=True); t += 3
    if V.get("offers_early", True):
        W(t, 3, "STARTER PACK offer"); t += 3
    # GS3 stretch
    if V.get("goto_needed"):   # GO TRAIN keeps taking you to what the spurt needs
        gs3 = V.get("gs3_s", 300) * (0.5 if V.get("boost_exp") else 1.0)
        T(t, gs3, "GS3 training (guided)")
        for j in range(1, int(gs3 // 25) + 1): R(t + 25 * j, 0.9, "bar step / weight unlock")
    else:                      # live: the kid trains what he's on; it stops counting at ~16%
        T(t, 40, "GS3 on the wrong muscle"); [R(t + 8 * j, 0.7, "weight unlock") for j in range(1, 5)]
        t += 40
        T(t, 25, "muscle maxed: reps still pay EXP, but the GROWTH SPURT bar doesn't move")
        t += 25
        if V.get("offers_early", True): W(t, 4, "OUT OF STAMINA + R$5 / R$49 offer"); t += 4
        gs3 = V.get("gs3_s", 300) * 1.4
        T(t, gs3, "GS3 (finds GO TRAIN later)")
        for j in range(1, int(gs3 // 40) + 1): R(t + 40 * j, 0.7, "weight unlock / coach level")
    if V.get("stamina_wall", True): S(t + gs3 * 0.5, 6, "OUT OF STAMINA (wait)")
    t += gs3
    R(t, 2.0, "GS3 READY"); W(t + 1, 6, "GROW 3"); t += 7; R(t, 4.0, "GS3: the PRO GYM opens", new=True)
    if V.get("new_area_trip"): W(t, 3, "dash to the PRO GYM"); R(t + 3, 3.0, "a new gym: new machines", new=True); t += 3
    # playtime gifts
    for gt in V.get("gifts", (333, 354, 593, 893, 1193, 1493)):
        R(gt, V.get("gift_size", 1.5) * (2.2 if gt == V.get("big_gift_at") else 1.0), "PLAYTIME GIFT", new=(gt == V.get("big_gift_at")))
    # the session ladder: one new thing every ~70 s (the plan)
    for at, size, lab in V.get("ladder", ()):
        R(at, size, lab, new=True)
    # dusk
    if V.get("dusk", True): S(540, 0.0, "dusk")  # marker only (handled as a boredom rate change)
    # after GS3: the long loop (Hank, more spurts), a GS every ~5 min, repeats in between
    loop = V.get("loop_s", 300)
    T(t, END - t, "later play")
    k = 0
    while t + loop * (k + 1) < END:
        k += 1; R(t + loop * k, 3.0, "next GROWTH SPURT", new=(k == 1))
        for j in range(1, 6): R(t + loop * (k - 1) + loop * j / 6, 0.6, "repeat reward")
    return ev

def kid(V, rng, patience):
    ev = timeline(V)
    spans = sorted([e for e in ev if e[1] != "reward"], key=lambda e: e[0])
    rewards = sorted([e for e in ev if e[1] == "reward"], key=lambda e: e[0])
    bored = 0.0; had = 0.0; t = 0.0; tick = 1.0; ri = 0; watched = 0.0; seen = set()
    dusk = V.get("dusk", True)
    while t < END:
        kind = None
        for e in spans:
            if e[0] <= t < e[0] + e[2]: kind = e[1]
        watched = watched + tick if kind == "watch" else 0.0
        if kind == "tour" and bored > 0.6 * patience:   # a bored kid taps SKIP
            cut = [e for e in spans if e[1] == "tour" and e[0] <= t < e[0] + e[2]]
            spans = [e for e in spans if e not in cut] + [(t, "tap", c[0] + c[2] - t, "back to lifting", True, False) for c in cut]
            spans.sort(key=lambda e: e[0]); kind = "tap"
        rate = {"watch": P["watch"], "auto": P["auto"], "tap": P["tap"], "tour": 0.2, "stall": 1.0, None: 1.0}[kind]
        if kind == "watch" and watched > 6: rate = P["drag"]
        if dusk and 540 <= t < 900 and rng.random() < 0.3 / 1:  # ~30% of new players' servers are at dusk/night then
            rate *= 1.0 + V.get("dark_pen", 0.25)
        bored += rate * tick
        while ri < len(rewards) and rewards[ri][0] <= t:
            r = rewards[ri]; ri += 1
            if rng.random() > 0.9: continue
            size = r[2] * (NEW_BONUS if r[5] else 1.0) * (1.0 if r[4] else 0.65)
            bored = max(0.0, bored - size * P["rew"] / (1 + HAB * had)); had += 1
        if bored > patience: return t
        t += tick
    return END

def run(V, n=1500, med=11, seed=7, cond=False):
    rng = random.Random(seed); qs = []
    for _ in range(n):
        qs.append(kid(V, rng, rng.lognormvariate(math.log(med), 0.45)))
    pct = lambda s: 100 * sum(q >= s for q in qs) / n
    if cond:
        surv = [q for q in qs if q >= 180] or [0]
        return st.mean(surv) / 60, 100 * sum(q >= 600 for q in surv) / max(1, len(surv))
    return {m: pct(m * 60) for m in (3, 5, 7, 10, 15)}, st.mean(min(q, 1800) for q in qs) / 60

LIVE = dict()
PLAN = [
  ("A  live 3-10 min after the new first 3 min (Phase 2b + 2d)", dict()),
  ("B  + beach grind 70 -> 40 reps (10 a group), GS2 at ~3:30", dict(grind_reps=40)),
  ("C  + no QUESTS TOUR: daily claim is a one-tap toast; CLAIM works", dict(grind_reps=40, tour=False)),
  ("D  + no paid offers before Growth Spurt 3 (starter pack, R$ refill) ", dict(grind_reps=40, tour=False, offers_early=False)),
  ("E  + GO TRAIN stays on in the first session: always to what the spurt needs ('FULL! next: CHEST')", dict(grind_reps=40, tour=False, offers_early=False, goto_needed=True)),
  ("F  + first session: no stamina wall (stamina refills while you walk; first empty = a free shake)", dict(grind_reps=40, tour=False, offers_early=False, goto_needed=True, stamina_wall=False)),
  ("G  + NEW PLAYER x2 EXP for 15 min (GS3 ~2.5 min after GS2)", dict(grind_reps=40, tour=False, offers_early=False, goto_needed=True, stamina_wall=False, boost_exp=True)),
  ("H  + GS3 = a trip: dash to the PRO GYM, new machines", dict(grind_reps=40, tour=False, offers_early=False, goto_needed=True, stamina_wall=False, boost_exp=True, new_area_trip=True)),
  ("I  + playtime gifts from minute 2, every 2 min, the 10-min one BIG (free trainer roll), chip counts down", dict(grind_reps=40, tour=False, offers_early=False, goto_needed=True, stamina_wall=False, boost_exp=True, new_area_trip=True, gifts=(120, 240, 360, 480, 600, 900, 1200, 1500), big_gift_at=600)),
  ("J  + a SESSION LADDER: a new thing every ~70 s (shake, plate tier, aura, posing show, Coral 2)", dict(grind_reps=40, tour=False, offers_early=False, goto_needed=True, stamina_wall=False, boost_exp=True, new_area_trip=True, gifts=(120, 240, 360, 480, 600, 900, 1200, 1500), big_gift_at=600,
        ladder=((250, 1.5, "first ENERGY SHAKE (free, 2x stamina)"), (320, 2.0, "BRONZE PLATES: heavier weight + new look"), (390, 2.5, "POSING SHOW invite: walk the runway, easy podium"), (460, 2.0, "first AURA from the show"), (530, 3.0, "CORAL rematch (tap fight)")))),
  ("K  + no dusk in a new player's first 15 min (his sky stays day; or night is bright)", dict(grind_reps=40, tour=False, offers_early=False, goto_needed=True, stamina_wall=False, boost_exp=True, new_area_trip=True, gifts=(120, 240, 360, 480, 600, 900, 1200, 1500), big_gift_at=600,
        ladder=((250, 1.5, "shake"), (320, 2.0, "plates"), (390, 2.5, "posing show"), (460, 2.0, "aura"), (530, 3.0, "Coral rematch")), dusk=False)),
]

LEAN = ("L  LEAN PLAN = B + C + D + E + F + I + K (no x2 EXP, no ladder, no GS3 trip)", dict(grind_reps=40, tour=False, offers_early=False, goto_needed=True, stamina_wall=False,
        gifts=(120, 240, 360, 480, 600, 900, 1200, 1500), big_gift_at=600, dusk=False))
PLAN.append(LEAN)

def live_full():   # the full LIVE game incl. its first 3 minutes, for calibration (mean playtime ~11.8 min)
    return dict()

if __name__ == "__main__":
    print(f"{'version (cumulative)':104} {'3m':>5} {'5m':>5} {'7m':>5} {'10m':>5} {'15m':>5}  mean")
    for name, V in PLAN:
        s, m = run(V)
        print(f"{name:104} " + " ".join(f"{s[k]:4.0f}%" for k in (3, 5, 7, 10, 15)) + f"  {m:4.1f} min")
    print("\nsensitivity, LEAN plan (L) vs A:")
    for med in (5, 7, 11, 16):
        a, am = run(PLAN[0][1], med=med); z, zm = run(PLAN[-1][1], med=med)
        print(f"  patience {med:2d} s: A 10 min {a[10]:3.0f}% (mean {am:4.1f})   LEAN 10 min {z[10]:3.0f}% 15 min {z[15]:3.0f}% (mean {zm:4.1f})")
