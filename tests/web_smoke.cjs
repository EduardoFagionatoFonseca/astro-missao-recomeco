// npm install playwright, then node tests/web_smoke.cjs
// Serve build/web on 127.0.0.1:8060 first. This exercises the actual exported game.
const assert = require('node:assert/strict');
const {chromium, devices} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');

(async () => {
  const browser = await chromium.launch({headless:true, channel:process.env.BROWSER_CHANNEL || 'chrome', args:['--autoplay-policy=no-user-gesture-required']});
  const results = [];
  try {
    for (const mobile of [false, true]) {
      const context = await browser.newContext(mobile ? {...devices['Pixel 7'], viewport:{width:915,height:412}} : {viewport:{width:1280,height:800}});
      const page = await context.newPage();
      const errors = [];
      page.on('pageerror', error => errors.push(String(error)));
      page.on('console', msg => {if (msg.type()==='error') errors.push(msg.text());});
      await page.goto('http://127.0.0.1:8060', {waitUntil:'networkidle'});
      await page.locator('#status').waitFor({state:'hidden',timeout:60000});
      await page.waitForTimeout(2200);
      await page.screenshot({path:`docs/web-${mobile?'mobile':'desktop'}-menu.png`});
      // The game renders UI to a canvas; reference coordinates use the 1440x900 canvas.
      const click = async (x,y) => {
        const box = await page.locator('canvas').boundingBox();
        const logicalWidth = mobile ? 900*915/412 : 1440;
        const sx = box.x + (x + (logicalWidth-1440)/2) / logicalWidth * box.width;
        const sy = box.y + y / 900 * box.height;
        if (mobile) await page.touchscreen.tap(sx,sy); else await page.mouse.click(sx,sy);
      };
      const menuClick = async offset => {
        const logicalWidth = mobile ? 900*915/412 : 1440;
        await click(logicalWidth*.085+offset-(logicalWidth-1440)/2,605);
      };
      await menuClick(481); // Gear beside Start, anchored to the left menu column.
      await page.waitForTimeout(300);
      await click(720,440); // Music gain, independent from alerts and interactions.
      await page.screenshot({path:`docs/web-${mobile?'mobile':'desktop'}-settings.png`});
      await click(720,745);
      if (!mobile) {
        await page.waitForTimeout(800); // Allow the browser's user filesystem to flush.
        await page.reload({waitUntil:'networkidle'});
        await page.locator('#status').waitFor({state:'hidden',timeout:60000});
        await page.waitForTimeout(700);
        await menuClick(481);
        await page.waitForTimeout(250);
        await page.screenshot({path:'docs/web-desktop-settings-restored.png'});
        await click(720,745);
      }
      await menuClick(210);
      await page.waitForTimeout(1800);
      await page.screenshot({path:`docs/web-${mobile?'mobile':'desktop'}-video.png`});
      // Skip at the right edge, anchored to viewport rather than reference width.
      const box = await page.locator('canvas').boundingBox();
      if (mobile) await page.touchscreen.tap(box.x+box.width-65,box.y+35);
      else await page.keyboard.press('Space');
      await page.waitForTimeout(600);
      await page.screenshot({path:`docs/web-${mobile?'mobile':'desktop'}-briefing.png`});
      await click(720,765);
      await page.waitForTimeout(350);
      await page.screenshot({path:`docs/web-${mobile?'mobile':'desktop'}-briefing2.png`});
      await click(900,765);
      await page.waitForTimeout(700);
      await page.screenshot({path:`docs/web-${mobile?'mobile':'desktop'}-world.png`});
      if (mobile) await click(720,825); else await page.keyboard.press('e');
      await page.waitForTimeout(700);
      await page.screenshot({path:`docs/web-${mobile?'mobile':'desktop'}-base.png`});
      if (!mobile) {
        await page.keyboard.down('w'); await page.waitForTimeout(1050); await page.keyboard.up('w');
        await page.keyboard.down('a'); await page.waitForTimeout(800); await page.keyboard.up('a');
        await page.keyboard.down('w'); await page.waitForTimeout(330); await page.keyboard.up('w');
        await page.keyboard.press('e');
        await page.waitForTimeout(300);
        await page.screenshot({path:'docs/web-desktop-power.png'});
        // New missions start with power online; this panel is read-only until 30%.
        await page.screenshot({path:'docs/web-desktop-power-online.png'});
        await page.keyboard.press('Escape');
      } else {
        // Exercise a real held touch on the virtual joystick, then release.
        const cdp = await context.newCDPSession(page);
        const scale = box.height / 900;
        const point = (x,y) => ({x:box.x+x*scale,y:box.y+y*scale,id:11});
        await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[point(172,726)]});
        await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[point(102,656)]});
        await page.waitForTimeout(1050);
        await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
        await page.screenshot({path:'docs/web-mobile-movement.png'});
      }
      assert.equal(errors.length,0,errors.join('\n'));
      results.push({device:mobile?'Pixel 7 emulation':'desktop Chrome',errors});
      await context.close();
    }
    console.log(JSON.stringify(results,null,2));
  } finally { await browser.close(); }
})().catch(error=>{console.error(error);process.exitCode=1;});
