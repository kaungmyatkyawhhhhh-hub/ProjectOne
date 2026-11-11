import math
TIERS=["Asteroid","Moon","Planet","Gas Giant","Star","Binary Star","Pulsar","Quasar"]
R=1.15
def base_cost(k): return 10*8**k
def base_inc(k): return 1.0*5**k
def ms(n): # milestone multiplier x2 at 25,50,100,200...
    m=1
    for t in (25,50,100,200,300,400): 
        if n>=t: m*=2
    return m
def tier_income(k,n): return base_inc(k)*n*ms(n)
def run(target, mult, unlocked=8, dt=1.0, start=0.0):
    own=[0]*8; cash=start; t=0; earned=0
    own[0]=1 if True else 0
    while earned<target:
        inc=sum(tier_income(k,own[k]) for k in range(unlocked))*mult
        # greedy: best payback among affordable-soon options
        best=None
        for k in range(unlocked):
            c=base_cost(k)*R**own[k]
            gain=(tier_income(k,own[k]+1)-tier_income(k,own[k]))*mult
            score=c/gain + (max(0,c-cash)/inc if inc>0 else 1e18)
            if best is None or score<best[0]: best=(score,k,c)
        _,k,c=best
        if cash>=c: cash-=c; own[k]+=1; continue
        cash+=inc*dt; earned+=inc*dt; t+=dt
        if t>1e6: break
    return t,own
if __name__=="__main__":
    for tgt in (1e5,3e5,1e6):
        t,own=run(tgt,1.0); print(tgt, round(t/60,1),"min",own)
