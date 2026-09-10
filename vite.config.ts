/// <reference types="vitest/config" />
import { defineConfig } from 'vite'

export default defineConfig({
  base: './',
  // A dedicated port keeps the Tailscale proxy pointed at Expression Pad
  // when other Vite apps are running on this Mac.
  server: {
    host: true,
    port: 5180,
    strictPort: true,
    allowedHosts: ['m4air', 'm4air.local', 'm4air.tail15c530.ts.net'],
  },
  preview: {
    host: true,
    allowedHosts: ['m4air', 'm4air.local', 'm4air.tail15c530.ts.net'],
  },
  build: { target: 'es2022' },
  test: {
    environment: 'jsdom',
    include: ['tests/**/*.test.ts'],
  },
})
