"""MEGA BITE debate-kids simulation, round 2 (13 Nov 2026): the LIVE Studio build, not the plan.
Round 1 (9 Nov, debatekids.py) scored the plan with every launch feature in it. This round scores only what is in the
build today, then adds the missing things one at a time. Rivals: the 10 of round 1 + 5 from the November 2026 lists
(GGRecon fastest-growing new games, 2 Nov 2026; Rowatcher most played, Jun 2026). Scores 0-10 are estimates."""
import random, statistics as st, json
import debatekids as D
g = D.g
D.RIVALS.update({
    "DONT SPLASH":        g(first_min=7, depth=4, social=8, pvp_thrill=2, pvp_safe=8, fair_money=7, looks=7, cute_funny=2, scary=8, crowd=9, updates=6, phone=7, easy=8, novelty=9, collect=3, show_off=4, ocean=3, original=8),
    "+1 Venom Evolution": g(first_min=8, depth=6, social=4, pvp_thrill=3, pvp_safe=8, fair_money=5, looks=5, cute_funny=4, scary=2, crowd=7, updates=7, phone=8, easy=9, novelty=5, collect=7, show_off=7, ocean=0, original=4),
    "Cat Battles":        g(first_min=8, depth=5, social=7, pvp_thrill=8, pvp_safe=6, fair_money=5, looks=6, cute_funny=9, scary=1, crowd=7, updates=6, phone=8, easy=8, novelty=7, collect=6, show_off=6, ocean=0, original=7),
    "RIVALS":             g(first_min=7, depth=7, social=8, pvp_thrill=10, pvp_safe=4, fair_money=6, looks=8, cute_funny=2, scary=2, crowd=10, updates=8, phone=6, easy=5, novelty=4, collect=7, show_off=9, ocean=0, original=7),
    "Adopt Me!":          g(first_min=7, depth=7, social=9, pvp_thrill=0, pvp_safe=10, fair_money=5, looks=7, cute_funny=10, scary=0, crowd=10, updates=8, phone=8, easy=9, novelty=2, collect=10, show_off=9, ocean=1, original=8),
})
# THE LIVE BUILD (13 Nov, read from Studio). Why each score: see the vault note.
LIVE = g(first_min=8, depth=8, social=5, pvp_thrill=7, pvp_safe=8, fair_money=8, looks=7, cute_funny=6, scary=4, crowd=1,
         updates=4, phone=6, easy=8, novelty=7, collect=7, show_off=7, ocean=10, original=7)
VERS = [("L0  the live build today", {}),
        ("L1  + PLAY TOGETHER: join a friend, crew of 4, crew bonus at the Kraken", dict(social=8)),
        ("L2  + update board at spawn: countdown, what is next, a Saturday event", dict(updates=8)),
        ("L3  + phone pass measured on a real cheap phone (margin)", dict(phone=7)),
        ("L4  + launch crowd (marketing, not design): full servers first, creators", dict(crowd=4)),
        ("L5  + launch push: code + event day", dict(crowd=5))]
if __name__ == "__main__":
    print("calibration (each rival as 'our game' against 3 others):")
    for name in ("Brookhaven RP", "Blox Fruits", "Fish It!", "DONT SPLASH", "Be Fish", "DEVOUR"):
        rv = dict(D.RIVALS); me = rv.pop(name); keep = D.RIVALS; D.RIVALS = rv
        r = D.run(me, n=1500); D.RIVALS = keep
        print("  %-18s agree %3.0f%%  1st pick %3.0f%%" % (name, r["agree"], r["first"]))
    mega = dict(LIVE); out = []
    print("\n%-74s agree  1st pick  top objections (groups out of 3,000)" % "version")
    for name, kw in VERS:
        mega.update(kw); r = D.run(mega, show=2 if not kw else 0)
        top = "; ".join("%s %d" % (k, c) for k, c in r["top"][:3]) or "none"
        print("%-74s %4.0f%%  %4.0f%%    %s" % (name, r["agree"], r["first"], top)); out.append((name, r["agree"], r["first"], r["top"][:4]))
        if not kw:
            for grp, riv, win, vs in r["examples"]:
                print("    debate:", ", ".join(k["name"] for k in grp), "| choices: MEGA BITE,", ", ".join(riv), "| they play:", win, "| against MEGA BITE:", "; ".join('%s: "%s"' % (n, v[1]) for n, v in vs))
    rng = random.Random(9); ag = []; fp = []; back = {}
    for _ in range(60):
        noisy = {k: max(0, min(10, v + rng.choice((-1, 0, 1)))) for k, v in mega.items()}
        r = D.run(noisy, n=1000, seed=rng.randrange(10 ** 6)); ag.append(r["agree"]); fp.append(r["first"])
        for k, c in r["top"]: back[k] = back.get(k, 0) + 1
    print("\nrobustness of L5 (every score +-1, 60 tries): agree median %.0f%% (worst %.0f%%), 1st pick median %.0f%%" % (st.median(ag), min(ag), st.median(fp)))
    print("objections that come back when a score slips:", sorted(back.items(), key=lambda kv: -kv[1])[:6])
    json.dump(out, open("debate_v2_out.json", "w"))
