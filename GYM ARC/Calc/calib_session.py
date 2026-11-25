import session_gymarc as S, tenmin_gymarc as TM
for hab in (0.06, 0.08, 0.1, 0.12):
    TM.HAB = hab
    print(hab, round(S.run(S.VERS[0][1], n=400, cond=True), 1), "min (target ~18 for live survivors of 3 min)")
