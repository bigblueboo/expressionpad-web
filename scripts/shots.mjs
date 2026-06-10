/**
 * Device-emulated screenshots of the running preview server.
 * Usage: node scripts/shots.mjs [baseUrl]
 */
import puppeteer from 'puppeteer-core'
import { mkdirSync } from 'node:fs'

const base = process.argv[2] ?? 'http://localhost:4173'
const outDir = 'reference/render'
mkdirSync(outDir, { recursive: true })

const shots = [
  { name: 'phone-portrait', w: 390, h: 844, q: 'layout=square&rows=5&cols=7' },
  { name: 'phone-landscape', w: 844, h: 390, q: 'layout=hex&scheme=Mono&panel=0&rows=5&cols=12' },
  { name: 'phone-piano-portrait', w: 390, h: 844, q: 'layout=piano&scheme=Magenta&rows=4&cols=7&panel=0' },
  { name: 'tablet-square', w: 1024, h: 768, q: 'layout=square&scheme=Ocean' },
  { name: 'tablet-smplr', w: 1024, h: 768, q: 'layout=square&scheme=Ocean&tab=smplr&panel=1&voice=sampler' },
  { name: 'tablet-hex', w: 1024, h: 768, q: 'layout=hex&scheme=Rainbow&rows=6&cols=14&tab=synth' },
  { name: 'tablet-piano', w: 1024, h: 768, q: 'layout=piano&scheme=Magenta&rows=3&cols=14&tab=fx' },
]

const browser = await puppeteer.launch({
  channel: 'chrome',
  headless: true,
})

const page = await browser.newPage()
for (const s of shots) {
  await page.setViewport({ width: s.w, height: s.h, isMobile: true, hasTouch: true, deviceScaleFactor: 2 })
  await page.goto(`${base}/?${s.q}`, { waitUntil: 'networkidle0' })
  await new Promise((r) => setTimeout(r, 250))
  await page.screenshot({ path: `${outDir}/${s.name}.png` })
  console.log(`✓ ${s.name}`)
}

await browser.close()
