const fs=require('fs');
const SL='#2a1c12',PL='url(#pl)',HI='url(#hi)',H2='url(#h2)';
function bodymap(plates,{W=30,sx=1.02}={}){ // plates: [d, role] role: 'p' plate, 'h' hi, 'h2', 'd' dark
  const col=r=>({p:PL,h:HI,h2:H2,d:'url(#dk)'})[r];
  let s='<g stroke="'+SL+'" stroke-width="'+W+'" stroke-linejoin="round" fill="'+SL+'">'+plates.map(([d])=>`<path d="${d}"/>`).join('')+'</g>';
  s+=plates.map(([d,r])=>`<path d="${d}" fill="${col(r)}"/>`).join('');
  s+='<g fill="none" stroke="'+SL+'" stroke-width="12" stroke-linejoin="round">'+plates.map(([d])=>`<path d="${d}"/>`).join('')+'</g>';
  return `<g transform="translate(256 256) scale(${sx} 0.94) translate(-256 -256)">${s}</g>`;
}
const M=d=>d.replace(/(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)/g,(m,x,y)=>`${512-+x} ${y}`); // mirror x
function both(d,r){return [[d,r],[M(d),r]]}
// ---- front torso plates (left side) ----
const F={
 neck:['M222 44 L290 44 L284 100 L228 100 Z'],
 trap:'M214 62 L218 106 L176 118 C190 94 202 76 214 62 Z',
 delt:'M168 128 C128 116 90 128 72 160 C60 184 62 214 74 238 C98 212 130 190 166 170 Z',
 pec:'M184 128 L248 118 L248 240 C220 252 184 250 160 234 C148 210 152 172 172 146 Z',
 arm:'M72 256 C84 242 102 230 124 224 C132 272 130 322 120 364 C108 382 90 394 72 398 C60 352 60 298 72 256 Z',
 serr:'M158 248 L196 258 L196 294 L162 290 C156 276 156 262 158 248 Z',
 obl:'M162 304 L196 310 L196 384 C188 404 182 424 178 444 C168 412 160 352 162 304 Z',
 abs:[ 'M206 256 L248 252 L248 294 L206 298 Z','M206 308 L248 304 L248 346 L206 348 Z','M206 358 L248 356 L248 398 L206 400 Z','M208 410 L248 410 L248 470 C228 466 214 450 208 410 Z']
};
function front(t){
  const r=k=>t===k?'h':'p';
  let P=[[F.neck[0],'p']];
  P.push(...both(F.trap,'p'),...both(F.delt,r('shoulders')),...both(F.pec,r('chest')),...both(F.arm,'p'),...both(F.serr,'p'),...both(F.obl,t==='abs'?'h2':'p'));
  for(const a of F.abs) P.push(...both(a,r('abs')));
  return bodymap(P);
}
function back(){
  const P=[];
  P.push(...both('M248 50 L248 200 C226 176 200 150 172 126 C204 112 226 90 238 54 Z','h2')); // traps
  P.push(...both(F.delt,'p'),...both(F.arm,'p'));
  P.push(...both('M176 142 C206 168 234 198 248 222 L248 340 C222 356 196 376 178 406 C162 346 156 268 160 206 C160 176 166 156 176 142 Z','h')); // lats
  P.push(...both('M248 346 L248 462 L184 462 C180 432 186 410 198 396 C214 374 232 358 248 346 Z','p')); // lower back
  return bodymap(P);
}
function legs(){
  const P=[];
  P.push(['M140 44 L372 44 L382 128 L272 128 L256 104 L240 128 L130 128 Z','d']); // shorts
  P.push(...both('M136 142 C128 200 136 262 164 312 L192 312 C184 250 188 192 200 142 Z','h')); // outer quad
  P.push(...both('M210 142 C200 196 200 256 206 312 L236 312 C246 262 250 196 244 142 Z','h')); // inner quad
  P.push(...both('M170 326 L232 326 C236 342 232 356 222 362 L180 362 C170 356 166 342 170 326 Z','p')); // knee
  P.push(...both('M172 376 L228 376 C238 406 236 432 226 452 L184 452 C172 432 166 406 172 376 Z','p')); // shin/calf
  P.push(...both('M182 464 L226 464 L234 482 C226 490 176 490 166 484 Z','p')); // foot
  return bodymap(P);
}
function bicep(){
  const P=[
   ['M60 352 L122 112 C128 96 142 88 158 86 L204 76 L222 140 L172 160 L182 300 C142 320 102 340 60 352 Z','p'], // forearm
   ['M214 60 L248 42 L298 102 L252 148 L230 140 Z','p'], // fist
   ['M74 372 C130 364 180 346 200 336 C300 352 390 344 452 318 L456 424 C380 448 260 446 170 428 C126 418 96 400 74 372 Z','p'], // upper arm
   ['M194 306 C208 270 238 254 266 260 C296 232 338 228 368 244 C404 262 436 282 452 300 C400 330 300 340 228 330 C210 326 198 318 194 306 Z','h'], // bicep
  ];
  return bodymap(P,{sx:1});
}
// ---- flat star / coins (ref style) ----
const NV='#2a1c12';
function starD(cx,cy,R,r){let pts=[];for(let i=0;i<10;i++){const a=-Math.PI/2+i*Math.PI/5,rr=i%2?r:R;pts.push([cx+Math.cos(a)*rr,cy+Math.sin(a)*rr])}
 let d='';for(let i=0;i<10;i++){const p=pts[i],n=pts[(i+1)%10],pr=pts[(i+9)%10];const k=i%2?0.1:0.17;const a=[p[0]+(pr[0]-p[0])*k,p[1]+(pr[1]-p[1])*k],c=[p[0]+(n[0]-p[0])*k,p[1]+(n[1]-p[1])*k];d+=(i?'L':'M')+a.map(v=>v.toFixed(1)).join(' ')+' Q'+p.map(v=>v.toFixed(1)).join(' ')+' '+c.map(v=>v.toFixed(1)).join(' ')+' ';}return d+'Z'}
function star(){const d=starD(256,280,236,112);
 return `<defs><clipPath id="c"><path d="${d}"/></clipPath></defs>
 <path d="${d}" fill="#ecd5a6"/><g clip-path="url(#c)"><path d="M0 0 L150 0 C110 120 110 320 150 512 L0 512 Z" fill="#f8ead0"/><path d="M512 0 L210 0 C330 120 350 320 300 512 L512 512 Z" fill="#d2b07a"/></g>
 <path d="${d}" fill="none" stroke="${NV}" stroke-width="26" stroke-linejoin="round"/>
 <path d="M150 390 L156 352" stroke="#fff" stroke-width="16" stroke-linecap="round"/><circle cx="160" cy="328" r="8" fill="#fff"/>`}
function coins(){
 let s='';const cx=170,rx=140,ry=46;
 for(let i=3;i>=0;i--){const y=420-i*64;
  s+=`<path d="M${cx-rx} ${y} L${cx-rx} ${y+52} A${rx} ${ry} 0 0 0 ${cx+rx} ${y+52} L${cx+rx} ${y} Z" fill="${i%2?'#e2c48e':'#d2b07a'}" stroke="${NV}" stroke-width="18" stroke-linejoin="round"/>`;
  for(let t=-3;t<=3;t++){const x=cx+t*40,yy=y+52+ry*Math.sqrt(1-(t*40/rx)**2);s+=`<path d="M${x} ${yy-2} L${x} ${yy-18}" stroke="${NV}" stroke-width="10" stroke-linecap="round"/>`}
 }
 s+=`<ellipse cx="${cx}" cy="228" rx="${rx}" ry="${ry}" fill="#f3e2bf" stroke="${NV}" stroke-width="18"/>`;
 // standing coin
 s+=`<g transform="translate(60 40) scale(.84) rotate(14 380 270)"><path d="M352 60 C412 60 462 160 462 270 C462 380 412 480 352 480 L330 480 C270 480 220 380 220 270 C220 160 270 60 330 60 Z" fill="#c9a46c" stroke="${NV}" stroke-width="18"/>
 <ellipse cx="352" cy="270" rx="110" ry="210" fill="#f3e2bf" stroke="${NV}" stroke-width="18"/><ellipse cx="352" cy="270" rx="70" ry="160" fill="#e2c48e" stroke="${NV}" stroke-width="14"/></g>`;
 return `<g transform="translate(0,-8) scale(.96) translate(10,10)">${s}</g>`}
const GLOW={shoulders:'#ff8a1e',chest:'#ff3b3b',abs:'#ffc83a',back:'#9b5cff',bicep:'#ff3b3b',legs:'#3d8bff',star:'#ffc83a',coins:'#ffc83a'};
const HL={shoulders:['#ffc27a','#f07a12'],chest:['#ff8a80','#d92a2a'],abs:['#ffe08a','#e0a21c'],back:['#c9a6ff','#7b45e6'],bicep:['#ff8a80','#d92a2a'],legs:['#9cc6ff','#2f74e6'],star:['#ffe08a','#e0a21c'],coins:['#ffe08a','#e0a21c']};
function dial(name,inner){
  const c=GLOW[name]; let t='';
  for(let i=0;i<96;i++){const a=i/96*Math.PI*2,r1=212,r2=i%8?200:194;t+=`<line x1="${256+Math.cos(a)*r1}" y1="${256+Math.sin(a)*r1}" x2="${256+Math.cos(a)*r2}" y2="${256+Math.sin(a)*r2}"/>`}
  let rays='';for(let i=0;i<12;i++){rays+=`<path d="M256 256 L${256+Math.cos(i/12*6.283-0.07)*300} ${256+Math.sin(i/12*6.283-0.07)*300} L${256+Math.cos(i/12*6.283+0.07)*300} ${256+Math.sin(i/12*6.283+0.07)*300} Z"/>`}
  let dust='';const R=[[100,170],[360,60],[420,410],[80,380],[300,470],[470,180],[150,60],[430,300]];for(const [x,y] of R)dust+=`<circle cx="${x}" cy="${y}" r="${(x*7%4)+2}" fill="#fff" opacity=".35"/>`;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512"><defs>
  <radialGradient id="bg" cx=".5" cy=".5" r=".7"><stop offset="0" stop-color="#2a201a"/><stop offset="1" stop-color="#110d0b"/></radialGradient>
  <radialGradient id="gl" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="${c}" stop-opacity=".55"/><stop offset=".55" stop-color="${c}" stop-opacity=".18"/><stop offset="1" stop-color="${c}" stop-opacity="0"/></radialGradient>
  <linearGradient id="pl" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f6e7c8"/><stop offset="1" stop-color="#d6b98a"/></linearGradient>
  <linearGradient id="hi" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${HL[name][0]}"/><stop offset="1" stop-color="${HL[name][1]}"/></linearGradient>
  <linearGradient id="h2" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f0c27a"/><stop offset="1" stop-color="#c98a3a"/></linearGradient>
  <linearGradient id="dk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5a4130"/><stop offset="1" stop-color="#3a2a1e"/></linearGradient>
  <filter id="sh"><feDropShadow dx="0" dy="0" stdDeviation="10" flood-color="${c}" flood-opacity=".8"/></filter></defs>
  <rect width="512" height="512" fill="url(#bg)"/>
  <g fill="${c}" opacity=".07">${rays}</g>
  <circle cx="256" cy="256" r="250" fill="url(#gl)"/>
  <g stroke="${c}" stroke-opacity=".7" stroke-width="2" fill="none"><circle cx="256" cy="256" r="214"/><circle cx="256" cy="256" r="150" stroke-opacity=".35"/>${t}
  <path d="M256 4 L256 66 M256 446 L256 508 M4 256 L66 256 M446 256 L508 256" stroke-opacity=".55"/><path d="M256 106 L406 256 L256 406 L106 256 Z" stroke-opacity=".2"/></g>
  ${dust}
  <g filter="url(#sh)" transform="translate(256 256) scale(.74) translate(-256 -256)">${inner}</g></svg>`;
}
const out={shoulders:front('shoulders'),chest:front('chest'),abs:front('abs'),back:back(),bicep:bicep(),legs:legs(),star:star(),coins:coins()};
fs.mkdirSync('out5',{recursive:true});for(const [k,v] of Object.entries(out))fs.writeFileSync('out5/'+k+'.svg',dial(k,v));
fs.writeFileSync('s5.html','<body style="margin:0;background:#000;display:flex">'+Object.keys(out).map(k=>`<img src="out5/${k}.svg" width=240 style="margin:4px">`).join('')+'</body>');
