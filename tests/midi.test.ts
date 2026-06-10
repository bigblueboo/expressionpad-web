import { describe, expect, it } from 'vitest'
import { bendBytes, ChannelAllocator, MidiIn } from '../src/midi/midi'
import { Store } from '../src/core/state'
import type { VoiceSink } from '../src/audio/sink'

describe('bendBytes', () => {
  it('centers at 8192 for zero bend', () => {
    const [lsb, msb] = bendBytes(0, 48)
    expect((msb << 7) | lsb).toBe(8192)
  })

  it('maxes at full positive range', () => {
    const [lsb, msb] = bendBytes(48, 48)
    expect((msb << 7) | lsb).toBe(16383)
  })

  it('bottoms near zero at full negative range', () => {
    const [lsb, msb] = bendBytes(-48, 48)
    expect((msb << 7) | lsb).toBe(1)
  })

  it('clamps out-of-range bends', () => {
    const [lsb, msb] = bendBytes(100, 48)
    expect((msb << 7) | lsb).toBe(16383)
  })

  it('scales linearly with the range setting', () => {
    const [lsb2, msb2] = bendBytes(1, 2)
    const [lsb48, msb48] = bendBytes(24, 48)
    expect((msb2 << 7) | lsb2).toBe((msb48 << 7) | lsb48)
  })

  it('produces valid 7-bit data bytes', () => {
    for (const semis of [-48, -1.3, 0, 0.5, 7, 48]) {
      const [lsb, msb] = bendBytes(semis, 48)
      expect(lsb).toBeGreaterThanOrEqual(0)
      expect(lsb).toBeLessThanOrEqual(127)
      expect(msb).toBeGreaterThanOrEqual(0)
      expect(msb).toBeLessThanOrEqual(127)
    }
  })
})

describe('ChannelAllocator', () => {
  it('hands out distinct member channels 1-15', () => {
    const alloc = new ChannelAllocator()
    const channels = new Set<number>()
    for (let id = 0; id < 15; id++) channels.add(alloc.acquire(id))
    expect(channels.size).toBe(15)
    expect(Math.min(...channels)).toBe(1)
    expect(Math.max(...channels)).toBe(15)
  })

  it('is idempotent for the same id', () => {
    const alloc = new ChannelAllocator()
    expect(alloc.acquire(7)).toBe(alloc.acquire(7))
  })

  it('recycles released channels with maximum reuse distance', () => {
    const alloc = new ChannelAllocator(1, 3)
    const a = alloc.acquire(1)
    alloc.acquire(2)
    alloc.acquire(3)
    alloc.release(1)
    // Channel `a` goes to the back of the queue; a 4th voice steals... no:
    // there is exactly one free channel now, so it must be `a`.
    expect(alloc.acquire(4)).toBe(a)
  })

  it('steals the oldest held channel when exhausted', () => {
    const alloc = new ChannelAllocator(1, 2)
    const first = alloc.acquire(1)
    alloc.acquire(2)
    const third = alloc.acquire(3)
    expect(third).toBe(first)
    expect(alloc.channelOf(1)).toBeUndefined()
  })
})

class SpySink implements VoiceSink {
  ons: Array<[number, number, number]> = []
  offs: number[] = []
  noteOn(id: number, pitch: number, vel: number) { this.ons.push([id, pitch, vel]) }
  glide() {}
  pressure() {}
  noteOff(id: number) { this.offs.push(id) }
  allOff() {}
}

describe('MidiIn', () => {
  it('routes note on/off pairs to the sink', () => {
    const store = new Store()
    store.set('midi.inEnabled', true)
    const sink = new SpySink()
    const midiIn = new MidiIn(store, sink)
    midiIn.handle(new Uint8Array([0x90, 60, 100]))
    expect(sink.ons).toHaveLength(1)
    expect(sink.ons[0][1]).toBe(60)
    expect(sink.ons[0][2]).toBeCloseTo(100 / 127)
    midiIn.handle(new Uint8Array([0x80, 60, 0]))
    expect(sink.offs).toEqual([sink.ons[0][0]])
  })

  it('treats velocity-0 note-on as note-off', () => {
    const store = new Store()
    store.set('midi.inEnabled', true)
    const sink = new SpySink()
    const midiIn = new MidiIn(store, sink)
    midiIn.handle(new Uint8Array([0x90, 64, 90]))
    midiIn.handle(new Uint8Array([0x90, 64, 0]))
    expect(sink.offs).toHaveLength(1)
  })

  it('ignores messages when disabled', () => {
    const store = new Store()
    const sink = new SpySink()
    const midiIn = new MidiIn(store, sink)
    midiIn.handle(new Uint8Array([0x90, 60, 100]))
    expect(sink.ons).toHaveLength(0)
  })
})
