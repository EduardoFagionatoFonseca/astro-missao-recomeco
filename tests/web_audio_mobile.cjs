// Actual Web Audio output and multi-touch gameplay, with normal browser autoplay rules.
const assert=require('node:assert/strict');
const {chromium,devices}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const dot=(a,b)=>a.reduce((s,v,i)=>s+v*b[i],0);
const unit=a=>{const l=Math.hypot(...a);return a.map(v=>v/l);};
const distance=(a,b)=>Math.acos(Math.max(-1,Math.min(1,dot(a,b))))*12;

(async()=>{
 const browser=await chromium.launch({headless:true,channel:process.env.BROWSER_CHANNEL||'chrome'});
 try {
  const context=await browser.newContext({...devices['Pixel 7'],viewport:{width:915,height:412}});
  const page=await context.newPage(); const errors=[];
  page.on('pageerror',e=>errors.push(String(e)));
  page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
  await page.addInitScript(()=>{
   window.__audioMeters=[];const connect=AudioNode.prototype.connect;
   AudioNode.prototype.connect=function(dest,...args){
    if(dest instanceof AudioDestinationNode){const meter=this.context.createAnalyser();meter.fftSize=2048;window.__audioMeters.push(meter);connect.call(this,meter);return connect.call(meter,dest,...args);}
    return connect.call(this,dest,...args);
   };
   window.__audioLevel=()=>Math.max(0,...window.__audioMeters.map(m=>{const d=new Float32Array(m.fftSize);m.getFloatTimeDomainData(d);return Math.sqrt(d.reduce((s,v)=>s+v*v,0)/d.length);}));
  });
  await page.goto('http://127.0.0.1:8060/?qa=1',{waitUntil:'networkidle'});
  await page.locator('#status').waitFor({state:'hidden',timeout:60000});
  await page.waitForFunction(()=>window.__astroQA);
  const box=await page.locator('canvas').boundingBox(), scale=box.height/900, width=box.width/scale;
  const click=async(x,y)=>page.touchscreen.tap(box.x+(x+(width-1440)/2)*scale,box.y+y*scale);
  const level=async()=>{let peak=0;for(let i=0;i<8;i++){peak=Math.max(peak,await page.evaluate(()=>window.__audioLevel()));await page.waitForTimeout(100);}return peak;};
  await click(1074,782);await page.waitForTimeout(250);
  assert(await level()>0.0001,'Menu music must produce an audible signal after a real touch.');
  // Master really silences every output, and restoring it restores sound.
  await click(300,310);await page.waitForTimeout(200);
  assert(await level()<0.00001,'Master zero should be silent.');
  await click(1140,310);await click(720,745);await click(720,782);
  await page.waitForTimeout(700);assert(await level()>0.0001,'Video audio must remain audible.');
  await page.touchscreen.tap(box.x+box.width-65,box.y+35);
  await page.waitForTimeout(250);await click(720,765);await page.waitForTimeout(250);await click(900,765);
  await page.waitForFunction(()=>window.__astroQA?.playing&&window.__astroQA.enabled);
  assert(await level()>0.0001,'Exploration MP3 must produce audio, not just report playing.');
  let state=await page.evaluate(()=>window.__astroQA);assert(state.mobile);
  const cdp=await context.newCDPSession(page);
  const point=(x,y,id)=>({x:box.x+x*scale,y:box.y+y*scale,id});
  let stick=point(172,726,11), held=false;
  const move=async(x,y)=>{
   stick=point(172+x*90,726-y*90,11);
   if(!held){await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[point(172,726,11)]});held=true;}
   await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[stick]});
  };
  const release=async()=>{await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});held=false;await page.waitForTimeout(150);};
  // All cardinal directions and diagonals move; joystick normalizes diagonal speed.
  const travel=[];
  for(const raw of [[1,0],[-1,0],[0,1],[0,-1],[1,1],[-1,-1],[-1,1],[1,-1]]){
   const d=unit(raw),before=(await page.evaluate(()=>window.__astroQA)).normal;
   await move(...d);await page.waitForTimeout(220);await release();
   state=await page.evaluate(()=>window.__astroQA);travel.push(distance(before,state.normal));
   assert(travel.at(-1)>0.25,'Every touch direction must move the player.');assert.equal(state.stick,-1);
  }
  assert(Math.max(...travel)/Math.min(...travel)<2,'Diagonals must not double movement speed.');
  const steer=async target=>{
   state=await page.evaluate(()=>window.__astroQA);
   const tangent=unit(target.map((v,i)=>v-state.normal[i]*dot(target,state.normal)));
   await move(dot(tangent,state.right),dot(tangent,state.forward));
  };
  const platform=state.platform;
  for(let i=0;i<40;i++){
   state=await page.evaluate(()=>window.__astroQA);
   if(distance(state.normal,platform)<1.15)break;
   await steer(platform);await page.waitForTimeout(100);
  }
  state=await page.evaluate(()=>window.__astroQA);
  assert(distance(state.normal,platform)<1.5,'Reach the practice ledge by joystick.');
  await steer(platform);
  const jump=point(width-152,627,22);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[stick,jump]});
  await page.waitForTimeout(170);
  state=await page.evaluate(()=>window.__astroQA);assert(state.hop>0.05&&state.stick===11,'Move and jump together with two fingers.');
  await page.screenshot({path:'docs/web-mobile-jump.png'});
  await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[stick]});
  for(let i=0;i<16;i++){
   state=await page.evaluate(()=>window.__astroQA);
   if(distance(state.normal,platform)<0.35)break;
   await steer(platform);await page.waitForTimeout(70);
  }
  await release();await page.waitForTimeout(1000);
  state=await page.evaluate(()=>window.__astroQA);
  assert(state.floor>0.3&&state.hop<0.01,'Land on the raised platform instead of clipping through it.');
  await page.screenshot({path:'docs/web-mobile-platform.png'});
  // Return to the base, enter by touch, and exercise free indoor movement.
  for(let i=0;i<45;i++){
   state=await page.evaluate(()=>window.__astroQA);
   if(distance(state.normal,state.camp)<1.5)break;
   await steer(state.camp);await page.waitForTimeout(90);
  }
  await release();await click(720,825);await page.waitForTimeout(700);
  state=await page.evaluate(()=>window.__astroQA);assert(state.inside,'Touch action enters the shelter.');
  assert(await level()>0.0001,'Base MP3 must produce real output.');
  const before=state.position;await move(1,0);await page.waitForTimeout(350);await release();
  state=await page.evaluate(()=>window.__astroQA);assert(Math.hypot(...state.position.map((v,i)=>v-before[i]))>0.3,'Joystick also moves indoors.');
  await page.screenshot({path:'docs/web-mobile-audio-base.png'});
  await move(1,0);
  await page.setViewportSize({width:412,height:915});
  await page.waitForTimeout(450);
  state=await page.evaluate(()=>window.__astroQA);
  assert(!state.enabled&&state.stick===-1,'Rotating to portrait cancels the held joystick and suspends movement.');
  assert.deepEqual(errors,[]);
  console.log(JSON.stringify({audio:'measured menu/video/world/base and Master silence/restore',mobile:'8 directions, diagonals, release, two-finger jump, ledge landing and indoor movement',travel,errors},null,2));
  await context.close();
 } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
