import numpy as np, soundfile as sf
SR=48000; FPS=30; N=270
mix=np.zeros(int(N/FPS*SR)+SR)
def put(name,frame,gain=1.0):
    x,_=sf.read(f'set/{name}.wav'); i=int(frame/FPS*SR); mix[i:i+len(x)]+=gain*x[:len(mix)-i]
amb,_=sf.read('set/_Ambience.wav'); mix[:len(amb)]+=amb[:len(mix)]
for j,f in enumerate([0,15,30,45]): put(f'Swim_Swish_{j%3+1}',f,0.7)
put('Idle_Bubbles_1',70,0.8); put('Idle_Bubbles_2',100,0.8)
put('Dart_Whoosh_1',121)
put('Bite_Chomp_1',153); put('Bite_Chomp_2',171); put('Gulp_1',177,0.9)
put('Sense_Ping',182)
put('Hurt_Bonk_1',225)
for j,f in enumerate([240,255]): put(f'Swim_Swish_{j+1}',f,0.7)
pk=abs(mix).max()
if pk>0.95: mix*=0.95/pk
sf.write('preview_mix.wav',mix[:int(N/FPS*SR)],SR); print('ok', pk)
