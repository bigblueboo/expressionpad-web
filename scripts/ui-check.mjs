/** Browser regressions for the instrument UI. Run with npm run test:ui (Chrome required). */
import puppeteer from 'puppeteer-core'
import assert from 'node:assert/strict'
import { createServer } from 'vite'

const server = await createServer({
  server: { host: '127.0.0.1', port: 0, strictPort: false },
  logLevel: 'error',
})
let browser
try {
  await server.listen()
  const base = server.resolvedUrls.local[0]
  browser = await puppeteer.launch({ channel: 'chrome', headless: true })
  const page = await browser.newPage()
  const errors = []
  page.on('pageerror', (error) => errors.push(error.message))
  await page.setViewport({
    width: 390,
    height: 844,
    isMobile: true,
    hasTouch: true,
  })
  await page.goto(`${base}?rows=5&cols=7`, { waitUntil: 'networkidle0' })
  // System tracks live OS changes; explicit choices override them and persist.
  const theme = () => page.$eval('html', (el) => el.dataset.theme)
  await page.emulateMediaFeatures([
    { name: 'prefers-color-scheme', value: 'dark' },
  ])
  await page.waitForFunction(
    () => document.documentElement.dataset.theme === 'dark',
  )
  assert.equal(
    await page.$eval('.theme-control select', (el) => el.value),
    'system',
  )
  await page.select('.theme-control select', 'light')
  assert.equal(await theme(), 'light')
  await page.emulateMediaFeatures([
    { name: 'prefers-color-scheme', value: 'light' },
  ])
  await page.select('.theme-control select', 'dark')
  assert.equal(await theme(), 'dark')
  await page.reload({ waitUntil: 'networkidle0' })
  assert.equal(
    await theme(),
    'dark',
    'Explicit dark persists despite light OS preference',
  )
  assert.equal(
    await page.$eval('.theme-control select', (el) => el.value),
    'dark',
  )
  await page.select('.theme-control select', 'system')
  assert.equal(await theme(), 'light')
  await page.emulateMediaFeatures([
    { name: 'prefers-color-scheme', value: 'dark' },
  ])
  await page.waitForFunction(
    () => document.documentElement.dataset.theme === 'dark',
  )
  await page.select('.theme-control select', 'light')
  await page.select('.bank-select', 'appearance')
  assert.ok(
    await page.$eval('.panel', (el) => el.scrollTop > 0),
    'Bank selector reaches hidden controls',
  )
  await page.click('[data-tab="synth"]')
  await page.select(
    '[data-page="synth"] select[aria-label="preset"]',
    'Growl Dark',
  )
  assert.equal(
    await page.$eval('.display-preset', (el) => el.textContent),
    'Growl Dark',
  )
  await page.select('select[aria-label="Sound source"]', 'sampler')
  assert.equal(
    await page.$eval('.display-preset', (el) => el.textContent),
    'E-Piano',
  )
  await page.select('select[aria-label="Sound source"]', 'synth')
  await page.click('.chevron')
  assert.equal(await page.$eval('.panel', (el) => el.inert), true)
  assert.equal(await page.$eval('.panel-nav', (el) => el.hidden), true)
  await page.waitForFunction(
    () => document.querySelector('.pad-container').clientHeight > 500,
  )
  await page.reload({ waitUntil: 'networkidle0' })
  assert.equal(
    await page.$eval('.display-preset', (el) => el.textContent),
    'Growl Dark',
  )
  assert.equal(await page.$eval('.panel', (el) => el.inert), true)

  // Exercise the real renderer with a silent recording sink. This catches
  // coordinate/border regressions that pure layout tests cannot observe.
  await page.evaluate(async () => {
    const { Store } = await import('/src/core/state.ts')
    const { PadView } = await import('/src/ui/pad.ts')
    const root = document.createElement('div')
    Object.assign(root.style, {
      position: 'fixed',
      left: '0',
      top: '0',
      width: '350px',
      height: '260px',
      border: '5px solid grey',
      zIndex: '10',
    })
    document.body.appendChild(root)
    const store = new Store()
    const events = []
    const sink = {
      noteOn: (id, note) => events.push(['on', id, note]),
      noteOff: (id) => events.push(['off', id]),
      glide: (id, note) => events.push(['glide', id, note]),
      pressure: (id, value) => events.push(['pressure', id, value]),
      allOff: () => events.push(['allOff']),
    }
    window.uiFixture = {
      store,
      events,
      pad: new PadView(store, sink, root),
      root,
    }
  })
  for (const layout of [
    'square',
    'hex',
    'piano',
    'kbd-chromatic',
    'kbd-piano',
  ]) {
    const target = await page.evaluate((layout) => {
      const f = window.uiFixture
      f.store.set('pad.layout', layout)
      f.events.length = 0
      const key =
        f.pad.currentLayout.keys.find((k) => k.kind === 'black') ??
        f.pad.currentLayout.keys[0]
      const rect = f.pad.canvas.getBoundingClientRect()
      return { x: rect.left + key.cx, y: rect.top + key.cy, note: key.note }
    }, layout)
    await page.mouse.move(target.x, target.y)
    await page.mouse.down()
    assert.equal(
      await page.evaluate(() => window.uiFixture.events[0][2]),
      target.note,
      `${layout}: hit target`,
    )
    await page.evaluate(() => {
      Object.assign(window.uiFixture.root.style, {
        width: '300px',
        height: '220px',
        top: '15px',
      })
    })
    await page.waitForFunction(() => window.uiFixture.pad.canvas.width === 290)
    await page.mouse.move(target.x, target.y)
    const held = await page.evaluate(() => {
      const f = window.uiFixture
      return {
        voices: f.pad.tracker.active.size,
        pitch: [...f.pad.tracker.active.values()][0]?.pitch,
        lifecycle: f.events.filter((e) =>
          ['on', 'off', 'allOff'].includes(e[0]),
        ),
      }
    })
    assert.equal(held.voices, 1, `${layout}: held voice survives reflow`)
    assert.equal(
      held.lifecycle.length,
      1,
      `${layout}: reflow does not retrigger or cancel`,
    )
    assert.ok(
      Math.abs(held.pitch - target.note) < 1e-5,
      `${layout}: stationary pitch is preserved`,
    )
    await page.mouse.up()
    assert.equal(
      await page.evaluate(() => window.uiFixture.pad.tracker.active.size),
      0,
    )
    const accessible = await page.evaluate(() => {
      const f = window.uiFixture
      const expected = f.pad.currentLayout.keys.at(-1).note
      f.root.querySelector('.pad-accessible-keys button:last-child').click()
      return {
        expected,
        actual: f.events.filter((e) => e[0] === 'on').at(-1)?.[2],
      }
    })
    assert.equal(
      accessible.actual,
      accessible.expected,
      `${layout}: accessible key follows current geometry`,
    )
    await page.waitForFunction(
      () => window.uiFixture.pad.tracker.active.size === 0,
    )
    await page.evaluate(() => {
      Object.assign(window.uiFixture.root.style, {
        width: '350px',
        height: '260px',
        top: '0px',
      })
    })
    await page.waitForFunction(() => window.uiFixture.pad.canvas.width === 340)
  }
  // Accessible taps and typing notes have independent voice IDs and releases.
  await page.evaluate(async () => {
    const f = window.uiFixture
    const { KeyboardInput } = await import('/src/ui/keyboard.ts')
    f.keyboard = new KeyboardInput(() => f.pad.currentLayout, f.pad.tracker)
    f.keyboard.onKeyDown(new KeyboardEvent('keydown', { code: 'KeyZ' }))
    f.root.querySelector('.pad-accessible-keys button:last-child').click()
  })
  assert.equal(
    await page.evaluate(() => window.uiFixture.pad.tracker.active.size),
    2,
  )
  await page.waitForFunction(
    () => window.uiFixture.pad.tracker.active.size === 1,
  )
  await page.evaluate(() =>
    window.uiFixture.keyboard.onKeyUp(
      new KeyboardEvent('keyup', { code: 'KeyZ' }),
    ),
  )
  assert.equal(
    await page.evaluate(() => window.uiFixture.pad.tracker.active.size),
    0,
  )
  assert.deepEqual(errors, [])
  console.log(
    'UI checks passed: saved/system themes, bank/source controls, persistence, collapsed focus, and held-note reflow in all five layouts.',
  )
} finally {
  await browser?.close()
  await server.close()
}
