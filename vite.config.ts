/// <reference types="vitest/config" />
import { defineConfig } from 'vite'

export default defineConfig({
  base: './',
  // Listen on the LAN and accept this Mac's hostnames so phones/tablets
  // on the same network can play it.
  server: {
    host: true,
    allowedHosts: ['m4air', 'm4air.local'],
  },
  preview: {
    host: true,
    allowedHosts: ['m4air', 'm4air.local'],
  },
  build: { target: 'es2022' },
  test: {
    environment: 'jsdom',
    include: ['tests/**/*.test.ts'],
  },
})
