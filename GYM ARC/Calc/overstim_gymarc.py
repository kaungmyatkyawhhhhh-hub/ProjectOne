"""GYM ARC overstimulated-kid simulation (owner's method), first 5 minutes of a NEW player, build v1914.
Every on-screen element below was MEASURED in the 25 Nov 2026 Studio play-through (UI logged every 0.5 s, screenshots):
name, time on screen, region, size weight, KEY (must be noticed) and words to read.
Weights: modal/full card 2, big centre card 1.5, banner 1, toast/side card 0.5, side tile/badge 0.25, flash 1 (0.3 s).
Kid: attention slots by age (7-9 y = 3, 10-12 y = 3.5), reading speed ~1.5 words/s at 7, ~3 at 10 (+-30%).
Tells: OVERLOAD (sum weight > slots for >= 0.5 s), MISSED KEY (covered/collided, shown during overload, or gone before
read), COLLISION (two elements in one region). A model with estimated weights, not real kids. Run: python overstim_gymarc.py
"""
import random, statistics as st

def elements(V):
    E = []  # (start, end, name, region, weight, key, words)
    def add(a, b, name, reg, w, key, words):
        if V.get("min_read") and key and reg in ("top", "bottom"): b = max(b, a + words / 1.5 + 0.5)
        E.append((a, b, name, reg, w, key, words))
    # 0-30 s: menu, intro cutscene (full screen, letterbox captions)
    add(0.6, 18.7, "intro cutscene", "full", 2.0, True, 18 if V.get("intro_short") is None else 8)
    # tutorial band (top centre) per step; it re-shows every 12 s for ~3 s on long steps
    add(20.0, 24.0, "band: Let's lift! Taking you to the Flat Bench", "top", 1.0, True, 8)
    add(20.5, 24.5, "coach dialog: Welcome! Lift to fill your GROWTH SPURT bar...", "bottom", 1.5, True, 15)
    add(24.0, 34.0, "machine HUD (REP, stamina, weight panel)", "right", 0.5, False, 0)
    add(25.0, 34.5, "band: Every rep fills your GROWTH SPURT bar", "top", 1.0, True, 8)
    add(25.5, 26.5, "first-rep big moment flash", "centre", 1.0, False, 0)
    add(34.0, 96.0, "machine HUD", "right", 0.5, False, 0)
    for t, txt in ((36, "Great set! Now let's train your LEGS"), (48, "Legs are growing too! Do 5 reps"),
                   (58, "Strong legs! Now let's train your CORE"), (66, "Your CORE is growing!"),
                   (74, "Last one: BACK!"), (84, "Fill your GROWTH SPURT bar to GROW TALLER!")):
        add(t, t + 4.0, "band: " + txt, "top", 1.0, True, len(txt.split()))
    # the personal-record banner lands on the same top strip as the tutorial band (seen at 81-84 s)
    pr = V.get("pr_side")
    for t in (44, 60, 81):
        add(t + 0.2, t + 3.0, "NEW PERSONAL RECORD banner", "side" if pr else "top", 0.5 if pr else 1.0, False, 3)
    add(70, 73, "Growth Spurt 50%/75% coins toast", "side", 0.5, False, 4)
    # invite card from 89 s, bottom centre, stays (it was still on screen at 205 s)
    if not V.get("invite_later"):
        add(89, 300, "INVITE FRIENDS card", "bottom", 1.5, False, 10)
    add(96, 108, "GROWTH SPURT READY card", "centre", 1.5, True, 6)
    add(102.4, 108.5, "GROW transform (full screen)", "full", 2.0, True, 4)
    add(109, 116.5 if V.get("story_long") else 114.2, "Benny story shot (letterbox + caption)", "full", 2.0, True, 9)
    # after Growth Spurt 1 the HUD opens up at once (screenshots 114-160 s)
    if not V.get("calm_hud"):
        add(114.5, 300, "left: DEAL tile + red badge", "left", 0.5, False, 1)
        add(114.5, 300, "left: STATS ! / MUSCLES ! / POSES NEW badges", "left", 0.75, False, 3)
        add(114.5, 300, "top-right: DAILY ! badge", "topright", 0.25, False, 1)
        add(150, 300, "left: FREE 1,000 tile", "left", 0.5, False, 2)
        add(160, 300, "left: INVITE +10% / PLUS +20% EXP tiles", "left", 0.5, False, 6)
    else:
        add(114.5, 300, "left: menu tiles (no badges, no offers before Growth Spurt 2)", "left", 0.25, False, 0)
    add(114.5, 300, "right: GROWTH SPURT 2 card + NEXT YOU card", "right", 1.0, False, 12)
    add(165, 300, "right: TODAY'S QUEST card", "right", 0.5, False, 5)
    add(115, 118.5, "notification band", "top", 1.0, False, 6)
    # the BeatBenny line blinks: 3 s of every 12 s while the kid stands at the table
    stall_end = 125 if V.get("benny_auto") else 175
    t = 127
    if V.get("benny_auto"):
        add(119, 125, "band: Beat BENNY at arm wrestling! (stays)", "top", 1.0, True, 9)
    else:
        while t < stall_end:
            add(t, t + 3.5, "band: Beat BENNY at arm wrestling to open the Beach Gym!", "top", 1.0, True, 11); t += 12.3
    words = 15 if V.get("short_card") else 44
    add(stall_end, stall_end + 8, "Benny's card (quote, stake, strength, 2 buttons)", "centre", 2.0, True, words)
    if V.get("queue"):   # one queue per strip: a line waits for the one before it; non-KEY toasts never on the tutorial strip
        out = []; busy = {}
        for e in sorted(E, key=lambda e: (e[0], not e[5])):
            a, b, name, reg, w, key, words = e
            if reg in ("top", "bottom", "centre") and reg in busy and a < busy[reg]:
                if key: d = busy[reg] - a + 0.3; a, b = a + d, b + d
                else: reg = "side"
            if reg in ("top", "bottom", "centre"): busy[reg] = max(busy.get(reg, 0), b)
            out.append((a, b, name, reg, w, key, words))
        E = out
    return E

def kid(E, rng):
    age = rng.choice([7, 8, 9, 10, 11, 12])
    slots = 3.0 if age <= 9 else 3.5
    read = (1.5 if age <= 8 else 2.2 if age <= 10 else 3.0) * rng.uniform(0.7, 1.3)
    dt = 0.1; over = 0.0; run = 0.0; overl = set(); t = 0.0
    while t < 300:
        on = [e for e in E if e[0] <= t < e[1]]
        if HIDE[0] and any(e[3] == "centre" and e[4] >= 1.5 for e in on):
            on = [e for e in on if e[3] not in ("left", "right", "side", "topright", "top")]   # side HUD + strip hide under a card
        full = [e for e in on if e[3] == "full"]
        if full: on = full[-1:]   # a full-screen cutscene covers everything else
        w = sum(e[4] for e in on)
        if w > slots:
            run += dt
            if run >= 0.5:
                over += dt
                for e in on: overl.add(e[2])
        else: run = 0.0
        t += dt
    missed = {}
    for e in E:
        if not e[5]: continue
        shown = e[1] - e[0]; need = e[6] / read + 0.5
        if "card" in e[2] and e[3] == "centre": shown = 99   # a card waits for a tap
        same = [o for o in E if o is not e and o[3] == e[3] and o[0] < e[1] and e[0] < o[1] and o[3] != "full"]
        why = None
        if shown < need: why = "gone before read"
        elif same: why = "covered by " + same[0][2]
        elif e[2] in overl: why = "shown during overload"
        if why: missed[e[2]] = why
    return over, missed, age

def collisions(E):
    out = {}
    for i, a in enumerate(E):
        for b in E[i + 1:]:
            if a[3] == b[3] and a[3] not in ("full", "left", "right") and a[0] < b[1] and b[0] < a[1]:
                k = f"{a[2]}  x  {b[2]}"; out[k] = out.get(k, 0) + 1
    return sorted(out.items(), key=lambda kv: -kv[1])

HIDE = [0]
def run(V, n=2000, seed=2):
    HIDE[0] = V.get("hide", 0)
    rng = random.Random(seed); E = elements(V); ov = []; keys = sum(1 for e in E if e[5]); m7 = []; whys = {}
    for _ in range(n):
        o, missed, age = kid(E, rng); ov.append(o)
        if age <= 7: m7.append(100 * len(missed) / keys)
        for k, w in missed.items(): whys[(k, w.split(" by ")[0])] = whys.get((k, w.split(" by ")[0]), 0) + 1
    top = sorted(whys.items(), key=lambda kv: -kv[1])[:5]
    return st.mean(ov) * 2, st.mean(m7), collisions(E), top, keys   # overload s per 10 min (5-min run x 2)

VERS = [
    ("A  live v1914", {}),
    ("B  + PERSONAL RECORD as a side toast (not on the tutorial line)", {"pr_side": 1}),
    ("C  + INVITE card only after Growth Spurt 2, and never while on a machine", {"pr_side": 1, "invite_later": 1}),
    ("D  + calm HUD before Growth Spurt 2: no DEAL / FREE / PLUS / INVITE tiles, no red badges", {"pr_side": 1, "invite_later": 1, "calm_hud": 1}),
    ("E  + Benny: his card opens by itself, line stays on, card text 44 -> 15 words", {"pr_side": 1, "invite_later": 1, "calm_hud": 1, "benny_auto": 1, "short_card": 1}),
    ("F  + intro captions shorter (8 s cutscene)", {"pr_side": 1, "invite_later": 1, "calm_hud": 1, "benny_auto": 1, "short_card": 1, "intro_short": 1}),
    ("G  + tutorial lines stay at least words / 1.5 + 0.5 s (7-year-old reading speed)", {"pr_side": 1, "invite_later": 1, "calm_hud": 1, "benny_auto": 1, "short_card": 1, "intro_short": 1, "min_read": 1}),
    ("H  + one queue per screen strip (a line waits for the one before it; notifications go to the side)", {"pr_side": 1, "invite_later": 1, "calm_hud": 1, "benny_auto": 1, "short_card": 1, "intro_short": 1, "min_read": 1, "queue": 1}),
    ("I  + side HUD hides while a centre card is open; Benny story shot 5 -> 7.5 s", {"pr_side": 1, "invite_later": 1, "calm_hud": 1, "benny_auto": 1, "short_card": 1, "intro_short": 1, "min_read": 1, "queue": 1, "hide": 1, "story_long": 1}),
]

if __name__ == "__main__":
    print(f"{'version':92} overload s/10min  KEY missed (7 y)   collisions")
    for name, V in VERS:
        o, m, col, top, keys = run(V)
        print(f"{name:92} {o:8.0f}        {m:6.0f}% of {keys:2d}      {len(col)}")
    o, m, col, top, keys = run(VERS[0][1])
    print("\nLIVE top collisions:"); [print("  ", k) for k, c in col[:6]]
    print("LIVE most-missed KEY messages (kids of 2,000):"); [print(f"   {c:5d}  {k[0]}  ({k[1]})") for k, c in top]
    o, m, col, top, keys = run(VERS[-1][1])
    print("\nFINAL most-missed KEY messages:"); [print(f"   {c:5d}  {k[0]}  ({k[1]})") for k, c in top]
    print("FINAL collisions:", [k for k, c in col])
