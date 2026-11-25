import tenmin_gymarc as T
# target: players who pass 3 min on live play ~18 min on average (D1 playtime 11.8 min with 15.2% <1 min, 22.6% 1-3 min)
for hab in (0.06, 0.08, 0.1):
    for tap in (0.025, 0.03):
        T.HAB = hab; T.P["tap"] = tap
        m, ten = T.run(T.PLAN[0][1], n=500, cond=True)
        print(f"HAB {hab} tap {tap}: survivors' mean {m:5.1f} min, survivors past 10 min {ten:3.0f}%")
