import puppeteer from 'puppeteer-core'

const browser = await puppeteer.launch({ channel: 'chrome', headless: true })
const page = await browser.newPage()
await page.setViewport({ width: 1000, height: 620, deviceScaleFactor: 1 })

const shot = (name) =>
  page.screenshot({ path: `/Users/cdeck/dev/expressionpad/reference/render/${name}.png` })
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
const tap = async (x, y) => {
  await page.mouse.move(x, y)
  await page.mouse.down()
  await page.mouse.up()
}

// 1. Square grid: darkened conventional black-key pitch classes.
await page.goto('http://localhost:4199/?layout=square&rows=4&cols=12&panel=0', {
  waitUntil: 'networkidle0',
})
await sleep(400)
await shot('grid-dark-accidentals')

// 2. Poke the center and catch the wave mid-flight.
await tap(500, 310)
await sleep(160)
await shot('grid-ripple-wave')

// 3. Same on hexes, Mono scheme.
await page.goto('http://localhost:4199/?layout=hex&rows=5&cols=12&panel=0&scheme=Mono', {
  waitUntil: 'networkidle0',
})
await sleep(400)
await tap(500, 310)
await sleep(160)
await shot('hex-ripple-wave')

await browser.close()
console.log('done')
