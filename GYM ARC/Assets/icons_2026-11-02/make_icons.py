import math, random
def frame(col, glow):
    random.seed(hash(col)%1000)
    ticks=''.join(f'<line x1="{256+math.cos(a)*205:.1f}" y1="{256+math.sin(a)*205:.1f}" x2="{256+math.cos(a)*222:.1f}" y2="{256+math.sin(a)*222:.1f}" stroke="{col}" stroke-opacity=".55" stroke-width="2"/>' for a in [i*2*math.pi/72 for i in range(72)])
    cross=''.join(f'<line x1="{256+math.cos(a)*190:.1f}" y1="{256+math.sin(a)*190:.1f}" x2="{256+math.cos(a)*250:.1f}" y2="{256+math.sin(a)*250:.1f}" stroke="{col}" stroke-opacity=".6" stroke-width="2"/>' for a in [i*math.pi/2 for i in range(4)])
    diag=''.join(f'<line x1="{256+math.cos(a)*200:.1f}" y1="{256+math.sin(a)*200:.1f}" x2="{256+math.cos(a)*215:.1f}" y2="{256+math.sin(a)*215:.1f}" stroke="{col}" stroke-opacity=".5" stroke-width="2"/>' for a in [math.pi/4+i*math.pi/2 for i in range(4)])
    rays=''.join(f'<path d="M256 256 L{256+math.cos(a-.05)*260:.0f} {256+math.sin(a-.05)*260:.0f} L{256+math.cos(a+.05)*260:.0f} {256+math.sin(a+.05)*260:.0f}Z" fill="{glow}" fill-opacity=".06"/>' for a in [i*2*math.pi/16 for i in range(16)])
    dots=''.join(f'<circle cx="{random.uniform(40,472):.0f}" cy="{random.uniform(40,472):.0f}" r="{random.uniform(1,3):.1f}" fill="#f4e6c8" fill-opacity="{random.uniform(.3,.8):.2f}"/>' for _ in range(26))
    return f'''<defs><radialGradient id="bg" cx=".5" cy=".5" r=".6"><stop offset="0" stop-color="{glow}" stop-opacity=".55"/><stop offset=".45" stop-color="{glow}" stop-opacity=".18"/><stop offset="1" stop-color="#0b0807" stop-opacity="0"/></radialGradient>
<linearGradient id="em" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f1e1bf"/><stop offset="1" stop-color="#d4b98d"/></linearGradient>
<filter id="gl" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="14"/></filter></defs>
<rect width="512" height="512" fill="#120d0b"/><rect width="512" height="512" fill="url(#bg)"/>{rays}
<circle cx="256" cy="256" r="222" fill="none" stroke="{col}" stroke-opacity=".6" stroke-width="2.5"/><circle cx="256" cy="256" r="205" fill="none" stroke="{col}" stroke-opacity=".5" stroke-width="2"/>{ticks}{cross}{diag}
<circle cx="256" cy="256" r="150" fill="none" stroke="{col}" stroke-opacity=".35" stroke-width="1.5"/>
<path d="M256 106 L406 256 L256 406 L106 256Z" fill="none" stroke="{col}" stroke-opacity=".18" stroke-width="1.5"/>{dots}'''
def emblem(shape, lines, glow):
    # glow behind, dark outline, beige fill, top highlight, engraved lines
    return f'''<g filter="url(#gl)"><g fill="{glow}" opacity=".9">{shape}</g></g>
<g transform="translate(0 6)" fill="#1c1009">{shape}</g>
<g fill="url(#em)" stroke="#2b1a0e" stroke-width="7" stroke-linejoin="round">{shape}</g>
<g fill="none" stroke="#5a3a1e" stroke-width="7" stroke-linecap="round" stroke-linejoin="round">{lines}</g>'''
I={}
# 1 shoulders (orange): traps + neck + two delt caps + tank-top neckline
I['shoulders']=('#c9864a','#ff8a2a','''<path d="M226 150 Q256 140 286 150 L296 182 Q330 196 352 210 Q396 196 424 222 Q448 258 430 300 Q414 330 380 330 L356 330 L356 360 L156 360 L156 330 L132 330 Q98 330 82 300 Q64 258 88 222 Q116 196 160 210 Q182 196 216 182Z"/>''',
 '''<path d="M216 190 Q256 236 296 190"/><path d="M160 226 Q150 270 170 310"/><path d="M352 226 Q362 270 342 310"/><path d="M256 236 V340"/>''')
# 2 star + dumbbell (gold)
star=' '.join(f'{256+math.cos(-math.pi/2+i*math.pi/8)*(170 if i%2==0 else 72):.0f},{256+math.sin(-math.pi/2+i*math.pi/8)*(170 if i%2==0 else 72):.0f}' for i in range(16))
I['star']=('#c9b06a','#ffd23f',f'<polygon points="{star}"/>',
 '<circle cx="256" cy="256" r="50"/><path d="M226 256 H286"/><path d="M226 234 V278"/><path d="M286 234 V278"/>')
# 3 bicep flex (red): upper arm horizontal, forearm up, fist on top, sleeve band
I['bicep']=('#c97070','#ff3a5a','''<path d="M84 318 Q80 270 120 262 L168 256 Q196 204 250 204 Q300 206 318 246 L328 252 L318 186 Q312 166 326 156 L330 120 Q332 96 356 92 L398 90 Q428 90 430 118 L432 156 Q434 178 414 186 L404 192 L396 298 Q392 344 348 348 L120 350 Q86 350 84 318Z"/>''',
 '''<path d="M118 268 V344"/><path d="M190 246 Q244 222 296 252"/><path d="M336 120 H426"/><path d="M336 138 H428"/><path d="M336 156 H428"/><path d="M362 96 V120 M392 94 V120"/><path d="M330 186 Q356 196 404 186"/><path d="M190 318 H320"/>''')
# 4 back (purple): head + V taper, tank top straps
I['back']=('#9a7ac9','#9a5aff','''<circle cx="256" cy="118" r="34"/><path d="M226 156 L286 156 L300 168 Q370 176 404 190 L376 352 L136 352 L108 190 Q142 176 212 168Z"/>''',
 '''<path d="M256 168 V340"/><path d="M180 206 Q222 196 244 214"/><path d="M332 206 Q290 196 268 214"/><path d="M160 248 L208 300 L214 340"/><path d="M352 248 L304 300 L298 340"/>''')
# 5 chest (red): neck stub, collarbones, two flat pec plates, straight lower edges, tank-top style
I['chest']=('#c97070','#ff3a5a','''<path d="M226 128 H286 L292 152 Q352 158 396 170 Q414 176 412 196 L392 350 L120 350 L100 196 Q98 176 116 170 Q160 158 220 152Z"/>''',
 '''<path d="M150 186 Q200 170 248 182"/><path d="M362 186 Q312 170 264 182"/><path d="M256 182 V274"/><path d="M144 210 L144 260 Q148 274 164 274 L246 274"/><path d="M368 210 L368 260 Q364 274 348 274 L266 274"/><path d="M180 312 H332"/>''')
# 6 coins (gold) keep
I['coins']=('#c9b06a','#ffd23f','''<rect x="104" y="214" width="190" height="190" rx="30"/><circle cx="330" cy="236" r="106"/>''',
 '''<path d="M110 250 H290 M110 286 H290 M110 322 H290 M110 358 H290"/><circle cx="330" cy="236" r="72"/><polygon points="330,190 342,224 378,224 349,245 360,280 330,259 300,280 311,245 282,224 318,224"/>''')
# 7 abs (gold)
I['abs']=('#c9b06a','#ffd23f','''<path d="M150 146 Q256 132 362 146 L350 368 L256 392 L162 368Z"/>''',
 '''<path d="M256 168 V376"/><path d="M200 214 H312"/><path d="M196 266 H316"/><path d="M200 318 H312"/><path d="M170 220 L190 238 M342 220 L322 238"/><path d="M172 290 L190 304 M340 290 L322 304"/>''')
# 8 legs (blue): shorts on top (no gap), two quads, knees, calves
I['legs']=('#6a8ac9','#3a8aff','''<path d="M132 104 H380 L392 212 Q390 224 376 226 L352 228 Q360 290 340 334 L336 396 Q336 424 312 424 L288 424 Q266 422 268 396 L272 334 Q258 290 262 228 L250 228 L244 228 Q252 290 238 334 L242 396 Q244 422 222 424 L198 424 Q174 424 174 396 L170 334 Q150 290 158 228 L134 226 Q120 224 120 212Z"/>''',
 '''<path d="M126 150 H386"/><path d="M256 150 V214"/><path d="M196 246 Q190 290 208 324"/><path d="M314 246 Q320 290 302 324"/><path d="M178 340 Q206 352 236 340"/><path d="M274 340 Q304 352 334 340"/><path d="M204 362 V404 M306 362 V404"/>''')
for name,(col,glow,shape,lines) in I.items():
    svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">{frame(col,glow)}{emblem(shape,lines,glow)}</svg>'
    open(f'{name}.svg','w').write(svg)
