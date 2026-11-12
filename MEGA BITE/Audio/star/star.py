# MEGA BITE - EXP star sounds (12 Nov). The 3D gold stars that burst out of every eat and fly into the EXP counter.
# Same family as UI set v3 (glass-bubble pluck, C major). Phone-first: identity in 1-5 kHz, nothing below ~250 Hz matters.
import sys; sys.argv=[sys.argv[0], sys.argv[1] if len(sys.argv)>1 else 'out']
exec(open(__file__.rsplit('/',1)[0]+'/kit.py').read())
def bell(midi,L=0.4,dec=0.14,ratio=3.5,idx=1.4,att=0.0015):
    """a small crystal bell: FM with an inharmonic ratio (glassy), index falling fast so only the strike is metallic"""
    t=tt(L); f=N(midi); ph=2*np.pi*f*t
    mod=np.sin(ph*ratio)*idx*np.exp(-t/0.03)
    y=np.sin(ph+mod)*np.exp(-t/dec)+0.18*np.sin(2*ph)*np.exp(-t/(dec*0.5))
    return (y*np.minimum(t/att,1)).astype(np.float32)
# 1 STAR BURST (stars pop out of the bite, 0.42 s out): a light up-fwish + a fast 3-note sprinkle + sparkle. Soft, it sits on EatPop.
burst=mix(0.7,(tick(0.015,4000,9000,0.002),0,0.25),(swish(0.32,1400,6500,peak=0.45,q=1.5),0.0,0.55),
          (pluck(G6,0.18,0.05,0.12,0.5),0.03,0.38),(pluck(C7,0.18,0.05,0.1,0.5),0.065,0.34),(pluck(E6+12,0.16,0.045,0.08,0.4),0.10,0.22),
          (sparkle(0.42,12,4300,8400,0.045,7),0.06,0.22))
out('Star_Burst',burst,lufs=-22,verb=0.07,room=0.22,hp=300,lp=10000)
# 2 STAR LAND (each star into the counter): a crisp crystal ting on C6; the game steps it up a C-major pentatonic ladder
land=mix(0.42,(tick(0.012,3500,8000,0.0018),0,0.35),(bell(C6,0.38,0.11,3.5,1.1),0.0005,1.0),(pluck(C7,0.14,0.035,0.06,0.3,0.6),0.001,0.18))
out('Star_Land',land,lufs=-20,verb=0.05,room=0.18,hp=350,lp=9500,peak=-3.0)
# 3 STAR FINAL (the last star lands, the counter pops): a quick C-E-G strum blooming into sparkle, one bubble under it
fin=mix(1.0,(tick(0.015,3000,8000,0.0025),0,0.3),(thup(260,170,0.05,0.014),0,0.25),
        (bell(C6,0.7,0.2,3.5,1.0),0.0,0.75),(bell(E6,0.7,0.2,3.5,0.9),0.022,0.6),(bell(G6,0.7,0.22,3.5,0.9),0.044,0.6),(pluck(C7,0.5,0.16,0.05,0.5),0.066,0.35),
        (sparkle(0.7,18,4200,8600,0.06,11),0.06,0.2),(bubble(800,1700,0.07),0.01,0.18))
out('Star_Final',fin,lufs=-19,verb=0.12,room=0.3,hp=280,lp=10500)
