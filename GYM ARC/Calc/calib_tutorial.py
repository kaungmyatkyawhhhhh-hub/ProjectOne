import tutorialsim_gymarc as T
# target (live funnel, Creator Hub 56 days): ~85% stay past 60 s, ~62% past 3 min (15.2% leave <60 s, 22.6% at 61-180 s)
best=None
for ar in (0.03,0.045,0.06,0.08):
    T.AUTO_RATE=ar
    for ap in (0.35,0.5,0.65,0.8,1.0):
        s,_=T.run(T.VERS[0][1],n=800,auto_pay=ap)
        err=(s[60]-85)**2+(s[180]-62)**2
        print(f"auto_rate {ar} auto_pay {ap}: 60s {s[60]:.0f} 3m {s[180]:.0f} 5m {s[300]:.0f}")
        if best is None or err<best[0]: best=(err,ar,ap)
print("BEST",best)
