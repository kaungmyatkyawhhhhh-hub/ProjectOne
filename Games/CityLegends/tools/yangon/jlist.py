import sys; sys.path.insert(0,__import__('os').path.dirname(__import__('os').path.abspath(__file__)))
import pickle, numpy as np
from common import *
k=load_kml(); main=pickle.load(open('main.pkl','rb'))
def boundary(key,a,b):
    n=main[key]['names']; P=main[key]['pts']
    last_a=max(i for i,x in enumerate(n) if x==a); first_b=min(i for i,x in enumerate(n) if x==b and i>last_a-30) if any(x==b for x in n) else last_a
    i=(last_a+first_b)//2; return tuple(P[i])
bl=main['blue']; on=bl['on']; i_leave=next(i for i in range(len(on)) if not on[i] and i>50)
JL=[
 ('Optima (START)',tuple(k['optima'][0]),''),
 ('Roundabout, Pyay Rd / U Wisara Rd',(-580,-733),''),
 ('Pyay Rd flyover / University Ave',tuple(k['more roads'][0]),''),
 ('University Ave / Thanlwin Rd',tuple(k['more roads'][-1]),''),
 ('Kabar Aye flyover / University Ave',tuple(k['new roasd'][0]),''),
 ('Kabar Aye Pagoda Rd / Parami Rd',boundary('loop','kabar aye pagoda road','parami road'),''),
 ('Parami Rd / Pyay Rd',boundary('loop','parami road','pyay road'),''),
 ('"new roasd" turns off Kabar Aye Pagoda Rd',tuple(k['new roasd'][6]),''),
 ('"new roasd" drawn part, middle',tuple(k['new roasd'][8]),''),
 ('"new roasd" joins the loop link',tuple(k['new roasd'][-1]),''),
 ('Novotel',tuple(k['novotel'][0]),''),
 ('MM Plaza',tuple(k['mm plaza'][0]),''),
]
if __name__=='__main__':
    for j in JL: print(j[0],[round(v) for v in j[1]])
