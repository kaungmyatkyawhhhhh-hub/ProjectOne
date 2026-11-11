const fs=require('fs');
const SL='#2a1c12';
// reuse dial + starD from v5 by eval of the needed parts
const src=fs.readFileSync(__dirname+'/base.js','utf8');
const starD=eval('('+src.match(/function starD[\s\S]*?return d\+'Z'\}/)[0]+')');
const GLOW={},HL={};
function shape(d,fill,w=30){return `<path d="${d}" fill="${SL}" stroke="${SL}" stroke-width="${w}" stroke-linejoin="round"/><path d="${d}" fill="${fill}"/><path d="${d}" fill="none" stroke="${SL}" stroke-width="12" stroke-linejoin="round"/>`}
function line(d,col,w){return `<path d="${d}" fill="none" stroke="${SL}" stroke-width="${w+26}" stroke-linecap="round" stroke-linejoin="round"/><path d="${d}" fill="none" stroke="${col}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"/>`}
function ell(cx,cy,rx,ry,rot,fill){const d=`M${cx-rx} ${cy} A${rx} ${ry} 0 1 0 ${cx+rx} ${cy} A${rx} ${ry} 0 1 0 ${cx-rx} ${cy} Z`;return `<g transform="rotate(${rot} ${cx} ${cy})">${shape(d,fill,24)}</g>`}
function dumbbell(cx,cy,s=1){return `<g transform="translate(${cx} ${cy}) scale(${s})">${shape('M-110 -10 L110 -10 L110 10 L-110 10 Z','url(#pl)',24)}${shape('M-120 -46 L-84 -46 L-84 46 L-120 46 Z','url(#dk2)',24)}${shape('M84 -46 L120 -46 L120 46 L84 46 Z','url(#dk2)',24)}${shape('M-150 -30 L-126 -30 L-126 30 L-150 30 Z','url(#dk2)',22)}${shape('M126 -30 L150 -30 L150 30 L126 30 Z','url(#dk2)',22)}</g>`}
// ---------- designs ----------
function olympian(){
 let s='';
 const leaf=(x,y,ang,L=84,W=30)=>{const d=`M0 0 Q${L*0.5} ${-W} ${L} 0 Q${L*0.5} ${W} 0 0 Z`;return `<g transform="translate(${x.toFixed(1)} ${y.toFixed(1)}) rotate(${ang.toFixed(1)})">${shape(d,'url(#h2)',20)}</g>`};
 for(const side of [-1,1]){
  let stem='';
  for(let i=0;i<=40;i++){const a=(92+i*3.2)*Math.PI/180;const x=256+side*-Math.cos(a)*-1*175*-1,y=262+Math.sin(a)*175;stem+=(i?'L':'M')+(256-side*Math.cos(a)*-175*-1).toFixed(1)+' '+y.toFixed(1)+' ';}
  s+=line(stem.replace(/M|L/g,m=>m),'#c98a3a',8);
  for(let i=0;i<6;i++){const deg=122+i*19;const a=deg*Math.PI/180;const x=256-side*Math.cos(a)*-175*-1,y=262+Math.sin(a)*175;
   const tang=Math.atan2(Math.cos(a)*175, side*Math.sin(a)*175)*180/Math.PI; // direction of travel
   const tx=-side*-Math.sin(a)*-1, ty=Math.cos(a);
   const t=Math.atan2(ty, -side*Math.sin(a)*-1*-1)*180/Math.PI;
   const travel=Math.atan2(Math.cos(a), side*Math.sin(a))*180/Math.PI;
   s+=leaf(x,y,travel+(side>0?-40:40)+180);
   s+=leaf(x,y,travel+(side>0?40:-40)+180,70,26);
  }
 }
 s+=`<g transform="translate(256 262) scale(.92) translate(-256 -262)">`;
 s+=shape('M156 340 L148 196 L208 250 L256 158 L304 250 L364 196 L356 340 Z','url(#hi)');
 s+=shape('M150 336 L362 336 L362 382 L150 382 Z','url(#pl)');
 for(const [x,y,r] of [[256,300,16],[200,302,10],[312,302,10],[148,192,12],[364,192,12],[256,154,13]]) s+=`<circle cx="${x}" cy="${y}" r="${r}" fill="#fff" stroke="${SL}" stroke-width="9"/>`;
 s+='</g>';
 return s;}
function hof(){
 let s='';
 s+=line('M168 140 C96 140 96 236 176 244','url(#pl)',20)+line('M344 140 C416 140 416 236 336 244','url(#pl)',20);
 s+=shape('M158 100 L354 100 C354 230 312 296 256 306 C200 296 158 230 158 100 Z','url(#hi)');
 s+=shape('M234 300 L278 300 L282 360 L230 360 Z','url(#pl)');
 s+=shape('M176 360 L336 360 L356 428 L156 428 Z','url(#pl)');
 s+=shape(starD(256,192,62,30),'#fff2c4',20);
 s+='<path d="M186 122 L196 220" stroke="#fff" stroke-width="14" stroke-linecap="round" opacity=".8"/>';
 return s;}
function legend(){
 let s='';
 s+=shape(starD(256,226,210,100),'url(#hi)');
 s+=`<path d="M150 150 L160 110" stroke="#fff" stroke-width="15" stroke-linecap="round"/>`;
 s+=shape('M120 364 L392 364 L372 400 L392 436 L120 436 L140 400 Z','url(#pl)',26);
 s+=`<text x="256" y="424" text-anchor="middle" font-family="Arial Black, Arial, sans-serif" font-weight="900" font-size="66" fill="${SL}">★10</text>`;
 return s;}
function pumpkin(){
 let s='';
 s+=shape('M248 118 C244 90 252 64 278 50 L292 70 C276 82 272 100 274 120 Z','#7a9a3a',26);
 s+=ell(176,262,96,140,0,'url(#hi)')+ell(336,262,96,140,0,'url(#hi)')+ell(256,262,104,150,0,'url(#h3)');
 s+=`<g fill="${SL}"><path d="M176 220 L232 216 L206 172 Z"/><path d="M336 220 L280 216 L306 172 Z"/><path d="M160 296 C200 346 312 346 352 296 L322 306 L306 330 L290 306 L256 316 L222 306 L206 330 L190 306 Z"/></g>`;
 s+=dumbbell(256,420,0.95);
 return s;}
function snow(){
 let s='<g transform="translate(256 226) scale(.82) translate(-256 -240)">';
 for(let i=0;i<6;i++){const a=i*Math.PI/3+Math.PI/2;const x=256+Math.cos(a)*190,y=240+Math.sin(a)*190;
  const bx=256+Math.cos(a)*120,by=240+Math.sin(a)*120;const p=a+Math.PI/2;
  s+=line(`M256 240 L${x.toFixed(1)} ${y.toFixed(1)} M${bx.toFixed(1)} ${by.toFixed(1)} L${(bx+Math.cos(a+0.6)*55).toFixed(1)} ${(by+Math.sin(a+0.6)*55).toFixed(1)} M${bx.toFixed(1)} ${by.toFixed(1)} L${(bx+Math.cos(a-0.6)*55).toFixed(1)} ${(by+Math.sin(a-0.6)*55).toFixed(1)}`,'url(#hi)',20);}
 s+=`<circle cx="256" cy="240" r="40" fill="url(#pl)" stroke="${SL}" stroke-width="12"/></g>`;
 s+=dumbbell(256,420,0.95);
 return s;}
function beach(){
 let s='<g transform="translate(256 214) scale(.84) translate(-256 -236)">';
 for(let i=0;i<12;i++){const a=i*Math.PI/6;const r1=150,r2=215;const c=[256+Math.cos(a)*r2,236+Math.sin(a)*r2],l=[256+Math.cos(a-0.16)*r1,236+Math.sin(a-0.16)*r1],r=[256+Math.cos(a+0.16)*r1,236+Math.sin(a+0.16)*r1];
  s+=shape(`M${l.map(v=>v.toFixed(1)).join(' ')} L${c.map(v=>v.toFixed(1)).join(' ')} L${r.map(v=>v.toFixed(1)).join(' ')} Z`,'url(#h2)',22);}
 s+=`<circle cx="256" cy="236" r="140" fill="${SL}"/><circle cx="256" cy="236" r="128" fill="url(#hi)"/>`;
 s+=`<g fill="${SL}"><path d="M150 200 L362 200 L356 222 C350 262 300 268 286 232 L270 222 L242 222 L226 232 C212 268 162 262 156 222 Z"/></g>`;
 s+=`<path d="M182 214 L206 214" stroke="#9ad8ff" stroke-width="10" stroke-linecap="round"/><path d="M296 214 L320 214" stroke="#9ad8ff" stroke-width="10" stroke-linecap="round"/>`;
 s+=`<path d="M196 298 C230 332 282 332 316 298" fill="none" stroke="${SL}" stroke-width="14" stroke-linecap="round"/></g>`;
 s+=dumbbell(256,430,0.95);
 return s;}
const DES={
 olympian:{f:olympian,glow:'#ffc83a',hl:['#ffe08a','#e0a21c']},
 hall_of_famer:{f:hof,glow:'#ff8a1e',hl:['#ffd27a','#f08a12']},
 legend:{f:legend,glow:'#9b5cff',hl:['#d6b8ff','#7b45e6']},
 halloween:{f:pumpkin,glow:'#ff6a12',hl:['#ffa04a','#e0560c']},
 winter:{f:snow,glow:'#3dbbff',hl:['#d8f2ff','#6cc4f5']},
 summer:{f:beach,glow:'#ffb21e',hl:['#fff08a','#ffb21e']},
};
function dial(c,hl,inner){
  let t='';
  for(let i=0;i<96;i++){const a=i/96*Math.PI*2,r1=212,r2=i%8?200:194;t+=`<line x1="${256+Math.cos(a)*r1}" y1="${256+Math.sin(a)*r1}" x2="${256+Math.cos(a)*r2}" y2="${256+Math.sin(a)*r2}"/>`}
  let rays='';for(let i=0;i<12;i++){rays+=`<path d="M256 256 L${256+Math.cos(i/12*6.283-0.07)*300} ${256+Math.sin(i/12*6.283-0.07)*300} L${256+Math.cos(i/12*6.283+0.07)*300} ${256+Math.sin(i/12*6.283+0.07)*300} Z"/>`}
  let dust='';for(const [x,y] of [[100,170],[360,60],[420,410],[80,380],[300,470],[470,180],[150,60],[430,300]])dust+=`<circle cx="${x}" cy="${y}" r="${(x*7%4)+2}" fill="#fff" opacity=".35"/>`;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512"><defs>
  <radialGradient id="bg" cx=".5" cy=".5" r=".7"><stop offset="0" stop-color="#2a201a"/><stop offset="1" stop-color="#110d0b"/></radialGradient>
  <radialGradient id="gl" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="${c}" stop-opacity=".55"/><stop offset=".55" stop-color="${c}" stop-opacity=".18"/><stop offset="1" stop-color="${c}" stop-opacity="0"/></radialGradient>
  <linearGradient id="pl" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f6e7c8"/><stop offset="1" stop-color="#d6b98a"/></linearGradient>
  <linearGradient id="hi" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${hl[0]}"/><stop offset="1" stop-color="${hl[1]}"/></linearGradient>
  <linearGradient id="h3" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffb862"/><stop offset="1" stop-color="#ef6a14"/></linearGradient>
  <linearGradient id="h2" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f0c27a"/><stop offset="1" stop-color="#c98a3a"/></linearGradient>
  <linearGradient id="dk2" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6a5040"/><stop offset="1" stop-color="#3a2a1e"/></linearGradient>
  <filter id="sh"><feDropShadow dx="0" dy="0" stdDeviation="10" flood-color="${c}" flood-opacity=".8"/></filter></defs>
  <rect width="512" height="512" fill="url(#bg)"/>
  <g fill="${c}" opacity=".07">${rays}</g>
  <circle cx="256" cy="256" r="250" fill="url(#gl)"/>
  <g stroke="${c}" stroke-opacity=".7" stroke-width="2" fill="none"><circle cx="256" cy="256" r="214"/><circle cx="256" cy="256" r="150" stroke-opacity=".35"/>${t}
  <path d="M256 4 L256 66 M256 446 L256 508 M4 256 L66 256 M446 256 L508 256" stroke-opacity=".55"/></g>
  ${dust}
  <g filter="url(#sh)" transform="translate(256 256) scale(.70) translate(-256 -256)">${inner}</g></svg>`;
}
fs.mkdirSync('out',{recursive:true});
for(const [k,v] of Object.entries(DES)) fs.writeFileSync('out/'+k+'.svg',dial(v.glow,v.hl,v.f()));
