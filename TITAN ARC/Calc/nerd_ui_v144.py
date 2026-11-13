"""Quality-nerd kid on the Stomp Evolution UI (13 Nov, v144 + phone fixes). Owner: "do picky kid check on the new screens".
The map kid (nerd_v127.py) looks at views on a walk; this one looks at SCREENS for 10 minutes:
 * the HUD is in every glance (a glance every ~2 s, the HUD is what he looks at ~1 glance in 4),
 * he opens windows like a new player: Daily once (it opens by itself), Shop 2x, Index 1-2x, Top 1x, Codes 1x,
   each open = ~4 glances at that window.
Every glance can catch a TELL that is really on that screen (from this session's PC + iPhone 17 Pro screenshots):
 HUD   empty plate     coin counter: a long gold bar with only "10" at the left
       style mismatch  the NEXT bar is a plain dark capsule (not the kit)
       caps mix        ALL CAPS ("NEXT: BRAWLER", "BRAWLER/AWAKEN/CROWN", "COINS") beside Title Case
       studs everywhere the same stud pattern on every surface (rim, boards, bars, cards, buttons)
 WIN   title over HUD  phone: the window title sticker sits on the Height counter
       blank icon      an icon is empty the first time a window opens (seen 3x this session, Roblox 502s too)
       empty board     Top: big empty stud field under few rows
WOWS: big glossy art on cards (Shop/Daily/Index), the Big Prize chest, medal rows, Today! pulse, found-tile colours.
Score = 1.6 log(1+wows) - sum w log(1+count). Trust TELLS PER 10 MIN + the top tells (the like split is all-or-nothing).
Run: python nerd_ui_v144.py"""
import math, random
W = {"empty plate": 0.7, "style mismatch": 0.8, "caps mix": 0.5, "studs everywhere": 0.6,
     "title over HUD": 0.7, "blank icon": 1.0, "empty board": 0.6}
NOTICE = {  # chance per glance at that screen that the kid notices the tell (it's there every time; he isn't always looking)
    "empty plate": 0.05, "style mismatch": 0.04, "caps mix": 0.03, "studs everywhere": 0.03,
    "title over HUD": 0.25, "empty board": 0.3}

def kid(v, rng, T=600):
    tells = {}; wows = 0.0
    def tell(k): tells[k] = tells.get(k, 0) + 1
    phone = rng.random() < 0.6                                   # most Roblox kids are on a phone
    opens = ["daily"] + ["shop"] * 2 + ["index"] * rng.choice([1, 2]) + ["top", "codes"]
    rng.shuffle(opens); opens.remove("daily"); opens.insert(0, "daily")
    open_at = sorted(rng.uniform(10, T - 20) for _ in opens)
    seen_first = set(); oi = 0; t = 0
    while t < T:
        t += 2
        if oi < len(opens) and t >= open_at[oi]:                 # a window: ~4 glances at it
            w = opens[oi]; oi += 1
            first = w not in seen_first; seen_first.add(w)
            if first and rng.random() < v["blank_icon_p"]: tell("blank icon")
            wows += {"daily": 1.5, "shop": 1.2, "index": 1.0, "top": 0.8, "codes": 0.5}[w] * (1 if first else 0.4)
            for _ in range(4):
                if phone and v["title_over_hud"] and rng.random() < NOTICE["title over HUD"]: tell("title over HUD")
                if w == "top" and v["empty_board"] and rng.random() < NOTICE["empty board"]: tell("empty board")
                if v["studs_everywhere"] and rng.random() < NOTICE["studs everywhere"]: tell("studs everywhere")
            t += 8
            continue
        if rng.random() < 0.25:                                  # a glance at the HUD
            for k, flag in (("empty plate", "empty_plate"), ("style mismatch", "next_bar_plain"), ("caps mix", "caps_mix"),
                            ("studs everywhere", "studs_everywhere")):
                if v[flag] and rng.random() < NOTICE[k]: tell(k)
    score = 1.6 * math.log1p(wows) - sum(W[k] * math.log1p(c) for k, c in tells.items())
    p_like = 1 / (1 + math.exp(-(score - 1.0) / 1.2)); p_dis = 1 / (1 + math.exp((score + 1.0) / 1.2))
    x = rng.random()
    return ("like" if x < p_like * 0.35 else ("dislike" if x > 1 - p_dis * 0.35 else "none")), tells, wows

def run(v, n=2000, seed=7):
    rng = random.Random(seed); likes = dis = 0; agg = {}; w = 0
    for _ in range(n):
        verdict, tells, wows = kid(v, rng); w += wows
        likes += verdict == "like"; dis += verdict == "dislike"
        for k, c in tells.items(): agg[k] = agg.get(k, 0) + c
    top = sorted(agg.items(), key=lambda kv: -kv[1])
    return dict(ratio=100 * likes / max(1, likes + dis), tells=sum(agg.values()) / n, wows=w / n,
                top=", ".join(f"{k} {c/n:.1f}" for k, c in top[:3]) or "none", worst=(top[0][1] / n if top else 0))

V = []
def ver(name, **kw):
    v = dict(V[-1]) if V else dict(empty_plate=True, next_bar_plain=True, caps_mix=True, studs_everywhere=True,
                                    title_over_hud=True, blank_icon_p=0.35, empty_board=True)
    v.update(kw); v["name"] = name; V.append(v)
ver("U0 v144 + phone fixes (as built)")
ver("U1 + windows open only after their images are loaded (preload + wait)", blank_icon_p=0.05)
ver("U2 + phones: the centre HUD (Height + NEXT) hides while a window is open", title_over_hud=False)
ver("U3 + coin counter plate fits the number", empty_plate=False)
ver("U4 + NEXT bar on a kit plate, Title Case everywhere", next_bar_plain=False, caps_mix=False)
ver("U5 + studs only on cards/buttons (plain big boards, rims, bars)", studs_everywhere=False)
ver("U6 + Top boards shrink to their rows", empty_board=False)
if __name__ == "__main__":
    print("QUALITY-NERD KID on the Stomp Evolution UI (2,000 kids, 10 minutes, 60% on phones; trust tells per 10 min)")
    print(f"{'version':78s} likes  tells/10min  wows  top tells")
    for v in V:
        r = run(v)
        print(f"{v['name']:78s} {r['ratio']:4.0f}%   {r['tells']:5.1f}     {r['wows']:5.1f}  {r['top']}")
