# Stomp Evolution - grinder sim on LIVE v132 numbers (13 Nov). Hour 1 / day 7 progress, stalls, time to STAR.
import math, random, statistics as st
PROPS = {  # name: need, mass, coins, landmark
'Flower':(0,1,1,0),'Mailbox':(0,1.5,1,0),'Bin':(0,2,2,0),'Bike':(2.05,4,3,0),'Car':(3.5,14,8,0),'Bus':(6,45,22,0),
'House':(10,150,60,0),'ShopRow':(18,520,180,0),'Tower':(32,1900,550,0),'Containers':(12,300,110,0),'OilTank':(18,700,260,0),
'Warehouse':(26,1500,520,0),'GlassTower':(40,3200,950,0),'NeonTower':(55,6000,1700,0),'Palace':(75,12000,3200,0),
'Playground':(2.6,24,14,1),'School':(7,380,150,1),'MegaMall':(14,1100,420,1),'Crane':(24,2600,900,1),'CargoShip':(28,3200,1100,1),
'TwinTowers':(45,9000,2600,1),'Stadium':(65,18000,5000,1),'CrownTower':(90,40000,10000,1)}
FORMS=[('STARTER',0),('BRAWLER',1.9),('STONE',2.4),('IRON',3.0),('MAGMA',4.5),('STORM',8),('CRYSTAL',13),('STAR',21)]
AREAS=[('SUBURBS',2.4),('DOWNTOWN',4.5),('HARBOUR',8),('TITAN',13),('CROWN',21)]
H=lambda m:1.7*(1+m/40)**0.24
def cost(lv): return round(8*2.1**lv)
def form(h): return max(i for i,(n,a) in enumerate(FORMS) if h>=a)
def power_pts(h):
    p=0
    for k in range(len(FORMS)-1):
        lo=1.7 if k==0 else FORMS[k][1]; hi=FORMS[k+1][1]
        for f in (1/3,2/3,1):
            if h>=lo+(hi-lo)*f: p+=1
    top=FORMS[-1][1]
    while h>=top*1.15 and p<24: top*=1.15; p+=1
    return p

def run(minutes, rate=3.4, prop_share=0.3, awaken_policy='at_star', seed=0, active=1.0, log=False):
    rnd=random.Random(seed)
    m=0; coins=10; pw=0; aw=0; cards=0; t=0.0; stomps=0
    seen_props=set(); best_h=0; events=[]; star_idx=0
    dt=1.0; T=minutes*60
    last_new=0; gaps=[]
    def new(what):
        nonlocal last_new
        gaps.append((t-last_new, what, t)); last_new=t; events.append((t,what))
    fi=0; area_i=0
    while t<T:
        h=H(m)
        avail=[(n,v) for n,v in PROPS.items() if v[0]<=h]
        best=max((v for n,v in avail if not v[3]), key=lambda v:v[1])
        # cards: 1 per power point; ~ half are mass cards worth ~+8% avg; after 20 cards shards +10%
        pp=power_pts(h)
        cardmult=1+0.06*min(pp,20)+0.10*max(0,pp-20)
        comb=1+5/15
        ev=1+(20/90)*(1/3)
        idx=1+0.01*min(star_idx,69)
        mult=(1+0.35*pw)*cardmult*comb*ev*idx*(1.5**aw)
        n_st=rate*dt*active
        stomps+=n_st
        # bare stomps pay 1.2*best; prop stomps pay the prop (avg ~0.7 of best, plus golden 1/80 x25)
        m_gain=n_st*((1-prop_share)*1.2*best[1] + prop_share*0.7*best[1]*(1+25/80))*mult
        c_gain=n_st*prop_share*0.7*best[2]*(1+25/80)*1.0
        m+=m_gain; coins+=c_gain
        # first smash of each kind (index NEW x5 coins) - landmarks reached when walking there
        for n,v in avail:
            if n not in seen_props and rnd.random()< (0.02 if v[3] else 0.08):
                seen_props.add(n); coins+=5*v[2]; star_idx+=0; new('prop '+n)
        # index stars grow slowly with smashes
        star_idx = min(69, int(math.log10(1+stomps*prop_share/ max(1,len(seen_props)))*3)*len(seen_props)//3)
        while coins>=cost(pw) and pw<99:
            coins-=cost(pw); pw+=1
            if pw<=3 or pw%5==0: new(f'Power {pw}')
        h=H(m)
        nf=form(h)
        if nf>fi: fi=nf; new('FORM '+FORMS[nf][0])
        while area_i<len(AREAS) and max(best_h,h)>=AREAS[area_i][1]:
            new('AREA '+AREAS[area_i][0]); area_i+=1
        best_h=max(best_h,h)
        if awaken_policy=='at_star' and h>=21:
            aw+=1; m=0; coins=10; pw=0; fi=0; new(f'AWAKEN {aw}')
        t+=dt
    return dict(h=H(m),best=best_h,aw=aw,pw=pw,events=events,gaps=gaps)

if __name__=='__main__':
    for mins in (60,):
        r=run(mins)
        print('--- first hour timeline')
        for t,w in r['events']:
            if not w.startswith('prop') or True: print(f'{t/60:6.1f} min  {w}')
