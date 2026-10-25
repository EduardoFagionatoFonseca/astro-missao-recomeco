// Run against build/web served at 127.0.0.1:8060.
const assert = require('node:assert/strict');
const {chromium, devices} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
(async () => {
  const browser = await chromium.launch({headless:true, channel:'chrome'});
  try {
    for (const mobile of [false,true]) {
      const context = await browser.newContext(mobile ? {...devices['Pixel 7'],viewport:{width:915,height:412}} : {viewport:{width:1280,height:800}});
      const page = await context.newPage();
      const errors = [];
      page.on('pageerror',e=>errors.push(String(e)));
      page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
      const load = async () => {
        await page.goto('http://127.0.0.1:8060/?qa=1');
        await page.locator('#status').waitFor({state:'hidden',timeout:60000});
        await page.waitForFunction(()=>window.__astroQA);
        await page.waitForTimeout(400);
      };
      const click = async (x,y) => {
        const width = mobile ? 900*915/412 : 1440;
        const box = await page.locator('canvas').boundingBox();
        const sx = box.x+(x+(width-1440)/2)/width*box.width;
        const sy = box.y+y/900*box.height;
        if(mobile)await page.touchscreen.tap(sx,sy); else await page.mouse.click(sx,sy);
        await page.waitForTimeout(200);
      };
      await load();
      await click(955,700); // Hard.
      await page.waitForFunction(()=>window.__astroQA.difficulty===2);
      await click(1074,795); // Settings.
      await page.waitForFunction(()=>window.__astroQA.settings);
      await click(975,650); // Language popup.
	  await page.screenshot({path:'.runtime/language-popup.png'});
	  await click(975,762); // English item.
      await page.waitForFunction(()=>window.__astroQA.language==='en');
      await page.screenshot({path:`.runtime/${mobile?'mobile':'desktop'}-english-settings.png`});
      await click(720,742); // Done.
      await page.waitForFunction(()=>!window.__astroQA.settings);
      await page.screenshot({path:`.runtime/${mobile?'mobile':'desktop'}-english-menu.png`});
      await click(720,795); // Start.
      await page.waitForFunction(()=>window.__astroQA.caption.startsWith('A storm'));
      await page.screenshot({path:`.runtime/${mobile?'mobile':'desktop'}-english-film.png`});
      await page.keyboard.press('Space');
      await page.waitForTimeout(300);
      await click(720,765);
      await page.screenshot({path:`.runtime/${mobile?'mobile':'desktop'}-english-guide.png`});
      await click(900,765);
      await page.waitForFunction(()=>window.__astroQA.playing);
      await page.waitForFunction(()=>window.__astroQA.guide==='Gather parts');
      await page.screenshot({path:`.runtime/${mobile?'mobile':'desktop'}-guidance.png`});
      assert.equal(errors.length,0,errors.join('\n'));
      await page.waitForTimeout(600);
      await page.reload();
      await page.locator('#status').waitFor({state:'hidden',timeout:60000});
      await page.waitForFunction(()=>window.__astroQA?.language==='en' && window.__astroQA?.difficulty===2);
      console.log(`PASS: ${mobile?'mobile':'desktop'} difficulty, language persistence, English film and first resource arrow`);
      await context.close();
    }
  } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
