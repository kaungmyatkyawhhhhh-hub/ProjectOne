const fs=require('fs');
const PAL={cream:['#fff3df','#f1cf9e','#c99a5e','#a87842'],red:['#ff7a5c','#e8281a','#a5120a','#8f150c'],orange:['#ffc06a','#ff7d10','#c44f00','#9c4205'],purple:['#c9a4ff','#7d3cf0','#4d1fae','#4a1ba0'],gold:['#ffe680','#f7b500','#c48100','#8f5d00'],blue:['#8fd0ff','#2d7ff5','#1546b0','#173f92'],black:['#4a4a55','#18181d','#000','#000'],white:['#ffffff','#dfe3ec','#a9b0c0','#7d8596']};
let uid=0;
function part(d,col,{gloss=null,lines=[],lw=12,ow=20}={}){
  const p=PAL[col],id='p'+(uid++);
  let s=`<defs><linearGradient id="${id}g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${p[0]}"/><stop offset=".55" stop-color="${p[1]}"/></linearGradient><clipPath id="${id}c"><path d="${d}"/></clipPath></defs>`;
  s+=`<path d="${d}" fill="url(#${id}g)"/>`;
  s+=`<g clip-path="url(#${id}c)"><path d="${d}" fill="none" stroke="${p[2]}" stroke-opacity=".55" stroke-width="40" transform="translate(0,22)"/>`;
  for(const l of lines) s+=`<path d="${l}" fill="none" stroke="${p[3]}" stroke-width="${lw}" stroke-linecap="round" stroke-linejoin="round" stroke-opacity=".85"/>`;
  if(gloss){const [cx,cy,rx,ry,r]=gloss; s+=`<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" transform="rotate(${r||-15} ${cx} ${cy})" fill="#fff" opacity=".75"/>`;}
  s+=`</g><path d="${d}" fill="none" stroke="#1a120c" stroke-width="${ow}" stroke-linejoin="round"/>`;
  return s;
}
const svg=(body,shadowD)=>`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">${body}</svg>`;
// ---------- torso front ----------
const TORSO='M214 118 L214 92 Q256 80 298 92 L298 118 C360 122 410 138 430 170 C440 190 436 214 420 232 C404 300 388 360 372 410 L140 410 C124 360 108 300 92 232 C76 214 72 190 82 170 C102 138 152 122 214 118 Z';
const DELT_L='M48 200 C42 156 76 128 116 130 C150 132 168 160 160 192 C152 226 120 246 88 242 C64 238 50 222 48 200 Z';
const DELT_R='M464 200 C470 156 436 128 396 130 C362 132 344 160 352 192 C360 226 392 246 424 242 C448 238 462 222 464 200 Z';
const PEC_L='M166 146 C194 132 234 132 250 138 L250 232 C222 248 188 248 168 236 C154 222 152 196 154 178 C156 162 160 152 166 146 Z';
const PEC_R='M346 146 C318 132 278 132 262 138 L262 232 C290 248 324 248 344 236 C358 222 360 196 358 178 C356 162 352 152 346 146 Z';
const ABS=[];for(let r=0;r<3;r++)for(const s of [-1,1]){const x=s<0?198:262,y=254+r*50;ABS.push(`M${x+6} ${y} L${x+46} ${y} C${x+52} ${y} ${x+52} ${y} ${x+52} ${y+6} L${x+52} ${y+36} C${x+52} ${y+42} ${x+52} ${y+42} ${x+46} ${y+42} L${x+6} ${y+42} C${x} ${y+42} ${x} ${y+42} ${x} ${y+36} L${x} ${y+6} C${x} ${y} ${x} ${y} ${x+6} ${y} Z`)}
const BELT='M140 400 L372 400 C380 400 384 406 382 414 L376 442 C374 448 370 452 362 452 L150 452 C142 452 138 448 136 442 L130 414 C128 406 132 400 140 400 Z';
const BUCKLE='M230 406 L282 406 L282 446 L230 446 Z';
const PECS='M150 150 C186 128 236 128 256 140 C276 128 326 128 362 150 C376 172 376 214 358 238 C330 258 284 256 256 240 C228 256 182 258 154 238 C136 214 136 172 150 150 Z';
const ABSB='M196 262 C220 254 292 254 316 262 C324 300 322 350 310 388 C290 396 222 396 202 388 C190 350 188 300 196 262 Z';
function torsoFront(hi){
  const acc={chest:'red',abs:'gold',shoulders:'orange'}[hi]; const C=k=>hi===k?acc:'cream';
  let b=part(TORSO,'cream',{gloss:[196,126,40,10,-8],ow:24});
  b+=part(PECS,C('chest'),{gloss:[196,158,30,10,-12],lines:['M256 146 L256 232'],ow:16});
  b+=part(ABSB,C('abs'),{gloss:[228,272,18,5,0],lines:['M256 266 L256 384','M204 302 L308 302','M202 344 L310 344'],ow:16,lw:10});
  b+=part(DELT_L,C('shoulders'),{gloss:[96,160,26,11,-25]})+part(DELT_R,C('shoulders'),{gloss:[400,158,24,10,20]});
  b+=part(BELT,'gold',{gloss:[200,410,40,5,0]})+part(BUCKLE,'gold',{gloss:[244,416,10,4,0],ow:12});
  return svg(b);
}
// ---------- torso back ----------
const TRAPS='M214 112 C236 104 276 104 298 112 L340 140 C310 150 282 168 256 196 C230 168 202 150 172 140 Z';
const LAT_L='M164 154 C200 160 236 186 250 214 L250 390 L174 390 C150 330 132 262 132 210 C134 182 146 162 164 154 Z';
const LAT_R='M348 154 C312 160 276 186 262 214 L262 390 L338 390 C362 330 380 262 380 210 C378 182 366 162 348 154 Z';
function torsoBack(){
  let b=part(TORSO,'cream',{gloss:[196,126,40,10,-8],ow:24});
  b+=part(LAT_L,'purple',{gloss:[176,200,14,30,-15],lines:['M160 300 C190 300 220 310 240 330']})+part(LAT_R,'purple',{gloss:[336,200,12,26,15],lines:['M352 300 C322 300 292 310 272 330']});
  b+=part(TRAPS,'purple',{gloss:[236,122,22,6,0]});
  b+=part(DELT_L,'cream',{gloss:[96,160,26,11,-25]})+part(DELT_R,'cream',{gloss:[400,158,24,10,20]});
  b+=part(BELT,'gold',{gloss:[200,410,40,5,0]});
  return svg(b);
}
// ---------- legs ----------
function legs(){
  const SH='M128 70 L384 70 C396 70 404 78 404 90 L412 182 C412 192 404 198 394 198 L272 198 L256 166 L240 198 L118 198 C108 198 100 192 100 182 L108 90 C108 78 116 70 128 70 Z';
  const Q=s=>{const x=s<0?0:1; return s<0?'M120 194 L244 194 C250 250 242 300 222 340 C204 360 166 362 146 344 C122 310 112 250 120 194 Z':'M392 194 L268 194 C262 250 270 300 290 340 C308 360 346 362 366 344 C390 310 400 250 392 194 Z'};
  const CALF=s=>s<0?'M150 344 C174 360 206 358 222 344 C226 380 218 412 206 432 L162 432 C150 410 144 378 150 344 Z':'M362 344 C338 360 306 358 290 344 C286 380 294 412 306 432 L350 432 C362 410 368 378 362 344 Z';
  const SHOE=s=>s<0?'M148 426 L214 426 C222 426 226 432 226 440 L226 462 C226 470 220 474 212 474 L124 474 C112 474 108 464 114 454 C122 440 136 428 148 426 Z':'M364 426 L298 426 C290 426 286 432 286 440 L286 462 C286 470 292 474 300 474 L388 474 C400 474 404 464 398 454 C390 440 376 428 364 426 Z';
  let b='';
  for(const s of [-1,1]) b+=part(SHOE(s),'white',{gloss:[s<0?160:350,438,16,5,0]})+part(CALF(s),'cream',{gloss:[s<0?168:340,370,8,16,0]});
  for(const s of [-1,1]) b+=part(Q(s),'blue',{gloss:[s<0?150:362,236,14,30,s<0?-10:10],lines:[s<0?'M176 290 C190 310 196 326 196 336':'M336 290 C322 310 316 326 316 336']});
  b+=part(SH,'black',{gloss:[170,88,40,7,0],lines:[]});
  b+=`<path d="M134 84 L126 186" stroke="#fff" stroke-width="12" stroke-linecap="round"/><path d="M378 84 L386 186" stroke="#fff" stroke-width="12" stroke-linecap="round"/>`;
  b+=part('M110 66 L402 66 C410 66 414 72 412 80 L410 96 L102 96 L100 80 C98 72 102 66 110 66 Z','gold',{gloss:[180,74,40,4,0]});
  return svg(b);
}
// ---------- star + dumbbell ----------
function star(){
  let pts=[];for(let i=0;i<10;i++){const a=-Math.PI/2+i*Math.PI/5,r=i%2?92:196;pts.push([256+Math.cos(a)*r,236+Math.sin(a)*r])}
  // rounded star via quadratic corners
  let d='';for(let i=0;i<10;i++){const p=pts[i],n=pts[(i+1)%10],pr=pts[(i+9)%10];const k=i%2?0.12:0.16;const a=[p[0]+(pr[0]-p[0])*k,p[1]+(pr[1]-p[1])*k],c=[p[0]+(n[0]-p[0])*k,p[1]+(n[1]-p[1])*k];d+=(i?'L':'M')+a.map(v=>v.toFixed(1)).join(' ')+' Q'+p.map(v=>v.toFixed(1)).join(' ')+' '+c.map(v=>v.toFixed(1)).join(' ')+' ';}
  d+='Z';
  let b=part(d,'gold',{gloss:[200,170,34,14,-30],lines:['M256 120 L256 150']});
  // dumbbell
  b+=part('M140 384 L372 384 L372 412 L140 412 Z','white',{ow:14});
  for(const s of [-1,1]){const x=s<0?104:360; b+=part(`M${x} 352 L${x+48} 352 C${x+54} 352 ${x+56} 356 ${x+56} 362 L${x+56} 442 C${x+56} 448 ${x+54} 452 ${x+48} 452 L${x} 452 C${x-6} 452 ${x-8} 448 ${x-8} 442 L${x-8} 362 C${x-8} 356 ${x-6} 352 ${x} 352 Z`,'red',{gloss:[x+12,368,8,5,0]});}
  return svg(b);
}
// ---------- coins ----------
function coins(){
  const coin=(cx,cy,rx,ry,h)=>`M${cx-rx} ${cy} L${cx-rx} ${cy+h} A${rx} ${ry} 0 0 0 ${cx+rx} ${cy+h} L${cx+rx} ${cy} A${rx} ${ry} 0 0 0 ${cx-rx} ${cy} Z`;
  const top=(cx,cy,rx,ry)=>`M${cx-rx} ${cy} A${rx} ${ry} 0 0 1 ${cx+rx} ${cy} A${rx} ${ry} 0 0 1 ${cx-rx} ${cy} Z`;
  let b='';
  for(let i=0;i<4;i++){const y=420-i*44; b+=part(coin(190,y,120,44,40),'gold',{})+part(top(190,y,120,44),'gold',{gloss:[160,y-14,40,8,0]});}
  // big front coin
  b+=part('M362 160 A112 112 0 1 1 361.9 160 Z','gold',{});
  b+=part('M362 132 C424 132 474 182 474 244 C474 306 424 356 362 356 C300 356 250 306 250 244 C250 182 300 132 362 132 Z','gold',{gloss:[322,176,30,14,-35]});
  let pts=[];for(let i=0;i<10;i++){const a=-Math.PI/2+i*Math.PI/5,r=i%2?26:60;pts.push((256+106+Math.cos(a)*r).toFixed(1)+' '+(250+Math.sin(a)*r).toFixed(1))}
  b+=`<path d="M362 166 A78 78 0 1 1 361.9 166 Z" fill="none" stroke="#c48100" stroke-width="10"/><path d="M${pts.join(' L')} Z" fill="#c48100" stroke="#8f5d00" stroke-width="6" stroke-linejoin="round"/>`;
  return svg(b);
}
const out={shoulders:torsoFront('shoulders'),chest:torsoFront('chest'),abs:torsoFront('abs'),back:torsoBack(),legs:legs(),star:star(),coins:coins()};
fs.mkdirSync('out',{recursive:true});for(const [k,v] of Object.entries(out))fs.writeFileSync('out/'+k+'.svg',v);
fs.writeFileSync('sheet.html',`<html><body style="margin:0;background:#2a2630;display:flex;flex-wrap:wrap;width:2048px">${Object.keys(out).map(k=>`<img src="out/${k}.svg" width="256" height="256">`).join('')}<img src="/mnt/user-data/outputs/gym_arc_alter_bicep_icons/bicep_golden.png" width="256"></body></html>`);
