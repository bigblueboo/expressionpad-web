/** Generate app icons: a glowing hex cluster on the app's dark navy. */
import puppeteer from 'puppeteer-core'

const html = `<!doctype html><html><head><style>
  html,body{margin:0;width:512px;height:512px;background:#0a0e14;overflow:hidden}
</style></head><body>
<svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="bg" cx="50%" cy="42%" r="75%">
      <stop offset="0%" stop-color="#11253a"/>
      <stop offset="100%" stop-color="#0a0e14"/>
    </radialGradient>
    <filter id="glow" x="-60%" y="-60%" width="220%" height="220%">
      <feGaussianBlur stdDeviation="14" result="b"/>
      <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
  </defs>
  <rect width="512" height="512" fill="url(#bg)"/>
  <g stroke-width="5">
    <polygon points="256,86 351,141 351,251 256,306 161,251 161,141"
      fill="#1c4f73" stroke="#2a6e96"/>
    <polygon points="161,251 256,306 256,416 161,471 66,416 66,306"
      fill="#2a86b8" stroke="#3aa0d8" transform="translate(0,-55)"/>
    <polygon points="351,251 446,306 446,416 351,471 256,416 256,306"
      fill="#eaf7ff" stroke="#ffffff" filter="url(#glow)" transform="translate(0,-55)"/>
  </g>
</svg>
</body></html>`

const browser = await puppeteer.launch({ channel: 'chrome', headless: true })
const page = await browser.newPage()
for (const [size, name] of [[512, 'icon-512.png'], [192, 'icon-192.png'], [180, 'apple-touch-icon.png']]) {
  await page.setViewport({ width: 512, height: 512, deviceScaleFactor: 1 })
  await page.setContent(html)
  if (size !== 512) {
    await page.evaluate((s) => {
      document.body.style.transform = `scale(${s / 512})`
      document.body.style.transformOrigin = '0 0'
    }, size)
    await page.setViewport({ width: size, height: size, deviceScaleFactor: 1 })
  }
  await page.screenshot({ path: `public/${name}` })
  console.log(`✓ ${name}`)
}
await browser.close()
