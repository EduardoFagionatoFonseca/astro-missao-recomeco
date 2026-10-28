// Serve build/web on 127.0.0.1:8060. Uses QA geometry from the actual canvas.
const assert = require('node:assert/strict');
const {chromium, devices} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
(async () => {
  const browser = await chromium.launch({headless:true, channel:process.env.BROWSER_CHANNEL || 'chrome'});
  try {
    for (const viewport of [{width:915,height:412}, {width:667,height:375}, {width:844,height:390}]) {
      const context = await browser.newContext({...devices['Pixel 7'], viewport});
      const page = await context.newPage();
      const errors = [];
      page.on('pageerror', e => errors.push(String(e)));
      await page.goto('http://127.0.0.1:8060/?qa', {waitUntil:'networkidle'});
      await page.locator('#status').waitFor({state:'hidden', timeout:60000});
      await page.waitForFunction(() => window.__astroQA);
      const tap = async (x,y) => {
        const size = await page.evaluate(() => window.__astroQA.logical_size);
        const box = await page.locator('canvas').boundingBox();
        await page.touchscreen.tap(box.x+x/size[0]*box.width,box.y+y/size[1]*box.height);
      };
      const centeredTap = async (x,y) => {
        const size = await page.evaluate(() => window.__astroQA.logical_size);
        await tap(x+(size[0]-1440)/2,y);
      };
      await centeredTap(720,782);
      await page.waitForTimeout(1100);
      const box = await page.locator('canvas').boundingBox();
      await page.touchscreen.tap(box.x+box.width-65,box.y+35);
      await page.waitForTimeout(500);
      await centeredTap(720,765);
      await page.waitForTimeout(350);
      await centeredTap(900,765);
      await page.waitForFunction(() => window.__astroQA.enabled);
      const state = await page.evaluate(() => window.__astroQA);
      assert.equal(state.mobile,true);
      assert.equal(state.camera_fov,36);
      const [x,y,w,h] = state.action_rect;
      const bottomGap = (state.logical_size[1]-y-h)/state.logical_size[1]*box.height;
      assert.ok(bottomGap >= 85, `badge gap ${bottomGap}`);
      assert.ok(state.jump_rect[1] > 250, 'jump button stays below HUD');
      // Simulate a fixed badge; verify touch still reaches the jump action.
      await page.evaluate(() => {
        const badge = document.createElement('div');
        badge.style.cssText='position:fixed;right:16px;bottom:16px;width:100px;height:48px;background:#00ad9f;z-index:9999';
        badge.textContent='Netlify'; document.body.appendChild(badge);
      });
      await tap(state.jump_rect[0]+state.jump_rect[2]/2,state.jump_rect[1]+state.jump_rect[3]/2);
      await page.waitForFunction(() => window.__astroQA.hop > 0);
      await page.screenshot({path:`.runtime/mobile-${viewport.width}.png`});
      await page.setViewportSize({width:viewport.height,height:viewport.width});
      await page.waitForFunction(() => !window.__astroQA.enabled);
      await page.waitForTimeout(400);
      const paused = await page.evaluate(() => window.__astroQA);
      await page.waitForTimeout(1300);
      const later = await page.evaluate(() => window.__astroQA);
      assert.equal(later.oxygen,paused.oxygen);
      assert.equal(later.elapsed,paused.elapsed);
      await page.setViewportSize(viewport);
      await page.waitForFunction(() => window.__astroQA.enabled);
      assert.deepEqual(errors,[]);
      console.log(`PASS: ${viewport.width}x${viewport.height}, ${bottomGap.toFixed(1)}px badge clearance, closer camera, touch jump, rotation pause/resume`);
      await context.close();
    }
  } finally { await browser.close(); }
})().catch(e => {console.error(e);process.exitCode=1;});
