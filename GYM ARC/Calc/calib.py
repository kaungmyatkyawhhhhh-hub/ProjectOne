import itertools
import impatientkid_gymarc as K
target60, target180 = 85.0, 62.0
res=[]
for watch, tap, drag, rew, fr in itertools.product((0.1,0.2,0.3),(0.03,0.06,0.1),(0.4,0.6,0.8),(6,10),(0.03,0.08,0.15)):
    K.P.update(watch=watch,tap=tap,drag=drag,rew=rew)
    s,_=K.run({"find_rate":fr}, n=600)
    res.append(((s[60]-target60)**2+(s[180]-target180)**2,watch,tap,drag,rew,fr,s[60],s[180],s[300]))
res.sort()
for r in res[:6]: print(r)
