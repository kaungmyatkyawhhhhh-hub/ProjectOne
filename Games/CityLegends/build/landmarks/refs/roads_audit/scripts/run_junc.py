import json,sys; sys.path.insert(0,'.')
import annot
J=[('Hledan junction and Pyay Road flyover',16.8262,96.1310),('Hanthawaddy roundabout',16.8133,96.1346),('Sule roundabout',16.7744,96.1586),
('Myaynigone junction and overpass',16.8032,96.1374),('Shwegondaing flyover (Kabar Aye)',16.8049,96.1560),('Bayint Naung flyover',16.8588,96.1086),
('Kabar Aye flyover by Myanmar Plaza',16.8238,96.1540),('Anawrahta x Sule Pagoda Road',16.7768,96.1583),('Thaketa roundabout',16.8070,96.2180),
('U Htaung Bo roundabout',16.7955,96.1566),('Waizayandar flyover',16.8115,96.1923),('8 Mile junction',16.8640,96.1440),
('Footbridge Pyay Road',16.80812,96.13606),('Footbridge Sule Pagoda Road',16.77712,96.15866),('Footbridge Kabar Aye Pagoda Road',16.85624,96.1567),('Footbridge Insein Road',16.82763,96.13042),
('Kamayut junction (Pyay x Insein)',16.8170,96.1310),('Pyay x University Ave (Hledan south)',16.8205,96.1320)]
for i,(n,la,lo) in enumerate(J):
    print(annot.draw(dict(name=n,lat=la,lon=lo,prefix='junc'),i,size=1000,half=0),flush=True)
