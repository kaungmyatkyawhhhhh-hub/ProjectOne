# MEGA BITE - GOLD RUSH stinger (13 Nov night). Same family as the UI v3 / star sounds (glass-bubble pluck, C major).
# Shape (K06 recipe): an airy riser that PEAKS on the hit (0.42 s), then a bright C-major bell chord + an octave strum up,
# a soft low whomp under it, and a 1 s shower of gold sparkle. Identity in 1-5 kHz for phone speakers.
import sys; sys.argv=[sys.argv[0], sys.argv[1] if len(sys.argv)>1 else 'out']
exec(open('/tmp/claude-0/sfx/star/kit.py').read())
def bell(midi,L=0.4,dec=0.14,ratio=3.5,idx=1.4,att=0.0015):
    t=tt(L); f=N(midi); ph=2*np.pi*f*t
    mod=np.sin(ph*ratio)*idx*np.exp(-t/0.03)
    y=np.sin(ph+mod)*np.exp(-t/dec)+0.18*np.sin(2*ph)*np.exp(-t/(dec*0.5))
    return (y*np.minimum(t/att,1)).astype(np.float32)
H=0.42
rush=mix(2.0,
  (swish(H+0.05,700,5200,peak=0.92,q=1.5),0.0,0.6),
  (pluck(C5+12,0.2,0.05,0.12,0.5),H-0.30,0.18),(pluck(E5+12,0.2,0.05,0.12,0.5),H-0.22,0.2),(pluck(G5+12,0.2,0.05,0.12,0.5),H-0.14,0.22),(pluck(C6+12,0.2,0.05,0.1,0.5),H-0.07,0.24),
  (tick(0.02,3000,9000,0.003),H,0.4),(thup(240,90,0.18,0.06),H,0.45),
  (bell(C6,1.2,0.42,3.5,1.1),H,0.8),(bell(E6,1.2,0.42,3.5,1.0),H+0.012,0.65),(bell(G6,1.2,0.45,3.5,1.0),H+0.024,0.65),
  (pluck(C7,0.8,0.25,0.05,0.5),H+0.09,0.4),(pluck(E6+12,0.8,0.22,0.05,0.4),H+0.16,0.3),(pluck(G6+12,0.8,0.2,0.05,0.4),H+0.23,0.28),
  (sparkle(1.1,34,4200,9000,0.07,21),H+0.03,0.3),(bubble(700,1600,0.08),H+0.02,0.2),(bubble(900,1900,0.07),H+0.12,0.15))
out('Gold_Rush',rush,lufs=-16,verb=0.16,room=0.35,hp=150,lp=11000)
