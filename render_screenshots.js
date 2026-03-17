const { createCanvas } = require('canvas');
const fs = require('fs');

const W=1920,H=1080;

// --- Noise ---
function hash(x,y){let h=(x*374761393+y*668265263)|0;h=Math.imul(h^(h>>>13),1274126177);return((h^(h>>>16))>>>0)/4294967296;}
function noise(x,y){const ix=Math.floor(x),iy=Math.floor(y),fx=x-ix,fy=y-iy;
  const ux=fx*fx*(3-2*fx),uy=fy*fy*(3-2*fy);
  return(hash(ix,iy)*(1-ux)+hash(ix+1,iy)*ux)*(1-uy)+(hash(ix,iy+1)*(1-ux)+hash(ix+1,iy+1)*ux)*uy;}
function fbm(x,y,o){let v=0,a=0.5,f=1;for(let i=0;i<(o||4);i++){v+=a*noise(x*f,y*f);a*=0.5;f*=2;}return v;}

const GOLD='#FFB612',BLU='#1A5CB0',RED='#D42A3C',LIGHT='#FFF0D6';
const VPx=W/2,VPy=H*0.25;
function w2s(wx,wy){const t=Math.pow(wy/100,0.72);const sy=H*0.95+(VPy-H*0.95)*t;const hw=W*0.58*(1-t*0.72);return{x:VPx+(wx/50)*hw,y:sy};}
function scl(wy){return 1-Math.pow(wy/100,0.72)*0.62;}

// --- Generate concrete texture ---
const texCvs=createCanvas(512,512),texCtx=texCvs.getContext('2d');
(function(){const w=512,id=texCtx.createImageData(w,w),d=id.data;
  for(let y=0;y<w;y++)for(let x=0;x<w;x++){const i=(y*w+x)*4;
    let n=fbm(x/60,y/60,6);let r=68+n*45,g=62+n*38,b=54+n*30;
    const ag=noise(x/2.5,y/2.5);if(ag>0.75){r+=18;g+=14;b+=10;}if(ag<0.25){r-=12;g-=10;b-=8;}
    const jx=x%128,jy=y%128;if(jx<3||jy<3){r=28;g=24;b=20;}
    const wet=fbm(x/100+10,y/100+10,3);if(wet>0.6){const wf=(wet-0.6)*2.5;r*=(1-wf*0.3);g*=(1-wf*0.25);b*=(1-wf*0.2);}
    d[i]=Math.max(0,Math.min(255,r));d[i+1]=Math.max(0,Math.min(255,g));d[i+2]=Math.max(0,Math.min(255,b));d[i+3]=255;}
  texCtx.putImageData(id,0,0);})();

function renderScene(name, drawFn) {
  const canvas = createCanvas(W, H);
  const ctx = canvas.getContext('2d');
  drawFn(ctx);
  fs.writeFileSync(`/home/user/nhl-project/nfl-street-game/${name}.png`, canvas.toBuffer('image/png'));
  console.log(`Saved ${name}.png`);
}

// === SCREENSHOT 1: TITLE SCREEN ===
renderScene('screenshot_title', (ctx) => {
  // Sky
  const g=ctx.createLinearGradient(0,0,0,H*0.5);
  g.addColorStop(0,'#060410');g.addColorStop(0.15,'#0e0a1e');g.addColorStop(0.35,'#1a1235');
  g.addColorStop(0.55,'#2a1a3a');g.addColorStop(0.75,'#452535');g.addColorStop(0.9,'#6a3525');g.addColorStop(1,'#8a4520');
  ctx.fillStyle=g;ctx.fillRect(0,0,W,H*0.5);
  ctx.fillStyle='#000';ctx.fillRect(0,H*0.5,W,H*0.5);
  
  // Stars
  for(let i=0;i<25;i++){ctx.fillStyle=`rgba(255,255,255,${0.2+Math.random()*0.3})`;
    ctx.beginPath();ctx.arc(hash(i,0)*W,hash(i,1)*H*0.28,0.6+hash(i,2)*0.4,0,6.28);ctx.fill();}
  
  // Moon
  ctx.save();ctx.globalCompositeOperation='lighter';
  const mg=ctx.createRadialGradient(W*0.82,H*0.08,0,W*0.82,H*0.08,80);
  mg.addColorStop(0,'rgba(255,250,240,0.15)');mg.addColorStop(0.3,'rgba(200,190,180,0.05)');mg.addColorStop(1,'rgba(0,0,0,0)');
  ctx.fillStyle=mg;ctx.beginPath();ctx.arc(W*0.82,H*0.08,80,0,6.28);ctx.fill();
  ctx.fillStyle='rgba(230,225,215,0.6)';ctx.beginPath();ctx.arc(W*0.82,H*0.08,8,0,6.28);ctx.fill();ctx.restore();
  
  // Clouds
  for(let c=0;c<12;c++){const cx2=100+c*160,cy2=60+Math.sin(c*1.5)*50,cw=130+Math.sin(c*2)*60;
    for(let b=0;b<6;b++){const bx=cx2+(Math.random()-0.5)*cw,by=cy2+(Math.random()-0.5)*30;
      const cg=ctx.createRadialGradient(bx,by,0,bx,by,40+Math.random()*30);
      cg.addColorStop(0,'rgba(200,195,190,0.12)');cg.addColorStop(0.5,'rgba(160,155,150,0.06)');cg.addColorStop(1,'rgba(0,0,0,0)');
      ctx.fillStyle=cg;ctx.beginPath();ctx.ellipse(bx,by,50+Math.random()*40,20+Math.random()*15,0,0,6.28);ctx.fill();}}
  
  // Buildings
  const base=H*0.42;
  const dbs=[{x:-10,w:90,h:120},{x:90,w:50,h:85},{x:160,w:110,h:165},{x:290,w:70,h:140},
    {x:380,w:100,h:195},{x:500,w:60,h:110},{x:580,w:130,h:220},{x:730,w:80,h:150},
    {x:830,w:100,h:185},{x:950,w:70,h:130},{x:1040,w:120,h:250},{x:1180,w:90,h:170},
    {x:1290,w:80,h:200},{x:1390,w:110,h:155},{x:1520,w:75,h:230},{x:1620,w:100,h:185},
    {x:1740,w:90,h:210},{x:1850,w:70,h:140}];
  dbs.forEach((b,i)=>{
    const bg2=ctx.createLinearGradient(b.x,base-b.h,b.x,base);
    bg2.addColorStop(0,i%3===0?'#0a0812':'#0c0a16');bg2.addColorStop(1,'#0e0c18');
    ctx.fillStyle=bg2;ctx.fillRect(b.x,base-b.h,b.w,b.h);
    for(let wy=1;wy<Math.floor(b.h/22);wy++)for(let wx=1;wx<Math.floor(b.w/16);wx++){
      if(hash(i*100+wy,wx)>0.55)continue;
      ctx.fillStyle=`rgba(255,230,180,${hash(i*50+wy,wx*3)*0.25+0.03})`;
      ctx.fillRect(b.x+wx*14+2,base-b.h+wy*20+4,6,8);}});
  
  // Neons
  ctx.save();ctx.shadowColor='#D4607A';ctx.shadowBlur=25;ctx.fillStyle='rgba(212,96,122,0.6)';ctx.font='bold 16px Arial';ctx.fillText('BAR',210,base-200);ctx.restore();
  ctx.save();ctx.shadowColor='#5A9EC7';ctx.shadowBlur=25;ctx.fillStyle='rgba(90,158,199,0.5)';ctx.font='bold 16px Arial';ctx.fillText('OPEN',890,base-230);ctx.restore();
  
  // Court with low light
  const nL=w2s(-50,0),nR=w2s(50,0),fL=w2s(-50,100),fR=w2s(50,100);
  ctx.save();ctx.beginPath();ctx.moveTo(nL.x,nL.y);ctx.lineTo(fL.x,fL.y);ctx.lineTo(fR.x,fR.y);ctx.lineTo(nR.x,nR.y);ctx.closePath();ctx.clip();
  ctx.fillStyle='#3a352c';ctx.fillRect(0,VPy-20,W,H);
  ctx.globalAlpha=0.5;const courtH=nL.y-fL.y;
  for(let r=0;r<15;r++){const ry=r/15,y1=fL.y+courtH*ry,y2=fL.y+courtH*(ry+0.07);
    const wL=fL.x+(nL.x-fL.x)*ry,wR=fR.x+(nR.x-fR.x)*ry;ctx.drawImage(texCvs,0,r*34,512,35,wL,y1,wR-wL,y2-y1);}
  ctx.globalAlpha=1;
  // Dim light pools
  ctx.save();ctx.globalCompositeOperation='lighter';
  [{wx:-38,wy:15},{wx:38,wy:15},{wx:-35,wy:80},{wx:35,wy:80}].forEach(l=>{
    const ls=w2s(l.wx,l.wy),lr=scl(l.wy)*60;
    const gr=ctx.createRadialGradient(ls.x,ls.y,0,ls.x,ls.y,lr);
    gr.addColorStop(0,'rgba(255,245,220,0.03)');gr.addColorStop(1,'rgba(255,240,214,0)');
    ctx.fillStyle=gr;ctx.fillRect(ls.x-lr,ls.y-lr,lr*2,lr*2);});ctx.restore();
  ctx.restore();
  
  // Lights (dim)
  ctx.save();ctx.globalCompositeOperation='lighter';
  [{x:100,y:H*0.06},{x:W-100,y:H*0.06},{x:280,y:H*0.04},{x:W-280,y:H*0.04}].forEach(l=>{
    ctx.globalAlpha=0.008;ctx.fillStyle=LIGHT;
    ctx.beginPath();ctx.moveTo(l.x-8,l.y);ctx.lineTo(l.x-60,H*0.7);ctx.lineTo(l.x+60,H*0.7);ctx.lineTo(l.x+8,l.y);ctx.closePath();ctx.fill();
    ctx.globalAlpha=0.5;const sg=ctx.createRadialGradient(l.x,l.y,0,l.x,l.y,25);
    sg.addColorStop(0,'rgba(255,252,245,0.8)');sg.addColorStop(1,'rgba(255,240,214,0)');
    ctx.fillStyle=sg;ctx.beginPath();ctx.arc(l.x,l.y,25,0,6.28);ctx.fill();});ctx.restore();
  
  // Dust
  ctx.save();ctx.globalCompositeOperation='lighter';
  for(let i=0;i<40;i++){ctx.globalAlpha=0.04+Math.random()*0.06;ctx.fillStyle=LIGHT;
    ctx.beginPath();ctx.arc(Math.random()*W,Math.random()*H,1+Math.random()*2,0,6.28);ctx.fill();}ctx.restore();
  
  // Vignette
  const vigG=ctx.createRadialGradient(W/2,H/2,W*0.25,W/2,H/2,W*0.72);
  vigG.addColorStop(0,'rgba(0,0,0,0)');vigG.addColorStop(0.6,'rgba(0,0,0,0)');vigG.addColorStop(0.85,'rgba(0,0,0,0.25)');vigG.addColorStop(1,'rgba(0,0,0,0.6)');
  ctx.fillStyle=vigG;ctx.fillRect(0,0,W,H);
  
  // Letterbox
  ctx.fillStyle='#000';ctx.fillRect(0,0,W,H*0.08);ctx.fillRect(0,H*0.92,W,H*0.08);
  
  // Title text
  ctx.save();ctx.textAlign='center';
  ctx.fillStyle=GOLD;ctx.font='900 88px Arial';
  ctx.shadowColor='rgba(255,182,18,0.5)';ctx.shadowBlur=40;
  ctx.fillText('NFL STREET REBORN',W/2,H/2-20);
  ctx.shadowBlur=0;ctx.fillStyle='rgba(255,240,214,0.6)';ctx.font='700 26px Arial';ctx.letterSpacing='10px';
  ctx.fillText('BILLS  vs  CHIEFS',W/2,H/2+25);
  ctx.fillStyle='rgba(255,182,18,0.5)';ctx.font='14px Arial';
  ctx.fillText('CLICK ANYWHERE TO BEGIN',W/2,H/2+80);
  ctx.restore();
});

// === SCREENSHOT 2: GAMEPLAY - LINE OF SCRIMMAGE ===
renderScene('screenshot_gameplay', (ctx) => {
  // Sky
  const g=ctx.createLinearGradient(0,0,0,H*0.5);
  g.addColorStop(0,'#060410');g.addColorStop(0.15,'#0e0a1e');g.addColorStop(0.35,'#1a1235');
  g.addColorStop(0.55,'#2a1a3a');g.addColorStop(0.75,'#452535');g.addColorStop(0.9,'#6a3525');g.addColorStop(1,'#8a4520');
  ctx.fillStyle=g;ctx.fillRect(0,0,W,H*0.5);
  ctx.fillStyle='#000';ctx.fillRect(0,H*0.5,W,H*0.5);
  
  // Stars
  for(let i=0;i<25;i++){ctx.fillStyle=`rgba(255,255,255,${0.15+Math.random()*0.2})`;
    ctx.beginPath();ctx.arc(hash(i,0)*W,hash(i,1)*H*0.28,0.6,0,6.28);ctx.fill();}
  // Moon
  ctx.save();ctx.globalCompositeOperation='lighter';
  const mg=ctx.createRadialGradient(W*0.82,H*0.08,0,W*0.82,H*0.08,80);
  mg.addColorStop(0,'rgba(255,250,240,0.12)');mg.addColorStop(1,'rgba(0,0,0,0)');
  ctx.fillStyle=mg;ctx.beginPath();ctx.arc(W*0.82,H*0.08,80,0,6.28);ctx.fill();
  ctx.fillStyle='rgba(230,225,215,0.5)';ctx.beginPath();ctx.arc(W*0.82,H*0.08,8,0,6.28);ctx.fill();ctx.restore();
  // Clouds
  for(let c=0;c<12;c++){const cx2=100+c*160,cy2=60+Math.sin(c*1.5)*50;
    for(let b=0;b<5;b++){const bx=cx2+(hash(c,b)-0.5)*120,by=cy2+(hash(b,c)-0.5)*25;
      const cg=ctx.createRadialGradient(bx,by,0,bx,by,35+hash(c*b,1)*25);
      cg.addColorStop(0,'rgba(200,195,190,0.1)');cg.addColorStop(1,'rgba(0,0,0,0)');
      ctx.fillStyle=cg;ctx.beginPath();ctx.ellipse(bx,by,45+hash(c,b*2)*35,18+hash(b*2,c)*12,0,0,6.28);ctx.fill();}}
  
  // Buildings
  const base=H*0.42;
  const dbs=[{x:-10,w:90,h:120},{x:90,w:50,h:85},{x:160,w:110,h:165},{x:290,w:70,h:140},
    {x:380,w:100,h:195},{x:500,w:60,h:110},{x:580,w:130,h:220},{x:730,w:80,h:150},
    {x:830,w:100,h:185},{x:950,w:70,h:130},{x:1040,w:120,h:250},{x:1180,w:90,h:170},
    {x:1290,w:80,h:200},{x:1390,w:110,h:155},{x:1520,w:75,h:230},{x:1620,w:100,h:185},
    {x:1740,w:90,h:210},{x:1850,w:70,h:140}];
  dbs.forEach((b,i)=>{
    ctx.fillStyle=i%3===0?'#0a0812':'#0c0a16';ctx.fillRect(b.x,base-b.h,b.w,b.h);
    for(let wy=1;wy<Math.floor(b.h/22);wy++)for(let wx=1;wx<Math.floor(b.w/16);wx++){
      if(hash(i*100+wy,wx)>0.55)continue;
      ctx.fillStyle=`rgba(255,230,180,${hash(i*50+wy,wx*3)*0.2+0.03})`;
      ctx.fillRect(b.x+wx*14+2,base-b.h+wy*20+4,6,8);}});
  ctx.save();ctx.shadowColor='#D4607A';ctx.shadowBlur=20;ctx.fillStyle='rgba(212,96,122,0.5)';ctx.font='bold 16px Arial';ctx.fillText('BAR',210,base-200);ctx.restore();
  ctx.save();ctx.shadowColor='#5A9EC7';ctx.shadowBlur=20;ctx.fillStyle='rgba(90,158,199,0.5)';ctx.font='bold 16px Arial';ctx.fillText('OPEN',890,base-230);ctx.restore();
  
  // Court
  const nL=w2s(-50,0),nR=w2s(50,0),fL=w2s(-50,100),fR=w2s(50,100);
  ctx.save();ctx.beginPath();ctx.moveTo(nL.x,nL.y);ctx.lineTo(fL.x,fL.y);ctx.lineTo(fR.x,fR.y);ctx.lineTo(nR.x,nR.y);ctx.closePath();ctx.clip();
  ctx.fillStyle='#3a352c';ctx.fillRect(0,VPy-20,W,H);
  ctx.globalAlpha=0.6;const courtH2=nL.y-fL.y;
  for(let r=0;r<15;r++){const ry=r/15,y1=fL.y+courtH2*ry,y2=fL.y+courtH2*(ry+0.07);
    const wL=fL.x+(nL.x-fL.x)*ry,wR=fR.x+(nR.x-fR.x)*ry;ctx.drawImage(texCvs,0,r*34,512,35,wL,y1,wR-wL,y2-y1);}
  ctx.globalAlpha=1;
  // Chiefs endzone
  const ezN=w2s(-50,85),ezNR=w2s(50,85),ezF=w2s(-50,100),ezFR=w2s(50,100);
  ctx.fillStyle='rgba(212,42,60,0.7)';ctx.beginPath();ctx.moveTo(ezN.x,ezN.y);ctx.lineTo(ezF.x,ezF.y);ctx.lineTo(ezFR.x,ezFR.y);ctx.lineTo(ezNR.x,ezNR.y);ctx.closePath();ctx.fill();
  const em=w2s(0,93),es=scl(93);ctx.save();ctx.translate(em.x,em.y);ctx.scale(es*1.6,es*0.5);
  ctx.fillStyle='rgba(255,255,255,0.65)';ctx.font='900 48px Arial';ctx.textAlign='center';ctx.fillText('CHIEFS',0,8);ctx.restore();
  // Bills endzone
  ctx.fillStyle='rgba(26,92,176,0.5)';const bN=w2s(-50,0),bF=w2s(-50,14),bNR=w2s(50,0),bFR=w2s(50,14);
  ctx.beginPath();ctx.moveTo(bN.x,bN.y);ctx.lineTo(bF.x,bF.y);ctx.lineTo(bFR.x,bFR.y);ctx.lineTo(bNR.x,bNR.y);ctx.closePath();ctx.fill();
  // Yard lines
  for(let yd=20;yd<=80;yd+=10){const l=w2s(-45,yd),r2=w2s(45,yd),s=scl(yd);
    ctx.strokeStyle=`rgba(255,255,255,${0.06+s*0.05})`;ctx.lineWidth=Math.max(0.5,s*1.2);
    ctx.beginPath();ctx.moveTo(l.x,l.y);ctx.lineTo(r2.x,r2.y);ctx.stroke();}
  // Light pools
  ctx.save();ctx.globalCompositeOperation='lighter';
  [{wx:-38,wy:15},{wx:38,wy:15},{wx:-35,wy:80},{wx:35,wy:80},{wx:0,wy:50}].forEach(l=>{
    const ls=w2s(l.wx,l.wy),lr=scl(l.wy)*80;
    const gr=ctx.createRadialGradient(ls.x,ls.y,0,ls.x,ls.y,lr);
    gr.addColorStop(0,'rgba(255,245,220,0.05)');gr.addColorStop(1,'rgba(255,240,214,0)');
    ctx.fillStyle=gr;ctx.fillRect(ls.x-lr,ls.y-lr,lr*2,lr*2);});ctx.restore();
  ctx.restore();
  
  // Players at line of scrimmage
  function drawPlayer(sx,sy,scale,color,num,pose,hasBall){
    const s=scale*60;if(s<8)return;ctx.save();ctx.translate(sx,sy);
    // Shadow
    ctx.save();ctx.scale(1,0.2);ctx.fillStyle='rgba(0,0,0,0.3)';ctx.beginPath();ctx.ellipse(0,s*0.1,s*0.4,s*0.15,0,0,6.28);ctx.fill();ctx.restore();
    if(hasBall){const bg3=ctx.createRadialGradient(0,-s*0.3,0,0,-s*0.3,s*0.8);bg3.addColorStop(0,'rgba(255,182,18,0.08)');bg3.addColorStop(1,'rgba(0,0,0,0)');ctx.fillStyle=bg3;ctx.beginPath();ctx.arc(0,-s*0.3,s*0.8,0,6.28);ctx.fill();}
    const lean=pose==='run'?-0.12:0;ctx.rotate(lean);
    const lh=s*0.35,tw=s*0.32,th=s*0.3,lw=s*0.1,ls2=s*0.08;
    const isBlue=color===BLU;
    // Legs
    ctx.fillStyle='#ddd';ctx.fillRect(-ls2-lw/2,-lh,lw,lh);ctx.fillRect(ls2-lw/2,-lh,lw,lh);
    ctx.fillStyle='#111';ctx.fillRect(-ls2-lw*0.6,-2,lw*1.2,3);ctx.fillRect(ls2-lw*0.6,-2,lw*1.2,3);
    // Torso
    const jb=isBlue?[26,92,176]:[212,42,60];
    const jg=ctx.createLinearGradient(-tw*1.2,0,tw*1.2,0);
    jg.addColorStop(0,`rgb(${jb.map(v=>Math.floor(v*0.6)).join(',')})`);
    jg.addColorStop(0.4,`rgb(${jb.join(',')})`);
    jg.addColorStop(0.6,`rgb(${jb.map(v=>Math.min(255,Math.floor(v*1.15))).join(',')})`);
    jg.addColorStop(1,`rgb(${jb.map(v=>Math.floor(v*0.55)).join(',')})`);
    ctx.fillStyle=jg;ctx.beginPath();
    ctx.moveTo(-tw*0.8,-lh);ctx.quadraticCurveTo(-tw*1.15,-lh-th*0.5,-tw*1.15,-lh-th);
    ctx.lineTo(tw*1.15,-lh-th);ctx.quadraticCurveTo(tw*1.15,-lh-th*0.5,tw*0.8,-lh);ctx.closePath();ctx.fill();
    // Number
    if(num&&s>16){ctx.fillStyle='rgba(255,255,255,0.85)';ctx.font=`bold ${Math.max(8,s*0.18)}px Arial`;ctx.textAlign='center';ctx.fillText(num,0,-lh-th*0.38);}
    // Helmet
    const hY=-lh-th-s*0.09,hR=s*0.12;
    const hc=isBlue?[26,74,144]:[176,34,46];
    const hg=ctx.createRadialGradient(hR*0.3,hY-hR*0.3,hR*0.2,0,hY,hR);
    hg.addColorStop(0,`rgb(${hc.map(v=>Math.min(255,Math.floor(v*1.4))).join(',')})`);
    hg.addColorStop(0.5,`rgb(${hc.join(',')})`);
    hg.addColorStop(1,`rgb(${hc.map(v=>Math.floor(v*0.5)).join(',')})`);
    ctx.fillStyle=hg;ctx.beginPath();ctx.arc(0,hY,hR,0,6.28);ctx.fill();
    ctx.strokeStyle='rgba(180,180,180,0.6)';ctx.lineWidth=Math.max(0.8,s*0.02);
    ctx.beginPath();ctx.arc(hR*0.15,hY+hR*0.15,hR*0.55,-0.4,0.9);ctx.stroke();
    // Rim light
    ctx.save();ctx.globalCompositeOperation='lighter';ctx.globalAlpha=0.12;ctx.strokeStyle='rgba(255,245,220,0.5)';ctx.lineWidth=Math.max(1,s*0.03);
    ctx.beginPath();ctx.moveTo(-tw*1.15,-lh-th);ctx.lineTo(-ls2-lw/2,-2);ctx.stroke();
    ctx.beginPath();ctx.moveTo(tw*1.15,-lh-th);ctx.lineTo(ls2+lw/2,-2);ctx.stroke();ctx.restore();
    ctx.restore();
  }
  
  // Bills offense (blue)
  const offense=[{wx:0,wy:30,n:'17'},{wx:-14,wy:30,n:'73'},{wx:14,wy:30,n:'66'},{wx:-26,wy:30,n:'77'},{wx:26,wy:30,n:'70'},
    {wx:22,wy:24,n:'14'},{wx:-22,wy:24,n:'28'}];
  const defense=[{wx:-10,wy:34,n:'95'},{wx:10,wy:34,n:'55'},{wx:0,wy:36,n:'38'},
    {wx:-22,wy:38,n:'22'},{wx:22,wy:38,n:'10'},{wx:0,wy:46,n:'32'},{wx:16,wy:52,n:'4'}];
  
  const all=[...offense.map(p=>({...p,c:BLU})),...defense.map(p=>({...p,c:RED}))].sort((a,b)=>a.wy-b.wy);
  all.forEach(p=>{const sp=w2s(p.wx,p.wy),s=scl(p.wy);drawPlayer(sp.x,sp.y,s,p.c,p.n,'st',p.n==='17');});
  
  // Crowd
  [-1,1].forEach(side=>{for(let yd=5;yd<=90;yd+=5){const pos=w2s(side*55,yd),s=scl(yd);if(s<0.2)continue;
    for(let i=0;i<Math.floor(2.5*s);i++){const cx2=pos.x+side*(6+i*8*s),cy2=pos.y-s*40-i*s*5;
      ctx.fillStyle=`rgba(${60+hash(yd,i)*120},${40+hash(i,yd)*80},${40+hash(yd*i,1)*60},0.7)`;
      ctx.fillRect(cx2-s*4,cy2-s*7,s*8,s*12);
      ctx.fillStyle=`rgba(${150+hash(yd,i)*60},${120+hash(i,yd)*30},90,0.9)`;
      ctx.beginPath();ctx.arc(cx2,cy2-s*10,s*3.5,0,6.28);ctx.fill();}}});
  
  // Fence
  [-1,1].forEach(side=>{ctx.strokeStyle='rgba(110,105,98,0.35)';ctx.lineWidth=0.5;
    for(let yd=0;yd<100;yd+=8){const p1=w2s(side*50,yd),s1=scl(yd);if(s1<0.2)continue;
      const fh=s1*60;for(let r=0;r<4;r++){const by=p1.y-fh+r*(fh/4);
        ctx.beginPath();ctx.moveTo(p1.x,by+fh/8);ctx.lineTo(p1.x+side*3*s1,by);ctx.lineTo(p1.x,by-fh/8);ctx.stroke();}}
    for(let yd=0;yd<=100;yd+=20){const p=w2s(side*50,yd),s=scl(yd),pw=Math.max(2,s*4);
      ctx.fillStyle='#555';ctx.fillRect(p.x-pw/2,p.y-s*65,pw,s*65);}});
  
  // Lights
  ctx.save();ctx.globalCompositeOperation='lighter';
  [{x:100,y:H*0.06},{x:W-100,y:H*0.06},{x:280,y:H*0.04},{x:W-280,y:H*0.04},{x:W/2-200,y:H*0.03},{x:W/2+200,y:H*0.03}].forEach(l=>{
    ctx.globalAlpha=0.012;ctx.fillStyle=LIGHT;ctx.beginPath();ctx.moveTo(l.x-8,l.y);ctx.lineTo(l.x-70,H*0.7);ctx.lineTo(l.x+70,H*0.7);ctx.lineTo(l.x+8,l.y);ctx.closePath();ctx.fill();
    for(let p=0;p<3;p++){const sz=[50,25,8][p],al=[0.12,0.35,0.85][p];ctx.globalAlpha=al;
      const sg=ctx.createRadialGradient(l.x,l.y,0,l.x,l.y,sz);sg.addColorStop(0,'rgba(255,252,245,0.9)');sg.addColorStop(1,'rgba(255,240,214,0)');
      ctx.fillStyle=sg;ctx.beginPath();ctx.arc(l.x,l.y,sz,0,6.28);ctx.fill();}
    ctx.globalAlpha=0.04;ctx.fillStyle=LIGHT;ctx.fillRect(l.x-100,l.y-0.5,200,1);});ctx.restore();
  
  // Dust
  ctx.save();ctx.globalCompositeOperation='lighter';
  for(let i=0;i<50;i++){ctx.globalAlpha=0.03+Math.random()*0.05;ctx.fillStyle=LIGHT;
    ctx.beginPath();ctx.arc(Math.random()*W,Math.random()*H,0.8+Math.random()*2,0,6.28);ctx.fill();}ctx.restore();
  
  // Bloom
  ctx.save();ctx.globalCompositeOperation='lighter';ctx.globalAlpha=0.06;ctx.filter='blur(12px)';
  // Simulate bloom with light areas
  [{x:100,y:H*0.06},{x:W-100,y:H*0.06},{x:280,y:H*0.04},{x:W-280,y:H*0.04}].forEach(l=>{
    const bg4=ctx.createRadialGradient(l.x,l.y,0,l.x,l.y,80);bg4.addColorStop(0,'rgba(255,250,240,0.4)');bg4.addColorStop(1,'rgba(0,0,0,0)');
    ctx.fillStyle=bg4;ctx.beginPath();ctx.arc(l.x,l.y,80,0,6.28);ctx.fill();});
  ctx.filter='none';ctx.restore();
  
  // Vignette
  const vigG=ctx.createRadialGradient(W/2,H/2,W*0.25,W/2,H/2,W*0.72);
  vigG.addColorStop(0,'rgba(0,0,0,0)');vigG.addColorStop(0.6,'rgba(0,0,0,0)');vigG.addColorStop(0.85,'rgba(0,0,0,0.25)');vigG.addColorStop(1,'rgba(0,0,0,0.6)');
  ctx.fillStyle=vigG;ctx.fillRect(0,0,W,H);
  
  // Color grade
  ctx.save();ctx.globalCompositeOperation='screen';ctx.globalAlpha=0.025;ctx.fillStyle='#3a2510';ctx.fillRect(0,0,W,H);ctx.restore();
  
  // HUD: Score bug
  ctx.save();ctx.fillStyle='rgba(10,8,5,0.9)';
  const sbx=20,sby=20,sbw=200,sbh=60;
  ctx.beginPath();ctx.roundRect(sbx,sby,sbw,sbh,8);ctx.fill();
  ctx.strokeStyle='rgba(255,182,18,0.25)';ctx.lineWidth=1;ctx.beginPath();ctx.roundRect(sbx,sby,sbw,sbh,8);ctx.stroke();
  ctx.font='900 16px Arial';ctx.fillStyle='#fff';ctx.fillText('BUF',sbx+30,sby+28);ctx.fillText('KC',sbx+120,sby+28);
  ctx.fillStyle=GOLD;ctx.font='900 26px Arial';ctx.fillText('14',sbx+70,sby+30);ctx.fillText('7',sbx+152,sby+30);
  ctx.fillStyle=BLU;ctx.fillRect(sbx+12,sby+12,4,22);ctx.fillStyle=RED;ctx.fillRect(sbx+108,sby+12,4,22);
  ctx.fillStyle='rgba(255,240,214,0.4)';ctx.font='10px Arial';ctx.textAlign='center';ctx.fillText('Q2 \u2022 1:34',sbx+sbw/2,sby+50);ctx.textAlign='left';
  ctx.restore();
  
  // Style gauge
  ctx.save();const gx=W-130,gy=H-130,gr2=40;
  ctx.beginPath();ctx.arc(gx,gy,gr2,0,6.28);ctx.strokeStyle='rgba(30,25,18,0.8)';ctx.lineWidth=8;ctx.stroke();
  const sa=-Math.PI/2,ea=sa+6.28*0.55;
  for(let i=0;i<=33;i++){const t2=i/60,a=sa+6.28*t2;ctx.beginPath();ctx.arc(gx,gy,gr2,a-0.05,a+0.05);
    ctx.strokeStyle=`rgb(${Math.floor(170+85*t2)},${Math.floor(40+160*t2)},${Math.floor(40-20*t2)})`;ctx.lineWidth=6;ctx.lineCap='round';ctx.stroke();}
  ctx.fillStyle=GOLD;ctx.font='bold 18px Arial';ctx.textAlign='center';ctx.fillText('32',gx,gy+2);
  ctx.font='8px Arial';ctx.fillStyle='rgba(255,240,214,0.35)';ctx.fillText('STYLE',gx,gy+14);ctx.restore();
});

console.log('All screenshots rendered!');
