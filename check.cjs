const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const elements=new Map(),el=()=>({style:{},classList:{add(){},remove(){}},appendChild(){},addEventListener(){},focus(){},getContext(){return {}},textContent:'',innerHTML:''});
const c={console,Math,setTimeout(){},clearTimeout(){},requestAnimationFrame(){},document:{getElementById(id){if(!elements.has(id))elements.set(id,el());return elements.get(id);},querySelectorAll(){return []},createElement:el,addEventListener(){}},window:{addEventListener(){}}};vm.createContext(c);vm.runInContext(fs.readFileSync(__dirname+'/game.js','utf8'),c);
function test(code){vm.runInContext(code,c);}
test(`s.paused=false;s.mode='play';for(let i=0;i<100;i++)update(.016);if(p.y!==530||!p.ground)throw Error('ground collision');jumpBuffer=.16;update(.016);if(p.vy>=0)throw Error('jump');`);
test(`reset();s.farm=true;s.energy=70;let f=forecast();if(f.demand!==70||f.energy!==0)throw Error('night consumption');s.farm=false;f=forecast();if(f.demand!==35)throw Error('power allocation');s.chapter=1;if(forecast().protected)throw Error('unshielded');s.up.shield=true;if(!forecast().protected)throw Error('shield');`);
test(`reset();s.paused=false;s.chapter=1;p.x=950;p.y=530;s.rad=50;update(1);if(s.rad>=50)throw Error('shelter');p.x=1400;p.y=500;const old=s.rad;update(.1);if(s.rad<=old)throw Error('exposure');`);
test(`reset();s.paused=false;p.x=3200;p.y=480;interact();if(!s.item||s.parts!==4)throw Error('equipment');p.x=215;s.energy=70;s.food=30;runNight();if(reportAction!=='next')throw Error('mission success');reset();s.item=true;s.energy=0;runNight();if(reportAction!=='retry')throw Error('retry');`);
test(`reset();s.parts=8;s.item=true;respawn('test');if(s.parts!==8||!s.item||s.o2!==100)throw Error('rescue');`);
assert.ok(elements.size);console.log('PASS: landing, jumping, energy allocation, radiation protection, equipment, mission outcomes, rescue');
